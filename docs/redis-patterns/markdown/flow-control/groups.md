# Groups & multi-tenant fairness

> Route: `/redis-patterns/flow-control/groups` · R6.03 module hub · Redis Patterns Applied
> Identity: BCS contract-sheet, redis-red. Grounded in the real as-built echo data layer (`echo/apps/echo_mq`).
> Technique (not a fresh catalog pattern): composes distributed-locking (the per-group semaphore) and
> rate-limiting (the per-group cap).

**A group is a tenant given its own lane: work enqueued under a branded group id rides that lane, the ring serves
every lane in turn, and a per-group concurrency ceiling caps how much of the machine any one tenant holds at once.**
Where rate-limiting bounds a rate and the rota keeps lanes fair, groups answer the multi-tenant operations question:
how does one queue carry many tenants without one starving the rest or monopolising the workers — and without
running a separate queue per tenant.

This is a flow-control *technique*, applied to the BCS bus. It reuses the same lane machinery the fairness module
builds — `EchoMQ.Lanes` over the `emq:{q}:` keyspace — and adds the multi-tenant operations layer on top: a
per-group concurrency ceiling, a way to park one tenant, a way to move work between tenants, and a way to recover or
drain one tenant on its own. The lane is the unit of fairness *and* of control.

## A group is a lane

A queue is not one line; it is a set of lanes, each named by a branded group id. Admitting work under a group puts
it on that group's lane and registers the lane for service:

```
EchoMQ.Lanes.enqueue(conn, "orders", group, job_id, payload)
# → writes emq:{orders}:g:<group>:pending, registers the lane on the ring
```

`enqueue/5` is one idempotent script. It refuses a duplicate, writes the job row with its `group` field, adds the
job to the lane's pending set `emq:{q}:g:<group>:pending`, and — if the group is not already serviced and is below
its ceiling — pushes the lane onto the ring with a wake for any parked consumer. The group is gated as a valid
branded id at the key builder before any command reaches the wire, so a lane is always named by a real identity.

Work that should ride a lane and is enqueued ungrouped is never claimed by the grouped path. The lane is the unit:
no group, no lane, no service. This is the property that makes the tenant boundary real — a tenant's work is exactly
the work on its lane, and nothing else can be confused for it.

## Round-robin across tenants

Every claim rotates the ring one step before it serves:

```
EchoMQ.Lanes.claim(conn, "orders", 30_000)
# → LMOVE ring ring LEFT RIGHT, then serve the head of the rotated lane
```

The ring `emq:{q}:ring` is a list holding exactly the **serviceable** lanes — nonempty, unpaused, and below their
concurrency ceiling. `claim/3` does `LMOVE ring ring LEFT RIGHT`, which moves the head to the tail and returns it,
then serves the head of that lane on a server-clock lease. Because the ring advances one step per claim, every
serviceable tenant is served in turn: fairness across tenants is **constructed by rotation, never hashed**. A busy
tenant cannot jump the rota, and a quiet tenant is never skipped.

A lane that empties or reaches its ceiling is removed from the ring; it returns the moment it becomes serviceable
again. So the rota always holds exactly the lanes that can be served right now, and rotation alone keeps the share
even.

## The per-group ceiling

Round-robin keeps the *rate of turns* fair, but it does not by itself bound how much of the machine one tenant holds
at once. That is the per-group concurrency ceiling:

```
EchoMQ.Lanes.limit(conn, "orders", group, 5)   # this tenant: at most 5 in flight at once
```

`limit/4` writes the cap into the `emq:{q}:glimit` hash and reconciles the ring immediately. The companion counter
`emq:{q}:gactive` tracks how many of a group's jobs are currently in flight; a claim increments it, a completion
decrements it. When a lane reaches its ceiling it is **de-ringed** — removed from rotation so the rota skips it
entirely — and re-ringed the moment a completion drops `gactive` below the limit. Lowering a ceiling below the live
count parks the lane until it drains; raising it may return the lane to rotation at once.

Two more controls act on a single lane without touching the rest of the queue. `pause/3` removes a lane from the
ring and adds the group to `emq:{q}:paused`, so the rota skips it while its backlog and in-flight work sit
untouched; `resume/3` returns it to rotation if it is serviceable, with a wake. One tenant can be held while the
others keep running — group-aware pause and resume, the operations move that a single shared queue otherwise cannot
make.

## Applied in EchoMQ

The whole technique is `EchoMQ.Lanes`, and it composes two patterns this course teaches separately. The per-group
ceiling is a distributed semaphore — a count of in-flight permits (`gactive`) checked against a cap (`glimit`),
exactly the shape of a counting lock. The ring is the fairness rota the queues chapter builds. Together they make a
queue multi-tenant: every tenant gets a turn, and no tenant takes more than its share of the machine at once.

The de-ring ceiling is the `@glimit` script, verbatim from `EchoMQ.Lanes`. It writes the cap, then either de-rings
the lane (already at or over the cap) or re-rings it if it is serviceable:

