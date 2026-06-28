# Redis Patterns Applied

> **The Redis design patterns, taught applied — grounded in the real BCS build: EchoMQ backed by Valkey, EchoStore
> in front, codemojex the worked consumer.** You learn each pattern as a problem→solution→trade-off→when-to-use
> unit, then see it proven in real code: a real Valkey key, command, atomic Lua script, or Elixir/Go function from
> EchoMQ (`echo/apps/echo_mq`) or EchoStore (`echo/apps/echo_store`). The course doubles as a guided build of that
> tier, and opens the door to a dedicated EchoMQ course.

This course teaches the **judgement layer above the command reference**: not *what* `ZADD` does, but *which pattern
fits which workload, and why*. Its claim is that an engineer (or an agent) who knows the commands still reaches for
the wrong pattern — a single-node "distributed lock" that a failure silently breaks, a fixed-window rate limiter
with a boundary-burst flaw, keys fanned across cluster slots and then a cross-slot `MULTI`. The fix is grounding:
every pattern here is shown **applied in a real system**, so the worked example is verifiable, not plausible.

## The running system: EchoMQ backed by Valkey

**EchoMQ** is an owned-protocol job queue at `echo/apps/echo_mq`, backed by **Valkey**: the braced `emq:{q}:`
keyspace, a three-field job hash, four sorted sets, eight verbs over six atomic Lua scripts — *the scripts ARE the
protocol*, an owned corpus of Redis patterns made declared code. So roughly two-thirds of the catalog (the queue,
coordination, streams, and scaling families) is grounded directly in EchoMQ's real code; the cache and modeling
families ground in **EchoStore** (`echo/apps/echo_store`, the L1/L2 near-cache) or clean standalone examples. The
worked consumer of both is the **codemojex** (`echo/apps/codemojex`, `echo/apps/codemojex/`). Where a chapter's
deeper implementation belongs to the protocol itself, it links forward to the **dedicated EchoMQ course**.

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
- **Grounding.** Real as-built code — `echo/apps/echo_mq` (EchoMQ), `echo/apps/echo_store` (EchoStore),
  `echo/apps/echo_wire` (the connector), `echo/apps/codemojex` (codemojex consumer) — and the committed
  BCS manuscript (`docs/echo/bcs/bcs.N.md`); never a fabricated module, never a `.out` transcript. The
  grounding map is fixed in [`redis-patterns.roadmap.md`](redis-patterns.roadmap.md).
- **Structure.** Three levels — chapter `R[N]` (a landing), module `R[N].[M]` (a hub), dive `R[N].[M].[S]` (≥3 per
  module). Each chapter closes with a **workshop** that advances the EchoMQ build.
- **Spec system.** The course is designed specs-first: this TOC is the map, [the roadmap](redis-patterns.roadmap.md)
  is the plan, and the per-chapter specs under [`specs/`](specs/redis-patterns.md) are the contracts pages are built
  from. See [`specs/redis-patterns.md`](specs/redis-patterns.md).
- **Quality.** Every page passes the ten jonnify-cms gates (`containers · svg · no-future · voice · storage ·
  motion · degrade · links · pager · refs`) and carries a branded Snowflake build stamp.

## Status — a living map

This TOC is kept in sync with the built course: when a module or chapter ships, its entry here is updated. It is the
human-readable companion to the per-chapter specs under [`specs/`](specs/redis-patterns.md), and must not contradict
them.

**Status legend:** `✓ built` (served under `/redis-patterns/…`) · `◐ in progress` · `○ planned`. **R0–R4** are
built and gated; R5 is complete (the landing + R5.01–R5.05 built); R6 is complete (the landing + R6.01–R6.06 built); R7 is complete (the landing + R7.01–R7.07 built); R8 is complete (the landing + R8.01–R8.07 built) — the catalog is fully built (R0–R8).

A `→ EchoMQ` marker on a chapter means its deeper implementation opens the door to the dedicated EchoMQ course.

**The reframe.** A parallel `re`-prefixed rung sequence ([`specs/reframe-echomq/`](specs/reframe-echomq/reframe-echomq.md))
rebrands the built course to the BCS **contract-sheet** identity (redis-red accent) and re-grounds it to **Valkey +
EchoMQ + EchoStore**, with the **codemojex** (`echo/apps/codemojex`, `echo/apps/codemojex/`) the worked consumer —
**no BullMQ**, the engine is Valkey only. **R0 is complete** (home + overview landing + R0.2 + R0.3, all in the
contract-sheet identity): R0.2 is retitled **"Valkey under codemojex"** (slug `redis-under-game` kept)
and re-grounded to the as-built `echo/apps/echo_wire` · `echo_mq` · `echo_store` and the codemojex consumer. R1–R4
are reconciled on the following rungs (`re2`–`re5`, via `/redis-reconcile`), where their per-module grounding is
retargeted from the Portal surfaces to the echo data layer.

