---
description: reviewer-orientedな観点でIMP・実装差分・リスクを整理します。arch/security/qaのペルソナ別チェックリスト・リスクマトリクス・確認質問リストを生成します。PRレビューにも対応。
allowed-tools: Read, Glob, Grep, Write, Edit, TodoWrite, Bash, AskUserQuestion
argument-hint: "[issue-id] [--persona arch|security|qa|all] [--pr <pr-number>]"
---

# tsumigi review

reviewer-oriented な観点で差分・リスク・確認事項を整理します。
ペルソナ（arch/security/qa）ごとにカスタマイズされた確認観点を提供します。

# context

issue_id={{issue_id}}
persona={{persona}}
pr_number={{pr_number}}
imp_file=specs/{{issue_id}}/IMP.md
imp_checklist_file=specs/{{issue_id}}/IMP-checklist.md
review_checklist_file=specs/{{issue_id}}/review-checklist.md
risk_matrix_file=specs/{{issue_id}}/risk-matrix.md
review_questions_file=specs/{{issue_id}}/review-questions.md

# step

- $ARGUMENTS を解析する：
  - `--persona` の後の値を persona に設定（デフォルト: all）
  - `--pr` の後の値を pr_number に設定
- issue_id の解決：
  - $ARGUMENTS の最初のトークンが指定されている場合はそれを issue_id に設定する
  - 未指定の場合は Bash で `git branch --show-current 2>/dev/null` を実行し、
    `feature/`, `feat/`, `fix/`, `hotfix/`, `chore/` などのプレフィックスを除いた値を issue_id に設定する
  - issue_id が取得できない場合は「issue-id を指定するか、feature/NNN-name 形式のブランチに切り替えてください」と言って終了する
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 成果物の収集

以下のファイルを存在する場合に Read する：
- `specs/{{issue_id}}/IMP.md`（メインのレビュー対象）
- `specs/{{issue_id}}/IMP-checklist.md`
- `specs/{{issue_id}}/IMP-risks.md`
- `specs/{{issue_id}}/implements/*/patch-plan.md`（全タスク）
- `specs/{{issue_id}}/tests/*/testcases.md`（全タスク）
- `specs/{{issue_id}}/rev-spec.md`
- `specs/{{issue_id}}/drift-report.md`（存在する場合）

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

`specs/{{issue_id}}/review-checklist.md` を生成する（既存の場合は更新）。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/review-checklist-template.md`
  - `.claude/commands/tsumigi/templates/review-checklist-template.md`
- テンプレートの変数を置換し、`{{persona}}` に含まれないペルソナのセクションは削除して Write する

## step6: リスクマトリクスの生成

`specs/{{issue_id}}/risk-matrix.md` を生成する。

IMP のリスクセクション・変更差分・drift レポートを分析してリスクを特定する。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/risk-matrix-template.md`
  - `.claude/commands/tsumigi/templates/risk-matrix-template.md`
- テンプレートの変数を置換し、分析したリスクを埋めて Write する

## step7: 確認質問リストの生成

`specs/{{issue_id}}/review-questions.md` を生成する。

レビュアーが実装者に確認すべき質問を生成する。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/review-questions-template.md`
  - `.claude/commands/tsumigi/templates/review-questions-template.md`
- テンプレートをベースに、IMP 固有の懸念点を「その他の確認事項」セクションに追加して Write する

## step8: PR へのチェックリスト投稿

pr_number が指定されている場合のみ実行する：

- 生成した `specs/{{issue_id}}/review-checklist.md` の内容を Read する
- Bash で PR コメントとして投稿する：
  ```bash
  gh pr comment {{pr_number}} --body "$(cat specs/{{issue_id}}/review-checklist.md)" 2>&1
  ```
- 投稿成功時：「📋 レビューチェックリストを PR #{{pr_number}} にコメントしました」と表示する
- 投稿失敗時：「PR コメントの投稿に失敗しました。手動で `specs/{{issue_id}}/review-checklist.md` を共有してください」と表示する

## step9: 完了通知

- 以下を表示する：
  ```
  ✅ review 完了: {{issue_id}}

  生成ファイル:
    specs/{{issue_id}}/review-checklist.md（N チェック項目）
    specs/{{issue_id}}/risk-matrix.md     （N リスク）
    specs/{{issue_id}}/review-questions.md（N 質問）

  レビュアーへの共有:
    PR にチェックリストを投稿済み（--pr 指定時）
    または specs/ ディレクトリを共有してください。

  PR 作成がまだの場合:
    /tsumigi:pr {{issue_id}} --post-checklist
  ```

- CRITICAL リスクが存在する場合は「CRITICAL リスクが N 件あります。リリース前に対応してください」と警告を表示する
- TodoWrite ツールでタスクを完了にマークする
