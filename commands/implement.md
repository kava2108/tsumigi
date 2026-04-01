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
imp_file=docs/imps/{{issue_id}}/IMP.md
note_file=docs/issues/{{issue_id}}/note.md
patch_plan_file=docs/implements/{{issue_id}}/{{task_id}}/patch-plan.md
impl_memo_file=docs/implements/{{issue_id}}/{{task_id}}/impl-memo.md
red_phase_file=docs/implements/{{issue_id}}/{{task_id}}/red-phase.md
信頼性評価=[]

# step

- $ARGUMENTS がない場合は「引数に issue-id を指定してください（例: /tsumigi:implement GH-123）」と言って終了する
- $ARGUMENTS を解析する：
  - `--dry-run` フラグを確認し dry_run に設定
  - `--mode tdd` または `--mode direct` を確認し mode に設定（デフォルト: tdd）
  - 最初のトークンを issue_id に設定
  - 2番目のトークン（あれば）を task_id に設定
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 前提チェック

- `docs/imps/{{issue_id}}/IMP.md` の存在を確認する
  - 存在しない場合：「先に `/tsumigi:imp_generate {{issue_id}}` を実行してください」と言って終了する
- IMP.md を Read する（imp_version と drift_baseline を取得する）
- `docs/issues/{{issue_id}}/note.md` を存在する場合に Read する
- step3 を実行する

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

- `docs/implements/{{issue_id}}/{{task_id}}/patch-plan.md` が存在するか確認する
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

- `docs/implements/{{issue_id}}/{{task_id}}/red-phase.md` に記録する

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

`docs/implements/{{issue_id}}/{{task_id}}/patch-plan.md` を生成する。

<patch_plan_template>
---
issue_id: {{issue_id}}
task_id: {{task_id}}
imp_version: {{imp_version}}
mode: {{mode}}
dry_run: {{dry_run}}
created_at: {{ISO8601}}
updated_at: {{ISO8601}}
---

# パッチ計画: {{issue_id}} / {{task_id}}

## 変更対象ファイル

| ファイルパス | 変更種別 | 変更概要 | AC 対応 |
|---|---|---|---|
| | 新規/変更/削除 | | AC-001, AC-002 |

## 変更内容サマリー

{{各ファイルの変更点を箇条書き}}

## テストファイル

| テストファイル | カバーする AC | 実行コマンド |
|---|---|---|
| | | |

## 実装時の判断事項

{{step10 で記録する実装判断}}

## 完了チェックリスト

- [ ] 全 AC に対応する実装が完了した
- [ ] TDD Red フェーズのテストが全て通過した
- [ ] 既存テストが破壊されていない
- [ ] IMP の変更ファイル一覧と実際の変更が一致している
</patch_plan_template>

## step10: 実装判断の記録

`docs/implements/{{issue_id}}/{{task_id}}/impl-memo.md` を生成する。

実装中に発生したトレードオフ・判断・代替案の検討を記録する。
将来のレビュアーや自分が「なぜこう実装したか」を理解できるようにする。

<impl_memo_template>
---
issue_id: {{issue_id}}
task_id: {{task_id}}
created_at: {{ISO8601}}
---

# 実装判断メモ: {{issue_id}} / {{task_id}}

## 採用したアプローチ

{{実装方針の説明}}

## 検討した代替案

| 代替案 | 不採用の理由 |
|---|---|
| | |

## 既存コードへの影響

{{既存実装への影響・注意点}}

## TODO・未解決事項

- [ ] {{次のタスク・残課題}}
</impl_memo_template>

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
    docs/implements/{{issue_id}}/{{task_id}}/patch-plan.md
    docs/implements/{{issue_id}}/{{task_id}}/impl-memo.md
    docs/implements/{{issue_id}}/{{task_id}}/red-phase.md（TDD 時）

  次のステップ:
    テスト生成:      /tsumigi:test {{issue_id}} {{task_id}}
    乖離確認:        /tsumigi:drift_check {{issue_id}}
    全タスク確認:    /tsumigi:sync {{issue_id}} --report-only
  ```

- TodoWrite ツールでタスクを完了にマークする
