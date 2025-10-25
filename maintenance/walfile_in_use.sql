/*
 * Script: walfile_in_use.sql
 * Purpose: Display currently active WAL files and their locations
 *
 * Usage:
 *   psql -d database_name -f maintenance/walfile_in_use.sql
 *
 * Requirements:
 *   - PostgreSQL 10+
 *   - Privileges: Superuser or pg_monitor role
 *
 * Output:
 *   - Current WAL file name
 *   - WAL file location (LSN)
 *   - WAL directory information
 *
 * Notes:
 *   - Helps troubleshoot disk space issues in pg_wal directory
 *   - Shows current write position
 *   - Useful for monitoring WAL generation rate
 *   - For PostgreSQL 9.6 and earlier, check pg_xlog directory
 *   - Large number of WAL files may indicate archiving issues
 */

-- Current WAL file
SELECT pg_walfile_name(pg_current_wal_lsn()) AS current_wal_file,
       pg_current_wal_lsn() AS current_wal_lsn,
       pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0') AS wal_bytes_written;

-- WAL statistics
SELECT
    last_archived_wal AS last_archived_file,
    last_archived_time,
    last_failed_wal AS last_failed_file,
    last_failed_time,
    stats_reset
FROM pg_stat_archiver;