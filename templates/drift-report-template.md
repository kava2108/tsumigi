---
issue_id: {{issue_id}}
run_id: {{run_id}}
run_at: {{ISO8601}}
imp_version: {{imp_version}}
drift_baseline: {{drift_baseline}}
drift_score: N
threshold: {{threshold}}
status: Aligned/Minor/Significant/Critical
---

# 乖離レポート: {{issue_id}}

## スコアサマリー

```
drift スコア: N/100 — [Aligned/Minor Drift/Significant Drift/Critical Drift]

CRITICAL: N件 (×10点 = N点)
WARNING:  N件 (×3点  = N点)
INFO:     N件 (×1点  = N点)
合計:     N点
```

---

## D1: 機能仕様の乖離

| AC | テスト | 実装 | 判定 | スコア |
|---|---|---|---|---|
| AC-001 | ✅ | ✅ | COVERED | 0 |
| AC-002 | ❌ | ✅ | PARTIAL | +3 |
| AC-003 | ❌ | ❌ | MISSING | +10 |

**D1 小計**: N点

---

## D2: API 契約の乖離

| エンドポイント | IMP 仕様 | 実装 | 乖離内容 | 判定 | スコア |
|---|---|---|---|---|---|
| GET /api/users | `{id, name}` | `{id, name, email}` | レスポンス構造の追加 | WARNING | +3 |

**D2 小計**: N点

---

## D3: スキーマの乖離

| スキーマ変更 | IMP 仕様 | 実装 | 乖離内容 | 判定 | スコア |
|---|---|---|---|---|---|
| | | | | | |

**D3 小計**: N点

---

## D4: テストカバレッジの乖離

| テスト種別 | IMP 目標 | 実際 | 乖離 | 判定 | スコア |
|---|---|---|---|---|---|
| Unit カバレッジ | 90% | 75% | -15% | WARNING | +3 |

**D4 小計**: N点

---

## D5: タスク完了状態の乖離

| タスク | 状態 | 判定 | スコア |
|---|---|---|---|
| TASK-0001 | patch-plan あり / チェック完了 | INFO | +0 |
| TASK-0002 | patch-plan なし | INFO | +1 |

**D5 小計**: N点

---

## 推奨アクション

### CRITICAL（即時対応）
- AC-003 の実装とテストが存在しない → `/tsumigi:implement {{issue_id}} TASK-XXXX` を実行する

### WARNING（早期対応）
- AC-002 のテストを追加する → `/tsumigi:test {{issue_id}}`
- IMP の API 仕様を実装に合わせて更新する → `/tsumigi:imp_generate {{issue_id}} --update`

### INFO（任意対応）
- TASK-0002 の実装着手 → `/tsumigi:implement {{issue_id}} TASK-0002`

---

## 前回との比較

| 指標 | 前回 | 今回 | 変化 |
|---|---|---|---|
| drift スコア | N | N | ↑N改善 / ↓N悪化 |
| CRITICAL | N | N | |
| WARNING | N | N | |
