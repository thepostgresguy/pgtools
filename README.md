# pgtools

A collection of SQL scripts and utilities for monitoring, troubleshooting, and maintaining PostgreSQL databases.

## 👋 New to pgtools?

**[👉 Get Started Here - Complete Beginner's Guide](GETTING-STARTED.md)**

Perfect for new users! This comprehensive guide walks you through installation, first steps, essential workflows, and automation setup.

## 📋 Table of Contents

- [Overview](#overview)
- [Script Categories](#script-categories)
- [Usage Examples](#usage-examples)
- [Contributing](#contributing)
- [License](#license)

### Quick Links

This toolkit provides battle-tested SQL scripts for PostgreSQL database administrators and developers to:
- Monitor database health and performance
- Troubleshoot common issues
- Maintain database integrity
- Optimize query performance
- Manage replication and WAL files
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

### 🤖 Maintenance Automation
**auto_maintenance.sh**
- Comprehensive automated maintenance operations (VACUUM, ANALYZE, REINDEX)
- Intelligent threshold-based maintenance with configurable parameters
- Parallel processing with safety controls and dry-run mode
- Large table detection and resource management

**maintenance_scheduler.sql**
- Analysis and scheduling recommendations for maintenance operations
- VACUUM/ANALYZE candidate identification with workload estimation
- Index bloat analysis and autovacuum effectiveness assessment
- Maintenance planning and resource optimization

**statistics_collector.sql**
- Table and index statistics analysis and optimization
- Statistics quality assessment and freshness analysis
- Column distribution analysis with optimization recommendations
- Extended statistics support for PostgreSQL 10+

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

### ⚡ Performance Analysis Scripts
**wait_event_analysis.sql**
- Comprehensive analysis of PostgreSQL wait events and performance bottlenecks
- Identifies I/O, locking, and resource contention issues
- Provides detailed wait event categorization and recommendations
- Analyzes connection pooling and background worker efficiency

**query_performance_profiler.sql**
- Detailed query performance analysis using pg_stat_statements
- Identifies slow queries, I/O intensive operations, and resource usage
- Analyzes query variance and performance degradation patterns
- Provides optimization recommendations for query tuning

**resource_monitoring.sql**
- Comprehensive system resource utilization monitoring
- Analyzes memory, I/O, connection, and storage usage patterns
- Monitors autovacuum activity and maintenance requirements
- Provides resource optimization recommendations

### ⚙️ Configuration Management Scripts
**configuration_analysis.sql**
- Comprehensive PostgreSQL configuration analysis and recommendations
- Reviews memory, connection, WAL, and security settings
- Analyzes current parameters against best practices
- Provides workload-specific tuning suggestions

**parameter_tuner.sh** (automation/configuration/)
- Interactive PostgreSQL parameter tuning assistant
- Generates optimized configurations for different workload types (OLTP, OLAP, Web)
- Provides memory and performance setting recommendations
- Supports configuration validation and analysis modes

### 🔗 Integration Tools
**grafana_dashboard_generator.sh** (integration/)
- Generates comprehensive Grafana dashboards for PostgreSQL monitoring
- Supports multiple dashboard types: comprehensive, performance, security, connections
- Provides direct Grafana API integration for automatic dashboard deployment
- Creates customizable monitoring visualizations

**prometheus_exporter.sh** (integration/)
- Custom PostgreSQL metrics exporter for Prometheus
- Exports database statistics, connection metrics, and performance data
- Supports daemon mode for continuous metrics collection
- Provides HTTP endpoint for Prometheus scraping

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

### Automation / HOT report verification
```bash
# Quick automation sanity check (connection, syntax, permissions)
./automation/test_pgtools.sh --fast

# Full automation suite with integration tests
./automation/test_pgtools.sh --full --verbose

# HOT checklist JSON validation
./automation/run_hot_update_report.sh --format json --database my_database --stdout

# HOT checklist text validation
./automation/run_hot_update_report.sh --format text --database my_database --stdout
```

## Script Categories

- **Monitoring** - Database health, locks, replication, bloating
- **Maintenance** - VACUUM, ANALYZE, statistics collection
- **Automation** - Health checks, scheduling, alerting
- **Administration** - Extensions, ownership, constraints, partitions
- **Optimization** - Index recommendations, HOT updates, missing indexes
- **Performance** - Query profiling, wait events, resource monitoring
- **Security** - Permission audits, compliance checks
- **Troubleshooting** - Diagnostic queries and cheat sheets
- **Backup & Recovery** - Backup validation and integrity checks
- **Configuration** - Parameter tuning and analysis
- **Integration** - Grafana dashboards, Prometheus exporters

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## License

See [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or contributions, please open an issue in the repository.
