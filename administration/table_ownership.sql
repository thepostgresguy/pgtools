
/*
 * Script: table_ownership.sql
 * Purpose: Display table ownership information across all schemas
 *
 * Usage:
 *   psql -d database_name -f administration/table_ownership.sql
 *
 * Requirements:
 *   - PostgreSQL 15+
 *   - Privileges: Any user (can see tables they have access to)
 *
 * Output:
 *   - Schema name
 *   - Table name
 *   - Owner (role name)
 *   - Table type (TABLE, VIEW, etc.)
 *
 * Notes:
 *   - Useful for permission audits
 *   - Helps identify orphaned objects after role changes
 *   - Does not include system catalog tables
 *   - Essential for database migration planning
 */

SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    pg_catalog.pg_get_userbyid(c.relowner) AS owner,
    CASE c.relkind
        WHEN 'r' THEN 'TABLE'
        WHEN 'v' THEN 'VIEW'
        WHEN 'm' THEN 'MATERIALIZED VIEW'
        WHEN 'f' THEN 'FOREIGN TABLE'
        WHEN 'p' THEN 'PARTITIONED TABLE'
    END AS table_type
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r','v','m','f','p')
    AND n.nspname NOT IN ('pg_catalog', 'information_schema')
    AND n.nspname !~ '^pg_toast'
ORDER BY n.nspname, c.relname;

--Change ownership of all tables

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE format('ALTER TABLE public.%I OWNER TO new_owner;', r.tablename);
    END LOOP;
END $$;
