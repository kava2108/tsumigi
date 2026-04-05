---
tsumigi:
  node_id: "adversary:tsumigi-v3-harness"
  artifact_type: "adversary_report"
  phase: "TEST"
  issue_id: "tsumigi-v3-harness"
  created_at: "2026-04-05T06:00:00Z"
  updated_at: "2026-04-05T12:00:00Z"
coherence:
  id: "adversary:tsumigi-v3-harness"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "validates"
      confidence: 0.95
      required: true
  band: "Amber"
---

# Adversary Report: tsumigi-v3-harness

**実行日時**: 2026-04-05T06:00:00Z  
**全体判定**: ❌ FAIL（初回）→ ✅ RESOLVED（全次元）  
**FAIL 次元**: 4 件（D1, D2, D4, D5）  
**修正終了**: D1, D2, D4, D5 — 全次元 RESOLVED（2026-04-05）  
**Adversary モード**: コンテキスト分離 + 強制否定バイアス

---

## 判定サマリー

| 次元 | 判定(初回) | 判定(現在) | 指摘件数 |
|------|------|------|------|
| 1. Spec Fidelity | ❌ FAIL | ✅ RESOLVED | 1 → 修正済み |
| 2. Edge Case Coverage | ❌ FAIL | ✅ RESOLVED | 4 → TC 追加済み |
| 3. Implementation Correctness | ✅ PASS | ✅ PASS | 1（軽微） |
| 4. Structural Integrity | ❌ FAIL | ✅ RESOLVED | 1 → 修正済み |
| 5. Verification Readiness | ❌ FAIL | ✅ RESOLVED | 4 → Bash テストスクリプト 13/13 PASS |

---

## 次元別詳細

### 次元 1: Spec Fidelity — ✅ RESOLVED

> **修正済み** (2026-04-05): `/tsumigi:implement tsumigi-v3-harness T03 --update` により `_check_ceg()` を jq DFS 実装に刷新。REQ-003-AC-2 充足済み。

**AC 22 件 vs 実装のマッピング**

| AC-ID | 記述（要約） | 実装確認 | 判定 |
|---|---|---|---|
| REQ-001-AC-1 | `phase:xxx` 付与 → Phase Agent 起動 | `vckd-pipeline.yml` ルーティング | ✅ |
| REQ-001-AC-2 | Gate PASS + AUTO_STEP=false → `pending:next-phase` | `emit_pending()` | ✅ |
| REQ-001-AC-3 | Gate PASS + AUTO_STEP=true → 即座に次ラベル | `emit_baton()` | ✅ |
| REQ-001-AC-4 | `approve` 付与 → pending 解除・次ラベル | `on_label_added()` | ✅ |
| REQ-001-AC-5 | Gate FAIL → `blocked:xxx` 付与 | `emit_blocked()` | ✅ |
| REQ-002-AC-1 | AUTO_STEP=false → `emit_pending` | `dispatch_baton()` 分岐 | ✅ |
| REQ-002-AC-2 | AUTO_STEP=true → `emit_baton` | `dispatch_baton()` 分岐 | ✅ |
| REQ-002-AC-3 | config.yaml 不在 → AUTO_STEP=false フォールバック | `_get_config()` デフォルト | ✅ |
| REQ-003-AC-1 | Gate 実行 → 必須成果物確認 | `_check_artifacts()` | ✅ |
| **REQ-003-AC-2** | **Gate 実行 → CEG 循環依存チェック** | **`_check_ceg()` jq DFS 実装（修正済み）** | ✅ |
| REQ-003-AC-3 | Gate 実行 → フェーズ固有チェック | `_check_phase_specific()` | ✅ |
| REQ-003-AC-4 | Gate 実行 → Gray ノードなし確認 | `_check_gray()` | ✅ |
| REQ-004-AC-1 | フェーズ完了 → GitHub コメント投稿 | `_gh_with_retry issue comment` | ✅ |
| REQ-004-AC-2 | バトン遷移 → baton-log.json 記録 | `_append_transition()` | ✅ |
| REQ-005-AC-1 | 成果物生成 → coherence frontmatter 付与 | `imp_generate.md` step | ✅ |
| REQ-005-AC-2 | coherence-scan → coherence.json 再構築 | `coherence-scan.md` | ✅ |
| REQ-006-AC-1 | harness.enabled=false → v1.0 互換動作 | `_check_harness_enabled()` | ✅ |
| REQ-006-AC-2 | harness.enabled=false → ラベル変更なし | 全公開関数の `|| return 0` | ✅ |
| REQ-007-AC-1 | RequirementsAgent 起動 → requirements.md | `requirements-agent.md` | ✅ |
| REQ-007-AC-2 | 3 回リトライ失敗 → `blocked:escalate` | `emit_escalate()` + retry family | ✅ |
| REQ-008-AC-1 | TEST→OPS Gate → 5 次元評価 | `adversary-agent.md` | ✅ |
| REQ-008-AC-2 | Adversarial FAIL → 次元根拠コメント | `adversary-agent.md` FAIL routing | ✅ |