---

## R0 · Overview — the catalog, and Valkey under codemojex · `/redis-patterns` · ✓ built (home + overview landing + R0.2 + R0.3, all gated)
> Orientation: the 30 patterns and how to read them, where Valkey sits in codemojex, and why getting a
> pattern exactly right is what makes a system correct. The course home (`index.html`, the full chapter→module map)
> plus the overview landing (`overview/index.html`, the R0 chapter landing). Grounding: the EchoMQ thesis.

- **R0.1 · The course home & the overview landing** — the home (`index.html`) carrying the full chapter→module map
  on the `elixir/index.html` pattern, plus the overview landing (`overview/index.html`): the R0 chapter landing —
  its module cards (R0.2, R0.3) and an "Up next" grid of the chapters that follow. A reading protocol and the
  Redis-specific (not Valkey/KeyDB) scope note are carried inline on the home, not as separate dives.
- **R0.2 · Valkey under codemojex** — the placement: codemojex reaches one boundary, the
  echo data layer; below it Valkey serves two roles — EchoStore (the derived near-cache) and the EchoMQ bus (the
  authoritative, owned-protocol bus at `echo/apps/echo_mq`), both over one owned client, EchoWire; the
  master-invariant seam, the two roles, and the tier retold as the program's convergence target. Dives: the facade
  seam · the two roles · the reserved tier.
- **R0.3 · Patterns become protocol** — the four-layer model and the immutable L1/L2 core; why the data model is the
  contract that makes three runtimes interoperate. Dives: the four layers · the immutable core · the door to the
  EchoMQ course.

## R1 · Caching — the read path · `/redis-patterns/caching` · ✓ built + reconciled (landing + R1.01–R1.07, all gated)
> The most common Valkey use: serving reads fast and keeping the cache consistent on writes. Grounding: **EchoStore**
> — the declared near-cache, an L1 of ETS tables over the shared L2 Valkey (`echo/apps/echo_store`) — in front of the
> **codemojex**'s instrument catalog; R1.04 reflects the idea in EchoMQ's SHA1 script cache.

- **R1.01 · Cache-aside (lazy loading)** — `cache-aside` — on miss, fetch and populate; on write, invalidate.
  Grounding: `EchoStore.Table.fetch/3` (`:hit|:l2|:fill`); `launch_flight` GET→loader→`SET … PX`; `invalidate/3` DEL.
  Dives: GET/SET miss-fill · explicit invalidation · TTL & staleness.
- **R1.02 · Write-through** — `write-through` — write to cache and the source synchronously so reads are always fresh.
  Grounding: `EchoStore.Table.put/3,4` (synchronous `SET` L2 + L1 insert, the `version<>value` frame). Dives:
  synchronous dual write · the consistency guarantee · the latency cost.
