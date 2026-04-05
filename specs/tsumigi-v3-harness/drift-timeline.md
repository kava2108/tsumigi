<!--
{
  "ceg": {
    "phase": "ops",
    "artifact_type": "drift-timeline",
    "generated_by": "Claude"
  }
}
-->
---
tsumigi:
  node_id: "drift-timeline:tsumigi-v3-harness"
  artifact_type: "drift-timeline"
  phase: "OPS"
  feature: "tsumigi-v3-harness"

coherence:
  id: "drift-timeline:tsumigi-v3-harness"
  depends_on:
    - id: "drift-report:tsumigi-v3-harness"
      relation: "extends"
      confidence: 1.0
      required: true
  band: "Green"
---

# drift タイムライン: tsumigi-v3-harness

> 累積 drift_check 実行履歴。スコアの推移と主要変化を記録する。

---

## 2026-04-05T00:00:00Z — run_id: drift-20260405-001

| drift スコア | CRITICAL | WARNING | INFO | IMP バージョン |
|---|---|---|---|---|
| **4** | 0 | 1 | 1 | 1.1.0 |

**主な変化**: 初回スキャン（ベースライン確立）

| # | レベル | 項目 | 詳細 |
|---|---|---|---|
| 1 | ⚠️ WARNING | D1: phases.json 外部化未実装 | IMP T03 §1.4 で phases.json による定義を仕様化したが、実装は `_check_phase_specific()` 内の Bash case 文。機能的等価だが外部設定ファイルとしての分離は未達。 |
| 2 | ℹ️ INFO | D5: vckd-pipeline.yml timeout-minutes 未設定 | IMP T05 §1.5 の 6h 超過時ジョブ分割を担保する `timeout-minutes` 設定が未記述。GitHub Actions デフォルト上限（6h）に依存中。 |

**フェーズゲート判定**: ✅ PASS（4点 ≤ 閾値 20点）

```
AC カバレッジ: 23/23 = 100%
テスト TC 数: 53件（P0=34, P1=8, P2=4, Security=2）
API 契約乖離: 0件
スキーマ乖離: 0件
タスク完了: T01〜T09 全完了
```

---

<!-- 次回実行時に以下の形式でエントリを追加する:

## {{ISO8601}} — run_id: {{run_id}}

| drift スコア | CRITICAL | WARNING | INFO | IMP バージョン |
|---|---|---|---|---|
| N | N | N | N | {{imp_version}} |

**主な変化**: {{前回との差分の要約}}

| # | レベル | 項目 | 詳細 |
|---|---|---|---|
|   |   |   |   |

**フェーズゲート判定**: ✅ PASS / ❌ FAIL（N点 vs 閾値 N点）

---
-->
