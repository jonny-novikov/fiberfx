# Agile Agent Workflow in Elixir

> **Pragmatic Programming with Claude Agents — building Portal from zero to production.**
> A practitioner's course on shipping reliable software with a human–agent pair. You decompose a product into thin,
> valuable increments, plan their delivery in a roadmap, define and prove each one in a spec, brief a Claude agent to
> build it, and harness it for correctness — then run that loop, increment by increment, until a real Elixir/OTP
> platform is live in production.

This course teaches a way of working, not a framework. Its claim is simple: a human who supplies judgment, taste, and
acceptance, paired with a Claude agent that supplies fast, tireless implementation, ships better software than either
alone — *provided the work is decomposed into thin, provable slices and the agent is briefed precisely.* Every idea is
practiced on one running project, the Portal, carried from an empty repository to a deployed, multi-surface system.

## The practical project: Portal

**Portal** is a learning platform — courses, enrollments, lessons, progress, payments — built as a stack of chapters
over a single domain core: a branded store, an event-sourced engine behind one facade, a Phoenix web surface, a
Telegram bot, and a student dashboard. You build it the way the course teaches: one value ladder per chapter, each rung
specified, briefed, built by an agent, and accepted only when its invariants and acceptance criteria hold. By the end,
Portal runs in production, and you have a living spec system that documents every decision.

## Who this course is for

Working developers and tech leads who want a repeatable, rigorous way to build software *with* AI coding agents rather
than around them. Comfort with a typed-or-functional language helps; the examples are Elixir/OTP, but the workflow
transfers to any stack. No prior agent experience is assumed.

## What you will be able to do

- Decompose a product vision into a dependency-ordered ladder of small, valuable, testable user stories.
- Plan delivery in a roadmap of thin, robust increments grouped into shippable milestones.
- Write specifications that are precise, traceable, and accepted only when proven — *correct by definition.*
- Brief a Claude agent with references, requirements, an execution topology, and a runnable implementation prompt.
- Run the Author/Operator loop, reviewing and steering an agent's work and knowing when to step in.
- Build for reliability and correctness with OTP supervision, boundaries, parse-don't-validate, a closed error set,
  event sourcing, and property-based tests.
- Take a system from zero to production with releases, runtime configuration, and clustering.

## Prerequisites

Programming fundamentals and version control. Elixir basics are reviewed where they matter; deep OTP knowledge is
built in Part VI. Access to a Claude coding agent (for example, Claude Code) for the workshops.

## How the course works

Each part teaches one layer of the workflow and applies it immediately to Portal in a hands-on workshop. The first six
parts build the method and the project together; the seventh runs the full loop end to end, chapter by chapter, to
production. A reference implementation — the Portal spec system, with its roadmaps, specs, and agent briefs — sits
alongside the course as a worked example you can read in full.

## Conventions

- **Language**: Elixir/OTP; pure functions and supervised processes.
- **Identifiers**: branded Snowflake ids (integer columns; a branded transport form with a namespace prefix and base62
  encoding, e.g. `TSK0KHTOWnGLuC`).
- **Artifacts**: a chapter `roadmap.md`, a per-rung spec, a `.stories.md`, and a `.llms.md` agent brief.
- **Quality**: every artifact passes mechanical gates (voice, structure, traceability, fences, links) before it ships
  — the course's working definition of "A+".

## Status — a living map, maintained by writers

This table of contents is **kept in sync with the built course in real time**: when a module or chapter ships, its
entry here is updated — status flipped, route linked, abstract refreshed — so this file always mirrors what is live.
It is the human-readable companion to two machine-checkable records, and must never contradict them: the
chapter/route/status table in `.claude/skills/agile-course-writer/references/course-map.md`, and the per-page sources
of record under `docs/agile-agent-workflow/content/`.

**Status legend:** `✓ built` (live, served under `/course/agile-agent-workflow/…`) · `◐ in progress` · `○ planned`.

