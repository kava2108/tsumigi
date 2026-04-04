---
description: VCKD バトン状態を表示します。アクティブな Issue のフェーズ・承認待ち・ブロック状態・直近の遷移履歴を一覧表示します。
allowed-tools: Read, Bash, Glob
argument-hint: "[issue-id]"
---

# tsumigi baton-status

VCKD Harness のバトン遷移状態を表示します。
`graph/baton-log.json` と GitHub Issue ラベルを組み合わせて、
全 Issue の現在フェーズを可視化します。

# context

issue_id={{issue_id}}
baton_log=graph/baton-log.json
config_file=.vckd/config.yaml

# step

- $ARGUMENTS を解析する：
  - 最初のトークンが指定された場合は issue_id に設定する（特定 Issue の詳細表示モード）
- `graph/baton-log.json` が存在するか確認する
  - 存在しない場合は「VCKD Harness がセットアップされていません。`/tsumigi:install --harness` を実行してください」と表示して終了する
- `graph/baton-log.json` を Read する
- step2 を実行する

## step2: GitHub ラベルの取得

- Bash で以下を実行してアクティブな Issue を取得する：
  ```bash
  gh issue list --label "phase:req,phase:tds,phase:imp,phase:test,phase:ops,phase:change" \
    --state open --json number,title,labels 2>/dev/null || echo "[]"
  ```
- Bash で以下を実行して pending Issue を取得する：
  ```bash
  gh issue list --label "pending:next-phase" \
    --state open --json number,title,labels 2>/dev/null || echo "[]"
  ```
- Bash で以下を実行してブロック中の Issue を取得する：
  ```bash
  gh issue list --label "blocked:req,blocked:tds,blocked:imp,blocked:ops,blocked:escalate" \
    --state open --json number,title,labels 2>/dev/null || echo "[]"
  ```
- step3 を実行する

## step3: 状態レポートの表示

取得した情報を以下の形式でレポートとして表示する：

```
## VCKD バトン状態レポート

### アクティブな Issue（phase:* ラベル付き）
| Issue | タイトル | ラベル | 直近バトン遷移 | 記録日時 |
|-------|---------|--------|--------------|---------|
| #N    | ...     | phase:imp | phase:tds → phase:imp | 2026-04-04T10:00:00Z |

### 承認待ち（pending:next-phase）
| Issue | タイトル | 次フェーズ候補 | 記録日時 |
|-------|---------|-------------|---------|
| #N    | ...     | phase:test  | ... |

### ブロック中（blocked:*）
| Issue | タイトル | ラベル | 推奨コマンド |
|-------|---------|--------|-----------|
| #N    | ...     | blocked:escalate | /tsumigi:rescue N |

### 直近 10 件のバトン遷移
| 日時 | Issue | from → to | mode |
|------|-------|----------|------|
| ... | ... | ... | manual/auto |
```

- `baton-log.json` の `transitions` 配列から直近 10 件を逆順（新しい順）で表示する
- `pending` オブジェクトの各エントリも表示する

## step4: 特定 Issue の詳細表示（issue_id 指定時のみ）

issue_id が指定されている場合は、その Issue に絞った詳細を追加表示する：

```
## バトン状態: #{{issue_id}}

### 現在のラベル
  （GitHub から取得したラベル一覧）

### pending 状態
  次フェーズ候補: phase:xxx（baton-log.json より）
  記録日時: ...

### 遷移履歴（全件）
  | 日時 | from → to | mode | triggered_by |
```

- Bash で `gh issue view {{issue_id}} --json labels,title,state 2>/dev/null` を実行してラベルを取得する
- `baton-log.json` の `transitions` から当該 Issue のエントリを抽出して表示する
