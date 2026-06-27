# R4 · The road ahead

> **Route:** `/redis-patterns/time-delay-priority/the-road-ahead` · R4 · chapter-closing dive

One data structure — the sorted set — carries this whole chapter. The granular ladder R4.01→R4.06 takes one score
reading at a time, and on the far side of the patterns waits the system that runs them: the EchoMQ Queue. This dive
surveys the arc, opens the door into the EchoMQ course, and names where a scheduled job reaches the durable floor.

This is an orientation dive. It has no single Redis-pattern source. It is grounded in the real chapter ladder and
the real EchoMQ surfaces (`echo/apps/echo_mq`) each module cites.

## The arc — one score reading at a time

The sorted set is the constant; the meaning of the score changes module to module. R4 walks the chapter one reading
at a time, and each module is grounded in one real EchoMQ surface.

- **R4.01 · The delayed queue** — score a job by its fire-time and sweep the due head by score. Grounded in
  `EchoMQ.Jobs.enqueue_at/6` / `enqueue_in/6` (park on `emq:{q}:schedule` at the run-at ms) and
  `EchoMQ.Jobs.promote/3` (the `@promote` Lua's `ZRANGEBYSCORE -inf now` of the due head, then `ZREM` to pending).
- **R4.02 · Schedulers & repeatable jobs** — recurring jobs via interval. Grounded in `EchoMQ.Repeat`, which `ZADD`s
  a registration on `emq:{q}:repeat` and upserts via the `@register` Lua's `EXISTS` guard, and `EchoMQ.Metronome`,
  which drives the beat.
- **R4.03 · Priority** — serve one class ahead of another. The textbook packs priority into the score; EchoMQ
  instead serves the score-0 `emq:{q}:pending` set in branded-id mint order, so the `claim` script's `ZPOPMIN`
  returns the oldest job.
- **R4.04 · Backoff & retry** — exponential backoff with jitter, re-using the schedule set. Grounded in
  `EchoMQ.Backoff.delay_ms/2` (`base × 2^(attempts-1)`, clamped, then optional jitter) for the delay, and
  `EchoMQ.Jobs.retry/7` (the `@retry` Lua re-parks onto `emq:{q}:schedule` at `now + delay`).
- **R4.05 · Leaderboards** — real-time rankings on the same sorted-set machinery. Grounded in codemojex's
  `Codemojex.Board`, which `ZADD`s each player's best linear total to `cm:<game>:board` and reads the top with
  `ZREVRANGE ... WITHSCORES`.
- **R4.06 · Workshop** — schedule codemojex's notification and digest jobs over the schedule and repeat sets,
  putting the whole chapter to work on one real surface (`Codemojex.NotificationWorker` over `EchoMQ.Jobs.enqueue_in/5`).

The reliable queue learned its lifecycle in R3; here it learns a clock and an order. Read the arc as one queue
gaining one sense — *when*, and *in what order* — from one sorted set read two ways.

## The door beyond — the EchoMQ Queue

R4 teaches the transferable sorted-set patterns. The engine that runs them is the subject of the dedicated **EchoMQ
course** — specifically **the Queue pillar** (`/echomq/queue`), which now absorbs scheduling, the lifecycle
controls, and lanes. Where this course cites one excerpt as proof, that course teaches the subsystem that runs it.

What the Queue owns beyond the patterns:

- **the schedule fence in depth** — the run-at score as a visibility fence, the promote pump's due-range sweep, and
  the server-clock invariant (`redis.call('TIME')` wherever a lease or a due-time is touched).
- **the dynamic re-score** — `EchoMQ.Jobs.delay/6` moves an *active* member back to `emq:{q}:schedule` without
  consuming an attempt, token-fenced so a stale holder cannot yank a member out from under its new owner.
- **lanes and fairness** — per-group lanes, the metronome's one-block-per-queue readiness fan-out, and
  consumer-fair dispatch.

## The persistence floor — where a scheduled job survives a crash

A scheduled or retried job lives on `emq:{q}:schedule` in Valkey memory. To survive a crash or a replica swap it
must reach a durable substrate. That is the **persistence floor**: ETS head → the Valkey bus + warm L2 → a durable
local page tier (the native `EchoStore.Graft.*` engine on CubDB) → Tigris remote, behind a create-only commit
fence. Durability is a dial — hold nothing, checkpoint per window, or commit-per-record and replicate off-box — and
the enqueue hot path touches only a small, mostly-idle outbox beside the bus, never a database on the path of every
dequeue. The comparison is **Oban**, which keeps jobs in the same Postgres as the data so a job and a row commit in
one transaction; EchoMQ separates the bus from the store and buys an in-memory hot path plus the dial, giving up
that one-transaction coupling. The durable substrate is the subject of the **/echo-persistence** course.

## The bridge

> **The patterns.** R4.01–R4.06 teach the sorted-set techniques applied: a job scored by fire-time, mint-ordered
> service, a recurring registry, a backoff reschedule. Each lands twice — the technique and its trade-offs, then the
> one real EchoMQ excerpt that proves it.
>
> **→ The system.** The EchoMQ Queue applies them all under one engine: the schedule fence, the promote pump, the
> dynamic re-score, lanes and fairness — and beneath them the persistence floor that makes a scheduled job durable.

**Take:** the patterns are the vocabulary; the EchoMQ Queue is the engine, and the persistence floor is the
durable ground it stands on. Learn the score readings here, then go run them there.

## References

### Sources

- [Valkey — *Sorted sets*](https://valkey.io/topics/) — the one structure this whole chapter reads two ways: a clock
  scored by fire-time and a mint-ordered queue scored `0`.
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — the command that sweeps the due head of the
  schedule set, the engine of R4.01's promote step.
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — the single write behind the schedule set, the repeat set, and
  the leaderboard.
- [llms.txt — *The /llms.txt convention*](https://llmstxt.org/) — the machine-readable map format both this course
  and the EchoMQ course publish for agents.

### Related in this course

- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter this dive closes.
- [R4 · The sorted set as a clock](/redis-patterns/time-delay-priority/the-sorted-set-as-a-clock) — dive 1: one
  sorted set read two ways, a timer wheel and a mint-ordered queue.
- [R4 · Score as meaning](/redis-patterns/time-delay-priority/score-as-meaning) — dive 2: the score is the whole
  semantic axis — fire-time, a flattened constant, next-run millis.
- [The Queue — EchoMQ, In Depth](/echomq/queue) — the EchoMQ state machine, the schedule fence, and the promote
  pump, in depth.
- [R3 · The road ahead](/redis-patterns/queues/the-road-ahead) — the parallel orientation dive that surveys the full
  course arc and the first EchoMQ doors.
