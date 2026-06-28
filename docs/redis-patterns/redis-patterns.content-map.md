# Redis Patterns Applied — content ↔ chapter mapping

> The bridge from the **original source corpus** (`docs/redis-patterns/content/`) to the **course chapters and
> modules**. Every one of the 30 upstream pattern files maps to exactly one **primary** module (where the pattern is
> taught) and, for the five recurring patterns, to the later modules that reuse it as an **applied** example. For each
> module this file names the source file and the specific **ideas and techniques** an author folds into its pages, so
> no upstream material is orphaned and every page is grounded in the original write-up.
>
> This is the authoring companion to the [TOC](redis-patterns.toc.md) (structure), the
> [roadmap](redis-patterns.roadmap.md) (the EchoMQ/Portal grounding map + the no-invent authority), and the
> [progress dashboard](redis-patterns.progress.md) (delivery). Where the upstream content and the grounding map
> differ on what is *real*, the grounding map wins — the content file supplies the **technique and trade-off**; the
> grounding map supplies the **verified artifact** (`docs/echomq/`, `apps/echomq-go/`, the Portal facade).

## The corpus

`docs/redis-patterns/content/` holds **30 pattern write-ups** (each as `<slug>.md.txt` + a rendered `.html`) in three
sections, plus support files:

- **`fundamental/` ×20** — atomic-updates, cache-aside, cache-stampede-prevention, client-side-caching,
  cross-shard-consistency, delayed-queue, distributed-locking, hash-tag-colocation, lexicographic-sorted-sets,
  memory-optimization, probabilistic-data-structures, rate-limiting, redis-as-primary-database, redlock,
  reliable-queue, streams-consumer-patterns, streams-event-sourcing, vector-sets, write-behind, write-through.
- **`community/` ×6** — bitmap-patterns, geospatial, leaderboards, pubsub, session-management, vector-search-ai.
- **`production/` ×4** — kernel-tuning, pinterest-task-queue, twitter-internals, uber-resilience.
- **Support** — `llms.txt` (the upstream pattern index + the "For Agents" selection tables), `commands-index.md.txt`
  (the Redis command reference, cited across every chapter for `redis.io/commands/<cmd>` links), `course.html` (the
  upstream catalog page, re-themed as the course **home map** — R0.1; not ported verbatim), `_00.txt`,
  `_downloads.html`.

**Authoring rule.** When a module is authored, its agent **mines its mapped content file** for the real commands,
the trade-offs (Advantage / Disadvantage / when-to-use), and the worked technique, then grounds the example in the
real EchoMQ/Portal artifact the [roadmap](redis-patterns.roadmap.md) names. The content file is the *technique
source*; it is not a license to invent — only real commands and real artifacts ship.

## Master map — content file → module(s)

| Content file | Primary module | Reused (applied) in | Section |
| --- | --- | --- | --- |
| `course.html` | R0.1 home map | — | — |
| `commands-index` | every chapter (command links) | — | — |
| `fundamental/cache-aside` | R1.01 | R1.07 workshop | F |
| `fundamental/write-through` | R1.02 | — | F |
| `fundamental/write-behind` | R1.03 | — | F |
| `fundamental/client-side-caching` | R1.04 | — | F |
| `fundamental/cache-stampede-prevention` | R1.05 | R1.07 workshop | F |
| `community/session-management` | R1.06 | R1.07 workshop | C |
| `fundamental/atomic-updates` | R2.01 | R3.04 state machine · R6.04 batches | F |
| `fundamental/distributed-locking` | R2.02 | R6.03 groups | F |
| `fundamental/redlock` | R2.03 *(contrast)* | — | F |
| `fundamental/cross-shard-consistency` | R2.04 | — | F |
| `fundamental/hash-tag-colocation` | R2.05 | — | F |
| `fundamental/reliable-queue` | R3.01 | R3.02 · R3.03 · R3.05 · R8.03 pinterest | F |
| `fundamental/delayed-queue` | R4.01 | R4.02 schedulers · R4.04 backoff | F |
| `fundamental/lexicographic-sorted-sets` | R4.03 | R6.02 priorities & fairness | F |
| `community/leaderboards` | R4.05 | — | C |
| `fundamental/streams-event-sourcing` | R5.01 | R5.04 projections | F |
| `fundamental/streams-consumer-patterns` | R5.02 | — | F |
| `community/pubsub` | R5.03 | — | C |
| `fundamental/rate-limiting` | R6.01 | R6.03 groups | F |
| `fundamental/redis-as-primary-database` | R7.01 | R8.02 persistence/failover | F |
| `fundamental/memory-optimization` | R7.02 | — | F |
| `fundamental/probabilistic-data-structures` | R7.03 *(contrast)* | — | F |
| `community/bitmap-patterns` | R7.04 | — | C |
| `fundamental/vector-sets` + `community/vector-search-ai` | R7.05 | — | F+C |
| `community/geospatial` | R7.06 | — | C |
| `production/kernel-tuning` | R8.01 | — | P |
| `production/pinterest-task-queue` | R8.03 | — | P |
| `production/twitter-internals` | R8.04 | — | P |
| `production/uber-resilience` | R8.05 | — | P |

