---
tsumigi:
  node_id: "drift:T13"
  artifact_type: "drift"
  phase: "OPS"
  issue_number: 11
  task_id: "T13"
  created_at: "2026-04-05T13:00:00Z"
coherence:
  id: "drift:T13"
  depends_on:
    - id: "adversary:T13"
      relation: "reviews"
      required: true
    - id: "impl:tsumigi-v3-harness:T13"
      relation: "verifies"
      confidence: 1.0
      required: true
  band: "Green"
---

# Drift Report — T13 phases.json 外部化

**全体判定**: ✅ Green（drift score: 0）  
**実行日時**: 2026-04-05T13:00:00Z  
**対象 Issue**: [#11](https://github.com/kava2108/tsumigi/issues/11)

---

## 1. 概要

T13 の drift 評価を 5 次元（D1〜D5）で実施した。

IMP.md §T13 が要求した「`_check_phase_specific()` の Bash `case` 文廃止 + `phases.json` 外部化」は、
実装・テスト・adversary review のすべてにおいて仕様との乖離なく完了している。
drift score は **0**（全次元 PASS）であり、残存する軽微な指摘は T13 スコープ外として既知事項に分類される。

---

## 2. 評価（5 次元）

### D1 Spec Drift（仕様との乖離）

**判定**: ✅ PASS（drift なし）

| IMP.md §T13 要求 | 実装 | 乖離 |
|----------------|------|------|
| `case` 文の完全廃止 | `_check_phase_specific()` の `case` 文を削除済み | なし |
| `.tsumigi/config/phases.json` を `jq` で参照 | 実装済み | なし |
| `{feature}` / `{issue-id}` テンプレート変数を保持 | JSON にそのまま保持 | なし |
| `phases.json` 不在時は FAIL（安全側） | `return 1` 実装済み | なし |
| drift D1 の恒久解消 | IMP.md §T13 の目的を達成 | なし |

drift D1（ハードコードされたフェーズリスト）は T13 の実装により **恒久解消済み**。

### D2 Design Drift（設計との乖離）

**判定**: ✅ PASS（drift なし）

TDS §5.2 の疑似コードで定義された `_check_phase_specific()` の責務（フェーズ固有チェックの実行）は、
JSON ドリブンへの移行後も変わらず維持されている。

- `_check_artifacts()` / `_check_ceg()` / `_check_gray()` との責務分離は保たれており、設計の境界が崩れていない。
- `check_phase_gate()` の呼び出し順序（Step 1〜4）は T13 前後で変更なし。

### D3 Implementation Drift（実装との乖離）

**判定**: ✅ PASS（drift なし）

元の `case` 文のロジックは `_run_phase_check()` に過不足なく移植されている。

| フェーズ遷移 | 元ロジック | 移植後 | 乖離 |
|------------|----------|--------|------|
| REQ（ears_format 等） | AC ID が 3 件以上 | `_run_phase_check()` で同一ロジック | なし |
| TDS（all_ac_covered_in_design） | スキップ | スキップ（`_check_artifacts` で実施済み） | なし |
| IMP（all_tasks_have_patch_plan） | `grep -q "patch-plan"` | 同一 | なし |
| TEST（adversary_pass） | `grep -q "全体判定.*PASS\|PASS"` | 同一 | なし |
| OPS（drift_score_threshold） | `drift_score <= threshold` | 同一 | なし |
| OPS（no_gray_nodes） | `_check_gray()` 委譲 | 同一 | なし |

### D4 Test Drift（テストとの乖離）

**判定**: ✅ PASS（drift なし）

T03 テストスイートの回帰実行結果（T13 実装後）：

```
結果: PASS=13 / FAIL=0 / SKIP=0
```

T13 の変更によってテストの期待結果が変化した項目はない。
`_check_phase_specific()` の内部実装が変わっても、外部から観測可能な振る舞い（PASS/FAIL の判定結果）は同一であることを確認済み。

### D5 Operational Drift（運用との乖離）

**判定**: ✅ PASS（drift なし）

| 観点 | 評価 |
|------|------|
| `jq` 依存 | 既存の `_check_ceg()` / `_ensure_baton_log()` でも使用済みであり、新規の運用上の依存増加ではない |
| `phases.json` の配置 | `.tsumigi/config/phases.json` に配置済み。install 手順への追加は不要（リポジトリに含まれる） |
| フォールバック動作 | `phases.json` 不在時 `return 1`（FAIL）。既存の `check_phase_gate()` の FAIL ハンドリングと整合 |
| 後方互換性 | 未定義フェーズ遷移は `return 0`（PASS）で従来動作を維持 |

---

## 3. 総合判定

**Green** ✅（drift score: 0）

5 次元の評価すべてで drift なし。T13 の実装は仕様・設計・実装・テスト・運用の各観点において乖離なく完了している。

---

## 4. 備考

- **`required_files` の未活用**: `phases.json` の `required_files` フィールドは現時点で `_check_phase_specific()` から読み込まれていない（`_check_artifacts()` の `case` 文が担当）。これは T13 のスコープ外であり、既知事項として記録する。将来 `_check_artifacts()` も JSON 外部化する際に対応すること。
- **`grep -oP` の macOS 非互換**: `_run_phase_check()` 内の `drift_score_threshold` チェックで `grep -oP`（Perl regex）を使用しており、macOS (bash 3.2) での非互換が残存する。T18（macOS 互換対応）で解消予定。
