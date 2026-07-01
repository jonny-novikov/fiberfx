# codemojex-admin — AAW scope ledger

## {codemojex-admin-decisions} Decisions

### D-1

admin.1 scope = the gated read foundation — Operator-ruled. This week ships admin.1: harden the as-built Fastify read plane (/health, rooms, games, players + live Valkey board) into a real operator API — auth-gated, TypeBox-typed, secret-never-on-wire, bootable solo + clustered, with tests. Management (admin.2), economy/treasury incl. cm.8 (admin.3), moderation (admin.4) ladder behind it. Rationale: the read foundation is the floor every later write/economy rung stands on.

### D-2

admin.1 auth = operator bearer token — Operator-ruled. The admin API currently has NO access control; admin.1 adds a Fastify preHandler checking a bearer against an env ADMIN_TOKEN (one shared operator credential, zero new deps). Coarse by design — per-operator identity/audit is deferred to a later rung. Chosen over the Telegram-admin allowlist (heavier: pulls in SES/initData verify) and over deferring auth (open API = weakest posture).

### D-3

The mercury workspace-wiring fix — Operator-ruled (a reconcile prerequisite). admin.1's build blocked on `mercury/pnpm-workspace.yaml` globbing the renamed-away `codemojex-node/*` (dead since the codemojex-node→codemojex rename); with no own workspace file, pnpm walked up to `mercury/` and left codemojex's `workspace:*` deps unlinked. codemojex CANNOT be standalone — its `@echo/core`/`@echo/cluster` deps live in `mercury/packages/`, forcing shared membership. Fix: repoint the glob to `codemojex/{packages,apps}/*`, EXCLUDE `apps/game` (its own nested workspace + lockfile). Director-applied + verified (a filter-resolution check). The `mercury/pnpm-workspace.yaml` + rewritten `mercury/pnpm-lock.yaml` are the Operator's in-flight mercury infra — a SEPARATE commit concern from the admin.1 code.

### D-4

The @codemojex/db drift = full read-model reconcile — Operator-ruled. The live games/guesses/players reads 500'd: `@codemojex/db` was hand-modeled "from observation" (its header says so) and had drifted broadly from the engine's migration DDL — a fictional `room_id`/`prize_usd`/`totals` (games), `game_id`/`codes`/`score` (guesses), `available_*` (players). Blast radius = admin-only (no other `@codemojex/db` importer). Ruled: full reconcile NOW (over games-path-only or close-lean), folded into admin.1, revising admin.1-R3 (the read-plane shapes change to the real columns). Two waves (schema.ts → routes + response schemas + test) against the migration DDL as truth; the real secret columns are `secret` + `cell_codes`.

### D-5

D — admin.5 fork rulings (Operator, Wave 2). admin.5-F1 → Arm B (compose the operator shell frame LOCALLY in apps/dashboard from @mercury/ui Card/Tabs/ScrollArea/Menubar; NO new @mercury/ui primitive; barrel untouched; build stays a cm-ship Duo; the shared AppShell extraction is ruled-DEFERRED to a later /mercury-ship rung, rule-of-three). admin.5-F2 → Arm A (same-origin) + a Vite dev proxy: VITE_ADMIN_API_BASE="" so the Bearer never crosses an origin; the Shell wires a vite server.proxy → the admin service (admin.5-D4 reads live in dev); the prod admin-Fastify @fastify/static serve is a NAMED near-term follow-up on apps/admin (deploy-gated, after the Shell dist/ exists) — NOT this rung's build gate. admin.5-F3 → confirmed: the live slot seats on the existing @mercury/effector channel adapter; no channel + no new effector API this rung; the only obligation is the $games store seam (admin.5-D5/INV4). Folded into admin.5.md (Forks RULED, D2/D3 pinned, DoD [x]) + admin.5.llms.md (write-ready) + admin.roadmap.md; admin.5.stories.md left (arm-agnostic). admin.5 is now fully-ruled BUILD-GRADE.

