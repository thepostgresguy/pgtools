/*
 * Script: switch_pg_wal_file.sql
 * Purpose: Force PostgreSQL to switch to a new WAL file
 *
 * Usage:
 *   psql -d database_name -f maintenance/switch_pg_wal_file.sql
 *
 * Requirements:
 *   - PostgreSQL 15+ (legacy pg_xlog functions apply to unsupported pre-10 versions)
 *   - Privileges: Superuser required
 *
 * Output:
 *   - New WAL file LSN position
 *
 * Notes:
 *   - Useful for forcing WAL archiving
 *   - Helps ensure backups include latest transactions
 *   - Call before taking file system snapshots
 *   - Legacy note: pre-10 instances used pg_switch_xlog(); PostgreSQL 15+ uses pg_switch_wal()
 *   - Does not affect database performance
 *   - Creates a new WAL segment file
 */

SELECT pg_switch_wal();