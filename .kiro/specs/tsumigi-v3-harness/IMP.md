<!--
{
  "ceg": {
    "phase": "imp",
    "wave": "P0+P1",
    "auto_step": false,
    "source": "design.md",
    "generated_by": "Claude"
  }
}
-->
---
tsumigi:
  node_id: "imp:tsumigi-v3-harness"
  artifact_type: "imp"
  phase: "IMP"
  feature: "tsumigi-v3-harness"
  imp_version: "1.2.0"
  status: "active"
  created_at: "2026-04-04T00:00:00Z"
  updated_at: "2026-04-05T00:00:00Z"
  drift_baseline: "2eef7040c9b669f7537c6af228a8e0ab9821d3d0"

coherence:
  id: "imp:tsumigi-v3-harness"
  depends_on:
    - id: "req:tsumigi-v3-harness"
      relation: "implements"
      confidence: 0.95
      required: true
    - id: "design:tsumigi-v3-harness"
      relation: "derives_from"
      confidence: 0.95
      required: true
  modules:
    - "commands"
    - "hooks"
    - "agents"
    - "graph"
    - "config"
  band: "Green"

baton:
  phase: "imp"
  auto_step: false
  pending_label: "pending:next-phase"
  issue_number: null
---

# Implementation Plan（IMP）: tsumigi v3.0 Harness Engineering 統合

**Feature**: `tsumigi-v3-harness`  
**IMP バージョン**: 1.2.0  
**対象 TDS**: `.kiro/specs/tsumigi-v3-harness/design.md`（Phase Gate TDS→IMP: PASS 済み）  
**作成日**: 2026-04-04  
**AUTO_STEP**: false（Manual Baton Mode 前提）

> **Issue 構造・ラベル定義・フェーズ FSM の詳細**: `.kiro/specs/tsumigi-v3-harness/design.md` §1〜§3 を参照。  
> 本 IMP は TDS の設計を実装粒度に変換したものであり、Issue 構造の一次定義は design.md が保持する。

---

## 0. IMP Overview

### 対象プロジェクト

**tsumigi v3.0 — Harness Engineering 統合**

VCKD v2.0 仕様書（`docs/unified-framework-spec-v2.0.md`）が定める
Label-Driven Baton Architecture・AUTO_STEP 制御・Phase Agent 専門化・CEG frontmatter
を tsumigi コマンド群として実装する。

### 対象タスクと波形

| 波形 | タスク | 内容 | 並列可否 |
|------|--------|------|---------|
| **P0** | T01 | Baton Infrastructure セットアップ | ✅ 並列可 |
| **P0** | T02 | CEG frontmatter 標準化 | ✅ 並列可 |
| **P0** | T03 | Phase Gate ロジック実装 | ⚠️ T01 完了後 |
| **P0** | T04 | Phase Agent SP（REQ/TDS/IMP） | ✅ 並列可 |
| **P1** | T05 | GitHub Actions 統合 | ⚠️ T01, T04 完了後 |
| **P1** | T06 | Phase Agent SP（TEST/OPS/CHANGE） | ⚠️ T04 完了後 |
| **P1** | T07 | coherence-scan / baton-status コマンド | ⚠️ T01, T02 完了後 |
| **P1** | T08 | 後方互換性（harness.enabled=false） | ⚠️ T01, T03 完了後 |
| **P1** | T09 | rescue コマンドと escalate 処理 | ⚠️ T04, T06 完了後 |
| **P2** | T10 | Bash テストスクリプト実装（T01/T04/T07） | ✅ 並列可 |
| **P2** | T11 | `VCKD_FROM_PHASE` 許可リスト検証 | ✅ 並列可 |
| **P2** | T12 | IMP.md ロールバック計画セクション追記 | ✅ 並列可 |
| **P2** | T13 | `phases.json` 外部化（drift D1 解消） | ✅ 並列可 |
| **P2** | T14 | `vckd-pipeline.yml` timeout-minutes 追加（drift D5 解消） | ✅ 並列可 |
| **P2** | T15 | 中間状態ロールバック手順文書化 | ✅ 並列可 |
| **P2** | T16 | `req:tsumigi-v3-harness` ノード登録（Amber 解消） | ✅ 並列可 |
| **P2** | T17 | 並列負荷テスト追加（Q6 回答） | ✅ 並列可 |
| **P2** | T18 | macOS 互換対応（bash 3.2 / `grep -oP`） | ✅ 並列可 |

### この IMP の目的

TDS（design.md）の設計を「実装者が迷わずコードを書ける」粒度に変換する。
各タスクについて I/O・アルゴリズム・エラー処理・テスト観点を明確化し、
実装判断の曖昧さを排除する。

---

## 1. Task Specifications

---

### T01: Baton Infrastructure セットアップ

#### 1.1 Purpose

Label-Driven Baton の動作基盤を構築する。
GitHub Labels・設定ファイル・Hooks・baton-log.json / coherence.json の初期化を行い、
「`/tsumigi:install --harness` を実行すれば即座にバトンが動く」状態を作る。

**TDS 対応セクション**: §1.2（コンポーネント構造）, §3.2〜3.4（スキーマ）, §16.2（Hook 実装）

#### 1.2 Inputs

| 入力 | 型・形式 | 説明 |
|------|---------|------|
| `docs/unified-framework-spec-v2.0.md` §5.4 | Markdown | ラベル完全一覧（phase:* / pending:* / blocked:* / approve） |
| `docs/unified-framework-spec-v2.0.md` §16.2 | Markdown | Hook 実装方式 A（Claude Code）の仕様 |
| TDS §3.4 `.vckd/config.yaml` スキーマ | YAML Schema | デフォルト設定値の定義 |
| TDS §3.2 `baton-log.json` スキーマ | JSON Schema | 初期ファイルの構造 |
| TDS §3.3 `coherence.json` スキーマ | JSON Schema | 初期ファイルの構造 |

**依存タスク**: なし（T01 は P0 の起点）

#### 1.3 Outputs

| 出力ファイル | 操作 | 内容 |
|------------|------|------|
| `.vckd/config.yaml` | 新規作成 | `harness.enabled=true, AUTO_STEP=false` のデフォルト設定 |
| `.tsumigi/hooks/post-tool-use.sh` | 新規作成 | VCKD_GATE_RESULT 環境変数を読み `dispatch_baton` を呼ぶシェルスクリプト |
| `.claude/settings.json` | 更新（マージ） | `PostToolUse` フックに `post-tool-use.sh` を追加 |
| `graph/baton-log.json` | 新規作成 | `{"version":"1.0.0","transitions":[],"pending":{}}` |
| `graph/coherence.json` | 新規作成 | `{"version":"1.0.0","nodes":{},"edges":[],"summary":{...}}` |
| `commands/install.md` | 更新 | `--harness` フラグで上記ファイル群を生成するステップを追加 |
| `commands/baton-status.md` | 新規作成 | `baton-log.json` を読んで現在の状態を表示するコマンド |

**GitHub API 副作用**:
- `gh label create` で以下のラベルをリポジトリに作成（存在する場合はスキップ）:
  `phase:req`, `phase:tds`, `phase:imp`, `phase:test`, `phase:ops`, `phase:change`, `phase:done`,
  `pending:next-phase`, `approve`, `blocked:req`, `blocked:tds`, `blocked:imp`, `blocked:ops`,
  `blocked:escalate`, `human:review`

#### 1.4 Implementation Strategy

**`.vckd/config.yaml` の生成**:

```yaml
# テンプレート（install.md が生成する内容）
harness:
  enabled: true
  AUTO_STEP: false
  mode: "claude-code-hooks"
  baton:
    post_comment: true
    pending_label: "pending:next-phase"
    approve_label: "approve"
kiro:
  use_cc_sdd: "auto"
  kiro_dir: ".kiro"
codd:
  cli_path: null
```

**`.tsumigi/hooks/post-tool-use.sh` の構造**:

```
入力環境変数:
  VCKD_GATE_RESULT  = "PASS" | "FAIL" | ""（空なら何もしない）
  VCKD_FROM_PHASE   = "REQ" | "TDS" | "IMP" | "TEST" | "OPS"
  VCKD_ISSUE_NUMBER = <整数>

処理フロー:
  1. 必須変数の存在確認（空ならexit 0）
  2. .vckd/config.yaml を読み harness.enabled と AUTO_STEP を取得
  3. harness.enabled=false なら exit 0（後方互換）
  4. VCKD_GATE_RESULT="PASS" なら dispatch_baton を呼ぶ
  5. VCKD_GATE_RESULT="FAIL" なら emit_blocked を呼ぶ
  6. 処理結果を baton-log.json に追記
```

**`.claude/settings.json` へのマージ方針**:

- 既存 settings.json が存在する場合: `PostToolUse` 配列に追記（上書きしない）
- 存在しない場合: 新規作成
- `jq` コマンドで安全にマージする（破壊的変更禁止）

**`commands/baton-status.md` の出力形式**:

```
## バトン状態: <issue-id>

### 現在のラベル
  phase:imp（GitHub から取得）

### pending 状態
  次フェーズ候補: phase:test（baton-log.json より）
  記録日時: 2026-04-04T10:00:00Z

### 直近 5 件のバトン遷移
  | 日時 | Issue | from → to | mode |
  |------|-------|----------|------|
  | ... | ... | ... | ... |
```

#### 1.5 Edge Cases / Exceptions

| ケース | 対処 |
|--------|------|
| `.claude/settings.json` に既に PostToolUse フックが存在する | 重複追加しない（スクリプトパスで重複判定） |
| `gh` CLI が未インストール | インストール確認ステップをコマンド冒頭に追加。未インストールなら警告して終了 |
| `graph/` ディレクトリが存在しない | `mkdir -p graph/` で自動作成 |
| GitHub Labels 作成時にアクセス権がない | エラーをキャッチして「権限がないため手動で作成してください」と案内 |
| `.vckd/config.yaml` が既に存在する（再実行時） | 既存ファイルを `--force` フラグなしで上書きしない。差分確認を促す |

