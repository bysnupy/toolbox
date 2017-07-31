-- extract current session status
set linesize 300
set pagesize 1000
set feedback off
alter session set nls_date_format='YYYY/MM/DD hh24:mi:ss';
set feedback on
col inst_id for 99
col sid for 999999
col serial# for 999999
col username for a15
col status for a10
col name for a15
col lockwait for a16
col schemaname for a10
col osuser for a10
col process for a10
col machine for a40
col terminal for a8
col logon_time for a19
col program for a50
col sql_id for a20
 
select
    s.inst_id
    ,s.username
    ,s.sid
    ,s.serial#
    ,s.status
    ,a.name
    ,s.lockwait
    ,s.schemaname
    ,s.osuser
    ,s.process
    ,s.machine
    ,s.terminal
    ,s.logon_time
    ,s.program
    ,s.sql_id
from
    gv$session s
    ,audit_actions a
where
    s.command = a.action
order by
    s.inst_id;
    
-- extract only the user sessions
set linesize 300
set pagesize 1000
set feedback off
alter session set nls_date_format='YYYY/MM/DD hh24:mi:ss';
set feedback on
col inst_id for 99
col sid for 999999
col serial# for 999999
col username for a15
col status for a10
col name for a15
col lockwait for a16
col schemaname for a10
col osuser for a10
col process for a10
col machine for a40
col terminal for a8
col logon_time for a19
col program for a50
col sql_id for a20
 
select
    s.inst_id
    ,s.username
    ,s.sid
    ,s.serial#
    ,s.status
    ,a.name
    ,s.lockwait
    ,s.schemaname
    ,s.osuser
    ,s.process
    ,s.machine
    ,s.terminal
    ,s.logon_time
    ,s.program
    ,s.sql_id
from
    gv$session s
    ,audit_actions a
where
    s.command = a.action
    and
    s.username not in ('SYS','SYSTEM')
    and
    s.type != 'BACKGROUND'
order by
    s.inst_id;
    
-- extract session datas including db events
set linesize 300
set pagesize 1000
set feedback off
alter session set nls_date_format='YYYY/MM/DD hh24:mi:ss';
set feedback on
col inst_id for 99
col sid for 999999
col serial# for 999999
col username for a15
col status for a10
col name for a15
col event for a30
col schemaname for a10
col osuser for a10
col process for a10
col machine for a20
col terminal for a8
col logon_time for a19
col program for a20
col sql_id for a20
 
select
    s.inst_id
    ,s.username
    ,s.sid
    ,s.serial#
    ,s.status
    ,a.name
    ,s.event
    ,s.schemaname
    ,s.osuser
    ,s.process
    ,substr(s.machine,0,20) machine
    ,s.terminal
    ,s.logon_time
    ,substr(s.program,0,20) program
    ,s.sql_id
from
    gv$session s
    ,audit_actions a
where
    s.command = a.action
    and
    s.username not in ('SYS','SYSTEM')
    and
    s.status = 'ACTIVE'
    and
    s.type != 'BACKGROUND'
order by
    s.inst_id;
    
-- extract session status with filtering as 'username' and 'action'
set linesize 300
set pagesize 1000
set feedback off
alter session set nls_date_format='YYYY/MM/DD hh24:mi:ss';
set feedback on
col inst_id for 99
col sid for 999999
col serial# for 999999
col username for a15
col status for a10
col action_name for a15
col lockwait for a16
col schemaname for a10
col osuser for a10
col process for a10
col machine for a40
col terminal for a8
col logon_time for a19
col program for a50
col sql_id for a20
 
select
    s.inst_id
    ,s.username
    ,s.sid
    ,s.serial#
    ,s.status
    ,a.name action_name
    ,s.lockwait
    ,s.schemaname
    ,s.osuser
    ,s.process
    ,s.machine
    ,s.terminal
    ,s.logon_time
    ,s.program
    ,s.sql_id
from
    gv$session s
    ,audit_actions a
where
    s.command = a.action
    and
    s.username not in ('SYS','SYSTEM')
    and
    s.type != 'BACKGROUND'
    and
    s.inst_id = &inst_id
    and
    s.username = upper('&username')
    and
    a.name =  upper('&action')
order by
    s.inst_id;
    
-- extract all locking sessions except sys,system and background process
set linesize 300
set pagesize 1000
set feedback off
alter session set nls_date_format='YYYY/MM/DD hh24:mi:ss';
set feedback on
col inst_id for 99
col sid for 999999
col serial# for 999999
col spid for a8
col username for a15
col status for a10
col name for a15
col lockwait for a16
col schemaname for a10
col osuser for a10
col process for a10
col machine for a40
col terminal for a8
col logon_time for a19
col program for a50
col sql_id for a20
 
select
    s.inst_id
    ,s.username
    ,s.sid
    ,s.serial#
    ,p.spid
    ,s.status
    ,a.name
    ,s.lockwait
    ,s.schemaname
    ,s.osuser
    ,s.process
    ,s.machine
    ,s.terminal
    ,s.logon_time
    ,s.program
    ,s.sql_id
from
    gv$session s
    ,audit_actions a
    ,gv$process p
where
    s.paddr = p.addr
    and
    s.command = a.action
    and
    s.username not in ('SYS','SYSTEM')
    and
    s.type != 'BACKGROUND'
    and
    s.lockwait is not null
order by
    inst_id;
