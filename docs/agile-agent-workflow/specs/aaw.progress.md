# Agile Agent Workflow · build progress (live dashboard)

> The course's **completion dashboard** — one glanceable view of how much of every chapter, module, and rung is
> built, updated as each rung lands. This is *how much is done*; the per-chapter `a<N>.progress.md` files are *how it
> was built* (the build narratives), and [`aaw.roadmap.md`](aaw.roadmap.md) is *what ships, in what order, and why*.
> It is maintained by hand by the Operator at each rung-close, alongside the four living views. The denominator is
> **pages** (a module = 1 hub + 3 dives = 4 pages; a chapter also has 1 landing); a percentage is built ÷ planned.

## Legend

```
✓ done (100%)      ◐ in progress (1–99%)      ○ planned (0%)      ▣ landing built

bar = 24 cells, █ built · ░ remaining        a rung = a module A<N>.<M> (hub + ≥3 dives)
```

## Course rollup

```
A0  Foundations          ◐  █████████░░░░░░░░░░░░░░░  ~38%   (landing ▣ · 1/3 modules)
A1  Why                  ✓  ████████████████████████  100%   (landing ▣ · 6/6 modules)
A2  Decomposition        ✓  ████████████████████████  100%   (landing ▣ · 7/7 modules)
A3  The roadmap layer    ✓  ████████████████████████  100%   (landing ▣ · 3 dives · 9/9 modules)
A4  The spec layer       ✓  ████████████████████████  100%   (landing ▣ · 7/7 modules)
A5  The agent brief      ○  ░░░░░░░░░░░░░░░░░░░░░░░░    0%   (triad seeded · 0/8 modules)   ← FRONTIER
A6  Reliability          ○  ░░░░░░░░░░░░░░░░░░░░░░░░    0%   (scope not yet enumerated)
A7  Portal exemplar      ○  ░░░░░░░░░░░░░░░░░░░░░░░░    0%   (planned · 0/7 steps)
────────────────────────────────────────────────────────────────────────────────────
COURSE (A0–A5, A7)       ◐  ███████████████░░░░░░░░░   64%   (30 / 47 modules built)
```

*A6 is excluded from the denominator until its triad is seeded and its modules are enumerated. The course total
counts modules across the seven chapters with a known module set (A0 3 · A1 6 · A2 7 · A3 9 · A4 7 · A5 8 · A7 7 =
47).*

## A0 · Foundations — `/what`  ◐ ~38%

```
▣ landing /what (doubles as the A0.2 hub)
○ A0.1  Why it works                       ░░░░░░░░░░░░░░░░░░░░░░░░    0%   (0/4)  planned
✓ A0.2  What we are building               ████████████████████████  100%   (4/4)  hub + 3 subpages
○ A0.3  Who does the work                  ░░░░░░░░░░░░░░░░░░░░░░░░    0%   (0/4)  planned
```

## A1 · Why an Agile Agent Workflow — `/why`  ✓ 100%

```
✓ A1.01  The two failure modes             ████████████████████████  100%   (4/4)
✓ A1.02  Pragmatic Programming, revisited  ████████████████████████  100%   (4/4)
✓ A1.03  The Author/Operator loop          ████████████████████████  100%   (4/4)
✓ A1.04  Two layers: roadmap and specs     ████████████████████████  100%   (4/4)
✓ A1.05  Correct by definition             ████████████████████████  100%   (4/4)
✓ A1.06  Meet the project: Portal          ████████████████████████  100%   (4/4)
```

## A2 · Decomposition — `/decomposition`  ✓ 100%

```
✓ A2.01  Value, not tasks                  ████████████████████████  100%   (4/4)
✓ A2.02  The Connextra form & the three Cs ████████████████████████  100%   (4/4)
✓ A2.03  INVEST                            ████████████████████████  100%   (4/4)
✓ A2.04  Acceptance with Given/When/Then   ████████████████████████  100%   (4/4)
✓ A2.05  Splitting stories too big         ████████████████████████  100%   (4/4)
✓ A2.06  The value ladder                  ████████████████████████  100%   (4/4)
✓ A2.07  Workshop — decomposing Portal     ████████████████████████  100%   (4/4)
```

