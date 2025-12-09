#!/bin/bash
#
# Script: run_security_audit.sh
# Purpose: Automated security audit runner with reporting
# Usage: ./automation/run_security_audit.sh [OPTIONS]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PGTOOLS_ROOT="$(dirname "$SCRIPT_DIR")"
SECURITY_SCRIPT="$PGTOOLS_ROOT/security/permission_audit.sql"

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
OUTPUT_FORMAT="text"
OUTPUT_FILE=""
SEND_EMAIL="false"
INCLUDE_RECOMMENDATIONS="true"
VERBOSE="false"

usage() {
    cat << EOF
PostgreSQL Security Audit Runner

Usage: $0 [OPTIONS]

OPTIONS:
    -f, --format FORMAT     Output format: text, html, json (default: text)
    -o, --output FILE       Output file (default: stdout)
    -e, --email             Send results via email
    -r, --no-recommendations  Skip recommendations section
    -v, --verbose           Verbose output
    -h, --help              Show this help

EXAMPLES:
    $0                                  # Basic audit to stdout
    $0 --format html --email            # HTML report via email
    $0 -o audit.txt --verbose           # Verbose text report to file
    $0 --format json -o audit.json      # JSON report to file

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
        -e|--email)
            SEND_EMAIL="true"
            shift
            ;;
        -r|--no-recommendations)
            INCLUDE_RECOMMENDATIONS="false"
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
    text|html|json) ;;
    *)
        error "Invalid format: $OUTPUT_FORMAT"
        exit 1
        ;;
esac

# Set up output file if specified
if [[ -n "$OUTPUT_FILE" ]]; then
    OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
    if [[ ! -d "$OUTPUT_DIR" ]]; then
        mkdir -p "$OUTPUT_DIR"
    fi
fi

# Database connection check
check_database_connection() {
    if [[ "$VERBOSE" == "true" ]]; then
        log "Testing database connection..."
    fi
    
    if ! psql -c "SELECT version();" > /dev/null 2>&1; then
        error "Cannot connect to PostgreSQL database"
        error "Check connection parameters: PGHOST, PGPORT, PGDATABASE, PGUSER"
        return 1
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        success "Database connection successful"
    fi
}

