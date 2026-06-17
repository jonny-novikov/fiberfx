# Scheduling & recurrence

> Route: `/echomq/queue/lifecycle-controls/scheduling-and-recurrence` · surface: dive · grounding: all **real code** in
> `echo/apps/echo_mq` — `EchoMQ.Jobs.{enqueue_at/5, enqueue_in/5, promote/3}` + the `@schedule`/`@promote` Lua,
> `EchoMQ.Backoff.delay_ms/2` (with its real doctests), `EchoMQ.Repeat.{register/6, cancel/3, due/3, advance/4, count/2}`.
> No `[RECONCILE]` markers.

## The fact — control over time

A queue's default is "as soon as a worker is free." Three controls move that in time:

- **Schedule** — admit a job now but make it invisible until a run-at instant. `enqueue_at/5` takes an absolute
  millisecond; `enqueue_in/5` takes a relative delay measured on the **server** clock.
- **Backoff** — when a job fails, the delay before the next attempt is a curve. `Backoff.delay_ms/2` is a pure function
  from a policy and an attempt count to a literal millisecond delay, computed above the wire.
- **Recurrence** — a job that runs on a cadence. `Repeat` registers once; the pump mints a **fresh** job id for every
  occurrence.

## The schedule set is a visibility fence, not a second queue

`enqueue_at/5` and `enqueue_in/5` both run the `@schedule` script. It is the enqueue transition with one change: the row
is written `state = scheduled`, and the id is added to the **schedule** set (`emq:{q}:schedule`) at the run-at score —
not the pending set. The same branded id is the member; byte order is still mint order, so once a scheduled job is
released it sorts among the pending jobs by its mint instant, not its release instant.

Beat one — the handle. `enqueue_in/5` and `enqueue_at/5` both delegate to one private `schedule/6`; the public verbs
differ only in the mode token (`"in"` / `"at"`) and the guard.

Beat two — `@schedule`. The same JOB-namespaced gate and EXISTS idempotency as enqueue. Then: if the mode is `"in"`, the
score is the **server** `TIME` plus the literal delay; otherwise the score is the literal run-at value. `HSET state
scheduled`, `ZADD KEYS[2]` (the schedule set) at that score, return 1.

The point: a scheduled job is not a different kind of job in a different queue. It is the same row, on the same slot,
fenced out of pending by a score the promote pass reads. `enqueue_in` measures the delay on the **same clock** that
promote and reap read — never the caller's.

## promote releases the due ones

`promote/3` runs `@promote`: read the server `TIME`, take the schedule members scored at or before now
(`ZRANGEBYSCORE schedule -inf now LIMIT 0 N`), and for each one `ZREM` it from schedule and add it to pending (or to its
lane if it is a grouped job) at score 0, then `HSET state pending`. It returns how many it released. The consumer loop
calls promote on its beat, so a scheduled job becomes claimable on the next pump after its instant passes.

## Backoff is a curve computed above the wire

When a job fails and will be retried, the delay before the next attempt is `Backoff.delay_ms(policy, attempts)` — a pure
function, no process, no clock, no I/O. Three policies:

- `{:fixed, ms}` — the same delay every attempt.
- `{:exponential, base, cap}` — `base * 2^(attempts-1)`, clamped at `cap`, so the curve climbs and then holds.
- `{:jitter, inner}` — a uniform random delay in `0..inner_delay`, the full-jitter form that spreads a retry storm.

The doctests in the module are real:

    iex> EchoMQ.Backoff.delay_ms({:exponential, 100, 10_000}, 1)
    100
    iex> EchoMQ.Backoff.delay_ms({:exponential, 100, 10_000}, 3)
    400
    iex> EchoMQ.Backoff.delay_ms({:exponential, 100, 10_000}, 20)
    10000

The wire takes a **literal** delay — `Jobs.retry/7` carries the computed value as the schedule delay. The curve is a
value the consumer can compute, table, and test without a server.

## Recurrence mints a fresh job per occurrence

`Repeat.register/6` writes a registration under a name: a record hash `emq:{q}:repeat:<name>` carrying `every_ms` and a
payload `template`, and a member on the `emq:{q}:repeat` sorted set scored by its next-run millisecond. `cancel/3`
removes both. `due/3` reads the names scored at or before now, each with its record. `advance/4` moves a name's next-run
score forward by its period. `count/2` is the registry depth.

The cadence is the pump's: it reads due registrations, mints and enqueues each occurrence, and advances the score. Each
occurrence is a first-class, browsable, mint-ordered job, because the id mints **fresh** per occurrence — never a reused
row (id reuse would break both the order theorem and the dedup semantics).

## Worked example

Register a daily report at `every_ms = 86_400_000`. The registry has one member. When it comes due, the pump mints a new
`JOB`-namespaced id, enqueues an occurrence carrying the template, and advances the score by one day. Tomorrow's run is
a different id, a different row, a different mint instant — the registration is unchanged.

## Interactive 1 (hero) — the schedule clock

A timeline of three jobs scheduled at run-at scores, and a "now" the reader advances. The readout shows which jobs
promote would release (score ≤ now) and which stay fenced. Pure: the set of released ids is a function of `now`.

## Interactive 2 (main) — the backoff-curve plotter

Pick a policy (fixed · exponential · jitter-over-exponential), plot `delay_ms` over attempts 1..8. The readout names the
exact delay per attempt, matching the doctests for the exponential case. Pure over the real `delay_ms` logic.

## Bridge

- The pattern (Redis Patterns Applied): a delayed/scheduled job is a ZSET scored by run-at time, swept by a promote
  pass; a retry curve is computed client-side. `/redis-patterns/time-delay-priority` teaches the delay/schedule family.
- The implementation (echo_mq): `@schedule` parks on the schedule set at the run-at score; `@promote` releases the due
  ones on the server clock; `Backoff.delay_ms/2` is the curve; `Repeat` is the cadence.

## Take

A schedule is a score, not a second queue; a backoff is a value, not a sleep; a recurrence is a registration, not a
loop. Time is a control, and the controls are scores and pure functions.

## References

### Sources
- valkey.io/commands/zadd/ — the schedule-set insertion at the run-at score.
- valkey.io/commands/zrangebyscore/ — the due read `@promote` runs each beat.
- redis.io/commands/evalsha/ — the load-once dispatch the schedule verbs run by SHA.
- valkey.io/docs/ — the substrate of record.

### Related in this course
- /echomq/queue — The Queue.
- /echomq/queue/lifecycle-controls — the module hub.
- /echomq/protocol — the keyspace and the Lua layer the schedule runs on.
- /redis-patterns/time-delay-priority — the delay/schedule/priority family.
