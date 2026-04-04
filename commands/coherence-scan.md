---
description: 全成果物の coherence frontmatter を収集して graph/coherence.json を再構築します。循環依存・dangling reference・Gray ノードを検出して可視化します。
allowed-tools: Read, Glob, Grep, Write, Bash, TodoWrite
argument-hint: "[--fix] [--verbose]"
---

# tsumigi coherence-scan

全成果物ファイルの `coherence:` frontmatter を収集し、
`graph/coherence.json` を再構築します。
循環依存・dangling reference・Gray ノードを検出して警告を出力します。

# context

fix_mode={{fix_mode}}
verbose={{verbose}}
coherence_json=graph/coherence.json

# step

- $ARGUMENTS を解析する：
  - `--fix` フラグを確認し fix_mode に設定（デフォルト: false）
  - `--verbose` フラグを確認し verbose に設定（デフォルト: false）
- `graph/coherence.json` が存在するか確認する（存在しない場合は `graph/` を `mkdir -p` で作成）
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: 対象ファイルの収集

以下のパターンで成果物ファイルを収集する（Glob を使用）：
- `specs/**/*.md`
- `.kiro/specs/**/*.md`

収集したファイル一覧を内部変数に保持する。

## step3: frontmatter の抽出とノード構築

収集したファイルごとに以下を実行する：

1. ファイルの先頭 50 行を Read する
2. `---` で囲まれた YAML frontmatter を検出する
3. `coherence:` セクションが存在する場合：
   - `coherence.id` をノードキーとして抽出する
   - `tsumigi.artifact_type`, `tsumigi.phase`, `tsumigi.issue_id` を抽出する
   - `coherence.depends_on` の各エントリを抽出する
   - `coherence.band` を抽出する（存在しない場合は `"Green"` をデフォルト）
4. frontmatter が壊れている（YAML パースエラー）場合：
   - ファイルパスと行番号を警告として出力する
   - そのファイルはスキップして続行する

**ノードオブジェクトの構造**:
```json
{
  "node-id": {
    "id": "node-id",
    "artifact_type": "imp",
    "phase": "IMP",
    "issue_id": "001-feature",
    "band": "Green",
    "file": "specs/001-feature/IMP.md",
    "last_scanned": "<ISO8601>"
  }
}
```

## step4: エッジ構築

各ノードの `coherence.depends_on` から edges 配列を構築する：

```json
{
  "from": "impl:001:T01",
  "to": "imp:001",
  "relation": "implements",
  "confidence": 0.95,
  "required": true
}
```

## step5: バリデーション

**循環依存チェック（DFS）**:
- nodes と edges から有向グラフを構築する
- DFS で循環依存を検出する
- 検出された場合: 循環しているノード ID のチェーンを警告として出力する
- スキャン自体は完了させる（エラーで停止しない）

**Dangling Reference チェック**:
- 各エッジの `to` ノードが nodes に存在するか確認する
- 存在しない場合: 警告を出力し、そのエッジの `from` ノードの `band` を `"Amber"` に強制設定する

## step6: サマリー計算と書き込み

- Green/Amber/Gray の件数を集計する
- `graph/coherence.json` を以下の構造で Write する（アトミック）：

```json
{
  "version": "1.0.0",
  "nodes": { ... },
  "edges": [ ... ],
  "summary": {
    "total": N,
    "green": N,
    "amber": N,
    "gray": N,
    "last_scanned": "<ISO8601>",
    "warnings": [
      { "type": "circular_dep", "nodes": ["id1", "id2"] },
      { "type": "dangling_ref", "from": "id1", "to": "id2" },
      { "type": "parse_error", "file": "specs/..." }
    ]
  }
}
```

## step7: 結果の表示

以下のレポートを表示する：

```
## coherence-scan 結果

スキャン対象: N ファイル
有効ノード: N 件

### バンド別サマリー
  🟢 Green: N 件（整合性良好）
  🟡 Amber: N 件（要確認）
  ⚫ Gray: N 件（未検証 / 要調査）

### 警告
  ⚠️ 循環依存: N 件
    [node-id1] → [node-id2] → [node-id1]
  ⚠️ Dangling Reference: N 件
    [from-id] → [存在しない: to-id]
  ⚠️ YAML パースエラー: N 件
    specs/xxx/yyy.md（先頭部分の YAML が不正）
```

`--verbose` フラグがある場合は全ノードの詳細も表示する。

Gray ノードが存在する場合は追加警告を表示する：
```
🚨 Gray ノードが N 件あります。Phase Gate は通過できません。
   OPS フェーズで coherence-scan を実行して解消してください。
```

## step8: 完了通知

- 以下を表示する：
  ```
  ✅ coherence-scan 完了

  graph/coherence.json を更新しました。
  （N ノード, Green: N / Amber: N / Gray: N）

  バトン状態の確認: /tsumigi:baton-status
  ```

- TodoWrite ツールでタスクを完了にマークする
