# Codemojex · The Mini App Render Stack

How the Codemoji Telegram Mini App is rendered — a **three-tier** stack laid *beside* the existing
JSON API + WebSocket-channel engine, not replacing it. This is the hub for three deep dives:

- **[LiveReact hot swap](livereact-hot-swap.md)** — the React game ships from the edge and swaps
  without a redeploy.
- **[Rendering](rendering.md)** — how each tier renders and how state flows server ⇆ game.
- **[Developing & testing in the browser](dev-and-testing.md)** — boot it locally, the auth gate, and
  the Playwright e2e harness.

> **TL;DR.** Tier 1 is a static welcome (no framework). Tier 2 is a server-rendered **LiveView** lobby.
> Tier 3 is a **LiveReact** game *island*: `CodemojexWeb.GameLive` is the shell, it feeds the React
> game props from `Codemojex.View`, and the **game bundle is fetched from `edge.codemoji.games` at
> runtime** (so it hot-swaps independently of the release). The game never scores — a guess is
> enqueued and the score returns asynchronously over PubSub. The JSON API + `RoomChannel` engine are
> untouched.

This stack landed 2026-06-27 (commits `0248159e` overlay · `b6951541` dev fixes · `5edc947c` e2e),
overlaying the bundle authored in
[`docs/codemojex-tma/codemojex-tma.roadmap.md`](../../../docs/codemojex-tma/codemojex-tma.roadmap.md).

---

## 1. The three tiers

| Tier | Screen | Rendering | Framework JS shipped | State origin |
|---|---|---|---|---|
| **1** | Welcome | Static HTML from `static.codemoji.games` | none | none |
| **2** | Lobby + rooms | Server-rendered, diff-patched (LiveView) | LiveView client only | `Codemojex.View.lobby/0`, patched to the DOM |
| **3** | Board | Client island, adopted from server props | LiveView client **+ edge game bundle** (loaded on entry) | `Codemojex.View.game_view/1` + leaderboard once, plus local pick state |

The dividing line is **"a fixed byte sequence vs a per-request render"**, not "front end vs back end":

```
                         ┌──────────────────────────────────────────────┐
                         │  static.codemoji.games  • welcome/ (Tier 1)   │
                         │  edge.codemoji.games    • game-<hash>.js +    │
                         │    manifest.json (Tier 3 React — content-hashed│
                         │    the asset that changes most often)         │
                         └───────────────▲──────────────────────────────┘
                                         │ dynamic import (browser)
                                         │ pointer GET (server, cached 10s)
   browser ───────────────► ┌───────────┴───────────────────────────────┐
   (Telegram WebView)       │  the codemojex Fly machine (always-on)     │
                            │  • PageController "/"  (legacy landing)    │
                            │  • LobbyLive  /lobby   (Tier 2)            │
                            │  • GameLive   /game/:gam (Tier 3 shell)    │
                            │  • /api/*  JSON API   ·  /socket RoomChannel│
                            │  • the engine: Rooms/Guesses/Scoring/Board │
                            └────────────────────────────────────────────┘
```

## 2. The one seam: the game island

Tiers 2 and 3 are plain LiveView. The *only* framework boundary is the React game, and it is held
together by a **three-part contract** that both sides must keep in lockstep across an edge swap:

1. **The mount signature** — `mount(el, props, bridge)` (in [`assets/src/index.tsx`](../../apps/codemojex/assets/src/index.tsx)).
2. **The `GameProps` shape** — declared in [`assets/src/types.ts`](../../apps/codemojex/assets/src/types.ts), built by `GameLive.game_props/3`.
3. **The bridge events** — `submit_guess`/`lock`/`unlock` out; `game:update`/`guess_rejected`/`revealed`/`golden_win` in.

Everything else — React version, CSS, component tree — lives entirely inside the game bundle. See
[rendering.md](rendering.md) for the data/event flow and [livereact-hot-swap.md](livereact-hot-swap.md)
for how the bundle is delivered.

## 3. The request lifecycle (welcome → lobby → game)

