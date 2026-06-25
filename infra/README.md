# jonnify · infra

Operational home for the Fly.io apps behind the BCS / `codemojex` stack: the
data-tier nodes the Phoenix umbrella reaches over Fly's **private 6PN**, plus the
ops surfaces that watch them.

Everything here follows one rule — **private by construction**. A node carries no
`[http_service]` and no `[[services]]`, so Fly Proxy assigns it no public address;
it answers only on the org's private network at `<app>.internal:<port>`. The sole
public surface is the ops dashboard, behind HTTPS + basic auth.

## The apps

| App | Region | Reached at (6PN) | Port | Volume | Status |
|---|---|---|---|---|---|
| `echo-valkey` | `fra` | `echo-valkey.internal` | 6390 | `valkey_data` (3 GB) | **deployed** |
| `echo-postgres` | `fra` | `echo-postgres.internal` | 5432 | `pg_data` (10 GB) | defined — not yet created |
| `codemojex-dashboard` | `lax` | public HTTPS (basic auth) | 8081 | — | defined — not yet created |

Supporting / experimental (not the core data tier):

- `datadog/` — the metrics agent.
- `dashboard/` — Go (+ Svelte) source for `codemojex-dashboard`: pgweb proxy + a native Valkey monitor behind one HTTPS site.
- `pgweb/` — an alternate standalone-pgweb config for `codemojex-dashboard` (superseded by `dashboard/`); its `pgbouncer.ini` is **not** used — `echo-postgres` runs no pooler.
- `cm-bitmapist/` — a bitmap-store spike (`cm-bitmapist.internal:6400`).

