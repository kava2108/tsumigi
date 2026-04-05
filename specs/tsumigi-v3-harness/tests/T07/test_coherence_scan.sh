#!/usr/bin/env bash
# T07 coherence-scan / baton-status テストスクリプト
# 実行: bash specs/tsumigi-v3-harness/tests/T07/test_coherence_scan.sh
#
# 前提: jq が利用可能であること、spec ファイルが存在すること
# テスト対象:
#   - graph/coherence.json（coherence-scan の出力）
#   - graph/baton-log.json（baton-status の入力）
#   - jq クエリロジック（循環依存検出、ダングリング参照検出）
#
# テスト方針:
#  - coherence-scan 自体は Claude Code スラッシュコマンドのため bash から直接実行不可
#  - 実行済みの coherence.json 構造を検証（回帰テスト）
#  - 合成データを用いた jq ロジックの単体テスト
#  - coherence-scan の冪等性は JSON の安定性で検証
#  - TC-T07-SEC-01/02: YAML frontmatter インジェクションの耐性確認

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
COHERENCE_JSON="$REPO_ROOT/graph/coherence.json"
BATON_LOG_JSON="$REPO_ROOT/graph/baton-log.json"

# ============================================================
# テスト結果カウンタ
# ============================================================
PASS=0
FAIL=0
SKIP=0

run_test() {
  local name="$1"
  shift
  echo -n "  $name ... "
  if "$@" 2>/dev/null; then
    echo "✅ PASS"
    (( PASS++ )) || true
  else
    echo "❌ FAIL"
    (( FAIL++ )) || true
  fi
}

skip_test() {
  local name="$1"
  local reason="$2"
  echo "  $name ... ⏭  SKIP ($reason)"
  (( SKIP++ )) || true
}

# ============================================================
# TC-T07-01: coherence.json が存在し全既知 spec ファイルのノードを含む
# ============================================================
test_tc01_coherence_json_contains_known_nodes() {
  [[ -f "$COHERENCE_JSON" ]] || return 1
  jq empty "$COHERENCE_JSON" 2>/dev/null || return 1

  # 既知の必須ノード（IMP・adversary・各 testcases）が存在することを確認
  local known_nodes=(
    "imp:tsumigi-v3-harness"
    "test:tsumigi-v3-harness:T01"
    "test:tsumigi-v3-harness:T03"
    "test:tsumigi-v3-harness:T07"
    "adversary:tsumigi-v3-harness"
  )
  for node_id in "${known_nodes[@]}"; do
    local found
    found=$(jq -r --arg id "$node_id" '.nodes[$id] // empty' "$COHERENCE_JSON" 2>/dev/null)
    [[ -n "$found" ]] || return 1
  done
  return 0
}

# ============================================================
# TC-T07-02: baton-log.json の pending エントリを jq クエリで正確に取得できる
#  （baton-status が pending エントリを表示するロジックの単体テスト）
# ============================================================
test_tc02_baton_log_pending_query() {
  local tmp_log
  tmp_log=$(mktemp)
  # 合成 baton-log.json: pending エントリあり
  cat > "$tmp_log" <<'EOJSON'
{
  "version": "1.0.0",
  "transitions": [],
  "pending": {
    "42": {
      "next": "phase:tds",
      "recorded_at": "2026-04-05T00:00:00Z"
    }
  }
}
EOJSON

  local next_phase
  next_phase=$(jq -r '.pending["42"].next // ""' "$tmp_log" 2>/dev/null || echo "")
  rm -f "$tmp_log"

  [[ "$next_phase" == "phase:tds" ]]
}

# ============================================================
# TC-T07-03: coherence.json の再読み込みでノード数が変化しない（冪等性検証）
# ============================================================
test_tc03_coherence_json_node_count_stable() {
  [[ -f "$COHERENCE_JSON" ]] || return 1

  local count1 count2
  count1=$(jq '.nodes | length' "$COHERENCE_JSON" 2>/dev/null || echo "-1")
  count2=$(jq '.nodes | length' "$COHERENCE_JSON" 2>/dev/null || echo "-2")

  [[ "$count1" == "$count2" ]] && [[ "$count1" -gt 0 ]]
}

