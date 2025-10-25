/*
 * Script: ForeignConst.sql
 * Purpose: List all foreign key constraints with detailed relationship information
 *
 * Usage:
 *   psql -d database_name -f administration/ForeignConst.sql
 *
 * Requirements:
 *   - PostgreSQL 8.0+
 *   - Privileges: Any user (can see constraints on accessible tables)
 *
 * Output:
 *   - Constraint name
 *   - Source table (child)
 *   - Source columns
 *   - Referenced table (parent)
 *   - Referenced columns
 *   - ON DELETE action
 *   - ON UPDATE action
 *
 * Notes:
 *   - Essential for understanding table relationships
 *   - Helps with schema documentation and ERD generation
 *   - Useful before dropping tables to check dependencies
 *   - Shows cascade rules for referential integrity
 */

SELECT
    tc.constraint_name,
    tc.table_schema || '.' || tc.table_name AS source_table,
    kcu.column_name AS source_column,
    ccu.table_schema || '.' || ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    rc.delete_rule AS on_delete,
    rc.update_rule AS on_update
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
    AND tc.table_schema = rc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_schema, tc.table_name, tc.constraint_name;