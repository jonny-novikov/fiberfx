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
| A1 | Why an Agile Agent Workflow | `/course/agile-agent-workflow/why` | `why/` | **complete — landing + A1.01–A1.06 built** |
| A2 | Decomposition: from vision to user stories | `/course/agile-agent-workflow/decomposition` | `decomposition/` | **complete — landing + A2.01–A2.07 built** |
| A3 | The roadmap layer: Agile delivery & iteration | `/course/agile-agent-workflow/roadmap` | `roadmap/` | **complete — landing + 3 orientation dives + A3.1–A3.9 built** |
| A4 | The spec layer: specifications & acceptance | `/course/agile-agent-workflow/spec` | `spec/` | **complete — landing + A4.1–A4.7 built** |
| A5 | The agent brief (.llms.md) & implementation | `…/brief` | `brief/` | **COMPLETE** — landing + 3 orientation dives + all 8 modules A5.1–A5.8 (hub + 3 dives each = 32 pages) built |
| A6 | Reliability and correctness | `…/reliability` | `reliability/` | **landing + 3 orientation dives built**; modules await `a6.*` triad (scope: OTP supervision, boundaries, parse-don't-validate, property tests) |
| A7 | Portal exemplar (zero to production) | `…/portal` | `portal/` | **landing + 3 orientation dives built**; steps A7.01–A7.07 await `a7.*` triad |

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
| A1.05 | Correct by definition | What "done" means: a closure over traced, executed checks. | `/why/correct` | **built** |
| A1.06 | Meet the project: Portal | The running project, zero to a deployed, multi-surface platform. | `/why/portal` | **built** |

(All six A1 modules are built; subpage slugs are locked. A1.05's dives: `the-closure`, `proven-not-asserted`, `gates`. A1.06's dives: `domain`, `zero-to-production`, `one-rung`.)

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

**Parts I, II, III, IV, and V are complete (A0–A5).** The course's own **spec system** lives under
`docs/agile-agent-workflow/specs/` — the single `aaw.roadmap.md`, the `aaw.operator.md` build runbook, the live
**`aaw.progress.md`** completion dashboard (per-rung status bar + %, recounted at each rung-close), and a **chapter
triad** (`a<N>.md` chapter spec + `a<N>.llms.md` brief + `a<N>.stories.md` stories) for **A3, A4, and A5** (A5 is
seeded ahead of its build — the "specced ahead" pattern).

**A4 — "The spec layer"** (`/spec`, Part IV) is COMPLETE — the course's second **spec-first** chapter, built from
its specs (`a4.{md,stories.md,llms.md}`) plus an `a4.progress.md` build narrative authored by a supervised Senior
Writer and embedded into each module Author's prompt so all seven modules stay consistent with the landing and with
A1–A3. Built: the landing `/spec` (the keystone, no orientation dives) + **all seven modules A4.1–A4.7**, each a hub
+ three dives, grounded verbatim on the real F6.1 (and F5.1, for the workshop) rung triads: **A4.1 `by-example`**,
**A4.2 `the-triad`**, **A4.3 `spec-anatomy`**, **A4.4 `to-stories`**, **A4.5 `invariants`**, **A4.6 `traceability`**,
**A4.7 `workshop`**. The no-code mandate held: every `pre.code` carries spec/stories markdown, never Elixir.

A later **refinement pass** (supervised Senior Writer → per-page fan-out, embedded brief in `a4.progress.md`)
re-grounded every retired-route citation onto the as-built surfaces — the public catalog `/courses`, a learner's own
`/my/courses`; the function `Portal.courses_of/1` **stayed** (only the `/courses/:user_id` *route* retired) — and
replaced bare-filename spec citations with an inline **`.specref` citation chip** (the build-stamp affordance applied
to a citation: a click-to-expand tooltip → the new **spec-ladder viewer** `/spec/specimens`, a git-iteration slider
over the shipped F6.1→F6.6 ladder). `workshop` cites F5.1 (below that ladder) as a named reference, no chip. The
critical chip mechanic: the `links` gate does not strip a `#fragment`, so each chip uses a **bare-route href +
`data-sr-hash`** and the JS appends the hash on click (degrades, and the gate stays green).

**A3 — "The roadmap layer"** (`/roadmap`, Part III) is COMPLETE: the landing + 3 orientation dives + **all nine
modules A3.1–A3.9** (`agile-distilled`, `xp-small-batches`, `roadmap-anatomy`, `thin-but-robust`, `milestones`,
`program-roadmap`, `tracer-bullets`, `workshop`, `glossary`), grounded on the real `phoenix.roadmap.md`.

**The chapter SKELETON is complete A0→A7.** A cross-chapter landings batch (supervised Senior Writer → embedded brief
`landings.progress.md` → 3 parallel chapter-writers) built the **three remaining chapter landings + a why/what/how
orientation triptych each** — A5 `/brief`, A6 `/reliability`, A7 `/portal` (12 pages, all gating A+). A5 was grounded
on its seeded triad; **A6 and A7 have NO triad** and were grounded only on `aaw.roadmap.md` at the chapter altitude,
with their module/step sets honestly **deferred** (a `.note`, not invented cards). The Senior Writer also ran a
reverse verification (A7→A6→A5→A4) so each chapter's `why` echoes what its predecessor leaves unfinished.

**A5 — "The agent brief"** (`/brief`, Part V) is COMPLETE: the landing + 3 orientation dives + **all eight modules
A5.1–A5.8** (each a hub + 3 dives = **32 pages**, all gating A+), built by the supervised-Senior-Writer-then-per-page
fan-out loop — a single `a5.progress.md` embedded brief (whole-chapter narrative, reverse-verified A5.8→A5.1, 32
per-page specs, shared directives) authored first, then **one agent per page**. Modules: **A5.1 `llms-txt`**, **A5.2
`references-requirements`**, **A5.3 `execution-topology`**, **A5.4 `agent-stories`**, **A5.5 `implementation-prompt`**,
**A5.6 `running-agents`**, **A5.7 `the-thesis`**, **A5.8 `workshop`**. Grounded verbatim on the real `f6.1.llms.md`
(References/`R1…R8`, topology/`T1→T7`, `AS1…AS4`, the prompt), the `f6.6`/`f6.7` ship prompts, and `f5.2.llms.md` (the
workshop's engine rung) — **every page cross-links the matching `/elixir/phoenix/*` rung** (the user's standing ask).
The no-code mandate held (every `pre.code` is spec/stories markdown, never Elixir). Two waves hit transient API
socket drops at the report boundary; the **md-first** checkpoint preserved each page's design, so recovery rebuilt
only the HTML from the surviving md — no content lost.

**Next: A6 "Reliability and correctness"** (`/reliability`, Part VI) — the new FRONTIER. The landing + orientation
are built but **A6 has NO triad**; seed `a6.{md,stories.md,llms.md}` first (the landing already names the scope —
supervision, boundaries, property tests), then run the same supervised-Senior-Writer-then-fan-out loop. **A7
"Portal exemplar"** (`/portal`, Part VII) follows: seed `a7.*`, then build its seven exemplar steps A7.01–A7.07.
The course thesis, restated each module: neither no-plan nor all-plan ships reliable software; the unit that does is
a thin slice of value, specified only enough, proven before the next begins.
