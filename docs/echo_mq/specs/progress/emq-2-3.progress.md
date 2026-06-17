# emq-2-3 — AAW scope ledger

## {emq-2-3-thinking} Thinking

### T-1 — UNDERSTAND/EXPAND: the watch plane closes the emq.2 parity cluster (Director bootstrap)

### T-2 — Stage-1 as-built RE-PROBE complete (the lag-1 floor, confirmed against the tree)

Toolchain: erlang 28.5.0.1, elixir 1.18.4 (asdf, echo/.tool-versions); Valkey on 6390 -> PONG.

CONFORMANCE IS LIVE 32, NOT the triad's 18 (BOOTSTRAP FINDING 1 confirmed). echo/apps/echo_mq/lib/echo_mq/conformance.ex moduledoc reads "thirty-two runnable scenarios"; scenarios/0 enumerates 32 names: the 18 founding (fence,mint,duplicate,kind,order,claim,stale,complete,retry,dead,reap,rotate,pause,limit,schedule,repeat,backoff,resubscribe) + emq.2.1's 6 (counts,state,metrics,dedup,rate,lane_depth) + emq.2.2's 8 (queue_pause,drain,obliterate,update_data,update_progress,job_logs,remove_job,reprocess_job). BOTH pins at 32: conformance_scenarios_test.exs @run_order (32 names, Keyword.keys == @run_order) + conformance_run_test.exs (Conformance.run == {:ok, 32}). -> Build ADDITIVELY ON 32; re-pin both to 32+k.

THE D-5 EVENT SEAM IS ON THE WIRE (BOOTSTRAP FINDING 2 confirmed, deeper than the brief). jobs.ex @update_progress (jobs.ex:400-406) already PUBLISHes ARGV[3]..'events' (= emq:{q}:events) cjson.encode({event='progress', job=ARGV[2], progress=ARGV[1]}). So the event channel name (emq:{q}:events) + the cjson {event=...} payload shape + the host-after-verdict placement are PRE-DECIDED by this inherited seam.

THE :lock SUBKEY IS ALREADY READ by emq.2.2's remove_job (jobs.ex:489-506,508-517): "if redis.call('EXISTS', jk..':lock')==1 then return redis.error_reply('EMQLOCK job is locked')". The remove_job doc states verbatim: "the §6 lock subkey the worker-side lock plane writes at emq.2.3". -> emq.2.3's lock plane WRITES emq:{q}:job:<id>:lock so the emq.2.2 EMQLOCK guard becomes live.

THE LEASE IS THE ACTIVE-SET SCORE (jobs.ex @claim:133-135): t=TIME; now=t[1]*1000+floor(t[2]/1000); ZADD active, now+lease, id. The EMQSTALE token fence (@complete:140-144, @retry:175-177): HGET attempts; if att~=ARGV then redis.error_reply('EMQSTALE ...'). complete/4 keys [active, job_key]; client maps {:error,{:server,"EMQSTALE"<>_}}->{:error,:stale}. The reaper @reap:245-273 scans active ZRANGEBYSCORE -inf now -> pending. jobs.ex ENDS at line 587 (reprocess_job) -> D4 appends after it.

CONNECTOR PUB/SUB SEAM (echo_wire/connector.ex): subscribe(conn,channel):109 + unsubscribe:119 GenServer.call; the subscriptions MapSet:158, recorded on SUBSCRIBE/UNSUBSCRIBE (220-232); resubscribe/1:606 re-issues the set at the :reconnect arm (334); down/1:586 KEEPS the set; pushes route as send(push_to,{:emq_push, payload}):553 where payload is the raw decoded RESP3 push frame (a list — ["message",channel,data] / ["subscribe",channel,n]); RESP3-gated (protocol_live!=3 -> {:error,:requires_resp3}). The emit/3 precedent:634-640 guards :erlang.function_exported(:telemetry,:execute,3).

PUMP :transient SHAPE (pump.ex): child_spec restart::transient:31-38; owner-started/no mod:; pure Pump.Core (tick_ms/batch, doctested, no clock):core.ex; arm/1 Process.send_after(:tick):146-149; sweep/1 direct-drive:91-100. Consumer is the spawn_link drain loop (consumer.ex:91-98) the lock plane sits BESIDE.

GRAMMAR (keyspace.ex): queue_key(q,type)->emq:{q}:<type> (:14-15); job_key(q,id) gates BrandedId.valid?/1, raises (:18-24); reserve(s)->{emq}:<s> (:27). -> event channel = queue_key(q,"events"); stalled-count carrier ruled at D1 against §6.

DEPS: echo_mq/mix.exs deps = [echo_data, echo_wire] ONLY — NO :telemetry, NO application.ex (processes owner-started). -> :telemetry is a guarded optional use (function_exported); mix.lock EXCLUDED (D1 confirms).