## A3 · The roadmap layer — `/roadmap`  ✓ 100%

```
▣ landing /roadmap  +  3 orientation dives (where-we-are · the-roadmap-layer · the-road-ahead)
✓ A3.1  Agile, distilled                   ████████████████████████  100%   (4/4)
✓ A3.2  Extreme Programming, small batches ████████████████████████  100%   (4/4)
✓ A3.3  Anatomy of a roadmap.md            ████████████████████████  100%   (4/4)
✓ A3.4  Thin but robust                    ████████████████████████  100%   (4/4)
✓ A3.5  Milestones and iterations          ████████████████████████  100%   (4/4)
✓ A3.6  The program roadmap                ████████████████████████  100%   (4/4)
✓ A3.7  Tracer bullets & walking skeletons ████████████████████████  100%   (4/4)
✓ A3.8  Workshop — roadmapping Portal       ███████████████████████  100%   (4/4)
✓ A3.9  Glossary, references & crosswalk    ███████████████████████  100%   (4/4)
```

## A4 · The spec layer — `/spec`  ✓ 100%  (landing + A4.1–A4.7 built)

```
▣ landing /spec                            ████████████████████████  100%   keystone (10/10 gates)
✓ A4.1  Specification by Example           ████████████████████████  100%   (4/4)   /spec/by-example
✓ A4.2  The triad: spec, stories, brief    ████████████████████████  100%   (4/4)   /spec/the-triad
✓ A4.3  Anatomy of a spec                  ████████████████████████  100%   (4/4)   /spec/spec-anatomy
✓ A4.4  From stories to a .stories.md      ████████████████████████  100%   (4/4)   /spec/to-stories
✓ A4.5  Invariants                         ████████████████████████  100%   (4/4)   /spec/invariants
✓ A4.6  Traceability — correct by def.     ████████████████████████  100%   (4/4)   /spec/traceability
✓ A4.7  Workshop — specifying the engine   ████████████████████████  100%   (4/4)   /spec/workshop
```

## A5 · The agent brief — `/brief`  ○ 0%  (triad seeded)

```
○ A5.1–A5.8 (8 modules)                    ░░░░░░░░░░░░░░░░░░░░░░░░    0%   triad a5.{md,stories,llms} seeded ahead
```

## A6 · Reliability and correctness — `/reliability`  ○ 0%  (scope pending)

```
○ modules not yet enumerated               ░░░░░░░░░░░░░░░░░░░░░░░░    0%   triad to be seeded
```

## A7 · Portal exemplar — `/portal`  ○ 0%  (planned)

```
○ A7.01–A7.07 (7 steps)                    ░░░░░░░░░░░░░░░░░░░░░░░░    0%   the whole loop run end to end
```

---

## How to maintain this file

At each rung-close, update three things together (or the views drift):

1. **The module row** — set its glyph and bar from `built_pages / 4` (a hub counts as 1, each dive as 1).
2. **The chapter rollup line** — recount built ÷ total modules; flip `○`→`◐`→`✓`; redraw the 24-cell bar.
3. **The course rollup** — recount total modules built ÷ 47; redraw.

A bar is `round(pct/100 × 24)` filled `█` cells + the rest `░` (24 total). The same rung-close edits the four living
views (served pages · `agile-agent-workflow.toc.md` · `course-map.md` · `llms.md`) and, where the rung is spec-first,
the chapter's `a<N>.progress.md` build narrative. This dashboard is the quantitative companion to those.

> Part of the jonnify toolkit. The roadmap plans; the stories tell; the agent builds; the gates accept; this file
> counts. Built ÷ planned, by the page — *correct by definition* applies to the tracker too.
