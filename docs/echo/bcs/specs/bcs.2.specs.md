# BCS.2 · spec of record

> The authoritative spec for the B2 rung (**The Elixir BCS Core**, `/bcs/elixir-core`): deliverables,
> invariants, the module ladder with the fixed dive partition, the acceptance stories folded in, and the
> Definition of Done. This rung builds **B2.1 and B2.2**; B2.3–B2.6 are specced rows built on later rungs.
> Chapter doc: [`bcs.2.md`](bcs.2.md) · agent guide (with the verified grounding bank):
> [`bcs.2.llms.md`](bcs.2.llms.md).

## Deliverables

- **BCS.2-D1 — The chapter landing.** `html/bcs/elixir-core/index.html` (+ md mirror
  `../markdown/elixir-core/index.md`): Part II's teaching arc (the law landed on OTP → the seven guidelines →
  the six chapters) over six module cards (B2.1/B2.2 live, B2.3–B2.6 non-anchor `soon`), an "Up next" grid
  (B3–B8 as non-anchor `soon` cards), ≥1 interactive, References, pager (prev `/bcs`, next the B2.1 hub), full
  chrome. Orchestrator-only; bootstraps its design from a built B1 chapter landing. [US: BCS.2-US1]
- **BCS.2-D2 — Two module hubs.** `otp-application/index.html` and `property-stores/index.html`, each: the
  module's framing from its manuscript chapter, its three dive cards, ≥1 interactive, a frozen-transcript
  evidence block (the rung record), References, pager (prev = chapter landing, next = own first dive).
  [US: BCS.2-US1]
- **BCS.2-D3 — Six dives.** `<module>/<sub>.html` per the ladder's dive column (three per module), each a full
  lesson: the manuscript's material for that slice, ≥2 interactives, verbatim evidence, References, a pager
  chaining hub → dive1 → dive2 → dive3 → hub. [US: BCS.2-US1]
- **BCS.2-D4 — The relink + sync + verification.** The course landing's B2 card flips to a live link (footer
  column too), the chapter landing's B2.1/B2.2 cards flip live, `bcs.toc.md` marks those two modules built, and
  the whole batch passes the verification sequence in [`bcs.2.llms.md`](bcs.2.llms.md). [US: BCS.2-US2]

## The module ladder (the fixed dive partition — D-B2.1)

