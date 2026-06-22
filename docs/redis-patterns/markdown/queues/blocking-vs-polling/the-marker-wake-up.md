# The marker wake-up — a doorbell, not a queue

> Route: `/redis-patterns/queues/blocking-vs-polling/the-marker-wake-up` · Dive R3.05.3 · Module R3.05
> blocking-vs-polling · Chapter R3 Reliable Queues.
> · Grounding: EchoMQ's marker handshake. The worker parks on `emq:{queue}:marker` (a ZSET, `EchoMQ.Keys.marker/1`,
> *"the marker sorted set (for blocking operations)"*) with `BZPOPMIN` via `do_wait_for_job/3`. The producer side, when
> adding a job, runs `addBaseMarkerIfNeeded` → `ZADD emq:{queue}:marker 0 "0"` (verified in `addStandardJob-9.lua` and
> `drain-5.lua`), which makes the blocked `BZPOPMIN` return `:job_available`. All real in `echo/apps/echomq`.

EchoMQ blocks on a dedicated **marker** ZSET, not on the work list. The marker is a doorbell: the producer rings it
when it adds a job, and the ring wakes a worker parked on `BZPOPMIN`. One `ZADD` wakes one `BZPOPMIN`, so the marker
signals *that work arrived* without being the work itself.

## The marker is a ZSET

`EchoMQ.Keys.marker/1` builds `emq:{queue}:marker`, documented as *"the marker sorted set (for blocking operations)"*.
It is a separate key from the work lists `emq:{queue}:wait` and `emq:{queue}:active`. The worker does not block on the
work list; it blocks on the marker, and fetches the job from the work lists once woken. Splitting the signal from the
work keeps the blocking connection parked on one small key and the fetch on the main connection.

## The handshake

The wake-up is four steps across the worker side and the producer side.

```
1. worker:    BZPOPMIN emq:{queue}:marker 30      # park on the marker (blocking connection)
2. producer:  LPUSH    emq:{queue}:wait <jobId>   # add the job to the work list
   producer:  ZADD     emq:{queue}:marker 0 "0"   # ring the doorbell (addBaseMarkerIfNeeded)
3. worker:    BZPOPMIN returns [marker, "0", 0]    # the ZADD woke the parked block → :job_available
4. worker:    fetch the job from wait/active        # on the main connection, then run it
```

Step 1 parks the worker. Step 2 adds the job and rings the marker — `addBaseMarkerIfNeeded` runs `ZADD
emq:{queue}:marker 0 "0"` (verified in `addStandardJob-9.lua` and `drain-5.lua`). Step 3 is the wake: the `ZADD` gives
the marker a member, so the parked `BZPOPMIN` pops it and returns; `EchoMQ.Worker.do_wait_for_job/3` reads that as
`:job_available`. Step 4 fetches the job and runs the lifecycle. The marker's value is a constant `"0"` — its presence
is the whole signal.

## One ring wakes one worker

`BZPOPMIN` pops the lowest-scored member and removes it. A single `ZADD` adds one member, so a single `ZADD` wakes
exactly one parked `BZPOPMIN`; any other workers parked on the same marker stay parked, waiting for the next ring.

```
3 workers parked on BZPOPMIN emq:{queue}:marker
producer: ZADD emq:{queue}:marker 0 "0"   # rings once
→ exactly one worker wakes and fetches; the other two stay parked
```

This is fan-out fairness: one added job wakes one worker, not a thundering herd. The marker carries a member per ring,
so a burst of additions wakes a matching number of parked workers, one each. The base marker is scored `0`; a delayed
job rings a marker scored by its timestamp instead, which is the time-and-delay chapter's territory, not this one.

## In EchoMQ — the doorbell, in real code

The whole handshake is real code in `echo/apps/echomq`. The worker's blocking-fetch internals
`EchoMQ.Worker.wait_for_job/2` → `do_wait_for_job/3` park on `BZPOPMIN emq:{queue}:marker timeout` on the dedicated
blocking connection and return `:job_available` or `:timeout`. The producer's `addBaseMarkerIfNeeded` runs `ZADD
emq:{queue}:marker 0 "0"` whenever a job is added, in `addStandardJob-9.lua`, `drain-5.lua`, and the other add
scripts. The Go port's empty-queue worker loop does not park on this marker — it sleeps a fixed interval
(`time.Sleep(100 * time.Millisecond)` / `time.Sleep(time.Second)` in `apps/echomq-go/pkg/echomq/worker_impl.go`), the
cross-runtime contrast: a poll cadence rather than a marker block.

```
# addBaseMarkerIfNeeded.lua (included by addStandardJob-9 / drain-5) — ring the doorbell (real)
ZADD emq:{queue}:marker 0 "0"   -- adding a job ZADDs the marker → the blocked BZPOPMIN returns
```

The pattern says block on a signal and ring it when work arrives, so one ring wakes one worker; in EchoMQ the signal is
the `emq:{queue}:marker` ZSET, the block is `BZPOPMIN`, and the ring is the producer's `ZADD marker 0 "0"`.

## Door — not depth

This module cites one excerpt of EchoMQ's protocol — the marker `BZPOPMIN` block and the producer's `ZADD` that wakes
it — as proof the blocking fetch ships. The full worker fetch loop, the dedicated blocking connection's lifecycle, and
the polyglot concurrency models that govern how each runtime parks and wakes are the subject of the dedicated **EchoMQ
course**, built next with this toolkit. The worker fetch loop is **E2 · the engine**; the marker / heartbeat
coordination across a worker pool is **E6 · the job lifecycle**. This module teaches the blocking-vs-polling pattern;
that course teaches the engine that runs it.

## References

### Sources
- [Redis — BZPOPMIN](https://redis.io/commands/bzpopmin/) — block on a sorted set until a member is added; the marker
  pop the worker parks on.
- [Redis — ZADD](https://redis.io/commands/zadd/) — add a member to a sorted set; the producer's `ZADD marker` that
  wakes a blocked worker.
- [Redis — Sorted sets](https://redis.io/docs/latest/develop/data-types/sorted-sets/) — the ZSET data type behind the
  marker and the `BZPOPMIN` pop.
- [BullMQ — the queue protocol](https://bullmq.io/) — the marker / `BZPOPMIN` doorbell EchoMQ ports, where the Lua
  scripts are the protocol.

### Related in this course
- [R3.05 · Blocking vs polling](/redis-patterns/queues/blocking-vs-polling) — the module hub.
- [R3.05.1 · The busy-poll cost](/redis-patterns/queues/blocking-vs-polling/the-busy-poll-cost) — the polling loop the
  marker block replaces.
- [R3.05.2 · Blocking pop](/redis-patterns/queues/blocking-vs-polling/blocking-pop) — the blocking primitive and the
  dedicated connection it parks on.
- [R3.01 · The processing list](/redis-patterns/queues/processing-list) — the wait/active lists the woken worker fetches
  from.
- [E2 · The engine](/echomq/core) — the dedicated EchoMQ course: the worker fetch loop and the blocking connection.
- [E6 · The job lifecycle](/echomq/lifecycle) — the dedicated EchoMQ course: the marker / heartbeat coordination and
  the polyglot concurrency models.
