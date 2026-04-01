---
description: reviewer-orientedな観点でIMP・実装差分・リスクを整理します。arch/security/qaのペルソナ別チェックリスト・リスクマトリクス・確認質問リストを生成します。PRレビューにも対応。
allowed-tools: Read, Glob, Grep, Write, Edit, TodoWrite, Bash, AskUserQuestion
argument-hint: "<issue-id> [--persona arch|security|qa|all] [--pr <pr-number>]"
---

# tsumigi review

reviewer-oriented な観点で差分・リスク・確認事項を整理します。
ペルソナ（arch/security/qa）ごとにカスタマイズされた確認観点を提供します。

# context

issue_id={{issue_id}}
persona={{persona}}
pr_number={{pr_number}}
imp_file=docs/imps/{{issue_id}}/IMP.md
imp_checklist_file=docs/imps/{{issue_id}}/IMP-checklist.md
review_checklist_file=docs/reviews/{{issue_id}}/review-checklist.md
risk_matrix_file=docs/reviews/{{issue_id}}/risk-matrix.md
review_questions_file=docs/reviews/{{issue_id}}/review-questions.md

# step

- $ARGUMENTS がない場合は「引数に issue-id を指定してください（例: /tsumigi:review GH-123）」と言って終了する
- $ARGUMENTS を解析する：
  - `--persona` の後の値を persona に設定（デフォルト: all）
  - `--pr` の後の値を pr_number に設定
  - 最初のトークンを issue_id に設定
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 成果物の収集

以下のファイルを存在する場合に Read する：
- `docs/imps/{{issue_id}}/IMP.md`（メインのレビュー対象）
- `docs/imps/{{issue_id}}/IMP-checklist.md`
- `docs/imps/{{issue_id}}/IMP-risks.md`
- `docs/implements/{{issue_id}}/*/patch-plan.md`（全タスク）
- `docs/tests/{{issue_id}}/*/testcases.md`（全タスク）
- `docs/specs/{{issue_id}}/rev-spec.md`
- `docs/drift/{{issue_id}}/drift-report.md`（存在する場合）

PR 番号が指定されている場合：
- Bash で `gh pr view {{pr_number}} --json title,body,files 2>/dev/null` を実行する
- Bash で `gh pr diff {{pr_number}} 2>/dev/null | head -500` を実行する

## step3: ペルソナの確認

- persona が未設定 または "all" 以外の場合、AskUserQuestion ツールを使って質問する：
  - question: "どのペルソナでレビューしますか？"
  - header: "レビューペルソナ"
  - multiSelect: true
  - options:
    - label: "arch（アーキテクチャ）"
      description: "設計パターン・依存関係・スケーラビリティを重視したレビュー"
    - label: "security（セキュリティ）"
      description: "認証認可・OWASP・機密情報取り扱いを重視したレビュー"
    - label: "qa（品質保証）"
      description: "テストカバレッジ・エッジケース・非機能要件を重視したレビュー"
    - label: "all（全ペルソナ）"
      description: "3つのペルソナ全てでレビューする"
  - 選択結果を context の {{persona}} に保存する

## step4: ペルソナ別レビューの実施

選択されたペルソナに応じてレビューを実施し、checklist を生成する：

---

### アーキテクチャレビュー（persona: arch または all）

以下の観点で IMP・実装・変更差分を分析する：

**設計整合性**:
- 既存アーキテクチャパターン（MVC/Clean/Hexagonal等）との整合を確認する
- Glob で `src/` 構造を把握し、レイヤー違反がないか確認する
- 依存方向（上位→下位の一方向性）が保たれているか確認する

**複雑度**:
- 変更の複雑度が適切か（YAGNI 原則: 今必要なもののみ）
- 過剰な抽象化・過小な分割がないか

**スケーラビリティ**:
- 変更後もスケールアウト可能な設計か
- ボトルネックになり得る箇所がないか

**外部依存**:
- 新規追加された外部ライブラリのセキュリティ・ライセンスを確認する
- バージョン固定がされているか

**ロールバック実現性**:
- IMP のロールバック計画が技術的に実行可能か確認する

---

### セキュリティレビュー（persona: security または all）

以下の観点で IMP・実装・変更差分を分析する：

**認証・認可**:
- Grep で認証チェックが全エンドポイントに適用されているか確認する
  - `middleware|auth|authorize|permission|role` 等のキーワード
- 認可漏れ（水平/垂直権限昇格）がないか確認する

