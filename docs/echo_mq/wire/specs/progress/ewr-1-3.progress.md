# ewr-1-3 — AAW scope ledger

## {ewr-1-3-alternatives} Alternatives

### V-1 — the placement fork for the two-tier error split (transport vs server), four arms framed; design doc docs/echo_mq/wire/specs/ewr.1/ewr.1.3.design.md.

VERIFIED LOAD-BEARING FACT (the classifier rests on this): for the Connector.pipeline/3 family that exec/1 flushes through, a server error is ALWAYS the in-band value {:error_reply, binary()} inside {:ok, [reply]} — NEVER {:error, {:server, _}}. pipe_reply(:plain, replies) = {:ok, replies} (connector.ex:560); fill/5 pushes {:error_reply, msg} verbatim (connector.ex:573 → resp.ex:47). The {:error, {:server, _}} term is eval/5-EXCLUSIVE (connector.ex:76-77, map_script_reply :87), unreachable through EchoWire.Pipe. Pool.pipeline/3 (pool.ex:48) is a pure pass-through — identical shape against connector or pool.

ARM 1 (RECOMMENDED) — a pure EchoWire.Result classifier over exec's return. classify/1 (tagged tri-state {:ok,replies} | {:transport_error,term} | {:server_error,oks,[{idx,err}]}) + non_valkey_error/1 (NonValkeyError, transport only) + error/1 (Error, transport-or-server) + server_errors/1 (per-reply lens). exec/1 UNCHANGED.
  STEELMAN: thinnest skin over a distinction the wire already draws; changes NO existing surface (exec/1 byte-identical, no ewr.1.1 test moves); pure data over a value → fully offline-testable + one :valkey WRONGTYPE story; faithful rueidis port (two fns on the result, mirroring the two methods); One-authority (exec stays the source, RESP.reply() stays the type, it partitions); composes forward with ewr.1.2's %Cmd flags into the retry-layer pair.
  CHOSEN-AGAINST: (written once the Operator rules)

ARM 2 — new exec variants exec_split/1 + exec!/1 on Pipe (+ exception types); exec/1 left byte-unchanged.
  STEELMAN: split at the flush, no second |> hop; exec! is the idiomatic fail-fast surface; sits beside exec/1, honors the freeze at the letter.
  CHOSEN-AGAINST: grows the Pipe surface permanently (2 verbs + 2 exceptions + their pool/connector contract); mixes classify into the construction module (wider responsibility); exec! bakes a raise-on-server-error POLICY (a WRONGTYPE is often a branch); harder to test in isolation (flush-bound); puts the vocabulary in the wrong module — the inverse of the ewr.1.1 "can't extract clean fns from a verb-first surface" lesson.

ARM 3 — a per-reply lens only (server_errors/1); NO transport-tier surface.
  STEELMAN: freezes the least (one pure fn over a list); cheapest to maintain/test; thin-but-robust literally; forward-compatible (a later classify/1 could call it).
  CHOSEN-AGAINST: an incomplete port that re-fragments the split — ships half the PAIRED discriminator, leaves the transport tier folklore at every call site (the asymmetry that drifts); under-serves the headline retry consumer (which needs transport-vs-server, not just server); the "transport is already idiomatic" premise misses that the value is a UNIFORM named vocabulary, not reading {:error,term}.

