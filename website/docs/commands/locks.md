---
sidebar_position: 1
---

# locks

Show current lock contention and blocking queries. This is typically the first command to run when a customer reports "the database is slow."

## Usage

```bash
./pgtools.sh locks "<connection_string>"
```

## What to Look For

- `granted = 'f'` — queries waiting for locks
- High `query_age` — long-running queries holding locks
- `AccessExclusiveLock` during business hours — DDL operations blocking reads/writes
