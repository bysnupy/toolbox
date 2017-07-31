-- extract lock status about TM(DML), TX(Transaction) and UL - User types locks
set linesize 300
set pagesize 1000
set feedback off
alter session set nls_date_format='YYYY/MM/DD hh24:mi:ss';
set feedback on
col username for a15
col inst_id for 99
col sid for 999999
col serial# for 999999
col sid for 999999
col serial# for 999999
col status for a10
col name for a15
col LTYPE for a5
col HELD for a5
col REQED for a5
col logon_time for a19
col lock_time(sec) for 9999999.9
col machine for a40
col osuser for a10
col process for a10
col program for a50
col sql_id for a20
select
    distinct
    s.inst_id
    ,s.username
    ,s.sid
    ,s.serial#
    ,s.status
    ,a.name
    ,l.type "ltype"
    ,decode (
        l.lmode
        ,0
        ,'NONE'
        ,1
        ,'NULL'
        ,2
        ,'  RS'
        ,3
        ,'  RX'
        ,4
        ,'   S'
        ,5
        ,' SRX'
        ,6
        ,'   X'
        ,'   ?'
    ) held
    ,decode (
        l.request
        ,0
        ,'NONE'
        ,1
        ,'NULL'
        ,2
        ,'  RS'
        ,3
        ,'  RX'
        ,4
        ,'   S'
        ,5
        ,' SRX'
        ,6
        ,'   X'
        ,'   ?'
    ) reqed
    ,s.logon_time
    ,l.ctime "lock_time(sec)"
    ,s.machine
    ,s.osuser
    ,s.process
    ,s.program
    ,s.lockwait
    ,s.sql_id
from
    gv$session s
    ,gv$lock l
    ,audit_actions a
where
    s.inst_id = l.inst_id
    and s.command = a.action
    and s.sid = l.sid
    and s.username not in ('SYS','SYSTEM')
    and s.type != 'BACKGROUND'
    and l.type in ('TM','TX','UL')
order by
    s.inst_id
    ,s.logon_time;
    
    
-- extract locking target objects
set linesize 200
set pagesize 1000
col inst_id for 99
col sid for 999999
col serial# for 999999
col lmode for a5
col owner for a10
col object_name for a30
select
 distinct
 s.inst_id,
 s.sid,
 s.serial#,
 decode (
     lo.locked_mode
     ,0
     ,'NONE'
     ,1
     ,'NULL'
     ,2
     ,'  RS'
     ,3
     ,'  RX'
     ,4
     ,'   S'
     ,5
     ,' SRX'
     ,6
     ,'   X'
     ,'   ?'
 ) lmode,
 do.owner,
 do.object_name
from
 gv$locked_object lo,
 dba_objects do,
 gv$session s
where
 lo.inst_id = s.inst_id
 and
 s.sid = lo.session_id
 and
 lo.object_id = do.object_id
 and
 s.username not in ('SYS','SYSTEM')
 and
 s.type != 'BACKGROUND'
 and
 s.lockwait is not null
order by
 s.inst_id;
