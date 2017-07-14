#!/usr/bin/env python
# vi: ft=python
#==========================================
# PostgreSQL object reporter
# Version: 1.1
#
# History:
# - 2017.6.30: adding trigger report section
#
'''
Usage: diff old_report.txt new_report.txt
'''

from subprocess import Popen,PIPE
import sys,datetime

# initialize variables

db_user='DB_USERNAME'
db_name='DB_NAME'
db_adminuser='postgres'
psql_cmd='/usr/local/pgsql/bin/psql'

date_suffix=datetime.datetime.today().strftime('%Y%m%d-%H%M')
result_file='/tmp/%s_%s.report' % (db_name, date_suffix)

file = open(result_file, 'w')

# initialize functions
def get_result(sql):
  result = Popen([psql_cmd, '-A', '-t', '-U', db_user, '-d', db_name , '-c', sql], stdout=PIPE)
  sql_result = result.stdout.read()
  if sql_result is None or len(sql_result) == 0:
    sql_result = 'None'
  return sql_result.strip()

def get_resultlist(sql):
  result = Popen([psql_cmd, '-A', '-t', '-U', db_user, '-d', db_name , '-c', sql], stdout=PIPE)
  return result

def get_tablecount(tablename):
  return Popen([psql_cmd, '-A', '-t', '-U', db_user, '-d', db_name , '-c', "SELECT count(*) FROM %s" % tablename], stdout=PIPE).stdout.read()

def get_seq_spec(tablename):
  return Popen([psql_cmd, '-A', '-t', '-U', db_user, '-d', db_name , '-c', "SELECT sequence_name,last_value,increment_by,min_value,max_value FROM %s" % tablename], stdout=PIPE).stdout.read()

# initialize SQL statements
## Tables
table_check_sql = '''SELECT pc.relname FROM pg_class pc LEFT JOIN pg_user pu ON pc.relowner = pu.usesysid
WHERE pu.usename = '%s' AND pc.relkind = 'r'
ORDER BY pc.relname DESC
''' % db_user
table_cnt_sql = '''SELECT count(*) FROM pg_class pc LEFT JOIN pg_user pu ON pc.relowner = pu.usesysid
WHERE pu.usename = '%s' AND pc.relkind = 'r'
''' % db_user
## Indexes
index_check_sql = '''SELECT indexrelname FROM pg_stat_user_indexes ORDER BY indexrelname DESC'''
index_cnt_sql = '''SELECT count(*) FROM pg_stat_user_indexes'''
## Sequences
seq_check_sql = '''SELECT pc.relname FROM pg_class pc LEFT JOIN pg_user pu ON pc.relowner = pu.usesysid
WHERE pu.usename = '%s' AND pc.relkind = 'S'
ORDER BY pc.relname DESC
''' % db_user
seq_cnt_sql = '''SELECT count(*) FROM pg_class pc LEFT JOIN pg_user pu ON pc.relowner = pu.usesysid
WHERE pu.usename = '%s' AND pc.relkind = 'S'
''' % db_user
## Views
view_check_sql = "SELECT viewname FROM pg_views WHERE viewowner = '%s' ORDER BY viewname DESC" % db_user
view_cnt_sql = "SELECT count(*) FROM pg_views WHERE viewowner = '%s'" % db_user

## Procedures
proc_check_sql = "SELECT p.proname FROM pg_proc p JOIN pg_user u ON p.proowner = u.usesysid WHERE u.usename <> '%s' ORDER BY p.proname DESC" % db_adminuser
proc_cnt_sql = "SELECT count(*) FROM pg_proc p JOIN pg_user u ON p.proowner = u.usesysid WHERE u.usename <> '%s'" % db_adminuser

## Trggers
trg_check_sql = "SELECT tgname FROM pg_trigger ORDER BY tgname DESC"
trg_cnt_sql   = "SELECT count(*) FROM pg_trigger"


table_name_list = get_result(table_check_sql)
seq_name_list = get_result(seq_check_sql)

section1 = '''
###################### 1. Objects check section ####################################

##### 1.1. Tables          #########################################################
%s
##### 1.2. Indexes         #########################################################
%s
##### 1.3. Sequences       #########################################################
%s
##### 1.4. Views           #########################################################
%s
##### 1.5. Procedures      #########################################################
%s
##### 1.6. Triggers        #########################################################
%s''' % (
table_name_list,
get_result(index_check_sql),
seq_name_list,
get_result(view_check_sql),
get_result(proc_check_sql),
get_result(trg_check_sql)
)
file.write(section1)
print section1

section2 =  '''
###################### 2. Table tuple counts check section ########################
'''
for table in table_name_list.split('\n'):
  section2 += '%-40s%38s' % (table, get_tablecount(table))

file.write(section2)
print section2

section3 = '''
###################### 3. Sequence states check section ###########################
sequence_name\t\tlast_value\tincrement_by\tmin_value\tmax_value
'''
for table in seq_name_list.split('\n'):
  section3 += '\t'.join(get_seq_spec(table).split('|'))

file.write(section3)
print section3

table_cnt = get_result(table_cnt_sql)
index_cnt = get_result(index_cnt_sql)
seq_cnt  = get_result(seq_cnt_sql)
view_cnt = get_result(view_cnt_sql)
proc_cnt = get_result(proc_cnt_sql)
trg_cnt  = get_result(trg_cnt_sql)
total_cnt = int(table_cnt) + int(index_cnt) + int(seq_cnt) + int(view_cnt) + int(proc_cnt) + int(trg_cnt)

summary = '''
###################### 4. Summary #################################################

  4.1. Table     counts     : %s
  4.2. Index     counts     : %s
  4.3. Sequence  counts     : %s
  4.4. View      counts     : %s
  4.5. Procedure counts     : %s
  4.6. Trigger   counts     : %s
-----------------------------------------------------------------------------------
  Total object counts       : %s
''' % (
table_cnt, index_cnt, seq_cnt, view_cnt, proc_cnt, trg_cnt, str(total_cnt)
)

file.write(summary)
print summary

file.close()
print 'Done.'
