# Uber: resilience & staggered sharding

> R8.05 · Production & Operations — module hub · route `/redis-patterns/production-operations/uber-resilience`

Uber built an **integrated Redis cache in front of Docstore** — a transparent caching layer that improved
latency, reduced database load, and cut cost, growing to serve **40 million reads per second** at a **99% cache
hit rate**. The headline is not the throughput; it is what Uber did so a sick cache never took the database down
with it. Three resilience techniques are worth taking apart: **staggered sharding** (the Redis sharding scheme
deliberately different from the database's, so one cluster's failure spreads across many database shards),
the **sliding-window circuit breaker** (count errors per node per time bucket and short-circuit once a threshold
is hit), and **graceful degradation** (a miss or short-circuit falls through to Docstore — degraded but
available).

This module reads Uber's integrated cache as the case study, then ties each idea back to the real BCS bus.
Uber's own stack legitimately names Redis and Docstore — that is their history, quoted as theirs. The BCS bus is
Valkey-only; the worked consumer is codemojex. The parallel that runs through the module is *same goals — fail
fast, recover, never amplify a sick dependency — different mechanisms*: Uber added a circuit breaker over Redis;
the EchoMQ connector reaches the same goals with backpressure, fail-fast errors, and supervised reconnect with
capped jittered backoff.

Grounding: the Uber source pack — *How Uber Uses Integrated Redis Cache to Serve 40M Reads/Second* (ByteByteGo) —
for the case study; the as-built `echo/apps/echo_wire/lib/echo_mq/connector.ex` (the connector's `@backoff_min` /
`@backoff_max`, the `:disconnected` fail-not-replay, the `max_pending` → `:overloaded` bound) for the applied
half. Every external claim cites a real source; no Uber number, Redis command, or echo surface is invented.

## §1 · The system: an integrated cache over Docstore

Docstore is Uber's distributed database. A read against it is durable and correct but pays the full database
cost; at Uber's scale, repeating identical reads against Docstore is expensive in both latency and load. Uber's
answer was an **integrated Redis cache** — a layer in front of Docstore that the application reads through
transparently. On a hit the value comes back from Redis in memory; on a miss the read falls through to Docstore
and the result populates the cache.

The wins were the cache-aside wins at scale: lower latency, less database load, lower cost. A documented use case
ran at **over 6 million reads per second with a 99% cache hit rate**. The title figure is the aggregate:
**40 million reads per second** served from the integrated cache.

But a cache in front of a database changes the failure model. When the cache is healthy it absorbs the load; when
the cache is sick, the traffic it was absorbing lands somewhere — and where it lands decides whether a cache
problem stays a cache problem or becomes a database outage. The rest of the module is the three things Uber did so
the second never happened.

## §2 · The three resilience techniques

**Staggered sharding — misalign the two sharding schemes.** Uber sharded the Redis cluster using a scheme
**different from the database sharding scheme**. The reason is the failure model: if Redis and Docstore were
sharded the same way, a single Redis cluster going down would dump all of its missed traffic onto the *one*
Docstore shard that backed it — a **hot shard**, a correlated failure that can take the database shard down too.
By deliberately misaligning the schemes, a single Redis cluster's load spreads **across multiple database shards**
instead of concentrating on one. Misalignment turns a correlated failure into a spread one.

**The sliding-window circuit breaker.** When a Redis node is down, every get and set routed to it pays a latency
penalty before it fails — and at millions of requests per second, that penalty compounds. Uber added a
**sliding-window circuit breaker** per node: count errors per node in each time bucket, sum the counts over the
window's width, and once the error count crosses a threshold, **short-circuit a fraction of the requests** to that
node — skip the doomed call and go straight to the fallback. If errors keep accumulating, the breaker **trips**:
no requests go to the node at all until the window passes and the counts age out. The circuit breaker is the
canonical resilience pattern — fail fast against a known-bad dependency rather than wait for each call to time
out.

**Graceful degradation.** A Redis miss or a short-circuited request **falls through to Docstore**. The read is
slower than a cache hit, but it is *served* — degraded, not failed. The combined effect was measured: **P75
latency down about 75%, P99.9 latency down over 67%**, and latency spikes limited. The same use case at over 6M
reads/second **failed over successfully to a remote region** when its primary region had trouble — the cache
going away in one region degraded to the remote path rather than taking the read down.

## §3 · The applied half — the BCS bus

Uber's integrated cache is the lens; the system the reader is building is EchoMQ, backed by Valkey. The honest
framing is *same goals, different mechanisms*. Uber's three techniques aim at three goals: do not concentrate a
failure (staggered sharding), do not keep calling a sick dependency (the circuit breaker), and stay available when
a dependency is gone (graceful degradation). The EchoMQ connector reaches the same three goals by different means.

The bridge:

- **The pattern** — staggered sharding spreads a cache cluster's failure across many database shards; the
  sliding-window circuit breaker stops hammering a node that is failing; graceful degradation falls through to the
  durable store so a read is served even when the cache is gone.
- **Its EchoMQ application** — placement is the `{q}` hashtag: a queue's keys hash to one of 16384 slots, decided
  by the queue name (cross-linked from R8.03, not re-derived here). Not-hammering-a-sick-dependency is the
  connector's **bounded in-flight depth** — `max_pending` (default `10_000`) answers `:overloaded` rather than
  buffering without bound (`echo/apps/echo_wire/lib/echo_mq/connector.ex`). Staying available is **fail-not-replay
  plus supervised reconnect**: on socket loss in-flight callers are failed `:disconnected` and never replayed, and
  the connector reconnects with capped jittered backoff (`@backoff_min 100`, `@backoff_max 2_000`).

