SELECT datname, age(datfrozenxid) AS xid_age, datfrozenxid
FROM pg_database
ORDER BY xid_age DESC;

-- Check individual tables:
SELECT relname, age(relfrozenxid)
FROM pg_class
WHERE relkind = 'r'
ORDER BY age(relfrozenxid) DESC
    LIMIT 10;