| Module | Slug · route under `/bcs/elixir-core/` | Manuscript | What it adds | Dives | This rung |
|---|---|---|---|---|---|
| **B2.1** | `otp-application` | `bcs2.1.md` | a system as an OTP application — boundary, tree, ownership, restart semantics as architecture; the `PASS 5/5` rung (R1–R5) | `the-export-list` (R1 surface — six domain functions plus OTP callbacks, nothing else; R5 the per-store namespace gate refusing `ORD` on `prt_store`) · `existence-and-the-kill` (R2 existence restored, data not — the BEAM guards data, not existence; R3 recovered through the boundary, not the heap — checkpoints are rows) · `the-blast-radius` (R4 `one_for_one`, sibling untouched; start order as dependency declaration; the Go `supervise` loop) | **✓ build** |
| **B2.2** | `property-stores` | `bcs2.2.md` | three stores under one tree — `AST`/`PRT`/`ORD` — the branded id the only key, chronology a property of the keyspace; the `PASS 5/5` rung (P1–P5) | `the-only-key` (P1 the database shape, values private; P2 the decimal rendering refused `:invalid` — the third door closed: storage 1.3, CPU 1.1, ingress here) · `chronology-without-a-column` (P3 `page_desc` newest-five by byte order; P4 `window/3` `[lo, hi)` 100 of 100 ascending — the order theorem as a read path) · `the-review-performed` (P5 surface grew by exactly one export: `window/3`; the frozen-record ethic; the interim positions map, superseded by 2.5) | **✓ build** |
| **B2.3** | `champ` | `bcs2.3.md` | the CHAMP property database — structural sharing as the snapshot mechanism, the contract hash as the trie's placement function; the `PASS 7/7` rung (H1–H7) | `the-forest-and-the-placement-law` (H1 the namespace→trie forest keyed by the snowflake integer; `compute_hash_int -> BrandedId.hash32`; the two-bitmap CHAMP node) · `sharing-at-the-honest-metric` (H2 `v1` holds 1000, `v2` holds 1001; H3 122 words beside v1, 98% shared; the denominator trap) · `the-crossover` (H4–H7 the flat-table-wins-present vs forest-wins-history line; chronology lost to hash order; the snapshot-out pattern) | ○ later rung |
| **B2.4** | `archetypes` | `bcs2.4.md` | archetypes as data under the `ARC` namespace; composition at read time by a pure fold; the `PASS 5/5` rung (A1–A5) | `archetypes-are-data` (the `compose` fold; A1 composition order — tick from instrument, settlement from archetype, margin from base; the `ARC` registration) · `one-definition-a-thousand-instruments` (A2 the amplification — `multiplier 100 at next read`, no migration; 18-word row vs 14-word view) · `the-guards-and-the-lanes` (A3 one `:extends`, `{:error, :cycle}`/`{:error, :depth}`; A4 `ARC` refuses `AST`; A5 snapshot-lane resolve cheaper than a bare get) | ○ later rung |
| **B2.5** | `relations` | `bcs2.5.md` | relations promoted to systems — the edges store, tuple-keyed, both ends gated, dual private indexes; the `PASS 5/5` rung (E1–E5) | `the-edge-is-the-relation` (the `:holds` model — `PRT` subjects, `AST` objects; E1 six verbs, indexes private; E2 both ends gated) · `the-supersession-performed` (E3 Codd's normalization on stage — positions struck out, copied down as edges; the 2.2 label paid) · `traversal-and-coherence` (E4 forward 200 ascending / reverse 50 — the acquisition timeline free; E5 degree 199, one writer, dual indexes coherent) | ○ later rung |
| **B2.6** | `boundary-acceleration` | *manuscript planned* | gates on every ingress, the deferred persistence adapter, the native codec and the measured line where it pays; the rung (`bcs_rung_2_6_check.out`, `PASS 5/5`, B1–B5) is on file, the prose chapter is not | *fixed when `bcs2.6.md` ships* | ○ manuscript pending |

Pager chain: chapter landing pager prev `/bcs` · next `otp-application`; hub prev = chapter landing, next =
own first dive; dives chain hub → dive1 → dive2 → dive3 → back to the hub; the last built module's hub may
point next at the chapter landing's "Up next".

## Invariants

- **BCS.2-INV1 (figures verbatim)** — every number, id, gate line, key shape, and transcript line is quoted
  exactly as the grounding bank in [`bcs.2.llms.md`](bcs.2.llms.md) records it from the committed sources; the
  rung records (`bcs_rung_2_1_check.out`, `bcs_rung_2_2_check.out`) are quoted character for character in
  source-labelled `figure.frozen` blocks. Agents cite the bank and the sources, re-derive nothing, invent
  nothing.
- **BCS.2-INV2 (full links PASS at every state)** — unbuilt routes are never anchored: the chapter landing's
  B2.3–B2.6 cards and the "Up next" B3–B8 cards are non-anchor `soon` cards; the two module agents defer
  cross-links to each other and the orchestrator restores them post-build; the course-landing relink happens
  only after the whole batch is green.
- **BCS.2-INV3 (identity)** — every page copies the contract-sheet system from a built BCS page (bootstrap: a
  built B1 page of the same surface); none of the dark-editorial MUST-NOT tokens (navy/cream/gold,
  Cormorant/PT Serif/Manrope, `.chap`/`.mods`/`.mod`) appear.
- **BCS.2-INV4 (chrome + stamps)** — segmented route-tag (three segments on a dive: `/bcs` → `elixir-core` →
  current; four on a deeper path is impossible — dives are flat under the module), canonical 3-column footer, a
  **fresh `BCS…` stamp per page** (minted + decode-verified), the static timestamp dd updated to the decoded
  value.
- **BCS.2-INV5 (md-first)** — `docs/echo/bcs/markdown/elixir-core/<route>.md` exists for all nine pages
  (landing + two hubs + six dives), authored before its HTML.
- **BCS.2-INV6 (living status + boundaries)** — nothing under `content/` is edited; bus/engine depth doors to
  `/echomq` / `/redis-patterns` / `/elixir`; B2.6 and B3–B8 are referenced by name only, and B2.6 plus any
  unwritten Part takes the living-status voice ("the manuscript plans…").

## Acceptance stories (folded)

- **BCS.2-US1 — The reader.** As a reader who has B1's vocabulary, I want Part II's reference implementation
  taught as a chapter — landing → module → dive — with the manuscript's own rung evidence on every page, so
  that the OTP-application surface, the ETS property store, the only-key law, and the chronology read paths are
  learnable without opening the repository.
  - Given the batch ships, when I open `/bcs/elixir-core`, then B2.1 and B2.2 are live cards and their six dives
    resolve; when I open any dive, then its figures match the manuscript's committed outputs character for
    character.
  - Given JavaScript is disabled, when I open any B2 page, then every section is readable and the interactives
    degrade to static diagrams.
  - Encodes BCS.2-INV1, BCS.2-INV3. Priority: must · Size: 5 · Implements: BCS.2-D1, BCS.2-D2, BCS.2-D3.
- **BCS.2-US2 — The Operator.** As the Operator, I want the batch gated and the views synced, so that the
  course's living maps stay truthful.
  - Given any page in the batch, when the gate command runs, then it reports STATUS: PASS on all ten gates.
  - Given the batch completes, when I open `/bcs`, then the B2 card is a live link, B3–B8 remain non-anchor
    `soon` cards, and `bcs.toc.md` shows B2.1/B2.2 `✓ built` with their dive lists.
  - Encodes BCS.2-INV2, BCS.2-INV4, BCS.2-INV5. Priority: must · Size: 3 · Implements: BCS.2-D4.
- **BCS.2-US3 — The authoring agent.** As a module agent, I want a brief that names my manuscript chapter, my
  dives, my verified figures, my sources, and my pager, so that I build without re-deriving structure or facts.
  - Given [`bcs.2.llms.md`](bcs.2.llms.md), when I author my module, then every fact I cite appears in the bank
    or in the named manuscript file, and my pages touch only my module's routes.
  - Encodes BCS.2-INV1, BCS.2-INV6. Priority: must · Size: 2 · Implements: BCS.2-D2, BCS.2-D3.

Coverage: D1→US1 · D2→US1,US3 · D3→US1,US3 · D4→US2.

## Definition of Done

- [ ] 9 md mirrors under `docs/echo/bcs/markdown/elixir-core/` (landing + 2 hubs + 6 dives), each authored
  before its HTML.
- [ ] 9 pages under `html/bcs/elixir-core/`, each STATUS: PASS via the exact command in
  [`bcs.2.llms.md`](bcs.2.llms.md).
- [ ] Figure-provenance audit: every number on every page re-found in its committed source (the bank's audit
  column) — the two rung records quoted verbatim.
- [ ] Identity audit: `grep -rn 'Cormorant\|Manrope\|PT Serif' html/bcs/elixir-core/` empty; no
  `.chap`/`.mods`/`.mod`.
- [ ] 9 fresh `BCS…` stamps, each decode-verified.
- [ ] Course landing relinked (B2 card + footer) and chapter landing relinked (B2.1/B2.2 cards), re-gated PASS;
  `bcs.toc.md` synced (B2.1/B2.2 `✓ built`).
- [ ] Live crawl: every new route 200 on `:8765`; `/bcs` still 200.
- [ ] No manuscript file, ledger, shared asset, or sibling-course file touched. No git commands run.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Chapter: ./bcs.2.md
