# A3 · The road ahead — a deep overview of the eight A3 modules ahead

- **Route:** `/course/agile-agent-workflow/roadmap/the-road-ahead`
- **File:** `html/agile-agent-workflow/roadmap/the-road-ahead.html`
- **Numbering:** A3 · orientation dive 3 (of 3)
- **Accent:** elixir-purple (`.ex`)
- **Stamp:** `TSK0Ng9hnHJgW0`

## Lead

The third and last orientation dive of A3. The first dive recapped where the course stands; the
second defined what the roadmap layer is and why it deserves its own layer. This dive takes the
**WHEN** and the **HOW**, then walks the eight teaching modules the chapter is built from. WHEN: the
roadmap is written after decomposition, read before building, and re-ordered by feedback between
rungs — a different cadence from the spec, which only feedback edits. HOW: thin-but-robust
increments are grouped into milestones and run through an inspect-and-adapt loop — ship a rung, demo
it, take feedback, re-order the roadmap, build the next. The eight modules are described here; none
are linked, because none are built yet — each becomes a hub with its own deep-dive subpages as the
chapter is authored.

## Precise definition

Two facts are load-bearing for the chapter ahead:

- **WHEN the roadmap acts.** Decomposition produces the backlog; the roadmap is written from it,
  read at the start of each rung to pick the next slice, and re-ordered by feedback between rungs. It
  changes often and coarsely. The spec changes rarely and only through feedback. Same workflow, two
  cadences: the roadmap re-orders; the spec is edited.
- **HOW the roadmap is walked.** A rung is a thin-but-robust increment: a narrow vertical slice built
  to production quality, not a flimsy stub. Rungs group into shippable milestones. The loop walks
  them: ship a rung, demo it, take feedback, re-order the roadmap, build the next. The loop re-orders
  the roadmap; it does not edit a spec and it does not decide the work — the Operator does, reading
  what the demo and the feedback show.

## The eight modules ahead (A3.1–A3.8)

A buckets vocabulary keeps the tour honest: each module serves one of seven concerns —
{philosophy, artifact, robustness, milestones, program, tracer, workshop}. They build in order, from
the values behind the layer to a worked roadmap of the Portal.

1. **A3.1 — Agile, distilled** (bucket: philosophy). The principles that drive the workflow,
   separated from the ceremony that does not. The values and the loop behind every later technique,
   stripped to what matters for one thin slice.
2. **A3.2 — Extreme Programming for small batches** (bucket: philosophy). Small releases, incremental
   design, and continuous feedback — the XP practices that survive and sharpen when the batch is a
   single, provable increment built by an Author/Operator pair.
3. **A3.3 — Anatomy of a roadmap.md** (bucket: artifact). What a chapter roadmap carries: the
   deliverable, the start/end handoff, the architecture decision, the milestones, the per-iteration
   table, and the open decisions — each line pointing at a spec without restating it.
4. **A3.4 — Thin but robust** (bucket: robustness). Each increment is a narrow vertical slice built
   to production quality. The module draws the line between thin and flimsy: what "robust" adds to
   "thin" on every rung.
5. **A3.5 — Milestones and iterations** (bucket: milestones). Grouping rungs into shippable
   milestones; the Ships/Demo/Harness/Feedback table; sequencing the rungs by dependency and
   priority, then walking them under feedback.
6. **A3.6 — The program roadmap** (bucket: program). The roadmap of roadmaps: sequencing whole
   chapters of work, and running parallel surfaces over one facade — dependency and value across a
   program, not one feature.
7. **A3.7 — Tracer bullets and walking skeletons** (bucket: tracer). A thin end-to-end thread built
   first, before depth — de-risking integration early by proving the architecture runs end to end.
8. **A3.8 — Workshop — roadmapping Portal** (bucket: workshop). The full sequence on the Portal: write
   Portal's chapter and program roadmaps — the delivery plan executed in Part VII.

## How the eight sequence

The modules are ordered, not a menu. Philosophy first (A3.1, A3.2) — the values and the small-batch
practices that the rest assumes. Then the artifact (A3.3) — the `roadmap.md` those values produce.
Then what makes a rung worth a roadmap line (A3.4, robustness), how rungs group into milestones
(A3.5), and how milestones scale to a whole program (A3.6). A3.7 is the de-risking move that runs
before the bulk of the backlog: one thin end-to-end thread. A3.8 puts it all on the Portal. The
sequence itself is a thin-but-robust progression: each module is small, complete, and stands on the
ones before it.

## Worked Portal example

Take the Portal's F6 web backlog from the A2 workshop — nine rungs of user stories, ordered into a
value ladder. The eight modules ahead turn that ladder into a worked plan. A3.3 gives the
`roadmap.md` its shape: a deliverable (the F6 web surface), a start/end handoff, the architecture
decision (one facade, parallel surfaces over it), the F6 milestones, the per-iteration table, and
the open decisions. A3.4 holds each F6 rung to thin-but-robust. A3.5 groups the nine rungs into
milestones and walks them with the Ships/Demo/Harness/Feedback table. A3.7 picks the first rung — a
tracer that renders one page end to end over the facade — to de-risk integration before the rest.
A3.8 writes the whole thing: the F6 chapter roadmap plus the program roadmap that sequences F6
against the surfaces around it. That delivery plan is executed in Part VII. The roadmap points at
each rung's spec and defines no behaviour; the Operator sequences, the Author builds.

