---
description: tsumigi プロジェクトの初期セットアップを行います。ディレクトリ構造・設定ファイル・IMP テンプレートを生成し、Skills の有効化手順を案内します。
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion, TodoWrite
argument-hint: "[project-name] [--lang ja|en] [--speckit]"
---

# tsumigi install

tsumigi エンジンをプロジェクトに導入するための初期セットアップを行います。
冪等設計のため、既存ファイルを上書きせずに差分のみを追加します。

# context

プロジェクト名={{project_name}}
言語={{lang}}
SpecKit連携={{speckit_enabled}}
作業ディレクトリ={{working_dir}}

# step

- $ARGUMENTS の内容を解析する：
  - `--lang en` が含まれる場合、lang を `en` に設定（デフォルト: `ja`）
  - `--speckit` が含まれる場合、speckit_enabled を `true` に設定
  - 残りの文字列をプロジェクト名として設定
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: プロジェクト名の確認

- プロジェクト名が未指定の場合、AskUserQuestion ツールを使って質問する：
  - question: "プロジェクト名を教えてください"
  - header: "プロジェクト名"
  - multiSelect: false
- 取得したプロジェクト名を context の {{project_name}} に保存する
- step3 を実行する

## step3: 既存セットアップの確認（idempotent チェック）

- `.tsumigi/config.json` が存在するか確認する
  - 存在する場合：「既存の tsumigi 設定が見つかりました。差分のみを追加します」と表示する
  - 存在しない場合：「新規セットアップを開始します」と表示する
- step4 を実行する

## step4: ディレクトリ構造の生成

以下のディレクトリを作成する（既存ディレクトリは変更しない）：

```
docs/issues/
docs/imps/
docs/implements/
docs/tests/
docs/specs/
docs/drift/
docs/reviews/
docs/sync/
.tsumigi/templates/
```

各ディレクトリに `.gitkeep` ファイルを作成する（既存ファイルはスキップ）。

## step5: 設定ファイルの生成

`.tsumigi/config.json` が存在しない場合のみ、以下の内容で作成する：

```json
{
  "tsumigi_version": "1.0.0",
  "project": {
    "name": "{{project_name}}",
    "language": "{{lang}}",
    "created_at": "<現在の ISO8601 日時>"
  },
  "integrations": {
    "speckit": {{speckit_enabled}},
    "github": {
      "enabled": true,
      "issue_prefix": "GH"
    }
  },
  "drift_check": {
    "threshold": 20,
    "auto_run_after_implement": true
  },
  "review": {
    "default_personas": ["arch", "security", "qa"],
    "require_checklist_before_merge": true
  },
  "imp": {
    "require_executive_summary": true,
    "require_rollback_plan": true,
    "version_scheme": "semver"
  },
  "docs": {
    "base_path": "docs",
    "issue_path": "docs/issues",
    "imp_path": "docs/imps",
    "implement_path": "docs/implements",
    "test_path": "docs/tests",
    "spec_path": "docs/specs",
    "drift_path": "docs/drift",
    "review_path": "docs/reviews",
    "sync_path": "docs/sync"
  }
}
```

## step6: IMP テンプレートの生成

`.tsumigi/templates/IMP-template.md` を作成する（既存の場合はスキップ）。

<imp_template>
---
imp_id: IMP-{{issue_id}}
imp_version: 1.0.0
source_issue: {{issue_id}}
created_at: {{ISO8601}}
updated_at: {{ISO8601}}
author: {{author}}
status: draft
drift_baseline: N/A
reviewers:
  arch: []
  security: []
  qa: []
---

# IMP: {{title}}

> **Executive Summary（1 分で読める概要）**
> 何を・なぜ・どう変えるかを 3 行以内で説明する。

---

## 1. 背景と動機

### 1.1 問題定義
<!-- 🔵確定 / 🟡推定 / 🔴不明 -->

### 1.2 目標
<!-- 変更後に達成したい状態。測定可能な形で記述 -->

### 1.3 非目標（Out of Scope）
<!-- 今回の変更に含まれない事項を明示する -->

---

## 2. 変更スコープ

### 2.1 変更ファイル一覧

| ファイルパス | 変更種別 | 変更概要 | 影響範囲 |
|---|---|---|---|
| | | | |

### 2.2 API 変更

| エンドポイント | 変更前 | 変更後 | 破壊的変更? |
|---|---|---|---|
| | | | |

### 2.3 スキーマ変更

| テーブル/型 | 変更内容 | マイグレーション必要? |
|---|---|---|
| | | |

---

## 3. タスク詳細

### TASK-0001: {{task_title}}

