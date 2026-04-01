---
description: IMP と実装からテスト観点・テストケースマトリクス・検証方針を生成します。正常系/異常系/境界値/セキュリティを網羅したマトリクスを出力し、--exec で実際にテストを実行します。
allowed-tools: Read, Glob, Grep, Write, Edit, TodoWrite, Bash, AskUserQuestion
argument-hint: "<issue-id> [task-id] [--exec] [--focus unit|integration|e2e|security|all]"
---

# tsumigi test

テストケースマトリクスと検証方針を生成します。
IMP の受け入れ基準に対してテストカバレッジを保証します。

# context

issue_id={{issue_id}}
task_id={{task_id}}
exec={{exec}}
focus={{focus}}
imp_file=docs/imps/{{issue_id}}/IMP.md
note_file=docs/issues/{{issue_id}}/note.md
patch_plan_file=docs/implements/{{issue_id}}/{{task_id}}/patch-plan.md
testcases_file=docs/tests/{{issue_id}}/{{task_id}}/testcases.md
test_plan_file=docs/tests/{{issue_id}}/{{task_id}}/test-plan.md
test_results_file=docs/tests/{{issue_id}}/{{task_id}}/test-results.md
信頼性評価=[]

# step

- $ARGUMENTS がない場合は「引数に issue-id を指定してください（例: /tsumigi:test GH-123）」と言って終了する
- $ARGUMENTS を解析する：
  - `--exec` フラグを確認し exec に設定
  - `--focus` の後の値を focus に設定（デフォルト: all）
  - 最初のトークンを issue_id に設定
  - 2番目のトークン（あれば）を task_id に設定
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 前提チェック

- `docs/imps/{{issue_id}}/IMP.md` の存在を確認する
  - 存在しない場合：「先に `/tsumigi:imp_generate {{issue_id}}` を実行してください」と言って終了する
- IMP.md を Read する
- `docs/issues/{{issue_id}}/note.md` を存在する場合に Read する
- `docs/implements/{{issue_id}}/{{task_id}}/patch-plan.md` を存在する場合に Read する
- 既存のテストファイルを Glob で探索する（`**/*.test.ts`, `tests/**/*.py` 等）
- step3 を実行する

## step3: フォーカス確認

- focus が未設定の場合、AskUserQuestion ツールを使って質問する：
  - question: "テストの重点領域を選択してください"
  - header: "テストフォーカス"
  - multiSelect: true
  - options:
    - label: "unit（単体テスト）" — description: "関数・メソッドレベルの動作確認"
    - label: "integration（統合テスト）" — description: "コンポーネント間・API レベルの動作確認"
    - label: "e2e（E2Eテスト）" — description: "ユーザーシナリオレベルの動作確認"
    - label: "security（セキュリティテスト）" — description: "認証認可・脆弱性の検証"
    - label: "all（推奨）" — description: "全レベルを網羅"
  - 選択結果を context の {{focus}} に保存する

## step4: IMP からの受け入れ基準抽出

IMP.md から以下を抽出する：
- 全受け入れ基準（AC-XXX 形式）
- テスト戦略セクション
- 非機能要件

各 AC に対して、テストケースが必要かどうかを判断する（P0/P1/P2 で優先度付け）。

## step5: テストケースマトリクスの生成

`docs/tests/{{issue_id}}/{{task_id}}/testcases.md` を生成する（既存の場合は差分マージ）。

<testcases_template>
---
issue_id: {{issue_id}}
task_id: {{task_id}}
imp_version: {{imp_version}}
focus: {{focus}}
total_cases: N
generated_at: {{ISO8601}}
---

# テストケースマトリクス: {{issue_id}} / {{task_id}}

## カバレッジサマリー

| AC | 正常系 | 異常系 | 境界値 | セキュリティ | 合計 | カバー状況 |
|---|---|---|---|---|---|---|
| AC-001 | 1 | 2 | 1 | 0 | 4 | ✅ |
| AC-002 | 1 | 1 | 2 | 1 | 5 | ✅ |

カバレッジ率: N/N AC = 100%

---

## 正常系テストケース

### TC-001: {{テスト名}}

| 項目 | 内容 |
|---|---|
| **対応 AC** | AC-001 |
| **優先度** | P0 |
| **前提条件** | {{テスト実行前の状態}} |
| **入力** | {{テスト入力データ}} |
| **操作** | {{実行する操作}} |
| **期待結果** | {{期待される出力・状態}} |
| **信頼性** | 🔵確定 |

---

## 異常系テストケース

### TC-XXX: {{テスト名}}

（同形式）

---

## 境界値テストケース

### TC-XXX: {{テスト名}}

（同形式）

