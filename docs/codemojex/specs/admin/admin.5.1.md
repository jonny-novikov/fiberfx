# admin.5.1 · rooms + players list desks

## Goal
Fill the two remaining LIST desks on the shipped admin.5 Shell. `@codemojex/dashboard` renders one live DB view
today (the games list); this rung adds `RoomsView` + `PlayersView`, each mirroring the as-built `GamesView`
template (`useUnit` an `@mercury/effector`-style store → a `@mercury/ui` `Table`) and reading the Bearer-gated
`GET /rooms` + `GET /players` through the existing admin client. Every desk gains **client-side search** and
**client-side pagination** over the ≤200 rows those routes already return — Operator-ruled: the browser filters
and pages the held rows, so no admin route, query param, or `apps/admin` file changes. The sidebar's disabled
Rooms/Players nav is enabled and each desk mounts in the content region; `types.ts`'s partial `RoomSummary` /
`PlayerSummary` stubs are completed to the real `schemas.ts` shapes. It is the read-plane's full desk surface —
the floor the master-detail layer (admin.5.2) and the live game path (admin.5.3) stand on.

## Rationale (5W)
- **Why** — the Shell proves one desk end to end, but the operator still reaches for `curl` to read rooms and
  players. Two list desks close the read plane's browser surface, and the pieces are all shipped — the as-built
  `GamesView` is the exact template, the admin client is a store seam built to be extended, and `@mercury/ui`'s
  `Search` + `Pagination` are in the barrel — so this is a thin compose, not a new capability.
- **What** — two `src/views/` desks (`RoomsView`, `PlayersView`), the admin client extended with the rooms /
  players fetch effects + stores + mount events (mirroring the games seam), the `types.ts` public shapes
  completed, the sidebar nav enabled, and the desks wired into the shell's content region — all client-side
  search + pagination over the held rows.
- **Who** — the human operator browsing the running game, who reads rooms and players from the console rather
  than a terminal.
- **When** — this rung, the first Shell desk increment after admin.5 (the Shell) shipped, before the
  master-detail layer (admin.5.2) and the live game path (admin.5.3).
- **Where** — `mercury/codemojex/apps/dashboard/src/` only (`views/RoomsView.tsx`, `views/PlayersView.tsx`,
  `api/client.ts`, `types.ts`, `App.tsx`, `dashboard.css`), composing `@mercury/ui` + `@mercury/effector` from
  source; reading the shipped `@codemojex/admin` read plane (admin.1); no edit crosses into `apps/admin`,
  `packages/*`, or `echo/`.

## Scope
**In.** `src/views/RoomsView.tsx` + `src/views/PlayersView.tsx`, each mirroring the as-built `GamesView` (a local
`Record`-extending display row, a `Column<Row>[]`, a `toRow` mapper, a mount-request `useEffect`, `<Card
title>` + `<Table columns data striped getRowKey>`); the admin client (`src/api/client.ts`) extended with
`fetchRoomsFx` / `$rooms` / `roomsRequested` and `fetchPlayersFx` / `$players` / `playersRequested` (mirroring
`fetchGamesFx` / `$games` / `gamesRequested`), and `$health` extended to react to all three effects;
`src/types.ts`'s `RoomSummary` / `PlayerSummary` completed to the real `apps/admin/src/schemas.ts` shapes;
`src/App.tsx` enabling the Rooms / Players nav and mounting each desk by `desk` state, with the Refresh action
made desk-aware; **client-side search** (`@mercury/ui` `Search` over name + id) and **client-side pagination**
(`@mercury/ui` `Pagination` over the filtered rows) per desk — realized as the shared app-local
`src/lib/usePagedList.ts` hook (the R6 optional DRY, as-built) — plus a rooms All/Open/Closed status filter
(`@mercury/ui` `Tabs`, the `GamesView` precedent); the small app-local layout CSS for the desk toolbar / pager.

**Out.** Room / player **detail** (a room's games, a player's guesses / ledger) and the detail-interaction model
— that is admin.5.2 (`GET /rooms/:id` + `GET /players/:id`, the selected-id seam, the ruled `Collapsible` /
`Popover` / `Panel` layout). The live game embed + the split game/events view (admin.5.3). Server-side paging or
search (the `/players` `?q` exists but is deliberately unused — the ruled ceiling is client-side over ≤200
rows). Any write / management (admin.2); balances / ledgers (admin.3); moderation (admin.4). A new `@mercury/ui`
reusable primitive or a shared `@mercury/core` paging hook (a `/mercury-ship` concern, rule-of-three — kept
app-local this rung). Any edit to `@codemojex/db`, `apps/admin`, `packages/*`, or the `echo/` engine. The prod
`@fastify/static` same-origin serve (the standing admin.5-F2 → Arm A follow-up).

