-- extract the all tablespaces usage including temporary tablespaces
set feedback off
set embedded on
col HIGH_VALUE for a30
set line 200
set pages 10000
col size(MB) for a12
col used(MB) for a12
col free(MB) for a12
col TABLESPACE_NAME for a30
SELECT
  tablespace_name,
        TO_CHAR(nvl(total_bytes/1024/1024,0),'999,999,999') as "size(MB)",
        TO_CHAR(nvl((total_bytes - free_total_bytes)/1024/1024,total_bytes/1024/1024),'999,999,999') as "used(MB)",
        TO_CHAR(nvl(free_total_bytes/1024/1024,0),'999,999,999') as "free(MB)",
        TO_CHAR(nvl(max_size/1024/1024,0),'999,999,999') as "max(MB)",
        round(nvl((total_bytes-NVL(free_total_bytes,0))/max_size*100,100),2) as "rate(%)"
FROM   (SELECT
  tablespace_name,
  sum(user_bytes) total_bytes,
  sum(maxbytes) as max_size
 FROM
  (SELECT
   tablespace_name,
   user_bytes,
   DECODE( maxbytes,0,user_bytes,maxbytes ) maxbytes
         FROM
   (select FILE_NAME,
   FILE_ID,
   TABLESPACE_NAME,
   BYTES,
   BLOCKS,
   STATUS,
   RELATIVE_FNO,
   AUTOEXTENSIBLE,
   MAXBYTES,
   MAXBLOCKS,
   INCREMENT_BY,
   USER_BYTES,
   USER_BLOCKS
   from dba_data_files
   union
   select * from dba_temp_files)
  )
  GROUP BY
   tablespace_name
 ),
 (SELECT
  tablespace_name free_tablespace_name, sum(bytes) free_total_bytes
  FROM dba_free_space
  GROUP BY tablespace_name)
WHERE
 tablespace_name = free_tablespace_name(+);
set feedback on
set embedded off 

-- extract all temporary tablespace usage
SELECT tablespace_name,
       tablespace_size/1024/1024 "TABLESPACE_SIZE(MB)",
       allocated_space/1024/1024 "ALLOCATED_SPACE(MB)",
       free_space/1024/1024 "FREE_SPACE(MB)"
FROM dba_temp_free_space;
