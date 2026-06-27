# Lock-on-miss

> Route: `/redis-patterns/caching/cache-stampede-prevention/lock-on-miss` · Module R1.05 · dive 1 · Source:
> `content/fundamental/cache-stampede-prevention.md.txt` (*Solution 2: Mutex Locking* — How It Works · Redis Commands ·
> Handling Waiting Clients · Releasing the Lock) · Grounding: EchoStore's single-flight `flights` map
> (`echo/apps/echo_store/lib/echo_store/table.ex`).

One request wins the lock and rebuilds the hot key. The rest wait, serve a stale copy, or fail fast — but never read
the source. Lock-on-miss is the deterministic defence: a per-key regeneration lock that admits exactly one writer.

## Acquire with NX and PX

The lock is one command. `SET lock:set:EMS0ODMggk1d5N <token> NX PX 5000` sets the lock key to a unique token only if it does
not already exist (`NX`), with a five-second expiry in milliseconds (`PX 5000`). The reply is the gate: `OK` means
this request holds the lock and may rebuild; `nil` means another request already holds it.

```
SET lock:set:EMS0ODMggk1d5N "a1b2c3-unique-token" NX PX 5000
# -> OK    : this request holds the lock; read the source and refill
# -> (nil) : another request holds it; this request waits or serves stale
```

The two options carry the whole guarantee. `NX` makes the acquire atomic — under a thousand concurrent attempts on
one key, the engine admits exactly one. `PX` bounds the lock's life so a winner that crashes mid-rebuild cannot hold
the key forever; the lock expires and the next miss elects a fresh winner. The token is a unique value per request,
used at release time to prove ownership.

This is a single-Valkey lease, not a distributed lock across independent nodes. The multi-node contrast — Redlock —
is the R2 Coordination chapter; here one Valkey is the source of truth.

## What the losers do

The point of the lock is what the requests that *lose* it do: not read the source. Each loser has four options:

- **Poll** — sleep briefly, then re-read the cache. The winner's fill lands within a rebuild, so a short poll loop
  returns the fresh value with no source read and no staleness, at the cost of a little added latency.
- **Serve stale** — if a previous value is kept (a longer physical TTL than the logical one), serve it immediately
  while the winner rebuilds. Zero added latency, at the cost of a brief, bounded staleness.
- **Return a default** — serve a degraded or placeholder response when no stale copy exists and latency matters more
  than completeness.
- **Fail fast** — return an error at once. The bluntest choice; it sheds load but surfaces the miss to the caller.

Whatever the losers do, the invariant holds: exactly one request reads the source per expiry. The flood of *N* misses
becomes one source read.

## Releasing the lock safely

Releasing looks trivial — delete the lock key after the refill — and a naive `DEL` is a bug. Suppose request A wins
the lock, but its rebuild runs long and the `PX 5000` expiry fires. The lock is now free; request B acquires it with
a fresh token. If A then finishes and calls a plain `DEL lock:set:EMS0ODMggk1d5N`, it deletes *B's* lock — and now two
requests run as the lock holder at once. The guard against this is the token.

The release reads the lock, checks the stored token equals this request's token, and deletes only on a match. That
read-compare-delete must be atomic, so it runs as one Lua script:

```
-- release only if this request still owns the lock (atomic)
if redis.call("get", KEYS[1]) == ARGV[1] then
    return redis.call("del", KEYS[1])
end
return 0
-- KEYS[1] = lock:set:EMS0ODMggk1d5N   ARGV[1] = this request's token
-- returns 1 (released) or 0 (the lock is no longer this one's — do nothing)
```

## Lock-on-miss on EchoStore

EchoStore reaches the same "one winner per miss" guarantee without a separate lock key — it elects the single fill
*at the owner*. A read first tries L1 caller-side; on a miss it calls the owner with `{:fill, id}`. The owner keeps a
`flights` map of in-flight loads keyed by id. The first miss launches a flight; a concurrent miss on the same id does
not launch a second — it appends its caller to the waiter list and bumps the `:coalesced` counter:

```elixir
def handle_call({:fill, id}, from, state) do
  # ... L1 re-check elided ...
  case Map.fetch(state.flights, id) do
    {:ok, {ref, waiters}} ->
      :counters.add(state.spec.counters, counter(:coalesced), 1)
      {:noreply, put_in(state.flights[id], {ref, [from | waiters]})}

    :error ->
      ref = launch_flight(state, id)
      {:noreply, put_in(state.flights[id], {ref, [from]})}
  end
end
```

The owner is the lock: serializing the fill through one process means the first caller's flight is the only one that
reaches L2 and the loader, and every waiter reads the one answer. The flight itself runs `GET ecc:{table}:id`; on
`{:ok, nil}` it calls the declared loader and writes both layers with `SET ... PX`. Where this dive's Redis lock
elects one rebuild across processes with `SET NX PX`, the EchoStore owner elects it in-process for free. The
functional-Elixir & OTP craft behind the echo data layer — GenServer call paths, `spawn_monitor`, the waiter list —
is the [`/elixir` course](/elixir/pragmatic/state).

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set) — the `NX` and `PX` options that make one client acquire a self-expiring regeneration lock.
- [Redis — SET](https://redis.io/commands/set) — the canonical command reference for the regeneration lock.
- [Redis — Documentation](https://redis.io/docs/) — expiry, atomic Lua scripting, and the patterns the token-checked release is built from.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on a single-instance lock, the token, and check-and-delete with Lua.

### Related in this course
- [R1.05 · Cache stampede prevention](/redis-patterns/caching/cache-stampede-prevention) — the module hub.
- [R1.05.2 · Probabilistic early refresh](/redis-patterns/caching/cache-stampede-prevention/early-refresh) — the next dive.
- [R1.05.3 · Request coalescing](/redis-patterns/caching/cache-stampede-prevention/coalescing) — one fill per herd, every waiter served.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [R0 · Overview](/redis-patterns/overview) — Valkey under codemojex.
- [/echomq/cache](/echomq/cache) — the EchoStore per-key single-flight, in depth.
