# emq-3-5 — AAW scope ledger

## {emq-3-5-analysis} Analysis

### A-1 — the headline design finding (grounded against the as-built echo_mq tree). COMPLETION composes recursively for (almost) FREE: validated against jobs.ex @complete:212-218 + complete/5:456 + parent_of/3:503. When an intermediate node's last child completes, the @complete fan-in DECRs to <=0 and ZADDs the parent to `p..'pending'` + HSETs its row `state pending` (jobs.ex:216-217) — the intermediate node becomes a REAL claimable pending job; once claimed+processed+completed, ITS OWN complete/5 reads ITS `parent`/`parent_queue` field (parent_of/3) and fans into the grandparent (same-slot atomic, or cross-slot via flow:outbox+sweep). So completion recursion needs ONLY the recursive ENQUEUE (each intermediate node enqueued as a flow-parent over its children AND carrying its own parent/parent_queue/parent_policy fields). FAILURE is the genuine NEW design: jobs.ex @retry sq:fp arm:286-290 moves the dead child's parent to `dead` (HSET KEYS[8] state dead; ZADD p..dead; ZREM p..pending) but does NOT itself re-propagate — the parent lands in the morgue INERT, with no signal to ITS parent. Same for the cross-queue @flow_fail_deliver fp arm (pump.ex:81): moves parent to dead, no further emit. So a grandchild's death fails the intermediate node, but the node's death does NOT reach the grandparent. THE RECURSIVE FAILURE HOOK is the sole genuinely-new mechanism emq.3.5 must design.

### A-2 — the reconcile delta (lag-1, re-read on disk; the emq.3.4 build moved the surface). EVERY emq.3.4.md As-built anchor MATCHES disk: flows.ex add/3:181, add_bulk/3:218, children_values/3:261, ignored_failures/3:295, dependencies/3:332, policy_token/1:359 (the both-flags-true→id resolver), add_cross_queue:420 + land_children:452 (the host-orchestration the spec cited ~:444-460 — MATCH on substance, the host HSET writes parent_policy on the child row after the byte-frozen @enqueue_flow_child EVAL at :463). jobs.ex @complete:175 (fan-in branch:212-219, cross-queue emit:204-211 — BYTE-FROZEN), @retry:252 (dead-letter morgue body:281-285 the 5 statements, ADDITIVE failure branch:286-302 dispatched on combined marker ARGV[7] = sq:fp/sq:id/xq:fp/xq:id, return dead:303), complete/5:456, retry/7:593, parent_of/3:503, parent_fail_of/3:535 (HMGET parent/parent_queue/parent_policy), policy_arm/1:559. pump.ex @flow_deliver:42 (BYTE-FROZEN), @flow_fail_deliver:78 (HSETNX-guarded, all {P}), deliver_flow_completions:205, sweep:170, split_entry:318/split_fail_entry/split_complete_entry (KIND-dispatch by leading-empty-field tag), deliver_one:254. keyspace.ex queue_key/2:14, job_key/2:18 (gated builder; composes :<sub> subkeys, no allowlist). admin.ex del_job:152 (DELs jk, jk:logs, jk:lock — FIXED) + @drain wipe():90 (DELs jk, jk:logs — FIXED): neither enumerates :dependencies/:processed/:failed/:unsuccessful/flow:outbox → the flow-subkey lifecycle carry CONFIRMED untouched. conformance.ex = 50 scenarios (the 7 flow scenarios :106-112; conformance_run_test.exs:44 pins {:ok, 50}). §6 grammar design.md:305-308 sub ∈ {lock,logs,dependencies,processed,failed,unsuccessful} — ALL flow subkeys reserved. VERDICT: BUILD-GRADE for the flat core emq.3.5 composes over. Zero STALE/INVENTED/MISSING. emq.3.5's OWN surface is forward-named (PLANNED).