One guard holds the parallel straight. The connector's `max_pending` → `:overloaded` bound is **backpressure / a
bounded in-flight queue, not a circuit breaker**. A circuit breaker tracks a dependency's *error rate* over a
window and stops calling it; the `max_pending` bound caps how many requests can be *in flight* at once and refuses
the overflow. They share a goal — do not pile work onto a struggling path — but the mechanisms differ:
backpressure is a depth limit, a circuit breaker is an error-rate trip. The circuit-breaker concept in this module
is Uber's; echo_mq's analogues are **backpressure, fail-fast, and reconnect-backoff**.

The worked consumer is **codemojex**. Every guess goes through `EchoMQ.Connector`, so a guess inherits these
properties for free: if the wire is saturated the caller gets a fast `:overloaded` rather than an unbounded
queue, and if Valkey drops the socket the in-flight guess fails `:disconnected` (a fast, honest error the caller
can retry) while the connector reconnects with backoff. The game stays responsive under trouble instead of hanging
on a sick wire.

### Notes on Valkey

A Valkey primary failover surfaces to a client as a `-READONLY` error: a replica that has not yet been promoted
refuses writes with `-READONLY You can't write against a read only replica`. The owned wire has **no special
`-READONLY` handler** — its recovery to a topology change is the general one: the socket drops and the supervised
connector reconnects (re-fencing on every reconnect). Treat `-READONLY` as the Valkey failover *signal*, not an
echo surface — [valkey.io/topics/latency](https://valkey.io/topics/latency/).

## The three dives

The module follows the resilience arc — place the failure, then break the circuit, then degrade gracefully:

- **R8.05.1 · Staggered sharding**
  (`/redis-patterns/production-operations/uber-resilience/staggered-sharding`) — the Redis sharding scheme
  deliberately different from the database's, so one Redis cluster's failure spreads across many database shards
  instead of creating a hot shard; the BCS echo: the `{q}` hashtag pins a queue's keys to one of 16384 slots
  (cross-linked from R8.03).
- **R8.05.2 · Circuit breakers**
  (`/redis-patterns/production-operations/uber-resilience/circuit-breakers`) — the sliding-window circuit breaker:
  per-node error counts in time buckets, short-circuit a fraction, trip until the window passes; the BCS echo:
  `max_pending` → `:overloaded` backpressure (the in-process cousin — same goal, a different mechanism).
- **R8.05.3 · Graceful degradation**
  (`/redis-patterns/production-operations/uber-resilience/graceful-degradation`) — fall through to Docstore on a
  miss or short-circuit; the P75 −75% / P99.9 −67% / remote-region failover results; the BCS echo: the
  connector's capped-jittered-backoff reconnect and fail-not-replay, and `-READONLY` as the Valkey failover
  pattern.

Read them in order: place the failure first, then stop hammering the sick node, then keep serving when it is
gone.

## References

### Sources

- [Uber Engineering — How Uber Serves Over 40 Million Reads Per Second Using an Integrated Cache](https://www.uber.com/blog/how-uber-serves-over-40-million-reads-per-second-using-an-integrated-cache/)
- [ByteByteGo — How Uber Uses Integrated Redis Cache to Serve 40M Reads/Second](https://blog.bytebytego.com/p/how-uber-uses-integrated-redis-cache)
  — the integrated cache over Docstore, staggered sharding, the sliding-window circuit breaker, graceful
  degradation, and the 40M reads/s / 99% hit / remote-region-failover figures.
- [Microsoft Learn — Circuit Breaker pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker)
  — the canonical resilience pattern: fail fast against a known-bad dependency rather than wait for each call to
  time out.
- [Valkey — Cluster specification](https://valkey.io/topics/cluster-spec/) — the `{…}` hashtag and CRC16 mod
  16384 hash slots behind the staggered-sharding tie.
- [Valkey — Diagnosing latency issues](https://valkey.io/topics/latency/) — failover and reconnect behaviour;
  the `-READONLY` signal the connector recovers from by reconnecting.

### Related in this course

- [R8.05.1 · Staggered sharding](/redis-patterns/production-operations/uber-resilience/staggered-sharding) — spread the failure, no hot shard.
- [R8.05.2 · Circuit breakers](/redis-patterns/production-operations/uber-resilience/circuit-breakers) — stop hammering a sick node.
- [R8.05.3 · Graceful degradation](/redis-patterns/production-operations/uber-resilience/graceful-degradation) — fall through, stay available.
- [R8.02 · Persistence, pooling & failover](/redis-patterns/production-operations/persistence-pooling-failover) — the failover and reconnect material this module frames through Uber's lens.
- [R8.03 · Pinterest: task queues & partitioning](/redis-patterns/production-operations/pinterest-task-queue) — the `{q}` hashtag and CRC16 slot the staggered-sharding tie reuses.
- [R8 · Production & Operations](/redis-patterns/production-operations) — the chapter.
- [/echomq/queue](/echomq/queue) — the Queue pillar: the connector, the lease, the lanes.
