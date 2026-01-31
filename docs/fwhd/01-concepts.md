# FWHD Concepts

Core concepts for understanding the FWHD deployment system.

---

## Entity Hierarchy

```
Package ──────────────────────────────────────────────────────────────────────┐
│  Uploaded tarball artifact                                                  │
│  ID: PKG0KM3abc123xy                                                        │
│  Contains: built Node.js code (dist/index.js)                               │
└─────────────────────────────────────────────────────────────────────────────┘
                          │
                          │ 1:N (one package → many releases)
                          ▼
Release ──────────────────────────────────────────────────────────────────────┐
│  Tagged version for deployment                                              │
│  ID: RLS0KM3def456yz                                                        │
│  Tag: v8.1.0                                                                │
│  Status: draft → staged → active                                            │
└─────────────────────────────────────────────────────────────────────────────┘
                          │
                          │ 1:N (one release → many deployments)
                          ▼
Deployment ───────────────────────────────────────────────────────────────────┐
│  Execution record                                                           │
│  ID: DPL0KM3ghi789ab                                                        │
│  Status: pending → in_progress → completed | failed                         │
│  Machine: specific Fly machine                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Packages

A **Package** is an uploaded artifact containing built application code.

### Schema

```sql
CREATE TABLE packages (
    id         TEXT PRIMARY KEY,  -- PKG branded ID
    name       TEXT NOT NULL,     -- e.g., "@fireheadz/codemoji-backend"
    version    TEXT NOT NULL,     -- semantic version
    tigris_key TEXT NOT NULL,     -- S3 key: "packages/backend-1.0.0.tar.gz"
    size_bytes INTEGER,           -- file size
    checksum   TEXT,              -- SHA256
    created_at DATETIME
);
```

### Tarball Structure

```
backend-1.0.0.tar.gz
├── dist/
│   ├── index.js        ← entry point
│   └── *.js
├── node_modules/       ← bundled dependencies
├── package.json
└── README.md
```

### Commands

```bash
# Create package record
flyer pkg create \
  --name "@fireheadz/codemoji-backend" \
  --version "1.0.0" \
  --key "packages/backend-1.0.0.tar.gz" \
  --checksum "sha256:abc123..." \
  --size 1234567

# List packages
flyer pkg list

# Get details
flyer pkg get PKG0KM3abc123xy
```

---

## Releases

A **Release** is a tagged version ready for deployment.

### Status Lifecycle

```
     ┌─────────┐
     │  draft  │  ← Created from package
     └────┬────┘
          │ stage
          ▼
     ┌─────────┐
     │ staged  │  ← Pending deployment
     └────┬────┘
          │ activate
          ▼
     ┌─────────┐
     │ active  │  ← Currently deployed
     └─────────┘
```

### Schema

```sql
CREATE TABLE releases (
    id         TEXT PRIMARY KEY,  -- RLS branded ID
    package_id TEXT NOT NULL,     -- FK to packages
    tag        TEXT NOT NULL,     -- e.g., "v8.1.0"
    status     TEXT DEFAULT 'draft',
    notes      TEXT,              -- release notes
    created_at DATETIME,
    staged_at  DATETIME,
    activated_at DATETIME
);
```

### Commands

```bash
# Create release
flyer release create --package PKG0xxx --tag v8.1.0 --notes "Bug fixes"

# Stage for deployment
flyer release stage RLS0xxx

# Activate (makes it live)
flyer release activate RLS0xxx

# List pending releases
flyer release pending
```

---

## Deployments

A **Deployment** tracks execution on a specific machine.

### Status Lifecycle

```
     ┌─────────┐
     │ pending │  ← Created, waiting to start
     └────┬────┘
          │ start
          ▼
     ┌────────────┐
     │ in_progress │  ← Workers being restarted
     └────┬───────┬┘
          │       │
    success│     failure│
          ▼       ▼
     ┌─────────┐ ┌────────┐
     │completed│ │ failed │
     └─────────┘ └────────┘
```

### Schema

```sql
CREATE TABLE deployments (
    id         TEXT PRIMARY KEY,  -- DPL branded ID
    release_id TEXT NOT NULL,     -- FK to releases
    status     TEXT DEFAULT 'pending',
    machine_id TEXT,              -- Fly machine ID
    trigger    TEXT,              -- manual|ci|watcher
    error      TEXT,              -- error message if failed
    started_at DATETIME,
    completed_at DATETIME
);
```

### Commands

```bash
# Start deployment
flyer deploy start --release RLS0xxx --machine 1234567890 --trigger ci

# Mark complete
flyer deploy complete DPL0xxx

# Mark failed
flyer deploy fail DPL0xxx --error "Health check timeout"

# Show active
flyer deploy active
```

---

## Active Versions

Tracks which release is currently active per component.

### Schema

```sql
CREATE TABLE active_versions (
    component  TEXT PRIMARY KEY,  -- e.g., "backend"
    release_id TEXT NOT NULL      -- FK to releases
);
```

### Usage

When `release activate` is called:
1. Updates `releases.status` → `active`
2. Inserts/updates `active_versions` for component

Workers and `flyer sync` read from `active_versions` to know which version to run.

---

## Branded IDs

All entities use 14-character branded IDs.

### Format

```
{NAMESPACE}{BASE62_SNOWFLAKE}
   ↓           ↓
   3 chars     11 chars

Example: PKG0KM3abc123xy
         ↑↑↑ ↑↑↑↑↑↑↑↑↑↑↑
         Namespace   Snowflake
```

### Namespaces

| NS | Entity | Example |
|----|--------|---------|
| PKG | Package | PKG0KM3abc123xy |
| RLS | Release | RLS0KM3def456yz |
| DPL | Deployment | DPL0KM3ghi789ab |
| CMD | Command | CMD0KM3jkl012cd |

### Properties

- **Sortable:** Chronologically ordered
- **Unique:** Snowflake prevents collisions
- **Parseable:** Extract timestamp, worker ID, sequence

### Commands

```bash
# Generate
flyer id new PKG

# Parse
flyer id parse PKG0KM3abc123xy

# List namespaces
flyer id list
```

---

## Storage

### SQLite Database

Primary state stored in `packages.db`:

```
/app/data/packages.db
/app/data/packages.db-wal    ← Write-ahead log
/app/data/packages.db-shm    ← Shared memory
```

### Litestream Replication

Continuous backup to Tigris S3:

```
s3://fwhd-packages/db/packages/
├── generations/
│   └── {gen-id}/
│       ├── *.wal.lz4
│       └── snapshot.lz4
```

### Package Storage

Tarballs on Tigris S3:

```
s3://fwhd-packages/packages/
├── backend-1.0.0.tar.gz
├── backend-1.0.1.tar.gz
└── backend-1.1.0.tar.gz
```

### Local Package Directory

Extracted on each machine:

```
/app/packages/
├── current → v8.1.0/          ← symlink to active
├── v8.0.0/
│   └── dist/index.js
└── v8.1.0/
    └── dist/index.js
```

---

## Next

- [Flyer CLI](02-flyer-cli.md) - Full command reference
- [Workflows](03-workflows.md) - Common operations
