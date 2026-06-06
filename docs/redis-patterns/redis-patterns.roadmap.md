# Redis Patterns Applied · program roadmap

> The delivery plan for the course: the chapter sequence as a guided build of Portal's reserved Redis tier, the
> milestones that group it, the **grounding map** that fixes which real EchoMQ/Portal artifact each pattern is shown
> in, and the door to the dedicated EchoMQ course. This file is the *plan and the grounding contract*; the
> structural map is [`redis-patterns.toc.md`](redis-patterns.toc.md) and each chapter's module ladder is its spec
> under [`specs/`](specs/redis-patterns.md).

This is the program view above the per-chapter specs. The contract for *how* a chapter is specified and a page is
authored is [`specs/redis-patterns.md`](specs/redis-patterns.md); this file is *what the course teaches, in what
order, grounded in what.*

## What the course delivers

The 30 Redis design patterns of the [catalog](README.md), taught **applied** — each shown in a real system rather
than in the abstract — and sequenced so the course reads as one build: caching the read path, then the atomicity
that makes a queue possible, then the reliable queue, then time and priority, then streams, then flow control, then
the data model and memory, then production operations. The through line is that **a pattern is only useful when you
know which workload it fits and how it fails**, and the only reliable way to teach that is to show it working in
real code. The course's worked examples are drawn from **EchoMQ** — a polyglot job queue whose *"Lua scripts ARE
the protocol,"* the candidate for Portal's reserved F7–F9 multi-runtime layer — and from Portal's other Redis
surfaces.

## Where this starts and ends

- **Start.** The reader knows Redis commands but reaches for the wrong pattern (the failure mode the
  [README](README.md) describes). The course assumes command familiarity, not pattern judgement.
- **End.** The reader can choose the right pattern for a workload, name its failure mode, read a real atomic Lua
  move, and operate Redis as a system of record — and is ready for the **dedicated EchoMQ course**, which teaches
  the polyglot protocol the patterns build.

## Architecture decision — pattern-family chapters along the EchoMQ build arc

The course is organized by **pattern family** (so it keeps its identity as a Redis-patterns course, not an EchoMQ
architecture course), but the families are **sequenced along the EchoMQ build arc** — coordination → reliable queue
→ time → streams → flow control → operations — so the course doubles as a guided reading of how those patterns
build a real queue. The alternative, organizing by EchoMQ's documentation layers (protocol → core → advanced →
scaling), was rejected: it would teach EchoMQ's architecture rather than the transferable Redis patterns, and it is
the dedicated EchoMQ course's job.

The reversible seam: the grounding is **cited, not coupled**. Every worked example points at a real artifact but the
lesson is the pattern, so a chapter survives deleting EchoMQ (it falls back to the Portal surface or a standalone
example). This is the boundary that lets a second course — the EchoMQ course — own the implementation depth without
duplicating the patterns.

## The course at a glance

| Chapter | Theme (family) | Grounding | Door | Status |
|---|---|---|---|---|
| **R0** Overview | the catalog, Redis under Portal, patterns become protocol | the EchoMQ thesis | — | ○ planned |
| **R1** `caching` | Caching — the read path | Portal cache machine | — | ○ planned |
| **R2** `coordination` | Coordination & consistency — atomicity first | EchoMQ locks / Lua / colocation | → EchoMQ | ○ planned |
| **R3** `queues` | Reliable queues — wait, active, done, recover | EchoMQ wait/active/`RPOPLPUSH` | → EchoMQ | ○ planned |
| **R4** `time-delay-priority` | Time, delay & priority — the sorted set as a clock | EchoMQ `:delayed`/`:repeat`/priority ZSETs | → EchoMQ | ○ planned |
| **R5** `streams-events` | Streams & events — the durable log | EchoMQ `:events` stream | → EchoMQ | ○ planned |
| **R6** `flow-control` | Flow control & scale — staying stable under load | EchoMQ limiter / groups / `addBulk` | → EchoMQ | ○ planned |
| **R7** `data-modeling` | Data modeling & memory — how data lives in RAM | Portal read-models; EchoMQ memory | partial | ○ planned |
| **R8** `production-operations` | Production & operations — running the tier at scale | EchoMQ production guide + the case studies | → EchoMQ (capstone) | ○ planned |

## How the chapters compose — the dependency arc

The chapters depend only on those before them, following the EchoMQ knowledge DAG (`protocol/data-layer/lifecycle →
core → advanced → scaling → production`):

