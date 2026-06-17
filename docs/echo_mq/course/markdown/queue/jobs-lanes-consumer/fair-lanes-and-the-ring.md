# Fair lanes & the ring — claiming in turn, not at random

**Route:** `/echomq/queue/jobs-lanes-consumer/fair-lanes-and-the-ring` · **Pillar:** The Queue · **Surface:** dive

> All real code in `echo/apps/echo_mq/lib/echo_mq/lanes.ex` + `keyspace.ex`. No `[RECONCILE]` markers.

## The fact

Fairness between identities is **constructed, not hashed**. Each identity gets its own pending set — a lane,
`emq:{q}:g:<group>:pending`. A Valkey LIST, the **ring**, holds exactly the lanes serviceable right now. Every claim
**rotates the ring one step** before serving its head, so the lanes take turns. No identity starves another.

## The shape

- a **lane** — `emq:{q}:g:<group>:pending`, a per-group pending set named by a branded id.
- the **ring** — `emq:{q}:ring`, a LIST holding the groups that can be served now (nonempty, unpaused, below limit).
- the concurrency books — `emq:{q}:gactive` (a hash, in-flight count per group), `emq:{q}:glimit` (a hash, the
  ceiling per group), `emq:{q}:paused` (a set of parked groups), `emq:{q}:wake` (the wake list a parked consumer
  blocks on).

## Hero interactive — rotate the ring

A ring of three lanes (A, B, C) and a claim button. Each claim does `LMOVE LEFT RIGHT` (rotate one step) then serves
the new head. Watch the rota cycle A→B→C→A — round-robin, constructed. Pure functions; live `.geo-readout`.

## Beat one — the `@gclaim` handle (real, `lanes.ex`)

```elixir
def claim(conn, queue, lease_ms) when is_integer(lease_ms) and lease_ms > 0 do
  if EchoMQ.Jobs.paused?(conn, queue) do
    :empty
  else
    keys = [Keyspace.queue_key(queue, "ring"), Keyspace.queue_key(queue, "active")]
    argv = [Keyspace.queue_key(queue, ""), Integer.to_string(lease_ms)]

    case Connector.eval(conn, @gclaim, keys, argv) do
      {:ok, []} -> :empty
      {:ok, [id, payload, att, group]} -> {:ok, {id, payload, att, group}}
      other -> other
    end
  end
end
```

KEYS = `[ring, active]`. The grouped claim returns the **group** beside the job: `{id, payload, att, group}`. A
queue-wide pause stops the grouped claim too (distinct from `pause/3`, which parks one lane).

## Beat two — the `@gclaim` Lua body (real, decoded, `lanes.ex`)

```lua
local g = redis.call('LMOVE', KEYS[1], KEYS[1], 'LEFT', 'RIGHT')
if not g then return {} end
local lane = ARGV[1] .. 'g:' .. g .. ':pending'
local popped = redis.call('ZPOPMIN', lane)
if #popped == 0 then
  redis.call('LREM', KEYS[1], 0, g)
  return {}
end
local id = popped[1]
local jk = ARGV[1] .. 'job:' .. id
local att = redis.call('HINCRBY', jk, 'attempts', 1)
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
local act = redis.call('HINCRBY', ARGV[1] .. 'gactive', g, 1)
local lim = redis.call('HGET', ARGV[1] .. 'glimit', g)
if lim and act >= tonumber(lim) then
  redis.call('LREM', KEYS[1], 0, g)
elseif redis.call('ZCARD', lane) == 0 then
  redis.call('LREM', KEYS[1], 0, g)
end
return {id, redis.call('HGET', jk, 'payload'), att, g}
```

- **rotate one step** — `LMOVE KEYS[1] KEYS[1] LEFT RIGHT` pops the head group of the ring and pushes it to the tail
  in one atomic move. The next claim starts at the next group: round-robin, constructed.
- **serve that lane's head** — `ZPOPMIN` the lane; an empty lane is removed from the ring (`LREM`) and the claim
  answers empty.
- the **lease + token** — same as the flat claim: `HINCRBY attempts`, `state active`, `ZADD active` at `now + lease`.
- the **concurrency books** — `HINCRBY gactive g 1`; if the group is at its `glimit`, the group leaves the ring until
  a completion frees a slot; an emptied lane also leaves the ring.

## Main interactive — concurrency limit parks a lane

Three lanes, a limit of 1 on lane B. Claim repeatedly: when B's in-flight hits its limit it drops off the ring and is
skipped until a completion frees a slot. Pure; live `.geo-readout`.

## The control verbs (real, `lanes.ex`)

- `enqueue/5` — grouped admission: kind policy, duplicate refusal, the row with its `group` field, the lane entry,
  the ring bookkeeping + a wake.
- `pause/3` / `resume/3` — remove / return a lane from / to rotation (backlog + in-flight untouched).
- `limit/4` — set the lane's concurrency ceiling (lowering below the live count parks it; raising may return it).
- `depth/3` — lane depth, `ZCARD` the lane.

## Bridge

- the pattern (Redis Patterns Applied): a reliable queue serves work to consumers; fairness across producers is a
  policy layered on top — R3 `/redis-patterns/queues` (built).
- the implementation (echo_mq): `EchoMQ.Lanes` builds fairness from a rotating ring of per-identity lanes — `@gclaim`
  rotates the ring one step, then serves that lane's head.

## Take

Fairness is constructed, not hashed: a ring of lanes, rotated one step per claim, so every identity takes its turn.

## References

### Sources
- Valkey — `LMOVE` — https://valkey.io/commands/lmove/
- Valkey — `ZPOPMIN` — https://valkey.io/commands/zpopmin/
- Valkey — `HINCRBY` — https://valkey.io/commands/hincrby/
- Redis — `EVALSHA` — https://redis.io/commands/evalsha/

### Related in this course
- `/echomq/queue/jobs-lanes-consumer` — the module hub
- `/echomq/queue/jobs-lanes-consumer/the-consumer-loop` — the loop that drains the ring
- `/redis-patterns/queues` — R3, the reliable-queue pattern
