
/*
 * Script: bloating.sql
 * Purpose: Detect table and index bloat to identify candidates for VACUUM/REINDEX
 * 
 * Usage:
 *   psql -d database_name -f monitoring/bloating.sql
 *
 * Requirements:
 *   - PostgreSQL 9.0+
 *   - Privileges: pg_monitor role or pg_stat_all_tables access
 *
 * Output:
 *   - Table/Index name
 *   - Dead tuples count
 *   - Live tuples count
 *   - Bloat percentage
 *   - Wasted space
 *
 * Notes:
 *   - Run regularly to maintain database health
 *   - High bloat (>20%) indicates VACUUM needed
 *   - Very high bloat (>50%) may need VACUUM FULL or REINDEX
 *   - May be resource-intensive on very large databases
 *   - Consider running during low-traffic periods
 */

-- Table bloat estimation
SELECT
    schemaname || '.' || tablename AS table_name,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    n_dead_tup AS dead_tuples,
    n_live_tup AS live_tuples,
    ROUND(n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_tuple_percent,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC
LIMIT 50;