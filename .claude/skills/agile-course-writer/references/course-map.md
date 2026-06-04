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

A0 is the historical exception: its landing was consolidated from the retired `/intro` into `/what`, which doubles
as the A0 chapter landing AND the A0.2 module hub. Every chapter from A1 on **nests** its modules
(`/<chapter>/<module>/<subpage>`).

## The chapters

| Chapter | Title | Landing route | Dir | Status |
|---|---|---|---|---|
| A0 | Foundations — why, what, who | `/course/agile-agent-workflow/what` | `what/` | **A0.2 built; A0.1, A0.3 planned** |
| A1 | Why an Agile Agent Workflow | `/course/agile-agent-workflow/why` | `why/` | **landing + A1.01–A1.04, A1.06 built; A1.05 planned** |
| A2 | Decomposition: from vision to user stories | `/course/agile-agent-workflow/decomposition` | `decomposition/` | **complete — landing + A2.01–A2.07 built** |
| A3 | The roadmap layer: Agile delivery & iteration | `…/roadmap` | — | planned |
| A4 | The spec layer: specifications & acceptance | `…/spec` | — | planned |
| A5 | The agent brief (.llms.md) & implementation | `…/brief` | — | planned |
| A6 | Reliability and correctness | `…/reliability` | — | planned |
| A7 | Portal exemplar (zero to production) | `…/portal` | — | planned (steps A7.01–A7.07) |

## A0 — built modules and subpages

- **A0 landing** `/what` (`what/index.html`) — the A0 chapter overview (consolidated from the retired `/intro`); it
  frames three modules — A0.1 Why it works (planned), **A0.2 What we are building (built)**, A0.3 Who does the work
  (planned) — and doubles as the A0.2 module hub.
- **A0.2 · What we are building** — hub `/what`. Subpages (md sources of record under
  `docs/agile-agent-workflow/content/what/`):
  - A0.2.1 The two-layer model → `/what/two-layer-model` (+ deep-dive `/what/two-layer-model-roadmap-anatomy`).
  - A0.2.2 The four artifacts → `/what/four-artifacts`.
  - A0.2.3 The Author/Operator loop → `/what/author-operator-loop`.

## A1 — modules (six; on the `/why` landing's `#lessons` grid)

| Module | Title | One-line | Hub route (nested) | Status |
|---|---|---|---|---|
| A1.01 | The two failure modes | Why vibe coding and big-bang specs both fail; the case for thin, provable slices. | `/why/failure-modes` | **built** |
| A1.02 | Pragmatic Programming, revisited for agents | The pragmatic canon re-read for a world where an agent writes the code. | `/why/pragmatic` | **built** |
| A1.03 | The Author/Operator loop | The two roles and the cycle that runs every rung end to end. | `/why/loop` | **built** |
| A1.04 | Two layers: roadmap and specs | Separating how we deliver from what we build and prove. | `/why/two-layers` | **built** |
| A1.05 | Correct by definition | What "done" means: a closure over traced, executed checks. | `/why/correct` | planned (next) |
| A1.06 | Meet the project: Portal | The running project, zero to a deployed, multi-surface platform. | `/why/portal` | **built** |

