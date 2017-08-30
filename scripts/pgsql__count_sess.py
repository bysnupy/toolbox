#!/usr/bin/env python
# vi:ft=python
import os, sys, time
from subprocess import Popen,PIPE,STDOUT

"""
Purpose: Counting the valid postgresql sessions.
Usage: arg1 - Target dbname (default: postgres)
       arg2 - Interval (default: 1 sec)
Return value: H24:mm:ss session_counts(num)
"""

# variables
psql_cmd='/home/postgres/pgsql/bin/psql' # psql absolute path
db_port="5432"         # db_port
time_fmt='%H:%M:%S'
target_dbname=str(sys.argv[1]) if len(sys.argv) > 1 else "postgres" # target DB
interval=sys.argv[2] if len(sys.argv) == 3 else 1

exec_sql='''
SELECT count(*) FROM pg_stat_activity
WHERE datname = '{dbname}'
AND procpid <> pg_backend_pid();
'''.format(dbname=target_dbname)

result_signal = "0"

# main process

# Message Header
info_msg = "Target DB: {dbname}, Interval: {seconds}".format(dbname=target_dbname, seconds=interval)
head_col = "Time\tsession counts\tloadavg(1 min:5 min:15 min)"
head_line = "=" * (len(info_msg) if len(info_msg) > len(head_col) else len(head_col))
print '''{info}
{col}
{line}
'''.format(info=info_msg, col=head_col, line=head_line)

try:
  while result_signal:
    time.sleep(int(interval))
    result = Popen([psql_cmd, '-p{port}'.format(port=db_port), '-A', '-t', '-c', exec_sql], stderr=STDOUT, stdout=PIPE)
# stdout result
    result_stdout = result.stdout.read()
# return code
    result_signal = [ result.communicate()[0], result.returncode]
# print result
    loadavg = "%.2f:%.2f:%.2f" % os.getloadavg()
    print "{time}\t{count}\t{loadavg}".format(time=time.strftime(time_fmt), count=result_stdout.strip(), loadavg=loadavg)

except KeyboardInterrupt:
  print "Done..."

exit(result_signal[1])
