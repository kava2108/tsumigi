---
description: 自然言語入力を tsumigi コマンドにルーティングします。ユーザーが何をしたいかを分析し、適切な /tsumigi コマンドを提案・実行します。「何をすべきか教えて」にも対応します。
allowed-tools: Read, Glob, AskUserQuestion, TodoWrite
argument-hint: "[自然言語の指示]"
---

# tsumigi cli

自然言語入力を tsumigi コマンドにルーティングします。
「何をしたいか」を伝えるだけで、適切なコマンドを提案・実行します。

# context

query={{query}}
detected_issue_id={{detected_issue_id}}
suggested_command={{suggested_command}}

# step

- $ARGUMENTS の内容を query に設定する
- $ARGUMENTS がない場合は AskUserQuestion ツールを使って質問する：
  - question: "何をしたいですか？（issue-id と一緒に教えてください）"
  - header: "tsumigi に何をさせますか？"
  - multiSelect: false
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 現状把握（必要な場合）

クエリに issue_id らしき文字列が含まれない場合：
- `.tsumigi/config.json` を存在する場合に Read する
- `docs/issues/` を Glob して存在する issue_id 一覧を取得する
- `docs/imps/` を Glob して IMP 済みの issue_id 一覧を取得する
- AskUserQuestion で対象 issue を選択させる

## step3: クエリの解析とコマンドのルーティング

クエリから以下を読み取り、適切なコマンドを提案する：

---

**Issue 起こし・初期化に関するクエリ**:
- 「〜から作業を始めたい」「Issue を整理したい」「タスクに落としたい」
- 「GH-XXX をやりたい」「Issue XXX の作業を始める」
→ 提案: `/tsumigi:issue_init <issue-id>`

---

**IMP 生成に関するクエリ**:
- 「IMP を作って」「実装計画を作りたい」「設計書を作って」
- 「Issue を IMP にして」「計画を立てて」
→ 提案: `/tsumigi:imp_generate <issue-id>`

**IMP 更新に関するクエリ**:
- 「IMP を更新したい」「IMP を直したい」「計画が変わった」
→ 提案: `/tsumigi:imp_generate <issue-id> --update`

---

**実装に関するクエリ**:
- 「実装して」「コードを書いて」「TDD で実装して」
- 「〜を作って」「〜を実装する」
→ 提案: `/tsumigi:implement <issue-id> [--mode tdd|direct]`

**特定タスクの実装**:
- 「TASK-XXX を実装して」「最初のタスクから始めて」
→ 提案: `/tsumigi:implement <issue-id> TASK-XXX`

**乾燥確認なしの実装**:
- 「まずどんな変更か見てみたい」「ドライランで」
→ 提案: `/tsumigi:implement <issue-id> --dry-run`

---

**テストに関するクエリ**:
- 「テストを作って」「テストケースを洗い出して」「テスト方針を決めて」
→ 提案: `/tsumigi:test <issue-id>`

**テスト実行に関するクエリ**:
- 「テストを実行して」「テストして結果を確認したい」
→ 提案: `/tsumigi:test <issue-id> --exec`

**セキュリティテスト**:
- 「セキュリティテストを追加して」「脆弱性を確認したい」
→ 提案: `/tsumigi:test <issue-id> --focus security`

---

**逆仕様生成に関するクエリ**:
- 「仕様書を生成して」「実装からドキュメントを作って」「逆仕様を書いて」
- 「API 仕様書を作って」「スキーマを文書化して」
→ 提案: `/tsumigi:rev <issue-id>`

---

**乖離検出に関するクエリ**:
- 「仕様と実装がずれていないか確認して」「drift を確認して」
- 「IMP と実装が合ってるか見て」「乖離を調べて」
→ 提案: `/tsumigi:drift_check <issue-id>`

---

**同期・整合性確認に関するクエリ**:
- 「全部整合してるか確認して」「sync して」
- 「成果物が揃っているか確認して」「整合性をチェックして」
→ 提案: `/tsumigi:sync <issue-id> --report-only`

