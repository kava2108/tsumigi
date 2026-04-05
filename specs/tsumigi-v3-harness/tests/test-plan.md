---
tsumigi:
  node_id: "test-plan:tsumigi-v3-harness"
  artifact_type: "test_plan"
  phase: "TEST"
  issue_id: "tsumigi-v3-harness"
  vmodel: "all"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "test-plan:tsumigi-v3-harness"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "derives_from"
      confidence: 1.0
      required: true
    - id: "test:tsumigi-v3-harness:T01"
      relation: "aggregates"
      confidence: 1.0
      required: false
    - id: "test:tsumigi-v3-harness:T02"
      relation: "aggregates"
      confidence: 1.0
      required: false
    - id: "test:tsumigi-v3-harness:T03"
      relation: "aggregates"
      confidence: 1.0
      required: false
    - id: "test:tsumigi-v3-harness:T04"
      relation: "aggregates"
      confidence: 1.0
      required: false
    - id: "test:tsumigi-v3-harness:T05"
      relation: "aggregates"
      confidence: 1.0
      required: false
    - id: "test:tsumigi-v3-harness:T06"
      relation: "aggregates"
      confidence: 1.0
      required: false
    - id: "test:tsumigi-v3-harness:T07"
      relation: "aggregates"
      confidence: 1.0
      required: false
  band: "Green"
---

# テスト計画書: tsumigi-v3-harness（V-Model All）

**Feature**: tsumigi v3.0 Harness Engineering 統合  
**IMP バージョン**: 1.1.0  
**生成日**: 2026-04-05  
**フォーカス**: unit / integration / e2e / security（全レイヤー）

---

## テスト方針

tsumigi v3.0 Harness Engineering の実装は以下の 3 層で検証する。

```
V-Model マッピング:

要件（REQ）          ←→  受け入れテスト（e2e）
  設計（TDS）        ←→  統合テスト（integration）
    実装（IMP/T01〜T07）  ←→  単体テスト（unit）
```

- **unit**: 各 Bash 関数・コマンドの単独動作を `VCKD_TEST_MODE=1` + `mock_gh` でテスト
- **integration**: 複数コンポーネント間の連携（phase-gate ↔ baton-log、Actions ↔ agents）
- **e2e**: ラベル付与から次フェーズ起動までのエンドツーエンドフロー
- **security**: シェルインジェクション・シークレット漏洩・コンテキスト汚染の防止

---

## テスト環境

| 項目 | 内容 |
|---|---|
| **シェル** | Bash 5.x（Ubuntu 22.04） |
| **テストフレームワーク** | bats-core（Bash Automated Testing System） |
| **CI** | GitHub Actions（`on: pull_request`） |
| **モック** | `VCKD_TEST_MODE=1` 環境変数で `mock_gh` を有効化 |
| **e2e 環境** | GitHub テスト用リポジトリ（`kava2108/tsumigi-e2e-sandbox`） |
| **セキュリティスキャン** | ShellCheck（静的解析） |

---

## テスト優先度

| 優先度 | 条件 | 対象 TC 件数 |
|---|---|---|
| P0 | CI で必ず通過すべきテスト（コアロジック・セキュリティ） | 34 件 |
| P1 | リリース前に確認すべきテスト（エッジケース・統合） | 8 件 |
| P2 | 余裕があれば確認するテスト（境界値・パフォーマンス） | 4 件 |

---

## タスク別テストケース一覧

| タスク | unit | integration | e2e | security | 合計 | AC カバー率 |
|--------|------|-------------|-----|----------|------|------------|
| T01 Baton Infrastructure | 4 | 2 | 0 | 1 | 7 | 3/3 = 100% |
| T02 CEG frontmatter | 4 | 0 | 0 | 0 | 6 | 1/1 = 100% |
| T03 Phase Gate（T08/T09 含む） | 9 | 5 | 0 | 1 | 15 | 11/11 = 100% |
| T04 Phase Agent REQ/TDS/IMP | 1 | 3 | 2 | 0 | 6 | 2/2 = 100% |
| T05 GitHub Actions 統合 | 2 | 3 | 1 | 0 | 6 | 1/1 = 100% |
| T06 Phase Agent TEST/OPS/CHANGE | 1 | 4 | 1 | 0 | 6 | 3/3 = 100% |
| T07 coherence-scan / baton-status | 5 | 1 | 0 | 0 | 7 | 2/2 = 100% |
| **合計** | **26** | **18** | **4** | **2** | **53** | **23/23 = 100%** |

