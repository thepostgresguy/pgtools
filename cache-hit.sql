/*
 * Script: sql/diagnostics/cache-hit.sql
 *
 * Purpose: Calculates and displays table and index cache hit rates.
 *
 * Description:
 * This query provides a crucial performance metric: the percentage of blocks
 * read from the PostgreSQL buffer cache versus from disk. High cache hit
 * rates (typically > 90-95%) indicate efficient memory usage and reduced
 * reliance on slower disk I/O.
 *
 * Red Flags:
 * - `hit_rate_pct` consistently below 90-95% on a busy table or index:
 *   Indicates significant I/O pressure, potentially due to insufficient
 *   `shared_buffers`, inefficient queries, or missing/bad indexes.
 * - `total_reads` is very high for an object with a low hit rate:
 *   This object is frequently accessed but rarely found in cache.
 *
 * Interpretation:
 * - `object_type`: TABLE (heap blocks) or INDEX (index blocks).
 * - `table_name`: The table the object belongs to (the index's table for INDEX rows).
 * - `hit_rate_pct`: Percentage of blocks found in shared_buffers.
 * - `total_reads`: Total number of blocks requested (cache hits + reads).
 * - `total_hits`: Number of blocks found in shared_buffers.
 *
 * Note: a "read" here means the block was not in shared_buffers. It may still
 * have come from the OS page cache, so a low hit rate is not always disk I/O.
 *
 * Safety:
 * This script is read-only. It queries `pg_statio_all_tables` and
 * `pg_statio_all_indexes`, which are standard PostgreSQL statistics views
 * designed for efficient diagnostic use. The `statement_timeout` set by
 * `pgtools.sh` provides a safety guarantee.
 */
SELECT
    schemaname,
    relname AS object_name,
    'TABLE' AS object_type,
    relname AS table_name,
    heap_blks_read + heap_blks_hit AS total_reads,
    heap_blks_hit AS total_hits,
    ROUND((heap_blks_hit * 100.0 / NULLIF(heap_blks_read + heap_blks_hit, 0)), 2) AS hit_rate_pct
FROM pg_statio_all_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
  AND (heap_blks_read + heap_blks_hit) > 0 -- Only show tables that have been accessed
UNION ALL
SELECT
    schemaname,
    indexrelname AS object_name,
    'INDEX' AS object_type,
    relname AS table_name,
    idx_blks_read + idx_blks_hit AS total_reads,
    idx_blks_hit AS total_hits,
    ROUND((idx_blks_hit * 100.0 / NULLIF(idx_blks_read + idx_blks_hit, 0)), 2) AS hit_rate_pct
FROM pg_statio_all_indexes
WHERE schemaname NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
  AND (idx_blks_read + idx_blks_hit) > 0 -- Only show indexes that have been accessed
ORDER BY hit_rate_pct ASC, total_reads DESC
LIMIT 50;
