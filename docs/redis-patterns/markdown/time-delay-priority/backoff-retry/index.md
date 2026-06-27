# R4.04 · Backoff & retry

> Route: `/redis-patterns/time-delay-priority/backoff-retry` · chapter R4 (Time, Delay & Priority) · pattern: the delayed queue applied to retries.

A failed job does not retry immediately. Re-schedule it into the future with a delay that grows on each attempt — a delayed job whose fire-time is computed by a backoff formula — so a struggling dependency is not hammered.

R4.04 is the delayed-queue pattern (R4.01) applied to **retries**: a failed job is parked on the same schedule set the delayed queue uses, scored by a future fire-time, and swept back to pending when the clock reaches it. The only new piece is **where the delay comes from** — a backoff formula instead of a caller-supplied time.

## The source line this is built on

The delayed-queue source (`content/fundamental/delayed-queue.md.txt`, "Retry with Backoff") puts it plainly: *"If a task fails, reschedule it with a delay … Track retry counts in the task data to implement exponential backoff or maximum retry limits."* The retry count and the formula turn one re-schedule into a curve.

## §1 — A retry is a delayed job

A retry is not a new mechanism. It is a re-schedule: read the attempt count, compute a delay, and ZADD the job back onto the schedule set at `now + delay`. The promotion sweep that already moves due delayed jobs back to pending moves the retry too. One structure carries both the first-time delayed job and every retry.

The attempt count is the input the formula needs. In the real bus it is the `attempts` field on the job row — the same fencing token a claim mints with `HINCRBY` — so the retry path reads the attempt that has failed and prices the next delay from it.

## §2 — The backoff formula (exponential)

Exponential backoff doubles the wait each attempt: `delay = base × 2^(attempts-1)`. Attempt 1 waits `base`; attempt 2 waits `2 × base`; attempt 3 waits `4 × base`. The curve climbs fast, so a dependency that is down gets longer and longer breathing room, and a clamp (`cap`) holds the curve at a ceiling so a stubborn job does not schedule itself years out.

In the real bus this curve is a **host-side pure function**: `EchoMQ.Backoff.delay_ms/2`. It takes a policy and the attempt that just failed and returns a literal `delay_ms`. `delay_ms({:exponential, 100, 10_000}, 3)` returns `400` (100 × 2²); at attempt 20 the same call returns `10000` — the cap. The wire never computes a curve; it takes the literal delay it is handed.

## §3 — Jitter — breaking the thundering herd

When many jobs fail at the same moment — a dependency blinks — a fixed backoff schedules every retry for the **same** future instant. They re-fire together: the thundering herd, a second spike on a service that is already struggling. Jitter spreads them. A jittered delay is a random value bounded by the backoff delay, so a cohort that failed together re-fires across a window instead of in one spike.

In the real bus jitter is a policy wrapper: `{:jitter, inner}`. It computes the inner policy's delay, then returns a uniform random value in `0..inner_delay` — the full-jitter form. The randomness is the point; the inner delay is its bound.

## §4 — Reusing the schedule set (no new structure)

A retry adds no key and no script of its own. `EchoMQ.Jobs.retry/7` is handed the literal `delay_ms` from `EchoMQ.Backoff`, reads the row's `attempts`, and — under the max-attempts ceiling — ZADDs the job onto the schedule set at `now + delay_ms` (server clock). `EchoMQ.Jobs.promote/3` then ZRANGEBYSCOREs the due range and moves those jobs back to pending. That is exactly the delayed-queue machinery from R4.01: the schedule set is the sorted set, the score is the fire-time, the promotion is the sweep. The retry just supplies a computed score.

## §5 — Capping — max attempts

A retry curve cannot climb forever. `retry/7` carries a `max_attempts` argument; when the row's `attempts` has reached it, the job is not re-scheduled — its state is set to `dead` and it lands on the morgue set instead. A retry is bounded by both a ceiling on the delay (the cap) and a ceiling on the count (max attempts).

## §6 — When backoff hurts (latency-sensitive work)

Backoff trades latency for protection. For a job a user is waiting on, a four-second third-attempt delay can be worse than a fast failure. Backoff fits work that can wait — a notification, a settlement, a digest — and fits poorly when a caller needs an answer now. The pattern is a position on that trade-off, not a default.

## The bridge — pattern to application

- **The pattern:** a delayed queue schedules a job for a future time. A retry is the same move with the future time computed by a backoff formula and bounded by a max-attempt count, so a failing job re-fires later and later, then gives up.
- **Its EchoMQ application:** `EchoMQ.Backoff.delay_ms/2` sets the delay (`base × 2^(attempts-1)`, clamped, optionally jittered); `EchoMQ.Jobs.retry/7` ZADDs the job onto `emq:{<queue>}:schedule` at `now + delay_ms`; `EchoMQ.Jobs.promote/3` (R4.01's sweep) brings it back when due. One structure, two uses.

The leaderboard and the workshop in this chapter (`Codemojex.Scoring`, `Codemojex.NotificationWorker`) ride the same schedule set for their scheduled and recurring jobs.

## References

### Sources

- Redis — *ZADD* — https://redis.io/commands/zadd/ — re-add the failed job to the schedule set scored by the backoff fire-time.
- Redis — *ZRANGEBYSCORE* — https://redis.io/commands/zrangebyscore/ — the due-sweep (`promote/3`) that brings a retry back.
- Valkey — *Sorted sets* — https://valkey.io/topics/data-types/ — the timer-wheel the retry reuses.
- Redis — *Documentation* — https://redis.io/docs/ — strings, sorted sets, and scheduling in context.

### Related in this course

- R4.04.1 · Exponential backoff — `/redis-patterns/time-delay-priority/backoff-retry/exponential-backoff`
- R4.04.2 · Jitter & the thundering herd — `/redis-patterns/time-delay-priority/backoff-retry/jitter-thundering-herd`
- R4.04.3 · Reusing the schedule set — `/redis-patterns/time-delay-priority/backoff-retry/reuse-the-delayed-zset`
- R4.01 · Delayed queue — `/redis-patterns/time-delay-priority/delayed-queue` — the schedule-set machinery this reuses.
- R4.02 · Schedulers — `/redis-patterns/time-delay-priority/schedulers` — recurring jobs on the same clock.
- The EchoMQ queue protocol — `/echomq/queue` — the schedule set, the claim, and the retry path in depth.
