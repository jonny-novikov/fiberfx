# R4.02 · Schedulers & repeatable jobs

> Route: `/redis-patterns/time-delay-priority/schedulers` · module hub

**A repeatable job is a delayed job that re-schedules itself: a sorted set holds one entry per registration, scored by the next run time, and each time an occurrence fires the next timestamp is computed and the same entry's score is rewritten — so the recurrence survives restarts without ever duplicating.**

The delayed-queue pattern schedules one future run by scoring a job in a sorted set with the timestamp it should fire. A scheduler carries that one move forward: it keeps a registry of recurring schedules, one entry per registration, each scored by *when it next runs*. When an occurrence fires, the next run time is computed and the same entry's score is rewritten. The registry never grows past one row per registration, and a restart that re-registers the same name finds the row already present and changes nothing rather than adding a second.

## What a scheduler adds over a one-shot delay

A one-shot delayed job is a member in a sorted set scored by its fire-time. It runs once and is gone. A scheduler adds three things on top:

- a **cadence** — a rule for "when next" (a wall-clock cron slot or a fixed interval), evaluated to a timestamp;
- a **registry** — a separate sorted set, scored by the next run time, holding one entry per recurring registration;
- an **upsert** — registering a name that already exists leaves its single entry alone rather than appending a duplicate.

The score is still a future timestamp, exactly as in the delayed queue. The new idea is that the entry is rewritten each cycle instead of consumed once.

## Naming the cadence (cron vs interval)

There are two ways to name *when next*. A **cron expression** (`0 9 * * *`) names a wall-clock calendar position — every day at 09:00 — and the next run is the next calendar slot at or after now. A **fixed interval** (`every_ms: 900000`) names a gap — every fifteen minutes — and the next run is the previous run plus the gap. Both reduce to a single millisecond timestamp, which is the score the registry stores. EchoMQ's `EchoMQ.Repeat` is the interval form: it carries an `every_ms` period and advances the score by it each cycle. The first dive computes the next run each way over a fixed clock and shows that both feed the same one-entry registry.

## The repeat registry (a sorted set of next-run times)

`EchoMQ.Repeat` declares two `{q}`-hashtagged keys, so a queue's repeat state lands on its own cluster slot:

- `emq:{q}:repeat` — a sorted set scored by the next-run millisecond, members the registration names.
- `emq:{q}:repeat:<name>` — a hash carrying `every_ms` and the payload `template`.

The registry sorted set carries only the next-run times; the period and the payload template live in the companion hash. Registration writes both atomically in one Lua script: `HSET emq:{q}:repeat:<name> every_ms <ms> template <json>` for the record, then `ZADD emq:{q}:repeat <first_at> <name>` for the registry entry.

## The upsert (no duplicate on boot)

A service that boots re-registers all its schedules. A naive add would push a second entry for a registration that already exists, and the recurring job would fire twice. The upsert prevents that. The `@register` script probes the record key first: `if redis.call('EXISTS', KEYS[2]) == 1 then return 0`. If the record already exists, the script returns `0` and writes nothing; `EchoMQ.Repeat.register/6` answers `{:ok, :exists}`. Only a name with no record runs the `HSET` and the `ZADD`, answering `{:ok, :registered}`. One registration name, one record, one registry entry, across any number of boots. The second dive runs two boots over the same name and counts the entries.

## Producing the next run (start-to-start)

The registry holds only the *next* run, never a queue of future runs. The cadence is `EchoMQ.Pump`'s: each tick the pump reads the due registrations off the sorted set (`ZRANGEBYSCORE emq:{q}:repeat -inf <now>`), mints a fresh branded `JOB` id and enqueues each occurrence, then advances the score. The advance is start-to-start: `EchoMQ.Repeat.advance/4` sets the new score to `now_ms() + every_ms` — measured from when the occurrence is released plus the period, not from when the prior occurrence finished running. Measuring from a finish would let a slow occurrence push every later run later and drift the schedule; advancing by the period keeps the cadence anchored to the period. Each occurrence mints a *fresh* `JOB` id, so it is a first-class, browsable, mint-ordered job — never a reused row. The third dive compares the start-to-start advance against a start-to-finish one and shows the drift.

## When to use