```
Telegram opens the Mini App
        │
        ▼
[Tier 1] welcome (edge)  ──►  forwards tg.initData as the `tg_init` cookie, links to /lobby
        │
        ▼  GET /lobby     (:browser pipeline → CodemojexWeb.MiniAppAuth)
[auth]  MiniAppAuth: tg_init cookie → InitData.verify → resolve_player_by_tg → Session.mint
        │               → put_session("ses")           (the single SES writer on the browser path)
        ▼
[Tier 2] LobbyLive.mount: Session.resolve(ses) → stream rooms (Codemojex.View.lobby/0)
        │   "Enter Room" (phx-click) → Codemojex.join_room/2 → {:ok, GAM} → push_navigate
        ▼  /game/<GAM>
[Tier 3] GameLive.mount: game_view/1 + leaderboard + history → game_props → render #game-root
        │   EdgeReact hook: import(Edge.game_url()) → mount(el, props, bridge)
        ▼
   the game is live; picks are local, the submit crosses the wire, the score returns over PubSub
```

If there is no valid session at any browser route, the LiveView `mount` redirects (`/lobby` → `/`,
`/game/:gam` → `/lobby`). **That redirect is the auth gate, not a bug** — see
[dev-and-testing.md §4](dev-and-testing.md).

## 4. The modules (file → role)

| File | Role |
|---|---|
| [`lib/codemojex_web/router.ex`](../../apps/codemojex/lib/codemojex_web/router.ex) | `:browser` pipeline + `live_session` for `/lobby`, `/game/:gam`; all `/api/*` routes preserved |
| [`lib/codemojex_web/endpoint.ex`](../../apps/codemojex/lib/codemojex_web/endpoint.ex) | the `/live` socket + `Plug.Session`; the existing `/socket` (`UserSocket`) kept |
| [`lib/codemojex_web/mini_app_auth.ex`](../../apps/codemojex/lib/codemojex_web/mini_app_auth.ex) | browser-pipeline auth: SES from session, else `tg_init` handshake |
| [`lib/codemojex_web/live/lobby_live.ex`](../../apps/codemojex/lib/codemojex_web/live/lobby_live.ex) | Tier 2 — room cards (streams), `"lobby"` PubSub, enter-room |
| [`lib/codemojex_web/live/game_live.ex`](../../apps/codemojex/lib/codemojex_web/live/game_live.ex) | Tier 3 shell — props, the game mount point, the async submit round-trip |
| [`lib/codemojex/edge.ex`](../../apps/codemojex/lib/codemojex/edge.ex) | `game_url/0` — resolves the edge bundle pointer (cached, fallback) |
| [`lib/codemojex_web/components/layouts.ex`](../../apps/codemojex/lib/codemojex_web/components/layouts.ex) | the root HTML shell (loads `app.js`/`app.css`) + flash group |
| [`assets/js/app.js`](../../apps/codemojex/assets/js/app.js) | the `LiveSocket` + the `EdgeReact` hook (dynamic-import + bridge) |
| [`assets/src/index.tsx`](../../apps/codemojex/assets/src/index.tsx) | the game bundle entry — `mount(el, props, bridge)` |
| [`assets/src/types.ts`](../../apps/codemojex/assets/src/types.ts) | the `GameProps`/`Bridge`/`GameView` contract |

## 5. Invariants (carried by every change to this stack)

1. **The game never scores.** A guess is acknowledged when *enqueued*, not when scored; the score
   returns out-of-band as `{:scored, …}`. (`GameLive.handle_event("submit_guess", …)`.)
2. **The secret and other players' guesses never cross the boundary.** `Codemojex.View` withholds them;
   a *golden* game also withholds per-guess scores until its sealed reveal.
3. **The game bundle is edge-delivered**, not baked into the release — a game change is an edge
   upload + pointer flip, not a `fly deploy`.
4. **The cross-swap contract is versioned in lockstep.** `types.ts` ↔ `GameLive.game_props/3` move
   together; an `apiVersion` in the props is prescribed (not yet present — see hot-swap §7).
5. **One SES writer on the browser path** (`MiniAppAuth`), mirroring the JSON API's `AuthController`.
   No dev auth bypass.
6. **The JSON API + `RoomChannel` are untouched.** This stack is additive.

## 6. Map

Deep dives: [livereact-hot-swap.md](livereact-hot-swap.md) · [rendering.md](rendering.md) ·
[dev-and-testing.md](dev-and-testing.md) · [edge-bucket-setup.md](edge-bucket-setup.md). Inbound bot transport:
[webhook-vs-polling.md](webhook-vs-polling.md). Source: [`apps/codemojex/`](../../apps/codemojex).
E2E harness: [`node/codemojex-e2e/`](../../../node/codemojex-e2e). Roadmap:
[`docs/codemojex-tma/codemojex-tma.roadmap.md`](../../../docs/codemojex-tma/codemojex-tma.roadmap.md).
Game canon: [`docs/codemojex/`](../../../docs/codemojex).
