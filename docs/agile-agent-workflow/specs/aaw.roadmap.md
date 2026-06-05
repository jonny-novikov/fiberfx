# Agile Agent Workflow · course roadmap

> The single delivery plan for the **Agile Agent Workflow** course — the one roadmap above every chapter. The course
> is built the way it teaches: each chapter is a value ladder of thin, provable increments (a chapter landing, its
> module hubs, their deep-dive subpages), specified before it is built, told as user stories, authored by a Claude
> agent, and accepted only when its ten quality gates pass. This file sequences the chapters into the course's
> milestones, shows how they stack on one design system and one teaching invariant, and hands rung-level detail to each
> chapter's agent brief (`a<N>.llms.md`) and user stories (`a<N>.stories.md`). It is *what ships, in what order, and
> why* — not how a page is authored (that is the `agile-course-writer` skill).

This is the program view. The build process it runs is in [`aaw.operator.md`](aaw.operator.md); the craft of a single
page is the `agile-course-writer` skill and `docs/agile-agent-workflow/CLAUDE.md`. The course is the worked exemplar of
its own method — the Portal spec system under `docs/elixir/specs/` is its model, one altitude up.

## What the course is

A course on **Pragmatic Programming with Claude Agents**: building reliable software as a human **Operator** (judgement,
decomposition, acceptance) paired with a Claude **Author** (fast, well-specified implementation), over thin, provable
increments. Every idea lands twice — the **principle** (Agile, XP, Pragmatic Programming, the Author/Operator thesis)
and its **practice on the Portal**, the one running project carried from an empty repository to a deployed, multi-surface
platform (the companion `/elixir` course's real build, cited never re-taught). It is dependency-light static HTML pages
on the jonnify dark-editorial design system, served at `/course/agile-agent-workflow`, each page graded **A+** across
the ten `jonnify-cms` gates.

## The course at a glance

Eight chapters. **A0** is the on-ramp; **A1–A7** are the seven teaching Parts. Each chapter is a landing + modules
`A<N>.<MM>`, each module a hub + ≥3 deep-dive subpages `A<N>.<MM>.<S>` (the three levels).

| Chapter | Title | Route | Delivers | Status |
| --- | --- | --- | --- | --- |
| A0 | Foundations — why, what, who | `/what` | the method in three questions; the framework in one read | **built** (A0.2) |
| A1 | Why an Agile Agent Workflow | `/why` | the thesis: thin, provable slices beat vibe-coding and big-bang specs | **complete** (A1.01–A1.06) |
| A2 | Decomposition: vision → user stories | `/decomposition` | a vision turned into a dependency-ordered value ladder of stories | **complete** (A2.01–A2.07) |
| A3 | The roadmap layer: Agile delivery & iteration | `/roadmap` | planning delivery as thin, robust increments in a `roadmap.md` | **complete** (A3.1–A3.9) |
| A4 | The spec layer: specifications & acceptance | `/spec` | defining and proving each rung — correct by definition | planned |
| A5 | The agent brief (`.llms.md`) & implementation | `/brief` | briefing a Claude agent and reviewing its work | planned |
| A6 | Reliability and correctness | `/reliability` | OTP supervision, boundaries, parse-don't-validate, property tests | planned |
| A7 | Portal exemplar (zero to production) | `/portal` | the whole loop run end to end on the Portal | planned |

## How the chapters compose

The chapters depend only downward — each stands on the ones below — and they mirror the workflow itself:

```text
A0  Foundations (the framework in one read)
     ▼
A1  Why ──────────────▶ the thesis + the Author/Operator loop + "correct by definition"
     ▼
A2  Decomposition ────▶ a value ladder of INVEST stories with Given/When/Then        ← the input A3 sequences
     ▼
A3  The roadmap layer ▶ a roadmap.md: how we deliver the backlog, thin but robust
     ▼
A4  The spec layer ───▶ what we build and prove, the single source of truth
     ▼
A5  The agent brief ──▶ the .llms.md handed to the Author; the build
     ▼
A6  Reliability ──────▶ the increment built to production quality
     ▼
A7  Portal exemplar ──▶ the loop run end to end, zero to production
```

The **teaching invariant** threads through every chapter, the way the master invariant threads the Portal: every page
lands a principle on the Portal as a concrete practice (the `.bridge`), reuses the design system rather than rebuilding
it, and is accepted only at `STATUS: PASS`. Adding a chapter adds teaching surface and never rebuilds the system.

## Course milestones

| Milestone | Chapters | What the reader can do at the end | Status |
| --- | --- | --- | --- |
| M1 · The method, framed | A0–A1 | name why thin, provable slices win, and the two roles that run the loop | **complete** |
| M2 · From vision to backlog | A2 | decompose a product vision into a dependency-ordered ladder of testable stories | **complete** |
| M3 · Planning delivery | A3 | plan a backlog's delivery as a `roadmap.md` of thin, robust increments | **complete** |
| M4 · Defining & proving | A4–A6 | write a spec, brief an agent, and build the increment correct by definition | planned |
| M5 · The exemplar | A7 | run the whole loop on the Portal, zero to production | planned |

## How the course is built

The course runs the same **Author/Operator loop** it teaches, on itself:

- **Operator (the human)** chooses the next chapter/module to sharpen — by dependency (only downward) and by teaching
  priority — writes or refines this roadmap, the chapter's user stories, and its agent brief, and accepts each shipped
  page only at `STATUS: PASS`.
- **Author (the `agile-expert` Claude agent)** turns a module's spec + stories into the built pages (a hub + its dives),
  copying the design system, grounding every example on the real Portal, and self-checking against the gates.

The loop is **sharpen → build → ship → demo → review → feedback → adapt**; feedback edits the specs (the single source
of truth), never the built page directly. The planning unit at course scale is the chapter and its milestones; within a
chapter it is the module, governed by this roadmap and the chapter's stories. The fan-out — one `agile-expert` per
module via the `/agile-write` command — is how a chapter's modules ship in parallel; the orchestrator (the Operator's
session) relinks the landing, syncs the four living views, and runs the final gate.

