# How do you fix or prevent Transaction Wraparound in PostgreSQL?
## What is Wraparound
PostgreSQL uses a 32 bit counter called transaction id (`xid`) to track transactions. Since its 32 bit, it wraps around after ~2 billion transactions. Old rows with very old XIDs may appear as "in the future" and become invisible, leading to data loss or corruption if not handled.
## How PostgreSQL Prevents Wraparound
PostgreSQL uses a mechanism called VACUUM (or autovacuum) to "freeze" old XIDs, marking them as no longer needing XID tracking. This is done by setting a special FrozenXID for old tuples.

•	autovacuum_freeze_max_age (default: 200 million) triggers autovacuum on a table.
•	vacuum_freeze_min_age and vacuum_freeze_table_age control freezing aggressiveness.
Once the age reaches 2 billion, PostgreSQL refuses to accept writes to protect data integrity.
