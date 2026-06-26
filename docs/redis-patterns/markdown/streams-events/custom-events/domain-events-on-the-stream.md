# R5.04.1 · Domain events on the stream

> Route: `/redis-patterns/streams-events/custom-events/domain-events-on-the-stream` · dive 1 · a named stream is a domain-event channel

A stream is identified by its name, so each kind of domain event can have its own. Append a `room-opened` to one
stream, a `guess-scored` to another, a `game-settled` to a third, and three independent append-only logs follow —
one channel per event type, each read by exactly the readers that care about it.

## The name is the channel

`XADD key field value …` appends to the stream named `key`, creating it on first append. Choose the key by the event
type and the key *is* the channel: every `room-opened` event lands on the `room-opened` stream, every
`guess-scored` on the `guess-scored` stream. A reader of one feed reads one stream; it does not filter a combined
log to find its events.

```
XADD room-opened   * room ROM0Nk2…  set animals  fee 1     # -> "…000-0"
XADD guess-scored  * game GAM0Nk3…  player PLR0…  total 480 # -> "…000-0" (a separate log)
XADD game-settled  * game GAM0Nk3…  winner PLR0…  pot 60    # -> "…000-0"
```

A new event type costs a new name and nothing else — no shared table to migrate, no enum to extend. The cost of one
stream per type is a key per type; the buy is a focused log per feed, so a reader's range read returns only its own
events in order.

## One brand per stream keeps order sound

Each entry carries a time-ordered id, and a later append always carries a larger id than an earlier one — within one
stream. The order holds because the entries are minted by a single writer in increasing order; the id sort, the
entry order, and the write order are the same sequence. Across two streams the ids are independent — `room-opened`
and `guess-scored` each start their own sequence — so a reader folds one stream at a time, in that stream's order.

## The events are facts, like any event-sourced log

A domain event is a fact that happened: a room was opened, a guess scored 480, a game settled to a winner. It is
appended once, never edited, never deleted as a correction — a correction is a new event. The streams grow forward
only, and any view over them is a fold of the facts. Custom events change *what* the facts are, not the rule that
they are immutable and append-only.

## Applied — EchoMQ.Stream.append/4 and the caller-chosen name

`EchoMQ.Stream.append(conn, queue, name, fields)` is the writer, and the `name` is the domain-event channel. It
mints an `EVT`-branded record id host-side, derives the explicit `XADD` id from it, and issues
`XADD emq:{q}:stream:<name> <xadd_id> id <branded> <fields…>`, returning `{:ok, branded}` — the branded id as the
receipt. The key is `emq:{q}:stream:<name>` via `EchoMQ.Keyspace.queue_key/2`, so each named stream of one queue
shares that queue's `{q}` hash-tag slot.

```
# EchoMQ.Stream.append/4 — name as the domain-event channel (real)
EchoMQ.Stream.append(conn, "cm", "room-opened",  [{"room", room}, {"set", "animals"}])
EchoMQ.Stream.append(conn, "cm", "guess-scored", [{"game", game}, {"player", player}, {"total", "480"}])
#  -> mints an EVT id; XADD emq:{cm}:stream:room-opened <xadd_id> id <branded> room … set animals
#  -> {:ok, "EVT0Nk2…"}    (the branded id is the receipt)
```

One brand per stream is enforced at the door. `EchoMQ.Stream.Id.evt?/1` is the kind predicate, and
`EchoMQ.Stream.append_id/5` raises before any wire if a caller supplies a record id of the wrong namespace. That
single-brand rule is what keeps the order theorem sound: base-62 byte order equals integer order only within one
namespace, so a stream that admits one brand (`EVT`) keeps its byte-ordered ids in mint order. `append/4` mints its
own `EVT` id, so a wrong kind there cannot occur.

The worked consumer is **codemojex** (`echo/apps/codemojex`), a Telegram emoji-guessing game on this stack. Its
lifecycle produces the domain events: `Codemojex.Rooms.create_room/3` opens a room (a `ROM`) and the first joiner
starts a game (a `GAM`); `Codemojex.Guesses.submit/3` enqueues a guess as a `JOB` on the player's `PLR` lane, which
the consumer scores with `Codemojex.Scoring.score/2`; the game settles to a winner. Each of those — room opened,
guess scored, game settled — is one domain event appended to its own named stream, so the activity feed and the
results view each fold their own channel.

### The pattern → its EchoMQ application

| The pattern | Its EchoMQ application |
|---|---|
| A stream is named, so each domain-event type gets its own; one append-only log per channel. | `EchoMQ.Stream.append/4` takes a caller-chosen `name` → `XADD emq:{q}:stream:<name>`; `EchoMQ.Stream.Id` admits one brand (`EVT`) per stream, keeping the id sort equal to mint order. The codemojex room / guess / settle events are one channel each. |

### A door, not a depth — the EchoMQ Bus pillar

This dive cites the named append as proof the domain-event channel ships. The consumer-group reader and the polyglot
seam that consume those channels are the subject of the dedicated **EchoMQ course**: open onto
[the Bus pillar](/echomq/bus) — the broadcast and the retained, replayable log. The figures are drawn from the
Branded Component System bus chapter, [`/bcs/bus`](/bcs/bus).

## References

### Sources

- [Valkey — XADD](https://valkey.io/commands/xadd/) — append an entry to a named stream, creating it on first
  append; one stream per domain-event type.
- [Valkey — Introduction to Streams](https://valkey.io/topics/streams-intro/) — the stream as an append-only log
  identified by its key.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag co-locates a
  queue's named streams on one of the 16384 slots.

### Related in this course

- [R5.04 · Custom events & projections](../custom-events.md) — the module hub.
- [R5.04.2 · Windowed aggregation](windowed-aggregation.md) — folding a window of one channel into a projection.
- [R5.04.3 · Reserved-name discipline](reserved-name-discipline.md) — the reserved `id` field and key suffixes a
  custom name must avoid.
- [R5.01 · Event sourcing on Streams](../../streams-event-sourcing/index.md) — the append-only log this reapplies to
  user-defined events.
- [/echomq · Bus](/echomq/bus) — the retained, replayable log in depth.
