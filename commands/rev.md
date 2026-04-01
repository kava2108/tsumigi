---
description: 実装コードから逆仕様・API仕様・データスキーマ・要件定義書を生成します。生成物はIMPとの差分フラグ付きで出力され、drift_checkのインプットになります。
allowed-tools: Read, Glob, Grep, Write, Edit, TodoWrite, AskUserQuestion
argument-hint: "<issue-id> [--target api|schema|spec|requirements|all]"
---

# tsumigi rev

実装コードから逆仕様・ドキュメントを生成します。
tsumiki の `rev-design` + `rev-specs` + `rev-requirements` を統合した Skill です。
生成物には IMP との差分箇所に ⚠️ マークを付与します。

# context

issue_id={{issue_id}}
target={{target}}
imp_file=docs/imps/{{issue_id}}/IMP.md
rev_spec_file=docs/specs/{{issue_id}}/rev-spec.md
rev_api_file=docs/specs/{{issue_id}}/rev-api.md
rev_schema_file=docs/specs/{{issue_id}}/rev-schema.md
rev_requirements_file=docs/specs/{{issue_id}}/rev-requirements.md
信頼性評価=[]

# step

- $ARGUMENTS がない場合は「引数に issue-id を指定してください（例: /tsumigi:rev GH-123）」と言って終了する
- $ARGUMENTS を解析する：
  - `--target` の後の値を target に設定（デフォルト: all）
  - 最初のトークンを issue_id に設定
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 前提チェック

- `docs/imps/{{issue_id}}/IMP.md` の存在を確認する
  - 存在しない場合：IMP なしでも逆仕様生成は可能。「IMP がないため IMP との差分比較はスキップします」と通知する
  - 存在する場合：IMP.md を Read し、仕様の基準として使用する
- `docs/implements/{{issue_id}}/` 以下のファイルを Glob で確認する
- step3 を実行する

## step3: 対象スコープの確認

- target が未設定の場合、AskUserQuestion ツールを使って質問する：
  - question: "逆生成する対象を選択してください"
  - header: "逆生成対象"
  - multiSelect: true
  - options:
    - label: "api — API 仕様" — description: "エンドポイント・リクエスト/レスポンス構造"
    - label: "schema — データスキーマ" — description: "DB テーブル・型定義"
    - label: "spec — 機能仕様書" — description: "ビジネスロジックの振る舞い"
    - label: "requirements — 要件定義書" — description: "実装から逆算した要件"
    - label: "all（推奨）" — description: "全て生成"
  - 選択結果を context の {{target}} に保存する

## step4: 実装コードの探索

技術スタックに応じて以下のファイルを探索・読み込む：

**API 関連**（target: api または all）:
- ルーティング定義を Grep で探索する
  - Express: `app.get|app.post|router.get|router.post`
  - FastAPI: `@app.get|@app.post|@router.get`
  - Next.js: `pages/api/**/*.ts`
  - Go: `http.HandleFunc|r.GET|r.POST`
- コントローラー・ハンドラーファイルを Read する
- OpenAPI/Swagger 定義ファイルを Glob で確認する

**スキーマ関連**（target: schema または all）:
- DB マイグレーションファイルを Glob で探索する
- ORM モデル定義を Grep で探索する（Prisma schema, SQLAlchemy, TypeORM等）
- TypeScript 型定義・インターフェースを Grep で探索する
- GraphQL スキーマを Glob で確認する

**機能仕様関連**（target: spec または all）:
- テストファイルから振る舞い定義を読み取る
- サービス・ユースケース層のファイルを Read する
- patch-plan.md を確認する

## step5: 逆仕様書の生成（target: spec または all）

`docs/specs/{{issue_id}}/rev-spec.md` を生成する（既存の場合は差分マージ）。

<rev_spec_template>
---
issue_id: {{issue_id}}
generated_at: {{ISO8601}}
source_files: [{{解析したファイル一覧}}]
imp_version: {{imp_version|N/A}}
---

# 逆生成仕様書: {{issue_id}}

> この仕様書は実装コードから自動生成されました。
> ⚠️ マークは IMP との差分がある箇所を示します。

## 機能仕様

### {{機能名1}}

**実際の振る舞い**:
{{テストコードと実装コードから読み取った振る舞いを記述}}

**入力**:
- {{パラメータ名}}: {{型}} — {{説明}}

**出力**:
- 正常時: {{レスポンス}}
- 異常時: {{エラーレスポンス}}

**実装根拠**: `{{ファイルパス}}:{{行番号}}`

**IMP との差分**: ✅ 一致 / ⚠️ 差分あり
{{差分がある場合：IMP では...だが、実装では...となっている}}

