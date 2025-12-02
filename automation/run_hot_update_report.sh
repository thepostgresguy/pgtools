#!/bin/bash
# run_hot_update_report.sh
# Generates HOT update checklist in text or JSON format
# Wraps optimization/hot_update_optimization_checklist.sql and *_json.sql

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PGTOOLS_ROOT="$(dirname "$SCRIPT_DIR")"
SQL_TEXT="$PGTOOLS_ROOT/optimization/hot_update_optimization_checklist.sql"
SQL_JSON="$PGTOOLS_ROOT/optimization/hot_update_optimization_checklist_json.sql"
REPORT_DIR="$PGTOOLS_ROOT/reports"
CONFIG_FILE="$SCRIPT_DIR/pgtools.conf"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "[$(date '+%H:%M:%S')] ${BLUE}INFO${NC} $*"; }
warn() { echo -e "[$(date '+%H:%M:%S')] ${YELLOW}WARN${NC} $*"; }
error() { echo -e "[$(date '+%H:%M:%S')] ${RED}ERROR${NC} $*"; }
success() { echo -e "[$(date '+%H:%M:%S')] ${GREEN}SUCCESS${NC} $*"; }

usage() {
    cat <<'EOF'
Usage: ./automation/run_hot_update_report.sh [OPTIONS]

Options:
  -f, --format FORMAT    Output format: json (default) or text
  -d, --database NAME    Target database (defaults to PGDATABASE or postgres)
  -o, --output FILE      Custom output path (default: reports/hot_update_<ts>.json|txt)
  -s, --stdout           Print report to stdout after generation
  -q, --quiet            Skip helper text
  -h, --help             Show this help

Connection precedence:
    CLI flags > environment variables (PGHOST, PGPORT, PGUSER, PGDATABASE, PGPASSWORD)
    > automation/pgtools.conf defaults.
EOF
}

[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

FORMAT="json"
DB_NAME="${PGDATABASE:-postgres}"
OUTPUT_FILE=""
ALSO_STDOUT="false"
QUIET="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--format)
            FORMAT="${2,,}"
            shift 2
            ;;
        -d|--database)
            DB_NAME="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -s|--stdout)
            ALSO_STDOUT="true"
            shift
            ;;
        -q|--quiet)
            QUIET="true"
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

case "$FORMAT" in
    json|text) ;;
    *)
        error "Invalid format: $FORMAT"
        exit 1
        ;;
esac

SQL_FILE="$SQL_JSON"
EXT="json"
if [[ "$FORMAT" == "text" ]]; then
    SQL_FILE="$SQL_TEXT"
    EXT="txt"
fi

if [[ ! -f "$SQL_FILE" ]]; then
    error "SQL file not found: $SQL_FILE"
    exit 1
fi

mkdir -p "$REPORT_DIR"
if [[ -z "$OUTPUT_FILE" ]]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_FILE="$REPORT_DIR/hot_update_${TIMESTAMP}.$EXT"
fi
mkdir -p "$(dirname "$OUTPUT_FILE")"

log "Running HOT checklist ($FORMAT) against database: $DB_NAME"
TEMP_LOG="$OUTPUT_FILE.log"
if ! psql -v ON_ERROR_STOP=1 -d "$DB_NAME" -f "$SQL_FILE" > "$OUTPUT_FILE" 2>"$TEMP_LOG"; then
    error "psql execution failed"
    warn "See $TEMP_LOG for details"
    rm -f "$OUTPUT_FILE"
    exit 1
fi
rm -f "$TEMP_LOG"

if [[ "$FORMAT" == "json" ]]; then
    if command -v jq >/dev/null 2>&1; then
        log "Validating JSON with jq"
        if ! jq empty "$OUTPUT_FILE"; then
            error "Invalid JSON payload"
            rm -f "$OUTPUT_FILE"
            exit 1
        fi
    else
        log "jq not found; using python3 -m json.tool"
        if ! python3 -m json.tool "$OUTPUT_FILE" >/dev/null; then
            error "Invalid JSON payload"
            rm -f "$OUTPUT_FILE"
            exit 1
        fi
    fi
fi

success "Report saved: $OUTPUT_FILE"

if [[ "$ALSO_STDOUT" == "true" ]]; then
    cat "$OUTPUT_FILE"
fi

if [[ "$FORMAT" == "json" && "$QUIET" == "false" ]]; then
    cat <<EOF
Next steps:
  1. Copy to iqtoolkit-analyzer:
     cp "$OUTPUT_FILE" /path/to/iqtoolkit-analyzer/samples/
  2. Run analyzer:
     cd /path/to/iqtoolkit-analyzer
     python analyzer.py --type pg-hot-update --input samples/$(basename "$OUTPUT_FILE")
EOF
fi

exit 0
