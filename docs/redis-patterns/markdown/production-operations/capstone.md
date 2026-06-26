# R8.07 · Capstone — the door to the EchoMQ course

> Route: `/redis-patterns/production-operations/capstone` · the **course capstone** (single page, no dives) ·
> the synthesis that recaps the journey R0→R8 and opens the door to the dedicated `/echomq` course.
>
> Grounding: the real surfaces the course taught, recapped as the through-line — the branded `JOB` id and the
> `emq:{q}:` keyspace (`echo/apps/echo_mq`); an atomic inline Lua move (`EchoMQ.Jobs.enqueue` / `claim`); fair lanes
> (`EchoMQ.Lanes.claim/3`); AOF durability (`infra/valkey/conf/valkey.conf` `appendfsync everysec`); the cluster
> slot (`EchoMQ.Keyspace.slot/1`, `slot("123456789") == 12739`); EchoStore (`echo/apps/echo_store`); the consumer
> `Codemojex.Guesses.submit/3` (`echo/apps/codemojex`). The branded-id conformance vectors anchor the through-line
> (`echo/apps/echo_data/lib/echo_data/branded_id.ex` `self_check!`):
> `placement("USR0KHTOWnGLuC") → 234878118`, `parse("USR0NgWEfAEJfs") → {:ok, "USR", 320636799581945856}`,
> `decode("USRzzzzzzzzzzz") → :error`. The `USR` namespace in those vectors is the verbatim manuscript figure
> (`bcs.0` / `bcs.2`); a codemojex example uses `PLR` / `ROM` / `GAM` / `GES` / `JOB`. Engine: Valkey 9. Doors:
> `/echomq` and its six pillars, `/bcs`, `/echo-persistence`.

A capstone is not a new pattern. It is the whole course read back as one line. Thirty Redis patterns, nine chapters,
and one consistent claim: a pattern is worth learning only when you can apply it. So this course taught each pattern
twice — the pattern (problem → solution → trade-off → when to use), and the concrete move it becomes in a real
system you can read on disk: **EchoMQ** backed by **Valkey**, **EchoStore** in front of it, and **codemojex** — the
Telegram code-breaking game — the worked consumer that drives the bus. This page recaps that arc, names the thread
that ran through all of it, and opens the door to the dedicated **EchoMQ, In Depth** course, where the system that
applies these patterns is taught in depth.

## The arc — nine chapters, thirty patterns

The course moved from a single key to a production tier, and each chapter landed its patterns on a real surface:

- **R0 · The catalog** — the thirty patterns mapped, and the one frame that holds them: a pattern is a problem, a
  solution, a trade-off, and a place it fits. Every later chapter is one row of that catalog, applied.
- **R1 · Caching** — read-heavy work served from memory: cache-aside, stampede control, client-side caching,
  sessions. The applied surface is **EchoStore** (`echo/apps/echo_store`) — the declared near-cache, L1 ETS over
  L2 Valkey, coherence by mint time.
- **R2 · Coordination** — making a multi-step change one step: atomic operations, locks, the fencing token, the
  inline Lua move that is one script because the keys share a slot.
- **R3 · Reliable queues** — work that survives a crash: the reliable-queue state machine, at-least-once delivery,
  the claim, the visibility lease, the retry with a fencing token. The applied surface is **`EchoMQ.Jobs`** — a
  branded `JOB` enqueued, claimed under a server-clock lease, completed or retried.
- **R4 · Time, delay & priority** — work scheduled for later or served in an order: the delay set, the priority
  queue, the scheduled job promoted when its time arrives.
- **R5 · Streams & events** — the ordered, replayable log: append-only events, consumer groups, the retained
  history a late reader can replay.
- **R6 · Flow control & scale** — keeping the queue stable under load: rate limiting, fair lanes, per-tenant
  groups, the batch path, worker concurrency. The applied surface is **`EchoMQ.Lanes`** worked through codemojex —
  each guess on the player's lane, drained by a rota.
- **R7 · Data modeling** — choosing the right structure for the access pattern: the primary-database trade, the
  encoding, the secondary index, the time series.
- **R8 · Production & operations** — running the tier as a system of record: the kernel settings, AOF durability,
  the connection pool, the reconnect discipline, cluster colocation, telemetry. The applied surface is the real
  `infra/valkey/conf/valkey.conf` and `EchoMQ.Pool` / `EchoMQ.Connector` / `EchoMQ.Keyspace` / `EchoMQ.Meter`.

Thirty patterns, each proven once in the real BCS build. None of it was invented for the page; every figure was
quoted from code or config you can open.

## The through-line — one branded id, carried unchanged

The course had a single thread, and it is worth naming on its own: the **branded id**. One 14-character name — a
3-character uppercase namespace and 11 Base62 characters carrying a 63-bit snowflake — minted once at the
consistent core and carried unchanged to the available periphery. It is what every chapter handled, under a
different aspect, and it has four properties:

- **Typed** — the namespace is on the wire and in the type. A `JOB` is a job, a `PLR` is a player, a `GES` is a
  guess. The brand is checked at every boundary, so a value cannot be used where it does not belong. This is the
  gated key the queue chapters relied on: `emq:{q}:job:<JOB>` is built from a branded `JOB`, and the key builder
  refuses anything else.
- **Ordered** — the text sorts as the mint instant. The id encodes a timestamp in its high bits, so the queue is
  mint-ordered without a separate sequence number. R3 and R4 leaned on this: a fair lane and a schedule set are
  both orderings of these ids.
- **Placed** — the id hashes to a fixed location. `EchoMQ.Keyspace.slot/1` computes the Valkey cluster slot
  client-side (`slot("123456789") == 12739`), and the queue's `{q}` hashtag forces every key of that queue onto
  one of 16384 slots. R2's atomic Lua and R8's cluster colocation both depend on that co-location — keys that
  share a slot can change in one script with no `CROSSSLOT` error.
