# R4.04 · Backoff & retry

> Route: `/redis-patterns/time-delay-priority/backoff-retry` · module hub · chapter R4 · Time, Delay & Priority

A failed job does not retry immediately. Re-schedule it into the future with a delay that grows on each attempt — a delayed job whose fire-time is computed by a backoff formula — so a struggling dependency is not hammered.

This module is the delayed-queue pattern (R4.01) applied to retries. The source's *Retry with Backoff* note is one line — *"This schedules a retry 60 seconds in the future. Track retry counts in the task data to implement exponential backoff or maximum retry limits"* — and *Retry mechanisms: retry failed operations with backoff* is one of its use cases. R4.04 takes that idea apart: a failed job is re-added to the same delayed sorted set, scored by a fire-time the backoff formula computes, and swept back when due. No new structure; one set, two uses.

## A retry is a delayed job

When a job fails, the worker does not drop it and does not loop on it. It re-schedules the job to run again later — and "later" is a fire-time, the exact axis the delayed queue already orders by. The source shows the minimal form: re-add with a future score.

```
ZADD delayed_queue 1706649060 "task:abc123"
```

That schedules a retry sixty seconds out. The member is the same job; the score is `now + 60s`. The delayed set sorts it by that fire-time alongside every other deferred job, and the due-sweep brings it back when the clock reaches it. The retry rides the machinery R4.01 already built — the only new question is *what delay to put in the score*.

## The backoff formula (exponential)

A fixed delay treats a transient failure and a struggling dependency the same. A backoff delay grows with the attempt, so the first retry is quick and a repeatedly-failing dependency gets progressively more breathing room. The exponential form doubles the delay each attempt:

```
delay = base × 2^(attempt - 1)
```

Attempt 1 waits `base`, attempt 2 waits `2 × base`, attempt 3 waits `4 × base`, attempt 4 waits `8 × base`. With a one-second base, the retries land at 1s, 2s, 4s, 8s, 16s out.

In EchoMQ this math is owned by `EchoMQ.Backoff.calculate/4` — Elixir, not Lua. The `:exponential` clause is `delay = trunc(:math.pow(2, attempt - 1) * base_delay)`, then `apply_jitter(delay, jitter)`. The doc example is exact: `calculate(:exponential, 3, 1000, jitter: 0.2)` returns about `4000`. The `:fixed` strategy returns `apply_jitter(base_delay, jitter)` — the same base every attempt. A custom strategy can be registered, but the two built-ins are fixed and exponential.

The ownership matters: the formula computes the *delay value*, and the Lua reschedule script is handed that value. The Lua never computes `2^(n-1)`.

## Jitter — breaking the thundering herd

Exponential backoff alone has a failure mode. If many jobs fail at the same instant — a dependency that went down took them all out together — they all compute the *same* backoff delay and all re-fire at the same future millisecond. The recovery becomes a synchronized spike: the thundering herd. The dependency, newly back on its feet, is hit by the whole batch at once and may fall over again.

Jitter spreads the retries. `EchoMQ.Backoff` applies it in `apply_jitter/2`: for a jitter fraction in (0, 1], it computes `min_delay = trunc(delay × (1 - jitter))` and `jitter_range = trunc(delay × jitter × 2)`, then returns `min_delay + :rand.uniform(jitter_range + 1) - 1`. With `jitter: 0.2` on a 4000 ms delay, each retry lands somewhere in `[3200, 4800]` — the computed delay plus or minus twenty percent. The default config carries it: `%{type: :exponential, delay: 1_000, jitter: 0.2}`. A herd that would have re-fired in one spike is smeared across a window instead.

## Reusing the delayed ZSET (no new structure)

A retry is not a new mechanism. It is R4.01's machinery used a second time. `EchoMQ.Scripts.retry_job/5` runs `retryJob-11.lua`, which re-adds the failed job to the delayed key (`KEYS[7]`) scored by the backoff fire-time. That script *includes* `promoteDelayedJobs` — the same due-sweep R4.01 teaches: `ZRANGEBYSCORE delayedKey 0 (timestamp + 1) × 0x1000 - 1 LIMIT 0 1000`, then `ZREM` the due jobs and `ZADD` them onto the wait or prioritized list. The retry re-enters `emq:{queue}:delayed` exactly the way a freshly-scheduled delayed job does, scored by `getDelayedScore` ((fire-time) × `0x1000`), and is swept back when the clock reaches it.

So the chapter's first module and this one share one sorted set. R4.01 schedules; R4.04 sizes the delay with `EchoMQ.Backoff` and re-schedules on failure. The structure does not change between them.

## Capping — max attempts

