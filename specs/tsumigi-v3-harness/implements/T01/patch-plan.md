---
tsumigi:
  node_id: "impl:tsumigi-v3-harness:T01"
  artifact_type: "patch_plan"
  phase: "IMP"
  issue_id: "tsumigi-v3-harness"
  task_id: "T01"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "impl:tsumigi-v3-harness:T01"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "implements"
      confidence: 0.95
      required: true
  band: "Green"
---

# Patch Plan: T01 — Baton Infrastructure セットアップ

**Issue**: [#1](https://github.com/kava2108/tsumigi/issues/1)  
**IMP バージョン**: 1.1.0  
**実装日**: 2026-04-05

---

## 変更対象ファイル

| ファイル | 操作 | 状態 |
|---------|------|------|
| `.vckd/config.yaml` | 新規作成 | ✅ 実装済み |
| `.tsumigi/hooks/post-tool-use.sh` | 新規作成 | ✅ 実装済み |
| `graph/baton-log.json` | 新規作成（初期化） | ✅ 実装済み |
| `graph/coherence.json` | 新規作成（初期化） | ✅ 実装済み |
| `commands/install.md` | 更新（`--harness` フラグ対応） | ✅ 実装済み |
| `commands/baton-status.md` | 新規作成 | ✅ 実装済み |

---

## 実装内容

### `.vckd/config.yaml`

```yaml
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

- `harness.enabled=true` / `AUTO_STEP=false` でデフォルト設定
- `pending_label` / `approve_label` をカスタマイズ可能

### `.tsumigi/hooks/post-tool-use.sh`

処理フロー:
1. `VCKD_GATE_RESULT` / `VCKD_FROM_PHASE` / `VCKD_ISSUE_NUMBER` の存在確認（空なら exit 0）
2. `VCKD_ISSUE_NUMBER` の整数バリデーション（不正値なら exit 2）
3. `yq` で `harness.enabled` を確認（`false` なら exit 0）
4. `phase-gate.sh` を source してロード
5. フェーズ → 次フェーズのマッピングテーブル参照（REQ→TDS→IMP→TEST→OPS→CHANGE→done）
6. `PASS` → `dispatch_baton()`、`FAIL` → `emit_blocked()`

### `commands/install.md`

- step5: `--harness` なし時は `harness.enabled=false` の config.yaml を生成
- step8: `--harness` あり時に以下を実行:
  - `.vckd/config.yaml` 生成
  - `graph/` ディレクトリ + JSON ファイル初期化
  - `.tsumigi/hooks/post-tool-use.sh` 生成 + chmod +x
  - `.claude/settings.json` への PostToolUse フック追加（重複チェック付き）
  - `gh label create` で 15 ラベルを作成

### `commands/baton-status.md`

表示項目:
- アクティブな Issue（`phase:*` ラベル付き）— `gh issue list` で取得
- 承認待ち（`pending:next-phase`）
- ブロック中（`blocked:*`）
- 直近 10 件の遷移履歴（`baton-log.json` の `transitions` 配列）

---

## AC 対応トレーサビリティ

| AC-ID | 実装箇所 |
|-------|---------|
| REQ-001-AC-1 | `post-tool-use.sh` + `install.md` step8（phase:* ラベル → バトン基盤） |
| REQ-002-AC-3 | `phase-gate.sh` `_get_auto_step()` の config.yaml 不在時フォールバック |
| REQ-004-AC-2 | `phase-gate.sh` `_append_transition()` による baton-log.json への記録 |

---

## テスト観点

| TC-ID | 確認内容 |
|-------|---------|
| TC-T01-02 | `config.yaml` 不在で `dispatch_baton` を呼ぶと `AUTO_STEP=false` として動作する |
| TC-T01-03 | `emit_baton` 実行後に `graph/baton-log.json` に遷移が記録される |
| TC-T01-04 | `.claude/settings.json` に既存フックがある場合、重複追加されない |
| TC-T01-05 | `graph/` が存在しない環境でも `install --harness` が正常完了する |
