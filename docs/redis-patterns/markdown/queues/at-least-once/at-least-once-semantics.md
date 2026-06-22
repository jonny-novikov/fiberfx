# At-least-once semantics — one or more times, never zero

> Route: `/redis-patterns/queues/at-least-once/at-least-once-semantics` · Dive R3.02.1 · Module R3.02 At-least-once.
> · Grounding: the move-under-lock from R3.01 — `LMOVE` / `RPOPLPUSH` into the in-flight list, held under a lock
> until acknowledged — yields at-least-once because the job stays until the worker confirms it. EchoMQ's worker path
> in `echo/apps/echomq` is the real form: `moveToActive-11.lua` parks the job in `emq:{queue}:active` under a lock,
> and `moveStalledJobsToWait-8.lua` returns a job whose lock expired to `wait`. Source roots: Recovery from Failures,
> Delivery Guarantees.

Three delivery guarantees bound every queue design: at-most-once, at-least-once, and exactly-once. A reliable queue
sits on the second, and not by accident — keeping a job until its acknowledgement is the only choice that loses no
job, and that same choice is what allows a job to run more than once.

## The three guarantees

The spectrum is set by one decision: when does the job leave the queue, before the work or after the acknowledgement.

**At-most-once.** The job is removed before the work runs — `RPOP` and process. A crash mid-job loses the job: zero
deliveries. The guarantee is that a job is delivered no more than once; the price is that it can be delivered zero
times. Acceptable only when a dropped job is harmless.

**At-least-once.** The job is held until the acknowledgement — moved into an in-flight list and only removed after
the work confirms. A crash mid-job redelivers the job: one delivery or more. The guarantee is that a job is delivered
at least once; the price is that it can be delivered twice. This is the reliable queue.

**Exactly-once.** One delivery and exactly one. This is what everyone wants and it is not achievable as a *delivery*
guarantee, because the acknowledgement itself can be lost — the third dive in this module is that argument. What is
buildable is an exactly-once *effect*, by making the consumer idempotent on top of at-least-once delivery.

A reliable queue must keep the job until it is acknowledged, so it lands on at-least-once. That is the only point on
the spectrum that never drops a job.

## Why the move-under-lock yields at-least-once

R3.01 moved a job *into* an in-flight list under a lock instead of popping it out. `LMOVE work active RIGHT LEFT`
(or the older `RPOPLPUSH`) makes the move atomic: the job is in exactly one of the two lists at every instant, never
in neither. The lock has a TTL; a healthy worker renews it on a heartbeat. When a worker crashes, the heartbeat
stops, the lock expires, and a recovery sweep finds the job still parked in-flight and returns it to the main queue.

The recovery path is what makes the queue reliable, and it is precisely why a job can run twice. A job in-flight is
never lost — that is the win. But a job in-flight whose lock expired is redelivered — that is the cost. The two are
the same mechanism viewed from two angles. You cannot keep the recovery and remove the redelivery, because removing
the recovery is exactly what loses the job.

```
# at-most-once: the job leaves before the work — a crash loses it
job = RPOP work             # job is out of Redis
process(job)                # crash here → job gone, zero deliveries

# at-least-once: the job is held until the acknowledgement — a crash redelivers it
job = LMOVE work active RIGHT LEFT   # atomic: held in `active` under a lock
process(job)                         # crash here → job stays in `active`, recoverable
LREM active 1 job                    # acknowledge: remove only after the work confirms
```

## The duplicate window

The duplicate is not a rare corner; it has a precise window. A worker takes a job into the in-flight list under a
lock. It applies the effect — charges the card, writes the row. Then it crashes *after the effect but before the
acknowledgement* (`LREM`). The effect is done; Redis does not know it. The lock expires. The recovery sweep finds a
job in-flight with an expired lock and returns it to the main queue. A second worker runs it again. The card is
charged twice.

This window is irreducible. No reordering closes it: if the acknowledgement comes first, the job leaves the in-flight
list before the work, and a crash now loses it (back to at-most-once). The acknowledgement has to come after the
work, which means there is always a moment where the work is done and the acknowledgement is not. A crash in that
moment redelivers. The window is small, but it is never zero — and over enough jobs, a never-zero probability fires.

The conclusion is forced: a reliable queue is at-least-once, the duplicate is structural, and the only place to
absorb it is the consumer. The next dive makes the consumer idempotent.

## The pattern, applied

EchoMQ's worker path is at-least-once in real code, in `echo/apps/echomq`. `moveToActive-11.lua` parks a job in
`emq:{queue}:active` under a lock — its body runs `rcall("RPOPLPUSH", waitKey, activeKey)`, where `waitKey` is
`emq:{queue}:wait` and `activeKey` is `emq:{queue}:active` (`EchoMQ.Keys.wait/1` and `EchoMQ.Keys.active/1`). The
job is held in `active` until the worker acknowledges it; a crash leaves it there, recoverable.
`moveStalledJobsToWait-8.lua` is the recovery sweep: for each job in `active` whose lock has expired it returns the
job to `wait` for another worker — and that return is the redelivery. Held-until-acknowledged plus
recover-on-expired-lock is exactly at-least-once: never lost, possibly twice.

```elixir
# the in-flight list and the recovery target — real EchoMQ keys
def wait(ctx),   do: "#{base(ctx)}:wait"     # emq:my_queue:wait — the main queue
def active(ctx), do: "#{base(ctx)}:active"   # emq:my_queue:active — held under a lock until acknowledged
```

**The bridge.** The pattern says hold the job until the acknowledgement and recover a crashed job, which is
at-least-once: never lost, possibly twice. In EchoMQ `moveToActive-11.lua` holds the job in `emq:{queue}:active`
under a lock and `moveStalledJobsToWait-8.lua` returns an expired-lock job to `emq:{queue}:wait` — the redelivery
that makes the guarantee at-least-once rather than exactly-once.

The full worker fetch loop — the heartbeat manager that renews the lock, the stalled-check coordination across a
worker pool, the polyglot concurrency models — is the dedicated EchoMQ course. This dive teaches the at-least-once
guarantee; that course teaches the engine that ships it.

## References

### Sources
- [Redis — RPOPLPUSH](https://redis.io/commands/rpoplpush/) — the original atomic move into the in-flight list,
  held until acknowledged: the heart of at-least-once.
- [Redis — LMOVE](https://redis.io/commands/lmove/) — the modern successor (Redis 6.2+) with explicit
  `RIGHT`/`LEFT` directions.
- [Redis — Redis queue](https://redis.io/glossary/redis-queue/) — the queue and its delivery-guarantee overview.
- [BullMQ — the queue protocol](https://bullmq.io/) — the wait/active/stalled worker path EchoMQ ports.

### Related in this course
- [R3.02 · At-least-once](/redis-patterns/queues/at-least-once) — the module hub.
- [R3.02.2 · Idempotent consumers](/redis-patterns/queues/at-least-once/idempotent-consumers) — the next dive: absorb
  the duplicate at the consumer.
- [R3.02.3 · Why exactly-once is a lie](/redis-patterns/queues/at-least-once/why-exactly-once-is-a-lie) — why no
  protocol closes the window.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the move-under-lock that yields
  at-least-once.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic move under the in-flight list.
- [E2 · The EchoMQ core](/echomq/core) — the worker fetch loop, in depth.
