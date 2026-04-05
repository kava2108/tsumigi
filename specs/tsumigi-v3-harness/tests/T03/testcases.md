---
tsumigi:
  node_id: "test:tsumigi-v3-harness:T03"
  artifact_type: "testcases"
  phase: "TEST"
  issue_id: "tsumigi-v3-harness"
  task_id: "T03"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "test:tsumigi-v3-harness:T03"
  depends_on:
    - id: "impl:tsumigi-v3-harness:T03"
      relation: "verifies"
      confidence: 1.0
      required: true
    - id: "imp:tsumigi-v3-harness"
      relation: "derives_from"
      confidence: 0.95
      required: true
  band: "Green"
---

# テストケースマトリクス: tsumigi-v3-harness / T03

**対象タスク**: T03 — Phase Gate ロジック実装（T08/T09 含む）  
**生成日**: 2026-04-05  
**フォーカス**: unit, integration

---

## カバレッジサマリー

| AC | 正常系 | 異常系 | 境界値 | セキュリティ | 合計 | カバー状況 |
|---|---|---|---|---|---|---|
| REQ-001-AC-2 | 1 | 0 | 0 | 0 | 1 | ✅ |
| REQ-001-AC-3 | 1 | 0 | 0 | 0 | 1 | ✅ |
| REQ-001-AC-4 | 1 | 1 | 0 | 0 | 2 | ✅ |
| REQ-001-AC-5 | 1 | 0 | 0 | 0 | 1 | ✅ |
| REQ-002-AC-1 | 1 | 0 | 0 | 0 | 1 | ✅ |
| REQ-002-AC-2 | 1 | 0 | 0 | 0 | 1 | ✅ |
| REQ-002-AC-3 | 1 | 1 | 0 | 0 | 2 | ✅ |
| REQ-003-AC-1 | 1 | 0 | 0 | 0 | 1 | ✅ |
| REQ-003-AC-2 | 1 | 0 | 0 | 0 | 1 | ✅ |
| REQ-003-AC-3 | 1 | 0 | 0 | 0 | 1 | ✅ |
| REQ-003-AC-4 | 1 | 0 | 0 | 0 | 1 | ✅ |
| REQ-006-AC-1 | 1 | 0 | 0 | 0 | 1 | ✅ |
| REQ-006-AC-2 | 1 | 0 | 0 | 0 | 1 | ✅ |

カバレッジ率: 13/13 AC = **100%**

---

## 正常系テストケース

### TC-T03-01: AUTO_STEP=false のとき dispatch_baton が emit_pending を呼ぶ

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-002-AC-1 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `.vckd/config.yaml` に `AUTO_STEP: false` が設定されている |
| **入力** | `dispatch_baton 1 "phase:req" "phase:tds"` |
| **操作** | `emit_pending` のコール数をスパイで記録 |
| **期待結果** | `emit_pending` が 1 回呼ばれ、`emit_baton` は呼ばれない |
| **信頼性** | 🔵 確定 |
| **モック** | `gh` → `VCKD_TEST_MODE=1` で `mock_gh` 実行 |

---

### TC-T03-02: AUTO_STEP=true のとき dispatch_baton が emit_baton を呼ぶ

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-002-AC-2 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `.vckd/config.yaml` に `AUTO_STEP: true` が設定されている |
| **入力** | `dispatch_baton 1 "phase:req" "phase:tds"` |
| **操作** | `emit_baton` のコール数をスパイで記録 |
| **期待結果** | `emit_baton` が 1 回呼ばれ、`emit_pending` は呼ばれない |
| **信頼性** | 🔵 確定 |

---

### TC-T03-03: emit_pending 実行後にラベルが pending:next-phase に変更される

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-001-AC-2 |
| **優先度** | P0 |
| **レイヤー** | integration |
| **前提条件** | Issue #1 に `phase:req` ラベルが付与されている（モック状態） |
| **入力** | `emit_pending 1 "phase:req" "pending:next-phase" "phase:tds"` |
| **操作** | `mock_gh` のラベル変更呼び出し履歴を確認 |
| **期待結果** | `phase:req` が削除され `pending:next-phase` が追加される。また、承認待ちコメント（`⏳ VCKD: 承認待ち`）が Issue に投稿される |
| **信頼性** | 🔵 確定 |

---

### TC-T03-04: emit_baton 実行後にラベルが即座に phase:yyy に変更される

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-001-AC-3 |
| **優先度** | P0 |
| **レイヤー** | integration |
| **前提条件** | Issue #1 に `phase:req` ラベルが付与されている（モック状態） |
| **入力** | `emit_baton 1 "phase:req" "phase:tds"` |
| **操作** | `mock_gh` のラベル変更呼び出し履歴を確認 |
| **期待結果** | `phase:req` が削除され `phase:tds` が追加される。また、バトン発行コメント（`🚀 VCKD: バトン発行（AUTO_STEP）`）が Issue に投稿される |
| **信頼性** | 🔵 確定 |

---

### TC-T03-05: approve 付与後に pending:next-phase が外れ次フェーズラベルが付与される

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-001-AC-4 |
| **優先度** | P0 |
| **レイヤー** | integration |
| **前提条件** | Issue #1 に `pending:next-phase` ラベルがあり、`baton-log.json` に `pending.1.next: "phase:tds"` が記録されている |
| **入力** | `on_label_added 1 "approve"` を呼び出す |
| **操作** | ラベル変更とログ更新を確認 |
| **期待結果** | `approve` と `pending:next-phase` が削除され、`phase:tds` が追加される |
| **信頼性** | 🔵 確定 |

