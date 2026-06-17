# The Art of Identity as a contract. Meet BCS.

## The Branded Component System — Table of Contents

<show-structure depth="2"/>

The reading order of the series. The historical case opens it ([`bcs.preface.md`](bcs.preface.md)); each part begins with its own preface carrying the part's design guidelines; every chapter is a foundational article in its own right, closes with a References section, and — where it narrates built work — quotes only committed outputs. The practical project threaded through the applied parts is a trading system: an external API feeding transactions and assets, portfolio and risk management as BCS systems, and trading strategies built on the decider pattern rethought over branded identities. Status, decisions of record, and follow-ups live in [`bcs.progress.md`](bcs.progress.md), not here.

## Part I. Ideas Behind

The conceptual floor — the law, the identity contract, the storage economics, and what distribution changes. Part preface: [`bcs1.md`](bcs1.md).

**Chapter 1.1. The System Substrate** — [`bcs1.1.md`](bcs1.1.md)
The law of Part I made executable in the smallest faithful form: a boundary gate, a property store that owns its table outright, a supervisor — built and transcript-proven in Elixir, designed in Go as the owner-goroutine counterpart. Six gates refuse the architecture's canonical crimes on stage, and the one correction the platform forced sharpens the first clause: the BEAM guards data, not existence.

**Chapter 1.2. The Identity Contract, Read as Architecture** — [`bcs1.2.md`](bcs1.2.md)
A guided reading of the normative contract, property by property: the namespace as a discriminant carried in the value and in the type, the order theorem as chronology without a clock, hash32 as placement any holder can compute, and the canon as the reason "which language" is a deployment detail. Each property is read against the failure it retires.

**Chapter 1.3. Choosing the ID System** — [`bcs1.3.md`](bcs1.3.md)
The decision record, measured: Valkey 8.1's open-addressing, cache-line-bucket hash table is read from its primary source, derived to a cost model, and then made to weigh seven key shapes across two engines at a million keys each. The branded form ties binary UUID-16, beats its own decimal rendering, and undercuts canonical UUID-36 by thirty-two bytes a key — and the streams experiment extends the contract into entry ids at zero cost per entry.

**Chapter 1.4. From ECS to BCS** — [`bcs1.4.md`](bcs1.4.md)
What distribution changes. The game-engine entity id — a process-local integer, the weakest value in the program — fails at the first save file, the first socket, and the first foreign store; the chapter traces each failure to a missing contract property and states what the branded id does about it, closing the historical arc the series preface opened.

**Chapter 1.5. The Time Inside the Name** — [`bcs1.5.md`](bcs1.5.md)
Time taken as the subject after four chapters of leaning on it: the 41-bit arithmetic and its recorded September-2093 horizon, the law of two clocks on Lamport's foundation — identity time is the id's, event time is data — the monotonic mint floor as policy of record for backwards wall clocks, windows as synthetic cursors in both runtimes, and the store's TTL as a third clock deliberately unmerged. The line Part VIII cites instead of re-arguing.

**Appendix 1.1. Branding Beats Its Own Integer** — [`bcs1.a1.md`](bcs1.a1.md)
The chapter's sharpest storage finding given its CPU trial: the encode path measured against the decimal rendering in all five runtimes of the canon, on the real implementations. The compiled runtimes agree emphatically (Rust 4.2x, C 2.8x), Go splits on allocation regime, the BEAM calls it a tie, and V8 records the one loss — in exactly the place the contract prescribes the wasm crossing. The whole-system accounting closes it: a brand is minted once and cheaper forever after.

## Part II. The Elixir BCS Core

The reference implementation of a system: an OTP application owning its property stores behind a supervised boundary, with the trading domain as the working vocabulary. Part preface: [`bcs2.md`](bcs2.md).

**Chapter 2.1. A System Is an OTP Application** — [`bcs2.1.md`](bcs2.1.md)
Boundary, supervision tree, ownership — the full treatment the substrate chapter previewed. Pure cores shelled by GenServers; what a system exports (functions over identities) and what it never exports (its tables); restart semantics as an architectural statement rather than an accident.

**Chapter 2.2. Property Stores on ETS** — [`bcs2.2.md`](bcs2.2.md)
Positions, balances, and instrument state as system-owned tables — the measured store families re-read as the property database, with the branded id as the only key and chronology as a property of the keyspace rather than a column.

**Chapter 2.3. The CHAMP Property Database** — [`bcs2.3.md`](bcs2.3.md)
The persistent-structure store: structural sharing as the snapshot mechanism, the contract hash as the trie's placement function, and where a CHAMP forest beats an ETS table — and where it does not.

**Chapter 2.4. Archetypes and Composition** — [`bcs2.4.md`](bcs2.4.md)
Property inheritance as data — the Looking Glass move in Elixir. Instrument archetypes (an equity, a future, an option) as bundles of property values; per-instrument overrides; the composite instrument without a class diamond.

