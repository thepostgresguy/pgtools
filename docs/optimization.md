# HOT Update Optimization

Use the pgtools HOT checklist utilities to spot tables with low heap-only tuple (HOT) efficiency, then export the results in the format best suited for your workflow.

## Manual SQL Execution

### Text report (interactive)
```bash
psql -d my_database -f optimization/hot_update_optimization_checklist.sql
```
This prints two sections:
- Top 50 heavily updated tables with HOT% and bloat indicators.
- Fillfactor recommendations (`ALTER TABLE ... SET (fillfactor = 90);`) for tables below 50% HOT.

### JSON-ready report
```bash
psql -d my_database -f optimization/hot_update_optimization_checklist_json.sql > hot_update_report.json
```
Outputs a single JSON document containing metadata, thresholds, table metrics, and a recommendations array. Ideal for downstream automation (e.g., iqtoolkit-analyzer).

## Automation Script

### `automation/run_hot_update_report.sh`
Single entrypoint that emits either JSON (default) or text.
```bash
# JSON export for iqtoolkit-analyzer
./automation/run_hot_update_report.sh --database my_database --format json

# Text report for quick reviews
./automation/run_hot_update_report.sh --database my_database --format text --stdout

# Custom output path
./automation/run_hot_update_report.sh --format json --output /tmp/hot.json
```
- Reads connection defaults from `automation/pgtools.conf` (PGHOST, PGPORT, PGUSER, PGDATABASE) and honors CLI/env overrides.
- JSON mode validates results via `jq` (falls back to `python3 -m json.tool`).
- Text mode mirrors the manual SQL output and can stream to stdout with `--stdout`.

**Verification commands:**
```bash
# Quick automation sanity test
./automation/test_pgtools.sh --fast

# Full automation suite (adds integration tests)
./automation/test_pgtools.sh --full --verbose

# Validate HOT checklist JSON path
./automation/run_hot_update_report.sh --format json --database my_database --stdout

# Validate HOT checklist text path
./automation/run_hot_update_report.sh --format text --database my_database --stdout

# Run the entire bundle (shellcheck + automation + HOT)
./scripts/precommit_checks.sh --database my_database
```

#### Connection configuration
1. Copy the sample config: `cp automation/pgtools.conf.example automation/pgtools.conf`.
2. Edit `automation/pgtools.conf` and set the standard libpq variables:
   ```bash
   PGHOST=db-server.example.com
   PGPORT=5432
   PGUSER=monitoring_user
   PGDATABASE=postgres    # default database used when --database is not passed
   # PGPASSWORD is optional; prefer ~/.pgpass for credentials
   ```
3. The script sources this file at runtime, so every `psql` command inherits those values automatically.

**Precedence:** command-line flags > environment variables > `pgtools.conf`. For example, running `./automation/run_hot_update_report.sh --database analytics` targets the `analytics` database while still using `PGHOST`/`PGPORT`/`PGUSER` from `pgtools.conf`. To override the server, export an environment variable before invoking the script (`PGHOST=staging-db ./automation/run_hot_update_report.sh`). If neither CLI nor environment overrides are provided, the values defined in `pgtools.conf` are used.

## iqtoolkit-analyzer Integration
1. Run `automation/run_hot_update_report.sh --format json` against the target database.
2. Copy the generated file (e.g., `reports/hot_update_20251202_101500.json`) into the analyzer repo’s intake folder (`/path/to/iqtoolkit-analyzer/samples/`).
3. Execute the analyzer:
   ```bash
   cd /path/to/iqtoolkit-analyzer
   python analyzer.py --type pg-hot-update --input samples/hot_update_20251202_101500.json
   ```
4. Review the analyzer findings alongside the fillfactor commands embedded in the JSON `recommendations` list.

## Requirements
- PostgreSQL 15+ for both the text and JSON variants.
- `pg_monitor` role or equivalent access to `pg_stat_user_tables`.
- `psql` client available on the automation host.
- Optional: `jq` for faster JSON validation.
