---
tsumigi:
  node_id: "rev-api:tsumigi-v3-harness"
  artifact_type: "rev_api"
  phase: "OPS"
  issue_id: "tsumigi-v3-harness"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "rev-api:tsumigi-v3-harness"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "reverse_of"
      confidence: 0.90
      required: false
    - id: "rev-spec:tsumigi-v3-harness"
      relation: "depends_on"
      confidence: 0.90
      required: false
  band: "Green"
---

# 逆生成 API 仕様書: tsumigi-v3-harness

> tsumigi v3.0 の「API」は HTTP ではなく、以下の 3 層から構成されます：
> 1. **Claude スラッシュコマンド**（ユーザーインターフェース）
> 2. **Bash 公開関数**（プログラマティックインターフェース）
> 3. **環境変数 + GitHub ラベル**（シグナルインターフェース）

---

## 1. Claude スラッシュコマンド

| コマンド | 引数 | 説明 | 実装ファイル |
|---------|------|------|------------|
| `/tsumigi:install` | `[--harness] [--project]` | 初期セットアップ。`--harness` でバトンインフラを構築 | `commands/install.md` |
| `/tsumigi:baton-status` | `[issue-id]` | バトン遷移状態を 4 カテゴリで表示 | `commands/baton-status.md` |
| `/tsumigi:coherence-scan` | `[issue-id]` | frontmatter を収集して coherence.json を再構築 | `commands/coherence-scan.md` |
| `/tsumigi:rescue` | `<issue-id> [--reason <text>]` | ブロック解除・リトライカウントリセット | `commands/rescue.md` |
| `/tsumigi:imp_generate` | `<issue-id> [--update]` | IMP の生成・更新（CEG frontmatter 付与） | `commands/imp_generate.md` |
| `/tsumigi:implement` | `<issue-id> [task-id]` | patch-plan.md 生成（CEG frontmatter 付与） | `commands/implement.md` |
| `/tsumigi:test` | `<issue-id> [--vmodel all]` | testcases.md・test-plan.md を生成 | `commands/test.md` |
| `/tsumigi:rev` | `<issue-id> [--target all]` | 実装から逆仕様書を生成 | `commands/rev.md` |
| `/tsumigi:drift_check` | `<issue-id>` | 仕様と実装の乖離を検出・可視化 | `commands/drift_check.md` |

---

## 2. Bash 公開関数（`.tsumigi/lib/phase-gate.sh`）

### `check_phase_gate(from_phase, to_phase, feature_name)`

**目的**: フェーズ遷移前のゲートチェックを実行し、PASS/FAIL を返す

**引数**:
| 引数 | 型 | 必須 | 説明 |
|------|---|------|------|
| `from_phase` | string | ✅ | "REQ" \| "TDS" \| "IMP" \| "TEST" \| "OPS" |
| `to_phase` | string | ✅ | "TDS" \| "IMP" \| "TEST" \| "OPS" \| "CHANGE" |
| `feature_name` | string | ✅ | `.kiro/specs/<feature>/` のディレクトリ名 |

