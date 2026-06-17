# Branded Component System · course roadmap

> The delivery plan for the course: the chapter sequence as the manuscript's arc, the milestones that group it,
> the **grounding map** that fixes which manuscript chapter and which committed evidence each course chapter is
> drawn from, and the doors to the sibling courses. This file is the *plan and the grounding contract*; the
> structural map is [`bcs.toc.md`](bcs.toc.md) and each chapter's module ladder is its triad under
> [`specs/`](specs/bcs.0.md).

This is the program view above the chapter triads. The contract for *how* a chapter is specified and a page is
authored is [`bcs.md`](bcs.md); this file is *what the course teaches, in what order, grounded in what.*

**Not this file:** the manuscript ledger plans its own `content/bcs.roadmap.md` — a per-runtime implementation
brief for the book's code. That is a manuscript artifact, owned by the Author/Operator; this file is the course
roadmap.

## What the course delivers

The Branded Component System, taught as a course: the law in three clauses, the branded-snowflake identity
contract, the Elixir reference implementation, the EchoMQ 2.0 Valkey-native bus, the near-cache, the Go and Node
runtimes, the Fly deployment, and the trading system that assembles all of it. The through line is the
manuscript's own: **the only values that cross system boundaries are identities and messages about identities,
and identity is a contract** — and every claim on a page is backed by a committed output, quoted verbatim.

## Where this starts and ends

- **Start.** The reader knows components and queues as folklore — ECS from game engines, ids as database
  auto-increments, boundaries as package layout. The course assumes programming fluency, not architecture
  vocabulary.
- **End.** The reader can draw system boundaries, design an identity contract, read the order theorem and the
  placement hash as load-bearing properties, and follow the trading system's assembly — and can go deeper through
  the doors: `/echomq` for the bus protocol (spec authority [`echo_mq.md`](../../echo_mq/echo_mq.md)),
  [`/redis-patterns`](../../redis-patterns/redis-patterns.toc.md) for the substrate patterns.

## Architecture decision — course chapters mirror manuscript Parts, in the course's own visual identity

The course is organized **one chapter per manuscript Part** (B1–B8 ⇄ Parts I–VIII, B0 the orientation landing),
with module numbers mapping one-to-one to manuscript chapters (`B2.3` teaches `content/bcs2.3.md`). The
alternative — reorganizing the material by runtime or by pattern family — was rejected: the manuscript's Part
structure *is* the pedagogy (law → reference implementation → bus → cache → runtimes → production → capstone),
and a second structure would fork the truth the course exists to teach.

Two consequences:

- **The course tracks a living book.** Parts I–III are written (Part III in progress); Parts IV–VIII are TOC
  abstracts. Course chapters are built only over written manuscript; B4–B8 stay `planned` until their Parts ship,
  and their pages use the living-status voice ("the manuscript plans…").
- **The course renders in its own visual identity** — defined by the B0 landing, not the shared dark-editorial
  system (the decision of record in [`bcs.md`](bcs.md), with the MUST-NOT token list). The reversible seam: the
  identity is carried entirely inside `html/bcs/` pages; no shared asset changes.

## The course at a glance

| Chapter | Route | Theme (manuscript Part) | Grounding | Door | Status |
|---|---|---|---|---|---|
| **B0** Orientation | `/bcs` | the law, the id anatomy, the evidence ethic, the map | preface + `bcs1.md` + the contract | → `/echomq`, `/redis-patterns` | ✓ built ([`specs/bcs.0.md`](specs/bcs.0.md)) |
| **B1** Ideas Behind | `/bcs/ideas` | Part I — the conceptual floor | `bcs1.md`–`bcs1.5.md`, `bcs1.a1.md` | → `/elixir` (echo_data lives in Portal) | ✓ built ([`specs/bcs.1.md`](specs/bcs.1.md)) |
| **B2** The Elixir BCS Core | `/bcs/elixir-core` | Part II — the reference implementation | `bcs2.md`–`bcs2.5.md` (+2.6 per ledger) | → `/elixir` | ◐ B2.1–B2.5 built ([`specs/bcs.2.md`](specs/bcs.2.md)) |
| **B3** The Bus | `/bcs/bus` | Part III — EchoMQ, Valkey-native | `bcs3.md`–`bcs3.6.md`, `bcsA.md` (Part fully written) | → `/echomq` (the emq ladder), `/redis-patterns` | ○ specced ([`specs/bcs.3.md`](specs/bcs.3.md)) |
| **B4** EchoCache | `/bcs/cache` | Part IV — the near-cache | `bcs4.md`–`bcs4.4.md` (4.5 = TOC entry) | → `/redis-patterns` R1, `/echomq` | ○ specced ([`specs/bcs.4.md`](specs/bcs.4.md)) |
| **B5** Go | `/bcs/go` | Part V — the canon needs no linking | TOC abstracts 5.1–5.2; `echo_data/runtimes/go` | → `/echomq` (runtimes) | ○ manuscript pending |
| **B6** Node 22+ | `/bcs/node` | Part VI — the brand in the type system | TOC abstracts 6.1–6.3; `echo_data/runtimes/node` | → `/echomq` (runtimes) | ○ manuscript pending |
| **B7** Production on Fly | `/bcs/fly` | Part VII — machines, replicas, FLAME | TOC abstracts 7.1–7.4 | → `/elixir` (the fly-deploy chapter) | ○ manuscript pending |
| **B8** The Trading System | `/bcs/trading` | Part VIII — the capstone assembly | TOC abstracts 8.1–8.4; the namespace registry | — (the arrival) | ○ manuscript pending |

