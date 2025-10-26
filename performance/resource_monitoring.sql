/*
 * Script: resource_monitoring.sql
 * Purpose: Comprehensive PostgreSQL resource utilization monitoring
 * 
 * This script monitors CPU, memory, I/O, and other system resources
 * to help identify bottlenecks and resource constraints.
 * 
 * Requires: PostgreSQL 10+, appropriate monitoring privileges
 * Privileges: pg_monitor role or superuser
 * 
 * Usage: psql -f performance/resource_monitoring.sql
 * 
 * Author: pgtools
 * Version: 1.0
 * Date: 2024-10-25
 */

\echo '================================================='
\echo 'PostgreSQL Resource Utilization Monitoring'
\echo '================================================='
\echo ''

-- Database size and growth analysis
\echo '--- DATABASE SIZE ANALYSIS ---'
SELECT 
    datname as database_name,
    pg_size_pretty(pg_database_size(datname)) as size,
    pg_database_size(datname) as size_bytes,
    CASE 
        WHEN pg_database_size(datname) > 100 * 1024^3 THEN 'VERY_LARGE (>100GB)'
        WHEN pg_database_size(datname) > 10 * 1024^3 THEN 'LARGE (>10GB)'
        WHEN pg_database_size(datname) > 1024^3 THEN 'MEDIUM (>1GB)'
        ELSE 'SMALL (<1GB)'
    END as size_category
FROM pg_database
WHERE datistemplate = false
ORDER BY pg_database_size(datname) DESC;

\echo ''

-- Memory utilization analysis
\echo '--- MEMORY UTILIZATION ANALYSIS ---'
WITH memory_settings AS (
    SELECT 
        name,
        setting,
        unit,
        CASE 
            WHEN unit = 'kB' THEN setting::bigint * 1024
            WHEN unit = 'MB' THEN setting::bigint * 1024 * 1024
            WHEN unit = 'GB' THEN setting::bigint * 1024 * 1024 * 1024
            WHEN unit = '8kB' THEN setting::bigint * 8192
            ELSE setting::bigint
        END as bytes_value
    FROM pg_settings
    WHERE name IN (
        'shared_buffers', 
        'work_mem', 
        'maintenance_work_mem',
        'effective_cache_size',
        'wal_buffers',
        'max_connections'
    )
)
SELECT 
    name as parameter,
    setting as configured_value,
    unit,
    pg_size_pretty(bytes_value) as size_pretty,
    CASE name
        WHEN 'shared_buffers' THEN 'Shared buffer pool size'
        WHEN 'work_mem' THEN 'Memory per sort/hash operation'
        WHEN 'maintenance_work_mem' THEN 'Memory for maintenance operations'
        WHEN 'effective_cache_size' THEN 'Estimated OS cache size'
        WHEN 'wal_buffers' THEN 'WAL buffer size'
        WHEN 'max_connections' THEN 'Maximum concurrent connections'
    END as description
FROM memory_settings
ORDER BY bytes_value DESC NULLS LAST;

\echo ''

-- Buffer cache analysis
\echo '--- BUFFER CACHE ANALYSIS ---'
SELECT 
    CASE 
        WHEN category = 'buffer content' THEN category || ' (' || name || ')'
        ELSE category
    END as resource_type,
    buffers,
    pg_size_pretty(buffers * 8192) as size,
    ROUND(100.0 * buffers / (SELECT setting FROM pg_settings WHERE name = 'shared_buffers')::int, 2) as percent_of_shared_buffers
FROM pg_buffercache_summary()
ORDER BY buffers DESC;

\echo ''

-- Connection and process analysis
\echo '--- CONNECTION AND PROCESS ANALYSIS ---'
SELECT 
    'Total Connections' as metric,
    COUNT(*) as current_value,
    (SELECT setting FROM pg_settings WHERE name = 'max_connections') as max_configured,
    ROUND(100.0 * COUNT(*) / (SELECT setting FROM pg_settings WHERE name = 'max_connections')::int, 2) as percent_used
FROM pg_stat_activity
UNION ALL
SELECT 
    'Active Connections',
    COUNT(*),
    (SELECT setting FROM pg_settings WHERE name = 'max_connections'),
    ROUND(100.0 * COUNT(*) / (SELECT setting FROM pg_settings WHERE name = 'max_connections')::int, 2)
FROM pg_stat_activity WHERE state = 'active'
UNION ALL
SELECT 
    'Idle Connections',
    COUNT(*),
    (SELECT setting FROM pg_settings WHERE name = 'max_connections'),
    ROUND(100.0 * COUNT(*) / (SELECT setting FROM pg_settings WHERE name = 'max_connections')::int, 2)
