## 概要

{{executive_summary}}

---

## 関連 Issue

Closes #{{github_issue_number}}

## 実装サマリー

| 項目 | 値 |
|---|---|
| IMP バージョン | {{imp_version}} |
| drift スコア | {{drift_score}}/100 |
| 整合性スコア | {{sync_score}}/100 |
| 実装モード | {{impl_mode}} |

## 成果物

| ドキュメント | パス |
|---|---|
| IMP（実装管理計画書） | `docs/imps/{{issue_id}}/IMP.md` |
| レビューチェックリスト | `docs/reviews/{{issue_id}}/review-checklist.md` |
| リスクマトリクス | `docs/reviews/{{issue_id}}/risk-matrix.md` |
| 乖離レポート | `docs/drift/{{issue_id}}/drift-report.md` |

## チェックリスト（マージ前確認）

- [ ] drift スコアが 20 以下である
- [ ] 整合性スコアが 70 以上である
- [ ] 全 P0 テストが通過している
- [ ] IMP-checklist.md のレビューが完了している

---

🤖 Generated with [tsumigi](https://github.com/kava2108/tsumigi)
