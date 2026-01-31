# FWHD Overview

**FWHD** = Fastify Worker Hot Deployment

A zero-downtime deployment system for Node.js (Fastify) workers running alongside Phoenix Echo on Fly.io.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Fly.io Machine                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────┐    ┌──────────────────────┐                       │
│  │   Phoenix Echo       │    │   Litestream         │                       │
│  │   (Main App)         │    │   (Replication)      │                       │
│  │                      │    │                      │                       │
│  │  - Web Server        │    │  packages.db ────────┼──▶ Tigris S3         │
│  │  - Channels          │    │                      │                       │
│  │  - MintProxy ──────┐ │    └──────────────────────┘                       │
│  └──────────────────────┼────────────────────────────────────────────────────┤
│                         │                                                    │
│                         ▼                                                    │
│  ┌──────────────────────────────────────────────────────────────────────────┤
│  │                   Echo.Workers.Manager                                    │
│  │                                                                           │
│  │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                      │
│  │   │  Worker 1   │  │  Worker 2   │  │  Worker 3   │                      │
│  │   │  (Fastify)  │  │  (Fastify)  │  │  (Fastify)  │                      │
│  │   │  port:3001  │  │  port:3002  │  │  port:3003  │                      │
│  │   └─────────────┘  └─────────────┘  └─────────────┘                      │
│  │                                                                           │
│  │   packages/                                                               │
│  │   ├── current → v8.1.0/                                                   │
│  │   ├── v8.0.0/                                                             │
│  │   └── v8.1.0/                                                             │
│  └───────────────────────────────────────────────────────────────────────────┘
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                            ┌──────────────┐
                            │  Tigris S3   │
                            │              │
                            │  packages/   │
                            │  db/         │
                            └──────────────┘
```

---

## Components

### 1. Flyer CLI

Go-based CLI tool for managing FWHD operations.

**Location:** `phoenix/tools/flyer/`

**Commands:**
- `flyer pkg` - Package management
- `flyer release` - Release lifecycle
- `flyer deploy` - Deployment tracking
- `flyer sync` - Pre-download packages
- `flyer stream` - Litestream operations

### 2. packages.db (SQLite)

Deployment state database replicated to Tigris S3 via Litestream.

**Tables:**
- `packages` - Uploaded tarballs with checksums
- `releases` - Tagged releases from packages
- `deployments` - Deployment execution records
- `active_versions` - Currently active release per component

### 3. Echo.Workers.Manager

Phoenix GenServer supervising Fastify workers.

**Responsibilities:**
- Start/stop Node.js worker processes
- Health monitoring
- Rolling restarts during deployment
- Blue-green cutover

### 4. MintProxy

HTTP proxy routing requests to healthy workers.

**Path:** `/api/v2/*` → `localhost:300x`

### 5. DistrWatcher

Watches for new package distributions.

**Trigger:** New release activated in `packages.db`

---

## Data Flow

### Deployment Flow

```
Developer                  CI/CD                   Fly Machine
    │                        │                          │
    │  git push              │                          │
    │───────────────────────▶│                          │
    │                        │                          │
    │                        │  build + upload          │
    │                        │  to Tigris S3            │
    │                        │───────┐                  │
    │                        │       │                  │
    │                        │◀──────┘                  │
    │                        │                          │
    │                        │  flyer pkg create        │
    │                        │  flyer release create    │
    │                        │  flyer release activate  │
    │                        │───────────────────────▶  │
    │                        │                          │
    │                        │      Litestream sync     │
    │                        │       packages.db ◀──────│
    │                        │                          │
    │                        │      DistrWatcher sees   │
    │                        │      new active version  │
    │                        │                          │
    │                        │      Download tarball    │
    │                        │      Extract to v8.1.0/  │
    │                        │      Update current →    │
    │                        │      Rolling restart     │
    │                        │                          │
```

### Startup Flow

```
Machine Start
     │
     ▼
┌─────────────────────────────┐
│ flyer stream restore        │  ← Restore packages.db from S3
│ flyer db init               │  ← Ensure schema exists
│ flyer sync                  │  ← Download current version
└─────────────────────────────┘
     │
     ▼
┌─────────────────────────────┐
│ Start Litestream replicate  │  ← Begin continuous replication
└─────────────────────────────┘
     │
     ▼
┌─────────────────────────────┐
│ Start Phoenix Echo          │  ← Main app + worker supervision
└─────────────────────────────┘
```

---

## Key Decisions

| ID | Decision | Rationale |
|----|----------|-----------|
| D-1 | SQLite + Litestream | Simple state, S3 replication, no external DB |
| D-2 | Branded IDs | Sortable, collision-free identifiers |
| D-3 | Tarball distribution | Single artifact per release |
| D-4 | Symlink switching | Atomic version changes |
| D-5 | Flyer CLI in Go | Single binary, no runtime deps |

---

## Related Plans

- **PLN0KIoZj7TQXK** - FWHD v3 Production Delivery
- **PLN0K2uui6Q7Bg** - FiberFx Deployment (uses FWHD patterns)
- **PLN0KLymjCy9q4** - Phoenix Flyer Toolchain (pg commands)

---

## Next Steps

1. [Concepts](01-concepts.md) - Understand packages, releases, deployments
2. [Flyer CLI](02-flyer-cli.md) - Command reference
3. [Workflows](03-workflows.md) - Common operations
4. [Troubleshooting](04-troubleshooting.md) - Debug guide
