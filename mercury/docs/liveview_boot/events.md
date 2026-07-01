# Events

← [README](README.md) · siblings: [architecture](architecture.md) · [channels](channels.md) ·
[interactions](interactions.md) · [effector-pipeline](effector-pipeline.md)

Every event in the vertical, by surface. Payload shapes are quoted from the emitting source.

## 1 · Server → island, over LiveView (`push_event`)

Registered by the boot's `GameIsland` hook (`liveview-boot/src/app.ts`); emitted by `GameLive`
(`echo/…/live/game_live.ex`).

| Event | Payload | Emitted when | Island routing |
|---|---|---|---|
| `game:update` | the full `game_props` map (below) | a `{:scored, …}` or `{:revealed, …}` PubSub message makes `GameLive` re-read the view (`push_props/1`) | `handle.update(p)` → `model.propsReceived` → `$props` |
| `guess_rejected` | `%{reason: string}` — `"no_game" · "closed" · "expired" · "bad_guess"` (validation) or a wallet reason such as `"insufficient_keys"` | `Codemojex.submit/3` returned `{:error, reason}` | fanned to `bridge.onServerEvent` listeners → GameEdge toast + `model.events.guessRejected` |
| `revealed` | see §4 (`broadcast_revealed`) | the game settled/revealed (also triggers a follow-up `game:update`) | same fan-out → toast + `model.events.revealed` |
| `golden_win` | `%{game, diamonds}` | a golden close paid out (`announce_golden`) | same fan-out → toast + `model.events.goldenWin` |

**`game_props`** (`GameLive.game_props/3` — mirrored by `apps/game/src/types.ts` `GameProps`; the
two are kept in lockstep by convention):

```elixir
%{
  view: Codemojex.game_view(gam),            # see below
  leaderboard: [%{player, name, score, is_me}],   # top 20, named via Store.player
  history: Codemojex.my_history(gam, plr, 50),    # [%{emojis, points?, at_ms}] — own guesses only
  me: plr                                          # "PLR…" branded id
}
```

**`view`** (`Codemojex.View.game_view/1` — privacy-preserving: never the secret, never others'
guesses): `game · room · emojiset (id, sprite_url, cell_size, cols, rows, codes) · ends_ms ·
prize_pool · prize_usd (Economy.to_usd) · guess_fee · free · status`, plus `totals` /
`gather` / `commitment` when present. For a **blind golden game** the per-guess score surface is
withheld until reveal (`revealed?/1` gates it), and `View.leaderboard/2` returns `[]` until then.

## 2 · Island → server, over the bridge (`pushEvent`)

Handled by `GameLive.handle_event/3`. The bridge is fire-and-forget (LiveView replies `{:noreply}`;
a real reply path is an open seam — [channels.md](channels.md) §6).

| Event | Payload | Server action |
|---|---|---|
| `submit_guess` | `%{emojis: [6 × "XXYY"]}` | `Codemojex.submit/3` → validate → `Locks.merge` → `Wallet.charge_guess` → `Lanes.enqueue` a branded `JOB` on the **player's lane**; errors bounce back as `guess_rejected` |
| `lock` | `%{pos: 0..5, code}` | `Codemojex.lock/4` — pins a code at a position across the player's guesses |
| `unlock` | `%{pos}` | `Codemojex.unlock/3` |

## 3 · Server → channel clients (`RoomChannel` pushes)

`RoomChannel` (`echo/…/channels/room_channel.ex`) subscribes to the same PubSub topic by joining
`game:<id>` and forwards three frames verbatim:

| Frame | Payload | Note |
|---|---|---|
| `scored` | `%{game, player: name, pct, eff}` | raw per-attempt tick (classic games only) — **not** a `game:update`; a channel client composes or `refresh`es |
| `revealed` | §4 | |
| `golden_win` | `%{game, diamonds}` | |

Inbound, the channel handles exactly one message: `refresh` → replies
`%{view, leaderboard: [%{player, score}]}`. There is **no** `submit_guess` inbound on the channel
today — the channel transport is read-only as-built ([channels.md](channels.md) §6).

## 4 · The PubSub broadcasts (the fan-out origin)

Topic: `"game:" <> game` on `Codemojex.PubSub`. Subscribers: every `GameLive` on the page route,
every joined `RoomChannel`.

| Message | Emitted by | Payload |
|---|---|---|
| `{:scored, %{game, player: name, pct, eff}}` | `ScoreWorker.handle/1` after recording a classic attempt | name (not id), percentage, leaderboard-effective score |
| `{:revealed, %{game, secret, nonce, commitment, board: [%{player, score}], payouts: [%{player, diamonds}], state}}` | `Rooms.broadcast_revealed/4` — the ONE fat reveal (V-13): the sealed preimage opens here | terminal |
| `{:golden_win, %{game, diamonds}}` | `Rooms.announce_golden/2` | total diamonds won |

## 5 · The bus's retained log (EchoMQ `Events`)

Beside the ephemeral PubSub broadcast, `ScoreWorker` also publishes the attempt onto EchoMQ's
**retained, replayable event log** (`EchoMQ.Events.publish(conn, "cm", "scored", job_id,
game:, player:, pct:, eff:)`). Ephemeral vs durable is the deliberate split: PubSub feeds *live*
UI; the bus log survives the moment (replay, audit, late consumers). See
[effector-pipeline.md](effector-pipeline.md) §3.

## 6 · Effector events inside the island (`channel/model.ts`)

| Unit | Type | Fed by |
|---|---|---|
| `propsReceived` | `Event<GameProps>` | join reply (`isGameProps` gate: `"view" in value`), `"game:update"` frames, and the mount facade's `update()` |
| `$props` | `Store<GameProps \| null>` | `propsReceived` |
| `$view` / `$leaderboard` / `$history` / `$me` | derived (`$props.map`) | fine-grained slices — subscribers re-render per slice |
| `serverEvent` | `Event<{name, payload}>` | every non-`game:update` inbound frame |
| `events.guessRejected` / `events.revealed` / `events.goldenWin` | `Event<unknown>` | `sample`d off `serverEvent` by name — the typed client terminus of the PubSub fan-out |
| `submitGuess(emojis)` / `lock(pos, code)` / `unlock(pos)` | functions | `chan.push` → the bound transport |
| `chan.$status` / `chan.$error` / `chan.joined` / `chan.message` | from `createChannel` | transport lifecycle ([channels.md](channels.md) §3) |

## 7 · HMR events (dev only)

| Surface | Behavior |
|---|---|
| `import(origin + "/@react-refresh")`, then `/@vite/client` | installed by the boot's `wireViteDev` before the entry import; idempotent via the preamble flag |
| react-refresh boundary | a **component** edit updates in place; React state survives |
| `import.meta.hot.accept` in `apps/game/src/index.tsx` | an **entry/model** edit hands the retained `LiveMount` to the *new* module's `remount` — fresh model, seeded from the latest retained props |
| `import.meta.hot.invalidate()` | fallback (no retained mount, or the island left the DOM) → full reload |
