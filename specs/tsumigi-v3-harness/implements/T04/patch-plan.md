---
tsumigi:
  node_id: "impl:tsumigi-v3-harness:T04"
  artifact_type: "patch_plan"
  phase: "IMP"
  issue_id: "tsumigi-v3-harness"
  task_id: "T04"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "impl:tsumigi-v3-harness:T04"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "implements"
      confidence: 0.95
      required: true
  band: "Green"
---

# Patch Plan: T04 — Phase Agent システムプロンプト（REQ/TDS/IMP）

**Issue**: [#4](https://github.com/kava2108/tsumigi/issues/4)  
**IMP バージョン**: 1.1.0  
**実装日**: 2026-04-05

---

## 変更対象ファイル

| ファイル | 操作 | 状態 |
|---------|------|------|
| `.tsumigi/agents/requirements-agent.md` | 新規作成 | ✅ 実装済み |
| `.tsumigi/agents/design-agent.md` | 新規作成 | ✅ 実装済み |
| `.tsumigi/agents/implement-agent.md` | 新規作成 | ✅ 実装済み |

---

## 実装内容

各 Agent ファイルは TDS §16.3 の 8 セクション構造を完全に実装している。

### `requirements-agent.md` — RequirementsAgent

**担当**: RequirementsInterviewer + EARSFormatter + RequirementsValidator

主要ロジック:
- AC が 3 件未満の場合: RequirementsInterviewer モードに切り替え、5W1H 質問を GitHub コメントに投稿
- EARS 記法変換（WHEN/IF/WHILE 形式）
- AC-ID の重複チェックと EARS 形式バリデーション
- CEG frontmatter 付き `requirements.md` の生成
- Phase Gate（REQ→TDS）の実行

**コンテキスト分離（読んではいけないもの）**:
- `specs/` 以下の IMP.md・patch-plan.md
- 他 Issue の requirements.md
- テストファイル・実装コード

### `design-agent.md` — DesignAgent

**担当**: ArchDesigner + APIDesigner + SchemaDesigner + TaskSplitter + IssueGenerator

主要ロジック:
- requirements.md を読んでアーキテクチャ・インターフェース・スキーマを設計
- P0/P1 波形でタスク分割（`tasks.md` 生成）
- harness.enabled=true の場合のみ GitHub Issue を `gh issue create` で生成
- CEG frontmatter 付き `design.md` + `tasks.md` の生成
- Phase Gate（TDS→IMP）の実行

### `implement-agent.md` — ImplementAgent

**担当**: IMPGenerator + Implementer

主要ロジック:
- IMP.md が存在しない場合は先に `imp_generate` を実行
- P0 タスクの実装（patch-plan.md + 実装コード）
- P0 完了後に P1 タスクの Issue に `phase:imp` を付与（wave:P0/P1 ラベル参照）
- CEG frontmatter 付き patch-plan.md の生成
- Phase Gate（IMP→TEST）の実行

---

## AC 対応トレーサビリティ

| AC-ID | 実装箇所 |
|-------|---------|
| REQ-007-AC-1 | `requirements-agent.md` — 起動後に `requirements.md` を生成 |
| REQ-007-AC-2 | 各 Agent の「リトライポリシー」セクション（3 回失敗後に `blocked:escalate`） |

---

## テスト観点

| TC-ID | 確認内容 |
|-------|---------|
| TC-T04-01 | RequirementsAgent 起動後に `requirements.md` が生成される（e2e） |
| TC-T04-02 | 3 回リトライ後に `blocked:escalate` が付与される（integration） |
| TC-T04-03 | Issue body が空の時 RequirementsInterviewer モードになる |
| TC-T04-04 | P0 タスク完了後に P1 Issue の `phase:imp` が付与される |
