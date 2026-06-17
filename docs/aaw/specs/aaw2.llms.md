# AAW2 · agent brief (llms)
> Implementation brief for the rules-of-the-game rung. References, traced requirements, the document topology,
> and a paste-ready prompt. Pairs with the spec aaw2.md and the stories aaw2.stories.md. The document is already
> written; this brief records the reproducible recipe — ground in the named sources, write the sections, hold
> the gates.

## References
- [aaw2.md](aaw2.md) + [aaw2.stories.md](aaw2.stories.md) — the contract and its acceptance.
- [aaw.framework.md](aaw.framework.md) — the definition this document constrains (AAW1's deliverable).
- [specs.approach.md](../elixir/specs/specs.approach.md) — the forward contract the rules link and must not
  restate: the templates, the traceability chain, and the completion rule (AAW2-INV3's reference target), and
  the spec-system gate set the gates section points at.
- The sources of record, in code form (named, never linked — they are tool configuration, not documents):
  `.claude/commands/x.md` (the LAWS and the audit ledger), `.claude/commands/reconcile.md` (the delta
  taxonomy), `.claude/agents/venus.md` · `.claude/agents/mars.md` · `.claude/agents/apollo.md` (the steward,
  implementor, and verifier charters and their guardrails).
- The operator guides under `docs/elixir/specs/phoenix/`: `phoenix.operator.md` (the operator's field manual)
  and `f6.progress.md` (the retrospective form and the mentoring ledger).
- The "code wins" precedent for reverse canonicality: [redlock](../elixir/redlock/redlock.md).

## Requirements
- **AAW2-R1** — the roles-and-fences table states Owns / Edits / Never for each of the seven roles (Operator ·
  Director · spec-steward · implementor · verifier · fan-out authors · researchers), and the guardrail rule says
  to sharpen one named charter line rather than stack a second, aimed at the contract-owning peer. [US: AAW2-US1]
- **AAW2-R2** — the two formations (lead-team for code · fan-out for content and specs; a reverse run composing
  both) and the cadence rules (stage gates · lag-1 reconcile · md-first checkpointing · concurrency asymmetry ·
  deferred sibling cross-links · standing-runtime handoff · pathspec commit rules) each cite the rung or source
  that earned them. [US: AAW2-US1]
- **AAW2-R3** — each one-line law (LAW-1, LAW-1a, LAW-4) is verbatim from `.claude/commands/x.md`; LAW-2 carries
  the dated the lead-team spawns specialized
  peers with TeamCreate (according aaw) with the charter applied via prompt; LAW-3 and the FAKE-N / V-SOLO family are stated; paraphrased rules
  are not quote-marked. [US: AAW2-US2]
- **AAW2-R4** — the decisions section names deferred choices as named decisions in the roadmap and states the
  Operator's decision rights (architecture, API contracts, dependencies, routing identity, hardening scope, the
  accept/iterate call, mentoring grants); an agent at an unsettled fork stops and surfaces it. [US: AAW2-US2]
- **AAW2-R5** — the delta taxonomy table gives one resolution per delta
  (MATCH/STALE/INVENTED/MISSING/DEFERRED), states direction-dependent canonicality (pre-build the spec wins,
  post-build the code wins on surface facts, reverse begins MISSING), and the verdict is BUILD-GRADE iff every
  promise is MATCH or a marked DEFERRED while any STALE/INVENTED/MISSING BLOCKS. [US: AAW2-US3]
- **AAW2-R6** — gate sets, templates, and the chain are referenced to `specs.approach.md` or the deliverable's
  own guide, never restated; the voice rule points at the forbidden set defined in `aaw.rules.md` as the one
  authority, and this brief does not duplicate that list. [US: AAW2-US3]

## Execution topology
Runtime (document dependency graph):
```text
specs.approach.md (forward contract, linked)        sources of record (.claude/commands/*.md, .claude/agents/*.md)
                 \                                  /            operator guides (docs/elixir/specs/phoenix/*.md)
                  aaw.framework.md (AAW1, linked)  /            redlock.md (reverse precedent, linked)
                                 \                /            /
                                  aaw.rules.md  (this rung's deliverable, normative layer)
                                 /             \
                  aaw.reverse.md (AAW3)          aaw.md / aaw.roadmap.md   (downstream rungs reference it)
```
Tasks:
```text
1. read the sources of record + specs.approach.md + aaw.framework.md   (ground every rule)
2. write the roles-and-fences table + the guardrail rule               (AAW2-D1; INV1)
3. write the two formations + the cadence rules                        (AAW2-D2; INV1)
4. write the LAWS, quoting one-line laws verbatim + the LAW-2 note      (AAW2-D3; INV2)
5. write the gates + the delta taxonomy + the verdict + feedback/decisions  (AAW2-D4; INV3)
6. sweep + spot-check INV1..3 (citations, verbatim laws, one-authority references)   (verification)
```
Touched files: `docs/aaw/aaw.rules.md` (the deliverable; already written — this brief is its reproducible
recipe), and the triad files `docs/aaw/aaw2.md`, `docs/aaw/aaw2.stories.md`, `docs/aaw/aaw2.llms.md`.

## Agent stories
- **AAW2-AS1** [implements AAW2-US1] — Directive: write the roles-and-fences table and the cadence rules,
  grounding every fence and rule in the charter, command, or rung that earned it. Acceptance gate: the seven
  roles each carry Owns / Edits / Never; the guardrail rule says sharpen-not-stack aimed at the contract-owning
  peer; no aspirational rule (AAW2-R1, AAW2-R2, AAW2-INV1).
- **AAW2-AS2** [implements AAW2-US2] — Directive: write the LAWS quoting the one-line laws verbatim from their
  source, record the LAW-2 divergence as a dated note, and write the decisions section with the Operator's
  decision rights. Acceptance gate: each quoted law matches its source character-for-character; paraphrases are
  unquoted; the decision rights and the stop-and-surface rule are present (AAW2-R3, AAW2-R4, AAW2-INV2).
- **AAW2-AS3** [implements AAW2-US3] — Directive: write the gates, the delta taxonomy with the verdict, and the
  feedback/mentoring/retrospective rules, referencing every gate list and template rather than restating it.
  Acceptance gate: the taxonomy gives one resolution per delta with the BUILD-GRADE/BLOCKED verdict; templates
  and the chain appear only as links; the voice rule points at the forbidden set in `aaw.rules.md` (AAW2-R5,
  AAW2-R6, AAW2-INV3).

## Execution plan — first two stories
1. **AAW2-AS1 — author fences and cadence.** Read the `.claude/agents/*.md` charters and `.claude/commands/x.md`;
   write the roles-and-fences table + the guardrail rule + the two formations + the cadence rules into
   `docs/aaw/aaw.rules.md`; run the link/fence/voice sweep and confirm each rule cites its source.
2. **AAW2-AS2 — author the LAWS and decisions.** Open `.claude/commands/x.md`, copy each one-line law verbatim,
   add the dated LAW-2 divergence note, write the decisions section with the Operator's decision rights; re-sweep
   and diff each quoted law against its source.

## Comprehensive implementation prompt
```text
You are authoring the AAW rules document (rung AAW2) at docs/aaw/aaw.rules.md. The document is the normative
companion of aaw.framework.md: it states the rules of the game, and every rule must be earned by a shipped rung
and cite where it is defined or where it fired. None may be aspirational.

Ground truth (read first, ground every rule against these):
- .claude/commands/x.md — the LAWS (LAW-1, LAW-1a, LAW-2, LAW-3, LAW-4) and the FAKE-N / V-SOLO family, the
  audit ledger, and the pathspec/single-commit discipline.
- .claude/commands/reconcile.md — the delta taxonomy (MATCH/STALE/INVENTED/MISSING/DEFERRED) and the verdict.
- .claude/agents/venus.md, mars.md, apollo.md — the steward, implementor, and verifier charters and their
  guardrails (the fences, the anti-rubber-stamp verdict charter, the propose-only charter-edit channel).
- docs/elixir/specs/phoenix/phoenix.operator.md and f6.progress.md — the operator's field manual, the
  retrospective form, and the mentoring ledger.
- docs/elixir/specs/specs.approach.md — the forward contract: LINK it for the spec-system gate set, the
  templates, the traceability chain, and the completion rule; never restate any of them here.

Write these sections, in order: How to read these rules (rules are imperative; named sources are the defining
authorities; code-form paths name tool-configuration sources; links point only at documents) · The roles and
their fences (a table of Operator, Director, spec-steward, implementor, verifier, fan-out authors, researchers
with Owns / Edits / Never, then the guardrail rule: a recurring finding becomes one named charter line; sharpen
a mis-worded line, never stack a second; aim it at the peer whose CONTRACT the finding implicates) · The two
formations (the lead-team six-stage pipeline for code; the fan-out senior-author-then-parallel-apply for content
and specs; one game, two formations; a reverse run composes both) · The events: rules of the cadence (the rung
pipeline gates; the lag-1 reconcile as an executable gate with [RECONCILE] deferral markers; md-first
checkpointing; concurrency asymmetry with the under-contention failures; concurrent-wave siblings not
cross-linked; standing runtime state lives in the Operator session or the deploy; pathspec commit rules) · The
LAWS: LAW-2 - all perrs runs opus model and the lead-team spawns specialized true Team Agents joining team peers with the charter applied via
prompt, the law's intent stands and awaits Operator revision; state LAW-3 and the FAKE-N / V-SOLO family; a
paraphrased rule is not quote-marked) · The gates (a check counts only if it RUNS, with the tier-climb
corollary; the verifier reproduces the gate and audits its own harness; the anti-rubber-stamp verdict charter;
gate sets owned by their deliverable and referenced not restated; the voice rule — point at the forbidden set
defined in this very document as the one authority, and do not list it twice) · The two directions and the
delta taxonomy (the taxonomy table with one resolution each; direction-dependent canonicality — pre-build the
spec wins, post-build the code wins on surface facts, reverse begins MISSING; the BUILD-GRADE/BLOCKED verdict;
the deterministic core is unrationalizable) · Feedback, mentoring, and the retrospective (feedback edits the
spec; process feedback edits the agent definition under an Operator grant, the harness fences self-modification;
the per-rung retrospective sub-sections; dashboards report, specs define) · Decisions (named decisions in the
roadmap; the Operator's absolute decision rights; an agent stops and surfaces an unsettled fork) · References.

Discipline: one authority per fact. The templates, the traceability chain, and the completion rule stay in
specs.approach.md (link them). Gate lists are owned by their deliverable and referenced, never restated. A
divergence from a law is a dated note, never a silent rewrite.

Gates before reporting: structure (the sections above present) · voice (no forbidden words, no first person
outside a quoted story form, no perceptual or interior-state verbs on software) · fences balanced · every
relative link resolves from docs/aaw/ · each one-line law diffs character-for-character against its source ·
no gate list or template is copy-pasteable from specs.approach.md. Never run git.
```

Spec: ./aaw2.md · Stories: ./aaw2.stories.md · Index: ./aaw.md · Approach: ../elixir/specs/specs.approach.md
