# R4.06 · Workshop — One sorted set, five readings

> Route: `/redis-patterns/time-delay-priority/workshop` · chapter workshop (capstone) · chapter R4 · Time, Delay & Priority · no dives

Fold the five R4 patterns into one worked scenario: EchoMQ schedules a Portal LMS's notification and digest jobs — a lesson reminder, a weekly digest, a password-reset email, a failed send that retries, and the ranking the digest carries. Every move is one sorted set read a different way.

The chapter taught five patterns over the sorted set: the delayed queue (R4.01), the scheduler registry (R4.02), the composite priority score (R4.03), backoff-and-retry (R4.04), and the leaderboard ranking (R4.05). This capstone is the one scenario that uses all five at once. Picture a Portal LMS — courses, lessons, learners — and the notifications it would send. EchoMQ *would* schedule those jobs; Portal does not ship a built notification system, so the scenario is a worked application of the chapter's machinery, not a claim about a Portal feature. The reminder is a one-shot delayed job; the digest is a repeatable job; the reset email is a priority job; the failed send is a backed-off retry; and the digest carries a ranking. Three sorted sets — `:delayed`, `:repeat`, `:prioritized` — drive one worker, all on the same `ZADD` / range / pop machinery.

## The scenario — five jobs about Portal entities

Portal models the entities the jobs are about, and each carries its own branded namespace (cite, do not invent):

- `Portal.Accounts.User` — a learner account, namespace `USR`, the struct `[:id, :email, :name]`.
- `Portal.Catalog.Lesson` — a lesson within a course, namespace `LSN`, the struct `[:id, :course_id, :title]`.
- `Portal.Enrollment.Progress` — a learner's progress through a lesson, namespace `PRG`, the struct `[:id, :enrollment_id, :lesson_id, :percent]` with `percent :: 0..100`.

The five jobs are scheduled *about* these entities. None of them assert Portal runs a scheduler; they are the chapter's patterns applied to Portal's data.

## The lesson reminder — a one-shot delayed job (R4.01)

A learner enrols in a lesson that starts tomorrow. EchoMQ schedules a reminder twenty-four hours out — a one-shot job that runs once and is gone. The job lands in the delayed sorted set scored by its fire-time. EchoMQ builds the key with `EchoMQ.Keys.delayed/1`, which returns `"#{base}:delayed"` → `emq:{queue}:delayed`, and scores the member with `getDelayedScore` in `addDelayedJob-6.lua`: `score = delayedTimestamp × 0x1000`, so the low twelve bits discriminate jobs due in the same millisecond. When the clock reaches the score, the included `promoteDelayedJobs` sweep — `ZRANGEBYSCORE delayedKey 0 (timestamp + 1) × 0x1000 - 1 LIMIT 0 1000`, then `ZREM` the due head — moves the reminder to the wait list and a worker delivers it.

The takeaway: the reminder is one member in `:delayed`, scored by when it should fire; the sweep promotes it when due, and the shift by `0x1000` keeps a millisecond able to hold more than one ordered job.

## The weekly digest — a repeatable job, upserted (R4.02)

Every Monday at 09:00 each learner gets a progress digest. That is a recurring schedule, not a one-shot, so it lives in the repeat registry: a sorted set scored by the *next* run time, one entry per scheduler. EchoMQ builds the key with `EchoMQ.Keys.repeat/1` → `"#{base}:repeat"` → `emq:{queue}:repeat`. Registering the schedule runs `storeRepeatableJob` in `addRepeatableJob-2.lua`: `ZADD repeatKey nextMillis customKey`, guarded by a `ZSCORE repeatKey customKey` probe above it. The probe is what makes a reboot safe — a service that boots re-registers all its schedules, and re-adding the same member rewrites its score rather than appending a second row. One schedule key, one registry entry, across any number of boots; no duplicate digest on restart.

The takeaway: the digest is one entry in `:repeat`, scored by its next run and rewritten each fire; the `ZSCORE`-then-`ZADD` upsert keeps the registry at one row per scheduler, so a boot adds no duplicate.

## The password-reset email — a priority job (R4.03)

