# Codemoji · Static assets at the edge versus embedded in Phoenix

<show-structure depth="2"/>

Codemoji runs as one Telegram Mini App at `codemoji.games`, served by a single Phoenix machine on Fly. That one machine raises a design question the moment a React board enters the picture: where does each piece of the front end come from? Three surfaces are in play — a welcome screen, a lobby, and a play board — and treating them as one bucket of "assets" hides the decision that matters. This article separates them, places each where its change-rate and render model want it, and shows how the board's React bundle ships from `static.codemoji.games` independent of the engine machine, so a board change is an edge upload rather than a redeploy.

## The machine we deploy onto

The deployment is deliberately small, and its shape drives everything here. The `codemojex` release runs as a single Fly machine in `fra` with `min_machines_running = 1` and `auto_stop_machines = false`, kept always-on so a live game's `/socket` session is never reaped mid-play. The public host is the apex `codemoji.games`. The runtime image is based on `node:22-bookworm-slim`: Node is present, but as the Dockerfile states in as many words, it is a runtime, not a build stage — there is no npm or vite step in the image, and nothing JavaScript is built or fetched during the release. The Node binary is reserved for a forthcoming server-side-rendering worker that will run beside the BEAM.

Two facts follow from that. First, any JavaScript the browser needs must arrive from somewhere other than an in-image build: either committed into `priv/static` ahead of the release, or fetched from an external origin at runtime. Second, because the machine is single and always-on, every redeploy is a rolling replace of the one node that is holding open game sockets — so the cost of coupling a front-end change to a release is paid in socket churn, not merely in build minutes.

There is already an external durable substrate in the stack. The `echo_store` tier folds its durable pages to Tigris through the Graft committer. Tigris is therefore not a new dependency to justify; it is where the system already keeps bytes that outlive a machine. Serving static front-end files from a Tigris public bucket is an extension of a path that exists, not a green-field addition.

## Three surfaces, three homes

The instinct to put "the front end" in one place fails because the three surfaces differ in what they are, not only in where they live.

The **welcome** screen is a fixed sequence of bytes: an HTML shell, a stylesheet, a logo, and a short script that forwards Telegram `initData` and links into the lobby. It has no per-request content. Its right home is a cache-fronted bucket, where first paint is bound by transfer rather than by a server render or a bundle parse.

The **lobby** is not an asset at all. It is the room list from the screenshot — names, live prize pools in USD, emoji counts, progress bars — rendered per request from `Codemojex.View.lobby/0` and patched over a WebSocket as pools move. It is a server render that depends on live state, so it belongs on the machine, as a LiveView. Pushing it to a bucket would mean giving up the live patching that is its reason for existing.

The **board** is the subtle one, because it is two things wearing one name. There is the board's *server state* — the game view, the leaderboard, the player's own history, all from `Codemojex.View` — which is a per-request render and stays on the machine. And there is the board's *structure* — the React component tree that paints slots, a keyboard, and a leaderboard, and that iterates on its own schedule as the product's look changes. The structure is a fixed bundle between edits, which makes it an asset; but it is the asset that changes most often. That combination is what the rest of this article is about.

The dividing line, then, is not "front end versus back end." It is "a fixed byte sequence versus a per-request render." The welcome shell and the board bundle are byte sequences and go to the edge. The lobby and the board's server state are per-request renders and stay on the machine.

## Why the board does not belong in the image

The default LiveReact wiring compiles the React components into the application's own `app.js`: the bundle is built by vite and registered as hooks on the `LiveSocket` [1]. On a multi-machine, build-in-image deployment that is a fine default. On this deployment it has a sharp edge. The board bundle would live inside the release, so every change to a board color, a label, or a layout would require `mix release` and a rolling deploy of the single always-on machine — the machine whose entire reason for staying up is to not drop sockets. UI iteration is frequent and low-risk; engine releases are infrequent and carry real risk on a single node. Binding the first to the second inverts their natural cadence.

The aim is to let the board's structure change at UI cadence while the engine changes at engine cadence. That means the board bundle must leave the image.

## The edge: static.codemoji.games

The board bundle, the welcome shell, and the sprites are served from a Tigris public bucket [3] addressed as `static.codemoji.games` — a subdomain pointed at the bucket by a CNAME, distinct from the apex `codemoji.games` that the machine answers [4]. Three properties make the bucket a safe place to hot-swap code.

Filenames are content-hashed. The board build emits `board-<hash>.js`, where the hash is a digest of the contents, so a new build is a new filename and an old URL never silently changes meaning. Hashed files are served with a long immutable cache header, because a content address can never go stale — the bytes behind `board-<hash>.js` are fixed for all time [6]. A root `manifest.json` pointer names the current hash and is served with a short cache, because the pointer is the one thing that moves. The welcome shell is served with a short cache for the same reason: it is small, and we want a change visible promptly.

Promotion is therefore an upload plus a pointer rewrite. The `edge-deploy.sh` script builds the bundle, uploads `board-<hash>.js` under the immutable cache, and rewrites `manifest.json` to point at the new hash. Rollback is the same operation aimed at a previous hash. Nothing about this touches the machine.

## The runtime pointer

For the machine to serve a bundle it does not contain, it has to resolve the pointer at render time. That is the whole of `Codemojex.Edge`:

```elixir
defmodule Codemojex.Edge do
  @pointer "https://static.codemoji.games/manifest.json"

  # Resolve the current board bundle url from the edge pointer, cached ~10s in
  # :persistent_term. Reuses the app's existing :inets/:ssl httpc — no new dep.
  def board_url do
    case cached() do
      url when is_binary(url) -> url
      _ -> resolve_and_cache()
    end
  end

  defp resolve_and_cache do
    url = fetch_pointer() || System.get_env("BOARD_ASSET_URL")
    if is_binary(url), do: :persistent_term.put(@pt_key, {url, now() + 10_000})
    url
  end
end
```

`GameLive` reads `Codemojex.Edge.board_url/0` on mount and renders the URL into the board's mount point as a data attribute, where a LiveView client hook reads it [2]. The browser hook dynamic-imports that URL and hands the imported module the server props [5]. A new board therefore reaches a player like this: `edge-deploy.sh` uploads a hash and flips the pointer; within the ten-second cache window the machine resolves the new URL; the next board mount imports the new bundle. No `mix release`, no `fly deploy`, no socket drop. A failed pointer fetch falls back to a per-release `BOARD_ASSET_URL`, so a bucket blip degrades to the last known bundle rather than a blank board.

The browser side is a thin loader. The board bundle exports a single `mount(el, props, bridge)` entry and owns its own React; the host's `app.js` carries only the `LiveSocket` and the loader hook:

```javascript
const EdgeReact = {
  async mounted() {
    const props = JSON.parse(this.el.dataset.props || "{}");
    const mod = await import(/* @vite-ignore */ this.el.dataset.bundle);
    this._handle = mod.mount(this.el, props, {
      pushEvent: (e, p) => this.pushEvent(e, p),
      onServerEvent: (cb) => { (this._l ||= new Set()).add(cb); return () => this._l.delete(cb); },
    });
    this.handleEvent("board:update", (p) => this._handle.update(p)); // scored -> prop diff
  },
  destroyed() { this._handle?.unmount(); },
};
```

## What the machine still renders

Moving the board's structure to the edge does not thin out the machine's job; it sharpens it. The machine still renders the lobby as a LiveView. It still runs the board's *shell* — the `GameLive` that resolves the branded `GAM`, reads `Codemojex.game_view/1` and the leaderboard, and supplies them as props. It still owns every authoritative concern: a guess goes to `Codemojex.submit/3`, the score is computed by the engine's consumer, and the result returns over the `"game:"<>game` PubSub topic as a prop diff. The secret and other players' guesses never cross to the client, because `Codemojex.View` withholds them on the server. The edge holds the board's appearance; the machine holds its truth.

Server-side rendering of the board is deferred in this design, which is what keeps the board purely client-rendered from server props for now. Because the board sits behind a navigation rather than at first paint, a client render from already-resolved props is acceptable, and it keeps the Node worker off the board path while the apex cutover settles. The Node 22 runtime in the image is the provision for turning SSR on later: at that point the worker renders the first board frame on the server by importing the same edge bundle, and the client hydrates it. The bundle's origin does not move when SSR arrives — only who imports it first.

## The contract that replaces the deploy coupling

Decoupling the board from the release does not delete the coupling; it relocates it from a shared deploy to a shared contract. When the board and the engine shipped together, a change to the props a board expected and a change to the props the server sent landed in the same release, so they could not skew. Once the board ships from the edge, the two can move apart, and the only thing holding them together is the shape of what crosses the boundary: the `mount(el, props, bridge)` signature, the `BoardProps` shape declared in `assets/react/types.ts`, and the events the bridge carries. That contract is now load-bearing, and the candid cost of the split is that an edge bundle and an engine can disagree about it. The discipline that pays for the freedom is to version the contract — an `apiVersion` carried in the props, bumped only when the shape changes — and to keep `types.ts` and `GameLive`'s prop builder in lockstep. Backward-compatible board changes ship freely; a breaking change is the one case that still wants both sides coordinated.

## When embedding is the right call

The edge split is not free of cost and is not always the better trade. If a board never needs to change independent of the engine — a stable internal tool, a board that ships once — then compiling it into `app.js` is fewer moving parts and the right answer. The split earns its keep when UI iteration outpaces engine releases, and the single always-on machine sharpens that case, because there every release is a roll of the node holding live sockets. Codemoji sits squarely on the side where the split pays: the board's look is iterated often, the engine is changed rarely, and the machine must stay up. The welcome shell and the board bundle go to `static.codemoji.games`; the lobby and the board's server state stay on `codemoji.games`; the line between them is the line between a fixed byte sequence and a per-request render.

## References

1. mrdotb — live_react (SSR, lazy-loading, hooks, Vite): [hexdocs.pm/live_react](https://hexdocs.pm/live_react)
2. Phoenix — LiveView JavaScript interoperability (hooks, pushEvent, handleEvent): [hexdocs.pm/phoenix_live_view/js-interop.html](https://hexdocs.pm/phoenix_live_view/js-interop.html)
3. Fly.io — Tigris object storage on Fly (buckets, credentials): [fly.io/docs/tigris](https://fly.io/docs/tigris/)
4. Tigris — custom domains for public buckets: [tigrisdata.com/docs/buckets/custom-domain](https://www.tigrisdata.com/docs/buckets/custom-domain/)
5. MDN — dynamic `import()` of ES modules at runtime: [developer.mozilla.org — import](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/import)
6. MDN — HTTP `Cache-Control`, immutable and content-addressed assets: [developer.mozilla.org — Cache-Control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
