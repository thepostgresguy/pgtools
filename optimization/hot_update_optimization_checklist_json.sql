/*
 * Script: hot_update_optimization_checklist_json.sql
 * Purpose: Emit the HOT update checklist results as a single JSON document
 *
 * Usage:
 *   psql -d database_name -f optimization/hot_update_optimization_checklist_json.sql
 *
 * Example (psql + jq):
 *   psql -d iqtoolkit_test -Xq -f optimization/hot_update_optimization_checklist_json.sql \
 *     | jq -r '.recommendations[] | {table_name, current_fillfactor, issue, action}'
 *
 * Notes on flags:
 *   -Xq avoids ~/.psqlrc side effects and suppresses extra psql output.
 *   This script also sets QUIET/tuples_only/unaligned/footer-off to keep output strict JSON.
 *
 * Requirements:
 *   - PostgreSQL 9.3+
 *   - Privileges: pg_monitor role or pg_stat_all_tables access
 *   - Optional: jq (only needed for the example pipeline above)
 *
 * Output:
 *   JSON document with:
 *     - database metadata
 *     - thresholds used in this report
 *     - full table metrics array
 *     - fillfactor recommendation list
 *
 * Notes:
 *   - Mirrors optimization/hot_update_optimization_checklist.sql logic
 *   - Designed for downstream automation (CSV/JSON pipeline no longer required)
 */

\set QUIET 1
\pset pager off

\pset tuples_only on
\pset format unaligned
\pset footer off

WITH settings AS (
    SELECT
        100::bigint AS minimum_updates,
        0.50::double precision AS low_hot_ratio,
        0.30::double precision AS critical_hot_ratio
),
base_stats AS (
    SELECT
        st.schemaname || '.' || st.relname AS table_name,
        st.n_tup_upd AS total_updates,
        st.n_tup_hot_upd AS hot_updates,
        CAST(ROUND(
            CASE WHEN st.n_tup_upd > 0 THEN 100.0 * st.n_tup_hot_upd / st.n_tup_upd ELSE 0 END,
            2
        ) AS double precision) AS hot_update_percent,
        st.n_tup_upd - st.n_tup_hot_upd AS non_hot_updates,
        COALESCE(
            (
                SELECT substring(opt from 'fillfactor=([0-9]+)')::int
                FROM unnest(c.reloptions) AS opt
                WHERE opt LIKE 'fillfactor=%'
                LIMIT 1
            ),
            100
        ) AS current_fillfactor,
        pg_relation_size(st.relid) AS table_size_bytes,
        pg_size_pretty(pg_relation_size(st.relid)) AS table_size_pretty,
        st.seq_scan + st.idx_scan AS total_scans,
        now() AT TIME ZONE 'UTC' AS collected_at
    FROM pg_stat_user_tables st
    JOIN pg_class c ON c.oid = st.relid
    CROSS JOIN settings
    WHERE st.n_tup_upd > settings.minimum_updates
    ORDER BY
        CASE WHEN st.n_tup_upd > 0 THEN st.n_tup_hot_upd::float / st.n_tup_upd ELSE 1 END ASC,
        st.n_tup_upd DESC
    LIMIT 50
),
table_payload AS (
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'table_name', table_name,
                'total_updates', total_updates,
                'hot_updates', hot_updates,
                'hot_update_percent', hot_update_percent,
                'non_hot_updates', non_hot_updates,
                'current_fillfactor', current_fillfactor,
                'table_size_bytes', table_size_bytes,
                'table_size', table_size_pretty,
                'total_scans', total_scans,
                'risk_level', CASE
                    WHEN hot_update_percent < 30 THEN 'high'
                    WHEN hot_update_percent < 50 THEN 'medium'
                    ELSE 'info'
                END,
                'recommended_fillfactor', CASE
                    WHEN hot_update_percent < 30 THEN 80
                    WHEN hot_update_percent < 50 THEN 90
                    ELSE NULL
                END,
                'collected_at', to_char(collected_at, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
            )
        ), '[]'::jsonb
    ) AS data
    FROM base_stats
),
recommendations AS (
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'table_name', table_name,
                'issue', 'Low HOT update percentage',
                'action', format(
                    'ALTER TABLE %s SET (fillfactor = %s);',
                    table_name,
                    CASE WHEN hot_update_percent < 30 THEN 80 ELSE 90 END
                ),
                'hot_update_percent', hot_update_percent,
                'current_fillfactor', current_fillfactor,
                'recommended_fillfactor', CASE
                    WHEN hot_update_percent < 30 THEN 80
                    ELSE 90
                END,
                'suggested_command', format(
                    'ALTER TABLE %s SET (fillfactor = %s);',
                    table_name,
                    CASE WHEN hot_update_percent < 30 THEN 80 ELSE 90 END
                )
            )
        ), '[]'::jsonb
    ) AS data
    FROM base_stats, settings
    WHERE hot_update_percent < settings.low_hot_ratio * 100
),
report AS (
    SELECT jsonb_pretty(
        jsonb_build_object(
            'database', current_database(),
            'extracted_at', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'thresholds', jsonb_build_object(
                'minimum_updates', (SELECT minimum_updates FROM settings),
                'low_hot_percent', (SELECT low_hot_ratio * 100 FROM settings),
                'critical_hot_percent', (SELECT critical_hot_ratio * 100 FROM settings)
            ),
            'tables', (SELECT data FROM table_payload),
            'recommendations', (SELECT data FROM recommendations)
        )
    ) AS body
)
SELECT body FROM report;
