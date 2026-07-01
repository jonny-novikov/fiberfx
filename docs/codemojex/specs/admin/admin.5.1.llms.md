# admin.5.1 · agent brief

Write-ready: the surface below is pre-mapped so the build's first actions are **writes**, not a read-to-understand
phase. This rung EXTENDS the shipped `@codemojex/dashboard` (admin.5) — the template it mirrors, the client it
extends, and the exact `@mercury/ui` prop shapes are carried inline. Ground every symbol in the shapes here or the
one named template; invent no export, prop, route, or column. Framing (propagate into any sub-brief): no gendered
pronouns for agents; no perceptual / interior-state verbs; no first-person narration.

## References
Read first (cap: these two — everything else is carried inline):
- The rung body — [`admin.5.1.md`](./admin.5.1.md) — the authoritative Deliverables + Invariants.
- The **template to mirror** — `mercury/codemojex/apps/dashboard/src/views/GamesView.tsx` (the as-built list-desk
  shape: a local `Record`-extending row, a `Column<Row>[]`, a `toRow` mapper, a mount-request `useEffect`, a
  `Tabs` filter, `<Card title><Table columns data striped getRowKey/></Card>`). `RoomsView` / `PlayersView` are
  this file with rooms / players data + a search + a pager.

Carried inline (do NOT re-read — the shapes are here):
- **The as-built client seam** (`src/api/client.ts`, admin.5): `fetchGamesFx = createEffect<void,
  GameSummary[]>` → `fetch(\`${base}/games\`, { headers: auth() })`; `$games =
  createStore<GameSummary[]>([]).on(fetchGamesFx.doneData, (_s, g) => g)`; `gamesRequested = createEvent()` +
  `sample({ clock: gamesRequested, target: fetchGamesFx })`; `const auth = () => ({ Authorization: \`Bearer
  ${token}\` })` with `base = import.meta.env.VITE_ADMIN_API_BASE ?? ""` and `token =
  import.meta.env.VITE_ADMIN_TOKEN`. `$health = createStore<Health>("idle").on(fetchGamesFx, () =>
  "loading").on(fetchGamesFx.done, () => "ok").on(fetchGamesFx.fail, () => "error")`; `type Health = "idle" |
  "loading" | "ok" | "error"`. **Reuse `auth()` + `base` + `token` — add no second credential path.**
- **The real admin route shapes** (`apps/admin/src/schemas.ts`, admin.1, shipped; all Bearer-gated, `.limit(200)`):
  - `GET /rooms` → `RoomSummary[]` = `{ id: string (ROM), name: string, free: boolean, clipCost: number|string,
    durationMs: number|null, status: string, insertedAt: string (ISO) }`. No query param.
  - `GET /players` → `PlayerSummary[]` = `{ id: string (PLR), name: string, tgUserId: string|number|null, clips:
    number, diamonds: number, bonusDiamonds: number, lockedDiamonds: number, keys: number, insertedAt: string }`.
    A server `?q` (ilike name) EXISTS but is **deliberately unused** (client-side ruling).
  - Neither carries a `secret` / `cell_codes` field (those are game-only, server-side).
- **The `@mercury/ui` prop shapes** (resolved from source — compose, do not re-house):
  - `Table<Row extends Record<string, unknown>>`: props `{ columns: Column<Row>[]; data: Row[]; striped?: boolean;
    getRowKey?: (row, index) => string | number }`. `Column<Row>` = `{ key: string; label: ReactNode; align?:
    "left" | "right"; render?: (row: Row) => ReactNode }`. (The prop is `data`, NOT `rows`.)
  - `Search`: props `{ value: string; onChange?: (value: string) => void; onSearch?: (value: string) => void;
    placeholder?: string; disabled? }` — controlled; Enter → `onSearch`, Escape → clears.
  - `Pagination`: props `{ page: number /* 1-based */; count: number /* total PAGES, not rows */; onPageChange:
    (page: number) => void; siblingCount?: number; size?: "sm" | "md"; caption?: ReactNode }`.
  - `Tabs<T>`: props `{ tabs: { label: string; value: T }[]; value: T; onChange: (v: T) => void; variant?:
    "pills" }` (the `GamesView` All/Live/Ended usage). `Card`: `{ title?: string; children }`.
