# A4.4.1 · Deliverable to story

- **Route:** `/course/agile-agent-workflow/spec/to-stories/deliverable-to-story`
- **File:** `html/agile-agent-workflow/spec/to-stories/deliverable-to-story.html`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`
- **Pager:** prev = hub `/spec/to-stories` · next = `the-coverage-line`

## Lead

A spec's Deliverables section is a list of the concrete artifacts a rung produces. The `.stories.md` realizes
each one with at least one user story. The rule is one-directional and total: **for every deliverable there is a
story that realizes it.** A deliverable with no story is a thing the rung produces that no one asked for and that
nothing accepts — a gap the Coverage line will expose.

## The worked example — F6.1's seven deliverables, five stories

F6.1 ships seven deliverables (F6.1-D1…D7) realized by five stories (F6.1-US1…US5). The mapping is many-to-many:
a story can implement several deliverables (US2 implements D3, D4, D5) and a deliverable can be realized by
several stories (D4 by US2, US3, US5). Each story's own line records the deliverables it implements verbatim, e.g.
US2: "Implements deliverables: F6.1-D3, F6.1-D4, F6.1-D5."

## Hero interactive — read a story's implemented deliverables

**Intent:** frame the move from the story side. The reader picks a story US1…US5; the readout names the
deliverables that story implements (verbatim from its "Implements deliverables" line) and whether that story is
testable per its INVEST line.

- **Element ids:** `storyPick` (US1…US5 buttons, first `active` with `data-c="elixir"`), `dlOut` (readout), SVG
  ids `s-us1`…`s-us5`.
- **Fixed dataset:** `STORY = {us1:{deliv:["D1","D2","D6"],role:"operator",testable:true},
  us2:{deliv:["D3","D4","D5"],role:"visitor",testable:true}, us3:{deliv:["D2","D4"],role:"developer",testable:true},
  us4:{deliv:["D2","D7"],role:"operator",testable:true}, us5:{deliv:["D4","D7"],role:"visitor",testable:true}}` —
  from each F6.1 story's "Implements deliverables" line.
- **Pure functions:** `deliverablesFor(key)`, `isTestable(key)`, `readoutFor(key)`.
- **Sample readout:** `US2 (visitor) implements D3, D4, D5. Testable: yes — by rendered output for the three
  cases.`

## Main interactive — build the map the other way: each deliverable to its stories

**Intent:** prove the consequence — read from the deliverable side and confirm every deliverable has ≥1 story.
The reader picks D1…D7; the readout names the stories that realize it and reports whether the deliverable is
covered. The "drop US2" toggle removes US2 from the dataset so D3 and D5 (realized only by US2) become uncovered —
the gap surfaces.

- **Element ids:** `delivPick` (D1…D7 buttons), `dropUS2` (a checkbox toggle), `mapOut` (readout), SVG ids
  `b-d1`…`b-d7`.
- **Fixed dataset:** the inverse of STORY — `COVERAGE = {d1:["US1"], d2:["US1","US3","US4"], d3:["US2"],
  d4:["US2","US3","US5"], d5:["US2"], d6:["US1"], d7:["US4","US5"]}`.
- **Pure functions:** `storiesFor(key, dropped)` (filters US2 when dropped), `coveredCount(dropped)`,
  `readoutFor(key, dropped)`.
- **Sample readouts:**
  - default: `D3 is realized by US2. Covered: 7 of 7 deliverables map to a story.`
  - dropped: `D3 has no covering story — dropping US2 leaves a gap. Covered: 5 of 7 deliverables.`

## The bridge

- **Principle:** every deliverable is realized by at least one story; a deliverable with no story is a gap.
- **On the Portal:** F6.1's D1…D7 each map to a story; remove US2 and D3 and D5 fall out of coverage — the gap is
  read straight from the map.

## References

- Sources: User Stories Applied, INVEST in Good Stories, Specification by Example.
- Related: hub, `the-coverage-line`, `/decomposition/invest`, `/decomposition/acceptance`, `/spec`,
  `/elixir/phoenix`.
