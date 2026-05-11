#!/bin/bash
set -e

password_file="/opt/perforce/servers/${P4NAME}/p4password/super.password"
marker_file="/opt/perforce/servers/${P4NAME}/.rotate_super_password_on_first_boot"

if [ -f "$password_file" ]; then
    CURRENT_SUPER_PASSWORD=$(cat "$password_file")
else
    CURRENT_SUPER_PASSWORD="$P4PASSWD"
fi

p4dctl start -t p4d $P4NAME
sudo service cron start
p4 trust -y -f
yes "$CURRENT_SUPER_PASSWORD" | p4 login

if [ -f "$marker_file" ]; then
    NEW_SUPER_PASSWORD=$(/usr/local/bin/generate-password.sh)
    printf '%s\n%s\n%s\n' "$CURRENT_SUPER_PASSWORD" "$NEW_SUPER_PASSWORD" "$NEW_SUPER_PASSWORD" | p4 passwd super
    mkdir -p "$(dirname "$password_file")"
    printf '%s' "$NEW_SUPER_PASSWORD" > "$password_file"
    chmod 600 "$password_file"
    CURRENT_SUPER_PASSWORD="$NEW_SUPER_PASSWORD"
    rm -f "$marker_file"
fi

sudo -E -u perforce yes "$CURRENT_SUPER_PASSWORD" | p4 login
cat /root/.p4trust > /opt/perforce/.p4trust
cat /root/.p4tickets > /opt/perforce/.p4tickets
exec /usr/bin/tail --pid=$(cat /var/run/p4d.$P4NAME.pid) -F "$P4ROOT/logs/log"
