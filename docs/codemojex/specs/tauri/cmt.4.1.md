# cmt.4.1 — the game DS + i18n foundation (the body)

> **Track:** codemojex Tauri (`cmt.N`) · **AAW scope:** `cm-tauri` · **Risk:** MED · **Depends:** cmt.3.
> Canon: [`./tauri.design.md`] · [`./tauri.specs.md`] · program [`../../program/codemojex.program.md`].
> The `.md` **body is authoritative**; [`./cmt.4.1.stories.md`] (acceptance) and [`./cmt.4.1.llms.md`] (build
> brief) derive from it. **DESIGN/SPEC ONLY** — no production code ships from this doc.
>
> **Status: BUILT — Director-verified 2026-07-02** (mars-cmt41-1). Gates green — `pnpm --filter
> @codemojex/game typecheck && build && test`, 35/35; the artifact probes pass (the smoke branch is folded
> out of the default bundle — `VITE_GAME_SMOKE` statically `"0"` in the emitted JS, the smoke component
> shaken; the i18n init + locales ride via the side-effect import chain). The pixel proof remains **OWED**
> — Operator-observed via the cmt.2 hot-load loop.
>
> **[RECONCILE] — the Operator SPLIT cmt.4 at Bootstrap, then re-aimed the split Classic-first
> (R-classic, 2026-07-02).** cmt.4 is split: **cmt.4.1 = the DS/i18n FOUNDATION only** (this rung);
> **cmt.4.2 = the Classic `BoardScreen` composition + the `GameProps`→board mapping that replaces the
> plain `GameEdge` internals** — the Classic board is `node/codemoji-design/stories/board/BoardScreen.tsx`
> (the "Game (Free)" board, Figma 94:2974); **cmt.4.3 = the Classic finished-state/events**. The GOLDEN
> variant — the golden screen, the gold texture, the boost surface — DEFERS to a later golden rung.
> cmt.4.1 lays the stack the Classic board stands on and **proves it in isolation** — it renders **no**
> game screen, only a dev-flagged **smoke** (mirroring the `BoardScreen` idiom) proving Tailwind
> resolves, the ported tokens ride the artifact, `cn` merges, and `t()` returns a bundled locale string.
> **F3** (the diamonds/clips/keys/boost data gap, `tauri.design.md` §3/§5) stays a **cmt.4.2** concern —
> cmt.4.1 renders **no balances**. The golden-oriented v1 deliverable cut of this body (D1..D8, incl. a
> gold-texture deliverable) was re-aimed Classic-first by the Operator's ruling and renumbered D1..D7.
>
> **[RECONCILE] — the ladder canon lags the split + the re-aim.** [`./tauri.specs.md`] §cmt.4 +
> [`./tauri.design.md`] §4 still list a **monolithic, golden-first cmt.4** — a STALE the Director/Operator
> syncs to the Classic re-sequence (cmt.4.2 = the Classic board · cmt.4.3 = the Classic
> finished-state/events · the golden variant later; out of this triad's 3-file scope; flagged, not edited
> here — the Director syncs those entries at this ship, in progress).
>
> **Forks RULED (2026-07-02) — the record.** The v1 body framed three forks OPEN; the Operator ruled:
>
> - **R-classic — the master ruling (2026-07-02).** Classic Free/Paid games ship first. "Free/Paid" is
>   the existing `view.free` / `view.guess_fee` distinction already carried by `GameProps`
>   (`src/types.ts`) — no new flow. cmt.4.1 = the foundation; cmt.4.2 = the Classic `BoardScreen`
>   composition + the `GameProps`→board mapping; the Classic finished-state/events follow (cmt.4.3); the
>   GOLDEN variant + the gold texture + the boost surface land on a later golden rung.
> - **F-cmt41-1 — RESOLVED BY THE PIVOT (2026-07-02).** The texture half is MOOT — deferred whole with
>   the golden rung (no `gold.png`, no `--gold-texture`, no placeholder swatch; the asset-backed token
>   leaves this rung entirely). The CSS half is RULED **Arm A**: Tailwind CSS imported `?inline` and
>   injected ONCE as a `<style>` from the module graph at `mount()`; preflight SKIPPED; everything scoped
>   under the root class — **renamed `.cmjx-golden` → `.cmjx-game`** (a Director-ratified rename, a pivot
>   consequence).
> - **F-cmt41-2 — RULED Arm A (2026-07-02).** One `src/styles/theme.css` `@theme` port of `tokens.mjs`,
>   values verbatim — EXCEPT asset-backed values (`gold.texture`), which are excluded (deferred with the
>   golden rung). The plain hex gold COLOR tokens may stay when ported as part of the verbatim base set;
>   the `--gold-texture` var + the `@utility bg-gold-texture` are OUT.
> - **F-cmt41-3 — RULED Arm A (2026-07-02).** A minimal `smoke.*` ru/en seed now; the full
>   `board.*`/`game.*` namespaces land with the cmt.4.2 components.
> - **F3 posture — unchanged.** `GameProps` carries no balances (`diamonds`/`clips`/`keys`) and no boost;
>   `me` is a bare PLR string; nothing is fabricated. The Classic `InfoDashboard` balance cells are a
>   cmt.4.2 omit/neutralize concern; the server `game_props` extension is a deferred `/codemojex-ship`
>   rung.

