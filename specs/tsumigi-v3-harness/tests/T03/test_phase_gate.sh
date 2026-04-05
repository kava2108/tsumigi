#!/usr/bin/env bash
# T03 Phase Gate テストスクリプト
# 実行: bash specs/tsumigi-v3-harness/tests/T03/test_phase_gate.sh
#
# 前提: jq が利用可能であること（yq は不要）
# テスト対象: .tsumigi/lib/phase-gate.sh
#
# 設計ポイント:
#  - 各テストはサブシェルで実行されるため、ファイルベーススパイで mock_gh の呼び出しを記録
#  - export -f mock_gh が必要（サブシェルに関数を渡すため）
#  - source した後に _check_harness_enabled を上書きして harness テストモードを有効化

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
PHASE_GATE_LIB="$REPO_ROOT/.tsumigi/lib/phase-gate.sh"

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

# ============================================================
# 共通: テスト用ディレクトリを作成し phase-gate.sh を source する
# ファイルベーススパイを使う（CALL_LOG ファイルに呼び出し記録）
# ============================================================
_make_test_env() {
  local d
  d=$(mktemp -d)
  mkdir -p "$d/.vckd" "$d/graph" "$d/specs/tsumigi-v3-harness" "$d/.kiro/specs/my-feature"
  echo '{"version":"1.0.0","transitions":[],"pending":{}}' > "$d/graph/baton-log.json"
  echo "$d"
}

# ============================================================
# TC-T03-01: AUTO_STEP=false のとき dispatch_baton が emit_pending を呼ぶ
# ============================================================
test_tc01_dispatch_baton_emit_pending() {
  local d
  d=$(_make_test_env)
  local call_log="$d/call.log"
  touch "$call_log"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    export CALL_LOG="$call_log"
    mock_gh() { echo "gh $*" >> "$CALL_LOG"; return 0; }
    export -f mock_gh

    # shellcheck source=/dev/null
    source "$PHASE_GATE_LIB"
    # harness を有効化（source 後に上書き必須）
    _check_harness_enabled() { return 0; }
    # AUTO_STEP=false を強制
    _get_auto_step() { echo "false"; }

    # emit_pending を spy: ファイルに記録
    emit_pending() { echo "emit_pending" >> "$CALL_LOG"; return 0; }
    emit_baton()   { echo "emit_baton"   >> "$CALL_LOG"; return 0; }

    dispatch_baton 1 "phase:req" "phase:tds"
  )

  local called_pending=0 called_baton=0
  grep -q "^emit_pending$" "$call_log" 2>/dev/null && called_pending=1
  grep -q "^emit_baton$"   "$call_log" 2>/dev/null && called_baton=1
  rm -rf "$d"

  [[ "$called_pending" == "1" ]] && [[ "$called_baton" == "0" ]]
}

# ============================================================
# TC-T03-02: AUTO_STEP=true のとき dispatch_baton が emit_baton を呼ぶ
# ============================================================
test_tc02_dispatch_baton_emit_baton() {
  local d
  d=$(_make_test_env)
  local call_log="$d/call.log"
  touch "$call_log"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    export CALL_LOG="$call_log"
    mock_gh() { echo "gh $*" >> "$CALL_LOG"; return 0; }
    export -f mock_gh

    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }
    _get_auto_step() { echo "true"; }

    emit_pending() { echo "emit_pending" >> "$CALL_LOG"; return 0; }
    emit_baton()   { echo "emit_baton"   >> "$CALL_LOG"; return 0; }

    dispatch_baton 1 "phase:req" "phase:tds"
  )

  local called_pending=0 called_baton=0
  grep -q "^emit_pending$" "$call_log" 2>/dev/null && called_pending=1
  grep -q "^emit_baton$"   "$call_log" 2>/dev/null && called_baton=1
  rm -rf "$d"

  [[ "$called_baton" == "1" ]] && [[ "$called_pending" == "0" ]]
}

# ============================================================
# TC-T03-03: emit_pending がラベル変更とコメント投稿を行う
# ============================================================
test_tc03_emit_pending_label_and_comment() {
  local d
  d=$(_make_test_env)
  local call_log="$d/call.log"
  touch "$call_log"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    export CALL_LOG="$call_log"
    mock_gh() { echo "gh $*" >> "$CALL_LOG"; return 0; }
    export -f mock_gh

    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }

    emit_pending 1 "phase:req" "pending:next-phase" "phase:tds"
  )

  local label_changed=0 comment_posted=0
  grep -q -- "--remove-label" "$call_log" 2>/dev/null && label_changed=1
  grep -q "issue comment"      "$call_log" 2>/dev/null && comment_posted=1
  rm -rf "$d"

  [[ "$label_changed" == "1" ]] && [[ "$comment_posted" == "1" ]]
}

