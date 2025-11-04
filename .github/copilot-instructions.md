# Copilot Instructions - Docker Helix Core

このプロジェクトは、Perforce Helix Core (P4D) サーバーを Docker コンテナで実行するためのセットアップです。

## 重要な指示

**必須要件: GitHub Copilot は、このプロジェクトでのすべての回答・提案・コメントを日本語で行ってください**

- コード提案時のコメント
- エラーメッセージの説明
- 実装方針の提案
- ドキュメント生成
- 問題解決の提案

すべて日本語で回答し、日本の開発者にとって理解しやすい形で情報を提供してください。

**絵文字使用禁止: GitHub Copilot は、このプロジェクトでの修正内容・コード・コメント・ドキュメントに絵文字を使用してはいけません**

- コード内のコメント
- ログメッセージ
- エラーメッセージ
- YAML・設定ファイル
- Shell Script・Python コード
- ドキュメント・README

すべてのプログラムコードとそのコメントは絵文字を含まず、テキストのみで記載してください。

## プロジェクト概要

- **目的**: Perforce Helix Core サーバーの Docker 化
- **対象環境**: 開発・テスト環境（本番環境向けには追加のセキュリティ設定が必要）
- **言語・技術スタック**: Docker, Docker Compose, Python, Shell Script, Makefile
- **メンテナー**: radicalgrimoire (六魔辞典)

## アーキテクチャ・構成

### ディレクトリ構造
```
docker-helixcore/
├── .github/                    # GitHub設定・ドキュメント
├── build/                      # イメージビルド用ファイル
│   ├── Dockerfile              # メインDockerfile
│   ├── Dockerfile.v2           # Swarmトリガー付きDockerfile
│   └── files/                  # 設定・スクリプトファイル
├── p4d/                        # シンプルなDockerfile（プリビルドイメージ使用）
├── docker-compose.yml          # Docker Compose設定
├── Makefile                    # 便利コマンド集
└── README.md                   # プロジェクトドキュメント
```

### ネットワーク設定
- **カスタムネットワーク**: `app_net` (172.16.238.0/24)
- **コンテナIP**: 172.16.238.10
- **公開ポート**: 1666 (SSL接続)

## コーディング規約・ベストプラクティス

### Docker関連
- **Dockerfile**: マルチステージビルドを使用し、セキュリティを重視
- **docker-compose.yml**: YAML形式、2スペースインデント
- **ボリューム**: データ永続化のため適切にボリュームマウント
- **ネットワーク**: セキュリティを考慮したカスタムネットワーク使用

### Python (トリガースクリプト)
- **Python バージョン**: 3.4以上
- **インデント**: 4スペース
- **文字エンコーディング**: UTF-8サポート
- **エラーハンドリング**: 適切な例外処理を実装
- **ログ出力**: トリガーの動作状況を適切にログ出力

### Shell Script
- **シェバン**: `#!/bin/bash` を使用
- **エラーハンドリング**: `set -e` でエラー時終了
- **変数**: 大文字で環境変数、小文字でローカル変数
- **クォート**: 変数は適切にクォートで囲む

### Makefile
- **タブ文字**: コマンド行はタブでインデント
- **変数**: 大文字で定義
- **Windows互換性**: `winpty` を使用してWindows環境に対応

## 重要な機能・コンポーネント

### セキュリティ機能
- **SSL設定**: デフォルトでSSL接続（ポート1666）
- **認証拡張**: SAML/OIDC統合準備済み
- **ケースセンシティブトリガー**: ファイル名の大文字小文字一貫性チェック

### 運用機能
- **ヘルスチェック**: 2分間隔でサーバー接続確認
- **ログローテーション**: 自動ログ管理
- **データ永続化**: Dockerボリュームによるデータ保持

### トリガーシステム
- **CheckCaseTrigger3.py**: ケース一貫性チェック
- **P4Triggers.py**: トリガーヘルパーライブラリ
- **エラーメッセージ**: 日本語対応を含むユーザーフレンドリーなメッセージ

## 環境変数

| 変数名 | 説明 | デフォルト値 |
|--------|------|-------------|
| `P4NAME` | Perforceサーバー名 | - |
| `P4PORT` | Perforceサーバーポート | `ssl:1666` |
| `P4USER` | 管理者ユーザー | `super` |
| `P4PASSWD` | 管理者パスワード | - |
| `P4HOME` | Perforceホームディレクトリ | `/opt/perforce` |
| `P4ROOT` | Perforceルートディレクトリ | - |
| `CASE_INSENSITIVE` | ケースセンシティブ設定 | `0` |

## 開発・運用ガイドライン

### 新機能追加時
1. **セキュリティ**: 新機能がセキュリティに影響しないか確認
2. **ドキュメント更新**: README.mdの適切な箇所を更新
3. **テスト**: Docker環境での動作確認
4. **後方互換性**: 既存の設定や動作に影響しないか確認

### コードレビューポイント
- **Dockerfile**: セキュリティベストプラクティスの遵守
- **Python**: P4Pythonライブラリの適切な使用
- **Shell Script**: エラーハンドリングとログ出力
- **設定ファイル**: 本番環境での使用を考慮した設定

### トラブルシューティング
- **ログ確認**: `make logs` でコンテナログを確認
- **コンテナアクセス**: `make shell` でコンテナ内にアクセス
- **SSL問題**: `ssl:1666` での接続確認
- **権限問題**: ボリュームマウントの権限設定確認

## 関連リンク・参考資料

- [Perforce Helix Core ドキュメント](https://www.perforce.com/manuals/p4sag/)
- [GitHub Container Registry](https://github.com/radicalgrimoire/docker-helixcore/pkgs/container/docker-helixcore%2Fhelix-p4d)
- [Helix Authentication Extension](https://github.com/perforce/helix-authentication-extension)

## 注意事項

このコンテナは開発・テスト用途向けです。本番環境での使用には以下を検討してください：
- セキュリティ設定の見直し
- ネットワーク設定の強化
- バックアップ戦略の策定
- モニタリング・アラート設定