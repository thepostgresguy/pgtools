# PostgreSQL Maintenance Tools

For complete documentation, see [docs/maintenance.md](../docs/maintenance.md) or visit the [online documentation](https://gmartinez-dbai.github.io/pgtools/maintenance).

## Quick Reference

This directory contains automated maintenance scripts:

- `auto_maintenance.sh` - Comprehensive automated maintenance operations (VACUUM, ANALYZE, REINDEX)
- `maintenance_scheduler.sql` - Analysis and scheduling recommendations
- `statistics_collector.sql` - Table and index statistics analysis
- `switch_pg_wal_file.sql` - WAL file rotation
- `walfile_in_use.sql` - Current WAL file information
- `Transaction Wraparound/` - Transaction wraparound monitoring

## Quick Start

```bash
# Automated maintenance with intelligent thresholds
./maintenance/auto_maintenance.sh --operation auto --verbose

# Generate maintenance scheduling analysis
psql -d mydb -f maintenance/maintenance_scheduler.sql
```

For detailed usage and configuration options, please refer to the complete documentation linked above.
