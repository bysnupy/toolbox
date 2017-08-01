-- check the efficiency of HOT update for TABLE
SELECT
relname,
n_tup_upd,
n_tup_hot_upd,
cast(n_tup_hot_upd AS numeric) / n_tup_upd AS hot_pct
FROM pg_stat_user_tables
WHERE n_tup_upd>0
ORDER BY hot_pct

-- check the DML counts of TABLE
SELECT
relname,
cast(n_tup_ins AS numeric) / (n_tup_ins + n_tup_upd + n_tup_del) AS ins_pct,
cast(n_tup_upd AS numeric) / (n_tup_ins + n_tup_upd + n_tup_del) AS upd_pct,
cast(n_tup_del AS numeric) / (n_tup_ins + n_tup_upd + n_tup_del) AS del_pct
FROM pg_stat_user_tables
WHERE (n_tup_ins + n_tup_upd + n_tup_del) > 0
ORDER BY relname

-- check cache hit ratio
SELECT
relname,
cast(heap_blks_hit as numeric) / (heap_blks_hit + heap_blks_read) AS hit_pct,heap_blks_hit,
heap_blks_read
FROM pg_statio_user_tables
WHERE (heap_blks_hit + heap_blks_read)>0
ORDER BY hit_pct;

-- check INDEX cache hit ratio
SELECT
relname,
cast(idx_blks_hit as numeric) / (idx_blks_hit + idx_blks_read) AS hit_pct,
idx_blks_hit,
idx_blks_read
FROM pg_statio_user_tables
WHERE (idx_blks_hit + idx_blks_read)>0
ORDER BY hit_pct;

-- check the read IO status including TOAST blocks
SELECT *,
(heap_blks_read + toast_blks_read + tidx_blks_read) AS total_blks_read,
(heap_blks_hit + toast_blks_hit + tidx_blks_hit) AS total_blks_hit
FROM pg_statio_user_tables;
