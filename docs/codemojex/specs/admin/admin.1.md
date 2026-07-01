# admin.1 · the gated read foundation

## Goal
Turn the as-built `@codemojex/admin` read scaffold into a credential-gated operator API: every data route sits
behind an `ADMIN_TOKEN` bearer, the read plane (rooms, games, players, and the live board) returns its
secret-stripped shapes over the `/health`-checked Postgres + Valkey substrate, and the `mercury/codemojex`
workspace is installed, typechecked, and boot-smoked solo and clustered. It is the floor the management, economy,
and moderation rungs stand on.

## Rationale (5W)
- **Why** — the admin API answers unauthenticated today; a control plane over real player wallets and live games
  cannot ship open, and the later write and economy rungs need a proven, gated read surface beneath them.
- **What** — a Fastify `preHandler` bearer gate plus the `ADMIN_TOKEN` env, applied to every route except
  `/health`, over the confirmed-typed read endpoints, with an `app.inject` test suite and a green workspace.
- **Who** — the human operator browsing the running game; `@codemojex/admin` is the surface they hold.
- **When** — this week: admin.1, the first rung of Milestone A, before any management or economy write.
- **Where** — `mercury/codemojex/apps/admin/` (the Fastify app) and `docs/codemojex/specs/admin/` (this triad); no
  edit crosses into the game engine or the `@codemojex/db` schema.

## Scope
**In.** The bearer `preHandler` + the `ADMIN_TOKEN` env (`env.ts`); gating every data route while `/health` stays
open; confirming the read endpoints (`/rooms`, `/rooms/:id`, `/games`, `/games/:id`, `/players`, `/players/:id`)
schema-typed and secret-stripped; an `app.inject` test suite; `pnpm install` + `typecheck` + a boot smoke over
`buildServer` and `runCluster`.

**Out.** New management writes beyond the as-built `PATCH /rooms/:id/status` (admin.2); balances, ledgers, and
withdrawals (admin.3); moderation (admin.4); any UI (admin.5); per-operator identity or audit (a later auth rung);
any change to the `@codemojex/db` schema or the game engine.

## Deliverables
- **admin.1-D1 — the bearer gate.** A Fastify `preHandler` registered in `buildServer` (`server.ts`) rejecting any
  non-`/health` request that lacks `Authorization: Bearer <ADMIN_TOKEN>` with `401 {"error":"unauthorized"}`;
  `ADMIN_TOKEN` added to `Env` and `loadEnv` (`env.ts`, required) and to `.env.example`.
- **admin.1-D2 — the hardened read plane.** The as-built endpoints confirmed behind the gate, each returning its
  TypeBox shape (`schemas.ts`): the rooms / games / players lists and details and the live board (`readBoard`),
  the game shapes secret- and keyboard-free (`gameCols` · `GameSummary`).
- **admin.1-D3 — the test suite.** An `app.inject`-driven suite over `buildServer(env)`: 401 without a token, 200
  with it on each read route, the secret-strip assertion, and `/health` answering tokenless.
- **admin.1-D4 — boots green.** `pnpm install` in `mercury/codemojex`, `pnpm --filter @codemojex/admin typecheck`
  clean, and `buildServer(loadEnv()).ready()` resolving (the boot smoke) for the `start` and `runCluster` entries.

## Invariants
- **admin.1-INV1 — the gate holds.** A request to a data route (for example `GET /rooms`) without a valid
  `Bearer ADMIN_TOKEN` returns 401; the same request with the token returns 200. Exercised by an `app.inject` pair.
- **admin.1-INV2 — no secret on the wire.** The `GET /games/:id` 200 body carries no `secret` key and no
  `keyboard` key. Exercised by an `app.inject` response-key assertion.
- **admin.1-INV3 — health is open.** `GET /health` returns 200 with no `Authorization` header. Exercised by an
  `app.inject` call carrying no token.
- **admin.1-INV4 — the workspace is green.** `pnpm --filter @codemojex/admin typecheck` exits 0 and
  `buildServer(loadEnv()).ready()` resolves without throwing. Exercised by the typecheck command plus the boot smoke.

## Definition of Done
- [ ] admin.1-D1 lands the `preHandler` gate + `ADMIN_TOKEN` env; admin.1-INV1 (401 without / 200 with) passes (admin.1-US1).
- [ ] admin.1-D2 confirms the read plane typed and secret-stripped; admin.1-INV2 (no secret) passes (admin.1-US2).
- [ ] admin.1-INV3 (health open, tokenless 200) passes (admin.1-US3).
- [ ] admin.1-D3 test suite runs green over `buildServer` via `app.inject`.
- [ ] admin.1-D4 + admin.1-INV4: `pnpm install` done, typecheck exits 0, boot smoke resolves solo and clustered (admin.1-US4).
- [ ] The six spec gates pass on this triad; the ledger records the close.

Stories: [`admin.1.stories.md`](./admin.1.stories.md) · Agent brief: [`admin.1.llms.md`](./admin.1.llms.md) · Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
