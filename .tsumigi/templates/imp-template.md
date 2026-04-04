<!--
{
  "ceg": {
    "phase": "imp",
    "auto_step": false,
    "source": "design.md",
    "generated_by": "Claude"
  }
}
-->
---
tsumigi:
  node_id: "imp:{{issue_id}}"
  artifact_type: "imp"
  phase: "IMP"
  issue_id: "{{issue_id}}"
  feature: "{{feature_name}}"
  imp_version: "{{imp_version}}"
  status: "active"
  created_at: "{{created_at}}"
  updated_at: "{{updated_at}}"
  drift_baseline: "{{drift_baseline}}"
coherence:
  id: "imp:{{issue_id}}"
  depends_on:
    - id: "req:{{feature_name}}"
      relation: "implements"
      confidence: 0.95
      required: true
    - id: "design:{{feature_name}}"
      relation: "derives_from"
      confidence: 0.95
      required: true
  modules: []
  band: "Green"
  last_validated: "{{created_at}}"
baton:
  phase: "imp"
  auto_step: false
  pending_label: "pending:next-phase"
  issue_number: null
---

# Implementation Plan（IMP）: {{issue_id}}

**Feature**: `{{feature_name}}`  
**IMP バージョン**: {{imp_version}}  
**対象 Issue**: {{issue_id}}  
**作成日**: {{created_at}}  
**AUTO_STEP**: false（Manual Baton Mode 前提）

---

## 0. IMP Overview

### Executive Summary

（3 行以内で変更の目的・範囲・期待効果を記述）

### 対象タスクと波形

| 波形 | タスク | 内容 | 並列可否 |
|------|--------|------|---------|
| **P0** | T01 | ... | ✅ 並列可 |

---

## 1. Task Specifications

---

### T01: （タスク名）

#### 1.1 Purpose

（このタスクの目的・背景）

#### 1.2 Inputs

| 入力 | 型・形式 | 説明 |
|------|---------|------|
| | | |

**依存タスク**: （依存するタスク or なし）

#### 1.3 Outputs

| 出力ファイル | 操作 | 内容 |
|------------|------|------|
| | | |

#### 1.4 Implementation Strategy

（実装の具体的なアルゴリズム・方針を記述）

#### 1.5 Edge Cases / Exceptions

| ケース | 対処 |
|--------|------|
| | |

#### 1.6 Test Strategy

| TC-ID | AC-ID | テスト観点 | レイヤー |
|-------|-------|----------|---------|
| | | | |

---

## 2. Patch Plan（実装パッチ計画）

### 2.1 実装順序

```
P0 タスク（並列実行可能なもの）:
  Day 1-2: T01

P1 タスク:
  Day 3-4: （P1 タスク）
```

---

## 3. I/O Traceability

| タスク | 読むファイル | 書くファイル | GitHub API |
|--------|------------|------------|-----------|
| **T01** | | | |

---

## 4. AC Traceability

| AC-ID | EARS 記法（要約） | 対応タスク |
|-------|----------------|----------|
| | | |

---

## 5. リスクマトリクス

| リスク | 発生確率 | 影響度 | 対応 |
|--------|---------|--------|------|
| | | | |

---

## 6. ロールバック計画

（変更を取り消す手順を記述）

---

## 7. レビュアーチェックリスト

### Architecture（arch）
- [ ] 設計パターンとの整合性
- [ ] レイヤー境界の遵守
- [ ] スケーラビリティへの影響

### Security（security）
- [ ] 認証・認可の網羅性
- [ ] 入力バリデーションの実装
- [ ] 機密情報の扱い

### QA（qa）
- [ ] テストカバレッジ
- [ ] エッジケースの考慮
- [ ] 非機能要件の充足
