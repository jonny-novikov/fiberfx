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

## Milestone B — the operator console (the frontend track)

The admin's read plane earns a face. Where Milestone A proves the gated API with `curl`, Milestone B turns it
into an operator **UX/DX for the DB view** — a `@codemojex/dashboard` React SPA composing `@mercury/ui` +
`@mercury/effector`, reading the same Bearer-gated read plane, with a forward slot for live Phoenix-channel
data. The frontend track is the focus from here, not an afterthought: the API is built (Milestone A) and the
design system it composes is mature. Two shipped foundations carry it:

- **`@mercury/ui` is mature** — a broad barrel (data-display `Table`/`DataList`/`Stat`/`Card`/`Badge`,
  navigation `Tabs`/`Menubar`/`Pagination`, inputs `Search`/`Select`, feedback `Alert`/`Spinner`/`Skeleton`,
  layout `AuthLayout`/`ScrollArea`); the Shell composes it and houses no reusable component of its own (the
  package/app split — a reusable primitive is a `/mercury-ship` concern, surfaced as a fork).
- **`@mercury/effector`'s `channel` adapter is the pubsub foundation** — `createChannel` + the
  `mercury/codemojex/apps/game/src/channel/model.ts` + `PhoenixGame.tsx` pattern already bind a Phoenix
  channel to an Effector model. The dashboard's live-data slot (admin.7) seats on this exact adapter, so it is
  added later with no rewrite of the Shell's data layer.

> **`@codemojex/economy` disambiguation.** The `economy` **app** (`mercury/codemojex/apps/economy`) is a
> **static** revenue-model calibration console served at `/economy` with **no API** — it is a structural
> sibling SPA the Shell mirrors, not a data source. It is distinct from admin.3's economy & treasury **desk**
> (the balances / `TXN` / `RVL` ledger API surface). The Shell reads only the `@codemojex/admin` read plane.

> **Note (not a decision).** As the frontend track deepens it could graduate from the admin chapter to its own
> `docs/codemojex/specs/dashboard/` chapter (the anticipated `dashboard.*` home). Kept in `admin.*` for now to
> preserve continuity with the read plane it consumes.

### admin.5 · the dashboard Shell — THE FOCUS
- **Ships.** The `@codemojex/dashboard` app skeleton (a Vite + React SPA in the mercury workspace, mirroring
  the `economy`/`game` scaffolding): an operator **shell layout** (sidebar + topbar + content) composed from
  `@mercury/ui`; the **admin API client** (Bearer `$ADMIN_TOKEN` → the read plane) as an
  `@mercury/effector`-style model; and ONE end-to-end **DB view** (the games or rooms list) proving the full
  stack against the live gated API. The data layer is a **two-clock seam** — admin HTTP now, the effector
  `channel` pubsub later — so admin.7 adds live data without a rewrite.
- **Demo.** An operator opens the console in a browser; the shell renders; the one DB view lists live
  games/rooms from the gated API (the Bearer flowing from config, never hard-coded); no `secret` / `cell_codes`
  appears on any row.
- **Harness.** `pnpm --filter @codemojex/dashboard typecheck` + `build` green; the client reads the gated API
  end to end; the `@mercury/ui` barrel is unchanged (0 removed/renamed).
- **Feedback.** Whether the shell layout + the one DB view are the right operator frame before the desks fan
  out. (The shell frame is composed locally — ruled admin.5-F1 → Arm B; the shared `@mercury/ui` `AppShell`
  extraction is the ruled-deferred item, rule-of-three: a later `/mercury-ship` rung once a 2nd console proves
  the shape.)

### admin.6 · the DB-view desks (sketch)
- **Ships.** The remaining read desks over the shell — rooms, games, players list + detail, each a
  `@mercury/ui` `Table`/`DataList` view reading the gated API, with pagination + search + navigation across
  rooms/games/players/board. Consumes the Shell's client + layout; adds no new data-transport.
- **Demo.** The operator browses every read surface from the console instead of `curl`.
- **Harness.** Each desk builds + reads the gated API; the barrel holds.

### admin.7 · the live pubsub channel (sketch)
- **Ships.** The live-data slot filled — a Phoenix-channel feed (a live board / room state) seated on the
  `@mercury/effector` `channel` adapter (the `game/src/channel/model.ts` pattern), so a desk updates in place
  off server pushes rather than a poll. This wires the two-clock seam's second clock; the engine-side channel
  is a coupling surface (an `echo/` concern, forked to `/codemojex-ship`).
- **Demo.** A live game's board updates in the console with no refresh.
- **Harness.** The channel model binds; a desk re-renders off a push.

Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