## Interactive 1 — hero — the eight-module map (tour the chapter ahead)

- **Move:** tour the chapter ahead. Select one of A3.1–A3.8 and read its title, one-line abstract,
  and which bucket it serves. Descriptive, non-link — the modules are not built.
- **Markup:** an SVG row of eight nodes A3.1–A3.8 laid left to right and joined by a dashed flow. A
  `.solid-select` of eight buttons (A3.1–A3.8); each SVG node is also selectable (click / keyboard).
  Default selection: A3.1.
- **Control ids:** `mapSel` (the button group), nodes `mod-0`…`mod-7`, readout `mapOut`.
- **Pure functions over a fixed `MODULES` array (id/title/one/bucket):**
  - `moduleReadout(i) -> string` — the full readout for module `i`: id · title — one-line abstract ·
    Serves: bucket · position in the sequence.
  - `bucketGloss(bucket) -> string` — a short gloss for the named bucket.
- **Sample readout:** `A3.1 · Agile, distilled — the principles that drive the workflow, separated
  from the ceremony that does not. Serves: philosophy — the values and the loop behind every later
  technique. · module 1 of 8; the chapter opens here.`

## Interactive 2 — main — the inspect-and-adapt loop / milestone grouping (show the HOW)

- **Move:** show the HOW that walks the roadmap. Group a fixed set of rungs into milestones and step
  the inspect-and-adapt loop; report the cadence at each step. Distinct from the hero's module tour.
- **Markup:** a cyclic SVG of five loop stages — ship → demo → feedback → re-order → build — drawn as
  a ring; the current stage is highlighted. A `.solid-select` of the five stages (`loopSel`) steps
  the loop; a milestone strip shows a fixed set of seven rungs grouped into three milestones. Default
  stage: ship.
- **Control ids:** `loopSel` (the five stage buttons), ring nodes `stg-0`…`stg-4`, the milestone
  strip `msStrip`, readout `loopOut`.
- **Pure functions over fixed `STAGES` (5) and `RUNGS` (7, each carrying a milestone index) arrays:**
  - `groupMilestones(rungs) -> [{name, rungs:[...]}]` — fold the seven rungs into their three
    milestones, preserving order.
  - `stageReadout(s) -> string` — for stage index `s`: the stage name, what it does to the roadmap or
    the spec, and the cadence note (the loop re-orders the roadmap; only feedback edits a spec).
- **Invariant proven:** the loop re-orders the roadmap; it never edits a spec, and it does not decide
  — the Operator reads the demo and the feedback and re-orders. Milestones are an ordered grouping of
  rungs, not new behaviour.
- **Sample readout:** `Stage 3 of 5 · re-order — feedback from the demo re-orders the roadmap: the
  next rung may change. Touches the roadmap, never a spec. Milestones: M1 (rungs 1–2) · M2 (rungs
  3–5) · M3 (rungs 6–7). The loop re-orders; the Operator decides; only feedback edits a spec.`

## Principle ↔ practice bridge

- **.cell.idea (principle):** A chapter is a planned sequence of increments — thin-but-robust rungs,
  grouped into milestones, walked under feedback in a fixed order that the loop re-orders as it goes.
- **.arrow**
- **.cell.elix (Portal practice):** A3 carries the Portal backlog into a `roadmap.md` — eight modules
  from the agile values to a worked Portal roadmap — executed rung by rung in Part VII.
- **.take:** The road ahead is eight modules and one move: turn a backlog into an ordered,
  milestone-grouped delivery plan, walked by the inspect-and-adapt loop and executed on the Portal.

## References

### Sources
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
  — tracer bullets and walking skeletons: the first thin increment that runs end to end.
- Continuous Delivery — https://continuousdelivery.com/ — keeping the system releasable at every
  increment; delivery as the discipline the eight modules plan.
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
  — small batches, iterations, and the inspect-and-adapt loop that walks the roadmap.

### Related in this course
- A3 — The roadmap layer (`/course/agile-agent-workflow/roadmap`) — the chapter landing.
- A2 — Decomposition (`/course/agile-agent-workflow/decomposition`) — the backlog these modules sequence.
- A1.03 — The Author/Operator loop (`/course/agile-agent-workflow/why/loop`) — the cadence the loop walks.
- A1.04 — Two layers: roadmap and specs (`/course/agile-agent-workflow/why/two-layers`) — the line A3 inherits.
- Companion — Phoenix (F6) (`/elixir/phoenix`) — the real chapter built from a worked roadmap.
- Companion — Functional Programming in Elixir (`/elixir/course`) — the Portal's Elixir and OTP foundations.

## Wiring

- Route-tag (4 segments): `course/agile-agent-workflow`(link) · `roadmap`(link) · `the-road-ahead`(`.rcur`).
- Pager: prev = `/course/agile-agent-workflow/roadmap/the-roadmap-layer` (built in parallel — a
  `links` FAIL on this one route is expected until it lands) · next =
  `/course/agile-agent-workflow/roadmap` (back to the landing, closing the loop).
- Footer: canonical `.foot-cols` + stamp `TSK0Ng9hnHJgW0`.
