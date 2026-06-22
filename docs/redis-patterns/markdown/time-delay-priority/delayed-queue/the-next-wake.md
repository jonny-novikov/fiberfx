# The next wake

> R4.01.3 · dive 3. Do not busy-poll an empty set. Read the head, compute the next due time, and sleep until then —
> EchoMQ carries the next fire-time as a delay marker's score so a blocked worker wakes exactly when the next job is
> due, not on a poll tick.

**Route:** `/redis-patterns/time-delay-priority/delayed-queue/the-next-wake`

A delayed set sits idle most of the time: the jobs in it are due in the future, not now. A worker that re-runs the
due-sweep on a fixed tick spends round trips finding the same empty due head over and over. The avoidance is to read
the head once, learn when the next job is due, and wait that long. The textbook computes the sleep and sleeps. EchoMQ
carries the next fire-time on a marker so the wait is a single block that returns the instant the job is due.

## The cost of busy-polling

Polling an empty set on a fixed tick wastes work. Every tick the worker runs the due-range, gets nothing back, and
sleeps a fixed interval — then repeats, whether or not anything has changed. The shorter the tick the more round
trips wasted on an empty set; the longer the tick the later a due job is noticed. A fixed poll cadence cannot be both
responsive and cheap.

The waste is not a job that runs slowly; it is a worker spending round trips to learn nothing. On an idle set, every
poll returns the same empty due head, and the interval between polls is latency added to whatever job lands next.

## Read the head, compute the next wake

The set already holds the answer. Its head is the earliest-due job, and its score is when that job is due:

```
ZRANGE delayed_queue 0 0 WITHSCORES
```

This returns the earliest task and its scheduled time in one command. When the head's time is at or below now, a job
is due and the worker sweeps it. When the head is still in the future, the worker sleeps until that time, or a bounded
maximum interval, whichever is sooner — and wakes with a job due, having spent no round trips in between. The sleep is
computed from the head's score: `next_wake = head_score - now`.

This replaces a fixed tick with a head-driven wait. On an empty set the worker sleeps the maximum interval; with a job
far out it sleeps until that job is due; with a job due now it does not sleep at all. The polling overhead collapses
toward zero when the set is idle or the next job is far off.

**The hero interactive — busy-poll versus head-wait.** A fixed set of delayed jobs and a notional idle window. A
control toggles between a fixed-tick poll and the head-driven wait. Under the poll, it counts the round trips spent
finding the empty due head across the window. Under the head-wait, it computes one sleep to the head's fire-time. The
readout reports the wasted polls avoided and the single next-wake offset.

> The set already names its next wake: the head's score is when the earliest job is due. Sleep to that time instead
> of polling on a tick, and an idle set costs almost nothing.

## EchoMQ's delay marker: wake exactly when due

EchoMQ does not sleep-and-recompute. It carries the next fire-time on a marker so a worker blocked on the marker wakes
at exactly the right time. A worker parks on `BZPOPMIN` on the marker set (the blocking pop covered in R3.05). For a
plain job the producer rings the marker with a score of zero — `ZADD markerKey 0 "0"` — which wakes the worker now,
because a plain job is due now. For a delayed job the marker carries the fire-time instead.

`addDelayMarkerIfNeeded` reads the head of the delayed set, recovers its real time, and writes that time as the
marker's score:

```
-- addDelayMarkerIfNeeded.lua (included by addDelayedJob-6) — carry the next fire-time on the marker (real)
local nextTimestamp = getNextDelayedTimestamp(delayedKey)   -- reads the head, returns headScore / 0x1000
if nextTimestamp ~= nil then
  rcall("ZADD", markerKey, nextTimestamp, "1")              -- marker score = the next fire-time (ms)
end
```

