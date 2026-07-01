# admin.5.2 · master-detail (the side-panel detail desk)

## Goal
Add the detail layer over the admin.5.1 list desks. Selecting a room or a player opens its detail in a **side
panel** beside the narrowed list — the ruled **Arm C (master-detail)** shape (D-6). A `$selectedId` store plus a
**keyed** detail-fetch effect (`fetchRoomDetailFx(id)` → `GET /rooms/:id`, `fetchPlayerDetailFx(id)` → `GET
/players/:id`, both shipped in admin.1) feed a pane composed **locally** from `@mercury/ui` `Card` + `ScrollArea`
(no new primitive — the admin.5-F1 → Arm B locality rule holds): a room's summary + its games, and a player's
summary + recent guesses + wallet ledger. Selection rides a `Column.render` action cell — `Table` carries no
row-click prop, so no barrel change. The same `$selectedId` + keyed-detail seam is what admin.5.3 extends
(room → game → the live pane), so this rung is both the detail desk and the master-detail spine beneath the live
game path.

## Rationale (5W)
- **Why** — the list desks (admin.5.1) show rows but not depth; an operator investigating a room needs its games,
  and a player needs their guesses and balances. A side-panel master-detail reads at operator density (it holds
  the player ledger without cramming), keeps the list in view, and establishes the one selected-id seam the live
  game path (admin.5.3) reuses — so it is the highest-leverage detail model, ruled Arm C.
- **What** — a `$selectedId` + keyed-detail store seam for rooms and players, a selection affordance on the
  admin.5.1 list desks, and two detail panes (room, player) composed locally from `@mercury/ui`, laid out beside
  the narrowed list.
- **Who** — the human operator drilling from a list into one room's or player's detail without leaving the
  console.
