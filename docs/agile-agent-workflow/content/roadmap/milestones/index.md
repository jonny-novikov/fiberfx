# A3.5 · Milestones and iterations — module hub

- **Route:** `/course/agile-agent-workflow/roadmap/milestones`
- **File:** `html/agile-agent-workflow/roadmap/milestones/index.html`
- **Accent:** elixir-purple (`<span class="ex">` in the `<h1>`; the `.cell.elix` bridge cell).
- **Model copied verbatim:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/index.html` (hub).
- **Stamp:** `TSK0Ng9hnHJgW0` (reused verbatim).

## Lead

A backlog is not a delivery plan. The roadmap layer groups the rungs into **milestones** — each a usable
capability boundary — and runs each rung through **one iteration** over four columns. This module reads the real
F6 ladder: nine named rungs, three milestones, the per-iteration table, ordered by dependency and product
priority so the most valuable, least risky thread ships first.

## Precise definition

A **milestone** is a contiguous group of rungs whose completion leaves a real role able to do something useful —
a *usable capability boundary*, not an internal checkpoint. The Portal's web chapter F6 has three, verbatim from
`phoenix.roadmap.md`:

| Milestone | Rungs | What you can do at the end |
|---|---|---|
| 1 · Ship the catalog | F6.1–F6.5.5 | browse a persistent catalog and add courses, server-rendered in the jonnify design system, with inline errors |
| 2 · Make it live | F6.6–F6.7 | search and create without reloads; every client updates live with a viewer count |
| 3 · Ship to users | F6.8–F6.9 | sign in, run behind auth on a deployed clustered release, watch an operations dashboard |

Re-grouping rungs edits the roadmap, never a spec.

## Worked Portal example

The nine named rungs `f6.1 … f6.9` over the unchanged `Portal` facade, assigned to the three milestones. The
assignment is a property of the roadmap; moving a rung between milestones changes the delivery plan and leaves
every `f6.N.md` spec untouched.

## The two interactives (hub carries ≥1 framing interactive)

### Framing interactive (hero `.fig`) — assign the nine rungs to the three milestones
- **Control:** `.solid-select#mileAssign` with one button per named rung
  (`f6.1, f6.2, f6.3, f6.4, f6.5, f6.6, f6.7, f6.8, f6.9`), each `data-c` set so the active button is visible.
- **SVG:** three milestone bands; the picked rung lights its true band.
- **Pure function:** `milestoneOf(rung) -> {n, name, capability}` over a FIXED `RUNGS` dataset (the verbatim
  table). `rungsIn(n) -> [rung]` lists a milestone's rungs.
- **Readout id `mileOut`:** e.g. `f6.1 → milestone 1 · Ship the catalog · rungs f6.1–f6.5.5 · at the end: browse a persistent catalog and add courses. A milestone is a usable capability boundary.`
- **Static default:** the f6.1 → milestone 1 row, correct without JS.

### Content interactive — capability boundary scanner
- **Control:** `.solid-select#mileScan`, one button per milestone (`1, 2, 3`), `data-c` set.
- **Pure function:** `boundaryOf(n) -> {name, lastRung, capability, shippable:true}` over the fixed dataset.
- **Readout id `scanOut`:** names the milestone's last rung and the capability that boundary unlocks.
- Teaches a DIFFERENT move from the hero: the hero assigns rungs to milestones; this reads each milestone as a
  shippable boundary.

## Bridge (principle → Portal practice)

- **idea:** Group the rungs into milestones — each a usable capability boundary — and run each rung through one
  iteration; the most valuable, least risky thread ships first.
- **elix:** F6's three milestones over the one `Portal` facade: ship the catalog · make it live · ship to users.
  Re-grouping rungs edits the roadmap, never a spec.
- **take:** A milestone is a place a real role can stop and use the product; the rungs in it are the iterations
  that get there.

## The three dives (`.mods` grid)

- A3.5.1 `shippable-milestones` — grouping rungs into milestones, each a usable capability boundary.
- A3.5.2 `the-iteration-loop` — one iteration over Ships | Demo | Harness | Feedback; the PR-sized increment.
- A3.5.3 `sequencing-the-ladder` — order by dependency and product priority; the most valuable, least risky first.

## References

### Sources (real, vetted)
- Continuous Delivery — https://continuousdelivery.com/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/

### Related in this course
- `/course/agile-agent-workflow/roadmap/milestones/shippable-milestones`
- `/course/agile-agent-workflow/roadmap/milestones/the-iteration-loop`
- `/course/agile-agent-workflow/roadmap/milestones/sequencing-the-ladder`
- `/course/agile-agent-workflow/roadmap/roadmap-anatomy/the-iteration-table`
- `/course/agile-agent-workflow/roadmap/xp-small-batches`
- `/course/agile-agent-workflow/roadmap`
- `/elixir/phoenix`

## Pager

- prev: `/course/agile-agent-workflow/roadmap` — A3 · The roadmap layer
- next: `/course/agile-agent-workflow/roadmap/milestones/shippable-milestones` — A3.5.1
