# R4 · Time, Delay & Priority — the sorted set as a clock

> Route: `/redis-patterns/time-delay-priority` · chapter landing (route manifest)

One data structure, read two ways: score a job by a future time and the set is a timer wheel; score it by a priority
and the set is a ladder.

A sorted set keeps its members ordered by a numeric score, and that is the whole chapter. Score a job by its
fire-time and a range query pulls out everything now due — a delayed queue. Pack a priority and an arrival counter
into one score and the smallest entry is the next to run — a priority queue with FIFO inside each tier. Score by
next-run time and the set is a scheduler registry. EchoMQ uses exactly this: `emq:{queue}:delayed` scores by
`timestamp × 0x1000`, `emq:{queue}:prioritized` by `priority × 2³² + arrival`, and `EchoMQ.Backoff` reschedules a
failed job onto the same delayed set. It stands on R3's reliable queue.

## Overview

R3 makes a job reliable: it can be delivered now, once, and recovered if a worker dies. It cannot yet be held for
later, recurred on a schedule, ordered by importance, or backed off after a failure. Every one of those is a property
of *when* and *in what order* a job runs — and every one is a sorted set whose score carries the answer.

A Redis sorted set (ZSET) stores members ordered by a numeric score, with range queries by score and a pop of the
smallest. Put a future timestamp in the score and `ZRANGEBYSCORE 0 now` returns the jobs whose time has come; the
textbook delayed queue is exactly that. Put a composite of priority and arrival in the score and `ZPOPMIN` returns the
most important job, oldest-first within a tier. The commands never change; the meaning of the score does.

EchoMQ runs both readings in real code. `addDelayedJob-6.lua` scores the delayed set by `(timestamp + delay) × 0x1000`
— the millisecond shifted left twelve bits so a low-bit discriminator keeps a stable order inside one millisecond —
and a `promoteDelayedJobs` sweep ranges the due head to the wait list. `getPriorityScore` packs
`priority × 0x100000000 + INCR pc` into one double so the priority set pops by tier then arrival. The same machinery
underlies schedulers, backoff, and leaderboards.

**Take.** A delayed queue and a priority queue are the same sorted set under two readings of the score — `ZADD` to
insert, a range or a pop to read.

## Why & when

Reach for the sorted set whenever a job's *time* or its *order* matters — not only whether it runs, but when and after
which others. Each need below maps to one score reading.

- **Run a job later** — a reminder, a deferred email, a cooldown — score the job by its fire-time and sweep the due
  head with a range query.
- **Recur a job without duplicates** — a nightly digest, a polling task — register it in a scheduler set keyed by
  next-run time, upserted so a reboot adds no duplicate.
- **Order a queue by priority** — paid before free, urgent before routine — pack priority and arrival into one score
  so the queue is strict by tier, FIFO inside it.
- **Retry after a failure** — back off so a failing dependency is not hammered — reschedule onto the delayed set with
  an exponential delay plus jitter.

**Take.** Every technique in this chapter answers one question about a job — run it when, recur it how often, run it
before which others, retry it after how long — and every answer is a sorted-set score.

## The patterns

Three orientation dives carry the chapter, then six granular modules take each pattern in depth.

**Orientation dives (built):**

- **The sorted set as a clock** (`/redis-patterns/time-delay-priority/the-sorted-set-as-a-clock`) — one ZSET, two
  readings: a timer wheel (`:delayed`, score = fire-time) and a priority ladder (`:prioritized`, score = composite).
- **Score as meaning** (`/redis-patterns/time-delay-priority/score-as-meaning`) — the score is the semantics:
  fire-time (`ts×0x1000`), composite priority (`priority×2³²+pc`), next-run millis (`:repeat`). Same commands, three
  meanings.
- **The road ahead** (`/redis-patterns/time-delay-priority/the-road-ahead`) — the arc R4.01→R4.06 and the door into
  the EchoMQ scheduler subsystem.

**Granular modules (planned):**

