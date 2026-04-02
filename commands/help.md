---
description: tsumigi のコマンド一覧・詳細ヘルプ・困りごと検索を提供します。
allowed-tools: Read, AskUserQuestion
argument-hint: "[command-name | キーワード]"
---

# tsumigi help

tsumigi のヘルプを表示します。引数なしで全コマンド一覧、引数ありで詳細ヘルプを表示します。

# step

- $ARGUMENTS がある場合は step3 へスキップ
- $ARGUMENTS がない場合は step2 を実行する

## step2: 全コマンド一覧の表示

以下を表示する：

---

## tsumigi コマンド一覧

### コアワークフロー

| コマンド | 説明 |
|---------|------|
| `/tsumigi:install` | プロジェクト初期セットアップ |
| `/tsumigi:issue_init <issue-id>` | Issue → 構造化タスク定義・note.md 生成 |
| `/tsumigi:imp_generate <issue-id>` | IMP（実装管理計画書）を生成・更新 |
| `/tsumigi:implement <issue-id>` | IMP ベースで実装案・パッチ案を生成 |
| `/tsumigi:test <issue-id>` | テストケースマトリクス・検証方針を生成 |
| `/tsumigi:rev <issue-id>` | 実装から逆仕様・API 仕様・スキーマを生成 |
| `/tsumigi:sync <issue-id>` | 全成果物の整合性確認・修正 |
| `/tsumigi:review <issue-id>` | reviewer-oriented な差分・リスク整理 |
| `/tsumigi:drift_check <issue-id>` | 仕様と実装の乖離を検出・スコア化 |
| `/tsumigi:pr <issue-id>` | GitHub PR を作成しレビューチェックリストを投稿 |

### ユーティリティ

| コマンド | 説明 |
|---------|------|
| `/tsumigi:help [command]` | このヘルプ |
| `/tsumigi:cli [自然言語]` | 自然言語 → コマンドルーティング |

### 標準ワークフロー

```
/tsumigi:issue_init GH-123
    ↓
/tsumigi:imp_generate GH-123
    ↓
/tsumigi:implement GH-123 [--mode tdd|direct]
    ↓
/tsumigi:test GH-123 [--exec]
    ↓
/tsumigi:rev GH-123
    ↓
/tsumigi:drift_check GH-123    ← いつでも実行可
    ↓
/tsumigi:sync GH-123 [--fix]
    ↓
/tsumigi:review GH-123 [--persona arch|security|qa|all]
    ↓
/tsumigi:pr GH-123 [--post-checklist]
```

### 困ったときは

```bash
# 何をすべきかわからない
/tsumigi:cli [やりたいことを自然言語で]

# 仕様と実装がずれている気がする
/tsumigi:drift_check <issue-id>

# 全体がちゃんと揃っているか確認したい
/tsumigi:sync <issue-id> --report-only

# レビュー前に資料を整えたい
/tsumigi:review <issue-id> --persona all
```

---

次のコマンドで詳細ヘルプを見られます：
`/tsumigi:help <command-name>`

- AskUserQuestion ツールを使って質問する：
  - question: "詳細を知りたいコマンドはありますか？"
  - header: "詳細ヘルプ"
  - multiSelect: false
  - options:
    - label: "install — 初期セットアップ"
    - label: "issue_init — Issue 構造化"
    - label: "imp_generate — IMP 生成"
    - label: "implement — 実装案生成"
    - label: "test — テスト生成"
    - label: "rev — 逆仕様生成"
    - label: "sync — 整合性確認"
    - label: "review — レビュー資料生成"
    - label: "drift_check — 乖離検出"
    - label: "pr — GitHub PR 作成"
    - label: "cli — 自然言語ルーティング"
    - label: "特に不要（閉じる）"
  - 選択されたコマンドがある場合は step3 へ、「特に不要」の場合は終了する

## step3: 詳細ヘルプの表示

