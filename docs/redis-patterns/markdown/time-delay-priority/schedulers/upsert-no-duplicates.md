# R4.02.2 · The upsert, no duplicates

> Route: `/redis-patterns/time-delay-priority/schedulers/upsert-no-duplicates` · dive 2

**A reboot re-registers the same scheduler. The `EXISTS`-guarded register keeps exactly one registry entry per registration name — no duplicate recurring job on boot.**

A service that owns recurring schedules registers them at startup. Restart the service and it registers them again. The danger is a second registry entry for a registration that already exists: the recurring job would then fire twice. The cure is the idempotent register — probe the record key with `EXISTS`, and write nothing when it is already present. `EchoMQ.Repeat.register/6` answers `{:ok, :exists}` for a name that is already live and `{:ok, :registered}` only for a fresh one, so the registry holds one entry per registration name no matter how many boots register it.

## The naive add duplicates

A naive registration appends. Boot once: the registry has one entry. Boot again without checking: a second registration appends a second entry, and the scheduler now produces two recurring jobs on the same cadence. With a member-keyed sorted set a re-`ZADD` of the *same* name would only rewrite its score — but a register that recomputed a different first-run time and wrote a fresh record would still corrupt the live cadence. The `EXISTS` guard rules that out at the record key: a present record means a registered name, and the script returns before it touches either key.

## EXISTS guards, HSET + ZADD store

The register is one inline Lua script with the guard at the top. First the probe: `redis.call('EXISTS', KEYS[2])` returns `1` when the record hash `emq:{q}:repeat:<name>` already exists, or `0` when the name is new. On `1` the script returns `0` and writes nothing — no record, no registry entry, no change. On `0` it runs the store: `HSET` the record hash with `every_ms` and the `template`, then `ZADD` the registry with the first-run score against the name. Because the guard is the first move and both writes are in the same script, two boots of the same name produce exactly one record and exactly one registry entry. The registry's cardinality stays at one entry per registration name across every boot.

## In EchoMQ — the EXISTS guard in @register

The real idempotence lives in the `@register` script of `EchoMQ.Repeat`. The `EXISTS` probe runs before any write:

```
-- @register (EchoMQ.Repeat, verbatim)
if redis.call('EXISTS', KEYS[2]) == 1 then
  return 0
end
redis.call('HSET', KEYS[2], 'every_ms', ARGV[2], 'template', ARGV[3])
redis.call('ZADD', KEYS[1], tonumber(ARGV[4]), ARGV[1])
return 1
```

A return of `0` is mapped by `register/6` to `{:ok, :exists}`; a return of `1` is `{:ok, :registered}`. `KEYS[2]` is the record hash and `KEYS[1]` is the registry sorted set, both `{q}`-hashtagged onto the queue's slot. A second register of a live name finds `EXISTS KEYS[2] == 1`, returns `0`, and the recurring job is registered exactly once. The mirror move is `cancel/3`: it `ZREM`s the registry member and `DEL`s the record, so a cancelled name is gone from the declared keyspace and a later register treats it as fresh again. The result across a worker pool — how a register races a sweep, how a cancel mid-tick is reconciled — is the scheduler subsystem the EchoMQ course covers.

## The pattern, applied

A textbook delayed queue adds a fire-time and forgets it. A scheduler must survive re-registration without re-firing. The `EXISTS` guard is the idempotence: it reads the prior record so the store runs only for a fresh name, and the registry never grows a duplicate on boot.

## References

### Sources

- [Redis — EXISTS](https://redis.io/commands/exists/) — the probe that reads whether the record is present and makes the register idempotent.
- [Redis — ZADD](https://redis.io/commands/zadd/) — the registry store; re-adding the same member would rewrite, but the guard runs first.
- [Redis — HSET](https://redis.io/commands/hset/) — the record hash carrying `every_ms` and the payload template per registration.
- [Valkey — Sorted sets](https://valkey.io/topics/sorted-sets/) — member uniqueness is what keeps the registry at one entry per registration.

### Related in this course

- [R4.02 · Schedulers & repeatable jobs](/redis-patterns/time-delay-priority/schedulers) — the module hub.
- [R4.02.1 · Cron vs interval](/redis-patterns/time-delay-priority/schedulers/cron-vs-interval) — naming the cadence the register stores.
- [R4.02.3 · Start-to-start cadence](/redis-patterns/time-delay-priority/schedulers/start-to-start-cadence) — rewriting the single entry each cycle.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [The Queue, in depth](/echomq/queue) — the EchoMQ course: the scheduling controls in depth.
