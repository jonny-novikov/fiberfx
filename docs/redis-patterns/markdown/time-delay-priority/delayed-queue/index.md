# The delayed queue

> R4.01 · module hub. Schedule tasks for future execution with a sorted set whose score is the timestamp at which
> the task should run. Lists deliver in FIFO order but cannot defer; a sorted set gives natural time-ordering and an
> efficient range query for the due head.

**Route:** `/redis-patterns/time-delay-priority/delayed-queue`

A delayed queue answers one need: run this task later, not now. A Redis list cannot express it — a list delivers in
the order it was filled, head to tail, with no notion of when a member becomes eligible. A sorted set can. Score
each task by the time it should run, and the set orders its members by fire-time for free; a range query bounded by
the current clock returns exactly the tasks whose time has come. This module takes the textbook pattern apart — the
data model, the schedule, the poll, the atomic claim — and then shows the move EchoMQ makes on top: a scheduled job
is parked on a `schedule` sorted set at its run-at millisecond, and a server-clock due-range sweep promotes it back
to the pending set when its time comes.

## Data Model

The structure is a single sorted set. Each member is a task identifier; each score is the time the task should run.

- **Member** — the task identifier or payload reference.
- **Score** — the timestamp at which the task should execute.

Tasks sort themselves by execution time, earliest first, with no extra index. The score is the whole ordering: read
the set low-to-high and the earliest-due task is at the head. In EchoMQ the set is `emq:{<queue>}:schedule`
(`EchoMQ.Keyspace.queue_key(queue, "schedule")`), and its members are branded `JOB` ids.

## Scheduling a Task

To schedule a task to run at a future time, add it to the set with that time as the score:

```
ZADD delayed_queue 1706649000 "task:abc123"
```

The score `1706649000` is the timestamp when the task should run. The payload can live separately, with the set
holding only the reference:

```
HSET task:abc123 type "send_email" recipient "user@example.com"
ZADD delayed_queue 1706649000 "task:abc123"
```

In EchoMQ both moves happen in one atomic script. `EchoMQ.Jobs.enqueue_at/5` writes the job row
(`HSET … state scheduled`) and parks the id on the schedule set (`ZADD schedule <run-at ms> <JOB id>`) in a single
`EVAL`. The relative form `enqueue_in/5` computes the run-at score wire-side from the server clock — `score = now +
delay` where `now` is read by `TIME` — so the delay is measured on the same clock the promote and reap paths read,
never the caller's.

## Polling for Ready Tasks

A worker reads the tasks whose time has passed with a range query bounded above by the current clock. Every member
from the start of the set up to now is due:

```
ZRANGEBYSCORE delayed_queue -inf 1706648500 LIMIT 0 10
```

This returns up to ten tasks with scores at or below the current time. The `-inf` lower bound means "no floor" — every
member from the start of the set up to the clock. The `LIMIT 0 10` caps the batch so one poll claims a bounded slice.

## Claiming Tasks Atomically

Many workers may poll the same set at once, so a worker must claim each task atomically before processing it, or two
workers process the same task. The claim is a `ZREM`:

```
ZREM delayed_queue "task:abc123"
```

`ZREM` returns `1` when this call removed the member — the caller won the claim — or `0` when another worker already
removed it. A worker processes a task only when its `ZREM` returns `1`. The removal is the claim; nothing else marks
ownership.

## The Complete Flow

The four steps are poll, claim, process, clean up:

1. **Poll** — `ZRANGEBYSCORE delayed_queue -inf <now> LIMIT 0 10`.
2. **Claim** — for each task, `ZREM delayed_queue "task:abc123"`.
3. **Process** — run the task only if its `ZREM` returned `1`.
4. **Clean up** — delete the payload, `DEL task:abc123`.

In EchoMQ the poll and the claim are one server-side step. `EchoMQ.Jobs.promote/3` runs the `@promote` script: it
reads the due range with `ZRANGEBYSCORE schedule -inf <now>`, then for each due id `ZREM`s it from the schedule set
and `ZADD`s it onto the pending set at score `0`. No second worker can interleave between the range and the move.

## Avoiding Busy Waiting

Polling an empty set on a fixed tick wastes work. The avoidance is to read the head and sleep until it is due:

```
ZRANGE delayed_queue 0 0 WITHSCORES
```

This returns the earliest task and its scheduled time. When nothing is due yet, a worker sleeps until that time, or
a bounded maximum interval, which cuts polling overhead sharply when the set is empty or the next task is far out. The
next-wake time is the head's score; reading it is one command.

## Combining with Lua

The poll and the claim are two commands, and between them another worker can claim the same task. To make poll-and-claim
one atomic step, run both inside a Lua script:

```
local tasks = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', ARGV[1], 'LIMIT', 0, ARGV[2])
for i, task in ipairs(tasks) do
    redis.call('ZREM', KEYS[1], task)
end
return tasks
```

The script finds and claims the ready tasks in a single round trip; no second worker can interleave between the range
and the removal. This is the shape EchoMQ's promote sweep takes — a `ZRANGEBYSCORE`, a `ZREM` per due id, and a move
onto the pending set, all inside one inline `@promote` script.

## Retry with Backoff

A failed task reschedules itself by re-adding with a future score, so a retry is a delayed task like any other:

