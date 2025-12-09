#!/bin/bash
#
# Script: export_metrics.sh  
# Purpose: Export PostgreSQL metrics for monitoring systems
# Usage: ./automation/export_metrics.sh [OPTIONS]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "[$(date '+%H:%M:%S')] ${BLUE}INFO${NC} $*"; }
warn() { echo -e "[$(date '+%H:%M:%S')] ${YELLOW}WARN${NC} $*"; }
error() { echo -e "[$(date '+%H:%M:%S')] ${RED}ERROR${NC} $*"; }
success() { echo -e "[$(date '+%H:%M:%S')] ${GREEN}SUCCESS${NC} $*"; }

# Default values
OUTPUT_FORMAT="prometheus"
OUTPUT_FILE=""
WEBHOOK_URL=""
VERBOSE="false"
INCLUDE_SLOW_QUERIES="false"

usage() {
    cat << EOF
PostgreSQL Metrics Exporter

Export PostgreSQL metrics in various formats for monitoring systems.

Usage: $0 [OPTIONS]

OPTIONS:
    -f, --format FORMAT     Output format: prometheus, grafana, json, influx
    -o, --output FILE       Output file (default: stdout)
    -w, --webhook URL       Send metrics to webhook URL
    -s, --slow-queries      Include slow query metrics
    -v, --verbose           Verbose output
    -h, --help              Show this help

FORMATS:
    prometheus    Prometheus metrics format
    grafana       Grafana dashboard JSON
    json          JSON metrics object
    influx        InfluxDB line protocol

EXAMPLES:
    $0                                          # Prometheus metrics to stdout
    $0 --format json --output metrics.json     # JSON metrics to file
    $0 --webhook http://prometheus:9091         # Push to Prometheus gateway
    $0 --format grafana > dashboard.json       # Generate Grafana dashboard

CONFIGURATION:
    Database connection settings are loaded from:
    - $SCRIPT_DIR/pgtools.conf
    - Environment variables (PGHOST, PGPORT, PGDATABASE, PGUSER)

EOF
}

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/pgtools.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1091
    # shellcheck source=pgtools.conf
    source "$CONFIG_FILE"
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -w|--webhook)
            WEBHOOK_URL="$2"
            shift 2
            ;;
        -s|--slow-queries)
            INCLUDE_SLOW_QUERIES="true"
            shift
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate format
case "$OUTPUT_FORMAT" in
    prometheus|grafana|json|influx) ;;
    *)
        error "Invalid format: $OUTPUT_FORMAT"
        exit 1
        ;;
esac

# Database connection check
check_database_connection() {
    if [[ "$VERBOSE" == "true" ]]; then
        log "Testing database connection..."
    fi
    
    if ! psql -c "SELECT version();" > /dev/null 2>&1; then
        error "Cannot connect to PostgreSQL database"
        return 1
    fi
}

# Collect basic metrics
collect_metrics() {
    local temp_file
    temp_file=$(mktemp)
    
    # Basic database metrics
    psql -t -c "
SELECT 
    'pg_up', '1',
    'pg_connections_total', (SELECT count(*) FROM pg_stat_activity),
    'pg_connections_active', (SELECT count(*) FROM pg_stat_activity WHERE state = 'active'),
    'pg_connections_idle', (SELECT count(*) FROM pg_stat_activity WHERE state = 'idle'),
    'pg_database_size_bytes', (SELECT pg_database_size(current_database())),
    'pg_transactions_total', (SELECT sum(xact_commit + xact_rollback) FROM pg_stat_database WHERE datname = current_database()),
    'pg_commits_total', (SELECT sum(xact_commit) FROM pg_stat_database WHERE datname = current_database()),
    'pg_rollbacks_total', (SELECT sum(xact_rollback) FROM pg_stat_database WHERE datname = current_database()),
    'pg_blocks_read_total', (SELECT sum(blks_read) FROM pg_stat_database WHERE datname = current_database()),
    'pg_blocks_hit_total', (SELECT sum(blks_hit) FROM pg_stat_database WHERE datname = current_database()),
    'pg_temp_files_total', (SELECT sum(temp_files) FROM pg_stat_database WHERE datname = current_database()),
    'pg_temp_bytes_total', (SELECT sum(temp_bytes) FROM pg_stat_database WHERE datname = current_database())
" | paste - - > "$temp_file"

    # Additional table metrics
    psql -t -c "
SELECT 
    'pg_table_size_bytes{table=\"' || schemaname || '.' || tablename || '\"}',
    pg_total_relation_size(schemaname||'.'||tablename)
FROM pg_tables 
WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 20;
" >> "$temp_file"

    # Lock metrics
    psql -t -c "
SELECT 
    'pg_locks_total{mode=\"' || mode || '\"}',
    count(*)
FROM pg_locks
GROUP BY mode;
" >> "$temp_file"

    # Slow queries if requested
    if [[ "$INCLUDE_SLOW_QUERIES" == "true" ]]; then
        psql -t -c "
SELECT 
    'pg_slow_queries{query_hash=\"' || md5(query) || '\"}',
    calls
FROM pg_stat_statements
WHERE mean_time > 1000
ORDER BY mean_time DESC
LIMIT 10;
" >> "$temp_file" 2>/dev/null || true
    fi

    echo "$temp_file"
}

