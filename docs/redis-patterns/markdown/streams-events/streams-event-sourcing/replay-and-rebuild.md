# R5.01.2 · Replay and rebuild

> Route: `/redis-patterns/streams-events/streams-event-sourcing/replay-and-rebuild` · dive 2 · `XRANGE`

State is derived, not stored: read the log in order and fold the events into an accumulator to reconstruct the
present. `XRANGE` is the read; the fold is the application of each entry in turn.

## XRANGE reads the log in order

`XRANGE key - +` returns every entry of a stream from the first to the last, in id order. `-` is the smallest
possible id and `+` the largest, so the pair reads the whole log; a bounded slice is `XRANGE key <start> <end>
COUNT n`. The entries come back as `[id, [field, value, …]]` pairs, already sorted by id — which, because the log
is append-only, is the order they happened in.

```
XRANGE orders - +                    # the whole log, oldest first
# 1) 1719312000000-0  type placed  amount 4200
# 2) 1719312000001-0  type filled  amount 4200
# 3) 1719312000002-0  type closed
```

Reading in order is the precondition for the rebuild: the fold applies events one at a time, and the result is
correct only if they arrive in the order they were appended. `XRANGE` guarantees that order; no sort is needed
afterward.

## State is the fold of the log

Rebuilding state is a left fold: start with an empty accumulator, and for each entry apply a transition function
that takes the accumulator and the event and returns the next accumulator. The current state is the accumulator
after the last event. The same log folded the same way always yields the same state — the rebuild is deterministic
in the log.

```
state = {}                                    # the empty accumulator
for entry in XRANGE orders - +:
    state = apply(state, entry)               # place -> open, fill -> filled, close -> closed
# state is now the present, reconstructed from the events
```

Nothing is read from a stored "current state": the present is recomputed from the events that produced it. This is
the inversion event sourcing rests on — the log is primary, the state is a view of it.

## The events are immutable; the fold is replaceable

An event, once appended, is never edited. A correction is a new event appended to the end, not an edit of an old
one. So the log is fixed history, and the fold over it is reproducible: replay the same entries and get the same
state. When the way state is derived has a bug, the fix is to change the fold and replay — the events stay exactly
as recorded, and the new state is computed from the unchanged history.

A long log is work to fold, so a rebuild is bounded by a **snapshot**: the folded state saved at a known id, plus
the events after it. A reader loads the snapshot and folds only the tail. The snapshot is an optimisation of the
replay, never a replacement for the log — the log is still the source of truth.

## Applied — EchoMQ.Stream.read/6

`EchoMQ.Stream.read(conn, queue, name, from, to, count)` is the read side of EchoMQ's Stream Tier, in real code in
`echo/apps/echo_mq`. It wraps `XRANGE` and parses each entry back into a `{branded, fields_map}` tuple in mint
order:

```
# EchoMQ.Stream.read/6 — XRANGE, parsed to {branded, fields} in mint order (real)
EchoMQ.Stream.read(conn, "orders", "events")          # from "-", to "+", whole log
#  XRANGE emq:{orders}:stream:events - +
#  -> {:ok, [
#       {"EVT0Nk2…", %{"type" => "placed", "amount" => "4200"}},
#       {"EVT0Nk2…", %{"type" => "filled", "amount" => "4200"}},
#       {"EVT0Nk2…", %{"type" => "closed"}}
#     ]}                                                # mint order, ready to fold
```

The branded record id is recovered from the stored `id` field; the remaining pairs are the payload as a map. The
entries arrive in mint order — which equals the `XRANGE` id order, because the writer mints monotone ids — so a
fold over the returned list reconstructs the current state with no extra sort. `from` and `to` default to the full
range `-`/`+`, and a `COUNT` bounds the slice for a paged replay. The read is un-grouped: it is the order-theorem
proof surface, not the consumer group (that is R5.02).

### The pattern → its EchoMQ application

| The pattern | Its EchoMQ application |
|---|---|
| Read the log in order and fold the events into an accumulator to reconstruct current state; the events are immutable, the state is derived. | `EchoMQ.Stream.read/6` issues `XRANGE emq:{q}:stream:<name>` and hands back `{branded, fields_map}` tuples in mint order, ready to fold; the entries are never mutated, so the fold is reproducible. |

### A door, not a depth — the EchoMQ Bus pillar

This dive cites one excerpt — the un-grouped read in `EchoMQ.Stream.read/6`. The consumer-group read that lets
many readers fold the same log at their own pace, the acknowledgement that resumes a reader where it left off, and
the snapshot-and-replay of a long history are the subject of the dedicated EchoMQ course. From here, open onto
[the Bus pillar](/echomq/bus). This dive teaches the fold; that course teaches the reader law.

## References

### Sources

- [Valkey — XRANGE](https://valkey.io/commands/xrange/) — read a range of stream entries in id order, the rebuild
  read.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the `-`/`+` range bounds and the
  entry shape a reader folds.
- [Valkey — XLEN](https://valkey.io/commands/xlen/) — the length of a stream, the size of the log to be folded.
- [Kreps — The Log: What every software engineer should know](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)
  — replaying the log as the way state is derived.

### Related in this course

- [R5.01 · Event sourcing on Streams](index.md) — the module hub: state is the replay of the log.
- [R5.01.1 · The append-only log](the-append-only-log.md) — the write side, `XADD`.
- [R5.01.3 · The cursor](the-cursor.md) — the entry id as resume position and time bound.
- [R5.02 · Stream consumer patterns](../streams-consumer-patterns/index.md) — reading the log reliably with groups.
- [/echomq/bus](/echomq/bus) — the EchoMQ Bus pillar, the reader law in depth.
