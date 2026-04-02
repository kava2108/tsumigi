---
description: Issue/IMP/実装/ドキュメントの整合性を確認・修正します。全成果物の整合性スコアを0-100で算出し、自動修正可能な乖離を修正します。--fixで自動修正、--report-onlyでレポートのみ生成します。
allowed-tools: Read, Glob, Grep, Write, Edit, TodoWrite, AskUserQuestion
argument-hint: "<issue-id> [--fix] [--report-only]"
---

# tsumigi sync

Issue/IMP/実装/ドキュメントの整合性を確認します。
全成果物の整合性スコアを算出し、不整合を可視化します。
冪等設計のため、何度実行しても安全です。

# context

issue_id={{issue_id}}
fix_mode={{fix_mode}}
report_only={{report_only}}
sync_report_file=specs/sync-report.md
sync_actions_file=specs/sync-actions.md
consistency_score={{consistency_score}}

# step

- $ARGUMENTS がない場合は「引数に issue-id を指定してください（例: /tsumigi:sync GH-123）」と言って終了する
- $ARGUMENTS を解析する：
  - `--fix` フラグを確認し fix_mode に設定
  - `--report-only` フラグを確認し report_only に設定
  - 最初のトークンを issue_id に設定
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 全成果物の収集

以下のファイルをすべて読み込む（存在するもののみ）：

**Issue 成果物**:
- `specs/issue-struct.md`
- `specs/tasks.md`
- `specs/note.md`

**IMP 成果物**:
- `specs/IMP.md`
- `specs/IMP-checklist.md`
- `specs/IMP-risks.md`

**実装成果物**:
- `specs/implements/*/patch-plan.md`（全タスク）
- `specs/implements/*/impl-memo.md`（全タスク）

**テスト成果物**:
- `specs/tests/*/testcases.md`（全タスク）
- `specs/tests/*/test-plan.md`（全タスク）
- `specs/tests/*/test-results.md`（存在する場合）

**逆仕様成果物**:
- `specs/rev-spec.md`
- `specs/rev-api.md`
- `specs/rev-schema.md`

**過去の同期レポート**:
- `specs/sync-report.md`（存在する場合）

## step3: 整合性チェックマトリクスの実行

5 つの整合性チェックを実行し、各チェックを Pass/Warn/Fail で評価する：

**チェック 1: Issue ↔ IMP の整合性（20点満点）**
- issue-struct.md の受け入れ基準が IMP.md に全て反映されているか
- issue-struct.md のタスク一覧が IMP.md のタスク詳細と対応しているか
- issue_id が一致しているか
- 非機能要件が IMP に反映されているか

**チェック 2: IMP ↔ 実装の整合性（25点満点）**
- IMP のタスク一覧が全て patch-plan.md に対応しているか
- IMP の変更ファイル一覧と実際の変更が一致しているか（Glob/Grep で確認）
- IMP の imp_version が patch-plan.md と一致しているか
- TDD モードの場合、red-phase.md が存在するか

**チェック 3: IMP ↔ テストの整合性（25点満点）**
- IMP のテスト戦略が testcases.md に実装されているか
- 全受け入れ基準に対応するテストケースが存在するか
- テスト計画書の合格基準が明確か

**チェック 4: 実装 ↔ 逆仕様の整合性（15点満点）**
- rev-spec.md / rev-api.md に IMP との⚠️差分フラグがないか
- 逆仕様が実際の実装と一致しているか（実装ファイルを Read して確認）

**チェック 5: 逆仕様 ↔ Issue の整合性（15点満点）**
- rev-requirements.md が issue-struct.md の受け入れ基準を満たしているか
- 全 AC が実装・テスト・逆仕様の全フェーズでカバーされているか

## step4: 整合性スコアの算出

各チェックの点数を合算して整合性スコア（0-100）を算出する：

```
整合性スコア = Σ(チェック点数 × 充足率)
```

スコアの解釈：
- 90-100: ✅ Excellent（リリース可能）
- 70-89:  ⚠️ Good（軽微な不整合、次のスプリントで対応）
- 50-69:  ⚠️ Fair（要対応、早期解消を推奨）
- 0-49:   ❌ Poor（即時対応が必要）

## step5: 同期レポートの生成

`specs/sync-report.md` を生成する（既存の場合は上書き）。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/sync-report-template.md`
  - `.claude/commands/tsumigi/templates/sync-report-template.md`
- テンプレートの変数を置換し、チェック結果を埋めて Write する

## step6: アクションリストの生成

`specs/sync-actions.md` を生成する（手動対応が必要な項目のみ）。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/sync-actions-template.md`
  - `.claude/commands/tsumigi/templates/sync-actions-template.md`
- テンプレートの変数を置換し、手動対応が必要なアクションを埋めて Write する

## step7: 自動修正の実行（--fix が指定されている場合）

`--report-only` でない かつ `--fix` が指定されている場合：

自動修正可能な不整合を修正する：
- **imp_version の不一致**: patch-plan.md / testcases.md 等の imp_version フィールドを更新する
- **updated_at の未更新**: 各ファイルの updated_at を現在日時に更新する
- **issue_id の表記ゆれ**: ファイル名・フィールド名の issue_id を統一する

各修正について Edit ツールを使用し、変更を sync-report.md に記録する。

手動対応が必要な不整合は修正しない。sync-actions.md に記録して終了する。

## step8: 完了通知

- 以下を表示する：
  ```
  ✅ sync 完了: {{issue_id}}

  整合性スコア: N/100 — [Excellent/Good/Fair/Poor]

  生成ファイル:
    specs/sync-report.md
    specs/sync-actions.md

  手動対応が必要: N 件
  ```

- スコアが 70 未満の場合は「整合性スコアが低い状態です。sync-actions.md を確認して対応してください」と警告を表示する
- TodoWrite ツールでタスクを完了にマークする
