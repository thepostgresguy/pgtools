/*
 * Script: switch_pg_wal_file.sql
 * Purpose: Force PostgreSQL to switch to a new WAL file
 *
 * Usage:
 *   psql -d database_name -f maintenance/switch_pg_wal_file.sql
 *
 * Requirements:
 *   - PostgreSQL 10+ (use pg_xlog functions for older versions)
 *   - Privileges: Superuser required
 *
 * Output:
 *   - New WAL file LSN position
 *
 * Notes:
 *   - Useful for forcing WAL archiving
 *   - Helps ensure backups include latest transactions
 *   - Call before taking file system snapshots
 *   - For PostgreSQL 9.6 and earlier, use pg_switch_xlog()
 *   - Does not affect database performance
 *   - Creates a new WAL segment file
 */

SELECT pg_switch_wal();