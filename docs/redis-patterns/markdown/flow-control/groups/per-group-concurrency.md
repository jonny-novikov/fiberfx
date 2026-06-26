# Per-group concurrency

> Route: `/redis-patterns/flow-control/groups/per-group-concurrency` · R6.03.2 dive · Redis Patterns Applied
> Identity: BCS contract-sheet, redis-red. Grounded in `echo/apps/echo_mq` — lanes.ex.

**A per-group concurrency ceiling caps how much of the machine one tenant holds at once: a lane at its ceiling is
de-ringed so the rota skips it, and re-ringed the moment a completion frees a permit.** Round-robin keeps the rate
of turns fair; the ceiling bounds the simultaneous in-flight work per tenant — a distributed semaphore, one per
lane.

## Two numbers per tenant

Per-group concurrency rides two per-queue hashes, both keyed by the group id:

- `emq:{q}:glimit` — the ceiling: how many of this tenant's jobs may be in flight at once.
- `emq:{q}:gactive` — the live count: how many of this tenant's jobs are in flight right now.

The ceiling is configuration; the count is state. A claim that serves a tenant's job increments `gactive`; a
completion, retry, or reap of that tenant's job decrements it. The ceiling is set with `limit/4`:

```elixir
EchoMQ.Lanes.limit(conn, "orders", group, 5)   # this tenant: at most 5 in flight at once
```

This is a counting semaphore expressed as data. The cap is a hash field, not a key per tenant, so a queue with ten
thousand tenants holds two hashes, not twenty thousand keys — and the whole tenant set shares the one `{q}` slot.

## The de-ring is how the ceiling is enforced

The ceiling is not checked at the claim and then ignored. It changes the membership of the ring: a lane at or above
its ceiling is **removed from rotation**, so the rota never even offers it a turn. This is the `@glimit` script,
verbatim — it writes the new cap and then reconciles the ring:

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

`HSET glimit group n` writes the ceiling. Then it reads the live count: if the tenant already has `n` or more in
flight, `LREM ring 0 group` removes the lane from the rota immediately — lowering a ceiling below the live count
parks the tenant until it drains. Otherwise, if the lane is unpaused, has pending work, and is not already on the
ring, `RPUSH ring group` returns it to rotation with a wake — raising a ceiling can re-admit a tenant that the
previous cap had de-ringed.

The same de-ring runs at the claim point. After serving a job, the claim increments `gactive`; if that increment
reaches the ceiling, the lane is de-ringed on the spot:

```lua
local act = redis.call('HINCRBY', ARGV[1] .. 'gactive', g, 1)
local lim = redis.call('HGET', ARGV[1] .. 'glimit', g)
if lim and act >= tonumber(lim) then
  redis.call('LREM', KEYS[1], 0, g)
end
```

So a tenant at its ceiling is not on the ring at all, and the rota passes over it — no skip logic, no per-turn
check. When a completion drops `gactive` below the ceiling, the transition re-rings the lane. The semaphore is the
ring membership: in the rota means a permit is free, off the rota means the permits are spent.

## Parking a tenant without touching the rest

Two more controls act on a single lane and leave the rest of the queue alone. `pause/3` removes a lane from the ring
and records the group in `emq:{q}:paused`:

```lua
redis.call('SADD', KEYS[1], ARGV[1])     -- mark the group paused
redis.call('LREM', KEYS[2], 0, ARGV[1])  -- drop the lane from the ring
return 1
```

The paused flag is why a re-ring guard always checks `SISMEMBER paused` first — a paused lane stays off the rota
even when a completion frees a permit. `resume/3` clears the flag and returns the lane to rotation if it is
serviceable (unpaused, below its ceiling, nonempty), with a wake. The tenant's backlog and its in-flight work are
untouched throughout — pause stops new turns, it does not cancel or drain anything.

This is the operations move a single shared queue otherwise cannot make: hold one tenant while the others keep
running. A misbehaving tenant is paused, investigated, and resumed, with no effect on any other tenant's flow.

> **The pattern** — a counting semaphore admits up to N concurrent holders and blocks the rest until a holder
> releases. **↔** Its EchoMQ application — `emq:{q}:gactive` counts a tenant's in-flight jobs against the
> `emq:{q}:glimit` ceiling; `EchoMQ.Lanes.limit/4` sets the cap and de-rings a lane at its ceiling, re-ringing it
> when a completion frees a permit — the semaphore is the lane's ring membership.

In codemojex, a per-room ceiling caps how much of the scoring engine any one room holds at once: a room with a large
backlog is served its turn in the rota, but never more than its ceiling of guesses in flight together, so one room's
burst cannot consume the workers a hundred other rooms need.

## Notes on Valkey

The ceiling and the live count live in two hashes, and the in-flight count moves with `HINCRBY` — atomic
increment-and-return on a hash field, so two concurrent claims of the same tenant cannot both read the count as
below the cap and both serve. `LREM ring 0 group` removes every occurrence of the group from the ring list in one
operation, and `LPOS ring group` is the membership test that keeps a re-ring from adding a duplicate —
https://valkey.io/commands/hincrby/.