#### 1.6 Test Strategy

| TC-ID | AC-ID | テスト観点 | レイヤー |
|-------|-------|----------|---------|
| TC-T01-01 | REQ-001-AC-1 | `phase:req` ラベル付与後に RequirementsAgent が起動することを確認 | integration |
| TC-T01-02 | REQ-002-AC-3 | `.vckd/config.yaml` が存在しない状態で `dispatch_baton` を呼ぶと `AUTO_STEP=false` として動作する | unit |
| TC-T01-03 | REQ-004-AC-2 | `emit_baton` 実行後に `graph/baton-log.json` に遷移が記録される | unit |
| TC-T01-04 | - | `.claude/settings.json` に既存フックがある場合、重複追加されない | unit |
| TC-T01-05 | - | `graph/` が存在しない環境でも `install --harness` が正常完了する | integration |

**モック対象**: `gh label create`（ラベル作成のテストは `--dry-run` フラグで実施）

---

### T02: CEG frontmatter 標準化

#### 1.1 Purpose

全成果物ファイルに `coherence:` + `baton:` frontmatter を付与する。
これにより `coherence-scan`（T07）が全ノードを収集できる状態を作る。

**TDS 対応セクション**: §4.2（完全スキーマ定義）, §3.1 ER 図

#### 1.2 Inputs

| 入力 | 型・形式 | 説明 |
|------|---------|------|
| TDS §4.2 frontmatter スキーマ | YAML Schema | tsumigi: / coherence: / baton: の全フィールド定義 |
| `commands/imp_generate.md`（既存） | Markdown | 拡張対象 |
| `commands/implement.md`（既存） | Markdown | 拡張対象 |
| `commands/rev.md`（既存） | Markdown | 拡張対象 |

**依存タスク**: なし

#### 1.3 Outputs

| 出力ファイル | 操作 | 変更内容 |
|------------|------|---------|
| `commands/imp_generate.md` | 更新 | IMP.md 生成時に coherence + baton frontmatter を先頭に付与するステップを追加 |
| `commands/implement.md` | 更新 | patch-plan.md 生成時に coherence frontmatter（node_id: impl:）を付与 |
| `commands/rev.md` | 更新 | rev-*.md 生成時に coherence frontmatter（node_id: rev-api: 等）を付与 |
| `.tsumigi/templates/imp-template.md` | 新規作成 | frontmatter 付き IMP.md のひな形 |

#### 1.4 Implementation Strategy

**frontmatter 付与の実装方針**:

各コマンド（.md ファイル）の「成果物生成ステップ」に以下の処理を追加する。

```
生成手順（imp_generate.md の例）:
  1. IMP.md の本文を生成する（既存ロジック）
  2. 以下の frontmatter を本文の先頭に付与して Write する:

  ---
  tsumigi:
    node_id: "imp:<issue-id>"
    artifact_type: "imp"
    phase: "IMP"
    issue_id: "<issue-id>"
    feature: "<feature-name>"  # .kiro/specs/<feature>/ から推論
    imp_version: "1.0.0"
    status: "active"
    created_at: "<ISO8601>"
    drift_baseline: "<git rev-parse HEAD>"
  coherence:
    id: "imp:<issue-id>"
    depends_on:
      - id: "req:<feature>"
        relation: "implements"
        confidence: 0.95
        required: true
      - id: "design:<feature>"
        relation: "derives_from"
        confidence: 0.95
        required: true
    modules: ["<module-1>", ...]  # IMP.md から変更対象モジュールを推論
    band: "Green"
    last_validated: "<ISO8601>"
  baton:
    phase: "imp"
    auto_step: false
    issue_number: <N>
  ---
```

**`feature` の推論ロジック**:
1. `.kiro/specs/` 以下のサブディレクトリを列挙
2. `tasks.md` に現在の `issue-id` が含まれるディレクトリを feature とみなす
3. 見つからない場合は `feature: null` として記録し警告を出す

**`.tsumigi/templates/imp-template.md`**:
frontmatter の空テンプレートと各セクション（Overview・受け入れ基準・タスク一覧・リスク）
の雛形を提供する。`imp_generate.md` から `Read` して変数を埋める形で使用する。

#### 1.5 Edge Cases / Exceptions

| ケース | 対処 |
|--------|------|
| 既存の IMP.md に frontmatter がすでに存在する（再実行時） | `---` で始まる既存 frontmatter を検出し、スキップ or 上書き確認 |
| `feature` の推論に失敗する | `feature: "unknown"` で記録、coherence-scan が警告を出すことで検知 |
| `git rev-parse HEAD` が失敗する（git 未初期化） | `drift_baseline: ""` として空文字を記録する |

#### 1.6 Test Strategy

| TC-ID | AC-ID | テスト観点 | レイヤー |
|-------|-------|----------|---------|
| TC-T02-01 | REQ-005-AC-1 | `imp_generate` 実行後の IMP.md に coherence frontmatter が存在する | unit |
| TC-T02-02 | REQ-005-AC-1 | `implement` 実行後の patch-plan.md に frontmatter が存在する | unit |
| TC-T02-03 | REQ-005-AC-1 | 既存 IMP.md に frontmatter がある場合、重複付与されない | unit |
| TC-T02-04 | - | `feature` 推論が失敗した場合、警告が出て処理が継続される | unit |

---

### T03: Phase Gate ロジック実装

#### 1.1 Purpose

`check_phase_gate()` / `dispatch_baton()` / `emit_pending()` / `emit_baton()` / `emit_blocked()` / `on_label_added()` を Bash で実装する。
これがバトンシステムの心臓部であり、AUTO_STEP=false/true の分岐制御を担う。

**TDS 対応セクション**: §2.1.2（GateResult 構造体）, §2.2（GitHub API）, §5.2（バトン発行ロジック疑似コード）

#### 1.2 Inputs

| 入力 | 型・形式 | 説明 |
|------|---------|------|
| 環境変数 `VCKD_GATE_RESULT` | "PASS"\|"FAIL"\|"" | Phase Gate の判定結果 |
| 環境変数 `VCKD_FROM_PHASE` | "REQ"\|"TDS"\|"IMP"\|"TEST"\|"OPS" | 遷移元フェーズ |
| 環境変数 `VCKD_ISSUE_NUMBER` | 整数 | 対象 Issue 番号 |
| `.vckd/config.yaml` | YAML | AUTO_STEP・enabled・pending_label・approve_label |
| `graph/baton-log.json` | JSON | pending エントリの読み書き |

**依存タスク**: T01（`baton-log.json`・`config.yaml` の存在が前提）

#### 1.3 Outputs

| 出力ファイル | 操作 | 内容 |
|------------|------|------|
| `.tsumigi/lib/phase-gate.sh` | 新規作成 | `check_phase_gate`, `dispatch_baton`, `emit_pending`, `emit_baton`, `emit_blocked` の実装 |
| `.tsumigi/lib/on-label-added.sh` | 新規作成 | `approve` ラベル検知 → バトン発行ハンドラ |
| `graph/baton-log.json` | 更新 | 遷移・pending エントリの追記 |

**GitHub API 副作用**:
- `emit_pending`: ラベル変更（`phase:xxx` → `pending:next-phase`）+ コメント投稿
- `emit_baton`: ラベル変更（`phase:xxx` → `phase:yyy`）+ コメント投稿
- `emit_blocked`: ラベル追加（`blocked:xxx`）+ FAIL 詳細コメント投稿
- `on_label_added`: ラベル変更（`approve` + `pending:next-phase` → `phase:yyy`）+ コメント

#### 1.4 Implementation Strategy

**`dispatch_baton()` のアルゴリズム**:

```bash
dispatch_baton() {
  local issue_number="$1"
  local current_label="$2"   # 例: "phase:imp"
  local next_label="$3"      # 例: "phase:test"

  # 1. harness.enabled チェック（T08 で追加する early-return の準備箇所）
  local enabled
  enabled=$(yq '.harness.enabled' .vckd/config.yaml 2>/dev/null || echo "false")
  [[ "$enabled" != "true" ]] && return 0

  # 2. AUTO_STEP 読み込み（ファイル不在時は false にフォールバック）
  local auto_step
  auto_step=$(yq '.harness.AUTO_STEP' .vckd/config.yaml 2>/dev/null || echo "false")

  # 3. 分岐
  if [[ "$auto_step" == "true" ]]; then
    emit_baton "$issue_number" "$current_label" "$next_label"
  else
    local pending_label
    pending_label=$(yq '.harness.baton.pending_label' .vckd/config.yaml \
                    2>/dev/null || echo "pending:next-phase")
    emit_pending "$issue_number" "$current_label" "$pending_label" "$next_label"
  fi
}
```

**`emit_pending()` の baton-log 更新**:

```bash
# jq でアトミックに pending エントリを更新
local tmp
tmp=$(mktemp)
jq --arg issue "$issue_number" \
   --arg next  "$next_candidate" \
   --arg ts    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   '.pending[$issue] = {next: $next, recorded_at: $ts}' \
   graph/baton-log.json > "$tmp" && mv "$tmp" graph/baton-log.json
```

**`on_label_added()` の処理フロー**:

```
1. approve_label 以外が付与された場合は即 return
2. pending_label が Issue に存在するか gh_get_labels で確認
   → 存在しない場合: error コメントを投稿して return
3. baton-log.json から pending[$issue].next を取得
   → 取得失敗: error コメントを投稿して return
4. gh issue edit: approve_label を削除
5. gh issue edit: pending_label を削除
6. gh issue edit: next_candidate を追加
7. baton-log.json の pending[$issue] エントリを削除
8. baton-log.json の transitions に遷移を追記（mode: "manual"）
9. gh issue comment: 承認完了コメントを投稿
```