### A-3 — the triad authored + the forks surfaced. Wrote 3 files under docs/echo_mq/specs/emq.3/: emq.3.5.md (652 lines, the authoritative body — Goal/5W/Scope In+Out/B1-B7/D1-D6/INV1-INV11/the surfaced forks/DoD, forward voice 📋 PLANNED), emq.3.5.stories.md (243 lines, US1-US7 + US-GATE + the Coverage map D1-D6→story→invariant), emq.3.5.llms.md (362 lines, the Mars brief — References/Requirements/Topology/Agent stories AS1-AS6/What-NOT-to-do). FORKS surfaced (Venus surfaces, Operator rules): S1 the RISK TIER (NORMAL vs HIGH, the gate fork, DECIDED BY S2), S2 the recursive-failure MECHANISM (host/sweep re-emit over byte-frozen scripts [RECOMMENDED] vs in-script recursive emit), S3 the recursive-enqueue SHAPE (unified add/3 nested-tree clause [RECOMMENDED] vs separate add_tree/3), S-Bound the depth cap (8 [RECOMMENDED]). S2 is the keystone — it decides S1 → Apollo's mandatoriness; authored to S2·Arm A → S1·NORMAL-risk → every shipped Lua byte-frozen, the recursion is a host tree-walk + a host re-emit. Conformance 50 → 52 (flow_grandchild + flow_grandchild_fail). ZERO production code touched, NO git. The triad IS the deliverable. Closing emq.3.5 CLOSES Movement I.



## {emq-3-5-progress} Progress

### P-1

P-1 (Mars) — T1 (recursive enqueue, flows.ex add/3 nested-tree clause) VERIFIED complete + correct against D2. Ceremony done (self-registered emq-3-5; read the authoritative body D2 + the llms brief Req1/AS1 + this ledger A-1/A-2). On picking up task #10 I found T1 ALREADY BUILT in the working tree (uncommitted M flows.ex; the prior mars-emq35 pass; task #10 already marked completed) — so per cite-do-not-invent I did NOT rebuild a working surface; instead I independently VERIFIED it against the acceptance gate.

AS-BUILT (re-pinned, MATCHES Venus A-2): flows.ex add/3:195 (cond: has_children? → add_tree; else flat dispatch byte-unchanged); @type tree_result:42; @max_tree_depth 8:37; add_tree:320; validate_tree/4:341 (acyclic + depth-cap, reduce_while, BEFORE any wire); land_node:372 (leaf→land_one_child / non-leaf→hold_node+land_children_tree); hold_node:400 (byte-frozen @hold_parent + host write_parent_link); land_one_child:430 (byte-frozen @enqueue_flow_child + host parent_policy HSET); land_children_tree:462 (fail-closed per node, reduce_while, spec-order results); write_parent_link:484 (parent always, parent_queue only cross-queue, parent_policy always — all {node}, DATA link); has_children?:500.

VERIFICATION (a throwaway probe against Valkey 6390, then deleted — T5 owns the committed test): 13/13 assertions PASS — (1) a 3-level same-queue flow returns nested {:ok,{root,[{node,[{gc,[]}]}]}}; root held deps=1, node held deps=1 carrying parent=root+parent_policy=fp, grandchild pending (leaf) carrying parent=node; (2) COMPLETION COMPOSES FOR FREE (D3): gc completes → node released to pending (deps 0) → node completes → root released (deps 0) — over the byte-frozen @complete, zero new completion code; (3) FLAT byte-identity: a depth-1 flow returns the FLAT {:ok,{parent,[children]}} (not nested), deps=2 — the emq.3.1-3.4 path unchanged; (4) a cyclic tree (id twice) → {:error,{:flow_cycle,id}} raised BEFORE any wire (parent row absent); a 9-level tree → {:error,{:flow_too_deep,8}}.

GATE: compile --warnings-as-errors clean; the flat-flow suites (flow_add+flow_fanin+flow_children_values+flow_cross_queue+flow_failure) 70 tests 0 failures (INV3 no-regression). BYTE-FREEZE: all 3 flow scripts (@enqueue_flow/@hold_parent/@enqueue_flow_child) byte-identical to the committed emq.3.4 forms — T1 edits NO Lua (the recursion is host-only, INV1); the v1 data-value parent_key NOT lifted at any level (write_parent_link uses declared subkeys + host-read fields, INV2). Slot-soundness: each node landed by a SINGLE-slot EVAL (non-leaf @hold_parent {node}, leaf @enqueue_flow_child {node}), parent-first; no script mixes slots.

T1 is BUILD-GRADE. Erlang re-probed from the app dir (echo_mq): OTP 28 / ERTS 16.4.0.1 (asdf current → 28.5.0.1; the L-1 lesson applied — probe from the app dir, not the repo root). NO git.

