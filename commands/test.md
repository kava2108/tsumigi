---
description: IMP と実装からテスト観点・テストケースマトリクス・検証方針を生成します。正常系/異常系/境界値/セキュリティを網羅したマトリクスを出力し、--exec で実際にテストを実行します。
allowed-tools: Read, Glob, Grep, Write, Edit, TodoWrite, Bash, AskUserQuestion
argument-hint: "[issue-id] [task-id] [--exec] [--focus unit|integration|e2e|security|all]"
---

# tsumigi test

テストケースマトリクスと検証方針を生成します。
IMP の受け入れ基準に対してテストカバレッジを保証します。

# context

issue_id={{issue_id}}
task_id={{task_id}}
exec={{exec}}
focus={{focus}}
imp_file=specs/{{issue_id}}/IMP.md
note_file=specs/{{issue_id}}/note.md
patch_plan_file=specs/{{issue_id}}/implements/{{task_id}}/patch-plan.md
testcases_file=specs/{{issue_id}}/tests/{{task_id}}/testcases.md
test_plan_file=specs/{{issue_id}}/tests/{{task_id}}/test-plan.md
test_results_file=specs/{{issue_id}}/tests/{{task_id}}/test-results.md
信頼性評価=[]

# step

- $ARGUMENTS がない場合は「引数に issue-id を指定してください（例: /tsumigi:test 001-feature-name）」と言って終了する
- $ARGUMENTS を解析する：
  - `--exec` フラグを確認し exec に設定
  - `--focus` の後の値を focus に設定（デフォルト: all）
  - 最初のトークンを issue_id に設定
  - 2番目のトークン（あれば）を task_id に設定
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 前提チェック

- `specs/{{issue_id}}/IMP.md` の存在を確認する
  - 存在しない場合：「先に `/tsumigi:imp_generate {{issue_id}}` を実行してください」と言って終了する
- IMP.md を Read する
- `specs/{{issue_id}}/note.md` を存在する場合に Read する
- `specs/{{issue_id}}/implements/{{task_id}}/patch-plan.md` を存在する場合に Read する
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

`specs/{{issue_id}}/tests/{{task_id}}/testcases.md` を生成する（既存の場合は差分マージ）。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/testcases-template.md`
  - `.claude/commands/tsumigi/templates/testcases-template.md`
- テンプレートの変数を置換し、IMP から抽出した受け入れ基準に基づくテストケースを埋めて Write する
- `{{focus}}` に含まれないテスト種別のセクションは削除する

## step6: テスト計画書の生成

`specs/{{issue_id}}/tests/{{task_id}}/test-plan.md` を生成する。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/test-plan-template.md`
  - `.claude/commands/tsumigi/templates/test-plan-template.md`
- テンプレートの変数を置換し、IMP のテスト戦略を反映して Write する

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

- 結果を `specs/{{issue_id}}/tests/{{task_id}}/test-results.md` に記録する
- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/test-results-template.md`
  - `.claude/commands/tsumigi/templates/test-results-template.md`
- テンプレートの変数を置換し、実行結果を埋めて Write する

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
    specs/{{issue_id}}/tests/{{task_id}}/testcases.md  (N ケース)
    specs/{{issue_id}}/tests/{{task_id}}/test-plan.md
    specs/{{issue_id}}/tests/{{task_id}}/test-results.md（--exec 時）

  カバレッジ: N/N AC = N%

  次のステップ:
    逆仕様生成:    /tsumigi:rev {{issue_id}}
    乖離確認:      /tsumigi:drift_check {{issue_id}}
  ```

- カバレッジが 100% 未満の場合は警告を表示する
- TodoWrite ツールでタスクを完了にマークする
