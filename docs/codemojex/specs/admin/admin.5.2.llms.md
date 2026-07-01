# admin.5.2 · agent brief

Write-ready: the surface below is pre-mapped so the build's first actions are **writes**, not a read-to-understand
phase. This rung EXTENDS admin.5.1's list desks (built before this rung) with a master-detail side panel — the
ruled **Arm C** (D-6). The keyed-detail seam, the exact `:id` route shapes, the `@mercury/ui` detail-pane props,
and the selection-without-a-fork rule are carried inline. Ground every symbol in the shapes here or the named
files; invent no export, prop, route, or column. **Reconcile against the as-built at build time** — admin.5.1
ships first, so re-confirm its `RoomsView` / `PlayersView` + `client.ts` seams before extending. Framing
(propagate into any sub-brief): no gendered pronouns for agents; no perceptual / interior-state verbs; no
first-person narration.

## References
Read first (cap: these two — everything else is carried inline):
- The rung body — [`admin.5.2.md`](./admin.5.2.md) — the authoritative Deliverables + Invariants.
- The base it extends — [`admin.5.1.md`](./admin.5.1.md) (the list desks + the client store seam this rung adds
  detail to) + the as-built `mercury/codemojex/apps/dashboard/src/views/GamesView.tsx` (the desk template; the
  `Column.render` cell hook is how selection is added).

Carried inline (do NOT re-read — the shapes are here):
- **The shipped `:id` routes** (`apps/admin/src/schemas.ts` + `routes/{rooms,players}.ts`, admin.1; Bearer-gated):
  - `GET /rooms/:id` → `RoomDetail = { room: RoomSummary, games: RoomGameItem[] }`, `RoomGameItem = { id: string
    (GAM), status: string, free: boolean, prizePool: number|string, endsMs: number|null, insertedAt: string }`.
  - `GET /players/:id` → `PlayerDetail = { player: PlayerSummary, guesses: GuessDetail[], ledger: unknown[] }`,
    `GuessDetail = { id: string (GES), gameId?: string, points: number, atMs?: number|null, insertedAt: string }`.
    The `ledger` is `unknown[]` (provisional server-side — render defensively; may be empty).
  - Neither carries `secret` / `cell_codes` (game-only, server-side). `RoomSummary` / `PlayerSummary` are the
    admin.5.1 shapes (completed).
- **The admin.5.1 client seam** (`src/api/client.ts`, the pattern to mirror): `const auth = () => ({
  Authorization: \`Bearer ${token}\` })`, `base = import.meta.env.VITE_ADMIN_API_BASE ?? ""`; `fetchGamesFx` +
  `$games` + `gamesRequested` + `sample`; `$health` fans in the list effects. **Reuse `auth()` / `base`; add no
  second credential path.**
- **The `@mercury/ui` detail-pane props** (resolved from source — compose, do not re-house):
  - `DataList`: `{ items: { label: ReactNode; value: ReactNode }[]; orientation?: "horizontal"|"vertical"; size?:
    "sm"|"md"|"lg"; labelWidth?: number }`. `ListRow`: `{ label: ReactNode; leading?; description?; value?;
    trailing?; onClick? }` — renders an interactive `<button>` when `onClick` is present, else a `<div>`.
  - `Stat`: `{ label: string; value: ReactNode; delta?; deltaTone?: "neutral"|"positive"|"negative"|"caution"|
    "brand"|"info"; hint?; leading?; align?: "left"|"center" }`. `Badge`: `{ children: ReactNode; variant?:
    "brand"|"negative"|"positive"|"caution"|"info"; size? }`.
  - `Table<Row extends Record<string,unknown>>`: `{ columns: Column<Row>[]; data: Row[]; striped?; getRowKey? }`,
    `Column<Row> = { key: string; label: ReactNode; align?: "left"|"right"; render?: (row: Row) => ReactNode }`.
    **`Table` has NO `onClick` / row-selection prop** — selection rides `Column.render` (a `Button`), never a new
    Table prop (that is a `/mercury-ship` barrel fork). `Card`: `{ title?: string; children }`. `ScrollArea`: `{
    scrollbars?; maxHeight?; children }`. `Button` (`actions/Button`) for the select cell.
- Approach — [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md).