**Chapter 2.5. Relations Are Systems** — [`bcs2.5.md`](bcs2.5.md)
The edges store as a system of its own: portfolio-holds-asset, order-fills-against-order, strategy-watches-instrument — tuple-keyed relations with paged traversal, never embedded in either endpoint.

**Chapter 2.6. Gates and Acceleration at the Boundary** — [`bcs2.6.md`](bcs2.6.md)
Every ingress gated by namespace; the Ecto parameterized type as the deferred persistence adapter; the canon NIF and the measured line where native pays on the BEAM.

## Part III. EchoMQ (Valkey-Native)

The bus on which identities and messages about identities travel between systems — owned wire, declared keys, fair lanes — backed by Valkey through the custom Elixir connector.

**Preface** — [`bcs3.md`](bcs3.md): the bus over the identity and memory layers; one transition, one script; the fence before the first command; jobs as entities; park-don't-poll with constructed fairness; named delivery semantics; rivals measured with their advantages printed.

## Part III — EchoMQ: the Valkey-native bus

**Preface** — [`bcs3.md`](bcs3.md): the bus over the identity and memory layers; one transition, one script; the fence before the first command; jobs as entities; park-don't-poll with constructed fairness; named delivery semantics; rivals measured with their advantages printed.

**Chapter 3.1. The Fence and the Keyspace** — [`bcs3.1.md`](bcs3.1.md): the connector substrate as the part's vocabulary: RESP discipline, the boot fence as queue-grade gating, every key shape, the slot function in reserve.

**Chapter 3.2. Jobs Are Entities** — [`bcs3.2.md`](bcs3.2.md): `JOB` registered under the D-8 bar; the job row; enqueue as one idempotent script; newest-first browsing as the order theorem's dividend.

**Chapter 3.3. The State Machine in Lua** — [`bcs3.3.md`](bcs3.3.md): claim, complete, retry, dead-letter as single-script transitions; the two-clocks law on the bus.

**Chapter 3.4. Fair Lanes** — [`bcs3.4.md`](bcs3.4.md): per-group concurrency and pause/resume; park-don't-poll; round-robin construction with a starvation refusal as a gate.

**Chapter 3.5. The Bus Meets the Stores** — [`bcs3.5.md`](bcs3.5.md): commands out of entities, results back into properties, ids the only cargo; the consumer as one more owner.

**Chapter 3.6. Conformance and the Rival's Numbers** — [`bcs3.6.md`](bcs3.6.md): the referee habit, the committed harness, and the transactional-enqueue rival with its advantage in its own row.

## Appendix A. The Connector — EchoMQ 2.0 on Valkey

[The Connector — EchoMQ 2.0 on Valkey**](bcsA.md)

Purpose-built Elixir client on raw `:gen_tcp` and a one-pass RESP2 codec — pipelining as the primitive, EVALSHA-first declared-keys scripts, the `echomq:2.0.0` fence typed and fatal, the keyspace composing with the identity canon, and slots computed client-side. Eight gates against the live 8.1.8: 454,483 pipelined ops/s over 29,456 sequential, exactly one NOSCRIPT load, ordered ten-thousand-reply pipelines, supervised restart re-fencing. The reference implementation the umbrella adopts.

## Appendix B — The production connector

[`bcsB.md`](bcsB.md): the connector rewritten production grade and re-certified by the appendix's own rung — authenticated boot ahead of the fence, bounded in-flight with typed overload, FIFO alignment under caller timeout, the heartbeat and the server-death drill, fail-never-replay, graceful shutdown, and the pool whose case is isolation: blocking verbs get their own lane; RESP3 negotiated whole — HELLO, out-of-band pushes, protocol 2 on demand. Specification: [`bcsB.specs.md`](bcsB.specs.md) — fourteen invariants, the certified ladder, conformance for ports, the F1–F8 future ladder.

## Part IV. EchoCache

The near-cache the comparison set does not ship: branded keys, local speed, bus-driven coherence.

**Chapter 4.1. Cache-Aside at ETS Speed** — declared L1 tables over L2 Valkey, single-flight fills, jittered TTL, and the sweeper — quote and reference-data caches that survive the thundering herd with one fill.

**Chapter 4.2. Coherence by Mint Time** — snowflake-versioned newer-wins invalidation over the bus — coherence without coordination — and the guaranteed job-backed path when at-least-once matters more than latency.

**Chapter 4.3. The Single Writer and the Ring** — coherence application as one owner draining an ordered ring: batched apply, occupancy as backpressure, and the storm drill; LMAX and the Disruptor read as prior art standing beside park-don't-poll.

**Chapter 4.4. The Lane That Remembers** — per-group SQLite journals under the consumers carrying provenance, checkpoints, and the last-applied version, streamed off-box by Litestream; the node-death drill: restore, replay into a warm L1, resume the lanes — the bus stays WAL-free by D-2.

