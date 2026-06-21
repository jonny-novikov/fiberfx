# emq-5-3 — AAW scope ledger

## {emq-5-3-thinking} Thinking

### T-1 — emq.5.3 §0 derivation (the grouped batch: affinity + concurrency + dynamic rate)

WHAT: the GROUP-AWARE batch — `@gbclaim` (a homogeneous lane-scoped batch claim, a NEW additive Lua script beside `@gwclaim` in lanes.ex) + a manual-pull host API (`Lanes.bclaim/N`), composing the SHIPPED 5.1 flat-batch spine (`@bclaim`) with the CLOSED emq.4 fairness ring (`@gclaim`/`@gwclaim`/`gactive`/`gweight`/`glimit`).
WHY: 5.1 gave a flat-set batch (over `emq:{q}:pending`); 5.2 gave it a cadence. Neither is group-aware — a flat batch crosses groups, bypassing the ring's per-group concurrency accounting. 5.3 makes the batch AFFINITY-respecting: drawn from a SINGLE group, counted against that group's ceiling, so bulk consumption coexists with fair lanes.
DO-NOTHING BASELINE: client-side per-group filtering of `@bclaim`'s flat batch — REJECTED (bypasses the ring's gactive accounting; the design §6.2 client-pop anti-pattern).
FORKS (ruled via AskUserQuestion BEFORE the build):
- FORK 5.3-A (RISK-DECIDING): additive `@gbclaim` (NORMAL+, `@gwclaim`/`@gclaim` byte-frozen) VS extend `@gwclaim` to a batch-return (HIGH — edits a frozen fairness script, forces byte-freeze of every lane script + Apollo MANDATORY). Lean: additive.
- FORK 5.3-B: reuse `gactive` (a batch counts as its `size` against the group ceiling) VS a new `gbatch` in-flight counter. Lean: reuse `gactive` (no new key, §6 grammar unedited).
INVARIANTS (runnable checks): INV-Affinity (every member from the served group — homogeneous) · INV-Ceiling (`gactive += actual count`; NEVER past `glimit` — the @gwclaim:75 ceiling discipline; a lane at ceiling is de-ringed) · INV-ServerClock (one TIME, one batch lease — the @gclaim:50-52 pattern, INV4) · INV-DeclaredKeys (the lane base pins the {q} slot; gactive/gweight/gpending ARGV-rooted on the declared base — the A-1/L-1 law) · INV-Frozen (`@gwclaim`/`@gclaim`/`@gweight` byte-frozen; grep redis.call on those = 0) · INV-Determinism (a MINT/LEASE surface → the ≥100 loop, the same-ms branded-JOB hazard) · the emq.4.4-L1 carry (a fair-share property needs a bounded-early-window INTERLEAVING witness, not a terminal drain).
SMALLEST CHANGE: one additive Lua (`@gbclaim`) + one host API + additive-minor conformance scenario(s) + reuse `gactive`. No new key, no frozen-script edit, no wire edit.
RISK: NORMAL+ → Director verify deepens (declared-keys + byte-freeze battery on the new lane script + the ≥100 loop); Apollo RECOMMENDED (the fair-lanes composition risk). Mode: Flat-L2.
NEXT: TeamDelete emq-5-2 (members shutting down) → TeamCreate emq-5-3 → Venus authors the 5.3 triad + lag-1 reconcile + frames forks → AskUserQuestion rules 5.3-A/5.3-B → Mars build.

### T-2

T-Mars-1 — build plan derived from ground truth (lag-0 re-probe)

