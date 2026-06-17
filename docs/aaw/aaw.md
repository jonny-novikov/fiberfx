# AAW — the framework · index

> The home of the **AAW framework artifacts**: the definition, the rules, the reverse playbook, and the spec
> triads that scaffold them. The course at `/course/agile-agent-workflow` (source tree
> `docs/agile-agent-workflow/`) **teaches** the workflow; this directory **defines and governs** it. The two
> trees are deliberately separate so course-authoring agents searching the course tree for content never
> collide with framework artifacts.

## The value ladder

| Rung | Feature | Value it adds | Grounding                                                                                                                                                 | Status |
| --- | --- | --- |-----------------------------------------------------------------------------------------------------------------------------------------------------------| --- |
| **AAW1** | [The framework definition](aaw.framework.md) | one shared model — Operator-Agent roles, the two layers, the four artifacts, the Author/Agent loop — every brief and charter can reference instead of restate | the A0 course canon + the shipped Portal/course practice                                                                                                  | built |
| **AAW2** | [The Rules of the Game](aaw.rules.md) | the normative layer — fences, formations, cadence rules, the LAWS, the gates, the delta taxonomy — quoted from the sources of record | `.claude/commands/x.md`, the agent charters, `reconcile.md`, the operator guides, the retrospectives                                                      | built |
| **AAW3** | [The reverse playbook](aaw.reverse.md) | the code→spec capability: derive roadmap + specs from a production tree, verify groundings convergently, harden invariants to running checks | the reconcile post-build direction + the redlock "code wins" precedent                                                                                    | built |
| **AAW4** | The validation run | the framework executed once in reverse against production code — proof, not theory | `echo/apps/echo_mq` → [design, roadmap, features, rungs](../echo_mq/specs/emq*.md) and [the full set of specs required to ship](../echo_mq/specs/emq*.md) | built |

Each rung depends only on the rungs above it in this table; the ladder leaves the framework usable after
every rung.

## The master invariant

> One authority per fact: every rule, template, and definition has exactly one defining document, and every
> other mention links to it. The framework describes the practice **as shipped** — where a framework document
> and the evidenced practice disagree, the practice wins and the document is corrected. No framework document
> restates a contract that lives elsewhere.

This is the DRY discipline of [aaw.rules.md](aaw.rules.md) applied to the framework itself: the forward
contract stays in [specs.approach.md](../elixir/specs/specs.approach.md) (linked, never copied); the LAWS stay
in their command sources (quoted, with citation); the course canon stays in the course tree.

## Start and end handoff

**Starts from:** a practice already shipping — the Portal spec chapters, the course pipelines, the lead-team
and fan-out formations, the reconcile machinery — with its rules scattered across commands, charters, operator
guides, and retrospectives.

**Ends with:** the rules codified in one place, a reverse-mode capability defined and proven by execution
against `echo/apps/echomq`, and a fold-back loop that keeps the framework corrected by each run's findings.

## The rungs

- **AAW1 — the framework definition.** [aaw.framework.md](aaw.framework.md): purpose, definition, theory
  (three pillars), values, the Operator-Agent model, the two-layer model, the four artifacts and their
  commitments, the Author/Agent loop, the two directions. Triad: [aaw1.md](aaw1.md) ·
  [aaw1.stories.md](aaw1.stories.md) · [aaw1.llms.md](aaw1.llms.md).
- **AAW2 — The Rules of the Game.** [aaw.rules.md](aaw.rules.md): roles & fences, the two formations, the
  cadence rules, the LAWS (with the dated LAW-2 divergence note), the gates, the delta taxonomy and
  direction-dependent canonicality, feedback/mentoring/retrospective, decisions. Triad: [aaw2.md](aaw2.md) ·
  [aaw2.stories.md](aaw2.stories.md) · [aaw2.llms.md](aaw2.llms.md).
- **AAW3 — the reverse playbook.** [aaw.reverse.md](aaw.reverse.md): when reverse mode applies and what
  inverts, the seven-stage workflow, the re-keyed triad semantics, the four added gates, the compact
  template. Triad: [aaw3.md](aaw3.md) · [aaw3.stories.md](aaw3.stories.md) · [aaw3.llms.md](aaw3.llms.md).
- **AAW4 — the validation run (EXECUTED 2026-06-10).** The reverse EchoMQ playbook ran end-to-end against
  `echo/apps/echomq`: `echo/apps/echo_mq` → [design, roadmap, features, rungs](../echo_mq/specs/emq*.md) and [the full set of specs required to ship](../echo_mq/specs/emq*.md), groundings
  verified convergently by two independent domain experts (zero INVENTED surfaces; one STALE caught and
  re-scoped), sixteen deltas recorded against the survey bank and the code, and the H1 lead-team hardening
  rung closed **BUILD-GRADE** (commit `750f7789`: a plain `mix test` terminates for the first time; seven
  new invariant tests, mutant-kill verified; four doc/type truths; the BANK-9 warn-log; EVALSHA self-heal in
  the scheduler). Findings folded back into [the rules](aaw.rules.md) and
  [the reverse playbook](aaw.reverse.md). Triad: [aaw4.md](aaw4.md) · [aaw4.stories.md](aaw4.stories.md) ·
  [aaw4.llms.md](aaw4.llms.md).

## Conventions

Rung ids `AAW<N>` with artifact ids `AAW<N>-D# / -INV# / -US# / -R# / -AS#`; triad files `aaw<n>.{md,stories.md,llms.md}`;
statuses `planned → specced → built` (AAW4: `in progress → built` when the run completes). Quality gates per
[specs.approach.md](../elixir/specs/specs.approach.md); voice per [aaw.rules.md](aaw.rules.md). This directory
carries no separate progress dashboard — the ladder table above is the status surface.

---

Definition: [aaw.framework.md](aaw.framework.md) · Rules: [aaw.rules.md](aaw.rules.md) ·
Reverse: [aaw.reverse.md](aaw.reverse.md) · Roadmap: [aaw.roadmap.md](aaw.roadmap.md) ·
Forward contract: [specs.approach.md](../elixir/specs/specs.approach.md)
