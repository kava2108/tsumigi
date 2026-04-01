---
description: IMP（仕様）と実装の乖離を5次元で検出・可視化します。drift スコア（0-100）を算出し、CRITICAL/WARNING/INFO で分類して乖離レポートを生成します。
allowed-tools: Read, Glob, Grep, Write, Edit, TodoWrite, Bash, AskUserQuestion
argument-hint: "<issue-id> [--since <commit-ish>] [--threshold <0-100>]"
---

# tsumigi drift_check

IMP（仕様）と実装の乖離を検出・スコア化します。
5 次元の照合エンジンで乖離を分類し、drift スコアとして定量化します。
冪等設計のため、実行するたびに drift-timeline.md に記録が蓄積されます。

# context

issue_id={{issue_id}}
since={{since}}
threshold={{threshold}}
imp_file=docs/imps/{{issue_id}}/IMP.md
drift_report_file=docs/drift/{{issue_id}}/drift-report.md
drift_timeline_file=docs/drift/{{issue_id}}/drift-timeline.md
drift_score=0
run_id={{UUID}}

# step

- $ARGUMENTS がない場合は「引数に issue-id を指定してください（例: /tsumigi:drift_check GH-123）」と言って終了する
- $ARGUMENTS を解析する：
  - `--since` の後の値を since に設定
  - `--threshold` の後の値を threshold に設定（デフォルト: 20）
  - 最初のトークンを issue_id に設定
- run_id として現在時刻を含むユニーク識別子を生成する（例: `drift-20260401-001`）
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 前提チェック

- `docs/imps/{{issue_id}}/IMP.md` の存在を確認する
  - 存在しない場合：「IMP.md が存在しません。先に `/tsumigi:imp_generate {{issue_id}}` を実行してください」と言って終了する
- IMP.md を Read する（imp_version, drift_baseline, 受け入れ基準, API仕様, スキーマ, タスクを抽出する）
- 過去の drift レポートを確認する：
  - `docs/drift/{{issue_id}}/drift-report.md` が存在する場合は Read する（前回スコアの比較用）

## step3: 実装スキャン

以下を Glob/Read/Grep で収集する：

**ソースファイル**:
- patch-plan.md から変更対象ファイルを取得する
- `docs/implements/{{issue_id}}/*/patch-plan.md` を全読み込みする
- 実際の変更ファイルを Read する

**テストファイル**:
- `src/**/*.test.{ts,tsx,js}`, `tests/**/*.py`, `**/*_test.go` 等を Glob する
- 各テストケース名・アサーション内容を Grep で抽出する

**API 定義**:
- ルーティングファイルを Grep する（エンドポイントパス・メソッドを抽出）
- OpenAPI/Swagger 定義があれば Read する

**スキーマ定義**:
- DB マイグレーション・モデル定義を Grep する

## step4: D1 — 機能仕様の乖離検出

**目的**: IMP の受け入れ基準（AC）が実装・テストでカバーされているか確認する

各 AC に対して以下を実施する：

1. AC から **キーワード**（名詞・動詞・条件）を抽出する
   例: `[WHEN] ユーザーが認証情報を送信する [THE SYSTEM SHALL] JWT を返す`
   → キーワード: `login`, `authenticate`, `jwt`, `token`

2. テストファイルを Grep してキーワードを検索する
3. 実装ファイルを Grep してキーワードを検索する
4. 判定する：
   - **COVERED** ✅: テストあり + 実装あり
   - **PARTIAL** ⚠️: 実装あり + テストなし（score += 3）
   - **TEST_ONLY** ⚠️: テストあり + 実装なし（score += 3）
   - **MISSING** ❌: 実装なし + テストなし（score += 10）

## step5: D2 — API 契約の乖離検出

**目的**: IMP の API 仕様と実際のエンドポイントが一致するか確認する

IMP から API 仕様を抽出する（「API 変更」セクション）。
実装ファイルを Grep してエンドポイントを抽出する。

各エンドポイントで以下を比較する：
- **パス** の一致: 不一致 → WARNING (score += 3)
- **HTTPメソッド** の一致: 不一致 → CRITICAL (score += 10)
- **レスポンス構造** の一致: 不一致 → WARNING (score += 3)
- **IMP 未記載の新規エンドポイント**: WARNING (score += 3)

## step6: D3 — スキーマの乖離検出

**目的**: IMP のスキーマ変更と実際のスキーマが一致するか確認する

IMP から「スキーマ変更」セクションを抽出する。
マイグレーション・モデルファイルを Read/Grep して実際のスキーマを取得する。

各スキーマ変更で以下を比較する：
- **カラム追加/削除** の一致: 不一致 → WARNING (score += 3)
- **型変更** の一致: 不一致 → CRITICAL (score += 10)
- **IMP 未記載のスキーマ変更**: WARNING (score += 3)

## step7: D4 — テストカバレッジの乖離検出

**目的**: IMP のテスト戦略と実際のテスト実装が一致するか確認する

IMP の「テスト戦略」セクションから目標を取得する。
testcases.md から実際のカバレッジを取得する。

比較する：
- **カバレッジ目標 vs 実際**: 目標 - 実際 > 10% → WARNING (score += 3)
- **P0 テストの未実装**: CRITICAL (score += 10)
- **セキュリティテストの未実装**: WARNING (score += 3)

## step8: D5 — タスク完了状態の乖離検出

**目的**: IMP のタスク一覧と実装の完了状態が一致するか確認する