- **The as-built shell** (`src/App.tsx`, admin.5): `type Desk = "games" | "rooms" | "players"`; `const NAV: {
  label; value: Desk; enabled: boolean; hint? }[]` — Rooms / Players are `enabled: false, hint: "admin.6"` (flip
  to `enabled: true`, drop the hint); the content region is `{desk === "games" && <GamesView />}` (add the rooms
  / players branches); the Menubar `MENUS` Refresh item fires `gamesRequested()` (make desk-aware).
- Approach — [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md).

## Requirements
- **admin.5.1-R1** — extend `src/api/client.ts`: add `fetchRoomsFx` (→ `GET /rooms` → `RoomSummary[]`), `$rooms`,
  `roomsRequested` + its `sample`, and the same players trio (`fetchPlayersFx` → `GET /players` → `$players`,
  `playersRequested`), each mirroring the games seam and reusing `auth()` / `base` / `token`. Extend `$health` to
  react to all three effects (`.on(fetchRoomsFx, …).on(fetchRoomsFx.done, …).on(fetchRoomsFx.fail, …)`, likewise
  players). [US: admin.5.1-US1]
- **admin.5.1-R2** — complete `src/types.ts`: `RoomSummary` gains `clipCost: number | string` + `durationMs:
  number | null`; `PlayerSummary` gains `tgUserId: string | number | null` + `clips: number` + `bonusDiamonds:
  number` + `lockedDiamonds: number`. Keep both precise interfaces; no `secret` / `cell_codes` field. [US:
  admin.5.1-US2]
- **admin.5.1-R3** — `src/views/RoomsView.tsx` (mirror `GamesView`): a `RoomRow extends Record<string, unknown>`,
  `COLUMNS: Column<RoomRow>[]` (Room · Name · Status · Free · Clip cost · Duration · Created), a `toRow(r:
  RoomSummary): RoomRow`, `useEffect(() => roomsRequested(), [])`, an All/Open/Closed `Tabs` filter off `status`,
  a `Search` (name + id) and a `Pagination` over the filtered rows, `<Card title="Rooms"><Table columns data
  striped getRowKey/></Card>`. No `fetch` in the view. [US: admin.5.1-US3]
- **admin.5.1-R4** — `src/views/PlayersView.tsx` (mirror `GamesView`): a `PlayerRow`, `COLUMNS` (Player · Name ·
  Diamonds · Clips · Keys · Created), a `toRow`, `useEffect(() => playersRequested(), [])`, a `Search` (name +
  id) and a `Pagination`; no status filter. `<Card title="Players"><Table .../></Card>`. No `fetch` in the view;
  public columns only. [US: admin.5.1-US4]
- **admin.5.1-R5** — `src/App.tsx`: set the Rooms / Players `NAV` entries `enabled: true` (drop the `"admin.6"`
  hint), add `{desk === "rooms" && <RoomsView />}` + `{desk === "players" && <PlayersView />}` in the content
  region, and make the Refresh action fire the active desk's request event. [US: admin.5.1-US5]
- **admin.5.1-R6** — the client-side page + search plumbing per desk: a `page` + `query` state, `filtered =
  rows.filter(name/id includes query)`, `pageCount = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE))`, `paged
  = filtered.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)`; reset `page` to 1 on a query / filter change; a
  `Pagination` `caption` like `Showing X–Y of Z`. `PAGE_SIZE` a local const (25). Optional DRY: a single app-local
  `src/lib/usePagedList.ts` hook the two desks share (app plumbing, not a `@mercury` component). [US:
  admin.5.1-US3, admin.5.1-US4]
- **admin.5.1-R7** — the small app-local layout CSS in `src/dashboard.css` for the desk toolbar (search + filter
  row) and the pager row (`.dsh-desk__tools`, `.dsh-desk__pager`), token-driven (`rgb(var(--token))`); reuse the
  existing `.dsh-desk__bar` / `.dsh-desk__count`. No `.mx-*` authored. [US: admin.5.1-US3]