## Goal

Wire the game design-system foundation into `@codemojex/game` so the Classic board (cmt.4.2) has a
resolving stack, and **prove the stack in isolation** with a dev-flagged smoke — WITHOUT rendering any
game screen or touching the live game. Six pieces land inside `@codemojex/game`: **Tailwind v4**
(`@tailwindcss/vite`) in the island's Vite build; the **token `@theme`** ported verbatim from
`node/codemoji-design/tokens/tokens.mjs` (the base palette · the type scale · the font · the bg-app
gradient pair · the card/action/accent tokens; asset-backed values excluded); the **`cn`** util (`clsx` +
`tailwind-merge`) at `src/lib/cn.ts`; **react-i18next** init (bundled ru/en, `useSuspense:false`) ported
from `node/codemoji-design/stories/i18n/i18n.ts`; the **CSS delivery** (the ruled F-cmt41-1 arm —
Tailwind CSS `?inline`, injected once as a `<style>` at `mount()`, preflight skipped, scoped under the
`.cmjx-game` root — a single self-contained artifact, no echo/ edit); and a **smoke** (`GameSmoke`,
dev-flagged) that renders a token-styled, `t()`-driven element mirroring the `BoardScreen` idiom —
exercising every layer. The `mount(el,props,bridge)` contract, the self-contained ESM bundle, and the
cmt.3 channel layer stay intact.

## Rationale (5W)

- **Why.** The Classic `BoardScreen` + its components (cmt.4.2) depend on a stack the island does **not**
  have today: Tailwind v4, the `@theme` tokens (`text-primary`/`text-2xs`/`bg-card`/the bg-app gradient
  pair), the `cn` util, react-i18next, and a way to deliver Tailwind CSS into a single dynamic-imported
  ESM bundle. Landing that foundation as a thin, provable rung — and proving it with a smoke before any
  board component exists — de-risks cmt.4.2 and isolates the **delivery** mechanism (F-cmt41-1, now
  ruled) from the component-mapping work.
- **Who.** The island developer building cmt.4.2 (the Classic board) on this foundation; the Operator,
  whose R-classic ruling fixed the target.
- **What.** Tailwind v4 + the token `@theme` (asset-backed values excluded) + `cn` + react-i18next + the
  ruled CSS-delivery mechanism + a dev-flagged smoke — all inside `@codemojex/game`.
- **Where.** Primary edit `mercury/codemojex/apps/game/**` only. **No `echo/` edit** — cmt.4.1 needs none
  (all six pieces live in the island); an echo/ change forks OUT to `/codemojex-ship`. No other app; the
  four BCS libs and `@mercury/*` are untouched (the island resolves `@mercury/effector` from source via
  the existing alias, unchanged here).
