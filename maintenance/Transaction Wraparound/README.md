# Transaction Wraparound Prevention

For complete documentation, see [docs/transaction-wraparound.md](../../docs/transaction-wraparound.md) or visit the [online documentation](https://gmartinez-dbai.github.io/pgtools/transaction-wraparound).

## What is Transaction Wraparound?

PostgreSQL uses a 32-bit counter called transaction ID (xid) to track transactions. Since it's 32-bit, it wraps around after ~2 billion transactions. Old rows with very old XIDs may appear as "in the future" and become invisible, leading to data loss or corruption if not handled.

## Quick Reference

This directory contains scripts for monitoring and preventing transaction wraparound:

- `queries.sql` - Transaction age monitoring queries

## Prevention

PostgreSQL uses VACUUM (or autovacuum) to "freeze" old XIDs, marking them as no longer needing XID tracking.

Key settings:
- `autovacuum_freeze_max_age` (default: 200 million) triggers autovacuum on a table
- `vacuum_freeze_min_age` and `vacuum_freeze_table_age` control freezing aggressiveness

For detailed information and best practices, please refer to the complete documentation linked above.