**`check_phase_gate()` の実装方針**:

TDS §5.2 の疑似コードを忠実に Bash に変換する。
4つのステップ（必須成果物確認→CEG 整合性→フェーズ固有チェック→Gray ノード確認）を
それぞれ独立した関数（`_check_artifacts`, `_check_ceg`, `_check_phase_specific`, `_check_gray`）
として実装し、`check_phase_gate` が順番に呼び出す構造にする。

フェーズ固有チェックは `phase-gate.sh` の `_check_phase_specific()` 内に Bash `case` 文として直接実装されている:

```bash
# .tsumigi/lib/phase-gate.sh — _check_phase_specific() の実装方式
case "$from_phase" in
  REQ)  # requirements.md の AC が 3 件以上あること
        ac_count=$(grep -c "REQ-[0-9]*-AC-[0-9]*" "..."); (( ac_count >= 3 )) ;;
  TDS)  # design.md と tasks.md の存在確認のみ（_check_artifacts で実施済み）
        ;;
  IMP)  # IMP.md に patch-plan パスが記載されていること
        grep -q "patch-plan" "specs/${issue_id}/IMP.md" ;;
  TEST) # adversary-report.md の全体判定が PASS であること
        grep -q "全体判定.*PASS\|PASS" "specs/${issue_id}/adversary-report.md" ;;
  OPS)  # drift-report.md の drift スコアが閾値以下であること
        drift_score=...; (( drift_score <= threshold )) ;;
esac
```

> **設計メモ（背景）**: 当初は外部 JSON ファイル（`phases.json`）でフェーズ定義を管理し、Bash から `jq` で参照する設計だった。
> 実装では Bash `case` 文のインライン実装を採用した。理由: フェーズ遷移ルールの変更頻度が低く、JSON 外部化による複雑性（`jq` の実行・エラーハンドリング）が benefit を上回るため。
> 将来的にフェーズを追加・変更する場合は `_check_phase_specific()` を直接編集する。
> 各フェーズの「必須成果物」定義は `_check_artifacts()` の `case` 文を参照すること。

#### 1.5 Edge Cases / Exceptions

| ケース | 対処 |
|--------|------|
| `gh` コマンドが失敗する（ネットワーク障害等） | 最大 3 回リトライ（exponential backoff: 2s, 4s, 8s）。3 回失敗で `blocked:escalate` を付与 |
| `baton-log.json` が破損している（不正 JSON） | `jq empty` でバリデーション → 失敗なら `baton-log.json.bak` にリネームして再初期化 |
| `approve` ラベルが付与されたが `pending:next-phase` がない | エラーコメントを投稿してリターン。**ラベルの二重操作は行わない** |
| `.vckd/config.yaml` が YAML として不正 | `yq` のエラーをキャッチし `AUTO_STEP=false` にフォールバック（安全側に倒す）。警告をコメント投稿 |
| `VCKD_ISSUE_NUMBER` が整数でない | `[[ "$var" =~ ^[0-9]+$ ]]` で検証。不正値なら exit 2（設定エラー）|

#### 1.6 Test Strategy

| TC-ID | AC-ID | テスト観点 | レイヤー |
|-------|-------|----------|---------|
| TC-T03-01 | REQ-002-AC-1 | `AUTO_STEP=false` のとき `dispatch_baton` が `emit_pending` を呼ぶ | unit |
| TC-T03-02 | REQ-002-AC-2 | `AUTO_STEP=true` のとき `dispatch_baton` が `emit_baton` を呼ぶ | unit |
| TC-T03-03 | REQ-002-AC-3 | `config.yaml` 不在のとき `AUTO_STEP=false` として動作する | unit |
| TC-T03-04 | REQ-001-AC-2 | `emit_pending` 実行後にラベルが `pending:next-phase` に変更される | integration |
| TC-T03-05 | REQ-001-AC-3 | `emit_baton` 実行後にラベルが即座に `phase:yyy` に変更される | integration |
| TC-T03-06 | REQ-001-AC-4 | `approve` 付与後に `pending:next-phase` が外れ次フェーズラベルが付与される | integration |
| TC-T03-07 | REQ-001-AC-5 | `emit_blocked` 実行後に `blocked:xxx` ラベルが付与される | integration |
| TC-T03-08 | REQ-003-AC-1 | `check_phase_gate` で必須ファイルが存在しない場合 FAIL を返す | unit |
| TC-T03-09 | REQ-003-AC-2 | `check_phase_gate` で循環依存が検出された場合 FAIL を返す | unit |
| TC-T03-10 | REQ-003-AC-3 | `check_phase_gate` でフェーズ固有チェックが失敗した場合 FAIL を返す | unit |
| TC-T03-11 | REQ-003-AC-4 | `check_phase_gate` で Gray ノードが存在する場合 FAIL を返す | unit |
| TC-T03-12 | - | `gh` が 3 回失敗後に `blocked:escalate` が付与される | integration |
| TC-T03-13 | - | `baton-log.json` が破損している場合、バックアップ後に再初期化される | unit |

**モック対象**: `gh issue edit`・`gh issue comment`・`gh issue view` はすべてモック関数で代替。
テスト実行時は `VCKD_TEST_MODE=1` を設定し、`gh` の代わりに `mock_gh` を使う。

---

### T04: Phase Agent システムプロンプト（REQ/TDS/IMP）

#### 1.1 Purpose

RequirementsAgent・DesignAgent・ImplementAgent の System Prompt を作成する。
各エージェントは「単一責任・コンテキスト制限・判断基準明示・出力フォーマット固定・エスカレーション条件定義」の 5 原則（TDS §3.4）を満たさなければならない。

**TDS 対応セクション**: §3.4（Phase Agent 専門化マップ）, §16.3（System Prompt 設計ガイドライン）

#### 1.2 Inputs

| 入力 | 説明 |
|------|------|
| TDS §3.4 Agent 一覧（#1〜10） | RequirementsInterviewer, EARSFormatter, Validator, ArchDesigner, APIDesigner, SchemaDesigner, TaskSplitter, IssueGenerator, IMPGenerator, Implementer |
| TDS §16.3 System Prompt ガイドライン | 5 原則の詳細 |
| `commands/spec-req.md`（既存） | RequirementsAgent が実行するコマンドの仕様 |
| `commands/spec-design.md`, `spec-tasks.md` | DesignAgent が実行するコマンドの仕様 |
| `commands/imp_generate.md`, `implement.md` | ImplementAgent が実行するコマンドの仕様 |

**依存タスク**: なし

#### 1.3 Outputs

| ファイル | 担当エージェント |
|---------|----------------|
| `.tsumigi/agents/requirements-agent.md` | RequirementsInterviewer + EARSFormatter + Validator |
| `.tsumigi/agents/design-agent.md` | ArchDesigner + APIDesigner + SchemaDesigner + TaskSplitter |
| `.tsumigi/agents/implement-agent.md` | IMPGenerator + Implementer |

#### 1.4 Implementation Strategy

各 agent ファイルは TDS §16.3 のテンプレートに従い、以下の構造で記述する：

```markdown
# <AgentName> System Prompt

## あなたの役割
（単一責任の明示）

## 実行環境の確認
- VCKD_ISSUE_NUMBER 環境変数の取得
- .vckd/config.yaml の読み込み（AUTO_STEP の確認）

## 入力（読んでよいもの）
（具体的なファイルパスのリスト）

## 入力（読んではいけないもの）
（コンテキスト汚染防止のリスト）

## 実行手順
（番号付きの具体的なステップ）

## Phase Gate の実行
- 成果物生成完了後に check_phase_gate を呼ぶ
- 環境変数 VCKD_GATE_RESULT にセットしてフックを起動する

## 成功判定（PASS/FAIL の基準）
（明示的な判定ロジック）

## リトライポリシー
- 最大リトライ: 3 回
- 失敗時: blocked:escalate を付与し理由をコメント
```

**RequirementsAgent の特記事項**:
- Issue body が AC 3 件未満の場合は RequirementsInterviewer モードに切り替え、
  5W1H 質問を GitHub コメントで投稿して AC を引き出す
- EARS 変換後に RequirementsValidator を呼んで AC-ID の重複・EARS 形式を確認する

**ImplementAgent の特記事項**:
- IMP.md が存在しない場合は先に `imp_generate` を実行してから `implement` に進む
- P0 タスクの実装が完了したら P1 タスクの Issue に `phase:imp` を自動付与する
  （IssueGenerator が付与した `wave:P0` / `wave:P1` ラベルを参照する）

#### 1.5 Edge Cases / Exceptions

| ケース | 対処 |
|--------|------|
| Issue body が空 | RequirementsInterviewer モード起動。質問 5 件を投稿して待機 |
| spec-req コマンドがエラー終了 | コマンドのエラー出力を Issue コメントに貼り付けてリトライ |
| .kiro/specs/ ディレクトリが存在しない | `mkdir -p` で作成してから続行 |
| タスクが依存 Issue を参照するが当該 Issue が未完了 | `wave:P0` ラベルを持つ Issue の `phase:done` を確認してから P1 を起動 |

#### 1.6 Test Strategy

| TC-ID | AC-ID | テスト観点 | レイヤー |
|-------|-------|----------|---------|
| TC-T04-01 | REQ-007-AC-1 | RequirementsAgent 起動後に requirements.md が生成される | e2e |
| TC-T04-02 | REQ-007-AC-2 | 3 回リトライ後に `blocked:escalate` が付与される | integration |
| TC-T04-03 | - | Issue body が空のとき RequirementsInterviewer モードになる | integration |
| TC-T04-04 | - | P0 タスク完了後に P1 Issue の `phase:imp` が付与される | integration |

---

### T05: GitHub Actions 統合

#### 1.1 Purpose

`issues: [labeled]` イベントを監視し、`phase:*` ラベルに対応する Phase Agent を
Claude Code（ヘッドレスモード）で起動する GitHub Actions ワークフローを実装する。

