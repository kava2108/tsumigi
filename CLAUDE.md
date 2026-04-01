# CLAUDE.md — tsumigi

このファイルは、Claude Code が tsumigi リポジトリで作業するときのガイダンスを提供します。

## 概要

tsumigi は AI-TDD エンジンです。Claude Code Plugin 経由でインストールされ、
Issue → IMP → 実装 → テスト → 逆仕様 → 同期 の全フェーズを一貫して実行します。

このリポジトリには以下が含まれています：
- **`commands/`**: Claude Code スラッシュコマンド用テンプレート（`.md` ファイル）
- **`.claude-plugin/`**: Claude Code Plugin 設定ファイル

## インストール方法

```bash
/plugin marketplace add https://github.com/kava2108/tsumigi.git
/plugin install tsumigi@tsumigi
```

インストール後、コマンドは `/tsumigi:` プレフィックスで実行します。

## コマンド一覧

| コマンド | 説明 |
|---------|------|
| `tsumigi:install` | プロジェクト初期セットアップ |
| `tsumigi:issue_init` | Issue → タスク構造起こし |
| `tsumigi:imp_generate` | IMP（実装管理計画書）生成・更新 |
| `tsumigi:implement` | IMP ベースで実装案・パッチ案を生成 |
| `tsumigi:test` | テストケース・検証方針を生成 |
| `tsumigi:rev` | 実装から逆仕様・ドキュメントを生成 |
| `tsumigi:sync` | 全成果物の整合性確認・修正 |
| `tsumigi:review` | reviewer-oriented な差分・リスク整理 |
| `tsumigi:drift_check` | 仕様と実装の乖離を検出・可視化 |
| `tsumigi:help` | ヘルプ・コマンド一覧 |
| `tsumigi:cli` | 自然言語からのコマンドルーティング |

## 設計原則

- **Idempotent**: 全 Skill は再実行安全。既存ファイルに差分マージする。
- **Reviewer-oriented**: 全出力は監査可能・再現可能な形式で生成する。
- **IMP 中心設計**: IMP.md が Issue〜実装〜ドキュメントの単一の真実の源となる。
- **Drift Correction**: 仕様と実装の乖離を定量化し、可視化する。

## プロジェクト構造

```
tsumigi/
├── .claude-plugin/
│   ├── plugin.json       # Claude Code Plugin 設定
│   └── marketplace.json  # マーケットプレイスメタデータ
├── commands/             # スラッシュコマンド定義（.md）
├── CLAUDE.md             # このファイル
├── README.md             # ユーザー向けドキュメント
└── package.json
```

## コマンドファイルの書き方

コマンドファイル（`commands/*.md`）は tsumiki と同じ形式に従います：

```markdown
---
description: コマンドの説明
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, TodoWrite, AskUserQuestion
argument-hint: "<必須引数> [任意引数]"
---

# コマンド名

## 目的
...

# context
変数名={{変数}}

# step
...

## step2
...
```

## 注意事項

- コマンドファイル（`.md`）を修正する際は、シークレット情報が含まれていないことを確認してから commit してください。
- `$ARGUMENTS` はユーザーがコマンドに渡した引数文字列全体を参照します。
- `{{variable}}` は context セクションで定義されたテンプレート変数です。
