# Valkey: Leveraging Multi-Threading from the BEAM

This chapter maps Valkey 8 and 9's asynchronous I/O threading onto Elixir clients, derives the inverted advice, and covers the two capabilities Valkey has: full RESP3 push semantics with client tracking, and the WAIT durability lever.

## What the server parallelizes, and what it does not

In Valkey, command execution remains on the main thread; the I/O threads introduced in 8.0 and redesigned in 9.1 offload socket reads, protocol parsing, and response writes, running concurrently with execution and handing the main thread batches of pre-parsed commands [1][2]. Batching is the heart of it: when commands arrive in groups, the engine prefetches the dictionary entries they will touch before executing them, so DRAM latency hides behind work instead of stalling it [2]. Valkey 9.1's reworked thread-communication model carries a single server to 2.1 million RPS, measured with nine I/O threads and a pipeline depth of ten [3].

Read that benchmark configuration as client guidance, because it is one. The headline number assumes pipelined traffic; the prefetcher and the batch handoff are fed by commands arriving in groups. A client that sends one command per round trip starves the machinery that makes Valkey 9 fast.

## The inverted tuning rule

Valkey execution capacity is the main thread regardless of connection count, so adding connections does not add execution parallelism; it adds I/O distribution, which the I/O threads already provide across a modest connection set. The dial that matters is pipeline depth per connection.

The practical shape for an Elixir application:

- A small fixed EchoWire pool, a handful of connections rather than a per-core fleet, routed by `hash32` of the branded ID exactly as before; the routing buys per-entity ordering, and that rationale is engine-independent.
- Aggressive use of `EchoWire.pipeline/2` on the throughput path. Pipelining is the primary performance tool: batched enqueues, batched acknowledgments, batched cache fills. The mastery comes from natural language native pipelining in Elixir.
- Dedicated connections for blocking commands, unchanged. A parked BLMOVE occupies its connection on any engine, so consumer lanes hold their own connections outside the pool on Valkey.

The pleasant corollary: a BEAM application tuned with large pool, hashtag-disciplined keys, deep pipelines, isolated blocking lanes runs well on Valkey without retuning.

## Hashtags without the lock semantics

The `emq:{q}:<type>` keyspace on standalone Valkey the braces are inert, all keys live in one execution domain, and on Valkey cluster they become load-bearing again: every key of a queue maps to one slot, so multi-key Lua over a queue's keys is legal cluster-wide. The discipline costs nothing where it is not needed and pays exactly where it is. 
On a single Valkey node they serialize on the main thread. Cross-queue fairness therefore comes from the protocol's group lanes, never from engine concurrency, which is the correct dependency direction anyway.

## RESP3 push and client tracking

Valkey inherits and maintains the full RESP3 surface of its lineage: HELLO 3, out-of-band push frames, and CLIENT TRACKING, including broadcast mode with prefix filters. For an EchoCache deployment this is a capability that Chapter 2 of that series steered invalidation away from server notifications entirely. On Valkey, a tracking connection subscribed in broadcast mode to the cache prefixes receives invalidation pushes when any client writes those keys, no polling and no separate pub/sub fan-out.

It's worth stating that the capability does not soften: pushes are hints, Snowflake-versioned newer-wins remains the guarantee. Tracking connections drop, pushes are fire-and-forget, and a reconnect window silently loses invalidations. The correct integration is a third lane beside command and blocking lanes, a push lane, whose messages accelerate convergence that version comparison already guarantees. Mainstream Elixir client support for RESP3 push frames is thin enough that this lane is one of the motivations for the custom connection in Chapter 4.

## WAIT as a checkpoint lever

Valkey retains WAIT: block until the preceding writes are acknowledged by N replicas, with a timeout. For the lifecycle rung's crash-survivable checkpoints, this converts replication from a background hope into a per-checkpoint decision, a checkpoint write can demand one replica acknowledgment before the worker proceeds, bounding loss to the AOF fsync window on two machines rather than one. It is a latency-priced option, not a default; the point is that the option exists on this engine, and the transport should expose it rather than bury it.

## Measuring from the BEAM side

Valkey 9 server benchmarked at depth one will look unremarkable and the conclusion will be wrong. Measure with the pipeline shaping the application will use, watch `INFO stats` for the instantaneous ops rate against the I/O thread count, and confirm the blocking lanes are isolated, the failure mode of a parked command starving a pooled connection is engine-independent and remains the most common self-inflicted wound. The deployment surface for all of this is the next chapter.

## References

1. https://valkey.io/blog/valkey-8-0-0-rc1/
2. https://valkey.io/blog/unlock-one-million-rps/
3. https://valkey.io/blog/valkey-9-1-delivers-improvements-in-security-performance-and-more/