- **admin.5.1-R8** — from `mercury/codemojex`: `pnpm --filter @codemojex/dashboard typecheck` exits 0; `pnpm
  --filter @codemojex/dashboard build` produces the bundle; the `@mercury/ui` resolved export set is unchanged;
  `grep -rnE '"Bearer |secret|cell_codes' src/` and `grep -rn 'fetch(' src/views/` read 0. [US: admin.5.1-US6]

## Execution topology
Runtime:
```
config: VITE_ADMIN_TOKEN, VITE_ADMIN_API_BASE="" (admin.5-F2, dev proxy forwards /rooms,/players -> admin svc)
      |
  api/client.ts (extended)
      |-- fetchRoomsFx   --> fetch(`${base}/rooms`,   { Authorization: `Bearer ${token}` }) --> $rooms
      |-- fetchPlayersFx --> fetch(`${base}/players`, { Authorization: `Bearer ${token}` }) --> $players
      |-- $health <- (fetchGamesFx | fetchRoomsFx | fetchPlayersFx) . (loading|done|fail)
      v
  views/RoomsView.tsx   --useUnit($rooms)--> Search + Tabs(status) + Table(paged) + Pagination   (no fetch)
  views/PlayersView.tsx --useUnit($players)--> Search + Table(paged) + Pagination                (no fetch)
      |
  App.tsx: NAV rooms/players enabled -> {desk === "rooms" && <RoomsView/>} / {"players" && <PlayersView/>}
           Menubar Refresh -> the active desk's *Requested() event
```
Tasks (build-order DAG):
```
R2 types.ts ─┬─> R1 client.ts ─┬─> R3 RoomsView ──┐
             │                 └─> R4 PlayersView ─┤
R6 paging ───┘ (inline or a shared hook)          ├─> R5 App.tsx (enable nav + mount + desk-aware refresh)
R7 dashboard.css ─────────────────────────────────┘        └─> R8 typecheck + build + greps
```
Touched files (all under `mercury/codemojex/apps/dashboard/`): NEW — `src/views/RoomsView.tsx`,
`src/views/PlayersView.tsx` (+ optional `src/lib/usePagedList.ts`); EDIT — `src/api/client.ts`, `src/types.ts`,
`src/App.tsx`, `src/dashboard.css`. Read-only template: `src/views/GamesView.tsx`. **No edit** to `apps/admin`,
`packages/*`, or `echo/`.

## Agent stories
- **admin.5.1-AS1** [implements admin.5.1-US1] — Directive: extend `api/client.ts` with the rooms / players store
  seams + the `$health` fan-in (R1) and complete `types.ts` (R2). Acceptance gate: postcondition — a rooms /
  players fetch lands in `$rooms` / `$players` and drives `$health`; invariant — no `"Bearer "` literal in `src/`,
  `auth()` reused, no `fetch(` added outside `client.ts`.
- **admin.5.1-AS2** [implements admin.5.1-US2] — Directive: complete the public shapes (R2). Acceptance gate:
  postcondition — `RoomSummary` / `PlayerSummary` carry the real `schemas.ts` columns; invariant — no `secret` /
  `cell_codes` field on `types.ts`.
- **admin.5.1-AS3** [implements admin.5.1-US3] — Directive: build the rooms desk (R3 + R6 + R7) mirroring
  `GamesView`. Acceptance gate: precondition — a reachable gated admin API; postcondition — the rooms desk lists
  live rows through `$rooms` with a status filter, a working `Search`, and a working `Pagination`; invariant — no
  `fetch(` in the view, search / page filter the client array (no new server param).
- **admin.5.1-AS4** [implements admin.5.1-US4] — Directive: build the players desk (R4 + R6). Acceptance gate:
  postcondition — the players desk lists live rows through `$players` with `Search` + `Pagination`; invariant — no
  `secret` / `cell_codes` column, no `fetch(` in the view.
