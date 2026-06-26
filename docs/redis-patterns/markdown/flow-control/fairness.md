# R6.02 · Fairness under load

> Route: `/redis-patterns/flow-control/fairness` — the module hub.
> Grounding: `echo/apps/echo_mq` · `EchoMQ.Lanes` (`claim/3`, `wclaim/3`, `weight/4`, `enqueue/5`, `depth/3`) · the
> keys `emq:{q}:ring` / `emq:{q}:g:<group>:pending` / `emq:{q}:gweight` / `emq:{q}:gactive`. Manuscript figure:
> `bcs.3.md` §B3.2 "Jobs and lanes" (B3, `/bcs/bus`). Consumer: codemojex (`Codemojex.Guesses`).

Fairness under load is keeping every producer's work moving when one floods the queue. A single first-in,
first-out line lets one heavy producer starve the rest, so EchoMQ drains a set of lanes by a rotation that serves
each in turn, and a weight tilts the share without letting any lane take all of it.

This module is the retarget of priority. An earlier pattern reached for a numeric per-job priority — a composite
score that sorts the line so the urgent work jumps ahead. EchoMQ retired that by design: there is no numeric
per-job priority. Fairness comes from the rotation and the weight, not from a number stamped on each job, because
mint order plus the rota already give a fair line.

## §1 The starvation problem

A queue is the simplest shared resource: one line, drained first-come-first-served. That line is fair only when
the producers are evenly matched. Put one producer that submits a thousand jobs next to one that submits ten, and
the small producer waits behind the whole flood — the line is fair to *jobs* and unfair to *producers*. This is
starvation: the order is correct, and the outcome is not.

The fix is to stop treating the queue as one line. A queue is a set of **lanes**, each a per-group pending set
named by a branded id (`emq:{q}:g:<group>:pending`). Work is admitted into the lane of its group, so the heavy
producer fills its own lane and the small producer keeps its own. The line is no longer shared; the *machine* is
shared, and the question becomes how to drain many lanes fairly.

## §2 The rota — service by rotation

EchoMQ drains the lanes with a **ring**: `emq:{q}:ring` is a list holding exactly the lanes that can be served
right now — nonempty, unpaused, and below their concurrency limit. Every claim rotates the ring one step before it
serves, so the lane at the head changes on every claim. Fairness between identities is *constructed by the
rotation*, never hashed and never sorted.

The rotation is one Valkey operation. `LMOVE emq:{q}:ring emq:{q}:ring LEFT RIGHT` pops the head of the ring and
pushes it to the tail in one atomic move, then the claim serves the head of that rotated lane. The next claim
lands on the next lane, and the one after that on the one after — round and round, so a thousand-job lane and a
ten-job lane are each served once per turn of the ring. A lane that empties or hits its ceiling drops out of the
ring; it rejoins the moment it is serviceable again.

`EchoMQ.Lanes.claim/3` is that move: rotate the ring one step, serve the head of the rotated lane, lease the job
on the server clock, and return the job beside its group. No producer can jump the rota by submitting more — more
work fills its lane deeper, and the lane is still served once per turn.

## §3 The weighted share

Equal rotation is the floor. Sometimes one lane should be served *more* than the others — a paid tenant, a
latency-sensitive class — without ever being served *all* of the machine. That is a **weight**, not a priority.

