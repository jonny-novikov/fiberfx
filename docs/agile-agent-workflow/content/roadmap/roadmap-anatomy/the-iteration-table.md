# A3.3.2 · The iteration table — dive

- **Route:** `/course/agile-agent-workflow/roadmap/roadmap-anatomy/the-iteration-table`
- **File:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/the-iteration-table.html`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Pager:** prev = `…/roadmap-anatomy/what-it-carries`; next = `…/roadmap-anatomy/open-decisions`.

## Lead

The per-iteration table is the operational heart of a roadmap. Each row is one rung: what it ships, the demo, the
harness, and the feedback asked. Verbatim from `phoenix.roadmap.md`: "each a PR-sized increment — a spec triad, the
slice, a green harness, a demo, a feedback note".

## The five columns (verbatim header row from `phoenix.roadmap.md`)

`| Rung | Ships (the slice) | Demo | Harness | Feedback asked |`

Sample rows (verbatim cells from the real file):

- **F6.1** — ships "the engine served as a web app (endpoint, request → facade → render)"; demo "hit the root, see a
  page"; harness "`ConnTest` GET smoke"; feedback asked "shell and layout right?".
- **F6.5** — ships "the rendered catalog (index, `course_card`, form, inline errors)"; demo "browse the catalog;
  create with inline errors"; harness "HTML render tests; valid/invalid create"; feedback asked "layout, UX, error
  wording?".
- **F6.6** — ships "interactivity (live search, live create, streams)"; demo "search as you type; create without a
  reload"; harness "`LiveViewTest` (`render_change`/`render_submit`)"; feedback asked "does the interaction feel
  right?".

## Hero interactive — read one row of the table

- **What it frames.** Pick a rung; the row's four cells (ships · demo · harness · feedback) render from the real
  table.
- **Element ids:** controls `#rowPick` (buttons f6.1, f6.5, f6.6, f6.7), readout `#rowOut` (`aria-live="polite"`),
  SVG `#rowGrid` showing the four cells.
- **Pure function:** `rowOf(rung) -> {ships, demo, harness, feedback}` over a fixed `ROWS` dataset (verbatim cells).
  Readout composes the four.
- **Sample readout:** "f6.6 ships: interactivity (live search, live create, streams) · demo: search as you type;
  create without a reload · harness: LiveViewTest (render_change/render_submit) · feedback asked: does the
  interaction feel right?"

## Main interactive — re-order the rungs, spec edits stay 0

- **What it proves.** Order is decoupled from definition: re-ordering the rung sequence changes the plan, never a
  spec. The "spec edits" counter stays at 0 across any re-order (the A3.3 acceptance).
- **Element ids:** controls `#reorderUp` / `#reorderDown` (move the selected rung; or `#reorderShuffle`), a list
  `#reorderList`, readout `#reorderOut` (`aria-live="polite"`) carrying the live "spec edits: 0" counter.
- **Pure function:** `reorder(order, i, dir) -> newOrder` (pure array swap; returns a new array, never mutates);
  `specEdits(order) -> 0` (constant — re-ordering touches no spec). Readout = the new order + "spec edits: 0".
- **Sample readout:** "order: f6.3 · f6.1 · f6.5 · f6.6 · f6.7 — spec edits: 0. Re-ordering changes delivery, never
  definition."

## Bridge

- **Principle:** The per-iteration table makes each rung a PR-sized increment with a demo and a harness; re-ordering
  the table re-plans delivery and edits no spec.
- **Portal practice:** `phoenix.roadmap.md`'s per-rung table; the loop "sharpen → build → ship → demo → review →
  feedback → adapt"; feedback edits the spec, the order does not.

## References — Sources (verbatim, real URLs)

- Continuous Delivery — https://continuousdelivery.com/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/

## Related (resolving)

- `/course/agile-agent-workflow/roadmap/roadmap-anatomy` — the hub.
- `/course/agile-agent-workflow/why/two-layers` — roadmap over spec.
- `/course/agile-agent-workflow/what/four-artifacts` — the four artifacts.
- `/elixir/phoenix` — the real F6 chapter.
