# R6 · Flow Control & Scale — staying stable under load

> Keeping the system stable under load: rate limiting, priority fairness, multi-tenant groups, batched enqueue, and
> worker concurrency. One new catalog pattern (`rate-limiting`) plus four flow-control techniques that compose
> patterns from earlier chapters, grounded in EchoMQ's limiter, groups, and bulk add. Depends on R3/R4.

## Where this chapter starts and ends

- **Start** — R3's queue and R4's priority/scheduling. The reader can run and order a queue but has not yet bounded
  its throughput, kept tenants fair, or enqueued in bulk.
- **End** — the reader can rate-limit work globally at the dequeue point, prevent priority starvation, share
  capacity fairly across tenants, enqueue thousands of jobs in one round trip, and reason about the Redis-fetch
  ceiling on worker concurrency. The workshop rate-limits and fairly schedules Portal's API and jobs.

## The grounding (Redis Pattern Applied)

Grounded in **EchoMQ's flow-control layer**: the limiter `bull:{queue}:limiter` is `INCR`/`PEXPIRE`d inside
`MoveToActive`, so the limit is **global across every worker and runtime** (a job over budget is sent back to wait,
surfaced as `RateLimitedError`); groups distribute work round-robin across tenant ids (with per-group concurrency
and limit keys); `addBulk` writes many jobs in one `MULTI/EXEC`; and the per-job `RPOP`/`ZPOPMIN` fetch is the
throughput ceiling that worker concurrency must plan around.

## The module ladder

| Module | Pattern | What it adds | Grounding | Dives |
| --- | --- | --- | --- | --- |
| R6.01 rate-limiting | `rate-limiting` | bound throughput at the dequeue point | `:limiter` `INCR`/`PEXPIRE` in `MoveToActive` | fixed/sliding window · token/leaky bucket · global vs local (the Go gap) |
| R6.02 priority-fairness | fairness — *extends R4.03 `lexicographic-sorted-sets`* | prevent priority starvation under load | the priority ZSET under load | priority starvation · aging / reserved capacity · priorities vs separate queues |
| R6.03 groups | fairness / round-robin — *composes `distributed-locking` + `rate-limiting`* | share capacity fairly across tenants | EchoMQ groups (and the workaround keys) | round-robin across tenants · per-group concurrency/limit · group vs separate-queue |
| R6.04 batches | *applies R2.01 `atomic-updates`* | one round-trip, all-or-nothing bulk enqueue | `addBulk` `MULTI/EXEC` | round-trip elimination · chunking across a pool · partial-failure handling |
| R6.05 worker-concurrency | technique — the Redis-fetch ceiling | plan capacity against the per-job fetch cost | EchoMQ concurrency models | parallel vs concurrent · the per-job-fetch bottleneck · capacity planning |
| R6.06 Workshop | — | rate-limit and fairly schedule Portal's API + jobs | the limiter + groups over Portal traffic | — |

## The door to the EchoMQ course

→ EchoMQ. The scaling subsystem — BullMQ Pro groups, the per-runtime concurrency primitives, batches, and the
benchmark envelope — belongs to the dedicated EchoMQ course. This chapter teaches rate limiting as a catalog pattern
and the flow-control techniques around it; that course teaches EchoMQ's scaling layer.

## Conventions

Pages follow the two mandatory layout rules, pass the ten gates including `refs`, and honour voice and no-invent:
cite the real EchoMQ key, command, or function from the grounding map. Only `rate-limiting` (R6.01) is a fresh
catalog pattern here; R6.02–R6.05 are flow-control techniques that extend or compose patterns from R2/R4, named as
such so each of the 30 catalog patterns keeps a single primary module. See [`../redis-patterns.md`](../redis-patterns.md).

Index: [`../redis-patterns.md`](../redis-patterns.md) · TOC: [`../../redis-patterns.toc.md`](../../redis-patterns.toc.md) · Roadmap: [`../../redis-patterns.roadmap.md`](../../redis-patterns.roadmap.md)
