# E2.01.3 · The lock protocol

> Route: `/echomq/core/lifecycle/the-lock-protocol` · Movement I · The Core (as-built, present tense) · dive 3
> Back-link: ← redis-patterns R3 (`/redis-patterns/queues`)

## The fact

While a worker runs a job, the job is **owned** by a lock — a single Redis key, `EchoMQ.Keys.lock/2`
(`"#{job(ctx, job_id)}:lock"`), holding a UUID token under a TTL. The lock has three moves:

- **Acquire** — inside `moveToActive-11`, the pickup script sets
  `SET emq:{queue}:{jobId}:lock <uuid-token> PX <lockDuration>`. The token is a UUID v4 unique to the worker; the
  `PX` TTL auto-expires the lock if the worker crashes, so a dead worker's job is not owned forever.
- **Heartbeat** — `extendLock-2.lua` re-sets the TTL while the worker runs (2 KEYS: `[1]` the lock, `[2]` the stalled
  set; ARGV `[1]` token, `[2]` duration-ms, `[3]` jobid). The Elixir executor reaches it as
  `EchoMQ.Scripts.extend_lock/5`. Its real body is twenty-three lines:

  ```lua
  local rcall = redis.call
  if rcall("GET", KEYS[1]) == ARGV[1] then
    if rcall("SET", KEYS[1], ARGV[1], "PX", ARGV[2]) then
      rcall("SREM", KEYS[2], ARGV[3])
      return 1
    end
  end
  return 0
  ```

  It verifies the token (no one else holds the lock), re-sets the TTL, and removes the job from the stalled set —
  returning `1` on success, `0` if the token no longer matches. A worker renews every `lockDuration/2`.
- **Verification** — `moveToFinished-14` (and other transitions) check the token before acting. Missing returns `-2`
  (`JobLockNotExist`); mismatched returns `-6` (`JobLockMismatch`). Release on success is the `DEL` step inside
  `moveToFinished-14`.

## The worked example — the lock timeline, and the token check

The timing is fixed by four parameters:

| Parameter | Default | Purpose |
|---|---|---|
| `lockDuration` | 30000 ms | the lock TTL |
| `lockRenewTime` | 15000 ms (= lockDuration/2) | the heartbeat interval |
| `stalledInterval` | 30000 ms | the stalled-check period |
| `maxStalledCount` | 1 | max stalls before permanent failure |

A worker acquires the lock at pickup and renews it every `lockDuration/2`, so a healthy job's lock never expires:
each renewal extends the 30000 ms TTL while only 15000 ms has elapsed. If a worker crashes and misses a renewal, the
TTL runs out; the next stalled sweep finds the job in `active` with no lock and moves it back to `wait` (or to
`failed` once `stc` reaches `maxStalledCount`). Given a renew interval shorter than `lockDuration`, a job stays owned;
a renew interval longer than `lockDuration` lets the lock lapse and the job stall.

The token check is the heartbeat's guard: `GET lock == ARGV[1] token` ⇒ the worker still holds the lock, so re-set the
TTL and `SREM` the job from the stalled set; otherwise the renewal fails (`0`), because another worker — or stalled
recovery — has taken or cleared the lock.

The per-lock heartbeat above is the primitive; production renews **all** of a worker's locks together. EchoMQ's
Elixir runtime drives one `EchoMQ.LockManager` timer per worker that batch-renews via
`EchoMQ.Scripts.extend_locks/5` (`extendLocks-1.lua`, one stalled key, job-ids and tokens packed into ARGV) — the
one-timer story, taught in the lock-management module of this chapter.

## The protocol ↔ runtime pairing (the Golden Rule)

The lock key, the `SET …:lock <uuid> PX` acquire, the `extendLock-2.lua` heartbeat, and the `-2`/`-6` verification
codes are **L1/L2 — immutable and shared**. The same lock protocol runs in every runtime; only the executor that
issues the heartbeat and the renew schedule above it vary.

- **The protocol (immutable L1/L2)** — `EchoMQ.Keys.lock/2`, the `SET …:lock <uuid> PX <lockDuration>` acquire, the
  `extendLock-2.lua` heartbeat, and the closed `-2`/`-6` lock codes.
- **Its three runtimes (variable L3/L4)** — Elixir issues the heartbeat with `EchoMQ.Scripts.extend_lock/5` over a
  Redix pool and schedules renewals with one `EchoMQ.LockManager` timer per worker; Go and Node.js run the same
  `extendLock-2.lua` their own way. The lock protocol does not move; the schedule above it does.

## Recap

A job is owned by a UUID token under a TTL at `EchoMQ.Keys.lock/2`. Pickup acquires it inside `moveToActive-11`;
`extendLock-2.lua` re-sets the TTL every `lockDuration/2` after verifying the token and clearing the stalled set;
completion's `DEL` releases it; a missing or mismatched token returns `-2` or `-6`. The defaults are 30000 ms TTL,
15000 ms renew, 30000 ms stalled check, `maxStalledCount` 1. The lock protocol is L1/L2 — the same in every runtime.

## References

### Sources

- BullMQ — *Documentation* (`https://docs.bullmq.io/`) — the lock protocol: acquire, heartbeat, verification, and the
  stalled-recovery timing.
- Redis — *SET* (`https://redis.io/commands/set/`) — the `SET key value PX ms` acquire and TTL re-set.
- Redis — *SREM* (`https://redis.io/commands/srem/`) — the remove-from-stalled-set step the heartbeat performs.
- Redis — *GET* (`https://redis.io/commands/get/`) — the token read the heartbeat verifies before re-setting the lock.

### Related in this course

- `/echomq/core/lifecycle` — E2.01 · The lifecycle & state machine (the module hub).
- `/echomq/core/lifecycle/every-transition-and-its-script` — E2.01.2 · Every transition & its script (where `-2`/`-6`
  are emitted, and the pickup that acquires the lock).
- `/echomq/protocol` — E1 · The protocol (the key taxonomy the lock key belongs to).
- `/redis-patterns/coordination` — redis-patterns R2 · Coordination (the lock-with-fence pattern, applied).
