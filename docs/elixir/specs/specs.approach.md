# Specs approach — pragmatic, story-led, correct by definition

> The pattern every F6 feature spec follows. It turns a chapter of the Portal into a sequence of value-adding
> increments, each one specified, told as user stories, handed to a coding agent as agent stories, and accepted only
> when its invariants and acceptance criteria hold. The aim is a build process that is pragmatic (each step ships
> value and stays runnable), invariant (the rules that must always hold are written down and checked), testable
> (every behavior is pinned by an example or a property), and correct by definition (nothing is "done" until its
> gates pass).

This file is the contract for the spec system itself. Chapter indexes (e.g. `phoenix/phoenix.md`) and feature specs
(`phoenix/f6.1.md`, …) all conform to it.

## Why this exists

The build guides under `build-guide/` teach a chapter and hand an agent copy-paste prompts. That works, but the
prompts describe *steps*, not *value*, and they carry no explicit notion of who the work is for or what must remain
true afterwards. This spec system adds three things on top:

- **Value framing.** Each spec is a feature that leaves the Portal demonstrably better and still running — the
  pragmatic "add value in thin vertical slices" discipline from F5, applied to the Phoenix layer.
- **Stories.** Each feature is expressed as user stories (who wants what, and how we will know it works) and as
  *agent stories* (the same intent, made executable by a coding agent).
- **Provable completion.** Each feature declares invariants and a Definition of Done, and every requirement traces to
  an acceptance check or an invariant — so "complete" is a verifiable claim, not an opinion.

## The unit of delivery

The unit is a **feature spec**: one increment, identified `F6.N`, that

1. delivers a capability a named role can use,
2. keeps everything below the `Portal` facade unchanged (the F5 boundary), and
3. leaves the platform runnable and demonstrable at the end.

A spec is small enough to build and verify in one pass and large enough to be worth a demo. Specs are ordered as a
*value ladder*: each rung depends only on rungs below it.

## The three artifacts per feature

Every feature `F6.N` is three files plus its entry in the chapter index.

| File | Audience | Answers | Key sections |
| --- | --- | --- | --- |
| `f6.N.md` | humans (author, reviewer) | what & why & done | Goal · Rationale (5W) · Scope · Deliverables · Invariants · Definition of Done |
| `f6.N.stories.md` | humans (product, QA) | who wants what, and how we'll know | User stories (Connextra) · acceptance criteria (Given/When/Then) · INVEST notes · priority & size |
| `f6.N.llms.md` | a coding agent (e.g. Claude Code) | how to build it, with proof gates | References · Requirements · Execution topology · Agent stories · Comprehensive implementation prompt |

The `.md` is the contract. The `.stories.md` makes the contract concrete from the user's side. The `.llms.md` is the
agent-facing brief — an `llms.txt`-style document dense with the exact references, requirements, topology, and a
runnable implementation prompt.

## What a Claude agent story is

A **Claude agent story** is the agent-executable counterpart of a user story. Where a user story says *"As a learner I
want to browse courses so that I can choose one,"* an agent story says *how an agent makes that true* and *how the
agent proves it*. An agent story is an `llms`-style brief that bundles:

- **References** — the exact sources the agent must read first: framework docs (URLs), the upstream contract (the
  `Portal` facade and `%Portal.Error{}` set), the relevant build-guide, and any prior spec it depends on. (`llms.txt`
  convention: links first, prose second.)
- **Requirements** — the numbered, testable statements the implementation must satisfy, each traced back to a user
  story and forward to an invariant or acceptance check.
- **Execution topology** — both the *runtime topology* (which processes, modules, and supervision relationships exist
  at run time and how a request flows through them) and the *task topology* (the ordered dependency graph of build
  steps).
- **A comprehensive implementation prompt** — the single brief an agent runs to implement the stories, in topology
  order, ending with the verification gates. This prompt *is* the story implementation.

