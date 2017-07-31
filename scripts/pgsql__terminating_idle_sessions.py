#!/usr/bin/env python
# vi:ft=python
from subprocess import Popen,PIPE,STDOUT
import sys,datetime

"""
Purpose: Terminating idle session more than specific times
Return value:  Terminating session counts
"""

# variables
target_dbname='EC_DB'
psql_cmd='/usr/local/postgres/bin/psql'
idle_interval_min='3'

extracting_target_sessions_sql='''
SELECT count(*) FROM (SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '%s'
AND pid <> pg_backend_pid()
AND state = 'idle'
AND state_change < current_timestamp - INTERVAL '%s' MINUTE) as temp;
''' % (target_dbname, idle_interval_min)

# main process
result = Popen([psql_cmd, '-A', '-t', '-c', extracting_target_sessions_sql], stderr=STDOUT, stdout=PIPE)

# stdout result
result_stdout = result.stdout.read()
# return code
result_signal = [ result.communicate()[0], result.returncode]

# print result
print result_stdout.strip()

exit(result_signal[1])
