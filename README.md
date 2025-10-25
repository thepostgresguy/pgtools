# pgtools

A collection of SQL scripts and utilities for monitoring, troubleshooting, and maintaining PostgreSQL databases.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Script Categories](#script-categories)
- [Usage Examples](#usage-examples)
- [Contributing](#contributing)
- [License](#license)

## Overview

This toolkit provides battle-tested SQL scripts for PostgreSQL database administrators and developers to:
- Monitor database health and performance
- Troubleshoot common issues
- Maintain database integrity
- Optimize query performance
- Manage replication and WAL files

## Prerequisites

- PostgreSQL 10+ (some scripts may work with earlier versions)
- Appropriate database privileges (typically `pg_monitor` role or superuser)
- `psql` command-line tool or any PostgreSQL client

## Quick Start

```bash
# Clone the repository
git clone https://github.com/thepostgresguy/pgtools.git
cd pgtools

# Connect to your database and run a script
psql -U username -d database_name -f locks.sql
```
## Script Categories
### 🔍 Monitoring Scripts
**bloating.sql**
- Detects table and index bloat
- Shows dead tuples and wasted space
- Helps identify tables needing VACUUM

**buffer_troubleshoot.sql**
- Analyzes shared buffer usage
- Shows buffer cache hit ratios
- Identifies tables with poor caching

**locks.sql**
- Lists current locks in the database
- Shows lock types and waiting queries
- Essential for deadlock investigation

**postgres_locking_blocking.sql**
- Advanced lock analysis
- Shows blocking and blocked queries
- Includes query details and wait times

**replication.sql**
- Monitors replication lag
- Shows replication slot status
- Checks standby server health

**txid.sql**
- Displays transaction ID information
- Monitors transaction wraparound risk
- Shows age of databases and tables

**connection_pools.sql**
- Monitors connection pooling health and efficiency
- Analyzes connection patterns and potential leaks
- Provides connection pool optimization recommendations
- Works with PgBouncer, Pgpool-II, and native connections

### 🔧 Maintenance Scripts
**switch_pg_wal_file.sql**
- Forces WAL file switching
- Useful for archiving and backup operations
- Requires superuser privileges

**walfile_in_use.sql**
- Shows currently active WAL files
- Displays WAL file location and size
- Helps troubleshoot disk space issues

**Transaction Wraparound**
- Scripts for monitoring and preventing transaction ID wraparound
- Critical for database availability

### 👤 Administration Scripts
**extensions.sql**
- Lists installed PostgreSQL extensions
- Shows extension versions and schemas
- Helps audit database capabilities

**table_ownership.sql**
- Shows table ownership information
- Useful for permission audits
- Helps with database migrations

**ForeignConst.sql**
- Lists foreign key constraints
- Shows constraint details and relationships
- Aids in schema documentation

**NonHypertables.sql**
- Identifies non-hypertables (TimescaleDB specific)
- Useful for TimescaleDB users
- Helps in migration planning

**partition_management.sql**
- Monitors partition health and performance
- Analyzes partition size distribution and balance
- Provides partition maintenance recommendations
- Supports automated partition management strategies

### ⚡ Optimization Scripts
**hot_update_optimization_checklist.sql**
- Checks HOT (Heap-Only Tuple) update optimization
- Identifies inefficient table structures
- Suggests fillfactor adjustments

**missing_indexes.sql**
- Identifies potentially beneficial indexes based on query patterns
- Analyzes sequential scan activity and unused indexes
- Detects foreign key columns missing indexes
- Provides index optimization recommendations

### 📦 Backup & Recovery Scripts
**backup_validation.sql**
- Validates backup completeness and integrity
- Checks WAL archiving status and health
- Analyzes backup readiness and configuration
- Provides backup strategy recommendations

### 🔒 Security Scripts
**permission_audit.sql**
- Comprehensive security audit of roles and permissions
- Identifies overprivileged accounts and security risks
- Analyzes database, schema, and table-level access
- Reviews authentication and Row Level Security (RLS)

### 🩺 Troubleshooting Scripts
**postgres_troubleshooting_queries.sql**
- Collection of diagnostic queries
- Quick health checks
- Performance analysis queries

**postgres_troubleshooting_query_pack_01.sql**
- First pack of troubleshooting queries
- Focuses on basic diagnostics

**postgres_troubleshooting_query_pack_02.sql**
- Second pack of troubleshooting queries
- Intermediate level diagnostics

**postgres_troubleshooting_query_pack_03.sql**
- Third pack of troubleshooting queries
- Advanced diagnostics

**postgres_troubleshooting_cheat_sheet.txt**
- Quick reference guide
- Common commands and queries
- Best practices and tips

## Usage Examples
### Check for blocking queries
```bash
psql -U postgres -d mydb -f monitoring/postgres_locking_blocking.sql
```
### Monitor replication lag
```bash
psql -U postgres -d mydb -f monitoring/replication.sql
```
### Identify bloated tables
```bash
psql -U postgres -d mydb -f monitoring/bloating.sql
```
### Check transaction wraparound risk
```bash
psql -U postgres -d mydb -f monitoring/txid.sql
```
### Validate backup readiness
```bash
psql -U postgres -d mydb -f backup/backup_validation.sql
```
### Analyze connection pooling efficiency
```bash
psql -U postgres -d mydb -f monitoring/connection_pools.sql
```
### Find missing indexes
```bash
psql -U postgres -d mydb -f optimization/missing_indexes.sql
```
### Security audit
```bash
psql -U postgres -d mydb -f security/permission_audit.sql
```
## Best Practices
1. **Test in non-production first**: Always test scripts in development/staging before running in production
2. **Check privileges**: Ensure you have necessary permissions before running scripts
3. **Monitor impact**: Some queries may be resource-intensive on large databases
4. **Regular monitoring**: Schedule regular runs of monitoring scripts for proactive maintenance
5. **Review before execution**: Always review script contents before running

## Common Use Cases
### Daily Health Check
```bash
psql -d mydb -f monitoring/locks.sql
psql -d mydb -f monitoring/replication.sql
psql -d mydb -f monitoring/txid.sql
psql -d mydb -f monitoring/connection_pools.sql
```
### Performance Investigation
```bash
psql -d mydb -f monitoring/bloating.sql
psql -d mydb -f monitoring/buffer_troubleshoot.sql
psql -d mydb -f optimization/missing_indexes.sql
psql -d mydb -f troubleshooting/postgres_troubleshooting_queries.sql
```
### Before Major Changes
```bash
psql -d mydb -f administration/table_ownership.sql
psql -d mydb -f administration/ForeignConst.sql
psql -d mydb -f administration/extensions.sql
psql -d mydb -f backup/backup_validation.sql
```
### Security Audit
```bash
psql -d mydb -f security/permission_audit.sql
```
### Partition Management
```bash
psql -d mydb -f administration/partition_management.sql
```
## Contributing
Contributions are welcome! Please:
1. Test your scripts thoroughly
2. Add clear comments explaining what each query does
3. Include usage examples in script headers
4. Update this README with new scripts

## License
See LICENSE file for details.
## Support
For issues, questions, or contributions, please open an issue in the repository.
**Note**: These scripts are provided as-is. Always review and test scripts in a non-production environment before using them on production databases.