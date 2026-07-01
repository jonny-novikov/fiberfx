# admin.5 · agent brief

Write-ready: the surface below is pre-mapped so the build's first actions are **writes**, not a read-to-understand
phase. Everything under `mercury/codemojex/apps/dashboard/` is NEW (greenfield). Ground every symbol in the shapes
carried here or the two named precedents; invent no export, prop, route, or column. Framing (propagate into any
sub-brief): no gendered pronouns for agents; no perceptual / interior-state verbs; no first-person narration.

## References
Read first (cap: these three — the rest is carried inline):
- The rung body — [`admin.5.md`](./admin.5.md) — the authoritative Deliverables + Invariants + Forks.
- The stories — [`admin.5.stories.md`](./admin.5.stories.md) — the acceptance.
- The **SPA precedent to copy** — `mercury/codemojex/apps/economy/` (`package.json`, `vite.config.ts`,
  `tsconfig.json`, `index.html`, `src/main.tsx`, `src/components/SplitLadderTable.tsx`). The dashboard mirrors this
  app's shape; the shapes are carried below, so a re-read is optional.

Carried inline (do NOT re-read — the shapes are here):
- **The admin API contract** (`@codemojex/admin`, admin.1, shipped): `GET /games` → `GameSummary[]`; all data
  routes behind `Authorization: Bearer $ADMIN_TOKEN`; `/health` open. The **public** `GameSummary` (secret-free,
  from `apps/admin/src/schemas.ts`): `id: string` (GAM), `roomId: string | null` (ROM), `status: string`,
  `free: boolean`, `guessFee: number | string`, `prizePool: number | string`, `endsMs: number | null`,
  `insertedAt: string` (ISO), `roomName?: string | null`. **No `secret`, no `cell_codes`, no `keyboard`.**
- **`@mercury/ui` exports** (resolved; compose, do not re-house): data-display `Table` (+ `type Column`) ·
  `DataList` · `Stat` · `Card` · `Badge` · `Tag` · `Chip` · `ListRow` · `Code` · `Kbd`; navigation `Tabs` ·
  `TabNav` · `Pagination` · `Menubar`; inputs `Search` · `Select` · `Input` · `Label`; feedback `Alert` ·
  `Callout` · `Spinner` · `Skeleton`; layout `AuthLayout` · `Collapsible` · `ScrollArea` · `AspectRatio`; + `cx`.
  **No operator `AppShell`** — that is fork admin.5-F1.
- **`@mercury/effector` exports** (resolved): `theme` (`initTheme` / `setTheme`) · `toast` · `form` · `strength` ·
  `cooldown` · `formatter` · `channel` (`createChannel` / `type ChannelLike`) · `disclosure`.
- The channel-pattern precedent (read-only, for admin.7 — NOT built now): `mercury/codemojex/apps/game/src/channel/
  model.ts` (`createChannel` + `sample`) + `PhoenixGame.tsx` (a `Socket` bound to the model).
- Approach — [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md).

## Requirements
- **admin.5-R1** — scaffold `mercury/codemojex/apps/dashboard/` as a Vite + React SPA mirroring `economy`:
  `package.json` (`@codemojex/dashboard`, `type: module`, deps `@mercury/ui` + `@mercury/effector` `workspace:*`,
  `react`/`react-dom` `^19`, `effector`/`effector-react` `^23`; dev `@vitejs/plugin-react` + `vite` + `typescript`
  + `@types/react`/`@types/react-dom`; scripts `dev`/`build`/`preview`/`typecheck: tsc --noEmit`), `vite.config.ts`
  (`react()` + aliases), `tsconfig.json` (extends `../../../tsconfig.base.json` + paths), `index.html` →
  `src/main.tsx`. [US: admin.5-US1]
- **admin.5-R2** — the `@mercury/*` source aliases in `vite.config.ts` AND `tsconfig.json`, **THREE `../`** to
  `mercury/packages` (two resolve into `codemojex/packages` — the economy trap): `@mercury/ui` →
  `../../../packages/mercury-ui/src/index.ts`, `@mercury/effector` → `../../../packages/mercury-effector/src/index.ts`,
  `@` → `./src`. [US: admin.5-US1]
- **admin.5-R3** — `src/App.tsx`: an operator shell frame — sidebar (rooms / games / players nav) + topbar (title
  + a connection/health indicator) + a content region — composed **locally** from existing `@mercury/ui` pieces
  (`Card` / `Tabs` / `ScrollArea` / `Menubar`), per the ruled **admin.5-F1 → Arm B**: no new `@mercury/ui`
  primitive, the barrel untouched. [US: admin.5-US2]