**TDS 対応セクション**: §16.2 方式 B（GitHub Actions）

#### 1.2 Inputs

| 入力 | 説明 |
|------|------|
| GitHub Actions イベント `github.event.label.name` | 付与されたラベル名 |
| GitHub Actions イベント `github.event.issue.number` | Issue 番号 |
| `.tsumigi/agents/*.md`（T04, T06 の成果物） | Phase Agent のシステムプロンプト |
| `secrets.ANTHROPIC_API_KEY` | Claude API キー |
| `secrets.GITHUB_TOKEN` | PR/Comment 操作用トークン |

**依存タスク**: T01（`config.yaml` の存在）, T04（`agents/` の存在）

#### 1.3 Outputs

| ファイル | 操作 |
|---------|------|
| `.github/workflows/vckd-pipeline.yml` | 新規作成 |

#### 1.4 Implementation Strategy

```yaml
# .github/workflows/vckd-pipeline.yml の構造

name: VCKD Autonomous Pipeline

on:
  issues:
    types: [labeled]

# ラベル → エージェントのルーティングテーブル
# phase:req → requirements-agent.md
# phase:tds → design-agent.md
# phase:imp → implement-agent.md
# phase:test → test-agent.md
# phase:ops → ops-agent.md
# phase:change → change-agent.md
# approve → on-label-added.sh（直接 Bash 実行、Agent 不要）

jobs:
  route-agent:
    条件: labels が "phase:" で始まるか "approve" の場合のみ実行

  run-phase-agent:
    steps:
      - checkout
      - setup-node (for gh CLI if needed)
      - Determine agent from label
      - Run Claude Code with system prompt
        環境変数:
          VCKD_ISSUE_NUMBER: ${{ github.event.issue.number }}
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**`approve` ラベルの処理**:
- GitHub Actions でも `on_label_added.sh` を呼び出す
- Claude Code 起動は不要（純粋な Bash 処理）

**同時実行制御**:
- `concurrency: group: "vckd-issue-${{ github.event.issue.number }}"` で
  同一 Issue への並列実行を防ぐ

#### 1.5 Edge Cases / Exceptions

| ケース | 対処 |
|--------|------|
| `approve` と `phase:xxx` が同時に付与された | `approve` を優先処理。`on_label_added.sh` を先に実行 |
| `ANTHROPIC_API_KEY` が未設定 | ワークフロー冒頭でチェック。未設定なら skip してコメントで通知 |
| Actions の実行時間が 6h を超える | ジョブをタスク単位で分割して呼び出す（IMP の 1 タスク = 1 ジョブ実行） |

#### 1.6 Test Strategy

| TC-ID | AC-ID | テスト観点 | レイヤー |
|-------|-------|----------|---------|
| TC-T05-01 | REQ-001-AC-1 | `phase:req` 付与 → Actions 起動 → RequirementsAgent が実行される | e2e |
| TC-T05-02 | - | 同一 Issue への並列実行が防止される | integration |
| TC-T05-03 | - | `approve` ラベルで `on_label_added.sh` が呼ばれる | integration |
| TC-T05-04 | - | `ANTHROPIC_API_KEY` 未設定で失敗せずに通知が出る | unit |

---

### T06: Phase Agent システムプロンプト（TEST/OPS/CHANGE）

#### 1.1 Purpose

TestAgent・AdversaryAgent・OpsAgent・ChangeAgent の System Prompt を作成する。
特に AdversaryAgent は「コンテキスト分離」と「強制否定バイアス」が核心であり、
読んではいけないファイルの列挙が最重要の設計ポイントとなる。

**TDS 対応セクション**: §3.4 Agent #11〜21, §4.2 UC-004（Adversarial Review）

#### 1.2 Inputs

| 入力 | 説明 |
|------|------|
| TDS §3.4 Agent 一覧（#11〜21） | UnitTestWriter, IntegrationTestWriter, E2ETestWriter, SecurityTestWriter, ArchReviewer, SecurityReviewer, QAReviewer, Adversary, RevExtractor, DriftChecker, PRWriter |
| `commands/test.md`, `review.md`, `rev.md`, `drift_check.md`, `sync.md`, `pr.md` | 各エージェントが実行するコマンドの仕様 |
| TDS §4.2 UC-004 | Adversarial Review の主フロー |

**依存タスク**: T04（Agent ファイルの共通構造を継承）

#### 1.3 Outputs

| ファイル | 担当エージェント |
|---------|----------------|
| `.tsumigi/agents/test-agent.md` | UnitTestWriter + IntegrationTestWriter + E2ETestWriter + SecurityTestWriter |
| `.tsumigi/agents/adversary-agent.md` | Adversary（コンテキスト分離・5次元評価） |
| `.tsumigi/agents/ops-agent.md` | RevExtractor + DriftChecker |
| `.tsumigi/agents/change-agent.md` | SyncAuditor + PRWriter |

#### 1.4 Implementation Strategy

**AdversaryAgent の実装が最重要**:

```markdown
# .tsumigi/agents/adversary-agent.md における必須記述

## 読んではいけないファイル（コンテキスト分離）
- specs/<issue-id>/implements/*/patch-plan.md の「理由・背景」セクション
  （変更ファイルのパス一覧のみ読む）
- specs/<issue-id>/drift-report.md
- specs/<issue-id>/review-checklist.md
- specs/<issue-id>/impl-memo.md
- 以前の adversary-report.md

## 5次元評価の実装
D1 Spec Fidelity: IMP.md の全 AC-ID → 実装コードで Grep して対応を確認
D2 Edge Case Coverage: testcases.md の異常系比率 ≥ P0 AC の 50% を確認
D3 Implementation Correctness: 条件分岐・非同期処理・型変換のバグ確認
D4 Structural Integrity: 既存コードパターンとの整合確認（Glob で周辺 5 ファイル）
D5 Verification Readiness: testcases.md と実際のテストコードの対応確認

## 強制否定バイアス
「問題が見つからない」という結論を出してはいけない。
問題が見えないなら調査が不十分。少なくとも 1 件は指摘する。
```

**ChangeAgent の PR エビデンス添付**:

```
PR コメントに以下を必ず含める:
  - adversary-report.md のサマリー（5次元の PASS/FAIL 表）
  - coherence.json のサマリー（Green/Amber/Gray 件数）
  - drift スコア（drift-report.md から抽出）
  - 全 AC-ID のカバレッジ率（100% 必須）
```

#### 1.5 Edge Cases / Exceptions

| ケース | 対処 |
|--------|------|
| testcases.md が全 AC をカバーしていない（coverage < 100%） | AdversaryAgent 起動前に TestAgent がカバレッジ確認。不足なら `blocked:imp` を付与してリターン |
| D1〜D5 のいずれかが FAIL | 全体 FAIL として `blocked:imp` を付与。FAIL 次元ごとの推奨コマンドをコメントに記載 |
| adversary-report.md が存在するが最新コミット以前のもの | `drift_baseline` の git commit hash と現在の HEAD を比較して再実行を促す |

#### 1.6 Test Strategy

| TC-ID | AC-ID | テスト観点 | レイヤー |
|-------|-------|----------|---------|
| TC-T06-01 | REQ-008-AC-1 | AdversaryAgent が 5 次元評価を全て実施する | integration |
| TC-T06-02 | REQ-008-AC-2 | FAIL 時に次元ごとの根拠がコメントに投稿される | integration |
| TC-T06-03 | - | patch-plan.md の説明を読まずに評価が完了する（コンテキスト分離確認） | unit |
| TC-T06-04 | REQ-007-AC-1 | ChangeAgent が PR にエビデンス 4 点を添付する | e2e |

---

### T07: coherence-scan と baton-status コマンド

#### 1.1 Purpose

`graph/coherence.json` を全成果物の frontmatter から再構築するコマンドと、
現在のバトン遷移状態を一覧表示するコマンドを実装する。

**TDS 対応セクション**: §3.2（baton-log.json スキーマ）, §3.3（coherence.json スキーマ）

#### 1.2 Inputs

| 入力 | 説明 |
|------|------|
| `specs/**/*.md` | coherence frontmatter を持つ全成果物 |
| `.kiro/specs/**/*.md` | REQ/TDS フェーズの成果物 |
| `graph/baton-log.json` | バトン遷移ログ |
| GitHub Issue labels（`gh issue list`） | 現在のフェーズ状態 |

**依存タスク**: T01（`graph/` ディレクトリの存在）, T02（frontmatter の存在）

#### 1.3 Outputs

| ファイル | 操作 | 内容 |
|---------|------|------|
| `commands/coherence-scan.md` | 新規作成 | frontmatter を収集して `coherence.json` を再構築するコマンド |
| `commands/baton-status.md` | 更新（T01 で骨格作成済み） | GitHub ラベル + baton-log の状態を統合表示 |
| `graph/coherence.json` | 更新（コマンド実行時） | 全ノード・エッジのスナップショット |

#### 1.4 Implementation Strategy

**`coherence-scan.md` のスキャンアルゴリズム**:

```
Step 1: 対象ファイルの収集
  - Glob で specs/**/*.md と .kiro/specs/**/*.md を列挙
  - 各ファイルの先頭 30 行を Read して frontmatter（--- ... ---）を抽出

Step 2: ノード構築
  - coherence.id をキーにして nodes オブジェクトに追加
  - artifact_type / phase / band / confidence / file を記録

Step 3: エッジ構築
  - coherence.depends_on の各エントリを edges 配列に追加

Step 4: バリデーション
  - 循環依存チェック（DFS）
  - 参照先が存在しないエッジの検出（dangling reference）
  - 検出された問題を警告として出力（エラーで停止しない）

Step 5: サマリー計算と書き込み
  - Green/Amber/Gray の件数を集計
  - graph/coherence.json を Write（アトミック）
```

**`baton-status.md` の表示形式**:

```markdown
## VCKD バトン状態レポート

