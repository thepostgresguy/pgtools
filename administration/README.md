# PostgreSQL Administration Scripts

For complete documentation, see [docs/administration.md](../docs/administration.md) or visit the [online documentation](https://gmartinez-dbai.github.io/pgtools/administration).

## Quick Reference

This directory contains database administration utilities:

- `extensions.sql` - Extension management queries
- `ForeignConst.sql` - Foreign key constraint analysis
- `NonHypertables.sql` - TimescaleDB hypertable identification
- `partition_management.sql` - Comprehensive partition lifecycle management
- `table_ownership.sql` - Table ownership and permission queries

## Quick Start

```bash
# Schema and ownership analysis
psql -d mydb -f administration/table_ownership.sql
psql -d mydb -f administration/extensions.sql

# Partition management
psql -d mydb -f administration/partition_management.sql
```

For detailed usage, workflows, and best practices, please refer to the complete documentation linked above.
