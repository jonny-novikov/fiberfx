# admin.5 · the dashboard Shell

## Goal
Stand up `@codemojex/dashboard` — the operator console over the admin.1 read plane. A Vite + React SPA in the
`mercury/codemojex` workspace (its SPA skeleton mirroring the `economy` app, its live-data seam mirroring the
`game` app's channel pattern) that composes `@mercury/ui` + `@mercury/effector`, reads the Bearer-gated admin API
through an `@mercury/effector`-style client, and renders an operator **shell layout** plus ONE end-to-end **DB
view** (the games list) against the live gated API. The data layer is a **two-clock seam** — admin HTTP now, the
effector `channel` pubsub later — so the DB-view desks (admin.6) and the live channel (admin.7) grow on it with
no rewrite. It is the frontend floor Milestone B stands on.

## Rationale (5W)
- **Why** — the read plane is proven but faceless: an operator drives it with `curl`. A console turns the gated
  API into an operator UX/DX for the DB view, and the two foundations it needs are shipped — `@mercury/ui` is a
  mature barrel and `@mercury/effector`'s `channel` adapter is the live-feed pattern — so the frontend track is
  the focus now, not an optional afterthought.
- **What** — a `@codemojex/dashboard` SPA skeleton: the app scaffolding (Vite + React + the `@mercury/*` source
  aliases), an operator shell layout composed from `@mercury/ui`, a Bearer admin API client as an
  `@mercury/effector`-style model, and one end-to-end DB view proving the full stack live.
- **Who** — the human operator browsing the running game; `@codemojex/dashboard` is the surface they hold.
- **When** — this rung, the first of Milestone B, before the DB-view desks (admin.6) fan out.
- **Where** — `mercury/codemojex/apps/dashboard/` (new — the greenfield app) composing
  `mercury/packages/{mercury-ui,mercury-effector}` (from source, additive-only); reading the `@codemojex/admin`
  API (`mercury/codemojex/apps/admin`, admin.1); no edit crosses into `echo/`.

## Scope
**In.** The `@codemojex/dashboard` app skeleton (`package.json`, `vite.config.ts`, `tsconfig.json`, `index.html`,
`src/main.tsx`, `src/App.tsx`, `src/types.ts`, `src/vite-env.d.ts`) mirroring the `economy` SPA precedent; the `@mercury/*` source
aliases (vite + tsconfig, THREE `../` to `mercury/packages`); an operator **shell layout** (sidebar + topbar +
content) composed from `@mercury/ui`; the **admin API client** (`src/api/client.ts`) — an `@mercury/effector`-style
model attaching `Authorization: Bearer <token>` (from config) to the read plane, exposing effector stores; ONE
end-to-end **DB view** (`src/views/GamesView.tsx`, the games list) reading `GET /games` live; the app typechecks
and builds.

**Out.** The remaining read desks — rooms / players list + detail, pagination, search (admin.6); the live
Phoenix-channel feed (admin.7 — the seam is shaped now, the channel is NOT built here); any write / management
(admin.2); balances / ledgers (admin.3); moderation (admin.4); a new `@mercury/ui` reusable primitive (a
`/mercury-ship` concern — the ruled-deferred `AppShell` extraction, admin.5-F1); any edit to `@codemojex/db` or
the `echo/` engine; **the prod same-origin serve** — the admin Fastify `@fastify/static` mount of the built
`dist/` (ruled admin.5-F2 → Arm A) is a **named near-term follow-up** (an `apps/admin` edit, deploy-gated, after
the Shell `dist/` exists), NOT this rung's build gate.

## Deliverables
- **admin.5-D1 — the app skeleton.** A `mercury/codemojex/apps/dashboard/` Vite + React **SPA** mirroring the
  `economy` precedent (index.html → `src/main.tsx` `createRoot`, a default `dist/` build — NOT the `game` app's
  library-mount `mount()` island): `package.json` (`@codemojex/dashboard`, `type: module`, `@mercury/ui` +
  `@mercury/effector` `workspace:*` deps + `react`/`react-dom`/`effector`/`effector-react`; scripts
  `dev`/`build`/`preview`/`typecheck`), `vite.config.ts` (`react()` + the `@mercury/ui` + `@mercury/effector`
  source aliases, THREE `../` — two would resolve into `codemojex/packages`, plus a `server.proxy` forwarding the
  admin routes to the admin service in dev — the ruled admin.5-F2 delivery), `tsconfig.json` (extends
  `../../../tsconfig.base.json` + the `@mercury/*` paths), `index.html` → `src/main.tsx` (`createRoot`, wrapped in
  the `@mercury/effector` theme provider).
- **admin.5-D2 — the operator shell layout.** `src/App.tsx` renders an operator frame — a **sidebar** (the
  rooms / games / players nav), a **topbar** (a title + a connection/health indicator), and a **content region**
  — composed **locally** from existing `@mercury/ui` pieces (`Card` / `Tabs` / `ScrollArea` / `Menubar`), per the
  ruled admin.5-F1 → Arm B: **no new `@mercury/ui` primitive**, the barrel untouched. The one DB view mounts in
  the content region. (A shared `AppShell` extraction is ruled-deferred to a later `/mercury-ship` rung.)
- **admin.5-D3 — the Bearer admin API client.** `src/api/client.ts` — an `@mercury/effector`-style model: a
  `createEffect` issuing `fetch(<base>/games, { headers: { Authorization: "Bearer " + token } })`, with `base =
  import.meta.env.VITE_ADMIN_API_BASE` (ruled admin.5-F2 → **same-origin**, `""`) and `token =
  import.meta.env.VITE_ADMIN_TOKEN`, never a source literal; the reply lands in an effector store (`$games`). In
  dev the same-origin call is served by the Vite dev proxy → the admin service; in prod by the admin Fastify
  `@fastify/static` serve (the named follow-up). The client consumes the **public** read-plane shapes
  (`src/types.ts`, secret-free) — it assumes no `secret` / `cell_codes` on any body.
- **admin.5-D4 — one end-to-end DB view.** `src/views/GamesView.tsx` renders the `$games` store as a
  `@mercury/ui` `Table` / `DataList` — id, room, status, prize, ends (from `endsMs`; the public `GameSummary` carries no count field) — proving the full stack
  (config → Bearer fetch → effector store → `@mercury/ui` render) against the live gated `GET /games`. No column
  is a `secret` or `cell_codes` (the games entity is the one that carries server-side secrets, so the games view
  is the secret-strip proof).
- **admin.5-D5 — the two-clock seam (shaped, not wired).** The client model exposes effector **stores** (`$games`
  fed by the HTTP effect), not component-local fetch state, so admin.7 adds a `@mercury/effector` `channel` model
  (the `game/src/channel/model.ts` pattern) that `sample`s the same store — with no rewrite of the view. The
  Shell builds NO channel; it shapes the store seam and documents where the second clock plugs in.
- **admin.5-D6 — green.** `pnpm install` in `mercury/codemojex`; `pnpm --filter @codemojex/dashboard typecheck`
  exits 0; `pnpm --filter @codemojex/dashboard build` produces the SPA bundle; the `@mercury/ui` barrel export
  set is unchanged (0 removed / renamed).

## Invariants
- **admin.5-INV1 — the Bearer gate is the only door.** The client attaches `Authorization: Bearer <token>` to
  every admin-API request, with `token` read from config, never a source literal. Exercised by a grep (no
  `"Bearer "` followed by a string literal in `src/`) plus the client unit asserting the header equals
  `"Bearer " + <the config value>`.
- **admin.5-INV2 — the public schema only.** `src/types.ts` and every view assume no `secret` and no `cell_codes`
  key on any response; the games view renders only public columns. Exercised by a structural type check
  (`src/types.ts` declares no `secret` / `cell_codes` field) plus a grep that no view reads either key.
- **admin.5-INV3 — the barrel holds.** `@mercury/ui`'s resolved export set is unchanged by this rung (0 removed /
  renamed); the Shell composes the barrel and houses no reusable component of its own (the package / app split).
  Exercised by the barrel-diff (the resolved export set) — this rung touches only
  `mercury/codemojex/apps/dashboard`.
