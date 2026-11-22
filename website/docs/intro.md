---
sidebar_position: 1
slug: /
---

# pgtools

The First Responder's Toolbelt for PostgreSQL.

`pgtools` is a curated collection of safe, read-only diagnostic scripts for PostgreSQL and TimescaleDB, wrapped in a simple command-line interface. It is designed for Support Engineers, DBAs, and developers who need to triage production database issues quickly and without causing harm.

Every script is executed with strict, short timeouts to ensure that diagnostic queries never impact a heavily loaded system.

## Core Principles

- **Zero-Harm Policy**: Every script is read-only and executed with a 5-second `statement_timeout` and 3-second `lock_timeout`.
- **No Dependencies**: The toolbelt relies only on `bash` and `psql`. No Python, Go, or other complex dependencies are required.
- **Ticket-Ready Output**: All output is formatted for easy copy-pasting into Zendesk, Jira, or Markdown documents.
- **Community-Driven**: Built for general PostgreSQL users, with specialized diagnostics for TimescaleDB.

## Quick Example

```bash
# Check for blocking locks
./pgtools.sh locks "postgresql://user:pass@host:port/dbname"

# Check TimescaleDB chunk stats
./pgtools.sh chunk-stats "service=my_customer_db"
```