# ============================================================
# TC-T03-04: emit_baton がラベル変更とコメント投稿を行う
# ============================================================
test_tc04_emit_baton_label_and_comment() {
  local d
  d=$(_make_test_env)
  local call_log="$d/call.log"
  touch "$call_log"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    export CALL_LOG="$call_log"
    mock_gh() { echo "gh $*" >> "$CALL_LOG"; return 0; }
    export -f mock_gh

    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }

    emit_baton 1 "phase:req" "phase:tds"
  )

  local label_changed=0 comment_posted=0
  grep -q -- "--remove-label" "$call_log" 2>/dev/null && label_changed=1
  grep -q "issue comment"      "$call_log" 2>/dev/null && comment_posted=1
  rm -rf "$d"

  [[ "$label_changed" == "1" ]] && [[ "$comment_posted" == "1" ]]
}

# ============================================================
# TC-T03-06: emit_blocked がブロックラベルとコメントを付与する
# ============================================================
test_tc06_emit_blocked_label_and_comment() {
  local d
  d=$(_make_test_env)
  local call_log="$d/call.log"
  touch "$call_log"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    export CALL_LOG="$call_log"
    mock_gh() { echo "gh $*" >> "$CALL_LOG"; return 0; }
    export -f mock_gh

    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }

    # emit_blocked は phase-gate.sh 内に実装されているので呼び出すのみ
    emit_blocked 1 "phase:imp" "blocked:imp" "テストカバレッジ不足"
  )

  local label_added=0 comment_posted=0
  grep -q "blocked:imp"    "$call_log" 2>/dev/null && label_added=1
  grep -q "issue comment"  "$call_log" 2>/dev/null && comment_posted=1
  rm -rf "$d"

  [[ "$label_added" == "1" ]] && [[ "$comment_posted" == "1" ]]
}

# ============================================================
# TC-T03-07: check_phase_gate が必須ファイル存在で PASS を返す
# ============================================================
test_tc07_check_phase_gate_pass() {
  local d
  d=$(_make_test_env)
  local result_file="$d/result.txt"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    mock_gh() { return 0; }
    export -f mock_gh

    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }

    # IMP→TEST 遷移に必要なファイルを作成
    printf "# IMP\npatch-plan: exists\n" > specs/tsumigi-v3-harness/IMP.md
    printf '{"version":"1.0.0","transitions":[],"pending":{},"summary":{"gray":0,"warnings":[]}}' \
      > graph/coherence.json

    set +e
    check_phase_gate "IMP" "my-feature" "tsumigi-v3-harness"
    local retval=$?
    echo "retval=$retval gate=${VCKD_GATE_RESULT:-}" >> "$result_file"
  )

  local retval="" gate=""
  if [[ -f "$result_file" ]]; then
    retval=$(grep -oP 'retval=\K[0-9]+' "$result_file" 2>/dev/null || echo "")
    gate=$(grep -oP 'gate=\K\S+' "$result_file" 2>/dev/null || echo "")
  fi
  rm -rf "$d"

  [[ "$retval" == "0" ]] && [[ "$gate" == "PASS" ]]
}

# ============================================================
# TC-T03-08: harness.enabled=false のとき dispatch_baton が何もしない
# ============================================================
test_tc08_harness_disabled_no_gh_call() {
  local d
  d=$(_make_test_env)
  local call_log="$d/call.log"
  touch "$call_log"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    export CALL_LOG="$call_log"
    mock_gh() { echo "gh $*" >> "$CALL_LOG"; return 0; }
    export -f mock_gh

    source "$PHASE_GATE_LIB"
    # harness を無効化（source 後に上書き）
    _check_harness_enabled() { return 1; }

    dispatch_baton 1 "phase:req" "phase:tds" || true
  )

  local called=0
  grep -q "^gh " "$call_log" 2>/dev/null && called=1
  rm -rf "$d"

  [[ "$called" == "0" ]]
}