## Deliverables
- **admin.5.1-D1 — the admin client extended (the store seam).** `src/api/client.ts` gains, mirroring the games
  seam exactly: `fetchRoomsFx = createEffect<void, RoomSummary[]>` calling `fetch(\`${base}/rooms\`, { headers:
  auth() })`; `$rooms = createStore<RoomSummary[]>([]).on(fetchRoomsFx.doneData, …)`; `roomsRequested =
  createEvent()` + `sample({ clock: roomsRequested, target: fetchRoomsFx })` — and the same trio for players
  (`fetchPlayersFx` → `GET /players` → `$players`, `playersRequested`). The Bearer `auth()` helper and the `base`
  are reused unchanged (no second token path). `$health` is extended to react to all three effects
  (`.on(fetchRoomsFx, …)` / `.done` / `.fail`, and likewise players) so the topbar indicator is truthful on
  every desk. No `fetch(` is added outside this file.
- **admin.5.1-D2 — the public shapes completed.** `src/types.ts`'s `RoomSummary` gains the two missing fields
  from `apps/admin/src/schemas.ts` — `clipCost: number | string` and `durationMs: number | null` — for a full
  `{ id, name, free, clipCost, durationMs, status, insertedAt }`. `PlayerSummary` gains the four missing fields —
  `tgUserId: string | number | null`, `clips: number`, `bonusDiamonds: number`, `lockedDiamonds: number` — for a
  full `{ id, name, tgUserId, clips, diamonds, bonusDiamonds, lockedDiamonds, keys, insertedAt }`. Both stay
  precise interfaces (no index signature) and carry no `secret` / `cell_codes` field (rooms and players carry
  none server-side).
- **admin.5.1-D3 — the rooms desk.** `src/views/RoomsView.tsx` mirrors `GamesView`: a `RoomRow extends
  Record<string, unknown>`, a `Column<RoomRow>[]` of public columns (Room id · Name · Status · Free · Clip cost ·
  Duration · Created), a `toRow(r: RoomSummary): RoomRow` mapper, a `useEffect(() => roomsRequested(), [])` mount
  request, an All/Open/Closed status filter (`Tabs`, off `status`), client-side `Search` (name + id) and
  `Pagination` over the filtered rows, rendered as `<Card title="Rooms"><Table columns data striped
  getRowKey/></Card>`. No `fetch` in the view; no `secret` / `cell_codes` column.
- **admin.5.1-D4 — the players desk.** `src/views/PlayersView.tsx` mirrors `GamesView` the same way: a
  `PlayerRow`, a `Column<PlayerRow>[]` of public columns (Player id · Name · Diamonds · Clips · Keys · Created),
  a `toRow`, a `useEffect(() => playersRequested(), [])`, client-side `Search` (name + id) and `Pagination` over
  the rows, rendered as `<Card title="Players"><Table .../></Card>`. No status filter (players have no
  open/closed). No `fetch` in the view; every player column is public.
- **admin.5.1-D5 — the shell wiring.** `src/App.tsx` sets the Rooms / Players `NAV` entries `enabled: true`
  (dropping the stale `"admin.6"` hint), mounts `<RoomsView />` / `<PlayersView />` in the content region by the
  `desk` state (beside the existing `<GamesView />`), and makes the Menubar Refresh action desk-aware — it fires
  the active desk's request event (`gamesRequested` / `roomsRequested` / `playersRequested`). No new `@mercury/ui`
  primitive; the shell frame stays locally composed (admin.5-F1 → Arm B); the barrel is untouched.
- **admin.5.1-D6 — green.** From `mercury/codemojex`: `pnpm --filter @codemojex/dashboard typecheck` exits 0;
  `pnpm --filter @codemojex/dashboard build` produces the SPA bundle; the `@mercury/ui` resolved export set is
  unchanged (0 removed / renamed); a grep confirms no `fetch(` in `src/views/` and no `secret` / `cell_codes`
  field on `types.ts` or in any view.

