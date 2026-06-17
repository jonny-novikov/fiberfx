# Branded Component System — the course

> **The architecture law and its identity contract, taught from the manuscript — and proven by committed
> evidence.** Systems own their state and behavior; only identities, and messages about identities, cross
> boundaries; identity is a typed, ordered, placed contract — the 14-byte branded snowflake, conformant across
> five runtimes against one canon. The course mirrors the BCS manuscript Part for Part, quotes its figures
> verbatim from frozen transcripts, and assembles toward a running trading system on the EchoMQ 2.0 Valkey-native
> bus.

**This is the course TOC** (the structural map of the pages served at `/bcs`). The *manuscript's* reading order is
a different artifact: [`content/bcs.toc.md`](content/bcs.toc.md) — Parts and Abstracts, owned by the
Author/Operator, never edited by course authoring.

## The running system: the manuscript and its evidence

The course teaches a book being written in this repository: the **BCS manuscript** under
[`content/`](content/bcs.toc.md) — eight Parts, every built chapter backed by a rung (an executable check script
plus a frozen `PASS n/n` transcript), decisions recorded as D-1…D-10 in the ledger. The identity canon is the
**branded snowflake** ([`content/contract.md`](content/contract.md)): a 3-character uppercase namespace + 11
Base62 characters carrying `ts(41) | node(10) | seq(12)`, epoch `1704067200000`. The worked project is a
**trading system** (`AST TXN PRT ORD RSK STR`); the bus is **EchoMQ 2.0, backed by Valkey**, reached through a
purpose-built Elixir connector. Where the course meets the bus protocol it doors to `/echomq` (the served course;
its spec authority is the EMQ ladder, [`echo_mq.md`](../../echo_mq/echo_mq.md)); where it meets the substrate
patterns it doors to [`/redis-patterns`](../../redis-patterns/redis-patterns.toc.md).

## Who this is for

Engineers and agents designing multi-system architectures — services, game-style component systems, queues, and
the boundaries between them — who want a contract stronger than folklore for the values that cross. Programming
fluency is assumed; the architecture vocabulary is built from the floor.

## What you will be able to do

- State the law in three clauses and name the failure mode each clause retires (the reach-through, the traveling
  object, the silent join, the second clock, the routing table, the dialect).
- Read the identity contract property by property — namespace, order theorem, placement hash, canon — as
  load-bearing architecture.
- Follow the Elixir reference implementation: systems as OTP applications, property stores on ETS and CHAMP,
  archetypes as data, relations as systems.
- Read the Valkey-native bus: the `emq:{q}:` keyspace, jobs as entities, the state machine in Lua.
- Trace the capstone: the trading system assembled from the parts above, with the decider pattern rethought over
  branded identities.

## Conventions

- **Subject.** The Branded Component System, taught from the manuscript; figures quoted verbatim from committed
  outputs; ids as inline code.
- **Grounding.** The manuscript files and the evidence package under `content/`; the canonical grounding map is
  fixed in [`bcs.roadmap.md`](bcs.roadmap.md). Never a fabricated figure, namespace, script, or API.
- **Structure.** Three levels — chapter `B[N]` (a landing), module `B[N].[M]` (a hub; module numbers map
  one-to-one to manuscript chapters), dive `B[N].[M].[S]` (≥3 per module, fixed in the chapter triad at build
  time).
- **Spec system.** Designed specs-first: this TOC is the map, [the roadmap](bcs.roadmap.md) is the plan, and the
  chapter triads under [`specs/`](specs/bcs.0.md) are the contracts pages are built from. See [`bcs.md`](bcs.md).
- **Quality.** Every page passes the ten jonnify-cms gates (`containers · svg · no-future · voice · storage ·
  motion · degrade · links · pager · refs`) and carries a branded **`BCS…`** Snowflake build stamp — the course
  stamps in its own namespace.
- **Identity.** The course renders in its own visual identity, defined by the B0 landing; the dark-editorial
  tokens of the sibling courses are out of bounds ([`bcs.md`](bcs.md)).

