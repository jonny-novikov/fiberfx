# A2.03.3 · Small and independent — dive

- **Route:** `/course/agile-agent-workflow/decomposition/invest/small-and-independent`
- **File:** `html/agile-agent-workflow/decomposition/invest/small-and-independent.html`
- **Accent:** gold
- **Position:** A2.03 · INVEST · dive 3

## Lead

Two of the six letters pull against each other. **Small** wants the thinnest possible
slice; **Independent** wants a slice that does not wait on its neighbours. Cut too coarse
and a story fails S; cut carelessly and the pieces fail I. The resolution is to split along
value, not along layers — the subject of A2.05.

## The tension, and why E follows from S

- **Small ⇒ Estimable.** A small story is estimable almost by definition: a slice that fits
  one rung has a guessable cost, because there is little of it to misjudge. A too-big story
  fails S and E together — the size is exactly what makes the estimate a guess.
- **Small vs Independent.** Making a story smaller can introduce a dependency: split
  "enrol and see the confirmation" into "enrol" then "see the confirmation", and the second
  half now waits on the first. The trap is splitting along technical layers (DB, then API,
  then UI), which produces thin slices that each fail I because none ships value alone.
- **Resolution.** Split along value, so each slice is independently demonstrable. "Browse
  the catalogue" and "enrol in a course" are both small and independent because each is a
  whole capability, not a layer of one.

## Worked Portal example

"Manage the whole catalogue" fails S and E. Splitting along value yields the ladder:
browse → enrol → open a lesson → track progress. Each rung is small (one turn), estimable
(small ⇒ estimable), and independent (a whole capability). Splitting along layers would
have produced "the courses table", "the courses API", "the courses page" — three slices
that each fail I, because none is demonstrable on its own. The how of the split is A2.05;
the why is here.

## Hero interactive (frames the idea)

A split-strategy comparison: toggle between "split by layer" and "split by value" for the
"manage the catalogue" story. Each strategy renders its resulting slices, marked
independent or coupled, and the readout reports how many of the slices are independently
demonstrable.
- Dataset: two strategies, each a list of slices with an `independent` boolean.
- Pure function: `splitOutcome(strategy) -> {slices, independentCount, total}`.
- Sample readout (layer): "Split by layer → 3 slices, 0 independently demonstrable. Each waits on another; all fail I."
- Sample readout (value): "Split by value → 4 slices, 4 independently demonstrable. Each is small and ships alone."

## Main interactive (proves a consequence)

A size→estimability slider: drag a story's size from "whole catalogue" down through the
ladder rungs; the figure reports whether S passes and whether E passes at each step,
showing E flips to pass exactly when S does. This proves the consequence: estimability is
not a separate judgement, it follows from smallness.
- Pure function: `estimability(sizeIndex) -> {small:bool, estimable:bool, label}` over a
  fixed five-step size scale.
- Sample readout: "Size: one rung (enrol) — Small: pass, Estimable: pass. E follows S."
- Sample readout: "Size: whole catalogue — Small: fail, Estimable: fail. Too big to estimate."

## Bridge

- **principle:** Small and Independent pull against each other; splitting along value, not
  along layers, satisfies both — and estimability follows from smallness.
- **practice (Portal):** "manage the catalogue" splits along value into browse → enrol →
  open → track, four small, independent, estimable rungs; splitting along layers would have
  produced three coupled slices that each fail I.

## References

Sources:
- INVEST in Good Stories — https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/
- User Stories Applied — https://www.mountaingoatsoftware.com/books/user-stories-applied
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/

Related:
- /course/agile-agent-workflow/decomposition/invest (hub)
- /course/agile-agent-workflow/decomposition/invest/story-smells (prev)
- /course/agile-agent-workflow/why/two-layers (A1.04)
- /course/agile-agent-workflow/decomposition (A2)
- /elixir/course

## Wiring

- Pager: prev = `/decomposition/invest/story-smells`; next = hub (`/decomposition/invest`).
- Crumbs: jonnify / Agile Agent Workflow / A2 / A2.03 / A2.03.3 · Small and independent.
