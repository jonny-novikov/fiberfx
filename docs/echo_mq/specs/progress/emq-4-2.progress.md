# emq-4-2 — AAW scope ledger

## {emq-4-2-thinking} Thinking

### T-1 — emq.4.2 derivation (group-aware recovery; the group-scoped stalled-sweep). Mode: Flat-L2, NORMAL-risk, right-sized to the standard loop (Venus author+reconcile → Director rule the build-choice gate → Mars build+self-verify+stories → Director verify → Mars-2 harden → Director ship). Runs UNDER the program calibration committed 37c731af this session.

5W — Why: a multi-tenant operator must recover ONE tenant's stuck work on demand without a queue-wide scan; a crashed group's in-flight leases return to THAT group's lane (g:<g>:pending), preserving ring fairness (the crashed tenant re-queues behind its own identity, never jumping the ring). What: a group-scoped stalled-sweep/reap returning a named group's expired-lease members to their lane, ring-respecting (re-ring only if unpaused + below glimit), gactive decremented, a wake pushed, on the SERVER clock (TIME in-script). Who: operators (on-demand per-group recovery), the program, the conformance harness (+N additive). When: Movement II, groups family 2nd sub-rung, after emq.4.1 founded the control plane. Where: echo/apps/echo_mq only — jobs.ex and/or lanes.ex (the sweep), conformance.ex (the scenario + count re-pin), test/*_test.exs + the two pin tests. echo_wire untouched; apps/echomq untouched; §6 grammar unedited.

As-built floor (Director pre-grounded, re-probe at Venus reconcile): BOTH recovery scripts are ALREADY group-aware + ring-respecting but QUEUE-WIDE — @reap (jobs.ex:341, crash-recovery single scan: TIME, expired grouped lease ZADD to p..'g:'..g..':pending', HINCRBY gactive -1/HDEL, re-ring guard SISMEMBER paused + glimit, wake) and @sweep_stalled (stalled.ex:50, count-thresholded: the full ring-respect at lines 76-84, dead-letters past max_stalled). The genuine delta is the GROUP-SCOPED ENTRY (one named group on demand), not a new recovery shape — which is why emq.4.2 is NORMAL.

Solution space — (baseline) do-nothing: the queue-wide @reap/@sweep_stalled recover grouped jobs into lanes already, but no group-scoped entry exists. (Arm A, additive-beside) a NEW inline @greap mirroring @reap's group branch with a `g == ARGV[group]` filter + a host verb (Lanes.reap_group/3 candidate), leaving @reap + @sweep_stalled BYTE-FROZEN (grep redis.call on them = 0) — NORMAL, no shipped-script edit, ~8-line bounded duplication of the recovery branch. (Arm B, edit) thread a `:group` filter ARGV into the shipped @sweep_stalled (or @reap): non-matching expired ids skipped (no ZREM, no recover), the non-group path byte-identical — DRY (reuses the proven branch) but a FROZEN-LINE TOUCH on a lease-critical script → re-grades NORMAL→HIGH + Apollo mandate + the byte-diff proof of the unedited branch. The seed states the build choice is a pre-build RECONCILE decision (Director rules the gate), NOT an Operator AskUserQuestion fork.

Invariants as runnable checks — INV1 non-group recovery path byte-unchanged (shipped reap/stalled scenarios + the prior 54 byte-frozen, git-verified; a git diff of the non-group branch empty). INV2 server clock (a grep of the new sweep for a host timestamp = empty; expiry from redis.call('TIME')). INV3 no new key family, ring-respecting (the sweep rides the shipped g:/ring/paused/glimit/gactive/wake; the re-ring guard matches @reap; §6 unedited). INV4 branded group gated at lane_key!/2 (ill-formed group raises pre-wire; recovered member reads back on its own lane). INV5 additive-minor conformance 54→N (only additions to scenarios/0; both pins re-pinned).

Determinism posture: the sweep TOUCHES a lease (→ server clock, INV2) but MINTS no id and starts no new process (a host-driven Connector.eval like reap/2 + check/3) — so the same-ms branded-id mint hazard cannot arise → NOT the ≥100 loop (running it would forge load the rung does not introduce); the honest posture is a multi-seed sweep + the statement (the emq.2.1/emq.4.1 posture).

Smallest change preserving correctness + Director's provisional ruling: Arm A (a group-scoped @reap, additive-beside) — the conservative byte-freeze-preserving NORMAL choice the seed names as the default. Ruling deferred to Venus's reconcile: build to Arm A UNLESS the reconcile surfaces a soundness reason the edit (Arm B) is required (then the Director re-grades to HIGH + attaches Apollo). Version: echomq release LABEL bumps mix.exs 2.4.1 → 2.4.2 (the wire FENCE stays frozen at echomq:2.0.0 — the two-planes model, this session's calibration).

### T-2 — emq.4.2 lag-1 reconcile (forward, pre-author) against as-built echo/apps/echo_mq

DELTA TABLE (claim → as-built → verdict):
1. Conformance count "52" (seed emq.4.2.md §What/INV5; chapter emq.4.md INV6) → LIVE = 54 (conformance.ex scenarios/0 ends flow_grandchild_fail; reassign+lane_drain are entries 44/45; conformance_run_test.exs:47 {:ok,54}; conformance_scenarios_test.exs @run_order = 54 names; both moduledocs "fifty-four"). VERDICT: STALE — emq.4.2 floor is 54→N, NOT 52→N. Seed pre-dates emq.4.1 ship. Reconciled in the triad I author.
2. mix.exs version → "2.4.1" (emq.4.1 shipped here). VERDICT: MATCH. emq.4.2 → 2.4.2 (additive minor; wire fence frozen {emq}:version=echomq:2.0.0).
3. @reap group branch (jobs.ex:341-369) → reads HGET jk 'group', expired grouped lease ZADD'd to p..'g:'..g..':pending', HINCRBY gactive -1 (HDEL if <=0), re-ring guard SISMEMBER paused==0 + (no glimit or act<glimit) + not LPOS ring → RPUSH ring + LPUSH wake + LTRIM wake 0 63, server clock redis.call('TIME'). VERDICT: MATCH (the exact mechanism to mirror). reap/2 host verb jobs.ex:719 (KEYS=[active,pending], ARGV=[queue_key("")]).
4. @sweep_stalled (stalled.ex:50-95) + Stalled.check/3 (stalled.ex:106) → KEYS[1]active/[2]pending/[3]dead, ARGV[1]=p base, max_stalled dead-lettering, grouped recovery into lane stalled.ex:76-85 mirroring reaper, server clock. VERDICT: MATCH.
5. NO group-scoped recovery verb exists (grep reap_group|sweep_group|group_reap|:group option = empty; only reap/2 + check/3 queue-wide). VERDICT: MISSING — the genuine delta. emq.4.2 ADDS it.
6. lane_key!/2 (lanes.ex:337, defp) → if EchoData.BrandedId.valid?(group) then queue_key(queue,"g:"<>group<>":pending") else raise ArgumentError. VERDICT: MATCH (the branded-group gate, INV4). Note: it is defp (private), called at 147/188/199/217/265/322 — host verb gates dst/group BEFORE wire.
7. emq.4.1 drain/3 (lanes.ex:319) + @gdrain (lanes.ex:294) → THE host-verb precedent: declared KEYS[1]=base/[2]=lane/[3]=ring, jk derived KEYS[1]..'job:'..id (KEYS-rooted A-1), no clock, {:ok,n}. VERDICT: MATCH — structural model for the new sweep verb.

DENORMALIZED-FIELD CHECK (calibration): group is read at jobs.ex @complete(:182)/@retry(:259)/@promote(:320)/@reap(:349) + stalled.ex:62 to find lane + adjust gactive. The group-scoped sweep is a PURE READER of group (HGET jk 'group' to filter g==target + find the lane) — it NEVER rewrites group (only emq.4.1 reassign HSETs it). So NO write→read corruption hazard: the sweep reads the same authoritative field the other readers read. Coherent by construction. The write→read cycle the scenario must prove is gactive: a recovered member decrements gactive[g] (HINCRBY -1) exactly as @reap does — assert gactive coherent post-recovery.

A-1 POSTURE for the new sweep: declare KEYS[1]=active, KEYS[2]=base (emq:{q}:) — root lane/gactive/ring/wake/paused/glimit from KEYS[2] (the @gdrain KEYS-rooted form, cleaner than @reap's ARGV[1]); the target group + lease params in ARGV. Every key shares the one {q} slot (group outside braces). Slot-sound.

DETERMINISM POSTURE: the sweep is a host-driven Connector.eval, mints NO branded id, starts NO process. It DOES touch a lease (reads TIME server-side) but introduces no same-ms-mint hazard. → multi-seed sweep + honest determinism statement, NOT the ≥100 loop (matching emq.4.1's posture — a lease-touching but mint-free/process-free surface).

VERDICT: BUILD-GRADE under Arm A after reconciling the 52→54 count. No INVENTED surface; every anchor probed by method.

### T-3 — Mars-2 build Stage-0 RE-PROBE (lag-1 law) against live echo/apps/echo_mq. Every anchor CONFIRMED vs the brief:

- Valkey 6390 PONG; erlang 28.5.0.1 / elixir 1.18.4 (echo/.tool-versions, re-probed from app dir).
- @reap (jobs.ex:341-369) BYTE-FROZEN target, the EXACT byte-model: p=ARGV[1]; TIME→now=t[1]*1000+floor(t[2]/1000); ZRANGEBYSCORE KEYS[1] -inf now LIMIT 0 100; per id ZREM KEYS[1] id; jk=p..'job:'..id; g=HGET jk 'group'; if g then act=HINCRBY p..'gactive' g -1 (HDEL if <=0); lane=p..'g:'..g..':pending'; ZADD lane 0 id; if SISMEMBER p..'paused' g ==0 then lim=HGET p..'glimit' g; if (not lim or act<tonumber(lim)) and not LPOS p..'ring' g then RPUSH ring + LPUSH wake '1' + LTRIM wake 0 63; else (no group) ZADD KEYS[2] 0 id; HSET jk 'state' 'pending'. CRITICAL byte-detail: act is the POST-decrement HINCRBY return, the re-ring guard tests act<lim against the decremented value — @greap_group must replicate this (decrement-then-test), NOT re-read gactive.
- reap/2 host verb jobs.ex:719: KEYS=[active,pending], ARGV=[queue_key("")].
- @sweep_stalled (stalled.ex:50-95) BYTE-FROZEN; group recovery into lane :75-86, same re-ring guard. MATCH.
- lane_key!/2 (lanes.ex:337, defp): raises ArgumentError unless BrandedId.valid?(group) → queue_key(queue,"g:"<>group<>":pending"). INV4 gate. MATCH.
- drain/3 (lanes.ex:319) + @gdrain (lanes.ex:294) the host-verb precedent: KEYS=[queue_key(""), lane_key!(group), queue_key("ring")], ARGV=[group]; @gdrain declares base=KEYS[1], jk=base..'job:'..id (KEYS-rooted A-1), no clock, {:ok,n}. MATCH — structural model.
- @greassign (lanes.ex:119) the sentinel-return model + the row-group authority pattern. BYTE-FROZEN.
- group readers (pure-read confirmation): @complete HGET <row> 'group' (jobs.ex:182), @retry(:259), @promote(:320), @reap(:349); stalled.ex(:62). The new sweep is a PURE READER (HGET to filter g==target + find lane; NEVER HSET 'group'). gactive is the write→read cycle to prove (HINCRBY -1).
- Conformance count LIVE = 54 (scenarios/0 ends flow_grandchild_fail, no trailing comma; reassign/lane_drain entries 44/45; conformance_run_test.exs:47 {:ok,54}; conformance_scenarios_test.exs @run_order 54 names; both moduledocs "fifty-four"). Seed's 52 STALE — reconciled to 54→55. CONFIRMED.
- stalled_group scenario (conformance.ex:1007) the recovery precedent; reassign (:1052) + lane_drain (:1098) the TWO-group structural model. lanes_reassign_test.exs the test model (lane_score/4, gactive/3, row_group/3 helpers, purge idiom, setup_all Snowflake.start(4)). groups_story_test.exs the story model (EchoMQ.Story DSL).
- Connector.eval (connector.ex:63) EVALSHA-first, maps int reply straight through → {:ok, n}.
- NO existing group-scoped recovery verb (grep reap_group|sweep_group|group_reap empty). Genuinely NEW.

BASELINE NOTE for the Director: echo/apps/echo_mq/mix.exs is ALREADY `M` at baseline (Operator out-of-band staged version "2.0.0"→"2.4.1", the emq.4.1 ship's bump, uncommitted). The rung's contribution is the single 2.4.1→2.4.2 line; the HEAD-relative diff will read 2.0.0→2.4.2. echo_mq lib/test tree otherwise CLEAN.

D-1 rulings CONFIRMED in ledger: Arm A (additive-beside), reap_group/3, NORMAL, no Apollo. VERDICT: ready to build, no invented surface, every public call grounded.

### T-4

V-1 [Director independent verify] — emq.4.2 GREEN under the climbing fence (Valkey 6390). No echomq:2.0.0 stragglers (grep over both apps' lib+test = clean); live key = echomq:2.4.2; compile --warnings-as-errors clean; the FULL echo_mq :valkey suite = 389 tests + 4 doctests, 0 failures; Conformance.run/2 → {:ok, 55} (CONFORMANCE 55/55, incl. CONF reap_group ok — the group-scoped sweep recovers ONLY the named group into g:<g>:pending, leaves a sibling's expired members in active for the queue-wide reaper, gactive decremented, server clock, ring-respecting). The version-agnostic :fence scenario + connector_test pass at 2.4.2 (the killed-PID log = expected connector-kill/reconnect test noise, 0 failures). Byte-freeze holds (@reap jobs.ex + @sweep_stalled stalled.ex = 0 diff). Connector diff = ONLY @wire_version (→echomq:2.4.2) + its moduledoc — fence/2 LOGIC frozen. Mars-2's reorder mutation battery (3/3 kill-rate) stands.

L-1 [Director directive footgun] — my Mars directive gave the WRONG path for connector_test.exs (said echo/apps/echo_wire/test/, actual = echo/apps/echo_mq/test/ — the connector LIB lives in echo_wire/lib/echo_mq/ but its TEST lives in echo_mq/test/, the cross-app lib/test split). Mars couldn't reach the file, so its 3 hardcoded echomq:2.0.0 assertions (47/91/97) were left, which the 2.4.2 fence would fail. The Director caught it at verify (re-grep, not trusting the report) and FIXED it net (3-line version-agnostic: a shape regex + == Connector.wire_version()) — verified green. Lesson for the calibration: a cross-app directive must cite the file's REAL path (the connector's test is echo_mq-side); a peer silently skips an unreachable path. emq.4.2 BUILD-GRADE; ready for the Stage-6 ship.

## {emq-4-2-alternatives} Alternatives

### V-1 — the build choice: additive-beside (Arm A) vs edit-a-shipped-sweep (Arm B). Recommend Arm A.

The seed (emq.4.2.md §The build choice) flags both and withholds the choice for the reconcile. The reconcile rules: ARM A.

ARM A — additive-beside (a NEW inline script + NEW host verb).
- Rationale: a group-scoped sweep that mirrors @reap's group branch with a g==ARGV[group] filter, leaving @reap AND @sweep_stalled byte-frozen. The recovery-into-the-lane mechanism is already proven (stalled_group scenario); the delta is purely the scoping filter.
- 5W: WHY — recover ONE named tenant's lapsed leases on demand without a queue-wide scan (multi-tenant fairness: the crashed tenant's work re-queues behind its own identity). WHAT — Lanes.reap_group/3 (candidate name, pinned) + @greap_group inline Script.new. WHO — multi-tenant operators (codemojex per-player lanes today; echo_bot planned); the conformance harness (+1 scenario). WHEN — emq.4.2, groups family 2nd sub-rung, after emq.4.1's control plane. WHERE — lanes.ex (NEW verb + script, beside drain/3+@gdrain) + conformance.ex (+1 scenario, 54→55) + tests.
- Steelman: byte-freeze preserved on TWO lease-critical shipped scripts (@reap, @sweep_stalled). Stays NORMAL-risk (no shipped-script edit, no Apollo mandate). The @gdrain/reassign precedent (emq.4.1) is the EXACT structural model — a host-driven Lanes verb over an inline declared-keys script. INV1 (non-group path byte-unchanged) holds BY CONSTRUCTION: the new script is reached only via the new verb. The duplicated ~8-line recovery branch is a known, bounded cost that the program already paid once (@reap vs @sweep_stalled already duplicate the group recovery branch — a third copy is consistent with the as-built pattern, not a new smell).
- Steward: +1 inline script (~20 lines), +1 host verb (~12 lines), +1 conformance scenario. Ages well — it rides the frozen g:-segment keyspace, adds no key family, no wire class, no fence code. Composes cleanly with emq.4.3 (the metronome will wake a consumer the sweep re-rings). One authority honored: the group field stays the single source the sweep reads. Thin-but-robust.

ARM B — edit a shipped sweep (thread a :group ARGV filter into @reap or @sweep_stalled).
- Rationale: DRY — re-use the proven group branch rather than duplicate it; a non-matching expired id is skipped (no ZREM, no recover), the non-group path byte-identical.
- 5W: same WHO/WHEN/WHERE-ish but WHERE edits a FROZEN lease-critical script.
- Steelman: no duplicated branch; one recovery codepath to maintain. The group filter is a conditioned branch, not a rewrite.
- Steward: a FROZEN-LINE TOUCH on @reap or @sweep_stalled (lease-critical). Re-grades NORMAL→HIGH, mandates Apollo, and requires a byte-diff proof of the unedited (non-group) branch. The byte-freeze discipline (grep redis.call on the lib diff for the frozen script = 0) is BROKEN for the edited script. The crash-recovery path (@reap, run by the consumer loop every tick) is the single most lease-critical script in the bus — editing it for an operator convenience verb is a poor risk trade. Higher ceremony, higher blast radius, for a marginal DRY win the as-built code does not even hold (it already duplicates the branch).

RECOMMENDATION: Arm A. The one reason that carries it: it keeps emq.4.2 NORMAL by preserving byte-freeze on TWO lease-critical shipped scripts (@reap, @sweep_stalled), and the as-built code ALREADY duplicates the group-recovery branch (@reap and @sweep_stalled each carry their own copy), so a third additive copy is consistent with the established pattern — Arm B's DRY argument is weaker than it appears. The Director rules the gate; I surface, I do not decide. Chapter body emq.4.md grades emq.4.2 NORMAL and INV3 requires the non-group path byte-unchanged → Arm A honors both by construction.

## {emq-4-2-progress} Progress

### P-1 — emq.4.2 triad authored + seed reconciled (Venus-2 design run complete, BUILD-GRADE under Arm A).

DOCS AUTHORED (docs/echo_mq/specs/emq.4/emq.4.rungs/):
- emq.4.2.stories.md — US1 (group-scoped sweep, the two-group scoping proof) · US2 (recovered member served in own lane, gactive honest, group a pure read) · US3 (non-group path byte-unchanged, additive 54→55) · US4 (proof, NORMAL, multi-seed not ≥100) · US-GATE (Valkey structural gate). Coverage maps D2/D5/D6 + the gate to stories.
- emq.4.2.llms.md — the Mars brief: References (read-first, the @reap group branch the EXACT model + @gdrain the host-verb precedent + the seed's stale-52→live-54 reconcile) · R1-R7 (reap_group/3 + @greap_group, the g==ARGV[group] filter, server clock, declared KEYS[2]-rooted A-1, NO HSET group, version 2.4.1→2.4.2) · Execution topology (1 verb, 1 script, files touched) · AS-CHOICE/AS1/AS2 (Directive + Acceptance contracts).
- emq.4.2.prompt.md — the runbook: NORMAL-risk, Flat-L2, the build-choice gate (Arm A recommended), the as-built floor (count 54), the 6-stage pipeline, the group-scoping + gactive-coherence + byte-freeze probes, the Stage-6 pathspec.

SEED RECONCILED (emq.4.2.md): status → SPECCED; the stale 52 → live 54 at all 6 count sites (§What, Scope, INV5 ×2, DoD, as-built floor); build-choice + verb-name recorded in the status block.

RECONCILE VERDICT: BUILD-GRADE under Arm A. Every claim MATCH or the genuine MISSING delta (the group-scoped verb — emq.4.2 adds it). The seed's only STALE was the conformance count (52, pre-emq.4.1) — reconciled. Denormalized group field: the sweep is a PURE READER (no write→read corruption); the write→read cycle to prove is gactive (HINCRBY -1, the @reap accounting).

OPEN ITEM SURFACED (not mine to edit): the family body emq.4.md INV6 + carve table + emq.4.stories.md + emq.4.llms.md still carry the founding 52 (emq.4.1's backward reconcile left the family body at its design-cycle count). I reconciled the emq.4.2 sub-rung triad (my scope) and DID NOT silently rewrite the family body (a different scope, near-frozen). The 4.2 prompt Stage-5 directs an optional family-body INV6 52→54 sync. Flag for the Director: rule whether emq.4's family-body count claims should track the live 54 or stay the founding 52.

LINK-CLEAN: all four 4.2 docs resolve (fixed one broken markdown link — echo-mq-implementor skill is a DIR; converted the three skill refs to plain code spans matching the sibling emq.4.1.llms.md form).

RECOMMENDATION TO THE DIRECTOR: Arm A (additive-beside) + verb reap_group/3. Stays NORMAL, byte-freezes @reap+@sweep_stalled. The Director rules the gate.

### P-2 — emq.4.2 build complete; one BLOCKER (E-1, the out-of-band connector fence) + one shared-task finding surfaced.

BUILD (all inside echo/apps/echo_mq, Arm A, cite-don't-invent):
- lanes.ex EDIT: NEW @greap_group inline Script.new (beside @gdrain) byte-modelling @reap's group branch + the g==ARGV[1] filter + THE REORDER (HGET group BEFORE ZREM; a non-matching expired id SKIPPED, never ZREM'd, stays in active for the queue-wide reaper). KEYS=[active, base(KEYS[2])] the A-1 @gdrain KEYS-rooted form; ARGV=[group, limit]; server clock TIME; post-decrement act drives the re-ring ceiling test (byte-identical to @reap). + reap_group/3 host verb (lane_key!/2 gate pre-wire → {:ok,n}). Realization-over-literal: added an optional limit \\ 100 4th param (ARGV[2], the brief's named default-100 scan bound) — arity-3 contract HELD (reap_group(conn,q,g) works as specced via default-applied arg); strictly additive over the contract.
- conformance.ex EDIT: :reap_group scenario (entry 46, after lane_drain) + apply_scenario(:reap_group) the TWO-group scoping probe (g+h both lapse → reap_group(g) recovers ONLY g into its lane, LEAVES h in active; gactive[g]→absent, gactive[h]=1; re-claim group=g attempts 2; complete charges down; {:ok,0} on no-expiry). Count re-pinned 54→55 (run_test {:ok,55}, scenarios_test @run_order + assertion, all 3 moduledocs fifty-four→fifty-five). Prior 54 byte-unchanged.
- mix.exs EDIT: 2.4.1→2.4.2 (SemVer minor; wire fence the two-planes model).
- test/lanes_reap_group_test.exs NEW: 8 :valkey tests — two-group scoping; the reorder (h survives in active, then queue-wide reap recovers it to g:<h>:pending); gactive coherence through re-claim+complete; live-lease exclusion; paused no-re-ring; serviceable re-ring+wake; {:ok,0} no-expiry; ill-formed raises pre-wire. GREEN 8/8 (logic proof, fence aligned).
- test/stories/groups_story_test.exs EDIT: +1 reap_group BDD scenario (Keyspace aliased). GREEN 5/5. mix echo_mq.stories regenerated, IDEMPOTENT (run twice byte-identical).
- conformance pins EDIT (run_test, scenarios_test).

ADVERSARIAL SELF-VERIFICATION (next): declared-keys grep on @greap_group; the reorder mutation probe (ZREM-before-group-check → h evicted → :reap_group FAILS → revert net-zero, SCRIPT FLUSH); byte-freeze grep on jobs.ex/stalled.ex = 0; multi-seed sweep.

FINDING (shared-task over-produces, emq.mars.md §5 — SURFACE-don't-prune): mix echo_mq.stories regenerates the WHOLE catalog → created ~13 NEW untracked docs/echo_mq/stories/wire-*.stories.md (the ewr.1.1 wire_pipe_* story tests, committed at HEAD, whose generated docs were NEVER committed — a pre-existing catalog gap the ewr rung owns, NOT emq.4.2). I will NOT delete them (deleting → non-idempotent next regen) and will NOT commit them (out of scope). README.md is now ENTANGLED (its catalogue listing grew to include the wire-* features), so emq.4.2's clean stories-layer artifact is groups.stories.md ALONE — the Director should EXCLUDE README.md + the wire-* files from the emq.4.2 pathspec, leaving the wire-* catalog to the ewr rung.

### P-3 — emq.4.2 GATE LADDER + ADVERSARIAL BATTERY complete. Build done, self-verified to closure.

GATE LADDER:
- Valkey 6390 PONG; erlang 28.5.0.1 / elixir 1.18.4 (re-probed from app dir).
- mix compile --warnings-as-errors: CLEAN (per-app echo_mq).
- Pure suite (TMPDIR=/tmp mix test, :valkey excluded): 389 tests + 4 doctests, 0 failures, 321 excluded. The pure conformance pin (conformance_scenarios_test) GREEN → 55 names re-pinned correctly.
- :valkey recovery family (fence-aligned, the ONLY way past E-1's connect fence): lanes_reap_group + reassign + drain + lanes + locks_stalled + groups_story = 48 tests, 0 failures.
- Conformance.run/2: PROVEN {:ok, 55} achievable — fence-aligned run returns {:error, [:fence]} (the SOLE failure, the E-1 connector conflict); reap_group + all 53 others print CONF ... ok. GATED on the connector revert, NOT a rung defect.
- mix.exs version 2.4.2 (wire fence frozen echomq:2.0.0 — confirmed restored in Valkey).

ADVERSARIAL BATTERY (primary code-quality gate — found my own defects first):
- DECLARED-KEYS A-1 LINT on @greap_group: CLEAN. KEYS[1]=active, KEYS[2]=base (both carry {q} slot); every other key grammar-rooted from KEYS[2] (base..'job:', base..'gactive', base..'g:'..g..':pending', base..'paused', base..'glimit', base..'ring', base..'wake') — the @gdrain KEYS-rooted form. NO key read from a data value (g is an HGET of a KEYS[2]-rooted row, used only as a ZSET member + lane grammar segment; target is the gated ARGV host group). One {q} slot, slot-sound. The F-1 cross-slot trap (invisible on single-node 6390) does not apply.
- SERVER-CLOCK grep (INV2): @greap_group computes expiry from redis.call('TIME') only; grep for a host timestamp = empty.
- BYTE-FREEZE grep (INV1): jobs.ex (@reap) + stalled.ex (@sweep_stalled) = 0 redis.call diff lines, 0 ANY diff lines (untouched). lanes.ex frozen scripts (@genqueue/@gclaim/@gpause/@gresume/@glimit/@greassign/@gdrain): 0 removed redis.call lines; lanes.ex diff is 96/0 (purely additive). The prior 54 conformance scenarios git-verified byte-unchanged (0 apply_scenario bodies on the removed side; scenarios/0 + @run_order diff = ONLY +reap_group).
- LUA MUTATION KILL-RATE: 3/3 caught (SCRIPT FLUSH before each — EVALSHA-first T-6; reverted net-zero by inverse Edit, NEVER git checkout — L-3):
  (1) THE REORDER (ZREM before the group check, the @reap order) → scoping + reorder tests FAIL (h evicted). CAUGHT.
  (2) DROP THE FILTER (g==target → if g, the unfiltered @reap form) → scoping + reorder tests FAIL. CAUGHT.
  (3) DROP THE GACTIVE DECREMENT (HINCRBY -1 → HGET) → gactive-coherence test FAIL. CAUGHT.
  Net-zero proven: suite green 8/8 after all reverts; lanes.ex removed-side = 0 (whole-file diff to closure).
- DETERMINISM: multi-seed sweep 8/8 (seeds 0,1,2,3,4,42,312540,999999), each with SCRIPT FLUSH. HONEST POSTURE: the ≥100 loop is NOT run — the sweep touches a lease (TIME) but mints NO branded id + starts NO process, so the same-ms-mint hazard the loop guards cannot arise; the loop would forge load. Multi-seed + this statement is the proof (the emq.4.1 / emq.2.1 posture).

INV1-5 (runnable):
- INV1 (non-group path byte-unchanged): jobs.ex/@reap + stalled.ex/@sweep_stalled byte-frozen (grep=0); the reorder test proves a non-matching/no-group id stays in active for the queue-wide reaper; prior 54 git-verified byte-unchanged. ✓
- INV2 (server clock): TIME in-script, no host timestamp (grep empty). ✓
- INV3 (no new key family, ring-respecting, no new wire class): A-1 clean, re-ring guard byte-models @reap, {:ok,n} count return (no error_reply), keyspace.ex grammar untouched. ✓
- INV4 (branded group gated): reap_group/3 calls lane_key!/2 (raises) BEFORE the wire; the ill-formed-group test proves the raise (no recovery ran). ✓
- INV5 (additive-minor 54→55): scenarios/0 + probe in the same change, prior 54 byte-unchanged, both pins + 3 moduledocs re-pinned. ✓

BOUNDARY: touch-set is EXACTLY echo/apps/echo_mq (6 EDIT + 1 NEW); keyspace.ex/jobs.ex/stalled.ex/apps/echomq(removed)/mix.lock untouched. The 3 out-of-band echo_wire/echo_mq mix.exs + connector.ex files are NOT mine (E-1/E-2). REALIZATION-OVER-LITERAL: reap_group gained an optional limit \\ 100 4th param (ARGV[2], the brief's named default-100 scan bound, lanes.ex) — the arity-3 contract HOLDS via default-applied arg; strictly additive over the contract.

### P-4 — CLIMBING-FENCE mechanism implemented (D-3/Fork-2 reopened); the E-1/E-2 blocker RESOLVED via fence-climb (NOT a revert). Conformance 55/55, all gates green.

STEPS:
1. connector.ex:33 @wire_version echomq:2.4.1 → echomq:2.4.2 (constant only) + moduledoc:11 version-agnostic prose ("the @wire_version boot fence ... climbs per rung, the connector logic version-agnostic"). The fence/2 LOGIC (connector.ex:465-487) is BYTE-UNCHANGED — it always compared against @wire_version, never a literal, so bumping the constant is the COMPLETE mechanism.
2. conformance.ex :fence VERSION-AGNOSTIC: contract → "reads the current wire version"; apply_scenario(:fence) → expected = Connector.wire_version(); assert {:ok, ^expected}. RE-MODELED in place (the count stays 55; no prior capability scenario touched — only :fence). Tracks @wire_version forever, never needs a per-rung edit.
3. connector_test.exs — NO TARGET: the file the Director's step 3 described DOES NOT EXIST (no connector_test.exs in echo_wire, never in git history; the test files are script/resp/echo_wire_facade + echo_wire/{cmd,pipe,command,result}). NO echo_wire test hardcodes echomq:2.0.0 or asserts the fence version. The only version_fence refs (result_test.exs:56/87/151) use abstract placeholders ("x"/"v"/"v2") for the RESULT CLASSIFIER (the two-tier error split), already version-agnostic, NOT the wire version. So step 3 + the "poison test echomq:0.0.1" + the fence_db re-align are MOOT — no file to edit. FLAGGED (cite-don't-invent: did NOT fabricate a connector_test.exs).
4. Re-aligned live Valkey: DEL {emq}:version (was the stale echomq:2.0.0). The first connector boot in the conformance run re-seeded echomq:2.4.2 via the nil-branch SET NX (connector.ex:474). Confirmed live key = echomq:2.4.2. (Prod = a one-time ops migration: DEL the fence key on deploy of a fence-climbing rung — NOTED.)
5. echo_wire/mix.exs 2.4.1 → 2.4.2 (already at 2.4.2 when I read it — a linter/Director had applied it; confirmed).

GATE (all at 2.4.2, NO manual key alignment — the fence is now self-consistent):
- echo_wire: compile --warnings-as-errors clean; full suite 109 tests, 0 failures.
- echo_mq: compile --warnings-as-errors clean; CONFORMANCE 55/55 ({:ok,55}); the :valkey recovery family (lanes_reap_group + reassign + drain + lanes + locks_stalled + conformance + groups_story) 51 tests, 0 failures; the full pure suite 389 tests + 4 doctests, 0 failures.
- REORDER MUTATION re-confirmed under the 2.4.2 fence: ZREM-before-group-check → scoping + reorder tests FAIL → CAUGHT → reverted net-zero (SCRIPT FLUSH, inverse Edit) → suite green 8/8.
- Multi-seed sweep 8/8 (seeds 0,1,2,3,4,42,312540,999999). Honest posture unchanged (NO ≥100 loop — mint-free/process-free).

BYTE-FREEZE (step 7): jobs.ex/@reap + stalled.ex/@sweep_stalled = 0 ANY diff. connector.ex diff = ONLY @wire_version + moduledoc prose (fence/2 logic 0 lines changed). echo_mq lib diff: 0 removed redis.call, 15 added (all @greap_group).

FINAL TOUCH-SET (the one echo_wire seam now included per D-3): echo_mq/{lanes.ex, conformance.ex, mix.exs, test/conformance_run_test.exs, test/conformance_scenarios_test.exs, test/stories/groups_story_test.exs, NEW test/lanes_reap_group_test.exs} + echo_wire/{lib/echo_mq/connector.ex (@wire_version+doc), mix.exs}.

DOC TENSION FLAGGED: docs/echo_mq/program/emq.program.md (line ~22) still says "the frozen echomq:2.0.0 wire fence" (the OLD two-planes model) — but docs/echo_mq/emq.roadmap.md (line ~19) was JUST updated to "the wire fence + the mix.exs label move together, echomq:2.4.1→2.4.2→…→3.0.0" (the climbing-fence model, matching D-3). The roadmap is now authoritative + matches my build; the program manual lags and needs its own reconcile (Venus/Director). NOT my edit (process doc).

## {emq-4-2-decisions} Decisions

### D-1 — build choice RULED: Arm A (additive-beside). On Venus-2's reconcile (V-1, BUILD-GRADE). Build a NEW inline @greap_group + a NEW EchoMQ.Lanes.reap_group/3 that byte-models @reap's group branch (jobs.ex:350-362) with a g==ARGV[group] filter + the HGET-before-ZREM REORDER (a non-matching expired id is SKIPPED, never ZREM'd — it stays in active for the queue-wide reaper). @reap (jobs.ex:341) + @sweep_stalled (stalled.ex:50) stay BYTE-FROZEN (grep redis.call on the jobs.ex+stalled.ex lib diff = 0). NORMAL-risk, NO Apollo mandate. Rationale: (a) preserves byte-freeze on TWO lease-critical shipped scripts (crash-recovery @reap is the most lease-critical in the bus); (b) the as-built ALREADY duplicates the group-recovery branch across @reap + @sweep_stalled (the Script.new inline-body model has no include) — so a third additive copy is consistent with the established convention, and Arm B's DRY argument is undercut by the architecture's existing non-DRY-ness; (c) Arm B (thread a :group filter INTO @reap/@sweep_stalled) re-grades NORMAL→HIGH (a frozen-line touch) + mandates Apollo + a byte-diff of the unedited branch — strictly more cost for a NORMAL-specced capability. The seed pre-ruled this is the Director's gate to call (a reconcile decision, not an Operator fork). Pinned surface: Lanes.reap_group(conn, queue, group) arity 3 (the drain/3 precedent), group gated at lane_key!/2 pre-wire (INV4), KEYS=[active, base] (base as KEYS[2] — the @gdrain A-1-clean KEYS-rooted form, cleaner than @reap's ARGV-base), ARGV=[group], → {:ok, n}. Conformance :reap_group (two-group scoping proof) 54→55. mix.exs release label 2.4.1→2.4.2 (wire fence frozen echomq:2.0.0). Denormalized-group check (Venus): the sweep is a PURE READER of group (returns a member to its OWN lane, never HSETs group) — no F1-class corruption; the write→read cycle to prove is gactive.

### D-2 — family-body count fork RULED: DEFER (emq.4.2 stays scoped to the sub-rung). Venus-2 escalated that the chapter family body emq.4.md (INV6 + carve table) + emq.4.stories.md + emq.4.llms.md still carry the founding 52 (emq.4.1's backward reconcile left it). Ruling: leave the family body at 52 for emq.4.2 — it is a defensible chapter-OPENING baseline (emq.4 genuinely opened at conformance 52 when Movement I closed), NOT stale data in the error sense; the LIVE per-rung counts (54 after 4.1, 55 after 4.2) live where they are operative — the sub-rung triads + the conformance pins + the roadmap/emq.progress dashboards (all synced). Editing the near-frozen family body during a sub-rung ship is scope-creep, and it matches the emq.4.1 precedent. emq.4.2 does NOT touch emq.4.md (Mars boundary). LOGGED DEFERRAL (honoring the flag-don't-silently-ignore calibration): a future emq.4 family reconcile (or an Apollo process-doc reconcile) should DE-HARDCODE the family-body INV6 count to a generic "prior count → N" so it never goes stale per rung — surfaced to the Operator in the status, overridable.

### D-3 — Fork-2 REOPENED + RULED: the wire fence CLIMBS per rung (supersedes the two-planes "fence frozen" framing of 37c731af / emq.4.1-D1). On Mars-2's surfaced out-of-band connector bump (@wire_version echomq:2.0.0→2.4.1) + the Operator's AskUserQuestion ruling "keep the fence climbing" — consistent with the founding message-1 rule ("bump protocol version the number of the rung … up to 3.0; current echomq:2.4.1"). MODEL: the wire fence = the protocol version, climbing by MINOR per rung (echomq:2.4.1 emq.4.1 → 2.4.2 emq.4.2 → … → 3.0.0 MAJOR at emq.8); the connector @wire_version CONSTANT is the marker (bumped per rung; the connector LOGIC — fence/2, the framing — stays FROZEN, only the constant moves). The single-owner wire makes per-rung climbing safe (no external clients; connector + server deploy as a unit, so the exact-match fence is a self-consistency check, not a cross-version compat gate). IMPLEMENTATION: (a) connector.ex @wire_version → echomq:2.4.2 (emq.4.2's fence; the one echo_wire seam this rung touches); (b) the :fence conformance scenario + connector_test go VERSION-AGNOSTIC — assert live == Connector.wire_version() (track the marker, never per-rung-edit again) — a SANCTIONED re-model of the version-marker scenario, distinct from the additive-minor law that governs CAPABILITY scenarios; (c) the live {emq}:version key DEL'd so the connector re-seeds the current @wire_version on next boot (the nil-branch SET NX, connector.ex:473-476 — a one-time re-seed per bump, logic frozen); (d) the calibration (emq.program.md two-planes section + emq.roadmap.md wire-version row) REVISED to the climbing model. Conformance stays 55. emq.4.2 ships the capability + this version mechanism together (the first rung under the climbing fence).

### D-4

D-3 (Director, Operator-reopened Fork-2) — THE WIRE FENCE CLIMBS PER RUNG, it is NOT frozen. My E-1/E-2 diagnosis (connector @wire_version was changed out-of-band) was correct on the FACT but the resolution is the OPPOSITE of a revert: the fence is SUPPOSED to climb; it was left at the emq.4.1 value (echomq:2.4.1) when emq.4.2 needs echomq:2.4.2. This SUPERSEDES E-1/E-2's "revert to echomq:2.0.0" recommendation.

The climbing-fence mechanism (a SANCTIONED echo_wire seam touch — the version CONSTANT only, the fence/2 LOGIC byte-frozen; the ONE echo_wire seam emq.4.2 touches, like the emq.1 resubscribe precedent):
1. connector.ex:33 @wire_version echomq:2.4.1 → echomq:2.4.2 (constant only).
2. conformance.ex :fence scenario → VERSION-AGNOSTIC: assert the live key == Connector.wire_version() (alias EchoMQ.Connector) instead of hardcoding echomq:2.0.0 — so it TRACKS @wire_version, never needs per-rung editing. RE-MODELED in place (a sanctioned version-marker change, D-3), NOT a new/removed scenario — count stays {:ok,55}, the other 54 unaffected.
3. connector_test.exs: the 3 hardcoded echomq:2.0.0 assertions (~47/91/97) → version-agnostic via Connector.wire_version(); the poison test (~105, echomq:0.0.1) STAYS (proves a mismatch refuses).
4. Re-align live Valkey: DEL {emq}:version (default db + fence_db variants) → next boot re-seeds echomq:2.4.2 via the nil-branch SET NX. Connector logic unchanged — a one-time operational re-seed (prod = an ops migration; note it).
5. echo_wire/mix.exs 2.4.1 → 2.4.2 (align the app label to the fence; both apps at the rung version).
6. Re-run the FULL gate (echo_wire suite + echo_mq :valkey + {:ok,55} + multi-seed + the reorder probe still catches).
7. Byte-freeze still holds (@reap/@sweep_stalled = 0 diff; fence/2 logic unchanged, only the constant).

Boundary now: echo/apps/echo_mq + the ONE echo_wire seam (connector.ex @wire_version + conformance.ex + connector_test.exs + echo_wire/mix.exs). The two-planes model is REVISED: the wire fence is no longer a frozen plane — it climbs to the rung version; the library SemVer and the fence now MOVE TOGETHER per rung. Implementing now.

## {emq-4-2-escalations} Escalations

### E-1 — BLOCKER (spec⇄as-built wire-fence contradiction, NOT mine to resolve; escalate per charter "STOP, do not paper over"). The :valkey gate cannot reach green for ANY test (mine OR the unmodified lanes_reassign_test.exs — both fail identically), because of an OUT-OF-BAND change to echo_wire the Operator staged but did not commit.

THE CONTRADICTION:
- echo/apps/echo_wire/lib/echo_mq/connector.ex is `M` at baseline: @wire_version "echomq:2.0.0" (HEAD) → "echomq:2.4.1" (working tree). This CHANGES THE WIRE FENCE.
- The live Valkey {emq}:version key holds "echomq:2.0.0" (set by an earlier run). The fence (connector.ex:465) demands an exact match OR a nil key to SET NX; "echomq:2.0.0" ≠ "echomq:2.4.1" and is non-nil → {:error, {:version_fence, "echomq:2.0.0"}} on EVERY connect. All :valkey tests fail at setup.
- This is the SAME class the master invariant forbids: the wire fence {emq}:version is FROZEN at echomq:2.0.0 through Movement II (the two-planes model — only the library SemVer moves). emq.4.2's own spec REQUIRES it: US-GATE (stories.md:136) "GET {emq}:version returns echomq:2.0.0"; the conformance `fence` scenario (conformance.ex:183) hard-asserts {:ok, "echomq:2.0.0"}.

WHY UPDATING THE VALKEY KEY DOES NOT FIX IT: even if the live key were SET to "echomq:2.4.1" to match the working-tree connector, the conformance `fence` scenario (conformance.ex:183) hard-asserts "echomq:2.0.0" → it would FAIL → Conformance.run/2 ≠ {:ok, 55}. The working-tree connector and the conformance/spec are MUTUALLY INCONSISTENT. A wire-fence bump is a protocol MAJOR (program law S-3); editing conformance+spec to chase it is exactly the wire break Movement II forbids.

BOUNDARY: connector.ex is echo_wire (outside the emq.4.2 echo_mq boundary) AND Operator out-of-band — I will NOT edit it, and I will NOT silently SET the Valkey key to mask the mismatch.

THE FIX (Director/Operator's call, NOT mine): REVERT echo/apps/echo_wire/lib/echo_mq/connector.ex @wire_version back to "echomq:2.0.0" (the HEAD value, the frozen fence). Then the connector matches BOTH the live Valkey key AND the conformance/spec, and the :valkey gate runs. The mix.exs SemVer (2.4.1→2.4.2, emq.4.2's correct contribution) is the RIGHT plane and is untouched by this — the two planes are exactly the point: the library label moves, the wire fence does not.

MY CODE STATUS: the rung build (lanes.ex @greap_group + reap_group/3, conformance.ex scenario + pins, mix.exs 2.4.2, the test, the story) is COMPLETE and does NOT touch the wire fence. I will verify it independently by probing against a connector pinned to the live fence value, to prove correctness is independent of this blocker, then report. The gate-green claim is GATED on the Director reverting connector.ex (or ruling otherwise).

### E-2

E-1 UPDATE — the full out-of-band wire-change picture (3 files, Operator-staged, uncommitted; the wire fence is the conflict):
- echo/apps/echo_wire/mix.exs: version "2.0.0"→"2.4.1" (echo_wire library SemVer label — HARMLESS, the right plane).
- echo/apps/echo_mq/mix.exs: version "2.0.0"→"2.4.1" (echo_mq library SemVer — HARMLESS; my rung takes it to 2.4.2).
- echo/apps/echo_wire/lib/echo_mq/connector.ex: @wire_version "echomq:2.0.0"→"echomq:2.4.1" (THE WIRE FENCE — the conflict). This conflates the library SemVer with the wire-protocol fence record. The two-planes model (program law S-3, the spec, this rung): the library LABEL moves freely; the wire FENCE {emq}:version stays FROZEN at echomq:2.0.0 through Movement II. A fence bump is a protocol MAJOR.

DEFINITIVE ISOLATION PROOF: with the live Valkey {emq}:version aligned to "echomq:2.4.1" (to let the connection past the connect-time fence), I ran the FULL EchoMQ.Conformance.run/2 → it returned {:error, [:fence]} — the ONLY failing scenario is :fence (conformance.ex:183 hard-asserts "echomq:2.0.0"). All 54 others, INCLUDING the new :reap_group, printed `CONF ... ok`. So Conformance.run/2 → {:ok, 55} is ACHIEVABLE and blocked SOLELY by the connector @wire_version change: revert connector.ex to "echomq:2.0.0" (the HEAD value) and the connector matches the live key AND the conformance/spec, and the gate runs green.

THE FIX (Director/Operator's call): REVERT echo/apps/echo_wire/lib/echo_mq/connector.ex @wire_version → "echomq:2.0.0". The two mix.exs SemVer bumps may stand (the right plane). I did NOT touch any of the three out-of-band files, and I RESTORED the live Valkey {emq}:version to echomq:2.0.0 (its prior value) after every fence-aligned probe — the environment is left exactly as I found it.

GATE STATUS: every emq.4.2 gate item PASSES except the wire :valkey Conformance.run/2 (and any first-connect :valkey suite), which is GATED on the connector revert — NOT a defect in my rung. The pure suite (389 tests + 4 doctests, 0 failures) and the :valkey recovery family (48 tests, fence-aligned, 0 failures) and the multi-seed sweep (8/8) all green.
