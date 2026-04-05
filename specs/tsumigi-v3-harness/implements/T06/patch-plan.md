---
tsumigi:
  node_id: "impl:tsumigi-v3-harness:T06"
  artifact_type: "patch_plan"
  phase: "IMP"
  issue_id: "tsumigi-v3-harness"
  task_id: "T06"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "impl:tsumigi-v3-harness:T06"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "implements"
      confidence: 0.95
      required: true
    - id: "impl:tsumigi-v3-harness:T04"
      relation: "depends_on"
      confidence: 0.9
      required: true
  band: "Green"
---

# Patch Plan: T06 — Phase Agent SP (TEST/OPS/CHANGE)

**Issue**: [#6](https://github.com/kava2108/tsumigi/issues/6)  
**IMP バージョン**: 1.1.0  
**実装日**: 2026-04-05

---

## 変更対象ファイル

| ファイル | 操作 | 状態 |
|---------|------|------|
| `.tsumigi/agents/test-agent.md` | 新規作成 | ✅ 実装済み |
| `.tsumigi/agents/adversary-agent.md` | 新規作成 | ✅ 実装済み |
| `.tsumigi/agents/ops-agent.md` | 新規作成 | ✅ 実装済み |
| `.tsumigi/agents/change-agent.md` | 新規作成 | ✅ 実装済み |

---

## 実装内容

### TestAgent

- **入力**: `test-plan.md`, `testcases.md`, `patch-plan.md`
- **出力**: `test-results.md`, `testcases.md` (更新)
- **Phase Gate**: `phase:test` → `phase:ops` への遷移検証

### AdversaryAgent — 5次元評価

| 次元 | 定義 |
|------|------|
| D1 Spec Fidelity | IMP.md / AC との整合性 |
| D2 Edge Coverage | 境界値・異常系テストの網羅 |
| D3 Impl Correctness | コードの実装品質 |
| D4 Structural Integrity | ファイル構造・命名規則 |
| D5 Verification Readiness | 次フェーズへの引き渡し準備 |

**強制ネガティブバイアス**: 全次元スコアが ≥4/5 でも Adversary は 1 つ以上の Concern を必須で記録する。  
**コンテキスト分離**: 前フェーズのエージェント出力を直接参照せず、ファイルからのみ読み込む。

### OpsAgent

- **入力**: `test-results.md`, `patch-plan.md`
- **出力**: `ops-memo.md` (デプロイ手順・ロールバック計画)
- **Phase Gate**: `phase:ops` → `phase:change` への遷移検証

### ChangeAgent

- **入力**: `ops-memo.md`, 実装差分
- **出力**: PR body (4 要件 — What / Why / Risks / Test Evidence)
- **Phase Gate**: `phase:change` → PR 作成

---

## AC 対応トレーサビリティ

| AC-ID | 実装箇所 |
|-------|---------|
| REQ-007-AC-1 | `test-agent.md` — TestAgent フェーズゲート |
| REQ-008-AC-1 | `adversary-agent.md` — 5次元評価スキーマ |
| REQ-008-AC-2 | `adversary-agent.md` — 強制ネガティブバイアスルール |
| REQ-009-AC-1 | `ops-agent.md` — OpsAgent 出力仕様 |
| REQ-010-AC-1 | `change-agent.md` — PR body 4 要件 |

---

## テスト観点

| TC-ID | 確認内容 |
|-------|---------|
| TC-T06-01 | TestAgent が `test-results.md` を生成する |
| TC-T06-02 | AdversaryAgent が全次元スコアを記録する |
| TC-T06-03 | 全スコア 5/5 でも Adversary が Concern を 1 件以上記録する（強制ネガ） |
| TC-T06-04 | OpsAgent が `ops-memo.md` にロールバック計画を含める |
| TC-T06-05 | ChangeAgent が `commands/pr.md` の PR body テンプレート 4 要件を満たす |
