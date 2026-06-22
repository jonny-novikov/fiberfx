# R4.02 · Schedulers & repeatable jobs

> Route: `/redis-patterns/time-delay-priority/schedulers` · module hub

**A repeatable job is a delayed job that re-schedules itself: a sorted set holds one entry per scheduler, scored by the next run time, and each time the job fires the next timestamp is computed and the score rewritten — so the recurrence survives restarts without ever duplicating.**

The delayed-queue pattern schedules one future run by scoring a job in a sorted set with the timestamp it should fire. A scheduler carries that one move forward: it keeps a registry of recurring schedules, one entry per scheduler, each scored by *when it next runs*. When the job fires, the next run time is computed and the same entry's score is rewritten. The registry never grows past one row per scheduler, and a restart that re-registers the same cron or interval finds the row already present and rewrites it rather than adding a second.

## What a scheduler adds over a one-shot delay

A one-shot delayed job is a member in the `:delayed` sorted set scored by its fire-time. It runs once and is gone. A scheduler adds three things on top:

- a **cadence** — a rule for "when next" (a cron expression or a fixed interval), evaluated to a timestamp;
- a **registry** — a separate sorted set, scored by the next run time, holding one entry per recurring schedule;
- an **upsert** — registering a schedule that already exists rewrites its single entry rather than appending a duplicate.

The score is still a future timestamp, exactly as in the delayed queue. The new idea is that the entry is rewritten each cycle instead of consumed once.

## Naming the cadence (cron vs interval)

There are two ways to name *when next*. A **cron expression** (`0 9 * * *`) names a wall-clock calendar position — every day at 09:00 — and the next run is the next calendar slot at or after now. A **fixed interval** (`every: 900000` ms) names a gap — every fifteen minutes — and the next run is the previous run plus the gap. Both reduce to a single millisecond timestamp, which is the score the registry stores. The first dive computes the next run each way over a fixed clock.

## The repeat registry (a sorted set of next-run times)

The registry is a sorted set scored by the next run time. The member is the scheduler's own key; the score is the millisecond at which it next fires. EchoMQ builds this key with `EchoMQ.Keys.repeat/1`, which returns `"#{base}:repeat"`. The behaviour is a sorted set: `ZADD repeatKey nextMillis customKey` to record, `ZSCORE repeatKey customKey` to read the prior next-run time. Per-scheduler options — the name, the cron pattern, the interval, the timezone — live in a *separate hash* at `repeatKey .. ":" .. customKey`, written with `HMSET`; the registry sorted set carries only the next-run times.

> Note on the source: the `keys.ex` doc-comment labels `:repeat` a "hash". The code's `ZADD` / `ZSCORE` calls are the ground truth — the registry is used as a sorted set. The hash the comment loosely points at is the companion per-scheduler options hash, a separate key.

## The upsert (no duplicate on boot)

A service that boots re-registers all its schedules. A naive add would push a second entry for a schedule that already exists, and the recurring job would fire twice. The upsert prevents that. Before adding, the script probes the registry: `local prevMillis = rcall("ZSCORE", repeatKey, customKey)`. If a prior entry exists, the script reconciles the stale delayed entry instead of adding a second scheduler; the store itself is `rcall("ZADD", repeatKey, nextMillis, customKey)`, and re-adding the same member rewrites its score rather than appending a row. One scheduler key, one registry entry, across any number of boots. The second dive runs two boots over the same scheduler key and counts the entries.

## Producing the next run (start-to-start)

The registry holds only the *next* run, never a queue of future runs. When a job is produced, the next run time is computed from the cadence and the registry's single entry is rewritten with the new score. The next run is measured **start-to-start** — from this run's scheduled time plus the interval — not start-to-finish. Measuring from the finish would let a slow job push every later run later and drift the schedule; measuring start-to-start keeps the cadence anchored to the clock. When the next run is known, EchoMQ also writes the wake marker — `ZADD markerKey nextTimestamp "1"` — so a blocked worker wakes at the next run rather than on a poll tick. The third dive compares start-to-start against start-to-finish and shows the drift.

