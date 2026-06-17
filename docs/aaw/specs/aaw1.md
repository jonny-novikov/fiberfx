# AAW1 · The framework definition
> One document defines AAW — roles, layers, artifacts, loop — so every brief, charter, and chapter references
> one model instead of restating it, and the course tree acknowledges the codification.

## Goal
`aaw.framework.md` exists as the definition of record for AAW, coherent with the shipped practice and the
course canon, and the course tree's self-description no longer contradicts it.

## Rationale (5W)
- **Why**   — the workflow's definition is scattered across commands, charters, guides, and course pages;
  every restatement is a drift surface, and the course TOC's "not a framework" line contradicts a codified
  rulebook.
- **What**  — the framework definition document (theory, values, the Operator-Agent model, the two-layer
  model, the four artifacts and commitments, the Author/Agent loop, the two directions), plus the two
  course-tree calibration edits that reconcile the course to it.
- **Who**   — the Operator (one model to review against), the Director (briefs reference, never restate),
  fan-out authors and lead-team peers (one definition upstream of every charter), course authors (a
  consistent self-description).
- **When**  — the first rung of the framework ladder; everything else in `docs/aaw/` builds on it.
- **Where** — `docs/aaw/aaw.framework.md`; calibration touches `docs/agile-agent-workflow/`
  (`agile-agent-workflow.toc.md` line 9 + Appendix, `CLAUDE.md` Sources registry) and nothing else in the
  course tree.

## Scope
- **In**  — the definition document; the toc line-9 reframe; the Scrum Guide entry in the Sources registry
  (`CLAUDE.md` table + toc Appendix).
- **Out** — the normative rules (AAW2); the reverse playbook (AAW3); any course HTML page (the course-home
  Sources block is a named seam in [aaw.roadmap.md](aaw.roadmap.md)); any edit to
  `specs.approach.md`.

## Deliverables
- **AAW1-D1** — `aaw.framework.md`: purpose · definition · theory (three pillars) · values · the
  Operator-Agent model · the two-layer model · the four artifacts with commitments · the Author/Agent loop ·
  the two directions · references, grounded in the A0 canon files and the shipped practice.
- **AAW1-D2** — the `agile-agent-workflow.toc.md` line-9 reframe: the course teaches a way of working that is
  now codified as the AAW framework, preserving the original anti-methodology intent.
- **AAW1-D3** — the Scrum Guide (Schwaber & Sutherland, `https://scrumguides.org/`) added to the Sources
  registry in `docs/agile-agent-workflow/CLAUDE.md` and to the toc Appendix canon.

## Invariants
- **AAW1-INV1** — every definitional claim is traceable to a shipped artifact or the course canon; nothing in
  the definition contradicts the evidenced practice.
- **AAW1-INV2** — one authority: the definition links the forward contract and the course canon; no section
  could be copy-pasted from `specs.approach.md` (zero template/chain/completion-rule restatement).
- **AAW1-INV3** — the toc reframe keeps AAW "a way of working" (codified), not a rigid methodology; the
  sentence's anti-ceremony intent survives.

## Definition of Done
- [ ] `aaw.framework.md` present with all nine sections and resolving links
- [ ] toc line-9 reframed; Scrum Guide present in the `CLAUDE.md` registry table and the toc Appendix
- [ ] gate sweep green (structure · voice · fences · traceability · links), AAW1-INV1..3 spot-checked
- [ ] the index ladder row for AAW1 reads `built`

Stories: ./aaw1.stories.md · Agent brief: ./aaw1.llms.md · Index: ./aaw.md · Approach: ../elixir/specs/specs.approach.md
