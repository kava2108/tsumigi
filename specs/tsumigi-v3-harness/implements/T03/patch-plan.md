---
tsumigi:
  node_id: "impl:tsumigi-v3-harness:T03"
  artifact_type: "patch_plan"
  phase: "IMP"
  issue_id: "tsumigi-v3-harness"
  task_id: "T03"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "impl:tsumigi-v3-harness:T03"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "implements"
      confidence: 0.95
      required: true
    - id: "impl:tsumigi-v3-harness:T01"
      relation: "depends_on"
      confidence: 1.0
      required: true
  band: "Green"
---

# Patch Plan: T03 — Phase Gate ロジック実装

**Issue**: [#3](https://github.com/kava2108/tsumigi/issues/3)  
**IMP バージョン**: 1.1.0  
**実装日**: 2026-04-05

---

## 変更対象ファイル

| ファイル | 操作 | 状態 |
|---------|------|------|
| `.tsumigi/lib/phase-gate.sh` | 新規作成 | ✅ 実装済み |
| `.tsumigi/lib/on-label-added.sh` | 新規作成 | ✅ 実装済み |

---

## 実装内容

### `.tsumigi/lib/phase-gate.sh` — 公開 API

| 関数 | シグネチャ | 説明 |
|------|----------|------|
| `check_phase_gate` | `<from_phase> <feature> <issue_id>` | 4 ステップの Phase Gate を実行。戻り値 0=PASS / 1=FAIL |
| `dispatch_baton` | `<issue_number> <current_label> <next_label>` | AUTO_STEP に応じて `emit_pending` か `emit_baton` を呼ぶ |
| `emit_pending` | `<issue_number> <current_label> <pending_label> <next_label>` | ラベルを `pending:next-phase` に変更。baton-log に pending エントリを追加 |
| `emit_baton` | `<issue_number> <current_label> <next_label>` | ラベルを次フェーズに変更。baton-log に遷移を記録 |
| `emit_blocked` | `<issue_number> <current_label> <blocked_label> <reason>` | `blocked:xxx` ラベルを追加。FAIL 詳細コメントを投稿 |
| `emit_escalate` | `<issue_number> <agent_name> <last_error>` | `blocked:escalate` を付与。推奨アクションコメントを投稿 |
| `get_retry_count` | `<issue_number>` | baton-log から現在のリトライ回数を取得 |
| `increment_retry_count` | `<issue_number> <error_msg> <agent_name>` | リトライカウントをインクリメント |
| `reset_retry_count` | `<issue_number>` | リトライカウントを 0 にリセット |

### `check_phase_gate()` — 4 ステップ実装

```
Step 1: _check_artifacts(from_phase, feature, issue_id)
  REQ: .kiro/specs/<feature>/requirements.md が存在するか
  TDS: design.md + tasks.md が存在するか
  IMP: specs/<issue-id>/IMP.md が存在するか
  TEST: specs/<issue-id>/adversary-report.md が存在するか
  OPS: specs/<issue-id>/drift-report.md が存在するか

Step 2: _check_ceg()
  graph/coherence.json が有効な JSON であるか（jq empty）

Step 3: _check_phase_specific(from_phase, feature, issue_id)
  REQ: requirements.md の AC が 3 件以上あること
  IMP: IMP.md に "patch-plan" の記載があること

Step 4: _check_gray()
  graph/coherence.json に band="Gray" のノードがないこと
```

### T08 相当（後方互換性）— T03 内包

全公開関数の冒頭に `_check_harness_enabled || return 0` を配置：

```bash
_check_harness_enabled() {
  local enabled
  enabled=$(yq '.harness.enabled' .vckd/config.yaml 2>/dev/null || echo "false")
  [[ "$enabled" == "true" ]]
}
```

### T09 相当（rescue/escalate）— T03 内包

```bash
get_retry_count / increment_retry_count / reset_retry_count / emit_escalate
```
- `emit_escalate`: リトライカウント 3 回到達時に `blocked:escalate` を付与して推奨アクションコメントを投稿

### `_gh_with_retry()` — exponential backoff

```
最大 3 回リトライ: delay=2s → 4s → 8s
3 回失敗後: エラーメッセージを stderr に出力。exit 1
呼び出し元が必要に応じて emit_blocked や emit_escalate を呼ぶ
```

---

## AC 対応トレーサビリティ

| AC-ID | 実装箇所 |
|-------|---------|
| REQ-001-AC-2 | `emit_pending()` — AUTO_STEP=false 時の pending:next-phase 付与 |
| REQ-001-AC-3 | `emit_baton()` — AUTO_STEP=true 時の即時ラベル変更 |
| REQ-001-AC-4 | `on_label_added()` — approve 承認フロー |
| REQ-001-AC-5 | `emit_blocked()` — Gate FAIL 時のブロック付与 |
| REQ-002-AC-1 | `dispatch_baton()` — AUTO_STEP=false → emit_pending |
| REQ-002-AC-2 | `dispatch_baton()` — AUTO_STEP=true → emit_baton |
| REQ-002-AC-3 | `_get_auto_step()` — config.yaml 不在時のフォールバック |
| REQ-003-AC-1〜4 | `check_phase_gate()` の 4 ステップ（_check_artifacts / _check_ceg / _check_phase_specific / _check_gray） |
| REQ-004-AC-1 | `emit_*` 関数のコメント投稿処理 |
| REQ-004-AC-2 | `_append_transition()` による baton-log.json 記録 |
| REQ-006-AC-1,2 | `_check_harness_enabled()` — enabled=false 時の早期 return |
| REQ-007-AC-2 | `emit_escalate()` — 3 回リトライ失敗後 blocked:escalate |

---

## テスト観点

| TC-ID | 確認内容 |
|-------|---------|
| TC-T03-01 | `AUTO_STEP=false` で `dispatch_baton` が `emit_pending` を呼ぶ |
| TC-T03-02 | `AUTO_STEP=true` で `dispatch_baton` が `emit_baton` を呼ぶ |
| TC-T03-03 | `config.yaml` 不在で `AUTO_STEP=false` として動作する |
| TC-T03-08 | 必須ファイル不在で FAIL を返す |
| TC-T03-09 | 循環依存検出で FAIL を返す |
| TC-T03-12 | `gh` 3 回失敗後に `blocked:escalate` が付与される |
| TC-T03-13 | `baton-log.json` 破損時にバックアップ後再初期化される |

---

## アップデート履歴

### v1.1.1 — Adversary FAIL 修正（2026-04-05）

**起因**: `/tsumigi:review tsumigi-v3-harness --adversary` による D1 / D4 FAIL 検出

#### 変更対象ファイル（--update）

| ファイル | 操作 | 修正起因 |
|---------|------|---------|
| `.tsumigi/lib/phase-gate.sh` | 更新（`_check_ceg()` 置き換え） | Adversary D1: REQ-003-AC-2 未充足 |
| `.tsumigi/lib/on-label-added.sh` | 更新（`on_label_added()` SRP 分割） | Adversary D4: 単一責任原則違反 |

#### D1 修正: `_check_ceg()` — DFS サイクル検出（REQ-003-AC-2）

**変更前**: `jq empty` による JSON 構文確認のみ。循環依存は未検出。

**変更後**: 3 段階チェック:
1. JSON 構文バリデーション（`jq empty`）
2. **Fast path**: `summary.warnings[].type == "circular_dep"` カウント確認  
   （`coherence-scan` 実行済みなら即座に検出）
3. **Full DFS**: jq 内で再帰関数 `dfs(node; stack; adj)` を実装  
   - 隣接マップ: `reduce .edges[] as $e ({}; .[$e.from] += [$e.to])` で構築  
   - DFS スタック上の再到達 → "cycle" 返却 → `return 1`  
   - すべてのノードから DFS を起動（非連結グラフ対応）

**トレース**: `adversary-report.md` D1 FAIL → RESOLVED  
**対応 AC**: REQ-003-AC-2

#### D4 修正: `on_label_added()` — SRP リファクタリング

**変更前**: 92 行・6 責務が混在するモノリシック関数  
（validate + label 操作 × 3 + baton-log 更新 + コメント投稿）

**変更後**: 4 ヘルパー関数 + 15 行オーケストレーター

| 関数 | 責務 |
|------|------|
| `_validate_approve_request(issue_number, pending_label)` | pending ラベル存在確認 + next_candidate 取得（stdout 返却） |
| `_update_github_labels_for_approval(issue_number, approve_label, pending_label, next_candidate)` | ラベル 3 操作（remove approve / remove pending / add next） |
| `_finalize_baton_for_approval(issue_number, pending_label, next_candidate)` | baton-log.json 更新（pending 削除 + 遷移追記） |
| `_notify_approval(issue_number, approve_label, pending_label, next_candidate)` | 承認完了コメント投稿 |
| `on_label_added()` | フロー制御のみ（~15 行） |

**設計決定**: `_validate_approve_request` は `next_candidate` を stdout で返却  
（Bash で値を返す慣用パターン: `result=$(func)` で取得）

**トレース**: `adversary-report.md` D4 FAIL → RESOLVED
