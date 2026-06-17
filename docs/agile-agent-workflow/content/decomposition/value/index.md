# A2.01 · Value, not tasks — module hub

- **Route:** `/course/agile-agent-workflow/decomposition/value`
- **File:** `html/agile-agent-workflow/decomposition/value/index.html`
- **Model copied from:** `html/agile-agent-workflow/why/two-layers/index.html`
- **Accent:** gold (the chapter's default; the value/demonstrability colour)
- **Numbering:** A2.01 — first module of chapter A2 (Decomposition)

## Lead

A unit of work is a unit of **value a role can use**, not a technical chore. This is the
single most important habit in the workflow, because it decides what the loop builds, what
gets demoed, and how the backlog is ordered. The shift is from a to-do list of work-to-do to
a backlog of outcomes — changes in what someone can do once a slice lands.

## What the module argues

A task names work to do; a story names a change in what a role can *do*. The demonstrability
test separates them: a story can be demoed because it produces an observable change a role can
use; a chore cannot, because nothing a role could touch changed. Value, not effort, is the
ordering key for the backlog. And value cuts *through* the layers — a usable end-to-end thread —
rather than completing one horizontal layer no one can demo.

## Framing interactive (hub)

**The task-vs-story sorter.** A fixed dataset of eight Portal work items, some stories and some
chores. Buttons select a lens (`all`, `stories`, `chores`); the readout reports, over the fixed
set, how many of each there are and — the point — how many can be demoed. Pure function
`tally(items, lens)` returns `{shown, demoable, count}`. Sample readout: "Lens: stories · 4 of 8
items · 4 demoable. Every story names a change a role can use, so every one can be demoed."

This frames the module: the dividing line is demonstrability, and the three dives each take one
edge of it.

## The three dives (the arc: name it → order by it → cut for it)

1. **A2.01.1 · `outcome-not-chore`** — task vs. story. A task names work to do; a story names a
   change in what a role can do once it lands. The demonstrability test: a story can be demoed, a
   chore cannot. Route `/course/agile-agent-workflow/decomposition/value/outcome-not-chore`.
2. **A2.01.2 · `who-benefits`** — every slice names a role and the value to that role; value, not
   effort, is the ordering key for the backlog.
   Route `/course/agile-agent-workflow/decomposition/value/who-benefits`.
3. **A2.01.3 · `vertical-slice`** — value cuts *through* layers (a usable end-to-end thread) vs.
   horizontal technical chores (a layer no one can demo).
   Route `/course/agile-agent-workflow/decomposition/value/vertical-slice`.

## Portal grounding (no-invent)

Canonical value ladder (reused from the A2 landing): "browse the catalogue of courses" → "enrol
in a course" → "open a lesson in an enrolled course" → "track progress through a course". Chore
counter-examples (NOT stories): "add the courses DB table", "wire the LiveView socket", "create
the Portal.ID module". Portal API named only where exact: `Portal.ID.generate/1`,
`Portal.ID.decode/1` (`.type`, `.timestamp`). Cite `/elixir` for OTP internals.

## Bridge (principle → Portal practice)

Principle: a backlog item is a unit of demonstrable value, not a unit of work. → Portal: "enrol
in a course" is a story (a learner can now do something new); "add the courses table" is a chore
that supports it but demos nothing on its own.

## References — Sources (real, vetted; from the course-home registry)

- User Stories Applied → mountaingoatsoftware.com — stories as value, not tasks.
- Extreme Programming Explained → oreilly.com — the on-site customer and demonstrable increments.
- The Pragmatic Programmer → pragprog.com — tracer bullets: a thin end-to-end thread.

Related in this course: the three dives; `/course/agile-agent-workflow/decomposition` (A2 landing);
`/course/agile-agent-workflow/why/two-layers` (A1.04, the spec layer each story feeds); `/elixir/course`.

## Pager

- prev = `/course/agile-agent-workflow/decomposition` (resolves)
- next = `/course/agile-agent-workflow/decomposition/value/outcome-not-chore` (first dive, resolves)

(The forward link to the parallel sibling `…/decomposition/connextra` appears only in the `.note`
forward-pointer and will FAIL `links` until that module lands — expected.)
