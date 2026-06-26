# R5.04 · Custom events & projections

> Route: `/redis-patterns/streams-events/custom-events` · module hub · pattern: **arbitrary domain events and windowed projections on one append-only log.**

Give every kind of domain event its own named stream, append each as an immutable entry, and fold a window of
those entries into a projection — a read-model shaped for one question. This is event sourcing (R5.01) applied to
*user-defined* events: the same append-only log, but the event types and the read-models are yours to choose.

## The pattern in one move

R5.01 taught the log as the source of truth and the fold as the rebuild. Custom events take that one step further:
the events are not a fixed catalogue (`placed`, `filled`, `closed`), they are whatever the domain produces — a room
opened, a guess scored, a game settled. Each event *type* gets its own named stream, so one log per channel keeps a
reader from sifting unrelated entries. And a projection is a fold scoped to a slice of the log: take the entries in
a time window and reduce them to exactly the shape one view needs — a per-room count, an hourly total, a running
tally — recomputed from the log, never a separate table kept in sync.

Two moves carry the module, and they are two of the three dives:

- **A custom event is a named stream.** `XADD <stream-name> …` appends to a stream chosen by name; the name *is* the
  domain-event channel. A new event type costs nothing but a new name; readers subscribe to the names they care
  about.
- **A projection is a windowed fold.** Read the slice of a stream between two instants and fold it to a read-model.
  Because a stream entry id carries the millisecond it was added, a `DateTime` becomes a range bound, so "the events
  of the last hour" is an id range, and the projection is the fold over it.

The third dive is the discipline that keeps custom names safe: a stream's `id` field and a couple of key suffixes
are reserved, and a custom event must keep clear of them.

## A custom event is a named stream

A stream is identified by its key. Give each domain-event type its own key, and one append-only log per type
follows: `room-opened` events go to one stream, `guess-scored` to another, `game-settled` to a third. A reader of
the settlement feed reads only settlement entries; it does not page through guesses to find them. Adding a new event
type is adding a new name — no schema migration, no shared table.

```
XADD room-opened   * room ROM0Nk2…  set animals  fee 1
XADD guess-scored  * game GAM0Nk3…  player PLR0…  total 480
XADD game-settled  * game GAM0Nk3…  winner PLR0…  pot 60
```

Each entry is immutable once written and carries a time-ordered id. The three streams are independent logs over the
same instance; a projection reads one of them, or fans across several, and folds.

## A projection is a windowed fold

A projection answers one question from the log: how many rooms opened this hour, what each player's running total
is, which games settled today. It is a fold — start with an empty accumulator, apply each entry in order — scoped to
a window of the log. The window is expressed in time, and time is an id range, because a stream entry id begins with
the millisecond the entry was added.

```
# the events of one hour, folded to a per-room count
XRANGE room-opened 1719312000000-0 1719315600000-0   # a closed [t0, t1] window
# everything from an instant onward, folded to a running total
XRANGE guess-scored 1719312000000-0 +                # a half-open [t0, ∞) window
```

The fold over the window is deterministic in the log: the same entries always reduce to the same projection, so a
read-model is never stale — it is recomputed, not maintained. Many projections fold the same log, each into its own
shape, without coordinating.

## Reserved names — what a custom event must avoid

Custom names are free, but a few are spoken for. The stream stores its canonical record id under a field named
`id`, so a payload must not also name a field `id` — the reader would not be able to tell the stored id from the
payload field. A key suffix is reserved for the archive watermark, so a stream's own name must not collide with it.
And the whole keyspace is namespaced under a reserved prefix, so a custom stream lives inside that namespace rather
than beside it. The discipline is small and mechanical: keep custom event names and payload field names clear of the
reserved few, and every other name is yours.

## When to use it, when to avoid it

Reach for custom events and projections when the domain produces many kinds of events and several views each need a
different slice or shape of them: an activity feed, per-entity counters, time-windowed rollups, an audit that other
readers also consume. One log per event type keeps each feed focused, and a projection per question keeps each
read-model recomputable from the log.

Avoid a stream per event type when the events are few and one combined log reads fine — splitting then adds keys
without buying focus. And a projection over a long window is work: where a rollup is read far more often than the
window changes, fold once and cache the result (a snapshot), or trim the log to bound the replay (R5.02). A
projection is recomputable, which is the point; recomputing it on every read when the inputs rarely change is waste.

## Applied — EchoMQ.Stream's caller-chosen name and the windowed read

EchoMQ's Stream Tier appends to a stream chosen by the caller. `EchoMQ.Stream.append(conn, queue, name, fields)`
takes a `name`, mints an `EVT`-branded record id host-side, and issues
`XADD emq:{q}:stream:<name> <xadd_id> id <branded> <fields…>` — so the `name` is the domain-event channel and the
key is `emq:{q}:stream:<name>` via `EchoMQ.Keyspace.queue_key/2`. One brand per stream (`EVT`, the kind door in
`EchoMQ.Stream.Id`) keeps the entry order, the id sort, and the mint order one and the same.