> **B8's consumer is now being built real — the Exchange Platform (`docs/exchange/`).** The capstone's `Exchange.*` is
> specified and shipped rung by rung as the **Exchange Platform** (renamed from the trading corpus; the `trd.*` codename
> kept), on this same as-built echo substrate. The first rung makes the door real: `Exchange.Gateway` — parse-don't-
> validate at the edge, `{units, nano}` integer money, the branded id as the venue idempotency key — at `trd.1.1`
> ([`docs/exchange/trd.1.1.specs.md`](../../exchange/trd.1.1.specs.md)). B8 teaches these as design; the Exchange
> Platform builds them.

## How the chapters compose — the dependency arc

```text
B0 Orientation        (the landing — the law, the id, the map)
     ▼
B1 Ideas Behind ──────▶ the law, the contract, the storage economics, time
     ▼
B2 Elixir BCS Core ───▶ systems as OTP apps, property stores, CHAMP, archetypes, relations
     ▼
B3 The Bus ───────────▶ EchoMQ 2.0 on Valkey: keyspace, jobs as entities, the Lua state machine
     │
     ├──────────────┬───────────────┐
     ▼              ▼               ▼
B4 EchoCache      B5 Go           B6 Node 22+
 (bus-driven       (the canon      (the type-system brand
  coherence)        unlinked)       + wasm crossing)
     └──────────────┴───────────────┘
                    ▼
B7 Production on Fly   (topology, replicas, FLAME, observability)
                    ▼
B8 The Trading System  (the decider over branded identities — the capstone)
```

B2 cannot precede B1 (the stores are meaningless without the contract), B3 needs B2 (jobs are entities — the bus
reuses the entity vocabulary), and B4–B6 are parallel surfaces over B3's bus and B2's stores, sequenced by
pedagogy, not hard dependency.

## The grounding map (canonical — cite these; never invent)

This table fixes which manuscript files and which committed evidence each course chapter draws on. It is the
source of truth for the grounding rule in [`bcs.md`](bcs.md). All paths are under
[`content/`](content/bcs.toc.md). Figures are quoted **verbatim** from the committed outputs; a number not present
in them does not appear on a page.

| Course chapter | Manuscript files | Committed evidence |
|---|---|---|
| B0 | `bcs.preface.md`, `bcs1.md`, `contract.md` | the canonical vector `hash32 = 234878118`; `MAX_PAYLOAD = "AzL8n0Y58m7"`; epoch `1704067200000`; the 41/10/12 split; `vectors.json` |
| B1 | `bcs1.md`, `bcs1.1.md` (+ its `.specs/.llms`), `bcs1.2.md`, `bcs1.3.md` (+ triad), `bcs1.4.md`, `bcs1.5.md`, `bcs1.a1.md`, `bcs.id-system.md` | `echo_data/runtimes/elixir/` rung 1.1 transcripts (`PASS 6/6`); `echo_data/bench/branding-vs-decimal/` (Rust 4.2×, C 2.8×); `echo_data/bench/valkey-id/` + `out/valkey_id_bench.out`; the September-2093 horizon |
| B2 | `bcs2.md`, `bcs2.1.md`–`bcs2.5.md` (2.6 exists in the ledger/git history only — say so) | `bcs_rung_2_2…2_5_check.exs` + frozen `.out`; the code drops `property_store.ex`, `branded_champ.ex`, `archetypes.ex`, `edge_store.ex`; the `ARC` namespace (D-8) |
| B3 | `bcs3.md`, `bcs3.1.md`–`bcs3.6.md`, `bcsA.md` (Part fully written; Appendix B = `bcsB.specs.md` only — living status, D-B3.2) | rung 3.1–3.6 frozen transcripts (`5/5 · 5/5 · 6/6 · 8/8 · 6/6 · 6/6`) + `emq_connector_check.out` (`PASS 8/8`); the `echo_mq/` modules (`keyspace`, `connector`, `resp`, `script`, `jobs`, `lanes`, `consumer`, `conformance`); 454,483 pipelined ops/s vs 29,456 sequential against live Valkey 9.1.0; the `echomq:2.0.0` fence; the `JOB` namespace (D-10); `CONFORMANCE 14/14`; the rival's row (Oban 2.18.3 / PostgreSQL 16.14, asymmetry stated first) |
| B4 | `bcs4.md`, `bcs4.1.md`–`bcs4.4.md` (4.5 is a TOC entry — living status, D-B4.2) | rung 4.1–4.4 frozen transcripts (each `PASS 6/6`, derive lines committed); the `echo_cache/` modules (`echo_cache`, `keyspace`, `table`, `coherence`, `ring`, `journal`); 762 ns hits vs 31 µs wire; 72 µs broadcast vs 148 µs job lane; 1,005,116 ring items/s; 143 µs journal pair |
| B5 | TOC abstracts 5.1–5.2 | `echo_data/runtimes/go/brandedid` (conformance + bench outputs, e.g. hash32 at 0.9586 ns) |
| B6 | TOC abstracts 6.1–6.3 | `echo_data/runtimes/node/` (TS brand + wasm); `docs/One-Contract-Three-Runtimes.md` (the 200/400/400/404 gate row) |
| B7 | TOC abstracts 7.1–7.4 | — (manuscript pending) |
| B8 | TOC abstracts 8.1–8.4 | the namespace registry in `contract.md` (`AST TXN PRT ORD RSK STR` reserved) |