# ============================================================
# TC-T03-09: get_retry_count と increment_retry_count が正しく動作する
# ============================================================
test_tc09_retry_count() {
  local d
  d=$(_make_test_env)
  local result_file="$d/result.txt"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    mock_gh() { return 0; }
    export -f mock_gh

    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }

    increment_retry_count 42 "test error" "test-agent"
    increment_retry_count 42 "test error" "test-agent"

    count=$(get_retry_count 42)
    echo "count=$count" >> "$result_file"
  )

  local count=""
  count=$(grep -oP 'count=\K[0-9]+' "$result_file" 2>/dev/null || echo "")
  rm -rf "$d"

  [[ "$count" == "2" ]]
}

# ============================================================
# TC-T03-10: config.yaml が存在しない場合 AUTO_STEP=false フォールバック
# ============================================================
test_tc10_no_config_auto_step_false() {
  local d
  d=$(_make_test_env)
  local call_log="$d/call.log"
  touch "$call_log"

  (
    cd "$d"
    rm -f .vckd/config.yaml
    export VCKD_TEST_MODE=1
    export CALL_LOG="$call_log"
    mock_gh() { echo "gh $*" >> "$CALL_LOG"; return 0; }
    export -f mock_gh

    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }
    # emit_ 関数を spy（ファイルに記録）
    emit_pending() { echo "emit_pending" >> "$CALL_LOG"; return 0; }
    emit_baton()   { echo "emit_baton"   >> "$CALL_LOG"; return 0; }

    dispatch_baton 1 "phase:req" "phase:tds"
  )

  local called_pending=0
  grep -q "^emit_pending$" "$call_log" 2>/dev/null && called_pending=1
  rm -rf "$d"

  [[ "$called_pending" == "1" ]]
}

# ============================================================
# TC-T03-12: check_phase_gate が必須ファイル不在で FAIL を返す
# ============================================================
test_tc12_check_phase_gate_fail_missing_artifact() {
  local d
  d=$(_make_test_env)
  local result_file="$d/result.txt"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    mock_gh() { return 0; }
    export -f mock_gh

    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }

    printf '{"version":"1.0.0","transitions":[],"pending":{},"summary":{"gray":0,"warnings":[]}}' \
      > graph/coherence.json
    # IMP.md を作成しない

    set +e
    check_phase_gate "IMP" "my-feature" "tsumigi-v3-harness"
    local retval=$?
    echo "retval=$retval gate=${VCKD_GATE_RESULT:-}" >> "$result_file"
  )

  local retval="" gate=""
  if [[ -f "$result_file" ]]; then
    retval=$(grep -oP 'retval=\K[0-9]+' "$result_file" 2>/dev/null || echo "")
    gate=$(grep -oP 'gate=\K\S+' "$result_file" 2>/dev/null || echo "")
  fi
  rm -rf "$d"

  [[ "$retval" != "0" ]] && [[ "$gate" == "FAIL" ]]
}

# ============================================================
# TC-T03-13: check_phase_gate が循環依存（A→B→A）で FAIL を返す
# ============================================================
test_tc13_check_phase_gate_fail_circular_dep() {
  local d
  d=$(_make_test_env)
  local result_file="$d/result.txt"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    mock_gh() { return 0; }
    export -f mock_gh

    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }

    # OPS フェーズ成果物を用意
    printf "# drift-report\ndrift score: 5\n" > specs/tsumigi-v3-harness/drift-report.md

    # 循環依存グラフ A→B→A
    cat > graph/coherence.json <<'EOJSON'
{
  "version": "1.0.0",
  "edges": [
    {"from": "A", "to": "B"},
    {"from": "B", "to": "A"}
  ],
  "summary": {"gray": 0, "warnings": []}
}
EOJSON

    set +e
    check_phase_gate "OPS" "my-feature" "tsumigi-v3-harness"
    local retval=$?
    echo "retval=$retval gate=${VCKD_GATE_RESULT:-}" >> "$result_file"
  )

  local retval="" gate=""
  if [[ -f "$result_file" ]]; then
    retval=$(grep -oP 'retval=\K[0-9]+' "$result_file" 2>/dev/null || echo "")
    gate=$(grep -oP 'gate=\K\S+' "$result_file" 2>/dev/null || echo "")
  fi
  rm -rf "$d"

  [[ "$retval" != "0" ]] && [[ "$gate" == "FAIL" ]]
}

