---
tsumigi:
  node_id: "test:tsumigi-v3-harness:T07"
  artifact_type: "testcases"
  phase: "TEST"
  issue_id: "tsumigi-v3-harness"
  task_id: "T07"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "test:tsumigi-v3-harness:T07"
  depends_on:
    - id: "impl:tsumigi-v3-harness:T07"
      relation: "verifies"
      confidence: 1.0
      required: true
    - id: "imp:tsumigi-v3-harness"
      relation: "derives_from"
      confidence: 0.95
      required: true
  band: "Green"
---

# テストケースマトリクス: tsumigi-v3-harness / T07

**対象タスク**: T07 — coherence-scan / baton-status コマンド  
**生成日**: 2026-04-05  
**フォーカス**: unit, integration

---

## カバレッジサマリー

| AC | 正常系 | 異常系 | 境界値 | セキュリティ | 合計 | カバー状況 |
|---|---|---|---|---|---|---|
| REQ-005-AC-2 | 1 | 1 | 1 | 0 | 3 | ✅ |
| REQ-004-AC-2 | 1 | 0 | 0 | 0 | 1 | ✅ |
| — (Security) | 0 | 0 | 0 | 2 | 2 | ✅ |

カバレッジ率: 2/2 AC = **100%** / セキュリティ TC: 2 件（D2-04 対応）

---

## 正常系テストケース

### TC-T07-01: coherence-scan 実行後に全成果物ノードが coherence.json に存在する

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-005-AC-2 |
| **優先度** | P0 |
| **レイヤー** | integration |
| **前提条件** | `specs/` と `.kiro/specs/` に frontmatter 付き成果物ファイルが存在する |
| **入力** | `/tsumigi:coherence-scan tsumigi-v3-harness` を実行 |
| **操作** | 生成された `graph/coherence.json` を確認 |
| **期待結果** | `specs/**/*.md` の全 `coherence.id` が `coherence.json` の `nodes` に存在する |
| **信頼性** | 🔵 確定 |

---

### TC-T07-02: baton-status が baton-log.json の pending エントリを正確に表示する

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-004-AC-2 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `graph/baton-log.json` に `pending.42.next: "phase:tds"` が記録されている |
| **入力** | `/tsumigi:baton-status` を実行 |
| **操作** | 出力の「承認待ち」セクションを確認 |
| **期待結果** | Issue #42 と「次フェーズ候補: phase:tds」が表示される |
| **信頼性** | 🔵 確定 |

---

### TC-T07-03: coherence-scan が再実行（idempotent）で重複エントリを生成しない

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-005-AC-2 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | `coherence-scan` を一度実行した後の `coherence.json` が存在する |
| **入力** | 同じコマンドを再度実行 |
| **操作** | `coherence.json` のノード数を 1 回目と 2 回目で比較 |
| **期待結果** | ノード数が同じ（重複追加なし） |
| **信頼性** | 🔵 確定 |

---

## 異常系テストケース

### TC-T07-04: 循環依存が存在する場合に Red バンドで検出される

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-005-AC-2 |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | 2 つのファイルが互いに `depends_on` で参照し合っている（A→B→A） |
| **入力** | `coherence-scan` を実行 |
| **操作** | DFS によるサイクル検出ロジックを確認 |
| **期待結果** | 循環に含まれるノードが `band: "Red"` に設定され、警告が出力される（スキャン自体は完了） |
| **信頼性** | 🔵 確定 |

---

### TC-T07-05: ダングリング参照が Amber バンドになる

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P0 |
| **レイヤー** | unit |
| **前提条件** | あるファイルの `depends_on` に存在しない `node_id` が参照されている |
| **入力** | `coherence-scan` を実行 |
| **操作** | 該当ノードのバンドを確認 |
| **期待結果** | 参照元ノードが `band: "Amber"` に設定される |
| **信頼性** | 🔵 確定 |

---

### TC-T07-06: frontmatter が壊れたファイルがあっても他のファイルはスキャン完了する