- **Conformant** — one canon across Elixir, Node, Go, PostgreSQL, and WASM. Every runtime mints, parses, and places
  the same id and computes the same placement. The runtime asserts this at boot — these are source truths, not
  measurements:

```
placement("USR0KHTOWnGLuC")  →  234878118              (the placed property — native and pure agree)
parse("USR0NgWEfAEJfs")      →  {:ok, "USR", 320636799581945856}
decode("USRzzzzzzzzzzz")     →  :error                 (an overflow is refused, not wrapped)
```

That fourth property is what makes a polyglot worker fleet possible: if every runtime agrees on the id and its
placement, a Go worker and an Elixir worker can drain the same bus. The `USR` namespace in those vectors is the
manuscript's illustrative figure; a codemojex example uses the live brands `PLR` / `ROM` / `GAM` / `GES` / `JOB`.

## What you can now do

The course's outcomes, stated plainly. After these thirty patterns you can:

- **Choose the right pattern and name its failure mode.** Cache-aside risks staleness; at-least-once delivery risks
  a duplicate; a fixed-window limiter risks a burst at the boundary. Knowing the trade is the skill — the pattern
  is the easy half.
- **Read a real atomic Lua move and say why the multi-key change is one script.** The keys share a slot (the `{q}`
  hashtag), so the change is atomic and `CROSSSLOT`-safe — one `EVAL`, not a transaction that can interleave.
- **Build a reliable, scheduled, observable, rate-limited queue.** The claim-with-lease, the retry with a fencing
  token, the delay set, the telemetry tree, the token bucket — each is a pattern you saw applied, and
  `Codemojex.Guesses.submit/3` is the worked consumer that composes them.
- **Operate the tier as a system of record.** AOF durability (`appendfsync everysec` bounds worst-case loss to
  about a second), a connection pool sized for round-trip-hiding rather than cores, a reconnect discipline that
  fails in-flight callers rather than replay them, cluster colocation by hashtag, and a telemetry surface a
  Prometheus or OpenTelemetry exporter can read.

## The door — `/echomq`, the system that applies them

Redis Patterns Applied taught the **patterns**. The dedicated **EchoMQ, In Depth** course teaches the **system
that applies them**, in depth, across its six pillars — all built:

- **`/echomq/overview`** — the one bus, the three roles, the owned wire.
- **`/echomq/protocol`** — the `emq:{q}:` keyspace, the Lua layer, immutability and branded ids.
- **`/echomq/queue`** — distribute work: jobs, lanes, the claim, retry, the schedule set, flow control.
- **`/echomq/bus`** — broadcast signals and a retained, replayable event log.
- **`/echomq/cache`** — serve reads from the near-cache, coherent by mint time.
- **`/echomq/proof`** — conformance, telemetry, and the measurement plane that proves the contract.

That is the natural next course: every Redis pattern here is one move the EchoMQ protocol makes, and the protocol
governs all of them at once. The polyglot fleet — the same bus drained by workers in several runtimes — is the
conformance target the protocol and the branded-id contract make reachable, and the **Proof** pillar is where that
target is demonstrated.

## The wider doors

Two more courses sit underneath this one:

- **`/bcs` · The Branded Component System** — the architecture the whole stack is built to. The branded id is the
  thread of this capstone because BCS makes it the thread of the system: an entity is a branded identity, a
  component is data, a system is a process that gates every ingress on its brand. EchoMQ and EchoStore are systems
  built to that law over the wire.
- **`/echo-persistence` · The durability floor** — the dial beneath the bus. R8 named AOF as the engine-level
  durability dial; `/echo-persistence` is the tier below it: a durable local page engine and a portable remote, the
  full ladder from holding nothing to commit-per-record replicated off-box.

The course ends here, at the door. The patterns are yours; the system that applies them is one click forward.

## References

### Sources

- [Valkey — *Cluster specification*](https://valkey.io/topics/cluster-spec/) — the `{q}` hashtag forces a queue's
  keys onto one of 16384 slots, the placement property that makes the atomic Lua move and cluster colocation legal.
- [Valkey — *Append-only file*](https://valkey.io/topics/persistence/) — AOF as the single source of durability;
  `appendfsync everysec` bounds worst-case loss to about a second, the production durability dial R8 grounded.
- [Valkey — *EVAL*](https://valkey.io/commands/eval/) — the scripting primitive behind every atomic multi-key move
  in the course; one script, declared keys, no interleave.
- [Redis — *Redis patterns*](https://redis.io/docs/latest/develop/use/patterns/) — the pattern catalog the course
  is built on, each entry taught here applied to a real system.
- [llms.txt convention](https://llmstxt.org/) — the route-mirrored markdown this course keeps beside every page,
  one source of record per route.

### Related in this course

- [R0 · The pattern catalog](/redis-patterns/overview) — the thirty patterns and the frame that holds them.
- [R1 · Caching](/redis-patterns/caching) — read-heavy work served from EchoStore.
- [R3 · Reliable queues](/redis-patterns/queues) — work that survives a crash, the `EchoMQ.Jobs` state machine.
- [R6 · Flow control & scale](/redis-patterns/flow-control) — keeping the queue stable under load.
- [R8 · Production & operations](/redis-patterns/production-operations) — running the tier as a system of record.
- [EchoMQ, In Depth](/echomq) — the dedicated course: the system that applies every pattern here.
- [EchoMQ · Proof](/echomq/proof) — conformance and the measurement plane; the polyglot-fleet target realized.
- [The Branded Component System](/bcs) — the architecture law the whole stack is built to.
- [The durability floor](/echo-persistence) — the dial beneath the bus.
