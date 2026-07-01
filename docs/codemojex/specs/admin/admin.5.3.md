# admin.5.3 · the live game path (room → game → the spectator view)

## Goal
Ship the **ruled node-only interim** of the live game path (Operator, D-6 → PHASED): the room → game
navigational path ending in a near-live spectator view. A keyed game-selection seam extends admin.5.2's
master-detail spine — a select affordance on the `RoomDetailPane`'s nested games `Table` fires
`gameSelected(id)` into `fetchGameDetailFx(id)` → `$gameDetail` (+ `$selectedGameId`), mirroring the ruled
`$selectedRoomId` pattern — and a spectator board is **re-rendered** from the shipped `GET /games/:id`
(`GameDetail.board` + the game summary) via `@mercury/ui` (admin.5.3-F1 → Arm C), kept near-live by a
client-side poll that re-fires the keyed fetch while the game stays selected (admin.5.3-F2 → Arm C), laid out
as a side-by-side game | events split with the guesses feed (admin.5.3-F3 → Arm A) and a stacked fallback at
the narrow breakpoint. Frontend-only, `apps/dashboard` only, zero `echo/` coupling. The TRUE live upgrade —
`mount`-ing the `@codemojex/game` island fed by a read-only engine `game:spectate:<id>` topic — is a LATER
`/codemojex-ship` fork, out of this rung; the two-clock seam makes it a no-rewrite swap (the later `channel`
model `sample`s into the SAME `$gameDetail` store).

## Rationale (5W)
- **Why** — the desk ladder's critical navigational path ends at the actual game, and admin.5.2 stops at a
  room's static games list. A re-rendered, polled spectator board delivers the operator watch surface today
  with zero engine coupling, and it seats the exact store seam the later live island-mount upgrades into — so
  the interim carries value now and forecloses no rework later (the D-6 phased ruling: interim now, live
  later).
- **What** — a keyed game-selection seam (`gameSelected` / `gameDeselected` / `$selectedGameId` /
  `fetchGameDetailFx` / `$gameDetail`), the game-detail public types, a spectator board re-rendered from
  `GET /games/:id`, a conservative client-side poll with pinned stop conditions, and a side-by-side
  game | events split with a back-to-room affordance and a stacked narrow fallback.
- **Who** — the human operator navigating room → game and watching a running game's board and guess activity
  from the console instead of a terminal.
- **When** — this rung, after admin.5.2 (whose `$selectedRoomId` keyed-detail seam it extends) and before the
  later live-upgrade fork (the island-mount + the engine spectator topic) and admin.5.4 (observability).
- **Where** — `mercury/codemojex/apps/dashboard/src/` only (`api/client.ts`, `types.ts`,
  `views/RoomDetailPane.tsx`, `views/RoomsView.tsx`, new `views/GameSpectatorView.tsx`, `dashboard.css`),
  composing `@mercury/ui` + `@mercury/effector` from source; reading the shipped `@codemojex/admin`
  `GET /games/:id` (admin.1); no edit crosses into `apps/admin`, `packages/*`, or `echo/`.

