# Codemojex · Rendering

How each tier of the [render stack](render-stack.md) produces its UI, and — the load-bearing part —
how game state flows **server ⇆ React island** across an *asynchronous* engine.

> **TL;DR.** Tier 1 is static HTML. Tier 2 (`LobbyLive`) is server-rendered HEEx kept current with
> LiveView diffs. Tier 3 (`GameLive`) is a shell that resolves state once and hands it to a React game
> as props; the game keeps only *local pick state*. A guess is sent over the bridge, **enqueued** by
> `Codemojex.submit/3` (the engine scores on its own lane), and the score returns later as a
> `{:scored, …}` broadcast that `GameLive` turns into a `game:update` prop diff. The game reads as
> responsive across that gap: clear-now, update-later.

---

## 1. Tier 1 — the static welcome

A framework-free HTML shell ([`priv/static/welcome/index.html`](../../apps/codemojex/priv/static/welcome/index.html),
edge-served in prod). Its only job is to hand Telegram `initData` to the LiveView and link onward:

```js
if (tg && tg.initData)
  document.cookie = "tg_init=" + encodeURIComponent(tg.initData) + ";path=/;max-age=120;samesite=lax";
// <a href="/lobby">Играть</a>
```

`MiniAppAuth` consumes that `tg_init` cookie on the next request (see [render-stack.md §3](render-stack.md)).

## 2. Tier 2 — the LiveView lobby

[`LobbyLive`](../../apps/codemojex/lib/codemojex_web/live/lobby_live.ex) is pure LiveView — no React.
The room cards come from `Codemojex.View.lobby/0` as a **stream**, server-rendered as HEEx and
diff-patched:

- `mount/3` resolves `Session.resolve(session["ses"])`; on success it subscribes to the `"lobby"`
  PubSub topic and starts a low-frequency `:tick` (3s), then `stream(:rooms, cards())`. On failure it
  `redirect`s to `/` (the auth gate).
- A live prize pool / room list rides the `"lobby"` topic plus the tick: `handle_info({:lobby_changed}, …)`
  and `handle_info(:tick, …)` both `upsert` the cards (the stream patches only what changed).
- **Enter Room** is a `phx-click="enter_room"`:

  ```elixir
  def handle_event("enter_room", %{"id" => room}, socket) do
    case Codemojex.join_room(room, socket.assigns.player) do
      {:ok, gam}      -> {:noreply, push_navigate(socket, to: ~p"/game/#{gam}")}
      {:error, reason} -> {:noreply, put_flash(socket, :error, reason_text(reason))}
    end
  end
  ```

  `join_room/2` starts or enters the game and returns the `GAM`; the live navigation gives the
  single-page feel without a single-page bundle.

There is no client store on the lobby — the server holds the truth and the DOM follows it.

## 3. Tier 3 — the game shell + the React island

[`GameLive`](../../apps/codemojex/lib/codemojex_web/live/game_live.ex) is the **shell**. It resolves the
player + the `GAM`, reads the privacy-preserving view *once on the server*, and hands it to React as
props — so the game mounts **populated**, with no client fetch and no spinner.

```elixir
def mount(%{"gam" => gam}, session, socket) do
  with {:ok, %{plr: plr}} <- Session.resolve(session["ses"]),
       {:ok, "GAM", _snow} <- EchoData.BrandedId.parse(gam),
       view when is_map(view) <- Codemojex.game_view(gam) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Codemojex.PubSub, "game:" <> gam)
    {:ok, assign(socket, player: plr, game: gam,
                 game_bundle: Edge.game_url(), game_props: game_props(gam, plr, view))}
  else
    _ -> {:ok, socket |> put_flash(:error, "Room not found") |> push_navigate(to: ~p"/lobby")}
  end
end
```

The render emits the sealed mount point (`#game-root`, `phx-update="ignore"`) carrying
`data-bundle` (the edge URL), `data-component`, and `data-props` (`Jason.encode!` of the props). The
`GameIsland` hook imports the bundle and calls `mount(el, props, bridge)` — see
[livereact-hot-swap.md §5](livereact-hot-swap.md).

### 3.1 The props — `game_props/3`

The game's whole initial state, server-resolved (mirrors what `RoomChannel.join` returns, widened with
the player's own history and the named leaderboard):

```elixir
defp game_props(gam, plr, view) do
  %{
    view:        view,                                    # Codemojex.View.game_view/1
    leaderboard: named(Codemojex.leaderboard(gam, 20), plr),  # [%{player, name, score, is_me}]
    history:     Codemojex.my_history(gam, plr, 50),      # the player's OWN guesses
    me:          plr
  }
end
```

The TypeScript mirror is [`game/src/types.ts`](../../../mercury/codemojex/apps/game/src/types.ts)
(`GameProps`, `GameView`, `LeaderRow`, `HistoryRow`). **Keep `types.ts` and `game_props/3` in
lockstep** — they are the cross-swap contract (see hot-swap §7).

### 3.2 The game entry — `mount(el, props, bridge)`

[`game/src/index.tsx`](../../../mercury/codemojex/apps/game/src/index.tsx):

