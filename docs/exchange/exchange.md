# TRD · The Exchange Platform on the As-Built Tree

<show-structure depth="2"/>

Status: **PROPOSED.** This is the front door of the Exchange Platform: the rationale, the five W's, what gets built and
why, the roadmap in summary, and how delivery runs. The system specification is
[`exchange.specs.md`](exchange.specs.md); the delivery ladder is [`exchange.roadmap.md`](exchange.roadmap.md); the two
patterns under the hot path are argued in depth in [`exchange.patterns.md`](exchange.patterns.md). Every module cited as
existing has a committed record in this repository; everything new is marked PROPOSED. Nothing here is a record — the
first rung's harness produces the first number this platform may ever claim.

## The problem, stated once

A trading platform has four jobs that pull in different directions: **sequence** commands per instrument with a
guarantee no lock can give as cheaply as a single writer; hold a **latency** budget measured in microseconds on the
match path; stay **durable and auditable** — every fill explainable as a fold over facts; and **fan out and follow
up** — ticks to many readers, settlement and risk as retriable work. The classic failure is answering all four with one
primitive: a queue pressed into being a log, a log pressed into being a bus, a bus carrying objects. The design rule
this suite holds is the opposite: three messaging shapes, each served by the primitive built for it, every primitive
kept in its role.

| Shape | Carries | Served by (as-built unless marked) |
|---|---|---|
| Command / sequencing | one ordered command stream per instrument, one writer | `EchoCache.Ring` ingress → `Exchange.Book` (PROPOSED) draining into a pure Decider; sequence is branded mint order |
| Event / fan-out | facts emitted once, read by many, replayable | the claim-check bus (`bcsG.md`) for fan-out; the Journal (Chapter 4.4) then per-instrument stream lanes (`bcsH.specs.md`) for the log |
| Work | retriable follow-ups: settlement, risk jobs, reporting | `EchoMQ.Jobs` / `Lanes` / `Consumer` — fair per-venue lanes (Chapter 3.4) |

## Rationale — re-grounding the earlier proposals

