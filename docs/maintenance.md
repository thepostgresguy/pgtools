# PostgreSQL Maintenance Tools

This directory contains automated maintenance scripts and analysis tools for PostgreSQL database health and performance optimization.

## Scripts Overview

### Automated Maintenance
- **`auto_maintenance.sh`** - Comprehensive automated maintenance operations (VACUUM, ANALYZE, REINDEX)
- **`maintenance_scheduler.sql`** - Analysis and scheduling recommendations for maintenance operations
- **`statistics_collector.sql`** - Table and index statistics analysis and optimization

## Script Details

### auto_maintenance.sh
Automated PostgreSQL maintenance operations with intelligent scheduling and safety features.

**Features:**
- **Multiple operations**: VACUUM, ANALYZE, REINDEX, and automated maintenance mode
- **Intelligent thresholds**: Configurable dead tuple and bloat thresholds
- **Safety features**: Dry-run mode, large table detection, parallel job control
- **Comprehensive logging**: Detailed progress reporting and error handling
- **Flexible targeting**: Schema patterns, table patterns, and size-based filtering

**Usage:**
```bash
# Automatic maintenance with intelligent thresholds
./maintenance/auto_maintenance.sh --operation auto --verbose

# VACUUM tables with >15% dead tuples
./maintenance/auto_maintenance.sh --operation vacuum --dead-threshold 15

# ANALYZE specific schema with parallel processing
./maintenance/auto_maintenance.sh --operation analyze --schema public --parallel 4

# Dry-run to preview actions
./maintenance/auto_maintenance.sh --operation auto --dry-run

# Target specific table patterns
./maintenance/auto_maintenance.sh --tables "user_*,order_*" --operation vacuum
```

**Operations:**
- **`vacuum`** - VACUUM tables based on dead tuple threshold
- **`analyze`** - ANALYZE tables with outdated or missing statistics  
- **`reindex`** - REINDEX operations for bloated indexes (future enhancement)
- **`auto`** - Automated maintenance combining ANALYZE and VACUUM operations
- **`full-vacuum`** - VACUUM FULL for severely bloated tables (use with caution)

**Safety Features:**
- **Dry-run mode** (`--dry-run`) - Preview all operations without execution
- **Large table detection** (`--skip-large`, `--large-size`) - Avoid operations on oversized tables
- **Configurable thresholds** - Prevent unnecessary maintenance operations
- **Parallel job control** (`--parallel`) - Manage system resource usage
- **Comprehensive validation** - Database connection and parameter validation

### maintenance_scheduler.sql
Comprehensive analysis script for maintenance planning and scheduling.

**Analysis Coverage:**
- **VACUUM candidates** - Tables with high dead tuple ratios requiring cleanup
- **ANALYZE candidates** - Tables with stale or missing statistics
- **Index bloat analysis** - Identification of bloated or unused indexes
- **Autovacuum effectiveness** - Analysis of autovacuum configuration and performance
- **Maintenance workload estimation** - Resource planning for maintenance operations

**Key Reports:**
- Tables requiring immediate VACUUM operations
- Tables with outdated statistics needing ANALYZE
- Index bloat and reindex recommendations
- Autovacuum configuration effectiveness
- Sample maintenance commands for manual execution

**Usage:**
```bash
# Generate comprehensive maintenance analysis
psql -f maintenance/maintenance_scheduler.sql

# Review recommendations and execute suggested commands
```

### statistics_collector.sql
Advanced PostgreSQL statistics analysis for query optimization and performance tuning.

**Analysis Features:**
- **Statistics configuration** - Review of statistics collection settings
- **Custom statistics targets** - Tables and columns with non-default targets
- **Statistics quality assessment** - Identification of insufficient statistics
- **Freshness analysis** - Detection of stale table statistics
- **Column distribution analysis** - NULL ratios, cardinality, and data characteristics
- **Index statistics** - Usage patterns and efficiency metrics
- **Extended statistics** - PostgreSQL 10+ multi-column statistics analysis

**Performance Insights:**
- **High-cardinality columns** with insufficient most common values (MCV)
- **Correlation statistics** for physically ordered data
- **NULL fraction impact** on query planning
- **Index efficiency** based on scan patterns
- **Statistics staleness** affecting query plan quality

**Optimization Recommendations:**
- Statistics target adjustments for specific columns
- Tables requiring immediate ANALYZE operations
- Configuration tuning suggestions
- Extended statistics creation recommendations

**Usage:**
```bash
# Comprehensive statistics analysis
psql -f maintenance/statistics_collector.sql

# Review recommendations for statistics target tuning
```

## Integration with Automation Framework

### Cron Integration
```bash
# Daily automated maintenance
0 2 * * * /path/to/pgtools/maintenance/auto_maintenance.sh --operation auto >> /var/log/postgresql/maintenance.log 2>&1

# Weekly comprehensive ANALYZE
0 3 * * 0 /path/to/pgtools/maintenance/auto_maintenance.sh --operation analyze --verbose >> /var/log/postgresql/weekly_analyze.log 2>&1

# Monthly maintenance analysis report
0 4 1 * * psql -f /path/to/pgtools/maintenance/maintenance_scheduler.sql > /var/log/postgresql/maintenance_report_$(date +\%Y\%m).log 2>&1
```

