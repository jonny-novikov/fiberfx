# admin.5.3 · agent brief

Write-ready: the surface below is pre-mapped so the build's first actions are **writes**, not a
read-to-understand phase. This rung EXTENDS the admin.5.2 master-detail (the `$selectedRoomId` keyed-detail
seam) with the room → game live path's **ruled node-only interim** (D-6 → PHASED: F1 → Arm C re-render · F2 →
Arm C poll · F3 → Arm A side-by-side; the island-mount + engine spectator topic is a LATER `/codemojex-ship`
fork — build the seam, not the upgrade). Ground every symbol in the shapes here or the two named files; invent
no export, prop, route, or column. Framing (propagate into any sub-brief): third person for agents; no
gendered pronouns for agents; no perceptual / interior-state verbs; no first-person narration.

## References
Read first (cap: these two — everything else is carried inline):
- The rung body — [`admin.5.3.md`](./admin.5.3.md) — the authoritative Deliverables + Invariants.
- The seam contract this rung extends — [`admin.5.2.md`](./admin.5.2.md) § Deliverables D1/D3/D5 (the
  `roomSelected` / `$selectedRoomId` / `fetchRoomDetailFx` / `$roomDetail` keyed-detail seam, the
  `RoomDetailPane` nested games `Table`, the master-detail layout + deselect-on-desk-switch). **admin.5.2 is
  SHIPPED (commit 244a5a3a) — the as-built names are settled and carried here:** `roomDeselected` is the
  room-deselect event; the `RoomDetailPane` nested-games `Table` uses `GAME_COLUMNS` (row keys id · status ·
  free · prizePool · ends · created) via a local `RoomGameRow` + `toGameRow`; the narrow breakpoint is
  **860px** (the `dashboard.css` media block the `dsh-md` grid already stacks in).

