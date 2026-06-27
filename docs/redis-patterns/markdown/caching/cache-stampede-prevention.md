# Cache stampede prevention

> Route: `/redis-patterns/caching/cache-stampede-prevention` · Module R1.05 · Source:
> `content/fundamental/cache-stampede-prevention.md.txt` · Grounding: EchoStore's single-flight `flights` map
> + the jittered TTL (`echo/apps/echo_store/lib/echo_store/table.ex`).

Prevent multiple clients from simultaneously regenerating an expired cache key using locking, probabilistic early
refresh, or request coalescing. A cache stampede — the thundering herd — happens when a popular cache key expires and
many concurrent requests all query the source at once to regenerate the value, which can overwhelm the source and
cause cascading failures.

## The Problem

Consider a cache key accessed ten thousand times per second. While it is present every read is a hit and the source
is untouched. When it expires, the picture inverts:

1. Thousands of requests arrive within milliseconds.
2. All take a cache miss.
3. All query the source simultaneously.
4. The source becomes overloaded.
5. Response times spike across the entire system.

This is particularly dangerous for keys with expensive regeneration costs — complex queries, aggregations, external
API calls. The danger scales with two factors: how hot the key is, and how expensive its regeneration is. Plain
cache-aside has no defence here — every miss is independent, so *N* concurrent misses become *N* source reads. The
cost of a miss is what makes the herd dangerous: in the measured EchoStore record an L1 ETS hit costs `762 ns`, while
the L2 GET it replaces costs `31 us` — the L1 hit is `40 times cheaper`. A herd that goes to L2 and the loader pays
that round trip *N* times at once.

## Solution 1: Probabilistic Early Expiration (X-Fetch)

This technique decouples logical expiration from physical expiration. The idea is to give any request a small
probability of refreshing the cache *before* it actually expires.

Set the physical TTL longer than needed (for example one hour). As requests arrive, each one calculates whether it
should proactively refresh based on how close the key is to expiration and a random factor. When the key is fresh the
probability of refresh is near zero; as expiration approaches the probability increases, until one request triggers a
refresh while all others continue serving the slightly stale value.

The decision to refresh is based on:

```
current_time - (expiry_time - delta * beta * log(random()))
```

Where `delta` is the time needed to regenerate the value, `beta` is a tuning parameter (typically 1.0), and
`random()` produces a value between 0 and 1. The formula ensures that as the gap to expiration shrinks, the
probability of any single request triggering a refresh increases. Instead of thousands of simultaneous queries at
expiration, a single request refreshes the cache moments before expiration while others continue serving cached data.
The traffic spike is smoothed away.

## Solution 2: Mutex Locking

A deterministic approach where only one process is allowed to regenerate the cache. When a cache miss occurs:

1. Attempt to acquire a lock using `SET lock:mykey <token> NX PX 5000`.
2. If the lock is acquired, query the source and update the cache.
3. Other requests either wait and poll, or return a stale or default value.
4. Release the lock after the cache is populated.

```
SET lock:popular_key abc123 NX PX 5000
```

The `NX` ensures only one client acquires the lock. The `PX 5000` sets a five-second timeout to prevent deadlocks if
the lock holder crashes.

Clients that fail to acquire the lock have options: **poll** (sleep briefly and check the cache again), **return
stale data** (serve a stale copy if one is available), **return a default** (serve a degraded response), or **fail
fast** (return an error immediately).

The lock must be released safely. A plain `DEL` risks deleting another client's lock if yours already expired. Use a
Lua script that checks the token matches before deleting:

```
if redis.call("get", KEYS[1]) == ARGV[1] then
    return redis.call("del", KEYS[1])
end
return 0
```

## Comparison

| Approach | Complexity | Database Queries | Staleness |
|----------|------------|------------------|-----------|
| No protection | Low | N (one per request) | None |
| X-Fetch | Medium | 1–2 | Brief window |
| Mutex lock | Higher | Exactly 1 | None |

## Recommendation

For most applications, start with mutex locking — it is easier to reason about and provides strong protection.
Consider X-Fetch for extremely high-traffic keys where even brief lock contention is problematic. Some systems
combine both: X-Fetch for normal operation, with a mutex fallback for hard cache misses.

## On EchoStore

EchoStore prevents the stampede by construction with two real mechanisms — and it is worth being exact about which.

**One fill per herd — the single-flight `flights` map.** Misses route through the table's owner, and concurrent
misses on one id coalesce onto a single in-flight load. The owner's `handle_call({:fill, id}, from, state)` keeps a
`flights` map: the first caller launches a flight; a concurrent miss on the same id appends its caller to the waiter
list (`put_in(state.flights[id], {ref, [from | waiters]})`) and bumps the `:coalesced` counter. The module's own
words: *"Concurrent misses on a key coalesce onto a single in-flight load … every waiter reads the one answer."*
That is request coalescing and the cross-process lock idea fused into one server move — no `N` source reads, one
fill, every waiter served.

**No synchronized expiry — the jittered TTL.** EchoStore does not implement the probabilistic XFetch rule; the
X-Fetch formula above is the pattern, taught here, not a claim about the code. What the code does instead is
**expiry jitter**: `expires_at/1` draws each row's expiry from `ttl ± ttl·jitter`, so a cohort filled together never
expires together. The moduledoc states it plainly: *"Rows expire on a jittered clock — `ttl ± ttl·jitter` — so a
cohort filled together never expires together."* The TTL itself no longer schedules the next herd.

A single-flight on the L1 owner plus a jittered expiry is the same goal the lock and X-Fetch reach: one regeneration
per herd, and no synchronized expiry to create the herd in the first place.

The three dives take one solution each — lock-on-miss (mutex locking), probabilistic early refresh (X-Fetch), and
request coalescing — and run it on a hot key, grounding the applied part in EchoStore's single-flight and jitter.

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set) — the `NX` and `PX` options that make one client acquire a self-expiring regeneration lock, and `PX` for the jittered millisecond TTL EchoStore writes.
- [Redis — SET](https://redis.io/commands/set) — the canonical command reference for the regeneration lock.
- [Redis — Documentation](https://redis.io/docs/) — expiry, key TTL, and the string commands the regeneration lock and refresh are built from.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on locks, TTL, and atomic check-and-delete with a token.
- [Answer.AI — llms.txt](https://llmstxt.org/) — the machine-readable convention this course's agent maps follow.

### Related in this course
- [R1.05.1 · Lock-on-miss](/redis-patterns/caching/cache-stampede-prevention/lock-on-miss) — the regeneration lock (mutex locking).
- [R1.05.2 · Probabilistic early refresh](/redis-patterns/caching/cache-stampede-prevention/early-refresh) — X-Fetch the pattern; jitter the applied mechanism.
- [R1.05.3 · Request coalescing](/redis-patterns/caching/cache-stampede-prevention/coalescing) — one fill per herd, every waiter served.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [R0 · Overview](/redis-patterns/overview) — Valkey under codemojex.
- [/echomq/cache](/echomq/cache) — EchoStore single-flight in the near-cache, in depth.
