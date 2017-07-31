-- extract DDL SQL from applied filters, 'segment_type', 'segment_name', 'owner'
accept owner  prompt 'Please enter Name of Owner: '
accept segment_type prompt 'Please enter Name of Segment Type: '
accept segment_name  prompt 'Please enter Name of Segment Name: '
set serveroutput on size 1000000
set serveroutput on size unlimited
set long          2000000000
set longchunksize 200000000
set linesize 500
set pagesize 0
set echo off
set feedback off
set heading off
set tab off
set trimspool on
column text format a500
 
select
 trim(substr(dbms_metadata.get_ddl(
 upper('&segment_type'),
 upper('&segment_name'),
 upper('&owner')
 ),2)) as text
from
 dual;
 
-- extract list about running SQLs
set pagesize 1000
set lines 250
col username for a15
col sid for 999999
col serial# for 999999
col terminal for a10
col machine for a40
col status for a10
col sql_text for a70
select
 a.username,
 a.sid,
 a.serial#,
 a.terminal,
 a.machine,
 a.status,
 b.sql_text
from
 v$session a,
 v$sqltext b
where
 a.sql_address = b.address
 and
 a.sql_hash_value = b.hash_value
 and
 b.piece = 0
 and
 a.username is not null
 and
 a.status = 'ACTIVE'
order by
 a.username,a.sid;
 
-- extract the locking SQLs
set linesize 200
set pagesize 1000
col username for a15
col sid for 999999
col serial# for 999999
col terminal for a10
col machine for a40
col status for a10
col sql_text for a70
select
 a.username,
 a.sid,
 a.serial#,
 a.terminal,
 a.machine,
 a.status,
 b.sql_text
from
 v$session a,
 v$sqltext b
where
 a.sql_address = b.address
 and
 a.sql_hash_value = b.hash_value
 and
 b.piece = 0
 and
 a.username not in ('SYS','SYSTEM')
 and
 a.status = 'ACTIVE'
 and
 a.type != 'BACKGROUND'
 and
 a.lockwait is not null
order by
 a.username,a.sid;
 
-- extract general database information, version, block size, character set and so on
set linesize 200
prompt
prompt *** db version
prompt
col banner for a100
SELECT * FROM v$version;
 
prompt
prompt *** db characterset
prompt
col parameter for a30
col value for a10
select parameter, value from nls_database_parameters where parameter like '%CHARACTERSET%';
 
prompt
prompt *** db block_size,db_unique_name
prompt
col name for a30
col value for a10
select name,value from gv$parameter where name in ('db_block_size','db_unique_name') group by name,value;
 
prompt
prompt *** db open_mode,role,log_mode
prompt
col open_mode for a15
col database_role for a15
col log_mode for a15
select open_mode,database_role,log_mode from v$database;
 
prompt
prompt *** open time
prompt
col startup_time for a19
select inst_id,to_char(startup_time,'YYYY/MM/DD hh24:mi:ss') startup_time from gv$instance order by inst_id;
 
prompt
prompt *** listener info
prompt
col name for a30
col value for a100
select inst_id,name,value from gv$parameter where name in ('service_names','local_listener','remote_listener','listener_networks') order by name,inst_id;
 
prompt
prompt *** recover filer
prompt
select * from v$recover_file;

