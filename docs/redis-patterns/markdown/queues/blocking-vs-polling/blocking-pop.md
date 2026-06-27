# Blocking pop — park the connection, wake on arrival

> Route: `/redis-patterns/queues/blocking-vs-polling/blocking-pop` · Dive R3.05.2 · Module R3.05 blocking-vs-polling
> · Chapter R3 Reliable Queues.
> Grounding: the source's `Blocking Variant`. EchoMQ's consumer parks on a blocking pop — `EchoMQ.Consumer.park/1`
> runs `BLPOP emq:{queue}:wake <beat>` — on a dedicated connector lane (the consumer's moduledoc: "a dedicated
> connector — blocking verbs get their own lane"), so the lane that drains and settles jobs stays free. All real in
> `echo/apps/echo_mq/lib/echo_mq/consumer.ex`.

A blocking pop removes the poll interval and the wasted round-trips at once. The worker parks on the server and the
call does not return until an element is available or the timeout elapses — so a job is picked up the moment it
arrives, and an idle queue costs no traffic at all.

## The blocking primitives

The source's reliable-queue loop replaces its pop/sleep spin with a blocking move:

```
BLMOVE work_queue processing:worker1 RIGHT LEFT 30
```

`BLMOVE` atomically moves an element from the work list to the processing list, parking the connection for up to thirty
seconds if the work list is empty. `BRPOPLPUSH` is the older form of the same move. `BLPOP` is the simplest blocking
pop: it removes and returns the first element of a list, parking until one is pushed or the timeout fires. All three
share the property that matters: **no poll interval and no empty round-trips** — the call returns the instant there is
work, or once on the timeout.

## The cost is the connection

A blocking call occupies its connection for the whole park. A command sent on the **same** connection waits behind the
block, so a worker that parks on its only connection cannot also fetch or acknowledge. The discipline is a
**dedicated** connection for the block:

- the blocking connection parks on the wake key and does nothing else;
- the command connection drains the ring, runs the claim, and settles the job;
- the two never contend, so a long park never stalls a fetch.

EchoMQ encodes this in the consumer: it holds "a dedicated connector — blocking verbs get their own lane," and the
park rides that lane while the drain rides the command lane.

## The park, in EchoMQ

The consumer's loop is reap → promote → drain → park, repeating. The park is one blocking call with the beat as its
timeout:

```elixir
# EchoMQ.Consumer.park/1 — park on the wake key for one beat, then loop (real, Elixir)
defp park(s) do
  secs = :erlang.float_to_binary(s.beat_ms / 1000, decimals: 3)
  wake = Keyspace.queue_key(s.queue, "wake")          # emq:{queue}:wake
  _ = Connector.command(s.conn, ["BLPOP", wake, secs], s.beat_ms + 2_000)
  :ok
end
```

The `BLPOP` returns one of two ways: a wake token was pushed (work was admitted — drain it), or the beat elapsed (run
the reap/promote pump, then park again). Either way the connection spent the idle time parked, not polling. The beat
(`:beat_ms`, default 1000) is the timeout, so the loop always re-runs its pump within one beat and is never parked
forever; the lease the claim holds is bounded by `:lease_ms` (default 30 000).

## The bridge

**The pattern:** a blocking pop with a timeout parks the connection until work arrives — no interval, no wasted
round-trips — at the cost of a tied-up connection, which a dedicated connection keeps off the working one.

**Its EchoMQ application:** `EchoMQ.Consumer.park/1` runs `BLPOP emq:{queue}:wake <beat>` on a dedicated connector
lane; the command lane stays free to claim and settle. The beat bounds the park; a wake returns it early. The next
dive walks the wake handshake that rings the doorbell.

## On Valkey

`BLPOP` is "the blocking variant of LPOP": when the list is empty it parks the client until another client pushes an
element, or the timeout elapses; the engine serves exactly one of several blocked clients per push, in park order
(valkey.io/commands/blpop). A blocking call is the reason a worker keeps a separate connection for it.

## References

### Sources

- [Valkey — BLPOP](https://valkey.io/commands/blpop/) — block until an element is pushed to a list; the park EchoMQ's consumer makes.
- [Redis — BLMOVE](https://redis.io/commands/blmove/) — the modern blocking reliable-queue pop the source uses.
- [Redis — BRPOPLPUSH](https://redis.io/commands/brpoplpush/) — the older blocking reliable-queue pop, the move BLMOVE replaces.
- [Redis — Documentation](https://redis.io/docs/) — blocking commands and why each blocking call wants its own connection.

### Related in this course

- [R3.05 · Blocking vs polling](/redis-patterns/queues/blocking-vs-polling) — the module hub.
- [R3.05.1 · The busy-poll cost](/redis-patterns/queues/blocking-vs-polling/the-busy-poll-cost) — the previous dive: the cost this removes.
- [R3.05.3 · The wake-up doorbell](/redis-patterns/queues/blocking-vs-polling/the-marker-wake-up) — the next dive: ringing the wake key.
- [R3 · Reliable Queues](/redis-patterns/queues) — the chapter.
- [/echomq/queue](/echomq/queue) — the Queue pillar: the dedicated connector lane in depth.
