---
sidebar_position: 3
---

# top-queries

Show the most time-consuming queries. Requires the `pg_stat_statements` extension.

## Usage

```bash
./pgtools.sh top-queries "<connection_string>"
```

## Prerequisites

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

You also need `shared_preload_libraries = 'pg_stat_statements'` in `postgresql.conf` (requires restart).
