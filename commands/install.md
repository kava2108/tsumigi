---
description: tsumigi プロジェクトの初期セットアップを行います。ディレクトリ構造・設定ファイル・IMP テンプレートを生成し、Skills の有効化手順を案内します。
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion, TodoWrite
argument-hint: "[project-name] [--lang ja|en] [--speckit]"
---

# tsumigi install

tsumigi エンジンをプロジェクトに導入するための初期セットアップを行います。
冪等設計のため、既存ファイルを上書きせずに差分のみを追加します。

# context

プロジェクト名={{project_name}}
言語={{lang}}
SpecKit連携={{speckit_enabled}}
作業ディレクトリ={{working_dir}}

# step

- $ARGUMENTS の内容を解析する：
  - `--lang en` が含まれる場合、lang を `en` に設定（デフォルト: `ja`）
  - `--speckit` が含まれる場合、speckit_enabled を `true` に設定
  - 残りの文字列をプロジェクト名として設定
- context の内容をユーザーに宣言する
- step2 を実行する

## step2: プロジェクト名の確認

- プロジェクト名が未指定の場合、AskUserQuestion ツールを使って質問する：
  - question: "プロジェクト名を教えてください"
  - header: "プロジェクト名"
  - multiSelect: false
- 取得したプロジェクト名を context の {{project_name}} に保存する
- step3 を実行する

## step3: 既存セットアップの確認（idempotent チェック）

- `.tsumigi/config.json` が存在するか確認する
  - 存在する場合：「既存の tsumigi 設定が見つかりました。差分のみを追加します」と表示する
  - 存在しない場合：「新規セットアップを開始します」と表示する
- step4 を実行する

## step4: ディレクトリ構造の生成

以下のディレクトリを作成する（既存ディレクトリは変更しない）：

```
specs/
.tsumigi/templates/
```

各ディレクトリに `.gitkeep` ファイルを作成する（既存ファイルはスキップ）。

## step5: 設定ファイルの生成

`.tsumigi/config.json` が存在しない場合のみ、以下の内容で作成する：

```json
{
  "tsumigi_version": "1.0.0",
  "project": {
    "name": "{{project_name}}",
    "language": "{{lang}}",
    "created_at": "<現在の ISO8601 日時>"
  },
  "integrations": {
    "speckit": {{speckit_enabled}},
    "github": {
      "enabled": true,
      "issue_prefix": "GH"
    }
  },
  "drift_check": {
    "threshold": 20,
    "auto_run_after_implement": true
  },
  "review": {
    "default_personas": ["arch", "security", "qa"],
    "require_checklist_before_merge": true
  },
  "imp": {
    "require_executive_summary": true,
    "require_rollback_plan": true,
    "version_scheme": "semver"
  },
  "docs": {
    "base_path": "specs"
  }
}
```

## step6: IMP テンプレートの生成

`.tsumigi/templates/IMP-template.md` を作成する（既存の場合はスキップ）。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/IMP-template.md`
  - `.claude/commands/tsumigi/templates/IMP-template.md`
- 読み込んだテンプレートをそのまま `.tsumigi/templates/IMP-template.md` として Write する

## step7: TSUMIGI.md の生成

プロジェクトルートに `TSUMIGI.md` を作成する（既存の場合はスキップ）。

- テンプレートを Read する（以下の順で探索し、最初に見つかったものを使用する）：
  - `~/.claude/commands/tsumigi/templates/TSUMIGI-md-template.md`
  - `.claude/commands/tsumigi/templates/TSUMIGI-md-template.md`
- テンプレートの `{{project_name}}` を context の {{project_name}} に置換して `TSUMIGI.md` を Write する

## step8: 完了通知

以下を表示する：

```
✅ tsumigi セットアップ完了

生成されたファイル:
  .tsumigi/config.json
  .tsumigi/templates/IMP-template.md
  TSUMIGI.md
  specs/{{issue_id}}/.gitkeep

次のステップ:
  1. 最初の Issue から作業を開始:
     /tsumigi:issue_init <issue-id>

  2. ヘルプを確認:
     /tsumigi:help
```

- TodoWrite ツールでセットアップ完了をマークする
