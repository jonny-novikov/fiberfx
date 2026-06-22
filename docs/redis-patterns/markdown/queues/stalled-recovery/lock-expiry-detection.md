# Lock-expiry detection — the lease as the death signal

> Route: `/redis-patterns/queues/stalled-recovery/lock-expiry-detection` · Dive R3.03.1 · Module R3.03 Stalled recovery.
> · Grounding: the lock lease `EchoMQ.Keys.lock/2` → `emq:{queue}:<id>:lock`, a `PX`-expiry key set when a worker takes
> a job and renewed on a heartbeat by `EchoMQ.LockManager` (one timer batch-extends all tracked leases). A lock that is
> gone is a worker that died. All real in `echo/apps/echomq`.

One question must be resolved before the recovery sweep does anything: which in-flight job no longer has a live worker?
The source pattern resolves it with a timeout — a message in the processing list longer than ten minutes is assumed
stalled. EchoMQ resolves it with a lease tied to the worker directly. The lease is the heartbeat of the job: while it is
renewed, a worker is alive; when it lapses, the worker is gone.

## The timeout, re-cast as a lease

The source's reaper scans the processing queue and, for each message older than a timeout, treats the worker as dead and
moves the message back. The timeout is a proxy. It misfires in both directions: a job that legitimately runs longer than
the timeout is reclaimed while its worker is still working, and a worker that dies one second into a ten-minute timeout
holds a job hostage for the rest of it.

The lease removes the proxy. When a worker takes a job, it sets a lock key with a short `PX` expiry. A live worker renews
that lease on a heartbeat — a periodic `SET … PX` that pushes the expiry forward — well before it can lapse. The lock is
present exactly while a worker is alive and renewing. The reclaim question becomes a key lookup: for each job in
`active`, is its lock key still present? A present lock is a live worker; a missing lock is a stalled job.

```
# the lease: set when a worker takes the job
SET emq:{queue}:<id>:lock <token> PX 30000     # a 30s lease

# the heartbeat: a live worker renews before the lease lapses
SET emq:{queue}:<id>:lock <token> PX 30000     # pushes the expiry forward, every ~half-lease

# the death signal: no renewal -> the TTL runs to 0 -> Redis evicts the key
EXISTS emq:{queue}:<id>:lock                    # 0 means the worker died -> stalled
```

The lease length and the heartbeat interval are a pair: the heartbeat must run several times within one lease so a single
missed tick does not lapse it, and the lease must be short enough that a dead worker is detected promptly. A lease of
thirty seconds renewed every ten is the usual shape: two missed renewals still leave the lock alive, three lapse it.

## Paused is not dead

The lease distinguishes a worker that paused from a worker that died — a distinction a timeout cannot make. A paused
worker that is still running its event loop keeps renewing the lease, so its lock stays present and the sweep leaves its
job alone, even if the job has run for an hour. A dead worker stops renewing, its lock lapses within one lease, and the
sweep reclaims its job. The test is the lock, not the clock: a long-running job under a live heartbeat is safe; a short
job under a dead worker is reclaimed.

This is why the lease is more precise than the timeout it replaces. The timeout's test is *how long has this job been
running?*, and it reclaims on a number. The lease's test is *is a worker still renewing this lock?*, and it reclaims on the worker. A
job that runs longer than any fixed timeout but holds a live heartbeat is exactly the case the timeout gets wrong and the
lease gets right.

## The pattern, applied

In EchoMQ the lease is `EchoMQ.Keys.lock/2`, which builds `emq:{queue}:<id>:lock` for a job id. It is set with a `PX`
expiry when the worker takes the job and renewed on the worker's heartbeat. The renewals do not run one timer per job:
`EchoMQ.LockManager` keeps a single timer that extends all tracked leases in one batch, so a pool of workers renews a
pool of leases without a timer storm. The recovery sweep — `moveStalledJobsToWait-8.lua` — tests the lock for each job in
`emq:{queue}:active`; a job whose lock has lapsed is the one with no live worker.

The full heartbeat manager — the lease length, the renew cadence, the batch-extend timer, and the pool-wide coordination
— is the dedicated EchoMQ course. This dive teaches the lease as a death signal; that course teaches the manager that
keeps it.

## References

### Sources
- [Redis — SET](https://redis.io/commands/set/) — the `PX` expiry behind the lock lease and the `SET … PX` heartbeat
  renewal.
- [Redis — EXPIRE](https://redis.io/commands/expire/) — TTL semantics: how a key with a `PX` expiry is evicted when its
  time runs out.
- [Redis — EXISTS](https://redis.io/commands/exists/) — the lock lookup the sweep runs: a missing lock is a stalled job.
- [BullMQ — the queue protocol](https://bullmq.io/) — the lock-renewal worker path EchoMQ ports.

### Related in this course
- [R3.03 · Stalled recovery](/redis-patterns/queues/stalled-recovery) — the module: the recovery sweep in full.
- [R3.03.2 · Two-phase mark/recover](/redis-patterns/queues/stalled-recovery/two-phase-mark-recover) — the next dive:
  mark once, recover on the next sweep.
- [R3.03.3 · Atomic vs non-atomic](/redis-patterns/queues/stalled-recovery/atomic-vs-non-atomic) — the atomic sweep that
  acts on this lock check.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place: the three guarantees.
- [E6 · The job lifecycle](/echomq/lifecycle) — the dedicated EchoMQ course: the heartbeat manager that renews the lease.
