#!/bin/bash

if ! p4dctl list 2>/dev/null | grep -q $P4NAME; then

/opt/perforce/sbin/configure-helix-p4d.sh $P4NAME -n -p $P4PORT -r $P4ROOT -u $P4USER -P $P4PASSWD --case $CASE_INSENSITIVE --unicode
echo bash /opt/perforce/sbin/configure-helix-p4d.sh $P4NAME -n -p $P4PORT -r $P4ROOT -u $P4USER -P $P4PASSWD --case $CASE_INSENSITIVE --unicode
p4 trust -y -f

cat > ~perforce/.p4config <<EOF
P4USER=$P4USER
P4PORT=$P4PORT
P4PASSWD=$P4PASSWD
EOF

chmod 0600 ~perforce/.p4config
chown perforce:perforce ~perforce/.p4config

p4 login <<EOF
$P4PASSWD
EOF

fi


