# Landings batch — the three remaining chapter landings (A5, A6, A7) — embedded brief

> **Shared context for the A5 / A6 / A7 chapter-landings batch.** This file is embedded verbatim into each
> chapter-writer's prompt. One writer takes A5 (`/brief`), one A6 (`/reliability`), one A7 (`/portal`). Each writer
> authors **four pages** — the chapter landing + its three orientation dives (`why`, `what`, `how`) — plus each
> page's md source of record. Read this end to end before authoring; it is self-contained. A chapter-writer with
> the `agile-course-writer` skill loaded and the two A3 model pages
> (`html/agile-agent-workflow/roadmap/index.html` = landing; `html/agile-agent-workflow/roadmap/the-roadmap-layer.html`
> = an orientation dive) can build its four pages from this file alone. **Build only your one chapter. Never run
> git. Edit only your chapter's files (the 4 pages + their md sources). Do NOT touch the home `index.html`, the
> other chapters, or the four living views — the Operator syncs those after the batch.**

The structural model for "landing + 3 orientation dives" is **chapter A3** — the only built chapter with exactly
this shape. Copy its landing for your landing, and copy one of its orientation dives for each of your three dives.
The design system, the segmented route-tag, and the `.foot-cols` footer come **verbatim** from those two model
pages; you change only `<title>`/`<meta name="description">`, the route-tag, the accent references, and the
`<main>` body. Reuse the build stamp `TSK0Ng9hnHJgW0` (it is in the footer you copy).

---

## (A) The whole-course-end narrative — A4 → A5 → A6 → A7

The course argues one thesis from end to end: **a Claude agent is a fast, tireless implementer of *well-specified*
thin slices; the human owns decomposition, judgement, and acceptance.** The first four Parts built the apparatus
that makes a slice *well-specified*; the last three Parts spend that apparatus to ship one increment to production
and then run the whole loop. Read the arc as one continuous story to the course's end:

- **A4 — the spec layer (`/spec`, built).** A4 defined and proved the unit: a thin slice written down as a spec —
  acceptance criteria, Given/When/Then, invariants, traceability — so that "done" is a closure over traced,
  executed checks, not an opinion. A4 produced **a spec that is correct by definition**. But a spec says *what and
  why and done*; it does not, on its own, become running code.

