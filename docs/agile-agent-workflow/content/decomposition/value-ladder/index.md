# A2.06 · The value ladder — module hub

- **Route:** `/course/agile-agent-workflow/decomposition/value-ladder`
- **File:** `html/agile-agent-workflow/decomposition/value-ladder/index.html`
- **Chapter:** A2 · Decomposition: from vision to user stories
- **Position:** module 6 of 7
- **Accent:** gold (the module-hub default; burgundy marks a broken ladder)

## Lead

The previous modules produced good stories one at a time — value not tasks, the Connextra
form, the INVEST tests. A ladder is what those stories become when they are put in order.
A **value ladder** is a dependency-ordered stack of stories where each rung adds one usable
capability, depends only on the rungs below it, and leaves the system runnable. It is the
structure the rest of the course plans, specifies, and builds over.

A ladder is not a pile. A pile is a set of stories with no order; a ladder is the same
stories arranged so that value accrues from the bottom up and the system can be demonstrated
after every rung. Three properties make a stack a ladder: each rung is a capability (not a
task), each rung depends only on rungs below it, and every prefix of the ladder runs. Lose
any one and the stack stops being a ladder.

## Precise definition

A **value ladder** for a vision is an ordered sequence of stories `r₁, r₂, …, rₙ` such that:
- **each rung is a usable capability** — a vertical slice a role can exercise, demonstrable
  on its own (the A2.01 rule);
- **each rung depends only on rungs below it** — `deps(rᵢ) ⊆ {r₁, …, rᵢ₋₁}` (a topological
  order of the dependency graph);
- **every prefix runs** — building `r₁ … rₖ` for any `k` leaves the system runnable and
  demoable.

Ordering by dependency and ordering by value are two different sorts; where they conflict,
dependency wins (a rung that depends on an unbuilt rung cannot ship), and value chooses the
order among rungs that do not depend on each other.

## Portal grounding (no-invent)

The canonical Portal ladder, in dependency order:
1. **browse the catalogue** — depends on nothing; the foundation rung.
2. **enrol in a course** — depends on rung 1 (there must be a catalogue to enrol from).
3. **open a lesson in an enrolled course** — depends on rung 2 (enrolment gates the lesson).
4. **track progress through a course** — depends on rung 3 (progress is over opened lessons).

A reordering that violates a dependency — for example, putting *enrol* before *browse* —
breaks runnability: *enrol* now points up at a rung that has not been built, so the system
cannot run through it. The id authority is `Portal.ID` (`Portal.ID.generate/1`,
`Portal.ID.decode/1` with `.type`, `.timestamp`); no other Portal surface is invented, and
OTP internals are cited to `/elixir`, never re-taught.

## The three dives (arc: compose → order → keep runnable)

1. **A2.06.1 · `compose-the-ladder`** — assembling individual stories into one ordered
   ladder; each rung a usable capability, not a task. The move from a pile of stories to a
   stacked ladder.
2. **A2.06.2 · `dependency-order`** — each rung depends only on the rungs below it;
   topological ordering; value accrues bottom-up; ordering by value vs. by dependency and how
   the two reconcile.
3. **A2.06.3 · `always-runnable`** — every rung leaves the system runnable and demoable;
   this is the structure the A3 roadmap layer plans delivery over (named, not re-taught).

## Hub framing interactive

A **ladder composer**: a row of candidates — the four Portal stories plus two non-stories
("manage the whole catalogue", "add the courses DB table") — and a stack of four rungs.
Select a candidate; the readout reports whether it is a rung (a usable capability that fits
the ladder) or is rejected (a task or an outsize story that is not one rung of value), and
which rung position it occupies. Pure function:
`classifyCandidate(key) -> {isRung, rung, reason}` over a fixed dataset. Different from the
A2 landing's read-up-to-level-N stepper: this one classifies a candidate as rung-or-not
rather than reading the already-assembled ladder.

## Bridge

- **principle:** Compose stories into a dependency-ordered ladder where each rung adds usable
  value and the whole remains runnable — the structure delivery is planned over.
- **practice (Portal):** browse → enrol → open lesson → track progress: four rungs, each a
  capability, each resting only on the ones below, the system demoable after every one.

## References

Sources (real, vetted — from the registry):
- User Stories Applied — https://www.mountaingoatsoftware.com/books/user-stories-applied
- Continuous Delivery — https://continuousdelivery.com/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/

Related in this course:
- /course/agile-agent-workflow/decomposition (A2 landing)
- /course/agile-agent-workflow/decomposition/value-ladder/compose-the-ladder
- /course/agile-agent-workflow/decomposition/value-ladder/dependency-order
- /course/agile-agent-workflow/decomposition/value-ladder/always-runnable
- /course/agile-agent-workflow/decomposition/value (A2.01, value not tasks)
- /course/agile-agent-workflow/decomposition/invest (A2.03, Independent/Small)
- /course/agile-agent-workflow/why/two-layers (A1.04, the roadmap/spec split A3 builds on)
- /elixir/course

## Wiring

- Crumbs: jonnify / Agile Agent Workflow / A2 · Decomposition / A2.06 · The value ladder
- Pager: prev = `/course/agile-agent-workflow/decomposition` (A2 chapter landing);
  next = `/course/agile-agent-workflow/decomposition/value-ladder/compose-the-ladder` (own
  first dive).
- Mods grid → compose-the-ladder, dependency-order, always-runnable (all in this batch,
  resolve).
- Do NOT link sibling modules being built in parallel (acceptance A2.04, splitting A2.05,
  workshop A2.07) — prose-only mentions.
