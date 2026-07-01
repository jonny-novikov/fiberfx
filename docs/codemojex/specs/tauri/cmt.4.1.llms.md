# cmt.4.1 — the build brief (`.llms.md`)

> Derived from [`./cmt.4.1.md`] (authoritative body) + [`./cmt.4.1.stories.md`] (acceptance). cmt.4.1
> lands the **game DS + i18n FOUNDATION** inside `@codemojex/game` and proves it with a **dev-flagged
> smoke** mirroring the Classic `BoardScreen` idiom — no game screen, no echo/ edit. The exact signatures
> + file bodies are carried below so the builder's first actions are **writes**. **Cap reading** to this
> triad + `node/codemoji-design/tokens/tokens.mjs` (for the full palette port; the i18n + `cn` +
> `BoardScreen` shapes are transcribed here). **Boundary:** `mercury/codemojex/apps/game/**` only — no
> `echo/` edit, no other app, no `@mercury/*` change. **Forks RULED (2026-07-02)** (§ Forks — the record)
> — the build is unblocked. **Agents run no git.** Framing: third person; no gendered pronouns for
> agents; no perceptual/interior-state verbs; forward-tense for unbuilt surface; cite the reference /
> `file:line` for every surface, invent nothing.

## References (read these — they are complete)

| Reference (read-only) | Use |
|---|---|
| `node/codemoji-design/tokens/tokens.mjs` | the token **source of truth** — port `base`/`literalColors`/`textScale`/`fontSans`/`actions`/`accentThemes` values **verbatim** into `theme.css` (asset-backed values excluded — § Forks record) |
| `node/codemoji-design/stories/i18n/i18n.ts` | the react-i18next init shape (transcribed below) |
| `node/codemoji-design/stories/board/BoardScreen.tsx` | the Classic idiom the smoke mirrors — the root screen-fill gradient + the `bg-card` float (transcribed below) |
| this triad | the authoritative spec + the write-ready sketches |

