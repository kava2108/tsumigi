---
description: Issue 構造定義から IMP（実装管理計画書）を生成・更新します。IMP は実装・テスト・レビューの全フェーズで参照される単一の真実の源です。reviewer-oriented な構造で監査可能な形式で出力します。
allowed-tools: Read, Glob, Grep, Write, Edit, TodoWrite, AskUserQuestion
argument-hint: "<issue-id> [--update] [--reviewer arch|security|qa]"
---

# tsumigi imp_generate

IMP（Implementation Management Plan / 実装管理計画書）を生成します。
IMP は Issue〜実装〜ドキュメントの**単一の真実の源**です。

# context

issue_id={{issue_id}}
update_mode={{update_mode}}
reviewer_personas={{reviewer_personas}}
issue_struct_file=docs/issues/{{issue_id}}/issue-struct.md
tasks_file=docs/issues/{{issue_id}}/tasks.md
note_file=docs/issues/{{issue_id}}/note.md
imp_file=docs/imps/{{issue_id}}/IMP.md
imp_checklist_file=docs/imps/{{issue_id}}/IMP-checklist.md
imp_risks_file=docs/imps/{{issue_id}}/IMP-risks.md
imp_version=1.0.0
信頼性評価=[]

# step

- $ARGUMENTS がない場合は「引数に issue-id を指定してください（例: /tsumigi:imp_generate GH-123）」と言って終了する
- $ARGUMENTS を解析する：
  - `--update` フラグを確認し update_mode に設定
  - `--reviewer` の後の値を reviewer_personas に設定
  - 最初のトークンを issue_id に設定
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 前提チェック

- `docs/issues/{{issue_id}}/issue-struct.md` の存在を確認する
  - 存在しない場合：「先に `/tsumigi:issue_init {{issue_id}}` を実行してください」と言って終了する
- `docs/issues/{{issue_id}}/issue-struct.md` を Read する
- `docs/issues/{{issue_id}}/tasks.md` を Read する
- `docs/issues/{{issue_id}}/note.md` を存在する場合に Read する
- step3 を実行する

## step3: 冪等チェック（既存 IMP の確認）

- `docs/imps/{{issue_id}}/IMP.md` が存在するか確認する
  - 存在する かつ `--update` フラグなし：
    - IMP.md を Read して現在のバージョンを確認する
    - 「既存 IMP が見つかりました（ver: X.Y.Z）。--update を付けて再実行すると差分更新します」と表示する
    - AskUserQuestion ツールで確認する：
      - question: "続行しますか？"
      - options: ["更新する（--update 相当）", "現在の IMP を表示して終了", "中断する"]
  - 存在する かつ `--update` フラグあり：
    - IMP.md を Read してバージョンを確認し、マイナーバージョンをインクリメントする
    - 「差分更新モードで実行します（ver: X.Y.Z → X.Y+1.Z）」と表示する
  - 存在しない：
    - 「新規 IMP を生成します（ver: 1.0.0）」と表示する
- step4 を実行する

## step4: レビュアーペルソナの確認

- reviewer_personas が未設定の場合、AskUserQuestion ツールを使って質問する：
  - question: "想定するレビュアーのペルソナを選択してください"
  - header: "レビュアーペルソナ"
  - multiSelect: true
  - options:
    - label: "arch（アーキテクチャ）"
      description: "設計パターン・依存関係・スケーラビリティを重視"
    - label: "security（セキュリティ）"
      description: "認証認可・OWASP・機密情報取り扱いを重視"
    - label: "qa（品質保証）"
      description: "テストカバレッジ・エッジケース・非機能要件を重視"
  - 選択結果を context の {{reviewer_personas}} に保存する

## step5: 関連コンテキストの収集

- 以下を存在する場合に Read する：
  - `.tsumigi/config.json`
  - `.tsumigi/templates/IMP-template.md`
  - 既存の IMP ファイル（依存関係にある Issue のもの）: `docs/imps/**/*.md`

- 実装ファイルの現状を Glob で把握する（変更スコープの特定のため）：
  - `src/**/*.{ts,tsx,js,py,go,java}` など（技術スタックに応じて調整）

## step6: IMP 本体の生成

`docs/imps/{{issue_id}}/IMP.md` を生成する。
`.tsumigi/templates/IMP-template.md` が存在する場合はそれをベースにする。

以下のすべてのセクションを埋める：

**必須フィールド**（欠如すると品質チェックで警告）:
- `imp_id`, `imp_version`, `source_issue`, `created_at`, `status`, `drift_baseline`
- Executive Summary（3 行以内）
- 受け入れ基準（EARS 記法、issue-struct.md から転写・精緻化）
- 変更スコープ（ファイル・API・スキーマ）
- タスク詳細（tasks.md から転写・実装手順付き）
- テスト戦略
- ロールバック計画
- リスクマトリクス
- レビュアーチェックリスト（ペルソナ別）

**drift_baseline の設定**:
- `git rev-parse HEAD 2>/dev/null` が実行できる場合は Bash で取得する
- 取得できない場合は `"N/A"` を設定する

**IMP バージョニングルール**:
- 新規生成: `1.0.0`
- --update（受け入れ基準の変更なし）: パッチバージョンをインクリメント（例: 1.0.1）
- --update（受け入れ基準の変更あり）: マイナーバージョンをインクリメント（例: 1.1.0）
- 破壊的変更（スコープの大幅変更）: メジャーバージョンをインクリメント（例: 2.0.0）

