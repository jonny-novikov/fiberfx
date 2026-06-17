# AAW3 · agent brief (llms)
> Implementation brief for the reverse-playbook rung. References, traced requirements, the document topology,
> and a paste-ready prompt. Pairs with the spec aaw3.md and the stories aaw3.stories.md. This rung was
> senior-authored by the orchestrator; the document is already written, so the prompt records the reproducible
> recipe rather than a build.

## References
- [aaw3.md](aaw3.md) + [aaw3.stories.md](aaw3.stories.md) — the contract and its acceptance.
- [aaw.reverse.md](aaw.reverse.md) — the deliverable document this triad specifies (the inversion section, the
  seven stages, the re-keyed triad semantics, the four gates, the compact template).
- [specs.approach.md](../elixir/specs/specs.approach.md) — the forward contract that owns the templates,
  the six standard gates, and the traceability chain; the reverse triad conforms to its structure (AAW3-INV1's
  comparison target).
- [aaw.rules.md](aaw.rules.md) — the source of the formation definitions and the delta taxonomy the workflow
  maps onto (AAW3-INV2's target).
- The "code wins" precedent and the reconcile machinery, in code form: the redlock chapter's canonicality
  rule, and `.claude/commands/reconcile.md` (the bidirectional differ whose post-build direction this playbook
  generalizes). The reverse run's output lands under `docs/echomq/specs/core/` — named in code form, not
  edited here (AAW4 owns it).

## Requirements
- **AAW3-R1** — the document carries the inversion section: when reverse mode applies, the three inversions
  (code canonical on surface facts · build brief becomes verify brief · done means proven), and the
  no-silent-sync rule (an intent doubt is a recorded delta for the Operator, never a silent correction). [US: AAW3-US1]
- **AAW3-R2** — the seven stages appear in order with the formation split stated (1–5 fan-out, 6 lead-team, 7
  orchestrator) and the Operator's hardening-scope decision placed before stage 6, never during it. [US: AAW3-US1]
- **AAW3-R3** — the re-keyed triad template carries exactly the six forward `##` headings, re-keyed only by a
  parenthetical (`Deliverables (Surfaces — as-built)`, `Definition of Done (Verification)`), so the forward
  structure gate passes it unmodified. [US: AAW3-US2]
- **AAW3-R4** — the `.llms.md` semantics are a reconcile/verify brief: Requirements are grounding assertions,
  and the closing fenced block is a grounding-and-hardening prompt, not a build prompt. [US: AAW3-US2]
- **AAW3-R5** — the four added gates (grounding · no-invent · exact-arity · file:line-resolves) are each
  described as decidable from the tree (existence, arity at the `def` site, location resolution), with no
  judgment-only gate among them. [US: AAW3-US3]

## Execution topology
Runtime (document dependency graph):
```text
specs.approach.md (forward contract, linked)      aaw.rules.md (formations + taxonomy, linked)
                 \                                /
                  aaw.reverse.md  (this rung's deliverable)
                 /            |              \
   AAW2 (rules, by id)   AAW4 (the run, by id)   docs/echomq/specs/core/ (the run's output, code form)
                          |
        the four added gates + the re-keyed compact template (govern every reverse triad)
```
Tasks:
```text
1. read aaw.reverse.md + specs.approach.md + aaw.rules.md   (ground against the deliverable + its sources)
2. confirm the inversion section + no-silent-sync rule      (AAW3-R1)
3. confirm the seven stages, formation split, Operator gate before stage 6   (AAW3-R2)
4. confirm the re-keyed template = six forward headings, parenthetical re-key only   (AAW3-R3, AAW3-R4)
5. confirm the four added gates are tree-decidable           (AAW3-R5)
6. write the triad (aaw3.{md,stories.md,llms.md}); sweep + spot-check INV1..3   (verification)
```
Touched files: `docs/aaw/aaw3.md`, `docs/aaw/aaw3.stories.md`, `docs/aaw/aaw3.llms.md`.

## Agent stories
- **AAW3-AS1** [implements AAW3-US1] — Directive: specify the inversion section and the seven-stage workflow,
  fixing the canonicality rule, the no-silent-sync rule, the formation split, and the Operator scope gate
  before stage 6. Acceptance gate: the spec's Deliverables D1/D2 and Invariant INV2 read against
  `aaw.reverse.md` with the stage-to-decision order matching the document (AAW3-R1, AAW3-R2).
- **AAW3-AS2** [implements AAW3-US2] — Directive: specify the re-keyed triad semantics so a fan-out brief is
  mechanical — the forward→reverse table, the heading-parenthetical rule, and the `.llms.md` as a
  reconcile/verify brief. Acceptance gate: the compact template's `##` headings diff to exactly the six
  forward headings with parenthetical re-keys only (AAW3-R3, AAW3-R4).
- **AAW3-AS3** [implements AAW3-US3] — Directive: specify the four added gates as tree-decidable, with the
  no-invent gate naming the spec as the defect. Acceptance gate: each of the four gates is shown decidable
  from the tree, with no judgment-only gate among them (AAW3-R5).

## Execution plan — first two stories
1. **AAW3-AS1 — specify the inversion and the workflow.** Read `aaw.reverse.md` §the inversion and §the
   workflow; write `aaw3.md` Deliverables D1/D2 and Invariant INV2; confirm the Operator scope gate falls
   before stage 6; run the link/fence/voice sweep.
2. **AAW3-AS2 — specify the re-keyed template.** Diff the compact template's headings against the forward
   `fN.M.md` template in `specs.approach.md`; write Deliverable D3 and Invariant INV1; re-sweep.

## Comprehensive implementation prompt
```text
You are authoring the triad for the AAW reverse playbook (rung AAW3). The deliverable document
docs/aaw/aaw.reverse.md is ALREADY WRITTEN — you specify it, you do not rewrite it. Touch only the three
files docs/aaw/aaw3.{md,stories.md,llms.md}.

Ground truth, read first: docs/aaw/aaw.reverse.md (the inversion section, the seven-stage workflow, the
forward->reverse section table, the four added gates, the compact template), docs/elixir/specs/specs.approach.md
(the forward contract — the six standard gates and the fN.M template the reverse triad must stay compatible
with; LINK it, never restate it), and docs/aaw/aaw.rules.md (the formation definitions and the delta taxonomy
the workflow maps onto). Reference the "code wins" precedent and .claude/commands/reconcile.md in code form;
name docs/echomq/specs/core/ (AAW4's output) in code form only — do not edit it.

Write aaw3.md with exactly six ## sections (Goal · Rationale (5W) with exactly five bold bullets · Scope In/Out
· Deliverables · Invariants · Definition of Done as checkboxes). Deliverables are AAW3-D1..D4 verbatim from the
brief: the inversion section + no-silent-sync rule; the seven-stage workflow + formation split + Operator scope
gate before stage 6; the re-keyed triad semantics + heading-parenthetical rule + compact template; the four
added gates. Invariants AAW3-INV1..3: structure-gate compatibility of the re-keyed template; the stage-to-
formation map with the Operator gate before hardening; each gate deterministic and tree-decidable.

Write aaw3.stories.md with three Connextra stories (Operator with a deriving workflow; orchestrator needing the
re-keyed template; domain-expert verifier needing deterministic gates), each with two Given/When/Then criteria,
an INVEST line ending "encodes AAW3-INV#", and a Priority/Size/Implements line. Close with
"Coverage: D1->US1 · D2->US1 · D3->US2 · D4->US3."

Write aaw3.llms.md in the forward section order: References · Requirements (AAW3-R1..R5, each ending [US: ...]) ·
Execution topology (a runtime fenced block = the document dependency graph; a tasks fenced block; a Touched
files line) · Agent stories (AAW3-AS1..AS3, each [implements ...] with a Directive and an Acceptance gate) ·
Execution plan — first two stories · this comprehensive prompt as a fenced block.

Gates before reporting: structure (six sections; five 5W bullets; checkbox DoD) · voice (no forbidden words; no
first person outside the stories' "I want"; no perceptual or interior-state verb on software) · fences balanced
· traceability (every D# in the Coverage line; every R# carries [US:]; every AS# carries [implements]; every
INV# encoded by a story) · every relative link resolves from docs/aaw/ (link only existing siblings, aaw.md,
aaw.reverse.md, aaw.rules.md, aaw1.*, and ../elixir/specs/specs.approach.md; reference AAW2/AAW4 by id only).
Never run git.
```

Spec: ./aaw3.md · Stories: ./aaw3.stories.md · Index: ./aaw.md · Approach: ../elixir/specs/specs.approach.md
