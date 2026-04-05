---
issue_id: tsumigi-v3-harness
generated_at: 2026-04-05T00:00:00Z
personas: all
---

# レビュー質問リスト: tsumigi-v3-harness

> このファイルはレビュアーが実装担当者に確認するための質問リストです。
> 各質問に回答が得られたら `answered_at` と `answer` を記入してください。

---

## Q1: 仕様の変更不可要素の確認（アーキテクチャ）

**質問**: `post-tool-use.sh` の `NEXT_PHASE` 連想配列（`declare -A`）は bash 4+ を必須とします。macOS のデフォルト bash（3.2）では動作しません。CI/CD 環境および開発者ローカル環境でのbashバージョン要件は明文化されていますか？

**対象箇所**: `.tsumigi/hooks/post-tool-use.sh` L33—L42

**期待する回答例**: 「CI は ubuntu-22.04 アクションランナーで bash 5.x を使用。macOS 開発者は Homebrew で bash 5 をインストールする手順を README に追記済み」

answered_at:
answer:

---

## Q2: 技術的負債・ライブラリ選定について（アーキテクチャ）

**質問**: `yq` が未インストールの場合、`.vckd/config.yaml` の `harness.enabled` が読めず harness が黙示的に無効化されます（`post-tool-use.sh` L18-25）。エラーメッセージを出力せず静かに無効化する設計は意図的ですか？ユーザーへの警告は不要と判断した理由を教えてください。

**対象箇所**: `.tsumigi/hooks/post-tool-use.sh` L18-25

answered_at:
answer:

---

## Q3: テスト計画の実行状況（QA）

**質問**: `test_phase_gate.sh`（T03）は 13/13 PASS が確認されています。一方、T01（Baton Infrastructure）・T04（Phase Agent 実装）・T07（coherence-scan）・T08/T09 に対応する Bash テストスクリプトが未実装です。これらのテストは本 PR に含めない判断ですか？含める場合はいつ実装予定ですか？

**対象箇所**: `specs/tsumigi-v3-harness/tests/` ディレクトリ

answered_at:
answer:

---

## Q4: セキュリティ上の懸念（セキュリティ）

**質問**: `dispatch_baton()` と `post-tool-use.sh` では `VCKD_ISSUE_NUMBER` の整数バリデーションが実装されています。一方、`VCKD_FROM_PHASE` 環境変数には許可リスト（REQ/TDS/IMP/TEST/OPS/CHANGE）の検証がありません。`VCKD_FROM_PHASE` に不正値が渡された場合の振る舞いを確認済みですか？また、許可リスト検証を追加する計画はありますか？

**対象箇所**: `.tsumigi/hooks/post-tool-use.sh` L44-55

answered_at:
answer:

---

## Q5: ロールバック戦略の実行可能性検証（アーキテクチャ）

**質問**: ロールバック計画は「`harness.enabled: false` で無効化」とされています。しかし、harness が途中まで動作して Issue のラベルを変更した後に無効化した場合、変更済みラベルはロールバックされません。この「中間状態」のリカバリー手順はドキュメント化されていますか？

answered_at:
answer:

---

## Q6: パフォーマンス・スケーラビリティへの影響（QA/Ops）

**質問**: `_gh_with_retry()` は最大 3 回リトライし、合計最大 14 秒（2+4+8s）の待機が発生します。GitHub Actions の `post-tool-use` フックが複数の Issue で並列実行された場合、各フックが最大 14 秒ブロックすることになります。CI のタイムアウト値は十分ですか？高並列時の挙動を確認済みですか？

**対象箇所**: `.tsumigi/lib/phase-gate.sh` `_gh_with_retry()` 関数

answered_at:
answer:

---

## その他の確認事項

### Q7（アーキテクチャ）: FSM の二重管理について

`NEXT_PHASE` 連想配列（`post-tool-use.sh`）と `_check_phase_specific()` の `case` 文（`phase-gate.sh`）の両方でフェーズ遷移を管理しています。新しいフェーズを追加する場合、2 箇所の修正が必要です。この二重管理は設計上の意図ですか？単一化の検討はされましたか？

answered_at:
answer:

---

### Q8（QA）: `baton-log.json` の並列書き込み安全性

`baton-log.json` への書き込みは `jq ... > tmp && mv tmp target` パターンです。複数の Issue が同時にフェーズ遷移した場合（例: 大規模プロジェクトで多数の Issue が存在する環境）、`flock` なしでは競合が発生します。現在の利用規模でこのリスクは許容範囲内と判断していますか？

answered_at:
answer:

---

### Q9（セキュリティ）: TEST フェーズ判定パターンの精度

`_check_phase_specific()` の TEST フェーズ判定で `grep -q "全体判定.*PASS\|PASS"` を使用しています。このパターンは "PASS" という文字列が含まれるファイル（例: テスト失敗レポートに "3/10 tests PASS"）でも true を返します。パターンをより厳格にする予定はありますか？

**提案**: `grep -q "^全体判定: PASS$"` または `grep -qm1 "全体判定.*PASS"` へ変更

answered_at:
answer:

---

## 質問サマリー

| ID | カテゴリ | 優先度 | ステータス |
|---|---|---|---|
| Q1 | arch | HIGH | 未回答 |
| Q2 | arch | MEDIUM | 未回答 |
| Q3 | qa | HIGH | 未回答 |
| Q4 | security | MEDIUM | 未回答 |
| Q5 | arch | MEDIUM | 未回答 |
| Q6 | qa | LOW | 未回答 |
| Q7 | arch | LOW | 未回答 |
| Q8 | qa | LOW | 未回答 |
| Q9 | security | LOW | 未回答 |