IMP の全タスクを取得する。
patch-plan.md の「完了チェックリスト」を確認する。

比較する：
- **タスクの未着手** (patch-plan.md が存在しない): INFO (score += 1)
- **完了チェックリストの未チェック**: WARNING (score += 3)
- **IMP 未記載のタスクが実装されている**: INFO (score += 1)

## step9: drift スコアの算出と分類

```
drift_score = min(Σ(各次元のスコア), 100)

CRITICAL 件数: N件 × 10点
WARNING  件数: N件 × 3点
INFO     件数: N件 × 1点
合計: N点
```

スコアの解釈：
- 0-10:   ✅ Aligned（仕様と実装が一致している）
- 11-20:  ⚠️ Minor Drift（軽微な乖離、次のタイミングで対応）
- 21-50:  ⚠️ Significant Drift（IMP を更新するか実装を修正する）
- 51-100: ❌ Critical Drift（即時対応が必要）

## step10: drift レポートの生成

`docs/drift/{{issue_id}}/drift-report.md` を生成する（上書き）。

<drift_report_template>
---
issue_id: {{issue_id}}
run_id: {{run_id}}
run_at: {{ISO8601}}
imp_version: {{imp_version}}
drift_baseline: {{drift_baseline}}
drift_score: N
threshold: {{threshold}}
status: Aligned/Minor/Significant/Critical
---

# 乖離レポート: {{issue_id}}

## スコアサマリー

```
drift スコア: N/100 — [Aligned/Minor Drift/Significant Drift/Critical Drift]

CRITICAL: N件 (×10点 = N点)
WARNING:  N件 (×3点  = N点)
INFO:     N件 (×1点  = N点)
合計:     N点
```

---

## D1: 機能仕様の乖離

| AC | テスト | 実装 | 判定 | スコア |
|---|---|---|---|---|
| AC-001 | ✅ | ✅ | COVERED | 0 |
| AC-002 | ❌ | ✅ | PARTIAL | +3 |
| AC-003 | ❌ | ❌ | MISSING | +10 |

**D1 小計**: N点

---

## D2: API 契約の乖離

| エンドポイント | IMP 仕様 | 実装 | 乖離内容 | 判定 | スコア |
|---|---|---|---|---|---|
| GET /api/users | `{id, name}` | `{id, name, email}` | レスポンス構造の追加 | WARNING | +3 |

**D2 小計**: N点

---

## D3: スキーマの乖離

| スキーマ変更 | IMP 仕様 | 実装 | 乖離内容 | 判定 | スコア |
|---|---|---|---|---|---|
| | | | | | |

**D3 小計**: N点

---

## D4: テストカバレッジの乖離

| テスト種別 | IMP 目標 | 実際 | 乖離 | 判定 | スコア |
|---|---|---|---|---|---|
| Unit カバレッジ | 90% | 75% | -15% | WARNING | +3 |

**D4 小計**: N点

---

## D5: タスク完了状態の乖離

| タスク | 状態 | 判定 | スコア |
|---|---|---|---|
| TASK-0001 | patch-plan あり / チェック完了 | INFO | +0 |
| TASK-0002 | patch-plan なし | INFO | +1 |

**D5 小計**: N点

---

## 推奨アクション

### CRITICAL（即時対応）
- AC-003 の実装とテストが存在しない → `/tsumigi:implement {{issue_id}} TASK-XXXX` を実行する

### WARNING（早期対応）
- AC-002 のテストを追加する → `/tsumigi:test {{issue_id}}`
- IMP の API 仕様を実装に合わせて更新する → `/tsumigi:imp_generate {{issue_id}} --update`

### INFO（任意対応）
- TASK-0002 の実装着手 → `/tsumigi:implement {{issue_id}} TASK-0002`

---

## 前回との比較

| 指標 | 前回 | 今回 | 変化 |
|---|---|---|---|
| drift スコア | N | N | ↑N改善 / ↓N悪化 |
| CRITICAL | N | N | |
| WARNING | N | N | |
</drift_report_template>

## step11: タイムラインの更新

`docs/drift/{{issue_id}}/drift-timeline.md` に今回の実行結果を追記する（既存の場合は追記のみ）。

<drift_timeline_append>
## {{ISO8601}} — run_id: {{run_id}}

| drift スコア | CRITICAL | WARNING | INFO | IMP バージョン |
|---|---|---|---|---|
| N | N | N | N | {{imp_version}} |

主な変化: {{前回との差分の要約}}

---
</drift_timeline_append>

## step12: 閾値チェックと完了通知

- drift スコアが threshold を超えている場合は警告を表示する

- 以下を表示する：
  ```
  ✅ drift_check 完了: {{issue_id}}

  drift スコア: N/100 — [Aligned/Minor/Significant/Critical]
  (閾値: {{threshold}})
  CRITICAL: N件 / WARNING: N件 / INFO: N件

  生成ファイル:
    docs/drift/{{issue_id}}/drift-report.md
    docs/drift/{{issue_id}}/drift-timeline.md（追記）
  ```

- CRITICAL が 1 件以上ある場合:
  「❌ CRITICAL 乖離が検出されました。リリース前に対応してください。」と表示する

- threshold を超えた場合:
  「⚠️ drift スコア（N）が閾値（{{threshold}}）を超えています。」
  「IMP の更新（`/tsumigi:imp_generate {{issue_id}} --update`）または実装の修正を検討してください。」
  と表示する

- TodoWrite ツールでタスクを完了にマークする