A weight is a throughput share, an integer of one or more, set per lane with `EchoMQ.Lanes.weight/4`. It rides the
`emq:{q}:gweight` hash, the same shape as the concurrency keys, and it never parks a lane (a parked lane is the
operator's `pause/3`, not a weight of zero). `EchoMQ.Lanes.wclaim/3` is the weighted rotation: it rotates the ring
one step exactly as `claim/3` does, then serves the rotated lane **K heads in one turn** instead of one, where

    K = min(weight, the lane's pending depth, the glimit headroom)

The three clamps each guard something. The weight is the share. The lane's pending depth means the turn never
serves more than the lane holds. The `glimit` headroom — the room left under the lane's concurrency ceiling — means
the weighted multi-pop can never push `gactive` past `glimit`; a weight is a throughput share but the limit is a
concurrency ceiling, and the share bends to the ceiling. A higher-weight lane is served proportionally more over a
window, never all of it, because the rotation still visits every other lane in turn.

So fairness has two dials. The rotation gives every lane an equal turn; the weight tilts how much each lane gets
*per* turn. Neither is a number on a job.

## §4 Applied in EchoMQ

The rota is the shipped fairness. `EchoMQ.Lanes.claim/3` is how every consumer takes work, and the inline `@gclaim`
Lua is the rotate-then-serve: one `LMOVE` rotates the ring, `ZPOPMIN` takes the head of the rotated lane,
`HINCRBY` counts the attempt as the fencing token, and the server clock (`TIME`) sets the lease. `wclaim/3`
deepens the same one-step rotation to the lane's fair share.

The architecture is the bus's fair-lanes property, stated in the manuscript (`bcs.3.md`, B3):

> A queue is not one line; it is a set of lanes, each named by a branded id, drained fairly. `Lanes.claim` is how
> every consumer takes work, and it spreads claims across lanes so no one lane starves the rest — the fair-lanes
> property. Group-aware pause and resume act on a lane without touching the queue, so one tenant can be held while
> the others run. Work that should ride a lane and is enqueued ungrouped is never claimed; the lane is the unit of
> fairness and of control.

**The bridge.** Fairness under load — serve every producer in turn so no flood starves the rest **↔** the
`emq:{q}:ring` rotated one step per claim by `LMOVE`, `EchoMQ.Lanes.claim/3` serving the rotated lane's head, and
`wclaim/3` serving a higher-weight lane K = min(weight, depth, headroom) heads per turn. There is no numeric
per-job priority — "served more" is a property of the identity, not the work.

**A consumer.** In codemojex (`echo/apps/codemojex`), a Telegram emoji-guessing game on the same stack,
`Codemojex.Guesses.submit/3` enqueues each guess on the **player's lane** — the lane is named by the player's
branded `PLR` id, so the queue `emq:{cm}:g:<PLR…>:pending` holds one lane per player. The scoring consumer
(`Codemojex.ScoreWorker`) drains through `Lanes.claim`, the player id arriving as the lane group, so the bus
rotates service across players and one keyboard masher cannot starve the field.

The deeper enforcement — the consumer loop that holds the rota under sustained load, the per-group ceiling that
caps how much of the machine any one lane holds — is the queue's scaling layer, taught in the EchoMQ course.

## §5 When to use / when to avoid

**Reach for fair lanes when:**

- Many producers share one queue and one of them can run hot — fan-in from many tenants, many users, many rooms.
- A flood from one source must not delay the rest, and the order within each source must still be honoured.
- Some classes deserve a larger share of throughput than others, but none should ever take the whole machine.

**Avoid it when:**

- There is only one producer, or the producers are evenly matched — a plain line is simpler and equally fair.
- The constraint is total *concurrency*, not fairness between producers — that is the per-group ceiling
  (`limit/4`), a sibling primitive, not the rota.
- Strict global ordering across all producers is required — the rota deliberately interleaves lanes, so a job from
  a busy lane can be served after a later job from a quiet one.

## Dives

- **Starvation under load** — why one first-in, first-out line starves under a flood, and the rota guarantee that
  every lane is served in turn.
- **The weighted share** — `wclaim/3`, `weight/4`, and the `gweight` hash; K = min(weight, depth, glimit
  headroom); why a weight is a throughput share, not a pause, and why there is no numeric per-job priority.
- **Lanes vs separate queues** — one queue with lanes (fairness constructed by the ring) against N separate queues
  (no cross-queue fairness, an external scheduler, N× consumers).

## References

### Sources

- Valkey — *LMOVE* (`https://valkey.io/commands/lmove/`) — atomically pop one end of a list and push the other; the
  ring's one-step rotation.
- Valkey — *RPUSH* (`https://valkey.io/commands/rpush/`) — append a lane to the tail of the ring when it becomes
  serviceable.
- Valkey — *LREM* (`https://valkey.io/commands/lrem/`) — drop a lane from the ring when it empties or hits its
  ceiling.
- Valkey — *ZPOPMIN* (`https://valkey.io/commands/zpopmin/`) — take the head (lowest score, the mint-ordered place)
  of a lane.
- Valkey — *Cluster specification* (`https://valkey.io/topics/cluster-spec/`) — the `{q}` hash tag pins every key
  of a queue to one of 16384 slots, so a multi-key rotation is slot-legal.

### Related in this course

- R6 · Flow Control & Scale (`/redis-patterns/flow-control`) — the chapter.
- R6.02.1 · Starvation under load (`/redis-patterns/flow-control/fairness/starvation-under-load`).
- R6.02.2 · The weighted share (`/redis-patterns/flow-control/fairness/the-weighted-share`).
- R6.02.3 · Lanes vs separate queues (`/redis-patterns/flow-control/fairness/lanes-vs-separate-queues`).
- `/echomq/queue` — the Queue pillar, where the rota and the ceiling are wired at the claim point.
- `/bcs/bus` — Part B3, the Valkey-native bus and its fair-lanes architecture.