GROUND TRUTH (re-probed, lanes.ex/conformance.ex/tests):
- @gwclaim (lanes.ex:87-129) is the near-isomorph: LMOVE ring step → ZCARD depth → k=min(w,depth,glimit headroom) → ONE TIME → for-loop ZPOPMIN×k leasing each on `now+lease_ms` → gactive+=k → post-incr re-ring guard (act>=lim OR ZCARD==0 → LREM). wclaim/3 (lanes.ex:281-294): pause-first, eval, {:ok,[]}→:empty / list→Enum.map(&List.to_tuple/1).
- @gclaim (lanes.ex:37-61) byte-frozen; KEYS=[ring,active], ARGV=[base, lease_ms]; lane=ARGV[1]..'g:'..g..':pending', gactive/glimit=ARGV[1]..'gactive'/'glimit' (ARGV-rooted on declared base, KEYS pin slot).
- Conformance: scenarios/0 = keyword list name:contract (conformance.ex:~90-156); dispatch defp apply_scenario(:name,conn,q). starvation_drill (1992-2073)=bounded-9-turn-early-window MapSet interleaving witness + per-member ZSCORE-active lease + terminal drain-to-0. weighted_proportion (1934-1990). batch_claim (2084-2130). reassign (1081-1125)/lane_drain (1127-1179) = grouped PRT lane setup + HGET gactive g assertions. helpers complete_all/good_rows_retired? take 3-tuple {id,_p,att} → my 4-tuple needs a 4-aware completer.
- Pins: conformance_run_test.exs:53 {:ok,67}; conformance_scenarios_test.exs:30-98 @run_order (67 names) + prose "sixty-seven". mix.exs:7 version "2.5.0" (5.1 set it; 5.2 host-process held it; 5.3 new-Lua → climbs 2.6.0). @wire_version echomq:2.4.2 FROZEN (connector.ex:35, not touched).

D-1 BINDING: 5.3-A additive @gbclaim · 5.3-B reuse gactive · 5.3-C ring-rotated bclaim/3 (NO caller group; served count = glimit headroom, the @gwclaim shape; K=min(headroom,ZCARD)). Fairness-witness acceptance (NOT affinity-isolation).

