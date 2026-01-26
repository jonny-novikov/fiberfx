# FiberFx Tools

Go toolchain for FWHD (Fastify Worker Hot Deployment) infrastructure.
Contains the distribution server, deployment CLI, database gateway, and S3 explorer.

## Projects

```
tools/
├── main.go                  # Jonnify distribution server
├── go.mod                   # github.com/jonny-novikov/jonnify
├── Dockerfile               # Multi-stage: jonnify + flyer distributions
├── fly.toml                 # Fly.io config (app: jonnify, region: fra)
│
├── flyer/                   # FWHD deployment CLI (Cobra)
│   ├── go.mod               # github.com/fiberfx/flyer
│   ├── Makefile              # Build toolchain -> ../bin/
│   ├── cmd/flyer/main.go
│   ├── branded/              # Snowflake-based branded IDs (PKG, RLS, DPL, CMD)
│   ├── config/               # nginx-style config parser
│   ├── db/                   # SQLite schema & operations
│   └── s3/                   # Tigris S3 client
│
├── apps/
│   ├── gateway/              # Auth proxy + Outerbase Studio
│   │   └── go.mod            # github.com/fireheadz/codemoji-gateway
│   └── s3xplorer/            # S3 bucket web explorer
│       └── go.mod            # github.com/sgaunet/s3xplorer
│
├── bin/                      # Build output (gitignored)
└── data/
    └── litestream-0.5.5.tar.gz
```

## Jonnify

Lightweight Fiber HTTP server that serves distribution tarballs for `litestream` and `flyer` CLI binaries.
Deployed to Fly.io as `jonnify` (Frankfurt).

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Health check |
| `GET /` | List available distributions (JSON) |
| `GET /distr/*` | Download distribution tarball |

**Build & run locally:**

```bash
go build -o bin/jonnify .
DISTR_DIR=./data PORT=8080 ./bin/jonnify
```

## Flyer

Cobra CLI for managing the full FWHD lifecycle: packages, releases, deployments, and Litestream replication.
Uses SQLite (pure Go, no CGO) for state and Tigris S3 for package storage.

**Commands:**

```
flyer id new <NS>           Generate branded ID
flyer db init               Initialize SQLite schema
flyer pkg create            Register package
flyer release create        Create release from package
flyer release stage <id>    Stage for deployment
flyer deploy start          Start deployment
flyer stream replicate      Start Litestream replication
flyer sync                  Pre-download packages from S3
flyer config show           Show configuration
```

**Build:**

```bash
cd flyer
make build              # -> ../bin/flyer (current platform)
make build-linux        # -> ../bin/flyer-linux-amd64
make clean
```

## Gateway

Go auth server (chi v5 + JWT) that proxies to Outerbase Studio for database management.
Supports PostgreSQL and SQLite. Deployed to Fly.io as `fiberfx-gateway`.

```bash
cd apps/gateway
go build -o ../../bin/gateway ./cmd/gateway
```

See `apps/gateway/README.md` for environment variables and architecture.

## S3xplorer

Web UI for browsing S3 buckets with PostgreSQL-backed caching and background scanning.
Uses Templ templates, Tailwind CSS, and sqlc for type-safe queries.

```bash
cd apps/s3xplorer
task build              # Requires Task CLI
```

See `apps/s3xplorer/README.md` for configuration.

## Deployment

Jonnify and flyer distributions are built together via the top-level `Dockerfile`.
The Docker build cross-compiles flyer for linux, windows, and darwin (all amd64)
and packages them as versioned tarballs served by jonnify.

```bash
# Deploy via Fly.io (auto-deploys on push to deploy/v8)
flyctl deploy           # jonnify
cd apps && flyctl deploy # gateway
```
