<!--
{
  "ceg": {
    "phase": "ops",
    "artifact_type": "drift-report",
    "generated_by": "Claude"
  }
}
-->
---
tsumigi:
  node_id: "drift-report:tsumigi-v3-harness"
  artifact_type: "drift-report"
  phase: "OPS"
  feature: "tsumigi-v3-harness"
  issue_id: "tsumigi-v3-harness"
  run_id: "drift-20260405-001"
  run_at: "2026-04-05T00:00:00Z"
  imp_version: "1.1.0"
  drift_baseline: "e5ef7f0c021d7c5c9b74ab7ce91e2e03e00a7eaf"
  drift_score: 4
  threshold: 20
  status: "Aligned"

coherence:
  id: "drift-report:tsumigi-v3-harness"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "validates"
      confidence: 1.0
      required: true
    - id: "rev-spec:tsumigi-v3-harness"
      relation: "references"
      confidence: 1.0
      required: true
    - id: "test-plan:tsumigi-v3-harness"
      relation: "references"
      confidence: 1.0
      required: true
  band: "Green"
---

# 乖離レポート: tsumigi-v3-harness

**run_id**: `drift-20260405-001`  
**実行日時**: 2026-04-05T00:00:00Z  
**IMP バージョン**: 1.1.0  
**drift_baseline**: `e5ef7f0c021d7c5c9b74ab7ce91e2e03e00a7eaf`  
**閾値**: 20点

---

## スコアサマリー

```
drift スコア: 4/100 — ✅ Aligned（乖離なし）

CRITICAL: 0件 (×10点 = 0点)
WARNING:  1件 (×3点  = 3点)
INFO:     1件 (×1点  = 1点)
合計:     4点
```

> 閾値 **20点** に対して **4点** — フェーズゲート通過可能

---

## D1: 機能仕様の乖離

> IMP の各 AC が実装・テスト両面でカバーされているか検証する。

