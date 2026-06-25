# Per-app users on `echo-postgres` — a Claude Code playbook

**Audience:** a Claude Code agent adding (or auditing) the Postgres login roles for
the internal apps that share `echo-postgres`. **Model:** `echo-postgres` runs
**plain Postgres 17 — no PgBouncer.** Each internal app connects over the 6PN with
its own bounded **Ecto (`DBConnection`) pool**; the pools sum well under
`max_connections = 100`, so a pooler would only add a hop (this is exactly what
`dashboard/README.md` and `dashboard/main.go` already say). "Multiple users" means
**one Postgres login role per internal app**, created on the node **at deploy**.

> You do not run `fly deploy`. Author the files + run the read-only checks, then hand
> the deploy to the Operator. See [`../README.md`](../README.md) for the lifecycle.

---

## 1 · As built today

Two identities exist on the node:

| Role | From | Privileges | For |
|---|---|---|---|
| `postgres` | `POSTGRES_PASSWORD` secret (image default superuser) | superuser | migrations, ops, break-glass |
| `echo_mesh` | `POSTGRES_ECHO_USER` / `POSTGRES_ECHO_PASSWORD` secrets | `LOGIN`, `CREATEDB`, read/write (SELECT/INSERT/UPDATE/DELETE) on the app DB; **not** superuser, **no** CREATEROLE | the everyday `echo_*` app identity |

The `echo_mesh` role is created at **first boot** by
[`../postgres/initdb/10-echo-role.sh`](../postgres/initdb/10-echo-role.sh). The
official `postgres:17` image runs every file in `/docker-entrypoint-initdb.d/` exactly
**once, on an empty data directory**, as the `postgres` superuser over the local
socket. The Dockerfile copies the dir in:

```dockerfile
COPY --chmod=0755 initdb/ /docker-entrypoint-initdb.d/
```

and the secrets are set before the first deploy:

```bash
fly secrets set -a echo-postgres \
  POSTGRES_PASSWORD="$(openssl rand -hex 32)" POSTGRES_DB=codemojex \
  POSTGRES_ECHO_USER=echo_mesh POSTGRES_ECHO_PASSWORD="$(openssl rand -hex 32)"
```

The real values live in `postgres/.env.production` (gitignored). The script reads the
`POSTGRES_ECHO_*` pair, creates the role, and grants it read/write on the
`POSTGRES_DB` schema plus `ALTER DEFAULT PRIVILEGES` for tables migrated later.
`CREATEDB` lets the app run `mix ecto.create` and **own** the database it makes — the
cleanest path, since an owner has full rights in its own database with no extra grants.

## 2 · Adding another internal app's role

Each internal app gets its **own** role + password; never share one login across apps,
and never hand an app the `postgres` superuser. To add app `foo`:

1. **Pick env var names** following the convention: `POSTGRES_FOO_USER` /
   `POSTGRES_FOO_PASSWORD`. Put real values in `postgres/.env.production` and plan the
   matching `fly secrets set`.
2. **Add a sibling init script** `postgres/initdb/20-foo-role.sh` — copy
   `10-echo-role.sh`, swap the `POSTGRES_ECHO_*` env names for `POSTGRES_FOO_*`, and
   adjust grants if `foo` needs less than full read/write. (Numeric prefixes set run
   order; the role only needs to exist before the app first connects.)
3. If several apps share **one** database, the per-app roles coexist in it with the
   grants from the script. If an app should be **isolated**, rely on its `CREATEDB`
   to create+own its own database (recommended for clean separation), or have the
   superuser `CREATE DATABASE foo OWNER foo` in the script.

> Alternative: generalize `10-echo-role.sh` to loop over a list of `(user, password)`
> pairs from a convention instead of one hard-coded prefix. Only worth it past ~3 apps.

## 3 · The connection budget

Every backend connection counts against `max_connections = 100`
(`superuser_reserved_connections = 3` is held back for ops). With no pooler, the cap
is the **sum of every app's Ecto `pool_size`** plus headroom:

```
Σ(each app's Ecto pool_size) + 3 (reserved) + a little for psql/migrations/monitoring ≤ 100
```

