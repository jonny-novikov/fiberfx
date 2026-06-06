# R8 · Production & Operations — running the tier at scale

> Operating the Redis/EchoMQ tier in production: kernel tuning, persistence and failover, and the real-world case
> studies — Pinterest, Twitter/X, Uber. The four Production catalog patterns plus the operational discipline,
> grounded in EchoMQ's production guide. The course capstone: it hands off to the dedicated EchoMQ course.

## Where this chapter starts and ends

- **Start** — R7's data modeling and the queue chapters before it. The reader knows the patterns but has not
  operated them under production load.
- **End** — the reader can tune the Linux host for Redis, configure persistence and connection pooling for
  failover, and apply the scaling lessons of Pinterest, Twitter/X, and Uber — and knows where the dedicated EchoMQ
  course continues with the polyglot protocol.

## The grounding (Redis Pattern Applied)

Grounded in **EchoMQ's production guide (ch29–31)** and the source case studies: `noeviction` plus RDB/AOF make the
queue durable; connection pooling with READONLY-reconnect handles failover (the Uber-resilience lesson, applied);
metrics and tracing observe the tier; and the case studies map onto operating EchoMQ at scale — Pinterest's
list-based reliable queues and functional partitioning, Twitter/X's custom structures that became Redis core, and
Uber's staggered sharding and circuit breakers.

## The module ladder

| Module | Pattern | What it adds | Grounding | Dives |
| --- | --- | --- | --- | --- |
| R8.01 kernel-tuning | `kernel-tuning` | host settings that prevent latency spikes and persistence failures | the source production case study | THP / overcommit · latency spikes · persistence-safe settings |
| R8.02 persistence-ops | *applies R7.01 `redis-as-primary-database`* | persistence, pooling, and failover in production | EchoMQ production guide (ch31) | RDB + AOF · pool sizing · READONLY-reconnect failover |
| R8.03 pinterest | `pinterest-task-queue` | functional partitioning and list-based reliable queues at scale | the source case study | functional partitioning · list-based reliable queues · 1 → 1000+ scaling |
| R8.04 twitter | `twitter-internals` | customizations that became Redis core | the source case study | quicklist / memory · timeline fan-out · what became core |
| R8.05 uber | `uber-resilience` | staggered sharding, circuit breakers, graceful degradation | the source case study; EchoMQ READONLY-reconnect | staggered sharding · circuit breakers · graceful degradation |
| R8.06 operating-echomq | technique — the bridge | pooling, cluster colocation, metrics and tracing in production | EchoMQ ch29–31 | cluster colocation in prod · Prometheus / OpenTelemetry · the polyglot fleet |
| R8.07 Capstone | — | the door to the EchoMQ course | the polyglot protocol, the Lua inventory, the three runtimes | — |

## The door to the EchoMQ course

→ EchoMQ (the capstone door). R8.06 and R8.07 are the bridge: having operated the Redis tier, the reader is ready
for the dedicated **EchoMQ course**, which teaches the polyglot protocol itself — the immutable L1/L2 layers, the
53-script Lua inventory, and the Elixir/Go/Node runtimes (`docs/echomq/`, `apps/echomq-go/`). That course is built
next with the same toolkit, the parser pointed at the EchoMQ corpus.

## Conventions

Pages follow the two mandatory layout rules, pass the ten gates including `refs`, and honour voice and no-invent:
cite the real EchoMQ production setting or the source case study. R8.02 applies R7.01's `redis-as-primary-database`
to operations rather than introducing a new catalog pattern; R8.06 is the bridge technique, not a catalog pattern.
See [`../redis-patterns.md`](../redis-patterns.md).

Index: [`../redis-patterns.md`](../redis-patterns.md) · TOC: [`../../redis-patterns.toc.md`](../../redis-patterns.toc.md) · Roadmap: [`../../redis-patterns.roadmap.md`](../../redis-patterns.roadmap.md)
