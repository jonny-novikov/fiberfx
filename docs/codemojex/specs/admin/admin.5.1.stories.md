# admin.5.1 · stories

## admin.5.1-US1
As an operator, I want the console's admin client to reach rooms and players through my Bearer credential and
land each reply in a store, so that the two new desks read live data on the same gated, config-supplied path the
games desk already uses.

**Acceptance criteria.**
- **Given** the admin client, **when** it issues the rooms or players request, **then** it attaches
  `Authorization: Bearer <token>` via the shared `auth()` helper with `token` read from config, and no `Bearer
  <literal>` string appears anywhere in `src/`.
- **Given** the client model, **when** a rooms or players fetch resolves, **then** the reply lands in an
  `@mercury/effector` store (`$rooms` / `$players`), and the topbar `$health` indicator reflects that fetch's
  loading / ok / error state.

INVEST: independent of the views; verifiable by a grep + a store-shape review; encodes admin.5.1-INV1,
admin.5.1-INV4.
Priority: must · Size: M · Implements deliverables: admin.5.1-D1.

## admin.5.1-US2
As an operator, I want the rooms and players shapes to carry their real public columns and no secret, so that the
desks show the fields the database actually holds without ever exposing a withheld value.

**Acceptance criteria.**
- **Given** `src/types.ts`, **when** `RoomSummary` and `PlayerSummary` are inspected, **then** each declares the
  real `apps/admin/src/schemas.ts` columns (rooms: `clipCost` + `durationMs` added; players: `tgUserId` + `clips`
  + `bonusDiamonds` + `lockedDiamonds` added) and neither declares a `secret` or `cell_codes` field.
- **Given** any desk view, **when** it maps a row, **then** it reads only public columns — no view reads a
  `secret` or `cell_codes` key.

INVEST: independent of the client wiring; verifiable by a structural type check + a grep; encodes admin.5.1-INV2.
Priority: must · Size: S · Implements deliverables: admin.5.1-D2.

## admin.5.1-US3
As an operator, I want a rooms desk I can filter, search, and page, so that I can find a room among many without
scrolling one long table or dropping to `curl`.

**Acceptance criteria.**
- **Given** a reachable, gated admin API, **when** the rooms desk mounts, **then** it renders `$rooms` (read via
  `useUnit`, no view-local `fetch`) as a `@mercury/ui` `Table` of public columns, with an All/Open/Closed status
  filter, a `Search` box, and a `Pagination` control.
- **Given** the rooms list, **when** the operator types a name into `Search` or clicks a page, **then** the
  visible rows filter / slice **in the browser** from the same fetched array — no new request, `limit`, or `page`
  parameter is sent to the admin API.

INVEST: independent of the players desk; verifiable against a live room list + a grep; encodes admin.5.1-INV4,
admin.5.1-INV5.
Priority: must · Size: M · Implements deliverables: admin.5.1-D3.

## admin.5.1-US4
As an operator, I want a players desk I can search and page, so that I can look up a player by name and read their
public balances without exposing anything private.

**Acceptance criteria.**
- **Given** a reachable, gated admin API, **when** the players desk mounts, **then** it renders `$players` (read
  via `useUnit`) as a `@mercury/ui` `Table` of public columns (name, diamonds, clips, keys, created), with a
  `Search` box and a `Pagination` control, and no `secret` / `cell_codes` field appears on any row.
- **Given** the players list, **when** the operator searches or pages, **then** the rows filter / slice in the
  browser over the same fetched array — no server query param is added.

INVEST: independent of the rooms desk; verifiable against a live player list + a type/grep check; encodes
admin.5.1-INV2, admin.5.1-INV5.
Priority: must · Size: M · Implements deliverables: admin.5.1-D4.

## admin.5.1-US5
As an operator, I want the sidebar's Rooms and Players entries to become real, active desks, so that the console's
nav reflects what I can actually browse instead of showing disabled stubs.

**Acceptance criteria.**
- **Given** the running console, **when** it renders, **then** the sidebar's Rooms and Players entries are enabled
  (the `"admin.6"` hint gone), and selecting one mounts its desk in the content region beside the existing games
  desk.
- **Given** the active desk, **when** the operator triggers the Menubar Refresh, **then** it re-runs that desk's
  request, and the `@mercury/ui` barrel export set is unchanged (0 removed / renamed) — the shell houses no
  reusable component of its own.

INVEST: independent of the desk internals; verifiable by a render + the barrel-diff; encodes admin.5.1-INV3.
Priority: must · Size: S · Implements deliverables: admin.5.1-D5.

## admin.5.1-US6
As the Director, I want the desks typechecked and built green, so that admin.5.1 ships on a compiling, composing
foundation and not an unverified addition.

**Acceptance criteria.**
- **Given** a clean `mercury/codemojex`, **when** `pnpm --filter @codemojex/dashboard typecheck` then `build`
  run, **then** the typecheck exits 0 and the build produces the SPA bundle, composing `@mercury/*` from source
  via the aliases.
- **Given** the built app, **when** the secret / `fetch`-in-view greps run, **then** each reads 0 — no `secret` /
  `cell_codes` field and no `fetch(` inside `src/views/`.

INVEST: independent of behaviour; verifiable by the command exit codes + the greps; encodes admin.5.1-INV6.
Priority: must · Size: S · Implements deliverables: admin.5.1-D6.

Coverage: D1→US1 · D2→US2 · D3→US3 · D4→US4 · D5→US5 · D6→US6 · INV1→US1 · INV2→US2,US4 · INV3→US5 · INV4→US1,US3 · INV5→US3,US4 · INV6→US6.  Spec: admin.5.1.md · Agent brief: admin.5.1.llms.md.