-- extract table, index, partition table, subpartition table based on statistics (not so accurate but useful) with filters (owner, tablename, etc)
set verify off
set feedback off
set linesize 300
set pagesize 1000
prompt
accept owner prompt 'Please enter Name of Table Owner: '
accept table_name  prompt 'Please enter Table Name to show Statistics for: '
alter session set nls_date_format='YYYY/MM/DD hh24:mi:ss';
col table_name for a30
col num_rows for 999,999,999,999
col blocks for 999,999,999
col empty_blocks for 999,999,999
col "AVG_SPACE(BYTE)" for 999,999,999
col chain_cnt for 999,999,999
col "AVG_ROW_LEN(BYTE)" for 999,999,999
col partitioned for a5
col last_analyzed for a19
col column_name for a30
col data_type for a30
col NULLABLE for a10
col num_distinct for 999,999,999,999
col density for 999.999
col "AVG_COL_LEN(BYTE)" for 999,999,999
col histogram for a15
col index_name for a30
col uniqueness for a9
col blev for 999
col leaf_blocks for 999,999,999
col distinct_keys for 999,999,999
col status for a8
col visibility for a10
col dropped for a3
col partition for a3
col index_owner for a15
col partition_name for a30
col global_stats for a3
col interval for a3
col part_type for a9
col part_key for a30
col subpartition_name for a30
col subpart_type for a9
prompt
prompt
prompt*** table info
select table_name,
 num_rows,
 blocks,
 empty_blocks,
 avg_space as "AVG_SPACE(BYTE)",
 chain_cnt,
 avg_row_len  as "AVG_ROW_LEN(BYTE)",
 partitioned as partd,
 last_analyzed
from dba_tables
where
owner = upper(nvl('&&owner',user))
and
table_name = upper('&&table_name')
/
 
prompt
prompt
prompt*** table columns info
select
 column_name,
 data_type,
 decode(nullable,
        'N','NOT NULL',
        'n','NOT NULL',
        NULL) as NULLABLE,
 num_distinct,
 density,
 avg_col_len as "AVG_COL_LEN(BYTE)",
 histogram,
 last_analyzed
from
 dba_tab_columns
where
 owner = upper(nvl('&owner',user))
 and
 table_name = upper('&table_name')
/
 
prompt
prompt
prompt*** index info
 
select
 c.index_owner,
 i.index_name,
 c.column_name,
 i.uniqueness,
 i.blevel blev,
 i.leaf_blocks,
 i.distinct_keys,
 i.status,
 i.visibility,
 i.dropped,
 i.partitioned as partd,
 i.last_analyzed
from
 dba_indexes i,
 dba_ind_columns c
where
 i.table_name = c.table_name
 and
 i.table_owner = c.table_owner
 and
 i.index_name = c.index_name
 and
 i.table_name = upper('&table_name')
 and
 i.table_owner = upper(nvl('&owner',user))
order by
 i.index_name
/
 
PROMPT
PROMPT
PROMPT ++++++++++ Next Partition info
PAUSE ++++++++++ Press Enter to continue or Ctrl+D to stop.
 
prompt
prompt
prompt*** table partition info
select
 t.partition_name,
 p.partitioning_type as part_type,
 k.column_name as part_key,
 p.status,
 t.num_rows,
 t.blocks,
 t.empty_blocks,
 t.avg_space as "AVG_SPACE(BYTE)",
 t.chain_cnt,
 t.avg_row_len  as "AVG_ROW_LEN(BYTE)",
 t.global_stats,
 t.interval,
 t.last_analyzed
from
dba_tab_partitions t,
dba_part_tables p,
dba_part_key_columns k
where
 t.table_owner = p.owner
 and
 t.table_name = p.table_name
 and
 t.table_owner = k.owner
 and
 t.table_name = k.name
 and
 t.table_owner = upper(nvl('&&owner',user))
 and
 t.table_name = upper('&&table_name')
order by
 t.partition_name
/
 
prompt
prompt
prompt*** table partition columns info
select
 partition_name,
 column_name,
 num_distinct,
 density,
 avg_col_len as "AVG_COL_LEN(BYTE)",
 histogram,
 last_analyzed
from
 dba_part_col_statistics
where
 owner = upper(nvl('&owner',user))
 and
 table_name = upper('&table_name')
order by
 partition_name
/
 
prompt
prompt
prompt*** table partition index info
 
select
 i.index_name,
 i.partition_name,
 c.index_owner,
 p.partitioning_type as part_type,
 p.locality,
 c.column_name,
 k.column_name as part_key,
 i.blevel blev,
 i.leaf_blocks,
 i.distinct_keys,
 i.status,
 i.global_stats,
 i.interval,
 i.last_analyzed
from
 dba_ind_partitions i,
 dba_ind_columns c,
 dba_part_indexes p,
 dba_part_key_columns k
