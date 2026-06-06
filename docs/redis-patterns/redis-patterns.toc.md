# Redis Patterns Applied

> **The Redis design patterns, taught applied — grounded in how a real polyglot job queue (EchoMQ) and the Portal
> platform use them.** You learn each pattern as a problem→solution→trade-off→when-to-use unit, then see it proven
> in real code: a real Redis key, command, atomic Lua script, or Go function from EchoMQ — the candidate for
> Portal's reserved multi-runtime layer. The course doubles as a guided build of that Redis tier, and opens the door
> to a dedicated EchoMQ course.

This course teaches the **judgement layer above the command reference**: not *what* `ZADD` does, but *which pattern
fits which workload, and why*. Its claim is that an engineer (or an agent) who knows the commands still reaches for
the wrong pattern — a single-node "distributed lock" that a failure silently breaks, a fixed-window rate limiter
with a boundary-burst flaw, keys fanned across cluster slots and then a cross-slot `MULTI`. The fix is grounding:
every pattern here is shown **applied in a real system**, so the worked example is verifiable, not plausible.

## The running system: EchoMQ-in-Portal

**EchoMQ** is a polyglot (Elixir/Go/Node.js) job queue built on the BullMQ protocol, the candidate for **Portal's
reserved F7–F9 multi-runtime layer**. Its governing fact — *"the BullMQ Lua scripts ARE the protocol"* — makes it
an almost one-to-one corpus of Redis patterns frozen into an immutable Redis data layer and Lua-script layer. So
roughly two-thirds of the catalog (the queue, coordination, streams, and scaling families) is grounded directly in
EchoMQ's real code; the remaining cache and modeling families are grounded in Portal's other Redis surfaces (the
cache machine, the dashboard read-models) or clean standalone examples. Where a chapter's deeper implementation
belongs to the polyglot protocol itself, it links forward to the **dedicated EchoMQ course** (built next).

## Who this is for

Engineers and agents writing or reviewing Redis code who want to pick the right pattern rather than guess. Comfort
with Redis commands helps; the gap this course closes is the decision and the trade-off, not the syntax. The
companion [`/elixir`](../elixir/specs/pragmatic/pragmatic.md) course builds Portal's engine; the
[`/course/agile-agent-workflow`](../agile-agent-workflow/agile-agent-workflow.toc.md) course is its sibling craft.

## What you will be able to do

- Choose the right Redis pattern for a workload, and name its failure mode before it bites.
- Read a real atomic Lua move and explain why the multi-key state change must be one script.
- Build a reliable queue, a delayed/priority queue, an event stream, a rate limiter, and a cluster-safe key layout —
  each grounded in EchoMQ's real implementation.
- Operate Redis as a system of record (persistence, memory, cluster) the way production systems do.

## Conventions

- **Subject.** Redis patterns, taught applied; commands as inline code, every technique with its trade-offs.
- **Grounding.** Real EchoMQ artifacts (`docs/echomq/`, `apps/echomq-go/`), real Redis commands, the Portal facade;
  never a fabricated module. The grounding map is fixed in [`redis-patterns.roadmap.md`](redis-patterns.roadmap.md).
- **Structure.** Three levels — chapter `R[N]` (a landing), module `R[N].[M]` (a hub), dive `R[N].[M].[S]` (≥3 per
  module). Each chapter closes with a **workshop** that advances the EchoMQ/Portal build.
- **Spec system.** The course is designed specs-first: this TOC is the map, [the roadmap](redis-patterns.roadmap.md)
  is the plan, and the per-chapter specs under [`specs/`](specs/redis-patterns.md) are the contracts pages are built
  from. See [`specs/redis-patterns.md`](specs/redis-patterns.md).
- **Quality.** Every page passes the ten jonnify-cms gates (`containers · svg · no-future · voice · storage ·
  motion · degrade · links · pager · refs`) and carries a branded Snowflake build stamp.

## Status — a living map

This TOC is kept in sync with the built course: when a module or chapter ships, its entry here is updated. It is the
human-readable companion to the per-chapter specs under [`specs/`](specs/redis-patterns.md), and must not contradict
them.

**Status legend:** `✓ built` (served under `/redis-patterns/…`) · `◐ in progress` · `○ planned`. Everything below
is **○ planned** — the spec system is authored; pages are a later stage.

