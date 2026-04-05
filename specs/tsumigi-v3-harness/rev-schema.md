---
tsumigi:
  node_id: "rev-schema:tsumigi-v3-harness"
  artifact_type: "rev_schema"
  phase: "OPS"
  issue_id: "tsumigi-v3-harness"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "rev-schema:tsumigi-v3-harness"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "reverse_of"
      confidence: 0.90
      required: false
  band: "Green"
---

# 逆生成スキーマ仕様書: tsumigi-v3-harness

> tsumigi v3.0 のデータスキーマは YAML / JSON / Markdown frontmatter の 3 形式で構成されます。

---

## データモデル概要

```
.vckd/config.yaml          設定スキーマ（静的）
       │
       ├── harness.enabled ─ .tsumigi/lib/phase-gate.sh
       └── harness.AUTO_STEP

graph/baton-log.json        バトンログスキーマ（動的）
  ├── transitions[]         完了した遷移の履歴
  └── pending{}             承認待ちエントリ（issue_number → 次フェーズ）

graph/coherence.json        CEG スキーマ（coherence-scan で再生成）
  ├── nodes{}               全成果物ノード（coherence.id → ノード属性）
  └── edges[]               depends_on エッジのリスト

Markdown frontmatter        各成果物ファイルの先頭に埋め込まれるメタデータ
  ├── tsumigi:              成果物メタデータ
  ├── coherence:            CEG 接続情報
  └── baton:                バトン状態
```

---

## 1. `.vckd/config.yaml`

実装から読み取った実際のスキーマ（`.vckd/config.yaml`、`_get_config()` 関数参照）:

```yaml
harness:
  enabled: boolean          # true = Harness 有効（デフォルト: false）
  AUTO_STEP: boolean        # true = 自律モード（デフォルト: false）
  mode: string              # "claude-code-hooks" | "github-actions"
  baton:
    post_comment: boolean   # Issue にコメントを投稿するか（デフォルト: true）
    pending_label: string   # 承認待ちラベル名（デフォルト: "pending:next-phase"）
    approve_label: string   # 承認ラベル名（デフォルト: "approve"）

kiro:
  use_cc_sdd: string        # "auto" | "always" | "never"
  kiro_dir: string          # Kiro 設定ディレクトリ（デフォルト: ".kiro"）

codd:
  cli_path: string | null   # CoDD CLI のパス（null = 無効）
```

**フォールバック** (`_get_config()` 実装より):
- `yq` 未インストール時: 全スカラーがデフォルト値にフォールバック
- `config.yaml` 不在時: 全スカラーがデフォルト値にフォールバック

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L20-48, `.vckd/config.yaml`

---

## 2. `graph/baton-log.json`

実装から読み取った実際のスキーマ（`_append_transition()`, `increment_retry_count()` 等参照）:

```json
{
  "version": "1.0.0",

  "transitions": [
    {
      "issue_number": 42,           // integer: GitHub Issue 番号
      "from_label": "phase:req",    // string
      "to_label": "phase:tds",      // string | "blocked:xxx" | "pending:next-phase"
      "transitioned_at": "ISO8601", // string: UTC タイムスタンプ
      "mode": "auto",               // "auto" | "manual" | "blocked"
      "triggered_by": "phase_gate"  // string: 発火源識別子
    }
  ],

  "pending": {
    "<issue_number>": {
      "next": "phase:tds",          // string: 承認後に付与するラベル
      "recorded_at": "ISO8601",     // string
      "retries": 0,                 // integer: 現在のリトライ回数
      "last_error": null,           // string | null: 最後のエラーメッセージ
      "agent": null                 // string | null: 失敗したエージェント名
    }
  }
}
```

**初期値**: `{"version":"1.0.0","transitions":[],"pending":{}}`  
**バリデーション**: `jq empty` で JSON 整合性確認。失敗時は `.bak` にリネームして再初期化  
**アトミック書き込み**: `mktemp` → `jq` → `mv` パターン

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L50-110（`_ensure_baton_log`, `_append_transition`）

---

## 3. `graph/coherence.json`

実装から読み取った実際のスキーマ（`coherence-scan.md` の Step5 参照）:

```json
{
  "version": "1.0.0",

  "nodes": {
    "<coherence.id>": {
      "artifact_type": "imp",        // string: IMP の tsumigi.artifact_type
      "phase": "IMP",               // string
      "band": "Green",              // "Green" | "Amber" | "Gray" | "Red"
      "file": "specs/xxx/IMP.md",  // string: ファイルパス
      "confidence": 0.95,           // float: 依存エッジ全体の最低 confidence
      "last_scanned": "ISO8601"     // string
    }
  },

  "edges": [
    {
      "from": "imp:tsumigi-v3-harness",
      "to": "req:tsumigi-v3-harness",
      "relation": "implements",
      "confidence": 0.95,
      "required": true
    }
  ],

  "summary": {
    "total": 0,
    "green": 0,
    "amber": 0,
    "gray": 0,
    "red": 0,
    "last_scanned": null            // string | null: ISO8601
  }
}
```

**バンド定義**:
| バンド | 条件 |
|--------|------|
| Green | required 依存が全て解決済み、循環なし |
| Amber | ダングリング参照、または confidence < 0.7 |
| Gray | 未スキャン / 参照がない孤立ノード |
| Red | 循環依存検出、または required 依存が欠落 |

**IMP との差分**: ✅ 一致  
**実装根拠**: `commands/coherence-scan.md`, `graph/coherence.json`（初期値）

---

## 4. CEG Frontmatter（Markdown 成果物の共通スキーマ）

各成果物 `.md` ファイルの先頭に付与される YAML frontmatter:

```yaml
---
tsumigi:
  node_id: string           # "<type>:<issue-id>[:<task-id>]" 例: "imp:tsumigi-v3-harness"
  artifact_type: string     # "imp" | "patch_plan" | "testcases" | "test_plan" |
                            # "rev_spec" | "rev_api" | "rev_schema" | "rev_requirements"
  phase: string             # "REQ" | "TDS" | "IMP" | "TEST" | "OPS" | "CHANGE"
  issue_id: string          # feature 識別子
  task_id: string?          # タスク識別子（T01〜T07 等）
  imp_version: string?      # IMP ファイルのみ: "1.0.0" 形式
  status: string?           # IMP ファイルのみ: "active" | "archived"
  created_at: string        # ISO8601
  updated_at: string?       # 更新時のみ
  drift_baseline: string?   # IMP ファイルのみ: git commit hash

coherence:
  id: string                # node_id と同値
  depends_on:               # 依存エッジのリスト
    - id: string            # 依存先の coherence.id
      relation: string      # "implements" | "derives_from" | "depends_on" |
                            # "verifies" | "reverse_of" | "aggregates" | "informed_by"
      confidence: float     # 0.0〜1.0
      required: boolean     # true = 依存が欠落すると Red バンド
  band: string              # "Green" | "Amber" | "Gray" | "Red"
  modules: string[]?        # IMP ファイルのみ: 変更対象モジュールのリスト
  last_validated: string?   # ISO8601

baton:                      # IMP ファイルのみ付与
  phase: string             # 現在の baton フェーズ（小文字）
  auto_step: boolean        # この Issue の AUTO_STEP の上書き設定
  issue_number: integer?    # GitHub Issue 番号（null = 未連携）
---
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `specs/tsumigi-v3-harness/implements/T01/patch-plan.md`（実際の frontmatter 例）
