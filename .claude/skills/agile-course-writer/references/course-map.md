# Agile Agent Workflow — course map

The course "Agile Agent Workflow in Elixir — Pragmatic Programming with Claude Agents" is served at
**`/course/agile-agent-workflow`** (re-mounted in `main.go`; the bare `/agile-agent-workflow` 404s). The home
page (`html/agile-agent-workflow/index.html`) is the **route manifest** — its chapter tiles define every chapter
route, including deliberate forward-links to chapters not yet built. Those forward-links FAIL the `links` gate **by
design on the home page only**; every lesson/hub page must keep all internal links resolving.

## Numbering — three levels, `A<chapter>.<module>.<subpage>`

- **Chapter** `A[N]` → a landing page. Routes are semantic dir names, not positional (`/why`, not `/a1`).
- **Module** `A[N].[M]` (two-digit M) → a hub, nested under the chapter dir (`/why/<module-slug>`).
- **Subpage** `A[N].[M].[S]` (single-digit S) → a deep-dive lesson inside the module (`/why/<module-slug>/<slug>`).

A0 is the historical exception: its landing is `/intro` and its one built module (A0.2) is the flat sibling
`/what`. Every chapter from A1 on **nests** its modules (`/<chapter>/<module>/<subpage>`).

## The chapters

| Chapter | Title | Landing route | Dir | Status |
|---|---|---|---|---|
| A0 | Foundations — why, what, who | `/course/agile-agent-workflow/intro` | `intro/` | **built** |
| A1 | Why an Agile Agent Workflow | `/course/agile-agent-workflow/why` | `why/` | **landing built; modules building** |
| A2 | Decomposition: from vision to user stories | `…/decomposition` | — | planned (manifest forward-link) |
| A3 | The roadmap layer: Agile delivery & iteration | `…/roadmap` | — | planned |
| A4 | The spec layer: specifications & acceptance | `…/spec` | — | planned |
| A5 | The agent brief (.llms.md) & implementation | `…/brief` | — | planned |
| A6 | Reliability and correctness | `…/reliability` | — | planned |
| A7 | Portal exemplar (zero to production) | `…/portal` | — | planned (steps A7.01–A7.07) |

## A0 — built modules and subpages

- **A0 landing** `/intro` (`intro/index.html`).
- **A0.2 · What we are building** — module hub `/what` (`what/index.html`). Subpages:
  - A0.2.1 The two-layer model → `/what/two-layer-model` (+ deep-dive `/what/two-layer-model-roadmap-anatomy`).
  - A0.2.2 The four artifacts → `/what/four-artifacts`.
  - A0.2.3 The Author/Operator loop → `/what/author-operator-loop`.

## A1 — modules (six; on the `/why` landing's `#lessons` grid)

| Module | Title | One-line | Hub route (nested) | Status |
|---|---|---|---|---|
| A1.01 | The two failure modes | Why vibe coding and big-bang specs both fail; the case for thin, provable slices. | `/why/failure-modes` | **building** |
| A1.02 | Pragmatic Programming, revisited for agents | The pragmatic canon re-read for a world where an agent writes the code. | `/why/pragmatic` | planned |
| A1.03 | The Author/Operator loop | The two roles and the cycle that runs every rung end to end. | `/why/loop` | planned |
| A1.04 | Two layers: roadmap and specs | Separating how we deliver from what we build and prove. | `/why/two-layers` | planned |
| A1.05 | Correct by definition | What "done" means: a closure over traced, executed checks. | `/why/correct` | planned |
| A1.06 | Meet the project: Portal | The running project, zero to a deployed, multi-surface platform. | `/why/portal` | planned |

(Module slugs A1.02–A1.06 above are suggested, not yet locked; lock each when its module is authored.)

## Resume point

**A1.01 — "The two failure modes"** (`why/failure-modes/`): a module hub plus three deep-dive subpages —
1. **A1.01.1 · `vibe-coding`** — the no-plan failure: prompting without a spec or acceptance; unreviewable diffs;
   compounding entropy. Portal example: a "store" built by vibe coding drifts and cannot be accepted.
2. **A1.01.2 · `big-bang-specs`** — the over-plan failure: the waterfall spec no one finishes; drift from reality;
   cost of delay; no feedback until the end. Portal example: a 40-page Portal spec that ships nothing.
3. **A1.01.3 · `thin-slices`** — the resolution: a thin, vertical, provable slice (INVEST, tracer bullets,
   walking skeleton); correct by definition. Portal example: the first rung — one branded id, proven, shipped.

The module's argument is the course thesis in miniature: neither no-plan nor all-plan ships reliable software; the
unit that does is a thin slice of value, specified just enough, proven before the next begins.