**自動修正も含めた同期**:
- 「整合性を直して」「sync して修正も」
→ 提案: `/tsumigi:sync <issue-id> --fix`

---

**レビューに関するクエリ**:
- 「レビュー資料を作って」「チェックリストを作って」
- 「PR のレビューをして」「リスクを整理して」
→ 提案: `/tsumigi:review <issue-id> --persona all`

**特定ペルソナのレビュー**:
- 「セキュリティ観点でレビューして」「セキュリティを確認して」
→ 提案: `/tsumigi:review <issue-id> --persona security`
- 「アーキテクチャ観点で」「設計をレビューして」
→ 提案: `/tsumigi:review <issue-id> --persona arch`
- 「テスト観点で」「品質観点で」
→ 提案: `/tsumigi:review <issue-id> --persona qa`

**PR レビュー**:
- 「PR XXX をレビューして」「PR のチェックリストを作って」
→ 提案: `/tsumigi:review <issue-id> --pr <pr-number>`

---

**インストール・セットアップに関するクエリ**:
- 「tsumigi を使い始めたい」「セットアップして」「初期化して」
→ 提案: `/tsumigi:install`

---

**ヘルプに関するクエリ**:
- 「何ができるか教えて」「使い方を教えて」「コマンド一覧を見たい」
→ 提案: `/tsumigi:help`

---

**「次に何をすべきか」に関するクエリ**:
- 「次は何をすればいい？」「どこまで進んだっけ？」「次のステップは？」
→ step4 を実行する（現状分析）

---

**複合クエリ（複数コマンドが必要）**:
- 「Issue から実装まで全部やって」「一通り流して」
→ 複数コマンドのシーケンスを提案する

---

## step4: 現状分析（「次に何をすべきか」の場合）

issue_id が特定されている場合：
- 以下の成果物の存在を Glob で確認する：
  - `docs/issues/{{issue_id}}/issue-struct.md` → issue_init 完了？
  - `docs/imps/{{issue_id}}/IMP.md` → imp_generate 完了？
  - `docs/implements/{{issue_id}}/` → implement 着手？
  - `docs/tests/{{issue_id}}/` → test 実施済み？
  - `docs/specs/{{issue_id}}/` → rev 実施済み？
  - `docs/drift/{{issue_id}}/` → drift_check 実施済み？
  - `docs/sync/{{issue_id}}/` → sync 実施済み？
  - `docs/reviews/{{issue_id}}/` → review 実施済み？

- 現在の進捗を表示する：
  ```
  📊 {{issue_id}} の進捗状況:

  ✅ issue_init   — docs/issues/{{issue_id}}/ 存在
  ✅ imp_generate — docs/imps/{{issue_id}}/IMP.md 存在
  🔄 implement    — 着手中 (TASK-0001 完了, TASK-0002 未着手)
  ❌ test         — 未実施
  ❌ rev          — 未実施
  ❌ drift_check  — 未実施
  ❌ sync         — 未実施
  ❌ review       — 未実施

  次の推奨コマンド:
    /tsumigi:implement {{issue_id}} TASK-0002
  ```

## step5: コマンドの提案と実行確認

提案するコマンドを表示する。

- AskUserQuestion ツールを使って確認する：
  - question: "提案コマンドを実行しますか？"
  - header: "コマンド確認"
  - multiSelect: false
  - options:
    - label: "実行する"
    - label: "コマンドを変更する"
    - label: "実行しない（確認のみ）"

- 「実行する」が選択された場合：
  - 「提案コマンドを実行します: `{{suggested_command}}`」と表示する
  - **重要**: 実際のコマンド実行は Claude Code のコマンドディスパッチャーに委ねる

- 「コマンドを変更する」が選択された場合：
  - AskUserQuestion でどう変更するかを確認する
  - step3 に戻る

- 「実行しない」が選択された場合：
  - コマンドをコピーしやすい形で再表示して終了する
