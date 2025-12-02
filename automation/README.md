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
- `run_hot_update_report.sh` - HOT update checklist (text or JSON, reads connection defaults from pgtools.conf)
- `scripts/precommit_checks.sh` - Local helper mirroring CI sanity checks
- `pgtools.conf.example` - Configuration template

## Quick Start

```bash
# Configure automation
cp automation/pgtools.conf.example automation/pgtools.conf

# Install automated monitoring
./automation/pgtools_scheduler.sh install
```

For detailed usage and configuration options, please refer to the complete documentation linked above.

## Verification commands

Run these before committing changes to automation scripts or HOT reporting logic:

```bash
# Quick sanity check (connection, syntax, permissions)
./automation/test_pgtools.sh --fast

# Full automation suite with integration tests
./automation/test_pgtools.sh --full --verbose

# Verify HOT JSON workflow
./automation/run_hot_update_report.sh --format json --database my_database --stdout

# Verify HOT text workflow
./automation/run_hot_update_report.sh --format text --database my_database --stdout

# Full local bundle (shellcheck + automation + HOT)
./scripts/precommit_checks.sh --database my_database
```

## Connection configuration

Most automation scripts, including `run_hot_update_report.sh`, source `automation/pgtools.conf` for their database settings.

1. Copy the template: `cp automation/pgtools.conf.example automation/pgtools.conf`.
2. Populate standard libpq variables (PGHOST, PGPORT, PGUSER, PGDATABASE, optional PGPASSWORD or ~/.pgpass).
3. Override as needed:
	- Command-line flags have highest priority (`--database analytics`).
	- Environment variables (e.g., `PGHOST=staging-db`) override the config.
	- Values in `pgtools.conf` act as defaults when nothing else is provided.

This precedence keeps existing automation jobs stable while still letting ad-hoc runs target alternate servers or databases.
