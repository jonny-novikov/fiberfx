# The consistency guarantee

> Route: `/redis-patterns/caching/write-through/consistency` · Module R1.02 · dive 2 · Source:
> `content/fundamental/write-through.md.txt` (the *Advantages* — reads always hit a fresh cache) · Grounding:
> the `version <> value` frame in `EchoCache.Table` (`echo/apps/echo_cache/lib/echo_cache/table.ex:294`) — both
> layers set under one TTL, framed with the write's mint-time version.

A read that follows a write-through write cannot be stale — because both layers were written on the same path, under
one TTL, framed with the write's mint-time version. The whole point of write-through is one property: read-after-write
freshness. This dive states the guarantee, and shows where cache-aside loses it.

## The guarantee, stated plainly

Write-through guarantees **read-after-write consistency** for the cache: any read that begins after a write has
returned serves the value that write produced, not an older one. The reason is structural, not probabilistic. The
write does not return until the cache has been written, so by the time a later read runs, the cache already holds the
new value. There is no interval in which the cache lags the source after the write completes.

In the as-built code the new value carries its own provenance: the put clause stores `version <> value` — a 14-byte
branded mint-time version in front of the bytes. The version is not for the read after this write (that read is fresh
because both layers were set in the one call); it is for the *next* writer's late message. A coherence message
compares versions and drops a row only when the incoming version is newer (`EchoCache.Coherence.newer?/2`), so a
late stale invalidation can never erase a newer row. Freshness on the write path; newer-wins across writers.

Contrast cache-aside, which invalidates the cache on a write rather than updating it. After a cache-aside write, the
cache is empty (or, if invalidation is deferred, briefly stale); the next read takes a miss, re-reads the source, and
backfills. That works, but it opens a window: between the write and the backfill, a concurrent reader is served an
empty or old cache. Write-through removes the window by paying for the cache write up front, on the write path.

- **read-after-write** — a read that starts after a write has returned. Write-through guarantees it returns the
  written value.
- **stale window** — an interval where the cache lags the source. Write-through has none after the write returns;
  cache-aside has one until the next backfill.
- **structural** — the guarantee follows from the order of operations, not from timing or luck: the cache write
  precedes the return.
- **the framed version** — `version <> value`, the write's mint-time branded prefix, so coherence across writers can
  compare newer-wins.

The guarantee is read-after-write freshness for the cached value, not a distributed transaction. Two layers are
written in sequence; if one fails, the write is reported as failed — the latency dive covers those failure modes.

## Classify a read after a write

Take a single key with an old value and a new value. A write-through write replaces both layers; a later read of that
key returns the new value, every time.

- **read after the write returns** — `GET ecc:{instruments}:<id>` returns the new value. Fresh, because both layers
  were set before the write returned.
- **read while the write runs** — the read returns the old or new value, never a torn one: a single-key `GET` returns
  one whole value, the before or the after, not a mix.
- **read after the TTL expires** — the L2 row has expired under its `PX`, so the read misses, the loader re-reads the
  still-current source, and the cache backfills. Fresh, because the source is the source of truth.

## On EchoCache

Take an instrument reference row that was updated. `EchoCache.Table.put` sets the L2 Valkey row and the L1 ETS table
on the same call; the write returns once both are done. A read of the same id is served from the cache and matches
what was written — there is no moment after the write where the cache could hand back the old value. A caller above
the table receives one consistent value, not a store and a timing race.

```
# echo/apps/echo_cache — a write-through put, then a fetch.
EchoCache.Table.put(:instruments, "AST0NgWEfAEJfs", new_value)
#   handle_call sets L2 (SET … PX) then L1 (insert) under one TTL  ->  {:reply, :ok}

EchoCache.Table.fetch(:instruments, "AST0NgWEfAEJfs")
#   {:ok, new_value, :hit}   — the L1 row holds the value the put produced
```

Across writers, the value's framed version is what keeps order: `EchoCache.Coherence.newer?/2` compares the 11-byte
snowflake payloads (lexicographic equals chronological), so a stale late message loses. The functional-Elixir and
OTP craft behind the echo data layer is in the [`/elixir`](/elixir) course. This dive states the guarantee and shows
a read confirming it.

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set) — the cache write that precedes the return, the reason the read is fresh; the `PX` expiry the one case a later read can miss.
- [Valkey — Topics](https://valkey.io/topics/) — single-key value semantics and the engine the L2 layer runs on (Valkey).
- [Redis — GET](https://redis.io/commands/get) — the single-key read that returns one whole value, never a torn one.
- [Redis — Documentation](https://redis.io/docs/) — the read and write commands and their consistency semantics on a single key.

### Related in this course
- [R1.02 · Write-through](/redis-patterns/caching/write-through) — the module hub.
- [R1.02.1 · The synchronous dual write](/redis-patterns/caching/write-through/dual-write) — the previous dive.
- [R1.02.3 · The latency cost](/redis-patterns/caching/write-through/latency-cost) — the next dive.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/echomq](/echomq) — the bus behind the coherence lane that carries the framed version.
