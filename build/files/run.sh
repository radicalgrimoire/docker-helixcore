#!/bin/bash
set -e

# 運用ツールのインストール
echo "Installing runtime tools..."
apt-get update && apt-get install -y vim less
echo "Runtime tools installed: vim, less"

# デバッグ: 環境変数の確認
echo "=== DEBUG: Environment Variables ==="
echo "P4NAME: $P4NAME"
echo "P4PORT: $P4PORT"
echo "P4USER: $P4USER"
echo "P4ROOT: $P4ROOT"
echo "P4PASSWD length: ${#P4PASSWD}"
echo "P4PASSWD (first 3 chars): ${P4PASSWD:0:3}***"
echo "=================================="

p4dctl start -t p4d $P4NAME
sudo service cron start
p4 trust -y -f
yes $P4PASSWD | p4 login
sudo -E -u perforce yes $P4PASSWD | p4 login
cat /root/.p4trust > /opt/perforce/.p4trust
cat /root/.p4tickets > /opt/perforce/.p4tickets
exec /usr/bin/tail --pid=$(cat /var/run/p4d.$P4NAME.pid) -F "$P4ROOT/logs/log"