ARM 4 — defer the rung; fold the split into ewr.1.2's command value (the do-nothing/baseline arm).
  STEELMAN: spends + freezes nothing; if the only consumer is a not-yet-built retry layer, building the vocabulary now risks freezing the wrong shape (MOVED/ASK redirect tier); keeps the option to design the discriminator WITH its consumer.
  CHOSEN-AGAINST: weak Steward because the split is NOT premature — its shape is already fully determined by the as-built return (transport {:error,term} vs in-band {:error_reply,_}), so there is nothing to defer away (unlike the design fork's genuinely-shapeless flag seam); leaves a RULED Movement-I rung unbuilt and every caller re-deriving the tiers by hand — the exact tax the program exists to remove; MOVED/ASK is moot single-node + reachable via the escape hatch.

SUB-QUESTION inside Arm 1 (surfaced, the public-shape choice): classify/1's result shape — (a) a tagged tuple tri-state [recommended: smaller frozen surface, idiomatic branch target] vs (b) a %EchoWire.Result{} struct [richer, a frozen struct]. The triad drafts (a).

DEFERRED SEAM (for the roadmap): cluster-redirect sub-classification (MOVED/ASK as a server-error sub-case, rueidis message.go:76-92) — opened when a cluster-routing consumer exists; Arm 1's server_errors/1 is forward-compatible (a router sub-matches the {:error_reply, msg} binaries with no surface change).

RECOMMENDATION: Arm 1, one reason — it names the two tiers exec already returns with the faithful rueidis discriminator at ZERO cost to the frozen exec/1 contract and zero new wire surface.

## {ewr-1-3-progress} Progress

### P-1 — ewr.1.3 design step COMPLETE. Authored: the four-arm design fork docs/echo_mq/wire/specs/ewr.1/ewr.1.3.design.md + the triad (ewr.1.3.{md,stories.md,llms.md,prompt.md}) drafted for the RECOMMENDED Arm 1 (forward-tense SPECCED, scope slug ewr-1-3). Mirrors ewr.1.1.* structure + ewr.design.md. All 51 relative md links resolve; the recommendation is advice, the fork is the Operator's to rule.

RECONCILE deltas found (lag-1 re-probe of the as-built floor):
- VERIFIED (load-bearing, MATCH): exec/1's server error is ALWAYS in-band {:error_reply, binary()} inside {:ok,[reply]}, NEVER {:error,{:server,_}}. pipe_reply(:plain,replies)={:ok,replies} (connector.ex:560); fill/5 pushes {:error_reply,msg} verbatim (connector.ex:573-575 → resp.ex:47). {:error,{:server,_}} is eval/5-EXCLUSIVE (connector.ex:76-77, :87) → unreachable via Pipe. Pool.pipeline/3 (pool.ex:48) pure pass-through. This is the floor the classifier rests on.
- STALE in UPSTREAM docs (NOT my files — corrected in my triad to as-built): the conformance count is {:ok, 53} (conformance_run_test.exs:46), NOT {:ok, 52}. ewr.1.1.md + ewr.program.md + ewr.roadmap.md still say 52/:45 — drifted since ewr.1.1 shipped. My ewr.1.3 triad pins 53/:46. Director should note the upstream docs owe a sync.

Pipeline note for the prompt: the fork is OPEN (4 arms) — unlike ewr.1.1 (pre-ruled). Stage 0 = Director rules it via AskUserQuestion before Stage 1 is reachable; if an arm other than 1 is ruled, Venus re-authors the triad first.

### P-2 — post-build reconcile DONE (Stage 4). Reconciled the 4 triad files SPECCED→BUILT, do-no-harm; the floor-doc sync + ledger Z-1 + the commit are the Director's.

Folded the as-built (Mars's design-make, Director-verified):
- classify/1's internal representation = a TAGGED TUPLE {:ok,replies} | {:transport_error,term} | {:server_error,oks,[{index,{:error_reply,msg}}]} with oks = the FULL reply list so indices stay valid (result.ex:104-111). The four accessors stay the frozen contract; the tuple is the representation, as specified. server_errors/1 = Enum.with_index|>flat_map, 0-based ascending (result.ex:87-94); non_valkey_error/1 = nil for {:ok,_} even carrying server errors (result.ex:122-123); error/1 transport-first (result.ex:134-141). {:error,{:server,_}} eval-exclusive, recorded-not-classified.
- HONEST INV6 (the key reconcile): transport-before-server ordering is STRUCTURAL — error/1's two clauses match disjoint inputs ({:error,_} vs {:ok,_}), so NO single exec return exercises both branches and there is NO order-mutation to kill (the delta from ewr.1.1's positional accumulator). The real net-zero proof is the PARTITION MISCLASSIFY mutation: blind server_errors/1 → the real WRONGTYPE :valkey story dies. Recorded honestly across all 4 files; the prior "order-theorem KILLED" framing is gone (survives only as explicit negations). The Director re-killed the misclassify mutation independently.
- CONFORMANCE reframed VALUE-FREE: removed every {:ok,53} pin. State "byte-stable — the wire registers no scenario, writes no registry.json; the count is emq-owned (drifted 52→53→54 — not the wire's to pin)"; 54 cited only as a descriptive floor where the gate needs one, never pinned.

Frame: SPECCED→BUILT in md/stories/llms/prompt; As-built reconcile block added to the body banner; DoD flipped 7/7 [x]. (design.md left as the fork record — not a SPECCED→BUILT artifact.) Verified: no residual {:ok,53}/53-scenario; order-theorem only as negations; 41/41 links resolve; no pipe.ex-edit claim. Edited ONLY the 4 triad files.

## {ewr-1-3-decisions} Decisions

### D-1 — RULED: Arm 1 (the pure EchoWire.Result classifier over exec's return). The Operator's ruling, 2026-06-18 — Venus's recommendation. EchoWire.Result ships the four rueidis-mirrored accessors over exec's return: classify/1 (the total transport-vs-server partition), non_valkey_error/1 (NonValkeyError — transport only), error/1 (Error — transport-or-server), server_errors/1 (the indexed per-reply lens). exec/1 is FROZEN and byte-unchanged (the classifier reads its return). The placement fork is CLOSED; Stage 1 is reachable.

CHOSEN-AGAINST:
- Arm 2 (new exec variants exec_split/1 + exec!/1 on Pipe): grows the Pipe surface, mixes classify into the construction module, exec! bakes a raise-on-server-error policy, harder to test in isolation, puts the vocabulary in the wrong module (the inverse of the ewr.1.1 "can't extract clean fns from a verb-first surface" lesson).
- Arm 3 (per-reply lens only, no transport-tier surface): an incomplete port — ships half the paired discriminator, leaves the transport tier folklore at every call site, under-serves the headline retry consumer (which needs transport-vs-server).
- Arm 4 (defer / fold into ewr.1.2): weak Steward — the split's shape is already fully determined by the as-built return, so there is nothing to defer away (unlike the design fork's genuinely-shapeless flag seam); leaves a ruled Movement-I rung unbuilt and every caller re-deriving the tiers by hand.

