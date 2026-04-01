---
description: GitHub Issue または自然言語の課題記述から、構造化タスク定義・note.md を生成します。IMP 生成のインプットとなる成果物を作成します。
allowed-tools: Read, Glob, Grep, Write, Edit, TodoWrite, WebFetch, AskUserQuestion
argument-hint: "<issue-id> [issue-url-or-text] [--scope full|lite]"
---

# tsumigi issue_init

Issue を構造化し、IMP 生成のインプットとなるタスク定義と技術コンテキストノートを作成します。
再実行は安全です（冪等）。既存ファイルには差分マージを行います。

# context

issue_id={{issue_id}}
issue_source={{issue_source}}
scope={{scope}}
出力ベース=docs/issues/{{issue_id}}
issue_struct_file=docs/issues/{{issue_id}}/issue-struct.md
tasks_file=docs/issues/{{issue_id}}/tasks.md
note_file=docs/issues/{{issue_id}}/note.md
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

- `docs/issues/{{issue_id}}/issue-struct.md` が存在するか確認する
  - 存在する場合：
    - ファイルを Read する
    - 「既存の構造化定義が見つかりました。差分更新モードで実行します」と表示する
  - 存在しない場合：
    - 「新規作成モードで実行します」と表示する
- step3 を実行する

## step3: Issue 内容の取得

- issue_source の内容に応じて処理を分岐する：

  **GitHub URL の場合**（`github.com` を含む、または `GH-` + 数字のみ）:
  - WebFetch ツールで Issue 本文・受け入れ基準・コメントを取得する
  - 取得できない場合はユーザーに課題内容を入力するよう求める

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

- 既存 IMP ファイルを Glob で確認する：`docs/imps/**/*.md`
  - 依存関係にある Issue の IMP があれば内容を把握する

## step6: 構造化 Issue 定義の生成

取得した Issue 内容をもとに、以下の構造で `docs/issues/{{issue_id}}/issue-struct.md` を生成する。
既存ファイルがある場合は差分マージし、変更箇所を明示する。

<issue_struct_template>
---
issue_id: {{issue_id}}
created_at: {{ISO8601}}
updated_at: {{ISO8601}}
scope: {{scope}}
status: structured
---

# Issue 構造定義: {{issue_id}}

## 1. 背景・動機（Why）
<!-- 信頼性: 🔵確定 / 🟡推定 / 🔴不明 -->

{{issue の背景・問題・動機を記述}}

## 2. 受け入れ基準（EARS 記法）

以下の形式で記述する：
- [WHEN/WHERE/IF/WHILE] {{条件}} [THE SYSTEM SHALL] {{振る舞い}}

| # | 条件 | 期待される振る舞い | 優先度 | 信頼性 |
|---|---|---|---|---|
| AC-001 | | | P0/P1/P2 | 🔵/🟡/🔴 |

## 3. スコープ定義

### 3.1 In Scope（今回の変更に含まれる）
- 

### 3.2 Out of Scope（今回の変更に含まれない）
- 

## 4. 非機能要件
<!-- full スコープの場合のみ -->

| 種別 | 要件 | 測定方法 | 信頼性 |
|---|---|---|---|
| パフォーマンス | | | 🔵/🟡/🔴 |
| セキュリティ | | | 🔵/🟡/🔴 |
| 可用性 | | | 🔵/🟡/🔴 |

## 5. 依存関係・前提条件

| 依存先 | 種別 | 状態 | 影響 |
|---|---|---|---|
| | Issue/IMP/外部 | 完了/進行中/未着手 | |

## 6. エッジケース・リスク
<!-- full スコープの場合のみ -->

| シナリオ | 影響 | 対策 |
|---|---|---|
| | H/M/L | |

## 7. 信頼性サマリー

- 🔵 確定項目: X 件
- 🟡 推定項目: Y 件（Issue に明記なし・推定で補完）
- 🔴 不明項目: Z 件（要確認・着手前にクリアが必要）
</issue_struct_template>

## step7: タスク分解の生成

`docs/issues/{{issue_id}}/tasks.md` を生成する（既存の場合は差分マージ）。

<tasks_template>
---
issue_id: {{issue_id}}
created_at: {{ISO8601}}
updated_at: {{ISO8601}}
total_tasks: N
---

# タスク一覧: {{issue_id}}

## タスクマップ

```
TASK-0001 → TASK-0002 → TASK-0003
               ↓
            TASK-0004
```

## タスク詳細

### TASK-0001: {{タスク名}}

**概要**: {{1 行の説明}}

**完了条件（EARS）**:
- [WHEN] ... [THE SYSTEM SHALL] ...

**作業内容**:
1.
2.

**推定規模**: S/M/L（S=半日, M=1日, L=2日以上）

**依存前提**: なし / TASK-XXXX 完了後

---

（以降、同形式で続く）

## 実行推奨順序

1. TASK-0001（依存なし）
2. TASK-0002（TASK-0001 完了後）
...
</tasks_template>

## step8: 技術コンテキストノートの生成

`docs/issues/{{issue_id}}/note.md` を生成する（既存の場合はスキップ）。
このファイルは後続の全 Skill が参照するコンテキストの集約場所となる。

<note_template>
---
issue_id: {{issue_id}}
created_at: {{ISO8601}}
purpose: 後続 Skill が参照する技術コンテキストの集約
---

# 技術コンテキストノート: {{issue_id}}

## 1. 技術スタック

- **言語**: {{検出された言語}}
- **フレームワーク**: {{検出されたFW}}
- **テストフレームワーク**: {{検出されたテストFW}}
- **パッケージマネージャー**: {{npm/yarn/pnpm/pip 等}}

## 2. 関連ファイル・ディレクトリ

| ファイル/ディレクトリ | 役割 | 変更見込み |
|---|---|---|
| | | ✅/❌ |

## 3. 開発ルール・制約

- {{プロジェクト固有の制約・規約}}

## 4. 関連 Issue・IMP

| 参照先 | 関係性 | 状態 |
|---|---|---|
| | 依存/被依存/参考 | |

## 5. 注意事項・既知の問題

- {{着手前に把握すべき注意事項}}
</note_template>

## step9: 品質チェックと完了通知

- 生成した issue-struct.md の品質を評価する：
  - 🔴 不明項目が 3 件以上ある → 警告を表示する
  - 受け入れ基準が 0 件 → エラーとして表示する
  - タスクの循環依存がないか確認する

- 以下を表示する：
  ```
  ✅ issue_init 完了: {{issue_id}}

  生成ファイル:
    docs/issues/{{issue_id}}/issue-struct.md
    docs/issues/{{issue_id}}/tasks.md
    docs/issues/{{issue_id}}/note.md

  品質サマリー:
    受け入れ基準: N 件
    タスク数: N 件
    🔵 確定: N 件 / 🟡 推定: N 件 / 🔴 不明: N 件

  次のステップ:
    /tsumigi:imp_generate {{issue_id}}
  ```

- 🔴 不明項目がある場合は「着手前に確認が必要な項目があります」と警告を表示する
- TodoWrite ツールでタスクを完了にマークする
