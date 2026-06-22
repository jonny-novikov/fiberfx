# Stalled recovery — reclaim a job whose worker died

> Route: `/redis-patterns/queues/stalled-recovery` · Module R3.03 · Chapter R3 Reliable Queues.
> · Grounding: EchoMQ's recovery sweep. The atomic, recommended form is `EchoMQ.Scripts.move_stalled_jobs_to_wait/4`
> wrapping `moveStalledJobsToWait-8.lua` (eight keys: `stalled`, `wait`, `active`, `failed`, `stalled-check`, `meta`,
> `paused`, `marker`) — one EVALSHA, the detect-and-move runs inside Redis's single thread. The liveness signal is the
> lock lease `EchoMQ.Keys.lock/2` → `emq:{queue}:<id>:lock`, a `PX`-expiry key kept alive by the `EchoMQ.LockManager`
> heartbeat. The Go port's `StalledChecker.checkStalledJobs` (`apps/echomq-go/pkg/echomq/stalled.go`) is the labelled
> cautionary contrast: it does the same work app-side in separate round trips. All real.

Guarantee at-least-once message delivery using LMOVE to atomically transfer messages to a processing list, enabling
recovery if consumers crash before completing work.

A reliable queue moves a job into an in-flight list under a lock so a crash leaves it parked, not lost. But a parked job
is only half the guarantee. Something must come back for it: a recovery sweep that finds the job whose worker died and
returns it to `wait` for another worker. This module is that sweep — how it detects a worker died, why it marks before it
recovers, and why the detect-and-move must be one indivisible step.

## Recovery from Failures

The source pattern runs a separate monitor process — sometimes called a "reaper" — that periodically scans the
processing queues for stalled messages. For each message, the reaper applies a timeout rule:

1. Check each processing queue.
2. If a message has been there longer than a timeout (for example, ten minutes), the worker is assumed dead.
3. Move the message back to the main queue: `LMOVE processing:worker1 work_queue RIGHT RIGHT`.

This guarantees at-least-once delivery: a message may be processed more than once, but it is never lost.

EchoMQ keeps the shape of the reaper and sharpens its test. The reaper's test is *has this message been in-flight longer
than a fixed timeout?* — a coarse proxy for a dead worker that misfires whenever a job legitimately runs long. EchoMQ's
test is more precise: *does this in-flight job still have a live worker?* The answer is a **lock lease**. Each
in-flight job holds a lock with a `PX` expiry, and a healthy worker renews that lease on a heartbeat. When the worker
dies, the heartbeat stops, the lease expires, and the lock is gone. **Lock gone means the worker died means the job
stalled.** The timeout becomes a lease, and the lease is exact: it is tied to the worker, not the clock.

The sweep does the same three things the reaper does — scan the in-flight list, decide which jobs lost their worker,
move those back — with two refinements the dives take apart. First, the decision is a lease check, not a timeout.
Second, the move is run as one atomic step so that two overlapping sweeps cannot reclaim the same job twice.

## The lease as the death signal

A lock that expired is the signal a worker died. The lease (`EchoMQ.Keys.lock/2` → `emq:{queue}:<id>:lock`) is a key
with a short `PX` TTL set when a worker takes a job. A live worker renews it on a heartbeat — `SET … PX`, a lease
renewal — before it can lapse. The renewals run in batch from one timer in `EchoMQ.LockManager`, so a pool of workers
extends a pool of leases without one timer per job.

When the worker crashes, the heartbeat stops. No renewal arrives, the TTL runs to zero, and Redis evicts the lock key.
The job is now in `active` with no live worker. The recovery sweep tests exactly this — for each job in `active`, is the
lock key still present? — and a missing lock is a stalled job. The first dive, **lock-expiry detection**, builds this
heartbeat-and-lease picture and shows why a paused worker that keeps renewing is correctly left alone while a dead one
is reclaimed.

## Mark, then recover

A brief pause is not a dead worker. A worker that misses one heartbeat — a long GC pause, a slow disk — may renew on the
next tick and finish the job. If the sweep reclaimed a job the instant its lock lapsed, every momentary stall would be
redelivered, doubling the work.

The fix is a two-phase sweep. The first sweep that finds a job stalled **marks** it: it records the job in a `stalled`
set rather than reclaiming it on the spot. Only the second sweep that *still* finds the job stalled **recovers** it. A
momentary stall survives one grace pass; a genuinely dead worker is reclaimed on the next sweep. When a job is recovered,
its attempt count is incremented and it goes back to `wait` — unless it has now exceeded its maximum attempts, in which
case it goes to `failed` instead of being retried forever. The second dive, **two-phase mark/recover**, walks the mark →
recover → `wait`-or-`failed` decision.

