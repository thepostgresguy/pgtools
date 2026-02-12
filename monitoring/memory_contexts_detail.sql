/*
 * Script: memory_contexts_detail.sql
 * Purpose: Drill into top memory contexts per backend and identify fragmentation
 *
 * Usage:
 *   psql -d database_name -f monitoring/memory_contexts_detail.sql
 *
 * Requirements:
 *   - PostgreSQL 15+
 *   - Privileges: pg_monitor role or sufficient permissions
 *
 * Output:
 *   - Top memory contexts per backend
 *   - Contexts with high free space (potential fragmentation)
 *
 * Notes:
 *   - Focuses on the largest contexts per backend to speed triage
 *   - High free_bytes inside a context can indicate fragmentation
 */

-- Top 5 memory contexts per backend
WITH ranked_contexts AS (
    SELECT
        pid,
        name,
        COALESCE(ident, '') AS ident,
        total_bytes,
        used_bytes,
        free_bytes,
        sum(total_bytes) OVER (PARTITION BY pid) AS backend_total_bytes,
        row_number() OVER (PARTITION BY pid ORDER BY total_bytes DESC) AS rn
    FROM pg_backend_memory_contexts
)
SELECT
    pid,
    name,
    ident,
    pg_size_pretty(total_bytes) AS total_memory,
    pg_size_pretty(used_bytes) AS used_memory,
    pg_size_pretty(free_bytes) AS free_memory,
    ROUND(100.0 * total_bytes / NULLIF(backend_total_bytes, 0), 2) AS backend_percent
FROM ranked_contexts
WHERE rn <= 5
ORDER BY backend_percent DESC, total_bytes DESC;

-- Contexts with high free space (potential fragmentation)
SELECT
    pid,
    name,
    COALESCE(ident, '') AS ident,
    pg_size_pretty(total_bytes) AS total_memory,
    pg_size_pretty(used_bytes) AS used_memory,
    pg_size_pretty(free_bytes) AS free_memory,
    ROUND(100.0 * free_bytes / NULLIF(total_bytes, 0), 2) AS free_percent
FROM pg_backend_memory_contexts
WHERE total_bytes > 0
    AND free_bytes > 67108864
ORDER BY free_bytes DESC
LIMIT 30;
