---
tsumigi:
  node_id: "impl:tsumigi-v3-harness:T10"
  artifact_type: "patch_plan"
  phase: "IMP"
  issue_id: "tsumigi-v3-harness"
  task_id: "T10"
  created_at: "2026-04-05T05:37:04Z"
coherence:
  id: "impl:tsumigi-v3-harness:T10"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "implements"
      confidence: 0.95
      required: true
    - id: "test:tsumigi-v3-harness:T01"
      relation: "verifies"
      confidence: 1.0
      required: true
    - id: "test:tsumigi-v3-harness:T04"
      relation: "verifies"
      confidence: 1.0
      required: true
    - id: "test:tsumigi-v3-harness:T07"
      relation: "verifies"
      confidence: 1.0
      required: true
  band: "Green"
---

# Patch Plan: tsumigi-v3-harness / T10

**タスク**: T10 — T01/T04/T07 Bash テストスクリプト実装  
**完了日**: 2026-04-05  
**担当**: ImplementAgent  
**参照パターン**: `specs/tsumigi-v3-harness/tests/T03/test_phase_gate.sh`（13/13 PASS）

---

## 変更スコープ

| ファイル | 操作 | 説明 |
|---|---|---|
| `specs/tsumigi-v3-harness/tests/T01/test_baton_infra.sh` | **新規作成** | Baton Infrastructure 単体テスト |
| `specs/tsumigi-v3-harness/tests/T04/test_phase_agent.sh` | **新規作成** | Phase Agent コンテンツ検証テスト |
| `specs/tsumigi-v3-harness/tests/T07/test_coherence_scan.sh` | **新規作成** | coherence-scan / baton-status テスト |
| `specs/tsumigi-v3-harness/implements/T10/patch-plan.md` | **新規作成** | このファイル |

---

## テストスクリプト詳細

### test_baton_infra.sh（T01）

**テスト対象**: `.tsumigi/lib/phase-gate.sh`  
**テスト数**: 4件（PASS=4 / FAIL=0 / SKIP=0）  
**実行確認**: ✅ 2026-04-05

| TC | 分類 | 内容 | 結果 |
|---|---|---|---|
| TC-T01-02 | 正常系 | emit_baton → baton-log.json に遷移記録 | ✅ PASS |
| TC-T01-03 | 正常系 | AUTO_STEP=false → emit_pending 呼出 | ✅ PASS |
| TC-T01-04 | 異常系 | config.yaml 不在 → emit_pending フォールバック | ✅ PASS |
| TC-T01-SEC-01 | セキュリティ | issue_number 非整数 → exit 2 | ✅ PASS |

**設計ポイント**:
- T03 と同じパターン（サブシェル + ファイルベーススパイ + `export -f mock_gh`）
- `source` 後に `_check_harness_enabled` を上書きしてハーネスを有効化
- TC-T01-02 は `emit_baton` が `_append_transition` を通じて baton-log.json を直接更新することを確認

---

### test_phase_agent.sh（T04）

**テスト対象**: `.tsumigi/agents/*.md`（Phase Agent プロンプトファイル）  
**テスト数**: 6 PASS + 2 SKIP  
**実行確認**: ✅ 2026-04-05

| TC | 分類 | 内容 | 結果 |
|---|---|---|---|
| TC-T04-01 | 正常系 | requirements-agent.md 存在 + EARS 言及 | ✅ PASS |
| TC-T04-02 | 正常系 | design-agent.md 存在 + design.md/tasks.md 言及 | ✅ PASS |
| TC-T04-03 | 正常系 | implement-agent.md が imp_generate 先行実行を明記 | ✅ PASS |
| TC-T04-04 | 正常系 | implement-agent.md が P0→P1 の phase:imp 付与を明記 | ✅ PASS |
| TC-T04-SEC-01 | セキュリティ | requirements-agent.md 他 Issue 読み取り禁止（D2-02） | ✅ PASS |
| TC-T04-SEC-02 | セキュリティ | implement-agent.md adversary-report 実装前禁止（D2-02） | ✅ PASS |
| TC-T04-01 e2e | — | RequirementsAgent → requirements.md 生成 | ⏭ SKIP |
| TC-T04-02 e2e | — | DesignAgent → design.md / tasks.md 生成 | ⏭ SKIP |