- **admin.5-R4** — `src/types.ts`: the public read-plane shapes (`GameSummary` above; `RoomSummary` /
  `PlayerSummary` stubs for admin.6), **no `secret` / `cell_codes` field**. [US: admin.5-US4]
- **admin.5-R5** — `src/api/client.ts`: an `@mercury/effector`-style model — a `createEffect` calling
  `fetch(\`${base}/games\`, { headers: { Authorization: \`Bearer ${token}\` } })` with `base = import.meta.env.
  VITE_ADMIN_API_BASE ?? ""` and `token = import.meta.env.VITE_ADMIN_TOKEN` (never a literal); the reply lands in
  `$games = createStore<GameSummary[]>([])`. Add `.env.example` with `VITE_ADMIN_TOKEN=` + `VITE_ADMIN_API_BASE=`
  (ruled admin.5-F2 → same-origin, blank base; the R8 dev proxy forwards the call in dev). [US: admin.5-US3]
- **admin.5-R6** — `src/views/GamesView.tsx`: `const games = useUnit($games)` → a `@mercury/ui` `<Table>` (the
  `economy/src/components/SplitLadderTable.tsx` pattern) of id / room / status / prize / counts. No `fetch` in the
  view; no `secret` / `cell_codes` column. [US: admin.5-US4, admin.5-US5]
- **admin.5-R7** — from `mercury/codemojex`: `pnpm install`; `pnpm --filter @codemojex/dashboard typecheck` exits
  0; `pnpm --filter @codemojex/dashboard build` produces the bundle; the `@mercury/ui` resolved export set is
  unchanged. [US: admin.5-US6]
- **admin.5-R8** — `vite.config.ts` `server.proxy` (ruled admin.5-F2, dev): forward the admin read routes
  (`/games`, `/rooms`, `/players`, `/health`) to the admin service's local origin (a dev target — confirm the
  admin `PORT` from `apps/admin/src/env.ts`), so the same-origin `VITE_ADMIN_API_BASE=""` client reads the live
  gated API in dev. [US: admin.5-US4]

## Execution topology
Runtime:
```
config: VITE_ADMIN_TOKEN, VITE_ADMIN_API_BASE="" (ruled F2 -> same-origin; dev: vite server.proxy -> admin service)
      |
  api/client.ts  --createEffect--> fetch(`${base}/games`, { Authorization: `Bearer ${token}` })
      |                                    |   @codemojex/admin (admin.1): preHandler bearer gate -> GameSummary[] (secret-free)
      v  .doneData                         v
  $games : Store<GameSummary[]>  <---------+
      |
  views/GamesView.tsx  --useUnit($games)--> <Table columns rows>  (@mercury/ui — no fetch in the view)
      |
  App.tsx shell: sidebar + topbar + <ScrollArea> content     <-- RULED F1 -> Arm B: local compose (Card/Tabs/ScrollArea/Menubar), no new primitive
      |
  main.tsx: initTheme() (@mercury/effector) + createRoot(#root).render(<StrictMode><App/></StrictMode>)

  [two-clock seam, admin.7 — NOT built now] channel model (createChannel, the game pattern) --sample--> $games
```
Tasks (build-order DAG):
```
R1 skeleton ─┬─> R2 aliases ─┬─> R5 client.ts ─┬─> R6 GamesView ─> R7 typecheck + build
             │               │                 │
R4 types.ts ─┘               R3 App.tsx (local, F1->B) ──┘ (mounts GamesView in the content region)
```
Touched files (ALL NEW, under `mercury/codemojex/apps/dashboard/`): `package.json`, `vite.config.ts`,
`tsconfig.json`, `index.html`, `.env.example`, `src/main.tsx`, `src/App.tsx`, `src/types.ts`, `src/api/client.ts`,
`src/views/GamesView.tsx`, `src/dashboard.css`. Read-only precedents: `apps/economy/**` (SPA shape),
`apps/game/src/channel/**` (admin.7 seam). **No edit** to `apps/admin`, `packages/*`, or `echo/`.