Bound each app's `pool_size` in its Ecto config (the default is 10). E.g. five apps at
`pool_size: 15` = 75 + 3 + headroom — fine. If app count grows enough to pressure 100,
*then* revisit a transaction-mode pooler — not before. (`postgresql.conf` also sets
`idle_in_transaction_session_timeout = '60s'`, so a leaked connection can't pin the
vacuum horizon indefinitely.)

## 4 · First-boot-only caveat

`/docker-entrypoint-initdb.d/*` runs **only on an empty data directory**. On a redeploy
with an existing `pg_data` volume it does **not** re-run, so a role added to the script
later will not appear. To apply a new/changed role to an already-initialised cluster,
run the same SQL by hand as the superuser:

```bash
fly proxy 15432:5432 -a echo-postgres &
PGPASSWORD="$POSTGRES_PASSWORD" psql -h 127.0.0.1 -p 15432 -U postgres -d codemojex <<'SQL'
  CREATE ROLE "foo" WITH LOGIN PASSWORD 'from-the-secret' CREATEDB;
  GRANT CONNECT ON DATABASE codemojex TO "foo";
  GRANT USAGE, CREATE ON SCHEMA public TO "foo";
  GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "foo";
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "foo";
SQL
```

## 5 · Optional: external (non-app) Postgres clients

Separate concern, off the internal-app path: if a laptop `psql`, a BI tool, or the ops
dashboard needs direct Postgres-protocol access, `pgweb/0002-external-roles.sql`
sketches **read-only / scoped** external roles (`codemojex_app` RW, `codemojex_ro` RO)
with per-role `CONNECTION LIMIT`s. Two notes if you wire it up: its explicit
`GRANT … ON ALL TABLES` must run **after** the app's first migration (it only grants on
tables that exist then), and external clients reach the private node via `fly proxy`,
not a public IP. This is *not* needed for the internal apps — they use their own role
(§1–2) over the 6PN.

## 6 · Invariants — do not break

- **Plain Postgres 17, no pooler.** Ecto's `DBConnection` is the pool. Do not
  reintroduce PgBouncer for the internal apps.
- **One role per app; never the superuser.** Apps get a `LOGIN` role with the
  privileges they need (read/write + `CREATEDB`), not `postgres`.
- **No secret in a file or layer.** Passwords arrive as Fly secrets / `psql -v`
  variables; `.env.production` stays gitignored.
- **Private by construction.** No public IP on `echo-postgres`; external reach is via
  `fly proxy`.
- **The durability/vacuum `postgresql.conf` is out of scope** for this task.

## 7 · Verification gate (agent-runnable, no deploy)

After the Operator deploys:

```bash
fly proxy 15432:5432 -a echo-postgres &

# the app role exists with the right attributes (LOGIN, Create DB; NOT Superuser):
PGPASSWORD="$POSTGRES_PASSWORD" psql -h 127.0.0.1 -p 15432 -U postgres -d codemojex -c "\du echo_mesh"

# it can connect and write, and reports itself (not the superuser):
PGPASSWORD="$POSTGRES_ECHO_PASSWORD" psql -h 127.0.0.1 -p 15432 -U echo_mesh -d codemojex \
  -c "create table _probe(x int); drop table _probe; select current_user;"

# the node is still private:
fly ips list -a echo-postgres            # empty
```

Confirm `\du echo_mesh` shows `Create DB` and **not** `Superuser`, the probe
table create/drop succeeds, and `current_user` is `echo_mesh`.

## 8 · Boundaries

The `postgresql.conf` facts (`max_connections`, reserved slots, the idle timeout) and
the "no pooler" decision are read from the committed tree (`postgres/postgresql.conf`,
`dashboard/main.go`, `dashboard/README.md`). `10-echo-role.sh` is the as-built bootstrap;
the §2 "add another app" steps and the §3 budget are patterns to apply, not yet-built
scripts. `pgweb/0002-external-roles.sql` (§5) is an unused sketch for *external* access,
kept distinct from the internal-app roles this playbook is about.
