
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
SELECT query, calls, total_time, mean_time, rows
FROM pg_stat_statements
ORDER BY total_time DESC
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


-- PostgreSQL Deep Troubleshooting Queries

-- 1. High Planning Time Queries
SELECT query, calls, total_plan_time, mean_plan_time
FROM pg_stat_statements
ORDER BY total_plan_time DESC
LIMIT 10;

-- 2. Queries with Poor Cache Hit Ratio
SELECT query, calls,
       100 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0) AS hit_ratio
FROM pg_stat_statements
ORDER BY hit_ratio ASC
LIMIT 10;

-- 3. Queries Generating Most Temp Files
SELECT query, temp_blks_written
FROM pg_stat_statements
ORDER BY temp_blks_written DESC
LIMIT 10;

-- 4. Temp File Usage by Database
SELECT datname, temp_bytes, temp_files
FROM pg_stat_database
ORDER BY temp_bytes DESC;

-- 5. Checkpoint Statistics
SELECT * FROM pg_stat_bgwriter;

-- 6. WAL Generation by Database
SELECT datname, pg_size_pretty(blks_written * 8192) AS wal_written
FROM pg_stat_database
ORDER BY blks_written DESC;

-- 7. Tables with Large TOAST Data
SELECT t.oid::regclass AS table,
       pg_size_pretty(pg_total_relation_size(t.oid) - pg_relation_size(t.oid)) AS toast_size
FROM pg_class t
WHERE relkind = 'r'
ORDER BY pg_total_relation_size(t.oid) - pg_relation_size(t.oid) DESC
LIMIT 10;

-- 8. Tables Never Vacuumed or Analyzed
SELECT schemaname, relname, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze
FROM pg_stat_user_tables
WHERE last_vacuum IS NULL OR last_analyze IS NULL;

-- 9. Autovacuum Workers In Use vs Max
SELECT count(*) AS running_autovacuums,
       (SELECT setting FROM pg_settings WHERE name = 'autovacuum_max_workers')::int AS max_workers
FROM pg_stat_activity
WHERE query LIKE '%autovacuum%';

-- 10. Tables with Stale or Missing Stats
SELECT relname, n_live_tup, n_dead_tup, last_analyze, last_autoanalyze
FROM pg_stat_user_tables
WHERE last_analyze IS NULL OR last_autoanalyze IS NULL
ORDER BY n_dead_tup DESC;

-- 11. DDL Changes Blocking Queries
SELECT pid, query, wait_event_type, wait_event
FROM pg_stat_activity
WHERE query ~* '(alter|create|drop)' AND state != 'idle';

-- 12. WAL Size Generated Since Last Checkpoint (PG13+)
SELECT checkpoint_lsn, redo_lsn,
       pg_size_pretty(pg_wal_lsn_diff(checkpoint_lsn, redo_lsn)) AS wal_generated
FROM pg_control_checkpoint();
