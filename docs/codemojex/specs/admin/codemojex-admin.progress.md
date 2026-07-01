# codemojex-admin — AAW scope ledger

## {codemojex-admin-decisions} Decisions

### D-1

admin.1 scope = the gated read foundation — Operator-ruled. This week ships admin.1: harden the as-built Fastify read plane (/health, rooms, games, players + live Valkey board) into a real operator API — auth-gated, TypeBox-typed, secret-never-on-wire, bootable solo + clustered, with tests. Management (admin.2), economy/treasury incl. cm.8 (admin.3), moderation (admin.4) ladder behind it. Rationale: the read foundation is the floor every later write/economy rung stands on.

### D-2

admin.1 auth = operator bearer token — Operator-ruled. The admin API currently has NO access control; admin.1 adds a Fastify preHandler checking a bearer against an env ADMIN_TOKEN (one shared operator credential, zero new deps). Coarse by design — per-operator identity/audit is deferred to a later rung. Chosen over the Telegram-admin allowlist (heavier: pulls in SES/initData verify) and over deferring auth (open API = weakest posture).

### D-3

The mercury workspace-wiring fix — Operator-ruled (a reconcile prerequisite). admin.1's build blocked on `mercury/pnpm-workspace.yaml` globbing the renamed-away `codemojex-node/*` (dead since the codemojex-node→codemojex rename); with no own workspace file, pnpm walked up to `mercury/` and left codemojex's `workspace:*` deps unlinked. codemojex CANNOT be standalone — its `@echo/core`/`@echo/cluster` deps live in `mercury/packages/`, forcing shared membership. Fix: repoint the glob to `codemojex/{packages,apps}/*`, EXCLUDE `apps/game` (its own nested workspace + lockfile). Director-applied + verified (a filter-resolution check). The `mercury/pnpm-workspace.yaml` + rewritten `mercury/pnpm-lock.yaml` are the Operator's in-flight mercury infra — a SEPARATE commit concern from the admin.1 code.

### D-4

The @codemojex/db drift = full read-model reconcile — Operator-ruled. The live games/guesses/players reads 500'd: `@codemojex/db` was hand-modeled "from observation" (its header says so) and had drifted broadly from the engine's migration DDL — a fictional `room_id`/`prize_usd`/`totals` (games), `game_id`/`codes`/`score` (guesses), `available_*` (players). Blast radius = admin-only (no other `@codemojex/db` importer). Ruled: full reconcile NOW (over games-path-only or close-lean), folded into admin.1, revising admin.1-R3 (the read-plane shapes change to the real columns). Two waves (schema.ts → routes + response schemas + test) against the migration DDL as truth; the real secret columns are `secret` + `cell_codes`.

## {codemojex-admin-progress} Progress

### P-1

admin chapter authored + gated — sharpen complete. Wrote docs/codemojex/specs/admin/{admin.md (index), admin.roadmap.md, admin.1.md, admin.1.stories.md, admin.1.llms.md} to aaw.specs-approach.md. Six gates GREEN: voice · structure (6 §, 5 5W bullets) · traceability (Coverage + every INV encoded + R#[US:] + AS#[implements]) · fences · format via the sweep, and links via mcp__msh__specs (no findings). Grounded in the as-built Fastify app (server.ts buildServer, env.ts loadEnv, reply.ts send, schemas.ts, routes/{rooms,games,players}.ts, valkey.ts readBoard, cluster.ts runCluster) — no invention. admin.1 = the gated read foundation: a Fastify preHandler bearer gate (ADMIN_TOKEN, /health exempt) over the as-built read plane, secret-never-on-wire, boots green solo + clustered. NEXT (build stage): implement admin.1 (Mars) — pnpm install in mercury/codemojex (deps absent), env.ts adminToken, the preHandler, apps/admin/test/admin.test.ts app.inject suite, typecheck + boot smoke.

### P-2

admin.1 BUILT + SHIPPED via /cm-ship (the harness's inaugural run). The bearer gate (`ADMIN_TOKEN` + a `preHandler` in `buildServer`, `/health` exempt, 401 `{error:"unauthorized"}`) + the `app.inject` suite (`node --test` via tsx, zero new dep) + the boot-smoke; then the D-4 read-model reconcile (games/guesses/players → the engine DDL) so the reads return live data. All four invariants LIVE-proven + green: INV1 (401/200 gate) live + mutation-verified (invert the gate → 4 tests fail); INV2 (no `secret`/`cell_codes`) proven LIVE on a real game (`GAM0OQGpUv3naC`) + structural + mutation-verified (leak the secret → 2 tests fail, reverted net-zero); INV3 (health open) live; INV4 (typecheck 0 + boot-smoke ready). Suite 7 pass / 0 skip. Director verify: an independent gate re-run + a schema↔information_schema diff + two net-zero mutation kills. Boundary held: `mercury/codemojex/apps/admin/**` + `packages/db/src/schema.ts`; no echo/ edit. Realizations: the shared-app-per-suite test (the `@codemojex/db` `sql` singleton); `preHandler` runs after validation (so the 401 tests hit list routes); the games→rooms join = `eq(games.room, rooms.id)` (a RoomId string, not a FK). L: cm-program's "installs independently" floor claim was WRONG (codemojex is a `mercury/` member) — corrected; the write-ready 2-wave reconcile (schema checkpoint → wiring) held.