**Route mapping.** The seven teaching **Parts I–VII** below map to course chapters **A1–A7**. An additional
**A0 · Foundations** on-ramp (built) previews the method in three questions before Part I develops them in depth.

### A0 · Foundations — the on-ramp&nbsp; `✓ built` · [`/course/agile-agent-workflow/what`](/course/agile-agent-workflow/what)
*A short foundations chapter that frames the whole method before Part I: **why** thin, provable slices beat both vibe
coding and big-bang specs; **what** we are building — two layers, four artifacts, one loop; and **who** does the work —
the Operator/Author pairing. Its built module, A0.2, is the framework in a single read; A0.1 and A0.3 preview Part I.*
- **A0.2 · What we are building** `✓` — the framework's structure, vocabulary, and motion:
  [the two-layer model](/course/agile-agent-workflow/what/two-layer-model)
  (+ [anatomy of a `roadmap.md`](/course/agile-agent-workflow/what/two-layer-model-roadmap-anatomy)),
  [the four artifacts](/course/agile-agent-workflow/what/four-artifacts),
  and [the Author/Operator loop](/course/agile-agent-workflow/what/author-operator-loop).
- A0.1 · Why it works `○` — the two failure modes and the case for thin slices (developed in depth at §1.1).
- A0.3 · Who does the work `○` — the Operator, the Author, and the pairing in practice (developed at §1.3).

**Current build front.** Part I is nearly complete — **§1.1–§1.4 and §1.6 are built** (chapter A1,
[`/course/agile-agent-workflow/why`](/course/agile-agent-workflow/why)); only §1.5 remains. **Part II is complete —
its landing and all seven modules §2.1–§2.7 are built**
([`/course/agile-agent-workflow/decomposition`](/course/agile-agent-workflow/decomposition)); Parts III–VII are
planned.

---

# Part I — Why an Agile Agent Workflow

*The philosophy and the thesis. Why pragmatic, story-led, agent-driven development works; the two roles and the two
layers; what "done" means. This part frames the whole course: a tight human–agent loop over thin, provable
increments.*

### 1.1 · The two failure modes: vibe coding and big-bang specs&nbsp; `✓ built` → [`/why/failure-modes`](/course/agile-agent-workflow/why/failure-modes)
Unstructured prompting produces code no one can trust; monolithic up-front specs produce documents no one can finish.
Both fail for the same reason — they skip the unit that makes software tractable. This chapter makes the case for thin
vertical slices with provable completion as the alternative.

### 1.2 · Pragmatic Programming, revisited for agents&nbsp; `✓ built` → [`/why/pragmatic`](/course/agile-agent-workflow/why/pragmatic)
Tracer bullets, walking skeletons, orthogonality, "good-enough software" — the pragmatic canon re-read for a world
where an agent writes much of the code. What the agent changes (throughput, tirelessness, breadth) and what it does not
(the need for judgment, decomposition, and acceptance) — the first statement of the course's central value.

### 1.3 · The Author/Operator loop&nbsp; `✓ built` → [`/why/loop`](/course/agile-agent-workflow/why/loop)
The two roles at the heart of the method: the human **Operator** who sharpens intent and reviews outcomes, and the
Claude **Author** who specifies and implements. The cycle — sharpen, build, ship, demo, review, feedback, adapt — and
why it is an inspect-and-adapt loop, not a handoff.

### 1.4 · Two layers: roadmap and specs&nbsp; `✓ built` → [`/why/two-layers`](/course/agile-agent-workflow/why/two-layers)
Separating *how we deliver* (the roadmap) from *what we build and prove* (the specs). The governing rule that keeps the
pair honest: the spec is the single source of truth, and feedback from a shipped increment edits the spec rather than
forking from it.

### 1.5 · Correct by definition&nbsp; `○ planned`
What "done" means in this workflow: a closure over traced, executed checks — every deliverable realized by a story,
every story accepted, every invariant proven. The mechanical quality gates that turn "A+" from an opinion into a
repeatable result.

