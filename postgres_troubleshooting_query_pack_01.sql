
-- PostgreSQL Troubleshooting Query Pack

-- 1. Long-Running Queries
SELECT pid, now() - query_start AS duration, state, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;

-- 2. Blocking & Blocked Queries
SELECT blocked_locks.pid AS blocked_pid,
       blocking_locks.pid AS blocking_pid,
       blocked.query AS blocked_query,
       blocking.query AS blocking_query
FROM pg_locks blocked_locks
JOIN pg_stat_activity blocked ON blocked.pid = blocked_locks.pid
JOIN pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.pid != blocked_locks.pid
JOIN pg_stat_activity blocking ON blocking.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- 3. Current Wait Events
SELECT pid, wait_event_type, wait_event, state, query
FROM pg_stat_activity
WHERE wait_event IS NOT NULL;

-- 4. Autovacuum & Dead Tuples
SELECT relname, n_dead_tup, last_autovacuum, last_vacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;

-- 5. Largest Tables
SELECT relname AS table, pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;

-- 6. Largest Indexes
SELECT relname AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC
LIMIT 10;

-- 7. Unused Indexes
SELECT schemaname, relname AS table, indexrelname AS index, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;

-- 8. Top Slow Queries (requires pg_stat_statements)
SELECT query, calls, total_exec_time, mean_exec_time, rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- 9. Transaction ID Wraparound Risk
SELECT datname, age(datfrozenxid) AS xid_age,
       pg_size_pretty(pg_database_size(datname)) AS db_size
FROM pg_database
ORDER BY age(datfrozenxid) DESC;

-- 10. Replication Status
SELECT pid, client_addr, state, sync_state, write_lag, flush_lag, replay_lag
FROM pg_stat_replication;

-- 11. Non-default Configuration Settings
SELECT name, setting, unit, source
FROM pg_settings
WHERE source != 'default';

-- 12. Active Connections Summary
SELECT datname, usename, client_addr, state, COUNT(*) AS conn_count
FROM pg_stat_activity
GROUP BY datname, usename, client_addr, state
ORDER BY conn_count DESC;

-- 13. HOT Updates
SELECT relname,
       n_tup_upd,
       n_tup_hot_upd,
       ROUND(100.0 * n_tup_hot_upd / NULLIF(n_tup_upd, 0), 2) AS hot_update_ratio
FROM pg_stat_user_tables
ORDER BY hot_update_ratio DESC;