where
 i.index_owner = c.index_owner
 and
 i.index_name = c.index_name
 and
 i.index_owner = p.owner
 and
 i.index_name  = p.index_name
 and
 i.index_owner = k.owner
 and
 i.index_name = k.name
 and
 c.table_name = upper('&table_name')
 and
 c.table_owner = upper(nvl('&owner',user))
order by
 i.index_name,
 i.partition_name
/
 
PROMPT
PROMPT
PROMPT ++++++++++ Next Sub Partition info
PAUSE ++++++++++ Press Enter to continue or Ctrl+D to stop.
 
prompt
prompt
prompt*** table sub partition info
select
 t.partition_name,
 t.subpartition_name,
 p.subpartitioning_type as subpart_type,
 k.column_name as part_key,
 p.status,
 t.num_rows,
 t.blocks,
 t.empty_blocks,
 t.avg_space as "AVG_SPACE(BYTE)",
 t.chain_cnt,
 t.avg_row_len  as "AVG_ROW_LEN(BYTE)",
 t.global_stats,
 t.interval,
 t.last_analyzed
from
dba_tab_subpartitions t,
dba_part_tables p,
dba_subpart_key_columns k
where
 t.table_owner = p.owner
 and
 t.table_name = p.table_name
 and
 t.table_owner = k.owner
 and
 t.table_name = k.name
 and
 t.table_owner = upper(nvl('&&owner',user))
 and
 t.table_name = upper('&&table_name')
order by
 t.partition_name,
 t.subpartition_name
/
 
prompt
prompt
prompt*** table sub partition columns info
select
 subpartition_name,
 column_name,
 num_distinct,
 density,
 avg_col_len as "AVG_COL_LEN(BYTE)",
 histogram,
 last_analyzed
from
 dba_subpart_col_statistics
where
 owner = upper(nvl('&owner',user))
 and
 table_name = upper('&table_name')
order by
 subpartition_name
/
 
prompt
prompt
prompt*** table sub partition index info
 
select
 i.index_name,
 i.partition_name,
 i.subpartition_name,
 c.index_owner,
 p.subpartitioning_type as subpart_type,
 p.locality,
 c.column_name,
 k.column_name as part_key,
 i.blevel blev,
 i.leaf_blocks,
 i.distinct_keys,
 i.status,
 i.global_stats,
 i.interval,
 i.last_analyzed
from
 dba_ind_subpartitions i,
 dba_ind_columns c,
 dba_part_indexes p,
 dba_subpart_key_columns k
where
 i.index_owner = c.index_owner
 and
 i.index_name = c.index_name
 and
 i.index_owner = p.owner
 and
 i.index_name  = p.index_name
 and
 i.index_owner = k.owner
 and
 i.index_name = k.name
 and
 c.table_name = upper('&table_name')
 and
 c.table_owner = upper(nvl('&owner',user))
order by
 i.index_name,
 i.partition_name,
 i.subpartition_name
/

-- listing the partitions
set feedback off
alter session set nls_date_format='YYYY/MM/DD hh24:mi:ss';
set feedback on
set linesize 300
set pagesize 1000
col table_owner for a15
col table_name for a30
col partition_name for a30
col part_type for a9
col part_key for a30
col tablespace_name for a30
col last_analyzed for a19
select
 t.table_owner,
 t.table_name,
 t.partition_name,
 p.partitioning_type as part_type,
 k.column_name as part_key,
 t.tablespace_name,
 t.last_analyzed
from
 dba_tab_partitions t,
 dba_part_tables p,
 dba_part_key_columns k
where
 t.table_owner not in ('SYS','SYSTEM')
 and
 t.table_owner = p.owner
 and
 t.table_name = p.table_name
 and
 t.table_owner = k.owner
 and
 t.table_name = k.name
order by
 t.table_owner,
 t.table_name,
 t.partition_name;
 