$ARGUMENTS または選択されたコマンド名に応じて以下を表示する：

### install

```
/tsumigi:install [project-name] [--lang ja|en] [--speckit]

プロジェクトに tsumigi を導入します。

オプション:
  project-name  プロジェクト名（省略時は対話入力）
  --lang        出力言語（デフォルト: ja）
  --speckit     SpecKit との連携設定を有効化

生成物:
  .tsumigi/config.json
  .tsumigi/templates/IMP-template.md
  TSUMIGI.md
  docs/{issues,imps,implements,tests,specs,drift,reviews,sync}/

冪等: ✅ 既存ファイルは上書きしません
```

### issue_init

```
/tsumigi:issue_init <issue-id> [issue-url-or-text] [--scope full|lite]

Issue を構造化し、IMP 生成のインプットとなるタスク定義を作成します。

引数:
  issue-id        Issue の識別子（例: GH-123, SPEC-42）
  issue-url-or-text  GitHub URL またはテキスト（省略時は対話入力）
  --scope         分解の詳細度（full=詳細, lite=最小限、デフォルト: full）

出力:
  docs/issues/{issue_id}/issue-struct.md  構造化 Issue 定義
  docs/issues/{issue_id}/tasks.md         タスク分解（TASK-XXXX 形式）
  docs/issues/{issue_id}/note.md          技術コンテキストノート

冪等: ✅ 再実行時は既存ファイルに差分マージ
前提: なし（最初のステップ）
```

### imp_generate

```
/tsumigi:imp_generate <issue-id> [--update] [--reviewer arch|security|qa]

IMP（実装管理計画書）を生成します。
IMP は Issue〜実装〜ドキュメントの単一の真実の源です。

引数:
  issue-id    Issue の識別子
  --update    既存 IMP を差分更新する
  --reviewer  想定レビュアー役割（複数指定可）

出力:
  docs/imps/{issue_id}/IMP.md             IMP 本体
  docs/imps/{issue_id}/IMP-checklist.md   レビュアーチェックリスト
  docs/imps/{issue_id}/IMP-risks.md       リスクマトリクス

冪等: ✅ --update なしの再実行は差分確認後に更新
前提: /tsumigi:issue_init が完了していること
```

### implement

```
/tsumigi:implement <issue-id> [task-id] [--dry-run] [--mode tdd|direct]

IMP ベースで実装案・パッチ案を生成します。

引数:
  issue-id   Issue の識別子
  task-id    特定タスクのみ実装（省略時は全タスク）
  --dry-run  パッチ案のみ生成、実ファイル変更なし
  --mode     実装モード（tdd=テストファースト, direct=実装ファースト）

出力:
  docs/implements/{issue_id}/{task_id}/patch-plan.md  実装計画
  docs/implements/{issue_id}/{task_id}/impl-memo.md   実装判断の根拠
  docs/implements/{issue_id}/{task_id}/red-phase.md   TDD Red フェーズ

冪等: ✅ 既存実装に diff 形式で提示、確認後に適用
前提: /tsumigi:imp_generate が完了していること
```

### test

```
/tsumigi:test <issue-id> [task-id] [--exec] [--focus unit|integration|e2e|security|all]

テストケースマトリクスと検証方針を生成します。

引数:
  issue-id  Issue の識別子
  task-id   特定タスクのみ（省略時は全タスク）
  --exec    テストを実際に実行して結果を記録
  --focus   テストの重点領域（デフォルト: all）

出力:
  docs/tests/{issue_id}/{task_id}/testcases.md    テストケースマトリクス
  docs/tests/{issue_id}/{task_id}/test-plan.md    テスト計画書
  docs/tests/{issue_id}/{task_id}/test-results.md テスト実行結果（--exec 時）

冪等: ✅
前提: /tsumigi:implement が完了していること
```

### rev

