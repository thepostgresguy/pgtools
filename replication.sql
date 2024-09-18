--Replication lag
SELECT now()-pg_last_xact_replay_timestamp() as replication_lag;