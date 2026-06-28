# Codemoji · Three-Tier Rendering on the As-Built Engine

This plan revises the original three-tier rendering roadmap against the fetched `fiberfx@echo_mq` source, so every server call it names targets a function that exists in `apps/codemojex/`. The shape of the front end is unchanged — a static welcome, a LiveView lobby, and a React board — but the engine underneath is not a sketch: it is a Phoenix release whose entities are branded components, whose guesses are jobs scored asynchronously on per-player lanes, and whose reads withhold the secret by construction. The reconciliation matters most at one seam: the original plan scored a guess synchronously inside the LiveView and returned the result; the real engine enqueues the guess and the score arrives later over PubSub. The board, the routes, and the state handoffs are reworked around that fact. The full integration source ships in `codemojex-livereact.zip`.

## The engine this renders, as built

The `codemojex` app already runs as a single Fly machine at `codemoji.games` with a JSON API and a `/socket` channel (`CodemojexWeb.RoomChannel`). This roadmap adds a LiveView and LiveReact surface beside that API; it does not replace the engine. Five facts about the engine drive the rest of the plan.

**Entities are branded ids.** A game is a `GAM`, a room a `ROM`, a player a `PLR`, a session a `SES`, a queue job a `JOB`, a stored guess a `GES`, an emoji set an `EMS` — each minted by `EchoData.BrandedId.generate!/1` and parsed by `EchoData.BrandedId.parse/1`, which returns `{:ok, namespace, snowflake}` or `:error`. Validation on the render path is that parse plus a namespace check, not a regex.

**Rooms are templates; a game is one play in a room.** `Codemojex.join_room/2` starts a game when the room is waiting — snapshotting the room's emoji set and props, minting a `GAM`, drawing a secret — or enters the active game otherwise, and it returns the `GAM`. So the lobby lists `ROM` rooms, and selecting one yields a `GAM` to navigate to. This is the correction to the original route: the board is keyed by the game, at `/game/:gam`, not by the room id.

**Play is asynchronous.** `Codemojex.submit/3` takes a game, a player, and exactly six emoji codes. It validates the guess against the game's snapshotted keyboard, charges the wallet on the room's currency through `Codemojex.Wallet`, and enqueues a `JOB` on the player's lane through `EchoMQ.Lanes` — the lane named by the `PLR`, so the bus rotates service across players and one fast tapper cannot starve the field. It returns `{:ok, job}` or `{:error, reason}`; it does not score. The host never scores. This single fact rewrites the submit round-trip from the original plan.

**One authority scores, and it broadcasts.** `Codemojex.ScoreWorker`, an EchoMQ consumer, drains the guess queue, reads the immutable secret through `Codemojex.Cache`, scores with the pure linear engine `Codemojex.Scoring.score/2` — points are `100 - 20*d` for distance `d`, out of 600 — writes a `GES` through `Codemojex.Store`, records the player's best on `Codemojex.Board` (a Valkey sorted set per game), and for a classic game broadcasts `{:scored, %{game: g, player: name, pct: p, eff: e}}` on the `Phoenix.PubSub` topic `"game:"<>g` [5]. The `RoomChannel` already consumes that topic; the board LiveView consumes the same one. A golden game stores the guess but emits no per-guess feedback until its sealed reveal — the blind contract.

**Reads withhold the secret.** `Codemojex.View` is the player-facing read surface, and the privacy invariant is built into it: nothing it returns carries the secret, and nothing carries another player's guesses. `View.lobby/0` returns the room cards from the screenshot — prize in USD, emoji count, cells, the leader's progress. `View.game_view/1` returns the keyboard snapshot, timer, pool, and totals, never the secret. `View.leaderboard/2` returns `{player, max_score}` pairs from the board. `View.my_history/3` returns only the asking player's own attempts, from Postgres. For a golden game before reveal, the view widens the gate further and withholds scores entirely. The board renders from these reads, so it cannot leak what the server does not send.

