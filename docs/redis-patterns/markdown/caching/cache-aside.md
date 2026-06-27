# Cache-aside (lazy loading)

> Route: `/redis-patterns/caching/cache-aside` · Module R1.01 · Source: `content/fundamental/cache-aside.md.txt`
> · Grounding: EchoStore's declared near-cache — `EchoStore.Table` (`echo/apps/echo_store`), L1 ETS over L2 Valkey.

Use cache-aside for read-heavy workloads: on a cache miss, fetch from the database and populate the cache; on a
write, invalidate or update the cache explicitly. The application treats the cache as an auxiliary data store,
managing it explicitly rather than letting the cache sit transparently between the application and the database.

## How It Works

When the application needs data, it follows one sequence:

1. **Check the cache first** — query Valkey for the key with `GET`.
2. **On a cache hit** — return the cached value immediately.
3. **On a cache miss** — query the primary database, write the result to Valkey with a TTL, then return it.

The key insight is that the application populates the cache. Valkey never fetches from the database on its own. Two
moves define the pattern: a **read** is `GET`, and on a miss read the source then `SET … PX` the value with an
expiry; a **write** to the source is followed by `DEL` of the cached key, so the next read re-fills it. The cache is
a disposable copy of a source of record; nothing keeps the two in lockstep, and the pattern bounds the lag with a
TTL.

## Redis Commands Used

A typical cache-aside flow uses three commands:

```
GET ecc:{quotes}:AST0NuE6bV7FoH                  # => nil  (a miss)
SET ecc:{quotes}:AST0NuE6bV7FoH "{…value…}" PX 300   # fill the cache with a 300 ms TTL
DEL ecc:{quotes}:AST0NuE6bV7FoH                  # invalidate on a write
```

Set the value and the TTL in one command. A separate `EXPIRE` after `SET` leaves an immortal key if the process dies
between the two. The `PX 300` caps the lifetime of any value the invalidation path misses.

**On EchoStore.** `EchoStore.Table` is the declared near-cache: an L1 of ETS in front of the L2 Valkey the systems
already share. The key is the cache's own keyspace — `ecc:{<table>}:<id>` (`EchoStore.Keyspace.key/2`), the table
name hash-tagged so every key of one cache lands in one cluster slot. `Table.fetch/3` is the whole read surface:
it returns `{:ok, value, source}` with source `:hit | :l2 | :fill` — an L1 hit in the caller's own process, an L2
Valkey hit, or a loader fill — and the moduledoc states the pattern outright: *cache-aside at ETS speed*. The
functional-Elixir and OTP craft behind the echo data layer is taught by the [`/elixir` course](/elixir/pragmatic/state);
this module is the cache placed in front of the source.

## Advantages

- **Resilience to cache failure** — if Valkey is unavailable, the application falls back to the database. Latency
  rises; the system keeps working.
- **Memory efficiency** — only data that is actually requested enters the cache; the working set is demand-shaped, so
  unused data does not occupy cache memory.
- **Simplicity** — the pattern is straightforward to implement and reason about.

## The Staleness Problem

The primary disadvantage is stale data. A reader takes a cache hit; another process updates the row in the database;
the cached copy stays unchanged until the TTL expires. The cache now holds outdated information, for up to the
remaining TTL.

## Mitigating Staleness

The standard mitigation is **cache invalidation on write**: when the application updates the source, it immediately
deletes the cached key with `DEL`. The next read misses and fetches fresh data. Deleting is simpler and safer than
updating the cache in place, which risks a race — two set-on-write writers can interleave and leave the older value
in place indefinitely, whereas delete-on-write is wrong for at most one TTL. The TTL is therefore a correctness
bound, not a memory knob. In EchoStore the unconditional admin verb is `Table.invalidate/3` — a `DEL` on L2 plus an
`:ets.delete` on L1, dropping one name from both layers.

## When to Use Cache-Aside

- The workload is read-heavy.
- Brief staleness is acceptable.
- Graceful degradation if the cache fails is wanted.
- Fine-grained control over what gets cached is needed.

## When to Avoid

- Strong consistency between cache and database is required.
- Write-then-immediately-read patterns are common (the read may hit a stale cache).
- The cost of a cache miss is extremely high.

## The bridge — cache-aside → EchoStore

The pattern: the application owns the cache — read Valkey first, fill on a miss with an expiry, invalidate on a
write. The cache is a disposable copy of a source of record, and its lag is bounded, not zero.

Its EchoStore application: `Table.fetch` returns `:hit | :l2 | :fill` — an L1 ETS hit, an L2 Valkey hit, or a loader
fill — and `invalidate` drops both layers. The measured floor is the chapter's title made a number: a `762 ns` L1
hit against a `31 us` L2 `GET` on the same wire — the L1 hit is **40 times cheaper** than the round trip it
replaces (`bcs.4`).

**The application door.** `SET key value PX <ms>` sets value and TTL atomically (valkey.io/commands/set); the
`ecc:{<table>}:<id>` hash-tag key lands one cache in one cluster slot. **A note on Valkey:** `SET … PX` writes the
value and its expiry in one command — a separate `EXPIRE` leaves an immortal key if the process dies between the
two (valkey.io/commands/set).

## References

### Sources
- [Redis — Documentation](https://redis.io/docs/) — the strings, expiry, and key commands cache-aside is built from.
- [Redis — GET](https://redis.io/commands/get) — the read that starts every lookup; returns the value or nil on a miss.
- [Valkey — SET](https://valkey.io/commands/set/) — set a value with the `PX` time-to-live in one command; the fill move that backs every key with an expiry.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on expiry, eviction, and keeping the cache a disposable copy.

### Related in this course
- [R1.01.1 · GET / SETEX miss-fill](/redis-patterns/caching/cache-aside/miss-fill) — the read path.
- [R1.01.2 · Explicit invalidation](/redis-patterns/caching/cache-aside/invalidation) — DEL on write.
- [R1.01.3 · TTL & staleness](/redis-patterns/caching/cache-aside/ttl-staleness) — the safety net.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/echomq/cache](/echomq/cache) — the EchoStore two-layer cache-aside near-cache, in depth.
- [/elixir · State](/elixir/pragmatic/state) — the functional-Elixir craft behind the echo data layer.
