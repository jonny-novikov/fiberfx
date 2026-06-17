# A3.5.1 · Shippable milestones — dive 1

- **Route:** `/course/agile-agent-workflow/roadmap/milestones/shippable-milestones`
- **File:** `html/agile-agent-workflow/roadmap/milestones/shippable-milestones.html`
- **Model copied verbatim:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/what-it-carries.html` (lesson).
- **Stamp:** `TSK0Ng9hnHJgW0`.

## Lead

A milestone is not a calendar date and not an internal checkpoint. It is a **usable capability boundary**: a
contiguous group of rungs whose completion leaves a real role able to do something useful. The test of a
shippable milestone is whether you could stop there and the product would still be worth using.

## Precise definition

Group the rungs so that each group ends at a point a real user can use. F6's three milestones, verbatim from
`phoenix.roadmap.md`:

1. **Ship the catalog** (F6.1–F6.5.5) — browse a persistent catalog and add courses, server-rendered in the
   jonnify design system, with inline errors.
2. **Make it live** (F6.6–F6.7) — search and create without reloads; every client updates live with a viewer count.
3. **Ship to users** (F6.8–F6.9) — sign in, run behind auth on a deployed clustered release, watch an operations
   dashboard.

Each is the first deployable product, then layered interactivity, then production reach. Re-grouping rungs edits
the roadmap, never a spec.

## The two interactives

### Hero (`.fig`) — the milestone grouper
- **Control:** `.solid-select#grpRung`, one button per named rung (`f6.1 … f6.9`), `data-c` set.
- **SVG:** three milestone bands; the chosen rung lights its true band; a small marker shows the band's boundary.
- **Pure function:** `groupOf(rung) -> {n, name, rungs, capability}` over the FIXED verbatim dataset.
- **Readout id `grpOut`:** names the milestone the rung belongs to and the capability the boundary unlocks.
- **Static default:** f6.1 → milestone 1, correct without JS.

### Content — "is this milestone shippable?" boundary test
- **Control:** `.solid-select#boundCand`, three candidate cut-points
  (`after f6.4`, `after f6.5.5`, `after f6.7`), `data-c` set.
- **Pure function:** `boundaryTest(cut) -> {usable:bool, why}` over the fixed dataset — a cut is shippable only if
  it ends at a real capability (after f6.5.5 = browse the catalog; after f6.7 = live; after f6.4 = no rendered UI
  yet, so not a usable boundary).
- **Readout id `boundOut`:** marks the cut `usable capability boundary` or `not yet usable` with the reason.
- Teaches a DIFFERENT move: the hero groups rungs into the SHIPPED milestones; this tests an arbitrary cut against
  the usable-capability rule.

## Worked Portal example

Cutting after F6.4 (the domain over the facade) leaves no rendered page — a developer can read and write the
domain, but no learner can browse. So F6.4 is not a milestone boundary; F6.5.5 (the rendered, persistent catalog)
is. The milestone is drawn at the capability, not at the convenient stopping point.

## Bridge

- **idea:** A milestone is a usable capability boundary — a contiguous group of rungs that leaves a real role able
  to do something useful.
- **elix:** F6 draws three: catalog, live, users. Each boundary is a deployable product; re-grouping rungs edits
  the roadmap, never a spec.
- **take:** Draw the milestone where a user could stop and still have something worth using.

## References

### Sources
- Continuous Delivery — https://continuousdelivery.com/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/

### Related in this course
- `/course/agile-agent-workflow/roadmap/milestones` (hub)
- `/course/agile-agent-workflow/roadmap/milestones/the-iteration-loop` (next)
- `/course/agile-agent-workflow/roadmap/roadmap-anatomy/the-iteration-table`
- `/course/agile-agent-workflow/roadmap/xp-small-batches`
- `/elixir/phoenix`

## Pager

- prev: `/course/agile-agent-workflow/roadmap/milestones` (hub)
- next: `/course/agile-agent-workflow/roadmap/milestones/the-iteration-loop` (A3.5.2)
