# The sorted set as a clock

> **Route:** `/redis-patterns/time-delay-priority/the-sorted-set-as-a-clock` · R4 · orientation dive

One data structure — the Valkey sorted set — is read two ways. Score a job by a future millisecond and the set is a
timer wheel; arrange the set so its head is always the next job to serve and the set is an order. The member is
always the job id; only what the score means changes, and the commands (`ZADD`, `ZRANGEBYSCORE`, `ZPOPMIN`) stay a
fixed vocabulary.

A sorted set stores members ordered by a numeric score. That is the whole structure: a member, a score, and the
ordering the score implies. Two of this chapter's patterns ride one sorted set; the only thing that differs is what
the score is taken to mean. Read the score as a fire-time and the set is a delayed queue. Arrange the set so the
smallest score is always the next job and the set is an order. The member stays the job id, and the read commands
never change.

## The textbook delayed queue

The classic delayed-queue pattern scores each task by the millisecond at which it should run, and stores it in a
sorted set. Tasks order themselves by execution time, earliest first, with no extra bookkeeping.

- **Member** — the task identifier.
- **Score** — the millisecond at which the task should run.

To schedule a task five minutes out, `ZADD schedule 1706649000000 "task:abc123"`. A worker promotes tasks whose
time has passed with a range query bounded above by the current clock: `ZRANGEBYSCORE schedule -inf <now> LIMIT 0
10` returns up to ten tasks with scores at or below now. The `-inf` lower bound means "no floor". A promoted task is
`ZREM`'d off the schedule set and moved to the run queue. The complete flow is read-due → remove → promote.

Constant polling of an empty set wastes work. The avoidance is to read the head and sleep until it is due. When
nothing is due yet, a pump sleeps until the head's score, or a bounded maximum interval, which cuts overhead when
the set is empty or the next task is far out. A failed task reschedules itself by re-adding with a future score, so
a retry is a delayed task like any other.

**The hero interactive — the delayed-queue simulator.** A fixed set of six jobs, each with a fire-time offset from a
notional `now = 0`. The slider sets the current clock from 0 to 120 seconds. On every move it computes the due set
(every job whose fire-time is at or below the clock — the `ZRANGEBYSCORE -inf now` semantics) and the next wake (the
smallest fire-time strictly above the clock). The readout names the due job ids, the count, and the next wake
offset, or reports that the set is idle once everything is due.

> Score a job by its fire-time and a range query bounded by the current clock returns exactly the jobs whose time
> has come; reading the head gives the next wake, so a pump sleeps instead of spinning.

## The second reading: an order

The same set shape carries a second pattern. Leave the member as the job id, but arrange the score so the smallest
score is always the next job to serve. The textbook does this by packing two numbers into one score — a priority
tier in the high bits and an arrival counter in the low bits — so a `ZPOPMIN` returns the next job in
priority-then-FIFO order. EchoMQ reaches the same order through a simpler invariant: its `pending` set scores every
member with the same score, `0`, and lets the *member itself* — the branded job id — carry the order, because a
branded id sorts as its mint instant. The smallest member is the oldest job; a `ZPOPMIN` serves it.

**The main interactive — the two-readings toggle.** A control toggles the same fixed job set between two readings.
Under **fire-time**, the jobs order by ascending fire-time and the read is `ZRANGEBYSCORE`. Under **order**, every
job carries score `0` and orders by its mint-ordered id, and the read is `ZPOPMIN`. The two orders differ; the data
structure is identical. Only the meaning assigned to the score, and the read command that suits it, change.

> The member is constant and the commands are a fixed vocabulary; the score is the semantic axis. Reading it as a
> fire-time gives a timer wheel; flattening it to a constant and letting the id order gives a mint-ordered queue —
> over one structure.

## What EchoMQ really stores

The textbook scores by a raw timestamp and splits delayed and prioritized into separate sets. EchoMQ keeps the
structure and sharpens it to one set per reading. Its schedule set is `Keyspace.queue_key(queue, "schedule")` →
`emq:{q}:schedule`, scored by the run-at millisecond — `EchoMQ.Jobs.enqueue_at/6` writes the caller's absolute ms,
`enqueue_in/6` computes `now + delay_ms` from the server clock (`redis.call('TIME')`). No left-shift, no lossy
recovery: the score *is* the millisecond.

Where the textbook re-polls, EchoMQ runs `EchoMQ.Jobs.promote/3`. Its inline Lua reads the due head —
`ZRANGEBYSCORE KEYS[1] '-inf' now 'LIMIT' 0 ARGV[2]` — then `ZREM`s each member and `ZADD`s it onto the score-0
`pending` set, where the order reading takes over. The pending set is not a separate prioritized set; it is the
one queue, scored `0`, ordered by the branded `JOB` id, served oldest-first by the `claim` script's `ZPOPMIN`. Two
readings, one sorted-set shape.

> **The pattern:** one sorted set scores a job by a future millisecond to make a timer wheel, or flattens the score
> so the member's own mint order serves as the queue; the member is constant and the score is the meaning.
>
> **→ In EchoMQ:** `emq:{q}:schedule` scores by run-at ms and `EchoMQ.Jobs.promote/3` ranges the due head with
> `ZRANGEBYSCORE -inf now` to pending; `emq:{q}:pending` scores every member `0` and is served oldest-first by the
> `claim` script's `ZPOPMIN` — the real Elixir time-and-order sets.

The take: a delayed queue and a mint-ordered queue are the same sorted set under two readings of the score — `ZADD`
to insert, a range query or a `ZPOPMIN` to read — and the chapter that follows takes each reading apart.

## References

### Sources

- [Valkey — *Sorted sets*](https://valkey.io/topics/) — the data type both readings stand on: members ordered by a
  numeric score, range and pop by score.
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — insert or update a member's score; the single write both the
  timer wheel and the mint-ordered queue use.
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — the range query that reads the due head of a
  schedule set, the read in `EchoMQ.Jobs.promote/3`.
- [Redis — *ZPOPMIN*](https://redis.io/commands/zpopmin/) — pop the smallest-score member; the read that pulls the
  oldest job from the pending set.

### Related in this course

- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter: every score reading of the
  sorted set, taken in turn.
- [R4 · Score as meaning](/redis-patterns/time-delay-priority/score-as-meaning) — the next dive: the score is the
  semantics — fire-time, a flattened constant, and next-run millis, over one structure.
- [R4 · The road ahead](/redis-patterns/time-delay-priority/the-road-ahead) — the arc R4.01→R4.06 and the door into
  the EchoMQ Queue.
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter this one stands on: the reliable wait/active/done
  queue the schedule set feeds.
