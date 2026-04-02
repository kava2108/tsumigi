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
imp_file=specs/IMP.md
rev_spec_file=specs/rev-spec.md
rev_api_file=specs/rev-api.md
rev_schema_file=specs/rev-schema.md
rev_requirements_file=specs/rev-requirements.md
信頼性評価=[]

# step

- $ARGUMENTS がない場合は「引数に issue-id を指定してください（例: /tsumigi:rev GH-123）」と言って終了する
- $ARGUMENTS を解析する：
  - `--target` の後の値を target に設定（デフォルト: all）
  - 最初のトークンを issue_id に設定
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 前提チェック

- `specs/IMP.md` の存在を確認する
  - 存在しない場合：IMP なしでも逆仕様生成は可能。「IMP がないため IMP との差分比較はスキップします」と通知する
  - 存在する場合：IMP.md を Read し、仕様の基準として使用する
- `specs/implements/` 以下のファイルを Glob で確認する
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

`specs/rev-spec.md` を生成する（既存の場合は差分マージ）。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/rev-spec-template.md`
  - `.claude/commands/tsumigi/templates/rev-spec-template.md`
- テンプレートの変数を置換し、実装コードから読み取った仕様を埋めて Write する

## step6: API 仕様書の生成（target: api または all）

`specs/rev-api.md` を生成する。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/rev-api-template.md`
  - `.claude/commands/tsumigi/templates/rev-api-template.md`
- テンプレートの変数を置換し、探索したエンドポイントを埋めて Write する

## step7: データスキーマ仕様書の生成（target: schema または all）

`specs/rev-schema.md` を生成する。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/rev-schema-template.md`
  - `.claude/commands/tsumigi/templates/rev-schema-template.md`
- テンプレートの変数を置換し、探索したスキーマを埋めて Write する

## step8: 要件定義書の逆生成（target: requirements または all）

`specs/rev-requirements.md` を生成する。

テストファイルから「何を保証しているか」を読み取り、要件として文書化する。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/rev-requirements-template.md`
  - `.claude/commands/tsumigi/templates/rev-requirements-template.md`
- テンプレートの変数を置換し、テスト・実装から逆算した要件を埋めて Write する

## step9: drift_check への橋渡し

IMP との差分が検出された場合：
- 差分件数を表示する
- `/tsumigi:drift_check {{issue_id}}` の実行を推奨する

## step10: 完了通知

- 以下を表示する：
  ```
  ✅ rev 完了: {{issue_id}}

  生成ファイル:
    specs/rev-spec.md
    specs/rev-api.md      （api 対象時）
    specs/rev-schema.md   （schema 対象時）
    specs/rev-requirements.md（requirements 対象時）

  IMP との差分: N 件
  次のステップ:
    乖離詳細確認:  /tsumigi:drift_check {{issue_id}}
    全体同期:      /tsumigi:sync {{issue_id}}
  ```

- TodoWrite ツールでタスクを完了にマークする
