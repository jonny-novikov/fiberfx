# emq-4-3 — AAW scope ledger

## {emq-4-3-thinking} Thinking

### T-1 — emq.4.3 §0 derivation (park-don't-poll metronome; Fork A → Arm B)

[5W] Harden/found the wake-notify beat so a parked consumer is served within the beat with NO lost wakeup + fair wakes across parked consumers. Movement II, groups family, 3rd sub-rung (after 4.1 control plane ✅, 4.2 recovery ✅). Mode Flat-L2, HIGH-risk (Apollo MANDATORY, ≥100 determinism loop, deepened Director verify).

[As-built, VERIFIED] The park-don't-poll CORE is SHIPPED & robust: consumer.ex spawn_link loop (:40), beat_ms 1000 (:58), loop reap→promote→drain→park (:91-98), park = BLPOP emq:{q}:wake <beat> via Connector.command/3 (:144-149). Wake-push (LPUSH 'wake' + LTRIM 0 63) baked into every serviceable transition: jobs.ex ×4, stalled.ex ×1, lanes.ex grouped path ×1. Single per-queue wake LIST capped 64, shared across all lanes/consumers. The token-LIST design AVOIDS the classic lost-wakeup by construction (the wake persists; BLPOP consumes it; drain is exhaustive so one token triggers full service).

[Solution space incl. do-nothing] The shipped loop is robust on the happy path — do-nothing is a real baseline. Risk concentrates in (a) multi-consumer/multi-lane fairness on the single shared wake, (b) cross-run same-ms branded-id mint contention.

[Reconcile deltas the build MUST carry] (1) seed repeats "prior 52 byte-unchanged" — live pin is {:ok, 55} (conformance_run_test.exs:48) → re-pin 55→N; (2) invariants pin {emq}:version = echomq:2.0.0 — live climbing fence is echomq:2.4.2 → emq.4.3 advances it to echomq:2.4.3.