**入力バリデーション**:
- Grep で全入力箇所にバリデーションが実装されているか確認する
- SQL インジェクション・XSS・CSRF のリスクを評価する

**機密情報**:
- Grep でハードコードされたシークレット・APIキーがないか確認する
  - `password|secret|api_key|token|private` 等のキーワード（ただし変数代入のみ）
- ログに機密情報が出力されないか確認する

**暗号化**:
- パスワードが適切にハッシュ化されているか
- 通信が TLS で保護されているか（設定ファイルを確認）

**監査ログ**:
- 重要な操作（ログイン・権限変更・データ削除）がログに記録されるか

---

### QA レビュー（persona: qa または all）

以下の観点で IMP・テスト・変更差分を分析する：

**テストカバレッジ**:
- 全 AC にテストケースが存在するか testcases.md で確認する
- 未カバーの AC を特定する

**テスト品質**:
- 正常系・異常系・境界値が網羅されているか
- テストが独立して実行可能か（テスト間の依存がないか）
- テストデータが適切に管理されているか

**非機能要件**:
- パフォーマンス要件のテストが存在するか
- 信頼性要件（エラー率・可用性）のテストが存在するか

**既存テストへの影響**:
- 変更によって既存テストが破壊されないか
- test-results.md で確認する（存在する場合）

## step5: レビューチェックリストの生成

`docs/reviews/{{issue_id}}/review-checklist.md` を生成する（既存の場合は更新）。

<review_checklist_template>
---
issue_id: {{issue_id}}
generated_at: {{ISO8601}}
personas: {{persona}}
pr_number: {{pr_number|N/A}}
---

# レビューチェックリスト: {{issue_id}}

> このチェックリストはレビュアーが PR を承認する前に確認する項目です。
> 確認済みの項目: `[ ]` → `[x]`
> 問題あり: `[ ]` → `[!]`（コメントを追加してください）

---

## 共通確認事項（全レビュアー）

- [ ] IMP の Executive Summary が変更内容と一致している
- [ ] ロールバック計画が実行可能である
- [ ] drift スコアが閾値（20）以下である
- [ ] sync スコアが 70 以上である

---

## アーキテクチャチェックリスト（arch）
<!-- persona に arch が含まれる場合のみ表示 -->

### 設計整合性
- [ ] 変更が既存アーキテクチャパターンと整合している
- [ ] レイヤー違反（上位→下位の依存方向）がない
- [ ] 循環依存が発生していない

### 複雑度・設計品質
- [ ] 設計の複雑度が最小限に抑えられている（YAGNI 原則）
- [ ] 過剰な抽象化がない
- [ ] 新規追加のライブラリが評価済みである（セキュリティ・ライセンス）

### 拡張性・運用性
- [ ] スケールアウト可能な設計である
- [ ] ロールバック計画が技術的に実行可能である
- [ ] 変更がデプロイ計画と整合している

**arch 総合判定**: ✅ 承認 / ⚠️ 条件付き承認 / ❌ 差し戻し
コメント:

---

## セキュリティチェックリスト（security）
<!-- persona に security が含まれる場合のみ表示 -->

### 認証・認可
- [ ] 全エンドポイントに適切な認証チェックが実装されている
- [ ] 権限昇格（水平・垂直）のリスクがない
- [ ] セッション管理が適切である

### 入力・出力
- [ ] 全入力箇所にバリデーションが実装されている
- [ ] SQL インジェクション・XSS・CSRF のリスクが軽減されている
- [ ] 出力にエスケープ処理が実装されている

### 機密情報・暗号化
- [ ] ハードコードされたシークレットがない
- [ ] パスワードが適切にハッシュ化されている
- [ ] ログに機密情報が出力されない

### 監査・ログ
- [ ] 重要な操作が監査ログに記録される
- [ ] ログに個人情報が含まれない

**security 総合判定**: ✅ 承認 / ⚠️ 条件付き承認 / ❌ 差し戻し
コメント:

---

## QA チェックリスト（qa）
<!-- persona に qa が含まれる場合のみ表示 -->

### テストカバレッジ
- [ ] 全 AC に対応するテストケースが存在する
- [ ] 正常系・異常系・境界値が網羅されている
- [ ] セキュリティテストケースが含まれている

### テスト品質
- [ ] テストが独立して実行可能である
- [ ] テストデータが適切に管理されている
- [ ] 既存テストへの影響が評価されている

