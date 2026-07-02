# The design-system foundation (cmt.4.1) — what board authors build on

> Shipped `457e0f56` (2026-07-02, Director-verified). The authoritative spec is the triad
> [`docs/codemojex/specs/tauri/cmt.4.1.md`](../../../docs/codemojex/specs/tauri/cmt.4.1.md).
> The token source of truth is `node/codemoji-design/tokens/tokens.mjs` — a **read-only visual
> reference** (F1 ruling): values are ported verbatim; the package is never imported.

## The stack, layer by layer

| Layer | Where | What it gives you |
|---|---|---|
| Tailwind v4 | `@tailwindcss/vite` in `vite.config.ts` `plugins` | utility classes compiled from scanned source, CSS-first config |
| The token `@theme` | `src/styles/theme.css` | the full codemoji token vocabulary as `--color-*` / `--text-*` / `--font-*` variables + generated utilities |
| `cn` | `src/lib/cn.ts` (`clsx` + `tailwind-merge`) | conditional class composition with last-wins conflict resolution |
| i18n | `src/i18n/i18n.ts` + `src/i18n/locales/{ru,en}/translation.json` | synchronous `t()` from bundled resources (`useSuspense: false`, fallback `ru`) |
| CSS delivery | `index.tsx` `injectTheme()` | the compiled CSS rides **inside** the JS bundle (`theme.css?inline`) and injects once as `<style data-cmjx-game>` |
| The smoke | `src/GameSmoke.tsx` (dev-flagged) | the living example of the whole stack in ~25 lines |

## The tokens (ported verbatim from `tokens.mjs`)

- **Base palette (oklch):** `--color-background`, `--color-foreground(-secondary)`,
  `--color-card(-foreground…)`, `--color-drawer…`, `--color-primary` (black) /
  `--color-primary-foreground` (white), `--color-accent` (the ONE themeable channel),
  `--color-border`, `--color-slot(-active)`, `--color-link`, popover/secondary/muted/destructive,
  chart-1..5, the sidebar set.
- **Literal HSL semantics:** `--color-bg-app-from: hsl(196, 48%, 94%)` (#E8F3F7) and
  `--color-bg-app-to: hsl(203, 32%, 76%)` (#AFC7D6) — **the Classic board's screen fill**
  (`BoardScreen` root: `linear-gradient(180deg, var(--color-bg-app-from), var(--color-bg-app-to))`);
  plus `bg-from/to`, `bg-main`, `bg-secondary`, `--color-success`, `--color-main-blue`,
  `--color-accent-secondary`, muted/dark-muted.
- **Gold COLOR tokens:** `--color-gold-surface #CC7500` / `-foreground #FFFFFF` /
  `-border #E6A900`. **The gold TEXTURE is deliberately absent** — `gold.texture` is the sole
  asset-backed value in `tokens.mjs` and it defers whole to the golden rung (cmt.5) per the
  F-cmt41-2 ruling. There is no `--gold-texture` var and no `bg-gold-texture` utility here.
- **Type scale:** `--text-2xs: 0.625rem` + `--text-h1..h6` + `--text-large`;
  `--font-sans: 'Noto Sans Mono', monospace`.
- **Actions (fixed, role-based):** `--color-action-enter #0050FF`,
  `--color-action-control #A8ACB0`, `--action-gradient-purchase` (a background-image value, kept
  a plain theme var).
- **Accent themes:** `[data-theme="orange"|"blue"|"green"]` blocks re-declare `--color-accent`
  **directly** for their subtree (a `var()`-chained `@theme` value would substitute at `:root`
  and not re-resolve per subtree).

## The delivery rules (why they are what they are)

1. **`?inline`, never a plain CSS import.** A plain `import "./theme.css"` in this build emits a
   second `game-[hash].css` file the host would have to load — breaking the one-artifact
   contract. The `?inline` import turns the compiled CSS into a string inside the bundle;
   `injectTheme()` appends it once.
2. **No preflight, ever.** `theme.css` imports only the `theme` + `utilities` layers. Tailwind's
   preflight is a document-scope reset (`*,::before,::after`) that would restyle the host
   LiveView page the island mounts into. If a board component needs a reset, scope it under
   `.cmjx-game`.
3. **`.cmjx-game` is the island's scope root** — the class on the island's own subtree, the
   `data-cmjx-game` marker on the injected style tag. Utilities apply only where their classes
   are used; the host page stays untouched.
4. **Used-only emission (the pruning posture).** tailwindcss 4.3.2 emits only theme variables
   that scanned source consumes — via utility classes **or** `var()` references in JS/TSX (that
   is how the bg-app pair rides: the smoke's `SCREEN_FILL` string). The unconsumed remainder of
   the verbatim port (chart-*, sidebar-*, gold colors, actions, h1..h6…) prunes from the emitted
   artifact until a consumer lands — `theme.css` **source** always carries the full port. If full
   emission is ever wanted: `@theme` → `@theme static`, one line.

## Rules for cmt.4.2 (Classic `BoardScreen`) authors

- **Compose from the ported vocabulary**: `bg-card`, `text-primary`, `text-2xs`, the bg-app
  gradient (inline `style`, mirroring the reference's `SCREEN_FILL`), `font-sans`, `rounded-2xl`.
  New tokens go into `theme.css` only if they exist verbatim in `tokens.mjs`.
- **`cn` for every conditional/merged className** (`import { cn } from "@/lib/cn"`).
- **All copy through `t()`** — the `board.*` / `game.*` namespaces port from the reference's
  locales **with the components** (the F-cmt41-3 ruling); today only the `smoke.*` seed exists.
- **No `@codemoji/design` import** — re-implement natively; the artifact is grep-gated to zero.
- **Balances omit/neutralize** (the F3 ruling): `GameProps` carries no
  `diamonds`/`clips`/`keys`/boost and `me` is a bare `PLR` string. Do not fabricate numbers; the
  server `game_props` extension is a deferred `/codemojex-ship` rung.
- **jsdom asserts strings, not pixels** — the vitest config carries no Tailwind, so test render +
  `t()` + `cn()` + `className` contents; never `getComputedStyle`. The pixel is
  Operator-observed via the dev loop.

## The smoke as the worked example

`src/GameSmoke.tsx` renders, under `VITE_GAME_SMOKE=1` only: the `.cmjx-game` root (via `cn`),
the Classic screen-fill gradient (inline style on the bg-app vars), a `bg-card p-4 text-primary`
surface, and a `text-2xs font-bold` `t("smoke.ping")` label — one element exercising every layer
above. Its suite (`GameSmoke.test.tsx`) is the testing idiom to copy.
