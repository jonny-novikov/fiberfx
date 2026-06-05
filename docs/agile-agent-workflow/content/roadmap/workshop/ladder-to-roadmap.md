# A3.8.1 · Ladder to roadmap (dive)

- **Route:** `/course/agile-agent-workflow/roadmap/workshop/ladder-to-roadmap`
- **File:** `html/agile-agent-workflow/roadmap/workshop/ladder-to-roadmap.html`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Model copied:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/what-it-carries.html` (lesson).

## Lead

A2 left a value ladder: nine vertical slices, dependency-ordered, each a real capability. That ladder is a backlog,
not yet a delivery plan. This dive takes it to a chapter roadmap by applying A3.3 (the anatomy) and A3.5
(milestones + iterations): assign each rung to one of three milestones, then fill each rung's row in the
per-iteration table. The output is the real F6 `phoenix.roadmap.md`, reproduced.

## Worked Portal example

The A2 value ladder for the web surface is the nine rungs `f6.1…f6.9`. The roadmap groups them into three
milestones (verbatim from `phoenix.roadmap.md`):
- Milestone 1 · Ship the catalog — f6.1, f6.2, f6.3, f6.4, f6.5 (and f6.5.5).
- Milestone 2 · Make it live — f6.6, f6.7.
- Milestone 3 · Ship to users — f6.8, f6.9.

Each rung then gets its iteration row, columns: Rung | Ships (the slice) | Demo | Harness | Feedback asked.

## Hero (framing) interactive — assign a rung to a milestone

- **Move:** select a rung; the readout names which of the three milestones it falls in (a usable-capability
  boundary), verbatim from the roadmap.
- **Control ids:** `.solid-select#asgnRung` buttons `data-k=f61|f63|f65|f66|f68`,
  `data-c=elixir|blue|gold|sage|elixir`.
- **SVG:** three milestone bands `#band-m1/#band-m2/#band-m3`; a moving rung chip highlights the matching band.
- **Readout id:** `#asgnOut`. Static default = f6.1 → milestone 1.
- **Pure function:** `milestoneOf(key) -> {n, name, rungs}` over `LADDER`.
- **Sample readout:** `f6.1 → milestone 1 · Ship the catalog (f6.1–f6.5.5). A milestone is a usable-capability boundary; the assignment is the roadmap, not a spec.`

## Content interactive — fill the iteration row (Ships / Demo / Harness / Feedback)

- **Move:** select a rung; the four-column iteration row fills in from the roadmap's verbatim cells; a spec-edits
  counter stays at 0 as you switch rungs (filling the table edits the roadmap, never a spec).
- **Control ids:** `.solid-select#rowRung` buttons `data-k=f61|f63|f65|f66|f68`,
  `data-c=elixir|blue|gold|sage|elixir`.
- **SVG:** four labelled cells `#cell-ships/#cell-demo/#cell-harness/#cell-fb` plus a `#cell-edits` counter held at 0.
- **Readout id:** `#rowOut`. Static default = f6.1 row.
- **Pure function:** `rowOf(key) -> {ships, demo, harness, feedback}` over `ROWS`; `specEdits()` -> 0 (constant).
- **Sample readout:** `f6.1 row — Ships: the engine served as a web app · Demo: hit the root, see a page · Harness: ConnTest GET smoke · Feedback: shell and layout right? · spec edits: 0.`

## pre.code — the per-iteration table as a roadmap.md fragment (markdown, NOT Elixir)

A markdown table fragment of three sample rows.

## Bridge

- **idea:** a value ladder becomes a roadmap by grouping rungs into milestones and filling each rung's iteration
  row — order and a row per rung, no behaviour.
- **practice:** on the Portal the table is `phoenix.roadmap.md`'s per-iteration table; each row points at its
  `f6.N.md` spec; re-grouping the rungs edits the roadmap, never a spec.
- **take:** the ladder is the backlog; the roadmap adds milestones and a row per rung — and defines no behaviour.

## Pager

- prev hub `/course/agile-agent-workflow/roadmap/workshop`
- next `/course/agile-agent-workflow/roadmap/workshop/choose-the-tracer`

## References — Sources

- Continuous Delivery · Extreme Programming Explained · The Pragmatic Programmer (vetted registry URLs).

## Related (resolve)

- hub; choose-the-tracer; A3.3 roadmap-anatomy/the-iteration-table; A3 roadmap; /elixir/phoenix; decomposition/workshop.
