# R3 · Reliable Queues — wait, active, done, recover

> The heart of the EchoMQ grounding: "reliable-queue" is not one pattern but a family — the processing list,
> at-least-once delivery, stalled recovery, the atomic state machine, and blocking pickup. This is the densest real
> grounding in the course, drawn straight from EchoMQ's worker path. Depends on R2's atomic moves and lock lease.

## Where this chapter starts and ends

- **Start** — R2's atomic updates and lock lease. The reader can make a multi-key change race-free but has not yet
  built a queue that survives a worker crash.
- **End** — the reader can build a queue where a job is never lost: moved into an in-flight list under a lock,
  delivered at least once to an idempotent consumer, reclaimed if its worker dies, transitioned atomically, and
  picked up without busy-polling. The workshop builds a reliable Portal enrollment-job queue.

## The grounding (Redis Pattern Applied)

Grounded in **EchoMQ's worker fetch loop**: `MoveToActive` performs `rcall("RPOPLPUSH", waitKey, activeKey)` so a
job is parked in `bull:{queue}:active` under a lock and survives a crash; `moveStalledJobsToWait` reclaims jobs
whose lock has expired (shown in both the atomic Lua form and the non-atomic Go form, the cautionary contrast);
`moveToFinished-14` completes the lifecycle in one ~1100-line script; and `BZPOPMIN` on `bull:{queue}:marker` wakes
a blocked worker instead of polling. All real in `apps/echomq-go/pkg/echomq/`.

## The module ladder

| Module | Pattern | What it adds | Grounding | Dives |
| --- | --- | --- | --- | --- |
| R3.01 processing-list | `reliable-queue` | move a job *into* an in-flight list so a crash is recoverable | `MoveToActive` `RPOPLPUSH wait→active` | LIST wait/active · LMOVE/RPOPLPUSH · the in-flight list |
| R3.02 at-least-once | `reliable-queue` | delivery guarantees; why consumers must be idempotent | EchoMQ custom IDs + `de:{id}` dedup | at-least-once semantics · idempotent consumers · why exactly-once is a lie |
| R3.03 stalled-recovery | `reliable-queue` | reclaim jobs whose worker died | `moveStalledJobsToWait` (atomic Lua vs non-atomic Go) | lock-expiry detection · two-phase mark/recover · atomic vs non-atomic |
| R3.04 atomic-state-machine | `atomic-updates` | the whole lifecycle as one Lua transition | `moveToFinished-14` (14 keys) | states as Redis locations · read-decide-write in one EVALSHA · EVALSHA + NOSCRIPT |
| R3.05 blocking-vs-polling | `reliable-queue` | stop busy-polling the queue | `:marker` + `BZPOPMIN` (vs the Go ticker) | the busy-poll cost · blocking pop · the marker wake-up |
| R3.06 Workshop | — | a reliable Portal enrollment-job queue | the wait/active/lock/stalled path over enrollment jobs | — |

## The door to the EchoMQ course

→ EchoMQ. The full worker fetch loop — the 11-key `moveToActive` include graph, the heartbeat manager, the
stalled-check coordination across a worker pool, and the polyglot concurrency models (BEAM process pool vs goroutine
semaphore) — belongs to the dedicated EchoMQ course. This chapter teaches the reliable-queue patterns; that course
teaches the engine that runs them.

## Conventions

Pages follow the two mandatory layout rules, pass the ten gates including `refs`, and honour voice and no-invent:
cite the real EchoMQ key, command, Lua script, or Go function from the grounding map, never an invented one. The Go
non-atomic stalled path is taught as the cautionary contrast to the atomic Lua, not as the recommended form. See
[`../redis-patterns.md`](../redis-patterns.md).

Index: [`../redis-patterns.md`](../redis-patterns.md) · TOC: [`../../redis-patterns.toc.md`](../../redis-patterns.toc.md) · Roadmap: [`../../redis-patterns.roadmap.md`](../../redis-patterns.roadmap.md)
