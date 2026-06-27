# Codemojex · LiveReact Hot Swap (the edge-delivered board)

How the Tier-3 React board ships **independently of the Phoenix release** — promoted by an edge upload
and a pointer flip, with no `mix release`, no `fly deploy`, and no socket drop. This is the one piece
of the [render stack](render-stack.md) that is genuinely a *hot swap*.

> **TL;DR.** The board is a content-hashed ESM bundle (`board-<hash>.js`) living at
> `edge.codemoji.games`, named by a short-cached `manifest.json` pointer. `Codemojex.Edge.board_url/0`
> resolves the pointer at runtime; `GameLive` renders the URL into `#board-root`; the `EdgeReact` client
> hook dynamic-imports it and calls the bundle's `mount(el, props, bridge)`. Promotion = upload a new
> hash + rewrite the pointer. Rollback = point at a previous hash. The contract held across a swap is
> the `mount` signature + the `BoardProps` shape + the bridge events — nothing else.

---

## 1. Why the board lives at the edge

The codemojex image is based on `node:22-bookworm-slim`, but **Node is a runtime there, not a build
stage — there is no `npm`/`vite` step in the image**. So any browser JS must either be committed into
`priv/static` ahead of the release, or fetched from an external origin at runtime. Two kinds of asset,
two homes:

| Asset | Changes | Home |
|---|---|---|
| The **LiveView client** (`app.js`: `LiveSocket` + the `EdgeReact` hook) | rarely (only when the host wiring changes) | committed to `priv/static/assets/app.js`, served by `Plug.Static` |
| The **React board** (the component tree) | often (every design/board iteration) | **edge** — `edge.codemoji.games/board-<hash>.js` |

Putting the *fast-moving* asset at the edge means a board iteration is decoupled from the engine's
release cadence: you rebuild + upload the board, flip a pointer, and the next mount picks it up.

## 2. The artifact — a content-hashed ESM bundle

[`assets/vite.config.ts`](../../apps/codemojex/assets/vite.config.ts) builds the board as an ES module
into `priv/static/board/`, content-hashed, with a vite manifest:

```ts
build: {
  outDir: "../priv/static/board",
  manifest: true,
  rollupOptions: {
    input: "react/index.tsx",
    output: { format: "es", entryFileNames: "board-[hash].js", chunkFileNames: "board-[hash].js" },
  },
}
```

- **`format: "es"`** — an ES module, so the browser can `import()` it dynamically.
- **`board-[hash].js`** — the hash is a digest of the contents, so a new build is a *new filename*; an
  old URL never silently changes meaning. Hashed files are served under a **long immutable cache**.
- **React is bundled inside** — the board owns its own runtime; there is no shared-runtime contract
  with the host page. The only outward contract is `mount(el, props, bridge)`.

(The board is built with `npm run build`. The separate `npm run build:client` builds the committed
`app.js` via [`vite.client.config.ts`](../../apps/codemojex/assets/vite.client.config.ts) — that one is
*not* edge-delivered.)

## 3. The pointer — `manifest.json`

A single small JSON object at the bucket root names the current board:

```json
{ "board": "https://edge.codemoji.games/board-<hash>.js" }
```

It is served with a **short cache** (it is the one thing that moves). Everything it points at is
immutable. So a promotion is **an upload plus a pointer rewrite**, and a rollback is the same operation
aimed at a previous hash.

## 4. Resolution — `Codemojex.Edge.board_url/0`

[`lib/codemojex/edge.ex`](../../apps/codemojex/lib/codemojex/edge.ex) reads the pointer at runtime and
briefly caches the result, on the render path, with **no extra process and no new HTTP dependency**:

```elixir
@pt_key   {__MODULE__, :board_url}
@ttl_ms   10_000
@default_edge_host "edge.codemoji.games"   # pointer host; override with BOARD_EDGE_HOST

def board_url do
  case cached() do
    url when is_binary(url) -> url
    _ -> resolve_and_cache()      # fetch https://<host>/manifest.json, else fall back
  end
end
```

- **Cache:** `:persistent_term` keyed by `@pt_key`, holding `{url, expiry}`; a global read with a
  **10-second TTL**. Within the window every mount resolves instantly; after it, the next mount
  re-fetches. So a pointer flip is visible within ~10s.
- **Fetch:** one small `GET` of the pointer via `:httpc` (the app already carries `:inets` + `:ssl`
  for `Codemojex.Telegram`), `timeout: 1_500`, `connect_timeout: 1_000`, expecting `%{"board" => url}`.
- **Fallback:** an unreachable/garbage pointer falls back to the `BOARD_ASSET_URL` env var (a per-deploy
  default), so a bucket blip does not take the board down. If both are empty, `board_url/0` returns
  `nil` and the shell renders with an empty `data-bundle` (the board simply does not mount — see §6).

