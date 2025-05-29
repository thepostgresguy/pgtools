-- Current Blocking Chains**

SELECT blocked_locks.pid AS blocked_pid,
       blocked.activity AS blocked_query,
       blocking_locks.pid AS blocking_pid,
       blocking.activity AS blocking_query,
       blocked_locks.locktype, blocked_locks.relation::regclass AS relation,
       blocked_locks.mode
FROM pg_locks blocked_locks
JOIN pg_stat_activity blocked ON blocked_locks.pid = blocked.pid
JOIN pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.granted
  AND blocked_locks.pid != blocking_locks.pid
JOIN pg_stat_activity blocking ON blocking.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;


-- Show Who Is Blocking Whom (Compact)**

SELECT
    blocked.pid AS blocked_pid,
    blocked.query AS blocked_query,
    now() - blocked.query_start AS blocked_duration,
    blocking.pid AS blocking_pid,
    blocking.query AS blocking_query,
    now() - blocking.query_start AS blocking_duration
FROM pg_stat_activity blocked
JOIN pg_locks blocked_locks ON blocked_locks.pid = blocked.pid
JOIN pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.relation = blocked_locks.relation
  AND blocking_locks.mode = blocked_locks.mode
  AND blocking_locks.granted = true
JOIN pg_stat_activity blocking ON blocking.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;


-- Waiting Queries & Wait Events

SELECT pid, usename, application_name, wait_event_type, wait_event, state, query
FROM pg_stat_activity
WHERE wait_event IS NOT NULL
  AND state != 'idle';


-- Table-Level Lock Overview

SELECT l.relation::regclass AS table,
       l.mode,
       l.granted,
       a.pid,
       a.query,
       a.query_start
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE l.relation IS NOT NULL
ORDER BY a.query_start;


-- Detect AccessExclusive Locks (e.g. during DDL)

SELECT pid, relation::regclass AS locked_table, mode, granted, query, state, wait_event
FROM pg_locks
JOIN pg_stat_activity USING (pid)
WHERE mode = 'AccessExclusiveLock'
  AND granted IS TRUE;


-- Count of Locks by Type

SELECT locktype, mode, count(*) AS count
FROM pg_locks
GROUP BY locktype, mode
ORDER BY count DESC;


-- Longest Waiters

SELECT pid, now() - query_start AS wait_duration, state, wait_event_type, wait_event, query
FROM pg_stat_activity
WHERE wait_event IS NOT NULL
ORDER BY wait_duration DESC
LIMIT 10;


-- Blocking Activity Snapshot (JSON-style)

SELECT json_agg(
  json_build_object(
    'blocked_pid', blocked.pid,
    'blocking_pid', blocking.pid,
    'blocked_query', blocked.query,
    'blocking_query', blocking.query
  )
)
FROM pg_locks blocked_locks
JOIN pg_stat_activity blocked ON blocked_locks.pid = blocked.pid
JOIN pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.granted
  AND blocked_locks.pid != blocking_locks.pid
JOIN pg_stat_activity blocking ON blocking.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
