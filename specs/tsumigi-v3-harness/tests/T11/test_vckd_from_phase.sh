#!/usr/bin/env bash
# T11 VCKD_FROM_PHASE 許可リスト検証テストスクリプト
# 実行: bash specs/tsumigi-v3-harness/tests/T11/test_vckd_from_phase.sh
#
# 前提: bash 4.x 以降
# テスト対象:
#   - .tsumigi/lib/phase-gate.sh  : _validate_from_phase() + check_phase_gate() での呼び出し
#   - .tsumigi/hooks/post-tool-use.sh : VCKD_FROM_PHASE 許可リスト検証（exit 2）
#
# 設計ポイント:
#  - T03 と同じパターン（サブシェル + ファイルベーススパイ + export -f mock_gh）
#  - _validate_from_phase() は環境変数ではなく引数を受け取るため、直接呼び出しでテスト
#  - post-tool-use.sh は環境変数 VCKD_FROM_PHASE をサブシェルで検証

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
PHASE_GATE_LIB="$REPO_ROOT/.tsumigi/lib/phase-gate.sh"
POST_TOOL_HOOK="$REPO_ROOT/.tsumigi/hooks/post-tool-use.sh"

if [[ ! -f "$PHASE_GATE_LIB" ]]; then
  echo "ERROR: phase-gate.sh not found at $PHASE_GATE_LIB" >&2
  exit 1
fi

if [[ ! -f "$POST_TOOL_HOOK" ]]; then
  echo "ERROR: post-tool-use.sh not found at $POST_TOOL_HOOK" >&2
  exit 1
fi

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
# 共通: テスト用一時環境を作成する
# ============================================================
_make_test_env() {
  local d
  d=$(mktemp -d)
  mkdir -p "$d/.vckd" "$d/graph" "$d/specs/tsumigi-v3-harness" "$d/.kiro/specs/my-feature"
  echo '{"version":"1.0.0","transitions":[],"pending":{}}' > "$d/graph/baton-log.json"
  echo "$d"
}

# ============================================================
# TC-T11-01: _validate_from_phase が許可リスト内の全フェーズを通過させる
# ============================================================
test_tc01_valid_phases_pass() {
  local d
  d=$(_make_test_env)
  local all_ok=1

  for phase in REQ TDS IMP TEST OPS CHANGE; do
    (
      cd "$d"
      export VCKD_TEST_MODE=1
      mock_gh() { return 0; }
      export -f mock_gh
      # shellcheck source=/dev/null
      source "$PHASE_GATE_LIB"
      _validate_from_phase "$phase"
    ) 2>/dev/null
    [[ $? -eq 0 ]] || all_ok=0
  done

  rm -rf "$d"
  [[ "$all_ok" == "1" ]]
}

# ============================================================
# TC-T11-02: _validate_from_phase が空文字のとき exit 0 でスキップする（REQ-010-AC-2）
# ============================================================
test_tc02_empty_phase_skips() {
  local d
  d=$(_make_test_env)
  local retval

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    mock_gh() { return 0; }
    export -f mock_gh
    # shellcheck source=/dev/null
    source "$PHASE_GATE_LIB"
    _validate_from_phase ""
  ) 2>/dev/null
  retval=$?

  rm -rf "$d"
  [[ "$retval" == "0" ]]
}

# ============================================================
# TC-T11-03: _validate_from_phase が不正値で return 2 する（REQ-010-AC-1）
# ============================================================
test_tc03_invalid_phase_returns_2() {
  local d
  d=$(_make_test_env)
  local result_file="$d/result.txt"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    mock_gh() { return 0; }
    export -f mock_gh
    # shellcheck source=/dev/null
    source "$PHASE_GATE_LIB"
    set +e
    _validate_from_phase "DEPLOY"
    echo "retval=$?" >> "$result_file"
  ) 2>/dev/null

  local retval=""
  retval=$(grep -oP 'retval=\K[0-9]+' "$result_file" 2>/dev/null || echo "")
  rm -rf "$d"

  [[ "$retval" == "2" ]]
}