## Status — a living map

This TOC is kept in sync with the built course: when a module or chapter ships, its entry here is updated.

**Status legend:** `✓ built` (served under `/bcs/…`) · `◐ in progress` · `○ planned/specced`. **B0** (the
landing) is in build; **B1** is built (landing + six modules + twenty dives); **B2** is in progress (landing +
B2.1–B2.5 built, B2.6 manuscript-pending); **B3** is in progress over a fully written Part III (landing +
B3.1–B3.3 built; triad `specs/bcs.3.*`, the remaining four modules manuscript-ready); **B4** is in progress over
Part IV written through 4.4 (landing + B4.1–B4.4 built; triad `specs/bcs.4.*`, B4.5 manuscript-pending); **B8**
is in progress over the **Exchange Platform design corpus** `docs/exchange/` (landing + B8.1–B8.2 built; spec
`specs/bcs.8.*`; the substrate as-built + hardened — `echo/apps/echo_cache` · `echo/apps/echo_mq` ·
`docs/echo_mq/emq.roadmap.md` — only the `Exchange.*` consumer PROPOSED); B5–B7 are planned over TOC abstracts
and wait for their manuscript Parts.

---

## B0 · Orientation — the law, the id, the map · `/bcs` · ◐ in progress

> The course landing, and the course's design exemplar: the law in three clauses, the 14-byte id dissected, the
> frozen-evidence ethic, and the chapter map. Unbuilt chapters appear as non-anchor `soon` cards — the landing
> holds a full `links` PASS. Triad: [`specs/bcs.0.md`](specs/bcs.0.md).

- **B0 · The landing** — the law as a triptych, the id anatomy as the anchor motif, the evidence transcript
  styling, the B1–B8 map, doors to `/echomq` and `/redis-patterns`, References.

## B1 · Ideas Behind — the conceptual floor · `/bcs/ideas` · ✓ built (27 pages; triad: [`specs/bcs.1.md`](specs/bcs.1.md))

> Part I: the law, the contract read as architecture, the storage economics, what distribution changes, and the
> time inside the name. Grounding: `content/bcs1.md`–`bcs1.5.md`, `bcs1.a1.md`, with the rung 1.1 transcripts and
> the bench record. Module slugs and dives are fixed in the triad's ladder ([`specs/bcs.1.specs.md`](specs/bcs.1.specs.md)).

- **B1.1 · The System Substrate** — `system-substrate` — the smallest faithful system: a boundary gate, a
  private-ETS property store, a supervisor; six gates refusing the canonical crimes (`PASS 6/6`); the Go
  owner-goroutine counterpart. Dives: the-six-gates · ownership-on-the-beam · the-owner-goroutine.
- **B1.2 · The Identity Contract, Read as Architecture** — `identity-contract` — the contract property by
  property: namespace, order theorem, hash32 placement, canon — each read against the failure it retires.
  Dives: the-namespace-discriminant · the-order-theorem · placement-not-security · the-minting-law-and-the-canon.
- **B1.3 · Choosing the ID System** — `id-system` — the measured decision record: seven key shapes, two engines,
  a million keys each; the branded form against UUID-16/decimal/UUID-36; stream ids at zero marginal cost.
  Dives: the-new-hash-table · the-measured-table · the-chooser · the-streams-horizon.
- **B1.4 · From ECS to BCS** — `ecs-to-bcs` — the index-handle's three deaths (save file, socket, foreign store),
  each traced to a missing contract property; the ECS→BCS translation table. Dives: the-handle-at-its-best ·
  the-three-deaths · the-translation-table.
- **B1.5 · The Time Inside the Name** — `time-inside-the-name` — the 41-bit horizon (September 2093), the law of
  two clocks, the monotonic mint floor, windows as synthetic cursors. Dives: the-41-bit-horizon ·
  the-law-of-two-clocks · the-floor-and-the-third-clock.
