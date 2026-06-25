# CLAUDE.md — codemoji-app (the Codemoji React frontend)

The `@codemoji/app` Telegram Mini App — the React UI for the Codemoji emoji-guessing game whose
backend is the BCS `echo/apps/codemojex` Phoenix consumer. This file is the concise build guide;
the design comes from Figma.

> **Building UI from the Figma design?** Use the `figma-local` MCP — usage + token-budget rules in
> [`../../mcp/docs/figma-local.md`](../../mcp/docs/figma-local.md) (scoped to **this app and
> `echo/apps/codemojex` only**). For any real extraction, drive the
> [`@codemoji/design`](../codemoji-design) toolkit, not the raw tools — it writes a spec + reference
> renders + a token map under `node/codemoji-design/figma/<screen>/`. The CODEMOJIES game screen is
> already extracted at `node/codemoji-design/figma/codemojies/`.

## Stack

Vite 7 · React 19 · TypeScript 5.9 · **Tailwind v4** (`@tailwindcss/vite`, CSS-first) · pnpm.
State: **jotai** (client atoms) + **@tanstack/react-query** (server state). Routing:
**react-router-dom 6.29**. Platform: **Telegram Mini App** (`@twa-dev/sdk`) + **TON wallet**
(`@tonconnect/ui-react`, `@ton/core`) for crystal withdraw. Realtime: `socket.io-client`. UI
primitives: Radix + **CVA** (`class-variance-authority`) + the **`cn`** merge helper
(`clsx` + `tailwind-merge`); `lucide-react` icons; `vaul` drawers; `swiper`; `react-confetti`;
`@dnd-kit` drag-drop; `emoji-mart` for the emoji set. i18n: `i18next`/`react-i18next` (en/ru).
Errors: `@sentry/react` + `react-error-boundary`. SVGs import as components via `vite-plugin-svgr`.

## Layout — Feature-Sliced Design (`src/`)

Strict FSD; imports flow **down** only (`app → pages → widgets → features → entities → shared`).

- `app/` — providers + composition root (`main.tsx`, `router.tsx`, `instrument.ts` = Sentry).
- `pages/` — `home` · `rooms` · `game` · `withdraw` (route targets; compose widgets).
- `widgets/` — self-contained UI blocks: `header` · `status-bar` · `emoji-slots` ·
  `selected-emojis` · `emotion-picker` · `game-rules` · the `*-dialog` set · `onboarding` ·
  banners. This is where most Figma figures land.
- `features/` — user actions: `game` · `emoji-actions` · `auth` · `connect-ton-wallet` ·
  `keys-purchase` · `withdraw-crystals` · `share-story` · `session-timer`.
- `entities/` — domain models + their UI: `player` · `balance` · `rooms` · `leaderboard` ·
  `golden-games` · `history` · `wallet`.
- `shared/` — `ui` (primitives) · `api` · `layout` (`base-layout`) · `libs` · `types` · `assets`.
  Cross-app types come from the `@codemoji/types` workspace package.

## Design tokens (Tailwind v4 CSS-first)

**All tokens live in `src/styles.css`** under `@theme inline` — never hardcode hex; use the
semantic utilities. Font: `--font-sans: 'Noto Sans Mono', monospace` (matches the Figma screen).
Key colors: `--color-accent` `#FF8400` (orange) · `--color-accent-secondary` `#FF2F00` ·
`--color-success` `#00D95F` · `--color-muted` `#666` · `--color-dark-muted` `#333` · `--card`
`#FFFFFF` · the app background gradient `#E8F3F7 → #AFC7D6` (`--color-bg-from`/`--color-bg-to`).
Type scale: `--text-h1` 20px → `--text-h6`/`--text-2xs` 10px, plus `--text-large` 26px. The
extraction's `tokens.md` maps each Figma value to the token here (and flags any new/unmapped one).

## Routing (`src/router.tsx`, `createBrowserRouter`)

All under `BaseLayout`: `/` → redirect to the default (`/rooms`) · `/home` · `/rooms` ·
`/game/:roomId/:gameId` · `/withdraw`. The game screen is parameterized by room + game id.

## Figure → slice map (from the CODEMOJIES extraction)

When building the game screen to match Figma: iOS header → `widgets/header`; info/balance card →
`widgets/status-bar` + `entities/balance`; the guess cards → `widgets/emoji-slots` +
`widgets/selected-emojis`; the emoji keyboard → `widgets/emotion-picker`; the leaderboard →
`entities/leaderboard`; the rules → `widgets/game-rules`; the iOS Home Indicator → Telegram
safe-area padding, not a component. Read radius/spacing from the reference PNGs (the extraction
JSON omits them until the `figl` MCP rungs land — see the figma-local usage guide).

## Commands

`pnpm dev` (Vite) · `pnpm build` · `pnpm check` (typecheck + lint + format) · `pnpm test`
(vitest) · `pnpm test:visual` (Playwright snapshot diff). Node ≥ 22.12, pnpm ≥ 10.
