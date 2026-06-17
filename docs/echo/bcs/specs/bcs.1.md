# BCS.1 · Ideas Behind — the conceptual floor, taught

> The second rung of the BCS course and its first full chapter: **B1 · Ideas Behind** (`/bcs/ideas`), teaching
> manuscript Part I — the law, the contract read as architecture, the storage economics, the ECS translation,
> the time inside the name, and the encode trial. One chapter landing, six module hubs, twenty dives. Spec of
> record: [`bcs.1.specs.md`](bcs.1.specs.md) · agent guide: [`bcs.1.llms.md`](bcs.1.llms.md).

## Why

B0 opened the door; behind it there is no room yet. Part I is the manuscript's conceptual floor — every later
Part cites it instead of re-arguing it — and it is **fully written** (`content/bcs1.md`–`bcs1.5.md`,
`bcs1.a1.md`), with its evidence committed: the rung 1.1 transcript, the Valkey storage table, the
five-runtime encode record, the normative vectors. So B1 is the first chapter the course can build without
waiting on the book, and the first batch that exercises the course's machinery end to end: the contract-sheet
identity beyond the landing (the first chapter-landing, hub, and dive surfaces), the fan-out via `bcs-expert`,
and the relink that turns the landing's first `soon` card into a live link.

## What

Twenty-seven pages over three surfaces, all derived from the B0 exemplar:

1. **The chapter landing** — `/bcs/ideas` (`html/bcs/ideas/index.html`): Part I's teaching arc (the law → the
   contract → the economics → the translation → time → the trial) over six module cards, closing with an
   "Up next" grid of B2–B8 (non-anchor `soon` cards).
2. **Six module hubs** — one per manuscript chapter, module numbers mapping one-to-one
   (`B1.3` teaches `content/bcs1.3.md`): `system-substrate` · `identity-contract` · `id-system` ·
   `ecs-to-bcs` · `time-inside-the-name` · `branding-beats-its-own-integer` (the appendix, promoted to module
   B1.6 per the course TOC).
3. **Twenty dives** — the per-module ladders fixed in [`bcs.1.specs.md`](bcs.1.specs.md) (3 or 4 per module),
   each a full lesson with verbatim frozen-transcript evidence, ≥2 interactives, References, and a pager.

Proof is mechanical: every page at STATUS: PASS across the ten gates (`--require-refs`), every figure traced to
its committed source, the md mirror authored first for every route.

## Who

- **The reader** — the engineer or agent who needs the architecture vocabulary: the three clauses with their
  failure modes, the four contract properties, the measured chooser, the ECS translation table, the law of two
  clocks, and the whole-system cost accounting.
- **The Operator** — reviews the first fanned-out batch and the identity's behavior on new surfaces.
- **The authoring agents** — one `bcs-expert` per module, briefed from [`bcs.1.llms.md`](bcs.1.llms.md), which
  carries the senior-verified grounding bank (agents cite from it and the sources; they re-derive nothing and
  invent nothing).

## When

After bcs.0 (shipped: the landing, the route, the identity) and before B2 — the hubs' "Up next" arcs and the
landing relink assume B0 is live and B2–B8 are not. Within the batch: the chapter landing first
(orchestrator-only), then module waves of ≤2 concurrent heavy agents, dives riding with their module's agent.

## Where

- Pages: `html/bcs/ideas/` (landing, six module dirs, twenty dive files); md mirrors:
  `docs/echo/bcs/markdown/ideas/**`.
- Grounding (read-only): `content/bcs1.md`, `bcs1.1.md`–`bcs1.5.md`, `bcs1.a1.md`, `contract.md`,
  `vectors.json`, `bcs.id-system.md`, and the evidence under `content/echo_data/` + the bench records the
  chapters quote. The per-module map is in [`bcs.1.llms.md`](bcs.1.llms.md).
- Relink targets (orchestrator-only): `html/bcs/index.html` (the B1 card + footer column),
  `docs/echo/bcs/bcs.toc.md`.

## How

Orchestrated by `/bcs-write ideas …`: the orchestrator authors the chapter landing from this triad (the first
chapter-landing surface bootstraps from the B0 exemplar), fans out one `bcs-expert` per module with the
[`bcs.1.llms.md`](bcs.1.llms.md) brief, adversarially verifies every page (gates + figure provenance + identity
leak + voice), then relinks the course landing and syncs the TOC. Waves of ≤2 module agents; cross-module links
between concurrent siblings are deferred and restored post-build. No git anywhere; the Operator commits
out-of-band.

## Decisions

- **D-B1.1 — The dive partition is fixed here.** Each module's dives slice its manuscript chapter's own
  structure (the transcript, the properties, the tables, the deaths, the clocks, the runtimes) — recorded in
  the spec's module ladder; agents do not redesign them.
- **D-B1.2 — The appendix is a module.** `bcs1.a1.md` is taught as **B1.6 · Branding Beats Its Own Integer**
  (slug `branding-beats-its-own-integer`), not as a dive of B1.3 — it carries its own measured record and its
  own arc (per the course TOC).
- **D-B1.3 — References extend the vetted registry with the manuscript's own citations.** Part I's chapters
  cite their sources precisely (Erlang/OTP ets docs, the Go share-memory codewalk, Appleby's SMHasher,
  Twitter's Snowflake announcement, Söderqvist's hash-table deep dive, the Valkey streams/XADD docs, West 2007,
  Weissflog 2018, Lamport 1978, Chassaing). These URLs are vetted for B1 pages; nothing outside the union of
  this list and the B0 registry.
- **D-B1.4 — The relink is the batch's last act.** The B1 card on the course landing flips from a non-anchor
  `soon` card to a live `<a>` only after every page in the batch holds STATUS: PASS — full links PASS at every
  intermediate state.

## Boundaries

This rung builds Part I's pages only. It does not author B2+ pages, does not edit the manuscript or its ledger,
does not touch shared assets, other courses, or the server wiring (already shipped with bcs.0), and does not
deploy. Where a dive meets the bus or the engine in depth, it doors to `/echomq` and `/redis-patterns` instead
of teaching them.

## Companion files

[`bcs.1.specs.md`](bcs.1.specs.md) (the spec of record: the module ladder, invariants, stories, DoD) ·
[`bcs.1.llms.md`](bcs.1.llms.md) (the agent guide: the verified grounding bank, per-module briefs, commands) ·
the course docs ([`../bcs.md`](../bcs.md) · [`../bcs.toc.md`](../bcs.toc.md) ·
[`../bcs.roadmap.md`](../bcs.roadmap.md)) · the B0 exemplar triad ([`bcs.0.md`](bcs.0.md)) · the manuscript
chapters and the chapter-side triads (`content/bcs1.1.specs.md`/`.llms.md`, `content/bcs1.3.specs.md`/`.llms.md`
— the rungs' own specs, cited not duplicated).

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Manuscript: ../content/bcs.toc.md
