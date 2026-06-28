# Redis Patterns Applied · program roadmap

> The delivery plan for the course: the chapter sequence as a guided build of the EchoMQ bus's Valkey tier, the
> milestones that group it, the **grounding map** that fixes which real EchoMQ/EchoStore artifact each pattern is shown
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
real code. The course's worked examples are drawn from **EchoMQ** — the owned-protocol job queue at `echo/apps/echo_mq`
whose *"Lua scripts ARE the protocol"* — and from **EchoStore** (`echo/apps/echo_store`), with the **codemojex**
(`echo/apps/codemojex`) the worked consumer.

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
lesson is the pattern, so a chapter survives deleting EchoMQ (it falls back to the EchoStore surface or a standalone
example). This is the boundary that lets a second course — the EchoMQ course — own the implementation depth without
duplicating the patterns.

## The course at a glance

| Chapter | Theme (family) | Grounding | Door | Status |
|---|---|---|---|---|
| **R0** Overview | the catalog, Valkey under codemojex, patterns become protocol | the EchoMQ thesis | → Protocol | ✓ built |
| **R1** `caching` | Caching — the read path | EchoStore (`echo/apps/echo_store`) | → Cache | ✓ built + reconciled |
| **R2** `coordination` | Coordination & consistency — atomicity first | EchoMQ inline Lua / claim lease + `attempts` fence / braced colocation (`echo/apps/echo_mq`) | → Protocol | ✓ built + reconciled |
| **R3** `queues` | Reliable queues — wait, active, done, recover | EchoMQ wait/active/`RPOPLPUSH` | → Queue, /echo-persistence | ✓ built |
| **R4** `time-delay-priority` | Time, delay & priority — the sorted set as a clock | EchoMQ `:delayed`/`:repeat`/priority ZSETs | → Queue, /echo-persistence | ✓ built |
| **R5** `streams-events` | Streams & events — the durable log | EchoMQ `:events` stream | → Bus, Cache | ✓ built |
| **R6** `flow-control` | Flow control & scale — staying stable under load | EchoMQ limiter / fair lanes / `enqueue_many` | → Queue | ✓ built |
| **R7** `data-modeling` | Data modeling & memory — how data lives in RAM | codemojex read-models; EchoMQ memory | → Protocol (secondary) | ✓ R7.01–R7.07 built (COMPLETE) |
| **R8** `production-operations` | Production & operations — running the tier at scale | the real `valkey.conf` + `EchoMQ.Pool`/`Connector` + the source case studies | → Proof (capstone) | ✓ R8.01–R8.07 built (COMPLETE) |

The **Door** column names the EchoMQ chapter(s) each redis-patterns chapter opens onto; the canonical, bidirectional
R↔E door map (with the content rationale and the matching `E ← R` reverse-links) is
[`redis-patterns.echomq-doors.md`](redis-patterns.echomq-doors.md). A door is a teaching hand-off, not a grounding:
R1 grounds in **EchoStore**'s real near-cache code (`echo/apps/echo_store`) yet doors to the **Cache** pillar (`/echomq/cache`) — the dedicated EchoMQ course's near-cache, EchoStore, in depth.

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
(`emq:{queue}:…`); functions/scripts are real in `echo/apps/echo_mq` (+ `echo_store` / `echo_wire`).

