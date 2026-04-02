# tsumigi — AI-TDD Engine

tsumigi は Claude Code を使った **AI-TDD エンジン**です。

**Issue → IMP → 実装 → テスト → 逆仕様 → 同期** までを一貫して実行し、
すべての処理を Claude Skills 経由で行います。

## 特徴

| 特徴 | 説明 |
|------|------|
| **IMP 中心設計** | IMP（実装管理計画書）が Issue〜実装〜ドキュメントの単一の真実の源 |
| **Drift Correction** | 仕様と実装の乖離を5次元で定量検出・可視化 |
| **Reviewer-oriented** | ペルソナ別（arch/security/qa）レビューチェックリストを自動生成 |
| **Idempotent** | 全 Skill は再実行安全。既存成果物に差分マージ |
| **tsumiki 継承** | tsumiki の設計思想・ワークフローをベースに拡張 |


## インストール

リポジトリをクローンして `setup.sh` を実行します。
コマンドは `~/.claude/commands/tsumigi/` にインストールされ、すべてのプロジェクトで `/tsumigi:*` として利用できます。

```bash
# 1. リポジトリをクローン
git clone https://github.com/kava2108/tsumigi.git
cd tsumigi

# 2. グローバルインストール（全プロジェクトで使用可能）
bash setup.sh

# または、特定プロジェクトのみに限定する場合
# bash setup.sh --project
```

Claude Code を再起動するとコマンドが有効になります。

## クイックスタート

### 1. プロジェクト初期化

```
/tsumigi:install
```

### 2. 標準ワークフロー

```bash
# Issue からタスク構造を起こす
/tsumigi:issue_init GH-123

# IMP（実装管理計画書）を生成する
/tsumigi:imp_generate GH-123

# TDD モードで実装する
/tsumigi:implement GH-123

# テストケースを生成・実行する
/tsumigi:test GH-123 --exec

# 実装から逆仕様を生成する
/tsumigi:rev GH-123

# 仕様と実装の乖離を確認する
/tsumigi:drift_check GH-123

# 全体を同期する
/tsumigi:sync GH-123

# レビュー資料を生成する
/tsumigi:review GH-123
```

### 3. 自然言語でも使える

```
/tsumigi:cli GH-123 の Issue から作業を始めたい
/tsumigi:cli 仕様と実装がずれていないか確認して
/tsumigi:cli セキュリティ観点でレビューして
```

## コマンド一覧

### コアワークフロー

| コマンド | 説明 |
|---------|------|
| `/tsumigi:install` | プロジェクト初期セットアップ（ディレクトリ・設定・テンプレート生成） |
| `/tsumigi:issue_init <issue-id>` | Issue → 構造化タスク定義・note.md 生成 |
| `/tsumigi:imp_generate <issue-id>` | IMP（実装管理計画書）を生成・更新 |
| `/tsumigi:implement <issue-id>` | IMP ベースで実装案・パッチ案を生成（TDD/direct） |
| `/tsumigi:test <issue-id>` | テストケースマトリクス・検証方針を生成 |
| `/tsumigi:rev <issue-id>` | 実装から逆仕様・API 仕様・スキーマを生成 |
| `/tsumigi:sync <issue-id>` | Issue/IMP/実装/ドキュメントの整合性確認・修正 |
| `/tsumigi:review <issue-id>` | reviewer-oriented な差分・リスク・確認事項を整理 |
| `/tsumigi:drift_check <issue-id>` | 仕様と実装の乖離を検出・スコア化 |

### ユーティリティ

| コマンド | 説明 |
|---------|------|
| `/tsumigi:help` | コマンド一覧・詳細ヘルプ |
| `/tsumigi:cli` | 自然言語 → コマンドルーティング |

## 成果物の場所

```
docs/
├── issues/{issue_id}/          # issue_init の出力
│   ├── issue-struct.md         # 構造化 Issue 定義
│   ├── tasks.md                # タスク分解
│   └── note.md                 # 技術コンテキストノート
├── imps/{issue_id}/            # imp_generate の出力
│   ├── IMP.md                  # IMP 本体（単一の真実の源）
│   ├── IMP-checklist.md        # レビュアーチェックリスト
│   └── IMP-risks.md            # リスクマトリクス
├── implements/{issue_id}/      # implement の出力
│   └── {task_id}/
│       ├── patch-plan.md       # 実装計画・変更対象ファイル
│       ├── impl-memo.md        # 実装判断の根拠
│       └── red-phase.md        # TDD Red フェーズ
├── tests/{issue_id}/           # test の出力
│   └── {task_id}/
│       ├── testcases.md        # テストケースマトリクス
│       ├── test-plan.md        # テスト計画書
│       └── test-results.md     # テスト実行結果
├── specs/{issue_id}/           # rev の出力
│   ├── rev-spec.md             # 逆生成仕様書
│   ├── rev-api.md              # API 仕様
│   └── rev-schema.md           # データスキーマ
├── drift/{issue_id}/           # drift_check の出力
│   ├── drift-report.md         # 乖離レポート
│   └── drift-timeline.md       # 乖離の時系列変化
├── reviews/{issue_id}/         # review の出力
│   ├── review-checklist.md     # レビューチェックリスト
│   ├── risk-matrix.md          # リスクマトリクス
│   └── review-questions.md     # レビュアー確認質問
└── sync/{issue_id}/            # sync の出力
    ├── sync-report.md          # 整合性レポート
    └── sync-actions.md         # 手動対応アクション
```

## tsumiki との関係

tsumigi は [tsumiki](https://github.com/classmethod/tsumiki) の設計思想を継承し、以下を拡張しています：

- tsumiki の `kairo-requirements` + `kairo-tasks` → tsumigi の `issue_init`
- tsumiki の `kairo-design` → tsumigi の `imp_generate`（IMP 構造化・reviewer-oriented）
- tsumiki の `tdd-red/green/refactor` → tsumigi の `implement`
- tsumiki の `tdd-testcases/verify` → tsumigi の `test`
- tsumiki の `rev-design/specs/requirements` → tsumigi の `rev`（統合 + IMP 差分フラグ）
- tsumigi 独自: `drift_check` / `sync` / `review`

## ライセンス

MIT
