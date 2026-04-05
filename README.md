# tsumigi — AI-TDD Engine (VCKD v3.0)

tsumigi は Claude Code を使った **AI-TDD エンジン**です。  
**VSDD × CoDD × Kiro × tsumigi × Harness Engineering** を統合した **VCKD**（Verified Coherence Kiro-Driven Development）フレームワークを実装します。

**Issue 作成 → 要件定義 → 技術設計 → 実装 → テスト → 整合性確認 → PR** までを AI エージェントが自律実行し、
人間の操作は原則 **3タッチ** だけです。

## 特徴

| 特徴 | 説明 |
|------|------|
| **Label-Driven Baton** | GitHub ラベル変更がフェーズ間のバトン信号。エージェントが自律起動する |
| **Phase Agent 専門化** | 21 の専門エージェントが各フェーズを担当。汎用エージェントより高精度 |
| **IMP 中心設計** | IMP（実装管理計画書）が Issue〜実装〜ドキュメントの単一の真実の源 |
| **CEG（依存グラフ）** | 全成果物ファイルの `coherence:` frontmatter から有向グラフを自動構築 |
| **Adversarial Review** | コンテキスト分離した独立評価で AI スロップを検出。Phase Gate に組み込み |
| **Drift Correction** | 仕様と実装の乖離を Green/Amber/Gray で定量化・可視化 |
| **Idempotent** | 全コマンドは再実行安全。既存成果物に差分マージ |

## 人間の役割（3 タッチのみ）

```
Touch 1: GitHub Issue を作成し、label: phase:req を付与する
Touch 2: human:review ラベルが付与されたとき、承認/差し戻しを判断する
         （設計の方向転換、Amber ノードの解消判断）
Touch 3: blocked:escalate ラベルのとき、詰まったエージェントをローカルで救出する

AI エージェントが自律実行する作業:
  EARS 要件整理 → 技術設計 → タスク分解 → Issue 生成
  → IMP 生成 → 実装 → テスト → Adversarial Review
  → 逆仕様生成 → 乖離チェック → PR 作成 + エビデンス添付
```

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

### 自律実行フロー（推奨）

```bash
# Touch 1: Issue を作成して label: phase:req を付与するだけ
gh issue create \
  --title "OAuth 2.0 認証機能" \
  --body "ユーザーが Google アカウントでログインできるようにしたい" \
  --label "phase:req"

# 以降はエージェントが自律実行:
# RequirementsAgent → DesignAgent → ImplementAgent（並列）
# → TestAgent + AdversaryAgent → OpsAgent → ChangeAgent → PR 作成
```

### 手動実行フロー（CI/CD なし環境・従来互換）

```bash
# REQ: 要件定義
/tsumigi:spec-steering
/tsumigi:spec-req user-auth-oauth

# TDS: 技術設計
/tsumigi:spec-design user-auth-oauth
/tsumigi:spec-tasks user-auth-oauth

# ブリッジ: Issue 生成
/tsumigi:issue-generate user-auth-oauth --wave P0

# IMP: 実装
/tsumigi:imp_generate 042-user-auth-login
/tsumigi:implement 042-user-auth-login

# TEST: テスト + Adversarial Review
/tsumigi:test 042-user-auth-login --vmodel all
/tsumigi:review 042-user-auth-login --adversary

# OPS: 逆仕様生成 + 乖離チェック
/tsumigi:rev 042-user-auth-login --target all
/tsumigi:drift_check 042-user-auth-login

# CHANGE: 同期 + PR
/tsumigi:sync 042-user-auth-login --audit
/tsumigi:pr 042-user-auth-login
```

### 自然言語でも使える

```
/tsumigi:cli 新機能の要件を整理したい
/tsumigi:cli 仕様と実装がずれていないか確認して
/tsumigi:cli セキュリティ観点で厳しくチェックして
/tsumigi:cli バトン状態を確認したい
```

## コマンド一覧

### REQ フェーズ（Kiro による要件定義）

| コマンド | 説明 |
|---------|------|
| `/tsumigi:spec-steering [--update]` | Steering 文書（技術スタック・規約）を生成 |
| `/tsumigi:spec-req <feature> [-y]` | EARS 記法の要件定義書を生成。Phase Gate REQ→TDS を実行 |

### TDS フェーズ（Kiro による技術設計）

| コマンド | 説明 |
|---------|------|
| `/tsumigi:spec-design <feature> [-y]` | Mermaid アーキテクチャ図・API 設計・DB 設計を生成 |
| `/tsumigi:spec-tasks <feature> [-y]` | P0/P1 波形でタスク分解。Phase Gate TDS→IMP を実行 |

### ブリッジ

| コマンド | 説明 |
|---------|------|
| `/tsumigi:issue-generate <feature> [--wave P0\|P1\|all]` | tasks.md → GitHub Issues 一括生成（label: phase:imp を付与） |

### IMP フェーズ（実装管理）

| コマンド | 説明 |
|---------|------|
| `/tsumigi:imp_generate <issue-id> [--update]` | IMP（実装管理計画書）を生成・更新（Kiro 参照 + CEG） |
| `/tsumigi:implement <issue-id> [task-id]` | IMP ベースで実装案・patch-plan.md を生成。Phase Gate IMP→TEST を実行 |

### TEST フェーズ（V-Model + Adversarial Gate）

| コマンド | 説明 |
|---------|------|
| `/tsumigi:test <issue-id> [--vmodel unit\|integration\|e2e\|all]` | V-Model + AC-ID トレースリンク付きテストケースを生成 |
| `/tsumigi:review <issue-id> [--adversary] [--persona arch\|security\|qa]` | ペルソナ別レビュー / `--adversary` で Phase Gate TEST→OPS を実行 |

