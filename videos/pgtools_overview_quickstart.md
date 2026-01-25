# Video Script: pgtools Overview & Quickstart (2–3 minutes)

## Hook (0:00–0:10)
- "Managing Postgres at scale? Here’s a ready-to-use toolkit to audit, monitor, and tune in minutes."

## What pgtools is (0:10–0:30)
- Brief: open-source toolkit of SQL + shell utilities for monitoring, maintenance, optimization.
- Mention tested baseline: PostgreSQL 15+.

## Quick setup (0:30–1:05)
- Clone repo: `git clone https://github.com/thepostgresguy/pgtools.git && cd pgtools`.
- Show structure: highlight `monitoring/`, `maintenance/`, `optimization/`, `automation/`.
- Note privileges: most scripts need `pg_monitor` or superuser.

## Fast demo: health snapshot (1:05–1:50)
- Run multi-check: `./automation/pgtools_health_check.sh --database your_db` (show that it emits HTML/JSON/text).
- Mention optional scheduler: `./automation/pgtools_scheduler.sh install` for cron-style runs.
- Call out config example: `automation/pgtools.conf.example`.

## Highlighted utilities (1:50–2:30)
- `monitoring/bloating.sql`: find table/index bloat with actions.
- `optimization/missing_indexes.sql`: surface missing indexes quickly.
- `maintenance/auto_maintenance.sh`: VACUUM/ANALYZE/REINDEX with thresholds and dry-run.
- `optimization/hot_update_optimization_checklist_json.sql`: HOT efficiency with JSON output for pipelines.

## CTA (2:30–2:50)
- "Grab the repo, point it at a test database, and run the health check. Links in description."