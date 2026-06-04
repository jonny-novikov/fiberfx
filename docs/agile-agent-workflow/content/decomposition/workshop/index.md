# A2.07 · Workshop — decomposing Portal (module hub)

- **Route:** `/course/agile-agent-workflow/decomposition/workshop`
- **File:** `html/agile-agent-workflow/decomposition/workshop/index.html`
- **Role:** module hub — the A2 capstone. Teaches decomposition on the Portal's **real** web surface (the F6
  Phoenix chapter in the companion `/elixir` course), decomposed into nine specified, built, and proven rungs.
- **Accent:** elixir-purple (`.ex`), the course signature — consistent with the A2 module hubs.

## Lead

A2.01–A2.06 each taught one move on toy stories. The capstone lands them where they were actually used: the
Portal's **web surface**, built in the companion course as chapter **F6** (Phoenix). A one-line vision — *serve
the Portal to people* — was decomposed into **nine vertical rungs** (`f6.1`–`f6.9`), each a real capability
carried by four artifacts, built over the unchanged engine, and proven before the next began. The decomposition
is not hypothetical: it already happened, rung by rung, in a repository the student can read.

## Precise definition

The **workshop** is the chapter's synthesis, made concrete on F6. Instead of an abstract pipeline, it walks the
real F6 roadmap: nine rungs, three milestones, the master invariant, and the git history that proves the
spec→build→reconcile cadence. The five Portal surfaces are fixed (no-invent): a branded **store**, an
event-sourced **engine** behind one facade, a Phoenix **web** app, a Telegram **bot**, a student **dashboard**.
F6 is the web surface; the canonical value ladder within it climbs from a bootstrapped endpoint to a live
operations dashboard.

The master invariant (verbatim from `phoenix.roadmap.md`): *"The web layer calls only the `Portal` facade and
renders only the closed `%Portal.Error{}` set."* The four artifacts per rung: a line in `phoenix.roadmap.md`, the
spec `f6.N.md`, stories + Given/When/Then in `f6.N.stories.md`, the agent brief `f6.N.llms.md`.

## The framing interactive (hub) — the F6 roadmap slider

**The F6 web chapter, rung by rung.** An SVG of the nine rungs in a row, grouped into the three milestones (M1
ship the catalog · M2 make it live · M3 ship to users), with a dashed frontier after F6.6 separating the six
shipped rungs from the three still specified. A single range slider (`#f6Slider`, `min=1 max=9 step=1`) selects a
rung; the readout reports the **four questions a decomposition has to settle for every rung** — *what* it
delivers, *when* it was specified and shipped (from git history), *why* (which milestone it serves), and *how* it
is proven (story count + one verbatim Given/When/Then). The data is a fixed nine-entry `RUNGS` array transcribed
from the real `docs/elixir/specs/phoenix/` spec system; status + dates are derived from the git log. It frames the
module: one vision, nine rungs, three milestones, every rung answered from the repository.

- control id: `#f6Slider` (range input; `#f6Val` shows `F6.N`; `#f6Out` is the live `.geo-readout`).
- pure function: `paintRung(n)` — repaints the nine SVG rung cells (current = elixir-purple, shipped = sage,
  specified = blue dashed) and rewrites `#f6Out` from `RUNGS[n-1]` (no side effects beyond the DOM it owns).
- supporting data: `var RUNGS` (9 entries: `n`, `title`, `ms`, `status`, `stories`, `what`, `when`, `gwt`),
  `MS` (milestone labels), and the `SHIP`/`SPEC`/`CUR` palettes.
- sample readout (F6.1): "F6.1 · Bootstrap the Phoenix Portal — what: the headless F5 engine stands up as a
  Phoenix app… when: specced 02 Jun, shipped 03 Jun. why: milestone 1, ship the catalog. how: 5 stories in
  f6.1.stories.md; proven by — Given the running app, when I request GET /health, then I receive 200 with body ok."
- take: "A decomposition answers why, what, when, and how for every rung — and a good one leaves that trail in the
  repository, not only in a plan."

The interactive degrades: the slider, SVG, and a correct F6.1 readout are present in static markup; JS only
enhances. It honours `prefers-reduced-motion` (no animation; transitions are CSS-only on fill/stroke) and uses no
browser storage.

## The three dives (arc: write → slice → order, i.e. what & why → how → when)

1. **A2.07.1 · `vision-to-stories`** — read the F6 web vision into its nine-rung value ladder; each rung a real
   capability and the actual user story quoted from its `f6.N.stories.md`. *(what & why)*
2. **A2.07.2 · `split-and-test`** — one vision split into nine vertical rungs; one rung (F6.6 LiveView) shown as
   its four real artifacts and proven by its Given/When/Then. *(how)*
3. **A2.07.3 · `order-the-backlog`** — the roadmap lens: nine rungs in three milestones, dependency-ordered and
   runnable, plus the git history of how the specs evolved (specified → shipped → reconciled). *(when)*

## Principle ↔ practice bridge

- principle: a decomposition is only proven when it is run end to end on a real input and leaves a readable trail
  — what, why, when, and how for every increment — not demonstrated one move at a time on a toy.
- practice: the F6 chapter — one vision, nine rungs, four artifacts each, three milestones, one unchanged facade —
  is that trail; the slider and the three dives read it straight from the repository.
- take: the workshop is where the chapter stops being six techniques and becomes one real, ordered, proven backlog.

## References (Sources — real, vetted)

- Cohn, M. — *User Stories Applied* — https://www.mountaingoatsoftware.com/books/user-stories-applied — turning a
  product vision into a story backlog, end to end.
- Adzic, G. — *Specification by Example* — https://gojko.net/books/specification-by-example/ — deriving a shared,
  testable backlog from a goal.
- Humble & Farley — *Continuous Delivery* — https://continuousdelivery.com/ — a backlog ordered so the system
  stays releasable at every rung.

## Related in this course (internal — must resolve)

- A2.07.1 vision-to-stories, A2.07.2 split-and-test, A2.07.3 order-the-backlog (own dives)
- A2.01 `/decomposition/value`, A2.02 `/decomposition/connextra`, A2.03 `/decomposition/invest`
- A2 landing `/decomposition`
- Companion `/elixir` cross-links (the rungs, built): `/elixir/phoenix` (the F6 chapter),
  `/elixir/phoenix/contexts` (F6.4), `/elixir/phoenix/liveview` (F6.6), `/elixir/phoenix/deployment` (F6.8);
  `/elixir/course`.

## Pager

- prev: `/course/agile-agent-workflow/decomposition` (A2 landing)
- next: `/course/agile-agent-workflow/decomposition/workshop/vision-to-stories` (own first dive)
