# emq-design · Venus-1 + Venus-2 with cross review execution design team + Apollo Agent Independent Evaluation 

## {emq-design-decisions} Decisions (audit trail — hand-written; aaw tool_x_decision unavailable this session)

### D-1 — Formation: real spawned peers without the aaw registration ceremony

The aaw MCP server disconnected this session (all `mcp__aaw__*` tools absent from the registry).
Per `docs/aaw/aaw.rules.md` "Formation availability" (earned 2026-06-10, the first reverse run), the
team runs as real spawned peer agents — separate execution contexts under their charters, the
Director holding every stage gate — and this record IS the honest formation note. No registration is
claimed. The audit trail lands as plain markdown in this directory instead of via `tool_x_*`.

### D-2 — One shared brief, by construction

Venus-1 and Venus-2 receive IDENTICAL locked-constraints briefs by reading the SAME runbook file
(`docs/echomq/specs/emq/emq.design.prompt.md`) rather than two hand-retyped copies — identical-by-
construction, no transcription drift. The prompts differ ONLY in: codename, leading lens
(Venus-1 = wire/protocol-first; Venus-2 = conformance/operations-first), deliverable filename, and
the sibling-file prohibition target.

### D-3 — One Venus identity per seat across D1→D2

Stage D2 (cross-review) resumes the SAME Venus-1/Venus-2 instances via SendMessage (context intact),
never fresh spawns — the registry-honesty pattern the build pipeline uses for Mars-1→Mars-2 ("one
Mars identity, two passes"), applied to the design formation.

### D-4 — Stage gates this run

D1 gate: both design files on disk + locked-fork greps clean (INV-A/C) before any cross-review
instruction. D2 gate: both reviews on disk. D3 gate: Apollo's evaluation carries the design-shaped
charter (convergence/divergence table, ADR completeness, constraint fidelity, echo-chamber probe,
synthesis recommendation). D4: Director synthesis written, then FULL STOP for the Operator — no D5
work, no spec edits, no code, regardless of verdict quality.

### D-5 — Seat resume across session death: fresh spawn re-derives the seat from its durable design file

Supersedes D-3's MECHANISM for this restart while preserving its INTENT (one Venus identity per seat). The Venus-2 seat is resumed by a fresh `general-purpose` spawn under the venus.md charter that re-derives the seat's positions by reading `design/venus-2.md` in full before reading the sibling — the durable artifact, not the dead instance, carries the seat. The spawn registers as Venus-2 (architect) under the live ceremony; the registry honestly shows this session's spawn, and this entry records that the D1 design was authored by the seat's PRIOR instance. Independence fences ride in the prompt: no read of `venus-1.review-of-venus-2.md` or this ledger before the review lands (INV-H); no edits to any existing file (INV-G); engine claims cited to official docs; no git.

## {emq-design-progress} · Progress (audit trail — hand-written; aaw tool_x_progress unavailable this session)

### P-1 — Stage D1 CLOSED, gate green (2026-06-10 ~22:05)

Both independent designs on disk and reported:
- `design/venus-1.md` — 966 lines, 20 ADRs, wire/protocol-first. Fork surfaced: v1-side fence vs
  freeze strictness (1.3.x fence-only patch vs strict freeze). 13 engine facts cited.
- `design/venus-2.md` — 959 lines, 16 ADRs, conformance/operations-first. Forks surfaced: F-1
  (same v1 fence/freeze fork — independently converged) + F-2 (matrix re-run cadence). 14 engine
  facts cited. Corrected a runbook input fact: `priv/emq_scripts/` + `lib/echomq/ext/` are ABSENT
  from the tree, not "empty" (strengthens the single-bundle decision).

Gate evidence: INV-A both files on disk (ls). INV-C locked-fork greps — all six signals present in
both; re-litigation probes zero hits; the lens split is visible in the hit distribution (venus-1
39× `emq:{q}`/41× `declared`; venus-2 14× `conformance truth`). INV-E tree delta — the team's
footprint is exactly `dev/tasks/` + `docs/echomq/specs/emq/design/`; operator out-of-band activity
(`.mcp.json` cclin→aaw rename, `apps/echomq-go/` staged deletions, `dev/plans/aaw-plan.md`) is
disjoint from the team's writes. Both reports assert no sibling read (Apollo probes this at D3).

Divergences visible at the gate (the D2 attention list, resolution deferred to D2/D3/D4):
1. Job identity — venus-1 ADR-4 replaces the per-queue counter with Snowflake ids; venus-2 keeps
   counter continuity through migration (ADR-11) and ratifies the v1 id conventions (ADR-12).
2. Caller-brace handling — venus-1 ADR-2 idempotent single-level unwrap; venus-2 ADR-8 REJECT
   (normalization aliases "orders"/"{orders}" silently — a recorded redesign of emq.1.md's line).
3. `{emq}:` cross-queue inventory — venus-1: queues registry + node-ids lease; venus-2: bundle +
   migration journal, node registry reserved-by-name unpopulated.
4. Engine-floor semantics — venus-1 ADR-13 documented plain-Redis ≥7.2 line; venus-2 ADR-4 fixed
   7.0-level command CEILING + computed floor (≈6.2) + deprecated-form modernization (LMOVE).
5. LMPOP/ZMPOP — venus-1 ADR-11 pre-cleared + earmarked for emq.3 batch fetch; venus-2 ADR-16
   rejected (client-side pop bypasses the script layer's bookkeeping).

Convergences visible at the gate: FUNCTION rejected for v2 (Dragonfly FCALL/FUNCTION* unsupported,
both verified the same compat page); EVALSHA + NOSCRIPT self-heal ratified; hash-field TTL real on
Valkey 9.x (HEXPIRE "Since: 9.0.0") yet excluded/deferred from the 2.0 core (close grounds);
Valkey current stable pinned 9.1.0 by both; per-queue events stream kept, SSUBSCRIBE deferred;
echomq-node held at `proposed`; the SAME v1 fence/freeze fork surfaced by both → Operator at D4.

D2 launched: cross-review, same Venus identities resumed via SendMessage (decision D-3).

### P-2 — The aaw server is live; this entry is tool-written (2026-06-10 ~23:50)

The minimal aaw MCP server (apps/aaw, 2.0.0-min) shipped mid-run and now serves this scope: this is
the FIRST tool-written entry in a ledger whose P-1/T-1/D-1…D-4/L-1 were hand-written under the
Formation-availability provision — the parse-compatibility gate (proposal §8) passing on the live
exemplar. Run state at this entry: stage D2 (cross-review) was in flight when the session restarted;
the D1 designs (venus-1.md, venus-2.md) are on disk and gate-verified; the D2 review files and the
D3 Apollo evaluation are pending re-drive in the restarted session.

### P-3 — Resume declared: Flat-L2 Design Phase re-entered at D2-completion (2026-06-11)

Mode re-declared: Flat-L2 — Design Phase variant (x.md §12 / x-mode §2b), RESUMED. First run of this scope with the full aaw ceremony live: director spawned + registered (`ccl-emq-design-1`), team `emq-design` created, fake_n_signal false. Remaining stages: D2-completion (Venus-2 → venus-2.review-of-venus-1.md) → D3 (Apollo → apollo.evaluation.md) → D4 (Director synthesis emq.design.md + Z-n, then FULL STOP for Operator approval). D5 stays post-approval. Git: NONE this run (runbook lock; Operator commits out-of-band — design artifacts already committed at HEAD, foreign dragonfly files pre-staged in the index, untouched).

# {emq-design-thinking} · Thinking (audit trail — hand-written; aaw tool_x_trace unavailable this session)

### T-1 — UNDERSTAND/EXPAND: the §0 derivation (2026-06-10)

**Mode:** Flat-L2 — Design Phase variant (x.md §12 / x-mode skill §2b). Runbook:
`docs/echomq/specs/emq/emq.design.prompt.md` (read; authoritative scope).

**5W.**
- Who: Director (main session) + Venus-1 ∥ Venus-2 (independent architects, general-purpose spawns
  adopting `.claude/agents/venus.md` incl. its Design Phase section) + Apollo (design evaluator,
  stage D3) + the Operator (jonny — the D4 approval gate). Mars does not spawn.
- What: the EchoMQ 2.0 architectural design + ADR set, re-founding the `emq.*` system spec the
  orchestrator-solo rewrite (V-SOLO-4) produced without design or ADR. Deliverables this run:
  `docs/echomq/specs/emq/design/venus-1.md`, `…/venus-2.md`, two cross-reviews,
  `…/apollo.evaluation.md`, the Director synthesis `…/emq.design.md` — then STOP for Operator
  approval. Stage D5 (rewriting emq.md, the emq.1–6 triads, echomq.v2-frame.md) is post-approval
  only.
- Where: new files under `docs/echomq/specs/emq/design/` + this audit dir. Zero edits elsewhere.
- When: now; D5 gated on explicit Operator feedback.
- Why: the 2026-06-10 remediation directive — system specs are team deliverables; the design phase
  was skipped; no v2 code exists yet (verified: `priv/emq_scripts/` and `lib/echomq/ext/` absent),
  so the design can still precede all code.

**Solution space.**
- A. Run D0–D5 in one pass — REJECTED: D5 is post-approval by construction; the Operator gate is
  the remediation's point.
- B. Run D0–D4 now, hold at the Operator approval gate — SELECTED (the runbook's own shape).
- C. Wait for the aaw server to reconnect — REJECTED: `docs/aaw/aaw.rules.md` "Formation
  availability" covers exactly this (real spawns without registration ceremony, recorded honestly);
  the Operator invoked the run twice; substance over ceremony.
- D. Director authors the design solo — REJECTED: V-SOLO-4, the violation under remediation.

**Invariants → runnable checks.**
- INV-A both designs on disk before any cross-review: `ls docs/echomq/specs/emq/design/`.
- INV-B independence: prompts forbid reading the sibling file; Apollo probes for cross-contamination.
- INV-C locked forks honored verbatim: grep each design for the emq prefix, the Valkey conformance
  truth, Dragonfly-as-performance-target; any re-litigation BLOCKS.
- INV-D engine claims cited: every Valkey/Dragonfly/Redis capability carries an official-docs URL.
- INV-E no implementation files touched: `git status --short` shows only `design/*` + `dev/tasks/*`.
- INV-F Director writes process records + the D4 synthesis only (the runbook assigns the synthesis
  to the Director; LAW-1a guards implementation files, and none are in scope).

**Reductive minimization.** D0–D4 create ONLY new files under `design/` + audit notes; the existing
spec tree is untouched until the approved design licenses D5.

**Stage-1 gate reachability.** The runbook exists; its six settled forks are Operator decisions
(no open fork rides in); the open questions are explicitly assigned to the Venuses. Gate reachable.

### T-2 — RESUME derivation: the run re-enters at D2-completion (2026-06-11, fresh session, full aaw ceremony live)

**Inputs.** The runbook (emq.design.prompt.md, re-read); this ledger's P-1/P-2 (the prior session's stage record); the design dir listing; git state; x.md §12; venus.md Design Phase section; apollo.md design-evaluation charter.

**State derived.** D1 CLOSED green per P-1 (venus-1.md 966 lines/20 ADRs + venus-2.md 959 lines/16 ADRs, both complete with D1 sign-off lines, tails verified). D2 HALF-DONE: `venus-1.review-of-venus-2.md` on disk, complete, signed; `venus-2.review-of-venus-1.md` ABSENT — the session restart (P-2) killed the Venus-2 instance mid-stage. D3 (apollo.evaluation.md) and D4 (emq.design.md) never ran. Git: the four design artifacts are committed at HEAD by the Operator out-of-band; foreign dragonfly-chapter files sit pre-staged in the index — reinforcing the runbook's git-NONE rule for this run.

**The D-3 problem.** Decision D-3 (resume the SAME Venus instances via SendMessage) is unsatisfiable: the prior execution contexts died with the session; the team registry is session-ephemeral. Solution space for the vacant Venus-2 seat:
- A. SendMessage to the old instance — impossible; no such teammate exists in this session.
- B. Fresh spawn ADOPTING the Venus-2 seat: context re-derives from the seat's own durable design file (venus-2.md) + the runbook, then reads venus-1.md and writes the review — SELECTED. The design document is the seat's durable context; the review grounds in what the document argues, not in dead working memory. Recorded honestly as D-5.
- C. Skip the second review (asymmetric D2) — REJECTED: the runbook's D2 gate is both reviews on disk; the conformance-lens audit of the wire-first design is half the cross-review's value.
- D. Fold the missing review into Apollo's D3 — REJECTED: collapses two perspectives into one context (echo-chamber by construction); the review is a Venus deliverable per the runbook.

**Invariants carried + added.** INV-A..F (T-1) stand. INV-G added: the fresh Venus-2 edits NOTHING — D2 writes exactly one new file (the review); venus-2.md is gate-frozen and committed at HEAD, so any edit is git-visible (check: `git status --short docs/echomq/specs/emq/design/` shows only the new review). INV-H added: review-level independence — Venus-2 reads neither the sibling's review nor this ledger (whose P-1 carries the Director's divergence attention-list) before its review is on disk; anchoring the review on the Director's list would propagate the Director's blind spots into the input Apollo treats as independent.

**Reductive minimization.** ONE fresh spawn (the Venus-2 seat), ONE new file; D1 is not re-run; Venus-1 takes no further action; then D3 (Apollo, fresh as always), then D4 synthesis + FULL STOP for the Operator. Pipeline named: the §12 Design Phase formation, resumed mid-flight.

### T-3

T — Venus-2 D2 derivation: cross-review of venus-1.md
INPUTS: runbook (locked forks §2 ride verbatim; open questions = workload); venus-2.md re-read IN FULL (960 lines, the seat's D1 positions); venus-1.md read IN FULL (967 lines, first sibling read — D2 lifts the D1 prohibition); as-built echo/apps/echomq re-read THIS SESSION at every anchor the review asserts (keys.ex:8,11,68-95; queue.ex:93,107-110,147,203,700-750; addStandardJob-9.lua:517-533; moveToActive-11.lua:9-30,145-165; moveToFinished-14.lua:23,460,846; retryJob-11.lua:8,17,172; echo_data/snowflake.ex:39-43; config/{config,test}.exs). Fences held: sibling review + ledger UNREAD before the review landed; one new file only; no git.
METHOD: (1) map ADR↔ADR across the two ledgers (16 vs 20) → 12 independent convergences = the confidence record (headline: BOTH seats independently re-purposed Dragonfly strict mode into the declared-keys runtime oracle). (2) For each divergence: steelman venus-1 first, then probe against (a) the locked-fork list, (b) cited engine facts, (c) as-built file:line read this turn — the no-invent rule applied to the REVIEW's own claims. (3) Re-verify the designs' SHARED factual substrate against primary sources rather than trusting either document — this is where the headline finding fired: both designs frame v1 as "the emq: keyspace"; the as-built default prefix is "bull" (keys.ex:11 + ten queue.ex callsites), configurable (test env "echomq_test"), so BOTH fences' v1-detection probes a namespace no stock v1 deployment writes (C-1, shared inherited defect — most plausibly absorbed from the draft prose both were told to treat as input-not-authority). (4) Classify each defeated venus-2 position as a CONCESSION (3: j: namespace, fence detection cluster, tool terminal delete) — recorded as D3/D4 input, venus-2.md untouched.
ALTERNATIVES WEIGHED: challenge-vs-graft for the j: namespace (resolved GRAFT+concession: the collision class is real in as-built — addStandardJob custom-id path has zero reserved-name validation — and grammatical classification IS a conformance capability, so the mirror baseline loses on the seat's own criterion); challenge-vs-accept for ADR-4 Snowflake (resolved CHALLENGE C-3 + fork F-A: the lease half is under-steelmanned — the missing alternative is config-assigned node ids, the as-built convention per snowflake.ex:39-43; identity switch spends fork risk budget on the hottest surface); accept-vs-challenge for the ≥7.2 Redis floor (resolved CHALLENGE C-5: WAITAOF is a probe instrument leaking into the user floor; the BSD-shelf reading is the salvageable steelman); whether the ADR-15/16 internal contradiction (boot reads emq:* sentinels while ADR-16 wields never-reads-emq:* absolutely) deserved its own challenge vs folding into C-1 (resolved: named inside C-2 — the contradiction is real AS WRITTEN and dissolves under C-1's prefix correction; the deeper defect is draft-prose-cited-as-LOCK, which D4's ledger must not inherit).
OUTPUT: venus-2.review-of-venus-1.md — 12 agreements (ADR pairs) / 7 challenges (C-1 prefix, C-2 phantom lock, C-3 Snowflake+lease, C-4 brace affordance, C-5 floor pin, C-6 {emq}:queues coherence, C-7 bundle layout) / 9 grafts (G-1 j:, G-2 fence detection, G-3 version semantics, G-4 manifest, G-5 Lua dialect — a genuine venus-2 GAP, G-6 KEYS-rooted derivation rule, G-7 copy-verify-DELETE+digest+cross-engine, G-8 emq.5 SSUBSCRIBE landing zone, G-9 --!df comment-form precision) / 3 concessions / forks F-A/F-B/F-C + convergent 1.3.1 + carried F-2. Verification gaps flagged for D3: d0.md/dragonfly.md ABSENT repo-wide (dangling runbook input; pattern re-verified against primary source, the 24–26/50 COUNT owed re-derivation); the DF lock_on_hashtags×undeclared-keys relaxation is a SHARED INFERENCE from a common source, unverifiable this session (dragonflydb.io unreachable) — convergence on it is not independent confirmation; settle empirically as emq.1's first dynamic act. No tool_x_decision written: D2 locks nothing.

## {emq-design-learnings} · Learnings (audit trail — hand-written; aaw tool_x_learning unavailable this session)

### L-1 — The aaw server disconnected mid-session, after availability was verified

The remediation session verified `mcp__aaw__*` present (deferred, loadable) and recorded that in
the runbook's D0 stage; by the time the Design Phase was invoked, the server had disconnected and the
tools left the registry. Two consequences recorded: (a) the runbook's "available, verified
2026-06-10" line is a point-in-time fact, not a standing guarantee — a D0 preflight must re-probe,
not trust the note; (b) the `docs/aaw/aaw.rules.md` "Formation availability" provision carried the
run — the second time in one day the provision is exercised, evidence it belongs in the rulebook
permanently. The original V-SOLO-4 incident plausibly shares this root cause (the pipeline's tooling
absent when the spec rewrite happened) — but tooling absence licenses a degraded FORMATION, never a
skipped PHASE; that distinction is the lesson.

### L-2 — The minimal server's scope index is read-once: out-of-band edits to .aaw/scopes.json diverge from server memory

Found at the first live verification (this entry is itself tool-written). The server loads
.aaw/scopes.json at boot and writes the full in-memory map back on every init — so a row removed
from the file while the server runs survives in memory and is resurrected by the next save
(observed: the aaw-selftest row, cleaned on disk post-boot, still reported by probe). The
files-are-truth rule (proposal R-1) therefore holds for the LEDGER but not yet for the INDEX. Fix
candidates for the Design Phase: re-read-merge before save, or mtime-checked reload, or treat the
index as server-owned state exempted from R-1 explicitly. Until then: edit scopes.json only with
the server stopped.