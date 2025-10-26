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
### Find missing indexes
```bash
psql -U postgres -d mydb -f optimization/missing_indexes.sql
```
### Security audit
```bash
psql -U postgres -d mydb -f security/permission_audit.sql
```
### Run automated maintenance
```bash
# Automated VACUUM/ANALYZE with intelligent thresholds
./maintenance/auto_maintenance.sh --operation auto --verbose

# Generate maintenance scheduling analysis
psql -U postgres -d mydb -f maintenance/maintenance_scheduler.sql

# Analyze statistics quality and optimization
psql -U postgres -d mydb -f maintenance/statistics_collector.sql
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
./maintenance/auto_maintenance.sh --operation auto --verbose
```
### Performance Investigation
```bash
psql -d mydb -f monitoring/bloating.sql
psql -d mydb -f monitoring/buffer_troubleshoot.sql
psql -d mydb -f optimization/missing_indexes.sql
psql -d mydb -f performance/query_performance_profiler.sql
psql -d mydb -f performance/wait_event_analysis.sql
psql -d mydb -f troubleshooting/postgres_troubleshooting_queries.sql
```
### Before Major Changes
```bash
psql -d mydb -f administration/table_ownership.sql
psql -d mydb -f administration/ForeignConst.sql
psql -d mydb -f administration/extensions.sql
psql -d mydb -f backup/backup_validation.sql
psql -d mydb -f configuration/configuration_analysis.sql
```
### Security Audit
```bash
psql -d mydb -f security/permission_audit.sql
```
### Partition Management
```bash
psql -d mydb -f administration/partition_management.sql
```
### Wait Event Analysis
```bash
psql -d mydb -f performance/wait_event_analysis.sql
```
### Query Performance Profiling
```bash
psql -d mydb -f performance/query_performance_profiler.sql
```
### Resource Monitoring
```bash
psql -d mydb -f performance/resource_monitoring.sql
```
### Configuration Analysis
```bash
psql -d mydb -f configuration/configuration_analysis.sql
```
### Parameter Tuning
```bash
./configuration/parameter_tuner.sh --mode recommend --workload oltp --ram 16GB
```
### Generate Grafana Dashboard
```bash
./integration/grafana_dashboard_generator.sh --type comprehensive -o dashboard.json
```
### Start Prometheus Exporter
```bash
./integration/prometheus_exporter.sh --port 9187 --daemon
```
### Maintenance Automation
```bash
# Run automated maintenance with intelligent thresholds
./maintenance/auto_maintenance.sh --operation auto --dry-run

# VACUUM tables with >15% dead tuples, using 4 parallel jobs
./maintenance/auto_maintenance.sh --operation vacuum --dead-threshold 15 --parallel 4

# Generate comprehensive maintenance analysis
psql -d mydb -f maintenance/maintenance_scheduler.sql

# Analyze statistics quality for optimization
psql -d mydb -f maintenance/statistics_collector.sql
```
## Contributing
Contributions are welcome! Please:
1. Test your scripts thoroughly
2. Add clear comments explaining what each query does
3. Include usage examples in script headers
4. Update this README with new scripts

## Automation Framework

The `automation/` directory provides a complete operational framework for pgtools:

- **`pgtools_health_check.sh`** - Comprehensive automation wrapper with multi-format reporting
- **`pgtools_scheduler.sh`** - Cron job management and scheduling
- **`run_security_audit.sh`** - Automated security audit runner  
- **`cleanup_reports.sh`** - Report cleanup and log rotation
- **`export_metrics.sh`** - Metrics export for Prometheus/Grafana
- **`test_pgtools.sh`** - Testing framework and validation

### Quick Automation Setup
```bash
# Configure automation
cp automation/pgtools.conf.example automation/pgtools.conf
edit automation/pgtools.conf

# Install automated monitoring
./automation/pgtools_scheduler.sh install

# Run comprehensive health check
./automation/pgtools_health_check.sh --format html --email
```

See `automation/README.md` for complete documentation.

## Directory Structure

```
administration/           # Database administration utilities
├── extensions.sql       # Extension management queries
├── ForeignConst.sql     # Foreign key constraint analysis  
├── NonHypertables.sql   # TimescaleDB hypertable identification
├── partition_management.sql  # Comprehensive partition lifecycle management
└── table_ownership.sql  # Table ownership and permission queries

automation/              # Automation and operational integration
├── cleanup_reports.sh   # Report cleanup and log rotation
├── export_metrics.sh    # Metrics export for monitoring systems
├── pgtools.conf.example # Configuration template
├── pgtools_health_check.sh  # Comprehensive health check automation
├── pgtools_scheduler.sh # Cron job management and scheduling
├── README.md           # Automation framework documentation
├── run_security_audit.sh    # Automated security audit runner
└── test_pgtools.sh     # Testing framework and validation

backup/                  # Backup validation and monitoring
└── backup_validation.sql    # Comprehensive backup health validation

maintenance/             # Database maintenance and automation
├── auto_maintenance.sh       # Comprehensive automated maintenance operations
├── maintenance_scheduler.sql # Maintenance analysis and scheduling recommendations
├── statistics_collector.sql  # Statistics analysis and optimization
├── switch_pg_wal_file.sql    # WAL file rotation
├── walfile_in_use.sql        # Current WAL file information
├── README.md                # Maintenance automation framework documentation
└── Transaction Wraparound/    # Transaction wraparound monitoring
    ├── queries.sql
    └── README.md

monitoring/              # Performance and health monitoring
├── bloating.sql         # Table and index bloat detection
├── buffer_troubleshoot.sql   # Buffer pool analysis
├── connection_pools.sql # Connection pooling efficiency analysis
├── locks.sql            # Lock monitoring and analysis
├── postgres_locking_blocking.sql  # Blocking query identification
├── replication.sql      # Replication status and lag monitoring  
└── txid.sql            # Transaction ID monitoring

performance/            # Performance analysis and monitoring tools  
├── hot_update_optimization_checklist.sql  # HOT update analysis
├── missing_indexes.sql  # Intelligent index recommendation engine
├── query_performance_profiler.sql         # Comprehensive query performance analysis
├── resource_monitoring.sql                # System resource utilization monitoring
└── wait_event_analysis.sql                # Wait event analysis and bottleneck identification

configuration/          # Configuration management and tuning
├── configuration_analysis.sql             # PostgreSQL configuration analysis
└── parameter_tuner.sh                     # Interactive parameter tuning assistant

integration/            # Monitoring system integration tools
├── grafana_dashboard_generator.sh         # Grafana dashboard generator
└── prometheus_exporter.sh                 # Custom Prometheus metrics exporter

security/                # Security auditing and compliance
└── permission_audit.sql # Enterprise-grade security audit

troubleshooting/         # Diagnostic and troubleshooting queries
├── postgres_troubleshooting_cheat_sheet.txt     # Quick reference guide
├── postgres_troubleshooting_queries.sql         # General diagnostic queries
├── postgres_troubleshooting_query_pack_01.sql   # Focused query set 1
├── postgres_troubleshooting_query_pack_02.sql   # Focused query set 2
└── postgres_troubleshooting_query_pack_03.sql   # Focused query set 3
```

## License
See LICENSE file for details.

## Support
For issues, questions, or contributions, please open an issue in the repository.

**Note**: These scripts are provided as-is. Always review and test scripts in a non-production environment before using them on production databases.