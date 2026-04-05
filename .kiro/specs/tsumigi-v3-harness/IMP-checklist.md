---
imp_id: IMP-tsumigi-v3-harness
imp_version: "1.1.0"
generated_at: "2026-04-05T00:00:00Z"
signed_off_at: "2026-04-05T00:00:00Z"
personas: ["arch", "security"]
signoff_status: "conditional"
---

# IMP レビューチェックリスト: tsumigi-v3-harness

## 使い方
このチェックリストはレビュアーが IMP を承認する前に確認する項目です。
各項目を確認したら `[ ]` を `[x]` に変更してください。

---

## 共通チェック（全レビュアー必須）

- [x] **Executive Summary** が 3 行以内で要点を伝えている
  > §0 IMP Overview が実質的な ES として機能。kiro 統合 IMP の設計ドキュメントとして適切な記述範囲内と判断。
- [x] **issue_id** が issue-struct.md の issue_id と一致している
  > issue-struct.md は kiro 統合のため不在（既知の例外）。全成果物で "tsumigi-v3-harness" に統一されていることを確認済み。
- [x] **受け入れ基準** が EARS 記法で記述されている（22 件全て）
  > §4 AC Traceability に 22 件 AC（REQ-001-AC-1〜REQ-008-AC-2）を確認。全件 EARS 形式。
- [ ] **ロールバック計画** が具体的な手順で記述されている
  > ⚠️ IMP.md 本体に "ロールバック計画" セクションが存在しない。`IMP-risks.md`（R-001〜R-010 に緩和策記載）および `commands/rescue.md` が実質的なロールバック手順として機能するが、IMP.md 本体への追記を推奨（次 Wave 対応）。
- [x] **🔴 不明項目** がゼロである（または着手前に解決済み）
  > IMP.md 全文を横断的に確認。🔴 マークのある不明項目は 0 件。
- [x] §7 Implementation Status の T01〜T09 が全て ✅ になっている
  > §7.1 タスク別実装状況を確認。T01〜T09 全件が ✅ 完了（T08/T09 は T03 内包として記録）。

---

## アーキテクチャレビュー（arch）

### Baton Infrastructure（T01）

- [x] `.vckd/config.yaml` のスキーマが TDS §3.4 と整合している
  > rev-schema.md で確認済み。harness.enabled / baton.auto_step / drift_check.threshold のキー構造が TDS §3.4 と一致。
- [x] `post-tool-use.sh` → `phase-gate.sh` の呼び出しフローが TDS §16.2 方式 A と一致している
  > rev-spec.md F-02 に詳細記録。post-tool-use.sh が VCKD_GATE_RESULT を評価して dispatch_baton / emit_blocked に分岐する設計が方式 A に準拠。
- [x] `graph/baton-log.json` / `graph/coherence.json` の初期構造が TDS §3.2〜3.3 スキーマ準拠である
  > rev-schema.md で 4 スキーマ（config.yaml / baton-log / coherence / frontmatter）を確認。IMP 差分ゼロ。

### Phase Gate ロジック（T03）

- [x] `dispatch_baton()` → `emit_pending()` / `emit_baton()` の分岐が TDS §5.2 疑似コードと一致している
  > phase-gate.sh L333-356 の `dispatch_baton()` 実装を確認。AUTO_STEP 分岐ロジックが TDS §5.2 と一致。
- [x] `check_phase_gate()` の 4 ステップ（必須成果物 → CEG → フェーズ固有 → Gray）が実装されている
  > phase-gate.sh L201〜 `check_phase_gate()` に `_check_artifacts()` → `_check_ceg()` → `_check_phase_specific()` → `_check_gray()` の 4 ステップを確認。
- [x] `on_label_added()` の `approve` ハンドリングが UC-002 の主フローを網羅している
  > on-label-added.sh + vckd-pipeline.yml `handle-approve` ジョブで UC-002 主フロー（pending 解除 → 次フェーズラベル付与）を確認。
- [x] `baton-log.json` への書き込みが `mktemp` + `mv` によるアトミック操作になっている
  > phase-gate.sh L93/L129/L151/L379 の 4 箇所で `mktemp` + `mv` パターンを確認。
- [x] フェーズ遷移マップ（REQ→TDS→IMP→TEST→OPS→CHANGE）に漏れがない
  > vckd-pipeline.yml routing（route-agent ジョブ）で全 6 フェーズ（req/tds/imp/test/ops/change）のルーティングを確認。
- [x] T08 相当の `_check_harness_enabled()` が全公開関数の冒頭で呼ばれている
  > phase-gate.sh L164 / L202 / L334 / L358 / L411 / L451 の全公開関数冒頭に `_check_harness_enabled || return 0` を確認。

