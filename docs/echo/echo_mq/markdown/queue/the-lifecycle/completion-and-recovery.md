# Completion & recovery

> Route: `/echomq/queue/the-lifecycle/completion-and-recovery` · surface: dive · pillar: The Queue.
> Grounded entirely in real code (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`). No reconcile shadow needed — all surfaces verified on disk.

## The fact

A claimed job leaves the active set in exactly one of four ways, and each is one atomic, token-fenced Lua script:

- **complete** (`@complete`) — the work succeeded. Only the holder of the current `attempts` token may retire the job:
  the script verifies the token (`EMQSTALE` on mismatch), `ZREM`s the active member, `DEL`s the row, and bumps
  `metrics:completed`.
- **retry → scheduled** (`@retry`) — the work failed below max attempts. The script records `last_error`, `ZREM`s the
  active member, sets `state = scheduled`, and `ZADD`s the schedule set at `now + delay`. The job is parked, not lost.
- **retry → dead** (`@retry`) — the work failed at max attempts. The script records `last_error`, sets `state = dead`,
  `ZADD`s the morgue, and bumps `metrics:failed`.
- **reap → pending** (`@reap`) — nobody completed or retried in time; the lease lapsed. A reaper finds the expired
  active member and returns it to pending on the **server clock** — crash recovery with no heartbeat.

A dead job is the only finished-and-retained state, so `reprocess_job/3` (dead → pending) is the "retry a failed job"
surface.

## Beat one — the complete handle

`complete/4` builds the active set and the row key, passes the id and the token, and maps the script's reply. (The fan-in
hook for flows is part of the same script; a non-flow completion runs the two-key call shown here.)

```elixir
# echo_mq — EchoMQ.Jobs (non-flow completion shape)
# complete/4 is the handle. KEYS = [active, row]; ARGV[1] is the id, ARGV[2] the
# attempts token the worker holds, ARGV[3] the queue base. Only the current token
# holder may retire the job — a stale token answers {:error, :stale}.
keys = [Keyspace.queue_key(queue, "active"), Keyspace.job_key(queue, job_id)]
argv = [job_id, Integer.to_string(token), Keyspace.queue_key(queue, "")]

case Connector.eval(conn, @complete, keys, argv) do
  {:ok, 1} -> :ok
  {:ok, 0} -> {:error, :gone}                              # the row was already gone
  {:error, {:server, "EMQSTALE" <> _}} -> {:error, :stale} # a non-current token holder
  other -> other
end
```

## Beat two — the complete body (the token fence)

`@complete` reads `attempts`, refuses a token mismatch, removes the active member, and — on the non-flow path — retires
the row and bumps the metric. The token check is what makes a redelivered or stale completion a no-op.

```lua
-- the @complete script — the token fence + the terminal (non-flow path)
-- Read the row's attempts. If the row is gone, return 0 (the handle's :gone).
local att = redis.call('HGET', KEYS[2], 'attempts')
if not att then return 0 end
-- The fence: the caller must present the CURRENT attempts token. A stale holder
-- (an old claim that was reaped and re-claimed) presents an older number and is
-- refused — its completion changes nothing.
if att ~= ARGV[2] then
  return redis.error_reply('EMQSTALE complete token mismatch')
end
-- Remove the active member; was_active is 1 if it was present (the normal case).
local was_active = redis.call('ZREM', KEYS[1], ARGV[1])
-- Retire the row and count the completion. The row is deleted — a completed job
-- leaves no row behind; the metric is the durable trace.
redis.call('DEL', KEYS[2])
redis.call('HINCRBY', ARGV[3] .. 'metrics:completed', 'count', 1)
return 1
```

## The recovery transitions

**`@retry` / `retry/7`** parks or dead-letters, token-fenced. Below max attempts it schedules with a **literal** delay
(the curve is computed above the wire); at max it dead-letters with `last_error`:

```lua
-- the @retry script — record the error, then park or dead-letter (core path)
redis.call('HSET', KEYS[4], 'last_error', ARGV[5])
if tonumber(att) >= tonumber(ARGV[4]) then          -- at or past max attempts
  redis.call('HSET', KEYS[4], 'state', 'dead')
  redis.call('ZADD', KEYS[3], 0, ARGV[1])           -- into the morgue
  redis.call('HINCRBY', ARGV[6] .. 'metrics:failed', 'count', 1)
  return 'dead'
