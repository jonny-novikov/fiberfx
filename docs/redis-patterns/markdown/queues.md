# R3 · Reliable Queues — wait, active, done, recover

> Route: `/redis-patterns/queues` (chapter landing) · Source of structure: the chapter spec
> `specs/queues/queues.md` + the TOC · Grounding: EchoMQ's worker fetch loop in the iconic Elixir app
> `echo/apps/echomq` (the Go port `apps/echomq-go` is the labelled contrast). The course's pivot chapter — the heart
> of the EchoMQ grounding.

The pivot of the course: a job is never lost. A reliable queue is not one pattern but a family — a job is moved into
an in-flight list under a lock, delivered at least once to an idempotent consumer, reclaimed if its worker dies,
transitioned atomically, and picked up without busy-polling. This is the densest real grounding in the course, drawn
straight from EchoMQ's worker path. It depends on R2's atomic moves and lock lease.

## Overview

A naive queue is a list: push on one end, pop on the other. It loses jobs. The moment a worker pops a job and then
crashes — before the work is done, before it is acknowledged — that job is gone from Redis and gone from memory.
Nothing reclaims it. The reliable-queue family is the set of techniques that close every one of those gaps: where
the job sits while in flight, how a duplicate delivery is made harmless, how a dead worker's job comes back, how the
whole lifecycle moves without tearing, and how a worker waits for work without burning CPU.

EchoMQ implements every one of these in real code. Its worker fetch loop is the worked example for the whole
chapter: `moveToActive-11.lua` parks a job in `emq:{queue}:active` with `RPOPLPUSH`; `EchoMQ.Keys.dedup/2` writes
the `de:{id}` marker that makes a second delivery idempotent; `moveStalledJobsToWait-8.lua` reclaims a job whose lock
expired; `moveToFinished-14.lua` is the whole lifecycle transition in one EVALSHA; and `EchoMQ.Keys.marker/1` with
`BZPOPMIN` wakes a blocked worker instead of polling.

## Why & when

Use the reliable-queue family whenever losing a job is not acceptable and a worker can crash at any instant — which
is every real background-job system. Each failure mode below has one matching technique:

- **A worker crashes mid-job** — the job must not vanish when a worker dies → move it into an in-flight list under a
  lock (`RPOPLPUSH wait→active`, `moveToActive-11.lua`), and reclaim it when the lock expires
  (`moveStalledJobsToWait-8.lua`).
- **A job runs twice** — at-least-once delivery means a job can be delivered more than once → make the consumer
  idempotent and mark completion (`emq:{queue}:de:{id}` via `EchoMQ.Keys.dedup/2`).
- **A multi-step transition tears** — a job's lifecycle move touches many keys and must be all-or-nothing → run the
  whole transition as one Lua script (`moveToFinished-14.lua`, one 14-key EVALSHA).
- **The worker busy-polls the queue** — a worker that loops on the queue burns CPU and adds latency → block on a
  marker (`emq:{queue}:marker` + `BZPOPMIN`) and let Redis wake it.

## The patterns

Three deep dives carry the chapter's built content; a granular module ladder builds each pattern in depth.

| Module | Pattern | Grounding |
| --- | --- | --- |
| The reliable queue | `reliable-queue` | `RPOPLPUSH wait→active` (`moveToActive-11.lua`) + `de:{id}` idempotency + `moveStalledJobsToWait-8.lua` |
| States as locations | `atomic-updates` | the lifecycle as one EVALSHA (`moveToFinished-14.lua`); `:marker` + `BZPOPMIN` replaces busy-polling |
| The road ahead | — | the arc R3→R8 and the door into the living EchoMQ course |

The granular module ladder, in progress: R3.01 processing-list · R3.02 at-least-once · R3.03 stalled-recovery ·
R3.04 atomic-state-machine · R3.05 blocking-vs-polling · R3.06 workshop — the modules that build each pattern in
depth.

## How to apply

Name the failure you cannot allow, and the reliable-queue technique follows:

- **A worker crashes mid-job** → the in-flight list: `RPOPLPUSH wait→active` (`moveToActive-11.lua`) parks the job
  under a lock so a crash is recoverable; stalled reclaim (`moveStalledJobsToWait-8.lua`) brings it back when the
  lock expires.
- **A job runs twice** → at-least-once with an idempotent consumer: `emq:{queue}:de:{id}` via `EchoMQ.Keys.dedup/2`
  makes a second delivery a no-op.
- **A multi-step transition tears** → the whole lifecycle as one EVALSHA: `moveToFinished-14.lua` moves the job
  across 14 keys atomically.
- **The worker busy-polls the queue** → blocking pickup: `BZPOPMIN` on `emq:{queue}:marker` (`EchoMQ.Keys.marker/1`)
  parks the worker on a dedicated blocking connection until a job arrives.

## The road ahead

R3 is the spine the rest of the course hangs from. Each later chapter is a different surface over the same reliable
queue:

- **R4 · Time, Delay & Priority** — the sorted set as a clock: schedule and prioritize the jobs R3 makes reliable.
- **R5 · Streams & Events** — the durable log: observe the lifecycle R3 defines, replayable after the fact.
- **R6 · Flow Control** — staying stable under load: rate-limit, batch, and bound concurrency over R3's jobs.
- **R7 · Data Modeling** — how data lives in RAM: the job record and read-models behind the queue.
- **R8 · Production & Operations** — running the tier at scale: operate everything above in production.

## The door

**→ EchoMQ.** R3's depth — the full worker fetch loop, the heartbeat manager, the stalled-check coordination across
a worker pool, and the polyglot concurrency models (BEAM process pool vs goroutine semaphore) — is the dedicated
**EchoMQ course**, a living companion that teaches the protocol in depth and tracks the EchoMQ build rung by rung.
Per its cross-link map, R3 opens onto E2 (the as-built library and the worker fetch loop), E5 (batches), and E6
(lifecycle controls).

## References

### Sources
- [Redis — RPOPLPUSH](https://redis.io/commands/rpoplpush/) — the atomic move that parks a job in the in-flight list.
- [Redis — BZPOPMIN](https://redis.io/commands/bzpopmin/) — the blocking pop that wakes a worker instead of polling.
- [Redis — Scripting with Lua](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) — the atomic lifecycle transition via EVAL / EVALSHA.
- [BullMQ](https://bullmq.io/) — the reliable-queue protocol EchoMQ ports.

### Related in this course
- [R2 · Coordination](/redis-patterns/coordination) — the atomic moves and lock lease R3 builds on.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — every state move as one Lua script.
- [R0.2 · Redis under Portal](/redis-patterns/overview/redis-under-portal) — the EchoMQ bus these patterns ground in.
- [/elixir · Commands, queries & events](/elixir/pragmatic/cqrs) — the engine the atomic moves run inside.
