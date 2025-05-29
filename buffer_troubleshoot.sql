--setup
-- # In postgresql.conf:
-- shared_preload_libraries = 'pg_buffercache'

-- Create extension
CREATE EXTENSION pg_buffercache;

-- Top Objects in Shared Buffers
SELECT c.relname,
       count(*) AS buffers,
       ROUND(100.0 * count(*) / (SELECT count(*) FROM pg_buffercache), 2) AS percent
FROM pg_buffercache b
JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
JOIN pg_database d ON b.reldatabase = d.oid
WHERE d.datname = current_database()
GROUP BY c.relname
ORDER BY buffers DESC
LIMIT 10;

--Buffers by Table and Index
SELECT c.relname, c.relkind,
       count(*) AS buffers,
       ROUND(100.0 * count(*) / total.total, 2) AS percent
FROM pg_buffercache b
JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
JOIN pg_database d ON b.reldatabase = d.oid
JOIN (SELECT count(*) AS total FROM pg_buffercache) AS total ON TRUE
WHERE d.datname = current_database()
GROUP BY c.relname, c.relkind, total.total
ORDER BY buffers DESC;

-- Cache Hit Ratios (per table)
SELECT relname,
       ROUND(100.0 * blks_hit / GREATEST(blks_hit + blks_read, 1), 2) AS hit_ratio,
       blks_hit, blks_read
FROM pg_stat_user_tables
ORDER BY hit_ratio ASC;

--I/O Load by Object (PostgreSQL 15+)
SELECT backend_type, relname, io_read, io_write
FROM pg_stat_io
JOIN pg_class ON pg_stat_io.relid = pg_class.oid
WHERE io_read + io_write > 0
ORDER BY io_read DESC;

-- Query Buffer Usage (via EXPLAIN)
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM your_table WHERE id = 123;
