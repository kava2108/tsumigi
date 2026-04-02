---
description: Issue 構造定義から IMP（実装管理計画書）を生成・更新します。IMP は実装・テスト・レビューの全フェーズで参照される単一の真実の源です。reviewer-oriented な構造で監査可能な形式で出力します。
allowed-tools: Read, Glob, Grep, Write, Edit, TodoWrite, AskUserQuestion
argument-hint: "<issue-id> [--update] [--reviewer arch|security|qa]"
---

# tsumigi imp_generate

IMP（Implementation Management Plan / 実装管理計画書）を生成します。
IMP は Issue〜実装〜ドキュメントの**単一の真実の源**です。

# context

issue_id={{issue_id}}
update_mode={{update_mode}}
reviewer_personas={{reviewer_personas}}
issue_struct_file=specs/issue-struct.md
tasks_file=specs/tasks.md
note_file=specs/note.md
imp_file=specs/IMP.md
imp_checklist_file=specs/IMP-checklist.md
imp_risks_file=specs/IMP-risks.md
imp_version=1.0.0
信頼性評価=[]

# step

- $ARGUMENTS がない場合は「引数に issue-id を指定してください（例: /tsumigi:imp_generate GH-123）」と言って終了する
- $ARGUMENTS を解析する：
  - `--update` フラグを確認し update_mode に設定
  - `--reviewer` の後の値を reviewer_personas に設定
  - 最初のトークンを issue_id に設定
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 前提チェック

- `specs/issue-struct.md` の存在を確認する
  - 存在しない場合：「先に `/tsumigi:issue_init {{issue_id}}` を実行してください」と言って終了する
- `specs/issue-struct.md` を Read する
- `specs/tasks.md` を Read する
- `specs/note.md` を存在する場合に Read する
- step3 を実行する

## step3: 冪等チェック（既存 IMP の確認）

- `specs/IMP.md` が存在するか確認する
  - 存在する かつ `--update` フラグなし：
    - IMP.md を Read して現在のバージョンを確認する
    - 「既存 IMP が見つかりました（ver: X.Y.Z）。--update を付けて再実行すると差分更新します」と表示する
    - AskUserQuestion ツールで確認する：
      - question: "続行しますか？"
      - options: ["更新する（--update 相当）", "現在の IMP を表示して終了", "中断する"]
  - 存在する かつ `--update` フラグあり：
    - IMP.md を Read してバージョンを確認し、マイナーバージョンをインクリメントする
    - 「差分更新モードで実行します（ver: X.Y.Z → X.Y+1.Z）」と表示する
  - 存在しない：
    - 「新規 IMP を生成します（ver: 1.0.0）」と表示する
- step4 を実行する

## step4: レビュアーペルソナの確認

- reviewer_personas が未設定の場合、AskUserQuestion ツールを使って質問する：
  - question: "想定するレビュアーのペルソナを選択してください"
  - header: "レビュアーペルソナ"
  - multiSelect: true
  - options:
    - label: "arch（アーキテクチャ）"
      description: "設計パターン・依存関係・スケーラビリティを重視"
    - label: "security（セキュリティ）"
      description: "認証認可・OWASP・機密情報取り扱いを重視"
    - label: "qa（品質保証）"
      description: "テストカバレッジ・エッジケース・非機能要件を重視"
  - 選択結果を context の {{reviewer_personas}} に保存する

## step5: 関連コンテキストの収集

- 以下を存在する場合に Read する：
  - `.tsumigi/config.json`
  - `.tsumigi/templates/IMP-template.md`
  - 依存関係にある Issue の IMP: Bash で `git show <branch>:specs/IMP.md 2>/dev/null` で参照（マージ済みブランチのみ）

- 実装ファイルの現状を Glob で把握する（変更スコープの特定のため）：
  - `src/**/*.{ts,tsx,js,py,go,java}` など（技術スタックに応じて調整）

## step6: IMP 本体の生成

`specs/IMP.md` を生成する。
`.tsumigi/templates/IMP-template.md` が存在する場合はそれをベースにする。

以下のすべてのセクションを埋める：

**必須フィールド**（欠如すると品質チェックで警告）:
- `imp_id`, `imp_version`, `source_issue`, `created_at`, `status`, `drift_baseline`
- Executive Summary（3 行以内）
- 受け入れ基準（EARS 記法、issue-struct.md から転写・精緻化）
- 変更スコープ（ファイル・API・スキーマ）
- タスク詳細（tasks.md から転写・実装手順付き）
- テスト戦略
- ロールバック計画
- リスクマトリクス
- レビュアーチェックリスト（ペルソナ別）

**drift_baseline の設定**:
- `git rev-parse HEAD 2>/dev/null` が実行できる場合は Bash で取得する
- 取得できない場合は `"N/A"` を設定する

**IMP バージョニングルール**:
- 新規生成: `1.0.0`
- --update（受け入れ基準の変更なし）: パッチバージョンをインクリメント（例: 1.0.1）
- --update（受け入れ基準の変更あり）: マイナーバージョンをインクリメント（例: 1.1.0）
- 破壊的変更（スコープの大幅変更）: メジャーバージョンをインクリメント（例: 2.0.0）

## step7: IMP チェックリストの生成

`specs/IMP-checklist.md` を生成する。
選択されたペルソナに応じたチェックリストを作成する。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/IMP-checklist-template.md`
  - `.claude/commands/tsumigi/templates/IMP-checklist-template.md`
- テンプレートの変数（`{{issue_id}}`, `{{imp_version}}`, `{{reviewer_personas}}`, `{{ISO8601}}`）を置換する
- `{{reviewer_personas}}` に含まれないペルソナのセクションは削除して `specs/IMP-checklist.md` を Write する

## step8: リスクマトリクスの生成

`specs/IMP-risks.md` を生成する。
issue-struct.md のリスクセクションと IMP の変更スコープを分析してリスクを特定する。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/IMP-risks-template.md`
  - `.claude/commands/tsumigi/templates/IMP-risks-template.md`
- テンプレートの変数を置換し、分析したリスクを埋めて `specs/IMP-risks.md` を Write する

## step9: 完全性スコアの算出と表示

IMP の必須フィールド充足率を算出して表示する：

```
📊 IMP 完全性スコア: N/100

必須セクション:
  ✅ Executive Summary
  ✅ 受け入れ基準（EARS）
  ✅ 変更スコープ
  ✅ タスク詳細
  ✅ テスト戦略
  ✅ ロールバック計画
  ✅ リスクマトリクス
  ✅ レビュアーチェックリスト
  ⚠️ drift_baseline（git が未使用のため N/A）

信頼性サマリー:
  🔵 確定: N 件
  🟡 推定: N 件
  🔴 不明: N 件（着手前に解消が必要）
```

## step10: 完了通知

- 以下を表示する：
  ```
  ✅ imp_generate 完了: {{issue_id}} (ver {{imp_version}})

  生成ファイル:
    specs/IMP.md
    specs/IMP-checklist.md
    specs/IMP-risks.md

  次のステップ:
    実装を開始する:  /tsumigi:implement {{issue_id}}
    乾燥確認する:    /tsumigi:drift_check {{issue_id}}
    レビューを依頼:  IMP-checklist.md をレビュアーに共有する
  ```

- TodoWrite ツールでタスクを完了にマークする
