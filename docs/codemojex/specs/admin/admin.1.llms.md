# admin.1 · agent brief

## References
Read first (cap: these):
- The rung body — [`admin.1.md`](./admin.1.md) — the authoritative Deliverables + Invariants.
- The stories — [`admin.1.stories.md`](./admin.1.stories.md) — the acceptance.
- The index — [`admin.md`](./admin.md) — the master invariant + the closed error set.
- The as-built app (read, do not restate): `mercury/codemojex/apps/admin/src/server.ts` (`buildServer` / `start`),
  `env.ts` (`Env` / `loadEnv`), `reply.ts` (`send` / `ApiError`), `valkey.ts` (`readBoard`), `schemas.ts` (the
  TypeBox shapes), `routes/{rooms,games,players}.ts`, `cluster.ts` (`runCluster`).
- Approach — [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md).

## Requirements
- **admin.1-R1** — add `adminToken: r.str("ADMIN_TOKEN")` to the `Env` interface and `loadEnv` (`env.ts`), required
  at boot; add `ADMIN_TOKEN=` to `.env.example`. [US: admin.1-US1]
- **admin.1-R2** — register a Fastify `preHandler` hook in `buildServer` (`server.ts`) returning
  `401 { "error": "unauthorized" }` for any request whose `Authorization` is not `Bearer <env.adminToken>`,
  exempting `GET /health`. [US: admin.1-US1]
- **admin.1-R3** — keep the read plane shape unchanged: the `GameSummary` / `GameDetail` responses stay secret- and
  keyboard-free; add no field to `gameCols` or the schemas. [US: admin.1-US2]
- **admin.1-R4** — leave `GET /health` reachable with no `Authorization` header. [US: admin.1-US3]
- **admin.1-R5** — add an `app.inject` test suite (`apps/admin/test/admin.test.ts`) covering 401-without-token,
  200-with-token, no-secret, and health-open. [US: admin.1-US1, admin.1-US2, admin.1-US3]
- **admin.1-R6** — `pnpm install` in `mercury/codemojex`; `pnpm --filter @codemojex/admin typecheck` exits 0; a
  boot smoke resolves `buildServer(loadEnv()).ready()` for the `start` and `runCluster` entries. [US: admin.1-US4]

## Execution topology
Runtime:
```
Authorization: Bearer $ADMIN_TOKEN
        |
   preHandler gate (server.ts)  --absent / wrong token-->  401 { "error": "unauthorized" }
        | ok  (or url == /health)
   route handler (routes/*.ts) --> Result<T, ApiError> --> send() --> TypeBox serializer (secret-stripped)
        |
   Postgres (@codemojex/db)  +  Valkey board:<gameId> (readBoard)
```
Tasks (build-order DAG):
```
R1 (ADMIN_TOKEN env) ─┐
                      ├─> R2 (preHandler gate) ─> R5 (inject tests) ─> R6 (typecheck + boot smoke)
R4 (health exempt) ───┘
R3 (secret-strip unchanged) ────────────────────> R5
```
Touched files: `apps/admin/src/env.ts`, `apps/admin/src/server.ts`, `apps/admin/.env.example`,
`apps/admin/test/admin.test.ts` (new). Read-only: `apps/admin/src/{reply,valkey,schemas}.ts`,
`apps/admin/src/routes/{rooms,games,players}.ts`.

## Agent stories
- **admin.1-AS1** [implements admin.1-US1] — Directive: add `ADMIN_TOKEN` to the env reader and a `preHandler`
  bearer gate in `buildServer`, exempting `/health`. Acceptance gate: precondition — `ADMIN_TOKEN` set;
  postcondition — `app.inject GET /rooms` with no token → 401, with the token → 200; invariant — no data route
  answers without the bearer.
- **admin.1-AS2** [implements admin.1-US2] — Directive: hold the read plane secret-free. Acceptance gate:
  postcondition — `app.inject GET /games/:id` (200) `game` has no `secret` / `keyboard`; invariant — `gameCols` and
  `GameSummary` list only public columns.
- **admin.1-AS3** [implements admin.1-US3] — Directive: keep `/health` exempt. Acceptance gate: postcondition —
  a tokenless `app.inject GET /health` → 200 with `{ postgres, valkey, worker }`.
- **admin.1-AS4** [implements admin.1-US4] — Directive: install, typecheck, and boot-smoke the workspace.
  Acceptance gate: postcondition — `pnpm --filter @codemojex/admin typecheck` exit 0 and
  `buildServer(loadEnv()).ready()` resolves; invariant — the `start` and `runCluster` entries both boot.

## Execution plan — first two stories
1. `env.ts`: add `adminToken: r.str("ADMIN_TOKEN")` to the `Env` interface and the `loadEnv` return; add
   `ADMIN_TOKEN=` to `.env.example`. (admin.1-AS1 precondition.)
2. `server.ts`: in `buildServer`, after `app.register(sensible)`, add `app.addHook("preHandler", …)` that lets
   `req.url === "/health"` pass and otherwise requires `req.headers.authorization === "Bearer " + env.adminToken`,
   replying `reply.code(401).send({ error: "unauthorized" })` on a mismatch. (admin.1-AS1 postcondition.)

## Comprehensive implementation prompt
```
Build admin.1 — the gated read foundation — inside mercury/codemojex/apps/admin ONLY.

1. env.ts: add `adminToken: r.str("ADMIN_TOKEN")` to Env + loadEnv (required; boot fails if absent).
   Add ADMIN_TOKEN= to .env.example.
2. server.ts / buildServer(env): register a preHandler hook that (a) lets GET /health through with no
   Authorization, (b) for every other route requires header Authorization === `Bearer ${env.adminToken}`,
   else reply.code(401).send({ error: "unauthorized" }). buildServer already receives env — thread
   env.adminToken through. Do NOT gate /health.
3. Do NOT change gameCols, GameSummary, or any schema — the read plane stays secret- and keyboard-free.
4. Add apps/admin/test/admin.test.ts using app.inject over buildServer(testEnv):
   - GET /rooms, no Authorization -> 401, body { error: "unauthorized" }.
   - GET /rooms, Bearer token     -> 200.
   - GET /games/:id, token (seed or stub a game row) -> 200 and body.game has no secret / keyboard key.
   - GET /health, no Authorization -> 200.
5. Gate, from mercury/codemojex: `pnpm install`; `pnpm --filter @codemojex/admin typecheck` (exit 0); a
   boot smoke where `buildServer(loadEnv()).ready()` resolves; the inject suite is green. Confirm the
   start (main.ts) and runCluster (cluster.ts) entries both boot.

Ground every symbol in the real files. Invent no endpoint, schema, or dependency. Boundary: apps/admin only —
no @codemojex/db schema edit, no game-engine edit. Report the gate output verbatim.
```

Stories: [`admin.1.stories.md`](./admin.1.stories.md) · Spec: [`admin.1.md`](./admin.1.md) · Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
