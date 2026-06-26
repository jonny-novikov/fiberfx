# The per-claim fetch bottleneck

> Route: `/redis-patterns/flow-control/worker-concurrency/the-per-claim-fetch-bottleneck` · R6.05.2 dive · Redis Patterns Applied
> Identity: BCS contract-sheet, redis-red. Grounded in the real as-built echo data layer (`echo/apps/echo_mq`).

**Each claim is one `ZPOPMIN` round-trip, so at high worker count the round-trip time dominates, not server CPU; the
fix is `EchoMQ.Lanes.bclaim/3`, the count-variant that serves k jobs per round-trip on one shared lease.** When the
per-job work is small relative to a round-trip, the fetch is the ceiling, and amortizing it is the lever.

## One claim, one job, one round-trip

`claim/3` serves one job. Inside it runs one `ZPOPMIN` against the pending sorted set, mints a lease on the server
clock, flips the job's state, and returns the single popped job. The whole exchange is one round-trip: the request
goes out, one job comes back. This is the `@claim` spine, verbatim:

```lua
local popped = redis.call('ZPOPMIN', KEYS[1])
if #popped == 0 then return {} end
local id = popped[1]
local jk = ARGV[1] .. id
local att = redis.call('HINCRBY', jk, 'attempts', 1)
redis.call('HSET', jk, 'state', 'active')
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
return {id, redis.call('HGET', jk, 'payload'), att}
```

`ZPOPMIN` pops the lowest-scored member — the head of the queue by score — and the script reads `TIME` for the lease
deadline so no host clock crosses the lease. The work the server does is small: a pop, an increment, a couple of
writes. The cost that matters at scale is the round-trip itself — the request out and the reply back over the
connection.

## When the round-trip dominates

Imagine a handler whose work is brief — a small computation, a single write elsewhere. A worker spends a round-trip
to claim one job, does the brief work, and spends another round-trip to claim the next. As workers are added (each
its own connector, real parallelism), more claims run at once, but every job still costs its own claim. The ceiling
is the rate of round-trips, and one job rides each one.

This is the regime where adding sockets stops helping. The pool is already wide, the server is not saturated, and yet
throughput is capped — because the per-claim fetch is one job per trip and the trip is the expensive part. The
profile is round-trip-bound, not CPU-bound: the latency of the network exchange, multiplied by one job per exchange,
sets the rate.

## Amortize the fetch with a batch claim

`EchoMQ.Lanes.bclaim/3` is the same spine, generalized to serve up to `k` heads in one round-trip. It reads the
pending depth, clamps `k = min(requested, depth)` so it never over-pops, reads **one** `TIME` so every job in the
batch is leased on the same deadline, then loops the per-job transitions and returns the served list:

```lua
local depth = redis.call('ZCARD', KEYS[1])
if depth == 0 then return {} end
local k = tonumber(ARGV[3])
if depth < k then k = depth end
local t = redis.call('TIME')
local now = t[1] * 1000 + math.floor(t[2] / 1000)
local served = {}
for _ = 1, k do
  local popped = redis.call('ZPOPMIN', KEYS[1])
  if #popped == 0 then break end
  local id = popped[1]
  local jk = ARGV[1] .. id
  local att = redis.call('HINCRBY', jk, 'attempts', 1)
  redis.call('HSET', jk, 'state', 'active')
  redis.call('ZADD', KEYS[2], now + tonumber(ARGV[2]), id)
  served[#served + 1] = {id, redis.call('HGET', jk, 'payload'), att}
end
return served
```

Now one round-trip carries `k` jobs instead of one. The fetch cost is amortized across the batch: the same single
exchange, divided over `k` jobs of work. An under-fill is honest — if the lane holds fewer than `k`, the loop stops
when the pop comes back empty and returns the short list, never blocking and never over-popping. The batch is a
**claim unit, not a resolution unit**: each job is settled independently afterward, over the byte-frozen completion
and retry paths.

The trade is latency for throughput. A larger batch claims more per trip but holds more leases at once, and a worker
that grabs a big batch and then stalls leaves more jobs to be reaped. So the batch size is tuned to the per-job work
and the lease window — large enough to amortize the fetch, small enough that a stall does not strand a long tail.

## The pattern, applied

**The per-claim fetch ↔ its amortization.** A per-job fetch is one `ZPOPMIN` per claim, one job per round-trip — the
ceiling when the round-trip dominates. The amortized fetch is `EchoMQ.Lanes.bclaim/3`, the count-variant `ZPOPMIN`
that serves up to `k` heads on one shared `TIME` lease, dividing the trip cost over the batch.

In codemojex the scoring consumer claims guess `JOB`s off the `cm` queue. When a single guess scores quickly, the
claim is the expensive part, and a busy event — many rooms guessing at once — is exactly where a batch claim earns
its keep: one round-trip pulls a handful of guesses, and the scoring engine stays ahead of the field. The single-pop
`claim/3` and the batch `bclaim/3` coexist; the choice is per workload, set by how the per-job work compares to the
round-trip.

> Wiring a batch-claiming consumer into a production deployment — the lease recovery for a stalled batch, the metrics
> per queue — is the queue's scaling layer, taught in the EchoMQ course.

**Notes on Valkey.** `ZPOPMIN` removes and returns the member with the lowest score in one atomic operation, so two
workers can never pop the same job — the claim is race-free by construction, single-pop or batched —
https://valkey.io/commands/zpopmin/.

## References

### Sources

- Valkey — *ZPOPMIN* (https://valkey.io/commands/zpopmin/) — pop the lowest-scored member atomically; the per-claim
  fetch, single or looped for a batch.
- Valkey — *ZCARD* (https://valkey.io/commands/zcard/) — the pending depth the batch claim reads to clamp k against
  the lane.
- Valkey — *Pipelining* (https://valkey.io/topics/pipelining/) — the round-trip cost model: a request and its reply
  are one exchange, and one job per exchange is the ceiling a batch amortizes.

### Related in this course

- R6.05 · Worker concurrency (`/redis-patterns/flow-control/worker-concurrency`) — the module hub.
- R6.05.1 · Parallel vs concurrent (`/redis-patterns/flow-control/worker-concurrency/parallel-vs-concurrent`) — pool
  width first, then the per-claim fetch.
- R6.05.3 · Capacity planning (`/redis-patterns/flow-control/worker-concurrency/capacity-planning`) — reasoning about
  throughput in round-trips, with batch size as a knob.
- /echomq/queue — the batch claim wired into a production consumer.
- /bcs/bus — Part B3, the Valkey-native bus the claim scripts run on.