- **B1.6 · Appendix — Branding Beats Its Own Integer** — `branding-beats-its-own-integer` — the encode path
  against the decimal rendering in all five runtimes (Rust 4.2×, C 2.8×, the BEAM tie, the one V8 loss where the
  wasm crossing is prescribed). Dives: the-two-renderings · the-five-runtimes · the-whole-system-accounting.

## B2 · The Elixir BCS Core — the reference implementation · `/bcs/elixir-core` · ◐ in progress (landing + B2.1–B2.5 built; triad: [`specs/bcs.2.md`](specs/bcs.2.md))

> Part II: the law landed on OTP — one application per system, property stores behind a supervised boundary, the
> trading domain as the working vocabulary. Grounding: `content/bcs2.md`–`bcs2.5.md` + the rung 2.1–2.5 frozen
> transcripts (chapter 2.6 exists in the ledger and git history; its course module waits for the file). The
> chapter landing and the five manuscript-ready modules are built; B2.6 waits for its manuscript chapter.

- **B2.1 · A System Is an OTP Application** — `otp-application` — boundary, supervision tree, ownership; pure
  cores shelled by GenServers; restart semantics as an architectural statement; the `PASS 5/5` rung (R1–R5).
  Dives: the-export-list · existence-and-the-kill · the-blast-radius. **✓ built**
- **B2.2 · Property Stores on ETS** — `property-stores` — positions, balances, and instrument state as
  system-owned tables; the branded id as the only key; chronology as a property of the keyspace; the `PASS 5/5`
  rung (P1–P5). Dives: the-only-key · chronology-without-a-column · the-review-performed. **✓ built**
- **B2.3 · The CHAMP Property Database** — `champ` — structural sharing as the snapshot mechanism; the contract
  hash as the trie's placement function; the ETS↔CHAMP crossover stated both ways; the `PASS 7/7` rung (H1–H7).
  Dives: the-forest-and-the-placement-law · sharing-at-the-honest-metric · the-crossover. **✓ built**
- **B2.4 · Archetypes and Composition** — `archetypes` — property inheritance as data under the `ARC` namespace
  (D-8); the composite instrument without a class diamond; the `PASS 5/5` rung (A1–A5). Dives:
  archetypes-are-data · one-definition-a-thousand-instruments · the-guards-and-the-lanes. **✓ built**
- **B2.5 · Relations Are Systems** — `relations` — the edges store: tuple-keyed relations, both ends gated, dual
  private indexes; normalization performed in a gate; the `PASS 5/5` rung (E1–E5). Dives:
  the-edge-is-the-relation · the-supersession-performed · traversal-and-coherence. **✓ built**
- **B2.6 · Gates and Acceleration at the Boundary** — `boundary-acceleration` — every ingress gated by
  namespace; the deferred persistence adapter; the canon NIF and the measured line where native pays on the
  BEAM. ○ manuscript pending

## B3 · The Bus — EchoMQ, Valkey-native · `/bcs/bus` · ◐ in progress (landing + B3.1–B3.3 built; triad: [`specs/bcs.3.md`](specs/bcs.3.md))

> Part III: the bus on which identities and messages about identities travel — owned wire, declared keys, jobs as
> entities — backed by Valkey through the custom connector. Grounding: `content/bcs3.md`–`bcs3.6.md` + `bcsA.md`
> with six frozen rung records (`5/5 · 5/5 · 6/6 · 8/8 · 6/6 · 6/6`) and the connector gate (`PASS 8/8`;
> 454,483 pipelined ops/s against live Valkey 9.1.0; the `echomq:2.0.0` fence). All seven modules are
> manuscript-ready. Appendix B (the production connector) is specced with committed rungs but its prose is
> unwritten — living status (D-B3.2). Protocol depth doors to `/echomq`.

- **B3.1 · The Fence and the Keyspace** — `fence-and-keyspace` — the `emq:{q}:` key grammar, the gate at the
  key, the live fence read, binary discipline, the co-location slot law; the `PASS 5/5` rung (F1–F5). Dives:
  the-key-grammar · the-fence-live · the-co-location-law. **✓ built**
