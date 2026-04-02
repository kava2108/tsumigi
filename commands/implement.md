---
description: IMP をインプットとして実装案・パッチ案を生成します。TDD モードでは失敗テストを先に作成し、最小実装で通過させます。実装後に自動で drift_check を実行します。
allowed-tools: Read, Glob, Grep, Write, Edit, TodoWrite, Bash, AskUserQuestion
argument-hint: "<issue-id> [task-id] [--dry-run] [--mode tdd|direct]"
---

# tsumigi implement

IMP ベースで実装案・パッチ案を生成します。
TDD モード（デフォルト）ではテストファーストで実装を進めます。

# context

issue_id={{issue_id}}
task_id={{task_id}}
dry_run={{dry_run}}
mode={{mode}}
github_issue_number={{github_issue_number}}
imp_file=specs/IMP.md
note_file=specs/note.md
patch_plan_file=specs/implements/{{task_id}}/patch-plan.md
impl_memo_file=specs/implements/{{task_id}}/impl-memo.md
red_phase_file=specs/implements/{{task_id}}/red-phase.md
信頼性評価=[]

# step

- $ARGUMENTS がない場合は「引数に issue-id を指定してください（例: /tsumigi:implement GH-123）」と言って終了する
- $ARGUMENTS を解析する：
  - `--dry-run` フラグを確認し dry_run に設定
  - `--mode tdd` または `--mode direct` を確認し mode に設定（デフォルト: tdd）
  - 最初のトークンを issue_id に設定
  - 2番目のトークン（あれば）を task_id に設定
- context の内容をユーザーに宣言する
- issue_id が `GH-NNN` 形式の場合、NNN を github_issue_number に設定する
- step2 を実行する

## step2: 前提チェック

- `specs/IMP.md` の存在を確認する
  - 存在しない場合：「先に `/tsumigi:imp_generate {{issue_id}}` を実行してください」と言って終了する
- IMP.md を Read する（imp_version と drift_baseline を取得する）
- `specs/note.md` を存在する場合に Read する
- step3 を実行する

## step2b: GitHub Issue への着手通知

issue_id が `GH-NNN` 形式の場合のみ実行する：

- Bash で Issue に着手を通知する：
  ```bash
  gh issue comment {{github_issue_number}} --body "$(cat <<'EOF'
  ## 🚀 tsumigi: implement 開始

  IMP に基づく実装を開始しました。

  | 項目 | 値 |
  |---|---|
  | Issue | #{{github_issue_number}} |
  | 実装モード | {{mode}} |
  | IMP | `specs/IMP.md` |

  完了時に結果を報告します。
  EOF
  )" 2>/dev/null
  ```
- 成功した場合：「GitHub Issue #{{github_issue_number}} に着手通知を投稿しました」と表示する
- 失敗した場合：スキップして続行する（エラーは表示しない）

## step3: 実装モードの確認

- mode が未設定の場合、AskUserQuestion ツールを使って質問する：
  - question: "実装モードを選択してください"
  - header: "実装モード"
  - multiSelect: false
  - options:
    - label: "tdd（推奨）"
      description: "テストファースト: 失敗するテストを書いてから最小実装で通過させる"
    - label: "direct"
      description: "実装ファースト: IMP に従って直接実装する"
  - 選択結果を context の {{mode}} に保存する

## step4: 対象タスクの選択

- task_id が指定されている場合：
  - IMP.md から該当タスクを特定する
  - 存在しない場合はエラーを表示する

- task_id が未指定の場合：
  - IMP.md から未完了のタスク一覧を表示する
  - AskUserQuestion ツールで実装するタスクを選択させる
  - context の {{task_id}} に設定する

## step5: 冪等チェック（既存実装の確認）

- `specs/implements/{{task_id}}/patch-plan.md` が存在するか確認する
  - 存在する場合：
    - ファイルを Read する
    - 「既存の実装計画が見つかりました。差分更新します」と表示する

## step6: コンテキスト収集

- IMP.md から対象タスクの以下を抽出する：
  - 完了条件（EARS 受け入れ基準）
  - 実装手順
  - 変更ファイル一覧
  - テスト戦略

- 対象ファイルの現在の実装を Read する（変更ファイル一覧に基づき）
- 関連テストファイルを Glob/Grep で探索する
- 型定義・インターフェースを Grep で収集する

## step7: TDD モード — Red フェーズ（mode=tdd の場合）

IMP の受け入れ基準をもとに、**失敗するテストコード**を生成する。

- テストファイルのパスを決定する（技術スタックに応じて）：
  - TypeScript/JavaScript: `src/**/__tests__/` または `*.test.ts`
  - Python: `tests/test_*.py`
  - Go: `*_test.go`

