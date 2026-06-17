# AAW4 · agent brief (llms)
> Reconcile-and-hardening brief for the validation run. References, traced requirements, the run topology, and a
> paste-ready prompt. Pairs with the spec aaw4.md and the stories aaw4.stories.md. This rung executes the
> reverse playbook rather than building a feature; the prompt records the run recipe end-to-end.

## References
- [aaw4.md](aaw4.md) + [aaw4.stories.md](aaw4.stories.md) — the contract and its acceptance.
- [aaw.reverse.md](aaw.reverse.md) — the seven-stage playbook this run executes, the re-keyed triad template,
  and the four added gates (grounding · no-invent · exact-arity · `file:line`-resolves).
- [aaw.rules.md](aaw.rules.md) — the two formations, the commit rules, the delta taxonomy, the voice rule.
- [specs.approach.md](../elixir/specs/specs.approach.md) — the forward contract owning the triad templates,
  the traceability chain, and the standard six gates.
- The verification target, in code form: `echo/apps/echomq` — `lib/` (the subsystem modules: `keys.ex`,
  `job.ex`, `scripts.ex`, `worker.ex`, `lock_manager.ex`, `queue.ex`, `job_scheduler.ex`, `flow_producer.ex`,
  `queue_events.ex`, `cancellation_token.ex`, `stalled_checker.ex`, `backoff.ex`, `telemetry.ex`),
  `priv/scripts/` (the 50 Lua scripts), `test/` (the suite).
- The chapter the run produces, in code form (the directory `docs/echomq/specs/core/` is empty at the start of
  this rung — every reference to it stays in code form, never a link): `core.md`, `core.roadmap.md`,
  `core.progress.md`, the triads `c1`–`c7`, and the hardening runbook `core.h1.prompt.md`.

## Requirements
- **AAW4-R1** — `docs/echomq/specs/core/` carries `core.md` (the as-built ladder C1–C7, the library-intrinsic
  master invariant, the rate-limiting cross-cutting invariant, the as-shipped error vocabulary),
  `core.roadmap.md` (the reconcile-and-harden plan with its iteration table), and `core.progress.md` (the
  durable record). [US: AAW4-US1]
- **AAW4-R2** — seven triads `c1`–`c7` exist on the re-keyed reverse template, one per subsystem, each with a
  `Deliverables (Surfaces — as-built)` section and a `Definition of Done (Verification)` section. [US: AAW4-US1]
- **AAW4-R3** — every surface in every triad is cited as `Module.fun/arity` with its `file:line`, and the four
  reverse gates pass for the triad — no invented surface, exact arity from the `def` site, resolvable
  location. [US: AAW4-US2]
- **AAW4-R4** — rate limiting is recorded as a cross-cutting invariant on `core.md`, not as a rung: it is
  implemented as threads through `worker.ex`, `queue.ex`, `keys.ex`, and the Lua (`getRateLimitTtl-2.lua`),
  with no `RateLimiter` module in `lib/`. [US: AAW4-US2]
- **AAW4-R5** — the target is recorded as v1.3.0, Elixir `~> 1.18`, library-only: `mix.exs` declares
  `extra_applications` only and no `mod:`, so the host supervises and `core.md`'s master invariant is
  library-intrinsic. [US: AAW4-US2]
- **AAW4-R6** — each invariant in `c1`–`c7` maps in `core.progress.md` to a running check (cited `file:line`,
  property, or tag) or to an explicit recorded gap; no invariant is left unmapped. [US: AAW4-US2]
- **AAW4-R7** — two independent experts re-verify every triad; convergence is the bar, and every INVENTED,
  STALE, or MISSING finding is a delta-taxonomy entry in `core.progress.md`, looping INVENTED/STALE back to
  re-authoring before hardening. [US: AAW4-US4]
- **AAW4-R8** — no intent-level divergence is silently synced; an as-built surface that looks wrong on purpose
  is surfaced to the Operator as a recorded delta, never corrected in the spec or the code. [US: AAW4-US4]
- **AAW4-R9** — the hardening closes the chosen gaps: the four untagged concurrency test files plus the
  untagged stress file that hang a plain `mix test` (the default exclude is `[:integration, :slow]`), missing
  property tests, doc-comment defects, and any genuinely failing invariant — each rung gated and verdict-graded
  by the lead-team. [US: AAW4-US2]
- **AAW4-R10** — formation discipline holds: the fan-out stages run no git and are committed out-of-band by the
  Operator; each lead-team hardening rung closes with exactly one Director pathspec commit scoped to the echo
  tree (no `git add -A`, no bare commit). [US: AAW4-US3]

