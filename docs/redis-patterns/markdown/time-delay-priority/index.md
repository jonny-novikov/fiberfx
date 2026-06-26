# R4 · Time, Delay & Priority

> **Route:** `/redis-patterns/time-delay-priority` · the chapter landing (manifest)

The sorted set is a clock. A Valkey sorted set keeps its members ordered by a numeric score, and that one
property carries this whole chapter: score a job by a future millisecond and the set is a timer wheel; score it so
the head is always the next job to serve and the set is an order. Six patterns from that family — the delayed
queue, schedulers, priority, backoff-and-retry, and leaderboards — each grounded in the real EchoMQ time machinery
(`echo/apps/echo_mq`) and worked through the **codemojex** consumer.

## Why & when

Time is a constraint the queue itself enforces. Reach for a delayed queue when work must run later, not now — a
reminder, a retry after a cooldown, a digest at a fixed hour. Reach for a scheduler when the same work recurs on a
cadence. Reach for priority when one class of work must jump ahead of another. Reach for backoff when a failure
should be retried, but not immediately and not all at once. Each is a position on one axis: *when* a job becomes
eligible, and *in what order* the eligible jobs are served.

EchoMQ answers all of these with one schedule set and one server clock. A scheduled job is parked on
`emq:{q}:schedule` at its run-at millisecond — a visibility fence, not a second queue. A pump promotes the due
range back to `pending` on the server's own clock, so the delay is measured on the same clock the reaper and the
promote pump read, never the caller's.

## The patterns

Six teaching modules, then a workshop. Each module is a hub with three dives.

- **R4.01 · The delayed queue** — score a job by its fire-time, sweep by score. `EchoMQ.Jobs.enqueue_at/6` /
  `enqueue_in/6` park the job on `emq:{q}:schedule`; `EchoMQ.Jobs.promote/3` ranges the due head back to pending.
- **R4.02 · Schedulers & repeatable jobs** — recurring jobs via interval, upserted so a boot adds no duplicate.
  `EchoMQ.Repeat` registers on `emq:{q}:repeat`; `EchoMQ.Metronome` drives the beat.
- **R4.03 · Priority** — serve one class of work ahead of another. The textbook packs priority into the score;
  EchoMQ instead serves the score-0 `pending` set in branded-id mint order, oldest first.
- **R4.04 · Backoff & retry** — exponential backoff with jitter, re-using the schedule set. `EchoMQ.Backoff`
  computes the delay above the wire; `EchoMQ.Jobs.retry/7` re-parks the job on `emq:{q}:schedule`.
- **R4.05 · Leaderboards** — real-time rankings on the same sorted-set machinery, over codemojex's scoring.
  `Codemojex.Board` writes each player's best linear total to `cm:<game>:board` with `ZADD` and reads the top with
  `ZREVRANGE ... WITHSCORES`.
- **R4.06 · Workshop** — schedule codemojex's notification and digest jobs on the schedule and repeat sets through
  `Codemojex.NotificationWorker` and `EchoMQ.Repeat`.

## How to apply

Name the time constraint that matters most, and the mechanism follows. Run later → a delay (`enqueue_in`). Recur on
a cadence → a repeat registration. Order one class ahead of another → mint order in the score-0 pending set, or a
separate lane. Retry after a failure, spread out → backoff plus the schedule set.

## The workshop

The chapter closes with **R4.06**: schedule codemojex's notification and digest jobs. A game-result notice is
enqueued on a fair lane and delivered under a rate limit; over budget, the worker re-enqueues the same job with
`EchoMQ.Jobs.enqueue_in/5` after the bucket's reported wait — deferred on the bus, durable, not dropped. A retry on
a transient delivery failure rides capped exponential backoff with jitter. A scheduled/retried job that must
survive a crash reaches the durable floor — the **/echo-persistence** course.

## Up next

After time comes streams and events — the durable, replayable log (R5), then flow control, data modeling, and
production operations (R6–R8).

## References

### Sources

- [Valkey — *Sorted sets*](https://valkey.io/topics/) — the data type the chapter stands on: members ordered by a
  numeric score, range and pop by score.
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — insert or update a member's score; the single write the
  schedule set, the repeat set, and the leaderboard share.
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — the range query the promote and reap sweeps
  use to read the due head of the schedule set.
- [Redis — *ZPOPMIN*](https://redis.io/commands/zpopmin/) — pop the smallest-score member; the read `claim` uses to
  serve the oldest pending job.

### Related in this course

- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter this one stands on: the wait/active/done queue the
  schedule set feeds.
- [The Queue — EchoMQ, In Depth](/echomq/queue) — the EchoMQ state machine, lanes, and the schedule set, in depth.
- [The Branded Component System](/bcs) — Part III builds the EchoMQ bus these time patterns apply.
- [Functional Programming in Elixir](/elixir) — the functional-Elixir and OTP craft behind the echo data layer.