### 1.6 · Meet the project: Portal&nbsp; `✓ built` → [`/why/portal`](/course/agile-agent-workflow/why/portal)
The running project introduced: a learning platform built as a stack of chapters over one facade, from a branded store
up to a student dashboard. What "zero" looks like, what "production" demands, and how the course will get there one
rung at a time.

---

# Part II — Decomposition: from vision to user stories&nbsp; `✓ all modules built` → [`/decomposition`](/course/agile-agent-workflow/decomposition)

*The craft of turning a product vision into a ladder of small, valuable, testable units. User stories, INVEST,
acceptance criteria, and splitting — the input that everything downstream depends on.*

### 2.1 · Value, not tasks&nbsp; `✓ built` → [`/decomposition/value`](/course/agile-agent-workflow/decomposition/value)
Why a unit of work is a unit of *value a role can use*, not a technical chore. The shift from to-do lists to outcomes,
and why it is the single most important habit in the workflow. Dives: `outcome-not-chore` · `who-benefits` ·
`vertical-slice`.

### 2.2 · The Connextra form and the three Cs&nbsp; `✓ built` → [`/decomposition/connextra`](/course/agile-agent-workflow/decomposition/connextra)
"As a `<role>`, I want `<capability>`, so that `<benefit>`." Card, Conversation, Confirmation — a story as a promise of
value with a conversation attached, not a frozen contract. Dives: `role-want-reason` · `three-cs` · `portal-cards`.

### 2.3 · INVEST: what a good story looks like&nbsp; `✓ built` → [`/decomposition/invest`](/course/agile-agent-workflow/decomposition/invest)
Independent, Negotiable, Valuable, Estimable, Small, Testable. The common story smells — too big, untestable, coupled,
purely technical — and how to fix each. Dives: `six-tests` · `story-smells` · `small-and-independent`.

### 2.4 · Acceptance criteria with Given/When/Then&nbsp; `✓ built` → [`/decomposition/acceptance`](/course/agile-agent-workflow/decomposition/acceptance)
Gherkin scenarios as the shared, executable definition of done for a story. A story's Confirmation (2.2) earns a
Given/When/Then form; the concrete example IS the spec, read the same way by product, the Operator, and the Author, and
run as the rung's acceptance test over happy and sad paths — the seed of the Part IV spec layer and its harness. Dives:
`given-when-then` · `examples-as-spec` · `scenarios-to-tests`.

### 2.5 · Splitting stories that are too big&nbsp; `✓ built` → [`/decomposition/splitting`](/course/agile-agent-workflow/decomposition/splitting)
Vertical-slice patterns — by workflow step, by business rule, by happy and sad paths, by operation — that cut a large
story into shippable ones without slicing it into horizontal layers no one can demo. The trigger is an INVEST failure on
Small or Estimable (2.3); the repair is a vertical split that keeps every slice demoable end to end (2.1.3), never a
horizontal layer (DB / API / UI) that ships a fragment no role can use. Dives: `when-to-split` · `split-patterns` ·
`vertical-not-horizontal`.

### 2.6 · The value ladder&nbsp; `✓ built` → [`/decomposition/value-ladder`](/course/agile-agent-workflow/decomposition/value-ladder)
Composing stories into a dependency-ordered ladder where each rung adds a usable capability, depends only on rungs
below it, and leaves the system runnable. The structure the rest of the course builds on. Dives: `compose-the-ladder` ·
`dependency-order` · `always-runnable`.

### 2.7 · Workshop — decomposing Portal&nbsp; `✓ built` → [`/decomposition/workshop`](/course/agile-agent-workflow/decomposition/workshop)
Turn the Portal vision into chapters and a value ladder: store, engine, web, bot, dashboard. You leave this chapter
with the backlog you will specify, brief, and build for the remainder of the course. Dives: `vision-to-stories` ·
`split-and-test` · `order-the-backlog`.

---

# Part III — The roadmap layer: Agile delivery & iteration

