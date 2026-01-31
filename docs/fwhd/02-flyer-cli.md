# Flyer CLI for FWHD

Command reference for the `flyer` CLI tool.

---

## Quick Reference

```bash
# Build
cd phoenix/tools/flyer && go build -o flyer ./cmd/flyer

# Package Lifecycle
flyer pkg create --name "@app/backend" --version "1.0.0" --key "..." --checksum "..." --size 1234
flyer pkg list
flyer pkg get PKG0xxx

# Release Lifecycle
flyer release create --package PKG0xxx --tag v8.1.0
flyer release stage RLS0xxx
flyer release activate RLS0xxx

# Deployment
flyer deploy start --release RLS0xxx --trigger ci
flyer deploy complete DPL0xxx
flyer deploy active

# Sync (startup)
flyer stream restore --if-not-exists
flyer db init
flyer sync --component backend

# Litestream
flyer stream generate
flyer stream status
flyer stream replicate
```

---

## Configuration

### flyer.conf

```nginx
database {
    path /app/data/packages.db;
}

s3 {
    endpoint   https://fly.storage.tigris.dev;
    bucket     fwhd-packages;
    region     auto;
    access_key env:AWS_ACCESS_KEY_ID;
    secret_key env:AWS_SECRET_ACCESS_KEY;
}

litestream {
    config_path              /app/litestream.yml;
    retention_days           7;
    s3_path                  db/packages;
    sync_interval            10s;
    snapshot_interval        1h;
    retention                72h;
}

packages {
    dir         /app/packages;
    entry_point dist/index.js;
}

sync {
    component backend;
    timeout   60;
}
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `AWS_ACCESS_KEY_ID` | Tigris S3 access key |
| `AWS_SECRET_ACCESS_KEY` | Tigris S3 secret |

---

## Package Commands

### pkg create

Create a package record in the database.

```bash
flyer pkg create \
  --name "@fireheadz/codemoji-backend" \
  --version "1.0.0" \
  --key "packages/backend-1.0.0.tar.gz" \
  --checksum "sha256:e3b0c44298fc..." \
  --size 5242880
```

**Required:**
- `--version` - Semantic version
- `--key` - S3 object key
- `--checksum` - SHA256 hash
- `--size` - File size in bytes

### pkg list

```bash
flyer pkg list
flyer pkg list --limit 50
```

**Output:**
```
ID              NAME                           VERSION     CREATED
PKG0KM3abc123  @fireheadz/codemoji-backend    1.0.0       2026-01-30 12:34
PKG0KM3def456  @fireheadz/codemoji-backend    1.0.1       2026-01-30 14:56
```

### pkg get

```bash
flyer pkg get PKG0KM3abc123xy
```

**Output:**
```
ID:        PKG0KM3abc123xy
Name:      @fireheadz/codemoji-backend
Version:   1.0.0
Key:       packages/backend-1.0.0.tar.gz
Size:      5242880 bytes
Checksum:  sha256:e3b0c44298fc...
Created:   2026-01-30 12:34:56
```

---

## Release Commands

### release create

```bash
flyer release create \
  --package PKG0KM3abc123xy \
  --tag v8.1.0 \
  --notes "Bug fixes and performance improvements"
```

Creates release in `draft` status.

### release stage

```bash
flyer release stage RLS0KM3def456yz
```

Moves release to `staged` status (ready for deployment).

### release activate

```bash
flyer release activate RLS0KM3def456yz
```

- Sets release status to `active`
- Updates `active_versions` table
- Triggers DistrWatcher on machines

### release pending

```bash
flyer release pending
```

**Output:**
```
ID              TAG          PACKAGE         STAGED
RLS0KM3def456  v8.1.0       PKG0KM3abc123   2026-01-30 15:00
```

---

## Deploy Commands

### deploy start

```bash
flyer deploy start \
  --release RLS0KM3def456yz \
  --machine 1234567890abcdef \
  --trigger ci
```

**Triggers:**
- `manual` - Human-initiated
- `ci` - CI/CD pipeline
- `watcher` - DistrWatcher auto-deploy

### deploy complete

```bash
flyer deploy complete DPL0KM3ghi789ab
```

### deploy fail

```bash
flyer deploy fail DPL0KM3ghi789ab --error "Health check failed after 30s"
```

### deploy active

```bash
flyer deploy active
```

**Output:**
```
ID:        DPL0KM3ghi789ab
Release:   RLS0KM3def456yz
Status:    completed
Machine:   1234567890abcdef
Trigger:   ci
Started:   2026-01-30 15:30:00
```

---

## Sync Command

Pre-download packages before application starts.

```bash
flyer sync
flyer sync --component backend --packages /app/packages --timeout 120
```

**What it does:**
1. Reads `active_versions` from `packages.db`
2. Downloads tarball from Tigris S3
3. Extracts to `packages/{tag}/`
4. Creates symlink: `current` → `{tag}`

**Use in startup:**
```bash
#!/bin/bash
flyer stream restore --if-not-exists
flyer db init
flyer sync --component backend
exec node /app/packages/current/dist/index.js
```

---

## Stream Commands (Litestream)

### stream restore

Restore database from S3 replica.

```bash
flyer stream restore
flyer stream restore --if-not-exists    # Skip if DB exists (default)
flyer stream restore --config /app/litestream.yml
```

### stream status

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

### stream generate

Generate litestream.yml from flyer.conf.

```bash
flyer stream generate
flyer stream generate --output /tmp/litestream.yml
flyer stream generate --databases /app/data/db1.db,/app/data/db2.db
```

### stream replicate

Start Litestream daemon (blocking).

```bash
flyer stream replicate
flyer stream replicate &    # Background
```

---

## Database Commands

### db init

Initialize schema.

```bash
flyer db init
flyer db init --db /custom/path/packages.db
```

### db path

Show database path.

```bash
flyer db path
```

---

## ID Commands

### id new

Generate branded ID.

```bash
flyer id new PKG    # Package
flyer id new RLS    # Release
flyer id new DPL    # Deployment
```

### id parse

Parse branded ID components.

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

### id list

List valid namespaces.

```bash
flyer id list
```

---

## Config Commands

### config show

Display current configuration.

```bash
flyer config show
```

### config init

Generate default configuration files.

```bash
flyer config init
flyer config init --output /etc/flyer
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

## Next

- [Workflows](03-workflows.md) - Common operations
- [Troubleshooting](04-troubleshooting.md) - Debug guide
