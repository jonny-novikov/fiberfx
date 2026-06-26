# Parallel vs concurrent

> Route: `/redis-patterns/flow-control/worker-concurrency/parallel-vs-concurrent` · R6.05.1 dive · Redis Patterns Applied
> Identity: BCS contract-sheet, redis-red. Grounded in the real as-built echo data layer (`echo/apps/echo_mq`).

**The BEAM gives concurrency cheaply — thousands of consumer processes — but the wire is the shared resource, so
real parallelism against Valkey is N sockets, not N processes on one connector.** Concurrency without pool width does
not raise throughput; the lever is `EchoMQ.Pool` width, not the count of BEAM processes.

## Two words that are not the same

Concurrency is having many things in progress. Parallelism is having many things happen at the same instant. On the
BEAM the two come apart sharply at the connector. A process is cheap, so a deployment can run a great many consumer
processes — that is concurrency, and it is nearly free. But each command those processes send to Valkey travels over
a socket, and a single owned socket carries one command at a time.

A connector is a single-owner socket. It sends a command, waits for the reply, and sends the next — pipelining lets
several be in flight, but they are still one ordered stream on one connection. Ten processes sharing one connector
are concurrent at the BEAM and serialized at the socket: the wire serves them one round-trip at a time, in order.
Adding an eleventh process changes nothing about how fast the wire drains. The shared resource is the connection.

## The connector is the bottleneck, not the scheduler

When a queue falls behind, the instinct is to add workers. If those workers share a connector, the queue does not
drain faster — the new workers wait their turn at the socket alongside the old ones. The BEAM scheduler is not
the constraint; it has cycles to spare. The constraint is the one stream of round-trips the connection can carry.

So throughput against Valkey is set by how many round-trips are outstanding at once, and that is a property of the
sockets, not the processes. To raise it you add sockets. `EchoMQ.Pool` is exactly that: a fixed pool of connectors,
each a pipeline, with a lock-free dispatcher that hands each call to the next member.

```
A fixed pool of pipelined connectors with lock-free round-robin dispatch.
Each member is already a pipeline, so a small pool multiplies throughput
without checkout ceremony: callers hit the next member by an atomic
counter and the member's own FIFO does the rest. One supervisor, N
connectors, one dispatcher — the appendix connector, multiplied.

def next(name) do
  {size, at} = :persistent_term.get({__MODULE__, name})
  member(name, rem(:atomics.add_get(at, 1, 1), size) + 1)
end
```

`next/1` reads the pool size and an atomics counter, increments the counter atomically, and takes its value modulo
the size — so successive calls land on member 1, 2, 3, 4, 1, 2, … with no lock and no contention. Each member is its
own connector and its own pipeline. Pool width is the real parallelism: a pool of four carries four streams of
round-trips at once, where four hundred processes on one connector carry one.

## One blocker for the whole pool

Running a pool of consumers raises a second problem: if every consumer parks on the wake key, a single enqueue wakes
all of them and they all claim at once — a thundering herd of round-trips for one job. The consumer's opt-in
`:metronome` mode solves it. With a metronome a consumer does not hold its own block; it registers idle with the
queue's metronome, awaits a `:claim_once` poke, runs `EchoMQ.Lanes.claim/3` exactly once, settles, and re-registers.

There is **one blocker per queue** — the metronome — and it fans readiness out across the idle consumers, one claim
per consumer per wake. The herd is gone, readiness is handed out fairly, and the pool's sockets stay busy without
every member racing for the same job. Without a metronome the consumer is the standalone loop, self-parking on its
own wake token; a lone consumer is no herd, so it needs no coordinator.

## The pattern, applied

**Concurrency ↔ parallelism.** Many BEAM processes are concurrency, and on the BEAM they are cheap; many sockets are
parallelism against Valkey, and they are what raises throughput. `EchoMQ.Pool` turns process concurrency into wire
parallelism — N pipelined connectors dispatched round-robin by an atomic counter — and the `:metronome` pool path
keeps a fleet of consumers fed from one blocker instead of a herd.

In codemojex the scoring consumer `Codemojex.ScoreWorker` drains the `cm` guess queue through `Lanes.claim`. Running
more scoring processes does not score guesses faster if they share one connector; a pool of connectors does, because
it is the sockets — not the processes — that carry the round-trips. The number of guesses scored per second is set by
the pool width, the claim cadence, and the batch size, never by the count of worker processes alone.

> Sizing a real pool, recovering a stalled lease, and fanning consumers across a deployment is the queue's scaling
> layer, taught in the EchoMQ course.

**Notes on Valkey.** `BLPOP` blocks the connection it is issued on until an element is pushed to the key or the
timeout elapses — which is why a parking consumer holds a dedicated connector, and why a pool of consumers needs a
coordinator so one enqueue does not unblock every member at once — https://valkey.io/commands/blpop/.

## References

### Sources

- Valkey — *BLPOP* (https://valkey.io/commands/blpop/) — block the connection until an element is pushed; the park
  that holds a connector and the reason a pool needs a coordinator.
- Valkey — *Pipelining* (https://valkey.io/topics/pipelining/) — send commands without waiting for each reply; why a
  pipelined connector keeps several round-trips outstanding.
- Erlang/OTP — *erlang:atomics* (https://www.erlang.org/doc/man/atomics.html) — the lock-free atomic counter behind
  the pool's round-robin dispatch.

### Related in this course

- R6.05 · Worker concurrency (`/redis-patterns/flow-control/worker-concurrency`) — the module hub.
- R6.05.2 · The per-claim fetch bottleneck
  (`/redis-patterns/flow-control/worker-concurrency/the-per-claim-fetch-bottleneck`) — once the pool is wide, the
  per-claim fetch is the next ceiling.
- R6.05.3 · Capacity planning (`/redis-patterns/flow-control/worker-concurrency/capacity-planning`) — pool width and
  cadence as structural knobs.
- /echomq/queue — the consumer and pool wired into a production deployment.
- /bcs/bus — Part B3, the Valkey-native bus the connector serves.