### Phase Agent 専門化（T04/T06）

- [x] 全 Agent ファイルが §16.3 の 8 セクション構造（役割・環境確認・入力許可/禁止・手順・Phase Gate・PASS/FAIL 基準・リトライポリシー）を持つ
  > requirements-agent.md / adversary-agent.md の構造を確認。全 7 Agent ファイルが同形式の 8 セクション構造を持つことを確認済み（rev-spec.md §2 参照）。
- [x] RequirementsAgent の "読んではいけないもの" リストに IMP.md・patch-plan.md が含まれている
  > requirements-agent.md L29: `specs/` 以下の IMP.md・patch-plan.md を明示的に禁止。
- [x] AdversaryAgent の "読んではいけないもの" リストに drift-report.md・impl-memo.md・以前の adversary-report.md が含まれている
  > adversary-agent.md L37/L39/L40: drift-report.md / impl-memo.md / 以前の adversary-report.md を明示的に禁止。
- [x] AdversaryAgent の「強制否定バイアス」条項が明記されている
  > adversary-agent.md L14: `**強制否定バイアス（Forced-Negative Bias）**` として明記。「問題が見つからないという結論を出してはいけない」条項を確認。
- [x] ImplementAgent に「P0 完了後に P1 Issue へ `phase:imp` を付与する」ロジックが記述されている
  > implement-agent.md L71-74: P0 完了後に P1 Issue へ `phase:imp` ラベルを付与する手順を確認。

### GitHub Actions 統合（T05）

- [x] `concurrency: group: "vckd-issue-${{ github.event.issue.number }}"` が設定されている
  > vckd-pipeline.yml L8-10: `concurrency.group: "vckd-issue-${{ github.event.issue.number }}"` を確認。
- [x] ラベル→エージェントのルーティングテーブルが全 6 フェーズ（req/tds/imp/test/ops/change）を網羅している
  > vckd-pipeline.yml `route-agent` ジョブの `case` 文で req/tds/imp/test/ops/change の 6 フェーズを網羅していることを確認。
- [x] `approve` ラベルが `on_label_added.sh` に正しくルーティングされる（Claude Code 不要）
  > vckd-pipeline.yml L59-61（is_approve=true）→ `handle-approve` ジョブ → `on-label-added.sh "$VCKD_ISSUE_NUMBER" "approve"` の経路を確認。
- [x] ワークフローの変更ファイル一覧に `.github/workflows/vckd-pipeline.yml` が含まれている
  > specs/tsumigi-v3-harness/implements/T05/patch-plan.md の変更対象ファイルに `.github/workflows/vckd-pipeline.yml` が含まれていることを確認。

### coherence-scan / baton-status（T07）

- [x] `coherence-scan` の 5 ステップアルゴリズム（Glob→ノード構築→エッジ構築→バリデーション→書き込み）が実装されている
  > commands/coherence-scan.md に Step1〜Step5 の 5 ステップアルゴリズムを確認。
- [x] 循環依存チェック（DFS）が `coherence-scan` に含まれている
  > commands/coherence-scan.md Step4 バリデーションに DFS による循環依存チェックを確認。
- [x] dangling reference 検出時に band を "Amber" に強制設定する処理がある
  > commands/coherence-scan.md Step4 および IMP T07 §1.5 Edge Cases に dangling reference 検出時 Amber 強制設定を確認。
- [x] `baton-status` の表示が 4 カテゴリ（アクティブ・承認待ち・ブロック・直近 10 件）を含む
  > commands/baton-status.md に 4 カテゴリ（アクティブ Issue / 承認待ち / ブロック中 / 直近 10 件バトン遷移）を確認。

---

## セキュリティレビュー（security）

### Bash スクリプト全般（T01/T03）

- [x] `set -euo pipefail` が全 sh ファイルの先頭に設定されている
  > phase-gate.sh L6 / post-tool-use.sh L9 / on-label-added.sh L6 の 3 ファイル全てで確認。
- [x] `VCKD_ISSUE_NUMBER` の整数バリデーション（`[[ "$var" =~ ^[0-9]+$ ]]`）が実装されている
  > phase-gate.sh L341: `[[ "$issue_number" =~ ^[0-9]+$ ]] || { echo "ERROR: invalid issue_number" >&2; return 2; }` を確認。
- [x] `gh` コマンドへの引数は変数展開を避け、クォートで保護されている（インジェクション対策）
  > phase-gate.sh の emit_* 関数群で gh コマンド引数がダブルクォートで保護されていることを確認。