| AC | テスト | 実装 | 判定 | スコア |
|---|---|---|---|---|
| REQ-001-AC-1: phase:* ラベル → Phase Agent 起動 | ✅ TC-T01-01, TC-T05-01 | ✅ vckd-pipeline.yml routing | COVERED | 0 |
| REQ-001-AC-2: emit_pending → pending:next-phase 付与 | ✅ TC-T03-04 | ✅ post-tool-use.sh, on-label-added.sh | COVERED | 0 |
| REQ-001-AC-3: emit_baton → 即座に phase:yyy 付与 | ✅ TC-T03-05 | ✅ dispatch_baton + emit_baton | COVERED | 0 |
| REQ-001-AC-4: approve → pending 解除 + 次フェーズ付与 | ✅ TC-T03-06 | ✅ on-label-added.sh handle-approve | COVERED | 0 |
| REQ-001-AC-5: emit_blocked → blocked:xxx 付与 | ✅ TC-T03-07 | ✅ emit_blocked in phase-gate.sh | COVERED | 0 |
| REQ-002-AC-1: AUTO_STEP=false → emit_pending 呼出 | ✅ TC-T03-01 | ✅ dispatch_baton case branch | COVERED | 0 |
| REQ-002-AC-2: AUTO_STEP=true → emit_baton 呼出 | ✅ TC-T03-02 | ✅ dispatch_baton auto branch | COVERED | 0 |
| REQ-002-AC-3: config.yaml 不在 → AUTO_STEP=false | ✅ TC-T01-02, TC-T03-03 | ✅ _get_auto_step() fallback | COVERED | 0 |
| REQ-003-AC-1: check_phase_gate 必須成果物不在 → FAIL | ✅ TC-T03-08 | ✅ _check_artifacts() case | COVERED | 0 |
| REQ-003-AC-2: check_phase_gate 循環依存検出 → FAIL | ✅ TC-T03-09 | ✅ _check_ceg() DFS | COVERED | 0 |
| REQ-003-AC-3: check_phase_gate フェーズ固有失敗 → FAIL | ✅ TC-T03-10 | ✅ _check_phase_specific() case | COVERED | 0 |
| REQ-003-AC-4: check_phase_gate Gray ノード → FAIL | ✅ TC-T03-11 | ✅ _check_gray() jq query | COVERED | 0 |
| REQ-004-AC-2: emit_baton 後 baton-log.json に遷移記録 | ✅ TC-T01-03, TC-T07-02 | ✅ emit_baton JSON append | COVERED | 0 |
| REQ-005-AC-1: frontmatter が IMP.md / patch-plan.md に存在 | ✅ TC-T02-01〜03 | ✅ post-tool-use.sh inject | COVERED | 0 |
| REQ-005-AC-2: coherence-scan 実行後 全ノードが coherence.json に存在 | ✅ TC-T07-01 | ✅ commands/coherence-scan.md | COVERED | 0 |
| REQ-006-AC-1: baton-status が pending エントリを正確に表示 | ✅ TC-T07-02 | ✅ commands/baton-status.md | COVERED | 0 |
| REQ-006-AC-2: baton-status が直近 10 件のバトン遷移を表示 | ✅ TC-T07 Suite | ✅ commands/baton-status.md | COVERED | 0 |
| REQ-007-AC-1: Phase Agent 起動後 成果物ファイルが生成される | ✅ TC-T04-01, TC-T06-04 | ✅ agents/*.md → Claude 実行 | COVERED | 0 |
| REQ-007-AC-2: 3回リトライ後 blocked:escalate 付与 | ✅ TC-T04-02 | ✅ get_retry_count + emit_blocked | COVERED | 0 |
| REQ-008-AC-1: AdversaryAgent が 5 次元評価を全て実施 | ✅ TC-T06-01 | ✅ adversary-agent.md D1〜D5 | COVERED | 0 |
| REQ-008-AC-2: FAIL 時に次元ごとの根拠がコメントに投稿 | ✅ TC-T06-02 | ✅ adversary-agent.md FAIL branch | COVERED | 0 |
| REQ-009-AC-1: harness.enabled=false → 全 baton 関数が無効化 | ✅ TC-T03-SEC-01 suite | ✅ _check_harness_enabled() guard | COVERED | 0 |
| REQ-009-AC-2: VCKD_TEST_MODE=1 → GitHub API 呼出なし | ✅ TC-T01-SEC-01 | ✅ dry-run分岐 in emit_* 関数 | COVERED | 0 |
| **IMP T03 §1.4**: フェーズ固有チェックの phases.json 外部化 | ✅ TC-T03-10（動作確認） | ⚠️ Bash case 文で実装（JSON 定義ファイルなし） | **WARNING** | **+3** |

**D1 小計**: 3点（WARNING 1件）

### D1 補足

IMP T03 §1.4 は「フェーズ固有チェックは JSON ファイルで定義する（`phases.json`）」と仕様化していたが、  
実際の実装では `_check_phase_specific()` 内の `case "$from_phase" in` Bash 構文として直接実装されている。  
`phases.json` ファイルは存在しない（`file_search "**/phases.json"` → 0 件）。

**影響**: 機能的には等価。IMP の設計意図（外部設定での拡張容易性）が未達の可能性がある。  
**リスク**: Low — チェックロジック変更時に Bash ファイルを直接編集する必要があり、JSON での一覧管理より変更追跡が困難。

---

## D2: API 契約の乖離

> Bash 公開 API（関数シグネチャ）、環境変数、GitHub ラベル仕様を IMP と照合する。

