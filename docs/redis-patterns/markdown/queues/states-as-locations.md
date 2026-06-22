# States as locations — the lifecycle as one atomic Lua move

> R3 · Reliable Queues · dive 2 — `/redis-patterns/queues/states-as-locations`

A job's state is not a status field on a record. It is *where the job's id lives*. A transition is moving the id from
one Redis key to another, the whole move run as one atomic Lua script, and a blocked worker woken by a marker instead
of a poll.

## The state is the location

A naive queue stores a `status` column — `"wait"`, `"active"`, `"done"` — and updates it as the job moves. Two things
can then disagree: where the job actually sits and what the status says. A crash between writing the status and moving
the job leaves the two out of sync, and nothing reconciles them.

EchoMQ holds no status field. A job's state *is* the Redis key its id lives in:

- `emq:{queue}:wait` — a **LIST** of ids waiting to run.
- `emq:{queue}:active` — a **LIST** of ids in flight under a lock.
- `emq:{queue}:delayed` — a **ZSET** scored by the time the job becomes due.
- `emq:{queue}:prioritized` — a **ZSET** scored by priority.
- `emq:{queue}:completed` — a **ZSET** of finished ids scored by finish time.
- `emq:{queue}:failed` — a **ZSET** of failed ids.

`EchoMQ.Keys` builds each of these from the queue context — `wait/1`, `active/1`, `delayed/1`, `prioritized/1`,
`completed/1`, `failed/1`. A transition is moving the id from one key to the next. There is no separate state column to
fall out of sync, because the location *is* the state.

## The whole transition is one atomic Lua move

Moving a job from `active` to `completed` is not one write. The lifecycle transition reads the job, checks its lock,
removes the id from `active`, writes the result into `completed`, updates counters and metrics, and pushes the next
job — touching many keys. Done as separate commands, a crash partway leaves the job in two places or in none.

`moveToFinished-14.lua` performs that whole transition across **fourteen keys** in one `EVALSHA`. Its header documents
the fourteen `KEYS`: wait, active, prioritized, the event stream, stalled, the rate limiter, delayed, paused, meta, the
priority counter, the completed-or-failed key, the job hash, the metrics key, and the marker. `EchoMQ.Scripts.move_to_finished/7`
assembles those fourteen keys in order and runs the script. Because Redis runs a Lua script to completion with no other
client interleaving, the move applies in full or not at all. There is no torn intermediate state to recover. This is the
R2.01 atomic-update pattern at lifecycle scale: read, decide, write — in one move.

## Load once, execute by SHA

The script is the protocol, and it is cached by its SHA1. `EchoMQ.Scripts.execute_raw/4` computes the script's
`sha1`, then issues `EVALSHA sha numkeys keys… args…`. On the first call for a script Redis has not seen, it answers
`NOSCRIPT`; `execute_raw/4` matches that error, falls back to `EVAL` with the full script body (which also caches it),
and every later call hits `EVALSHA`. The full ~1050-line `moveToFinished-14.lua` body crosses the wire once; after that
the worker sends only its SHA.

## Blocking pickup, not busy-polling

A worker that loops `LRANGE`/sleep over the wait list burns CPU and adds latency between a job arriving and a worker
noticing. EchoMQ wakes a blocked worker instead. Every enqueue touches the `emq:{queue}:marker` ZSET
(`EchoMQ.Keys.marker/1`), and an idle worker parks on `BZPOPMIN marker timeout` on a *dedicated blocking connection* —
`Redix.command(conn, ["BZPOPMIN", marker_key, timeout_seconds], …)` in the worker's `do_wait_for_job/3`. The worker
sleeps until a job arrives, then Redis returns the popped marker and the worker fetches the job. No CPU is spent while
the queue is empty. The Go port's polling ticker is the contrast — it wakes on a fixed interval whether or not a job is
waiting.

## In EchoMQ — the lifecycle the worker runs

The pattern and the application line up directly. A job's state is its Redis location, every transition is one atomic
Lua move, and an idle worker blocks on a marker rather than polling. In EchoMQ that is `moveToFinished-14.lua` — fourteen
keys, one `EVALSHA` via `EchoMQ.Scripts.execute_raw/4` — together with `emq:{queue}:marker` and `BZPOPMIN`.

The whole lifecycle — the eight states, the script behind every transition, the lock protocol, and the closed error
codes — is the dedicated EchoMQ course. R3 opens onto its lifecycle chapters.

## References

### Sources

- [Redis — Scripting with Lua (EVAL / EVALSHA)](https://redis.io/docs/latest/develop/interact/programmability/eval-intro/) — the atomic lifecycle transition; a script runs to completion with no interleaving.
- [Redis — EVALSHA](https://redis.io/commands/evalsha/) — run a cached script by its SHA1; `NOSCRIPT` falls back to `EVAL`.
- [Redis — BZPOPMIN](https://redis.io/commands/bzpopmin/) — the blocking pop on the marker ZSET that wakes a worker instead of polling.
- [BullMQ](https://bullmq.io/) — the reliable-queue protocol EchoMQ ports, where the Lua scripts are the protocol.

### Related in this course

- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter: the reliable-queue family in one place.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — dive 1: the in-flight list, at-least-once, and stalled reclaim.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic move; this dive is that pattern at lifecycle scale.
- [R0.2 · Redis under Portal](/redis-patterns/overview/redis-under-portal) — the EchoMQ bus these patterns ground in.