## Execution topology
Runtime (the run's stage and formation topology):
```text
stage 1 survey (researchers, read-only, banked)   stage 2 ladder (orchestrator, never delegated)
                          \                                /
                 stage 3 senior instruments (orchestrator): core.md · core.roadmap.md · core.progress.md · exemplar triad
                          |
                 stage 4 triad fan-out (authors, <=2 concurrent, heaviest alone): c1..c7      [FAN-OUT — no git]
                          |
                 stage 5 adversarial verification (two experts, read-only): deltas -> core.progress.md
                          |   (INVENTED/STALE loops back to stage 4 before any hardening)
                 stage 6 invariant->check hardening (LEAD-TEAM on echo/apps/echomq):
                          steward brief -> implementor build -> harden -> verifier verdict -> Director ratify+commit
                          |   (one Director pathspec commit per rung, echo tree only)
                 stage 7 fold-back (orchestrator): aaw.reverse.md + aaw.rules.md; flip aaw.md row -> built
```
Tasks (the seven playbook stages instantiated for echomq):
```text
1. survey echo/apps/echomq          (BANKED: module->fun/arity->file:line; 50 Lua scripts; 30-file suite + tags)
2. cut the ladder                   (C1 keys+protocol/Lua floor · C2 job · C3 scripts · C4 worker+lock ·
                                      C5 queue facade · C6 scheduling+flows · C7 events+cancellation+stalled+backoff+telemetry;
                                      rate limiting = cross-cutting invariant, NOT a rung)
3. author core.md + core.roadmap.md + core.progress.md + the exemplar triad   (AAW4-D1; orchestrator)
4. fan out c1..c7 from grounded briefs   (AAW4-D2; <=2 concurrent, heaviest alone; gates per triad; no git)
5. two experts re-verify; record deltas; loop INVENTED/STALE back   (AAW4-D3; convergence the bar)
6. write the invariant->check table (md-first); author core.h1.prompt.md; run the lead-team on the gaps
                                      (AAW4-D4; one Director pathspec commit per rung)
7. fold findings into aaw.reverse.md + aaw.rules.md; flip the aaw.md row to built   (AAW4-D5)
```
Touched files: `docs/echomq/specs/core/core.md`, `docs/echomq/specs/core/core.roadmap.md`,
`docs/echomq/specs/core/core.progress.md`, `docs/echomq/specs/core/c1.md` … `c7.md` (each with its
`.stories.md` and `.llms.md`), `docs/echomq/specs/core/core.h1.prompt.md`; the hardening rungs touch
`echo/apps/echomq/test/` (and `lib/` only inside a lead-team rung); the fold-back touches
[aaw.reverse.md](aaw.reverse.md), [aaw.rules.md](aaw.rules.md), and [aaw.md](aaw.md).

## Agent stories
- **AAW4-AS1** [implements AAW4-US1] — Directive: author the chapter instruments — `core.md` (ladder C1–C7,
  the library-intrinsic master invariant, the rate-limiting cross-cutting invariant, the as-shipped error
  vocabulary), `core.roadmap.md` (the reconcile-and-harden plan with its iteration table), `core.progress.md`
  (the durable record) — and the exemplar triad the fan-out copies. Acceptance gate: all four instruments
  present; standard six gates green; the ladder cites only verified-inventory modules (AAW4-R1, AAW4-R5).
- **AAW4-AS2** [implements AAW4-US2] — Directive: fan out `c1`–`c7` at most two concurrent with the heaviest
  rung alone, each author citing every surface as `Module.fun/arity` with its `file:line` and recording rate
  limiting as the cross-cutting invariant, not a rung. Acceptance gate: every triad passes the four reverse
  gates; rate limiting appears as an invariant on `core.md` with no `RateLimiter` module cited (AAW4-R3,
  AAW4-R4).
- **AAW4-AS3** [implements AAW4-US4] — Directive: run two independent experts over every triad; record each
  finding as a delta-taxonomy entry in `core.progress.md`; loop INVENTED/STALE back to re-authoring before any
  hardening; surface intent-level doubts to the Operator. Acceptance gate: convergence reached on every triad;
  no intent-level divergence silently synced (AAW4-R7, AAW4-R8).
- **AAW4-AS4** [implements AAW4-US2] — Directive: write the invariant→check table md-first into
  `core.progress.md`, mapping every invariant in `c1`–`c7` to a running check (`file:line`, property, tag) or
  an explicit gap. Acceptance gate: no invariant left unmapped; each cited check resolves in `echo/apps/echomq`
  (AAW4-R6).
- **AAW4-AS5** [implements AAW4-US3] — Directive: author `core.h1.prompt.md` and run the lead-team on the
  chosen gaps — the four untagged concurrency files plus the untagged stress file, missing property tests,
  doc-comment defects, any failing invariant — each rung gated, verdict-graded, and closed by one Director
  pathspec commit on the echo tree. Acceptance gate: the chosen gaps closed; one scoped commit per rung; no
  `git add -A`, no bare commit (AAW4-R9, AAW4-R10).
- **AAW4-AS6** [implements AAW4-US1] — Directive: fold the run's findings into `aaw.reverse.md` and
  `aaw.rules.md` as inspect-and-adapt edits, then flip the AAW4 row in `aaw.md` from `in progress` to `built`.
  Acceptance gate: the fold-back edits land; the index row reads `built`; links resolve (AAW4-R1, the run's
  closure).

## Execution plan — first two stories
1. **AAW4-AS1 — author the chapter instruments.** From the banked survey, cut the ladder (orchestrator), then
   write `docs/echomq/specs/core/core.md`, `core.roadmap.md`, `core.progress.md`, and the exemplar triad;
   record rate limiting as a cross-cutting invariant and the target as v1.3.0 library-only; run the six gates.
2. **AAW4-AS2 — fan out the triads.** Hand each author a grounded brief (verified inventory only); fan out
   `c1`–`c7` at most two concurrent with the heaviest alone; each cites every surface as `Module.fun/arity` —
   `file:line`; run the four reverse gates per triad; no git in this stage.

## Comprehensive implementation prompt
```text
You are running the AAW reverse playbook (rung AAW4) end-to-end against the production library
echo/apps/echomq, producing the retrospective spec chapter docs/echomq/specs/core/ and a hardening pass.
The playbook is docs/aaw/aaw.reverse.md; the formations and commit rules are docs/aaw/aaw.rules.md; the
triad templates and standard gates are docs/elixir/specs/specs.approach.md. The code wins on every as-built
surface fact; the spec records, it never redesigns.

Ground truth (verify in the tree, never from a prose table — the brief is not exempt from no-invent):
echo/apps/echomq is v1.3.0, Elixir ~> 1.18, library-only (mix.exs has extra_applications only and no mod: —
the host supervises). 50 Lua scripts live under priv/scripts/ whose filename suffix -N is the script's KEYS
count. Rate limiting is threads through worker.ex, queue.ex, keys.ex, and getRateLimitTtl-2.lua with NO
RateLimiter module — so it is a CROSS-CUTTING INVARIANT on core.md, not a rung. The test suite excludes
[:integration, :slow] by default; the four concurrency files and one stress file carry no exclusion tag and
hang a plain mix test; integration tests need a live Redis (REDIS_URL).

Stage 1 (survey) is already banked — module -> public function -> arity -> file:line -> one-line behavior,
plus the scripts/keys/test taxonomies. Treat it as evidence, not truth: re-probe any claim a verifier
contradicts.

Stage 2 (ladder — orchestrator, never delegated). Cut the as-built tree into seven rungs: C1 keys + the
protocol/Lua floor · C2 the job model · C3 the scripts execution layer · C4 the worker + the lock · C5 the
queue facade · C6 scheduling + flows · C7 events + cancellation + stalled checker + backoff + telemetry. A
cross-cutting concern (rate limiting) gets a named invariant on the index, not a rung.

Stage 3 (senior instruments — orchestrator). Author core.md (the ladder, the library-intrinsic master
invariant, the rate-limiting cross-cutting invariant, the as-shipped error vocabulary, per-rung abstracts),
core.roadmap.md (the reconcile-and-harden plan + iteration table), core.progress.md (the durable record: it
carries the verification notes, the delta records, and the invariant->check table), and the exemplar triad
the fan-out copies. Gates: voice/structure/fences/links.

Stage 4 (triad fan-out — at most two concurrent, the heaviest rung alone, NO git). Each author applies the
exemplar template to a fixed grounded brief and cites every surface as Module.fun/arity with its file:line.
Run the four reverse gates per triad: grounding (the artifact exists), no-invent (no surface absent from the
inventory), exact-arity (read from the def site), file:line-resolves.

Stage 5 (adversarial verification — two independent experts, read-only). Re-verify every triad; convergence
is the bar; a disagreement is probed in source. Record findings as delta-taxonomy entries in
core.progress.md; loop any INVENTED or STALE back to stage 4 BEFORE any hardening. Surface an intent-level
doubt to the Operator as a recorded delta; never silently sync it.

Stage 6 (invariant->check hardening — LEAD-TEAM on echo/apps/echomq). First md-first: write the
invariant->check table (every invariant x its check: test file:line, property, or tag — or the explicit gap).
Triage the gaps with the Operator (scope is the Operator's call, made before this stage). Author
core.h1.prompt.md (the lead-team runbook). Run the lead-team pipeline (steward brief -> implementor build ->
harden -> verifier verdict -> Director ratify+commit) until the chosen gaps close: tag or split the four
untagged concurrency files and the untagged stress file so a plain mix test is green, add the missing property
tests, fix the doc-comment defects, and treat any genuinely failing invariant as a defect finding (Operator
decides fix-now or record-and-defer). Each hardening rung is gated, verdict-graded, and closed by ONE Director
pathspec commit scoped to the echo tree.

Stage 7 (fold-back — orchestrator). Fold the run's findings into aaw.reverse.md and aaw.rules.md as
inspect-and-adapt edits, then flip the AAW4 row in aaw.md from `in progress` to `built`.

Gates throughout: the standard six (voice · structure · traceability · fences · links · format) on every
spec file, plus the four reverse gates on every triad, plus the lead-team's own gates (compile, scoped tests,
verdict) on each hardening rung. Git discipline: the fan-out stages (1-5, 7) run NO git — the Operator
commits batches out-of-band; only the lead-team hardening rungs commit, one Director pathspec commit each.
```

Spec: ./aaw4.md · Stories: ./aaw4.stories.md · Index: ./aaw.md · Approach: ../elixir/specs/specs.approach.md