- **B3.2 · Jobs Are Entities** — `jobs-are-entities` — the `JOB` namespace (D-10); the three-field job row; the
  score-zero pending zset as FIFO + browse + time index in one; the idempotent enqueue script and the `EMQKIND`
  wire class; the `PASS 5/5` rung (J1–J5). Dives: the-job-row · enqueue-one-script · the-orders-dividend.
  **✓ built**
- **B3.3 · The State Machine in Lua** — `state-machine` — claim, complete, retry, dead-letter as single-script
  transitions; the `attempts` counter as the fencing token; the two-clocks law on the bus; the `PASS 6/6` rung
  (L1–L6). Dives: claim-the-token-mint · the-fencing-token · the-morgue-and-the-reaper. **✓ built**
- **B3.4 · Fair Lanes** — `fair-lanes` — per-group lanes under the ring invariant, the rotating claim, ceilings
  and pause/resume, park-don't-poll, the loop, the reap window closed; the `PASS 8/8` rung (G1–G8). Dives:
  the-ring-and-the-rotation · ceilings-and-pauses · park-dont-poll.
- **B3.5 · The Bus Meets the Stores** — `bus-meets-stores` — commands out of entities, results back into
  properties, ids the only cargo; exactly-once effect by provenance; the consumer as one more owner; the
  `PASS 6/6` rung (B1–B6). Dives: the-round-trip · exactly-once-by-name · one-more-owner.
- **B3.6 · Conformance and the Rival's Numbers** — `conformance` — the committed fourteen-scenario harness; the
  referee habit with derivations printed before measurements; Oban 2.18.3 on PostgreSQL 16.14 with its
  advantage in its own row; the `PASS 6/6` rung (C1–C6) + `CONFORMANCE 14/14`. Dives: the-committed-harness ·
  the-referee-habit · the-rivals-numbers.
- **B3.7 · Appendix A — The Connector** — `the-connector` — the purpose-built Elixir client on raw `:gen_tcp`:
  one-pass RESP2, EVALSHA-first declared-keys scripts, the typed fatal fence, client-side slots; eight gates
  against the live 8.1.8 (`emq_connector_check.out`, `PASS 8/8`). Dives: resp-one-pass · the-typed-fence ·
  measured-on-the-wire.

## B4 · EchoCache — the near-cache · `/bcs/cache` · ◐ in progress (landing + B4.1–B4.4 built; triad: [`specs/bcs.4.md`](specs/bcs.4.md))

> Part IV: branded keys, local speed, bus-driven coherence — the near-cache whose coherence message carries a
> mint-time version, against a comparison set whose coherence is deletion. Grounding: `content/bcs4.md` +
> `bcs4.1.md`–`bcs4.4.md` with four frozen rung records (each `PASS 6/6`, derive lines committed beside the
> measurements). B4.1–B4.4 are manuscript-ready; **chapter 4.5 is a manuscript TOC entry — B4.5 stays planned**
> (D-B4.2). Doors: `/redis-patterns` R1 (caching), `/echomq` (the bus the coherence rides).

- **B4.1 · Cache-Aside at ETS Speed** — `cache-aside` — the declared directory, single-flight fills, the 762 ns
  hit against the 31 µs wire, the jittered clock and the sweeper, the bound that degrades to pass-through; the
  `PASS 6/6` rung (E1–E6). Dives: declared-not-discovered · one-fill-per-herd · the-jittered-clock. **✓ built**
- **B4.2 · Coherence by Mint Time** — `coherence-by-mint-time` — the twenty-nine-byte message, newer-wins as a
  comparison of two names, the broadcast lane at 72 µs vs the job lane at 148 µs (the guarantee costs 2.1×);
  the `PASS 6/6` rung (F1–F6). Dives: the-twenty-nine-bytes · the-broadcast-lane · the-job-lane. **✓ built**