A learner requests a password reset. That email cannot wait behind a backlog of bulk marketing mail — it jumps ahead. EchoMQ enqueues it on the prioritized sorted set, built with `EchoMQ.Keys.prioritized/1` → `"#{base}:prioritized"` → `emq:{queue}:prioritized`, and scores it with `getPriorityScore` in `addPrioritizedJob-9.lua`: `priority × 0x100000000 + (INCR pc)`. `0x100000000` is `2^32`, so the priority tier sits in the high thirty-two bits and the arrival counter in the low thirty-two. The counter is the value of `INCR` on the priority-counter key — `EchoMQ.Keys.pc/1` → `"#{base}:pc"` — taken when the job is added, so two jobs in the same tier order by arrival. A worker pops the next job with `ZPOPMIN` in `moveToActive-11.lua`: the smallest score is the highest-precedence tier and, within it, the earliest arrival. A *lower* priority number wins, because the formula makes a higher-precedence job a smaller number and `ZPOPMIN` always returns the smallest first.

The takeaway: the reset email is one member in `:prioritized`, scored by `priority × 0x100000000 + (INCR pc)`; one `ZPOPMIN` returns the right job — tier first, arrival second — so it pops ahead of the bulk mail.

## The failed send — a backed-off retry (R4.04)

A digest email fails: the mail provider returns a transient error. The worker does not drop the job and does not loop on it. It re-schedules the job to run again later, with a delay that grows on each attempt, so a struggling provider is not hammered. The delay is sized by `EchoMQ.Backoff.calculate/4` in Elixir — the `:exponential` clause computes `delay = trunc(:math.pow(2, attempt - 1) × base_delay)`, then `apply_jitter(delay, jitter)`. The doc example is exact: `calculate(:exponential, 3, 1000, jitter: 0.2)` returns about `4000`. Jitter widens each delay into a band — `[3200, 4800]` for that example — and draws an independent point per job, so a batch that failed together does not re-fire in one synchronized spike. The reschedule itself adds no new structure: `retryJob-11.lua` re-adds the failed job to `emq:{queue}:delayed` at the backoff fire-time, and the included `promoteDelayedJobs` — R4.01's sweep — brings it back when due. The formula chooses the delay; the Lua never computes `2^(n-1)`.

The takeaway: the failed send is a delayed job whose fire-time is a backoff delay; `EchoMQ.Backoff.calculate/4` sizes it, the same `:delayed` set holds it, and the same sweep promotes it — one structure, two uses.

## The ranking the digest carries — a sorted-set ranking (R4.05)

The digest's content names the week's top learners. That is a ranking: order learners by their progress, read the top-N. Portal records a learner's progress through a lesson as a percent — the `Portal.Enrollment.Progress` struct, the field `percent :: 0..100`, the namespace `PRG`, held as a row in an in-memory, namespace-partitioned store. **Portal runs no Redis sorted set and has no progress ranking; the percent is a plain stored value.** A leaderboard that ranks learners by progress is exactly this pattern applied to that data: score each learner by their percent — `ZADD board <percent> <learner>` — and the top-N learners are a `ZREVRANGE`, a learner's standing is a `ZREVRANK`, and an around-me view is a rank-range read. The rank is computed on read in `O(log N)`, never stored. Stated plainly and counterfactually: Portal stores progress as a percent today, and the sorted-set ranking is the ordinary structure to reach for when a ranked view of that percent is wanted.

The takeaway: the ranking is the leaderboard pattern over the progress percent Portal already records; Portal stores the percent and the ranked view over it is one sorted set away — no rank is stored, the order is the rank.

## The bridge — five patterns, one sorted set

- **The chapter.** Five patterns: the delayed queue (R4.01), the scheduler (R4.02), the composite priority score (R4.03), backoff-and-retry (R4.04), and the leaderboard (R4.05) — each a different reading of one structure.
- **This workshop.** One Portal LMS scenario reads the sorted set five ways: a fire-time clock (`:delayed`), a recurrence registry (`:repeat`), a priority ladder (`:prioritized`), a retry timer (`:delayed` reused), and a ranking — all the same `ZADD` / range / pop machinery, scored by a number whose meaning the pattern chooses.

The takeaway: the chapter's five patterns are one sorted set read five times. The score is a fire-time, a next-run, a packed priority, a backoff delay, or a player's points — and the structure never changes, only the meaning poured into the score.

## Where this is heading — EchoMQ 2.0

