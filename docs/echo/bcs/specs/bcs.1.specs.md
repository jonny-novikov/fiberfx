# BCS.1 · spec of record

> The authoritative spec for the B1 rung (**Ideas Behind**, `/bcs/ideas`): deliverables, invariants, the module
> ladder with the fixed dive partition, the acceptance stories folded in, and the Definition of Done. Chapter
> doc: [`bcs.1.md`](bcs.1.md) · agent guide (with the verified grounding bank): [`bcs.1.llms.md`](bcs.1.llms.md).

## Deliverables

- **BCS.1-D1 — The chapter landing.** `html/bcs/ideas/index.html` (+ md mirror `../markdown/ideas/index.md`):
  Part I's teaching arc over six module cards, an "Up next" grid (B2–B8 as non-anchor `soon` cards), ≥1
  interactive, References, pager (prev `/bcs`, next the B1.1 hub), full chrome. First chapter-landing surface —
  bootstraps its design from the B0 exemplar. [US: BCS.1-US1]
- **BCS.1-D2 — Six module hubs.** `<module>/index.html` per the ladder below, each: the module's framing from
  its manuscript chapter, its dive cards, ≥1 interactive, a frozen-transcript evidence block, References, pager
  (prev = chapter landing, next = own first dive). [US: BCS.1-US1]
- **BCS.1-D3 — Twenty dives.** `<module>/<sub>.html` per the ladder's dive column, each a full lesson: the
  manuscript's material for that slice, ≥2 interactives, verbatim evidence, References, a pager chaining
  hub → dive1 → … → hub. [US: BCS.1-US1]
- **BCS.1-D4 — The relink + sync + verification.** The course landing's B1 card flips to a live link (footer
  column too), `bcs.toc.md` marks B1 built, and the whole batch passes the verification sequence in
  [`bcs.1.llms.md`](bcs.1.llms.md). [US: BCS.1-US2]

## The module ladder (the fixed dive partition — D-B1.1)