## step7: IMP チェックリストの生成

`docs/imps/{{issue_id}}/IMP-checklist.md` を生成する。
選択されたペルソナに応じたチェックリストを作成する。

<imp_checklist_template>
---
imp_id: IMP-{{issue_id}}
imp_version: {{imp_version}}
generated_at: {{ISO8601}}
personas: {{reviewer_personas}}
---

# IMP レビューチェックリスト: {{issue_id}}

## 使い方
このチェックリストはレビュアーが IMP を承認する前に確認する項目です。
各項目を確認したら `[ ]` を `[x]` に変更してください。

---

## 共通チェック（全レビュアー必須）

- [ ] **Executive Summary** が 3 行以内で要点を伝えている
- [ ] **issue_id** が issue-struct.md の issue_id と一致している
- [ ] **受け入れ基準** が EARS 記法で記述されている
- [ ] **ロールバック計画** が具体的な手順で記述されている
- [ ] **🔴 不明項目** がゼロである（または着手前に解決済み）

---

## アーキテクチャレビュー（arch）
<!-- 選択されたペルソナが arch を含む場合のみ表示 -->

- [ ] 変更が既存アーキテクチャパターンと整合している
- [ ] 新たな外部依存の追加が適切に評価されている（セキュリティ・ライセンス）
- [ ] スケーラビリティへの影響が分析されている
- [ ] 設計の複雑度が最小限に抑えられている（YAGNI 原則）
- [ ] ロールバック計画が実行可能である（技術的に確認済み）
- [ ] 変更ファイル一覧に漏れがない

---

## セキュリティレビュー（security）
<!-- 選択されたペルソナが security を含む場合のみ表示 -->

- [ ] 認証・認可フローに抜け穴がない
- [ ] 秘密情報（シークレット・APIキー・パスワード）がコードに含まれていない
- [ ] 入力バリデーション・サニタイズが全入力ポイントで実装されている
- [ ] SQL インジェクション・XSS・CSRF のリスクが評価されている
- [ ] 監査ログが適切に記録される設計になっている
- [ ] 暗号化方式が現行のベストプラクティスに従っている

---

## QA レビュー（qa）
<!-- 選択されたペルソナが qa を含む場合のみ表示 -->

- [ ] 全ての受け入れ基準に対応するテストケースが定義されている
- [ ] 正常系・異常系・境界値が網羅されている
- [ ] テストが自動化可能な形で設計されている
- [ ] 既存テストスイートへの影響が評価されている
- [ ] パフォーマンス要件のテストが含まれている
- [ ] テストデータの管理方針が明確である

---

## 承認欄

| ペルソナ | 担当者 | 承認日時 | 備考 |
|---|---|---|---|
| arch | | | |
| security | | | |
| qa | | | |
</imp_checklist_template>

## step8: リスクマトリクスの生成

`docs/imps/{{issue_id}}/IMP-risks.md` を生成する。
issue-struct.md のリスクセクションと IMP の変更スコープを分析してリスクを特定する。

<imp_risks_template>
---
imp_id: IMP-{{issue_id}}
generated_at: {{ISO8601}}
---

# リスクマトリクス: {{issue_id}}

## リスク評価基準

| 軸 | H（高） | M（中） | L（低） |
|---|---|---|---|
| 影響度 | サービス停止・データ消失 | 一部機能の劣化 | UX の軽微な低下 |
| 発生確率 | 80%以上 | 30-80% | 30%未満 |

## リスク一覧

| # | リスク内容 | 影響度 | 発生確率 | 優先度 | 対策 | オーナー |
|---|---|---|---|---|---|---|
| R-001 | | H/M/L | H/M/L | 影響×確率 | | |

## 依存関係リスク

| 依存先 | リスク | 影響 | 緩和策 |
|---|---|---|---|
| | | | |

## 残留リスク（対策後も残るリスク）

| リスク | 残留理由 | 受容判断 |
|---|---|---|
| | | 受容済み/要監視/要対応 |
</imp_risks_template>

## step9: 完全性スコアの算出と表示

IMP の必須フィールド充足率を算出して表示する：

```
📊 IMP 完全性スコア: N/100

必須セクション:
  ✅ Executive Summary
  ✅ 受け入れ基準（EARS）
  ✅ 変更スコープ
  ✅ タスク詳細
  ✅ テスト戦略
  ✅ ロールバック計画
  ✅ リスクマトリクス
  ✅ レビュアーチェックリスト
  ⚠️ drift_baseline（git が未使用のため N/A）

信頼性サマリー:
  🔵 確定: N 件
  🟡 推定: N 件
  🔴 不明: N 件（着手前に解消が必要）
```

## step10: 完了通知

- 以下を表示する：
  ```
  ✅ imp_generate 完了: {{issue_id}} (ver {{imp_version}})

  生成ファイル:
    docs/imps/{{issue_id}}/IMP.md
    docs/imps/{{issue_id}}/IMP-checklist.md
    docs/imps/{{issue_id}}/IMP-risks.md

  次のステップ:
    実装を開始する:  /tsumigi:implement {{issue_id}}
    乾燥確認する:    /tsumigi:drift_check {{issue_id}}
    レビューを依頼:  IMP-checklist.md をレビュアーに共有する
  ```

- TodoWrite ツールでタスクを完了にマークする
