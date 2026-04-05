#!/usr/bin/env bash
# T01 Baton Infrastructure テストスクリプト
# 実行: bash specs/tsumigi-v3-harness/tests/T01/test_baton_infra.sh
#
# 前提: jq が利用可能であること
# テスト対象: .tsumigi/lib/phase-gate.sh
#   - emit_baton: baton-log.json への遷移記録
#   - dispatch_baton: AUTO_STEP フラグに応じた emit_pending / emit_baton 分岐
#
# 設計ポイント:
#  - T03 と同じパターン（サブシェル + ファイルベーススパイ + export -f mock_gh）
#  - source 後に _check_harness_enabled を上書きしてハーネステストモードを有効化

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
PHASE_GATE_LIB="$REPO_ROOT/.tsumigi/lib/phase-gate.sh"

if [[ ! -f "$PHASE_GATE_LIB" ]]; then
  echo "ERROR: phase-gate.sh not found at $PHASE_GATE_LIB" >&2
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
# TC-T01-02: emit_baton 実行後に baton-log.json に遷移が記録される
# ============================================================
test_tc02_emit_baton_writes_transition() {
  local d
  d=$(_make_test_env)

  (
    cd "$d"
    export VCKD_TEST_MODE=1
    mock_gh() { return 0; }
    export -f mock_gh

    # shellcheck source=/dev/null
    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }

    emit_baton 42 "phase:req" "phase:tds"
  )

  local count from_label to_label
  count=$(jq '.transitions | length' "$d/graph/baton-log.json" 2>/dev/null || echo "0")
  from_label=$(jq -r '.transitions[0].from_label // ""' "$d/graph/baton-log.json" 2>/dev/null || echo "")
  to_label=$(jq -r '.transitions[0].to_label // ""' "$d/graph/baton-log.json" 2>/dev/null || echo "")
  rm -rf "$d"

  [[ "$count" == "1" ]] && [[ "$from_label" == "phase:req" ]] && [[ "$to_label" == "phase:tds" ]]
}

# ============================================================
# TC-T01-03: AUTO_STEP=false の場合 dispatch_baton が emit_pending を呼ぶ
# ============================================================
test_tc03_dispatch_baton_auto_step_false() {
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
    _check_harness_enabled() { return 0; }
    _get_auto_step() { echo "false"; }

    emit_pending() { echo "emit_pending" >> "$CALL_LOG"; return 0; }
    emit_baton()   { echo "emit_baton"   >> "$CALL_LOG"; return 0; }

    dispatch_baton 42 "phase:req" "phase:tds"
  )

  local called_pending=0 called_baton=0
  grep -q "^emit_pending$" "$call_log" 2>/dev/null && called_pending=1
  grep -q "^emit_baton$"   "$call_log" 2>/dev/null && called_baton=1
  rm -rf "$d"

  [[ "$called_pending" == "1" ]] && [[ "$called_baton" == "0" ]]
}

# ============================================================
# TC-T01-04: config.yaml が存在しない場合 AUTO_STEP=false にフォールバックする
# ============================================================
test_tc04_no_config_fallback_emit_pending() {
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

    # shellcheck source=/dev/null
    source "$PHASE_GATE_LIB"
    _check_harness_enabled() { return 0; }
    # emit_ 関数をスパイ（ファイルに記録）
    emit_pending() { echo "emit_pending" >> "$CALL_LOG"; return 0; }
    emit_baton()   { echo "emit_baton"   >> "$CALL_LOG"; return 0; }

    dispatch_baton 42 "phase:req" "phase:tds"
  )

  local called_pending=0
  grep -q "^emit_pending$" "$call_log" 2>/dev/null && called_pending=1
  rm -rf "$d"

  [[ "$called_pending" == "1" ]]
}

# ============================================================
# TC-T01-SEC-01: issue_number に非整数が渡された場合 exit 2 で拒否される
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

    # shellcheck source=/dev/null
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
echo "  T01 Baton Infrastructure テストスイート"
echo "=================================================="
echo ""
echo "--- 正常系 ---"
run_test "TC-T01-02: emit_baton → baton-log.json に遷移記録"        test_tc02_emit_baton_writes_transition
run_test "TC-T01-03: AUTO_STEP=false → emit_pending 呼出"           test_tc03_dispatch_baton_auto_step_false
echo ""
echo "--- 異常系 ---"
run_test "TC-T01-04: config.yaml 不在 → emit_pending フォールバック" test_tc04_no_config_fallback_emit_pending
echo ""
echo "--- セキュリティ ---"
run_test "TC-T01-SEC-01: issue_number 整数以外 → exit 2"            test_tc_sec01_injection_exit2
echo ""
echo "=================================================="
echo "  結果: PASS=$PASS / FAIL=$FAIL / SKIP=$SKIP"
echo "=================================================="
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