- **When.** After cmt.3 (the Effector channel state layer is shipped). **The forks are RULED**
  (R-classic + F-cmt41-1/2/3, 2026-07-02, recorded above) — the build is unblocked; no ruling gate
  remains before build.

## Scope

**In**

- **Tailwind v4 in the island build** — add `@tailwindcss/vite` to `vite.config.ts` `plugins` (beside
  `react()`); add `tailwindcss` + `@tailwindcss/vite` to the game's own `devDependencies`.
- **The token `@theme`** — a `src/styles/theme.css` (Tailwind v4 CSS-first) carrying a `@theme` block
  that ports `tokens.mjs` verbatim (the base palette → `--color-*`, incl. `primary`/`card`;
  `literalColors` → `--color-*`, incl. the bg-app gradient pair `--color-bg-app-from`/`--color-bg-app-to`;
  `textScale` → `--text-*`; `fontSans` → `--font-*`; the action tokens; `accentThemes` → `[data-theme]`
  blocks) — **asset-backed values excluded** (the F-cmt41-2 ruling). The values are copied verbatim from
  `tokens.mjs` (NO-INVENT — it is the token source of truth).
- **The `cn` util** — `src/lib/cn.ts` = `twMerge(clsx(inputs))`; add `clsx` + `tailwind-merge` to the
  game's `dependencies`. (The smoke — and the cmt.4.2 board composition after it — import `cn` from
  `@/lib/cn`.)
- **react-i18next** — `src/i18n/i18n.ts` ported from the reference (init `initReactI18next`, bundled
  `ru`/`en`, `supportedLngs:['ru','en']`, `fallbackLng:'ru'`, `useSuspense:false`, the `isInitialized`
  guard); add `react-i18next` + `i18next` to `dependencies`; the ruled minimal `smoke.*` ru/en seed
  (F-cmt41-3 — the full `board.*`/`game.*` namespaces land with the cmt.4.2 components).
- **The CSS delivery** (the ruled F-cmt41-1 arm) — Tailwind CSS imported `?inline` and injected ONCE as a
  `<style>` from the module graph at `mount()`; preflight SKIPPED; everything scoped under the
  `.cmjx-game` root class — one self-contained artifact, no host-page clobber, no echo/ edit.
