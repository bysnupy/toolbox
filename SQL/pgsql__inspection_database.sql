-- check the INDEX RANGE SCAN statistics
SELECT
indexrelname,
cast(idx_tup_read AS numeric) / idx_scan AS avg_tuples,
idx_scan,
idx_tup_read
FROM pg_stat_user_indexes
WHERE idx_scan > 0;

-- check the INDEX usage counts
SELECT
schemaname,
relname,
indexrelname,
idx_scan,
pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size
FROM
pg_stat_user_indexes i
JOIN pg_index USING (indexrelid)
WHERE
indisunique IS false
ORDER BY idx_scan,relname;

-- check the block IO statistics per Databases
SELECT
datname,
blks_read,
blks_hit,
tup_returned,
tup_fetched,
tup_inserted,
tup_updated,
tup_deleted
FROM pg_stat_database;

-- check the TRANSACTION statistics per Databases
SELECT
datname,
numbackends,
xact_commit,
xact_rollback
FROM pg_stat_database;

-- check the valid session counts
SELECT
count(*)
FROM pg_stat_activity
WHERE NOT procpid=pg_backend_pid();

-- check the long-term transactions
SELECT
pid,
waiting,
current_timestamp - least(query_start,xact_start) AS runtime,substr(query,1,25) AS query
FROM pg_stat_activity
WHERE NOT pid=pg_backend_pid();

-- check the locking states
SELECT
locktype,
virtualtransaction,
transactionid,
nspname,
relname,
mode,
granted,
cast(date_trunc('second',query_start) AS timestamp) AS query_start,
substr(query,1,25) AS query
FROM
pg_locks
LEFT OUTER JOIN pg_class ON (pg_locks.relation = pg_class.oid)
LEFT OUTER JOIN pg_namespace ON (pg_namespace.oid = pg_class.
relnamespace),
pg_stat_activity
WHERE
NOT pg_locks.pid=pg_backend_pid() AND
pg_locks.pid=pg_stat_activity.pid;

-- check the watings due to locking - pid and user level
SELECT
locked.pid AS locked_pid,
locker.pid AS locker_pid,
locked_act.usename AS locked_user,
locker_act.usename AS locker_user,
locked.virtualtransaction,
locked.transactionid,
locked.locktype
FROM
pg_locks locked,
pg_locks locker,
pg_stat_activity locked_act,
pg_stat_activity locker_act
WHERE
locker.granted=true AND
locked.granted=false AND
locked.pid=locked_act.pid AND
locker.pid=locker_act.pid AND
(locked.virtualtransaction=locker.virtualtransaction OR
locked.transactionid=locker.transactionid);

-- check the waitings due to locking - table level
SELECT
locked.pid AS locked_pid,
locker.pid AS locker_pid,
locked_act.usename AS locked_user,
locker_act.usename AS locker_user,
locked.virtualtransaction,
locked.transactionid,
relname
FROM
pg_locks locked
LEFT OUTER JOIN pg_class ON (locked.relation = pg_class.oid),
pg_locks locker,
pg_stat_activity locked_act,
pg_stat_activity locker_act
WHERE
locker.granted=true AND
locked.granted=false AND
locked.pid=locked_act.pid AND
locker.pid=locker_act.pid AND
locked.relation=locker.relation;

-- calculating the table and index sizes
SELECT
nspname,
relname,
relkind as "type",
pg_size_pretty(pg_table_size(C.oid)) AS size,
pg_size_pretty(pg_indexes_size(C.oid)) AS idxsize,
pg_size_pretty(pg_total_relation_size(C.oid)) as "total"
FROM pg_class C
LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
WHERE nspname NOT IN ('pg_catalog', 'information_schema') AND
nspname !~ '^pg_toast' AND
relkind IN ('r','i')
ORDER BY pg_total_relation_size(C.oid) DESC;

-- check the backend IO statistics
SELECT
(100 * checkpoints_req) / (checkpoints_timed + checkpoints_req) AS checkpoints_req_pct,
pg_size_pretty(buffers_checkpoint * block_size / (checkpoints_timed + checkpoints_req)) AS avg_checkpoint_write,
pg_size_pretty(block_size * (buffers_checkpoint + buffers_clean + buffers_backend)) AS total_written,
100 * buffers_checkpoint / (buffers_checkpoint + buffers_clean + buffers_backend) AS checkpoint_write_pct,
100 * buffers_backend / (buffers_checkpoint + buffers_clean + buffers_backend) AS backend_write_pct,
*
FROM pg_stat_bgwriter,(SELECT cast(current_setting('block_size') AS
integer) AS block_size) AS bs;