- **R1.03 · Write-behind (write-back)** — `write-behind` — write to Valkey and sync the source asynchronously.
  Grounding: `EchoStore.Journal` (the SQLite outbox + replay; `Coherence.enqueue` over EchoMQ's fair lanes). Dives:
  the async buffer · the durability trade-off · coalescing writes.
- **R1.04 · Server-assisted client-side caching** — `client-side-caching` — cache in app memory; the server pushes
  invalidations. Grounding: RESP3 push (`Connector` protocol:3) + `Coherence.broadcast` `ecc:{t}:coh`; `EchoMQ.Script`
  SHA1 (EVALSHA-first). Dives: RESP3 client tracking · invalidation push · the SHA1 script-cache parallel.
- **R1.05 · Cache stampede prevention** — `cache-stampede-prevention` — stop a thundering herd regenerating one
  expired key. Grounding: EchoStore single-flight (the `flights` map, the `coalesced` counter) + jittered `expires_at`.
  Dives: lock-on-miss · early refresh (jitter) · request coalescing.
- **R1.06 · Session management** — `session-management` — store sessions with TTL expiry. Grounding:
  `EchoStore.Table.put` (`SET … PX`) + the kind gate (a branded `SES` key); `expires_at` + sweeper. Dives: Hash vs
  String vs framed value · TTL expiry · the auth-session tie-in.
- **R1.07 · Workshop** — cache codemojex's instrument catalog end to end.

## R2 · Coordination & Consistency — atomicity first · `/redis-patterns/coordination` · → EchoMQ · ✓ built + reconciled (landing + R2.01–R2.06)
> The atomicity foundation every later chapter builds on: a reliable queue is made of atomic moves and a lock lease.
> Grounding: EchoMQ's inline Lua transitions, the claim lease + `attempts` fence, and the braced `emq:{q}:` keyspace
> (`echo/apps/echo_mq`, v2). Placed before the queue chapters per the dependency graph (atomic-multi-key-Lua → claim).

- **R2.01 · Atomic updates** — [`atomic-updates`](/redis-patterns/coordination/atomic-updates) — read-modify-write
  without a race. **✓ built + reconciled** (hub + 3 dives, all gated). Grounding: every EchoMQ state move is one
  **inline** Lua script (`EchoMQ.Script.new/2`, run EVALSHA-first by `EchoMQ.Connector.eval/5`) —
  `EchoMQ.Jobs.enqueue`/`claim`/`complete` + `enqueue_many` (pipelined EVALSHA), `echo/apps/echo_mq`; the generic
  `WATCH/MULTI/EXEC` is the contrast. Dives: `watch-multi-exec` · `lua-for-logic` · `shadow-key-bulk`.
- **R2.02 · Distributed locking** — [`distributed-locking`](/redis-patterns/coordination/distributed-locking) —
  mutual exclusion via the claim lease + a fencing token. **✓ built + reconciled** (hub + 3 dives, all gated).
  Grounding: `@claim`'s `ZADD active (now+lease_ms)` lease on the server clock + `attempts` (`HINCRBY`) the fencing
  token, `EMQSTALE` on a stale token at `@complete`/`@retry`; `EchoMQ.Consumer`/`Jobs.reap` recovery
  (`echo/apps/echo_mq`). Dives: `set-nx-px` (contrast) · `fencing-tokens` · `lease-renewal`.
- **R2.03 · The Redlock algorithm** — [`redlock`](/redis-patterns/coordination/redlock) — a majority-of-N multi-master
  lock. **✓ built + reconciled** (hub + 3 dives, all gated). Grounding: **contrast** — EchoMQ implements no Redlock;
  its lock is the single-Valkey claim lease + `attempts` fence, which a queue's idempotent work makes sufficient.
  Dives: `majority-of-n` · `clock-assumptions` · `single-instance-enough`.
- **R2.04 · Cross-shard consistency** — [`cross-shard-consistency`](/redis-patterns/coordination/cross-shard-consistency)
  — detect torn writes across instances. **✓ built + reconciled** (hub + 3 dives, all gated). Grounding: EchoMQ's
  answer is **prevention** — a multi-key Lua EVAL requires one slot, so the braced `{q}` keyspace co-locates a
  queue's keys (a cross-slot EVAL raises `CROSSSLOT`); `attempts` is the monotone version token. Dives: `torn-writes`
  · `version-tokens` · `commit-markers`.
- **R2.05 · Hash-tag co-location** — [`hash-tag-colocation`](/redis-patterns/coordination/hash-tag-colocation) — force
  related keys to one cluster slot. **✓ built + reconciled** (hub + 3 dives, all gated). Grounding:
  `EchoMQ.Keyspace.queue_key` → `emq:{q}:*` ("the hashtag IS the queue name"); `slot/1` = CRC16-XMODEM over
  `hashtag/1` % 16384, computed client-side (vector `slot("123456789") == 12739`, `echo/apps/echo_mq`). Dives:
  `the-tag-mechanic` · `crossslot-prevention` · `cluster-auto-detect`.
- **R2.06 · Workshop** — [`workshop`](/redis-patterns/coordination/workshop) — make an codemojex order
  placement atomic across runtimes. **✓ built + reconciled** (capstone hub, no dives). Grounding:
  `Codemojex.Guesses.submit/3` → the atomic `@enqueue` over co-located `emq:{orders}:*`. **Door:** the dedicated
  EchoMQ course (`/echomq`).

## R3 · Reliable Queues — pending, active, done, recover · `/redis-patterns/queues` · → EchoMQ · ✓ built (landing + 3 course-direction dives + all 6 granular modules R3.01–R3.06)
> The heart of EchoMQ: "reliable-queue" is a family of techniques — the densest real grounding in the course.
> Grounding: EchoMQ's `:pending`/`:active` lists, the `@claim` lease handoff, and stalled recovery. Depends on R2.

**✓ built — the chapter landing + 3 course-direction dives** ([`/redis-patterns/queues`](/redis-patterns/queues)): the
pivot chapter, written forward-looking (it surveys the arc R3→R8). Dives: [`the-reliable-queue`](/redis-patterns/queues/the-reliable-queue)
(`EchoMQ.Jobs.claim/3` leasing pending→active under a server-clock lease + idempotency at the gated branded-`JOB` key)
· [`states-as-locations`](/redis-patterns/queues/states-as-locations) (`EchoMQ.Jobs.complete/5` + `retry/7` as one EVALSHA
across the `attempts` fence + `EchoMQ.Consumer.park/1`'s `BLPOP emq:{queue}:wake`) · [`the-road-ahead`](/redis-patterns/queues/the-road-ahead)
(the arc R3→R8 + the door). Grounded in the real Elixir app `echo/apps/echo_mq`. **Door:** R3 → the living EchoMQ
course's **Queue pillar** ([`/echomq/queue`](/echomq/queue)) + the durability frontier
([`/echo-persistence`](/echo-persistence)). The granular module ladder R3.01–R3.06 below is the in-depth build — all six built.

- **R3.01 · [Processing list](/redis-patterns/queues/processing-list)** — `reliable-queue` — ✓ built — move a job out
  of pending *into* an in-flight list, so a crash is recoverable. Grounding: `EchoMQ.Jobs.claim/3` → the inline `@claim`
  Lua (pending→active under a lease). Dives: list-pending-active · the-lease-move ·
  the-in-flight-list.
- **R3.02 · [At-least-once](/redis-patterns/queues/at-least-once)** — `reliable-queue` — ✓ built — delivery guarantees
  and why consumers must be idempotent. Grounding: branded `JOB` ids + dedup at the gated key
  (`EchoMQ.Keyspace`). Dives: at-least-once-semantics · idempotent-consumers · why-exactly-once-is-a-lie.
- **R3.03 · [Stalled recovery](/redis-patterns/queues/stalled-recovery)** — `reliable-queue` — ✓ built — reclaim jobs
  whose worker died. Grounding: `EchoMQ.Stalled.check/3` (lease-expiry by server `TIME`, dead-letter past
  `max_stalled`). Dives: lease-expiry-detection · server-clock-compare · dead-lettering.
- **R3.04 · [Atomic state machine](/redis-patterns/queues/atomic-state-machine)** — `atomic-updates` — ✓ built — the
  whole lifecycle as one Lua transition. Grounding: `EchoMQ.Jobs.complete/5` + `retry/7` (the `attempts` fence; settle
  AND fetch the next in one EVALSHA) + the `EVALSHA→NOSCRIPT→EVAL` fallback. Dives:
  states-as-locations · read-decide-write-in-one-evalsha · evalsha-and-noscript.
- **R3.05 · [Blocking vs polling](/redis-patterns/queues/blocking-vs-polling)** — `reliable-queue` — ✓ built — stop
  busy-polling the queue. Grounding: `EchoMQ.Consumer.park/1`'s `BLPOP emq:{queue}:wake` (a list), woken when work
  is enqueued, vs a `time.Sleep` poll.
  Dives: the-busy-poll-cost · blocking-pop · the-wake-list-pickup.
- **R3.06 · [Workshop](/redis-patterns/queues/workshop)** — ✓ built — a reliable codemojex command-job queue
  assembling R3.01–R3.05; at-least-once + codemojex's idempotent `Codemojex.Guesses.submit/3` over
  `Codemojex.CommandWorker` = exactly-once-in-effect (applied design). No dives. **Door:** EchoMQ's
  Queue pillar ([`/echomq/queue`](/echomq/queue)).

## R4 · Time, Delay & Priority — the sorted set as a clock · `/redis-patterns/time-delay-priority` · → EchoMQ · ✓ complete (landing + 3 orientation dives + all six granular modules R4.01–R4.06 built)
> Scheduling: the sorted set as a timer wheel and a priority ladder. Grounding: EchoMQ's `:schedule`/`:repeat`
> machinery; priority is the contrast (EchoMQ retires numeric per-job priority for fair lanes). Depends on R3.

Orientation dives (built — hosted directly under the landing, the strategic-entry shape):
- **R4 · The sorted set as a clock** — [`/redis-patterns/time-delay-priority/the-sorted-set-as-a-clock`](/redis-patterns/time-delay-priority/the-sorted-set-as-a-clock) — one ZSET, two readings: a timer wheel (`:schedule`, score = run-at ms) and the composite-priority pattern (score = priority+arrival, the Redis form EchoMQ retires for fair lanes). ✓ built
- **R4 · Score as meaning** — [`/redis-patterns/time-delay-priority/score-as-meaning`](/redis-patterns/time-delay-priority/score-as-meaning) — the score is the semantics: run-at ms (`:schedule`), composite priority (`priority×2^32+pc`, the pattern), next-run millis (`:repeat`). ✓ built
- **R4 · The road ahead** — [`/redis-patterns/time-delay-priority/the-road-ahead`](/redis-patterns/time-delay-priority/the-road-ahead) — the arc R4.01→R4.06 and the door into EchoMQ's Queue pillar (scheduler + fair-lane precedence) plus the durability frontier. ✓ built

Granular modules (all built):
- **R4.01 · The delayed queue** — [`/redis-patterns/time-delay-priority/delayed-queue`](/redis-patterns/time-delay-priority/delayed-queue) — score a job by its fire-time, sweep by score. Grounding: EchoMQ
  `:schedule` ZSET + `EchoMQ.Jobs.enqueue_at/5` / `enqueue_in/5` + `promote/3` (the `@promote` sweep). Dives: score-is-fire-time · zrangebyscore-promotion · the-next-wake. ✓ built
- **R4.02 · Schedulers & repeatable jobs** — [`/redis-patterns/time-delay-priority/schedulers`](/redis-patterns/time-delay-priority/schedulers) — recurring jobs via cron/interval. Grounding: `EchoMQ.Repeat`
  (`every_ms`, EXISTS-upsert) driven by `EchoMQ.Pump` + `EchoMQ.Metronome`. Dives: cron-vs-interval · upsert-no-duplicates · start-to-start-cadence. ✓ built
- **R4.03 · Priority with composite scores** — [`/redis-patterns/time-delay-priority/priority-scores`](/redis-patterns/time-delay-priority/priority-scores) — the composite-score *pattern* (pack priority + arrival into one score) — and why EchoMQ retires it.
  Grounding: the Redis pattern `priority * 2^32 + counter` read by `ZPOPMIN`; the EchoMQ contrast — numeric per-job priority is **retired by design** (`lanes.ex`), precedence is per-lane fair-share weight (`EchoMQ.Lanes.weight/4` + `wclaim/3`, the `@gwclaim` Lua) and arrival is the branded `JOB` mint order. Dives: packing-two-keys-in-one-score ·
  fifo-within-tier · fair-lanes-vs-numeric-priority. ✓ built
- **R4.04 · Backoff & retry** — [`/redis-patterns/time-delay-priority/backoff-retry`](/redis-patterns/time-delay-priority/backoff-retry) — `delayed-queue` applied to retries: a failed job re-enters the same schedule ZSET at a backoff fire-time.
  Grounding: **`EchoMQ.Backoff.delay_ms/2` owns the math** (exponential + jitter); `EchoMQ.Jobs.retry/7` reschedules onto `:schedule`. Dives: exponential-backoff ·
  jitter-thundering-herd · reuse-the-schedule-zset. ✓ built
- **R4.05 · Leaderboards** — [`/redis-patterns/time-delay-priority/leaderboards`](/redis-patterns/time-delay-priority/leaderboards) — `leaderboards` — rankings on the sorted set; the rank is computed on read, never stored. Grounding: `Codemojex.Board`
  (one sorted set per game `cm:<game>:board` — `record/3` writes each player's best linear total with `ZADD` via `EchoWire.Cmd`, `top/2` reads the top-N with `ZREVRANGE … WITHSCORES`; score from `Codemojex.Scoring`). Dives: zadd-and-zrank · top-n-and-around-me · the-score-update-path. ✓ built
- **R4.06 · Workshop** — [`/redis-patterns/time-delay-priority/workshop`](/redis-patterns/time-delay-priority/workshop) — the single-page capstone: EchoMQ schedules codemojex's notification jobs (`Codemojex.NotificationWorker` over `cm.notify`), folding all five modules. **Door:** EchoMQ's Queue pillar ([`/echomq/queue`](/echomq/queue)). ✓ built

## R5 · Streams & Events — the durable log · `/redis-patterns/streams-events` · → EchoMQ · ✓ complete
> Observability and event-driven coordination, with Valkey Streams as the durable, replayable log. Grounding:
> EchoMQ's real shipped **Stream Tier** (`EchoMQ.Stream` / `EchoMQ.StreamConsumer`, keyspace `emq:{q}:stream`).
> Depends on R3 (the lifecycle the log records). Doors → `/echomq/bus` (the Bus pillar, built) + `/bcs/bus` (B3) +
> `/echo-persistence` (the archive frontier). The landing + R5.01–R5.05 are all built — the chapter is complete.

- **R5.01 · Event sourcing on Streams** — `streams-event-sourcing` — ✓ built — the append-only log is the source
  of truth; state is its replay. Grounding: `EchoMQ.Stream.append/4` → `XADD emq:{q}:stream`; `read/6` → `XRANGE`.
  Dives: `the-append-only-log` · `replay-and-rebuild` · `the-cursor`.
- **R5.02 · Stream consumer patterns** — `streams-consumer-patterns` — ✓ built — block, batch, trim, resume.
  Grounding: the naive `XREAD BLOCK` → `EchoMQ.StreamConsumer` (consumer groups, `XREADGROUP`/`XACK`, ack + resume)
  + `EchoMQ.Stream.trim/4` (`MAXLEN ~`) + `EchoMQ.StreamRetention`. Dives: `the-blocking-read` · `consumer-groups` ·
  `maxlen-trimming`.
- **R5.03 · Pub/Sub vs Streams** — `pubsub` — ✓ built — fire-and-forget vs durable, and how to choose. Grounding:
  `EchoMQ.Events` (the `emq:{q}:events` channel) + `EchoMQ.Cancel` (worker-side cooperative) — the durable-Streams
  choice is the contrast. Dives: fire-and-forget vs durable · the choosing rule · the dedicated blocking connection.
- **R5.04 · Custom events & projections** — `custom-events` — ✓ built — arbitrary domain events and windowed
  projections on the same stream. Grounding: custom events on `EchoMQ.Stream`. Dives: domain events on the stream ·
  windowed aggregation · reserved-name discipline.
- **R5.05 · [Workshop](/redis-patterns/streams-events/workshop)** — ✓ built — a live **codemojex** activity feed off
  the stream / `:events` lifecycle: a guess submitted / scored / a round settled appended via `EchoMQ.Stream.append/4`
  (the `EVT` receipt), the feed a fold of the log (`read/6`), consumed reliably with `EchoMQ.StreamConsumer`, bounded
  by `EchoMQ.StreamRetention` and archived by `EchoStore.StreamArchive`. Single-page capstone; folds all five modules.
  **Doors:** the EchoMQ Bus pillar (`/echomq/bus`) · `/bcs/bus` · `/echo-persistence`.

## R6 · Flow Control & Scale — staying stable under load · `/redis-patterns/flow-control` · → EchoMQ · ✓ complete (landing + R6.01–R6.06 built)
> Keeping the system stable under load: rate-limiting, lane fairness, multi-tenant groups, bulk enqueue, and worker
> concurrency. Grounding: EchoMQ's real flow-control layer — the `emq:{q}:limiter` counter, the fair-lane ring
> (`EchoMQ.Lanes`), and the bulk-enqueue path. Depends on R3/R4. The chapter landing + R6.01–R6.05 (each a
> hub + 3 dives) + R6.06 (the workshop) are built — the chapter is complete. Only `rate-limiting` (R6.01) is a fresh catalog pattern; R6.02–R6.05
> are flow-control techniques composing R2/R4 patterns.

- **R6.01 · Rate limiting** — `rate-limiting` — ✓ built (hub + 3 dives) — cap work to a budget per window.
  Grounding: `EchoMQ.Metrics.get_rate_limit_ttl/3` + the `@rate_ttl` Lua over `emq:{q}:limiter` / `emq:{q}:meta`
  (a fixed-window counter read; the window is the key's `PTTL`), `get_global_rate_limit/2`, the
  `[:emq, :rate_limit, :hit]` telemetry receipt; the dequeue-point enforcement is the dedicated EchoMQ scaling layer
  (door `/echomq/queue`). Dives: fixed & sliding windows · token & leaky buckets · global, not local (the limiter is
  server-side, so the budget is global by construction — retargets the old "global vs local").
- **R6.02 · Fairness under load** — fairness (the rota, **not** numeric per-job priority — retired by design) —
  ✓ built (hub + 3 dives) — prevent starvation under load. Grounding: `EchoMQ.Lanes` — the round-robin ring
  (`claim/3` + the `@gclaim` ring `LMOVE`) and the weighted share (`wclaim/3` / `weight/4` / the `gweight` hash,
  K = min(weight, depth, `glimit` headroom)); the B3.2 fair-lanes figure (`bcs.3.md`); consumer codemojex (a player
  lane, `Codemojex.Guesses`). Dives: starvation under load · the weighted share · lanes vs separate queues.
- **R6.03 · Groups & multi-tenant fairness** — fairness / round-robin — ✓ built (hub + 3 dives) — share capacity
  fairly across tenants. Grounding: `EchoMQ.Lanes` groups — grouped admission (`enqueue/5`), the ring (`claim/3`)
  with a per-group concurrency ceiling (`limit/4` → `glimit` / `gactive`), `pause`/`resume`, `reassign/4`; the B3.2
  fair-lanes figure (`bcs.3.md`); consumer codemojex (a player lane on the `cm` queue, `Codemojex.Guesses`). Dives:
  round-robin across tenants · per-group concurrency · group vs separate-queue.
- **R6.04 · Batches & pipelining** — *applies `atomic-updates`* — ✓ built (hub + 3 dives) — bulk enqueue in one wire
  flush, a per-item verdict for each job (NOT an all-or-nothing transaction). Grounding: `EchoMQ.Jobs.enqueue_many/4`
  (a pipelined EVALSHA batch via `EchoWire.Pipe`; `:enqueued`/`:duplicate`/`{:error, :kind}` per item, in input order)
  and the grouped batch claim `EchoMQ.Lanes.bclaim/3` (the `@bclaim` count-variant `ZPOPMIN`, one shared lease). Dives:
  round-trip elimination · chunking across a pool · partial-failure handling.
- **R6.05 · Worker concurrency** — ✓ built (hub + 3 dives) — the per-claim fetch ceiling and how to plan capacity.
  Grounding: the worker loop `EchoMQ.Consumer` (park-on-`BLPOP`; the opt-in `:metronome` pool path) over a round-robin
  `EchoMQ.Pool` (N pipelined connectors); the per-claim `ZPOPMIN` fetch (`claim/3`) amortized by
  `EchoMQ.Lanes.bclaim/3`. Dives: parallel vs concurrent · the per-claim-fetch bottleneck · capacity planning.
- **R6.06 · Workshop** — ✓ built — the single-page capstone: folds R6.01–R6.05 over codemojex's notification + guess
  pipelines (`Codemojex.NotificationWorker`'s "Fairness · Rate · Delivery", the `Codemojex.RateLimiter` token bucket,
  `Codemojex.Guesses.submit/3` per-player lanes, the `Codemojex.ScoreWorker`/`CommandWorker` consumer pool). **Door:**
  EchoMQ's scaling subsystem (`/echomq/queue`).

## R7 · Data Modeling & Memory — how data lives in RAM · `/redis-patterns/data-modeling` · ◐ in progress (landing + R7.01–R7.03 built)
> How data is modeled and how memory is spent — the modeling family and codemojex's dashboard read-models. Grounding:
> codemojex read-models, with EchoMQ's memory discipline as the worked example for optimization. Doors → `/bcs/fly`
> (the production config), `/bcs/persistence` + `/echo-persistence` (the durability floor). No `/echomq` door (the
> modeling family is not the bus's protocol).

- **R7.01 · Redis as a primary database** — `primary-database` — ✓ built — Redis as the system of record,
  not a cache. Grounding: EchoMQ's job HASH (`emq:{q}:job:<JOB>` — `state`/`attempts`/`payload`) as the record of
  truth under `noeviction` + AOF (`infra/valkey/conf/valkey.conf`); codemojex's per-datum split (game state in
  Valkey, money in Postgres). Dives: `system-of-record` · `noeviction` · `persistence`.
- **R7.02 · Memory optimization** — `memory-optimization` — ✓ built — compact encodings and short fields.
  Grounding: EchoMQ's memory discipline — the short job HASH (`state`/`attempts`/`payload`) → listpack, the
  `LTRIM`-capped wake list (`lanes.ex`), `MAXLEN ~`-capped streams (`stream.ex`). Dives: `listpack-and-intset` ·
  `short-field-names` · `capped-structures`.
- **R7.03 · Probabilistic data structures** — `probabilistic-data-structures` — ✓ built — trade accuracy for memory.
  Grounding: **contrast** with EchoMQ's exact dedup (`emq:{q}:de:<dedupId>`, `EchoMQ.Metrics.get_deduplication_job_id/3`).
  Dives: `hyperloglog` · `bloom-and-cuckoo` · `count-min-and-t-digest`.
- **R7.04 · Bitmaps** — `bitmap-patterns` — ✓ built — millions of boolean flags in minimal memory. Grounding: a
  standalone `SETBIT`/`BITCOUNT`/`BITOP` example + the branded-id placement as a bit offset
  (`placement("USR0KHTOWnGLuC") → 234878118`, door → `/bcs/overview`) + the forward-tense codemojex `cm-bitmapist`
  cohort spike (`infra/cm-bitmapist`). Dives: `1-bit-flags` · `bitcount-aggregates` · `daily-active-patterns`.
- **R7.05 · Vectors & similarity search** — `vector-sets` + `vector-search-ai` — ✓ built — Redis 8 native vector
  sets (HNSW) for semantic search. Grounding: a standalone Redis 8 Vector Sets example (`VADD`/`VSIM`); the **Valkey**
  engine reaches vectors via the `valkey-search` **module** (`FT.CREATE … VECTOR HNSW`, `FT.SEARCH … KNN`) — the
  core-vs-module honesty R7.03 drew for HLL vs Bloom; a forward-tense codemojex recommendation note (no vector
  surface ships, and — unlike R7.04 — no spike). Dives: `the-hnsw-graph` · `rag-and-recommendations` ·
  `filtered-queries`.
- **R7.06 · Geospatial** — `geospatial` — ✓ built — locations and radius queries on a geohash sorted set. Grounding:
  a standalone **core-Valkey** `GEOADD`/`GEOSEARCH` example — a GEO set is a sorted set (the geohash is the score) —
  + an honest-absence codemojex note (geo is orthogonal to the emoji game). Dives: `geoadd-and-geosearch` ·
  `radius-and-box-queries` · `the-geohash-sorted-set`.
- **R7.07 · Workshop** — `workshop` — ✓ built — codemojex's dashboard read-models, folding R7's patterns through real
  surfaces: the leaderboard (`Codemojex.Board` ZSET, `ZADD`/`ZREVRANGE cm:<game>:board`), the unique-players count (an
  **exact** `SCARD` SET — *not* HyperLogLog, the R7.03 road-not-taken), and the live game view (`Codemojex.View`
  projection, pushed by the room channel — *not* an `XADD` stream). The honest-subset thesis: a real consumer uses ~3
  of the 6 modeling patterns, chosen by its workload. Single-page capstone, no dives.

## R8 · Production & Operations — running the tier at scale · `/redis-patterns/production-operations` · → EchoMQ · ✓ built (landing + R8.01–R8.07)
> Operating the Redis/EchoMQ tier in production — the real-world case studies and the operational discipline; the
> capstone that hands off to the EchoMQ course. Grounding: the real `infra/valkey/conf/valkey.conf` (EchoMQ's production
> posture) + the source case studies. Doors → `/echomq` (the Proof pillar — the capstone) + `/bcs/fly` (B8, production on Fly).

- **R8.01 · Linux kernel tuning for Redis** — `kernel-tuning` — ✓ built — kernel settings that prevent latency spikes
  and persistence failures. Grounding: the real `infra/valkey/conf/valkey.conf` (EchoMQ's production posture) + the
  source case study. Dives: `huge-pages-overcommit` · `latency-spikes` · `persistence-safe-settings`.
- **R8.02 · Persistence, pooling & failover** — *applies `redis-as-primary-database`* — ✓ built (hub + 3 dives) —
  operating the bus as a record of truth in production. Grounding: the real `infra/valkey/conf/valkey.conf` persistence
  block (`appendonly yes` + `appendfsync everysec` + `save ""` + `propagation-error-behavior panic`), `EchoMQ.Pool`
  (N pipelined connectors hiding RTT over a single-threaded server), and `EchoMQ.Connector`'s capped-jittered-backoff
  reconnect (in-flight fail-not-replay; no literal `-READONLY` handler — failover is socket-drop → reconnect). Dives:
  RDB + AOF · pool sizing · READONLY-reconnect failover.
- **R8.03 · Pinterest: task queues & partitioning** — `pinterest-task-queue` — ✓ built (hub + 3 dives) — functional partitioning and
  list-based reliable queues at scale. Dives: functional partitioning · list-based reliable queues · 1 → 1000+ scaling.
- **R8.04 · Twitter/X: internals & custom structures** — `twitter-internals` — ✓ built (hub + 3 dives) — customizations that became Redis
  core. Dives: quicklist / memory · timeline fan-out · what became core.
- **R8.05 · Uber: resilience & staggered sharding** — `uber-resilience` — ✓ built (hub + 3 dives) — staggered sharding, circuit breakers,
  graceful degradation. Grounding: EchoMQ's READONLY-reconnect. Dives: staggered sharding · circuit breakers ·
  graceful degradation.
- **R8.06 · Operating EchoMQ** — ✓ built (hub + 3 dives) — the bridge to the dedicated EchoMQ course: pooling, cluster
  colocation, metrics and tracing in production. Grounding: `EchoMQ.Keyspace.slot/1` (CRC16-XMODEM over the `{q}` hashtag
  % 16384, `slot("123456789") == 12739`), `EchoMQ.Meter`'s `[:emq, …]` telemetry tree → Prometheus/OpenTelemetry +
  `EchoMQ.Dashboard`, and the branded-id conformance (one id canon across runtimes; the boot-asserted vectors). Dives:
  cluster colocation in prod · Prometheus / OpenTelemetry · the polyglot fleet.
- **R8.07 · Capstone — the door to the EchoMQ course** — ✓ built — the COURSE capstone: a single-page synthesis of the
  arc R0→R8 (the 30 patterns proven in the real BCS build) + the through-line (the branded id —
  typed·ordered·placed·conformant) + the door to the dedicated **EchoMQ, In Depth** course (the six built pillars:
  overview · protocol · queue · bus · cache · proof). Doors: `/echomq` + the pillars · `/bcs` · `/echo-persistence`. No dives.

---

## The door to the EchoMQ course

The chapters marked **→ EchoMQ** (R2, R3, R4, R5, R6, R8) each end by pointing at a separate, dedicated **EchoMQ
course** that teaches the polyglot protocol itself — the immutable L1/L2 layers, the 53 Lua scripts, the three
runtimes (`docs/echomq/`, `apps/echomq-go/`). That course is built next with the same toolkit, the parser pointed at
the EchoMQ corpus. redis-patterns teaches the patterns; the EchoMQ course teaches the system that applies them.

## Tally

9 chapters (R0 landing + R1–R8 spec chapters), ~46 teaching modules + 8 workshops, ~140 dives. Each of the 30
catalog patterns has a single **primary** module; a handful (`atomic-updates`, `delayed-queue`,
`lexicographic-sorted-sets`, `redis-as-primary-database`, `streams-event-sourcing`) recur as labelled *applied*
examples in later chapters, so they are taught once and reused in context. Primary placement: **Fundamental ×20**
across R1–R7, **Community ×6** (bitmap R7.04, geospatial R7.06, leaderboards R4.05, pubsub R5.03, session-management
R1.06, vector-search-ai R7.05), **Production ×4** in R8.

---

> Part of the jonnify toolkit. The TOC maps; the [roadmap](redis-patterns.roadmap.md) plans; the
> [chapter specs](specs/redis-patterns.md) define. Branded id format: `TSK` + Base62(snowflake), e.g.
> `TSK0KHTOWnGLuC`.