Carried inline (do NOT re-read — the shapes are here; Director-probed live from `apps/admin/src/schemas.ts`):
- **The wire route** (admin.1, shipped, Bearer-gated): `GET /games/:id` → `GameDetail = { game: GameSummary,
  board: BoardEntry[], guesses: GuessSummary[] }`; `BoardEntry = { player: string, score: number }`;
  `GuessSummary = { id (GES), gameId?, playerId?, points: number, atMs? (untyped on the wire), insertedAt }`.
  The game schemas list ONLY public columns — the privileged answer payload and cell codes are withheld by
  the serializer contract. The dashboard's as-built `GameSummary` TS shape (`src/types.ts`): `{ id, roomId,
  status, free, guessFee, prizePool, endsMs, insertedAt, roomName? }` — reuse it unchanged.
- **The admin.5.2 seam contract** (its spec D1, shipped as-built): `roomSelected(id)` / `$selectedRoomId`
  / `fetchRoomDetailFx(id)` / `$roomDetail` (with `RoomDetail.games: RoomGameItem[]` = `{ id (GAM), status,
  free, prizePool, endsMs, insertedAt }`); the admin.5.1 client pattern (`auth()` / `base`, effect + store +
  event trios, `$health` array-form fan-in); the views read stores via `useUnit` only (no view fetch — the
  INV4 lineage).
- **The `@mercury/ui` pieces** (all confirmed in the barrel; compose locally, no new primitive): `Card`,
  `ScrollArea`, `Table`, `DataList`, `ListRow`, `Stat`, `Badge`, `Button`, `Spinner`, `Tabs`. `Table`'s data
  prop is `data` (NOT `rows`); `Column.render` is the action-cell hook; `Table` has NO row-click prop (adding
  one is a forbidden `/mercury-ship` barrel fork). `Table<Row extends Record<string, unknown>>` props:
  `{ columns: Column<Row>[]; data: Row[]; striped?; getRowKey? }`; `Column<Row>` = `{ key; label; align?;
  render?: (row: Row) => ReactNode }`. `DataList` / `ListRow` / `Stat` prop shapes are NOT carried here —
  mirror the as-built admin.5.2 pane usage; confirm at `mercury/packages/mercury-ui/src/components/` only if
  a prop name is in doubt.
- Approach — [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md).

## Requirements
- **admin.5.3-R1** — extend `src/types.ts`: add `BoardEntry = { player: string; score: number }`,
  `GameGuessItem = { id: string; gameId?: string; playerId?: string; points: number; atMs?: number | null;
  insertedAt: string }`, `GameDetail = { game: GameSummary; board: BoardEntry[]; guesses: GameGuessItem[] }`.
  Precise interfaces; no withheld field; the 5.2 detail shapes untouched. [US: admin.5.3-US2]
- **admin.5.3-R2** — extend `src/api/client.ts` with the keyed game seam: `gameSelected` / `gameDeselected`
  events, `fetchGameDetailFx = createEffect<string, GameDetail>` (reusing `auth()` / `base` — no second
  credential path), `$selectedGameId` + `$gameDetail` (reset on `gameDeselected` AND `roomDeselected` — a
  game selection never outlives its room), `sample({ clock: gameSelected, target: fetchGameDetailFx })`,
  `$gameDetail` populated ONLY through the guarded done-sample (`clock: fetchGameDetailFx.done`, `source:
  $selectedGameId`, `filter: (sel, { params }) => sel === params` — the admin.5.2 hardening idiom, ledger
  L-2: a late reply for a superseded or cleared id is dropped; a poll reply for the current id passes), and
  `$health` fanning in `fetchGameDetailFx.done` / `.fail` ONLY (no loading flip — the poll would strobe the
  topbar every cadence). No `fetch(` outside this file. [US: admin.5.3-US1]
- **admin.5.3-R3** — the poll plumbing in `client.ts`: `gamePollTicked = createEvent()` + the guarded
  `sample({ clock: gamePollTicked, source: $selectedGameId, filter: (id): id is string => id !== null,
  target: fetchGameDetailFx })`. [US: admin.5.3-US3]
- **admin.5.3-R4** — `src/views/RoomDetailPane.tsx`: the as-built `GAME_COLUMNS` (`RoomGameRow` /
  `toGameRow`) gains a `Column.render` action cell — an `@mercury/ui` `Button` (variant `ghost` / `soft`)
  labelled Watch firing `gameSelected(row.id)` — the 5.2 selection precedent; no `Table` row-click prop.
  [US: admin.5.3-US4]
- **admin.5.3-R5** — `src/views/GameSpectatorView.tsx` (NEW): reads `$gameDetail` (+
  `fetchGameDetailFx.pending`) via `useUnit`; ONE `useEffect` interval firing `gamePollTicked()` every
  `POLL_MS = 5000` (a local const) with `clearInterval` in the cleanup; a back-to-room `Button` firing
  `gameDeselected()`; the game pane (summary `DataList` / `Stat` + status `Badge` + the board as a
  score-descending `Table` of Player · Score) beside the events pane (`GameDetail.guesses` newest-first by
  `insertedAt` as `ListRow` / `DataList`; `atMs` rendered defensively); first-load loading state only
  (`$gameDetail` null + pending → `Spinner`); no `fetch(` in the view. [US: admin.5.3-US3, admin.5.3-US5]
- **admin.5.3-R6** — `src/views/RoomsView.tsx`: read `$selectedGameId` via `useUnit`; while non-null render
  `<GameSpectatorView />` in place of the master-detail body (the split takes the desk's width); on null the
  5.2 list + pane render as before. The desk-switch deselect chain is settled: the shipped 5.2
  `roomDeselected` resets the game stores (R2), so a desk switch clears the watch surface.
  [US: admin.5.3-US4]
- **admin.5.3-R7** — `src/dashboard.css`: app-local `dsh-watch*` layout — two panes side-by-side, each a
  `Card` + `ScrollArea`, stacked below the as-built **860px** narrow breakpoint (the media block the
  `dsh-md` grid already stacks in); token-driven (`rgb(var(--token))`); no `.mx-*` authored.
  [US: admin.5.3-US5]
- **admin.5.3-R8** — from `mercury/codemojex`: `pnpm --filter @codemojex/dashboard typecheck` exits 0; `pnpm
  --filter @codemojex/dashboard build` produces the bundle; the `@mercury/ui` resolved export set is
  unchanged; `grep -rnE '"Bearer |secret|cell_codes' src/` and `grep -rn 'fetch(' src/views/` read 0 (keep
  every comment and identifier clear of those tokens). [US: admin.5.3-US6]

## Execution topology
Runtime:
```
config: VITE_ADMIN_TOKEN, VITE_ADMIN_API_BASE (unchanged; the dev proxy forwards /games -> the admin svc)
      |
  api/client.ts (extended)
      |-- gameSelected(id) ──sample──> fetchGameDetailFx(id) --> fetch(`${base}/games/${id}`, auth())
      |-- fetchGameDetailFx.done ──sample(source: $selectedGameId, filter: sel === params)──> $gameDetail (L-2)
      |-- gamePollTicked ──sample(source: $selectedGameId, filter: id !== null)──> fetchGameDetailFx
      |-- gameDeselected / roomDeselected --> reset $selectedGameId + $gameDetail
      |-- $health <- fetchGameDetailFx.(done|fail) only (no loading flip on a poll refresh)
      v
  views/RoomDetailPane.tsx --games Table Column.render Watch Button--> gameSelected(row.id)
  views/GameSpectatorView.tsx --useUnit($gameDetail)--> [game pane: summary + board Table] | [events pane: guesses feed]
      |     (one interval: POLL_MS=5000 -> gamePollTicked; cleanup clears on unmount = back / deselect / desk switch)
  views/RoomsView.tsx: $selectedGameId != null ? <GameSpectatorView/> : the 5.2 master-detail body
```
Tasks (build-order DAG):
```
R1 types.ts ──> R2 client.ts (seam) ──> R3 poll sample ──┬─> R4 RoomDetailPane Watch cell ──┐
                                                         ├─> R5 GameSpectatorView ─────────┼─> R6 RoomsView wiring ─> R8 gates
R7 dashboard.css (the split + stacked fallback) ─────────┴─────────────────────────────────┘
```
Touched files (all under `mercury/codemojex/apps/dashboard/`): NEW — `src/views/GameSpectatorView.tsx`; EDIT
— `src/api/client.ts`, `src/types.ts`, `src/views/RoomDetailPane.tsx`, `src/views/RoomsView.tsx`,
`src/dashboard.css`. **No edit** to `apps/admin`, `packages/*`, or `echo/`; the diff is `apps/dashboard`
only.

## Agent stories
- **admin.5.3-AS1** [implements admin.5.3-US2] — Directive: add the game-detail types (R1). Acceptance gate:
  postcondition — `GameDetail` / `BoardEntry` / `GameGuessItem` mirror the carried wire shapes; invariant —
  no withheld field on `types.ts`.
- **admin.5.3-AS2** [implements admin.5.3-US1] — Directive: extend `client.ts` with the keyed game seam + the
  chained room-clear + the `done` / `fail` health fan-in (R2). Acceptance gate: postcondition — a select
  lands the detail in `$gameDetail` and a deselect (game or room) resets both stores; invariant — no
  `"Bearer "` literal in `src/`, `auth()` reused, no `fetch(` added outside `client.ts`, no loading flip on
  `$health` from the game effect, and `$gameDetail` accepts only a reply whose `params` match the current
  `$selectedGameId` (the L-2 done-guard).
- **admin.5.3-AS3** [implements admin.5.3-US3] — Directive: wire the poll (R3 + the R5 interval). Acceptance
  gate: postcondition — a selected game re-fetches every `POLL_MS` and the board updates in place; invariant
  — one interval, cleared on unmount; a deselect stops all further `/games/:id` requests; a stale tick with
  no id fires no fetch.
- **admin.5.3-AS4** [implements admin.5.3-US4] — Directive: the room → game navigation (R4 + R6). Acceptance
  gate: postcondition — Watch on a games row opens the spectator view in place of the master-detail body and
  back restores it; a desk switch clears the watch surface; invariant — the `@mercury/ui` resolved export set
  is unchanged (no row-click prop, no new primitive).
- **admin.5.3-AS5** [implements admin.5.3-US5] — Directive: build the spectator split (R5 + R7). Acceptance
  gate: postcondition — the game pane (summary + score-descending board) renders beside the events pane
  (guesses newest-first), stacking at the narrow breakpoint, with first-load loading + defensive `atMs`
  rendering; invariant — no `fetch(` in the view; the split is composed locally from `Card` + `ScrollArea`.
- **admin.5.3-AS6** [implements admin.5.3-US6] — Directive: gate green (R8). Acceptance gate: postcondition —
  `typecheck` exit 0 + `build` produces a bundle; invariant — the barrel holds; the withheld-field /
  `fetch`-in-view greps read 0.

## Execution plan — first two stories
1. **admin.5.3-AS1 then AS2 (the seam first).** Open `src/types.ts`; add `BoardEntry` / `GameGuessItem` /
   `GameDetail` (shapes above — first action is a write). Then open `src/api/client.ts` and add the game
   seam: the two events, the keyed effect (mirror the 5.2 detail effect, swapping the path + type), the two
   stores with the double reset (`gameDeselected` + the shipped `roomDeselected`), the L-2 guarded
   done-sample into `$gameDetail`, the select `sample`, the poll event + guarded `sample`, and the `done` /
   `fail` health fan-in.
2. **admin.5.3-AS4 (the Watch cell) then AS5 (the view).** Add the Watch `Column.render` cell to
   `RoomDetailPane`'s as-built `GAME_COLUMNS` (the 5.2 action-cell precedent — copy its select `Button`
   cell, swap the event). Then write `GameSpectatorView.tsx` from the sketch below and wire `RoomsView` to
   swap the body on `$selectedGameId`.

## Write-ready sketches (copy + adapt; the survival kit)
`src/api/client.ts` (the keyed game seam + the poll — mirror the 5.2 detail trio):
```ts
import type { GameDetail } from "@/types";
export const gameSelected = createEvent<string>();
export const gameDeselected = createEvent();
export const gamePollTicked = createEvent();
export const fetchGameDetailFx = createEffect<string, GameDetail>(async (id) => {
  const res = await fetch(`${base}/games/${id}`, { headers: auth() });
  if (!res.ok) throw new Error(`admin /games/:id ${res.status}`);
  return (await res.json()) as GameDetail;
});
export const $selectedGameId = createStore<string | null>(null)
  .on(gameSelected, (_s, id) => id)
  .reset(gameDeselected)
  .reset(roomDeselected); // the shipped 5.2 room-deselect — a game selection never outlives its room
export const $gameDetail = createStore<GameDetail | null>(null)
  .reset(gameDeselected)
  .reset(roomDeselected);
sample({
  clock: fetchGameDetailFx.done,           // .done carries params (the requested id)
  source: $selectedGameId,
  filter: (sel, { params }) => sel === params,   // a late reply for a superseded/cleared id is dropped (L-2)
  fn: (_sel, { result }) => result,
  target: $gameDetail,
});
sample({ clock: gameSelected, target: fetchGameDetailFx });
sample({
  clock: gamePollTicked,
  source: $selectedGameId,
  filter: (id): id is string => id !== null, // a stale tick fires no fetch
  target: fetchGameDetailFx,
});
// $health: fan in fetchGameDetailFx.done / .fail ONLY — the poll re-fires the effect every POLL_MS,
// so a loading flip would strobe the topbar; ok/error stay truthful.
```
`src/views/GameSpectatorView.tsx` (the split — the store is the seam, no fetch here):
```tsx
const POLL_MS = 5000; // the pinned near-live cadence (admin.5.3-D3)
export function GameSpectatorView() {
  const detail = useUnit($gameDetail);
  const pending = useUnit(fetchGameDetailFx.pending);
  useEffect(() => {
    const t = setInterval(() => gamePollTicked(), POLL_MS);
    return () => clearInterval(t); // unmount (back / room deselect / desk switch) stops the poll
  }, []);
  if (!detail) return <Card title="Game">{pending ? <Spinner /> : <span>No game selected.</span>}</Card>;
  const { game, board, guesses } = detail;
  const boardRows = [...board].sort((a, b) => b.score - a.score).map(toBoardRow);
  const feed = [...guesses].sort((a, b) => (a.insertedAt < b.insertedAt ? 1 : -1));
  return (
    <div className="dsh-watch">
      <Card title={`Game ${game.id}`}>
        <Button variant="ghost" onClick={() => gameDeselected()}>Back to room</Button>
        {/* game summary: DataList / Stat of id · room · free · guessFee · prizePool · endsMs + a status Badge
            — mirror the as-built 5.2 pane usage for DataList/Stat prop names */}
        <ScrollArea>
          <Table<BoardRow> columns={BOARD_COLUMNS} data={boardRows} striped getRowKey={(r) => String(r.player)} />
        </ScrollArea>
      </Card>
      <Card title="Events">
        <ScrollArea>{/* feed.map -> ListRow: guess id · points · at (atMs defensively, else insertedAt) */}</ScrollArea>
      </Card>
    </div>
  );
}
```
> `Table`'s prop is `data` (NOT `rows`); `Pagination`-style paging is NOT part of this view. The board pane
> and events pane are each a `Card` + `ScrollArea` — `.dsh-watch` lays them side-by-side, stacking below the
> as-built 860px breakpoint. The LATER live upgrade (out of this rung) replaces only the data source: an engine
> `game:spectate:<id>` `channel` model `sample`s into the SAME `$gameDetail` and the poll is retired — build
> nothing for it beyond this seam.

## Comprehensive implementation prompt
```
Extend @codemojex/dashboard with the live game path's ruled node-only interim — admin.5.3 (D-6 -> PHASED; the
island-mount + engine spectator topic is a LATER /codemojex-ship fork: build the seam, not the upgrade).
Boundary: mercury/codemojex/apps/dashboard/ ONLY (no apps/admin, no packages/*, no echo/ edit). There is NO
open fork: F1 -> Arm C (re-render the board via @mercury/ui), F2 -> Arm C (poll GET /games/:id), F3 -> Arm A
(side-by-side game | events, stacked narrow fallback). admin.5.2 is SHIPPED (244a5a3a) — the settled
as-built names: roomDeselected (the room-deselect event), GAME_COLUMNS + RoomGameRow/toGameRow (the
RoomDetailPane nested-games Table), 860px (the dashboard.css narrow breakpoint).

1. src/types.ts: add BoardEntry { player: string; score: number }, GameGuessItem { id; gameId?; playerId?;
   points: number; atMs?: number|null; insertedAt: string }, GameDetail { game: GameSummary; board:
   BoardEntry[]; guesses: GameGuessItem[] }. GameSummary reused unchanged. No withheld field.
2. src/api/client.ts: gameSelected/gameDeselected events; fetchGameDetailFx = createEffect<string,
   GameDetail> -> fetch(`${base}/games/${id}`, { headers: auth() }); $selectedGameId + $gameDetail reset on
   gameDeselected AND roomDeselected; $gameDetail populated ONLY via the guarded done-sample — sample(clock:
   fetchGameDetailFx.done, source: $selectedGameId, filter: (sel, { params }) => sel === params, fn: (_sel,
   { result }) => result, target: $gameDetail) — the L-2 take-latest guard (a late reply for a superseded or
   cleared id is dropped; a poll reply for the current id passes); sample(gameSelected -> fetchGameDetailFx);
   gamePollTicked + guarded sample(source: $selectedGameId, filter non-null -> fetchGameDetailFx); $health
   fans in fetchGameDetailFx.done/.fail ONLY (no loading flip — the poll would strobe the topbar). No fetch(
   outside this file.
3. src/views/RoomDetailPane.tsx: a Watch Column.render action cell (Button ghost/soft) on the nested games
   Table firing gameSelected(row.id). No Table row-click prop.
4. src/views/GameSpectatorView.tsx (NEW): useUnit($gameDetail) + fetchGameDetailFx.pending; ONE useEffect
   interval firing gamePollTicked() every POLL_MS = 5000 with clearInterval cleanup; a back Button firing
   gameDeselected(); the game pane (summary DataList/Stat + status Badge + score-descending board Table of
   Player/Score) beside the events pane (guesses newest-first by insertedAt as ListRow/DataList, atMs
   rendered defensively); loading only while the FIRST fetch is pending ($gameDetail null).
5. src/views/RoomsView.tsx: while $selectedGameId is non-null render <GameSpectatorView/> in place of the
   master-detail body (the split takes the desk's width); on null the 5.2 list + pane render as before; a
   desk switch clears the selection through the 5.2 deselect chain.
6. src/dashboard.css: .dsh-watch side-by-side layout (each pane Card + ScrollArea), stacked below the
   as-built 860px narrow breakpoint (the media block the dsh-md grid already stacks in), token-driven; no
   .mx-* authored.
7. Gate, from mercury/codemojex: pnpm --filter @codemojex/dashboard typecheck (exit 0); build (bundle
   produced); grep -rnE '"Bearer |secret|cell_codes' src/ -> 0; grep -rn 'fetch(' src/views/ -> 0; the
   @mercury/ui resolved export set unchanged.

Table's prop is `data` (NOT rows). Ground every symbol in admin.5.3.md / the carried shapes / the as-built
5.2 surface. Invent no export, prop, route, or column. Report the gate output verbatim. Framing: third person
for agents; no gendered pronouns; no perceptual/interior-state verbs; no first-person narration.
```

Stories: [`admin.5.3.stories.md`](./admin.5.3.stories.md) · Spec: [`admin.5.3.md`](./admin.5.3.md) · Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
