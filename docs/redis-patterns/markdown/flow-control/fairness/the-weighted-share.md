# R6.02.2 · The weighted share

> Route: `/redis-patterns/flow-control/fairness/the-weighted-share` — a dive of R6.02.
> Grounding: `echo/apps/echo_mq` · `EchoMQ.Lanes.wclaim/3` and the inline `@gwclaim` Lua (the weighted multi-pop) ·
> `EchoMQ.Lanes.weight/4` and the `@gweight` script · the keys `emq:{q}:gweight` / `emq:{q}:gactive` /
> `emq:{q}:glimit` / `emq:{q}:g:<group>:pending`.

Equal rotation is the floor. Sometimes one lane should be served more than its peers — a paid tenant, a
latency-sensitive class — without ever being served all of the machine. That is a weight: a per-lane throughput
share, set with `weight/4`, that makes `wclaim/3` serve a lane K = min(weight, depth, glimit headroom) heads in one
turn. There is no numeric per-job priority; "served more" is a property of the identity, not the work.

## §1 A weight, not a priority

An earlier model reached for a numeric per-job priority — a score stamped on each job so the line sorts the urgent
work to the front. EchoMQ retired that by design. The replacement is a weight on the *lane*, not the job. The
distinction is the whole point: a priority says "this job matters more"; a weight says "this producer's stream gets
a larger share of the machine". Urgency travels with the identity, never with a single piece of work.

A weight is an integer, one or more. `EchoMQ.Lanes.weight/4` sets it, writing the value into the `emq:{q}:gweight`
hash (group → weight) — the same shape as the concurrency keys, no new key family. A weight of one is plain
rotation: the lane is served a single head per turn, identical to `claim/3`. A higher weight serves the lane more
heads per turn, proportionally more over a window — and never the whole ring, because every other lane still takes
its turn.

A weight is never zero. A weight is a throughput share, and `weight/4` requires `w >= 1`; parking a lane is a
different operation — the operator's `pause/3`, which removes the lane from the ring entirely. Setting a weight
never changes whether a lane is serviceable (serviceable means nonempty, unpaused, and below its limit, all
weight-independent), so `weight/4` touches no ring bookkeeping at all — it is a single `HSET`.

## §2 The multi-pop — K = min(weight, depth, headroom)

`EchoMQ.Lanes.wclaim/3` is the weighted rotation. It rotates the ring one step exactly as `claim/3` does — one
`LMOVE`, the same rota step — then, instead of serving one head, it serves the rotated lane **K heads in one atomic
turn**, where:

    K = min(weight, the lane's pending depth, the glimit headroom)

Each clamp guards a different invariant:

- **the weight** is the requested share, read from `emq:{q}:gweight` (absent or below one, it clamps to one);
- **the lane's pending depth** means a turn never serves more than the lane holds — a weight of five against a lane
  of two serves two;
- **the glimit headroom** — the room left under the lane's concurrency ceiling (`glimit` minus `gactive`) — means
  the multi-pop can never push `gactive` past `glimit`. A weight is a throughput share; the limit is a concurrency
  ceiling; the share bends to the ceiling. With no headroom the lane is at its ceiling, so it is de-ringed and
  nothing is served this turn.

The K served jobs share one lease deadline, computed once from the server clock for the whole turn, and `gactive`
is incremented by the actual count served, after which the same re-ring guard as `claim/3` runs once (the ceiling
test and the empty-lane test). The result is a fair share that respects the ceiling: a higher-weight lane drains
faster, but never past the concurrency it is allowed, and never to the exclusion of the other lanes.

## §3 Two dials, no per-job number

Fairness now has two dials, and they are orthogonal. The **rotation** gives every serviceable lane an equal turn —
this is `claim/3`, the floor. The **weight** tilts how many heads a lane gets *per* turn — this is `wclaim/3`, the
share. Neither dial is a number on a job.

`EchoMQ.Lanes.weight/4` carries the design intent in its own documentation: weight is per-lane, never per-job —
there is no numeric per-job priority (retired by design); "served more" is a property of the identity, not the
work. The companion `reassign/4` carries the other half of the retarget: "matters more now" is a change of lane,
mint order is the order theorem — a job that should be served sooner is moved to a different lane, not given a
higher number.

So the two questions a scheduler usually answers with a priority number are answered structurally here. *Whose
turn?* — the rotation. *How big a share?* — the weight. *This one job sooner?* — move its lane. The number never
appears.

**The bridge.** "Serve this producer more, but never all of the machine" **↔** a weight in the `emq:{q}:gweight`
hash, set by `EchoMQ.Lanes.weight/4`, and `EchoMQ.Lanes.wclaim/3` serving the rotated lane K = min(weight, depth,
glimit headroom) heads per turn. A weight is a throughput share, not a pause, and not a per-job priority.

A consumer keeps it concrete. In codemojex the lanes are players (the lane is named by the player's `PLR` id), and
the rota serves players in turn through `Codemojex.ScoreWorker`. A weight on a player's lane would let that lane
drain more heads per turn — a larger share of the scoring machine — without ever halting the others; the weight is
the dial for "more", the ring still guarantees "everyone".

## References

### Sources

- Valkey — *HSET* (`https://valkey.io/commands/hset/`) — set a lane's weight in the `gweight` hash; the `@gweight`
  script is a single `HSET`.
- Valkey — *HGET* (`https://valkey.io/commands/hget/`) — read the weight, the limit, and the active count the
  multi-pop clamps against.
- Valkey — *LMOVE* (`https://valkey.io/commands/lmove/`) — the one rota step `wclaim/3` shares with `claim/3`.
- Valkey — *ZPOPMIN* (`https://valkey.io/commands/zpopmin/`) — the K heads of the rotated lane, popped in mint
  order.

### Related in this course

- R6.02 · Fairness under load (`/redis-patterns/flow-control/fairness`) — the module hub.
- R6.02.1 · Starvation under load (`/redis-patterns/flow-control/fairness/starvation-under-load`).
- R6.02.3 · Lanes vs separate queues (`/redis-patterns/flow-control/fairness/lanes-vs-separate-queues`).
- `/echomq/queue` — the weighted share wired at the claim point.
- `/bcs/bus` — Part B3, the fair-lanes architecture.