end
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('HSET', KEYS[4], 'state', 'scheduled')
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[3]), ARGV[1])  -- park with a literal delay
return 'scheduled'
```

**`@reap` / `reap/2`** is crash recovery on the server clock. It range-queries the active set for members whose lease
score is in the past and returns each to pending — no heartbeat, no worker liveness check:

```lua
-- the @reap script — return expired leases to pending (server-clock recovery)
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
-- Any active member scored at/below now has a LAPSED lease (the claimant is gone
-- or stuck). The active-set score IS the deadline, so this is a range query.
local exp = redis.call('ZRANGEBYSCORE', KEYS[1], '-inf', now, 'LIMIT', 0, 100)
for _, id in ipairs(exp) do
  redis.call('ZREM', KEYS[1], id)                   -- out of active
  redis.call('ZADD', KEYS[2], 0, id)                -- back to pending (non-grouped path)
  redis.call('HSET', ARGV[1] .. 'job:' .. id, 'state', 'pending')
end
return #exp
```

**`reprocess_job/3`** moves a `dead` job back to pending — and refuses a job that is not dead:

```elixir
# echo_mq — EchoMQ.Jobs
# reprocess_job/3 moves a dead job back to pending: clear last_error, set
# state = pending, ZADD pending. The script refuses a job NOT in the morgue with
# {:error, :not_dead}, and a missing job with {:error, :gone}.
case Connector.eval(conn, @reprocess, keys, [job_id]) do
  {:ok, 1} -> :ok
  {:ok, -1} -> {:error, :gone}
  {:error, {:server, "EMQSTATE" <> _}} -> {:error, :not_dead}
  other -> other
end
```

## Interactives

- **Hero — the exit selector.** Pick how a claimed job leaves the active set (complete / retry-scheduled / retry-dead /
  reap) and read the transition, the resulting set, the row `state`, and the metric touched. Pure over the dataset.
- **Main — the token fence.** Present a token against a job whose current `attempts` is fixed; the readout shows
  `:ok` for the matching token and `{:error, :stale}` (`EMQSTALE`) for a stale one — the same check `@complete`,
  `@retry`, and `extend_lock/5` share.

## Pattern & implementation

- The pattern (Redis Patterns Applied): a reliable queue confirms work atomically and recovers a crashed worker's job
  from a visibility timeout — *The reliable queue* and *States as locations* in `/redis-patterns/queues`.
- The implementation (echo_mq): `@complete` token-fences the terminal; `@retry` parks or dead-letters with `last_error`;
  `@reap` returns lapsed leases to pending on the server clock; `reprocess_job/3` re-enters a dead job.

## The durable floor (the door to Echo Persistence)

A completed row is deleted and a dead-lettered job keeps its `last_error` in the morgue, but neither has to stay
resident forever. When a queue trims its history, `EchoStore.StreamArchive` folds the trimmed segments into the durable
`EchoStore.Graft` floor — CubDB's append-only B-tree, on to Tigris — deep history without resident memory, readable
beside the live tail. The fold is real code (`echo/apps/echo_store/lib/echo_store/{stream_archive,graft}.ex`); the
durable floor is taught in full in Echo Persistence (`/echo-persistence`), per `docs/echo/bcs/bcs.3.md` B3.3 / `bcs.5.md`.

## References

### Sources
- Valkey — ZRANGEBYSCORE — `https://valkey.io/commands/zrangebyscore/` — the expired-lease range the reaper reads.
- Valkey — ZADD — `https://valkey.io/commands/zadd/` — the schedule/morgue/pending insertions the transitions write.
- Valkey — ZREM — `https://valkey.io/commands/zrem/` — the active-set removal every exit performs.
- Redis — EVALSHA — `https://redis.io/commands/evalsha/` — the load-once dispatch each transition runs by SHA.

### Related in this course
- `/echomq/queue/the-lifecycle` — the module this dive belongs to.
- `/echomq/queue/the-lifecycle/claim-and-the-lease` — the lease and the token the fence checks.
- `/echomq/protocol/the-lua-layer` — the Lua layer these transitions are scripts in.
- `/redis-patterns/queues` — the reliable-queue pattern this implements.
- `/echo-persistence` — the durable floor a dead-lettered job and a trimmed segment fold into.