| Pattern (catalog slug) | Chapter | Real grounding |
|---|---|---|
| `cache-aside` | R1.01 | `EchoStore.Table.fetch/3` (`:hit\|:l2\|:fill`); `launch_flight` GET→loader→`SET … PX`; `invalidate/3` DEL |
| `write-through` | R1.02 | `EchoStore.Table.put/3,4` — synchronous `SET` L2 + L1 insert, the `version<>value` frame |
| `write-behind` | R1.03 | `EchoStore.Journal` — the SQLite outbox + replay; `Coherence.enqueue` over EchoMQ's fair lanes |
| `client-side-caching` | R1.04 | RESP3 push (`Connector` protocol:3) + `Coherence.broadcast` `ecc:{t}:coh`; `EchoMQ.Script` SHA1 (EVALSHA-first) |
| `cache-stampede-prevention` | R1.05 | EchoStore single-flight (the `flights` map, the `coalesced` counter) + jittered `expires_at` |
| `session-management` | R1.06 | `EchoStore.Table.put` (`SET … PX`) + the kind gate (a branded `SES` key); `expires_at` + sweeper |
| `atomic-updates` | R2.01, R3.04 | every EchoMQ inline Lua move (`EchoMQ.Script.new/2`, EVALSHA-first) — `Jobs.enqueue`/`claim`/`complete`, `enqueue_many`; the generic `WATCH/MULTI/EXEC` contrast |
| `distributed-locking` | R2.02 | the claim lease `ZADD active now+lease_ms` (server clock) + `attempts` (`HINCRBY`) the fence; `EMQSTALE` on a stale token; `Consumer`/`Jobs.reap` recovery |
| `redlock` | R2.03 | **contrast** — single-Redis lease ≠ multi-master Redlock |
| `cross-shard-consistency` | R2.04 | EchoMQ multi-key Lua requires one slot (the torn-write reason) |
| `hash-tag-colocation` | R2.05 | `EchoMQ.Keyspace.queue_key` → `emq:{q}:*`; `slot/1`/`hashtag/1` CRC16-XMODEM % 16384, client-side (vector `12739`) |
| `reliable-queue` | R3.01–R3.05 | `:wait`/`:active` LISTs; `MoveToActive` `RPOPLPUSH`; `moveStalledJobsToWait`; `:marker` `BZPOPMIN` |
| `delayed-queue` | R4.01, R4.02, R4.04 | `:delayed` ZSET (score=ts); `promoteDelayedJobs`; `:repeat` ZSET; `retryJob` backoff `base*2^(n-1)` |
| `lexicographic-sorted-sets` | R4.03, R6.02 | `:prioritized` ZSET; `getPriorityScore` `priority*0x100000000+pc`; `:pc` `INCR` |
| `leaderboards` | R4.05 | `Codemojex.Board` — one ZSET per game (`cm:<game>:board`); `record/3` ZADD, `top/2` ZREVRANGE |
| `streams-event-sourcing` | R5.01, R5.04 | `:events` STREAM; `events.go` `XADD MAXLEN ~`; `last_event_id` replay |
| `streams-consumer-patterns` | R5.02 | EchoMQ QueueEvents — `XREAD BLOCK`; naive → `XREADGROUP` consumer groups; `MAXLEN ~` trim |
| `pubsub` | R5.03 | `echomq:cancel` channel; the explicit Streams-vs-Pub/Sub decision (ch22) |
| `rate-limiting` | R6.01 | `:limiter` `INCR`/`PEXPIRE` inside `MoveToActive` → `RateLimitedError` (global, not per-worker) |
| `redis-as-primary-database` | R7.01, R8.02 | EchoMQ job HASH as record of truth; `noeviction`; RDB/AOF |
| `memory-optimization` | R7.02 | the 3-field job HASH (`state`/`attempts`/`payload`) as a listpack; `LTRIM 0 63` wake-list cap (`lanes.ex`); `XTRIM … MAXLEN ~` (`stream.ex`); the Valkey listpack/intset thresholds |
| `probabilistic-data-structures` | R7.03 | **contrast** — exact `de:{id}` dedup motivates Bloom/Cuckoo/HLL |
| `bitmap-patterns` | R7.04 | codemojex daily-active-player analytics (BITCOUNT; the planned `cm-bitmapist` spike) |
| `vector-sets` + `vector-search-ai` | R7.05 | standalone Redis 8 Vector Sets (`VADD`/`VSIM`, HNSW); Valkey via the `valkey-search` module; forward-tense codemojex reco note (no surface) |
| `geospatial` | R7.06 | standalone core-Valkey `GEOADD`/`GEOSEARCH` (a GEO set is a ZSET, geohash = the score); honest-absence codemojex note |
| `kernel-tuning` | R8.01 | the source production case study |
| `pinterest-task-queue` | R8.03 | the source case study (functional partitioning, list queues) |
| `twitter-internals` | R8.04 | the source case study (custom structures → Redis core) |
| `uber-resilience` | R8.05 | the source case study; EchoMQ READONLY-reconnect failover |

The patterns *not* grounded in the EchoMQ queue (the cache and modeling families) are grounded elsewhere, honestly,
not forced onto the bus: the **cache family** (`cache-aside`, `write-through`, `write-behind`, `client-side-caching`,
`cache-stampede-prevention`, `session-management`) in **EchoStore** (`echo/apps/echo_store`); the modeling family
(`vector-sets`, `vector-search-ai`, `geospatial`, `bitmap-patterns`) in clean standalone examples with a codemojex
Platform note.

## Milestones

| Milestone | Chapters | What the reader can do at the end |
|---|---|---|
| **M1 · Read & coordinate** | R0–R2 | navigate the catalog, cache a read path, and reason about atomicity, locks, and cluster colocation |
| **M2 · The queue** | R3–R6 | build a reliable, scheduled, observable, rate-limited queue — the heart of the EchoMQ grounding |
| **M3 · Model & operate** | R7–R8 | model data and memory, and operate the Redis tier in production — the handoff to the EchoMQ course |

## The reframe — identity + grounding (a parallel rung sequence)

