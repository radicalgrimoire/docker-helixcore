#!/bin/bash

if ! p4dctl list 2>/dev/null | grep -q $P4NAME; then

/opt/perforce/sbin/configure-helix-p4d.sh $P4NAME -n -p $P4PORT -r $P4ROOT -u $P4USER -P $P4PASSWD --case $CASE_INSENSITIVE --unicode
echo bash /opt/perforce/sbin/configure-helix-p4d.sh $P4NAME -n -p $P4PORT -r $P4ROOT -u $P4USER -P $P4PASSWD --case $CASE_INSENSITIVE --unicode
p4 trust -y -f

p4 configure set server.extensions.allow.unsigned=1
p4 configure set net.keepalive.idle=10
p4 configure set net.keepalive.interval=30
p4 configure set net.keepalive.count=3

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

su - perforce

yes ${P4PASSWD} | p4 -p ${P4PORT} -u super login

pushd /usr/local/bin/
p4 triggers -o > triggers.txt
echo '   CheckCaseTrigger change-submit //... "python3 /usr/local/bin/CheckCaseTrigger3.py %changelist% port=ssl:1666 user=super"' >> triggers.txt
p4 triggers -i < triggers.txt
popd

cp /root/.p4trust /opt/perforce/.p4trust
cp /root/.p4tickets /opt/perforce/.p4tickets

chown perforce:perforce /opt/perforce/.p4trust
chown perforce:perforce /opt/perforce/.p4tickets

pushd /opt/perforce
p4 trust -y -f
popd

p4 -p $P4PORT group -i < /opt/perforce/admin.txt


exit

fi