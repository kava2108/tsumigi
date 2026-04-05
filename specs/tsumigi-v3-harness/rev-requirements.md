---
tsumigi:
  node_id: "rev-requirements:tsumigi-v3-harness"
  artifact_type: "rev_requirements"
  phase: "OPS"
  issue_id: "tsumigi-v3-harness"
  created_at: "2026-04-05T00:00:00Z"
  derivation_method: "testcases.md + implementation code から逆算"
coherence:
  id: "rev-requirements:tsumigi-v3-harness"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "reverse_of"
      confidence: 0.90
      required: false
    - id: "test-plan:tsumigi-v3-harness"
      relation: "informed_by"
      confidence: 0.90
      required: false
  band: "Green"
---

# 逆生成要件定義書: tsumigi-v3-harness

> この要件定義書はテストケース（testcases.md）および実装コードから逆算して生成されました。  
> 🟡 マークは「テストが存在しないが実装から推定した」要件を示します。

---

## 機能要件

### FR-001: ラベル起点バトン進行

**EARS 記法**:  
[WHEN] GitHub Issue に `phase:*` ラベルが付与されたとき [THE SYSTEM SHALL] 対応する Phase Agent を起動し、フェーズの成果物を生成する

**根拠**:
- テストコード: `T01/testcases.md` TC-T01-01、`T05/testcases.md` TC-T05-01
- 実装コード: `.tsumigi/hooks/post-tool-use.sh` L44-52、`.github/workflows/vckd-pipeline.yml`
- 信頼性: 🔵

**IMP との整合性**: ✅ 一致（REQ-001）

---

### FR-002: AUTO_STEP 制御

**EARS 記法**:  
[WHEN] `.vckd/config.yaml` の `AUTO_STEP=false` のとき [THE SYSTEM SHALL] `pending:next-phase` ラベルを付与して人間の承認を待ち、`approve` ラベルが付与されてから次のフェーズに進む

**根拠**:
- テストコード: `T03/testcases.md` TC-T03-01、TC-T03-05
- 実装コード: `.tsumigi/lib/phase-gate.sh` `dispatch_baton()` L333-356
- 信頼性: 🔵

**IMP との整合性**: ✅ 一致（REQ-002）

---

### FR-003: AUTO_STEP 自律進行

**EARS 記法**:  
[WHEN] `.vckd/config.yaml` の `AUTO_STEP=true` のとき [THE SYSTEM SHALL] Phase Gate PASS 後に即座に次フェーズのラベルを付与し、新しいフェーズを起動する

**根拠**:
- テストコード: `T03/testcases.md` TC-T03-02
- 実装コード: `.tsumigi/lib/phase-gate.sh` `emit_baton()` L410-449
- 信頼性: 🔵

**IMP との整合性**: ✅ 一致（REQ-002-AC-2）

---

### FR-004: config.yaml 不在時のフォールバック

**EARS 記法**:  
[WHEN] `.vckd/config.yaml` が存在しないとき [THE SYSTEM SHALL] `AUTO_STEP=false` として動作し、フェーズの進行を停止させない

**根拠**:
- テストコード: `T01/testcases.md` TC-T01-04、`T03/testcases.md` TC-T03-10
- 実装コード: `.tsumigi/lib/phase-gate.sh` `_get_config()` L20-30（デフォルト値引数）
- 信頼性: 🔵

**IMP との整合性**: ✅ 一致（REQ-002-AC-3）

---

### FR-005: Phase Gate — 必須ファイルチェック

**EARS 記法**:  
[WHEN] フェーズ遷移が試みられたとき [THE SYSTEM SHALL] 必須成果物ファイルの存在を確認し、1 つでも欠落していれば FAIL を返す

**根拠**:
- テストコード: `T03/testcases.md` TC-T03-07、TC-T03-12
- 実装コード: `.tsumigi/lib/phase-gate.sh` `check_phase_gate()` L201、`_check_artifacts()`
- 信頼性: 🔵

**IMP との整合性**: ✅ 一致（REQ-003-AC-1）

---

### FR-006: Phase Gate — CEG 整合性チェック

**EARS 記法**:  
[WHEN] フェーズ遷移が試みられたとき [THE SYSTEM SHALL] `graph/coherence.json` を DFS で検査し、循環依存が存在する場合は FAIL を返す

**根拠**:
- テストコード: `T03/testcases.md` TC-T03-13、`T07/testcases.md` TC-T07-04
- 実装コード: `.tsumigi/lib/phase-gate.sh` `_check_ceg()` / `commands/coherence-scan.md` Step4
- 信頼性: 🔵

**IMP との整合性**: ✅ 一致（REQ-003-AC-2）

---

### FR-007: baton-log.json の遷移記録

**EARS 記法**:  
[WHEN] バトン遷移（emit_baton / emit_pending / emit_blocked）が実行されたとき [THE SYSTEM SHALL] `graph/baton-log.json` の `transitions` 配列に遷移レコードをアトミックに追記する

**根拠**:
- テストコード: `T01/testcases.md` TC-T01-02
- 実装コード: `.tsumigi/lib/phase-gate.sh` `_append_transition()` L103-110（mktemp + mv パターン）
- 信頼性: 🔵

**IMP との整合性**: ✅ 一致（REQ-004-AC-2）

---

### FR-008: CEG frontmatter の付与

**EARS 記法**:  
[WHEN] `imp_generate` / `implement` / `rev` コマンドで成果物ファイルを生成したとき [THE SYSTEM SHALL] ファイル先頭に `coherence:` frontmatter を付与し、既存 frontmatter がある場合は重複付与しない

