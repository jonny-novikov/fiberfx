# Request coalescing

> Route: `/redis-patterns/caching/cache-stampede-prevention/coalescing` · Module R1.05 · dive 3 · Source:
> `content/fundamental/cache-stampede-prevention.md.txt` (the *Handling Waiting Clients* / single-regeneration idea
> behind both solutions, extended across processes by *Solution 2: Mutex Locking*) · Grounding: EchoStore's
> single-flight `flights` map, the `:coalesced` counter, and the "one fill per herd" moduledoc
> (`echo/apps/echo_store/lib/echo_store/table.ex`).

The first miss starts the rebuild. Every later miss on the same owner attaches to it and waits for the one result —
one source read serves the whole burst. Request coalescing is the mechanism underneath the lock and X-Fetch.

## One in-flight regeneration

Coalescing turns a key into a one-rebuild-at-a-time resource. The first request to miss the key starts the
regeneration and records it in a small in-process table: *key → the in-flight rebuild*. The next request that misses
the same key, milliseconds later, looks in that table, finds the entry, and attaches to the running rebuild rather
than starting a second one. Every attached request waits on the same result; when the rebuild completes, the value is
delivered to all of them and the table entry is cleared.

The effect is that concurrency on one key collapses to one. A thousand near-simultaneous misses produce one source
read and one cache fill; the other nine hundred and ninety-nine requests pay only the wait for that single rebuild. It
needs no extra key on the engine: the merge is in-process state — a map of in-flight rebuilds keyed by the cache key.

The boundary is the process. The in-flight table lives in one application instance, so coalescing dedupes the misses
*within* that instance. Across a fleet of instances, each one independently coalesces its own burst — so a hundred
instances make up to a hundred source reads, not one.

## Coalescing across processes

In-process coalescing is one source read per instance. To make it one source read for the whole fleet, the merge has
to live somewhere shared — and that is the regeneration lock from the first dive. The first instance to win `SET lock
val NX PX` for the key does the rebuild; the others, having lost the lock, do what the losers do — poll for the fill
or serve stale. Valkey is the shared in-flight registry: the lock key is the cross-process equivalent of the
in-process table entry.

```
# Two layers: coalesce in-process, then the lock across processes.
# 1. in-process: the first miss starts the rebuild; later misses attach.
# 2. cross-process: the rebuild contends for the shared lock —
SET lock:set:EMS0ODMggk1d5N "token" NX PX 5000
# one instance wins and reads the source; the rest serve stale or poll.
```

So the two layers compose. Coalescing inside each instance collapses that instance's concurrent misses to one attempt
on the lock; the lock across instances collapses those attempts to one rebuild for the fleet. Together they take a
fleet-wide flood — every instance, every concurrent request — down to a single source read. No protection makes one
source read per miss; in-process coalescing makes one per instance; the lock makes exactly one for the whole fleet.

## On EchoStore — the flights map

This is EchoStore's read path, exactly. A read first tries L1 caller-side; on a miss it calls the owner with
`{:fill, id}`. The owner keeps a `flights` map keyed by id. The first miss launches a flight; a concurrent miss on
the same id finds the entry, appends its caller to the waiter list, and bumps the `:coalesced` counter — it does not
start a second load:

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

When the flight finishes, the owner replies to every waiter with the one answer and clears the entry. The moduledoc
names the law: *"Concurrent misses on a key coalesce onto a single in-flight load; the first caller's flight checks
L2, falls through to the declared loader, writes both layers, and every waiter reads the one answer."* The flight runs
`GET ecc:{table}:id`; on `{:ok, nil}` it calls the loader and writes both layers with `SET ... PX`. The committed
drill shows the merge under a real herd: 200 concurrent cold readers, the loader runs once, 199 waiters coalesced —
one fill for the whole herd. The functional-Elixir & OTP craft behind the echo data layer — the GenServer call path,
the waiter list, `spawn_monitor` — is the [`/elixir` course](/elixir/pragmatic/state).

## References

### Sources
- [Valkey — SET](https://valkey.io/commands/set) — `NX`/`PX` for the cross-process lock that extends the merge across instances, and `PX` for the L2 fill.
- [Redis — SET](https://redis.io/commands/set) — the canonical command reference for the lock the merge rides across a fleet.
- [Redis — Documentation](https://redis.io/docs/) — the expiry and locking primitives that extend an in-process merge across a fleet.
- [Sanfilippo, S. — antirez weblog](https://antirez.com/) — the Redis creator on single-instance locks and coordinating one writer.
- [Answer.AI — llms.txt](https://llmstxt.org/) — the machine-readable convention this course's agent maps follow.

### Related in this course
- [R1.05 · Cache stampede prevention](/redis-patterns/caching/cache-stampede-prevention) — the module hub.
- [R1.05.1 · Lock-on-miss](/redis-patterns/caching/cache-stampede-prevention/lock-on-miss) — the lock that carries the merge across processes.
- [R1.05.2 · Probabilistic early refresh](/redis-patterns/caching/cache-stampede-prevention/early-refresh) — the lockless alternative.
- [R1 · Caching](/redis-patterns/caching) — the chapter.
- [R0 · Overview](/redis-patterns/overview) — Valkey under codemojex.
- [/echomq/cache](/echomq/cache) — EchoStore single-flight coalesces the fills, in depth.