```tsx
export function mount(el: HTMLElement, props: GameProps, bridge: Bridge) {
  const root = createRoot(el);
  const render = (p: GameProps) => root.render(<GameEdge {...p} bridge={bridge} />);
  render(props);
  return { update: (p) => render(p), unmount: () => root.unmount() };
}
```

Inside `GameEdge`, the **picks in progress are local React state**; only a completed guess crosses
the wire.

## 4. The asynchronous submit round-trip (the core mechanic)

**The game never scores.** `Codemojex.submit/3` charges the guess and enqueues a `JOB` on the player's
EchoMQ lane, returning `{:ok, job}` — it does *not* compute a score. The score is produced later by the
`Codemojex.ScoreWorker` consumer and announced over PubSub. So a guess is **two events**, not one:

```
 React game                 GameLive (LiveView)              the engine (async)
 ───────────                 ───────────────────              ──────────────────
 tap 6 emoji (local state)
 bridge.pushEvent(
   "submit_guess",
   {emojis})        ───────► handle_event("submit_guess")
                              Codemojex.submit/3  ──────────► charge + EchoMQ.Lanes.enqueue(JOB)
                              {:ok, _job}  → {:noreply}                 │
 (clear picks now)  ◄───────  (no score yet)                           │ ScoreWorker drains the lane
                                                                       │ Scoring.score → GES → Board.record
                              handle_info({:scored, _}) ◄──── broadcast {:scored,…} on "game:"<>gam
                              push_props → push_event(
                                "game:update", game_props) ─► hook → handle.update(props)
 (re-render with the score) ◄──────────────────────────────────────────┘
```

- **Out (client → server):** `bridge.pushEvent("submit_guess", {emojis})` with six `"XXYY"` codes.
- **Back (server → client), the prop diff:** on `{:scored, _}` (and on `{:revealed, _}`), `GameLive`
  re-reads `game_view/1` and `push_event(socket, "game:update", game_props(...))`; the hook calls
  `handle.update(props)`, which re-renders `<GameEdge>`. Because `#game-root` is `phx-update="ignore"`,
  this rides `push_event` — **not** a re-render of `data-props`.

This is why the game reads as responsive: the optimistic clear happens immediately on enqueue; the
authoritative game arrives a moment later as its own event.

## 5. One-off events + the bridge

Besides the `game:update` prop diff, `GameLive` forwards three one-off events the game surfaces as
transient UI (toasts, the reveal):

| Server (`GameLive`) | Wire | GameEdge (`bridge.onServerEvent`) |
|---|---|---|
| `push_event(socket, "guess_rejected", %{reason})` (on `submit` error) | `guess_rejected` | toast the rejection |
| `handle_info({:revealed, payload})` → `push_event(… "revealed" …)` + `push_props` | `revealed` | reveal the secret/payouts |
| `handle_info({:golden_win, payload})` → `push_event(… "golden_win" …)` | `golden_win` | the golden close |

The **bridge** ([`types.ts`](../../../mercury/codemojex/apps/game/src/types.ts)) is the game's only handle on
the socket:

```ts
interface Bridge {
  pushEvent: (event: string, payload: unknown) => void;            // → the live socket
  onServerEvent: (cb: (name: string, payload: any) => void) => () => void;  // ← server one-offs
}
```

The `GameIsland` hook implements `pushEvent` as `this.pushEvent` and fans the one-off `handleEvent`s
out to every `onServerEvent` listener (returning an unsubscribe).

There are also two per-slot events the game can send — `lock` (`%{pos, code}`) and `unlock`
(`%{pos}`) — handled by `GameLive` via `Codemojex.lock/4` / `unlock/3`.

## 6. The privacy / blind contract

`Codemojex.View` is the trust boundary: **the secret and other players' guesses are never in any view**.
For a **golden** game the view is *blind* — per-guess scores and the leaderboard are withheld until the
sealed reveal:

- `history` rows drop `points` pre-reveal (`HistoryRow.points` is optional in `types.ts`).
- `leaderboard` is empty pre-reveal; `totals` carries only `{players, attempts}` (no `best`).
- The secret arrives **only** with `{:revealed, …}` (the finished state), never on the in-progress game.

The game must therefore tolerate a score-less view and render the blind state — never assume `points`
or a populated leaderboard.

## 7. Reconnect

On a LiveView reconnect, `GameLive.mount` runs again and re-sends the props; the React island is sealed
by `phx-update="ignore"`, so the existing React tree **survives** the reconnect and is refreshed by the
next `game:update`. Local pick state is the game's own; durable state always comes from (and returns
to) the server.

## 8. Map

[render-stack.md](render-stack.md) · [livereact-hot-swap.md](livereact-hot-swap.md) ·
[dev-and-testing.md](dev-and-testing.md) · source:
[`game_live.ex`](../../apps/codemojex/lib/codemojex_web/live/game_live.ex),
[`lobby_live.ex`](../../apps/codemojex/lib/codemojex_web/live/lobby_live.ex),
[`types.ts`](../../../mercury/codemojex/apps/game/src/types.ts).