-- listing the subpartitions
set feedback off
alter session set nls_date_format='YYYY/MM/DD hh24:mi:ss';
set feedback on
set linesize 300
set pagesize 1000
col table_owner for a15
col table_name for a30
col partition_name for a30
col subpartition_name for a30
col tablespace_name for a30
col part_key for a30
col subpart_type for a9
col last_analyzed for a19
select
 t.table_owner,
 t.table_name,
 t.partition_name,
 t.subpartition_name,
 p.subpartitioning_type as subpart_type,
 k.column_name as part_key,
 t.tablespace_name,
 t.last_analyzed
from
 dba_tab_subpartitions t,
 dba_part_tables p,
 dba_subpart_key_columns k
where
 t.table_owner not in ('SYS','SYSTEM')
 and
 t.table_owner = p.owner
 and
 t.table_name = p.table_name
 and
 t.table_owner = k.owner
 and
 t.table_name = k.name
order by
 t.table_owner,
 t.table_name,
 t.partition_name,
 t.subpartition_name;
 
-- extract the disk groups from ASM
SET LINE 270;
SET PAGESIZE 9999;
COL "DiskGroup Name" FORMAT A10;
COL "Disk Name" FORMAT A30;
COL FAILGROUP FORMAT A15;
COL PATH FORMAT A60;
COL MOUNT_STATUS FORMAT A10;
COL HEADER_STATUS FORMAT A10;
COL MODE_STATUS FORMAT A10;
SELECT g.name "DiskGroup Name",
d.name "Disk Name",
d.failgroup,
d.path,
d.mount_status,
d.header_status,
d.mode_status,
d.total_mb,
d.free_mb
FROM v$asm_disk d,
v$asm_diskgroup g
WHERE g.group_number = d.group_number
ORDER BY 1,3,2;

-- extract maintenance jobs results
set lines 200
col window_name for a20
col resource_plan for a30
col next_start_date for a35
col last_start_date for a35
col enabled for a15
col job_name for a22
col job_status for a10
 
select
 s.window_name,
 s.resource_plan,
 s.next_start_date,
 s.last_start_date,
 s.enabled,
 j.job_name,
 j.job_status
from
 dba_scheduler_windows s,
 dba_autotask_job_history j
where
 s.window_name = j.window_name
order by
 s.window_name,
 j.job_name;
 
-- extract the hidden parameters
set linesize 150
set pages 9999
col Parameter for a50
col Value for a90
select
  a.ksppinm "Parameter"
 ,b.ksppstvl "Value"
 --,a.KSPPDESC "Description"
from
  x$ksppi a,
  x$ksppcv b
where
  a.indx = b.indx
 and
  a.ksppinm like '%&PARAM_NAME%';
  
-- extract materialized view log informations
set linesize 270
set feedback off
alter session set nls_date_format = 'yyyy/mm/dd hh24:mi:ss';
set feedback on
col log_owner for a10
col master for a30
col log_table for a30
col purge_asynchronous for a3
col purge_deferred for a3
col purge_start for a19
col purge_interval for a30
col last_purge_date for a19
col last_purge_status for 999
col num_rows_purged for 999999999999
col rowids for a5
col p_key for a5
select
 log_owner,
 master,
 log_table,
 purge_asynchronous,
 purge_deferred,
 purge_start,
 purge_interval,
 last_purge_date,
 last_purge_status,
 num_rows_purged,
 rowids,
 primary_key p_key
from
 dba_mview_logs;
 
-- extract the materialized view informations
set linesize 270
set pages 9999
set feedback off
alter session set nls_date_format = 'yyyy/mm/dd hh24:mi:ss';
set feedback on
col owner for a10
col mview_name for a30
col master_link for a30
col master_rollback_seg for a20
col refresh_mode for a10
col refresh_method for a10
col fast_refreshable for a15
col last_refresh_date for a19
col last_refresh_type for a10
col updatable for a1
col staleness for a10
col stale_since format a19
 
select
 owner,
 mview_name,
 master_link,
 master_rollback_seg,
 refresh_mode,
 refresh_method,
 fast_refreshable,
 last_refresh_date,
 last_refresh_type,
 updatable,
 staleness,
 stale_since
from
 dba_mviews;
 
