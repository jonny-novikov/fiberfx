# cmt.4.1 — acceptance stories (Given / When / Then)

> Derived from [`./cmt.4.1.md`] (authoritative). Each story is a Connextra user story + concrete
> Given/When/Then acceptance + the invariant(s) it exercises. The Coverage line maps every Deliverable
> `cmt.4.1-D#` → its story. Names are grounded in the as-built island tree
> (`mercury/codemojex/apps/game/`) + the F1-ratified read-only reference (`node/codemoji-design/`:
> `tokens/tokens.mjs`, `stories/i18n/i18n.ts`, `stories/board/BoardScreen.tsx`). **The forks are RULED
> (2026-07-02)** — R-classic + F-cmt41-1/2/3, recorded in the body header — and the acceptance below
> encodes the ruled arms.

## US1 — Tailwind v4 in the island build

*As the island developer, I want Tailwind v4 compiled into the game's Vite build, so that the utility
classes the cmt.4.2 Classic board components use resolve without a separate build step or a new artifact
the host must load.*

- **Given** `vite.config.ts` has `plugins:[react()]`, aliases `@`/`@mercury/effector`, builds the lib
  `game-[hash].js` into `echo/apps/codemojex/priv/static/game` (`manifest:true`, `target:es2024`), and the
  game carries no Tailwind,
- **When** `@tailwindcss/vite` is added to `plugins` (beside `react()`) and `tailwindcss` +
  `@tailwindcss/vite` are added to the game's own `devDependencies` (explicit `^` specifiers, not
  `catalog:`),
- **Then** `pnpm --filter @codemojex/game build` emits **one** `game-[hash].js` (+ its manifest) into the
  echo priv path; the emitted JS carries the compiled game CSS (per the ruled delivery); no second file
  the host must load.
- **encodes cmt.4.1-INV2, cmt.4.1-INV7**.

## US2 — the token `@theme`

*As the island developer, I want the design tokens ported verbatim into a Tailwind v4 `@theme`, so that
`text-primary` / `text-2xs` / `bg-card` and the rest resolve to the exact values the Classic board
components expect.*

- **Given** `node/codemoji-design/tokens/tokens.mjs` is the token source of truth (the base palette incl.
  `primary` `oklch(0 0 0)` / `primary-foreground` `oklch(1 0 0)` / `card` `oklch(1 0 0)`; `literalColors`
  incl. `bg-app-from` `hsl(196, 48%, 94%)` / `bg-app-to` `hsl(203, 32%, 76%)`; `textScale['2xs']
  = 0.625rem`; `fontSans = 'Noto Sans Mono', monospace`; the action + accent tokens),
- **When** `src/styles/theme.css` ports those values verbatim into a `@theme` block (`--color-*` /
  `--text-*` / `--font-*`) + the `[data-theme]` accent blocks (the ruled F-cmt41-2 Arm A), EXCLUDING
  asset-backed values (deferred with the golden rung),
- **Then** `text-primary` resolves to black, `text-2xs` to `0.625rem`, `bg-card` to white; **no** value is
  invented (each traces to `tokens.mjs`); no asset-backed token appears in `theme.css`.
- **encodes cmt.4.1-INV2, cmt.4.1-INV3**.

## US3 — the Classic board tokens ride the artifact

*As the island developer, I want the board tokens — the bg-app gradient pair + card/primary/2xs — to
resolve and ride the emitted artifact, so that the cmt.4.2 `BoardScreen` composition paints its "All
Screen Fill" gradient and floats its cards on day one.*

- **Given** the `BoardScreen` reference paints its root `linear-gradient(180deg,
  var(--color-bg-app-from), var(--color-bg-app-to))` and floats `bg-card` surfaces on it, and `tokens.mjs`
  carries `bg-app-from` / `bg-app-to` / `card` verbatim,
- **When** the `@theme` port (US2) lands and `pnpm --filter @codemojex/game build` emits the artifact,
- **Then** a grep of the emitted `game-[hash].js` finds the ported `--color-bg-app-from` token AND a
  compiled smoke-used utility rule (the `text-2xs` / `bg-card` rule); the smoke's gradient element paints,
  Operator-observed via the hot-load loop.
- **encodes cmt.4.1-INV2, cmt.4.1-INV3**.

## US4 — the `cn` util

*As the island developer, I want a `cn` util (`clsx` + `tailwind-merge`), so that the smoke and the
cmt.4.2 board composition compose conditional and conflicting Tailwind classes through one merge point
(`import { cn } from '@/lib/cn'`).*

- **Given** the game has no `src/lib` and no class-merge util,
- **When** `src/lib/cn.ts` exports `cn(...inputs: ClassValue[]) = twMerge(clsx(inputs))` and `clsx` +
  `tailwind-merge` are added to the game's `dependencies`,
- **Then** `@/lib/cn` is importable and typechecks; a vitest assert shows `cn('p-2', cond && 'hidden',
  'p-4')` collapses conflicting utilities (last-wins) — proving both libs are wired.
- **encodes cmt.4.1-INV3, cmt.4.1-INV7**.

## US5 — react-i18next init + bundled ru/en

*As the island developer, I want react-i18next initialized with bundled ru/en and `useSuspense:false`, so
that the board components' `useTranslation()`/`t(...)` calls (cmt.4.2) return real strings synchronously
with no Suspense boundary and no fetch.*

- **Given** `stories/i18n/i18n.ts` (reference) inits `initReactI18next` with bundled `ru`/`en`,
  `supportedLngs:['ru','en']`, `fallbackLng:'ru'`, `defaultNS:'translation'`,
  `interpolation:{escapeValue:false}`, `react:{useSuspense:false}`, behind an `if (!i18n.isInitialized)`
  guard,
