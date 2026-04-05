---
tsumigi:
  node_id: "impl:tsumigi-v3-harness:T07"
  artifact_type: "patch_plan"
  phase: "IMP"
  issue_id: "tsumigi-v3-harness"
  task_id: "T07"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "impl:tsumigi-v3-harness:T07"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "implements"
      confidence: 0.95
      required: true
    - id: "impl:tsumigi-v3-harness:T01"
      relation: "depends_on"
      confidence: 0.9
      required: true
    - id: "impl:tsumigi-v3-harness:T02"
      relation: "depends_on"
      confidence: 1.0
      required: true
  band: "Green"
---

# Patch Plan: T07 — coherence-scan / baton-status

**Issue**: [#7](https://github.com/kava2108/tsumigi/issues/7)  
**IMP バージョン**: 1.1.0  
**実装日**: 2026-04-05

---

## 変更対象ファイル

| ファイル | 操作 | 状態 |
|---------|------|------|
| `commands/coherence-scan.md` | 新規作成 | ✅ 実装済み |
| `commands/baton-status.md` | 新規作成 | ✅ 実装済み |

---

## 実装内容

### coherence-scan — 5ステップアルゴリズム

| Step | 処理 |
|------|------|
| Step 1 | Glob スキャン: `.kiro/**/*.md`, `specs/**/*.md`, etc. の frontmatter 収集 |
| Step 2 | ノードビルド: `coherence.id` を key に CEG ノードマップを構築 |
| Step 3 | エッジビルド: `depends_on` リストからエッジを構築 |
| Step 4 | 検証: 循環依存（DFS）・ダングリング参照・バンド整合性チェック |
| Step 5 | 書き出し: `graph/coherence.json` に差分マージ |

### バンド評価基準

| バンド | 条件 |
|--------|------|
| Green | required 依存が全て解決済み、循環なし |
| Amber | ダングリング参照あり、または confidence < 0.7 |
| Red | 循環依存検出、または required 依存が欠落 |

### 循環依存検出

DFS（深さ優先探索）で `depends_on` グラフを走査。  
訪問スタックにノードが既に存在する場合を循環とみなし、Red バンドに分類。

### baton-status — 4 カテゴリ表示

| カテゴリ | 内容 |
|---------|------|
| Current Phase | 最新の `phase:*` ラベル |
| Pending Batons | `pending:next-phase` ラベルがある Issue |
| Blocked Issues | `blocked` ラベルがある Issue |
| Escalated Issues | `escalate` ラベルがある Issue |

---

## AC 対応トレーサビリティ

| AC-ID | 実装箇所 |
|-------|---------|
| REQ-004-AC-2 | `commands/baton-status.md` — 4 カテゴリ表示 |
| REQ-005-AC-2 | `commands/coherence-scan.md` — DFS 循環依存検出 |
| REQ-005-AC-3 | `commands/coherence-scan.md` — ダングリング参照 → Amber バンド |

---

## テスト観点

| TC-ID | 確認内容 |
|-------|---------|
| TC-T07-01 | `coherence-scan` が `graph/coherence.json` を生成する |
| TC-T07-02 | 循環依存がある場合に Red バンドで検出される |
| TC-T07-03 | ダングリング参照（存在しない node_id への depends_on）が Amber バンドになる |
| TC-T07-04 | `baton-status` が blocked / escalated Issue を正しく分類する |
| TC-T07-05 | 再実行（idempotent）時に `coherence.json` が重複エントリなく更新される |
