# AAW3 · The reverse playbook
> One document defines AAW's code→spec capability as an executable playbook — derive, verify, harden — so a
> production tree without specs can be specified by the framework rather than by improvisation.

## Goal
`aaw.reverse.md` exists as the definition of record for reverse mode: when it applies and what inverts, the
seven-stage workflow with its formation split and Operator scope gate, the re-keyed triad semantics that keep
the forward structure gate unforked, and the four deterministic gates the reverse direction adds.

## Rationale (5W)
- **Why**   — the framework runs forward by default (spec first, code derived); a production tree that grew
  faster than its documents has no forward path, and without a written playbook each code→spec run reinvents
  the canonicality rule, the stage order, and the gates.
- **What**  — the reverse-mode playbook document: the three inversions with the no-silent-sync rule, the
  seven stages with the formation split and the Operator scope gate before hardening, the re-keyed triad
  semantics and compact template, and the four added gates.
- **Who**   — the Operator (a deriving workflow whose decision gates fall in the right places), the Director
  or orchestrator (a re-keyed template fixed enough that fan-out briefs are mechanical), domain-expert
  verifiers (deterministic gates to verify a derived triad against the tree).
- **When**  — the third rung of the framework ladder; it depends on the definition (AAW1) and the rules
  (AAW2), and AAW4 executes it once against `echo/apps/echomq`.
- **Where** — `docs/aaw/aaw.reverse.md`; the playbook links the forward contract
  [specs.approach.md](../elixir/specs/specs.approach.md) and the rules [aaw.rules.md](aaw.rules.md), names the
  reconcile machinery in code form, and touches nothing under `docs/echomq/specs/core/` (AAW4's output).

## Scope
- **In**  — the triad for the already-written reverse playbook: the inversion section, the seven-stage
  workflow, the re-keyed triad semantics, the four added gates, and the compact template.
- **Out** — the framework definition (AAW1); the normative rules and their formations (AAW2, referenced by
  link as the source of formation definitions); the validation run that first executes this playbook (AAW4,
  referenced by id in prose only); any edit to `aaw.reverse.md` itself or to any other file.

## Deliverables
- **AAW3-D1** — `aaw.reverse.md` §the inversion: when reverse mode applies, the three inversions (code
  canonical on surface facts · the build brief becomes a verify brief · done means proven), and the
  no-silent-sync rule — an intent-level doubt is a recorded delta for the Operator, never a silent correction
  in either artifact.
- **AAW3-D2** — the seven-stage workflow (survey wave → ladder design → senior instruments → triad fan-out →
  adversarial grounding verification → invariant→check hardening loop → fold-back), with the formation split
  (stages 1–5 fan-out, stage 6 lead-team, stage 7 orchestrator) and the Operator scope gate placed before
  stage 6.
- **AAW3-D3** — the re-keyed triad semantics: the forward→reverse section table; the heading-parenthetical
  rule (`## Deliverables (Surfaces — as-built)`, `## Definition of Done (Verification)`) that keeps the
  structure gate unforked; the `.llms.md` as a reconcile/verify brief ending in a grounding-and-hardening
  prompt; the compact fenced template.
- **AAW3-D4** — the four added gates (grounding · no-invent · exact-arity · file:line-resolves), each
  checkable from the tree alone.

## Invariants
- **AAW3-INV1** — the re-keyed template remains structure-gate-compatible: exactly the six forward `##`
  headings, re-keyed only by a parenthetical, so the forward structure sweep passes a reverse triad
  unmodified.
- **AAW3-INV2** — the workflow's stages map onto the formations defined in `aaw.rules.md`, with the
  Operator's hardening-scope decision placed before the hardening stage, never during it.
- **AAW3-INV3** — each added gate is deterministic — decidable by reading the tree (existence, arity at the
  `def` site, location resolution) — with no judgment-only gate among the four.

## Definition of Done
- [ ] `aaw.reverse.md` present with the inversion section, the seven stages, the re-keyed triad semantics, the
  four gates, and the compact template; resolving links
- [ ] the seven stages name the formation split and place the Operator scope gate before stage 6
- [ ] the re-keyed template carries exactly the six forward `##` headings (parenthetical re-key only)
- [ ] gate sweep green (structure · voice · fences · traceability · links), AAW3-INV1..3 spot-checked
- [ ] the index ladder row for AAW3 reads `built`

Stories: ./aaw3.stories.md · Agent brief: ./aaw3.llms.md · Index: ./aaw.md · Approach: ../elixir/specs/specs.approach.md
