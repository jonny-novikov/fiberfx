# The reliable queue — lose no job

> Route: `/redis-patterns/queues/the-reliable-queue` · Dive R3 · 1 · Chapter R3 Reliable Queues.
> · Grounding: EchoMQ's worker fetch loop. `moveToActive-11.lua` runs `rcall("RPOPLPUSH", waitKey, activeKey)` so a
> job leaves `emq:{queue}:wait` and lands in `emq:{queue}:active` under a lock in one step — a crash parks it
> recoverable, never lost. `EchoMQ.Keys.dedup/2` builds `emq:{queue}:de:{id}` so a redelivered job runs its effect
> once. `moveStalledJobsToWait-8.lua` returns a job whose worker died (its lock expired) to `wait` for another worker.
> All real in `echo/apps/echomq`.

A reliable queue is one that loses no job. The naive form — pop a job, process it, done — loses a job the instant the
worker dies between the pop and the finish: the job is gone from Redis and was never completed. Three guarantees turn
that fragile loop into a reliable one, and they build in order: move the job *into an in-flight list* atomically so a
crash leaves it recoverable; accept that redelivery means **at-least-once**, so the consumer must be idempotent; and
reclaim a job whose worker died back to `wait` for another worker. EchoMQ's real worker path is each of the three.

## The in-flight move

`RPOP` and process is the leak. The job leaves the queue the moment it is popped, before any work has happened; if the
worker crashes mid-job — a deploy, an OOM kill, a power loss — the job is neither in Redis nor finished. It is lost,
silently, with nothing to recover it from.

The fix is to never let a job leave Redis until it is done. Instead of popping the job out, move it *into a second
list* — an in-flight list — in one atomic step. `RPOPLPUSH source dest` (and its modern successor `LMOVE source dest
RIGHT LEFT`) pops from one list and pushes to another as a single command: the job is in exactly one of the two lists
at every instant, never in neither. A job parked in the in-flight list whose worker has died is still *there* — it can
be found and returned for redelivery. The job is not lost; it is waiting to be reclaimed.

```
# the leak: a window where the job is in neither list
job = RPOP queue            # job is now out of Redis...
process(job)                # ...if the worker dies HERE, the job is gone

# the fix: the job is always in exactly one list
job = RPOPLPUSH queue processing   # atomic: leaves `queue`, lands in `processing`
process(job)                       # a crash here leaves the job in `processing`, recoverable
LREM processing 1 job              # remove only after the work is truly done
```

`RPOPLPUSH` is the original move command; `LMOVE` (Redis 6.2+) generalises it with explicit directions and is the
recommended form for new code. Either way the guarantee is the same: there is no instant at which the job exists
nowhere.

## At-least-once and idempotency

The in-flight move makes redelivery *possible* — that is the whole point. But it also makes redelivery *inevitable* in
one case: a worker that finishes the work, then crashes before it can remove the job from the in-flight list. On
recovery the job is still in-flight, so it is redelivered and the work runs again. The same is true of any reclaim
path: a job whose worker stalled is handed to a new worker, and the old worker may yet be alive and slow.

This is the honest cost of never losing a job. **Exactly-once delivery is a lie** — you cannot both guarantee a job is
never lost *and* guarantee it is never delivered twice, because the acknowledgement itself can be lost. What a reliable
queue actually offers is **at-least-once** delivery: a job is delivered one or more times, never zero. The
responsibility moves to the consumer, which must be **idempotent** — running the same job twice must produce the same
effect as running it once.

The discipline is to make the *effect* exactly-once even though the *delivery* is at-least-once. The standard move is a
dedup marker keyed by a stable job id: before the effect runs, claim the marker; if it already exists, the effect has
already happened, so skip it.

```
# at-least-once delivery + an idempotent effect = exactly-once effect
if SET dedup:{job_id} 1 NX:          # claim the marker; NX = only if absent
    apply_effect(job)                # first delivery: charge the card once
else:
    skip()                           # a redelivery: the marker is already set, do nothing
```