- **When** — this rung, after admin.5.1 (the list desks) and before admin.5.3 (the live game path, which extends
  this rung's selected-id seam).
- **Where** — `mercury/codemojex/apps/dashboard/src/` only (`api/client.ts`, `types.ts`, `views/RoomsView.tsx`,
  `views/PlayersView.tsx`, new `views/RoomDetailPane.tsx` + `views/PlayerDetailPane.tsx`, `dashboard.css`),
  composing `@mercury/ui` + `@mercury/effector` from source; reading the shipped `@codemojex/admin` `:id` routes
  (admin.1); no edit crosses into `apps/admin`, `packages/*`, or `echo/`.

## Scope
**In.** The admin client (`src/api/client.ts`) extended with the **keyed** detail seam: `fetchRoomDetailFx =
createEffect<string, RoomDetail>` + `$selectedRoomId` + `$roomDetail` + `roomSelected` / `roomDeselected` events,
and the same players trio (`fetchPlayerDetailFx` → `PlayerDetail`, `$selectedPlayerId`, `$playerDetail`), with
`$health` extended to react to the detail effects; `src/types.ts` gaining `RoomDetail` / `RoomGameItem` and
`PlayerDetail` / `GuessDetail` (grounded in `apps/admin/src/schemas.ts`); a **selection affordance** on the
admin.5.1 `RoomsView` / `PlayersView` (a `Column.render` action cell — an `@mercury/ui` `Button` — firing
`roomSelected(id)` / `playerSelected(id)`); two detail panes — `RoomDetailPane` (the room summary as `DataList` /
`Stat` + a `Badge` status + its games as a nested `Table`) and `PlayerDetailPane` (the player summary +
balances as `DataList` / `Stat` + recent guesses and the wallet ledger as `DataList` / `ListRow`) — each with an
empty ("select a row") and a loading state; the master-detail **layout** (list region | side pane) composed
locally from `Card` + `ScrollArea`, with app-local `dsh-md*` CSS; deselect on desk switch.

**Out.** Any NEW backend route or query param, or any `apps/admin` edit — the detail reads the **shipped**
`GET /rooms/:id` + `GET /players/:id` (admin.1). The game detail pane and the live game embed / split (admin.5.3
— though this rung's selected-id seam is what it extends). Server-side anything (the client-side ceiling from
admin.5.1 holds). Any write / management (admin.2); a game-detail (`GET /games/:id`) desk. A new `@mercury/ui`
reusable primitive — a `Panel` / `SplitPane` / a `Table` row-click — is a `/mercury-ship` fork, kept app-local
this rung (rule-of-three). A shared `@mercury/core` master-detail hook (same deferral). Any edit to
`@codemojex/db`, `apps/admin`, `packages/*`, or the `echo/` engine.

## Deliverables
- **admin.5.2-D1 — the keyed detail store seam.** `src/api/client.ts` gains, for rooms: `fetchRoomDetailFx =
  createEffect<string, RoomDetail>` calling `fetch(\`${base}/rooms/${id}\`, { headers: auth() })`; `roomSelected =
  createEvent<string>()` + `roomDeselected = createEvent()`; `$selectedRoomId =
  createStore<string | null>(null).on(roomSelected, (_s, id) => id).reset(roomDeselected)`; `$roomDetail =
  createStore<RoomDetail | null>(null).on(fetchRoomDetailFx.doneData, (_s, d) => d).reset(roomDeselected)`;
  `sample({ clock: roomSelected, target: fetchRoomDetailFx })` — selecting a row sets the id AND fires the keyed
  fetch. The same trio for players (`fetchPlayerDetailFx` → `PlayerDetail`, `$selectedPlayerId`, `$playerDetail`,
  `playerSelected` / `playerDeselected`). `$health` is extended to react to both detail effects. The Bearer
  `auth()` / `base` are reused; no `fetch(` is added outside this file.
- **admin.5.2-D2 — the detail types.** `src/types.ts` gains `RoomGameItem = { id: string; status: string; free:
  boolean; prizePool: number | string; endsMs: number | null; insertedAt: string }` and `RoomDetail = { room:
  RoomSummary; games: RoomGameItem[] }`; `GuessDetail = { id: string; gameId?: string; points: number; atMs?:
  number | null; insertedAt: string }` and `PlayerDetail = { player: PlayerSummary; guesses: GuessDetail[];
  ledger: unknown[] }` — grounded in `apps/admin/src/schemas.ts` (`RoomDetail` / `RoomGameItem` / `PlayerDetail` /
  `GuessSummary`). No `secret` / `cell_codes` field on any detail shape; the `ledger` is `unknown[]` (provisional
  server-side) and is rendered defensively.
- **admin.5.2-D3 — the rooms master-detail.** The admin.5.1 `RoomsView` gains a selection affordance — a
  `Column.render` cell (an `@mercury/ui` `Button`, variant `ghost`/`soft`) firing `roomSelected(row.id)` — and a
  `RoomDetailPane` (`src/views/RoomDetailPane.tsx`) that reads `$selectedRoomId` + `$roomDetail` via `useUnit` and
  renders, inside a local `Card` + `ScrollArea`: the room summary (`DataList` of name / free / clipCost /
  durationMs / created + a `Badge` for status) and the room's games as a nested `Table` (id · status · free ·
  prizePool · endsMs · created). An empty state when nothing is selected; a loading state on
  `fetchRoomDetailFx.pending`. No `fetch` in either view; no `secret` / `cell_codes` column.
- **admin.5.2-D4 — the players master-detail.** The admin.5.1 `PlayersView` gains the same selection affordance
  (`playerSelected(row.id)`) and a `PlayerDetailPane` (`src/views/PlayerDetailPane.tsx`) that reads
  `$selectedPlayerId` + `$playerDetail` and renders, in a local `Card` + `ScrollArea`: the player summary +
  balances (`DataList` / `Stat` of diamonds / bonusDiamonds / lockedDiamonds / clips / keys), the recent guesses
  as a `DataList` / `ListRow` list (game · points · at), and the wallet ledger as a defensive `ListRow` list (or
  an empty "no ledger entries" state — the `ledger` is `unknown[]`). Empty + loading states as D3. Every player /
  guess field is public.
