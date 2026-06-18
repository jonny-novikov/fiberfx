# E2.03 · Lock management & the supporting processes

> Route: `/echomq/core/lock-management` · Movement I · The Core (as-built) · `← redis-patterns R3`

A job in EchoMQ is owned while a worker runs it — by a lock key under a `PX` TTL. Three library
processes keep that ownership honest and keep the queue alive, and the host application supervises
all of them: EchoMQ-Elixir is **library-only**, with no `Application` or supervision tree of its own.

- **`EchoMQ.LockManager`** holds locks fresh with **one timer per worker, not one per job** —
  a single recurring timer that batch-renews every tracked job in one Redis call.
- **`EchoMQ.StalledChecker`** finds jobs whose worker died and recovers them, in a two-phase
  mark-then-recover sweep.
- **`EchoMQ.JobScheduler`** emits recurring jobs by cron pattern or fixed interval, and
  **`EchoMQ.QueueEvents`** consumes the queue's lifecycle events from a Redis Stream.

The lock key and the renew/recovery Lua scripts are **L1/L2** — frozen and shared across the three
runtimes. The processes above them are each runtime's own **L3/L4**: how a runtime schedules a
renewal or consumes the event stream varies, but the lock key, the `extendLocks-1.lua` script, the
`moveStalledJobsToWait-8.lua` script, and the `emq:{queue}:events` stream do not.

## The three dives

1. **E2.03.1 · One timer, not N** — `EchoMQ.LockManager` runs a single `Process.send_after`
   timer per worker that fires every ~7.5 s, selects every tracked job past its half-window
   threshold, and renews them all in one `extendLocks-1.lua` call. N jobs cost O(1) timers and one
   Redis round-trip, not N of each.
2. **E2.03.2 · Stalled recovery** — `EchoMQ.StalledChecker` lists `active`, probes each job's lock
   with a pipelined `EXISTS`, and runs `moveStalledJobsToWait-8.lua` to requeue or fail the jobs
   whose lock is gone — two-phase, with `max_stalled_count` defaulting to 1.
3. **E2.03.3 · Schedulers & events** — `EchoMQ.JobScheduler` computes the next run from
   `%{every: ms}` or `%{pattern: cron}` and emits a delayed job each time it fires;
   `EchoMQ.QueueEvents` blocks on `XREAD` against the `emq:{queue}:events` stream and delivers each
   event to its subscribers.

## How it fits — the protocol and its three runtimes

The lock key `emq:{queue}:{jobId}:lock`, the renew script `extendLocks-1.lua`, the recovery script
`moveStalledJobsToWait-8.lua`, and the `emq:{queue}:events` stream that every transition script
`XADD`s onto are **L1/L2** — immutable and identical in Elixir, Go, and Node.js. The four library
processes that drive them — `LockManager`, `StalledChecker`, `JobScheduler`, `QueueEvents` — are
**L3/L4**: each is an OTP `GenServer` choice, and Go and Node.js make their own. The wire underneath
does not move.

The Golden Rule holds: L1 (the keys and field names) and L2 (the Lua scripts and the stream) are
frozen and shared; L3 (the executor) and L4 (the API) vary.

## References

### Sources

- BullMQ — Documentation — the lock protocol, the stalled-job recovery sweep, repeatable jobs, and
  the events stream EchoMQ implements. https://docs.bullmq.io/
- Redis — EXISTS — the lock-presence probe the stalled checker pipelines over the active list.
  https://redis.io/commands/exists/
- Redis — XADD — the append each transition script makes onto the queue's events stream.
  https://redis.io/commands/xadd/

### Related in this course

- `/echomq/core` — E2 · The core (the chapter landing).
- `/echomq/core/lifecycle/the-lock-protocol` — E2.01.3 · the single-lock acquire, heartbeat, and
  verification this module scales up.
- `/echomq/core/jobs-queues-workers` — E2.02 · the worker fetch loop that picks up jobs and tracks
  their locks.
- `/redis-patterns/queues` — redis-patterns R3 · the reliable-queue pattern these locks uphold.
