# R5.04.3 · Reserved-name discipline

> Route: `/redis-patterns/streams-events/custom-events/reserved-name-discipline` · dive 3 · the names a custom event must keep clear of

Custom event names and payload fields are free to choose — with a few exceptions. A stream stores its canonical
record id under a field named `id`, a key suffix is reserved for the archive watermark, and the whole keyspace lives
under a reserved prefix. A custom event keeps clear of those few, and every other name is yours.

## The `id` field is reserved

When an entry is appended, the stream stores the record's canonical id under a field named `id`, alongside the
payload fields. A reader recovers the id from that field and treats the rest as the payload. So a payload must not
also carry a field named `id`: the reader could not tell the stored record id from the payload value, and one would
shadow the other. Name the domain's own identifier something specific — `room`, `game`, `player` — and leave `id`
to the stream.

```
# right — the payload names its entities specifically
XADD guess-scored * game GAM0Nk3…  player PLR0…  total 480
# wrong — a payload "id" collides with the stored record id field
XADD guess-scored * id 480  game GAM0Nk3…                 # ambiguous on read
```

## A key suffix and a prefix are reserved

A stream's history can be archived, and a small cache records how far the archive has advanced — under a key formed
by adding a reserved suffix to the stream's key. So a stream name must not be chosen such that its key collides with
that watermark key. And every key in the system lives under a reserved namespace prefix, so a custom stream lives
*inside* that namespace rather than beside it — the name is the part after the prefix, not a free-standing key. Two
mechanical rules: do not reuse the reserved suffix as part of a stream name, and let the namespace own the prefix.

## Why the discipline is small

The reserved set is short because the contract is narrow: one field name for the stored id, one suffix for the
archive seam, one prefix for the namespace. None of them constrains the *shape* of a custom event — the payload can
hold any fields under any other names, and a stream can be named for any event type. The discipline is a handful of
names to avoid, checked once when a new event type or payload is designed, not a schema to satisfy on every append.

## Applied — the reserved names in EchoMQ.Stream

EchoMQ's Stream Tier makes the three reserves concrete. The record id is stored under the field `id`:
`EchoMQ.Stream.append/4` issues `XADD <key> <xadd_id> id <branded> <fields…>`, and on read,
`EchoMQ.Stream.read/6` recovers the branded id from the `id` field and **deletes `id` from the payload map** before
returning `{branded, fields_map}`. A custom event that named a payload field `id` would have it consumed as the
record id, so the field name `id` is reserved.

```
# EchoMQ.Stream — the id field is the stored record id, deleted from the payload on read (real)
EchoMQ.Stream.append(conn, "cm", "guess-scored", [{"game", game}, {"total", "480"}])
#  -> XADD emq:{cm}:stream:guess-scored <xadd_id> id <branded> game <game> total 480
EchoMQ.Stream.read(conn, "cm", "guess-scored")
#  -> {:ok, [{branded, %{"game" => game, "total" => "480"}}, …]}   ("id" recovered, then removed)
```

The archive seam is the second reserve. `EchoMQ.Stream.put_archived/4` caches the watermark under
`emq:{q}:stream:<name>:archived` via `EchoMQ.Keyspace.queue_key/2` — the `:archived` sub on the stream's key. A
stream name must not collide with that suffix. The third reserve is the protocol's namespace: every key is built by
`EchoMQ.Keyspace`, braced as `emq:{q}:`, so a custom stream's name is the `<name>` in `emq:{q}:stream:<name>`, owned
by the keyspace builder rather than a bare key. Keep custom event names and payload field names clear of `id`, the
`:archived` suffix, and the `emq:{q}:` prefix, and the rest is the domain's to name.

In **codemojex** (`echo/apps/codemojex`), the queue is `cm` and the consumer surfaces — `Codemojex.Guesses`,
`Codemojex.Board`, `Codemojex.Scoring`, `Codemojex.Rooms` — name their entities `room`, `game`, `player` rather than
`id`, so a domain event appended to a codemojex stream leaves the `id` field to the record id and keeps its payload
unambiguous.

### The pattern → its EchoMQ application

| The pattern | Its EchoMQ application |
|---|---|
| A few names are reserved — the stored-id field, an archive suffix, a namespace prefix; a custom event keeps clear of them. | `EchoMQ.Stream` stores the record id under the field `id` (and `read/6` deletes it from the payload), reserves `emq:{q}:stream:<name>:archived` for the watermark, and builds every key under the braced `emq:{q}:` namespace via `EchoMQ.Keyspace`. |

### A door, not a depth — the EchoMQ Bus pillar

The archive watermark this dive names is the seam between the live stream and the durable floor; the fold that
advances it, and the full keyspace grammar, are the subject of the dedicated **EchoMQ course**:
[the Bus pillar](/echomq/bus). The figures are drawn from the Branded Component System bus chapter,
[`/bcs/bus`](/bcs/bus). What is archived below the watermark folds to the persistence floor,
[`/echo-persistence`](/echo-persistence).

## References

### Sources

- [Valkey — XADD](https://valkey.io/commands/xadd/) — fields are appended as flat name/value pairs, the stored `id`
  field beside the payload.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — entry fields and the entry id.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the braced hash tag the `emq:{q}:`
  namespace uses to co-locate a queue's keys.

### Related in this course

- [R5.04 · Custom events & projections](../custom-events.md) — the module hub.
- [R5.04.1 · Domain events on the stream](domain-events-on-the-stream.md) — the named channel.
- [R5.04.2 · Windowed aggregation](windowed-aggregation.md) — the windowed fold, and the archive watermark a window
  ages past.
- [R5.01 · Event sourcing on Streams](../../streams-event-sourcing/index.md) — the log this module reapplies.
- [/echomq · Bus](/echomq/bus) — the keyspace and the archive seam in depth.
