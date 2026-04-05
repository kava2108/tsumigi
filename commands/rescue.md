---
description: blocked:escalate または blocked:* 状態の Issue を救出します。ブロックラベルを解除し、リトライカウントをリセットして Phase Agent を再起動します。
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion, TodoWrite
argument-hint: "<issue-number>"
---

# tsumigi rescue

`blocked:escalate` または `blocked:*` 状態の Issue を人間が救出するコマンドです。
ブロックラベルを解除し、リトライカウントをリセットして Phase Agent を再起動します。

# context

issue_number={{issue_number}}
baton_log=graph/baton-log.json
config_file=.vckd/config.yaml

# step

- $ARGUMENTS を解析する：
  - 最初のトークンを issue_number に設定する
  - issue_number が未指定または整数でない場合は「Issue 番号を指定してください（例: /tsumigi:rescue 42）」と言って終了する
- `graph/baton-log.json` が存在するか確認する
  - 存在しない場合は「VCKD Harness がセットアップされていません。`/tsumigi:install --harness` を実行してください」と表示して終了する
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: Issue の状態確認

- Bash で Issue の現在のラベルを取得する：
  ```bash
  gh issue view {{issue_number}} --json labels,title,state 2>/dev/null
  ```
- ブロック系ラベルを検出する（`blocked:escalate`, `blocked:req`, `blocked:tds`, `blocked:imp`, `blocked:ops`）
- **ブロックラベルが存在しない場合**:
  「Issue #{{issue_number}} はブロックされていません。rescue は不要です。」と表示して終了する
- ブロックラベルが存在する場合: step3 を実行する

## step3: ブロック状態の詳細表示

`graph/baton-log.json` を Read して、Issue #{{issue_number}} のエントリを確認する。

以下の情報を表示する：
```
## 🚨 ブロック状態: Issue #{{issue_number}}

### 現在のラベル
  （検出されたブロックラベル一覧）

### baton-log 情報
  リトライ回数: N/3
  最後のエラー: <エラー内容>
  担当エージェント: <AgentName>

### 最後のバトン遷移
  <日時> | <from> → <to> | blocked
```

step4 を実行する

## step4: 救出確認

AskUserQuestion ツールを使ってユーザーに確認する：
- question: "以下のブロックラベルを解除して Phase Agent を再起動しますか？\n\nラベル: （ブロックラベル一覧）\n再起動するフェーズ: （推奨フェーズ）"
- header: "rescue 確認"
- multiSelect: false
- options:
  - label: "続行する（ブロックを解除して再起動）"
  - label: "ラベルのみ解除（再起動しない）"
  - label: "中断する"

「中断する」を選択した場合はメッセージを表示して終了する。

step5 を実行する

## step5: ブロックラベルの解除と retries リセット

**ブロックラベルの削除**:
- Bash で以下のラベルを削除する（存在する場合のみ）：
  ```bash
  gh issue edit {{issue_number}} \
    --remove-label "blocked:escalate" \
    --remove-label "blocked:req" \
    --remove-label "blocked:tds" \
    --remove-label "blocked:imp" \
    --remove-label "blocked:ops" \
    2>/dev/null || true
  ```
- `pending:next-phase` ラベルも存在する場合は削除する：
  ```bash
  gh issue edit {{issue_number}} --remove-label "pending:next-phase" 2>/dev/null || true
  ```

**baton-log.json の retries リセット**:
- `graph/baton-log.json` を Read する
- Issue #{{issue_number}} の `pending.retries` を 0 にリセットする：

```json
// baton-log.json の pending エントリのリセット
{
  "pending": {
    "{{issue_number}}": {
      "next": "<次フェーズ>",
      "recorded_at": "<ISO8601>",
      "retries": 0,
      "last_error": null,
      "agent": null
    }
  }
}
```

step6 を実行する

## step6: Phase Agent の再起動（ユーザーが「続行する」を選択した場合）

- 推奨フェーズのラベルを確認する：
  - baton-log.json の `pending.next` から推奨フェーズを取得する
  - 取得できない場合は AskUserQuestion で確認する