- **admin.5.1-AS5** [implements admin.5.1-US5] — Directive: wire the shell (R5). Acceptance gate: postcondition —
  the Rooms / Players nav is enabled and each desk mounts; Refresh re-runs the active desk; invariant — the
  `@mercury/ui` resolved export set is unchanged (barrel-diff, 0 removed / renamed).
- **admin.5.1-AS6** [implements admin.5.1-US6] — Directive: gate green (R8). Acceptance gate: postcondition —
  `typecheck` exit 0 + `build` produces a bundle; invariant — the barrel holds; the secret / `fetch`-in-view greps
  read 0.

## Execution plan — first two stories
1. **admin.5.1-AS2 then AS1 (the seam first).** Open `src/types.ts`; add `clipCost` / `durationMs` to
   `RoomSummary` and `tgUserId` / `clips` / `bonusDiamonds` / `lockedDiamonds` to `PlayerSummary` (shapes above).
   Then extend `src/api/client.ts`: copy the `fetchGamesFx` / `$games` / `gamesRequested` trio twice (rooms,
   players), swapping the path + type + store, reusing `auth()`; extend `$health` with the two new effects. First
   actions are writes — the shapes are all above.
2. **admin.5.1-AS3 (the rooms desk).** Copy `src/views/GamesView.tsx` to `RoomsView.tsx`; swap `GameRow` →
   `RoomRow` + its `COLUMNS` + `toRow`; swap `$games` / `gamesRequested` → `$rooms` / `roomsRequested`; keep the
   `Tabs` filter but as All/Open/Closed off `status`; add a `Search` state + a `Pagination` over the filtered
   rows (R6 sketch below). Then `PlayersView.tsx` the same, without the status filter.