# ============================================================
# TC-T11-04: _validate_from_phase が小文字フェーズ名を拒否する
# ============================================================
test_tc04_lowercase_phase_rejected() {
  local d
  d=$(_make_test_env)
  local result_file="$d/result.txt"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    mock_gh() { return 0; }
    export -f mock_gh
    # shellcheck source=/dev/null
    source "$PHASE_GATE_LIB"
    set +e
    _validate_from_phase "req"
    echo "retval=$?" >> "$result_file"
  ) 2>/dev/null

  local retval=""
  retval=$(grep -oP 'retval=\K[0-9]+' "$result_file" 2>/dev/null || echo "")
  rm -rf "$d"

  [[ "$retval" == "2" ]]
}

# ============================================================
# TC-T11-05: check_phase_gate が不正な from_phase で return 2 する
# ============================================================
test_tc05_check_phase_gate_invalid_phase_returns_2() {
  local d
  d=$(_make_test_env)
  local result_file="$d/result.txt"

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    mock_gh() { return 0; }
    export -f mock_gh
    # shellcheck source=/dev/null
    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }

    set +e
    check_phase_gate "INVALID_PHASE" "my-feature" "tsumigi-v3-harness"
    echo "retval=$?" >> "$result_file"
  ) 2>/dev/null

  local retval=""
  retval=$(grep -oP 'retval=\K[0-9]+' "$result_file" 2>/dev/null || echo "")
  rm -rf "$d"

  [[ "$retval" == "2" ]]
}

# ============================================================
# TC-T11-SEC-01: post-tool-use.sh が不正な VCKD_FROM_PHASE で exit 2 する
# ============================================================
test_tc_sec01_post_tool_use_invalid_phase_exit2() {
  local d
  d=$(_make_test_env)
  local retval

  retval=$(
    cd "$d"
    export VCKD_GATE_RESULT="PASS"
    export VCKD_FROM_PHASE="INJECT;rm -rf /"
    export VCKD_ISSUE_NUMBER="42"
    bash "$POST_TOOL_HOOK" 2>/dev/null; echo $?
  )

  rm -rf "$d"
  [[ "$retval" == "2" ]]
}

# ============================================================
# TC-T11-SEC-02: post-tool-use.sh が全許可フェーズを正常通過させる
#  （許可リスト検証で正常フェーズが誤拒否されないことを確認）
# ============================================================
test_tc_sec02_post_tool_use_valid_phase_not_rejected() {
  local d
  d=$(_make_test_env)
  # harness.enabled=false の場合 post-tool-use.sh は exit 0 で終わる
  # → 2 以外であれば許可リスト検証は通過
  local retval
  retval=$(
    cd "$d"
    export VCKD_GATE_RESULT="PASS"
    export VCKD_FROM_PHASE="IMP"
    export VCKD_ISSUE_NUMBER="42"
    bash "$POST_TOOL_HOOK" 2>/dev/null; echo $?
  )

  rm -rf "$d"
  [[ "$retval" != "2" ]]
}

# ============================================================
# テスト実行
# ============================================================
echo ""
echo "=================================================="
echo "  T11 VCKD_FROM_PHASE 許可リスト検証テストスイート"
echo "=================================================="
echo ""
echo "--- 正常系（許可リスト内フェーズ）---"
run_test "TC-T11-01: 全許可フェーズ（REQ/TDS/IMP/TEST/OPS/CHANGE）が PASS" test_tc01_valid_phases_pass
run_test "TC-T11-02: 空文字のとき exit 0 でスキップ（REQ-010-AC-2）"         test_tc02_empty_phase_skips
echo ""
echo "--- 異常系（不正値）---"
run_test "TC-T11-03: 不正値「DEPLOY」→ return 2（REQ-010-AC-1）"             test_tc03_invalid_phase_returns_2
run_test "TC-T11-04: 小文字「req」→ return 2（大文字のみ許可）"              test_tc04_lowercase_phase_rejected
run_test "TC-T11-05: check_phase_gate に不正 from_phase → return 2"        test_tc05_check_phase_gate_invalid_phase_returns_2
echo ""
echo "--- セキュリティ ---"
run_test "TC-T11-SEC-01: post-tool-use.sh 不正 VCKD_FROM_PHASE → exit 2"   test_tc_sec01_post_tool_use_invalid_phase_exit2
run_test "TC-T11-SEC-02: post-tool-use.sh 正常フェーズ（IMP）は通過"        test_tc_sec02_post_tool_use_valid_phase_not_rejected
echo ""
echo "=================================================="
echo "  結果: PASS=$PASS / FAIL=$FAIL / SKIP=$SKIP"
echo "=================================================="
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
