# The score is the fire-time

> R4.01.1 · dive 1. The score of a delayed job is the time it should run. The textbook scores by a raw Unix
> timestamp; EchoMQ scores `(timestamp + delay) × 0x1000`, shifting the fire-time left twelve bits so the low twelve
> bits can discriminate jobs due in the same millisecond.

**Route:** `/redis-patterns/time-delay-priority/delayed-queue/score-is-fire-time`

A delayed queue is a sorted set whose score carries the meaning. For a delayed job that meaning is its fire-time —
the moment it becomes eligible to run. Score a job by its fire-time and the set orders its members by when they are
due, head first. The whole pattern rests on one decision: what number goes in the score. The textbook answer is the
fire-time itself. EchoMQ's answer is the fire-time shifted, so a single millisecond can hold more than one ordered job.

## The textbook score: the fire-time itself

The classic delayed-queue pattern puts the Unix timestamp at which the task should run directly into the score:

```
ZADD delayed_queue 1706649000 "task:abc123"
```

The score is the fire-time, second-for-second. The set sorts by it, so the earliest-due task is at the head, and a
range query bounded by the current clock returns the due tasks. The fire-time of a deferred task is `now + delay` — to
defer five minutes, score by `now + 300`. One number, one meaning: when this task should run.

This is enough for most schedulers. Its one weak spot is resolution. The Unix-second score gives every task scheduled
in the same second the identical score, and a sorted set keeps members with equal scores in lexicographic order of the
member, not arrival order. For most work that is fine. For a queue that schedules thousands of jobs a second and wants
them to keep their arrival order within a tick, the bare timestamp is too coarse.

## EchoMQ's score: the fire-time, shifted twelve bits

EchoMQ keeps the structure and sharpens the score. In `addDelayedJob-6.lua`, the included `getDelayedScore` computes:

```
delayedTimestamp = timestamp + delay         -- the fire-time, in milliseconds
minScore         = delayedTimestamp * 0x1000  -- shift left 12 bits (× 4096)
maxScore         = (delayedTimestamp + 1) * 0x1000 - 1
```

`0x1000` is `4096`, which is two-to-the-twelfth. Multiplying the millisecond fire-time by it shifts the value left
twelve binary places, leaving the low twelve bits at zero. Those twelve bits are now a free field below the
millisecond: every value from `minScore` to `maxScore` belongs to the same fire-time millisecond, and there are `4096`
of them. The job is added with `ZADD delayedKey score jobId`. A job with no contention takes `minScore` — the
millisecond's floor.

The recovery is exact, never lossy. `getNextDelayedTimestamp` reads the head and returns `nextTimestamp / 0x1000` —
divides the shift back out to recover the real millisecond. The shift packs an extra field into the low bits without
losing the time it sits above.

**The hero interactive — the fire-time, scored.** A slider sets a job's `delay` in milliseconds against a fixed
`now`. On every move it computes `delayedTimestamp = now + delay`, the textbook score `delayedTimestamp` (the bare
millisecond), and the EchoMQ score `delayedTimestamp × 0x1000`. The readout names all three and confirms the recovery
`score / 0x1000` returns the millisecond.

> The score of a delayed job is its fire-time. Scoring by the bare millisecond is the textbook; scoring by
> `millisecond × 0x1000` keeps the time and frees the low twelve bits for an ordering field.

## The low twelve bits: a within-millisecond discriminator

The reason for the shift shows when two jobs land on the same millisecond. The textbook bare-timestamp score gives
them the identical number, and the sorted set falls back to member order to break the tie. EchoMQ's shift gives the
set somewhere to put the tie-break. `getDelayedScore` checks the millisecond's band before inserting:

```
result = ZREVRANGEBYSCORE delayedKey maxScore minScore WITHSCORES LIMIT 0 1
currentMaxScore = the score of the highest job already in this millisecond band
if currentMaxScore is nil        -> return minScore          -- first job this ms: the floor
if currentMaxScore >= maxScore   -> return maxScore          -- band full: the ceiling
else                             -> return currentMaxScore + 1 -- one tick above the last
```

