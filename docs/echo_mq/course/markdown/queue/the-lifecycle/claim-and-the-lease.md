# Claim & the lease

> Route: `/echomq/queue/the-lifecycle/claim-and-the-lease` · surface: dive · pillar: The Queue.
> Grounded entirely in real code (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`). No reconcile shadow needed — all surfaces verified on disk.

## The fact

To claim a job is to run one atomic Lua script, `@claim`. It pops the oldest pending id, increments the row's `attempts`,
sets the row `state = active`, and adds the id to the **active set at a score of `now + lease`**. Two facts make the rest
of the lifecycle work and need no separate lock service:

- **The active-set score IS the lease deadline.** A claimed job's active-set member is scored at the server-clock instant
  its lease runs out. Recovery (`@reap`) is then a range query: any active member whose score is in the past has a lapsed
  lease.
- **`attempts` IS the fencing token.** Each claim increments `attempts`, and the new value is returned to the worker. To
  complete or extend the job later, the worker presents that number; a stale holder presents an older number and is
  refused. There is no separate lock string.

## Beat one — the handle

`claim/3` checks the queue-wide pause flag first (the separate-gate form that keeps `@claim` byte-unchanged), then builds
the two keys the script touches — the pending set and the active set — passes the row-key base and the lease window as
`ARGV`, and maps the script's reply to `:empty` or `{:ok, {id, payload, att}}`.

```elixir
# echo_mq — EchoMQ.Jobs
# claim/3 is the handle. It honors the queue-wide pause flag FIRST (a paused
# queue answers :empty and leaves the pending set untouched), then runs @claim.
# KEYS = [pending, active]; ARGV[1] is the job-key base ("emq:{q}:job:"),
# ARGV[2] the lease window in ms. The script's reply is the claim result.
def claim(conn, queue, lease_ms) when is_integer(lease_ms) and lease_ms > 0 do
  if paused?(conn, queue) do
    :empty
  else
    keys = [Keyspace.queue_key(queue, "pending"), Keyspace.queue_key(queue, "active")]
    argv = [Keyspace.queue_key(queue, "job:"), Integer.to_string(lease_ms)]

    case Connector.eval(conn, @claim, keys, argv) do
      {:ok, []} -> :empty                              # pending was empty
      {:ok, [id, payload, att]} -> {:ok, {id, payload, att}}  # the claimed job + its fencing token
      other -> other
    end
  end
end
```

The pause flag itself is the `paused` field on `emq:{q}:meta`, read host-side by `paused?/2` — a paused queue answers
`:empty` even with a non-empty pending set, and the pending set is left unmutated.

## Beat two — the script body

`@claim` is the transition. `KEYS[1]` is the pending set, `KEYS[2]` the active set; `ARGV[1]` is the job-key base,
`ARGV[2]` the lease window. The empty-pop branch returns an empty table — the handle reads it as `:empty`.

```lua
-- the @claim script — one atomic transition
-- Pop the oldest pending id. The pending set is scored at 0, so ZPOPMIN returns
-- the lexically-smallest member — and because the member is the branded id,
-- lexically-smallest is mint-oldest. An empty pop returns {} (the handle's :empty).
local popped = redis.call('ZPOPMIN', KEYS[1])
if #popped == 0 then return {} end
local id = popped[1]
local jk = ARGV[1] .. id
-- Increment attempts and KEEP the new value: this number IS the fencing token.
-- The worker that holds it is the current claimant; a later complete/extend must
-- present this exact number or be refused as stale.
local att = redis.call('HINCRBY', jk, 'attempts', 1)
redis.call('HSET', jk, 'state', 'active')
-- The SERVER clock, not the caller's. now + lease is the lease DEADLINE, and it
-- is stored as the active-set SCORE — so the active set is, by construction, an
-- index of leases ordered by expiry. Recovery is a range query over it.
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
-- Return the id, the payload, and the fencing token to the worker.
return {id, redis.call('HGET', jk, 'payload'), att}
```

No part of this can interleave with another claim: `ZPOPMIN` removes the id before any other claimer can pop it, and the
whole script runs as one server-side step. Two workers cannot claim the same job.

## Interactives

- **Hero — the claim stepper.** Step the four moves of `@claim` (pop → increment attempts → set active → score the
  lease) over a fixed dataset; the readout shows the line and what it establishes (the fencing token, the lease
  deadline).
- **Main — the lease + token inspector.** Pick a lease window and a "now"; the readout computes the active-set score
  (`now + lease`) and the new `attempts` value, and shows how a second claimer finds the pending set already popped.

## Pattern & implementation

- The pattern (Redis Patterns Applied): a reliable claim atomically moves a job out of the wait list and stamps it with
  an expiry, so a dead worker's job can be recovered — *The reliable queue* in `/redis-patterns/queues`.
- The implementation (echo_mq): `@claim` pops, fences (`attempts`), and leases (the active-set score) in one atomic
  script; `claim/3` gates on `paused?/2` first and returns the fencing token to the worker.

## References

### Sources
- Valkey — ZPOPMIN — `https://valkey.io/commands/zpopmin/` — the atomic pop of the oldest pending member.
- Valkey — ZADD — `https://valkey.io/commands/zadd/` — the active-set insertion that scores the lease deadline.
- Valkey — HINCRBY — `https://valkey.io/commands/hincrby/` — the attempts increment that mints the fencing token.
- Redis — EVALSHA — `https://redis.io/commands/evalsha/` — the load-once dispatch the handle runs `@claim` by.

### Related in this course
- `/echomq/queue/the-lifecycle` — the module this dive belongs to.
- `/echomq/queue/the-lifecycle/the-four-sets` — the active set the lease score lives in.
- `/echomq/protocol/the-lua-layer` — the Lua layer `@claim` is a script in.
- `/redis-patterns/queues` — the reliable-queue pattern this implements.