- **When** `src/i18n/i18n.ts` ports that shape and `react-i18next` + `i18next` are added to
  `dependencies`, with the ruled minimal `smoke.*` ru/en seed (F-cmt41-3 Arm A — the full
  `board.*`/`game.*` namespaces land with the cmt.4.2 components),
- **Then** `t('smoke.ping')` returns the bundled ru (or en) string (≠ the raw key) synchronously in a
  vitest render; `react-i18next` resolves against React 19 (no cross-major).
- **encodes cmt.4.1-INV3, cmt.4.1-INV5, cmt.4.1-INV7**.

## US6 — the CSS delivery (the crux, ruled)

*As the edge-deploy / the host LiveView page, I want the game's Tailwind CSS delivered inside the single
dynamic-imported ESM bundle and scoped, so that one artifact still self-contains the island AND mounting
it does not restyle the host page.*

- **Given** the bundle is one self-contained ESM `game-[hash].js` dynamic-imported by the `GameIsland`
  hook into a LiveView page, and cmt.4.1 makes **no** echo/ edit,
- **When** the ruled F-cmt41-1 arm delivers the CSS — `theme.css` imported `?inline` and injected ONCE as
  a `<style>` from the module graph at `mount()`, preflight skipped, everything scoped under the
  `.cmjx-game` root class,
- **Then** the emitted `game-[hash].js` is a **single** artifact carrying the compiled CSS (no second file
  the host loads, INV2); a grep of the delivered artifact shows the `.cmjx-game` root marker and **no**
  document-scope preflight reset (INV4); no echo/ file changes.
- **encodes cmt.4.1-INV2, cmt.4.1-INV4**.

## US7 — the self-contained ESM bundle holds

*As the `mount` contract consumer (the `GameIsland` hook), I want the island's outward contract and
self-containment unchanged, so that adding the DS foundation breaks neither the dynamic-import boot nor the
cmt.3 state layer.*

- **Given** `src/index.tsx` exports `mount(el, props, bridge) → { update, unmount }` + `export { GameEdge }`
  and renders the live game by default — as-built the `LiveMount` facade (commit `1c99cfa6`) renders the
  model-driven `BridgeGame`, which composes `GameEdge` internally (the cmt.3 Phase-A composition, one level
  deeper; Phase B deferred to `/codemojex-ship`),
- **When** cmt.4.1's rung-attributable additions to `index.tsx` are the theme import/inject + an
  off-by-default smoke branch (grafted onto the concurrent hot-loading entry), and it leaves
  `src/channel/*`, `GameEdge.tsx`, `types.ts`, `@mercury/effector` untouched,
- **Then** the `mount` signature + `export { GameEdge }` are byte-stable; with the smoke flag off `mount`
  renders the default game path (`BridgeGame` composing `GameEdge`); `pnpm --filter @codemojex/game
  typecheck && build && test` is green
  and the cmt.3 suites (`GameEdge.test.tsx`, `channel/model.test.ts`) stay green; no `@codemoji/design`
  import, no bare unbundled external in the artifact.
- **encodes cmt.4.1-INV1, cmt.4.1-INV2, cmt.4.1-INV6**.

## US8 — the smoke proves the stack

*As the Operator, I want a dev-flagged smoke that renders a token-styled, `t()`-driven element, so that the
whole foundation is proven working before any board component exists — on evidence, not a claim.*

- **Given** the foundation (Tailwind + the `@theme` + `cn` + i18n + the delivery) is landed and the
  default mount renders the game path (`BridgeGame` composing `GameEdge`),
- **When** `src/GameSmoke.tsx` (a minimal probe mirroring the `BoardScreen` idiom — the `.cmjx-game`
  root, the screen-fill gradient `linear-gradient(180deg, var(--color-bg-app-from),
  var(--color-bg-app-to))`, a `bg-card p-4` surface, `text-2xs`/`text-primary`, `cn`, `useTranslation`)
  is rendered by `index.tsx` **only** under the explicit `VITE_GAME_SMOKE` dev flag (off by default),
- **Then** a vitest render asserts `GameSmoke` mounts, `t('smoke.ping')` returns a bundled string, `cn()`
  merges, and the `className` carries `bg-card`/`text-2xs`/`text-primary`; the build grep confirms the
  compiled smoke-used rule + the ported bg-app token in the artifact; with the flag off the default path
  is the live game (`BridgeGame` composing `GameEdge`, INV1); the live pixel (classes resolve, the gradient
  paints, the host un-clobbered) is Operator-observed.
- **encodes cmt.4.1-INV1, cmt.4.1-INV3, cmt.4.1-INV4**.

## Coverage

| Deliverable | Story |
|---|---|
| cmt.4.1-D1 — Tailwind v4 in the build | US1 |
| cmt.4.1-D2 — the token `@theme` | US2, US3 |
| cmt.4.1-D3 — the `cn` util | US4 |
| cmt.4.1-D4 — react-i18next + seed locales | US5 |
| cmt.4.1-D5 — the CSS delivery | US6 |
| cmt.4.1-D6 — the self-contained ESM bundle holds | US7 |
| cmt.4.1-D7 — the smoke | US8 |

Every `cmt.4.1-INV#` is exercised: INV1 (US7/US8), INV2 (US1/US2/US3/US6/US7), INV3 (US2/US3/US4/US5/US8),
INV4 (US6/US8), INV5 (US5), INV6 (US7), INV7 (US1/US4/US5).