A retry loop needs a floor. A job that fails forever should not retry forever. The source's own note is *"maximum retry limits"*: track the attempt count in the job data and stop re-scheduling once it crosses a configured maximum. In EchoMQ the attempts limit is part of the job's options (`attempts: 5` in the `Backoff` doc examples), checked on each failure before `retry_job/5` is called; past the limit the job moves to the failed set instead of back to delayed. The backoff formula sizes the delays; the attempts cap decides how many of them there are.

## When backoff hurts (latency-sensitive work)

Backoff trades latency for protection. That trade is right for a job whose work tolerates a delayed retry — an email, a webhook, a batch import — and wrong for work that must complete now or not at all. A user-facing request waiting on a synchronous response cannot afford an 8-second backoff before its second attempt; it needs a fast in-line retry or an immediate failure, not a deferred one. Backoff also assumes the failure is transient and the dependency will recover; against a permanent failure it only delays the inevitable trip to the failed set, so the attempts cap should be small. For protecting a *shared* dependency from sustained load — not merely spacing one job's retries — rate limiting and the circuit breaker (R6 · Flow Control) are the right tools; backoff spaces one job's own retries, it does not cap the fleet.

## Where this is heading — EchoMQ 2.0

Today a retry lands on `emq:{queue}:delayed` and is swept by `promoteDelayedJobs`. The EchoMQ 2.0 protocol break — the first rung of the EMQ roadmap — renames this key to `emq:{queue}:delayed`, applies the `{queue}` hashtag transparently in the core, declares every Lua key in `KEYS[]`, and bumps `meta.version` from `bullmq:5.65.1` to `echomq:2.0.0` behind a two-way typed boot fence. The backoff math (`EchoMQ.Backoff.calculate/4`) and the due-sweep (`promoteDelayedJobs`) are unchanged — only the prefix and the now-fully-declared keys change. That is why the pattern is safe to teach before the break ships: retry-with-backoff is a property of the sorted set — the score, the doubling, the sweep — not of the prefix it rides on.

## The bridge — pattern to application

- **The pattern.** A delayed queue (R4.01) schedules a job for a future time. A retry is the same move, with the future time computed by a backoff formula that grows the delay each attempt.
- **In EchoMQ.** `EchoMQ.Backoff.calculate/4` sets the delay (`base × 2^(n-1)`, jittered); `retryJob-11.lua` re-adds the job to `emq:{queue}:delayed` at that score via the included reschedule; `promoteDelayedJobs` (R4.01's sweep) brings it back when due. One structure, two uses.

The takeaway: a retry is a delayed job whose fire-time is a backoff delay. The formula lives in Elixir (`EchoMQ.Backoff`); the reschedule and the sweep live in the Lua that R4.01 already taught.

## The three dives

- **R4.04.1 · Exponential backoff** — the formula `delay = base × 2^(attempt - 1)`, owned by `EchoMQ.Backoff.calculate/4`, not the Lua.
- **R4.04.2 · Jitter & the thundering herd** — fixed backoff synchronizes retries; `apply_jitter` spreads them across a window.
- **R4.04.3 · Reusing the delayed ZSET** — a retry is R4.01's machinery reused: `retryJob-11.lua` re-adds to `:delayed`, `promoteDelayedJobs` sweeps it back.

## References

### Sources

- [Redis — *ZADD*](https://redis.io/commands/zadd/) — re-add the failed job to the delayed set scored by the backoff fire-time.
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — the due-sweep (`promoteDelayedJobs`) that brings a retry back.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the timer-wheel the retry reuses.
- [BullMQ — *the queue protocol*](https://bullmq.io/) — the retry/backoff protocol EchoMQ ports.
- [DragonflyDB — *BullMQ on Dragonfly*](https://www.dragonflydb.io/docs/integrations/bullmq) — the BullMQ-on-Dragonfly direction EchoMQ 2.0 takes native.

### Related in this course

- R4.04.1 · Exponential backoff — `/redis-patterns/time-delay-priority/backoff-retry/exponential-backoff`
- R4.04.2 · Jitter & the thundering herd — `/redis-patterns/time-delay-priority/backoff-retry/jitter-thundering-herd`
- R4.04.3 · Reusing the delayed ZSET — `/redis-patterns/time-delay-priority/backoff-retry/reuse-the-delayed-zset`
- R4 · Time, Delay & Priority — `/redis-patterns/time-delay-priority`
- R4.01 · The delayed queue — `/redis-patterns/time-delay-priority/delayed-queue`
- R4.02 · Scheduler registry — `/redis-patterns/time-delay-priority/schedulers`
- E6 · Lifecycle controls — `/echomq/lifecycle`