| API 要素 | IMP 仕様 | 実装 | 乖離内容 | 判定 | スコア |
|---|---|---|---|---|---|
| `check_phase_gate(from_phase, feature, issue_id)` | 3 引数、VCKD_GATE_RESULT エクスポート | ✅ phase-gate.sh L201〜 | 一致 | COVERED | 0 |
| `dispatch_baton(issue_number, current_label, next_label)` | 3 引数、AUTO_STEP 分岐 | ✅ dispatch_baton() 実装済み | 一致 | COVERED | 0 |
| `emit_pending / emit_baton / emit_blocked` | 各 3 引数 | ✅ 全関数 phase-gate.sh 実装済み | 一致 | COVERED | 0 |
| `get_retry_count(issue_number)` | 整数返却 | ✅ baton-log.json から計算 | 一致 | COVERED | 0 |
| `VCKD_GATE_RESULT` 環境変数 | "PASS" / "FAIL" | ✅ export 済み | 一致 | COVERED | 0 |
| `VCKD_FAIL_REASON` 環境変数 | スペース区切り文字列 | ✅ export 済み | 一致 | COVERED | 0 |
| `VCKD_ISSUE_NUMBER` 環境変数 | 整数チェック済み | ✅ 整数バリデーション実装 | 一致 | COVERED | 0 |
| `VCKD_TEST_MODE` 環境変数 | 1 でドライランモード | ✅ emit_* 関数の dry-run 分岐 | 一致 | COVERED | 0 |
| GitHub ラベル 14 種 | TDS §3.1 と一致 | ✅ vckd-pipeline.yml routing 一致 | 一致 | COVERED | 0 |
| GitHub Actions ルーティング | phase:* → 各 agent_file | ✅ case ステートメント 6 ルート | 一致 | COVERED | 0 |

**D2 小計**: 0点

---

## D3: スキーマの乖離

> `.vckd/config.yaml`, `graph/baton-log.json`, `graph/coherence.json`, CEG frontmatter を IMP スキーマと照合する。

| スキーマ | IMP 仕様 | 実装 | 乖離内容 | 判定 | スコア |
|---|---|---|---|---|---|
| `.vckd/config.yaml` | harness.enabled, baton.auto_step, drift_check.threshold | ✅ .vckd/config.yaml 実装済み | 一致 | COVERED | 0 |
| `graph/baton-log.json` | transitions[], entries.from/to/mode/timestamp | ✅ graph/baton-log.json スキーマ一致 | 一致 | COVERED | 0 |
| `graph/coherence.json` | nodes{}, edges[], summary{green/amber/gray} | ✅ graph/coherence.json スキーマ一致 | 一致 | COVERED | 0 |
| CEG frontmatter | tsumigi: / coherence: 両ブロック必須 | ✅ post-tool-use.sh によるインジェクト | 一致 | COVERED | 0 |

**D3 小計**: 0点

---

## D4: テストカバレッジの乖離

> testcases.md の実際のカバレッジを IMP の各タスクテスト戦略と照合する。

| タスク | IMP 目標 TC 数 | 実際 TC 数 | AC カバレッジ | セキュリティ TC | 判定 | スコア |
|---|---|---|---|---|---|---|
| T01: インストール・インフラ | 3件 | 7件 | 3/3 AC = 100% | 1件 (VCKD_TEST_MODE) | COVERED | 0 |
| T02: frontmatter 自動注入 | 3件 | 6件 | 1/1 AC = 100% | 0件 | COVERED | 0 |
| T03: フェーズゲート（T08/T09 含む） | 11件 | 15件 | 11/11 AC = 100% | 1件 (harness disabled) | COVERED | 0 |
| T04: Phase Agent 基盤 | 2件 | 6件 | 2/2 AC = 100% | 0件 | COVERED | 0 |
| T05: GitHub Actions 統合 | 4件 | 6件 | 1/1 AC = 100% | 0件 | COVERED | 0 |
| T06: Phase Agent SP（TEST/OPS/CHANGE） | 4件 | 6件 | 3/3 AC = 100% | 0件 | COVERED | 0 |
| T07: coherence-scan / baton-status | 4件 | 7件 | 2/2 AC = 100% | 0件 | COVERED | 0 |
| **合計** | **31件** | **53件** | **23/23 AC = 100%** | **2件** | **COVERED** | **0** |

**D4 小計**: 0点

---

## D5: タスク完了状態の乖離

> IMP §7 のタスク完了基準を実際の成果物存在と照合する。

