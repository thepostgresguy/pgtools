/*
 * Script: hot_update_optimization_checklist.sql
 * Purpose: Identify tables with poor HOT (Heap-Only Tuple) update efficiency
 * 
 * Usage:
 *   psql -d database_name -f optimization/hot_update_optimization_checklist.sql
 *
 * Requirements:
 *   - PostgreSQL 15+
 *   - Privileges: pg_monitor role or pg_stat_all_tables access
 *
 * Output:
 *   - Table name
 *   - Total updates
 *   - HOT updates
 *   - HOT update percentage
 *   - Non-HOT update count
 *
 * Notes:
 *   - HOT updates are faster and create less bloat
 *   - Low HOT% (<50%) indicates optimization opportunities
 *   - Common fixes:
 *     * Remove unnecessary indexes on frequently updated columns
 *     * Adjust fillfactor (default 100, try 90 or 80)
 *     * Ensure proper VACUUM frequency
 *   - HOT updates only work when indexed columns are not modified
 *   - Use: ALTER TABLE table_name SET (fillfactor = 90);
 */

SELECT 
    schemaname || '.' || relname AS table_name,
    n_tup_upd AS total_updates,
    n_tup_hot_upd AS hot_updates,
    n_live_tup AS live_tuples,
    n_dead_tup AS dead_tuples,
    CASE 
        WHEN n_tup_upd > 0 THEN 
            ROUND(100.0 * n_tup_hot_upd / n_tup_upd, 2)
        ELSE 0 
    END AS hot_update_percent,
    n_tup_upd - n_tup_hot_upd AS non_hot_updates,
    pg_size_pretty(pg_relation_size(schemaname||'.'||relname)) AS table_size,
    seq_scan + idx_scan AS total_scans
FROM pg_stat_user_tables
WHERE n_tup_upd > 100  -- Only tables with significant updates
ORDER BY 
    CASE WHEN n_tup_upd > 0 THEN n_tup_hot_upd::float / n_tup_upd ELSE 1 END ASC,
    n_tup_upd DESC
LIMIT 50;

-- Suggested fillfactor settings for low HOT update tables
\echo '\nTables that might benefit from fillfactor adjustment (HOT% < 50%):\n'

SELECT 
    schemaname || '.' || relname AS table_name,
    ROUND(100.0 * n_tup_hot_upd / NULLIF(n_tup_upd, 0), 2) AS hot_update_percent,
    'ALTER TABLE ' || schemaname || '.' || relname || ' SET (fillfactor = 90);' AS suggested_command
FROM pg_stat_user_tables
WHERE n_tup_upd > 100
    AND n_tup_hot_upd::float / NULLIF(n_tup_upd, 0) < 0.5
ORDER BY n_tup_upd DESC
LIMIT 20;