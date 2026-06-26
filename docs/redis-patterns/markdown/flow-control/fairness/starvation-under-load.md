# R6.02.1 · Starvation under load

> Route: `/redis-patterns/flow-control/fairness/starvation-under-load` — a dive of R6.02.
> Grounding: `echo/apps/echo_mq` · `EchoMQ.Lanes.claim/3` and the inline `@gclaim` Lua (the `LMOVE` rotate-then-serve)
> · the keys `emq:{q}:ring` / `emq:{q}:g:<group>:pending`.

A single first-in, first-out line is fair to jobs and unfair to producers. When one producer floods the queue, the
rest wait behind the whole flood — the order is correct and the outcome is starvation. EchoMQ avoids it by drainage
across a set of lanes, rotated one step per claim, so every lane is served in turn regardless of how deep its
backlog runs.

## §1 Why one line starves

Take a queue drained strictly first-come-first-served and two producers. Producer A submits a thousand jobs in a
burst; producer B submits ten a moment later. In one line, B's ten sit behind A's thousand. B is not served until
A is drained — its work is correct in its place and arbitrarily late. The line honoured arrival order perfectly,
and it starved the small producer.

The cause is that a single line couples two things that should be separate: the *order within a producer* and the
*share between producers*. First-in, first-out is the right rule for the first — a producer's own jobs should run
in the order it sent them. It is the wrong rule for the second — a producer's share of the machine should not be
proportional to how much it dumped on the queue. Couple them and the heaviest producer wins the machine.

Adding workers does not fix it. Ten workers drain A's thousand ten times faster, and B still waits for all thousand
to clear the head of the line before its first job is even visible. The starvation is in the *ordering*, not the
throughput — more workers drain the same unfair order faster.

## §2 The lane is the unit

The fix is to split the line by producer. A queue is a set of **lanes**, each a per-group pending set named by a
branded id (`emq:{q}:g:<group>:pending`). A's thousand jobs land in A's lane; B's ten land in B's. Within a lane,
order is still first-in, first-out — a lane is a sorted set keyed by mint order, and the head is the oldest job. Across
lanes, the line is no longer shared, so the question is no longer "who is first" but "whose turn is it".

A lane is created by admission. `EchoMQ.Lanes.enqueue/5` writes the job row with its group, adds the job to the
group's lane, and — if the lane is serviceable and not already present — appends the group to the ring. Work that
should ride a lane but is enqueued with no group is never claimed: the lane is the unit of fairness *and* of
control, and ungrouped work has no lane to be served from.

## §3 The rota guarantee

The ring is the rota. `emq:{q}:ring` is a list holding exactly the serviceable lanes — nonempty, unpaused, below
their concurrency ceiling. A claim rotates the ring one step, then serves the head of the lane it landed on. The
rotation is one atomic Valkey move:

    LMOVE emq:{q}:ring emq:{q}:ring LEFT RIGHT

The head moves to the tail and the claim serves it. The next claim rotates again and serves the next lane. Over one
full turn of the ring, every serviceable lane is served exactly once — A's lane and B's lane each get one head per
turn, whether A holds a thousand jobs or ten. A deep backlog fills its lane deeper; it never wins a larger share of
the rota.

`EchoMQ.Lanes.claim/3` is that operation, and its inline `@gclaim` Lua is the rotate-then-serve in full: rotate the
ring (`LMOVE`), take the head of the rotated lane (`ZPOPMIN`, so the oldest job in the lane), count the attempt as
the fencing token (`HINCRBY`), and lease the job on the server clock (`TIME`). If the rotated lane is empty it is
dropped from the ring (`LREM`) and the claim returns empty so the consumer rotates on. The guarantee is structural:
fairness is *constructed* by the rotation, not bought with a priority number, not approximated by a hash.

**The bridge.** A single FIFO line that lets one flood starve the rest **↔** the `emq:{q}:ring` rotated one step
per claim by `LMOVE`, with `EchoMQ.Lanes.claim/3` serving the head of the rotated lane — every lane served in turn,
the order within each lane preserved, no lane able to buy a bigger share by being deeper.

A consumer makes the guarantee concrete. In codemojex, `Codemojex.Guesses.submit/3` enqueues each guess on the
player's lane (named by the player's `PLR` id), and `Codemojex.ScoreWorker` drains through `Lanes.claim` with the
player id arriving as the lane group — so a player who mashes the keyboard fills only their own lane, and the rota
keeps serving every other player in turn.

## References

### Sources

- Valkey — *LMOVE* (`https://valkey.io/commands/lmove/`) — the atomic pop-and-push that rotates the ring one step.
- Valkey — *ZPOPMIN* (`https://valkey.io/commands/zpopmin/`) — pop the lowest-scored member, the oldest job in a
  lane.
- Valkey — *LREM* (`https://valkey.io/commands/lrem/`) — remove a lane from the ring when it empties.
- Valkey — *Lists* (`https://valkey.io/topics/data-types/`) — the ring is a list; the rota is list rotation.

### Related in this course

- R6.02 · Fairness under load (`/redis-patterns/flow-control/fairness`) — the module hub.
- R6.02.2 · The weighted share (`/redis-patterns/flow-control/fairness/the-weighted-share`).
- R6.02.3 · Lanes vs separate queues (`/redis-patterns/flow-control/fairness/lanes-vs-separate-queues`).
- `/echomq/queue` — the rota wired at the claim point.
- `/bcs/bus` — Part B3, the fair-lanes architecture.
