# FWHD Documentation

**FWHD** = Fastify Worker Hot Deployment

A zero-downtime deployment system for Node.js workers on Fly.io.

---

## Documentation Index

| Document | Description |
|----------|-------------|
| [00-overview.md](00-overview.md) | Architecture and component overview |
| [01-concepts.md](01-concepts.md) | Core concepts: packages, releases, deployments |
| [02-flyer-cli.md](02-flyer-cli.md) | Flyer CLI command reference |
| [03-workflows.md](03-workflows.md) | Common operations and CI/CD pipelines |
| [04-troubleshooting.md](04-troubleshooting.md) | Debug guide and issue resolution |

---

## Quick Start

### 1. Build Flyer CLI

```bash
cd phoenix/tools/flyer
go build -o flyer ./cmd/flyer
```

### 2. Initialize

```bash
./flyer config init
./flyer db init
```

### 3. First Deployment

```bash
# Upload package to Tigris S3
# Then register it:
./flyer pkg create --name "@app/backend" --version "1.0.0" \
  --key "packages/backend-1.0.0.tar.gz" --checksum "sha256:..." --size 1234567

# Create and activate release
./flyer release create --package PKG0xxx --tag v1.0.0
./flyer release stage RLS0xxx
./flyer release activate RLS0xxx
```

### 4. Machine Startup

```bash
flyer stream restore --if-not-exists
flyer db init
flyer sync --component backend
flyer stream replicate &
exec /app/bin/start
```

---

## Key Components

| Component | Purpose |
|-----------|---------|
| `flyer` | Go CLI for deployment management |
| `packages.db` | SQLite state (replicated via Litestream) |
| `Echo.Workers.Manager` | Phoenix GenServer for worker supervision |
| `MintProxy` | HTTP proxy to healthy workers |
| `DistrWatcher` | Watches for new releases |

---

## Related Resources

- **Main Flyer Docs:** [../README.md](../flyer/README.md)
- **Plan:** PLN0KIoZj7TQXK (FWHD v3 Production Delivery)
- **Epic:** EPC0KCJhe55sum (FWHD Technology)
- **KB:** KBC0KFIvoAxl20 (FWHD v3: Proxied /api/v2)