## Requirements
- **admin.5.2-R1** — extend `src/api/client.ts` with the keyed detail seam for rooms: `fetchRoomDetailFx =
  createEffect<string, RoomDetail>(async (id) => …/rooms/${id}…)`; `roomSelected = createEvent<string>()`,
  `roomDeselected = createEvent()`; `$selectedRoomId = createStore<string|null>(null).on(roomSelected, (_s, id) =>
  id).reset(roomDeselected)`; `$roomDetail = createStore<RoomDetail|null>(null).on(fetchRoomDetailFx.doneData,
  (_s, d) => d).reset(roomDeselected)`; `sample({ clock: roomSelected, target: fetchRoomDetailFx })`. The same
  trio for players. Extend `$health` to react to both detail effects. Reuse `auth()`; add no `fetch(` outside this
  file. [US: admin.5.2-US1]
- **admin.5.2-R2** — add to `src/types.ts`: `RoomGameItem`, `RoomDetail`, `GuessDetail`, `PlayerDetail` (shapes
  above). No `secret` / `cell_codes` field; `ledger: unknown[]`. [US: admin.5.2-US2]
- **admin.5.2-R3** — the rooms master-detail: add a select `Column.render` cell (a `Button` firing
  `roomSelected(row.id)`) to the admin.5.1 `RoomsView`, and write `src/views/RoomDetailPane.tsx` reading
  `$selectedRoomId` + `$roomDetail` (+ `fetchRoomDetailFx.pending`) via `useUnit` → a local `Card` + `ScrollArea`
  with the room summary (`DataList` + a status `Badge`) and its games as a nested `Table`; empty + loading states.
  No `fetch` in the view. [US: admin.5.2-US3]
- **admin.5.2-R4** — the players master-detail: the same select cell (`playerSelected(row.id)`) on `PlayersView`,
  and `src/views/PlayerDetailPane.tsx` rendering the player summary + balances (`DataList` / `Stat`), guesses
  (`DataList` / `ListRow`), and the ledger (defensive `ListRow` list / empty state). Public fields only. [US:
  admin.5.2-US4]