- **The smoke** — `src/GameSmoke.tsx`, a minimal dev-flagged probe mirroring the `BoardScreen` idiom (the
  `.cmjx-game` root; the board's screen-fill paint `linear-gradient(180deg, var(--color-bg-app-from),
  var(--color-bg-app-to))`; a `bg-card`-style surface; `text-2xs`/`text-primary`; `cn`;
  `t('smoke.ping')`) that index.tsx renders **only** when a dev flag is set (off by default); a vitest
  render assertion + the build/emitted-JS grep prove the stack.

**Out**

- **The golden screen + the gold texture + the boost surface** — the whole GOLDEN variant defers to a
  later golden rung (R-classic); no `gold.png`, no `--gold-texture`, no placeholder swatch in this rung.
- **All Classic board COMPONENTS + the `BoardScreen` composition** and the `GameProps`→board mapping that
  replaces the plain `GameEdge` internals (**cmt.4.2**); the Classic finished-state/events (**cmt.4.3**).
  cmt.4.1 renders no game screen — only the smoke.
- **The F3 data gap** (diamonds/clips/keys/boost) and any `game_props`/balance surface — cmt.4.2; cmt.4.1
  renders no balances.
- **Any `echo/` edit** — including the second-file CSS path (the F-cmt41-1 Arm B shape, which forks to
  `/codemojex-ship`).
- **Any change to the cmt.3 channel layer** (`src/channel/*`), `GameEdge.tsx`, `types.ts`, or the
  `@mercury/effector` package; the default `mount` render path (with the smoke flag off) stays the live
  game (as-built: `BridgeGame` composing `GameEdge` — the cmt.3 Phase-A composition, one level deeper).
- **The mercury catalog** — the new deps are explicit version specifiers in the game's own `package.json`,
  not `catalog:` (the codemojex sub-workspace is not on the mercury catalog; that is mx.10's deferred
  concern).

## Deliverables

- **cmt.4.1-D1 — Tailwind v4 in the island build.** `vite.config.ts` `plugins` gains `@tailwindcss/vite`
  (beside `react()`); `tailwindcss` + `@tailwindcss/vite` added to the game's `devDependencies`. The lib
  build (`game-[hash].js` into `echo/apps/codemojex/priv/static/game`, `manifest:true`, `target:es2024`) is
  otherwise unchanged.
- **cmt.4.1-D2 — the token `@theme` (`src/styles/theme.css`).** A Tailwind v4 CSS-first entry porting
  `tokens.mjs` verbatim: `@theme` with `--color-*` (the base palette, incl. `primary` `oklch(0 0 0)` /
  `primary-foreground` `oklch(1 0 0)` / `card` `oklch(1 0 0)`; the `literalColors` set, incl. the bg-app
  gradient pair `--color-bg-app-from: hsl(196, 48%, 94%)` / `--color-bg-app-to: hsl(203, 32%, 76%)` — the
  exact vars the `BoardScreen` root gradient consumes), `--text-2xs: 0.625rem` (+ the type scale),
  `--font-*` (`'Noto Sans Mono', monospace`), the action tokens (`gradientPurchase`/`enter #0050FF`/
  `control #A8ACB0`), the `accentThemes` `[data-theme]` blocks. **Asset-backed values excluded** per the
  F-cmt41-2 ruling (the texture tokens leave with the golden rung). Shape = the ruled Arm A (one
  `theme.css`). The verbatim port is a SOURCE-level guarantee — the emitted artifact carries the consumed
  subset (the INV3 as-built posture).
- **cmt.4.1-D3 — the `cn` util (`src/lib/cn.ts`).** `export function cn(...inputs: ClassValue[]) { return
  twMerge(clsx(inputs)); }`; `clsx` + `tailwind-merge` added to `dependencies`. Importable as `@/lib/cn`.
- **cmt.4.1-D4 — react-i18next (`src/i18n/i18n.ts`) + seed locales.** Ported from the reference: `i18n.use(
  initReactI18next).init({ resources:{ru,en}, supportedLngs:['ru','en'], fallbackLng:'ru',
  defaultNS:'translation', interpolation:{escapeValue:false}, react:{useSuspense:false} })` behind the
  `if (!i18n.isInitialized)` guard; `react-i18next` + `i18next` added to `dependencies`. The seed is the
  ruled minimal `smoke.*` ru/en set (F-cmt41-3 Arm A); the full `board.*`/`game.*` namespaces port in
  cmt.4.2.
- **cmt.4.1-D5 — the CSS delivery (the ruled F-cmt41-1 arm).** Tailwind CSS imported `?inline` and
  injected ONCE as a `<style>` from the module graph at `mount()`; preflight SKIPPED; everything scoped
  under the `.cmjx-game` root class — ONE self-contained artifact, no echo/ edit, host CSS un-clobbered.
- **cmt.4.1-D6 — the self-contained ESM bundle holds.** `pnpm --filter @codemojex/game build` still emits a
  **single** `game-[hash].js` (+ its Vite manifest) into `echo/apps/codemojex/priv/static/game`; the `mount`
  export + the `export { GameEdge }` are intact; no `@codemoji/design` import; no bare unbundled external;
  the game CSS is **delivered** (per D5), not dropped.
- **cmt.4.1-D7 — the smoke (`src/GameSmoke.tsx`, dev-flagged).** A minimal probe rendered by `index.tsx`
  only when the `VITE_GAME_SMOKE` dev flag is set (off by default), mirroring the `BoardScreen` idiom —
  the `.cmjx-game` root; an element painting the board's screen fill (`linear-gradient(180deg,
  var(--color-bg-app-from), var(--color-bg-app-to))`); a `bg-card p-4` surface; `text-2xs`/`text-primary`;
  `cn()` in use — proving: Tailwind classes apply, the ported tokens ride, `cn()` merges, and
  `t('smoke.ping')` returns a bundled ru/en string — WITHOUT wiring the live game.

## Invariants (each a runnable check — a no-op must fail it)

- **cmt.4.1-INV1 — the `mount` contract holds; the default path is the live game.** `src/index.tsx` keeps
  `mount(el, props, bridge) → { update, unmount }` and `export { GameEdge }` byte-stable in signature; with
  the smoke flag **off** (the default) `mount` renders the model-driven `BridgeGame` — which composes
  `GameEdge` internally (the cmt.3 Phase-A composition unchanged, one level deeper); the smoke branch is
  off by default. The rung-attributable `index.tsx` additions are the theme inject (D5) + the
  off-by-default smoke branch (D7), grafted onto the concurrent hot-loading entry (the `LiveMount` facade,
  commit `1c99cfa6` — the build brief's Grounded facts carry the as-built shape).
  *Check:* `grep "export function mount"` + `grep "export { GameEdge }"` present; a typecheck-level assert
  the render default (flag unset) is the game path. *No-op fails:* a changed signature, a lost `GameEdge`
  export, or the smoke on by default.
- **cmt.4.1-INV2 — the self-contained bundle holds.** `pnpm --filter @codemojex/game build` emits exactly
  one `game-[hash].js` into `echo/apps/codemojex/priv/static/game`; a grep of the emitted JS finds **no**
  `@codemoji/design` import, **no** bare unbundled external, and (per D5) the compiled game CSS **is
  present** in the artifact (the smoke-used utility rules + the ported token values ride inside the JS, not
  a dropped/second file the host must load). *No-op fails:* a missing `mount`, a second required CSS/asset
  file the host must serve, or Tailwind CSS absent from the artifact.
- **cmt.4.1-INV3 — the stack resolves (the smoke proves it).** A vitest (jsdom) render of `GameSmoke`
  asserts: it renders without throwing; `t('smoke.ping')` returns the bundled string (≠ the raw key — i18n
  initialized); `cn('a', false && 'b', 'a')` de-dupes/merges (clsx+tailwind-merge wired); the rendered
  `className` carries the Classic set — `bg-card`/`text-2xs`/`text-primary`. The **build** gate greps the
  emitted JS for a compiled smoke-used utility rule (the `text-2xs` / `bg-card` rule) AND the ported
  bg-app token (`--color-bg-app-from`, carrying its `tokens.mjs` value) — Tailwind compiled the `@theme`
  and the tokens ride the artifact. **Verification posture (honest):** jsdom computes no Tailwind pixels
  and no browser runs in the island — the pixel proof (classes resolve visually, the bg-app gradient
  paints) is **Operator-observed** via the cmt.2 hot-load loop (the game's Vite dev server in the shell).
  *No-op fails:* `t()` returns the key, `cn` is a passthrough, or the emitted JS lacks the compiled rule /
  the ported token.
  **As-built posture (2026-07-02):** tailwindcss 4.3.2 emits used-only theme variables — the artifact
  carries the smoke-consumed subset (incl. the bg-app pair, tracked via the `var()` references in scanned
  source); the unconsumed remainder of the verbatim port (the chart-*/sidebar-* sets, the F-cmt41-2
  plain-hex set, the actions, the h1..h6 scale) prunes from the artifact until cmt.4.2 lands consumers.
  The `theme.css` SOURCE carries the full verbatim port; `@theme static` is the one-line flip if full
  emission is ever wanted.
