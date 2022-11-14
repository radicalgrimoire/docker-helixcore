#!/bin/bash
set -e

p4dctl start -t p4d $P4NAME
exec /usr/bin/tail --pid=$(cat /var/run/p4d.$P4NAME.pid) -F "$P4ROOT/logs/log"