## Scope
**In.** The admin client (`src/api/client.ts`) extended with the **keyed game seam**: `fetchGameDetailFx =
createEffect<string, GameDetail>` (→ the shipped `GET /games/:id`), `gameSelected` / `gameDeselected` events,
`$selectedGameId` + `$gameDetail` stores (both also cleared when the room deselects — a game selection never
outlives its room; `$gameDetail` populated through the ledger-L-2 done-guard, so a late reply for a
superseded or cleared selection is dropped), a `gamePollTicked` event with a **guarded** `sample` off
`$selectedGameId`, and `$health`
fanning in the game-detail effect's `done` / `fail` (deliberately not its loading flip — the poll would strobe
the topbar). `src/types.ts` gaining `BoardEntry` / `GameGuessItem` / `GameDetail`, grounded in the admin.1
wire schemas (public columns only; `atMs` untyped on the wire, rendered defensively). A **select affordance**
on the `RoomDetailPane`'s nested games `Table` (a `Column.render` action cell — an `@mercury/ui` `Button` —
firing `gameSelected(row.id)`, the admin.5.2 selection precedent). The **spectator view**
(`src/views/GameSpectatorView.tsx`): the game pane (game summary + status `Badge` + the board re-rendered as a
score-descending `Table` of Player · Score) side-by-side with the events pane (`GameDetail.guesses`
newest-first as a feed), composed locally from `Card` + `ScrollArea` with app-local `dsh-*` CSS, a
back-to-room `Button` firing `gameDeselected()`, empty + first-load loading states, and a stacked fallback at
the narrow breakpoint. The **poll**: one `setInterval` at a pinned local `POLL_MS = 5000`, mounted with the
spectator view and cleared on unmount, so back / room-deselect / desk-switch all stop it. The rooms-desk
wiring: while `$selectedGameId` is non-null the spectator view replaces the master-detail body (the split
takes the desk's width — the F3 side-by-side needs it); deselect restores the list + room pane.

**Out.** The TRUE live upgrade — mounting the `@codemojex/game` island (a workspace dep, a second React) and
the read-only engine `game:spectate:<id>` spectator topic — a LATER phased rung whose engine half is a
`/codemojex-ship` fork (admin.5.3-F1 → Arm A / F2 → Arm A, ruled later); this rung only documents the seam it
lands in. Any `echo/` or `apps/admin` edit; any NEW backend route or query param (the poll re-uses the shipped
route). Server-side push (SSE / WebSocket) on the read plane. A new `@mercury/ui` primitive (a `SplitPane`, a
`Table` row-click prop — forbidden barrel forks; the split composes locally). An iframe embed (rejected, F1 →
Arm B). Live `revealed` / `guess_rejected` server-event frames in the events feed (they arrive with the later
channel; the interim feed is `GameDetail.guesses`). Any write / management (admin.2); admin.5.4
(observability, shared filter state, auto-refresh beyond this pane's poll). Any edit to `@codemojex/db`,
`packages/*`, or the `echo/` engine.

## Deliverables
- **admin.5.3-D1 — the keyed game seam.** `src/api/client.ts` gains: `gameSelected = createEvent<string>()` +
  `gameDeselected = createEvent()`; `fetchGameDetailFx = createEffect<string, GameDetail>` calling
  `fetch(\`${base}/games/${id}\`, { headers: auth() })`; `$selectedGameId = createStore<string |
  null>(null).on(gameSelected, (_s, id) => id)` reset by `gameDeselected` AND by the shipped admin.5.2
  `roomDeselected` (a game selection never outlives its room); `$gameDetail = createStore<GameDetail |
  null>(null)` with the same two resets, populated ONLY through a guarded `sample({ clock:
  fetchGameDetailFx.done, source: $selectedGameId, filter: (sel, { params }) => sel === params, fn: (_sel,
  { result }) => result, target: $gameDetail })` — the admin.5.2 hardening idiom (ledger L-2): a keyed
  effect has no take-latest, so a late reply for a superseded selection would silently overwrite the pane
  and a reply landing after a reset would repopulate the cleared store, and this rung's poll makes in-flight
  multiplicity the common case, not the edge; a poll reply for the CURRENT id passes the filter (`sel ===
  params` on every tick), so the near-live refresh is unaffected. `sample({ clock: gameSelected, target:
  fetchGameDetailFx })`. `$health` fans in
  `fetchGameDetailFx.done` / `.fail` (ok / error) and deliberately NOT the effect's loading flip — the poll
  re-fires the effect every cadence and a loading flip would strobe the topbar indicator. The Bearer `auth()`
  / `base` are reused; no `fetch(` is added outside this file.
- **admin.5.3-D2 — the game-detail types.** `src/types.ts` gains `BoardEntry = { player: string; score:
  number }`, `GameGuessItem = { id: string; gameId?: string; playerId?: string; points: number; atMs?: number
  | null; insertedAt: string }`, and `GameDetail = { game: GameSummary; board: BoardEntry[]; guesses:
  GameGuessItem[] }` — grounded in the shipped admin.1 wire schemas (`GameDetail` / `BoardEntry` /
  `GuessSummary` in `apps/admin/src/schemas.ts`; the game schemas list ONLY public columns — the privileged
  answer payload and cell codes are withheld by the serializer contract). The as-built `GameSummary`
  (`{ id, roomId, status, free, guessFee, prizePool, endsMs, insertedAt, roomName? }`) is reused unchanged.
  No withheld field on any shape; the admin.5.2 detail shapes are not edited.
- **admin.5.3-D3 — the near-live poll.** A `gamePollTicked = createEvent()` plus a **guarded** `sample({
  clock: gamePollTicked, source: $selectedGameId, filter: (id) => id !== null, target: fetchGameDetailFx })`
  in `client.ts`; the spectator view runs ONE `useEffect` interval firing `gamePollTicked()` every `POLL_MS`
  (a local const, pinned **5000 ms** — conservative on the read plane), with the interval cleared in the
  effect's cleanup. The stop conditions are structural: back-to-room, room deselect, and desk switch each
  unmount the spectator view, so the cleanup clears the interval and no further request fires; a stale tick
  with no selected id fires no fetch (the guarded `sample`). A poll refresh replaces `$gameDetail` in place —
  no blanking; the loading state shows only while the FIRST fetch is pending (`$gameDetail` still null). The
  live-upgrade slot is documented at the seam: the later engine `game:spectate:<id>` `channel` model
  `sample`s into the SAME `$gameDetail` store and the poll is retired — no view rewrite (a `/codemojex-ship`
  fork, out of this rung).
- **admin.5.3-D4 — the room → game navigation.** The `RoomDetailPane`'s nested games `Table` gains a
  `Column.render` action cell — an `@mercury/ui` `Button` (variant `ghost` / `soft`) labelled Watch — firing
  `gameSelected(row.id)` (`Table` carries no row-click prop, so the barrel holds). While a game is selected on
  the rooms desk, the spectator view replaces the master-detail body (list + room pane) — the side-by-side
  split takes the desk's full width; a back-to-room `Button` on the spectator view fires `gameDeselected()`
  and restores the master-detail. A desk switch deselects (the admin.5.2 deselect precedent chains: room
  deselect clears the game selection too), so a stale watch surface never shows on the wrong desk.
- **admin.5.3-D5 — the spectator split view.** `src/views/GameSpectatorView.tsx` (NEW) reads `$selectedGameId`
  + `$gameDetail` via `useUnit` and renders the ruled side-by-side split (admin.5.3-F3 → Arm A), composed
  locally from `Card` + `ScrollArea` (no new primitive): the **game pane** — the game summary as `DataList` /
  `Stat` (id · room · status as a `Badge` · free · guessFee · prizePool · endsMs · created) and the spectator
  board re-rendered from `GameDetail.board` as a score-descending `Table` (Player · Score); the **events
  pane** — `GameDetail.guesses` newest-first (by `insertedAt`) as a `ListRow` / `DataList` feed (guess id ·
  points · at, `atMs` rendered defensively). App-local `dsh-*` CSS (token-driven) lays the two panes
  side-by-side with a stacked fallback at the as-built **860px** narrow breakpoint the admin.5.2
  master-detail layout establishes (the `dashboard.css` media block the `dsh-md` grid already stacks in).
  Empty ("no game selected" — unreachable in normal flow, rendered defensively) + first-load loading states.
- **admin.5.3-D6 — green.** From `mercury/codemojex`: `pnpm --filter @codemojex/dashboard typecheck` exits 0;
  `pnpm --filter @codemojex/dashboard build` produces the SPA bundle; the `@mercury/ui` resolved export set is
  unchanged (0 removed / renamed); a grep confirms no `fetch(` in `src/views/` and no withheld-field token in
  `src/` (the admin.5.1 grep pair).

## Invariants
- **admin.5.3-INV1 — the Bearer gate is the only door.** `fetchGameDetailFx` attaches `Authorization: Bearer
  <token>` via the existing `auth()` helper, with `token` from config, never a source literal — the game
  fetch and its poll open no un-gated path. Exercised by a grep (no `"Bearer "` followed by a string literal
  in `src/`) plus the shared `auth()` reuse.
- **admin.5.3-INV2 — the public schema only.** `GameDetail` / `BoardEntry` / `GameGuessItem` declare no
  `secret` and no `cell_codes` field, and no view or comment carries either token — every rendered field is a
  public read-plane column (the wire schemas withhold the answer payload and cell codes by contract).
  Exercised by a structural check on `types.ts` plus the src-wide grep reading 0.
- **admin.5.3-INV3 — the barrel holds.** The `@mercury/ui` resolved export set is unchanged (0 removed /
  renamed); the spectator view and the select affordance compose existing barrel exports (`Card` ·
  `ScrollArea` · `Table` · `DataList` · `ListRow` · `Stat` · `Badge` · `Button` · `Spinner`) and add no
  `Table` row-click prop, no `SplitPane`, no new primitive — selection rides a `Column.render` action cell
  and the split is composed locally. Exercised by the barrel-diff (the resolved export set) — this rung
  touches only `mercury/codemojex/apps/dashboard`.
- **admin.5.3-INV4 — the two-clock seam holds (the live-upgrade slot).** The spectator view reads
  `$gameDetail` via `useUnit`, never a component-local `fetch` — the poll reaches the wire only through
  `fetchGameDetailFx` in `client.ts` — so the later engine spectator `channel` model can `sample` into the
  SAME `$gameDetail` store and retire the poll with no view rewrite. Exercised by a grep: no `fetch(` inside
  any `src/views/` component; the view reads the detail store through `useUnit`.
- **admin.5.3-INV5 — no new backend surface.** The path reads the **shipped** `GET /games/:id` (admin.1)
  through the one keyed effect; no new route, query param, or `apps/admin` file is added; zero `echo/`
  coupling. Exercised by an observable — selecting a game fires `fetchGameDetailFx(id)` against the existing
  `:id` route and the spectator view renders that game — plus the diff scope (0 `apps/admin` files; no new
  route / param in `client.ts`).
- **admin.5.3-INV6 — the poll is bounded and stoppable.** At most one interval runs at a time (one mount, one
  `useEffect`), at the pinned `POLL_MS = 5000`; back-to-room, room deselect, and desk switch each stop it
  (the view unmounts, the cleanup clears), after which no further `/games/:id` request fires; a tick with no
  selected id fires no fetch (the guarded `sample`). Exercised by an observable — deselect, then confirm no
  subsequent game-detail request is issued (network log / effect watcher) — plus the cleanup's presence in
  the one interval effect.
- **admin.5.3-INV7 — green + composed.** `pnpm --filter @codemojex/dashboard typecheck` exits 0 and `build`
  produces a bundle; the spectator view composes `@mercury/*` from source via the existing aliases (no
  re-implemented primitive). Exercised by the typecheck + build commands.

## Definition of Done
- [x] admin.5.3-D1 extends the client with the keyed game seam (select / deselect / chained room-clear) and
  the `done` / `fail` health fan-in; admin.5.3-INV1 + admin.5.3-INV4 pass (admin.5.3-US1).
- [x] admin.5.3-D2 adds `BoardEntry` / `GameGuessItem` / `GameDetail` with no withheld field; admin.5.3-INV2
  passes (admin.5.3-US2).
- [x] admin.5.3-D3 polls the keyed fetch at `POLL_MS = 5000` while a game is selected and stops on back /
  room-deselect / desk-switch; admin.5.3-INV5 + admin.5.3-INV6 pass (admin.5.3-US3).
- [x] admin.5.3-D4 navigates room → game via the Watch action cell and back via `gameDeselected()` — built +
  wired, the live read served-pending a standing admin service (the admin.5 posture); admin.5.3-INV3 +
  admin.5.3-INV5 pass (admin.5.3-US4).
- [x] admin.5.3-D5 renders the side-by-side game | events split (board score-descending, guesses
  newest-first) reading `$gameDetail` via `useUnit`, with the stacked narrow fallback and empty / loading
  states; admin.5.3-INV2 + admin.5.3-INV3 + admin.5.3-INV4 pass (admin.5.3-US5).
- [x] admin.5.3-D6 + admin.5.3-INV7: `typecheck` exits 0, `build` produces a bundle, the barrel is unchanged,
  and the withheld-field / `fetch`-in-view greps read 0 (admin.5.3-US6).
- [x] The six spec gates pass on this triad; the ledger records the close (P-9). The fork is **ruled** (D-6 →
  PHASED: F1 → Arm C interim / Arm A later · F2 → Arm C interim / Arm A later · F3 → Arm A); the live-upgrade
  slot (the island-mount + the engine spectator topic, a `/codemojex-ship` fork) is documented at the seam;
  no open fork remains.

Stories: [`admin.5.3.stories.md`](./admin.5.3.stories.md) · Agent brief: [`admin.5.3.llms.md`](./admin.5.3.llms.md) · Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
