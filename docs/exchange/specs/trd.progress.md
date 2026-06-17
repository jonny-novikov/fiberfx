# TRD · Progress — the trading suite ledger

<show-structure depth="2"/>

Status: **the standalone home of the trading suite.** As of the relocation below, the suite lives in its own folder
rather than inside the BCS series tree; this file is its progress ledger and its forward plan. The suite stands on
the BCS series and the EchoMQ program as external dependencies, cited by name. Voice and link gates hold here exactly
as in the series.

## Shipped

**The five suite documents.** `exchange.md` (the front door — problem, rationale re-grounding table, five W's, why
this shape, roadmap summary, AAW delivery); `exchange.roadmap.md` (the TRD.1–TRD.8 delivery ladder with as-built
dependencies); `exchange.specs.md` (the system specification — master invariant, the Disruptor seat, components, data
structures, log A→B, bus, jobs, placement, seams); `exchange.patterns.md` (the deep article on the two patterns under
the hot path — the Decider and the Disruptor, alternatives weighed, the final-choice table); `exchange.strategies.md`
(the in-depth patterns article for hosting strategies — six archetypes as workloads, seven patterns, seven
anti-patterns, the overfitting trap at its formal source).

**TRD.1 and TRD.2 — full quads (PROPOSED, spec-only).** Each rung carries the four-file quad: chapter (`trd.N.md`),
authoritative spec (`trd.N.specs.md`), dual-audience stories (`trd.N.stories.md`), and agent runbook
(`trd.N.llms.md`). TRD.1 is the Gateway (parse-don't-validate at the edge, a closed command vocabulary and a closed
six-member error set, branded ids minted at acceptance, integer `{units, nano}` money, a stateless boundary), grounded
in the Tinkoff Invest order contract. TRD.2 is the Book (the Disruptor seat made real on the as-built `EchoCache.Ring`,
one `Exchange.Book` per instrument as the sole writer, a pure `Exchange.Decider` over a pure `Exchange.OrderBook`,
admission-reconcile as the headline gate). Both `trd.N.md` chapters now carry a `## References` section across four
buckets (external patterns, BCS, the redis-patterns course, echo_mq) — the one writing-rule violation found and fixed
at relocation.

**Code shipped — `echo/apps/exchange` (the real build).** The ladder is now built rung-by-rung in the echo umbrella
(`Exchange.*`, lib-only on `{:echo_data, in_umbrella: true}`), each rung shipped via x-mode Flat-L2 to a committed
rung gate beside the others:

- **TRD.1.1 — the Gateway MVP** (commit `39cc2baa`): `Exchange.Gateway`, parse-don't-validate — untrusted `map` →
  a typed `place`(limit+market)/`cancel` command or one of a closed six-atom error set; branded `CMD`/`ORD` minted at
  acceptance; `{units, nano}` money, never a float; a stateless boundary. Gate `trd_1_1_check.exs` → **PASS 8/8**.
  Deferred to TRD.1.2: `replace`/`:bestprice`, the idempotency seam.
- **TRD.2.1 — the pure matching core** (this rung): `Exchange.OrderBook` (per-side `gb_trees` price ladder, each
  level a FIFO by branded mint order, `new/0`+`best/2`, fully pure) and `Exchange.Decider` (`decide/2`+`evolve/2`,
  pure modulo the single `FIL` mint). Two crossing orders fill at the **maker's** price; a limit remainder rests, a
  market remainder rejects `:no_liquidity`; a same-account cross rejects the aggressor in full (`:self_trade`, book
  unchanged); price-time priority falls out of the id byte order (no clock); no float in any event or fold. Gate
  `trd_2_1_check.exs` → **PASS 6/6** (G1 maker-price · G2 price-time · G5 no-float · G6 self-trade · AS-2 pure-grep ·
  AS-7 fill-key freeze); 34 tests / 10 properties. **Deferred to TRD.2.2:** the `Exchange.Book` GenServer (the single
  writer), the `EchoCache.Ring` drain + admission-reconcile (INV-1/INV-2/INV-7, gates G3/G4), cancel-against-the-book
  matching, and the per-account `EchoData.BrandedTree` index.