```
/tsumigi:rev <issue-id> [--target api|schema|spec|requirements|all]

実装コードから逆仕様・ドキュメントを生成します。

引数:
  issue-id   Issue の識別子
  --target   生成対象（デフォルト: all）

出力:
  docs/specs/{issue_id}/rev-spec.md          逆生成仕様書
  docs/specs/{issue_id}/rev-api.md           API 仕様（api 対象時）
  docs/specs/{issue_id}/rev-schema.md        データスキーマ（schema 対象時）
  docs/specs/{issue_id}/rev-requirements.md  逆生成要件定義（requirements 対象時）

冪等: ✅
前提: 実装が存在すること
```

### sync

```
/tsumigi:sync <issue-id> [--fix] [--report-only]

Issue/IMP/実装/ドキュメントの整合性を確認・修正します。

引数:
  issue-id       Issue の識別子
  --fix          自動修正可能な乖離を修正する
  --report-only  レポートのみ生成、変更なし

出力:
  docs/sync/{issue_id}/sync-report.md   整合性レポート（スコア 0-100）
  docs/sync/{issue_id}/sync-actions.md  手動対応アクション一覧

整合性スコア:
  90-100: ✅ Excellent
  70-89:  ⚠️ Good（軽微な不整合）
  50-69:  ⚠️ Fair（要対応）
  0-49:   ❌ Poor（即時対応が必要）

冪等: ✅
```

### review

```
/tsumigi:review <issue-id> [--persona arch|security|qa|all] [--pr <pr-number>]

reviewer-oriented な差分・リスク・確認事項を整理します。

引数:
  issue-id         Issue の識別子
  --persona        レビュアーペルソナ（デフォルト: all）
  --pr             PR 番号（GitHub PR の diff を取得）

出力:
  docs/reviews/{issue_id}/review-checklist.md   ペルソナ別チェックリスト
  docs/reviews/{issue_id}/risk-matrix.md        リスクマトリクス
  docs/reviews/{issue_id}/review-questions.md   レビュアー確認質問

冪等: ✅
```

### drift_check

```
/tsumigi:drift_check <issue-id> [--since <commit-ish>] [--threshold <0-100>]

IMP（仕様）と実装の乖離を検出・可視化します。

引数:
  issue-id     Issue の識別子
  --since      比較基点のコミット・ブランチ
  --threshold  警告閾値（デフォルト: 20）

出力:
  docs/drift/{issue_id}/drift-report.md   乖離レポート（スコア 0-100）
  docs/drift/{issue_id}/drift-timeline.md 乖離の時系列変化

Drift スコア:
  0-10:   ✅ Aligned
  11-20:  ⚠️ Minor Drift
  21-50:  ⚠️ Significant Drift
  51-100: ❌ Critical Drift

冪等: ✅ 再実行時は前回レポートとの diff を表示
前提: IMP.md が存在すること
```

### pr

```
/tsumigi:pr <issue-id> [--draft] [--base <branch>] [--post-checklist]

IMP の内容から GitHub PR を作成します。
drift スコア・整合性スコアを PR 本文に埋め込みます。

引数:
  issue-id         Issue の識別子（例: GH-123）
  --draft          ドラフト PR として作成
  --base           ベースブランチ（デフォルト: main）
  --post-checklist レビューチェックリストを PR コメントに投稿

出力:
  GitHub PR（URL を表示）
  PR コメント: docs/reviews/{issue_id}/review-checklist.md（--post-checklist 時）

前提: /tsumigi:review が完了していること（--post-checklist を使う場合）
```

### cli

```
/tsumigi:cli [自然言語の指示]

自然言語入力を tsumigi コマンドにルーティングします。

例:
  /tsumigi:cli GH-123 の Issue から作業を始めたい
  /tsumigi:cli 仕様と実装がずれていないか確認して
  /tsumigi:cli セキュリティ観点でレビューして
  /tsumigi:cli 何をすべきか教えて
```
