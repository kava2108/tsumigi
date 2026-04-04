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

# on_label_added: ラベル付与イベントのハンドラ
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

  # pending_label が Issue に存在するか確認
  local pending_label
  pending_label=$(_get_pending_label)

  local issue_labels
  issue_labels=$(gh issue view "$issue_number" --json labels --jq '.labels[].name' 2>/dev/null || echo "")

  if ! echo "$issue_labels" | grep -q "^${pending_label}$"; then
    # pending_label がない場合はエラーコメントを投稿してリターン
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
  next_candidate=$(jq -r --arg issue "$issue_number" '.pending[$issue].next // empty' "$BATON_LOG" 2>/dev/null || echo "")

  if [[ -z "$next_candidate" ]]; then
    gh issue comment "$issue_number" --body "$(cat <<EOF
## ⚠️ VCKD: 承認エラー

\`baton-log.json\` に Issue #${issue_number} の保留エントリが見つかりません。

**対処**: \`/tsumigi:baton-status ${issue_number}\` で状態を確認してください。
EOF
)" 2>/dev/null || true
    return 1
  fi

  # approve_label を削除
  _gh_with_retry issue edit "$issue_number" \
    --remove-label "$approve_label" 2>/dev/null || true

  # pending_label を削除
  _gh_with_retry issue edit "$issue_number" \
    --remove-label "$pending_label" 2>/dev/null || true

  # next_candidate を追加
  if ! _gh_with_retry issue edit "$issue_number" \
       --add-label "$next_candidate" 2>/dev/null; then
    echo "ERROR: Failed to add next label $next_candidate to issue #$issue_number" >&2
    gh issue edit "$issue_number" --add-label "blocked:escalate" 2>/dev/null || true
    return 1
  fi

  # baton-log.json の pending エントリを削除
  local tmp
  tmp=$(mktemp)
  jq --arg issue "$issue_number" \
     'del(.pending[$issue])' \
     "$BATON_LOG" > "$tmp" && mv "$tmp" "$BATON_LOG"

  # 遷移ログに追記（mode: "manual" — 人間が approve した）
  _append_transition "$issue_number" "$pending_label" "$next_candidate" "manual" "human_approve"

  # 完了コメントを投稿
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

# スクリプトとして直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <issue_number> <label_name>" >&2
    exit 1
  fi
  on_label_added "$1" "$2"
fi
