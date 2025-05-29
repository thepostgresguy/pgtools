
-- PostgreSQL Troubleshooting Queries

-- 1. Current connections per database
SELECT datname, COUNT(*) AS connections
FROM pg_stat_activity
GROUP BY datname
ORDER BY connections DESC;

-- 2. Check remaining connections vs limit
SELECT max_conn, used_conn, max_conn - used_conn AS available
FROM (
  SELECT COUNT(*) AS used_conn FROM pg_stat_activity
) AS used,
(SELECT setting::int AS max_conn FROM pg_settings WHERE name = 'max_connections') AS max;

-- 3. Long-running queries
SELECT pid, now() - pg_stat_activity.query_start AS runtime,
       usename, datname, state, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY runtime DESC;

-- 4. Blocking queries
SELECT blocked.pid AS blocked_pid,
       blocked.query AS blocked_query,
       blocking.pid AS blocking_pid,
       blocking.query AS blocking_query
FROM pg_locks blocked_locks
JOIN pg_stat_activity blocked ON blocked_locks.pid = blocked.pid
JOIN pg_locks blocking_locks ON blocked_locks.locktype = blocking_locks.locktype
     AND blocked_locks.database IS NOT DISTINCT FROM blocking_locks.database
     AND blocked_locks.relation IS NOT DISTINCT FROM blocking_locks.relation
     AND blocked_locks.page IS NOT DISTINCT FROM blocking_locks.page
     AND blocked_locks.tuple IS NOT DISTINCT FROM blocking_locks.tuple
     AND blocked_locks.pid != blocking_locks.pid
JOIN pg_stat_activity blocking ON blocking_locks.pid = blocking.pid
WHERE NOT blocked_locks.granted;

-- 5. Dead tuples and autovacuum status
SELECT relname AS table_name,
       n_dead_tup,
       n_live_tup,
       last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;

-- 6. Largest tables
SELECT relname AS table_name,
       pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;

-- 7. Largest indexes
SELECT relname AS index_name,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
       idx_scan AS scans
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC
LIMIT 10;

-- 8. Unused indexes
SELECT schemaname, relname AS table_name, indexrelname AS index_name, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- 9. High I/O queries
SELECT query, shared_blks_read, local_blks_read, temp_blks_read
FROM pg_stat_statements
ORDER BY shared_blks_read DESC
LIMIT 10;

-- 10. High CPU queries
SELECT query, total_exec_time, calls, mean_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- 11. Autovacuum in progress
SELECT pid, relname, phase, wait_event_type, wait_event, query
FROM pg_stat_progress_vacuum
JOIN pg_class ON pg_stat_progress_vacuum.relid = pg_class.oid;

-- 12. Current locks
SELECT pid, mode, granted, relation::regclass, query
FROM pg_locks
JOIN pg_stat_activity USING (pid)
WHERE relation IS NOT NULL;

-- 13. Frequent deadlocks
SELECT relname, deadlocks
FROM pg_stat_user_tables
WHERE deadlocks > 0
ORDER BY deadlocks DESC;

-- 14. Duplicate indexes
SELECT indrelid::regclass AS table,
       array_agg(indexrelid::regclass) AS dup_indexes
FROM pg_index
GROUP BY indrelid, indkey
HAVING COUNT(*) > 1;

-- 15. Replication status
SELECT pid, state, client_addr, sync_state, write_lag, flush_lag, replay_lag
FROM pg_stat_replication;

-- 16. Replication slots
SELECT slot_name, database, active, restart_lsn, confirmed_flush_lsn
FROM pg_replication_slots;

-- 17. Buffer cache hit ratio
SELECT sum(blks_hit) / (sum(blks_hit) + sum(blks_read)) AS hit_ratio
FROM pg_stat_database;

-- 18. Non-default settings
SELECT name, setting, unit, source
FROM pg_settings
WHERE source NOT IN ('default', 'override');

-- 19. Autovacuum settings
SELECT name, setting
FROM pg_settings
WHERE name ILIKE 'autovacuum%';

-- 20. XID wraparound risk
SELECT datname, age(datfrozenxid) AS xid_age, pg_size_pretty(pg_database_size(datname)) AS db_size
FROM pg_database
ORDER BY age(datfrozenxid) DESC;