# Format metrics for Prometheus
format_prometheus() {
    local metrics_file="$1"
    
    cat << 'EOF'
# HELP pg_up PostgreSQL server is up
# TYPE pg_up gauge
# HELP pg_connections_total Total number of connections
# TYPE pg_connections_total gauge
# HELP pg_connections_active Number of active connections
# TYPE pg_connections_active gauge
# HELP pg_connections_idle Number of idle connections
# TYPE pg_connections_idle gauge
# HELP pg_database_size_bytes Size of database in bytes
# TYPE pg_database_size_bytes gauge
# HELP pg_transactions_total Total transactions
# TYPE pg_transactions_total counter
# HELP pg_commits_total Total commits
# TYPE pg_commits_total counter
# HELP pg_rollbacks_total Total rollbacks
# TYPE pg_rollbacks_total counter
# HELP pg_blocks_read_total Total blocks read
# TYPE pg_blocks_read_total counter
# HELP pg_blocks_hit_total Total blocks hit
# TYPE pg_blocks_hit_total counter
# HELP pg_temp_files_total Total temporary files
# TYPE pg_temp_files_total counter
# HELP pg_temp_bytes_total Total temporary bytes
# TYPE pg_temp_bytes_total counter
# HELP pg_table_size_bytes Size of tables in bytes
# TYPE pg_table_size_bytes gauge
# HELP pg_locks_total Number of locks by mode
# TYPE pg_locks_total gauge
EOF

    while IFS=$'\t' read -r metric value; do
        if [[ -n "$metric" && -n "$value" ]]; then
            echo "${metric} ${value}"
        fi
    done < "$metrics_file"
}

# Format metrics for JSON
format_json() {
    local metrics_file="$1"
    
    echo "{"
    echo "  \"timestamp\": \"$(date -Iseconds)\","
    echo "  \"database\": \"${PGDATABASE:-postgres}\","
    echo "  \"host\": \"${PGHOST:-localhost}\","
    echo "  \"port\": \"${PGPORT:-5432}\","
    echo "  \"metrics\": {"
    
    local first=true
    while IFS=$'\t' read -r metric value; do
        if [[ -n "$metric" && -n "$value" ]]; then
            [[ "$first" == "false" ]] && echo ","
            echo -n "    \"$metric\": $value"
            first=false
        fi
    done < "$metrics_file"
    
    echo ""
    echo "  }"
    echo "}"
}

# Format metrics for InfluxDB
format_influx() {
    local metrics_file="$1"
    local timestamp
    timestamp=$(date +%s)000000000  # nanoseconds
    
    while IFS=$'\t' read -r metric value; do
        if [[ -n "$metric" && -n "$value" ]]; then
            echo "postgresql,host=${PGHOST:-localhost},database=${PGDATABASE:-postgres} ${metric}=${value} ${timestamp}"
        fi
    done < "$metrics_file"
}

# Generate Grafana dashboard
format_grafana() {
    cat << EOF
{
  "dashboard": {
    "id": null,
    "title": "PostgreSQL Monitoring",
    "tags": ["postgresql", "database"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Connections",
        "type": "stat",
        "targets": [
          {
            "expr": "pg_connections_total",
            "legendFormat": "Total"
          },
          {
            "expr": "pg_connections_active", 
            "legendFormat": "Active"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "palette-classic"
            }
          }
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        }
      },
      {
        "id": 2,
        "title": "Database Size",
        "type": "stat",
        "targets": [
          {
            "expr": "pg_database_size_bytes",
            "legendFormat": "Size"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "bytes"
          }
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        }
      },
      {
        "id": 3,
        "title": "Transaction Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(pg_commits_total[5m])",
            "legendFormat": "Commits/sec"
          },
          {
            "expr": "rate(pg_rollbacks_total[5m])",
            "legendFormat": "Rollbacks/sec"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 8
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF
}

# Send to webhook
send_webhook() {
    local data="$1"
    
    if [[ -z "$WEBHOOK_URL" ]]; then
        return 0
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        log "Sending metrics to webhook: $WEBHOOK_URL"
    fi
    
    if command -v curl > /dev/null 2>&1; then
        if curl -s -X POST -H "Content-Type: application/json" -d "$data" "$WEBHOOK_URL" > /dev/null; then
            success "Metrics sent to webhook successfully"
        else
            error "Failed to send metrics to webhook"
            return 1
        fi
    else
        error "curl not available for webhook"
        return 1
    fi
}

# Main execution
main() {
    if [[ "$VERBOSE" == "true" ]]; then
        log "Collecting PostgreSQL metrics in $OUTPUT_FORMAT format"
    fi
    
    check_database_connection
    
    local metrics_file
    metrics_file=$(collect_metrics)
    
    local output=""
    case "$OUTPUT_FORMAT" in
        prometheus)
            output=$(format_prometheus "$metrics_file")
            ;;
        json)
            output=$(format_json "$metrics_file")
            ;;
        influx)
            output=$(format_influx "$metrics_file")
            ;;
        grafana)
            output=$(format_grafana)
            ;;
    esac
    
    # Output to file or stdout
    if [[ -n "$OUTPUT_FILE" ]]; then
        echo "$output" > "$OUTPUT_FILE"
        if [[ "$VERBOSE" == "true" ]]; then
            success "Metrics exported to: $OUTPUT_FILE"
        fi
    else
        echo "$output"
    fi
    
    # Send to webhook if specified
    if [[ -n "$WEBHOOK_URL" ]]; then
        send_webhook "$output"
    fi
    
    rm -f "$metrics_file"
    
    if [[ "$VERBOSE" == "true" ]]; then
        success "Metrics collection completed"
    fi
}

main "$@"