The first job to claim a millisecond takes `minScore`, the band's floor. The second job that lands on the same
millisecond takes `currentMaxScore + 1` — one tick above the first, a distinct score still inside the same
millisecond band. So two jobs due in the same millisecond get two distinct, ordered scores, and the set keeps them in
arrival order without falling back to member order. The band holds up to `4096` jobs per millisecond before it
saturates at `maxScore`.

**The main interactive — two jobs, one millisecond.** A control schedules two jobs to fire at the same millisecond.
The first takes `minScore = ms × 0x1000`; the second, finding the band occupied, takes `currentMaxScore + 1`. The
readout shows both scores, their difference of exactly one, and that both divide back to the same millisecond.

> Multiplying the fire-time by `0x1000` reserves twelve low bits per millisecond; the second job to claim a
> millisecond takes one tick above the first, so the two keep their order inside a single tick.

## In EchoMQ — the delayed score, in real code

The whole score is real code in `echo/apps/echomq`. The delayed set is `EchoMQ.Keys.delayed/1` →
`emq:{queue}:delayed`. The score is computed by `getDelayedScore`, an included function in `addDelayedJob-6.lua`:
`delayedTimestamp = timestamp + delay`, `minScore = delayedTimestamp × 0x1000`, the same-millisecond bump to
`currentMaxScore + 1`. The add is `rcall("ZADD", delayedKey, score, jobId)`. The recovery is `getNextDelayedTimestamp`
returning `nextTimestamp / 0x1000`.

```
-- getDelayedScore.lua (included by addDelayedJob-6) — score the job by its fire-time (real)
local delayedTimestamp = timestamp + delay
local minScore = delayedTimestamp * 0x1000          -- fire-time shifted left 12 bits
local maxScore = (delayedTimestamp + 1) * 0x1000 - 1
-- a job alone this ms takes minScore; a same-ms collision takes currentMaxScore + 1
```

The number chosen to carry the meaning is the whole pattern. The bare timestamp says only "this millisecond"; the
shifted timestamp says "this millisecond, and this position within it".

> **The pattern:** a delayed job is scored by its fire-time, so the sorted set orders its members by when they are
> due.
>
> **→ In EchoMQ:** `getDelayedScore` scores by `(timestamp + delay) × 0x1000`, reserving the low twelve bits so a
> same-millisecond collision takes `currentMaxScore + 1` — a distinct, ordered score inside one tick;
> `getNextDelayedTimestamp` recovers the real time by dividing by `0x1000`.

The take: scoring by the bare fire-time orders jobs by the millisecond; scoring by `fire-time × 0x1000` orders them by
the millisecond and by arrival inside it, and the time is recovered exactly by dividing the shift back out.

## References

### Sources

- [Redis — *ZADD*](https://redis.io/commands/zadd/) — add a member with its score; the single write that schedules a
  delayed job by its fire-time.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the data type behind the
  delayed set: members ordered by a numeric score.
- [Redis — *ZRANGEBYSCORE*](https://redis.io/commands/zrangebyscore/) — the range query the same score is later read
  by, the next dive's sweep.
- [BullMQ — *the queue protocol*](https://bullmq.io/) — the delayed-score protocol EchoMQ ports, where the Lua scripts
  are the protocol.

### Related in this course

- [R4.01 · The delayed queue](/redis-patterns/time-delay-priority/delayed-queue) — the module hub.
- [R4.01.2 · ZRANGEBYSCORE promotion](/redis-patterns/time-delay-priority/delayed-queue/zrangebyscore-promotion) — the
  next dive: reading the due head this score creates.
- [R4.01.3 · The next wake](/redis-patterns/time-delay-priority/delayed-queue/the-next-wake) — reading the head's score
  to compute the next due time.
- [R4 · Score as meaning](/redis-patterns/time-delay-priority/score-as-meaning) — the score is the semantics:
  fire-time, composite priority, next-run millis.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [E6 · Lifecycle controls](/echomq/lifecycle) — the dedicated EchoMQ course: the delay and promote scheduler in depth.
