# R4.02.3 · Start-to-start cadence

> Route: `/redis-patterns/time-delay-priority/schedulers/start-to-start-cadence` · dive 3

**The registry holds only the next run. When an occurrence is produced the next timestamp is computed and the single score rewritten — start-to-start, anchored to the period, not start-to-finish.**

A scheduler does not pre-compute a queue of future runs. It keeps exactly one entry per registration, scored by the *next* run, and rewrites that score each time an occurrence is produced. The question is what the next run is measured from. Start-to-start advances by the period from when the occurrence is released, so the cadence stays anchored to the period. Start-to-finish measures from when the occurrence *finished*, so a slow occurrence pushes every later run later and the schedule drifts. `EchoMQ.Repeat` advances start-to-start.

## One entry, rewritten each cycle

The registry is a sorted set scored by next-run time. A registration occupies one member. When the pump produces the next occurrence, it computes the next run from the period and `ZADD`s the new score against the same member — rewriting the single entry, not appending a new one. The registry's size is the number of distinct registrations, never the number of runs. A registration that has fired ten thousand times still holds exactly one row, and each occurrence is enqueued under a *fresh* branded `JOB` id, so the runs are first-class browsable jobs while the registry stays at one entry.

## Start-to-start vs start-to-finish

Consider an every-15-minute registration where an occurrence takes 4 minutes to run. Start-to-start: the occurrence released at 09:00 advances the next score to 09:15, the one after to 09:30 — the cadence is anchored to the 15-minute period and the 4-minute run does not move it. Start-to-finish: the 09:00 occurrence finishes at 09:04, so the next is scheduled for 09:19, which finishes at 09:23, so the next is 09:38 — every run drifts later by the run duration, and after enough cycles the schedule has slid far off the period. Start-to-start keeps fifteen-minute marks at :00, :15, :30, :45; start-to-finish lets them creep.

## The pump reads due, advances by the period

`EchoMQ.Pump` is the cadence (Chapter 3.7). Each tick it reads the due registrations off the registry — `ZRANGEBYSCORE emq:{q}:repeat -inf <now>` — mints a fresh branded `JOB` id and enqueues each occurrence, then advances the score. The advance is `EchoMQ.Repeat.advance/4`, and it computes the next score as `now_ms() + every_ms`: the release instant plus the period, never a finish time. Because promotion and the repeat sweep are both idempotent over their sets, a pump restart re-sweeps without loss or duplication.

## In EchoMQ — next score from now plus the period

The advance computes the next run start-to-start and rewrites the single registry entry. The `@advance` script first checks the record still exists (a cancelled name is swept), then `ZADD`s the new score against the registration name:

```
-- @advance (EchoMQ.Repeat, verbatim) — KEYS[1]=emq:{q}:repeat, KEYS[2]=record hash
if redis.call('EXISTS', KEYS[2]) == 0 then
  redis.call('ZREM', KEYS[1], ARGV[1])
  return 0
end
redis.call('ZADD', KEYS[1], tonumber(ARGV[2]), ARGV[1])
return 1
```

The host computes `ARGV[2]` as `now_ms() + every_ms` in `advance/4` — the start-to-start step from the release instant plus the period. A return of `1` is `{:ok, :advanced}`; a return of `0` sweeps a registration cancelled mid-tick and answers `{:ok, :absent}`. The snap-forward over a missed slot, the overlap policy, and the scheduler-vs-delayed reconciliation across a worker pool are the scheduler subsystem the EchoMQ course covers. This dive teaches the start-to-start advance and the single entry it rewrites. A produced occupation that is later archived for replay reaches the durable persistence floor — the **`/echo-persistence`** course follows that path.

## The pattern, applied

A textbook delayed queue scores one run and is done. A scheduler rewrites its single score each cycle, and *how* it computes the next score governs whether the cadence holds. Start-to-start anchors to the period; the registry stays one entry; each occurrence mints a fresh job.

## References

### Sources

- [Redis — ZADD](https://redis.io/commands/zadd/) — rewriting the single registry score with the start-to-start next-run time.
- [Valkey — ZRANGEBYSCORE](https://valkey.io/commands/zrangebyscore/) — the pump's due read: the names scored at or before now.
- [Valkey — Sorted sets](https://valkey.io/topics/sorted-sets/) — the one-entry-per-registration registry rewritten each cycle.
- [Redis — EXISTS](https://redis.io/commands/exists/) — the advance guard: a missing record sweeps the dangling registry member.

### Related in this course

- [R4.02 · Schedulers & repeatable jobs](/redis-patterns/time-delay-priority/schedulers) — the module hub.
- [R4.02.1 · Cron vs interval](/redis-patterns/time-delay-priority/schedulers/cron-vs-interval) — the cadence the next run is computed from.
- [R4.02.2 · The upsert, no duplicates](/redis-patterns/time-delay-priority/schedulers/upsert-no-duplicates) — one entry per registration name.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [The persistence floor](/echo-persistence) — the durable substrate a produced occurrence reaches when archived.
- [The Queue, in depth](/echomq/queue) — the EchoMQ course: the scheduling subsystem in depth.
