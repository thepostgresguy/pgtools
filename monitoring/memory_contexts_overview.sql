/*
 * Script: memory_contexts_overview.sql
 * Purpose: Provide a high-level view of backend memory context usage
 *
 * Usage:
 *   psql -d database_name -f monitoring/memory_contexts_overview.sql
 *
 * Requirements:
 *   - PostgreSQL 15+
 *   - Privileges: pg_monitor role or sufficient permissions
 *
 * Output:
 *   - Top memory-consuming backends
 *   - Top memory context families across backends
 *   - Backends with high memory utilization
 *
 * Notes:
 *   - The view pg_backend_memory_contexts shows per-backend memory usage
 *   - Use this to identify memory-heavy backends before deeper inspection
 */

-- Top memory-consuming backends
WITH backend_memory AS (
    SELECT
        pid,
        sum(total_bytes) AS total_bytes,
        sum(used_bytes) AS used_bytes,
        sum(free_bytes) AS free_bytes
    FROM pg_backend_memory_contexts
    GROUP BY pid
)
SELECT
    bm.pid,
    sa.backend_type,
    sa.usename,
    sa.application_name,
    sa.client_addr,
    sa.state,
    pg_size_pretty(bm.total_bytes) AS total_memory,
    pg_size_pretty(bm.used_bytes) AS used_memory,
    pg_size_pretty(bm.free_bytes) AS free_memory,
    ROUND(100.0 * bm.used_bytes / NULLIF(bm.total_bytes, 0), 2) AS used_percent,
    LEFT(sa.query, 100) AS query_snippet
FROM backend_memory bm
LEFT JOIN pg_stat_activity sa ON sa.pid = bm.pid
ORDER BY bm.total_bytes DESC
LIMIT 30;

-- Top memory context families (aggregated across backends)
SELECT
    name,
    COALESCE(ident, '') AS ident,
    pg_size_pretty(sum(total_bytes)) AS total_memory,
    pg_size_pretty(sum(used_bytes)) AS used_memory,
    pg_size_pretty(sum(free_bytes)) AS free_memory,
    COUNT(*) AS context_count
FROM pg_backend_memory_contexts
GROUP BY name, ident
ORDER BY sum(total_bytes) DESC
LIMIT 30;

-- Backends with high memory utilization (used vs total)
WITH backend_memory AS (
    SELECT
        pid,
        sum(total_bytes) AS total_bytes,
        sum(used_bytes) AS used_bytes
    FROM pg_backend_memory_contexts
    GROUP BY pid
)
SELECT
    bm.pid,
    sa.backend_type,
    sa.usename,
    sa.application_name,
    pg_size_pretty(bm.total_bytes) AS total_memory,
    ROUND(100.0 * bm.used_bytes / NULLIF(bm.total_bytes, 0), 2) AS used_percent,
    CASE
        WHEN bm.used_bytes / NULLIF(bm.total_bytes, 0) > 0.9 THEN 'CRITICAL: >90% used'
        WHEN bm.used_bytes / NULLIF(bm.total_bytes, 0) > 0.75 THEN 'WARNING: >75% used'
        ELSE 'OK'
    END AS utilization_status
FROM backend_memory bm
LEFT JOIN pg_stat_activity sa ON sa.pid = bm.pid
ORDER BY bm.used_bytes DESC
LIMIT 30;