- **admin.5.2-D5 — the master-detail layout.** A two-region layout — the list region (narrowed) beside the side
  pane region — composed locally from `Card` + `ScrollArea` with app-local `dsh-md*` CSS (token-driven), inside
  each of `RoomsView` / `PlayersView` (App.tsx's content region is unchanged beyond mounting the admin.5.1 desks).
  Switching the active desk deselects (`roomDeselected` / `playerDeselected`) so a stale detail never shows on the
  wrong desk. The barrel is untouched (`Column.render` selection, not a `Table` row-click).
- **admin.5.2-D6 — green.** From `mercury/codemojex`: `pnpm --filter @codemojex/dashboard typecheck` exits 0;
  `pnpm --filter @codemojex/dashboard build` produces the SPA bundle; the `@mercury/ui` resolved export set is
  unchanged (0 removed / renamed); a grep confirms no `fetch(` in `src/views/` and no `secret` / `cell_codes`
  field on `types.ts` or in any pane.

## Invariants
- **admin.5.2-INV1 — the Bearer gate is the only door.** The keyed detail effects attach `Authorization: Bearer
  <token>` via the existing `auth()` helper, with `token` from config, never a source literal — the `:id` fetches
  open no un-gated path. Exercised by a grep (no `"Bearer "` followed by a string literal in `src/`) plus the
  shared `auth()` reuse.
- **admin.5.2-INV2 — the public schema only.** `RoomDetail` / `PlayerDetail` (and their item shapes) declare no
  `secret` and no `cell_codes` field, and no pane reads either key; every rendered field is a public read-plane
  column. Exercised by a structural check on `types.ts` (no `secret` / `cell_codes` field) plus a grep that no
  pane reads either key.
- **admin.5.2-INV3 — the barrel holds.** The `@mercury/ui` resolved export set is unchanged (0 removed / renamed);
  the panes and selection compose existing barrel exports (`Card` · `ScrollArea` · `DataList` · `ListRow` ·
  `Table` · `Stat` · `Badge` · `Button`) and add **no** `Table` row-click prop or new primitive — selection rides
  a `Column.render` action cell. Exercised by the barrel-diff (the resolved export set) — this rung touches only
  `mercury/codemojex/apps/dashboard`.
- **admin.5.2-INV4 — the two-clock seam holds.** Each pane reads its detail from an `@mercury/effector` store
  (`$roomDetail` / `$playerDetail`) via `useUnit`, never a component-local `fetch` — so a `channel` model can
  target the same detail store in admin.5.3 (the live game pane) without a pane rewrite. Exercised by a grep: no
  `fetch(` inside any `src/views/` component; the panes read the detail stores through `useUnit`.
- **admin.5.2-INV5 — no new backend surface.** The detail reads the **shipped** `GET /rooms/:id` + `GET
  /players/:id` (admin.1) through keyed effects; no new route, query param, or `apps/admin` file is added, and
  selection is a client store. Exercised by an observable — selecting a row fires `fetchRoomDetailFx(id)` against
  the existing `:id` route and the pane renders that row's detail — plus the diff scope (0 `apps/admin` files; no
  new route/param in `client.ts`).
- **admin.5.2-INV6 — green + composed.** `pnpm --filter @codemojex/dashboard typecheck` exits 0 and `build`
  produces a bundle; the panes compose `@mercury/*` from source via the existing aliases (no re-implemented
  primitive). Exercised by the typecheck + build commands.

## Definition of Done
- [ ] admin.5.2-D1 extends the client with the keyed room / player detail seams and the `$health` fan-in;
  admin.5.2-INV1 + admin.5.2-INV4 pass (admin.5.2-US1).
- [ ] admin.5.2-D2 adds `RoomDetail` / `PlayerDetail` (+ item shapes) with no secret field; admin.5.2-INV2 passes
  (admin.5.2-US2).
- [ ] admin.5.2-D3 renders the rooms master-detail (select → the room's summary + games in a side pane) reading
  `$roomDetail` via `useUnit`; admin.5.2-INV4 + admin.5.2-INV5 pass (admin.5.2-US3).
- [ ] admin.5.2-D4 renders the players master-detail (select → the player's summary + guesses + ledger);
  admin.5.2-INV2 + admin.5.2-INV5 pass (admin.5.2-US4).
- [ ] admin.5.2-D5 lays out the list beside the side pane, empty / loading states hold, and a desk switch
  deselects; admin.5.2-INV3 (barrel holds) passes (admin.5.2-US5).
- [ ] admin.5.2-D6 + admin.5.2-INV6: `typecheck` exits 0, `build` produces a bundle, the barrel is unchanged, and
  the secret / `fetch`-in-view greps read 0 (admin.5.2-US6).
- [ ] The six spec gates pass on this triad; the ledger records the close. The fork is **ruled** (D-6 → Arm C);
  no open fork remains.

Stories: [`admin.5.2.stories.md`](./admin.5.2.stories.md) · Agent brief: [`admin.5.2.llms.md`](./admin.5.2.llms.md) · Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
