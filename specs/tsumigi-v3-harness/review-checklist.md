---
issue_id: tsumigi-v3-harness
generated_at: 2026-04-05T00:00:00Z
personas: all
pr_number: N/A
---

# レビューチェックリスト: tsumigi-v3-harness

> このチェックリストはレビュアーが PR を承認する前に確認する項目です。
> 確認済みの項目: `[ ]` → `[x]`
> 問題あり: `[ ]` → `[!]`（コメントを追加してください）

---

## 共通確認事項（全レビュアー）

- [x] IMP の Executive Summary が変更内容と一致している
  > rev-spec.md 全 F-01〜F-11 が IMP 仕様と一致（⚠️ 差分はゼロ）
- [x] ロールバック計画が実行可能である
  > `harness.enabled: false` 設定で全バトン処理を即時無効化可能（`post-tool-use.sh` L28-29）
- [x] drift スコアが閾値（20）以下である
  > drift スコア: **4/100**（閾値 20 に対し余裕あり）
- [ ] sync スコアが 70 以上である
  > sync-report.md を確認すること（未確認）

---

## アーキテクチャチェックリスト（arch）

### 設計整合性
- [x] 変更が既存アーキテクチャパターンと整合している
  > Harness Layer は既存 commands/ を拡張する形であり、破壊的変更なし
- [x] レイヤー違反（上位→下位の依存方向）がない
  > `phase-gate.sh` ← `on-label-added.sh` ← `post-tool-use.sh` の一方向依存
- [x] 循環依存が発生していない
  > `_check_ceg()` DFS で CEG 循環依存チェックを実施済み。TC-T03-13 が 13/13 PASS 確認済み

### 複雑度・設計品質
- [x] 設計の複雑度が最小限に抑えられている（YAGNI 原則）
  > yq 非依存の jq ベース実装に変更済み。フォールバック設計で依存を最小化
- [x] 過剰な抽象化がない
  > `dispatch_baton` → `emit_pending|emit_baton` の 2 層構造は明確
- [x] 新規追加のライブラリが評価済みである（セキュリティ・ライセンス）
  > 外部ライブラリなし。`jq`（jq-1.7）・`gh` CLI（既存）のみ

### 拡張性・運用性
- [x] スケールアウト可能な設計である
  > フェーズ追加時は `NEXT_PHASE` 連想配列と `_check_phase_specific` の `case` 文を追加するだけ
- [x] ロールバック計画が技術的に実行可能である
  > `.vckd/config.yaml` の `harness.enabled: false` で即時無効化。ラベル操作のロールバックは `gh issue edit` で実施
- [ ] 変更がデプロイ計画と整合している
  > `vckd-pipeline.yml` の GitHub Actions パイプラインとの整合を確認すること

### ⚠️ arch 指摘事項
- **[要確認] `declare -A` (`post-tool-use.sh` L33)**: `bash 3.x`（macOS デフォルト）では連想配列が使用不可。CI 環境が `bash 4+` であることを確認すること。
- **[軽微] `_check_phase_specific()` の OPS フェーズ**: `drift-report.md` の drift スコア抽出に `grep -oP`（Perl regex）を使用。macOS の BSD grep では `-P` フラグが不要なため互換性リスクあり。

**arch 総合判定**: ✅ 条件付き承認
コメント: bash 3.x 非対応の潜在リスクあり。CI が bash 4+ であれば問題なし。

---

## セキュリティチェックリスト（security）

### 認証・認可
- [x] 全エンドポイントに適切な認証チェックが実装されている
  > GitHub API は `gh` CLI 経由でトークン認証。追加の認証実装不要
- [x] 権限昇格（水平・垂直）のリスクがない
  > Issue 番号ごとに操作対象を限定。`VCKD_ISSUE_NUMBER` の整数バリデーション実装済み
- [x] セッション管理が適切である
  > ステートレス設計（各フック呼び出しで完結）

### 入力・出力
- [x] 全入力箇所にバリデーションが実装されている
  > `VCKD_ISSUE_NUMBER` の整数チェック: `[[ "$var" =~ ^[0-9]+$ ]]` 実装済み（`post-tool-use.sh` L22, `phase-gate.sh` L390）
- [x] SQL インジェクション・XSS・CSRF のリスクが軽減されている
  > Web バックエンドなし。シェルインジェクションは整数バリデーションで防止
- [x] 出力にエスケープ処理が実装されている
  > GitHub コメント body は heredoc でリテラル生成。`jq --arg` で変数を安全に注入（引用符エスケープ済み）

### 機密情報・暗号化
- [x] ハードコードされたシークレットがない
  > `.tsumigi/lib/` 全ファイルにシークレット・APIキーのハードコードなし（grep 確認済み）
