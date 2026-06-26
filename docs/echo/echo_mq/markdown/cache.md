# The Cache — `/echomq/cache` (pillar III)

> Route-mirror source-of-record for the Cache pillar landing. The pillar grounds in **real shipped code**
> (`echo/apps/echo_store`), so there is **no `[RECONCILE]` marker** here — every claim is in the file.
> Reverse-door: `← redis-patterns R1 · Caching` (and R5 · Streams & Events). Figure home: `docs/echo/bcs/bcs.4.md` (B4).

## Thesis

The Cache is pillar III, and it stands in front of the other two. Where the Queue distributes work and the Bus
broadcasts signals, the Cache **serves reads**. It is a **declared near-cache** — an L1 ETS table in front of the L2
Valkey the bus already runs on — read **cache-aside**: a hit is a caller-side `:ets.lookup` that never enters the
owning process, and the owner is consulted only on a miss, where the second law holds — **one fill per herd**.
Concurrent misses coalesce onto a single loader; expiry is **jittered** so no cohort dies together; and a full cache
**degrades to pass-through, it never fails**. Every value is framed with its writer's **mint-time version** — the seed
of the coherence that keeps the caches honest.

## The read, cache-aside (framing interactive)

A cache-aside read tries the layers in order and stops at the first that answers. The fast path never leaves the
caller (`:ets.lookup` in the caller's process). Only a miss consults the owner, and a miss in front of a thundering
herd becomes **one** fill. The interactive resolves a read to `:hit` (L1), `:l2` (the shared Valkey via `GET
ecc:{table}:id`), or `:fill` (the declared loader, then `SET … PX`), shows the herd coalescing onto one flight, and
shows the jittered clock + the sweeper. `fetch/3 → {:ok, value, :hit | :l2 | :fill}`.

## The modules

1. **Cache-aside, two layers** (`cache-aside-two-layers`, built) — the declared near-cache: the directory + the two
   tiers (L1 ETS / L2 Valkey, `ecc:{table}:id`, the `{table}` hashtag → one of 16384 cluster slots), the cache-aside
   `fetch/3` (`:hit | :l2 | :fill` + the kind gate at the door), and the version-framed write (`put/3-4`, `version <>
   value`) + the unguarded admin `invalidate/3`.
2. **Single-flight & jittered TTL** (`single-flight-and-jittered-ttl`, built) — one loader for a thundering herd
   (`launch_flight` + the coalesced waiters), cohorts that never expire in step (`expires_at` = `ttl ± ttl·jitter` +
   the `:sweep` reclaim), and a full cache that degrades to pass-through (`insert` → `reclaim` → `:full_skips`), with
   the `stats/1` counters as the cache's honest self-report.
3. **Coherence — newer wins on the Bus** (`soon`) — a message about a name: the two identities, the eleven-byte mint
   comparison (`Coherence.newer?/2`), the broadcast lane (the Disruptor-shaped `EchoStore.Ring`, at-most-once) and the
   job lane (`EchoMQ.Lanes`, at-least-once, the `EchoStore.Journal` outbox), the `:coherence_drop` Lua on the wire, and
   server-assisted `:tracking` (RESP3 `CLIENT TRACKING`).
4. **Workshop** (`soon`) — hit at ETS speed, survive a herd with one fill, watch a jittered cohort expire, invalidate
   from another node.

## Redis Patterns Applied (reverse-door)

→ [`/redis-patterns/caching`](/redis-patterns/caching) (R1 — cache-aside / stampede-prevention / session, applied) and
→ [`/redis-patterns/streams-events`](/redis-patterns/streams-events) (R5 — bus-coherent invalidation). Both built →
hard-linked. The door map is `docs/redis-patterns/redis-patterns.echomq-doors.md` (it wins on R↔E edges).

## Doors

- → `/bcs/store` (B4 EchoStore — the manuscript figure home, `docs/echo/bcs/bcs.4.md`).
- → `/echo-persistence` (the durable floor beneath the volatile tiers — the coherence job lane's crash-survival).

## References

**Sources** — Erlang/OTP `ets` module; Valkey Cluster specification; Söderqvist, *A new hash table* (Valkey); Helland,
*Life Beyond Distributed Transactions*; King, *Announcing Snowflake*. **Related** — `/echomq/bus`, `/echomq/queue`,
`/echomq/protocol`, `/bcs/store`, `/echo-persistence`.
