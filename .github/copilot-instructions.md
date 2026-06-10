# 重要な指示

# 必須要件: GitHub Copilot は、このプロジェクトでのすべての回答・提案・コメントを日本語で行ってください

- コード提案時のコメント
- エラーメッセージの説明
- 実装方針の提案
- ドキュメント生成
- 問題解決の提案

すべて日本語で回答し、日本の開発者にとって理解しやすい形で情報を提供してください。

# 絵文字使用禁止: GitHub Copilot は、このプロジェクトでの修正内容・コード・コメント・ドキュメントに絵文字を使用してはいけません

- コード内のコメント
- ログメッセージ
- エラーメッセージ
- YAML・設定ファイル
- Shell Script・Python コード
- ドキュメント・README

すべてのプログラムコードとそのコメントは絵文字を含まず、テキストのみで記載してください。

# プロジェクト概要

- **目的**: Perforce Helix Core サーバーの Docker 化
- **対象環境**: 開発・テスト環境（本番環境向けには追加のセキュリティ設定が必要）
- **言語・技術スタック**: Docker, Docker Compose, Python, Shell Script, Makefile
- **メンテナー**: radicalgrimoire (六魔辞典)


# Git 運用ルール

- `main` ブランチへの直接 push は禁止します
- 変更を行う際は必ず作業用の別ブランチを作成し、`main` 上ではコミットせず、その作業ブランチ上でコミットしてください。
- 最終的な反映はプルリクエストを作成し、レビュー後にマージする運用を前提としてください。
- コミットメッセージおよびプルリクエスト本文・タイトルは英語で記述してください。
- Copilot がコミットおよび push を完了した後は、必ず `main` ブランチへ切り替えてください。
- 未コミット変更などで `main` へ切り替えできない場合は、変更を勝手に破棄せず停止し、ユーザーに確認してください。
- ブランチ命名規則は feature ブランチを基本とし、以下の形式を使用してください。
  - `feature/<ブランチ名>`

# 関連リンク・参考資料

- [Perforce Helix Core ドキュメント](https://www.perforce.com/manuals/p4sag/)
- [GitHub Container Registry](https://github.com/radicalgrimoire/docker-helixcore/pkgs/container/docker-helixcore%2Fhelix-p4d)
- [Helix Authentication Extension](https://github.com/perforce/helix-authentication-extension)

# 注意事項

このコンテナは開発・テスト用途向けです。本番環境での使用には以下を検討してください：
- セキュリティ設定の見直し
- ネットワーク設定の強化
- バックアップ戦略の策定
- モニタリング・アラート設定