All 30 patterns are placed once as a **primary** module; the five recurring ones (`atomic-updates`, `reliable-queue`,
`delayed-queue`, `lexicographic-sorted-sets`, `redis-as-primary-database` / `streams-event-sourcing`) reappear as
labelled **applied** examples, taught once and reused in context. R6.05 worker-concurrency and R8.06 operating-EchoMQ
have **no** upstream pattern file — they are grounded directly in the EchoMQ docs (`docs/echomq/`), as is R0.2/R0.3.

---

## R1 · Caching — deep technique map

> Source files mined per module; the **ideas/techniques** column is what an authoring agent folds into the dives.

### R1.01 cache-aside ← `fundamental/cache-aside.md.txt`
- **miss-fill** — *How It Works* + *Redis Commands Used* (`GET` → on miss read source → `SETEX`); the 2-round-trip read path.
- **invalidation** — *Mitigating Staleness* (explicit invalidate on write via `DEL`); the write-then-invalidate ordering hazard (a concurrent read can resurrect the old value).
- **ttl-staleness** — *The Staleness Problem* + *Mitigating Staleness* (TTL as a bounded backstop); *When to Use / When to Avoid* (read-heavy, staleness-tolerant).

### R1.02 write-through ← `fundamental/write-through.md.txt`
- **dual-write** — *How It Works* + *Redis Commands Used* (`SET` cache + DB synchronously, `GET` on read).
- **consistency** — *Advantages* (reads always hit fresh cache); read-after-write freshness.
- **latency-cost** — *Disadvantages* + *Handling Partial Failures* (every write pays both stores; what happens when one store fails).

### R1.03 write-behind ← `fundamental/write-behind.md.txt`
- **async-buffer** — *How It Works* + *The Sync Process* (write Redis now, queue the DB sync).
- **durability** — *The Durability Trade-off* + *Mitigating Data Loss* (the unflushed window; AOF/replica bounds).
- **coalescing** — *Advantages* (collapse repeated writes to one key into a single flush).

### R1.04 client-side-caching ← `fundamental/client-side-caching.md.txt`
- **client-tracking** — *The Architecture* + *Tracking Modes* (Default vs Broadcasting); `CLIENT TRACKING`.
- **invalidation-push** — *How Invalidation Works* + *The NOLOOP Option* + *OPTIN/OPTOUT* (RESP3 invalidation message).
- **script-cache** — the *parallel*: `EVALSHA` + a local SHA cache + `NOSCRIPT` fallback, grounded in the real EchoMQ `ScriptLoader` (`apps/echomq-go/pkg/echomq/scripts/loader.go`) — a parallel, **not** an EchoMQ door.

### R1.05 cache-stampede-prevention ← `fundamental/cache-stampede-prevention.md.txt`
- **lock-on-miss** — *Solution 2: Mutex Locking* (`SET NX PX` regeneration lock; *Handling Waiting Clients*; *Releasing the Lock*).
- **early-refresh** — *Solution 1: Probabilistic Early Expiration (X-Fetch)* + *The Algorithm* (the real refresh-ahead formula — cite it, do not invent).
- **coalescing** — *The Problem* + *Comparison* + *Recommendation* (many concurrent misses collapse into one regeneration).