- recurring work on a calendar or a fixed cadence — periodic reports, cleanup sweeps, polling an upstream;
- schedules that must survive a restart without re-firing or duplicating;
- a small-to-moderate number of named registrations, each with its own period.

## When to avoid

- sub-second or hard-real-time cadences — a sorted-set registry swept by a pump on a beat is millisecond-grained, not a real-time scheduler;
- enormous fan-outs of distinct one-off future runs (millions of independent timestamps) — those are delayed jobs, not registrations, and belong in the schedule set;
- cadences that need full calendar correctness across timezones and daylight-saving transitions — that parsing depth belongs to EchoMQ's scheduler subsystem, the EchoMQ course's territory.

## In EchoMQ — the registration that does not duplicate

A textbook delayed queue can already schedule one future run. A scheduler makes the run re-schedule itself. `EchoMQ.Repeat` keeps exactly one `emq:{q}:repeat` entry per registration name and makes the register idempotent with the `EXISTS` probe, so a restart re-registering the same name finds the record already present and changes nothing rather than spawning a duplicate.

Registration is one inline Lua script. Its first move is the idempotence guard — `if redis.call('EXISTS', KEYS[2]) == 1 then return 0` — and only a fresh name runs `HSET KEYS[2] 'every_ms' ARGV[2] 'template' ARGV[3]` then `ZADD KEYS[1] tonumber(ARGV[4]) ARGV[1]`. The score is the next-run millisecond; the member is the registration name. `EchoMQ.Pump` then sweeps the set each tick, minting a fresh branded `JOB` id per occurrence and advancing the score by `every_ms` start-to-start (Chapter 3.7).

The full cron parser, the timezone and daylight-saving handling, and the scheduler-vs-delayed reconciliation across a worker pool are the subject of the dedicated EchoMQ course's Queue pillar, which absorbs the scheduling and lifecycle controls. This module teaches the registry and its upsert; that course teaches the scheduler subsystem that maintains it. A scheduled occurrence that is archived for replay reaches the durable persistence floor — the **`/echo-persistence`** course follows that path down.

## The three dives

| # | Dive | Teaches |
|---|---|---|
| R4.02.1 | Cron vs interval | two ways to name "when next" — a cron expression (wall-clock calendar) vs a fixed interval (`every_ms`); each produces the next-run timestamp the registry is scored by, and `EchoMQ.Repeat` is the interval form |
| R4.02.2 | The upsert, no duplicates | a reboot re-registers the same name; the `EXISTS`-guarded register keeps exactly one registry entry per registration name — no duplicate recurring job on boot |
| R4.02.3 | Start-to-start cadence | the registry holds only the next run; when an occurrence is produced `advance/4` rewrites the score to `now + every_ms` — start-to-start, not start-to-finish |

## References

### Sources

- [Redis — ZADD](https://redis.io/commands/zadd/) — write the next-run millisecond as the registry score; re-adding the same member rewrites it.
- [Valkey — ZRANGEBYSCORE](https://valkey.io/commands/zrangebyscore/) — the pump's due read: the names scored at or before now.
- [Valkey — Sorted sets](https://valkey.io/topics/sorted-sets/) — the registry as a sorted set of next-run times, on the engine the connector is gated against.
- [Redis — EXISTS](https://redis.io/commands/exists/) — the idempotence probe: a present record makes the register a no-op.
- [Redis — Documentation](https://redis.io/docs/) — sorted sets, expiry, and the recurring-schedule access pattern in context.

### Related in this course

- [R4.02.1 · Cron vs interval](/redis-patterns/time-delay-priority/schedulers/cron-vs-interval) — naming the cadence.
- [R4.02.2 · The upsert, no duplicates](/redis-patterns/time-delay-priority/schedulers/upsert-no-duplicates) — one entry per registration name.
- [R4.02.3 · Start-to-start cadence](/redis-patterns/time-delay-priority/schedulers/start-to-start-cadence) — rewriting the single next-run score.
- [R4.01 · Delayed queue](/redis-patterns/time-delay-priority/delayed-queue) — the one-shot delay this recurrence builds on.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [The Queue, in depth](/echomq/queue) — the EchoMQ course: the queue protocol and its scheduling controls.
