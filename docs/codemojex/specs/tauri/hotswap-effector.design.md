# LiveView boot hot-swap + the deep Game Effector — design of record

> **Track:** codemojex Tauri (`cmt.N`, the hot-loading RETURN-CONTEXT) · **AAW scope:** `cm-tauri` ·
> **Method:** [`../../../aaw/aaw.architect-approach.md`] (four-part arms; alternatives on the record;
> forks surfaced, never decided) · **Siblings:** [`./gameroom.steelman.design.md`] ·
> [`./gameroom.steward.design.md`] · [`./cmt.3.md`] (the Effector channel foundation) ·
> [`./cmt.4.1.md`] (the golden DS foundation, unrelated scope) · delivery canon
> `echo/docs/codemojex/frontend-delivery.design.md` (§1a externalization · §2 the boot · §4b the
> committed modules).
>
> **DESIGN + BUILD RECORD.** The Operator directed this rung: *design the LiveView boot
> (`mercury/codemojex/apps/liveview-boot/`) for hot-swapping the GameIsland, design the deep Game
> Effector over `@mercury/effector` + PubSub with effector-react capabilities and mercury+Game addons,
> and implement three improvements.* The improvement **selection** is therefore ruled by directive;
> each improvement is still argued in the four-part arm anatomy, the alternatives keep their
> CHOSEN-AGAINST case, and the residual choices no directive covers are surfaced in §7 — open, not
> decided here.

## 1 · Frame — what exists, what is missing

The delivery chain, as built (every surface verified on disk):

| Surface | Where | Fact |
|---|---|---|
| The boot | `mercury/codemojex/apps/liveview-boot/src/app.ts` | The LiveView client (`GameIsland` hook + `LiveSocket` bootstrap), vite lib-built with `@echo/*`/`phoenix` externalized to the host import map; committed as `echo/apps/codemojex/priv/static/assets/app.js` by `phoenix-modules-build.sh` |
| The host page | `echo/…/live/game_live.ex` | `#game-root` with `phx-hook="GameIsland"`, `phx-update="ignore"`, `data-bundle={GAME_DEV_URL || GameBundle.src()}`, `data-props={game_props}`; pushes `game:update` + `guess_rejected`/`revealed`/`golden_win`; handles `submit_guess`/`lock`/`unlock` |
| The island | `mercury/codemojex/apps/game/src/index.tsx` | `mount(el, props, bridge) → {update, unmount}` — createRoot + an **imperative** `root.render(<GameEdge/>)` per `update()` |
| The channel twin (cmt.3) | `…/game/src/channel/{model.ts,PhoenixGame.tsx}` | `createGameModel()` over `@mercury/effector`'s `createChannel`: `$props` fed by the join reply + `"game:update"` frames; `serverEvent` for one-offs; `submitGuess`/`lock`/`unlock` pushes. `PhoenixGame` opens its own socket (the Tauri path) |
| The plug | `mercury/packages/mercury-effector/src/channel.ts` | `createChannel()` — structural `ChannelLike`, `$status`/`$error`/`joined`/`message`/`push`/`pushAsync`/`bind` |
| The dev override | `game_live.ex` `dev_bundle_url/0` | `GAME_DEV_URL` (e.g. `http://127.0.0.1:5173/src/index.tsx`) short-circuits the edge bundle — the cmt.2 hot-load seam |

Three gaps carry this rung:

1. **The dev override loads, but nothing hot-swaps.** `GAME_DEV_URL` makes the island import the Vite
   dev-server *source* entry — but the page never loads `/@vite/client` or the react-refresh preamble,
   so no HMR socket exists: an edit does nothing until a full LiveView page reload. The RETURN-CONTEXT
   (game-tauri hot-loading) is exactly this missing loop.
2. **The two transports don't share the state layer.** The Tauri path is Effector-driven (`$props`);
   the production LiveView path is imperative (`update()` → wholesale re-render). Every capability
   built on the model (derived stores, typed events, status) is invisible to the path players use.
3. **A failed bundle import kills the island silently.** `await import(bundle)` is unguarded — in a
   dev loop where the server may not be up yet, that is a routine state, not an exception.

## 2 · The three improvements (each argued as an arm)

### I1 — the boot's Vite dev hot-wire (`GameIsland` dev mode)