Behind those reads, the system of record is Postgres through `Codemojex.Store`; the near-cache `Codemojex.Cache` holds the immutable secret and emoji set over an `EchoStore` L1-ETS-over-L2-Valkey tier; the leaderboard is `Codemojex.Board` in Valkey. A game's mutable status is read from the system of record, because the cached blob's status can lag a state change even though the secret it caches is immutable. The economy and settlement are server-only: a guess charge is booked on submit, and a game's payout runs as a separate settle-queue job through `Codemojex.Settle` and `Codemojex.Rooms.close_game/1` — the move-then-settle split, where the guess queue competes and the settle queue pays. The relevant modules sit in `apps/codemojex/lib/codemojex/game.ex` (which holds `Codemojex.Guesses`, `Codemojex.ScoreWorker`, `Codemojex.Settle`, and the `Codemojex` facade), `rooms.ex`, `board.ex`, `scoring.ex`, and `view.ex`.

## Locked decisions and ship target

The welcome screen is static HTML, served from `static.codemoji.games`. The lobby and room list are a `CodemojexWeb.LobbyLive` using HEEx, streams, and PubSub. Selecting "Enter Room" calls `Codemojex.join_room/2` and navigates to the returned `GAM` at `/game/:gam`, where `CodemojexWeb.GameLive` hosts the React board. The board's component bundle is served from the edge and mounted through a client hook, so a board change is an edge upload rather than a release — the mechanism is the subject of the companion article `codemoji.static-edge.md`. The backend stays in Elixir and is the engine above: Ecto owns the economy through `Codemojex.Wallet`, the leaderboard lives in `Codemojex.Board`, and the board reaches both only as props from `Codemojex.View`. The target is a working end-to-end path on Fly this week: welcome, into the lobby, into a room, a guess submitted, the leaderboard updating from the scored broadcast.

## The rendering model: three tiers, three state origins

Each tier renders with the lightest mechanism that fits its job, and each initializes its state at the cheapest layer available.

| Tier | Screen | Rendering | Framework JS shipped | State origin |
|---|---|---|---|---|
| 1 | Welcome | Static HTML from static.codemoji.games | None | None |
| 2 | Lobby + rooms | Server-rendered, diff-patched (LiveView) | LiveView client only | `Codemojex.View.lobby/0`, patched to the DOM |
| 3 | Board | Client island, adopted from server props | LiveView client + edge board bundle, loaded on entry | `Codemojex.View.game_view/1` + leaderboard once, plus local pick state |

### Tier 1 — Static HTML welcome

The front door ships no framework runtime: HTML and CSS served from `static.codemoji.games`, so first paint is bound by transfer rather than by a bundle parse. Its one job is to move the player to the lobby; it forwards Telegram `initData` to the LiveView as a short-lived cookie and links to `/lobby`.

### Tier 2 — LiveView lobby and rooms

The lobby is the screen in the screenshot: the room cards, the live prize pool, the archive. It is server-rendered HTML that LiveView keeps current with diffs over a WebSocket, and React is absent from it. The cards come from `Codemojex.View.lobby/0` as a stream, so a change to one card patches that card in place [4]; pool changes arrive over a `"lobby"` topic and a low-frequency re-read. There is no client store on the lobby — the server holds the truth and the DOM follows it.

### Tier 3 — React board island

The board is the one screen with local, high-frequency, optimistic interaction — tapping emoji into slots before a guess is submitted — so it renders as a React island. The LiveView seals the mount region, feeds it props from `Codemojex.View.game_view/1` plus the leaderboard, and exposes a bridge so the island can call back over the live socket [1][3]. The picks in progress live in React state; everything durable comes from and returns to the server. What is different from a stock LiveReact wiring is where the component bundle lives: it is fetched from `static.codemoji.games` at room entry by a client hook, not compiled into the release. That keeps the board's appearance on a UI cadence while the engine stays on its own — covered in `codemoji.static-edge.md`.

## Avoiding the two costs: JS load and state init

A single-page app pays twice on every screen — it downloads a large client bundle, then boots it into an empty state and fetches data to fill it. The three-tier model removes both.

The heavy framework is scoped to the one screen that needs it. The welcome ships no framework; the lobby ships only the LiveView client; the board bundle is fetched on room entry, so the pre-game surface and the bulk of a session never download it [1]. A player who browses rooms and never enters one pays nothing for React.

