-- 1. Lower Fillfactor on Frequently Updated Tables
---------------------------------------------------
ALTER TABLE your_table SET (fillfactor = 70);
-- Reclaim space:
VACUUM FULL your_table;

-- 2. Avoid Indexing Frequently Updated Columns
-----------------------------------------------
-- Review indexes on your table:
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'your_table';

-- Drop unused or unnecessary indexes:
DROP INDEX IF EXISTS your_index_name;

-- 3. Check HOT Update Ratio
-----------------------------
SELECT relname,
       n_tup_upd,
       n_tup_hot_upd,
       ROUND(100.0 * n_tup_hot_upd / NULLIF(n_tup_upd, 0), 2) AS hot_update_ratio
FROM pg_stat_user_tables
ORDER BY hot_update_ratio DESC;

-- 4. Monitor Index Usage
--------------------------
SELECT relname AS table,
       indexrelname AS index,
       idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
JOIN pg_index USING (indexrelid)
ORDER BY idx_scan DESC;

-- 5. Tune Autovacuum
----------------------
-- Monitor autovacuum effectiveness:
SELECT relname, last_autovacuum, n_dead_tup
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

-- Adjust autovacuum settings in postgresql.conf if needed:
# autovacuum_vacuum_scale_factor = 0.05
# autovacuum_vacuum_threshold = 50
# autovacuum_naptime = 10s