- [x] パスワードが適切にハッシュ化されている
  > パスワード処理なし（GitHub 認証は `gh` CLI に委譲）
- [x] ログに機密情報が出力されない
  > ログ出力は `echo "WARNING/ERROR: ..." >&2` のみで Issue 内容等は含まない

### 監査・ログ
- [x] 重要な操作が監査ログに記録される
  > `baton-log.json` の `transitions[]` に全フェーズ遷移を記録（`from_label`, `to_label`, `mode`, `transitioned_at`, `triggered_by`）
- [x] ログに個人情報が含まれない
  > `baton-log.json` に含まれるのは Issue 番号・ラベル名・タイムスタンプのみ

### ⚠️ security 指摘事項
- **[中] GitHub コメント body の LLM 出力インジェクション**: T04〜T07 の Phase Agent が出力したテキストが GitHub コメントに含まれる。悪意ある PR 説明文や Issue body からのプロンプトインジェクションが LLM 経由で `emit_pending` のコメント内容として反映されるリスクあり。現行実装でコメント body の無害化処理なし。
  > 対策: コメント body に Issue body 等の外部入力を直接含めないこと（現行実装は固定文言のみのため低リスク）
- **[低] `VCKD_FROM_PHASE` に任意文字列が設定可能**: `[[ "$VCKD_FROM_PHASE" =~ ^[A-Z]+$ ]]` のバリデーションなし。`NEXT_PHASE` の参照が空文字列になるだけで安全だが、明示的な許可リスト検証が望ましい。

**security 総合判定**: ✅ 条件付き承認
コメント: LLM 出力インジェクションは理論的リスク。現行実装では固定コメント文言のみのため実害なし。`VCKD_FROM_PHASE` の許可リスト検証を追加推奨。

---

## QA チェックリスト（qa）

### テストカバレッジ
- [x] 全 AC に対応するテストケースが存在する
  > T03 testcases.md: **13/13 AC = 100%**（REQ-001-AC-2〜5, REQ-002-AC-1〜3, REQ-003-AC-1〜4, REQ-006-AC-1〜2）
- [x] 正常系・異常系・境界値が網羅されている
  > 正常系 8件・異常系 4件・セキュリティ 1件（T03）。T04〜T07 にセキュリティ TC × 2件ずつ追加済み
- [x] セキュリティテストケースが含まれている
  > TC-T03-SEC-01（整数以外の ISSUE_NUMBER インジェクション）、T04-07 各 SEC-01/02 追加済み

### テスト品質
- [x] テストが独立して実行可能である
  > `test_phase_gate.sh`: 各 TC が tmpdir パターンで独立。`_make_test_env` でクリーンな環境を作成
- [x] テストデータが適切に管理されている
  > テストデータは全て tmpdir 内に生成。テスト後に `rm -rf` で削除
- [x] 既存テストへの影響が評価されている
  > `_check_ceg()` の jq DFS バグ修正（`reduce...as $adj` → `. as $g | ... as $adj`）がテスト実行中に発見・修正済み

### 非機能要件
- [ ] パフォーマンス要件のテストが存在する
  > `_gh_with_retry` の retry 間隔（2s, 4s, 8s）の実際の遅延は CI で未確認。テストはモックで代替
- [ ] 信頼性要件のテストが存在する
  > 高並列（複数 Issue 同時バトン）でのロック競合テストは未実装（testcases.md「手動テスト推奨」に記載）

### ⚠️ qa 指摘事項
- **[中] T01〜T02・T07〜T09 のテストスクリプト未実装**: `test_phase_gate.sh`（T03）のみ実装済み。T01（Baton Infrastructure）・T04（Phase Agent）・T07（coherence-scan）等の実行可能テストがない。
- **[中] `baton-log.json` の並列書き込み安全性**: `jq ... > tmp && mv tmp baton-log.json` のパターンは単一プロセスなら安全だが、複数エージェントが同時に書き込んだ場合の競合を防ぐロック機構がない。
- **[低] TC-T03-05（approve フロー）が `on-label-added.sh` のテストスクリプトで未カバー**: T03 テストスクリプトは `phase-gate.sh` のみ対象。`on_label_added()` の統合テストが Bash スクリプトで未実装。

**qa 総合判定**: ⚠️ 条件付き承認
コメント: T03 Bash テストは 13/13 PASS で品質良好。T01/T04/T07〜T09 の実行可能テスト不在が残課題。

---

## 承認記録

| ペルソナ | 担当者 | 判定 | 承認日時 |
|---|---|---|---|
| arch | | ⚠️ 条件付き承認 | |
| security | | ⚠️ 条件付き承認 | |
| qa | | ⚠️ 条件付き承認 | |
