# R6.02.3 · Lanes vs separate queues

> Route: `/redis-patterns/flow-control/fairness/lanes-vs-separate-queues` — a dive of R6.02.
> Grounding: `echo/apps/echo_mq` · `EchoMQ.Lanes` (`enqueue/5`, `claim/3`, `wclaim/3`, `depth/3`) · the keys
> `emq:{q}:ring` / `emq:{q}:g:<group>:pending`.

There are two ways to keep one producer from starving another. Give each producer its own lane inside one queue and
rotate the lanes, or give each producer its own separate queue. The first builds fairness into the queue; the
second pushes fairness out to whatever schedules the queues. This dive compares them and shows why EchoMQ takes the
lane.

## §1 The two shapes

A **lane** is a producer's pending set inside a shared queue (`emq:{q}:g:<group>:pending`). One queue holds every
lane, one ring (`emq:{q}:ring`) rotates them, and one set of consumers drains the lot. Fairness is a property of the
ring — a claim rotates one step and serves the lane it lands on, so every lane is served in turn.

A **separate queue** is a producer's own queue, a distinct keyspace, drained by its own consumers. There is no ring
across queues and no shared rota — each queue is independent, and whatever decides how much attention each queue
gets lives outside the queues, in the deployment.

Both isolate producers. The difference is *where the fairness lives*. With lanes it is inside the queue, constructed
by the rotation. With separate queues it is outside, in whatever schedules the consumers across the queues.

## §2 What the lane buys

One queue with lanes makes fairness a property you get for free from the claim. The ring rotates, every lane is
served in turn, and a weight (`wclaim/3` over the `gweight` hash) tilts the share of one lane against another —
*cross-lane*, because the lanes share one ring. None of that is expressible across separate queues: you cannot say
"serve lane B three times as often as lane A" when A and B are different queues with no shared rota.

The control operations are also one-slot and atomic. Every key of one queue carries the `{q}` hash tag, so the ring
and all the lanes hash to one cluster slot — which is what lets a claim touch the ring and a lane in one Lua script
without a CROSSSLOT error. Within that one slot, EchoMQ moves a job between lanes (`reassign/4`), recovers one
group's stalled work (`reap_group/4`), or drains one lane (`drain/3`) — each a single atomic operation on lanes that
share the slot. The same moves across separate queues are cross-keyspace and cannot be done atomically.

And the consumer pool is shared. One queue with lanes is drained by one set of consumers that the rota keeps busy
across every lane. Capacity is pooled — an idle moment on one lane is spent on another — so the machine stays full.

## §3 What separate queues buy, and the cost

Separate queues buy hard **isolation**. Different keyspaces, different consumers, different blast radius — a queue
that misbehaves, fills, or is misconfigured cannot touch another, because they share nothing. When producers must be
isolated for an operational or a security reason, separate queues are the honest answer.

The cost is the fairness and the operations. There is no cross-queue rota, so fairness between queues is whatever an
external scheduler imposes — and writing that scheduler is the work the ring did for free. There is no cross-queue
weight. The control moves that are atomic within one slot — moving work between producers, recovering one
producer's stalled work, draining one producer — become cross-keyspace and lose their atomicity. And the consumer
pool fragments: N queues need consumers allocated across them, so an idle queue's capacity sits idle rather than
helping a busy one, and the operational surface multiplies by N.

So the choice is the usual one between building a property in and bolting it on. Lanes build fairness into one queue
and keep the control atomic on one slot, at the cost of a shared blast radius. Separate queues give hard isolation,
at the cost of an external scheduler, no cross-queue weight, non-atomic cross-queue moves, and N times the
consumers and the operations.

**The bridge.** "Keep producers fair without starving each other" **↔** one EchoMQ queue holding a lane per
producer (`emq:{q}:g:<group>:pending`), the `emq:{q}:ring` rotated by `claim/3` to serve them in turn and `wclaim/3`
to weight them — fairness constructed by the ring, not delegated to an external scheduler across N queues.

A consumer shows the shape. codemojex runs one queue (`"cm"`) with a lane per player, so every player's guesses are
fair against every other player's through one shared ring and one consumer pool (`Codemojex.ScoreWorker`) — not N
per-player queues that would need a scheduler to keep fair and N pools of consumers to drain.

## References

### Sources

- Valkey — *LMOVE* (`https://valkey.io/commands/lmove/`) — the shared-ring rotation that makes fairness a property
  of one queue.
- Valkey — *Cluster specification* (`https://valkey.io/topics/cluster-spec/`) — the `{q}` hash tag co-locates a
  queue's keys on one slot, so cross-lane moves are atomic where cross-queue moves are not.
- Valkey — *Keyspace* (`https://valkey.io/topics/keyspace/`) — separate queues are separate keyspaces with no shared
  rota.
- Redis — *Documentation* (`https://redis.io/docs/`) — the list and sorted-set primitives the ring and the lanes are
  built from.

### Related in this course

- R6.02 · Fairness under load (`/redis-patterns/flow-control/fairness`) — the module hub.
- R6.02.1 · Starvation under load (`/redis-patterns/flow-control/fairness/starvation-under-load`).
- R6.02.2 · The weighted share (`/redis-patterns/flow-control/fairness/the-weighted-share`).
- `/echomq/queue` — the Queue pillar, one queue with lanes at scale.
- `/bcs/bus` — Part B3, the fair-lanes architecture and the one-namespace gate.