- **B4.3 · The Single Writer and the Ring** — `single-writer-ring` — two atomic sequences over preallocated ETS
  slots, order through batches, occupancy as the gauge, drop as a counted refusal, the storm drill; LMAX and
  the Disruptor as prior art; the `PASS 6/6` rung (G1–G6). Dives: two-sequences-one-table ·
  occupancy-and-the-bound · the-storm-drill. **✓ built**
- **B4.4 · The Lane That Remembers** — `the-lane-that-remembers` — per-group SQLite journals (the outbox + the
  last word per name), the crash seams closed, the bus dying and the lane replaying, coverage as compaction,
  the 3.5× price of memory; Litestream named, not built; the `PASS 6/6` rung (H1–H6). Dives:
  two-memories-one-file · the-bus-dies-the-lane-replays · coverage-and-the-price. **✓ built**
- **B4.5 · The Cache Referee** — `cache-referee` — Nebulex, Cachex, and Valkey's server-assisted tracking
  measured where they run. The manuscript plans this chapter; no comparative figure exists until it ships.
  ○ manuscript pending

## B5 · Go — the canon needs no linking · `/bcs/go` · ○ planned (manuscript pending)

> Part V: native u64 arithmetic, the measured case against crossing into C, and Go systems as full BCS citizens on
> the bus. The conformance evidence exists today (`content/echo_data/runtimes/go/brandedid`).

- **B5.1 · The Pure-Go Contract** — *manuscript chapter planned.*
- **B5.2 · Go Systems on the Bus** — *manuscript chapter planned.*

## B6 · Node 22+ — the brand in the type system · `/bcs/node` · ○ planned (manuscript pending)

> Part VI: `BrandedId<NS>` and the compile error as the gate; Rust paying its way through V8 via wasm; the native
> v2 Node implementation joining the fleet. The cross-runtime evidence exists today
> (`content/echo_data/runtimes/node`, the 200/400/400/404 gate row).

- **B6.1 · The Brand in the Type System** — *manuscript chapter planned.*
- **B6.2 · Rust on V8** — *manuscript chapter planned.*
- **B6.3 · echomq-node** — *manuscript chapter planned.*

## B7 · Production on Fly — the architecture deployed · `/bcs/fly` · ○ planned (manuscript pending)

> Part VII: app machines and the dedicated Valkey machine, the local replica, FLAME ephemeral job execution,
> observability and release. Door: the `/elixir` fly-deploy chapter.

- **B7.1 · Topology** — *manuscript chapter planned.*
- **B7.2 · The Local Replica** — *manuscript chapter planned.*
- **B7.3 · FLAME: Ephemeral Job Execution** — *manuscript chapter planned.*
- **B7.4 · Observability and Release** — *manuscript chapter planned.*

## B8 · The Trading System — the capstone · `/bcs/trading` · ◐ in progress (landing + B8.1–B8.2 built; spec: [`specs/bcs.8.specs.md`](specs/bcs.8.specs.md))

> Part VIII: the worked project assembled on the as-built tree — a trading platform. **Two-layer grounding
> (BCS.8-INV1/INV2):** the **substrate is real, shipped, actively-hardened source** — `EchoCache.Ring` et al.
> (`echo/apps/echo_cache/`), the EchoMQ bus (`echo/apps/echo_mq/`), the canon — carrying committed records (the
> lanes B3.4, the cache/ring/journal B4.1–B4.4, the claim check Appendix G, the connector referee Appendix H, the
> `hash32` audit) **and** a live rung-gated hardening program (`docs/echo_mq/emq.roadmap.md`); the chapter quotes
> those figures verbatim and teaches the substrate present-tense. Only the **trading consumer** — the
> `Exchange.*` / `Trading.Ledger` modules (no source yet) — is **PROPOSED**, the roadmap's "named consumer
> standing on this tree," taught in living-status voice with **no platform figure invented**. The design is the
> Operator's corpus under `docs/exchange/`. The four modules follow it: the engine, the memory, the strategies,
> the scale-out.

