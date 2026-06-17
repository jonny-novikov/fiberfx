# Lifecycle controls

> Route: `/echomq/queue/lifecycle-controls` · surface: module hub (The Queue) · grounding: all **real code** in
> `echo/apps/echo_mq` (`jobs.ex`, `admin.ex`, `backoff.ex`, `repeat.ex`, `cancel.ex`, `stalled.ex`). No `[RECONCILE]`
> markers — every surface is verified on disk.

## The control plane

Enqueue, claim, complete is the spine. The control plane is everything an operator and a worker reach for *around* that
spine: control over **time** — schedule a job for later, retry it on a curve, run it on a cadence; control over the
**worker in hand** — cancel a long handler cooperatively, checkpoint its lease so it is not reaped mid-work, recover the
ones that stalled; and control over the **whole queue** — pause claiming, drain the backlog, obliterate a dead queue,
and reach into one job's row to fix it.

Three dives:

1. **Scheduling & recurrence** — `enqueue_at/5` + `enqueue_in/5` park a job on the schedule set at a run-at score (a
   visibility fence, not a second queue); `promote/3` releases the due ones; `Backoff.delay_ms/2` is the pure host-side
   curve the wire takes a literal value from; `Repeat` registers a cadence that mints a fresh job per occurrence.
2. **Cancellation & checkpoints** — the cooperative cancellation token (`EchoMQ.Cancel`); `extend_lock/5` checkpoints
   the lease; `EchoMQ.Stalled` is the count-thresholded sweep that recovers or dead-letters a job that keeps stalling.
3. **The operator plane** — `EchoMQ.Admin` pause/resume/drain/obliterate over the whole queue, and the per-job verbs on
   `EchoMQ.Jobs` (update the payload, write progress, append logs, remove a job, reprocess a dead one).

## The framing interactive (hub)

A control-surface map: pick a control (schedule · backoff · repeat · cancel · checkpoint · stalled · pause · drain ·
obliterate · per-job), the readout names the real module fn, the structure it touches, and the one-line effect. Pure
lookup over a fixed dataset.

## Bridge

- The pattern (Redis Patterns Applied): delay, schedule, and priority over Redis — a ZSET scored by run-at time, a
  promote pass, a backoff curve. `/redis-patterns/time-delay-priority` teaches the family.
- The implementation (echo_mq): the same machine, owned — the schedule set, `@promote`, `Backoff`, and the operator
  plane above it.

## References

### Sources
- valkey.io/commands/zadd/ — the schedule set insertion.
- valkey.io/commands/zrangebyscore/ — the due read promote runs.
- valkey.io/docs/ — the substrate of record.

### Related in this course
- /echomq/queue — The Queue.
- /echomq/protocol — the keyspace and the Lua layer the controls run on.
- /redis-patterns/time-delay-priority — the delay/schedule/priority family.
