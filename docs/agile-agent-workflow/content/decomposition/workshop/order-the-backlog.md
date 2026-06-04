# A2.07.3 · Order the backlog

- **Route:** `/course/agile-agent-workflow/decomposition/workshop/order-the-backlog`
- **File:** `html/agile-agent-workflow/decomposition/workshop/order-the-backlog.html`
- **Role:** dive 3 of the workshop, and the A2 capstone close. Apply the value ladder (A2.06) to order the
  stories by dependency across the five surfaces; the runnable backlog carried into Part III.
- **Accent:** elixir-purple.

## Lead

The stories from dives 1 and 2 are ready but unordered. This dive applies the value ladder: order them so
each rung depends only on rungs below it and the system is runnable after every one. The result is the
backlog the course specifies, briefs, and builds for the rest of Part III onward.

## Worked Portal example (the five surfaces, the canonical ladder)

Order the stories by dependency across the five Portal surfaces — store, engine, web, bot, dashboard:

1. **browse the catalogue** (web, over the engine) — depends on nothing the learner sees. Foundation rung.
2. **enrol in a course** (web → engine) — depends on rung 1: a learner can only enrol in a course they can see.
3. **open a lesson** (web → engine) — depends on rung 2: a lesson belongs to an enrolled course.
4. **track progress** (the split slices from A2.07.2: mark-complete, then dashboard) — depends on rung 3:
   progress is recorded against opened lessons; the dashboard surface reads it.

The branded **store** and the event-sourced **engine** behind one facade underlie every rung; the **bot** is
a parallel surface over the same facade that reuses rungs 1–3 without adding a dependency. The ladder is
runnable at every rung: after rung 1 the catalogue is live; after rung 2 enrolment works; and so on. This is
the canonical Portal ladder — browse → enrol → open a lesson → track progress — fixed for the rest of the
course.

The mis-order to show: putting "enrol" below "browse" — a learner cannot enrol in a course they cannot see;
the rung would have nothing runnable to demo. Dependency order is what keeps the ladder demoable.

## Hero interactive — the five surfaces over one facade

**The runnable ladder.** Step up the rungs (1–4). The figure shows the four rungs stacked over the store and
engine, with each rung tagged by its surface (web / dashboard) and the bot drawn as a parallel surface. The
readout reports, for the selected rung, what is runnable, which surface it touches, and what it depends on.

- control ids: `#otbRung` (segmented, `data-rung` = 1|2|3|4)
- pure function: `rungReadout(level) -> string` over the fixed four-rung ladder
- sample readout: "Rung 2 of 4 — enrol in a course (web → engine). Depends on rung 1 (browse the catalogue). Runnable now: a learner can browse and enrol. The store and engine underlie every rung; the bot reuses rungs 1–3."

## Main interactive — dependency order vs mis-order

**Prove the order.** A control toggles between the dependency-correct order and a mis-order (enrol before
browse). For each, the readout reports whether every rung has its dependency satisfied below it and whether
the ladder is runnable at every step.

- control ids: `#otbOrder` (segmented, `data-k` = correct|misordered)
- pure function: `orderCheck(kind) -> { brokenRungs:int, firstBroken:string|null, runnable:bool }`
- sample readout: "mis-ordered (enrol below browse) — 1 rung breaks: enrol sits below the browse it depends on, so it has no visible course to act on. The ladder is not runnable at every rung."

## Principle ↔ practice bridge

- principle: a backlog is a dependency-ordered ladder where each rung adds usable value, depends only on
  rungs below it, and leaves the system runnable.
- practice: the Portal stories order into browse → enrol → open a lesson → track progress over the store and
  engine, with the bot a parallel surface — runnable at every rung, the backlog Part III builds.
- take: ordering turns a set of ready stories into a ladder the loop can climb one provable rung at a time.

## References (Sources — real, vetted)

- Humble & Farley — *Continuous Delivery* — https://continuousdelivery.com/ — keeping the system releasable
  at every increment.
- Cohn, M. — *User Stories Applied* — https://www.mountaingoatsoftware.com/books/user-stories-applied —
  ordering a backlog by value and dependency.
- Adzic, G. — *Specification by Example* — https://gojko.net/books/specification-by-example/ — the ordered,
  testable backlog as the shared plan.

## Related (internal — must resolve)

- A2.01 value, A2.02 connextra, A2.03 invest; workshop hub; A2 landing; `/elixir/course`
- A2.07.2 split-and-test (prev)
- (A2.06 value-ladder named in prose only — not linked.)

## Pager

- prev: `/course/agile-agent-workflow/decomposition/workshop/split-and-test`
- next: workshop hub `/course/agile-agent-workflow/decomposition/workshop` (back to hub — module close)