- **admin.5-INV4 — the two-clock seam holds.** A view reads its data from an `@mercury/effector` store via
  `useUnit`, never a component-local `fetch` — so an `@mercury/effector` `channel` model can target the same
  store in admin.7 without a view rewrite. Exercised by a grep: no `fetch(` inside a `src/views/` component; the
  view reads `$games` through `useUnit`.
- **admin.5-INV5 — green + composed.** `pnpm --filter @codemojex/dashboard typecheck` exits 0 and `build`
  produces a bundle; the app composes `@mercury/*` from source via the aliases (no re-implemented primitive).
  Exercised by the typecheck + build commands.

## Definition of Done
- [x] admin.5-D1 lands the SPA skeleton mirroring the `economy` precedent; the `@mercury/*` aliases resolve (admin.5-US1).
- [x] admin.5-D2 renders the operator shell layout from `@mercury/ui`; admin.5-INV3 (barrel holds) passes (admin.5-US2).
- [x] admin.5-D3 + admin.5-D4 read the gated API through the Bearer client and render the games DB view — built + wired, the live read served-pending a standing admin service; admin.5-INV1 (Bearer from config) + admin.5-INV2 (no secret) pass (admin.5-US3, admin.5-US4).
- [x] admin.5-D5 + admin.5-INV4: the data layer is an effector store a channel can later target — the two-clock seam holds (admin.5-US5).
- [x] admin.5-D6 + admin.5-INV5: `typecheck` exits 0, `build` produces a bundle, the barrel is unchanged (admin.5-US6).
- [x] The three forks are **ruled** (Wave 2): admin.5-F1 → Arm B (local compose, no barrel touch, cm-ship Duo; `AppShell` extraction ruled-deferred) · admin.5-F2 → Arm A same-origin + a Vite dev proxy (prod `@fastify/static` serve a named follow-up) · admin.5-F3 → confirmed (no channel, no new effector API this rung).
- [x] The six spec gates pass on this triad; the ledger records the close.

