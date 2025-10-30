#!/bin/bash
set -e

# 運用ツールのインストール
echo "Installing runtime tools..."
apt-get update -qq && apt-get install -y vim less
echo "Runtime tools installed: vim, less"

p4dctl start -t p4d $P4NAME
sudo service cron start
p4 trust -y -f
yes $P4PASSWD | p4 login
sudo -E -u perforce yes $P4PASSWD | p4 login
cat /root/.p4trust > /opt/perforce/.p4trust
cat /root/.p4tickets > /opt/perforce/.p4tickets
exec /usr/bin/tail --pid=$(cat /var/run/p4d.$P4NAME.pid) -F "$P4ROOT/logs/log"