A `→ EchoMQ` marker on a chapter means its deeper implementation opens the door to the dedicated EchoMQ course.

---

## R0 · Overview — the catalog, and Redis under Portal · `/redis-patterns` · ○ planned
> Orientation: the 30 patterns and how to read them, where Redis sits in Portal, and why getting a pattern exactly
> right is what makes a system correct. The course landing (`index.html`) plus the re-themed catalog
> (`overview/course.html`). Grounding: the EchoMQ thesis.

- **R0.1 · The course & the catalog** — the 30 patterns in three families, and how a pattern page reads. *(the
  re-themed `overview/course.html`.)* Dives: the pattern map · how to read a pattern · Redis-specific (not
  Valkey/KeyDB) provenance.
- **R0.2 · Redis under Portal** — the two roles Redis plays (the cache machine and the EchoMQ bus), the
  master-invariant seam, and the reserved F7–F9 multi-runtime tier this course fills in. Dives: the facade seam ·
  the two Redis roles · the reserved multi-runtime tier.
- **R0.3 · Patterns become protocol** — the four-layer model and the immutable L1/L2 core; why the data model is the
  contract that makes three runtimes interoperate. Dives: the four layers · the immutable core · the door to the
  EchoMQ course.

## R1 · Caching — the read path · `/redis-patterns/caching` · ○ planned
> The most common Redis use: serving reads fast and keeping the cache consistent on writes. Grounding: Portal's
> catalog cache machine (the cache family is not an EchoMQ one), with one bonus from EchoMQ's SHA1 script cache.

- **R1.01 · Cache-aside (lazy loading)** — `cache-aside` — on miss, fetch and populate; on write, invalidate.
  Grounding: Portal catalog reads. Dives: GET/SETEX miss-fill · explicit invalidation · TTL & staleness.
- **R1.02 · Write-through** — `write-through` — write to cache and database synchronously so reads are always fresh.
  Grounding: Portal write path. Dives: synchronous dual write · the consistency guarantee · the latency cost.
- **R1.03 · Write-behind (write-back)** — `write-behind` — write to Redis and sync to the database asynchronously.
  Grounding: Portal write buffer. Dives: the async buffer · the durability trade-off · coalescing writes.
- **R1.04 · Server-assisted client-side caching** — `client-side-caching` — cache in app memory; Redis pushes
  invalidations. Grounding: `CLIENT TRACKING`; bonus — EchoMQ's `ScriptLoader` SHA1 script cache. Dives: CLIENT
  TRACKING · invalidation push · the SHA1 script-cache parallel.
- **R1.05 · Cache stampede prevention** — `cache-stampede-prevention` — stop a thundering herd regenerating one
  expired key. Grounding: Portal hot-key refresh. Dives: lock-on-miss · probabilistic early refresh · request
  coalescing.
- **R1.06 · Session management** — `session-management` — store sessions with TTL expiry. Grounding: Portal F6.8.1
  session store. Dives: Hash vs String vs JSON · TTL expiry · the auth-session tie-in.
- **R1.07 · Workshop** — cache Portal's catalog tier end to end.

## R2 · Coordination & Consistency — atomicity first · `/redis-patterns/coordination` · → EchoMQ · ○ planned
> The atomicity foundation every later chapter builds on: a reliable queue is made of atomic moves and locks.
> Grounding: EchoMQ's Lua transactions, lock lease, and hash-tag colocation. Placed before the queue chapters per
> the dependency graph (atomic-multi-key-Lua → moveToActive).

- **R2.01 · Atomic updates** — `atomic-updates` — read-modify-write without a race. Grounding: every EchoMQ state
  move is one Lua script (`moveToActive-11`, `moveToFinished-14`). Dives: WATCH/MULTI/EXEC · Lua for complex logic ·
  shadow-key bulk.
- **R2.02 · Distributed locking** — `distributed-locking` — mutual exclusion with `SET NX PX` + a fencing token.
  Grounding: EchoMQ `:{id}:lock` + `ExtendLock` lease renewal. Dives: SET NX PX · fencing tokens · lease renewal
  (one timer per worker).
- **R2.03 · The Redlock algorithm** — `redlock` — a majority-of-N multi-master lock. Grounding: **contrast** with
  EchoMQ's single-Redis lease. Dives: N/2+1 majority · clock assumptions · when single-instance is enough.