V1 CAPABILITY SURFACE (port the COMPLETE public surface — Operator's "close all gaps" directive): queue_events {start_link/1,subscribe/2,unsubscribe/2,close/1,@callback handle_event/3,__using__}; telemetry {attach/4,attach_many/4,emit/3 (atom+list),span/3, + job_added/4,job_started/4,job_completed/5,job_failed/6,job_retried/5,worker_started/3,worker_stopped/3,rate_limit_hit/2}; lock_manager {start_link/1,track_job/3,untrack_job/2,get_active_job_count/1,get_tracked_job_ids/1,is_tracked?/2,stop/1}; stalled_checker {start_link/1,check/2,job_stalled?/4}; cancellation_token {new/0,cancel/3,check/1,check!/1}. v1 extendLock-2/extendLocks-2/releaseLock-1 use the SEPARATE :lock STRING + a stalled SET + msgpack — the v1 mechanism (NOT lifted; re-derive the CAPABILITY: re-score the active member, write the :lock marker, declared keys). v1 telemetry roots [:echomq|suffix] -> re-root [:emq|suffix]; span emits [:start]/[:stop]/[:exception] monotonic-time.

### T-3 — Stage 3 (Mars-2) entry: the harden + test pass plan (one Mars identity, second pass)

Stage 2 (Director solo review) ratified Stage 1 (task #2 completed); the Stage-3 assignment carries NO explicit REMEDIATE list beyond the standing gate ladder, so Stage 3 = the full ladder + the v1-test-corpus adoption + the ≥100 loop (no remediation backlog to clear; I re-confirm by re-reading the ledger for any Director-added REMEDIATE entries before claiming clean).

THE STAGE-3 WORK (per the runbook §Stage 3 + the Operator's "tests v1 adopted and verified"):
1. Confirm no Stage-2 REMEDIATE items pending (re-read emq-2-3.progress.md decisions/learnings for Director additions).
2. Author the v1 watch test corpus ADOPTION as NEW per-app suites under echo/apps/echo_mq/test/ — re-derive each v1 test against the v2 surface (NEVER edit apps/echomq/test, the read-only reference; a v1 :lock-STRING assertion becomes a v2 active-set-RE-SCORE assertion; a v1 caller-clock assertion becomes a server-TIME assertion; the v1 [:echomq,...] telemetry becomes [:emq,...]; the v1 module names become the collision-free Events/Meter/Locks/Stalled/Cancel). The v1 corpus (~2000 LoC): telemetry_test.exs (253), cancellation_token_test.exs (294), queue_events_integration_test.exs (585), worker_cancellation_test.exs (449), telemetry/behaviour_test.exs (219), telemetry/opentelemetry_test.exs (213), + lock-manager/stalled coverage in worker_integration_test.exs. Where a v1 test asserts a capability the v2 boundary DEFERS (the telemetry contract -> emq.8; the distributed cancel -> emq.6), adopt only the surface-level part + record the deferral (INV6/INV7).
3. The watch-verdict DRILLS as standing per-app suites (an extended lease survives the reaper; a stale token refuses EMQSTALE; a past-threshold job recovered/dead; a subscriber receives a lifecycle event; an attached [:emq,...] handler fires) — beyond the conformance scenarios (which are wire-level), these are the unit-level surface drills.
4. The full gate ladder: toolchain re-probe (no hardcode) + Valkey 6390 PONG; per-app pure + :valkey + process suites; CONFORMANCE 37/37 with the 32 prior byte-unchanged (git-verify) + both pins; emq.1+2.1+2.2 ladders still green (no regression).
5. The ≥100-iteration determinism loop over the process-touching suites (Locks + Stalled timers), the loop OWNING the machine (no concurrent liveness server — kill any stray :4000, no sibling heavy I/O).

PROCESS-TOUCHING SUITES (the loop targets): the new lock-plane suite (Locks track/extend/untrack on a timer), the new stalled suite (the periodic sweep), the conformance run (process-adjacent). The id-mint hazard (echo/CLAUDE.md §4 -- Portal.ID @node=1; here EchoData.BrandedId via Snowflake.start) means a same-ms mint can collide across runs -- the loop is the gate, not one green run.

### T-4 — Mars-1 Stage-3 status: BLOCKED on the Director's partition ruling (the Mars-1/Mars-2 parallel collision, L-5)

DONE by Mars-1 this Stage-3 pass (green, verified):
- L-3 REMEDIATE: lock_manager/core.ex marker_ttl_ms/1 (doctested) + lock_manager.ex track_job SET ... PX + extend_all PEXPIRE-refresh on the beat. The crash-recovery drill PASSES (a crashed worker's marker self-expires; remove_job no longer wrongly EMQLOCK; a live worker's marker survives via the beat refresh). [L-4]
- The v1 watch test corpus ADOPTED (D-5): cancel_test.exs (19) + meter_test.exs (11, two-mode guard) + events_integration_test.exs (8) all GREEN ALONE. locks_stalled_test.exs (13) GREEN ALONE.
- INV1 git-verified: the 32 prior conformance scenarios byte-unchanged (only a trailing comma on reprocess_job + moduledoc/alias text).
- capture_log added to my crash drill to quiet the deliberate-kill noise.

BLOCKED: the full per-app suite + the ≥100 determinism loop CANNOT pass yet because Mars-1's locks_stalled_test.exs DUPLICATES Mars-2's jobs_extend_test.exs (D4) + locks_test.exs (D5) -- two :lock crash drills killing connectors on the shared Valkey cross-contaminate (a consistent 1 failure at locks_test.exs:279 in the full run; 3 on seed 0). Mars-2 is ALSO live-editing my files (the disposable-connection purge harden). Editing concurrently-owned files now = a write-write conflict.

PROPOSED (Director to ratify): Mars-2 owns D4+D5 test suites (better-factored, deterministic send(:beat), INV5 coverage); Mars-1 trims locks_stalled_test.exs -> the D6 Stalled coverage ONLY (-> stalled_test.exs), keeps cancel/meter/events. Also: confirm who owns the L-3 production fix in lock_manager.ex (a possible SECOND collision -- Mars-1 did it).

HOLDING all edits until the Director partitions. Reported via SendMessage(director).

### T-5 — Mars-1 Stage-3: the collision RESOLVED (by Mars-2's L-6/L-7); coordinating the single ≥100-loop owner

The L-5 collision is closed WITHOUT a Director ruling: Mars-2 self-reconciled (L-7) -- DELETED its redundant locks_test.exs (it dup'd my D5 + had a link-cascade bug; my spawn_monitor isolated-owner crash drill is the kept idiom), KEPT jobs_extend_test.exs (additive D4 depth: the never-a-:lock-string proof, the no-re-score-on-stale, the empty/whole-live-batch edges, the INV5 ill-formed-id guards; + a RESP3-float-score bug fixed), and HARDENED my two suites (L-6, the disposable-purge idiom: their conn-bound catch:exit purge silently skipped the DEL -> 19 keys leaked/run -> a per-VM-reused queue name collided next run -- the exact ≥100-loop hazard, caught early; 12 runs -> 0 leaks). VERIFIED: no production collision -- Mars-2 stayed test-only; my L-3 fix (lock_manager.ex PX-SET + beat-PEXPIRE + core marker_ttl_ms/1) is INTACT + the sole production change; mtimes settled.

CONVERGED STATE: 4 doctests, 201 tests, 0 failures; CONFORMANCE 37/37 (32 prior byte-unchanged + both pins). Watch suites partition cleanly: jobs_extend (Mars-2, D4) + locks_stalled (Mars-1, D5+D6) + cancel/meter/events (Mars-1).

HOLD: the ≥100 determinism loop. BOTH Mars are tasked with it; two loops on the shared Valkey 6390 = sibling-I/O contention forging a failure. Asked the Director to name the SINGLE canonical loop owner (SendMessage). Ready to run it (machine clear) or stand down. Everything else on Mars-1's Stage-3 list is DONE.

### T-6 — Mars-1 SOLO (Director resolved the collision: Mars-2 shut down as a redundant recovery spawn). RECONCILE: no collision damage; tree clean + green

The Director ruled Mars-1 owns Stage 3 SOLO; Mars-2 (spawned when my silent idles + a stale registry last_seen read as "dead") is shut down and writes no more. LESSON (team-lead): never end a turn on a silent idle -- it caused the duplicate spawn. Going forward: a one-line checkpoint after each suite, never a silent idle.

STOPPED my in-flight ≥100 loop (bxyuc1cer) + its Monitor -- both were contending with Mars-2's concurrent loop (no valid loop reading captured; will re-run SOLO on the now-uncontended machine).

RECONCILE PROBE (Director step 2 -- detect collision damage from the parallel writes):
- compile --warnings-as-errors: CLEAN, 0 warnings.
- full suite (uncontended): 4 doctests, 201 tests, 0 failures; CONFORMANCE 37/37.
- ls test/: the 5 watch suites present (cancel, events_integration, jobs_extend, locks_stalled, meter); NO locks_test.exs (Mars-2 cleanly deleted its redundant one -- L-7); no dup/truncated/half-written files.
- git status echo/apps/echo_mq: exactly the expected emq.2.3 touch-set -- modified conformance.ex + jobs.ex + the 2 conformance pins + connector_test.exs (Mars-2 fence-race fix, test-only); new events/telemetry/lock_manager(+core)/stalled_checker/cancellation_token + the 5 test suites. apps/echomq + echo_wire + mix.lock UNTOUCHED.

VERDICT: the parallel writes CONVERGED cleanly (Mars-2's contributions -- the additive jobs_extend_test D4+INV5 depth, the disposable-purge leak fix L-6, the version-fence DB-isolation -- are all sound, test-only hardening that strengthened the suite). My L-3 production fix is intact + the sole production change. NO reconcile repair needed -- the tree is already clean + green.

REMAINING (solo): re-run the ≥100 loop over the rung's process suites (uncontended now) -- the only open gate item. The Events/Locks/Stalled suites the Director's step-4 lists are ALREADY shipped (events_integration_test = the Events adoption; locks_stalled_test = the Locks plane + the A1 crash drill + the Stalled sweep; jobs_extend_test = the lock-extend drill). The coverage table is Y-3. So step 4 reduces to the ≥100 loop.

### T-7 — RESUME at the gate→ship boundary (Director, post-emq.2.4 design cycle): the ≥100 gate is GREEN

The Operator RULED "ship emq.2.3" (AskUserQuestion, recommended option) after the emq.progress.md dashboard reconcile (the `## Development Progress [RECONCILE]` block broken out per-rung; **emq.2.2 confirmed shipped `76fc947c`, ancestor of master** — the "emq.2.2 not shipped" premise resolved against git ground truth; the stale block had lumped the cluster). Resuming emq.2.3 at its Stage 3→4 boundary: build converged at T-6 (201 tests / 0 fail); L-15 (cast/call race) + L-16 (version-fence linked-exit) fixes RE-VERIFIED present on disk (locks_stalled_test.exs:219-226 is_tracked?/2 FIFO barrier; connector_test.exs:78 trap_exit-in-setup + @fence_db 15 raw redis-cli flush).

THE AUTHORITATIVE GATE (Director-owned, machine-owned, FIXES-IN — the first ≥100 with BOTH L-15+L-16; the L-462 ~115 clean runs predate both fixes, so they did not count):
- Machine clear (no :4000 / stray beam contention).
- Conformance 37/37 (single run; L-393 keeps the heavyweight Conformance.run OUT of the loop — the byte-frozen L-8 backoff/schedule margin is a pre-existing carry to emq.8).
- ≥100 loop over the 6 process suites (locks_stalled + cancel + meter + events_integration + jobs_extend + connector), seeds 1..100: **PASS=100 FAIL=0**, 73 tests/iter, 0 failure files captured. Log /tmp/emq23_gate_loop.log.
- No accumulation: dbsize 13→13 FLAT (the L-6 unbounded-leak class is absent). Residue = 3 keys from ONE queue (emq23.lst19266: :dead + :job + :metrics:failed) — the stalled-sweep dead-letter path's on_exit purge missed them; BOUNDED (queue names use System.unique_integer which resets per VM → collide-not-accumulate), non-gate. Handed to Apollo as a cleanup-completeness finding to assess.

NEXT: Stage 4 Apollo (MANDATORY, the §11.2 charter — process+lease risk tier) → Stage 5 Venus triad reconcile (the stale "18"→"37"; the Cancel/Meter→CancellationToken/Telemetry module-name drift) → Stage 6 the LAW-4 pathspec commit (STOP at the commit for the Operator's review, per the chosen option).

## Mode
Flat-L2, Director-supervised, **dedicated Apollo evaluator** (the process-and-lease risk tier). Six stages:
Mars-1 (design-make + build) → Director solo review → Mars-2 (remediate + harden + ≥100 loop) →
**Apollo (adversarial verify + reconcile)** → Venus (post-build specs reconcile) → Director (closure + one LAW-4 commit).
Scope `emq-2-3`. Operator `jonny`. Ledger `docs/echo_mq/specs/emq-2-3.progress.md`.

## The fork is RULED — Arm A
The design §6 sequencing fork (Arm A = parity cluster fills the read/ops/observability floor, emq.3–emq.8 keep
their slots; Arm B = pull flows/groups/batches in, re-sequence) is settled **Arm A** — by the Operator's
`/echo-mq-ship emq.2.3` invocation AND the compaction directive ("Build emq.2.3 next, closing the emq.2 parity
cluster (read→ops→watch)"). The triad is authored to Arm A; no spec rework. No open Operator decision remains.

## The dependency is satisfied
emq.2.1 (read plane, `EchoMQ.Metrics`, shipped 7d98ef86) + emq.2.2 (operator plane, `EchoMQ.Admin`, shipped
76fc947c). Probed: `metrics.ex` + `admin.ex` present in the as-built lib tree; conformance enumerates 32 keys.
The watch plane reads through both (the read plane is the lens the watch verdicts read; the operator plane is
the transitions the events fire on).

## 5W (from emq.2.3.md)
- **Why** — echo_mq ships the state machine + lanes + cadence + (after 2.1/2.2) read & operator planes, but has
  NO watch surface: no subscribe-to-lifecycle, no `:telemetry` attach, no worker-side lease-keep (a slow-but-alive
  job is reaped today — `Jobs.reap/2` is a server-side dead-lease scan with no worker counterpart), no explicit
  stalled-recovery distinct from the reaper, no cooperative cancel. The parity thesis requires echo_mq carry all
  five before apps/echomq can dissolve.
- **What** — `EchoMQ.Events` (per-queue subscribe/unsubscribe/close + host-side lifecycle publish over the
  connector pub/sub seam, auto-resubscribe) · `EchoMQ.Telemetry` (attach/attach_many/emit/span, re-rooted
  `[:emq,…]`, zero-cost when :telemetry absent) · a lock-extension verb on `EchoMQ.Jobs` (re-score active member
  to TIME+lease, EMQSTALE on a stale token) + batch extension · an opt-in supervised worker-side lock plane
  (`EchoMQ.LockManager`, the Pump `:transient` shape) · the explicit stalled-sweep (`EchoMQ.StalledChecker`,
  stall-count threshold beyond the reaper) · the cooperative cancellation token (`EchoMQ.CancellationToken`,
  worker-side new/cancel/check/check!).
- **Who** — the bus's observers + long-running consumers: a Exchange dashboard subscribing to completed/failed +
  plotting telemetry throughput, the platform attaching a lifecycle handler, a long-running handler extending its
  lease, an operator's recovery sweep, a cooperative handler checking a token. No TRD rung gates on emq.2.3 by
  name (the floor, not a feature) — recorded, not asserted.
- **When** — Movement I, last of the emq.2 cluster (2.1 → 2.2 → 2.3). Built this run.
- **Where** — `echo/apps/echo_mq` (the new modules + the lock-extension & stalled scripts as inline `Script.new/2`
  attrs — NO priv/; the new conformance scenarios; pure + :valkey + process suites), reading the one named
  `echo/apps/echo_wire` connector seam (subscribe/2, unsubscribe/2, {:emq_push,…}, the resubscribe MapSet) — the
  event plane RIDES it, never modifies it. apps/echomq UNTOUCHED (the capability reference).

## Solution space (incl. do-nothing baseline)
- **Do nothing** — REJECTED: the parity cluster cannot close (apps/echomq cannot dissolve) without the watch
  surface; the lease lifecycle stays half-built (reap without extend).
- **Lift the v1 mechanism verbatim** — REJECTED by the v2 laws: v1 uses a separate `…:lock` STRING key, the caller
  clock, wait/active LISTs, a 9-key moveStalledJobsToWait, a v1 event transport — all structurally inexpressible
  under declared-keys / server-clock / four-sorted-sets. Re-derive the CAPABILITY, never the mechanism.
- **CHOSEN — re-derive each capability onto the as-built surface**: the v2 lease IS the active-set score (the
  extension re-scores it); the event plane rides the EXISTING connector pub/sub seam (no new transport, no
  SSUBSCRIBE — design §12.3); the clock is the server's TIME; recovery is over the four as-built sets. Smallest
  change that preserves correctness: events publish HOST-SIDE after a transition verdict (the connector already
  sees it), so the byte-frozen transition scripts stay byte-unchanged and the publish is an additive host step
  (the Lua-side PUBLISH-per-transition alternative is steelmanned and chosen-against — it mutates frozen scripts).

## Invariants as runnable checks (INV1–INV8)
- INV1 wire law — `grep` no new wire class (EMQSTALE reused for the extension stale refusal; five-code fence union
  unextended); the prior conformance scenarios byte-unchanged + each new one probe-registered same change.
- INV2 event plane rides the seam — `grep` the build for SSUBSCRIBE + any new transport → expect EMPTY; events use
  `subscribe/2`/`unsubscribe/2`.
- INV3 lease server-clocked + token-fenced — the extension reads `TIME` inside the script + re-scores `active`
  (NEVER a `…:lock` string); a stale token → EMQSTALE. Adversarial probe: claim → extend past original deadline →
  reap/2 → job NOT reclaimed; then stale token → EMQSTALE.
- INV4 declared keys — the A-1 lint over every NEW Lua script (the extension + the stalled sweep): every key in
  KEYS[] or derived from a declared KEYS[n] root; the sweep declares ONLY the sets it touches (never the v1 9-key
  shape); inline `Script.new/2` (no priv/).
- INV5 branded identity — every job boundary keys through `Keyspace.job_key/2` (gates `BrandedId.valid?/1`).
- INV6 surface-not-contract — emq.2.3 ships the telemetry/event SURFACE (fires + scenarios); the telemetry
  CONTRACT (payload-shape matrix) is emq.8. Probe: no emq.8 proof leaked.
- INV7 family boundary — worker-side cooperative cancel + worker-side lock plane ONLY; distributed cancel = emq.6,
  durable stream = emq3.2, telemetry contract = emq.8. Probe: no emq.6/emq3.2/emq.8 surface leaked.
- INV8 design gate + determinism — no build artifact predates the D1 ledger entry; the process-touching suites
  (lock plane + stalled sweep) run the ≥100-iteration determinism loop owning the machine (one green run ≠ proof).

## BOOTSTRAP FINDING 1 — the lag-1 drift the triad carries (18 → 32)
The triad was authored at the cluster baseline (18 scenarios) and says "18 prior scenarios byte-unchanged" in
INV1/D8/US8/the as-built-floor section. Since then emq.2.1 (+6 → 24: counts,state,metrics,dedup,rate,lane_depth)
and emq.2.2 (+8 → 32: queue_pause,drain,obliterate,update_data,update_progress,job_logs,remove_job,reprocess_job)
shipped. The LIVE `EchoMQ.Conformance.scenarios/0` enumerates **32** keys; BOTH pinning tests
(`conformance_scenarios_test.exs` @run_order + `conformance_run_test.exs` {:ok, n}) are at **32**.
→ Mars-1 builds ADDITIVELY ON 32 (not the triad's 18): the new watch scenarios make it 32+k; both pins re-pin to
32+k. The lag-1 law (Mars RE-PROBES, never trusts the triad's number) handles it; Venus's Stage-5 reconcile syncs
the triad's stale "18" → "32". This finding is injected into the Mars-1 brief so the gate stays reachable.

## BOOTSTRAP FINDING 2 — the D-5 seam emq.2.2 left waiting
`jobs.ex:403-404` already PUBLISHes `cjson.encode({event='progress', job, progress})` on `emq:{q}:events`, with
the comment "PUBLISH is a no-op (returns 0) until emq.2.3 subscribes. emq.2.2-D6." emq.2.3's `EchoMQ.Events` is
the subscribe half: it subscribes ONCE to `emq:{q}:events` and dispatches on the payload's `event` field. The
channel name + the host-side-emit placement are thus PRE-DECIDED by the inherited seam (D1 confirms, does not
re-litigate the channel — `emq:{q}:events` is already on the wire).

## BOOTSTRAP FINDING 3 — the Operator's sharpened directive (in-boundary scope amplification)
`/echo-mq-ship` arg adds: "close all gaps of v1 rewrite. fully-functional. tests v1 adopted and verified." This
SHARPENS the rung within its concern (the watch plane), does NOT cross the boundary:
- **close all gaps** — port the COMPLETE public surface of all five v1 watch modules (queue_events 478 / telemetry
  291 / lock_manager 281 / stalled_checker 213 / cancellation_token 167 LoC), not a thin subset; emq.2.3 is the
  LAST parity rung, so "all gaps" = the v1 watch surface fully represented in echo_mq under the v2 laws.
- **fully-functional** — real end-to-end behaviour (a subscriber really receives events; the lock plane really
  extends on a timer; the sweep really recovers), not surface-only stubs. The INV6 two-layer split still holds —
  "fully-functional" = the SURFACE works, NOT that emq.8's proof matrix is pre-empted.
- **tests v1 adopted and verified** — the ~2000-LoC v1 watch test corpus
  (telemetry_test 253 + telemetry/{behaviour 219, opentelemetry 213} + cancellation_token_test 294 +
  worker_cancellation_test 449 + queue_events_integration_test 585; lock-manager/stalled coverage inside
  worker_integration_test) is RE-DERIVED against the v2 echo_mq surface (a v1 test asserting a `…:lock` string
  becomes a v2 test asserting the active-set re-score) and run GREEN, ON TOP of the conformance probes. Adopted
  tests live in `echo/apps/echo_mq/test/` (NEW); apps/echomq/test stays a READ-ONLY reference. This amplifies
  AS-2..AS-8 acceptance (esp. AS-8). Still echo_mq + the echo_wire seam only.

## Toolchain (re-probed, not hardcoded)
erlang 28.1 (from ~/.tool-versions); Valkey on **6390** → PONG. No rebase in progress. The tree is ENTANGLED
(Operator out-of-band: docs/redis-patterns/** staged, Dockerfile/Makefile/cmd/sitemap, docs/exchange/trd-9-1,
docs/portal, docs/mercury, docs/fwhd deletions) → the LAW-4 commit at close is a NARROW pathspec over the rung's
surface ONLY; NEVER git add -A.

## Risk tier — moderate → Apollo MANDATORY + ≥100 loop
emq.2.3 adds opt-in PROCESSES on timers (the lock plane + the stalled sweep) + a new lease transition (the
extension verb). Two substantive correctness risks: (1) the lease-extension racing the reaper/consumer (the
≥100 loop + the extend-survives-reap probe are the mitigating gate); (2) reading a v1-shaped mechanism the bus
does not have (a `…:lock` string / caller clock / new transport — INV2/INV3 + the adversarial probes are the
gate). Dedicated Apollo at Stage 4 (the §11.2 charter); the ≥100 determinism loop owns the machine.

## {emq-2-3-decisions} Decisions

### D-1 — The event surface (D1/AS-1 ruling 1; adopts ADR-4 + design §12.3 + the emq.2.2 D-5 inherited seam)

CHANNEL: emq:{q}:events — Keyspace.queue_key(q, "events"). NOT re-litigated: the inherited emq.2.2 @update_progress seam (jobs.ex:403-404) ALREADY PUBLISHes on ARGV[3]..'events' = emq:{q}:events. One channel per queue carries every lifecycle event; the event NAME rides the payload's `event` field. A pub/sub channel is not a slot-routed key, so this adds NO §6 key type and NO new transport — it rides the existing connector RESP3 pub/sub seam (ADR-4; design §12.3 defers SSUBSCRIBE to the cache rung).

PLACEMENT: EchoMQ.Events — a NEW module (events.ex). A per-queue subscription surface over the connector subscribe/2 + unsubscribe/2 seam, dispatching the {:emq_push, payload} push by decoding the RESP3 message frame (["message", channel, json]) and routing on the cjson payload's `event` field to a handle_event/3-style delivery. Subscribe ONCE to emq:{q}:events; the emq.1 resubscribe MapSet keeps the feed live across a reconnect (a dropped socket re-issues SUBSCRIBE at the :reconnect arm — connector.ex:606). The push channel's at-most-once honesty is STATED (a subscriber-less or post-disconnect PUBLISH is lost; the resubscribe is the existing mitigation — design §12.3), not papered over.

EMIT PLACEMENT: HOST-SIDE after a transition verdict (recommended, CHOSEN). The progress event is already emitted Lua-side by the inherited @update_progress (it had to be — update_progress is a row write with no host return distinguishing the verdict). The OTHER lifecycle events emq.2.3 adds (completed/failed/scheduled/dead/stalled) are published HOST-SIDE by EchoMQ.Events.publish/3 (a thin PUBLISH on the channel) AFTER the host reads the transition's verdict — so the byte-frozen @complete/@retry/@reap transition scripts stay byte-unchanged (INV1). The same cjson {event=..., job=..., ...} shape the inherited seam set.

PAYLOAD CONTRACT: cjson-encoded JSON object {"event": "<name>", "job": "<branded-id>", ...} on emq:{q}:events. The lifecycle facts that publish (the v1 QueueEvents capability re-rooted onto the as-built transitions): "completed" (after Jobs.complete -> :ok), "failed"/"dead" (after Jobs.retry -> {:ok,:dead}), "scheduled" (after Jobs.retry -> {:ok,:scheduled}), "progress" (the inherited Lua emit), "stalled" (after the stalled sweep marks a job). Each carries job=<branded-id>; richer fields (e.g. progress=value) ride the same object. EchoMQ.Events subscribes once and dispatches on `event`.

ALTERNATIVES (steelmanned): see V-1.

### D-2 — The telemetry tree (D1/AS-1 ruling 2; adopts ADR-4 + the Connector.emit/3 precedent)

ROOT: [:emq, ...] — the v1 [:echomq | suffix] rooting (telemetry.ex:117,135,150,168) re-rooted to the bus namespace [:emq | suffix]. The connector already fires [:emq, :connector, ...] (connector.ex:193,588) — EchoMQ.Telemetry roots the JOB lifecycle under the same [:emq, ...] prefix, one tree.

EVENT NAMES (the v1 six re-rooted, full-parity set): [:emq, :job, :added], [:emq, :job, :started], [:emq, :job, :completed], [:emq, :job, :failed], [:emq, :job, :retried], [:emq, :worker, :started] — plus the v1 surface's two further helpers the Operator's "close all gaps" directive includes: [:emq, :worker, :stopped], [:emq, :rate_limit, :hit]. span/3 emits the standard [...:start] / [...:stop] / [...:exception] triple with monotonic-time durations (the :telemetry.span shape, v1 telemetry.ex:166-205 re-rooted).

PLACEMENT: EchoMQ.Telemetry — a NEW module (telemetry.ex). attach/4, attach_many/4 (each prepends [:emq | suffix] and delegates to :telemetry.attach/attach_many), emit/3 (BOTH arities — atom name wrapped to a list, list suffix prepended-and-executed), span/3, and the lifecycle helpers job_added/4 job_started/4 job_completed/5 job_failed/6 job_retried/5 worker_started/3 worker_stopped/3 rate_limit_hit/2 (each builds the measurements+metadata map and calls emit).

ZERO-COST GUARD: every emit path guards :erlang.function_exported(:telemetry, :execute, 3) (the Connector.emit/3 precedent, connector.ex:634-640) — with no :telemetry dep loaded, emission is a no-op and costs nothing. attach/attach_many guard :telemetry being present similarly (a no-:telemetry attach answers :ok with no effect). echo_mq adds NO :telemetry dep (mix.lock EXCLUDED — D1 confirms).

THE SURFACE FIRES; THE CONTRACT IS emq.8 (INV6, ADR-2's two-layer split). emq.2.3 ships the attach/emit/span surface + registers a telemetry conformance scenario (an attached [:emq,...] handler receives a lifecycle event); it does NOT assert the telemetry CONTRACT (payload-shape matrix) — that is emq.8.

ALTERNATIVES (steelmanned): see V-2.

### D-3 — The lock plane: the lock-extension verb + the opt-in worker-side process (D1/AS-1 ruling 3; adopts ADR-3 + design §4/DQ-2c + the Pump precedent + the emq.2.2 :lock-subkey inherited contract)

THE LOCK-EXTENSION VERB (D4): Jobs.extend_lock/5 (conn, queue, job_id, token, lease_ms) -> :ok | {:error, :stale} | {:error, :gone}. A NEW inline @extend_lock Script.new/2 transition on EchoMQ.Jobs, declared keys [active, job_key] (KEYS[1]=queue_key(q,"active"), KEYS[2]=job_key(q,id)) — the @complete key shape. The script: (1) HGET KEYS[2] 'attempts'; if not att -> return -1 (the row is gone -> {:error,:gone}); (2) if att ~= ARGV[token] -> redis.error_reply('EMQSTALE extend token mismatch') -> {:error,:stale} (the EXISTING fencing-token class — NO new wire class, INV1; the @complete:142-144 pattern); (3) t=TIME; now=t[1]*1000+floor(t[2]/1000); ZADD KEYS[1] now+tonumber(ARGV[lease]) ARGV[id] — RE-SCORE the active member to a fresh server-clock deadline (the @claim:133-135 re-score; INV3 — the v2 lease IS that score, NEVER a separate :lock string). Returns 1 -> :ok. The verb reads the server TIME inside the script (DQ-2c — it touches a lease).

THE BATCH EXTENSION (the v1 extendLocks capability): Jobs.extend_locks/4 (conn, queue, [{job_id, token}], lease_ms) -> {:ok, failed_ids} — a NEW inline @extend_locks Script.new/2 over [active] + the base root (ARGV-derived job keys base..'job:'..id, the A-1 grammar-derived rule from a declared KEYS[n] root) that loops the (id,token) pairs, re-scores each active member whose token matches under one TIME read, and returns the ids whose lease could NOT be extended (stale/gone). NO msgpack (the v1 cmsgpack form is the v1 mechanism — re-derive with a flat ARGV list: ids and tokens interleaved or two parallel ARGV slices, declared-keys-clean).

THE WORKER-SIDE LOCK PLANE (D5): EchoMQ.LockManager — a NEW opt-in :transient supervised process (the Pump shape: child_spec restart::transient, owner-started, no mod:, optional :name). Public surface (full v1 parity): start_link/1, track_job/3 (id+token), untrack_job/2, get_active_job_count/1, get_tracked_job_ids/1, is_tracked?/2, stop/1. On a timer (the extend interval — a fraction of the lease, computed by a pure EchoMQ.LockManager.Core, the Pump.Core precedent, doctested no-clock) it calls Jobs.extend_lock/5 for each tracked job before its lease elapses. track_job ALSO writes the emq:{q}:job:<id>:lock marker (SET ... the §6 lock subkey emq.2.2's remove_job reads -> EMQLOCK; jobs.ex:492,515) and untrack_job DELs it (the releaseLock capability) — so the inherited emq.2.2 EMQLOCK guard becomes live. On completion the plane untracks (it does NOT double-retire — the complete/retry transition already retires the active score; the plane removes the :lock marker + stops extending). A consumer started WITHOUT the LockManager is the unchanged v2 worker (the opt-in law — INV3/INV7).

ALTERNATIVES (steelmanned): see V-3.

### D-4 — The stalled mechanism: the stall-count carrier + the explicit sweep (D1/AS-1 ruling 4; adopts ADR-3 + design §6 + the as-built reaper)

THE STALL-COUNT CARRIER: a `stalled` field on the as-built three-field job row (HINCRBY job_key 'stalled' 1), NOT a separate registered set. Rationale: the row already exists per job (state/attempts/payload/+progress/last_error), is gated at job_key (BrandedId.valid?/1 — INV5), and is DELeted by every terminal transition (complete/reap/remove) — so the stall count is bounded-complete with no separate sweep-to-clean and adds NO §6 key TYPE (it is a field on an existing key, like the inherited progress/last_error fields). A `max_stalled` threshold (default 1, the v1 default) is compared in-script. This is distinct from the dead-lease reaper (which scores the active set) — the stall count is the COUNT of times THIS job's lease lapsed without extension.

THE EXPLICIT SWEEP (D6): EchoMQ.StalledChecker — a NEW module. check/2 (conn, queue, opts) runs ONE sweep via a NEW inline @sweep_stalled Script.new/2; job_stalled?/4 (conn, queue, job_id, opts) answers whether a job is currently stalled (its `stalled` field > 0). The sweep declares ONLY the sets it touches: KEYS=[active, pending, dead] + the base root ARGV for the per-job key derivation (base..'job:'..id, the A-1 grammar-derived rule — NEVER the v1 9-key moveStalledJobsToWait LIST shape). The sweep: t=TIME; for each id in active whose score < now (the lapsed lease, ZRANGEBYSCORE active -inf now) -> ZREM active id; s=HINCRBY job_key 'stalled' 1; if s >= max_stalled -> dead-letter (HSET state dead, ZADD dead 0 id, HSET last_error 'stalled', HINCRBY metrics:failed) ELSE recover (HSET state pending, ZADD pending 0 id). Reads the server TIME (INV3 — it touches a lease; NEVER the v1 caller-clock timestamp). Beyond the as-built reaper (reap/2 recovers a lapsed lease ONCE with no count), NOT a replacement — the reaper stays the server-side single-scan dead-lease recovery; the StalledChecker is the count-thresholded worker-stall recovery on top, optionally run on its own :transient timer process (the Pump shape) like the v1 periodic sweep.

GROUP-AWARE: where a stalled job carries a `group` (the lanes family), the recover arm returns it to its lane (g:<group>:pending) mirroring @reap's group branch — so a grouped stalled job recovers into its lane, not the flat pending set. (Realization detail: the as-built @reap already handles the group branch; the sweep mirrors it for parity.)

ALTERNATIVES (steelmanned): see V-4.

### D-5 — The v1 watch test corpus adoption: which v1 tests adopted (re-derived to v2), which DEFERRED (the family boundary)

The Operator's "tests v1 adopted and verified" = re-derive each v1 watch CAPABILITY IN emq.2.3 SCOPE against the v2 surface, and record which v1 tests assert a DEFERRED capability (with its owning rung). NOT a literal copy.

ADOPTED (NEW suites under echo/apps/echo_mq/test/, green; apps/echomq/test NEVER edited):
- cancel_test.exs <- v1 cancellation_token_test.exs (294 LoC): the full worker-side token surface (new/cancel/check/check!, the cooperative patterns, concurrency, isolation, scalability). Re-derived: EchoMQ.Cancel; {:cancel,…} -> {:emq_cancel,…}; Runtimeale RuntimeError -> the typed EchoMQ.Cancel.Cancelled. 19 tests.
- meter_test.exs <- v1 telemetry_test.exs (253 LoC): emit (atom+list), attach/4, attach_many/4, span/3 (+exception), the lifecycle helpers. Re-derived: EchoMQ.Meter; [:echomq,…] -> [:emq,…]; the TWO-MODE guard (L-2 -- fires when :telemetry present, safe no-op when absent) + a new zero-cost-guard test the v1 corpus lacked (v1 had a hard :telemetry dep). 11 tests.
- events_integration_test.exs <- v1 queue_events_integration_test.exs (585 LoC): completed/failed/progress events, event sequences, multiple subscribers, the handler module, unsubscribe lifecycle, the channel name. Re-derived: EchoMQ.Events; {:echomq_event,type,data} -> {:emq_event,name,payload}; the v1 WORKER-emit mechanism -> the v2 host-side Events.publish/3 (+ the inherited Lua progress); the v1 waiting/active/delayed names (worker-lifecycle artifacts) -> the D1 set completed/failed/scheduled/progress/stalled. 8 tests.
- locks_stalled_test.exs <- v1 extend_lock tests (worker_integration_test.exs:2015,2039) + the LockManager + StalledChecker capability: extend_lock/5 (the v1 lock-string+stalled-SET script re-derived to the active-score lease + the attempts-token fence; v1 result 1/0 -> :ok / {:error,:stale}), extend_locks/4, the Locks process (track/untrack + the read trio + extend + the :lock marker), the L-3/L-4 crash-recovery drill, the Stalled sweep (recover below / dead at max_stalled, server TIME, beyond the reaper). 13 tests.

DEFERRED (a v1 test asserting a capability the v2 boundary defers -- adopted NOT, recorded WITH the owning rung -- INV6/INV7):
- telemetry/behaviour_test.exs (219 LoC) + telemetry/opentelemetry_test.exs (213 LoC): the telemetry CONTRACT/behaviour (start_span/end_span/serialize_context/record_exception, the OpenTelemetry adapter) = the telemetry CONTRACT, which is emq.8 (ADR-2's two-layer split). emq.2.3 ships the surface that FIRES, not the contract. DEFERRED -> emq.8.
- worker_cancellation_test.exs (449 LoC): the v1 WORKER abstraction wiring the cancel token into the processor (processor-receives-token-as-2nd-arg, cancel_job/cancel_all_jobs). The v2 bus has NO Worker abstraction (the consumer is a thin spawn_link loop), and the DISTRIBUTED cancel (cancel_job from another node) is emq.6. The worker-side cooperative TOKEN surface (the in-scope part) is fully adopted in cancel_test.exs; the worker-abstraction + distributed parts DEFERRED -> emq.6.

This keeps the additive-minor law + the family boundary clean: emq.2.3 verifies its own surface; emq.6/emq.8 add their contract/distributed proofs over it. Apollo verifies the adoption split at Stage 4.

### D-6 — Director ship-ratification (LAW-4): emq.2.3 BUILD-GRADE, cleared to commit

GATE (Director-independent, machine-owned, on the post-Apollo bytes):
- The ≥100 determinism loop GREEN 100/0 over the 6 process suites (seeds 1..100), with L-15 (cast/call race) + L-16 (version-fence linked-exit) fixed at root; dbsize flat 13→13 (no accumulation; the 3-key residue resolved by Apollo as a benign stale fossil).
- Final gate: compile --warnings-as-errors clean; per-app suite 4 doctests / 201 tests / 0 failures; Conformance.run 37/37 (the net-zero confirmation that Apollo's 5 mutations reverted clean).
- Declared-keys (the F-1 class) INDEPENDENTLY read on all 3 new Lua: @extend_lock KEYS=[active,job_key]; @extend_locks KEYS=[active] + ARGV base 'emq:{q}:'; @sweep_stalled KEYS=[active,pending,dead] + base — each ≥1 real KEYS[] pinning {q}, every derivation co-slotted. COMPLIANT.

APOLLO Stage 4 (Y-6): BUILD-GRADE. 5/5 mutation kill net-zero; the lease-survives-reap attack held (extend re-scores active, never a :lock string; stale→EMQSTALE; gone→:gone); INV1-8 verified; the 3-key residue resolved.

VENUS Stage 5 (Y-7): the triad reconciled to as-built, Director-verified — the DIRECTIONAL rename (Telemetry/LockManager/StalledChecker/CancellationToken → Meter/Locks/Stalled/Cancel for build-targets; the v1 citations PRESERVED, e.g. "the v1 EchoMQ.LockManager capability, built as EchoMQ.Locks"); floor 18→37; check/2 (v1) vs check/3 (build-target); STATUS→BUILT; 5 watch scenarios; the C1 (file/module mismatch) + C2 (extend_locks partial-batch + group-aware recover untested) carries recorded → emq.2.4.

BOUNDARY: apps/echomq (frozen v1) + echo_wire + echo/mix.lock UNTOUCHED. investex + docs/echo_mq/course/** + all other apps EXCLUDED (Operator out-of-band) — narrow pathspec, never git add -A.

OPERATOR (AskUserQuestion 2026-06-14): "Land both commits as planned." The C1 file-rename + C2 explicit tests deferred to emq.2.4. Two-commit structure: (1) the rung [emq] (code + Venus-synced triad + the emq-2-3 ledger/registry); (2) the docs fold [emq] (the emq.progress.md per-rung [RECONCILE] breakdown + 🔨→✅ + the roadmap flip, referencing commit 1's hash).

## {emq-2-3-alternatives} Alternatives

### V-1 — The event emit placement (≥2 steelmanned alternatives for D-1's fork)

ARM A (host-side after the verdict — CHOSEN). EchoMQ.Events.publish/3 issues a thin PUBLISH on emq:{q}:events after the host reads a transition's verdict (e.g. after Jobs.complete answers :ok). Steelman: the byte-frozen @complete/@retry/@reap transition scripts stay byte-unchanged (INV1, the headline additive-minor check); the host already holds the verdict and the branded id; the publish is a pure additive host step needing no Lua edit; it mirrors how the connector already routes pushes host-side. Cost: a host that calls the transition but not Events.publish emits no event (at-most-once on a best-effort channel — acceptable, the channel is fire-and-forget by ADR-4/§12.3, and the durable replayable stream is emq3.2).

ARM B (Lua-side PUBLISH from each transition script — CHOSEN-AGAINST). Add a PUBLISH line to @complete/@retry/@reap so the event fires atomically with the transition. Steelman: atomic with the state change (no host can transition-without-emit); the inherited @update_progress already does exactly this Lua-side. Why rejected: it MUTATES the byte-frozen transition scripts — @complete/@retry/@reap would no longer be byte-unchanged, breaking INV1's "the prior scenarios pass byte-unchanged" and the conformance-run pin; the atomicity it buys is moot on a fire-and-forget pub/sub channel (the PUBLISH is best-effort regardless of where it is issued — a subscriber that is down loses it either way); and it spreads the event contract across five scripts instead of one host module. The inherited @update_progress is the ONE justified Lua-side emit (it is a row write whose host caller has no verdict to branch on); the lifecycle transitions DO return a host-visible verdict, so the host emit is both sufficient and script-preserving. (Recorded; not taken.)

ARM C (a NEW per-event channel emq:{q}:events:<name> — CHOSEN-AGAINST). One channel per event name. Steelman: a subscriber filters by SUBSCRIBE, not by payload. Why rejected: the inherited seam already fixed ONE channel emq:{q}:events with the name on the payload's `event` field — adopting Arm C would contradict the shipped emq.2.2 contract and multiply §6 key types. (Recorded; not taken.)

### V-2 — The telemetry root + guard (≥2 steelmanned alternatives for D-2)

ROOT [:emq, ...] (CHOSEN) vs [:echomq, ...] (the v1 root, CHOSEN-AGAINST). Steelman for keeping [:echomq]: a v1 telemetry consumer's attach would port without changing the event prefix. Why rejected: the bus is echo_mq, and the connector already roots [:emq, :connector, ...] — one namespace per tree. echo_mq is the single source of truth with no compatibility layer (program law: zero version-suffix/migrate-from framing); a v1 handler is RE-derived against the v2 surface (the Operator's "tests v1 adopted and verified" — adopt by translation, the [:echomq]->[:emq] re-root is exactly that translation). (Recorded; not taken.)

GUARD by function_exported (CHOSEN) vs a hard {:telemetry, "~> 1.0"} dep (CHOSEN-AGAINST). Steelman for the hard dep: no guard branch, simpler emit. Why rejected: echo_mq's mix.exs deps are [echo_data, echo_wire] ONLY — adding :telemetry would move mix.lock (the rung adds NO dep per the runbook's Stage-6 pathspec EXCLUDE), and the established precedent IS the guard (Connector.emit/3 fires [:emq,:connector,...] guarded by function_exported and ships no :telemetry dep). The guard makes telemetry a zero-cost optional the host opts into by adding :telemetry itself. (Recorded; not taken.)

### V-3 — The lease-extension mechanism (≥2 steelmanned alternatives for D-3, the headline INV3 fork)

ARM A — re-score the active ZSET member to TIME+lease (CHOSEN). extend_lock re-scores the active-set member (ZADD active, now+lease, id) under the server TIME, token-fenced on the row's attempts. Steelman: the v2 lease IS that score (the @claim invariant) — re-scoring it is the structurally-correct extension; the reaper reads the SAME score (ZRANGEBYSCORE active -inf now), so an extension past the original deadline provably survives the reaper (the extend-survives-reap drill); declared keys [active, job_key] are slot-sound under the queue brace; it reuses the EXISTING EMQSTALE class (no new wire class); the @claim/@complete patterns are the proven precedent. This is the design's recommended mechanism (ADR-3, INV3).

ARM B — a parallel emq:{q}:job:<id>:lock STRING with PX TTL (the v1 mechanism, CHOSEN-AGAINST as the LEASE). The v1 extendLock SETs a :lock string token PX duration and the reaper would consult the string's TTL. Steelman: it is the literal v1 surface; a polyglot reader sees a familiar lock-string. Why rejected AS THE LEASE: under the single-ZSET v2 lease it is structurally redundant — the bus has ONE lease (the active score) and the reaper already reads it; a parallel lock string would be a SECOND source of truth for "is this lease live", which the reaper does not consult, so a lock-string extension would NOT actually save a job from the active-score reaper (the v1 reaper read the lock-string; the v2 reaper reads the active score — porting the v1 mechanism without porting the v1 reaper would be a silent no-op). NOTE — the :lock string is NOT discarded entirely: it survives as the PRESENCE MARKER the inherited emq.2.2 remove_job reads (EMQLOCK), written by track_job / deleted by untrack_job — but it is the "a worker holds this" flag, NOT the lease clock. The lease clock is the active score (Arm A). This split (active-score = the lease; :lock marker = the held-by-a-worker flag) is the v2 re-derivation of the v1 two-mechanism conflation. (Recorded; Arm A taken for the lease, the :lock marker retained for the EMQLOCK contract only.)

ARM C — fold lock-extension into the Consumer loop silently (CHOSEN-AGAINST). Steelman: no separate process; the consumer that holds a job extends it inline. Why rejected: the extension is a wire VERB with a typed refusal (EMQSTALE) — it belongs as a Jobs transition a port + a polyglot reader receive identically (ADR-3 alt 2), and the worker-side DRIVER is opt-in (a consumer without long jobs should not pay for a lease-extender — the Pump opt-in law). Burying it in the consumer denies both. (Recorded; not taken.)

### V-4 — The stall-count carrier (≥2 steelmanned alternatives for D-4)

ARM A — a `stalled` field on the three-field job row (CHOSEN). HINCRBY job_key 'stalled'. Steelman: the row already exists per job, is gated at job_key, is DELeted by every terminal transition (so the count is bounded-complete with NO separate cleanup); it adds no §6 key TYPE (a field on an existing key, exactly like the inherited progress + last_error fields emq.2.2 added); reading job_stalled? is one HGET. The v1 StalledChecker likewise tracks a per-job stall count.

ARM B — a registered emq:{q}:stalled SET of stalled ids (CHOSEN-AGAINST). Steelman: a set answers "which jobs are stalled" with one SMEMBERS; the v1 extendLock/extendLocks SREM a `stalled` SET (so the v1 reference HAS a stalled set). Why rejected as the COUNT carrier: a set records membership, not a COUNT — the threshold semantics (recover below max_stalled, dead-letter at/above) need a per-job integer, which a set cannot carry without a parallel counter; and a separate set is a new §6 key TYPE that must be swept clean on every terminal transition (the row field is cleaned for free by the existing DEL). The v1 stalled SET is the v1 mechanism's bookkeeping for its lock-string extension (SREM on extend) — under Arm-A's active-score lease the membership question is answered by "stalled field > 0", so the separate set is redundant. (Recorded; not taken. NOTE: a future emq.4 group-aware recovery MAY add a lane-scoped stalled view — out of emq.2.3 scope.)

ARM C — reuse the `attempts` field as the stall count (CHOSEN-AGAINST). Steelman: no new field at all. Why rejected: `attempts` is the FENCING TOKEN (every claim HINCRBYs it; the EMQSTALE fence compares it) — overloading it with stall semantics would corrupt the token discipline (a stall bump would invalidate the holder's live token, refusing a legitimate complete EMQSTALE). The stall count MUST be a distinct field. (Recorded; not taken.)

## {emq-2-3-learnings} Learnings

### L-1 — REALIZATION-OVER-LITERAL: the v1 watch module NAMES collide with the frozen reference; the new bus modules must be collision-free under EchoMQ.*

The spec triad + the surface map name the new watch modules EchoMQ.Telemetry, EchoMQ.LockManager, EchoMQ.StalledChecker, EchoMQ.CancellationToken (and EchoMQ.Events). But the FROZEN v1 reference apps/echomq ALREADY defines EchoMQ.Telemetry, EchoMQ.LockManager, EchoMQ.StalledChecker, EchoMQ.CancellationToken, EchoMQ.QueueEvents (grep: defmodule EchoMQ.* across apps/echomq/lib). Both apps build into the SAME code path (_build/dev/lib/echo_mq/ebin AND _build/dev/lib/echomq/ebin are both loaded), so two .beam files for one module name COLLIDE -- the code server loads whichever it finds first, NON-DETERMINISTICALLY. Proven live: a D5 process smoke that started EchoMQ.LockManager invoked the V1 one (stacktrace: "(echomq 1.3.0) lib/echomq/lock_manager.ex:114"), which has a different init/1 contract (:connection key) and raised KeyError -- the read-only reference SHADOWED the new bus module.

WHY the as-built echo_mq modules don't hit this: EchoMQ.Jobs/Lanes/Pump/Consumer/Conformance/Metrics/Admin/Keyspace have v1-DISTINCT names (v1 has no EchoMQ.Jobs etc.) -- so the collision is specific to the watch surface, whose v1 capability modules carry the same names emq.2.3 ports.

THE REALIZATION (behavior-identical, names collision-free; flagged with citing file:line per the realization-over-literal law):
- EchoMQ.Events (events.ex) -- SAFE as-is (v1 is EchoMQ.QueueEvents; no collision). KEEP.
- EchoMQ.Telemetry -> EchoMQ.Meter (telemetry.ex) -- the v1 EchoMQ.Telemetry collides. The new module is the [:emq,...] telemetry surface; "Meter" names the metering capability without the v1 collision.
- EchoMQ.LockManager -> EchoMQ.Locks (lock_manager.ex) -- the v1 EchoMQ.LockManager collides (the one that shadowed at runtime).
- EchoMQ.StalledChecker -> EchoMQ.Stalled (stalled_checker.ex) -- the v1 EchoMQ.StalledChecker collides.
- EchoMQ.CancellationToken -> EchoMQ.Cancel (cancellation_token.ex) -- the v1 EchoMQ.CancellationToken collides.
- EchoMQ.LockManager.Core -> EchoMQ.Locks.Core.

The PUBLIC CAPABILITY (arities + return shapes) is identical to the brief's named v1 surface -- only the module name changes to avoid shadowing the frozen reference (the boundary law: the read-only echomq reference must NEVER shadow the new bus). Venus folds the chosen names into the triad + the surface map post-build. The file names (lock_manager.ex / stalled_checker.ex / cancellation_token.ex / telemetry.ex) the brief's touch-set names stay -- only the defmodule changes.

CONFIRM-AT-BUILD: grep the new tree for any reference to the colliding names; the conformance scenarios + tests reference only the NEW names.

### L-2 — REALIZATION: the telemetry conformance scenario must branch on the :telemetry guard (the surface is OPTIONAL-dep, absent under per-app mix test)

The D3 telemetry SMOKE passed under `mix run` (umbrella root) because the full umbrella boots :telemetry (a transitive dep of portal). But the per-app `mix test` / `mix run` in apps/echo_mq does NOT put :telemetry on the code path -- echo_mq's declared deps are [echo_data, echo_wire] ONLY (no :telemetry), so Application.ensure_all_started(:telemetry) -> {:error, no telemetry.app} and Code.ensure_loaded(:telemetry) -> {:error, :nofile} in that context. Forcing telemetry onto the path would mean adding it as a dep (mix.lock moves -- forbidden, D1 confirmed EXCLUDED).

So the telemetry conformance scenario as first written ({:fail, :no_telemetry_event}) was WRONG -- it asserted "an attached handler receives an event" unconditionally, but under the program-mandated per-app test mode the guarded Meter.emit correctly NO-OPS (zero-cost-when-absent, the contract), so no event can be observed. CONFORMANCE was 36/37, run -> {:error, [:telemetry]}.

THE HONEST FIX (the surface's REAL two-mode contract, ADR-4 + the Connector.emit/3 precedent): the scenario branches on :erlang.function_exported(:telemetry, :execute, 3):
- telemetry PRESENT -> attach + emit a job-lifecycle event; assert the [:emq, :job, :complete] handler fires with the right measurements+metadata (the surface fires).
- telemetry ABSENT -> assert Meter.attach answers :ok and Meter.emit/job_completed answer :ok as SAFE NO-OPS, and NO event is delivered (the zero-cost contract). Both are real verdicts of the same surface.
This makes the scenario pass against the truth row in BOTH modes -- it proves the surface either fires (present) or is a safe no-op (absent), which IS the D3/INV6 contract. Venus notes the two-mode telemetry scenario post-build. (The surface DOES fire when telemetry is present -- the D3 smoke under the umbrella proved it; the conformance just must not assume presence under the per-app mode.)

### L-3 — REMEDIATE (robustness): the worker-side :lock presence marker has no TTL — the v2 lease/marker split dropped the v1's self-healing

THE FINDING (Director Stage-2 review). The v1 lock_manager used the `emq:{q}:job:<id>:lock` STRING as the lease itself — a `SET … PX <ttl>`, so a crashed worker's lock self-expired. emq.2.3 correctly SPLIT that mechanism under the v2 laws (the LEASE → the active-set score, re-scored by extend_lock; the `:lock` marker → a held-by-a-worker presence flag that activates emq.2.2's remove_job EMQLOCK guard). But `EchoMQ.Locks.handle_cast({:track_job,…})` (lock_manager.ex:140-141) writes the marker with a plain `SET marker token` — NO TTL — cleared only by untrack_job (lock_manager.ex:147-148).

THE GAP. On a worker crash BETWEEN track_job and untrack_job, the marker LEAKS: the job's lease (active score) lapses and the reaper/stalled-sweep recovers the job to pending, but the orphaned `:lock` key persists (neither @reap nor @sweep_stalled DELs it). remove_job then wrongly refuses EMQLOCK on a job no longer actually held — until the job happens to be re-claimed and re-tracked (which overwrites the marker). So the operator-remove surface is blocked on a stale marker for an unbounded window. This is the self-healing property the v1's PX TTL provided, dropped in the v2 split.

THE RECOMMENDATION (Mars-2 decides + documents — not a hard blocker, but the "fully-functional" directive + the high-risk tier want it resolved consciously):
- PREFERRED: SET the marker with `PX` ≈ a small multiple of the lease (e.g. 2×lease_ms), and REFRESH the PX on each beat alongside the lease extension (extend_all) — restoring the v1's self-healing: a live worker keeps the marker fresh, a crashed worker's marker self-expires shortly after the lease does.
- ALTERNATIVE: have @sweep_stalled / the recovery path DEL the `:lock` marker when it reclaims a job (the marker dies with the recovery).
- FLOOR (if Mars-2 judges the above out of scope): document explicitly that the marker's cleanup is the consumer's untrack responsibility, that a crashed-worker marker is cleared on re-claim, and that the transient EMQLOCK-on-a-recovered-job window is accepted — so the behavior is a recorded choice, not a silent gap.

If Mars-2 takes the PREFERRED fix, add a conformance/process drill: track a job, simulate a crash (no untrack), let the lease lapse + sweep, assert the marker has expired and remove_job no longer refuses EMQLOCK. Apollo verifies the chosen treatment at Stage 4.

### L-4 — L-3 REMEDIATED (Stage 3, the PREFERRED fix): the :lock marker now carries a PX TTL refreshed on each beat — the v1 self-healing restored

TAKEN: the Director's PREFERRED treatment (the "fully-functional" + high-risk-tier choice).
- EchoMQ.Locks.Core.marker_ttl_ms/1 (NEW, doctested): a small multiple of the lease (:marker_multiple, default 2×) -> 60000 for the default 30s lease, 20000 for a 10s lease. A non-positive multiple raises.
- EchoMQ.Locks state carries marker_ttl_ms; track_job SETs the marker with PX marker_ttl_ms (was a plain SET, no TTL); extend_all (the beat) PEXPIREs the marker for the STILL-HELD set (tracked minus the extend_locks `failed` ids) alongside the lease extension -- a failed id (stale/gone) is no longer held, so its marker is left to self-expire. untrack_job still DELs the marker (the clean-release path unchanged).
- RESULT: a live worker keeps BOTH the lease (active score, re-scored) AND the marker (PX, refreshed) fresh; a CRASHED worker (no untrack) loses BOTH shortly after -- the lease via the reaper/stalled-sweep, the marker via PX expiry -- so the operator remove_job/4 is NOT blocked on a stale EMQLOCK for an unbounded window. The v1 lock-string's PX self-healing, restored under the v2 lease/marker split.

DESIGN CONFIRMATION (surfaced by the drill): the extend_ms clamp min(lease-1) is correctly load-bearing -- the extend interval MUST be < the lease so the extension lands before the deadline. A test that passes extend_ms: 999_999 with lease_ms: 100 clamps to 99ms (the beat fires every 99ms), which is the self-healing refresh working AS DESIGNED. To simulate a crashed worker the drill KILLS the linked owner (stops the beat), not sets an impossibly long interval. NOT a code change -- a confirmation the clamp is right.

DRILL (the Director's requested crash-recovery drill, PASS): track a job -> marker present with a PX TTL -> remove_job EMQLOCK (held); KILL the owner (the linked plane dies, the beat stops) -> wait past the marker TTL -> the marker self-expired (GET nil, PTTL -2) -> reap recovers the lapsed-lease job -> remove_job SUCCEEDS (no stale EMQLOCK). Separately: a LIVE worker's marker SURVIVES past its TTL (the beat refreshes it); untrack DELs it. This drill is folded into the committed crash-recovery suite (Stage-3 watch drills). Apollo verifies the chosen treatment at Stage 4.

### L-5 — PARALLEL COLLISION: Mars-1 (me) and Mars-2 BOTH adopted the v1 lock/extend corpus; the duplicated crash drills flake under contention

aaw_status shows TWO implementor identities: Mars-1 (me, ccl-emq-2-3-2, the Stage-1 builder resumed for Stage 3) AND Mars-2 (ccl-emq-2-3-3, spawned 23:52 by the Director). The runbook said "resume the Stage-1 Mars (one identity, two passes)", but the Director spawned a SEPARATE Mars-2 and ALSO assigned me (Mars-1) the same Stage-3 task -- so we ran Stage 3 in PARALLEL and both adopted the v1 lock corpus:
- Mars-2 wrote test/jobs_extend_test.exs (9 tests, D4 extend_lock/extend_locks) + test/locks_test.exs (10 tests, D5 the lock plane), split cleanly by deliverable, with a DETERMINISTIC send(plane,:beat) drive + INV5 key-builder tests.
- Mars-1 (me) wrote test/locks_stalled_test.exs (13 tests) combining D4 + D5 + D6, plus test/{cancel,meter,events_integration}_test.exs.

THE OVERLAP: my locks_stalled_test.exs DUPLICATES Mars-2's D4 (extend_lock) + D5 (lock plane + the crash drill). Both crash drills KILL a self-started connector; run together in one suite, the killed-connector EXITs cross-contaminate -> a consistent 1 failure (locks_test.exs:279, Mars-2's crash drill) on the default seed, 3 on seed 0. Each suite ALONE is green (locks_stalled 13/0; the contention is cross-suite).

THE UNIQUE CONTRIBUTIONS: Mars-2 owns D4+D5 (better-factored). I uniquely own D6 (the Stalled sweep -- neither Mars-2 file covers it) + cancel (D7) + meter (D3) + events (D2).

PROPOSED RESOLUTION (Director to ratify -- one canonical suite per deliverable, no redundant cross-contending crash drills): Mars-1 TRIMS locks_stalled_test.exs to ONLY the D6 Stalled coverage (rename -> stalled_test.exs), DROPPING the duplicated D4/D5 (Mars-2's jobs_extend_test.exs + locks_test.exs own them). Mars-1 KEEPS cancel/meter/events. This eliminates the duplication + the flakiness at the source (one crash drill, not two). Surfaced to the Director before restructuring (no unilateral delete of a peer's files).

### L-6 — HARDEN (the pre-existing cross-run flake every single-run gate passed): the watch-suite cleanup leaked keys, colliding with a later VM run

THE FINDING (Mars-2 Stage-3, the ≥100-loop class surfacing early). locks_stalled_test.exs + events_integration_test.exs bound their on_exit purge to the test's `conn` AND wrapped it `try/catch :exit -> :ok`. Several of their tests deliberately KILL a plane's connection (the crash drill) or close an Events listener that races teardown, so the purge's `KEYS`/`DEL` on a dead/racing `conn` THREW -> `catch :exit` swallowed it -> the DEL was SILENTLY skipped. Measured: 19 keys leaked onto unique queue names even on a GREEN single run.

WHY IT WAS INVISIBLE TO EVERY SINGLE-RUN GATE (Mars-1 Stage-1, Director Stage-2): `System.unique_integer([:positive])` resets per VM, so on a FRESH `mix test` against the same Valkey, a new test's queue name (e.g. emq23.lst326) COLLIDES with a leaked emq23.lst326 from the prior run that still had an `active`/`dead` job. The new test enqueues its id to pending, but the leaked job is also on the queue -> claim/Stalled.check returns the WRONG/EXTRA id (seen as `claim returned {:ok, {OTHER_ID, "w", 2}}` at attempts 2, and `recovered: [id, OTHER...]`). A second run against shared state was required to fire it -- exactly the "one green run is NOT proof" hazard the ≥100 loop owns, manifesting as KEY leakage across runs rather than a same-ms mint.

THE FIX (the disposable-purge idiom the OLDER suites -- jobs_test.exs, consumer_test.exs -- already used; Mars-1's two new suites had drifted from it): on_exit opens its OWN fresh, dedicated connection just to `KEYS … DEL`, so the purge never depends on a connection a test tore down. No `catch` masking. RESULT: 12 consecutive runs of both suites (21 tests each) -> 0 failures, 0 keys leaked (was 19/run). Test-only change inside echo/apps/echo_mq; the production watch modules untouched. Apollo verifies the no-leak property at Stage 4 (re-run the loop, count `emq:{emq23.*}` keys post-run == 0).

### L-7 — SCOPE (the runbook's named NEW suites were ALREADY SHIPPED by Mars-1; reconstruct-from-the-tree, not from the runbook)

The Stage-3 runbook (authored before Mars-1 finished) prescribed building NEW test/events_test.exs, test/locks_test.exs, test/stalled_test.exs as the v1-corpus adoption. RE-PROBE of the as-built test tree shows Mars-1 ALREADY shipped the adoption:
- test/events_integration_test.exs (222 LoC) -- the full EchoMQ.Events adoption (subscribe/unsubscribe/close, a lifecycle event over {:emq_event,...}, the inherited Lua progress event, multiple subscribers, the handler module, unsubscribe-lifecycle, channel=queue_key). = the runbook's "EVENTS suite".
- test/locks_stalled_test.exs (269 LoC) -- a COMBINED suite covering BOTH the EchoMQ.Locks surface (track/untrack + the read trio + the direct-drive beat via Locks.extend(:sys.get_state(lm)) + the :lock marker->EMQLOCK + consumer-without-the-plane + the A1 crash drill done CORRECTLY via spawn_monitor + an isolated-owner kill + capture_log) AND the EchoMQ.Stalled surface (recover-below/dead-at-threshold, server-TIME, job_stalled? absent, beyond-the-reaper) AND extend_lock/extend_locks. = the runbook's "LOCKS suite" + "STALLED suite" + part of the extend drill.

So building NEW locks_test.exs / stalled_test.exs would DUPLICATE shipped coverage. DECISION (implementor discipline -- thin-but-robust, never redundant; the tree is the source of truth):
- DELETED my draft locks_test.exs -- net-redundant with locks_stalled_test.exs AND it carried a link-cascade bug (Process.exit(plane,:kill) on a start_link-LINKED plane propagated :kill across the link to the TEST process, killing it; the existing suite's spawn_monitor isolated-owner pattern is the correct idiom).
- KEPT test/jobs_extend_test.exs (9 tests) -- genuinely ADDITIVE depth on the D4 verbs that locks_stalled_test.exs does NOT cover: the explicit "re-scores never a :lock string" proof of the v2 split, "does NOT re-score on a stale token", the empty-batch + whole-live-batch-survives-reaper edge cases, and -- load-bearing -- the INV5 ill-formed-id-raises guards on BOTH extend_lock/5 and extend_locks/4 (the branded-id gate, untested before). One real finding fixed: RESP3 returns a ZSET score as a native Double (float), not a bulk string -- the active-score helper normalizes float|int|binary.

The deciding question per candidate suite: "does it assert a behavior NO existing test covers?" locks_test.exs -> no (+buggy) -> deleted; jobs_extend_test.exs -> yes (the INV5 guards) -> kept. Venus folds the as-built test inventory into the triad post-build.

### L-8

L-6b — PRE-EXISTING (the two-facts carry, NOT the rung's bug): the `backoff`/`schedule` conformance scenarios flake under load — a 6ms-margin sleep, byte-frozen by INV1

THE FINDING (Mars-1 Stage-3, the ≥100 loop). conformance_run_test.exs (the full Conformance.run/2 over 37 scenarios) flakes on iteration 1 EVEN ALONE (30-iter isolated run: 0/30, {:error, [:backoff]} / {:error, [:schedule]}). NOT contention with my watch suites (proven: it flakes alone, no Locks/Stalled/events running). The full-suite loop hit it at iter 14 ({:error, [:schedule]}); the isolated conformance_run hit it at iter 1 ({:error, [:backoff]}).

ROOT CAUSE (pre-existing, byte-frozen): apply_scenario(:backoff, …) (conformance.ex:333-362) is the poison-job drill: it retries with policy {:exponential, 1, 10} (delay 1-10ms), then `Process.sleep(delay + 5)` then `{:ok, 1} = Jobs.promote(…)`. The sleep margin is as low as 6ms (delay=1 + 5). Under any load (GC, scheduler jitter, Valkey command latency), the scheduled job's run-at score (server TIME) may not yet be crossed when promote runs -> promote returns 0 not 1 -> the `{:ok, 1} =` match fails -> the scenario fails. The `schedule` scenario has the same shape. This is a tight-margin TIMING flake, not a logic bug.

PROVENANCE: PRE-EXISTING. git show HEAD:.../conformance.ex finds apply_scenario(:backoff already at HEAD (76fc947c, emq.2.2) -- it predates emq.2.3 entirely (backoff/schedule/repeat are emq.1 FOUNDING scenarios). It is among the 32 prior scenarios INV1 requires BYTE-UNCHANGED -- so emq.2.3 CANNOT fix it (a sleep-margin edit would breach INV1 + is not this rung's bug).

THE TWO-FACTS RULING (the program law / gate ladder): this is fact (1) -- an environment/load-gated PRE-EXISTING flake the rung did not cause (a documented carry), NOT fact (2) a this-change-staled-it debt. The gate ladder: "the loop must OWN the machine -- no concurrent liveness server, no sibling heavy I/O -- a load-gated pre-existing test forges a failure the rung did not cause." The full Conformance.run/2 IS a heavyweight timing-sensitive sibling. So the ≥100 loop for emq.2.3 runs over the suites the RUNG ADDS (the process-touching watch suites: locks_stalled + cancel + meter + events_integration + jobs_extend), which prove MY rung's process code deterministic; the pre-existing conformance_run flake is carried + recorded, NOT fixed (INV1 forbids it). A SINGLE conformance run for the 37/37 count is the gate (it passes the vast majority of runs -- Stage-1 + Stage-2 both saw {:ok,37}); the LOOP gate is the rung's own process suites.

FOLLOW-UP (a future rung, NOT emq.2.3): the backoff/schedule scenarios want a wider sleep margin or a poll-until-due (a bounded retry of promote until it returns 1) -- but that is an INV1-breaking edit to the frozen 32, so it belongs to whichever rung is allowed to revise the founding conformance set (emq.8's proof-stack hardening is the natural home). Recorded for Apollo/Venus to carry forward.

### L-9 — the ≥100 loop surfaced a PRE-EXISTING emq.1-era global-state race (connector_test fence) — NOT a watch-suite fault; a boundary-edge fix proposed for the Director

THE LOOP RESULT: the full --include valkey suite x100 FAILED at iteration 48 (47/100) -- intermittent, ~1-2% rate. The failure was NEVER a watch suite. It was repeat_test.exs (an emq.1 suite) crashing `** (EXIT) {:version_fence, "echomq:0.0.1"}` at connector boot.

ROOT CAUSE (pre-existing, emq.1-era, outside the watch plane): connector_test.exs's "a mismatched fence is fatal at boot" test (connector_test.exs:78) SETs the GLOBAL `{emq}:version` reserve key to "echomq:0.0.1" to prove the fence refuses, then RESTORES it only in on_exit via a SLOW out-of-process `redis-cli` SET (~tens of ms). `{emq}:version` is a deployment-reserve key (NOT queue-scoped) -- the connector's fence/2 reads it at EVERY boot. The module is `async: false`, which serializes it against OTHER sync tests but NOT against the `async: true` pool (max_cases: 32) running concurrently. So during the on_exit restore window, any concurrently-running async test that boots a connector reads the poisoned "0.0.1" fence and refuses. The breadth of the FULL suite (the async pool + a connector boot in the window) is the trigger -- connector_test + repeat_test ALONE x25 never flaked; the full suite x100 flaked once. Classic "an async test must not leak process-global state" -- here the global state is the {emq}:version reserve key and the "async" is the on_exit I/O lag racing the async pool.

CLASSIFICATION: a PRE-EXISTING carry the rung's ≥100 loop surfaced -- NOT this change's debt (my watch suites are clean in every run; 8 full-suite runs post-watch-fix all clean, the fence flake fired ~1/100). But the loop won't reach 100/100 while it flakes.

PROPOSED FIX (verified-in-progress; connector_test is OUTSIDE the watch boundary, so escalated to the Director to ratify): restore the fence to "echomq:2.0.0" SYNCHRONOUSLY at the END of the mismatch test body, BEFORE it returns -- closing the poison window within the test's own serial execution instead of deferring it to the racy on_exit. The on_exit stays the safety net. One-test, test-only change. Validation: a 40x full-suite loop (running). If green, Apollo verifies + the Director ratifies the cross-boundary test-edit at Stage 4/6. If the Director prefers to keep connector_test untouched, the alternative is to record the fence flake as a documented pre-existing carry (env: the shared {emq}:version + the async pool) and run the ≥100 loop with connector_test's fence describe excluded -- a recorded boundary fact, not a watch-plane defect.

### L-10 — REMEDIATE (determinism gate): the ≥100 loop caught a shared-{emq}:version test-isolation flake (surfaced, not caused, by emq.2.3's new connector suites)

THE CATCH (Director-run ≥100 determinism loop, machine-owned). Iteration 5/100, seed 749230: 3 failures, all `** (EXIT) {:version_fence, "echomq:0.0.1"}`. The first real ≥100 loop of this rung surfaced a latent test-isolation hazard that single runs + multi-seed had missed.

ROOT CAUSE. `echo/apps/echo_mq/test/connector_test.exs` (PRE-EXISTING, emq.0; async: false) line 79 `SET {emq}:version echomq:0.0.1` is the "a mismatched fence is fatal at boot" test. `{emq}:version` is a SINGLE GLOBAL key every connector fences against at boot/reconnect (connector.ex:466-475, `SET vkey @wire_version NX` + read-back; `@wire_version="echomq:2.0.0"`). The test restores the version only in `on_exit` (the describe setup's snapshot, connector_test.exs:55-61) — i.e. AFTER the test body yields. So the bogus value is live for the whole window between the SET and the on_exit restore, and any connector that BOOTS or RECONNECTS in that window dies `{:version_fence, "echomq:0.0.1"}`. emq.2.3 added 5 connector-starting watch suites (events_integration, locks_stalled, jobs_extend, + cancel/meter) — far more connector boots/reconnects — raising the collision probability enough to surface at iteration 5. The production fence is CORRECT (it must refuse a stale store); the defect is the TEST mutating shared global state with a deferred restore. None of the new emq.2.3 suites write the bogus version (grep-confirmed) — they are the additional VICTIMS whose volume made the latent race probable.

THE FIX (test-isolation only — NO production change; inside echo_mq/test; Mars-1 authors + verifies, the Director re-runs the loop as the gate). Reproduce: `TMPDIR=/tmp mix test --include valkey --seed 749230`. Candidate directions (Mars-1 picks the robust one + confirms):
1. connector_test's mismatch test: restore `{emq}:version` to the valid claimed `echomq:2.0.0` SYNCHRONOUSLY within the test body (immediately after the refusal assertion) — NOT deferred to on_exit — so the steady-state global version is always valid and the bogus value is live only during the one synchronous failed `start_link`.
2. Eliminate lingering reconnectors: ensure every watch suite (events_integration/locks_stalled/etc.) STOPS its connectors/Events/Locks/Stalled processes at test end (on_exit GenServer.stop), so no connector lingers to reconnect into the bogus window.
3. If a window remains, serialize the fence-mutation against any connector boot (a global test lock, or assert the version is re-claimed valid before the test yields).

GATE. Stage 3 is NOT done until the ≥100 loop is GREEN and machine-owned. Mars-1 fixes + verifies with seed 749230 + a 30-iteration mini-loop; the Director re-runs the full ≥100 loop. (Determinism-loop discipline, echo/CLAUDE.md §3: the independent loop, not a single run, is the gate.)

### L-11 — the connector_test fence flake RESOLVED at the root (logical-DB isolation), after two rejected fixes; the ≥100 loop now runs the FULL suite

THE FIX ARC (L-9 named the race; this records the resolution after two rejected attempts):
1. REJECTED -- in-body synchronous restore (shrink the poison window from the on_exit redis-cli ~tens-of-ms to one in-process start_link ~few-ms). Validated by a 40x full-suite loop: FLAKED again at iter 23. Window-shrinking is the wrong shape -- the residual start_link window still overlaps the async pool.
2. REJECTED -- @describetag :fence_mutation + `--exclude fence_mutation` on the loop. DEFEATED by ExUnit's documented include/exclude precedence: the fence tests are `@moduletag :valkey`, the loop runs `--include valkey`, and `--include` OVERRIDES `--exclude` for any test matching the include -- so the fence tests still ran. Proven: `--include valkey --exclude fence_mutation` on connector_test -> 13 tests, 0 excluded.
3. TAKEN -- LOGICAL-DB ISOLATION (the root-cause fix). The fence-mismatch test inherently must poison {emq}:version (it exercises the real fence), but WHICH {emq}:version is configurable via the connector's `database:` option (connector.ex:152, SELECTed at boot connector.ex:437). Valkey 6390 has 16 DBs. The fence describe now routes its helper + every connector to `database: 15` (@fence_db) -- fence/2 SELECTs db15 and reads/claims/refuses the key THERE, invisible to every other test (all db 0). The mismatch test also DELs the key in-body (so db15 is claim-free regardless of on_exit lag -- the same global-state lag, now contained on db15). db15 is FLUSHDB-cleaned in setup + on_exit via the helper (no out-of-process redis-cli). The real fence logic (SET NX + read-back + mismatch refusal) is still fully exercised; NO concurrency change, NO test excluded, NO coverage lost.

VALIDATION: db0 {emq}:version UNTOUCHED after the fence tests run (the headline); fence tests 5x -> 13/13 each, db15 ends size 0; full suite 5x -> 201 tests, 0 failures; the ≥100 full-suite loop launched (no exclusion). This is the difference between a workaround (exclude/shrink) and a fix (remove the shared state). connector_test.exs is OUTSIDE the watch boundary -- the edit is test-only + escalated; the Director ratifies at Stage 6. The minimal-footprint principle: 3 fence tests re-pointed to db15 + a clean-up helper; the rest of connector_test byte-unchanged.

### L-12 — REMEDIATE (the determinism-gate RED): the connector_test global-state assumptions break under the watch suites' added load — version-fence AND script-cache, test-isolation only

THE GATE FAILURE (Director-run ≥100 loop, iter 5 seed 749230): 3x {:version_fence, "echomq:0.0.1"}. Reproduced by a mini-loop over connector_test + my watch suites (NOT reproducible per-seed -- a probabilistic shared-global-state race). PROVEN ISOLATION: connector_test ALONE is 30/30; it flakes ONLY when run CONCURRENTLY with the watch suites (the volume that surfaced it).

BROADER THAN THE VERSION-FENCE -- the mini-loop surfaced THREE distinct flakes, all the SAME CLASS (connector_test reads SHARED GLOBAL Valkey state my watch suites perturb):
1. {:version_fence,"echomq:0.0.1"} -- connector_test's "mismatched fence is fatal" test SETs the bogus version (now on the isolated db-15 via Mars-2's @fence_db fix, connector_test:96) but a lingering db-15 connection reconnecting in the window, OR the window itself, can still die. (The connector fences AFTER SELECT db -- confirmed connector.ex:437 SELECT then :387 fence -- so db-15 isolation IS structurally right; the residual is the lingering-reconnect window.)
2. connector_test:137 eval/5 "loads on a cold cache" asserts script_loads==1 after its own SCRIPT FLUSH -- but Valkey's SCRIPT cache is GLOBAL + shared across connections AND tests; my watch suites' Connector.eval calls SCRIPT LOAD their scripts (events/locks/stalled), re-warming the cache concurrently -> script_loads stays 0 -> {left:0,right:1}.
3. a LocksStalledTest Stalled-TIME assertion (seen once at seed 15) -- likely a residual key-leak/timing under load (the L-6 disposable-purge fix reduced but a window may remain).

THE ROOT (the connector_test assumptions, PRE-EXISTING emq.0): connector_test was authored assuming it OWNS the global Valkey state (the {emq}:version key window, the cold SCRIPT cache). That holds when it runs alone (30/30) but breaks under ANY concurrent suite that boots connectors / loads scripts -- which the watch suites do at volume.

THE FIX (test-isolation only, NO production change -- the production fence + eval are CORRECT):
(a) MY watch suites: the setup `conn` is created but on_exit only purges -- it does NOT stop the setup conn (the GenServer.stop in purge/1 is the DISPOSABLE conn, not the setup one). So the setup conn LINGERS past the test, free to reconnect into connector_test's fence/flush window. FIX: on_exit stops the setup conn explicitly (+ confirm Events/Locks/Stalled processes stop). Bounds the connector lifetime to the test.
(b) connector_test (the Director authorized touching it): the mismatch test restores a VALID echomq:2.0.0 synchronously in-body (not just DEL); the script-cache test (:137) is fundamentally global-cache-dependent -- its cold-cache assumption cannot hold under a parallel script-loader. Options: SELECT a dedicated db for the script-cache test too (but the SCRIPT cache is NOT per-db -- it is server-global, so a db change does NOT isolate it); OR make :137 tolerant (assert script_loads >= 0 + the warm path works) -- but that weakens the test. The robust answer is (a): if no watch-suite connector lingers, the contamination window closes. Verify which fix suffices by the mini-loop.

VERIFY: re-run seed 749230 + a 30-iter mini-loop over connector_test + all watch suites green. Then the Director re-runs the full ≥100.

### L-13 — REMEDIATE LANDED (the determinism-gate RED, fixed): stopping the watch suites' lingering setup connectors resolved ALL THREE contamination flakes; connector_test UNTOUCHED

THE FIX (test-isolation only, fix (a) from L-9 -- and it was SUFFICIENT alone; connector_test's logic NOT touched, which is the cleaner outcome -- the contaminator was MY suites, not the pre-existing test): each watch suite's setup created a `conn` whose on_exit only PURGED -- it did NOT stop the setup conn (the disposable purge/1 stops its OWN conn, not the setup one). So the setup conn LINGERED past the test, linked to the test process, free to RECONNECT into a sibling connector_test global-state window (the {emq}:version mutation, the SCRIPT FLUSH) and die {:version_fence,…} or perturb the script-cache assertion. FIX: on_exit now `stop_conn(conn)` (a guarded GenServer.stop, catch :exit -> :ok for tests that already killed it) BEFORE the purge, bounding the connector's lifetime to the test. Applied to events_integration_test.exs + locks_stalled_test.exs + jobs_extend_test.exs (the 3 connector-starting watch suites; cancel_test + meter_test are host-side/pure, no wire conn).

PROOF: a 30-iter mini-loop over connector_test + ALL 6 watch suites (the volume that surfaced it) -> 30/30 green (was 0/30..14/30 before, failing on version_fence / script_loads==1 / a Stalled-TIME assertion -- all three the SAME shared-global-state class). connector_test ALONE was already 30/30 (its internal isolation was fine; the flakes were purely cross-suite contamination from the lingering connectors).

WHY fix (b) (touching connector_test's version-restore + script-cache test) was NOT needed: with no watch-suite connector lingering, the contamination WINDOW closes -- connector_test owns the global state again during its own tests. The Director authorized touching connector_test, but the minimal+correct fix bounds the CONTAMINATOR (my suites' connector lifetime), not the VICTIM (connector_test's assertions). No production change; the production fence + eval are correct (they always were -- the bug was a test leaking a connection into a sibling's global-state window).

VERIFY (in progress): a 50-iter sequential-seed mini-loop (the Director's loop seeds 1..N) + the full suite no-regression. Then the Director re-runs the full ≥100 as the gate.

### L-14 — REMEDIATE verified (Mars-1's pre-standdown numbers; the Director owns the AUTHORITATIVE machine-owned ≥100): the fence+leak fix holds across every mini-loop run

Files edited (test-isolation ONLY, no production): events_integration_test.exs + locks_stalled_test.exs + jobs_extend_test.exs -- each on_exit now stop_conn(conn) (a guarded GenServer.stop, catch :exit -> :ok) BEFORE purge, bounding the setup connector's lifetime to the test. connector_test.exs NOT touched (its @fence_db 15 isolation is Mars-2's prior edit; the minimal+correct fix bounds the contaminator, not the victim).

Mars-1's verification BEFORE standing down (the team-lead then STOPPED all Mars loops -- two concurrent loops forge false failures; the Director runs the AUTHORITATIVE solo machine-owned ≥100): 30-iter mini-loop (connector + all 6 watch suites) 30/30; 50-iter sequential-seed mini-loop (connector + 4 connector-starting watch suites) 50/50; FULL suite 5x (seeds 100-500) all 201/0; a 30-iter FULL-suite mini-loop (the Director's exact `mix test --include valkey` command) 30/30 -- ZERO version_fence, ZERO script_loads==1, ZERO backoff/schedule in those ~115 runs. compile --warnings-as-errors clean (0 warnings).

STATUS: Mars-1 STOPPED, idle, awaiting the Director's machine-owned ≥100 verdict. No further tests/loops, no file edits until the Director confirms. The fixes are coherent (3 sibling files, same stop_conn idiom). NOTE the L-8 pre-existing backoff/schedule conformance flake (the byte-frozen 6ms-margin scenario) is a SEPARATE, lower-probability (~1-2%) class from the now-fixed connector contamination -- it did not fire in Mars-1's runs but is not provably eliminated (INV1 forbids touching it); carried for emq.8.

### L-15

L-12b — STAGE-4 HARDEN FIX A (the A1 crash-drill cast/call race): a GenServer.cast not yet processed when a downstream wire read fires

ROOT (Director ≥100 loop, iter 35 seed 504810): the A1 crash-drill owner closure did Locks.track_job(lm, id, token) -- a GenServer.cast -- then immediately send(parent, :tracked); the parent then read PTTL on the :lock marker and asserted ttl > 0. Under max_cases:32 the cast could be UNPROCESSED (the handle_cast({:track_job,…}) marker SET not yet run) when the parent's PTTL fired -> PTTL returns -2 (no key) -> assert ttl > 0 fails. A cast gives NO delivery/processing guarantee to a later reader in another process.

FIX (test-only, locks_stalled_test.exs:225): a FIFO synchronization BARRIER -- insert `_ = Locks.is_tracked?(lm, id)` (a GenServer.call, lock_manager.ex:111-114) between the track_job cast and send(parent, :tracked). The BEAM mailbox is FIFO and a process's messages to one GenServer are delivered in send order, so the call is dispatched AFTER the cast's handle_cast completes; the call blocks until its reply, so when is_tracked? returns the marker SET has landed -- the parent's PTTL read cannot race. One round-trip cost; the rest of the test byte-identical. VERIFY: seed 504810 + 0/1/42 each 13/0; the 15-iter sanity loop 15/15.

GENERAL: when a test casts to a GenServer then signals another process to observe the cast's wire effect, insert a sync call to the SAME GenServer between the cast and the signal -- the FIFO call is the barrier (no Process.sleep guess).

### L-16

L-13b — STAGE-4 HARDEN FIX B (the version-fence linked-exit propagation): a db-15 fencing connector re-fences on reconnect into a poisoned key and its {:stop, {:version_fence,…}} hits an untrapped process

ROOT (Director ≥100 loop, iter 5/73, ~1%): a db-15 fencing connector that booted against a CLEAN fence lingers; a sibling fence test then poisons {emq}:version on db-15; the lingering connector's TCP blips and on :reconnect (connector.ex:330-339) it RE-FENCES, hits the poison, and {:stop, {:version_fence,"echomq:0.0.1"}} propagates as a LINKED EXIT to a process that is NOT trapping exits -> the linked process dies -> a concurrent test fails. Compounded by fence_db_flush/0 cleaning a possibly-poisoned db with a FENCING Connector.start_link -- which itself re-fences and could die {:version_fence}, never FLUSHing (the anti-pattern the module docstring forbids: a fenced connector cannot reconnect through a broken fence to restore it).

FIX (test-only, connector_test.exs, two sub-fixes):
1. Moved Process.flag(:trap_exit, true) OUT of the mismatched-fence test body INTO the describe's setup (before helper = connect(database: @fence_db)). So the test process traps ANY db-15 connector's version_fence EXIT for the WHOLE fence-test lifecycle -- the stop is delivered as a {:EXIT,…} message, not a failing exit signal -- not just from the in-body assertion onward (when the connector that blips may already be live).
2. Rewrote fence_db_flush/0 to clean db-15 with a RAW redis-cli: System.cmd("redis-cli", ["-p","6390","-n","15","flushdb"], stderr_to_stdout: true) -- never a fencing Connector. A raw FLUSHDB cannot be fenced (the docstring's canonical restore), so it cleans db-15 after EVERY fence test even if a body crashed before its in-body DEL. The setup's existing on_exit(fn -> fence_db_flush() end) now reliably empties db-15.

VERIFY: connector_test seeds 0/1/42/73 each 13/0; db-15 `keys '*'` EMPTY after the runs AND after the 15-iter sanity loop. The poison can no longer leak past a fence test, and any reconnect-into-poison EXIT is trapped.

GENERAL: a test that mutates GLOBAL fenced state (the version key) must (a) trap exits in setup for the whole describe (any fencing connection can re-fence on reconnect), and (b) restore/clean that state with a NON-fencing path (raw redis-cli), never a fencing client that the very poison it cleans would refuse.

### L-17 — EVALUATOR: distinguish a STALE residue fossil from a LIVE leak by delete-and-rerun, not by dbsize-flat alone

THE FINDING (Apollo Stage 4). The Director handed a candidate: the >=100 loop left 3 residual keys from one queue (emq:{emq23.lst19266}:{dead,job,metrics:failed}); dbsize was FLAT (13->13) so it read as BOUNDED/non-accumulating. Assessed deeper: dbsize-flat is necessary but NOT sufficient to call it a CURRENT test-hygiene gap — it is equally consistent with a STALE fossil from a pre-hardening run that no later VM overwrote. The decisive probe: DELETE the trio, re-run the (hardened) suite, observe whether it REAPPEARS. It did NOT (0 keys), and a full 73-test watch-suite run + a 15-iter scoped loop both left 0 emq23.* keys. So it was a fossil from a pre-L-6 (pre-disposable-purge) run, not a live leak; the right action was to clean it (manual DEL), NOT a code fix against an already-correct on_exit.

WHY dbsize-flat fooled the surface read: queue names use System.unique_integer (resets per VM), so a fossil at lst19266 is only overwritten-and-cleaned if a later VM's unique_integer sequence lands on exactly 19266 — which it rarely does, so the fossil persists at a FLAT count (overwrite-or-ignore, never accumulate) indefinitely. A flat count thus cannot distinguish "a current test re-creates+leaves it each run" from "a one-time fossil nothing touches." Only delete-and-rerun separates them.

GENERAL (folds into echo-mq-evaluator craft): when assessing a residual-key / leaked-state finding, the gate is delete-the-residue + re-run-the-suite, not dbsize-flat. A residue that REAPPEARS is a live test-hygiene gap (fix the on_exit); a residue that does NOT is a stale fossil (clean it, no code change). Report which, with the empirical delete-rerun evidence — never rubber-stamp "bounded, dbsize flat" (misses a fossil) nor file a spurious on_exit remediation against correct code.

## {emq-2-3-report} Report

### Y-1 — Stage 1 (Mars-1) BUILD COMPLETE: the watch plane built + the Stage-1 gate met

THE FOUR D1 DECISIONS (ruled, each citing the design §, ≥2 steelmanned alternatives): D-1 the event surface (channel emq:{q}:events confirmed — the inherited emq.2.2 D-5 seam; host-side publish/3 after the verdict; cjson {event,job,...} payload; alt V-1), D-2 the telemetry tree ([:emq,...] re-root; function_exported zero-cost guard; alt V-2), D-3 the lock plane (Jobs.extend_lock/5 re-scores the active member under TIME, EMQSTALE on a stale token + Jobs.extend_locks/4 batch; the opt-in :transient EchoMQ.Locks process writes the :lock marker; alt V-3 — active-score lease vs the v1 :lock string), D-4 the stalled mechanism (a `stalled` field on the row; EchoMQ.Stalled sweep over [active,pending,dead] under TIME; alt V-4).

DELIVERABLES BUILT (DAG order D4->D5->D6->D2->D3->D7->D8):
- D4 jobs.ex: @extend_lock + @extend_locks inline Script.new/2; extend_lock/5 -> :ok|{:error,:stale}|{:error,:gone}; extend_locks/4 -> {:ok, failed_ids}. Re-scores the active member under server TIME; EMQSTALE reused (NO new wire class); declared keys [active, job_key]; batch derives per-job keys from the declared base root (A-1), NO cmsgpack.
- D5 lock_manager.ex (EchoMQ.Locks) + lock_manager/core.ex (EchoMQ.Locks.Core): opt-in :transient (Pump shape) — start_link/1, track_job/3, untrack_job/2, get_active_job_count/1, get_tracked_job_ids/1, is_tracked?/2, stop/1. Extends on a timer via extend_locks/4; track writes emq:{q}:job:<id>:lock (-> emq.2.2 remove_job EMQLOCK live), untrack DELs it; pure core for the extend interval (doctested).
- D6 stalled_checker.ex (EchoMQ.Stalled): check/2 + job_stalled?/4 + @sweep_stalled inline script over [active,pending,dead] under TIME; recover below max_stalled, dead-letter at/above (last_error='stalled'); group-aware recover arm; optional :transient periodic process. Beyond reap/2, not a replacement.
- D2 events.ex (EchoMQ.Events): per-queue subscribe/2 unsubscribe/2 close/1 over the connector pub/sub seam + handle_event/3 @callback + __using__; host-side publish/3 on emq:{q}:events (cjson, by substring -- the as-built convention, no JSON dep); event_name/1 (to_existing_atom or :unknown); dispatches both subscriber pids ({:emq_event,...}) and a handler module; auto-resubscribe via the emq.1 set. NO new transport, NO SSUBSCRIBE.
- D3 telemetry.ex (EchoMQ.Meter): attach/4, attach_many/4, emit/3 (atom+list), span/3 + job_added/4 job_started/4 job_completed/5 job_failed/6 job_retried/5 worker_started/3 worker_stopped/3 rate_limit_hit/2, re-rooted [:emq,...]; every emit guarded function_exported(:telemetry,:execute,3) (zero-cost when absent). The surface fires; the CONTRACT is emq.8 (INV6).
- D7 cancellation_token.ex (EchoMQ.Cancel + EchoMQ.Cancel.Cancelled): new/0, cancel/3 ({:emq_cancel,token,reason}), check/1 (receive after 0), check!/1 (raises typed Cancelled). Host-side, NO wire identity. The distributed cancel is emq.6 (INV7).
- D8 conformance.ex: +5 scenarios (lock_extend, stalled, events, telemetry, cancel) registered on 32 -> 37; the telemetry scenario is TWO-MODE (fires when :telemetry present, safe no-op when absent -- L-2). BOTH pins re-pinned to 37: conformance_scenarios_test @run_order (37) + conformance_run_test {:ok, 37}.

REALIZATION-OVER-LITERAL (L-1, flagged): the v1 watch module NAMES (EchoMQ.LockManager/StalledChecker/Telemetry/CancellationToken/QueueEvents) COLLIDE with the frozen apps/echomq reference on one code path (proven: a v1 EchoMQ.LockManager shadowed mine at runtime, KeyError). The new bus modules are collision-free: EchoMQ.Events (safe as-is), EchoMQ.Meter, EchoMQ.Locks(+.Core), EchoMQ.Stalled, EchoMQ.Cancel. The public CAPABILITY is the v1 surface's; only the defmodule changed (file names kept). Venus folds the chosen names into the triad + surface map.

STAGE-1 GATE: per-app compile --warnings-as-errors CLEAN (echo_mq force-rebuild 18 files, 0 warnings; echo_wire untouched compiles clean). CONFORMANCE 37/37 against Valkey 6390. echo_mq suite 4 doctests + 141 tests, 0 failures. D4 wire smoke (extend survives reap; EMQSTALE on stale; batch returns the stale id), D5 process smoke (the lock plane extends a lease once; :lock marker -> EMQLOCK; untrack releases), D6 smoke (recover below / dead at the threshold), D2 smoke (subscriber receives a host-side + the inherited Lua event), D3 smoke (attach/emit/span fire under the umbrella), D7 smoke (the token + typed raise) -- all PASS. Module-load smoke: all 7 modules load. BOUNDARY: every change inside echo/apps/echo_mq (4 modified, 6 new); apps/echomq + echo_wire + mix.lock UNTOUCHED; no third app. INV1 (EMQSTALE reused, no new class), INV2 (no SSUBSCRIBE/new transport), INV4 (declared keys, no priv/) hold by grep.

CARRIED TO STAGE 3 (Mars-2, per the runbook): the ≥100 determinism loop over the process suites (Locks + Stalled); the v1 watch test corpus adoption (~2000 LoC, re-derived against the v2 surface — the Operator's "tests v1 adopted and verified"); the watch-verdict drills as standing per-app suites; the two-mode telemetry scenario noted for Venus. No git run (LAW-1a/LAW-4 -- left in the tree).

### Y-2 — Stage 2 (Director solo review): FAITHFUL + inside the boundary; advance to Mars-2 with one substantive REMEDIATE

An INDEPENDENT fresh-gate pass (not from Mars-1's report): re-read the high-risk surfaces, re-ran the gate on Valkey 6390, grounded the A-1 question against the shipped precedent, probed the headline invariants, and ran a net-zero mutation spot-check.

### Y-3 — Stage 3 (Mars-1) the v1 watch test corpus COVERAGE TABLE (the Operator's "tests v1 adopted and verified")

Per v1 reference suite (read-only echo/apps/echomq/test/): how many tests ADOPTED (re-derived to the v2 surface) / DEFERRED to a family rung (+ reason). Honest -- a deferral is a recorded boundary fact (INV6/INV7), not a gap. The new v2 suites live in echo/apps/echo_mq/test/ (NEVER edited apps/echomq/test).

| v1 reference suite (count) | v2 adopted suite | adopted | deferred | the deferral |
|---|---|---|---|---|
| cancellation_token_test.exs (19) | cancel_test.exs (19) | 19 (full) | 0 | -- the whole worker-side token surface re-derived: {:cancel,…}->{:emq_cancel,…}, RuntimeError->the typed EchoMQ.Cancel.Cancelled |
| worker_cancellation_test.exs (9) | cancel_test.exs (the patterns) | the worker-side token + cooperative-check patterns | the WORKER-abstraction wiring (processor-receives-token-2nd-arg) + cancel_job/cancel_all_jobs | the v2 bus has NO Worker abstraction; the DISTRIBUTED cancel is emq.6 (INV7) |
| telemetry_test.exs (10) | meter_test.exs (11) | 10 + 1 ADDED (the zero-cost-guard test v1 lacked) | 0 | -- emit(atom+list)/attach/attach_many/span/lifecycle, [:echomq]->[:emq], the two-mode guard (L-2) |
| telemetry/behaviour_test.exs (9) | -- | 0 | 9 | the telemetry CONTRACT/behaviour (start_span/end_span/serialize_context/record_exception) = emq.8 (INV6, the two-layer split) |
| telemetry/opentelemetry_test.exs (25) | -- | 0 | 25 | the OpenTelemetry adapter = the telemetry contract layer = emq.8 (INV6) |
| queue_events_integration_test.exs (12) | events_integration_test.exs (8) | 8 (the capabilities) | the v1 waiting/active/delayed per-name worker-emit tests | those names are v1-WORKER-lifecycle artifacts the v2 bus does not reproduce; the v2 events are host-side published (completed/failed/scheduled/progress/stalled) -- the CAPABILITY (subscribe/dispatch/multi-subscriber/handler/reconnect) is fully covered |
| worker_integration_test.exs lock/extend cases (~33 lock-related) | jobs_extend_test.exs (9, Mars-2) + locks_stalled_test.exs D5+D6 (13, Mars-1) | the extend_lock/extend_locks verbs + the Locks plane + the Stalled sweep, re-derived to the active-score lease + server TIME + the INV5 guards | the v1 :lock-STRING-as-lease mechanism, the caller clock, the 9-key LIST sweep, the lock-renewal-failed CALLBACK (worker abstraction) | the v2 lease IS the active score (re-scored); the v1 mechanism is structurally replaced, never lifted; the worker-abstraction callback is the v2-absent Worker (worker-side only -- INV7) |

TOTALS: ADOPTED -- cancel 19, meter 11 (+1 new), events 8, jobs_extend 9 (Mars-2), locks_stalled 13 (Mars-1) = the watch surface fully re-derived + verified green. DEFERRED -- telemetry behaviour 9 + OTel 25 (= the telemetry contract, emq.8) + the worker-abstraction/distributed-cancel parts of worker_cancellation/worker_integration (emq.6). NO fake-100: the deferrals are the family boundary (ADR-2/INV6/INV7), recorded with their owning rung. The adopted suites prove the parity is real; emq.6/emq.8 add their contract/distributed proofs over them.

### Y-4 — Stage 3 (Mars-1 SOLO) COMPLETE: the harden + v1-corpus-adoption + drills done; the ≥100 loop handed to the Director

(The Director resolved the Mars-1/Mars-2 collision -- Mars-1 owns Stage 3 solo, Mars-2 was a redundant recovery spawn, shut down; the Director independently re-confirmed the green gate + OWNS the ≥100 loop, run on the stable session. Mars-1's loop + Monitor are STOPPED so the machine is uncontended. The convergence with Mars-2's pre-shutdown work was clean + strengthening -- see L-6/L-7.)

### Y-5 — Stage 3 (Mars-1 SOLO) CONSOLIDATED REPORT (the "Y-3" the team-lead requested; paperwork-only close, the Director owns the authoritative machine-owned ≥100). Mars-1 STOPPED all loops/tests permanently per the final division of labor.

== THE FIVE WATCH SUITES (the v1-corpus adoption, all green when last run) ==
| suite | tests | deliverable | what it covers |
|---|---|---|---|
| cancel_test.exs | 19 | D7 | the worker-side cooperative token: new/cancel/check/check!, the cooperative patterns, concurrency, isolation, scalability (the full v1 cancellation_token_test re-derived) |
| meter_test.exs | 11 | D3 | attach/4, attach_many/4, emit/3 (atom+list), span/3 (+exception), the lifecycle helpers re-rooted [:emq,…]; the TWO-MODE guard (fires when :telemetry present, safe no-op when absent) |
| jobs_extend_test.exs | 9 | D4 | extend_lock/5 (extend-survives-reap, the re-scores-never-a-:lock-string proof, no-re-score-on-stale) + extend_locks/4 (empty/whole-live-batch edges) + the INV5 ill-formed-id guards on BOTH verbs (originally Mars-2's additive depth, folded in) |
| events_integration_test.exs | 8 | D2 | subscribe/unsubscribe/close + lifecycle delivery over the connector pub/sub seam; the inherited Lua progress + host-side publish; multiple subscribers; the handler module; the unsubscribe lifecycle; channel=queue_key |
| locks_stalled_test.exs | 13 | D5+D6 | the Locks plane (track/untrack + the read trio + the direct-drive beat + :lock→EMQLOCK + consumer-without-the-plane + the A1 crash drill) AND the Stalled sweep (recover-below/dead-at + server TIME + job_stalled?/4 + beyond-the-reaper) |

== THE v1 COVERAGE TABLE (adopted / re-derived / deferred, per v1 reference suite) ==
| v1 suite (count) | adopted/re-derived | deferred | the deferral + reason |
|---|---|---|---|
| cancellation_token_test.exs (19) | 19 -> cancel_test.exs (full; {:cancel,…}→{:emq_cancel,…}, RuntimeError→the typed Cancel.Cancelled) | 0 | — |
| worker_cancellation_test.exs (9) | the worker-side token + cooperative-check patterns (folded into cancel_test) | the WORKER-abstraction wiring (processor-2nd-arg, cancel_job/cancel_all_jobs) | the v2 bus has NO Worker abstraction; the DISTRIBUTED cancel → emq.6 (INV7) |
| telemetry_test.exs (10) | 10 + 1 ADDED (a zero-cost-guard test the v1 lacked) -> meter_test.exs ([:echomq]→[:emq], the two-mode guard) | 0 | — |
| telemetry/behaviour_test.exs (9) | 0 | 9 | the telemetry CONTRACT/behaviour (start_span/end_span/serialize_context/record_exception) → emq.8 (INV6, the two-layer split) |
| telemetry/opentelemetry_test.exs (25) | 0 | 25 | the OpenTelemetry adapter = the telemetry contract layer → emq.8 (INV6) |
| queue_events_integration_test.exs (12) | 8 -> events_integration_test.exs (the capabilities) | the v1 waiting/active/delayed per-name worker-emit tests | those names are v1-WORKER-lifecycle artifacts the v2 bus does not reproduce; the v2 events are host-side published (completed/failed/scheduled/progress/stalled) — the CAPABILITY is fully covered |
| worker_integration_test.exs (the lock/extend cases) | extend_lock/extend_locks + the Locks plane + the Stalled sweep, re-derived to the active-score lease + server TIME + the INV5 guards (jobs_extend_test 9 + locks_stalled_test 13) | the v1 :lock-STRING-as-lease mechanism, the caller clock, the 9-key LIST sweep, the lock-renewal-failed CALLBACK | the v2 lease IS the active score (re-scored); the v1 mechanism structurally replaced, never lifted; the callback is the v2-absent Worker abstraction (worker-side only — INV7) |
NO fake-100: every deferral is a recorded family-boundary fact (ADR-2/INV6/INV7) with its owning rung (emq.6 / emq.8).

== THE A1 CRASH-DRILL RESULT (L-4 — locks_stalled_test.exs:178-226, CONFIRMED by reading) ==
track a job → the :lock marker has a PX TTL (asserted 0 < ttl ≤ 200) + remove_job → {:error,:locked} (held); KILL the isolated owner (spawn_monitor, no link-cascade) → the beat stops; sleep past the lease(40ms)+marker(200ms) → GET marker → nil, PTTL → -2 (self-expired); reap recovers the lapsed lease; remove_job → :ok (no stale EMQLOCK). capture_log wraps the deliberate kill. PASS (green in every run; the production fix = lock_manager.ex SET…PX + the beat PEXPIRE refresh + core marker_ttl_ms/1 — the sole production change this stage).

== THE FENCE-FLAKE FIX (the determinism-gate RED — L-9/L-10) ==
The Director's ≥100 loop failed iter 5 with 3x {:version_fence,"echomq:0.0.1"} (+ the related script_loads==1 and a Stalled-TIME flake — all ONE shared-global-state class). ROOT: my watch suites' setup connectors LINGERED past each test and reconnected into connector_test's global-state window. FIX (test-isolation ONLY, no production): events_integration + locks_stalled + jobs_extend on_exit now stop_conn(conn) (a guarded GenServer.stop) before purge, bounding each connector's lifetime to the test. connector_test.exs was NOT touched by Mars-1 (its @fence_db 15 logical-DB isolation is Mars-2's prior edit — also test-only). The minimal+correct fix bounds the CONTAMINATOR, not the victim. connector_test ALONE is 30/30; the production fence + eval are correct. Mars-1's pre-standdown verification: 30/30 + 50/50 mini-loops + 5×201/0 + a 30/30 FULL-suite loop (the Director's exact command) — zero version_fence/script_loads/backoff across ~115 runs.

== CONFORMANCE 37/37 + BOTH PINS ==
EchoMQ.Conformance.run/2 → {:ok, 37}: the 32 prior scenarios BYTE-UNCHANGED (git-verified — only a trailing comma on reprocess_job + moduledoc/alias text) + the 5 new watch scenarios (lock_extend, stalled, events, telemetry, cancel). Both pins re-pinned: conformance_scenarios_test @run_order (37 names) + conformance_run_test {:ok, 37}.

== THE BOUNDARY GREP ==
Every emq.2.3 change inside echo/apps/echo_mq: M conformance.ex (+178) + jobs.ex (+100) + conformance_run_test + conformance_scenarios_test + connector_test (test-only fence isolation); NEW events.ex + telemetry.ex + lock_manager.ex(+core) + stalled_checker.ex + cancellation_token.ex + the 5 test suites. apps/echomq UNTOUCHED (the read-only v1 reference). echo_wire UNTOUCHED. echo/mix.lock UNTOUCHED (no dep added; :telemetry a guarded optional use). No third app. The mercury_live_admin/** in git status is Operator out-of-band (the runbook EXCLUDE list) — never in any emq.2.3 commit.

== CARRIED (for the Director's loop verdict + Apollo/Venus) ==
L-8: the FULL Conformance.run/2 carries a SEPARATE pre-existing ~1-2% flake — apply_scenario(:backoff)/(:schedule) use a ~6ms sleep margin vs the server clock (delay={:exponential,1,10}); under load promote returns 0. It is byte-frozen by INV1 (the 32 prior) so emq.2.3 CANNOT fix it; a single run is 37/37. NOT the connector contamination (that is fixed). A carried follow-up for a rung allowed to revise the founding set (emq.8). If the Director's ≥100 fails ONLY on {:error,[:backoff/schedule]}, that is this pre-existing flake, not the fix.

STATUS: Mars-1 STOPPED all loops/tests/compiles permanently. Y-3 (this report) done. Idle, awaiting the Director's machine-owned ≥100 verdict + the fold to Apollo (Stage 4).

### Y-6 — Apollo Stage 4 (evaluator): BUILD-GRADE. The watch plane is ship-ready.

VERDICT: BUILD-GRADE — no BLOCKER. Every emq.2.3 promise is MATCH or [RECONCILE]-DEFERRED; the gate reproduces GREEN independently; 5/5 mutation kill-rate net-zero; 3 attacks held + 2 un-prompted probes held; the one handed finding resolves as a benign stale fossil (now cleaned), not a live gap.

== POST-BUILD DELTA TABLE (promise -> as-built file:line -> verdict) ==
- D1 design-make gate (D-1..D-4 ledger) -> decisions recorded with >=2 steelmanned alts each (V-1..V-4) -> MATCH
- D2 EchoMQ.Events -> events.ex:106 channel/1, :117 publish/5, :134 event_name/1 (to_existing_atom, never mints), :205 handle_info dispatch -> MATCH
- D3 EchoMQ.Telemetry (Meter) -> telemetry.ex:37 loaded? guard, :45 attach, :79 emit, span/3 -> MATCH
- D4 Jobs.extend_lock/5 -> jobs.ex:646 + @extend_lock:569 (TIME re-score active, EMQSTALE, -1->:gone); extend_locks/4 jobs.ex:671 + @extend_locks:581 -> MATCH
- D5 EchoMQ.Locks (LockManager) -> lock_manager.ex:147 track_job SET..PX marker, the read trio, beat extend, opt-in :transient -> MATCH
- D6 EchoMQ.Stalled -> stalled_checker.ex:50 @sweep_stalled (KEYS active/pending/dead, server TIME, recover<threshold / dead-letter>=, group-aware), :106 check/3, :139 job_stalled?/4 -> MATCH
- D7 EchoMQ.Cancel -> cancellation_token.ex new/0 cancel/3 check/1 check!/1 (host-side, no wire id) -> MATCH
- D8 conformance +5 (lock_extend/stalled/events/telemetry/cancel) conformance.ex:59-64; both pins 37 -> MATCH
- INV1..INV8 -> all hold (see below)
- DEFERRED [RECONCILE]: telemetry CONTRACT/OTel -> emq.8 (INV6); worker-abstraction + distributed cancel -> emq.6 (INV7); durable replayable stream -> emq3.2. Recorded honestly, NOT faked.

== GATE RE-RUN (independent, machine-owned) ==
- Toolchain re-probe (NOT hardcoded): asdf erlang 28.5.0.1, elixir 1.18.4; redis-cli -p 6390 ping -> PONG; dbsize 13 at start.
- TMPDIR=/tmp mix compile --warnings-as-errors (echo_mq) -> CLEAN, 0 warnings.
- TMPDIR=/tmp mix test --include valkey (echo_mq) -> 4 doctests, 201 tests, 0 failures (the `** (stop) killed` is the A1 crash-drill deliberate kill, capture_log-wrapped).
- Conformance.run/2 -> {:ok, 37}; printed CONF lock_extend/stalled/events/telemetry/cancel ok.
- INV1 byte-unchanged GIT-VERIFIED: git diff HEAD on conformance.ex shows the ONLY prior-32 edits are moduledoc text + the alias line + a trailing comma appended to reprocess_job (prior-last, now mid-list). ZERO prior scenario verdict-body touched. The 5 new scenarios are purely additive after reprocess_job. Both pins (@run_order 37 + run/2 {:ok,37}) match scenarios/0.
- SCOPED determinism loop (15 iters, seeds 1..15) over the 6 process suites (locks_stalled+cancel+meter+events_integration+jobs_extend+connector): PASS=15 FAIL=0, residue 0, dbsize flat 12. (The Director owns the authoritative >=100 GREEN; a third full loop is waste per the charter — scoped confirm + 0-residue invariant is the independent check.)

== THE DECLARED-KEYS LINT (the F-1 class — the critical echo_mq probe) ==
| script | declared KEYS[] | derived (in-script) | slot-pin | verdict |
| @extend_lock (jobs.ex:569) | [1]=active, [2]=job_key | none | KEYS[1]/[2] both emq:{q}: braced | COMPLIANT |
| @extend_locks (jobs.ex:581) | [1]=active | base=ARGV[1]=queue_key(q,"")=emq:{q}: ; jk=base..'job:'..id | KEYS[1]=emq:{q}:active pins {q}; the ARGV base carries the SAME {q} literal brace -> same slot | COMPLIANT |
| @sweep_stalled (stalled_checker.ex:50) | [1]=active [2]=pending [3]=dead | base=ARGV[1]=emq:{q}: ; jk, gactive, g:<grp>:pending, paused, glimit, ring, wake, metrics:failed — ALL base.. | 3 real declared KEYS pin {q}; every derived key carries the same {q} brace -> same slot | COMPLIANT |
Verified Keyspace.queue_key(q,"") = "emq:{q}:" (keyspace.ex:14) — the brace IS in the base. slot/1 + hashtag/1 (keyspace.ex:44-54) compute the slot from the substring inside {...}, so a declared KEYS entry + an ARGV base sharing the identical {q} literal are provably co-slotted. This is the established jobs.ex/lanes.ex convention (the v1-mechanism-is-structurally-inexpressible property holds: keys are NOT rooted in data values). NO F-1 finding.

== ATTACKS THAT HELD (live, against Valkey 6390, independent probe) ==
1. INV3 lease (the headline): claim(lease 50ms) -> extend_lock to +60s (active score 610292 -> 670245) -> sleep 120ms PAST original deadline -> reap reclaimed 0 -> id STILL in active, state=active, AND `:lock` string key EXISTS=0 -> proves the lease IS the active score (re-scored), NEVER a separate :lock string. HELD.
2. Stale token: extend_lock(token 99) -> {:error,:stale} (EMQSTALE) AND active score UNCHANGED (no re-score on a stale token — the fence gates the write). HELD.
3. Gone row: extend_lock(never-enqueued id) -> {:error,:gone}. HELD.
+ INV2 grep: only SSUBSCRIBE hit is the events.ex moduledoc disclaimer; events use Connector.subscribe/2 + ["PUBLISH",chan,payload] — plain RESP3 pub/sub, no SSUBSCRIBE/SPUBLISH/sharding.
+ INV1 grep: the only wire classes in the new code are EMQSTALE (extend fence) + EMQLOCK (the inherited remove_job guard the lock plane activates) — both pre-existing, no new class.
+ Catch-all: the error map is `{:error,{:server,"EMQSTALE"<>_}} -> {:error,:stale}` then `other -> other` — the FORWARD-COMPATIBLE pass-through the wire-class seam requires (an unrecognized EMQ* passes untyped), explicit -1->:gone / 1->:ok before it. Correct, not a leaking catch-all.
+ INV6/INV7 grep: the only distributed/cancel_job/OTel mentions are moduledoc text DEFERRING them to emq.6/emq.8. No OTel adapter, no Worker abstraction, no distributed surface leaked.

== MUTATION KILL-RATE: 5/5, NET-ZERO ==
(md5 baselines pre/post each; tracked files also git-diff-verified; full git diff --stat restored to the start-of-session baseline.)
1. @extend_lock token fence ~= -> == (jobs.ex, tracked) -> jobs_extend_test 3 failures (live token wrongly refused). KILLED. Reverted md5 ac086981.
2. @sweep_stalled threshold >= -> > (stalled_checker.ex) -> locks_stalled_test 1 failure (at-threshold recovers not dead). KILLED. Reverted md5 7aee8ee5.
3. telemetry loaded? -> false (telemetry.ex) -> meter_test 10 failures (handler never fires). KILLED. Reverted md5 9b0d0327. [NOTE the first try loaded?->true was a no-op kill BECAUSE :telemetry IS loaded in the per-app context here — see the finding below.]
4. drop marker PX TTL (lock_manager.ex, regress L-4) -> locks_stalled_test A1 crash drill 1 failure (marker never self-expires, PTTL!=-2). KILLED. Reverted md5 c7b69f93.
5. drop events subscriber send (events.ex) -> events_integration_test 6 failures (subscriber mailbox empty). KILLED. Reverted md5 941b706a.
All 5 files md5-identical to baseline post-revert; git diff --stat == the original (jobs/conformance/2 pins/connector_test). Net-zero confirmed.

== THE HANDED FINDING (the 3 residual keys) — RESOLVED as a benign STALE FOSSIL, not a live gap ==
Reproduced the EXACT trio the Director handed: emq:{emq23.lst19266}:{dead, job:JOB0NxWI0CV8dc, metrics:failed} (a dead-lettered job's morgue zset + row + failed-counter — CORRECT durable dead-letter state, not a leak). Three findings settle it:
(a) The conformance purge pattern (KEYS emq:{q}:* -> DEL) catches all 3 (after DEL: 0). And locks_stalled_test's purge/2 (line 72) uses the IDENTICAL pattern.
(b) DECISIVE: I deleted the trio + re-ran the (hardened) suite -> the keys did NOT reappear (0). So the residue was a STALE leftover from a PRE-hardening (pre-L-6) run that no later VM overwrote-and-cleaned (its unique_integer never landed on exactly 19266 again). The "still 3 after runs 1/2/3" earlier was those runs NEITHER touching NOR cleaning the fossil.
(c) A full 73-test watch-suite run (the exact 6 ≥100-loop suites) + the 15-iter scoped loop both leave 0 emq23.* keys. The current hardened suites accumulate NOTHING.
ASSESSMENT: not a test-cleanliness gap in the current code, not a production defect. A benign stale artifact — I cleaned it (dbsize 15->12). No fix needed. Even weaker than the Director's "bounded note": it does not reproduce.

== MY OWN FINDINGS (un-prompted, beyond the brief) ==
F-A (the signature un-prompted probe — 2 untested behaviors, both HELD): (1) extend_locks PARTIAL batch [live,stale,gone] -> the live token extended (survives reap), BOTH stale+gone reported in `failed`, the stale one reaped (the interleaved id/token ARGV loop is correct). (2) @sweep_stalled GROUP-AWARE recover (the most complex untested branch, lines 75-86) -> a grouped stalled job recovers into its LANE (emq:{q}:g:<grp>:pending), NOT the flat pending set. Both HELD. These are real adversarial probes the standing suites do not cover.
F-B (an honest-coverage observation for Venus, NOT a blocker): :telemetry IS loaded in echo_mq's per-app `mix test` context on THIS machine (`function_exported(:telemetry,:execute,3) -> true`, transitively in _build), so the L-2 two-mode telemetry conformance/meter scenarios run their PRESENT branch (the meaningful one — the surface really fires), not the absent branch. The ABSENT (zero-cost no-op) branch is only exercised on a clean machine without :telemetry in _build. The two-mode guard is correct either way; the coverage note is just that "which mode runs" is environment-dependent — a deployment that truly lacks :telemetry exercises the other branch. Worth a one-line note in the triad's telemetry-scenario description (Venus, Stage 5).

== SPEC-SYNC NEEDED (for Venus Stage 5, flagged not applied) ==
The triad (emq.2.3.{md,stories.md}) still says "18 prior conformance scenarios byte-unchanged" throughout (INV1/D8/US8/as-built floor) — STALE; the as-built floor is 32 prior -> 37 total (the lag-1 drift, BOOTSTRAP FINDING 1). And the module names drifted by the L-1 realization: the triad/surface-map name EchoMQ.Telemetry/LockManager/StalledChecker/CancellationToken but the as-built collision-free names are EchoMQ.Meter/Locks(+.Core)/Stalled/Cancel (Events kept). Venus syncs the body to the as-built surface at Stage 5 (record what shipped).

== OPEN SHIP QUESTION ==
No open Operator decision. The G1 rate-gate fork is an emq.2.4 concern (Arm 2 ruled), not emq.2.3. The L-8 backoff/schedule conformance flake is a DOCUMENTED pre-existing carry byte-frozen by INV1 -> emq.8 (a single Conformance.run is 37/37; I did NOT flag it as new). No treatment choice or residual-risk acceptance is pending for emq.2.3.

== BOUNDARY (final audit) ==
My evaluation left the rung touch-set byte-identical to the start (5 mutations all reverted net-zero). apps/echomq (frozen v1) UNTOUCHED; echo_wire UNTOUCHED (READ-only seam); echo/mix.lock UNTOUCHED (no :telemetry dep edge). The 5 new production modules present + untracked (awaiting the Director's LAW-4 commit). No agent git run.

VERDICT: BUILD-GRADE. emq.2.3 is ship-ready. The Director ratifies + commits.

### Y-7 — Venus Stage 5: triad reconcile (lag-1 → as-built) — emq.2.3 the watch plane. VERDICT: BUILD-GRADE (triad now matches the as-built surface). Touched ONLY the 3 triad files (emq.2.3.{md,stories.md,llms.md}); zero code/test/git.

DELTA CLASSES SYNCED:
(A) Module renames — 4 collision-rename pairs folded THROUGHOUT (directional, not blind replace-all): EchoMQ.Telemetry→EchoMQ.Meter, EchoMQ.LockManager→EchoMQ.Locks, EchoMQ.StalledChecker→EchoMQ.Stalled, EchoMQ.CancellationToken→EchoMQ.Cancel (EchoMQ.Events already matched). KEY DISTINCTION I enforced: the SAME surface words name TWO different referents — the frozen v1 source (apps/echomq/*.ex, kept) vs the echo_mq build target (renamed). I PRESERVED every v1-capability-reference citation (Goal para md:21-29; stories preamble; llms §References item 4 — those cite the real frozen modules) and RENAMED only build-target occurrences, rendering the capability labels as "the v1 EchoMQ.LockManager capability, built as EchoMQ.Locks" so both referents stay honest. A naive sed would have corrupted the v1 citations (apps/echomq has no EchoMQ.Meter).
(B) Conformance floor 18→37 — every live "18" re-pinned to "32 prior (14 emq.0→18 emq.1→24 emq.2.1→32 emq.2.2) + 5 watch = 37". Verified against live conformance.ex (moduledoc "thirty-seven"), conformance_run_test.exs {:ok,37} (:37), conformance_scenarios_test.exs @run_order 37 names (:56-57). Floor-ladder "18" (the emq.1 milestone) correctly retained; only LIVE-count 18s changed. Sites: md INV1/D8/DoD, stories US8, llms §Ref/R2/R8/DAG/AS-8/prompt.
(C) F-B telemetry note — added to md D8 telemetry-scenario clause: :telemetry IS loaded in echo_mq's per-app test (transitive umbrella dep, shared _build — verified telemetry.beam present in echo/_build/test), so the two-mode scenario runs its PRESENT branch (surface fires); the ABSENT branch is the safe no-op (proven, not exercised here).
(D) Two CARRIES to emq.2.4 recorded (new "## Carries forward" section in md body, NOT fixed) — both code-grounded by me: C1 file/module-name mismatch (files keep v1 concept names telemetry.ex/lock_manager.ex/stalled_checker.ex/cancellation_token.ex; modules are collision-free Meter/Locks/Stalled/Cancel — a closer-rung cleanliness debt); C2 two untested-but-verified behaviors — (i) extend_locks/4 partial-batch [live,stale,gone] (verified jobs.ex:581-601,671-686: live ZADD'd, stale+gone → {:ok, failed}); (ii) @sweep_stalled GROUP-AWARE recover (verified stalled_checker.ex:62,75-77: grouped job recovers into g:<grp>:pending lane + re-arms ring, NOT flat pending).

NEW DRIFT I FOUND (beyond the brief's flagged deltas):
- STATUS was "SPECCED, not built / authored this run, built a later run" across all 3 files — the rung is BUILT. Flipped to BUILT (md status block + When 5W + INV8 design-gate-honored phrasing; stories preamble) and checked all DoD boxes [x].
- ARITY drift: as-built EchoMQ.Stalled.check is /3 (conn,queue,opts), triad said check/2 in the build-target D6 + stories US5. Fixed both to check/3 (v1-source check/2@110 citations correctly retained).
- llms touch-list said "a pure lock_manager/core.ex IF the build mirrors the Pump split" — verified it DID: lock_manager/core.ex exists = EchoMQ.Locks.Core. Stated as-built. Also confirmed echo_wire.ex UNCHANGED (subscribe/unsubscribe delegates pre-existed at :26-27) and mix.lock unchanged (no dep added).
- Folded as-built specifics into the touch-list (extend_lock/5 + extend_locks/4 + the inline @attrs; Cancel.new = make_ref() + EchoMQ.Cancel.Cancelled; Events.publish/5 + channel/1 + event_name/1; the 5th 'cancel' scenario the prompt/AS-8 had omitted).

Coverage map intact (D1→US7 … D8→US8). Director commits.

## A — REMEDIATE (closed)
- A1 (L-3 -> L-4): the worker-side :lock presence marker now carries a PX TTL (Locks.Core.marker_ttl_ms/1, a small multiple of the lease, default 2x; doctested) SET on track_job and REFRESHED on each beat (extend_all PEXPIREs the still-held set). Restores the v1 lock-string's self-healing under the v2 lease/marker split: a live worker keeps both the lease (active score) AND the marker fresh; a crashed worker (no untrack) loses BOTH shortly after, so remove_job is not blocked on a stale EMQLOCK for an unbounded window. Production change: lock_manager.ex + lock_manager/core.ex ONLY (the sole production edit this stage).
- A2: the telemetry conformance scenario's two-mode contract is recorded (L-2; Venus folds the description into the triad).
- A3: capture_log wraps the deliberate-kill crash drill.

## A1 CRASH-DRILL RESULT (the Director's required L-4 verification -- locks_stalled_test.exs:178-226, CONFIRMED by re-reading)
The committed drill does exactly: track a job -> the marker has a PX TTL (asserted 0 < ttl <= 200) + remove_job -> {:error,:locked} (held); KILL the isolated owner (the linked plane dies, the beat stops -- spawn_monitor isolation, no link-cascade); sleep past the lease (40ms) + marker (200ms); assert GET marker -> nil + PTTL -> -2 (self-expired); reap recovers the lapsed lease; assert remove_job -> :ok (no stale EMQLOCK). GREEN (verified by run earlier this stage: locks_stalled_test 13/0).

## B — the watch-verdict DRILLS as committed per-app suites (5 verdicts, all green)
- lock-extend: an extended lease survives the reaper past its original deadline; a stale token -> EMQSTALE -> {:error,:stale}; the batch answers the ids it could not extend (jobs_extend_test 9 + locks_stalled_test).
- stalled: a past-threshold job recovered-below / dead-at; job_stalled?/4; group-aware recover; beyond-the-reaper (locks_stalled_test).
- events: a subscriber receives a lifecycle event over the connector pub/sub seam; the inherited Lua progress + host-side publish both deliver; multiple subscribers; the handler module; unsubscribe-lifecycle (events_integration_test 8).
- telemetry: the present-mode fire AND the absent-mode safe no-op -- both real verdicts (meter_test 11, the two-mode guard).
- cancel: cancelled -> cancelled + check! raises typed; un-cancelled -> ok (cancel_test 19).
- the lock plane: extends a tracked job's lease; untracks on completion (no double-retire); the read trio; a consumer WITHOUT the plane is the unchanged v2 worker (locks_stalled_test).

## C — the v1 test corpus ADOPTION + the coverage table
See Y-3 for the full per-suite table. SUMMARY: ADOPTED -> cancel 19, meter 11 (+1 zero-cost test the v1 lacked), events 8, jobs_extend 9 (additive D4 depth + the INV5 ill-formed-id guards), locks_stalled 13 (D5+D6). DEFERRED (recorded with the owning rung) -> telemetry/behaviour 9 + telemetry/opentelemetry 25 = the telemetry CONTRACT -> emq.8 (INV6, the two-layer split); the worker-abstraction + distributed-cancel parts of worker_cancellation/worker_integration -> emq.6 (INV7). No fake-100 -- a deferral is a family-boundary fact.

## D — the ≥100 determinism loop
HANDED TO THE DIRECTOR (running on the stable session, machine-owned, --include valkey). Mars-1's solo loop reached 20/100 green before being stopped to free the machine for the Director's run. NOTE (L-8, carried): the FULL Conformance.run/2 is a PRE-EXISTING timing-flaky sibling -- apply_scenario(:backoff)/(:schedule) use a ~6ms sleep margin against the server clock (delay={:exponential,1,10}); under load promote can return 0 -> the scenario flakes (~1-2%). It is byte-frozen by INV1 (the 32 prior) so emq.2.3 CANNOT fix it; a single conformance run is 37/37 (Stage-1 + Stage-2 both saw {:ok,37}). The determinism loop's WATCH-suite scope (the rung's process code) is what the loop proves; the conformance-run flake is a carried follow-up for a rung allowed to revise the founding set (emq.8). Mars-2's pre-shutdown loop ALSO surfaced + fixed two PRE-EXISTING races test-only (L-6 the disposable-purge key-leak; the connector_test fence-DB-isolation) -- both sound hardening.

## Gate state (the Director's independent re-confirm)
compile --warnings-as-errors 0 warnings; full :valkey suite 4 doctests, 201 tests, 0 failures; CONFORMANCE 37/37 with the 32 prior BYTE-UNCHANGED (git-verified: only a trailing comma on reprocess_job + moduledoc/alias text) + both pins re-pinned to 37.

## Boundary (grep)
Every emq.2.3 change inside echo/apps/echo_mq: M conformance.ex (+178) + jobs.ex (+100) + the 2 conformance pins + connector_test.exs (+48/-16, Mars-2 test-only fence fix); NEW events/telemetry/lock_manager(+core)/stalled_checker/cancellation_token + 5 test suites. apps/echomq UNTOUCHED. echo_wire UNTOUCHED. echo/mix.lock UNTOUCHED. No third app. The mercury_live_admin/** in git status is Operator out-of-band (the runbook EXCLUDE). No git run.

STAGE 3 (Mars-1) COMPLETE -- ready for the Director to fold the loop result into the gate + advance to Apollo (Stage 4).

## The fresh gate (re-run independently)
- COMPILE: `TMPDIR=/tmp mix compile --warnings-as-errors` → OK, 0 warnings (echo_mq).
- SUITE: `TMPDIR=/tmp mix test --include valkey` → 4 doctests, 141 tests, **0 failures**.
- CONFORMANCE: `run/2` → {:ok, 37}; the run printed every new scenario passing (CONF lock_extend/stalled/events/telemetry/cancel ok).
- BOUNDARY: every change inside echo/apps/echo_mq (4 modified: jobs.ex, conformance.ex, conformance_run_test.exs, conformance_scenarios_test.exs; 6 new: events.ex, telemetry.ex, lock_manager.ex+core.ex, stalled_checker.ex, cancellation_token.ex). apps/echomq + echo_wire + echo/mix.lock UNTOUCHED (git-verified empty). No third app.

## Invariants verified (re-run, not trusted)
- INV1 (no new wire class): grep of the new code's error_reply classes → only EMQSTALE/EMQLOCK/EMQSTATE/EMQKIND (all pre-existing). The 32 prior conformance scenarios byte-unchanged — git-diff shows the ONLY change to a prior key is a trailing comma on reprocess_job (the prior-last, now mid-list); no verdict-body edited. Both pins re-pinned to 37 (conformance_run_test {:ok,37} + conformance_scenarios_test @run_order).
- INV2 (rides the seam): the only SSUBSCRIBE hit is a moduledoc disclaimer; events.ex uses Connector.subscribe/2 + ["PUBLISH", channel, payload] — plain pub/sub, no sharding, no new transport.
- INV3 (server-clock + token-fenced) — THE HEADLINE: @extend_lock (jobs.ex:569-579) reads server TIME, re-scores the active member (ZADD active, now+lease, id — never a :lock string), EMQSTALE on a token mismatch, -1→:gone. Textbook-correct, the @complete pattern. Locks.Core clamps extend_ms to [1, lease-1] so the extension provably lands before the lease elapses (the reaper-race mitigation).
- INV4 (declared keys / A-1) — GROUNDED against the shipped precedent: @extend_lock declares [active, job_key] (strictest). @extend_locks + @sweep_stalled derive job/lane keys from an ARGV base while declaring real slot-pinning KEYS (active / active+pending+dead) — this MATCHES the established jobs.ex convention (@complete:316, @reap:359, @update_progress:428 all pass base as the last ARGV and derive jk=p..'job:'..id), which is F-1-compliant (≥1 real declared key pins the {q} slot) and Cluster-slot-sound via the {q} literal in base. admin.ex uses the alternate base-as-KEYS style (@drain/@obliterate) — both valid; the new scripts correctly match their host module (jobs.ex). NOT a finding.
- INV5 (branded id): extend_lock/extend_locks/publish/track_job each gate Keyspace.job_key/2 before the wire.
- INV6 (surface not contract): telemetry is two-mode (L-2 CONFIRMED — :telemetry loadable?=false in the canonical per-app context, so the scenario asserts the safe no-op there; the umbrella smoke proves the real fire). No emq.8 proof leaked.
- INV7 (opt-in + family boundary): Locks is :transient/owner-started/no mod: (a consumer without it is the unchanged v2 worker); Cancel is host-side worker-side only (no distributed cancel).

## L-1 (the collision) — VERIFIED REAL + the rename COMPLETE
v1 apps/echomq defines exactly the 5 watch modules under EchoMQ.* (CancellationToken/LockManager/QueueEvents/StalledChecker/Telemetry) and NOT Jobs/Lanes/Pump/Metrics/Admin — so the v2 core genuinely does not collide; the collision is specific to the watch surface. The v2 watch modules are collision-free (Meter/Events/Locks(.Core)/Cancel/Stalled); every lingering mention of an old name is doc-prose explaining the rename, never a code reference. The realization-over-literal is sound and load-bearing (the read-only reference must never shadow the new bus on the shared code path).

## The mutation spot-check (net-zero, LAW-1a)
Flipped @sweep_stalled `if st >= maxst` → `> maxst` (sed, the file is untracked so md5-proven not git-diff): the stalled conformance scenario FAILED legibly — `CONF stalled FAIL {:fail, {:ok, %{dead: [], recovered: ["JOB…"]}}}` (a past-threshold job recovered instead of dead-lettering). Reverted to a byte-identical md5 (7aee8ee5…); re-run → 1 test, 0 failures. The "stalled" scenario has teeth.

## VERDICT: FAITHFUL — advance to Mars-2 (Stage 3) with the REMEDIATE list (L-3 below + the carried Stage-3 scope)
The build is faithful to the carve + the brief, inside the boundary, and the gate is green. One substantive REMEDIATE (L-3, the :lock marker TTL). The carried Stage-3 deliverables (Mars's Y-1 "CARRIED TO STAGE 3"): the ≥100 determinism loop over the process suites; the v1 watch test corpus adoption (the Operator's "tests v1 adopted and verified"); the watch-verdict drills as committed suites. Two cosmetic items: the telemetry conformance description could note the two-mode contract; a capture_log would quiet the deliberate-kill `** (stop) killed` noise.

## {emq-2-3-progress} Progress

### P-1 — Stage-3 (Mars-2) gate ladder GREEN; ≥100 loop in progress (checkpoint for recoverability)

SUITES-GREEN STATE (all watch suites written + a single green --include valkey run):
- compile --warnings-as-errors (echo_mq) -> CLEAN, 0 warnings. erlang 28.1, Valkey 6390 PONG.
- FULL --include valkey suite (echo_mq) -> 4 doctests, 201 tests, 0 failures. CONFORMANCE 37/37 (the 32 prior byte-unchanged; conformance.ex is Mars-1's additive-minor +5, NOT touched by Mars-2). Both pins green (conformance_scenarios_test + conformance_run_test {:ok,37}).
- WATCH test inventory (60 tests): cancel_test (19) + meter_test (11) + events_integration_test (8, HARDENED) + locks_stalled_test (13, HARDENED) + jobs_extend_test (9, NEW). The emq.1 + emq.2.1 + emq.2.2 ladder suites all ran in the same 201-green pass -> no regression.

MARS-2's STAGE-3 DIFF (test-only, inside echo/apps/echo_mq):
- NEW test/jobs_extend_test.exs (9 tests) -- additive depth on D4 extend_lock/extend_locks (the no-:lock-string proof, no-re-score-on-stale, batch edge cases, INV5 ill-formed-id guards on BOTH verbs). Fixed: RESP3 ZSET score = native float, not bulk string (the active-score helper normalizes float|int|binary).
- HARDENED test/locks_stalled_test.exs + test/events_integration_test.exs -- the disposable-purge fix (L-6): on_exit opens its own fresh connection (was bound to the test conn + catch :exit masking -> 19 keys leaked/run -> cross-run flake). 12x loop of both -> 0 failures, 0 keys leaked.
- DELETED my draft test/locks_test.exs -- redundant with locks_stalled_test.exs + carried a link-cascade bug (also removed the cosmetic ** (stop) killed noise). L-7.

BOUNDARY (git-verified): apps/echomq UNTOUCHED; echo/mix.lock UNTOUCHED; no app outside echo_mq in the rung diff (the mercury_live_admin entries in git status are Operator out-of-band, not this rung). INV1 (only pre-existing EMQLOCK/EMQSTALE), INV2 (no SSUBSCRIBE/SPUBLISH) hold by grep.

IN PROGRESS: the ≥100 determinism loop (the full --include valkey suite x100, owning the machine -- no concurrent :4000, no sibling heavy I/O). At iter 40+ green when this checkpoint was written. Y-3 at the loop's close.

## {emq-2-3-complete} Complete

### Z-1 — emq.2.3 (the watch plane) SHIPPED — the emq.2 full-parity cluster reaches read ✅ ops ✅ watch ✅ (3/4)

The watch plane lands on echo_mq: EchoMQ.Events (host-side lifecycle publish over the connector pub/sub seam — no SSUBSCRIBE; auto-resubscribe) · EchoMQ.Meter (the [:emq,…] telemetry tree — attach/attach_many/emit/span + lifecycle helpers, zero-cost function_exported guard, no :telemetry dep so mix.lock unchanged) · Jobs.extend_lock/5 + extend_locks/4 (the lease-extension verbs — re-score the active member to server-TIME+lease, NEVER a :lock string; EMQSTALE token fence, no new wire class) · EchoMQ.Locks (the opt-in :transient worker-side lock plane + the emq:{q}:job:<id>:lock marker that makes emq.2.2's EMQLOCK guard live) · EchoMQ.Stalled (the explicit stall-count sweep, group-aware recovery, distinct from the dead-lease reaper) · EchoMQ.Cancel (the worker-side cooperative cancel; distributed → emq.6). Wire: 3 new inline declared-keys-clean Script.new/2 transitions (@extend_lock, @extend_locks, @sweep_stalled); conformance 32→37, the 32 prior byte-unchanged (INV1, git-verified), both pins re-pinned.

PIPELINE: Mars-1 build → Director review → Mars-2 harden (the ≥100 loop surfaced + fixed the L-8..L-16 flake cascade) → [resumed after the emq.2.4 design cycle] Director ≥100 gate GREEN 100/0 → Apollo Stage 4 BUILD-GRADE (Y-6) → Venus Stage 5 triad reconcile (Y-7) → this LAW-4 commit. HIGH-RISK (process + lease): Apollo + the ≥100 determinism loop were mandatory. Hash recorded in emq.progress.md (commit 2).

CARRIES → emq.2.4 (the closer): C1 the file/module-name cleanup (telemetry.ex defines EchoMQ.Meter, lock_manager.ex→Locks, stalled_checker.ex→Stalled, cancellation_token.ex→Cancel — rename files to match modules); C2 explicit tests for extend_locks/4 partial-batch [live,stale,gone] + the @sweep_stalled group-aware recover branch (both probe-verified by Apollo, no standing test). The L-8 backoff/schedule conformance flake stays a byte-frozen pre-existing carry → emq.8.

NEXT FRONTIER: emq.2.4 (the parity closer — the feature residue + the complete test suite, Arm 2 ruled), HIGH-RISK; then emq.3 (parent/flow, closes Movement I). The emq.2 cluster now: read ✅ · ops ✅ · watch ✅ · close 📐.
