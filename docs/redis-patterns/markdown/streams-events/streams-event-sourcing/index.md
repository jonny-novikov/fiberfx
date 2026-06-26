# R5.01 · Event sourcing on Streams

> Route: `/redis-patterns/streams-events/streams-event-sourcing` · module hub · pattern: **the append-only log is the source of truth; state is its replay.**

Store every change as an immutable event appended to a log, and treat that log as the source of truth: current
state is not stored directly, it is the replay of the events that produced it. A Redis Stream is the structure —
an append-only sequence of entries, each with a server-or-caller-assigned id that orders it against every other.

## The pattern in one move

A row says what is true now. A log says everything that ever happened, in order. Event sourcing keeps the log and
derives the row: nothing is overwritten, every transition is appended, and the present is reconstructed by folding
the log from the start. Three properties follow, and they are the three dives:

- **The log is the source of truth.** Every state change is appended, never updated in place. `XADD` adds an entry
  to the end of a stream and returns its id; the entry is immutable once written.
- **State is derived, not stored.** `XRANGE` reads the log in order; folding the entries — applying each in turn to
  an accumulator — reconstructs the current state. The state is a view of the log, recomputable at any time.
- **The entry id is the cursor.** A stream entry id is monotonic and orders the log. It is the resume position a
  reader saves, and — because the id carries time — a `DateTime` becomes a range bound, so the log can be read as
  of any past instant.

## How it works

A Redis Stream is created the first time something is appended to it. `XADD key * field value …` appends an entry,
assigning a time-ordered id of the form `<milliseconds>-<sequence>`; the `*` asks the server to mint the id, or an
explicit id may be supplied. The entries form an ordered log: a later append always carries a larger id than an
earlier one.

Reading is by range. `XRANGE key - +` returns every entry from the first (`-`) to the last (`+`) in id order;
`XRANGE key <start> <end> COUNT n` reads a bounded slice. To rebuild state, a reader starts with an empty
accumulator and applies each entry in order — the same fold every time, deterministic in the log.

## The events are immutable; the state is a fold

An event is a fact that happened: it is never edited and never deleted as a correction (a correction is a new
event). The log grows forward only. Because the entries never change, the fold over them is reproducible: replay
the same log and get the same state. A bug in how state is derived is fixed by changing the fold and replaying —
the events stay as they were recorded.

## When to use it

Use event sourcing when the history matters as much as the present: an audit trail, a feed of activity, a value
that must be reconstructable as of a past time, or a state machine whose transitions other readers also consume.
The log is the one authority; multiple independent readers each fold it for their own view.

## When to avoid it

Avoid it when only the latest value matters and history is noise — a plain key holds the current value far more
cheaply than a log that must be folded. A log also grows without bound unless retention is applied (the subject of
R5.02); an unbounded log is a leak. And a fold over a long history is work — a snapshot of the folded state, taken
periodically, bounds the replay a reader must do.

## Applied — EchoMQ's Stream Tier

EchoMQ's bus carries a queue (work claimed and completed once) and, beside it, a **Stream Tier**: an append-only
log many readers consume at their own pace. `EchoMQ.Stream` is the writer. `EchoMQ.Stream.append(conn, queue,
name, fields)` mints an `EVT`-branded record id host-side, derives the explicit `XADD` id from it, and issues
`XADD emq:{q}:stream:<name> <xadd_id> id <branded> <fields…>` — returning `{:ok, branded}`, the branded id as the
receipt. The log is ordered by append the way the property store is ordered by mint: a strictly monotone writer
makes the stream id, the entry order, and the mint order one and the same.

`EchoMQ.Stream.read(conn, queue, name, from, to, count)` wraps `XRANGE` and parses each entry back into a
`{branded, fields_map}` tuple in mint order — the read side of the rebuild. The stream key
`emq:{q}:stream:<name>` carries the per-queue `{q}` hash tag, so every key of one queue lands on one Valkey
cluster slot. The three dives ground in this writer and reader: the append, the rebuild, and the cursor.

### The pattern → its EchoMQ application

| The pattern | Its EchoMQ application |
|---|---|
| Append every state change as an immutable entry to a log that is the source of truth; reconstruct current state by folding the log from the start. | `EchoMQ.Stream.append/4` issues `XADD emq:{q}:stream:<name>` and returns the branded `EVT` id; `EchoMQ.Stream.read/6` issues `XRANGE` and hands the entries back in mint order to fold. The append order is the truth order. |

## The three dives

1. **[The append-only log](the-append-only-log.md)** — `XADD`: the log is the source of truth, every transition
   appended, the entry immutable once written.
2. **[Replay and rebuild](replay-and-rebuild.md)** — `XRANGE`: fold the log to reconstruct current state; an event
   is immutable, state is derived.
3. **[The cursor](the-cursor.md)** — the stream entry id as the resume position; `read_since` from a `%DateTime{}` —
   time as a range bound, the time-travel seam.

## References

### Sources

- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the append-only log, entry ids, and
  the range read this pattern is built on.
- [Valkey — XADD](https://valkey.io/commands/xadd/) — append an entry to a stream, assigning a time-ordered id.
- [Valkey — XRANGE](https://valkey.io/commands/xrange/) — read a range of stream entries in id order, the rebuild read.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag forces a queue's
  keys onto one of the 16384 slots.
- [Kreps — The Log: What every software engineer should know](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)
  — the log as the shared abstraction beneath a stream.

### Related in this course

- [R5.01.1 · The append-only log](the-append-only-log.md) — the write side, `XADD`.
- [R5.01.2 · Replay and rebuild](replay-and-rebuild.md) — the read side, `XRANGE` and the fold.
- [R5.01.3 · The cursor](the-cursor.md) — the entry id as resume position and time bound.
- [R5.02 · Stream consumer patterns](../streams-consumer-patterns/index.md) — reading the log reliably.
- [/echomq/bus](/echomq/bus) — the EchoMQ Bus pillar: the retained, replayable log in depth.
- [/bcs/bus](/bcs/bus/the-stream-tier) — the Stream Tier in the Branded Component System manuscript (B3.3).
