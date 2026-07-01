# Channels

← [README](README.md) · siblings: [architecture](architecture.md) · [events](events.md) ·
[interactions](interactions.md) · [effector-pipeline](effector-pipeline.md)

The channel layer, server → client: the socket, the server channel, the Effector plug, the two
transport adapters, and the honest seams between them.

## 1 · `CodemojexWeb.UserSocket` (server)

`echo/…/channels/user_socket.ex` routes `channel "game:*", CodemojexWeb.RoomChannel` and
authenticates the **socket connect** by SES:

- the session id arrives as a connect **param** (`session`, or `token`) — a body field, kept out of
  the query string so it never lands in proxy logs;
- `Codemojex.Session.resolve/1` must return a player, else the connection is **refused** (`:error`);
- `id/1` is `"player_socket:" <> plr` for an authenticated socket — a per-player identity, so a
  player's sockets can be disconnected as a group.

The client side matches: `PhoenixGame` connects `new Socket(endpoint, { params: { session } })`.

## 2 · `CodemojexWeb.RoomChannel` (server)

Joining `game:<id>` subscribes the channel process to the PubSub topic `"game:" <> game` — the same
topic `GameLive` subscribes to; the scorer broadcasts once and both transports hear it.

| Direction | Surface | Shape |
|---|---|---|
| join reply | `{:ok, %{view: Codemojex.game_view(game)}}` | **view only** — thinner than `GameLive`'s `game_props` (no leaderboard/history/me) |
| push | `scored` / `revealed` / `golden_win` | forwarded verbatim from PubSub ([events.md](events.md) §3–4) |
| inbound | `refresh` | replies `%{view, leaderboard: [%{player, score}]}` — a re-read on demand |

## 3 · `createChannel` — the Effector plug (`@mercury/effector`)

`packages/mercury-effector/src/channel.ts`. State lives outside React; the plug is **structurally
typed** (`ChannelLike`), so the package takes no `@echo/phoenix` dependency — anything with the
channel shape plugs in (a real Phoenix channel, a fake in tests, or the `bridgeChannel` adapter).

```
$status : idle → joining → joined | errored | closed   (reset on unbind)
$error  : the last join/close/error reason, or null
joined  : Event<unknown>          — fires with the join "ok" reply
message : Event<{event, payload}> — every inbound frame for a bound name
push(event, payload)              — fire-and-forget (routed via an Effector effect)
pushAsync(event, payload)         — Promise: "ok" resolves, "error"/"timeout" reject
bind(channel, inbound[]) → unbind — join + listen; unbind removes listeners + detaches
useStatus()                       — React hook over $status
```

`bind` is the hot-plug: attach a live channel at runtime, get an unbind back. Rebinding a fresh
channel when the room changes is the intended pattern.

## 4 · `createGameModel` — the game model over the plug

`apps/game/src/channel/model.ts` binds `GAME_INBOUND = ["game:update", "revealed", "golden_win",
"guess_rejected"]` and wires, entirely with `sample`:

- join reply **and** `"game:update"` frames → `propsReceived` → `$props` (gate:
  `isGameProps = "view" in value`);
- every other frame → `serverEvent` → the typed `events.{guessRejected, revealed, goldenWin}`;
- derived `$view / $leaderboard / $history / $me`;
- outbound `submitGuess / lock / unlock` → `chan.push`.

The model is transport-agnostic: nothing in it knows whether a Phoenix channel or a LiveView bridge
sits underneath.

## 5 · The two adapters

### `PhoenixGame` — the real-channel transport (`apps/game/src/channel/PhoenixGame.tsx`)

One socket + one channel per mount: `new Socket(endpoint ?? "/socket", { params: { session } })`,
`socket.channel("game:" <> game)`, `model.chan.bind(channel, GAME_INBOUND)`; cleanup unbinds,
leaves, disconnects. Renders `GameEdge` from `useUnit($props)` once the join reply seeds it.

### `BridgeGame` — the LiveView transport (`apps/game/src/channel/BridgeGame.tsx`)

No socket of its own — the LiveView socket already exists (the boot owns it). The host `Bridge` is
lifted into `ChannelLike` by **`bridgeChannel`** (`packages/mercury-effector/src/bridge.ts`):

| `ChannelLike` op | `bridgeChannel` semantics |
|---|---|
| `join()` | resolves `"ok"` **synchronously** with `opts.joinReply` — the host delivered the initial state before the island mounted; there is nothing to wait for and no way to fail |
| `on(event, cb)` | one `bridge.onServerEvent` subscription per bound name, filtered by name; per-ref unsubscribe bookkeeping backs `off(_, ref)` |
| `push(event, payload)` | `bridge.pushEvent(event, payload)` + an immediate `"ok"` ack (see §6) |
| `onClose` / `onError` | no-ops — the LiveView socket owns lifecycle and reconnection |
| `leave()` | releases every subscription |

`BridgeGame` seeds the join reply from `model.$props.getState() ?? initial` — so a re-bind after a
hot swap resumes from the **latest** props, not the stale mount-time snapshot.

## 6 · Seams (as-built, verified — not smoothed over)

1. **The channel transport is read-only today.** `RoomChannel`'s only `handle_in` is `"refresh"`;
   an unhandled inbound (`submit_guess`) would crash the channel process. Guesses flow through
   LiveView (production) or server-side calls. Wiring the write path onto the channel is the
   deferred Phase-B/D4 completion (an `echo/`-side rung).
2. **The channel join reply is thinner than `game_props`.** `%{view}` passes the model's
   `isGameProps` gate, so `$props` seeds with `view` only — `leaderboard`/`history`/`me` arrive via
   `refresh` or not at all. Fine for the Tauri dev toolkit's tap; a real channel-first client wants
   the join reply widened (server seam).
3. **`scored` is not in `GAME_INBOUND`.** Over the channel, per-attempt ticks are pushed as
   `scored` frames the model does not bind; over LiveView they arrive folded into `game:update`.
   A channel-first leaderboard would bind `scored` and fold it — or `refresh`.
4. **Push acks are synthetic on the bridge.** `bridgeChannel.push` acks `"ok"` immediately
   (fire-and-forget): `GameLive.handle_event` returns `{:noreply}` — no reply channel exists. A
   true ack (`{:reply, …}` + the hook's `pushEvent(event, payload, onReply)` threaded through the
   `Bridge`) would give `pushAsync` real server acknowledgements on the LiveView transport.