> **Now being built real (`docs/exchange/`).** The PROPOSED `Exchange.*` consumer is the design of the **Exchange
> Platform** (renamed from the trading corpus; the `trd.*` rung codename is kept), which now ships rung by rung on this
> same as-built tree. The first rung makes the door real: `Exchange.Gateway` — parse-don't-validate at the edge,
> `{units, nano}` integer money, branded ids minted at acceptance — at `trd.1.1`
> ([`docs/exchange/trd.1.1.specs.md`](../../exchange/trd.1.1.specs.md)). As each rung lands, the matching B8 module
> retires its living-status hedge for a built reference.

- **B8.1 · The Engine — Ring, Book, and Decider** — `engine` — the hot path: the Disruptor seat (the as-built
  `EchoCache.Ring`, `echo/apps/echo_cache/lib/echo_cache/ring.ex` — `publish/2` → `:ok`/`:dropped` counted), the
  single-writer Book draining a pure Decider (PROPOSED `Exchange.*`), price-time priority falling out of the id
  law. Grounds in `trading.patterns.md` + `trading.specs.md`; as-built ring record `bcs4.3.md` (`PASS 6/6`).
  Dives: the-disruptor-seat · the-decider · price-time-by-mint-order. **✓ built**
- **B8.2 · The Log and the Ledger** — `log-and-ledger` — the memory: the as-built `EchoCache.Journal` + pluggable
  `EchoCache.Shadow` (`echo/apps/echo_cache/`, record `bcs4.4.md` `PASS 6/6`), replay equals live; the PROPOSED
  `Trading.Ledger` double-entry in Postgres + idempotent projections. Dives: the-journal-and-the-shadow ·
  replay-equals-live · the-double-entry-ledger. **✓ built**
- **B8.3 · Strategies as Deciders** — `strategies` — a strategy is a Decider emitting intents; the four-stage
  pipeline; risk as gating deciders and the kill switch that is already a lane verb; the backtest is the live
  system replayed. Dives: the-strategy-is-a-decider · risk-and-the-kill-switch · the-backtest-is-the-system-replayed.
  *(design-grounded; PROPOSED platform)*
- **B8.4 · Fan-Out and the Scale-Out** — `scale-out` — claims-only on the bus (29 bytes, never an object),
  placement by the audited `hash32`, CP matching and AP market data on partition, the cross-shard saga. Dives:
  claims-only-on-the-bus · placement-by-the-audited-hash · cp-ap-on-partition. *(design-grounded; PROPOSED platform)*

---

## The doors

- **`/echomq`** — the bus protocol in depth: the `emq:{q}:` break, the Lua inventory, the conformance suite on
  Valkey. B3 is the manuscript's narrative of the same system the EchoMQ course teaches rung by rung.
- **`/redis-patterns`** — the substrate patterns applied: sorted sets, atomic Lua moves, locks, streams — the
  judgement layer under the bus.
- **`/elixir`** — the Portal engine and the umbrella where `echo_data` (the production identity library) lives.

## Tally

9 chapters (B0–B8) · 37 modules mapped to manuscript chapters (6 + 6 + 7 + 5 + 2 + 3 + 4 + 4, over Parts I–VIII;
Part IV grew from two planned chapters to five as the book shipped) · dives fixed per chapter triad at build
time. Built today: B0 + B1 built; B2 in progress (landing + B2.1–B2.5, 21 pages; B2.6 manuscript-pending); B3 in
progress (landing + B3.1–B3.3, 13 pages; B3.4–B3.7 manuscript-ready); B4 in progress (landing + B4.1–B4.4,
17 pages; B4.5 manuscript-pending); B8 in progress (landing + B8.1–B8.2, 9 pages, over the `docs/exchange/` design
corpus on the as-built + hardened echo substrate; B8.3–B8.4 next, the `Exchange.*` consumer PROPOSED and now being
built rung by rung — `Exchange.Gateway` at `trd.1.1`).

---

> The TOC maps; the [roadmap](bcs.roadmap.md) plans; the [chapter triads](bcs.md) define. Branded id format:
> `BCS` + Base62(snowflake), e.g. `BCS0NtBpC9oGGW`.