### アクティブな Issue（phase:* ラベル付き）
| Issue | ラベル | 直近バトン | 記録日時 |
|-------|--------|----------|---------|

### 承認待ち（pending:next-phase）
| Issue | 次フェーズ候補 | 記録日時 |
|-------|-------------|---------|

### ブロック中（blocked:*）
| Issue | ラベル | 修正コマンド |
|-------|--------|-----------|

### 直近 10 件のバトン遷移
| 日時 | Issue | from → to | mode |
```

#### 1.5 Edge Cases / Exceptions

| ケース | 対処 |
|--------|------|
| frontmatter が壊れている（YAML パースエラー） | ファイルパスと行番号を警告出力してスキップ |
| 循環依存が検出された | 循環しているノード ID のチェーンを警告として表示。スキャン自体は完了させる |
| dangling reference（参照先ノードが存在しない） | 警告出力。coherence.json には記録するが band を "Amber" に強制設定 |

#### 1.6 Test Strategy

| TC-ID | AC-ID | テスト観点 | レイヤー |
|-------|-------|----------|---------|
| TC-T07-01 | REQ-005-AC-2 | `coherence-scan` 実行後に全成果物ノードが `coherence.json` に存在する | integration |
| TC-T07-02 | REQ-004-AC-2 | `baton-status` が `baton-log.json` の pending エントリを正確に表示する | unit |
| TC-T07-03 | - | 循環依存が存在するリポジトリで `coherence-scan` が警告を出して完了する | unit |
| TC-T07-04 | - | frontmatter が壊れたファイルがあっても他のファイルはスキャン完了する | unit |

---

### T08: 後方互換性（harness.enabled=false モード）

#### 1.1 Purpose

`harness.enabled=false` のとき、全コマンドが v1.0（tsumigi v2 以前）と同一の動作をすることを保証する。
`dispatch_baton` を含む全バトン関数の冒頭に `enabled` チェックを追加し、
ラベル変更・コメント投稿が一切発生しないようにする。

**TDS 対応セクション**: §16.6（後方互換性）

#### 1.2 Inputs

| 入力 | 説明 |
|------|------|
| `.tsumigi/lib/phase-gate.sh`（T03 の成果物） | `enabled` チェックを追加する対象 |
| `commands/install.md`（T01 の成果物） | `--harness` なし時の初期動作を定義する対象 |

**依存タスク**: T01, T03

#### 1.3 Outputs

| ファイル | 変更内容 |
|---------|---------|
| `.tsumigi/lib/phase-gate.sh` | 全関数の冒頭に `[[ "$enabled" != "true" ]] && return 0` を追加 |
| `commands/install.md` | `--harness` フラグなし時は `harness.enabled=false` の config.yaml を生成するステップを追加 |

#### 1.4 Implementation Strategy

**enabled チェックの追加場所**:

```bash
# phase-gate.sh 内の全公開関数に追加
_check_harness_enabled() {
  local enabled
  enabled=$(yq '.harness.enabled' .vckd/config.yaml 2>/dev/null || echo "false")
  [[ "$enabled" == "true" ]]
}

dispatch_baton() {
  _check_harness_enabled || return 0  # ← この 1 行を先頭に追加
  # ... 既存ロジック
}

emit_pending()  { _check_harness_enabled || return 0; ... }
emit_baton()    { _check_harness_enabled || return 0; ... }
emit_blocked()  { _check_harness_enabled || return 0; ... }
on_label_added(){ _check_harness_enabled || return 0; ... }
```

**`install.md` の分岐**:

```
引数なしまたは --no-harness 指定の場合:
  .vckd/config.yaml を harness.enabled=false で生成
  graph/ ディレクトリは作成しない
  GitHub Labels は作成しない

--harness 指定の場合:
  .vckd/config.yaml を harness.enabled=true で生成
  graph/ ディレクトリを作成
  GitHub Labels を作成
