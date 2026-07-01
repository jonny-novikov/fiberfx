# The pipeline: EchoMQ → PubSub → GameUpdates → (prize_pool, leaderboard) Effector

← [README](README.md) · siblings: [architecture](architecture.md) · [events](events.md) ·
[channels](channels.md) · [interactions](interactions.md)

The full data path of one scored attempt, stage by stage, with the code that carries it. This is
the load-bearing flow of the live game: everything the player watches move — the prize pool, the
leaderboard — moves through here.

```
[1] Guesses.submit ── Lanes.enqueue(JOB, lane=PLR) ──▶ EchoMQ queue "cm" (Valkey)
                                                            │
[2]                                    EchoMQ.Consumer (:cm_score) — Lanes.claim
                                                            │
                                              ScoreWorker.handle/1
                                     score · Store.put_guess(GES) · attempts++
                                                            │
[3]                              Board.record ── HSET base(max) · ZADD board ──▶ Valkey
                                                            │
                            ┌───────────────────────────────┴─────────────────────┐
[4]           Events.publish("cm","scored",…)                Phoenix.PubSub.broadcast
              — the RETAINED bus log (replay)                "game:"<>gam  {:scored,…}
                                                                    │
[5]                                        GameLive.handle_info ── push_props
                                           game_view + leaderboard + my_history
                                                                    │
                                           push_event("game:update", game_props)
                                                                    │
[6]                       boot GameIsland handleEvent ──▶ handle.update(props)
                                                                    │
[7]                        LiveMount facade ──▶ model.propsReceived(props)
                                                                    │
[8]              $props ──map──▶ $view (prize_pool · prize_usd) · $leaderboard
                                                                    │
[9]                        useUnit / useStoreMap ──▶ React re-render (GameEdge)
```

## Stage 1 — the guess becomes a job (`Codemojex.Guesses.submit/3`)

`echo/apps/codemojex/lib/codemojex/game.ex`. Validation (`open`, not expired, codes ∈ the game's
keyboard), lock overlay, wallet charge — then:

```elixir
job = EchoData.BrandedId.generate!("JOB")
payload = :erlang.term_to_binary({:guess, game, player, guess})
Lanes.enqueue(Bus.conn(), @queue, player, job, payload)   # @queue "cm", lane = PLR
```

Two deliberate choices: the **branded `JOB` id** (time-ordered, coordination-free — the BCS id
contract), and the **lane keyed by the player**, so `Lanes.claim` rotates across players and one
keyboard masher cannot starve the field. The host never scores; enqueue is the whole write.

## Stage 2 — the single scoring authority (`Codemojex.ScoreWorker`)

`Codemojex.Application` supervises `EchoMQ.Consumer` (`id: :cm_score`) draining `"cm"` via
`Lanes.claim`; the lane group arrives as the player id. The worker reads the game through the cache
(**only the immutable secret is trusted from cache**; mutable status is read from the system of
record), scores with the pure engine, persists:

```elixir
s = Scoring.score(secret, emojis)
Store.put_guess(gid, %{game:, player:, emojis:, points: s.total, at_ms:})   # GES row
Cmd.incr("cm:" <> game <> ":attempts") |> Wire.run(conn)
eff = Board.record(game, player, s.total)
```

An unknown game answers `:ok` — a drop, never a retry loop.

## Stage 3 — the leaderboard write (`Codemojex.Board.record/3`)

The leaderboard is a Valkey sorted set, written by exactly one writer (this worker):

```elixir
old = hget_int(conn, k(game, "base"), player)
new_base = max(old, base)                                     # best-of semantics
Cmd.hset(k(game, "base"), player, to_string(new_base)) |> Wire.run(conn)
Cmd.zadd(k(game, "board")) |> Cmd.score(new_base, player) |> Wire.run(conn)
```

Read side: `Board.top/2` = `ZREVRANGE … WITHSCORES` → `{player, score}` highest-first.

## Stage 4 — the double fan-out (durable + ephemeral)

For a classic game (`feedback == "score"`), the worker emits the result twice — different
guarantees, different consumers:

```elixir
Events.publish(conn, @queue, "scored", job_id, game:, player: name, pct:, eff:)
# EchoMQ's RETAINED event log — replayable, consumer-independent, survives the moment

Phoenix.PubSub.broadcast(Codemojex.PubSub, "game:" <> game,
  {:scored, %{game:, player: name, pct:, eff:}})
# in-cluster, ephemeral — feeds every live subscriber NOW
```

