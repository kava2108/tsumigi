#!/usr/bin/env bash
# T04 Phase Agent テストスクリプト
# 実行: bash specs/tsumigi-v3-harness/tests/T04/test_phase_agent.sh
#
# 前提: bash 4.x 以降、grep が利用可能であること
# テスト対象: .tsumigi/agents/ 以下の Phase Agent プロンプトファイル
#   - requirements-agent.md: REQ フェーズ
#   - design-agent.md: TDS フェーズ
#   - implement-agent.md: IMP フェーズ
#
# テスト方針:
#  - エージェントプロンプト（.md ファイル）の存在確認とコンテンツ検証
#  - e2e テスト（Claude Code 実行による成果物生成確認）は SKIP
#  - セキュリティTC: コンテキスト分離・プロンプトインジェクション防止の仕様確認

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
AGENTS_DIR="$REPO_ROOT/.tsumigi/agents"

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
# TC-T04-01: requirements-agent.md が存在し EARS 形式変換の記述を含む
# （TC本体: RequirementsAgent 起動後に requirements.md が生成される — e2e は SKIP）
# ============================================================
test_tc01_requirements_agent_exists() {
  local file="$AGENTS_DIR/requirements-agent.md"
  [[ -f "$file" ]] && grep -q "EARS" "$file"
}

# ============================================================
# TC-T04-02: design-agent.md が存在し design.md / tasks.md 生成の記述を含む
# （TC本体: DesignAgent 起動後に design.md と tasks.md が生成される — e2e は SKIP）
# ============================================================
test_tc02_design_agent_exists() {
  local file="$AGENTS_DIR/design-agent.md"
  [[ -f "$file" ]] && grep -q "design\.md" "$file" && grep -q "tasks\.md" "$file"
}

# ============================================================
# TC-T04-03: implement-agent.md が imp_generate を先行実行する記述を含む
# ============================================================
test_tc03_implement_agent_runs_imp_generate_first() {
  local file="$AGENTS_DIR/implement-agent.md"
  # IMP.md が不在の場合に imp_generate を実行してから再開することが明記されている
  grep -q "imp_generate" "$file" 2>/dev/null
}

# ============================================================
# TC-T04-04: implement-agent.md が P0 完了後の P1 Issue への phase:imp 付与を含む
# ============================================================
test_tc04_implement_agent_p0_to_p1_transition() {
  local file="$AGENTS_DIR/implement-agent.md"
  # P1 タスクの Issue に phase:imp ラベルを付与するロジックが明記されている
  grep -q "phase:imp" "$file" 2>/dev/null && grep -q "P1" "$file" 2>/dev/null
}

# ============================================================
# TC-T04-SEC-01: requirements-agent.md が他 Issue のファイル読み取りを禁止している
#  （コンテキスト汚染防止 = プロンプトインジェクション対策）
# ============================================================
test_tc_sec01_requirements_agent_context_isolation() {
  local file="$AGENTS_DIR/requirements-agent.md"
  # 「読んではいけないもの」セクションと「コンテキスト汚染防止」の記述を確認
  grep -q "読んではいけない" "$file" 2>/dev/null && \
  grep -q "コンテキスト汚染防止\|他の Issue" "$file" 2>/dev/null
}

# ============================================================
# TC-T04-SEC-02: implement-agent.md が実装前に adversary-report.md の
#  読み取りを禁止している（実装フェーズのコンテキスト分離）
# ============================================================
test_tc_sec02_implement_agent_no_adversary_before_impl() {
  local file="$AGENTS_DIR/implement-agent.md"
  # adversary-report.md が「読んではいけないもの」として明記されている
  grep -q "adversary-report" "$file" 2>/dev/null && \
  grep -q "読んではいけない" "$file" 2>/dev/null
}

# ============================================================
# テスト実行
# ============================================================
echo ""
echo "=================================================="
echo "  T04 Phase Agent テストスイート"
echo "=================================================="
echo ""
echo "--- 正常系（存在確認・コンテンツ検証）---"
run_test "TC-T04-01: requirements-agent.md 存在 + EARS 言及"          test_tc01_requirements_agent_exists
run_test "TC-T04-02: design-agent.md 存在 + design.md/tasks.md 言及" test_tc02_design_agent_exists
run_test "TC-T04-03: implement-agent.md が imp_generate 先行実行を明記" test_tc03_implement_agent_runs_imp_generate_first
run_test "TC-T04-04: implement-agent.md が P0→P1 の phase:imp 付与を明記" test_tc04_implement_agent_p0_to_p1_transition
echo ""
skip_test "TC-T04-01 e2e: RequirementsAgent → requirements.md 生成" "Claude Code e2e は手動実行が必要"
skip_test "TC-T04-02 e2e: DesignAgent → design.md / tasks.md 生成"  "Claude Code e2e は手動実行が必要"
echo ""
echo "--- セキュリティ（コンテキスト分離・プロンプトインジェクション防止）---"
run_test "TC-T04-SEC-01: requirements-agent.md 他 Issue 読み取り禁止"    test_tc_sec01_requirements_agent_context_isolation
run_test "TC-T04-SEC-02: implement-agent.md adversary-report 実装前禁止" test_tc_sec02_implement_agent_no_adversary_before_impl
echo ""
echo "=================================================="
echo "  結果: PASS=$PASS / FAIL=$FAIL / SKIP=$SKIP"
echo "=================================================="
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
