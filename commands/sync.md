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
sync_report_file=docs/sync/{{issue_id}}/sync-report.md
sync_actions_file=docs/sync/{{issue_id}}/sync-actions.md
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
- `docs/issues/{{issue_id}}/issue-struct.md`
- `docs/issues/{{issue_id}}/tasks.md`
- `docs/issues/{{issue_id}}/note.md`

**IMP 成果物**:
- `docs/imps/{{issue_id}}/IMP.md`
- `docs/imps/{{issue_id}}/IMP-checklist.md`
- `docs/imps/{{issue_id}}/IMP-risks.md`

**実装成果物**:
- `docs/implements/{{issue_id}}/*/patch-plan.md`（全タスク）
- `docs/implements/{{issue_id}}/*/impl-memo.md`（全タスク）

**テスト成果物**:
- `docs/tests/{{issue_id}}/*/testcases.md`（全タスク）
- `docs/tests/{{issue_id}}/*/test-plan.md`（全タスク）
- `docs/tests/{{issue_id}}/*/test-results.md`（存在する場合）

**逆仕様成果物**:
- `docs/specs/{{issue_id}}/rev-spec.md`
- `docs/specs/{{issue_id}}/rev-api.md`
- `docs/specs/{{issue_id}}/rev-schema.md`

**過去の同期レポート**:
- `docs/sync/{{issue_id}}/sync-report.md`（存在する場合）

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

`docs/sync/{{issue_id}}/sync-report.md` を生成する（既存の場合は上書き）。

<sync_report_template>
---
issue_id: {{issue_id}}
run_at: {{ISO8601}}
consistency_score: N
status: Excellent/Good/Fair/Poor
---

# 整合性レポート: {{issue_id}}

## スコアサマリー

```
整合性スコア: N/100 — [Excellent/Good/Fair/Poor]

チェック1 Issue ↔ IMP:      N/20  [Pass/Warn/Fail]
チェック2 IMP ↔ 実装:       N/25  [Pass/Warn/Fail]
チェック3 IMP ↔ テスト:     N/25  [Pass/Warn/Fail]
チェック4 実装 ↔ 逆仕様:    N/15  [Pass/Warn/Fail]
チェック5 逆仕様 ↔ Issue:   N/15  [Pass/Warn/Fail]
```

---

## チェック詳細

### チェック1: Issue ↔ IMP（N/20点）

| 項目 | 結果 | 詳細 |
|---|---|---|
| 受け入れ基準の転写 | ✅/⚠️/❌ | |
| タスク対応 | ✅/⚠️/❌ | |
| issue_id 一致 | ✅/⚠️/❌ | |
| 非機能要件の反映 | ✅/⚠️/❌ | |

（以降、チェック2〜5を同形式で記述）

---

## 不整合一覧

| # | 種別 | 内容 | 影響度 | 自動修正? |
|---|---|---|---|---|
| SY-001 | IMP未反映 | issue-struct の AC-003 が IMP に未記載 | H | ❌ 手動対応 |
| SY-002 | バージョン不一致 | IMP v1.0.0 だが patch-plan は v0.9.0 | M | ✅ 自動修正可 |

---

## 前回実行との比較

| 前回スコア | 今回スコア | 変化 |
|---|---|---|
| N | N | ↑N点改善 / ↓N点悪化 / 変化なし |

---

## 次のアクション

### 自動修正済み（--fix 実行時）
- [x] SY-002: patch-plan の imp_version を更新

### 手動対応が必要
→ `docs/sync/{{issue_id}}/sync-actions.md` を参照
</sync_report_template>

## step6: アクションリストの生成

`docs/sync/{{issue_id}}/sync-actions.md` を生成する（手動対応が必要な項目のみ）。

<sync_actions_template>
---
issue_id: {{issue_id}}
generated_at: {{ISO8601}}
total_actions: N
---

# 手動対応アクション: {{issue_id}}

これらは自動修正できないため、手動での対応が必要です。
対応完了後に `/tsumigi:sync {{issue_id}} --report-only` で再確認してください。

## 優先度 HIGH（即時対応）

### ACTION-001: {{内容}}

| 項目 | 内容 |
|---|---|
| **種別** | IMP未反映 / テスト不足 / スキーマ不整合 等 |
| **影響** | {{影響の説明}} |
| **対応方法** | `/tsumigi:xxx` コマンドを実行する |
| **担当** | |
| **期限** | |

---

## 優先度 MEDIUM（次のスプリントまで）

（同形式）

## 優先度 LOW（余裕があれば）

（同形式）

## 対応完了チェック

- [ ] ACTION-001
- [ ] ACTION-002
</sync_actions_template>

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
    docs/sync/{{issue_id}}/sync-report.md
    docs/sync/{{issue_id}}/sync-actions.md

  手動対応が必要: N 件
  ```

- スコアが 70 未満の場合は「整合性スコアが低い状態です。sync-actions.md を確認して対応してください」と警告を表示する
- TodoWrite ツールでタスクを完了にマークする