## 5. The mount point + the loader

**Server side** — [`GameLive.render/1`](../../apps/codemojex/lib/codemojex_web/live/game_live.ex) emits
a sealed mount point carrying the bundle URL and the server props:

```heex
<div id="board-root" class="board-root"
     phx-hook="EdgeReact" phx-update="ignore"
     data-bundle={@board_bundle}
     data-component="BoardScreen"
     data-props={Jason.encode!(@board_props)}>
</div>
```

`phx-update="ignore"` is what **seals the React subtree**: LiveView renders this element once and never
touches its children again, so React owns the DOM inside it and survives LiveView patches/reconnects.

**Client side** — the `EdgeReact` hook in [`assets/js/app.js`](../../apps/codemojex/assets/js/app.js)
turns the data-attributes into a mounted board:

```js
const bundle = el.dataset.bundle;            // the edge URL from Codemojex.Edge
const props  = safeParse(el.dataset.props);  // the server-built BoardProps
const bridge = { pushEvent, onServerEvent };  // see rendering.md
const mod = await import(/* @vite-ignore */ bundle);   // dynamic import of the edge bundle
this._handle = mod.mount(el, props, bridge);           // the board's mount(el, props, bridge)
```

The hook then wires server→client updates onto the handle/bridge (`board:update` → `handle.update`;
`guess_rejected`/`revealed`/`golden_win` → the bridge listeners) and, on `destroyed()`, calls
`handle.unmount()`. The flow detail lives in [rendering.md](rendering.md).

```
edge bundle (board-<hash>.js)             the host page (app.js)
  export mount(el, props, bridge) ───────► import(bundle) ──► mount(el, props, bridge)
       │  owns its own React                       │
       │  returns { update, unmount } ◄────────────┘
```

## 6. Promotion, rollback, and failure

**Promote a new board** (the role of `scripts/edge-deploy.sh` — see §7, to be authored):

```
1. npm run build                # vite → priv/static/board/board-<hash>.js (+ manifest)
2. upload board-<hash>.js       # → edge.codemoji.games, long immutable cache
3. rewrite manifest.json        # { "board": ".../board-<hash>.js" }, short cache
   └─ within ~10s (Edge TTL) every new mount imports the new bundle. No release, no socket drop.
```

**Rollback:** rewrite `manifest.json` to a previous hash. Because old hashes are immutable and never
deleted, rollback is instant and safe.

**Failure modes:**

| Situation | Behaviour |
|---|---|
| Pointer unreachable / malformed | `Edge.board_url/0` falls back to `BOARD_ASSET_URL` |
| Pointer + fallback both empty | `data-bundle` is empty → the hook logs an error and returns; the shell renders but the board does not mount |
| Bundle 404 / no `mount` export | the hook logs an error and returns; no crash; LiveView shell is unaffected |

## 7. Status & the contract to keep

- **`scripts/edge-deploy.sh` ships the board.** Build → upload hashed-immutable → flip the pointer →
  verify (with `--dry-run` and `--rollback`). Standing up the dedicated `edge.codemoji.games` bucket +
  custom domain and running the first deploy is [edge-bucket-setup.md](edge-bucket-setup.md).
- **Until the first deploy, the board is absent in dev.** The pointer resolves to nothing and
  `BOARD_ASSET_URL` is unset, so `data-bundle` is **empty** — `/game/:gam` renders the shell + server
  props but no React UI (the expected deferred state, asserted by the e2e board-shell story).
- **The cross-swap contract** is the load-bearing rule. Because the edge bundle and the engine can be
  at different versions at the same instant, keep them compatible:
  - `mount(el, props, bridge)` — the signature in `index.tsx`.
  - `BoardProps` — `types.ts` ↔ `GameLive.board_props/3`, moved together.
  - the bridge events — `submit_guess`/`lock`/`unlock` (out), `board:update`/`guess_rejected`/
    `revealed`/`golden_win` (in).
  - **`apiVersion`** — the roadmap prescribes carrying an `apiVersion` in the props and bumping it only
    when the shape changes; it is **not yet present** in `types.ts`/`board_props/3`. Add it before the
    edge bundle and the engine are allowed to skew.

## 8. Map

[render-stack.md](render-stack.md) · [rendering.md](rendering.md) · [dev-and-testing.md](dev-and-testing.md)
· [edge-bucket-setup.md](edge-bucket-setup.md) · source: [`edge.ex`](../../apps/codemojex/lib/codemojex/edge.ex),
[`edge-deploy.sh`](../../apps/codemojex/scripts/edge-deploy.sh),
[`app.js`](../../apps/codemojex/assets/js/app.js),
[`vite.config.ts`](../../apps/codemojex/assets/vite.config.ts).
