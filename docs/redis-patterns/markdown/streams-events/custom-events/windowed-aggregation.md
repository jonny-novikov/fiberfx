# R5.04.2 · Windowed aggregation

> Route: `/redis-patterns/streams-events/custom-events/windowed-aggregation` · dive 2 · fold a time window of one channel into a projection

A projection is a fold scoped to a slice of the log: take the entries between two instants and reduce them to the
one shape a view needs — a count, a total, a tally. Because a stream entry id begins with the millisecond it was
added, a `DateTime` becomes a range bound, so "the events of the last hour" is an id range and the projection is the
fold over it.

## Time is an id range

A stream entry id is `<milliseconds>-<sequence>`. The leading milliseconds make the id a clock: an instant maps to
an id, and an id range expresses a time range. To read everything in a closed window `[t0, t1]`, form the smallest
id at `t0` — `<t0-in-ms>-0` — and the largest id at `t1` — `<t1-in-ms>-<max-seq>` — and range between them. To read
everything from an instant onward, range from the floor id to `+`.

```
XRANGE guess-scored 1719312000000-0 1719315600000-0   # closed [t0, t1]
XRANGE guess-scored 1719312000000-0 +                 # half-open [t0, ∞)
```

The floor id `<ms>-0` is the lowest id at that millisecond, so the lower edge is exact: an entry minted at the
instant is in, one minted a millisecond earlier is out. The ceiling id `<ms>-<max-seq>` is the highest id at that
millisecond, so the upper edge is exact too: an entry at `t1` reads back, one a millisecond later does not.

## A projection is the fold over the window

With the window read, the projection is the same fold as any event-sourced rebuild — start with an empty
accumulator, apply each entry in order — but scoped to the window and shaped for one question. A per-room count
folds `room-opened` to a map; a running total folds `guess-scored` to a sum; the day's results fold `game-settled`
to a list. The fold is deterministic in the entries, so the projection is recomputed from the log, never a separate
table kept in sync — and many projections fold the same window into different shapes without coordinating.

## Recompute, or snapshot

A projection is recomputable, which is its strength: change the shape and re-fold, and the answer is right. The cost
is that folding a long window is work proportional to its entries. Where a rollup is read far more often than its
window changes, fold once and cache the result, or bound the window with retention (R5.02) so the replay stays
short. Recomputing a stable projection on every read is the waste to avoid; recomputing it when the inputs change is
exactly the point.

## Applied — EchoMQ.Stream.read_window/6 and read_since/5

EchoMQ derives the window bounds host-side so the wire only ever sees an `<ms>-<seq>` id, never a raw integer.
`EchoMQ.Stream.read_window(conn, queue, name, t0, t1, count)` reads the closed `[t0, t1]` window;
`EchoMQ.Stream.read_since(conn, queue, name, t0, count)` reads the half-open `[t0, ∞)` window. Both delegate to the
range read and return `{branded, fields_map}` tuples in mint order — the input to the fold.

```
# EchoMQ.Stream.read_window/6 — a closed mint-time window to fold (real)
EchoMQ.Stream.read_window(conn, "cm", "guess-scored",
  ~U[2024-06-25 12:00:00Z], ~U[2024-06-25 13:00:00Z])
#  from = minid_floor(t0)  ->  "<ms>-0"            (lowest id at t0)
#  to   = maxid_ceil(t1)   ->  "<ms>-<max-seq>"    (highest id at t1)
#  XRANGE emq:{cm}:stream:guess-scored <ms>-0 <ms>-<max-seq>
#  -> {:ok, [{branded, fields_map}, …]}            mint order, [t0, t1] — fold to a projection

# everything from an instant onward, half-open [t0, ∞)
EchoMQ.Stream.read_since(conn, "cm", "guess-scored", ~U[2024-06-25 12:00:00Z])
#  from = minid_floor(t0), to = "+"
```

`minid_floor/1` turns `t0` into `"<ms>-0"` and `maxid_ceil/1` turns `t1` into `"<ms>-<max-seq>"`, where the
milliseconds is the real Unix millisecond of the instant (`DateTime.to_unix(dt, :millisecond)`) and the sequence is
the maximal 22-bit tail. So a `read_window` returns exactly the entries whose `EVT` mint instant falls in
`[t0, t1]`, which equals reading the whole stream and filtering by mint instant — the window is a server-side
filter via the bounds, and `read_window/6` raises before any wire on an inverted window (`t1` before `t0`). The
returned tuples fold to the projection: a per-window count of room openings, a per-player running total of scores,
the settled games of the day.

In **codemojex** (`echo/apps/codemojex`), the score worker scores each guess with `Codemojex.Scoring.score/2` and
records the player's best with `Codemojex.Board.record/3`; the leaderboard `Codemojex.Board.top/2` is the live rank.
A windowed read of the `guess-scored` channel folds to the recent activity feed — the last hour's scores — while the
board holds the all-time rank; the two are different projections of the same play, one a windowed fold of the log,
one a running aggregate.

### The pattern → its EchoMQ application

| The pattern | Its EchoMQ application |
|---|---|
| A projection is a fold scoped to a time window; time is an id range because the entry id carries the millisecond. | `EchoMQ.Stream.read_window/6` reads a closed `[t0, t1]` window and `read_since/5` a half-open `[t0, ∞)` one, deriving exact bounds with `minid_floor/1` and `maxid_ceil/1`; the mint-ordered tuples fold to the projection — codemojex's windowed activity feed beside the running board. |

### A door, not a depth — the persistence floor

A windowed history does not grow without bound: a log is trimmed under a retention policy (R5.02), and what is
trimmed folds into the durable page tier and, beyond it, to remote object storage behind a create-only commit fence.
That floor — the single-writer engine, the lazy reader, and the durability dial a system turns from "hold nothing"
to "commit-per-record + replicate off-box" — is the subject of [the EchoStore persistence course](/echo-persistence).
The time-travel reads in full and the archive fold consumer are the subject of the dedicated **EchoMQ course**,
[the Bus pillar](/echomq/bus).

## References

### Sources

- [Valkey — XRANGE](https://valkey.io/commands/xrange/) — the `<ms>-<seq>` id range and the time-bounded read folded
  to a projection.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the entry id as a clock, an instant
  mapping to an id.
- [Valkey — XLEN](https://valkey.io/commands/xlen/) — the number of entries a fold must apply, the size a window
  bounds the work against.
- [Kreps — The Log: What every software engineer should know](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)
  — many projections folded from one shared log.

### Related in this course

- [R5.04 · Custom events & projections](../custom-events.md) — the module hub.
- [R5.04.1 · Domain events on the stream](domain-events-on-the-stream.md) — the named channel a projection folds.
- [R5.04.3 · Reserved-name discipline](reserved-name-discipline.md) — the reserved `id` field and key suffixes.
- [R5.01.3 · The cursor](../../streams-event-sourcing/the-cursor.md) — the entry id as a time bound, reapplied here
  to a window.
- [/echo-persistence](/echo-persistence) — the durable floor a trimmed window folds into.
