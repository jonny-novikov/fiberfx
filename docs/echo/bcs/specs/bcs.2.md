# BCS.2 · The Elixir BCS Core — the reference implementation, taught

> The third rung of the BCS course and its second full chapter: **B2 · The Elixir BCS Core**
> (`/bcs/elixir-core`), teaching manuscript Part II — the law landed on OTP: a system as an application, property
> stores on ETS, the CHAMP forest, archetypes as data, and relations as systems. One chapter landing, six module
> hubs (B2.1–B2.6), dives fixed per module in the ladder. Spec of record:
> [`bcs.2.specs.md`](bcs.2.specs.md) · agent guide: [`bcs.2.llms.md`](bcs.2.llms.md).

## Why

B1 argued the law; B2 builds it. Part II is the manuscript's reference implementation — the place the noun
"system" acquires a runtime shape: a supervised process owning a private table behind an export list, on the
platform where the law's first clause is the language's native grain rather than a discipline bolted on. The
Part is **manuscript-ready** (`content/bcs2.md`–`bcs2.5.md`, five chapters written), and its evidence is
committed and frozen: five rung records on file (`bcs_rung_2_1`…`2_5_check.out`, tallying `5/5 · 5/5 · 7/7 ·
5/5 · 5/5`), the four code drops (`property_store.ex`, `branded_champ.ex`, `archetypes.ex`, `edge_store.ex`),
and the `ARC` namespace registered as a decision. So B2 is the course's second buildable chapter, and the one
that carries the abstractions of Part I (the contract, the order theorem, the placement hash, the two clocks)
into working Elixir the reader can trace gate by gate.

This rung builds two modules of the six — **B2.1** and **B2.2** — establishing the OTP-application surface and
the ETS property store. B2.3–B2.6 are specced in the ladder and built on later rungs (B2.6 waits for its
manuscript chapter; its rung exists in the ledger, its prose does not).

## What

The chapter, and the first batch's slice of it:

1. **The chapter landing** — `/bcs/elixir-core` (`html/bcs/elixir-core/index.html`): Part II's teaching arc
   — the law landed on OTP (the three clauses on the BEAM), the seven design guidelines, the six chapters —
   over six module cards, closing with an "Up next" grid (B3–B8 as non-anchor `soon` cards). Orchestrator-only.
2. **B2.1 · A System Is an OTP Application** — hub `otp-application/index.html` + three dives: `the-export-list`
   (R1 boundary + R5 declared kinds), `existence-and-the-kill` (R2 existence-not-data + R3 checkpoints are
   rows), `the-blast-radius` (R4 `one_for_one`, start order, the Go supervise loop). Teaches `content/bcs2.1.md`,
   grounded in `bcs_rung_2_1_check.out` (`PASS 5/5`).
3. **B2.2 · Property Stores on ETS** — hub `property-stores/index.html` + three dives: `the-only-key`
   (P1 the database shape + P2 the decimal refused `:invalid`), `chronology-without-a-column` (P3 `page_desc` +
   P4 `window/3`), `the-review-performed` (P5 the surface grew by exactly one export). Teaches
   `content/bcs2.2.md`, grounded in `bcs_rung_2_2_check.out` (`PASS 5/5`) and the real `property_store.ex`.

B2.3 (`champ`), B2.4 (`archetypes`), B2.5 (`relations`), B2.6 (`boundary-acceleration`) are fixed in the ladder
and built on later rungs.

Proof is mechanical: every page at STATUS: PASS across the ten gates (`--require-refs`), every figure traced to
its committed source, the md mirror authored first for every route.

## Who

- **The reader** — the engineer or agent who has the architecture vocabulary from B1 and now needs the
  reference implementation: how a system becomes an OTP application, why existence is the supervisor's and data
  is not, why the branded id is the only key, and how chronology is read off the keyspace without a timestamp
  column.
- **The Operator** — reviews the batch and the chapter's grounding against the frozen rung records.
- **The authoring agents** — one `bcs-expert` per module (B2.1, B2.2 in this batch), briefed from
  [`bcs.2.llms.md`](bcs.2.llms.md), which carries the senior-verified grounding bank (agents cite from it and
  the named sources; they re-derive nothing and invent nothing).

## When

After B1 (built: the law, the contract, the chooser, the translation, the clocks, the trial) and before B3 —
the hubs' "Up next" arcs and the landing relink assume B0–B1 are live and B3–B8 are not. Within the batch: the
chapter landing first (orchestrator-only), then the two module agents (a single wave of two — B2.1 + B2.2),
each authoring its hub and three dives; deferred cross-module links restored after the wave lands.

