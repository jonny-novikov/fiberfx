# Redis Patterns, Applied

> Route: `/redis-patterns` (course home — the map) · The full chapter→module directory · Grounding: the BCS build
> (EchoMQ backed by Valkey, EchoCache in front) — real keys, commands, and atomic Lua scripts quoted verbatim
> from committed records. Reframed under [`specs/reframe-echomq/`](../specs/reframe-echomq/reframe-echomq.md).

The judgement layer above the command reference — every pattern shown working in a real system. Thirty Redis
design patterns, taught as problem → solution → trade-off → when-to-use, then shown where the **BCS architecture**
applies them: **EchoMQ** backed by **Valkey**, Valkey under the hood, **EchoCache** in front. Nine chapters; each
closes by building one slice of the BCS Redis tier.

## How to read this

Each chapter teaches a family of Redis patterns. A pattern is a single unit: the problem it solves, the Valkey
structures and commands that solve it, the trade-off it accepts, and the workload it fits. The claim of the
course is that knowing the commands is not enough — the same engineer reaches for a single-node "distributed
lock" a failover silently breaks, or a fixed-window rate limiter with a boundary burst. The fix is **grounding**:
every pattern is shown applied in a real system, so the worked example is verifiable.

The running system is the **BCS build**. **EchoMQ** is the bus between systems, and it owns its protocol: the
braced `emq:{q}:` keyspace, every Lua key declared or root-derived, the wire version `echomq:2.0.0` behind a
two-way typed boot fence — **backed by Valkey** (the current stable line, an enforced conformance gate). The
atomic Lua scripts *are* the protocol — a corpus of Redis patterns made owned, declared code. **EchoCache** is
the near-cache in front: branded keys, an L1 of ETS tables over the shared L2 Valkey, coherence by mint time.
The worked consumer of both is the **Exchange Platform** — the trading system these patterns are applied inside
(`echo/apps/exchange`). Where a chapter's deeper implementation belongs to the protocol itself, it doors forward
to the dedicated [EchoMQ course](/echomq).

A scope note: the engine is **Valkey** — the current stable line, the substrate the EchoMQ connector is gated
against. Where a pattern depends on a specific command, the lesson names it.

## The map

The full course, chapter by chapter. The patterns are sequenced along the EchoMQ build — coordination, then
queues, then time, streams, flow, and operations — so the catalog doubles as a guided build of the BCS Redis
tier. The workshop module closes each chapter. ([R0 · Overview](/redis-patterns/overview) sets up the grounding
first.)

### [R1 · Caching](/redis-patterns/caching)
The read path: serving reads fast and keeping the cache consistent on writes.
- R1.01 Cache-aside (lazy loading) · R1.02 Write-through · R1.03 Write-behind · R1.04 Server-assisted client-side caching · R1.05 Cache stampede prevention · R1.06 Session management · R1.07 Workshop — cache the BCS catalog tier end to end.

### [R2 · Coordination & Consistency](/redis-patterns/coordination) → EchoMQ
Atomicity first — the foundation every later chapter builds on.
- R2.01 Atomic updates · R2.02 Distributed locking · R2.03 The Redlock algorithm (contrast) · R2.04 Cross-shard consistency · R2.05 Hash-tag co-location · R2.06 Workshop — make enrollment atomic across runtimes.

### [R3 · Reliable Queues](/redis-patterns/queues) → EchoMQ
Wait, active, done, recover — the heart of EchoMQ, the densest grounding in the course.
- R3.01 The processing list · R3.02 At-least-once & idempotency · R3.03 Stalled-job recovery · R3.04 The atomic state machine · R3.05 Blocking vs polling · R3.06 Workshop — a reliable enrollment-job queue.

### [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) → EchoMQ
The sorted set as a clock — a timer wheel and a priority ladder.
- R4.01 The delayed queue · R4.02 Schedulers & repeatable jobs · R4.03 Priority with composite scores · R4.04 Backoff & retry · R4.05 Leaderboards · R4.06 Workshop — schedule the notification and digest jobs.

### [R5 · Streams & Events](/redis-patterns/streams-events) → EchoMQ
The durable log — observability and event-driven coordination.
- R5.01 Event sourcing on Streams · R5.02 Stream consumer patterns · R5.03 Pub/Sub vs Streams · R5.04 Custom events & projections · R5.05 Workshop — a live activity feed.

### [R6 · Flow Control & Scale](/redis-patterns/flow-control) → EchoMQ
Staying stable under load — limiting, fairness, batching, concurrency.
- R6.01 Rate limiting · R6.02 Priorities & fairness · R6.03 Groups & multi-tenant fairness · R6.04 Batches & pipelining · R6.05 Worker concurrency · R6.06 Workshop — rate-limit and fairly schedule the API and jobs.

### [R7 · Data Modeling & Memory](/redis-patterns/data-modeling)
How data lives in RAM — the modeling family and the BCS read-models.
- R7.01 Redis as a primary database · R7.02 Memory optimization · R7.03 Probabilistic data structures (contrast) · R7.04 Bitmaps · R7.05 Vectors & similarity search · R7.06 Geospatial · R7.07 Workshop — the dashboard read-models.

### [R8 · Production & Operations](/redis-patterns/production-operations) → EchoMQ
Running the tier at scale — case studies and operational discipline; the capstone.
- R8.01 Linux kernel tuning · R8.02 Persistence, pooling & failover · R8.03 Pinterest: task queues & partitioning · R8.04 Twitter/X: internals & custom structures · R8.05 Uber: resilience & staggered sharding · R8.06 Operating EchoMQ · R8.07 Capstone — the door to EchoMQ.

## The evidence ethic

Every claim is backed by a committed record. The connector gate, against live Valkey: `fence claimed
echomq:2.0.0`, sequential INCR `29456 ops/s`, pipelined SET `454483 ops/s`, pipelined EVALSHA `161192 ops/s`,
`script_loads 1`, `PASS 8/8` (`docs/echo/bcs/content/bcsA.md`).

## The doors

- **/echomq** — the EchoMQ protocol in depth: the `emq:{q}:` keyspace, the Lua inventory, conformance on Valkey.
- **/bcs** — the Branded Component System: the architecture EchoMQ and EchoCache are built inside.
- **/elixir** — the functional-Elixir and OTP craft behind the echo umbrella — where EchoMQ, EchoCache, and the Exchange Platform are built.

## References

### Sources
- [Redis — Documentation](https://redis.io/docs/) — the command reference and data-type guides the patterns draw on.
- [Valkey — Topics](https://valkey.io/topics/) — the engine the EchoMQ connector is gated against.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — EVALSHA, atomic scripts, the declared-keys discipline.
- [llmstxt.org — The llms.txt convention](https://llmstxt.org/) — the machine-readable map format the course follows.

### Related in this course
- [R0 · Overview](/redis-patterns/overview) — where Valkey sits in the BCS build, and the reading protocol.
- [R1 · Caching](/redis-patterns/caching) — the read path, the first chapter.
- [/echomq](/echomq) — the EchoMQ course, the far side of the door.
- [/bcs](/bcs) — the Branded Component System, the architecture these patterns run inside.
