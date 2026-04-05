---
tsumigi:
  node_id: "impl:tsumigi-v3-harness:T11"
  artifact_type: "patch_plan"
  phase: "IMP"
  issue_id: "tsumigi-v3-harness"
  task_id: "T11"
  created_at: "2026-04-05T05:44:05Z"
coherence:
  id: "impl:tsumigi-v3-harness:T11"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "implements"
      confidence: 0.95
      required: true
  band: "Green"
---

# Patch Plan: tsumigi-v3-harness / T11

**タスク**: T11 — `VCKD_FROM_PHASE` 許可リスト検証  
**完了日**: 2026-04-05  
**担当**: ImplementAgent  
**対応 review-questions**: Q4（`VCKD_FROM_PHASE` に不正値が渡された場合の処理）

---

## 変更スコープ

| ファイル | 操作 | 説明 |
|---|---|---|
| `.tsumigi/lib/phase-gate.sh` | **変更** | `_validate_from_phase()` 関数を追加、`check_phase_gate()` 冒頭で呼び出し |
| `.tsumigi/hooks/post-tool-use.sh` | **変更** | `VCKD_FROM_PHASE` 許可リスト検証を追加（空文字チェック直後） |
| `specs/tsumigi-v3-harness/tests/T11/test_vckd_from_phase.sh` | **新規作成** | 7件の自動テスト（PASS=7 / FAIL=0） |
| `specs/tsumigi-v3-harness/implements/T11/patch-plan.md` | **新規作成** | このファイル |

---

## 実装詳細

### `.tsumigi/lib/phase-gate.sh` の変更

**追加した `_validate_from_phase()` 関数**（内部ユーティリティセクション末尾）:

```bash
# _validate_from_phase: from_phase 引数の許可リスト検証（REQ-010）
# 引数: $1=phase 文字列
# 戻り値: 0=OK, 2=不正値
_validate_from_phase() {
  local phase="$1"
  # 空文字はスキップ（REQ-010-AC-2: 既存動作との後方互換性維持）
  [[ -z "$phase" ]] && return 0
  [[ "$phase" =~ ^(REQ|TDS|IMP|TEST|OPS|CHANGE)$ ]] \
    || { echo "ERROR: invalid phase='$phase' — allowed: REQ|TDS|IMP|TEST|OPS|CHANGE" >&2; return 2; }
}
```

**`check_phase_gate()` の変更**（harness 有効化チェック直後に検証挿入）:

```diff
-  local from_phase="$1"
-  local feature="${2:-}"
-  local issue_id="${3:-}"
-
-  local result="PASS"
+  local from_phase="$1"
+  local feature="${2:-}"
+  local issue_id="${3:-}"
+
+  # from_phase 許可リスト検証（REQ-010-AC-1）
+  _validate_from_phase "$from_phase" || return 2
+
+  local result="PASS"
```

### `.tsumigi/hooks/post-tool-use.sh` の変更

`VCKD_FROM_PHASE` の空チェック直後に許可リスト検証を追加:

```diff
 [[ -z "${VCKD_FROM_PHASE:-}" ]] && exit 0
+# VCKD_FROM_PHASE 許可リスト検証（REQ-010-AC-1）
+[[ "$VCKD_FROM_PHASE" =~ ^(REQ|TDS|IMP|TEST|OPS|CHANGE)$ ]] \
+  || { echo "ERROR: invalid VCKD_FROM_PHASE='$VCKD_FROM_PHASE' — allowed: REQ|TDS|IMP|TEST|OPS|CHANGE" >&2; exit 2; }
 [[ -z "${VCKD_ISSUE_NUMBER:-}" ]] && exit 0
```

---

## テストスクリプト詳細

**ファイル**: `specs/tsumigi-v3-harness/tests/T11/test_vckd_from_phase.sh`  
**テスト数**: 7件（PASS=7 / FAIL=0 / SKIP=0）  
**実行確認**: ✅ 2026-04-05

| TC | 分類 | 内容 | 結果 |
|---|---|---|---|
| TC-T11-01 | 正常系 | 全許可フェーズ（REQ/TDS/IMP/TEST/OPS/CHANGE）が PASS | ✅ PASS |
| TC-T11-02 | 正常系 | 空文字のとき exit 0 でスキップ（REQ-010-AC-2） | ✅ PASS |
| TC-T11-03 | 異常系 | 不正値「DEPLOY」→ return 2（REQ-010-AC-1） | ✅ PASS |
| TC-T11-04 | 異常系 | 小文字「req」→ return 2（大文字のみ許可） | ✅ PASS |
| TC-T11-05 | 異常系 | check_phase_gate に不正 from_phase → return 2 | ✅ PASS |
| TC-T11-SEC-01 | セキュリティ | post-tool-use.sh 不正 VCKD_FROM_PHASE → exit 2 | ✅ PASS |
| TC-T11-SEC-02 | セキュリティ | post-tool-use.sh 正常フェーズ（IMP）は許可リスト通過 | ✅ PASS |

**回帰テスト確認**: T03（phase-gate.sh）13/13 PASS ✅

---

## 受け入れ基準充足確認

| AC-ID | 内容 | 充足確認 |
|---|---|---|
| **REQ-010-AC-1** | WHEN `VCKD_FROM_PHASE` が許可リスト外のとき THE SYSTEM SHALL エラーを出力して exit 2 する | TC-T11-03, TC-T11-05, TC-T11-SEC-01 ✅ |
| **REQ-010-AC-2** | WHEN `VCKD_FROM_PHASE` が空文字のとき THE SYSTEM SHALL exit 0 でスキップする | TC-T11-02 ✅ |

---

## セキュリティ考慮事項

**シェルインジェクション防止**:
- `[[ "$var" =~ ^(...)$ ]]` を使用しており、`eval` や `$()` によるコマンド実行は発生しない
- 不正値は `echo "ERROR: ..." >&2; return 2` / `exit 2` で処理（エラーメッセージに変数値をエコーバックするが、標準エラーへの出力のみで実行は行わない）
- エラーメッセージ中に `$phase` の値を含めるが、これは診断目的の出力のみ（コマンド置換ではない）

**後方互換性**:
- `VCKD_FROM_PHASE` が未設定・空文字の場合は既存の `exit 0` / `return 0` 動作を維持（REQ-010-AC-2）
- `harness.enabled=false` の場合は `check_phase_gate` が `_check_harness_enabled || return 0` で早期リターンするため影響なし
