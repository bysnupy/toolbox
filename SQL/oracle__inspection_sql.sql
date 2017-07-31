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