A **blind golden game skips both** (B-1): the score exists server-side but nothing leaks in-flight;
the first public result is the ONE fat `{:revealed, …}` at close (`Rooms.broadcast_revealed/4` —
secret, nonce, commitment, final board, payouts, state). A perfect 600 on an `:open` game also
routes `Rooms.close_game/1` through the settle queue (`"cm-settle"`, lane = the game) — the
move-then-settle split: the guess queue competes, the settle queue pays.

## Stage 5 — GameUpdates (`GameLive.push_props/1`)

Both `{:scored, …}` and `{:revealed, …}` land in `GameLive.handle_info/2` (it subscribed to
`"game:" <> gam` at mount) and trigger a **full re-read** — the update is authoritative state, not
an increment:

```elixir
%{
  view: Codemojex.game_view(gam),        # ← prize_pool lives here
  leaderboard: named(Codemojex.leaderboard(gam, 20), plr),
  history: Codemojex.my_history(gam, plr, 50),
  me: plr
}
|> then(&push_event(socket, "game:update", &1))
```

- **`prize_pool`**: `View.game_view/1` reads it off the game record (`r.prize_pool`, the system of
  record) and derives `prize_usd: Economy.to_usd(r.prize_pool)` — the client never computes money.
- **`leaderboard`**: `View.leaderboard/2` gates on `revealed?/1` (a blind golden game returns `[]`
  until reveal), then `Board.top` rows; `GameLive.named/2` joins each `{player, score}` with the
  player's display name and an `is_me` flag.

Full-props-per-update is the simplicity contract: the client holds no merge logic, so it can never
drift from the server's view.

## Stages 6–7 — across the bridge into the model

The boot's hook wired `handleEvent("game:update", p => handle.update(p))` at mount. The island's
`LiveMount` facade (`apps/game/src/index.tsx`) records the payload (`live.props = p` — this is what
a hot swap reseeds from) and fires the model:

```ts
update: (p: GameProps) => { live.props = p; live.apply(p); }   // apply = model.propsReceived
```

On the **channel transport** the same store is fed by the join reply + bound frames instead — same
model, different plug ([channels.md](channels.md) §5).

## Stage 8 — the Effector fan-out (`channel/model.ts`)

```ts
const $props = createStore<GameProps | null>(null).on(propsReceived, (_s, p) => p);

const $view        = $props.map((p) => p?.view ?? null);        // ← prize_pool, prize_usd, status…
const $leaderboard = $props.map((p) => p?.leaderboard ?? []);   // ← the named, is_me-flagged rows
const $history     = $props.map((p) => p?.history ?? []);
const $me          = $props.map((p) => p?.me ?? null);
```

Derived stores are the fine-grained subscription surface: a consumer of `$leaderboard` recomputes
only when the leaderboard slice changes identity, not on every props tick's unrelated fields. The
one-off events ride beside the stores — `events.{guessRejected, revealed, goldenWin}` are `sample`d
off `serverEvent` by name, a typed client-side mirror of the server's PubSub messages.

## Stage 9 — React consumption (effector-react)

As built, `BridgeGame`/`PhoenixGame` subscribe the whole props store and render the presentational
screen:

```tsx
const props = useUnit(model.$props);
return <GameEdge {...(props ?? initial)} bridge={bridge} />;
```

The derived stores are the contract for the next screen (GameRoom): a prize widget reads
`useUnit(model.$view)` and touches nothing else; a leaderboard row can go finer with
`useStoreMap(model.$leaderboard, rows => rows[i])` so one player's score change re-renders one row.
State stays outside React (the Mercury plug posture) — which is also exactly what lets a hot swap
rebuild the tree without losing the game ([interactions.md](interactions.md) §4).

## Why this shape holds up

- **One writer per fact.** The scorer alone writes the board; the game record alone holds the pool;
  the client holds nothing authoritative — it renders `$props`.
- **Two fan-outs, two guarantees.** The retained bus log (`Events.publish`) survives the moment;
  PubSub feeds the moment. Losing a live subscriber loses nothing durable.
- **Full-state updates.** `game:update` is idempotent and self-healing — a dropped frame is
  corrected by the next one; reconnect just re-reads.
- **The identity travels, the payload doesn't.** The `JOB`/`GES`/`PLR`/`GAM` branded ids cross the
  boundaries; secrets and other players' guesses never do (`View` is the privacy gate).