-- extract db links informations
set lines 200
set pagesize 100
set feedback off
alter session set nls_date_format = 'yyyy/mm/dd hh24:mi:ss';
set feedback on
col owner for a15
col db_link for a30
col username for a15
col host for a30
col created for a19
select
 owner,
 db_link,
 username,
 host,
 created
from
 dba_db_links
order by
 1,2,3;
 
-- extract the SQL informations based on SQL start time and end time
accept starttime prompt 'Please enter exec start time[ex 2012/07/05 08:00:01] : '
accept endtime prompt 'Please enter exec end time[ex 2012/07/05 14:00:01] : '
accept inst_no prompt 'Please enter instance number : '
set lines 400
set pagesize 2000
col sql_exec_start for a21
col max_sample_time for a21
col machine for a35
col sql_id for a15
col sql_opname for a15
col op_count for 9999
col "min_pga(MB)" for 999999999
col "max_pga(MB)" for 999999999
col "min_temp(MB)" for 999999999
col "max_temp(MB)" for 999999999
select
 to_char(sql_exec_start,'YYYY/MM/DD hh24:mi:ss') sql_exec_start,
 max(to_char(sample_time,'YYYY/MM/DD hh24:mi:ss')) as max_sample_time,
 substr(machine,0,35) machine,
 sql_id,
 sql_opname,
 count(*) as op_count,
 min(round(pga_allocated/1024/1024,1)) as "min_pga(MB)",
 max(round(pga_allocated/1024/1024,1)) as "max_pga(MB)",
 min(round(temp_space_allocated/1024/1024,1)) as "min_temp(MB)",
 max(round(temp_space_allocated/1024/1024,1)) as "max_temp(MB)"
from
 dba_hist_active_sess_history
where
 sql_exec_start between
 to_date('&starttime','YYYY/MM/DD hh24:mi:ss')
 and
 to_date('&endtime','YYYY/MM/DD hh24:mi:ss')
 and
 instance_number=&inst_no
group by
 sql_id,
 sql_opname,
 sql_exec_start,
 machine
order by sql_exec_start;

-- extract SQL counts from SQLID and time ranges
accept sqlid prompt 'Please enter sql_id : '
accept starttime prompt 'Please enter exec start time[ex 2012/07/05 08:00:01] : '
accept endtime prompt 'Please enter exec start time[ex 2012/07/05 14:00:01] : '
accept inst_no prompt 'Please enter instance number : '
col sql_exec_start for a16
col exec_count for 999999
select
 sql_exec_start
 ,count(*) as exec_count
from
(
select
 to_char(sql_exec_start,'YYYY/MM/DD hh24') sql_exec_start
from
 dba_hist_active_sess_history
where
 sql_id='&sqlid'
 AND
 instance_number=&inst_no
 AND
 sql_exec_start BETWEEN
 to_date('&starttime','YYYY/MM/DD hh24:mi:ss')
 AND
 to_date('&endtime','YYYY/MM/DD hh24:mi:ss')
group by
 sql_exec_start
)
group by
 sql_exec_start
order by
 sql_exec_start;
 
-- extract SQL sample counts based on program, machine and exec plans
accept sqlid prompt 'Please enter sql_id : '
accept starttime prompt 'Please enter sample time[ex 12-07-05 08:00:01] : '
accept endtime prompt 'Please enter sample time[ex 12-07-05 14:00:01] : '
accept inst_no prompt 'Please enter instance number : '
 
set lines 400
set pagesize 2000
col session_type for a10
col program for a35
col machine for a35
col sql_exec_start for a21
col sql_plan_hash_value for 9999999999999999999
 
select
 to_char(sql_exec_start,'YYYY/MM/DD hh24:mi:ss') sql_exec_start
 ,substr(machine,0,35) machine
 ,substr(program,0,35) program
 ,sql_plan_hash_value
 ,session_type
 ,count(*) sample_count
from
 dba_hist_active_sess_history
where
 sql_id in ('&sqlid')
 AND
 sample_time between
 to_timestamp('&starttime','YY-MM-DD HH24:MI:SS')
 AND
 to_timestamp('&endtime','YY-MM-DD HH24:MI:SS')
 AND
 instance_number=&inst_no