D-2 — the result-SHAPE sub-question DELEGATED to Mars's design-make (the Director's call, per the "contract-to-specify, shape-to-leave-to-Mars" rule, program/ewr.venus.md). The FROZEN CONTRACT specified by the triad is the four accessors + the partition behaviour (total + exhaustive over exec's return; the server tier is exactly the in-band {:error_reply,_}; transport precedes server; the three accessors agree) + their runnable checks asserted THROUGH the accessors. The INTERNAL REPRESENTATION of classify/1's return — a tagged tuple (e.g. {:ok,replies} | {:transport_error,term} | {:server_error,oks,server_errors}) vs a %EchoWire.Result{} struct — is the implementor's, never pinned as a literal (the ewr.1.1 precedent: the %Pipe{via} dispatch field was Mars's, the conn-or-pool contract was checked). The tuple in the triad is illustrative, not the contract.

Triad reframed for both rulings: status banners flipped to RULED across all four triad files + the design doc; D1(b) recast from "the Operator-ruled result shape" to "the delegated internal representation"; D2/INV4/US1/US-GATE/the offline-suite descriptions now bind the partition OUTCOME through the accessors (non_valkey_error/1 non-nil iff transport-error; server_errors/1 non-[] iff server-error), never a literal return shape. No code, no git.

### D-2 — EWR.1.3-D1 design-make CONFIRMED at build time (Mars-1, before any .ex/test artifact). Arm 1 (D-1) + the delegated result-shape (D-2) adopted, not re-litigated.