[Invariants as runnable checks] lost-wakeup (:valkey admit-while-parked + park-boundary race → served within the beat); fairness (N parked, none starved); server clock on any touched lease (grep host-ts = 0); additive-minor (prior 55 byte-unchanged, re-pin both pinning tests); byte-freeze unchanged script logic (grep redis.call on diff = 0 where the rung doesn't name it); no wire break.

[Smallest change] Under Arm B: the minimal NEW blocking-claim primitive that subsumes the wake-token two-step; the mechanism + the frozen-wire question are the next fork (D-1).

[Toolchain] Erlang 28.5.0.1 / Elixir 1.18.4 (echo/.tool-versions); Valkey 6390 → PONG.

### T-2 — V-1 emq.4.3 reconcile begins (Arm B re-derivation)

Director ruling D-1: Fork A → Arm B (found a NEW blocking-claim primitive that subsumes the shipped wake-token two-step). The seed emq.4.3.md was authored to Arm A (deepen) — must re-derive to Arm B.
First reconcile reads confirm two deltas already:
- consumer.ex:147 — park/1 = `Connector.command(s.conn, ["BLPOP", wake, secs], s.beat_ms + 2_000)`. The connector ALREADY carries an arbitrary blocking command with a custom (beat+2000ms) timeout. The seed's "no new connector verb needed for BLPOP" is MATCH.
- consumer.ex:91-97 — loop = check_control → reap → promote → drain(rotating claim) → park. drain (114-142) is exhaustive recursion until Lanes.claim → :empty. So one wake token triggers full lane service (the lost-wakeup-by-construction argument the seed makes).
- consumer.ex:40 spawn_link (NOT GenServer) MATCH; beat_ms default 1000 :58 MATCH.
Next: the FROZEN WIRE verdict (echo_wire Connector public API + the committed freeze records), the wake-push sites (lanes.ex/jobs.ex/stalled.ex), the live conformance count + version fence.

### T-3 — emq.4.3 reconcile COMPLETE + FROZEN-WIRE VERDICT

RECONCILE TABLE (all MATCH except 2 STALE deltas, both carried):
- consumer.ex: park loop spawn_link:40 (NOT GenServer) / beat_ms 1000:58 / loop reap→promote→drain→park :91-97 / park/1 = Connector.command(conn,["BLPOP",wake,secs],beat_ms+2000):144-149 — all MATCH the seed.
- lanes.ex: @gclaim ring rotation `LMOVE ring ring LEFT RIGHT`:38, server-clock TIME lease :50-51, ZPOPMIN head; wake-push (LPUSH p..'wake' '1' + LTRIM 0 63) in @genqueue:30-31 @gresume:77-78 @glimit:94-95 @greassign:132-133 @greap_group:375-376. Single per-queue wake LIST capped 64. MATCH.
- jobs.ex wake-push: @complete:200-201 @retry:277-278 @promote:336-337 @reap:366-367. stalled.ex @sweep_stalled:83-84. All server-clock TIME. MATCH. (7 wake-push scripts total across the 3 files.)
- DELTA 1 (count): live conformance = {:ok, 55}, NOT seed's 52. conformance_run_test.exs:48 `== {:ok, 55}`; conformance_scenarios_test.exs @run_order = 55 names (last: dedup_release region). emq.4.2 prompt confirms 54→55 at 4.2 ship. RE-PIN 55→N.
- DELTA 2 (fence): @wire_version "echomq:2.4.2" (connector.ex:35), NOT seed's "echomq:2.0.0". emq.4.2 climbed 2.4.1→2.4.2 in lockstep (mix.exs label + @wire_version + {emq}:version, D-3). emq.4.3 climbs 2.4.2→2.4.3. NOT 3.0.0 (that MAJOR is ratified at emq.8).

FROZEN-WIRE VERDICT: Connector/RESP/Script frozen by committed records (echo_wire.ex:12-14 states it; EchoWire facade = the forward name). Public connector surface: command/3, pipeline/3, eval/5, push_command/3, subscribe/2, unsubscribe/2, noreply_pipeline/3, transaction_pipeline/3, stats, wire_version. command/3 (connector.ex:49) carries ARBITRARY parts with a custom timeout — park's BLPOP rides it (consumer.ex:147). A blocking BLMOVE/BLMPOP would ride the SAME command/3 verb → NO new connector verb, NO echo_wire edit, NO facade change for either Arm-B mechanism. The connector is a serialized FIFO GenServer — a blocking command/3 holds the WHOLE connector for the block; the consumer already holds a DEDICATED connector lane (moduledoc "blocking verbs get their own lane"), so this is sound.

## {emq-4-3-decisions} Decisions

### D-1 — Fork A ruled: Arm B (found a new blocking-claim primitive)

Operator ruled Fork A = Arm B (NOT the recommended Arm A). emq.4.3 re-scopes from "deepen the shipped BLPOP-wake loop" to "found a NEW blocking-claim primitive" that subsumes the wake-token two-step.

Opens a mechanism sub-fork: (i) server-side blocking grouped-claim — block directly on the ring/lanes (BLMOVE/BLMPOP). NOTE Connector.command/3 ALREADY carries blocking commands (park uses BLPOP today with a custom timeout), so (i) may ride the EXISTING connector with NO frozen-wire edit. vs (ii) a dedicated metronome process distinct from EchoMQ.Consumer that owns the beat/notify. The frozen-wire-touch question is the pivotal reconcile delta (the wire broke once → a touch is the risk surface).

NEXT: Venus authors the triad to Arm B + frames the mechanism fork as four-part Arms; Director rules it via AskUserQuestion BEFORE Mars. Dual-architect escalation GATED on the reconcile putting a frozen-wire touch genuinely in play. HIGH-risk stands either way (Apollo MANDATORY, ≥100 loop, deepened verify).

## {emq-4-3-learnings} Learnings

### L-1 — Arm B's mechanism (i) collides with design §12.2, which is the spine of the whole fork

The design canon §12.2 (emq.design.md:457-463) already RULED against client-side multi-key pops (LMPOP/ZMPOP): "Availability is not the blocker (Since 7.0.0); necessity is. Every v2 state transition is one Lua script — atomic on the engine — so a client-side pop would BYPASS the script layer's event and bookkeeping path: a second, weaker transition path is the opposite of a wire contract... claim IS ZPOPMIN inside the claim script, so the client-side variant has no role at all." And §12.5 (emq.design.md:483-490): the 2.0 core wire is bounded by the 7.0-level CEILING; floor ≈ 6.2-level (LMOVE the newest); "a computed-floor raise is a protocol minor at minimum."
IMPLICATION for Arm B mechanism (i) — server-side blocking grouped-claim (BLMOVE/BLMPOP on the ring/lane): a Lua EVAL CANNOT block (no blocking command is allowed inside a script — Valkey rejects it). So the block MUST be a connector-level blocking command FOLLOWED by the atomic @gclaim EVAL. But the ring is `LMOVE ring ring LEFT RIGHT` (rotate) and the lane is a ZSET (ZPOPMIN). A BLMOVE blocks on a LIST; the lane is a ZSET, so BLMOVE cannot pop the lane. BLMPOP (7.0, at the ceiling) blocks on a ZSET but pops the member OUTSIDE the @gclaim script — bypassing the TIME lease + attempts mint + gactive bookkeeping + the ring-rotation fairness — EXACTLY the §12.2-forbidden "second weaker transition path." So a blocking pop that REPLACES the wake-token two-step would either (a) need the block on a NEW per-lane signal LIST (a wake-shaped key, BLMOVE-able) feeding the SAME @gclaim EVAL (a block-then-claim, NOT a block-AND-claim) — which is the wake token RENAMED, not subsumed; or (b) bypass @gclaim (forbidden). This is the decisive cost the steward analysis must surface: Arm B's "subsume the two-step" is in TENSION with the design's one-transition-one-script law + the §12.2 ruling. A genuine subsumption keeps @gclaim as the claim and only changes how the consumer BLOCKS — i.e. it blocks on the readiness signal directly (a server-side block) instead of BLPOP-on-wake-then-drain. The signal it blocks on is still a §6-grammar key.