### Integration with pgtools Automation
```bash
# Use with pgtools health check framework
./automation/pgtools_health_check.sh --include-maintenance

# Combine with monitoring and alerting
./maintenance/auto_maintenance.sh --operation auto --output maintenance_report.log
./automation/pgtools_health_check.sh --format html --email
```

## Best Practices

### 1. Maintenance Scheduling
- **Daily**: Run automated maintenance during low-activity periods
- **Weekly**: Comprehensive ANALYZE operations for statistics updates
- **Monthly**: Full maintenance analysis and planning review
- **As-needed**: Manual maintenance for specific performance issues

### 2. Threshold Configuration
- **Dead tuple threshold**: 15-20% for regular VACUUM operations
- **Statistics freshness**: ANALYZE tables after 10% data changes
- **Large table handling**: Define size thresholds based on maintenance windows
- **Parallel operations**: Match to available system resources

### 3. Safety Considerations
- **Always test in non-production** before implementing maintenance automation
- **Use dry-run mode** to validate maintenance plans
- **Monitor maintenance duration** and adjust thresholds accordingly
- **Coordinate with application maintenance windows**

### 4. Performance Optimization
- **Statistics targets**: Increase for high-cardinality columns used in WHERE clauses
- **Extended statistics**: Create for correlated columns in PostgreSQL 10+
- **Index maintenance**: Regular monitoring and selective REINDEX operations
- **Autovacuum tuning**: Adjust settings based on workload patterns

## Maintenance Workflows

### Daily Automated Maintenance
```bash
# Morning maintenance routine
./maintenance/auto_maintenance.sh --operation auto --dead-threshold 20 --verbose

# Generate daily maintenance report
psql -f maintenance/maintenance_scheduler.sql > daily_maintenance_$(date +%Y%m%d).log
```

### Weekly Deep Maintenance
```bash
# Comprehensive statistics update
./maintenance/auto_maintenance.sh --operation analyze --parallel 4

# Statistics quality analysis
psql -f maintenance/statistics_collector.sql > weekly_stats_$(date +%Y%m%d).log

# Review and optimize based on reports
```

### Monthly Maintenance Planning
```bash
# Complete maintenance analysis
psql -f maintenance/maintenance_scheduler.sql

# Statistics analysis and optimization
psql -f maintenance/statistics_collector.sql

# Plan manual maintenance for identified issues
# Review autovacuum effectiveness and tuning
```

## Troubleshooting

### Common Issues

**High Dead Tuple Ratios:**
```bash
# Immediate VACUUM for critical tables
./maintenance/auto_maintenance.sh --operation vacuum --dead-threshold 10

# Review autovacuum configuration
SELECT name, setting FROM pg_settings WHERE name LIKE 'autovacuum%';
```

**Stale Statistics:**
```bash
# Force ANALYZE on problem tables
./maintenance/auto_maintenance.sh --operation analyze --tables "problem_table_*"

# Check statistics collection settings
psql -f maintenance/statistics_collector.sql
```

**Maintenance Taking Too Long:**
```bash
# Use parallel operations
./maintenance/auto_maintenance.sh --operation auto --parallel 2

# Skip large tables during regular maintenance
./maintenance/auto_maintenance.sh --operation vacuum --skip-large --large-size 5GB
```

**Autovacuum Not Effective:**
```bash
# Review autovacuum settings and table-specific configurations
SELECT schemaname, tablename, last_autovacuum, n_dead_tup 
FROM pg_stat_user_tables 
WHERE n_dead_tup > n_live_tup * 0.2;

# Consider manual VACUUM FULL for severely bloated tables (during maintenance window)
./maintenance/auto_maintenance.sh --operation full-vacuum --tables "bloated_table" --dry-run
```

## Configuration Reference

### Key Parameters for Maintenance
```sql
-- Autovacuum configuration
autovacuum = on
autovacuum_max_workers = 3
autovacuum_vacuum_threshold = 50
autovacuum_vacuum_scale_factor = 0.2
autovacuum_analyze_threshold = 50
autovacuum_analyze_scale_factor = 0.1

-- Statistics collection
default_statistics_target = 100
track_counts = on
track_activities = on

-- Maintenance work memory
maintenance_work_mem = 256MB
```

### Table-specific Maintenance Tuning
```sql
-- Increase statistics target for high-cardinality columns
ALTER TABLE users ALTER COLUMN user_id SET STATISTICS 1000;

-- Adjust autovacuum settings for high-update tables
ALTER TABLE user_sessions SET (
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05
);

-- Create extended statistics for correlated columns (PostgreSQL 10+)
CREATE STATISTICS user_location_stats ON city, state FROM users;
```

This maintenance framework provides comprehensive tools for PostgreSQL database health, ensuring optimal performance through intelligent automation and detailed analysis.