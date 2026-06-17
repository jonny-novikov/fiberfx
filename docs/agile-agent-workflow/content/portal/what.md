# A7 · orientation dive 2 — what the chapter covers

- **Route:** `/course/agile-agent-workflow/portal/what` (`portal/what.html`)
- **Eyebrow:** `A7 · orientation dive 2`
- **Crumbs:** `jonnify / Agile Agent Workflow / A7 · Portal exemplar / What it covers`.
- **Accent:** gold on interactive accents; `h1 .ex` stays elixir-purple.
- **Pager:** prev `= /course/agile-agent-workflow/portal/why`, next `= /course/agile-agent-workflow/portal/how`.

## Reverse-verification echo (open with this)

A6 makes each rung production-grade; A7 runs the whole loop end to end so the hardened rungs become one shipped
system. This dive names what that run covers: the seven steps A7.01–A7.07, the zero-to-production arc — at the
roadmap's altitude, with each step's internals deferred to the unseeded triad.

## Lead

A7 covers one thing at length: the whole loop, run once, on the Portal. Seven steps carry it from an empty
repository to a deployed platform. Each step runs a technique a prior chapter taught; the chapter is the composition,
not a new technique.

## The seven steps (named as a sequence only)

- A7.01 — Decompose the vision — runs A2.
- A7.02 — Plan the delivery — runs A3.
- A7.03 — Specify the rung — runs A4.
- A7.04 — Brief the Author — runs A5.
- A7.05 — Build the increment — runs A5.
- A7.06 — Harden to production — runs A6.
- A7.07 — Accept and ship — closes the loop.

## Interactive 1 (hero figure) — the seven-step walk

- **Element ids:** `stepSel` (`.solid-select`, gold; seven buttons A7.01…A7.07), `stepOut` (`.geo-readout`), SVG
  step nodes `sw-0`…`sw-6`, a phase label `sw-phase`, a technique label `sw-tech`.
- **Fixed dataset:** the seven steps `{id, phase, runs, chapter}` (the table above; `chapter` is the prior chapter
  route the step runs, or "" for A7.07).
- **Pure fns:** `stepAt(i)`; `priorChapter(i)` → the route of the prior chapter the step runs (or `null`);
  `readoutFor(i)` → readout string. No step internals are computed — only the phase name and which chapter it runs.
- **Sample readout (A7.04):** `A7.04 · Brief the Author — runs A5 (the .llms.md the agent builds from). Step 4 of 7
  of the zero-to-production arc. · the step's internals are detailed once the a7.* triad is seeded.`
- **Take:** each step is a prior chapter's technique run in sequence; the arc is the seven composed.

## Interactive 2 (main content) — the milestone grouping

- **Element ids:** `msSel` (`.solid-select`, gold; three buttons: "M1 · plan & specify", "M2 · brief & build",
  "M3 · harden & ship"), `msOut` (`.geo-readout`), SVG group cells `ms-0`…`ms-2`, a count cell `ms-count`.
- **Fixed dataset:** the seven steps grouped into three milestones at roadmap altitude:
  - M1 · plan & specify — A7.01, A7.02, A7.03
  - M2 · brief & build — A7.04, A7.05
  - M3 · harden & ship — A7.06, A7.07
- **Pure fns:** `groupAt(i)` → the milestone record `{label, steps}`; `stepCount(i)` → the number of steps in the
  milestone; `readoutFor(i)`.
- **Sample readout (M2):** `M2 · brief & build — A7.04, A7.05 (2 steps). The Author turns the spec into running
  code, briefed by the .llms.md. The milestone's internals are detailed once the a7.* triad is seeded.`
- **Take:** the seven steps group into three milestones — the same shape the roadmap layer taught, run on the whole
  loop.
- **`.note`:** the per-step detail (acceptance criteria, the demo each ships) is deferred to the seeded
  `a7.{md,stories.md,llms.md}` triad; this dive names the arc, not the internals.

## Bridge

- **Principle:** an end-to-end run still groups into milestones — releasable checkpoints, not one big bang.
- **Portal practice:** A7's seven steps ship the Portal's five surfaces in dependency order, each milestone a
  releasable checkpoint on the way from empty repository to deployed platform.
- **Take:** the zero-to-production arc is seven steps in three milestones, each step a prior technique run.

## References

**Sources:**
- The Pragmatic Programmer — `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
  — the tracer bullet and walking skeleton: the whole system end to end before the backlog fills in.
- Continuous Delivery — `https://continuousdelivery.com/` — milestones as releasable checkpoints across the arc.
- Extreme Programming Explained — `https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/`
  — small batches grouped into iterations.

**Related in this course:** `/portal`, `/roadmap`, `/spec`, `/decomposition`, `/portal/how`, `/elixir/phoenix`,
`/elixir/course`.