(A1.02–A1.04 and A1.06 are built; their subpage slugs are locked — see below. A1.06's dives: `domain`, `zero-to-production`, `one-rung`. The A1.05 slug remains suggested until that module is authored.)

## A1.02 — built (the second module), slugs locked

**A1.02 · Pragmatic Programming, revisited for agents** (`why/pragmatic/`) — module hub plus three deep-dive
subpages, the arc *knowledge → specification → structure*. The running argument: when generation is cheap, three
pragmatic principles re-weight upward. Each subpage carries two interactives (hero-split + main) and passes all
ten gates with `--require-refs`. md sources of record under `docs/agile-agent-workflow/content/why/pragmatic/`.
1. **A1.02.1 · `dry`** — DRY → the single source of truth: duplication is a drift surface the agent creates for
   free and the human reconciles. Interactives: change-the-fact drift; the reconciliation-cost meter.
2. **A1.02.2 · `contracts`** — Design by Contract → the contract is the spec: pre/post/invariant as the unit an
   agent implements against and you accept against. Interactives: live contract eval; the acceptance gate.
3. **A1.02.3 · `orthogonality`** — Orthogonality → decoupling for review: a bounded blast radius is a reviewable
   diff. Interactives: orthogonal-vs-coupled graph; the 1+c blast-radius slider.
Portal grounding: one id authority (`Portal.ID`), one id contract (the A1.01.3 slice's acceptance), surfaces
behind facades.

## A1.03 — built (the third module), slugs locked

**A1.03 · The Author/Operator loop** (`why/loop/`) — module hub plus three deep-dive subpages, the arc *who →
how it turns → how it adapts*. Grounded in A0.2.3's canonical roles (Operator = human: intent, judgement,
acceptance, never writes the code; Author = Claude agent: production, never decides the goal; they meet on the
spec). Each subpage carries two interactives (hero-split + main) and passes all ten gates with `--require-refs`.
1. **A1.03.1 · `roles`** — the two roles and the hard line between them. Interactives: the who-owns-what board;
   the acceptance multiplier (⌊10/c⌋ accepted per cycle — cheap acceptance is the lever, ties A1.02.2).
2. **A1.03.2 · `turn`** — one rung through the six owned stages (sharpen/demo/review/feedback = Operator;
   build/ship = Author). Interactives: step through the turn; skip-a-stage → which A1.01 failure returns.
3. **A1.03.3 · `adapt`** — feedback edits the spec, not the code. Interactives: edit-spec-vs-patch-code (drift
   0 vs 3, ties A1.02.1 DRY); the loop ledger (rungs + spec edits locked, drift pinned 0).

## A1.04 — built (the fourth module), slugs locked

**A1.04 · Two layers: roadmap and specs** (`why/two-layers/`) — module hub plus three deep-dive subpages, the arc
*deliver → define → keep apart*. Grounded in A0.2.1 (roadmap layer = how we deliver, points at the spec, never
defines behaviour; spec layer = what we build + prove, the single source of truth, edited only by feedback; the
user stories + agent brief derive from the spec). Authored by fanning out one agile-course-writer-skilled agent
per dive, in parallel (user-confirmed process). Each subpage carries two interactives and passes all ten gates
with `--require-refs`.
1. **A1.04.1 · `roadmap`** — the coarse, re-orderable delivery plan. Interactives: re-order by value/risk/dep
   (specs untouched); coarse-vs-full-spec granularity (fine = big-bang, A1.01.2).
2. **A1.04.2 · `spec`** — the single source of truth; the hub the stories/brief/code/tests derive from.
   Interactives: the spec-as-hub; zoom (one rung, two granularities).
3. **A1.04.3 · `source`** — only feedback edits the spec; the two cadences; conflation costs. Interactives: the
   two-cadence timeline; the conflation stack (bigbang = A1.01.2, coupled = A1.02.3).

## A2 — built modules (all seven; on the `/decomposition` landing's `#modules` grid), slugs locked

The chapter's seven modules carry decomposition end to end: *value → form → quality → acceptance → splitting → ordering → workshop*.
Authored by fanning out one `agile-expert`/`agile-course-writer`-skilled agent per module, in parallel (one hub +
three dives each). md sources of record under `docs/agile-agent-workflow/content/decomposition/<module>/`. Each
subpage carries two interactives and passes all ten gates with `--require-refs`.

| Module | Title | Hub route | Dives | Status |
|---|---|---|---|---|
| A2.01 | Value, not tasks | `/decomposition/value` | `outcome-not-chore`, `who-benefits`, `vertical-slice` | **built** |
| A2.02 | The Connextra form and the three Cs | `/decomposition/connextra` | `role-want-reason`, `three-cs`, `portal-cards` | **built** |
| A2.03 | INVEST: what a good story looks like | `/decomposition/invest` | `six-tests`, `story-smells`, `small-and-independent` | **built** |
| A2.04 | Acceptance criteria with Given/When/Then | `/decomposition/acceptance` | `given-when-then`, `examples-as-spec`, `scenarios-to-tests` | **built** |
| A2.05 | Splitting stories that are too big | `/decomposition/splitting` | `when-to-split`, `split-patterns`, `vertical-not-horizontal` | **built** |
| A2.06 | The value ladder | `/decomposition/value-ladder` | `compose-the-ladder`, `dependency-order`, `always-runnable` | **built** |
| A2.07 | Workshop — decomposing Portal | `/decomposition/workshop` | `vision-to-stories`, `split-and-test`, `order-the-backlog` | **built** |

Portal grounding (locked, no-invent): the canonical value ladder — browse the catalogue → enrol → open a lesson →
track progress — plus the two non-stories ("manage the whole catalogue" fails Small/Estimable; "add the courses DB
table" fails Valuable/Testable). A2.02.3 `portal-cards` foreshadows Given/When/Then (A2.04); A2.03.3
`small-and-independent` forward-refs splitting (A2.05); A2.04 `acceptance` proves the story with Given/When/Then; A2.05
`splitting` thins the outsize ones; A2.06 `value-ladder` orders them by dependency; A2.07 `workshop` runs the whole
sequence on Portal's five surfaces (store, engine, web, bot, dashboard) to produce the backlog Part III delivers.

## Resume point

Built since last resume: **A2.04–A2.07** (`/decomposition/{acceptance,splitting,value-ladder,workshop}`, hub + three
dives each, all A+) — which **completes chapter A2** (landing + all seven modules A2.01–A2.07). The remaining gaps are
now **A1.05** ("Correct by definition", `/why/correct` — the lone gap inside the otherwise-complete chapter A1) and the
**start of Part III / chapter A3** ("The roadmap layer", `/roadmap` — landing not yet built).

**A1.05 — "Correct by definition"** (`/why/correct`, slug suggested): what "done" means — a closure over traced,
executed checks, and the quality gates that hold it. Author the module hub `why/correct/index.html` plus ≥3
deep-dive subpages (md-first under `docs/agile-agent-workflow/content/why/correct/`), each with a hero-split
interactive, a main interactive, and a References section whose `Sources` are real, vetted external links (reuse the
course-home registry — Pragmatic Programmer/XP/Spec-by-Example/Continuous-Delivery/llms.txt/Anthropic; never
fabricate a URL), then relink the A1.05 card on `/why` (div → a, soon → live). **Process
(user-confirmed):** fan out one agile-course-writer-skilled agent per dive, in parallel; ground the definition of
"done" and the gates in the established course material before authoring. The course thesis, restated each module:
neither no-plan nor all-plan ships reliable software; the unit that does is a thin slice of value, specified only
enough, proven before the next begins.
