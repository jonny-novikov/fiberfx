# The delayed queue

> R4.01 · module hub. Schedule tasks for future execution with a sorted set whose score is the timestamp at which
> the task should run. Lists deliver in FIFO order but cannot defer; a sorted set gives natural time-ordering and an
> efficient range query for the due head.

**Route:** `/redis-patterns/time-delay-priority/delayed-queue`

A delayed queue answers one need: run this task later, not now. A Redis list cannot express it — a list delivers in
the order it was filled, head to tail, with no notion of when a member becomes eligible. A sorted set can. Score
each task by the time it should run, and the set orders its members by fire-time for free; a range query bounded by
the current clock returns exactly the tasks whose time has come. This module takes the textbook pattern apart — the
data model, the schedule, the poll, the atomic claim — and then shows the one move EchoMQ sharpens: scoring by
`timestamp × 0x1000` so the low twelve bits can discriminate jobs due in the same millisecond.

## Data Model

The structure is a single sorted set. Each member is a task identifier; each score is the time the task should run.

- **Member** — the task identifier or payload reference.
- **Score** — the timestamp at which the task should execute.

Tasks sort themselves by execution time, earliest first, with no extra index. The score is the whole ordering: read
the set low-to-high and the earliest-due task is at the head.

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

## Polling for Ready Tasks

A worker reads the tasks whose time has passed with a range query bounded above by the current clock:

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
and the removal. This is the shape EchoMQ's sweep takes — a range followed by a `ZREM`, inside one script.

## Retry with Backoff

A failed task reschedules itself by re-adding with a future score, so a retry is a delayed task like any other:

```
ZADD delayed_queue 1706649060 "task:abc123"
```

That schedules a retry sixty seconds out. The delay between attempts can grow with the attempt count — exponential
backoff — but that math is a module of its own: **R4.04 · Backoff and retry** owns the formula
(`EchoMQ.Backoff.calculate/4`, `base × 2^(n-1)`). This module schedules the retry; the formula that chooses the delay
is the next reading of the chapter.

## When to Use / When to Avoid

The sorted-set delayed queue fits scheduled work where the ordering axis is time and the read is a due-range:

- **Scheduled and deferred work** — send at a time, notify after a delay, handle a task off-peak.
- **Retry with backoff** — reschedule a failed task with a growing delay.
- **Rate spacing** — space API calls over time by their fire-time.

It fits less well where the queue needs consumer groups, message acknowledgement, or replay — those are Redis Streams
territory. A sorted set delivers time-ordering and an efficient due-range query, not an acknowledgement protocol; for
complex queue requirements, a stream with a delay layer built on top is the better tool.

## The three dives

Each dive takes one layer of the delayed queue, building on the source spine and adding the EchoMQ refinement on top:

- **R4.01.1 · The score is the fire-time** — the textbook scores by a raw Unix timestamp; EchoMQ scores
  `delayedTimestamp × 0x1000`, so the low twelve bits discriminate jobs due in the same millisecond.
- **R4.01.2 · ZRANGEBYSCORE promotion** — the due-sweep: range from `0` to now, `ZREM` the head, move it to the wait
  list — EchoMQ's included `promoteDelayedJobs` function.
- **R4.01.3 · The next wake** — not busy-polling an empty set: read the head, compute the next due time, and let the
  delay marker wake a blocked worker exactly when due.

## The bridge — what EchoMQ really scores

The textbook delayed queue scores a task by a raw Unix timestamp. EchoMQ keeps the structure and sharpens the score.
Its delayed set is `EchoMQ.Keys.delayed/1` → `emq:{queue}:delayed`. The score is not the bare millisecond: in
`addDelayedJob-6.lua`'s `getDelayedScore`, `delayedTimestamp = timestamp + delay`, `minScore = delayedTimestamp ×
0x1000`, and `maxScore = (delayedTimestamp + 1) × 0x1000 - 1`. The fire-time is shifted left twelve bits, so the low
twelve bits are free to carry a within-millisecond discriminator: when two jobs land on the same millisecond, the
second takes `currentMaxScore + 1`, a distinct score one tick above the first. The recovery is exact — not lossy:
`getNextDelayedTimestamp` reads the head and returns `nextTimestamp / 0x1000`, dividing the shift back out to recover
the real millisecond.

> **The pattern:** a delayed queue scores each task by the timestamp at which it should run, and reads the due head
> with a range query bounded by the current clock.
>
> **→ In EchoMQ:** `emq:{queue}:delayed` scores by `(timestamp + delay) × 0x1000`, so the low twelve bits
> discriminate jobs due in the same millisecond; a `promoteDelayedJobs` sweep ranges `0 → (now + 1) × 0x1000 - 1` and
> moves the due head to the wait list — the real Elixir delayed set and sweep.

The take: a delayed queue is a sorted set scored by fire-time; EchoMQ scores `ts × 0x1000` so a millisecond can hold
more than one ordered job, and recovers the real time by dividing the shift back out.

## References

### Sources

- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the sorted set as a timer
  wheel: members ordered by a numeric score, read by score range.
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — score a member by its fire-time; the single write that schedules
  a delayed task.
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — the range query that reads the due head, the
  read inside the sweep.
- [Redis — *ZREM*](https://redis.io/commands/zrem/) — the atomic claim: `1` means this caller won the task, `0` means
  another already did.
- [BullMQ — *the queue protocol*](https://bullmq.io/) — the delayed set and marker protocol EchoMQ ports, where the
  Lua scripts are the protocol.

### Related in this course

- [R4.01.1 · The score is the fire-time](/redis-patterns/time-delay-priority/delayed-queue/score-is-fire-time) — the
  score is the fire-time, shifted twelve bits to discriminate within a millisecond.
- [R4.01.2 · ZRANGEBYSCORE promotion](/redis-patterns/time-delay-priority/delayed-queue/zrangebyscore-promotion) — the
  due-sweep that moves the head to the wait list.
- [R4.01.3 · The next wake](/redis-patterns/time-delay-priority/delayed-queue/the-next-wake) — read the head, compute
  the next due time, wake on the marker.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter: every score reading of the sorted
  set.
- [R4 · The sorted set as a clock](/redis-patterns/time-delay-priority/the-sorted-set-as-a-clock) — the orientation
  dive: one set, two readings of the score.
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter this one feeds: the reliable list the swept job lands in.
- [E6 · Lifecycle controls](/echomq/lifecycle) — the dedicated EchoMQ course: the delay, promote, and retry scheduler
  in depth.
