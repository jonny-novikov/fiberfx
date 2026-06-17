# BCS.8 · spec of record

> The authoritative spec for the B8 chapter (**The Trading System — the capstone**, `/bcs/trading`):
> deliverables, the two-layer grounding discipline, the module ladder with the fixed dive partition, the
> acceptance stories folded in, and the Definition of Done. **B8 grounds in a design corpus, not a manuscript
> Part.** The BCS manuscript's Part VIII (`bcs8*.md`) is unwritten; in its place the Operator has authored the
> **trading suite design** under [`../../../trading/`](../../../trading/) — `trading.md` (front door),
> `trading.specs.md` (system spec), `trading.roadmap.md` (the 8-rung ladder), `trading.patterns.md` (the Decider
> and the Disruptor argued in depth), `trading.strategies.md` (the strategy patterns). That corpus is **status
> PROPOSED** — a design and expertise corpus, not a record. B8 teaches the capstone *design*, grounded on the
> **as-built BCS records** it composes. Chapter doc lives inline here (no separate `bcs.8.md` yet); agent guide
> folds into the per-module briefs of `/bcs-write`.

## The two-layer grounding discipline (read first — the master rule for B8)

B8 teaches a trading platform built **on a real, shipped, actively-hardened substrate**. The line is between the
*substrate* (as-built code) and the *trading consumer* (the proposed `Exchange.*` suite) — two layers, two
voices, never confused.

1. **The substrate — AS-BUILT SOURCE, shipped and actively hardened.** The primitives the platform composes are
   **real Elixir modules living in the echo umbrella**, not a design and not a frozen drop:
   - `EchoCache.Ring` — `echo/apps/echo_cache/lib/echo_cache/ring.ex` (`publish/2` → `:ok`/`:dropped` counted,
     `occupancy/1`, `stats/1`, the two-atomics tail/head, edge-triggered wakes, the single-producer drain). Also
     `EchoCache.{Table, Journal, Coherence, Shadow, Litestream, Keyspace}` in the same app.
   - `EchoMQ.{Jobs, Lanes, Consumer, Keyspace, Conformance, Pool, Pump, Backoff, Repeat}` —
     `echo/apps/echo_mq/lib/echo_mq/` — with `EchoWire` (`echo/apps/echo_wire`) and the canon `EchoData`
     (`echo/apps/echo_data`).

   These carry **committed records** (the fair lanes `bcs3.4.md` `PASS 8/8`; cache · ring · journal `bcs4.1.md`–
   `bcs4.4.md` each `PASS 6/6`; the claim check `content/bcsG.md`; the connector referee `content/bcsH.md` +
   `bcsH.specs.md`; the hash audit `bcs_hash_audit.out`; the canon `contract.md` + `vectors.json`) **and** a live
   hardening program: **`docs/echo_mq/emq.roadmap.md`** — "all EchoMQ code converges in `echo/apps/echo_mq` …
   measured, rung-gated code," three movements (0 · the migration landed; I · the Core — scheduler/retry,
   migration path, parent-flow; II · groups · batches · lifecycle · cache-deepened · conformance/benchmark),
   `emq.0` shipped (Apollo BUILD-GRADE, 2026-06-13), `emq.1` ratified. **Every substrate figure a B8 page quotes
   is verbatim from its committed record, source-labelled** (BCS.8-INV1) — the same law as B1–B4 — and the
   substrate is taught present-tense (it exists and is hardened), citing the umbrella source path where apt.