- **cmt.4.1-INV4 — the host page is not clobbered (the ruled F-cmt41-1 collision-avoidance).** The
  injected styles are scoped so mounting the smoke does not restyle the host LiveView page
  (welcome/lobby/game shell): the injected/emitted CSS rides under the `.cmjx-game` root scope and carries
  **no** document-scope preflight reset (no bare `*,::before,::after { … }` at `:root`/document scope).
  *Check:* a grep of the delivered artifact asserts the `.cmjx-game` root marker + the absence of a global
  preflight selector; the live host render is Operator-observed. *No-op fails:* a global Tailwind preflight
  leaks onto the host.
- **cmt.4.1-INV5 — React 19.2.7, one copy.** The island owns its runtime (React bundled); the game
  (`react ^19.2.7`) and the design reference (`node/codemoji-design`, 19.2.7) share the major;
  `react-i18next` resolves against React 19 (no cross-major). *Check:* `react`/`react-dom` stay `^19.2.7`;
  the build carries one React copy. *No-op fails:* a second React or a cross-major i18next peer.
- **cmt.4.1-INV6 — scope held.** The diff touches **only** `mercury/codemojex/apps/game/**` + this rung's
  `docs/codemojex/specs/tauri/` triad; **no** `echo/` edit; **no** other app; `src/channel/*`,
  `GameEdge.tsx`, `types.ts`, and the `@mercury/effector` package are unchanged; the cmt.3 suites
  (`GameEdge.test.tsx`, `channel/model.test.ts`) stay green. *No-op fails:* an echo/ edit, a channel-layer
  edit, or a red cmt.3 test.
