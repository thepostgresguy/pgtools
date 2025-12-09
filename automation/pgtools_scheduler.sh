#!/bin/bash
#
# Script: pgtools_scheduler.sh  
# Purpose: Cron job scheduler and manager for pgtools
# Usage: ./automation/pgtools_scheduler.sh [install|remove|status|run-job]
#
# This script helps set up automated PostgreSQL monitoring using cron jobs
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

usage() {
    cat << EOF
PostgreSQL Tools Scheduler

Usage: $0 COMMAND [OPTIONS]

COMMANDS:
    install         Install cron jobs for automated monitoring
    remove          Remove pgtools cron jobs
    status          Show current cron job status
    run-job JOB     Manually run a specific job
    list-jobs       List available job types

JOB TYPES:
    daily-quick     Daily quick health check
    weekly-full     Weekly comprehensive check
    monthly-audit   Monthly security audit
    backup-check    Backup validation check

EXAMPLES:
    $0 install                 # Install all cron jobs
    $0 status                  # Check cron job status  
    $0 run-job daily-quick     # Run daily check manually
    $0 remove                  # Remove all pgtools cron jobs

CONFIGURATION:
    Edit $SCRIPT_DIR/pgtools.conf to customize:
    - Database connection parameters
    - Email notification settings
    - Alert thresholds
    - Schedule timing

EOF
}

# Load configuration
CONFIG_FILE="$SCRIPT_DIR/pgtools.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1091
    # shellcheck source=pgtools.conf
    source "$CONFIG_FILE"
else
    warn "Configuration file not found: $CONFIG_FILE"
    warn "Using defaults and example configuration"
    if [[ -f "$SCRIPT_DIR/pgtools.conf.example" ]]; then
        # shellcheck disable=SC1091
        # shellcheck source=pgtools.conf.example
        source "$SCRIPT_DIR/pgtools.conf.example"
    fi
fi

# Default schedule values if not set in config
DAILY_QUICK_CHECK="${DAILY_QUICK_CHECK:-0 8 * * *}"
WEEKLY_FULL_CHECK="${WEEKLY_FULL_CHECK:-0 2 * * 0}"  
MONTHLY_SECURITY_AUDIT="${MONTHLY_SECURITY_AUDIT:-0 3 1 * *}"

# Function to create cron job entries
generate_cron_entries() {
    cat << EOF
# PostgreSQL Tools Automated Monitoring
# Generated on $(date)

# Daily quick health check
$DAILY_QUICK_CHECK $SCRIPT_DIR/pgtools_health_check.sh --quick --format text >> $SCRIPT_DIR/cron.log 2>&1

# Weekly comprehensive check  
$WEEKLY_FULL_CHECK $SCRIPT_DIR/pgtools_health_check.sh --format html >> $SCRIPT_DIR/cron.log 2>&1

# Monthly security audit
$MONTHLY_SECURITY_AUDIT $SCRIPT_DIR/run_security_audit.sh >> $SCRIPT_DIR/cron.log 2>&1

# Cleanup old reports (daily at 1 AM)
0 1 * * * $SCRIPT_DIR/cleanup_reports.sh >> $SCRIPT_DIR/cron.log 2>&1

EOF
}

# Install cron jobs
install_cron_jobs() {
    log "Installing pgtools cron jobs..."
    
    # Backup existing crontab
    if crontab -l > /dev/null 2>&1; then
        crontab -l > "$SCRIPT_DIR/crontab.backup.$(date +%Y%m%d_%H%M%S)"
        log "Existing crontab backed up"
    fi
    
    # Generate temporary cron file
    local temp_cron
    temp_cron=$(mktemp)
    
    # Get existing crontab (excluding pgtools entries)
    if crontab -l > /dev/null 2>&1; then
        crontab -l | grep -v "PostgreSQL Tools" | grep -v "pgtools" > "$temp_cron" || true
    fi
    
    # Add pgtools entries
    generate_cron_entries >> "$temp_cron"
    
    # Install new crontab
    if crontab "$temp_cron"; then
        success "Cron jobs installed successfully"
        rm -f "$temp_cron"
    else
        error "Failed to install cron jobs"
        rm -f "$temp_cron"
        return 1
    fi
    
    log "Cron schedule:"
    echo "  Daily quick check: $DAILY_QUICK_CHECK"
    echo "  Weekly full check: $WEEKLY_FULL_CHECK"  
    echo "  Monthly audit: $MONTHLY_SECURITY_AUDIT"
}

