#!/bin/bash
#
# Script: test_pgtools.sh
# Purpose: Test runner and validation for pgtools scripts
# Usage: ./automation/test_pgtools.sh [OPTIONS]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PGTOOLS_ROOT="$(dirname "$SCRIPT_DIR")"

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

# Test results tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Default values
RUN_FAST="false"
RUN_FULL="false" 
TEST_PATTERN="*"
VERBOSE="false"

usage() {
    cat << EOF
PostgreSQL Tools Testing Framework

Usage: $0 [OPTIONS]

OPTIONS:
    --fast              Run fast tests only (connection, syntax)
    --full              Run full test suite including database operations
    -p, --pattern GLOB  Test pattern to run (default: all tests)
    -v, --verbose       Verbose test output
    -h, --help          Show this help

TEST CATEGORIES:
    connection          Database connection tests
    syntax              SQL syntax validation
    permissions         Permission requirement checks
    automation          Automation script tests
    integration         End-to-end integration tests

EXAMPLES:
    $0 --fast                       # Quick validation tests
    $0 --full                       # Complete test suite
    $0 --pattern "connection*"      # Only connection tests
    $0 --verbose --full             # Full tests with verbose output

CONFIGURATION:
    Database connection settings are loaded from:
    - $SCRIPT_DIR/pgtools.conf
    - Environment variables (PGHOST, PGPORT, PGDATABASE, PGUSER)

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fast)
            RUN_FAST="true"
            shift
            ;;
        --full)
            RUN_FULL="true"
            shift
            ;;
        -p|--pattern)
            TEST_PATTERN="$2"
            shift 2
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

# If neither fast nor full specified, default to fast
if [[ "$RUN_FAST" == "false" && "$RUN_FULL" == "false" ]]; then
    RUN_FAST="true"
fi

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/pgtools.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1091
    # shellcheck source=pgtools.conf
    source "$CONFIG_FILE"
fi

# Test execution framework
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    if [[ "$TEST_PATTERN" != "*" ]] && [[ ! "$test_name" == "$TEST_PATTERN" ]]; then
        return 0
    fi
    
    ((TESTS_RUN++))
    
    if [[ "$VERBOSE" == "true" ]]; then
        log "Running test: $test_name"
    fi
    
    if $test_function; then
        ((TESTS_PASSED++))
        success "✓ $test_name"
    else
        ((TESTS_FAILED++))
        error "✗ $test_name"
    fi
}

# Connection tests
test_database_connection() {
    psql -c "SELECT version();" > /dev/null 2>&1
}

test_database_permissions() {
    # Test basic read permissions
    psql -c "SELECT count(*) FROM pg_stat_activity;" > /dev/null 2>&1
}

test_extensions_available() {
    # Check if common extensions are available
    local extensions=("pg_stat_statements")
    
    for ext in "${extensions[@]}"; do
        if ! psql -t -c "SELECT 1 FROM pg_available_extensions WHERE name = '$ext';" | grep -q 1; then
            if [[ "$VERBOSE" == "true" ]]; then
                warn "Extension not available: $ext"
            fi
        fi
    done
    return 0  # Don't fail if extensions missing
}

# Syntax validation tests
test_sql_syntax() {
    local sql_files=(
        "$PGTOOLS_ROOT/backup/backup_validation.sql"
        "$PGTOOLS_ROOT/security/permission_audit.sql"
        "$PGTOOLS_ROOT/monitoring/connection_pools.sql"
        "$PGTOOLS_ROOT/optimization/missing_indexes.sql"
        "$PGTOOLS_ROOT/administration/partition_management.sql"
    )
    
    for sql_file in "${sql_files[@]}"; do
        if [[ -f "$sql_file" ]]; then
            if ! psql -f "$sql_file" --dry-run > /dev/null 2>&1; then
                # Dry run not supported, try syntax check
                if ! psql -c "\\i $sql_file" > /dev/null 2>&1; then
                    error "SQL syntax error in: $sql_file"
                    return 1
                fi
            fi
        else
            warn "SQL file not found: $sql_file"
        fi
    done
    return 0
}