- **A5 — the agent brief (`/brief`, this batch's first landing).** A5 wraps that spec in a machine-readable brief
  (an `.llms.md`: references first, numbered testable requirements, the execution topology, the agent stories, the
  one comprehensive implementation prompt) and runs a Claude Author to turn the spec into code — briefing,
  supervising, and reviewing a first full pass from spec to running increment. A5 produces **a built increment**:
  code that exists and passes its own acceptance. But "it builds and the demo passes" is not yet "it survives
  production" — a happy-path increment can still crash on a malformed input, leak a crashed process, or hold an
  invariant only by luck.

- **A6 — reliability and correctness (`/reliability`, this batch).** A6 takes the built increment and makes it
  production-grade: OTP supervision (a crash is isolated and recovered, not propagated), boundaries that
  parse-don't-validate (untrusted input becomes a typed value at the edge or is rejected there), and property
  tests that prove an invariant across generated inputs rather than asserting it on a chosen few. A6 produces **an
  increment built to production quality** — correct under failure, not only on the happy path.

- **A7 — the Portal exemplar (`/portal`, this batch).** A7 runs the *whole loop* — decompose, roadmap, spec, brief,
  build, harden, accept — end to end on the Portal, zero to production. Every Part so far taught one move on a
  worked fragment; A7 is the single uninterrupted run that proves the moves compose into a shipped, multi-surface
  system. A7 produces **the worked exemplar**: the course's method demonstrated in full, from an empty repository
  to a deployed Portal.

That is the culmination: A4 *defined and proved the slice*; A5 *briefed an agent and turned the spec into running
code*; A6 *made that increment production-grade*; A7 *ran the whole loop end to end on the Portal, zero to
production*. The thesis lands because the human never wrote the implementation and never lost ownership of the
decomposition, the judgement, or the acceptance.

---

## (B) The reverse verification — "the path behind" (A7 → A6 → A5 → A4)

Walking backward, each chapter's reason-to-exist must be answered by what its predecessor produced — no gap, no
non-sequitur. For each link below, the **constraint sentence** is the one thing the successor's `why` dive must
echo so the chain reads coherently backward. These constraints are binding on the `why`/`what`/`how` content in
Section (C).

- **A7 (run the whole loop) needs A6's production-grade increment.** You cannot run a zero-to-*production* exemplar
  on an increment that only passes the happy path; the end-to-end run is only meaningful because each rung was
  hardened to production quality first. **A7's `why` must echo:** *the exemplar runs the whole loop end to end
  because every rung it ships was first made production-grade (A6) — the loop is only worth demonstrating if its
  output survives production.*

- **A6 (reliability and correctness) needs A5's built increment.** There is nothing to harden until an increment
  exists; A5 produces running code that passes its own acceptance, and A6 is precisely the work that turns "the
  demo passes" into "it survives a malformed input, a crashed process, and an unproven invariant." **A6's `why`
  must echo:** *A5 leaves a built increment that is correct on the happy path but not yet proven under failure —
  A6 names exactly what production-readiness A5 leaves unproven (supervision, boundaries, properties) and closes
  it.* (This is the load-bearing seam: A6's reason-to-exist is the gap A5 leaves.)

- **A5 (brief → code) needs A4's spec.** A brief wraps a spec; with no spec there is nothing to brief an agent
  against, and the agent would be left to decide what "done" means — which the Operator must own. A5 turns the A4
  spec into a machine-readable brief and a build. **A5's `why` must echo:** *A4 defines what and why and done, but
  a spec is not runnable by an agent on its own — A5 is the brief that fixes every remaining how-to-build decision
  and turns the spec into code.*

- **A4 (the spec) needs A3's roadmap.** A spec defines and proves one rung; the roadmap is what names which rung is
  next and in what order rungs ship. A4 stands on A3's delivery plan. **(Already built; stated here only to close
  the chain — A4's landing already carries this; no A4 change in this batch.)**

The chain reads with no gap backward: A7 ⇐ A6 ⇐ A5 ⇐ A4 ⇐ A3. Each successor's `why` dive opens by naming the
specific thing its predecessor leaves undone, then promises to close it. **Do not write a `why` that motivates the
chapter in the abstract; motivate it as the answer to the precise deficit the previous chapter leaves.**

---

## (C) Per-chapter build plan

Each writer follows exactly one of the three sections below, verbatim. Locked across all three:

- **Slugs (locked):** the three dives are `why`, `what`, `how` — served `/<chapter>/why`, `/<chapter>/what`,
  `/<chapter>/how`. The landing is `/<chapter>` (`<chapter>/index.html`).
- **Eyebrow on each dive:** `A<N> · orientation dive 1` (why), `A<N> · orientation dive 2` (what),
  `A<N> · orientation dive 3` (how). The landing eyebrow is `A<N> · chapter overview`.
- **Crumbs (locked):** landing crumbs are `Agile Agent Workflow / A<N> · <Chapter>` (the two-element form the A3
  landing uses — see model line 339). Each **dive's** crumbs are the four-element form the A3 dive uses (model
  lines 271–279): `jonnify / Agile Agent Workflow / A<N> · <Chapter> / <here>`, where the `A<N> · <Chapter>`
  segment links the chapter landing and `<here>` is `<span class="here">`.
- **Pager + crumbs point at the INTENDED parent.** The `links` gate proves a route *resolves*, not that it is the
  right one — read your crumbs and pager against the locked targets below.
- **`.mods` grid is `grid-template-columns:repeat(3,1fr)`** (the three dive cards in one row). Each dive card is a
  real `<a class="mod" href="/course/agile-agent-workflow/<chapter>/<why|what|how>">` with a `<span class="pill
  built">built</span>` once you have authored all three (they ship together, so all three are `built`).

### A5 — `/brief` — "The agent brief (`.llms.md`) & implementation"

**Accent (locked): elixir-purple** (`--elixir` / `--elixir-bright`; `<span class="ex">` is already this colour in
the shared CSS). This is the course's signature accent and A5's seeded triad names it (`a5.llms.md`).

**Model + grounding.** Copy `roadmap/index.html` for the landing and `roadmap/the-roadmap-layer.html` for each
dive. Ground **only** on the seeded A5 triad: `docs/agile-agent-workflow/specs/a5.{md,stories.md,llms.md}`, and the
real Portal briefs/prompts cited there (`docs/elixir/specs/phoenix/f6.N.llms.md` / `f6.N.prompt.md`) — quoted
verbatim, never invented. The A5 brief's own anatomy is the five parts: **references → requirements → topology →
agent stories → the implementation prompt.**

**Landing `/brief` content:**
- **Hero.** `<h1>` `The agent <span class="ex">brief</span>` (or similar; the accent word in `<span class="ex">`).
  Lede: a spec says what and why and done; a brief tells a Claude Author *how to build* it — links first, every
  reference exact — and the practice of running that agent well. Kicker at roadmap altitude.
- **Framing interactive (on the landing — ≥1, real computation).** Reuse the **course-arc selector** the A3
  landing carries (model lines 375–452 + the `<script>` at 758–857), re-centred on **A5** (set `status:"here"` on
  A5, `"built"` on A0–A4, `"planned"` on A6–A7; pre-select A5; update the readout tail to name the A4 spec as the
  input A5 wraps). This is a real pure-function readout over the fixed 8-part dataset and degrades. A **second**
  framing interactive is encouraged but the landing's minimum is one.
- **Orientation `.mods` grid** — the 3 dive cards (`why`/`what`/`how`), real hrefs, `built` pills.
- **Module preview — A5 lists its 8 modules.** A `.mods` grid (use `repeat(3,1fr)`, it wraps) of **eight
  `<div class="mod soon">` cards WITHOUT an href** (so the `links` gate stays green on the unbuilt routes), each
  with `<span class="pill soon">soon</span>`. The eight, from `a5.llms.md`:
  A5.1 *Writing for an agent: the llms.txt convention* · A5.2 *References and requirements* · A5.3 *Execution
  topology* · A5.4 *Agent stories* · A5.5 *The comprehensive implementation prompt* · A5.6 *Running Claude agents
  well* · A5.7 *Pragmatic Programming with Claude Agents* · A5.8 *Workshop — briefing the agent for Portal*. A
  `.note` says the modules ship after the landing, fanned out one Author per module against the seeded triad.
- **References** (≥3 real vetted Sources — see (D) registry). Use: the `llms.txt` convention (`llmstxt.org`),
  Anthropic — Building effective agents (`anthropic.com/engineering/building-effective-agents`), The Pragmatic
  Programmer (`pragprog.com`). Related-in-course: `/spec`, `/why/loop`, `/what/four-artifacts`, `/roadmap`,
  `/elixir/phoenix`.

**The three A5 dives:**
- **`why` (dive 1) — why a brief layer.** The argument: a spec defines what/why/done but is not runnable by an
  agent on its own; the brief fixes every remaining *how-to-build* decision (the exact sources, the runtime shape,
  the build order, the proof gates) and leaves the agent no ambiguity the Operator must own. **Open by echoing the
  reverse-verification link:** *A4 produced a spec that is correct by definition; A5 exists because a spec is not
  code, and an agent without a brief would decide what the Operator must decide.* Interactive idea (real data):
  **spec-vs-brief diff** over a fixed dataset of the A5 brief's five parts — toggle "person doc" vs "agent brief"
  and the readout reports how many references are front-loaded and how many narrative lines are removed (pure fn
  over the fixed five-part list; grounds on a real `f6.N.llms.md`).
- **`what` (dive 2) — what the chapter covers.** The five parts of an `.llms.md` (references, requirements,
  topology, agent stories, the implementation prompt) and the eight modules ahead, at roadmap altitude. Interactive
  idea: a **brief-anatomy selector** — pick one of the five parts (fixed dataset), readout reports its role, the
  module that teaches it (A5.1…A5.5), and the real Portal artifact it lands on (`f6.N.llms.md` / `f6.N.prompt.md`).
- **`how` (dive 3) — how you learn and build it here.** The method: write the brief part by part, run the agent,
  review *against the spec's Definition of Done, not the agent's self-report*, intervene when needed. The Portal
  practice: the A5.8 workshop briefs the engine chapter and makes a first full pass from spec to running code.
  Interactive idea: a **review-the-output checklist** — a fixed list of acceptance gates from a real agent story;
  toggle each "checked against spec" and the readout reports how many gates a critical review closes vs an
  agent-self-report (pure fn; the take: review against the spec, never the self-report).

**Locked pager/crumbs for A5:**
- Landing pager: prev `= /course/agile-agent-workflow/spec` (A4 landing), next `= /course/agile-agent-workflow/brief/why`.
- `why` pager: prev `= …/brief` (landing), next `= …/brief/what`.
- `what` pager: prev `= …/brief/why`, next `= …/brief/how`.
- `how` pager: prev `= …/brief/what`, next `= /course/agile-agent-workflow/reliability` (the **next chapter
  landing**, A6).
- **Cross-chapter transient:** `…/brief/how`'s `next` (`/reliability`) is built by the A6 sibling in this same
  batch. A `links` FAIL on **that one route only** is expected at your self-gate until A6 lands; every other link
  must resolve. The Operator runs the authoritative full-batch gate at the end.

### A6 — `/reliability` — "Reliability and correctness"

**Accent (locked): sage** (`--sage` / `--sage-bright`). Keep `<h1> .ex` rendering elixir-purple if you copy the
shared CSS unchanged (that is fine and consistent course-wide); apply **sage** to this chapter's *interactive
accents* — set `data-c="sage"` on the `.solid-select` buttons and use the sage fills in your SVGs — so A6 reads as
the sage chapter without editing the shared `h1 .ex` rule. (Do not invent new CSS; reuse the existing `data-c`
hooks and the `--sage*` tokens already in the design system.)

**Model + grounding — NO TRIAD.** Copy the same two A3 model pages. **A6 has no seeded triad** (`a6.*` does not
exist) — ground **ONLY on `aaw.roadmap.md`** (Part VI: "the increment built to production quality") and the
`aaw.progress.md` line ("scope not yet enumerated"). A6's scope, named **only at the roadmap's altitude**: **OTP
supervision, boundaries, parse-don't-validate, property tests.** Do **not** enumerate or invent A6 modules — there
is no module set yet; the dashboard excludes A6 from its denominator until its triad is seeded.

**Landing `/reliability` content:**
- **Hero.** `<h1>` `Reliability and <span class="ex">correctness</span>` (accent word in `<span class="ex">`).
  Lede: A5 leaves a built increment that passes its own demo; A6 makes it production-grade — it survives a
  malformed input, a crashed process, and an invariant proven across generated inputs rather than asserted on a
  chosen few. Kicker at roadmap altitude.
- **Framing interactive (≥1, real computation).** Reuse the **course-arc selector**, re-centred on **A6** (A0–A5
  `built`/`here` appropriately: A0–A4 `built`, A5 `built` for the purpose of "ships before A6", A6 `here`, A7
  `planned`; the readout tail names *what A5 leaves unproven* — the production-readiness gap A6 closes). One framing
  interactive is the minimum.
- **NO module cards — honest deferral.** A6 does **not** invent module cards. Instead a `.note` (the canonical
  forward-pointer style) states plainly: *A6's modules will be enumerated when its triad (`a6.{md,stories.md,
  llms.md}`) is seeded; the chapter's scope, per the course roadmap, is OTP supervision, boundaries that
  parse-don't-validate, and property tests — the techniques that turn a built increment into a production-grade
  one.* This is the load-bearing honesty rule for A6: name the scope at roadmap altitude, defer the module set.
- **References** (≥3 real vetted Sources, all already in the home registry): parse-don't-validate
  (`lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/`), railway-oriented programming
  (`fsharpforfunandprofit.com/rop/`), StreamData (`hexdocs.pm/stream_data/StreamData.html`). Optionally also
  Continuous Delivery (`continuousdelivery.com`). Related-in-course: `/brief`, `/spec`, `/why/correct`,
  `/why/loop`, `/elixir/phoenix`, `/elixir/course` (OTP internals — cite, do not re-teach).

**The three A6 dives** (all grounded on `aaw.roadmap.md` scope only; defer specifics where the triad is unseeded):
- **`why` (dive 1) — why reliability is its own layer / the failure it prevents.** **Open by echoing the
  reverse-verification link:** *A5 produces a built increment that is correct on the happy path but not proven
  under failure; A6 exists to close exactly that gap.* Name the three failures A6 prevents: an unhandled malformed
  input, a crashed process that propagates, an invariant held by luck. Interactive idea: **happy-path-vs-production
  meter** over a fixed dataset of input cases (valid, malformed, boundary, concurrent) — toggle "happy path only"
  vs "production-grade" and the readout reports how many of the fixed cases survive (pure fn over the fixed case
  list; the take: a demo passing is not a production guarantee).
- **`what` (dive 2) — what the chapter covers.** The four scope pillars from the roadmap: **OTP supervision ·
  boundaries · parse-don't-validate · property tests** — each named at roadmap altitude, each with a one-line
  what-it-adds. A `.note` defers the module-by-module breakdown to the unseeded triad. Interactive idea: a
  **scope-pillar selector** — pick one of the four pillars (fixed dataset), readout reports the failure it
  addresses and the companion `/elixir` chapter that teaches its OTP mechanics (cite, do not re-teach).
- **`how` (dive 3) — how you learn and build it here.** The method: harden the *built* increment from A5 against
  the four pillars, accept it only when an invariant is *proven* (property test) not asserted, and treat a parsed
  boundary value as the only thing the core trusts. The Portal practice: the increment's boundary parses untrusted
  input into a typed value (cite `Portal.ID.generate/1`/`decode/1` as the only free API; do not invent surfaces),
  and a supervisor isolates a crash. Interactive idea: **assert-vs-prove** over a fixed set of invariants — toggle
  "asserted on examples" vs "proven across generated inputs" and the readout reports the count of inputs covered
  (pure fn; the take: a property test proves; an example asserts).

**Locked pager/crumbs for A6:**
- Landing pager: prev `= /course/agile-agent-workflow/brief` (A5 landing — **built by the A5 sibling in this
  batch; a `links` FAIL on this one route is the expected cross-chapter transient until A5 lands**), next
  `= /course/agile-agent-workflow/reliability/why`.
- `why` pager: prev `= …/reliability` (landing), next `= …/reliability/what`.
- `what` pager: prev `= …/reliability/why`, next `= …/reliability/how`.
- `how` pager: prev `= …/reliability/what`, next `= /course/agile-agent-workflow/portal` (the **next chapter
  landing**, A7 — built by the A7 sibling; expected transient until A7 lands).

### A7 — `/portal` — "Portal exemplar (zero to production)"

**Accent (locked): gold** (`--gold` / `--gold-bright`). Gold is the design system's primary affordance colour and
suits the capstone. As with A6, keep the shared `h1 .ex` rule unchanged (it renders elixir-purple — consistent
course-wide) and apply **gold** to this chapter's interactive accents (`data-c="gold"` on `.solid-select` buttons,
gold SVG fills). Reuse existing hooks; invent no CSS.

**Model + grounding — NO TRIAD.** Copy the same two A3 model pages. **A7 has no seeded triad** (`a7.*` does not
exist) — ground **ONLY on `aaw.roadmap.md`** (Part VII: "the whole loop run end to end on the Portal, zero to
production") and `aaw.progress.md` ("planned · 0/7 steps", **steps A7.01–A7.07**). The seven steps are named at the
roadmap's altitude as *steps* (not modules), and the step *contents* are deferred to the unseeded triad — name the
sequence, not invented detail.

**Landing `/portal` content:**
- **Hero.** `<h1>` `The Portal <span class="ex">exemplar</span>` (accent word in `<span class="ex">`). Lede: every
  Part taught one move on a worked fragment; A7 runs the whole loop — decompose, roadmap, spec, brief, build,
  harden, accept — end to end on the Portal, zero to production. Kicker at roadmap altitude.
- **Framing interactive (≥1, real computation).** Two good options; pick one as the primary and the other as a
  second if you add one. (1) The **course-arc selector** re-centred on **A7** (A0–A6 `built`/appropriate, A7
  `here`; the readout tail names A7 as the run that composes every prior Part). (2) A **the-whole-loop walk** —
  reuse the A3 `.arc-flow` spine pattern but over the **seven A7 steps A7.01–A7.07** as a fixed dataset: select a
  step, the readout reports its name (zero-to-production phase) and which prior chapter's technique it runs
  (A2 decompose → A3 roadmap → A4 spec → A5 brief/build → A6 harden → accept → ship). Both are real pure-function
  readouts over a fixed dataset and degrade. The loop-walk is the stronger framer because it shows the composition
  the chapter is *about*.
- **NO module/step-content cards — honest deferral.** A7 names the **seven steps A7.01–A7.07** *as a sequence only*
  (in prose or as a list, at roadmap altitude), and a `.note` states: *A7's steps will be detailed when its triad
  (`a7.{md,stories.md,llms.md}`) is seeded; the chapter, per the course roadmap, runs the whole Author/Operator
  loop end to end on the Portal — zero to production — across the seven steps A7.01–A7.07.* Do **not** invent the
  content of any step, any Portal surface beyond the five canonical ones, or any API beyond
  `Portal.ID.generate/1`/`decode/1`.
- **References** (≥3 real vetted Sources from the registry): The Pragmatic Programmer (`pragprog.com` — tracer
  bullets / the whole system running end to end), Continuous Delivery (`continuousdelivery.com` — releasable at
  every increment), Extreme Programming Explained (`oreilly.com` — the inspect-and-adapt loop run whole).
  Related-in-course: `/reliability`, `/brief`, `/roadmap`, `/decomposition`, `/spec`, `/elixir/phoenix`.

**The three A7 dives** (grounded on `aaw.roadmap.md` only; defer step contents to the unseeded triad):
- **`why` (dive 1) — why an end-to-end exemplar.** **Open by echoing the reverse-verification link:** *A6 makes
  each rung production-grade; A7 exists because the method is only proven when the whole loop runs end to end on a
  real system — a sequence of hardened rungs is not the same as a demonstrated, composed run.* The failure it
  prevents: techniques taught in isolation that never compose into a shipped system. Interactive idea:
  **isolated-moves-vs-composed-run** over a fixed dataset of the seven Parts A1–A7 — toggle "taught in isolation"
  vs "run as one loop" and the readout reports whether the system ships (pure fn; the take: a method is proven by
  one whole run, not seven separate lessons).
- **`what` (dive 2) — what the chapter covers.** The seven steps A7.01–A7.07 as the zero-to-production arc, named
  at roadmap altitude, with the module/step detail deferred. Interactive idea: a **seven-step walk** — select a
  step (fixed dataset A7.01–A7.07), readout reports the step's phase name and which prior chapter's technique it
  runs; a `.note` defers the step's internals to the triad.
- **`how` (dive 3) — how the loop runs here.** The method: run the Author/Operator loop once, uninterrupted, on the
  Portal — Operator decomposes/roadmaps/specs/briefs/accepts, Author builds/hardens — each rung shipped to
  production quality before the next. The Portal practice: the five canonical surfaces (the branded store, the
  event-sourced engine behind one facade, the Phoenix web app, the Telegram bot, the student dashboard) come up in
  dependency order; cite the companion `/elixir` build, never re-teach it. Interactive idea: a **rung-by-rung
  ledger** — a fixed sequence of rungs; advance through them and the readout reports rungs shipped and the
  production-quality gate held at each (pure fn; the take: the loop ships one production-grade rung at a time, end
  to end).

**Locked pager/crumbs for A7:**
- Landing pager: prev `= /course/agile-agent-workflow/reliability` (A6 landing — **built by the A6 sibling in this
  batch; a `links` FAIL on this one route is the expected cross-chapter transient until A6 lands**), next
  `= /course/agile-agent-workflow/portal/why`.
- `why` pager: prev `= …/portal` (landing), next `= …/portal/what`.
- `what` pager: prev `= …/portal/why`, next `= …/portal/how`.
- `how` pager: prev `= …/portal/what`, next `= /course/agile-agent-workflow` (the **course home** — A7 is the last
  chapter, so its final `how` returns to the course home, which resolves).

---

## (D) Mandatory rules + guards (every page, every writer)

1. **Clickable segmented route-tag** (the Elixir pattern). In `<header class="site">`, render each path part as its
   own element: intermediate parts are `<a href>` to that route level, the current (last) part is
   `<span class="rcur">`, separated by `<span class="rsep">/</span>`; `/course/agile-agent-workflow` is **one**
   segment. Keep the `.route-tag a` / `.rsep` / `.rcur` CSS. Examples:
   - A5 landing: `<span class="route-tag"><span class="rsep">/</span><a href="/course/agile-agent-workflow">course/agile-agent-workflow</a><span class="rsep">/</span><span class="rcur">brief</span></span>`
   - A5 `why` dive: `…/course/agile-agent-workflow</a><span class="rsep">/</span><a href="/course/agile-agent-workflow/brief">brief</a><span class="rsep">/</span><span class="rcur">why</span></span>`
   (A6 uses `reliability`, A7 uses `portal` in place of `brief`.)
2. **Canonical 3-column `.foot-cols` footer** — copy verbatim from the model (no one-off footers). Brand + `.tag` /
   a chapter-or-module link column / a "The course" column + `.foot-bottom` with the `.stamp` + decoder script
   (verbatim; the valid `TSK0Ng9hnHJgW0` id). Keep the `.foot-cols` / `.fbrand` / `.foot-bottom` CSS.
3. **References → Sources are REAL vetted external links** — `<li><a href="https://…">Author &mdash;
   <em>Title</em></a> &mdash; gloss.</li>`. Reuse ONLY URLs from the registry below; **never invent a URL.**
   `Related in this course` entries are internal routes that must resolve.
4. **Two interactives per page** (one in the hero `.hero-split` figure, one in main content) that teach *different*
   moves. **The landing carries ≥1 framing interactive.** Each performs the real operation and shows its actual
   result in a live `.geo-readout` (`aria-live`), computed by small **pure** functions over a **fixed dataset**;
   **degrades** (controls + SVG in static markup, JS only enhances); honours `prefers-reduced-motion`; uses **no**
   browser storage. Close concept pairings with a `.bridge` (`.cell.idea` principle → `.arrow` → `.cell.elix`
   Portal practice) and a `.take`.
5. **Voice.** No first person; no exclamation marks; no emoji; none of {just, simply, obviously, effortless,
   magical, revolutionary, blazing}; no perceptual/interior-state verb applied to a tool or an agent — **the agent
   is never anthropomorphised** (it implements well-specified work; it does not "want"/"see"/"think"). Active
   voice, short sentences. ("just enough" → "only enough".)
6. **Clamp() values SPACED.** `clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` — keep spaces around `+`/`-`. `1.9rem+4.2vw`
   is invalid CSS and silently drops to a UA default. (Copying the model `<head>` verbatim gives you the correct
   spaced forms — do not retype them.)
7. **md-first.** Each page also gets its md source of record under
   `docs/agile-agent-workflow/content/<chapter>/<index|why|what|how>.md` — route, lead, the precise framing, the
   worked Portal example, BOTH interactives (exact element ids + pure-function signatures + readout strings), the
   principle↔practice bridge, references, and wiring.
8. **No-invent (CRITICAL for A6/A7 — they have NO triad).** Ground A6/A7 **only on `aaw.roadmap.md`**. Invent no
   module, no step content, no API, no Portal surface. The only free Portal API is `Portal.ID.generate/1` /
   `Portal.ID.decode/1` (`.type`, `.timestamp`). The five canonical Portal surfaces are the branded store, the
   event-sourced engine behind one facade, the Phoenix web app, the Telegram bot, the student dashboard — invent no
   others. Cite the companion `/elixir` course for OTP internals; do not re-teach them. **Where deep content would
   require the unseeded triad, NAME the deferral** (a `.note` saying the modules/steps are detailed once `a6.*` /
   `a7.*` is seeded) rather than fabricate.
9. **No Elixir source on the page** unless a real verbatim citation — a `pre.code` block carries spec/roadmap
   markdown (like the A3 dive's `phoenix.roadmap.md` excerpt), never invented Elixir.

### The Sources registry (real, vetted; reuse, never fabricate)

| Title | URL | Best for |
|---|---|---|
| The Pragmatic Programmer | `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` | A5, A7 |
| Extreme Programming Explained | `https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/` | A7 |
| Continuous Delivery | `https://continuousdelivery.com/` | A6, A7 |
| User Stories Applied | `https://www.mountaingoatsoftware.com/books/user-stories-applied` | A5 |
| The `llms.txt` convention | `https://llmstxt.org/` | A5 |
| Anthropic — Building effective agents | `https://www.anthropic.com/engineering/building-effective-agents` | A5 |
| Anthropic — Claude Code best practices | `https://www.anthropic.com/engineering/claude-code-best-practices` | A5 |
| Parse, don't validate (King) | `https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/` | A6 |
| Railway-oriented programming (Wlaschin) | `https://fsharpforfunandprofit.com/rop/` | A6 |
| StreamData (property testing) | `https://hexdocs.pm/stream_data/StreamData.html` | A6 |

