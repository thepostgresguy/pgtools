# PostgreSQL Tools Automation Framework

This directory contains automation scripts and tools to operationalize the pgtools monitoring and maintenance suite.

## Scripts Overview

### Core Automation
- **`pgtools_health_check.sh`** - Comprehensive health check automation with multi-format reporting
- **`pgtools_scheduler.sh`** - Cron job management and automated scheduling 
- **`run_security_audit.sh`** - Automated security audit runner with notifications
- **`cleanup_reports.sh`** - Report cleanup and log rotation management
- **`export_metrics.sh`** - Metrics export for monitoring systems (Prometheus, Grafana, etc.)
- **`test_pgtools.sh`** - Testing framework and validation suite
- **`run_hot_update_report.sh`** - HOT update checklist exporter (text or JSON)
- **`scripts/precommit_checks.sh`** - Mirrors CI validation locally

### Configuration
- **`pgtools.conf.example`** - Configuration template with all available settings

## Quick Start

### 1. Configuration Setup
```bash
# Copy and customize configuration
cp automation/pgtools.conf.example automation/pgtools.conf
edit automation/pgtools.conf

# Make scripts executable
chmod +x automation/*.sh
```

### 2. Test Installation
```bash
# Run basic tests
./automation/test_pgtools.sh --fast

# Run full test suite
./automation/test_pgtools.sh --full
```

### 3. Set Up Automated Monitoring
```bash
# Install cron jobs for automated monitoring
./automation/pgtools_scheduler.sh install

# Check status
./automation/pgtools_scheduler.sh status
```

### 4. Manual Operations
```bash
# Run health check
./automation/pgtools_health_check.sh --quick

# Generate HTML report
./automation/pgtools_health_check.sh --format html -o report.html

# Run security audit
./automation/run_security_audit.sh --format html --email

# Export metrics
./automation/export_metrics.sh --format prometheus > metrics.txt

# HOT report (JSON default)
./automation/run_hot_update_report.sh --database my_database --format json

# HOT report (text)
./automation/run_hot_update_report.sh --format text --stdout

# Full pre-commit bundle
./scripts/precommit_checks.sh --database my_database
```

## Script Details

### pgtools_health_check.sh
Comprehensive automation wrapper for running PostgreSQL monitoring scripts.

**Features:**
- Multi-format output (text, HTML, JSON)
- Email notifications with configurable thresholds
- Dry-run mode for testing
- Quick vs comprehensive check modes
- Integration with external monitoring systems

**Usage:**
```bash
# Quick health check
./pgtools_health_check.sh --quick

# Full check with HTML report and email
./pgtools_health_check.sh --format html --email

# JSON output for API integration  
./pgtools_health_check.sh --format json -o health.json

# Dry run (test mode)
./pgtools_health_check.sh --dry-run --verbose
```

### pgtools_scheduler.sh
Cron job management for automated PostgreSQL monitoring.

**Features:**
- Install/remove cron jobs with single command
- Configurable schedules via configuration file
- Backup existing crontab before changes
- Status monitoring and validation

**Usage:**
```bash
# Install automated monitoring
./pgtools_scheduler.sh install

# Check current status
./pgtools_scheduler.sh status

# Run specific job manually
./pgtools_scheduler.sh run-job daily-quick

# Remove all pgtools cron jobs
./pgtools_scheduler.sh remove
```

**Default Schedule:**
- Daily quick check: 8 AM every day
- Weekly full check: 2 AM every Sunday  
- Monthly security audit: 3 AM first day of month
- Report cleanup: 1 AM daily

### run_security_audit.sh
Specialized runner for comprehensive security audits.

**Features:**
- Multiple output formats (text, HTML, JSON)
- Email integration for security alerts
- Verbose reporting with detailed analysis
- Integration with compliance frameworks

**Usage:**
```bash
# Basic security audit
./run_security_audit.sh

# HTML report with email notification
./run_security_audit.sh --format html --email

# JSON output for SIEM integration
./run_security_audit.sh --format json -o security.json
```

### export_metrics.sh
Export PostgreSQL metrics for monitoring systems.

**Features:**
- Multiple format support (Prometheus, Grafana, JSON, InfluxDB)
- Webhook integration for real-time monitoring
- Slow query analysis (optional)
- Grafana dashboard generation

**Usage:**
```bash
# Prometheus metrics
./export_metrics.sh --format prometheus

# Send to Prometheus Pushgateway
./export_metrics.sh --webhook http://prometheus:9091/metrics/job/postgresql

# Generate Grafana dashboard
./export_metrics.sh --format grafana > dashboard.json

# Include slow query metrics
./export_metrics.sh --slow-queries --format json
```

### cleanup_reports.sh
Automated cleanup of old reports and logs.

**Features:**
- Configurable retention period
- Automatic compression before deletion
- Dry-run mode for testing
- Multiple directory cleanup
- Size reporting and statistics

**Usage:**
```bash
# Clean reports older than default (30 days)
./cleanup_reports.sh

# Custom retention period with dry-run
./cleanup_reports.sh --days 7 --dry-run

# Verbose cleanup with compression disabled
./cleanup_reports.sh --verbose --no-compress
```

### test_pgtools.sh
Comprehensive testing framework for validation.

**Features:**
- Connection and permission testing
- SQL syntax validation
- Automation script verification
- Integration testing
- Detailed test reporting

**Usage:**
```bash
# Quick validation tests
./test_pgtools.sh --fast

# Full test suite
./test_pgtools.sh --full --verbose

# Test specific components
./test_pgtools.sh --pattern "connection*"
```

