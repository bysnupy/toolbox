#!/bin/bash

# variables
psql_comm=$HOME/pgsql/bin/psql
psql_opts=" -d postgres -A -t "
exec_sql='select count(*) from pg_stat_activity where procpid != pg_backend_pid()'
interval_sec=1

while :
do
  echo "$(date '+%H:%M:%S') "$($psql_comm $psql_opts -c "$exec_sql")
  sleep $interval_sec
done

exit $?