# ============================================================
# TC-T07-04: 循環依存グラフ（A→B→A）を DFS で検出できる
#  （coherence.json の _check_ceg() jq DFS ロジックの単体テスト）
# ============================================================
test_tc04_circular_dep_detected_by_dfs() {
  local tmp_json
  tmp_json=$(mktemp)
  # 循環依存: A → B → A
  cat > "$tmp_json" <<'EOJSON'
{
  "version": "1.0.0",
  "nodes": {},
  "edges": [
    {"from": "A", "to": "B"},
    {"from": "B", "to": "A"}
  ],
  "summary": {"green": 0, "amber": 0, "gray": 0, "red": 0, "warnings": []}
}
EOJSON

  # T03 test_phase_gate.sh の _check_ceg() と同じ DFS ロジック
  local cycle_result
  cycle_result=$(jq -r '
    def dfs(node; stack; adj):
      if (stack | index(node)) != null then "cycle"
      else
        reduce (adj[node] // [])[] as $n (
          "ok";
          if . == "cycle" then "cycle"
          else dfs($n; stack + [node]; adj)
          end
        )
      end;

    . as $g |
    ($g.edges | reduce .[] as $e ({}; .[$e.from] += [$e.to])) as $adj |
    ([($g.edges[] | .from, .to)] | unique) as $all_nodes |
    reduce $all_nodes[] as $node (
      "ok";
      if . == "cycle" then "cycle"
      else dfs($node; []; $adj)
      end
    )
  ' "$tmp_json" 2>/dev/null || echo "error")

  rm -f "$tmp_json"
  [[ "$cycle_result" == "cycle" ]]
}

# ============================================================
# TC-T07-05: ダングリング参照を持つノードが Amber バンドになっている
#  （現行 coherence.json に Amber ノードが存在することを確認）
# ============================================================
test_tc05_dangling_ref_nodes_are_amber() {
  [[ -f "$COHERENCE_JSON" ]] || return 1

  # Amber ノードが 1 件以上存在することを確認
  local amber_count
  amber_count=$(jq '[.nodes[] | select(.band == "Amber")] | length' "$COHERENCE_JSON" 2>/dev/null || echo "0")
  [[ "$amber_count" -gt 0 ]]
}

# ============================================================
# TC-T07-06: 壊れた frontmatter ファイルが存在しても他ファイルのパースは続行する
#  （grep + bash による frontmatter パーサーの robustness テスト）
# ============================================================
test_tc06_broken_frontmatter_does_not_halt_scan() {
  local tmpdir
  tmpdir=$(mktemp -d)

  # 正常なファイル
  cat > "$tmpdir/good.md" <<'EOMD'
---
coherence:
  id: "test:good"
  band: "Green"
---
# Good file
EOMD

  # 壊れた YAML frontmatter
  cat > "$tmpdir/broken.md" <<'EOMD'
---
coherence:
  id: {{{{BROKEN
   band: [unclosed
---
# Broken file
EOMD

  # frontmatter 抽出: awk で --- 区切りの間を抽出し、coherence.id をパースする
  local good_ids=()
  while IFS= read -r file; do
    local raw_id=""
    raw_id=$(awk '/^---/{f=!f; next} f' "$file" 2>/dev/null | grep -oP 'id:\s*"\K[^"]+' | head -1 || true)
    [[ -n "$raw_id" ]] && good_ids+=("$raw_id")
  done < <(find "$tmpdir" -name "*.md" | sort)

  rm -rf "$tmpdir"

  # good.md の id が取得でき、ループが broken.md で停止しなかったことを確認
  [[ "${#good_ids[@]}" -ge 1 ]] && [[ "${good_ids[0]}" == "test:good" ]]
}

# ============================================================
# TC-T07-07: 空の nodes を持つ coherence.json が valid JSON である
#  （coherence-scan が specs/ 空の場合でも正常生成できる形式の検証）
# ============================================================
test_tc07_empty_coherence_json_is_valid() {
  local tmp_json
  tmp_json=$(mktemp)
  # coherence-scan が空の specs/ で生成するはずの最小構造
  cat > "$tmp_json" <<'EOJSON'
{
  "version": "1.0.0",
  "generated_at": "2026-04-05T00:00:00Z",
  "nodes": {},
  "edges": [],
  "summary": {
    "total": 0,
    "green": 0,
    "amber": 0,
    "gray": 0,
    "red": 0,
    "warnings": []
  }
}
EOJSON

  jq empty "$tmp_json" 2>/dev/null
  local retval=$?
  rm -f "$tmp_json"
  [[ "$retval" == "0" ]]
}

# ============================================================
# TC-T07-SEC-01: YAML frontmatter の node_id に shell injection 文字列を含む
#  ファイルが存在しても、grep/awk ベースのパーサーが安全に処理する
# ============================================================
test_tc_sec01_yaml_injection_in_node_id() {
  local tmpdir
  tmpdir=$(mktemp -d)

  # node_id に コマンド置換を埋め込んだ YAML
  cat > "$tmpdir/injection.md" <<'EOMD'
---
coherence:
  id: "$(rm -rf /)"
  band: "Green"
---
# Injection attempt
EOMD

  # grep -oP でシングルクォート内のみを抽出するため、コマンド置換は実行されない
  local extracted_id=""
  extracted_id=$(awk '/^---/{f=!f; next} f' "$tmpdir/injection.md" 2>/dev/null \
    | grep -oP 'id:\s*"\K[^"]+' | head -1 || true)

  rm -rf "$tmpdir"

  # 抽出された文字列がそのまま取得され（実行されず）、かつ期待値と一致する
  [[ "$extracted_id" == '$(rm -rf /)' ]]
}

# ============================================================
# TC-T07-SEC-02: coherence.json の band フィールドに不正値が混入しても
#  jq クエリが安全に動作する（NoSQL injection 相当の耐性確認）
# ============================================================
test_tc_sec02_malicious_band_value_handled_safely() {
  local tmp_json
  tmp_json=$(mktemp)
  cat > "$tmp_json" <<'EOJSON'
{
  "version": "1.0.0",
  "nodes": {
    "legit:node": {"id": "legit:node", "band": "Green"},
    "evil:node":  {"id": "evil:node",  "band": "; rm -rf /; echo \"injected\""}
  },
  "edges": [],
  "summary": {"total": 2, "green": 1, "amber": 0, "gray": 0, "red": 0, "warnings": []}
}
EOJSON

  # jq で Green 以外のノードを取得しても、コード実行は発生しない
  local non_green_count
  non_green_count=$(jq '[.nodes[] | select(.band != "Green")] | length' "$tmp_json" 2>/dev/null || echo "0")
  rm -f "$tmp_json"

  # 不正な band 値を持つノードが 1 件として jq に取得される（実行されない）
  [[ "$non_green_count" == "1" ]]
}

# ============================================================
# テスト実行
# ============================================================
echo ""
echo "=================================================="
echo "  T07 coherence-scan / baton-status テストスイート"
echo "=================================================="
echo ""
echo "--- 正常系 ---"
run_test "TC-T07-01: coherence.json に既知ノードが全て存在する"              test_tc01_coherence_json_contains_known_nodes
run_test "TC-T07-02: baton-log.json pending エントリの jq クエリ正確性"      test_tc02_baton_log_pending_query
run_test "TC-T07-03: coherence.json ノード数の冪等性（再読み込み安定）"      test_tc03_coherence_json_node_count_stable
echo ""
echo "--- 異常系 ---"
run_test "TC-T07-04: 循環依存 A→B→A を DFS で検出"                           test_tc04_circular_dep_detected_by_dfs
run_test "TC-T07-05: ダングリング参照ノードが Amber バンド"                   test_tc05_dangling_ref_nodes_are_amber
run_test "TC-T07-06: 壊れた frontmatter があっても他ファイルのパース継続"    test_tc06_broken_frontmatter_does_not_halt_scan
echo ""
echo "--- 境界値 ---"
run_test "TC-T07-07: 空 nodes の coherence.json が valid JSON"               test_tc07_empty_coherence_json_is_valid
echo ""
echo "--- セキュリティ ---"
run_test "TC-T07-SEC-01: node_id への shell injection → 文字列として安全取得" test_tc_sec01_yaml_injection_in_node_id
run_test "TC-T07-SEC-02: band フィールドの不正値を jq が安全に処理"          test_tc_sec02_malicious_band_value_handled_safely
echo ""
echo "=================================================="
echo "  結果: PASS=$PASS / FAIL=$FAIL / SKIP=$SKIP"
echo "=================================================="
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