### R1.06 session-management ← `community/session-management.md.txt`
- **encodings** — *Hash-Based Sessions* vs *String-Based Sessions with JSON* (field-level access vs opaque blob); *Memory Optimization*.
- **ttl-expiry** — *Sliding Expiration* (refresh-on-access) + *Session Data Cleanup* (lazy/active eviction).
- **auth-session** — *Session Creation Flow* + *Logout Operations* + *Multi-Device Session Tracking* + *Real-Time Session Invalidation* + *Security Considerations*; grounded in Portal's F6.8.1 session store.

### R1.07 workshop ← `cache-aside` + `cache-stampede-prevention` + `session-management` (applied) + Portal catalog
- **cache-the-catalog** — wire cache-aside (R1.01) over the listing + a course page.
- **keep-it-consistent** — invalidation + the consistency choice (aside vs through, R1.01/R1.02).
- **harden-and-measure** — stampede-protect the hot course (R1.05) + measure hit rate with `INCR` counters.

---

## R2–R8 · technique map (headline; deepened per wave)

> Each row: the module's content source + the headline techniques to fold in. Deepened to per-dive detail (as R1
> above) when the chapter's wave is authored.

### R2 · Coordination
- **R2.01 atomic-updates** ← `fundamental/atomic-updates` — `WATCH/MULTI/EXEC` optimistic locking (contrast) · Lua for complex logic · shadow-key bulk. Ground in EchoMQ's inline Lua moves (`EchoMQ.Jobs.enqueue`/`claim`/`complete` via `EchoMQ.Script.new/2`, EVALSHA-first).
- **R2.02 distributed-locking** ← `fundamental/distributed-locking` — `SET NX PX` (contrast) · fencing tokens · lease renewal. Ground in the claim lease (`@claim` `ZADD active now+lease_ms`) + `attempts` (`HINCRBY`) the fence; `Consumer`/`Jobs.reap` recovery.
- **R2.03 redlock** ← `fundamental/redlock` *(contrast)* — N/2+1 majority · clock assumptions · when single-instance is enough (EchoMQ's single-Valkey claim lease).
- **R2.04 cross-shard-consistency** ← `fundamental/cross-shard-consistency` — torn writes · version tokens · commit markers. Ground in the one-slot requirement of a multi-key Lua EVAL + `attempts` the monotone token.
- **R2.05 hash-tag-colocation** ← `fundamental/hash-tag-colocation` — `{tag}` slot forcing · `CROSSSLOT` prevention · cluster CRC16. Ground in `EchoMQ.Keyspace.queue_key` → `emq:{q}:*`, `slot/1` CRC16 % 16384 (client-side).

### R3 · Reliable Queues
- **R3.01 processing-list** ← `fundamental/reliable-queue` — `LMOVE`/`RPOPLPUSH` to a processing list. Ground in EchoMQ `MoveToActive`.
- **R3.02 at-least-once** ← `fundamental/reliable-queue` (applied) — delivery guarantees · idempotent consumers · `de:{id}` dedup.
- **R3.03 stalled-recovery** ← `fundamental/reliable-queue` (applied) — reclaim crashed-worker jobs. Ground in EchoMQ `moveStalledJobsToWait`.
- **R3.04 atomic-state-machine** ← `fundamental/atomic-updates` (applied) — the lifecycle as one Lua transition. Ground in EchoMQ `moveToFinished-14`.
- **R3.05 blocking-vs-polling** ← `fundamental/reliable-queue` (applied) — busy-poll cost · blocking pop. Ground in EchoMQ `:marker` + `BZPOPMIN`.

### R4 · Time, Delay & Priority
- **R4.01 delayed-queue** ← `fundamental/delayed-queue` — ZSET score = fire-time · `ZRANGEBYSCORE` promotion. Ground in EchoMQ `:delayed` + `promoteDelayedJobs`.
- **R4.02 schedulers** ← `fundamental/delayed-queue` (applied) — cron vs interval · upsert. Ground in EchoMQ `:repeat` ZSET.
- **R4.03 priority-scores** ← `fundamental/lexicographic-sorted-sets` — composite score packing. Ground in EchoMQ `getPriorityScore` (`priority * 0x100000000 + pc`).
- **R4.04 backoff-retry** ← `fundamental/delayed-queue` (applied) — exponential backoff + jitter. Ground in EchoMQ `retryJob`.
- **R4.05 leaderboards** ← `community/leaderboards` — `ZADD`/`ZRANK` · top-N · around-me. Ground in Portal progress rankings.

### R5 · Streams & Events
- **R5.01 event-sourcing** ← `fundamental/streams-event-sourcing` — append-only log · replay · `last_event_id`. Ground in EchoMQ `:events` `XADD`.
- **R5.02 consumer-patterns** ← `fundamental/streams-consumer-patterns` — `XREAD BLOCK` → consumer groups · poison pills · `MAXLEN ~`. Ground in EchoMQ QueueEvents.
- **R5.03 pubsub-vs-streams** ← `community/pubsub` — fire-and-forget vs durable. Ground in EchoMQ `echomq:cancel` + the ch22 decision.
- **R5.04 projections** ← `fundamental/streams-event-sourcing` (applied) — domain events · windowed projections.

### R6 · Flow Control
- **R6.01 rate-limiting** ← `fundamental/rate-limiting` — fixed/sliding window · token/leaky bucket. Ground in EchoMQ `:limiter` `INCR`/`PEXPIRE`.
- **R6.02 priorities-fairness** ← `fundamental/lexicographic-sorted-sets` (applied) — priority starvation · aging.
- **R6.03 groups** ← `fundamental/distributed-locking` + `fundamental/rate-limiting` (applied) — round-robin fairness · per-group semaphore. Ground in EchoMQ groups.
- **R6.04 batches** ← `fundamental/atomic-updates` (applied) — `MULTI/EXEC` bulk. Ground in EchoMQ `addBulk`.
- **R6.05 worker-concurrency** ← *(no content file)* `docs/echomq/` — the Redis-fetch ceiling · BEAM process / goroutine semaphore.

### R7 · Data Modeling & Memory
- **R7.01 primary-database** ← `fundamental/redis-as-primary-database` — system-of-record · `noeviction` · persistence. Ground in EchoMQ's job HASH.
- **R7.02 memory-optimization** ← `fundamental/memory-optimization` — listpack/intset · short fields · capped structures. Ground in EchoMQ compressed fields (`atm/ats/stc/deid`).
- **R7.03 probabilistic** ← `fundamental/probabilistic-data-structures` *(contrast)* — HyperLogLog · Bloom/Cuckoo · Count-Min/T-Digest vs EchoMQ exact `de:{id}`.
- **R7.04 bitmaps** ← `community/bitmap-patterns` — 1-bit flags · `BITCOUNT`. Ground in Portal daily-active analytics.
- **R7.05 vectors** ← `fundamental/vector-sets` + `community/vector-search-ai` — Redis 8 HNSW vector sets · RAG/recommendations · filtered queries.
- **R7.06 geospatial** ← `community/geospatial` — `GEOADD`/`GEOSEARCH`/`GEODIST` · geohash ZSET.

### R8 · Production & Operations
- **R8.01 kernel-tuning** ← `production/kernel-tuning` — THP · overcommit · persistence-safe settings.
- **R8.02 persistence-failover** ← `fundamental/redis-as-primary-database` (applied) + `docs/echomq/` ch31 — RDB+AOF · pool sizing · READONLY-reconnect.
- **R8.03 pinterest** ← `production/pinterest-task-queue` — functional partitioning · list-based reliable queues · 1→1000+.
- **R8.04 twitter** ← `production/twitter-internals` — quicklist · timeline fan-out · what became core.
- **R8.05 uber** ← `production/uber-resilience` — staggered sharding · circuit breakers · graceful degradation.
- **R8.06 operating-echomq** ← *(no content file)* `docs/echomq/` ch29–31 — pooling · cluster colocation · metrics/tracing.

---

## R0 · Overview — orientation (no pattern files)

- **R0.1** ← `content/course.html` re-themed as the home map; the upstream `llms.txt` selection tables seed the home's grounding interactive.
- **R0.2** ← Portal facade + `portal.roadmap.md` (no content pattern file).
- **R0.3** ← the EchoMQ four-layer model in `docs/echomq/` (no content pattern file).

---

> Part of the jonnify toolkit. The corpus supplies the technique; the grounding map supplies the verified artifact;
> together they keep every page both **useful** (a real Redis technique with its trade-off) and **honest** (grounded
> in real code, nothing invented).
