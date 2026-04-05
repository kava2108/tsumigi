#!/usr/bin/env bash
# .tsumigi/lib/on-label-added.sh
# approve ラベル付与時に pending:next-phase を解除して次フェーズへ移行するハンドラ
# 使用方法: source .tsumigi/lib/phase-gate.sh && on_label_added <issue_number> <label_name>

set -euo pipefail

BATON_LOG="graph/baton-log.json"
CONFIG_FILE=".vckd/config.yaml"

# phase-gate.sh をロード（同じ lib/ ディレクトリから）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/phase-gate.sh"

# ============================================================
# on_label_added ヘルパー関数（SRP 準拠のため責務を分割）
# ============================================================

# _validate_approve_request: approve 前提条件を確認し next_candidate を stdout に出力する
# 引数: $1=issue_number $2=pending_label
# 戻り値: 0=OK（stdout に next_candidate）/ 1=前提条件エラー
_validate_approve_request() {
  local issue_number="$1"
  local pending_label="$2"

  # pending_label が Issue に存在するか確認
  local issue_labels
  issue_labels=$(gh issue view "$issue_number" --json labels \
    --jq '.labels[].name' 2>/dev/null || echo "")

  if ! echo "$issue_labels" | grep -q "^${pending_label}$"; then
    gh issue comment "$issue_number" --body "$(cat <<EOF
## ⚠️ VCKD: 承認エラー

\`approve\` ラベルが付与されましたが、\`${pending_label}\` ラベルが見つかりません。

バトンが保留状態ではないため、承認処理をスキップしました。

**確認**: 先に Phase Gate を実行してから approve を付与してください。
EOF
)" 2>/dev/null || true
    return 1
  fi

  # baton-log.json から next_candidate を取得
  local next_candidate
  next_candidate=$(jq -r --arg issue "$issue_number" \
    '.pending[$issue].next // empty' "$BATON_LOG" 2>/dev/null || echo "")

  if [[ -z "$next_candidate" ]]; then
    gh issue comment "$issue_number" --body "$(cat <<EOF
## ⚠️ VCKD: 承認エラー

\`baton-log.json\` に Issue #${issue_number} の保留エントリが見つかりません。

**対処**: \`/tsumigi:baton-status ${issue_number}\` で状態を確認してください。
EOF
)" 2>/dev/null || true
    return 1
  fi

  echo "$next_candidate"
}

# _update_github_labels_for_approval: approve/pending 削除・次フェーズラベル追加
# 引数: $1=issue_number $2=approve_label $3=pending_label $4=next_candidate
# 戻り値: 0=OK / 1=ラベル追加失敗
_update_github_labels_for_approval() {
  local issue_number="$1"
  local approve_label="$2"
  local pending_label="$3"
  local next_candidate="$4"

  _gh_with_retry issue edit "$issue_number" \
    --remove-label "$approve_label" 2>/dev/null || true
  _gh_with_retry issue edit "$issue_number" \
    --remove-label "$pending_label" 2>/dev/null || true

  if ! _gh_with_retry issue edit "$issue_number" \
       --add-label "$next_candidate" 2>/dev/null; then
    echo "ERROR: Failed to add next label $next_candidate to issue #$issue_number" >&2
    gh issue edit "$issue_number" --add-label "blocked:escalate" 2>/dev/null || true
    return 1
  fi
}

# _finalize_baton_for_approval: baton-log の pending 削除と遷移ログ追記
# 引数: $1=issue_number $2=pending_label $3=next_candidate
_finalize_baton_for_approval() {
  local issue_number="$1"
  local pending_label="$2"
  local next_candidate="$3"

  local tmp
  tmp=$(mktemp)
  jq --arg issue "$issue_number" \
     'del(.pending[$issue])' \
     "$BATON_LOG" > "$tmp" && mv "$tmp" "$BATON_LOG"

  _append_transition "$issue_number" "$pending_label" "$next_candidate" "manual" "human_approve"
}

# _notify_approval: 承認完了コメントを投稿する
# 引数: $1=issue_number $2=approve_label $3=pending_label $4=next_candidate
_notify_approval() {
  local issue_number="$1"
  local approve_label="$2"
  local pending_label="$3"
  local next_candidate="$4"

  _gh_with_retry issue comment "$issue_number" --body "$(cat <<EOF
## ✅ VCKD: 承認完了

フェーズ移行が承認されました。

| 項目 | 値 |
|---|---|
| 承認ラベル除去 | \`${approve_label}\` |
| 保留ラベル除去 | \`${pending_label}\` |
| 次フェーズ | \`${next_candidate}\` |
| モード | manual（人間承認） |
EOF
)" 2>/dev/null || true
}

# on_label_added: ラベル付与イベントのハンドラ（単一責任: フロー制御のみ）
# 引数: $1=issue_number $2=label_name
on_label_added() {
  _check_harness_enabled || return 0

  local issue_number="$1"
  local label_name="$2"

  # approve_label 以外は無視
  local approve_label
  approve_label=$(_get_approve_label)
  [[ "$label_name" == "$approve_label" ]] || return 0

  _ensure_baton_log

  local pending_label next_candidate
  pending_label=$(_get_pending_label)

  # 前提条件バリデーション（next_candidate を取得）
  next_candidate=$(_validate_approve_request "$issue_number" "$pending_label") || return 1

  # GitHub ラベル操作
  _update_github_labels_for_approval \
    "$issue_number" "$approve_label" "$pending_label" "$next_candidate" || return 1

  # baton-log 更新
  _finalize_baton_for_approval "$issue_number" "$pending_label" "$next_candidate"

  # 承認完了通知
  _notify_approval "$issue_number" "$approve_label" "$pending_label" "$next_candidate"
}

# スクリプトとして直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <issue_number> <label_name>" >&2
    exit 1
  fi
  on_label_added "$1" "$2"
fi
