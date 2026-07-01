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
  channel to an Effector model. The dashboard's live-data slot (admin.5.3) seats on this exact adapter, so it is
  added later with no rewrite of the Shell's data layer.

> **`@codemojex/economy` disambiguation.** The `economy` **app** (`mercury/codemojex/apps/economy`) is a
> **static** revenue-model calibration console served at `/economy` with **no API** — it is a structural
> sibling SPA the Shell mirrors, not a data source. It is distinct from admin.3's economy & treasury **desk**
> (the balances / `TXN` / `RVL` ledger API surface). The Shell reads only the `@codemojex/admin` read plane.

> **Note (not a decision).** As the frontend track deepens it could graduate from the admin chapter to its own
> `docs/codemojex/specs/dashboard/` chapter (the anticipated `dashboard.*` home). Kept in `admin.*` for now to
> preserve continuity with the read plane it consumes.

### admin.5 · the dashboard Shell — BUILT ✓ (gate green; live read served-pending a standing admin service)
- **Built.** `@codemojex/dashboard` — a Vite+React SPA at `mercury/codemojex/apps/dashboard` (11 files, mirroring
  `economy`): the operator shell (a `Menubar` topbar + a local token-styled sidebar + a `ScrollArea` content
  region, composed from `@mercury/ui` per F1→Arm B, the barrel untouched), the Bearer `@mercury/effector`-style
  admin client (`$games` + a derived `$health` store; the token from config), and the live **games** DB view
  (`useUnit($games)` → `@mercury/ui` `Table`; a client-side All/Live/Ended filter off `endsMs`; no
  `secret`/`cell_codes`). `typecheck` + `build` green (bundle 236 kB / gzip 78 kB); the two-clock store seam holds
  (admin.5.3 seats a `channel` model into `$games`). Via `/cm-ship` (Director + mars-cm Duo); the prod
  `@fastify/static` same-origin serve remains the named `apps/admin` follow-up.
- **Ships.** The `@codemojex/dashboard` app skeleton (a Vite + React SPA in the mercury workspace, mirroring
  the `economy`/`game` scaffolding): an operator **shell layout** (sidebar + topbar + content) composed from
  `@mercury/ui`; the **admin API client** (Bearer `$ADMIN_TOKEN` → the read plane) as an
  `@mercury/effector`-style model; and ONE end-to-end **DB view** (the games or rooms list) proving the full
  stack against the live gated API. The data layer is a **two-clock seam** — admin HTTP now, the effector
  `channel` pubsub later — so admin.5.3 adds live data without a rewrite.
- **Demo.** An operator opens the console in a browser; the shell renders; the one DB view lists live
  games/rooms from the gated API (the Bearer flowing from config, never hard-coded); no `secret` / `cell_codes`
  appears on any row.
- **Harness.** `pnpm --filter @codemojex/dashboard typecheck` + `build` green; the client reads the gated API
  end to end; the `@mercury/ui` barrel is unchanged (0 removed/renamed).
- **Feedback.** Whether the shell layout + the one DB view are the right operator frame before the desks fan
  out. (The shell frame is composed locally — ruled admin.5-F1 → Arm B; the shared `@mercury/ui` `AppShell`
  extraction is the ruled-deferred item, rule-of-three: a later `/mercury-ship` rung once a 2nd console proves
  the shape.)

> **The Shell desk ladder (admin.5.1–5.4).** The coarse admin.6 (DB-view desks) + admin.7 (live pubsub) sketches
> are dissolved into a finer sub-ladder under the shipped admin.5 Shell — each a thin, frontend-only increment on
> the `@codemojex/dashboard` console that composes the Shell's client + layout. admin.5.3 **subsumes** the old
> admin.7 (the live-channel slot arrives folded into the room→game navigational path). The framed forks for
> admin.5.2 (the detail-interaction model) and admin.5.3 (the game-embed model · the spectator bridge · the
> split-view) live in the desk-ladder design doc [`admin.5.desks.design.md`](./admin.5.desks.design.md); the
> Operator rules them before those rungs build. Pagination + search across the desks are **client-side** (filter /
> page the ≤200 rows the read routes already return, in the browser) — Operator-ruled — so admin.5.1/5.2 are
> **frontend-only** (`apps/dashboard`), no backend edit.

