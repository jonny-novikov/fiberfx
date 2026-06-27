# The busy-poll cost — the spin no interval fixes

> Route: `/redis-patterns/queues/blocking-vs-polling/the-busy-poll-cost` · Dive R3.05.1 · Module R3.05
> blocking-vs-polling · Chapter R3 Reliable Queues.
> Grounding: the polling loop the source's `Blocking Variant` section replaces — pop the work list; if nil,
> `sleep(interval)`; repeat. The contrast for the rest of the module is EchoMQ's parked consumer
> (`EchoMQ.Consumer.park/1` running `BLPOP emq:{queue}:wake <beat>`, real in
> `echo/apps/echo_mq/lib/echo_mq/consumer.ex`): "park, don't poll — a parked consumer costs the wire nothing."

A worker that takes the next job by polling pays a cost on every empty queue. The loop is plain: pop the work list;
if the result is nil, sleep a fixed interval; retry. On a queue that is empty most of the time, that nil-then-sleep is
the steady state, and it pays two costs that no single interval can both make cheap.

## The polling loop

The naive wait is a spin. Each pass sends a pop command and, when the queue is empty, gets a nil back. That nil is a
**wasted round-trip** — a full command-and-reply over the wire for no work. The worker then sleeps the interval and
tries again. The work of *checking* whether a job exists is paid separately from the work of *doing* the job, and on
an idle queue only the checking happens.

```
# the polling loop: spin, sleep, retry — every nil pass is a wasted round-trip
loop:
  job = pop work_queue -> processing
  if job == nil:
    sleep(interval)          # burn the interval, then poll again
    continue
  process(job)
```

The second cost is latency. A job rarely arrives exactly when the worker polls. It arrives in the gap between two
polls and waits the rest of that gap before the next poll picks it up, so average pickup latency is about **half the
interval**.

## The interval is the only dial — and it has no good setting

The interval is the single knob, and it sets the two costs against each other:

- A **short** interval cuts pickup latency but multiplies the empty round-trips on an idle queue — a 50 ms interval is
  twenty polls a second per worker, almost all of them empty.
- A **long** interval cuts the round-trips but lengthens pickup latency — a 1 s interval is one poll a second, but a
  job can wait up to a full second before pickup.

No value is cheap on both axes, because polling charges for checking and for doing as two separate things. The only
way off the trade is to stop checking on a cadence at all — to park until there is something to do.

## The cost, quantified

Over a fixed window with a known arrival rate, the polling cost is arithmetic:

- empty polls ≈ `window / interval` minus the polls that land on work,
- average pickup latency ≈ `interval / 2`,
- round-trips per second ≈ `1000 / interval` per idle worker.

Pick the interval and both numbers move in opposite directions. Sweep it and there is no minimum that satisfies both —
the wasteful end and the laggy end are the only choices polling offers.

## The bridge

**The pattern:** a pop/sleep loop pays a wasted round-trip on every empty poll and adds about half an interval of
pickup latency; the interval dials one cost against the other, and no setting wins.

**Its EchoMQ application:** `EchoMQ.Consumer` does not poll. Its loop drains the ring, then parks on
`BLPOP emq:{queue}:wake <beat>` — no spin, no empty round-trips, and a wake returns it the instant work is admitted.
The next dive builds that blocking park.

## On Valkey

A pop on an empty list returns nil immediately, so a polling loop must add its own sleep to avoid a tight spin — and
that sleep is exactly the interval that sets latency against round-trips. The blocking forms remove the sleep by
parking the connection on the server (valkey.io/commands/blpop).

## References

### Sources

- [Redis — Documentation](https://redis.io/docs/) — lists, pops, and why a polling loop needs an explicit sleep.
- [Valkey — LPOP](https://valkey.io/commands/lpop/) — the non-blocking pop a polling loop spins on; nil on an empty list.
- [Valkey — BLPOP](https://valkey.io/commands/blpop/) — the blocking alternative that removes the interval and the empty round-trips.

### Related in this course

- [R3.05 · Blocking vs polling](/redis-patterns/queues/blocking-vs-polling) — the module hub.
- [R3.05.2 · Blocking pop](/redis-patterns/queues/blocking-vs-polling/blocking-pop) — the next dive: the primitive that removes the spin.
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter.
- [/echomq/queue](/echomq/queue) — the Queue pillar: the consumer loop in depth.