## Write-ready sketches (copy + adapt; the survival kit)
`src/api/client.ts` (the two new seams — mirror the games trio exactly):
```ts
import type { RoomSummary, PlayerSummary } from "@/types";
export const fetchRoomsFx = createEffect<void, RoomSummary[]>(async () => {
  const res = await fetch(`${base}/rooms`, { headers: auth() });
  if (!res.ok) throw new Error(`admin /rooms ${res.status}`);
  return (await res.json()) as RoomSummary[];
});
export const $rooms = createStore<RoomSummary[]>([]).on(fetchRoomsFx.doneData, (_s, r) => r);
export const roomsRequested = createEvent();
sample({ clock: roomsRequested, target: fetchRoomsFx });
// …the players trio is identical: /players -> PlayerSummary[] -> $players, playersRequested.
// $health fans in all three:
export const $health = createStore<Health>("idle")
  .on([fetchGamesFx, fetchRoomsFx, fetchPlayersFx], () => "loading")
  .on([fetchGamesFx.done, fetchRoomsFx.done, fetchPlayersFx.done], () => "ok")
  .on([fetchGamesFx.fail, fetchRoomsFx.fail, fetchPlayersFx.fail], () => "error");
```
`src/views/RoomsView.tsx` (the client-side search + pager over `GamesView`'s shape):
```tsx
const PAGE_SIZE = 25;
export function RoomsView() {
  const rooms = useUnit($rooms);                 // the store is the seam — no fetch here
  const [status, setStatus] = useState<"all" | "open" | "closed">("all");
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  useEffect(() => { roomsRequested(); }, []);
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return rooms.filter((r) =>
      (status === "all" || r.status === status) &&
      (q === "" || r.name.toLowerCase().includes(q) || r.id.toLowerCase().includes(q)),
    );
  }, [rooms, status, query]);
  const pageCount = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const clamped = Math.min(page, pageCount);
  const paged = filtered.slice((clamped - 1) * PAGE_SIZE, clamped * PAGE_SIZE).map(toRow);
  // reset page on filter/query change: useEffect(() => setPage(1), [status, query]);
  return (
    <Card title="Rooms">
      <div className="dsh-desk__bar">
        <Tabs<"all" | "open" | "closed"> tabs={STATUS_TABS} value={status} onChange={setStatus} variant="pills" />
        <Search value={query} onChange={setQuery} placeholder="Search rooms" />
        <span className="dsh-desk__count">{filtered.length} shown</span>
      </div>
      <Table<RoomRow> columns={COLUMNS} data={paged} striped getRowKey={(r) => r.id} />
      <Pagination page={clamped} count={pageCount} onPageChange={setPage}
        caption={`Showing ${filtered.length === 0 ? 0 : (clamped - 1) * PAGE_SIZE + 1}–${Math.min(clamped * PAGE_SIZE, filtered.length)} of ${filtered.length}`} />
    </Card>
  );
}
```
> `Pagination.count` is the total **page** count (not rows). `Table`'s prop is `data` (not `rows`) — the admin.5
> mutation-kill proved `rows` fails typecheck. Confirm at `mercury/packages/mercury-ui/src/components/data-display/
> Table/Table.tsx` + `inputs/Search/Search.tsx` + `navigation/Pagination/Pagination.tsx` only if a prop name is
> in doubt — the shapes are carried above.

## Comprehensive implementation prompt
```
Extend @codemojex/dashboard (admin.5, shipped) with the rooms + players LIST desks — admin.5.1. Boundary:
mercury/codemojex/apps/dashboard/ ONLY (no apps/admin, no packages/*, no echo/ edit). There is NO open fork:
pagination + search are client-side (filter/page the <=200 rows the routes return, in the browser) and the build
is frontend-only. Mirror the as-built src/views/GamesView.tsx template exactly.

1. src/types.ts: complete RoomSummary (+ clipCost: number|string, durationMs: number|null) and PlayerSummary
   (+ tgUserId: string|number|null, clips, bonusDiamonds, lockedDiamonds: number) to apps/admin/src/schemas.ts.
   No secret / cell_codes field.
2. src/api/client.ts: add fetchRoomsFx/$rooms/roomsRequested and fetchPlayersFx/$players/playersRequested,
   mirroring the fetchGamesFx trio, reusing auth()/base/token (no second credential path). Extend $health to
   fan in all three effects. Add no fetch( outside this file.
3. src/views/RoomsView.tsx: mirror GamesView — a RoomRow extends Record<string,unknown>, a Column<RoomRow>[] of
   public columns (Room/Name/Status/Free/Clip cost/Duration/Created), a toRow, useEffect(roomsRequested), an
   All/Open/Closed Tabs filter off status, a client-side Search (name+id) + Pagination (PAGE_SIZE=25, count =
   ceil(filtered/PAGE_SIZE)) over the filtered rows, <Card title="Rooms"><Table columns data striped getRowKey/>.
4. src/views/PlayersView.tsx: same shape for players (Player/Name/Diamonds/Clips/Keys/Created), Search +
   Pagination, no status filter.
5. src/App.tsx: set the Rooms/Players NAV entries enabled:true (drop the "admin.6" hint); mount {desk==="rooms"
   && <RoomsView/>} and {desk==="players" && <PlayersView/>}; make the Menubar Refresh fire the active desk's
   *Requested() event.
6. src/dashboard.css: small app-local layout for the desk toolbar (search+filter) + pager rows, token-driven; no
   .mx-* authored. Reuse .dsh-desk__bar / .dsh-desk__count.
7. Gate, from mercury/codemojex: pnpm --filter @codemojex/dashboard typecheck (exit 0); build (bundle produced);
   grep -rnE '"Bearer |secret|cell_codes' src/ -> 0; grep -rn 'fetch(' src/views/ -> 0; the @mercury/ui resolved
   export set unchanged.

Table's prop is `data` (NOT rows). Pagination.count is total PAGES. Ground every symbol in admin.5.1.md / the
carried shapes / the GamesView template. Invent no export, prop, route, or column. Report the gate output
verbatim. Framing: no gendered pronouns for agents; no perceptual/interior-state verbs; no first-person.
```

Stories: [`admin.5.1.stories.md`](./admin.5.1.stories.md) · Spec: [`admin.5.1.md`](./admin.5.1.md) · Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