# Generate HTML header
generate_html_header() {
    cat << EOF
<!DOCTYPE html>
<html>
<head>
    <title>PostgreSQL Security Audit Report</title>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; }
        h2 { color: #34495e; margin-top: 30px; }
        .header { background: #ecf0f1; padding: 20px; border-radius: 5px; }
        .critical { color: #e74c3c; font-weight: bold; }
        .warning { color: #f39c12; font-weight: bold; }
        .info { color: #3498db; }
        .success { color: #27ae60; font-weight: bold; }
        table { border-collapse: collapse; width: 100%; margin: 15px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        pre { background: #f8f9fa; padding: 15px; border-radius: 5px; overflow-x: auto; }
        .timestamp { font-size: 0.9em; color: #7f8c8d; }
    </style>
</head>
<body>
    <div class="header">
        <h1>PostgreSQL Security Audit Report</h1>
        <p class="timestamp">Generated: $(date)</p>
        <p>Database: ${PGDATABASE:-default}</p>
        <p>Host: ${PGHOST:-localhost}:${PGPORT:-5432}</p>
    </div>
EOF
}

# Generate JSON header
generate_json_header() {
    cat << EOF
{
    "audit_report": {
        "metadata": {
            "generated": "$(date -Iseconds)",
            "database": "${PGDATABASE:-default}",
            "host": "${PGHOST:-localhost}",
            "port": "${PGPORT:-5432}",
            "format": "json"
        },
        "results": [
EOF
}

# Run security audit
run_audit() {
    local temp_output
    temp_output=$(mktemp)
    
    if [[ "$VERBOSE" == "true" ]]; then
        log "Running security audit..."
    fi

    if [[ "$INCLUDE_RECOMMENDATIONS" != "true" ]]; then
        log "Recommendations section disabled for this run"
    fi
    
    # Execute the security audit SQL
    if ! psql -f "$SECURITY_SCRIPT" > "$temp_output" 2>&1; then
        error "Security audit failed"
        cat "$temp_output"
        rm -f "$temp_output"
        return 1
    fi
    
    # Process output based on format
    case "$OUTPUT_FORMAT" in
        text)
            if [[ -n "$OUTPUT_FILE" ]]; then
                {
                    echo "PostgreSQL Security Audit Report"
                    echo "Generated: $(date)"
                    echo "Database: ${PGDATABASE:-default}"
                    echo "Host: ${PGHOST:-localhost}:${PGPORT:-5432}"
                    echo "========================================"
                    echo
                    cat "$temp_output"
                } > "$OUTPUT_FILE"
            else
                echo "PostgreSQL Security Audit Report"
                echo "Generated: $(date)"
                echo "========================================"
                echo
                cat "$temp_output"
            fi
            ;;
        html)
            {
                generate_html_header
                echo "<pre>"
                cat "$temp_output" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
                echo "</pre>"
                echo "</body></html>"
            } > "${OUTPUT_FILE:-/dev/stdout}"
            ;;
        json)
            {
                generate_json_header
                echo "{"
                echo "\"audit_output\": ["
                # Convert text output to JSON array
                cat "$temp_output" | sed 's/"/\\"/g' | sed 's/^/"/; s/$/",/' | sed '$ s/,$//'
                echo "]"
                echo "}"
                echo "]"
                echo "}"
                echo "}"
            } > "${OUTPUT_FILE:-/dev/stdout}"
            ;;
    esac
    
    rm -f "$temp_output"
    
    if [[ "$VERBOSE" == "true" ]]; then
        success "Security audit completed"
    fi
}

# Send email notification
send_email_notification() {
    if [[ "$SEND_EMAIL" != "true" ]] || [[ -z "${PGTOOLS_EMAIL_TO:-}" ]]; then
        return 0
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        log "Sending email notification..."
    fi
    
    local subject
    subject="PostgreSQL Security Audit Report - $(date +%Y-%m-%d)"
    local email_body
    email_body="PostgreSQL Security Audit completed.

Database: ${PGDATABASE:-default}
Host: ${PGHOST:-localhost}:${PGPORT:-5432}
Report generated: $(date)

Please see attached report for details."
    
    if command -v mail > /dev/null 2>&1; then
        if [[ -n "$OUTPUT_FILE" ]]; then
            echo "$email_body" | mail -s "$subject" -A "$OUTPUT_FILE" "${PGTOOLS_EMAIL_TO}"
        else
            echo "$email_body" | mail -s "$subject" "${PGTOOLS_EMAIL_TO}"
        fi
        success "Email sent to ${PGTOOLS_EMAIL_TO}"
    elif command -v mutt > /dev/null 2>&1; then
        if [[ -n "$OUTPUT_FILE" ]]; then
            echo "$email_body" | mutt -s "$subject" -a "$OUTPUT_FILE" -- "${PGTOOLS_EMAIL_TO}"
        else
            echo "$email_body" | mutt -s "$subject" "${PGTOOLS_EMAIL_TO}"
        fi
        success "Email sent to ${PGTOOLS_EMAIL_TO}"
    else
        warn "No mail command available (mail, mutt)"
    fi
}

# Main execution
main() {
    if [[ "$VERBOSE" == "true" ]]; then
        log "Starting PostgreSQL security audit"
        log "Format: $OUTPUT_FORMAT"
        [[ -n "$OUTPUT_FILE" ]] && log "Output file: $OUTPUT_FILE"
    fi
    
    check_database_connection
    run_audit
    send_email_notification
    
    if [[ "$VERBOSE" == "true" ]]; then
        success "Security audit completed successfully"
    fi
}

main "$@"