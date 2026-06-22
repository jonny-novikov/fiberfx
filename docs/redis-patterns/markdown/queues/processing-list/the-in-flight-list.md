# The in-flight list — the recovery ledger

> Route: `/redis-patterns/queues/processing-list/the-in-flight-list` · Dive R3.01.3 · Module R3.01 Processing list.
> · Grounding: EchoMQ's `emq:{queue}:active` (`EchoMQ.Keys.active/1`) is the in-flight list a crashed worker leaves a
> job parked in; the lock `emq:{queue}:<id>:lock` (`EchoMQ.Keys.lock/2`) marks the holding worker. The ack is
> `LREM active 1 job` after the work is done. Real in `echo/apps/echomq`.

The in-flight list is not a buffer to pass jobs through quickly. It is a ledger: at any instant it holds exactly the
jobs currently being processed. Because a job stays in the ledger until the work is acknowledged, a worker that dies
mid-job leaves its job sitting in the ledger — found, attributed, and returnable. That property is the whole reason the
move into the list is atomic. This dive reads the list as a record of in-flight work.

## The list is a record, not a buffer

A job moved into `active` does not pass through — it stays there for the entire duration of the work, and only an
explicit acknowledgement removes it. So `active` is a live record: every job in it is a job a worker has taken and not
yet finished. Reading the list answers a question that matters for reliability — what work is in flight right now —
without any extra bookkeeping. The record is the list itself.

```
emq:{queue}:active  (LIST)   →  [ job 7, job 6 ]   two jobs in flight
```

This is what makes a crash recoverable. When a worker dies between taking a job and acknowledging it, the job is still
in `active`. Nothing was lost, because nothing removed it. A recovery process can read the list and see the parked job,
exactly because the list is a record of in-flight work and not a transient buffer.

## Per-worker lists attribute the parked job

One shared in-flight list works, but it cannot tell which worker holds which job. Giving each worker its own in-flight
list does: `processing:worker1`, `processing:worker2`. A job in `processing:worker1` is held by worker 1. When worker 1
dies, a recovery monitor reads worker 1's list, finds the parked jobs, and returns them to the waiting list for another
worker — `LMOVE processing:worker1 work_queue RIGHT RIGHT`. Per-worker lists make the attribution direct: the list name
is the worker.

```
processing:worker1  (LIST)   jobs held by worker 1
processing:worker2  (LIST)   jobs held by worker 2
```

A real engine refines the death signal beyond "how long has the job sat here." EchoMQ marks each in-flight job with a
lock that has a TTL, renewed by the live worker on a heartbeat; an expired lock is the death signal, and a stalled sweep
returns the job to the waiting list. R3.03 is that sweep. Here the shape is enough: a per-worker list attributes a
parked job to the worker that left it.

## The ack removes it only when done

A job leaves the in-flight list with one command: `LREM active 1 job` — remove one occurrence of this job from the
list. The discipline is *when* it runs: only after the work is truly complete. Run it too early — before the side effect
is durable — and a crash after the ack but before the effect loses the job for real, because the ledger no longer holds
it. Run it after the effect, and a crash before the ack leaves the job parked, recoverable, and redelivered.

```
job = RPOPLPUSH wait active   # take the job into the in-flight ledger
process(job)                  # do the work; durable side effect lands here
LREM active 1 job             # ack: remove from the ledger ONLY now
```

That ordering is what makes delivery at-least-once rather than at-most-once. A job is delivered again if the worker died
before the ack, and delivered once if the ack landed — never zero times. The cost is that a worker which finished the
work and died before the ack redelivers the job, which is why R3.02 makes the consumer idempotent. This dive's job is
the ledger and the ack; the redelivery cost is the next module's.

## The pattern, applied

EchoMQ's in-flight list is `emq:{queue}:active`, built by `EchoMQ.Keys.active/1` (`"#{base(ctx)}:active"`), real in
`echo/apps/echomq`. A job is moved into it under a lock named by `EchoMQ.Keys.lock/2` (`emq:{queue}:<id>:lock`,
`"#{job(ctx, job_id)}:lock"`), so the parked job is both in the ledger and attributable to its worker. A crash leaves
the job in `active` with its lock still set; once the lock's TTL expires, the stalled sweep returns it to `wait`. The
ack that removes a finished job from `active` runs only after the work is done.

```lua
-- moveToActive-11.lua — the job lands in the in-flight ledger, under a lock (real)
local activeKey = KEYS[2]    -- emq:{queue}:active  (EchoMQ.Keys.active/1)
local jobId = rcall("RPOPLPUSH", waitKey, activeKey)  -- job parked in the ledger
-- the lock emq:{queue}:<id>:lock (EchoMQ.Keys.lock/2) marks the holding worker
```

`{queue}` is a documentation placeholder for the queue name (`EchoMQ.Keys.base/1` is `"#{prefix}:#{name}"`), not the
cluster hash-tag `{tag}`. The lock manager, the heartbeat that renews the lock, and the stalled sweep that reads expired
locks are the dedicated EchoMQ course; this dive teaches the ledger and the ack.

## References

### Sources
- [Redis — Lists](https://redis.io/docs/latest/develop/data-types/lists/) — the list as a record of ordered elements,
  the in-flight ledger.
- [Redis — LREM](https://redis.io/commands/lrem/) — the ack: remove one occurrence of a job from the in-flight list
  after the work is done.
- [Redis — RPOPLPUSH](https://redis.io/commands/rpoplpush/) — the move that parks a job in the in-flight ledger
  atomically.
- [BullMQ — the queue protocol](https://bullmq.io/) — the active-list-plus-lock layout EchoMQ ports.

### Related in this course
- [R3.01 · Processing list](/redis-patterns/queues/processing-list) — the module hub: the in-flight move.
- [R3.01.1 · List as wait + active](/redis-patterns/queues/processing-list/list-wait-active) — the two named lists.
- [R3.01.2 · LMOVE / RPOPLPUSH](/redis-patterns/queues/processing-list/lmove-rpoplpush) — the atomic move that parks the
  job in this ledger.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — at-least-once and stalled recovery, the
  guarantees this ledger enables.
- [E2 · the engine](/echomq/core) — the dedicated EchoMQ course: the lock manager and stalled sweep in depth.
