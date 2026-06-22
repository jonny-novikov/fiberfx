# R4.02.3 · Start-to-start cadence

> Route: `/redis-patterns/time-delay-priority/schedulers/start-to-start-cadence` · dive 3

**The registry holds only the next run. When a job is produced the next timestamp is computed and the single score rewritten — start-to-start, anchored to the clock, not start-to-finish.**

A scheduler does not pre-compute a queue of future runs. It keeps exactly one entry per schedule, scored by the *next* run, and rewrites that score each time the job is produced. The question is what the next run is measured from. Start-to-start measures from this run's scheduled time plus the interval, so the cadence stays anchored to the clock. Start-to-finish measures from when this run *finished*, so a slow run pushes every later run later and the schedule drifts. EchoMQ measures start-to-start.

## One entry, rewritten each cycle

The registry is a sorted set scored by next-run time. A schedule occupies one member. When the scheduler produces the next job, it computes the next run from the cadence and `ZADD`s the new score against the same member — rewriting the single entry, not appending a new one. The registry's size is the number of distinct schedules, never the number of runs. A schedule that has fired ten thousand times still holds exactly one row.

## Start-to-start vs start-to-finish

Consider an every-15-minute schedule where a run takes 4 minutes. Start-to-start: the run scheduled for 09:00 produces the next at 09:15, the one after at 09:30 — the cadence is anchored to the clock and the 4-minute run does not move it. Start-to-finish: the 09:00 run finishes at 09:04, so the next is scheduled for 09:19, which finishes at 09:23, so the next is 09:38 — every run drifts later by the run duration, and after enough cycles the schedule has slid far off the clock. Start-to-start keeps fifteen-minute marks at :00, :15, :30, :45; start-to-finish lets them creep.

The interval scheduler in `addJobScheduler-11.lua` computes the next millisecond from the previous scheduled millisecond plus `every`, not from a finish time: `nextMillis = prevMillis + every`, then snaps to the next slot if that has already passed. The cadence is derived from the schedule, never from how long a run took.

## The marker rings at the next run

Once the next run is known, the scheduler writes the wake marker so a blocked worker wakes at the right moment rather than on a poll tick. In `addJobScheduler-11.lua`, `addDelayMarkerIfNeeded` runs `rcall("ZADD", markerKey, nextTimestamp, "1")` — the marker carries the next fire-time as its score, the same marker mechanism the blocking-vs-polling module uses, here scored by the scheduler's next run. The worker parked on the marker wakes exactly when the next scheduled run is due.

## In EchoMQ — next-millis from the schedule

The interval path computes the next run start-to-start and rewrites the single registry entry:

```
-- addJobScheduler-11.lua (real)
nextMillis = prevMillis + every                 -- start-to-start: from the prior scheduled time
if nextMillis < now then
  nextMillis = math.floor(now / every) * every + every   -- snap forward to the next slot
end
-- storeJobScheduler rewrites the one registry entry
rcall("ZADD", repeatKey, nextMillis, schedulerId)
rcall("ZADD", markerKey, nextTimestamp, "1")    -- wake the worker at the next run
```

`prevMillis + every` is the start-to-start step; the snap-forward handles a missed slot without abandoning the clock anchor. The full scheduler-vs-delayed reconciliation across a worker pool — how a missed run, an overlapping run, and a paused queue interact — is the scheduler subsystem the EchoMQ course covers (E6 · Lifecycle controls). This dive teaches the start-to-start rewrite and the marker that rings at the next run.

## The pattern, applied

A textbook delayed queue scores one run and is done. A scheduler rewrites its single score each cycle, and *how* it computes the next score governs whether the cadence holds. Start-to-start anchors to the clock; the registry stays one entry; the marker rings at the next run.

## References

### Sources

- [Redis — ZADD](https://redis.io/commands/zadd/) — rewriting the single registry score with the start-to-start next-run time.
- [Redis — ZSCORE](https://redis.io/commands/zscore/) — reading the prior scheduled time the next run is measured from.
- [Redis — Sorted sets](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the one-entry-per-schedule registry rewritten each cycle.
- [BullMQ — the queue protocol](https://bullmq.io/) — the job-scheduler cadence path EchoMQ ports.

### Related in this course

- [R4.02 · Schedulers & repeatable jobs](/redis-patterns/time-delay-priority/schedulers) — the module hub.
- [R4.02.1 · Cron vs interval](/redis-patterns/time-delay-priority/schedulers/cron-vs-interval) — the cadence the next run is computed from.
- [R4.02.2 · The upsert, no duplicates](/redis-patterns/time-delay-priority/schedulers/upsert-no-duplicates) — one entry per scheduler key.
- [R4 · Score as meaning](/redis-patterns/time-delay-priority/score-as-meaning) — the `:repeat` ZSET in the orientation arc.
- [E6 · Lifecycle controls](/echomq/lifecycle) — the EchoMQ course: the scheduler subsystem in depth.