An earlier proposal set (now deleted at the Operator's direction; its sound shape is kept) reached for parts this tree
does not carry: a BullMQ-wire queue whose compatibility this project dropped by decision, `Phoenix.PubSub` where the
one wire already fans out, `libcluster` + `Horde` where the canon's own audited hash is the placement function, and an
event store that existed as discipline rather than as a certified component. The rethink re-grounds every role:

| Role | Rethought answer |
|---|---|
| Ingress + backpressure | `EchoCache.Ring` — bounded `publish/2` answering `:ok` or `:dropped` with the drop counted; admission control as a typed answer |
| Sequencing | the branded Snowflake stamped at admission — the sequence is the id, so the cursor, the sort, the claim, and the cache key are the same fourteen bytes |
| Single writer | `Exchange.Book` (PROPOSED), the sole drainer of its instrument's Ring, shelling to `Exchange.Decider` (pure) |
| Event store, milestone A | `EchoCache.Journal` under a pluggable `EchoCache.Shadow` — append, dedup, fold-to-state replay, box-loss restore: all committed (4.4, Appendix D, the shadow rung) |
| Event log, milestone B | per-instrument stream lanes — conn.1–conn.2 of `bcsH.specs.md`, a recorded dependency |
| Fan-out | `EchoCache.Coherence` broadcast and RESP3 tracking on the data connection (4.2, 4.5); payloads are 29-byte claims, never objects (Appendix G law) |
| Work | as-built EchoMQ lanes; a flooded venue cannot starve its neighbors because the rotation is a committed record |
| Reads | `EchoCache.Table` — nanosecond-class hits, one fill per herd, newer-wins by mint order |
| Regulated ledger | Postgres double-entry over the SQL canon (`src/postgres`), one `Ecto.Multi` per posting |
| Placement, milestone C | `Exchange.Placement` (PROPOSED) — a consistent ring over `EchoData.BrandedId.hash32/1`; data already shards by `Keyspace` hash tags |
| The client | `EchoMQ.Connector` via `EchoWire` — hardened and refereed on exactly this traffic (`bcsH.md`) |

## The five W's

**Why.** Latency by construction — the hot path is one bounded buffer, one process, one pure function; overload is a
typed `:dropped` at the door, not a timeout discovered downstream. Audit by construction — state is a fold over an
append-only log a committed rung already replays byte-for-byte. Fairness by construction — the lanes already proved
their rotation under flood. One wire — fan-out, invalidation, the log, and the work ride the connector this series
refereed, and one id discipline makes every store sort by time for free.

**What.** `Exchange.Gateway` parses untrusted input once into typed commands with a closed error set, minting branded
ids at the edge; commands enter the instrument's Ring; the Book drains in batches, asks the Decider, appends the
resulting events to the log, answers the caller; projections, risk, and settlement consume the log idempotently;
positions read through Tables; settled money posts to Postgres; market data fans out as claims that resolve through
the immutable `(id, version)` term cache.

**Who.** New and PROPOSED: `Exchange.Gateway`, `Exchange.Book`, `Exchange.OrderBook` (pure), `Exchange.Decider`
(pure), `Exchange.Projection`, `Exchange.Placement`, `Trading.Ledger`. As-built underneath: `EchoData.*`,
`EchoCache.*`, `EchoMQ.*`, over `EchoWire`. The Operator directs; the Author ships — see AAW delivery below.

**When.** Milestone A ships on today's tree: the Journal is a certified event store, the Ring a certified buffer, the
lanes certified fair. Milestone B gates on conn.1–conn.2. Milestone C gates on the Placement primitive and a
partition-mode table fixed at its own rung. Dependencies are recorded in the roadmap, never discovered.

**Where.** The BEAM beside Valkey — Dragonfly the native primary, Valkey the portable secondary by construction —
over loopback or unix sockets per Appendix H's transport rows; Postgres beside it for the regulated record; Fly
machines as the deployment grain, FLAME-style ephemeral Work consumers named as a seam the disposable-consumer
pattern already permits.

## Why this shape — the positive case

No microservices, stated positively rather than defensively: the command hot path is in-BEAM because a synchronous
service call on the match path buys nothing and costs a network round trip the budget cannot afford; bounded contexts
are umbrella apps because the compile-time boundary is the reversible seam — a context can be lifted out the day a
real independent-deploy need appears, and not a day sooner; and scale is sharding, not splitting — the data tier
shards by hash tag, the books place by hash ring, and the code stays one deployable. The compounding argument is the
BCS property: pay the encoding once at mint (Appendix F) and the sequence, the key, the sort, the claim, and the
cache key are the same paid form — measured at a constant 232 ns warm resolve on the bus and a byte-sort that equals
the decode-sort at a fraction of the cost.

## Roadmap, in summary

Three milestones, climbed in order — the full ladder with per-rung gates lives in
[`exchange.roadmap.md`](exchange.roadmap.md):

| Milestone | Rungs | At the end you can |
|---|---|---|
| A · the walking skeleton | TRD.1–TRD.5 | submit an order, watch it match in a single-writer book fed by a Ring, replay the book from its Journal, read a position at hit speed, see the fill posted double-entry, and watch settlement drain a fair lane |
| B · the durable core | TRD.6 | replay any instrument from a stream lane; attach a polyglot risk consumer through a consumer group |
| C · the scale-out | TRD.7–TRD.8 | place books across nodes by the audited hash, lose a node and watch a book hand off, flood a venue and watch the others hold |

## AAW delivery

The Exchange Platform ships under the dual-role Agile Agent Workflow this repository runs everywhere. **The Operator** directs:
selects the entry rung, reviews each shipped increment, and gives feedback that edits the spec — the spec is the
single source of truth, and feedback never patches an implementation past its specification. **The Author** builds:
each rung becomes a spec-first increment grounded in real modules and real commands (NO-INVENT — nothing cited that
does not exist, everything new marked PROPOSED until its rung lands), then the slice, then the harness, then the
committed record. The loop per rung is sharpen → build → ship → demo → review → feedback → adapt.

The house laws carry over whole: derivations before measurements, and a measurement that contradicts its derivation
overturns it on the record with the mechanism named; records freeze — a flawed run is replaced whole and confessed in
the progress ledger; figures in any article appear verbatim in a committed record; ledgers mutate before gates run;
every voice and link gate that holds for the series holds here. Each rung is a vertical slice built to production
quality — single-writer and atomic (one process per aggregate, single-slot Lua for multi-key transitions, one
`Ecto.Multi` per posting), supervised (every process a supervised child; pure logic in side-effect-free cores the
processes shell out to), harnessed (unit tests on the cores, properties on the invariants, the determinism loop on
every process-touching slice), and truthful (at-least-once stays at-least-once; the numbers a rung claims are the
numbers its harness produced).

## Map

The specification: [`exchange.specs.md`](exchange.specs.md). The ladder: [`exchange.roadmap.md`](exchange.roadmap.md).
The patterns under the hot path: [`exchange.patterns.md`](exchange.patterns.md). The records this suite stands on:
`bcs.toc.md` — the lanes, the cache and its coherence, the journal and its shadow, the claim check
(`bcsG.md`), the connector referee (`bcsH.md`) and its forward specification
(`bcsH.specs.md`).
