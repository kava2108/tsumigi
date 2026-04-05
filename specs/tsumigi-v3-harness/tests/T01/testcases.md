---
tsumigi:
  node_id: "test:tsumigi-v3-harness:T01"
  artifact_type: "testcases"
  phase: "TEST"
  issue_id: "tsumigi-v3-harness"
  task_id: "T01"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "test:tsumigi-v3-harness:T01"
  depends_on:
    - id: "impl:tsumigi-v3-harness:T01"
      relation: "verifies"
      confidence: 1.0
      required: true
    - id: "imp:tsumigi-v3-harness"
      relation: "derives_from"
      confidence: 0.95
      required: true
  band: "Green"
---

# テストケースマトリクス: tsumigi-v3-harness / T01

**対象タスク**: T01 — Baton Infrastructure セットアップ  
**生成日**: 2026-04-05  
**フォーカス**: unit, integration, e2e, security

---

## カバレッジサマリー

| AC | 正常系 | 異常系 | 境界値 | セキュリティ | 合計 | カバー状況 |
|---|---|---|---|---|---|---|
| REQ-001-AC-1 | 1 | 1 | 0 | 0 | 2 | ✅ |
| REQ-002-AC-3 | 1 | 1 | 0 | 0 | 2 | ✅ |
| REQ-004-AC-2 | 1 | 1 | 1 | 0 | 3 | ✅ |

カバレッジ率: 3/3 AC = **100%**

---

## 正常系テストケース

### TC-T01-01: phase:req ラベル付与 → RequirementsAgent 起動確認

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-001-AC-1 |
| **優先度** | P0 |
| **レイヤー** | integration |
| **前提条件** | `install --harness` 済み、`.vckd/config.yaml` が存在する（`AUTO_STEP=false`） |
| **入力** | GitHub Issue #N に `phase:req` ラベルを付与 |
| **操作** | `gh issue edit $N --add-label "phase:req"` を実行し、GitHub Actions の起動を確認 |
| **期待結果** | `.github/workflows/vckd-pipeline.yml` がトリガーされ、RequirementsAgent が起動する |
| **信頼性** | 🔵 確定 |
| **モック** | `gh` CLI は VCKD_TEST_MODE=1 でモック置換 |

---

### TC-T01-02: emit_baton 実行後に baton-log.json に遷移が記録される

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-004-AC-2 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `graph/baton-log.json` が初期化済み（`{"version":"1.0.0","transitions":[],"pending":{}}`） |
| **入力** | `emit_baton 42 "phase:req" "phase:tds"` を呼び出す |
| **操作** | `.tsumigi/lib/phase-gate.sh` の `emit_baton` 関数を実行（VCKD_TEST_MODE=1） |
| **期待結果** | `graph/baton-log.json` の `transitions` 配列に `{issue: "42", from: "phase:req", to: "phase:tds", mode: "auto"}` が追記される |
| **信頼性** | 🔵 確定 |

---

### TC-T01-03: AUTO_STEP=false の場合 emit_pending が呼ばれる

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-002-AC-3 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `.vckd/config.yaml` に `AUTO_STEP: false` が設定されている |
| **入力** | `dispatch_baton 42 "phase:req" "phase:tds"` を呼び出す |
| **操作** | `emit_baton` ではなく `emit_pending` が呼ばれることをスパイで確認 |
| **期待結果** | `graph/baton-log.json` の `pending.42` に `next: "phase:tds"` が記録される |
| **信頼性** | 🔵 確定 |

---

## 異常系テストケース

### TC-T01-04: config.yaml が存在しない場合 AUTO_STEP=false のフォールバック

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-002-AC-3 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `.vckd/config.yaml` が存在しない（削除状態） |
| **入力** | `dispatch_baton 42 "phase:req" "phase:tds"` を呼び出す |
| **操作** | `dispatch_baton` を実行して動作確認 |
| **期待結果** | `AUTO_STEP=false` にフォールバックし、`emit_pending` が呼ばれる（エラーで停止しない） |
| **信頼性** | 🔵 確定 |

---

### TC-T01-05: settings.json に既存フックがある場合、重複追加されない

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `.claude/settings.json` に PostToolUse フック `post-tool-use.sh` が既に存在する |
| **入力** | `install.md --harness` ステップを再実行 |
| **操作** | install コマンドの Step8（hooks マージ処理）をテスト |
| **期待結果** | settings.json の `PostToolUse` 配列に `post-tool-use.sh` が 1 件のみ存在する（重複なし） |
| **信頼性** | 🔵 確定 |

---

### TC-T01-06: graph/ ディレクトリが存在しない場合も install --harness が完了する

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P1 |
| **レイヤー** | integration |
| **前提条件** | `graph/` ディレクトリが存在しない |
| **入力** | `install --harness` を実行 |
| **操作** | `install.md` の全ステップを実行 |
| **期待結果** | `graph/` が自動作成され、`baton-log.json` と `coherence.json` が初期化される |
| **信頼性** | 🔵 確定 |

---

## 境界値テストケース

### TC-T01-07: baton-log.json が大量の transitions（1000 件）でも正常追記できる

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-004-AC-2 |
| **優先度** | P2 |
| **レイヤー** | unit |
| **前提条件** | `graph/baton-log.json` の `transitions` 配列に 1000 件のダミーエントリが存在する |
| **入力** | `emit_baton 1 "phase:req" "phase:tds"` を呼び出す |
| **操作** | jq によるファイル更新処理を実行 |
| **期待結果** | 1001 件目が正常に追加され、ファイルが有効な JSON として保存される |
| **信頼性** | 🟡 推定 |

---

## セキュリティテストケース

### TC-T01-SEC-01: VCKD_ISSUE_NUMBER に不正値が渡された場合の拒否

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P0 |
| **テスト種別** | 入力バリデーション |
| **攻撃ベクター** | `VCKD_ISSUE_NUMBER="; rm -rf /"` などのシェルインジェクション文字列 |
| **操作** | `post-tool-use.sh` を実行し VCKD_ISSUE_NUMBER に不正値をセット |
| **期待結果** | `[[ "$var" =~ ^[0-9]+$ ]]` バリデーションで exit 2 となり、`gh` コマンドは实行されない |
| **信頼性** | 🔵 確定 |

---

## 未カバーケース（手動テスト推奨）

| # | 内容 | 理由 | 推奨対応 |
|---|---|---|---|
| 1 | GitHub Labels が既に存在する本物のリポジトリで `gh label create` をスキップできるか | 実 GitHub API 実行が必要 | ステージング環境で手動確認 |
| 2 | GitHub Actions 権限なしリポジトリでの `install --harness` | 権限依存で自動化困難 | 手動確認 |