2. **The trading consumer — PROPOSED, living-status voice.** The trading platform's own modules
   (`Exchange.Gateway`, `Exchange.Book`, `Exchange.OrderBook`, `Exchange.Decider`, `Exchange.Projection`,
   `Exchange.Placement`, `Trading.Ledger`) **do not exist yet — no `Exchange.*` source is in the umbrella.** They
   are the roadmap's **named downstream consumer**: *"the proposed `Exchange.*` suite standing on exactly this
   tree; the program's named consumer"* (`emq.roadmap.md`). B8 teaches them in **design voice** — "the Book is
   designed to drain…", "the Decider, PROPOSED, returns…", "the walking skeleton will…" — attributed to
   `docs/trading/*.md`, and **no platform match/throughput/fill number is invented** (BCS.8-INV2; the corpus's own
   law: "the first rung's harness produces the first number this platform may ever claim"). The only numbers on a
   B8 page are (a) an as-built substrate figure from its named committed record, or (b) an external published
   figure from a cited source (LMAX's *"6 million orders per second on a single thread"*), quoted with attribution.

The sharp scoping (do not blur it): the **Ring/bus/cache/journal exist and are measured** — their numbers are
real; it is the **trading engine's match/fill numbers that do not exist yet**. "PROPOSED" qualifies `Exchange.*`
and `Trading.Ledger`, never the substrate. This is not authoring ahead of the book: the substrate is shipped and
the design is written; only the trading platform's *evidence* is future, and B8 never asserts it.

## Deliverables

- **BCS.8-D1 — The chapter landing.** `html/bcs/trading/index.html` (+ md mirror `../markdown/trading/index.md`):
  the capstone's framing — the four jobs that pull apart, the three messaging shapes each served by its own
  primitive, the master invariant, the four-module arc over four module cards (all non-anchor `soon` until
  built), the three milestones (A · the walking skeleton, B · the durable core, C · the scale-out), the as-built
  floor it stands on, ≥1 interactive, References, pager (prev `/bcs/cache`, next the first built hub), full
  chrome. Orchestrator-only; bootstraps from the built B4 chapter landing. [US: BCS.8-US1]
- **BCS.8-D2 — Four module hubs.** One per ladder row, each: the module's framing from the trading corpus, its
  three dive cards, ≥1 interactive, a source-labelled evidence block (the as-built record it composes, quoted
  verbatim; OR — where the module teaches a PROPOSED design — a `figure`-framed *design* block clearly marked
  PROPOSED and attributed to `docs/trading/`), References, pager (prev = chapter landing, next = own first dive).
  [US: BCS.8-US1]
- **BCS.8-D3 — Twelve dives.** Three per module per the ladder's dive column, each a full lesson: the corpus's
  material for that slice, ≥2 interactives, evidence (as-built verbatim / design-PROPOSED attributed),
  References, a pager chaining hub → dive1 → dive2 → dive3 → hub. [US: BCS.8-US1]
- **BCS.8-D4 — The relink + sync + verification.** The course landing's B8 card flips live with the first green
  batch (footer too), the chapter landing's cards flip per batch, `bcs.toc.md`'s B8 section is rewritten to this
  four-module ladder, and the batch passes the verification sequence. [US: BCS.8-US2]

## The module ladder (the fixed dive partition — D-B8.1)

The four modules follow the trading corpus's own structure: the engine, the memory, the strategies, the
scale-out. Module slugs sit under `/bcs/trading/`.

| Module | Slug · route | Grounds in (design) | As-built floor (committed) | Dives |
|---|---|---|---|---|
| **B8.1** | `engine` | `trading.patterns.md` (the Decider + the Disruptor), `trading.specs.md` (the Disruptor seat, the pure book), `trading.md` (the three shapes, the master invariant) | `EchoCache.Ring` (`bcs4.3.md`, `PASS 6/6`), the canon/`BrandedTree` (Appendix F), LMAX (Fowler/Disruptor) | `the-disruptor-seat` (the Ring as bounded ingress — `publish/2` answers `:ok`/`:dropped`, the drop counted; one drainer; what transfers from LMAX and what the BEAM does not copy; the chase sequence is the branded Snowflake *inside* the data, `page_after/4`) · `the-decider` (the pure core `initialState`/`decide`/`evolve` (Chassaing); **event** sourcing not command sourcing; testability·replay·audit as corollaries of the signatures; functional-core/imperative-shell — `Exchange.Book` the shell, `Exchange.Decider`/`OrderBook` pure, all PROPOSED) · `price-time-by-mint-order` (the order book as a price ladder per side over `gb_trees`, each level a FIFO resolved by branded **mint order**, so price-time priority falls out of the id law rather than a comparator; the single-writer reconcile — publishes equal applies plus counted drops) |
| **B8.2** | `log-and-ledger` | `trading.specs.md` (the log, the regulated ledger), `trading.roadmap.md` (TRD.3, TRD.5) | `EchoCache.Journal` (`bcs4.4.md`, `PASS 6/6`), the Shadow (Appendix D + the shadow rung), the order theorem (Appendix F) | `the-journal-and-the-shadow` (one `EchoCache.Journal` per book — append, dedup, fold-to-state replay — under a pluggable `EchoCache.Shadow`: Litestream in production, the Copy shadow on a laptop, the same contract; milestone-A event store; the move to per-instrument stream lanes is milestone B, the conn.1–conn.2 recorded dependency) · `replay-equals-live` (state *is* the fold of the log; the Chapter 4.4 replay posture re-gated per book; recovery is replay, not a feature) · `the-double-entry-ledger` (settled money posts double-entry in Postgres, one `Ecto.Multi` per posting; the stream is the source of truth for *unsettled* state, the Postgres ledger the regulated record of *settled*; projections fold the log idempotently into Tables) |
| **B8.3** | `strategies` | `trading.strategies.md` (the seven strategy patterns) | the lanes' pause/resume/limit (`bcs3.4.md`, the kill switch), Tables (`bcs4.1.md`), the claims bus (`bcs4.2.md` + Appendix G) | `the-strategy-is-a-decider` (a strategy is `decide`/`evolve` one level up, emitting **intents, never orders**; inputs are events including its own fills; **event time, not wall time** (the mint instant, replayable); the supervised host; backtest-live identity) · `risk-and-the-kill-switch` (the four-stage pipeline — signal · sizing · risk · execution; risk as gating deciders, `pass`/`clamp`/`refuse`; the **kill switch is a lane verb** — Chapter 3.4's committed pause/resume/limit per strategy id; the OMS state machine, idempotent by branded intent id) · `the-backtest-is-the-system-replayed` (the parity law — the backtest is the live system replayed, one `decide`, the fill model the one swapped seam; why backtests lie — selection bias under multiple testing, Bailey et al.; every trial a record; shadow → canary → full-lane promotion as lane wiring) |
| **B8.4** | `scale-out` | `trading.specs.md` (the bus/claims, placement & partitions), `trading.roadmap.md` (TRD.4, TRD.6–8), `trading.md` (the milestones) | `EchoCache.Coherence` (`bcs4.2.md`), the claim check (Appendix G), the hash audit (`bcs_hash_audit.out`), `Keyspace` hash tags, the connector referee (Appendix H) | `claims-only-on-the-bus` (market data as 29-byte `(id, version)` **claims, never objects** — the Appendix G law; coherence broadcast + RESP3 tracking on the data connection; the immutable term cache; reads through declared Tables, newer-wins by mint order) · `placement-by-the-audited-hash` (`Exchange.Placement` (PROPOSED): a consistent ring over `EchoData.BrandedId.hash32/1` — the hash whose cross-runtime agreement is the audited record `bcs_hash_audit.out`; data co-location by `Keyspace` hash tags, one slot per book; scale is **sharding, not splitting** — one deployable) · `cp-ap-on-partition` (on partition: matching is **CP** — orders for an unreachable book are refused, never split-brained; market data is **AP** — a stale tick is served and marked; cross-shard trades a **saga** over the log with compensating events, the rule named at TRD.8; the three milestones A/B/C) |