- **R2.04 · Cross-shard consistency** — `cross-shard-consistency` — detect torn writes across instances. Grounding:
  EchoMQ's single-slot requirement for multi-key Lua. Dives: torn writes · version tokens · commit markers.
- **R2.05 · Hash-tag co-location** — `hash-tag-colocation` — force related keys to one cluster slot. Grounding:
  EchoMQ `bull:{queue}:*`, `cluster.go` CRC16 % 16384. Dives: the `{tag}` mechanic · CROSSSLOT prevention · cluster
  auto-detect.
- **R2.06 · Workshop** — make Portal enrollment atomic across runtimes. **Door:** EchoMQ's atomic-Lua transaction model.

## R3 · Reliable Queues — wait, active, done, recover · `/redis-patterns/queues` · → EchoMQ · ○ planned
> The heart of EchoMQ: "reliable-queue" is a family of techniques — the densest real grounding in the course.
> Grounding: EchoMQ's `:wait`/`:active` lists, the `RPOPLPUSH` handoff, and stalled recovery. Depends on R2.

- **R3.01 · The processing list** — `reliable-queue` — move a job out of wait *into* an in-flight list, so a crash
  is recoverable. Grounding: EchoMQ `MoveToActive` `rcall("RPOPLPUSH", waitKey, activeKey)`. Dives: LIST wait/active
  · LMOVE/RPOPLPUSH · the in-flight list.
- **R3.02 · At-least-once & idempotency** — `reliable-queue` — delivery guarantees and why consumers must be
  idempotent. Grounding: EchoMQ custom IDs + `de:{id}` dedup. Dives: at-least-once semantics · idempotent consumers
  · why exactly-once is a lie.
- **R3.03 · Stalled-job recovery** — `reliable-queue` — reclaim jobs whose worker died. Grounding: EchoMQ
  `moveStalledJobsToWait` (the atomic Lua vs the non-atomic Go version). Dives: lock-expiry detection · two-phase
  mark/recover · atomic vs non-atomic.
- **R3.04 · The atomic state machine** — `atomic-updates` — the whole lifecycle as one Lua transition. Grounding:
  EchoMQ `moveToFinished-14` (≈1100 lines, 14 keys). Dives: states as Redis locations · read-decide-write in one
  EVALSHA · EVALSHA + NOSCRIPT.
- **R3.05 · Blocking vs polling** — `reliable-queue` — stop busy-polling the queue. Grounding: EchoMQ `:marker` +
  `BZPOPMIN` (vs the Go ticker). Dives: the busy-poll cost · blocking pop · the marker wake-up.
- **R3.06 · Workshop** — a reliable Portal enrollment-job queue. **Door:** EchoMQ's worker fetch loop.

## R4 · Time, Delay & Priority — the sorted set as a clock · `/redis-patterns/time-delay-priority` · → EchoMQ · ○ planned
> Scheduling: the sorted set as a timer wheel and a priority ladder. Grounding: EchoMQ's `:delayed`/`:repeat` ZSETs
> and the composite priority score. Depends on R3.

- **R4.01 · The delayed queue** — `delayed-queue` — score a job by its fire-time, sweep by score. Grounding: EchoMQ
  `:delayed` ZSET + `promoteDelayedJobs`. Dives: score = fire-time · ZRANGEBYSCORE promotion · the next-wake computation.
- **R4.02 · Schedulers & repeatable jobs** — `delayed-queue` — recurring jobs via cron/interval. Grounding: EchoMQ
  `:repeat` ZSET, upsert. Dives: cron vs interval · upsert (no duplicates on boot) · start-to-start cadence.
- **R4.03 · Priority with composite scores** — `lexicographic-sorted-sets` — pack priority + arrival into one score.
  Grounding: EchoMQ `getPriorityScore` `priority * 0x100000000 + pc`. Dives: packing two keys in one score ·
  FIFO-within-tier · ZPOPMIN.
- **R4.04 · Backoff & retry** — `delayed-queue` — exponential backoff with jitter on the same delayed ZSET.
  Grounding: EchoMQ `retryJob` (`base * 2^(n-1)`). Dives: exponential backoff · jitter (thundering herd) · the
  delayed-ZSET reuse.
- **R4.05 · Leaderboards** — `leaderboards` — real-time rankings with the same ZSET machinery. Grounding: Portal
  progress rankings. Dives: ZADD/ZRANK · top-N & around-me · the score-update path.