- [x] `baton-log.json` の書き込みは `mktemp` 経由のアトミック操作になっている（競合書き込み防止）
  > phase-gate.sh L93/L129/L151/L379 の 4 箇所で mktemp + mv アトミックパターンを確認。
- [x] `baton-log.json` が破損していた場合に `.bak` にリネームして再初期化する処理がある
  > phase-gate.sh L57-59: `jq empty` 失敗 → `mv "$BATON_LOG" "${BATON_LOG}.bak"` → 再初期化を確認。

### Secrets 管理（T05 GitHub Actions）

- [x] `ANTHROPIC_API_KEY` / `GITHUB_TOKEN` が `secrets.*` 経由でのみ参照され、ハードコードされていない
  > vckd-pipeline.yml L80/L106/L120/L121 で `secrets.GITHUB_TOKEN` / `secrets.ANTHROPIC_API_KEY` 経由のみを確認。ハードコードなし。
- [x] `ANTHROPIC_API_KEY` 未設定時のフェイルセーフ（スキップ＋コメント通知）が実装されている
  > vckd-pipeline.yml L96-104: `[[ -z "...ANTHROPIC_API_KEY..." ]]` → スキップ + Issue コメント通知を確認。
- [ ] ワークフローに `permissions:` セクションがあり最小権限原則が適用されている
  > ❌ `vckd-pipeline.yml` に `permissions:` セクションが存在しない。現在リポジトリのデフォルト設定（write-all）に依存。最小権限（`issues: write` / `contents: read`）を明示した `permissions:` ブロックの追加を推奨（diff を参照）。
- [x] `gh issue comment` / `gh issue edit` の実行者が明確に制限されている（GitHub Actions のコンテキストのみ）
  > `secrets.GITHUB_TOKEN` スコープにより GitHub Actions コンテキスト外からの実行を防止。`concurrency` によって同一 Issue への並列実行も制限済み。

### `config.yaml` / `baton-log.json` の不正入力（T03）

- [x] `yq` 失敗時に `AUTO_STEP=false` にフォールバックする（安全側に倒す設計）
  > phase-gate.sh `_get_config()`: `yq` 読み取り失敗時に第 2 引数のデフォルト値（AUTO_STEP の場合 "false"）にフォールバックする設計を rev-spec.md F-03 で確認。
- [x] `jq empty` による JSON バリデーションが `baton-log.json` 操作前に実行されている
  > phase-gate.sh L57: `_ensure_baton_log()` 内で `jq empty` を実行してから書き込み操作に進む構造を確認。
- [x] `emit_blocked` / `emit_escalate` のコメント文字列にユーザー入力が含まれる場合、エスケープされている
  > `VCKD_FAIL_REASON` は Bash 変数として引き渡され、gh コマンドへの引数はダブルクォートで保護。JSON 構築には `jq` の `--arg` エスケープを使用。

### Phase Agent コンテキスト分離（T04/T06）

- [x] AdversaryAgent の "読んではいけないもの" リストに機密性の高いファイルが含まれていない
  > adversary-agent.md の禁止リスト（drift-report.md / impl-memo.md / 以前の adversary-report.md）は実装成果物のみを列挙。機密情報（API キー・個人情報等）は含まれていない。
- [x] `ANTHROPIC_API_KEY` がエージェントのシステムプロンプトや Issue コメントにログとして出力されない設計になっている
  > vckd-pipeline.yml で `ANTHROPIC_API_KEY` は env セクション経由で渡され、echo など明示的な出力命令は存在しない。Issue コメントへの出力パスもなし。

---

## 承認欄

| ペルソナ | 担当者 | 承認日時 | 判定 | 備考 |
|---------|--------|---------|------|------|
| arch    | Claude (reviewer) | 2026-04-05T00:00:00Z | ✅ SIGNOFF | ロールバック計画セクションが IMP.md 本体になし。IMP-risks.md + rescue.md が代替として機能。次 Wave で IMP.md 本体への追記を推奨。 |
| security | Claude (reviewer) | 2026-04-05T00:00:00Z | ⚠️ CONDITIONAL SIGNOFF | `permissions:` セクション未追加（1 項目）。推奨 diff を sync-actions ACTION-006 として登録。次スプリントでの対応を条件に条件付き承認。 |

### 未チェック項目サマリー

| # | ペルソナ | 項目 | 対処 |
|---|---------|------|------|
| 1 | 共通 | ロールバック計画（IMP.md 本体） | IMP-risks.md + rescue.md が代替。次 Wave で IMP.md §8 Rollback Plan を追加推奨 |
| 2 | security | `permissions:` セクション | `vckd-pipeline.yml` への `permissions:` ブロック追加（diff 参照） |
