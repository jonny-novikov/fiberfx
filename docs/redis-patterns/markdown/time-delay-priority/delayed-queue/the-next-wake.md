# The next wake

> R4.01.3 · dive 3. Do not busy-poll an empty set. Read the head, compute the next due time, and wait until then —
> EchoMQ holds one `BLPOP emq:{q}:wake <beat>` block per queue in the metronome, and an admit's `LPUSH` on the wake
> token releases the single blocker so the promote sweep runs on demand, not on a busy tick.

**Route:** `/redis-patterns/time-delay-priority/delayed-queue/the-next-wake`

A delayed set sits idle most of the time: the jobs in it are due in the future, not now. A worker that re-runs the
due-sweep on a fixed tick spends round trips finding the same empty due head over and over. The avoidance is to read
the head once, learn when the next job is due, and wait that long. The textbook computes the sleep and sleeps. EchoMQ
holds one block per queue and is woken by the admit that creates work, so promotion runs when there is something to
promote and the bus stays quiet when there is not.

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
is due and the worker sweeps it. When the head is still in the future, the worker waits until that time, or a bounded
maximum interval, whichever is sooner — and proceeds with a job due, having spent no round trips in between. The wait
is computed from the head's score: `next_wake = head_score - now`.

This replaces a fixed tick with a head-driven wait. On an empty set the worker waits the maximum interval; with a job
far out it waits until that job is due; with a job due now it does not wait at all. The polling overhead collapses
toward zero when the set is idle or the next job is far off.

**The hero interactive — busy-poll versus the metronome beat.** A fixed set of delayed jobs and a notional idle
window. A control toggles between a fixed-tick poll and a single block woken by an admit. Under the poll, it counts
the round trips spent finding the empty due head across the window. Under the metronome, it shows one block that
returns the instant an admit `LPUSH`es the wake token, or on the beat timeout otherwise. The readout reports the
wasted polls avoided and the single beat that does the promote.

> The set already names its next wake: the head's score is when the earliest job is due. Hold one block instead of
> polling on a tick, and an idle set costs almost nothing.

## EchoMQ's metronome: one block per queue, woken by the admit

EchoMQ does not run a poll loop per worker. It holds one block per queue in `EchoMQ.Metronome` — a single process
that owns the only `BLPOP emq:{<queue>}:wake <beat>` and a registry of idle consumers. The beat is a bounded fallback;
the real wake is an admit. When a job is admitted, the producer `LPUSH`es the wake token, and the single block
returns at once. Each beat — whether woken by an admit or by the timeout — the metronome runs the reap and promote
pumps before poking the idle consumers:

```
# EchoMQ.Metronome (metronome.ex) — the beat (real)
{:ok, _} = Jobs.reap(conn, queue)                 # return expired leases to pending
{:ok, _} = Jobs.promote(conn, queue, pump_batch)  # promote the due schedule head
# then hold the single block until the next admit or the beat timeout:
Connector.command(conn, ["BLPOP", Keyspace.queue_key(queue, "wake"), secs], beat_ms + 2_000)
```

So promotion runs on demand. An admit that schedules a job `LPUSH`es the wake token; the metronome's single block
returns; the beat runs `promote/3`, which sweeps any due head onto the pending set; and the metronome pokes the idle
consumers, each running its byte-frozen claim once. The herd of pollers is gone — one connection blocks, one beat
sweeps, and the wake comes from the work, not from a clock the workers race. The `beat_ms` (default `1_000`) bounds
how long an idle queue waits before a fallback sweep; `pump_batch` (default `100`) caps how many due jobs one beat
promotes.

**The main interactive — the admit rings the beat.** A fixed schedule set with one job due soon. A control toggles
between two timings: the bounded beat fallback, and an admit that `LPUSH`es the wake token. On each it reports when
the promote sweep runs — at the beat timeout under the fallback, or at once under the admit — and how many round trips
the idle queue spent waiting in between (none, under either path).