- **Rationale.** HMR inside a LiveView-hosted island requires the host page to install Vite's client
  and (for React) the react-refresh preamble *before* the source entry executes — Vite's documented
  Backend Integration contract. The boot is the only surface that sees the bundle URL early enough,
  and it can detect the dev case without any `echo/` edit: only a dev server serves a `.ts`/`.tsx`
  source path (the built artifact is always `game-[hash].js`).
- **5W.** **Why** — close the hot-loading gap (the RETURN-CONTEXT). **What** — `devOriginOf(url)`
  (absolute `http(s)` + `.ts`/`.tsx` pathname → origin, else null) + `wireViteDev(origin)` (await
  `/@react-refresh`, run the documented preamble injection, await `/@vite/client`), called from
  `mounted()` before the entry import, failure-tolerant (`console.warn` + fall through); plus a
  guarded entry import (`console.error` + abort, never an unhandled rejection). **Who** — the island
  developer running `GAME_DEV_URL`; inert for players (edge URLs are `.js` → null). **When** — this
  rung. **Where** — `liveview-boot/src/app.ts` only; ships with the next committed `app.js`.
- **Steelman.** The preamble sequence is Vite's own contract (`/@react-refresh` →
  `injectIntoGlobalHook(window)` → `$RefreshReg$`/`$RefreshSig$`/`__vite_plugin_react_preamble_installed__`
  → `/@vite/client`), driven as awaited dynamic imports so ordering is deterministic — no script-tag
  races. Detection is a *structural* fact of the artifact (source path vs built hash-name), not a
  heuristic flag someone must remember to set; zero `echo/` edits; zero production surface (an edge
  bundle can never end `.tsx`). With it, a `GameEdge.tsx` edit updates **in place** — LiveView socket,
  page, and React state all survive.
- **Steward.** ~50 lines in one file the boot already owns; no new dependency. The cost to keep: the
  preamble idiom tracks `@vitejs/plugin-react` (stable across v4; re-verify on a Vite major). The
  idempotency guard (`__vite_plugin_react_preamble_installed__` short-circuit) keeps re-mounts safe.
  Honest limit: jsdom cannot execute the dev-server imports, so unit tests prove the seam functions
  (`devOriginOf`, `wireViteDev` with an injected importer) and the resilience path; the pixel-level
  HMR loop is Operator-observed (§5).

### I2 — `bridgeChannel` — a host-bridge → `ChannelLike` adapter (the Mercury addon)

- **Rationale.** The island's `Bridge` (`{pushEvent, onServerEvent}`) and a Phoenix channel carry the
  same frames because both terminate the same `Phoenix.PubSub` topic (`"game:" <> gam` — `GameLive`
  subscribes, `RoomChannel` joins). Lifting the bridge into `ChannelLike` lets `createChannel()` —
  and everything built over it — run **unchanged** over the LiveView transport. One state layer, two
  transports.