- AskUserQuestion ツールで再起動するフェーズを確認する：
  - question: "再起動するフェーズのラベルを確認してください"
  - options: （現在 Issue に付いているフェーズラベルを選択肢に表示）

- Bash で推奨フェーズラベルを付与する（GitHub Actions が起動する）：
  ```bash
  gh issue edit {{issue_number}} --add-label "<phase-label>" 2>/dev/null
  ```

## step7: 完了通知

- 以下を表示する：
  ```
  ✅ rescue 完了: Issue #{{issue_number}}

  実行した操作:
    ✅ ブロックラベルを解除しました
    ✅ リトライカウントをリセットしました（0/3）
    （✅ Phase Agent を再起動しました: <フェーズ>）

  Phase Agent の出力を確認:
    /tsumigi:baton-status {{issue_number}}

  ⚠️ 同じ箇所で再度 escalate になる場合は、
     システムプロンプト（.tsumigi/agents/*.md）の修正が必要です。
  ```

- Bash でコメントを投稿する：
  ```bash
  gh issue comment {{issue_number}} --body "$(cat <<'EOF'
  ## 🔧 tsumigi rescue: 実行

  人間オペレーターによる救出処理が実行されました。

  | 操作 | 状態 |
  |------|------|
  | ブロックラベル解除 | ✅ |
  | リトライカウントリセット | ✅ 0/3 |
  | Phase Agent 再起動 | ✅/⏭️ |

  `/tsumigi:rescue` コマンドによる手動復旧。
  EOF
  )" 2>/dev/null || true
  ```

- TodoWrite ツールでタスクを完了にマークする

---

## 中間状態のリカバリー手順

harness が有効な状態でフェーズラベルを変更した後、harness を無効化（`harness.enabled: false`）した場合、
Issue のラベル状態と `baton-log.json` の内容が不整合になることがあります。
以下の手順で手動リカバリーを行ってください。

### ケース: harness 無効化後に Issue のラベルが不正な状態で残っている

**症状**:
- `phase:xxx` ラベルが付いたまま Phase Agent が動作しない
- `pending:next-phase` ラベルが残ったまま `approve` を待っている
- `baton-log.json` の `pending` エントリが古い情報を持っている

**手順**:

#### 1. 現在のラベルを確認する

```bash
gh issue view <N> --json labels,title,state
```

#### 2. 不正ラベルを削除する

```bash
# 不要なフェーズラベルを削除
gh issue edit <N> --remove-label "phase:xxx"

# pending:next-phase が残っている場合も削除
gh issue edit <N> --remove-label "pending:next-phase"

# approve ラベルが残っている場合も削除
gh issue edit <N> --remove-label "approve"
```

#### 3. 正しいラベルを再付与する

再開したいフェーズのラベルを付与します（GitHub Actions は harness が無効なため起動しません）:

```bash
gh issue edit <N> --add-label "phase:yyy"
```

harness を再有効化して Phase Agent を再起動する場合は `.vckd/config.yaml` を編集してから付与してください。

#### 4. baton-log.json の pending エントリを手動修正する（必要に応じて）

`graph/baton-log.json` を開き、対象 Issue の `pending` エントリを修正または削除します:

```json
{
  "pending": {
    "<N>": {
      "next": "phase:yyy",
      "recorded_at": "<ISO8601>",
      "retries": 0,
      "last_error": null,
      "agent": null
    }
  }
}
```

エントリごと削除する場合:

```bash
tmp=$(mktemp)
jq --arg n "<N>" 'del(.pending[$n])' graph/baton-log.json > "$tmp" && mv "$tmp" graph/baton-log.json
```

#### 5. 整合性を確認する

```bash
/tsumigi:coherence-scan
```

coherence.json の `amber` / `gray` ノード数が増加していないことを確認してください。
増加している場合は `/tsumigi:drift_check` で乖離の原因を特定してください。

### harness を再有効化せずに Issue を完結させる場合

1. `gh issue edit <N> --remove-label "phase:xxx"` で全フェーズラベルを削除
2. `gh issue edit <N> --add-label "phase:done"` で完了ラベルを付与
3. `gh issue close <N>` で Issue をクローズ
