# R4.02.1 · Cron vs interval

> Route: `/redis-patterns/time-delay-priority/schedulers/cron-vs-interval` · dive 1

**Two ways to name "when next": a cron expression names a wall-clock calendar position, a fixed interval names a gap. Both reduce to one millisecond timestamp — the score the registry stores.**

A scheduler needs a rule for the next run. There are two such rules, and they answer different questions. A cron expression answers *which calendar slot* — every day at 09:00, the first of every month. A fixed interval answers *how long a gap* — every fifteen minutes, every six hours. Whichever rule a registration uses, the registry stores the same thing: one millisecond timestamp, the score of the registration's single sorted-set entry. EchoMQ's `EchoMQ.Repeat` is the interval form — it carries an `every_ms` period — and this dive shows that the cron rule produces the same kind of value the interval rule does.

## The cron expression — a wall-clock slot

A cron expression is five fields — minute, hour, day-of-month, month, day-of-week. `0 9 * * *` reads "minute 0, hour 9, any day, any month, any weekday" — 09:00 every day. The next run is the earliest calendar slot at or after the current time that the expression matches. Cron anchors to the wall clock, so a daily-at-09:00 schedule fires at 09:00 regardless of when it last ran or how long the last run took.

## The fixed interval — a gap

A fixed interval is a single number of milliseconds — `every_ms: 900000` is fifteen minutes. The next run is the previous run plus the gap. An interval anchors to its own previous run rather than to the calendar, so an interval-every-15-min schedule fires at :00, :15, :30, :45 past whatever minute it started on, marching forward by the gap. `EchoMQ.Repeat` is exactly this: registration takes `every_ms`, the record hash stores it, and the pump advances the score by it each cycle.

## Both reduce to one timestamp

The two rules compute differently but produce the same kind of value: a future millisecond. That single number is the score `ZADD`'d into the registry against the registration's member. The registry does not separate a calendar match from a gap addition — it stores a sorted set of next-run times and the pump reads the earliest. Naming the cadence is the only place the two rules differ; downstream, a cron schedule and an interval schedule are the same one-entry-scored-by-next-run row.

## In EchoMQ — every_ms on the record hash

`EchoMQ.Repeat.register/6` takes a period in milliseconds and a payload template, and writes both the registry entry and a companion record hash in one inline Lua script. The script's first move is the idempotence probe; on a fresh name it writes the record then the registry score:

```
-- @register (EchoMQ.Repeat, verbatim)
if redis.call('EXISTS', KEYS[2]) == 1 then
  return 0
end
redis.call('HSET', KEYS[2], 'every_ms', ARGV[2], 'template', ARGV[3])
redis.call('ZADD', KEYS[1], tonumber(ARGV[4]), ARGV[1])
return 1
```

`KEYS[1]` is `emq:{q}:repeat` (the registry sorted set), `KEYS[2]` is `emq:{q}:repeat:<name>` (the record hash). `ARGV[2]` is `every_ms` — the interval — and `ARGV[3]` is the payload `template`. `ARGV[4]` is the first run's millisecond, the registry score. The interval lives on the record hash; the registry sorted set stores only the computed next-run time. The cron-parser depth — how a `pattern` plus a timezone resolves a calendar slot across daylight-saving transitions — belongs to the scheduler subsystem the EchoMQ course covers; `EchoMQ.Repeat` ships the interval form. This dive teaches the two cadence shapes and the single timestamp they both become.

## The pattern, applied

A textbook delayed queue scores a job by one fixed fire-time. A scheduler computes that fire-time from a cadence rule each cycle. Cron and interval are the two rules; the registry stores their output, never the rule itself, and `EchoMQ.Repeat` carries the interval rule as `every_ms`.

## References

### Sources

- [Cron — Wikipedia](https://en.wikipedia.org/wiki/Cron) — the five-field cron expression as a calendar cadence spec.
- [Redis — ZADD](https://redis.io/commands/zadd/) — the command that writes the computed next-run millisecond as the registry score.
- [Valkey — Sorted sets](https://valkey.io/topics/sorted-sets/) — the registry of next-run times both cadences feed.
- [Redis — HSET](https://redis.io/commands/hset/) — the record hash that carries `every_ms` and the payload template beside the registry.

### Related in this course

- [R4.02 · Schedulers & repeatable jobs](/redis-patterns/time-delay-priority/schedulers) — the module hub.
- [R4.02.2 · The upsert, no duplicates](/redis-patterns/time-delay-priority/schedulers/upsert-no-duplicates) — storing the computed next-run without duplicating.
- [R4.02.3 · Start-to-start cadence](/redis-patterns/time-delay-priority/schedulers/start-to-start-cadence) — producing the next run from the cadence.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [The Queue, in depth](/echomq/queue) — the EchoMQ course: cron parsing, timezones, and the scheduling controls.