Pager chain: chapter-landing pager prev `/bcs/cache` · next the first built hub; hub prev = chapter landing,
next = own first dive; dives chain hub → dive1 → dive2 → dive3 → back to the hub.

## Invariants

- **BCS.8-INV1 (as-built figures verbatim)** — every number, gate line, key shape, or id a page quotes from the
  as-built floor is exact as its committed source records it (`bcs3.4`, `bcs4.1`–`bcs4.4`, `bcsG`, `bcsH`,
  `bcs_hash_audit.out`, the canon). Each module hub carries a source-labelled evidence block. Re-derive nothing.
- **BCS.8-INV2 (no invented platform figure — the PROPOSED rule)** — the trading platform has produced no
  measurements; **no page invents a platform latency, throughput, or fill number.** Every `Exchange.*` module
  and every platform-level behavior is taught in design/living-status voice ("designed to…", "PROPOSED", "the
  walking skeleton will…"), attributed to `docs/trading/*.md`. External published figures (LMAX 6M/s) are quoted
  with their citation only. This is the D-B4.2 living-status discipline, applied to a whole chapter.
- **BCS.8-INV3 (identity)** — every page copies the contract-sheet system from a built BCS page (bootstrap: the
  B4 chapter landing / a built B4 hub / a built B4 dive); none of the dark-editorial MUST-NOT tokens appear.
- **BCS.8-INV4 (chrome + stamps)** — segmented clickable route-tag, canonical 3-column footer, a fresh `BCS…`
  stamp per page (minted + decode-verified), the static timestamp dd updated.
- **BCS.8-INV5 (md-first)** — `docs/echo/bcs/markdown/trading/<route>.md` exists for every page, authored before
  its HTML.
- **BCS.8-INV6 (doors)** — protocol depth doors to `/echomq`, substrate patterns to `/redis-patterns`, the
  umbrella + the decider/strategy core to `/elixir`. Internal `Related` links resolve to built routes only;
  unbuilt B-chapters and the PROPOSED `Exchange.*` modules are named in `<strong>`, never anchored.
- **BCS.8-INV7 (the two patterns taught with their alternatives)** — where a page teaches the Decider or the
  Disruptor seat, it carries the corpus's *alternatives-weighed* honesty (the mutating aggregate; the unbounded
  mailbox; GenStage/Broadway; a stream as ingress) — the design's reasoning, not a bare assertion (the
  `trading.patterns.md` discipline).