A non-idempotent consumer double-charges on every redelivery. An idempotent one charges once, no matter how many times
the job arrives. The marker is what makes the difference: the second delivery sees it and skips the effect.

## Stalled recovery

A job in the in-flight list whose worker has died must come back. The signal that a worker died is a **lock that
expired**: each in-flight job holds a lock with a TTL, and a healthy worker renews it on a heartbeat. When the worker
crashes, the heartbeat stops, the lock expires, and the job is now stuck in-flight with no live worker.

A separate recovery sweep finds these jobs and returns them to `wait` for another worker to pick up. It checks the
in-flight list, and for each job whose lock has expired, moves it back to the waiting list. The job re-enters the
normal pickup path and is delivered again — at-least-once in action — to a worker that can finish it. A job is only
truly lost if both the recovery sweep and every worker fail at once, which is the failure the lock TTL plus the sweep
are designed to bound.

The recovery sweep must itself be careful. If it runs the check and the move as two separate steps, two recovery
processes can both see the same stalled job and both move it, redelivering it twice over. The atomic form runs the
detect-and-move as one step — one Lua script over the in-flight list, the lock, and the waiting list — so each stalled
job is reclaimed exactly once per sweep. The non-atomic form, where the check and the move are separate round trips, is
the cautionary contrast: correct only until two sweeps overlap.

## The pattern, applied

EchoMQ's worker fetch loop is all three guarantees in real code, in `echo/apps/echomq`.

The in-flight move is `moveToActive-11.lua`: its body runs `rcall("RPOPLPUSH", waitKey, activeKey)`, where `waitKey`
is `emq:{queue}:wait` and `activeKey` is `emq:{queue}:active` (`EchoMQ.Keys.wait/1` and `EchoMQ.Keys.active/1`). The
job leaves `wait` and lands in `active` under a lock in one atomic script — a crash leaves it in `active`, recoverable,
never lost.

At-least-once with an idempotent effect is the dedup marker `EchoMQ.Keys.dedup/2`, which builds
`emq:{queue}:de:{id}` (`"#{base(ctx)}:de:#{dedup_id}"`). A job carrying a deduplication id is dropped if the marker
already exists, so the effect runs once across redeliveries.

Stalled recovery is `moveStalledJobsToWait-8.lua`: it operates over the `stalled`, `wait`, and `active` keys, and for
each job in `active` whose lock has expired it moves the job back to `wait` for another worker. The Go port's
non-atomic stalled path — a separate check followed by a separate move — is the cautionary contrast to this atomic
form, not the recommended one.

The full worker fetch loop — the heartbeat manager that renews the lock, the stalled-check coordination across a whole
worker pool, the include graph of the eleven-key `moveToActive`, and the polyglot concurrency models — is the
dedicated EchoMQ course, which teaches that protocol in depth. This dive teaches the reliable-queue pattern; that
course teaches the engine that runs it.

## References

### Sources
- [Redis — RPOPLPUSH](https://redis.io/commands/rpoplpush/) — the original atomic move that parks a job in the
  in-flight list, the heart of `moveToActive-11.lua`.
- [Redis — LMOVE](https://redis.io/commands/lmove/) — the modern successor (Redis 6.2+), with explicit `RIGHT`/`LEFT`
  directions, recommended for new code.
- [Redis — EVAL / scripting](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) — how the
  multi-key reliable move and the stalled sweep run as one atomic Lua script.
- [BullMQ — the queue protocol](https://bullmq.io/) — the wait/active/stalled worker path EchoMQ ports, where "the Lua
  scripts are the protocol."

### Related in this course
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter: the whole reliable-queue family.
- [R3 · States as locations](/redis-patterns/queues/states-as-locations) — the next dive: each job state is a Redis
  list it lives in, and the move between them is the state transition.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic move the reliable queue is built
  on: read-decide-write in one indivisible step.
- [R0.2 · Redis under Portal](/redis-patterns/overview/redis-under-portal) — where EchoMQ sits in Portal's reserved
  Redis tier.