**指摘 D1-01: REQ-003-AC-2 — 循環依存チェックが未実装（修正済み）**

修正前は `jq empty`（JSON 構文確認のみ）だったが、以下の 3 段階実装に刷新:

1. JSON 構文バリデーション（`jq empty`）
2. Fast path: `summary.warnings[].type == "circular_dep"` カウント確認
3. Full DFS: `def dfs(node; stack; adj)` — jq 内の再帰関数でサイクル検出

**影響**: 循環依存を持つ CEG がある状態では Phase Gate が FAIL を返すよう修正。仕様違反での次フェーズ進行が防止された。

---

### 次元 2: Edge Case Coverage — ✅ RESOLVED

> **修正済み** (2026-04-05): `/tsumigi:test tsumigi-v3-harness T04〜T07` によりセキュリティ TC を T04, T05, T06, T07 に追加。D2-01〜D2-04 全件対応済み。

**セキュリティテストケース分布（導入後）**

| タスク | 正常系 | 異常系 | セキュリティ | 備考 |
|---|---|---|---|---|
| T01 | 3 | 2 | 0 | (T03 に委任) |
| T02 | 5 | 2 | 0 | — |
| T03 | 9 | 5 | 1 | TC-T03-SEC-01 |
| T04 | 4 | 1 | **2** | TC-T04-SEC-01/02（プロンプト injection） |
| T05 | 3 | 1 | **2** | TC-T05-SEC-01/02（ラベル injection） |
| T06 | 3 | 1 | **2** | TC-T06-SEC-01/02（コンテキスト分離） |
| T07 | 2 | 1 | **2** | TC-T07-SEC-01/02（YAML injection） |

**対応内容**:

| 指摘 | 対応 TC | ステータス |
|--------|---------|----------|
| D2-01: T05 ラベル名インジェクションテスト皆無 | TC-T05-SEC-01, TC-T05-SEC-02 | ✅ 追加済み |
| D2-02: T04/T06 プロンプトインジェクションテスト皆無 | TC-T04-SEC-01/02, TC-T06-SEC-01/02 | ✅ 追加済み |
| D2-03: T06 アドバーサリ分離検証なし | TC-T06-SEC-01（分離バイパス試行 TC） | ✅ 追加済み |
| D2-04: T07 YAML インジェクションテスト皆無 | TC-T07-SEC-01, TC-T07-SEC-02 | ✅ 追加済み |

> **注記**: TC-T04-SEC-01/02, TC-T06-SEC-01 の信頼性は 🟡 推定（LLM の prompt injection 耐性は環境依存）。技術的強制機構（ファイルシステム権限）の導入は将来検討課題として未カバーケースに記載した。

---

### 次元 3: Implementation Correctness — ✅ PASS

**確認済み項目**:

| 項目 | 判定 | 根拠 |
|---|---|---|
| `(( ac_count >= 3 )) \|\| return 1` パターン（set -e との整合） | ✅ | `\|\|` が `set -e` を抑制する正当な Bash 慣用句 |
| `while (( attempt < max_retries ))` の終了条件 | ✅ | while 条件の false は `set -e` の対象外 |
| `dispatch_baton` の整数バリデーション | ✅ | `[[ "$var" =~ ^[0-9]+$ ]]` で exit 2 |
| `emit_pending` の検証後ラベル操作順序 | ✅ | 検証 → 削除 → 追加（IMP §1.4 と一致） |
| `mktemp` + `mv` によるアトミック JSON 更新 | ✅ | 全 4 箇所で実施 |
| `jq empty` による JSON バリデーション | ✅ | 破損検知 → `.bak` リネーム → 再初期化 |

**軽微な指摘 D3-01（FAIL 判定対象外）**:

`on_label_added()` 内の `gh issue view` がリトライなしで呼ばれている:
```bash
issue_labels=$(gh issue view "$issue_number" --json labels \
  --jq '.labels[].name' 2>/dev/null || echo "")
```
`_gh_with_retry` を使わないため、一時的な GitHub API 障害で `issue_labels=""` となり、
`pending:next-phase` が見つからないとして誤ったエラーコメントが投稿される。
データ破損ではないが、承認処理の偽陰性（誤ったエラー報告）が発生しうる。

---

### 次元 4: Structural Integrity — ✅ RESOLVED

> **修正済み** (2026-04-05): `/tsumigi:implement tsumigi-v3-harness T03 --update` により `on_label_added()` を 4 ヘルパー関数 + 15 行オーケストレーターに SRP リファクタリング済み。

**指摘 D4-01: `on_label_added` 関数 — SRP 違反（修正済み）**

ファイル: `.tsumigi/lib/on-label-added.sh`  
関数行数: 92 行 → **29 行**（修正後）

```
修正前（92行・6責務混在）→ 修正後（4ヘルパー関数 + 15行オーケストレーター）:
  _validate_approve_request()          ← バリデーション + next_candidate 解決
  _update_github_labels_for_approval() ← ラベル操作 × 3
  _finalize_baton_for_approval()       ← baton-log.json 更新
  _notify_approval()                   ← コメント投稿
  on_label_added()                     ← フロー制御のみ（~15行）
```