group by
　program
 ,machine
 ,sql_plan_hash_value
 ,session_type
 ,sql_exec_start
order by
 sql_exec_start;
 
-- extract top 5 wait events based on the instance number adn time range (e.g. between 10 minutes)
accept inst_no prompt 'Please enter instance number : '
accept starttime prompt 'Please enter sample time[ex 12-07-05 08:00] : '
accept endtime prompt 'Please enter sample time[ex 12-07-05 08:03] : '
 
select
 sample_time
 ,event
 ,exec_count
from
(
select 
 sample_time
 ,event
 ,count(event) as exec_count 
 ,row_number() over(partition by sample_time order by count(event) desc) as rank
from 
( 
select 
 to_char(sample_time,'YYYY/MM/DD hh24:MI') sample_time
 ,event
from
 dba_hist_active_sess_history
where 
 instance_number=&inst_no
 AND 
 SAMPLE_TIME BETWEEN
 to_timestamp('&starttime','YY-MM-DD HH24:MI')
 AND
 to_timestamp('&endtime','YY-MM-DD HH24:MI')
) 
group by 
 sample_time
 ,event
order by  
 sample_time,
 exec_count desc
)
where
 rank <= 5;

-- extract SQL_IDs having specific events
accept waitevent prompt 'Please enter wait event : '
accept starttime prompt 'Please enter sample time[ex 12-07-05 08:00:00] : '
accept endtime prompt 'Please enter sample time[ex 12-07-05 08:03:00] : '
 
select 
 count(sql_id), 
 sql_id 
from 
 dba_hist_active_sess_history
where 
 event='&waitevent'
  AND 
 SAMPLE_TIME BETWEEN
 to_timestamp('&starttime','YY-MM-DD HH24:MI:SS') 
  AND 
 to_timestamp('&endtime','YY-MM-DD HH24:MI:SS') 
group by 
 sql_id order by 1 desc;
 
-- extract full scan(table, index) SQLs - LAST_ACTIVE_TIME colum is decision point
set lines 400
col sql_id for a15
col operation for a20
col sql_text for a150
col options for a10
col object_owner for a20
col object_name for a30
col last_active_time for a21
col parsing_user for a20
select
 sp.sql_id
 ,max(sp.operation) as operation
 ,sp.options as options
 ,max(sp.object_owner) as object_owner
 ,max(du.username) as parsing_user
 ,max(sp.object_name) as object_name
 ,max(to_char(s.last_active_time,'YYYY/MM/DD hh24:mi:ss')) as last_active_time
 ,substr(s.sql_text,0,150) as sql_text
from
 gv$sql s,
 gv$sql_plan_statistics_all sp,
 dba_users du
where
 sp.options in ('FULL','FULL SCAN')
 and
 sp.object_owner=upper('&OWNER')
 and
 s.address=sp.address
 and
 s.hash_value=sp.hash_value
 and
 s.plan_hash_value=sp.plan_hash_value
 and
 du.user_id = s.parsing_user_id
group by
 sp.sql_id,
 sp.options,
 s.sql_text
order by
 sql_text
 ,operation
 ,object_name;

-- if 'select min(SAMPLE_TIME),max(SAMPLE_TIME) from v$active_session_history;' is empty, you should replace the 'gv$active_session_history' with 'dba_hist_active_sess_history'
accept starttime prompt 'inspection start time [ex 12-07-05 08:00:00] : '
accept endtime prompt 'instpection end time[ex 12-07-05 08:03:00] : '
accept min_cputime prompt 'specify the minimum CPU milliseonds (e.g. 10000 = 10 secs) : '
 