### admin.5.1 · rooms + players list desks — BUILT ✓ (gate green; live read served-pending a standing admin service)
- **Built.** `RoomsView` + `PlayersView` at `mercury/codemojex/apps/dashboard/src/views/`, each mirroring the
  shipped `GamesView` (`useUnit` a store → a `@mercury/ui` `Table`), reading the gated `GET /rooms` + `GET
  /players` through the extended Bearer client — `fetchRoomsFx`/`$rooms`/`roomsRequested` + the players trio,
  one `auth()` path, `$health` fanned into all three effects. Client-side `Search` (name + id) + `Pagination`
  (PAGE_SIZE 25, page-reset on query/filter change, a `Showing X–Y of Z` caption) via the shared app-local
  `src/lib/usePagedList.ts` hook (the R6 optional DRY); the rooms desk adds the All/Open/Closed `Tabs` filter;
  `types.ts` completed to the real `schemas.ts` shapes; the sidebar nav enabled + the Menubar Refresh
  desk-aware. `typecheck` + `build` green (bundle 242 kB / gzip 79 kB); the barrel untouched; the secret /
  `fetch`-in-view greps read 0. Via `/cm-ship` (Director + mars-cm Duo).
- **Ships.** The two remaining LIST desks over the Shell — `RoomsView` + `PlayersView`, each mirroring the
  as-built `GamesView` (`useUnit` a store → a `@mercury/ui` `Table`), reading the gated `GET /rooms` + `GET
  /players` through the Bearer client. Client-side **search** (`@mercury/ui` `Search`) + **pagination**
  (`@mercury/ui` `Pagination`) over the ≤200 client-held rows, and a rooms All/Open/Closed status filter. The
  sidebar's Rooms/Players nav is enabled; `types.ts`'s `RoomSummary`/`PlayerSummary` stubs are completed to the
  real `schemas.ts` shapes; no `secret`/`cell_codes` on any row; the barrel untouched.
- **Demo.** The operator switches to Rooms, searches by name, pages through the list; switches to Players, same;
  every row is a public column only — no secret leaks.
- **Harness.** `pnpm --filter @codemojex/dashboard typecheck` + `build` green; a grep confirms no `fetch(` in
  `src/views/` and no `secret`/`cell_codes` field; the `@mercury/ui` resolved export set is unchanged.
- **Feedback.** Whether client-side search/paging over ≤200 rows is the right ceiling before a server-paged desk
  is wanted (the `/players` server `?q` exists, deliberately unused this rung).

### admin.5.2 · master-detail (the side-panel detail desk) — BUILT ✓ (gate green; live read served-pending a standing admin service)
- **Built.** The keyed detail seam + two side panes at `mercury/codemojex/apps/dashboard/src/`:
  `roomSelected`/`roomDeselected`/`fetchRoomDetailFx`/`$selectedRoomId`/`$roomDetail` + the identical players
  trio in `api/client.ts` (one `auth()` path; `$health` fanned over all five effects), with the detail stores
  filled through a **selection-filtered `sample`** off `.done` (`sel === params`) so a late reply for a
  superseded or cleared selection is dropped — the Director-verify hardening (a keyed `createEffect` has no
  take-latest). `RoomDetailPane` (status `Badge` + `DataList` summary + games as a nested `Table`, empty/loading
  states) + `PlayerDetailPane` (`Stat` balances + `DataList` + guesses as `ListRow`s + the `unknown[]` ledger
  rendered defensively) beside the narrowed lists in a `dsh-md*` two-region grid (stacks at the 860px
  breakpoint); selection rides a `Column.render` `Button` cell (no Table row-click — the barrel untouched);
  desk switch deselects. `typecheck` + `build` green (bundle 249 kB / gzip 81 kB); the secret / `fetch`-in-view
  greps read 0. Via `/cm-ship` (Director + mars-cm Duo, two-pass: build → verify finding → harden).
