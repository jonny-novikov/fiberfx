# Chunking across a pool

> Route: `/redis-patterns/flow-control/batches/chunking-across-a-pool` · R6.04.2 dive · Redis Patterns Applied
> Identity: BCS contract-sheet, redis-red. Grounded in the real as-built echo data layer (`echo/apps/echo_mq`).

**One pipelined connection is already fast; a pool of them is faster, because the flush round-robins across several
sockets. The trick that makes it safe is that the script cache is server-global — load the body once on any member
and every member can run it by SHA.** This dive is about flushing a batch through `EchoMQ.Pool`, and the one
property that keeps a round-robin `EVALSHA` from faulting.

## A pool of pipelines

`EchoMQ.Pool` is a fixed pool of pipelined connectors with lock-free round-robin dispatch. Each member is already a
pipeline, so a small pool multiplies throughput without checkout ceremony: a caller hits the next member by an
atomic counter, and that member's own FIFO does the rest. One supervisor, N connectors, one dispatcher.

The default size is four. `next/1` picks the next member with an atomic add-and-get — no lock, no contention:

```
defp next(name) do
  {size, at} = :persistent_term.get({__MODULE__, name})
  member(name, rem(:atomics.add_get(at, 1, 1), size) + 1)
end
```

`:atomics.add_get` bumps a shared counter and returns the new value in one hardware-atomic step; the remainder maps
it onto a member index. Two callers racing to dispatch get two different members, with no coordination between them.
`command/3`, `pipeline/3`, and `eval/5` all route through this `next/1`, so every call spreads across the pool.

## Fronting the flush with the pool

`enqueue_many/4` takes the pool through `opts[:via]`. The default `via` is the single connector — so the
single-argument form is unchanged — and passing `via: EchoMQ.Pool` routes both wire steps through the pool instead:
the `SCRIPT LOAD`, and the `EchoWire.Pipe` flush.

```
EchoMQ.Jobs.enqueue_many(conn, "cm", pairs, via: EchoMQ.Pool)
# → SCRIPT LOAD on one member; the EVALSHA batch flushed round-robin via Pool.pipeline/3
```

The pipe carries the `via` reference and flushes through `Pool.pipeline/3` when a pool is supplied. The reference is
carried, never inspected — the batch does not look inside the pool, it only dispatches through it.

## The fault that does not happen

Here is the hazard the design has to answer. `enqueue_many/4` loads the script with `SCRIPT LOAD` once, on whichever
member the call lands on. Then it sends the batch as `EVALSHA` — run-by-SHA — round-robin across members. If the
cache were per connection, every member except the one that loaded the body would answer the `EVALSHA` with
`NOSCRIPT`, because they had never seen the script.

That fault does not happen, because Valkey's script cache is **server-global**. There is one server, and one cache
in it; the SHA the first member loaded is resolvable for every connection to that server, pooled or not. So a single
`SCRIPT LOAD` on any member makes the subsequent round-robin `EVALSHA` resolve on all of them.

```
# enqueue_many/4, the two wire steps through `via`:
via.command(conn, ["SCRIPT", "LOAD", source])   # cache the body once — server-global
# ... then the EVALSHA batch, flushed round-robin through Pool.pipeline/3
```

The `SCRIPT LOAD` caches the script on whichever member it lands on; because the cache is server-global, that one
load makes the SHA resolvable on every member, which is why the round-robin `EVALSHA` never faults across members.

> **The pattern** — multiply a pipelined flush across several connections without coordination.
> **↔** Its EchoMQ application — `EchoMQ.Pool` dispatches each call to the next member by a lock-free atomic counter;
> `enqueue_many/4` with `via: EchoMQ.Pool` flushes the `EVALSHA` batch round-robin, and the server-global script
> cache keeps every member's `EVALSHA` resolvable from one `SCRIPT LOAD`.

## Chunking a very large batch

Round-robin spreads a batch across members, but each member's flush still queues on that member's FIFO. A single
enormous batch flushed through one member would grow that member's FIFO unbounded; chunking is the answer. Split a
huge batch into chunks and flush each chunk, so no single member holds an overlong pipeline at once and the work
spreads across the pool. The chunk size is a throughput-versus-memory knob: larger chunks amortise more round-trip
per flush, smaller chunks bound the in-flight queue depth.

## Applied

In codemojex — a Telegram emoji-guessing game on the same stack — many bot workers admit guesses concurrently. A
burst that arrives all at once is the case where the pool earns its width: the flat-queue batch over
`emq:{cm}:pending` flushes round-robin across the pool's members, each guess a `JOB`-keyed idempotent enqueue, and
the one `SCRIPT LOAD` keeps every member's `EVALSHA` resolvable. The per-claim and pool-width tuning at the dequeue
side is the queue's scaling layer, taught in the EchoMQ course.

## References

### Sources

- Valkey — *SCRIPT LOAD* (https://valkey.io/commands/script-load/) — cache a script body and return its SHA; the
  cache is server-global, which is the property the pool relies on.
- Valkey — *EVALSHA* (https://valkey.io/commands/evalsha/) — run a cached script by SHA, with `NOSCRIPT` when the
  body is not cached; the fault the server-global cache avoids across pool members.
- Valkey — *Pipelining* (https://valkey.io/topics/pipelining/) — why each member being a pipeline already multiplies
  throughput before the pool widens it.

### Related in this course

- R6.04 · Batches & pipelining (`/redis-patterns/flow-control/batches`) — the module hub.
- R6.04.1 · Round-trip elimination (`/redis-patterns/flow-control/batches/round-trip-elimination`) — the single-flush
  win the pool multiplies.
- R6.04.3 · Partial-failure handling (`/redis-patterns/flow-control/batches/partial-failure-handling`) — the per-item
  verdicts a pooled flush returns, in order.
- /echomq/queue — EchoMQ's Queue pillar, where pool width is tuned at the dequeue point.
- /bcs/bus — Part B3, the Valkey-native bus the figures draw from.
