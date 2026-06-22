# The busy-poll cost — the spin no interval fixes

> Route: `/redis-patterns/queues/blocking-vs-polling/the-busy-poll-cost` · Dive R3.05.1 · Module R3.05
> blocking-vs-polling · Chapter R3 Reliable Queues.
> · Grounding: the polling loop the source's `Blocking Variant` section replaces — `RPOP wait`; if nil,
> `sleep(interval)`; repeat. The contrast for the rest of the module is EchoMQ's blocking marker fetch
> (`do_wait_for_job/3` running `BZPOPMIN emq:{queue}:marker`); the polling form is also what the Go port's empty-queue
> worker loop does (`time.Sleep` in `apps/echomq-go/pkg/echomq/worker_impl.go`).

A worker that takes the next job by polling pays a cost on every empty queue. The loop is plain: pop the work list;
if the result is nil, sleep a fixed interval; repeat. The sleep interval is the only dial, and it cannot be set well —
short trades latency for round-trips, long trades round-trips for latency, and the loop pays both at once.

## The polling loop

The naive wait is a spin. The worker pops the work list; an empty queue returns nil; the worker sleeps, then polls
again.

```
# the polling loop — RPOP, sleep, retry
loop:
  job = RPOP wait              # nil when the queue is empty
  if job == nil:
    sleep(interval)            # burn the interval, then poll again
    continue
  process(job)                 # a job arrived — run it
```

Every pass that returns nil is a **wasted round-trip**: a command sent to Redis and a nil sent back, for no work. On a
queue that is empty most of the time, that is the steady state — the worker spends its life asking an empty queue
whether it is still empty.

## The latency a poll adds

A job rarely arrives exactly when the worker polls. It arrives somewhere in the gap between two polls, and waits the
rest of the gap before the next poll picks it up. Over many arrivals, the wait averages about **half the interval**:

```
poll        poll        poll        poll
 |           |     ↑      |           |
 |<-- interval -->|       |           |
                  job arrives here, waits ~½ interval for the next poll
```

A 100 ms interval adds about 50 ms of average pickup latency on top of the work itself. The interval is a floor on
responsiveness that no amount of worker speed removes.

## No interval wins

The two costs pull against each other on the one dial:

```
short interval (10 ms)   →  ~5 ms latency,  but ~100 empty polls/sec on an idle queue
long interval (1000 ms)  →  ~500 ms latency, but ~1 empty poll/sec
```

Shorten the interval to cut latency and the empty round-trips multiply. Lengthen it to cut the round-trips and pickup
latency grows. There is no value that is cheap on both axes, because polling pays for *checking* whether work exists
separately from *doing* the work. The fix is not a better interval. The fix is to stop polling: block on a primitive,
and let Redis return the instant work arrives — the next dive.

## In EchoMQ — the contrast the rest of the module removes

EchoMQ's worker does not run this loop on an idle queue. When no job is immediately available, it parks on a blocking
fetch — `EchoMQ.Worker.do_wait_for_job/3` runs `BZPOPMIN emq:{queue}:marker timeout` on a dedicated blocking
connection — so it spends no round-trips while idle and picks a job up the instant the producer rings the marker. The
polling loop above is what that blocking fetch replaces. It is also what the Go port's empty-queue worker loop does:
`apps/echomq-go/pkg/echomq/worker_impl.go` runs `time.Sleep(100 * time.Millisecond)` / `time.Sleep(time.Second)` when
the queue is empty — a fixed-interval poll, the cross-runtime contrast to the marker block.

The pattern says the wait-by-polling cost is paid twice and dialled once; in EchoMQ the worker blocks on the marker
instead, so the next two dives build the primitive and the handshake that remove the cost.

## References

### Sources
- [Redis — RPOP](https://redis.io/commands/rpop/) — the non-blocking pop the polling loop spins on, returning nil on an
  empty queue.
- [Redis — BLMOVE](https://redis.io/commands/blmove/) — the blocking move that removes the poll interval, built in the
  next dive.
- [Redis — Latency monitoring](https://redis.io/docs/latest/develop/use/patterns/) — the Redis patterns index, the home
  of the reliable-queue and blocking-consumer guidance.
- [BullMQ — the queue protocol](https://bullmq.io/) — the marker-based worker wait EchoMQ ports in place of the poll.

### Related in this course
- [R3.05 · Blocking vs polling](/redis-patterns/queues/blocking-vs-polling) — the module hub.
- [R3.05.2 · Blocking pop](/redis-patterns/queues/blocking-vs-polling/blocking-pop) — the primitive that removes the
  poll interval and the wasted round-trips.
- [R3.05.3 · The marker wake-up](/redis-patterns/queues/blocking-vs-polling/the-marker-wake-up) — the EchoMQ marker
  handshake that wakes the worker.
- [R3.01 · The processing list](/redis-patterns/queues/processing-list) — the wait/active lists the worker pops from.
- [E2 · The engine](/echomq/core) — the dedicated EchoMQ course: the worker fetch loop.
