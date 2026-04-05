---
tsumigi:
  node_id: "impl:tsumigi-v3-harness:T05"
  artifact_type: "patch_plan"
  phase: "IMP"
  issue_id: "tsumigi-v3-harness"
  task_id: "T05"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "impl:tsumigi-v3-harness:T05"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "implements"
      confidence: 0.95
      required: true
    - id: "impl:tsumigi-v3-harness:T01"
      relation: "depends_on"
      confidence: 1.0
      required: true
    - id: "impl:tsumigi-v3-harness:T04"
      relation: "depends_on"
      confidence: 1.0
      required: true
  band: "Green"
---

# Patch Plan: T05 — GitHub Actions 統合

**Issue**: [#5](https://github.com/kava2108/tsumigi/issues/5)  
**IMP バージョン**: 1.1.0  
**実装日**: 2026-04-05

---

## 変更対象ファイル

| ファイル | 操作 | 状態 |
|---------|------|------|
| `.github/workflows/vckd-pipeline.yml` | 新規作成 | ✅ 実装済み |

---

## 実装内容

### ワークフロー構造

```yaml
トリガー: on: issues: types: [labeled]
同時実行制御: concurrency: group: "vckd-issue-${{ github.event.issue.number }}"
条件: startsWith(label, 'phase:') || label == 'approve'
```

### ラベル → エージェントのルーティングテーブル

| ラベル | エージェントファイル | Claude Code 使用 |
|--------|-----------------|----------------|
| `phase:req` | `requirements-agent.md` | ✅ |
| `phase:tds` | `design-agent.md` | ✅ |
| `phase:imp` | `implement-agent.md` | ✅ |
| `phase:test` | `test-agent.md` | ✅ |
| `phase:ops` | `ops-agent.md` | ✅ |
| `phase:change` | `change-agent.md` | ✅ |
| `approve` | `on-label-added.sh` | ❌（Bash のみ） |

### Claude Code 実行方式

```bash
claude --print --max-turns 50 \
  --system-prompt "$(cat .tsumigi/agents/<agent>.md)" \
  "GitHub Issue #$ISSUE_NUMBER を処理してください"
```

### ANTHROPIC_API_KEY 未設定時の処理

ワークフロー冒頭でシークレット存在チェックを実施:
- 未設定の場合: ジョブを skip して Issue コメントで通知
- サイレント失敗を防ぐ設計

---

## AC 対応トレーサビリティ

| AC-ID | 実装箇所 |
|-------|---------|
| REQ-001-AC-1 | `vckd-pipeline.yml` — `phase:*` ラベル付与 → Actions → Phase Agent 起動 |

---

## テスト観点

| TC-ID | 確認内容 |
|-------|---------|
| TC-T05-01 | `phase:req` 付与 → Actions 起動 → RequirementsAgent が実行される（e2e） |
| TC-T05-02 | 同一 Issue への並列実行が防止される（concurrency 設定） |
| TC-T05-03 | `approve` ラベルで `on_label_added.sh` が呼ばれる |
| TC-T05-04 | `ANTHROPIC_API_KEY` 未設定で失敗せずに通知が出る |