## Reconciliation — the relocation (this entry)

The suite was found in two trees (the canonical `echo_data/docs/bcs/` and the publish mirror `echo/docs/bcs/`), moved
to its own folder, and relinked. The decisions, recorded so the move is a decision and not a drift:

**Intra-suite links stay relative.** Every link among the thirteen suite files is a bare relative filename; these
resolve inside the folder and inside the zip unchanged.

**Cross-series links are delinked to citations.** The twenty-one markdown links from the suite into the BCS series
(`bcs.toc.md`, `bcsG.md`, `bcsH.md`, `bcsH.specs.md`, `bcsI.md`) were converted to backtick citations — the suite no
longer carries the series, so it does not hold paths that would not resolve once extracted. The series is referenced
by name; the `trd.N.md` References sections give the full pointers.

**The canon's pointers into the suite are now external.** The BCS series files that referenced the suite
(`bcsI.md` companion line, the `emq2`/`emq3` specs and roadmaps, the series progress ledger) had their links to the
moved files delinked to citations in the same pass, so the series sweeps clean with the suite gone. Historical series
ledger entries keep their words verbatim; only the link mechanic updated, the established treatment for a moved target.

**The external dependency surface, fixed.** The suite depends on: the BCS series (the canon `contract/contract.md`;
Appendix F the order theorem; Appendix G the claim-check; Chapter 3.4 the lanes; Chapter 4.1–4.3 the cache, coherence,
and Ring; Chapter 4.4 the journal; Appendices D and H the shadow and the connector referee), the EchoMQ program
(`emq2.specs.md` the line, `emq3.specs.md` the stream tier — TRD.6's recorded dependency), the redis-patterns course
(the keyspace and hash-tag conventions), and the external venue (the Tinkoff Invest gRPC contract and its Go SDK).

## Upcoming specs to add

The ladder is fixed at TRD.1–TRD.8 ([`exchange.roadmap.md`](exchange.roadmap.md)); TRD.1–TRD.2 are specced. The
remaining rungs below are the next quads to author, each with a detailed abstract, its five W's, the decisions it must
settle, and how it fits the roadmap. The Go worker tier — the external processor the Operator named as crucial — is
specified last as a cross-cutting concern realized across three of these rungs.

| Rung | The quad to add | Milestone | Hard dependency |
|---|---|---|---|
| TRD.3 | the ledger, the journal, and settlement work | A | certified Journal + Shadow + Lanes + the SQL canon |
| TRD.4 | market data as claims, and the external-feed ingestion | A | Coherence + the term-cache pattern |
| TRD.5 | projections into Tables | A | Journal replay + Table |
| TRD.6 | the stream log and the polyglot risk consumer | B | emq3.1–emq3.2 **and** emq.0 |
| TRD.7 | placement across the cluster | C | the audited `hash32` |
| TRD.8 | cluster sharding and cross-venue fairness | C | Keyspace + Lanes |

### TRD.3 — the ledger, the journal, and settlement work

**Abstract.** The rung that makes the matched book durable and the money regulated. Each `Exchange.Book` gains an
`EchoCache.Journal` — append-only events, dedup at admission, fold-to-state replay — under a pluggable
`EchoCache.Shadow` (Litestream to object storage in production, the Copy shadow on a development laptop, one contract
either way). Fills post to a Postgres double-entry ledger (`Trading.Ledger`) one `Ecto.Multi` per posting, all-or-
nothing. Settlement becomes `EchoMQ.Jobs` drained on a per-venue lane — and this is the **first appearance of the Go
worker tier**: a Go settlement worker consumes a fill job keyed by its `FIL` id, computes settlement amounts in
integer `{units, nano}`, and posts. The book's recovery becomes a property rather than a hope: fold the journal,
reproduce live state.

**5W.** *Why* — durability and audit become real (replay equals live) and settled money lives in a regulated store.
*What* — Journal + Shadow wiring per book; `Ecto.Multi` postings; settlement jobs on a venue lane; the Go settlement
worker. *Who* — `Exchange.Book` (emits), `Trading.Ledger` (Postgres under the SQL canon), `EchoMQ.Lanes` (venue
fairness), the Go settlement worker (a Tinkoff Invest Go SDK client). *When* — milestone A, after TRD.2; stands on the
certified Journal, Shadow, and Lanes plus the SQL canon, so no unbuilt dependency. *Where* — `lib/exchange`,
`lib/trading/ledger`, and the Go worker module.

**Decisions.** The stream is the source of truth for unsettled state, Postgres for settled (carried from
`exchange.specs.md`, decided in the stream's favor). The settlement trigger — per-fill or batched — is the rung's
feedback ask. The Go worker's idempotent-handler contract: a duplicate fill job collides on the `FIL` id and
no-double-posts (the at-least-once posture the lanes gate). Money stays `{units, nano}` integer across the BEAM-to-Go
boundary, never a float.

**Roadmap fit.** Closes the walking skeleton's durability and money story; opens the Go worker tier.

### TRD.4 — market data as claims, and the external-feed ingestion

**Abstract.** Two directions of market data. **Outbound:** fills and book deltas fan out as twenty-nine-byte claims
on the coherence bus, resolved warm through the immutable `(id, version)` term cache — many readers, one decode.
**Inbound:** the Tinkoff Invest `MarketDataStream` (a bidirectional gRPC feed) is ingested by a Go market-data worker
that normalizes ticks into typed market events carrying branded ids and `{units, nano}` prices, published as claims —
the external feed's entry point, in Go for the streaming-gRPC throughput.

**5W.** *Why* — many readers need ticks cheaply, and the external feed must enter the platform as typed, branded,
claim-shaped data rather than raw venue messages. *What* — the coherence broadcast of fills and deltas; the term-cache
resolve; the Go market-data ingestion worker. *Who* — `Exchange` (emits deltas), `EchoCache.Coherence`, the Go MD
worker (a `MarketDataStream` client). *When* — milestone A, after TRD.3. *Where* — `lib/exchange` and the Go MD
worker.

**Decisions.** Delta granularity — per-fill or level-aggregated — is the feedback ask. The feed's reconnect and
backoff live in the Go worker (the SDK's behavior, mirrored from the connector law in Appendix H). Claims only on the
bus — the worker resolves objects through the store, never carries them. Event time comes from the tick's mint
instant, not the ingester's wall clock.

**Roadmap fit.** The volatile fan-out tier; the external feed's ingestion seam made real beside it.

### TRD.5 — projections into Tables

**Abstract.** Book-snapshot and position projections (`Exchange.Projection`) consume the log idempotently into
`EchoCache.Table`s, read at the committed hit-class speed, newer-wins by mint order. Crash a projection, rebuild it
from the log, and the rebuilt state equals the live one — the read path as a fold, fenced and fast.

**5W.** *Why* — gates, dashboards, and risk need a fast fenced view of positions and the book. *What* — projection
consumers; Table declarations per kind; the snapshot cadence. *Who* — `Exchange.Projection`, `EchoCache.Table`, the
journal replay. *When* — milestone A, after TRD.4. *Where* — `lib/exchange/projection`.

**Decisions.** Which projections first — positions or book snapshot. Snapshot cadence. Idempotency under
re-delivery (a replayed event must not double-apply).

**Roadmap fit.** The read path; the fast fenced view the risk gates (TRD.6 and the strategies' risk stage) read from.

### TRD.6 — the stream log and the polyglot risk consumer

**Abstract.** The event log moves from the per-book Journal to per-instrument stream lanes — hash-tagged `XADD`,
consumer groups — per `emq3.1`–`emq3.2`, the recorded dependency. Risk runs as a consumer group, and this is where
the **Go worker tier's risk and pricing half** lands: a Go risk worker reads the same stream through
`XREADGROUP`/`XACK`, computes margin, exposure, and value-at-risk with GPU-accelerated math, acks, and is
re-delivered on crash through `XAUTOCLAIM`. The polyglot seam is proven end to end — a non-BEAM consumer on the same
durable log, at-least-once with an idempotent handler.

**5W.** *Why* — durable replay for many independent groups, and heavy risk math off the BEAM where Go's throughput
and GPU acceleration pay. *What* — stream lanes; the risk consumer group; the Go risk worker; the polyglot
at-least-once contract. *Who* — `EchoMQ.Stream` (the emq3 tier), the Go risk worker (Go SDK plus GPU math),
`Exchange`. *When* — milestone B; gates on `emq3.1`–`emq3.2` **and** on `emq.0` (the wire extraction the stream verbs
land on). *Where* — the stream tier and the Go risk worker.

**Decisions.** The non-BEAM reader's id and ack contract. The retention window — `MAXLEN` or `MINID` by the
compliance window. The Go worker's GPU batch size against its latency budget. Replay parity with TRD.3's journal fold
(the stream log must reproduce what the journal did).

**Roadmap fit.** Milestone B's durable core; the Go worker tier's risk half; the rung that consumes the EchoMQ stream
work.

### TRD.7 — placement across the cluster

**Abstract.** `Exchange.Placement` — a consistent ring over the audited `EchoData.BrandedId.hash32/1` — places one
book process per node and routes orders to the owner by id; kill a node and a book hands off; matching refuses (CP)
for an instrument whose owner is unreachable rather than risking a split-brain ladder.

**5W.** *Why* — scale by adding nodes, not by splitting services, and survive node loss without a split-brain book.
*What* — the placement ring; location-transparent routing; the handoff drill; the CP/AP table fixed at this rung.
*Who* — `Exchange.Placement`, the audited hash, the cluster-membership mechanism. *When* — milestone C; stands on the
audited hash. *Where* — `lib/exchange/placement`.

**Decisions.** The virtual-node count. CP for matching, AP for market data — the full per-subsystem table fixed here.
The membership mechanism.

**Roadmap fit.** Milestone C scale-out, part one.

### TRD.8 — cluster sharding and cross-venue fairness

**Abstract.** Shard books across slots by hash tag so a book's keys live in one slot by construction; hold cross-venue
fairness at cluster scale (the lanes' rotation, proven under flood, holding cluster-wide); and name the cross-shard
saga rule — compensating events over the event log — for a trade touching two instruments in different slots.

**5W.** *Why* — data-tier scale and fairness under venue skew at cluster scale. *What* — hash-tag sharding; the
cross-cluster fairness gate; the cross-shard saga rule. *Who* — `Keyspace`, `EchoMQ.Lanes`, the saga. *When* —
milestone C, after TRD.7. *Where* — the sharding and lanes surfaces.

**Decisions.** CP/AP per subsystem on partition. The reshard runbook. Whether any real instrument pair needs the saga
(deferred until one does — a product question, not pre-built).

**Roadmap fit.** Milestone C scale-out, part two — the end state.

### TRD.9 — investex (the BEAM-native Tinkoff Invest client)

**Abstract.** TRD.9 founds **investex** — `echo/apps/investex`, OTP `:investex`, modules `Investex.*` — the
BEAM-native Tinkoff Invest API client, covering the same surface the Go SDK covers: **10 gRPC services / 72 RPCs**
(re-derived exact from the committed `proto/*.proto`; the runbook's "~75" prose resolves to 72). The shape:
elixir-grpc over the Mint adapter + elixir-protobuf (the HTTP/2 stack is already locked, so no new transport
substrate; grpc/protobuf are the two new hex deps); a supervised `Investex.Client` owning the channel + config; seven
stateless per-service modules (one function per unary RPC) + five supervised stream GenServers (resubscribe on
reconnect, `Ping`); money decoded to the canon's `{units, nano}` integers via `Investex.Money` (the Go float bridge
deliberately NOT mirrored); a pure `Investex.Retry.decide/3`; and a two-tier test strategy — a pure default gate plus a
`@tag :sandbox` suite that skips keyless. The chapter quad ships PROPOSED this rung; the build is the 9.1–9.5 ladder.

**5W.** *Why* — a BEAM-native venue client puts order placement, stream supervision, and edge validation under OTP
where the platform lives, speaks the canon's integer money + branded ids, and unblocks the BEAM from the Go fleet for
venue I/O. *What* — `Investex.Client` + the seven unary modules + the five stream processes (72 RPCs) + `Investex.Money`
+ `Investex.Config` + `Investex.Retry` + the committed `Investex.Proto.*`. *Who* — investex is the BEAM's venue client
(PROPOSED); upstream the Gateway (TRD.1) mints the branded `ORD` id it carries as the venue idempotency key; alongside,
the Go worker tier prices the fills. *When* — TRD.9, on the as-built `echo_data` canon + the committed contracts; build
rungs 9.1–9.5 are separate, later x-mode runs. *Where* — `echo/apps/investex` with a gate + transcript at
`echo/rungs/exchange/trd_9_N_check.{exs,out}`.

**Decisions.** F-1…F-11 locked as D-1…D-11 in `trd-9.progress.md`: lib-only umbrella app (no `mod:`); elixir-grpc
over Mint + protobuf; committed protoc-gen-elixir modules; a supervised client + stateless per-service modules; one
GenServer per stream, resubscribe-on-reconnect; `{units, nano}` integer money via `Investex.Money` (no float, no
`.ToFloat()`); `Investex.Config` mirroring the Go Config (env-sourced token, `jonnify.investex` app-name); the pure
retry decision; the two-tier test strategy; the exhaustive parity manifest + a parity-check test; and secret hygiene
(`INVEST_TOKEN` env-only, the value in nothing). SandboxService is split 9.1 (3 bootstrap) / 9.3 (5 order) / 9.4 (6
remaining) = 14 (D-12), recorded reasoning: the Go SDK auto-bootstraps a sandbox account in its constructor, so the
bootstrap trio is needed at 9.1 to test anything. **Risk:** the *spec* is NORMAL risk (a design doc); the *build*
rungs are HIGH risk (real network, a live secret, auth) → each warrants a dedicated Apollo + the secret-hygiene gate.

**Roadmap fit.** TRD.9 is the venue-client subsystem named in the roadmap's "Go worker tier" — the BEAM-native
equivalent of the Go SDK's venue-client seat (see the reconcile of that open decision, immediately below). It stands
adjacent to the Go tier, not in place of it: the Go tier keeps the GPU money-math; investex gives the BEAM a
first-class, supervised, branded venue client. Both speak `{units, nano}` integer money and the branded `ORD` id.

**Build status.** **TRD.9.1 — the transport spine — SHIPPED 2026-06-14.** `echo/apps/investex` founded lib-only (no
`mod:`, INV-5): `Investex.Config` (defaults + env-only `resolve/1`) · `Investex.Client` (supervised TLS channel,
`Bearer` + `x-app-name` metadata, a quiet supervised stop) · the pure `Investex.Retry.decide/3` (linear 500 ms;
`x-ratelimit-reset`-honoring on `ResourceExhausted`) · `Investex.Money` (integer `{units, nano}`, no float) ·
`Investex.Error` + the `Caller` seam · UsersService (4) + the SandboxService bootstrap (3) · the committed
protoc-gen-elixir `Tinkoff.Public.Invest.Api.Contract.V1.*` modules + the `mix investex.gen_proto` regen task · the
parity scaffold (7 mapped / 65 pending / 72 enumerated from the real services) · the two-tier harness. Gated
`echo/rungs/exchange/trd_9_1_check.exs` → **PASS 5/5** (Tier 1, network-free, reproducible) AND the **live sandbox
round-trip** (`open → get_accounts → close`) a **standing result across seeds** against the real sandbox endpoint —
the Operator's hard gate. **[RECONCILE — corrected by TRD.9.1.1: the live "standing result" was a FALSE-GREEN. The
as-built transport could not dial the venue — DEFECT A (the stale sinkholed `…tinkoff.ru` endpoint; the live host is
the T-Bank rebrand `…tbank.ru`) and DEFECT B (`verify_peer` against an OS bundle holding 0 Russian roots, while the
venue chains to a self-signed Russian Trusted Root CA) — so a real non-empty `account_id` was structurally impossible
and the live floor was never genuinely met. The earlier Apollo loop fixed a DIFFERENT false-green (an `async` OS-env
token clobber) and hardened the gate's own-liveness, but the gate's letter was satisfied by a dial that could not have
run as recorded. TRD.9.1.1 fixes A+B (env-resolve the endpoint, default `…tbank.ru:443`; vendor + pin the Russian
Trusted Root CA, keep `verify_peer`) and re-proves G6 through a 3-way live harness; `docs/exchange/trd.9.1.1.specs.md`
authoritative.]** Built via **x-mode Flat-L2 + a dedicated Apollo** (HIGH risk: network / live secret / auth):
Apollo BLOCKED a false-green G6 (an `async` OS-env clobber in `ConfigTest` that no-op'd the hard gate), the team
remediated (FIX-1 `async: false` + save/restore; FIX-2 the gate asserts its own liveness + fails loudly keyless;
FIX-3 a quiet supervised stop), and Apollo re-verified **BUILD-GRADE**. `:grpc` 0.11.5 + `:protobuf` 0.17.0 are the
only new umbrella deps. Slice `trd.9.1.{md,specs.md}`; runbook `trd.9.1.prompt.md`; ledger `trd-9-1.progress.md`.
**TRD.9.1.1 — the transport fix (endpoint + Russian-CA TLS trust) — OPEN (PROPOSED, in build).** The corrective slice
that makes the 9.1 transport actually dial the live venue and corrects the false-green G6 above. Two real defects:
DEFECT A — `Investex.Config` hardcoded the stale `sandbox-invest-public-api.tinkoff.ru:443` (`config.ex:20`) and
`resolve/1` ignored `INVEST_API_URL`/`INVEST_API_PORT` (`config.ex:89-91`); the live host is the T-Bank rebrand
`sandbox-invest-public-api.tbank.ru:443`. DEFECT B — `tls_opts/0` verified `verify_peer` against
`:public_key.cacerts_get()` (0 Russian roots) while the venue chains leaf → Russian Trusted Sub CA → Russian Trusted
Root CA (`client.ex:184-193`). The fix (smallest correct change, no new dep, no shim, no 9.2 file touched):
env-resolve the endpoint (default `…tbank.ru:443`, INV-10); vendor + fingerprint-pin the `Russian Trusted Root CA`
under `priv/certs/` and append it to `cacerts`, keeping `verify_peer` (INV-11, SHA-256 `D2:6D:…:CF:31`); a
network-free trust proof (G-TLS) + a 3-way live harness (G6′: PASS / TLS-trust-FAIL=BLOCK / egress-BLOCK=reproduced
-defer). **It re-proves 9.1's G6 genuinely and unblocks TRD.9.2's live floor** (which re-runs through the same harness;
9.2's held Stage-5 commit ships after). HIGH risk (it changes TLS peer-verification trust and vendors a foreign
state-operated root CA) → a dedicated Apollo. Slice [`trd.9.1.1.md`](trd.9.1.1.md) ·
[`trd.9.1.1.specs.md`](trd.9.1.1.specs.md); runbook [`trd.9.1.1.prompt.md`](trd.9.1.1.prompt.md); ledger
`trd-9-1-1.progress.md`.

**Next (after TRD.9.1.1 re-proves the dial): TRD.9.2** — the read services (InstrumentsService 27 + MarketDataService 7
+ OperationsService 7), reusing this transport unchanged and moving their rows from the parity scaffold's pending list
to asserted; its live floor re-runs through the TRD.9.1.1 harness.

### The Go worker tier (cross-cutting — the external processor)

**Abstract.** The external processor the Operator named as crucial is a fleet of Go workers: drained as `EchoMQ.Jobs`
and reading through `EchoCache`, chosen for numeric throughput and GPU-accelerated money-math. It is not one rung but
a spine realized across three — settlement (TRD.3), market-data ingestion (TRD.4), and risk (TRD.6) — and the contract
it honors is frozen by the two rungs already specced: money is `{units, nano}` integers on both runtimes, the branded
id is the job key and the venue idempotency key (`PostOrderRequest.order_id`), and claims (never objects) cross the
bus. The BEAM emits a fact; the fact becomes a job; a Go worker drains it. No Go worker sits on the matching hot path —
the hot path stays pure and in-BEAM, joined to the heavy math only by a claim-keyed job. **The venue-I/O leg of this
tier is now a BEAM-native client (TRD.9, investex)** — the Go tier keeps the GPU money-math, the BEAM no longer waits
on the Go fleet to reach the venue, and both share the `{units, nano}` money and the branded `ORD` id.

**Decisions to settle at its rungs.** The job payload schema — a versioned claim envelope carrying the branded id and
integer money, nothing more. The idempotent-handler contract — `FIL`/`CMD` id dedup so a duplicate delivery is a
no-op. The result topic — a compacted changelog the Tables hydrate from (the `emq3.6` changelog read, no compactor).
The GPU batch-versus-latency dial. The gRPC reconnect and backoff — the SDK's, mirrored from the connector law in
Appendix H. The deployment grain — FLAME-style ephemeral runners, a consumer that exists only for the drain, the
journal-beside-consumer pattern making it disposable.

**Roadmap fit.** The external-processor spine, gated incrementally at TRD.3, TRD.4, and TRD.6. **Open Operator
decision — RESOLVED (2026-06-13).** The question was whether to specify the tier as one dedicated quad or keep it
distributed across the three consuming rungs. The Operator resolved the *venue-I/O leg* of it by asking for a
first-class BEAM-native client: **TRD.9 (investex) is that dedicated subsystem with its own quad**, covering the full
Tinkoff Invest surface the Go SDK covers. The remaining Go worker tier — the GPU-accelerated money-math (settlement,
pricing, risk) — stays distributed across TRD.3 / TRD.4 / TRD.6 as before, now *fed by* investex's venue data rather
than owning the venue-client seat itself. So: the venue client is one documented subsystem (TRD.9); the money-math
fleet remains the three consuming rungs. The contract both honor is unchanged — `{units, nano}` integer money, the
branded `ORD` id as the venue idempotency key and the job key, claims (not objects) on the bus.

## Map

The suite: [`exchange.md`](exchange.md) · [`exchange.roadmap.md`](exchange.roadmap.md) ·
[`exchange.specs.md`](exchange.specs.md) · [`exchange.patterns.md`](exchange.patterns.md) ·
[`exchange.strategies.md`](exchange.strategies.md). The specced rungs: [`trd.1.md`](trd.1.md) and
[`trd.2.md`](trd.2.md) with their `.specs`, `.stories`, and `.llms` quads. External dependencies are cited by name:
the BCS series (the canon, Appendices F, G, D, H, and Chapters 3.4 and 4.1–4.4), the EchoMQ program (`emq2.specs.md`,
`emq3.specs.md`), the redis-patterns course, and the Tinkoff Invest contract and Go SDK.
