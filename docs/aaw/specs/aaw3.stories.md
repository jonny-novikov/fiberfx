# AAW3 · user stories
> Who wants the code→spec playbook written down, and how we will know its workflow, template, and gates are right.

## AAW3-US1 — a deriving workflow with the decisions in the right places
As an Operator with a production codebase and no specs, I want a written code→spec workflow whose canonicality
rule and decision gates are fixed, so that a derived spec records the running system without silently
redesigning it, and I make the scope call before the work it scopes.

Acceptance criteria
- Given the inversion section, when I read what reverse mode changes, then the code is canonical on surface
  facts, the build brief is a verify brief, and done means proven — and an intent-level doubt is a recorded
  delta for me, never a silent correction in either artifact.
- Given the seven-stage workflow, when I trace the hardening-scope decision, then it is the Operator's call
  and it falls before stage 6 (the hardening loop), not during it, with stages 1–5 as fan-out, stage 6 as
  lead-team, and stage 7 as the orchestrator fold-back.

INVEST — independent of the template mechanics (this is the workflow and its gates); testable by reading the
inversion rule and the stage-to-decision order; encodes AAW3-INV2.
Priority: must · Size: 3 · Implements deliverables: AAW3-D1, AAW3-D2.

## AAW3-US2 — a re-keyed template fan-out can apply mechanically
As an orchestrator, I want the reverse triad's section semantics fixed against the forward template, so that
the briefs I hand to fan-out authors are mechanical and the forward structure gate accepts a reverse triad
unmodified.

Acceptance criteria
- Given the forward→reverse section table and the compact template, when I compare its `##` headings with the
  forward spec template, then there are exactly the six forward headings, re-keyed only by a parenthetical
  (`Deliverables (Surfaces — as-built)`, `Definition of Done (Verification)`) — so the structure sweep does
  not fork.
- Given the `.llms.md` semantics, when I read how the agent brief re-keys, then it is a reconcile/verify brief
  whose Requirements are grounding assertions and whose closing block is a grounding-and-hardening prompt, not
  a build prompt.

INVEST — negotiable in wording, fixed in the heading set; testable by diffing the headings against the
forward template; encodes AAW3-INV1.
Priority: must · Size: 2 · Implements deliverables: AAW3-D3.

## AAW3-US3 — deterministic gates to verify a derived triad
As a domain-expert verifier, I want the reverse direction's added gates to be decidable from the tree alone,
so that I can verify a derived triad against the code without a judgment call standing in for proof.

Acceptance criteria
- Given the added-gates section, when I read each of the four, then grounding, no-invent, exact-arity, and
  file:line-resolves are each decided by reading the tree (existence, arity at the `def` site, location
  resolution) — with no judgment-only gate among them.
- Given a derived triad citing a surface absent from the verified inventory, when I run the no-invent gate,
  then the gate names the spec itself as the defect rather than asking me to adjudicate intent.

INVEST — small and isolated (the four gates only); testable by checking each gate is tree-decidable; encodes
AAW3-INV3.
Priority: must · Size: 1 · Implements deliverables: AAW3-D4.

---
Coverage: D1→US1 · D2→US1 · D3→US2 · D4→US3.  Spec: aaw3.md · Agent brief: aaw3.llms.md.
