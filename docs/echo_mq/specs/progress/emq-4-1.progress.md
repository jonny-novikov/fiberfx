# emq-4-1 — AAW scope ledger

## {emq-4-1-thinking} Thinking

### T-1 — emq.4.1 control plane: the §0 derivation (Flat-L2, NORMAL-risk)

WHAT — the fair-lanes operator control plane over the SHIPPED EchoMQ.Lanes: (a) lane re-assignment — a member moves emq:{q}:g:<src>:pending → g:<dst>:pending in ONE atomic inline Script.new/2 (ZREM src + ZADD dst; both {q}-co-located → both declared KEYS[n]; the ring re-shaped so both lanes reflect new serviceability); (b) deepened pause/resume/limit/drain over the shipped lane keys; (c) the two RETIRED v1 re-aims — changePriority-7 → lane re-assignment (NO numeric priority; mint order IS the order theorem), getCountsPerPriority-4 → Metrics.lane_depths/3.
WHY — the control plane is the most-exercised, least-risky groups surface; it founds the chapter's vocabulary + gate posture before the HIGH-risk metronome (4.3) and weighted fairness (4.4), and discharges the canon's two RETIRED v1 priority commands.
WHO — the program; multi-tenant operators (live re-shaping of group traffic); the conformance harness (+N additive-minor). codemojex = prospective consumer (a re-grouped player's work moves lane) — recorded, not asserted.
WHERE — echo/apps/echo_mq ONLY: lanes.ex EDIT (re-assignment verb + its inline script + deepened control verbs); metrics.ex EDIT iff the lane_depths/3 re-aim deepens it (else untouched); conformance.ex EDIT (the re-assignment scenario + re-pin 52→N); test/*_test.exs NEW/EDIT (:valkey proof); the two pinning tests EDIT. echo_wire UNTOUCHED (rides the shipped connector eval/command); apps/echomq UNTOUCHED; keyspace.ex §6 grammar UNEDITED (no new key family).

DO-NOTHING BASELINE — no operator control plane for groups: cannot re-shape live group traffic, the two RETIRED v1 priority commands stay undischarged. Rejected: the family's whole point is operator-grade depth.
SMALLEST CHANGE THAT PRESERVES CORRECTNESS — add the re-assignment verb + deepened control verbs as additive wire calls over the shipped g: keys + ONE new inline script (the atomic same-queue move); edit NO shipped lane script (@gclaim/@genqueue/@gpause/@gresume/@glimit byte-frozen).

INVARIANTS AS RUNNABLE CHECKS (the subset emq.4.1 carries):
- INV1 (wire law): grep any new script for a lane key outside the shipped g:-segment family = empty; grep for a numeric-priority score / prioritized key = empty; {emq}:version reads echomq:2.0.0 after connect; §6 grammar unedited.
- INV2 (branded both ends): an ill-formed src OR dst group raises at Lanes.lane_key!/2 before any wire; the scenario uses two distinct branded groups.
- INV3 (shipped lane surface byte-frozen): grep redis.call on @gclaim/@genqueue/@gpause/@gresume/@glimit in the lib diff = 0; prior scenarios (rotate/pause/limit/lane_depth/stalled_group) git-verified unchanged.
- INV4 (additive-minor conformance): git-diff shows only additions to scenarios/0; the prior 52 byte-unchanged; the count re-pins 52→N in BOTH pinning tests; Conformance.run/2 prints N.
- INV5 (slot soundness): the move script declares keys of exactly one {q}; a cross-queue destination is REJECTED at the host verb (typed/host-side error, never silently mis-keyed); no script claims atomicity across slots.

RISK — NORMAL: pure control over shipped keys + a read re-aim; no shipped-script edit; founds no process/lease surface. Standard per-app gate ladder + a multi-seed sweep + an honest determinism-posture statement (the ≥100 loop is NOT required — running it would forge load the rung did not introduce). ENGINE: Valkey 6390 (PONG). MODE: Flat-L2.

### T-2 — emq.4.1 lag-1 reconcile (the as-built floor for the control plane)

RE-PROBED echo/apps/echo_mq/lib/echo_mq/{lanes,metrics,jobs,consumer,admin,keyspace,conformance}.ex on disk (line numbers verified, not trusted from hints).

SURFACE CONFIRMED (all MATCH; none must be edited):
- Lanes verbs: enqueue/5, claim/3, pause/3, resume/3, limit/4, depth/3 + lane_key!/2 (the branded-gated builder, raises unless BrandedId.valid?/1). Shipped scripts @genqueue/@gclaim/@gpause/@gresume/@glimit (lanes.ex:16-99). INV3 byte-freeze of these 5 is EXPRESSIBLE (grep redis.call on those scripts in the lib diff = 0).
- @gclaim ZPOPMINs the lane head (lanes.ex:41) — score-0 is load-bearing for FIFO/mint-order head selection. Fork C (park) confirmed CORRECT.
- Metrics.lane_depths/3 (@lane_counts, metrics.ex:279-310) EXISTS as the getCountsPerPriority-4 re-aim target. NO new read needed (Fork C parked). lane_depth/3 delegates to Lanes.depth.
- Jobs.@reap (jobs.ex:341-369) already group-aware (the stalled_group scenario is its proof). NOT touched by 4.1 (that is 4.2).
- Consumer park loop (consumer.ex:91-149): reap→promote→drain(rotating claim)→park(BLPOP wake). NOT touched by 4.1 (that is 4.3).
- Admin.drain/3 (@drain, admin.ex:84-122) = the slot-rooted derived-key A-1 precedent (base..'g:'..g..':pending' from a declared KEYS[1] base). The QUEUE-WIDE drain precedent for the "deepened drain" verb.

LIVE CONFORMANCE COUNT = 52 (re-probed: scenarios/0 has 52 entries, ending flow_grandchild_fail at conformance.ex:118; module doc says "fifty-two"; conformance_run_test.exs:45 asserts {:ok, 52}; conformance_scenarios_test.exs:18 references {:ok, 52}). Lane scenarios present: rotate, pause, limit, lane_depth, stalled_group, obliterate_grouped. The re-assignment scenario(s) re-pin 52 → N in BOTH pin tests.

THE ARITY FINDING (the load-bearing reconcile result):
- @genqueue stores 'group', ARGV[3] ON the job row (lanes.ex:23). Every group-aware script reads it via HGET jk 'group' (@gclaim:49 sets state but the group is read at @complete:182, @retry:259, @promote:320, @reap:349). So the SOURCE group IS derivable from the row → arity 4 is VIABLE: reassign(conn, queue, job_id, dst_group).
- CRITICAL: the move script MUST HSET the row's 'group' field to dst. Every later @gclaim/@complete/@reap reads HGET jk 'group' to find the lane + decrement gactive[g]. If the row still says src after the move, a later claim from the dst lane would touch gactive[src] — corrupting ceiling accounting. So the atomic move = ZREM src-lane + ZADD dst-lane (score 0) + HSET jk group=dst + ring re-shape for BOTH lanes.
- RECOMMENDATION: verb name `reassign`, arity 4 (conn, queue, job_id, dst_group) — src derived from the row. Rationale: (a) the house style is terse single words (enqueue/claim/pause/resume/limit/depth); `reassign` reads as the operator verb; (b) arity 4 is the minimal honest signature since src is authoritative on the row (passing src as arity 5 invites a src-mismatch failure mode the row already answers); (c) the dst group is branded-gated at lane_key!/2 (INV4). The job_id is gated at Keyspace.job_key/2.

NO EXISTING reassign/move verb (grep empty) — the surface is genuinely NEW (PROPOSED, forward-tense correct).

RE-AIMS CONFIRMED: changePriority-7 RETIRED → lane re-assignment (no numeric priority — grep-confirmed no priority/prioritized in jobs.ex/lanes.ex). getCountsPerPriority-4 RETIRED → Metrics.lane_depths/3 (already shipped). addPrioritizedJob-9 SHIPPED re-aimed (the score-0-lane-no-new-key discipline — the precedent that lanes are score-0).

THE MOVE-SCRIPT SHAPE (sketched; WITHHOLD undetermined ring-detail to build): inline Script.new/2; KEYS[1]=job row, KEYS[2]=src lane g:<src>:pending, KEYS[3]=dst lane g:<dst>:pending, KEYS[4]=ring (+ paused/glimit/gactive/wake as needed for the dst ring re-shape) — ALL on one {q} slot. Body: guard the row exists + is grouped (read HGET KEYS[1] 'group' = src, refuse if absent/mismatch); ZREM KEYS[2] id; if removed, ZADD KEYS[3] 0 id; HSET KEYS[1] 'group' dst; re-ring dst if serviceable (the @genqueue ring-add pattern: SISMEMBER paused / glimit-vs-gactive / LPOS / RPUSH ring + wake); shrink src from the ring if its lane is now empty (the @gclaim LREM-on-empty pattern). NO server clock (no lease touched — INV5 trivially holds, no TIME). A cross-queue dst is REJECTED at the HOST verb (typed/host-side error — slot({src})==slot({dst}) only same-queue; INV5 atomicity). The EXACT ring-reshape lines are pinned at the build's pre-build reconcile (the lag-1 law) — withheld here, not invented.

VERDICT: BUILD-GRADE. Forks honored (C park / additive-minor). INV1-5 all expressible as runnable checks. Boundary clean (echo_mq only; no echo_wire; no keyspace.ex grammar edit; no shipped-script edit). One D-2 ruling owed from the Director: confirm verb=reassign, arity=4 (src-derived).

### T-3 — Mars-1 pre-build reconcile (Stage 3, the lag-1 re-probe on disk)

TOOLCHAIN: elixir 1.18.4 / erlang 28.5.0.1 (asdf current, echo/.tool-versions). Valkey 6390 → PONG.

SURFACE RE-CONFIRMED ON DISK (line numbers verified, not trusted):
- lanes.ex: @genqueue (16-35) — HSET row 'group',ARGV[3] at :23; ZADD KEYS[2] 0 ARGV[1] score-0 at :24; ring-add guard (SISMEMBER paused / glimit-vs-gactive / LPOS / RPUSH ring + LPUSH wake + LTRIM 0 63) at :25-32. @gclaim (37-61) — lane derived `ARGV[1] .. 'g:' .. g .. ':pending'` at :40 (the A-1 ARGV-slot-rooted convention); ZPOPMIN head at :41 (score-0 load-bearing — Fork C park CORRECT); LREM ring 0 g lane-drop at :43,:55-58. @gpause/@gresume/@glimit (63-99). lane_key!/2 (197-203) gates BrandedId.valid?/1, RAISES. Verbs enqueue/5, claim/3, pause/3, resume/3, limit/4, depth/3.
- jobs.ex group-field readers CONFIRMED by grep: HGET <row> 'group' at :182 (@complete), :259 (@retry), :320 (@promote), :349 (@reap) — FOUR consumers rebuild the lane key + adjust gactive[g] from this field. The move's HSET row group=dst is load-bearing over all four (T-2/D-3 correctness finding holds on disk).
- metrics.ex lane_depths/3 + @lane_counts (279-310) — the getCountsPerPriority-4 re-aim target, ALREADY SHIPPED, branded-gated. No new read (Fork C parked). UNTOUCHED.
- conformance.ex LIVE COUNT = 52 (re-probed: scenarios/0 ends flow_grandchild_fail at :118; moduledoc "fifty-two"; conformance_run_test.exs:45 {:ok, 52}; conformance_scenarios_test.exs @run_order 52 names + moduledoc "fifty-two"). Lane scenarios present: rotate, pause, limit, lane_depth, stalled_group, obliterate_grouped. The stalled_group scenario (:995-1014) is the closest model for the reassign scenario (enqueue grouped → claim grouped → ZSCORE lane assert → Lanes.claim returns group).
- NO existing reassign/move/@greassign surface (grep empty) — PROPOSED forward-tense correct.

BOUNDARY: repo-root git status confirms the pre-staged tree is docs/go/spec only — NOTHING under echo/apps/echo_mq/{lib,test}. The wire_pipe story tests the brief warns of are not in this app's lib/test. Build is clean of the entanglement.

PLAN per D-3: reassign(conn, queue, job_id, dst_group) arity-4 src-derived; new inline @greassign; HSET row group=dst load-bearing; DROP dead :cross_queue path (arity-4 single-queue ⟹ same slot by construction); returns {:ok,:reassigned}/{:ok,:noop}/{:error,:not_found}/{:error,:not_pending}. Test file test/lanes_reassign_test.exs NEW (:valkey). Conformance +1 (reassign) → 53, re-pin in BOTH pin tests + moduledocs. No lane-scoped drain unless Director confirms in scope (R3 — minimal control plane = reassign + carried pause/resume/limit).

### T-4 — Mars-1 build COMPLETE (Stage 3): the fair-lanes control plane, gates green

BUILT (D-3 exactly):
- lanes.ex: NEW @greassign inline Script.new/2 + reassign(conn, queue, job_id, dst_group) arity-4 src-derived. Host gates job_id at Keyspace.job_key/2 + dst_group at lane_key!/2 (raises before wire). KEYS=[job_row, dst_lane, ring, paused, glimit, gactive, wake]; ARGV=[job_id, dst_group, queue_base]. Script: HGET row 'group'=src (nil→-1); src==dst→0; src_lane=ARGV[3]..'g:'..g..':pending' (A-1 ARGV-slot-rooted, @gclaim:40 convention); ZREM src_lane (0→-2, in-flight/absent, row UNtouched); ZADD dst_lane 0 (score-0 FIFO-by-mint); HSET row group=dst (LOAD-BEARING); re-ring dst via @genqueue guard (SISMEMBER paused / glimit-vs-gactive / LPOS → RPUSH ring + LPUSH/LTRIM wake); LREM src from ring if ZCARD src_lane==0. NO TIME, NO gactive mutation. Returns numeric sentinel host-mapped: 1→{:ok,:reassigned}, 0→{:ok,:noop}, -1→{:error,:not_found}, -2→{:error,:not_pending} (the update_data/-1→:gone idiom; NO error_reply → wire-class registry UNEXTENDED).
- DROPPED the dead :cross_queue path (arity-4 single-queue ⟹ same {q} slot by construction — not expressible).
- conformance.ex: +reassign scenario (full cycle: enqueue grouped src → reassign dst → ZSCORE src nil + dst score-0 + row group==dst → noop idempotent → claim returns group==dst → in-flight gactive[dst]=="1" & gactive[src]==nil → complete → both gactive absent). Re-pinned 52→53 in scenarios/0 + run/2 doc + module moduledoc ("fifty-two"→"fifty-three").
- test/lanes_reassign_test.exs NEW (243L, 11 :valkey tests): move+score-0+row-rewrite; served-in-dst-rotation; claim+complete charges gactive[dst] not [src]; src-emptied→ring-drop; src-sibling→ring-stays; dst-paused→parked-not-ringed; dst-at-ceiling→parked-not-ringed; same-group noop; not_found (missing+flat-non-grouped); not_pending (in-flight, row UNtouched); ill-formed dst raises.
- conformance_run_test.exs + conformance_scenarios_test.exs: re-pinned {:ok,52}→{:ok,53}, @run_order +:reassign (after :obliterate_grouped), moduledocs + test names "fifty-two"→"fifty-three".

R3 DECISION (surfaced to Director): NO lane-scoped drain built. The minimal control plane = reassign + the SHIPPED Lanes.{pause,resume,limit} carried byte-UNCHANGED (zero diff to @gpause/@gresume/@glimit + their host wrappers); Admin.drain/3 already provides queue-wide drain. A lane-scoped drain is the brief's "build-time judgment to confirm" — left for the Director to rule (additive if wanted).

RE-AIMS recorded (no new code): changePriority-7 → reassign/4 (no numeric priority — doc'd on reassign/4); getCountsPerPriority-4 → SHIPPED Metrics.lane_depths/3 (untouched, Fork C parked).

A RUN-CAUGHT FINDING: ZSCORE returns RESP3 double (0.0) not "0" under the default connection — the first :valkey run failed 5/11 on {:ok,"0"} assertions. Fixed: lane_score/4 helper normalizes to float (+0.0 OTP-27 canonical); the conformance scenario asserts dst_score in [0,"0",+0.0]. The stalled_group scenario sidesteps this by not pinning the score form. NOT a script logic error — the move was correct (wire confirmed 0.0).

GATES (Valkey 6390 PONG; elixir 1.18.4 / erlang 28.5.0.1):
- compile --warnings-as-errors: CLEAN (lib + tests, no OTP-27 float-pattern warning).
- per-app suite --include valkey: 4 doctests, 366 tests, 0 failures (full bus, no regression).
- Conformance.run/2: CONFORMANCE 53/53, CONF reassign ok.
- multi-seed sweep (seeds 0-4) reassign+conformance: 14 tests 0 failures each. ≥100 loop NOT run (NORMAL — no id-mint/process/lease hazard: the move mints no branded id, touches no TIME, starts no process; running it would forge load the rung did not introduce).

INV1-5 SELF-CHECK:
- INV1: no priority/prioritized/pc/ZCOUNT in any CODE line (only doc comments asserting absence); @greassign keys all g:-segment + the row (no new family); keyspace.ex grammar UNEDITED (no diff); {emq}:version reads echomq:2.0.0 (live + :fence scenario).
- INV2: dst gated at lane_key!/2 (raises) BEFORE wire (lanes.ex:265 in keys list); src valid-by-construction (row's stored group). The ill-formed-dst test proves the host-side raise.
- INV3: 5 shipped lane scripts BYTE-IDENTICAL to HEAD by md5 (@genqueue 421526e8…, @gclaim 3d00686f…, @gpause 194b7f9c…, @gresume 7be3b500…, @glimit 41fff81d…); zero '-redis.call' lines in the lib diff.
- INV4: additive-minor — prior 52 scenario NAMES diff = only '+reassign'; all 52 prior apply_scenario clause BODIES byte-identical to HEAD by md5; count re-pinned both pin tests + moduledocs; Conformance.run → 53.
- INV5: slot-sound — src_lane derived from ARGV[3] (queue base), KEYS[1] (row) + KEYS[2] (dst lane) both built from the SAME queue → one {q} slot by construction; cross-queue not expressible (stronger than rejected).

BOUNDARY: 5 echo_mq files only (4 EDIT + 1 NEW), all UNSTAGED (no git). echo_wire + apps/echomq + mix.lock + keyspace.ex UNTOUCHED. The codemojex README.md (M) + codemojex.game_rules.md (A, staged) + emq.epic.1/emq.1.stories.md (D) are OPERATOR out-of-band pre-stage — EXCLUDE from the rung pathspec.

### T-5

V-1 — Stage-4 Director verify: INDEPENDENT pass GREEN (gates re-run on Valkey 6390 + adversarial probes + net-zero mutation)

GATES (Director re-ran — not Mars's word): compile --warnings-as-errors CLEAN; 4 doctests + 366 tests, 0 failures (full per-app :valkey suite); Conformance.run/2 → 53/53, CONF reassign ok.
INV1 (wire law): @greassign uses only g:-segment keys + the row; numeric sentinels -1/-2 (NOT error_reply) → wire-class registry UNEXTENDED; {emq}:version stays echomq:2.0.0. PASS.
INV2 (branded dst): lane_key!/2 (lanes.ex:265) raises before the wire; src valid-by-construction (the row's group, gated at enqueue). PASS.
INV3 (byte-freeze): git diff lanes.ex = +92/-0; ZERO removed redis.call lines; the 5 shipped Lua scripts + the pause/resume/limit host verbs byte-identical; @greassign + reassign/4 PURE additions. PASS.
INV4 (additive-minor): prior 52 apply_scenario BODIES byte-unchanged (only moduledoc prose reflowed); count re-pinned 52→53 in BOTH pin tests; the :reassign clause + @run_order entry additive. PASS.
INV5 (slot soundness / declared keys — the F-1 probe): KEYS[1..7] declared; src_lane derived from ARGV[3]=Keyspace.queue_key(queue,"") (the @gclaim:40 convention), KEYS[1] co-pins the slot; same-queue by construction (cross-queue not expressible → no dead path). PASS.
NO-INVENT: the -1/-2→atom sentinel idiom is REAL (jobs.ex:757/794, emq.2.2-D7), not invented; Metrics.lane_depths/3 shipped (metrics.ex:297). PASS.
ACCOUNTING PROOF: conformance reassign scenario (conformance.ex:1047) asserts gactive[dst]=="1" & gactive[src]==nil after claim, both nil after complete — the corruption guard D-3 demanded. PASS.
NET-ZERO MUTATION (LAW-1a): broke HSET row group=dst (→ stale src group); CAUGHT at 3 independent points (conformance {:error,[:reassign]}; lanes_reassign_test:63 row-group; :90 ceiling accounting); reverted byte-identical (diff HSET line = ARGV[2]; tests 12/0 green). The tests have teeth.
BOUNDARY: 5 echo_mq files only; no echo_wire/jobs.ex/keyspace.ex/apps/echomq/mix.lock.
VERDICT: the built surface is SHIP-READY as a NORMAL-risk rung; no remediation found (Stage-5 collapses). ONE open scope item → R3 (lane-scoped drain), routed to the Operator as a destructive-treatment fork.

### T-6 — Mars-2 harden COMPLETE (Stage 5): the lane-scoped destructive drain (R3 ruled BUILD, D-5), gates green

D-5 BUILT (the reassign surface @greassign + reassign/4 + lanes_reassign_test.exs stays BYTE-FROZEN — Mars-2's lanes.ex diff is purely additive, zero deleted lines):
- lanes.ex: NEW @gdrain inline Script.new/2 + drain(conn, queue, group) arity-3. Host gates group at lane_key!/2 (raises before wire). KEYS=[queue_base, lane, ring]; ARGV=[group]. Script (the Admin.@drain wipe scoped to ONE lane, admin.ex:84): ZRANGE KEYS[2] (lane) → per id DEL base..'job:'..id + ..':logs' (job key A-1-derived from declared base=KEYS[1]) → DEL KEYS[2] → LREM KEYS[3] (ring) 0 group → return #ids. Returns {:ok, n}. NO TIME (no lease).
- BLAST RADIUS (audited): @gdrain touches ONLY KEYS[2] (lane set), KEYS[3] (ring), and base..'job:'..id rows+logs. Forbidden-key grep EMPTY — no active/gactive/paused/glimit/repeat/flat-pending. The destructive op cannot over-reach by construction.
- conformance.ex: +lane_drain scenario (53→54). The scenario is the BLAST-RADIUS proof: enqueue 3 grouped on lane a + 1 on sibling b → claim a1 (→active, gactive[a]=1) → add log to a2 → register a repeat → drain a → assert {:ok,2}, a2/a3 rows + a2 logs + lane-a set gone, ring has no a but has b, a1 STILL active + gactive[a]=="1", sibling b row+set intact, repeat registry intact, an absent lane drains to 0. Re-pinned 53→54 in scenarios/0 + run/2 doc + module moduledoc.
- test/lanes_drain_test.exs NEW (6 :valkey tests): full delete (rows+logs+set+ring, count); in-flight-same-lane untouched (active + gactive); sibling untouched; paused/glimit config + repeat registry survive; empty/absent → 0; ill-formed group raises.
- conformance_run_test.exs + conformance_scenarios_test.exs: re-pinned {:ok,53}→{:ok,54}, @run_order +:lane_drain (after :reassign), moduledocs + test names "fifty-three"→"fifty-four".

SELF-MUTATION (the teeth proof, pre-empting the Director's battery): removed the ring LREM from @gdrain → CAUGHT at 3 points (CONF lane_drain FAIL {:fail,{:ok,1}} → 53/54; lanes_drain_test LPOS-ring assertion + 2 cascades). Reverted byte-identically (5 shipped scripts md5-confirmed unchanged; @gdrain restored c9ac7042…; suite back to 54/54).

GATES (Valkey 6390 PONG; elixir 1.18.4 / erlang 28.5.0.1):
- compile --warnings-as-errors: CLEAN (lib + tests).
- per-app suite --include valkey: 4 doctests, 372 tests, 0 failures (366 + 6 drain; full bus, no regression).
- Conformance.run/2: CONFORMANCE 54/54, CONF lane_drain ok + CONF reassign ok.
- multi-seed sweep (seeds 0-4) drain+reassign+conformance: 20 tests 0 failures each. ≥100 loop NOT run per D-5 (the drain mints no id, touches no TIME, starts no process — the loop would forge load; blast radius is the real hazard, proven by the scope audit + the conformance scenario + the self-mutation).

INV SELF-CHECK (HIGH-risk, destructive op):
- INV1: @gdrain keys all g:-segment lane + ring + the row (no new family); no priority/prioritized/pc; keyspace.ex grammar UNEDITED; {emq}:version echomq:2.0.0; drain returns {:ok,n} (no error_reply, wire-class registry UNEXTENDED).
- INV2: group gated at lane_key!/2 (raises) before wire; the ill-formed-group test proves the host-side raise.
- INV3: 5 shipped lane scripts + @greassign BYTE-FROZEN — the 5 md5-identical to HEAD (@genqueue 421526e8…, @gclaim 3d00686f…, @gpause 194b7f9c…, @gresume 7be3b500…, @glimit 41fff81d…); @greassign + reassign/4 untouched by Mars-2 (lanes.ex diff zero deleted lines, only @gdrain + drain/3 added).
- INV4: additive-minor — all 52 HEAD-existing apply_scenario bodies byte-identical; :reassign clause (Mars-1) intact; +lane_drain additive; count re-pinned both pin tests + moduledocs; Conformance.run → 54.
- INV5/blast-radius: KEYS[1] (base) pins the {q} slot; lane + ring + the derived job rows all share it; @gdrain declares 3 real KEYS, derives job keys from the declared base (A-1).

BOUNDARY: 6 echo_mq files (4 EDIT + 2 NEW: lanes_reassign_test.exs Mars-1 + lanes_drain_test.exs Mars-2), all UNSTAGED. echo_wire + keyspace.ex + jobs.ex + apps/echomq + mix.lock UNTOUCHED. codemojex (Operator out-of-band) not in the rung pathspec.

emq.4.1 is now HIGH-risk (drain built, all 4 control-plane axes complete). No remediation outstanding. Ready for the Director's DEEPENED verify (the destructive-op mutation battery).

### T-7

V-2 — Stage-4 DEEPENED verify (the destructive lane-drain, D-5): INDEPENDENT pass GREEN (the blast-radius mutation battery)

GATES (Director re-ran): compile --warnings-as-errors CLEAN; 4 doctests + 372 tests (366 + 6 drain), 0 failures; Conformance.run/2 → 54/54 (CONF reassign ok + CONF lane_drain ok).
@gdrain (lanes.ex:294) BLAST-RADIUS read: references ONLY KEYS[1]=base (job-key root), KEYS[2]=lane (ZRANGE+DEL), KEYS[3]=ring (LREM), + the derived base..'job:'..id rows + :logs. NO gactive/active/paused/glimit/repeat/flat-pending reference — blast radius contained BY CONSTRUCTION (no SCAN/KEYS*/wildcard; max damage provable by reading the key list).
INV3 (byte-freeze under the addition): lanes.ex +140/-0; ZERO removed redis.call lines; the 5 shipped scripts + @greassign + reassign/4 byte-identical (Mars-2 purely additive).
INV4 (additive-minor): conformance.ex logic-removed = NONE (only moduledoc prose reflowed); prior 53 scenario bodies (incl Mars-1's reassign) byte-unchanged; lane_drain additive; count re-pinned 53→54 in BOTH pin tests.
INV5 (declared keys): KEYS[1]=base pins the {q} slot; job keys A-1 derived; 3 declared real keys.
THE MUTATION BATTERY (both failure directions proven caught):
- OVER-REACH (Director's M1): injected HDEL gactive into @gdrain → CAUGHT at 2 points (conformance {:error,[:lane_drain]} → 53/54; lanes_drain_test:64 "gactive intact" → nil). The destructive-op's worst failure (corrupting in-flight accounting) is guarded.
- UNDER-CLEAN (Mars's self-mutation + scenario-asserted): skip the ring LREM → CAUGHT (the scenario's LPOS-ring-a==nil assert, conformance.ex:1134).
- Reverted byte-identical (lanes.ex removed-lines=0, HDEL-trace=0; tests back to 7/0, 54/54).
lane_drain SCENARIO (conformance.ex:1098) = a genuine blast-radius proof: in-flight a1 survives (active + gactive[a]=="1"), sibling lane b intact, repeat registry intact, an absent lane drains to 0.
BOUNDARY: 6 echo_mq files (lanes.ex, conformance.ex, lanes_reassign_test.exs, lanes_drain_test.exs, the 2 pin tests); no echo_wire/jobs.ex/keyspace.ex/apps/echomq/mix.lock.
VERDICT: emq.4.1 SHIP-READY as a HIGH-risk rung — both axes (reassign + lane-drain) built + independently verified; no remediation. NEXT: Venus syncs the triad to as-built (HIGH-risk, both verbs), then the LAW-4 ship.

### T-8 — emq.4.1 BACKWARD reconcile (post-build, pre-ship): the triad synced to as-built reality

Ran the lag-1 reconcile backward — diffed the shipped triad's forward-tense claims against the GREEN-verified as-built code, then synced. PROBED the real surface (lanes.ex:100-344 read; conformance + pin tests + byte-freeze grep), did NOT sync from the Director's report alone.

AS-BUILT CONFIRMED (cited from the real surface):
- TWO verbs shipped: reassign/4 (lanes.ex:262) + @greassign (:119); drain/3 (:319) + @gdrain (:294). Grep-verified no other reassign/move/drain verb.
- @greassign: HGET <row> 'group' (src-derive, :120) → ZREM src_lane (:124) → ZADD dst score 0 (:125) → HSET <row> 'group' dst (:126, the LOAD-BEARING rewrite) → re-ring dst (@genqueue guard, :127-135) → LREM src from ring if emptied (:136-138). Numeric sentinels: 1/0/-1/-2 → {:ok,:reassigned}/{:ok,:noop}/{:error,:not_found}/{:error,:not_pending} (no error_reply — registry UNEXTENDED). NO TIME.
- @gdrain: ZRANGE lane → DEL rows+logs → DEL lane set → LREM ring → return #ids (:294-304). Blast radius bounded: ONLY target lane's pending rows+logs+set + ring entry; NOT active/gactive/paused/glimit/sibling-lanes/repeat. NO TIME.
- BYTE-FREEZE VERIFIED: git diff HEAD lanes.ex redis.call lines are ALL '+' additions in @greassign/@gdrain — ZERO changes to the 5 frozen scripts (@genqueue/@gclaim/@gpause/@gresume/@glimit). INV3 holds at the source.
- CONFORMANCE 52 → 54: reassign (conformance.ex:118) + lane_drain (:119); both pin tests re-pinned (conformance_run_test.exs:47 {:ok,54}; conformance_scenarios_test.exs).
- jobs.ex UNTOUCHED — its group-field readers (HGET <row> 'group' at @complete:182/@retry:259/@promote:320/@reap:349) consume the field @greassign rewrites; the move WRITES what they READ.

TWO MATERIAL DELTAS from my forward-tense brief (corrected):
1. CROSS-QUEUE: my brief said "rejected host-side with {:error,:cross_queue}". As built it is NOT EXPRESSIBLE at arity 4 — src derived from the row, dst is a lane_key! of THIS queue, so both lanes share the one {q} slot; atomic BY CONSTRUCTION, not a rejected case. Better outcome than I specified. Synced everywhere (the stale cross-queue-rejection probe in the prompt's Stage-2 also fixed).
2. RISK NORMAL → HIGH: R3 was ruled BUILD (D-5), and the lane-scoped drain is a DESTRUCTIVE at-rest delete (a frozen-class hazard). The verify was the BLAST-RADIUS mutation battery (over-reach + under-clean both caught), NOT the ≥100 loop (the drain mints no id/TIME/process — the loop would forge load). Synced the risk tier, the Mode block, the gate ladder, the Stage-2 probes, the Risk-tier section.

FORK RULINGS RECORDED in the triad: Fork C → PARK (D-1, lanes score-0, @greassign ZADDs score 0 :125); version → additive-minor echomq:2.0.0 (D-1); verb name → reassign/4 src-derived (D-2); R3 → BUILD (D-5).

FILES SYNCED (docs/echo_mq/specs/emq.4/emq.4.rungs/): emq.4.1.md (body — status ✅ SHIPPED, Goal/5W/Scope/INV1-5/Fork C RULED/DoD all checked, as-built footer); emq.4.1.stories.md (rewritten — US1 cross-queue-not-expressible + sentinels, US2 not_pending, US3 the destructive drain + blast radius, US4 5 frozen scripts + 52→54, US5 HIGH/blast-radius, US-FORK ruled, Coverage); emq.4.1.llms.md (as-built banner + R1/R3/R5/R7 + topology + AS1/AS2/AS3 synced); emq.4.1.prompt.md (Mode HIGH, fork-gate RULED, Stage-2 blast-radius probe, Risk-tier HIGH).

VERIFIED: no stale "52 → N"/"NORMAL-risk" residue (grep exit 1); count=54 in all four; both verbs named in all four; all load-bearing links resolve (incl. the echo-mq-ship/SKILL.md fix carried from the forward pass). The specs now MATCH as-built. Boundary clean: edited ONLY the triad + the ledger; NO production code, NO git.

### T-9

Y-1 (consolidation for Apollo) — emq.4.1 findings + learnings (Director-consolidated, Stage-7 input)

CRAFT/CONTRACT FINDINGS (→ the agent calibrations):
F1 [Venus WIN → emq.venus.md] — the lag-1 reconcile caught a LOAD-BEARING correctness finding: the lane move is NOT a ZSET swap, because the group is DENORMALIZED onto the job row and read at 4 jobs.ex sites (complete:182/retry:259/promote:320/reap:349) to find the lane + adjust gactive. The move MUST HSET row group=dst atomically or it silently corrupts ceiling accounting (gate-invisible without a move→claim→complete cycle). LEARNING: when a mutation touches a denormalized field, re-probe EVERY read-site of that field before pinning the contract.
F2 [Mars WIN → emq.mars.md] — arity-4 src-derived BEAT the brief's arity-5: passing src invites a src-mismatch failure the row already answers; AND it makes cross-queue NOT EXPRESSIBLE (one queue arg → one {q} slot), strictly stronger than a guarded rejection. LEARNING: prefer the signature that makes the invalid state unrepresentable over the one that guards it.
F3 [Mars WIN → emq.mars.md] — numeric sentinels (-1/-2→atom) over error_reply kept the wire-class registry UNEXTENDED (INV1). LEARNING: host-mapped sentinels for host-distinguishable refusals; error_reply only for genuine wire classes (jobs.ex emq.2.2-D7 precedent).
F4 [META → emq.program.md] — the destructive drain is HIGH-risk for BLAST RADIUS, not determinism. The right gate was the MUTATION BATTERY (over-reach HDEL gactive + under-clean skip-ring-LREM both caught), NOT the ≥100 loop (the drain mints no id/TIME/process — the loop would forge load). LEARNING: match the rigor to the HAZARD — ≥100 loop = id-mint/process/lease determinism; mutation battery = destructive blast radius; blast-radius-by-construction (no SCAN/KEYS*) is auditable by reading the key list.
F5 [process → emq.program.md] — R3 (the destructive lane-drain) emerged MID-BUILD (Mars flagged it as a build-time judgment); the Operator ruled BUILD, bumping NORMAL→HIGH. LEARNING: a destructive-treatment choice can surface mid-build — surface it to the Operator (don't decide it), and re-grade the risk + verify depth when it lands.
F6 [Venus WIN → emq.venus.md] — the triad sync ran the lag-1 reconcile BACKWARD post-build, catching 2 deltas (cross-queue framing, risk grade) so the committed spec matches as-built. LEARNING: reconcile both directions — forward before build, backward after.

PROCESS (→ emq.program.md reconcile):
- The as-built run flow: Director bootstrap+fork-rule (Fork C park, version additive-minor) → Venus author+reconcile (F1) → Director rule verb D-3 → Mars build reassign → Director verify (net-zero mutation) → R3 fork mid-build (F5) → Operator rules BUILD D-5 → Mars-2 build drain → Director DEEPENED verify (mutation battery F4) → Venus triad-sync-backward (F6) → Director ship (LAW-4 rung commit 6bca0d6d + separate 3.0-note commit 7dc828ff) → Apollo Stage 7. Does emq.program.md describe this loop + the Stage-7 (Apollo calibrate+reconcile, D-2/D-4) element?
- Minor coordination note: a redundant Mars-2 directive crossed with Mars's proactive drain build (built before the directive → re-confirmed, not rebuilt). LEARNING: when a builder proactively extends scope, confirm-don't-rebuild.

Apollo (Stage 7) spawned to fold these into docs/echo_mq/program + reconcile it against the as-built run + eval the @gdrain destructive-op craft. PROPOSE-ONLY, Director-ratified.

### T-10 — Apollo Stage-7 COMPLETE: calibrate + reconcile docs/echo_mq/program + the destructive-op eval (PROPOSE-ONLY, Director-ratified)

OUT of the per-rung pipeline (no build/verify/finish). Three dimensions on the Director's Y-1 consolidation, all docs-only, no production code, no git.

A · CALIBRATE — ONE guardrail per finding, aimed at the implicated contract:
- emq.venus.md ← F1 (when a mutation touches a DENORMALIZED field, re-probe EVERY read-site before pinning the contract — the lane move HSETs row group=dst because jobs.ex reads it at @complete/@retry/@promote/@reap; sharpened into the reconcile remit). F6 (reconcile in BOTH directions — forward pre-build, backward post-build pre-ship; folded into the lag-1 reconcile bullet).
- emq.mars.md ← F2 (prefer the signature that makes the invalid state UNREPRESENTABLE over the one that guards it — reassign/4 src-derived made cross-queue not expressible). F3 (host-mapped numeric sentinels for host-distinguishable refusals; error_reply only for a genuine wire class — kept the closed registry unextended, INV1). Both added under the build step.
- emq.program.md ← F4 (match the gate's rigor to the HAZARD — a destructive at-rest op draws the MUTATION BATTERY + blast-radius-by-construction probe, NOT the ≥100 loop, which forges load; added to the gate ladder). F5 (a rung's risk tier can change MID-BUILD — surface, don't decide, Operator rules, re-grade NORMAL→HIGH + deepen verify; confirm-don't-rebuild a proactive scope extension; footgun #8).
- emq.apollo.md ← Job 3, the Operator-grantable Stage-7 extensions (process-doc reconcile D-4 + destructive-op eval D-5), recording this run's own role so the next high-risk-rung Apollo reads it.

B · RECONCILE (docs → shipped reality; Venus's lag-1 applied to the process docs):
- DRIFT: emq.program.md frontier read "Movement I CLOSED — conformance 52/52" + emq.4 as "NEXT" (lines 20, 128) — STALE. The roadmap (the shipped reality, synced at ship 7dc828ff) already records emq.4.1 ✅ SHIPPED + the echomq:3.0.0 era. SYNCED the manual to it: live conformance 54/54; emq.4.1 the fair-lanes control plane SHIPPED (reassign + lane-drain, HIGH-risk); the version arc (additive minors over frozen echomq:2.0.0 → cumulative 3.0.0 major at emq.8); NEXT = 4.2→4.4. "Movement I CLOSED AT 52/52" kept as the correct historical fact.
- DRIFT: the Apollo roster bullet cast Stage 7 as calibrate-only ("no closure reconcile"). RECONCILED: Stage 7 is Operator-grantable-extensible — (a) process-doc reconcile (D-4), (b) destructive-op eval on a HIGH-risk rung (D-5); both PROPOSE-ONLY, docs-only. The per-rung build-closure reconcile/spec-sync stays the Director's/Venus's (preserved the distinction).
- CROSS-CHECK: the manual, the roadmap, and the calibrations now agree on the live count (54), emq.4.1's status, and the 3.0.0 version arc.

C · DESTRUCTIVE-OP EVAL (@gdrain, lanes.ex:294) — VERDICT: blast radius CONTAINED (Y).
- The key list (read at the source): KEYS[1]=base (job-key root only), KEYS[2]=lane set (ZRANGE+DEL), KEYS[3]=ring (LREM ARGV[1]), + derived base..'job:'..id rows + :logs. NO SCAN/KEYS*/wildcard → max damage provable by reading the 11-line body. Forbidden-key grep (gactive|active|paused|glimit|repeat|de:|delay|sched) = EMPTY.
- The lane_drain conformance scenario (conformance.ex:1098) is a genuine blast-radius proof — it positively asserts the SURVIVORS: in-flight a1 still :active + gactive[a]=="1" (:1137-1138), sibling lane b row+set intact (:1140-1141), repeat registry present (:1143), an absent lane drains to 0 changing nothing (:1145). The corruption direction is gated, not just the deletion.
- Gate REPRODUCED independently (Valkey 6390 PONG, elixir 1.18.4 / erlang 28.5.0.1): compile --warnings-as-errors CLEAN; CONFORMANCE 54/54 (CONF reassign ok + CONF lane_drain ok printed); conformance_run + conformance_scenarios + lanes_drain + lanes_reassign suites = 20 tests, 0 failures. INV3 byte-freeze re-verified at the source (zero '-redis.call' lines in the lanes.ex diff). Count pinned 54 in BOTH pin tests with :reassign + :lane_drain in run order.

FILES EDITED (docs/echo_mq/program ONLY): emq.venus.md, emq.mars.md, emq.program.md, emq.apollo.md. PROPOSE-ONLY — the Director ratifies + commits as a SEPARATE commit (not the rung). No skill/charter edits this run (all six findings map to the program docs; none recurred enough to need a skill-level guardrail). Boundary clean: docs only, no production code, no git.

### T-11

Ratification — Apollo's Stage-7 program calibration RATIFIED (Director review of the full diff)

Reviewed the complete `git diff -- docs/echo_mq/program/` (4 files, +93/-13). All sound:
- emq.venus.md (F1 denormalized-field read-sites + F6 both-directions reconcile) · emq.mars.md (F2 unrepresentable>guarded + F3 sentinels-vs-error_reply) · emq.program.md (F4 hazard-matched gate + F5 mid-build risk re-grade/footgun-8 + the Stage-7 grantable extension + the echomq:3.0.0 arc + the 52→54 frontier reconcile) · emq.apollo.md (Job 3 the grantable Stage-7 extensions).
- GROUNDED: each guardrail cites a real emq.4.1 finding + the as-built surface. ACCURATE: the reconcile facts correct (52/52 = Movement-I-close historical; 54/54 = live; emq.4.1 SHIPPED). NO OVERREACH: the PROPOSE-only fence preserved; no invented surface; no first-person agent voice.
- The @gdrain destructive-op eval (Apollo, independently reproduced: key-list no-SCAN/KEYS* + the survivor-asserting scenario + 54/54 gate) → blast radius CONTAINED, matching the Director's own mutation battery (V-2).
RATIFIED → committing as a SEPARATE program-calibration commit (not the rung). No skill/charter edits (first-occurrence findings, kept lean). Stage 7 + the run CLOSED; frontier → emq.4.2 (group-aware recovery).

## {emq-4-1-decisions} Decisions

### D-1 — the two pre-build forks ruled (Operator, via the Director's AskUserQuestion)

FORK C (intra-group priority — land at 4.1 vs park) → RULED PARK (Arm B). Lanes stay score-0; the ring rotation IS the fairness, and score-0 + the time-ordered branded JOB id gives FIFO-by-mint head-selection (@gclaim ZPOPMIN) for free. A non-zero lane score would change which member is the head, pulling 4.1 into the byte-frozen @gclaim it is authored to leave untouched (INV3). The carve was authored to park → NO re-scope. The intra-group priority band is RECORDED as parked (a future rung's option), not built here.

VERSION POSTURE (the "EchoMQ 3.0 / echomq:3.0.0" kickoff framing vs the committed emq.4 INV1 "wire at echomq:2.0.0, no fence code") → RULED additive-minor now + record the 3.0 target separately. emq.4.1 ships additive-minor — {emq}:version stays echomq:2.0.0, no fence code, no new wire class, no wire break (INV1 holds); conformance grows 52→N. The echomq:3.0.0-by-end-of-emq.8 horizon target is recorded as a FORWARD note in emq.roadmap.md as a SEPARATE scoped commit (NOT the 4.1 rung commit), so Movement II's version arc is on record without bumping the wire now. The 3.0.0 ratification = a cumulative horizon-end major over the accumulated additive minors (an emq.8 concern); no emq.4 rung re-breaks the wire.

### D-2 — Stage 7 GRANTED: Apollo mentor calibrates the echo_mq 3.0 program + team (explicit Operator grant)

The Operator adds Stage 7 to this run and GRANTS the calibration the skill gates behind an explicit Operator grant: after the ship (Stage 6), the Director CONSOLIDATES the rung's findings + learnings (the full T/D/V/Z ledger + the Stage-4 verify findings + the Stage-5 harden notes) and spawns Apollo — the Mentor, OUT of the per-rung pipeline (it does not build/verify/finish) — to fold them forward. PROPOSE-ONLY; the Director ratifies each proposal.

TARGET (Operator-named): docs/echo_mq/program — the operating manual `emq.program.md` + the agent calibrations `emq.venus.md` / `emq.mars.md` / `emq.apollo.md`. Apollo ALSO folds the Movement II / echomq:3.0.0 horizon framing into the program docs (the 3.0-era posture; the version arc per D-1: additive minors now → a cumulative 3.0.0 major ratified by end of emq.8). Apollo MAY additionally PROPOSE one-guardrail-per-finding edits to the `.claude/skills/echo-mq-{architect,implementor}` skills or the role charters — each separately Director-ratified.

SEQUENCING: Apollo runs AFTER Stage 6 — it needs the consolidated findings; no rung findings exist until build+verify+harden complete. Apollo edits docs only (the program docs; PROPOSE-only for skills/charters); NEVER production code, NEVER git.

### D-3 — the re-assignment verb ruled + the multi-key atomic move contract (Venus recommended, Director-verified on disk)

VERB: EchoMQ.Lanes.reassign(conn, queue, job_id, dst_group) — ARITY 4, src-derived. House style (terse single words: enqueue/claim/pause/resume/limit/depth); reads as the operator verb; matches the spec's "re-assignment" terminology. If a later need arises, move/5 is the fallback — NOT chosen.

CONFIRMED CORRECTNESS REQUIREMENT (Director independently re-probed lanes.ex + jobs.ex): the move MUST atomically HSET <row> 'group' = dst. Evidence: @genqueue writes the group on the row (lanes.ex:23); jobs.ex reads HGET <row> 'group' at @complete:182, @retry:259, @promote:320, @reap:349 and uses it to rebuild the lane key + adjust gactive[g]. A stale row group → wrong-lane gactive accounting on the next complete/reap — gate-invisible WITHOUT a move→claim→complete conformance test (the new scenario MUST include that full cycle, not just the ZSET swap).

THE MOVE SCRIPT (a new inline @greassign, declared keys, NO priv/): ZREM src_lane (src derived server-side from the row's HGET'd group + the ARGV queue base — the A-1 ARGV-slot-rooted convention, EXACTLY as @gclaim derives its lane at lanes.ex:40) + ZADD dst_lane SCORE 0 (preserves FIFO-by-mint; the member keeps its mint-ordered place) + HSET row group=dst + ring re-shape BOTH ends (LREM src from ring if its pending emptied — mirrors @gclaim:57–58; RPUSH dst + LPUSH/LTRIM wake if dst is serviceable: not paused AND gactive[dst] < glimit[dst] AND not already on ring — mirrors @genqueue:25–32 / @gresume). NO TIME (no lease touched). NO gactive MUTATION (a pending member is not counted in gactive — only @gclaim increments it). Declare ≥1 real KEYS[] to pin the {q} slot (the emq.2.1 F-1 law).

INV2 REFRAME (recorded): dst gated host-side at Lanes.lane_key!/2 (raises on ill-formed) before the wire; src is the row's stored group — valid-BY-CONSTRUCTION (gated at enqueue by @genqueue's lane_key!/2). Arity-4 eliminates the arity-5 src-mismatch failure mode. The INV2 check becomes "an ill-formed DST raises before the wire" (src cannot be ill-formed — it is a live lane member).

INV5 BY CONSTRUCTION: arity-4 single-queue ⟹ src + dst lanes share the one {queue} hashtag ⟹ same slot ALWAYS (the group is outside the braces). A cross-queue move is NOT EXPRESSIBLE — strictly stronger than rejected. DROP the dead {:error, :cross_queue} path Venus's brief sketched; the scenario drops the cross-queue assertion.

EDGE CASES (Mars-2 harden): not-found / not-grouped (HGET group nil) → typed refusal (e.g. {:error, :not_found}); not-pending / in-flight (ZREM src_lane returns 0 — the member is claimed, counted under src's gactive) → {:error, :not_pending}, and DO NOT HSET the row (rewriting an in-flight job's group corrupts the OTHER gactive direction at complete); same-group (dst == src) → idempotent {:ok, :noop} (or {:ok, :reassigned}) with no wire churn.

### D-4 — Stage 7 scope EXTENDED: Apollo also RECONCILES docs/echo_mq/program against the as-built run (Operator directive)

Extends D-2. Apollo's Stage-7 mandate now has TWO dimensions, both PROPOSE-ONLY + Director-ratified, edits confined to docs/echo_mq/program (PROPOSE-only for skills/charters):

(1) CALIBRATE (D-2) — fold THIS run's findings/learnings forward into the operating manual (emq.program.md) + the agent calibrations (emq.venus.md / emq.mars.md / emq.apollo.md) + the Movement II / echomq:3.0.0 framing; one guardrail per finding.

(2) RECONCILE (this directive) — check docs/echo_mq/program AGAINST how THIS run ACTUALLY ran (the emq-4-1.progress.md ledger trace + the as-built Flat-L2 stage flow: Director bootstrap+fork-rule → Venus author+reconcile → Director rule the verb [D-3] → Mars build → Director verify → Mars-2 harden → Director ship → Apollo calibrate+reconcile), and SYNC any drift between the documented pipeline/roles and reality. This is Venus's lag-1 reconcile discipline applied to the PROCESS docs — emq.program.md is the spec FOR the loop; Apollo is its steward. Distinct from calibrate: reconcile is corrective (docs→reality), calibrate is additive (findings→guardrails).

Sequenced AFTER the ship (Stage 6) — the run must complete to BE the reconcile evidence. Never production code, never git. Grants: D-2 (calibrate) + D-4 (reconcile).

### D-5 — R3 RULED: build the lane-scoped destructive drain now (Operator) → emq.4.1 bumps NORMAL → HIGH-risk

The Operator ruled BUILD (not park): emq.4.1 gains a lane-scoped drain, completing all four named control-plane axes. This adds a DESTRUCTIVE at-rest delete → the rung is now HIGH-RISK.

THE CONTRACT (modeled on the shipped Admin.@drain at admin.ex:84, scoped to ONE lane):
EchoMQ.Lanes.drain(conn, queue, group) — arity 3. A NEW inline @gdrain Script.new (never priv/): ZRANGE the lane g:<group>:pending → DEL each job row + its :logs subkey → DEL the lane set → LREM the group from the ring; return #drained. KEYS=[queue_base, lane, ring]; ARGV=[group]. KEYS[1]=base pins the {q} slot, the job keys derive from it (the Admin.@drain A-1 convention). Host gates group at lane_key!/2 (raises). Returns {:ok, n}.
SCOPE — what it MUST NOT touch (the destructive-op safety): NOT active/in-flight (mirrors Admin.drain — active jobs continue), NOT gactive (counts in-flight, not pending), NOT paused, NOT glimit, NOT the repeat registry, NOT any SIBLING lane. ONLY the target lane's pending rows + logs + set + the ring entry.
PROOF: a conformance scenario (53→54, suggested name lane_drain) — enqueue N grouped on a lane (+ a sibling lane + optionally one in-flight) → drain → assert the lane set + the drained rows + logs gone, the ring entry gone, n returned, AND active/gactive/sibling-lane/repeat-registry UNTOUCHED; :valkey edge tests (empty lane→0, in-flight untouched, sibling untouched, rows+logs actually deleted, ill-formed group raises). Re-pin 53→54 in BOTH pin tests. INV3: the 5 original shipped scripts + @greassign byte-frozen.

CONSEQUENCES OF THE BUMP:
- Mars-2 (same identity, second pass) builds the drain; the reassign surface (@greassign + reassign/4 + tests) stays byte-frozen.
- The Director's verify DEEPENS for the destructive op: the FULL MUTATION BATTERY (mutate @gdrain to over-delete / touch active / touch a sibling lane / skip the ring LREM — confirm each CAUGHT) + blast-radius scope probes. NOT the ≥100 loop (the drain mints no id, touches no TIME, starts no process — the loop would forge load; blast radius is the real hazard).
- Apollo MANDATORY (already granted Stage 7 via D-2/D-4) — its scope GAINS the destructive-op adversarial evaluation (does drain's blast radius match its contract?).
- The roadmap fold + the triad sync record emq.4.1 as HIGH-risk (drain built), not NORMAL.

## {emq-4-1-progress} Progress

### P-1 — emq.4.1 triad authored + reconciled (Stage 1 Venus DONE)

Authored the full emq.4.1 quad in docs/echo_mq/specs/emq.4/emq.4.rungs/ (beside the existing emq.4.1.md carve seed):
- emq.4.1.stories.md — US1 (re-assignment headline) · US2 (the move is sound past the ZSET swap — the row-rewrite/gactive correctness) · US3 (deepened control verbs + the re-aim) · US4 (byte-freeze + additive-minor) · US5 (proof + honest NORMAL posture) · US-FORK (Fork C park) · US-GATE (Valkey gate) + a Coverage map D1-D6 → stories.
- emq.4.1.llms.md — the Mars brief: References (read-order, the v1 re-aim records as FORM-NOT-TO-LIFT) · R1-R7 (each traced story→invariant) · Execution topology (the build-order DAG + the EXACT files + the gate ladder) · AS-FORK/AS1/AS2/AS3 agent stories (Directive + precondition/postcondition/invariant + acceptance gate) · the propagation clause.
- emq.4.1.prompt.md — the runbook: Flat-L2 NORMAL-risk, the ruled forks (C park / additive-minor) recorded, the verb-name/arity D-2 surfaced, the per-stage directives (Venus done · Mars build · Director verify · Mars-2 harden · Apollo OPTIONAL · Director ship), the gate ladder (per-app compile + :valkey suite + Conformance additive-minor + a multi-seed sweep, NO ≥100 loop with the honest posture stated), the Stage-6 pathspec.

LINK HYGIENE: all relative links resolved against the real filesystem; fixed one stale link (echo-mq-ship.md → echo-mq-ship/SKILL.md, the skill is a directory package). The jobs.ex group-field readers confirmed by grep: HGET <row> 'group' at jobs.ex:182/259/320/349 (@complete/@retry/@promote/@reap) — the move's row-rewrite is load-bearing over FIVE consumers (T-2 correctness finding holds).

Boundary clean: edited ONLY the triad + the ledger. No production code, no git. BUILD-GRADE.

## {emq-4-1-complete} Complete

### Z-1 — emq.4.1 SHIPPED: the fair-lanes operator control plane (reassign + lane-drain), HIGH-risk, BUILD-GRADE

Movement II opener, BUILD-GRADE on Valkey 6390. Two verbs deepening the shipped EchoMQ.Lanes:
- Lanes.reassign(conn,queue,job_id,dst_group)/4 + @greassign (lanes.ex:119/262) — the multi-key atomic move: ZREM src + ZADD dst (score 0) + HSET row group=dst + ring re-shape. The row-rewrite is LOAD-BEARING (jobs.ex reads HGET row 'group' at :182/259/320/349). Re-aims RETIRED v1 changePriority-7 (no numeric priority) + getCountsPerPriority-4 → Metrics.lane_depths/3. Cross-queue not expressible at arity 4. D-3.
- Lanes.drain(conn,queue,group)/3 + @gdrain (lanes.ex:294/319) — the Admin.@drain wipe scoped to one lane (ZRANGE → DEL rows+logs → DEL lane → LREM ring); blast radius contained BY CONSTRUCTION. R3 ruled BUILD → HIGH-risk. D-5.
FORKS: C parked (lanes score-0; D-1) · version additive-minor echomq:2.0.0 (D-1) · R3 build (D-5).
GATE: compile --warnings-as-errors clean; 4 doctests + 372 tests/0 failures; Conformance 54/54 (52→54 additive-minor, prior 52 byte-frozen, re-pinned both pin tests); INV1-5 confirmed; the 5 shipped lane scripts byte-frozen (md5).
VERIFY (Director, independent): the blast-radius mutation battery — over-reach (HDEL gactive) + under-clean (skip ring LREM) both CAUGHT, reverted net-zero; the reassign net-zero (stale-row caught at 3 points). NOT the ≥100 loop (no id-mint/process/lease hazard — honest posture). V-1/V-2.
TRIAD: synced backward to as-built (Venus T-8) — 2 verbs, HIGH-risk, forks recorded; cross-queue "not expressible" improved on the forward brief.
SHIP: one LAW-4 pathspec commit (code 6 + triad 4 + ledger 2 + the roadmap/progress fold). Boundary echo_mq only (no echo_wire/jobs.ex/keyspace.ex/apps/echomq/mix.lock). The echomq:3.0.0-by-emq.8 horizon note rides a SEPARATE commit (D-1). NEXT: Apollo (Stage 7, MANDATORY for the destructive op) — calibrate + reconcile docs/echo_mq/program + the destructive-op craft eval; then frontier emq.4.2 (group-aware recovery).
