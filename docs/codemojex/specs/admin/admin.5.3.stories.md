# admin.5.3 · stories

## admin.5.3-US1
As an operator, I want selecting a game in a room's games list to load that game's detail through my Bearer
credential into a keyed store, so that the watch surface reads live data on the same gated, config-supplied
path every desk already uses.

**Acceptance criteria.**
- **Given** the admin client, **when** the game-detail request fires (on select or on a poll tick), **then**
  it attaches `Authorization: Bearer <token>` via the shared `auth()` helper with `token` read from config,
  and no `Bearer <literal>` string appears anywhere in `src/`.
- **Given** the client model, **when** `gameSelected(id)` fires, **then** `$selectedGameId` holds the id and
  the keyed fetch lands the reply in `$gameDetail`; **when** `gameDeselected()` or `roomDeselected` fires,
  **then** both stores reset to null.
- **Given** an in-flight game-detail reply, **when** it resolves after the selection changed or cleared,
  **then** `$gameDetail` does not accept it — the done-guard admits only a reply whose requested id equals
  the current `$selectedGameId` (the shipped admin.5.2 hardening idiom, ledger L-2), while a poll reply for
  the current id passes.
- **Given** the topbar indicator, **when** a game-detail fetch succeeds or fails, **then** `$health` reads
  `ok` / `error` — and a poll refresh does not flip it to `loading` (no strobe at the poll cadence).

INVEST: independent of the views; verifiable by a grep + a store-shape review; encodes admin.5.3-INV1,
admin.5.3-INV4.
Priority: must · Size: M · Implements deliverables: admin.5.3-D1.

## admin.5.3-US2
As an operator, I want the game-detail shapes to carry only the public wire columns, so that the watch
surface never renders a withheld answer payload or cell code.

**Acceptance criteria.**
- **Given** `src/types.ts`, **when** `GameDetail` / `BoardEntry` / `GameGuessItem` are inspected, **then**
  each mirrors the shipped admin.1 wire schema's public columns (`board` entries `player` + `score`; guesses
  `id` · `gameId?` · `playerId?` · `points` · `atMs?` · `insertedAt`) and none declares a `secret` or
  `cell_codes` field.
- **Given** the spectator view, **when** it renders the board and the guesses feed, **then** it reads only
  public fields, and `atMs` (untyped on the wire) is rendered defensively — a missing or malformed value
  degrades to the `insertedAt` timestamp, not a crash.

INVEST: independent of the client wiring; verifiable by a structural type check + a grep; encodes
admin.5.3-INV2.
Priority: must · Size: S · Implements deliverables: admin.5.3-D2.

## admin.5.3-US3
As an operator, I want the selected game's board to refresh on a steady cadence and stop the moment I leave
it, so that the view stays near-live while I watch and stops loading the read plane when I do not.

**Acceptance criteria.**
- **Given** a selected game, **when** `POLL_MS` (5000 ms) elapses, **then** one `gamePollTicked` re-fires the
  keyed fetch for the SAME selected id against the shipped `GET /games/:id` — no new route or query param —
  and the board re-renders in place (the previous detail is replaced, never blanked mid-poll).
- **Given** the watch surface, **when** the operator activates back-to-room, deselects the room, or switches
  desks, **then** the interval is cleared and no further `/games/:id` request fires afterward.
- **Given** a poll tick with no selected id, **when** the guarded `sample` evaluates it, **then** no fetch
  fires (the filter blocks a stale tick).

INVEST: independent of the split layout; verifiable by a network / effect-call observation across select →
wait → deselect; encodes admin.5.3-INV5, admin.5.3-INV6.
Priority: must · Size: M · Implements deliverables: admin.5.3-D3.

## admin.5.3-US4
As an operator, I want a Watch affordance on a room's games and a back affordance on the game view, so that I
can move room → game → room without leaving the console.

**Acceptance criteria.**
- **Given** a selected room's detail pane, **when** the operator activates the Watch action-cell `Button` on
  a games row, **then** `gameSelected(row.id)` fires and the spectator view replaces the master-detail body
  on the rooms desk (the split takes the desk's width).
- **Given** the spectator view, **when** the operator activates the back-to-room `Button`, **then**
  `gameDeselected()` fires and the list + room pane return; **when** the operator switches desks, **then**
  the game selection clears and no stale watch surface shows on the wrong desk.
- **Given** the selection mechanics, **when** the barrel is diffed, **then** the `@mercury/ui` resolved
  export set is unchanged — selection rides a `Column.render` action cell, not a `Table` row-click prop.

INVEST: independent of the poll; verifiable by a render walk-through + the barrel-diff + the diff scope (0
`apps/admin` files); encodes admin.5.3-INV3, admin.5.3-INV5.
Priority: must · Size: M · Implements deliverables: admin.5.3-D4.

## admin.5.3-US5
As an operator, I want the game view split side-by-side — the board beside the guesses feed — so that game
state and activity read together at a glance on an operator screen.

**Acceptance criteria.**
- **Given** a loaded `$gameDetail`, **when** the spectator view renders, **then** the game pane shows the
  game summary (status as a `Badge`, the public summary fields as `DataList` / `Stat`) and the board as a
  score-descending `Table` (Player · Score), and the events pane lists `GameDetail.guesses` newest-first as a
  `ListRow` / `DataList` feed — both read from `$gameDetail` via `useUnit`, with no `fetch(` in the view.
- **Given** the narrow breakpoint, **when** the viewport narrows below it, **then** the two panes stack
  (game above events) — the layout is app-local `dsh-*` CSS composed from `Card` + `ScrollArea`, no new
  primitive.
- **Given** a first selection, **when** the initial fetch is pending, **then** a loading state shows; a
  later poll refresh shows no loading state (the board updates in place).

INVEST: independent of the navigation wiring; verifiable by a render at two viewport widths + a grep; encodes
admin.5.3-INV2, admin.5.3-INV3, admin.5.3-INV4.
Priority: must · Size: M · Implements deliverables: admin.5.3-D5.

## admin.5.3-US6
As the Director, I want the live game path typechecked and built green, so that admin.5.3 ships on a
compiling, composing foundation and not an unverified addition.

**Acceptance criteria.**
- **Given** a clean `mercury/codemojex`, **when** `pnpm --filter @codemojex/dashboard typecheck` then `build`
  run, **then** the typecheck exits 0 and the build produces the SPA bundle, composing `@mercury/*` from
  source via the aliases.
- **Given** the built app, **when** the withheld-field / `fetch`-in-view greps run, **then** each reads 0 —
  no withheld-field token in `src/` and no `fetch(` inside `src/views/` — and the `@mercury/ui` resolved
  export set is unchanged.

INVEST: independent of behaviour; verifiable by the command exit codes + the greps; encodes admin.5.3-INV7.
Priority: must · Size: S · Implements deliverables: admin.5.3-D6.

Coverage: D1→US1 · D2→US2 · D3→US3 · D4→US4 · D5→US5 · D6→US6 · INV1→US1 · INV2→US2,US5 · INV3→US4,US5 · INV4→US1,US5 · INV5→US3,US4 · INV6→US3 · INV7→US6.  Spec: admin.5.3.md · Agent brief: admin.5.3.llms.md.
