# pgtools

A collection of SQL scripts and utilities for monitoring, troubleshooting, and maintaining PostgreSQL databases.

## 📚 Documentation

The complete documentation is available in the [docs directory](docs/) and on [GitHub Pages](https://gmartinez-dbai.github.io/pgtools/).

### Quick Links

- [Main Documentation](docs/index.md) - Complete guide and script reference
- [Monitoring Guide](docs/monitoring.md) - Database health and performance monitoring
- [Automation Framework](docs/automation.md) - Automated operations and scheduling
- [Maintenance Guide](docs/maintenance.md) - Database maintenance and optimization
- [Administration Guide](docs/administration.md) - Schema management and permissions
- [Workflows](docs/workflows.md) - Operational workflows and procedures
- [Transaction Wraparound](docs/transaction-wraparound.md) - Preventing transaction wraparound

## Quick Start

```bash
# Clone the repository
git clone https://github.com/gmartinez-dbai/pgtools.git
cd pgtools

# Connect to your database and run a script
psql -U username -d database_name -f monitoring/locks.sql
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
