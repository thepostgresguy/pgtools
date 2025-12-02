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
- PostgreSQL 9.0+ for the text report; 9.3+ for the JSON variant (uses `jsonb`).
- `pg_monitor` role or equivalent access to `pg_stat_user_tables`.
- `psql` client available on the automation host.
- Optional: `jq` for faster JSON validation.
