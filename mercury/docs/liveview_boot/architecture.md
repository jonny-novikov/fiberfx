# Architecture

← [README](README.md) · siblings: [events](events.md) · [channels](channels.md) ·
[interactions](interactions.md) · [effector-pipeline](effector-pipeline.md)

## 1 · Three delivery tiers

The frontend ships in three tiers with three different lifecycles:

| Tier | Artifact | Built where | Delivered how | Changes via |
|---|---|---|---|---|
| **Ship-with** | `priv/static/assets/{phoenix.js, phoenix_live_view.js, app.js}` | Mercury (`pnpm --filter @echo/phoenix* build`, `--filter @codemojex/liveview-boot build`) | **committed to git**, served by Phoenix | `mercury/codemojex/apps/game/bin/phoenix-modules-build.sh` + a commit |
| **Edge** | `game-[hash].js` (the React island, self-contained) | Mercury (`pnpm --filter @codemojex/game build`) | pushed to `edge.codemoji.games`; `Codemojex.GameBundle` pulls the bytes once and re-serves them **same-origin** from memory | an edge deploy — **not** a `fly deploy` |
| **Server** | the Phoenix release | echo/ umbrella | Operator-run deploy | `/codemojex-ship` rungs |

The point of the split: a game change is an edge deploy; the committed boot changes rarely and
deliberately (it is the stable contract surface between the two).

## 2 · The import map and the one-Socket law

`CodemojexWeb.Layouts.root/1` (echo side) emits, in order: `modulepreload` hints for the phoenix
modules, an **import map**, then the boot as a module script:

```html
<script type="importmap">
  { "imports": {
      "@echo/phoenix":           "/assets/phoenix.js",
      "@echo/phoenix_live_view": "/assets/phoenix_live_view.js" } }
</script>
<script type="module" src="/assets/app.js"></script>
```

The boot is vite-built in **library mode with `@echo/*` and `phoenix` externalized**
(`liveview-boot/vite.config.ts`), so `dist/app.js` begins with *bare* imports:

```js
import { Socket } from "@echo/phoenix";
import { LiveSocket } from "@echo/phoenix_live_view";
```

The browser resolves those through the import map — which means **every module on the page shares
one `Socket` class and one `LiveSocket` instance** (`window.liveSocket`). Nothing else may bundle
its own copy of the phoenix client; that is the externalization contract
(`echo/docs/codemojex/frontend-delivery.design.md` §1a).

## 3 · The boot module (`liveview-boot/src/app.ts`)

One file, four responsibilities:

1. **Bootstrap** — read the CSRF meta, `new LiveSocket("/live", Socket, { hooks: { GameIsland } })`,
   `connect()`, expose `window.liveSocket`. Runs at module load.
2. **`GameIsland`** — the LiveView hook that owns the island lifecycle: read `data-bundle` /
   `data-props` off the hook element, dynamic-import the bundle, call
   `mount(el, props, bridge)`, register the four server-event handlers, and tear everything down in
   `destroyed()` (`removeHandleEvent(ref)` per ref — never invoke a ref; that was a real bug the
   typed migration surfaced).
3. **The `Bridge`** — the only capability the island receives from the host:
   `{ pushEvent(event, payload), onServerEvent(cb) → unsubscribe }`. Outbound goes to the LiveView
   socket; inbound one-off events fan out to the island's registered listeners.
4. **The dev hot-wire** — `devOriginOf` + `wireViteDev` (see §6).

The boot carries **no game code**: the island arrives at runtime.

## 4 · The island bundle (`apps/game`)

The game builds as **one self-contained ESM file** (`game-[hash].js` + a Vite manifest): React
bundled (the island owns its runtime), `@mercury/effector` resolved **from source** via alias with
`dedupe: ["effector", "effector-react"]` (one Effector graph even though the adapter lives in a
Mercury package). The only outward contract is:

```ts
mount(el: HTMLElement, props: GameProps, bridge: Bridge): { update(p), unmount() }
```

### The F-1 gate — export signatures are the contract

The island is an **app-mode** Vite build (`rollupOptions.input`, not `build.lib`). Without
`preserveEntrySignatures: "strict"` (set in `apps/game/vite.config.ts`), Rollup drops the entry's
named exports — the emitted module imports fine and renders nothing, because `mod.mount` is
`undefined`. This shipped silently once. The gate is therefore an **import of the artifact**, not a
grep:

```sh
node -e "import('file://<abs>/game-<hash>.js').then(m => console.log(Object.keys(m)))"
# must include: mount, GameEdge
```

## 5 · Two transports, one model

The island's state layer is a single Effector model (`createGameModel`, [channels.md](channels.md)
§4). Two thin components plug it into the two real transports:

```
production (Mini App)                        Tauri dev toolkit / channel clients
─────────────────────                        ───────────────────────────────────
GameLive (LiveView)                          CodemojexWeb.RoomChannel  (game:<id>)
   │  data-props + push_event                   │  join reply + push
boot GameIsland bridge                       @echo/phoenix Socket("/socket")
   │                                            │
bridgeChannel(bridge, {joinReply})           the channel itself (ChannelLike)
   └───────────────┬────────────────────────────┘
                   ▼
        createChannel().bind(...)   ← @mercury/effector
                   ▼
           createGameModel()        ← $props · $view · $leaderboard · events
                   ▼
     BridgeGame ───┴─── PhoenixGame ──▶ GameEdge (presentational, unchanged)
```

`bridgeChannel` (Mercury, `packages/mercury-effector/src/bridge.ts`) lifts the host bridge into the
`ChannelLike` contract — the initial `data-props` ride as a synthetic join "ok" reply, mirroring
`RoomChannel.join`'s `%{view: …}` reply. One model, no per-transport wiring.

## 6 · The dev hot-wire (HMR in a page Vite doesn't own)

`GameLive.dev_bundle_url/0` honors `GAME_DEV_URL` (e.g. `http://127.0.0.1:5173/src/index.tsx`) over
the edge bundle. The boot detects that case **structurally** — an absolute `http(s)` URL whose
pathname ends `.ts`/`.tsx` is something only a Vite dev server serves (built bundles are
`game-[hash].js`) — and, before importing the entry, performs Vite's documented backend-integration
sequence as awaited imports (deterministic ordering, no script-tag races):

```
/@react-refresh  → injectIntoGlobalHook(window), $RefreshReg$, $RefreshSig$, preamble flag
/@vite/client    → the HMR websocket client
then: import(entry)
```

Failure is non-fatal (`console.warn`, fall through) — a not-yet-started dev server is a routine dev
state. In production the detector returns `null` and none of this executes.

Hot-swap semantics inside the island (`apps/game/src/index.tsx`):

- **Component edit** → react-refresh updates in place; React state (picks, toast) survives.
- **Entry/model edit** → the graph bubbles to the self-accepting entry; the *new* module `remount`s
  over the retained `LiveMount` facade (`import.meta.hot.data.live`), rebuilding a **fresh model
  from the latest retained props** — new logic applies, data survives, the LiveView page and socket
  never reload.
- Guard rail: hot-swap code keys on `import.meta.hot?.data`, not `import.meta.hot` — Vitest exposes
  a truthy partial `hot` without a `data` bag.

## 7 · Boundaries

- The boot never imports game code; the game never imports the boot. The contract between them is
  `mount`/`Bridge`/`GameProps` (`apps/game/src/types.ts`, kept in lockstep with
  `GameLive.game_props/3`).
- The island never imports `@mercury/ui`; `@mercury/effector` enters from source and is bundled.
- `echo/` is a read dependency of these docs, not of the Mercury build: nothing in the Mercury tree
  edits echo/ (the built artifacts land in echo `priv/static/`, which is untracked / Operator-shipped).