```

#### 1.5 Edge Cases / Exceptions

| ケース | 対処 |
|--------|------|
| config.yaml が存在しない | `enabled` のデフォルトを `false` に設定（既に T03 で実装済み） |
| `harness.enabled=false` で `coherence-scan` を実行した場合 | スキャン自体は実行可能（ローカル処理のみ）。GitHub API は呼ばない |

#### 1.6 Test Strategy

| TC-ID | AC-ID | テスト観点 | レイヤー |
|-------|-------|----------|---------|
| TC-T08-01 | REQ-006-AC-1 | `harness.enabled=false` でコマンドを実行しても Phase Gate が v1.0 互換で動作する | integration |
| TC-T08-02 | REQ-006-AC-2 | `harness.enabled=false` で `dispatch_baton` を呼んでもラベル変更・コメントが発生しない | unit |
| TC-T08-03 | - | `install` 実行（`--harness` なし）で `enabled=false` の config.yaml が生成される | unit |

---

### T09: rescue コマンドと escalate 処理

#### 1.1 Purpose

エージェントが手詰まり（`blocked:escalate`）になったときに人間がローカルで救出できる
コマンドと、エージェントが自動でエスカレーションするリトライポリシーを実装する。

**TDS 対応セクション**: §4.2 UC-006, §3.4 Agent リトライポリシー

#### 1.2 Inputs

| 入力 | 説明 |
|------|------|
| `ISSUE_NUMBER` 引数（rescue コマンド） | 救出する Issue 番号 |
| `graph/baton-log.json` | リトライカウント・エスカレーション理由 |
| `.tsumigi/agents/*.md`（T04, T06 の成果物） | リトライロジックを追記する対象 |

**依存タスク**: T04, T06

#### 1.3 Outputs

| ファイル | 操作 | 内容 |
|---------|------|------|
| `commands/rescue.md` | 新規作成 | `blocked:*` / `blocked:escalate` を解除して Phase Agent を再起動するコマンド |
| `.tsumigi/agents/*.md` | 全ファイル更新 | リトライカウント管理・3 回失敗後の escalate 処理を追記 |
| `graph/baton-log.json` | スキーマ拡張 | `retries` / `last_error` フィールドを追加 |

#### 1.4 Implementation Strategy

**`baton-log.json` への `retries` フィールド追加**:

```json
{
  "pending": {
    "42": {
      "next": "phase:test",
      "recorded_at": "...",
      "retries": 2,             // ← 追加
      "last_error": "...",      // ← 追加
      "agent": "TestAgent"      // ← 追加
    }
  }
}
```

**エージェントのリトライロジック（agents/*.md に追記）**:

```
## リトライポリシー

実行前に baton-log.json から現在の retries カウントを取得する。

retries < 3 の場合:
  エラーを記録して再試行する
  baton-log.json の retries をインクリメントする

retries >= 3 の場合:
  blocked:escalate ラベルを Issue に付与する
  以下の形式でコメントを投稿する:
    🆘 Agent Escalation: <AgentName>
    リトライ回数: 3/3
    最後のエラー: <エラー内容>
    推奨アクション: /tsumigi:rescue <issue-number> を実行してください
  処理を終了する（exit 3）
```

**`rescue.md` の処理フロー**:

```
Step 1: 引数から ISSUE_NUMBER を取得
Step 2: 現在のラベルを gh issue view で取得
Step 3: 以下のラベルを削除:
  - blocked:escalate
  - blocked:req / blocked:tds / blocked:imp / blocked:ops（存在すれば）
  - pending:next-phase（存在すれば）
Step 4: baton-log.json の retries を 0 にリセット
Step 5: Human に確認:
  "以下のラベルを再付与して Agent を再起動します: phase:xxx
   続行しますか？ [y/N]"
Step 6: y の場合: phase:xxx ラベルを付与してエージェントを再起動
```

#### 1.5 Edge Cases / Exceptions

| ケース | 対処 |
|--------|------|
| `blocked:escalate` も `blocked:*` も付いていない Issue に rescue を実行 | 「この Issue はブロックされていません」と表示して終了 |
| rescue 後に同じ箇所で再度 escalate になる | retries が 0 にリセットされるため、さらに 3 回試行される。繰り返す場合は人間がシステムプロンプトを修正する必要がある |

#### 1.6 Test Strategy

| TC-ID | AC-ID | テスト観点 | レイヤー |
|-------|-------|----------|---------|
| TC-T09-01 | REQ-007-AC-2 | エージェントが 3 回失敗後に `blocked:escalate` を付与する | integration |
| TC-T09-02 | REQ-007-AC-2 | escalate コメントにリトライ回数・エラー内容・推奨アクションが含まれる | integration |
| TC-T09-03 | - | `rescue` コマンド実行後に blocked:* ラベルが削除される | integration |
| TC-T09-04 | - | `rescue` コマンドで retries が 0 にリセットされる | unit |

---

### T10: Bash テストスクリプト実装（T01 / T04 / T07）

**優先度**: P2-P0（risk-matrix R-009 HIGH 解消）  
**目的**: T01（Baton Infrastructure）・T04（Phase Agent SP REQ/TDS/IMP）・T07（coherence-scan）の実行可能な Bash テストスクリプトを実装する。`test_phase_gate.sh`（T03: 13/13 PASS 確認済み）と同パターンで作成する。

**依存タスク**: なし

#### 1.2 Inputs

| 入力 | 説明 |
|------|------|
| `specs/tsumigi-v3-harness/tests/T01/testcases.md` | TC-T01-01〜TC-T01-05 |
| `specs/tsumigi-v3-harness/tests/T04/testcases.md` | TC-T04-01〜TC-T04-04 |
| `specs/tsumigi-v3-harness/tests/T07/testcases.md` | TC-T07-01〜TC-T07-04 |
| `specs/tsumigi-v3-harness/tests/T03/test_phase_gate.sh` | 参照パターン（VCKD_TEST_MODE / mock_gh） |

#### 1.3 Outputs

| ファイル | 内容 |
|---------|------|
| `specs/tsumigi-v3-harness/tests/T01/test_baton_infra.sh` | TC-T01-01〜05 の自動テスト |
| `specs/tsumigi-v3-harness/tests/T04/test_phase_agent.sh` | TC-T04-01〜04 の自動テスト |
| `specs/tsumigi-v3-harness/tests/T07/test_coherence_scan.sh` | TC-T07-01〜04 の自動テスト |

#### 1.6 Test Strategy（AC）

| AC-ID | EARS 記法 | 確認方法 |
|-------|----------|---------|
| **REQ-009-AC-1** | WHEN テストスクリプトを実行するとき THE SYSTEM SHALL 各 TC の PASS/FAIL を stdout に出力する | bash 実行 |
| **REQ-009-AC-2** | WHEN 全 TC が PASS のとき THE SYSTEM SHALL `全体判定: PASS` を出力して exit 0 する | bash 実行 |
| **REQ-009-AC-3** | WHEN 1 件以上 FAIL のとき THE SYSTEM SHALL `全体判定: FAIL` を出力して exit 1 する | bash 実行 |

---

### T11: `VCKD_FROM_PHASE` 許可リスト検証

**優先度**: P2-P0（セキュリティ強化 / review-questions Q4 回答）  
**目的**: `post-tool-use.sh` および `phase-gate.sh` において `VCKD_FROM_PHASE` を許可リストで検証し、不正値が渡された場合はエラーを出力して exit する。

**依存タスク**: なし

#### 1.3 Outputs

| ファイル | 変更内容 |
|---------|---------|
| `.tsumigi/hooks/post-tool-use.sh` | 冒頭に `VCKD_FROM_PHASE` 許可リスト検証を追加 |
| `.tsumigi/lib/phase-gate.sh` | `_validate_inputs()` 関数を追加し全公開関数から呼ぶ |

#### 1.4 Implementation Strategy

```bash
_validate_inputs() {
  # 空文字はスキップ（既存動作維持 / REQ-010-AC-2）
  [[ -z "$VCKD_FROM_PHASE" ]] && return 0
  [[ "$VCKD_FROM_PHASE" =~ ^(REQ|TDS|IMP|TEST|OPS|CHANGE)$ ]] \
    || { echo "ERROR: invalid VCKD_FROM_PHASE='$VCKD_FROM_PHASE'"; exit 2; }
}
```

#### 1.6 Test Strategy（AC）

| AC-ID | EARS 記法 | 確認方法 |
|-------|----------|---------|
| **REQ-010-AC-1** | WHEN `VCKD_FROM_PHASE` が許可リスト外のとき THE SYSTEM SHALL エラーを出力して exit 2 する | unit（mock） |
| **REQ-010-AC-2** | WHEN `VCKD_FROM_PHASE` が空文字のとき THE SYSTEM SHALL exit 0 でスキップする | unit（mock） |

---

### T12: IMP.md ロールバック計画セクション追記

**優先度**: P2-P0（IMP-checklist 形式要件 / `.kiro/specs/tsumigi-v3-harness/IMP-checklist.md` の `[ ] ロールバック計画` チェック解消）  
**目的**: 本 IMP.md に §2.4 ロールバック計画を追記し、IMP-checklist の未チェック項目を解消する。
**→ §2.4 として本 IMP に記述済み。**

---

### T13: `phases.json` 外部化（drift D1 恒久解消）

**優先度**: P2-P1  
**目的**: `_check_phase_specific()` の Bash `case` 文を `.tsumigi/config/phases.json` への `jq` 参照に移行し、フェーズ追加・変更時の変更箇所を 1 ファイルに集約する。

**依存タスク**: T03（`phase-gate.sh` の存在）

#### 1.3 Outputs

| ファイル | 操作 | 内容 |
|---------|------|------|
| `.tsumigi/config/phases.json` | 新規作成 | フェーズ定義 JSON |
| `.tsumigi/lib/phase-gate.sh` | 更新 | `_check_phase_specific()` を `jq` 参照に変更 |

#### 1.4 Implementation Strategy

```json
{
  "REQ":    { "next": "TDS",    "required_artifacts": ["requirements.md"], "ac_min": 3 },
  "TDS":    { "next": "IMP",    "required_artifacts": ["design.md", "tasks.md"] },
  "IMP":    { "next": "TEST",   "required_artifacts": ["IMP.md"], "grep_check": "patch-plan" },
  "TEST":   { "next": "OPS",    "required_artifacts": ["adversary-report.md"], "grep_check": "全体判定.*PASS" },
  "OPS":    { "next": "CHANGE", "required_artifacts": ["drift-report.md"], "drift_threshold": 20 },
  "CHANGE": { "next": "DONE",   "required_artifacts": ["sync-report.md"] }
}
```

---

### T14: `vckd-pipeline.yml` timeout-minutes 追加（drift D5 解消）

**優先度**: P2-P1  
**目的**: `run-phase-agent` ジョブに `timeout-minutes: 350` を追加し、GitHub Actions デフォルト上限（6h）への暗黙的依存を排除する。

#### 1.4 Implementation Strategy

```yaml
# .github/workflows/vckd-pipeline.yml
run-phase-agent:
  timeout-minutes: 350  # 5h50m（6h 上限に 10m バッファ）
  runs-on: ubuntu-latest
```

---

### T15: 中間状態ロールバック手順文書化

**優先度**: P2-P1（review-questions Q5 回答）  
**目的**: `commands/rescue.md` に「harness 中間状態（ラベル変更済み後に harness を無効化した場合）のリカバリー手順」セクションを追記する。

#### 1.3 Outputs

| ファイル | 変更内容 |
|---------|---------|
| `commands/rescue.md` | `## 中間状態のリカバリー手順` セクションを追記 |

#### 1.4 Implementation Strategy（追記内容の概要）

```
1. 現在ラベルを確認: gh issue view <N> --json labels
2. 不正ラベルを削除: gh issue edit <N> --remove-label "phase:xxx"
3. 正しいラベルを再付与: gh issue edit <N> --add-label "phase:yyy"
4. baton-log.json の pending エントリを手動修正（必要に応じて）
5. 整合性確認: /tsumigi:coherence-scan
```

---

### T16: `req:tsumigi-v3-harness` ノード登録（coherence Amber 解消）

**優先度**: P2-P2  
**目的**: `specs/tsumigi-v3-harness/issue-struct.md` を新規作成し `coherence.id: "req:tsumigi-v3-harness"` を付与する。coherence-scan の dangling ref 2 件を解消し Amber 3 → 1 に削減する。

**依存タスク**: なし

---

### T17: 並列負荷テスト追加

**優先度**: P2-P2（review-questions Q6 回答）  
**目的**: GitHub Actions `matrix:` を使って 3 Issue を同時発火し、`_gh_with_retry()` の並列時ブロッキング（最大 14 秒 × N Issue）が CI タイムアウト（350 分）内に収まることを実証する。

---

### T18: macOS 互換対応（bash 3.2 / `grep -oP`）

**優先度**: P2-P2（risk-matrix R-004 LOW 解消）  
**目的**: `grep -oP`（Perl regex）を `grep -oE`（POSIX ERE）に置換し、`declare -A` 依存箇所に bash バージョンガードを追加する。

**影響ファイル**: `.tsumigi/hooks/post-tool-use.sh`, `.tsumigi/lib/phase-gate.sh`

---

## 2. Patch Plan（実装パッチ計画）

### 2.1 実装順序

```
Week 1: P0 タスク（T01, T02, T04 は並列実行可能、T03 は T01 完了後）

  Day 1-2: T01（Baton Infrastructure）
           T02（CEG frontmatter）   ← T01 と並列
           T04（Agent SP REQ/TDS/IMP）← T01 と並列

  Day 3-4: T03（Phase Gate ロジック）← T01 完了後

Week 2: P1 タスク（T05/T06/T07/T08 を並列、T09 は T06 完了後）

  Day 5-6: T05（GitHub Actions）   ← T01, T04 完了後
           T06（Agent SP TEST/OPS/CHANGE）← T04 完了後
           T07（coherence-scan / baton-status）← T01, T02 完了後
           T08（後方互換性）        ← T01, T03 完了後

  Day 7-8: T09（rescue / escalate）← T04, T06 完了後
```

### 2.2 並列実行できるタスクの組み合わせ

| 実行タイミング | 並列可能なタスク | 注意事項 |
|-------------|---------------|---------|
| 最初の並列グループ | T01, T02, T04 | 相互依存なし |
| T01 完了後 | T03（+ T01, T02, T04 と並列続行可） | T03 は `baton-log.json` が必要 |
| T01, T04 完了後 | T05, T06, T07, T08 | 4タスク同時に着手可 |
| T04, T06 完了後 | T09 | 最終タスク |

### 2.3 依存関係の理由（TDS DAG に基づく）

| 依存 | 理由 |
|------|------|
| T03 → T01 | `dispatch_baton` が `graph/baton-log.json`・`.vckd/config.yaml` の存在を前提とする |
| T05 → T01 | Actions が `.vckd/config.yaml` を参照する |
| T05 → T04 | Actions が `.tsumigi/agents/*.md` でエージェントを起動する |
| T06 → T04 | T04 の Agent 共通構造（リトライポリシー等）を T06 が継承する |
| T07 → T01 | `baton-status` が `graph/baton-log.json` を参照する |
| T07 → T02 | `coherence-scan` が T02 で付与した frontmatter を収集する |
| T08 → T01 | `enabled` チェックが `.vckd/config.yaml` を参照する |
| T08 → T03 | T03 で実装した関数に `enabled` ガードを追加する |
| T09 → T04 | T04 の Agent ファイルにリトライロジックを追記する |
| T09 → T06 | T06 の Agent ファイルにも同様のリトライロジックを追記する |

### 2.4 ロールバック計画

**トリガー**: 本番適用後に重大なバグ・意図しないフェーズ進行が確認された場合。

#### Step 1: harness を即時無効化

```bash
# .vckd/config.yaml を編集して harness を無効化
# 変更: harness.enabled: true → false
```

効果: `dispatch_baton` / `emit_baton` / `emit_blocked` の全処理がスキップされる。
ラベルの追加・削除が発生しなくなる（**既存ラベルはそのまま残る**）。

#### Step 2: 中間状態のラベルを巻き戻す

```bash
# ラベルの現状確認
gh issue view <ISSUE_NUMBER> --json labels

# 不正なラベルを削除し、前フェーズのラベルを再付与
gh issue edit <ISSUE_NUMBER> --remove-label "phase:yyy" --add-label "phase:xxx"
gh issue edit <ISSUE_NUMBER> --remove-label "pending:next-phase"
```

詳細手順: `commands/rescue.md`（`/tsumigi:rescue <issue-number>` として実行可）

#### Step 3: baton-log.json の巻き戻し

```bash
cp graph/baton-log.json graph/baton-log.json.bak
jq 'del(.transitions[-1])' graph/baton-log.json > /tmp/baton-fix.json
mv /tmp/baton-fix.json graph/baton-log.json
```

#### Step 4: coherence-scan で整合性確認

```
/tsumigi:coherence-scan
```

全ノードが Green に戻ったことを確認してから問題点を修正する。

#### Step 5: 問題修正後に harness を再有効化

`.vckd/config.yaml` の `harness.enabled` を `true` に戻し、修正済みの Issue に正しいフェーズラベルを付与する。

**制約**:
- ロールバックは Issue ごとに個別実施（一括ロールバック機能は未実装）
- `baton-log.json` の手動修正はアトミックではない（並列書き込み競合に注意）
- GitHub Actions が実行中の場合は先にワークフローをキャンセルすること

---

## 3. I/O Traceability

各タスクがどのファイルを読み書きするかの完全マップ。

| タスク | 読むファイル | 書くファイル | GitHub API |
|--------|------------|------------|-----------|
| **T01** | `docs/unified-framework-spec-v2.0.md` | `.vckd/config.yaml`, `.tsumigi/hooks/post-tool-use.sh`, `.claude/settings.json`, `graph/baton-log.json`, `graph/coherence.json`, `commands/install.md`, `commands/baton-status.md` | `gh label create` × 15 |
| **T02** | `commands/imp_generate.md`（既存）, `commands/implement.md`（既存）, `commands/rev.md`（既存） | 同ファイル（更新）, `.tsumigi/templates/imp-template.md` | なし |
| **T03** | `.vckd/config.yaml`, `graph/baton-log.json`, `graph/coherence.json` | `.tsumigi/lib/phase-gate.sh`, `.tsumigi/lib/on-label-added.sh`, `graph/baton-log.json`（実行時） | `gh issue edit`, `gh issue comment`, `gh issue view`（実行時） |
| **T04** | `commands/spec-req.md`, `commands/spec-design.md`, `commands/spec-tasks.md`, `commands/imp_generate.md`, `commands/implement.md`, `docs/unified-framework-spec-v2.0.md §3.4` | `.tsumigi/agents/requirements-agent.md`, `.tsumigi/agents/design-agent.md`, `.tsumigi/agents/implement-agent.md` | なし |
| **T05** | `.tsumigi/agents/*.md`（T04 成果物）, `.vckd/config.yaml` | `.github/workflows/vckd-pipeline.yml` | なし（ワークフロー定義のみ） |
| **T06** | `commands/test.md`, `commands/review.md`, `commands/rev.md`, `commands/drift_check.md`, `commands/sync.md`, `commands/pr.md`, `docs/unified-framework-spec-v2.0.md §3.4 #11〜21` | `.tsumigi/agents/test-agent.md`, `.tsumigi/agents/adversary-agent.md`, `.tsumigi/agents/ops-agent.md`, `.tsumigi/agents/change-agent.md` | なし |
| **T07** | `specs/**/*.md`, `.kiro/specs/**/*.md`, `graph/baton-log.json` | `commands/coherence-scan.md`, `commands/baton-status.md`, `graph/coherence.json`（実行時） | `gh issue list`（実行時） |
| **T08** | `.tsumigi/lib/phase-gate.sh`（T03 成果物）, `commands/install.md`（T01 成果物） | 同ファイル（更新） | なし |
| **T09** | `.tsumigi/agents/*.md`（T04, T06 成果物）, `graph/baton-log.json` | `commands/rescue.md`, `.tsumigi/agents/*.md`（更新）, `graph/baton-log.json`（スキーマ拡張） | `gh issue edit`（rescue 実行時） |

**TDS §2 との整合性チェック**:
- TDS §2.1.1 で定義した終了コード（0/1/2/3）: T03 `check_phase_gate` で実装済み ✅
- TDS §2.2 GitHub API 仕様（idempotent・error_handling）: T03 `emit_*` 関数で実装済み ✅
- TDS §2.3 エラーコメントスキーマ: T03 `emit_blocked` + T06 `adversary-agent` で実装済み ✅

---

## 4. AC Traceability

AC 22 件すべてについて、対応タスクと TDS セクションを紐付ける。

| AC-ID | EARS 記法（要約） | 対応タスク | TDS セクション |
|-------|----------------|----------|-------------|
| **REQ-001-AC-1** | WHEN `phase:xxx` 付与 THEN Phase Agent 起動 | T01, T05 | §1.2, §16.2 |
| **REQ-001-AC-2** | WHEN Gate PASS + AUTO_STEP=false THEN `pending:next-phase` 付与 | T03 | §5.2 |
| **REQ-001-AC-3** | WHEN Gate PASS + AUTO_STEP=true THEN 即座に次ラベル付与 | T03 | §5.2 |
| **REQ-001-AC-4** | WHEN `approve` 付与 THEN pending 解除・次ラベル付与 | T03 | §4.2 UC-002 |
| **REQ-001-AC-5** | WHEN Gate FAIL THEN `blocked:xxx` 付与 | T03 | §2.3, §5.1 |
| **REQ-002-AC-1** | IF AUTO_STEP=false THEN `dispatch_baton` → `emit_pending` | T03 | §5.2 |
| **REQ-002-AC-2** | IF AUTO_STEP=true THEN `dispatch_baton` → `emit_baton` | T03 | §5.2 |
| **REQ-002-AC-3** | IF config.yaml 不在 THEN AUTO_STEP=false フォールバック | T03 | §3.4, §5.0 |
| **REQ-003-AC-1** | WHEN Gate 実行 THEN 必須成果物確認 | T03 | §5.2 Step 1 |
| **REQ-003-AC-2** | WHEN Gate 実行 THEN CEG 循環依存チェック | T03 | §5.2 Step 2 |
| **REQ-003-AC-3** | WHEN Gate 実行 THEN フェーズ固有チェック | T03 | §5.2 Step 3 |
| **REQ-003-AC-4** | WHEN Gate 実行 THEN Gray ノードなしを確認 | T03 | §5.2 Step 4 |
| **REQ-004-AC-1** | WHEN フェーズ完了 THEN GitHub コメント投稿 | T03 | §2.2, §16.4 |
| **REQ-004-AC-2** | WHEN バトン遷移 THEN baton-log.json 記録 | T01, T03 | §3.2 |
| **REQ-005-AC-1** | WHEN 成果物生成 THEN coherence frontmatter 付与 | T02 | §4.2 |
| **REQ-005-AC-2** | WHEN coherence-scan 実行 THEN coherence.json 再構築 | T07 | §3.3 |
| **REQ-006-AC-1** | IF harness.enabled=false THEN v1.0 互換動作 | T08 | §16.6 |
| **REQ-006-AC-2** | IF harness.enabled=false THEN ラベル変更・コメントなし | T08 | §16.6 |
| **REQ-007-AC-1** | WHEN RequirementsAgent 起動 THEN requirements.md 生成 | T04 | §4.2 UC-001 |
| **REQ-007-AC-2** | WHEN 3 回リトライ失敗 THEN `blocked:escalate` 付与 | T09 | §4.2 UC-006 |
| **REQ-008-AC-1** | WHEN TEST→OPS Gate THEN Adversarial 5 次元評価 | T06 | §4.2 UC-004 |
| **REQ-008-AC-2** | WHEN Adversarial FAIL THEN 次元根拠コメント投稿 | T06 | §2.3, §5.5 |
| **REQ-009-AC-1** | WHEN テストスクリプトを実行するとき THEN 各 TC の PASS/FAIL を stdout に出力する | T10 | — |
| **REQ-009-AC-2** | WHEN 全 TC が PASS THEN `全体判定: PASS` を出力して exit 0 する | T10 | — |
| **REQ-009-AC-3** | WHEN 1 件以上 FAIL THEN `全体判定: FAIL` を出力して exit 1 する | T10 | — |
| **REQ-010-AC-1** | WHEN `VCKD_FROM_PHASE` が許可リスト外 THEN エラーを出力して exit 2 する | T11 | — |
| **REQ-010-AC-2** | WHEN `VCKD_FROM_PHASE` が空文字 THEN exit 0 でスキップする（既存動作維持） | T11 | — |
| **REQ-011-AC-1** | WHEN IMP.md が存在するとき THEN ロールバック計画セクション（§2.4）が記述されている | T12 | — |
| **REQ-011-AC-2** | WHEN ハーネスが中間状態で無効化されるとき THEN rescue コマンドでラベル巻き戻しが可能 | T15 | — |

**未対応 AC: 0 件**（全 30 件が T01〜T18 のいずれかに対応）

---

## 5. GateResult Specification

AUTO_STEP=false を前提とした GateResult の生成条件と判定基準を定義する。

### 5.1 GateResult の生成条件

```
GateResult は check_phase_gate() 関数が返す構造体。
Steps 1〜4 をすべて通過した場合のみ passed=true になる。

PASS 条件（全て満たすこと）:
  Step 1: get_required_artifacts(from_phase) で列挙した全ファイルが存在する
  Step 2: detect_circular_dependencies(ceg) が空配列を返す
  Step 3: check_phase_specific(from_phase, to_phase) が passed=true を返す
  Step 4: [n for n in ceg.nodes if n.band == "Gray"] が空配列

FAIL 条件（いずれか 1 つで FAIL）:
  - 必須ファイルが 1 件でも存在しない → type: "missing_artifact"
  - 循環依存が検出された → type: "circular_dep"
  - フェーズ固有チェックが失敗 → type: "phase_specific"
  - Gray ノードが存在する → type: "gray_node"
```

### 5.2 AUTO_STEP=false における PASS 後の動作

```
PASS かつ AUTO_STEP=false の場合:
  mode = "manual"
  baton_label = "pending:next-phase"

  動作:
    1. emit_pending(issue_number, current_phase_label, pending_label, next_candidate)
    2. baton-log.json の pending[$issue] にエントリ追加
    3. GitHub コメント（承認待ち案内）を投稿
    4. 処理終了（Agent はここで stop）

  次のアクションは Human が行う:
    - approve ラベルを付与 → on_label_added が next_candidate を付与

PASS かつ AUTO_STEP=true の場合:
  mode = "auto"
  baton_label = next_candidate（例: "phase:tds"）

  動作:
    1. emit_baton(issue_number, current_phase_label, next_candidate)
    2. baton-log.json の transitions に追記
    3. GitHub コメント（バトン発行通知）を投稿
    4. 処理終了（次の Agent が label イベントで起動）
```

### 5.3 approve / reject / needs-review の判定基準

| 状態 | 条件 | ラベル変化 |
|------|------|----------|
| **approve（Human が実行）** | Issue に `approve` ラベルを付与 | `pending:next-phase` → `phase:yyy`（次フェーズ） |
| **reject（Human が実行）** | Issue に `phase:xxx`（前フェーズ）ラベルを再付与 | `pending:next-phase` → `phase:xxx`（前フェーズ再実行） |
| **needs-review（System が発行）** | OPS→CHANGE Gate で Amber ノードが存在する | `phase:ops` → `human:review`（内容確認を要請） |
| **needs-escalation（Agent が発行）** | 3 回リトライ失敗 | `phase:xxx` → `blocked:escalate` |

### 5.4 GateResult と baton-log.json の整合

```
check_phase_gate が GateResult を返した後、
dispatch_baton または emit_blocked が baton-log.json に記録する。

PASS の場合の記録:
  transitions[]:
    issue_number: <N>
    from_label: "phase:xxx"
    to_label: "pending:next-phase"（AUTO_STEP=false）
              または "phase:yyy"（AUTO_STEP=true）
    transitioned_at: <ISO8601>
    mode: "manual" または "auto"
    triggered_by: "phase_gate"

FAIL の場合の記録:
  transitions[]:
    issue_number: <N>
    from_label: "phase:xxx"
    to_label: "blocked:xxx"
    transitioned_at: <ISO8601>
    mode: "blocked"
    triggered_by: "phase_gate"
```

---

## 6. CEG Frontmatter（tsumigi v3 用）

```json
{
  "ceg": {
    "phase": "imp",
    "wave": "P0+P1+P2",
    "auto_step": false,
    "source": "design.md",
    "generated_by": "Claude",
    "tasks": {
      "P0": ["T01", "T02", "T03", "T04"],
      "P1": ["T05", "T06", "T07", "T08", "T09"],
      "P2": ["T10", "T11", "T12", "T13", "T14", "T15", "T16", "T17", "T18"]
    },
    "ac_total": 30,
    "ac_covered": 30,
    "coverage": "100%"
  }
}
```

```yaml
---
tsumigi:
  node_id: "imp:tsumigi-v3-harness"
  artifact_type: "imp"
  phase: "IMP"
  feature: "tsumigi-v3-harness"
  imp_version: "1.0.0"
  status: "active"
  created_at: "2026-04-04T00:00:00Z"

coherence:
  id: "imp:tsumigi-v3-harness"
  depends_on:
    - id: "req:tsumigi-v3-harness"
      relation: "implements"
      confidence: 0.95
      required: true
    - id: "design:tsumigi-v3-harness"
      relation: "derives_from"
      confidence: 0.95
      required: true
  modules: ["commands", "hooks", "agents", "graph", "config"]
  band: "Green"

baton:
  phase: "imp"
  auto_step: false
  pending_label: "pending:next-phase"
---
```

---

## 7. Implementation Status

本セクションは IMP v1.1.0 更新時（2026-04-05）に追加。
GitHub Issues #1〜#7 の作成完了を受け、各タスクの実装済みファイルを棚卸しした結果を記録する。

### 7.1 タスク別実装状況

| タスク | Issue | 波形 | ステータス | 主要成果物 |
|--------|-------|------|----------|-----------|
| **T01** | [#1](../../issues/1) Baton Infrastructure | P0 | ✅ 完了 | `.vckd/config.yaml`, `.tsumigi/hooks/post-tool-use.sh`, `graph/baton-log.json`, `graph/coherence.json` |
| **T02** | [#2](../../issues/2) CEG frontmatter 標準化 | P0 | ✅ 完了 | `.tsumigi/templates/imp-template.md`, `commands/imp_generate.md`（frontmatter step 追加済み） |
| **T03** | [#3](../../issues/3) Phase Gate ロジック | P0 | ✅ 完了 | `.tsumigi/lib/phase-gate.sh`, `.tsumigi/lib/on-label-added.sh` |
| **T04** | [#4](../../issues/4) Phase Agent SP（REQ/TDS/IMP） | P0 | ✅ 完了 | `.tsumigi/agents/requirements-agent.md`, `design-agent.md`, `implement-agent.md` |
| **T05** | [#5](../../issues/5) GitHub Actions 統合 | P1 | ✅ 完了 | `.github/workflows/vckd-pipeline.yml` |
| **T06** | [#6](../../issues/6) Phase Agent SP（TEST/OPS/CHANGE） | P1 | ✅ 完了 | `.tsumigi/agents/test-agent.md`, `adversary-agent.md`, `ops-agent.md`, `change-agent.md` |
| **T07** | [#7](../../issues/7) coherence-scan / baton-status | P1 | ✅ 完了 | `commands/coherence-scan.md`, `commands/baton-status.md` |
| **T08** | *(Issue なし)* 後方互換性 | P1 | ✅ T03 内包 | `phase-gate.sh` の `_check_harness_enabled()` で実現済み |
| **T09** | *(Issue なし)* rescue / escalate | P1 | ✅ T03 内包 | `phase-gate.sh` の `emit_escalate()` / `get_retry_count()` / `reset_retry_count()` で実現済み。`commands/rescue.md` も存在 |
| **T10** | *(Issue なし)* Bash テストスクリプト（T01/T04/T07） | P2 | ✅ 完了 | T01: 4/4 PASS, T04: 6/6 PASS + 2 SKIP, T07: 9/9 PASS（合計 19 PASS） |
| **T11** | *(Issue なし)* `VCKD_FROM_PHASE` 検証 | P2 | ✅ 完了 | 7/7 PASS — `_validate_from_phase()` を `phase-gate.sh` に追加、`post-tool-use.sh` にも許可リスト検証を追加 |
| **T12** | *(Issue なし)* ロールバック計画セクション | P2 | ✅ §2.4 として追記済み | — |
| **T13** | [#11](https://github.com/kava2108/tsumigi/issues/11) `phases.json` 外部化 | P1 | 🔲 未着手 | drift D1 恒久解消 |
| **T14** | [#12](https://github.com/kava2108/tsumigi/issues/12) `vckd-pipeline.yml` timeout-minutes | P1 | ✅ 完了（既適用） | `run-phase-agent` に `timeout-minutes: 350` は既に設定済みと確認 |
| **T15** | [#13](https://github.com/kava2108/tsumigi/issues/13) 中間状態ロールバック手順 | P1 | ✅ 完了 | `commands/rescue.md` に `## 中間状態のリカバリー手順` セクションを追記 |
| **T16** | *(Issue なし)* `req:` ノード登録 | P2 | 🔲 未着手 | coherence Amber 解消 |
| **T17** | *(Issue なし)* 並列負荷テスト | P2 | 🔲 未着手 | Q6 回答 |
| **T18** | *(Issue なし)* macOS 互換対応 | P2 | 🔲 未着手 | R-004 LOW 解消 |

### 7.2 スコープ注記

- **GitHub Issues #1〜#7** は IMP の P0+P1 全タスク（T01〜T07）を網羅している
- **T08（後方互換性）** は T03 の `phase-gate.sh` 内で `_check_harness_enabled()` として実装済み。独立 Issue は不要
- **T09（rescue/escalate）** は T03 の `phase-gate.sh` 内でリトライファミリ関数として実装済み。`commands/rescue.md` も既存。独立 Issue は不要

### 7.3 次のアクション

P0 タスク（T01〜T04）が完了しているため、各ファイルの内容完成度レビューを実施してから TEST フェーズへ進む：

```bash
# 各 Agent ファイルの内容確認
/tsumigi:implement tsumigi-v3-harness T01 --issue 1   # 未確認の実装補完
/tsumigi:test tsumigi-v3-harness --vmodel all
/tsumigi:review tsumigi-v3-harness --adversary
```

---

*IMP v1.2.0 更新完了（2026-04-05）。次フェーズへ進む場合は `/tsumigi:test tsumigi-v3-harness --vmodel all` を実行してください。*
*AUTO_STEP=false のため、まず Issue に `approve` ラベルを付与して IMP→TEST Phase Gate を通過させてください。*
*v1.2.0 追加: P2 タスク（T10〜T18）は独立して着手可能。優先度 P0 は T10（Bash テスト）・T11（VCKD_FROM_PHASE 検証）・T12（ロールバック計画 §2.4 追記済み）。*