**出力**:
```
終了コード 0 = PASS → 環境変数 VCKD_GATE_RESULT=PASS をセット
終了コード 1 = FAIL → 環境変数 VCKD_GATE_RESULT=FAIL をセット
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L201

---

### `dispatch_baton(issue_number, current_label, next_label)`

**目的**: AUTO_STEP の設定に基づき emit_baton または emit_pending にルーティング

**引数**:
| 引数 | 型 | 必須 | 説明 |
|------|---|------|------|
| `issue_number` | integer | ✅ | GitHub Issue 番号 |
| `current_label` | string | ✅ | 現在の phase ラベル（例: "phase:imp"） |
| `next_label` | string | ✅ | 遷移先の phase ラベル（例: "phase:test"） |

**出力**: なし（副作用: baton-log.json 更新 + GitHub ラベル/コメント操作）

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L333

---

### `emit_pending(issue_number, current_label, pending_label, next_label)`

**目的**: 手動承認モード（AUTO_STEP=false）でのバトン待機状態を設定

**引数**:
| 引数 | 型 | 必須 | 説明 |
|------|---|------|------|
| `issue_number` | integer | ✅ | GitHub Issue 番号 |
| `current_label` | string | ✅ | 現在の phase ラベル |
| `pending_label` | string | ✅ | 待機ラベル（デフォルト: "pending:next-phase"） |
| `next_label` | string | ✅ | 承認後に付与する phase ラベル |

**副作用**:
- GitHub: `current_label` 削除 → `pending_label` 追加
- `baton-log.json`: `pending[issue_number].next = next_label` を記録
- GitHub: 承認待ちコメント投稿（`post_comment=true` の場合）

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L357

---

### `emit_baton(issue_number, current_label, next_label)`

**目的**: 自律モード（AUTO_STEP=true）での即時バトン進行

**副作用**:
- GitHub: `current_label` 削除 → `next_label` 追加
- `baton-log.json`: `transitions` 配列に `{mode:"auto"}` で追記
- GitHub: バトン移行コメント投稿

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L410

---

### `emit_blocked(issue_number, current_label, blocked_label, reason)`

**副作用**:
- GitHub: `blocked_label` 追加（`current_label` は保持）
- `baton-log.json`: `{mode:"blocked"}` で transitions に追記
- GitHub: FAIL 理由コメント投稿

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L450

---

### `emit_escalate(issue_number, agent_name, last_error)`

**目的**: 3 回リトライ失敗後のエスカレーション処理

**副作用**:
- GitHub: `blocked:escalate` ラベル追加
- GitHub: エスカレーション詳細コメント投稿

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L163

---

### `get_retry_count(issue_number)` / `increment_retry_count(...)` / `reset_retry_count(issue_number)`

**引数・戻り値**:

| 関数 | 引数 | 戻り値 |
|------|------|--------|
| `get_retry_count` | issue_number | integer（現在のリトライ数） |
| `increment_retry_count` | issue_number, error_message, agent_name | なし |
| `reset_retry_count` | issue_number | なし |

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L113-161

---

## 3. 環境変数インターフェース

| 変数名 | 型 | 必須 | 値の例 | 説明 |
|--------|---|------|--------|------|
| `VCKD_GATE_RESULT` | string | △ | `"PASS"` \| `"FAIL"` | Phase Gate 判定結果。空の場合 hook は早期離脱 |
| `VCKD_FROM_PHASE` | string | △ | `"REQ"` \| `"TDS"` \| `"IMP"` \| `"TEST"` \| `"OPS"` | 遷移元フェーズ |
| `VCKD_ISSUE_NUMBER` | integer | △ | `"42"` | 対象 GitHub Issue 番号（整数以外は exit 2） |
| `VCKD_FAIL_REASON` | string | ✕ | `"テストカバレッジ不足"` | FAIL 時の詳細理由（emit_blocked に渡す） |
| `VCKD_TEST_MODE` | string | ✕ | `"1"` | 設定時に `gh` を `mock_gh` に置き換え（テスト用） |

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/hooks/post-tool-use.sh` L4-8

---

## 4. GitHub ラベルインターフェース

| ラベル | 種別 | 付与タイミング | 削除タイミング |
|--------|------|--------------|--------------|
| `phase:req` | フェーズ | Issue 起票時 / バトン進行 | 次フェーズ移行時 |
| `phase:tds` | フェーズ | REQ→TDS 移行時 | 次フェーズ移行時 |
| `phase:imp` | フェーズ | TDS→IMP 移行時 | 次フェーズ移行時 |
| `phase:test` | フェーズ | IMP→TEST 移行時 | 次フェーズ移行時 |
| `phase:ops` | フェーズ | TEST→OPS 移行時 | 次フェーズ移行時 |
| `phase:change` | フェーズ | OPS→CHANGE 移行時 | 次フェーズ移行時 |
| `phase:done` | フェーズ | CHANGE 完了時 | 手動のみ |
| `pending:next-phase` | 状態 | emit_pending 実行時（AUTO_STEP=false） | approve 承認時 |
| `approve` | 操作 | 人間が手動で付与 | on_label_added.sh が直ちに削除 |
| `blocked:req` / `:tds` / `:imp` / `:ops` | 状態 | emit_blocked 実行時 | rescue コマンド実行時 |
| `blocked:escalate` | 状態 | emit_escalate 実行時（3 回リトライ失敗後） | rescue コマンド実行時 |
| `human:review` | 状態 | 手動 または escalate 後 | 手動のみ |
| `wave:P0` / `wave:P1` | 管理 | IssueGenerator が付与 | 変更なし |

**IMP との差分**: ✅ 一致  
**実装根拠**: `commands/install.md` Step5（`gh label create` 一覧）

---

## 5. GitHub Actions インターフェース（`.github/workflows/vckd-pipeline.yml`）

**トリガー**:
```
on:
  issues:
    types: [labeled]
```

**ルーティングテーブル**:

| ラベル | 実行内容 | エージェントファイル |
|--------|---------|-----------------|
| `phase:req` | Claude Code（headless） | `.tsumigi/agents/requirements-agent.md` |
| `phase:tds` | Claude Code（headless） | `.tsumigi/agents/design-agent.md` |
| `phase:imp` | Claude Code（headless） | `.tsumigi/agents/implement-agent.md` |
| `phase:test` | Claude Code（headless） | `.tsumigi/agents/test-agent.md` |
| `phase:ops` | Claude Code（headless） | `.tsumigi/agents/ops-agent.md` |
| `phase:change` | Claude Code（headless） | `.tsumigi/agents/change-agent.md` |
| `approve` | Bash のみ | `.tsumigi/lib/on-label-added.sh` |

**同時実行制御**:
```
concurrency:
  group: "vckd-issue-${{ github.event.issue.number }}"
  cancel-in-progress: false
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `.github/workflows/vckd-pipeline.yml`
