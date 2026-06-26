# R5.01.3 · The cursor

> Route: `/redis-patterns/streams-events/streams-event-sourcing/the-cursor` · dive 3 · the entry id as resume position and time bound

The stream entry id is the cursor: it orders the log, it is the resume position a reader saves, and — because the
id carries the time the entry was added — a `DateTime` becomes a range bound, so the log can be read as of any past
instant.

## The entry id is the resume position

A reader of a long log does not re-read from the start each time. It remembers the id of the last entry it
processed, and the next read starts strictly after that id: `XRANGE key (<last-id> +` reads everything newer than
`<last-id>` — the `(` makes the bound exclusive. The saved id is the cursor; advancing it is the whole of
"resume". Because the id is monotonic, "after this id" is unambiguous, and a restarted reader picks up exactly
where it stopped.

```
# first read — from the start
XRANGE orders - + COUNT 100        # … last entry id 1719312000099-0
# save the cursor: 1719312000099-0
# next read — strictly after the cursor
XRANGE orders (1719312000099-0 + COUNT 100
```

The cursor is just an id, so it is cheap to store anywhere — a key, a row, a variable. A reader is defined by its
cursor: where it is in the log is the id it last saw.

## The id carries time, so time is a bound

A stream entry id begins with the millisecond the entry was added. That makes the id a clock: an instant maps to
an id, and an id range expresses a time range. To read "everything from time `t` onward", form the smallest id at
that millisecond — `<t-in-ms>-0` — and range from there:

```
XRANGE orders 1719312000000-0 +    # every entry from that millisecond onward
XRANGE orders 1719312000000-0 1719315600000-0   # a closed time window
```

This is the time-travel read: state as of a past instant is the fold of the log up to that instant. Folding the
events with id at or below `<t>` reconstructs exactly what was true at `t` — the log read as a function of time.

## The archive frontier — a cursor into durable history

A log is trimmed so it does not grow without bound (R5.02). What is trimmed is not lost: it folds into a durable
store, and a watermark records how far the archive has advanced. That watermark is itself a cursor — the id of the
highest entry already archived. Below it is deep history, read from the durable floor; above it is the live tail,
read from the stream. A reader chooses which side of the watermark it needs, and the two read paths meet at that
one id.

## Applied — EchoMQ.Stream.read_since/5 and the archive cursor

EchoMQ derives the time bound host-side so the wire only ever sees an `<ms>-<seq>` id, never a raw integer.
`EchoMQ.Stream.read_since(conn, queue, name, %DateTime{} = t0, count)` reads everything minted at or after `t0`,
in real code in `echo/apps/echo_mq`:

```
# EchoMQ.Stream.read_since/5 — a DateTime becomes a range bound (real)
EchoMQ.Stream.read_since(conn, "orders", "events", ~U[2024-06-25 12:00:00Z])
#  from = minid_floor(t0)  ->  "<ms>-0"     (the smallest id at that ms)
#  to   = "+"                                (the live top)
#  XRANGE emq:{orders}:stream:events <ms>-0 +
#  -> {:ok, [{branded, fields_map}, …]}      mint order, [t0, ∞)
```

`minid_floor/1` turns `t0` into `"<ms>-0"` — the lowest id at that millisecond — so the half-open `[t0, ∞)` edge
is exact: an entry minted at `t0` is included, one minted a millisecond earlier is not. `read_window/6` adds the
inclusive upper bound `maxid_ceil/1` (`"<ms>-<max-seq>"`) for a closed `[t0, t1]` window — backtest, audit, debug.
The branded `EVT` mint instant of each returned entry falls inside the window, in mint order.

The archive watermark is a cursor too. `EchoMQ.Stream.put_archived/4` caches the branded `EVT` id of the
highest-folded record under `emq:{q}:stream:<name>:archived`, and `EchoMQ.Stream.get_archived/3` reads it back —
`{:ok, w}` for a recorded seam, or `:empty` when the whole stream is still live tail. A polyglot reader discovers
where the archive ends and the live tail begins from that one id, without a store call. What is below the
watermark folds to the durable floor; the store-side `EchoStore.StreamArchive.fold/3` is the engine that puts it
there.

### The pattern → its EchoMQ application

| The pattern | Its EchoMQ application |
|---|---|
| The entry id is the cursor — the resume position, and a time bound because the id carries the time. | `EchoMQ.Stream.read_since/5` turns a `%DateTime{}` into the floor id `"<ms>-0"` via `minid_floor/1` and ranges from it; the archive watermark `emq:{q}:stream:<name>:archived` is the cursor where durable history meets the live tail. |

### A door, not a depth — the persistence floor

What is trimmed off the log folds into the durable page tier and, beyond it, to remote object storage behind a
create-only commit fence. That floor — the single-writer engine, the lazy reader, the durability dial a system
turns from "hold nothing" to "commit-per-record + replicate off-box" — is the subject of
[the EchoStore persistence course](/echo-persistence). `EchoStore.StreamArchive.fold/3` folds a trimmed slice into
it. This dive teaches the cursor; that course teaches the floor the archive cursor points into. The Bus pillar that
owns the stream is [`/echomq/bus`](/echomq/bus).

## References

### Sources

- [Valkey — XRANGE](https://valkey.io/commands/xrange/) — the exclusive `(` bound and the `<ms>-<seq>` id range,
  the cursor and the time bound.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the entry id as a clock and a
  resume position.
- [Valkey — XINFO STREAM](https://valkey.io/commands/xinfo-stream/) — the stream's last id, the top the cursor
  chases.
- [Kreps — The Log: What every software engineer should know](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)
  — the offset into the log as the reader's position.

### Related in this course

- [R5.01 · Event sourcing on Streams](index.md) — the module hub: the entry id is the cursor.
- [R5.01.1 · The append-only log](the-append-only-log.md) — the write side, `XADD`.
- [R5.01.2 · Replay and rebuild](replay-and-rebuild.md) — the read side, `XRANGE` and the fold.
- [R5.02 · Stream consumer patterns](../streams-consumer-patterns/index.md) — trimming the log and the archive.
- [/echo-persistence](/echo-persistence) — the durable floor a trimmed segment folds into.
