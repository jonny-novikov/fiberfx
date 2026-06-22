# R4.04.3 · Reusing the delayed ZSET

> Route: `/redis-patterns/time-delay-priority/backoff-retry/reuse-the-delayed-zset` · dive 3 of R4.04

A retry introduces no new structure. It is R4.01's delayed sorted set used a second time: `retryJob-11.lua` re-adds the failed job to `emq:{queue}:delayed` scored by the backoff fire-time, and `promoteDelayedJobs` — the same due-sweep R4.01 teaches — brings it back when due. One set, two uses.

## The retry re-enters the delayed set

When a job fails and has retries left, the worker calls `EchoMQ.Scripts.retry_job/5`, which runs `retryJob-11.lua`. That script's `KEYS[7]` is the delayed key — `emq:{queue}:delayed`, the exact set R4.01 schedules into. The failed job is re-added there, scored by its fire-time the way every delayed job is, with the score coming from the same `getDelayedScore` shift R4.01 walks: `(timestamp + delay) × 0x1000`, the fire-time shifted twelve bits so jobs due in the same millisecond stay ordered.

The delay in that fire-time is the backoff delay — computed first by `EchoMQ.Backoff.calculate/4` in Elixir, then handed to the reschedule. So the retry sits in the delayed set indistinguishable from a freshly-scheduled deferred job: same key, same score shape, same ordering. The set does not know one member is a retry and another is a first-time schedule. To the sorted set they are all jobs scored by when they are due.

## The sweep is the same `promoteDelayedJobs`

`retryJob-11.lua` does not only re-add the job — it *includes* the promote sweep. The script carries `[INCLUDED: includes/promoteDelayedJobs.lua]`, and that included function is the same one R4.01's promotion dive teaches:

```lua
-- promoteDelayedJobs (included by retryJob-11.lua) — real
local jobs = rcall("ZRANGEBYSCORE", delayedKey, 0, (timestamp + 1) * 0x1000 - 1, "LIMIT", 0, 1000)
if (#jobs > 0) then
  rcall("ZREM", delayedKey, unpack(jobs))
  -- ZADD each onto the target (wait) or prioritized list
end
```

It ranges the delayed key from `0` up to `(timestamp + 1) × 0x1000 - 1` — every job whose shifted fire-time is at or below the current millisecond — removes them with `ZREM`, and moves them onto the wait or prioritized list. The retry re-enters at a future score and is swept back by exactly this function when the clock reaches it. There is no retry-specific sweep; the retry is promoted by the same machinery that promotes every delayed job, invoked as `promoteDelayedJobs(KEYS[7], ...)` inside the retry script.

## One structure, two uses — what changes and what does not

The whole module reduces to this: R4.01 owns the delayed set, the score shift, and the promote sweep. R4.04 reuses all three. What R4.04 *adds* is upstream of the set — the computation of *which delay* to put in the score, done by `EchoMQ.Backoff` (the exponential doubling, the jitter). What R4.04 does *not* add is any new key, command, or sweep. The reschedule is a `ZADD` to `emq:{queue}:delayed`; the recovery is `promoteDelayedJobs`; both are R4.01's.

This is why the pattern is economical. A queue that already has a delayed queue has a retry mechanism for free — it needs only a formula to size the delay and an attempts counter to cap the loop. The hard part (a time-ordered set with an efficient due-range read) was built once, in R4.01, and serves both scheduled work and retries.

## Where this is heading — EchoMQ 2.0

The retry re-enters `emq:{queue}:delayed` and is swept by `promoteDelayedJobs` today. EchoMQ 2.0 renames the key to `emq:{queue}:delayed`, applies the `{queue}` hashtag transparently in the core, and declares every Lua key in `KEYS[]` — so `retryJob-11.lua`'s `KEYS[7]` and the sweep's `delayedKey` become fully-declared `emq:`-prefixed keys, and `meta.version` reads `echomq:2.0.0` behind the two-way boot fence. The reuse this dive teaches — one set serving both schedule and retry, swept by one `promoteDelayedJobs` — is unchanged by the break. The break renames the prefix and tightens key declaration; it does not split the delayed set or add a retry-specific structure. The "one structure, two uses" property is a fact about the sorted set, not the prefix.

## The bridge — pattern to application

- **The pattern.** A retry is a delayed job: re-add the failed job to the delayed set at a backoff fire-time, and let the existing due-sweep bring it back when its time comes. No new structure.
- **In EchoMQ.** `retryJob-11.lua` re-adds the job to `emq:{queue}:delayed` (`KEYS[7]`) at the backoff score, and the *included* `promoteDelayedJobs` sweeps it back with `ZRANGEBYSCORE delayedKey 0 (timestamp + 1) × 0x1000 - 1` then `ZREM` — R4.01's own sweep, called from inside the retry script.

The takeaway: a retry adds no structure — it reuses R4.01's delayed set, score shift, and `promoteDelayedJobs` sweep, contributing only the backoff delay that sets the fire-time.

## References

### Sources

- [Redis — *ZADD*](https://redis.io/commands/zadd/) — re-add the failed job to `emq:{queue}:delayed` at the backoff fire-time score.
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — the `promoteDelayedJobs` range that sweeps the due retry back to wait.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the one timer-wheel that serves both schedule and retry.
- [DragonflyDB — *BullMQ on Dragonfly*](https://www.dragonflydb.io/docs/integrations/bullmq) — the BullMQ-on-Dragonfly direction EchoMQ 2.0 takes native.

### Related in this course

- R4.04 · Backoff & retry — `/redis-patterns/time-delay-priority/backoff-retry`
- R4.04.1 · Exponential backoff — `/redis-patterns/time-delay-priority/backoff-retry/exponential-backoff`
- R4.04.2 · Jitter & the thundering herd — `/redis-patterns/time-delay-priority/backoff-retry/jitter-thundering-herd`
- R4.01 · The delayed queue — `/redis-patterns/time-delay-priority/delayed-queue`
- R4.02 · Scheduler registry — `/redis-patterns/time-delay-priority/schedulers`
- E6 · Lifecycle controls — `/echomq/lifecycle`
