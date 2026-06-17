# EchoMQ — the program

> **Status: LIVING DOCUMENT — Operator-governed.** The front door of the EchoMQ program: what it is, how
> its spec home reads, the complete roadmap — the ratified program ladder and the proposed 3.x stream
> tier — and the milestone layer that binds each Movement's completion to a concrete Exchange-platform
> ship (`docs/exchange/` → `echo/apps/exchange/`). The milestone layer is what this file ADDS (the
> Operator's directive, recorded in the run ledger as D-11/D-12); everything else links to where it
> already lives. This file PLANS; [`./emq.design.md`](./emq.design.md) and the [`./specs/`](./specs/)
> triads DEFINE. Corrections ride Operator checkpoints; feedback edits this file, never an
> implementation past it.

## The program in one screen

**One program, three movements: all EchoMQ code converges in `echo/apps/echo_mq`.** The full 5W per
movement lives in [`./emq.roadmap.md`](./emq.roadmap.md); one line each here:

- **Movement 0 · BCS Migration** — the measured, rung-gated BCS drop lands in the production umbrella
  and is re-proven there: `echo_wire` (the extracted wire layer under the `EchoWire` facade), `echo_mq`
  (the bus), `echo_cache` (with the pluggable `EchoCache.Shadow`), the `EchoData` BCS subtree, the rung
  gates tracked. Rung **emq.0 — shipped** (`a2d599c8`).
- **Movement I · The Core** — the v1 capability surface pushed to state of the art inside `echo_mq`:
  the scheduler + retry vocabulary (**emq.1**, shipped), the **full-parity rewrite of the v1
  capability floor** `echo_mq` lacks — introspection & metrics, the operator lifecycle verbs, the
  observability & recovery plane, decomposed into **emq.2.1 / emq.2.2 / emq.2.3** (**emq.2**, cluster
  2/3 shipped — emq.2.3 watch next), the parent/flow family (**emq.3**). The frozen v1 line (`apps/echomq`, `1.3.0`) is a
  **capability reference** (the surfaces to port); it dissolves when absorption completes (timing
  Operator-owned). echo_mq is the single source of truth — built fresh, never migrated from.
- **Movement II · The Extension** — the family depth a multi-tenant production bus needs: groups
  deepened, batches, lifecycle controls, the cache deepened, the proof stack (**emq.4–emq.8**).

**The delivery thesis.** The movements exist to ship the Exchange platform. The five-document PROPOSED
suite under `docs/exchange/` ([front door](../exchange/exchange.md) ·
[ladder](../exchange/exchange.roadmap.md) · [specification](../exchange/exchange.specs.md) ·
[engine patterns](../exchange/exchange.patterns.md) ·
[strategy patterns](../exchange/exchange.strategies.md)) becomes `echo/apps/exchange/` code as the
movements complete — each Movement done is a milestone with a named Exchange ship (the milestone blocks
below). The platform already records this program as its substrate: its specification names the bus as
the work surface ("Settlement, notifications, end-of-day reporting, reconciliation: `EchoMQ.Jobs` …
drained by `EchoMQ.Consumer`, shaped by `EchoMQ.Lanes` with one group per venue" —
[`exchange.specs.md`](../exchange/exchange.specs.md) §Jobs) and traces its scheduled-jobs needs to
Movement I's opening rung ("scheduled and repeatable jobs remain the EchoMQ roadmap's 2.1 row, with
this platform's needs recorded there as an input" — the same section).

## The spec home — how to read it

| Surface | File | Role |
| --- | --- | --- |
| The design canon | [`./emq.design.md`](./emq.design.md) | Operator-approved, reconcile-only, never redesigned: genesis, the S-1…S-7 locks (braced `emq:{q}:` grammar, branded `JOB` ids, the one-time fork, Valkey-as-gate, declared keys), the ADRs, the deferred families |
| The engineering roadmap | [`./emq.roadmap.md`](./emq.roadmap.md) | **the single, consolidated roadmap** — the program "EchoMQ in Three Movements" (the epic, per-movement 5W, the rung ladder emq.0–emq.8 incl. the emq.2 parity cluster, seams 1–9, the course bridge) AND the 3.x stream tier (§EchoMQ 3.x); the former `emq2.roadmap.md`/`emq3.roadmap.md` were consolidated into it and removed |
| The 2.x line specification | [`./emq2.specs.md`](./emq2.specs.md) | the BCS-side specification of the 2.x line's laws and surfaces — aligned with the program, never redesigning what the canon owns (the delivery view is the consolidated [`./emq.roadmap.md`](./emq.roadmap.md)) |
| The 3.x stream tier specification | [`./emq3.specs.md`](./emq3.specs.md) | the PROPOSED next major: event streams, retention as declared policy, the archive under a shadow, time-travel by mint instant — awaiting Operator slot ratification (the delivery view is [`./emq.roadmap.md` §EchoMQ 3.x](./emq.roadmap.md)) |
| The bibliography | [`./emq.references.md`](./emq.references.md) | read-first before expanding the roadmap: the consolidated BCS bibliography |
| The rung triads | [`./specs/`](./specs/) — [`emq.0.md`](./specs/emq.0.md) (in flight) · [`emq.1.md`](./specs/emq.1.md) (specced) | the binding per-rung contracts (`emq.N.md` / `.stories.md` / `.llms.md`), built to [`../elixir/specs/specs.approach.md`](../elixir/specs/specs.approach.md) |
| The run ledger | [`./specs/emq-0.progress.md`](./specs/progress/emq-0.progress.md) | the emq-0 run's thinking/decisions/learnings/report channels |

## The complete roadmap, with milestones

*Interpretation, recorded:* the Operator's "complete roadmap based on `emq*.roadmap.md` current, 2, 3"
named three roadmap files — the program ladder, the 2.x line view, and the 3.x stream tier. They are now
**consolidated into one** — [`./emq.roadmap.md`](./emq.roadmap.md) (the ratified program ladder, the 2.x
line view it mirrored, and the 3.x stream tier, §EchoMQ 3.x); the former `emq2.roadmap.md`/`emq3.roadmap.md`
were consolidated into it and removed (history in git). The ladder therefore appears once below; the 3.x tier enters as its own section with
its status carried, never re-decided here.

### The program ladder (emq.0–emq.8) — what each rung unblocks for the Exchange platform

| Rung | Mvt | Ships (the slice) | Unblocks for the Exchange platform | Status |
| --- | --- | --- | --- | --- |
| **emq.0** | 0 | the Movement-0 delta (the `echo_wire` extraction · the pluggable shadow · the shadow rung · dual-path loaders) + the test/coverage pass — [`./specs/emq.0.md`](./specs/emq.0.md) | the platform's entire as-built starting inventory, production-certified: "the wire (`EchoMQ.Connector` over `EchoWire` …) … the work queue … the cache … the buffer (`EchoCache.Ring` …) … the event store (`EchoCache.Journal` …) under a pluggable shadow … the canon" ([`exchange.roadmap.md`](../exchange/exchange.roadmap.md) §Where-this-starts) — every component milestone A stands on; also the 3.x tier's two hard dependencies (the extracted wire; the pluggable Shadow) | **shipped** (`a2d599c8`) |
| **emq.1** | I | the scheduler + retry vocabulary: run-at/run-in over the schedule set, repeatables as fresh `JOB` mints, attempts-with-backoff + the poison-job drill, the supervised promote pump, connector auto-resubscribe — [`./specs/emq.1.md`](./specs/emq.1.md) | the recorded 2.1-row trace closes: scheduled settlement triggers (TRD.3's feedback line "settlement trigger — per-fill or batched" gains its scheduled arm), notifications, end-of-day reporting, and Pattern IV's "reconciliation as a consumer: a periodic sweep" ([`exchange.strategies.md`](../exchange/exchange.strategies.md)); claims-bus subscribers survive a reconnect | **shipped** (`e0fa9b03`; conformance 14→18) |
| emq.2 | I | the **full-parity rewrite** of the v1 capability floor `echo_mq` lacks, under the v2 laws — **emq.2.1** introspection & metrics · **emq.2.2** lifecycle & mutation ops · **emq.2.3** observability & recovery (the carve + ADRs: [`./specs/emq.2.design.md`](specs/emq.2/emq.2.design.md)) | **the operational floor every consumer reads through**: the counts/metrics/state introspection a Exchange dashboard reads (emq.2.1), the operator lifecycle verbs a runbook drives — pause/drain/obliterate/reprocess (emq.2.2), and the event/telemetry plane the platform observes the work surface through (emq.2.3) | **cluster 2/3 shipped** — emq.2.1 ✅ `7d98ef86` + emq.2.2 ✅ `76fc947c`; emq.2.3 watch next |
| emq.3 | I | the parent/flow family (the A-1-compatible flow design first — design §11.10 — then the build) | no Exchange line names this family today; its consumer claim stays open until a rung records one | planned abstract |
| emq.4 | II | groups deepened: control plane, group-aware recovery, the park-don't-poll metronome, weighted/deficit rotation, the starvation drill | the venue-lane verbs the platform adopts as its safety machinery, re-gated deeper: "the kill switch is a lane verb" (Pattern V — pause/resume/limit per strategy), promotion/demotion as lane wiring (Pattern VI: shadow → canary → full), "one group per venue" (§Jobs), TRD.8's flooded-venue fairness re-gated cluster-wide | planned abstract |
| emq.5 | II | batches: bulk consumption, `min_size`/`timeout` shaping, affinity, the partitioned finish | THE batching rung the platform's spec defers to: "Batched settlement maps to the as-built one-flush pipeline posture … until a batching rung earns its own record" (§Jobs); TRD.3's batched-settlement arm | planned abstract |
| emq.6 | II | lifecycle controls: TTL per worker/name, distributed cancel, checkpoints | governs the work surface §Jobs names (settlement, notifications, reporting, reconciliation); no Exchange line names TTL/cancel/checkpoints yet — the mapping stays open | planned abstract |
| emq.7 | II | the cache deepened: BCAST tracking, absorbed-fills compaction, `synchronous=FULL` per group, the invalidation-transport evaluation | the hot market-data read and fan-out path: "positions and exposure read from Tables" (Pattern V), claims fan-out with "RESP3 tracking on the same connection (Chapter 4.5's lag rows are the budget)" ([`exchange.specs.md`](../exchange/exchange.specs.md) §The-bus) | planned abstract — pull-forward candidate (Operator call, recorded) |
| emq.8 | II | conformance + the engine matrix + the telemetry contract + the benchmark gate (the three-layer proof stack) | certifies the substrate under the platform's own house law ("figures in any article appear verbatim in a committed record" — [`exchange.md`](../exchange/exchange.md) §AAW-delivery): every bus property the platform stands on becomes a parse, not prose | planned abstract |

### The 3.x stream tier (PROPOSED — awaiting Operator slot ratification)

The next major, specified from the platform's needs ([`./emq3.specs.md`](./emq3.specs.md)): event
streams on the certified wire, retention as declared policy, the archive under a shadow, time-travel by
mint instant — one wire, no second protocol (a partitioned-log adoption was examined and rejected; the
record is the appendix the spec cites). **Hard dependency: emq.0** — the stream verbs land on the
extracted `echo_wire` and nowhere else; the archive lives under the pluggable `EchoCache.Shadow`.
emq3.1–emq3.2 are wire-and-keyspace work and may be pulled forward beside Movement I — an Operator
call, recorded in [`./emq.roadmap.md` §EchoMQ 3.x](./emq.roadmap.md).

| Tier milestone | Rungs | Unblocks for the Exchange platform |
| --- | --- | --- |
| S1 · the writer | emq3.1–emq3.2 | TRD.4 retargets its event log to emq3.2's `EchoMQ.Stream` (the 3.x roadmap's own recorded consumer line) |
| S2 · the readers | emq3.3–emq3.4 | **TRD.6 — milestone B, the durable core — gates on emq3.3** (the polyglot risk consumer group with crash re-delivery); retention per the compliance window (TRD.6's feedback line "retention — MAXLEN cap or MINID by the compliance window") |
| S3 · the memory | emq3.5–emq3.6 | the strategies' evaluation harness: "run-id replay discipline gates on emq3.4's windows and emq3.5's archive" ([`./emq.roadmap.md` §EchoMQ 3.x](./emq.roadmap.md)); walk-forward depth without resident memory |

### Milestone M0 — Movement 0 complete (emq.0, shipped `a2d599c8`)

**The certified foundation. No Exchange code yet — the substrate the platform stands on.** EchoMQ 2.0
(`echo/apps/echo_mq`), the extracted wire (`echo/apps/echo_wire` under the `EchoWire` facade), the
near-cache with the pluggable shadow (`echo/apps/echo_cache`: `Litestream` and `Shadow.Copy`
conforming), and the `EchoData` BCS subtree — imported, tested pure and `:valkey`-tagged, rung-gated in
the production umbrella, with the migration record's §5 flipped and `echo/rungs/` tracked
([`./specs/emq.0.md`](./specs/emq.0.md)). What this closes for delivery: the Exchange ladder's own
inventory claim — "The walking skeleton (A) has no unbuilt dependency: every component it stands on
carries a committed record today" ([`exchange.roadmap.md`](../exchange/exchange.roadmap.md)
§Dependencies) — holds against production code, not only against the frozen drop; and the 3.x tier's
two hard dependencies (the wire, the Shadow) close with it.

### Milestone M1 — Movement I complete: fully functional EchoMQ (emq.1–emq.3)

**The Exchange App scaffold lands at `echo/apps/exchange`, with Go workers for external market-data
processing.** All forward tense — none of this exists yet; the milestone defines what landing looks
like.

- **The scaffold.** A new umbrella app at `echo/apps/exchange`: the application skeleton and supervision
  tree, standing on the certified inventory over the `EchoWire`-fed client ("`EchoMQ.Connector` via
  `EchoWire`" — the platform's named client throughout its docs), scoped from the Exchange ladder's
  earliest rungs: TRD.1's `Exchange.Gateway` (parse once, typed commands, ids minted at the edge),
  TRD.2's Ring-drained `Exchange.Book` over the pure `Exchange.OrderBook`/`Exchange.Decider`, TRD.3's
  Journal-plus-Shadow wiring with settlement on a venue lane
  ([`exchange.roadmap.md`](../exchange/exchange.roadmap.md) §The-rungs; "TRD.1 is the natural start" — its
  status line). The TRD ladder remains the platform's own delivery ladder under its own AAW loop; this
  milestone lands the app those rungs build in. The binding is deliberately conservative: by M1 the bus
  already carries the platform's recorded 2.1-row needs (scheduled settlement, repeatables for
  end-of-day reporting and the periodic reconciliation sweep, the retry vocabulary with the poison-job
  drill, reconnect-surviving subscriptions), so the scaffold lands on a work surface that already
  serves its §Jobs specification.
- **The Go workers.** External market-data ingestion built on the broker SDK vendored at
  `github.local/invest-api-go-sdk` — module **`github.com/tinkoff/invest-api-go-sdk`** (`go.mod`; gRPC
  transport). The real public surface the workers stand on: `investgo.NewClient`
  (`investgo/client.go:34`) opens the connection; `Client.NewMarketDataStreamClient`
  (`investgo/client.go:137`) yields `MarketDataStream()` (`investgo/md_stream_client.go:20`), whose
  channel-typed subscriptions are the ingestion feed — `SubscribeCandle`
  (`investgo/md_stream.go:47`), `SubscribeOrderBook` (`:89`), `SubscribeTrade` (`:129`),
  `SubscribeInfo` (`:168`), `SubscribeLastPrice` (`:207`) — driven by `Listen`/`Stop`
  (`:253`/`:306`); the unary `Client.NewMarketDataServiceClient` (`investgo/client.go:175`) covers
  backfill (candles, last prices, order book, trading status, last trades, close prices, historic
  candles); own-fill and account feeds ride `Client.NewOrdersStreamClient` (`investgo/client.go:247`)
  and `Client.NewOperationsStreamClient` (`investgo/client.go:259`). Token and account configuration is
  per the SDK README — no value reproduced anywhere in this spec home.
- **The wire meeting point, stated honestly.** How Go-side ingestion meets the `emq:{q}:` keyspace is
  roadmap-forward: **no v2 Go client or keyspace port exists today.** That work has a named slot — the
  program roadmap's seam 8, "the Go-driven conformance harness and the Go store/keyspace ports"
  ([`./emq.roadmap.md`](./emq.roadmap.md) §Seams), held unslotted and "slotted only by a checkpoint
  ruling" ([`./emq.roadmap.md`](./emq.roadmap.md) §Dependencies). Until the Operator slots it, the
  milestone's Go workers own venue-side ingestion and normalization, and the handoff into the
  platform is fixed at the scaffold's first rung with the Operator — never assumed here. One recorded
  adjacency, not a decision: the 3.x tier's open feedback line asks for "the non-BEAM reference
  reader's runtime (Go or Python)" (emq3.3) — an M1 Go fleet makes Go the standing candidate when that
  question reaches its checkpoint.

### Milestone M2 — Movement II complete (emq.4–emq.8)

**The platform's operational depth rides the extension families.** Each mapping below is grounded in a
named line of the Exchange docs; where no line exists, that is stated rather than invented.

| Family (rung) | The Exchange ship it serves | The named line |
| --- | --- | --- |
| groups deepened (emq.4) | per-strategy and per-venue safety machinery: kill switch, throttle, slow-restart; promotion as lane wiring | "route a strategy's intents through its own EchoMQ group and the committed pause/resume/limit controls … *are* the kill switch" (Pattern V); "promotion as lane wiring, demotion as the same wiring reversed" (Pattern VI); "one group per venue" (§Jobs) |
| batches (emq.5) | batched settlement graduates from the pipeline posture to its own record | "until a batching rung earns its own record" (§Jobs); TRD.3's "settlement trigger — per-fill or batched" |
| lifecycle controls (emq.6) | governs the §Jobs work surface (settlement, notifications, reporting, reconciliation) | no Exchange line names TTL/cancel/checkpoints yet — the consumer claim stays open |
| the cache deepened (emq.7) | hot market-data reads and fan-out under a measured budget | "Positions and exposure read from Tables" (Pattern V); "RESP3 tracking on the same connection (Chapter 4.5's lag rows are the budget)" (§The-bus) |
| the proof stack (emq.8) | the substrate's claims become parses under the same law the platform holds for itself | "figures in any article appear verbatim in a committed record" ([`exchange.md`](../exchange/exchange.md) §AAW-delivery) |

When M2 closes, the program ladder is complete and the push source's dissolution becomes an Operator
scheduling question (seam 5), not an engineering one. The platform's milestone B (TRD.6) is the 3.x
tier's business (emq3.3 — the table above), sequenced by the Operator's slot ratification; milestone C
(TRD.7–TRD.8) gates on the platform's own `Exchange.Placement` rung, not on this program.

## Seams — carried, not re-decided

The standing open decisions that touch Exchange delivery, each owned where it was raised:

1. **The wire-app ↔ `Keyspace` fence-time dependency** — the dependency-free `echo_wire`'s connector
   reads `EchoMQ.Keyspace.version_key/0` at fence time (the emq-0 run's ratified build deviation);
   the spec-side resolution (inline the fence-key constant beside the wire version, or move
   `version_key/0` into `echo_wire`) is carried to **emq.1's opening design gate** (run ledger D-10).
2. **The Go-client slot** — seam 8 of [`./emq.roadmap.md`](./emq.roadmap.md): the Go conformance
   harness and the Go store/keyspace ports, unslotted, checkpoint-ruled. M1's wire meeting point
   (above) stands on this seam.
3. **`apps/echomq` dissolution timing** — Operator-owned (seam 5), with the course re-grounding it
   triggers.
4. **The emq.7 pull-forward** — the cache rung is least coupled to the bus machine and may be pulled
   forward; an Operator call, recorded so it is a decision, not drift.
5. **The 3.x tier's slot** — the whole tier awaits Operator slot ratification against the program
   ladder; emq3.1–emq3.2 carry their own recorded pull-forward call
   ([`./emq.roadmap.md` §EchoMQ 3.x](./emq.roadmap.md)).

## Map

The design canon: [`./emq.design.md`](./emq.design.md). The single, consolidated roadmap (the program +
the 2.x line view + the 3.x stream tier): [`./emq.roadmap.md`](./emq.roadmap.md). The line/tier
specifications: [`./emq2.specs.md`](./emq2.specs.md) (2.x) · [`./emq3.specs.md`](./emq3.specs.md) (3.x). The
progress dashboard: [`./emq.progress.md`](./emq.progress.md). The bibliography:
[`./emq.references.md`](./emq.references.md). The triads: [`./specs/`](./specs/) — `emq.0`/`emq.1` shipped,
the emq.2 cluster specced. The ledger: [`./specs/emq-0.progress.md`](./specs/progress/emq-0.progress.md). The
consumer: [`../exchange/exchange.md`](../exchange/exchange.md) and its four siblings.