LAG-1 RE-PROBE of the VERIFIED SERVER-ERROR SHAPE (the classifier rests on it — confirmed at build time):
- exec/1 (pipe.ex:500-505) → via.pipeline(conn, Enum.reverse(cmds), timeout). pipeline/3 (connector.ex:54-58) → GenServer.call({:pipeline,cmds}) → pipe_reply(:plain, replies) = {:ok, replies} (connector.ex:560). fill/5 (connector.ex:564-584) pushes RESP.parse's value verbatim incl. {:error_reply, msg} (connector.ex:573). resp.ex:47 = parse(<<?-,rest>>) → {:error_reply, &1}. So a SERVER error on the Pipe path is ALWAYS the in-band value {:error_reply, binary()} inside {:ok, [reply]} — NEVER {:error, {:server, _}}. CONFIRMED.
- {:error, {:server, _}} is eval/5-EXCLUSIVE: connector.ex:76-77 ({:ok,{:error_reply,msg}} -> {:error,{:server,msg}}) + map_script_reply/1 @:87-88, reached only from the EVALSHA path @:63-82. EchoWire.Pipe never flushes through eval → unreachable via the Pipe surface. NOT classified; named OUT (INV5).
- Pool.pipeline/3 (pool.ex:48) = Connector.pipeline(next(name),...) — pure pass-through, no re-map. Identical shape vs connector or pool. CONFIRMED.
- transport tier (exec's {:error,term}): :disconnected / :overloaded / {:version_fence,got} / :empty_pipeline (pipe.ex:501) + any other {:error,term}.

DESIGN-MAKE (D-2 delegated, ruled):
(D1b classify/1 internal representation) a TAGGED TUPLE tri-state: {:ok, replies} | {:transport_error, term} | {:server_error, oks, server_errors} where server_errors = [{index, {:error_reply, msg}}] ascending. Chosen over a %EchoWire.Result{} struct: smaller frozen surface, an idiomatic case-branch target, mirrors the illustrative shape the triad/D-2 names — and the CONTRACT binds through the four accessors, not this tuple (checked via non_valkey_error/1 / server_errors/1 on the classified value, never a literal). The accessors + partition (D2-D5) are the frozen contract.
(D1c oks content) the FULL reply list (errors NOT elided) — server_errors carries the indexed errors, and keeping oks complete lets a caller read the positional successes alongside without re-zipping; the index in server_errors stays valid against the full list.
(accessor order INV6) error/1 checks the transport branch FIRST (a transport {:error,term} means there is no reply list), else the first/lowest-index {:error_reply,_}, else nil. non_valkey_error/1 = transport only ({:error,term} → that, success → nil incl. a server-error-carrying success). server_errors/1 = the per-reply lens over a bare reply list.
(purity D6/INV3) no Connector/Pool/socket/process/GenServer/pipeline call; pure transform; exec/1 NOT edited (pipe.ex byte-unchanged). server_errors/1 authored first, classify/1 reuses it.
(placement) lib/echo_wire/result.ex + test/echo_wire/result_test.exs; echo_mq/test/stories/wire_pipe_error_*_story_test.exs → docs/echo_mq/wire/stories/ via --match wire_pipe (NO Mix-task edit — --match already shipped ewr.1.1).

DEVIATION FLAGGED (same as ewr-1-2 D-1): the triad pins conformance {:ok, 53}; the AS-BUILT floor is {:ok, 54} (conformance_run_test.exs:47). emq drifted 53→54 out-of-band (emq.4.1 reassign + lane_drain). The wire registers none; I gate on {:ok, 54} byte-stable and surface the stale-number to the Director.

## {ewr-1-3-report} Report

### Y-1 — EWR.1.3 BUILT (Mars-1). The two-tier error classifier (Arm 1), all gates green.

DESIGN-MAKE REALIZED (ledgered before any artifact; D-1/D-2 adopted):
- classify/1 internal representation = a TAGGED TUPLE tri-state: {:ok, replies} | {:transport_error, term} | {:server_error, oks, [{index, {:error_reply, msg}}]} ascending. Chosen over %EchoWire.Result{}: smaller frozen surface, idiomatic case-branch target, mirrors the illustrative D-2 shape. The CONTRACT binds through the four accessors, not this tuple.
- oks = the FULL reply list (errors NOT elided) — server_errors carries the indexed errors; keeping oks complete keeps the indices valid against it + lets a caller read positional successes.
- server_errors/1 authored first (the building block); classify/1 reuses it; non_valkey_error/1 (transport only — nil for a server-error-carrying success); error/1 (transport-FIRST, then first {:error_reply,_}, else nil).

VERIFIED SERVER-ERROR SHAPE (the floor the classifier rests on, re-probed at build): exec's server error is ALWAYS in-band {:error_reply, binary()} inside {:ok,[reply]} (pipe_reply(:plain) = {:ok,replies} connector.ex:560; fill/5 pushes verbatim :573 → resp.ex:47), NEVER {:error,{:server,_}} (eval/5-exclusive connector.ex:76-77, unreachable via Pipe). Pool.pipeline/3 pure pass-through.

FILES:
- NEW echo/apps/echo_wire/lib/echo_wire/result.ex — the pure classifier: classify/1 + non_valkey_error/1 + error/1 + server_errors/1, no I/O.
- NEW test/echo_wire/result_test.exs (23 tests: the partition through the accessors, the index lens, transport-first ordering, cross-consistency INV6, purity grep INV3, no-{:server,_} INV5).
- NEW echo/apps/echo_mq/test/stories/wire_pipe_error_split_story_test.exs (4 :valkey scenarios: a REAL WRONGTYPE split, a clean flush, a partial-batch lens, an empty-pipe transport tier) → GEN docs/echo_mq/wire/stories/wire-result-error-split.stories.md.
- pipe.ex is NOT edited by this rung's classifier (exec/1 frozen); the only pipe.ex change in the tree is ewr.1.2's command/2 head.

GATE NUMBERS:
- echo_wire: compile --warnings-as-errors CLEAN; mix test 109/0 (includes the 23 result tests). Facade still 11.
- echo_mq: mix test --include valkey 380 + 4 doctests, 0 failures; CONFORMANCE 54/54 byte-stable.
- regen: --match wire_pipe idempotent (diff -r clean ×2), bus dir byte-unchanged, default emits all 13 features.
- multi-seed: echo_wire 5/5; echo_mq error stories 5/5. NO ≥100 loop — no id-mint/process/lease; the classifier is synchronous pure fns, the :valkey round-trips deterministic request/reply.

ADVERSARIAL BATTERY (Lua items N/A — no Lua):
- REAL WRONGTYPE provoked live: SET k "a-string" then LPUSH k "x" → Valkey returns {:error_reply,"WRONGTYPE ..."} at index 1; classify → {:server_error, ["OK", {:error_reply,"WRONGTYPE"..}], [{1, {:error_reply,"WRONGTYPE"..}}]}; non_valkey_error → nil. NOT hand-built (INV7).
- (3) PARTITION MUTATION (INV4): classify's :server_error branch flipped to return {:transport_error, err} → 4 KILLS (partition, server-error, exhaustiveness, cross-consistency). Reverted net-zero.
- ORDER-THEOREM note (INV6, L-4): the "transport-before-server" ordering is STRUCTURALLY enforced by disjoint tuple shapes — a transport {:error,term} and a server-carrying {:ok,replies} are non-overlapping inputs, so no single input exercises both error/1 branches (unlike ewr.1.1's positional accumulator where reversal genuinely corrupts). The cross-consistency test (the three accessors agree on every shape) is the real INV6 proof; a mutation that misclassifies (MUTATION-3) IS killed. Reported honestly rather than forced.
- FROZEN-FLOOR: result.ex purity grep (Connector|Pool|gen_tcp|GenServer.|.pipeline() ) = 0 (asserted in-suite); pipe.ex/exec untouched by 1.3; grep redis.call = 0; facade 11; conformance 54; mix.lock unchanged.
- module mutation kill-rate (shared 1.2+1.3): 3/3.

DEVIATIONS (flagged):
- CONFORMANCE {:ok,53}→{:ok,54} as-built (emq.4.1 drift) — same as ewr-1-2 D-1. Gate on 54; triad owes a sync (P-1 already noted the upstream docs owe it).
INCOMPLETE: none.

## {ewr-1-3-learnings} Learnings

> Consolidated by the Director for Apollo (the Mentor, out of pipeline — PROPOSE-ONLY).

### L-1 — [Venus] cite a sibling program's MUTABLE count VALUE-FREE

Same lesson as `ewr-1-2` L-1: the conformance count drifted `52→53→54` in one session (emq out-of-band), so
the wire spec must cite it as the INVARIANT ("byte-stable; the wire registers no scenario; the count is
emq-owned"), never a pinned number. A sibling program's mutable surface is not the wire's to pin.

### L-2 — [convention] the order-theorem (L-4) proves a POSITIONAL invariant — do not forge it for a disjoint partition

`ewr.1.1`'s L-4 made the order-theorem mutation (reverse/drop the accumulator → a test dies) the standing proof
for a "replies map 1:1 in order" invariant. `ewr.1.3` showed its **boundary**: `classify`'s outcomes are
**disjoint tuple shapes** — a transport `{:error, term}` and a server-carrying `{:ok, replies}` are
non-overlapping inputs, so no single input exercises both `error/1` branches and there is **no order to
corrupt**. Mars reported this honestly and proved INV6 the real way (the cross-consistency test that the three
accessors agree on every shape, plus the partition-misclassify mutation, which IS killed) rather than forge a
non-killing "order mutation" to look rigorous. GUARDRAIL: apply the order-theorem **only** to positional
invariants; for a disjoint-shape partition the misclassify mutation is the proof — and the *absence* of a
mutation is a finding to state, never a gap to paper over with a fake one.

## {ewr-1-3-complete} Complete

### Z-1 — ewr.1.3 (EchoWire.Result) SHIPPED — the two-tier error classifier, build-grade.

WHAT SHIPPED: **`EchoWire.Result`** — the rueidis `NonValkeyError()`/`Error()` model as a **pure** reader over
`EchoWire.Pipe.exec/1`'s return: `classify/1` (the total transport-vs-server partition) + `non_valkey_error/1`
(transport tier) + `error/1` (transport-or-server, transport precedes) + `server_errors/1` (the per-reply lens).
The **four accessors are the frozen contract**; `classify/1`'s tagged-tuple representation is the implementor's
design-make (the Operator delegated the shape). Server tier = the in-band `{:error_reply, _}`; transport tier =
`exec`'s `{:error, term}` — a total partition, no invented term. `exec/1` is UNCHANGED (purely additive).

VERIFICATION (Director-independent, valkey 6390): echo_wire **109/0** (the 23 `result` tests); the error-split
`:valkey` story — a **real `WRONGTYPE`** provocation — green; conformance **byte-stable** (emq-owned, value-free
per L-1); the partition (INV4) mutation **re-killed independently** by the Director (`server_errors` blinded →
the WRONGTYPE story died, reverted net-zero); frozen-floor clean (`result.ex` purity grep = 0; `pipe.ex`/`exec`
untouched by 1.3; `redis.call`=0; facade 11).

RULINGS (Operator, via the mandatory `AskUserQuestion` gate): **Arm 1** (`EchoWire.Result` classifier); the
result-SHAPE delegated to Mars's design-make (the accessors are the contract). Recorded `D-1`/`D-2`; arms 2/3/4
keep their case.

LAW-4: scoped to the rung — NEW `result.ex` + `result_test.exs` + `wire_pipe_error_split_story_test.exs` + the
generated `wire-result-error-split.stories.md`. NO `pipe.ex` edit (`exec` frozen). The Operator commits
out-of-band, scoped by concern.
