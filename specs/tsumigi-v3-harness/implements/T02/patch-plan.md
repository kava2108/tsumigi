---
tsumigi:
  node_id: "impl:tsumigi-v3-harness:T02"
  artifact_type: "patch_plan"
  phase: "IMP"
  issue_id: "tsumigi-v3-harness"
  task_id: "T02"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "impl:tsumigi-v3-harness:T02"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "implements"
      confidence: 0.95
      required: true
  band: "Green"
---

# Patch Plan: T02 — CEG frontmatter 標準化

**Issue**: [#2](https://github.com/kava2108/tsumigi/issues/2)  
**IMP バージョン**: 1.1.0  
**実装日**: 2026-04-05

---

## 変更対象ファイル

| ファイル | 操作 | 状態 |
|---------|------|------|
| `commands/imp_generate.md` | 更新（step6 に frontmatter 付与ステップ追加） | ✅ 実装済み |
| `commands/implement.md` | 更新（step9 に frontmatter 付与ステップ追加） | ✅ 実装済み |
| `commands/rev.md` | 更新（step5 に frontmatter 付与ステップ追加） | ✅ 実装済み |
| `.tsumigi/templates/imp-template.md` | 新規作成（frontmatter 付き IMP ひな形） | ✅ 実装済み |

---

## 実装内容

### `commands/imp_generate.md` — step6 への追加

IMP.md 生成時に CEG frontmatter を先頭に付与するステップを追加：

```yaml
---
tsumigi:
  node_id: "imp:<issue-id>"
  artifact_type: "imp"
  phase: "IMP"
  feature: "<feature-name>"   # .kiro/specs/ から推論
  imp_version: "1.0.0"
  drift_baseline: "<git rev-parse HEAD>"
coherence:
  id: "imp:<issue-id>"
  depends_on:
    - id: "req:<feature>"
      relation: "implements"
      confidence: 0.95
    - id: "design:<feature>"
      relation: "derives_from"
      confidence: 0.95
  band: "Green"
baton:
  phase: "imp"
  auto_step: false
  issue_number: <N>
---
```

### `commands/implement.md` — step9 への追加

patch-plan.md 生成時に frontmatter を付与（`node_id: "impl:<issue-id>:<task-id>"`）

### `commands/rev.md` — step5 への追加

rev-*.md 生成時にそれぞれ frontmatter を付与：
- `rev-spec.md` → `node_id: "rev-spec:<issue-id>"`
- `rev-api.md` → `node_id: "rev-api:<issue-id>"`
- `rev-schema.md` → `node_id: "rev-schema:<issue-id>"`

### `feature` の推論ロジック

```
1. .kiro/specs/ 以下のサブディレクトリを列挙
2. tasks.md に <issue-id> が含まれるディレクトリを feature とみなす
3. 見つからない場合は feature: "unknown" + 警告
```

### `drift_baseline` の取得

```bash
git rev-parse HEAD 2>/dev/null || echo ""
```

---

## AC 対応トレーサビリティ

| AC-ID | 実装箇所 |
|-------|---------|
| REQ-005-AC-1 | `imp_generate.md` step6 / `implement.md` step9 / `rev.md` step5 に frontmatter 付与ステップ追加 |

---

## テスト観点

| TC-ID | 確認内容 |
|-------|---------|
| TC-T02-01 | `imp_generate` 実行後の IMP.md に coherence frontmatter が存在する |
| TC-T02-02 | `implement` 実行後の patch-plan.md に frontmatter が存在する |
| TC-T02-03 | 既存 IMP.md に frontmatter がある場合、重複付与されない（`---` 検出でスキップ） |
| TC-T02-04 | `feature` 推論が失敗した場合、警告が出て処理が継続される |
