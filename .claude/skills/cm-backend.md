---
name: cm-backend
description: >-
  The backend capability skill for codemojex-node, lazy-loaded by venus-cm / mars-cm on a SERVICE rung (the
  @codemojex/admin Fastify operator API, a future @codemojex/dashboard API, or any package doing Postgres/Valkey
  I/O). It carries the backend craft the design-system role skills do not: Fastify + @fastify/type-provider-typebox
  (one TypeBox schema → static type + validator + serializer) + Drizzle (@codemojex/db) + Valkey (iovalkey :6390)
  + the @echo/core env reader + @echo/cluster runCluster; the no-secret-on-wire law (the response schema strips
  the server-side secret via fast-json-stringify); the closed error set (401/400/404/500); the bearer preHandler
  auth pattern; the app.inject test craft; and the solo + clustered boot-smoke. The program-wide law lives in the
  shared reference .claude/skills/cm-program.md; read it first. Loaded THROUGH venus-cm / mars-cm — not a role
  skill and not a ship command. Do NOT use for a frontend rung (mars-mercury / venus-mercury), the echo/ codemojex
  Elixir engine (codemojex-ship), or the Mercury packages (mercury-ship).
---

# cm-backend — the backend capability, on codemojex-node

The domain craft `venus-cm` (the reconcile lens) and `mars-cm` (the build) load on a **service** rung. The
program-wide law — the boundary, the gate ladder, the git posture — is the shared reference
**`.claude/skills/cm-program.md`**; this file is the Fastify/Drizzle/Valkey/TypeBox craft on top of it. **NO-INVENT:
the anatomy below is the as-built shape at authoring — re-probe the app's real `src/**` + `package.json` before
citing a signature, and ground every route/field/env-key in a real file.**

## The stack (grounded in `apps/admin/package.json`)

`fastify` + `@fastify/type-provider-typebox` (`@sinclair/typebox`) — **one TypeBox schema is the static type, the
request validator, AND the response serializer** · `drizzle-orm` over `@codemojex/db` (the Postgres record) ·
`iovalkey` (the Valkey client, :6390) · `@fastify/cors` + `@fastify/sensible` · `@echo/core` (the `r.str(...)`
env reader behind `loadEnv`) · `@echo/cluster` (`runCluster`). Re-probe: a "no new dependency" claim is read from
the app's `package.json` `dependencies`, never the root lockfile.

## The as-built anatomy (`apps/admin/src/` — re-probe before citing)

- **`server.ts` — `buildServer(env)`** registers the plugins (`cors`, `sensible`, the Valkey plugin), the
  `/health` route, and the resource routes (`routes/{rooms,games,players}.ts`), returning the Fastify instance;
  `start()` listens. `buildServer` already RECEIVES `env` — thread a new env value (an `ADMIN_TOKEN`) through it,
  never read `process.env` in a handler.
- **`env.ts` — `Env` + `loadEnv`** via the `@echo/core` reader (`r.str("DATABASE_URL")`, the Valkey host/port,
  …). A required key that is absent must fail the boot loudly (`r.str`, not a silent default).
- **`reply.ts` — the Result seam**: `ApiError { status, message }` + `notFound` (404) / `badRequest` (400) +
  `send(reply, result)` writing the wire error shape `{ error: message }`. The **closed error set is
  401/400/404/500** — invent no other status.
- **`schemas.ts` — the TypeBox shapes**: `GameSummary` is the **public** game shape — it lists no `secret` and no
  `keyboard`; `GamesList = Array(GameSummary)`; a detail response nests `game: GameSummary`. `valkey.ts` reads the
  live board (`readBoard` over the `cm:<game>:*` keyspace). Boot entries: `main.ts` → `start`, `cluster.ts` →
  `runCluster`.

## The no-secret-on-wire law (the master invariant)

The `games` row holds a server-side `secret` (and a `keyboard` snapshot) the Elixir engine writes. The admin read
plane must never leak it. The enforcement is **structural, not vigilance**: the TypeBox *response* schema lists
only public columns, so `fast-json-stringify` drops `secret`/`keyboard` **even if a query selected them**. A
backend rung asserts this rather than trusts it — an `app.inject` **response-key** assertion: the `GET /games/:id`
200 body carries no `secret` key and no `keyboard` key. Withholding by serializer contract is the invariant;
the test is its proof.

## The auth pattern (admin.1 — the bearer preHandler)

A control plane over live games + player wallets does not answer unauthenticated. The `admin.1` shape: an
`ADMIN_TOKEN` added to `Env` + `loadEnv` (required) + `.env.example`; a Fastify **`preHandler`** hook in
`buildServer` that lets `GET /health` through with no `Authorization`, and for every other route requires
`Authorization === "Bearer " + env.adminToken`, else `reply.code(401).send({ error: "unauthorized" })`. Coarse,
per-operator identity is deferred to a later auth rung. `/health` stays open for an uptime probe / load balancer.

## The test craft (`app.inject` over `buildServer(testEnv)`)

- **No test runner is wired yet** — `apps/admin` has `typecheck` + `build` + `start` scripts but **no `test`
  script and no runner dep**. A service rung ADDS one: the built-in `node --test` (zero new dep — the default)
  or `vitest` (a devDep add, surface it as a dependency fork if chosen). Add the `test` script in the same change.
- **Drive the real server, not a mock**: `const app = buildServer(testEnv); const res = await app.inject({ method,
  url, headers })`. The acceptance battery for `admin.1`: `GET /rooms` no-token → 401 `{ error: "unauthorized" }`
  · `GET /rooms` with `Bearer` → 200 · `GET /games/:id` with the token (seed or stub a game row) → 200, body
  `game` has no `secret`/`keyboard` key · `GET /health` no-token → 200. **A check counts only if it RUNS** — an
  `async` test that mutates a process-global (`process.env`) races the others; save-and-restore or isolate.

## The boot-smoke (the suite is not the server)

`app.inject` proves the plugin pipeline, NOT that the node boots + binds. Before reporting a service rung done,
resolve **`buildServer(loadEnv()).ready()`** without throwing (against a reachable Postgres + Valkey), and confirm
BOTH entries boot — `start` (`main.ts`) and `runCluster` (`cluster.ts`). A build-local boot is not the live
deploy: the Operator runs deploys — hand off the boot command + verify, never deploy.

## The gate (run from `mercury/codemojex/`, per `cm-program.md`)

```bash
pnpm install
pnpm --filter @codemojex/admin typecheck      # tsc -p tsconfig.json --noEmit, exit 0
pnpm --filter @codemojex/admin build          # tsc -p tsconfig.json
pnpm --filter @codemojex/admin test           # the app.inject suite (add the script + runner if absent)
# + the secret-strip response-key assertion + buildServer(loadEnv()).ready() boot-smoke (solo + clustered).
```

Node ≥20, no `TMPDIR` (Elixir-only). The boundary stays `mercury/codemojex/apps/<app>/**` (+ a `@codemojex/db`
schema change on a data rung, which is a coupling fork — `cm-program.md` § the elixir-coupled capability).
