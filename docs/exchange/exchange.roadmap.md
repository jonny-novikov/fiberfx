# TRD · Roadmap — the delivery ladder

<show-structure depth="2"/>

Status: **PROPOSED — awaiting Operator selection of the entry rung; TRD.1 is the natural start.** This is the delivery
view of the platform fronted by [`exchange.md`](exchange.md) and specified in [`exchange.specs.md`](exchange.specs.md);
the patterns under the hot path are argued in [`exchange.patterns.md`](exchange.patterns.md). One shippable,
demonstrable increment per rung; every dependency recorded here, none discovered mid-rung.

## Where this starts

The as-built inventory the first rung stands on, every line a committed record: the wire (`EchoMQ.Connector` over
`EchoWire`, refereed in Appendix H), the work queue (`EchoMQ.Jobs` / `Lanes` / `Consumer` — fair per-venue lanes,
Chapter 3.4; the three-way referee, Appendix E), the cache (`EchoCache.Table` and `Coherence`, Chapters 4.1–4.2; the
referee, 4.5), the buffer (`EchoCache.Ring`, Chapter 4.3 — bounded publish, counted drops, one drainer), the event
store (`EchoCache.Journal`, Chapter 4.4 — append, dedup, fold-to-state replay) under a pluggable shadow
(`EchoCache.Shadow` with the Litestream and Copy implementations — Appendix D and the shadow rung), the canon
(`EchoData.*` — ids, Snowflake, BrandedTree, the CHAMP family; Appendix F), and the SQL canon for Postgres
(`src/postgres`). No `Exchange.*` module exists yet — that is this ladder.

## Where this ends

After C: instruments partitioned across BEAM nodes, each book a single-writer process placed by a consistent ring over
the audited hash; every fill an immutable event on a per-instrument stream lane that projections and polyglot
consumers replay; settlement and risk as EchoMQ work in fair per-venue lanes; positions read through Tables at hit
speed; the regulated ledger double-entry in Postgres; the whole thing one deployable that scales by adding BEAM nodes
and shards.

## The master invariant (held at every rung)

> One instrument's book is mutated by exactly one process — the sole drainer of that instrument's Ring — and its state
> is reconstructable as a fold over an append-only event log. Sequence is mint order. Every primitive keeps its role:
> the queue is never a log, the log is never a fan-out bus, the bus never carries an object. Nothing on a hot path
> runs heavier than regular-scheduler work. Every id is branded and refused at the wrong door.

The full statement and its mechanics live in [`exchange.specs.md`](exchange.specs.md).

## Milestones

| Milestone | Rungs | What you can do at the end |
|---|---|---|
| A · the walking skeleton | TRD.1–TRD.5 | submit an order through the gateway; watch it match in a Ring-fed single-writer book; replay the book from its Journal; see the fill post double-entry and a settlement job drain a fair lane; read a position at hit speed; watch market data arrive as claims |
| B · the durable core | TRD.6 | replay any instrument's state from a per-instrument stream lane; attach a non-BEAM risk consumer through a consumer group and watch re-delivery on its crash |
| C · the scale-out | TRD.7–TRD.8 | run books partitioned across a BEAM cluster placed by the audited hash; kill a node and watch a book hand off under the CP rule; flood one venue and watch the others hold cluster-wide |

## The rungs

