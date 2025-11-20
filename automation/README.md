# PostgreSQL Tools Automation Framework

For complete documentation, see [docs/automation.md](../docs/automation.md) or visit the [online documentation](https://gmartinez-dbai.github.io/pgtools/automation).

## Quick Reference

This directory contains automation scripts for pgtools:

- `pgtools_health_check.sh` - Comprehensive health check automation
- `pgtools_scheduler.sh` - Cron job management and scheduling
- `run_security_audit.sh` - Automated security audit runner
- `cleanup_reports.sh` - Report cleanup and log rotation
- `export_metrics.sh` - Metrics export for monitoring systems
- `test_pgtools.sh` - Testing framework and validation
- `pgtools.conf.example` - Configuration template

## Quick Start

```bash
# Configure automation
cp automation/pgtools.conf.example automation/pgtools.conf

# Install automated monitoring
./automation/pgtools_scheduler.sh install
```

For detailed usage and configuration options, please refer to the complete documentation linked above.
