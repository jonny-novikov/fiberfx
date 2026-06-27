# Write-through

> Route: `/redis-patterns/caching/write-through` · Module R1.02 · Source: `content/fundamental/write-through.md.txt`
> · Grounding: `EchoStore.Table.put/3,4` (`echo/apps/echo_store/lib/echo_store/table.ex`) — the writer path that
> sets both layers under one TTL, framed with the write's mint-time version; the engine is Valkey.

Maintain cache-database consistency by synchronously writing to both the cache and the database before returning
success — so reads always hit the cache with fresh data. Every write updates both the cache and the backing database
synchronously, before the operation acknowledges success. This eliminates cache misses for recently written data at
the cost of higher write latency: the trade against cache-aside, which fills the cache lazily on a read miss and
invalidates on a write, leaving a window where the cache holds a stale value.

## How It Works

When a write occurs, three steps run in order:

1. The application writes the data to the cache.
2. The application writes the same data to the database.
3. Only after both writes succeed does the operation complete.

The cache and the database are always updated together, which keeps them consistent with each other. A write-through
cache treats the two stores as one write target: the writer sets the cache with `SET … PX` and the database with an
update, and the write does not return until both are done. Because the cache was updated on the same path as the
source, a read that follows serves the cached value and matches the database.

## Redis Commands Used

A typical write-through operation is a single cache write followed immediately by the corresponding database write,
and the application returns success to the client only after both complete:

```
SET ecc:{instruments}:AST0NgWEfAEJfs "<version><value>" PX 300000   # the cache write, value + TTL atomically
UPDATE instruments ... WHERE id = ...                               # the corresponding database write
# return success only after both acknowledge
```

`SET … PX` sets the value and the millisecond TTL in one command — value and expiry together, atomically. A separate
`EXPIRE` after `SET` leaves an immortal key if the process dies between the two. The cache half of a write-through
write is one command; the dual-write dive takes that command apart.

**On EchoStore.** `EchoStore.Table.put/3` is the writer path: it sets both layers under the declared TTL, framed
with the write's mint-time version. `put/3` mints the version now, of the table's kind — the write is its own event;
`put/4` carries the writer's own 14-byte version. The key is the cache's own form `ecc:{<table>}:<id>`
(`EchoStore.Keyspace.key/2`), with the table name hash-tagged so every key of one cache lands in one cluster slot.
The functional-Elixir and OTP craft behind the echo data layer is taught in the [`/elixir`](/elixir) course; this
module shows the Valkey side of the write.

## Advantages

- **Strong consistency** — the cache always reflects the latest data. There is no window where the cache holds stale
  information, because the cache write is on the same path as the database write.
- **Fast reads after writes** — data written is immediately available in the cache for the next read, which benefits
  write-then-read patterns. The L1 ETS hit it serves is `40 times cheaper` than the L2 round trip (`bcs.4`).
- **Simpler cache invalidation** — because writes go through the cache, there is no need to explicitly invalidate
  keys after a database update.

## Disadvantages

- **Increased write latency** — the write is not complete until both the cache and the database acknowledge, so the
  total latency is at least the sum of both write latencies. The latency dive measures this against write-behind.
- **Cache pollution** — data that is written but rarely read still occupies cache memory, and can evict more
  valuable, frequently-read data.
- **Failure complexity** — if the database write fails after the cache write succeeds, the two stores disagree. The
  application has to handle partial failures carefully.

## Handling Partial Failures

The safest approach is to write to the database first:

1. Write to the database.
2. If that succeeds, write to the cache.
3. If the cache write fails, log the error but do not fail the operation.

This way the database — the source of truth — is always correct, and a later cache miss reads fresh data from the
database. A partial failure can never leave the cache ahead of the source; the worst case is a cache miss, not a
wrong answer.

## When to Use Write-Through

- Strong consistency between cache and database is required.
- Write-then-immediately-read patterns are common.
- The write-latency overhead is acceptable.
- The dataset is relatively small, so cache pollution is less of a concern.

## When to Avoid

- Write latency is critical.
- Most data is written but rarely read.
- The system needs to tolerate cache failures without affecting write operations.

A write-heavy, stale-tolerant workload reaches for write-behind instead — the next module.

## Redis Pattern Applied — on EchoStore's write path

Write the cache and the source in one synchronous step, so a read after a write is always fresh — at the cost of a
second write on every change. On EchoStore, `EchoStore.Table.put` runs `SET … PX` to the L2 Valkey row then
`insert` into the L1 ETS table, both inside one synchronous `GenServer.call`; reads are always fresh. The write's
mint-time branded version frames the value (`version <> value`) so coherence can later compare newer-wins. The
near-cache — EchoStore's two-layer write kept coherent by the framed mint-time version — is taught in depth at
[`/echomq/cache`](/echomq/cache); the EchoStore manuscript is [`/bcs`](/bcs), Part IV.

Three dives take the pattern apart:

- **The synchronous dual write** — one write reaches both stores: `SET … PX` to the L2 Valkey row and an `insert`
  into the L1 ETS table, together, before the write returns.
- **The consistency guarantee** — why the next read cannot be stale: both layers were set under one TTL, framed with
  the write's mint-time version, so a read-after-write serves the value that write produced.
- **The latency cost** — the synchronous `GenServer.call` waits for the L2 `SET` round-trip; the trade against
  write-behind's deferred database write.

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set) — `SET key value PX <ms>` sets the value and the millisecond TTL atomically; the L2 write-path command.
- [Valkey — Topics](https://valkey.io/topics/) — the engine EchoStore's L2 layer is written against; the live line is Valkey.
- [Redis — SET](https://redis.io/commands/set) — the string write-path command and its `EX`/`PX` expiry options.
- [Redis — Documentation](https://redis.io/docs/) — the data structures and commands the cache write is built from.

### Related in this course
- [R1.02.1 · The synchronous dual write](/redis-patterns/caching/write-through/dual-write) — the write that touches both layers.
- [R1.02.2 · The consistency guarantee](/redis-patterns/caching/write-through/consistency) — read-after-write freshness.
- [R1.02.3 · The latency cost](/redis-patterns/caching/write-through/latency-cost) — the price of the guarantee.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [R0 · Overview](/redis-patterns/overview) — Valkey under codemojex.
- [/echomq/cache](/echomq/cache) — the EchoStore dual-layer write kept coherent, in depth.
- [/bcs](/bcs) — the EchoStore manuscript, Part IV.