The five historical articles under [`content/docs/`](content/docs/) are the **pre-series measured record**
(decisions D-2/D-5 in the ledger): citable everywhere as evidence, taught nowhere as chapters.

## Milestones

| Milestone | Chapters | What the reader can do at the end |
|---|---|---|
| **M1 · The door is open** | B0 | find the course, read the law, see the id anatomy, and know what evidence backs the series |
| **M2 · The law and the core** | B1–B2 | argue the three clauses, read the contract property by property, and follow the Elixir reference implementation |
| **M3 · The bus** | B3 | read the Valkey-native keyspace, jobs-as-entities, and the Lua state machine — with the `/echomq` door for protocol depth |
| **M4 · The fleet and the capstone** | B4–B8 | built as the manuscript's Parts IV–VIII ship |

## How the course is authored — the Author/Operator loop

- **Operator (the human)** writes the manuscript, settles the structure (this roadmap, the TOC, the chapter
  triads), and reviews each authored batch. The manuscript and its ledger are never edited by course authoring
  (decision D-7: ledger edits never ride behind gates).
- **Author (Claude)** expands a chapter triad into pages — landing, hubs, dives — each grounded per the map above,
  each gated to STATUS: PASS.

The loop per chapter is **spec → author → gate → review → adapt.** Feedback edits the spec; pages are never
authored ahead of the spec.

## Seams & open decisions

- **`html/llms.txt` is not edited.** The hand-authored site map frames "the eleven course series" and excludes
  every folder-routed developer course (`/echomq`, `/redis-patterns`, `/course/agile-agent-workflow` are absent);
  `/bcs` follows that precedent. Revisit when the map's framing changes.
- **No root-hub card.** The `/` landing carries the eleven learner series only; no developer course has a card
  there. `/bcs` follows suit.
- **`cmd/sitemap` `folderRouted` is not extended.** The slice omits `/redis-patterns` and `/echomq` today; `/bcs`
  defers identically. Adding all three is one future change.
- **The manuscript's internal links predate its re-homing.** Files under `content/` still carry relative links
  from the pre-move layout (`../One-Contract-Three-Runtimes.md`, `../../contract/contract.md`). Course docs cite
  the current paths; fixing the manuscript's own links is the Author/Operator's call.
- **Deploys are manual.** The Dockerfile `COPY html/bcs/` line ships the course on the next `fly deploy`; local
  verification cannot cover the deployed image.

## Conventions

- **The grounding rule** (the master discipline): every page cites the manuscript and its committed outputs;
  figures verbatim; living-status voice for unwritten Parts; no invented namespace, figure, script, or API.
- **Branded Snowflake ids** on every built page — a **`BCS…`** build stamp in the canonical footer (the course's
  own namespace, per D-8).
- **The spec system** is the contract: TOC maps, roadmap plans, chapter triads define; pages pass the ten
  jonnify-cms gates before they ship.
- **Voice.** Plain, specific, impersonal; the forbidden set (`revolutionary`, `blazing`, `magical`, `simply`,
  `just`, `obviously`, `effortless`), no first person, no exclamation, no perceptual verb applied to a tool.

## Map

- The structural map: [`bcs.toc.md`](bcs.toc.md).
- The spec-system contract + chapter map: [`bcs.md`](bcs.md).
- The chapter triads: [`specs/bcs.0.md`](specs/bcs.0.md) (the exemplar, shipped) ·
  [`specs/bcs.1.md`](specs/bcs.1.md) (B1, built) · [`specs/bcs.2.md`](specs/bcs.2.md) (B2, built to its
  manuscript edge) · [`specs/bcs.3.md`](specs/bcs.3.md) (B3, specced — all seven modules manuscript-ready) ·
  [`specs/bcs.4.md`](specs/bcs.4.md) (B4, specced — B4.1–B4.4 manuscript-ready, B4.5 pending); B5–B8 triads are
  authored as each manuscript Part ships.
- The manuscript: [`content/bcs.toc.md`](content/bcs.toc.md) (reading order) ·
  [`content/bcs.progress.md`](content/bcs.progress.md) (status + decisions) ·
  [`content/contract.md`](content/contract.md) (the canon).

---

> Part of the jonnify toolkit. The roadmap plans and fixes the grounding; the triads define; both are settled
> before any page is built. Branded id format: `BCS` + Base62(snowflake), e.g. `BCS0NtBpC9oGGW`.
