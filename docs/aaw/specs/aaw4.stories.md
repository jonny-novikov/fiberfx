# AAW4 · user stories
> Who wants the reverse playbook proven against production code, and how we will know the run held.

## AAW4-US1 — proof before trust
As an Operator, I want the framework run once in reverse against a real production tree, so that I can trust
the reverse capability on other trees only after it has produced a verified spec chapter from actual code.

Acceptance criteria
- Given `echo/apps/echomq` and the seven-stage playbook, when the run completes, then `docs/echomq/specs/core/`
  holds `core.md`, `core.roadmap.md`, `core.progress.md`, and the triads `c1`–`c7`, and the AAW4 index row
  reads `built`.
- Given any deferred reverse target, when I read the scope, then `portal`, `echo_data`, and `echo_bot` are
  named future runs, not silent omissions, so the proof's boundary is explicit.

INVEST — independent of any later reverse run (this run alone is the proof); testable by reading the chapter on
disk and the flipped row; encodes AAW4-INV2.
Priority: must · Size: 5 · Implements deliverables: AAW4-D1, AAW4-D5.

## AAW4-US2 — the as-built behavior pinned
As a maintainer of echomq, I want the library's as-built behavior pinned by specs and running checks, so that a
refactor cannot silently break a surface or an invariant the code currently holds.

Acceptance criteria
- Given any triad `c1`–`c7`, when I read its surfaces, then each is cited as `Module.fun/arity` with a
  `file:line` that resolves in the current tree, and the four reverse gates pass for the triad.
- Given the invariant→check table in `core.progress.md`, when I read any invariant in `c1`–`c7`, then it maps
  to a running check at a cited `file:line` or to an explicitly recorded gap, with no invariant left unmapped.

INVEST — negotiable in rung wording, fixed in grounding; testable by resolving every citation and running each
named check; encodes AAW4-INV1, AAW4-INV3.
Priority: must · Size: 8 · Implements deliverables: AAW4-D2, AAW4-D4.

## AAW4-US3 — two formations, one git discipline
As a Director, I want the run to compose the fan-out and the lead-team without breaking the commit rules, so
that the survey-and-author work stays git-free and only the lead-team hardening rungs commit.

Acceptance criteria
- Given the fan-out stages (instruments, triads, verification), when the work lands, then no git ran in those
  stages and the Operator committed the batches out-of-band per [aaw.rules.md](aaw.rules.md).
- Given each lead-team hardening rung, when it closes, then exactly one Director pathspec commit lands, scoped
  to the echo tree, with no `git add -A` and no bare commit.

INVEST — small in surface, load-bearing in discipline; testable by inspecting who committed which stage and the
pathspec of each commit; encodes AAW4-INV4.
Priority: must · Size: 3 · Implements deliverables: AAW4-D4.

## AAW4-US4 — deltas recorded, not silently fixed
As a domain expert, I want every grounding doubt recorded as a delta rather than quietly corrected, so that the
chapter records what the code is and surfaces what looks wrong to the Operator instead of redesigning it.

Acceptance criteria
- Given a re-verification of a triad, when a cited surface is INVENTED or a claim is STALE, then the finding is
  written as a delta-taxonomy entry in `core.progress.md` and the triad loops back to re-authoring before any
  hardening runs.
- Given an intent-level doubt — a surface that looks wrong on purpose — when it is found, then it is surfaced
  to the Operator as a recorded delta, never silently synced in the spec or the code.

INVEST — independent of the hardening (verification gates the chapter first); testable by reading the delta
records against the triads they correct; encodes AAW4-INV2, AAW4-INV3.
Priority: must · Size: 3 · Implements deliverables: AAW4-D3.

---
Coverage: D1→US1 · D2→US2 · D3→US4 · D4→US2,US3 · D5→US1.  Spec: aaw4.md · Agent brief: aaw4.llms.md.