### D-6

D — admin.5.2 / 5.3 / 5.4 fork rulings (Operator). The three forks venus framed in `admin.5.desks.design.md` are RULED:
(1) **admin.5.2-F1 → Arm C (side panel / master-detail).** A `$selectedId` + a keyed `fetchDetailFx(id)` seam; a side pane composed LOCALLY (`Card` + `ScrollArea` — NO new `@mercury/ui` primitive, the admin.5-F1→Arm B locality rule holds) beside the narrowed list. Chosen over Arm A (inline `Collapsible`, too shallow for the player ledger) + Arm B (`Popover` peek, ephemeral, doesn't extend to the live pane); the selected-id seam is the SAME one admin.5.3 extends (room→game→live).
(2) **admin.5.3 → PHASED (interim now / live later).** admin.5.3 ships a NODE-ONLY interim FIRST — a spectator board re-rendered from `GET /games/:id` (board + guesses) via `@mercury/ui` + a poll for near-live, in a side-by-side split (game | events), the room→game nav extending admin.5.2's `$selectedId` seam; frontend-only, ZERO echo/ coupling. The TRUE live island-mount (`mount` `@codemojex/game` + a read-only echo/ `game:spectate:<id>` topic) is a LATER live-upgrade rung — a `/codemojex-ship` ENGINE fork — swappable with no rewrite (the two-clock store seam). So 5.3-F1 → Arm C interim / Arm A later; 5.3-F2 → Arm C poll / Arm A (echo/) later; 5.3-F3 → Arm A side-by-side.
(3) **admin.5.4 → 5.4-a (observability & shared filter-state).** A header `Stat` strip (live counts) + URL-encoded filter/search + per-desk auto-refresh; frontend-only. Chosen over 5.4-b (operator actions / the write twin — deferred to pair with admin.2).
Folded into `admin.5.desks.design.md` (each fork marked RULED, arms kept as decision-context), `admin.roadmap.md` (the 5.2/5.3/5.4 entries), and admin.5.2 authored to BUILD-GRADE (the master-detail rung, Arm C). admin.5.3's full triad is left for its own build run (a strong design entry now); admin.5.4 stays a roadmap entry.

## {codemojex-admin-progress} Progress

### P-1

admin chapter authored + gated — sharpen complete. Wrote docs/codemojex/specs/admin/{admin.md (index), admin.roadmap.md, admin.1.md, admin.1.stories.md, admin.1.llms.md} to aaw.specs-approach.md. Six gates GREEN: voice · structure (6 §, 5 5W bullets) · traceability (Coverage + every INV encoded + R#[US:] + AS#[implements]) · fences · format via the sweep, and links via mcp__msh__specs (no findings). Grounded in the as-built Fastify app (server.ts buildServer, env.ts loadEnv, reply.ts send, schemas.ts, routes/{rooms,games,players}.ts, valkey.ts readBoard, cluster.ts runCluster) — no invention. admin.1 = the gated read foundation: a Fastify preHandler bearer gate (ADMIN_TOKEN, /health exempt) over the as-built read plane, secret-never-on-wire, boots green solo + clustered. NEXT (build stage): implement admin.1 (Mars) — pnpm install in mercury/codemojex (deps absent), env.ts adminToken, the preHandler, apps/admin/test/admin.test.ts app.inject suite, typecheck + boot smoke.

### P-2

admin.1 BUILT + SHIPPED via /cm-ship (the harness's inaugural run). The bearer gate (`ADMIN_TOKEN` + a `preHandler` in `buildServer`, `/health` exempt, 401 `{error:"unauthorized"}`) + the `app.inject` suite (`node --test` via tsx, zero new dep) + the boot-smoke; then the D-4 read-model reconcile (games/guesses/players → the engine DDL) so the reads return live data. All four invariants LIVE-proven + green: INV1 (401/200 gate) live + mutation-verified (invert the gate → 4 tests fail); INV2 (no `secret`/`cell_codes`) proven LIVE on a real game (`GAM0OQGpUv3naC`) + structural + mutation-verified (leak the secret → 2 tests fail, reverted net-zero); INV3 (health open) live; INV4 (typecheck 0 + boot-smoke ready). Suite 7 pass / 0 skip. Director verify: an independent gate re-run + a schema↔information_schema diff + two net-zero mutation kills. Boundary held: `mercury/codemojex/apps/admin/**` + `packages/db/src/schema.ts`; no echo/ edit. Realizations: the shared-app-per-suite test (the `@codemojex/db` `sql` singleton); `preHandler` runs after validation (so the 401 tests hit list routes); the games→rooms join = `eq(games.room, rooms.id)` (a RoomId string, not a FK). L: cm-program's "installs independently" floor claim was WRONG (codemojex is a `mercury/` member) — corrected; the write-ready 2-wave reconcile (schema checkpoint → wiring) held.

### P-3

admin.5 (the dashboard Shell) AUTHORED + RECONCILED — a spec-only /cm-ship **Duo** run (Director + venus-cm), no build / no git. The reconcile promoted admin.5 from "the console UI (optional)" to **THE FOCUS**: a new **Milestone B** (the operator console / frontend track) with admin.5 (the Shell) + admin.6 (DB-view desks) + admin.7 (live pubsub channel) sketched; `@codemojex/economy` disambiguated (a STATIC `/economy` console, no API — distinct from admin.3's economy&treasury DESK); the frontend-precedent split corrected (economy = the SPA-skeleton template; game = the channel-pattern precedent only — see L-1). Grounded in the mature `@mercury/ui` barrel (Table/DataList/Stat/Card/… — **no operator AppShell**), the existing `@mercury/effector` `channel` adapter (`game/src/channel/model.ts`) as the pubsub foundation, the shipped `@codemojex/admin` read plane (`GameSummary`, secret-free), and the echo/ `frontend-delivery.design.md` same-origin precedent. The Shell = a Vite+React SPA at `mercury/codemojex/apps/dashboard` (greenfield, `@codemojex/dashboard`): a locally-composed operator shell layout, a Bearer `@mercury/effector`-style admin client, one live games DB view, a two-clock store seam (HTTP now / `channel` later) — D1–D6, INV1–5, US1–6, R1–R8, AS1–6. Three forks framed + Operator-RULED (D-5): F1→Arm B (local compose, no barrel touch → the build is a **cm-ship Duo, not Squad**), F2→Arm A same-origin + a Vite dev-proxy (token never crosses an origin; the prod `@fastify/static` serve = a named `apps/admin` follow-up), F3→confirmed (no channel this rung). Six spec gates GREEN; `mcp__msh__specs` no findings; admin.5 is fully-ruled BUILD-GRADE. NEXT (build stage): `/cm-ship admin.5` — spawn the Duo from `admin.5.llms.md` as-is. Craft note: a Wave-2 agent-message DEDUP (venus read the rulings-fold as a stale task echo → "nothing to do") was resolved by explicit **single-writer** discipline — the Director restated the rulings (which unstuck the fold), let venus own the triad edits, and held off co-editing after a `modified-since-read` near-collision; candidate to fold into the spawn-resilience harness law.

### P-4

admin.5 (the dashboard Shell) BUILT + gate GREEN via /cm-ship — a **Duo** (Director + mars-cm), the harness's first codemojex-node *frontend* build. Greenfield `@codemojex/dashboard` at `mercury/codemojex/apps/dashboard` (11 files, mirroring the `economy` SPA per [[L-1]]): `package.json` · `vite.config.ts` (+ `server.proxy` → the admin service :3000, ruled F2 dev) · `tsconfig.json` · `index.html` · `.env.example` · `src/{main,App}.tsx` · `src/types.ts` · `src/api/client.ts` · `src/views/GamesView.tsx` · `src/dashboard.css` · `src/vite-env.d.ts`. Composes `@mercury/ui` (`Menubar`/`ScrollArea`/`Card`/`Table`/`Tabs`) + `@mercury/effector` (`initTheme`/`setTheme`); the barrel is UNTOUCHED (F1→Arm B, local compose). The two-clock seam: `api/client.ts` holds `fetchGamesFx` + `$games` + a derived `$health` tri-state + a `gamesRequested` mount event; a view reads `$games` via `useUnit` (no view-local fetch) so admin.7 `sample`s a `channel` model INTO `$games` with no rewrite. Director verify (independent): `pnpm --filter @codemojex/dashboard typecheck` clean + `build` green (bundle 236 kB / gzip 78 kB); INV1 (Bearer from config — only the env template `` `Bearer ${token}` ``, no literal) · INV2 (no `secret`/`cell_codes`/`keyboard` — STRUCTURAL on `types.ts` + grep 0) · INV3 (barrel held — authorship disjoint from `packages/`, NOT a text-diff: a concurrent /mercury-ship run was editing `mercury-ui/index.ts` in parallel) · INV4 (raw `fetch(` only in `client.ts`) · INV5 (green). Net-zero mutation kill: `data`→`rows` on `<Table>` → `TS2322 Property 'rows' does not exist` → reverted (the typecheck gate has teeth). Liveness: BUILT proves the config→Bearer-fetch→store→render pipeline; the LIVE gated read is **served-pending a standing admin service** (a spawned node is reaped at turn-end — dev: `pnpm -C mercury --filter @codemojex/dashboard dev` with the admin up on :3000). Boundary held: `mercury/codemojex/apps/dashboard/**` ONLY; no `apps/admin`/`packages/*`/`echo/` edit. **Lockfile EXCLUDED from the rung commit** — `pnpm install` reconciled `mercury/pnpm-lock.yaml` against an actively-changing tree (my dashboard-add + a concurrent prune of a stale `apps/showcase` importer — showcase is gone on disk), an entangled shared root artifact the Operator manages out-of-band; a fresh `pnpm install` regenerates it from the committed `package.json`s. Spec reconciled to as-built: DoD [x]; D4 columns `counts`→`ends` (the public `GameSummary` carries no count field — a spec over-reach corrected, in `.md` + `.llms`); `vite-env.d.ts` added to the D1 skeleton. Deviations (all Director-verified sound): the `$health` store (makes R3's indicator real, derived PURELY from the effect — no new wire); a client-side All/Live/Ended `Tabs` filter off `endsMs` (no invented server param; "All" default preserves the full list, AS4); a `Menubar` topbar (Refresh→`gamesRequested`, Theme→`setTheme`); two doc-comment rewordings so the INV2/INV4 greps read a clean 0 without matching prose (the STRUCTURAL invariants hold independently — verified by READ, not the proxy grep). NEXT: admin.6 (the DB-view desks — rooms/players list+detail, pagination, search over the Shell) · the prod `@fastify/static` same-origin serve (the named `apps/admin` follow-up, deploy-gated) · admin.2 lifecycle (Milestone A).

### P-5

admin.6 → the admin.5.1–5.4 desk ladder RE-CHAPTERED + specs AUTHORED — a spec-only `/cm-ship` **Duo** (Director
+ venus-cm), no build / no git. The Operator dissolved the coarse admin.6 (DB-view desks) + admin.7 (live pubsub)
into a finer sub-ladder under the shipped admin.5 Shell: **admin.5.1** (rooms + players LIST desks) · **admin.5.2**
(master-detail) · **admin.5.3** (the live game path — embed `@codemojex/game`, split game/events; **subsumes**
admin.7) · **admin.5.4** (a PROPOSED forward slot). Pagination + search ruled **client-side** (filter/page the
≤200 rows the routes already return, in-browser), so admin.5.1/5.2 are **frontend-only** (`apps/dashboard`), no
backend edit.

**Reconciled against the as-built** (lag-1, the frontend/mercury capability lens): the shipped `GamesView` is the
list-desk template — `<Table<Row> columns data striped getRowKey>` (the prop is `data`, NOT `rows` — the [[P-4]]
mutation-kill proved `rows` fails typecheck; the admin.5.llms sketch's `rows` was STALE), `Column<Row>{key,label,
align?,render?}`, `<Card title>`, a `Tabs` client filter, a mount-request `useEffect`. Two STALE→corrected facts
carried into admin.5.1: (1) `types.ts`'s `RoomSummary`/`PlayerSummary` are **partial stubs** — MISSING
`clipCost`/`durationMs` (rooms) and `tgUserId`/`clips`/`bonusDiamonds`/`lockedDiamonds` (players) vs the real
`apps/admin/src/schemas.ts`; admin.5.1-D2 completes them. (2) `$health` derives from `fetchGamesFx` only; admin.5.1
fans it into all three effects. `@mercury/ui` `Search` (controlled `value`/`onChange`/`onSearch`) + `Pagination`
(`page`/`count`=total **pages**/`onPageChange`/`caption`) confirmed in the barrel → admin.5.1 composes existing
exports, **no new primitive, no open fork**. Verdict: **admin.5.1 = BUILD-GRADE** (D1–D6, INV1–6, US1–6, R1–R8,
AS1–6; six gates + `mcp__msh__specs` clean).

**Authored:** `admin.roadmap.md` re-chaptered (admin.6/7 → the 5.1–5.4 ladder + a Shell-desk-ladder note; stale
admin.7 refs repointed to admin.5.3) · `admin.5.1.{md,stories.md,llms.md}` (full write-ready triad, mirroring the
admin.5 quality) · `admin.5.desks.design.md` (NEW — the framed forks + the 5.4 proposals) · `admin.md` (value
ladder → the 5.x sub-ladder + the Two-tracks para) · this ledger.

**Framed forks (Operator rules before those rungs build):** admin.5.2-F1 the detail-interaction model (Arm A
inline `Collapsible` · Arm B `Popover` peek · Arm C side `Panel`/master-detail — Steward leans **C**, the
selected-id seam extends into 5.3) · admin.5.3-F1 game-embed (Arm A workspace-`mount` the island · Arm B iframe
the edge game · Arm C re-render via `@mercury/ui` — Steward leans **A** paired with F2, **C** the zero-coupling
interim) · admin.5.3-F2 spectator bridge (Arm A an engine spectator topic — an **`echo/` → `/codemojex-ship`
fork** · Arm B join read-only · Arm C poll `GET /games/:id` — Steward leans **A** for live, **C** node-only
interim) · admin.5.3-F3 split-view (side-by-side / stacked / tabbed — leans side-by-side, low-stakes). **admin.5.4
PROPOSED:** 5.4-a cross-desk observability & shared filter-state (frontend-only) · 5.4-b operator actions on the
desks (the read plane's write twin — surfaces `PATCH /rooms/:id/status`, crosses into write, pairs with admin.2);
a lighter export/snapshot noted. NEXT (build stage): `/cm-ship admin.5.1` (spawn the Duo from `admin.5.1.llms.md`
as-is — no fork to rule) · the Operator rules the 5.2 / 5.3 forks + picks 5.4 before those rungs author triads.
Boundary held: `docs/codemojex/specs/admin/**` only; no code / no build / no git; every symbol grounded in a real
file (no invented route/prop/column/export). [[P-4]] [[D-5]] [[L-1]]

### P-6

Wave 2 — the three forks RULED (D-6) + admin.5.2 authored BUILD-GRADE. A spec-only `/cm-ship` delta (Director + venus-cm), no build / no git. The Operator ruled admin.5.2-F1 → **Arm C** (side panel / master-detail), admin.5.3 → **phased** (node-only interim now / the echo/-coupled live-mount later, a `/codemojex-ship` fork), admin.5.4 → **5.4-a** (observability). Folded the rulings into `admin.5.desks.design.md` (each fork header marked RULED, arms retained as decision-context) + `admin.roadmap.md` (the 5.2/5.3/5.4 entries repointed to the ruled directions).

**Authored `admin.5.2.{md,stories.md,llms.md}` to build-grade** — the master-detail rung over the admin.5.1 list desks. Reads the SHIPPED (admin.1) `GET /rooms/:id` → `RoomDetail { room, games:[{id,status,free,prizePool,endsMs,insertedAt}] }` + `GET /players/:id` → `PlayerDetail { player, guesses:[{id,gameId,points,atMs,insertedAt}], ledger: unknown[] }` through keyed `fetchRoomDetailFx(id)` / `fetchPlayerDetailFx(id)` effects + a `$selectedRoomId` / `$selectedPlayerId` store; a side pane (`Card` + `ScrollArea`, LOCAL) renders the detail (room summary as `DataList`/`Stat` + its games as a nested `Table`; player summary + guesses + ledger as `DataList`/`ListRow`/`Stat`) beside the narrowed list. **Grounded the detail-pane primitives against the real `.tsx`** (`DataList`{items}, `ListRow`{label,onClick→interactive-button}, `Stat`{label,value,delta}, `Badge`{children,variant}). Fork-avoidance pinned: `Table` has NO `onClick`/row-selection prop → selection goes through a `Column.render` action cell (the `render?` hook is real), NEVER a new Table prop (a `/mercury-ship` barrel fork). Same INV spine as admin.5.1 (Bearer-from-config · public-schema-only, no secret/cell_codes · barrel-holds, compose-only · two-clock store seam, the detail store a channel can later target · green); frontend-only (`apps/dashboard`), no echo/ / apps/admin / packages/* edit. Six spec gates GREEN (`mcp__msh__specs` no findings). admin.5.2 = BUILD-GRADE. NEXT: `/cm-ship admin.5.1` then `/cm-ship admin.5.2` (each reconciles against the as-built at build time — 5.2 extends 5.1's views + client seam). [[P-5]] [[D-6]]

### P-7

admin.5.1 (rooms + players list desks) BUILT + gate GREEN via `/cm-ship` — a **Duo** (Director + mars-cm), the
write-ready dispatch spawned from `admin.5.1.llms.md` as-is (no fork to rule; the P-5/P-6 client-side +
frontend-only rulings in hand). Built, all under `mercury/codemojex/apps/dashboard/`: NEW
`src/views/RoomsView.tsx` (Room·Name·Status·Free·Clip cost·Duration·Created; All/Open/Closed `Tabs` off
`status`) · NEW `src/views/PlayersView.tsx` (Player·Name·Diamonds·Clips·Keys·Created; no status filter) · NEW
`src/lib/usePagedList.ts` (the R6 optional-DRY shared hook: PAGE_SIZE 25, `pageCount = max(1,
ceil(filtered/25))`, page clamped + reset-to-1 on query/resetKey change, the `Showing X–Y of Z` caption) · EDIT
`src/api/client.ts` (`fetchRoomsFx`/`$rooms`/`roomsRequested` + the players trio mirroring the games seam, ONE
`auth()` path; `$health` fanned into all three effects via the array `.on` form) · EDIT `src/types.ts`
(`RoomSummary` +`clipCost`/`durationMs`, `PlayerSummary` +`tgUserId`/`clips`/`bonusDiamonds`/`lockedDiamonds` —
the real `schemas.ts` shapes) · EDIT `src/App.tsx` (NAV `enabled: true`, the stale `"admin.6"` hints dropped;
both desks mounted; Refresh desk-aware via a `REFRESH: Record<Desk, () => void>` map + `buildMenus(desk)` under
`useMemo`) · EDIT `src/dashboard.css` (`.dsh-desk__tools` + `.dsh-desk__pager`, token-driven, no raw hex, no
`.mx-*`). Director verify (independent): `pnpm --filter @codemojex/dashboard typecheck` exit 0 + `build` green
(bundle 241.75 kB / gzip 79.17 kB); `grep -rnE '"Bearer |secret|cell_codes' apps/dashboard/src/` → 0 (INV1/INV2)
· `grep -rn 'fetch(' apps/dashboard/src/views/` → 0 (INV4) · INV3 barrel held by authorship disjointness (only
`apps/dashboard` touched; a concurrent run is minting `mercury/packages/mercury-ds/` — the [[P-4]] text-diff
caveat applies) · INV5 by construction (no server param added in `client.ts`; 0 `apps/admin` files in the diff).
Adversarial probe HELD: `schemas.ts` types `clipCost`/`durationMs`/`tgUserId` as `Loose = Type.Any()` — the TS
pins mirror the shipped `GameSummary`-over-`Loose` precedent, and a string-on-the-wire `durationMs` coerces
safely through JS division (no NaN path short of garbage; the wire typing is admin.1's serialization concern).
Net-zero mutation kill: `count={list.pageCount}` → `count={list.caption}` on `<Pagination>` → `TS2322 Type
'string' is not assignable to type 'number'` → reverted, typecheck green again (the typecheck gate has teeth;
no unit suite in this SPA). Deviations (all Director-verified sound): the shared `usePagedList` hook (brief-
sanctioned) · `Search` nested in a `.dsh-desk__tools` group inside the reused `.dsh-desk__bar` (R7's toolbar
made real) · the Refresh label dynamic (`Refresh ${desk}`; R5 pins the event, not the label) · display picks
(`duration` = `${round(ms/1000)}s` with the null em-dash, `free` = yes/no — the `GamesView` precedent).
REMEDIATE loop closed at ZERO findings — the mars-cm-2 harden wave collapsed (right-size). Liveness: the
config→Bearer-fetch→store→render pipeline is proven by build + greps; the LIVE gated read stays served-pending
a standing admin service (dev: the Vite proxy → the admin service, the [[P-4]] posture). Boundary held:
`mercury/codemojex/apps/dashboard/**` ONLY; **lockfile again EXCLUDED** (the pre-existing entangled
`mercury/pnpm-lock.yaml` modification is concurrent-work fallout, not this rung's). Spec folded: DoD [x] (+ the
as-built `usePagedList` note in Scope In); roadmap → BUILT ✓; the `admin.md` ladder row bolded. NEXT: `/cm-ship
admin.5.2` (master-detail, ruled Arm C — triad authored BUILD-GRADE) · admin.5.3 authors its triad at build time
(ruled phased) · the prod `@fastify/static` same-origin serve (the standing `apps/admin` follow-up, deploy-
gated). [[P-4]] [[P-5]] [[P-6]] [[D-6]] [[L-1]]

## {codemojex-admin-learnings} Learnings

### L-1

L — the SPA-vs-island precedent split (codemojex-node frontend craft). A standalone `@codemojex` console (economy, dashboard) is an SPA: `index.html` → `src/main.tsx` `createRoot`, `@mercury/ui`+`@mercury/effector` source aliases (THREE `../` to `mercury/packages`; two resolve into `codemojex/packages`), default `dist/` build — the `economy` app is the structural template. `@codemojex/game` is NOT that template: it is a library-mount island (`src/index.tsx` exports `mount(el,props,bridge)`, React bundled, content-hashed `game-[hash].js`, dynamic-imported by a Phoenix hook). Mirror `economy` for a console's skeleton; mirror `game` ONLY for its `channel/model.ts` (`createChannel` + `sample`) pubsub pattern. Applied on admin.5 (dashboard Shell): the Director brief named `game` as the template; the reconcile corrected it to economy-for-skeleton / game-for-channel. Fold into venus-cm/mars-cm frontend briefs.
