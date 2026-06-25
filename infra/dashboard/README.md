# codemojex-dashboard

A Gin web server that fronts **pgweb** (Postgres browser) and a native **Valkey
monitor** behind one HTTPS surface, with a **Svelte** frontend. It reaches
`echo-postgres` and `echo-valkey` over Fly's private 6PN and exposes only its own
site, behind HTTP basic auth.

## Why no PgBouncer

Both `Codemojex` (the game, via Ecto) and this dashboard connect to
`echo-postgres` directly over the 6PN. Each has its own bounded pool, and the sum
is far under Postgres `max_connections`. There is no external Postgres client and
nothing to multiplex, so a pooler would add a hop and the transaction-mode
prepared-statement caveat for no gain. Ecto's `DBConnection` is already the pool.

## How pgweb is connected

pgweb is built on Gin and supports a URL prefix (`--prefix`). The dashboard runs
pgweb as a **supervised child process** bound to loopback with `--prefix=/db/`,
and reverse-proxies `/db` to it. Because pgweb emits its asset and API URLs under
`/db`, the proxy is a clean pass-through — no path rewriting, and no collision
with the dashboard's own `/` (SPA) and `/api/valkey/*` routes. pgweb runs
`--readonly` against the read-only role.

```
browser ──HTTPS──> Gin (:8080, basic auth)
                     ├── /                 Svelte SPA (embedded)
                     ├── /api/valkey/*      Valkey monitor (valkey-go)
                     └── /db/*  ──proxy──>  pgweb child (:8081, --prefix=/db/)
                                  │
        echo-postgres.internal:5432 (6PN)   echo-valkey.internal:6390 (6PN)
```

## Layout

- `main.go` — Gin server: basic auth, embedded SPA, Valkey API, pgweb supervision + proxy.
- `valkey.go` — the Valkey monitor (valkeycompat / go-redis-compatible): INFO, DBSIZE, CONFIG, CLIENT LIST, SLOWLOG.
- `web/` — Svelte + Vite frontend (built to `web/dist`, embedded via `go:embed`).
- `Dockerfile` — three stages: build the UI, build the Go binary + pgweb from source, assemble.
- `fly.toml` — private DB/Valkey access, public HTTPS, scale-to-zero.

## Build & run

This repository is a scaffold; build it with a Go toolchain (not included in the
authoring environment). First resolve modules, then run.

```bash
# pin dependencies (writes go.sum)
go mod tidy

# local dev: Go server on :8080, Vite on :5173 proxying /api and /db
go run .                       # set DASH_USER, DASH_PASS, PGWEB_DATABASE_URL, VALKEY_ADDRESS
npm --prefix web install && npm --prefix web run dev

# production image
docker build -t codemojex-dashboard .
```

## Environment

| Var | Example |
|---|---|
| `DASH_USER` / `DASH_PASS` | `ops` / a generated secret |
| `PGWEB_DATABASE_URL` | `postgres://codemojex_ro:…@echo-postgres.internal:5432/codemojex?sslmode=disable` |
| `VALKEY_ADDRESS` | `echo-valkey.internal:6390` |

The `codemojex_ro` role is the read-only login created in
`postgres-pgbouncer/init/0002-external-roles.sql` (a `CONNECTION LIMIT` keeps the
dashboard's footprint small).

## Notes to verify on first build

- `pgweb` flags (`--prefix`, `--readonly`, `--bind`, `--listen`, `--url`) are from
  pgweb's usage docs; confirm against the pinned `@v0.16.2` (adjust the version to
  the latest release).
- The Valkey monitor uses `valkeycompat` (a go-redis-compatible adapter), so the
  command method names follow go-redis; `go mod tidy` resolves the exact line.