col sql_id for a15
col max_tm_delta_cpu_time_ms for 999,999,999,999
col STARTTIME for a20
col ENDTIME for a20
col rnk for 999
select
 sql_id,  -- SQL_ID to sepecify the current SQL
 count(*), -- SQL sample counts
 max(to_char(sql_exec_start,'YYYY/MM/DD hh24:mi:ss')) as starttime, -- SQL start time
 max(to_char(sample_time,'YYYY/MM/DD hh24:mi:ss')) as endtime, -- SQL end time based on sample
 sum(tm_delta_cpu_time/1000) as max_tm_delta_cpu_time_ms, -- CPU time (milliseconds based on exec time)
 RANK() over (order by sum(tm_delta_cpu_time/1000) desc) AS rnk -- add the SQL rank
from
 gv$active_session_history
where
 sample_time between
  to_timestamp('&starttime','YY-MM-DD HH24:MI:SS')
 AND
  to_timestamp('&endtime','YY-MM-DD HH24:MI:SS')
 group by
  sql_id,sql_exec_start
having
 sum(tm_delta_cpu_time/1000) > &min_cputime;

-- specify the PGA usage SQLs. If 'select min(SAMPLE_TIME),max(SAMPLE_TIME) from v$active_session_history;'  is empty, you should replace the 'gv$active_session_history' with 'dba_hist_active_sess_history'
accept starttime prompt 'insepection start time [ex 12-07-05 08:00:00] : '
accept endtime prompt 'inspection end time [ex 12-07-05 08:03:00] : '
accept pga_alloc prompt 'the minimum PGA usage(KB) [e.g. 10240 = 10 MB ] : ' 
 
col sql_id for a15
col max_pga_allocated_kb for 999,999,999,999
col STARTTIME for a20
col ENDTIME for a20
col rnk for 999
select
 sql_id,   -- SQL_ID to sepecify the current SQL
 count(*), -- SQL sample counts
 max(to_char(sql_exec_start,'YYYY/MM/DD hh24:mi:ss')) as starttime, -- SQL start time
 max(to_char(sample_time,'YYYY/MM/DD hh24:mi:ss')) as endtime, -- SQL end time based on sample
 max(pga_allocated/1024) as max_pga_allocated_kb, -- max PGA size filtered with sql_id and sql_exec_start
 RANK() over (order by max(pga_allocated) desc) AS rnk -- adding the SQL rank
from
 gv$active_session_history
where
 sample_time between
  to_timestamp('&starttime','YY-MM-DD HH24:MI:SS')
 AND
  to_timestamp('&endtime','YY-MM-DD HH24:MI:SS')
 group by
  sql_id,sql_exec_start
having
 max(pga_allocated/1024) > &pga_alloc;

-- extract the SQLs to used temporary tablespaces. If 'select min(SAMPLE_TIME),max(SAMPLE_TIME) from v$active_session_history;'  is empty, you should replace the 'gv$active_session_history' with 'dba_hist_active_sess_history'
accept starttime prompt 'inspection start time [e.g. 12-07-05 08:00:00] : '
accept endtime prompt 'inspection end time [e.g. 12-07-05 08:03:00] : '
accept temp_space_alloc prompt 'specify the minimum TEMP usage size(KB) [e.g. 10240 = 10 MB] : '
 
col sql_id for a15
col max_temp_space_allocated_kb for 999,999,999,999
col STARTTIME for a20
col ENDTIME for a20
col rnk for 999
select
 sql_id,    -- SQL_ID to sepecify the current SQL
 count(*),　-- SQL sample counts
 max(to_char(sql_exec_start,'YYYY/MM/DD hh24:mi:ss')) as starttime,　-- SQL start time
 max(to_char(sample_time,'YYYY/MM/DD hh24:mi:ss')) as endtime,　-- SQL end time based on sample
 max(temp_space_allocated/1024) as max_temp_space_allocated_kb,　-- max TEMP size filtered with sql_id and sql_exec_start
 RANK() over (order by sum(temp_space_allocated) desc) AS rnk　-- adding the SQL rank
from
 gv$active_session_history
where
 sample_time between
  to_timestamp('&starttime','YY-MM-DD HH24:MI:SS')
 AND
  to_timestamp('&endtime','YY-MM-DD HH24:MI:SS')
 group by
  sql_id,sql_exec_start
having
 max(temp_space_allocated/1024) > &temp_space_alloc;


