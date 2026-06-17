# A4.4 · From stories to a .stories.md — module hub

- **Route:** `/course/agile-agent-workflow/spec/to-stories`
- **File:** `html/agile-agent-workflow/spec/to-stories/index.html`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`
- **Pager:** prev = `/course/agile-agent-workflow/spec` · next = `/course/agile-agent-workflow/spec/to-stories/deliverable-to-story`

## Lead

A spec lists what an increment delivers. The `.stories.md` answers a different question — *who wants each
deliverable, and how we will know it works* — and it does so as Connextra user stories with Given/When/Then
acceptance and an INVEST line. The contract between the two files is a single rule: **every deliverable is
realized by at least one story, and every story names the invariants it `encodes`.** A `.stories.md` ends with a
**Coverage line** that maps each deliverable to the stories that realize it. A deliverable absent from that line
has no covering story, and the rung is not yet specifiable as done.

This module reads the real F6.1 stories file (`docs/elixir/specs/phoenix/f6.1.stories.md`): five stories
F6.1-US1…US5 over seven deliverables F6.1-D1…D7, closing on the verbatim Coverage line
`Coverage: D1→US1 · D2→US1,US3,US4 · D3→US2 · D4→US2,US3,US5 · D5→US2 · D6→US1 · D7→US4,US5.`

## Framing interactive (hero) — build the coverage map

**Intent:** frame the module's one move — turning a list of deliverables into a covered map. The reader picks a
deliverable D1…D7; the readout names the stories that realize it (from the fixed map) and reports the running
covered count. With every deliverable selected at least once the map is complete; an artificially dropped
deliverable (the "uncovered" toggle) flags the gap.

- **Element ids:** `mapPick` (the `.solid-select` of D1…D7 buttons, the first `active` carrying `data-c`),
  `covOut` (the `.geo-readout`, `aria-live="polite"`), SVG ids `m-d1`…`m-d7`.
- **Fixed dataset:** `COVERAGE = {d1:["US1"], d2:["US1","US3","US4"], d3:["US2"], d4:["US2","US3","US5"],
  d5:["US2"], d6:["US1"], d7:["US4","US5"]}` — verbatim from the F6.1 Coverage line.
- **Pure functions:** `storiesFor(key)` → the array for a deliverable; `coveredCount(map)` → how many
  deliverables have ≥1 story (7 of 7 for F6.1); `readoutFor(key)` → the readout string.
- **Sample readout:** `D4 is realized by US2, US3, US5. Covered: 7 of 7 deliverables map to a story — the map is
  closed.`

## Recap + the three dives

The three dives walk the move end to end: build the map (deliverable → story), read the line that records it
(the Coverage line), then read what each story carries (the INVEST line and the invariants it `encodes`).

1. **A4.4.1 — Deliverable to story** (`deliverable-to-story`): every deliverable is realized by ≥1 story; build
   the F6.1 map and flag a deliverable with no story.
2. **A4.4.2 — The Coverage line** (`the-coverage-line`): the one line that records the deliverable→story map, read
   verbatim; how a missing deliverable surfaces.
3. **A4.4.3 — INVEST and invariants** (`invest-and-invariants`): each story's INVEST line names the invariants it
   `encodes` and whether it is testable.

## The bridge

- **Principle:** a list of deliverables is turned into a map of stories that realize them; every deliverable is
  covered, and every story names the invariants it exercises.
- **On the Portal:** F6.1's seven deliverables map to five stories, recorded in the Coverage line; each story's
  INVEST line names the F6.1 invariants it `encodes` (e.g. US2 encodes F6.1-INV1).

## References

- Sources: User Stories Applied (`mountaingoatsoftware.com`), INVEST in Good Stories (`xp123.com`),
  Specification by Example (`gojko.net`).
- Related: `/spec` (landing), the three dives, `/decomposition/invest`, `/decomposition/acceptance`,
  `/elixir/phoenix`.
