# R5.02.3 · MAXLEN trimming

> Route: `/redis-patterns/streams-events/streams-consumer-patterns/maxlen-trimming` · dive
> Grounding: `echo/apps/echo_mq/lib/echo_mq/stream.ex` — `trim/4 {:maxlen, count, approx?}` /
> `{:minid, dt, approx?}`; `stream_retention.ex` the opt-in driver;
> `echo/apps/echo_store/lib/echo_store/stream_archive.ex` — `fold/3` to the durable floor.

A log that only grows is a leak. A stream keeps every entry until something removes it, and acknowledgement
does not remove it — `XACK` marks an entry handled in the group's metadata, but the entry itself stays in the
log. So a stream needs a retention policy, and the right tool is `XTRIM`, not `XDEL`. This dive is the
operational close of the module: bound the log by length or age, do it approximately so it is cheap, make it a
policy rather than a default, and fold what is trimmed into a durable floor so bounded memory does not mean
lost history.

## XTRIM, not XDEL

The tempting cleanup is to `XDEL` an entry right after `XACK`ing it. It is harmful. A stream stores entries in
a radix tree of macro-nodes (listpacks). `XDEL` marks an entry deleted but does not free the memory until the
entire macro-node is empty, so heavy `XDEL` use leaves "Swiss cheese" fragmentation — memory that is logically
free but physically held.

The correct pattern keeps the two concerns apart:

- `XACK` marks an entry handled — consumer-group state only, it does not touch the log.
- `XTRIM` enforces retention — it frees memory by removing whole macro-nodes from the tail.

`XADD ... MAXLEN ~ N` trims on every write; `XTRIM ... MAXLEN ~ N` trims periodically. Either way the unit of
work is a macro-node, which is why approximate trimming is the cheap default.

## Approximate trimming — why `~`

`MAXLEN ~ N` does not promise exactly `N` entries. The `~` selects approximate trimming: Valkey removes whole
macro-nodes from the tail and stops when removing the next one would drop the count below `N`. So it may keep a
little more than `N` — it under-trims — but it never removes an entry it should have kept. The payoff is CPU:
trimming a whole listpack at once is dramatically cheaper than walking to an exact boundary entry. The exact
form, `MAXLEN = N`, removes precisely to the edge and is the opt-in for when the count must be exact.

`MINID ~ <ms>-0` trims by time instead of count — it removes every entry whose id is older than the floor, the
timestamp-based retention horizon.

## trim/4 — the verb

EchoMQ exposes both forms as one verb, `EchoMQ.Stream.trim/4`, issued direct over `XTRIM`:

```elixir
def trim(conn, queue, name, {:maxlen, count, approx?}) do
  key = stream_key(queue, name)
  xtrim(conn, ["XTRIM", key, "MAXLEN", approx_flag(approx?), Integer.to_string(count)])
end

def trim(conn, queue, name, {:minid, %DateTime{} = dt, approx?}) do
  key = stream_key(queue, name)
  xtrim(conn, ["XTRIM", key, "MINID", approx_flag(approx?), minid_floor(dt)])
end
```

`{:maxlen, count, approx?}` keeps the `count` newest entries; `{:minid, dt, approx?}` keeps entries minted at
or after a `DateTime`, with the floor `"<ms>-0"` **derived** from the branded mint instant — never a raw
snowflake integer handed to the wire. `approx?` true selects `~` (the safe default — it may under-trim but can
**never** over-trim, so a trim can never delete inside the declared window); false selects `=` (exact, the
opt-in). Either way the blast radius is bounded by the window: a trim can never delete an entry inside it. The
call returns `{:ok, removed_count}` — and under `~` that count can be `0` even when entries are old, because
approximate trimming works in whole macro-nodes.

## Retention is a policy, not a default

A trim is a destructive verb, so it is never coupled to the append and never folded into a consumer's beat.
`EchoMQ.StreamRetention` is the named, **opt-in** driver: a supervised process that beats on a tick and
re-applies a declared per-stream policy through the public `trim/4`. Two design choices make it safe.

It is **decoupled from consumer liveness**: a stream nobody drains still trims if its policy is declared,
because bounded memory is a safety property and "a consumer is up" is a liveness fact — coupling a safety
property to a liveness fact is the silent-no-op class the design refuses, so the cadence lives on its own beat.

And it is **owner-started**: a deployment that wants continuous bounded memory over a stream starts the driver
for it; a stream the operator wants unbounded is not declared and is never silently trimmed. A manual
`EchoMQ.Stream.trim/4` call is the equally-supported cadence — the driver is sugar over the verb, not the only
path to it.

## What is trimmed is not lost

Trimming frees memory, but the history a trimmed entry held may still matter for an audit or a backtest. The
two needs are reconciled by folding what is trimmed into a durable floor before it is removed.
`EchoStore.StreamArchive.fold/3` folds a mint-ordered slice of `{branded, fields}` records into the native
Graft engine's page store — one page per record, in a reserved high page range disjoint from business data —
and advances a watermark `W` to the branded `EVT` id of the highest-folded record:

```elixir
EchoStore.StreamArchive.fold(volume_id, slice, db)
#=> {:ok, w}     # the new frontier — the highest folded branded id
```

The fold commits **before** the trim removes anything, so an entry is durable in the floor before it leaves the
live log — no-gap, no-overlap is a consequence of fold-before-trim plus the order theorem, not a per-read
check. A reader then merges the two: records with a branded id at or below `W` come from the archive, records
above `W` come from the live tail, joined in mint order. Deep history stays readable without resident memory.
That archive frontier is where the durability dial lives — how much to keep, where, behind what fence — taught
in full at `/echo-persistence`.

## The pattern, applied

A codemojex game's activity stream (`echo/apps/codemojex`) grows as rounds are played. The operator declares a
retention policy — keep the recent window live — and `EchoMQ.StreamRetention` trims it on its beat with
`MAXLEN ~`, so memory stays bounded no matter how long the game runs. Before each trim, the trimmed segment is
folded to the Graft floor, so the full round history of a long-running game is recoverable for a leaderboard
audit even though only the recent window sits in the live log.

## References

### Sources

- [Valkey — XTRIM](https://valkey.io/commands/xtrim/) — `MAXLEN ~` and `MINID` retention; the `~` trims whole
  macro-nodes, the `=` trims to an exact edge.
- [Valkey — XADD](https://valkey.io/commands/xadd/) — the `MAXLEN ~ N` trim-on-write form and why `XDEL` is the
  wrong cleanup.
- [Valkey — XLEN](https://valkey.io/commands/xlen/) — the live length a retention policy bounds.
- [Tigris — Conditional operations](https://www.tigrisdata.com/docs/objects/conditionals/) — the create-only
  fence an archived segment lands behind on the durable floor.

### Related in this course

- [R5.02 · Stream consumer patterns](/redis-patterns/streams-events/streams-consumer-patterns) — the module
  hub.
- [R5.02.1 · The blocking read](/redis-patterns/streams-events/streams-consumer-patterns/the-blocking-read) —
  the long-poll the reader uses.
- [R5.02.2 · Consumer groups](/redis-patterns/streams-events/streams-consumer-patterns/consumer-groups) — the
  reader law on the log this trims.
- [/echo-persistence](/echo-persistence) — the durability dial a trimmed segment folds onto.
- [/bcs/bus](/bcs/bus) — the manuscript bus chapter the Stream Tier figures are drawn from.
