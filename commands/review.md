---
description: reviewer-orientedな観点でIMP・実装差分・リスクを整理します。arch/security/qaのペルソナ別チェックリスト・リスクマトリクス・確認質問リストを生成します。--adversaryフラグでAdversarialレビュー（コンテキスト分離・5次元バイナリ評価・強制否定バイアス）を実行します。PRレビューにも対応。
allowed-tools: Read, Glob, Grep, Write, Edit, TodoWrite, Bash, AskUserQuestion
argument-hint: "[issue-id] [--persona arch|security|qa|all] [--adversary] [--pr <pr-number>]"
---

# tsumigi review

reviewer-oriented な観点で差分・リスク・確認事項を整理します。
ペルソナ（arch/security/qa）ごとにカスタマイズされた確認観点を提供します。

`--adversary` フラグを指定すると **Adversarial Review モード** で実行します。
Adversary は Builder のコンテキストを持たず、成果物だけを読んで批判的に評価します。

# context

issue_id={{issue_id}}
persona={{persona}}
adversary_mode={{adversary_mode}}
pr_number={{pr_number}}
imp_file=specs/{{issue_id}}/IMP.md
imp_checklist_file=specs/{{issue_id}}/IMP-checklist.md
review_checklist_file=specs/{{issue_id}}/review-checklist.md
risk_matrix_file=specs/{{issue_id}}/risk-matrix.md
review_questions_file=specs/{{issue_id}}/review-questions.md
adversary_report_file=specs/{{issue_id}}/adversary-report.md

# step

- $ARGUMENTS を解析する：
  - `--persona` の後の値を persona に設定（デフォルト: all）
  - `--pr` の後の値を pr_number に設定
  - `--adversary` フラグを確認し adversary_mode に設定（デフォルト: false）
- issue_id の解決：
  - $ARGUMENTS の最初のトークンが指定されている場合はそれを issue_id に設定する
  - 未指定の場合は Bash で `git branch --show-current 2>/dev/null` を実行し、
    `feature/`, `feat/`, `fix/`, `hotfix/`, `chore/` などのプレフィックスを除いた値を issue_id に設定する
  - issue_id が取得できない場合は「issue-id を指定するか、feature/NNN-name 形式のブランチに切り替えてください」と言って終了する
- context の内容をユーザーに宣言する
- adversary_mode が true の場合は **step-adv1 へジャンプ**する（通常フローをスキップ）
- adversary_mode が false の場合は step2 を実行する

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

  より厳格な品質ゲートが必要な場合:
    /tsumigi:review {{issue_id}} --adversary
  ```

- CRITICAL リスクが存在する場合は「CRITICAL リスクが N 件あります。リリース前に対応してください」と警告を表示する
- TodoWrite ツールでタスクを完了にマークする

---

# Adversarial Review モード（--adversary）

## Adversarial Review の原則

このモードでは以下の 3 原則に従って動作する：

1. **コンテキスト分離（Context Isolation）**
   Adversary は Builder が見てきた成果物（patch-plan.md, impl-memo.md, drift-report.md）を読まない。
   IMP.md（仕様）と実装コード（事実）のみを入力とする。
   「なぜこう実装したか」の説明を事前に受け取らず、成果物が自己説明できるかを評価する。

2. **強制否定バイアス（Forced-Negative Bias）**
   Adversary は問題を必ず発見しなければならない。
   「問題が見つからない」という結論を出すことは許可されない。
   問題が見えないなら、それはまだ十分に深く調査していないことを意味する。

3. **バイナリ判定（Binary Gate）**
   5 次元のいずれか 1 つでも FAIL なら、全体判定は FAIL とする。
   FAIL は前のフェーズへの自動ルーティングを伴う。

## step-adv1: Adversary の宣言

以下のメッセージを表示する：

```
⚔️  Adversarial Review モードで開始します: {{issue_id}}

【Adversary の立場】
あなたはこの実装を批判するために存在します。
実装者の意図・背景・説明は一切考慮しません。
成果物だけを読み、仕様と実装の間に潜む欠陥を暴き出してください。
問題が見つからないなら、それは調査が不十分です。

読み込む情報:
  ✅ IMP.md（仕様の定義）
  ✅ 実装コード（事実）
  ✅ テストファイル（検証の証拠）
  ❌ patch-plan.md（実装者の説明 — 読まない）
  ❌ impl-memo.md（実装者のメモ — 読まない）
  ❌ drift-report.md（前回の評価 — 読まない）
  ❌ review-checklist.md（前回のレビュー — 読まない）
