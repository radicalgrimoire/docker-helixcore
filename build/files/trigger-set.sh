#!/bin/bash

yes ${P4PASSWD} | p4 -p ${P4PORT} -u super login
pushd /usr/local/bin/
p4 triggers -o > triggers.txt
echo '   CheckCaseTrigger change-submit //... "python3 /usr/local/bin/CheckCaseTrigger3.py %changelist% port=ssl:1666 user=super"' >> triggers.txt
p4 triggers -i < triggers.txt
popd
