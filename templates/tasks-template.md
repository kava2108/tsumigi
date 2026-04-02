---
issue_id: {{issue_id}}
created_at: {{ISO8601}}
updated_at: {{ISO8601}}
total_tasks: N
---

# タスク一覧: {{issue_id}}

## タスクマップ

```
TASK-0001 → TASK-0002 → TASK-0003
               ↓
            TASK-0004
```

## タスク詳細

### TASK-0001: {{タスク名}}

**概要**: {{1 行の説明}}

**完了条件（EARS）**:
- [WHEN] ... [THE SYSTEM SHALL] ...

**作業内容**:
1.
2.

**推定規模**: S/M/L（S=半日, M=1日, L=2日以上）

**依存前提**: なし / TASK-XXXX 完了後

---

（以降、同形式で続く）

## 実行推奨順序

1. TASK-0001（依存なし）
2. TASK-0002（TASK-0001 完了後）
...
