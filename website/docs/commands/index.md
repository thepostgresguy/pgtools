---
sidebar_position: 3
---

# Commands

Run `./pgtools.sh` with no arguments to see the full list of commands.

## General Diagnostics

| Command | Description |
|---------|-------------|
| [`locks`](./locks) | Show current lock contention and blocking queries |
| [`activity`](./activity) | Display current query activity from `pg_stat_activity` |
| [`top-queries`](./top-queries) | Show most time-consuming queries (requires `pg_stat_statements`) |
| [`bloat`](./bloat) | Identify table and index bloat |
| [`replication`](./replication) | Monitor replication lag and status |
| [`disk-usage`](./disk-usage) | Show disk usage by table and index |
| [`cache-hit`](./cache-hit) | Show table and index cache hit rates |

## TimescaleDB Diagnostics

| Command | Description |
|---------|-------------|
| [`chunk-stats`](./chunk-stats) | Show chunk count and size per hypertable |
| [`compression-stats`](./compression-stats) | Show compression ratio and job status per hypertable |
| [`cagg-stats`](./cagg-stats) | Show continuous aggregate health and refresh policy status |
| [`job-errors`](./job-errors) | Show recent errors from background jobs |
| [`uncompressed-chunks`](./uncompressed-chunks) | Show chunks that are old but not compressed |

## Administration

| Command | Description |
|---------|-------------|
| [`permissions`](./permissions) | Audit user and role permissions |
| [`ownership`](./ownership) | Display table and object ownership |