- **5W.** **Why** — unify the transports at the adapter, not by duplicating model wiring. **What** —
  `bridgeChannel(bridge, {joinReply})`: `join()` resolves "ok" with `joinReply` (the initial props —
  mirroring `RoomChannel.join`'s `game_props` reply); `on(event)` filters the bridge fan-out per
  event with per-ref unsubscribe bookkeeping; `push()` forwards to `bridge.pushEvent` and acks "ok"
  (fire-and-forget — LiveView's `handle_event` here replies nothing; §7 seam); `onClose`/`onError`
  are no-ops (the LiveView socket owns reconnection); `leave()` releases every subscription.
  **Who** — the game island now; any future host-bridged Mercury consumer. **When** — this rung.
  **Where** — `mercury/packages/mercury-effector/src/bridge.ts`, exported additively from the barrel.
- **Steelman.** Pure TypeScript, zero dependencies, type-only imports from `./channel` — the exact
  "state lives outside React" posture of the package, and generic (nothing game-specific: event names
  and payload validation stay in the consumer). The strongest evidence is what it makes free: the
  game model gains the LiveView transport with **no model edit at all**, and the cmt.3 Phase-B flip
  (default mount → channel transport) becomes a render-path choice instead of a rewrite.
- **Steward.** A new public Mercury surface — a multi-year liability priced deliberately: it is small
  (one function, two interfaces), additive to the barrel (the master invariant holds), and versioned
  by the `ChannelLike` contract it mirrors rather than by Phoenix. The honest seams are documented in
  the source: no close/error propagation (host-owned), ack-only push semantics. Behavioral tests live
  in the game suite (`channel/bridge.test.ts`) — the package has no vitest harness, and the
  dual-vitest jest-dom trap says don't bolt a mismatched one on; the package gate stays
  `typecheck + build`, the consumer suite proves behavior through the real usage path.

### I3 — the deep Game Effector mount (model-driven LiveView path + typed PubSub + hot-stateful entry)

- **Rationale.** With I2, the production path can be driven by the same Effector model as the Tauri
  path — `$props` becomes the single state authority, `update()` becomes an event
  (`propsReceived`), and effector-react (`useUnit`) subscribes the tree. That is the "deep" half the
  directive names: state outside React, fine-grained derived stores, and a typed client-side terminus
  of the server's PubSub fan-out.
- **5W.** **Why** — one model over both transports; store-grade state for GameRoom and the dev loop.
  **What** — (a) `createGameModel` grows **additively**: derived stores `$view` / `$leaderboard` /
  `$history` / `$me` (`$props.map` slices — `useUnit`/`useStoreMap` consumers re-render per slice),
  and `events = { guessRejected, revealed, goldenWin }` — typed one-off events sampled off
  `serverEvent` (the client mirror of `Phoenix.PubSub` broadcasts); (b) **`BridgeGame`**
  (`channel/BridgeGame.tsx`) — the LiveView twin of `PhoenixGame`: binds the model over
  `bridgeChannel(bridge, {joinReply: $props ?? initial})`, renders `GameEdge` from `useUnit($props)`
  (falling back to `initial` so the first paint is as immediate as today); (c) `index.tsx`'s `mount`
  rewired through a stable `LiveMount` facade — `update(p)` records `p` and fires the model, and an
  entry-level `import.meta.hot.accept` remounts the **new** module over the retained props, so a
  non-component edit (e.g. `model.ts`) hot-swaps the island in place instead of reloading the page.
  **Who** — players (unchanged behavior), the island developer (stateful HMR), GameRoom (the derived
  stores are its consumption surface). **When** — this rung. **Where** — `apps/game/src/{index.tsx,
  channel/model.ts, channel/BridgeGame.tsx, vite-env.d.ts}`.
- **Steelman.** The outward contract is untouched — `mount(el, props, bridge) → {update, unmount}`
  byte-compatible in signature, `GameEdge` still the rendered screen with the same `bridge` (its
  toast subscription and outbound pushes are unchanged) — yet everything upstream becomes reactive.
  The hot-swap semantics are *honest by construction*: react-refresh preserves component state on
  component edits; an entry/model edit rebuilds the model **from the latest retained props** (the
  `LiveMount` facade records every `update`), so logic edits actually apply instead of silently
  running stale code against a preserved-but-old model instance.
- **Steward.** The new island surface is one small component + additive model fields; the facade is
  ~30 lines. The `import.meta.hot` block is dead code in the library build (Vite defines it away) and
  singleton-scoped (`hot.data.live`) — correct for the one `#game-root` GameLive renders, noted as a
  limit. The known cost: client-only React state below `GameEdge` (in-flight picks) does not survive
  an *entry-level* swap (it does survive component-level refresh) — accepted and documented rather
  than smuggling picks into the model prematurely (that is GameRoom's call, on the derived-store
  surface this rung ships).

### F-1 — a latent delivery defect, found and fixed while gating I3

Gating HSE-INV1 with a **real import of the emitted artifact** (not a source grep) exposed a
pre-existing pipeline defect: the game's app-mode Vite build (`rollupOptions.input`, no `build.lib`)
was **dropping the entry's export signature** — the emitted `game-[hash].js` exported no `mount` at
all (and the model graph reachable only through the dropped exports was tree-shaken away with it).
A rebuild of the **pre-rung** source reproduced the same mount-less artifact byte-for-byte, proving
the defect predates this rung (introduced with the reorg's config move; production survives on an
older, correctly-shaped artifact — any fresh edge deploy would have shipped a dead island). Fix:
`preserveEntrySignatures: "strict"` in `apps/game/vite.config.ts` (one hunk). The rebuilt artifact
imports as `{ GameEdge, mount, remount }`, still self-contained (zero bare externals). The lesson is
codified as HSE-INV7: the mount contract is gated by importing the artifact, the only check that
sees what the host's dynamic `import()` sees.

## 3 · Alternatives — CHOSEN-AGAINST, kept on the record

- **A `#dev` URL-hash marker (or a new `data-*` attr) instead of suffix detection** (vs I1). Explicit,
  but the attr needs an `echo/` edit (out of boundary, forks to `/codemojex-ship`) and the hash is one
  more thing to forget with zero added safety: a `.tsx` pathname is already a signal only a dev server
  can produce. CHOSEN-AGAINST for this rung; the attr arm remains available if a future host wants
  dev-wiring for a `.js` pre-bundled dev artifact.
- **`model.bindBridge(...)` inside the game instead of a Mercury adapter** (vs I2). Keeps Mercury
  untouched, but duplicates the model's sample wiring per transport and leaves the generic capability
  (host bridge → `ChannelLike`) stranded in one app. The directive names `@mercury/effector` +
  mercury addons as the integration base. CHOSEN-AGAINST.
- **Persisting the model instance across entry swaps** (vs I3's rebuild-from-props). Preserves more
  state, but a `model.ts` edit would then keep executing the *old* model logic against the new tree —
  a misleading dev loop. Rebuild-from-retained-props applies new logic and keeps the data. CHOSEN-AGAINST.
- **Intercepting `vite:beforeFullReload`** to suppress page reloads globally. Fragile against Vite
  internals; the entry self-accept achieves the same for the graph that matters. CHOSEN-AGAINST.

## 4 · The one contract, both transports (the shape after this rung)

```
                    Phoenix.PubSub "game:"<>gam
                    ┌────────────┴─────────────┐
             GameLive (LiveView)         RoomChannel (game:<id>)
                    │ push_event                │ push
        boot GameIsland bridge            Phoenix channel
                    │                           │
         bridgeChannel(bridge,          (a real ChannelLike)
           {joinReply: props})                  │
                    └────────────┬──────────────┘
                          createChannel().bind
                                 │
                        createGameModel()
             $props · $view · $leaderboard · $history · $me
             serverEvent · events.{guessRejected,revealed,goldenWin}
             submitGuess · lock · unlock
                                 │ useUnit (effector-react)
                    BridgeGame ──┴── PhoenixGame
                                 │
                             GameEdge (unchanged)
```

## 5 · The dev loop, as operated (the runbook this design serves)

1. `pnpm --filter @codemojex/game exec vite` (or the app's dev script) — the source entry serves at
   `http://127.0.0.1:5173/src/index.tsx`.
2. `GAME_DEV_URL=http://127.0.0.1:5173/src/index.tsx` on the Phoenix node (cmt.2's seam); open the
   game (browser or the game-tauri shell).
3. The boot detects the source entry → wires `/@react-refresh` + `/@vite/client` → imports the entry.
   A component edit hot-updates in place (state preserved); an entry/model edit remounts the island
   from the retained props; the LiveView page and socket never reload. Dev server down → one clear
   `console.error`, island idle, page alive.

## 6 · Invariants (each a runnable check) + the gate

- **HSE-INV1 — the mount contract is byte-stable in signature.** `mount(el, props, bridge)` returning
  `{update, unmount}` + `export { GameEdge }` hold. *Check:* grep + the mount-level vitest.
- **HSE-INV2 — the boot's dev wire is invisible outside dev.** `devOriginOf` returns null for every
  non-`http(s)` or non-`.ts/.tsx` URL (edge + same-origin `.js` bundles); the existing 12 boot tests
  stay green untouched. *Check:* unit tests over the URL matrix.
- **HSE-INV3 — one shared Socket still.** The boot build keeps `@echo/*` + `phoenix` externalized
  (bare specifiers in `dist/app.js`). *Check:* grep the built module for `from"@echo/` /
  `from "phoenix"` and the absence of a bundled LiveSocket.
- **HSE-INV4 — the Mercury barrel is additive.** `@mercury/effector`'s export set gains
  `bridgeChannel`/`HostBridge` and loses nothing. *Check:* `pnpm --filter @mercury/effector typecheck
  && build`; barrel diff is additions-only.
- **HSE-INV5 — the model grows additively.** Every pre-rung `createGameModel` field is intact
  (`chan/$props/serverEvent/propsReceived/submitGuess/lock/unlock`); `model.test.ts` (cmt.3-INV5's
  proof) passes byte-unchanged. *Check:* the existing suite.
- **HSE-INV6 — behavior parity on the LiveView path.** First paint from initial props (no fallback
  flash), `update()` re-renders with fresh props, one-offs reach GameEdge's toasts through the same
  bridge, unmount cleans up. *Check:* `mount.test.tsx` + the untouched `GameEdge.test.tsx`.
- **HSE-INV7 — the emitted artifact exports the contract (F-1).** A dynamic import of the built
  `game-[hash].js` yields keys ⊇ `{ mount, GameEdge }`. *Check:* `node -e "import('file://<artifact>')
  .then(m => …Object.keys(m))"` after the build; a source-level grep is **insufficient** — the defect
  lives in emission, not in source.

**Gate (from `mercury/`):** `pnpm --filter @codemojex/liveview-boot typecheck && test && build` ·
`pnpm --filter @mercury/effector typecheck && build` · `pnpm --filter @codemojex/game typecheck &&
test && build` · the HSE-INV3 dist grep. Never `pnpm -r`; no `TMPDIR` (Elixir-only rule).
Determinism posture: no id-mint / process / lease / schema surface → the ≥100 loop is not required
(per [`./tauri.specs.md`]); the posture is the suites above + the Operator-observed HMR loop (§5).

## 7 · Seams & open decisions (surfaced, not decided)

- **Push acknowledgement over LiveView.** `bridgeChannel.push` acks "ok" immediately;
  `GameLive.handle_event` returns `{:noreply, …}` today. A real reply path (`{:reply, map, socket}` +
  the hook `pushEvent(event, payload, onReply)` threaded through the `Bridge`) is an `echo/`-touching
  rung via `/codemojex-ship` — it would give `pushAsync` true server acks on the LiveView transport.
- **The cmt ladder renumber.** The gameroom steelman/steward re-decomposition is still pending the
  Operator's ruling; this design stays scope-named (`hotswap-effector`) so it lands under either
  ladder without renumber churn.
- **Phase B (default transport flip to `PhoenixGame`)** remains deferred to `/codemojex-ship`
  (RoomChannel D4 live-proof) — unchanged by this rung, but the flip is now a one-line render choice.
- **GameRoom's client state in the model** (picks as an Effector store, surviving entry swaps) — a
  GameRoom-rung decision over the derived-store surface shipped here.
- **The edge Docker deploy rewrite** (flagged since Arm A) is still owed and untouched here.

## 8 · Boundary + reconcile flags

- **Diff boundary:** `mercury/codemojex/apps/liveview-boot/src/**` ·
  `mercury/packages/mercury-effector/src/{bridge.ts,index.ts}` (additive) ·
  `mercury/codemojex/apps/game/src/**` + one `apps/game/vite.config.ts` hunk (F-1) + this document.
  **No `echo/` edit** (the `priv/static/game` artifact regenerated by the build is untracked);
  `apps/game-tauri`, `GameEdge.tsx`, `types.ts`, and the cmt.3 suites untouched.
- **Entanglement note (Director-attribution).** The working tree concurrently carries the cmt.4.1
  build (its own `vite.config.ts` plugins hunk + `package.json` + `src/{i18n,lib,styles}`). This
  rung's hunks are disjoint today, but **cmt.4.1-D6/D8 also edits `index.tsx`** — the two rungs must
  fold that file sequentially (one writer), not concurrently.
- **[RECONCILE]** the committed `echo/…/priv/static/assets/app.js` lags this boot source until the
  Operator runs `phoenix-modules-build.sh` and commits the artifact (the §4b ship-with tier — an
  `echo/`-side byte change, Operator-run per the delivery canon).
- **[RECONCILE]** `tauri.specs.md`/`tauri.design.md` still carry the pre-split cmt.4 ladder (flagged
  by cmt.4.1 already; unchanged here).
