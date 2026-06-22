# The sorted set as a clock

> R4 · orientation. One data structure — the Redis sorted set — is read two ways. Score a job by a future
> timestamp and the set is a timer wheel; score it by a composite priority and the set is a priority ladder. The
> member is always the job id; only the score's meaning changes, and the commands (`ZADD`, `ZRANGEBYSCORE`,
> `ZPOPMIN`) stay constant.

**Route:** `/redis-patterns/time-delay-priority/the-sorted-set-as-a-clock`

A sorted set stores members ordered by a numeric score. That is the whole structure: a member, a score, and the
ordering the score implies. Two patterns in this chapter use one sorted set; the only thing that differs between
them is what the score is taken to mean. Read the score as a fire-time and the set is a delayed queue. Read it as a
packed priority and the set is a priority queue. The member stays the job id, and the read commands never change —
which is the orientation this dive surveys before the granular modules take each reading in depth.

## The textbook delayed queue

The classic delayed-queue pattern scores each task by the Unix timestamp at which it should run, and stores it in a
sorted set. Tasks order themselves by execution time, earliest first, with no extra bookkeeping.

- **Member** — the task identifier.
- **Score** — the Unix timestamp at which the task should run.

To schedule a task five minutes out, `ZADD delayed_queue 1706649000 "task:abc123"`. A worker polls for tasks whose
time has passed with a range query bounded above by the current clock: `ZRANGEBYSCORE delayed_queue -inf <now>
LIMIT 0 10` returns up to ten tasks with scores at or below now. The `-inf` lower bound means "no floor".

Many workers may poll the same set at once, so a worker must claim each task atomically before processing it. `ZREM
delayed_queue "task:abc123"` returns `1` when this call removed the member — the caller won the claim — or `0` when
another worker already removed it. A worker processes a task only when its `ZREM` returns `1`. The complete flow is
poll → claim → process → clean up.

Constant polling of an empty set wastes work. The avoidance is to read the head and sleep until it is due: `ZRANGE
delayed_queue 0 0 WITHSCORES` returns the earliest task and its scheduled time. When nothing is due yet, a worker
sleeps until that time, or a bounded maximum interval, which cuts polling overhead when the set is empty or the
next task is far out. A failed task reschedules itself by re-adding with a future score (`ZADD delayed_queue
<now + 60> "task:abc123"`), so a retry is a delayed task like any other.

**The hero interactive — the delayed-queue simulator.** A fixed set of six jobs, each with a fire-time offset from a
notional `now = 0`. The slider sets the current clock from 0 to 120 seconds. On every move it computes the due set
(every job whose fire-time is at or below the clock — the `ZRANGEBYSCORE 0 now` semantics) and the next wake (the
smallest fire-time strictly above the clock — the head, `ZRANGE 0 0`). The readout names the due job ids, the count,
and the next wake offset, or reports that the set is idle once everything is due.

> Score a job by its fire-time and a range query bounded by the current clock returns exactly the jobs whose time
> has come; reading the head gives the next wake, so a worker sleeps instead of spinning.

## The second reading: a priority ladder

The same set shape carries a second pattern. Leave the member as the job id, but score it by a composite of two
numbers packed into one: a priority tier in the high bits and an arrival counter in the low bits. The score becomes
`priority × 0x100000000 + arrival`. Now the sorted set is a priority queue: the smallest score is the most important
job, and within one priority tier the smallest score is the earliest arrival. A pop of the smallest, `ZPOPMIN`,
returns the next job to run in priority-then-FIFO order.

Packing two fields into one score is what makes the single read command work. The priority tier occupies the high 32
bits, so any job in a more important tier sorts ahead of every job in a less important one. The arrival counter
occupies the low 32 bits, so two jobs in the same tier break their tie by arrival order — first in, first out, inside
the tier. One number, two meanings, read by one `ZPOPMIN`.