---

## (E) The gate command — ship each page only at STATUS: PASS

In zsh, define the flags once and splat them with `${=FLAGS}`:

```zsh
FLAGS="--routes-from /course/agile-agent-workflow=html/agile-agent-workflow --chapter-alias a0=what,a1=why,a2=decomposition,a3=roadmap,a4=spec,a5=brief,a6=reliability,a7=portal --require-refs"
apps/jonnify-cms/bin/cms check ${=FLAGS} html/agile-agent-workflow/<chapter>/<page>.html
```

All ten gates must PASS: `containers · svg · no-future · voice · storage · motion · degrade · links · pager · refs`.
**The one expected transient:** the cross-chapter prev/next that points at a sibling chapter's landing still being
built in this batch (A6's landing.prev `/brief`; A7's landing.prev `/reliability`; A5's `how`.next `/reliability`;
A6's `how`.next `/portal`) will FAIL `links` on **that one route only** until the sibling lands — every other gate
and every other link must pass. The Operator runs the authoritative full-batch gate after all three chapters land.

After PASS, adversarially read the gate-invisible bits: clamp() values are spaced; the route-tag is the exact
segmented form; every Sources `<li>` carries `href="http`; crumbs and pager point at the **intended** parent (the
locked targets above), not merely a resolving one; each inline `<script>` parses (`node --check`).

---

## (F) Hard constraints (every writer)

- **Never run git** — no `add`, `commit`, `restore`, `stash`, `checkout`, `reset`. Leave changes in the working
  tree for the Operator to commit.
- **Edit ONLY your one chapter's files** — its 4 pages (`<chapter>/index.html`, `<chapter>/why.html`,
  `<chapter>/what.html`, `<chapter>/how.html`) and their 4 md sources under
  `docs/agile-agent-workflow/content/<chapter>/`. Do **NOT** touch the home `index.html`, the other two chapters,
  or the four living views (`agile-agent-workflow.toc.md`, `course-map.md`, `llms.md`, the served-page relinks) —
  the Operator syncs those after the batch to avoid a parallel-write conflict.
- **Never screenshot** — validation is headless and text-only (`cms check` + reading the markup + an optional
  `curl`/`python3` crawl against `:8765`).

> The four pages of your chapter are a thin, provable slice of this course: the landing frames the chapter, the
> three orientation dives orient the reader, and every page lands a principle on the Portal as a concrete practice.
> Build only your chapter. Ship only at STATUS: PASS.