## Forks (RULED by the Operator — Wave 2; the framed four-part arms are in `admin.5.llms.md`)
- **admin.5-F1 → Arm B (compose locally).** The operator shell frame is composed **locally in `apps/dashboard`**
  from existing `@mercury/ui` pieces (`Card` / `Tabs` / `ScrollArea` / `Menubar`) — **no new `@mercury/ui`
  primitive this rung**, so the barrel is untouched and the build stays a **cm-ship Duo**. *Rationale:* a shared
  `AppShell` earns extraction only after a second console proves the shape (rule of three) — that extraction is
  the **ruled-deferred** item, a later `/mercury-ship` `mx.N` rung.
- **admin.5-F2 → Arm A (same-origin) + a Vite dev proxy.** The console reads the admin plane **same-origin**
  (`VITE_ADMIN_API_BASE` = `""`), so the Bearer token never crosses an origin in browser JS. *In this rung
  (dev):* `vite.config.ts` `server.proxy` forwards the admin routes to the admin service, so admin.5-D4 reads the
  live gated API. *Prod (a named near-term follow-up, NOT this rung's build gate):* the admin Fastify serves the
  built `dist/` via `@fastify/static` (the game-bundle same-origin precedent, no CORS) — an `apps/admin` edit,
  deploy-gated, sequenced after the Shell `dist/` exists (see Scope **Out**).
- **admin.5-F3 → confirmed.** The live slot seats on the **existing** `@mercury/effector` `channel` adapter (the
  `game/src/channel/model.ts` pattern); the Shell adds **no channel and no new effector API** — the only
  obligation is the `$games` store seam (admin.5-D5 / admin.5-INV4).

Stories: [`admin.5.stories.md`](./admin.5.stories.md) · Agent brief: [`admin.5.llms.md`](./admin.5.llms.md) · Index: [`admin.md`](./admin.md) · Approach: [`../../../aaw/aaw.specs-approach.md`](../../../aaw/aaw.specs-approach.md)
