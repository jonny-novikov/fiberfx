# Flyer Quick Reference

Cheat sheet for common flyer commands.

---

## Configuration

```bash
flyer config show              # Show current config
flyer config init              # Generate default files
flyer --config /path config show  # Use specific config dir
```

---

## Branded IDs

```bash
flyer id new PKG               # Generate package ID
flyer id new RLS               # Generate release ID
flyer id parse PKG0xxx         # Parse ID details
flyer id list                  # List namespaces
```

---

## SQLite Database

```bash
flyer db init                  # Initialize schema
flyer db path                  # Show database path
flyer --db /custom/path.db db init  # Custom DB path
```

---

## Packages

```bash
flyer pkg list                 # List all packages
flyer pkg list --limit 10      # Limit results
flyer pkg get PKG0xxx          # Get package details
flyer pkg create \
  --name "@app/backend" \
  --version "1.0.0" \
  --key "pkg/backend-1.0.0.tar.gz" \
  --checksum "sha256:abc..." \
  --size 12345
```

---

## Releases

```bash
flyer release pending          # List pending releases
flyer release create \
  --package PKG0xxx \
  --tag v1.0.0
flyer release stage RLS0xxx    # Stage for deployment
flyer release activate RLS0xxx # Activate release
```

---

## Deployments

```bash
flyer deploy active            # Show active deployment
flyer deploy start --release RLS0xxx
flyer deploy complete DPL0xxx  # Mark success
flyer deploy fail DPL0xxx --error "reason"
```

---

## Litestream (SQLite Replication)

```bash
flyer stream status            # Check replication status
flyer stream restore           # Restore from S3
flyer stream restore --if-not-exists  # Skip if exists
flyer stream replicate         # Start replication daemon
flyer stream generate          # Generate litestream.yml
```

---

## Package Sync

```bash
flyer sync                     # Sync packages from S3
flyer sync --component backend
flyer sync --timeout 120
```

---

## PostgreSQL Operations

### Setup

```bash
flyer pg functions check       # Verify functions exist
flyer pg functions create      # Install functions
flyer pg functions create --sql-dir /path/to/phoenix/sql
```

### Data Export

```bash
flyer pg data fetch            # Export all tables to CSV
flyer pg data fetch --output-dir /tmp/export
flyer pg data fetch --tables players,emoji_sets
```

### Data Import

```bash
flyer pg data dry-run          # Test import (rollback)
flyer pg data upload           # Preview scripts
flyer pg data upload --confirm # Execute scripts
flyer pg data upload --confirm --skip-clean
```

### Table Management

```bash
flyer pg clear                 # Preview truncation
flyer pg clear --confirm       # Execute truncation
```

---

## Environment Files

```bash
flyer pg --env .env.staging functions check
flyer pg --env .env.production data fetch
```

---

## Common Workflows

### Initial Setup

```bash
flyer config init
vim flyer.conf
flyer db init
flyer stream generate
```

### Deploy New Version

```bash
flyer pkg create --name "@app/backend" --version "2.0.0" ...
flyer release create --package PKG0xxx --tag v2.0.0
flyer release stage RLS0xxx
flyer release activate RLS0xxx
```

### Startup Script

```bash
flyer stream restore --if-not-exists
flyer db init
flyer sync
exec ./start-app
```

### PostgreSQL Migration

```bash
flyer pg functions check || flyer pg functions create
flyer pg data fetch --output-dir /tmp/backup
flyer pg data dry-run
flyer pg data upload --confirm
```

---

## Flags Reference

| Flag | Commands | Description |
|------|----------|-------------|
| `--config` | All | Config directory |
| `--db` | All | SQLite database path |
| `--env` | pg | Environment file |
| `--verbose` | pg | Verbose output |
| `--confirm` | pg clear, pg data upload | Confirm destructive action |
| `--sql-dir` | pg functions create, pg data | SQL scripts directory |
| `--output-dir` | pg data fetch | CSV output directory |
| `--tables` | pg data fetch | Tables to export (comma-separated) |
| `--skip-clean` | pg data upload/dry-run | Skip 01-clean.sql |