**Chapter 4.5. The Cache Referee** — Nebulex's near-cache topology, Cachex, and Valkey's server-assisted tracking measured where they run: hit-path latency, the herd drill, and coherence-lag distributions, with the rows the comparison set cannot print — typed keys, mint-ordered newer-wins, a job-backed lane — beside the rows it wins.

## Part V. Go

The runtime that proves the canon needs no linking.

**Chapter 5.1. The Pure-Go Contract**
Native u64 arithmetic, the measured case against crossing into C, and the conformance suite as the only coupling to the canon.

**Chapter 5.2. Go Systems on the Bus**
The Go port speaking v2 natively: a market-data ingest system as a full BCS citizen — owner goroutines for stores, declared keys on the wire, namespace gates at every channel edge, placement parity with the BEAM.

## Part VI. Node 22+

The runtime where the type system carries the discriminant and Rust pays its way through V8.

**Chapter 6.1. The Brand in the Type System**
`BrandedId<NS>` and the compile error as the gate; Fastify schemas as the system boundary in HTTP clothing — the wrong-namespace request refused before any handler runs.

**Chapter 6.2. Rust on V8**
The wasm-backed codec from the canon crate, and the boundary principle measured: where BigInt loses and the crossing wins.

**Chapter 6.3. echomq-node**
The native v2 Node implementation joining the fleet — workers as systems, the brand at every queue boundary, and the external trading API's edge runtime as the consumer story.

## Part VII. Production on Fly

The architecture deployed: machines, replicas, ephemeral execution, and the operational surface.

**Chapter 7.1. Topology**
App machines and the dedicated Valkey machine for EchoMQ; private networking; who talks to whom and on which names.

**Chapter 7.2. The Local Replica**
Read posture and failover drills for the queue's store — what the cluster chapter's wire semantics buy at the infrastructure layer.

**Chapter 7.3. FLAME: Ephemeral Job Execution**
Phoenix FLAME machine pools for job execution — configuration, pool sizing, cold-start economics, and the identity contract crossing into machines that exist for one job.

**Chapter 7.4. Observability and Release**
Telemetry from every system to one surface; deploys, runbooks, and the conformance suite as the release gate.

## Part VIII. The Trading System

The practical project, assembled: the parts above composed into a running trading platform.

**Chapter 8.1. The Domain and Its Namespaces**
The trading vocabulary as a namespace registry — `AST` assets, `TXN` transactions, `PRT` portfolios, `ORD` orders, `RSK` risk envelopes, `STR` strategies — and the system map those names imply: which system owns which table, and which identities each boundary admits.

**Chapter 8.2. The External API Boundary**
Transactions and assets arriving from the external API as the architecture's edge case study: gates at ingestion, idempotency from branded identity, and the translation between foreign keys and minted names done exactly once.

**Chapter 8.3. Portfolio and Risk as Systems**
Portfolio state and risk envelopes as property stores with bus-fed inputs: positions as a timeline by construction, exposure recomputed from messages about identities, and the reach-through that classic risk engines commit refused by the boundary.

**Chapter 8.4. Strategies: The Decider, Rethought**
Jérémie Chassaing's decider — `decide: Command -> State -> Event list`, `evolve: State -> Event -> State`, an initial state, a terminal predicate — re-grounded in BCS: commands and events become messages about branded identities, the decider's state becomes a system's own table, event streams become branded stream entries with replay windows from the order theorem, and strategies compose as `STR`-keyed deciders supervised like any other system.

## Appendix A. The Connector — EchoMQ 2.0 on Valkey

**Appendix A. The Connector — EchoMQ 2.0 on Valkey** — [`bcsA.md`](bcsA.md)
Decision D-1 made flesh: a purpose-built Elixir client on raw `:gen_tcp` and a one-pass RESP2 codec — pipelining as the primitive, EVALSHA-first declared-keys scripts, the `echomq:2.0.0` fence typed and fatal, the keyspace composing with the identity canon, and slots computed client-side. Eight gates against the live 8.1.8: 454,483 pipelined ops/s over 29,456 sequential, exactly one NOSCRIPT load, ordered ten-thousand-reply pipelines, supervised restart re-fencing. The reference implementation the umbrella adopts.


## Appendix B — The production connector

[`bcsB.md`](bcsB.md): the connector rewritten production grade and re-certified by the appendix's own rung — authenticated boot ahead of the fence, bounded in-flight with typed overload, FIFO alignment under caller timeout, the heartbeat and the server-death drill, fail-never-replay, graceful shutdown, and the pool whose case is isolation: blocking verbs get their own lane; RESP3 negotiated whole — HELLO, out-of-band pushes, protocol 2 on demand. Specification: [`bcsB.specs.md`](bcsB.specs.md) — fourteen invariants, the certified ladder, conformance for ports, the F1–F8 future ladder.