| Module | Slug · route under `/bcs/ideas/` | Manuscript | What it adds | Dives |
|---|---|---|---|---|
| **B1.1** | `system-substrate` | `bcs1.1.md` | the smallest faithful system — gate, private-ETS store, supervisor; the `PASS 6/6` transcript | `the-six-gates` (G1–G6, one refused crime each) · `ownership-on-the-beam` (private table, `:ordered_set` prev-walk, `self_check!` at init, no second parser) · `the-owner-goroutine` (the Go design: channel boundary, gate at the receiving edge, sorted key slice) |
| **B1.2** | `identity-contract` | `bcs1.2.md` | the contract read property by property — the architecture's entire interface definition | `the-namespace-discriminant` (typed: carried twice; the compiler error; 200/400/400/404) · `the-order-theorem` (Snowflake's "roughly sortable" hardened to exact per node; keys as timelines) · `placement-not-security` (hash32's one finalizer round; 234878118 everywhere; the hard edge) · `the-minting-law-and-the-canon` (burst-borrow, node bits excluded; the four-refusal taxonomy; suite membership) |
| **B1.3** | `id-system` | `bcs1.3.md` | the chooser, settled by measurement on Valkey 8.1's new hash table | `the-new-hash-table` (chained dict → cache-line buckets; one allocation, two reads) · `the-measured-table` (seven shapes × 1M keys; the staircase; the prefix budget) · `the-chooser` (the candidate table; UUIDv7 the strongest outsider; every column filled) · `the-streams-horizon` (the entry-id injection; the 40960-entry window) |
| **B1.4** | `ecs-to-bcs` | `bcs1.4.md` | what distribution changes — the handle's three deaths, the translation table | `the-handle-at-its-best` (Weissflog's discipline; the generation counter; West's confession) · `the-three-deaths` (save file · socket · foreign store, each a missing contract property) · `the-translation-table` (entity→identity …; the litmus question; hybrids behind the boundary) |
| **B1.5** | `time-inside-the-name` | `bcs1.5.md` | time as a subject — the horizon, the law of two clocks, the floor, the third clock | `the-41-bit-horizon` (69.7 years; September 2093; the planned successor epoch) · `the-law-of-two-clocks` (identity time vs event time; Lamport's foundation; `min_for` cursors) · `the-floor-and-the-third-clock` (the monotonic mint floor as policy; TTL as the store's clock, deliberately unmerged) |
| **B1.6** | `branding-beats-its-own-integer` | `bcs1.a1.md` | the encode trial — the brand against its own decimal rendering in five runtimes | `the-two-renderings` (11 divmods by 62 into fixed positions vs ~19 by 10 into unknown width) · `the-five-runtimes` (the measured table; the Go split; the Elixir tie; the Node loss in the prescribed place) · `the-whole-system-accounting` (minted once, cheaper forever: 8 bytes at rest, 5 per hop) |

Pager chain: chapter landing pager prev `/bcs` · next `system-substrate`; hub prev = chapter landing, next =
own first dive; dives chain hub → dive1 → dive2 → (dive3 → dive4) → back to the hub; the last module's hub may
point next at the chapter landing's "Up next".

## Invariants

- **BCS.1-INV1 (figures verbatim)** — every number, id, key shape, and transcript line is quoted exactly as the
  grounding bank in [`bcs.1.llms.md`](bcs.1.llms.md) records it from the committed sources; agents cite the
  bank and the sources, re-derive nothing, invent nothing. A figure not in the bank is verified against
  `content/` before use or dropped.
- **BCS.1-INV2 (full links PASS at every state)** — unbuilt routes are never anchored: the landing's module
  cards start non-anchor where a wave has not landed; concurrent siblings defer cross-links and the
  orchestrator restores them post-build; the course-landing relink happens only after the whole batch is green.
- **BCS.1-INV3 (identity)** — every page copies the contract-sheet system from a built BCS page (bootstrap: the
  B0 exemplar); none of the dark-editorial MUST-NOT tokens appear.
- **BCS.1-INV4 (chrome + stamps)** — segmented route-tag (three segments on a dive: `/bcs` → `ideas` →
  current), canonical 3-column footer, a **fresh `BCS…` stamp per page** (minted + decode-verified), the static
  timestamp dd updated to the decoded value.
- **BCS.1-INV5 (md-first)** — `docs/echo/bcs/markdown/ideas/<route>.md` exists for all 27 pages, authored
  before its HTML.
- **BCS.1-INV6 (boundaries)** — nothing under `content/` is edited; bus/engine depth doors to `/echomq` /
  `/redis-patterns`; B2–B8 are referenced by name only (their manuscript Parts where unwritten take the
  living-status voice).

## Acceptance stories (folded)

- **BCS.1-US1 — The reader.** As a reader, I want Part I taught as a chapter — landing → module → dive — with
  the manuscript's own evidence on every page, so that the law, the contract, the chooser, the translation, the
  clocks, and the trial are learnable without opening the repository.
  - Given the batch ships, when I open `/bcs/ideas`, then the six modules are live cards and every dive
    resolves; when I open any dive, then its figures match the manuscript's committed outputs character for
    character.
  - Given JavaScript is disabled, when I open any B1 page, then every section is readable and the interactives
    degrade to static diagrams.
  - Encodes BCS.1-INV1, BCS.1-INV3. Priority: must · Size: 8 · Implements: BCS.1-D1, BCS.1-D2, BCS.1-D3.
- **BCS.1-US2 — The Operator.** As the Operator, I want the batch gated and the views synced, so that the
  course's living maps stay truthful.
  - Given any page in the batch, when the gate command runs, then it reports STATUS: PASS on all ten gates.
  - Given the batch completes, when I open `/bcs`, then the B1 card is a live link, B2–B8 remain non-anchor
    `soon` cards, and `bcs.toc.md` shows B1 `✓ built` with the dive lists.
  - Encodes BCS.1-INV2, BCS.1-INV4, BCS.1-INV5. Priority: must · Size: 3 · Implements: BCS.1-D4.
- **BCS.1-US3 — The authoring agent.** As a module agent, I want a brief that names my manuscript chapter, my
  dives, my verified figures, my sources, and my pager, so that I build without re-deriving structure or facts.
  - Given [`bcs.1.llms.md`](bcs.1.llms.md), when I author my module, then every fact I cite appears in the bank
    or in the named manuscript file, and my pages touch only my module's routes.
  - Encodes BCS.1-INV1, BCS.1-INV6. Priority: must · Size: 2 · Implements: BCS.1-D2, BCS.1-D3.

Coverage: D1→US1 · D2→US1,US3 · D3→US1,US3 · D4→US2.

## Definition of Done

- [ ] 27 md mirrors under `docs/echo/bcs/markdown/ideas/`, each authored before its HTML.
- [ ] 27 pages under `html/bcs/ideas/`, each STATUS: PASS via the exact command in
  [`bcs.1.llms.md`](bcs.1.llms.md).
- [ ] Figure-provenance audit: every number on every page re-found in its committed source (the bank's audit
  column).
- [ ] Identity audit: `grep -rn 'Cormorant\|Manrope\|PT Serif' html/bcs/ideas/` empty; no `.chap`/`.mods`/`.mod`.
- [ ] 27 fresh `BCS…` stamps, each decode-verified.
- [ ] Course landing relinked (B1 card + footer), re-gated PASS; `bcs.toc.md` synced (B1 `✓ built`).
- [ ] Live crawl: every new route 200 on `:8765`; `/bcs` still 200.
- [ ] No manuscript file, ledger, shared asset, or sibling-course file touched. No git commands run.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Chapter: ./bcs.1.md