### 非機能要件
- [ ] パフォーマンス要件のテストが存在する
- [ ] 信頼性要件のテストが存在する

**qa 総合判定**: ✅ 承認 / ⚠️ 条件付き承認 / ❌ 差し戻し
コメント:

---

## 承認記録

| ペルソナ | 担当者 | 判定 | 承認日時 |
|---|---|---|---|
| arch | | ✅/⚠️/❌ | |
| security | | ✅/⚠️/❌ | |
| qa | | ✅/⚠️/❌ | |
</review_checklist_template>

## step6: リスクマトリクスの生成

`docs/reviews/{{issue_id}}/risk-matrix.md` を生成する。

IMP のリスクセクション・変更差分・drift レポートを分析してリスクを特定する。

<risk_matrix_template>
---
issue_id: {{issue_id}}
generated_at: {{ISO8601}}
---

# レビュー用リスクマトリクス: {{issue_id}}

## リスク評価基準

| 影響度 | H（高）| M（中）| L（低）|
|---|---|---|---|
| 定義 | サービス停止・データ消失・セキュリティ侵害 | 一部機能の劣化・パフォーマンス低下 | UX の軽微な低下 |

| 発生確率 | H（高）| M（中）| L（低）|
|---|---|---|---|
| 定義 | 変更後 30 日以内に高確率で発生 | 特定条件下で発生する可能性 | まれなケースのみ |

## リスク一覧

| # | カテゴリ | リスク内容 | 影響度 | 発生確率 | 優先度 | 対策 | 状態 |
|---|---|---|---|---|---|---|---|
| R-001 | 機能 | | H/M/L | H/M/L | HH/HM/HLなど | | 未対応/対策済 |
| R-002 | セキュリティ | | | | | | |
| R-003 | パフォーマンス | | | | | | |

## 優先度の解釈

| 優先度 | 影響×確率 | 推奨アクション |
|---|---|---|
| CRITICAL | HH | 即時対応必須、リリースブロック |
| HIGH | HM または MH | リリース前に対応 |
| MEDIUM | MM または HL/LH | 次のスプリントで対応 |
| LOW | ML/LM/LL | バックログに積む |

## ロールバックトリガー

| トリガー条件 | 閾値 | 監視方法 |
|---|---|---|
| エラー率 | > X% | Datadog / CloudWatch |
| レスポンスタイム | > N ms | |
| その他 | | |
</risk_matrix_template>

## step7: 確認質問リストの生成

`docs/reviews/{{issue_id}}/review-questions.md` を生成する。

レビュアーが実装者に確認すべき質問を生成する。

<review_questions_template>
---
issue_id: {{issue_id}}
generated_at: {{ISO8601}}
---

# レビュアー確認質問リスト: {{issue_id}}

これらの質問は、レビュー時に実装者に確認することを推奨します。
回答を記入して PR コメントやミーティングで使用してください。

---

## アーキテクチャに関する質問

- Q1: [arch] この設計を選んだ理由は何ですか？他の設計案と比較しましたか？
  → 回答:

- Q2: [arch] ロールバックが必要になった場合、どの程度の時間で実行できますか？
  → 回答:

---

## セキュリティに関する質問

- Q3: [security] 認証チェックが適用されないエンドポイントはありますか？
  → 回答:

- Q4: [security] 入力バリデーションの漏れがあった場合の影響は何ですか？
  → 回答:

---

## テスト・品質に関する質問

- Q5: [qa] テストカバレッジが低い部分の理由と対応予定は？
  → 回答:

- Q6: [qa] このリリース後に監視すべきメトリクスは何ですか？
  → 回答:

---

## その他の確認事項

（分析で発見された IMP 固有の懸念点を追加）
</review_questions_template>

## step8: 完了通知

- 以下を表示する：
  ```
  ✅ review 完了: {{issue_id}}

  生成ファイル:
    docs/reviews/{{issue_id}}/review-checklist.md（N チェック項目）
    docs/reviews/{{issue_id}}/risk-matrix.md     （N リスク）
    docs/reviews/{{issue_id}}/review-questions.md（N 質問）

  レビュアーへの共有:
    docs/reviews/{{issue_id}}/ ディレクトリを共有するか、
    PR の description に checklist を貼り付けてください。
  ```

- CRITICAL リスクが存在する場合は「CRITICAL リスクが N 件あります。リリース前に対応してください」と警告を表示する
- TodoWrite ツールでタスクを完了にマークする
