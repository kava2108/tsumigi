---
description: IMP をもとに GitHub PR を作成します。Executive Summary から PR タイトル・本文を自動生成し、レビューチェックリストを PR コメントに投稿します。
allowed-tools: Read, Glob, Bash, Write, TodoWrite, AskUserQuestion
argument-hint: "[issue-id] [--draft] [--base <branch>] [--post-checklist] [--issue <number>]"
---

# tsumigi pr

IMP の内容から GitHub PR を作成します。
drift スコア・整合性スコアを PR 本文に埋め込み、レビュアーが判断しやすい形で提示します。

# context

issue_id={{issue_id}}
draft={{draft}}
base_branch={{base_branch}}
post_checklist={{post_checklist}}
github_issue_number={{github_issue_number}}
imp_file=specs/{{issue_id}}/IMP.md
pr_number=（作成後に設定）

# step

- $ARGUMENTS を解析する：
  - `--draft` フラグを確認し draft に設定
  - `--base` の後の値を base_branch に設定（デフォルト: main）
  - `--post-checklist` フラグを確認し post_checklist に設定
  - `--issue` の後の数値を github_issue_number に設定
- issue_id の解決：
  - $ARGUMENTS の最初のトークンが指定されている場合はそれを issue_id に設定する
  - 未指定の場合は Bash で `git branch --show-current 2>/dev/null` を実行し、
    `feature/`, `feat/`, `fix/`, `hotfix/`, `chore/` などのプレフィックスを除いた値を issue_id に設定する
  - issue_id が取得できない場合は「issue-id を指定するか、feature/NNN-name 形式のブランチに切り替えてください」と言って終了する
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 前提チェック

- `specs/{{issue_id}}/IMP.md` の存在を確認する
  - 存在しない場合：「先に `/tsumigi:imp_generate {{issue_id}}` を実行してください」と言って終了する
- IMP.md を Read する（imp_version, Executive Summary, status を取得する）
- Bash で現在のブランチを確認する：
  ```bash
  git branch --show-current 2>/dev/null
  ```
- Bash で未コミットの変更がないか確認する：
  ```bash
  git status --short 2>/dev/null
  ```
  - 未コミットの変更がある場合：「未コミットの変更があります。コミット後に再実行してください」と警告を表示する
- step3 を実行する

## step3: スコアの収集

- `specs/{{issue_id}}/drift-report.md` が存在する場合 Read し、drift_score を取得する（存在しない場合は "未計測"）
- `specs/{{issue_id}}/sync-report.md` が存在する場合 Read し、consistency_score を取得する（存在しない場合は "未計測"）
- `specs/{{issue_id}}/implements/` 以下から最後に使われた impl_mode を確認する（tdd/direct/不明）
- step4 を実行する

## step4: PR タイトル・本文の生成

- IMP の Executive Summary の1行目を PR タイトルに使用する
  - フォーマット: `[{{issue_id}}] {{executive_summary_first_line}}`
- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/pr-body-template.md`
  - `.claude/commands/tsumigi/templates/pr-body-template.md`
- テンプレートの以下の変数を置換する：
  - `{{executive_summary}}` → IMP の Executive Summary 全文（3行以内）
  - `{{github_issue_number}}` → github_issue_number（不明の場合は行ごと削除）
  - `{{imp_version}}` → IMP のバージョン
  - `{{drift_score}}` → 収集した drift_score
  - `{{sync_score}}` → 収集した consistency_score
  - `{{impl_mode}}` → 実装モード
  - `{{issue_id}}` → issue_id
- 生成した PR タイトルと本文をユーザーに確認する：
  - AskUserQuestion ツールで確認する：
    - question: "この内容で PR を作成しますか？"
    - options: ["作成する", "タイトルを修正する", "本文を修正する", "中断する"]
  - 修正を求められた場合は修正して再確認する
  - 「中断する」が選ばれた場合は終了する
- step5 を実行する

## step5: PR の作成

- Bash で PR を作成する：
  ```bash
  gh pr create \
    --title "<PR タイトル>" \
    --body "<PR 本文>" \
    --base {{base_branch}} \
    $([ "{{draft}}" = "true" ] && echo "--draft") \
    2>&1
  ```
- 作成成功時：
  - PR URL を取得して表示する
  - PR 番号を context の pr_number に設定する
  - 「✅ PR を作成しました: <URL>」と表示する
- 作成失敗時：
  - エラー内容を表示し、手動で PR を作成するよう案内して終了する
- step6 を実行する

## step6: レビューチェックリストの PR コメント投稿

post_checklist が true の場合、または `specs/{{issue_id}}/review-checklist.md` が存在する場合は実行する：

- `specs/{{issue_id}}/review-checklist.md` が存在するか確認する
  - 存在しない場合：「レビューチェックリストが未生成です。`/tsumigi:review {{issue_id}}` を先に実行することを推奨します」と案内してスキップする
  - 存在する場合：ファイルを Read する
- Bash で PR にコメントとして投稿する：
  ```bash
  gh pr comment {{pr_number}} --body "$(cat specs/{{issue_id}}/review-checklist.md)" 2>&1
  ```
- 投稿成功時：「📋 レビューチェックリストを PR コメントに投稿しました」と表示する
- step7 を実行する

## step7: Issue へのコメント投稿

github_issue_number が設定されている場合のみ実行する：

- Bash で Issue に PR 作成を通知する：
  ```bash
  gh issue comment {{github_issue_number}} --body "$(cat <<'EOF'
  ## 🔗 PR を作成しました

  PR #{{pr_number}} を作成しました。

  | 項目 | 値 |
  |---|---|
  | PR | #{{pr_number}} |
  | drift スコア | {{drift_score}}/100 |
  | 整合性スコア | {{sync_score}}/100 |

  レビューをお願いします。
  EOF
  )" 2>/dev/null
  ```
- 成功した場合：「Issue #{{github_issue_number}} に PR 作成を通知しました」と表示する
- 失敗した場合：スキップする（エラーは表示しない）

## step8: 完了通知

- 以下を表示する：
  ```
  ✅ pr 完了: {{issue_id}}

  PR: <URL>
  ベースブランチ: {{base_branch}}
  ドラフト: {{draft}}

  次のステップ:
    レビュー資料の生成（未実施の場合）:
      /tsumigi:review {{issue_id}} --pr {{pr_number}}
    マージ前の最終確認:
      /tsumigi:drift_check {{issue_id}}
      /tsumigi:sync {{issue_id}} --report-only
  ```

- TodoWrite ツールでタスクを完了にマークする
