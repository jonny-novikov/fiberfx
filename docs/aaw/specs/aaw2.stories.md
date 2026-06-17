# AAW2 · user stories
> Who wants the rules of the game codified in one document, and how we will know each rule is earned and cited.

## AAW2-US1 — fences and cadence pinned, so a spawn prompt carries only the rung delta
As a Director, I want the roles, their fences, and the cadence rules codified in one document, so that I can
brief any rung by referencing the rules and adding only the rung's delta, instead of restating who edits what
on every spawn.

Acceptance criteria
- Given the roles-and-fences table, when I check any role, then its Owns / Edits / Never columns are stated
  once, and the guardrail rule says to sharpen an existing line rather than stack a second and to aim it at the
  contract-owning peer.
- Given the cadence rules, when I read them, then the stage gates, the lag-1 reconcile, md-first checkpointing,
  concurrency asymmetry, deferred sibling cross-links, the standing-runtime handoff, and the pathspec commit
  rules each cite the rung or source that earned them, and no rule is aspirational.

INVEST — independent of AAW3/AAW4 (the rules layer only, no reverse playbook); testable by reading each fence
and cadence rule against its cited source; encodes AAW2-INV1.
Priority: must · Size: 3 · Implements deliverables: AAW2-D1, AAW2-D2.

## AAW2-US2 — the LAWS and the decision rights in one referenceable place
As an Operator, I want the LAWS and my decision rights codified in one document, so that I can hold any
execution against the same agreed laws and the same boundary of what only I decide.

Acceptance criteria
- Given the LAWS section, when I compare a one-line law against its source of record, then the quoted text is
  verbatim, the LAW-2 divergence is recorded as a dated note rather than a rewrite, and any paraphrased rule is
  not in quote marks.
- Given the decisions section, when I look for who settles a fork, then it names the deferred choices as named
  decisions in the roadmap and states the decision rights reserved to the Operator, and an agent that meets an
  unsettled fork stops and surfaces it rather than picking.

INVEST — negotiable in wording, fixed in fidelity; testable by checking each quoted law against its source;
encodes AAW2-INV2.
Priority: must · Size: 2 · Implements deliverables: AAW2-D3.

## AAW2-US3 — the taxonomy and verdict semantics stable across rungs
As a verifier, I want the delta taxonomy, the gate principles, and the verdict semantics codified once and
referenced rather than restated, so that every rung's reconcile reads the same and the gate lists stay owned by
one authority.

Acceptance criteria
- Given the delta taxonomy table, when I classify a claim, then MATCH / STALE / INVENTED / MISSING / DEFERRED
  carry one resolution each, direction-dependent canonicality is stated, and the verdict is BUILD-GRADE only
  when every promise is MATCH or a marked DEFERRED while any STALE / INVENTED / MISSING BLOCKS.
- Given the gates section, when I look for a gate list or a template, then it is referenced to
  `specs.approach.md` or the deliverable's own guide rather than restated, and the voice rule points at the
  forbidden set defined in `aaw.rules.md` as the one authority.

INVEST — small and isolated (the taxonomy, gates, and verdict only); testable by reading the table and the
references; encodes AAW2-INV3.
Priority: must · Size: 2 · Implements deliverables: AAW2-D4.

---
Coverage: D1→US1 · D2→US1 · D3→US2 · D4→US3.  Spec: aaw2.md · Agent brief: aaw2.llms.md.
