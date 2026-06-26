# Group vs separate queue

> Route: `/redis-patterns/flow-control/groups/group-vs-separate-queue` · R6.03.3 dive · Redis Patterns Applied
> Identity: BCS contract-sheet, redis-red. Grounded in `echo/apps/echo_mq` — lanes.ex.

**One queue with groups gives per-tenant config, limits, and operations inside one keyspace slot; N separate queues
give hard isolation but no cross-tenant fairness and N× the operational surface.** The multi-tenant question is not
*can I separate the tenants* — both designs do — it is *who runs the scheduler, and what does each tenant cost to
operate*.

## The two designs

There are two honest ways to carry many tenants on a queue.

**N separate queues.** Each tenant gets its own queue — its own keyspace, its own consumers, its own retention.
Isolation is total: a tenant cannot see, starve, or even name another tenant's work. The cost is that nothing
balances them. Fairness across tenants now lives *outside* the queue, in whatever process selects which queue a
worker polls next; with N queues and a fixed worker pool, that scheduler is yours to write, and getting it fair is
the same rota problem moved up a layer. Every tenant also multiplies the operational surface: N sets of metrics, N
pause switches, N retention policies, N things to provision when a tenant is added.

**One queue with groups.** Every tenant is a lane in one queue — one keyspace, one ring, one set of consumers. The
rota that serves the lanes *is* the cross-tenant scheduler, built into the claim, so fairness is free and there is
nothing to write. Per-tenant control is data: a ceiling is a `glimit` hash field, a pause is a `paused` set member,
a tenant is created by its first job. The cost is the converse of isolation: tenants share storage, failure domain,
and retention, so a design that needs those split per tenant cannot use groups.

## What one queue with groups can do per tenant

The group design is not "one queue, no per-tenant levers" — `EchoMQ.Lanes` gives a full per-tenant operations set
inside the one `{q}` slot:

- **A per-tenant concurrency ceiling.** `EchoMQ.Lanes.limit(conn, q, group, n)` caps one tenant's in-flight work
  without affecting the rest — the `glimit`/`gactive` semaphore.
- **Park and unpark one tenant.** `EchoMQ.Lanes.pause(conn, q, group)` and `resume/3` hold a single tenant while
  the others keep running.
- **Move work between tenants.** `EchoMQ.Lanes.reassign(conn, q, job_id, dst_group)` moves a pending job from its
  lane to another in one atomic script; the source group is read from the job row, so the move cannot disagree with
  what the row records, and the mint-ordered place is kept. There is no numeric per-job priority to set — "matters
  more now" is a change of lane, not a score.
- **Recover one tenant on demand.** `EchoMQ.Lanes.reap_group(conn, q, group)` returns one tenant's expired-lease
  jobs to its own lane without a queue-wide scan — a crashed tenant re-queues behind its own identity and never
  jumps the rota.
- **Drain one tenant.** `EchoMQ.Lanes.drain(conn, q, group)` empties one lane's pending backlog and drops it from
  the ring, leaving every sibling lane, the ceiling config, and the in-flight work alone.
- **Read one tenant's depth.** `EchoMQ.Lanes.depth(conn, q, group)` is the lane's pending count.

Each of these is one operation against one tenant. The same operations across N separate queues are N queues to
enumerate, N connections to address, and a separate scheduler to keep them fair — the per-tenant levers exist, but
the cross-tenant balance and the per-tenant cost do not come for free.

## The deciding trade

The reassign script shows why the group design holds together as one slot. The move is atomic by construction
because both lanes share the one `{q}` hash tag — a cross-queue move is not even expressible:

```lua
local g = redis.call('HGET', KEYS[1], 'group')   -- the row is authoritative
if not g then return -1 end
if g == ARGV[2] then return 0 end
local src_lane = ARGV[3] .. 'g:' .. g .. ':pending'
if redis.call('ZREM', src_lane, ARGV[1]) == 0 then return -2 end
redis.call('ZADD', KEYS[2], 0, ARGV[1])          -- enter dst at mint order
redis.call('HSET', KEYS[1], 'group', ARGV[2])    -- the row now records dst
```

Moving a job between two separate queues is a two-queue transaction — remove from one, add to the other, atomically,
across keys that may live on different slots. Between two lanes of one queue it is a single script on one slot, and
the group is outside the braces so the move stays inside the `{q}` tag. That is the structural payoff: one queue
with groups buys per-tenant operations *and* atomic cross-tenant moves, because everything shares one slot.

So the rule is about what must be split. If tenants need separate storage, separate failure domains, or separate
retention, separate queues are correct and the scheduler is the price. If tenants share all of that and what is
needed is fairness plus per-tenant levers, one queue with groups is correct — the rota is the scheduler, the levers
are data, and a tenant costs one hash field, not one queue.

> **The pattern** — multi-tenant work is partitioned either by isolation (a resource per tenant) or by fairness (a
> shared resource scheduled per tenant). **↔** Its EchoMQ application — one queue with `EchoMQ.Lanes` groups gives
> per-tenant `limit/4`, `pause/3`, `reassign/4`, `reap_group/4`, and `drain/3` inside one `{q}` slot with the rota
> as the scheduler; N separate queues give isolation but move fairness and N× the operations outside the queue.

In codemojex, rooms share one queue as lanes rather than each holding its own: a room is created by its first
guess, served its fair turn by the rota, capped by a per-room ceiling, and recoverable on its own — without one
queue, one metric, and one pause switch per room of the game.

## Notes on Valkey

A multi-key script is legal only when its keys live on one slot, which a key's `{q}` hash tag guarantees: every
lane, the ring, and the `glimit`/`gactive` hashes of a queue carry the same `{q}` brace, so they all hash to one of
16384 slots and a script touching several of them never raises CROSSSLOT. That co-location is exactly what makes the
single-script reassign and the de-ring ceiling possible — across separate queues, the keys are on separate slots and
no single script can span them — https://valkey.io/topics/cluster-spec/.
