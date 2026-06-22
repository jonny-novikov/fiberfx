# TTL & staleness

> Route: `/redis-patterns/caching/cache-aside/ttl-staleness` · Module R1.01 · dive 3 · Source:
> `content/fundamental/cache-aside.md.txt` (*The Staleness Problem*) · Grounding: `EchoCache.Table.expires_at/1`
> (`table.ex:484`, jittered `ttl ± ttl·jitter`), the `:sweep` sweeper (`table.ex:350`), and `SET … PX`
> (`table.ex:290`).

The TTL is a safety net. It caps how long a stale value can live when an invalidation is missed, and it bounds the
window between a write and its expiry. This is the staleness half of cache-aside — the source's *Staleness Problem*,
focused on the TTL as the upper bound.

## A TTL no key can outlive

The previous dive cleared the cache with an explicit `DEL` on every write, and that invalidation can fail: a writer
crashes between the source commit and the `DEL`, a delete is dropped, an event is missed. The TTL is the backstop.
Because every L2 row was written with `SET … PX ttl`, it carries an expiry from birth. If the `DEL` runs, the key is
gone immediately; if it never runs, the key still expires at its TTL and the next read re-fills with the current
source value. The TTL does not make the cache correct sooner — it caps how long it can be wrong. A short TTL bounds
staleness tightly but raises the miss rate; a long TTL serves more from cache but lets a missed invalidation linger.

## Bounding the worst case

The worst case is the longest a read can return stale data. With a working invalidation, that window is the time
from the source write to the `DEL` — usually small. With a missed invalidation, the window stretches to the key's
remaining TTL at the moment of the write. The bound is the smaller of those two: whichever removes the stale key
first.

```
PTTL ecc:{quotes}:AST0NuE6bV7FoH       # => remaining ms, or -2 if the key is already gone
```

## On EchoCache

EchoCache fills every L2 row with `SET … PX ttl_ms` (`table.ex:290`), so a missed invalidation still expires. Two
mechanisms keep the floor honest. First, expiry is **jittered**: `expires_at/1` (`table.ex:484`) draws each L1 row's
deadline from `ttl ± ttl·jitter`, so a cohort filled together never expires together and the TTL itself cannot
schedule the next herd. Second, a `:sweep` sweeper (`table.ex:350`) reclaims expired L1 rows on a fixed tick with a
`select_delete`, so dead rows leave whether or not anyone reads them again. The committed record shows the L2
expiry on the server's own clock — `PTTL 300 ms of 300`. The functional-Elixir craft behind the cache is taught by
the [`/elixir` state chapter](/elixir/pragmatic/state).

```elixir
# expires_at/1 (table.ex:484) — each row's deadline drawn from ttl ± ttl·jitter.
defp expires_at(spec) do
  base = System.monotonic_time(:millisecond) + spec.ttl_ms
  spread = trunc(spec.ttl_ms * spec.jitter)
  if spread == 0, do: base, else: base + :rand.uniform(2 * spread + 1) - spread - 1
end
```

The TTL bounds the worst case the cache will serve stale: at most the row's remaining time-to-live if the
invalidation is missed, and the delete latency if it lands.

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set/) — fill a key with a value and the `PX` time-to-live; the source of the TTL every L2 row carries.
- [Redis — DEL](https://redis.io/commands/del) — the explicit invalidation the TTL backstops when it is missed.
- [Valkey — EXPIRE](https://valkey.io/commands/expire/) — expiration semantics and the server's two reclamation paths, the L2-side counterpart of the sweeper.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on expiry, eviction policy, and bounding the cost of stale data.

### Related in this course
- [R1.01 · Cache-aside](/redis-patterns/caching/cache-aside) — the module hub.
- [R1.01.1 · GET / SET PX miss-fill](/redis-patterns/caching/cache-aside/miss-fill) — the read path that fills with the TTL.
- [R1.01.2 · Explicit invalidation](/redis-patterns/caching/cache-aside/invalidation) — the DEL the TTL backstops.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [/echomq](/echomq) — the EchoMQ protocol behind the connector.
- [/elixir · State](/elixir/pragmatic/state) — the functional-Elixir craft behind the cache.
