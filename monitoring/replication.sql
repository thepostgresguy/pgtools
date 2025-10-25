/*
 * Script: replication.sql
 * Purpose: Monitor replication lag and slot status for streaming replication
 *
 * Usage:
 *   psql -d database_name -f monitoring/replication.sql
 *
 * Requirements:
 *   - PostgreSQL 9.1+ (10+ for full features)
 *   - Privileges: Superuser or pg_monitor role
 *   - Must run on primary server
 *
 * Output:
 *   - Replication slot name and status
 *   - Standby application name
 *   - Current LSN positions
 *   - Replication lag (bytes and time)
 *   - Sync state (async/sync/potential)
 *
 * Notes:
 *   - Run on primary server to monitor standby servers
 *   - High lag may indicate network issues or standby performance problems
 *   - Inactive slots can cause WAL file accumulation
 *   - Lag > 1GB may need investigation
 *   - Time lag requires synchronized clocks on servers
 */

-- Replication slots and lag
SELECT
    slot_name,
    slot_type,
    database,
    active,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS replication_lag_bytes,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS flush_lag_bytes
FROM pg_replication_slots
ORDER BY active DESC, slot_name;

-- Standby status and time lag
SELECT
    application_name,
    client_addr,
    state,
    sync_state,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn)) AS sending_lag,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), write_lsn)) AS write_lag_bytes,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), flush_lsn)) AS flush_lag_bytes,
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS replay_lag_bytes,
    write_lag AS write_lag_time,
    flush_lag AS flush_lag_time,
    replay_lag AS replay_lag_time
FROM pg_stat_replication
ORDER BY application_name;
--Replication lag
SELECT now()-pg_last_xact_replay_timestamp() as replication_lag;