## Atomic vs non-atomic recovery

The recovery sweep must itself be careful. The detect step tests *is this job stalled?* and the recover step does *remove
it from `active`, push it to `wait`*. If those are two separate round trips, two sweeps running at once can both pass the
detect step for the same job and both run the recover step — the job lands in `wait` twice, and its attempt counter is
mis-incremented. This is the double-recovery window.

The atomic form closes it. `moveStalledJobsToWait-8.lua` runs the whole detect-and-move as **one EVALSHA**: the read,
the decision, and the writes happen inside Redis's single thread, so no second sweep can interleave. Each stalled job is
reclaimed once per sweep, and the attempt count is incremented in the script. The Go port's `StalledChecker` does the
same work app-side — `LRANGE active`, then per job `EXISTS lock`, then `LREM`/`LPUSH` — across separate round trips, and
increments the attempt count client-side. It is correct until two checkers overlap; then the window opens. The third
dive, **atomic vs non-atomic**, is the centrepiece: it runs the two overlapping checkers and counts the recoveries.

## The pattern, applied

EchoMQ's recovery sweep is the atomic form in real code, in `echo/apps/echomq`. `EchoMQ.Scripts.move_stalled_jobs_to_wait/4`
wraps `moveStalledJobsToWait-8.lua`, an eight-key script over `stalled`, `wait`, `active`, `failed`, `stalled-check`,
`meta`, `paused`, and `marker` (`EchoMQ.Keys.stalled/1`, `EchoMQ.Keys.wait/1`, `EchoMQ.Keys.active/1`, and the rest). One
EVALSHA: for each job in `active` whose lock has expired, the script marks it on the first pass and, on the next pass,
moves it back to `wait` (or `failed` past max attempts) and increments its attempt count — all without interleaving.

The liveness signal is the lease. `EchoMQ.Keys.lock/2` builds `emq:{queue}:<id>:lock`, a `PX`-expiry key, and
`EchoMQ.LockManager` renews all tracked leases from one timer batch. A lock that is gone is a worker that died.

The Go port `apps/echomq-go/pkg/echomq/stalled.go` is the cautionary contrast. `StalledChecker.checkStalledJobs` runs
`LRANGE active 0 -1`, then for each job `isJobStalled` runs `EXISTS lock`, then `recoverStalledJob` runs `HGETALL job`,
increments the `atm` (attemptsMade) field in Go, runs `LREM active`, branches to `failed` past max attempts, and runs
`LPUSH wait` with a pipelined `HSET atm`. The same job recovery, app-side, in separate round trips — the form that is
correct only until two sweeps overlap. It is the Go runtime's path, not EchoMQ's recommended one.

The full worker fetch loop — the heartbeat manager across a whole pool, the stalled-check coordination, and the polyglot
concurrency models — is the dedicated EchoMQ course. This module teaches the recovery pattern; that course teaches the
engine that runs it.

## References

### Sources
- [Redis — SET](https://redis.io/commands/set/) — the `PX` option behind the lock lease and the heartbeat renewal.
- [Redis — EVALSHA](https://redis.io/commands/evalsha/) — the cached-script call that runs the atomic detect-and-move as
  one step.
- [Redis — EVAL / scripting](https://redis.io/commands/eval/) — why a Lua script is one indivisible step, so the sweep
  cannot interleave.
- [Redis — LREM](https://redis.io/commands/lrem/) — the removal of the stalled job from the in-flight list.
- [Redis — LMOVE](https://redis.io/commands/lmove/) — the move back to wait, the modern form of the source's
  `LMOVE processing work RIGHT RIGHT`.
- [BullMQ — the queue protocol](https://bullmq.io/) — the stalled-check worker path EchoMQ ports.

### Related in this course
- [R3.03.1 · Lock-expiry detection](/redis-patterns/queues/stalled-recovery/lock-expiry-detection) — the lease as the
  death signal.
- [R3.03.2 · Two-phase mark/recover](/redis-patterns/queues/stalled-recovery/two-phase-mark-recover) — mark once, recover
  on the next sweep.
- [R3.03.3 · Atomic vs non-atomic](/redis-patterns/queues/stalled-recovery/atomic-vs-non-atomic) — one EVALSHA vs the
  multi-round-trip loop.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place: the three guarantees.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the one-step atomic move the sweep needs.
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter.
- [E6 · The job lifecycle](/echomq/lifecycle) — the dedicated EchoMQ course: the heartbeat manager and the pool-wide
  stalled-check coordination.
