# tsumigi × CoDD 統合仕様書 v1.0

**対象バージョン**: tsumigi v3.0（設計段階）  
**統合方針**: 方向性 A — 緩やかな統合（CoDD CLI オプション依存、フォールバック維持）  
**作成日**: 2026-04-04  
**ステータス**: Draft

---

## 目次

1. [目的とスコープ](#1-目的とスコープ)
2. [設計原則と統合方針](#2-設計原則と統合方針)
3. [依存グラフ: frontmatter 構造定義](#3-依存グラフ-frontmatter-構造定義)
4. [ノード/エッジ命名規則](#4-ノードエッジ命名規則)
5. [drift_check の CoDD 化](#5-drift_check-の-codd-化)
6. [sync と audit の統合仕様](#6-sync-と-audit-の統合仕様)
7. [rev と extract の互換仕様](#7-rev-と-extract-の互換仕様)
8. [test コマンドの V-Model 対応](#8-test-コマンドの-v-model-対応)
9. [CLI 拡張案](#9-cli-拡張案)
10. [統合アーキテクチャ図](#10-統合アーキテクチャ図)
11. [MVP 最小実装セット](#11-mvp-最小実装セット)
12. [移行ガイド](#12-移行ガイド)

---

## 0. 用語定義

| 用語 | 定義 |
|------|------|
| **Coherence** | 仕様・実装・テスト・ドキュメント間の整合性 |
| **Drift** | tsumigi における乖離スコア（0-100）。CoDD の impact 結果と統合可能 |
| **依存グラフ** | frontmatter `depends_on` から構築されるノード間の有向グラフ |
| **Band** | CoDD の変更影響分類。Green / Amber / Gray の 3 段階 |
| **IMP** | Implementation Management Plan。tsumigi の中心成果物 |
| **codd-enabled** | `.tsumigi/config.json` に `"codd": { "enabled": true }` が設定されている状態 |

---

## 1. 目的とスコープ

### 1.1 なぜ統合するか

tsumigi v2 の課題は「差分ベースの整合性確認」にある。`drift_check` は D1〜D5 の 5 次元で乖離をスコアリングするが、**どのドキュメントが何に依存しているかを知らない**。その結果：

- IMP.md が変わっても、rev-api.md が連鎖的に影響を受けることが検出されない
- `sync` は全成果物を均等に再確認する（影響がないものも含めて）
- `rev` は生成した逆仕様と他のドキュメントの因果関係を持たない

CoDD が解決するのはこの「**変更の連鎖把握**」である。frontmatter `depends_on` により依存グラフを構築し、変更影響を **Green / Amber / Gray** の 3 バンドで因果的に分類する。

### 1.2 スコープ

**対象（v3.0 で変更するもの）**:

| コマンド | 変更内容 |
|---|---|
| `drift_check` | 5次元スコアリング + Green/Amber/Gray バンド分類を追加 |
| `sync` | 依存グラフに基づく影響範囲の絞り込みを追加 |
| `rev` | 生成物に `depends_on` frontmatter を付与 |
| `test` | V-Model レイヤー（Unit/Integration/E2E）の明示化 |
| `imp_generate` | IMP.md に `depends_on` frontmatter を付与 |
| `install` | `codd` CLI 検出・設定を追加 |

**対象外（v3.0 では変更しない）**:

- `issue_init`, `implement`, `review`, `pr`, `cli`, `help`
- CoDD の内部アルゴリズム（`codd scan`, `codd impact` の実装）

### 1.3 統合方針: Graceful Degradation

```
codd CLI あり → CoDD フル活用モード（依存グラフ + impact + audit）
codd CLI なし → tsumigi スタンドアロンモード（現行動作を維持）
```

tsumigi は CoDD に依存しない。CoDD は tsumigi を強化するアドオンである。

---

## 2. 設計原則と統合方針

### 2.1 概念マッピング

| tsumigi 概念 | CoDD 概念 | 統合後の挙動 |
|---|---|---|
| IMP.md | `req:` / `design:` ノード | frontmatter で依存を宣言 |
| rev-api.md | `design:api-design` ノード | `derives_from: IMP` を持つ |
| rev-schema.md | `design:db-design` ノード | `derives_from: IMP` を持つ |
| drift_check (D1-D5) | `codd impact` | バンド分類を追加 |
| sync (整合性スコア) | `codd audit` | 依存グラフを走査して絞り込み |
| rev (逆仕様生成) | `codd extract` | frontmatter 付き生成物を出力 |
| test (focus) | V-Model レイヤー | 設計レイヤーから自動決定 |

### 2.2 フローの変化

**v2（現行）**:

```
Issue → IMP → 実装 → テスト → rev → drift_check → sync
                                         ↑ diff ベース（全体）
```

**v3（統合後）**:

```
Issue → IMP[depends_on] → 実装 → テスト → rev[depends_on]
                                              ↓
                                    drift_check（グラフ走査）
                                      ├── Green: 自動修正候補
                                      ├── Amber: 人間レビュー必要
                                      └── Gray:  影響なし（スキップ）
                                              ↓
                                    sync（影響ノードのみ確認）
```

---

## 3. 依存グラフ: frontmatter 構造定義

### 3.1 設計原則

> **ノードはファイル、エッジは依存関係。** tsumigi の全成果物ファイルが依存グラフのノードになる。
> **各成果物が自分の依存を宣言する**（CoDD 方式）ことで、グラフが自然に構築される。

### 3.2 frontmatter スキーマ

```yaml
---
# tsumigi × CoDD 共通 frontmatter（全成果物ファイルに付与）
tsumigi:
  node_id: "<type>:<issue_id>/<artifact>"   # グローバルユニーク識別子
  artifact_type: "imp|rev-spec|rev-api|rev-schema|rev-requirements|testcases|test-plan"
  issue_id: "NNN-kebab-case"
  imp_version: "1.0.0"                      # 参照した IMP のバージョン
  created_at: "2026-04-04T00:00:00Z"
  updated_at: "2026-04-04T00:00:00Z"
  drift_baseline: "abc1234"                 # 生成時の git commit hash
  depends_on:
    - id: "<type>:<issue_id>/<artifact>"
      relation: "derives_from|implements|verifies|constrains"
  modules: ["api", "auth", "db"]            # 関連するソースコードモジュール
  codd_compatible: true                     # CoDD CLI との互換フラグ
---
```

### 3.3 各成果物の frontmatter 定義

#### IMP.md

```yaml
---
tsumigi:
  node_id: "imp:001-user-auth"
  artifact_type: "imp"
  issue_id: "001-user-auth"
  imp_version: "1.2.0"
  created_at: "2026-04-01T09:00:00Z"
  updated_at: "2026-04-03T14:00:00Z"
  drift_baseline: "abc1234"
  depends_on:
    - id: "issue:001-user-auth"
      relation: "implements"       # Issue の受け入れ基準を実装する
  modules: ["auth", "api"]
  codd_compatible: true
---
```

**IMP.md は依存グラフの起点（ルートノード）となる。**

#### rev-api.md

```yaml
---
tsumigi:
  node_id: "rev-api:001-user-auth"
  artifact_type: "rev-api"
  issue_id: "001-user-auth"
  imp_version: "1.2.0"
  created_at: "2026-04-04T10:00:00Z"
  updated_at: "2026-04-04T10:00:00Z"
  drift_baseline: "def5678"
  depends_on:
    - id: "imp:001-user-auth"
      relation: "derives_from"     # IMP の API 仕様セクションから派生
    - id: "impl:001-user-auth/T01"
      relation: "verifies"         # 実装コードを検証・文書化する
  modules: ["api"]
  codd_compatible: true
---
```

#### rev-schema.md

```yaml
---
tsumigi:
  node_id: "rev-schema:001-user-auth"
  artifact_type: "rev-schema"
  issue_id: "001-user-auth"
  imp_version: "1.2.0"
  depends_on:
    - id: "imp:001-user-auth"
      relation: "derives_from"
    - id: "impl:001-user-auth/T01"
      relation: "verifies"
  modules: ["db", "auth"]
  codd_compatible: true
---
```

#### testcases.md

```yaml
---
tsumigi:
  node_id: "test:001-user-auth/T01"
  artifact_type: "testcases"
  issue_id: "001-user-auth"
  task_id: "T01"
  imp_version: "1.2.0"
  vmodel_layer: "unit"             # unit | integration | e2e
  depends_on:
    - id: "imp:001-user-auth"
      relation: "verifies"         # IMP の受け入れ基準を検証する
    - id: "impl:001-user-auth/T01"
      relation: "verifies"
  modules: ["auth"]
  codd_compatible: true
---
```

### 3.4 relation の意味論

| relation | 方向 | 意味 |
|---|---|---|
| `implements` | A → B | A は B（Issue/要件）の実装である |
| `derives_from` | A → B | A は B（IMP/設計）から導出された |
| `verifies` | A → B | A は B（実装/IMP）を検証する |
| `constrains` | A → B | A は B に制約を課す（非機能要件等） |

---

## 4. ノード/エッジ命名規則

### 4.1 node_id 命名規則

```
<type>:<issue_id>[/<sub_id>]

type の値:
  issue      — GitHub/Linear Issue
  imp        — IMP.md
  impl       — 実装成果物（patch-plan.md + 実装コード）
  rev-spec   — rev-spec.md
  rev-api    — rev-api.md
  rev-schema — rev-schema.md
  rev-req    — rev-requirements.md
  test       — testcases.md
  test-plan  — test-plan.md

issue_id: NNN-kebab-case（ブランチ名から派生）
sub_id: タスクID（T01, T02...）またはアーティファクトの識別子
```

**例**:

```
issue:001-user-auth
imp:001-user-auth
impl:001-user-auth/T01
rev-api:001-user-auth
test:001-user-auth/T01
```

### 4.2 modules フィールド命名規則

```
modules はソースコードのトップレベルディレクトリ名か
機能モジュール名を使う（プロジェクト固有）

例（Next.js + Prisma）:
  ["api", "auth", "db", "ui", "lib"]

例（FastAPI）:
  ["routers", "models", "services", "schemas"]

例（Go）:
  ["handler", "usecase", "repository", "domain"]
```

`modules` フィールドにより、ソースコードの変更がどの成果物ドキュメントに影響するかを逆引きできる。

---

## 5. drift_check の CoDD 化

### 5.1 変更後のアーキテクチャ

```
drift_check v3
│
├── [既存] D1-D5 スコアリング（差分ベース）
│     → 維持。ただし各エラーに node_id を付与する
│
├── [新規] グラフ走査フェーズ
│     → IMP.md の frontmatter を起点にグラフを構築
│     → 変更されたノードから影響を伝播させる
│
└── [新規] Green/Amber/Gray バンド分類
      → D1-D5 のエラーをバンドに変換して出力
```

### 5.2 現行 vs 新設計

| 観点 | 現行（v2） | v3.0 統合後 |
|------|-----------|------------|
| スキャン範囲 | 全 D1〜D5 を毎回全件チェック | 変更ノードの下流のみスキャン |
| 出力分類 | CRITICAL / WARNING / INFO | **Green / Amber / Gray** + CRITICAL/WARNING/INFO |
| 修正指示 | 「対応してください」 | Green: 自動修正、Amber: 要レビュー指示 |
| codd 連携 | なし | codd-enabled 時は `codd impact` を呼び出し、結果をマージ |

### 5.3 バンド定義

```
GREEN  🟢  自動修正候補
  条件: drift スコア 0-10 かつ relation が derives_from / implements
  アクション: --fix-green フラグで AI が自動更新
  tsumigi: updated_at, imp_version, coherence_band を自動同期

AMBER  🟡  人間レビュー必要
  条件: 以下のいずれか
    - CRITICAL 判定の乖離が存在する
    - relation が "verifies" かつ対応するテストが変更されていない
    - imp_version が依存先と不一致
  アクション: sync-actions.md に「要レビュー」として記録

GRAY   ⚪  影響なし（追跡済み）
  条件: グラフ走査で影響が伝播しなかったノード
  アクション: チェックをスキップ（ログにのみ記録）
```

### 5.4 Green/Amber/Gray 判定アルゴリズム

```python
def classify_band(node, drift_results, graph):
    """
    node: チェック対象の成果物ノード
    drift_results: D1-D5 の照合結果リスト
    graph: 依存グラフ（node_id → depends_on リスト）
    """

    # Step 1: グラフ走査で影響を伝播
    changed_nodes = get_changed_nodes(graph)  # git diff から変更ノードを取得
    affected = propagate_impact(changed_nodes, graph)

    if node.node_id not in affected:
        return Band.GRAY  # 影響なし → スキップ

    # Step 2: CRITICAL が存在するか
    has_critical = any(r.severity == "CRITICAL" for r in drift_results)

    # Step 3: imp_version の不一致
    imp_version_mismatch = (
        node.imp_version != get_current_imp_version(node.issue_id)
    )

    # Step 4: verifies 関係の未更新テスト
    verifies_stale = (
        node.artifact_type in ["testcases", "test-plan"]
        and not is_recently_updated(node)
        and has_implementation_changed(node.modules)
    )

    # Amber 判定
    if has_critical or imp_version_mismatch or verifies_stale:
        return Band.AMBER

    # Green 判定（WARNING 以下のみ）
    return Band.GREEN


def propagate_impact(changed_nodes, graph):
    """
    変更されたノードから depends_on を逆引きして
    影響を受けるノードを BFS で収集する
    """
    affected = set(changed_nodes)
    queue = list(changed_nodes)

    while queue:
        current = queue.pop(0)
        dependents = get_dependents(current, graph)  # current に depends_on しているノード
        for dep in dependents:
            if dep not in affected:
                affected.add(dep)
                queue.append(dep)

    return affected
```

### 5.5 drift_check v3 のステップ変更

**新規追加ステップ（既存ステップの間に挿入）**:

```
step2.5: 依存グラフの構築
  - specs/{{issue_id}}/ 以下の全 .md ファイルの frontmatter を読み込む
  - tsumigi.node_id と tsumigi.depends_on からグラフを構築する
  - codd CLI が存在する場合: `codd scan --path .` を実行してグラフをキャッシュする
  - 存在しない場合: tsumigi 独自のインメモリグラフで処理する

step3.5: 変更ノードの特定
  - git diff で変更されたファイルを取得する
  - 変更ファイルから modules フィールドの逆引きで影響ノードを特定する
  - 影響伝播（BFS）で Amber/Gray の予備分類を行う

step9.5: バンド分類の実行
  - D1-D5 の各エラーに対して classify_band() を適用する
  - バンド別に結果を集計する
  - Gray ノードはレポートから除外する（サマリーには件数を記載）
```

### 5.6 drift-report.md の出力形式変更

```markdown
## drift_check レポート: 001-user-auth

run_id: drift-20260404-001
drift スコア: 23/100 — Significant Drift

### 影響バンド サマリー
| バンド | 件数 | アクション |
|--------|------|-----------|
| 🟢 Green | 3 件 | `--fix-green` で自動修正可能 |
| 🟡 Amber | 2 件 | 人間レビュー必要 |
| ⚪ Gray  | 5 件 | 影響なし（スキップ）|

### 🟢 Green バンド（自動修正候補）
- [rev-api:001-user-auth] API レスポンス構造の軽微な差分 (D2-WARNING)
  → `imp_version: 1.1.0 → 1.2.0` に更新で解消
- [rev-schema:001-user-auth] カラム追加の未反映 (D3-WARNING)
  → rev-schema.md の再生成で解消

### 🟡 Amber バンド（人間レビュー必要）
- [test:001-user-auth/T01] P0 テストが未実装 (D4-CRITICAL)
  → 実装を確認し、テストケースを手動で追加してください
- [imp:001-user-auth] imp_version 不一致（rev-api が 1.1.0 を参照）
  → rev-api.md を更新するか、IMP をロールバックしてください

### ⚪ Gray バンド（スキップ）
- rev-requirements.md, IMP-checklist.md, IMP-risks.md ... 他 2 件
  → 今回の変更スコープ外
```

---

## 6. sync と audit の統合仕様

### 6.1 現行 sync の課題

`sync` v2 は全 5 チェックを毎回フルスキャンする。依存グラフがないため、影響のないドキュメントも確認対象になる。

### 6.2 設計方針

```
tsumigi sync     = 成果物の「内容」の整合性（Issue↔IMP↔実装↔テスト↔逆仕様）
codd audit       = 成果物の「構造」の整合性（frontmatter・依存グラフ・ポリシー）
tsumigi sync --audit = 両方を一括実行してマージレポートを生成
```

### 6.3 sync v3: グラフ駆動の絞り込み

**フロー**:

```
1. 依存グラフの構築（drift_check v3 と同じ手順）
2. --since オプションまたは前回実行時の git hash から
   変更ノードを特定する
3. 影響伝播（BFS）で確認対象ノードを絞り込む
4. 絞り込み後のノードに対してのみ整合性チェックを実行する
5. Gray ノードは "スコープ外" として整合性スコアから除外する
```

**整合性スコアの計算変更**:

```
v2: 全チェックの合計点 / 全チェックの満点
v3: 影響ノードのチェックの合計点 / 影響ノードのチェックの満点

  Gray ノードのスコアは計算から除外
  ただし sync-report.md には Gray ノード一覧を記載する（監査証跡）
```

### 6.4 CoDD audit との統合（codd-enabled 時）

```bash
# tsumigi sync --audit の内部処理
if command -v codd &> /dev/null; then
    codd audit --skip-review --path . \
      > specs/{{issue_id}}/codd-audit-report.json
    # JSON から verdict, risk-level を取得して sync-report.md に埋め込む
fi
```

**sync-report.md の CoDD セクション（codd あり時のみ）**:

```markdown
## CoDD Audit 結果（codd v1.4.0）

| 項目 | 結果 |
|------|------|
| Verdict | CONDITIONAL |
| Risk Level | MEDIUM |
| Policy 違反 | 0 件 |
| Frontmatter 不整合 | 1 件 |

詳細: specs/{{issue_id}}/codd-audit-report.json
```

### 6.5 sync の新フラグ

```
/tsumigi:sync [issue-id] [--fix] [--report-only] [--audit] [--affected-only]

--audit          codd audit を実行して結果を埋め込む（codd CLI 必要）
--affected-only  グラフで影響を受けたノードのみを確認する（デフォルト: false）
```

---

## 7. rev と extract の互換仕様

### 7.1 現行 rev vs CoDD extract の対比

| 観点 | tsumigi rev | CoDD extract |
|------|-------------|--------------|
| 入力 | 実装コード + IMP.md | 実装コード のみ |
| 出力 | rev-spec / rev-api / rev-schema / rev-requirements | modules/*.md + system-context.md |
| IMP 差分 | ⚠️ フラグ付きで出力 | なし（構造事実のみ） |
| 依存グラフ | なし | modules フィールドで自動構築 |
| 目的 | IMP との乖離検出 | 設計ドキュメントの逆生成 |

### 7.2 rev v3: frontmatter 付き生成

`rev` v3 は生成する全ドキュメントに tsumigi frontmatter を付与する。

**生成物ごとの frontmatter テンプレート**:

```yaml
# rev-api.md のヘッダー（自動生成）
---
tsumigi:
  node_id: "rev-api:{{issue_id}}"
  artifact_type: "rev-api"
  issue_id: "{{issue_id}}"
  imp_version: "{{imp_version}}"       # IMP.md から取得
  created_at: "{{ISO8601}}"
  updated_at: "{{ISO8601}}"
  drift_baseline: "{{git_hash}}"       # git rev-parse HEAD
  depends_on:
    - id: "imp:{{issue_id}}"
      relation: "derives_from"
    - id: "impl:{{issue_id}}/{{task_id}}"
      relation: "verifies"
  modules: {{inferred_modules}}        # 実装コードの探索結果から推論
  codd_compatible: true
---
```

**modules の自動推論ロジック**:

```
1. 探索したソースファイルのパスを収集する
   例: src/routes/auth.ts, src/services/user.ts
2. src/ 以下の第一レベルディレクトリ名を抽出する
   例: ["routes", "services"]
3. .tsumigi/config.json の module_map があれば変換する
   例: routes → api, services → auth
4. frontmatter の modules に設定する
```

### 7.3 CoDD との frontmatter 共存

`codd_compatible: true` フラグを持つ tsumigi 成果物は CoDD の `codd scan` で読み込み可能にする。
tsumigi の `tsumigi:` frontmatter と CoDD の `codd:` frontmatter は**共存可能**:

```yaml
---
# tsumigi ネイティブフィールド
tsumigi:
  node_id: "rev-api:001-user-auth"
  artifact_type: "rev-api"
  imp_version: "1.2.0"
  depends_on:
    - id: "imp:001-user-auth"
      relation: "derives_from"
  modules: ["api", "auth"]
  codd_compatible: true

# CoDD フィールド（codd CLI がある場合に tsumigi が自動生成）
codd:
  node_id: "design:001-user-auth/api"
  modules: ["api", "auth"]
  depends_on:
    - id: "imp:001-user-auth"
      relation: derives_from
---
```

### 7.4 rev の CoDD モード（codd CLI あり時）

```bash
# rev 内部処理（codd-enabled 時）
if command -v codd &> /dev/null; then
    codd extract --path . --output specs/{{issue_id}}/codd-extracted/
    # 生成された codd/ 形式ドキュメントと rev-*.md を差分比較する
    # 差分がある場合は Amber フラグを立てる
    codd scan --path . 2>/dev/null  # グラフを更新
fi
```

### 7.5 rev v3 のステップ変更

**新規追加ステップ**:

```
step2.5: frontmatter コンテキストの収集
  - IMP.md の tsumigi.node_id と imp_version を取得する
  - git rev-parse HEAD を実行して drift_baseline を取得する
  - 既存の rev-*.md から depends_on を引き継ぐ（再生成時）

step10.5: CoDD フォーマット出力（codd CLI あり時）
  - tsumigi frontmatter から codd frontmatter を自動変換する
  - codd scan を実行してグラフに追加する
```

---

## 8. test コマンドの V-Model 対応

### 8.1 V-Model と tsumigi の対応

```
【V-Model — tsumigi における対応】

要件定義 (issue-struct.md)
    └── 受け入れ基準 (AC-XXX)
          └── [verifies] E2E テスト / システムテスト
                  └── IMP.md (API 仕様 / 機能仕様)
                        └── [verifies] 統合テスト
                                └── 実装 (patch-plan.md + コード)
                                      └── [verifies] 単体テスト
```

| V-Model レイヤー | 検証対象 | 参照する設計ドキュメント | `--vmodel` オプション |
|---|---|---|---|
| E2E / System | issue-struct.md の AC | issue-struct.md | `e2e` |
| Integration | IMP.md の API / スキーマ仕様 | IMP.md (API 変更セクション) | `integration` |
| Unit | 実装コード（関数・クラス） | patch-plan.md | `unit` |
| Security | IMP.md の非機能要件 | IMP.md (セキュリティ要件) | `security` |

### 8.2 vmodel_layer の自動推論ロジック

```python
def infer_vmodel_layer(node, graph):
    """
    depends_on の relation と artifact_type から
    V-Model レイヤーを推論する
    """
    imp_node = get_depends_on(node, "imp:*", "verifies")

    if imp_node is None:
        return "unit"  # IMP への依存がない → 単体テスト

    issue_node = get_depends_on(imp_node, "issue:*", "implements")

    if issue_node and node.modules_overlap(issue_node.modules):
        return "e2e"   # Issue レベルの AC をカバー → E2E

    if imp_node.has_api_spec() or imp_node.has_schema_spec():
        return "integration"  # API / DB を跨ぐ → 統合テスト

    return "unit"
```

### 8.3 testcases.md の V-Model 形式

```markdown
---
tsumigi:
  node_id: "test:001-user-auth/T01"
  vmodel_layer: "integration"        # 自動推論または手動指定
  depends_on:
    - id: "imp:001-user-auth"
      relation: "verifies"
  ...
---

# テストケースマトリクス: 001-user-auth / T01

## V-Model レイヤー: Integration テスト
**検証対象設計書**: IMP.md §3 API 仕様
**上位 AC**: AC-001, AC-003

| TC-ID | テスト名 | 対応 AC | レイヤー | P | 状態 |
|-------|---------|---------|---------|---|------|
| TC-001 | POST /auth/login — 正常系 | AC-001 | integration | P0 | - |
| TC-002 | POST /auth/login — 不正パスワード | AC-001 | integration | P0 | - |
| TC-003 | JWT 有効期限切れ | AC-003 | unit | P1 | - |
```

### 8.4 V-Model カバレッジサマリー（test コマンド完了通知に追加）

```
📊 V-Model カバレッジ:

  E2E (AC カバレッジ):          4/5 AC = 80%  ⚠️
  Integration (API カバレッジ): 6/6 EP = 100% ✅
  Unit (関数カバレッジ):         推定 85%       ✅
  Security:                     2/3 要件 = 67% ⚠️
```

### 8.5 test v3 のステップ変更

**新規追加ステップ**:

```
step3.5: vmodel_layer の自動推論
  - 依存グラフから vmodel_layer を推論する
  - --vmodel オプションが指定されている場合はそれを優先する
  - 推論結果をユーザーに表示して確認を求める

step8.5: V-Model カバレッジ分析
  - vmodel_layer ごとのカバレッジを算出する
  - E2E: AC のカバレッジ
  - Integration: API エンドポイントのカバレッジ
  - Unit: 変更関数のカバレッジ（推定）
```

---

## 9. CLI 拡張案

### 9.1 新規コマンド: `tsumigi:impact`

CoDD の `codd impact` に相当する tsumigi ネイティブコマンド。

```
/tsumigi:impact [issue-id] [--node <node_id>] [--format band|graph|json]

目的:
  依存グラフを走査し、指定ノードからの影響伝播を可視化する。
  drift_check を実行する前に「何が影響を受けるか」を確認する。

出力例:
  Changed: imp:001-user-auth (imp_version: 1.1.0 → 1.2.0)

  Impact:
    🟢 Green (3): rev-api, rev-schema, test-plan/T01
    🟡 Amber (1): test/T01 (P0 テストの実装確認が必要)
    ⚪ Gray  (4): IMP-risks, IMP-checklist, rev-requirements, note

  推奨アクション:
    1. /tsumigi:rev 001-user-auth --target api,schema
    2. /tsumigi:drift_check 001-user-auth
```

### 9.2 既存コマンドのフラグ拡張

```bash
# drift_check
/tsumigi:drift_check [issue-id]
  --band <green|amber|gray|all>   # バンドでフィルタ（デフォルト: all）
  --fix-green                     # Green バンドを自動修正
  --codd                          # codd impact を併用（codd CLI 必要）

# sync
/tsumigi:sync [issue-id]
  --affected-only                 # 影響ノードのみを確認
  --audit                         # codd audit を実行

# rev
/tsumigi:rev [issue-id]
  --with-frontmatter              # tsumigi frontmatter を付与（v3 デフォルト: true）
  --codd-extract                  # codd extract と差分比較（codd CLI 必要）

# test
/tsumigi:test [issue-id] [task-id]
  --vmodel <unit|integration|e2e|security|all>  # V-Model レイヤー指定（--focus の拡張）
  --from-graph                    # 依存グラフから vmodel_layer を自動推論

# install
/tsumigi:install [project-name]
  --codd                          # CoDD CLI を検出・設定する
```

### 9.3 install v3: CoDD 検出の追加

```
## step3.5（追加）: CoDD CLI の検出

- `command -v codd` を Bash で実行する
- codd が存在する場合：
  - `codd --version` を取得して config.json に記録する
  - `.tsumigi/config.json` の `integrations.codd` を設定する：
    {
      "enabled": true,
      "version": "<detected version>",
      "auto_scan_on_edit": false,
      "config_dir": ".codd"
    }
  - 「CoDD CLI が検出されました。統合モードで動作します」と表示する
  - hook 設定の案内を表示する（下記）

- codd が存在しない場合：
  - `integrations.codd.enabled: false` を設定する
  - 「CoDD CLI が見つかりません。tsumigi スタンドアロンモードで動作します」と表示する
  - オプション: `pip install codd-dev` の案内を表示する
```

**CoDD hook の設定案内**（install 完了時に表示）:

```json
// .claude/settings.json に追加を推奨（任意）
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "codd scan --path . 2>/dev/null || true"
      }]
    }]
  }
}
```

---

## 10. 統合アーキテクチャ図

### 10.1 tsumigi v3 全体アーキテクチャ

```
╔══════════════════════════════════════════════════════════════════════╗
║                     tsumigi v3 — AI-TDD Engine                      ║
║                  (CoDD Coherence Layer 統合版)                       ║
╚══════════════════════════════════════════════════════════════════════╝

  [GitHub/Linear Issue]
         │
         ▼
  ┌─────────────┐   issue-struct.md
  │ issue_init  │──────────────────┐
  └─────────────┘                  │
                                   ▼
  ┌──────────────┐   IMP.md ◄──── [node: imp:NNN]
  │ imp_generate │                 │  depends_on: issue:NNN
  └──────────────┘                 │
         │                         │ implements ↓
         ▼                         │
  ┌─────────────┐   patch-plan.md  │
  │  implement  │──[node: impl:NNN/Txx]◄──────────────────┐
  └─────────────┘                  │                      │
                                   │ derives_from ↑       │
  ╔══════════════════════════════╗ │  ╔═══════════════════╗│
  ║   Coherence Layer (v3 新規)  ║ │  ║  依存グラフ        ║│
  ║                              ║ │  ║                   ║│
  ║  imp:NNN ──────────────────► ║ │  ║  imp:NNN          ║│
  ║    │ implements              ║ │  ║   ├─derives─► rev ║│
  ║    ▼                         ║ │  ║   └─verifies◄ test║│
  ║  issue:NNN                   ║ │  ║                   ║│
  ║    │                         ║ │  ║  [codd scan cache]║│
  ║    ▼ verifies                ║ │  ╚═══════════════════╝│
  ║  test:NNN/Txx                ║ │                       │
  ║    │ derives_from            ║ │                       │
  ║    ▼                         ║ │                       │
  ║  rev-api:NNN                 ║ │                       │
  ║  rev-schema:NNN              ║ │                       │
  ╚══════════════════════════════╝ │                       │
                                   │                       │
  ┌─────────────┐   testcases.md   │                       │
  │    test     │──[vmodel_layer]──┘                       │
  │  (V-Model)  │    verifies ↑                            │
  └─────────────┘                                          │
                                                           │
  ┌─────────────┐   rev-*.md                               │
  │     rev     │──[depends_on: imp:NNN, impl:NNN/Txx]─────┘
  │(+frontmatter)│
  └─────────────┘
         │
         ▼
  ┌─────────────────────────────────────────────────────────┐
  │                  drift_check v3                          │
  │                                                         │
  │  1. グラフ構築 (frontmatter 読み込み)                    │
  │  2. 変更ノード特定 (git diff + modules 逆引き)           │
  │  3. 影響伝播 BFS → Gray ノードを除外                     │
  │  4. D1-D5 スコアリング (影響ノードのみ)                  │
  │  5. Green/Amber/Gray バンド分類                          │
  │                                                         │
  │  🟢 Green → --fix-green で自動修正                       │
  │  🟡 Amber → sync-actions.md に記録                       │
  │  ⚪ Gray  → レポートから除外 (監査証跡のみ記録)           │
  └─────────────────────────────────────────────────────────┘
         │
         ▼
  ┌─────────────┐
  │    sync     │──影響ノードのみを整合性チェック
  │  (v3 改)    │──--audit で codd audit を呼び出し
  └─────────────┘
         │
         ▼
  ┌─────────────┐
  │   review    │──drift-report.md + sync-report.md をもとにリスク整理
  │    / pr     │
  └─────────────┘

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  オプション: CoDD CLI あり (pip install codd-dev)

  PostToolUse Hook
    Edit/Write → codd scan（依存グラフをリアルタイム更新）
                     ↓
              /tsumigi:impact → codd impact（バンド出力）
                     ↓
              /tsumigi:sync --audit → codd audit
                                      (Verdict: APPROVE/CONDITIONAL/REJECT)
```

### 10.2 フロントマター依存グラフ（Issue 001 の例）

```
  issue:001-user-auth
       │
       │ implements ▼
  ┌────┴──────────┐
  │ imp:001-user-auth (v1.2.0)
  └────┬──────┬───┘
       │      │
  derives_from│derives_from
       │      │
       ▼      ▼
  rev-api    rev-schema
  :001       :001
       │      │
  verifies▲  verifies▲
       │      │
  impl:001/T01◄──(patch-plan.md + コード)
       │
  verifies▲
       │
  test:001/T01
  (vmodel_layer: integration)
```

---

## 11. MVP 最小実装セット

### 11.1 MVP の選定基準

「CoDD コンセプトの最大効果を最小変更で得る」を基準とする。

```
MVP = frontmatter 標準化 + drift_check バンド分類 + rev frontmatter 付与
      ↑ Phase 1               ↑ Phase 2                ↑ Phase 1 の一部
```

### 11.2 MVP タスク一覧

#### Phase 1: frontmatter 基盤（1〜2日）🔴 MUST

| # | 変更対象 | 内容 |
|---|---|---|
| 1 | `commands/imp_generate.md` | IMP.md 生成時に `tsumigi:` frontmatter ブロックを付与 |
| 2 | `commands/rev.md` | 全生成物に frontmatter を付与するステップを追加（step2.5, step10.5） |
| 3 | `templates/IMP-template.md` | frontmatter セクションを先頭に追加 |
| 4 | `templates/rev-*-template.md` | frontmatter セクションを先頭に追加（4ファイル） |

**実装の要点**: 新フィールドは全て既存テンプレートに `---` ブロックを先頭に追加するだけ。既存コマンドのロジック変更は最小限。

#### Phase 2: drift_check バンド分類（2〜3日）🔴 MUST

| # | 変更対象 | 内容 |
|---|---|---|
| 5 | `commands/drift_check.md` | step2.5（グラフ構築）を追加 |
| 6 | `commands/drift_check.md` | step3.5（変更ノード特定・影響伝播）を追加 |
| 7 | `commands/drift_check.md` | step9.5（バンド分類）を追加 |
| 8 | `templates/drift-report-template.md` | Green/Amber/Gray セクションを追加 |

**実装の要点**: グラフ構築は「frontmatter を読んで dict に積む」だけ。CoDD 不要なスタンドアロン実装で十分。

#### Phase 3: install の CoDD 検出（0.5日）🟡 SHOULD

| # | 変更対象 | 内容 |
|---|---|---|
| 9 | `commands/install.md` | step3.5（codd CLI 検出）を追加 |
| 10 | config.json テンプレート | `integrations.codd` フィールドを追加 |

#### Phase 4: test V-Model 対応（1日）🟡 SHOULD

| # | 変更対象 | 内容 |
|---|---|---|
| 11 | `commands/test.md` | `--vmodel` フラグを追加、`vmodel_layer` を frontmatter に記録 |
| 12 | `templates/testcases-template.md` | V-Model カバレッジサマリーを追加 |

#### Phase 5: sync 影響絞り込み（1〜2日）🟢 NICE

| # | 変更対象 | 内容 |
|---|---|---|
| 13 | `commands/sync.md` | グラフ構築・影響絞り込みを追加 |
| 14 | `commands/sync.md` | `--affected-only`, `--audit` フラグを追加 |

#### Phase 6: impact コマンド新設（2日）🟢 NICE

| # | 変更対象 | 内容 |
|---|---|---|
| 15 | `commands/impact.md` | 新規コマンドとして追加 |

### 11.3 MVP の完了定義

```
Phase 1 + Phase 2 が完了した時点を MVP とする。

MVP 完了の検証基準:
  1. /tsumigi:imp_generate で生成した IMP.md に tsumigi: frontmatter が含まれる
  2. /tsumigi:rev で生成した rev-api.md に depends_on が含まれる
  3. /tsumigi:drift_check の出力に Green/Amber/Gray セクションが含まれる
  4. Gray ノードはチェックをスキップし、drift スコアに加算されない
  5. codd CLI なしで全コマンドが正常動作する（スタンドアロンモード）
```

### 11.4 推奨着手順序

```
Day 1: templates 更新（#3, #4）
         → 既存テンプレートに frontmatter ブロックを追加
         → 最もリスクが低く、他フェーズのベースになる

Day 2: imp_generate + rev の frontmatter 出力（#1, #2）
         → step2.5 / step10.5 としてステップを追加
         → IMP.md を source of truth として rev が参照

Day 3-4: drift_check バンド分類（#5, #6, #7, #8）
         → グラフ構築（frontmatter の Glob + Read + dict 構築）
         → 影響伝播（BFS ループ）
         → バンド分類（CRITICAL/WARNING/INFO → Green/Amber/Gray）

Day 5: install CoDD 検出 + 検証（#9, #10）
         → MVP 完了テスト
```

---

## 12. 移行ガイド

### 12.1 既存プロジェクトへの適用

```bash
# 1. tsumigi を v3 に更新
cd ~/.claude/commands/tsumigi
git pull && bash setup.sh

# 2. 既存 IMP.md に frontmatter を付与
/tsumigi:imp_generate <issue-id> --update
  # --update フラグで既存 IMP を frontmatter 付きに再生成

# 3. 既存 rev-*.md を frontmatter 付きに再生成
/tsumigi:rev <issue-id> --target all
  # 既存ファイルに frontmatter を差分マージ

# 4. CoDD を使う場合（任意）
pip install codd-dev
/tsumigi:install --codd  # CoDD を検出・設定
```

### 12.2 後方互換性の保証

- frontmatter なし（v2 形式）のドキュメントは v3 でも正常に動作する
- frontmatter がない場合、グラフ構築でそのノードは孤立ノードとして扱われ、従来通りフルスキャンが適用される
- `--focus` フラグは `--vmodel` の alias として引き続き動作する

### 12.3 段階的移行パス

```
v2 → v3 の段階的移行:

Step A（最小）: テンプレートのみ更新
  → 新規 Issue から frontmatter が付与され始める
  → 既存 Issue は影響なし

Step B（推奨）: drift_check v3 を有効化
  → frontmatter なしの既存ドキュメントはフォールバック動作
  → frontmatter ありの新規ドキュメントはバンド分類が適用される

Step C（完全移行）: 既存 Issue を --update で再生成
  → 全成果物が frontmatter を持ち、依存グラフが完成する
  → drift_check / sync がグラフ駆動の絞り込みで高速化される
```

---

## 付録 A: 変更ファイル一覧

```
commands/
  drift_check.md          step2.5, step3.5, step9.5 追加、出力形式変更
  sync.md                 step1.5 追加、--affected-only, --audit フラグ追加
  rev.md                  step2.5, step10.5 追加、frontmatter 付与
  test.md                 vmodel_layer 対応、V-Model カバレッジサマリー追加
  imp_generate.md         frontmatter テンプレート参照を追加
  install.md              step3.5（CoDD 検出）追加
  impact.md               新規作成（Phase 6）

templates/
  IMP-template.md                   tsumigi: frontmatter ブロック追加
  rev-spec-template.md              frontmatter ブロック追加
  rev-api-template.md               frontmatter ブロック追加
  rev-schema-template.md            frontmatter ブロック追加
  rev-requirements-template.md      frontmatter ブロック追加
  testcases-template.md             vmodel_layer, V-Model サマリー追加
  drift-report-template.md          Green/Amber/Gray セクション追加

設定ファイル:
  .tsumigi/config.json テンプレート  integrations.codd フィールド追加
```

## 付録 B: CoDD 参照リンク

- CoDD リポジトリ: [yohey-w/codd-dev](https://github.com/yohey-w/codd-dev)
- CoDD インストール: `pip install codd-dev`
- CoDD ドキュメント: `codd --help`
