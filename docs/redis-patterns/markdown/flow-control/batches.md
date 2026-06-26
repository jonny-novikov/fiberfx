# Batches & pipelining

> Route: `/redis-patterns/flow-control/batches` · R6.04 module hub · Redis Patterns Applied
> Identity: BCS contract-sheet, redis-red. Grounded in the real as-built echo data layer (`echo/apps/echo_mq`).
> Technique (not a fresh catalog pattern): applies `atomic-updates` (R2.01) — the per-item idempotent script —
> run many times in one wire flush.

**Batching turns many small writes into one network round-trip: assemble the commands, send them together, read
the replies together — paying the wire cost once instead of once per item.** A queue that admits work one job at a
time pays a request-and-reply latency for every job; under a burst that latency, not the server, is the wall the
throughput hits. Pipelining moves the wall: the producer sends the whole burst in one flush and the round-trip is
amortised across every item in it.

This is a flow-control *technique*, applied to the BCS bus. The real surface is `EchoMQ.Jobs.enqueue_many/4` — and
it is worth being precise about what it is, because the catalog name "bulk enqueue" invites a wrong picture. It is
**not** a transaction. It is a **pipeline of per-item idempotent scripts in one flush**, and it returns a **verdict
per item** rather than a single all-or-nothing result. That distinction is the spine of this module.

## What batching is, and what it is not

Two different ideas hide under "do many things at once," and conflating them is the common mistake.

- **Pipelining** is a transport optimisation. The client stops waiting for each reply before sending the next
  command; it writes N commands to the socket back to back and then reads N replies. The server still runs N
  commands — pipelining changes *when the bytes travel*, not *how much work the server does*. The win is wall-clock
  round-trip time.
- **A transaction** (`MULTI`/`EXEC`) is an atomicity guarantee. The commands run as one indivisible unit; either
  every queued command applies or, on the narrow conditions `MULTI` rolls back, none do. The win is all-or-nothing
  semantics, paid for with the cost of holding and discarding a batch.

`enqueue_many/4` is the first, not the second. It pipelines N idempotent enqueue scripts and returns a list of N
verdicts. There is no rollback: if the third item is a duplicate, the first two are still enqueued and the verdict
list says so plainly at position three. That is a deliberate design choice, examined in the third dive.

## One round-trip, N scripts

`EchoMQ.Jobs.enqueue_many(conn, queue, pairs, opts \\ [])` takes a list of `{id, payload}` pairs and admits them in
one wire flush. It runs in two wire steps:

1. **Load the script once.** `SCRIPT LOAD` caches the enqueue script body and returns its SHA. Valkey's script
   cache is **server-global** — one server, one cache — so a single load makes the SHA resolvable for every command
   that follows, on any pooled connection.
2. **Assemble and flush the batch.** For each pair it appends an `EVALSHA` command — the cached enqueue script,
   keyed at this pair's job key and the queue's pending set — to an `EchoWire.Pipe`, then flushes the whole pipe in
   one `exec`. The replies come back in one frame, in input order.

```
EchoMQ.Jobs.enqueue_many(conn, "cm", pairs)
# → SCRIPT LOAD once, then one EVALSHA per pair flushed together through EchoWire.Pipe
# → [:enqueued, :duplicate, :enqueued, {:error, :kind}, ...]  (one verdict per pair, in order)
```

Each pair runs the same script `enqueue/4` runs for a single job — the per-item atomic move from the
`atomic-updates` pattern. The script kind-gates the id, refuses a duplicate, and writes the row and the pending
entry on the server in one step:

```lua
if string.sub(ARGV[1], 1, 3) ~= 'JOB' then
  return redis.error_reply('EMQKIND job id must be JOB-namespaced')
end
if redis.call('EXISTS', KEYS[1]) == 1 then
  return 0
end
redis.call('HSET', KEYS[1], 'state', 'pending', 'attempts', '0', 'payload', ARGV[2])
redis.call('ZADD', KEYS[2], 0, ARGV[1])
return 1
```

So each member is: kind-gate (`JOB`-namespaced) → duplicate refusal (`EXISTS` returns `0`) → row write plus
pending insert → `1`. The batch pipelines many of these. The **idempotency is per item** — `:duplicate` is one
item's verdict, never an abort of the rest — which is exactly why the move is a pipeline and not a single
`MULTI`/`EXEC`.

## The verdict per item

The reply is a list, in input order, one entry per pair:

- `:enqueued` — the script returned `1`: the row and the pending entry were written.
- `:duplicate` — the script returned `0`: a row already existed at that id, so nothing changed.
- `{:error, :kind}` — the id was not `JOB`-namespaced; the script refused it with `EMQKIND` and that one item
  failed.

An **empty** `pairs` list answers `{:error, :empty_pipeline}` — there is nothing to flush, and the empty pipe
refuses rather than send an empty frame. A non-empty batch always returns the verdict list; reading it is how a
caller learns which items landed.

## Chunking across a pool

`opts[:via]` chooses the dispatch module. The default is the single connector; passing `via: EchoMQ.Pool` fronts
the flush with a fixed pool of pipelined connectors, dispatched round-robin by a lock-free atomic counter. Because
`SCRIPT LOAD` is server-global, the SHA the first member loaded resolves on every other member too — so the
round-robin `EVALSHA` never faults with `NOSCRIPT` across members. A very large batch is chunked so no single
member's FIFO grows overlong; the pool multiplies the flush across members without checkout ceremony. The `via`
reference is carried through and never inspected.

