# PostgreSQL Administration Scripts

This directory contains essential database administration utilities for PostgreSQL schema management, permission auditing, and operational maintenance. These scripts support day-to-day administrative tasks and compliance requirements.

## 📋 Table of Contents

- [Quick Reference](#quick-reference)
- [Scripts Overview](#scripts-overview)
- [Administrative Workflows](#administrative-workflows)
- [Security and Compliance](#security-and-compliance)
- [Migration Support](#migration-support)
- [Best Practices](#best-practices)

## Quick Reference

### Essential Administration Commands
```bash
# Schema and ownership analysis
psql -d mydb -f administration/table_ownership.sql     # Review table ownership
psql -d mydb -f administration/extensions.sql          # Check installed extensions
psql -d mydb -f administration/ForeignConst.sql        # Analyze foreign keys

# Partition management
psql -d mydb -f administration/partition_management.sql # Partition health check

# TimescaleDB specific (if applicable)
psql -d mydb -f administration/NonHypertables.sql      # Identify regular tables
```

### Pre-Migration Checklist
```bash
# Complete database structure analysis
./administration/pre_migration_check.sh your_database
```

## Scripts Overview

### 📋 Schema Management Scripts

#### `table_ownership.sql`
**Purpose:** Comprehensive table ownership and permission analysis
**Use Cases:**
- Security audits and compliance reviews
- Database migration planning
- Permission troubleshooting

**Sample Output:**
```
schema_name | table_name      | owner    | table_size | row_count | last_analyzed
------------|-----------------|----------|------------|-----------|---------------
public      | users          | app_user | 2.5 GB     | 1000000   | 2025-10-25 08:30:00
public      | orders         | app_user | 8.2 GB     | 2500000   | 2025-10-25 07:15:00
reporting   | user_stats     | analyst  | 156 MB     | 50000     | 2025-10-24 22:00:00
audit       | access_log     | auditor  | 12.8 GB    | 15000000  | 2025-10-25 06:00:00
```

**Key Information Provided:**
- **Table Ownership:** Current owner and schema
- **Size Metrics:** Table size and estimated row counts
- **Statistics:** Last ANALYZE timestamp for maintenance planning
- **Dependencies:** Referenced by foreign keys or views

**Administrative Actions:**
```sql
-- Change table ownership (example from script output)
ALTER TABLE public.users OWNER TO new_owner;

-- Transfer schema ownership
ALTER SCHEMA reporting OWNER TO new_owner;

-- Grant table privileges
GRANT SELECT, INSERT, UPDATE ON public.orders TO app_role;
```

#### `extensions.sql`
**Purpose:** PostgreSQL extension inventory and management
**Use Cases:**
- Environment documentation
- Migration compatibility checks
- Security compliance audits

**Sample Output:**
```
extension_name    | schema_name | version | relocatable | comment
------------------|-------------|---------|-------------|----------------------------------
plpgsql          | pg_catalog  | 1.0     | f           | PL/pgSQL procedural language
pg_stat_statements| public     | 1.9     | t           | track planning and execution statistics
uuid-ossp        | public      | 1.1     | t           | generate universally unique identifiers
postgis          | public      | 3.3.2   | f           | PostGIS geometry and geography spatial types
pg_cron          | pg_catalog  | 1.4     | f           | Job scheduler for PostgreSQL
```

**Management Actions:**
```sql
-- Install extension (requires superuser)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Upgrade extension
ALTER EXTENSION pg_stat_statements UPDATE;

-- Remove extension (use with caution)
DROP EXTENSION IF EXISTS unused_extension CASCADE;
```

**Environment Checklist:**
- **Production:** Document all installed extensions
- **Staging:** Ensure extension parity with production
- **Development:** Test extension updates before deployment

#### `ForeignConst.sql`
**Purpose:** Foreign key constraint analysis and relationship mapping
**Use Cases:**
- Database schema documentation
- Data migration planning
- Referential integrity validation

**Sample Output:**
```
constraint_name     | from_table | from_column | to_table | to_column | match_type | update_rule | delete_rule | deferrable
--------------------|------------|-------------|----------|-----------|------------|-------------|-------------|------------
fk_order_user       | orders     | user_id     | users    | id        | SIMPLE     | NO ACTION   | RESTRICT    | f
fk_order_product     | orders     | product_id  | products | id        | SIMPLE     | CASCADE     | CASCADE     | f  
fk_user_department   | users      | dept_id     | departments| id      | SIMPLE     | RESTRICT    | SET NULL    | f
fk_audit_user        | audit_log  | user_id     | users    | id        | SIMPLE     | NO ACTION   | NO ACTION   | t
```

**Relationship Analysis:**
- **CASCADE Dependencies:** Identify tables that cascade deletes/updates
- **RESTRICT Constraints:** Tables that prevent deletion of referenced rows
- **SET NULL Behavior:** Columns that accept NULL on reference deletion
- **Deferrable Constraints:** Constraints that can be deferred within transactions

**Migration Considerations:**
```sql
-- Temporarily disable constraints for data migration
ALTER TABLE orders DISABLE TRIGGER ALL;

-- Re-enable after migration with validation
ALTER TABLE orders ENABLE TRIGGER ALL;

-- Validate constraint integrity
ALTER TABLE orders VALIDATE CONSTRAINT fk_order_user;
```

### 🔧 Partition Management Scripts

#### `partition_management.sql`
**Purpose:** Comprehensive partition lifecycle management and monitoring
**Use Cases:**
- Automated partition maintenance
- Performance optimization
- Storage management

**Sample Output:**
```
schema_name | parent_table    | partition_name       | partition_type | partition_key | size_gb | row_count | creation_date | pruning_eligible
------------|-----------------|----------------------|----------------|---------------|---------|-----------|---------------|------------------
public      | sales_data     | sales_data_202510    | RANGE          | created_at    | 2.8     | 450000    | 2025-10-01    | false
public      | sales_data     | sales_data_202509    | RANGE          | created_at    | 3.2     | 520000    | 2025-09-01    | true
public      | audit_log      | audit_log_hash_1     | HASH           | user_id       | 1.2     | 180000    | 2025-08-15    | false
public      | events         | events_daily_20251025| RANGE          | event_time    | 0.8     | 95000     | 2025-10-25    | false
```

**Maintenance Operations:**
```sql
-- Create new partition (automated in script)
CREATE TABLE sales_data_202511 PARTITION OF sales_data
FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

-- Drop old partition (with data retention policy)
DROP TABLE sales_data_202507;

-- Attach existing table as partition
ALTER TABLE sales_data ATTACH PARTITION sales_archive_q1_2024
FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
```

**Automated Maintenance:**
```bash
# Weekly partition maintenance
./administration/partition_maintenance.sh --database mydb --retain-months 12

# Monthly partition analysis
psql -d mydb -f administration/partition_management.sql > partition_report_$(date +%Y%m).log
```

### 📊 TimescaleDB Administration Scripts

#### `NonHypertables.sql`
**Purpose:** Identify non-hypertables in TimescaleDB environments
**Use Cases:**
- TimescaleDB migration planning
- Performance optimization analysis
- Storage efficiency reviews

**Sample Output:**
```
schema_name | table_name      | table_type | size_gb | row_count | time_column | conversion_candidate | recommendation
------------|-----------------|------------|---------|-----------|-------------|---------------------|----------------
public      | sensor_data    | regular    | 45.2    | 50000000  | timestamp   | yes                 | Convert to hypertable
public      | user_profiles  | regular    | 2.1     | 100000    | created_at  | no                  | Keep as regular table  
public      | config_settings| regular    | 0.01    | 50        | NULL        | no                  | Keep as regular table
audit       | access_log     | regular    | 12.8    | 15000000  | log_time    | yes                 | Convert with partitioning
```

**Conversion Recommendations:**
```sql
-- Convert large time-series table to hypertable
SELECT create_hypertable('sensor_data', 'timestamp', chunk_time_interval => INTERVAL '1 day');

-- Convert with custom chunk sizing
SELECT create_hypertable('access_log', 'log_time', 
    chunk_time_interval => INTERVAL '7 days',
    number_partitions => 4);
```

**Best Practices for Conversion:**
- **Large Tables (>1GB):** Strong candidates for hypertables
- **Time-Series Data:** Tables with timestamp columns and time-based queries
- **High Insert Volume:** Tables with frequent data ingestion
- **Regular Tables:** Keep small lookup tables as regular PostgreSQL tables

## Administrative Workflows

### 1. New Database Setup Workflow
```bash
#!/bin/bash
# new_database_setup.sh

DATABASE=$1

echo "=== New Database Setup: $DATABASE ==="

# Step 1: Verify base configuration
echo "1. Checking base extensions..."
psql -d $DATABASE -f administration/extensions.sql

# Step 2: Set up ownership structure
echo "2. Analyzing initial ownership..."
psql -d $DATABASE -f administration/table_ownership.sql

# Step 3: Document schema relationships
echo "3. Mapping foreign key relationships..."
psql -d $DATABASE -f administration/ForeignConst.sql

# Step 4: Initialize partition management (if needed)
echo "4. Setting up partition monitoring..."
psql -d $DATABASE -f administration/partition_management.sql

echo "Setup complete. Review output for any configuration needs."
```

### 2. Pre-Migration Assessment
```bash
#!/bin/bash
# pre_migration_assessment.sh

SOURCE_DB=$1
TARGET_ENV=$2

echo "=== Pre-Migration Assessment: $SOURCE_DB to $TARGET_ENV ==="

# Document current state
mkdir -p migration_docs/$(date +%Y%m%d)
cd migration_docs/$(date +%Y%m%d)

# Capture schema information
echo "Documenting extensions..."
psql -d $SOURCE_DB -f ../../administration/extensions.sql > extensions_current.log

echo "Documenting ownership..."
psql -d $SOURCE_DB -f ../../administration/table_ownership.sql > ownership_current.log

echo "Documenting constraints..."
psql -d $SOURCE_DB -f ../../administration/ForeignConst.sql > constraints_current.log

# TimescaleDB assessment (if applicable)
if psql -d $SOURCE_DB -c "SELECT 1 FROM pg_extension WHERE extname='timescaledb';" -t | grep -q 1; then
    echo "Documenting TimescaleDB structure..."
    psql -d $SOURCE_DB -f ../../administration/NonHypertables.sql > timescaledb_current.log
fi

# Partition analysis
echo "Analyzing partitions..."
psql -d $SOURCE_DB -f ../../administration/partition_management.sql > partitions_current.log

echo "Assessment complete. Documentation saved to $(pwd)"
```

### 3. Monthly Administration Review
```bash
#!/bin/bash
# monthly_admin_review.sh

DATABASE=$1
REPORT_DATE=$(date +%Y%m)

echo "=== Monthly Administration Review: $DATABASE ($REPORT_DATE) ==="

mkdir -p admin_reports/$REPORT_DATE
cd admin_reports/$REPORT_DATE

# Extension inventory
echo "1. Extension inventory..."
psql -d $DATABASE -f ../../administration/extensions.sql > extensions_$REPORT_DATE.log

# Ownership analysis  
echo "2. Ownership and permissions analysis..."
psql -d $DATABASE -f ../../administration/table_ownership.sql > ownership_$REPORT_DATE.log

# Constraint health check
echo "3. Foreign key constraint validation..."
psql -d $DATABASE -f ../../administration/ForeignConst.sql > constraints_$REPORT_DATE.log

# Partition maintenance review
echo "4. Partition maintenance review..."
psql -d $DATABASE -f ../../administration/partition_management.sql > partitions_$REPORT_DATE.log

# Generate summary report
cat << EOF > admin_summary_$REPORT_DATE.md
# Monthly Administration Report - $REPORT_DATE

## Database: $DATABASE
## Report Generated: $(date)

### Key Findings
- Extensions: $(grep -c "^[^-]" extensions_$REPORT_DATE.log) installed
- Tables: $(grep -c "^[^-]" ownership_$REPORT_DATE.log) total
- Constraints: $(grep -c "^[^-]" constraints_$REPORT_DATE.log) foreign keys
- Partitions: $(grep -c "^[^-]" partitions_$REPORT_DATE.log) active

### Action Items
[ ] Review extension versions for updates
[ ] Validate table ownership compliance  
[ ] Check constraint performance impact
[ ] Plan partition maintenance schedule

EOF

echo "Monthly review complete. Reports saved to $(pwd)"
```

## Security and Compliance

### 1. Ownership Audit Workflow
```sql
-- Identify tables owned by inappropriate users
SELECT schemaname, tablename, tableowner 
FROM pg_tables 
WHERE tableowner NOT IN ('app_user', 'service_account')
AND schemaname NOT IN ('pg_catalog', 'information_schema');

-- Find objects with excessive permissions
SELECT grantee, table_schema, table_name, privilege_type
FROM information_schema.role_table_grants 
WHERE grantee = 'public'
AND table_schema NOT IN ('pg_catalog', 'information_schema');
```

### 2. Extension Security Review
```sql
-- Check for potentially dangerous extensions
SELECT extname, extversion 
FROM pg_extension 
WHERE extname IN ('dblink', 'postgres_fdw', 'file_fdw', 'adminpack');

-- Verify extension installation privileges
SELECT rolname, rolsuper, rolcreaterole, rolcreatedb 
FROM pg_roles 
WHERE rolname IN (
    SELECT distinct extowner::regrole::text 
    FROM pg_extension 
    WHERE extname NOT IN ('plpgsql')
);
```

### 3. Constraint Compliance Checks
```sql
-- Identify tables without primary keys
SELECT schemaname, tablename 
FROM pg_tables t
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
AND NOT EXISTS (
    SELECT 1 FROM pg_constraint c 
    WHERE c.conrelid = (t.schemaname||'.'||t.tablename)::regclass 
    AND c.contype = 'p'
);

-- Find foreign keys without supporting indexes
SELECT DISTINCT 
    conname as constraint_name,
    conrelid::regclass as table_name,
    array_to_string(conkey::int[], ',') as columns
FROM pg_constraint 
WHERE contype = 'f'
AND NOT EXISTS (
    SELECT 1 FROM pg_index i 
    WHERE i.indrelid = conrelid 
    AND i.indkey::text LIKE conkey::int[]::text||'%'
);
```

## Migration Support

### 1. Schema Export for Migration
```bash
#!/bin/bash
# export_schema_for_migration.sh

DATABASE=$1
EXPORT_DIR="migration_export_$(date +%Y%m%d)"

mkdir -p $EXPORT_DIR
cd $EXPORT_DIR

# Export schema structure
pg_dump -d $DATABASE -s > schema_structure.sql

# Export extension list
psql -d $DATABASE -f ../administration/extensions.sql -o extensions_list.csv

# Export ownership information
psql -d $DATABASE -f ../administration/table_ownership.sql -o ownership_mapping.csv

# Export constraint definitions
psql -d $DATABASE -f ../administration/ForeignConst.sql -o constraint_definitions.csv

# Create migration checklist
cat << EOF > migration_checklist.md
# Migration Checklist for $DATABASE

## Pre-Migration
- [ ] Review schema_structure.sql for compatibility
- [ ] Verify all extensions in extensions_list.csv are available in target
- [ ] Plan ownership mapping from ownership_mapping.csv
- [ ] Review constraint dependencies in constraint_definitions.csv

## During Migration
- [ ] Create extensions before schema import
- [ ] Import schema structure
- [ ] Set up table ownership as per mapping
- [ ] Validate all constraints after data import

## Post-Migration
- [ ] Run administration scripts to verify setup
- [ ] Update application connection strings
- [ ] Validate referential integrity
- [ ] Test application functionality

EOF

echo "Migration export complete in $EXPORT_DIR"
```

### 2. TimescaleDB Migration Planning
```bash
#!/bin/bash
# timescaledb_migration_plan.sh

DATABASE=$1

echo "=== TimescaleDB Migration Planning: $DATABASE ==="

# Check if TimescaleDB is installed
if ! psql -d $DATABASE -c "SELECT 1 FROM pg_extension WHERE extname='timescaledb';" -t | grep -q 1; then
    echo "TimescaleDB not detected. Regular PostgreSQL migration process applies."
    exit 0
fi

echo "TimescaleDB detected. Analyzing hypertable structure..."

# Document hypertables
psql -d $DATABASE -c "
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM _timescaledb_catalog.hypertable h
JOIN pg_tables t ON t.tablename = h.table_name;
" > hypertables_list.csv

# Identify conversion candidates
psql -d $DATABASE -f administration/NonHypertables.sql > conversion_candidates.csv

echo "TimescaleDB migration planning complete."
echo "Review hypertables_list.csv and conversion_candidates.csv for migration strategy."
```

## Best Practices

### 1. Regular Administrative Tasks
```bash
# Weekly ownership audit
psql -d production -f administration/table_ownership.sql > weekly_ownership_$(date +%Y%m%d).log

# Monthly extension review
psql -d production -f administration/extensions.sql > monthly_extensions_$(date +%Y%m%d).log

# Quarterly constraint analysis
psql -d production -f administration/ForeignConst.sql > quarterly_constraints_$(date +%Y%m%d).log
```

### 2. Documentation Standards
- **Maintain ownership mapping** for all database objects
- **Document extension purposes** and their business requirements  
- **Track constraint changes** and their performance impact
- **Version control** all administrative scripts and configurations

### 3. Change Management
```sql
-- Always document ownership changes
COMMENT ON TABLE users IS 'Owner changed from old_user to new_user on 2025-10-25 for security compliance';

-- Track extension installations
INSERT INTO admin_log (action, object_name, details, changed_by) 
VALUES ('EXTENSION_INSTALL', 'pg_stat_statements', 'Added for query monitoring', current_user);

-- Document constraint modifications
ALTER TABLE orders ADD CONSTRAINT fk_order_customer 
    FOREIGN KEY (customer_id) REFERENCES customers(id);
COMMENT ON CONSTRAINT fk_order_customer ON orders IS 'Added 2025-10-25 for referential integrity';
```

### 4. Security Guidelines
- **Principle of least privilege:** Grant minimum necessary permissions
- **Regular audits:** Review ownership and permissions monthly
- **Extension control:** Document business justification for all extensions
- **Constraint validation:** Ensure all foreign keys have supporting indexes

### 5. Performance Considerations
- **Monitor constraint impact** on INSERT/UPDATE operations
- **Index foreign key columns** to prevent lock contention
- **Consider deferrable constraints** for bulk operations
- **Plan partition maintenance** during low-activity periods

This administration framework provides comprehensive database management capabilities while ensuring security, compliance, and operational efficiency.