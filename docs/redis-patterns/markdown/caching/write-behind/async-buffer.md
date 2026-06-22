# The async buffer

> Route: `/redis-patterns/caching/write-behind/async-buffer` · Module R1.03 · dive 1 · Source:
> `content/fundamental/write-behind.md.txt` (the *How It Works* sequence + *The Sync Process*) · Grounding:
> `EchoCache.Journal.intend_and_enqueue/4` — the outbox in one verb. Engine: Valkey.

The write lands in Valkey and returns; a separate worker carries it to the database later, on its own clock. This is the
write half of write-behind — the source's *How It Works* sequence and its *Sync Process*, focused on the buffer that
absorbs the burst.

## One write, two paths

A read-through cache fronts reads; a write-behind cache fronts *writes*. The application stops writing the database on
the request and writes Valkey instead. Two operations happen together on the write path: the value is stored (a `SET` on
a String, or an `HSET` on a Hash), and the changed key is pushed onto a write-buffer List with `LPUSH`. The caller is
acknowledged the moment both succeed — no database round trip is on the path.

The flush path is a separate background worker on a timer. Each tick it drains the buffer from the tail with `RPOP`,
reading keys in arrival order, looks up the current value of each, and writes them to the database in one batch. Two
paths, one store: the write path fills the buffer, the flush path empties it.

```
# write path — runs on the request, returns at once
SET   ecc:{limits}:LIM0NgWEfAEJfs  {…}   # store the new value in Valkey
LPUSH writebuf  LIM0NgWEfAEJfs           # mark the key dirty on the buffer List
# -> ack the caller. No database write here.

# flush path — a background worker, on a timer
RPOP  writebuf                           # -> "LIM0NgWEfAEJfs" (arrival order)
GET   ecc:{limits}:LIM0NgWEfAEJfs        # read the current value
# -> write the batch to the database in one round trip
```

- **write path** — on the request: store the value, `LPUSH` the key onto the buffer, acknowledge. No database round
  trip.
- **write buffer** — a Valkey List of changed keys, filled with `LPUSH` at the head and drained with `RPOP` at the tail
  — first in, first out.
- **flush path** — a background worker that drains the buffer on a timer and writes the batch to the database, off the
  request path.
- **flush interval** — how long the worker waits between drains. Longer means bigger batches and fewer database writes;
  it also means more pending writes between flushes.

A List buffer keeps a key once per change, so the same key can appear several times. The coalescing dive (R1.03.3) swaps
the List for a dirty-set that keeps each key once.

## Drain the buffer, tick by tick

Step the flush worker through a fixed buffer to watch the two paths interleave. The buffer starts with five queued
writes. Each *arrive* pushes another key on with `LPUSH`; each *flush* drains everything pending with `RPOP` and writes
one database batch. The readout reports the buffer depth, the total database batches, and how many writes a single batch
carried. The write path never waits for the flush path: a burst piles into the buffer and leaves the database in a
handful of batches, not one round trip per write.

## On EchoCache — the outbox in one verb

EchoCache's write-behind path is the transactional outbox in `EchoCache.Journal`. The writer's verb,
`intend_and_enqueue/4` (`journal.ex:66`), is the two paths made real: it mints a `JOB` id, `record`s the intent in a
local SQLite file, calls `Lanes.enqueue` (the async job lane over EchoMQ) with the coherence payload, and
`mark_enqueued`s the intent. The write returns after the **local record** — the bus carries the apply off the write
path, exactly the split this dive draws.

```elixir
{:ok, job_id} = Journal.intend_and_enqueue(:limits_journal, conn, name_id, version)
```

The job lane is `EchoCache.Coherence.enqueue/5` (`coherence.ex:89`): `Lanes.enqueue(conn, queue(table), group, JOB-id,
payload)` — "the job lane: at-least-once over EchoMQ's fair lanes." The key the value lands under is
`ecc:{<table>}:<id>` (`EchoCache.Keyspace.key/2`, `keyspace.ex:20`) — the table name hash-tagged so one cache lands in
one cluster slot. The fair-lanes queue itself is the EchoMQ protocol; the [`/echomq` course](/echomq) teaches it in
depth.

## References

### Sources
- [Valkey — LPUSH](https://valkey.io/commands/lpush/) — pushes the changed key onto the head of the write-buffer List.
- [Valkey — RPOP](https://valkey.io/commands/rpop/) — the flush worker drains the buffer from the tail, keys in arrival order.
- [Valkey — SET](https://valkey.io/commands/set/) — stores the value on the write path before the buffer mark.
- [Redis — Documentation](https://redis.io/docs/) — Lists as a queue, and the data structures a write buffer is built from.

### Related in this course
- [R1.03 · Write-behind](/redis-patterns/caching/write-behind) — the module hub.
- [R1.03.2 · The durability trade-off](/redis-patterns/caching/write-behind/durability) — the next dive.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/echomq](/echomq) — the fair-lanes job queue the apply rides.