**その他の構造確認（PASS）**:
- 循環依存: `phase-gate.sh` ← `on-label-added.sh` / `post-tool-use.sh`（一方向） ✅
- DRY: `_gh_with_retry` による再利用 ✅
- ハードコード定数: `max_retries=3`, `delay=2`（IMP §1.5 に定義あり、設定外出化なし）

---

### 次元 5: Verification Readiness — ✅ RESOLVED

> **修正済み** (2026-04-05): `/tsumigi:test tsumigi-v3-harness T03` により以下を実施。
>
> - `specs/tsumigi-v3-harness/tests/T03/test_phase_gate.sh` を新規作成（13 テストケース実装）
> - テスト実行結果: **13/13 PASS**（正常系 8件 + 異常系 4件 + セキュリティ 1件）
> - テスト実行中に `_check_ceg()` の jq DFS 構文バグ（jq 1.7 非互換）を発見・修正
> - TC-T03-03/04 にコメント投稿アサーション追加（testcases.md 更新）
> - TC-T03-08 の AC タグに `REQ-006-AC-1, REQ-006-AC-2` を追加（カバレッジ 13/13 = 100%）

**解決した D5 指摘の詳細:**

| 指摘 | 状態 | 対応 |
|------|------|------|
| D5-01: TC-T03-13 実装不能 | ✅ 解消 | `_check_ceg()` jq DFS 修正後、TC-T03-13 は正常動作。信頼性を 🔵 確定 に更新済み |
| D5-02: REQ-006-AC-1/2 未リンク | ✅ 解消 | TC-T03-08 の AC タグに追加、カバレッジサマリー 11/11 → 13/13 に更新 |
| D5-03: コメント投稿未検証 | ✅ 解消 | TC-T03-03/04 の期待結果にコメント投稿確認を追加、Bash テストでアサート済み |
| D5-04: T04〜T07 セキュリティ TC 欠如 | ✅ 解消（前セッション） | 各 testcases.md にセキュリティ TC × 2 件追加済み（8 件合計） |

**Bash テストスクリプト実行結果:**

```
specs/tsumigi-v3-harness/tests/T03/test_phase_gate.sh
  PASS=13 / FAIL=0 / SKIP=0
```

---

## 自動ルーティング

FAIL 次元に対して以下のアクションが必要です：

| # | 次元 | 指摘 | アクション |
|---|---|---|---|
| 1 | D1 Spec Fidelity | REQ-003-AC-2: `_check_ceg()` 循環依存検出なし | `_check_ceg()` に DFS/BFS ベースの循環依存検出を実装（`coherence-scan.md` のアルゴリズムを移植） |
| 2 | D2 Edge Case | T04/T05/T06/T07 のセキュリティテスト欠如 | 各 testcases.md にセキュリティ TC を追加 |
| 3 | D4 Structural | `on_label_added` 92 行・6 責務 SRP 違反 | 関数を `_validate_approve_request()`, `_update_github_labels()`, `_update_baton_log()`, `_notify_approval()` に分割 |
| 4 | D5 Verification | テストコード不存在・TC-T03-13 実装不一致 | `tests/` 以下に Bash テストスクリプト（bats または plain sh）を実装、TC-T03-13 を修正 |

**推奨コマンド**:
```
D1 / D3 → /tsumigi:implement tsumigi-v3-harness T03 --update
D2 / D5 → /tsumigi:test tsumigi-v3-harness T04
           /tsumigi:test tsumigi-v3-harness T05
           /tsumigi:test tsumigi-v3-harness T06
           /tsumigi:test tsumigi-v3-harness T07
D4       → /tsumigi:imp_generate tsumigi-v3-harness --update
```

---

## Adversary の総評

**全体品質評価: ✅ リリース可能（全次元 RESOLVED）**

> **更新** (2026-04-05): 全 4 次元の指摘が解消された。初回評価時点の問題と解決状況:

- **D1（REQ-003-AC-2）**: `_check_ceg()` が jq DFS 実装（jq 1.7 互換）に刷新され、A→B→A 等の循環依存を正しく検出する。テスト実行で確認済み（TC-T03-13 PASS）。
- **D2（セキュリティ TC 欠如）**: T04〜T07 の各 testcases.md にセキュリティテストケースを 2 件ずつ追加（合計 8 件）。
- **D4（SRP 違反）**: `on_label_added()` を 4 ヘルパー関数 + 15 行オーケストレーターに分割。
- **D5（実行可能テストなし）**: `specs/tsumigi-v3-harness/tests/T03/test_phase_gate.sh` を実装し、13/13 PASS を確認。TC-T03-03/04 コメント投稿アサーション、TC-T03-08 AC タグも修正済み。

また、テスト実行中に **新たな実装バグ**（`_check_ceg()` の jq DFS コードが jq 1.7 で構文エラー）を発見し、即時修正した。これにより当初実装済みと見なしていた D1 修正が実際には動作していなかった問題も解消された。

---

*注意: この評価は Builder のコンテキストを持たない Adversary による独立評価です。  
実装者の意図・背景・設計判断は考慮していません。*
