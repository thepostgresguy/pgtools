---
sidebar_position: 5
---

# replication

Monitor replication lag and status. Run on the primary server.

## Usage

```bash
./pgtools.sh replication "<connection_string>"
```

## Critical Alerts

- Lag >5 minutes on sync replicas
- Inactive replication slots