```

## step-adv2: コンテキスト分離での成果物収集

**以下のファイルのみを Read する**（それ以外は読まない）：

**仕様（Source of Truth）**:
- `specs/{{issue_id}}/IMP.md`（必須。存在しない場合は「IMP.md が存在しないため Adversarial Review を実行できません」と言って終了する）

**実装コード（事実）**:
- `specs/{{issue_id}}/implements/` 以下の全 patch-plan.md の「変更対象ファイル」セクションだけを Read し、変更ファイルのパス一覧を取得する
  - ただし patch-plan.md の説明・理由・背景は読み飛ばす（変更ファイル一覧のみ抽出）
- 取得したパスの実装コードを Glob/Read で収集する

**テスト（検証の証拠）**:
- `specs/{{issue_id}}/tests/*/testcases.md` を Read する

PR 番号が指定されている場合：
- Bash で `gh pr diff {{pr_number}} 2>/dev/null | head -1000` を実行して diff を取得する
- diff のみを参照し、PR の説明文・コメント・レビュー履歴は読まない

## step-adv3: 5 次元バイナリ評価

以下の 5 次元を順番に評価する。各次元は **PASS / FAIL のみ** で判定する。
中間評価（WARNING など）はない。疑わしければ FAIL とする。

---

### 次元 1: Spec Fidelity（仕様忠実性）

**問い**: IMP.md の全受け入れ基準（AC）を実装が満たしているか？

評価手順:
1. IMP.md から全 AC を一覧化する
2. 各 AC に対して、実装コードにその AC を満たすロジックが存在するかを確認する
3. AC のキーワード（名詞・動詞・条件）を実装コードで Grep する
4. 以下のいずれかに該当すれば FAIL:
   - AC に対応する実装が見つからない
   - 実装はあるが AC の条件（WHEN/IF/SHALL）を満たしていない
   - IMP に記載されていない機能が実装されている（スコープクリープ）

**判定**: PASS / FAIL
FAIL の場合: 未実装 AC、条件違反、スコープクリープの具体的な箇所を列挙する

---

### 次元 2: Edge Case Coverage（エッジケースカバレッジ）

**問い**: 正常系以外のケースが十分にテストされているか？

評価手順:
1. testcases.md から正常系・異常系・境界値テストの件数を確認する
2. 実装コードのエラーハンドリング箇所を Grep する（try/catch, if err != nil, .catch 等）
3. 以下のいずれかに該当すれば FAIL:
   - 異常系テストが P0 受け入れ基準の 50% 未満
   - 実装にエラーハンドリングがあるがテストが存在しない
   - ネットワーク障害・タイムアウト・空配列・null 等の境界値が未テスト
   - セキュリティ系テスト（認証失敗・権限昇格試行）が皆無

**判定**: PASS / FAIL
FAIL の場合: 未テストのエッジケースを具体的に列挙する

---

### 次元 3: Implementation Correctness（実装正確性）

**問い**: コードに論理的な誤りはないか？

評価手順:
1. 実装コードを注意深く読み、以下を確認する:
   - 条件分岐の論理（AND/OR の誤り、否定の見落とし）
   - 非同期処理の扱い（await 漏れ、race condition）
   - データ変換・型変換の正確性
   - ループ・再帰の終了条件
2. IMP の API 仕様と実際のレスポンス構造を照合する
3. 以下のいずれかに該当すれば FAIL:
   - 明らかな論理バグが存在する
   - API のレスポンス構造が IMP と異なる
   - データ変換に精度損失・オーバーフロー等のリスクがある
   - 非同期処理が正しくハンドリングされていない

**判定**: PASS / FAIL
FAIL の場合: バグの箇所・理由・影響範囲を具体的に示す

---

### 次元 4: Structural Integrity（構造的健全性）

**問い**: コードの構造・設計が健全か？

評価手順:
1. 既存コードベースのパターンを Glob で把握する（変更ファイルの周辺 5 ファイル程度）
2. 変更コードが既存パターンから逸脱していないかを確認する
3. 以下のいずれかに該当すれば FAIL:
   - 既存アーキテクチャのレイヤー境界を侵犯している（例: UI 層に DB クエリ）
   - 同じ責務を持つコードが重複している（DRY 違反）
   - 循環依存が生じている
   - 1 関数が 50 行超かつ複数の責務を持つ（SRP 違反）
   - ハードコードされた設定値・マジックナンバーが存在する

**判定**: PASS / FAIL
FAIL の場合: 構造的問題の箇所と理由を具体的に示す

---

### 次元 5: Verification Readiness（検証可能性）

**問い**: テストは実行可能で、仕様を正しく検証しているか？

評価手順:
1. testcases.md の各テストケースが実際のテストコードと対応しているかを Grep で確認する
2. テストコードの品質を評価する
3. 以下のいずれかに該当すれば FAIL:
   - testcases.md に記載されたテストケースがテストコードに実装されていない
   - テストが実装の内部実装に依存している（振る舞いではなく実装をテストしている）
   - モックが過剰でインテグレーションの検証になっていない
   - P0 テストが 1 件でも欠如している
   - テスト自体が間違った仕様を検証している（偽陽性）

**判定**: PASS / FAIL
FAIL の場合: 検証できていないテストケースと理由を具体的に示す

---

## step-adv4: 全体判定と FAIL 分析

5 次元の判定結果を集計する：

```
⚔️ Adversarial Review 判定: {{issue_id}}

┌────────────────────────────┬────────┬─────────────────────────┐
│ 次元                        │ 判定   │ 主要な指摘               │
├────────────────────────────┼────────┼─────────────────────────┤
│ 1. Spec Fidelity           │ PASS/FAIL │ (要約)              │
│ 2. Edge Case Coverage      │ PASS/FAIL │ (要約)              │
│ 3. Implementation Correctness│ PASS/FAIL│ (要約)             │
│ 4. Structural Integrity    │ PASS/FAIL │ (要約)              │
│ 5. Verification Readiness  │ PASS/FAIL │ (要約)              │
└────────────────────────────┴────────┴─────────────────────────┘

全体判定: ✅ PASS / ❌ FAIL
```

**全体判定のルール**:
- 全次元が PASS → 全体 PASS
- 1 次元でも FAIL → 全体 FAIL（例外なし）

全体 FAIL の場合、FAIL 次元ごとに**自動ルーティング先**を決定する：

| FAIL 次元 | ルーティング先 | 推奨コマンド |
|---|---|---|
| Spec Fidelity | 実装の修正 | `/tsumigi:implement {{issue_id}} --update` |
| Edge Case Coverage | テストの追加 | `/tsumigi:test {{issue_id}} {{task_id}}` |
| Implementation Correctness | 実装の修正 | `/tsumigi:implement {{issue_id}} --update` |
| Structural Integrity | IMP の設計見直し | `/tsumigi:imp_generate {{issue_id}} --update` |
| Verification Readiness | テストの修正 | `/tsumigi:test {{issue_id}} {{task_id}}` |

## step-adv5: Adversary レポートの生成

`specs/{{issue_id}}/adversary-report.md` を生成する（既存の場合は上書き）。

以下の内容を Write する：

```markdown
# Adversary Report: {{issue_id}}

**実行日時**: {{ISO8601}}
**全体判定**: PASS / FAIL
**FAIL 次元**: N 件

## 判定サマリー

| 次元 | 判定 | 指摘件数 |
|------|------|---------|
| 1. Spec Fidelity | PASS/FAIL | N |
| 2. Edge Case Coverage | PASS/FAIL | N |
| 3. Implementation Correctness | PASS/FAIL | N |
| 4. Structural Integrity | PASS/FAIL | N |
| 5. Verification Readiness | PASS/FAIL | N |

## 次元別詳細

### 次元 1: Spec Fidelity — PASS/FAIL

[具体的な指摘内容]

### 次元 2: Edge Case Coverage — PASS/FAIL

[具体的な指摘内容]

...（各次元を記述）

## 自動ルーティング

FAIL に対して以下のアクションが必要です：

1. [アクション内容] → `/tsumigi:コマンド {{issue_id}}`

## Adversary の総評

[全体的な品質評価と最も重要な修正事項の要約]
注意: この評価は Builder のコンテキストを持たない Adversary による独立評価です。
```

## step-adv6: 完了通知

全体判定が **PASS** の場合：

```
✅ Adversarial Review: PASS — {{issue_id}}

全 5 次元をクリアしました。

生成ファイル:
  specs/{{issue_id}}/adversary-report.md

次のステップ:
  PR 作成: /tsumigi:pr {{issue_id}}
```

全体判定が **FAIL** の場合：

```
❌ Adversarial Review: FAIL — {{issue_id}}

FAIL 次元: N 件

[FAIL 次元ごとの指摘サマリー]

自動ルーティング:
  [FAIL 次元に対応する推奨コマンドを列挙]

生成ファイル:
  specs/{{issue_id}}/adversary-report.md

⚠️ 上記の修正が完了したら、再度 Adversarial Review を実行してください:
  /tsumigi:review {{issue_id}} --adversary
```

- TodoWrite ツールでタスクを完了にマークする
