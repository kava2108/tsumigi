# tsumigi 要件仕様書 v3.0

> 「人間は質問に答える。AI がすべてを紡ぐ。」

---

## 目次

1. [目的（Purpose）](#1-目的purpose)
2. [設計思想](#2-設計思想)
3. [アーキテクチャ](#3-アーキテクチャ)
4. [人間の役割](#4-人間の役割)
5. [確認推奨事項の設計](#5-確認推奨事項の設計)
6. [Skills 体系（Claude Code Plugin）](#6-skills-体系claude-code-plugin)
7. [ディレクトリ構造](#7-ディレクトリ構造)
8. [IMP 仕様（9 セクション）](#8-imp-仕様9-セクション)
9. [drift correction 仕様](#9-drift-correction-仕様)
10. [自動化パイプライン](#10-自動化パイプライン)
11. [インストール・セットアップ](#11-インストールセットアップ)
12. [v2.1 からの変更点](#12-v21-からの変更点)
13. [最終ビジョン](#13-最終ビジョン)

---

## 1. 目的（Purpose）

tsumigi は、**AI がソフトウェア開発の全工程を自律的に駆動するフレームワーク**である。

人間の役割は「質問に答える」と「承認する」の 2 点に限定する。
それ以外の工程（仕様書生成・Issue 起票・IMP 生成・実装・テスト・逆仕様生成・同期）はすべて AI が担う。

仕様の正解（Single Source of Truth）は、人間が最初に書いたものではなく、
**実装・テストから逆生成された仕様（`/tsumigi:rev`）** が常に最新の正とする。

### v3.0 での位置づけ

tsumigi v3.0 は **Claude Code Plugin** として実装される。
すべての処理は Claude Skills（スラッシュコマンド）経由で実行され、
外部 CLI ツールや Python ランタイムへの依存を持たない。

---

## 2. 設計思想

### 基本原則

| 原則 | 内容 |
|------|------|
| AI ファースト | 書く・考える・決める、すべての起点は AI |
| 人間は承認者 | 人間は読んで判断するだけ。書かない |
| 壁打ちで曖昧さを解消 | 不明点は AI との対話で納得するまで詰める |
| 常識は AI が判断 | 自明な判断は AI が進む。人間を煩わせない |
| 確認推奨事項で透明性確保 | AI が判断した内容は可視化し、人間が選択できる |
| 動くコードが仕様の正 | 逆仕様生成（`/tsumigi:rev`）により、実装が仕様を常に更新する |
| Idempotent（冪等） | 全 Skill は再実行安全。既存成果物に差分マージする |
| Reviewer-oriented | 全出力は監査可能・再現可能な形式で生成する |

### 人間の入力形式

人間が情報を提供する場面では、以下の形式に限定する。

- **選択式**：AI が提示した選択肢から選ぶ（`AskUserQuestion` ツール）
- **簡単な問い**：Yes / No、単語、一文程度の回答
- **壁打ち**：曖昧な点を AI と対話して解決する（任意・重要箇所のみ）

> 長文の記述・仕様の詳細化・設計判断は、すべて AI の責務とする。

### 実行モード

`/tsumigi:issue_init` 開始時に、以下のモードを選択する。

| モード | 内容 | 用途 |
|--------|------|------|
| **信頼モード（full）** | AI の常識判断に任せる。確認推奨事項は 🔴 のみ表示 | スピード優先・慣れたドメイン |
| **慎重モード（lite）** | 🔴🟡 を都度確認。壁打ちを積極的に促す | 新規ドメイン・高リスク実装 |

> モードは Issue 単位で `--scope full|lite` で指定可能。デフォルトは `full`。

---

## 3. アーキテクチャ

### 全体パイプライン

```
人間が質問に答える（選択 or 簡単な問い）
    ↕ 曖昧な点は AI と壁打ち（任意）
    ↓
/tsumigi:issue_init（Issue → 構造化タスク定義 + note.md）
    ↓
/tsumigi:imp_generate（IMP 生成 + 確認推奨事項付き）
    ↓
人間が承認 ← 唯一の必須介入点
    ↓ 承認内容を IMP 本文へ自動マージ
/tsumigi:implement（IMP に基づく AI 実装・TDD/direct）
    ↓
/tsumigi:test（テスト生成・実行）
    ↓
/tsumigi:rev（コード → 逆仕様生成）
    ↓
/tsumigi:drift_check（仕様と実装の乖離をスコア化）
    ↓
/tsumigi:sync（逆生成仕様で Issue・IMP・実装を自動同期）
    ↓
/tsumigi:review（reviewer-oriented なチェックリスト生成）
    ↓
PR 作成
```

### 4 層構造

```
┌──────────────────────────────────────────────┐
│ 1. 要件層                                    │
│    人間の回答 → AI が issue-struct.md を生成  │
└───────────────────────┬──────────────────────┘
                        ▼
┌──────────────────────────────────────────────┐
│ 2. 計画層（IMP 層）                          │
│    AI が IMP.md を生成（単一の真実の源）      │
│    人間が承認 → IMP 本文へ自動マージ          │
└───────────────────────┬──────────────────────┘
                        ▼
┌──────────────────────────────────────────────┐
│ 3. 実装・検証層                              │
│    AI 実装 → TDD → テスト実行                │
└───────────────────────┬──────────────────────┘
                        ▼
┌──────────────────────────────────────────────┐
│ 4. 同期層                                    │
│    逆仕様生成 → drift 検出 → sync → review   │
└──────────────────────────────────────────────┘
```

### SSOT（Single Source of Truth）の変遷

```
開発開始時：issue-struct.md が SSOT
    ↓ imp_generate 実行後
IMP.md が SSOT（Issue〜実装〜ドキュメントの単一の真実の源）
    ↓ rev + sync 実行後
逆生成仕様（rev-spec.md）が SSOT
    ↓ sync --fix 実行後
IMP.md が逆仕様で自動更新され、再び最新の SSOT となる
    ↓ このサイクルを維持
常に「動いているコード」が仕様の正となるサイクル
```

---

## 4. 人間の役割

tsumigi における人間の介入点は以下の 2 つに限定する。

### 介入点 1：Issue インタビューへの回答（開発開始時）

`/tsumigi:issue_init` 実行時、AI が質問を提示し、人間が答えることで
`issue-struct.md` の素材を収集する。

```
AI：「この Issue の分解スコープを選択してください」
    A) full（詳細分解・EARS 記法・非機能要件・エッジケースを含む）
    B) lite（最小限のタスク定義のみ）

人間：A を選択
```

- 基本は `AskUserQuestion` ツールによる選択式
- 選択肢に該当なしの場合のみ、簡単な言葉で補足する
- 曖昧な点は壁打ちで解消する（強制ではない）
- 実行モード（full / lite）をここで選択する

### 介入点 2：IMP の承認（実装前）

`/tsumigi:imp_generate` が生成した IMP と確認推奨事項を読み、承認する。

- 🔴 要確認事項があれば、壁打ちして解決してから承認する
- 🟡 推奨確認事項は、判断して承認 or スキップする
- ⚪ 参考事項はスキップして承認でよい
- **承認された内容は自動的に IMP 本文（セクション 1「概要」または 8「禁止事項」）へマージされ、実装の絶対的な制約条件として固定される**

> **承認 = `/tsumigi:implement` の実行トリガー**

---

## 5. 確認推奨事項の設計

AI が実装中・仕様生成中に曖昧な点を発見した場合、**人間を即座に止めるのではなく
「確認推奨事項」として記載**し、判断を委ねる。

### 重要度分類

```markdown
## 確認推奨事項

### 🔴 要確認（実装に影響大・承認前に解決を推奨）
- [ ] エラー時のリトライ回数はどうするか？
      → 決まっていない場合、デフォルト 3 回で実装します

### 🟡 推奨確認（常識的に判断可能・スキップ可）
- [ ] ログ出力は INFO レベルでよいか？
      → スキップ時は INFO で実装します

### ⚪ 参考（AI が常識的に判断して進む・確認不要）
- [x] 変数名は camelCase に統一しました
- [x] エラーメッセージは英語で統一しました
```

### 決定事項の永続化

承認後、確認推奨事項の選択内容は以下の通り自動処理される。

```
人間が確認推奨事項を承認
    ↓ /tsumigi:implement 実行前に自動マージ
IMP「1. 概要」または「8. 禁止事項」へ決定事項として追記
    ↓
実装時のコンテキストとして固定（変更不可）
    ↓
選択履歴は IMP 内に記録され、トレーサビリティを確保
```

### 設計原則

| 原則 | 内容 |
|------|------|
| 人間を止めない | 常識の範疇は AI が判断して進む |
| 透明性の確保 | AI が判断した内容は ⚪ として必ず可視化する |
| 判断の委譲 | 🔴 🟡 は人間が選択できる。強制はしない |
| デフォルトの明示 | 各項目に「スキップ時の AI の判断」を明記する |
| 決定の永続化 | 承認された内容は IMP 本文へ自動マージし、実装の制約として固定する |
| 履歴の保全 | 選択履歴を IMP 内に記録し、決定プロセスをトレース可能にする |

### 実行モード別の表示制御

| モード | 🔴 | 🟡 | ⚪ |
|--------|----|----|-----|
| 信頼モード（full） | 表示・要対応 | 非表示（AI が判断） | 非表示 |
| 慎重モード（lite） | 表示・要対応 | 表示・対応推奨 | 表示（参考） |

---

## 6. Skills 体系（Claude Code Plugin）

tsumigi v3.0 はすべての機能を **Claude Code Plugin のスラッシュコマンド**として提供する。
インストール後、`/tsumigi:` プレフィックスで全 Skill が呼び出せる。


### インストール

Claude Code Chat では /plugin コマンドは利用できません。
拡張機能の導入やプラグインの追加は、Claude Code Chat の公式ドキュメントや設定画面から行ってください。
もしくは、リポジトリをクローンして手動でセットアップしてください：

```bash
git clone https://github.com/kava2108/tsumigi.git
cd tsumigi
# 必要に応じて依存パッケージをインストール
# 例: npm install など
```

### コマンド一覧

```bash
# 初期化
/tsumigi:install [project-name] [--lang ja|en] [--speckit]

# 要件収集・構造化
/tsumigi:issue_init <issue-id> [issue-url-or-text] [--scope full|lite]

# IMP 生成（承認のインプット）
/tsumigi:imp_generate <issue-id> [--update] [--reviewer arch|security|qa]

# 実装
/tsumigi:implement <issue-id> [task-id] [--dry-run] [--mode tdd|direct]

# テスト
/tsumigi:test <issue-id> [task-id] [--exec] [--focus unit|integration|e2e|security|all]

# 逆仕様生成
/tsumigi:rev <issue-id> [--target api|schema|spec|requirements|all]

# 乖離検出
/tsumigi:drift_check <issue-id> [--since <commit-ish>] [--threshold <0-100>]

# 全体同期
/tsumigi:sync <issue-id> [--fix] [--report-only]

# レビュー資料生成
/tsumigi:review <issue-id> [--persona arch|security|qa|all] [--pr <pr-number>]

# ユーティリティ
/tsumigi:help [command-name]
/tsumigi:cli [自然言語の指示]
```

### 各 Skill の責務

| Skill | 責務 | 主な出力 |
|-------|------|---------|
| `install` | プロジェクト初期化・テンプレート配置 | `.tsumigi/`, `TSUMIGI.md`, `docs/` |
| `issue_init` | Issue → 構造化タスク定義 | `issue-struct.md`, `tasks.md`, `note.md` |
| `imp_generate` | IMP 生成・確認推奨事項付与 | `IMP.md`, `IMP-checklist.md`, `IMP-risks.md` |
| `implement` | TDD/direct 実装案生成 | `patch-plan.md`, `impl-memo.md`, `red-phase.md` |
| `test` | テストケースマトリクス生成 | `testcases.md`, `test-plan.md`, `test-results.md` |
| `rev` | 実装 → 逆仕様生成 | `rev-spec.md`, `rev-api.md`, `rev-schema.md` |
| `drift_check` | 仕様↔実装 乖離検出 | `drift-report.md`, `drift-timeline.md` |
| `sync` | 全成果物の整合性確認・修正 | `sync-report.md`, `sync-actions.md` |
| `review` | reviewer-oriented レビュー資料生成 | `review-checklist.md`, `risk-matrix.md` |
| `help` | コマンド説明・詳細ヘルプ | — |
| `cli` | 自然言語 → コマンドルーティング | — |

### 自然言語からの呼び出し

`/tsumigi:cli` を使うと自然言語でコマンドを指示できる。

```
/tsumigi:cli GH-123 の Issue から作業を始めたい
  → /tsumigi:issue_init GH-123 を提案・実行

/tsumigi:cli 仕様と実装がずれていないか確認して
  → /tsumigi:drift_check <issue-id> を提案・実行

/tsumigi:cli 次は何をすればいい？
  → 現状の進捗を分析して次のコマンドを提案
```

---

## 7. ディレクトリ構造

### リポジトリ構造（tsumigi 本体）

```
kava2108/tsumigi/
  ├── .claude-plugin/
  │   ├── plugin.json           # Claude Code Plugin 設定
  │   └── marketplace.json      # マーケットプレイスメタデータ
  ├── commands/                 # スラッシュコマンド定義（.md）
  │   ├── install.md
  │   ├── issue_init.md
  │   ├── imp_generate.md
  │   ├── implement.md
  │   ├── test.md
  │   ├── rev.md
  │   ├── drift_check.md
  │   ├── sync.md
  │   ├── review.md
  │   ├── help.md
  │   └── cli.md
  ├── docs/
  │   └── requirements-spec-v3.0.md  # この文書
  ├── CLAUDE.md                 # Claude Code 向けガイダンス
  ├── README.md                 # ユーザー向けドキュメント
  └── package.json
```

### 導入先プロジェクトの成果物構造

```
{project-root}/
  ├── .tsumigi/
  │   ├── config.json           # tsumigi 設定
  │   └── templates/
  │       └── IMP-template.md   # IMP テンプレート
  ├── TSUMIGI.md                # プロジェクト固有ワークフロー
  └── docs/
      ├── issues/{issue_id}/
      │   ├── issue-struct.md   # 構造化 Issue 定義（EARS 記法）
      │   ├── tasks.md          # タスク分解（TASK-XXXX 形式）
      │   └── note.md           # 技術コンテキストノート
      ├── imps/{issue_id}/
      │   ├── IMP.md            # IMP 本体（単一の真実の源）
      │   ├── IMP-checklist.md  # レビュアーチェックリスト
      │   └── IMP-risks.md      # リスクマトリクス
      ├── implements/{issue_id}/{task_id}/
      │   ├── patch-plan.md     # 実装計画・変更対象ファイル
      │   ├── impl-memo.md      # 実装判断の根拠
      │   └── red-phase.md      # TDD Red フェーズ定義
      ├── tests/{issue_id}/{task_id}/
      │   ├── testcases.md      # テストケースマトリクス
      │   ├── test-plan.md      # テスト計画書
      │   └── test-results.md   # テスト実行結果
      ├── specs/{issue_id}/
      │   ├── rev-spec.md       # 逆生成仕様書
      │   ├── rev-api.md        # 逆生成 API 仕様
      │   ├── rev-schema.md     # 逆生成スキーマ
      │   └── rev-requirements.md # 逆生成要件定義
      ├── drift/{issue_id}/
      │   ├── drift-report.md   # 乖離レポート（drift スコア）
      │   └── drift-timeline.md # 乖離の時系列変化
      ├── reviews/{issue_id}/
      │   ├── review-checklist.md # ペルソナ別レビューチェックリスト
      │   ├── risk-matrix.md    # リスクマトリクス
      │   └── review-questions.md # レビュアー確認質問
      └── sync/{issue_id}/
          ├── sync-report.md    # 整合性レポート（スコア 0-100）
          └── sync-actions.md   # 手動対応アクション一覧
```

---

## 8. IMP 仕様（9 セクション）

IMP（Implementation Management Plan / 実装管理計画書）は tsumigi の中心となる仕様書。
**AI が実装するための「本文」であり、人間が承認する「合意文書」**。
すべてのフェーズ（実装・テスト・逆仕様・同期・レビュー）がこの文書を参照する。

### セクション定義

| # | セクション | 概要 | 承認後の扱い |
|---|------------|------|-------------|
| 1 | 概要（Executive Summary） | 目的・背景・スコープ（3 行以内）。承認済み決定事項がここに固定 | 確認推奨事項の決定内容を自動追記 |
| 2 | 変更スコープ | 変更ファイル・API・スキーマの一覧 | 変更不可（承認で固定） |
| 3 | タスク詳細 | TASK-XXXX 単位の実装手順・EARS 受け入れ基準 | 変更不可 |
| 4 | I/O 定義 | 関数シグネチャ・入出力・エラー定義 | 変更不可 |
| 5 | テスト戦略 | TDD のためのテストシナリオ・カバレッジ目標 | 変更不可 |
| 6 | 例外・境界条件 | エッジケース・想定外入力の方針 | 変更不可 |
| 7 | ロールバック計画 | 障害時の切り戻し手順・トリガー条件・所要時間 | 変更不可 |
| 8 | 禁止事項（Forbidden） | AI がやってはいけない実装の明示。承認済み制約がここに固定 | 確認推奨事項の制約内容を自動追記 |
| 9 | Definition of Done | 実装完了の判定基準・整合性スコアの合格ライン | 変更不可 |

IMP には必ず **確認推奨事項** セクションを付帯する。
承認後は確認推奨事項の内容が「1. 概要」または「8. 禁止事項」へ自動マージされる。

### IMP メタデータ

```yaml
---
imp_id: IMP-{issue_id}
imp_version: 1.0.0           # semver。受け入れ基準変更でマイナーアップ
source_issue: {issue_id}
created_at: {ISO8601}
updated_at: {ISO8601}
author: {author}
status: draft | review | approved | implemented
drift_baseline: {git_commit_hash}  # drift_check の基点
reviewers:
  arch: []
  security: []
  qa: []
---
```

### IMP バージョニングルール

| 変更種別 | バージョン変化 | 例 |
|----------|--------------|-----|
| 初版生成 | — | `1.0.0` |
| 軽微な修正（受け入れ基準変更なし） | パッチアップ | `1.0.0` → `1.0.1` |
| 受け入れ基準の変更 | マイナーアップ | `1.0.0` → `1.1.0` |
| スコープの大幅変更（破壊的） | メジャーアップ | `1.0.0` → `2.0.0` |

---

## 9. drift correction 仕様

`/tsumigi:drift_check` は IMP（仕様）と実装の乖離を **5 次元**で検出し、
drift スコア（0-100）として定量化する。

### 5 次元照合エンジン

| 次元 | 対象 | 検出方法 |
|------|------|---------|
| D1: 機能仕様 | IMP の受け入れ基準（AC）が実装・テストにカバーされているか | AC のキーワードを Grep で実装・テストと照合 |
| D2: API 契約 | IMP の API 仕様と実際のエンドポイントが一致するか | ルーティング定義を Grep して比較 |
| D3: スキーマ | IMP のスキーマ変更と実際のマイグレーションが一致するか | マイグレーションファイルを Read して比較 |
| D4: テストカバレッジ | IMP のテスト戦略と実際のカバレッジが一致するか | testcases.md の充足率を評価 |
| D5: タスク完了 | IMP のタスク一覧と実装の完了状態が一致するか | patch-plan.md のチェックリストを確認 |

### Severity 分類とスコアリング

| Severity | 意味 | スコア重み |
|----------|------|-----------|
| CRITICAL | 受け入れ基準が未実装 / HTTP メソッド変更 / P0 テスト未実装 | +10 点/件 |
| WARNING | テスト未作成 / API レスポンス構造変更 / カバレッジ不足 | +3 点/件 |
| INFO | タスク未着手 / IMP 未記載の軽微な変更 | +1 点/件 |

```
drift_score = min(Σ(severity_weight × count), 100)
```

### drift スコアの解釈

| スコア | 状態 | 推奨アクション |
|--------|------|--------------|
| 0-10 | ✅ Aligned | 次フェーズへ進める |
| 11-20 | ⚠️ Minor Drift | drift-report.md を確認、軽微な修正 |
| 21-50 | ⚠️ Significant Drift | IMP を更新するか実装を修正する |
| 51-100 | ❌ Critical Drift | `/tsumigi:sync --fix` で即時対応 |

### 自動 drift_check トリガー

`/tsumigi:implement` 完了後、軽量な drift チェックが自動実行される（スコアのみ表示）。
閾値（デフォルト: 20）を超えた場合は警告を表示する。

### drift-timeline（履歴管理）

実行するたびに `drift-timeline.md` へ結果が**追記**される（上書きなし）。
乖離の時系列変化を追跡し、改善トレンドを可視化する。

---

## 10. 自動化パイプライン

### 標準ワークフロー

```
Step 1: /tsumigi:install
    プロジェクト初期化（.tsumigi/, TSUMIGI.md, docs/ 生成）

Step 2: /tsumigi:issue_init <issue-id>
    Issue を構造化。tasks.md + note.md を生成。
    [人間] 選択式インタビューに回答

Step 3: /tsumigi:imp_generate <issue-id>
    IMP.md + IMP-checklist.md + IMP-risks.md を生成。
    確認推奨事項を付帯。
    [人間] IMP を読んで承認。🔴 は壁打ちで解消。

Step 4: /tsumigi:implement <issue-id>
    IMP に基づく実装（TDD: Red → Green）。
    patch-plan.md + impl-memo.md を生成。
    完了後に自動 drift チェックを実行。

Step 5: /tsumigi:test <issue-id> --exec
    テストケース生成 → 実行 → 結果記録。

Step 6: /tsumigi:rev <issue-id>
    実装 → 逆仕様書（rev-spec.md, rev-api.md 等）を生成。
    IMP との差分に ⚠️ フラグを付与。

Step 7: /tsumigi:drift_check <issue-id>
    5 次元の乖離検出。drift スコアを算出。
    CRITICAL が 0 件・スコアが閾値以下になるまで繰り返す。

Step 8: /tsumigi:sync <issue-id> --fix
    全成果物の整合性を確認・自動修正。
    整合性スコア 70 以上を目標とする。

Step 9: /tsumigi:review <issue-id> --persona all
    arch / security / qa ペルソナ別チェックリスト生成。
    PR description に貼り付けてレビュアーに共有。
```

### 人間の介入点まとめ

| タイミング | 内容 | 形式 |
|-----------|------|------|
| Step 2（issue_init） | スコープ・モード選択・インタビュー回答 | 選択式 / 簡単な問い |
| Step 3（imp_generate 後） | IMP と確認推奨事項の承認 | 承認 or 壁打ち |

**この 2 点以外、人間は何もしない。**

### GitHub Issue へのトレーサビリティ

`/tsumigi:issue_init` が生成する `issue-struct.md` は、GitHub Issue の識別子を
メタデータとして保持する。IMP.md の `source_issue` フィールドが Issue と IMP を連結し、
GitHub 上のプロジェクト管理（人間用）と IMP による実装（AI 用）をシステム的に統合する。

---

## 11. インストール・セットアップ


### Claude Code Chat でのインストール

Claude Code Chat では /plugin コマンドは利用できません。
拡張機能の導入やプラグインの追加は、Claude Code Chat の公式ドキュメントや設定画面から行ってください。
もしくは、リポジトリをクローンして手動でセットアップしてください：

```bash
git clone https://github.com/kava2108/tsumigi.git
cd tsumigi
# 必要に応じて依存パッケージをインストール
# 例: npm install など
```

### プロジェクト初期化

```bash
/tsumigi:install [project-name]
```

`/tsumigi:install` は以下を生成する（全て idempotent）：

| 生成物 | 内容 |
|--------|------|
| `.tsumigi/config.json` | tsumigi 設定（drift 閾値・デフォルトペルソナ等） |
| `.tsumigi/templates/IMP-template.md` | IMP テンプレート（9 セクション） |
| `TSUMIGI.md` | プロジェクト固有ワークフロー説明書 |
| `docs/{各カテゴリ}/.gitkeep` | 成果物ディレクトリ |

### 設定ファイル（.tsumigi/config.json）

```json
{
  "tsumigi_version": "1.0.0",
  "project": { "name": "...", "language": "ja" },
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
  }
}
```

---

## 12. v2.1 からの変更点

| 項目 | v2.1 | v3.0 |
|------|------|------|
| **実装形態** | 未定義（CLI ツール想定） | **Claude Code Plugin（スラッシュコマンド）として実装** |
| **コマンド体系** | `tsumigi init / plan / issue` 等の CLI | **`/tsumigi:install / issue_init / imp_generate` 等の Skills** |
| **IMP 構造** | 9 セクション（概要〜DoD） | **9 セクション継承 + メタデータ（imp_version, drift_baseline）追加** |
| **drift correction** | 未定義 | **5 次元照合エンジン + drift スコア（0-100）+ 時系列タイムライン** |
| **sync の役割** | 逆生成仕様で要件仕様書・IMP を更新 | **5 チェック軸の整合性スコア算出 + 自動修正（--fix）** |
| **reviewer-oriented** | なし | **arch / security / qa ペルソナ別チェックリスト + リスクマトリクス** |
| **idempotency** | 部分的 | **全 Skill で冪等性を保証。再実行は差分マージ** |
| **自然言語ルーティング** | なし | **`/tsumigi:cli` で自然言語 → コマンドへのルーティング** |
| **progress tracking** | なし | **`/tsumigi:cli` が現状分析して次コマンドを提案** |
| **Python 抽象 IF** | なし | **将来 Python 実装への移行を想定した抽象インターフェース定義** |

---

## 13. 最終ビジョン

> **「人間は質問に答える。AI がすべてを紡ぐ。」**

tsumigi は、AI 時代の開発における **"仕様・実装・テストの自動織機（loom）"** である。

人間がすることは 2 つだけ。

1. AI の質問に答える（選択式・簡単な問い）
2. AI が生成した IMP を読んで承認する

常識の範疇は AI が判断して進む。
曖昧な点は確認推奨事項として可視化し、人間が選択できる。
重要な判断は壁打ちで納得するまで詰める。
実装が完了したら、動くコードが仕様の正となり、要件仕様書は自動更新される。

これにより、**「書かない開発」「承認するだけの開発」** を実現する。
そして仕様書は、人間が書いた初期状態ではなく、
**常に実装の現実を反映した生きたドキュメント**であり続ける。

```
仕様 → 実装 → 逆仕様 → 仕様（更新）→ 実装 → …

このサイクルが自動で回り続ける状態が、tsumigi の完成形である。
```

---

*tsumigi 要件仕様書 v3.0*
*旧バージョン: v2.1（廃止）*
