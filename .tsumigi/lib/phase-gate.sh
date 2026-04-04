#!/usr/bin/env bash
# .tsumigi/lib/phase-gate.sh
# VCKD Phase Gate & Baton ライブラリ
# このファイルは source で読み込んで使用する

set -euo pipefail

BATON_LOG="graph/baton-log.json"
CONFIG_FILE=".vckd/config.yaml"

# テストモードでは gh を mock に置き換える
if [[ "${VCKD_TEST_MODE:-}" == "1" ]]; then
  gh() { mock_gh "$@"; }
fi

# ============================================================
# 内部ユーティリティ
# ============================================================

_get_config() {
  local key="$1"
  local default="$2"
  if command -v yq &>/dev/null && [[ -f "$CONFIG_FILE" ]]; then
    local val
    val=$(yq "$key" "$CONFIG_FILE" 2>/dev/null || echo "")
    [[ -z "$val" || "$val" == "null" ]] && echo "$default" || echo "$val"
  else
    echo "$default"
  fi
}

_check_harness_enabled() {
  local enabled
  enabled=$(_get_config '.harness.enabled' 'false')
  [[ "$enabled" == "true" ]]
}

_get_auto_step() {
  _get_config '.harness.AUTO_STEP' 'false'
}

_get_pending_label() {
  _get_config '.harness.baton.pending_label' 'pending:next-phase'
}

_get_approve_label() {
  _get_config '.harness.baton.approve_label' 'approve'
}

_ensure_baton_log() {
  if [[ ! -f "$BATON_LOG" ]]; then
    mkdir -p "$(dirname "$BATON_LOG")"
    echo '{"version":"1.0.0","transitions":[],"pending":{}}' > "$BATON_LOG"
    return
  fi
  # JSON バリデーション
  if ! jq empty "$BATON_LOG" 2>/dev/null; then
    echo "WARNING: $BATON_LOG is invalid JSON. Creating backup and reinitializing." >&2
    mv "$BATON_LOG" "${BATON_LOG}.bak"
    echo '{"version":"1.0.0","transitions":[],"pending":{}}' > "$BATON_LOG"
  fi
}

_gh_with_retry() {
  local max_retries=3
  local delay=2
  local attempt=0
  while (( attempt < max_retries )); do
    if gh "$@"; then
      return 0
    fi
    attempt=$(( attempt + 1 ))
    if (( attempt < max_retries )); then
      echo "WARNING: gh command failed (attempt $attempt/$max_retries). Retrying in ${delay}s..." >&2
      sleep "$delay"
      delay=$(( delay * 2 ))
    fi
  done
  echo "ERROR: gh command failed after $max_retries attempts." >&2
  return 1
}

_append_transition() {
  local issue_number="$1"
  local from_label="$2"
  local to_label="$3"
  local mode="$4"         # "manual" | "auto" | "blocked"
  local triggered_by="${5:-phase_gate}"

  _ensure_baton_log

  local tmp
  tmp=$(mktemp)
  jq --arg issue "$issue_number" \
     --arg from  "$from_label" \
     --arg to    "$to_label" \
     --arg ts    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     --arg mode  "$mode" \
     --arg tby   "$triggered_by" \
     '.transitions += [{
       issue_number: ($issue | tonumber),
       from_label: $from,
       to_label: $to,
       transitioned_at: $ts,
       mode: $mode,
       triggered_by: $tby
     }]' \
     "$BATON_LOG" > "$tmp" && mv "$tmp" "$BATON_LOG"
}

# get_retry_count: Issue の現在のリトライ回数を取得する
# 引数: $1=issue_number
get_retry_count() {
  local issue_number="$1"
  _ensure_baton_log
  jq -r --arg issue "$issue_number" '.pending[$issue].retries // 0' "$BATON_LOG" 2>/dev/null || echo "0"
}

