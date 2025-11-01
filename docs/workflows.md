# PostgreSQL Operational Workflows

This directory contains comprehensive workflow guides, checklists, and procedures for PostgreSQL database operations. These workflows provide step-by-step guidance for common operational scenarios, incident response, and maintenance procedures.

## 📋 Table of Contents

- [Quick Reference](#quick-reference)
- [Incident Response](#incident-response)
- [Maintenance Procedures](#maintenance-procedures)
- [Production Readiness](#production-readiness)
- [Workflow Automation](#workflow-automation)

## Quick Reference

### Emergency Response (Critical Issues)
```bash
# Immediate incident response
./workflows/incident_response.sh --severity critical --database production

# Performance emergency
./workflows/performance_emergency.sh --database production --output incident_$(date +%Y%m%d_%H%M).log
```

### Routine Maintenance
```bash
# Daily health check
./workflows/daily_maintenance.sh --database production --email-report

# Weekly comprehensive maintenance
./workflows/weekly_maintenance.sh --database production --include-optimization
```

### Production Deployment
```bash
# Pre-deployment readiness check
./workflows/production_readiness.sh --database staging --checklist

# Post-deployment validation
./workflows/post_deployment.sh --database production --validate-all
```

## Incident Response

### Critical Incident Response Workflow
**Use Case:** Database outage, severe performance degradation, or data integrity issues
**Response Time:** Immediate (within 5 minutes)

#### Phase 1: Assessment (0-5 minutes)
```bash
#!/bin/bash
# critical_incident_assessment.sh

DATABASE=$1
INCIDENT_ID=$(date +%Y%m%d_%H%M%S)

echo "=== CRITICAL INCIDENT RESPONSE - $INCIDENT_ID ==="
echo "Database: $DATABASE"
echo "Start Time: $(date)"

# Create incident directory
mkdir -p incidents/$INCIDENT_ID
cd incidents/$INCIDENT_ID

# STEP 1: Database connectivity check
echo "1. Testing database connectivity..."
if ! psql -d $DATABASE -c "SELECT NOW() as current_time, version();" > connectivity_check.log 2>&1; then
    echo "CRITICAL: Cannot connect to database"
    exit 1
fi

# STEP 2: Basic health metrics
echo "2. Collecting basic health metrics..."
psql -d $DATABASE -c "
SELECT 
    'Connection Count' as metric,
    count(*) as value
FROM pg_stat_activity
UNION ALL
SELECT 
    'Active Queries' as metric,
    count(*) as value
FROM pg_stat_activity 
WHERE state = 'active'
UNION ALL
SELECT 
    'Waiting Queries' as metric,
    count(*) as value
FROM pg_stat_activity 
WHERE wait_event IS NOT NULL;
" > basic_metrics.log

# STEP 3: Immediate blocking query check
echo "3. Checking for blocking queries..."
psql -d $DATABASE -f ../../monitoring/postgres_locking_blocking.sql > blocking_analysis.log

# STEP 4: System resource check
echo "4. Analyzing system resources..."
psql -d $DATABASE -f ../../monitoring/buffer_troubleshoot.sql > resource_analysis.log

echo "Phase 1 complete. Review logs for immediate action items."
```

#### Phase 2: Immediate Actions (5-15 minutes)
```bash
#!/bin/bash
# immediate_actions.sh

DATABASE=$1
INCIDENT_ID=$2

cd incidents/$INCIDENT_ID

# Check for long-running blocking queries
BLOCKING_QUERIES=$(grep -c "blocking_pid" blocking_analysis.log)

if [ "$BLOCKING_QUERIES" -gt 0 ]; then
    echo "WARNING: $BLOCKING_QUERIES blocking relationships detected"
    
    # Extract blocking PIDs for potential termination
    grep "blocking_pid" blocking_analysis.log | awk '{print $1}' > blocking_pids.txt
    
    echo "Blocking PIDs identified. Review and consider termination:"
    cat blocking_pids.txt
    
    # Terminate if critical (uncomment with caution)
    # while read pid; do
    #     psql -d $DATABASE -c "SELECT pg_terminate_backend($pid);"
    # done < blocking_pids.txt
fi

# Check for transaction wraparound emergency
echo "Checking transaction age..."
psql -d $DATABASE -f ../../monitoring/txid.sql > transaction_age.log

WRAPAROUND_RISK=$(grep -i "critical" transaction_age.log | wc -l)
if [ "$WRAPAROUND_RISK" -gt 0 ]; then
    echo "EMERGENCY: Transaction wraparound risk detected"
    echo "Consider immediate VACUUM FREEZE"
    
    # Emergency VACUUM FREEZE (uncomment if critical)
    # psql -d $DATABASE -c "VACUUM FREEZE;"
fi

# Check replication status (if applicable)
if psql -d $DATABASE -c "SELECT count(*) FROM pg_stat_replication;" -t | grep -q -v "0"; then
    echo "Checking replication status..."
    psql -d $DATABASE -f ../../monitoring/replication.sql > replication_status.log
    
    # Alert on replication lag
    LAG_CRITICAL=$(grep -E "[0-9]{2}:[0-9]{2}:[0-9]{2}" replication_status.log | wc -l)
    if [ "$LAG_CRITICAL" -gt 0 ]; then
        echo "WARNING: Replication lag detected. Check standby servers."
    fi
fi
```

#### Phase 3: Root Cause Analysis (15-30 minutes)
```bash
#!/bin/bash
# root_cause_analysis.sh

DATABASE=$1
INCIDENT_ID=$2

cd incidents/$INCIDENT_ID

echo "=== ROOT CAUSE ANALYSIS - $INCIDENT_ID ==="

# Detailed performance analysis
echo "1. Comprehensive performance analysis..."
psql -d $DATABASE -f ../../performance/query_performance_profiler.sql > query_performance.log
psql -d $DATABASE -f ../../performance/wait_event_analysis.sql > wait_events.log
psql -d $DATABASE -f ../../performance/resource_monitoring.sql > resource_utilization.log

# Storage and bloating analysis
echo "2. Storage and bloating analysis..."
psql -d $DATABASE -f ../../monitoring/bloating.sql > bloating_analysis.log

# Configuration analysis
echo "3. Configuration analysis..."
psql -d $DATABASE -f ../../configuration/configuration_analysis.sql > config_analysis.log

# Connection pattern analysis
echo "4. Connection pattern analysis..."
psql -d $DATABASE -f ../../monitoring/connection_pools.sql > connection_patterns.log

# Generate incident summary
cat << EOF > incident_summary.md
# Incident Summary - $INCIDENT_ID

## Timeline
- **Start Time:** $(head -1 connectivity_check.log | grep -o '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}')
- **Assessment Complete:** $(date)

## Key Findings
- **Blocking Queries:** $(grep -c "blocking_pid" blocking_analysis.log) relationships
- **Active Connections:** $(grep "Connection Count" basic_metrics.log | awk '{print $NF}')
- **Buffer Hit Ratio:** $(grep -o '[0-9]*\.[0-9]*%' resource_analysis.log | head -1)

## Action Items
- [ ] Review query performance report
- [ ] Analyze wait events for bottlenecks
- [ ] Check configuration recommendations
- [ ] Plan preventive measures

## Files Generated
- connectivity_check.log
- blocking_analysis.log
- resource_analysis.log
- query_performance.log
- wait_events.log
- bloating_analysis.log

EOF

echo "Root cause analysis complete. Review incident_summary.md for findings."
```

### Performance Degradation Workflow
**Use Case:** Slow query performance, high resource usage, response time issues
**Response Time:** Within 15 minutes

```bash
#!/bin/bash
# performance_degradation_response.sh

DATABASE=$1
SEVERITY=${2:-medium}  # critical, high, medium, low

echo "=== PERFORMANCE DEGRADATION RESPONSE ==="
echo "Database: $DATABASE"
echo "Severity: $SEVERITY"
echo "Start Time: $(date)"

# Create performance incident directory
PERF_ID="perf_$(date +%Y%m%d_%H%M%S)"
mkdir -p performance_incidents/$PERF_ID
cd performance_incidents/$PERF_ID

# Phase 1: Quick assessment (0-5 minutes)
echo "Phase 1: Quick Performance Assessment"

# Current query activity
psql -d $DATABASE -c "
SELECT 
    count(*) as total_connections,
    count(*) FILTER (WHERE state = 'active') as active_queries,
    count(*) FILTER (WHERE state = 'idle in transaction') as idle_in_transaction,
    count(*) FILTER (WHERE wait_event IS NOT NULL) as waiting_queries
FROM pg_stat_activity;
" > quick_stats.log

# Top resource-consuming queries
psql -d $DATABASE -c "
SELECT 
    pid, 
    now() - pg_stat_activity.query_start AS duration, 
    query 
FROM pg_stat_activity 
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes'
ORDER BY duration DESC
LIMIT 10;
" > long_running_queries.log

# Phase 2: Detailed analysis (5-15 minutes)
echo "Phase 2: Detailed Performance Analysis"

# Query performance profiling
psql -d $DATABASE -f ../../performance/query_performance_profiler.sql > query_profiler.log

# Wait event analysis
psql -d $DATABASE -f ../../performance/wait_event_analysis.sql > wait_events.log

# Resource utilization
psql -d $DATABASE -f ../../performance/resource_monitoring.sql > resource_monitoring.log

# Buffer analysis
psql -d $DATABASE -f ../../monitoring/buffer_troubleshoot.sql > buffer_analysis.log

# Phase 3: Recommendations (15+ minutes)
echo "Phase 3: Performance Recommendations"

# Generate performance report
cat << EOF > performance_report.md
# Performance Degradation Report - $PERF_ID

## Summary
- **Database:** $DATABASE
- **Severity:** $SEVERITY
- **Analysis Time:** $(date)

## Quick Stats
\`\`\`
$(cat quick_stats.log)
\`\`\`

## Long Running Queries
$(if [ -s long_running_queries.log ]; then echo "Found $(grep -c "pid" long_running_queries.log) long-running queries"; else echo "No long-running queries detected"; fi)

## Immediate Actions Required
$(if grep -q "Critical" *.log; then echo "- [ ] Address critical issues identified in analysis"; fi)
$(if [ $(grep -c "pid" long_running_queries.log) -gt 0 ]; then echo "- [ ] Review long-running queries for optimization"; fi)
- [ ] Review wait events for system bottlenecks
- [ ] Check buffer hit ratios and memory usage
- [ ] Analyze query patterns for optimization opportunities

## Follow-up Actions
- [ ] Schedule detailed query optimization review
- [ ] Consider configuration tuning based on analysis
- [ ] Plan preventive monitoring for similar issues

EOF

echo "Performance degradation analysis complete."
echo "Report saved as performance_report.md"
```

## Maintenance Procedures

### Daily Maintenance Workflow
**Schedule:** Every day at 2:00 AM (low activity period)
**Duration:** 15-30 minutes

```bash
#!/bin/bash
# daily_maintenance.sh

DATABASE=${1:-production}
EMAIL_REPORT=${2:-false}
LOG_DIR="maintenance_logs/daily/$(date +%Y%m%d)"

mkdir -p $LOG_DIR
cd $LOG_DIR

echo "=== DAILY MAINTENANCE - $(date) ==="
echo "Database: $DATABASE"

# 1. Health Check Routine
echo "1. Running daily health checks..."
psql -d $DATABASE -f ../../monitoring/locks.sql > daily_locks.log
psql -d $DATABASE -f ../../monitoring/replication.sql > daily_replication.log
psql -d $DATABASE -f ../../monitoring/txid.sql > daily_txid.log
psql -d $DATABASE -f ../../monitoring/connection_pools.sql > daily_connections.log

# 2. Automated Maintenance
echo "2. Running automated maintenance..."
../../maintenance/auto_maintenance.sh --operation auto --database $DATABASE --verbose > auto_maintenance.log

# 3. Basic Performance Check
echo "3. Basic performance monitoring..."
psql -d $DATABASE -c "
SELECT 
    'Buffer Hit Ratio' as metric,
    round(100.0 * sum(blks_hit) / (sum(blks_hit) + sum(blks_read)), 2) || '%' as value
FROM pg_stat_database
WHERE datname = '$DATABASE'
UNION ALL
SELECT 
    'Active Connections' as metric,
    count(*)::text as value
FROM pg_stat_activity 
WHERE state = 'active'
UNION ALL
SELECT 
    'Database Size' as metric,
    pg_size_pretty(pg_database_size('$DATABASE')) as value;
" > daily_metrics.log

# 4. Check for alerts
echo "4. Checking for alert conditions..."
ALERTS=""

# Check for long locks
LONG_LOCKS=$(grep -c "minutes" daily_locks.log)
if [ "$LONG_LOCKS" -gt 0 ]; then
    ALERTS="$ALERTS\n- WARNING: $LONG_LOCKS long-running locks detected"
fi

# Check replication lag
if grep -q "lag" daily_replication.log; then
    LAG_COUNT=$(grep -c "00:[0-5][0-9]:[0-9][0-9]" daily_replication.log)
    if [ "$LAG_COUNT" -lt $(grep -c "standby" daily_replication.log) ]; then
        ALERTS="$ALERTS\n- WARNING: Replication lag detected"
    fi
fi

# Check transaction age
if grep -q "Critical" daily_txid.log; then
    ALERTS="$ALERTS\n- CRITICAL: Transaction wraparound risk detected"
fi

# 5. Generate daily report
cat << EOF > daily_report_$(date +%Y%m%d).md
# Daily Maintenance Report - $(date +%Y-%m-%d)

## Database: $DATABASE
## Maintenance Window: $(date)

### Health Check Summary
- **Locks:** $(if [ "$LONG_LOCKS" -eq 0 ]; then echo "✅ No long-running locks"; else echo "⚠️ $LONG_LOCKS long-running locks"; fi)
- **Replication:** $(if grep -q "streaming" daily_replication.log; then echo "✅ Replication healthy"; else echo "⚠️ Check replication status"; fi)
- **Transactions:** $(if ! grep -q "Critical" daily_txid.log; then echo "✅ Transaction age normal"; else echo "🚨 Critical transaction age"; fi)
- **Connections:** $(if grep -q "efficient" daily_connections.log; then echo "✅ Connection pools efficient"; else echo "⚠️ Review connection patterns"; fi)

### Maintenance Results
$(if grep -q "SUCCESS" auto_maintenance.log; then echo "✅ Automated maintenance completed successfully"; else echo "⚠️ Review maintenance log for issues"; fi)

### Performance Metrics
\`\`\`
$(cat daily_metrics.log)
\`\`\`

$(if [ -n "$ALERTS" ]; then echo "### ⚠️ Alerts Requiring Attention"; echo -e "$ALERTS"; fi)

### Files Generated
- daily_locks.log
- daily_replication.log  
- daily_txid.log
- daily_connections.log
- auto_maintenance.log
- daily_metrics.log

EOF

# Email report if requested
if [ "$EMAIL_REPORT" = "true" ]; then
    mail -s "PostgreSQL Daily Maintenance Report - $(date +%Y-%m-%d)" admin@company.com < daily_report_$(date +%Y%m%d).md
fi

echo "Daily maintenance complete. Report: daily_report_$(date +%Y%m%d).md"
```

### Weekly Maintenance Workflow
**Schedule:** Every Sunday at 1:00 AM
**Duration:** 1-2 hours

```bash
#!/bin/bash
# weekly_maintenance.sh

DATABASE=${1:-production}
INCLUDE_OPTIMIZATION=${2:-false}
LOG_DIR="maintenance_logs/weekly/$(date +%Y%m%d)"

mkdir -p $LOG_DIR
cd $LOG_DIR

echo "=== WEEKLY MAINTENANCE - $(date) ==="
echo "Database: $DATABASE"

# 1. Comprehensive Health Analysis
echo "1. Comprehensive health analysis..."
psql -d $DATABASE -f ../../monitoring/bloating.sql > weekly_bloating.log
psql -d $DATABASE -f ../../monitoring/buffer_troubleshoot.sql > weekly_buffer.log
psql -d $DATABASE -f ../../performance/resource_monitoring.sql > weekly_resources.log
psql -d $DATABASE -f ../../performance/wait_event_analysis.sql > weekly_wait_events.log

# 2. Statistics Collection and Analysis
echo "2. Statistics collection and analysis..."
../../maintenance/auto_maintenance.sh --operation analyze --database $DATABASE --parallel 4 --verbose > weekly_analyze.log
psql -d $DATABASE -f ../../maintenance/statistics_collector.sql > weekly_statistics.log

# 3. Security and Administration Review
echo "3. Security and administration review..."
psql -d $DATABASE -f ../../administration/table_ownership.sql > weekly_ownership.log
psql -d $DATABASE -f ../../administration/extensions.sql > weekly_extensions.log
psql -d $DATABASE -f ../../security/permission_audit.sql > weekly_security.log

# 4. Backup Validation
echo "4. Backup validation..."
psql -d $DATABASE -f ../../backup/backup_validation.sql > weekly_backup.log

# 5. Performance Analysis (if requested)
if [ "$INCLUDE_OPTIMIZATION" = "true" ]; then
    echo "5. Performance optimization analysis..."
    psql -d $DATABASE -f ../../performance/query_performance_profiler.sql > weekly_query_analysis.log
    psql -d $DATABASE -f ../../optimization/missing_indexes.sql > weekly_index_analysis.log
    psql -d $DATABASE -f ../../optimization/hot_update_optimization_checklist.sql > weekly_hot_updates.log
fi

# 6. Maintenance Scheduling Analysis
echo "6. Maintenance scheduling analysis..."
psql -d $DATABASE -f ../../maintenance/maintenance_scheduler.sql > weekly_maintenance_schedule.log

# 7. Generate comprehensive report
echo "7. Generating weekly report..."

BLOAT_CRITICAL=$(grep -c "Critical\|VACUUM FULL" weekly_bloating.log)
SECURITY_ISSUES=$(grep -c "WARNING\|CRITICAL" weekly_security.log)
BACKUP_STATUS=$(if grep -q "SUCCESS\|OK" weekly_backup.log; then echo "✅ Healthy"; else echo "⚠️ Issues detected"; fi)

cat << EOF > weekly_report_$(date +%Y%m%d).md
# Weekly Maintenance Report - Week of $(date +%Y-%m-%d)

## Database: $DATABASE
## Maintenance Window: $(date)

## Executive Summary
- **Database Health:** $(if [ "$BLOAT_CRITICAL" -eq 0 ]; then echo "✅ Good"; else echo "⚠️ Requires attention"; fi)
- **Security Status:** $(if [ "$SECURITY_ISSUES" -eq 0 ]; then echo "✅ Compliant"; else echo "⚠️ $SECURITY_ISSUES issues found"; fi)
- **Backup Status:** $BACKUP_STATUS
- **Performance:** $(if grep -q "optimization" weekly_*.log; then echo "📊 Analysis included"; else echo "📋 Basic monitoring"; fi)

## Key Findings

### Database Health
- **Bloating Issues:** $(if [ "$BLOAT_CRITICAL" -eq 0 ]; then echo "No critical bloating detected"; else echo "$BLOAT_CRITICAL tables require attention"; fi)
- **Buffer Performance:** $(grep "Hit Ratio" weekly_buffer.log | head -1 | awk '{print $NF}')
- **Statistics Health:** $(if grep -q "stale" weekly_statistics.log; then echo "Some statistics need refresh"; else echo "Statistics are current"; fi)

### Security Review
$(if [ "$SECURITY_ISSUES" -gt 0 ]; then echo "- ⚠️ $SECURITY_ISSUES security issues identified"; fi)
- **Extension Audit:** $(grep -c "^[^-]" weekly_extensions.log) extensions installed
- **Ownership Review:** $(grep -c "^[^-]" weekly_ownership.log) tables analyzed

### Maintenance Recommendations
$(grep -A 5 "Recommended Actions" weekly_maintenance_schedule.log | tail -5)

$(if [ "$INCLUDE_OPTIMIZATION" = "true" ]; then echo "### Performance Optimization"; echo "$(grep -A 3 "Top Recommendations" weekly_query_analysis.log | tail -3)"; fi)

## Action Items
- [ ] Review bloating analysis for maintenance scheduling
- [ ] Address security findings from audit
- [ ] Validate backup processes and retention
- [ ] Plan maintenance based on scheduler recommendations
$(if [ "$INCLUDE_OPTIMIZATION" = "true" ]; then echo "- [ ] Implement query optimization recommendations"; fi)
$(if [ "$INCLUDE_OPTIMIZATION" = "true" ]; then echo "- [ ] Consider index additions from analysis"; fi)

## Files Generated
$(ls -1 *.log | sed 's/^/- /')

EOF

# Archive logs older than 30 days
find ../../maintenance_logs -name "*.log" -mtime +30 -delete

echo "Weekly maintenance complete. Report: weekly_report_$(date +%Y%m%d).md"
```

### Monthly Maintenance Workflow
**Schedule:** First Sunday of each month at 12:00 AM
**Duration:** 2-4 hours

```bash
#!/bin/bash
# monthly_maintenance.sh

DATABASE=${1:-production}
MAINTENANCE_WINDOW_HOURS=${2:-4}
LOG_DIR="maintenance_logs/monthly/$(date +%Y%m)"

mkdir -p $LOG_DIR
cd $LOG_DIR

echo "=== MONTHLY MAINTENANCE - $(date) ==="
echo "Database: $DATABASE"
echo "Maintenance Window: $MAINTENANCE_WINDOW_HOURS hours"

# 1. Pre-maintenance backup verification
echo "1. Pre-maintenance backup verification..."
psql -d $DATABASE -f ../../backup/backup_validation.sql > monthly_backup_validation.log

if grep -q "CRITICAL\|ERROR" monthly_backup_validation.log; then
    echo "ERROR: Backup validation failed. Aborting maintenance."
    exit 1
fi

# 2. Comprehensive performance baseline
echo "2. Establishing performance baseline..."
psql -d $DATABASE -f ../../performance/query_performance_profiler.sql > baseline_query_performance.log
psql -d $DATABASE -f ../../performance/resource_monitoring.sql > baseline_resource_usage.log
psql -d $DATABASE -f ../../performance/wait_event_analysis.sql > baseline_wait_events.log

# 3. Deep maintenance operations
echo "3. Running deep maintenance operations..."

# VACUUM operations with extended thresholds
../../maintenance/auto_maintenance.sh --operation vacuum --database $DATABASE --dead-threshold 10 --parallel 2 --verbose > monthly_vacuum.log

# Comprehensive ANALYZE
../../maintenance/auto_maintenance.sh --operation analyze --database $DATABASE --parallel 4 --verbose > monthly_analyze.log

# 4. Index analysis and optimization
echo "4. Index analysis and optimization..."
psql -d $DATABASE -f ../../optimization/missing_indexes.sql > monthly_index_analysis.log

# Check for unused indexes (careful - requires monitoring data)
psql -d $DATABASE -c "
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    pg_size_pretty(pg_relation_size(indexrelid)) as size
FROM pg_stat_user_indexes
WHERE idx_scan < 10
AND pg_relation_size(indexrelid) > 1024*1024
ORDER BY pg_relation_size(indexrelid) DESC;
" > monthly_unused_indexes.log

# 5. Configuration analysis and recommendations
echo "5. Configuration analysis..."
psql -d $DATABASE -f ../../configuration/configuration_analysis.sql > monthly_config_analysis.log

# 6. Comprehensive security audit
echo "6. Security audit..."
psql -d $DATABASE -f ../../security/permission_audit.sql > monthly_security_audit.log

# 7. Partition maintenance (if applicable)
echo "7. Partition maintenance..."
psql -d $DATABASE -f ../../administration/partition_management.sql > monthly_partition_analysis.log

# 8. Statistics quality assessment
echo "8. Statistics quality assessment..."
psql -d $DATABASE -f ../../maintenance/statistics_collector.sql > monthly_statistics_quality.log

# 9. Post-maintenance performance comparison
echo "9. Post-maintenance performance comparison..."
psql -d $DATABASE -f ../../performance/query_performance_profiler.sql > post_maintenance_query_performance.log
psql -d $DATABASE -f ../../performance/resource_monitoring.sql > post_maintenance_resource_usage.log

# 10. Generate comprehensive monthly report
echo "10. Generating comprehensive monthly report..."

VACUUM_TABLES=$(grep -c "VACUUM" monthly_vacuum.log)
ANALYZE_TABLES=$(grep -c "ANALYZE" monthly_analyze.log)
SECURITY_ISSUES=$(grep -c "WARNING\|CRITICAL\|ALERT" monthly_security_audit.log)
CONFIG_RECOMMENDATIONS=$(grep -c "RECOMMEND\|SUGGEST" monthly_config_analysis.log)

cat << EOF > monthly_report_$(date +%Y%m).md
# Monthly Maintenance Report - $(date +%B\ %Y)

## Database: $DATABASE
## Maintenance Window: $(date) - $MAINTENANCE_WINDOW_HOURS hours

## Executive Summary
- **Maintenance Operations:** $VACUUM_TABLES tables vacuumed, $ANALYZE_TABLES tables analyzed
- **Security Status:** $(if [ "$SECURITY_ISSUES" -eq 0 ]; then echo "✅ No issues detected"; else echo "⚠️ $SECURITY_ISSUES items require attention"; fi)  
- **Configuration:** $(if [ "$CONFIG_RECOMMENDATIONS" -eq 0 ]; then echo "✅ Optimally configured"; else echo "📋 $CONFIG_RECOMMENDATIONS optimization opportunities"; fi)
- **Performance Impact:** $(echo "Comparing pre/post maintenance metrics...")

## Maintenance Operations Summary

### VACUUM Operations
- **Tables Processed:** $VACUUM_TABLES
- **Space Reclaimed:** $(grep -o "reclaimed [0-9.]* MB" monthly_vacuum.log | awk '{sum += $2} END {print sum " MB"}')
- **Duration:** $(grep "Total maintenance time" monthly_vacuum.log | awk '{print $NF}')

### ANALYZE Operations  
- **Tables Processed:** $ANALYZE_TABLES
- **Statistics Updated:** $(grep -c "INFO.*updated" monthly_analyze.log)
- **Performance:** $(grep "completion time" monthly_analyze.log | tail -1 | awk '{print $NF}')

### Index Analysis
- **Missing Index Opportunities:** $(grep -c "CREATE INDEX" monthly_index_analysis.log)
- **Unused Indexes Detected:** $(grep -c "^[^-]" monthly_unused_indexes.log)
- **Storage Impact:** $(awk '{sum += $5} END {print sum " MB"}' monthly_unused_indexes.log)

## Security and Compliance

### Security Audit Results
$(if [ "$SECURITY_ISSUES" -eq 0 ]; then 
    echo "✅ **No security issues detected**"
else 
    echo "⚠️ **Security Issues Requiring Attention:**"
    grep -E "WARNING|CRITICAL|ALERT" monthly_security_audit.log | head -5 | sed 's/^/- /'
fi)

### Permission Review
- **Roles Audited:** $(grep -c "role:" monthly_security_audit.log)
- **Table Permissions:** $(grep -c "table permission" monthly_security_audit.log)
- **Compliance Status:** $(if grep -q "compliant" monthly_security_audit.log; then echo "✅ Compliant"; else echo "📋 Review required"; fi)

## Performance Analysis

### Configuration Recommendations
$(if [ "$CONFIG_RECOMMENDATIONS" -gt 0 ]; then
    echo "**Optimization Opportunities Identified:**"
    grep -A 2 -E "RECOMMEND|SUGGEST" monthly_config_analysis.log | head -10 | sed 's/^/- /'
else
    echo "✅ **Configuration is well-tuned**"
fi)

### Query Performance Comparison
\`\`\`
Before Maintenance:
$(grep -A 5 "Top Resource Consuming Queries" baseline_query_performance.log | tail -5)

After Maintenance:  
$(grep -A 5 "Top Resource Consuming Queries" post_maintenance_query_performance.log | tail -5)
\`\`\`

### Resource Utilization
\`\`\`
Baseline Metrics:
$(grep -E "Memory|Connection|Buffer" baseline_resource_usage.log)

Post-Maintenance Metrics:
$(grep -E "Memory|Connection|Buffer" post_maintenance_resource_usage.log)
\`\`\`

## Action Items for Next Month

### High Priority
$(if [ "$SECURITY_ISSUES" -gt 0 ]; then echo "- [ ] Address security audit findings"; fi)
$(if [ "$CONFIG_RECOMMENDATIONS" -gt 0 ]; then echo "- [ ] Implement configuration recommendations"; fi)
$(if grep -q "CREATE INDEX" monthly_index_analysis.log; then echo "- [ ] Review and implement recommended indexes"; fi)

### Medium Priority
- [ ] Monitor performance trends from maintenance impact
- [ ] Review unused indexes for potential removal
- [ ] Plan capacity based on growth trends
$(if grep -q "partition" monthly_partition_analysis.log; then echo "- [ ] Implement partition maintenance automation"; fi)

### Low Priority  
- [ ] Update documentation with configuration changes
- [ ] Schedule quarterly deep performance review
- [ ] Plan annual disaster recovery testing

## Files Generated
$(ls -1 *.log | sed 's/^/- /')

## Next Maintenance Window
**Scheduled:** First Sunday of $(date -d "+1 month" +%B\ %Y)
**Duration:** $MAINTENANCE_WINDOW_HOURS hours
**Focus Areas:** $(echo "Performance optimization, index maintenance, security review")

EOF

# Cleanup old monthly reports (keep 12 months)
find ../../maintenance_logs/monthly -name "*.md" -mtime +365 -delete

echo "Monthly maintenance complete. Report: monthly_report_$(date +%Y%m).md"
echo "Next maintenance: First Sunday of $(date -d "+1 month" +%B\ %Y)"
```

## Production Readiness

### Production Readiness Checklist
**Use Case:** New deployment validation and go-live verification
**Timeline:** 2-4 hours before production deployment

```bash
#!/bin/bash
# production_readiness.sh

DATABASE=$1
ENVIRONMENT=${2:-staging}
CHECKLIST_MODE=${3:-interactive}

echo "=== PRODUCTION READINESS CHECK ==="
echo "Database: $DATABASE"
echo "Environment: $ENVIRONMENT" 
echo "Mode: $CHECKLIST_MODE"
echo "Check Time: $(date)"

READINESS_DIR="production_readiness/$(date +%Y%m%d_%H%M)"
mkdir -p $READINESS_DIR
cd $READINESS_DIR

# Initialize checklist results
CHECKLIST_RESULTS=""
CRITICAL_ISSUES=0
WARNING_ISSUES=0

# Function to add checklist item
add_checklist_item() {
    local status=$1
    local category=$2
    local description=$3
    local details=$4
    
    case $status in
        "PASS") CHECKLIST_RESULTS="$CHECKLIST_RESULTS\n✅ [$category] $description" ;;
        "WARN") 
            CHECKLIST_RESULTS="$CHECKLIST_RESULTS\n⚠️ [$category] $description - $details"
            WARNING_ISSUES=$((WARNING_ISSUES + 1))
            ;;
        "FAIL") 
            CHECKLIST_RESULTS="$CHECKLIST_RESULTS\n❌ [$category] $description - $details"
            CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
            ;;
    esac
}

echo "1. Database Connectivity and Basic Health..."

# Test database connectivity
if psql -d $DATABASE -c "SELECT version();" > connectivity_test.log 2>&1; then
    add_checklist_item "PASS" "CONNECTIVITY" "Database connection successful"
else
    add_checklist_item "FAIL" "CONNECTIVITY" "Cannot connect to database" "Check connection parameters"
fi

# Check database size and basic stats
psql -d $DATABASE -c "
SELECT 
    pg_database_size('$DATABASE') as db_size_bytes,
    pg_size_pretty(pg_database_size('$DATABASE')) as db_size_pretty,
    (SELECT count(*) FROM pg_stat_user_tables) as user_tables,
    (SELECT count(*) FROM pg_stat_user_indexes) as user_indexes;
" > basic_stats.log

echo "2. Security and Permissions Audit..."
psql -d $DATABASE -f ../../security/permission_audit.sql > security_audit.log

SECURITY_CRITICAL=$(grep -c "CRITICAL" security_audit.log)
SECURITY_WARNINGS=$(grep -c "WARNING" security_audit.log)

if [ "$SECURITY_CRITICAL" -eq 0 ] && [ "$SECURITY_WARNINGS" -eq 0 ]; then
    add_checklist_item "PASS" "SECURITY" "Security audit passed"
elif [ "$SECURITY_CRITICAL" -eq 0 ]; then
    add_checklist_item "WARN" "SECURITY" "Security audit has warnings" "$SECURITY_WARNINGS warnings found"
else
    add_checklist_item "FAIL" "SECURITY" "Security audit failed" "$SECURITY_CRITICAL critical issues found"
fi

echo "3. Backup Validation..."
psql -d $DATABASE -f ../../backup/backup_validation.sql > backup_validation.log

if grep -q "SUCCESS\|VALID" backup_validation.log; then
    add_checklist_item "PASS" "BACKUP" "Backup validation successful"
elif grep -q "WARNING" backup_validation.log; then
    add_checklist_item "WARN" "BACKUP" "Backup validation has warnings" "Review backup configuration"
else
    add_checklist_item "FAIL" "BACKUP" "Backup validation failed" "Critical backup issues detected"
fi

echo "4. Performance Baseline Establishment..."
psql -d $DATABASE -f ../../performance/query_performance_profiler.sql > performance_baseline.log
psql -d $DATABASE -f ../../performance/resource_monitoring.sql > resource_baseline.log

# Check buffer hit ratio
BUFFER_HIT_RATIO=$(grep -o '[0-9]*\.[0-9]*%' resource_baseline.log | head -1 | sed 's/%//')
if (( $(echo "$BUFFER_HIT_RATIO > 95" | bc -l) )); then
    add_checklist_item "PASS" "PERFORMANCE" "Buffer hit ratio optimal ($BUFFER_HIT_RATIO%)"
elif (( $(echo "$BUFFER_HIT_RATIO > 90" | bc -l) )); then
    add_checklist_item "WARN" "PERFORMANCE" "Buffer hit ratio acceptable ($BUFFER_HIT_RATIO%)" "Consider memory optimization"
else
    add_checklist_item "FAIL" "PERFORMANCE" "Buffer hit ratio poor ($BUFFER_HIT_RATIO%)" "Requires immediate attention"
fi

echo "5. Configuration Analysis..."
psql -d $DATABASE -f ../../configuration/configuration_analysis.sql > config_analysis.log

CONFIG_ISSUES=$(grep -c "CRITICAL\|SUBOPTIMAL" config_analysis.log)
if [ "$CONFIG_ISSUES" -eq 0 ]; then
    add_checklist_item "PASS" "CONFIGURATION" "Database configuration optimal"
else
    add_checklist_item "WARN" "CONFIGURATION" "Configuration has optimization opportunities" "$CONFIG_ISSUES items identified"
fi

echo "6. Schema and Data Integrity..."
psql -d $DATABASE -f ../../administration/table_ownership.sql > schema_validation.log
psql -d $DATABASE -f ../../administration/ForeignConst.sql > constraint_validation.log

# Check for tables without primary keys
TABLES_NO_PK=$(psql -d $DATABASE -t -c "
SELECT count(*)
FROM information_schema.tables t
LEFT JOIN information_schema.table_constraints tc 
    ON t.table_name = tc.table_name 
    AND tc.constraint_type = 'PRIMARY KEY'
WHERE t.table_schema NOT IN ('information_schema', 'pg_catalog')
AND tc.constraint_name IS NULL;
")

if [ "$TABLES_NO_PK" -eq 0 ]; then
    add_checklist_item "PASS" "SCHEMA" "All tables have primary keys"
else
    add_checklist_item "WARN" "SCHEMA" "Tables without primary keys detected" "$TABLES_NO_PK tables need attention"
fi

echo "7. Monitoring and Alerting Setup..."

# Check if pg_stat_statements is enabled
if psql -d $DATABASE -c "SELECT count(*) FROM pg_stat_statements LIMIT 1;" > /dev/null 2>&1; then
    add_checklist_item "PASS" "MONITORING" "pg_stat_statements extension active"
else
    add_checklist_item "WARN" "MONITORING" "pg_stat_statements not available" "Consider enabling for query monitoring"
fi

# Check if replication monitoring is possible (if replicas exist)
REPLICA_COUNT=$(psql -d $DATABASE -c "SELECT count(*) FROM pg_stat_replication;" -t | tr -d ' ')
if [ "$REPLICA_COUNT" -gt 0 ]; then
    add_checklist_item "PASS" "REPLICATION" "$REPLICA_COUNT replica(s) detected and monitorable"
else
    add_checklist_item "PASS" "REPLICATION" "No replicas configured (single instance setup)"
fi

echo "8. Maintenance and Automation Setup..."

# Check autovacuum configuration
AUTOVACUUM_STATUS=$(psql -d $DATABASE -c "SHOW autovacuum;" -t | tr -d ' ')
if [ "$AUTOVACUUM_STATUS" = "on" ]; then
    add_checklist_item "PASS" "MAINTENANCE" "Autovacuum enabled"
else
    add_checklist_item "FAIL" "MAINTENANCE" "Autovacuum disabled" "Enable autovacuum for automated maintenance"
fi

# Test maintenance automation scripts
if [ -x "../../maintenance/auto_maintenance.sh" ]; then
    if ../../maintenance/auto_maintenance.sh --operation analyze --database $DATABASE --dry-run > maintenance_test.log 2>&1; then
        add_checklist_item "PASS" "AUTOMATION" "Maintenance automation scripts functional"
    else
        add_checklist_item "WARN" "AUTOMATION" "Maintenance automation needs configuration" "Review script permissions and database access"
    fi
else
    add_checklist_item "WARN" "AUTOMATION" "Maintenance automation not available" "Configure automated maintenance"
fi

echo "9. Load Testing and Capacity Validation..."

# Basic connection limit test
MAX_CONNECTIONS=$(psql -d $DATABASE -c "SHOW max_connections;" -t | tr -d ' ')
CURRENT_CONNECTIONS=$(psql -d $DATABASE -c "SELECT count(*) FROM pg_stat_activity;" -t | tr -d ' ')
CONNECTION_UTILIZATION=$(echo "scale=2; $CURRENT_CONNECTIONS * 100 / $MAX_CONNECTIONS" | bc)

if (( $(echo "$CONNECTION_UTILIZATION < 70" | bc -l) )); then
    add_checklist_item "PASS" "CAPACITY" "Connection utilization healthy (${CONNECTION_UTILIZATION}%)"
elif (( $(echo "$CONNECTION_UTILIZATION < 85" | bc -l) )); then
    add_checklist_item "WARN" "CAPACITY" "Connection utilization moderate (${CONNECTION_UTILIZATION}%)" "Monitor during peak load"
else
    add_checklist_item "FAIL" "CAPACITY" "Connection utilization high (${CONNECTION_UTILIZATION}%)" "Increase max_connections or optimize connection pooling"
fi

echo "10. Final Validation and Documentation..."

# Generate readiness report
cat << EOF > production_readiness_report.md
# Production Readiness Report

## Environment Details
- **Database:** $DATABASE
- **Environment:** $ENVIRONMENT
- **Assessment Date:** $(date)
- **Assessed By:** $(whoami)

## Readiness Summary
- **Critical Issues:** $CRITICAL_ISSUES ❌
- **Warning Issues:** $WARNING_ISSUES ⚠️
- **Overall Status:** $(if [ "$CRITICAL_ISSUES" -eq 0 ]; then echo "✅ READY FOR PRODUCTION"; else echo "❌ NOT READY - CRITICAL ISSUES MUST BE RESOLVED"; fi)

## Detailed Checklist Results
$(echo -e "$CHECKLIST_RESULTS")

## Recommendations

### Before Go-Live
$(if [ "$CRITICAL_ISSUES" -gt 0 ]; then echo "🚨 **CRITICAL: Resolve all critical issues before production deployment**"; fi)
$(if [ "$WARNING_ISSUES" -gt 0 ]; then echo "⚠️ Address warning issues or document acceptable risks"; fi)
- [ ] Schedule maintenance windows for ongoing operations
- [ ] Configure monitoring and alerting systems
- [ ] Document emergency response procedures
- [ ] Test backup and recovery procedures

### Post Go-Live Monitoring (First 24 Hours)
- [ ] Monitor connection patterns and resource utilization
- [ ] Validate backup processes are running successfully
- [ ] Check replication lag (if applicable)
- [ ] Review query performance baselines
- [ ] Verify maintenance automation is functioning

### Follow-Up Actions (First Week)
- [ ] Analyze performance trends and adjust if needed
- [ ] Review and tune configuration based on actual load
- [ ] Validate security audit findings in production context
- [ ] Schedule regular health checks and maintenance

## Files Generated
- connectivity_test.log
- basic_stats.log  
- security_audit.log
- backup_validation.log
- performance_baseline.log
- resource_baseline.log
- config_analysis.log
- schema_validation.log
- constraint_validation.log
- maintenance_test.log

## Sign-Off

**Database Administrator:** ________________________ Date: __________

**Application Owner:** _________________________ Date: __________

**Security Officer:** __________________________ Date: __________

**Operations Lead:** ___________________________ Date: __________

EOF

# Interactive mode prompts
if [ "$CHECKLIST_MODE" = "interactive" ]; then
    echo ""
    echo "=== PRODUCTION READINESS ASSESSMENT COMPLETE ==="
    echo "Critical Issues: $CRITICAL_ISSUES"
    echo "Warning Issues: $WARNING_ISSUES"
    echo ""
    
    if [ "$CRITICAL_ISSUES" -gt 0 ]; then
        echo "❌ PRODUCTION DEPLOYMENT NOT RECOMMENDED"
        echo "Critical issues must be resolved before go-live."
        echo ""
        echo "Review production_readiness_report.md for details."
        exit 1
    elif [ "$WARNING_ISSUES" -gt 0 ]; then
        echo "⚠️ PRODUCTION DEPLOYMENT WITH CAUTION"
        echo "$WARNING_ISSUES warnings identified - review and accept risks."
        echo ""
        read -p "Proceed with deployment? (yes/no): " proceed
        if [ "$proceed" != "yes" ]; then
            echo "Deployment cancelled. Review warnings and re-run assessment."
            exit 1
        fi
    else
        echo "✅ PRODUCTION READY"
        echo "All checks passed. Deployment approved."
    fi
fi

echo "Production readiness assessment complete."
echo "Report: production_readiness_report.md"
```

This comprehensive workflow system provides structured approaches for incident response, maintenance procedures, and production readiness validation, ensuring reliable PostgreSQL operations across all scenarios.