## Write-ready sketches (copy + adapt; the survival kit)
`vite.config.ts` (mirror `economy/vite.config.ts` — THREE `../`):
```ts
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";
export default defineConfig({
  plugins: [react()],
  resolve: { alias: {
    "@": resolve(__dirname, "./src"),
    "@mercury/ui": resolve(__dirname, "../../../packages/mercury-ui/src/index.ts"),
    "@mercury/effector": resolve(__dirname, "../../../packages/mercury-effector/src/index.ts"),
  }},
  // ruled admin.5-F2 (dev): same-origin base; proxy the admin read plane to the admin service (confirm the PORT).
  server: { proxy: Object.fromEntries(
    ["/games", "/rooms", "/players", "/health"].map((p) => [p, process.env.VITE_ADMIN_PROXY_TARGET ?? "http://localhost:3000"]),
  ) },
});
```
`src/main.tsx` (mirror `economy/src/main.tsx`):
```tsx
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { initTheme, setTheme } from "@mercury/effector";
import { App } from "./App";
import "./dashboard.css";
if (typeof localStorage !== "undefined" && !localStorage.getItem("mercury-theme")) setTheme("dark");
initTheme();
createRoot(document.getElementById("root")!).render(<StrictMode><App /></StrictMode>);
```
`src/api/client.ts` (the effector store seam — admin.5-D5/INV4):
```ts
import { createEffect, createStore } from "effector";
import type { GameSummary } from "@/types";
const base = (import.meta.env.VITE_ADMIN_API_BASE as string) ?? "";
const token = import.meta.env.VITE_ADMIN_TOKEN as string;      // from config — never a literal
const auth = () => ({ Authorization: `Bearer ${token}` });
export const fetchGamesFx = createEffect<void, GameSummary[]>(async () => {
  const res = await fetch(`${base}/games`, { headers: auth() });
  if (!res.ok) throw new Error(`admin /games ${res.status}`);
  return (await res.json()) as GameSummary[];
});
export const $games = createStore<GameSummary[]>([]).on(fetchGamesFx.doneData, (_s, g) => g);
// admin.7 seats a @mercury/effector `channel` model here and `sample`s into $games — no view rewrite.
```
`src/views/GamesView.tsx` (mirror `economy/src/components/SplitLadderTable.tsx` — `useUnit` a store → `Table`):
```tsx
import { useUnit } from "effector-react";
import { Card, Table } from "@mercury/ui";
import type { Column } from "@mercury/ui";
import { $games } from "@/api/client";
import type { GameSummary } from "@/types";
export function GamesView() {
  const games = useUnit($games);        // no fetch here — the store is the seam
  const cols: Column<GameSummary>[] = [/* id, roomName, status, prizePool, ... public only */];
  return <Card><Table columns={cols} rows={games} /></Card>;   // verify Table's real prop names at the .tsx
}
```
> The `<Table>` prop names (`columns`/`rows` vs `data`) and the `Column` shape: confirm at
> `mercury/packages/mercury-ui/src/components/data-display/Table/Table.tsx` (or the economy call site) — the one
> `.tsx` the build reads to fix the render API.

