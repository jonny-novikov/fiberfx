# Score as meaning

> The sorted set is one mechanism; the score is the whole semantic axis. Score a job
> by a future timestamp and the set is a delayed queue; score it by a composite
> priority and the set is a priority ladder; score it by a next-run time and the set is
> a scheduler registry. Same member, same commands — three meanings, all carried by one
> number.

**Route:** `/redis-patterns/time-delay-priority/score-as-meaning`
**Chapter:** R4 · Time, Delay & Priority — orientation dive
**Pager:** prev `the-sorted-set-as-a-clock` · next `the-road-ahead`

A sorted set stores members ordered by a floating-point score. The textbook delayed
queue uses the simplest possible score: a Unix timestamp. The member is the task id; the
score is when it should run; `ZRANGEBYSCORE` reads back everything due. That one idea —
the score is a number that sorts the set — is the whole pattern. This dive shows how
EchoMQ refines it: the same double can carry two meanings at once, because the bits of
the score are split into a high field and a low field.

## The score is a number that sorts

The delayed-queue pattern (`docs/redis-patterns/content/fundamental/delayed-queue.md.txt`)
schedules tasks with a sorted set whose score is a Unix timestamp:

```
ZADD delayed_queue 1706649000 "task:abc123"
ZRANGEBYSCORE delayed_queue -inf 1706648500 LIMIT 0 10
ZREM delayed_queue "task:abc123"
```

The member is the task id, the score is the fire-time, and the set stays ordered by
fire-time with no extra bookkeeping. A worker reads the due head with `ZRANGEBYSCORE`,
claims each task with an atomic `ZREM` (1 means this worker won the claim), and processes
it. Nothing in Redis is told what the score "means" — it is a number, and the set sorts
by it. The meaning lives in how the writer chooses the number and how the reader
interprets the order.

That freedom is the lever. Because the score is an arbitrary `double`, a writer can pack
more than one fact into it, as long as the bit layout still sorts the way the reader
needs. EchoMQ does exactly this on its `emq:{queue}:delayed` set.

### The hero interactive — the composite-score decoder

A priority tier (1–5; lower = more urgent) and an arrival number (0–999) feed the EchoMQ
priority formula `score = priority * 4294967296 + arrival`. The readout shows the decimal
score, the hex split (the tier in the high 32 bits, the arrival in the low 32), and where
the job sorts: served before any job in a higher-numbered tier, and after earlier arrivals
within its own tier.

## Packing two meanings into one double

EchoMQ scores its `:prioritized` set with a **composite priority**. The Lua function
`getPriorityScore` (verbatim in `addPrioritizedJob-9.lua`, `addDelayedJob-6.lua`,
`changePriority-7.lua`, `addJobScheduler-11.lua`, `promote-9.lua`, `addParentJob-6.lua`)
computes:

```
prioCounter = rcall("INCR", priorityCounterKey)        -- the :pc arrival counter
score       = priority * 0x100000000 + prioCounter % 0x100000000
```

`0x100000000` is 2³² = 4294967296. Multiplying the priority by 2³² shifts it into the
**high 32 bits** of the score; the arrival counter (the next value of `INCR :pc`) occupies
the **low 32 bits**. One double now carries two facts:

- **the priority tier** (high 32 bits) — the primary sort key. A lower tier value is more
  urgent, and `ZPOPMIN` pops the smallest score first, so tier 1 always outranks tier 2.
- **the arrival number** (low 32 bits) — the tiebreaker. Within a tier, the job that was
  enqueued first has the smaller arrival counter, so it has the smaller score and is served
  first. Strict priority across tiers, FIFO within a tier — from a single number.

