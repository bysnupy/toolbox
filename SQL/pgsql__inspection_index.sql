-- check the INDEX to bloat
SELECT
nspname,relname,
round(100 * pg_relation_size(indexrelid) / pg_relation_size(indrelid)) / 100 AS index_ratio,
pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
pg_size_pretty(pg_relation_size(indrelid)) AS table_size
FROM pg_index I
LEFT JOIN pg_class C ON (C.oid = I.indexrelid)
LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)
WHERE
nspname NOT IN ('pg_catalog', 'information_schema', 'pg_toast') AND C.relkind='i' AND pg_relation_size(indrelid) > 0;

-- check the INDEX SCAN ration
SELECT
schemaname,
relname,
seq_scan,
idx_scan,
cast(idx_scan AS numeric) / (idx_scan + seq_scan) AS idx_scan_pct
FROM pg_stat_user_tables
WHERE (idx_scan + seq_scan) > 0 
ORDER BY idx_scan_pct

-- check the tuples per INDEX SCAN
SELECT
relname,
seq_tup_read,
idx_tup_fetch,
cast(idx_tup_fetch AS numeric) / (idx_tup_fetch + seq_tup_read) AS idx_tup_pct
FROM pg_stat_user_tables
WHERE (idx_tup_fetch + seq_tup_read) > 0
ORDER BY idx_tup_pct
