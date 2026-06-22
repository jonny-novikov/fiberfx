# R4.02.1 · Cron vs interval

> Route: `/redis-patterns/time-delay-priority/schedulers/cron-vs-interval` · dive 1

**Two ways to name "when next": a cron expression names a wall-clock calendar position, a fixed interval names a gap. Both reduce to one millisecond timestamp — the score the registry stores.**

A scheduler needs a rule for the next run. There are two such rules, and they answer different questions. A cron expression answers *which calendar slot* — every day at 09:00, the first of every month. A fixed interval answers *how long a gap* — every fifteen minutes, every six hours. Whichever rule a schedule uses, the registry stores the same thing: one millisecond timestamp, the score of the scheduler's single sorted-set entry.

## The cron expression — a wall-clock slot

A cron expression is five fields — minute, hour, day-of-month, month, day-of-week. `0 9 * * *` reads "minute 0, hour 9, any day, any month, any weekday" — 09:00 every day. The next run is the earliest calendar slot at or after the current time that the expression matches. Cron anchors to the wall clock, so a daily-at-09:00 schedule fires at 09:00 regardless of when it last ran or how long the last run took.

## The fixed interval — a gap

A fixed interval is a single number of milliseconds — `every: 900000` is fifteen minutes. The next run is the previous run plus the gap. An interval anchors to its own previous run rather than to the calendar, so an interval-every-15-min schedule fires at :00, :15, :30, :45 past whatever minute it started on, marching forward by the gap.

EchoMQ's scheduler keeps the interval on a per-scheduler options hash. In `addRepeatableJob-2.lua`, `storeRepeatableJob` writes the cadence fields with `HMSET repeatKey .. ":" .. customKey "name" ... "pattern" ... "every" ...` — the cron `pattern` and the interval `every` are both stored, alongside an optional `tz`. The registry sorted set stores only the computed next-run millisecond; the rule that produced it lives in the companion hash.

## Both reduce to one timestamp

The two rules compute differently but produce the same kind of value: a future millisecond. That single number is the score `ZADD`'d into the registry against the scheduler's member. The registry does not care whether the next run came from a calendar match or a gap addition — it stores a sorted set of next-run times and pops the earliest. Naming the cadence is the only place the two rules differ; downstream, a cron schedule and an interval schedule are the same one-entry-scored-by-next-run row.

## In EchoMQ — pattern and every on the options hash

The store function `storeRepeatableJob(repeatKey, customKey, nextMillis, rawOpts)` is given `nextMillis` already computed by the caller, and it records two things: the next-run time on the registry sorted set, and the cadence on the companion hash.

```
-- addRepeatableJob-2.lua · storeRepeatableJob (real)
rcall("ZADD", repeatKey, nextMillis, customKey)          -- the next run, on the registry ZSET
rcall("HMSET", repeatKey .. ":" .. customKey,            -- the cadence, on a separate hash
  "name", opts['name'], "pattern", opts['pattern'], "every", opts['every'])
```

The `pattern` field holds the cron expression; the `every` field holds the interval. EchoMQ stores both so a schedule can be defined either way; only one is set per scheduler. The cron-parser depth — how `pattern` plus `tz` resolves a calendar slot across daylight-saving transitions — belongs to the scheduler subsystem the EchoMQ course covers (E6 · Lifecycle controls). This dive teaches the two cadence shapes and the single timestamp they both become.

## The pattern, applied

A textbook delayed queue scores a job by one fixed fire-time. A scheduler computes that fire-time from a cadence rule each cycle. Cron and interval are the two rules; the registry stores their output, never the rule itself.

## References

### Sources

- [Cron — Wikipedia](https://en.wikipedia.org/wiki/Cron) — the five-field cron expression as a calendar cadence spec.
- [Redis — ZADD](https://redis.io/commands/zadd/) — the command that writes the computed next-run millisecond as the registry score.
- [Redis — Sorted sets](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the registry of next-run times both cadences feed.
- [BullMQ — the queue protocol](https://bullmq.io/) — the repeatable-jobs cadence options (`pattern`, `every`, `tz`) EchoMQ ports.

### Related in this course

- [R4.02 · Schedulers & repeatable jobs](/redis-patterns/time-delay-priority/schedulers) — the module hub.
- [R4.02.2 · The upsert, no duplicates](/redis-patterns/time-delay-priority/schedulers/upsert-no-duplicates) — storing the computed next-run without duplicating.
- [R4.02.3 · Start-to-start cadence](/redis-patterns/time-delay-priority/schedulers/start-to-start-cadence) — producing the next run from the cadence.
- [R4 · Score as meaning](/redis-patterns/time-delay-priority/score-as-meaning) — the `:repeat` ZSET in the orientation arc.
- [E6 · Lifecycle controls](/echomq/lifecycle) — the EchoMQ course: cron parsing, timezones, and the scheduler subsystem.
