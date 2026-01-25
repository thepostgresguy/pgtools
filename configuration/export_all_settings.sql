/*
 * Script: export_all_settings.sql
 * Purpose: Export all PostgreSQL server settings in human-readable and JSON formats
 * Supports: PostgreSQL 15, 16, 17, 18
 * Privileges: pg_read_all_settings (preferred) or superuser
 * Usage: psql -f configuration/export_all_settings.sql > settings.txt
 */

\echo '================================================='
\echo 'PostgreSQL All Settings Export'
\echo '================================================='
\echo ''

-- Optional: reduce noise in psql output
\pset tuples_only off
\pset pager off

-- Basic server metadata for context
\echo '--- SERVER METADATA ---'
SELECT 
    version() AS postgresql_version,
    current_setting('server_version_num')::int AS server_version_num,
    current_setting('data_directory') AS data_directory,
    current_setting('config_file') AS config_file;

\echo ''

-- Full settings list
\echo '--- ALL SETTINGS (TABLE FORM) ---'
SELECT 
    name,
    setting,
    unit,
    category,
    short_desc,
    context,
    vartype,
    source,
    boot_val,
    reset_val,
    pending_restart
FROM pg_settings
ORDER BY category, name;

\echo ''

-- Settings that differ from defaults
\echo '--- SETTINGS OVERRIDDEN FROM DEFAULTS ---'
SELECT 
    name,
    setting,
    reset_val AS default_value,
    source,
    sourcefile,
    sourceline,
    pending_restart
FROM pg_settings
WHERE source <> 'default'
ORDER BY category, name;

\echo ''

-- JSON export (one row, json_agg)
\echo '--- ALL SETTINGS (JSON) ---'
SELECT json_agg(s ORDER BY category, name) AS settings_json
FROM (
    SELECT 
        name,
        setting,
        unit,
        category,
        short_desc,
        context,
        vartype,
        source,
        boot_val,
        reset_val,
        pending_restart
    FROM pg_settings
) AS s;

\echo ''
\echo 'Tip: For CSV use psql \"\\copy (SELECT ... FROM pg_settings ORDER BY category, name) TO \"'"'"'settings.csv'"'"' CSV HEADER\"'