## Where

- Pages: `html/bcs/elixir-core/` (landing, the `otp-application` and `property-stores` module dirs with three
  dives each; the four later module dirs follow on their rungs); md mirrors:
  `docs/echo/bcs/markdown/elixir-core/**`.
- Grounding (read-only): `content/bcs2.md`, `bcs2.1.md`–`bcs2.5.md`, with the rung records and code drops under
  `content/echo_data/runtimes/elixir/` (the per-module map is in [`bcs.2.llms.md`](bcs.2.llms.md)).
- Relink targets (orchestrator-only): `html/bcs/index.html` (the B2 card + footer column),
  `html/bcs/elixir-core/index.html` (the B2.1/B2.2 module cards), `docs/echo/bcs/bcs.toc.md`.

## How

Orchestrated by `/bcs-write elixir-core …`: the orchestrator authors the chapter landing from this triad
(bootstrapped from a built B1 chapter landing), fans out one `bcs-expert` per module with the
[`bcs.2.llms.md`](bcs.2.llms.md) brief, adversarially verifies every page (gates + figure provenance + identity
leak + voice), then relinks the course landing and the chapter landing and syncs the TOC. One wave of two
module agents; cross-module links between the concurrent siblings are deferred and restored post-build. No git
anywhere; the Operator commits out-of-band.

## Decisions

- **D-B2.1 — The dive partition slices the chapter's own gates.** Each module's dives follow the manuscript
  chapter's gate structure (B2.1's R1–R5, B2.2's P1–P5), recorded in the spec's module ladder; agents do not
  redesign them. (The D-B1.1 discipline, applied to Part II.)
- **D-B2.2 — Two modules this rung; the chapter's other four are specced, not built.** B2.1 and B2.2 ship in
  this batch; B2.3–B2.5 are manuscript-ready ladder rows built on later rungs; **B2.6 stays `planned` until its
  manuscript chapter (`bcs2.6.md`) is written** — its rung (`bcs_rung_2_6_check.out`, `PASS 5/5`) is committed,
  but the course teaches the prose chapter, not the bare rung, so B2.6 takes the living-status voice.
- **D-B2.3 — The frozen-record ethic is taught, not only obeyed.** Chapter 2.2's own decision — *evidence
  outputs are frozen; scripts evolve with the surface, committed records do not* — is a lesson on the
  `the-review-performed` dive, where the 2.1 record is shown as the pre-amendment surface evidence.
- **D-B2.4 — The relink is the batch's last act.** The B2 card on the course landing flips from a non-anchor
  `soon` card to a live `<a>` only after every page in the batch holds STATUS: PASS; the chapter landing's
  B2.1/B2.2 cards flip in the same final pass. Full links PASS at every intermediate state.
- **D-B2.5 — References extend the vetted registry with Part II's own citations.** Part II cites the Erlang/OTP
  `supervisor` and `ets` documentation, Steindorfer & Vinju (CHAMP, OOPSLA 2015), West 2007, the Gamma
  composition-over-inheritance interview, and Codd 1970. These URLs are vetted for B2 pages; nothing outside the
  union of this list and the B0/B1 registry.

## Boundaries

This rung builds Part II's B2.1 and B2.2 pages and specs the rest of the chapter. It does not author B3+ pages,
does not edit the manuscript or its ledger (`content/**`), does not touch shared assets, other courses, or the
server wiring (already shipped with bcs.0), and does not deploy. Where a dive meets the bus or the persistence
engine in depth, it doors to `/echomq`, `/redis-patterns`, and `/elixir` instead of teaching them. The native
codec and the granted-table acceleration belong to B2.6 (manuscript pending) — referenced by name, not taught
here.

## Companion files

[`bcs.2.specs.md`](bcs.2.specs.md) (the spec of record: the module ladder, invariants, stories, DoD) ·
[`bcs.2.llms.md`](bcs.2.llms.md) (the agent guide: the verified grounding bank for B2.1/B2.2, per-module briefs,
commands) · the course docs ([`../bcs.md`](../bcs.md) · [`../bcs.toc.md`](../bcs.toc.md) ·
[`../bcs.roadmap.md`](../bcs.roadmap.md)) · the B0/B1 exemplar triads ([`bcs.0.md`](bcs.0.md) ·
[`bcs.1.md`](bcs.1.md)) · the manuscript chapters (`../content/bcs2.md`, `bcs2.1.md`–`bcs2.5.md`) and the
committed evidence under `../content/echo_data/runtimes/elixir/`.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Manuscript: ../content/bcs.toc.md