*Planning delivery as thin, robust increments. Milestones, iterations, and the inspect-and-adapt loop — where the
Agile Manifesto, Extreme Programming, and Continuous Delivery meet the agent workflow in a `roadmap.md`.*

### 3.1 · Agile, distilled
Working software in short cycles, responding to change, inspect-and-adapt. The handful of principles that actually
drive the workflow, separated from the ceremony that does not.

### 3.2 · Extreme Programming for small batches
Small releases, incremental design, and continuous feedback, re-cast for an Author/Operator pair. Why small batches
lower risk and raise learning — and how an agent makes small batches cheap.

### 3.3 · Anatomy of a roadmap.md
What a chapter roadmap carries: what it delivers, the start/end handoff, the architecture decision, the milestones, the
per-iteration table, and the explicitly-named open decisions. A read-through of a complete roadmap.

### 3.4 · Thin but robust
The discipline at the centre of the method: each increment is a narrow vertical slice built to production quality —
supervised, contract-guarded, harnessed, and gated — never a prototype to be redone. The line between thin and flimsy.

### 3.5 · Milestones and iterations
Grouping rungs into shippable milestones; the Ships / Demo / Harness / Feedback iteration table; sequencing by
dependency and by product priority so the most valuable, least risky thread ships first.

### 3.6 · The program roadmap
The roadmap of roadmaps: sequencing whole chapters into program milestones for a system with many surfaces over one
core. How parallel surfaces (a web app and a bot) share a facade and ship on their own cadence.

### 3.7 · Tracer bullets and walking skeletons
Shipping a thin end-to-end thread before adding depth; de-risking integration early; deferring breadth deliberately —
the pragmatic techniques that keep a roadmap honest about uncertainty.

### 3.8 · Workshop — roadmapping Portal
Write Portal's chapter roadmaps and its program roadmap: the milestones, the iteration tables, and the seams you
choose to defer. The delivery plan you will execute in Part VII.

---

# Part IV — The spec layer: specifications & acceptance

*Specifications that are precise, traceable, and accepted only when proven. Specification by Example, the spec triad's
anatomy, invariants, and the traceability that makes completion verifiable rather than asserted.*

### 4.1 · Specification by Example
Examples as the shared, executable specification; living documentation that cannot drift from the system because the
system is checked against it. Removing ambiguity before a line of code is written.

### 4.2 · The triad: spec, stories, agent brief
Three artifacts per rung and the distinct question each answers — *what and why and done* (the spec), *who wants what*
(the stories), and *how to build it with proof gates* (the agent brief). Why the separation matters.

### 4.3 · Anatomy of a spec
Goal, Rationale (the five Ws), Scope (in and out), Deliverables, Invariants, and a Definition of Done. How to write
each section so it constrains the build without over-specifying the solution.

### 4.4 · From stories to a .stories.md
Deriving the stories file from the spec: Connextra stories with Given/When/Then, an INVEST line that names the
invariants each story exercises, and a Coverage line that maps every deliverable to the stories that realize it.

### 4.5 · Invariants: properties that must always hold
Naming the rules an increment must never break, and distinguishing an invariant (true for every value, always) from an
acceptance check (true for a specific scenario). The raw material of correctness.

### 4.6 · Traceability — correct by definition
The chain from deliverable to story to acceptance and invariant to requirement to agent story, and the completion rule
that closes it. How to make the whole chain checkable from the text alone.

### 4.7 · Workshop — specifying Portal's engine
Write the specs and stories for the engine chapter: its deliverables, its invariants, and the acceptance criteria that
will accept it. The contracts an agent will implement in Part V.

---

# Part V — The agent brief (.llms.md) and the implementation workflow

*The agent-facing brief and how a Claude agent turns it into working code. References-first, requirements, execution
topology, agent stories, and the comprehensive implementation prompt — and the practice of running an agent well. The
heart of "Pragmatic Programming with Claude Agents."*

