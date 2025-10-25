/*
 * Script: locks.sql
 * Purpose: Display current locks in the database with query information
 *
 * Usage:
 *   psql -d database_name -f monitoring/locks.sql
 *
 * Requirements:
 *   - PostgreSQL 9.2+
 *   - Privileges: pg_monitor role or sufficient permissions
 *
 * Output:
 *   - Lock type and mode
 *   - Locked relation (table/index)
 *   - Process ID holding the lock
 *   - Query being executed
 *   - Lock granted status
 *   - Wait duration
 *
 * Notes:
 *   - Essential for diagnosing blocking and deadlocks
 *   - Run during performance issues or hung queries
 *   - Granted = false indicates waiting lock
 *   - AccessExclusiveLock blocks all access to table
 */

SELECT
    l.locktype,
    l.database,
    l.relation::regclass AS relation,
    l.page,
    l.tuple,
    l.virtualxid,
    l.transactionid,
    l.mode,
    l.granted,
    a.pid,
    a.usename,
    a.application_name,
    a.client_addr,
    age(now(), a.query_start) AS query_age,
    a.state,
    a.query
FROM pg_locks l
LEFT JOIN pg_stat_activity a ON l.pid = a.pid
WHERE l.database = (SELECT oid FROM pg_database WHERE datname = current_database())
    OR l.database IS NULL
ORDER BY l.granted, a.query_start;