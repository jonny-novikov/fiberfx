# R3 · The road ahead

> Route: `/redis-patterns/queues/the-road-ahead` · R3 · Reliable Queues · dive 3 (orientation)

The reliable queue is the spine of everything that follows. Each later chapter adds one
capability on top of it, and on the far side of the patterns waits the system that applies
them: the living EchoMQ course. This dive surveys the arc R3→R8 and opens that door.

This is an orientation dive. It has no single Redis-pattern source. It is grounded in the
real course arc (the [redis-patterns TOC](../../redis-patterns.toc.md)) and the real EchoMQ
cross-link map.

## Where the queue goes next — the arc R3→R8

R3 builds a queue that is correct under a crash: a job moves from `wait` to `active` to
`completed`, and a worker that dies leaves its job recoverable. That correct queue is the
floor. Every chapter after it adds exactly one capability on top, and each capability is one
more Redis structure used in one more way.

- **R4 · Time, Delay & Priority** (`/redis-patterns/time-delay-priority`) — the sorted set as
  a clock. Delayed jobs are scored by fire-time in a ZSET and swept by score; priority packs a
  tier and an arrival counter into one composite score. The queue learns *when* and *in what
  order*.
- **R5 · Streams & Events** (`/redis-patterns/streams-events`) — the durable log. The
  `emq:{queue}:events` STREAM records every lifecycle transition; consumer groups read it
  without losing their place; event sourcing rebuilds state from the log. The queue learns to
  *remember and replay*.
- **R6 · Flow Control & Scale** (`/redis-patterns/flow-control`) — staying stable under load.
  Rate limiters, worker concurrency, fair groups across tenants, and bulk batches keep the
  tier from tipping over when demand spikes. The queue learns *restraint*.
- **R7 · Data Modeling & Memory** (`/redis-patterns/data-modeling`) — how data lives in RAM.
  Compact encodings, short field names, capped structures, and the probabilistic structures
  that trade accuracy for memory. The queue learns to *spend memory well*.
- **R8 · Production & Operations** (`/redis-patterns/production-operations`) — running the tier
  at scale. Persistence, pooling, failover, and the Pinterest, Twitter, and Uber case studies,
  closing on the capstone door. The queue learns to *survive production*.

The reliable queue is the constant. Read the arc as one queue gaining one sense at a time:
a clock, a memory, restraint, frugality, endurance.

## The door beyond — the living EchoMQ course

Having learned the patterns, the reader is ready for the system that applies them. The
dedicated **EchoMQ course** (`/echomq`) teaches the polyglot job-queue protocol in depth. It
is a *living, agile-spec course*, built in two movements.

- **Movement I (E1–E2)** teaches the as-built core library: the immutable wire protocol and
  data layer (E1), then the lifecycle, components, and three runtimes (E2).
- **Movement II (E3–E8)** is a living spine that tracks the EMQ extension ladder
  (`emq.1`–`emq.6`) rung by rung. Each page stands on the triangle — the redis-patterns
  pattern, the `emq.N` implementation spec, and the as-built code — and teaches from the spec
  while the rung is drafted.

Per the cross-link map, every `→ EchoMQ` door in this course opens precisely: **R0.3→E1 ·
R2→E1/E3 · R3→E2/E5/E6 · R4/R5→E6/E7 · R6→E4/E5 · R8→E8**. R3, this chapter, opens onto three
EchoMQ chapters:

- **E2 · The lifecycle, components & runtimes** (`/echomq/core`) — the engine that runs the
  reliable queue: the eight-state machine, the worker fetch loop, lock management, and the
  three runtimes.
- **E5 · Batches** (`/echomq/batches`) — bulk consumption: up to N jobs per processor
  invocation, shaped by size and timeout, with a partitioned per-job completion contract.
- **E6 · Lifecycle controls** (`/echomq/lifecycle`) — declarative TTL, distributed cancel by
  job id, and crash-survivable checkpoints that let a retry resume mid-pipeline.

A note on honesty. The EchoMQ course is designed — its spec system and TOC are authored — and
the EMQ ladder is drafted (the `emq.1`–`emq.6` specs exist). The served `/echomq` pages ship as
the build lands. It is the living companion course, not a course "built next" all at once.

## The bridge

**The patterns.** R0–R8 teach the Redis techniques applied. Each pattern lands twice — the
technique and its trade-offs, then the one real EchoMQ excerpt that proves it. The course is a
catalog of judgement, grounded.

→

**The system.** The living EchoMQ course teaches the whole protocol in depth and tracks the
EMQ build, E1–E8 standing on emq.1–emq.6. Where this course cites one excerpt as proof, that
course teaches the system that applies it.

**Take:** the patterns are the vocabulary; EchoMQ is the language. Learn the patterns here,
then go build with them there.

## A door, not a depth

This page names the door and steps through it. The deeper protocol — the full Lua inventory,
the three runtime implementations, the governance that keeps the wire frozen — is the subject
of the dedicated EchoMQ course, not of this one.

- The EchoMQ course home: [`/echomq`](/echomq).
- R3's specific doors: [E2 · The lifecycle, components & runtimes](/echomq/core),
  [E5 · Batches](/echomq/batches), [E6 · Lifecycle controls](/echomq/lifecycle).

Start building with [`/echomq`](/echomq).

## References

### Sources

- [Redis — *Streams*](https://redis.io/docs/latest/develop/data-types/streams/) — the durable,
  replayable log R5 teaches on top of the reliable queue: `XADD`, consumer groups, `MAXLEN ~`.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the
  ZSET as a clock and a priority ladder, the structure R4 turns into delay and priority.
- [BullMQ](https://bullmq.io/) — the queue protocol the whole arc builds on and that EchoMQ
  ports across three runtimes.
- [llms.txt — *The /llms.txt convention*](https://llmstxt.org/) — the machine-readable map
  format both this course and the EchoMQ course publish for agents.

### Related in this course

- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter this dive closes.
- [R3 · States as locations](/redis-patterns/queues/states-as-locations) — dive 2: the
  lifecycle as one atomic Lua move, the foundation the later chapters build on.
- [R0.3 · The door to EchoMQ](/redis-patterns/overview/patterns-become-protocol/the-door-to-echomq)
  — the course's first EchoMQ door: the cross-runtime contract.
- [R0.2 · Redis under Portal](/redis-patterns/overview/redis-under-portal) — where Redis sits
  in Portal and the reserved multi-runtime tier the queue patterns fill.