**設計ポイント**:
- エージェントは Claude Code スラッシュコマンドのため bash から直接実行不可
- コンテンツ検証（grep）で仕様準拠・セキュリティ対策の記述を確認
- SKIP 理由を明示し手動テスト推奨の形で残す

---

### test_coherence_scan.sh（T07）

**テスト対象**: `graph/coherence.json`、`graph/baton-log.json`、jq ロジック  
**テスト数**: 9件（PASS=9 / FAIL=0 / SKIP=0）  
**実行確認**: ✅ 2026-04-05

| TC | 分類 | 内容 | 結果 |
|---|---|---|---|
| TC-T07-01 | 正常系 | coherence.json に既知ノードが全て存在 | ✅ PASS |
| TC-T07-02 | 正常系 | baton-log.json pending エントリの jq クエリ正確性 | ✅ PASS |
| TC-T07-03 | 正常系 | coherence.json ノード数の冪等性 | ✅ PASS |
| TC-T07-04 | 異常系 | 循環依存 A→B→A を DFS で検出 | ✅ PASS |
| TC-T07-05 | 異常系 | ダングリング参照ノードが Amber バンド | ✅ PASS |
| TC-T07-06 | 異常系 | 壊れた frontmatter があっても他ファイルのパース継続 | ✅ PASS |
| TC-T07-07 | 境界値 | 空 nodes の coherence.json が valid JSON | ✅ PASS |
| TC-T07-SEC-01 | セキュリティ | node_id への shell injection → 文字列として安全取得（D2-04） | ✅ PASS |
| TC-T07-SEC-02 | セキュリティ | band フィールドの不正値を jq が安全に処理（D2-04） | ✅ PASS |

**設計ポイント**:
- coherence-scan は Claude Code コマンドのため直接実行せず、出力 JSON を検証
- TC-T07-04 は T03 の `_check_ceg()` と同一 DFS jq クエリを再利用（回帰テスト）
- TC-T07-SEC-01: `grep -oP` でダブルクォート内のみ抽出するため shell injection が不活性化される

---

## 受け入れ基準充足確認

| AC-ID | 内容 | 充足ファイル |
|---|---|---|
| REQ-009-AC-1 | T01/T04/T07 の Bash テストスクリプトが実装されている | test_baton_infra.sh, test_phase_agent.sh, test_coherence_scan.sh |
| REQ-009-AC-2 | 各スクリプトが `PASS=N / FAIL=0` で終了する | 実行確認済み（計 19 PASS） |
| REQ-009-AC-3 | T03 のテストパターン（サブシェル + スパイ）を踏襲している | test_baton_infra.sh のパターン確認 |

---

## 実装ノート

**T01 の特殊考慮事項**:
- `emit_baton` は `_check_harness_enabled || return 0` で始まるため、source 後に `_check_harness_enabled() { return 0; }` で上書きが必要
- `emit_baton` は gh call に加えて `_append_transition` で baton-log.json を直接更新するため、モッキングなしでファイル書き込みを確認可能

**T04 の特殊考慮事項**:
- セキュリティ TCs（D2-02）は 🟡 推定（LLM の prompt injection 耐性は環境依存）
- Bash レベルでは「仕様書に禁止規定が記述されている」ことを確認するに留まる

**T07 の特殊考慮事項**:
- TC-T07-05 は現行 coherence.json の Amber ノード（`req:tsumigi-v3-harness` のダングリング参照）に依存
- `req:tsumigi-v3-harness` ノードが作成されると TC-T07-05 は FAIL になる（T16 実装後に更新が必要）
