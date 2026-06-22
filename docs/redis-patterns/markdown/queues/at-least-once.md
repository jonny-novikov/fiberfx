# At-least-once — delivered more than once, never zero

> Route: `/redis-patterns/queues/at-least-once` · Module R3.02 · Chapter R3 Reliable Queues.
> · Grounding: EchoMQ's producer-side deduplication. `EchoMQ.Keys.dedup/2` builds `emq:{queue}:de:{id}`
> (`"#{base(ctx)}:de:#{dedup_id}"`), the marker that drops a duplicate enqueue; `removeDeduplicationKey-1.lua`
> `GET`s that key and `DEL`s it only when it matches the job id. That is **producer-side** dedup — it stops two
> identical jobs from entering the queue. It does **not** make a consumer exactly-once. The consumer becomes
> exactly-once *in effect* only by being idempotent. All real in `echo/apps/echomq`.

Guarantee at-least-once message delivery using LMOVE to atomically transfer messages to a processing list, enabling
recovery if consumers crash before completing work.

R3.01 built the move that loses no job: the worker moves a job *into* an in-flight list with `LMOVE` (or the older
`RPOPLPUSH`), so a crash leaves the job parked and recoverable rather than gone. That move makes redelivery
*possible* — and that is the point. This module reads the consequence of that choice. A reliable queue does not
deliver a job once and exactly once; it delivers it **one or more times, never zero**. The cost of never losing a
job is that a job can run twice, and the responsibility for absorbing that lands on the consumer. Make the consumer
idempotent — running the same job twice must produce the same effect as running it once — and at-least-once delivery
yields an exactly-once *effect*.

## Recovery from Failures

A separate monitor process — a reaper — periodically scans the processing list for stalled messages. For each job
that has sat there longer than a timeout, it treats the worker as dead and moves the job back to the main queue with a
second atomic move. R3.01 grounded this in EchoMQ's stalled sweep. The recovery path is what makes the queue
reliable, and it is also what makes redelivery inevitable.

The window is precise. A worker takes a job into the in-flight list under a lock, applies the effect — charges a
card, writes a row, sends a mail — and then crashes *before* it can remove the job from the in-flight list. The
effect already happened; the acknowledgement did not. The reaper finds a job whose lock expired, returns it to the
main queue, and a second worker runs it again. The effect runs twice.

> **This guarantees "at-least-once" delivery — messages may be processed multiple times but are never lost.**

That sentence from the source is the whole bargain. The dependency chain is exact: R3.01's in-flight move makes
redelivery *possible* (that is the design); a finish-then-crash before the acknowledgement makes it *inevitable*;
therefore the consumer must be idempotent. There is no fourth option that removes the duplicate without
reintroducing the loss.

## Delivery Guarantees

This pattern provides **at-least-once** delivery, which is two properties stated together:

- **Messages are never lost** — a job always exists in some list (the main queue, the in-flight list), so no crash
  drops it.
- **Messages may be processed multiple times** — a worker that crashes after the effect but before the
  acknowledgement leaves the job in-flight, and recovery runs it again.

The three delivery guarantees that bound the design space are worth naming side by side. **At-most-once** removes the
job before the work, so a crash loses it — zero or one delivery, never a duplicate, but a job can vanish.
**At-least-once** keeps the job until the acknowledgement, so a crash redelivers it — one or more deliveries, never
zero, but a job can repeat. **Exactly-once** would be one delivery and exactly one — and it is not achievable as a
*delivery* guarantee, because the acknowledgement itself can be lost, which is the subject of the third dive.

A reliable queue must keep the job until it is acknowledged, so it is at-least-once. That is not a defect of the
implementation; it is the only point on the spectrum that loses no job.

> **For exactly-once semantics, make message handlers idempotent — processing the same message twice should produce
> the same result as processing it once.**

This is where the work moves to the consumer. Idempotency is the property that closes the gap: it converts
at-least-once *delivery* into an exactly-once *effect*. Some effects are naturally idempotent — a `SET key value`
overwrites to the same value however many times it runs. Others are not — an `INCR`, a charge, a row insert — and
those need a guard: a dedup marker claimed with `SET … NX` keyed by a stable job id, so the second delivery finds
the marker and skips.