---

## V-Model 対応表（AC レベル）

```
REQ-001 (ラベル起点バトン)
  └─ AC-1: TC-T01-01, TC-T05-01 [e2e]
  └─ AC-2: TC-T03-03 [integration]
  └─ AC-3: TC-T03-04 [integration]
  └─ AC-4: TC-T03-05 [integration]
  └─ AC-5: TC-T03-06 [integration]

REQ-002 (AUTO_STEP 制御)
  └─ AC-1: TC-T03-01 [unit]
  └─ AC-2: TC-T03-02 [unit]
  └─ AC-3: TC-T01-03, TC-T03-10 [unit]

REQ-003 (Phase Gate)
  └─ AC-1: TC-T03-07, TC-T03-12 [unit]
  └─ AC-2: TC-T03-13 [unit]
  └─ AC-3: TC-T03-14 (via check_phase_specific) [unit]
  └─ AC-4: TC-T03-09 (via check_gray) [unit]

REQ-004 (baton-log 管理)
  └─ AC-2: TC-T01-02, TC-T07-02 [unit]

REQ-005 (CEG frontmatter)
  └─ AC-1: TC-T02-01, TC-T02-02, TC-T02-03 [unit]
  └─ AC-2: TC-T07-01, TC-T07-03 [integration]

REQ-007 (Phase Agent 起動)
  └─ AC-1: TC-T04-01, TC-T06-03, TC-T06-04 [e2e/integration]
  └─ AC-2: TC-T04-06 [integration]

REQ-008 (Adversarial Review)
  └─ AC-1: TC-T06-01, TC-T06-05 [integration]
  └─ AC-2: TC-T06-02 [integration]
```

---

## 実行順序（推奨）

```
Phase 1 (unit - 独立):
  T01 unit + T02 unit + T03 unit + T07 unit
  並列実行可。所要時間目安: 5 分

Phase 2 (integration - 依存あり):
  T01 integration → T03 integration → T05 integration
  T04 integration + T06 integration（並列可）
  所要時間目安: 15 分

Phase 3 (e2e - 実 GitHub API):
  T04 e2e + T05 e2e + T06 e2e
  ステージング環境で実行。所要時間目安: 30 分

Phase 4 (security):
  T01-SEC + T03-SEC
  ShellCheck 静的解析と組み合わせて実行。所要時間目安: 5 分
```

---

## 除外事項

| 除外内容 | 理由 |
|---|---|
| 本番 GitHub リポジトリへの実際のラベル操作 | ステージング環境に限定 |
| `ANTHROPIC_API_KEY` を使った Claude API の実際の応答検証 | LLM 出力のランダム性のため unit テスト対象外。e2e でサンプル確認 |
| GitHub Actions の課金上限テスト | 本番環境依存 |

---

## 合格基準

- **P0 テスト 34 件が全て通過**すること
- **AC カバレッジ 23/23 件（100%）**を維持すること
- **ShellCheck** が `.tsumigi/lib/*.sh`, `.tsumigi/hooks/*.sh` でエラー 0 件であること
- **セキュリティテスト（TC-T01-SEC-01, TC-T03-SEC-01）が通過**すること

---

## リスクと対策

| リスク | 確率 | 影響 | 対策 |
|--------|------|------|------|
| e2e テストが GitHub API 障害で失敗 | 低 | 中 | リトライ 3 回 + スキップフラグ |
| `mock_gh` の実装漏れで integration テストが通る | 中 | 高 | `mock_gh` の呼び出し履歴を毎テスト後に検証 |
| LLM 出力の非決定性で e2e が不安定 | 高 | 低 | e2e は「構造チェック（必須フィールドの存在）」に限定。内容品質は Adversary に委譲 |
