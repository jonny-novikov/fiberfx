# A3.8 · Workshop — roadmapping Portal (module hub)

- **Route:** `/course/agile-agent-workflow/roadmap/workshop`
- **File:** `html/agile-agent-workflow/roadmap/workshop/index.html`
- **Accent:** elixir-purple (`<span class="ex">` in the `<h1>`; `.cell.elix`).
- **Stamp:** reuse `TSK0Ng9hnHJgW0` verbatim.
- **Model copied:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/index.html` (hub).

## Lead

A3.4–A3.7 each taught one move of the roadmap layer. The workshop runs all of them on one real target, the
Portal's web chapter, and produces an artifact you can read: the F6 `phoenix.roadmap.md` itself. The capstone is
not hypothetical — the roadmap it reconstructs already shipped, rung by rung, in the companion course.

## Precise framing

The roadmap layer decides *how we deliver* the A2 backlog, separately from *what we build and prove* (the spec
layer, A4). The workshop is the layer applied once end to end: the A2 value ladder becomes a chapter roadmap with
three milestones and a per-iteration table, a tracer bullet is chosen and breadth deferred, and the chapter roadmap
sits inside a program view of web and bot over the one `Portal` facade. The worked output reproduces the real F6
`phoenix.roadmap.md`; re-ordering rungs edits the roadmap, never a spec.

## Framing interactive (hero figure) — the workshop pipeline

- **Move:** step through the five workshop stages over a fixed dataset and name the artifact each one produces.
- **Stages (fixed dataset):**
  1. `ladder` — A2 value ladder → produces *the ordered nine-rung ladder (f6.1…f6.9)*.
  2. `milestones` — group rungs → produces *three milestones (ship the catalog · make it live · ship to users)*.
  3. `table` — fill each rung → produces *the per-iteration table (Rung | Ships | Demo | Harness | Feedback)*.
  4. `tracer` — pick the first thread → produces *the tracer bullet (f6.1: request → facade → render) + deferred seams*.
  5. `program` — place the chapter in the program → produces *the program view (web F6 + bot F10 over one facade)*.
- **Control ids:** `.solid-select#wsPick` buttons `data-k=ladder|milestones|table|tracer|program`,
  `data-c=blue|sage|gold|elixir|elixir`.
- **SVG:** five stacked stage rows `#ws-ladder … #ws-program` plus a master-invariant band.
- **Readout id:** `#wsOut` (`aria-live="polite"`). Static default = the `ladder` stage.
- **Pure function:** `stageArtifact(key) -> string` over `STAGES` (each entry holds the verbatim artifact phrase).
- **Sample readout:** `Stage 1 · ladder to roadmap — produces: the ordered nine-rung ladder f6.1…f6.9 from A2's value ladder. The order is the roadmap; no rung defines behaviour.`

## Bridge

- **idea:** the roadmap layer is five moves applied once end to end — order the ladder, group milestones, fill the
  iteration table, choose the tracer, place the chapter in the program.
- **practice:** the workshop's output reproduces the real F6 `phoenix.roadmap.md` — rungs point at specs and define
  no behaviour; re-ordering rungs edits the roadmap, never a spec.
- **take:** the workshop is the roadmap layer applied once on the Portal — the delivery plan Part VII executes.

## The three dives (`.mods` grid)

- A3.8.1 `ladder-to-roadmap` — A2's value ladder → a chapter roadmap (milestones + the iteration table).
- A3.8.2 `choose-the-tracer` — choose the tracer bullet (F6.1) and name the deferred seams.
- A3.8.3 `the-program-view` — the program roadmap: web (F6) + bot (F10) over one facade.

## Pager

- prev `/course/agile-agent-workflow/roadmap`
- next `/course/agile-agent-workflow/roadmap/workshop/ladder-to-roadmap`

## References — Sources (vetted)

- Continuous Delivery — https://continuousdelivery.com/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/

## Related in this course (resolve)

- `/course/agile-agent-workflow/roadmap/workshop/ladder-to-roadmap`
- `/course/agile-agent-workflow/roadmap/workshop/choose-the-tracer`
- `/course/agile-agent-workflow/roadmap/workshop/the-program-view`
- `/course/agile-agent-workflow/decomposition/workshop`
- `/course/agile-agent-workflow/roadmap/roadmap-anatomy`
- `/course/agile-agent-workflow/roadmap`
- `/elixir/phoenix`
