---
issue_id: {{issue_id}}
run_at: {{ISO8601}}
consistency_score: N
status: Excellent/Good/Fair/Poor
---

# 整合性レポート: {{issue_id}}

## スコアサマリー

```
整合性スコア: N/100 — [Excellent/Good/Fair/Poor]

チェック1 Issue ↔ IMP:      N/20  [Pass/Warn/Fail]
チェック2 IMP ↔ 実装:       N/25  [Pass/Warn/Fail]
チェック3 IMP ↔ テスト:     N/25  [Pass/Warn/Fail]
チェック4 実装 ↔ 逆仕様:    N/15  [Pass/Warn/Fail]
チェック5 逆仕様 ↔ Issue:   N/15  [Pass/Warn/Fail]
```

---

## チェック詳細

### チェック1: Issue ↔ IMP（N/20点）

| 項目 | 結果 | 詳細 |
|---|---|---|
| 受け入れ基準の転写 | ✅/⚠️/❌ | |
| タスク対応 | ✅/⚠️/❌ | |
| issue_id 一致 | ✅/⚠️/❌ | |
| 非機能要件の反映 | ✅/⚠️/❌ | |

（以降、チェック2〜5を同形式で記述）

---

## 不整合一覧

| # | 種別 | 内容 | 影響度 | 自動修正? |
|---|---|---|---|---|
| SY-001 | IMP未反映 | issue-struct の AC-003 が IMP に未記載 | H | ❌ 手動対応 |
| SY-002 | バージョン不一致 | IMP v1.0.0 だが patch-plan は v0.9.0 | M | ✅ 自動修正可 |

---

## 前回実行との比較

| 前回スコア | 今回スコア | 変化 |
|---|---|---|
| N | N | ↑N点改善 / ↓N点悪化 / 変化なし |

---

## 次のアクション

### 自動修正済み（--fix 実行時）
- [x] SY-002: patch-plan の imp_version を更新

### 手動対応が必要
→ `docs/sync/{{issue_id}}/sync-actions.md` を参照
