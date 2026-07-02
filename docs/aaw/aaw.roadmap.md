# AAW — the framework roadmap

> The delivery plan for the framework scaffold and its first reverse-mode validation run. The roadmap plans;
> the documents it ships define. Index: [aaw.md](aaw.md).

## What this roadmap delivers

Two milestones: **M1 — the foundation** (the definition, the rules, the reverse playbook, each scaffolded by
its own spec triad — the framework eating its own dogfood), and **M2 — the validation run** (the reverse
playbook executed against the production `echo/apps/echomq` library, producing the retrospective spec chapter
at `docs/echomq/specs/core/` and a hardening pass that maps every invariant to a running check).

**Starts from** the practice as shipped and its scattered rules. **Ends with** the framework codified, proven
in reverse against production code, and corrected by its own run's findings.

## Architecture decisions

- **A dedicated `docs/aaw/` home.** Framework artifacts live in their own top-level tree, not under
  `docs/agile-agent-workflow/` — course-authoring agents search the course tree for content to write, and
  framework documents there would be ambiguous search hits. Reversible seam: everything here is links; the
  tree can be relocated by moving files and re-resolving relative paths.
- **One game, two formations — not two frameworks.** The lead-team (code) and the fan-out (content/specs)
  share the definition, the loop, the gates, and the taxonomy; they differ only in formation rules
  ([aaw.rules.md](aaw.rules.md)). A reverse run composes both.
- **Link, never copy.** The forward contract remains [specs.approach.md](../elixir/specs/specs.approach.md)
  — the one authority for templates, traceability, and completion. The framework documents reference it. (The
  byte-identical copy of that contract found under `docs/echomq/specs/reference/` predates this rule and is
  left untouched; new chapters link.)
- **Validation-first proof.** The framework ships with an executed run (M2), not as theory: AAW4's
  deliverable is the proof that the reverse capability works on real production code.

## The master invariant

Restated from [aaw.md](aaw.md): one authority per fact; the framework describes the practice as shipped;
where a framework document and the evidenced practice disagree, the practice wins and the document is
corrected; no framework document restates a contract that lives elsewhere.

## How this roadmap runs

The Author/Operator loop of [aaw.framework.md](aaw.framework.md), applied to documents: the Operator fixed
the scope (the placement decision, the hardening scope, the ladder depth, the course-tree calibration); the
orchestrator senior-authors the design-bearing documents and the exemplar triad; fan-out authors apply the
locked templates to the remaining triads; domain experts verify groundings adversarially; the lead-team
executes the hardening; findings fold back. **Thin but robust, for documents:** each document is useful alone,
passes the gates, and links resolve on disk at every step.

## The delivery arc

| Rung | Ships (the slice) | Demo | Harness | Feedback asked |
| --- | --- | --- | --- | --- |
| AAW1 | `aaw.framework.md` + the toc:9 reframe + the Scrum Guide registry entry + the `aaw1` triad | read the definition end-to-end; the course tree acknowledges the framework | gate sweep (structure · voice · fences · traceability · links) | does the definition match the practice you run? |
| AAW2 | `aaw.rules.md` + the `aaw2` triad | every rule cites its defining source; the LAWS quoted verbatim | gate sweep + spot-check three rules against their sources | which rule is mis-stated or missing? |
| AAW3 | `aaw.reverse.md` + the `aaw3` triad | the seven-stage workflow + the re-keyed triad template, readable as a runbook | gate sweep + the template parses against the forward structure gate | is the hardening loop's Operator gate placed right? |
| AAW4 | the validation run: `docs/echomq/specs/core/` (index + roadmap + progress + `c1`–`c7`) + the hardening rung(s) + the fold-back | the core chapter on disk; the invariant→check table; lead-team verdicts | the four reverse gates + expert convergence + the lead-team's own gates (compile, scoped tests, verdict) | accept the deltas and the hardening commits? |

M1 = AAW1–AAW3 · M2 = AAW4.

## Seams & open decisions

- **LAW-2 revision** — four authoring charters now pin `fable` and lead-team
  peers spawn as general-purpose with charter-via-prompt. Recorded as a dated divergence note in
  [aaw.rules.md](aaw.rules.md); the rewording is the Operator's.
- **The course-home Sources block** (`html/agile-agent-workflow/index.html`) is the registry's canonical
  page copy; adding the Scrum Guide there is a course-page edit (cms gates) deferred out of this scaffold.
- **A forward cross-pointer from `specs.approach.md`** to this directory is deferred — do-no-harm on a
  proven contract; the Operator may add it later.
- **Future reverse runs** — `portal`, `echo_data`, `echo_bot` are candidate targets for the same playbook;
  out of scope here.
- **A course chapter teaching the framework documents** (the course currently teaches the workflow, not this
  codification) — deferred to the course roadmap.
- **`portal.status.md` unfreezing** — a known lagging dashboard, owned by the Portal program, untouched here.

## Conventions

Ids and statuses per [aaw.md](aaw.md). Gates per [specs.approach.md](../elixir/specs/specs.approach.md) plus,
for AAW4's output, the four reverse gates of [aaw.reverse.md](aaw.reverse.md). Voice per
[aaw.rules.md](aaw.rules.md). Fan-out authors edit only their assigned triad files; the orchestrator owns this
file, the index, and all shared relinks. No agent runs git; the Operator commits batches out-of-band, except
the lead-team hardening rungs, which close with one Director pathspec commit each.

---

Index: [aaw.md](aaw.md) · Definition: [aaw.framework.md](aaw.framework.md) ·
Rules: [aaw.rules.md](aaw.rules.md) · Reverse: [aaw.reverse.md](aaw.reverse.md)