| 項目 | 内容 |
|---|---|
| **対応 AC** | — |
| **優先度** | P1 |
| **レイヤー** | unit |
| **前提条件** | `specs/tsumigi-v3-harness/tests/broken.md` に不正な YAML frontmatter が含まれる |
| **入力** | `coherence-scan` を実行 |
| **操作** | `coherence.json` の内容と警告出力を確認 |
| **期待結果** | 破損ファイルがスキップされ（パスと行番号を警告出力）、他の正常ファイルはスキャン完了する |
| **信頼性** | 🔵 確定 |

---

## 境界値テストケース

### TC-T07-07: ファイルが 0 件の場合も coherence.json が正常に生成される

| 項目 | 内容 |
|---|---|
| **対応 AC** | REQ-005-AC-2 |
| **優先度** | P2 |
| **レイヤー** | unit |
| **前提条件** | `specs/` が空ディレクトリ |
| **入力** | `coherence-scan` を実行 |
| **期待結果** | `{"version":"1.0.0","nodes":{},"edges":[],"summary":{"green":0,"amber":0,"gray":0,"red":0}}` が生成される |
| **信頼性** | 🔵 確定 |

---
## セキュリティテストケース

### TC-T07-SEC-01: frontmatter に shell metacharacter を含む悪意ある値があってもコマンド実行されない

| 項目 | 内容 |
|---|---|
| **対応 AC** | — (D2-04: Adversary 指摘) |
| **優先度** | P0 |
| **レイヤー** | security |
| **脅威モデル** | 攻撃者が `specs/malicious/note.md` の frontmatter に `band: "Green"; rm -rf /tmp/test"` 等の悠意ある文字列を含め、`coherence-scan.md` の YAML パース時にコマンド実行を試みる |
| **前提条件** | `specs/malicious/note.md` の frontmatter:
```yaml
---
coherence:
  id: "malicious-node"
  band: "Green"; rm -rf /tmp/test
---
``` |
| **入力** | `coherence-scan` を実行 |
| **期待結果** | YAML パースエラーとしてファイルをスキップ（警告出力）。`/tmp/test` 删除が実行されない。他の正常ファイルは引き続きスキャン完了する |
| **検証方法** | 1) `yq` / `python-frontmatter` の YAML パーサ使用を確認（`eval` や `bash -c` 不使用） 2) `coherence-scan.md` 内の frontmatter 値取得コードに `jq` または `yq` が使われることを静的確認 3) `/tmp/test` が実行後も存在することを確認 |
| **信頼性** | 🔵 確定（`coherence-scan.md` が YAML パーサインタプリタ軏道で値を取得する限りインジェクションは発生しない） |

---

### TC-T07-SEC-02: frontmatter に極端に大きな値（DoS 的入力）が含まれてもスキャンが完了する

| 項目 | 内容 |
|---|---|
| **対応 AC** | — (D2-04: Adversary 指摘) |
| **優先度** | P1 |
| **レイヤー** | security |
| **脅威モデル** | frontmatter の `id` フィールドに 1MB 以上の文字列を設定し、YAML パーサまたは文字列操作のメモリ展開で OOM / タイムアウトを評罚する |
| **前提条件** | frontmatter の `coherence.id` に `"a" * 1000000` の文字列を設定した `specs/huge/note.md` |
| **入力** | `coherence-scan` を実行 |
| **期待結果** | コマンドが 60 秒以内に完了する。ファイルをスキップことれば后のスキャンが続行する（確定）。OOM クラッシュが起きない |
| **検証方法** | `coherence-scan` にタイムアウトガードを入れる（`timeout 60 coherence-scan`）。先頭 30 行のみを読む設計（Step 1）の場合は大部分無効化される |
| **信頼性** | 🔵 確定（`coherence-scan` の Step 1 が先頭 30 行のみを読む設計のため 1MB ファイルでもメモリ展開は限定的） |

---
## 未カバーケース（手動テスト推奨）

| # | 内容 | 理由 | 推奨対応 |
|---|---|---|---|
| 1 | 1000 ファイル以上のリポジトリでのスキャン所要時間 | 大規模データが必要 | ベンチマーク環境で計測 |
| 2 | `baton-status` の GitHub ラベル取得精度（実リポジトリ） | 実 GitHub API 必要 | ステージング環境で確認 |