State is initialized once, on the server, where the data already lives. When the LiveView handles a navigation to the board, it has already resolved the `GAM` and read `Codemojex.game_view/1` and the leaderboard, so it renders the island with that data in its props and React adopts a populated state on mount. There is no empty-then-fetch, no spinner, and no second connection. Ongoing updates ride the same socket: when the score worker finishes a guess and broadcasts `{:scored, …}`, the LiveView re-reads the view and pushes a prop diff; the island never opens its own API channel and never polls. The only state the client owns is the in-flight picks, transient until submit.

## How state crosses each boundary

The path is a chain of cheap handoffs, reworked around the asynchronous engine. Welcome to lobby is a navigation into `/lobby`; the lobby mounts, resolves the player's `SES` from the session, streams the cards from `Codemojex.View.lobby/0`, and subscribes to `"lobby"`. "Enter Room" calls `Codemojex.join_room/2`, which starts or enters the game and returns the `GAM`, and the lobby `push_navigate`s to `/game/<gam>`.

At the board, `GameLive.mount/3` resolves the `SES` to a `PLR`, parses the `GAM` with `EchoData.BrandedId.parse/1`, reads `Codemojex.game_view/1`, and builds the board props — the view, the named leaderboard from `Codemojex.leaderboard/2`, and the player's own `Codemojex.my_history/3`. The island mounts populated. A submit then goes out as `pushEvent("submit_guess", %{emojis: picks})` with six codes; the LiveView calls `Codemojex.submit/3`, which charges the wallet and enqueues a `JOB`, and returns `{:ok, job}` — nothing is scored yet. The board clears its picks; if the enqueue is refused, the LiveView pushes `guess_rejected` with the reason.

The score returns out of band. `Codemojex.ScoreWorker` scores the queued guess, writes the `GES` and the board, and broadcasts `{:scored, …}` on `"game:"<>gam`. `GameLive` is subscribed; on that message it re-reads `Codemojex.game_view/1` and the leaderboard and pushes them to the island as a `board:update` prop diff. A golden game's sealed close arrives as `{:revealed, …}`, and a tournament win as `{:golden_win, …}`, both forwarded to the island. Money is computed and recorded only on the server, across the submit charge, the score worker, and the settle queue; the client renders the verdict.

## The hot-swap board, in brief

The board's component bundle is built as a content-hashed ES module, uploaded to the `static.codemoji.games` Tigris bucket, and named by a short-cached `manifest.json` pointer. `Codemojex.Edge.board_url/0` resolves that pointer at runtime, `GameLive` renders the URL into the mount point, and the `EdgeReact` client hook dynamic-imports it and calls the bundle's `mount(el, props, bridge)`. Promoting a new board is an upload and a pointer flip — no `mix release`, no socket drop. The contract that the two sides share across a swap is the `mount` signature, the `BoardProps` shape in `assets/react/types.ts`, and the bridge events. The full rationale and the trade it makes are in `codemoji.static-edge.md`.

## Implementation plan, day by day

### Day 1 — Island boundary, board mounts with props

Add `{:phoenix_live_view, "~> 1.0"}` and `{:live_react, "~> 1.1"}` to `apps/codemojex/mix.exs`, and add the `:live_view`/`:html` helpers to `codemojex_web.ex`. Add the `/live` socket and the session options to `endpoint.ex`, and a `:browser` pipeline plus `live "/game/:gam", GameLive` to `router.ex`. Stand up `GameLive` rendering the board mount point with props built from `Codemojex.View.game_view/1`. End of day: navigating to a game route renders the board with server-supplied props, no interactivity yet.

### Day 2 — Resolver and the real reads

In `GameLive.mount/3`, resolve the player's `SES` with `Codemojex.Session.resolve/1`, parse the `GAM` with `EchoData.BrandedId.parse/1`, and read `Codemojex.game_view/1`; redirect to the lobby on a miss. Build the board props from the view, `Codemojex.leaderboard/2`, and `Codemojex.my_history/3`, resolving player handles through `Codemojex.Store.player/1`. The board now mounts with the real game state, resolved once on the server.

### Day 3 — The asynchronous submit round-trip

