---
issue_id: tsumigi-v3-harness
generated_at: 2026-04-05T00:00:00Z
drift_score: 4
threshold: 20
---

# リスクマトリクス: tsumigi-v3-harness

> 影響度 (Impact)・発生確率 (Prob) は High/Medium/Low の 3 段階。
> 優先度 (Priority) は自動算出: H/H→CRITICAL、H/M|M/H→HIGH、M/M→MEDIUM、L/any|any/L→LOW

---

## リスク一覧

| ID | カテゴリ | リスク概要 | 影響度 | 発生確率 | 優先度 | 緩和策 | 残留リスク |
|---|---|---|---|---|---|---|---|
| R-001 | Arch | `declare -A` がbash 4+ を要求（macOS デフォルト: bash 3.2） | MEDIUM | MEDIUM | MEDIUM | CI環境のbashを `bash --version` で事前確認し、`>=4.0` を保証する。`setup.sh` にバージョンチェックを追加 | bashバージョンが固定されるまでは残留 |
| R-002 | Arch | yq 未インストールの場合 `harness.enabled` が読めず harness が黙示的に無効化される | MEDIUM | MEDIUM | MEDIUM | `install --harness` に yq の存在確認と警告を追加。ドキュメントに前提条件として yq を明記 | yq普及率に依存 |
| R-003 | Arch | `NEXT_PHASE` 配列と `_check_phase_specific()` の case文で FSM 遷移が2箇所で管理される | LOW | MEDIUM | LOW | FSMの単一化は設計変更が大きいため、コメントで2箇所を明示し変更漏れを防ぐ。テストで両者の整合性を検証 | 保守コストとして残留 |
| R-004 | Arch | `_check_phase_specific()`（OPS フェーズ）が `grep -oP`（Perl regex）を使用：macOS 非互換 | LOW | LOW | LOW | `grep -oE` ＋ POSIX ERE パターンに置換、または `awk` で同等処理 | macOS上でのテスト追加まで残留 |
| R-005 | Security | LLM 経由のプロンプトインジェクション：Phase Agent の出力が GitHub コメント body に含まれる場合 | MEDIUM | LOW | LOW | Phase Agent の出力は固定文言テンプレートのみに限定。外部入力（Issue body等）を直接コメントに使用しない | 実装規約として残留 |
| R-006 | Security | `VCKD_FROM_PHASE` 環境変数に任意文字列が設定可能：NEXT_PHASE の参照が空になる | LOW | LOW | LOW | `[[ "$VCKD_FROM_PHASE" =~ ^(REQ\|TDS\|IMP\|TEST\|OPS\|CHANGE)$ ]]` の許可リスト検証を追加 | 追加実装まで残留 |
| R-007 | Ops | `_gh_with_retry` の総リトライ遅延が最大 14 秒（2s+4s+8s）：CI タイムアウトを引き起こす可能性 | LOW | MEDIUM | LOW | リトライ上限をドキュメント化。CI タイムアウトを 60s 以上に設定。必要に応じて最大リトライ回数を削減 | CIの設定に依存 |
| R-008 | QA | `baton-log.json` の並列書き込み: 複数エージェントが同時に書き込む場合の競合 | MEDIUM | LOW | LOW | `flock` コマンドによるファイルロック追加を検討（Linux/macOS両対応）。高並列シナリオのテスト追加 | flock実装まで残留 |
| R-009 | QA | T01/T04/T07〜T09 の実行可能テストスクリプト未実装 | MEDIUM | HIGH | HIGH | 次フェーズで T01・T04・T07 の Bash テストスクリプトを実装。各 `testcases.md` の TC を自動化する | 次スプリントの対応まで残留 |
| R-010 | QA | TEST フェーズの判定パターン `grep -q "全体判定.*PASS\|PASS"` が汎用的すぎる（false-positive リスク） | LOW | LOW | LOW | パターンを `grep -q "^全体判定: PASS$"` に厳格化。またはライン完全一致で検索 | パターン修正まで残留 |

---

## 優先度ヒートマップ

```
           発生確率
影響度    HIGH    MEDIUM  LOW
HIGH      [R-009]
MEDIUM    [R-009] [R-001] [R-005]
                  [R-002] [R-008]
LOW               [R-003] [R-004]
                  [R-007] [R-006]
                          [R-010]
```

---

## CRITICAL/HIGH リスクのアクションアイテム

| ID | アクション | 担当 | 期限 |
|---|---|---|---|
| R-009 | T01/T04/T07〜T09 の Bash テストスクリプト実装 | 実装担当 | 次スプリント |

---

## リスクサマリー

| 優先度 | 件数 |
|---|---|
| CRITICAL | 0 |
| HIGH | 1 |
| MEDIUM | 2 |
| LOW | 7 |
| 合計 | 10 |

**全体リスク評価**: ⚠️ 条件付きリリース可
> CRITICAL リスクなし。HIGH リスク（R-009: テスト不在）は次スプリントで対応。セキュリティリスクは現行実装の範囲では低い。
