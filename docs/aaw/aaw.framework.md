# AAW — the framework definition

> The definition of record for **AAW (the Agile Agent Workflow)**: a way of working, codified. One human
> **Operator** who supplies intent, decomposition, and acceptance, paired with Claude agents that supply fast,
> well-specified production, shipping software in thin, provable increments under executable gates. This
> document defines the framework — its theory, values, roles, layers, artifacts, and loop — the way the Scrum
> Guide defines Scrum: rules earned by practice, written down second. The normative rules live in
> [aaw.rules.md](aaw.rules.md); the reverse-mode playbook in [aaw.reverse.md](aaw.reverse.md).

## Purpose of this document

AAW shipped working software before it had a name: the Portal program (`docs/elixir/specs/`), the course trees,
and their agent pipelines all run the same workflow. The course at `/course/agile-agent-workflow`
**teaches** that workflow; this document **defines** it, so that every brief, charter, and chapter can reference
one model instead of restating it. The anatomy is patterned on the Scrum Guide — definition, theory, values,
team, events, artifacts — re-grounded in this repository's shipped practice. Where this definition and the
evidenced practice disagree, the practice wins and the definition is corrected.

## Definition of AAW

AAW is a way of working in which a human Operator and Claude agents build software together over **rungs** —
thin vertical increments, each small enough to build and verify in one pass and large enough to be worth a
demo. Each rung is planned on a roadmap, defined by a spec, told as user stories, built by an agent from a
brief, and accepted only when its invariants and acceptance criteria hold under checks that actually run.

AAW is not a rigid methodology. The rules describe a practice that shipped first and was codified afterward;
they constrain *how work is proven*, not *what may be attempted*. Anything not forbidden by a fence or a gate
is open.

## Theory

AAW is empirical: knowledge comes from shipped increments, and decisions are made on evidence — a running
demo, a green gate, a reconciled spec — never on an unverified report. Three pillars carry that empiricism.

- **Transparency.** Every working artifact is plain text in the repository: roadmaps, specs, stories, briefs,
  progress records, retrospectives, audit ledgers. A claim that cannot be inspected in the tree is not yet a
  fact; an agent's report becomes evidence only when its artifact survives in the working tree.
- **Inspection.** Gates are run, not asserted. Each increment is demoed against its stories; a verifier
  re-runs the gates independently and adversarially (and audits its own harness); a reconcile pass diffs the
  spec against the code each rung, in whichever direction the mode dictates.
- **Adaptation.** Feedback edits the spec — never the code directly, never a derived artifact on its own.
  Process feedback edits the agent definitions (mentoring) and the retrospective. The roadmap re-plans freely,
  because it defines no behaviour.

## Values

Five values, each earned by a shipped rung rather than declared in advance.

- **Thin but robust.** A rung is a narrow vertical slice built to production quality — supervised,
  contract-guarded, harnessed, gated. Thin is shape; flimsy is quality; only robustness makes a thin slice
  shippable.
- **Grounded.** No invention: every public call cites its source, every referenced surface exists, every
  arity is verified in the tree. A brief carries only verified facts, and the brief itself is not exempt.
- **One authority.** Every fact has exactly one defining document; every other mention links to it.
  Duplication is a drift surface an agent creates for free and a human reconciles by hand.
- **Do no harm.** Prefer the smallest, deterministic, reversible change; never "fix" a working surface in
  passing; retain what works.
- **Judgment at the ends, throughput in the middle.** The human decides what matters and whether it was met;
  the agents produce. Run alone, each fails — an Operator without agents ships nothing, agents without an
  Operator ship the wrong thing, confidently.

## The Operator-Agent model

The team is one human and a set of Claude agents in named roles, self-managing within fences (the fences are
rules — see [aaw.rules.md](aaw.rules.md)).

- **The Operator (human).** The source of intent, decomposition, judgment, and acceptance. Sharpens the next
  rung, reviews each spec and each shipped increment, makes every architecture / contract / dependency
  decision, and gives the go or no-go. Writes no code; the Operator's scarce attention goes to deciding what
  matters and whether it was met.
- **The Director (orchestrating agent).** Runs the work between the Operator's decisions: designs ladders and
  briefs, spawns and gates the specialized agents, verifies adversarially, ratifies results, and — in the
  lead-team formation — makes the rung's commit. The Director coordinates; once a team is spawned it does not
  implement, grade its own work, or decide a fork the Operator owns.
- **The specialized agents.** The production roles, each with a charter: a **spec-steward** reconciles the
  spec against reality and authors the build brief; an **implementor** builds and hardens from that brief and
  nothing else; a **verifier** re-runs the gates, reconciles the spec to what shipped, documents the process,
  and mentors the other charters; **authors** write course pages or spec triads from fixed designs in
  parallel waves; **researchers** survey read-only and return verified inventories. An agent surfaces forks;
  it never decides them.

The pairing claim, from the course's canonical statement of the loop: the human's judgment sits at the start
and end of every rung, the agent's throughput in the middle, and paired over thin provable rungs they
compound ([the Author/Operator loop](../agile-agent-workflow/content/what/author-operator-loop.md)).

## The two-layer model

Work is organized in two layers that change at different rates and answer different questions
([the two-layer model](../agile-agent-workflow/content/what/two-layer-model.md)).

- **The roadmap layer** answers *how we deliver*: milestones, iterations, the order of rungs. It is re-planned
  freely and defines no behaviour.
- **The spec layer** answers *what we build and how we know it is right*: the spec, its user stories, and the
  agent brief — definition and proof, per rung.

