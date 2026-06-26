# R7.07 · Workshop — codemojex's read-model dashboard

> Route: `/redis-patterns/data-modeling/workshop` · the chapter capstone (single page, no dives) ·
> Pattern: **the honest subset — three of R7's six modeling patterns, applied to codemojex's real
> dashboard read-models.**
>
> Grounding: the **codemojex** consumer (`echo/apps/codemojex`), every surface verified on disk.
> `Codemojex.Board` — the leaderboard ZSET (`ZADD`/`ZREVRANGE cm:<game>:board`);
> `Codemojex.View.total_players/1` — `SCARD cm:<game>:players`; `Codemojex.Rooms.add_player/2` — `SADD
> cm:<game>:players`; `CodemojexWeb.RoomChannel` — the live broadcast over Phoenix Channels. The engine
> is Valkey. The keyspace is **unbraced `cm:<game>:…`** (not EchoMQ's `emq:{q}:`). Doors:
> `/bcs` (B7 — codemojex), `/bcs/overview`.

A workshop is not a new pattern. It is the chapter's patterns assembled against one real consumer, and
the most useful question that assembly can ask is: **which of R7's six patterns did this consumer actually
reach for?** The answer is honest and narrow. codemojex uses three. It does not use the other three. The
chapter thesis closes on that gap.

## The premise — six patterns, three in play

R7 taught six data-modeling patterns:

1. **R7.01 · Redis as a primary database** — the job HASH as the record of truth, `noeviction` + AOF.
2. **R7.02 · Memory optimization** — compact encodings; short fields; capped structures.
3. **R7.03 · Probabilistic data structures** — HyperLogLog, Bloom filter, Count-Min Sketch.
4. **R7.04 · Bitmaps** — boolean flags at 1 bit per entity; cohort analytics.
5. **R7.05 · Vector sets** — HNSW similarity search; semantic cache; recommendations.
6. **R7.06 · Geospatial** — `GEOADD`/`GEOSEARCH` over a geohash sorted set.

codemojex uses: **R7.01** (the bus's job HASH), **R7.02** (the Board ZSET is a compact, capped
read-model), and **R7.03's exact-SET baseline** (`SADD`/`SCARD` for player-count). It does not use
HyperLogLog at scale (too small a player count), bitmaps, vectors, or geospatial (domain doesn't call
for them).

## The three real read-models

### Read-model 1 — the leaderboard ZSET (`Codemojex.Board`)

`Codemojex.Board` is the competitive state in Valkey. The leaderboard is one sorted set per game; its
moduledoc states: *"The leaderboard is one sorted set per game … writes it straight to the board — no
tier ladder, no first-mover…"*

Key: `cm:<game>:board` (unbraced — the `<game>` is a branded `GAM` id).

```elixir
# board.ex — record a scored guess
defp k(game, suffix), do: "cm:" <> game <> ":" <> suffix
def record(game, player, base) do
  Cmd.zadd(k(game, "board")) |> Cmd.score(new_base, player) |> Wire.run(conn)
end

# board.ex — top n, highest first
def top(game, n \\ 10) do
  Cmd.zrevrange(k(game, "board"), 0, n - 1) |> Cmd.withscores() |> Wire.run(Bus.conn())
end
```

Commands: `ZADD cm:<game>:board <score> <PLR>` (write) · `ZREVRANGE cm:<game>:board 0 n-1 WITHSCORES`
(read). Exposed at `GET /games/:id/leaderboard` and broadcast by the room channel on every scored guess.

**R7 tie:** a ZSET read-model — compact and ordered (R7.02 small structures; the same ZSET-as-ranked
family as R4).

### Read-model 2 — the unique-players count (exact SET, `Codemojex.View` + `Codemojex.Rooms`)

`Codemojex.Rooms.add_player/2` fills the players set each time a player joins a game:

```elixir
# rooms.ex
defp add_player(game, player),
  do: Cmd.sadd("cm:" <> game <> ":players", player) |> Wire.run(Bus.conn())
```

`Codemojex.View.total_players/1` counts it:

```elixir
# view.ex line 117
def total_players(game), do: scard("cm:" <> game <> ":players")
```

Key: `cm:<game>:players`. Commands: `SADD` (join) · `SCARD` (count).

**R7.03 tie — the honest contrast:** codemojex counts unique players with an **exact SET**, not
HyperLogLog. HLL (R7.03) is the road-not-taken: it is the right move when the cardinality is so large
that storing every id exactly is too expensive and a bounded error rate is acceptable. A game's player
count is small — exact is correct here.

### Read-model 3 — the live view (`Codemojex.View` + `CodemojexWeb.RoomChannel`)

`Codemojex.View.game_view/1` folds the Valkey operational state — the board, the player count, the
privacy-gated game state — into the player-facing dashboard view. `CodemojexWeb.RoomChannel`'s moduledoc
states: *"leaderboard updates without any per-game process … a `refresh` re-reads the view and the
leaderboard."*

The room channel pushes a re-read view over Phoenix Channels on every scored guess or on a client
`refresh`. There is **no `XADD` activity stream** in codemojex (grep of `echo/apps/codemojex/lib` for
`XADD` is empty). The live view is a projection pushed by the channel — the simpler real choice over
an event-sourced stream (R5's road-not-taken).

## The roads not taken — honest absences

| Pattern | codemojex | Why not |
|---|---|---|
| HyperLogLog (R7.03) | ✗ | player count is small — exact SET is correct |
| Bitmaps (R7.04) | ✗ | domain: no large-cardinality boolean flag (cm-bitmapist is a planned spike, not live) |
| Vector sets (R7.05) | ✗ | no recommendation surface; no infra spike |
| Geospatial (R7.06) | ✗ | a location-agnostic emoji game — no location dimension |

## The thesis

A real system uses a small, workload-chosen subset of the modeling family. codemojex reaches for three:
the compact ZSET as a live read-model, the exact SET for a bounded cardinality count, and the job HASH
as the bus's record of truth. The other three patterns are absent because the domain and scale don't call
for them — not because they are bad patterns. "Know which pattern fits which workload" is the chapter's
instruction, and the dashboard makes it concrete.

## References

### Sources

- Valkey — *ZADD*: <https://valkey.io/commands/zadd/>
- Valkey — *ZREVRANGE*: <https://valkey.io/commands/zrevrange/>
- Valkey — *SADD*: <https://valkey.io/commands/sadd/>
- Valkey — *SCARD*: <https://valkey.io/commands/scard/>

### Related in this course

- `/redis-patterns/data-modeling` — R7 chapter landing
- `/redis-patterns/data-modeling/primary-database` — R7.01 the job HASH as the record of truth
- `/redis-patterns/data-modeling/memory-optimization` — R7.02 compact encodings + capped structures
- `/redis-patterns/data-modeling/probabilistic-data-structures` — R7.03 HLL vs exact SET
- `/redis-patterns/data-modeling/bitmap-patterns` — R7.04 boolean flags
- `/redis-patterns/data-modeling/vector-sets` — R7.05 similarity search
- `/redis-patterns/data-modeling/geospatial` — R7.06 geohash sorted set
- `/bcs` — the Branded Component System (B7 = codemojex)
- `/bcs/overview` — BCS overview
