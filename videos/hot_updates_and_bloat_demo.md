# Video Script: Fixing HOT Updates & Bloat with pgtools (3–4 minutes)

## Hook (0:00–0:12)
- "Is Postgres slowing down from bloat and cold updates? Let’s spot the issues and fix them fast with pgtools."

## Context (0:12–0:35)
- Audience: DBAs/devs on PostgreSQL 15+.
- Goal: identify HOT update inefficiency and table bloat, then plan fillfactor/VACUUM actions.

## Part 1: HOT update checklist (0:35–1:35)
- Command: `psql -d your_db -Xq -f optimization/hot_update_optimization_checklist_json.sql \` 
  `  | jq -r '.recommendations[] | {table_name, current_fillfactor, issue, action}'`.
- Explain outputs: table, current_fillfactor, suggested fillfactor (80/90), action command.
- Note thresholds: focuses on tables with low HOT%, recommends fillfactor tweak.

## Part 2: Bloat scan (1:35–2:25)
- Command: `psql -d your_db -f monitoring/bloating.sql`.
- What to watch: `dead_tuple_percent`, `dead_tuples`, last vacuum/autovacuum.
- Quick filter: `... | awk '$6 > 20 {print}'` to surface heavier bloat.

## Part 3: Plan actions (2:25–3:10)
- Apply fillfactor recs: `ALTER TABLE ... SET (fillfactor = 80);` then `VACUUM (ANALYZE) ...`.
- For high bloat: schedule `VACUUM (FULL, ANALYZE)` in a maintenance window.
- Suggest rerun after changes to confirm improvements.

## Wrap (3:10–3:40)
- Recap: one JSON-driven HOT report + one bloat scan gives actionable steps.
- CTA: "Clone pgtools, run the two commands on staging, and lock in wins before production."