Do **not** re-read the island tree — its relevant state is transcribed under Grounded facts. Do **not**
read any other `node/codemoji-design` file (only the three above are in the ratified read set — the
R-classic re-aim swapped the read set's third file to `stories/board/BoardScreen.tsx`) nor any `echo/`
file.

**Grounded facts (NO-INVENT — the island facts probed 2026-07-01; the Classic reference + token facts
probed 2026-07-02):**

- **The island build** (`mercury/codemojex/apps/game/vite.config.ts`): `plugins:[react()]`; `resolve.alias`
  `@`→`./src`, `@mercury/effector`→`../../../packages/mercury-effector/src/index.ts`;
  `dedupe:["effector","effector-react"]`; `build.outDir` → **absolute** `../../../../echo/apps/codemojex/
  priv/static/game`; `emptyOutDir:true`; `manifest:true`; `target:"es2024"`; `rollupOptions.input`
  `./src/index.tsx`; `output` `format:"es"`, `game-[hash].js`. cmt.4.1 adds **only** `@tailwindcss/vite` to
  `plugins`. As-built the file also carries an uncommitted `preserveEntrySignatures: "strict"` from the
  hot-loading track — a rung-adjacent fact riding the same file, load-bearing for the mount contract
  (without it an app-mode Rollup build can drop the entry's named exports); the rung commit includes the
  file whole.
- **The entry, AS-BUILT** (`src/index.tsx` — rewritten by the concurrent game-tauri hot-loading track,
  committed `1c99cfa6` 2026-07-02 02:03, sweeping this rung's grafts aboard; the pre-build "frozen mount"
  fact is superseded): the entry is a `LiveMount` facade — `mount(el, props, bridge)` calls `injectTheme()`
  first (the rung's graft: the `theme.css?inline` string injected once as `<style data-cmjx-game>`), builds
  `live = {el, bridge, props, root, apply}`, and calls an internal `render(live)`. `render()` opens with
  the smoke branch — `if (import.meta.env.VITE_GAME_SMOKE === "1") { live.apply = () => {};
  live.root.render(<GameSmoke />); return; }` — then the DEFAULT path builds `createGameModel()` and
  renders `<BridgeGame model bridge initial={live.props}>` (the model-driven mount; `BridgeGame` composes
  `GameEdge` internally — the cmt.3 Phase-A composition unchanged, one level deeper). `update()` =
  `live.props = p; live.apply(p)`. An `export function remount(live)` + an `import.meta.hot.accept` block
  carry the hot-swap loop (dead code in the library build). `export function mount` + `export { GameEdge }`
  are both intact — the INV1 greps pass as written.
- **The package** (`package.json`): `@codemojex/game`, `type:module`, `engines.node ">=22.12.0"`; deps
  `@echo/phoenix`/`@echo/phoenix_live_view` (`workspace:*`), `effector`/`effector-react` `^23.3.0`, `react`/
  `react-dom` `^19.2.7`; devDeps incl. `@vitejs/plugin-react`, `jsdom`, `typescript ^5.5.4`, `vite ^6`,
  `vitest ^4`, testing-library. **`@mercury/effector` is NOT a package dep — it is alias-only** (vite +
  vitest + tsconfig `paths`). The game has **no** Tailwind/i18n/clsx/css/theme today.
- **Resolved deps (as-built 2026-07-02):** clsx 2.1.1 · tailwind-merge 3.6.0 · i18next 25.10.10 ·
  react-i18next 15.7.4 · tailwindcss 4.3.2 · @tailwindcss/vite 4.3.2; the `package.json` specifiers:
  `^2.1.1` / `^3.0.0` / `^25.0.0` / `^15.2.0` / `^4.1.0` / `^4.1.0`. No peer warnings; one React `^19.2.7`
  (INV5 held).
- **tsconfig.json**: `strict`, `noUnusedLocals`, `noUnusedParameters`, `moduleResolution:"bundler"`,
  **`resolveJsonModule:true`** (so the i18n JSON imports typecheck — no change needed), `jsx:"react-jsx"`,
  `paths` `@/*`+`@mercury/effector`, `include:["src","js"]`. **No `types` field** — a `/// <reference
  types="vite/client" />` in a `src/*.d.ts` is picked up.
- **vitest.config.ts**: `plugins:[react()]`, `environment:"jsdom"`, `globals:true`, `setupFiles:["./test/
  setup.ts"]`, `include:["src/**/*.test.{ts,tsx}"]`, alias `@`+`@mercury/effector`. **A new `src/*.test.tsx`
  is auto-included — no vitest.config change.** Note: vitest carries **no** `@tailwindcss/vite`, so it
  computes **no** Tailwind pixels — the smoke test asserts render + `t()` + `cn()` + the className string,
  never `getComputedStyle`.
- **The cmt.3 layer (untouched targets)**: `src/channel/{model.ts,PhoenixGame.tsx,model.test.ts}`,
  `src/GameEdge.tsx` (imports its own `@/components/*`), `src/types.ts`, `src/GameEdge.test.tsx`,
  `src/vitest.d.ts`, `test/setup.ts`. Keep all byte-unchanged; keep their suites green.
- **The Classic reference** (`node/codemoji-design/stories/board/BoardScreen.tsx`): the root is
  `<div className="font-sans" style={{ background: SCREEN_FILL }}>` with `SCREEN_FILL =
  'linear-gradient(180deg, var(--color-bg-app-from), var(--color-bg-app-to))'` (BoardScreen.tsx:84-89) —
  the board's "All Screen Fill" gradient (Figma 94:2974) on the bg tokens (#E8F3F7 → #AFC7D6); the cards
  float on it as `bg-card rounded-2xl` surfaces (the `BoardCard` idiom, BoardScreen.tsx:104-119); the copy
  runs through `useTranslation` — `t('game.guessTheCode')` (BoardScreen.tsx:108) + `t('board.freeKeyIn',
  { hours: 15 })` (BoardScreen.tsx:135-136), grounding the `board.*`/`game.*` namespaces (cmt.4.2, per the
  F-cmt41-3 ruling); the `InfoDashboard` composition consumes `keys`/`timeLeft`/`prizeUsd`/`diamonds`/…
  sample props (BoardScreen.tsx:94-102) — the F3 omit/neutralize surface for cmt.4.2.
- **Must-have token values** (from `tokens.mjs`, for the smoke + the Classic idiom): `primary`
  `oklch(0 0 0)` (tokens.mjs:32) / `primary-foreground` `oklch(1 0 0)` (tokens.mjs:33) / `card`
  `oklch(1 0 0)` (tokens.mjs:24); the bg-app gradient pair — `literalColors['bg-app-from']` =
  `hsl(196, 48%, 94%)` (#E8F3F7, tokens.mjs:86) + `literalColors['bg-app-to']` = `hsl(203, 32%, 76%)`
  (#AFC7D6, tokens.mjs:87) — landing as `--color-bg-app-from`/`--color-bg-app-to`, the exact vars the
  `BoardScreen` root consumes (BoardScreen.tsx:84); `textScale['2xs']` `0.625rem` (tokens.mjs:103);
  `fontSans` `'Noto Sans Mono', monospace` (tokens.mjs:113); actions `linear-gradient(90deg,#FF8800
  0%,#FF4800 100%)`/`#0050FF`/`#A8ACB0` (tokens.mjs:165-170); accents orange `#FF8400`, blue `#0050FF`,
  green `#00D95F` (tokens.mjs:122-124). **Port the full `base`/`literalColors`/`textScale` sets from
  `tokens.mjs` verbatim** — the above are the proven subset. The sole asset-backed value (`gold.texture`,
  tokens.mjs:146) is **EXCLUDED** per the F-cmt41-2 ruling.

## Requirements (each traced `[US:]`)

- **R1 — Tailwind v4 in the build.** `[US1]` Add `@tailwindcss/vite` to `vite.config.ts` `plugins`; add
  `tailwindcss` + `@tailwindcss/vite` (v4) to the game's `devDependencies`. → INV2, INV7.
- **R2 — the token `@theme`.** `[US2, US3]` `src/styles/theme.css` ports `tokens.mjs` verbatim into a
  `@theme` block (+ the `[data-theme]` accent blocks), EXCLUDING asset-backed values (§ Forks record); the
  bg-app pair + `card` + `primary` + `--text-2xs` ride the port. → INV2, INV3.
- **R3 — the `cn` util.** `[US4]` `src/lib/cn.ts` = `twMerge(clsx(inputs))`; add `clsx` + `tailwind-merge`
  to `dependencies`. → INV3, INV7.
- **R4 — react-i18next + seed.** `[US5]` `src/i18n/i18n.ts` (the transcribed init) + the ruled minimal
  `smoke.*` ru/en seed (F-cmt41-3); add `react-i18next` (React-19-compatible) + `i18next` to
  `dependencies`. → INV3, INV5, INV7.
- **R5 — the CSS delivery.** `[US6]` The ruled F-cmt41-1 arm: `theme.css` imported `?inline` + a one-time
  `<style>` inject from `mount()`; preflight skipped; the `.cmjx-game` scope root — one self-contained
  artifact, no echo/ edit, host un-clobbered. → INV2, INV4.
- **R6 — the self-contained bundle holds.** `[US7]` `index.tsx` gains **only** the rung-attributable theme
  import/inject + an off-by-default smoke branch (as-built: grafted onto the concurrent `LiveMount` entry —
  Grounded facts); the `mount` signature + `export { GameEdge }` are byte-stable and the default path stays
  the live game (`BridgeGame` composing `GameEdge`); `channel/*`/`GameEdge.tsx`/`types.ts`/
  `@mercury/effector` untouched. → INV1, INV2, INV6.
- **R7 — the smoke.** `[US8]` `src/GameSmoke.tsx` (dev-flagged, mirrors the `BoardScreen` idiom) +
  `src/GameSmoke.test.tsx` (the vitest render assertion). → INV1, INV3, INV4.

## Execution topology

**One zone** — `@codemojex/game` (the island). No echo/ zone, no `@mercury/*` zone. The bundle stays a
single dynamic-imported ESM `game-[hash].js`; the Tailwind CSS rides **inside** it (the ruled F-cmt41-1
arm).

**Build-order DAG (two write-ready waves).**
1. **Wave A — the foundation** (no `index.tsx` touch, no build-graph risk): the `@tailwindcss/vite` plugin +
   deps · `src/styles/theme.css` (port `tokens.mjs` verbatim, EXCLUDING asset-backed values; **skip
   preflight**) · `src/lib/cn.ts` · `src/i18n/i18n.ts` + the seed locales · `src/vite-env.d.ts`. Gate:
   `pnpm install`; `pnpm --filter @codemojex/game typecheck` green.
2. **Wave B — the delivery + the smoke**: `index.tsx` (the `?inline` theme inject + the off-by-default
   `VITE_GAME_SMOKE` smoke branch) · `src/GameSmoke.tsx` · `src/GameSmoke.test.tsx`. Gate: `pnpm --filter
   @codemojex/game build` (one self-contained artifact; the emitted-JS utility/token + no-preflight +
   no-`@codemoji/design` greps) + `test` (the smoke + the cmt.3 suites green).

**Exact files**

| File | Change | Wave |
|---|---|---|
| `mercury/codemojex/apps/game/package.json` | +4 deps (`clsx`, `tailwind-merge`, `i18next`, `react-i18next`) + 2 devDeps (`tailwindcss`, `@tailwindcss/vite`) — `^` specifiers, **not** `catalog:` | A |
| `mercury/codemojex/apps/game/vite.config.ts` | + `import tailwindcss from "@tailwindcss/vite"` + `tailwindcss()` in `plugins` | A |
| `mercury/codemojex/apps/game/src/styles/theme.css` | **new** — the `@theme` port (port `tokens.mjs` verbatim, EXCLUDING asset-backed values; skip preflight) | A |
| `mercury/codemojex/apps/game/src/lib/cn.ts` | **new** — the `cn` util | A |
| `mercury/codemojex/apps/game/src/i18n/i18n.ts` | **new** — the init | A |
| `mercury/codemojex/apps/game/src/i18n/locales/ru/translation.json` | **new** — seed `{"smoke":{"ping":"пинг"}}` | A |
| `mercury/codemojex/apps/game/src/i18n/locales/en/translation.json` | **new** — seed `{"smoke":{"ping":"ping"}}` | A |
| `mercury/codemojex/apps/game/src/vite-env.d.ts` | **pre-existed** (landed with `1c99cfa6`, the required content verbatim — `/// <reference types="vite/client" />`, typing `*.css?inline` + `import.meta.env`) — no rung write | A |
| `mercury/codemojex/apps/game/src/index.tsx` | + the theme `?inline` inject + an off-by-default smoke branch (signature/default byte-stable; as-built grafted onto the concurrent `LiveMount` entry — Grounded facts) | B |
| `mercury/codemojex/apps/game/src/GameSmoke.tsx` | **new** — the dev-flagged probe | B |
| `mercury/codemojex/apps/game/src/GameSmoke.test.tsx` | **new** — the vitest smoke | B |

**Write-ready sketches** (adapt to the resolved dep versions; the shapes are load-bearing):

- **`src/lib/cn.ts`:**
  ```ts
  import { clsx, type ClassValue } from "clsx";
  import { twMerge } from "tailwind-merge";
  export function cn(...inputs: ClassValue[]): string {
    return twMerge(clsx(inputs));
  }
  ```
- **`src/i18n/i18n.ts`** (the reference shape, minimal seed):
  ```ts
  import i18n from "i18next";
  import { initReactI18next } from "react-i18next";
  import en from "./locales/en/translation.json";
  import ru from "./locales/ru/translation.json";

  export const SUPPORTED_LANGUAGES = ["ru", "en"] as const;
  export type Language = (typeof SUPPORTED_LANGUAGES)[number];

  if (!i18n.isInitialized) {
    void i18n.use(initReactI18next).init({
      resources: { ru: { translation: ru }, en: { translation: en } },
      supportedLngs: [...SUPPORTED_LANGUAGES],
      fallbackLng: "ru",
      defaultNS: "translation",
      interpolation: { escapeValue: false },
      react: { useSuspense: false },
    });
  }
  export default i18n;
  ```
- **`src/styles/theme.css`** (Tailwind v4, **preflight skipped** for INV4; port every plain value from
  `tokens.mjs`):
  ```css
  /* game DS theme — values ported verbatim from node/codemoji-design/tokens/tokens.mjs.
     Asset-backed values are EXCLUDED (the F-cmt41-2 ruling; see the spec's Forks record).
     Preflight is intentionally omitted (INV4): no global reset clobbers the host
     LiveView page. */
  @layer theme, components, utilities;
  @import "tailwindcss/theme.css" layer(theme);
  @import "tailwindcss/utilities.css" layer(utilities);

  @theme {
    --color-primary: oklch(0 0 0);
    --color-primary-foreground: oklch(1 0 0);
    --color-card: oklch(1 0 0);
    /* … the rest of tokens.mjs `base` (background/foreground/drawer/accent/border/…) verbatim … */
    --color-bg-app-from: hsl(196, 48%, 94%);
    --color-bg-app-to: hsl(203, 32%, 76%);
    /* … the rest of `literalColors` (bg-from/bg-to/bg-main/success/main-blue/…) verbatim … */
    --text-2xs: 0.625rem;
    /* … the rest of `textScale` (h1..h6, large) … */
    --font-sans: "Noto Sans Mono", monospace;
    /* the `actions` values verbatim; `accentThemes` → the [data-theme] blocks below */
  }
  ```
- **`src/GameSmoke.tsx`** (mirrors the `BoardScreen` idiom; the smoke subtree under `.cmjx-game`):
  ```tsx
  import { useTranslation } from "react-i18next";
  import { cn } from "@/lib/cn";
  import "@/i18n/i18n";

  // The board's "All Screen Fill" — the exact root paint of the Classic BoardScreen
  // (node/codemoji-design/stories/board/BoardScreen.tsx, SCREEN_FILL).
  const SCREEN_FILL =
    "linear-gradient(180deg, var(--color-bg-app-from), var(--color-bg-app-to))";

  export function GameSmoke() {
    const { t } = useTranslation();
    return (
      <div
        className={cn("cmjx-game font-sans overflow-hidden rounded-2xl")}
        style={{ background: SCREEN_FILL }}
      >
        <div className="bg-card p-4 text-primary">
          <span className="text-2xs font-bold">{t("smoke.ping")}</span>
        </div>
      </div>
    );
  }
  ```
- **`src/index.tsx`** (the v1 pre-build sketch, kept as history — **superseded as-built**: the shipped
  entry is the concurrent `LiveMount` facade carrying the same two grafts; Grounded facts):
  ```ts
  import { createRoot, Root } from "react-dom/client";
  import { GameEdge } from "@/GameEdge";
  import { GameSmoke } from "@/GameSmoke";
  import type { GameProps, Bridge } from "@/types";
  import theme from "@/styles/theme.css?inline";

  let styleInjected = false;
  function injectTheme() {
    if (styleInjected || typeof document === "undefined") return;
    const el = document.createElement("style");
    el.dataset.cmjxGame = "";
    el.textContent = theme;
    document.head.appendChild(el);
    styleInjected = true;
  }

  export function mount(el: HTMLElement, props: GameProps, bridge: Bridge) {
    injectTheme();
    const root: Root = createRoot(el);
    const smoke = import.meta.env.VITE_GAME_SMOKE === "1";
    const render = (p: GameProps) =>
      root.render(smoke ? <GameSmoke /> : <GameEdge {...p} bridge={bridge} />);
    render(props);
    return { update: (p: GameProps) => render(p), unmount: () => root.unmount() };
  }
  export { GameEdge };
  ```

## Known snags (carry the fix in — do not rediscover)

1. **Tailwind v4 preflight would clobber the host (INV4).** `@import "tailwindcss"` bundles preflight (a
   global `*,::before,::after` reset). **FIX:** import only the `theme` + `utilities` layers (the sketch
   above); omit preflight. **Verify:** grep the emitted CSS for a document-scope `*,::before,::after` reset
   → **0**. (cmt.4.2 may add a `.cmjx-game`-scoped mini-reset if a component needs it.)
2. **Vite would emit a second CSS file (INV2).** A plain `import "./styles/theme.css"` in a lib build emits
   `game-[hash].css` — a second file the host must load (INV2 fail). **FIX:** import `theme.css?inline` (a
   string) and inject a `<style>` from `mount()` (the sketch). **Verify:** the emitted `game-[hash].js`
   contains a compiled smoke-used utility rule (the `text-2xs` / `bg-card` rule — grep); no `.css` asset is
   required by the host. **Fallback** (only if `?inline` does not carry Tailwind-compiled CSS under Vite 6 +
   `@tailwindcss/vite`): add `vite-plugin-css-injected-by-js` (a devDep) — try `?inline` first (no new dep).
3. **`?inline` + `import.meta.env` TS types.** Under `strict`, `import theme from "…?inline"` and
   `import.meta.env.VITE_GAME_SMOKE` need Vite's client types. **FIX:** add `src/vite-env.d.ts` =
   `/// <reference types="vite/client" />` (declares `*.css?inline` → `string` + `import.meta.env`). No
   `tsconfig.json` edit needed (`resolveJsonModule` already true; the `.d.ts` is under `include:["src"]`).
   As-built: the file pre-existed (landed with `1c99cfa6`) with exactly this content — no write was needed.
4. **react-i18next React-19 peer.** Use a react-i18next major that declares React 19 support (`^15+`);
   `i18next` is framework-agnostic. **Verify:** `pnpm install` raises no unmet-React-peer warning; the game
   keeps one React `^19.2.7` (INV5).
5. **The smoke test cannot compute Tailwind pixels.** vitest carries no `@tailwindcss/vite`, and jsdom
   computes no CSS. **Assert** render + `t('smoke.ping') !== 'smoke.ping'` + `cn('p-2', false && 'x', 'p-4')`
   collapsing to `p-4` + the className carrying `bg-card`/`text-2xs`/`text-primary`. **Do not** assert
   `getComputedStyle`. The pixel is Operator-observed (the hot-load loop).
6. **The bg-app pair must ride the artifact (INV3).** The smoke consumes
   `--color-bg-app-from`/`--color-bg-app-to` via an inline `style` gradient (the `BoardScreen` idiom,
   BoardScreen.tsx:84-89) — not via a scanned utility class — so a Tailwind v4 configuration that emits
   only utility-consumed theme variables could omit the pair from the compiled CSS (the gradient would
   silently not paint). The INV3 emitted-JS grep for `--color-bg-app-from` is the tripwire. **If absent:**
   force full-variable emission (the `@theme static` variant per the installed tailwindcss v4 theme docs —
   verify on the installed version) or give the pair a scanned utility consumer; re-run the grep.
   **As-built resolution (2026-07-02):** not needed — tailwindcss 4.3.2 tracked the pair via the `var()`
   references in scanned source; the INV3 grep passed with used-only emission (the artifact carries the
   smoke-consumed subset; the unconsumed remainder of the verbatim port prunes until cmt.4.2 lands
   consumers; `@theme static` remains the one-line flip for full emission).

## Agent stories

- **AS1 — the foundation (Wave A)** `[implements R1, R2, R3, R4]`. **Directive:** add the `@tailwindcss/vite`
  plugin + the six deps (`^` specifiers in the game's `package.json`, not `catalog:`); write `theme.css`
  (port `tokens.mjs` verbatim, EXCLUDING asset-backed values, **skip preflight**), `cn.ts`, `i18n/i18n.ts`
  + the two seed locales, and `vite-env.d.ts`; `pnpm install`. **Acceptance gate:** `pnpm --filter
  @codemojex/game typecheck` green;
  `grep -E "tailwindcss|@tailwindcss/vite|clsx|tailwind-merge|react-i18next|i18next" package.json` → the six,
  each `^`-versioned; `git diff` shows **no** `mercury/pnpm-workspace.yaml`/catalog change.
- **AS2 — the delivery + the smoke (Wave B)** `[implements R5, R6, R7]`. **Directive:** wire the
  `theme.css?inline` inject + the off-by-default `VITE_GAME_SMOKE` smoke branch in `index.tsx` (signature
  byte-stable; the default path stays the live game); write `GameSmoke.tsx` + `GameSmoke.test.tsx`. **Acceptance gate:**
  `pnpm --filter @codemojex/game build` emits **one** `game-[hash].js` (+ manifest) into
  `echo/apps/codemojex/priv/static/game`; greps of the emitted JS: **no** `@codemoji/design`, **no** bare
  unbundled external, a compiled smoke-used utility rule (the `text-2xs` / `bg-card` rule) **present**, the
  ported `--color-bg-app-from` token **present**, **no** document-scope preflight reset; `pnpm --filter
  @codemojex/game test` green incl. the smoke; `GameEdge.test.tsx` + `channel/model.test.ts` still green;
  `grep "export function mount"` + `grep "export { GameEdge }"` present.

## Forks — RULED (the record, 2026-07-02)

The v1 brief framed three forks OPEN and gated the build on the Operator's ruling. The Operator ruled on
2026-07-02 (R-classic, the master re-aim, plus the three forks); the build is unblocked. The pivot renames
the smoke `GoldenSmoke` → `GameSmoke` and the scope root `.cmjx-golden` → `.cmjx-game`, and swaps the
smoke's mirrored reference from the golden hero (`stories/golden-game/GoldenHero.tsx`) to the Classic
`stories/board/BoardScreen.tsx`. The original arms stay below as history; the rulings are binding.

- **R-classic — the master ruling (2026-07-02).** Classic Free/Paid games ship first. "Free/Paid" is the
  existing `view.free` / `view.guess_fee` distinction already carried by `GameProps` (`src/types.ts`) — no
  new flow. cmt.4.1 = the foundation; cmt.4.2 = the Classic `BoardScreen` composition + the
  `GameProps`→board mapping replacing the plain `GameEdge` internals; the Classic finished-state/events
  follow (cmt.4.3); the GOLDEN variant + the gold texture + the boost surface land on a later golden rung.
- **F-cmt41-1 — the CSS + texture delivery — RESOLVED BY THE PIVOT (2026-07-02).** *The original frame
  (history):* the bundle is one self-contained ESM dynamic-imported into a LiveView page; the rung had to
  add Tailwind CSS + a 1.39 MB gold-texture raster with no echo/ edit, one artifact, no host clobber. The
  arms: **(A)** inline both — `?inline` CSS inject + a data-URI texture; **(B)** co-emit `game-[hash].css`
  + host-serve the raster — an echo/ edit → `/codemojex-ship`; **(C)** a Shadow-DOM mount. The steelman for
  B was the raster: a 1.39 MB texture arguably should ship as a separately-cached edge asset, not
  re-inlined into every JS load. *The ruling:* the texture half is **MOOT** — the pivot defers `gold.png`,
  the `--gold-texture` var, and any placeholder swatch whole with the golden rung; the asset-backed token
  leaves this rung entirely, the raster (`node/codemoji-design/public/assets/gold.png`) becomes the golden
  rung's copy-source concern (superseding the v1 scope-ring note), and with it the texture snag — the
  data-URI-vs-served-asset size trade — leaves the rung too. The CSS half is **RULED Arm A**: Tailwind CSS
  imported `?inline`, injected ONCE as a `<style>` from the module graph at `mount()`; preflight SKIPPED;
  everything scoped under the root class — **renamed `.cmjx-golden` → `.cmjx-game`** (a Director-ratified
  rename, a pivot consequence).
- **F-cmt41-2 — the token-port shape — RULED Arm A (2026-07-02).** *The original frame (history):* **(A)**
  one `src/styles/theme.css` (`@theme` + utilities, imported `?inline`) — the Tailwind-v4 CSS-first idiom
  codemoji-design already uses (`tokens.mjs → theme.css`); **(B)** a split / a JS token object fed to a
  config — more structure, no benefit for a foundation. *The ruling:* **Arm A** — one `theme.css` `@theme`
  port of `tokens.mjs`, values verbatim — EXCEPT asset-backed values (`gold.texture`), which are excluded
  (deferred with the golden rung). The plain hex gold COLOR tokens may stay when ported as part of the
  verbatim base set; the `--gold-texture` var + the `@utility bg-gold-texture` are OUT.
- **F-cmt41-3 — the i18n seed depth — RULED Arm A (2026-07-02).** *The original frame (history):* **(A)** a
  minimal `smoke.*` ru/en seed now, the full namespaces with the components; **(B)** port the full
  namespace now — needs the reference `translation.json` files ratified into the read set, yet cmt.4.1
  renders no component to consume them. *The ruling:* **Arm A** — the minimal `smoke.*` ru/en seed now; the
  full `board.*`/`game.*` namespaces land with the cmt.4.2 components (the `BoardScreen` consumes
  `t('game.guessTheCode')` + `t('board.freeKeyIn')` — the namespaces are real, and they port with the
  components).
- **F3 posture — unchanged by the pivot.** `GameProps` carries no balances (`diamonds`/`clips`/`keys`) and
  no boost; `me` is a bare PLR string; nothing is fabricated. The Classic `InfoDashboard` balance cells
  (the reference composition consumes `keys`/`diamonds`/`prizeUsd`/… sample props, BoardScreen.tsx:94-102)
  are a cmt.4.2 omit/neutralize concern; the server `game_props` extension is a deferred `/codemojex-ship`
  rung.

## Comprehensive prompt (for the builder)

> Land the game DS + i18n **foundation** inside `@codemojex/game` per this brief and the authoritative
> body [`./cmt.4.1.md`], and prove it with a **dev-flagged smoke** — render **no** game screen, make
> **no** `echo/` edit, change **no** `@mercury/*`. The forks are RULED (§ Forks) — build to the ruled
> arms. Build in two waves. **Wave A:** add `@tailwindcss/vite` to `vite.config.ts` `plugins` + the six
> deps (`^` specifiers in the game's own `package.json`, never `catalog:`); write `src/styles/theme.css`
> porting `node/codemoji-design/tokens/tokens.mjs` **verbatim** into a Tailwind-v4 `@theme` (+ the
> `[data-theme]` accent blocks), EXCLUDING asset-backed values (§ Forks record) and **omitting
> preflight** so the host page is not clobbered; write `src/lib/cn.ts` (`twMerge(clsx(inputs))`),
> `src/i18n/i18n.ts` (the transcribed init, `useSuspense:false`, the ruled minimal `smoke.*` ru/en seed)
> + the two `locales/*/translation.json`, and `src/vite-env.d.ts` (`/// <reference types="vite/client"
> />`). **Wave B:** wire the `theme.css?inline` `<style>` inject + an off-by-default `VITE_GAME_SMOKE`
> smoke branch into `src/index.tsx` — keeping the `mount(el,props,bridge)→{update,unmount}` signature,
> `export { GameEdge }`, and the default `GameEdge` render path byte-stable; write `src/GameSmoke.tsx`
> (mirroring the `BoardScreen` idiom — the `.cmjx-game` root, the screen-fill gradient
> `linear-gradient(180deg, var(--color-bg-app-from), var(--color-bg-app-to))`, a `bg-card p-4` surface,
> `text-2xs`/`text-primary`, `cn`, `useTranslation`) + `src/GameSmoke.test.tsx`. Carry the six known
> snags' fixes (skip preflight; `?inline` not a second CSS file; the `vite/client` types; the
> react-i18next React-19 peer; the jsdom-can't-compute-Tailwind smoke posture; the bg-app pair riding the
> artifact). Leave `src/channel/*`, `GameEdge.tsx`, `types.ts`, `@mercury/effector` untouched; keep the
> cmt.3 suites green. **Gates** (from `mercury/codemojex/`, never `pnpm -r`, no `TMPDIR`, Node ≥22):
> `pnpm install`; `pnpm --filter @codemojex/game typecheck && build && test`; the build emits **one**
> self-contained `game-[hash].js` (+ manifest) into `echo/apps/codemojex/priv/static/game` with a
> compiled smoke-used utility rule (the `text-2xs` / `bg-card` rule) present, the ported
> `--color-bg-app-from` token present, **no** `@codemoji/design`, **no** bare unbundled external, **no**
> document-scope preflight; the vitest smoke asserts render + `t()` + `cn()` + the className string
> (never `getComputedStyle`). The pixel (classes resolve, the bg-app gradient paints, the host is
> un-clobbered) is Operator-observed via the cmt.2 hot-load loop. **Framing:** third person, no gendered
> pronouns for agents, no perceptual/interior-state verbs, forward-tense for unbuilt surface; cite the
> reference / `file:line` for every surface, invent nothing. **Boundary:**
> `mercury/codemojex/apps/game/**` + the `docs/codemojex/specs/tauri/` triad only — no other app, no
> `echo/`, no `@mercury/*`, no `git`.
