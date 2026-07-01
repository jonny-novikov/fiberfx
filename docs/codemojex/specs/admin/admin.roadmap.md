# admin · roadmap

The milestone arc for the codemojex operator control plane and the per-iteration plan. The roadmap re-plans freely
and defines no behaviour; the rung bodies ([`admin.1.md`](./admin.1.md) and its successors) are authoritative.
Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md).

## Milestone A — a credential-gated window on the live game

The admin becomes a gated window on the running game — rooms, games, players, and the live board — with the secret
withheld and the workspace green. This is the floor the management, economy, and moderation desks stand on. `@codemojex/admin`
is already scaffolded (`server.ts` `buildServer`/`start`, `routes/{rooms,games,players}.ts`, `schemas.ts`,
`valkey.ts`, `cluster.ts`); Milestone A hardens it and gates it.

## The iterations

### admin.1 · the gated read foundation — SHIPPED ✓
- **Ships.** A Fastify `preHandler` bearer gate (`ADMIN_TOKEN`) over every data route; the read plane
  (`/health`, `/rooms`, `/rooms/:id`, `/games`, `/games/:id`, `/players`, `/players/:id`) schema-typed and
  secret-stripped, its `@codemojex/db` read-model reconciled to the engine's real DDL (games/guesses/players so the
  reads return live data); the `mercury/codemojex` workspace installed, typechecked, and boot-smoked solo + clustered.
- **Demo.** A `curl` with no token → 401; with `Authorization: Bearer $ADMIN_TOKEN` → the rooms / games / players
  JSON; `GET /games/:id` returns a board and recent guesses and no `secret`; `GET /health` answers 200 tokenless.
- **Harness.** `app.inject` tests (401 gate · 200 with token · secret-strip · health-open) + `pnpm --filter
  @codemojex/admin typecheck` + a `buildServer(loadEnv()).ready()` boot smoke.
- **Feedback.** Whether the coarse shared token suffices or per-operator identity is wanted sooner (a later auth rung).

### admin.2 · lifecycle management
- **Ships.** The explicit management endpoints — open / close / void a game, create + configure a room (mode +
  policies) — extending the as-built `PATCH /rooms/:id/status`.
- **Demo.** An operator closes an open game and voids a never-filled gather; the status and board reflect it.
- **Harness.** Write-path `app.inject` tests over `buildServer`; a management action is recorded for audit.
- **Feedback.** The lifecycle actions the operator reaches for first.

### admin.3 · the economy & treasury desk
- **Ships.** Balance and ledger views (the `TXN` transactions and the `RVL` revenue ledger) and the operator side
  of cm.8 — withdrawal review and approval.
- **Demo.** An operator reads a player's wallet ledger and approves a pending withdrawal.
- **Harness.** Ledger-read tests; a withdrawal-approval path test.
- **Feedback.** The treasury operations the cash-out flow needs.

### admin.4 · players & moderation
- **Ships.** Player detail, membership (`RMP`), balance adjustment and ban, and the append-only analytics view (`AEV`).
- **Demo.** An operator adjusts a balance and bans a player; the action lands on the audit trail.
- **Harness.** Moderation-path tests; the audit trail is asserted.
- **Feedback.** The moderation gaps a live game surfaces.

### admin.5 · the console UI (optional)
- **Ships.** A Mercury-UI frontend app consuming the admin API (a sibling of the `economy` and `game` apps).
- **Demo.** The operator drives the API from a browser console instead of `curl`.
- **Harness.** The Mercury app builds; the UI reads the gated API end to end.
- **Feedback.** Whether the API-only surface was enough.

Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
