#!/bin/bash

# Usage: 
#    arg1: IP:Port
#    arg2: ss or netstat (default: ss, optional argument)
#
############################################################################

cmdtype="ss"
if [ $# -gt 1 ]
then
  cmdtype=$2
fi
target="$1"
interval=1

echo "Target connection: $target"

while :
do
  case $cmdtype in
    ss) /usr/sbin/ss -tna | awk -v target=$1 '
       BEGIN { printf "%s ",strftime("%H:%M:%S", systime()); conn_counts=0; }
       { if ( target == $4 && "ESTAB" == $1 ) conn_counts+=1; }
       END { print conn_counts; }'
       sleep $interval
       ;;
    netstat) /usr/sbin/netstat -tna | awk -v target=$1 '
       BEGIN { printf "%s ",strftime("%H:%M:%S", systime()); conn_counts=0; }
       { if ( target == $4 && "ESTABLISHED" == $6 ) conn_counts+=1; }
       END { print conn_counts; }'
       sleep $interval
       ;;
    esac
done

exit $?