- 各 AC（受け入れ基準）に対応するテストケースを作成する：
  - 正常系テスト（AC を満たす場合）
  - 異常系テスト（AC に違反する場合）
  - 境界値テスト（エッジケース）

- `specs/implements/{{task_id}}/red-phase.md` に記録する

- `--dry-run` でない場合：
  - テストファイルを Write する
  - Bash でテストを実行し、**失敗することを確認する**：
    - Jest: `npx jest <テストファイル> 2>&1 | tail -20`
    - pytest: `pytest <テストファイル> -v 2>&1 | tail -20`
    - Go test: `go test ./<パッケージ> -run <テスト名> 2>&1 | tail -20`
  - テストが失敗しない場合は警告を表示する（既に実装済みの可能性）

## step8: 実装案の生成

IMP のタスク詳細に従って実装案を生成する。

**実装原則**:
- TDD モード: テストを通過させる最小限の実装のみ生成する
- direct モード: IMP の実装手順を忠実に実装する
- 既存コードの規約・パターンを踏襲する

**変更のトレーサビリティ**:
- 各変更箇所に IMP のタスク ID・AC 番号をコメントで記載する
  例: `// IMP GH-123 TASK-0001 AC-001`

## step9: パッチ計画の記録

`specs/implements/{{task_id}}/patch-plan.md` を生成する。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/patch-plan-template.md`
  - `.claude/commands/tsumigi/templates/patch-plan-template.md`
- テンプレートの変数を置換し、実装内容を埋めて `specs/implements/{{task_id}}/patch-plan.md` を Write する

## step10: 実装判断の記録

`specs/implements/{{task_id}}/impl-memo.md` を生成する。

実装中に発生したトレードオフ・判断・代替案の検討を記録する。
将来のレビュアーや自分が「なぜこう実装したか」を理解できるようにする。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/impl-memo-template.md`
  - `.claude/commands/tsumigi/templates/impl-memo-template.md`
- テンプレートの変数を置換し、実装判断を記録して `specs/implements/{{task_id}}/impl-memo.md` を Write する

## step11: TDD モード — Green フェーズ確認（mode=tdd の場合）

- `--dry-run` でない場合：
  - 実装を Write する
  - Bash でテストを実行し、**通過することを確認する**
  - 通過しない場合は修正を加え、再実行する（最大 3 回）
  - 3 回で通過しない場合はユーザーに状況を報告し、手動修正を依頼する

## step12: 自動 drift_check の実行

実装完了後、軽量な drift チェックを実行する：

- IMP.md の受け入れ基準と patch-plan.md の変更内容を照合する
- 未対応の AC がある場合は警告を表示する
- drift スコアを簡易算出して表示する

```
🔍 自動 drift チェック結果:
  対応 AC: N/N 件
  軽量 drift スコア: N/100
  ⚠️ 未対応: AC-XXX "..."

詳細確認: /tsumigi:drift_check {{issue_id}}
```

## step13: 完了通知

- 以下を表示する：
  ```
  ✅ implement 完了: {{issue_id}} / {{task_id}}

  生成ファイル:
    specs/implements/{{task_id}}/patch-plan.md
    specs/implements/{{task_id}}/impl-memo.md
    specs/implements/{{task_id}}/red-phase.md（TDD 時）

  次のステップ:
    テスト生成:      /tsumigi:test {{issue_id}} {{task_id}}
    乖離確認:        /tsumigi:drift_check {{issue_id}}
    全タスク確認:    /tsumigi:sync {{issue_id}} --report-only
  ```

- TodoWrite ツールでタスクを完了にマークする

## step14: GitHub Issue への完了通知

issue_id が `GH-NNN` 形式の場合のみ実行する：

- Bash で Issue に完了を通知する：
  ```bash
  gh issue comment {{github_issue_number}} --body "$(cat <<'EOF'
  ## ✅ tsumigi: implement 完了

  実装が完了しました。

  | 成果物 | パス |
  |---|---|
  | パッチ計画 | `specs/implements/{{task_id}}/patch-plan.md` |
  | 実装メモ | `specs/implements/{{task_id}}/impl-memo.md` |
  | Red フェーズ（TDD） | `specs/implements/{{task_id}}/red-phase.md` |

  **次のステップ**: `/tsumigi:test {{issue_id}} {{task_id}}`
  EOF
  )" 2>/dev/null
  ```
- 成功した場合：「GitHub Issue #{{github_issue_number}} に完了通知を投稿しました」と表示する
- 失敗した場合：スキップする（エラーは表示しない）