```
ZADD delayed_queue 1706649060 "task:abc123"
```

That schedules a retry sixty seconds out. The delay between attempts can grow with the attempt count — exponential
backoff — but that math is a module of its own: **R4.04 · Backoff and retry** owns the formula. EchoMQ's own retry
path re-uses this same schedule set: `EchoMQ.Jobs.retry/7` parks a failed job back on `schedule` at `now + delay`,
the very transition the promote sweep later releases. This module schedules the deferred run; the formula that
chooses the delay is the next reading of the chapter.

## When to Use / When to Avoid

The sorted-set delayed queue fits scheduled work where the ordering axis is time and the read is a due-range:

- **Scheduled and deferred work** — send at a time, notify after a delay, handle a task off-peak.
- **Retry with backoff** — reschedule a failed task with a growing delay.
- **Rate spacing** — space calls over time by their fire-time.

It fits less well where the queue needs consumer groups, message acknowledgement, or replay — those are Redis Streams
territory. A sorted set delivers time-ordering and an efficient due-range query, not an acknowledgement protocol; for
complex queue requirements, a stream with a delay layer built on top is the better tool.

## The three dives

Each dive takes one layer of the delayed queue, building on the source spine and adding the EchoMQ refinement on top:

- **R4.01.1 · The score is the fire-time** — the score carries the meaning: a job's run-at millisecond. EchoMQ scores
  the schedule set by the run-at ms (the caller's for `enqueue_at`, `now + delay` from the server clock for
  `enqueue_in`), while the mint-ordered branded `JOB` id stays the sort key once promoted.
- **R4.01.2 · ZRANGEBYSCORE promotion** — the due-sweep: `ZRANGEBYSCORE schedule -inf now`, `ZREM` each due id, and
  `ZADD` it onto the pending set — EchoMQ's `@promote` script, driven by `EchoMQ.Jobs.promote/3`.
- **R4.01.3 · The next wake** — not busy-polling an empty set: the metronome holds one `BLPOP emq:{q}:wake <beat>`
  per queue, and an admit's `LPUSH` on the wake token wakes the single blocker so promotion runs on demand, not on a
  busy tick.

## The bridge — what EchoMQ really schedules

The textbook delayed queue scores a task by a raw Unix timestamp and polls the due head from a loop. EchoMQ keeps the
structure and makes two moves on top. First, the schedule and the row write are one atomic script:
`EchoMQ.Jobs.enqueue_at/5` and `enqueue_in/5` run the `@schedule` body — `HSET … state scheduled` then
`ZADD emq:{<queue>}:schedule <run-at ms> <JOB id>` — so a scheduled job is never observable half-written. Second,
the promote is a server-clock sweep, not a client poll: `EchoMQ.Jobs.promote/3` runs `@promote`, which reads
`ZRANGEBYSCORE schedule -inf now LIMIT 0 <batch>` against the server's own `TIME`, then moves each due id onto the
pending set. The score is the raw run-at millisecond; the eventual queue order is the branded id's mint order, since
the pending set is score-`0` and its members are the ids themselves.

> **The pattern:** a delayed queue scores each task by the timestamp at which it should run, and reads the due head
> with a range query bounded by the current clock.
>
> **→ In EchoMQ:** `EchoMQ.Jobs.enqueue_at/5` / `enqueue_in/5` park a branded `JOB` id on `emq:{<queue>}:schedule`
> at its run-at millisecond, and `EchoMQ.Jobs.promote/3` runs `ZRANGEBYSCORE schedule -inf now`, `ZREM`s each due id,
> and `ZADD`s it onto the pending set — the real Elixir schedule set and due-range sweep, on the server clock.

The take: a delayed queue is a sorted set scored by run-at time; EchoMQ schedules and promotes it with two inline
scripts on the server clock, and the promoted job inherits the mint order of its branded id.

## References

### Sources

- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the sorted set as a timer
  wheel: members ordered by a numeric score, read by score range.
- [Valkey — *ZADD*](https://valkey.io/commands/zadd/) — score a member by its fire-time; the single write that parks
  a delayed task on the schedule set.
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — the range query that reads the due head, the
  read inside the promote sweep.
- [Redis — *ZREM*](https://redis.io/commands/zrem/) — the atomic claim: `1` means this caller won the task, `0` means
  another already did.

### Related in this course

- [R4.01.1 · The score is the fire-time](/redis-patterns/time-delay-priority/delayed-queue/score-is-fire-time) — the
  run-at score, and the mint-ordered id that becomes the sort key.
- [R4.01.2 · ZRANGEBYSCORE promotion](/redis-patterns/time-delay-priority/delayed-queue/zrangebyscore-promotion) — the
  due-sweep that moves the head onto the pending set.
- [R4.01.3 · The next wake](/redis-patterns/time-delay-priority/delayed-queue/the-next-wake) — the metronome beat that
  drives promotion on demand, not on a busy tick.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter: every score reading of the sorted
  set.
- [R4 · The sorted set as a clock](/redis-patterns/time-delay-priority/the-sorted-set-as-a-clock) — the orientation
  dive: one set, two readings of the score.
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter this one feeds: the pending set the promoted job lands in.
- [/echomq · Queue](/echomq/queue) — the dedicated EchoMQ course: the schedule set, the promote pump, and lifecycle
  controls in depth.
