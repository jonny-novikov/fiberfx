# emq-5-2 — AAW scope ledger

## {emq-5-2-thinking} Thinking

### T-1 — emq.5.2 derivation (the §0): min_size/timeout batch shaping

WHAT. A batch-aware EchoMQ.Consumer mode that flushes a batch when pending depth ≥ min_size OR a timeout elapses, draining via the SHIPPED @bclaim/claim_batch/4 (jobs.ex:520) over the flat emq:{q}:pending set; a PURE accumulate/flush shaping core (injected clock); batch lifecycle events on the EchoMQ.Events.publish/5 seam (events.ex:117, host-side — byte-frozen transition scripts untouched). The spine (5.1) is a manual single-shot pull; 5.2 gives it a self-pacing cadence with a SIZE FLOOR (min_size) + a LATENCY CEILING (timeout).

WHY. Amortize the wake→handle cycle for batch workloads. A consumer that wants ≥N jobs per handler invocation should not hand-roll a timer + a depth poll + the partial-failure settle loop; 5.2 packages that cadence over the proven spine.

WHO/WHERE. EchoMQ.Consumer (a new additive mode beside the standalone + metronome paths) · a pure shaping core (a new module or private core) · EchoMQ.Events (additive batch events) · EchoMQ.Conformance (+ scenarios, additive-minor over 64) · a new :valkey test + a story. BOUNDARY = echo/apps/echo_mq ONLY (no echo_wire/echo_data/sibling-app edit).

WHEN. Now — emq.5.1 shipped (@bclaim jobs.ex:200-219, claim_batch/4 jobs.ex:520-539 LIVE, conformance 64, label 2.5.0).

SOLUTION SPACE (incl. do-nothing).
- Do-nothing baseline: callers loop claim_batch/4 themselves with their own timer + depth poll (the 5.1 manual-pull). 5.2 earns its place ONLY by removing that hand-rolled cadence + the size-floor/latency-ceiling bookkeeping into one supervised, tested core.
- FORK 5.2-A (the home): a MODE on EchoMQ.Consumer (additive — reuses child_spec/stop/handler/connector lifecycle) vs a new EchoMQ.BatchConsumer (clean separation, duplicates the lifecycle). Lean: a mode on the shipped Consumer.
- A possible FORK 5.2-B (the accumulation model): WATCH-DEPTH (read ZCARD pending; claim ONLY at flush — no lease ticks during accumulation) vs ACCUMULATE-CLAIMED (claim as jobs arrive, hold leased members until min_size/timeout — precise sizes but leases tick during the wait). Lean: watch-depth — matches the carve's "waits for ≥ min_size OR timeout THEN drains via @bclaim", and dodges the lease-tick hazard. Venus to frame iff it rises to an Operator decision.
- A possible minor (the events shape): per-member publish (reuse publish/5 as-is, N events) vs a batch-level event (a count, not a single gated job_id). Venus to frame.

