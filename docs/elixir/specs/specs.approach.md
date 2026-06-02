# Specs approach — pragmatic, story-led, correct by definition

> The pattern every chapter of the Portal follows. It works in two layers: an **Agile roadmap** plans how a chapter's
> rungs ship as thin, robust increments, and a **spec triad** per rung defines, tells, and proves each increment. A
> rung is specified, told as user stories, handed to a coding agent as agent stories, and accepted only when its
> invariants and acceptance criteria hold. The aim is a build process that is pragmatic (each step ships value and
> stays runnable), invariant (the rules that must always hold are written down and checked), testable (every behavior
> is pinned by an example or a property), and correct by definition (nothing is "done" until its gates pass).

This file is the contract for the spec system itself. Every chapter conforms to it: `pragmatic/` (F5 — the engine),
`phoenix/` (F6 — the web), and `bot/` (F10 — the Telegram bot). Chapter indexes (e.g. `phoenix/phoenix.md`), chapter
roadmaps (e.g. `phoenix/phoenix.roadmap.md`), and rung triads (e.g. `phoenix/f6.1.md`) all follow the shapes below.
A rung is written `fN.M` (file) and `FN.M` (id prefix) — `N` the chapter, `M` the rung.

## Why this exists

The build guides under `build-guide/` teach a chapter and hand an agent copy-paste prompts. That works, but the
prompts describe *steps*, not *value*, and they carry no explicit notion of who the work is for, how it ships, or what
must remain true afterwards. This spec system adds four things on top:

- **Value framing.** Each rung is a feature that leaves the Portal demonstrably better and still running — the
  "add value in thin vertical slices" discipline, applied chapter by chapter.
- **A delivery plan.** Each chapter has a roadmap that sequences its rungs into shippable milestones and runs them as
  an inspect-and-adapt loop, so the order and the demo of each increment are explicit.
- **Stories.** Each rung is expressed as user stories (who wants what, and how we will know it works) and as *agent
  stories* (the same intent, made executable by a coding agent).
- **Provable completion.** Each rung declares invariants and a Definition of Done, and every requirement traces to an
  acceptance check or an invariant — so "complete" is a verifiable claim, not an opinion.

## The two layers: roadmap and specs

The system separates *how the work is delivered* from *what the work is and how it is proven*.

- **The roadmap layer** — `<chapter>.roadmap.md` (e.g. `pragmatic.roadmap.md`, `phoenix.roadmap.md`, `f10.roadmap.md`).
  The Agile delivery plan: it states what the chapter delivers, groups the rungs into shippable milestones, and runs
  them as an Author/Operator loop. The roadmap plans; it does not define behavior.
- **The spec layer** — the chapter index plus a triad per rung. The single source of truth: it defines each rung,
  tells it as stories, makes it executable as agent stories, and accepts it only when its gates pass.

The governing rule between the layers: **the spec is canonical, and feedback edits the spec.** When a shipped increment
prompts a change, the change lands in the rung's spec (and flows to its stories and agent brief), never as a divergent
build. The roadmap points at the specs; it never overrides them.

## The chapter and the value ladder

A **chapter** is a directory (`pragmatic/`, `phoenix/`, `bot/`) covering one layer of the Portal. Its rungs
`fN.1 … fN.k` form a **value ladder**: each rung

