# ZRANGEBYSCORE promotion

> R4.01.2 · dive 2. The due-sweep: range the delayed set from `0` to the current clock, claim each member with
> `ZREM`, and move it to the wait list. EchoMQ runs this as an included `promoteDelayedJobs` function inside the
> worker scripts, not a standalone poll.

**Route:** `/redis-patterns/time-delay-priority/delayed-queue/zrangebyscore-promotion`

A delayed job scored by its fire-time sits in the set until its time comes. Something has to notice it is due and move
it to where workers fetch. That move is the sweep: a range query for everything at or below the current clock, an
atomic claim of each due member, and a push to the wait list. The textbook runs it as a poll loop. EchoMQ folds the
same range-then-claim into the scripts the workers already run, so the sweep happens on the path of normal work.

## The due-range read

The read is a range query bounded above by the current clock. Every member from the start of the set up to now is due:

```
ZRANGEBYSCORE delayed_queue -inf <now> LIMIT 0 10
```

`-inf` is "no floor" — start from the lowest score. The upper bound is the current time. `LIMIT 0 10` caps the batch
to ten so one sweep claims a bounded slice and a backlog drains over several sweeps rather than one giant move. The
result is the due head: the members whose fire-time has passed, earliest first.

The range is a read only. It names the due jobs; it does not remove them. Between the read and the removal another
worker can read the same members, which is why the claim must be atomic and separate.

## The atomic claim

Each due member is claimed with a `ZREM`. The removal is the claim:

```
ZREM delayed_queue "task:abc123"
```

`ZREM` returns `1` when this call removed the member — the caller owns the task — or `0` when another worker already
removed it. A worker proceeds with a task only when its `ZREM` returns `1`. With many workers sweeping the same set,
the range may hand the same member to several of them, but only one `ZREM` returns `1`; the rest get `0` and drop it.
The removal establishes the owner, atomically, with no extra lock.

**The hero interactive — step the clock, sweep the due head.** A fixed set of six jobs with fire-times. A control
steps the clock forward in stages. On each step it computes the due range (`ZRANGEBYSCORE 0 → now`), the members it
returns, and the `ZREM` that claims and removes each. The readout names the promoted job ids and the count, and shows
the set shrinking as the swept jobs leave.

> Range the set from the start to the current clock to read the due head, then `ZREM` each member to claim it; the
> removal is the claim, so only one worker promotes each due job.

## Folding it into one script

The range and the `ZREM` are two commands, and between them a second worker can interleave. To make poll-and-claim a
single atomic step, run both inside a Lua script:

```
local tasks = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', ARGV[1], 'LIMIT', 0, ARGV[2])
for i, task in ipairs(tasks) do
    redis.call('ZREM', KEYS[1], task)
end
return tasks
```

The script reads the due head and removes every member in one round trip; no other worker can claim a job between the
range and the `ZREM`. This is the shape EchoMQ's sweep takes — a range, a `ZREM`, and a move to the target list, all
inside one script, on the worker path.

## EchoMQ's promoteDelayedJobs sweep

In EchoMQ the sweep is `promoteDelayedJobs`, an included function — an identical copy compiled into
`moveToActive-11.lua`, `retryJob-11.lua`, and `moveToFinished-14.lua`. It is not a standalone script and is never
called as one; it runs as part of the scripts the workers already execute, so a due delayed job is promoted on the
path of normal work, not by a separate poller. Its body is the range-then-claim, with the shifted upper bound the
fire-time score requires:

```
-- promoteDelayedJobs (included in moveToActive-11 / retryJob-11 / moveToFinished-14) — the due-sweep (real)
local jobs = rcall("ZRANGEBYSCORE", delayedKey, 0, (timestamp + 1) * 0x1000 - 1, "LIMIT", 0, 1000)
if #jobs > 0 then
  rcall("ZREM", delayedKey, unpack(jobs))            -- claim the whole due head atomically
  for _, jobId in ipairs(jobs) do
    -- priority 0 → LPUSH onto the wait list; priority > 0 → ZADD onto the prioritized set
  end
end
```

The upper bound is `(timestamp + 1) × 0x1000 - 1`, not `timestamp`, because the score is the fire-time shifted twelve
bits: that bound is the top of the current millisecond's band, so the range catches every job due in this millisecond
including its within-millisecond tie-breaks. The `LIMIT 0 1000` caps each sweep at a thousand jobs. Each promoted job
goes to the wait list when its priority is `0`, or onto the prioritized set when it carries a priority — the priority
reading the chapter takes up in a later module.

A distinct script promotes a single named job on demand: `EchoMQ.Scripts.promote/3` runs `promote-9.lua`, which
`ZREM`s one job from the delayed set (`KEYS[1]`) and moves it to the wait list (`KEYS[2]`). The bulk
`promoteDelayedJobs` sweeps the whole due head by score; `promote-9.lua` promotes one job by name, now. Two moves, one
shape.

> **The pattern:** sweep the delayed set by reading the due head with a range query and claiming each member with an
> atomic `ZREM`, then move it to the queue workers fetch from.
>
> **→ In EchoMQ:** `promoteDelayedJobs` is an included function in `moveToActive-11.lua`, `retryJob-11.lua`, and
> `moveToFinished-14.lua` — it runs `ZRANGEBYSCORE delayedKey 0 (timestamp + 1) × 0x1000 - 1 LIMIT 0 1000`, `ZREM`s the
> due head, and moves each to the wait or prioritized set; `EchoMQ.Scripts.promote/3` promotes one named job on demand.

The take: the due-sweep is a range to read the head and a `ZREM` to claim it; EchoMQ folds it into the worker scripts
as `promoteDelayedJobs`, so a delayed job is promoted on the path of normal work, never by a separate poller.

## References

### Sources

- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — read the due head: every member from the
  start of the set up to the current clock.
- [Redis — *ZREM*](https://redis.io/commands/zrem/) — the atomic claim: `1` means this caller promoted the job, `0`
  means another already did.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the data type the sweep
  ranges over, ordered by fire-time score.
- [BullMQ — *the queue protocol*](https://bullmq.io/) — the delayed-promotion sweep EchoMQ ports, where the Lua
  scripts are the protocol.

### Related in this course

- [R4.01 · The delayed queue](/redis-patterns/time-delay-priority/delayed-queue) — the module hub.
- [R4.01.1 · The score is the fire-time](/redis-patterns/time-delay-priority/delayed-queue/score-is-fire-time) — the
  fire-time score the sweep ranges over.
- [R4.01.3 · The next wake](/redis-patterns/time-delay-priority/delayed-queue/the-next-wake) — the next dive: not
  sweeping an empty set, waking on the marker instead.
- [R3.01 · The processing list](/redis-patterns/queues/processing-list) — the wait/active lists the swept job lands in.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [E6 · Lifecycle controls](/echomq/lifecycle) — the dedicated EchoMQ course: the promote and retry scheduler in depth.
