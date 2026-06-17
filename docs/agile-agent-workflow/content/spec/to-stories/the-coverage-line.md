# A4.4.2 · The Coverage line

- **Route:** `/course/agile-agent-workflow/spec/to-stories/the-coverage-line`
- **File:** `html/agile-agent-workflow/spec/to-stories/the-coverage-line.html`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`
- **Pager:** prev = `deliverable-to-story` · next = `invest-and-invariants`

## Lead

The deliverable→story map is not left implicit. A `.stories.md` records it as a single line at the end of the
file — the **Coverage line**. It reads each deliverable once and names the stories that realize it. The line is
the audit: a quick scan tells whether every deliverable is covered, because an absent deliverable is visible by
its absence.

## The worked example — the real F6.1 Coverage line (verbatim)

`Coverage: D1→US1 · D2→US1,US3,US4 · D3→US2 · D4→US2,US3,US5 · D5→US2 · D6→US1 · D7→US4,US5.`

Seven entries, one per deliverable D1…D7. Every deliverable appears, so the map is closed. The `pre.code` block
carries this line (and the two stories that frame it) as markdown — no Elixir source.

## Hero interactive — read the Coverage line entry by entry

**Intent:** frame the line as the record. The reader steps through the seven entries D1…D7; the readout names the
entry verbatim (`D4→US2,US3,US5`) and the running count of deliverables read so far against the total.

- **Element ids:** `entryPick` (D1…D7 buttons, first `active` with `data-c="elixir"`), `lineOut` (readout), SVG
  ids `e-d1`…`e-d7`.
- **Fixed dataset:** `ENTRIES = [["D1",["US1"]],["D2",["US1","US3","US4"]],["D3",["US2"]],
  ["D4",["US2","US3","US5"]],["D5",["US2"]],["D6",["US1"]],["D7",["US4","US5"]]]` — verbatim from the line.
- **Pure functions:** `entryText(key)` (e.g. "D4→US2,US3,US5"), `indexOf(key)`, `readoutFor(key)`.
- **Sample readout:** `Entry 4 of 7: D4→US2,US3,US5 — deliverable D4 is realized by US2, US3, US5.`

## Main interactive — drop a deliverable's entry and read the gap

**Intent:** prove the consequence — what a missing entry looks like. The reader picks which deliverable's entry
is removed from the line (or "none"); the readout reports whether the line is closed and, if not, names the
deliverable that has no entry. This is exactly the signal that a deliverable is not yet realized by a story.

- **Element ids:** `dropPick` (a `.solid-select` of "none" + D1…D7), `gapOut` (readout), SVG ids `g-d1`…`g-d7`.
- **Fixed dataset:** the seven keys; "closed" means all seven present.
- **Pure functions:** `presentKeys(dropped)`, `isClosed(dropped)`, `readoutFor(dropped)`.
- **Sample readouts:**
  - none dropped: `The Coverage line is closed: all 7 deliverables have an entry.`
  - D5 dropped: `D5 has no entry — the line is not closed: 6 of 7 deliverables are covered. D5 is not yet realized
    by a story.`

## The bridge

- **Principle:** the deliverable→story map is recorded as one auditable line; a closed line covers every
  deliverable, an open one names the gap.
- **On the Portal:** F6.1's Coverage line reads `D1→US1 · … · D7→US4,US5` — seven entries, all present, closed.

## References

- Sources: Specification by Example, User Stories Applied, Continuous Delivery.
- Related: hub, `deliverable-to-story`, `invest-and-invariants`, `/decomposition/acceptance`, `/spec`,
  `/elixir/phoenix`.
