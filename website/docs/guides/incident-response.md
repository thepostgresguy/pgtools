---
sidebar_position: 4
---

# Incident Response

A customer reports "the database is slow." Here's a typical triage flow using pgtools.

## Step 1: Check for Blocking Locks

This is the most common cause of a sudden slowdown.

```bash
./pgtools.sh locks "<conn_string>"
```

## Step 2: Check Current Activity

See what queries are actively running or waiting.

```bash
./pgtools.sh activity "<conn_string>"
```

## Step 3: Check Top Queries

If `pg_stat_statements` is enabled, find which queries are consuming the most time historically.

```bash
./pgtools.sh top-queries "<conn_string>"
```

## Step 4: Check Cache Hit Rate

A low hit rate points to I/O bottlenecks.

```bash
./pgtools.sh cache-hit "<conn_string>"
```
