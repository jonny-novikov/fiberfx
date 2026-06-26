# R8.02.2 · Pool sizing — pipeline depth, not cores

> Dive · `/redis-patterns/production-operations/persistence-pooling-failover/pool-sizing`

A connection pool is the standard answer to serving many callers over a server. The standard intuition
for sizing it — one connection per CPU core, because more cores means more parallelism — is wrong for
Valkey, and getting it wrong wastes sockets without buying throughput. This dive derives the right rule
from the real `EchoMQ.Pool` and the one fact that overturns the intuition: the server runs commands on a
single thread.

## EchoMQ.Pool — N pipelined connectors, round-robined lock-free

`EchoMQ.Pool` (`echo/apps/echo_mq/lib/echo_mq/pool.ex`) is a fixed pool of pipelined connectors with
lock-free round-robin dispatch. Its moduledoc states the shape:

```
A fixed pool of pipelined connectors with lock-free round-robin dispatch.
Each member is already a pipeline, so a small pool multiplies throughput
without checkout ceremony: callers hit the next member by an atomic
counter and the member's own FIFO does the rest. One supervisor, N
connectors, one dispatcher -- the appendix connector, multiplied.
```

Two design choices carry the production behaviour. First, **each member is already a pipeline** — a
single `EchoMQ.Connector` keeps a FIFO of in-flight commands on one socket, so it does not block waiting
for a reply before sending the next. Second, **dispatch is lock-free** — there is no checkout. `next/1`
advances an `:atomics` counter and a caller hits the next member directly:

```
defp next(name) do
  {size, at} = :persistent_term.get({__MODULE__, name})
  member(name, rem(:atomics.add_get(at, 1, 1), size) + 1)
end
```

The default is `size: 4`. There is no per-call lock contention: `:atomics.add_get` is an atomic
increment, and the member's own FIFO does the ordering. A small pool multiplies throughput without
checkout ceremony.

## The single-threaded server — the insight that overturns the intuition

Here is the fact that decides how to size it. Valkey executes commands on a **single thread**. The real
`valkey.conf` sets `io-threads 1` and its comment reads *"command execution is single-threaded."* No
matter how many connections you open, the server runs one command at a time.

So a pool does **not** buy N× server parallelism. Opening four connections does not let the server run
four commands at once — it runs them one after another on the same thread. What the pool buys is
something else: it hides **round-trip latency**. With one connection, a caller that waits for each reply
before sending the next leaves the command thread idle during every network round trip. With a pipeline,
commands stack on the wire and the one command thread stays fed — it always has the next command ready
when it finishes the last. The pool is several pipelines, so several callers can keep the thread fed
concurrently without coordinating.

The rule that follows: **size for pipeline depth and RTT-hiding, not for cores.** Enough connectors to
keep the single command thread continuously fed across the network round trip is enough. Beyond that,
each extra connection adds a socket the single thread serializes anyway — more memory and more file
descriptors, no more throughput. `size: 4` is a small pool because a small pool is what RTT-hiding needs;
over-sizing it to match core count is sizing for parallelism the server does not have.

## The same Pool, sized rather than introduced — the R6.05 tie

R6.05 (`worker-concurrency`) introduces this exact `EchoMQ.Pool` as the concurrency primitive: how
workers share connectors to drain a queue. This dive does not re-teach that — it *sizes* the same Pool
for production, with the single-threaded-server fact as the sizing rule. R6.05 is the what; this is the
how-big.

## The bridge

| The pattern — pool for RTT-hiding | Its EchoMQ application |
|---|---|
| Size a connection pool for pipeline depth to keep a single command thread fed across the round trip, not for cores the server does not use | `EchoMQ.Pool` round-robins `size: 4` pipelined connectors lock-free via `:atomics`; over a Valkey with `io-threads 1`, four pipelines hide RTT for the codemojex bot workers without contending for parallelism the server never had |

The take: pool sizing is a question about the network, not the CPU. A pool hides the round trip on a
single-threaded server; size it for the depth that keeps the thread fed, and stop.

## Where the pool meets the rest of the posture

The pool serves the load; the persistence policy (dive 1) keeps the data across a restart; the connector
(dive 3) keeps each member reachable across a failover. The three are one production posture: a member of
the pool *is* an `EchoMQ.Connector`, so the pool inherits the connector's reconnect discipline — a member
whose socket drops fails its in-flight callers `:disconnected` and reconnects on its own, while the other
members keep serving.

## References

### Sources

- [Redis — *Pipelining*](https://redis.io/docs/latest/develop/use/pipelining/) — why a pipeline hides
  round-trip latency, the premise behind sizing for depth rather than cores.
- [Valkey — *Clients*](https://valkey.io/topics/client-side-caching/) — the client-side behaviour a
  pooled connector negotiates; pipelining and connection reuse.
- [Redis — *Documentation*](https://redis.io/docs/) — the connection and performance topics pool sizing
  draws on.
- [antirez — *On Redis latency*](https://antirez.com/latency) — the Redis creator's notes on the single
  command thread and where latency comes from.

### Related in this course

- [R8.02 · Persistence, pooling & failover](/redis-patterns/production-operations/persistence-pooling-failover) — the module hub.
- [R6.05 · Worker concurrency](/redis-patterns/flow-control/worker-concurrency) — the same `EchoMQ.Pool` as the concurrency primitive.
- [R8.02.1 · RDB and AOF](/redis-patterns/production-operations/persistence-pooling-failover/rdb-and-aof) — the durability policy this load runs over.
- [R8.02.3 · READONLY-reconnect failover](/redis-patterns/production-operations/persistence-pooling-failover/readonly-reconnect-failover) — the reconnect discipline each pool member inherits.
- [/echomq · the Proof pillar](/echomq/proof) — the production evidence the bus carries.
- [/bcs · Production on Fly](/bcs/fly) — where this pool runs against a Fly Valkey.