NOTE on T3 (#11, the recursive failure hook): per the brief (§"The forks are OPEN ... do not build until S2 is ruled"), T3/D4 is the ONE task gated on the Operator's S2 ruling (host/sweep re-emit Arm A = NORMAL-risk vs in-script branch Arm B = HIGH-risk + Apollo MANDATORY). T1 was safe to verify/ship because it is ARM-INDEPENDENT (D2's host tree-walk is identical under both S2 arms; S3·Arm A's add/3-clause is the recommended shape). T3 genuinely needs S2 ruled first.

### P-2

P-2 (Mars) — T3 (#11) VERIFIED with a same-queue defect; HOLDING for the lead on two gates (S2 ruling + go-ahead). Did NOT rebuild the existing partial T3 (cite-do-not-invent) nor build the fix past the spec's "do not build until S2 ruled" gate (escalate-do-not-invent).

VERIFICATION RESULT (throwaway Valkey probe, 9 assertions, deleted; the committed test is T5/#13):
- PASS A1/A2: same-queue gc death fails the node atomically (@retry sq:fp, emq.3.4 one-level).
- FAIL A3/A4: the node's death does NOT reach the root (same-queue recursion broken).
- PASS B1/B2: cross-queue recursion WORKS (gc death → cq2 sweep → node dead → re-emit → cq1 sweep → root dead).
- PASS C1 / FAIL C2/C3: same-queue ignore-dep top hop — node dead, but root does not proceed + node not in root's :unsuccessful.

ROOT CAUSE: maybe_reemit_parent_death (pump.ex) is invoked ONLY from the deliver loop (:301, :410) — the cross-queue/sweep path. A same-queue death fails the parent inside the byte-frozen @retry EVAL and returns via retry/7 with NO sweep, so the re-emit never fires. T3's cross-queue half is built; the same-queue retry/7 half (named in the #11 task) is MISSING.

BYTE-FREEZE (Arm A held, all confirmed 0 Lua +/-): @retry, @complete (jobs.ex); @flow_deliver, @flow_fail_deliver (pump.ex). jobs.ex realization: a NEW public parent_fail_link/3 wraps the private parent_fail_of/3 (defp, byte-frozen) — clean, not a defp→def flip.

THE FIX WHEN UNBLOCKED (Arm A, host-only, no Lua): retry/7's wrapper, on {:ok, :dead} for a same-queue flow CHILD whose death moved its PARENT to dead, calls maybe_reemit_parent_death for that parent (host detects "parent moved to dead" via a re-read, re-emits by the parent's parent_fail_link). Then re-verify 9/9 + the ≥100 loop.

GATES BLOCKING THE BUILD: (1) S2 unruled (no D-n; brief says do not build T3 until S2 ruled); (2) the lead's go-ahead (#11 was re-assigned to me but is mis-marked completed). Both in E-1. T5 (#13) MUST cover the same-queue 3-level fail or this defect ships green.

### P-3

P-3 (Mars) — T4 (#12) VERIFIED: built + at 52/52 GREEN, but the flow_grandchild_fail scenario passes for the WRONG reason (E-2) — its probe (conformance.ex:1521) hand-calls Pump.on_same_queue_child_death, a function the production retry/7 path never invokes, masking the T3 same-queue gap (E-1). Confirmed prod-real (no hand-call): a same-queue 3-level fail_parent flow leaves the root :awaiting_children forever (hung), node not in root's :failed. HOLDING for the lead on: (1) the S2 ruling (still no D-n; the standing precondition), (2) the go to land the honest T4 probe + the T3 retry/7 re-emit together (both Arm A host-only, no Lua). Did NOT make T4 honest in isolation (would flip the shared suite red mid-closure with no green path until the coupled T3 fix lands) nor touch the contested jobs.ex retry/7 without the go. The fix when unblocked: T4 probe drives ONLY retry/7 + the sweep (no on_same_queue_child_death hand-call) → red until T3; retry/7 triggers the re-emit on a same-queue child's death-to-dead → green for the right reason; then 9/9 prod-real + ≥100 loop. #11 + #12 BOTH mis-marked completed. Two ledger escalations: E-1 (the T3 production gap), E-2 (the T4 false-green). NO git; boundary echo/apps/echo_mq.

### P-4

P-4 (Mars) — RECONCILED: my E-1/E-2 fix + the lead's harden pass COEXIST in the tree, green for the right reason. The lead's reply was composed before seeing my Y-1 (it answered my T1-verification message), but the work converged correctly — verified by re-probe, no clobber:
- My retry/7 re-emit trigger INTACT (jobs.ex:695, EchoMQ.Pump.on_same_queue_child_death on the {:ok,:dead} same-queue arm).
- ZERO actual on_same_queue_child_death CALL sites remain (my 4 hand-call removals hold); the one residual grep hit (flow_recursion_test.exs:314) is an explanatory COMMENT, not a call — every scenario exercises the production retry/7 path.
- The lead's NEW same_queue_recursion_depth4 helper (conformance.ex:1658) is PROD-PATH HONEST and a STRONGER proof than my depth-3: it kills the leaf via real retry/7 (no hand-call), then drives the sweep twice, asserting the RECURSIVE deliver-loop re-emit (maybe_reemit_parent_death) fires hop-by-hop (leaf→n2 atomic; tick1 n1 dead + re-emit; tick2 root dead; tick3 no-op). A depth-3 chain can't reach the deliver-loop re-emit (retry/7 re-emits straight to the root) — depth-4 forces TWO hops, exercising both re-emit sites. My fix ENABLED this proof.
- Full per-app suite: 4 doctests, 346 tests, 0 failures (346 = my 345 + the lead's depth-4 test); Conformance 52/52; the lead reports the recursion ≥100 loop 100/100 on their side (mine was 110/110 pre-merge).

BOTH FLAGS RESOLVED: Flag 2 (conformance.ex:1583 syntax error) FIXED by the lead (a `with # comment` on the with-line broke the parser). Flag 1 (S2 ruling not in the ledger) — the lead confirms S2=Arm A IS the Operator's ruling (per the team-lead tasking) and escalated to the Director to record the D-n (recording an Operator decision is the Director's/Venus's job, outside our code boundary). emq.3.5 is built + green + harden-passed; Movement I closes with this rung, pending the Director's D-n record + LAW-4 commit. No further code action from me. NO git; boundary echo/apps/echo_mq.

## {emq-3-5-escalations} Escalations

### E-1

E-1 (Mars) — T3 (#11, the recursive failure hook) has a VERIFIED same-queue DEFECT + an OPEN S2-ruling precondition. Escalating before building further (escalate-do-not-invent).

CONTEXT: #11 was re-assigned to me, but T3 is ALREADY substantially built in the working tree (jobs.ex + pump.ex edited, compiles clean): jobs.ex adds a PUBLIC parent_fail_link/3 (a clean realization-over-literal — wraps the private parent_fail_of/3, which stays defp byte-frozen, instead of flipping it to def); pump.ex adds maybe_reemit_parent_death/4 + push_fail_entry in the deliver loop. All 4 shipped scripts (@retry/@complete/@flow_deliver/@flow_fail_deliver) byte-frozen (Arm A held). I did NOT rebuild a working surface — I VERIFIED it behaviorally.

THE DEFECT (verified by a throwaway Valkey probe, 9 assertions): the CROSS-queue recursion WORKS (B1/B2 PASS: a cross-queue gc death → sweep → node dead → re-emit → next sweep → root dead). But the SAME-QUEUE recursion is BROKEN (A3/A4 + C2/C3 FAIL): a same-queue fail_parent grandchild dies → the node dies ATOMICALLY in @retry's sq:fp arm (A1/A2 PASS) — but the node's death NEVER reaches the root (root not dead, node not in root's :failed). Root cause: maybe_reemit_parent_death is called ONLY from pump.ex (the deliver loop, :301 + :410), which fires for cross-queue (outbox) deaths. A SAME-QUEUE death fails the parent inside the byte-frozen @retry EVAL and returns via retry/7 WITHOUT ever going through the sweep — so the re-emit hook never fires. The ignore-dep top-hop variant fails the same way (C2/C3: root does not proceed, node not in root's :unsuccessful).

THE TASK NAMED IT: the #11 description says "Also the same-queue retry/7 path" — so T3 is INCOMPLETE (the cross-queue half built, the same-queue half missing), not wrong-in-approach. The fix (Arm A, no Lua edit): retry/7's host wrapper, after a {:ok, :dead} where the dead job is a same-queue flow CHILD whose death just moved its PARENT to dead, triggers maybe_reemit_parent_death for that parent host-side (the host must detect "the parent moved to dead" — re-read the parent's state, or have @retry's sq:fp arm's effect inferred host-side — and re-emit by the parent's own parent_fail_link, reusing the same machinery). This stays host-only (Arm A).

THE OPEN PRECONDITION: S2 is STILL not ruled — the ledger has NO D-n recording an Operator S2 ruling (only A-3's surfacing). The brief is explicit: "do not build until S2 is ruled (it decides S1 → Apollo's mandatoriness)." T1 was arm-independent (safe pre-ruling); T3 is the ONE task S2 actually gates. The existing partial T3 was built to Arm A pre-ruling — defensible (the recommended arm, byte-frozen) but the formal gate is unsatisfied.

RECOMMENDATION: (1) confirm the S2 ruling is recorded (or that "build to the recommended Arm A" is the standing instruction) — I will not build past the spec's explicit gate without that; (2) then I complete T3's same-queue half (the retry/7 re-emit hook, Arm A host-only) + re-verify all 9 probe assertions green + the ≥100 loop. Holding for the lead's go on both. #11 is currently marked completed in the TaskList — that is STALE given the defect.

### E-2

E-2 (Mars) — CRITICAL: the T4 flow_grandchild_fail conformance scenario PASSES FOR THE WRONG REASON (the emq.3.3 L-2 defect class), masking the T3 same-queue production gap (E-1). The suite is green at 52/52 but the same-queue recursive failure is BROKEN in production.

THE SMOKING GUN: flow_grandchild_fail's probe (conformance.ex:1521) manually calls `Pump.on_same_queue_child_death(conn, q, gc, "boom-gc")` — a function `retry/7` NEVER calls in production (confirmed: grep of retry/7's body for on_same_queue_child_death/maybe_reemit/reemit = EMPTY). The probe SIMULATES the re-emit the production path fails to trigger, so the scenario goes green while production hangs.

PROD-REAL PROOF (a probe with NO manual hook call — only the real retry/7 + a sweep, exactly what a worker does):
  node state: {:ok, :dead}            ← the one-level propagation works (emq.3.4)
  root state: {:ok, :awaiting_children}  ← BROKEN: the root HANGS, never dies
  node in root :failed? {:ok, nil}    ← BROKEN: the node never recorded in root's :failed
So a same-queue 3-level fail_parent flow leaves the root hung forever — the exact "a poison child stalls the flow" gap the whole flow-failure family exists to close, re-opened one level up.

TWO COUPLED DEFECTS:
 (1) T3 PRODUCTION (jobs.ex retry/7, E-1): the same-queue re-emit hook (maybe_reemit_parent_death) is invoked ONLY from pump.ex's deliver loop (the cross-queue/sweep path). retry/7 (the same-queue death path) returns {:ok,:dead} without triggering it. Pump.on_same_queue_child_death EXISTS (pump.ex:389) but NOTHING in the production path calls it — only the test does.
 (2) T4 TEST (conformance.ex:1521, MY assignment): the probe hand-calls Pump.on_same_queue_child_death to paper over (1) — a wire-fixture-counts-only-if-byte-faithful violation in spirit (L-2): a test step that counts only if it mirrors the PRODUCER, here a host step the producer never runs.

THE HONEST FIX (two parts, both Arm A host-only, NO Lua edit):
 - T4 (mine, now): the flow_grandchild_fail probe must exercise the PRODUCTION path — kill the same-queue grandchild via retry/7, then drive ONLY the sweep (Pump.deliver_flow_completions), NO manual on_same_queue_child_death call. This makes the scenario HONEST → it will FAIL until T3 is fixed (the test correctly goes red).
 - T3 (jobs.ex retry/7): on {:ok,:dead} for a same-queue flow child whose death moved its parent to dead, retry/7 itself triggers the re-emit (call Pump.on_same_queue_child_death, or fold the equivalent host re-emit) so the PRODUCTION path propagates — then the honest T4 scenario passes for the RIGHT reason.

GATES: S2 still unruled (the standing precondition). I will make T4 honest (it is my assignment + an honest-failing test is strictly better than a false-green) but I am NOT editing jobs.ex retry/7 (the T3 fix) without the lead's go — jobs.ex is the contested file + S2 is open. Recommend: rule S2 (or confirm Arm A standing) → assign the retry/7 fix → I land both + re-verify 9/9 prod-real + the ≥100 loop. #11 + #12 are BOTH mis-marked completed.

## {emq-3-5-report} Report

### Y-1

Y-1 (Mars) — T5 (#13) COMPLETE + the E-1/E-2 defect FIXED. The same-queue recursive-failure gap that would have shipped behind a green 52/52 suite is closed; every test now exercises the PRODUCTION path (no hand-calls). Movement-I-closing rung is gate-green for the RIGHT reason.

THE TWO-PART FIX (both Arm A, host-only, zero Lua edited):
1. T3 production gap (jobs.ex retry/7): WIRED the missing trigger. retry/7 already read parent_fail_of/3; on {:ok,"dead"} for a SAME-QUEUE flow child, it now captures parent_link and calls EchoMQ.Pump.on_same_queue_child_death(conn, queue, job_id, error) — the already-built host hook (pump.ex:391) that production never invoked (only the tests did). The call is gated to the :same_queue arm (a non-flow/cross-queue retry adds no work; the hook self-guards on the parent→dead transition, idempotent). @retry Lua attribute BYTE-UNCHANGED (the fix is host Elixir in the def body — confirmed 0 Lua +/- in @retry). No module cycle (Jobs→Pump runtime ref; Pump→Jobs already existed).
2. The 4 false-green hand-calls REMOVED (the L-2 defect class): flow_recursion_test.exs:299/374 + conformance.ex:1521/1622 each hand-called Pump.on_same_queue_child_death — simulating the re-emit production never did, masking (1). All 4 removed; each site now kills the same-queue grandchild via the real retry/7 + drives ONLY the sweep, so the scenarios exercise retry/7 → outbox → sweep → @flow_fail_deliver end-to-end. (Post-fix the hand-calls were ALSO actively harmful — a double-push — so removal was required, not just hygienic.)

VERIFICATION (prod-real, NO hand-calls): a focused probe, 7/7 PASS — same-queue 3-level fail_parent: node dead → root dead via the recursive re-emit, node in root's :failed; same-queue ignore-dep top hop: node dead, root PROCEEDS (released), node in root's :unsuccessful; idempotent: re-sweep leaves root's :failed at exactly 1 entry. (Before the fix these 4 same-queue assertions FAILED — the root hung :awaiting_children forever; cross-queue already worked.)

THE GATE LADDER (all green, BEFORE reporting):
- compile --warnings-as-errors clean (no unused Pump alias — Pump still used 10/12 sites).
- flow_recursion_test + both pins: 16 tests 0 failures (production-path).
- Conformance.run/2 → {:ok, 52} (flow_grandchild + flow_grandchild_fail now exercise the real path).
- FULL per-app suite: 4 doctests, 345 tests, 0 failures (INV3 no-regression).
- ≥100 DETERMINISM LOOP OWNING THE MACHINE: 110 iterations of flow_recursion_test + conformance_run, ALL GREEN (376s) — the mint-dense recursion (one branded JOB id per node across many queues), no same-ms flake.
- BYTE-FREEZE (Arm A): 0 removed Lua lines across ALL 7 shipped scripts (@retry/@complete/@flow_deliver/@flow_fail_deliver/@enqueue_flow/@hold_parent/@enqueue_flow_child). 0 hand-calls remain.

TOUCH-SET: flows.ex (T1, prior), jobs.ex (retry/7 re-emit trigger — my fix + the prior parent_fail_link/3), pump.ex (T3 host re-emit, prior), conformance.ex (T4 + the 2 honesty fixes), the 2 pins (52), flow_recursion_test.exs NEW (the 2 honesty fixes). Erlang re-probed from the app dir: OTP 28 / ERTS 16.4.0.1.

OPEN: S2 is STILL unruled (no D-n). I built the retry/7 fix to Arm A (host-only) because the WHOLE rung is committed to Arm A (every shipped Lua byte-frozen) + the brief says "build to the recommended arm pending the ruling" + the lead assigned T5 (which requires the fix to pass). If the Operator rules S2·Arm B the fix stays zero-cost-reversible (host-only). RECOMMEND the Director/Operator record the S2 ruling before the LAW-4 commit. Movement I closes with this rung.

## {emq-3-5-learnings} Learnings

### L-1

L-1 (Mars) — ATTRIBUTION CORRECTION for E-1, so a future reconcile reads it right. The lead's reconciliation framed E-1 as "Mars verified a stale pre-fix tree; the retry/7 fix landed out-of-band / the same-queue path was already fixed." That is INACCURATE. The precise timeline:
- The same-queue recursive failure WAS genuinely broken (E-1): retry/7 had ZERO re-emit calls (grepped); a prod-real probe (no hand-call) showed the root hung :awaiting_children forever, node never in root's :failed.
- The conformance + recursion tests MASKED it with 4 hand-calls to Pump.on_same_queue_child_death (E-2, the L-2 false-green class).
- The FIX was a real code change I made THIS session (Y-1): the retry/7 host wrapper now captures parent_link and, on {:ok,:dead} for a :same_queue flow child, calls EchoMQ.Pump.on_same_queue_child_death (jobs.ex:693-699) — host-only, @retry Lua byte-frozen. I ALSO removed the 4 hand-calls. This is an UNCOMMITTED working-tree change (git diff shows it as + lines this session, the comment prose is mine) — NOT a prior commit, NOT out-of-band.
- The lead, replying before seeing my Y-1, saw my own fix in the tree and attributed it to "out-of-band / already-fixed."

WHY THIS MATTERS (not credit — correctness of the record): "self-resolved / pre-existing / never broken" would let a future reconcile believe the same-queue recursion never had a production gap, hiding that it required the retry/7 wiring. The honest record: a real gap existed; it needed a code change; that change (mine, Y-1) is in the tree.

WHAT WE AGREE ON (the substance, unchanged): on_same_queue_child_death + maybe_reemit_parent_death are the LEAD's design (correct, just not wired to retry/7 until Y-1); the lead's same_queue_recursion_depth4 test is the stronger proof (it forces the recursive deliver-loop hop a depth-3 chain can't reach) and the lead proved it bites (a deliver-loop-disabling mutation left depth-3 green, depth-4 red). The convergence (Mars + Director + lead on the same defect + fix) is the cross-check that makes it solid. End state: rung green for the right reason (346 tests, Conformance 52/52, ≥100 loop clean), the fix present + correct + proven. Open: the S2 D-n (Director's to record). LESSON: when the tree moves between agents out-of-band, an uncommitted diff is the ground truth for WHO fixed WHAT — check git diff authorship of the actual lines before attributing a fix to "out-of-band," in either direction.

## {emq-3-5-build} Build closure

### D-1 — the fork ruling (Operator, recorded)

**D-1 (Operator-ruled, 2026-06-15)** — S2 (recursive-failure mechanism) = **Arm A** (host/sweep-orchestrated re-emit over byte-frozen Lua) → S1 (risk tier) = **NORMAL-risk** (Apollo non-mandatory); S3 (enqueue shape) = **Arm A** (unified `add/3` nested-tree clause); S-Bound (depth cap) = **8**. Surfaced as the open forks in A-3; ruled via the Director's `/echo-mq-ship` tasking; T3/D4 built to it host-side with every shipped Lua byte-frozen (Arm A confirmed by the Director's independent byte-freeze + mutation probe).

### Z-1 — the build closure (Apollo, post-build reconcile + spec sync)

emq.3.5 is **SHIPPED — BUILD-GRADE, NORMAL-risk, Arm A**. The Director's Stage-3 review returned BUILD-GRADE; Apollo's independent post-build reconcile against `echo/apps/echo_mq` confirms **every D1–D6 deliverable + INV1–INV11 invariant MATCH** the as-built (the delta table is in Apollo's closure message to the Director). Movement I is CLOSED with this rung — the flow family is parity-complete; Movement II (emq.4–emq.8) opens on a complete core. (Records freeze: the A-1/A-2/A-3 design analysis + the P/E/Y/L build records above are NOT rewritten — this section is appended.)

THE FORKS RULED (the Operator, via the Director — the standing "build to the recommended Arm A" instruction, E-1/P-4): **S2 · Arm A** (the keystone — the recursive failure hook host/sweep-orchestrated over the byte-frozen scripts) → **S1 · NORMAL-risk** (no shipped-script edit; Apollo the fast finisher, the rebalance); **S3 · Arm A** (the unified `add/3` nested-tree clause, not a separate `add_tree/3` verb); **S-Bound · 8** (`@max_tree_depth 8`, a typed `{:error, {:flow_too_deep, 8}}` on a deeper tree). The build held every ruling.

THE AS-BUILT SURFACE (the anchors Apollo pinned):
- **D2 (recursive enqueue):** `flows.ex` — `add/3` branches on a pure `has_children?` shape test to `add_tree/3`; `validate_tree/4` (acyclic + depth-cap, BEFORE any wire); `land_node`/`hold_node`/`land_one_child`/`land_children_tree` (each node a SINGLE-SLOT EVAL via the byte-frozen `@hold_parent`/`@enqueue_flow_child`, parent-first, fail-closed per node); `write_parent_link` (the declared §6 subkey + host-read `parent`/`parent_queue`/`parent_policy`, the v1 data-value `parent_key` NOT lifted).
- **D3 (multi-level completion, FREE):** no new completion script — `@complete`/`@flow_deliver` byte-identical to HEAD; proven by the `flow_grandchild` scenario (`conformance.ex`).
- **D4 (the recursive failure hook):** `pump.ex` — `maybe_reemit_parent_death/4` (the deliver-loop re-emit, gated on the parent→`dead` transition the `dead_before?` read at `deliver_one/2` detects) + `on_same_queue_child_death/4` (the synchronous trigger) + `push_fail_entry/7` (byte-faithful to `@retry`'s `xq:*` fail-entry); `jobs.ex` `retry/7` calls `on_same_queue_child_death` on the `{:ok, "dead"}` same-queue arm; `parent_fail_link/3` (the public host-read wrapping the byte-frozen private `parent_fail_of/3`).
- **D6 (conformance):** `flow_grandchild` + `flow_grandchild_fail` registered additive-minor (`scenarios/0`); count re-pinned 50 → 52 in both `conformance_run_test.exs` + `conformance_scenarios_test.exs`; `run/2` → `{:ok, 52}`.

THE GATE EVIDENCE (Apollo reproduced, on Valkey 6390, erlang 28.5.0.1 from the app dir):
- `mix compile --warnings-as-errors` clean.
- FULL per-app suite: **4 doctests, 346 tests, 0 failures** (`--include valkey`).
- `Conformance.run/2` → **{:ok, 52}** (both new scenarios pass with honest descriptions).
- The ≥100 determinism loop: Mars **110/110**, the Director **100/100**; Apollo reproduced ONE confirming full suite (346/0) + a SCOPED recursion loop **69/70** (29/30 then 40/40) — the one break did NOT reproduce in 40 fresh iterations, classified as the pre-existing connector-teardown artifact (the `** (stop) killed` line on suite shutdown — exit 0, zero assertion context, the umbrella §4 class), NOT the rung's mint. (Per the rebalance, a third full ~6-min loop is waste once build+harden ran ≥2 green 100/100 uncontended.)

THE BYTE-FREEZE PROOF (INV1/INV3, Arm A): an extract-and-diff of EVERY `Script.new/2` body against HEAD — **14 in jobs.ex + 2 in pump.ex + 3 in flows.ex = all 19 byte-identical**. The recursion is host tree-walk + host re-emit; no `redis.call`/`Script.new` body moved. The prior 50 conformance scenarios are byte-unchanged (zero removed name atoms; only the predecessor `flow_add_bulk` gained a trailing comma so the list can grow).

THE DIRECTOR'S MUTATION PROBE (the suite bites): disabling the deliver-loop re-emit (`pump.ex:301`) left the depth-4 same-queue assertion **RED** while depth-3 stayed **GREEN** and cross-queue went **RED**, then restored **net-zero** (an inverse Edit, never `git checkout`).

THE ROOT CAUSE (the E-1/E-2 finding, CORRECTED 2026-06-15 — supersedes the earlier "proof-depth only / feature always correct" framing): the **SAME-QUEUE half of D4 had a GENUINE PRODUCTION GAP in the first build**, NOT a proof-only thinness. `on_same_queue_child_death` existed as a correct function but was **UNWIRED from `retry/7`** — only the tests called it — so in production a same-queue flow child's death would have **HUNG its parent** (`:awaiting_children` forever, the node never recorded in the root's `:failed`): no re-emit ever propagated the node's death up the tree. The **CROSS-QUEUE half WAS correct from the first build** (the deliver-loop hook `maybe_reemit_parent_death` fires for sweep-delivered deaths). THE FIX (Y-1, the harden/reconcile cycle): wiring `on_same_queue_child_death` into `retry/7`'s `:dead` arm (`jobs.ex:695`) + removing **4 test-only hand-calls** that masked the gap (a false-green — the L-2 wire-fixture-counts-only-if-faithful class). THE PROOF: the depth-4 same-queue test (root → n1 → n2 → leaf, asserted tick-by-tick) exercises the recursion on the REAL production path (RED-while-broken under the deliver-loop mutation — the Director confirmed independently). So D4 is complete for BOTH topologies, green for the RIGHT reason — but the same-queue half was a **real gap the harden cycle closed**, not proof-depth thinness. (The earlier "byte-identical feature code → always correct" reasoning compared two POST-wiring states, so it could not see the pre-wiring gap — the lesson is in the spec body's lessons section.) ZERO hand-calls remain (the only `on_same_queue_child_death` CALL site is `jobs.ex:695`, production).

THE FLAKE NOTE: the `** (stop) killed` connector-teardown log on full-suite shutdown is a PRE-EXISTING umbrella §4-class artifact (exit 0, no assertion context), not this rung's debt and not a gate failure.

NO production code edited by Apollo; NO git (the Director commits by pathspec at the rung's close). Boundary: `docs/echo_mq/` (the spec triad + dashboard + roadmap + this ledger). Movement I CLOSED.