```lua
redis.call('HSET', KEYS[1], ARGV[2], ARGV[3])
local act = tonumber(redis.call('HGET', KEYS[2], ARGV[2]) or '0')
if act >= tonumber(ARGV[3]) then
  redis.call('LREM', KEYS[3], 0, ARGV[2])
else
  local lane = ARGV[1] .. 'g:' .. ARGV[2] .. ':pending'
  if redis.call('SISMEMBER', KEYS[4], ARGV[2]) == 0 and redis.call('ZCARD', lane) > 0 and
     not redis.call('LPOS', KEYS[3], ARGV[2]) then
    redis.call('RPUSH', KEYS[3], ARGV[2])
    redis.call('LPUSH', KEYS[5], '1')
    redis.call('LTRIM', KEYS[5], 0, 63)
  end
end
return 1
```

> **The pattern** — share capacity fairly across tenants: round-robin lanes with a per-group concurrency ceiling.
> **↔** Its EchoMQ application — a tenant is a lane `emq:{q}:g:<group>:pending`; `EchoMQ.Lanes.enqueue/5` admits by
> group, `claim/3` rotates the ring to serve every tenant in turn, and `limit/4` (over `glimit`/`gactive`) caps how
> much one tenant holds at once, de-ringing a lane at its ceiling.

The manuscript frames the operations move directly (B3, *Jobs and lanes*): *"Group-aware pause and resume act on a
lane without touching the queue, so one tenant can be held while the others run."* That sentence is the whole
multi-tenant promise — one queue, many tenants, each held or served on its own.

A consumer makes the tenant boundary concrete. In codemojex — a Telegram emoji-guessing game on the same stack — a
room is a tenant: work enqueued under a branded room id rides that room's lane (`emq:{cm}:g:<RMM…>:pending`), so a
busy room cannot starve a quiet one, and a per-room ceiling caps how much of the engine any one room holds at once.

## When to use / when to avoid

**Reach for groups when:**

- One queue carries work from many tenants and any one could otherwise starve the rest or monopolise the workers.
- Per-tenant operations are needed — pause one tenant, cap one tenant, move or recover one tenant's work — without a
  separate queue per tenant and the operational cost that brings.
- The set of tenants is open or large, so provisioning a queue each is impractical; a lane is created by the first
  job that names the group.
- Fairness across tenants matters as much as throughput — the rota guarantees every serviceable tenant a turn.

**Avoid groups when:**

- Tenants need hard isolation — separate storage, separate failure domains, separate retention — that a shared
  queue cannot give; then separate queues are the right tool, at N× the operational cost.
- There is effectively one tenant; the lane machinery adds bookkeeping with no fairness to buy.
- The constraint is a *rate* per window rather than concurrency or fairness — that is the rate limiter, a per-window
  counter, not a per-group ceiling.

The dives take the three moves apart in turn: round-robin as the tenant rota, the per-group ceiling and how a lane
de-rings, and the operations trade between one queue with groups and N separate queues.

## References

### Sources

- Valkey — *LMOVE* (https://valkey.io/commands/lmove/) — atomically move the ring head to the tail and return it;
  the one-step rotation behind the tenant rota.
- Valkey — *HSET* (https://valkey.io/commands/hset/) — write a group's ceiling into the `glimit` hash; the per-group
  cap is a hash field, not a key per tenant.
- Valkey — *HINCRBY* (https://valkey.io/commands/hincrby/) — increment and decrement the in-flight count `gactive`
  atomically as a tenant claims and completes.
- Valkey — *Cluster specification* (https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag pins every lane,
  the ring, and the ceiling hashes to one of 16384 slots, so a multi-key script is slot-legal.
- AWS — *Tenant isolation* (https://docs.aws.amazon.com/whitepapers/latest/saas-architecture-fundamentals/tenant-isolation.html)
  — the shared-vs-isolated trade groups make against a queue-per-tenant model.

### Related in this course

- R6 · Flow Control & Scale (`/redis-patterns/flow-control`) — the chapter.
- R6.02 · Fairness under load (`/redis-patterns/flow-control/fairness`) — the rota and weights this technique builds
  on.
- R6.03.1 · Round-robin across tenants (`/redis-patterns/flow-control/groups/round-robin-across-tenants`) — the lane
  as a tenant and the rotation that serves each in turn.
- R6.03.2 · Per-group concurrency (`/redis-patterns/flow-control/groups/per-group-concurrency`) — the ceiling, the
  de-ring, and group-aware pause.
- R6.03.3 · Group vs separate queue (`/redis-patterns/flow-control/groups/group-vs-separate-queue`) — one queue with
  groups against N separate queues.
- /echomq/queue — EchoMQ's Queue pillar, where groups and the ceiling are wired at the claim point.
- /bcs/bus — Part B3, the Valkey-native bus and the fair-lanes architecture; the specific dive /bcs/bus/jobs-and-lanes.