# Remove cron jobs
remove_cron_jobs() {
    log "Removing pgtools cron jobs..."
    
    if ! crontab -l > /dev/null 2>&1; then
        warn "No crontab found"
        return 0
    fi
    
    # Backup existing crontab
    crontab -l > "$SCRIPT_DIR/crontab.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Generate temporary cron file without pgtools entries
    local temp_cron
    temp_cron=$(mktemp)
    crontab -l | grep -v "PostgreSQL Tools" | grep -v "pgtools" > "$temp_cron" || true
    
    # Install cleaned crontab
    if crontab "$temp_cron"; then
        success "pgtools cron jobs removed"
        rm -f "$temp_cron"
    else
        error "Failed to remove cron jobs"
        rm -f "$temp_cron"
        return 1
    fi
}

# Show cron job status
show_status() {
    log "Current pgtools cron jobs:"
    
    if crontab -l > /dev/null 2>&1; then
        if crontab -l | grep -q "pgtools"; then
            echo
            crontab -l | grep -A 10 -B 2 "PostgreSQL Tools" || crontab -l | grep "pgtools"
            echo
            success "pgtools cron jobs are installed"
        else
            warn "No pgtools cron jobs found"
        fi
    else
        warn "No crontab found for current user"
    fi
    
    # Check if scripts are executable
    log "Checking script permissions..."
    
    local health_check_script="$SCRIPT_DIR/pgtools_health_check.sh"
    if [[ -x "$health_check_script" ]]; then
        success "Health check script is executable"
    else
        warn "Health check script not executable: $health_check_script"
        log "Run: chmod +x $health_check_script"
    fi
}

# Run specific job manually
run_job() {
    local job_type="$1"
    
    log "Running job: $job_type"
    
    case "$job_type" in
        "daily-quick")
            "$SCRIPT_DIR/pgtools_health_check.sh" --quick --format text
            ;;
        "weekly-full")  
            "$SCRIPT_DIR/pgtools_health_check.sh" --format html
            ;;
        "monthly-audit")
            "$SCRIPT_DIR/run_security_audit.sh"
            ;;
        "backup-check")
            "$SCRIPT_DIR/pgtools_health_check.sh" --quick --format text -o "$SCRIPT_DIR/reports/backup-$(date +%Y%m%d)"
            ;;
        *)
            error "Unknown job type: $job_type"
            echo "Available jobs: daily-quick, weekly-full, monthly-audit, backup-check"
            return 1
            ;;
    esac
}

# List available jobs
list_jobs() {
    cat << EOF
Available Job Types:

daily-quick     - Quick health check (essential monitoring scripts)
                  Schedule: $DAILY_QUICK_CHECK
                  
weekly-full     - Comprehensive health check (all monitoring scripts)  
                  Schedule: $WEEKLY_FULL_CHECK
                  
monthly-audit   - Security and compliance audit
                  Schedule: $MONTHLY_SECURITY_AUDIT
                  
backup-check    - Backup validation and readiness check
                  Schedule: On-demand or custom

Manual execution:
  $0 run-job JOB_TYPE

EOF
}

# Main command processing
case "${1:-}" in
    "install")
        install_cron_jobs
        ;;
    "remove")
        remove_cron_jobs
        ;;
    "status")
        show_status
        ;;
    "run-job")
        if [[ $# -lt 2 ]]; then
            error "Job type required"
            usage
            exit 1
        fi
        run_job "$2"
        ;;
    "list-jobs")
        list_jobs
        ;;
    "")
        error "Command required"
        usage
        exit 1
        ;;
    *)
        error "Unknown command: $1"
        usage
        exit 1
        ;;
esac