- **R4.06 · Workshop** — schedule Portal's notification/digest jobs. **Door:** EchoMQ's scheduler subsystem.

## R5 · Streams & Events — the durable log · `/redis-patterns/streams-events` · → EchoMQ · ○ planned
> Observability and event-driven coordination, with Redis Streams as the durable, replayable log. Grounding:
> EchoMQ's `:events` stream. Depends on R3 (the lifecycle events).

- **R5.01 · Event sourcing on Streams** — `streams-event-sourcing` — the append-only log is the source of truth;
  state is its replay. Grounding: EchoMQ `:events` `XADD`. Dives: the append-only log · replay/rebuild ·
  `last_event_id` cursor.
- **R5.02 · Stream consumer patterns** — `streams-consumer-patterns` — block, batch, trim, resume. Grounding:
  EchoMQ QueueEvents (`XREAD BLOCK`; the naive→`XREADGROUP` consumer-group arc). Dives: XREAD BLOCK · consumer
  groups · `MAXLEN ~` trimming.
- **R5.03 · Pub/Sub vs Streams** — `pubsub` — fire-and-forget vs durable, and how to choose. Grounding: EchoMQ
  `echomq:cancel` channel + the explicit ch22 decision. Dives: fire-and-forget vs durable · the choosing rule · the
  dedicated blocking connection.
- **R5.04 · Custom events & projections** — `streams-event-sourcing` — arbitrary domain events and windowed
  projections on the same stream. Grounding: EchoMQ custom events. Dives: domain events on the stream · windowed
  aggregation · reserved-name discipline.
- **R5.05 · Workshop** — a live Portal activity feed. **Door:** EchoMQ's cross-runtime event system.

## R6 · Flow Control & Scale — staying stable under load · `/redis-patterns/flow-control` · → EchoMQ · ○ planned
> Keeping the system stable under load: limiting, fairness, batching, concurrency. Grounding: EchoMQ's limiter,
> groups, and bulk add. Depends on R3/R4.

- **R6.01 · Rate limiting** — `rate-limiting` — fixed/sliding window, token/leaky bucket, enforced globally.
  Grounding: EchoMQ `:limiter` `INCR`/`PEXPIRE` inside `MoveToActive`. Dives: fixed/sliding window · token/leaky
  bucket · global vs local (the Go gap).
- **R6.02 · Priorities & fairness** — `lexicographic-sorted-sets` — starvation and how to avoid it. Grounding: the
  priority ZSET under load. Dives: priority starvation · aging / reserved capacity · priorities vs separate queues.
- **R6.03 · Groups & multi-tenant fairness** — round-robin fairness + a per-group `distributed-locking`/
  `rate-limiting` semaphore. Grounding: EchoMQ groups (and the workaround keys). Dives: round-robin across tenants ·
  per-group concurrency/limit · group vs separate-queue.
- **R6.04 · Batches & pipelining** — `atomic-updates` — one round-trip, all-or-nothing bulk enqueue. Grounding:
  EchoMQ `addBulk` `MULTI/EXEC`. Dives: round-trip elimination · chunking across a pool · partial-failure handling.
- **R6.05 · Worker concurrency** — the Redis-fetch ceiling and how to plan capacity. Grounding: EchoMQ's
  concurrency models (BEAM process / goroutine semaphore). Dives: parallel vs concurrent · the per-job-fetch
  bottleneck · capacity planning.
- **R6.06 · Workshop** — rate-limit and fairly schedule Portal's API + jobs. **Door:** EchoMQ's scaling subsystem.

## R7 · Data Modeling & Memory — how data lives in RAM · `/redis-patterns/data-modeling` · ○ planned
> How data is modeled and how memory is spent — the modeling family and Portal's dashboard read-models. Grounding:
> Portal read-models, with EchoMQ's memory discipline as the worked example for optimization.

- **R7.01 · Redis as a primary database** — `redis-as-primary-database` — Redis as the system of record, not a
  cache. Grounding: EchoMQ's job HASH as the record of truth (`noeviction`). Dives: system-of-record · `noeviction`
  · persistence (RDB/AOF).
- **R7.02 · Memory optimization** — `memory-optimization` — compact encodings and short fields. Grounding: EchoMQ
  compressed fields (`atm/ats/stc/deid`), `LTRIM`, `MAXLEN ~`. Dives: listpack/intset encodings · short field names
  · capped structures.