**完了条件（EARS 記法）**
- [WHEN] ... [THE SYSTEM SHALL] ...

**実装手順**
1.
2.
3.

**受け入れ基準チェックリスト**
- [ ]
- [ ]

**依存関係**
- 前提:
- 後続:

---

## 4. テスト戦略

### 4.1 テスト方針

| レベル | カバレッジ目標 | 使用フレームワーク |
|---|---|---|
| Unit | 90% 以上 | |
| Integration | 主要フロー全数 | |
| E2E | ハッピーパスのみ | |

### 4.2 テスト除外事項

### 4.3 テストデータ方針

---

## 5. ロールバック計画

### 5.1 ロールバックトリガー条件

### 5.2 ロールバック手順
1.
2.

### 5.3 ロールバック所要時間
- 自動:
- 手動:

---

## 6. リスクと依存関係

### 6.1 リスクマトリクス

| リスク | 影響度 | 発生確率 | 対策 |
|---|---|---|---|
| | H/M/L | H/M/L | |

### 6.2 依存関係

| 依存先 | 種別 | 影響 |
|---|---|---|
| | | |

---

## 7. レビュアーチェックリスト

### 7.1 アーキテクチャレビュー
- [ ] 変更が既存アーキテクチャパターンと整合している
- [ ] 新たな外部依存の追加が適切に評価されている
- [ ] スケーラビリティへの影響が分析されている
- [ ] 設計の複雑度が最小限に抑えられている
- [ ] ロールバック計画が実行可能である

### 7.2 セキュリティレビュー
- [ ] 認証・認可フローに抜け穴がない
- [ ] 秘密情報の取り扱いが適切
- [ ] 入力バリデーション・サニタイズが実装されている
- [ ] OWASP Top10 の該当項目が考慮されている
- [ ] 監査ログが適切に記録される

### 7.3 QA レビュー
- [ ] 全ての受け入れ基準にテストケースが対応している
- [ ] 正常系・異常系・境界値が網羅されている
- [ ] 既存テストへの影響が確認されている
- [ ] テスト環境での動作確認手順が明確
- [ ] パフォーマンス要件のテストが含まれている

---

## 8. 承認記録

| ロール | 担当者 | 承認日時 | コメント |
|---|---|---|---|
| アーキテクト | | | |
| セキュリティ | | | |
| QA | | | |
| 実装者 | | | |

---

## Appendix: 変更履歴

| バージョン | 変更内容 | 変更者 | 日時 |
|---|---|---|---|
| 1.0.0 | 初版作成 | | {{ISO8601}} |
</imp_template>

## step7: TSUMIGI.md の生成

プロジェクトルートに `TSUMIGI.md` を作成する（既存の場合はスキップ）。

<tsumigi_md_template>
# TSUMIGI — AI-TDD Engine for {{project_name}}

## 標準ワークフロー

```bash
# 1. Issue からタスク構造を起こす
/tsumigi:issue_init GH-123

# 2. IMP（実装管理計画書）を生成する
/tsumigi:imp_generate GH-123

# 3. 実装する（TDD モード）
/tsumigi:implement GH-123 --mode tdd

# 4. テストを生成・実行する
/tsumigi:test GH-123 --exec

# 5. 逆仕様を生成する
/tsumigi:rev GH-123

# 6. 乖離を確認する
/tsumigi:drift_check GH-123

# 7. 全体を同期する
/tsumigi:sync GH-123

# 8. レビュー資料を生成する
/tsumigi:review GH-123
```

## よく使うコマンド

```bash
# 自然言語から開始する
/tsumigi:cli [やりたいことを自然言語で入力]

# ヘルプ
/tsumigi:help
```

## プロジェクト設定

設定ファイル: `.tsumigi/config.json`

## 注意事項

- すべてのコマンドは冪等（再実行安全）です
- IMP.md が全フェーズの単一の真実の源です
- drift スコアが 20 を超えたら IMP または実装の修正が必要です
</tsumigi_md_template>

## step8: 完了通知

以下を表示する：

```
✅ tsumigi セットアップ完了

生成されたファイル:
  .tsumigi/config.json
  .tsumigi/templates/IMP-template.md
  TSUMIGI.md
  docs/{issues,imps,implements,tests,specs,drift,reviews,sync}/.gitkeep

次のステップ:
  1. Claude Code Plugin をインストール（未実施の場合）:
     /plugin marketplace add https://github.com/kava2108/tsumigi.git
     /plugin install tsumigi@tsumigi

  2. 最初の Issue から作業を開始:
     /tsumigi:issue_init <issue-id>

  3. ヘルプを確認:
     /tsumigi:help
```

- TodoWrite ツールでセットアップ完了をマークする
