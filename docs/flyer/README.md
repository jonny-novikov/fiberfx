# Flyer CLI Documentation

**Version:** dev
**Purpose:** FWHD (Fastify Worker Hot Deployment) Management Tool

Flyer is a pure Go CLI for managing deployment operations, including SQLite database management, S3/Tigris storage, Litestream replication, and PostgreSQL data migration.

---

## Table of Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Command Reference](#command-reference)
   - [id](#id---branded-id-operations)
   - [db](#db---sqlite-database-operations)
   - [pkg](#pkg---package-operations)
   - [release](#release---release-operations)
   - [deploy](#deploy---deployment-operations)
   - [stream](#stream---litestream-replication)
   - [sync](#sync---package-synchronization)
   - [config](#config---configuration-management)
   - [pg](#pg---postgresql-operations)
4. [Workflows](#workflows)
5. [Environment Variables](#environment-variables)

---

## Installation

```bash
# Build from source
cd phoenix/tools/flyer
go build -o flyer ./cmd/flyer

# Or with version info
go build -ldflags "-X main.version=1.0.0 -X main.commit=$(git rev-parse --short HEAD)" -o flyer ./cmd/flyer
```

---

## Configuration

Flyer uses nginx-style configuration files with block syntax.

### Configuration Files

| File | Purpose |
|------|---------|
| `flyer.default.conf` | Default settings (shipped with tool) |
| `flyer.conf` | User overrides (optional) |

### Configuration Loading

Flyer searches for configuration in this order:
1. `--config` flag (if specified)
2. `/app` directory
3. `/etc/flyer` directory
4. Current directory (`.`)

### Configuration Syntax

```nginx
# Comments start with #

# Block syntax
block_name {
    directive value;
    another_directive "quoted value";
}

# Environment variable references
password env:MY_SECRET;           # Resolves $MY_SECRET
path ${HOME}/data;                # Shell-style expansion
```

### Complete Configuration Reference

```nginx
# SQLite database (for FWHD deployment tracking)
database {
    path /app/data/packages.db;
}

# S3/Tigris storage
s3 {
    endpoint   https://fly.storage.tigris.dev;
    bucket     fwhd-packages;
    region     auto;
    access_key env:AWS_ACCESS_KEY_ID;
    secret_key env:AWS_SECRET_ACCESS_KEY;
}

# Litestream replication
litestream {
    config_path              /app/litestream.yml;
    retention_days           7;
    s3_path                  db/packages;
    sync_interval            10s;
    snapshot_interval        1h;
    retention                72h;
    retention_check_interval 1h;
    validation_interval      1h;
}

# Package storage
packages {
    dir         /app/packages;
    entry_point dist/index.js;
}

# Sync settings
sync {
    component backend;
    timeout   60;
}

# PostgreSQL (for pg commands)
postgres {
    host       localhost;
    port       25432;
    database   codemoji_game;
    user       fireheadz_studio;
    password   env:PG_PASS;
    export_dir /tmp/codemoji-migration;
    sql_dir    /Users/jonny/dev/fireheadz/phoenix/sql;
}
```

---

## Command Reference

### Global Flags

```
--config string   Config directory (contains flyer.conf)
--db string       Path to SQLite database (default "/app/data/packages.db")
-h, --help        Help for any command
-v, --version     Show version information
```

---

### `id` - Branded ID Operations

Generate and parse branded IDs (snowflake-based identifiers).

#### `id new <namespace>`

Generate a new branded ID.

```bash
flyer id new PKG    # Generate package ID
flyer id new RLS    # Generate release ID
flyer id new DPL    # Generate deployment ID
```

**Output:** `PKG0KM3abc123xy`

#### `id parse <id>`

Parse a branded ID to extract components.

```bash
flyer id parse PKG0KM3abc123xy
```

**Output:**
```
Value:     PKG0KM3abc123xy
Namespace: PKG
Snowflake: 1234567890123456
Timestamp: 2026-01-30 12:34:56.789
Worker:    1
Sequence:  42
```

#### `id list`

List all valid namespaces.

```bash
flyer id list
```

**Namespaces:**
- `PKG` - Package
- `RLS` - Release
- `DPL` - Deployment
- `CMD` - Command

---

### `db` - SQLite Database Operations

Manage the SQLite database for deployment tracking.

#### `db init`

Initialize the database schema.

```bash
flyer db init
flyer db init --db /custom/path/packages.db
```

#### `db path`

Show the current database path.

```bash
flyer db path
```

---

### `pkg` - Package Operations

Manage package records in the deployment database.

#### `pkg create`

Create a new package record.

```bash
flyer pkg create \
  --name "@fireheadz/codemoji-backend" \
  --version "1.0.0" \
  --key "packages/backend-1.0.0.tar.gz" \
  --checksum "sha256:abc123..." \
  --size 1234567
```

**Required flags:**
- `--version` - Package version
- `--key` - Tigris S3 key
- `--checksum` - SHA256 checksum
- `--size` - File size in bytes

#### `pkg list`

List packages.

```bash
flyer pkg list
flyer pkg list --limit 50
```

#### `pkg get <id>`

Get package details.

```bash
flyer pkg get PKG0KM3abc123xy
```

---

### `release` - Release Operations

Manage release lifecycle.

#### `release create`

Create a new release from a package.

```bash
flyer release create \
  --package PKG0KM3abc123xy \
  --tag v8.0.0 \
  --notes "Bug fixes and improvements"
```

#### `release stage <id>`

Stage a release for deployment.

```bash
flyer release stage RLS0KM3def456yz
```

#### `release activate <id>`

Activate a release (make it live).

```bash
flyer release activate RLS0KM3def456yz
```

#### `release pending`

List staged releases pending deployment.

```bash
flyer release pending
```

---

### `deploy` - Deployment Operations

Manage deployment lifecycle.

#### `deploy start`

Start a new deployment.

```bash
flyer deploy start \
  --release RLS0KM3def456yz \
  --machine 1234567890abcdef \
  --trigger manual
```

**Triggers:** `manual`, `ci`, `watcher`

#### `deploy complete <id>`

Mark deployment as completed.

```bash
flyer deploy complete DPL0KM3ghi789ab
```

#### `deploy fail <id>`

Mark deployment as failed.

```bash
flyer deploy fail DPL0KM3ghi789ab --error "Health check timeout"
```

#### `deploy active`

Show the currently active deployment.

```bash
flyer deploy active
```

---

### `stream` - Litestream Replication

Manage SQLite replication to Tigris S3.

#### `stream restore`

Restore database from Tigris S3 replica.

```bash
flyer stream restore
flyer stream restore --config /app/litestream.yml
flyer stream restore --if-not-exists    # Skip if DB exists (default)
```

**Use in startup scripts:**
```bash
#!/bin/bash
flyer stream restore --if-not-exists
flyer db init
exec ./start-app
```

#### `stream status`

Check replication status.

```bash
flyer stream status
```

**Output:**
```
Database: /app/data/packages.db
  Size: 12345 bytes
  Modified: 2026-01-30 12:34:56
  WAL: 1234 bytes (active)
  SHM: present

Litestream Generations:
  ...
```

#### `stream replicate`

Start Litestream replication daemon (blocking).

```bash
flyer stream replicate
```

#### `stream generate`

Generate litestream.yml configuration.

```bash
flyer stream generate
flyer stream generate --output /tmp/litestream.yml
flyer stream generate --databases /app/data/db1.db,/app/data/db2.db
```

---

### `sync` - Package Synchronization

Pre-download packages before application starts.

```bash
flyer sync
flyer sync --component backend
flyer sync --packages /app/packages --timeout 120
```

**What it does:**
1. Reads `packages.db` to find active version for component
2. Downloads tarball from Tigris S3
3. Extracts to `packages/{tag}/`
4. Creates symlink: `current` → `{tag}`

**Use in startup scripts:**
```bash
#!/bin/bash
flyer stream restore --if-not-exists
flyer db init
flyer sync --component backend
exec node /app/packages/current/dist/index.js
```

---

### `config` - Configuration Management

#### `config show`

Display current configuration.

```bash
flyer config show
```

#### `config init`

Generate default configuration files.

```bash
flyer config init
flyer config init --output /etc/flyer
```

Creates:
- `flyer.default.conf` - Default settings
- `flyer.conf` - Override template

---

### `pg` - PostgreSQL Operations

PostgreSQL commands for data migration.

#### Global pg Flags

```
--env string      Load environment from file (default: .env.staging)
--verbose         Verbose output
```

#### `pg functions check`

Verify branded ID functions exist.

```bash
flyer pg functions check
```

**Output:**
```
Checking branded ID functions on fireheadz_studio@localhost:25432/codemoji_game...
  OK  encode_base62
  OK  decode_base62
  OK  extract_snowflake_ts
  OK  format_branded_id
All 4 functions verified.
```

#### `pg functions create`

Install branded ID functions from SQL file.

```bash
flyer pg functions create
flyer pg functions create --sql-dir /Users/jonny/dev/fireheadz/phoenix/sql
```

#### `pg clear`

Truncate migration tables (FK-safe order).

```bash
# Preview (no changes)
flyer pg clear

# Execute
flyer pg clear --confirm
```

**Tables truncated:**
1. `game_rooms`
2. `shop_packages`
3. `player_resources`
4. `players`
5. `emoji_sets`

#### `pg data fetch`

Export tables to CSV files.

```bash
flyer pg data fetch
flyer pg data fetch --output-dir /tmp/export
flyer pg data fetch --tables players,emoji_sets
```

#### `pg data upload`

Execute SQL scripts against target database.

```bash
# Preview (no changes)
flyer pg data upload

# Execute
flyer pg data upload --confirm
flyer pg data upload --confirm --skip-clean
flyer pg data upload --confirm --sql-dir /path/to/initial_data
```

**Scripts executed:**
1. `00-preflight.sql`
2. `01-clean.sql` (skippable)
3. `02-import-emoji-sets.sql`
4. `03-import-players.sql`
5. `04-transform-player-resources.sql`
6. `05-import-shop-packages.sql`
7. `06-import-game-rooms.sql`
8. `07-verify.sql`

#### `pg data dry-run`

Execute scripts with automatic rollback.

```bash
flyer pg data dry-run
flyer pg data dry-run --skip-clean
```

---

## Workflows

### Initial Deployment Setup

```bash
# 1. Initialize config
flyer config init

# 2. Edit flyer.conf with your settings
vim flyer.conf

# 3. Initialize database
flyer db init

# 4. Generate litestream config
flyer stream generate

# 5. Create first package
flyer pkg create --name "@app/backend" --version "1.0.0" ...

# 6. Create and stage release
flyer release create --package PKG... --tag v1.0.0
flyer release stage RLS...
flyer release activate RLS...
```

### Startup Script (Dockerfile ENTRYPOINT)

```bash
#!/bin/bash
set -e

# Restore database from S3 (if not exists)
flyer stream restore --if-not-exists

# Initialize schema (idempotent)
flyer db init

# Sync packages from S3
flyer sync --component backend

# Start Litestream replication in background
flyer stream replicate &

# Start application
exec node /app/packages/current/dist/index.js
```

### PostgreSQL Migration Workflow

```bash
# 1. Check functions exist
flyer pg functions check

# 2. If missing, create them
flyer pg functions create --sql-dir /Users/jonny/dev/fireheadz/phoenix/sql

# 3. Export data from source
flyer pg data fetch --output-dir /tmp/migration

# 4. Dry-run import (verify)
flyer pg data dry-run

# 5. Execute import
flyer pg data upload --confirm
```

---

## Environment Variables

### S3/Tigris

| Variable | Description |
|----------|-------------|
| `AWS_ACCESS_KEY_ID` | S3 access key |
| `AWS_SECRET_ACCESS_KEY` | S3 secret key |

### PostgreSQL

| Variable | Default | Description |
|----------|---------|-------------|
| `PG_HOST` | `localhost` | PostgreSQL host |
| `PG_PORT` | `25432` | PostgreSQL port |
| `PG_NAME` | `codemoji_game` | Database name |
| `PG_USER` | `fireheadz_studio` | Database user |
| `PG_PASS` | (required) | Database password |
| `EXPORT_DIR` | `/tmp/codemoji-migration` | CSV export directory |
| `SQL_DIR` | (auto-detected) | Path to phoenix/sql |

### Loading from .env files

```bash
# Load specific env file
flyer pg --env .env.staging functions check

# Default search order:
# 1. .env.staging
# 2. .env
```

---

## Path Configuration

Flyer supports both relative and absolute paths in configuration:

```nginx
# Absolute paths (recommended for production)
postgres {
    sql_dir    /Users/jonny/dev/fireheadz/phoenix/sql;
    export_dir /tmp/codemoji-migration;
}

# Environment variable expansion
postgres {
    sql_dir    ${HOME}/dev/phoenix/sql;
    export_dir env:EXPORT_DIR;
}
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Configuration error |
| 3 | Database error |
| 4 | Network/S3 error |

---

## See Also

- [FWHD Architecture](./FWHD-ARCHITECTURE.md)
- [Litestream Documentation](https://litestream.io/reference/config/)
- [Tigris S3 Documentation](https://www.tigrisdata.com/docs/)