test_automation_scripts() {
    local scripts=(
        "$SCRIPT_DIR/pgtools_health_check.sh"
        "$SCRIPT_DIR/pgtools_scheduler.sh"
        "$SCRIPT_DIR/run_security_audit.sh"
        "$SCRIPT_DIR/cleanup_reports.sh"
        "$SCRIPT_DIR/export_metrics.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if ! bash -n "$script"; then
                error "Bash syntax error in: $script"
                return 1
            fi
        else
            warn "Script not found: $script"
        fi
    done
    return 0
}

test_configuration_files() {
    local config_files=(
        "$SCRIPT_DIR/pgtools.conf.example"
    )
    
    for config_file in "${config_files[@]}"; do
        if [[ -f "$config_file" ]]; then
            # Test if config file can be sourced
            if ! bash -c "source $config_file"; then
                error "Configuration file has errors: $config_file"
                return 1
            fi
        else
            warn "Config file not found: $config_file"
        fi
    done
    return 0
}

# Permission requirement tests
test_monitoring_permissions() {
    # Test if we can access monitoring views
    local required_views=(
        "pg_stat_activity"
        "pg_stat_database" 
        "pg_locks"
    )
    
    for view in "${required_views[@]}"; do
        if ! psql -c "SELECT 1 FROM $view LIMIT 1;" > /dev/null 2>&1; then
            error "Cannot access required view: $view"
            return 1
        fi
    done
    return 0
}

test_backup_permissions() {
    # Test backup-related permissions
    if ! psql -c "SELECT pg_is_in_recovery();" > /dev/null 2>&1; then
        return 1
    fi
    return 0
}

# Integration tests (only run with --full)
test_health_check_integration() {
    if [[ "$RUN_FULL" != "true" ]]; then
        return 0
    fi
    
    local health_script="$SCRIPT_DIR/pgtools_health_check.sh"
    if [[ -x "$health_script" ]]; then
        if ! "$health_script" --dry-run --quick > /dev/null 2>&1; then
            return 1
        fi
    else
        return 1
    fi
    return 0
}

test_metrics_export_integration() {
    if [[ "$RUN_FULL" != "true" ]]; then
        return 0
    fi
    
    local metrics_script="$SCRIPT_DIR/export_metrics.sh"
    if [[ -x "$metrics_script" ]]; then
        local temp_output
        temp_output=$(mktemp)
        if "$metrics_script" --format json > "$temp_output" 2>&1; then
            # Validate JSON output
            if command -v python3 > /dev/null 2>&1; then
                if ! python3 -m json.tool < "$temp_output" > /dev/null 2>&1; then
                    rm -f "$temp_output"
                    return 1
                fi
            fi
            rm -f "$temp_output"
            return 0
        else
            rm -f "$temp_output"
            return 1
        fi
    fi
    return 1
}

# Report generation
generate_test_report() {
    echo
    echo "==============================================="
    echo "PostgreSQL Tools Test Report"
    echo "==============================================="
    echo "Tests run: $TESTS_RUN"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo "Success rate: $(( TESTS_PASSED * 100 / TESTS_RUN ))%"
    echo "==============================================="
    
    if [[ "$TESTS_FAILED" -gt 0 ]]; then
        error "Some tests failed"
        return 1
    else
        success "All tests passed"
        return 0
    fi
}

# Main test execution
main() {
    log "Starting pgtools test suite"
    
    if [[ "$RUN_FAST" == "true" ]]; then
        log "Running fast tests (connection and syntax validation)"
    fi
    
    if [[ "$RUN_FULL" == "true" ]]; then
        log "Running full test suite (including integration tests)"
    fi
    
    # Connection tests
    run_test "connection_basic" test_database_connection
    run_test "connection_permissions" test_database_permissions
    run_test "connection_extensions" test_extensions_available
    
    # Syntax tests
    run_test "syntax_sql_files" test_sql_syntax
    run_test "syntax_automation_scripts" test_automation_scripts
    run_test "syntax_configuration" test_configuration_files
    
    # Permission tests
    run_test "permissions_monitoring" test_monitoring_permissions
    run_test "permissions_backup" test_backup_permissions
    
    # Integration tests (full mode only)
    if [[ "$RUN_FULL" == "true" ]]; then
        run_test "integration_health_check" test_health_check_integration
        run_test "integration_metrics_export" test_metrics_export_integration
    fi
    
    generate_test_report
}

main "$@"