Beneath both sits the subject of the work — a framework-free domain core behind one facade (forward mode), or
an existing production codebase (reverse mode). Which layer is canonical depends on direction: forward, the
spec is the single source of truth and only feedback edits it; reverse, the code is canonical for as-built
surface facts and the spec is derived from and reconciled to it (see
[The two directions](#the-two-directions)).

## The four artifacts and their commitments

Every rung is carried by four plain-text artifacts; each answers exactly one question and carries one
commitment — the promise that makes it inspectable
([the four artifacts](../agile-agent-workflow/content/what/four-artifacts.md)).

| Artifact | Answers | Commitment it carries |
| --- | --- | --- |
| `roadmap.md` | what ships, and in what order | the master invariant and the milestone arc — every rung holds the boundary and lands in its planned slice |
| spec (`<rung>.md`) | what we build and how we know it is right | the invariants and the Definition of Done — completion is a closure over traced, executed checks |
| user stories (`<rung>.stories.md`) | what the user gets | the acceptance criteria (Given/When/Then) and the Coverage line — every deliverable is realized by a story a person can sign off |
| agent brief (`<rung>.llms.md`) | how the agent builds it | traced requirements and a prompt that ends in its own verification gates |

Three of the four move together as the **triad** — the spec is the contract, the stories are how a person
accepts it, the brief is how an agent builds it; stories and brief are derived from the spec, so they cannot
silently disagree with it. The roadmap sits outside the triad and decides which rung the triad is for.

Around the four, the practice keeps named instruments: the chapter **index** (the map of a ladder), the
**prompt runbook** (`<rung>.prompt.md`, the Director's orchestration brief), the **progress records** (a
dashboard that reports state, and a build narrative that records how a chapter was actually built), the
**operator guide** (`*.operator.md`, the human's field manual), and the **retrospective**. For a cross-cutting body that spans many rungs (a command catalogue, a knowledge base), the practice adds the **Epic / corpus** instrument: a thin catalogue index (`<epic>.md`) + per-feature slices under a cross-reference grammar — the one-authority and thin-but-robust values applied to the knowledge layer; the corpus is git-controlled and Director-owned, first proven in the emq program (`emq.epic.0`). Their rules live in
[aaw.rules.md](aaw.rules.md); their templates live in the contract they conform to
([specs.approach.md](../elixir/specs/specs.approach.md)).

## The Author/Agent loop

One rung runs as one turn of a six-stage loop between the two sides — the framework's only event cycle, and
the unit of inspection and adaptation. The stages and their owners, verbatim from the course canon:

1. **sharpen** — state intent · agree the spec — *Operator*
2. **build** — implement from spec + brief — *agents*
3. **ship** — thin but robust, behind the boundary — *agents*
4. **demo** — run it against the stories — *Operator*
5. **review** — does it meet acceptance? — *Operator*
6. **feedback** — capture what is missing — *Operator*

The adapt arc closes the loop: **feedback edits the spec**, and the next turn starts from one agreed truth.
In Scrum terms: the rung is the sprint; sharpening is planning; the demo and review are the sprint review;
the per-rung retrospective note replaces the retrospective meeting; and the reconcile pass — run before a
build against the upstream code, and after a build against what shipped — is the artifact-truth event Scrum
never needed, because Scrum's builders did not generate code from the spec. The loop runs identically in both
formations (the lead-team for code, the fan-out for content and specs — defined in
[aaw.rules.md](aaw.rules.md)).

## The two directions

- **Forward — spec → code.** The default for new capability. The spec is canonical; the build cites it line
  by line; the reconcile pass checks the as-built result against the spec's promises. The binding contract for
  forward work — the templates, the traceability chain, the completion rule — is
  [specs.approach.md](../elixir/specs/specs.approach.md), referenced from here rather than restated.
- **Reverse — code → spec.** For production code that has no spec. The code is canonical for surface facts;
  the roadmap and specifications are derived from the tree, every cited surface verified at its source; then
  each invariant is mapped to a running check and the gaps are hardened by the lead-team until the invariants
  are met. The playbook is [aaw.reverse.md](aaw.reverse.md).

A divergence between intent and either artifact is never silently synced in either direction — it is recorded
as a delta and surfaced to the Operator (the delta taxonomy is defined in [aaw.rules.md](aaw.rules.md)).

## References

- Schwaber, K. & Sutherland, J., *The Scrum Guide* — the rulebook anatomy this definition is patterned on:
  <https://scrumguides.org/>.
- The Agile Manifesto and principles — working software in short cycles, inspect-and-adapt:
  <https://agilemanifesto.org/principles.html>.
- Hunt, A. & Thomas, D., *The Pragmatic Programmer* — tracer bullets, thin slices:
  <https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/>.
- Beck, K., *Extreme Programming Explained* — small releases and the feedback loop:
  <https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/>.
- Adzic, G., *Specification by Example* — the living, executable single source of truth:
  <https://gojko.net/books/specification-by-example/>.
- Cohn, M., *User Stories Applied* — stories and acceptance:
  <https://www.mountaingoatsoftware.com/books/user-stories-applied>.
- The `llms.txt` convention — the agent brief's lineage: <https://llmstxt.org/>.
- Anthropic, *Building effective agents* —
  <https://www.anthropic.com/engineering/building-effective-agents>.
- The course canon this definition is grounded in:
  [the two-layer model](../agile-agent-workflow/content/what/two-layer-model.md) ·
  [the four artifacts](../agile-agent-workflow/content/what/four-artifacts.md) ·
  [the Author/Operator loop](../agile-agent-workflow/content/what/author-operator-loop.md).
- The forward contract: [specs.approach.md](../elixir/specs/specs.approach.md).

---

Index: [aaw.md](aaw.md) · Rules: [aaw.rules.md](aaw.rules.md) · Reverse: [aaw.reverse.md](aaw.reverse.md) ·
Roadmap: [aaw.roadmap.md](aaw.roadmap.md)