FROM pg_stat_activity WHERE state = 'idle'
UNION ALL
SELECT 
    'Idle in Transaction',
    COUNT(*),
    (SELECT setting FROM pg_settings WHERE name = 'max_connections'),
    ROUND(100.0 * COUNT(*) / (SELECT setting FROM pg_settings WHERE name = 'max_connections')::int, 2)
FROM pg_stat_activity WHERE state = 'idle in transaction';

\echo ''

-- I/O statistics by database
\echo '--- I/O STATISTICS BY DATABASE ---'
SELECT 
    datname as database_name,
    blks_read as blocks_read_from_disk,
    blks_hit as blocks_read_from_cache,
    ROUND(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2) as cache_hit_ratio,
    tup_returned as tuples_returned,
    tup_fetched as tuples_fetched,
    tup_inserted as tuples_inserted,
    tup_updated as tuples_updated,
    tup_deleted as tuples_deleted,
    CASE 
        WHEN blks_hit + blks_read = 0 THEN 'NO_ACTIVITY'
        WHEN 100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0) > 95 THEN 'EXCELLENT'
        WHEN 100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0) > 90 THEN 'GOOD'
        WHEN 100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0) > 80 THEN 'FAIR'
        ELSE 'POOR'
    END as cache_performance
FROM pg_stat_database
WHERE datname IS NOT NULL
ORDER BY blks_read + blks_hit DESC;

\echo ''

-- Table I/O and size analysis
\echo '--- TOP TABLES BY I/O AND SIZE ---'
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    pg_total_relation_size(schemaname||'.'||tablename) as size_bytes,
    heap_blks_read,
    heap_blks_hit,
    ROUND(100.0 * heap_blks_hit / NULLIF(heap_blks_hit + heap_blks_read, 0), 2) as cache_hit_ratio,
    idx_blks_read,
    idx_blks_hit,
    ROUND(100.0 * idx_blks_hit / NULLIF(idx_blks_hit + idx_blks_read, 0), 2) as index_hit_ratio,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch
FROM pg_statio_user_tables 
WHERE heap_blks_read + heap_blks_hit > 0
ORDER BY heap_blks_read + heap_blks_hit + idx_blks_read + idx_blks_hit DESC
LIMIT 20;

\echo ''

-- Index utilization and efficiency
\echo '--- INDEX UTILIZATION ANALYSIS ---'
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(schemaname||'.'||indexname)) as index_size,
    idx_scan as times_used,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched,
    CASE 
        WHEN idx_scan = 0 THEN 'UNUSED'
        WHEN idx_scan < 10 THEN 'RARELY_USED'
        WHEN idx_scan < 100 THEN 'MODERATELY_USED'
        ELSE 'FREQUENTLY_USED'
    END as usage_category,
    CASE
        WHEN idx_scan = 0 THEN 'Consider dropping if confirmed unused'
        WHEN idx_scan < 10 AND pg_relation_size(schemaname||'.'||indexname) > 10*1024*1024 THEN 'Large rarely used index'
        ELSE 'Normal usage'
    END as recommendation
FROM pg_stat_user_indexes 
ORDER BY pg_relation_size(schemaname||'.'||indexname) DESC
LIMIT 25;

\echo ''

-- WAL and checkpoint statistics
\echo '--- WAL AND CHECKPOINT STATISTICS ---'
SELECT 
    'WAL Location' as metric,
    pg_current_wal_lsn() as current_value,
    'Current WAL write location' as description
UNION ALL
SELECT 
    'WAL Buffers',
    pg_size_pretty((SELECT setting FROM pg_settings WHERE name = 'wal_buffers')::bigint * 8192),
    'Configured WAL buffer size'
UNION ALL
SELECT 
    'Checkpoint Segments',
    (SELECT setting FROM pg_settings WHERE name = 'checkpoint_segments'),
    'WAL segments between checkpoints (if applicable)'
UNION ALL  
SELECT 
    'Max WAL Size',
    (SELECT setting FROM pg_settings WHERE name = 'max_wal_size'),
    'Maximum size to let WAL grow during automatic checkpoints';

\echo ''

-- Background writer and checkpointer stats
\echo '--- BACKGROUND WRITER STATISTICS ---'
SELECT 
    'Checkpoints Timed' as statistic,
    checkpoints_timed as value,
    'Scheduled checkpoints' as description
FROM pg_stat_bgwriter
UNION ALL
SELECT 
    'Checkpoints Requested',
    checkpoints_req,
    'Requested checkpoints (may indicate tuning needed)'
FROM pg_stat_bgwriter
UNION ALL
SELECT 
    'Checkpoint Write Time (ms)',
    checkpoint_write_time,
    'Time spent writing files during checkpoint'