- **admin.5.2-R5** — the master-detail layout: a two-region (`list | pane`) layout inside each view, composed from
  `Card` + `ScrollArea`, with app-local `dsh-md*` CSS in `src/dashboard.css` (token-driven, no `.mx-*` authored);
  deselect on desk switch (fire `roomDeselected` / `playerDeselected` when the active desk changes, e.g. in
  `App.tsx`'s desk handler or a per-view unmount effect). [US: admin.5.2-US5]
- **admin.5.2-R6** — from `mercury/codemojex`: `pnpm --filter @codemojex/dashboard typecheck` exits 0; `build`
  produces the bundle; the `@mercury/ui` resolved export set is unchanged; `grep -rnE '"Bearer |secret|cell_codes'
  src/` and `grep -rn 'fetch(' src/views/` read 0. [US: admin.5.2-US6]

## Execution topology
Runtime:
```
list desk (admin.5.1 RoomsView) --Column.render Button--> roomSelected(id)
      |                                                        |
      |                                    sample -> fetchRoomDetailFx(id) --> GET /rooms/:id (Bearer)
      |                                                        |
      |  $selectedRoomId <- roomSelected                       v  .doneData
      |                                              $roomDetail : Store<RoomDetail|null>
      v                                                        |
  RoomDetailPane --useUnit($selectedRoomId,$roomDetail,fetchRoomDetailFx.pending)--> Card + ScrollArea
      (empty | loading | DataList summary + Badge status + nested Table of games)   [no fetch in the pane]

  App.tsx desk switch --> roomDeselected / playerDeselected (reset the pane)
  (players mirrors rooms: playerSelected -> fetchPlayerDetailFx -> $playerDetail -> PlayerDetailPane
     summary/balances DataList+Stat + guesses DataList/ListRow + ledger ListRow[defensive])
```
Tasks (build-order DAG):
```
R2 types.ts ─> R1 client.ts (keyed seam) ─┬─> R3 RoomsView select + RoomDetailPane ──┐
                                          └─> R4 PlayersView select + PlayerDetailPane ┤
R5 layout + dashboard.css ─────────────────────────────────────────────────────────── ├─> R6 typecheck + build + greps
(App.tsx desk-switch deselect) ──────────────────────────────────────────────────────┘
```
Touched files (under `mercury/codemojex/apps/dashboard/`): NEW — `src/views/RoomDetailPane.tsx`,
`src/views/PlayerDetailPane.tsx`; EDIT — `src/api/client.ts`, `src/types.ts`, `src/views/RoomsView.tsx`,
`src/views/PlayersView.tsx`, `src/App.tsx` (desk-switch deselect), `src/dashboard.css`. Read-only base:
`src/views/GamesView.tsx`. **No edit** to `apps/admin`, `packages/*`, or `echo/`.

## Agent stories
- **admin.5.2-AS1** [implements admin.5.2-US1] — Directive: write the keyed detail seam (R1) + the detail types
  (R2). Acceptance gate: postcondition — selecting a row fires `fetchRoomDetailFx(id)` / `fetchPlayerDetailFx(id)`
  and the reply lands in `$roomDetail` / `$playerDetail`; invariant — no `"Bearer "` literal, `auth()` reused, no
  `fetch(` added outside `client.ts`.
- **admin.5.2-AS2** [implements admin.5.2-US2] — Directive: add the detail shapes (R2). Acceptance gate:
  postcondition — `RoomDetail` / `PlayerDetail` carry the real `schemas.ts` fields; invariant — no `secret` /
  `cell_codes` field; `ledger: unknown[]`.
- **admin.5.2-AS3** [implements admin.5.2-US3] — Directive: build the rooms master-detail (R3 + R5). Acceptance
  gate: precondition — a reachable gated admin API; postcondition — selecting a room renders its summary + games
  in a side pane from `$roomDetail`; invariant — no `fetch(` in the pane; selection via `Column.render`, not a
  Table prop.
- **admin.5.2-AS4** [implements admin.5.2-US4] — Directive: build the players master-detail (R4). Acceptance gate:
  postcondition — selecting a player renders balances + guesses + ledger; invariant — public fields only, the
  ledger rendered defensively, no `fetch(` in the pane.
- **admin.5.2-AS5** [implements admin.5.2-US5] — Directive: lay out list | pane + deselect on desk switch (R5).
  Acceptance gate: postcondition — the pane sits beside the list, fills on select, resets on desk switch;
  invariant — the `@mercury/ui` resolved export set is unchanged (barrel-diff, 0 removed / renamed).
- **admin.5.2-AS6** [implements admin.5.2-US6] — Directive: gate green (R6). Acceptance gate: postcondition —
  `typecheck` exit 0 + `build` produces a bundle; invariant — the barrel holds; the secret / `fetch`-in-view greps
  read 0.

## Execution plan — first two stories
1. **admin.5.2-AS2 then AS1 (the seam first).** Add `RoomGameItem` / `RoomDetail` / `GuessDetail` / `PlayerDetail`
   to `src/types.ts` (shapes above). Then extend `src/api/client.ts`: write the rooms keyed trio
   (`fetchRoomDetailFx` / `$selectedRoomId` / `$roomDetail` / `roomSelected` / `roomDeselected` + the `sample`),
   copy it for players, and fan `$health` over both effects. First actions are writes.
2. **admin.5.2-AS3 (the rooms pane).** Add the select `Column.render` cell to `RoomsView` (a `Button` →
   `roomSelected(row.id)`); write `RoomDetailPane.tsx` (sketch below); wrap `RoomsView`'s list + the pane in the
   `dsh-md` two-region layout. Then mirror for players.

## Write-ready sketches (copy + adapt; the survival kit)
`src/api/client.ts` (the rooms keyed seam — players is identical):
```ts
import type { RoomDetail, PlayerDetail } from "@/types";
export const roomSelected = createEvent<string>();
export const roomDeselected = createEvent();
export const fetchRoomDetailFx = createEffect<string, RoomDetail>(async (id) => {
  const res = await fetch(`${base}/rooms/${id}`, { headers: auth() });
  if (!res.ok) throw new Error(`admin /rooms/${id} ${res.status}`);
  return (await res.json()) as RoomDetail;
});
export const $selectedRoomId = createStore<string | null>(null).on(roomSelected, (_s, id) => id).reset(roomDeselected);
export const $roomDetail = createStore<RoomDetail | null>(null).on(fetchRoomDetailFx.doneData, (_s, d) => d).reset(roomDeselected);
sample({ clock: roomSelected, target: fetchRoomDetailFx });
```
Select cell on the admin.5.1 `RoomsView` COLUMNS (no Table row-click — a render cell):
```tsx
{ key: "open", label: "", render: (r) => <Button size="sm" variant="ghost" onClick={() => roomSelected(r.id)}>View</Button> },
```
`src/views/RoomDetailPane.tsx`:
```tsx
export function RoomDetailPane() {
  const [id, detail, loading] = useUnit([$selectedRoomId, $roomDetail, fetchRoomDetailFx.pending]);
  if (!id) return <Card title="Detail"><p className="dsh-md__empty">Select a room to see its games.</p></Card>;
  if (loading || !detail) return <Card title="Detail"><Spinner /></Card>;
  const { room, games } = detail;
  return (
    <Card title={room.name}>
      <ScrollArea scrollbars="vertical" maxHeight="calc(100vh - 12rem)">
        <Badge variant={room.status === "open" ? "positive" : "neutral" as never}>{room.status}</Badge>
        <DataList items={[
          { label: "Free", value: String(room.free) },
          { label: "Clip cost", value: String(room.clipCost) },
          { label: "Duration", value: room.durationMs == null ? "—" : `${room.durationMs} ms` },
          { label: "Created", value: new Date(room.insertedAt).toLocaleString() },
        ]} />
        <Table<RoomGameRow> columns={GAME_COLUMNS} data={games.map(toGameRow)} striped getRowKey={(g) => g.id} />
      </ScrollArea>
    </Card>
  );
}
```
> `Badge`'s `variant` set is `brand|negative|positive|caution|info` (no `neutral`) — pick a real variant or omit
> for the default. Nest games through a local `RoomGameRow extends Record<string,unknown>` + `toGameRow` (the
> `GamesView` row-mapping precedent). The player pane mirrors this: `DataList`/`Stat` for balances, `ListRow` for
> each guess (`label` = game, `value` = points), the ledger a defensive `ListRow` list or a "no ledger" empty.

## Comprehensive implementation prompt
```
Extend @codemojex/dashboard with the master-detail side panel — admin.5.2, ruled Arm C (D-6). Boundary:
mercury/codemojex/apps/dashboard/ ONLY (no apps/admin, no packages/*, no echo/ edit). Frontend-only; the detail
reads the SHIPPED GET /rooms/:id + GET /players/:id (admin.1) — add NO route/param. Reconcile against admin.5.1
as-built first (it ships before this rung).

1. src/types.ts: add RoomGameItem, RoomDetail, GuessDetail, PlayerDetail (grounded in apps/admin/src/schemas.ts).
   No secret/cell_codes; ledger: unknown[].
2. src/api/client.ts: add the keyed detail seam — fetchRoomDetailFx(id)/$selectedRoomId/$roomDetail/roomSelected/
   roomDeselected + sample, and the players trio; fan $health over both effects; reuse auth()/base; no fetch(
   outside this file.
3. RoomsView/PlayersView (admin.5.1): add a select Column.render cell (a @mercury/ui Button firing
   roomSelected/playerSelected(row.id)) — NOT a Table onClick (that is a /mercury-ship barrel fork).
4. src/views/RoomDetailPane.tsx + PlayerDetailPane.tsx: read $selected*Id + $*Detail (+ .pending) via useUnit ->
   a LOCAL Card + ScrollArea; room = DataList summary + status Badge + nested Table of games; player = DataList/
   Stat balances + guesses DataList/ListRow + ledger defensive ListRow/empty. Empty + loading states. No fetch.
5. Layout: a two-region list|pane inside each view (Card + ScrollArea, app-local dsh-md* CSS in dashboard.css,
   token-driven, no .mx-*); deselect on desk switch (roomDeselected/playerDeselected in App.tsx's desk handler).
6. Gate, from mercury/codemojex: pnpm --filter @codemojex/dashboard typecheck (exit 0); build (bundle produced);
   grep -rnE '"Bearer |secret|cell_codes' src/ -> 0; grep -rn 'fetch(' src/views/ -> 0; @mercury/ui export set
   unchanged.

Table has no row-click prop — selection is a Column.render Button. Ground every symbol in admin.5.2.md / the
carried shapes / the admin.5.1 base. Invent no export, prop, route, or column. Report the gate output verbatim.
Framing: no gendered pronouns for agents; no perceptual/interior-state verbs; no first-person.
```

Stories: [`admin.5.2.stories.md`](./admin.5.2.stories.md) · Spec: [`admin.5.2.md`](./admin.5.2.md) · Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