```text
R1 Caching            (independent — the read-path gateway)
R2 Coordination ──────▶ atomicity + locks + colocation
     │  (a reliable queue is built from atomic moves and a lock lease)
     ▼
R3 Reliable Queues ───▶ wait/active/RPOPLPUSH, stalled recovery, the atomic state machine
     │
     ├──────────────┬───────────────┐
     ▼              ▼               ▼
R4 Time/Priority  R5 Streams      R6 Flow Control
 (the delayed +    (the :events    (rate-limit, groups,
  priority ZSETs    log, consumers   batches, concurrency —
  over R3's jobs)   over R3's        over R3/R4)
                    lifecycle)
     └──────────────┴───────────────┘
                    ▼
R7 Data Modeling & Memory   (how the records and read-models live in RAM)
                    ▼
R8 Production & Operations  (operating all of the above at scale) ──▶ the EchoMQ course
```

Two consequences shape the order. **Coordination precedes the queue chapters** because EchoMQ's reliable queue is
literally an atomic Lua move plus a lock lease — R3 cannot be taught honestly before R2. And **R4/R5/R6 are
parallel surfaces over R3's jobs** (time, observability, and flow control of the same queue), so they are sequenced
by pedagogy, not by hard dependency.

## The grounding map (canonical — cite these; never invent)

This table fixes which real artifact each pattern's worked example is drawn from. It is the source of truth for the
"Redis Pattern Applied" rule in [`specs/redis-patterns.md`](specs/redis-patterns.md). Keys are EchoMQ's
(`bull:{queue}:…`); functions/scripts are real in `docs/echomq/` and `apps/echomq-go/pkg/echomq/`.

| Pattern (catalog slug) | Chapter | Real grounding |
|---|---|---|
| `cache-aside` | R1.01 | Portal catalog reads (cache miss-fill / invalidate) |
| `write-through` | R1.02 | Portal synchronous dual-write |
| `write-behind` | R1.03 | Portal async write buffer |
| `client-side-caching` | R1.04 | `CLIENT TRACKING`; EchoMQ `ScriptLoader` SHA1 script cache |
| `cache-stampede-prevention` | R1.05 | Portal hot-key refresh (lock / early-refresh / coalesce) |
| `session-management` | R1.06 | Portal F6.8.1 session store (TTL) |
| `atomic-updates` | R2.01, R3.04 | every EchoMQ Lua move — `moveToActive-11`, `moveToFinished-14`; `MULTI/EXEC` |
| `distributed-locking` | R2.02 | `bull:{queue}:{id}:lock` UUID+`PX`; `ExtendLock` GET-then-SET-PX; `removeLock` (`-2`/`-6`) |
| `redlock` | R2.03 | **contrast** — single-Redis lease ≠ multi-master Redlock |
| `cross-shard-consistency` | R2.04 | EchoMQ multi-key Lua requires one slot (the torn-write reason) |
| `hash-tag-colocation` | R2.05 | `bull:{queue}:*`; `cluster.go` `CalculateCRC16` / `GetClusterSlot` (% 16384) |
| `reliable-queue` | R3.01–R3.05 | `:wait`/`:active` LISTs; `MoveToActive` `RPOPLPUSH`; `moveStalledJobsToWait`; `:marker` `BZPOPMIN` |
| `delayed-queue` | R4.01, R4.02, R4.04 | `:delayed` ZSET (score=ts); `promoteDelayedJobs`; `:repeat` ZSET; `retryJob` backoff `base*2^(n-1)` |
| `lexicographic-sorted-sets` | R4.03, R6.02 | `:prioritized` ZSET; `getPriorityScore` `priority*0x100000000+pc`; `:pc` `INCR` |
| `leaderboards` | R4.05 | Portal progress rankings (ZADD/ZRANK/ZREVRANGE) |
| `streams-event-sourcing` | R5.01, R5.04 | `:events` STREAM; `events.go` `XADD MAXLEN ~`; `last_event_id` replay |
| `streams-consumer-patterns` | R5.02 | EchoMQ QueueEvents — `XREAD BLOCK`; naive → `XREADGROUP` consumer groups; `MAXLEN ~` trim |
| `pubsub` | R5.03 | `echomq:cancel` channel; the explicit Streams-vs-Pub/Sub decision (ch22) |
| `rate-limiting` | R6.01 | `:limiter` `INCR`/`PEXPIRE` inside `MoveToActive` → `RateLimitedError` (global, not per-worker) |
| `redis-as-primary-database` | R7.01, R8.02 | EchoMQ job HASH as record of truth; `noeviction`; RDB/AOF |
| `memory-optimization` | R7.02 | compressed fields `atm/ats/stc/deid`; `LTRIM` metrics; `MAXLEN ~`; msgpack opts |
| `probabilistic-data-structures` | R7.03 | **contrast** — exact `de:{id}` dedup motivates Bloom/Cuckoo/HLL |
| `bitmap-patterns` | R7.04 | Portal daily-active-learner analytics (BITCOUNT) |
| `vector-sets` + `vector-search-ai` | R7.05 | Portal recommendations (Redis 8 HNSW vector sets) |
| `geospatial` | R7.06 | standalone GEOADD/GEOSEARCH + a Portal note |
| `kernel-tuning` | R8.01 | the source production case study |
| `pinterest-task-queue` | R8.03 | the source case study (functional partitioning, list queues) |
| `twitter-internals` | R8.04 | the source case study (custom structures → Redis core) |
| `uber-resilience` | R8.05 | the source case study; EchoMQ READONLY-reconnect failover |