---

## セキュリティテストケース
<!-- focus に security が含まれる場合のみ -->

### TC-SEC-001: 認証なしアクセスの拒否

| 項目 | 内容 |
|---|---|
| **対応 AC** | AC-XXX |
| **優先度** | P0 |
| **テスト種別** | 認証・認可 |
| **攻撃ベクター** | 未認証リクエスト |
| **期待結果** | HTTP 401 が返る |

---

## パフォーマンステストケース
<!-- IMP に性能要件が含まれる場合 -->

### TC-PERF-001: {{テスト名}}

| 項目 | 内容 |
|---|---|
| **対応要件** | レスポンスタイム < N ms |
| **負荷条件** | 同時 N リクエスト |
| **期待結果** | 95パーセンタイルで N ms 以内 |

---

## 未カバーケース（手動テスト推奨）

| # | 内容 | 理由 | 推奨対応 |
|---|---|---|---|
| | | 自動化困難 | 手動確認 |
</testcases_template>

## step6: テスト計画書の生成

`docs/tests/{{issue_id}}/{{task_id}}/test-plan.md` を生成する。

<test_plan_template>
---
issue_id: {{issue_id}}
task_id: {{task_id}}
generated_at: {{ISO8601}}
---

# テスト計画書: {{issue_id}} / {{task_id}}

## テスト方針

{{IMP のテスト戦略セクションから転写・精緻化}}

## テスト環境

| 項目 | 内容 |
|---|---|
| **言語** | |
| **テストフレームワーク** | |
| **実行コマンド** | `npm test` / `pytest` / `go test ./...` 等 |
| **テストデータ** | |

## テスト優先度

| 優先度 | 条件 | 件数 |
|---|---|---|
| P0 | CI で必ず通過すべきテスト | N |
| P1 | リリース前に確認すべきテスト | N |
| P2 | 余裕があれば確認するテスト | N |

## 除外事項

| 除外内容 | 理由 |
|---|---|
| | |

## 合格基準

- 全 P0 テストが通過すること
- テストカバレッジが X% 以上であること
- セキュリティテストに合格すること
</test_plan_template>

## step7: テスト実行（--exec が指定されている場合）

- 技術スタックに応じてテスト実行コマンドを構築する
- Bash でテストを実行する：

  ```bash
  # Jest の例
  npx jest --coverage 2>&1

  # pytest の例
  pytest --cov=src --cov-report=term-missing 2>&1

  # Go の例
  go test ./... -v 2>&1
  ```

- 結果を `docs/tests/{{issue_id}}/{{task_id}}/test-results.md` に記録する

<test_results_template>
---
issue_id: {{issue_id}}
task_id: {{task_id}}
executed_at: {{ISO8601}}
result: PASS/FAIL
---

# テスト実行結果: {{issue_id}} / {{task_id}}

## サマリー

| 項目 | 結果 |
|---|---|
| **実行日時** | {{ISO8601}} |
| **総テスト数** | N |
| **通過** | N |
| **失敗** | N |
| **スキップ** | N |
| **カバレッジ** | N% |
| **実行時間** | Ns |

## 失敗したテスト

| テスト名 | エラー内容 | 対応状況 |
|---|---|---|
| | | 未対応/修正中/解決済 |

## カバレッジ詳細

（テストランナーの出力をそのまま貼り付け）
</test_results_template>

## step8: カバレッジギャップの分析

IMP の受け入れ基準と生成したテストケースを照合する：
- カバーされていない AC を特定する
- 未カバーの理由を分析する（技術的制約・スコープ外・優先度低）

```
📊 テストカバレッジサマリー:
  IMP 受け入れ基準: N 件
  テストケース総数: N 件
  カバー済み AC: N/N 件

  ✅ AC-001: TC-001, TC-002, TC-003 でカバー
  ⚠️ AC-004: 境界値テストが未作成
  ❌ AC-007: テストケースが存在しない（要対応）
```

## step9: 完了通知

- 以下を表示する：
  ```
  ✅ test 完了: {{issue_id}} / {{task_id}}

  生成ファイル:
    docs/tests/{{issue_id}}/{{task_id}}/testcases.md  (N ケース)
    docs/tests/{{issue_id}}/{{task_id}}/test-plan.md
    docs/tests/{{issue_id}}/{{task_id}}/test-results.md（--exec 時）

  カバレッジ: N/N AC = N%

  次のステップ:
    逆仕様生成:    /tsumigi:rev {{issue_id}}
    乖離確認:      /tsumigi:drift_check {{issue_id}}
  ```

- カバレッジが 100% 未満の場合は警告を表示する
- TodoWrite ツールでタスクを完了にマークする
