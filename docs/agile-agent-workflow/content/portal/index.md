# A7 · Portal exemplar (zero to production) — chapter landing

- **Route:** `/course/agile-agent-workflow/portal` (`portal/index.html`)
- **Eyebrow:** `A7 · chapter overview`
- **Crumbs:** `Agile Agent Workflow / A7 · Portal exemplar` (two-element landing form)
- **Accent:** gold (`--gold` / `--gold-bright`) on interactive accents; `h1 .ex` stays elixir-purple (shared CSS).
- **Pager:** prev `= /course/agile-agent-workflow/reliability` (A6 landing — built by the A6 sibling this batch;
  expected `links` transient until A6 lands), next `= /course/agile-agent-workflow/portal/why`.

## Grounding (NO seeded triad)

A7 has **no** `a7.*` triad. Grounded ONLY on:

- `aaw.roadmap.md` — Part VII row: "Portal exemplar (zero to production) · `/portal` · the whole loop run end to end
  on the Portal · planned"; the compose diagram line "A7 Portal exemplar ──▶ the loop run end to end, zero to
  production".
- `aaw.progress.md` — "A7 · Portal exemplar — `/portal` ○ 0% (planned)"; "A7.01–A7.07 (7 steps) · the whole loop run
  end to end".

The seven steps A7.01–A7.07 are named **as a sequence only**, at the roadmap's altitude. Their content is deferred
to the unseeded triad (a `.note`). No step content, module, API, or Portal surface is invented beyond the five
canonical surfaces and `Portal.ID.generate/1` / `Portal.ID.decode/1`.

## Lead

Every Part of the course taught one move on a worked fragment. A7 runs the whole loop — decompose, roadmap, spec,
brief, build, harden, accept — end to end on the Portal, zero to production. This is the capstone: the single
uninterrupted run that proves the moves compose into a shipped, multi-surface system, from an empty repository to a
deployed Portal.

## Reverse-verification framing (A6 ⇐ A7)

A7 is worth running only because every rung it ships was first made production-grade by A6. A zero-to-*production*
exemplar cannot run on an increment that only passes the happy path; the end-to-end run is meaningful precisely
because each rung was hardened first. The landing states this in prose; the `why` dive opens by echoing it.

## Interactive 1 (hero figure) — the course-arc selector, re-centred on A7

- **Element ids:** `arcSel` (the `.solid-select`), `arcOut` (`.geo-readout`, `aria-live="polite"`), SVG nodes
  `arc-0`…`arc-7`.
- **Fixed dataset:** the eight Parts A0–A7 with `{id, title, route, delivers, status}`. A0–A6 `status:"built"`,
  A7 `status:"here"`. Pre-selected: A7 (index 7).
- **Pure fns:** `partsBefore(i)` → count of `built` parts before index `i`; `readoutFor(i)` → the readout string.
- **Sample readout (A7):** `A7 · Portal exemplar — /portal. Delivers: the whole loop run end to end on the Portal,
  zero to production. Status: you are here. · 7 of 8 parts built before this one; A7 composes every prior Part into
  one uninterrupted run.`
- **Take:** A0–A6 each taught one move; A7 runs them all as one loop on the Portal — zero to production.

## Interactive 2 (main content) — the-whole-loop walk over the seven steps

- **Element ids:** `loopSel` (the `.solid-select`, gold), `loopOut` (`.geo-readout`), SVG step nodes
  `lw-0`…`lw-6` plus a phase label `lw-phase`, technique label `lw-tech`.
- **Fixed dataset:** the seven steps A7.01–A7.07, each `{id, phase, runs}` where `phase` is the zero-to-production
  phase name (at roadmap altitude) and `runs` names which prior chapter's technique the step runs:
  - A7.01 — Decompose the vision → runs A2 (decomposition: vision → a value ladder of stories)
  - A7.02 — Plan the delivery → runs A3 (the roadmap.md: thin-but-robust increments grouped into milestones)
  - A7.03 — Specify the rung → runs A4 (the spec: correct by definition)
  - A7.04 — Brief the Author → runs A5 (the .llms.md the agent builds from)
  - A7.05 — Build the increment → runs A5 (the Author turns the spec into running code)
  - A7.06 — Harden to production → runs A6 (supervision, boundaries, property tests)
  - A7.07 — Accept and ship → closes the loop (accepted at STATUS: PASS; shipped to production)
- **Pure fns:** `stepAt(i)` → the step record; `priorBuilt(i)` → count of A7.01..A7.0i steps whose technique was
  taught in a built prior chapter; `readoutFor(i)` → readout string.
- **Sample readout (A7.03):** `A7.03 · Specify the rung — runs A4 (the spec: correct by definition). Step 3 of 7
  of the zero-to-production run. · the step's internals are detailed once the a7.* triad is seeded.`
- **Take:** the run is the prior Parts composed — each step runs a technique an earlier chapter taught.
- **`.note` after the walk:** A7's steps will be detailed when its triad (`a7.{md,stories.md,llms.md}`) is seeded;
  the chapter, per the course roadmap, runs the whole Author/Operator loop end to end on the Portal — zero to
  production — across the seven steps A7.01–A7.07.

## Bridge (principle → Portal practice)

- **Principle:** a method is proven not by seven separate lessons but by one whole run that ships a real system.
- **Portal practice:** A7 runs the loop once on the Portal — the branded store, the event-sourced engine behind one
  facade, the Phoenix web app, the Telegram bot, the student dashboard come up in dependency order, each rung shipped
  to production quality before the next.
- **Take:** the exemplar is the course's method demonstrated in full, from an empty repository to a deployed Portal.

## Orientation dives (`.mods`, repeat(3,1fr), all `built`)

- `why` — why an end-to-end exemplar.
- `what` — the seven steps as the zero-to-production arc.
- `how` — how the loop runs once on the Portal.

## References

**Sources (real, vetted):**
- The Pragmatic Programmer — `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
  — tracer bullets and the walking skeleton: the whole system running end to end.
- Continuous Delivery — `https://continuousdelivery.com/` — releasable at every increment; production as the bar A7
  runs to.
- Extreme Programming Explained — `https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/`
  — the inspect-and-adapt loop run whole.

**Related in this course (internal, must resolve):** `/roadmap`, `/decomposition`, `/spec`, `/portal/why`,
`/portal/what`, `/portal/how`, `/elixir/phoenix`, `/elixir/course`. (`/reliability` and `/brief` are unbuilt this
batch — kept out of the resolving link set; named in prose only.)