## Definition of done (correct by definition)

A page is done only when **all ten gates pass**: `containers · svg · no-future · voice · storage · motion · degrade ·
links · pager · refs`. Beyond the gates, the Operator reads the gate-invisible bits — clamp spacing, the segmented
route-tag, real Sources links, the intended (not merely resolving) crumbs/pager, no invented Portal API, no duplicate
ids, parseable inline scripts. The four living views (the served pages, `agile-agent-workflow.toc.md`,
`course-map.md`, `llms.md`) must agree; a change to one is a change to all.

## The near-term path

Given the state above — A0–A3 complete (A3.1–A3.9 all built, grounded on the real `phoenix.roadmap.md`, with an
`a3.progress.md` build narrative) — the recommended sequence is:

1. **Open A4 (the spec layer).** Its triad is already seeded (`a4.{md,stories.md,llms.md}`). Author the chapter
   **landing `/spec` first** (the keystone, modelled on the A3 landing), then fan out its modules — A4 is the natural
   next chapter, where this roadmap's reader becomes the spec writer.
2. **Build A4's modules** with the supervised-lead-then-fan-out loop A3 used: a Senior Writer pass that authors an
   `a4.progress.md` and reviews the keystone, then one `agile-expert` per module against the seeded stories + brief.
3. **Then A5 (the agent brief)** — its triad is also seeded; the same loop applies.
4. **A6–A7** — reliability, then the zero-to-production Portal exemplar that runs the whole loop end to end.

## Conventions (the course's invariants)

- **The design system is reused, never rebuilt** — the dark-editorial tokens, the segmented clickable route-tag, the
  canonical 3-column `.foot-cols` footer, the branded `TSK…` Snowflake stamp. No libraries; vanilla JS only.
- **Every concept lands twice** — principle → Portal practice (the `.bridge`), closed by a `.take`.
- **Two interactives per lesson** (one in the hero, one in main), each a real computation over a fixed dataset with a
  live `.geo-readout`, degrading without JS, honouring `prefers-reduced-motion`, using no browser storage.
- **References → Sources are real, vetted external links**; the Portal API is cited, never invented (only
  `Portal.ID.generate/1`,`Portal.ID.decode/1`, plus the real F6 surfaces as they appear in `docs/elixir/specs/`).
- **Voice** — no first person, no exclamation/emoji, no hype; a tool or an agent is never anthropomorphised.

## Map

- The build process: [`aaw.operator.md`](aaw.operator.md).
- Chapter A3 agent brief: [`a3.llms.md`](a3.llms.md) · its user stories: [`a3.stories.md`](a3.stories.md).
- The living views: `docs/agile-agent-workflow/agile-agent-workflow.toc.md` (the TOC),
  `.claude/skills/agile-course-writer/references/course-map.md` (the route/status map),
  `docs/agile-agent-workflow/llms.md` (the agent site-map).
- The model spec system (one altitude up, the Portal's real build): `docs/elixir/specs/` —
  [`portal.roadmap.md`](../../elixir/specs/portal.roadmap.md), [`specs.approach.md`](../../elixir/specs/specs.approach.md),
  [`phoenix/phoenix.roadmap.md`](../../elixir/specs/phoenix/phoenix.roadmap.md).

---

> Part of the jonnify toolkit. One course, one running project, one design system, one roadmap. The roadmap plans; the
> stories tell; the agent builds; the gates accept. The course is the exemplar of the method it teaches.