## Agent stories
- **admin.5-AS1** [implements admin.5-US1] — Directive: scaffold the SPA skeleton mirroring `economy` (R1 + R2).
  Acceptance gate: postcondition — `pnpm --filter @codemojex/dashboard typecheck` resolves the `@mercury/*`
  aliases; invariant — index.html → main.tsx `createRoot` (an SPA, not the game's `mount()` island).
- **admin.5-AS2** [implements admin.5-US2] — Directive: render the operator shell frame **locally** from
  `@mercury/ui` pieces (`Card` / `Tabs` / `ScrollArea` / `Menubar`) — ruled admin.5-F1 → Arm B, no new primitive.
  Acceptance gate: postcondition — sidebar + topbar + content render; invariant — the `@mercury/ui` resolved
  export set is unchanged (barrel-diff, 0 removed/renamed).
- **admin.5-AS3** [implements admin.5-US3] — Directive: write the Bearer effector client (R5) + `src/types.ts`
  (R4). Acceptance gate: postcondition — the request header equals `Bearer ${VITE_ADMIN_TOKEN}`; invariant — no
  `"Bearer "` string literal in `src/`; `$games` is an effector store (not component state).
- **admin.5-AS4** [implements admin.5-US4] — Directive: render the games DB view live (R6). Acceptance gate:
  precondition — a reachable gated admin API; postcondition — `GamesView` lists live rows through the store;
  invariant — no `secret` / `cell_codes` field on `src/types.ts` or in any view.
- **admin.5-AS5** [implements admin.5-US5] — Directive: keep the data layer a store the channel can later target.
  Acceptance gate: invariant — no `fetch(` in `src/views/`; a view reads `$games` via `useUnit`; the seam is
  documented in `client.ts`. (Build no channel — admin.7.)
- **admin.5-AS6** [implements admin.5-US6] — Directive: gate green. Acceptance gate: postcondition — `typecheck`
  exit 0 + `build` produces a bundle; invariant — the barrel holds.

## The forks (RULED by the Operator — Wave 2; kept with their arms as decision-context)
- **admin.5-F1 — the `@mercury/ui` shell primitive. → RULED: Arm B (compose locally).** The shell frame is
  composed in `apps/dashboard` from `Card` / `Tabs` / `ScrollArea` / `Menubar` — no new `@mercury/ui` primitive,
  the barrel untouched, the build a cm-ship Duo; the shared `AppShell` extraction is ruled-deferred to a later
  `/mercury-ship` rung (rule of three).
  - *Rationale.* The shell needs an app frame (sidebar + topbar + content); the barrel's layout group is
    `AuthLayout` / `Collapsible` / `ScrollArea` / `AspectRatio` — no operator `AppShell` (verified in
    `mercury/packages/mercury-ui/src/index.ts`).
  - *5W.* Who — the dashboard + any future operator console · What — an `AppShell` (± `Sidebar` / `Topbar`) ·
    When — now, the Shell needs a frame · Where — `@mercury/ui/layout` (reusable) vs `apps/dashboard/src` (local) ·
    Why — reuse across consoles vs locality + a smaller blast radius.
  - *Steelman.* **Arm A (add `@mercury/ui` `AppShell`)** — every future operator console inherits one frame; the
    design system owns the operator-chrome vocabulary; it is the right home for a reusable primitive. **Arm B
    (compose locally from `Card`/`Tabs`/`ScrollArea`/`Menubar`)** — the Shell stays a cm-ship Duo inside
    `apps/dashboard`; no barrel change, no `/mercury-ship` rung, no HIGH-risk Squad; the frame is proven once
    before it is extracted (rule of three).
  - *Steward.* Lean **Arm B** for admin.5: it keeps the barrel invariant trivially held and the build a Duo, and
    the operator-chrome pattern earns extraction only after a second console (admin.6+) proves it — then a
    `/mercury-ship mx.N` rung lifts `AppShell` into `@mercury/ui`. Arm A now forces a barrel-additive
    `/mercury-ship` rung + makes this build HIGH-risk (Squad) for a single-consumer primitive.
- **admin.5-F2 — the API-origin / delivery seam. → RULED: Arm A (same-origin) + a Vite dev proxy.**
  `VITE_ADMIN_API_BASE=""` (same-origin, token never crosses an origin); this rung wires the Vite `server.proxy`
  to the admin service so admin.5-D4 reads live in dev; the prod admin-Fastify `@fastify/static` serve is a named
  follow-up on `apps/admin` (deploy-gated, after the Shell `dist/` exists).
  - *Rationale.* How the built `dist/` bundle reaches the admin service, and how the Bearer credential is supplied
    without baking the raw operator token into browser-readable JS (`VITE_ADMIN_TOKEN` in a bundle is world-readable).
  - *5W.* Who — the operator's browser + the `@codemojex/admin` Fastify service · What — the bundle's origin + the
    token's home · When — before a prod serve (dev works on any arm) · Where — the admin Fastify, a Vite proxy, or
    a separate static origin · Why — a same-origin path removes CORS + keeps the token off the wire.
  - *Steelman.* **Arm A — same-origin serve** (the `game_bundle_controller` precedent; `echo/docs/codemojex/
    frontend-delivery.design.md` §3c): the admin Fastify serves the built console (via `@fastify/static`) and the
    SPA calls the same-origin API — no CORS, and the token can be a server-injected header, so the browser need
    not hold the raw secret. **Arm B — Vite dev proxy**: `server.proxy` forwards `/api` → the admin service in
    dev; smallest surface, best DX; a prod-serve answer is still owed (composes with A as the dev overlay).
    **Arm C — CORS + a configured base URL**: the console ships as a separate static origin (the `economy`
    static-serve shape) reading `VITE_ADMIN_API_BASE`; the admin service enables CORS; decoupled, but the raw
    token then lives in the browser (exposure) unless an operator enters it at runtime.
  - *Steward.* Lean **Arm A same-origin** (admin Fastify serving its own console) as the prod home — one origin,
    no CORS, the token off the wire — with **Arm B** as the dev-time overlay. Note Arm A on the **echo/ Phoenix**
    app (the literal game-bundle twin) is possible but couples operator tooling to the player app; the admin
    Fastify is the natural home. This fork also sets `VITE_ADMIN_API_BASE` (`""` for same-origin vs a URL).
- **admin.5-F3 — the future-pubsub seam. → RULED: confirmed.** The live slot seats on the existing
  `@mercury/effector` `channel` adapter; the Shell adds no channel and no new effector API — the only obligation
  is the `$games` store seam (admin.5-D5 / admin.5-INV4).
  - *Rationale.* Confirm the live-data slot seats on the **existing** `@mercury/effector` `channel` adapter, so
    admin.7 adds live data with no Shell rewrite; surface any additive effector-API need now.
  - *5W.* Who — admin.7 · What — a `channel` model over the Shell's stores · When — admin.7 (not now) · Where —
    `apps/dashboard/src/channel` (app-local, the `game` pattern) · Why — the two-clock seam.
  - *Steelman / finding.* The `game/src/channel/model.ts` builds its model **in the app** on `createChannel`
    (from `@mercury/effector`) — the adapter is shipped and sufficient; a channel model `sample`s into an existing
    store. So honoring the seam needs **no additive `@mercury/effector` API now**; the only Shell obligation is the
    store shape (admin.5-D5 / admin.5-INV4).
  - *Steward.* **Confirm the seam, build no channel in the Shell.** If the Operator wants the channel model
    pre-seated for admin.7, that is an explicit scope-add (still app-local, still no effector-API change).

## Comprehensive implementation prompt
```
Build admin.5 — the dashboard Shell — as a NEW app at mercury/codemojex/apps/dashboard/ ONLY. It is a Vite +
React SPA (index.html -> src/main.tsx createRoot), mirroring mercury/codemojex/apps/economy — NOT the game app's
library-mount mount() island. The forks are RULED (Wave 2): F1 -> compose the shell LOCALLY from @mercury/ui
Card/Tabs/ScrollArea/Menubar (no new @mercury/ui primitive, barrel untouched); F2 -> same-origin
VITE_ADMIN_API_BASE="" + a vite server.proxy to the admin service in dev (the prod @fastify/static serve is a
separate follow-up on apps/admin); F3 -> no channel, keep the $games store seam.

1. Scaffold (copy economy's shape): package.json (@codemojex/dashboard, type module, deps @mercury/ui +
   @mercury/effector workspace:*, react/react-dom ^19, effector/effector-react ^23; scripts dev/build/preview/
   typecheck), vite.config.ts (react() + THREE ../ aliases for @mercury/ui + @mercury/effector + @ -> ./src),
   tsconfig.json (extends ../../../tsconfig.base.json + the same paths), index.html -> src/main.tsx, .env.example
   (VITE_ADMIN_TOKEN=, VITE_ADMIN_API_BASE= blank/same-origin). Add a vite server.proxy forwarding
   /games,/rooms,/players,/health to the admin service in dev (ruled F2; confirm the admin PORT from apps/admin/src/env.ts).
2. src/main.tsx: initTheme() from @mercury/effector + createRoot(#root).render(<StrictMode><App/></StrictMode>).
3. src/types.ts: the public GameSummary (id, roomId, status, free, guessFee, prizePool, endsMs, insertedAt,
   roomName) — NO secret / cell_codes field. RoomSummary / PlayerSummary stubs for admin.6.
4. src/api/client.ts: createEffect fetch(`${base}/games`, { Authorization: `Bearer ${token}` }) with base/token
   from import.meta.env (never a literal); $games = createStore<GameSummary[]>([]).on(fetchGamesFx.doneData, ...).
   Document the admin.7 channel seam in a comment. No fetch outside this file.
5. src/App.tsx: ruled F1 -> Arm B, compose LOCALLY — a sidebar (rooms/games/players nav) + topbar + <ScrollArea>
   content from @mercury/ui Card/Tabs/ScrollArea/Menubar (NO new @mercury/ui primitive); mount <GamesView/> in the
   content region.
6. src/views/GamesView.tsx: useUnit($games) -> <Table> (the economy SplitLadderTable pattern); public columns
   only. Confirm Table's real prop names at mercury/packages/mercury-ui/src/components/data-display/Table/Table.tsx.
7. Gate, from mercury/codemojex: pnpm install; pnpm --filter @codemojex/dashboard typecheck (exit 0);
   pnpm --filter @codemojex/dashboard build (bundle produced); grep -rE '"Bearer ' src/  -> 0 literal-token hits;
   the @mercury/ui resolved export set unchanged.

Ground every symbol in admin.5.md / the carried shapes / the economy precedent. Invent no export, prop, route, or
column. Boundary: apps/dashboard only — no packages/* edit, no apps/admin edit, no echo/ edit. Report the gate
output verbatim. Framing: no gendered pronouns for agents; no perceptual/interior-state verbs; no first-person.
```

Stories: [`admin.5.stories.md`](./admin.5.stories.md) · Spec: [`admin.5.md`](./admin.5.md) · Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
