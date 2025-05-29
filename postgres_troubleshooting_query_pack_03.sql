
-- PostgreSQL Troubleshooting Query Pack

-- 1. Disk Usage by Tables and Index
SELECT
  schemaname,
  relname AS table_name,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
  pg_size_pretty(pg_relation_size(relid)) AS table_size,
  pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS index_and_toast_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;

-- 2. WAL Activity Overview
SELECT
  datname,
  pg_size_pretty(sum(pg_xlog_location_diff(pg_current_xlog_insert_location(), replay_location))) AS wal_lag
FROM pg_stat_replication
GROUP BY datname;


-- 3.Replication Slots and Their Status
SELECT slot_name, plugin, slot_type, active, restart_lsn, confirmed_flush_lsn
FROM pg_replication_slots;


-- 4. Check for Bloat Estimation on Tables
WITH bloat_info AS (
  SELECT
    schemaname,
    tablename,
    pg_relation_size(schemaname || '.' || tablename) AS table_size,
    pg_total_relation_size(schemaname || '.' || tablename) AS total_size
  FROM pg_tables
  WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
)
SELECT schemaname, tablename,
       pg_size_pretty(table_size) AS table_size,
       pg_size_pretty(total_size) AS total_size,
       pg_size_pretty(total_size - table_size) AS bloat_estimate
FROM bloat_info
ORDER BY total_size - table_size DESC
LIMIT 10;


-- 5. Check for Disk Full or Near Full Tablespaces
SELECT spcname,
       pg_size_pretty(pg_tablespace_size(spcname)) AS size,
       pg_tablespace_location(oid) AS location
FROM pg_tablespace
ORDER BY pg_tablespace_size(spcname) DESC;


-- 6. PostgreSQL Configuration Parameters
SELECT name, setting, unit, category, short_desc
FROM pg_settings
ORDER BY category, name;


-- 7. Check for Deadlocks in the Logs
SELECT *
FROM pg_catalog.pg_stat_activity
WHERE query ~* 'deadlock';


-- 8. Check Connection Saturation
SELECT COUNT(*) AS total_connections,
       MAX(setting::int) AS max_connections
FROM pg_stat_activity, pg_settings
WHERE name = 'max_connections';


-- 9. Check for Locks Held Too Long
SELECT pid, mode, relation::regclass, granted, age(clock_timestamp(), query_start) AS duration, query
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE granted
  AND age(clock_timestamp(), query_start) > interval '5 minutes'
ORDER BY duration DESC;