A separate `re`-prefixed rung sequence rebrands the built course from its dark-editorial identity to the BCS
**contract-sheet** identity (redis-red accent), re-grounds it to **Valkey + EchoMQ + EchoStore**, drops the BullMQ
framing, and retargets "Applied" to the BCS architecture. It is specified at
[`specs/reframe-echomq/`](specs/reframe-echomq/reframe-echomq.md) (the contract + the roadmap + the `re0` exemplar
triad). Rungs: **re0** (home + overview landing + R0.3 — shipped, the exemplar) · re1 (R0.2) · re2–re5 (R1–R4) ·
then R5–R8 are born reframed. The reframe gate adds the cross-course mounts (`/echomq`, `/bcs`, `/elixir`) so the
doors resolve; manifests reach a full links-PASS (unbuilt = non-anchor cards).

## How the course is authored — the Author/Operator loop

The course runs the same Author/Operator loop the elixir/AAW courses use:

- **Operator (the human)** settles the structure (this roadmap, the TOC, the chapter specs), then reviews each
  authored batch.
- **Author (Claude)** expands a chapter spec into pages — module hubs and dives — each grounded per the map above,
  each gated to STATUS: PASS.

The loop per chapter is **spec → author → gate → review → adapt.** Feedback edits the spec, which is the source of
truth; pages are never authored ahead of the spec.

## Seams & open decisions

- **The EchoMQ course is not designed here.** The chapters marked → EchoMQ link forward to it; it is **built** (the
  six pillars), grounded in `docs/echo_mq/` + `echo/apps/echo_mq`. It owns the protocol, the Lua inventory, and the
  polyglot thesis — the depth this course deliberately does not teach.
- **The deep spec layout starts at R0.** R0 carries the full elixir mirror — a chapter index
  ([`specs/overview/overview.md`](specs/overview/overview.md)), a chapter roadmap
  ([`specs/overview/r0.md`](specs/overview/r0.md)), and a per-module quad (`r0.M.{md,stories,llms,prompt}`) — as the
  exemplar. R1–R8 hold a chapter index today and deepen to quads as each is authored.
- **R0 is both the course landing and a `specs/` chapter.** It is realized as the home `index.html` (the full
  chapter→module map) + the overview landing `overview/index.html` (the R0 chapter landing), and is specified under
  [`specs/overview/`](specs/overview/overview.md).
- **EchoMQ is real and shipped.** The Elixir implementation (`echo/apps/echo_mq` + `echo_store` / `echo_wire`) is
  the real, citable canon, taught in depth by the dedicated `/echomq` course. Worked examples cite the real Elixir
  code and the committed BCS figures; they never fabricate a module, key, or script.

## Conventions

- **The grounding rule** (the master discipline): every module cites one real artifact and stays inside the
  redis-patterns ↔ EchoMQ-course boundary. No invented Redis command, Lua script, EchoMQ module, or codemojex API.
- **Branded Snowflake ids** on every built page (a `TSK…` build stamp in the canonical footer).
- **The spec system** is the contract: TOC maps, roadmap plans, chapter specs define; pages pass the ten
  jonnify-cms gates before they ship.
- **Voice.** Plain, specific, impersonal; the forbidden set (`revolutionary`, `blazing`, `magical`, `simply`,
  `just`, `obviously`, `effortless`), no first person, no exclamation, no perceptual verb applied to a tool.

## Map

- The structural map: [`redis-patterns.toc.md`](redis-patterns.toc.md).
- The spec-system contract + chapter map: [`specs/redis-patterns.md`](specs/redis-patterns.md).
- The chapter specs: [`specs/overview/overview.md`](specs/overview/overview.md) (deep: + `r0.md` + the `r0.1`/`r0.2` quads) ·
  [`specs/caching/caching.md`](specs/caching/caching.md) ·
  [`specs/coordination/coordination.md`](specs/coordination/coordination.md) ·
  [`specs/queues/queues.md`](specs/queues/queues.md) ·
  [`specs/time-delay-priority/time-delay-priority.md`](specs/time-delay-priority/time-delay-priority.md) ·
  [`specs/streams-events/streams-events.md`](specs/streams-events/streams-events.md) ·
  [`specs/flow-control/flow-control.md`](specs/flow-control/flow-control.md) ·
  [`specs/data-modeling/data-modeling.md`](specs/data-modeling/data-modeling.md) ·
  [`specs/production-operations/production-operations.md`](specs/production-operations/production-operations.md).
- The grounding corpus: [`../echo_mq/echo_mq.md`](../echo_mq/echo_mq.md) and `echo/apps/echo_mq/`.

---

> Part of the jonnify toolkit. The roadmap plans and fixes the grounding; the specs define; both are settled before
> any page is built. Branded id format: `TSK` + Base62(snowflake), e.g. `TSK0KHTOWnGLuC`.