### 5.1 · Writing for an agent: the llms.txt convention
Why a brief written for an agent differs from documentation written for a person — links first, prose second, every
reference exact. The shape of a machine-readable implementation brief.

### 5.2 · References and requirements
The precise sources the agent must read first — framework docs, the upstream contract, the prior specs — and numbered,
testable requirements, each traced back to a story and forward to an invariant or check.

### 5.3 · Execution topology
Giving the agent the runtime shape (processes, supervision, request flow) and the build-order task DAG, plus the exact
files it will touch — so the agent assembles a system rather than a pile of snippets.

### 5.4 · Agent stories
The executable counterpart of a user story: a Directive (what the agent does) and an Acceptance gate (the check that
closes it). The short first-two-stories plan that proves the path is unambiguous before the agent runs.

### 5.5 · The comprehensive implementation prompt
The single brief an agent runs to build an increment in task order and self-check against the gates. The anatomy of a
prompt that leaves no decision the spec has not already fixed.

### 5.6 · Running Claude agents well
The practice around the prompt: how to brief, supervise, and review an agent; reading its work critically; recognizing
when to let it run and when to intervene. Lessons from building effective agents, applied to real implementation.

### 5.7 · Pragmatic Programming with Claude Agents
The thesis chapter. The agent as a fast, tireless implementer of *well-specified* thin slices; the human as the source
of judgment, taste, and acceptance; and why the pairing compounds — speed from the agent, direction and correctness
from the workflow. Where the value is real, and where it is not.

### 5.8 · Workshop — briefing the agent for Portal
Write the engine chapter's agent briefs and run the implementation with a Claude agent: brief, build, and verify
against the Definition of Done. Your first full pass from spec to running code.

---

# Part VI — Reliability and correctness

*Building it right. The Elixir/OTP and functional-programming techniques that make each increment reliable and
correct: supervision, boundaries, parsing at the edge, illegal states made unrepresentable, a closed error set,
event sourcing, and property-based testing.*

### 6.1 · Let it crash: OTP supervision
Processes, supervisors, and restart strategies. Reliability through isolation and recovery rather than defensive code —
why a supervised system heals, and how to shape a supervision tree.

### 6.2 · Boundaries: functional core, imperative shell
Keeping the domain pure and pushing effects to the edge. The testability and reasoning that follow when the core is a
function of its inputs and the shell is thin.

### 6.3 · The master invariant
A single architectural rule — every surface calls only the facade; the core is framework-free — that keeps a growing
system safe as you add chapters. How to state one, and how to check it mechanically.

### 6.4 · Parse, don't validate
Turning untrusted input into a constrained type once, at the boundary, so downstream code is total and cannot be
handed a bad value. The technique that makes "validate everywhere" unnecessary.

### 6.5 · Make illegal states unrepresentable
Encoding invariants in types and structs so a bad state cannot be constructed in the first place. Designing data so the
compiler and the shape of the value carry the rules.

### 6.6 · Railway-oriented error handling
`with` and tagged tuples; a closed `%Portal.Error{}` set; expected failures modeled as values and exceptions reserved
for the truly exceptional. One consistent error discipline an agent can apply every time.

### 6.7 · Event sourcing and the Decider
`decide` and `evolve`; events as the source of truth; replay and audit. When event sourcing earns its complexity and
when it does not — a pragmatic, not dogmatic, treatment.

### 6.8 · Property-based testing
Stating an invariant and generating cases to attack it; shrinking to a minimal counterexample; the testing pyramid of
example, property, contract, and doctest. Proving the residual the types cannot.

### 6.9 · Quality gates as code
The mechanical checks — voice, structure, traceability, fences, links — that make "A+" objective and repeatable, run on
every artifact and every increment. Turning review standards into something a machine enforces.

### 6.10 · Workshop — making Portal correct
Encode the engine's invariants in types and a closed error set, and harness them with example and property tests. The
increment from Part V, now provably correct.

---