So: the user story is the intent; the agent story is the intent plus the references, requirements, topology, and the
prompt that realizes it and checks itself.

## Traceability — correct by definition

Every artifact uses stable ids so the chain from intent to proof is explicit:

```text
Deliverable (f6.N.md  · F6.N-D#)
   └─ realized by → User story (f6.N.stories.md · F6.N-US#)
        └─ accepted by → Acceptance criteria (Given/When/Then on the story)
   └─ built by   → Agent story (f6.N.llms.md · F6.N-AS#)   [implements F6.N-US#]
        └─ governed by → Requirement (f6.N.llms.md · F6.N-R#)
             └─ proven by → Invariant (f6.N.md · F6.N-INV#)  or  an acceptance test
```

**The completion rule.** A feature is done only when (a) every Deliverable maps to at least one User story, (b) every
User story's acceptance criteria pass, (c) every Requirement is satisfied, and (d) every Invariant holds under test.
"Correct by definition" means exactly this closure: there is no behavior in the increment that is not pinned by an
acceptance check or an invariant, and no gate that is merely asserted rather than run.

## Definitions

- **User story** — a short statement of value in the Connextra form *"As a `<role>`, I want `<capability>`, so that
  `<benefit>`,"* sized to the INVEST heuristics (Independent, Negotiable, Valuable, Estimable, Small, Testable). A
  story is not a task list; it is a promise of value with a way to check it.
- **Acceptance criteria** — the conditions that make a story demonstrably satisfied, written as Given/When/Then
  (Gherkin) scenarios so they read the same to product, QA, and an agent.
- **Claude agent story** — see above: the executable counterpart of a user story.
- **Invariant** — a property that must hold before and after every operation in the increment, in the spirit of
  design by contract (preconditions, postconditions, invariants). Invariants are the rules a refactor may never break;
  in this project the master invariant is *the web layer calls only the `Portal` facade and renders only the closed
  `%Portal.Error{}` set.*
- **Execution topology** — the runtime shape (processes, supervision, request flow) and the build-order graph (task
  dependencies) of the increment.
- **Definition of Done (DoD)** — the checklist that closes the spec: deliverables present, invariants tested,
  acceptance criteria green, platform runnable.
- **Correct by definition** — the completion rule above: completion is a closure over traced, executed checks, not a
  judgment call.

## The workflow

1. **Author the spec** (`f6.N.md`): Goal, Rationale (5W), Scope, Deliverables (`D#`), Invariants (`INV#`), DoD.
2. **Derive the user stories** (`f6.N.stories.md`): one per distinct unit of value, each with acceptance criteria;
   map each Deliverable to ≥1 story.
3. **Derive the agent stories** (`f6.N.llms.md`): References, Requirements (`R#`, traced to `US#`), Execution
   topology, Agent stories (`AS#`, each implementing a `US#`), and the comprehensive implementation prompt.
4. **Run** the comprehensive prompt with a coding agent, executing agent stories in task-topology order; the platform
   stays runnable after each.
5. **Verify** against the DoD: run acceptance criteria and invariant tests; confirm the traceability closure.
6. **Mark done** only when the completion rule holds. Then the next rung on the value ladder may start.

## Templates

**`f6.N.md`**

```text
# F6.N · <feature name>
> <one-sentence value statement>

## Goal
<the outcome this increment delivers>

## Rationale (5W)
Why   — <the problem / motivation>
What  — <the capability being added>
Who   — <the roles who benefit>
When  — <position in the value ladder / triggering condition>
Where — <the layer, modules, and files touched; the boundary respected>

## Scope
In:  <what this spec covers>
Out: <what it deliberately defers, and to which later spec>

## Deliverables
- F6.N-D1 — <concrete artifact>
- F6.N-D2 — <concrete artifact>

## Invariants
- F6.N-INV1 — <property that must always hold>

## Definition of Done
- [ ] <deliverables present>
- [ ] <invariants tested>
- [ ] <acceptance criteria green>
- [ ] <platform runnable / demoable>

Stories: ./f6.N.stories.md · Agent brief: ./f6.N.llms.md
```

