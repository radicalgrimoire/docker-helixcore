# Docker Helix Core

Perforce Helix Core (P4D) サーバーを Docker コンテナで実行するためのリポジトリです。  
現在の標準起動構成は、`p4d/Dockerfile` から既存イメージを参照して `docker-compose.yml` で起動する方式です。

## 概要

- 開発・検証向けの Helix Core コンテナ環境
- SSL 接続 (`1666`) 前提の構成
- 起動時ヘルスチェックあり
- ケース一貫性チェック用トリガー（`CheckCaseTrigger3.py`）を含むイメージを利用
- データは Docker ボリューム `servers` に永続化

## 現在の構成

主要ファイル:

- `docker-compose.yml`: コンテナ起動設定（`helix-p4d`）
- `Makefile`: 主要操作コマンド（起動/停止/ログ/シェル/ビルド）
- `p4d/Dockerfile`: `ghcr.io/radicalgrimoire/docker-helixcore/helix-p4d:latest` ベースの実行用イメージ
- `build/Dockerfile`: ベースイメージを独自に再構築するための定義
- `build/files/init.sh`: 初期セットアップ（サーバー設定・トリガー設定）
- `build/files/run.sh`: サーバー起動・ログ出力

ネットワーク/ポート設定（`docker-compose.yml`）:

- カスタムネットワーク: `app_net` (`172.16.238.0/24`)
- コンテナ IP: `172.16.238.10`
- 公開ポート: `1666:1666`

## 前提条件

- Docker
- Docker Compose
- Make（`Makefile` 利用時）
- Windows で `make shell` を使う場合は `winpty` が必要

## クイックスタート

### 1. 起動

```bash
make start
```

または:

```bash
docker-compose -f docker-compose.yml -p helixcore up -d
```

### 2. ログ確認

```bash
make logs
```

### 3. シェル接続

```bash
make shell
```

### 4. 停止

```bash
make stop
```

### 5. コンテナ削除

```bash
make remove
```

## Makefile コマンド

- `make start`: 起動
- `make stop`: 停止
- `make remove`: `docker-compose down`
- `make logs`: ログ追従
- `make shell`: コンテナ内シェル
- `make build`: イメージビルド
- `make rebuild`: キャッシュ無しで再ビルド

## 環境変数

このプロジェクトで利用する主な環境変数:

| 変数名 | 説明 | 代表値 |
| --- | --- | --- |
| `P4NAME` | Perforce サーバー名 | 任意 |
| `P4PORT` | Perforce サーバーポート | `ssl:1666` |
| `P4USER` | 管理者ユーザー | `super` |
| `P4PASSWD` | 管理者パスワード | 任意 |
| `P4HOME` | Perforce ホーム | `/opt/perforce` |
| `P4ROOT` | Perforce ルート | 例: `/opt/perforce/servers/<server>/root` |
| `CASE_INSENSITIVE` | 大文字小文字設定 | `0` |

注記:

- 現在の `docker-compose.yml` では環境変数を明示指定していません。
- 既定動作は参照元イメージ側の設定に依存します。
- 値を固定したい場合は `docker-compose.yml` の `services.helixcore.environment` に明示してください。

例:

```yaml
services:
  helixcore:
    environment:
      P4NAME: helix
      P4PORT: ssl:1666
      P4USER: super
      P4PASSWD: your-password
```

## データ永続化

- ボリューム: `servers`
- マウント先: `/opt/perforce/servers`

コンテナを再作成してもボリュームを削除しない限りデータは保持されます。

## 接続方法

P4V / CLI からの接続例:

- サーバー: `ssl:localhost:1666`
- ユーザー: `super`（または設定したユーザー）
- パスワード: 設定値

CLI 例:

```bash
p4 -p ssl:localhost:1666 -u super login
```

## 独自ビルド（必要時）

通常運用では `p4d/Dockerfile` による既存イメージ利用で十分です。  
独自イメージを作る場合は `build/` を使用します。

```bash
make build
make rebuild
```

または:

```bash
bash build/docker-build.sh Dockerfile ./build
```

## トラブルシューティング

### 起動しない

- `1666` ポート使用状況を確認
- `make logs` でエラー確認
- `docker ps -a` でコンテナ状態を確認

### 接続できない

- 接続先が `ssl:localhost:1666` になっているか確認
- 初回接続時に証明書信頼が必要な場合あり

### 状態確認

```bash
make shell
p4dctl status
```

## 参考リンク

- [Perforce Helix Core ドキュメント](https://www.perforce.com/manuals/p4sag/)
- [コンテナイメージ](https://github.com/radicalgrimoire/docker-helixcore/pkgs/container/docker-helixcore%2Fhelix-p4d)
- [Helix Authentication Extension](https://github.com/perforce/helix-authentication-extension)

## 注意事項

この構成は開発・検証用途を想定しています。  
本番利用時は、認証/権限管理、ネットワーク制限、バックアップ、監視、証明書運用を別途設計してください。
