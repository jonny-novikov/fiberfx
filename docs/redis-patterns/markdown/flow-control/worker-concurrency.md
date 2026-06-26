# Worker concurrency

> Route: `/redis-patterns/flow-control/worker-concurrency` · R6.05 module hub · Redis Patterns Applied
> Identity: BCS contract-sheet, redis-red. Grounded in the real as-built echo data layer (`echo/apps/echo_mq`).
> Technique (not a fresh catalog pattern): the per-claim fetch ceiling and how to plan capacity around it.

**Worker concurrency is running many workers against one store without the wire becoming the bottleneck: the BEAM
gives concurrency cheaply, but a claim is a round-trip, so throughput is set by how many round-trips are in flight,
not by how many processes are running.** A consumer that parks instead of polling costs the wire nothing while idle;
a pool of pipelined connectors raises the number of round-trips that can be outstanding at once; and a batch claim
amortizes the per-claim fetch when one job per trip is the ceiling.

This is a flow-control *technique*, applied to the BCS bus. It is built from three real surfaces — `EchoMQ.Consumer`
(the claim loop that owns the rhythm), `EchoMQ.Pool` (the concurrency primitive), and the per-claim `ZPOPMIN` fetch
inside `claim/3`, amortized by `EchoMQ.Lanes.bclaim/3`. The throughput question is structural: how wide is the pool,
how often does a consumer claim, and is each claim one job or many.

## The wire is the shared resource

The BEAM makes processes cheap. A deployment can run thousands of consumer processes for the cost of a few
megabytes, and OTP supervises them for free. So the instinct is to add workers when a queue falls behind. But adding
BEAM processes does not, on its own, raise throughput against Valkey.

The reason is the connector. A single owned socket carries one command at a time: requests go out and replies come
back in order, on the wire. Ten processes sharing one connector do not get ten times the work done — they queue at
the socket, and the wire serves them one round-trip at a time. Concurrency on the BEAM is not parallelism on the
wire. The shared resource is the connection, and the unit of cost is the round-trip.

The claim loop is `EchoMQ.Consumer`. It holds a **dedicated connector** — a private lane, so a blocking verb cannot
stall a shared one — and beats on a cadence: reap expired leases, promote due schedules, drain the ring with
rotating claims, then park.

```
EchoMQ.Consumer.start_link(queue: "orders", handler: &handle/1, connector: conn_opts)
# → a supervised loop with its own connector lane; beats reap → promote → drain → park
```

The handler is a function taking `%{id:, payload:, attempts:, group:}` and answering `:ok` or `{:error, reason}`.
A returned error becomes a typed retry; a raising handler is caught and retried too, and the loop survives.

## Park, don't poll

A naive worker loop polls: claim, and if the queue is empty, sleep a little and claim again. Polling spends
round-trips on an idle queue and adds latency on a busy one. The consumer does neither. When the ring is drained it
**parks on the wake key with `BLPOP`** until readiness arrives as a wake or the beat elapses:

```
# inside the consumer's park step:
BLPOP emq:{q}:wake <beat seconds>
```

`BLPOP` blocks the connection until something is pushed to the wake key or the timeout expires. An enqueue pushes a
wake token, which unparks exactly the consumers waiting on it. **A parked consumer costs the wire nothing** — no
round-trips spent waiting, and no polling delay when work arrives. The beat doubles as the cadence for the reap and
promote sweeps, so an idle consumer still wakes periodically to do its housekeeping.

Because `BLPOP` holds the connection for the duration of the block, a blocking consumer needs its own connector
lane — which is exactly why the consumer holds a dedicated connector and never shares one. A shared connector would
have every other command on it wait behind the block.

## The pool is the concurrency primitive

Real parallelism against Valkey means more sockets. `EchoMQ.Pool` is a fixed pool of pipelined connectors with
lock-free round-robin dispatch:

```
EchoMQ.Pool.start_link(name: :work_pool, size: 4)
# → 4 supervised connectors, each a pipeline; next/1 picks the next by an atomic counter
```

> "A fixed pool of pipelined connectors with lock-free round-robin dispatch. Each member is already a pipeline, so a
> small pool multiplies throughput without checkout ceremony."

There is no checkout, no lock, no waiting for a free connection. A caller hits the **next** member by an atomic
counter (`:atomics.add_get`) and the member's own FIFO does the rest. One supervisor, N connectors, one dispatcher —
the single connector, multiplied. Pool width is the number of round-trips that can be outstanding at once: it is the
real parallelism, where the count of BEAM processes is only concurrency.

The consumer's opt-in `:metronome` mode fans a pool's readiness from one blocker: each consumer registers idle with
the queue's metronome, awaits a `:claim_once` poke, claims once, settles, and re-registers — one block per queue, the
herd gone, readiness handed out fairly across the pool.

## The per-claim fetch is the ceiling

Every claim pops one job. `claim/3` runs one `ZPOPMIN` against the pending set, mints a lease on the server clock,
and returns one job — one job per claim, one round-trip per claim. The fetch is the throughput ceiling: a worker
cannot go faster than its round-trips, and each round-trip carries one job.

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

