
/*
 * Script: NonHypertables.sql
 * Purpose: Identify regular tables that are not TimescaleDB hypertables
 *
 * Usage:
 *   psql -d database_name -f administration/NonHypertables.sql
 *
 * Requirements:
 *   - PostgreSQL 9.6+
 *   - TimescaleDB extension installed
 *   - Privileges: Any user (can see tables they have access to)
 *
 * Output:
 *   - Schema name
 *   - Table name
 *   - Table size
 *   - Row count estimate
 *
 * Notes:
 *   - Specific to TimescaleDB environments
 *   - Useful for identifying candidates for hypertable conversion
 *   - Helps with migration planning to time-series architecture
 *   - Excludes system schemas and existing hypertables
 *   - Returns error if TimescaleDB is not installed
 */

SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    n_live_tup AS estimated_rows
FROM pg_stat_user_tables
WHERE schemaname||'.'||tablename NOT IN (
    SELECT format('%I.%I', schema_name, table_name)::text
    FROM timescaledb_information.hypertables
)
AND schemaname NOT IN ('pg_catalog', 'information_schema', '_timescaledb_internal', '_timescaledb_cache')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;