DELTA @gwclaim→@gbclaim: drop the gweight read; k = min(depth, glimit headroom) [no weight term]; headroom is the SOLE upper bound (a lane with no glimit set serves its whole depth — unbounded like @gwclaim's no-limit case). Everything else byte-identical: LMOVE, ONE TIME, for-loop lease, gactive+=k, re-ring guard, nested-array return {id,payload,att,g}.

SCENARIOS (67→70): grouped_batch_affinity (homogeneous — every member's row group == served group, members from g:<served>:pending only) · grouped_batch_ceiling (glimit=3, flood 8, EXACTLY 3 served, gactive==3==glimit, second claim :empty until complete frees headroom) · grouped_batch_fairness (emq.4.4-L1: skewed lanes, bounded-early-window interleaving MapSet witness — every light lane in early window + terminal drain-to-0).

## {emq-5-3-alternatives} Alternatives

### V-1 — FORK 5.3-C (NEW, surfaced by Venus at the reconcile): the group-selection mechanism. "Affinity" is ambiguous and the reconcile confirmed NO caller-named-group claim exists today (ring-rotate LMOVE is the ONLY group-selection — @gclaim/@gwclaim). Arm 1 RING-ROTATED (@gbclaim does the LMOVE like @gwclaim, serves whichever lane the rotation lands on; bclaim/3 + size; fairness preserved by construction; carries emq.4.4-L1; the direct @gwclaim isomorph — LEAN) vs Arm 2 CALLER-NAMED (@gbclaim takes a specific group, no LMOVE; bclaim/4 with group; true affinity; fairness is the caller's responsibility; the codemojex/echo_bot dedicated-worker pull model) vs Arm 3 BOTH. This is API-CONTRACT-DECIDING: it sets the bclaim/N arity AND selects the fairness vs isolation acceptance story (US-FAIRNESS interleaving witness under Arm 1 / US-ISOLATION named-lane-only under Arm 2). The Director rules via AskUserQuestion alongside 5.3-A/5.3-B BEFORE the build. Does NOT change the risk tier (both keep @gbclaim additive).



## {emq-5-3-decisions} Decisions

### D-1 — forks 5.3-A / 5.3-B / 5.3-C RULED (Operator, AskUserQuestion) — all to the lean arms

- **5.3-A (risk-deciding) → ADDITIVE `@gbclaim`.** A NEW inline `Script.new` in `lanes.ex` beside `@gwclaim`; every shipped `@g*`/`@bclaim` script BYTE-FROZEN. Risk tier = NORMAL+ (the HIGH arm — editing the frozen fairness script — is NOT taken). Apollo RECOMMENDED stands.
- **5.3-B → REUSE `gactive`.** A batch counts as its served `size` against the existing `gactive` ceiling; the `glimit` headroom clamp guarantees no batch passes the ceiling (INV-Ceiling). No new key; the §6 keyspace grammar unedited.
- **5.3-C (API-deciding) → RING-ROTATED `bclaim/3`.** `@gbclaim` rotates the ring (LMOVE) like `@gwclaim` and serves a homogeneous batch from whichever lane it lands on — fairness-by-construction (INV-Fairness, the emq.4.4-L1 interleaving witness), the direct `@gwclaim` isomorph, EXTENSIBLE to caller-named (Arm 2) later additively. The host verb takes NO caller group (`bclaim/3` per the body — the size is the glimit headroom, the `@gwclaim` shape). The acceptance story = the fairness interleaving-witness (NOT affinity-isolation).
All three == the body's written-to leans, so Venus's post-build Stage-5 sync is a cosmetic WITHHELD→RULED flip. The triad is BUILD-GRADE + link-clean (msh specs 246 files, 0 findings). Next: Mars builds to the body + these rulings; conformance 67 → 70 (affinity · ceiling · fairness-witness); the ≥100 determinism loop (MINT/LEASE); the declared-keys + byte-freeze battery on the new lane script.

### D-2 — the mix.exs rung label = 2.5.1, NOT Mars's 2.6.0 (the within-family patch convention)

Mars derived 2.6.0 (a MINOR bump) and flagged it for confirmation. The label ladder shows the convention: a rung WITHIN a family takes a PATCH bump (emq.4.3 → 2.4.3, emq.4.4 → 2.4.4); OPENING a family takes a MINOR bump (emq.4.4 `2.4.4` → emq.5.1 `2.5.0`, patch reset to 0). emq.5.3 is a rung within the emq.5 family (which started at 2.5.0 and HELD through 5.2) → the next substance climb is the PATCH `2.5.1`. A minor bump to 2.6.0 would mis-signal the emq.6 family (lifecycle controls), which does not exist. The wire `@wire_version` stays FROZEN at `echomq:2.4.2` (the two planes — the rung label is the documentary plane, read by nobody at runtime). RULING: **2.5.1.** Ruled by Director discretion (a documentary version convention, not a wire/API design fork — no AskUserQuestion needed; the changelog ladder is unambiguous). Mars-2 corrects mix.exs 2.6.0 → 2.5.1.

## {emq-5-3-progress} Progress

### P-1

P-Mars-1 — emq.5.3 BUILD complete, gates green, determinism loop running

BUILT (6 files, all ⊆ echo/apps/echo_mq):
- lanes.ex (+122 ins, 0 del): NEW @gbclaim inline Script.new (the @gwclaim isomorph — gweight read DROPPED, K=min(depth, glimit headroom), one TIME lease, gactive+=actual k, re-ring guard) + Lanes.bclaim/3 host verb (pause-first, {:ok,[{id,payload,att,group}]}|:empty).
- conformance.ex: +3 scenarios (grouped_batch_affinity / grouped_batch_ceiling / grouped_batch_fairness) + enqueue_lane/4 helper + run/2 moduledoc count 64→70 (the 64 was a pre-existing emq.5.2 lag — corrected while re-pinning).
- mix.exs: label 2.5.0→2.6.0 (roadmap-rung plane climbs — a new-Lua substance rung, the emq.5.1 precedent; @wire_version frozen echomq:2.4.2). REALIZATION-FLAG: the spec body said "the rung label climbs" without pinning a number; I derived 2.6.0 from the emq.5.1=2.5.0/emq.5.2-held-2.5.0 lineage — Director to confirm.
- conformance_run_test.exs / conformance_scenarios_test.exs: pin 67→70 ({:ok,70} + @run_order +3 names + prose).
- test/lanes_batch_test.exs (NEW): 11 focused :valkey unit tests for bclaim/3.

GATES GREEN (Valkey 6390, Erlang 28.5.0.1, TMPDIR=/tmp):
- compile --warnings-as-errors: clean (echo_data sibling-app warnings pre-existing, unrelated).
- mix test --include valkey: 9 doctests, 451 tests, 0 failures.
- Conformance.run → {:ok, 70} (CONFORMANCE 70/70; the 3 new scenarios CONF ok).
- BYTE-FREEZE PROVEN: git diff lib | grep redis.call = 16 added (ALL inside @gbclaim), 0 removed. lanes.ex 122 ins/0 del — every shipped @g*/@bclaim/@claim byte-identical to HEAD.
- DECLARED-KEYS PROVEN: @gbclaim keys = KEYS[1]=ring + KEYS[2]=active PIN the {q} slot; lane/gactive/glimit/job ARGV[1]-rooted on the declared base — one slot {q}, no key from a data value (A-1/L-1).
- MUTATION KILL-RATE 3/3 (SCRIPT FLUSH before each — EVALSHA-first trap): (1) headroom+1 over-pop → ceiling test RED; (2) re-rotate mid-loop cross-group leak → affinity unit + grouped_batch_affinity scenario RED; (3) k=depth+3 over-pop-beyond-depth → depth-bound test RED. All reverted net-zero by inverse Edit (NO git checkout); post-revert lib diff still 16/0.

RUNNING: the ≥100 determinism loop (120 iterations, mint/lease surface, owns the machine).
BOUNDARY: 0 changes outside echo/apps/echo_mq; echo_wire/echomq/mix.lock untouched; echo_graft/README.md M = Operator out-of-band (NOT mine).

## {emq-5-3-learnings} Learnings

### L-1

L-Mars-1 — the @gwclaim/@gbclaim loop body is BYTE-IDENTICAL (the isomorph is literal, not just conceptual)

When I attempted a mutation Edit on the @gbclaim ZPOPMIN loop, the Edit tool reported "Found 2 matches" — because @gwclaim and @gbclaim share the for-loop body VERBATIM (the pop/HINCRBY-attempts/HSET-active/ZADD-lease/tuple-build block). This is the strongest possible evidence the additive-isomorph ruling (D-1, FORK 5.3-A Arm 1) was sound: @gbclaim is @gwclaim with exactly ONE semantic line changed — `local k = depth` (the headroom-as-sole-bound) in place of @gwclaim's `local k = w` + the gweight read dropped. Everything else (LMOVE rota, ZCARD depth-guard, glimit headroom clamp, k<=0 de-ring, one TIME, the lease loop, gactive+=k, the post-increment re-ring guard) is byte-shared.

THE IMPLICATION for the mutation battery: a mutation anchored on a SHARED line cannot be applied to @gbclaim alone (the inverse-Edit would hit @gwclaim too — a frozen-script touch). The only @gbclaim-LOCAL anchor lines are `local depth = redis.call('ZCARD', lane)`, `local k = depth`, and the `att, g}` tuple tail. So mutation 3 (k=depth+3) had to anchor on `local k = depth` (unique), and mutation 2 (cross-group leak) had to rewrite the whole loop block with the unique `local k = depth` line as the leading context. Kill-rate 3/3 achieved this way; SCRIPT FLUSH before each (EVALSHA-first) was load-bearing. Folds into the implementor craft: on an additive-isomorph rung, identify the script-LOCAL lines FIRST (grep the new vs the precedent), because the shared body constrains where a mutation can be surgically injected and reverted net-zero.

## {emq-5-3-report} Report

### Y-1 — Director verify emq.5.3 — CLEAN (one remediate: the label). Deepened pass (NORMAL+/MINT-LEASE, a new Lua script).

- **@gbclaim (read line-by-line, adversarial):** declared keys ✅ — KEYS[1]=ring/KEYS[2]=active PIN the {q} slot; lane/glimit/gactive/job derive from the DECLARED base ARGV[1] (the A-1/L-1 law — Mars CITED the just-shipped guardrail in the script comment, the calibration visibly paying off). Ceiling ✅ — k=min(depth, lim-cur), gactive+=k, so post-batch gactive ≤ lim, never exceeds. Single TIME ✅ — one read, one shared deadline across all K. Affinity ✅ — one LMOVE → one group, every tuple tagged g, homogeneous; Valkey script atomicity rules out a nil-pop mid-loop. De-ring matches the @gwclaim:106/@gclaim:55 discipline.
- **bclaim/3 ✅** — pause checked FIRST; KEYS=[ring,active] braced via Keyspace; ARGV=[base, lease_ms]; {:ok,[tuples]}|:empty.
- **Ring-key integration ✅** — @gbclaim's "ring" == the shipped convention (6× in lanes.ex); the test helper `enqueue_lane` uses the SHIPPED `Lanes.enqueue/5`, so the scenarios exercise the real ring→@gbclaim path end-to-end, not a fake.
- **Byte-freeze ✅** — lanes.ex 0-del (shipped @gwclaim/@gclaim/@gweight byte-identical); 16 redis.call ALL inside @gbclaim; jobs.ex (@bclaim/@claim) absent from the diff = frozen. Boundary = only the rung surface (lanes.ex/conformance.ex/mix.exs/2 pins/lanes_batch_test); echo_wire/keyspace/connector/mix.lock untouched.
- **Conformance ✅** — INDEPENDENT re-run: CONFORMANCE 70/70, 9 doctests, 451 tests, 0 failures. The 3 deletions benign (the trailing-comma artifact + 2 stale-moduledoc count fixes); prior 67 byte-unchanged; the 3 new scenarios non-vacuous (each names its no-op-defeater — incl. the grouped_batch_fairness bounded-early-window interleaving witness, emq.4.4-L1).
- **Mutation spot-check (INDEPENDENT, distinct from Mars's 3):** `local k = depth` → `local k = 1` (under-serve) — caught by 6/10 lanes_batch_test (the ceiling, gactive-increment, whole-depth, lease, pause tests). Reverted by inverse Edit (NO git checkout); net-zero re-verified (lanes.ex 122-ins/0-del; lanes_batch 10/10 green).
- **Determinism:** Mars ran the ratifying ≥100 loop 120/120; the Director's INDEPENDENT ≥100 loop is launching next (the MINT/LEASE gate — same-ms branded-JOB mint hazard).
ONE REMEDIATE → D-2 (the mix.exs label). Everything else clean; Mars-2 is a near-collapse (the single label fix).

## {emq-5-3-complete} Complete

### Z-1 — emq.5.3 SHIPPED (group-affinity batch: @gbclaim + bclaim/3, ring-rotated)

The grouped batch claim is built, Director-verified CLEAN, the determinism gate ratified, the triad synced — ready for the single LAW-4 pathspec commit.
- WHAT: NEW @gbclaim (additive inline Script.new in lanes.ex beside @gwclaim) + Lanes.bclaim/3 — rotates the fair-lanes ring (LMOVE) and serves a HOMOGENEOUS batch from the landed lane, K=min(depth, glimit headroom), one TIME, one shared lease, gactive += served, the @gwclaim re-ring guard. The @gwclaim isomorph minus the gweight read (the one semantic delta). reuse gactive (the ceiling). conf 67→70.
- FORKS (Operator, D-1): 5.3-A → additive @gbclaim (NORMAL+, shipped @g*/@bclaim byte-frozen) · 5.3-B → reuse gactive · 5.3-C → ring-rotated bclaim/3 (extensible to caller-named later). LABEL (D-2): 2.5.1 (within-family patch, not 2.6.0).
- VERIFY (Y-1) CLEAN: @gbclaim read line-by-line (declared keys A-1/L-1, ceiling clamp, single TIME, affinity); byte-freeze (lanes.ex 0-del, 16 redis.call all in @gbclaim, jobs.ex untouched); ring-key integration real (enqueue_lane uses shipped Lanes.enqueue); 70/70 independent; mutation k=depth→k=1 caught 6/10 + reverted net-zero; the INDEPENDENT ≥100 determinism loop 100/100 (every iter 451 tests/0 failures/conf 70). Mars-2 = the single label fix.
- TRIAD: Venus Stage-5 sync (0 WITHHELD, forks RULED, as-built captured); the .prompt.md left as the frozen original scope (5.1/5.2 precedent); msh tree CLEAN (the 2 ledger false-positives — the KEYS-bracket-then-paren Lua-prose mis-parse — reworded to the KEYS[n]=word form, meaning preserved).
- COMMIT SURFACE (12 files): 6 code (lanes.ex/conformance.ex/mix.exs/2 pins/lanes_batch_test.exs) + 4 triad (emq.5.3.{md,stories,llms,prompt}) + 2 ledger (emq-5-3.progress.md/.registry.json). The index is empty (Operator cleared the pre-staged foreign out-of-band); --only pathspec for robustness.
NEXT: the Stage-6 canon fold (roadmap/progress/changelog/emq.5.md → 5.3 SHIPPED, conf 70, 5.4 next) as a SEPARATE commit; then Apollo's post-ship mentoring (fold the 5.3 craft forward). emq.5 family: 5.1 spine + 5.2 shaping + 5.3 affinity SHIPPED, 5.4 partitioned finish remains.
