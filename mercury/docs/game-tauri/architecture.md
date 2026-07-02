# Architecture — the three tiers and the one contract

> Grounded 2026-07-02 against the as-built tree. Spec canon:
> [`docs/codemojex/specs/tauri/tauri.design.md`](../../../docs/codemojex/specs/tauri/tauri.design.md).

## The three tiers

```
┌─────────────────────────────────────────────────────────────────┐
│  Tauri shell        mercury/codemojex/apps/game-tauri           │
│  (Mode A: WebviewUrl::External → PHX_APP_URL; system webview;   │
│   dev panel injected via initialization_script, Ctrl+`)         │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Phoenix engine   echo/apps/codemojex  (:4000)            │  │
│  │  welcome (/) → lobby (/lobby) → game (/game/:gam)         │  │
│  │  GameLive assigns game_bundle → the page's GameIsland     │  │
│  │  hook dynamic-imports it                                  │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │  Game island   mercury/codemojex/apps/game          │  │  │
│  │  │  @codemojex/game — one self-contained ESM bundle,   │  │  │
│  │  │  its OWN React 19; mount(el, props, bridge)         │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

- **The engine** (`echo/apps/codemojex`) is the BCS Elixir app over Postgres + Valkey (`:6390`).
  It serves the pages and the Phoenix Channels the game rides on. From the island's point of view
  it is a **host**: the island never imports engine code, and `/cm-ship` work never edits `echo/`.
- **The island** (`@codemojex/game`) is a React app compiled to **one content-hashed ESM file**
  with everything inside — React, Effector, the compiled Tailwind CSS, the i18n resources. The
  host page knows nothing about its internals.
- **The shell** (`game-tauri`) is Mode A of three documented modes (see the app's own
  `README.md`): the window loads the Phoenix URL directly (`WebviewUrl::External`), so the shell
  is a wrapper, not a fork of the frontend. The **dev panel** (`dev-panel/inject.js`) is injected
  via a Tauri initialization script; it taps every Phoenix Channel frame by wrapping
  `window.WebSocket`. Toggle with the floating button or **Ctrl+`** (`inject.js:145`).

## The one contract — `mount`

The island's outward contract is exactly one module surface (`src/index.tsx`):

```ts
export function mount(el: HTMLElement, props: GameProps, bridge: Bridge)
  → { update(p: GameProps): void, unmount(): void }
export { GameEdge }
```

`GameProps = { view, leaderboard, history, me }` (`src/types.ts`); `me` is a bare branded `PLR`
string. The bridge carries the BCS branded ids (`SES`/`ROM`/`GAM`/`PLR`/`GES`) — the track mints
no entity of its own.

As-built (post `1c99cfa6` + `457e0f56`), `mount` is a **LiveMount facade**:

1. `injectTheme()` first — the Tailwind-compiled `theme.css` is imported `?inline` (a string
   inside the bundle) and appended once as `<style data-cmjx-game>`. No second CSS file, no
   host-page reset (preflight is omitted at the source).
2. A `LiveMount` object (`{el, bridge, props, root, apply}`) is built and rendered via an
   internal `render(live)`:
   - **Smoke branch** (first): `import.meta.env.VITE_GAME_SMOKE === "1"` renders the
     foundation probe `GameSmoke` instead of the game. In a production build the flag is
     statically replaced and the whole branch **folds out of the artifact**.
   - **Default**: `createGameModel()` is built and `<BridgeGame model bridge initial>` renders —
     the model-driven mount (`BridgeGame` composes `GameEdge` internally; the cmt.3 Phase-A
     composition, one level deeper).
3. `update(p)` retains the latest props (`live.props = p`) and fires `live.apply(p)` →
   `model.propsReceived(p)`.
4. **Hot swap** (dev only): `export function remount(live)` + an `import.meta.hot.accept`
   handler hand the retained `LiveMount` from the OLD module to the NEW one, which re-renders its
   own graph from the retained props — the LiveView page and socket never reload. All of it is
   compile-time dead in the library build. (Guard hot-swap code on `import.meta.hot?.data`:
   vitest exposes a partial `import.meta.hot` with no `data`.)

## The state layer (cmt.3 Phase A + hotswap-effector)

- `@mercury/effector` provides `createChannel` and `bridgeChannel(bridge, {joinReply})` — the
  HostBridge→ChannelLike adapter (join `"ok"` = the initial props).
- The game's `src/channel/model.ts` (`createGameModel`) exposes `$props` plus derived
  `$view` / `$leaderboard` / `$history` / `$me` and typed events
  (`guessRejected`, `revealed`, `goldenWin`); `BridgeGame` (`src/channel/BridgeGame.tsx`) is the
  bridge-driven twin of `PhoenixGame`.
- Components stay presentational; the model owns the channel.

## Bundle delivery

- `vite build` (app-mode, `rollupOptions.input: src/index.tsx`) emits **one**
  `game-[hash].js` + `.vite/manifest.json` into `echo/apps/codemojex/priv/static/game/` — a
  **gitignored** output dir (root `.gitignore:220`), so builds never dirty the tree.
- Phoenix serves it via `GameBundleController` (`/game-bundle/:file`); `GameLive` assigns
  `game_bundle: dev_bundle_url()` (`game_live.ex:46`) — `GAME_DEV_URL` wins when set, else
  `GameBundle.src()`.
- **Load-bearing:** `preserveEntrySignatures: "strict"` in `vite.config.ts`. Without it,
  app-mode Rollup applies the facade optimization and can emit a **mount-less** bundle — invisible
  to source greps; only importing the artifact catches it (see
  [testing.md](./testing.md) § The node-import gate).

## Boundaries

- `/cm-ship` rungs edit `mercury/codemojex/**` (+ ratified additive `mercury/packages/*`); an
  `echo/` change forks to `/codemojex-ship`. The island **building into** the gitignored echo
  output dir is fine — the boundary governs the diff, not the filesystem.
- `node/codemoji-design` is a **read-only visual reference** (F1 ruling): components are
  re-implemented natively in `@codemojex/game`; there is no `@codemoji/design` dependency, and
  the built artifact is grep-gated to prove it.
