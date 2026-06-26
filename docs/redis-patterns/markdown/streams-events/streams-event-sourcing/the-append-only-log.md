# R5.01.1 · The append-only log

> Route: `/redis-patterns/streams-events/streams-event-sourcing/the-append-only-log` · dive 1 · `XADD`

The log is the source of truth: every state change is appended, never updated in place. A Redis Stream is the
structure — `XADD` adds an entry to the end and returns its id; the entry is immutable once written.

## A stream is an append-only log

A Redis Stream is an ordered sequence of entries, each a small set of field-value pairs under an id. The only way
to add to it is `XADD`, which appends to the end and returns the new entry's id. There is no in-place update of a
written entry: a stream grows forward only. That single property — append, never overwrite — is what makes it the
right structure for event sourcing.

```
XADD orders * type placed payment 4200   # append; * mints a time-ordered id
                                          # -> "1719312000000-0"
XADD orders * type filled  amount  4200   # append the next event
                                          # -> "1719312000001-0"
```

The id is `<milliseconds>-<sequence>`: the millisecond the entry was added, then a sequence number that breaks ties
within the same millisecond. A later append always carries a larger id than an earlier one, so the id orders the
log. The `*` asks the server to mint the id; an explicit id may be supplied instead, and must exceed the current
top of the stream or `XADD` rejects it.

## Every transition is an event

Event sourcing records each change as its own entry. An order placed, an order filled, an order cancelled — three
events, appended in the order they happened, never collapsed into one mutable "order" row. The log holds the whole
history; the present is whatever the history adds up to. Because nothing is overwritten, the log is an audit trail
for free: it says not only what is true now but how it came to be true.

## The append rejects a smaller id

A stream's entry id must strictly exceed its current top. `XADD` with an explicit id at or below the top is
refused — the server answers an error rather than break the order. This is the property that keeps the log a log:
the id sequence is strictly increasing, so reading by id reads in append order. A writer that mints ids in order
never trips it; one that does trips it loudly, and the error is not swallowed.

## Applied — EchoMQ.Stream.append/4

`EchoMQ.Stream` is the writer of EchoMQ's Stream Tier. `EchoMQ.Stream.append(conn, queue, name, fields)` does the
append in four steps, in real code in `echo/apps/echo_mq`:

```
# EchoMQ.Stream.append/4 — the append, shaped to the wire (real)
EchoMQ.Stream.append(conn, "orders", "events", [{"type", "placed"}, {"amount", "4200"}])
#  1. mint an EVT-branded record id host-side  (EchoData.Snowflake.next_branded("EVT"))
#  2. derive the explicit XADD id from it       (Stream.Id.xadd_id/1 — "<ms>-<tail22>")
#  3. XADD emq:{orders}:stream:events <xadd_id> id <branded> type placed amount 4200
#  4. -> {:ok, branded}    (the branded id is the receipt)
```

The writer owns the mint, so there is nothing to spoof — the id comes from the host, not a client. The 14-byte
branded id is stored as the stream entry's `id` **field**, so a reader in any language gets the canonical id
without re-encoding it. The append returns `{:ok, branded}`; a Valkey rejection of an id at or below the top is
mapped to `{:error, :nonmonotonic}` — never swallowed, never retried with `*`, because that error is the wire
telling the truth that an upstream mint-order violation happened.

The order theorem holds because a single writer per stream mints strictly increasing snowflakes: successive mints
are strictly increasing, so the next id always exceeds the stream top and no `XADD` rejection is possible. Stream
order equals id sort equals mint order — the log is ordered by append the way the property store is ordered by
mint.

### The pattern → its EchoMQ application

| The pattern | Its EchoMQ application |
|---|---|
| Append every state change as an immutable entry to a log; the id orders it, and a smaller id is refused. | `EchoMQ.Stream.append/4` mints an `EVT` id, derives the `XADD` id, issues `XADD emq:{q}:stream:<name>`, and returns the branded id; an `id≤top` rejection surfaces as `{:error, :nonmonotonic}`. |

### A door, not a depth — the EchoMQ Bus pillar

This dive cites one excerpt — the append in `EchoMQ.Stream.append/4`. The batch append, the explicit kind door on
a caller-supplied id, and the way the writer's monotone mint proves the order theorem are the subject of the
dedicated EchoMQ course. From here, open onto [the Bus pillar](/echomq/bus). This dive teaches the append; that
course teaches the writer that runs it.

## References

### Sources

- [Valkey — XADD](https://valkey.io/commands/xadd/) — append an entry to a stream, assigning a time-ordered id; the
  explicit-id rejection of an id at or below the top.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the append-only log and the
  `<ms>-<seq>` entry id.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag forcing a queue's
  stream key onto one of the 16384 slots.
- [Kreps — The Log: What every software engineer should know](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying)
  — the append-only log as the shared abstraction.

### Related in this course

- [R5.01 · Event sourcing on Streams](index.md) — the module hub: the log is the source of truth.
- [R5.01.2 · Replay and rebuild](replay-and-rebuild.md) — read the log back and fold it to current state.
- [R5.01.3 · The cursor](the-cursor.md) — the entry id as resume position and time bound.
- [R3.01 · Processing list](../../../queues/processing-list/index.md) — the queue beside the log, claimed once.
- [/echomq/bus](/echomq/bus) — the EchoMQ Bus pillar, the writer in depth.
