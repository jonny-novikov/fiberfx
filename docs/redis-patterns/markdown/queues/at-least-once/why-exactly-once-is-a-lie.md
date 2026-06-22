# Why exactly-once is a lie — the acknowledgement can be lost

> Route: `/redis-patterns/queues/at-least-once/why-exactly-once-is-a-lie` · Dive R3.02.3 · Module R3.02 At-least-once.
> · Grounding: the acknowledgement-gap argument — exactly-once *delivery* is impossible because the acknowledgement
> itself can be lost; exactly-once *effect* via idempotency is what gets built. The precise distinction: EchoMQ's
> producer-side `EchoMQ.Keys.dedup/2` (`emq:{queue}:de:{id}`, cleaned by `removeDeduplicationKey-1.lua`) dedups at
> enqueue and is **not** consumer exactly-once. Real in `echo/apps/echomq`. Source roots: Delivery Guarantees and
> the closing idempotency line.

"Exactly-once delivery" is sold as a feature. It is not one. A delivery can be made at-least-once or at-most-once,
but not exactly-once, because the acknowledgement that would confirm a single delivery can itself be lost — and no
protocol closes that gap. What is real, and what every robust system actually builds, is an exactly-once *effect*:
at-least-once delivery on top of an idempotent consumer.

## The acknowledgement gap

The argument is the two-generals problem in queue clothing. A worker takes a job, does the work, and sends an
acknowledgement. The queue removes the job when the acknowledgement arrives. Now ask: what happens if the
acknowledgement is lost in transit, or the worker crashes the instant after sending it.

The queue is in a position with no clean exit. It sent the job and received no acknowledgement. Two histories produce
that exact state, and from the outside the two are indistinguishable:

- The worker never did the work (a real loss), so the job must be redelivered.
- The worker did the work and the acknowledgement was lost, so redelivering runs the work twice.

To guarantee no loss, the queue must redeliver on a missing acknowledgement. But redelivering on a missing
acknowledgement runs the second history twice. There is no third behaviour: redeliver and risk a duplicate, or do
not redeliver and risk a loss. A confirmation of the confirmation does not help — that message can be lost too, and
the regress never bottoms out. The gap is structural, not an implementation gap.

```
worker:  take job → do work → send ACK ──╳ (ACK lost here)
queue:   sent job, no ACK on record → must redeliver to avoid loss → work runs twice
         ("work never ran" and "ACK was lost" leave the same state)
```

So a queue picks a side. A reliable queue picks no-loss, which forces redeliver-on-missing-ack, which is
at-least-once. The duplicate is the price of never losing a job, and it is paid at the acknowledgement gap.

## Exactly-once effect is the real target

Exactly-once *delivery* is unreachable; exactly-once *effect* is reachable, and it is what the phrase should mean.
Hold at-least-once delivery — never lose a job — and make the consumer idempotent so a redelivery changes nothing
the second time. The effect happens once even though the delivery may happen twice. Systems that advertise
"exactly-once" deliver this: at-least-once transport plus an idempotent or deduplicating consumer. The honest framing
moves the guarantee from the delivery to the effect, where it can actually hold.

This reframing is not a downgrade. It is more honest and it is more robust, because it puts the duplicate-handling
where the duplicate is observable — at the effect, keyed by the job's identity — rather than pretending a transport
layer can see into a lost acknowledgement.

## Two keys, two jobs — producer dedup is not consumer exactly-once

The sharpest error in this area is to point at a deduplication key and call it exactly-once. EchoMQ's
`EchoMQ.Keys.dedup/2` builds `emq:{queue}:de:{id}` (`"#{base(ctx)}:de:#{dedup_id}"`), and
`removeDeduplicationKey-1.lua` cleans it up — it `GET`s the key and `DEL`s it only when the value matches the job id.
This is real and useful, and it is **producer-side**: it dedups at *enqueue*, dropping a second job that carries the
same deduplication id before it ever enters the queue.

That is a different job from consumer exactly-once. Producer dedup answers "two identical jobs were submitted — keep
one." Consumer idempotency answers "one job was delivered twice by the recovery path — apply its effect once." The
recovery sweep can redeliver a single in-flight job whose lock expired regardless of the producer dedup marker,
because that job already entered the queue exactly once. So the `de:{id}` marker does nothing to close the
acknowledgement gap at the consumer. The two keys protect two moments:

- **`emq:{queue}:de:{id}`** — producer-side, claimed at *enqueue*, keyed by the deduplication id, cleaned by
  `removeDeduplicationKey-1.lua`. Stops duplicate *submissions*.
- **`dedup:{job_id}` (`SET … NX`)** — consumer-side, claimed at *effect-time*, keyed by the job's identity. Absorbs
  duplicate *deliveries* from the recovery path.

Keep them distinct. Producer dedup is not the answer to "is my consumer exactly-once" — an idempotent consumer is.

```elixir
# producer-side dedup key — real, and NOT consumer exactly-once
def dedup(ctx, dedup_id), do: "#{base(ctx)}:de:#{dedup_id}"   # emq:my_queue:de:<id>, dedups at enqueue
```

**The bridge.** The pattern says exactly-once delivery is impossible because the acknowledgement can be lost, so
build an exactly-once effect on at-least-once delivery and an idempotent consumer. In EchoMQ the producer-side
`EchoMQ.Keys.dedup/2` marker dedups submissions at enqueue and is not consumer exactly-once; the exactly-once effect
is the consumer's, made by an effect-time `NX` marker or a naturally idempotent effect.

The full recovery coordination — the heartbeat manager, the lock TTL, the stalled-check across a worker pool — is the
dedicated EchoMQ course. This dive teaches why exactly-once delivery cannot exist; that course teaches the lifecycle
that makes the effect exactly-once anyway.

## References

### Sources
- [Redis — SET](https://redis.io/commands/set/) — the `NX` marker behind the consumer-side exactly-once effect.
- [Redis — Redis queue](https://redis.io/glossary/redis-queue/) — the queue and its delivery-guarantee framing.
- [Salvatore Sanfilippo — RPOPLPUSH (the reliable queue pattern)](https://antirez.com/news/77) — the design note for
  the reliable-queue move, by the creator of Redis.
- [BullMQ — the queue protocol](https://bullmq.io/) — the worker path EchoMQ ports, including custom ids and
  deduplication.

### Related in this course
- [R3.02 · At-least-once](/redis-patterns/queues/at-least-once) — the module hub.
- [R3.02.1 · At-least-once semantics](/redis-patterns/queues/at-least-once/at-least-once-semantics) — the three
  guarantees and the structural duplicate.
- [R3.02.2 · Idempotent consumers](/redis-patterns/queues/at-least-once/idempotent-consumers) — the exactly-once
  effect, built.
- [R3 · The reliable queue](/redis-patterns/queues/the-reliable-queue) — the family in one place.
- [R2.01 · Atomic updates](/redis-patterns/coordination/atomic-updates) — the atomic `SET … NX` claim.
- [E6 · The lifecycle](/echomq/lifecycle) — the acknowledge/finish lifecycle, in depth.
