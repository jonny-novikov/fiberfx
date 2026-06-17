# A2.06.1 · Compose the ladder — deep-dive

- **Route:** `/course/agile-agent-workflow/decomposition/value-ladder/compose-the-ladder`
- **File:** `html/agile-agent-workflow/decomposition/value-ladder/compose-the-ladder.html`
- **Chapter:** A2 · Decomposition — **Position:** A2.06 · dive 1 of 3
- **Accent:** gold (rung = capability); burgundy (rejected: a task, not a rung)

## Lead

The earlier modules made good stories one at a time. Composing the ladder is the move that
turns a pile of those stories into one ordered stack. A pile is a set with no order. A ladder
is the same set arranged so each rung adds one usable capability and rests on the rungs below
it. The first property of a ladder is the one this dive isolates: **every rung is a
capability, not a task.**

## Precise definition

To **compose a ladder** is to select, from the candidate stories for a vision, the ones that
are usable capabilities, and stack them so each adds value on its own. A rung is admitted only
if it is a vertical slice a role can exercise (the A2.01 test). A candidate that is a technical
chore ("add the courses DB table") or an outsize wish ("manage the whole catalogue") is not one
rung of value: the chore delivers nothing a role can do, and the wish is many rungs, not one.
Composing is therefore a filter and a sort: keep the capabilities, drop or split the rest, and
order what remains.

## Portal grounding (no-invent)

The Portal ladder is composed from four capability stories:
1. browse the catalogue
2. enrol in a course
3. open a lesson in an enrolled course
4. track progress through a course

Each is a vertical slice a learner can exercise and demonstrate. Two candidates are rejected at
composition time: "add the courses DB table" (a task — no learner can do anything new; it
belongs *inside* rung 1, not as a rung) and "manage the whole catalogue" (an outsize story —
months of work, many capabilities; it is split before it joins the ladder). Id authority:
`Portal.ID.generate/1`, `Portal.ID.decode/1` (`.type`, `.timestamp`). OTP is cited to `/elixir`.

## Hero interactive (frames the idea: rung or not a rung)

A **rung-or-task tester**. A row of candidate cards — the four ladder stories plus the two
non-stories. Select one; the SVG marks it as a rung (gold, admitted to the ladder) or rejected
(burgundy, not one rung of value), and the readout names *why*: a usable capability, a task with
no user-visible value, or an outsize wish that is many rungs. Pure function:
`classify(key) -> {kind, reason}` where kind ∈ {rung, task, outsize}. Frames the property; does
not yet assemble the order.

## Main interactive (proves the consequence: a composed ladder is all capabilities)

A **composer**. Four slots, bottom to top; each holds one Portal story. A readout reports, for
the assembled stack, that all four rungs are capabilities and the stack is a ladder — and lets
the reader drop in one of the two non-stories to a slot and watch the stack stop being a ladder
(the slot turns burgundy; the readout names the rung that is not a capability). Pure function:
`ladderState(slots) -> {allCapabilities, badSlot}` over the fixed candidate set. Teaches a
*different* move from the hero: the hero judges one candidate; the composer judges the whole
stack as a ladder.

## Worked example (prose + code)

The pile, then the ladder. From the candidate list, three are capabilities and two are not:

    candidates = [browse, enrol, open_lesson, track_progress, manage_catalogue, courses_table]
    rungs      = Enum.filter(candidates, &capability?/1)   # drops manage_catalogue, courses_table
    # => [browse, enrol, open_lesson, track_progress]

"add the courses DB table" is not dropped from the work — it is folded *into* rung 1 (browse the
catalogue needs a place to read courses from). "manage the whole catalogue" is split into rungs
(A2.05) before any of its slices join. What is left is four rungs, each a capability.

## Bridge

- **principle:** A ladder rung is a usable capability, never a task; composing a ladder keeps the
  capabilities and drops or splits the rest.
- **practice (Portal):** browse, enrol, open a lesson, track progress — four capabilities;
  "add the courses DB table" folds into a rung, "manage the whole catalogue" is split before it
  joins.

## Recap

A ladder is a pile put in order, and the first thing that makes the order a ladder is that every
rung is a capability. The next dive fixes the order itself: each rung may depend only on the
rungs below it.

## References

Sources (real, vetted — from the registry):
- User Stories Applied — https://www.mountaingoatsoftware.com/books/user-stories-applied
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Continuous Delivery — https://continuousdelivery.com/

Related in this course:
- /course/agile-agent-workflow/decomposition/value-ladder (A2.06 hub)
- /course/agile-agent-workflow/decomposition/value-ladder/dependency-order (next dive)
- /course/agile-agent-workflow/decomposition/value (A2.01, value not tasks)
- /course/agile-agent-workflow/decomposition/invest (A2.03, Small/Independent)
- /elixir/course

## Wiring

- Crumbs: jonnify / Agile Agent Workflow / A2 · Decomposition / A2.06 / A2.06.1 · Compose the ladder
- Pager: prev = `/course/agile-agent-workflow/decomposition/value-ladder` (hub);
  next = `/course/agile-agent-workflow/decomposition/value-ladder/dependency-order`.
