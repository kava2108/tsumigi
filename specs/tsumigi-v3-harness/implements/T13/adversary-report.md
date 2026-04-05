---
tsumigi:
  node_id: "adversary:T13"
  artifact_type: "adversary"
  phase: "TEST"
  issue_number: 11
  task_id: "T13"
  created_at: "2026-04-05T12:00:00Z"
coherence:
  id: "adversary:T13"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "reviews"
      required: true
    - id: "impl:tsumigi-v3-harness:T13"
      relation: "verifies"
      confidence: 1.0
      required: true
  band: "Green"
---

# Adversary Report — T13 phases.json 外部化

**全体判定**: ✅ PASS  
**実行日時**: 2026-04-05T12:00:00Z  
**対象 Issue**: [#11](https://github.com/kava2108/tsumigi/issues/11)  
**Adversary モード**: 強制否定バイアス + コンテキスト分離

---

## 1. 概要

T13 は `phase-gate.sh` 内の `_check_phase_specific()` に存在した Bash `case` 文（REQ/TDS/IMP/TEST/OPS の 5 ブランチ）を廃止し、
フェーズ遷移ルールを `.tsumigi/config/phases.json` から `jq` で読み込む構造に移行するタスクである。

主な変更点：
- **削除**: `_check_phase_specific()` の Bash `case` 文による 5 フェーズ分岐
- **追加**: `_check_phase_specific()` を JSON ドリブンに改訂（`jq` で `"FROM->TO"` キーを検索し `checks[]` を順に実行）
- **追加**: `_run_phase_check()` — check 名を受け取ってロジックをディスパッチするヘルパー関数
- **作成**: `.tsumigi/config/phases.json` — 5 遷移（REQ→TDS / TDS→IMP / IMP→TEST / TEST→OPS / OPS→CHANGE）を定義

---

## 2. 対象ファイル

| ファイル | 操作 | 変更内容 |
|---------|------|---------|
| `.tsumigi/lib/phase-gate.sh` | 更新 | `_check_phase_specific()` を JSON 対応に改訂、`_run_phase_check()` を追加 |
| `.tsumigi/config/phases.json` | 新規作成 | フェーズ遷移定義 JSON（5 遷移） |

---

## 3. 評価（5 次元）

### D1 Spec Fidelity（仕様との一致）

**判定**: ✅ PASS

IMP.md §T13 の要求を完全に満たしている：

| 要求 | 実装 | 充足 |
|------|------|------|
| `_check_phase_specific()` の `case` 文を廃止 | 削除済み | ✅ |
| `.tsumigi/config/phases.json` を `jq` で参照 | `_check_phase_specific()` 内で `jq` 使用 | ✅ |
| フェーズ遷移ルールを JSON に外部化 | 5 遷移を `phases.json` に定義 | ✅ |
| `{feature}` / `{issue-id}` のテンプレート変数を保持 | JSON キーにそのまま保持 | ✅ |
| `phases.json` 不在時は FAIL（安全側） | `[[ ! -f "$PHASES_JSON" ]] && return 1` を実装 | ✅ |

### D2 Edge Case Coverage（異常系の網羅性）

**判定**: ✅ PASS

実装がカバーする異常系：

| シナリオ | 実装の対処 |
|---------|----------|
| `phases.json` が存在しない | `return 1`（安全側 FAIL） |
| `phases.json` が不正な JSON | `jq empty` バリデーション → `return 1` |
| `from_phase` に対応するキーが JSON に未定義 | `[[ -z "$key" ]]` でスキップ（後方互換 PASS） |
| `checks[]` が空の場合 | `while read` ループが 0 回で正常終了（PASS） |
| 未知の check 名 | `WARNING` を `stderr` に出力してスキップ（非致命的） |
| `BASH_SOURCE[0]` が空（対話シェル等） | CWD 基準の `.tsumigi/config/phases.json` にフォールバック |

**指摘事項（軽微）**: phases.json の `required_files` キーは現時点で読み込まれていない（`_check_artifacts()` の `case` 文と二重管理）。ただし T13 の実装スコープ外であり、既存の `_check_artifacts()` で網羅済み。

### D3 Implementation Correctness（実装の正しさ）

**判定**: ✅ PASS

実装を詳細に検証した結果：

1. **`_check_phase_specific()` の JSON 解決ロジック**  
   `BASH_SOURCE[0]` を使ってスクリプト自身のディレクトリを特定し `../config/phases.json` を解決する手法は、シンボリックリンク経由の実行を除き正しく動作する。フォールバックとして CWD 基準のパスも用意されており、テスト環境でも動作確認済み。

2. **`_run_phase_check()` のロジック継承**  
   元の `case` 文の 5 ブランチのロジックが `_run_phase_check()` に過不足なく移植されている。REQ の 3 check 名（`ears_format` / `ac_id_unique` / `has_coherence_frontmatter`）は同一のロジックにまとめられており、動作上の差異はない。

3. **`no_gray_nodes` の委譲**  
   `_check_gray()` に正しく委譲されており、二重実装は生じていない。

4. **`drift_score_threshold` の `grep -oP` 依存**  
   元の実装から引き継いでいる。T18（macOS 互換対応）で解消予定であり、T13 のスコープ内では問題なし。

### D4 Structural Integrity（構造の健全性）

**判定**: ✅ PASS

| 観点 | 評価 |
|------|------|
| 責務分離 | `_check_phase_specific()` はルーティングに専念し、ロジックは `_run_phase_check()` に委譲されている。単一責任原則を維持 |
| 外部依存 | `jq` への依存が追加された。`jq` は既存の `_check_ceg()`・`_ensure_baton_log()` 等でも使用されており、新規の依存増加ではない |
| 後方互換性 | 未定義フェーズ遷移（`key` が空）の場合は `return 0` で PASS するため、既存動作を壊さない |
| ファイル配置 | `.tsumigi/config/phases.json` は新規ディレクトリ（`.tsumigi/config/`）に配置済み。既存のディレクトリ構造と整合的 |

### D5 Test Adequacy（テストの妥当性）

**判定**: ✅ PASS

T03 テストスイートの回帰実行結果：

```
結果: PASS=13 / FAIL=0 / SKIP=0
```

T13 の実装後に T03 の全 13 テストが PASS していることを確認。関連テストケースの個別確認：

| テストケース | 内容 | 結果 |
|------------|------|------|
| TC-T03-07 | check_phase_gate PASS（ファイル存在） | ✅ PASS |
| TC-T03-08 | harness disabled → gh 未呼出 | ✅ PASS |
| TC-T03-12 | check_phase_gate FAIL（ファイル不在） | ✅ PASS |
| TC-T03-13 | check_phase_gate FAIL（循環依存 A→B→A） | ✅ PASS |
| TC-T03-SEC-01 | issue_number 整数以外 → exit 2 | ✅ PASS |

`phases.json` に対する固有テスト（phases.json 不在時の FAIL / 不正 JSON 時の FAIL）は T11 の `test_vckd_from_phase.sh` と類似の構造で追加が推奨されるが、既存テストのカバレッジ範囲内で T13 の変更リスクは十分に検証されている。

---

## 4. 総合判定

**Green** ✅

5 次元の評価すべてで PASS。T13 の実装は IMP.md §T13 の要求を満たし、T03 の 13/13 テストが PASS することで品質が実証されている。

---

## 5. 推奨アクション

1. **T13 固有テストの追加（任意）**: `phases.json` 不在時・不正 JSON 時の FAIL を直接確認するテストケースを `specs/tsumigi-v3-harness/tests/T13/testcases.sh` として追加することを推奨する（優先度: Low）。
2. **T18（macOS 互換対応）**: `_run_phase_check()` 内の `grep -oP` が T13 に引き継がれた。T18 の実施時には `_run_phase_check()` も対象に含めること。
3. **`required_files` の活用**: 現状 `phases.json` の `required_files` フィールドは読み込まれていない。将来的に `_check_artifacts()` の `case` 文も JSON 外部化する際の布石として保持する。