```
# EchoMQ.Stream.append/4 — the name IS the domain-event channel (real)
EchoMQ.Stream.append(conn, "cm", "room-opened",  [{"room", room}, {"set", "animals"}])
EchoMQ.Stream.append(conn, "cm", "guess-scored", [{"game", game}, {"player", player}, {"total", "480"}])
EchoMQ.Stream.append(conn, "cm", "game-settled", [{"game", game}, {"winner", winner}, {"pot", "60"}])
#  -> XADD emq:{cm}:stream:room-opened  <xadd_id> id <branded> room … set animals
#  -> {:ok, "EVT0Nk2…"}    (the branded id is the receipt)
```

A projection is a windowed read folded to a read-model. `EchoMQ.Stream.read_window(conn, queue, name, t0, t1,
count)` reads the closed `[t0, t1]` window, and `EchoMQ.Stream.read_since(conn, queue, name, t0, count)` the
half-open `[t0, ∞)` window. Both derive the bounds host-side — `minid_floor/1` turns `t0` into `"<ms>-0"`,
`maxid_ceil/1` turns `t1` into `"<ms>-<max-seq>"` — so the wire only ever sees an `<ms>-<seq>` id and the window
edges are exact. The returned `{branded, fields_map}` tuples are in mint order; fold them to the projection.

The worked consumer is **codemojex** — a Telegram emoji-guessing game on this stack (`echo/apps/codemojex`).
`Codemojex.Rooms.create_room/3` opens a room (a `ROM`), the first joiner starts a game (a `GAM`),
`Codemojex.Guesses.submit/3` enqueues a guess as a `JOB` on the player's `PLR` lane, and `Codemojex.Scoring.score/2`
scores it. Each of those lifecycle moments is a domain event appended to its own named stream; a windowed read of
`guess-scored` folds to the live activity feed, and a read of `game-settled` folds to the day's results.

### The pattern → its EchoMQ application

| The pattern | Its EchoMQ application |
|---|---|
| Give each domain-event type its own named stream and fold a time window of it into a projection. | `EchoMQ.Stream.append/4` takes a caller-chosen `name` → `XADD emq:{q}:stream:<name>`; `read_window/6` and `read_since/5` read a closed `[t0, t1]` or half-open `[t0, ∞)` window in mint order to fold. The worked consumer is codemojex's room / guess / settle events. |

### A door, not a depth — the EchoMQ Bus pillar

This module cites the append with a caller-chosen name and the windowed reads as proof the named log and the
time-bounded read ship. The consumer-group reader, the polyglot seam, retention, and the archive fold are the
subject of the dedicated **EchoMQ course**: open onto [the Bus pillar](/echomq/bus) — the broadcast and the
retained, replayable log. The figures are drawn from the Branded Component System bus chapter,
[`/bcs/bus`](/bcs/bus). Where a windowed history ages out, the trimmed slice folds to the durable floor —
[`/echo-persistence`](/echo-persistence).

## The three dives

Each dive takes one move: the named stream as a domain-event channel, the windowed fold as a projection, and the
reserved-name discipline that keeps custom names safe. Read them in order — the channel, the projection, the
discipline.

- **R5.04.1 · Domain events on the stream** — `append/4` with a caller-chosen `name` as a domain-event channel; one
  brand `EVT` per stream; the codemojex room / guess / settle events.
- **R5.04.2 · Windowed aggregation** — `read_window/6` and `read_since/5`; fold a mint-instant window into a
  projection; the exact `[t0, t1]` and `[t0, ∞)` edges — the R5.01 cursor reapplied.
- **R5.04.3 · Reserved-name discipline** — the reserved `id` field, the `:archived` sub, the `{emq}:` reserve; keep
  custom names and payload fields clear of them.

## References

### Sources

- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the append-only log, entry ids, and
  the range read this pattern is built on.
- [Valkey — XADD](https://valkey.io/commands/xadd/) — append an entry to a named stream, assigning a time-ordered
  id; one stream per domain-event type.
- [Valkey — XRANGE](https://valkey.io/commands/xrange/) — read a range of stream entries in id order, the windowed
  read folded to a projection.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag forces a queue's
  keys onto one of the 16384 slots, so every named stream of one queue is co-located.
- [Kreps — The Log: What every software engineer should know](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)
  — many independent read-models folded from one shared log.

### Related in this course

- [R5.04.1 · Domain events on the stream](custom-events/domain-events-on-the-stream.md) — the named stream as a
  domain-event channel.
- [R5.04.2 · Windowed aggregation](custom-events/windowed-aggregation.md) — the windowed fold as a projection.
- [R5.04.3 · Reserved-name discipline](custom-events/reserved-name-discipline.md) — the reserved `id` field and key
  suffixes.
- [R5.01 · Event sourcing on Streams](../streams-event-sourcing/index.md) — the append-only log and the fold this
  module reapplies to user-defined events.
- [/echomq · Bus](/echomq/bus) — the retained, replayable log in depth.
- [/bcs · The Stream Tier](/bcs/bus) — the manuscript bus chapter, B3.
