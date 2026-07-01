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
- **Where** — `mercury/codemojex/apps/admin/` (the Fastify app) and `mercury/codemojex/packages/db` (the
  `@codemojex/db` read-model, reconciled to the engine's real DDL — see admin.1-D2), plus
  `docs/codemojex/specs/admin/` (this triad); no edit crosses into the echo/ game engine (the system of record).

## Scope
**In.** The bearer `preHandler` + the `ADMIN_TOKEN` env (`env.ts`); gating every data route while `/health` stays
open; confirming the read endpoints (`/rooms`, `/rooms/:id`, `/games`, `/games/:id`, `/players`, `/players/:id`)
schema-typed and secret-stripped; reconciling the `@codemojex/db` read-model to the engine's real schema so the
reads return live data; an `app.inject` test suite; `pnpm install` + `typecheck` + a boot smoke over `buildServer`
and `runCluster`.

**Out.** New management writes beyond the as-built `PATCH /rooms/:id/status` (admin.2); balances, ledgers, and
withdrawals (admin.3); moderation (admin.4); any UI (admin.5); per-operator identity or audit (a later auth rung);
any edit to the echo/ game engine (the system of record — the `@codemojex/db` read-model was corrected to match
it, never the reverse).

## Deliverables
- **admin.1-D1 — the bearer gate.** A Fastify `preHandler` registered in `buildServer` (`server.ts`) rejecting any
  non-`/health` request that lacks `Authorization: Bearer <ADMIN_TOKEN>` with `401 {"error":"unauthorized"}`;
  `ADMIN_TOKEN` added to `Env` and `loadEnv` (`env.ts`, required) and to `.env.example`.
- **admin.1-D2 — the hardened, reconciled read plane.** The as-built endpoints behind the gate, each returning its
  TypeBox shape (`schemas.ts`): the rooms / games / players lists and details and the live board (`readBoard`). The
  `@codemojex/db` read-model (games / guesses / players) was reconciled to the engine's real migration DDL — it had
  drifted (a fictional `room_id` / `prize_usd` / `totals` on games, `game_id` / `codes` / `score` on guesses,
  `available_*` on players), so every game / guess / player read `500`d until corrected. The game shapes stay
  secret-free: `gameCols` · `GameSummary` list only public columns, so the real server-side secrets — `secret` and
  `cell_codes` — never serialize.
- **admin.1-D3 — the test suite.** An `app.inject`-driven suite over `buildServer(env)`: 401 without a token, 200
  with it on each read route, the secret-strip assertion (structural over `GameSummary` + a live real-game body),
  and `/health` answering tokenless.
- **admin.1-D4 — boots green.** `pnpm install` in `mercury/codemojex` (a member of the `mercury/` pnpm workspace),
  `pnpm --filter @codemojex/admin typecheck` clean, and `buildServer(loadEnv()).ready()` resolving (the boot smoke)
  for the `start` and `runCluster` entries.

## Invariants
- **admin.1-INV1 — the gate holds.** A request to a data route (for example `GET /rooms`) without a valid
  `Bearer ADMIN_TOKEN` returns 401; the same request with the token returns 200. Exercised by an `app.inject` pair.
- **admin.1-INV2 — no secret on the wire.** The `GET /games/:id` 200 body carries no `secret` key and no
  `cell_codes` key (the two server-side secret columns the engine writes). Exercised by a structural `GameSummary`
  assertion plus a live `app.inject` response-key assertion against a real game.
- **admin.1-INV3 — health is open.** `GET /health` returns 200 with no `Authorization` header. Exercised by an
  `app.inject` call carrying no token.
- **admin.1-INV4 — the workspace is green.** `pnpm --filter @codemojex/admin typecheck` exits 0 and
  `buildServer(loadEnv()).ready()` resolves without throwing. Exercised by the typecheck command plus the boot smoke.

## Definition of Done
- [x] admin.1-D1 lands the `preHandler` gate + `ADMIN_TOKEN` env; admin.1-INV1 (401 without / 200 with) passes, live + mutation-verified (admin.1-US1).
- [x] admin.1-D2 reconciles the read plane to the engine DDL and confirms it secret-stripped; admin.1-INV2 (no `secret` / `cell_codes`) passes live on a real game + structurally (admin.1-US2).
- [x] admin.1-INV3 (health open, tokenless 200) passes (admin.1-US3).
- [x] admin.1-D3 test suite runs green over `buildServer` via `app.inject` (7 pass, 0 skip).
- [x] admin.1-D4 + admin.1-INV4: `pnpm install` done, typecheck exits 0, boot smoke resolves solo and clustered (admin.1-US4).
- [x] The six spec gates pass on this triad; the ledger records the close.

Stories: [`admin.1.stories.md`](./admin.1.stories.md) · Agent brief: [`admin.1.llms.md`](./admin.1.llms.md) · Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