**`f6.N.stories.md`**

```text
# F6.N · user stories

## F6.N-US1 — <title>
As a <role>, I want <capability>, so that <benefit>.

Acceptance criteria
- Given <context>, when <action>, then <observable outcome>.

INVEST — <one line on independence/size/testability>
Priority: <must/should/could> · Size: <points>
Implements deliverables: F6.N-D#
```

**`f6.N.llms.md`**

```text
# F6.N — <feature> · agent brief (llms)
> <one line>

## References
- <doc/url> — <why the agent needs it>
- Upstream contract: Portal facade + %Portal.Error{} (F5.08)

## Requirements
- F6.N-R1 — <testable statement> [US: F6.N-US#]

## Execution topology
Runtime: <processes / supervision / request flow>
Tasks:   <ordered dependency graph of build steps>

## Agent stories
### F6.N-AS1 — <title> [implements F6.N-US1]
Directive: <what the agent does>
Acceptance gate: <the check that closes it>

## Comprehensive implementation prompt
<the single paste-into-an-agent brief that executes AS1..ASn in topology
 order and ends with the verification gates>
```

## References

**Stories, specifications, and acceptance**

- Mike Cohn, *User Stories Applied: For Agile Software Development* (Addison-Wesley, 2004) — the canonical treatment of
  user stories, splitting, and acceptance. Publisher/author page: <https://www.mountaingoatsoftware.com/books/user-stories-applied>.
- Bill Wake, *INVEST in Good Stories, and SMART Tasks* — the heuristics for well-formed stories:
  <https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/>.
- Connextra story template ("As a … I want … so that …"), as documented by the Agile Alliance glossary:
  <https://www.agilealliance.org/glossary/user-story-template/>.
- Gherkin / Given-When-Then reference (Cucumber): <https://cucumber.io/docs/gherkin/reference/>.
- Dan North, *Introducing BDD*: <https://dannorth.net/introducing-bdd/>.
- Gojko Adzic, *Specification by Example* — examples as the shared, executable spec:
  <https://gojko.net/books/specification-by-example/>.

**Invariants, contracts, and tests**

- Bertrand Meyer, design by contract (preconditions, postconditions, invariants) — overview:
  <https://en.wikipedia.org/wiki/Design_by_contract>. Applied in this course in F5.04.
- Property-based testing with `StreamData` (state an invariant, generate cases):
  <https://hexdocs.pm/stream_data/StreamData.html>.
- Hunt & Thomas, *The Pragmatic Programmer* (tracer bullets, walking skeletons) — the value-ladder discipline:
  <https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/>.

**Agent and implementation workflow**

- `llms.txt` convention (links-first, machine-readable briefs): <https://llmstxt.org/>.
- Anthropic, *Claude Code best practices*: <https://www.anthropic.com/engineering/claude-code-best-practices>.
- Anthropic, *Building effective agents*: <https://www.anthropic.com/engineering/building-effective-agents>.

**Implementation surface (the Portal on Phoenix)**

- Phoenix: <https://hexdocs.pm/phoenix/overview.html>. Phoenix LiveView: <https://hexdocs.pm/phoenix_live_view>.
- Upstream contract for every F6 spec: the `Portal` facade and the closed `%Portal.Error{}` set assembled in F5.08 /
  F5.09. The master invariant — *the web layer calls only `Portal` and renders only `%Portal.Error{}`* — is what lets
  F6 add a web platform without changing anything below the facade.

---

> Part of the jonnify toolkit. Branded id format: `TSK` + Base62(snowflake), e.g. `TSK0KHTOWnGLuC`.
> Markdown is the source; specs are reviewed here before any implementation runs.
