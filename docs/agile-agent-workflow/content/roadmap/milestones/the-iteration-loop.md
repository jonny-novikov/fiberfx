# A3.5.2 · The iteration loop — dive 2

- **Route:** `/course/agile-agent-workflow/roadmap/milestones/the-iteration-loop`
- **File:** `html/agile-agent-workflow/roadmap/milestones/the-iteration-loop.html`
- **Model copied verbatim:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/what-it-carries.html` (lesson).
- **Stamp:** `TSK0Ng9hnHJgW0`.

## Lead

Inside a milestone, each rung is one iteration. The per-iteration table sizes a rung as a PR-sized increment over
four columns — **Ships | Demo | Harness | Feedback** — and the per-rung loop runs
`sharpen → build → ship → demo → review → feedback → adapt`. Feedback edits the spec, never the shipped code.

## Precise definition

A rung's iteration row, verbatim from `phoenix.roadmap.md` — each a PR-sized increment (a spec triad, the slice,
a green harness, a demo, a feedback note):

| Rung | Ships (the slice) | Demo | Harness | Feedback asked |
|---|---|---|---|---|
| F6.1 | the engine served as a web app (endpoint, request → facade → render) | hit the root, see a page | `ConnTest` GET smoke | shell and layout right? |
| F6.3 | durable catalog and enrollments (Postgres adapter behind the F5 port) | data survives a restart | schema/changeset tests; sandbox; restart-replay | schema fields and constraints? |
| F6.5 | the rendered catalog (index, course_card, form, inline errors) | browse the catalog; create with inline errors | HTML render tests; valid/invalid create | layout, UX, error wording? |
| F6.7 | multi-client live updates and a viewer count (PubSub, Presence) | two windows; one creates, the other updates | broadcast tests; presence diff | what should propagate; count semantics? |

The `pre.code` block on the page shows the table as a `roadmap.md` markdown fragment — never Elixir.

## The two interactives

### Hero (`.fig`) — fill the iteration row for a rung
- **Control:** `.solid-select#rowRung`, buttons `f6.1, f6.3, f6.5, f6.7`, `data-c` set.
- **SVG:** four labelled cells (Ships · Demo · Harness · Feedback) that fill with the chosen rung's verbatim cells.
- **Pure function:** `iterationRow(rung) -> {ships, demo, harness, feedback}` over the FIXED verbatim dataset.
- **Readout id `rowOut`:** the four cells joined; states the increment is PR-sized and accepted before the next.
- **Static default:** the f6.1 row, correct without JS.

### Content — step the loop
- **Control:** prev/next stepper `#loopPrev` / `#loopNext` (buttons; not `.solid-select`, so no `data-c` needed)
  over the seven phases `sharpen → build → ship → demo → review → feedback → adapt`.
- **Pure function:** `loopPhase(i) -> {name, does, editsSpec:bool}` over the fixed seven-phase dataset; only the
  `feedback`/`adapt` phases edit the spec, and never the shipped code.
- **Readout id `loopOut`:** names the phase, what it does, and whether it edits the spec.
- Teaches a DIFFERENT move: the hero fills a rung's table row; this walks the per-rung loop and shows feedback
  edits the spec, not the code.

## Worked Portal example

F6.1's row: Ships "the engine served as a web app"; Demo "hit the root, see a page"; Harness "`ConnTest` GET
smoke"; Feedback "shell and layout right?". A PR-sized increment with a demo and a harness, accepted before F6.2
begins. When the feedback ("the shell needs the nav") arrives, it edits F6.1's spec — the next rung is built from
the corrected spec, not by patching shipped code.

## Bridge

- **idea:** Run each rung through one iteration over Ships | Demo | Harness | Feedback; a PR-sized increment with
  a demo and a harness, accepted before the next begins.
- **elix:** F6's per-iteration table sizes every rung that way over the one `Portal` facade. Feedback edits the
  spec; re-grouping rungs edits the roadmap, never a spec.
- **take:** Size a rung so it ships, demos, and is accepted in one pass — then the next rung starts from a clean,
  corrected spec.

## References

### Sources
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- Continuous Delivery — https://continuousdelivery.com/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/

### Related in this course
- `/course/agile-agent-workflow/roadmap/milestones` (hub)
- `/course/agile-agent-workflow/roadmap/milestones/shippable-milestones` (prev)
- `/course/agile-agent-workflow/roadmap/milestones/sequencing-the-ladder` (next)
- `/course/agile-agent-workflow/roadmap/roadmap-anatomy/the-iteration-table`
- `/course/agile-agent-workflow/roadmap/xp-small-batches`
- `/elixir/phoenix`

## Pager

- prev: `/course/agile-agent-workflow/roadmap/milestones/shippable-milestones` (A3.5.1)
- next: `/course/agile-agent-workflow/roadmap/milestones/sequencing-the-ladder` (A3.5.3)