Today every job in this scenario rides the v1.x BullMQ-compatible wire: the reminder and the retry on `emq:{queue}:delayed`, the digest on `emq:{queue}:repeat`, the reset email on `emq:{queue}:prioritized`. The settled **EchoMQ 2.0** design — the protocol break on the first EMQ rung, `emq.1` — drops BullMQ compatibility (the v1 line freezes at `1.3.0`), renames the whole keyspace to the native `emq:` prefix (`emq:{queue}:delayed`, `emq:{queue}:repeat`, `emq:{queue}:prioritized`; the `{queue}` hashtag applied transparently in the core, the braced `{emq}:` base reserved for the core's own keys), declares every Lua key in `KEYS[]` — the inherited undeclared-keys flaw resolved at the root — and bumps `meta.version` from `bullmq:5.65.1` to `echomq:2.0.0` behind a two-way typed boot fence, DragonflyDB-native. The whole scenario is unchanged by the break. The fire-time score, the upsert, the composite priority score, the backoff delay, and the ranking are each a property of the sorted set — the score, the sweep, the pop, the rank — not of the prefix it rides on. The break renames the keyspace and declares the keys; every pattern in this workshop carries over byte-for-byte. That is why the chapter is safe to teach before EchoMQ 2.0 ships: it teaches the sorted set, and the prefix it rides on is the part that changes.

## Grounded in EchoMQ's real scheduler

Every symbol in this scenario is a real surface in `echo/apps/echomq` and `echo/apps/portal`, cited as proof the patterns ship:

- The delayed key and score — `EchoMQ.Keys.delayed/1`, `getDelayedScore` (`score = delayedTimestamp × 0x1000`) in `addDelayedJob-6.lua`, swept by the included `promoteDelayedJobs`.
- The repeat registry — `EchoMQ.Keys.repeat/1`, `storeRepeatableJob`'s `ZADD repeatKey nextMillis customKey` probed by `ZSCORE` in `addRepeatableJob-2.lua`.
- The priority score — `EchoMQ.Keys.prioritized/1`, `getPriorityScore` (`priority × 0x100000000 + (INCR pc)`) in `addPrioritizedJob-9.lua`, the counter key `EchoMQ.Keys.pc/1`, consumed by `ZPOPMIN` in `moveToActive-11.lua`.
- The backoff delay — `EchoMQ.Backoff.calculate/4` (`:exponential` → `trunc(:math.pow(2, attempt - 1) × base_delay)`, then `apply_jitter`); `retryJob-11.lua` re-adds onto `:delayed`.
- The ranking data — `Portal.Enrollment.Progress` (`percent :: 0..100`, namespace `PRG`); Portal runs no sorted set, so the ranking is the applied pattern, phrased counterfactually.

This workshop cites one excerpt of each move as a door, not a depth. The full scheduler subsystem — the cron parser, the delay/promote/retry coordination across a worker pool, the polyglot concurrency models — is the subject of the dedicated **EchoMQ course**, which opens at `/echomq/lifecycle` (E6 · Lifecycle controls). This workshop closes R4 with five patterns over one sorted set; that course teaches the scheduler that runs them.

## References

### Sources

- [Redis — *ZADD*](https://redis.io/commands/zadd/) — the single write behind every move: the fire-time score, the repeat upsert, the priority score, the leaderboard score.
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — the due-range read inside `promoteDelayedJobs` that promotes the reminder and the retry.
- [Redis — *ZPOPMIN*](https://redis.io/commands/zpopmin/) — pop the smallest composite score: the highest-precedence tier, earliest arrival — how the reset email jumps the queue.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the one structure the scenario reads five ways: members ordered by a numeric score.
- [BullMQ — *the queue protocol*](https://bullmq.io/) — the `:delayed` / `:repeat` / `:prioritized` protocol EchoMQ ports, where the Lua scripts are the protocol.
- [DragonflyDB — *BullMQ on Dragonfly*](https://www.dragonflydb.io/docs/integrations/bullmq) — the BullMQ-on-Dragonfly direction EchoMQ 2.0 takes native, prefix renamed and keys fully declared.

### Related in this course

- R4.01 · The delayed queue — `/redis-patterns/time-delay-priority/delayed-queue`
- R4.02 · Schedulers & repeatable jobs — `/redis-patterns/time-delay-priority/schedulers`
- R4.03 · Priority with composite scores — `/redis-patterns/time-delay-priority/priority-scores`
- R4.04 · Backoff & retry — `/redis-patterns/time-delay-priority/backoff-retry`
- R4.05 · Leaderboards — `/redis-patterns/time-delay-priority/leaderboards`
- R4 · Time, Delay & Priority — `/redis-patterns/time-delay-priority`
- E6 · Lifecycle controls — `/echomq/lifecycle`
