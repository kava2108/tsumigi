---
issue_id: tsumigi-v3-harness
task_id: T03
created_at: 2026-04-05T00:00:00Z
updated_at: 2026-04-05T00:00:00Z
---

# 実装判断メモ: tsumigi-v3-harness / T03

## v1.1.1 アップデート（Adversary D1 / D4 修正）

### D1: `_check_ceg()` — DFS サイクル検出

#### 採用したアプローチ

**jq 内再帰 DFS**（`def dfs(node; stack; adj)` パターン）

```jq
def dfs(node; stack; adj):
  if (stack | index(node)) != null then "cycle"
  else
    reduce (adj[node] // [])[] as $n (
      "ok";
      if . == "cycle" then "cycle"
      else dfs($n; stack + [node]; adj)
      end
    )
  end;
```

**Fast path を先行**: coherence-scan が `summary.warnings` に `circular_dep` を記録済みなら、フル DFS をスキップして即時検出。

#### 検討した代替案

| 代替案 | 不採用の理由 |
|---|---|
| Bash 再帰 DFS | 再帰深度制限 (`ulimit -s`) リスク、associative array の関数スコープ問題あり |
| Python スクリプト | `python3` の存在を前提にするためポータビリティが低下する |
| Kahn's algorithm（位相ソート） | jq ではキューベース処理が複雑になる。DFS の方が jq パターンとして自然 |
| coherence-scan 任せ（fast path のみ） | coherence-scan が実行されていない場合に未検出となる。Phase Gate は自律的に検出すべき |

#### トレードオフ

- **計算量**: 全ノードから DFS を起動するため O(V*(V+E))。  
  coherence グラフはフェーズ数 × タスク数程度（通常 10〜50 ノード）なので実用上問題なし。
- **visited 最適化の省略**: jq の不変データ構造では visited セット（全体）を持ち回すと
  reduce の state 管理が複雑になる。小グラフでは省略が合理的。
- **coherence.json の更新タイミング**: Phase Gate 実行時点で coherence.json が存在しない場合は `return 0`。
  これは「CEG が未構築 = 依存関係が未定義」と解釈し、ゲートを通過させる設計とした。

---

### D4: `on_label_added()` — SRP リファクタリング

#### 採用したアプローチ

4 つのヘルパー関数 + オーケストレーターパターン：

| 関数 | 責務 | 行数 |
|------|------|------|
| `_validate_approve_request` | バリデーション + next_candidate 解決 | ~20 行 |
| `_update_github_labels_for_approval` | ラベル操作（3 件） | ~15 行 |
| `_finalize_baton_for_approval` | baton-log 更新 | ~10 行 |
| `_notify_approval` | コメント投稿 | ~12 行 |
| `on_label_added`（オーケストレーター） | フロー制御のみ | ~15 行 |

#### 設計決定: `_validate_approve_request` の戻り値

`next_candidate` を stdout で返却し、呼び出し元は `result=$(func)` で取得する。

```bash
# 呼び出し例
next_candidate=$(_validate_approve_request "$issue_number" "$pending_label") || return 1
```

**理由**: Bash 関数は整数 exit code のみ返せるため、文字列値を返すには stdout を使うのが慣用パターン。
`local -n` (nameref) や global 変数による副作用は呼び出し元への結合が強くなるため不採用。

#### 既存コードへの影響

- `on_label_added()` の外部 API（引数シグネチャ: `issue_number label_name`）は変更なし。
- ヘルパー関数は `_` プレフィックス付きでプライベート扱い。他ファイルへの影響なし。
- `phase-gate.sh` の `_gh_with_retry` を各ヘルパーから引き続き利用。

---

## v1.1.0 初期実装メモ

### 主要設計判断

- **Harness チェック先立て**: 全公開関数の冒頭で `_check_harness_enabled || return 0`。
  これにより harness 無効プロジェクトではノーオプとなり後方互換を保つ。
- **baton-log.json の二重書き**: `jq` による原子的更新（tmp ファイル → mv）を採用。
  直接リダイレクト書き込みは読み書き競合のリスクがあるため不採用。
- **exponential backoff**: `_gh_with_retry` の遅延を `2s / 4s / 8s` に設定。
  GitHub API の rate limit 回避として標準的な値。

## TODO・未解決事項

- [ ] D2 (T04〜T07): セキュリティ TC（prompt injection, label injection, YAML injection）追加
- [ ] D5: Bash 実行可能なテストスクリプト（bats or plain sh）の実装
- [ ] TC-T03-13: `_check_ceg()` DFS 修正後の AC 検証ステータス更新
- [ ] `gh issue view` のリトライ未対応（`_validate_approve_request` 内）— minor