-- check the table size to bloat for decision of FULL VACUUM
SELECT * 
FROM 
(SELECT 
pg_namespace.nspname, 
pg_class.relname, 
pg_class.reltuples, 
pg_class.relpages, 
rowwidths.avgwidth, 
ceil(pg_class.reltuples * rowwidths.avgwidth::double precision / current_setting('block_size'::text)::double precision) AS expectedpages, 
pg_class.relpages::double precision / ceil(pg_class.reltuples * 
rowwidths.avgwidth::double precision / current_setting('block_size'::text)::double precision) AS bloat, 
ceil((pg_class.relpages::double precision * current_setting('block_size'::text)::double precision - ceil(pg_class.reltuples * rowwidths.avgwidth::double precision)) / 1024::double precision) AS kb_wastedspace
FROM 
 (SELECT 
  pg_statistic.starelid, 
  sum(pg_statistic.stawidth) AS avgwidth
  FROM pg_statistic
  GROUP BY pg_statistic.starelid) rowwidths
JOIN pg_class ON rowwidths.starelid = pg_class.oid
JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
WHERE pg_class.relpages > 1 ) relbloat 
ORDER BY kb_wastedspace desc;

-- check the INDEX size to bloat - verbose version
SELECT
schemaname, tablename, reltuples::bigint, relpages::bigint, otta,
ROUND(CASE WHEN otta=0 THEN 0.0 ELSE sml.relpages/otta::numeric END,1) AS tbloat,
relpages::bigint - otta AS wastedpages,
bs*(sml.relpages-otta)::bigint AS wastedbytes,
pg_size_pretty((bs*(relpages-otta))::bigint) AS wastedsize,
iname, ituples::bigint, ipages::bigint, iotta,
ROUND(CASE WHEN iotta=0 OR ipages=0 THEN 0.0 ELSE ipages/iotta::numeric END,1) AS ibloat,
      CASE WHEN ipages < iotta THEN 0 ELSE ipages::bigint - iotta END AS wastedipages,
      CASE WHEN ipages < iotta THEN 0 ELSE bs*(ipages-iotta) END AS wastedibytes,
      CASE WHEN ipages < iotta THEN pg_size_pretty(0::bigint) ELSE pg_size_pretty((bs*(ipages-iotta))::bigint) END AS wastedisize
FROM (
       SELECT
       schemaname, tablename, cc.reltuples, cc.relpages, bs,
       CEIL((cc.reltuples*((datahdr+ma-(CASE WHEN datahdr%ma=0 THEN ma ELSE datahdr%ma END))+nullhdr2+4))/(bs-20::float)) AS otta,
             COALESCE(c2.relname,'?') AS iname, COALESCE(c2.reltuples,0) AS ituples, COALESCE(c2.relpages,0) AS ipages,
             COALESCE(CEIL((c2.reltuples*(datahdr-12))/(bs-20::float)),0) AS iotta -- very rough approximation, assumes all cols
       FROM (
              SELECT
              ma,bs,schemaname,tablename,
              (datawidth+(hdr+ma-(case when hdr%ma=0 THEN ma ELSE hdr%ma END)))::numeric AS datahdr,
              (maxfracsum*(nullhdr+ma-(case when nullhdr%ma=0 THEN ma ELSE nullhdr%ma END))) AS nullhdr2
              FROM (
                     SELECT
                     schemaname, tablename, hdr, ma, bs,
                     SUM((1-null_frac)*avg_width) AS datawidth,
                     MAX(null_frac) AS maxfracsum,
                     hdr+(
                           SELECT 1+count(*)/8
                           FROM pg_stats s2
                           WHERE null_frac<>0 AND s2.schemaname = s.schemaname AND s2.tablename = s.tablename
                          ) AS nullhdr
                    FROM pg_stats s, (
                                       SELECT
                                       (SELECT current_setting('block_size')::numeric) AS bs,
                                       CASE WHEN substring(v,12,3) IN ('8.0','8.1','8.2') THEN 27 ELSE 23 END AS hdr,
                                       CASE WHEN v ~ 'mingw32' THEN 8 ELSE 4 END AS ma
                                       FROM (SELECT version() AS v) AS foo
                                     ) AS constants
                    GROUP BY 1,2,3,4,5
              ) AS foo
       ) AS rs
       JOIN pg_class cc ON cc.relname = rs.tablename
       JOIN pg_namespace nn ON cc.relnamespace = nn.oid AND nn.nspname = rs.schemaname
       LEFT JOIN pg_index i ON indrelid = cc.oid
       LEFT JOIN pg_class c2 ON c2.oid = i.indexrelid
) AS sml
WHERE sml.relpages - otta > 0 OR ipages - iotta > 10
ORDER BY wastedbytes DESC, wastedibytes DESC;