### OPS フェーズ（整合性確認）

| コマンド | 説明 |
|---------|------|
| `/tsumigi:rev <issue-id> [--target api\|schema\|spec\|all]` | 実装から逆仕様・API 仕様・スキーマを生成（CEG 更新） |
| `/tsumigi:drift_check <issue-id> [--since <commit>]` | 仕様と実装の乖離を Green/Amber/Gray で検出。Phase Gate OPS→CHANGE を実行 |

### CHANGE フェーズ

| コマンド | 説明 |
|---------|------|
| `/tsumigi:sync <issue-id> [--audit]` | 全成果物の整合性確認・修正 |
| `/tsumigi:pr <issue-id>` | PR 生成 + エビデンス添付（Adversarial / coherence / drift） |

### ユーティリティ

| コマンド | 説明 |
|---------|------|
| `/tsumigi:impact <issue-id> [--node <node_id>]` | BFS 影響分析（変更の波及範囲） |
| `/tsumigi:spec-status <feature>` | フェーズ進捗 + CEG サマリー + バトン状態 |
| `/tsumigi:baton-status [<issue-id>]` | 全 Issue のラベル・バトン遷移履歴を表示 |
| `/tsumigi:coherence-scan` | graph/coherence.json を再構築 |
| `/tsumigi:install` | プロジェクト初期セットアップ（`--harness` でフック・ラベルも設定） |
| `/tsumigi:help` | コマンド一覧・詳細ヘルプ |
| `/tsumigi:cli` | 自然言語 → コマンドルーティング |

## 価値ストリーム（VSDD）

```
REQ ──► TDS ──► IMP ──► TEST ──► OPS ──► CHANGE
 │        │       │        │        │        │
Kiro   Kiro   tsumigi  tsumigi  tsumigi  tsumigi
               CoDD     VSDD     CoDD     CoDD
              Harness  Harness  Harness  Harness
```

各フェーズ間に **Phase Gate** があり、整合性チェックを通過しないと次フェーズに進めません。
Gate PASS 時はバトン信号（GitHub ラベル変更）が発行され、次の Phase Agent が自律起動します。

## AUTO_STEP 設定

Phase Gate PASS 後の自動進行は `.vckd/config.yaml` で制御します。

```yaml
harness:
  AUTO_STEP: false   # デフォルト: false（手動承認モード）
```

| モード | AUTO_STEP | 動作 |
|--------|-----------|------|
| **Manual Baton**（推奨・初期） | `false` | Gate PASS → `pending:next-phase` ラベル + コメント投稿。人間が `approve` ラベルで進行 |
| **Auto Baton**（本番） | `true` | Gate PASS → 即座に次フェーズラベルに変更。人間の操作不要 |

## 成果物の場所

```
.kiro/
├── steering/              # プロジェクト規約・技術スタック
│   ├── structure.md
│   └── tech.md
└── specs/<feature>/       # フィーチャー単位の仕様
    ├── requirements.md    # EARS 要件定義（REQ）
    ├── design.md          # アーキテクチャ設計（TDS）
    └── tasks.md           # タスク分解・P0/P1 波形（TDS）

docs/
├── specs/<issue-id>/      # issue_init の出力
│   ├── issue-struct.md
│   └── note.md
├── imps/<issue-id>/       # imp_generate の出力
│   ├── IMP.md
│   ├── IMP-checklist.md
│   └── IMP-risks.md
├── implements/<issue-id>/ # implement の出力
│   └── <task-id>/
│       ├── patch-plan.md
│       └── impl-memo.md
├── tests/<issue-id>/      # test の出力
│   └── <task-id>/
│       ├── testcases.md
│       └── test-plan.md
├── specs/<issue-id>/      # rev の出力
│   ├── rev-spec.md
│   ├── rev-api.md
│   └── rev-schema.md
├── drift/<issue-id>/      # drift_check の出力
│   └── drift-report.md
├── reviews/<issue-id>/    # review の出力
│   ├── review-checklist.md
│   └── adversary-report.md
└── sync/<issue-id>/       # sync の出力
    ├── sync-report.md
    └── sync-actions.md

graph/
├── coherence.json         # グローバル CEG（依存グラフ）
└── baton-log.json         # バトン遷移履歴

.tsumigi/
├── config.json
└── hooks/                 # Claude Code hooks（バトン発行）
    ├── post-tool-use.sh
    └── agents/            # Phase Agent システムプロンプト
        ├── requirements-agent.md
        ├── design-agent.md
        ├── implement-agent.md
        ├── test-agent.md
        ├── adversary-agent.md
        ├── ops-agent.md
        └── change-agent.md
```

## tsumiki との関係

tsumigi は [tsumiki](https://github.com/classmethod/tsumiki) の設計思想を継承し、以下を拡張しています：

| tsumiki | tsumigi v3.0 |
|---------|-------------|
| `kairo-requirements` + `kairo-tasks` | `spec-req` + `spec-tasks`（EARS + CEG frontmatter） |
| `kairo-design` | `spec-design` + `imp_generate`（IMP 構造化・Kiro トレースリンク） |
| `tdd-red/green/refactor` | `implement`（P0/P1 波形 + Phase Gate） |
| `tdd-testcases/verify` | `test`（V-Model + AC-ID） + `review --adversary` |
| `rev-design/specs/requirements` | `rev`（coherence frontmatter + 信頼度算出） |
| ─ | `drift_check` / `sync` / `review` / `pr` / `baton-status`（tsumigi 独自） |

## ライセンス

MIT