- **R7.03 · Probabilistic data structures** — `probabilistic-data-structures` — trade accuracy for memory.
  Grounding: **contrast** with EchoMQ's exact `de:{id}` dedup. Dives: HyperLogLog · Bloom/Cuckoo · Count-Min/T-Digest.
- **R7.04 · Bitmaps** — `bitmap-patterns` — millions of boolean flags in minimal memory. Grounding: Portal
  daily-active-learner analytics. Dives: 1-bit flags · BITCOUNT aggregates · daily-active patterns.
- **R7.05 · Vectors & similarity search** — `vector-sets` + `vector-search-ai` — Redis 8 native vector sets for
  semantic search. Grounding: Portal course recommendations. Dives: Redis 8 HNSW vector sets · RAG / recommendations
  · filtered queries.
- **R7.06 · Geospatial** — `geospatial` — locations and radius queries on a geohash sorted set. Grounding: a clean
  standalone example + a Portal note. Dives: GEOADD/GEOSEARCH · radius/box queries · the geohash sorted-set.
- **R7.07 · Workshop** — Portal's dashboard read-models (leaderboard + HyperLogLog uniques + recommendations).

## R8 · Production & Operations — running the tier at scale · `/redis-patterns/production-operations` · → EchoMQ · ○ planned
> Operating the Redis/EchoMQ tier in production — the real-world case studies and the operational discipline; the
> capstone that hands off to the EchoMQ course. Grounding: EchoMQ's production guide and the source case studies.

- **R8.01 · Linux kernel tuning for Redis** — `kernel-tuning` — kernel settings that prevent latency spikes and
  persistence failures. Dives: THP / overcommit · latency spikes · persistence-safe settings.
- **R8.02 · Persistence, pooling & failover** — operating `redis-as-primary-database` in production. Grounding:
  EchoMQ's production guide (ch31). Dives: RDB + AOF · pool sizing · READONLY-reconnect failover.
- **R8.03 · Pinterest: task queues & partitioning** — `pinterest-task-queue` — functional partitioning and
  list-based reliable queues at scale. Dives: functional partitioning · list-based reliable queues · 1 → 1000+ scaling.
- **R8.04 · Twitter/X: internals & custom structures** — `twitter-internals` — customizations that became Redis
  core. Dives: quicklist / memory · timeline fan-out · what became core.
- **R8.05 · Uber: resilience & staggered sharding** — `uber-resilience` — staggered sharding, circuit breakers,
  graceful degradation. Grounding: EchoMQ's READONLY-reconnect. Dives: staggered sharding · circuit breakers ·
  graceful degradation.
- **R8.06 · Operating EchoMQ** — the bridge: pooling, cluster colocation, metrics and tracing in production.
  Grounding: EchoMQ ch29–31. Dives: cluster colocation in prod · Prometheus / OpenTelemetry · the polyglot fleet.
- **R8.07 · Capstone — the door to the EchoMQ course** — what the dedicated EchoMQ course teaches next: the polyglot
  protocol, the full Lua inventory, the three runtimes.

---

## The door to the EchoMQ course

The chapters marked **→ EchoMQ** (R2, R3, R4, R5, R6, R8) each end by pointing at a separate, dedicated **EchoMQ
course** that teaches the polyglot protocol itself — the immutable L1/L2 layers, the 53 Lua scripts, the three
runtimes (`docs/echomq/`, `apps/echomq-go/`). That course is built next with the same toolkit, the parser pointed at
the EchoMQ corpus. redis-patterns teaches the patterns; the EchoMQ course teaches the system that applies them.

## Tally

9 chapters (R0 landing + R1–R8 spec chapters), ~46 teaching modules + 8 workshops, ~140 dives. All 30 catalog
patterns are placed exactly once: **Fundamental ×20** across R1–R7, **Community ×6** (bitmap R7.04, geospatial
R7.06, leaderboards R4.05, pubsub R5.03, session-management R1.06, vector-search-ai R7.05), **Production ×4** in R8.

---

> Part of the jonnify toolkit. The TOC maps; the [roadmap](redis-patterns.roadmap.md) plans; the
> [chapter specs](specs/redis-patterns.md) define. Branded id format: `TSK` + Base62(snowflake), e.g.
> `TSK0KHTOWnGLuC`.