`getNextDelayedTimestamp` reads the delayed head and returns `nextTimestamp / 0x1000` — it divides out the
twelve-bit shift the fire-time score carries, recovering the real millisecond. That millisecond is written as the
marker's score with `ZADD markerKey nextTimestamp "1"`. A worker blocked on the marker wakes when the marker's
lowest score becomes available, which the runtime schedules for the next fire-time — so the worker wakes exactly when
the next delayed job is due, not on a poll tick. The marker's member is `"1"` for a delayed wake, distinct from the
`"0"` of the base marker that wakes a worker for a plain job now.

**The main interactive — the marker's score is the next wake.** A fixed delayed set. A control adds or removes the
earliest job. On each change it reads the new head, recovers `headScore / 0x1000` as the real fire-time, and writes
it as the marker score with `ZADD markerKey nextTimestamp "1"`. The readout names the head's raw score, the recovered
millisecond, and the marker score the blocked worker will wake on.

> EchoMQ carries the next fire-time on the marker: `ZADD markerKey (headScore / 0x1000) "1"`, so a worker blocked on
> `BZPOPMIN` wakes when the next delayed job is due, with no poll in between.

## In EchoMQ — the delay marker, in real code

The whole wake is real code in `echo/apps/echomq`, in `addDelayedJob-6.lua`. `getNextDelayedTimestamp` reads the head
and returns `nextTimestamp / 0x1000`, dividing out the shift to recover the millisecond. `addDelayMarkerIfNeeded`
writes that millisecond as the marker score with `rcall("ZADD", markerKey, nextTimestamp, "1")`. The base marker for a
plain due-now job is `ZADD markerKey 0 "0"` instead — the same marker, a different score, so the worker wakes now for
a plain job and at the fire-time for a delayed one.

The recovery is the linchpin. Because the fire-time score is `ms × 0x1000`, the head's raw score is not a time a
worker can sleep to; dividing by `0x1000` recovers the real millisecond, and that millisecond is what the marker
carries. The shift that packs the within-millisecond discriminator is divided back out exactly, so the wake time is
precise.

> **The pattern:** do not poll an empty delayed set; read the head, compute when the next job is due, and wait until
> then rather than re-polling on a tick.
>
> **→ In EchoMQ:** `getNextDelayedTimestamp` reads the head and returns `headScore / 0x1000`, and
> `addDelayMarkerIfNeeded` writes it as the marker score with `ZADD markerKey nextTimestamp "1"`, so a worker blocked
> on `BZPOPMIN` wakes exactly when the next delayed job is due — the base marker `ZADD markerKey 0 "0"` wakes it now
> for a plain job.

The take: the head's score is the next wake; sleeping to it beats polling on a tick, and EchoMQ carries that
fire-time on the marker so a blocked worker wakes the instant the next delayed job is due.

## References

### Sources

- [Redis — *BZPOPMIN*](https://redis.io/commands/bzpopmin/) — block on a sorted set until a member is available; the
  marker pop the worker parks on to wake at the next fire-time.
- [Redis — *ZADD*](https://redis.io/commands/zadd/) — write the next fire-time as the marker's score; the ring that
  schedules the wake.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the data type behind both
  the delayed set's head and the marker the worker blocks on.
- [BullMQ — *the queue protocol*](https://bullmq.io/) — the delay-marker wake protocol EchoMQ ports, where the Lua
  scripts are the protocol.

### Related in this course

- [R4.01 · The delayed queue](/redis-patterns/time-delay-priority/delayed-queue) — the module hub.
- [R4.01.1 · The score is the fire-time](/redis-patterns/time-delay-priority/delayed-queue/score-is-fire-time) — the
  shifted score the head carries, recovered by dividing by `0x1000`.
- [R4.01.2 · ZRANGEBYSCORE promotion](/redis-patterns/time-delay-priority/delayed-queue/zrangebyscore-promotion) — the
  sweep the wake triggers when the marker fires.
- [R3.05 · Blocking vs polling](/redis-patterns/queues/blocking-vs-polling) — the `BZPOPMIN` block and the base marker
  the delay marker extends.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [E6 · Lifecycle controls](/echomq/lifecycle) — the dedicated EchoMQ course: the delay marker and scheduler coordination
  in depth.