## The pattern, applied

EchoMQ carries a real deduplication key, and it is worth being precise about what it does. `EchoMQ.Keys.dedup/2`
builds `emq:{queue}:de:{id}` (`"#{base(ctx)}:de:#{dedup_id}"`). A producer enqueuing a job with a deduplication id
claims this marker; a second enqueue carrying the same id is dropped because the marker is already present. The Lua
script `removeDeduplicationKey-1.lua` cleans it up: it `GET`s the key and `DEL`s it only when the stored value
matches the job id, so the cleanup never deletes a marker some other job holds.

This is **producer-side** deduplication. It stops two identical jobs from entering the queue at enqueue time. It is
**not** consumer exactly-once: it says nothing about a single job being *delivered* twice to a worker, because the
in-flight recovery path can still redeliver a job that already entered the queue once. Producer dedup and consumer
idempotency are two different keys protecting two different moments — the enqueue and the effect. The exactly-once
*effect* a reliable queue ships is the consumer's job: a naturally idempotent effect, or a marker claimed at
effect-time with `SET … NX`.

```
# at-least-once delivery + an idempotent effect = exactly-once effect (the consumer's job)
if SET dedup:{job_id} 1 NX:     # claim the marker; NX = only if absent
    apply_effect(job)           # first delivery: run the effect once
else:
    skip()                      # a redelivery: the marker is already set, do nothing
```

```elixir
# EchoMQ.Keys.dedup/2 — producer-side dedup key (real)
def dedup(ctx, dedup_id), do: "#{base(ctx)}:de:#{dedup_id}"   # emq:my_queue:de:<id>
```

**The bridge.** The pattern says a reliable queue is at-least-once and the consumer must be idempotent. In EchoMQ
the producer-side `EchoMQ.Keys.dedup/2` marker (`emq:{queue}:de:{id}`, cleaned by `removeDeduplicationKey-1.lua`)
deduplicates at enqueue, while the consumer's effect must still be made idempotent to absorb a redelivery the
recovery path cannot avoid.

## The three dives

- **At-least-once semantics** — the three delivery guarantees and why the move-under-lock yields at-least-once; the
  duplicate-on-crash-after-process-before-ack window. Messages are never lost; they may run more than once.
- **Idempotent consumers** — make the handler idempotent: a naturally idempotent `SET` versus a dedup marker for a
  non-idempotent `INCR` or charge. Worked example: a Portal enrollment, where enrolling a student twice equals
  enrolled once.
- **Why exactly-once is a lie** — the acknowledgement-gap argument: exactly-once *delivery* is impossible because the
  acknowledgement can be lost; exactly-once *effect* via idempotency is what you build. `de:{id}` is producer-side
  dedup, not consumer exactly-once.

## References

### Sources
- [Redis — SET](https://redis.io/commands/set/) — the `NX` option behind the idempotency marker (`SET … NX`): claim
  the key only if absent.
- [Redis — RPOPLPUSH](https://redis.io/commands/rpoplpush/) — the at-least-once move into the in-flight list that
  makes redelivery possible.
- [Redis — Redis queue](https://redis.io/glossary/redis-queue/) — the queue and its delivery-guarantee overview.
- [BullMQ — the queue protocol](https://bullmq.io/) — the worker path EchoMQ ports, including custom job ids and
  deduplication.

### Related in this course
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter.
- [R3.02.1 · At-least-once semantics](/redis-patterns/queues/at-least-once/at-least-once-semantics) — the three
  guarantees and the duplicate window.
- [R3.02.2 · Idempotent consumers](/redis-patterns/queues/at-least-once/idempotent-consumers) — the marker and the
  naturally idempotent effect.
- [R3.02.3 · Why exactly-once is a lie](/redis-patterns/queues/at-least-once/why-exactly-once-is-a-lie) — the
  acknowledgement-gap argument.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic move the move-under-lock rests
  on.
- [E2 · The EchoMQ core](/echomq/core) and [E6 · The lifecycle](/echomq/lifecycle) — the doors to the worker fetch
  loop and the acknowledge/finish lifecycle.
