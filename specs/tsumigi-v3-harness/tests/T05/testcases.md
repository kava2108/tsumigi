---
tsumigi:
  node_id: "test:tsumigi-v3-harness:T05"
  artifact_type: "testcases"
  phase: "TEST"
  issue_id: "tsumigi-v3-harness"
  task_id: "T05"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "test:tsumigi-v3-harness:T05"
  depends_on:
    - id: "impl:tsumigi-v3-harness:T05"
      relation: "verifies"
      confidence: 1.0
      required: true
    - id: "imp:tsumigi-v3-harness"
      relation: "derives_from"
      confidence: 0.95
      required: true
  band: "Green"
---

# テストケースマトリクス: tsumigi-v3-harness / T05

**対象タスク**: T05 — GitHub Actions 統合  
**生成日**: 2026-04-05  
**フォーカス**: unit, integration, e2e

---

## カバレッジサマリー

| AC | 正常系 | 異常系 | 境界値 | セキュリティ | 合計 | カバー状況 |
|---|---|---|---|---|---|---|
| REQ-001-AC-1 | 1 | 0 | 0 | 0 | 1 | ✅ |
| — (Security) | 0 | 0 | 0 | 2 | 2 | ✅ |

カバレッジ率: 1/1 AC = **100%** / セキュリティ TC: 2 件（D2-01 対応）

---

## 正常系テストケース

### TC-T05-01: phase:req 付与 → Actions 起動 → RequirementsAgent が実行される

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-001-AC-1 |
| **優先度** | P0 |
| **レイヤー** | e2e |
| **前提条件** | `ANTHROPIC_API_KEY` が GitHub Secrets に設定されている |
| **入力** | Issue #N に `phase:req` ラベルを付与 |
| **操作** | GitHub Actions の実行ログを確認 |
| **期待結果** | `vckd-pipeline.yml` の `route-agent` / `run-phase-agent` ジョブが起動し、`requirements-agent.md` が system prompt として使用される |
| **信頼性** | 🟡 推定（実 GitHub Actions 依存） |

---

### TC-T05-02: approve ラベルで on_label_added.sh が呼ばれる

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P0 |
| **レイヤー** | integration |
| **前提条件** | Issue に `pending:next-phase` が付与されている |
| **入力** | `approve` ラベルを付与 |
| **操作** | ワークフローのルーティング分岐を確認 |
| **期待結果** | `approve` ラベルが付与されたとき、Claude Code ではなく `on_label_added.sh` が直接実行される |
| **信頼性** | 🔵 確定 |

---

### TC-T05-03: ルーティングテーブルの全 6 フェーズが対応エージェントを呼ぶ

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-001-AC-1 |
| **優先度** | P0 |
| **レイヤー** | integration |
| **前提条件** | ワークフローファイルが正しく配置されている |
| **入力** | 各 `phase:*` ラベル（req / tds / imp / test / ops / change）を 1 つずつ検証 |
| **操作** | `vckd-pipeline.yml` のルーティングロジックを静的解析（`act` または `actionlint`） |
| **期待結果** | 全 6 ラベルが対応エージェントファイルにマッピングされている |
| **信頼性** | 🔵 確定 |

---

## 異常系テストケース

### TC-T05-04: ANTHROPIC_API_KEY 未設定で失敗せずに通知が出る

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `secrets.ANTHROPIC_API_KEY` が設定されていない（または空） |
| **入力** | ワークフローのキーチェックステップを実行 |
| **期待結果** | ジョブが `skip` 状態で終了し、Issue コメントで「APIキーが未設定です」と通知される（エラーで終わらない） |
| **信頼性** | 🔵 確定 |

---

### TC-T05-05: 同一 Issue への並列実行が防止される

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P0 |
| **レイヤー** | integration |
| **前提条件** | Issue #1 に対してほぼ同時に 2 つのラベルが付与される |
| **操作** | `concurrency` グループ設定を確認（`vckd-issue-${{ github.event.issue.number }}`） |
| **期待結果** | 2 つ目の実行が `cancel-in-progress: false` の待機状態になり、1 つ目の完了後に実行される |
| **信頼性** | 🔵 確定（ワークフロー設定で保証） |

---

## 境界値テストケース

### TC-T05-06: phase:done ラベルではワークフローが起動しない

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P1 |
| **レイヤー** | unit |
| **前提条件** | ワークフローのフィルタ条件を確認 |
| **入力** | `phase:done` ラベルを付与 |
| **期待結果** | `route-agent` ジョブの `if` 条件が false となり、実行されない |
| **信頼性** | 🔵 確定 |

---
## セキュリティテストケース

### TC-T05-SEC-01: ラベル名に shell metacharacter が含まれる場合のコマンドインジェクション防止

| 項目 | 内容 |
|---|---|
| **対応 AC** | — (D2-01: Adversary 指摘) |
| **優先度** | P0 |
| **レイヤー** | security |
| **脅威モデル** | 攻撃者が GitHub ラベル名に `phase:req; rm -rf /` や `` phase:req`id` `` 等の shell metacharacter を含むラベルを作成し、`vckd-pipeline.yml` の `case` ステートメントで不正コマンド実行を試みる |
| **前提条件** | GitHub ラベル名: `phase:req; echo INJECTED` |
| **入力** | 上記ラベルを Issue に付与して Actions を起動 |
| **期待結果** | `case "$LABEL" in` の `case` 構文マッチが失敗（マッチするパターンなし）し、コマンドインジェクションが実行されない。ルーティングの `*` ブランチが起動もドロップもしない安全なフォールバック動作になる |
| **検証方法** | 1) `actionlint` で `${{ github.event.label.name }}` をシェル展開するステップのリントエラー確認 2) `LABEL` 変数のクォートが `"$LABEL"` 形式であることを静的解析で確認 3) GitHub API のラベル名の文字種制限（`;` `\`` `$` はラベル名は使用不可）を確認 |
| **信頼性** | 🔵 確定（GitHub ラベルは制御文字が制限されるため実際のインジェクションリスクは低い。クォートの存在を静的確認で検証する） |

---

### TC-T05-SEC-02: ラベル名が 256 文字超過（長さ境界値）でもワークフローが安全に完了する

| 項目 | 内容 |
|---|---|
| **対応 AC** | — (D2-01: Adversary 指摘) |
| **優先度** | P1 |
| **レイヤー** | security |
| **脅威モデル** | ラベル名に極端に長い文字列（256 文字超）を入力することで `case` 文パターンマッチや環境変数展開を利用して倒壊を試みる |
| **前提条件** | 256 文字以上のラベル名（GitHub は最大 50 文字だが API 経由で試なる |
| **入力** | `phase:req` + `a` × 250 のラベル名 |
| **期待結果** | `case` の `*` （デフォルト）ブランチが実行され、非零退出コードや不正コマンドが実行されない |
| **検証方法** | ワークフローのルーティングステップに入力長バリデーション（`echo "$LABEL" | wc -c` で間接確認）を追加することを推奨 |
| **信頼性** | 🔵 確定（GitHub 自体のラベル名上限が 50 文字のため実驕は限定的。ワークフローの安全性は静的解析で確認） |

---
## 未カバーケース（手動テスト推奨）

| # | 内容 | 理由 | 推奨対応 |
|---|---|---|---|
| 1 | Actions の実行時間が 6h を超えた場合のジョブ分割 | 長時間実行は CI で再現困難 | 本番監視で対応 |
| 2 | GitHub Actions の課金制限に達した場合の動作 | 課金制限は環境依存 | 本番監視で対応 |
