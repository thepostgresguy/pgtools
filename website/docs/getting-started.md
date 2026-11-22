---
sidebar_position: 2
---

# Getting Started

## Prerequisites

- **Shell**: A `bash`-compatible shell.
- **Tools**: `psql` (the PostgreSQL command-line client) and `git`.
- **Database Access**: A valid PostgreSQL connection string or service name. Most scripts require privileges equivalent to the `pg_monitor` role.

## Installation

```bash
# Clone the repository
git clone https://github.com/thepostgresguy/pgtools.git
cd pgtools

# Make the main script executable
chmod +x pgtools.sh
```

## Usage

All commands are run through the `pgtools.sh` wrapper:

```bash
./pgtools.sh <command> "<connection_string>"
```

### Examples

```bash
# Check for blocking locks
./pgtools.sh locks "postgresql://user:pass@host:port/dbname"

# Check current activity
./pgtools.sh activity "service=my_customer_db"
```

## Verify Installation

```bash
# Test basic functionality
./automation/test_pgtools.sh --help

# Run quick validation (requires local PostgreSQL)
./automation/test_pgtools.sh --fast
```

## PostgreSQL Compatibility

Tested against PostgreSQL 15 through 19. Check your version:

```bash
psql --version
```

PostgreSQL 14 or earlier is not officially supported — some scripts may not work as expected.