# ============================================================
# TC-T03-15: baton-log.json が破損していたらバックアップ後に再初期化
# ============================================================
test_tc15_baton_log_corrupted_reinit() {
  local d
  d=$(_make_test_env)
  local result_file="$d/result.txt"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    mock_gh() { return 0; }
    export -f mock_gh

    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }

    # 破損した JSON を書き込む
    echo "CORRUPTED {{{{" > graph/baton-log.json

    _ensure_baton_log 2>/dev/null

    local bak_exists=0 valid_json=0
    [[ -f "graph/baton-log.json.bak" ]] && bak_exists=1
    jq empty graph/baton-log.json 2>/dev/null && valid_json=1

    echo "bak=$bak_exists json=$valid_json" >> "$result_file"
  )

  local bak="" json=""
  if [[ -f "$result_file" ]]; then
    bak=$(grep -oP 'bak=\K[0-9]' "$result_file" 2>/dev/null || echo "0")
    json=$(grep -oP 'json=\K[0-9]' "$result_file" 2>/dev/null || echo "0")
  fi
  rm -rf "$d"

  [[ "$bak" == "1" ]] && [[ "$json" == "1" ]]
}

# ============================================================
# TC-T03-SEC-01: issue_number が整数以外なら exit 2（shell injection 防止）
# ============================================================
test_tc_sec01_injection_exit2() {
  local d
  d=$(_make_test_env)
  local call_log="$d/call.log"
  local result_file="$d/result.txt"
  touch "$call_log"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    export CALL_LOG="$call_log"
    mock_gh() { echo "gh $*" >> "$CALL_LOG"; return 0; }
    export -f mock_gh

    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }
    emit_pending() { return 0; }
    emit_baton()   { return 0; }

    set +e
    dispatch_baton "1; echo INJECTED" "phase:req" "phase:tds"
    local retval=$?
    echo "retval=$retval" >> "$result_file"
  )

  local retval="" gh_called=0
  retval=$(grep -oP 'retval=\K[0-9]+' "$result_file" 2>/dev/null || echo "")
  grep -q "^gh " "$call_log" 2>/dev/null && gh_called=1
  rm -rf "$d"

  [[ "$retval" == "2" ]] && [[ "$gh_called" == "0" ]]
}

# ============================================================
# テスト実行
# ============================================================
echo ""
echo "=================================================="
echo "  T03 Phase Gate テストスイート"
echo "=================================================="
echo ""
echo "--- 正常系 ---"
run_test "TC-T03-01: AUTO_STEP=false → emit_pending 呼出" test_tc01_dispatch_baton_emit_pending
run_test "TC-T03-02: AUTO_STEP=true  → emit_baton 呼出"  test_tc02_dispatch_baton_emit_baton
run_test "TC-T03-03: emit_pending → ラベル変更 + コメント投稿" test_tc03_emit_pending_label_and_comment
run_test "TC-T03-04: emit_baton   → ラベル変更 + コメント投稿" test_tc04_emit_baton_label_and_comment
run_test "TC-T03-06: emit_blocked → blocked ラベル + コメント" test_tc06_emit_blocked_label_and_comment
run_test "TC-T03-07: check_phase_gate PASS（ファイル存在）"    test_tc07_check_phase_gate_pass
run_test "TC-T03-08: harness disabled → gh 未呼出"            test_tc08_harness_disabled_no_gh_call
run_test "TC-T03-09: retry_count 2 回 increment"              test_tc09_retry_count
echo ""
echo "--- 異常系 ---"
run_test "TC-T03-10: config.yaml 不在 → AUTO_STEP=false フォールバック" test_tc10_no_config_auto_step_false
run_test "TC-T03-12: check_phase_gate FAIL（ファイル不在）"             test_tc12_check_phase_gate_fail_missing_artifact
run_test "TC-T03-13: check_phase_gate FAIL（循環依存 A→B→A）"          test_tc13_check_phase_gate_fail_circular_dep
run_test "TC-T03-15: baton-log.json 破損 → バックアップ + 再初期化"    test_tc15_baton_log_corrupted_reinit
echo ""
echo "--- セキュリティ ---"
run_test "TC-T03-SEC-01: issue_number 整数以外 → exit 2"               test_tc_sec01_injection_exit2
echo ""
echo "=================================================="
echo "  結果: PASS=$PASS / FAIL=$FAIL / SKIP=$SKIP"
echo "=================================================="
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