FROM pg_stat_bgwriter
UNION ALL
SELECT 
    'Checkpoint Sync Time (ms)',
    checkpoint_sync_time,
    'Time spent syncing files during checkpoint'
FROM pg_stat_bgwriter
UNION ALL
SELECT 
    'Buffers Checkpoint',
    buffers_checkpoint,
    'Buffers written during checkpoints'
FROM pg_stat_bgwriter
UNION ALL
SELECT 
    'Buffers Clean',
    buffers_clean,
    'Buffers written by background writer'
FROM pg_stat_bgwriter
UNION ALL
SELECT 
    'Buffers Backend',
    buffers_backend,
    'Buffers written directly by backends'
FROM pg_stat_bgwriter;

\echo ''

-- Autovacuum and maintenance analysis
\echo '--- AUTOVACUUM AND MAINTENANCE ANALYSIS ---'
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_tuples,
    n_dead_tup as dead_tuples,
    ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) as dead_tuple_ratio,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    CASE 
        WHEN n_dead_tup > n_live_tup * 0.2 THEN 'VACUUM_NEEDED'
        WHEN n_dead_tup > n_live_tup * 0.1 THEN 'VACUUM_SOON'
        WHEN last_analyze < NOW() - INTERVAL '7 days' AND n_tup_ins + n_tup_upd + n_tup_del > 1000 THEN 'ANALYZE_NEEDED'
        ELSE 'OK'
    END as maintenance_status
FROM pg_stat_user_tables
WHERE n_live_tup + n_dead_tup > 0
ORDER BY dead_tuple_ratio DESC NULLS LAST
LIMIT 20;

\echo ''

-- Lock analysis and contention
\echo '--- LOCK ANALYSIS ---'
SELECT 
    mode as lock_mode,
    COUNT(*) as lock_count,
    COUNT(*) FILTER (WHERE granted = false) as waiting_locks,
    string_agg(DISTINCT locktype, ', ') as lock_types
FROM pg_locks
GROUP BY mode
ORDER BY lock_count DESC;

\echo ''

-- Resource usage recommendations
\echo '--- RESOURCE OPTIMIZATION RECOMMENDATIONS ---'
\echo ''

WITH resource_analysis AS (
    SELECT 
        (SELECT COUNT(*) FROM pg_stat_activity) as current_connections,
        (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') as max_connections,
        (SELECT SUM(blks_hit) FROM pg_stat_database) as total_cache_hits,
        (SELECT SUM(blks_read) FROM pg_stat_database) as total_disk_reads,
        (SELECT checkpoints_req FROM pg_stat_bgwriter) as checkpoint_requests,
        (SELECT checkpoints_timed FROM pg_stat_bgwriter) as checkpoint_timed
)
SELECT 
    CASE 
        WHEN current_connections > max_connections * 0.8 THEN 'HIGH CONNECTION USAGE: Consider connection pooling or increasing max_connections'
        WHEN current_connections > max_connections * 0.6 THEN 'MODERATE CONNECTION USAGE: Monitor connection patterns'
        ELSE 'CONNECTION USAGE: Normal'
    END as connection_analysis
FROM resource_analysis
UNION ALL
SELECT 
    CASE 
        WHEN total_cache_hits * 100.0 / NULLIF(total_cache_hits + total_disk_reads, 0) < 90 THEN 
            'LOW CACHE HIT RATIO (<90%): Consider increasing shared_buffers'
        WHEN total_cache_hits * 100.0 / NULLIF(total_cache_hits + total_disk_reads, 0) < 95 THEN 
            'MODERATE CACHE HIT RATIO (<95%): Monitor I/O patterns'
        ELSE 'CACHE HIT RATIO: Excellent (>95%)'
    END
FROM resource_analysis
UNION ALL
SELECT 
    CASE 
        WHEN checkpoint_requests > checkpoint_timed * 0.1 THEN 
            'FREQUENT CHECKPOINT REQUESTS: Consider increasing max_wal_size or checkpoint_completion_target'
        WHEN checkpoint_requests > 0 THEN 
            'OCCASIONAL CHECKPOINT REQUESTS: Monitor WAL generation'
        ELSE 'CHECKPOINT BEHAVIOR: Normal'
    END
FROM resource_analysis;

\echo ''
\echo '================================================='
\echo 'Resource Monitoring Complete'
\echo ''
\echo 'Key metrics to monitor regularly:'
\echo '1. Cache hit ratio (target >95%)'
\echo '2. Connection usage (target <80% of max_connections)'
\echo '3. Dead tuple ratio (vacuum when >10-20%)'
\echo '4. Checkpoint frequency (minimize forced checkpoints)'
\echo '5. Lock contention (minimize waiting locks)'
\echo '6. Index usage (identify unused indexes)'
\echo '================================================='