---
tsumigi:
  node_id: "test:tsumigi-v3-harness:T02"
  artifact_type: "testcases"
  phase: "TEST"
  issue_id: "tsumigi-v3-harness"
  task_id: "T02"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "test:tsumigi-v3-harness:T02"
  depends_on:
    - id: "impl:tsumigi-v3-harness:T02"
      relation: "verifies"
      confidence: 1.0
      required: true
    - id: "imp:tsumigi-v3-harness"
      relation: "derives_from"
      confidence: 0.95
      required: true
  band: "Green"
---

# テストケースマトリクス: tsumigi-v3-harness / T02

**対象タスク**: T02 — CEG frontmatter 標準化  
**生成日**: 2026-04-05  
**フォーカス**: unit, integration

---

## カバレッジサマリー

| AC | 正常系 | 異常系 | 境界値 | 合計 | カバー状況 |
|---|---|---|---|---|---|
| REQ-005-AC-1 | 3 | 1 | 0 | 4 | ✅ |

カバレッジ率: 1/1 AC = **100%**

---

## 正常系テストケース

### TC-T02-01: imp_generate 実行後の IMP.md に coherence frontmatter が存在する

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-005-AC-1 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | frontmatter なしの IMP.md ドラフトが存在する |
| **入力** | `imp_generate` コマンドの frontmatter 付与ステップを実行 |
| **操作** | 生成された IMP.md の先頭を確認 |
| **期待結果** | ファイル先頭に `---\ntsumigi:\n  node_id: "imp:..."` が存在し、`coherence:` セクションも含まれる |
| **信頼性** | 🔵 確定 |

---

### TC-T02-02: implement 実行後の patch-plan.md に frontmatter が存在する

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-005-AC-1 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `specs/<issue-id>/implements/<task-id>/` ディレクトリが存在する |
| **入力** | `implement.md` の patch-plan 生成ステップを実行 |
| **操作** | 生成された `patch-plan.md` の先頭を確認 |
| **期待結果** | `node_id: "impl:..."` および `depends_on:` エントリが含まれる frontmatter が存在する |
| **信頼性** | 🔵 確定 |

---

### TC-T02-03: rev 実行後の rev-api.md に frontmatter が存在する

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-005-AC-1 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `rev.md` コマンドでの rev-api.md 生成対象が存在する |
| **入力** | `rev.md` の Step5（frontmatter 付与）を実行 |
| **操作** | 生成された `rev-*.md` ファイルの先頭を確認 |
| **期待結果** | `artifact_type: "rev-api"` または対応する type の frontmatter が先頭に存在する |
| **信頼性** | 🔵 確定 |

---

## 異常系テストケース

### TC-T02-04: 既存 IMP.md に frontmatter がある場合、重複付与されない

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-005-AC-1 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | IMP.md の先頭に既に `---\ntsumigi:...---` が存在する（再実行シナリオ） |
| **入力** | `imp_generate` の frontmatter 付与ステップを再実行 |
| **操作** | IMP.md の `---` 出現回数を確認 |
| **期待結果** | `---` が先頭に 2 回（開始・終了で 1 セット）のみ存在し、frontmatter の重複がない |
| **信頼性** | 🔵 確定 |

---

### TC-T02-05: feature 推論が失敗した場合、警告が出て処理が継続される

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P1 |
| **レイヤー** | unit |
| **前提条件** | `.kiro/specs/` 以下に issue-id に対応するディレクトリが存在しない |
| **入力** | `imp_generate` コマンドを実行 |
| **操作** | feature 推論ステップの出力を確認 |
| **期待結果** | `feature: "unknown"` として frontmatter に記録され、警告メッセージが出力されて処理は完了する |
| **信頼性** | 🔵 確定 |

---

## 境界値テストケース

### TC-T02-06: git が初期化されていない場合 drift_baseline が空文字になる

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P2 |
| **レイヤー** | unit |
| **前提条件** | `.git` ディレクトリが存在しない（または `git rev-parse HEAD` が失敗する環境） |
| **入力** | frontmatter 生成処理を実行 |
| **操作** | 生成された frontmatter の `drift_baseline` を確認 |
| **期待結果** | `drift_baseline: ""` として空文字が記録され、エラーで停止しない |
| **信頼性** | 🔵 確定 |

---

## 未カバーケース（手動テスト推奨）

| # | 内容 | 理由 | 推奨対応 |
|---|---|---|---|
| 1 | 10 万行のドキュメントファイルへの frontmatter 付与パフォーマンス | 実スケールデータが必要 | 手動確認 |