## The claim side, in one shape

The mirror of a batch enqueue is a batch claim. `EchoMQ.Lanes.bclaim/3` rotates to a serviceable lane and serves up
to a batch of heads in one script, every member leased on **one shared `TIME` deadline** read once for the whole
batch. The non-grouped spine is the count-variant `ZPOPMIN` loop: it reads the pending depth, clamps the count to
`k = min(requested, depth)` so it never over-pops, takes one server-clock reading, and pops `k` heads on that one
deadline. An under-fill returns the short list rather than refusing.

The batch is a **claim unit, not a resolution unit**. The members are claimed together, but each is settled on its
own through the byte-frozen completion and retry paths — so one poisoned member is isolated to its own retry while
the rest of the batch settles.

## Applied in EchoMQ

> **The pattern** — many writes, one round-trip, no rollback.
> **↔** Its EchoMQ application — `EchoMQ.Jobs.enqueue_many/4`: the per-item idempotent enqueue script `SCRIPT LOAD`ed
> once (server-global cache), an `EVALSHA` per pair assembled through `EchoWire.Pipe` and flushed in one round-trip,
> a **verdict per item** (`:enqueued` / `:duplicate` / `{:error, :kind}`) returned in input order.

The whole technique is `EchoMQ.Jobs.enqueue_many/4`, and it is the `atomic-updates` pattern run in bulk: the same
script, the same row shape, the same idempotency as the single `enqueue/4`, pipelined so the wire is paid once. The
batch is not transactional, and that is the design — per-item idempotent dedup beats whole-batch rollback for an
at-least-once queue, because a re-sent batch settles to the same state rather than failing wholesale.

A consumer makes the burst concrete. In codemojex — a Telegram emoji-guessing game on the same stack — a single
guess is admitted by `Codemojex.Guesses.submit/3`, which mints a branded `JOB`, builds the guess payload, and
enqueues it. When the bot ingests a burst of player commands at once, the flat-queue shape of the same move admits
the whole burst in one flush — `enqueue_many(conn, "cm", pairs)` over `emq:{cm}:pending` — so one wire round-trip
admits the burst and each guess-`JOB` is idempotent at its own `JOB`-keyed row.

Wiring the batch claim into the dequeue path at scale — the consumer that drives `bclaim/3`, the pool width, the
lease recovery — is the queue's scaling layer, taught in the EchoMQ course rather than here.

## When to use / when to avoid

**Reach for a pipelined batch when:**

- A producer admits many jobs at once and the per-job round-trip is the bottleneck — a burst of events, a fan-out, a
  backfill.
- Each item is independently meaningful: a duplicate or a bad id on one item should not undo the others. Per-item
  verdicts are exactly what you want to read back.
- The work is idempotent at the item level, so a re-sent batch settles to the same state. The enqueue script's
  `EXISTS` guard gives this for free.

**Avoid a pipelined batch — or reach for a real transaction instead — when:**

- The items must be all-or-nothing: either every write applies or none does. That is a transaction's job, not a
  pipeline's; a pipeline has no rollback.
- The batch is so large that one connection's FIFO would grow unbounded; chunk it across a pool, or cap the chunk
  size.
- There is only ever one item; the batch machinery adds assembly with no round-trip to amortise.

The dives take the three moves apart in turn: where the round-trip win actually comes from, how a pool chunks a
batch so the server-global cache keeps `EVALSHA` resolvable, and the honest contrast with `MULTI`/`EXEC` that
corrects the "all-or-nothing" picture.

## References

### Sources

- Valkey — *Pipelining* (https://valkey.io/topics/pipelining/) — sending multiple commands without waiting for each
  reply; the transport optimisation behind a batch enqueue, and why it is not a transaction.
- Valkey — *EVALSHA* (https://valkey.io/commands/evalsha/) — run a cached script by its SHA; the per-item command a
  batch assembles, resolvable on any connection once the body is loaded.
- Valkey — *SCRIPT LOAD* (https://valkey.io/commands/script-load/) — cache a script body and return its SHA; the
  server-global cache that lets a pool's round-robin `EVALSHA` never fault.
- Valkey — *Transactions* (https://valkey.io/topics/transactions/) — `MULTI`/`EXEC` and the all-or-nothing
  guarantee a pipeline deliberately does not provide.
- Valkey — *ZADD* (https://valkey.io/commands/zadd/) — the score-0 insert that puts a job's branded id into the
  pending set in the enqueue script.

### Related in this course

- R6 · Flow Control & Scale (`/redis-patterns/flow-control`) — the chapter.
- R6.04.1 · Round-trip elimination (`/redis-patterns/flow-control/batches/round-trip-elimination`) — N round-trips
  collapse to one flush; the win is wall-clock RTT, not server work.
- R6.04.2 · Chunking across a pool (`/redis-patterns/flow-control/batches/chunking-across-a-pool`) — `via: EchoMQ.Pool`,
  round-robin dispatch, and the server-global script cache.
- R6.04.3 · Partial-failure handling (`/redis-patterns/flow-control/batches/partial-failure-handling`) — per-item
  verdicts against `MULTI`/`EXEC` rollback; the honest model.
- R2 · Distributed coordination (`/redis-patterns/coordination`) — `atomic-updates`, the per-item idempotent script
  each batch member runs.
- /echomq/queue — EchoMQ's Queue pillar, where the batch claim and pool width are wired at the dequeue point.
- /bcs/bus — Part B3, the Valkey-native bus the figures draw from.
