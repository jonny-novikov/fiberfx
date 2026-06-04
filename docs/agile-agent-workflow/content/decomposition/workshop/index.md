# A2.07 · Workshop — decomposing Portal (module hub)

- **Route:** `/course/agile-agent-workflow/decomposition/workshop`
- **File:** `html/agile-agent-workflow/decomposition/workshop/index.html`
- **Role:** module hub — the A2 capstone. Runs the whole chapter sequence on the Portal vision.
- **Accent:** elixir-purple (`.ex`), the course signature — consistent with the A2 module hubs.

## Lead

A2.01–A2.06 each taught one move. This module runs them in order, on one input: the one-line Portal
vision. The output is the backlog the rest of the course specifies, briefs, and builds — a runnable,
demoable ladder of stories across the five Portal surfaces.

## Precise definition

The **workshop** is the chapter's synthesis: a single pass that takes the Portal vision and produces an
ordered, tested backlog by applying every A2 technique in dependency order —

1. **value, not tasks** (A2.01) — a unit is a change in what a role can do, not a chore.
2. **the Connextra form** (A2.02) — "as a `<role>`, I want `<capability>`, so that `<benefit>`."
3. **INVEST** (A2.03) — the six yes/no readiness tests.
4. **Given/When/Then acceptance** (A2.04) — the concrete, executable definition of done.
5. **splitting** (A2.05) — cut the too-big stories into rung-sized vertical slices.
6. **the value ladder** (A2.06) — order the slices so each rests on the ones below and the system stays runnable.

The five surfaces are fixed (no-invent): a branded **store**, an event-sourced **engine** behind one
facade, a Phoenix **web** app, a Telegram **bot**, a student **dashboard**. The canonical value ladder is
fixed: browse the catalogue → enrol → open a lesson → track progress.

## The framing interactive (hub)

**The A2 pipeline applied to one vision.** A horizontal pipeline of six stages (value · form · INVEST ·
acceptance · splitting · ladder). Selecting a stage reports what that technique does to the work in transit
and what the backlog looks like after it. Pure function `stageReadout(key)` over a fixed six-entry dataset;
live `.geo-readout`. It frames the module: one input, six transforms, one backlog out.

- control ids: `#wsPipe` (segmented buttons, `data-k` = value|form|invest|accept|split|ladder)
- pure function: `stageReadout(stageKey) -> string`
- sample readout: "Stage 2 of 6 — the Connextra form: each kept story is rewritten as role, want, reason, so the value is on the card before it is built. Backlog so far: 4 candidate stories, all in role-want-reason form."

## The three dives (arc: write → slice → order)

1. **A2.07.1 · `vision-to-stories`** — take the vision; apply value-not-tasks, Connextra, INVEST, and
   Given/When/Then to produce a first story set. Some stories are still too big — that is the input to dive 2.
2. **A2.07.2 · `split-and-test`** — apply splitting to the too-big stories; re-test each slice against
   INVEST; converge on rung-sized stories.
3. **A2.07.3 · `order-the-backlog`** — apply the value ladder to order the stories by dependency across the
   five surfaces; the runnable, demoable backlog carried into Part III (A3 roadmap).

## Principle ↔ practice bridge

- principle: a method is only proven when it is run end to end on a real input, not demonstrated one move at
  a time.
- practice: the six A2 techniques, applied in order to the Portal vision, yield the ordered, tested backlog
  the course builds from.
- take: the workshop is where the chapter stops being six techniques and becomes one backlog.

## References (Sources — real, vetted)

- Cohn, M. — *User Stories Applied* — https://www.mountaingoatsoftware.com/books/user-stories-applied — the
  end-to-end practice of turning a vision into a story backlog.
- Adzic, G. — *Specification by Example* — https://gojko.net/books/specification-by-example/ — deriving a
  shared, testable backlog from a goal.
- Humble & Farley — *Continuous Delivery* — https://continuousdelivery.com/ — a backlog ordered so the system
  stays releasable at every rung.

## Related in this course (internal — must resolve)

- A2.07.1 vision-to-stories, A2.07.2 split-and-test, A2.07.3 order-the-backlog (own dives)
- A2.01 `/decomposition/value`, A2.02 `/decomposition/connextra`, A2.03 `/decomposition/invest`
- A2 landing `/decomposition`; `/elixir/course`
- (A2.04 acceptance, A2.05 splitting, A2.06 value-ladder named in prose only — built in parallel, NOT linked.)

## Pager

- prev: `/course/agile-agent-workflow/decomposition` (A2 landing)
- next: `/course/agile-agent-workflow/decomposition/workshop/vision-to-stories` (own first dive)