INVARIANTS AS RUNNABLE CHECKS.
- INV-NoLua: grep redis.call on the lib diff = 0 — @bclaim + every shipped script byte-frozen (5.2 adds NO Lua).
- INV-Boundary: diff ⊆ echo/apps/echo_mq; @wire_version frozen echomq:2.4.2; no sibling app / mix.lock.
- INV-PureCore: the flush/wait decision is a PURE fn of (depth, elapsed, min_size, timeout, size) with an INJECTED clock — no Process.send_after/monotonic_time inside the core; the proof drives it deterministically.
- INV-Floor+Ceiling: a flush carries ≥ min_size UNLESS the timeout fired (then whatever's available, ≥0); never blocks past timeout.
- INV-ClaimPath: the mode drains via claim_batch/4 over flat pending (NOT Lanes.claim — that grouped path is 5.3); pause honored (claim_batch → :empty on pause).
- INV-Conf: prior 64 byte-unchanged + git-verified; new scenarios probe-registered; re-pin BOTH pins.
- INV-Events: batch events ride Events.publish/5 (host-side); id gated at the key builder (INV5).

SMALLEST CHANGE. A :batch option-set on Consumer (min_size, timeout, size) → a third loop path that calls a pure shaping core deciding flush/wait from a depth read + an injected clock, drains via claim_batch/4, settles each member via the shipped per-member complete/retry (the 5.1 partial-failure isolation), emits batch events via Events.publish/5. No new Lua, no new lease, no new key.

RISK = NORMAL. No new Lua/lease/process-type, no destructive at-rest op, no frozen-line edit, no wire break. Determinism = MULTI-SEED SWEEP + an honest posture (the core is pure + clock-injected → deterministic; a modest repeat loop shakes process-timing flakes) — NOT the ≥100 mint-hazard loop (5.2 mints/leases nothing new; the carve §3 rules this). RIGHT-SIZE-COLLAPSE candidate: Director may collapse Mars-2 if Stage-2 verify is clean. Mode = Flat-L2.

### T-2 — Mars build derivation (anchors re-probed, D-1/D-2/D-3 binding)

ALL anchors confirmed on disk (lag-1 re-probe):
- claim_batch/4 jobs.ex:520 → {:ok,[{id,payload,att},…]}|:empty; guard size>0; checks paused?/2 FIRST (jobs.ex:522) → INV-ClaimPath pause-honored is STRUCTURAL.
- pending_size/2 jobs.ex:864 = ZCARD emq:{q}:pending (watch primitive, no lease tick).
- complete/5 jobs.ex:589 = complete(conn,q,id,token,result\\nil); batch scenarios call the 4-arg form complete(conn,q,id,att).
- retry/7 jobs.ex:759 = retry(conn,q,id,token,delay_ms,max_attempts,error).
- Events.publish/5 events.ex:117 = publish(conn,q,event,job_id,extra\\[]); gates ONE job_id at key builder (INV5).
- @bclaim jobs.ex:200-219 BYTE-FROZEN (no Lua edit this rung).
- Pump.Core pump/core.ex = pure-core precedent (tick_ms/batch raise on non-positive; doctested).
- Consumer consumer.ex = lifecycle precedent (child_spec:28/start_link:52/stop:101/check_control:127/drain:137 try-rescue-catch). DO NOT EDIT.
- conformance 64 LIVE (run_test:50; scenarios_test:97 @run_order 64 names); batch scenarios at conformance.ex:2079/2133/2174 = the templates I generalize; helpers complete_all:2436/good_rows_retired?:2447/purge:2453.
- mix.exs:7 label 2.5.0; @wire_version echomq:2.4.2 connector.ex:35 FROZEN.

BUILD PLAN (4 deliverables, all in echo/apps/echo_mq):
(a) BatchShaper.Core (NEW pure module) — validate(min_size,timeout) raises on non-positive (Pump.Core discipline); decide(depth,elapsed_ms,min_size,timeout) → {:flush,size}|:wait. D1 floor: depth>=min_size → {:flush, depth} (request the full observed depth — claim_batch clamps to depth anyway, and a flood ≥min_size should drain all ready, not artificially cap at min_size; INV-Floor+Ceiling says size≥min_size on the floor leg, satisfied). D2 ceiling: elapsed>=timeout → depth==0 → :wait (empty case, re-open) else {:flush, depth} (partial). Doctested.
(b) BatchConsumer (NEW process) — consumer.ex lifecycle duplicated minimally + INJECTED clock seam (:now_fn default System.monotonic_time/1 ms). batch_loop: open window (mark t0) → check_control → poll pending_size/2 → Core.decide(depth, elapsed) → :wait → sleep poll_ms, loop window (NO claim) → {:flush,size} → claim_batch/4 ONCE → handler.(members) → verdict map → per-member complete/5 (att) | retry/7 | absent→retry "missing verdict" (D-2 fail-safe) → per-member Events.publish/5 (D3, on member's own id, "completed"/"failed") → re-open window. Handler raise → whole-batch retry (drain/1 rescue/catch generalized). pause: claim_batch→:empty → no batch, re-open.
(c) per-member events — inside BatchConsumer settle (D3).
(d) 3 conformance scenarios (batch_shaping_floor/timeout/partial_failure) + re-pin 64→67 both pins. These drive the host fns + Core directly (NOT a spun process — the harness is wire-level; a supervised process per scenario adds nondeterminism). floor: flood ≥min_size, Core.decide→{:flush,N}, claim_batch, settle. timeout: trickle M<min_size, Core.decide at elapsed<timeout→:wait, at elapsed>=timeout→{:flush,M} (injected elapsed, no real sleep); empty window depth==0→:wait. partial_failure: generalize batch_partial_failure through the verdict-map mapping (one member {:error}, rest :ok, absent→retry).

DETERMINISM POSTURE (NORMAL): multi-seed sweep + honest statement (Core pure+clock-injected → deterministic; no id-mint/lease in 5.2's own code — @bclaim does leasing, byte-frozen, proven by 5.1's ≥100). PLUS ≈25× repeat of the :valkey suite (process-timing due diligence). NOT the ≥100 mint-hazard loop (carve §3 rules this out — running it forges load 5.2 did not introduce).

## {emq-5-2-learnings} Learnings

### L-1 — anchor correction (the lag-1 re-probe): the watch-depth primitive is `EchoMQ.Jobs.pending_size/2` (jobs.ex:863-866) = `Connector.command(conn, ["ZCARD", Keyspace.queue_key(queue, "pending")])` — a PURE READ, no lease tick. The Director's seed guessed "likely Jobs.depth/2 or similar"; the real fn name is `pending_size/2`. This is the flush-decision's depth read (no claim during accumulation → no lease ticks). Also confirmed: claim_batch/4 (jobs.ex:520-539) + @bclaim (jobs.ex:200-219) shipped exactly as described (BYTE-FROZEN by 5.2 — no new Lua); Jobs.complete/5 = complete(conn,queue,job_id,token,result\\nil) (jobs.ex:589), Jobs.retry/7 = retry(conn,queue,job_id,token,delay_ms,max_attempts,error) (jobs.ex:759) — the per-member settle fns (BYTE-FROZEN); Events.publish/5 = publish(conn,queue,event,job_id,extra\\[]) (events.ex:117) gates ONE job_id at the key builder; conformance 64 LIVE (conformance_run_test.exs:50); mix.exs:7 label 2.5.0; @wire_version echomq:2.4.2 frozen (connector.ex:35). Pump.Core (pump/core.ex) = the pure-core PRECEDENT for the shaping core: tick_ms/1 + batch/1, pure fns of opts, doctests, no clock/process/IO.

### L-2 — pre-existing link defect in the SHIPPED emq.5.1 triad (flag to Director, NOT in 5.2 scope): emq.5.1.md (lines 32, 315 design.md; 318 roadmap.md; 319 approach.md) + emq.5.1.llms.md (line 43 design.md) use a 3-up relative path (`../../../emq.design.md`) to the canon — DEAD. The CORRECT depth from `specs/emq2/emq.5/emq.5.rungs/` to `docs/echo_mq/` is 4-up (`../../../../emq.design.md` for design/roadmap; 5-up `../../../../../elixir/...` for approach) — confirmed by filesystem test (the emq.5.1 form resolves to a nonexistent `docs/echo_mq/specs/emq2/emq.design.md`). This is the documented specs-reorg link-rebase trap (memory: reorg-link-rebase-verification) — the link-checker was not gating emq.5.1's ship. My emq.5.2 quad authored CLEAN (corrected to 4-up/5-up; `msh specs` over docs/echo_mq shows ZERO findings in any emq.5.2.* file). Recommend the Director route an emq.5.1 link-fix as a separate hygiene pass (5 edits, body-authoritative — out of band from the emq.5.2 build to keep the commit unentangled).

### L-3 — the conformance-mirror drift-seam (an accepted pattern, for Apollo's calibration)

emq.5.2's conformance scenarios settle through a conformance-local `settle_batch/4` that MIRRORS the lib's `BatchConsumer.settle/3` (the verdict-map mapping + the fail-safe default) rather than driving the live process — Mars's rationale: a supervised process per scenario would inject process-timing nondeterminism into the wire-level conformance gate. This is the RIGHT call for the conformance harness, but it creates a duplication/drift hazard: a future bug in the real settle/3 could pass the conformance mirror green. The hazard is MITIGATED two ways and is therefore accepted, NOT a finding: (1) the mirror carries an explicit cross-reference comment ("exactly as EchoMQ.BatchConsumer.settle/3 does"); (2) the REAL process is independently tested for the absent-member fail-safe in batch_consumer_test.exs:187-247. The craft lesson for the family (5.3 @gbclaim / 5.4 partitioned finish will mirror this): when a conformance scenario must replicate lib logic for determinism, PIN the duplication with a cross-ref comment AND ensure the live-process suite independently covers the same invariant — never let the deterministic mirror be the sole witness of a settle contract. A future refactor candidate: lift settle/3 to a thin pure mapper the conformance can call directly (no process, no copy) — defer unless 5.3/5.4 force it.

## {emq-5-2-progress} Progress

### P-1 — emq.5.2 triad authored + reconciled BUILD-GRADE (Stage 0/1 DONE). Quad authored: emq.5.2.{md (body authoritative),stories.md,llms.md,prompt.md} under specs/emq2/emq.5/emq.5.rungs/. Reconcile delta (every claim re-probed, lag-1): all MATCH — claim_batch/4 (jobs.ex:520-539), @bclaim (jobs.ex:200-219), pending_size/2 (jobs.ex:863-866, the watch-depth primitive — CORRECTED from Director's "Jobs.depth/2 guess"), complete/5 (jobs.ex:589), retry/7 (jobs.ex:759), paused?/2 (jobs.ex:482), Events.publish/5 (events.ex:117, gates ONE job_id), Pump.Core (pump/core.ex:24-47, the pure-core precedent), Consumer (consumer.ex: child_spec:28 / start_link:52 / stop:101 / check_control:127 / loop:114 / metronome_loop:185 / :metronome dispatch:82-85 — BOTH modes claim via Lanes.claim/3→{id,payload,att,group}, the grouped ring), enqueue_many/3 (jobs.ex:124), conformance 64 (conformance_run_test.exs:50), mix.exs:7 label 2.5.0, @wire_version echomq:2.4.2 (connector.ex:35). NO STALE/INVENTED/MISSING. Forks framed OPEN: 5.2-A (the home — Consumer mode vs BatchConsumer; lean Consumer mode/Arm A), 5.2-B (the batch handler contract — single verdict vs per-member map vs failed-ids vs per-job-claim-only; lean per-member map/Arm B, the load-bearing one) + count granularity [WITHHELD] (lean +3→67). 3 design calls settled with rationale (D1 watch-depth, D2 ceiling-wins, D3 per-member events). Risk NORMAL (no Lua/lease/wire/destructive — a host-process rung; multi-seed sweep, NOT the ≥100 loop; right-size-collapse candidate). Links: emq.5.2 quad CLEAN (msh specs 0 findings); flagged L-2 pre-existing emq.5.1 dead-link defect (5 links, separate hygiene pass).

### P-2 — Mars-1 released to build emq.5.2 (Stage-3)

Harness team `emq-5-2` re-created after the MCP restart cleared the in-memory team (the aaw registry + ledger survived on disk — Director/Venus rows + T-1 + D-1/D-2/D-3 all intact; the V-SOLO-1 signal is the expected sole-active-row advisory since Venus's reconcile finished).
Mars-1 (`Mars@emq-5-2`, opus, run_in_background) building to the BINDING rulings:
- D-1: NEW module `EchoMQ.BatchConsumer` (not a Consumer mode); `EchoMQ.BatchShaper.Core` pure isomorph of `Pump.Core`.
- D-2: per-member verdict map `%{id => :ok | {:error, reason}}`; absent id → fail-safe retry "missing verdict".
- D-3: conformance 64→67 (`batch_shaping_floor`/`batch_shaping_timeout`/`batch_shaping_partial_failure`); prior 64 byte-unchanged; both pins re-pinned.
Laws bound into the brief: INV-NoLua (`grep -c redis.call` on lib diff = 0), boundary = echo_mq only (consumer.ex untouched), watch-depth not accumulate-claimed, injected clock, NORMAL determinism posture (multi-seed sweep + ≈25× repeat loop, NOT the ≥100 loop), no git. Awaiting Mars-1's BUILD-GRADE/BLOCKED report → Director verify next.

### P-3 — emq.5.2 BUILD-GRADE (Mars build, all 8 INVs green, gates green)

DELIVERABLES (all ⊆ echo/apps/echo_mq):
- NEW lib/echo_mq/batch_shaper/core.ex (~110L) — the pure flush-decision core (Pump.Core isomorph). validate!/2 (raises non-positive, ArgumentError); decide/4 (depth,elapsed,min_size,timeout) → {:flush,depth}|:wait. D1 floor: depth>=min_size → {:flush, depth} (request full observed depth, ≥min_size — drain all-ready). D2 ceiling: elapsed>=timeout & depth>0 → {:flush,depth} (partial); depth==0 → :wait (empty case). NO process/clock/IO. 5 doctests.
- NEW lib/echo_mq/batch_consumer.ex (~250L) — the watch-depth process (D-1: NEW module, NOT a Consumer mode; consumer.ex UNTOUCHED). child_spec/start_link(spawn_link+trap_exit)/stop/2 minimally duplicated. INJECTED clock :now_fn (default System.monotonic_time(:millisecond)). loop→window(t0): check_control → pending_size/2 (ZCARD, NO claim) → Core.decide → :wait → poll_wait(receive..after poll_ms, control-honored) → re-window; {:flush,size} → claim_batch/4 ONCE → invoke handler over [%{id,payload,attempts}] → per-member verdict map (D-2) → settle: :ok→complete/5+publish "completed"; {:error,r}→retry/7+publish "failed"; ABSENT→retry "missing verdict" (D-2 fail-safe). Handler raise→whole-batch retry (drain/1 rescue/catch generalized). Per-member Events.publish/5 (D-3).
- EDIT lib/echo_mq/conformance.ex — +3 scenarios (batch_shaping_floor/timeout/partial_failure) probe-registered; prior 64 BYTE-UNCHANGED (the only - line is batch_partial_failure gaining a trailing comma — contract text byte-identical). +alias ShaperCore. +settle_batch/4 helper (mirrors BatchConsumer.settle). Scenarios drive host fns + Core directly (wire-level harness — no spun process per scenario). partial_failure OMITS a member to prove the fail-safe observable.
- NEW test/batch_shaper_core_test.exs (doctest + validate!/decide guards + floor/ceiling/empty/determinism).
- NEW test/batch_consumer_test.exs (:valkey — floor flush, ceiling flush via INJECTED :counters clock, empty-window no-flush, partial-failure isolation through the live process + per-member events via Events.subscribe, stop/2, non-positive-knob raise).
- EDIT test/conformance_run_test.exs ({:ok,64}→{:ok,67} + title + moduledoc).
- EDIT test/conformance_scenarios_test.exs (@run_order +3 names + title + moduledoc).

GATE LADDER (per-app, TMPDIR=/tmp, from echo/apps/echo_mq):
- asdf: elixir 1.18.4 / erlang 28.5.0.1 (re-probed from app dir). valkey-cli -p 6390 ping → PONG.
- compile --warnings-as-errors --force → exit 0, echo_mq clean (echo_data ChampView warnings pre-existing cross-app, not my code).
- mix test --include valkey → CONFORMANCE 67/67; 9 doctests, 441 tests, 0 failures.
- Conformance.run → {:ok, 67} (all 3 new scenarios CONF ok).
- BatchShaper.Core doctests pass (in the 9).

INV-BY-INV (all 8 green):
- INV-NoLua ✅ — 0 redis.call added (lib + test diff); @bclaim + every shipped script byte-frozen.
- INV-Boundary ✅ — diff ⊆ echo/apps/echo_mq; 0 changes to {echo_wire,echo_data,echo_mq/mix.exs,mix.lock}; @wire_version echomq:2.4.2 frozen (live {emq}:version reads it); mix.exs label 2.5.0 unchanged; no new key family (new code rides Jobs/Events host fns, no Keyspace builder).
- INV-PureCore ✅ — Core has NO Connector/Jobs/Process/:timer/monotonic_time ref; deterministic given args (50× same-args doctest-asserted); non-positive knob raises.
- INV-Floor+Ceiling ✅ — floor leg requests full depth (≥min_size); ceiling partial (1..min_size-1); empty window flushes nothing; never waits past timeout.
- INV-ClaimPath ✅ — flush calls claim_batch/4 over flat pending (NOT Lanes.claim); pause honored (claim_batch consults paused?/2 first — structural).
- INV-PartialFailure ✅ — per-member complete/5 / retry/7; one poison retries alone, rest complete; absent→retry; proof FAILS a real member (non-vacuous).
- INV-Conf ✅ — prior 64 byte-unchanged (git-verified); +3 probe-registered same change; both pins 64→67.
- INV-Events ✅ — per-member Events.publish/5 (completed/failed) on each member's own gated id; no new transport.

DETERMINISM POSTURE (NORMAL, honest): multi-seed sweep (8 seeds: 0/1/7/42/99/1000/31337/65535 — ALL GREEN on pure-core + conformance registry) + 25× repeat of the new BatchConsumer :valkey suite + conformance run (25/25 GREEN — process-timing shakeout). NOT the ≥100 mint-hazard loop: 5.2 mints NO branded id in its own code + creates NO new lease (the timer is isolated behind the injected clock; @bclaim does the leasing, byte-frozen, proven by 5.1's ≥100). Running ≥100 here would forge load 5.2 did not introduce (carve §3).

BRIEF GAPS / L-n: none. All anchors matched on re-probe. The team-lead's "claim_batch/4 jobs.ex:520-539" / "complete/5 jobs.ex:589" / "retry/7 jobs.ex:759" / "pending_size/2 jobs.ex:863-866" / "Events.publish/5 events.ex:117" all confirmed exact. Note: the [error] GenServer ...killed log lines in the :valkey run are the pre-existing connector-lane-dies-with-owner pattern (consumer_test.exs documents it) — log noise, 0 test failures. STATE: BUILD-GRADE.

## {emq-5-2-decisions} Decisions

### D-1 — FORK 5.2-A RULED: a NEW EchoMQ.BatchConsumer (reverses the Venus/draft lean of a Consumer mode)

The home of the min_size/timeout batch cadence is a NEW module `echo/apps/echo_mq/lib/echo_mq/batch_consumer.ex`, NOT a third mode on EchoMQ.Consumer. Operator-delegated to the Director with a 5W decision matrix + recommendation; the Director ruled Arm B.

WHY (the 5W matrix's deciding factor): emq.5.2 is the FIRST of three batch-family rungs (5.2 flat-batch via @bclaim · 5.3 grouped via @gbclaim · 5.4 the partitioned finish). The choice is really WHERE the whole batches family lives. The clean responsibility boundary is Consumer = the single-job RING consumer (standalone + metronome are the SAME Lanes.claim/3 + single-job-handler shape, just pool-coordinated) vs BatchConsumer = the BATCH consumer (watch-depth → flush → batch handler → per-member settle — a DIFFERENT claim path AND a different handler contract). A mode would accrete 4 cadences + 2 handler contracts into the 257-line consumer.ex and put EVERY batch-family edit on the shipped single-job modes' file (a recurring regression surface). A new module gives the family a home 5.3/5.4 extend and keeps the two SHIPPED Consumer modes off the per-rung regression surface (zero blast radius on standalone/metronome).

REVERSAL recorded honestly: Venus's per-rung lean was Arm A (mode) on carve-wording + lifecycle-reuse + the :metronome precedent — all true in isolation, but that framing under-weighted the 5.3/5.4 family coupling the Operator's matrix request surfaced. The :metronome precedent is weaker than it looks (metronome is still a single-job ring consumer; batch is not).

COST accepted: ~40 lines of stable OTP lifecycle boilerplate duplicated (child_spec / the :conn-:connector lane / stop/2 / check_control) — cheaper than coupling three divergent cadences; a later rung MAY extract a shared lifecycle helper (YAGNI-deferred). The carve's "a Consumer mode" wording is synced at Stage-5 (carve §4 framed 5.2-A as an OPEN fork, sanctioning the divergence). RISK unchanged: NORMAL (a new pure module + a new process module; no Lua, no lease, no wire edit — @bclaim does the leasing, byte-frozen).

### D-2 — FORK 5.2-B RULED: the per-member verdict map (the load-bearing fork)

The batch handler is invoked ONCE over the served members `[%{id:, payload:, attempts:}]` and answers a PER-MEMBER verdict map `%{id => :ok | {:error, reason}}`; the consumer completes the `:ok` members via the byte-frozen Jobs.complete/5 and retries the `{:error, reason}` members via the byte-frozen Jobs.retry/7 (each member's `reason` → that member's last_error). This makes emq.5.1's partial-failure isolation (INV7) OBSERVABLE and USABLE through the shaping cadence — one poison member retries alone, the rest complete.

Chosen over: Arm A (single batch verdict — forfeits isolation, one bad member redoes the whole batch); Arm C (failed-ids list — loses the per-member reason for last_error); Arm D (per-job handler, claim-only — forfeits the handler-WORK amortization the min_size floor's latency is paid for; the floor's whole rationale presumes the handler SEES the batch).

SUB-DECISION (the body fixes; the Director's lean, FAIL-SAFE): a served member ABSENT from the returned map is a contract violation treated as a RETRY (`{:error, "missing verdict"}`), NEVER a silent complete — unprocessed work must not retire. This per-member-verdict-map shape is the batch-family handler-contract PRECEDENT emq.5.3's grouped @gbclaim handler will mirror (a family-wide decision, not a 5.2-local one).

### D-3 — the conformance count RULED: +3 → 67 (granular, the emq.5.1 FORK-5.1-B precedent)

+3 → 67, the granular decomposition the Operator chose at emq.5.1 (granular over folded): `batch_shaping_floor` (the size-floor flush — a flood ≥ min_size flushes one batch of ≥ min_size via claim_batch/4) · `batch_shaping_timeout` (the latency-ceiling flush — a trickle < min_size held until timeout flushes the partial against the injected clock; the soft floor; the empty case) · `batch_shaping_partial_failure` (the isolation through the cadence — one member fails, retries with its last_error; the rest complete; a fresh post-promote claim finds only the poison). Additive-minor: prior 64 byte-unchanged + git-verified, each new scenario probe-registered in the SAME change, re-pin 64→67 in BOTH pinning tests (conformance_run_test.exs `{:ok, 67}` + conformance_scenarios_test.exs `@run_order`). The pure-core flush decision is ALSO covered by an EchoMQ.BatchShaper.Core doctest/unit (a structural property, not a conformance scenario).

### D-4 — Mars-2 COLLAPSED (right-size); next = Venus-2 Stage-5 triad sync before the ship

The Director verify (Y-1) found ZERO defects and zero hardening gaps: the build is spec-faithful, both flagged realization deviations (size=depth; the conformance mirror) are spec-licensed + tested + documented, the gate is green on an independent re-run, and the mutation spot-check confirms the tests bite. Per the right-size discipline (rigor constant, only ceremony scales — a clean verify with no REMEDIATE list has no second-pass work), Mars-2 collapses: there is nothing to remediate or harden. The full gate ladder + the determinism posture are already established (Mars-1's sweep + my re-run).
The one remaining pre-commit step is the Stage-5 triad sync: the spec body emq.5.2.md still frames forks 5.2-A / 5.2-B as `RULING: [WITHHELD]`; a SHIPPED rung must commit a self-consistent triad (the body, not just the ledger, is the program's source of truth). That is Venus's surface (the Director does not author/edit the spec body). Releasing a focused Venus-2 to flip the two forks to D-1/D-2/D-3 and fold the as-built realization notes (size=depth licensed by INV-Floor+Ceiling; the settle_batch/4 mirror seam; the window-from-open timeout semantics) into the body. THEN the Director's LAW-4 commit ships code + the consistent triad + the progress ledger.

## {emq-5-2-report} Report

### Y-1 — Director verify emq.5.2 — CLEAN (BUILD-GRADE ratified, zero REMEDIATE)

Independent pass on Valkey 6390, not a glance. All 8 INVs verified as runnable checks:
- INV-Boundary ✅ — `git status` shows ONLY the rung surface: NEW lib/echo_mq/batch_shaper/core.ex + lib/echo_mq/batch_consumer.ex + test/{batch_shaper_core,batch_consumer}_test.exs; M conformance.ex + the 2 pin tests. consumer.ex / jobs.ex / events.ex / connector / mix.exs / mix.lock / echo_wire / echo_data / apps/echomq ALL untouched.
- INV-NoLua ✅ — `git diff lib | grep -c redis.call` = 0; no Script.new touched.
- INV-PureCore ✅ — core.ex has no Connector/Jobs/Process/clock/IO; deterministic.
- INV-Floor+Ceiling ✅ — spec body line 287 LICENSES `size = depth` ("carries ≥ min_size … the request size ≥ min_size", NOT "exactly min_size"); ceiling measured from window-open (line 292); empty-window flushes nothing.
- INV-ClaimPath ✅ — flush calls Jobs.claim_batch/4 over flat pending (NOT Lanes.claim); pending_size/2 watch; pause via claim_batch's paused?/2-first.
- INV-PartialFailure ✅ — per-member complete/5 (att = the fence token, mirroring byte-frozen consumer.ex:157/243 EXACTLY) / retry/7; absent id → fail-safe retry "missing verdict".
- INV-Conf ✅ — prior 64 byte-unchanged (sole `-` = a trailing-comma artifact on the previously-last map entry); +3 additive + probe-registered; both pins re-pinned 64→67.
- INV-Events ✅ — per-member Events.publish/5 on the gated id; no new transport.
ADVERSARIAL: (a) token semantics — confirmed `att` IS the optimistic fence (consumer.ex reference), Mars's settle is the canonical pattern, not a bug; (b) window/loop — t0 is PRESERVED across :wait recursion (ceiling genuinely fires), fresh t0 only after a flush; (c) drift-seam — the conformance settle_batch/4 mirrors BatchConsumer.settle/3, but the REAL process test (batch_consumer_test.exs:187-247) independently proves the absent-member fail-safe → not a hidden-bug risk.
GATE (independent re-run): compile --warnings-as-errors EXIT 0 (echo_mq clean; the lone warning is the pre-existing echo_data ChampView→EchoStore.Graft cross-app ref, not this rung); `mix test --include valkey` → CONFORMANCE 67/67, 9 doctests, 441 tests, 0 failures. The `[error] GenServer killed` lines = the documented test-conn-dies-with-owner pattern (0 failures).
MUTATION SPOT-CHECK (LAW-1a, net-zero): injected 2 faults — (1) batch_consumer.ex:259 fail-safe default `{:error,"missing verdict"}`→`:ok`; (2) core.ex:84 ceiling `>=`→`>`. 4 tests caught them (the live-process fail-safe test + the core boundary + partial + doctest). Reverted by inverse Edit (NO git checkout); net-zero confirmed by string re-grep (originals present, mutations absent); targeted suites green again.
DETERMINISM POSTURE: NORMAL, honest — Mars's 8-seed sweep + 25× repeat loop + my independent full re-run. No ≥100 loop (mints no branded id, opens no new lease; the batch lease shipped byte-frozen in 5.1's @bclaim; the only nondeterminism is the timer, injected/deterministic).

## {emq-5-2-complete} Complete

### Z-1 — emq.5.2 SHIPPED (min_size/timeout batch shaping)

The batch-shaping cadence is built, Director-verified BUILD-GRADE, and the triad is self-consistent — ready for the single LAW-4 pathspec commit (Part A of the four-part directive complete).
- WHAT: NEW EchoMQ.BatchShaper.Core (pure decide/4 + validate!/2) + EchoMQ.BatchConsumer (watch-depth process, injected clock, sibling of Consumer) over the byte-frozen @bclaim/claim_batch/4. Per-member verdict map + absent→fail-safe-retry. conf 64→67. No Lua, no new lease, no new key, no wire edit.
- RULINGS: D-1 (new module, the Arm-A→Arm-B reversal on the family boundary) · D-2 (per-member verdict map + fail-safe) · D-3 (+3→67) · D-4 (Mars-2 collapsed, right-size).
- VERIFY (Y-1): 8/8 INVs; independent gate CONFORMANCE 67/67, 9 doctests, 441 tests, 0 failures; mutation spot-check caught 4× + reverted net-zero; NORMAL determinism posture (8-seed + 25× + re-run, no ≥100 loop — mints nothing, opens no lease).
- TRIAD: synced to the as-built by Venus-2 (Stage-5); both forks flipped WITHHELD→ruled; the carve decision-trail preserved.
- COMMIT SURFACE (13 paths, the rung's measured surface ONLY): the 4 new batch files + conformance.ex + the 2 pin tests (echo/apps/echo_mq); the emq.5.2 triad+prompt; the emq-5-2 progress+registry. The 5 Operator pre-staged foreign files (.claude/agents/mars.md, echo/.env.test, echo_graft ×3) EXCLUDED via --only.
CARRIED FORWARD (post-ship): Part B reconcile — the emq.5.1 dead-link defect (L-2) is msh-CONFIRMED STILL PRESENT (5 DEAD-TARGET errors, emq.5.1.md:32/315/318/319 + emq.5.1.llms.md:43; Venus-2's "0 findings" was an over-claim), to fix as a SEPARATE hygiene commit + the roadmap/progress/changelog fold; Part C Apollo calibration (fold L-1/L-3); Part D ship emq.5.3.