## Invariants
- **admin.5.1-INV1 — the Bearer gate is the only door.** Every new fetch effect attaches `Authorization: Bearer
  <token>` via the existing `auth()` helper, with `token` from config, never a source literal — the rooms /
  players effects open no second, un-gated path to the admin API. Exercised by a grep (no `"Bearer "` followed by
  a string literal in `src/`) plus the shared `auth()` reuse (a single credential helper).
- **admin.5.1-INV2 — the public schema only.** `src/types.ts` declares no `secret` and no `cell_codes` field on
  `RoomSummary` / `PlayerSummary`, and no desk view reads either key; every rendered room / player column is a
  public read-plane field. Exercised by a structural check on `types.ts` (no `secret` / `cell_codes` field) plus
  a grep that no view reads either key.
- **admin.5.1-INV3 — the barrel holds.** The `@mercury/ui` resolved export set is unchanged by this rung (0
  removed / renamed); the desks compose existing barrel exports (`Table` · `Card` · `Tabs` · `Search` ·
  `Pagination`) and house no reusable component of their own (the package / app split — a shared paging hook, if
  extracted, is a later `/mercury-ship` concern). Exercised by the barrel-diff (the resolved export set) — this
  rung touches only `mercury/codemojex/apps/dashboard`.
- **admin.5.1-INV4 — the two-clock seam holds.** Each desk reads its rows from an `@mercury/effector` store
  (`$rooms` / `$players`) via `useUnit`, never a component-local `fetch` — so a `channel` model can target the
  same store in admin.5.3 without a view rewrite. Exercised by a grep: no `fetch(` inside any `src/views/`
  component; the views read `$rooms` / `$players` through `useUnit`.
- **admin.5.1-INV5 — client-side page + search, no backend edit.** Pagination and search filter and slice the
  client-held rows in the browser: the `Pagination` `count` is a page count computed over the filtered row array
  and `Search` filters the held rows — no admin route, query param, `limit`, or `page` is sent, and the diff
  touches no `apps/admin` file. Exercised by an observable — changing the search query filters the visible rows
  and clicking a page shows the next slice of the SAME fetched array — plus the diff scope (0 `apps/admin` files;
  no new server param in `client.ts`).
- **admin.5.1-INV6 — green + composed.** `pnpm --filter @codemojex/dashboard typecheck` exits 0 and `build`
  produces a bundle; the desks compose `@mercury/*` from source via the existing aliases (no re-implemented
  primitive). Exercised by the typecheck + build commands.

## Definition of Done
- [x] admin.5.1-D1 extends the admin client with the rooms / players store seams and the `$health` fan-in;
  admin.5.1-INV1 (Bearer from config) + admin.5.1-INV4 (store seam) pass (admin.5.1-US1).
- [x] admin.5.1-D2 completes `RoomSummary` / `PlayerSummary` to the real `schemas.ts` shapes with no secret
  field; admin.5.1-INV2 passes (admin.5.1-US2).
- [x] admin.5.1-D3 renders the rooms desk (list + status filter + client-side search + pagination) reading
  `$rooms` via `useUnit` — built + wired, the live read served-pending a standing admin service (the admin.5
  posture); admin.5.1-INV4 + admin.5.1-INV5 pass (admin.5.1-US3).
- [x] admin.5.1-D4 renders the players desk (list + client-side search + pagination) reading `$players`;
  admin.5.1-INV2 + admin.5.1-INV5 pass (admin.5.1-US4).
- [x] admin.5.1-D5 enables the Rooms / Players nav, mounts each desk, and makes Refresh desk-aware;
  admin.5.1-INV3 (barrel holds) passes (admin.5.1-US5).
- [x] admin.5.1-D6 + admin.5.1-INV6: `typecheck` exits 0, `build` produces a bundle, the barrel is unchanged, and
  the secret / `fetch`-in-view greps read 0 (admin.5.1-US6).
- [x] The six spec gates pass on this triad; the ledger records the close (P-7). This rung surfaced **no open
  fork** (the client-side + frontend-only ruling is in hand); admin.5.2's detail-interaction fork and admin.5.3's
  game-embed forks are framed in `admin.5.desks.design.md` for their own rungs.

Stories: [`admin.5.1.stories.md`](./admin.5.1.stories.md) · Agent brief: [`admin.5.1.llms.md`](./admin.5.1.llms.md) · Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