**The main interactive — the two-readings toggle.** A control toggles the same fixed job set between two score
readings. Under **fire-time**, the jobs order by ascending fire-time and the read is `ZRANGEBYSCORE`. Under
**priority**, each job's composite score is computed as `tier × 0x100000000 + arrival`, the jobs order by ascending
score, and the read is `ZPOPMIN`. The two orders differ; the data structure is identical. Only the meaning assigned
to the score, and the read command that suits it, change.

> The member is constant and the commands are a fixed vocabulary; the score is the entire semantic axis. Reading it
> as a fire-time gives a timer wheel, reading it as a packed priority gives a priority ladder, over one structure.

## The bridge — what EchoMQ really stores

The textbook pattern scores by a raw Unix timestamp. EchoMQ keeps the structure and sharpens the score. Its delayed
set is `EchoMQ.Keys.delayed/1` → `emq:{queue}:delayed`, scored by `(timestamp + delay) × 0x1000` — the fire-time
millisecond shifted left twelve bits so the low twelve bits can pack an ordering discriminator within a single
millisecond (`addDelayedJob-6.lua`'s `getDelayedScore`, `minScore = delayedTimestamp × 0x1000`). The recovery is
exact, not lossy: `getNextDelayedTimestamp` reads the head and returns `nextTimestamp / 0x1000`, dividing the shift
back out to recover the real millisecond.

Where the textbook worker sleeps and re-polls, EchoMQ runs a sweep. The included `promoteDelayedJobs` Lua function
ranges the due head — `ZRANGEBYSCORE delayedKey 0 (timestamp + 1) × 0x1000 - 1 LIMIT 0 1000` — then `ZREM`s each
member and moves it to the wait list. The priority reading is `EchoMQ.Keys.prioritized/1` →
`emq:{queue}:prioritized`, scored by `getPriorityScore` = `priority × 0x100000000 + (INCR pc) % 0x100000000` (the
priority tier in the high 32 bits, the `pc` arrival counter in the low 32 bits), and read by `ZPOPMIN`. Two named
sets, one sorted-set shape, two readings of the score.

> **The pattern:** one sorted set scores a job by a future timestamp to make a timer wheel, or by a packed priority
> to make a priority ladder; the member is constant and the score is the meaning.
>
> **→ In EchoMQ:** `emq:{queue}:delayed` scores by `(timestamp + delay) × 0x1000` and a `promoteDelayedJobs` sweep
> ranges the due head to wait; `emq:{queue}:prioritized` scores by `getPriorityScore` and is read by `ZPOPMIN` — the
> real Elixir time-and-priority sets.

The take: a delayed queue and a priority queue are the same sorted set under two readings of the score — `ZADD` to
insert, a range query or a `ZPOPMIN` to read — and the chapter that follows takes each reading apart.

## References

### Sources

- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the data type both
  readings stand on: members ordered by a numeric score, range and pop by score.
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — insert or update a member's score; the single write both the
  timer wheel and the priority ladder use.
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — the range query that reads the due head of a
  delayed set, the read in `promoteDelayedJobs`.
- [Redis — *ZPOPMIN*](https://redis.io/commands/zpopmin/) — pop the smallest-score member; the read that pulls the
  next job from a priority ladder.
- [BullMQ — *the queue protocol*](https://bullmq.io/) — the delayed and prioritized sets EchoMQ ports, where the Lua
  scripts are the protocol.

### Related in this course

- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter: every score reading of the
  sorted set, taken in turn.
- [R4 · Score as meaning](/redis-patterns/time-delay-priority/score-as-meaning) — the next dive: the score is the
  semantics — fire-time, composite priority, and next-run millis, three meanings over one structure.
- [R4 · The road ahead](/redis-patterns/time-delay-priority/the-road-ahead) — the arc R4.01→R4.06 and the door into
  EchoMQ's scheduler subsystem.
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter this one stands on: the reliable list-based queue the
  delayed and priority sets feed.
