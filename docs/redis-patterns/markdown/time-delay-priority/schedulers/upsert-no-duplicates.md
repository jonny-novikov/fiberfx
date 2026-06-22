# R4.02.2 · The upsert, no duplicates

> Route: `/redis-patterns/time-delay-priority/schedulers/upsert-no-duplicates` · dive 2

**A reboot re-registers the same scheduler. The `ZSCORE`-then-`ZADD` upsert keeps exactly one registry entry per scheduler key — no duplicate recurring job on boot.**

A service that owns recurring schedules registers them at startup. Restart the service and it registers them again. The danger is a second registry entry for a schedule that already exists: the recurring job would then fire twice. The cure is the upsert — probe for a prior entry with `ZSCORE`, then store with `ZADD`. Re-adding the same member to a sorted set rewrites its score rather than appending a row, so the registry holds one entry per scheduler key no matter how many boots register it.

## The naive add duplicates

A naive registration appends. Boot once: the registry has one entry. Boot again without checking: a second registration appends a second entry, and the scheduler now produces two recurring jobs on the same cadence. With a member-keyed sorted set this cannot actually happen for the *same* member — but the failure mode the upsert guards is producing a *stale second delayed job* from a re-registration that recomputed a different next-run time, leaving an orphaned future run behind. The probe is what finds and reconciles that stale entry.

## ZSCORE probes, ZADD stores

The upsert is two commands. First the probe: `ZSCORE repeatKey customKey` returns the prior next-run score if the scheduler key is already registered, or false if it is new. If a prior score is found, the script reconciles the stale delayed entry from the previous registration before storing the new one. Then the store: `ZADD repeatKey nextMillis customKey`. Because the member is the scheduler's own key, the `ZADD` either inserts a new row or rewrites the existing row's score — never two rows for one scheduler. The registry's cardinality stays at one entry per scheduler key across every boot.

## In EchoMQ — the probe in addRepeatableJob

The real upsert lives in `addRepeatableJob-2.lua`. The probe runs before the store reconciles whatever the previous registration left in `:delayed`:

```
-- addRepeatableJob-2.lua (real)
local prevMillis = rcall("ZSCORE", repeatKey, customKey)   -- was this scheduler already registered?
if prevMillis then
  local delayedJobId = "repeat:" .. customKey .. ":" .. prevMillis
  -- reconcile the stale delayed entry from the prior next-run, then re-store
end

-- storeRepeatableJob (called below) — the store
rcall("ZADD", repeatKey, nextMillis, customKey)            -- one row per scheduler key
```

`prevMillis` is the prior next-run timestamp. A present `prevMillis` means the scheduler key was already in the registry, so the script removes the stale delayed job the previous registration scheduled (`removeJob` + `ZREM delayedKey delayedJobId`) before `storeRepeatableJob` rewrites the registry entry. The result is exactly one `:repeat` entry per scheduler key and no orphaned duplicate run. The newer scheduler API does the same thing keyed by a scheduler id — `storeJobScheduler(...)` in `addJobScheduler-11.lua` runs `rcall("ZADD", repeatKey, nextMillis, schedulerId)` on the same registry sorted set.

## The pattern, applied

A textbook delayed queue adds a fire-time and forgets it. A scheduler must survive re-registration without re-firing. The `ZSCORE` probe is the idempotence: it reads the prior entry so the `ZADD` rewrites rather than appends, and the registry never grows a duplicate on boot.

## References

### Sources

- [Redis — ZSCORE](https://redis.io/commands/zscore/) — the probe that reads the prior next-run score and makes the add idempotent.
- [Redis — ZADD](https://redis.io/commands/zadd/) — re-adding the same member rewrites its score rather than appending a row.
- [Redis — Sorted sets](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — member uniqueness is what keeps the registry at one entry per scheduler.
- [BullMQ — the queue protocol](https://bullmq.io/) — the repeatable-jobs registration path EchoMQ ports.

### Related in this course

- [R4.02 · Schedulers & repeatable jobs](/redis-patterns/time-delay-priority/schedulers) — the module hub.
- [R4.02.1 · Cron vs interval](/redis-patterns/time-delay-priority/schedulers/cron-vs-interval) — naming the cadence the upsert stores.
- [R4.02.3 · Start-to-start cadence](/redis-patterns/time-delay-priority/schedulers/start-to-start-cadence) — rewriting the single entry each cycle.
- [R4 · Score as meaning](/redis-patterns/time-delay-priority/score-as-meaning) — the `:repeat` ZSET in the orientation arc.
- [E6 · Lifecycle controls](/echomq/lifecycle) — the EchoMQ course: the scheduler subsystem in depth.