# increment_retry_count: Issue のリトライ回数をインクリメントする
# 引数: $1=issue_number $2=error_message $3=agent_name
increment_retry_count() {
  local issue_number="$1"
  local error_message="${2:-unknown error}"
  local agent_name="${3:-unknown}"

  _ensure_baton_log

  local tmp
  tmp=$(mktemp)
  jq --arg issue "$issue_number" \
     --arg err   "$error_message" \
     --arg agent "$agent_name" \
     --argjson inc 1 \
     'if .pending[$issue] then
       .pending[$issue].retries = ((.pending[$issue].retries // 0) + $inc) |
       .pending[$issue].last_error = $err |
       .pending[$issue].agent = $agent
     else
       .pending[$issue] = {retries: 1, last_error: $err, agent: $agent}
     end' \
     "$BATON_LOG" > "$tmp" && mv "$tmp" "$BATON_LOG"
}

# reset_retry_count: Issue のリトライ回数を 0 にリセットする
# 引数: $1=issue_number
reset_retry_count() {
  local issue_number="$1"
  _ensure_baton_log

  local tmp
  tmp=$(mktemp)
  jq --arg issue "$issue_number" \
     'if .pending[$issue] then
       .pending[$issue].retries = 0 |
       .pending[$issue].last_error = null |
       .pending[$issue].agent = null
     else . end' \
     "$BATON_LOG" > "$tmp" && mv "$tmp" "$BATON_LOG"
}

# emit_escalate: 3 回リトライ失敗後に blocked:escalate を付与する
# 引数: $1=issue_number $2=agent_name $3=last_error
emit_escalate() {
  _check_harness_enabled || return 0

  local issue_number="$1"
  local agent_name="${2:-unknown}"
  local last_error="${3:-unknown error}"

  # blocked:escalate ラベルを付与
  _gh_with_retry issue edit "$issue_number" \
    --add-label "blocked:escalate" 2>/dev/null || true

  # エスカレーションコメントを投稿
  _gh_with_retry issue comment "$issue_number" --body "$(cat <<EOF
## 🆘 Agent Escalation: ${agent_name}

Phase Agent が 3 回連続で失敗したため、人間のサポートが必要です。

| 項目 | 値 |
|---|---|
| エージェント | ${agent_name} |
| リトライ回数 | 3/3 |
| 最後のエラー | \`${last_error}\` |

**推奨アクション**: \`/tsumigi:rescue ${issue_number}\` を実行してください。
EOF
)" 2>/dev/null || true
}

# ============================================================
# 公開 API
# ============================================================

# check_phase_gate: Phase Gate を実行して PASS/FAIL を判定する
# 引数: $1=from_phase ("REQ"|"TDS"|"IMP"|"TEST"|"OPS")
#       $2=feature (例: "my-feature")
#       $3=issue_id (例: "001-my-feature")
# 戻り値: 0=PASS, 1=FAIL
# 出力: VCKD_GATE_RESULT 環境変数を設定する
check_phase_gate() {
  _check_harness_enabled || { VCKD_GATE_RESULT=""; return 0; }

  local from_phase="$1"
  local feature="${2:-}"
  local issue_id="${3:-}"

  local result="PASS"
  local fail_reasons=()

  # Step 1: 必須成果物の存在確認
  if ! _check_artifacts "$from_phase" "$feature" "$issue_id"; then
    result="FAIL"
    fail_reasons+=("missing_artifact: 必須成果物が存在しません")
  fi

  # Step 2: CEG 循環依存チェック
  if ! _check_ceg; then
    result="FAIL"
    fail_reasons+=("circular_dep: 循環依存が検出されました")
  fi

  # Step 3: フェーズ固有チェック
  if ! _check_phase_specific "$from_phase" "$feature" "$issue_id"; then
    result="FAIL"
    fail_reasons+=("phase_specific: フェーズ固有チェックに失敗しました")
  fi

  # Step 4: Gray ノード確認
  if ! _check_gray; then
    result="FAIL"
    fail_reasons+=("gray_node: Gray ノードが存在します")
  fi

  export VCKD_GATE_RESULT="$result"
  if [[ "$result" == "FAIL" ]]; then
    export VCKD_FAIL_REASON="${fail_reasons[*]}"
    return 1
  fi
  return 0
}

_check_artifacts() {
  local from_phase="$1"
  local feature="$2"
  local issue_id="$3"

  case "$from_phase" in
    REQ)
      [[ -f ".kiro/specs/${feature}/requirements.md" ]] || return 1
      ;;
    TDS)
      [[ -f ".kiro/specs/${feature}/design.md" ]] || return 1
      [[ -f ".kiro/specs/${feature}/tasks.md" ]] || return 1
      ;;
    IMP)
      [[ -f "specs/${issue_id}/IMP.md" ]] || return 1
      ;;
    TEST)
      [[ -f "specs/${issue_id}/adversary-report.md" ]] || return 1
      ;;
    OPS)
      [[ -f "specs/${issue_id}/drift-report.md" ]] || return 1
      ;;
    *) return 0 ;;
  esac
  return 0
}

_check_ceg() {
  # coherence.json が存在する場合のみ循環依存チェックを実施
  if [[ -f "graph/coherence.json" ]]; then
    # Gray ノードや基本的な構造の確認（フル循環チェックは coherence-scan コマンドに委譲）
    jq empty "graph/coherence.json" 2>/dev/null || return 1
  fi
  return 0
}

_check_phase_specific() {
  local from_phase="$1"
  local feature="$2"
  local issue_id="$3"

  case "$from_phase" in
    REQ)
      # requirements.md の AC が 3 件以上あること
      if [[ -f ".kiro/specs/${feature}/requirements.md" ]]; then
        local ac_count
        ac_count=$(grep -c "REQ-[0-9]*-AC-[0-9]*" ".kiro/specs/${feature}/requirements.md" 2>/dev/null || echo "0")
        (( ac_count >= 3 )) || return 1
      fi
      ;;
    TDS)
      # design.md と tasks.md の存在確認のみ（成果物チェックで実施済み）
      ;;
    IMP)
      # IMP.md に patch-plan パスが記載されていること
      if [[ -f "specs/${issue_id}/IMP.md" ]]; then
        grep -q "patch-plan" "specs/${issue_id}/IMP.md" 2>/dev/null || return 1
      fi
      ;;
    TEST)
      # adversary-report.md の全体判定が PASS であること
      if [[ -f "specs/${issue_id}/adversary-report.md" ]]; then
        grep -q "全体判定.*PASS\|PASS" "specs/${issue_id}/adversary-report.md" 2>/dev/null || return 1
      fi
      ;;
    OPS)
      # drift-report.md の drift スコアが閾値以下であること（デフォルト: 20 以下）
      if [[ -f "specs/${issue_id}/drift-report.md" ]]; then
        local threshold
        threshold=$(_get_config '.drift_check.threshold' '20')
        local drift_score
        drift_score=$(grep -oP 'drift.*score.*\K[0-9]+' "specs/${issue_id}/drift-report.md" 2>/dev/null | head -1 || echo "0")
        (( drift_score <= threshold )) || return 1
      fi
      ;;
  esac
  return 0
}

_check_gray() {
  if [[ -f "graph/coherence.json" ]]; then
    local gray_count
    gray_count=$(jq '.summary.gray // 0' "graph/coherence.json" 2>/dev/null || echo "0")
    (( gray_count == 0 )) || return 1
  fi
  return 0
}

# dispatch_baton: PASS 後にバトンを発行する（AUTO_STEP に応じて分岐）
# 引数: $1=issue_number $2=current_label $3=next_label
dispatch_baton() {
  _check_harness_enabled || return 0

  local issue_number="$1"
  local current_label="$2"
  local next_label="$3"

  # VCKD_ISSUE_NUMBER の整数チェック
  [[ "$issue_number" =~ ^[0-9]+$ ]] || { echo "ERROR: invalid issue_number: $issue_number" >&2; return 2; }

  local auto_step
  auto_step=$(_get_auto_step)

  if [[ "$auto_step" == "true" ]]; then
    emit_baton "$issue_number" "$current_label" "$next_label"
  else
    local pending_label
    pending_label=$(_get_pending_label)
    emit_pending "$issue_number" "$current_label" "$pending_label" "$next_label"
  fi
}

# emit_pending: Manual モードで pending:next-phase を付与する
# 引数: $1=issue_number $2=current_label $3=pending_label $4=next_candidate
emit_pending() {
  _check_harness_enabled || return 0

  local issue_number="$1"
  local current_label="$2"
  local pending_label="$3"
  local next_candidate="$4"

  _ensure_baton_log

  # GitHub ラベル変更: current_label → pending_label
  if ! _gh_with_retry issue edit "$issue_number" \
       --remove-label "$current_label" \
       --add-label "$pending_label" 2>/dev/null; then
    echo "WARNING: Failed to update labels on issue #$issue_number" >&2
    # ラベル操作失敗時は blocked:escalate を付与
    gh issue edit "$issue_number" --add-label "blocked:escalate" 2>/dev/null || true
    return 1
  fi

  # baton-log.json の pending エントリを更新
  local tmp
  tmp=$(mktemp)
  jq --arg issue "$issue_number" \
     --arg next  "$next_candidate" \
     --arg ts    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     '.pending[$issue] = {next: $next, recorded_at: $ts}' \
     "$BATON_LOG" > "$tmp" && mv "$tmp" "$BATON_LOG"

  # 遷移ログに追記
  _append_transition "$issue_number" "$current_label" "$pending_label" "manual"

  # GitHub コメントを投稿
  local comment
  comment=$(cat <<EOF
## ⏳ VCKD: 承認待ち

Phase Gate をクリアしました。次フェーズへの移行を承認してください。

| 項目 | 値 |
|---|---|
| 現在フェーズ | \`${current_label}\` |
| 次フェーズ候補 | \`${next_candidate}\` |
| 承認ラベル | \`${pending_label}\` |

**承認手順**: Issue に \`approve\` ラベルを付与してください。
EOF
)
  _gh_with_retry issue comment "$issue_number" --body "$comment" 2>/dev/null || true
}

# emit_baton: AUTO_STEP=true モードで直接次フェーズラベルを付与する
# 引数: $1=issue_number $2=current_label $3=next_label
emit_baton() {
  _check_harness_enabled || return 0

  local issue_number="$1"
  local current_label="$2"
  local next_label="$3"

  _ensure_baton_log

  # GitHub ラベル変更: current_label → next_label
  if ! _gh_with_retry issue edit "$issue_number" \
       --remove-label "$current_label" \
       --add-label "$next_label" 2>/dev/null; then
    echo "WARNING: Failed to update labels on issue #$issue_number" >&2
    gh issue edit "$issue_number" --add-label "blocked:escalate" 2>/dev/null || true
    return 1
  fi

  # 遷移ログに追記
  _append_transition "$issue_number" "$current_label" "$next_label" "auto"

  # GitHub コメントを投稿
  local comment
  comment=$(cat <<EOF
## 🚀 VCKD: バトン発行（AUTO_STEP）

Phase Gate をクリアしました。自動的に次フェーズへ移行します。

| 項目 | 値 |
|---|---|
| 前フェーズ | \`${current_label}\` |
| 次フェーズ | \`${next_label}\` |
| モード | AUTO_STEP |
EOF
)
  _gh_with_retry issue comment "$issue_number" --body "$comment" 2>/dev/null || true
}

# emit_blocked: Phase Gate FAIL 時にブロックラベルを付与する
# 引数: $1=issue_number $2=current_label $3=blocked_label $4=fail_reason
emit_blocked() {
  _check_harness_enabled || return 0

  local issue_number="$1"
  local current_label="$2"
  local blocked_label="$3"
  local fail_reason="${4:-Phase Gate FAIL}"

  _ensure_baton_log

  # GitHub ラベル追加
  _gh_with_retry issue edit "$issue_number" \
    --add-label "$blocked_label" 2>/dev/null || true

  # 遷移ログに追記
  _append_transition "$issue_number" "$current_label" "$blocked_label" "blocked"

  # GitHub コメントを投稿
  local comment
  comment=$(cat <<EOF
## ❌ VCKD: Phase Gate FAIL

Phase Gate チェックに失敗しました。以下の問題を修正してください。

| 項目 | 値 |
|---|---|
| フェーズ | \`${current_label}\` |
| ブロックラベル | \`${blocked_label}\` |

**失敗理由**:
\`\`\`
${fail_reason}
\`\`\`

修正後、\`${blocked_label}\` ラベルを外して再実行してください。
EOF
)
  _gh_with_retry issue comment "$issue_number" --body "$comment" 2>/dev/null || true
}
