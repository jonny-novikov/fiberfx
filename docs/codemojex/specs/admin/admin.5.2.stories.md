# admin.5.2 · stories

## admin.5.2-US1
As an operator, I want selecting a room or player to fetch its detail into a store on my Bearer credential, so that
the detail panel reads live depth on the same gated, config-supplied path the list desks use.

**Acceptance criteria.**
- **Given** the admin client, **when** a row is selected, **then** a keyed effect (`fetchRoomDetailFx(id)` /
  `fetchPlayerDetailFx(id)`) issues `GET /rooms/:id` / `GET /players/:id` with `Authorization: Bearer <token>` via
  the shared `auth()` helper (token from config), and no `Bearer <literal>` string appears in `src/`.
- **Given** the detail effect resolves, **when** it completes, **then** the reply lands in an `@mercury/effector`
  store (`$roomDetail` / `$playerDetail`) and `$health` reflects that fetch's state.

INVEST: independent of the panes; verifiable by a grep + a store-shape review; encodes admin.5.2-INV1,
admin.5.2-INV4.
Priority: must · Size: M · Implements deliverables: admin.5.2-D1.

## admin.5.2-US2
As an operator, I want the detail shapes to carry the real public columns and no secret, so that a room's games and
a player's guesses and balances show exactly what the database holds and nothing withheld.

**Acceptance criteria.**
- **Given** `src/types.ts`, **when** `RoomDetail` / `RoomGameItem` and `PlayerDetail` / `GuessDetail` are
  inspected, **then** each declares the real `apps/admin/src/schemas.ts` fields and none declares a `secret` or
  `cell_codes` field.
- **Given** either detail pane, **when** it renders a field, **then** it reads only public columns — the ledger
  (`unknown[]`) is rendered defensively and no pane reads a `secret` / `cell_codes` key.

INVEST: independent of the client wiring; verifiable by a structural type check + a grep; encodes admin.5.2-INV2.
Priority: must · Size: S · Implements deliverables: admin.5.2-D2.

## admin.5.2-US3
As an operator, I want to click a room and see its detail beside the list, so that I can read a room's games
without losing the list or dropping to `curl`.

**Acceptance criteria.**
- **Given** the rooms desk, **when** the operator clicks a row's select action, **then** `roomSelected(id)` fires,
  `fetchRoomDetailFx(id)` reads the shipped `GET /rooms/:id`, and a side pane (`Card` + `ScrollArea`, local)
  renders the room summary (`DataList` + a status `Badge`) and its games as a nested `Table` — read from
  `$roomDetail` via `useUnit`, no view-local `fetch`.
- **Given** no row is selected, **when** the rooms desk renders, **then** the pane shows an empty "select a room"
  state; while the detail loads, it shows a loading state.

INVEST: independent of the players desk; verifiable against a live room + a grep; encodes admin.5.2-INV4,
admin.5.2-INV5.
Priority: must · Size: M · Implements deliverables: admin.5.2-D3.

## admin.5.2-US4
As an operator, I want to click a player and see their balances, guesses, and ledger, so that I can review a
player's account depth without exposing anything private.

**Acceptance criteria.**
- **Given** the players desk, **when** the operator selects a player, **then** `fetchPlayerDetailFx(id)` reads the
  shipped `GET /players/:id` and the pane renders the player summary + balances (`DataList` / `Stat`), the recent
  guesses (`DataList` / `ListRow`), and the wallet ledger (a defensive `ListRow` list or an empty state) — no
  `secret` / `cell_codes` field on any row.
- **Given** the player detail, **when** the ledger is absent or empty, **then** the pane shows a "no ledger
  entries" state rather than erroring.

INVEST: independent of the rooms desk; verifiable against a live player + a type/grep check; encodes
admin.5.2-INV2, admin.5.2-INV5.
Priority: must · Size: M · Implements deliverables: admin.5.2-D4.

## admin.5.2-US5
As an operator, I want the detail to sit in a side panel beside the list and clear when I switch desks, so that the
master-detail reads cleanly and never shows a stale room's detail on the players desk.

**Acceptance criteria.**
- **Given** a desk, **when** it renders, **then** the list sits beside a side pane (a two-region layout composed
  from `Card` + `ScrollArea`), and selecting a row fills the pane; switching the active desk deselects
  (`roomDeselected` / `playerDeselected`) so the pane resets.
- **Given** the master-detail, **when** the `@mercury/ui` barrel export set is resolved before and after this
  rung, **then** it is unchanged (0 removed / renamed) — selection rides a `Column.render` action cell, adding no
  `Table` row-click prop and no new primitive.

INVEST: independent of the detail internals; verifiable by a render + the barrel-diff; encodes admin.5.2-INV3.
Priority: must · Size: M · Implements deliverables: admin.5.2-D5.

## admin.5.2-US6
As the Director, I want the master-detail typechecked and built green, so that admin.5.2 ships on a compiling,
composing foundation and not an unverified addition.

**Acceptance criteria.**
- **Given** a clean `mercury/codemojex`, **when** `pnpm --filter @codemojex/dashboard typecheck` then `build`
  run, **then** the typecheck exits 0 and the build produces the SPA bundle, composing `@mercury/*` from source.
- **Given** the built app, **when** the secret / `fetch`-in-view greps run, **then** each reads 0 — no `secret` /
  `cell_codes` field and no `fetch(` inside `src/views/`.

INVEST: independent of behaviour; verifiable by the command exit codes + the greps; encodes admin.5.2-INV6.
Priority: must · Size: S · Implements deliverables: admin.5.2-D6.

Coverage: D1→US1 · D2→US2 · D3→US3 · D4→US4 · D5→US5 · D6→US6 · INV1→US1 · INV2→US2,US4 · INV3→US5 · INV4→US1,US3 · INV5→US3,US4 · INV6→US6.  Spec: admin.5.2.md · Agent brief: admin.5.2.llms.md.