---

## 信頼性サマリー

- 🔵 実装に根拠あり: N 件
- 🟡 テストのみで確認: N 件（実装の直接確認が必要）
- 🔴 不明（推定）: N 件

## IMP との乖離サマリー

⚠️ 差分が検出された箇所: N 件
→ 詳細確認: `/tsumigi:drift_check {{issue_id}}`
</rev_spec_template>

## step6: API 仕様書の生成（target: api または all）

`docs/specs/{{issue_id}}/rev-api.md` を生成する。

<rev_api_template>
---
issue_id: {{issue_id}}
generated_at: {{ISO8601}}
---

# 逆生成 API 仕様書: {{issue_id}}

## エンドポイント一覧

| Method | Path | 説明 | 認証 | 実装ファイル |
|---|---|---|---|---|
| GET | `/api/...` | | Required/Optional/None | `src/...` |

## エンドポイント詳細

### {{METHOD}} {{PATH}}

**概要**: {{説明}}

**認証**: {{認証方式}}

**リクエスト**:
```json
{
  "field": "type"
}
```

**レスポンス（成功）**:
```json
HTTP 200
{
  "field": "type"
}
```

**レスポンス（エラー）**:
```
HTTP 400: {{バリデーションエラー}}
HTTP 401: {{認証エラー}}
HTTP 404: {{リソース未検出}}
HTTP 500: {{サーバーエラー}}
```

**IMP との差分**: ✅ 一致 / ⚠️ {{差分内容}}

**実装根拠**: `{{ファイルパス}}:{{行番号}}`
</rev_api_template>

## step7: データスキーマ仕様書の生成（target: schema または all）

`docs/specs/{{issue_id}}/rev-schema.md` を生成する。

<rev_schema_template>
---
issue_id: {{issue_id}}
generated_at: {{ISO8601}}
---

# 逆生成スキーマ仕様書: {{issue_id}}

## データモデル概要

```
{{エンティティ関連図（テキスト形式）}}
```

## テーブル/モデル定義

### {{テーブル名/モデル名}}

| カラム/フィールド | 型 | NULL | デフォルト | 説明 |
|---|---|---|---|---|
| | | | | |

**インデックス**:
- {{インデックス定義}}

**制約**:
- {{制約定義}}

**IMP との差分**: ✅ 一致 / ⚠️ {{差分内容}}

## 型定義（TypeScript/Python等）

```typescript
{{型定義コード}}
```
</rev_schema_template>

## step8: 要件定義書の逆生成（target: requirements または all）

`docs/specs/{{issue_id}}/rev-requirements.md` を生成する。

テストファイルから「何を保証しているか」を読み取り、要件として文書化する。

<rev_requirements_template>
---
issue_id: {{issue_id}}
generated_at: {{ISO8601}}
derivation_method: テストコード・実装コードから逆算
---

# 逆生成要件定義書: {{issue_id}}

> この要件定義書はテストコード・実装コードから逆算して生成されました。
> 🟡マークは「テストが存在しないが実装から推定した」要件です。

## 機能要件

### FR-001: {{機能名}}

**EARS 記法**:
[WHEN] ... [THE SYSTEM SHALL] ...

**根拠**:
- テストコード: `{{テストファイル}}:{{テスト名}}`
- 実装コード: `{{実装ファイル}}:{{行番号}}`
- 信頼性: 🔵/🟡/🔴

**IMP との整合性**: ✅ 一致 / ⚠️ 差分あり / 🔴 IMP に未記載

---

## 非機能要件

（同形式）

## 元の IMP に存在するが実装で未確認の要件

| IMP 要件 | 状態 | 推奨アクション |
|---|---|---|
| AC-XXX: ... | 未実装の可能性 | `/tsumigi:drift_check` で確認 |
</rev_requirements_template>

## step9: drift_check への橋渡し

IMP との差分が検出された場合：
- 差分件数を表示する
- `/tsumigi:drift_check {{issue_id}}` の実行を推奨する

## step10: 完了通知

- 以下を表示する：
  ```
  ✅ rev 完了: {{issue_id}}

  生成ファイル:
    docs/specs/{{issue_id}}/rev-spec.md
    docs/specs/{{issue_id}}/rev-api.md      （api 対象時）
    docs/specs/{{issue_id}}/rev-schema.md   （schema 対象時）
    docs/specs/{{issue_id}}/rev-requirements.md（requirements 対象時）

  IMP との差分: N 件
  次のステップ:
    乖離詳細確認:  /tsumigi:drift_check {{issue_id}}
    全体同期:      /tsumigi:sync {{issue_id}}
  ```

- TodoWrite ツールでタスクを完了にマークする