Wire the guess submit to `pushEvent("submit_guess", %{emojis: picks})` from the board's actions, with six codes. Handle it in `GameLive` by calling `Codemojex.submit/3` and, on `{:error, reason}`, pushing `guess_rejected`. Subscribe `GameLive` to `"game:"<>gam` on mount and handle `{:scored, _}` by re-reading the view and the leaderboard and pushing a `board:update` prop diff. Keep the picks in React state so only the submit crosses the wire. Keep the existing Russian copy in the island for now and note any gettext consolidation as a follow-up.

### Day 4 — Lobby streams, PubSub, navigation

Build `LobbyLive`: stream the cards from `Codemojex.View.lobby/0`, subscribe to `"lobby"`, and turn "Enter Room" into `Codemojex.join_room/2` followed by `push_navigate` to `/game/<gam>`. Re-read and upsert the cards on a low-frequency tick and on a `{:lobby_changed}` nudge, with no React on this page. Link the static welcome into the lobby; from there, navigation between lobby and board is live, which gives the single-page feel without a single-page bundle.

### Day 5 — Auth, edge board, harden, ship

Add the `CodemojexWeb.MiniAppAuth` browser plug — the same handshake as `AuthController.handshake/2` (verify `initData`, resolve the `PLR`, mint a `SES`) but landing the `SES` in the session for the LiveView to read. Build the board bundle and wire `scripts/edge-deploy.sh` so the board arrives from `static.codemoji.games` and `Codemojex.Edge` resolves the pointer. Defer server-side rendering: because the board sits behind a navigation rather than first paint, a client render from server props is acceptable, and it keeps the Node worker off the board path for now; turn SSR on later only if a mount flash proves visible [2]. Handle reconnect — LiveView re-sends props and the sealed island survives — fit the Telegram Mini App viewport, deploy to Fly, and smoke-test the whole path.

## Code sketches

The board host, resolving the player and the `GAM`, reading the view, and rendering the edge-loaded island — the asynchronous submit returns only the enqueue, and the score arrives over PubSub:

```elixir
defmodule CodemojexWeb.GameLive do
  use CodemojexWeb, :live_view
  alias Codemojex.{Edge, Session, Store}

  def mount(%{"gam" => gam}, session, socket) do
    with {:ok, %{plr: plr}} <- Session.resolve(session["ses"]),
         {:ok, "GAM", _snow} <- EchoData.BrandedId.parse(gam),
         view when is_map(view) <- Codemojex.game_view(gam) do
      if connected?(socket), do: Phoenix.PubSub.subscribe(Codemojex.PubSub, "game:" <> gam)
      {:ok,
       socket
       |> assign(player: plr, game: gam, board_bundle: Edge.board_url())
       |> assign(board_props: board_props(gam, plr, view))}
    else
      _ -> {:ok, socket |> put_flash(:error, "Room not found") |> push_navigate(to: ~p"/lobby")}
    end
  end

  # enqueue only — the engine scores on its own lane and broadcasts {:scored, …}
  def handle_event("submit_guess", %{"emojis" => emojis}, socket) when is_list(emojis) do
    case Codemojex.submit(socket.assigns.game, socket.assigns.player, emojis) do
      {:ok, _job} -> {:noreply, socket}
      {:error, reason} -> {:noreply, push_event(socket, "guess_rejected", %{reason: to_string(reason)})}
    end
  end

  # the score lands here, out of band — re-read the view, push a prop diff
  def handle_info({:scored, _payload}, socket) do
    %{game: gam, player: plr} = socket.assigns
    view = Codemojex.game_view(gam)
    {:noreply, push_event(socket, "board:update", board_props(gam, plr, view))}
  end

  defp board_props(gam, plr, view) do
    %{
      view: view,
      leaderboard: Enum.map(Codemojex.leaderboard(gam, 20), fn {p, s} ->
        %{player: p, name: name(p), score: s, is_me: p == plr}
      end),
      history: Codemojex.my_history(gam, plr, 50),
      me: plr
    }
  end

  defp name(plr), do: (Store.player(plr) || %{name: "?"}).name
end
```

The board owns its own React and exports the only cross-swap contract — `mount(el, props, bridge)`; the submit sends six codes and the score returns as a `board:update`:

```tsx
export function mount(el: HTMLElement, props: BoardProps, bridge: Bridge) {
  const root = createRoot(el);
  const render = (p: BoardProps) => root.render(<BoardScreen {...p} bridge={bridge} />);
  render(props);
  return { update: (p: BoardProps) => render(p), unmount: () => root.unmount() };
}

// inside BoardScreen: picks are local; only the submit crosses the wire
const submit = () => {
  if (picks.length !== 6) return;
  bridge.pushEvent("submit_guess", { emojis: picks }); // XXYY codes
  setPicks([]);
};
```

The lobby stream and the join that returns a `GAM`:

```elixir
defmodule CodemojexWeb.LobbyLive do
  use CodemojexWeb, :live_view
  alias Codemojex.Session

  def mount(_params, session, socket) do
    case Session.resolve(session["ses"]) do
      {:ok, %{plr: plr}} ->
        if connected?(socket), do: Phoenix.PubSub.subscribe(Codemojex.PubSub, "lobby")
        {:ok, socket |> assign(player: plr) |> stream(:rooms, cards())}
      _ ->
        {:ok, redirect(socket, to: ~p"/")}
    end
  end

  def handle_event("enter_room", %{"id" => room}, socket) do
    case Codemojex.join_room(room, socket.assigns.player) do
      {:ok, gam} -> {:noreply, push_navigate(socket, to: ~p"/game/#{gam}")}
      {:error, reason} -> {:noreply, put_flash(socket, :error, to_string(reason))}
    end
  end

  defp cards, do: Enum.map(Codemojex.lobby(), fn c -> Map.put(c, :id, c.room) end)
end
```

## Full source

The complete integration overlays `apps/codemojex/` and ships in `codemojex-livereact.zip`. It contains, as new or changed files: `Codemojex.Edge` (the edge pointer resolver); `codemojex_web.ex`, `endpoint.ex`, and `router.ex` extended for LiveView; `CodemojexWeb.MiniAppAuth` (the browser handshake); `CodemojexWeb.Layouts`; `LobbyLive` and `GameLive`; the `mix.exs` deps; a `config/runtime.exs` delta; the static welcome; the committed `app.css`; the React board under `assets/react/` (the `mount` entry, `BoardScreen`, the keyboard, slots, leaderboard, and info components, and the `types.ts` contract); the `app.js` LiveView client with the `EdgeReact` hook; the two vite configs; and `scripts/edge-deploy.sh`. Every Elixir module parses under an Elixir syntax gate; a full umbrella `mix compile` was not run in the authoring environment, since the `echo_data` native codec and the Postgres-backed boot were not provisioned there — compile inside the umbrella before shipping. The `README.md` in the archive maps each file to the engine call it binds to.

## Boundaries and risks

The LiveView owns the page DOM and the React island is a sealed subtree it will not patch, which is what lets the two renderers share a page [3]. The branded-id contract is checked on the Elixir side with `EchoData.BrandedId.parse/1`, so the side that owns the data validates the input. The asynchronous submit is the load-bearing change from the original plan: a guess is acknowledged when enqueued, not when scored, so the board's optimistic clear and the later `board:update` are two separate events, and the UI must read as responsive across that gap rather than waiting for a synchronous result. A golden game scores blind, so the board must tolerate a view that withholds scores until `{:revealed, …}`. Decoupling the board to the edge relocates the old deploy coupling into a versioned props contract, which can skew between an edge bundle and the engine; an `apiVersion` in the props and `types.ts` kept in lockstep with the prop builder are the discipline that pays for the freedom. The economy is never computed on the client. The remaining schedule risk is any i18n consolidation, deferred rather than attempted in the same week.

## References

1. mrdotb — live_react (lazy-loading, hooks, Vite, SSR): [hexdocs.pm/live_react](https://hexdocs.pm/live_react)
2. mrdotb — live_react Server-Side Rendering guide: [github.com/mrdotb/live_react](https://github.com/mrdotb/live_react/blob/main/guides/ssr.md)
3. Phoenix — LiveView JavaScript interoperability (hooks, pushEvent, phx-update): [hexdocs.pm/phoenix_live_view/js-interop.html](https://hexdocs.pm/phoenix_live_view/js-interop.html)
4. Phoenix — LiveView streams for large collections: [hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream/4](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream/4)
5. Phoenix — PubSub broadcast/subscribe (the topic the scored event rides): [hexdocs.pm/phoenix_pubsub](https://hexdocs.pm/phoenix_pubsub)