| Rung | Ships (all PROPOSED) | Stands on (as-built) | Demo | Gate sketch | Feedback asked |
|---|---|---|---|---|---|
| TRD.1 | `Exchange.Gateway`: parse once into typed commands, closed error set, ids minted at the edge | the canon, the kind law | post a valid and an invalid order; one accepted, one refused with a typed error | boundary-parse property; wrong-kind refused at the door | the command set v1 — limit, market, cancel only? |
| TRD.2 | `Exchange.Book` as Ring drainer + `Exchange.OrderBook` + `Exchange.Decider` (pure, events out) | Ring (4.3), BrandedTree | two crossing orders match; the fill events print; a flood answers `:dropped` instead of queueing silently | price-time property; single-writer reconcile — publishes equal applies plus counted drops; crossing → fills | matching edge cases — self-trade, partial fills |
| TRD.3 | the book's Journal + Shadow wiring; fills post via one `Ecto.Multi`; settlement on a venue lane | Journal (4.4), Shadow (D, the shadow rung), Lanes (3.4), the SQL canon | kill the book, restart, replay equals live; a fill posts atomically and a settlement job drains | replay == live state per book; all-or-nothing posting; lane round trip | settlement trigger — per-fill or batched |
| TRD.4 | market data as claims: fills and deltas broadcast, term-cached resolve | Coherence (4.2), the Appendix G term-cache pattern | a subscriber sees a delta as a 29-byte claim and resolves it warm | claims-only sweep on every bus payload; staleness law re-gated on book data | delta granularity — per-fill or level-aggregated |
| TRD.5 | projections (book snapshot, positions) consuming the log idempotently into Tables | Journal replay, Table (4.1) | crash a projection, rebuild from the log, read the position at hit speed | crash-and-rebuild == live; idempotency under re-delivery; hit-class read | which projections first; snapshot cadence |
| TRD.6 | the log moves to stream lanes; risk as a consumer group; the polyglot seam documented | **conn.1–conn.2 of `bcsH.specs.md` — the recorded dependency**; Keyspace tags | a Go or Python consumer reads the same stream, acks, crashes, and is re-delivered | at-least-once with idempotent handlers; replay parity with TRD.3's journal | retention — MAXLEN cap or MINID by the compliance window |
| TRD.7 | `Exchange.Placement`: a consistent ring over `hash32`; books placed per node; handoff drill | the audited hash (`bcs_hash_audit.out`), the CP/AP table fixed here | three nodes; orders route to the owner; kill a node, the book hands off, matching refuses during the gap | placement determinism; handoff drill; CP refusal on owner loss | the placement strategy's virtual-node count |
| TRD.8 | cluster sharding by hash tag; cross-venue fairness at cluster scale; the cross-shard saga rule named | Keyspace, Lanes | shard books across slots; flood one venue; the others hold | single-slot property per book's keys; flooded-venue fairness re-gated cluster-wide | CP/AP per subsystem on partition; reshard runbook |
| TRD.9 | **investex** — the BEAM-native Tinkoff Invest client (`echo/apps/investex`, `Investex.*`): 10 gRPC services / 72 RPCs, one function per RPC, supervised streams, `{units, nano}` money, the branded `ORD` seam; decomposed 9.1–9.5 | the `echo_data` canon (in-umbrella), the committed Tinkoff Invest contracts | place a venue order from the BEAM with a branded `ORD` id; read accounts/instruments/operations; a self-resubscribing market-data stream; the sandbox round trip | parity check (72 RPCs mapped); integer-money property; pure retry-decision unit tests; keyless sandbox suite skips | the environment cutover (sandbox vs production); the retry posture |

> **The investex subsystem (TRD.9).** TRD.9 founds the BEAM-native venue client — the Elixir-side equivalent of the
> Go SDK's venue-client seat. It is **adjacent to** the *Go worker tier* (the cross-cutting external processor named
> below the milestones in [`trd.progress.md`](trd.progress.md)): the Go tier keeps the GPU-accelerated money-math; the
> BEAM gets a first-class venue client so venue I/O is supervised, branded, and never blocked on the Go fleet. Both
> speak the same `{units, nano}` integer money and the same branded `ORD` id (the venue idempotency key). TRD.9's
> build rungs (9.1–9.5) are HIGH risk — real network, a live secret, auth — and each warrants a dedicated Apollo and
> the secret-hygiene gate. The chapter quad is [`trd.9.md`](trd.9.md) and its `.specs`/`.stories`/`.llms`.

## Dependencies, recorded

TRD.6 gates on the connector's stream rungs (conn.1 verbs, conn.2 partitioned lanes) — sequenced with the connector
specification, not assumed. TRD.7 gates on the Placement primitive, authored at its own rung. Batched settlement and
scheduled jobs trace to the EchoMQ roadmap's 2.1 row; this platform's needs are recorded there as an input. The
walking skeleton (A) has no unbuilt dependency: every component it stands on carries a committed record today. TRD.9
(investex) stands on the as-built `echo_data` canon (in-umbrella) and the committed Tinkoff Invest contracts — no
unbuilt dependency for its spec; its build rungs add the new hex deps `{:grpc, …}` + `{:protobuf, …}` (the HTTP/2
stack the Mint adapter rides is already locked) and depend on the as-built `echo_data` branded-id surface.

## How delivery runs

The AAW loop in [`exchange.md`](exchange.md): the Operator selects and reviews, the Author ships spec-first increments;
sharpen → build → ship → demo → review → feedback → adapt, with feedback editing the spec. Each rung lands as a
PR-sized increment — the spec, the slice, a green harness, a demo, and a committed record whose numbers are the only
numbers the rung may claim. The house gates (voice, links, figures-verbatim, ledger-before-gate, records-freeze) hold
unchanged.

## Conventions

Branded Snowflake ids for every platform-minted identifier; caller-supplied instrument and account identifiers are
wrapped at the edge. Lua-first atomicity for every multi-key transition on the wire; one `Ecto.Multi` for every
multi-row posting; `with` and tagged tuples for sequential domain steps; the closed error set at the boundary.
Grounded, never invented. A+ gates and Writerside-friendly markdown throughout.
