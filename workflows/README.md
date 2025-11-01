# PostgreSQL Operational Workflows

For complete documentation, see [docs/workflows.md](../docs/workflows.md) or visit the [online documentation](https://gmartinez-dbai.github.io/pgtools/workflows).

## Quick Reference

This directory contains comprehensive workflow guides and procedures for:

- **Incident Response** - Critical incident and performance degradation workflows
- **Maintenance Procedures** - Daily, weekly, and monthly maintenance routines
- **Production Readiness** - Pre-deployment checklists and validation

## Quick Start

```bash
# Emergency response
./workflows/incident_response.sh --severity critical --database production

# Daily maintenance
./workflows/daily_maintenance.sh --database production --email-report

# Production readiness check
./workflows/production_readiness.sh --database staging --checklist
```

For detailed workflows, checklists, and operational procedures, please refer to the complete documentation linked above.
