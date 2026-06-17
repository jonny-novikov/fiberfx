# AAW2 · The Rules of the Game
> One document codifies the normative layer of AAW — the fences, the two formations, the cadence rules, the
> LAWS, the gates, and the delta taxonomy — every rule earned by a shipped rung and cited to where it is defined.

## Goal
`aaw.rules.md` exists as the normative document of record for AAW: roles and their fences, the two formations
and the cadence rules, the LAWS quoted from their sources, the gates, and the delta taxonomy with its verdict —
each rule traceable to a defining source or the rung that earned it, none aspirational.

## Rationale (5W)
- **Why**   — the workflow's rules are scattered across command files, agent charters, the reconcile spec, the
  operator guides, and the retrospectives; each restatement is a drift surface, and a brief that re-owns a fence
  or a law forks from its source the moment the source changes.
- **What**  — the normative document: the roles-and-fences table with the guardrail rule, the two formations
  and the cadence rules, the LAWS (with the dated LAW-2 divergence note), the gates and the delta taxonomy with
  direction-dependent canonicality and the BUILD-GRADE/BLOCKED verdict, plus the feedback, mentoring,
  retrospective, and decisions rules.
- **Who**   — the Director (fences and stage gates pinned so a spawn prompt carries only the rung delta), the
  Operator (decision rights and the LAWS in one referenceable place), the verifier and peers (the taxonomy and
  verdict semantics stable across rungs), every charter and brief (one normative authority to reference).
- **When**  — the second rung of the framework ladder; it depends on the definition (AAW1) and is referenced by
  the reverse playbook (AAW3) and the validation run (AAW4).
- **Where** — `docs/aaw/aaw.rules.md`; the rules cite tool-configuration sources of record in code form
  (`.claude/commands/x.md`, `.claude/commands/reconcile.md`, the `.claude/agents/*.md` charters) and the operator
  guides under `docs/elixir/specs/phoenix/`; it links only documents, restates no contract that lives elsewhere.

## Scope
- **In**  — the triad for the already-written rules document: its roles-and-fences table and guardrail rule, the
  two formations and the cadence rules, the LAWS, the gates and the delta taxonomy with the verdict, and the
  feedback/mentoring/retrospective/decisions rules.
- **Out** — the framework definition (AAW1); the reverse playbook (AAW3); the validation run (AAW4); any edit to
  `aaw.rules.md` itself or to any other file. The forward contract (templates, traceability chain, completion
  rule) stays in [specs.approach.md](../elixir/specs/specs.approach.md), linked and never restated here.

## Deliverables
- **AAW2-D1** — `aaw.rules.md`: the roles-and-fences table (Operator · Director · spec-steward · implementor ·
  verifier · fan-out authors · researchers) with the guardrail rule — sharpen, do not stack, and aim the
  guardrail at the contract-owning peer.
- **AAW2-D2** — the two formations (the lead-team for code · the fan-out for content and specs; one game, two
  formations, a reverse run composing both) and the cadence rules (the stage gates · the lag-1 reconcile ·
  md-first checkpointing · concurrency asymmetry · deferred sibling cross-links · the standing-runtime handoff ·
  the pathspec commit rules).
- **AAW2-D3** — the LAWS section (LAW-1, LAW-1a, LAW-2 with its dated 2026-06-10 divergence note, LAW-3, LAW-4,
  and the FAKE-N / V-SOLO family), quoted verbatim from their sources of record where the law is one line.
- **AAW2-D4** — the gates (a check counts only if it runs, with the tier-climb corollary · the verifier
  reproduces the gate and audits its own harness · the anti-rubber-stamp charter · gate sets owned by their
  deliverable and referenced not restated · the voice rule) and the delta taxonomy table
  (MATCH/STALE/INVENTED/MISSING/DEFERRED) with direction-dependent canonicality and the BUILD-GRADE/BLOCKED
  verdict, plus the feedback, mentoring, retrospective, and decisions rules including the Operator's decision
  rights.

## Invariants
- **AAW2-INV1** — every rule cites its defining source (a code-form repository path) or the shipped rung that
  earned it; no aspirational rule appears in the document.
- **AAW2-INV2** — every law quoted as verbatim is verbatim from its source of record; a paraphrased rule is not
  quote-marked.
- **AAW2-INV3** — one authority: the gate lists, the templates, and the traceability chain are referenced (to
  `specs.approach.md` or the deliverable's own guide), never restated; a divergence from a law is recorded as a
  dated note, never a silent rewrite.

## Definition of Done
- [ ] `aaw.rules.md` present with the roles-and-fences table, the two formations, the cadence rules, the LAWS, the gates, the delta taxonomy, and the feedback/decisions sections, and resolving links
- [ ] every rule cites a defining source or an earned rung; no aspirational rule (AAW2-INV1)
- [ ] each one-line law is verbatim from its source; the LAW-2 divergence is a dated note; paraphrases are unquoted (AAW2-INV2)
- [ ] gate sets, templates, and the chain are referenced, not restated (AAW2-INV3)
- [ ] gate sweep green (structure · voice · fences · traceability · links), AAW2-INV1..3 spot-checked
- [ ] the index ladder row for AAW2 reads `built`

Stories: ./aaw2.stories.md · Agent brief: ./aaw2.llms.md · Index: ./aaw.md · Approach: ../elixir/specs/specs.approach.md