## Acceptance stories (folded)

- **BCS.8-US1 — The reader.** As a reader who has B1's contract, B2's stores, B3's bus, and B4's cache, I want
  the capstone taught as a chapter — landing → module → dive — showing how the proven primitives compose into a
  trading platform, with the as-built parts cited from their records and the new parts honestly marked PROPOSED,
  so that the engine, the log and ledger, the strategies, and the scale-out are learnable without opening the
  repository.
  - Given a batch ships, when I open `/bcs/trading`, then its built modules are live cards and their dives
    resolve; when I open any dive, then every as-built figure matches its committed source and every platform
    claim reads as design, not as a measurement.
  - Given JavaScript is disabled, when I open any B8 page, then every section is readable and the interactives
    degrade to static diagrams.
  - Encodes BCS.8-INV1, BCS.8-INV2, BCS.8-INV3. Priority: must · Size: 8 · Implements: BCS.8-D1/D2/D3.
- **BCS.8-US2 — The Operator.** As the Operator, I want every batch gated and the views synced, so the course's
  living maps stay truthful and the B8 ladder reflects the trading corpus.
  - Given any page in a batch, when the gate command runs, then STATUS: PASS on all ten gates.
  - Given a batch completes, when I open `/bcs`, then the B8 card state is truthful and `bcs.toc.md`'s B8 section
    matches this four-module ladder.
  - Encodes BCS.8-INV4, BCS.8-INV5. Priority: must · Size: 3 · Implements: BCS.8-D4.
- **BCS.8-US3 — The authoring agent.** As a module agent, I want a brief that names my grounding corpus, my
  as-built records, my dives, my sources, and my pager, so that I build without inventing structure or a figure.
  - Given this spec + the trading corpus, when I author my module, then every as-built fact I cite appears in its
    named record character-for-character, every platform claim is design-voiced and attributed, and my pages
    touch only my module's routes.
  - Encodes BCS.8-INV1, BCS.8-INV2, BCS.8-INV6, BCS.8-INV7. Priority: must · Size: 2 · Implements: D2, D3.

Coverage: D1→US1 · D2→US1,US3 · D3→US1,US3 · D4→US2.

## Definition of Done (per module; the chapter closes after B8.4)

- [ ] md mirrors under `docs/echo/bcs/markdown/trading/` (landing + each built hub + its 3 dives), each authored
  before its HTML.
- [ ] Pages under `html/bcs/trading/`, each STATUS: PASS via the gate command.
- [ ] As-built figure-provenance audit: every as-built number re-found in its committed source; the composed
  record quoted verbatim in a source-labelled block.
- [ ] PROPOSED-honesty audit: no platform latency/throughput/fill number invented; every `Exchange.*` behavior
  reads as design (grep the page for any bare platform measurement — there must be none).
- [ ] Identity audit: `grep -rn 'Cormorant\|Manrope\|PT Serif' html/bcs/trading/` empty; no `.chap`/`.mods`/`.mod`.
- [ ] Fresh `BCS…` stamps, each decode-verified.
- [ ] Course landing relinked (B8 card + footer) and chapter landing relinked per batch, re-gated PASS;
  `bcs.toc.md` synced to this ladder.
- [ ] Live crawl: every new route 200 on `:8765`; `/bcs` still 200.
- [ ] No trading-corpus file, manuscript file, ledger, shared asset, or sibling-course file edited. No git run.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Trading corpus:
[`../../../trading/trading.md`](../../../trading/trading.md) ·
[`trading.specs.md`](../../../trading/trading.specs.md) ·
[`trading.patterns.md`](../../../trading/trading.patterns.md) ·
[`trading.strategies.md`](../../../trading/trading.strategies.md) ·
[`trading.roadmap.md`](../../../trading/trading.roadmap.md)
