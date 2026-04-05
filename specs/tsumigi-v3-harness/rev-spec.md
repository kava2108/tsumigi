---
tsumigi:
  node_id: "rev-spec:tsumigi-v3-harness"
  artifact_type: "rev_spec"
  phase: "OPS"
  issue_id: "tsumigi-v3-harness"
  created_at: "2026-04-05T00:00:00Z"
coherence:
  id: "rev-spec:tsumigi-v3-harness"
  depends_on:
    - id: "imp:tsumigi-v3-harness"
      relation: "reverse_of"
      confidence: 0.90
      required: false
    - id: "test-plan:tsumigi-v3-harness"
      relation: "informed_by"
      confidence: 0.85
      required: false
  band: "Green"
---

# 逆生成仕様書: tsumigi-v3-harness

> この仕様書は実装コードから自動生成されました。  
> ⚠️ マークは IMP との差分がある箇所を示します。

**解析対象ファイル**:
- `.tsumigi/lib/phase-gate.sh`
- `.tsumigi/hooks/post-tool-use.sh`
- `.tsumigi/lib/on-label-added.sh`
- `.github/workflows/vckd-pipeline.yml`
- `.vckd/config.yaml`
- `commands/install.md`, `commands/baton-status.md`, `commands/coherence-scan.md`, `commands/rescue.md`
- `.tsumigi/agents/*.md`（7 ファイル）

---

## 機能仕様

---

### F-01: Baton Infrastructure セットアップ（`/tsumigi:install --harness`）

**実際の振る舞い**:  
`install.md` の `--harness` フラグが指定された場合、以下を順番に実行する：
1. `gh` CLI の存在確認（未インストール時は警告して終了）
2. GitHub Labels を `gh label create --force-create` で一括作成（存在時はスキップ）
3. `.vckd/config.yaml` を生成（既存の場合は差分確認を促す）
4. `graph/baton-log.json` / `graph/coherence.json` を初期化
5. `.claude/settings.json` に `PostToolUse` フックを `jq` でマージ追記
6. `.tsumigi/hooks/post-tool-use.sh` を生成

**IMP との差分**: ✅ 一致  
**実装根拠**: `commands/install.md` Step5, Step8

---

### F-02: PostToolUse Hook（`.tsumigi/hooks/post-tool-use.sh`）

**実際の振る舞い**:

```
起動条件:
  VCKD_GATE_RESULT が空 → exit 0（早期離脱）
  VCKD_FROM_PHASE が空 → exit 0
  VCKD_ISSUE_NUMBER が空 → exit 0
  VCKD_ISSUE_NUMBER が整数でない → exit 2（設定エラー）
  harness.enabled != "true" → exit 0（後方互換）

PASS ルート:
  dispatch_baton $ISSUE_NUMBER $CURRENT_LABEL $NEXT_LABEL を呼ぶ
  フェーズマッピング: REQ→tds, TDS→imp, IMP→test, TEST→ops, OPS→change, CHANGE→done

FAIL ルート:
  emit_blocked $ISSUE_NUMBER $CURRENT_LABEL "blocked:$phase" $FAIL_REASON を呼ぶ
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/hooks/post-tool-use.sh` L1-60

---

### F-03: dispatch_baton()

**実際の振る舞い**:

```
引数: issue_number, current_label, next_label

1. _check_harness_enabled() → false なら return 0
2. AUTO_STEP を config.yaml から取得（true/false, デフォルト false）
3. AUTO_STEP=true → emit_baton を呼ぶ
   AUTO_STEP=false → emit_pending を呼ぶ
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L333-356

---

### F-04: emit_pending()

**実際の振る舞い**:

```
引数: issue_number, current_label, pending_label, next_label

1. _check_harness_enabled チェック
2. gh issue edit: current_label を削除、pending_label を追加
  （_gh_with_retry で最大 3 回リトライ: exponential backoff 2s→4s→8s）
3. baton-log.json の pending[$issue] に {next, recorded_at} を記録
  （jq でアトミック更新）
4. post_comment=true なら gh issue comment で承認待ち旨のコメントを投稿
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L357-409

---

### F-05: emit_baton()

**実際の振る舞い**:

```
引数: issue_number, current_label, next_label

1. _check_harness_enabled チェック
2. gh issue edit: current_label を削除、next_label を追加（リトライあり）
3. baton-log.json の transitions に {issue_number, from, to, ts, mode:"auto"} を追記
4. post_comment=true なら gh issue comment でバトン移行コメントを投稿
5. 全 gh 呼び出し失敗時は emit_escalate を呼ぶ
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L410-449

---

### F-06: emit_blocked()

**実際の振る舞い**:

```
引数: issue_number, current_label, blocked_label, reason