- **cmt.4.1-INV7 — the new deps land in the game's own `package.json`, versioned (not `catalog:`).**
  `tailwindcss` + `@tailwindcss/vite` (devDeps), `react-i18next` + `i18next` + `clsx` + `tailwind-merge`
  (deps) are explicit `^`-version specifiers in `mercury/codemojex/apps/game/package.json`; the mercury
  catalog is untouched. *Check:* `grep` the six specifiers in the game's package.json; `git diff` shows no
  `mercury/pnpm-workspace.yaml`/catalog change. *No-op fails:* a `catalog:` reference or a dep placed in a
  package other than the game.

## Definition of Done

- **The forks are RULED and folded** (R-classic · F-cmt41-1 · F-cmt41-2 · F-cmt41-3 · the F3 posture —
  2026-07-02, recorded in the header): the texture + golden surface left the rung; the CSS delivery, the
  token-port shape, and the i18n seed are fixed. The build is unblocked — no ruling gate remains.
- **cmt.4.1-INV1..7 pass.** Gate (from `mercury/codemojex/`): `pnpm install`; `pnpm --filter @codemojex/game
  typecheck && build && test`; the build emits **one** self-contained `game-[hash].js` (+ manifest) into
  `echo/apps/codemojex/priv/static/game` with the game CSS delivered (INV2) and no
  `@codemoji/design`/bare external; the vitest smoke asserts the stack (INV3); the emitted-JS
  utility/token grep + the host-non-clobber grep pass (INV3/INV4). **Never `pnpm -r`.** Node ≥22, no
  `TMPDIR`.
- **The pixel proof is Operator-observed** — the ported classes resolve, the bg-app gradient paints, and
  the host page is un-clobbered, seen via the cmt.2 hot-load loop (the game's Vite dev server in the
  shell). No id-mint / process / lease / schema surface → **the ≥100 determinism loop is not required**
  (per [`./tauri.specs.md`] § determinism posture); the posture is build + the vitest smoke + the
  emitted-JS grep + the Operator-observed pixel.
- **No `echo/` edit** (INV6); the cmt.3 channel layer + `GameEdge` + the `mount` contract intact
  (INV1/INV6); the Classic board COMPONENTS + the screen + the F3 balances are **cmt.4.2**, not here; the
  golden surface is a later golden rung.
- **Ladder canon STALE flagged** — the monolithic, golden-first cmt.4 entries in
  `tauri.specs.md`/`tauri.design.md` await the Classic re-sequence sync (cmt.4.2 = the Classic board ·
  cmt.4.3 = the Classic finished-state/events · the golden variant later) by the Director/Operator
  (underway at this ship) — out of this triad's scope.
- Commit (Director, when the Operator asks): `mercury/codemojex/apps/game/… + docs/codemojex/specs/tauri/…`
  as one pathspec. No `git add -A`; no push unless asked.