- **Ships.** The detail layer over the list desks, the ruled **Arm C (master-detail)** — a room's games and a
  player's guesses/ledger, read from the shipped `GET /rooms/:id` + `GET /players/:id` on a `$selectedId` + keyed
  `fetchDetailFx(id)` store seam, rendered in a **side pane** (`Card` + `ScrollArea`, composed locally — no new
  primitive) beside the narrowed list: the room summary (`DataList`/`Badge`) + its games (nested `Table`); the
  player summary/balances (`DataList`/`Stat`) + guesses + wallet ledger (`DataList`/`ListRow`). Selection rides a
  `Column.render` action cell (`Table` has no row-click prop — so the barrel holds). Frontend-only; no backend
  edit; no `secret`/`cell_codes`.
- **Demo.** The operator selects a room and views its games (and a player and their recent guesses/balances) in a
  side pane without leaving the console; switching desks clears the pane.
- **Harness.** `pnpm --filter @codemojex/dashboard typecheck` + `build` green; the panes read the gated `:id`
  routes via keyed effects; a grep confirms no `fetch(` in `src/views/` and no secret field; the barrel holds.
- **Feedback.** Whether the side-panel density reads well before the live game path extends the same seam.
- **Ruled (Operator, D-6 → Arm C).** Triad authored: [`admin.5.2.md`](./admin.5.2.md) ·
  [`admin.5.2.stories.md`](./admin.5.2.stories.md) · [`admin.5.2.llms.md`](./admin.5.2.llms.md); the arms are kept
  as decision-context in [`admin.5.desks.design.md`](./admin.5.desks.design.md) (admin.5.2-F1).

### admin.5.3 · the live game path — room → game → the game view — RULED PHASED (interim now / live later)
- **Ships (interim, node-only).** The critical navigational path — room → game → the game view — as a spectator
  board **re-rendered** from the shipped `GET /games/:id` (board + guesses) via `@mercury/ui` + a poll for
  near-live, on a **side-by-side split** (game | events/guesses), the room→game nav extending admin.5.2's
  `$selectedId` seam. Frontend-only, ZERO echo/ coupling.
- **Ships (live upgrade, later — a `/codemojex-ship` engine fork).** The TRUE live view — `mount`-ing the
  `@codemojex/game` island + a read-only engine `game:spectate:<id>` topic seated on the `@mercury/effector`
  `channel` adapter — swaps in with **no rewrite** (the two-clock seam's second clock). The engine topic + authz
  is an `echo/` concern, out of the codemojex-node boundary.
- **Demo.** The operator navigates room → game and watches the board update (interim: a polled re-render; live
  upgrade: the actual island), beside a live guesses feed.
- **Harness.** The game view builds + reads the gated `:id` route; the split renders; the barrel holds; (live
  upgrade) the spectator feed binds once the engine channel exists.
- **Feedback.** Whether the re-rendered split is enough before the live island-mount is worth the engine fork.
- **Ruled (Operator, D-6 → phased):** F1 → Arm C (re-render) interim / Arm A (island-mount) later · F2 → Arm C
  (poll) interim / Arm A (engine topic) later · F3 → Arm A (side-by-side). The full triad is authored at admin.5.3's
  own build run; the ruled design entry is [`admin.5.desks.design.md`](./admin.5.desks.design.md) (admin.5.3-F1/F2/F3).

### admin.5.4 · observability & shared filter-state — RULED (5.4-a)
- **Ships.** The ruled **5.4-a** — a console-wide observability surface: a header `Stat` strip (live counts —
  open games, active rooms, players) + a URL-encoded filter/search state (linkable, refresh-surviving) + a
  per-desk auto-refresh cadence. Frontend-only (reads the existing read plane, computes counts client-side).
- **Demo.** The operator reads live counts at a glance and shares a URL that restores a filtered desk view.
- **Harness.** `typecheck` + `build` green; the counts derive from the existing stores; the barrel holds.
- **Feedback.** Whether observability is the right next step before the write twin (5.4-b).
- **Ruled (Operator, D-6 → 5.4-a).** 5.4-b (operator actions / the read-plane write twin) is deferred to pair with
  admin.2. Stays a roadmap entry (no triad yet); the candidate sketches are in
  [`admin.5.desks.design.md`](./admin.5.desks.design.md) § admin.5.4.

Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