The amortization is the batch claim. `EchoMQ.Lanes.bclaim/3` is the count-variant of the same spine: it reads the
pending depth, clamps `k = min(requested, depth)` so it never over-pops, reads **one** `TIME` for the whole batch so
every served job is leased on the same deadline, then loops the per-job transitions and returns up to `k` jobs in one
round-trip. The same fetch, amortized over `k` jobs:

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

So three knobs raise throughput, and they are independent. Pool width sets how many fetches are outstanding at once.
Batch size sets how many jobs each fetch carries. The claim cadence (`:beat_ms`) sets how often a consumer reaches
for work. None of them is the count of BEAM processes.

## Applied in EchoMQ

The technique is the consumer loop plus the pool plus the fetch. `EchoMQ.Consumer` owns the rhythm and parks on
`BLPOP` so an idle worker is free; `EchoMQ.Pool` multiplies the sockets so many round-trips run at once; and the
per-claim `ZPOPMIN` is the unit of throughput, amortized by `EchoMQ.Lanes.bclaim/3` when one job per trip is the
ceiling. The count of workers is concurrency; the pool width and the batch size are throughput.

**The pattern → its EchoMQ application.** Worker concurrency — run many workers without the wire becoming the
bottleneck ↔ `EchoMQ.Pool` (N pipelined connectors, round-robin by an atomic counter) feeding `EchoMQ.Consumer`
loops that park on `BLPOP` (no poll), each claim one `ZPOPMIN` round-trip — amortized by the batch claim
`EchoMQ.Lanes.bclaim/3`.

In codemojex — a Telegram emoji-guessing game on the same stack — `Codemojex.Guesses.submit/3` enqueues each guess
as a branded `JOB` on the player's lane (`emq:{cm}:…`), and `Codemojex.ScoreWorker` is the scoring consumer:
`EchoMQ.Consumer` drains the guess queue through `Lanes.claim`, the player id arriving as the lane group. During a
busy event — many rooms guessing at once — the per-claim `ZPOPMIN` is the ceiling, and pool width plus the batch
claim are what keep the scoring engine ahead of the field. Wiring the claim loop into a production deployment — the
pool sizing, the lease recovery, the metrics per queue — is the queue's scaling layer, taught in the EchoMQ course
rather than here.

## When to use / when to avoid

**Widen the pool and batch the claim when:**

- A queue falls behind and adding consumer processes does not help — the bottleneck is the wire, not the BEAM, so
  the lever is more sockets (pool width), not more processes.
- The per-job work is small relative to the round-trip, so the fetch dominates and a batch claim (`bclaim/3`)
  amortizes it over several jobs.
- Many consumers compete on one queue and the thundering herd of wakes is a cost — the `:metronome` pool path fans
  readiness from one blocker.

**Leave the defaults when:**

- The queue keeps up at one connector and a modest beat — concurrency is not the constraint, and a wider pool buys
  nothing.
- The per-job handler work dwarfs the round-trip; then the fetch is not the ceiling, the handler is, and batching the
  claim changes little.
- A hard ceiling on the *rate* of work is the goal rather than throughput — that is the rate limiter, a per-window
  counter, not pool width.

## References

### Sources

- Valkey — *BLPOP* (https://valkey.io/commands/blpop/) — block the connection until an element is pushed or the
  timeout expires; the park step that lets an idle consumer cost the wire nothing.
- Valkey — *ZPOPMIN* (https://valkey.io/commands/zpopmin/) — pop the lowest-scored member of a sorted set; one pop
  per claim is the per-claim fetch, the throughput ceiling.
- Valkey — *Pipelining* (https://valkey.io/topics/pipelining/) — send many commands without waiting for each reply,
  so a pipelined connector keeps several round-trips outstanding.
- Valkey — *Cluster specification* (https://valkey.io/topics/cluster-spec/) — the `{q}` hash tag pins a queue's keys
  to one of 16384 slots, so a multi-key claim script is slot-legal.

### Related in this course

- R6 · Flow Control & Scale (`/redis-patterns/flow-control`) — the chapter.
- R6.05.1 · Parallel vs concurrent (`/redis-patterns/flow-control/worker-concurrency/parallel-vs-concurrent`) — why
  the wire, not the BEAM, is the shared resource.
- R6.05.2 · The per-claim fetch bottleneck
  (`/redis-patterns/flow-control/worker-concurrency/the-per-claim-fetch-bottleneck`) — one `ZPOPMIN` per claim, and
  how `bclaim/3` amortizes it.
- R6.05.3 · Capacity planning (`/redis-patterns/flow-control/worker-concurrency/capacity-planning`) — the structural
  knobs, reasoned in round-trips.
- /echomq/queue — EchoMQ's Queue pillar, where the consumer and pool are wired into a production deployment.
- /bcs/bus — Part B3, the Valkey-native bus the figures draw from.