The patterns *not* grounded in EchoMQ (the cache and modeling families: `cache-aside`, `cache-stampede-prevention`,
`client-side-caching`, `write-behind`, `write-through`, `vector-sets`, `vector-search-ai`, `geospatial`,
`bitmap-patterns`, `session-management`) are grounded on Portal's other Redis surfaces or clean standalone examples
— honestly, not forced onto EchoMQ.

## Milestones

| Milestone | Chapters | What the reader can do at the end |
|---|---|---|
| **M1 · Read & coordinate** | R0–R2 | navigate the catalog, cache a read path, and reason about atomicity, locks, and cluster colocation |
| **M2 · The queue** | R3–R6 | build a reliable, scheduled, observable, rate-limited queue — the heart of the EchoMQ grounding |
| **M3 · Model & operate** | R7–R8 | model data and memory, and operate the Redis tier in production — the handoff to the EchoMQ course |

## How the course is authored — the Author/Operator loop

The course runs the same Author/Operator loop the elixir/AAW courses use:

- **Operator (the human)** settles the structure (this roadmap, the TOC, the chapter specs), then reviews each
  authored batch.
- **Author (Claude)** expands a chapter spec into pages — module hubs and dives — each grounded per the map above,
  each gated to STATUS: PASS.

The loop per chapter is **spec → author → gate → review → adapt.** Feedback edits the spec, which is the source of
truth; pages are never authored ahead of the spec.

## Seams & open decisions

- **The EchoMQ course is reserved, not designed here.** The chapters marked → EchoMQ link forward to it; it is built
  next with the same toolkit, the parser pointed at `docs/echomq/` + `apps/echomq-go/`. It owns the polyglot
  protocol, the 53-script Lua inventory, and the three runtimes — the depth this course deliberately does not teach.
- **Per-chapter roadmaps + per-module triads are deferred.** This stage authors the chapter index specs
  (`<chapter>.md`). The fuller elixir mirror — a `<chapter>.roadmap.md` and a per-module/dive triad — is added later
  if the page-authoring stage needs it.
- **R0 is the course landing, not a `specs/` chapter.** Its three modules live in the TOC and are realized as the
  home `index.html` + the re-themed `overview/course.html`.
- **EchoMQ is real but partly reserved.** The Go implementation (`apps/echomq-go/`) and the docs are real and
  citable; the Elixir/Node runtimes and the full multi-runtime deployment are documented intent. Worked examples
  cite the real Go code and the documented seam; they never fabricate shipped Elixir modules.

## Conventions

- **The grounding rule** (the master discipline): every module cites one real artifact and stays inside the
  redis-patterns ↔ EchoMQ-course boundary. No invented Redis command, Lua script, EchoMQ module, or Portal API.
- **Branded Snowflake ids** on every built page (a `TSK…` build stamp in the canonical footer).
- **The spec system** is the contract: TOC maps, roadmap plans, chapter specs define; pages pass the ten
  jonnify-cms gates before they ship.
- **Voice.** Plain, specific, impersonal; the forbidden set (`revolutionary`, `blazing`, `magical`, `simply`,
  `just`, `obviously`, `effortless`), no first person, no exclamation, no perceptual verb applied to a tool.

## Map

- The structural map: [`redis-patterns.toc.md`](redis-patterns.toc.md).
- The spec-system contract + chapter map: [`specs/redis-patterns.md`](specs/redis-patterns.md).
- The chapter specs: [`specs/caching/caching.md`](specs/caching/caching.md) ·
  [`specs/coordination/coordination.md`](specs/coordination/coordination.md) ·
  [`specs/queues/queues.md`](specs/queues/queues.md) ·
  [`specs/time-delay-priority/time-delay-priority.md`](specs/time-delay-priority/time-delay-priority.md) ·
  [`specs/streams-events/streams-events.md`](specs/streams-events/streams-events.md) ·
  [`specs/flow-control/flow-control.md`](specs/flow-control/flow-control.md) ·
  [`specs/data-modeling/data-modeling.md`](specs/data-modeling/data-modeling.md) ·
  [`specs/production-operations/production-operations.md`](specs/production-operations/production-operations.md).
- The grounding corpus: [`../echomq/echomq_index.md`](../echomq/echomq_index.md) and `apps/echomq-go/`. The reserved
  Portal layer: [`../elixir/specs/portal.roadmap.md`](../elixir/specs/portal.roadmap.md).

---

> Part of the jonnify toolkit. The roadmap plans and fixes the grounding; the specs define; both are settled before
> any page is built. Branded id format: `TSK` + Base62(snowflake), e.g. `TSK0KHTOWnGLuC`.