1. delivers a capability a named role can use,
2. depends only on rungs below it,
3. keeps everything below the `Portal` facade unchanged (the F5 boundary — see [The master invariant](#the-master-invariant)),
4. and leaves the platform runnable and demonstrable at the end.

Every chapter has an **index** (`<chapter>.md`) that maps the ladder, an optional **roadmap**
(`<chapter>.roadmap.md`) that plans delivery, and a **triad** per rung. A rung is small enough to build and verify in
one pass and large enough to be worth a demo.

## The artifacts

| Artifact | Scope | Audience | Answers |
| --- | --- | --- | --- |
| `<chapter>.md` (index) | one chapter | author, reviewer | the value ladder, the start/end handoff, the master invariant, per-rung abstracts and status |
| `<chapter>.roadmap.md` | one chapter | author, operator | how the rungs ship — milestones, the Author/Operator loop, per-iteration demo & harness |
| `fN.M.md` (spec) | one rung | humans (author, reviewer) | what & why & done |
| `fN.M.stories.md` | one rung | humans (product, QA) | who wants what, and how we'll know |
| `fN.M.llms.md` (agent brief) | one rung | a coding agent | how to build it, with proof gates |

The index is the map; the roadmap is the plan; the triad is the contract. The roadmap is optional for a chapter that
is purely specified (no near-term delivery), but a chapter being shipped has one.

## The Agile roadmap

A chapter's roadmap is the delivery contract. It carries:

- **What the chapter delivers**, and the **start/end handoff** — what it assumes (the prior chapter's facade and
  contract) and what running system it leaves behind.
- **The architecture decision** where one is being made (e.g. ex_gram in-BEAM for the bot; standard Phoenix/LiveView
  for the web), with the reasoning and the reversible seam.
- **The master invariant**, restated for the chapter — the boundary every rung holds.
- **How the roadmap runs** — the Author/Operator loop (below).
- **A "thin but robust" definition** — what production quality means for this chapter (supervised, contract-guarded,
  harnessed, gated).
- **The delivery arc** — the rungs grouped into shippable **milestones**, and a per-rung iteration table with columns
  **Rung · Ships (the slice) · Demo · Harness · Feedback asked**.
- **Seams & open decisions** — choices deliberately deferred to a later rung, named so they are decisions, not
  surprises.
- **Conventions** — the master invariant, branded Snowflake ids, the chapter's framework idioms, and the quality
  gates.

**The Author/Operator loop.** Two roles run each rung:

- **Author (Claude)** turns a roadmap rung into a spec triad and a build plan, at the quality bar in this document.
- **Operator (the human)** reviews the delivered specs and the shipped increment, then returns feedback asking for the
  next rung's specs or a change to a shipped one.

The loop per rung is **sharpen → build → ship → demo → review → feedback → adapt** — an inspect-and-adapt cycle.
"Adopt / learn / evolve" refers to this feature-development process, not to end-user telemetry. Feedback edits the
spec, because the spec is the single source of truth.

**Thin but robust.** Each rung is a narrow vertical slice — usually one capability, end to end — built to production
quality, not a prototype: supervised under OTP, every action through the `Portal` contract and the closed
`%Portal.Error{}` set, harnessed by tests (and without external services where a test double or in-memory adapter
serves), and shipped behind the same Definition-of-Done gates the specs use. Near-term rungs ship first; later rungs
are specified as abstracts and deferred until the shipped slice earns feedback.

## The three artifacts per feature (the triad)

Every rung `fN.M` is three files plus its entry in the chapter index.

| File | Answers | Key sections |
| --- | --- | --- |
| `fN.M.md` | what & why & done | Goal · Rationale (5W) · Scope (In/Out) · Deliverables · Invariants · Definition of Done |
| `fN.M.stories.md` | who wants what, and how we'll know | User stories (Connextra) · acceptance criteria (Given/When/Then) · INVEST + `encodes` invariant link · Priority/Size/Implements · Coverage line |
| `fN.M.llms.md` | how to build it, with proof gates | References · Requirements · Execution topology · Agent stories · Execution plan — first two stories · Comprehensive implementation prompt |

The `.md` is the contract. The `.stories.md` makes the contract concrete from the user's side. The `.llms.md` is the
agent-facing brief — an `llms.txt`-style document dense with the exact references, requirements, topology, and a
runnable implementation prompt.

## What a Claude agent story is

A **Claude agent story** is the agent-executable counterpart of a user story. Where a user story says *"As a learner I
want to browse courses so that I can choose one,"* an agent story says *how an agent makes that true* and *how the
agent proves it*. The agent brief bundles:

- **References** — the exact sources the agent reads first: framework docs (URLs), the upstream contract (the `Portal`
  facade and the `%Portal.Error{}` set), the relevant build-guide, and any prior spec it depends on. (`llms.txt`
  convention: links first, prose second.)
- **Requirements** — numbered, testable statements the implementation must satisfy, each traced back to a user story
  (`[US: …]`) and forward to an invariant or acceptance check.
- **Execution topology** — both the *runtime topology* (which processes, modules, and supervision relationships exist
  at run time and how a request flows through them) and the *task DAG* (the ordered dependency graph of build steps),
  plus the touched files.
- **Agent stories** — a bulleted list, each `FN.M-AS#` `[implements FN.M-US#]` with a **Directive** (what the agent
  does) and an **Acceptance gate** (the check that closes it).
- **Execution plan — first two stories** — a short numbered trace of the first two agent stories, to confirm the path
  is short and leaves no decision the spec has not already fixed.
- **A comprehensive implementation prompt** — the single brief an agent runs to implement the stories, in task order,
  ending with the verification gates. This prompt *is* the story implementation.

So: the user story is the intent; the agent story is the intent plus the references, requirements, topology, and the
prompt that realizes it and checks itself.

## Traceability — correct by definition

Every artifact uses stable ids so the chain from intent to proof is explicit:

```text
Deliverable (fN.M.md  · FN.M-D#)
   └─ realized by → User story (fN.M.stories.md · FN.M-US#)
        ├─ accepted by → Acceptance criteria (Given/When/Then on the story)
        └─ encodes     → Invariant (fN.M.md · FN.M-INV#)        (named on the story's INVEST line)
   └─ built by   → Agent story (fN.M.llms.md · FN.M-AS#)        [implements FN.M-US#]
        └─ governed by → Requirement (fN.M.llms.md · FN.M-R#)   [US: FN.M-US#]
             └─ proven by → Invariant (FN.M-INV#)  or  an acceptance test
```

Two closures make the chain checkable from the text alone: the stories file ends with a **Coverage line**
(`D#→US# · …`) mapping every Deliverable to the stories that realize it, and each story's **INVEST line** ends with
`encodes FN.M-INV#`, naming the invariants it exercises — so every invariant is reachable from a story.

**The completion rule.** A rung is done only when (a) every Deliverable maps to at least one User story, (b) every
User story's acceptance criteria pass, (c) every Requirement is satisfied, and (d) every Invariant holds under test.
"Correct by definition" means exactly this closure: there is no behavior in the increment that is not pinned by an
acceptance check or an invariant, and no gate that is merely asserted rather than run.

## Definitions

- **User story** — a short statement of value in the Connextra form *"As a `<role>`, I want `<capability>`, so that
  `<benefit>`,"* sized to the INVEST heuristics (Independent, Negotiable, Valuable, Estimable, Small, Testable). A
  story is a promise of value with a way to check it, not a task list.
- **Acceptance criteria** — the conditions that make a story demonstrably satisfied, written as Given/When/Then
  (Gherkin) scenarios so they read the same to product, QA, and an agent.
- **Claude agent story** — see above: the executable counterpart of a user story.
- **Invariant** — a property that must hold for every value the increment produces, enforced the functional way:
  encode it in the type/struct so illegal states cannot be built (*make illegal states unrepresentable*), parse
  untrusted input into that type once at the boundary (*parse, don't validate*), and pin the residual with a
  property-based test. This is the functional analogue of a design-by-contract invariant — established by construction
  and by `StreamData`, not by scattered runtime assertions.
- **Execution topology** — the runtime shape (processes, supervision, request flow) and the build-order graph (the
  task DAG) of the increment.
- **Milestone** — a group of rungs on the roadmap that together ship a coherent product step (e.g. *ship the catalog*,
  *make it live*, *ship to users*).
- **Definition of Done (DoD)** — the checklist that closes the spec: deliverables present, invariants tested,
  acceptance criteria green, platform runnable.
- **Correct by definition** — the completion rule above: completion is a closure over traced, executed checks, not a
  judgment call.

## The master invariant

> The web, bot, or any UI layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set. The
> domain core is framework-free and depends on nothing above it. No controller, LiveView, plug, template, or bot
> handler names `Portal.Engine`, a repo, or `GenServer.call`.

This single rule is what makes the ladders safe: every rung adds surface without reaching below the facade, so nothing
under the F5 boundary changes as F6 and F10 grow. Each chapter restates it in its own terms — for F6 the driving
adapter is the web (the only structural change to the F5 tree across the chapter is adding `PortalWeb.Endpoint`, then
`PubSub`/`Presence` as real-time needs them); for F10 it is the ex_gram bot; for F5 it is the functional-core /
imperative-shell split with the facade as the one public surface. The closed error set is
`:already_enrolled | :course_not_found | :lesson_locked | :invalid_progress`, extended only by an explicit, no-catch-all
mapping.

## Control flow & error handling

Specs use one FP-native control-flow discipline so agents implement errors the same way every time — railway-oriented:
a pipeline either reaches `:ok`/`{:ok, value}` or short-circuits to a typed `{:error, %Portal.Error{}}`.

| Approach | Use it for | Why |
| --- | --- | --- |
| `with` + tagged tuples | the default — sequential context/business steps that each return `{:ok, _} / {:error, _}` | linear, composable, pure, pattern-matchable; the Elixir form of railway-oriented programming |
| `Ecto.Multi` / `Repo.transaction` | any operation that writes more than one row or must be atomic | all-or-nothing; named steps; introspectable without running |
| changeset → `Portal.Error.from_changeset/1` | parsing untrusted input at a boundary (forms, params, Telegram `initData`) | parse-don't-validate: one typed result, or a field-level closed error |
| exceptions (`raise`, bang funcs) | truly exceptional faults and programmer errors only — *let it crash* under supervision | keeps the value channel clean; OTP restarts the process |

Avoid result-monad libraries unless `with` ergonomics genuinely break down, and never use exceptions for an expected
domain failure. In the event-sourced engine, the Decider keeps this clean: `decide/2` returns events only, and the
contract guards rejection at the boundary as tagged tuples (see [`pragmatic/decider-pattern.md`](pragmatic/decider-pattern.md)).
Full sourcing is in [References](#references).

## Quality gates — the mechanical checks

Every artifact passes these before it is presented; together they are what "A+ quality gates" means in practice. They
are cheap to run and are run, not asserted.

- **Voice.** No hype: the forbidden set is `revolutionary`, `blazing[ -]?fast`, `magical`, `simply`, `just`,
  `obviously`, `effortless` (case-insensitive). Plain, specific prose instead.
- **Structure.** A spec has exactly its six sections; the Rationale has exactly five bold bullets (Why/What/Who/When/
  Where); the DoD is checkboxes. A stories file has Connextra stories with Given/When/Then, an INVEST line ending in
  `encodes FN.M-INV#`, a Priority/Size/Implements line, and a closing Coverage line. An agent brief matches the triad
  section order, with agent stories as bullets and a numbered first-two-stories plan.
- **Traceability.** Every Deliverable appears in the Coverage line; every Requirement carries `[US: …]`; every agent
  story carries `[implements …]`; every invariant is named by at least one story's `encodes`.
- **Fences.** Every opening code fence has a matching close (an even number of fence markers per file), and fences
  are never nested at the same backtick length.
- **Links.** Every relative link resolves on disk; zero broken across the tree.
- **Format.** Writerside-friendly markdown — prose over heavy formatting, lists and tables only where they earn their
  place.

## The workflow

0. **Plan the chapter** (`<chapter>.roadmap.md`): the value ladder, the milestones, the near-term iterations, and the
   master invariant for the chapter.
1. **Author the spec** (`fN.M.md`): Goal, Rationale (5W), Scope, Deliverables (`D#`), Invariants (`INV#`), DoD.
2. **Derive the user stories** (`fN.M.stories.md`): one per distinct unit of value, each with acceptance criteria and
   an `encodes FN.M-INV#` line; map each Deliverable to ≥1 story; end with the Coverage line.
3. **Derive the agent stories** (`fN.M.llms.md`): References, Requirements (`R#`, traced to `US#`), Execution topology
   (runtime + task DAG + touched files), Agent stories (`AS#`, each implementing a `US#`), the first-two-stories plan,
   and the comprehensive implementation prompt.
4. **Run** the comprehensive prompt with a coding agent, executing agent stories in task order; the platform stays
   runnable after each.
5. **Verify** against the DoD and the quality gates: run acceptance criteria and invariant tests; confirm the
   traceability closure; sweep voice, fences, and links.
6. **Ship, demo, and review** the increment; the Operator returns feedback. Feedback edits the spec; then the next
   rung on the ladder starts.

## Templates

**`fN.M.md`**

```text
# FN.M · <feature name>
> <one- or two-sentence value statement>

## Goal
<the outcome this increment delivers>

## Rationale (5W)
- **Why**   — <the problem / motivation>
- **What**  — <the capability being added>
- **Who**   — <the roles who benefit>
- **When**  — <position in the value ladder / what it depends on>
- **Where** — <the layer, modules, and files touched; the boundary respected>

## Scope
- **In**  — <what this spec covers>
- **Out** — <what it defers, and to which later rung>

## Deliverables
- **FN.M-D1** — <concrete artifact>

## Invariants
- **FN.M-INV1** — <property that must always hold>

## Definition of Done
- [ ] <deliverables present>
- [ ] <invariants tested>
- [ ] <acceptance criteria green>
- [ ] <platform runnable / demoable>

Stories: ./fN.M.stories.md · Agent brief: ./fN.M.llms.md · Index: ./<chapter>.md · Approach: ../specs.approach.md
```

**`fN.M.stories.md`**

```text
# FN.M · user stories
> Who wants this, what they need, and how we will know it works.

## FN.M-US1 — <title>
As a <role>, I want <capability>, so that <benefit>.

Acceptance criteria
- Given <context>, when <action>, then <observable outcome>.

INVEST — <independence>; testable by <how>; encodes FN.M-INV#.
Priority: <must/should/could> · Size: <points> · Implements deliverables: FN.M-D#.

---
Coverage: D1→US# · D2→US# · …  Spec: fN.M.md · Agent brief: fN.M.llms.md.
```

**`fN.M.llms.md`**

```text
# FN.M · agent brief (llms)
> Implementation brief for an agent. References, traced requirements, the execution topology, and a paste-ready
> prompt. Pairs with the spec fN.M.md and the stories fN.M.stories.md.

## References
- <doc/url> — <why the agent needs it>.
- Upstream: the Portal facade + %Portal.Error{} (F5.8/F5.9), and any prior spec depended on.

## Requirements
- **FN.M-R1** — <testable statement> [US: FN.M-US#]

## Execution topology
Runtime: <processes / supervision / request flow>            — rendered as a fenced text block
Tasks:   <ordered task DAG; each step leaves the app compiling>  — rendered as a fenced text block
Touched files: <the files this rung creates or edits>.

## Agent stories
- **FN.M-AS1** [implements FN.M-US1] — Directive: <what the agent does>. Acceptance gate: <the check that closes it>.

## Execution plan — first two stories
1. **FN.M-AS1 — <title>.** <files, command, gate>.
2. **FN.M-AS2 — <title>.** <files, command, gate>.

## Comprehensive implementation prompt
<the single paste-into-an-agent brief that executes AS1..ASn in task order and ends with the verification gates;
 itself a fenced text block>
```

## References

**Stories, specifications, and acceptance**

- Mike Cohn, *User Stories Applied: For Agile Software Development* (Addison-Wesley, 2004) — the canonical treatment of
  user stories, splitting, and acceptance: <https://www.mountaingoatsoftware.com/books/user-stories-applied>.
- Bill Wake, *INVEST in Good Stories, and SMART Tasks* — the heuristics for well-formed stories:
  <https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/>.
- Connextra story template ("As a … I want … so that …"), Agile Alliance glossary:
  <https://www.agilealliance.org/glossary/user-story-template/>.
- Gherkin / Given-When-Then reference (Cucumber): <https://cucumber.io/docs/gherkin/reference/>.
- Dan North, *Introducing BDD*: <https://dannorth.net/introducing-bdd/>.
- Gojko Adzic, *Specification by Example* — examples as the shared, executable spec:
  <https://gojko.net/books/specification-by-example/>.

**Agile delivery & iteration (the roadmap layer)**

- Kent Beck, *Extreme Programming Explained* — small releases, incremental design, and continuous feedback, the spine
  of the Author/Operator loop: <https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/>.
- The Agile Manifesto and its principles — working software in short cycles, inspect-and-adapt:
  <https://agilemanifesto.org/principles.html>.
- Hunt & Thomas, *The Pragmatic Programmer* (tracer bullets, walking skeletons) — the value-ladder and thin-slice
  discipline: <https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/>.
- Humble & Farley, *Continuous Delivery* — keep every increment releasable; the deploy discipline behind F6.8:
  <https://continuousdelivery.com/>.

**Functional correctness — invariants, control flow, and tests**

- Scott Wlaschin, *Railway Oriented Programming* — compose `{:ok, _} | {:error, _}` steps that short-circuit; the model
  behind Elixir's `with`: <https://fsharpforfunandprofit.com/rop/>. Counterweight (do not overuse `Result`):
  <https://fsharpforfunandprofit.com/posts/against-railway-oriented-programming/>.
- Elixir `with` and tagged tuples — idiomatic happy-path composition and error short-circuiting:
  <https://hexdocs.pm/elixir/lists-and-tuples.html>.
- Alexis King, *Parse, don't validate* — turn untrusted input into a constrained type once, at the edge:
  <https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/>.
- Yaron Minsky, *Effective ML* (make illegal states unrepresentable):
  <https://vimeo.com/14313378>.
- Gary Bernhardt, *Boundaries* (functional core, imperative shell):
  <https://www.destroyallsoftware.com/talks/boundaries>.
- Property-based testing with `StreamData` — state an invariant, generate cases, shrink to a counterexample:
  <https://hexdocs.pm/stream_data/StreamData.html>.
- Elixir's set-theoretic type system — Castagna, Duboc & Valim, *The Design Principles of the Elixir Type System*:
  <https://arxiv.org/abs/2306.06391>.
- Lineage, not the backbone: design by contract, re-expressed here as types + boundary parsing + properties:
  <https://en.wikipedia.org/wiki/Design_by_contract> (applied in F5.4).
- The functional event-sourcing Decider used by the engine: [`pragmatic/decider-pattern.md`](pragmatic/decider-pattern.md).

**Agent and implementation workflow**

- `llms.txt` convention (links-first, machine-readable briefs): <https://llmstxt.org/>.
- Anthropic, *Claude Code best practices*: <https://www.anthropic.com/engineering/claude-code-best-practices>.
- Anthropic, *Building effective agents*: <https://www.anthropic.com/engineering/building-effective-agents>.

**The chapters and their plans**

- F5 engine — index [`pragmatic/pragmatic.md`](pragmatic/pragmatic.md), roadmap [`pragmatic/pragmatic.roadmap.md`](pragmatic/pragmatic.roadmap.md).
- F6 web — index [`phoenix/phoenix.md`](phoenix/phoenix.md), roadmap [`phoenix/phoenix.roadmap.md`](phoenix/phoenix.roadmap.md).
- F10 bot — roadmap [`bot/f10.roadmap.md`](bot/f10.roadmap.md).
- The upstream contract for every chapter is the `Portal` facade and the closed `%Portal.Error{}` set assembled in
  F5.8 / F5.9; the master invariant is what lets later chapters add surface without changing anything below it.

---

> Part of the jonnify toolkit. Branded id format: `TSK` + Base62(snowflake), e.g. `TSK0KHTOWnGLuC`.
> Markdown is the source; the roadmap plans, the specs define, and both are reviewed here before any implementation runs.
