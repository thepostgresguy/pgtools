# Changelog

All notable changes to pgtools will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive README with usage examples and best practices
- Standardized header comments for all SQL scripts including:
  - Purpose and description
  - Usage instructions
  - PostgreSQL version requirements
  - Required privileges
  - Output description
  - Important notes and warnings
- This CHANGELOG file to track project changes
- Script organization into logical folder structure

### Changed
- Reorganized scripts into logical folders:
  - `administration/` - Database administration scripts (extensions, ownership, constraints)
  - `maintenance/` - WAL file management and maintenance utilities
  - `monitoring/` - Performance and health monitoring (locks, bloat, replication)
  - `optimization/` - Performance optimization tools (HOT updates)
  - `troubleshooting/` - Diagnostic queries and troubleshooting packs

### Improved
- Documentation clarity across all scripts
- Consistent formatting and comment style
- Better categorization for easier script discovery

## [1.0.0] - 2025-10-25

### Added

#### Administration Scripts
- `extensions.sql` - List installed PostgreSQL extensions
- `table_ownership.sql` - Display table ownership information
- `ForeignConst.sql` - Show foreign key constraints and relationships
- `NonHypertables.sql` - Identify non-hypertable tables (TimescaleDB specific)

#### Monitoring Scripts
- `bloating.sql` - Detect table and index bloat
- `buffer_troubleshoot.sql` - Analyze shared buffer usage and cache hit ratios
- `locks.sql` - Display current database locks
- `postgres_locking_blocking.sql` - Advanced lock analysis with blocking relationships
- `replication.sql` - Monitor replication lag and slot status
- `txid.sql` - Monitor transaction ID usage and wraparound risk

#### Maintenance Scripts
- `switch_pg_wal_file.sql` - Force WAL file switching
- `walfile_in_use.sql` - Display currently active WAL files
- Transaction wraparound monitoring utilities

#### Optimization Scripts
- `hot_update_optimization_checklist.sql` - Identify HOT update optimization opportunities

#### Troubleshooting Scripts
- `postgres_troubleshooting_queries.sql` - Collection of diagnostic queries
- `postgres_troubleshooting_query_pack_01.sql` - Basic diagnostics pack
- `postgres_troubleshooting_query_pack_02.sql` - Intermediate diagnostics pack
- `postgres_troubleshooting_query_pack_03.sql` - Advanced diagnostics pack
- `postgres_troubleshooting_cheat_sheet.txt` - Quick reference guide

### Technical Details
- Minimum PostgreSQL version: 8.0 (some scripts require 9.0+, 10+, or specific versions)
- Most monitoring scripts require `pg_monitor` role or superuser privileges
- Maintenance scripts generally require superuser privileges
- Some scripts require extensions (e.g., `pg_buffercache`)

---

## Version History

- **1.0.0** (2025-10-25) - Initial organized release with folder structure and basic scripts
- **Unreleased** - Added comprehensive documentation, standardized headers, and this changelog

## Upgrade Notes

### Unreleased → 1.0.0
No breaking changes. Scripts have been reorganized into folders, so update any automation or documentation to reference the new paths:
- Old: `bloating.sql`
- New: `monitoring/bloating.sql`

## Future Plans

### Planned Features
- [ ] Automated testing framework
- [ ] Docker container for easy testing
- [ ] Additional replication monitoring for logical replication
- [ ] Query performance analysis scripts
- [ ] Partition management utilities
- [ ] Backup and recovery scripts
- [ ] Connection pooling analysis
- [ ] Index usage and recommendation scripts

### Under Consideration
- Web dashboard for visualizing metrics
- Prometheus exporter compatibility
- GitHub Actions for automated testing
- Example cron job configurations
- Integration with monitoring tools (Grafana, Nagios, etc.)

## Contributing

See README.md for contribution guidelines. When adding new scripts:
1. Place in appropriate folder
2. Add standardized header comment
3. Update CHANGELOG.md under [Unreleased]
4. Update README.md with script description
5. Test on supported PostgreSQL versions

## Support

For issues, questions, or contributions, please open an issue in the repository.