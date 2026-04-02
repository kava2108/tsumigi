---
description: GitHub Issue または自然言語の課題記述から、構造化タスク定義・note.md を生成します。IMP 生成のインプットとなる成果物を作成します。
allowed-tools: Read, Glob, Grep, Write, Edit, TodoWrite, WebFetch, Bash, AskUserQuestion
argument-hint: "<issue-id> [issue-url-or-text] [--scope full|lite]"
---

# tsumigi issue_init

Issue を構造化し、IMP 生成のインプットとなるタスク定義と技術コンテキストノートを作成します。
再実行は安全です（冪等）。既存ファイルには差分マージを行います。

# context

issue_id={{issue_id}}
issue_source={{issue_source}}
scope={{scope}}
出力ベース=specs/{{issue_id}}
issue_struct_file=specs/{{issue_id}}/issue-struct.md
tasks_file=specs/{{issue_id}}/tasks.md
note_file=specs/{{issue_id}}/note.md
信頼性評価=[]

# step

- $ARGUMENTS がない場合は「引数に issue-id を指定してください（例: /tsumigi:issue_init GH-123）」と言って終了する
- $ARGUMENTS を解析する：
  - `--scope full` または `--scope lite` を確認し context に設定（デフォルト: full）
  - 最初のトークンを issue_id に設定
  - 残りのテキストを issue_source に設定
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 冪等チェック（既存成果物の確認）

- `specs/{{issue_id}}/issue-struct.md` が存在するか確認する
  - 存在する場合：
    - ファイルを Read する
    - 「既存の構造化定義が見つかりました。差分更新モードで実行します」と表示する
  - 存在しない場合：
    - 「新規作成モードで実行します」と表示する
- step3 を実行する

## step3: Issue 内容の取得

issue_source と issue_id の内容に応じて処理を分岐する：

**GitHub Issue の場合**（issue_id が `GH-NNN` 形式、または issue_source に `github.com/*/issues/` を含む）:

- issue 番号を特定する：
  - `GH-123` → `123`
  - GitHub URL → URL 末尾の数字
- Bash で `gh issue view <番号> --json number,title,body,labels,assignees,milestone,comments 2>/dev/null` を実行する
  - 成功した場合：title, body, labels, assignees, milestone, comments を context に取り込む
  - 失敗した場合（gh 未設定・権限なし等）：WebFetch にフォールバックし Issue URL を取得する
- 取得した Issue のメタデータをまとめて表示する：
  ```
  📋 GitHub Issue #{{番号}} を取得しました
  タイトル: {{title}}
  ラベル:   {{labels}}
  担当者:   {{assignees}}
  ```

**テキストが指定されている場合**:
- そのテキストを課題内容として使用する

**未指定の場合**:
- AskUserQuestion ツールを使って質問する：
  - question: "Issue の内容を教えてください（GitHub URL またはテキストで）"
  - header: "Issue 内容"
  - multiSelect: false

- step4 を実行する

## step4: スコープ確認

- scope が未設定の場合、AskUserQuestion ツールを使って質問する：
  - question: "Issue 分解の詳細度を選択してください"
  - header: "分解スコープ"
  - multiSelect: false
  - options:
    - label: "full（推奨）"
      description: "詳細な受け入れ基準・EARS記法・非機能要件・エッジケース・リスクを含む完全な分解"
    - label: "lite"
      description: "最小限のタスク定義のみ。素早く IMP 生成に進みたい場合"
  - 選択結果を context の {{scope}} に保存する

## step5: プロジェクトコンテキストの収集

- 以下のファイルを存在する場合に読み込む：
  - `docs/tsumigi-context.md`（プロジェクト技術スタック概要）
  - `.tsumigi/config.json`（tsumigi 設定）
  - `TSUMIGI.md`（プロジェクト固有ワークフロー）
  - `README.md` または `CLAUDE.md`（プロジェクト概要）

- 既存 IMP ファイルを Glob で確認する：`specs/**/IMP.md`
  - 依存関係にある Issue の IMP があれば内容を把握する

## step6: 構造化 Issue 定義の生成

取得した Issue 内容をもとに `specs/{{issue_id}}/issue-struct.md` を生成する。
既存ファイルがある場合は差分マージし、変更箇所を明示する。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/issue-struct-template.md`
  - `.claude/commands/tsumigi/templates/issue-struct-template.md`
- テンプレートの変数（`{{issue_id}}`, `{{scope}}`, `{{ISO8601}}` 等）を実際の値で置換する
- Issue の内容に基づいて各セクションを埋めて `specs/{{issue_id}}/issue-struct.md` を Write する

## step7: タスク分解の生成

`specs/{{issue_id}}/tasks.md` を生成する（既存の場合は差分マージ）。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/tasks-template.md`
  - `.claude/commands/tsumigi/templates/tasks-template.md`
- テンプレートの変数を置換し、Issue から分解したタスクを埋めて `specs/{{issue_id}}/tasks.md` を Write する

## step8: 技術コンテキストノートの生成

`specs/{{issue_id}}/note.md` を生成する（既存の場合はスキップ）。
このファイルは後続の全 Skill が参照するコンテキストの集約場所となる。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/note-template.md`
  - `.claude/commands/tsumigi/templates/note-template.md`
- テンプレートの変数を置換し、プロジェクト探索で得た技術コンテキストを埋めて `specs/{{issue_id}}/note.md` を Write する

## step9: 品質チェックと完了通知

- 生成した issue-struct.md の品質を評価する：
  - 🔴 不明項目が 3 件以上ある → 警告を表示する
  - 受け入れ基準が 0 件 → エラーとして表示する
  - タスクの循環依存がないか確認する

- 以下を表示する：
  ```
  ✅ issue_init 完了: {{issue_id}}

  生成ファイル:
    specs/{{issue_id}}/issue-struct.md
    specs/{{issue_id}}/tasks.md
    specs/{{issue_id}}/note.md

  品質サマリー:
    受け入れ基準: N 件
    タスク数: N 件
    🔵 確定: N 件 / 🟡 推定: N 件 / 🔴 不明: N 件

  次のステップ:
    /tsumigi:imp_generate {{issue_id}}
  ```

- 🔴 不明項目がある場合は「着手前に確認が必要な項目があります」と警告を表示する
- TodoWrite ツールでタスクを完了にマークする
- step10 を実行する

## step10: GitHub Issue へのコメント投稿

issue_id が `GH-NNN` 形式の場合のみ実行する：

- Bash で以下を実行する：
  ```bash
  gh issue comment <番号> --body "$(cat <<'EOF'
  ## 🤖 tsumigi: issue_init 完了

  Issue を構造化しました。次は IMP を生成してください。

  | 成果物 | パス |
  |---|---|
  | 構造化定義 | `specs/{{issue_id}}/issue-struct.md` |
  | タスク一覧 | `specs/{{issue_id}}/tasks.md` |
  | 技術ノート | `specs/{{issue_id}}/note.md` |

  **次のステップ**: `/tsumigi:imp_generate {{issue_id}}`
  EOF
  )" 2>/dev/null
  ```
- 成功した場合：「GitHub Issue #{{番号}} にコメントを投稿しました」と表示する
- 失敗した場合（権限なし等）：スキップして終了する（エラーは表示しない）
