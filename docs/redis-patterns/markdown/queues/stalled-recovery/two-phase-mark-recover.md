# Two-phase mark/recover — one grace pass before a reclaim

> Route: `/redis-patterns/queues/stalled-recovery/two-phase-mark-recover` · Dive R3.03.2 · Module R3.03 Stalled recovery.
> · Grounding: `moveStalledJobsToWait-8.lua` (`EchoMQ.Scripts.move_stalled_jobs_to_wait/4`) uses a `stalled` set
> (`EchoMQ.Keys.stalled/1` → `emq:{queue}:stalled`) to mark a job on the first sweep and recover it on the second,
> moving it to `wait` or, past max attempts, to `failed`. All real in `echo/apps/echomq`.

A lock that lapsed is a strong signal a worker died, but it is not certain. A worker can miss one heartbeat — a long GC
pause, a slow disk, a scheduler hiccup — and still recover on the next tick. If the sweep reclaimed a job the instant its
lock lapsed, every momentary stall would be redelivered, and the work would run twice. The two-phase sweep gives a job
one grace pass before it is reclaimed.

## Mark on the first sweep

The first sweep that finds a job stalled does not reclaim it. It **marks** it: it records the job in a `stalled` set and
moves on. The mark is a memory across sweeps — a note that this job was seen without a live worker once. A job that was
merely paused, whose worker renews its lock before the next sweep, has its mark cleared and is never touched. A job whose
worker is genuinely dead stays stalled, and its mark survives.

The grace pass costs one sweep interval of delay before a dead worker's job is reclaimed, in exchange for not
redelivering every job that briefly pauses. The trade is deliberate: a momentary stall is common and harmless, while a
double-run is expensive, so the sweep spends one interval to avoid the second.

## Recover on the second sweep

The next sweep checks the marked jobs. A job still in the `stalled` set, still without a live worker, is **recovered**:
its attempt count is incremented, and it is moved out of `active`. A job whose mark was cleared in between — its worker
came back and renewed the lock — is left alone.

Where a recovered job goes depends on its attempt count. A job back from a stall has used one of its attempts. If it has
attempts left, it returns to `wait` to be picked up again. If the recovery has pushed it past its maximum attempts, it
goes to `failed` instead — a job that stalls every time it runs would otherwise loop forever, so the attempt ceiling
caps the retries.

```
# sweep 1: mark the stalled job (no reclaim yet)
SADD emq:{queue}:stalled <id>             # record it; a paused worker clears this before sweep 2

# sweep 2: recover only if still marked and still stalled
if SISMEMBER emq:{queue}:stalled <id> and EXISTS emq:{queue}:<id>:lock == 0:
    attempts = HINCRBY emq:{queue}:<id> atm 1
    LREM emq:{queue}:active 1 <id>
    if attempts >= max_attempts:
        ZADD emq:{queue}:failed <ts> <id>   # past the ceiling: fail, do not retry
    else:
        LPUSH emq:{queue}:wait <id>          # attempts left: back to wait for another worker
```

The two phases together make the sweep tolerant. A flicker is forgiven by the grace pass; a dead worker is reclaimed on
the second sweep; a chronically stalling job is failed rather than retried without end.

## The pattern, applied

In EchoMQ the two phases live inside one script. `moveStalledJobsToWait-8.lua` operates over a `stalled` set
(`EchoMQ.Keys.stalled/1` → `emq:{queue}:stalled`) alongside `wait`, `active`, and `failed`. On a sweep it marks a newly
stalled job into the `stalled` set; a job already in the set that is still stalled is the one it recovers, moving it to
`wait` or — past its attempt ceiling — to `failed`, incrementing the attempt count as it goes. The `max_stalled_count`
argument bounds how many times a job may be recovered from a stall before it is failed outright. Because the mark and the
recover live in the same script, the two-phase decision runs without a separate process holding intermediate state.

The full sweep cadence — how often the script runs, how the `stalled-check` key throttles concurrent sweeps, and the
pool-wide coordination — is the dedicated EchoMQ course. This dive teaches the mark-then-recover decision; that course
teaches the schedule that drives it.

## References

### Sources
- [Redis — Sets](https://redis.io/docs/latest/develop/data-types/sets/) — the `stalled` set that marks a job once across
  sweeps.
- [Redis — SADD](https://redis.io/commands/sadd/) — the mark: record a newly stalled job for the next sweep.
- [Redis — HINCRBY](https://redis.io/commands/hincrby/) — the attempt-count increment on a recovered job.
- [Redis — EVAL / scripting](https://redis.io/commands/eval/) — why the mark and the recover run in one indivisible
  script.
- [BullMQ — the queue protocol](https://bullmq.io/) — the two-phase stalled-check worker path EchoMQ ports.

### Related in this course
- [R3.03 · Stalled recovery](/redis-patterns/queues/stalled-recovery) — the module: the recovery sweep in full.
- [R3.03.1 · Lock-expiry detection](/redis-patterns/queues/stalled-recovery/lock-expiry-detection) — the prior dive: the
  lease as the death signal.
- [R3.03.3 · Atomic vs non-atomic](/redis-patterns/queues/stalled-recovery/atomic-vs-non-atomic) — the next dive: why the
  recover step must be one step.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place: the three guarantees.
- [E6 · The job lifecycle](/echomq/lifecycle) — the dedicated EchoMQ course: the sweep schedule that drives the two
  phases.
