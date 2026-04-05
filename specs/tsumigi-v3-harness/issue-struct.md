---
issue_id: tsumigi-v3-harness
created_at: "2026-04-05T00:00:00Z"
updated_at: "2026-04-05T14:00:00Z"
scope: harness
status: structured
tsumigi:
  node_id: "req:tsumigi-v3-harness"
  artifact_type: "requirements"
  phase: "REQ"
  issue_id: "tsumigi-v3-harness"
coherence:
  id: "req:tsumigi-v3-harness"
  band: "Green"
---

# Issue 構造定義: tsumigi-v3-harness

## 0. Summary

tsumigi AI-TDD エンジンに VCKD v3 Phase Gate / Baton Harness を実装し、
GitHub Issues のフェーズラベル遷移を自動化・可視化する。

## 1. 背景・動機（Why）

tsumigi は Issue → IMP → 実装 → テスト → 逆仕様 → 同期 の全フェーズを一貫して実行する AI-TDD エンジンである。
各フェーズの遷移を手動で管理すると遷移漏れ・ラベル不整合が発生しやすく、プロジェクトの進捗可視性が低下する。
VCKD Harness を導入することで、Phase Gate による品質チェックとバトン機構による自動遷移を実現する。

## 2. 受け入れ基準（EARS 記法）

| # | 条件 | 期待される振る舞い | 優先度 | 信頼性 |
|---|---|---|---|---|
| REQ-001-AC-1 | WHEN Issue に `phase:xxx` ラベルが付与された | THE SYSTEM SHALL Phase Gate チェックを実行し PASS/FAIL を判定する | P0 | 🔵 |
| REQ-001-AC-2 | WHEN Phase Gate が PASS かつ `AUTO_STEP=false` | THE SYSTEM SHALL `pending:next-phase` ラベルを付与してレビュー待ち状態にする | P0 | 🔵 |
| REQ-001-AC-3 | WHEN Phase Gate が PASS かつ `AUTO_STEP=true` | THE SYSTEM SHALL 次フェーズラベルを即座に付与する | P0 | 🔵 |
| REQ-001-AC-4 | WHEN `approve` ラベルが付与され `pending:next-phase` が存在する | THE SYSTEM SHALL 次フェーズラベルを付与し `pending:next-phase` を削除する | P0 | 🔵 |
| REQ-001-AC-5 | WHEN Phase Gate が FAIL した | THE SYSTEM SHALL `blocked:xxx` ラベルを付与しコメントを投稿する | P0 | 🔵 |
| REQ-002-AC-1 | WHEN `AUTO_STEP=false` が設定されている | THE SYSTEM SHALL `dispatch_baton` が `emit_pending` を呼ぶ | P0 | 🔵 |
| REQ-002-AC-2 | WHEN `AUTO_STEP=true` が設定されている | THE SYSTEM SHALL `dispatch_baton` が `emit_baton` を呼ぶ | P0 | 🔵 |
| REQ-002-AC-3 | WHEN `.vckd/config.yaml` が存在しない | THE SYSTEM SHALL `AUTO_STEP=false` にフォールバックする | P0 | 🔵 |
| REQ-003-AC-1 | WHEN Phase Gate が実行される | THE SYSTEM SHALL 必須成果物の存在を確認する | P0 | 🔵 |
| REQ-003-AC-2 | WHEN Phase Gate が実行される | THE SYSTEM SHALL CEG 循環依存チェックを実行する | P0 | 🔵 |
| REQ-003-AC-3 | WHEN Phase Gate が実行される | THE SYSTEM SHALL フェーズ固有チェックを実行する | P0 | 🔵 |
| REQ-003-AC-4 | WHEN Phase Gate が実行される | THE SYSTEM SHALL Gray ノードの有無を確認する | P0 | 🔵 |
| REQ-006-AC-1 | WHEN `harness.enabled=false` が設定されている | THE SYSTEM SHALL Phase Gate チェックをスキップし何もしない | P1 | 🔵 |
| REQ-006-AC-2 | WHEN `harness.enabled=false` が設定されている | THE SYSTEM SHALL `gh` コマンドを一切呼び出さない | P1 | 🔵 |
| REQ-010-AC-1 | WHEN `VCKD_FROM_PHASE` に不正な値が渡された | THE SYSTEM SHALL exit 2 を返しエラーメッセージを出力する | P1 | 🔵 |
| REQ-010-AC-2 | WHEN `VCKD_FROM_PHASE` が空文字列の場合 | THE SYSTEM SHALL 検証をスキップして処理を継続する | P1 | 🔵 |

## 3. スコープ定義

### 3.1 In Scope（今回の変更に含まれる）
- Baton Infrastructure（`emit_baton` / `emit_pending` / `dispatch_baton`）
- CEG frontmatter（coherence-scan 対応）
- Phase Gate ロジック（`check_phase_gate` / `_check_phase_specific`）
- Phase Agent システムプロンプト（REQ/TDS/IMP/TEST/OPS/CHANGE）
- GitHub Actions 統合（`vckd-pipeline.yml`）
- coherence-scan / baton-status コマンド
- 後方互換性（`harness.enabled=false`）
- rescue コマンドと escalate 処理
- phases.json 外部化（T13）
- VCKD_FROM_PHASE 許可リスト検証（T11）

### 3.2 Out of Scope（今回の変更に含まれない）
- tsumigi コア命令（`imp_generate`, `implement` 等）の変更
- GitHub Actions 以外の CI/CD への対応
- マルチリポジトリ対応

## 4. 非機能要件

| 種別 | 要件 | 測定方法 | 信頼性 |
|---|---|---|---|
| セキュリティ | `issue_number` は整数のみ受け付ける（Shell injection 防止） | `[[ "$var" =~ ^[0-9]+$ ]]` 検証 | 🔵 |
| 可用性 | `gh` コマンド失敗時は最大 3 回リトライ | exponential backoff（2s, 4s, 8s） | 🔵 |
| 耐久性 | `baton-log.json` 破損時はバックアップ後に再初期化 | `jq empty` バリデーション | 🔵 |

## 5. 依存関係・前提条件

| 依存先 | 種別 | 状態 | 影響 |
|---|---|---|---|
| `jq` コマンド | 外部ツール | 利用可能 | coherence-scan・baton-log 操作に必須 |
| `gh` CLI | 外部ツール | 利用可能 | ラベル操作・コメント投稿に必須 |
| GitHub Actions | 外部サービス | 設定済み | `vckd-pipeline.yml` の実行基盤 |
| `.vckd/config.yaml` | 設定ファイル | 任意（不在時フォールバック） | AUTO_STEP / harness.enabled の設定 |

## 6. エッジケース・リスク

| シナリオ | 影響 | 対策 |
|---------|------|------|
| `gh` コマンドがネットワーク障害で失敗 | M | 3 回リトライ後 `blocked:escalate` |
| `baton-log.json` が破損 | M | `.bak` にリネーム後に再初期化 |
| `VCKD_FROM_PHASE` に不正値が渡される | H | 許可リスト検証（exit 2） |
| `phases.json` が不在 | M | `return 1`（安全側 FAIL） |
| harness 無効化後の中間状態 | L | `commands/rescue.md` の手順で手動リカバリー |

## 7. Notes

- VCKD v3 Harness の実装は IMP.md（T01〜T18）で管理されている
- T01〜T15 は完了済み。T16〜T18 は P2-P2 優先度で未着手
