/*
 * Script: extensions.sql
 * Purpose: List all installed PostgreSQL extensions with version and schema information
 * 
 * Usage:
 *   psql -d database_name -f administration/extensions.sql
 *
 * Requirements:
 *   - PostgreSQL 9.1+
 *   - Privileges: Any user (reads from pg_extension catalog)
 *
 * Output:
 *   - Extension name
 *   - Installed version
 *   - Schema location
 *   - Description
 *
 * Notes:
 *   - Useful for auditing database capabilities
 *   - Helps identify extension dependencies before migrations
 *   - Returns empty if no extensions are installed
 */

SELECT 
    e.extname AS extension_name,
    e.extversion AS version,
    n.nspname AS schema,
    c.description
FROM pg_extension e
JOIN pg_namespace n ON n.oid = e.extnamespace
LEFT JOIN pg_description c ON c.objoid = e.oid 
    AND c.classoid = 'pg_extension'::regclass
ORDER BY e.extname;