### run_hot_update_report.sh
Unified HOT update checklist exporter for iqtoolkit-analyzer integration and manual audits.

**Features:**
- JSON (default) or text output with timestamped filenames in `reports/`.
- Automatic JSON validation via `jq` or `python3 -m json.tool`.
- Honors `automation/pgtools.conf` for connection settings, with CLI/env overrides.

**Usage:**
```bash
# Default JSON report using config defaults
./automation/run_hot_update_report.sh

# Target a different database on the same server
./automation/run_hot_update_report.sh --database analytics

# Override both server and format
PGHOST=staging-db ./automation/run_hot_update_report.sh --format text --stdout

# Save to a custom location
./automation/run_hot_update_report.sh --format json --output /tmp/hot_update.json

# Combine all checks before committing
./scripts/precommit_checks.sh --database my_database
```

**Regression tests:**
```bash
# Quick automation sanity check (connection, syntax, permissions)
./automation/test_pgtools.sh --fast

# Full automation suite with integration runs (requires DB access)
./automation/test_pgtools.sh --full --verbose

# Verify HOT JSON path end-to-end
./automation/run_hot_update_report.sh --format json --database my_database --stdout

# Verify HOT text path
./automation/run_hot_update_report.sh --format text --database my_database --stdout
```

## Configuration Reference

The `pgtools.conf` file controls all automation behavior:

```bash
# Database Connection
PGHOST="localhost"
PGPORT="5432"  
PGDATABASE="postgres"
PGUSER="monitoring_user"

# Email Settings
PGTOOLS_EMAIL_TO="admin@company.com"
PGTOOLS_EMAIL_FROM="pgtools@server.com"
PGTOOLS_SMTP_SERVER="smtp.company.com"

# Alert Thresholds
PGTOOLS_CONNECTION_THRESHOLD=80
PGTOOLS_DISK_THRESHOLD=90
PGTOOLS_MEMORY_THRESHOLD=85

# Scheduling
DAILY_QUICK_CHECK="0 8 * * *"
WEEKLY_FULL_CHECK="0 2 * * 0"
MONTHLY_SECURITY_AUDIT="0 3 1 * *"

# Report Retention
PGTOOLS_KEEP_REPORTS_DAYS=30
```

**Configuration precedence:**
1. Command-line flags (e.g., `--database analytics`) override everything.
2. Environment variables such as `PGHOST`, `PGPORT`, `PGUSER`, `PGDATABASE`, `PGPASSWORD` override the config file.
3. Values in `automation/pgtools.conf` act as defaults when no overrides are supplied.

Because every automation script sources `automation/pgtools.conf` first, this order lets you define safe defaults for scheduled jobs while still pointing ad-hoc runs to alternative servers or databases.

## Integration Examples

### Prometheus Integration
```bash
# Add to prometheus.yml
- job_name: 'postgresql-custom'
  static_configs:
    - targets: ['db-server:9187']
  metrics_path: '/metrics'
  scrape_interval: 30s

# Export metrics via webhook
./export_metrics.sh --webhook http://prometheus:9091/metrics/job/postgresql
```

### Grafana Dashboard
```bash
# Generate dashboard JSON
./export_metrics.sh --format grafana > postgresql-dashboard.json

# Import via Grafana API
curl -X POST \
  http://grafana:3000/api/dashboards/db \
  -H 'Content-Type: application/json' \
  -d @postgresql-dashboard.json
```

### Email Alerts Setup
```bash
# Configure email in pgtools.conf
PGTOOLS_EMAIL_TO="dba-team@company.com"
PGTOOLS_EMAIL_FROM="postgresql-monitoring@company.com"

# Test email functionality
./run_security_audit.sh --email --verbose
```

### Cron Integration
```bash
# Install automated monitoring
./pgtools_scheduler.sh install

# Monitor cron execution
tail -f automation/cron.log

# Custom schedule modification
edit automation/pgtools.conf
./pgtools_scheduler.sh remove
./pgtools_scheduler.sh install
```

## Troubleshooting

### Common Issues

**Permission Errors:**
```bash
# Make scripts executable
chmod +x automation/*.sh

# Check database permissions
./test_pgtools.sh --pattern "permissions*"
```

**Email Not Working:**
```bash
# Test mail command
echo "test" | mail -s "test" admin@company.com

# Check email configuration
grep EMAIL automation/pgtools.conf
```

**Cron Jobs Not Running:**
```bash
# Check cron status
./pgtools_scheduler.sh status

# View cron logs  
tail -f automation/cron.log

# Test manual execution
./pgtools_scheduler.sh run-job daily-quick
```

**Database Connection Issues:**
```bash
# Test connection
./test_pgtools.sh --pattern "connection*"

# Check configuration
psql -c "SELECT version();"
```

## Security Considerations

1. **Database Credentials**: Store securely, use .pgpass or environment variables
2. **Email Configuration**: Use encrypted SMTP when possible  
3. **File Permissions**: Restrict access to configuration files (600)
4. **Log Rotation**: Enable automated cleanup to prevent disk filling
5. **Monitoring Integration**: Use secure webhook URLs and API keys

## Performance Impact

- **Quick checks**: Minimal impact, suitable for frequent execution
- **Full checks**: Higher impact, recommended for off-peak hours  
- **Security audits**: Moderate impact, monthly execution recommended
- **Metrics export**: Low impact, can run every 30 seconds

## Support and Maintenance

- Review cron logs regularly: `automation/cron.log`
- Update retention policies in configuration
- Test backups of automation configuration
- Monitor disk space for report directories
- Validate email delivery periodically