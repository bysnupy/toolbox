#!/bin/bash

#
# tcp connection counts from ss or netstat output
# 

netstat -tna | 
awk 'BEGIN { printf "%s ", strftime("%H:%M:%S", systime()); conn_counts=0; }
{ if ( "xxx.xxx.xxx.xxx" == $4 && "ESTABLISHED" == $6 ) conn_counts += 1; }
END { print conn_counts; }'

exit $?
