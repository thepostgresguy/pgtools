/*
 * Script: extension_availables.sql
 * Purpose: List all available PostgreSQL extensions with their descriptions
 * 
 * Usage:
 *   psql -d database_name -f administration/extension_availables.sql
 *
 * Requirements:
 *   - PostgreSQL 15+
 *   - Privileges: Any user (reads from pg_available_extensions view)
 *
 * Output:
 *   - Extension name
 *   - Default version
 *   - Installed version (NULL if not installed)
 *   - Description/comment
 *
 * Notes:
 *   - Shows both installed and available (not yet installed) extensions
 *   - Useful for discovering what extensions can be enabled
 *   - Helps plan extension installations before migrations
 *   - installed_version will be NULL for extensions not yet installed
 */
SELECT name,
       default_version,
       installed_version,
       comment
FROM pg_available_extensions
ORDER BY name;