The delayed set uses the same trick at a different scale. `getDelayedScore`
(`addDelayedJob-6.lua`) scores a delayed job by `delayedTimestamp * 0x1000`, where
`delayedTimestamp = timestamp + delay`. `0x1000` is 4096 = 2¹², so the fire-time in
milliseconds sits in the high bits and a 12-bit discriminator sits in the low bits — two
jobs due in the same millisecond can still be ordered. To recover the real millisecond,
`getNextDelayedTimestamp` reads the head and returns `nextTimestamp / 0x1000`, dividing
the 12-bit shift back out.

### The main interactive — the three-readings panel

One fixed example job, read three ways. Each reading computes the actual stored score and
names the write command and the read command:

- **fire-time** → `score = (now + delay) * 4096`; write `ZADD :delayed score id`; read
  `ZRANGEBYSCORE :delayed 0 now*4096`.
- **priority** → `score = tier * 4294967296 + arrival`; write `ZADD :prioritized score id`;
  read `ZPOPMIN :prioritized`.
- **next-run** → `score = nextRunMs`; write `ZADD :repeat nextRunMs key` (upsert); read
  `ZRANGE :repeat 0 0 WITHSCORES`.

The same job is stored three different ways because the score carries three different
meanings.

## The bridge — three sets, one mechanism

The third reading is the scheduler registry. EchoMQ's `:repeat` set
(`EchoMQ.Keys.repeat/1` → `"#{base}:repeat"`) is a **ZSET** scored by the next-run
millisecond: `storeRepeatableJob` (`addRepeatableJob-2.lua`, `addJobScheduler-11.lua`)
runs `ZADD repeatKey nextMillis customKey`, and **upserts** by reading the prior score
with `ZSCORE repeatKey customKey` and replacing it — so a reboot that re-registers the
same recurring job does not duplicate it. (The `keys.ex` doc-comment that calls `:repeat`
a "hash" is a source defect; the code uses `ZADD`/`ZSCORE`, which are ZSET commands.)

| reading | set | score | meaning |
| --- | --- | --- | --- |
| fire-time | `:delayed` | `(timestamp + delay) * 0x1000` | *when* a job runs |
| composite priority | `:prioritized` | `priority * 0x100000000 + (INCR :pc)` | *in what order* |
| next-run | `:repeat` | next-run millis (upsert) | *how often* |

Three sorted sets, one mechanism. The commands stay constant — `ZADD` to write,
`ZRANGEBYSCORE` / `ZPOPMIN` / `ZSCORE` / `ZRANGE` to read — and the score is the whole
semantic axis. To read an EchoMQ set is to read what its score means.

**Take:** the sorted set does not store time, priority, or schedule — it stores one number
per member and keeps the set ordered by it. The number is the meaning, and the writer
encodes it.

## References

### Sources

- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) —
  the data type: members ordered by a floating-point score, the substrate every reading
  shares.
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — add or update a member's score; the
  one write command behind all three readings (and the `:repeat` upsert).
- [Redis — *ZSCORE*](https://redis.io/commands/zscore/) — read a member's current score;
  the upsert check that lets `:repeat` replace a prior next-run rather than duplicate it.
- [Redis — *ZPOPMIN*](https://redis.io/commands/zpopmin/) — pop the lowest-scored member;
  the read that turns the composite-priority set into a strict-then-FIFO ladder.
- [BullMQ](https://bullmq.io/) — the reliable-queue protocol EchoMQ ports, where the
  composite priority and the `* 0x1000` delayed score originate.

### Related in this course

- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter: the
  sorted-set-as-clock family in one place.
- [R4 · The sorted set as a clock](/redis-patterns/time-delay-priority/the-sorted-set-as-a-clock) —
  the prior dive: one set, two readings (timer wheel and priority ladder).
- [R4 · The road ahead](/redis-patterns/time-delay-priority/the-road-ahead) — the arc
  R4.01→R4.06 and the door to EchoMQ's scheduler subsystem.
- [R3 · Blocking vs polling](/redis-patterns/queues/blocking-vs-polling) — the marker
  wake-up that replaces the textbook sleep-to-next-due.
