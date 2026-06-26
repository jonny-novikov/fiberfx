# Round-robin across tenants

> Route: `/redis-patterns/flow-control/groups/round-robin-across-tenants` · R6.03.1 dive · Redis Patterns Applied
> Identity: BCS contract-sheet, redis-red. Grounded in `echo/apps/echo_mq` — lanes.ex.

**A tenant is a lane: work enqueued under a branded group id rides that lane, and the ring serves every lane in
turn.** Round-robin across tenants is the rota that keeps a shared queue fair — a busy tenant cannot jump ahead, a
quiet one is never skipped, and the order is a property of rotation, not of a hash or a score.

## Admission by group

A grouped queue admits work by tenant. The group id names the lane; the job goes onto that lane's pending set:

```elixir
EchoMQ.Lanes.enqueue(conn, "orders", group, job_id, payload)
# group is a branded id; the job lands on emq:{orders}:g:<group>:pending
```

`enqueue/5` is one idempotent script. It checks the kind of the job id, refuses a duplicate, writes the job row
carrying its `group` field, adds the job to the lane's pending sorted set at score zero (mint order is the order),
and — only if the group is not already on the ring and is below its ceiling — pushes the lane onto the ring with a
wake for any parked consumer. The group is gated as a valid branded id at the key builder, so the lane is always
named by a real identity; an ill-formed group raises before any command reaches the wire.

The lane is created by the first job that names the group. There is no provisioning step, no registry to update, no
queue to declare per tenant — a new tenant exists the moment its first job is admitted, and disappears when its lane
empties. The set of tenants is open by construction.

## The ring is the rota

The ring `emq:{q}:ring` is a Valkey list, and it holds exactly the **serviceable** lanes: nonempty, unpaused, and
below their concurrency ceiling. It is not the set of all tenants — it is the set of tenants that can be served right
now. A lane joins the ring when it becomes serviceable and leaves the moment it does not.

Every claim rotates the ring one step before it serves. The rotation is a single atomic `LMOVE`:

```lua
local g = redis.call('LMOVE', KEYS[1], KEYS[1], 'LEFT', 'RIGHT')
if not g then return {} end
local lane = ARGV[1] .. 'g:' .. g .. ':pending'
local popped = redis.call('ZPOPMIN', lane)
```

`LMOVE ring ring LEFT RIGHT` pops the head of the ring and pushes it to the tail, returning the group it moved. That
group is the tenant served this turn: the script derives the lane key from the group, pops the lowest-scored member
(the oldest, mint order kept), leases it on the server clock, and returns it. The next claim moves the next head to
the tail, and so on around the ring.

So the rota is the list order, advanced one step per claim. Three tenants on the ring are served A, B, C, A, B, C —
each gets one turn per cycle, regardless of how deep its backlog is. **Fairness between tenants is constructed by
rotation, never hashed**: there is no priority field to game, no consistent-hash bucket to fall into, only the ring
advancing one position at a time.

## A lane that empties or fills leaves the ring

The rota only holds serviceable lanes, so the script keeps the ring honest as it serves. After it pops a member, it
checks two conditions:

```lua
local act = redis.call('HINCRBY', ARGV[1] .. 'gactive', g, 1)
local lim = redis.call('HGET', ARGV[1] .. 'glimit', g)
if lim and act >= tonumber(lim) then
  redis.call('LREM', KEYS[1], 0, g)        -- at its ceiling: de-ring
elseif redis.call('ZCARD', lane) == 0 then
  redis.call('LREM', KEYS[1], 0, g)        -- lane now empty: de-ring
end
```

If serving that job pushed the tenant to its concurrency ceiling, the lane is removed from the ring so the rota
skips it until a completion frees a permit. If the lane is now empty, it is removed because there is nothing left to
serve. Either way, the next rotation lands on a lane that genuinely has serviceable work — the ring never wastes a
turn on a tenant that cannot be served.

A lane returns to the ring the moment it becomes serviceable again: a fresh `enqueue/5` onto an empty lane re-rings
it, a completion that drops `gactive` below the ceiling re-rings it, a `resume/3` re-rings a paused lane. The rota
is self-maintaining.

> **The pattern** — round-robin scheduling serves a set of queues in strict rotation, one item per queue per turn,
> so no queue starves another. **↔** Its EchoMQ application — the ring `emq:{q}:ring` holds the serviceable lanes;
> `EchoMQ.Lanes.claim/3` does `LMOVE ring ring LEFT RIGHT` then serves the head of the rotated lane, so every tenant
> is served in turn and the order is rotation, not a score.

In codemojex, a room is a tenant. Guesses from a room are enqueued under that room's branded id, so they ride one
lane (`emq:{cm}:g:<PLR…>:pending`); the ring rotates through the active rooms, and a room flooding the engine with
guesses takes only its turn in the rota — the quiet rooms are served on the very next steps. Work enqueued without a
room id rides no lane and is never claimed by the grouped path: the lane is the unit of control.

## Notes on Valkey

`LMOVE source destination LEFT RIGHT` is atomic: in one operation it removes the first element of the source list
and pushes it to the end of the destination. With the same key for both, it rotates the list one position and
returns the moved element — exactly the rota step the claim needs, with no read-modify-write window where two
consumers could rotate the same head — https://valkey.io/commands/lmove/.