> EchoMQ holds one block per queue: `BLPOP emq:{<queue>}:wake <beat>`. An admit `LPUSH`es the wake token to release it
> at once; otherwise the beat times out and runs the promote sweep — a due job is released without a busy poll.

## When a deferred job needs to survive a crash

A scheduled job lives on the `schedule` set in Valkey, which is fast but volatile — if the process holding it dies,
an in-flight schedule entry is only as durable as the bus's own persistence. For work that must survive a crash, the
deferred run is folded onto the durable substrate beneath the bus: an ETS head over a Valkey L2, a durable local page
tier, and a remote object store, with durability a dial a system turns rather than a fixed cost on every enqueue. The
mechanics of that floor — the single-writer page engine, the lazy reader, the commit fence — are a course of their
own: open the **[/echo-persistence](/echo-persistence)** course where a scheduled or retried job reaches the durable
floor, and **[/bcs · Persistence](/bcs/persistence)** for the same substrate read as architecture. This module
schedules and wakes the job; that course makes the schedule durable.

## In EchoMQ — the wake, in real code

The whole wake is real code in `echo/apps/echo_mq/lib/echo_mq/metronome.ex`. The metronome holds the single
`BLPOP emq:{<queue>}:wake <beat_ms>` per queue, the identical block the shipped consumer used to make, relocated to
one blocker. Its beat runs `EchoMQ.Jobs.reap/2` then `EchoMQ.Jobs.promote/3` — the reap returns expired leases to
pending, the promote sweeps the due schedule head onto the pending set — before poking the idle consumers. An admit's
`LPUSH` on the wake token releases the block, so a scheduled job whose time has come is promoted promptly, and an idle
queue holds one quiet block instead of a herd of polls.

> **The pattern:** do not poll an empty delayed set; read the head, compute when the next job is due, and wait until
> then rather than re-polling on a tick.
>
> **→ In EchoMQ:** `EchoMQ.Metronome` holds one `BLPOP emq:{<queue>}:wake <beat>` per queue, and each beat runs
> `EchoMQ.Jobs.reap/2` then `EchoMQ.Jobs.promote/3`; an admit's `LPUSH` on the wake token releases the single block at
> once, so the promote sweep runs on demand rather than on a busy poll.

The take: the head's score is the next wake; holding one metronome block per queue beats polling on a tick, and an
admit's `LPUSH` on the wake token releases it the instant there is something to promote.

## References

### Sources

- [Valkey — *BLPOP*](https://valkey.io/commands/blpop/) — the blocking pop the metronome holds on the wake token, so
  one block per queue replaces a herd of pollers.
- [Valkey — *LPUSH*](https://valkey.io/commands/lpush/) — the ring an admit writes to the wake token to release the
  single block at once.
- [Redis — *ZRANGE*](https://redis.io/commands/zrange/) — read the schedule head and its score: the earliest job and
  when it is due.
- [Redis — *Sorted sets*](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the data type behind the
  schedule set's head the wake reads.

### Related in this course

- [R4.01 · The delayed queue](/redis-patterns/time-delay-priority/delayed-queue) — the module hub.
- [R4.01.1 · The score is the fire-time](/redis-patterns/time-delay-priority/delayed-queue/score-is-fire-time) — the
  run-at score the schedule head carries.
- [R4.01.2 · ZRANGEBYSCORE promotion](/redis-patterns/time-delay-priority/delayed-queue/zrangebyscore-promotion) — the
  sweep the metronome beat runs once the wake fires.
- [R3.05 · Blocking vs polling](/redis-patterns/queues/blocking-vs-polling) — the blocking-pop pattern the metronome's
  single wake block is built on.
- [R4 · Time, Delay & Priority](/redis-patterns/time-delay-priority) — the chapter.
- [/echo-persistence](/echo-persistence) — the durable floor a scheduled or retried job reaches when it must survive a
  crash.
- [/echomq · Queue](/echomq/queue) — the dedicated EchoMQ course: the metronome, the promote pump, and the consumer
  pool in depth.
