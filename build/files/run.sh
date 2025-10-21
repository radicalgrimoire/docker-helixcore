#!/bin/bash
set -e

p4dctl start -t p4d $P4NAME
sudo service cron start
p4 trust -y -f
yes $P4PASSWD | p4 login
sudo -E -u perforce yes $P4PASSWD | p4 login
cat /root/.p4trust > /opt/perforce/.p4trust
cat /root/.p4tickets > /opt/perforce/.p4tickets
exec /usr/bin/tail --pid=$(cat /var/run/p4d.$P4NAME.pid) -F "$P4ROOT/logs/log"