**根拠**:
- テストコード: `T02/testcases.md` TC-T02-01〜TC-T02-04
- 実装コード: `commands/imp_generate.md` Step6、`commands/implement.md` Step9、`commands/rev.md` Step5
- 信頼性: 🔵

**IMP との整合性**: ✅ 一致（REQ-005-AC-1）

---

### FR-009: coherence-scan の idempotent 実行

**EARS 記法**:  
[WHEN] `coherence-scan` コマンドが複数回実行されたとき [THE SYSTEM SHALL] `graph/coherence.json` に重複エントリを生成せず、同一の結果を返す

**根拠**:
- テストコード: `T07/testcases.md` TC-T07-03
- 実装コード: `commands/coherence-scan.md` Step5（差分マージ仕様）
- 信頼性: 🔵

**IMP との整合性**: ✅ 一致（REQ-005-AC-2 に包含）

---

### FR-010: AdversaryAgent 5 次元評価

**EARS 記法**:  
[WHEN] `phase:test` フェーズが実行されたとき [THE SYSTEM SHALL] D1〜D5 の全次元を評価し、全スコアが PASS でも最低 1 件の Concern を必ず記録する（強制ネガティブバイアス）

**根拠**:
- テストコード: `T06/testcases.md` TC-T06-01、TC-T06-05
- 実装コード: `.tsumigi/agents/adversary-agent.md`（強制ネガバイアスルール）
- 信頼性: 🟡（LLM 出力依存のため部分的推定）

**IMP との整合性**: ✅ 一致（REQ-008-AC-1）

---

### FR-011: シェルインジェクション防止

**EARS 記法**:  
[WHEN] `VCKD_ISSUE_NUMBER` 環境変数が整数以外の値を持つとき [THE SYSTEM SHALL] `exit 2` を返し、`gh` コマンドを一切実行しない

**根拠**:
- テストコード: `T01/testcases.md` TC-T01-SEC-01、`T03/testcases.md` TC-T03-SEC-01
- 実装コード: `.tsumigi/hooks/post-tool-use.sh` L22（`[[ =~ ^[0-9]+$ ]]`）
- 信頼性: 🔵

**IMP との整合性**: ✅ 一致（セキュリティ要件として明示）

---

### FR-012: gh コマンドリトライ

**EARS 記法**:  
[WHEN] `gh` CLI コマンドが失敗したとき [THE SYSTEM SHALL] exponential backoff（2s → 4s → 8s）で最大 3 回リトライし、3 回全て失敗した場合は `emit_escalate` を呼ぶ

**根拠**:
- テストコード: `T03/testcases.md` TC-T03-14
- 実装コード: `.tsumigi/lib/phase-gate.sh` `_gh_with_retry()` L63-80
- 信頼性: 🔵

**IMP との整合性**: ✅ 一致（REQ-003-AC-1 のエッジケース）

---

### FR-013: baton-log.json 破損時の自己修復

**EARS 記名**:  
[WHEN] `_ensure_baton_log()` が不正な JSON を検出したとき [THE SYSTEM SHALL] 既存ファイルを `.bak` にリネームして新規ファイルで再初期化し、処理を継続する

**根拠**:
- テストコード: `T03/testcases.md` TC-T03-15
- 実装コード: `.tsumigi/lib/phase-gate.sh` `_ensure_baton_log()` L51-59
- 信頼性: 🔵

**IMP との整合性**: ✅ 一致（T03 エッジケース）

---

### FR-014: backward compat — harness.enabled=false

**EARS 記法**:  
[WHEN] `.vckd/config.yaml` の `harness.enabled` が `false` のとき [THE SYSTEM SHALL] 全バトン関連関数が early-return し、GitHub への一切の操作を行わない（tsumigi v2.x 互換）

**根拠**:
- テストコード: `T03/testcases.md` TC-T03-08
- 実装コード: `.tsumigi/lib/phase-gate.sh` `_check_harness_enabled()` L32-37（全 public 関数の先頭で呼ぶ）
- 信頼性: 🔵

**IMP との整合性**: ✅ 一致（T08）

---

## 非機能要件

### NFR-001: アトミック書き込み

**根拠**: `_append_transition()`, `_ensure_baton_log()` が `mktemp → jq → mv` パターンで一貫して実装されていることを確認  
**信頼性**: 🔵

### NFR-002: idempotent 設計

**根拠**: `install --harness` の重複実行が settings.json を破壊しないこと（TC-T01-05）。`coherence-scan` が重複エントリを生成しないこと（TC-T07-03）  
**信頼性**: 🔵

### NFR-003: テストモード分離

**根拠**: `VCKD_TEST_MODE=1` で `gh` が `mock_gh` に置き換わることを `phase-gate.sh` L12-14 で確認  
**信頼性**: 🔵

---

## 元の IMP に存在するが実装で未確認の要件

| IMP 要件 | 状態 | 推奨アクション |
|---|---|---|
| `phases.json` によるフェーズ固有チェック定義（IMP T03 §1.4） | 🟡 実装の中で JSON ファイル参照は確認できず Bash 関数内に直接実装か | `/tsumigi:drift_check tsumigi-v3-harness` で確認 |
| GitHub Actions の 6h 超過時のジョブ分割（IMP T05 §1.5） | 🟡 ワークフローファイルに明示的な timeout/分割は未確認 | 手動でワークフロー確認 |
| ChangeAgent の PR エビデンス 4 点添付評価（IMP T06 §1.4） | 🟡 agent.md に明示されているが LLM 出力依存 | e2e テストで確認（TC-T06-03） |
