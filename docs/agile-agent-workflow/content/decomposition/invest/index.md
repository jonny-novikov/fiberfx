# A2.03 · INVEST: what a good story looks like — module hub

- **Route:** `/course/agile-agent-workflow/decomposition/invest`
- **File:** `html/agile-agent-workflow/decomposition/invest/index.html`
- **Chapter:** A2 · Decomposition: from vision to user stories
- **Position:** module 3 of 7
- **Accent:** gold (the module-hub default)

## Lead

A story is the unit of work the Operator hands the Author. INVEST is the six-letter
checklist that says when a story is ready to hand over: **I**ndependent, **N**egotiable,
**V**aluable, **E**stimable, **S**mall, **T**estable. Each letter is a yes/no question.
A story that fails one is not wrong — it is not yet a story, and the failing letter
names the repair.

INVEST is a readiness gate, not a grading rubric. It is read before the rung is built,
because a story that fails S or T cannot be specified or accepted, and an agent given an
unestimable, untestable instruction produces work no one can demonstrate. The six tests
are how the Operator keeps the spec layer honest before any code is generated.

## Precise definition

INVEST (Bill Wake, 2003): a good user story is
- **Independent** — can be built and shipped without waiting on another story.
- **Negotiable** — a placeholder for a conversation, not a frozen contract of detail.
- **Valuable** — names a change in what someone can do, demonstrable to a user.
- **Estimable** — small and clear enough that the cost can be guessed.
- **Small** — fits one rung; buildable and demonstrable in a single turn.
- **Testable** — has a concrete way to confirm it is done.

## Portal grounding (no-invent)

Score against the canonical Portal ladder of stories, in dependency order:
1. browse the catalogue
2. enrol in a course
3. open a lesson
4. track progress

Failing examples reused across the three dives:
- **"manage the whole catalogue"** — too big: fails **S** (months of work) and **E**
  (no one can estimate it), which drags down **I** as well.
- **"add the courses DB table"** — purely technical: fails **V** (no user can do
  anything new) and **T** as a unit of value (a passing migration is not a demonstrable
  behaviour). It is a task hiding inside a story-shaped sentence.

Portal API named (only these exist): `Portal.ID.generate/1`, `Portal.ID.decode/1`
(`.type`, `.timestamp`). OTP internals are cited to `/elixir`, never re-taught.

## The three dives (arc: score → diagnose → resolve the tension)

1. **A2.03.1 · `six-tests`** — each letter as a yes/no question; an interactive
   scorecard that scores a Portal story against the six and shows the pass count.
2. **A2.03.2 · `story-smells`** — the four smells (too big, untestable, coupled, purely
   technical); diagnose one, name its failing INVEST letters, rewrite it.
3. **A2.03.3 · `small-and-independent`** — the tension between Independent and Small;
   estimability follows from smallness; splitting (forward-ref A2.05) resolves a story
   that fails S without breaking I.

## Hub framing interactive

A six-letter INVEST board: toggle each letter to read its yes/no question and the Portal
example that passes or fails it. The readout reports how many of the six the currently
selected Portal story passes, and names the first failing letter. Pure function:
`scoreStory(storyKey) -> {pass, fail, firstFail}` over a fixed dataset of the four ladder
stories plus the two non-stories.

## Bridge

- **principle:** A story is ready only when six independent tests all pass; a single No
  names the repair, not a defect.
- **practice (Portal):** "enrol in a course" passes all six and ships in one rung; "manage
  the whole catalogue" fails Small and Estimable, so it is split before it is handed over.

## References

Sources (real, vetted — from the registry):
- INVEST in Good Stories — https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/
- User Stories Applied — https://www.mountaingoatsoftware.com/books/user-stories-applied
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/

Related in this course:
- /course/agile-agent-workflow/decomposition (A2 landing)
- /course/agile-agent-workflow/decomposition/invest/six-tests
- /course/agile-agent-workflow/decomposition/invest/story-smells
- /course/agile-agent-workflow/decomposition/invest/small-and-independent
- /course/agile-agent-workflow/why/two-layers (A1.04)
- /elixir/course

## Wiring

- Crumbs: jonnify / Agile Agent Workflow / A2 · Decomposition / A2.03 · INVEST
- Pager: prev = `/course/agile-agent-workflow/decomposition/connextra` (A2.02, parallel
  sibling — `links` FAIL expected until it lands); next = `/course/agile-agent-workflow/decomposition`
  (A2 chapter landing; A2.04 not built, so point next at the chapter home).
- Mods grid → six-tests, story-smells, small-and-independent (all in this batch, resolve).
