---
imp_id: IMP-tsumigi-v3-harness
generated_at: "2026-04-05T00:00:00Z"
---

# リスクマトリクス: tsumigi-v3-harness

## リスク評価基準

| 軸 | H（高） | M（中） | L（低） |
|----|---------|---------|---------|
| 影響度 | バトン停止・フェーズ進行不能 | 一部 Issue で遷移が遅延 | UX の軽微な低下 |
| 発生確率 | 80%以上 | 30〜80% | 30%未満 |

優先度 = 影響度 × 発生確率（H×H=Critical / H×M または M×H=High / その他=Medium/Low）

---

## リスク一覧

| # | リスク内容 | 影響度 | 発生確率 | 優先度 | 対策 | オーナー |
|---|-----------|--------|---------|--------|------|---------|
| R-001 | `gh` CLI 認証失敗（トークン期限切れ・権限不足）により `emit_baton` / `emit_blocked` が実行できない | H | M | **High** | exponential backoff 3 回リトライ → `blocked:escalate` 付与。`/tsumigi:rescue` で回復 | T03 実装者 |
| R-002 | `baton-log.json` への同時書き込み競合（並列 Actions ジョブ、concurrency 制御が効かない場合） | H | L | **Medium** | `mktemp` + `mv` によるアトミック書き込み。`concurrency:` で同一 Issue への並列実行を防止 | T01/T03 実装者 |
| R-003 | `ANTHROPIC_API_KEY` が未設定のまま Actions が起動し、エラーなく完了したように見える（サイレント失敗） | H | M | **High** | ワークフロー冒頭でシークレット存在チェック → 未設定なら skip + Issue コメント通知 | T05 実装者 |
| R-004 | `AUTO_STEP=true` に設定されたまま本番リポジトリで実行し、意図しないフェーズ進行が発生する | H | L | **Medium** | デフォルトを `AUTO_STEP=false` に固定。`install --harness` 時も明示的な変更が必要 | T01 設計 |
| R-005 | `.vckd/config.yaml` が YAML として不正（手動編集ミス）で `yq` がクラッシュし、バトン処理全体が止まる | M | M | **Medium** | `yq` 失敗時に `AUTO_STEP=false` へフォールバック。警告コメントを Issue に投稿 | T03 実装者 |
| R-006 | `baton-log.json` が破損（不正 JSON）した場合、`jq` がエラーを吐き続けてフックが機能しない | M | L | **Low** | `jq empty` バリデーション → 失敗時に `.bak` リネームして再初期化 | T03 実装者 |
| R-007 | AdversaryAgent がコンテキスト分離ルールを破り、`patch-plan.md` の意図を読んで評価がバイアスされる | M | M | **Medium** | "読んではいけないもの" リストを agent ファイルに明示。チェックリスト TC-T06-03 で確認 | T06 実装者 |
| R-008 | `approve` ラベルと `phase:xxx` ラベルが同時に付与され、処理順序が不定になる | M | L | **Low** | Actions の `if:` 条件で `approve` ラベルを優先処理。`on_label_added.sh` を先に実行 | T05 実装者 |
| R-009 | GitHub Actions の実行時間が 6h を超えてタイムアウトし、中途半端な状態でフェーズが終了する | M | L | **Low** | タスク単位でジョブを分割（1 タスク = 1 ジョブ）。長時間タスクは `implement` の `--issue` フラグでタスク指定 | T05 設計 |
| R-010 | `commands/rescue.md` 実行時に誤った Issue 番号を指定し、別 Issue のブロックラベルを消去してしまう | M | L | **Low** | `rescue` 実行前に現在のラベルを表示し、ユーザーに確認プロンプトを提示する | T09 実装者 |

---

## 依存関係リスク

| 依存先 | リスク | 影響 | 緩和策 |
|--------|--------|------|--------|
| `gh` CLI（GitHub CLI） | バージョン互換性の変化 | `gh issue edit` / `gh issue comment` の引数仕様が変わると全バトン関数が壊れる | `gh --version` でバージョンチェック。最低 v2.30 以上を推奨 |
| `jq` | 未インストール環境での実行 | `baton-log.json` 更新が全て失敗する | `command -v jq` で存在確認 → 未インストールなら警告して exit |
| `yq` | 未インストール環境での実行 | `config.yaml` が読めず `AUTO_STEP=false` フォールバックが常時発動 | `command -v yq` で存在確認 → 警告を出すが処理は継続（安全側） |
| Claude Code / `claude` CLI | ヘッドレスモードのオプション変更 | `--print --max-turns 50` が非推奨になった場合 Actions が起動できない | Actions ワークフロー内でバージョンピニングを行う |
| Anthropic API | レートリミット・障害 | Agent の応答が途中でタイムアウトし、`blocked:escalate` が多発する | リトライポリシーの delay を長く設定。障害時は `rescue` コマンドでリセット |

---

## 残留リスク（対策後も残るリスク）

| リスク | 残留理由 | 受容判断 |
|--------|---------|---------|
| R-003: ANTHROPIC_API_KEY 未設定のサイレント失敗 | Secrets が設定されていない fork リポジトリでは通知コメントも出ない可能性がある | 受容済み（セットアップ手順に明記） |
| R-007: AdversaryAgent のコンテキスト分離 | LLM の動作はプロンプトで制御するため、完全な保証はできない | 要監視（TC-T06-03 で継続的に確認） |
| R-010: rescue の誤操作 | 確認プロンプトがあっても誤入力の可能性は残る | 受容済み（git コミット履歴から回復可能） |
