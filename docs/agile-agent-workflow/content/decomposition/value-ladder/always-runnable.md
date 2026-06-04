# A2.06.3 · Always runnable — deep-dive

- **Route:** `/course/agile-agent-workflow/decomposition/value-ladder/always-runnable`
- **File:** `html/agile-agent-workflow/decomposition/value-ladder/always-runnable.html`
- **Chapter:** A2 · Decomposition — **Position:** A2.06 · dive 3 of 3
- **Accent:** gold (prefix runs); burgundy (an orphaned rung cannot run)

## Lead

A ladder is composed of capabilities (dive 1) in dependency order (dive 2). This dive states the
property the order buys: **every rung leaves the system runnable and demoable.** Build the first
rung and it runs; build the first two and they run; every prefix of the ladder is a working,
demonstrable system. This is the structure the A3 roadmap layer later plans delivery over — named
here, not re-taught.

## Precise definition

A ladder is **always runnable** when, for every `k`, the prefix `r₁ … rₖ` is a runnable,
demoable system. This follows directly from dependency order: if every rung depends only on rungs
below it, then for any prefix, every dependency of every included rung is also included — nothing
points outside the prefix. The contrapositive is the failure: if a rung is included but a rung it
depends on is not, that rung is **orphaned** — it points at something not built, so the prefix
cannot run through it. Remove or skip a rung and every rung above it that depended on it is
orphaned.

"Runnable" is the demoability the A2.01 vertical slice gives each rung, extended to the whole
prefix: after rung `k` there is something a role can exercise end to end.

## Portal grounding (no-invent)

The Portal ladder runs at every prefix:
- after browse: a learner can browse the catalogue — demoable.
- after browse + enrol: browse, then enrol — demoable.
- after browse + enrol + open lesson: enrol and open a lesson — demoable.
- the full four: track progress over opened lessons — demoable.

Skip *enrol* and keep *open lesson* and *open lesson* is orphaned: it depends on enrolment that
was never built, so that prefix cannot run. Id authority: `Portal.ID.generate/1`,
`Portal.ID.decode/1` (`.type`, `.timestamp`). OTP is cited to `/elixir`, never re-taught.

## Hero interactive (frames the idea: every prefix runs)

A **prefix runner**. A slider/stepper sets `k`, the number of rungs built (1–4); the SVG lights
the prefix and the readout reports that the prefix `r₁ … rₖ` is runnable and names what a learner
can demo after it. Pure function: `prefixDemo(k) -> {runnable, capability}` over the fixed ladder.
Frames the property: the system is demoable after every rung.

## Main interactive (proves the consequence: skip a rung → an orphan appears)

A **runnability checker**. Four toggles mark each rung built or skipped; the checker reports
whether the built set runs, and on a skip it names the first **orphaned** rung — a built rung
whose dependency was skipped — and paints it burgundy. Pure function:
`runnable(set) -> {ok, orphan}` where `set` is the map of included rung keys and `orphan` is
the lowest rung whose dependency is missing. Different move from the hero: the hero confirms a
clean prefix runs; the checker shows what breaks runnability when a rung is dropped out of order.

## Worked example (prose + code)

Runnability as a predicate over the built set:

    deps = %{browse: [], enrol: [:browse], open: [:enrol], track: [:open]}

    runnable? = fn built ->
      Enum.all?(built, fn rung ->
        Enum.all?(deps[rung], &(&1 in built))   # every dependency is also built
      end)
    end

    runnable?.(MapSet.new([:browse, :enrol]))          # => true  — a clean prefix
    runnable?.(MapSet.new([:browse, :open]))           # => false — open is orphaned (enrol missing)

A clean prefix always passes; a built set that skips a rung leaves an orphan and fails. That is
why the ladder is built bottom-up: the order guarantees the prefix.

## Bridge

- **principle:** Every prefix of a dependency-ordered ladder is a runnable, demoable system; skip
  a rung and the rungs above it are orphaned.
- **practice (Portal):** browse, then enrol, then open a lesson, then track progress — demoable
  after each; skip enrol and "open a lesson" is orphaned and the prefix cannot run.

## Recap

A value ladder is the structure this chapter set out to build: capabilities, in dependency order,
runnable at every rung. The A3 roadmap layer plans delivery over exactly this ladder — which rung
ships in which iteration — and A4 specifies each rung before the Author builds it. (Named only;
A3 and A4 are taught later. Splitting an outsize rung is A2.05; the chapter's closing workshop,
A2.07, composes the whole Portal ladder.)

## References

Sources (real, vetted — from the registry):
- Continuous Delivery — https://continuousdelivery.com/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- User Stories Applied — https://www.mountaingoatsoftware.com/books/user-stories-applied

Related in this course:
- /course/agile-agent-workflow/decomposition/value-ladder (A2.06 hub)
- /course/agile-agent-workflow/decomposition/value-ladder/dependency-order (previous dive)
- /course/agile-agent-workflow/decomposition/value-ladder/compose-the-ladder (dive 1)
- /course/agile-agent-workflow/decomposition/value (A2.01, vertical slice)
- /course/agile-agent-workflow/why/two-layers (A1.04, roadmap layer plans over the ladder)
- /elixir/course

## Wiring

- Crumbs: jonnify / Agile Agent Workflow / A2 · Decomposition / A2.06 / A2.06.3 · Always runnable
- Pager: prev = `/course/agile-agent-workflow/decomposition/value-ladder/dependency-order`;
  next = `/course/agile-agent-workflow/decomposition/value-ladder` (back to the hub — last dive).