## When to use

- recurring work on a calendar or a fixed cadence — periodic reports, cleanup sweeps, polling an upstream;
- schedules that must survive a restart without re-firing or duplicating;
- a small-to-moderate number of named schedules, each with its own cron or interval.

## When to avoid

- sub-second or hard-real-time cadences — a sorted-set registry polled by a worker is millisecond-grained, not a real-time scheduler;
- enormous fan-outs of distinct one-off future runs (millions of independent timestamps) — those are delayed jobs, not schedules, and belong in `:delayed`;
- cadences that need full calendar correctness across timezones and daylight-saving transitions at the edge — that parsing depth belongs to EchoMQ's scheduler subsystem, the EchoMQ course's territory.

## In EchoMQ — the registry that does not duplicate

A textbook delayed queue can already schedule one future run. A scheduler makes the run re-schedule itself. EchoMQ keeps exactly one `:repeat` entry per scheduler key and upserts it by `ZSCORE`, so a restart re-registering the same cron or interval finds the entry already present and rewrites its score rather than spawning a duplicate.

The store is `storeRepeatableJob(repeatKey, customKey, nextMillis, rawOpts)` in `addRepeatableJob-2.lua`, whose first line is `rcall("ZADD", repeatKey, nextMillis, customKey)` — score is the next-run millisecond, member is the scheduler's custom key. The idempotence comes from the probe above it: `local prevMillis = rcall("ZSCORE", repeatKey, customKey)`; a present prior entry is reconciled, not duplicated. The newer scheduler API, `storeJobScheduler(...)` in `addJobScheduler-11.lua`, writes the same registry sorted set keyed by a scheduler id: `rcall("ZADD", repeatKey, nextMillis, schedulerId)`.

The full cron parser, the timezone and daylight-saving handling, and the scheduler-vs-delayed reconciliation across a worker pool are the subject of the dedicated EchoMQ course — E6 · Lifecycle controls. This module teaches the registry and its upsert; that course teaches the scheduler subsystem that maintains it.

## The three dives

| # | Dive | Teaches |
|---|---|---|
| R4.02.1 | Cron vs interval | two ways to name "when next" — a cron expression (wall-clock calendar) vs a fixed interval (every N ms); each produces the next-run timestamp the registry is scored by |
| R4.02.2 | The upsert, no duplicates | a reboot re-registers the same scheduler; the `ZSCORE`-then-`ZADD` upsert keeps exactly one registry entry per scheduler key |
| R4.02.3 | Start-to-start cadence | the registry holds only the next run; when a job is produced the next timestamp is computed and the score rewritten — start-to-start, not start-to-finish |

## References

### Sources

- [Redis — ZADD](https://redis.io/commands/zadd/) — the upsert: re-`ZADD` the same member to rewrite its next-run score.
- [Redis — ZSCORE](https://redis.io/commands/zscore/) — the probe that makes the add idempotent: read the prior next-run time before storing.
- [Redis — Sorted sets](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the registry as a sorted set of next-run times.
- [BullMQ — the queue protocol](https://bullmq.io/) — the repeatable-jobs / job-schedulers protocol EchoMQ ports.
- [Cron — Wikipedia](https://en.wikipedia.org/wiki/Cron) — the cron expression as a cadence spec.

### Related in this course

- [R4.02.1 · Cron vs interval](/redis-patterns/time-delay-priority/schedulers/cron-vs-interval) — naming the cadence.
- [R4.02.2 · The upsert, no duplicates](/redis-patterns/time-delay-priority/schedulers/upsert-no-duplicates) — one entry per scheduler key.
- [R4.02.3 · Start-to-start cadence](/redis-patterns/time-delay-priority/schedulers/start-to-start-cadence) — rewriting the single next-run score.
- [R4 · Score as meaning](/redis-patterns/time-delay-priority/score-as-meaning) — the orientation dive that names the `:repeat` ZSET.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [E6 · Lifecycle controls](/echomq/lifecycle) — the EchoMQ course: the scheduler subsystem in depth.
