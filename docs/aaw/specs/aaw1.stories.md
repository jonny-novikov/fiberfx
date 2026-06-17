# AAW1 · user stories
> Who wants the framework defined in one document, and how we will know it is right.

## AAW1-US1 — one model to review against
As an Operator, I want the workflow defined in a single document, so that I can review any rung, brief, or
charter against one agreed model instead of reconstructing it from scattered sources.

Acceptance criteria
- Given `aaw.framework.md`, when I read it end-to-end, then the roles, the two layers, the four artifacts,
  and the loop are each defined once, with the commitment each artifact carries.
- Given any definitional claim in the document, when I ask where it comes from, then it traces to a shipped
  artifact, a quoted source of record, or a linked course-canon page — never to an unevidenced assertion.

INVEST — independent of AAW2/AAW3 (definition only, no normative rules); testable by reading each claim
against its cited source; encodes AAW1-INV1.
Priority: must · Size: 3 · Implements deliverables: AAW1-D1.

## AAW1-US2 — reference, never restate
As a Director, I want the definition to link the forward contract and the course canon rather than restate
them, so that briefs built on it inherit one authority per fact and cannot drift.

Acceptance criteria
- Given the definition's artifact and direction sections, when I compare them with
  `docs/elixir/specs/specs.approach.md`, then the templates, the traceability chain, and the completion rule
  appear only as links — no section is copy-pasteable between the two documents.
- Given the three A0 canon pages, when the definition states the roles, layers, artifacts, or loop, then the
  statement matches the canon and links it.

INVEST — negotiable in wording, fixed in discipline; testable by overlap inspection; encodes AAW1-INV2.
Priority: must · Size: 2 · Implements deliverables: AAW1-D1.

## AAW1-US3 — the course acknowledges the codification
As a course author, I want the course tree's self-description and Sources registry reconciled to the
framework, so that the TOC no longer contradicts the rulebook and the Scrum Guide lineage is citable on any
page.

Acceptance criteria
- Given `agile-agent-workflow.toc.md`, when I read its opening claim, then it presents the course as teaching
  a way of working now codified as the AAW framework — and its anti-methodology intent is preserved.
- Given the `CLAUDE.md` Sources registry and the toc Appendix, when I search for the Scrum Guide, then both
  carry `https://scrumguides.org/` as a vetted source.

INVEST — small and isolated (two files, three edits); testable by reading the lines; encodes AAW1-INV3.
Priority: must · Size: 1 · Implements deliverables: AAW1-D2, AAW1-D3.

---
Coverage: D1→US1,US2 · D2→US3 · D3→US3.  Spec: aaw1.md · Agent brief: aaw1.llms.md.