- **R4.01 · The delayed queue** — score a job by its fire-time, sweep by score: the `:delayed` ZSET and the
  `promoteDelayedJobs` range.
- **R4.02 · Schedulers & repeatable jobs** — recurring jobs via cron or interval on the `:repeat` ZSET, upserted so a
  boot adds no duplicate.
- **R4.03 · Priority with composite scores** — pack priority and arrival into one score: `getPriorityScore` =
  `priority×0x100000000+pc`.
- **R4.04 · Backoff & retry** — exponential backoff with jitter on the same delayed set: `EchoMQ.Backoff` =
  `base×2^(n-1)`.
- **R4.05 · Leaderboards** — real-time rankings on the same ZSET machinery, over Portal progress.
- **R4.06 · Workshop** — the capstone: schedule Portal's notification and digest jobs on the `:delayed`/`:repeat`
  sets.

## How to apply

The choice is always the same one question: what does the job's score need to mean?

- **Run a job later** → the delayed queue (`emq:{queue}:delayed` · `addDelayedJob-6.lua`): store `(timestamp +
  delay) × 0x1000`, then a `promoteDelayedJobs` sweep ranges `0 → now` and moves the due head to the wait list.
- **Recur without duplicates** → the scheduler registry (`emq:{queue}:repeat` · `addRepeatableJob-2.lua`): register
  in the `:repeat` ZSET scored by next-run time; the add upserts via `ZSCORE` so a reboot replaces rather than
  duplicates.
- **Order by priority** → the composite priority score (`emq:{queue}:prioritized` · `getPriorityScore`): pack
  `priority × 0x100000000 + (INCR pc)`; `ZPOPMIN` returns strict priority then FIFO within the tier.
- **Retry after a failure** → exponential backoff on the delayed set (`EchoMQ.Backoff.calculate/4` · `retryJob-11.lua`):
  `calculate(:exponential, attempt, base)` returns `base × 2^(attempt-1)`, optionally with jitter, and `retryJob`
  re-adds the job with that delay.

**Take.** There is no separate data structure for time and for priority — only the sorted set, and the score you
choose to give it.

## The road ahead

R4 adds the time and order axes to R3's reliable job. The later chapters are further surfaces over the same jobs: R5
Streams & Events (the durable log), R6 Flow Control (staying stable under load, with priority as the fairness lever),
R7 Data Modeling (the job record and the leaderboard sets), R8 Production & Operations (running the scheduled,
prioritized queue at scale).

## The door

This chapter teaches the sorted-set time and priority patterns and proves each with one real EchoMQ excerpt. The
**scheduler subsystem** that runs them — the timezone and DST rules of a cron schedule, the guard that holds a job
while its slot is busy, the migration of legacy repeatable jobs, and the scheduling of parent-child job flows — is the
subject of the dedicated EchoMQ course.

→ **EchoMQ.** Per its cross-link map, R4 opens onto **E6 · Lifecycle controls** (`/echomq/lifecycle` — the TTL clock,
the delay and promote path, the retry/checkpoint machinery) and **E4 · Groups** (`/echomq/groups` — intra-group
priority and the control plane). The course home is `/echomq`.

## References

### Sources

- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the data type that orders
  members by score, the substrate for the whole chapter.
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — the range query that sweeps the due head of a
  delayed set.
- [Redis — *ZPOPMIN*](https://redis.io/commands/zpopmin/) — the pop of the smallest score, the priority queue's read.
- [BullMQ — *Delayed & prioritized jobs*](https://bullmq.io/) — the protocol EchoMQ ports across runtimes.

### Related in this course

- [R3 · Reliable Queues](/redis-patterns/queues) — the reliable job this chapter schedules and orders.
- [R3.05 · Blocking vs polling](/redis-patterns/queues/blocking-vs-polling) — the marker the delayed set wakes a
  worker through.
- [R0.2 · Redis under Portal](/redis-patterns/overview/redis-under-game) — the EchoMQ bus these patterns ground in.
- [/elixir · The GenServer](/elixir/language/otp/genserver) — the runtime process the scheduler's timers run inside.