# Part VII — Portal: from zero to production

*The full loop, end to end. Walk the entire Portal build with the workflow — store, engine, web, bot, dashboard,
deploy — running the Author/Operator loop chapter by chapter until the platform is live. The capstone, and the proof
of the method.*

### 7.1 · The starting line: the branded store
The given foundation — branded Snowflake identities and the store the engine stands on. Establishing the conventions
and the zero state from which everything is built.

### 7.2 · The engine
From spec and brief to a supervised, event-sourced engine behind a single facade. The first real chapter built
end to end with the full workflow — decompose, roadmap, specify, brief, build, prove.

### 7.3 · The web
Serving the engine as a product: bounded contexts over the facade, server-rendered pages, LiveView, real-time updates,
authentication, and deployment. A live web application, shipped milestone by milestone.

### 7.4 · A second surface: the Telegram bot
A parallel surface over the same facade, in-process first with a documented scale-out seam. The payoff of the workflow's
discipline — a new channel that reuses the core without touching it.

### 7.5 · The student dashboard
Adding a new domain dimension — entitlements, where paid becomes unlocked — and a learner-facing dashboard of progress
and owned courses. Extending the closed error set safely, the workflow's way.

### 7.6 · Shipping to production
Releases, runtime configuration, clustering, and migrations. What production actually demands, and how thin, robust
increments arrived there without a big-bang launch.

### 7.7 · Retrospective: what the workflow bought us
A review of the journey: velocity from the agent, reliability from OTP and the gates, and a living spec system as
documentation. Where pragmatic programming with Claude agents paid off, where human judgment still decided, and how to
carry the loop to the next project.

---

# Appendix — Canon and further reading

The course distils and extends a body of practice. These are the primary sources, grouped by the workflow layer they
inform.

**Stories, specifications, and acceptance**
- Mike Cohn, *User Stories Applied* — <https://www.mountaingoatsoftware.com/books/user-stories-applied>.
- Bill Wake, *INVEST in Good Stories, and SMART Tasks* — <https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/>.
- Connextra story template (Agile Alliance glossary) — <https://www.agilealliance.org/glossary/user-story-template/>.
- Gherkin / Given-When-Then reference (Cucumber) — <https://cucumber.io/docs/gherkin/reference/>.
- Dan North, *Introducing BDD* — <https://dannorth.net/introducing-bdd/>.
- Gojko Adzic, *Specification by Example* — <https://gojko.net/books/specification-by-example/>.

**Agile delivery and iteration (the roadmap layer)**
- Kent Beck, *Extreme Programming Explained* — <https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/>.
- The Agile Manifesto and its principles — <https://agilemanifesto.org/principles.html>.
- Hunt & Thomas, *The Pragmatic Programmer* — <https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/>.
- Humble & Farley, *Continuous Delivery* — <https://continuousdelivery.com/>.

**Agent and implementation workflow**
- The `llms.txt` convention — <https://llmstxt.org/>.
- Anthropic, *Claude Code best practices* — <https://www.anthropic.com/engineering/claude-code-best-practices>.
- Anthropic, *Building effective agents* — <https://www.anthropic.com/engineering/building-effective-agents>.

**Reliability and correctness (Elixir and functional design)**
- Gary Bernhardt, *Boundaries* — <https://www.destroyallsoftware.com/talks/boundaries>.
- Scott Wlaschin, *Railway Oriented Programming* — <https://fsharpforfunandprofit.com/rop/>.
- Alexis King, *Parse, don't validate* — <https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/>.
- Yaron Minsky, *Effective ML* (make illegal states unrepresentable) — <https://vimeo.com/14313378>.
- `StreamData` (property-based testing for Elixir) — <https://hexdocs.pm/stream_data/StreamData.html>.

---

> Part of the jonnify toolkit. One project, carried from zero to production by a human and a Claude agent working a
> tight loop over thin, provable increments. The roadmap plans; the specs define and prove; the agent builds; the
> gates accept.
