# admin.5 · stories

## admin.5-US1
As an operator, I want a `@codemojex/dashboard` console app in the workspace, so that the admin read plane has a
browser surface instead of only `curl`.

**Acceptance criteria.**
- **Given** the `mercury/codemojex` workspace, **when** `mercury/codemojex/apps/dashboard/` is scaffolded as a
  Vite + React SPA mirroring the `economy` app (index.html → `src/main.tsx` `createRoot`, a default `dist/`
  build), **then** it is a member of the workspace and `pnpm --filter @codemojex/dashboard` resolves it.
- **Given** the app's `vite.config.ts` and `tsconfig.json`, **when** they alias `@mercury/ui` and
  `@mercury/effector` to `mercury/packages/*/src` with THREE `../`, **then** the app composes those packages from
  source (no prebuild), exactly as `economy` does.

INVEST: independent of the read wiring; verifiable by the workspace resolving the app; encodes admin.5-INV5.
Priority: must · Size: S · Implements deliverables: admin.5-D1.

## admin.5-US2
As an operator, I want a shell layout — a sidebar, a topbar, and a content region — so that I have a stable frame
to browse rooms, games, and players from.

**Acceptance criteria.**
- **Given** the running app, **when** it renders, **then** `src/App.tsx` shows a sidebar (a rooms / games /
  players nav), a topbar (a title + a connection/health indicator), and a content region composed from
  `@mercury/ui`.
- **Given** the shell is built, **when** the `@mercury/ui` barrel export set is resolved before and after this
  rung, **then** it is unchanged (0 removed / renamed) and the dashboard houses no reusable component of its own.

INVEST: independent of the client; verifiable by a render + the barrel-diff; encodes admin.5-INV3.
Priority: must · Size: M · Implements deliverables: admin.5-D2.

## admin.5-US3
As an operator, I want the console to reach the admin API only through my Bearer credential, supplied by config,
so that the control plane is never opened by a token baked into the shipped bundle.

**Acceptance criteria.**
- **Given** the API client, **when** it issues a request, **then** it attaches `Authorization: Bearer <token>`
  with `token` read from config (`import.meta.env.VITE_ADMIN_TOKEN`), and no `Bearer <literal>` string appears
  anywhere in `src/`.
- **Given** the client model, **when** it fetches `GET /games`, **then** the reply lands in an `@mercury/effector`
  store (`$games`), not component-local state.

INVEST: independent of the view; verifiable by a grep + a client unit; encodes admin.5-INV1, admin.5-INV4.
Priority: must · Size: M · Implements deliverables: admin.5-D3.

## admin.5-US4
As an operator, I want one live DB view — the games list — so that I can see real games from the database in the
console and confirm no secret leaks to the browser.

**Acceptance criteria.**
- **Given** a reachable, gated admin API, **when** the games view mounts, **then** it renders the `$games` store
  as a `@mercury/ui` `Table` / `DataList` of live rows (id, room, status, prize, counts) end to end (config →
  Bearer fetch → store → render).
- **Given** any rendered game row, **when** its fields are inspected, **then** no `secret` and no `cell_codes`
  key is present — `src/types.ts` declares only public columns and no view reads a secret field.

INVEST: independent management-side; verifiable against a live game + a type/grep check; encodes admin.5-INV2.
Priority: must · Size: M · Implements deliverables: admin.5-D4.

## admin.5-US5
As the architect of admin.6/admin.7, I want the Shell's data layer shaped as an effector store, so that the live
pubsub channel plugs into the same store later with no rewrite of the views.

**Acceptance criteria.**
- **Given** the client model, **when** a view needs data, **then** it reads an `@mercury/effector` store via
  `useUnit` and there is no `fetch(` inside any `src/views/` component.
- **Given** the two-clock seam, **when** admin.7 later adds a `@mercury/effector` `channel` model (the
  `game/src/channel/model.ts` pattern), **then** it can `sample` into the same store — the Shell builds no channel
  but leaves the seam documented.

INVEST: independent; verifiable by a grep + the store-shape review; encodes admin.5-INV4.
Priority: should · Size: S · Implements deliverables: admin.5-D5.

## admin.5-US6
As the Director, I want the dashboard app typechecked and built green, so that admin.5 ships on a compiling,
composing foundation and not an unverified scaffold.

**Acceptance criteria.**
- **Given** a clean `mercury/codemojex`, **when** `pnpm install` then `pnpm --filter @codemojex/dashboard
  typecheck` run, **then** the typecheck exits 0.
- **Given** the built app, **when** `pnpm --filter @codemojex/dashboard build` runs, **then** it produces the SPA
  bundle, composing `@mercury/*` from source via the aliases.

INVEST: independent of behaviour; verifiable by the command exit codes; encodes admin.5-INV5.
Priority: must · Size: S · Implements deliverables: admin.5-D6.

Coverage: D1→US1 · D2→US2 · D3→US3 · D4→US4 · D5→US5 · D6→US6 · INV1→US3 · INV2→US4 · INV3→US2 · INV4→US3,US5 · INV5→US1,US6.  Spec: admin.5.md · Agent brief: admin.5.llms.md.