The **design docs** — the *why* behind every tuning knob — live in `codemojex/`
(described by content; the filenames don't all match their subject):

- `codemojex/codemojex.fly.md` — the **Valkey 9.1 node**: allocator, single-core ceiling, 1 GB sizing.
- `codemojex/codemojex.postgres.md` — the **Postgres 17 node**: money-DB durability + autovacuum tuning.
- `codemojex/codemojex.valkey.md` — **Valkey 8.1 vs 9.1** version choice for EchoMQ.

Agent playbooks live in `docs/` — currently [`docs/postgres-multi-user.md`](docs/postgres-multi-user.md).

## Lifecycle: create → disk → secrets → deploy → verify

Order matters: **the volume and the secrets must exist before the first deploy**,
because the machine mounts the volume at boot and reads its password from a secret
during first-boot init.

### 1 · Create the app — no public IP

These are private nodes; create the bare app so Fly assigns no public address.

**From the terminal (canonical for private nodes):**

```bash
fly apps create echo-postgres --org personal   # no public IP by default
```

**From the Fly web console** (fly.io → your org → *Create app* / *Launch*):
this is fine, **but** the console's launch flow (like `fly launch`) scaffolds a
default web service (80/443 → 8080) with `auto_stop_machines`, and allocates
public IPs. For a private datastore that is wrong on two counts — it exposes a
public surface, and the idle-stop watches proxy traffic while the node's real
traffic rides the 6PN (off-proxy), so an "idle" machine gets stopped and nothing
restarts it. If you create from the console, immediately reconcile to the
committed (service-free) `fly.toml` on the next deploy and release the IPs:

```bash
fly ips list -a echo-postgres                 # must end up EMPTY
fly ips release <addr> -a echo-postgres       # drop anything the scaffold added
```

> This is exactly the cleanup `echo-valkey` needed on first launch — see
> [The echo-valkey precedent](#the-echo-valkey-precedent).

### 2 · Create the disk (volume)

A Fly volume is host-local NVMe — **one volume to one machine, single region**, not
network storage. Size it above the working set; volumes grow, never shrink.

```bash
# Valkey — the AOF working set  (already provisioned for echo-valkey)
fly volumes create valkey_data --size 3  --region fra -a echo-valkey

# Postgres — the WAL + the growing ledger/guesses tables
fly volumes create pg_data     --size 10 --region fra -a echo-postgres
```

Keep the volume region **equal to the app's `primary_region` (`fra`)** so the
machine and its disk are co-located — and co-located with the bus/DB they serve.
(The volume-create example in `postgres/fly.toml`'s header comment shows a stale
region; `fra` — matching its `primary_region` and `echo-valkey` — is authoritative.)

> ⚠️ **The "use two or more volumes to avoid downtime" prompt — ignore it here.**
> A second *empty* volume is not a replica (it holds no data), and a second machine
> without configured replication is split-brain, not HA. Real HA for these
> single-primary nodes is a configured **streaming replica** (Postgres) or
> **`replicaof`** (Valkey) plus the off-site durability floor — a deliberate later
> step, never a bare extra volume.

### 3 · Set the secrets — before the first deploy

```bash
# Valkey: requirepass, injected via the image entrypoint's extra flags
fly secrets set -a echo-valkey \
  VALKEY_EXTRA_FLAGS="--requirepass $(openssl rand -hex 32)"

# Postgres: the superuser password, the initial database, and the echo_* app role
fly secrets set -a echo-postgres \
  POSTGRES_PASSWORD="$(openssl rand -hex 32)" POSTGRES_DB=codemojex \
  POSTGRES_ECHO_USER=echo_mesh POSTGRES_ECHO_PASSWORD="$(openssl rand -hex 32)"
```

Record the generated values in the app's `.env.production` so the consuming app and
ops can authenticate. Those files are **gitignored** (the global `~/.gitignore`
`.env.production` rule) and nothing secret is tracked under `infra/` — keep it that
way; the password must never land in an image layer or a commit.

### 4 · Deploy — the Operator runs this

> **Deploys are the Operator's to run. Claude agents do not run `fly deploy`.**
> Hand off the deploy; an agent's job is to *verify the result* (step 5).

```bash
# Operator, from the app's own directory (build context = the dir with the Dockerfile):
cd infra/postgres && fly deploy -a echo-postgres
```

### 5 · Verify — agent-runnable, no deploy

```bash
fly machines list -a echo-postgres                       # want: started, checks N/N
fly machine status <id> -a echo-postgres --display-config \
  | grep -iE "services|auto_?stop|internal_port"         # want: NO matches (private, no idle-stop)
fly ips list -a echo-postgres                            # want: empty (private)

# reachability over the real 6PN path:
fly proxy 15432:5432 -a echo-postgres &                  # local tunnel → echo-postgres.internal:5432
PGPASSWORD="$POSTGRES_PASSWORD" psql -h 127.0.0.1 -p 15432 -U postgres -d codemojex -c "select 1"
```

(For Valkey the equivalent proof is `fly proxy 16390:6390 -a echo-valkey` then an
authenticated `PING` → `PONG`, with the password from `valkey/.env.production`.)

## Multiple users on the Postgres node

`echo-postgres` runs **plain Postgres 17 — no PgBouncer.** Each app brings its own
bounded Ecto (`DBConnection`) pool over the 6PN, and those pools sum well under
`max_connections = 100`, so a pooler would only add a hop. "Multiple users" here
means **one Postgres login role per internal app**, created on the node at deploy:

- **`postgres`** — the superuser (`POSTGRES_PASSWORD`); migrations, ops, break-glass.
- **`echo_mesh`** (and siblings) — the everyday app identity (`POSTGRES_ECHO_USER` /
  `POSTGRES_ECHO_PASSWORD`): `LOGIN` with read/write (SELECT/INSERT/UPDATE/DELETE) +
  `CREATEDB` (so the app can `mix ecto.create` and own its database). **Not** a
  superuser; cannot create roles.

The roles are created at **first boot** by `postgres/initdb/10-echo-role.sh` — the
official image runs `/docker-entrypoint-initdb.d/*` once, on an empty cluster,
reading the `POSTGRES_ECHO_*` secrets (so no password touches an image layer). To add
another app's role, follow the same pattern; the playbook is
**[`docs/postgres-multi-user.md`](docs/postgres-multi-user.md)**.

## Canonical names

**The committed `fly.toml` `app =` line is the source of truth** for an app's name —
and therefore its `<app>.internal` 6PN hostname. Fly's private DNS resolves only the
real `app` name, so always use the canonical host in a `DATABASE_URL` / `VALKEY_ADDRESS`:

| App | 6PN host | Superseded aliases (reconciled) |
|---|---|---|
| `echo-postgres` | `echo-postgres.internal:5432` | ~~`codemojex-db`~~, ~~`codemojex-postgres`~~ |
| `echo-valkey` | `echo-valkey.internal:6390` | ~~`codemojex-valkey`~~ |

The stale aliases that were scattered across `pgweb/`, `dashboard/`, `codemojex/*.md`,
and `valkey/README.md` have been reconciled to these canonical names.

## The echo-valkey precedent

`echo-valkey` was first stood up through a scaffolding flow that gave it a public
web service (80/443 → 8080) with `auto_stop_machines` **and two public IPs** —
contradicting private-by-design. It was reconciled by redeploying from the
committed, service-free `fly.toml` and releasing the IPs; an authenticated `PING`
over the 6PN proxy now returns `PONG`, `fly ips list` is empty, and the machine
config carries no `services`/`autostop`. The lesson is baked into step 1: **create
bare, never allocate a public IP, and verify `fly ips list` is empty.**
