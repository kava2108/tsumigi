---
tsumigi:
  node_id: "sync-actions:tsumigi-v3-harness"
  artifact_type: "sync-actions"
  phase: "OPS"
  issue_id: "tsumigi-v3-harness"
  generated_at: "2026-04-05T00:00:00Z"
  total_actions: 5
---

# 手動対応アクション: tsumigi-v3-harness

整合性スコア: **90/100 (Excellent)** — 全アクションは Low 優先度です。  
対応完了後に `/tsumigi:sync tsumigi-v3-harness --report-only` で再確認してください。

---

## 優先度 LOW（余裕があれば）

### ACTION-001: issue-struct.md / tasks.md の整備

| 項目 | 内容 |
|---|---|
| **種別** | 成果物パス非標準（SY-001） |
| **影響** | チェック1（Issue ↔ IMP）と チェック5（逆仕様 ↔ Issue）の完全照合が不可 |
| **背景** | 本プロジェクトは kiro 統合（`.kiro/specs/`）を使用しているため、標準の `specs/tsumigi-v3-harness/issue-struct.md`・`tasks.md` が生成されていない |
| **対応方法 A** | `specs/tsumigi-v3-harness/issue-struct.md` を手動で作成し、IMP.md の 23 AC を EARS 記法で転記する（`/tsumigi:issue_init tsumigi-v3-harness` を参考に手動作成） |
| **対応方法 B** | IMP.md 冒頭に `.kiro/specs/tsumigi-v3-harness/design.md` へのリンクを追記し、Issue ソースを明示する |
| **担当** | |
| **期限** | 次回 sync 実行まで |

---

### ACTION-002: IMP-checklist.md のレビュアーサインオフ

| 項目 | 内容 |
|---|---|
| **種別** | 形式レビュー未実施（SY-002） |
| **影響** | アーキテクチャ・セキュリティレビューが形式上未完了のため、監査証跡が不完全 |
| **背景** | `.kiro/specs/tsumigi-v3-harness/IMP-checklist.md` の全 20+ 項目が `[ ]` 未チェック |
| **対応方法** | チェックリストの各項目を実装・テスト結果に照らして確認し、確認済み項目を `[x]` に更新する |
| **確認観点（主要）** | `_check_harness_enabled()` が全公開関数の冒頭で呼ばれているか（phase-gate.sh を読んで確認）、`concurrency:` が vckd-pipeline.yml に設定されているか |
| **担当** | arch / security レビュアー |
| **期限** | リリース前 |

---

### ACTION-003: phases.json 外部化の対応

| 項目 | 内容 |
|---|---|
| **種別** | D1 WARNING — 実装方式の乖離（SY-003、drift-report より） |
| **影響** | フェーズ固有チェックロジックの変更が Bash ファイルの直接編集を要求する（JSON での一覧管理より変更追跡が困難） |
| **背景** | IMP T03 §1.4 は「フェーズ固有チェックは `phases.json` で定義する」と仕様化したが、実装では `_check_phase_specific()` 内の `case "$from_phase" in` Bash 構文として直接実装 |
| **対応方法 A（推奨）** | IMP T03 §1.4 の記述を「Bash case 文による実装」に更新し、仕様と実装を一致させる（スコープが小さい） |
| **対応方法 B** | `.tsumigi/config/phases.json` を新規作成し、`_check_phase_specific()` から `jq` で読み込む形式に移行する（拡張性が上がる） |
| **コマンド例** | `対応方法 B を選択する場合: /tsumigi:implement tsumigi-v3-harness --task T03-patch-phases-json` |
| **担当** | |
| **期限** | 次回 Wave まで |

---

### ACTION-004: vckd-pipeline.yml に timeout-minutes を追加

| 項目 | 内容 |
|---|---|
| **種別** | D5 INFO — 設定漏れ（SY-004、drift-report より） |
| **影響** | Phase Agent ジョブが 6h (GitHub Actions デフォルト上限) を超過した場合、中途半端な状態でフェーズが終了する可能性がある |
| **背景** | IMP T05 §1.5 の「6h 超過時はジョブをタスク単位で分割」に対応する `timeout-minutes` 設定が `run-phase-agent` ジョブに存在しない |
| **対応方法** | `.github/workflows/vckd-pipeline.yml` の `run-phase-agent:` ジョブに `timeout-minutes: 350` を追加する |
| **変更内容** | ```yaml<br>  run-phase-agent:<br>    timeout-minutes: 350  # 5h50m（6h 上限にバッファ 10m を設ける）<br>    runs-on: ubuntu-latest<br>``` |
| **担当** | |
| **期限** | 次回 Wave まで |

---

### ACTION-005: ChangeAgent PR エビデンス 4 点添付の実行確認

| 項目 | 内容 |
|---|---|
| **種別** | 実行時確認（SY-005） |
| **影響** | AdversaryAgent の 5 次元評価結果・coherence.json サマリー・drift スコア・AC カバレッジ率の全 4 点が PR に添付されるかが未確認 |
| **背景** | ChangeAgent の PR エビデンス添付は LLM の実行に依存するため、静的な成果物分析では確認不可（TC-T06-04 は e2e テストとして定義） |
| **対応方法** | テスト環境で `/tsumigi:pr tsumigi-v3-harness` を実行し、生成される PR コメントに以下の 4 点が含まれることを確認する： |
| **確認項目** | 1. adversary-report.md の 5 次元 PASS/FAIL 表 / 2. coherence.json の Green/Amber/Gray 件数 / 3. drift スコア（drift-report.md から抽出） / 4. 全 AC-ID のカバレッジ率（100% 必須） |
| **担当** | QA |
| **期限** | Phase CHANGE 実行時 |

---

## 対応完了チェック

- [ ] ACTION-001: issue-struct.md / tasks.md の整備
- [ ] ACTION-002: IMP-checklist.md のレビュアーサインオフ
- [ ] ACTION-003: phases.json 外部化の対応（方法 A or B を選択）
- [ ] ACTION-004: vckd-pipeline.yml に timeout-minutes を追加
- [ ] ACTION-005: ChangeAgent PR エビデンス 4 点添付の実行確認