1. _check_harness_enabled チェック
2. gh issue edit: blocked_label を追加（current_label は残す）
3. gh issue comment: FAIL 理由と修正コマンドを投稿
4. baton-log.json の transitions に {mode:"blocked"} として追記
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L450-

---

### F-07: on_label_added（承認フロー）

**実際の振る舞い**:

```
引数: issue_number, label_name

early-return 条件:
  label_name != approve_label → return 0
  Issue に pending:next-phase がない → エラーコメント投稿して return
  baton-log.json の pending[$issue] が存在しない → エラーコメント投稿して return

メインフロー:
  1. baton-log.json から next_candidate を取得
  2. gh issue edit: approve + pending:next-phase を削除
  3. gh issue edit: next_candidate を追加
  4. baton-log.json の pending エントリを削除
  5. baton-log.json の transitions に {mode:"manual"} を追記
  6. gh issue comment: 承認完了コメントを投稿
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/on-label-added.sh`

---

### F-08: check_phase_gate()

**実際の振る舞い**:

```
引数: from_phase, to_phase, feature_name

4ステップ処理:
  Step 1 _check_artifacts: 必須ファイルの存在確認
  Step 2 _check_ceg: CEG 整合性（循環依存・ダングリング参照）チェック
    → coherence.json を読み、DFS でサイクルを検出
  Step 3 _check_phase_specific: フェーズ遷移固有チェック
    → "IMP->TEST" では all_tasks_have_patch_plan を確認
  Step 4 _check_gray: Gray ノードの存在確認

全てのステップが PASS → VCKD_GATE_RESULT=PASS、exit 0
いずれかが FAIL → VCKD_GATE_RESULT=FAIL、exit 1
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L201-332

---

### F-09: escalate / retry（T09）

**実際の振る舞い**:

```
get_retry_count($issue):
  baton-log.json の pending[$issue].retries を返す（未設定時は 0）

increment_retry_count($issue, $error, $agent):
  pending[$issue].retries をインクリメント
  last_error と agent を記録

reset_retry_count($issue):
  retries=0, last_error=null, agent=null にリセット

emit_escalate($issue, $agent, $last_error):
  harness.enabled チェック後
  gh issue edit: blocked:escalate ラベルを追加
  gh issue comment: エスカレーション理由・エージェント名・エラー詳細を投稿
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L113-200

---

### F-10: coherence-scan コマンド

**実際の振る舞い**:

```
Step 1: Glob で specs/**/*.md, .kiro/specs/**/*.md を収集
Step 2: 各ファイルの frontmatter から coherence.id をキーにノードを構築
Step 3: depends_on からエッジを構築
Step 4: バリデーション（DFS 循環 → Red、dangling → Amber）
  YAML パースエラー → 警告+スキップで継続
Step 5: graph/coherence.json をアトミックに書き込み（差分マージ）
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `commands/coherence-scan.md`

---

### F-11: baton-status コマンド

**実際の振る舞い**:

```
表示カテゴリ:
  1. アクティブな Issue（phase:* ラベル保持）
  2. 承認待ち（pending:next-phase ラベル保持）
  3. ブロック中（blocked:* ラベル保持）
  4. 直近 10 件のバトン遷移（baton-log.json から読み込み）
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `commands/baton-status.md`

---

### F-12: rescue コマンド（T09）

**実際の振る舞い**:

```
1. blocked:* / blocked:escalate ラベルを削除
2. baton-log.json のリトライカウントをリセット
3. 前フェーズラベル（phase:xxx）を再付与
4. Issue コメントでレスキュー理由を記録
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `commands/rescue.md`

---

### F-13: backward compat（harness.enabled=false）

**実際の振る舞い**:

```
全ての public 関数（dispatch_baton, emit_*, check_phase_gate 等）の先頭で
_check_harness_enabled() を呼び、false なら return 0（early-return）
→ tsumigi v2.x 以前の環境では一切のバトン操作を行わない
```

**IMP との差分**: ✅ 一致  
**実装根拠**: `.tsumigi/lib/phase-gate.sh` L32-37（`_check_harness_enabled`）

---

## 信頼性サマリー

- 🔵 実装に根拠あり（直接コード確認）: 13 件
- 🟡 テストのみで確認（testcases.md から推定）: 0 件
- 🔴 不明（推定）: 0 件

## IMP との乖離サマリー

⚠️ 差分が検出された箇所: **0 件**

全仕様が実装と一致しています。
→ 詳細確認: `/tsumigi:drift_check tsumigi-v3-harness`