| タスク | patch-plan.md | 実装確認 | IMP 記載との差異 | 判定 | スコア |
|---|---|---|---|---|---|
| T01: インストール・インフラ | ✅ implements/T01/patch-plan.md | ✅ install.md, on-label-added.sh | なし | COVERED | 0 |
| T02: frontmatter 自動注入 | ✅ implements/T02/patch-plan.md | ✅ post-tool-use.sh, commands/*.md | なし | COVERED | 0 |
| T03: フェーズゲート | ✅ implements/T03/patch-plan.md | ✅ phase-gate.sh（T08/T09 統合済み） | なし | COVERED | 0 |
| T04: Phase Agent 基盤 | ✅ implements/T04/patch-plan.md | ✅ agents/requirements-agent.md 等 | なし | COVERED | 0 |
| T05: GitHub Actions 統合 | ✅ implements/T05/patch-plan.md | ✅ .github/workflows/vckd-pipeline.yml | なし | COVERED | 0 |
| T06: Phase Agent SP | ✅ implements/T06/patch-plan.md | ✅ agents/adversary-agent.md 等 | なし | COVERED | 0 |
| T07: coherence-scan / baton-status | ✅ implements/T07/patch-plan.md | ✅ commands/coherence-scan.md 等 | なし | COVERED | 0 |
| T08: 後方互換性（T03 統合） | T03 patch-plan に記載 | ✅ _check_harness_enabled() | なし | COVERED | 0 |
| T09: エスカレーション管理（T03/T04 統合） | T03/T04 patch-plan に記載 | ✅ get_retry_count + emit_blocked | なし | COVERED | 0 |
| **IMP T05 §1.5**: 6h 超過時のジョブ分割設定 | — | ⚠️ vckd-pipeline.yml に timeout-minutes 未設定 | 設定漏れ | **INFO** | **+1** |

**D5 小計**: 1点（INFO 1件）

### D5 補足

IMP T05 §1.5 のエッジケース「Actions の実行時間が 6h を超えた場合はジョブをタスク単位で分割する」  
に対応する `timeout-minutes` 設定が `vckd-pipeline.yml` の `run-phase-agent` ジョブに存在しない。

**影響**: GitHub Actions のデフォルト上限（6時間）に依存している状態。  
**リスク**: Low — Phase Agent の実行が 6h を超えるシナリオは通常発生しない。ただし大規模タスクでは問題になる可能性あり。

---

## 推奨アクション

### WARNING: phases.json 外部化（D1）

```bash
# 対処案 A: phases.json を新規作成して _check_phase_specific() から読み込む
# 対処案 B: IMP T03 §1.4 の記述を更新し「Bash case 文による実装」と明記する
```

| 優先度 | 対処 | 担当フェーズ |
|------|------|----------|
| Low | IMP T03 §1.4 を「実際の実装方式（Bash case 文）」に合わせて更新する | CHANGE |
| Medium | 将来の拡張性を考慮し `phases.json` スキーマを定義して実装移行する | TDS（次 Wave） |

### INFO: timeout-minutes 未設定（D5）

```yaml
# vckd-pipeline.yml の run-phase-agent ジョブに追加推奨
jobs:
  run-phase-agent:
    timeout-minutes: 350  # 5h50m （6h 上限 - バッファ 10m）
```

| 優先度 | 対処 | 担当フェーズ |
|------|------|----------|
| Low | `vckd-pipeline.yml` に `timeout-minutes: 350` を追加する | CHANGE |

---

## 結論

```
drift スコア: 4/100 → ✅ Aligned
フェーズゲート: PASS（閾値 20点 以下）

次推奨アクション: /tsumigi:sync tsumigi-v3-harness
```

| 判定項目 | 結果 |
|---------|------|
| AC カバレッジ | 23/23 = 100% ✅ |
| API 契約 | 全一致 ✅ |
| スキーマ整合性 | 全一致 ✅ |
| テストカバレッジ | 53 TC / 23 AC = 100% ✅ |
| タスク完了状態 | T01〜T09 全完了 ✅ |
| 未解決 WARNING | 1件（phases.json 外部化未実装） |
| 未解決 INFO | 1件（timeout-minutes 未設定） |
