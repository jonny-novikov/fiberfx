# AAW1 · agent brief (llms)
> Implementation brief for the framework-definition rung. References, traced requirements, the document
> topology, and a paste-ready prompt. Pairs with the spec aaw1.md and the stories aaw1.stories.md. This rung
> was senior-authored by the orchestrator; the prompt records the reproducible recipe.

## References
- [aaw1.md](aaw1.md) + [aaw1.stories.md](aaw1.stories.md) — the contract and its acceptance.
- [specs.approach.md](../elixir/specs/specs.approach.md) — the forward contract the definition links and must
  not restate (AAW1-INV2's comparison target).
- The A0 canon (ground truth for roles/layers/artifacts/loop):
  [two-layer-model](../agile-agent-workflow/content/what/two-layer-model.md) ·
  [four-artifacts](../agile-agent-workflow/content/what/four-artifacts.md) ·
  [author-operator-loop](../agile-agent-workflow/content/what/author-operator-loop.md).
- The Scrum Guide — the rulebook anatomy and the registry entry: <https://scrumguides.org/>.
- Calibration targets: `docs/agile-agent-workflow/agile-agent-workflow.toc.md` (line 9 + Appendix),
  `docs/agile-agent-workflow/CLAUDE.md` (the Sources registry table).

## Requirements
- **AAW1-R1** — the definition carries exactly these sections: Purpose · Definition · Theory (three pillars) ·
  Values · the Operator-Agent model · the two-layer model · the four artifacts and commitments · the
  Author/Agent loop · the two directions · References. [US: AAW1-US1]
- **AAW1-R2** — every definitional claim cites or links its source (a shipped artifact, a source of record in
  code form, or a canon page); no unevidenced assertion. [US: AAW1-US1]
- **AAW1-R3** — zero copy-pasteable overlap with `specs.approach.md`: templates, traceability chain, and
  completion rule appear only as links. [US: AAW1-US2]
- **AAW1-R4** — the six loop stages and the role definitions match the A0 canon verbatim in substance. [US: AAW1-US2]
- **AAW1-R5** — toc line 9 reframed preserving the anti-methodology intent; the Scrum Guide present in both
  the `CLAUDE.md` registry table and the toc Appendix. [US: AAW1-US3]

## Execution topology
Runtime (document dependency graph):
```text
specs.approach.md (forward contract, linked)      A0 canon (3 pages, linked)
                 \                                /
                  aaw.framework.md  (this rung's deliverable)
                 /        |         \
        aaw.rules.md  aaw.reverse.md  aaw.md / aaw.roadmap.md   (downstream rungs reference it)
                          |
        toc.md line 9 + Appendix · CLAUDE.md registry           (calibration edits reconcile the course tree)
```
Tasks:
```text
1. read the A0 canon + specs.approach.md          (ground)
2. author aaw.framework.md                        (AAW1-D1; gates: structure/voice/fences/links)
3. reframe toc.md:9                               (AAW1-D2; intent-preserving single-sentence edit)
4. add Scrum Guide to CLAUDE.md registry + toc Appendix   (AAW1-D3)
5. sweep + spot-check INV1..3                     (verification)
```
Touched files: `docs/aaw/aaw.framework.md`, `docs/agile-agent-workflow/agile-agent-workflow.toc.md`,
`docs/agile-agent-workflow/CLAUDE.md`.

## Agent stories
- **AAW1-AS1** [implements AAW1-US1] — Directive: author `aaw.framework.md` to AAW1-R1/R2, grounding every
  claim in the canon or a source of record. Acceptance gate: all nine sections present; every link resolves;
  a claim-by-claim read finds no unevidenced assertion.
- **AAW1-AS2** [implements AAW1-US2] — Directive: hold the DRY boundary while writing — link
  `specs.approach.md` for templates/chain/completion; quote only what the rules document does not own.
  Acceptance gate: overlap inspection finds no copy-pasteable section (AAW1-R3) and the loop/roles match the
  canon (AAW1-R4).
- **AAW1-AS3** [implements AAW1-US3] — Directive: apply the two calibration edits (toc:9 reframe; Scrum Guide
  into the registry table and the Appendix). Acceptance gate: both files carry the edits; the reframed
  sentence preserves the anti-methodology intent (AAW1-R5).

## Execution plan — first two stories
1. **AAW1-AS1 — author the definition.** Read the three canon files + `specs.approach.md`; write
   `docs/aaw/aaw.framework.md`; run the link/fence/voice sweep on it.
2. **AAW1-AS2 — hold the DRY boundary.** Diff-read the definition against `specs.approach.md` section by
   section; convert any restatement into a link; re-sweep.

## Comprehensive implementation prompt
```text
You are authoring the AAW framework definition (rung AAW1) at docs/aaw/aaw.framework.md.

Ground truth: docs/agile-agent-workflow/content/what/{two-layer-model,four-artifacts,author-operator-loop}.md
(the canonical roles, layers, artifacts, loop) and docs/elixir/specs/specs.approach.md (the forward contract —
LINK it for templates/traceability/completion; never restate it).

Write these sections, in order: Purpose · Definition of AAW · Theory (transparency/inspection/adaptation,
re-cast for agent work) · Values (five, practice-earned) · The Operator-Agent model (Operator, Director,
specialized agents; the pairing claim) · The two-layer model · The four artifacts and their commitments
(table) · The Author/Agent loop (the six canon stages + the adapt arc; the Scrum mapping) · The two
directions (forward by reference to specs.approach.md; reverse by reference to aaw.reverse.md) · References
(Scrum Guide https://scrumguides.org/ first among the lineage).

Then calibrate the course tree: reframe agile-agent-workflow.toc.md line 9 so the course "teaches a way of
working, codified as the AAW framework" (preserve the anti-methodology intent); add
| The Scrum Guide | `https://scrumguides.org/` | to the CLAUDE.md Sources registry table and the toc Appendix
canon. Touch nothing else under docs/agile-agent-workflow/.

Gates before reporting: structure (the nine sections) · voice (no forbidden words, no first person, no
perceptual verbs on software) · fences balanced · every relative link resolves from docs/aaw/ · zero
copy-pasteable overlap with specs.approach.md. Never run git.
```

Spec: ./aaw1.md · Stories: ./aaw1.stories.md · Index: ./aaw.md · Approach: ../elixir/specs/specs.approach.md