---

### TC-T03-06: emit_blocked 実行後に blocked:xxx ラベルが付与される

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-001-AC-5 |
| **優先度** | P0 |
| **レイヤー** | integration |
| **前提条件** | Issue #1 に `phase:imp` ラベルが付与されている |
| **入力** | `emit_blocked 1 "imp" "テストカバレッジ不足"` |
| **操作** | `mock_gh` のラベル・コメント呼び出しを確認 |
| **期待結果** | `blocked:imp` ラベルが付与され、理由がコメントとして投稿される |
| **信頼性** | 🔵 確定 |

---

### TC-T03-07: check_phase_gate が必須ファイルの存在で PASS を返す

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-003-AC-1 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `IMP->TEST` 遷移で必要な全ファイルが存在する |
| **入力** | `check_phase_gate "IMP" "TEST" "tsumigi-v3-harness"` |
| **期待結果** | 戻り値 0（PASS）、`VCKD_GATE_RESULT=PASS` |
| **信頼性** | 🔵 確定 |

---

### TC-T03-08: harness.enabled=false のとき全関数が early-return する（T08）

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-006-AC-1, REQ-006-AC-2 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `.vckd/config.yaml` に `harness.enabled: false` を設定 |
| **入力** | `dispatch_baton 1 "phase:req" "phase:tds"` を呼び出す |
| **期待結果** | 関数が何もせず exit 0 し、`gh` は一切呼ばれない |
| **信頼性** | 🔵 確定 |

---

### TC-T03-09: get_retry_count と increment_retry_count が正しく動作する（T09）

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | Issue #42 のリトライカウントが 0 |
| **入力** | `increment_retry_count 42` を 2 回呼ぶ |
| **期待結果** | `get_retry_count 42` が 2 を返す |
| **信頼性** | 🔵 確定 |

---

## 異常系テストケース

### TC-T03-10: config.yaml が存在しない場合 AUTO_STEP=false のフォールバック

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-002-AC-3 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `.vckd/config.yaml` が存在しない |
| **操作** | `dispatch_baton 1 "phase:req" "phase:tds"` を呼び出す |
| **期待結果** | `emit_pending` が呼ばれる（エラーで停止しない） |
| **信頼性** | 🔵 確定 |

---

### TC-T03-11: approve 付与されたが pending:next-phase がない場合はエラーコメント

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-001-AC-4 |
| **優先度** | P0 |
| **レイヤー** | integration |
| **前提条件** | Issue #1 に `approve` のみ付与、`pending:next-phase` は存在しない |
| **入力** | `on_label_added 1 "approve"` |
| **期待結果** | エラーコメントが投稿され、ラベルの二重操作は行われない |
| **信頼性** | 🔵 確定 |

---

### TC-T03-12: check_phase_gate が必須ファイル不在で FAIL を返す

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-003-AC-1 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `IMP->TEST` で必要な `specs/tsumigi-v3-harness/IMP.md` が存在しない |
| **入力** | `check_phase_gate "IMP" "TEST" "tsumigi-v3-harness"` |
| **期待結果** | 戻り値 1（FAIL）、`VCKD_GATE_RESULT=FAIL` |
| **信頼性** | 🔵 確定 |

---

### TC-T03-13: check_phase_gate が循環依存で FAIL を返す

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-003-AC-2 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `coherence.json` に 循環依存（A→B→A）が含まれる |
| **入力** | `check_phase_gate "OPS" "CHANGE" "tsumigi-v3-harness"` |
| **期待結果** | `_check_ceg` が循環を検出し FAIL を返す |
| **信頼性** | 🔵 確定 |

---

### TC-T03-14: gh が 3 回失敗後に blocked:escalate が付与される（T09）

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P0 |
| **レイヤー** | integration |
| **前提条件** | `mock_gh` を常に失敗するように設定 |
| **入力** | `emit_baton 1 "phase:req" "phase:tds"` |
| **期待結果** | 3 回リトライ後に `emit_escalate` が呼ばれ `blocked:escalate` ラベルが付与される |
| **信頼性** | 🔵 確定 |

---

### TC-T03-15: baton-log.json が破損している場合バックアップ後に再初期化される

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P1 |
| **レイヤー** | unit |
| **前提条件** | `graph/baton-log.json` に不正な JSON（壊れた内容）が含まれる |
| **入力** | `emit_baton 1 "phase:req" "phase:tds"` を呼び出す |
| **期待結果** | `baton-log.json.bak` に旧ファイルが保存され、`baton-log.json` が再初期化される |
| **信頼性** | 🔵 確定 |

---

## セキュリティテストケース

### TC-T03-SEC-01: VCKD_ISSUE_NUMBER 整数以外で exit 2

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P0 |
| **テスト種別** | 入力バリデーション / シェルインジェクション防止 |
| **攻撃ベクター** | `VCKD_ISSUE_NUMBER="1; cat /etc/passwd"` |
| **期待結果** | bash の `[[ =~ ^[0-9]+$ ]]` チェックで exit 2。`gh` は呼ばれない |
| **信頼性** | 🔵 確定 |

---

## 未カバーケース（手動テスト推奨）

| # | 内容 | 理由 | 推奨対応 |
|---|---|---|---|
| 1 | 実際の GitHub API を使ったラベル変更 | リアルな API トークンが必要 | ステージング環境で確認 |
| 2 | 高並列（複数 Issue 同時バトン）でのロック競合 | 並列テストインフラが必要 | 負荷試験で確認 |
