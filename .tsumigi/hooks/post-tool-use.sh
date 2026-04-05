#!/usr/bin/env bash
# .tsumigi/hooks/post-tool-use.sh
# VCKD Phase Gate Hook — PostToolUse で呼ばれる
# 環境変数:
#   VCKD_GATE_RESULT  = "PASS" | "FAIL" | ""
#   VCKD_FROM_PHASE   = "REQ" | "TDS" | "IMP" | "TEST" | "OPS"
#   VCKD_ISSUE_NUMBER = <整数>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
CONFIG_FILE=".vckd/config.yaml"

# 必須変数の確認
[[ -z "${VCKD_GATE_RESULT:-}" ]] && exit 0
[[ -z "${VCKD_FROM_PHASE:-}" ]] && exit 0
[[ -z "${VCKD_ISSUE_NUMBER:-}" ]] && exit 0

# VCKD_FROM_PHASE 許可リスト検証（REQ-010-AC-1）
[[ "$VCKD_FROM_PHASE" =~ ^(REQ|TDS|IMP|TEST|OPS|CHANGE)$ ]] \
  || { echo "ERROR: invalid VCKD_FROM_PHASE='$VCKD_FROM_PHASE' — allowed: REQ|TDS|IMP|TEST|OPS|CHANGE" >&2; exit 2; }

# VCKD_ISSUE_NUMBER が整数かチェック
[[ "$VCKD_ISSUE_NUMBER" =~ ^[0-9]+$ ]] || { echo "ERROR: VCKD_ISSUE_NUMBER is not a valid integer: $VCKD_ISSUE_NUMBER" >&2; exit 2; }

# harness.enabled チェック
if command -v yq &>/dev/null && [[ -f "$CONFIG_FILE" ]]; then
  HARNESS_ENABLED=$(yq '.harness.enabled' "$CONFIG_FILE" 2>/dev/null || echo "false")
else
  HARNESS_ENABLED="false"
fi
[[ "$HARNESS_ENABLED" != "true" ]] && exit 0

# phase-gate.sh をロード
source "$LIB_DIR/phase-gate.sh"

# フェーズ → 次フェーズ マッピング
declare -A NEXT_PHASE=(
  ["REQ"]="phase:tds"
  ["TDS"]="phase:imp"
  ["IMP"]="phase:test"
  ["TEST"]="phase:ops"
  ["OPS"]="phase:change"
  ["CHANGE"]="phase:done"
)

CURRENT_LABEL="phase:$(echo "$VCKD_FROM_PHASE" | tr '[:upper:]' '[:lower:]')"
NEXT_LABEL="${NEXT_PHASE[$VCKD_FROM_PHASE]:-}"

if [[ "$VCKD_GATE_RESULT" == "PASS" ]]; then
  if [[ -n "$NEXT_LABEL" ]]; then
    dispatch_baton "$VCKD_ISSUE_NUMBER" "$CURRENT_LABEL" "$NEXT_LABEL"
  fi
elif [[ "$VCKD_GATE_RESULT" == "FAIL" ]]; then
  BLOCKED_LABEL="blocked:$(echo "$VCKD_FROM_PHASE" | tr '[:upper:]' '[:lower:]')"
  emit_blocked "$VCKD_ISSUE_NUMBER" "$CURRENT_LABEL" "$BLOCKED_LABEL" "${VCKD_FAIL_REASON:-Phase Gate FAIL}"
fi

exit 0
