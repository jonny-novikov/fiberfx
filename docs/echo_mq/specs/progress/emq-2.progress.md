# emq-2 — AAW scope ledger

## {emq-2-thinking} Thinking

### T-1 — UNDERSTAND/EXPAND: emq.2 RE-SCOPED by the Operator from "v1→v2 migration" to "full echomq feature-parity rewrite into echo_mq" + an agent-tooling design phase.

MODE: Flat-L2, design-phase variant (x-mode §2b) — the deliverable IS the spec + the agent tooling; no Mars and no production code this session; ends at Operator approval (a session restart that reloads the tuned agents/skills; the build runs the next session).

THE PIVOT (Operator answers, 2026-06-13). The three launch-gate questions returned a reframe, not a ruling: (1) the seam → a full ADR, AND echo_mq MUST reach FULL feature parity with the v1 echomq line — every module + every Lua script rewritten to the v2 laws; (2) brand-new EchoMQ, NO compatibility layer; rewrite from scratch; ZERO "1.3.1"/"old"/"legacy" language; echo_mq is the single source of truth; (3) pipeline collapses to solo-Director — Venus-1 reconciles + authors granular emq.2.1/2.2/2.3 (triads + prompts); Venus-2 designs the per-agent skills + the agent-def tuning; the Director solo-writes them.

CONSEQUENCE — the migration narrative is RETIRED. The prior emq.2 triad's intent (migrate/4 copy-verify-DELETE, the tombstone fence arm, the v1 maintenance-branch patch, drain-and-switch) no longer applies: there is nothing to migrate FROM. apps/echomq (25 .ex + 26 .lua) becomes a FEATURE REFERENCE only — the capability list to port, rewritten under braced+branded+declared-keys.

5W. WHO: the program — echo_mq becomes the complete bus; apps/echomq dissolves as a reference, not a push source. WHAT: reconcile the emq roadmap/specs to a full-parity rewrite decomposed emq.2.1/2.2/2.3; author the agent tooling (skills + tuned defs) so the build team is echo_mq-specialized + roadmap-aware. WHERE: docs/echo_mq/specs (granular triads + prompts, the reconciled roadmap), .claude/skills/ (per-role skills), .claude/agents/{venus,mars,apollo}.md (additive echo_mq tuning). WHEN: now (design + tooling); the build is a later session, post-restart.

PARITY GAP (the carve Venus-1 fixes from the real inventory). v1 echomq has: flow_producer (parent/child flows), lock_manager (locks), job_scheduler, queue_events (events), stalled_checker (stalled recovery), telemetry, worker, priorities (addPrioritizedJob), rate-limiting (getRateLimitTtl/isMaxed), metrics (getCounts/getMetrics/getState), pause/resume, obliterate/drain, reprocessJob, updateData/updateProgress, cancellation_token. echo_mq has: keyspace/fence, jobs (state machine), lanes (fair groups), consumer, pool, + emq.1's backoff/repeat/pump, + conformance. GAP ≈ flows · locks · events · stalled-recovery · telemetry/metrics · priorities · rate-limiting · lifecycle (pause/cancel/obliterate/checkpoints) · the worker abstraction — decomposed into emq.2.1/2.2/2.3 under the v2 laws.

SMALLEST CHANGE THAT PRESERVES CORRECTNESS (this phase): produce SPECS + TOOLING only; invent no feature the v1 reference + the design canon don't already name; agent-def tuning is ADDITIVE (preserve the shared charters for portal/mercury/redis/etc.); no commit (files land for restart-reload, Operator commits out-of-band).

INVARIANTS AS CHECKS (this phase): (a) every emq.2.x deliverable traces to a real v1 module/Lua script or a design §; (b) zero "1.3.1"/"old"/"legacy"/"migrate-from" framing in the new docs (grep); (c) the tuned charters keep their existing cross-program content intact (additive diff only); (d) each new skill follows the .claude/skills/<name>/SKILL.md convention; (e) the triad traceability closure (D→US→R→AS) holds for each of emq.2.1/2.2/2.3.

GATE: the launch forks are now Operator-ruled (D-1..D-6); the design phase is reachable; next — spawn Venus-1 ∥ Venus-2 (real general-purpose + venus charter, self-registering).

### T-2 — EXPAND: the ladder-reconciliation problem (the carve's hardest constraint, found before authoring)

INPUTS: emq.design.md §4 (the 34-row BCS gap matrix + the four re-aim clusters) + §10 (the two Operator seams) · emq.roadmap.md (the CONFIRMED Stage-1b ladder emq.0..emq.8 + the old→new bridge) · emq2.roadmap.md (the BCS-side mirror) · emq3.roadmap.md (the stream tier, hard-gated on emq.0) · the re-scope D-1..D-6.

DERIVATION:
1. The design canon ALREADY re-aimed the v1-shaped lifecycle surface into a rung it calls "old emq.2 — the BCS state machine" (§4 cluster 1: rows 1,16-18,21,23-29 + folds 2,31). But the roadmap's old→new bridge says that rung is "largely CLOSED BY THE DROP" — the as-built echo_mq carries the three-field row, four sets, attempts-as-token EMQSTALE, completion-deletes, server-clock reap, REV BYLEX browse (the 14 conformance scenarios assert them). So the BCS state machine is NOT the parity gap — it already shipped in Movement 0.
2. The CURRENT roadmap emq.2 slot = "the v1→v2 migration path re-proven (drain-and-switch; order-preserving branding; typed unmigratable refusal; v1 terminal 1.3.1 fence)". This is EXACTLY the migration intent the Operator RETIRED (D-2: echo_mq is built fresh, nothing to migrate FROM). So the re-scope VACATES the emq.2 slot's current content entirely.
3. CONSEQUENCE: the parity cluster (emq.2.1/2.2/2.3) takes the vacated emq.2 slot. Migration retires as a NON-FEATURE (no compat layer; from-scratch). The design §10 seam-1 (in-place v2→v2 migration) resolves on the no-release precondition (§11.11: the v2 line never shipped → drain-precondition is the honest default, no converter to build).
4. THE PARITY GAP (the real carve target, from emq-2.progress T-1 + the v1 inventory): NOT the state machine (shipped) but the v1 capability surface echo_mq lacks — flows · locks · events · stalled-recovery · telemetry/metrics · priorities · rate-limiting · lifecycle (pause/cancel/obliterate/checkpoints/updateData) · the worker abstraction. SOME of these the existing ladder ALREADY slots: parent/flow→emq.3, groups→emq.4, batches→emq.5, lifecycle→emq.6, conformance/telemetry→emq.8. So the carve MUST de-conflict: emq.2.N ships the parity surface NOT already owned by emq.3..emq.8, OR the cluster re-sequences those rungs.

THE FORK THIS RAISES (for the carve decision, ruled in D-n next): does the parity cluster (A) ship ONLY the un-slotted parity gap and LEAVE emq.3..emq.8 as-is, or (B) SUBSUME the Movement-I/II feature rungs into the emq.2.N cluster and re-sequence? Counter-example test for (A): if emq.2.N ships "events" but emq.8 ships "telemetry", the queue-events stream and the telemetry handler both read the same job lifecycle — splitting them across the ladder fragments one surface. Pull: the Operator said "FULL feature parity" + "every module + every Lua script" → that reads as (B)-leaning (the cluster IS the parity rewrite), BUT the existing ladder is CONFIRMED (Stage-1b) and emq3.x hard-gates on it — re-sequencing has blast radius. RESOLUTION GROUND: the carve keeps the cluster to the v1 PARITY surface (one-increment-one-run, dependency-ordered) and reconciles the OVERLAP rungs explicitly in the ADR's ladder-reconciliation table — naming for each existing rung whether emq.2.N subsumes it, re-sequences it, or leaves it. This is a D-n + a surfaced fork to the Director (architecture/sequencing = Operator's call per the venus charter "surface forks, never decide them").

INVARIANTS THIS DEPENDS ON: the v2 master invariant holds for every emq.2.N rung; the as-built echo_mq surface (jobs/lanes/consumer/pool/keyspace + emq.1's backoff/repeat/pump) is the floor the parity surface builds ON, not re-builds; emq.0's wire (echo_wire) is the transport for every new script.

### T-3 — Venus-2 derivation: the agent-tooling design (skills + additive charter tuning)

WHO/WHAT/WHERE: Venus-2 (architect, ccl-emq-2-3, registered 3/3 no FAKE-N). Deliverable = ONE design spec at docs/echo_mq/specs/emq-2.tooling-design.md the Director writes the real .claude files FROM. I DESIGN; the Director WRITES. No .claude edits by me.

THE PROBLEM (D-1..D-6): emq.2 re-scoped to a full echomq→echo_mq feature-parity rewrite, no compat, single source of truth. The build team (venus/mars/apollo) must become echo_mq-specialized + roadmap-aware WITHOUT losing its cross-program service (portal/mercury/redis/elixir). Mechanism (D-5): a per-agent dev SKILL under .claude/skills/ + an ADDITIVE "## echo_mq program" charter block — additive-only, no removal.

GROUNDING READ (read-only): the 3 charters venus/mars/apollo.md (the cross-program craft I must preserve — F6.x guardrails, the determinism loop, the boundary grep, the realization-over-literal, the design-phase rules, the mentoring loop); x-mode SKILL.md (the .claude/skills/<name>/SKILL.md convention + references/ subdir, exemplar = bcs-course-writer/references/course-map.md); emq.design.md (the canon: S-1..S-7 locks, the §2 branded-id ADR, §3 fence merge, §4 gap matrix, §5 wire-class registry, §6 grammar-total, §10 seams, §11 founding decisions, §12 engine ADRs); emq.roadmap.md (Movements 0/I/II, the emq.0→emq.8 ladder, the master invariant — per-app testing BANNED, agents run no git, Director commits by pathspec); echo_mq.md (front door — emq.2 = program hygiene, trading the named consumer); emq-1.progress.md (THE craft already earned, shipped: per-app compile --warnings-as-errors, TMPDIR=/tmp, Valkey 6390 PONG, the ≥100 determinism loop for same-ms branded-id mint collisions, inline Script.new/2 NOT priv/, the conformance additive-minor law 14→18 prior-N-byte-unchanged each probe-registered, the lag-1 pre-build reconcile, the realization-over-literal Director-ratify, the solo-Director-review-replaces-Apollo variant, the L-6 "pre-existing must distinguish env-gated-cannot-run from this-change-staled-it").

DERIVATION (the smallest design that makes the team echo_mq-specialized + preserves cross-program service):
- The skill is the WHERE the program craft lives so the charter block stays a thin pointer (DRY: the charter says "load <skill> on an emq.* rung"; the skill carries the full law). This keeps the additive charter diff minimal (the LAW: additive-only, preserve cross-program content) AND keeps the craft in ONE authority (the team's own single-source-of-truth discipline applied to its own tooling).
- THREE skills not one: each role's craft is genuinely distinct (architect = triad+reconcile+carve+the seam-fork-surface; implementor = spec-cited build inside the boundary + the Lua/key/branded-id/inline-script laws + the gate ladder; evaluator = the §11.2 charter applied to echo_mq + the adversarial order-theorem/declared-keys/destructive-act probes + the conformance count-byte-unchanged re-verify). A single shared skill would force each spawn to read past 2/3 irrelevant craft — the bloat the apollo charter's "one guardrail per recurring finding, keep the definitions lean" rule warns against. The SHARED program facts (the v2 laws, the gate ladder, the roadmap, NO-INVENT, no-git) are common to all three — those go in a references/ file all three SKILL.md files point at, so the common law is itself single-source.
- ADDITIVE charter tuning not dedicated *-echomq charter variants: venus/mars/apollo already carry the program-neutral discipline (reconcile, cite-don't-invent, done-is-a-closure, the design phase, mentoring) — that IS the echo_mq discipline too; a dedicated variant would FORK the shared craft (every future portal/redis lesson would have to be applied twice). The program-specific delta (the v2 laws, the roadmap ladder, the per-app/Valkey-6390/determinism-loop specifics, the skill pointer) is small and bolts on as one "## echo_mq program" section — exactly the additive shape D-5 names.

NEXT: read reconcile.md (the differ both architect+evaluator skills cite) + probe the as-built echo_mq/echo_wire surface (the real module/Lua/key names the skills cite as NO-INVENT anchors), then write the design spec.

### T-4 — SYNTHESIZE: the parity gap resolved against the as-built floor + the existing ladder (the carve's content)

AS-BUILT echo_mq SURFACE (the floor — verified by grep, file:line):
- jobs.ex: enqueue/4, enqueue_at/5, enqueue_in/5, enqueue_many/3, claim/3, complete/4, retry/7, promote/3, reap/2, browse/3, pending_size/2 — 7 inline scripts (@enqueue/@schedule/@claim/@complete/@retry/@promote/@reap). The BCS state machine: three-field row, four sets (pending/active/schedule/dead), attempts-as-token EMQSTALE, completion-deletes, REV BYLEX browse, server-clock TIME. SHIPPED.
- lanes.ex: enqueue/5, claim/3, pause/3 (per-GROUP), resume/3, limit/4, depth/2 — fair groups basics. SHIPPED (G1–G8).
- consumer.ex: child_spec/start_link/stop — the worker shell. pump.ex + pump/core.ex: the promote+repeat cadence. repeat.ex: register/cancel/due/advance/count. backoff.ex: delay_ms/2 (fixed/exponential/jitter). pool.ex: round-robin connections. keyspace.ex: queue_key/job_key/reserve/version_key/slot/hashtag. conformance.ex: 18 scenarios.

v1 CAPABILITY SURFACE (the reference to port — by module, public API verified):
- flow_producer.ex: add/2, add_bulk/2 (parent/child flows) → OWNED by emq.3 (parent/flow family).
- queue.ex (2144 LoC, the API hub): add/add_bulk, get_job, get_job_state, get_counts, count, get_job_counts, get_meta/get_version/update_meta, get_jobs (by states), get_waiting/active/delayed/prioritized/completed/failed (+ _count each), get_global_concurrency, get_global_rate_limit, get_rate_limit_ttl, get_deduplication_job_id, remove_deduplication_key, get_job_logs, get_metrics, get_workers/_count, export_prometheus_metrics, pause/resume.
- worker.ex (1908 LoC): pause/resume/paused?/running?/active_count, cancel_job/cancel_all_jobs/active_job_ids, get_next_job, stalled-check timer, close, update_progress/log/update_data.
- job_scheduler.ex: upsert/get/list/count/remove/remove_by_key/calculate_next_millis (CRON repeatable — richer than echo_mq's Repeat).
- lock_manager.ex: track_job/untrack_job/get_active_job_count/get_tracked_job_ids/is_tracked? + extend_locks loop.
- queue_events.ex: subscribe/unsubscribe/close + handle_event behaviour (the events stream).
- stalled_checker.ex: check/2, job_stalled?/4 + periodic sweep.
- telemetry.ex: attach/attach_many/emit/span + job_added/started/completed/failed/retried/worker_started.
- cancellation_token.ex: new/cancel/check/check! (cooperative cancel).
- v1 Lua: getCounts, getMetrics, getRateLimitTtl, isMaxed, getState, pause, obliterate, drain, reprocessJob, updateData, updateProgress, addLog, removeJob, moveStalledJobsToWait, extendLock(s), releaseLock.

THE DE-CONFLICT (which gap rung owns what — the load-bearing carve):
- flows → emq.3 (EXISTING). groups deepened (control plane/recovery/rotation) → emq.4 (EXISTING). batches (bulk-CONSUME) → emq.5 (EXISTING). cancel/checkpoints → emq.6 (EXISTING). conformance/telemetry/benchmark → emq.8 (EXISTING).
- REMAINING parity gap NOT owned by any existing rung = THREE coherent clusters:
  · CLUSTER A = INTROSPECTION & METRICS: get_counts/count/get_job_counts (getCounts), get_job_state/get_jobs-by-state/get_waiting/active/etc (getState), get_metrics (getMetrics), get_job/get_meta, get_deduplication_job_id, the RATE-LIMIT family (get_rate_limit_ttl/get_global_rate_limit/getRateLimitTtl/isMaxed), get_workers, export_prometheus. ALL read-or-limit verbs — no state-machine change. ← emq.2.1.
  · CLUSTER B = LIFECYCLE & MUTATION OPS: pause/resume (queue-wide, the v1 pause-7.lua), drain (drain-6), obliterate (obliterate-2), update_data/update_progress (updateData/updateProgress), add_log/get_job_logs (addLog), remove_job (removeJob), reprocess_job (reprocessJob). The operator/maintenance verbs over the row + sets. ← emq.2.2.
  · CLUSTER C = OBSERVABILITY & RECOVERY: queue_events (the per-queue event stream pub/sub), telemetry (attach/emit/span over the lifecycle), stalled_checker / moveStalledJobsToWait (the explicit stalled-sweep beyond the built reap), lock_manager/extendLock(s)/releaseLock (the worker-side lock tracking + lease extension), cancellation_token. ← emq.2.3.

DEPENDENCY ORDER: A (pure reads, no new transition) → B (mutations that the reads observe) → C (the event/telemetry/recovery plane that watches A+B). One-increment-one-run; each builds ON the as-built floor, none re-builds the state machine.

THE LADDER RESLOT THIS FORCES (the fork for the Director/Operator): the parity cluster takes the emq.2 slot (emq.2.1/2.2/2.3). The OLD emq.2 (migration) RETIRES as a non-feature (D-2: built fresh, no compat). The §10 seam-1 in-place v2→v2 migration resolves on the no-release precondition (drain default). emq.3–emq.8 KEEP their slots and content (flows/groups/batches/lifecycle/cache/conformance) — the parity cluster does NOT subsume them; it fills the gap BELOW them. RECONCILE: emq3.x stream tier still hard-gates on emq.0 (unaffected). This is option (A) from T-2 — keep the cluster to the un-slotted parity surface, leave emq.3–emq.8 as-is — chosen because emq.3–emq.8 are CONFIRMED (Stage-1b) + emq3.x gates on the ladder; re-sequencing has blast radius for zero parity gain (flows/groups/batches are genuinely later families, not the v1 floor echo_mq lacks today).

### T-5 — TOOLING HALF COMPLETE + gated (Director solo-write, the "Direct Solo Write" split of D-3). Venus-2's design (emq-2.tooling-design.md, ACCEPTED build-grade) written to disk:

NEW skill files (the .claude/skills/<name>/SKILL.md convention; loader-confirmed registered):
- .claude/skills/echo-mq-program.md — shared program-law reference (v2 laws table · roadmap awareness · gate ladder · conformance additive-minor law · NO-INVENT · process locks). Flat file; loader correctly ignores non-SKILL.md.
- .claude/skills/echo-mq-surface.md — the as-built NO-INVENT anchor map (echo_mq · echo_wire · the frozen feature reference · the substrate).
- .claude/skills/echo-mq-architect/SKILL.md — Venus craft (lag-1 reconcile · triad-to-v2-laws · carve · surface-forks · design phase).
- .claude/skills/echo-mq-implementor/SKILL.md — Mars craft (build inside the boundary · cite-don't-invent · the Lua laws · conformance mechanics · the gate ladder).
- .claude/skills/echo-mq-evaluator/SKILL.md — Apollo craft (post-build reconcile · the adversarial echo_mq probes · re-run-the-gate · sync + mentor).

ADDITIVE charter tunings (git --numstat: venus +21/-0, mars +20/-0, apollo +21/-0 = 62 insertions, ZERO deletions): a "## echo_mq program" block inserted before the confirmed anchor in each of .claude/agents/{venus,mars,apollo}.md — every existing cross-program line preserved (the shared charters still serve portal/mercury/redis/elixir). Refinement over the design: repo-relative read-paths; the banned-framing guardrail phrased generically ("legacy"/"old"/version-suffix/"migrate-from") rather than hard-coding a version token.

GATE: additive-only diff PASS (0 deletions); no banned framing as prose (only the guardrail names the banned set) PASS; skill convention PASS (3 dirs registered + 2 refs ignored). Ratifies Venus-2's D-7 (3 per-role skills + 1 shared reference) and D-8 (additive charter blocks, not dedicated variants).

REMAINING (blocked on Venus-1): gate the parity ADR + carve + roadmap reconcile + the emq.2.1 exemplar; fan out spec-author ×2 for emq.2.2/2.3 if Venus-1 hands the carve back; reconcile the skills' ladder bullet + emq.progress.md to Venus-1's final carve; the restart + handoff prompt. The tuned agents/skills reload at session start — the restart is the activation, no commit (D-6). EXCLUDE from any emq-2 surface: the Operator's out-of-band .claude/agents/mercury-expert.md + .claude/skills/mercury-ship/ + echo/apps/exchange/ (trd.1.1).

### T-6 — emq.2.3 lag-1 reconcile: the watch-plane seams are REAL (ground for ADR-3/ADR-4)

Venus-4 probed the as-built tree the emq.2.3 watch plane stands on. Classification MATCH/STALE per anchor:

ADR-4 (events + telemetry):
- `EchoMQ.Connector.subscribe/2` + `unsubscribe/2` (echo_wire/lib/echo_mq/connector.ex:108-121) — MATCH. Record the channel in the `subscriptions` MapSet; `resubscribe/1` (connector.ex:606-617) re-issues the whole set at the `:reconnect` success arm (connector.ex:334-335); `down/1` (connector.ex:586-599) KEEPS the set. Pushes route to `push_to` as `{:emq_push, payload}` (connector.ex:553). RESP3-gated (`requires_resp3` when protocol != 3). The `EchoWire` facade exposes `subscribe`/`unsubscribe` defdelegates (echo_wire.ex:26-27). → EchoMQ.Events rides THIS seam; NO new transport (design §12.3 holds).
- The telemetry primitive is the private `Connector.emit/3` (connector.ex:634-640): `:erlang.function_exported(:telemetry, :execute, 3)` zero-cost guard, already firing `[:emq, :connector, {connection,disconnection,reconnect,overload,pipeline,stop}]`. → EchoMQ.Telemetry re-roots THIS pattern over the JOB lifecycle `[:emq, :job, …]` / `[:emq, :worker, …]`.

ADR-3 (stalled plane) — the gap is REAL:
- `EchoMQ.Jobs.reap/2` (jobs.ex:329-333 + the @reap script jobs.ex:243-271) — server-side single scan, `TIME` server-clock, `ZRANGEBYSCORE active -inf now LIMIT 0 100` → back to pending. MATCH as the as-built reaper.
- NO lock-extension verb on Jobs, NO worker-side tracking — STALE-as-MISSING (the v1 gap emq.2.3 closes). The re-score pattern to PORT: the @claim script `ZADD KEYS[2], now + tonumber(ARGV[2]), id` (jobs.ex:135) refreshes the active-set score; the token fence to PORT: @complete `att ~= ARGV[2] → redis.error_reply('EMQSTALE …')` (jobs.ex:142-144). So the lock-extension verb = re-score active member to TIME+lease, EMQSTALE on stale attempts-token. Declared keys: KEYS=[active, job_key] (the @complete key shape).
- The process precedent = `EchoMQ.Pump` (pump.ex): `:transient` (child_spec restart: :transient, pump.ex:36), opt-in/owner-started ("A worker started without the pump is the v2 core worker, unchanged", pump.ex:7-9), pure decision `Pump.Core`, timer via `arm/1` Process.send_after(:tick) (pump.ex:146-149), GenServer thin shell. → the worker-side lock plane (lock_manager) mirrors this shape: track held jobs, extend on a timer, release on completion.
- `EchoMQ.Consumer` (consumer.ex) is a spawn_link loop (NOT a GenServer), reap+promote+drain+park; the lock plane is a SEPARATE opt-in process beside it, not folded in (ADR-3 alt 2 rejected).

Conformance: `EchoMQ.Conformance.scenarios/0` = 18 (conformance.ex:20-41), byte-confirmed: fence,mint,duplicate,kind,order,claim,stale,complete,retry,dead,reap,rotate,pause,limit,schedule,repeat,backoff,resubscribe. `run/2` → {:ok, n} (conformance.ex:48-68). The 18 are the byte-unchanged contract; emq.2.3 grows the count additively.

emq.2.2 does NOT exist on disk yet (only emq.2.1 authored as exemplar). emq.2.3 references emq.2.2's transitions (pause/drain/update_*/remove) as the events fire on — grounded against the CARVE (ADR-1) which fixes emq.2.2's surface, NOT re-spec'd. Forward-tense.

Verdict so far: BUILD-GRADE seams. Every ADR-3/ADR-4 mechanism grounds in a real anchor or a design §. Probing the v1 feature reference next (lock_manager/stalled_checker/telemetry/queue_events/cancellation_token) for the NO-INVENT capability anchors.

### T-7 — emq.2.3 v1 feature-reference anchors + the v2-rewrite delta (NO-INVENT ground)

Every emq.2.3 ported capability has a REAL v1 anchor; each is rewritten to the v2 laws (never the v1 form). Probed echo/apps/echomq:

WORKER-SIDE LOCK PLANE (ADR-3):
- `lock_manager.ex`: track_job/3 (l.62), untrack_job/2 (l.70), get_active_job_count/1 (l.78), get_tracked_job_ids/1 (l.86), is_tracked?/2 (l.94), start_link/1 (l.54), + the extend_locks loop. → v2 EchoMQ port mirrors EchoMQ.Pump's process shape (:transient, opt-in, owner-started, pure Core, timer).
- LOCK-EXTENSION verb DELTA (the "port capability not form" law): v1 extendLock-2.lua roots a SEPARATE string key `emq:{q}:j:<id>:lock`, GET==token → SET PX, SREM stalled. The v2 bus has NO separate lock string — the lease IS the active ZSET score (jobs.ex:135 @claim `ZADD KEYS[2], now+lease, id`). So the v2 lock-extension verb RE-SCORES the active member to TIME+lease, token-fenced on attempts (`att ~= ARGV[2] → EMQSTALE`, the @complete pattern jobs.ex:142-144), declared keys [active, job_key]. extendLocks-2.lua (msgpack batch) + releaseLock-1.lua are the batch/release anchors.

STALLED SWEEP (ADR-3):
- `stalled_checker.ex`: check/2 (l.110), job_stalled?/4 (l.122), start_link/1 (l.99) + periodic sweep. moveStalledJobsToWait-9.lua DELTA: v1 roots 9 keys (separate `stalled` SET, wait/active LISTs, events STREAM, stalled-check throttle, meta, paused, marker) + CALLER clock (ARGV[2] timestamp ms). v2 re-derives the CAPABILITY (a stall-count threshold beyond a dead-lease reap) under TIME server-clock + the as-built four ZSETs — never the v1 9-key LIST shape. Distinguishes a reaped dead lease from a stalled-count threshold (beyond Jobs.reap/2's single scan).

EVENTS (ADR-4):
- `queue_events.ex`: subscribe/2 (l.184, pid \\ self()), unsubscribe/2 (l.192), close/1 (l.200), @callback handle_event/3 (l.462) behaviour, lifecycle event atoms :completed/:failed (l.53/59). → v2 EchoMQ.Events rides the connector subscribe/2+unsubscribe/2 pub/sub seam (NOT a v1 transport); the {:emq_push, …} message + the resubscribe MapSet are the mechanism. Channel = a queue_key suffix spelled against §6 (Keyspace.queue_key/2 → emq:{q}:<type>).

TELEMETRY (ADR-4 + ADR-2 two-layer):
- `telemetry.ex`: attach/4 (l.116), attach_many/4 (l.134), emit/3 (l.145/149), span/3 (l.166); the six lifecycle helpers job_added/4 (l.223), job_started/4 (l.232), job_completed/5 (l.242), job_failed/6 (l.252), job_retried/5 (l.263), worker_started/3 (l.272). → v2 EchoMQ.Telemetry re-roots all under `[:emq, …]`. NOTE (ADR-2): emq.2.3 ships the SURFACE (events fire); the telemetry CONTRACT proof stack is emq.8 — DO NOT ship emq.8's proof here.

COOPERATIVE CANCEL (ADR-3, worker-side half only):
- `cancellation_token.ex`: new/0 (l.107), cancel/3 (l.117, reason \\ nil), check/1 (l.140), check!/1 (l.161). → v2 worker-side new/cancel/check. DISTRIBUTED cancel stays emq.6 (ADR-2) — DO NOT ship it here.

WIRE-CLASS (design §5): closed registry EMQKIND+EMQSTALE at 2.0; "adding a wire class is an additive minor with probe"; five-code fence union stands unextended (design.md:277-281). The lock-extension stale refusal REUSES EMQSTALE (the existing fencing-token class) — NO new class needed for emq.2.3.

TRANSPORT (design §12.3, design.md:488-493): SSUBSCRIBE deferred to the cache rung's invalidation bus; under completion-deletes "the event record is the durable receipt — the stream's value RISES." ADR-4's no-new-transport holds exactly; the durable replayable stream is emq3.2 (OUT of scope).

CONFORMANCE PINNING (the two tests emq.2.3 must update): conformance_scenarios_test.exs pins @run_order (18 names) via `Keyword.keys(Conformance.scenarios()) == @run_order` (l.34-35); conformance_run_test.exs pins `Conformance.run(conn, q) == {:ok, 18}` behind :valkey (l.34). Both update with the new scenarios + the new total (additive-minor law). The 18 names stay byte-unchanged.

All anchors GROUND. NO escalation needed — every capability maps to a real v1 module + a v2 mechanism. Authoring the triad to Arm A.

### T-8 — emq.2.2 lag-1 reconcile (as-built ⇄ the carve, NO-INVENT)

Venus-3 reconciled the operator-plane carve (emq.2.design ADR-1 §2; the carve = pause/resume · drain · obliterate · update_data/update_progress · add_log/get_job_logs · remove_job · reprocess_job) against the as-built tree.

AS-BUILT FLOOR (probed, MATCH):
- EchoMQ.Jobs (jobs.ex) — the v2 four-set state machine: pending (ZSET score-0), active (ZSET lease-scored), schedule (ZSET run-at), dead (ZSET); three-field row state/attempts/payload; completion-DELETES the row (no `completed`/`failed` set). 7 inline Script.new attrs (@enqueue/@schedule/@claim/@complete/@retry/@promote/@reap). EMQKIND first act of enqueue; EMQSTALE token fence on complete/retry. Server clock TIME on every lease touch.
- EchoMQ.Keyspace — queue_key/2 → emq:{q}:<type>; job_key/2 gates BrandedId.valid?/1 + RAISES; reserve/1 → {emq}:; §6 grammar.
- EchoMQ.Lanes — per-GROUP pause/3 (SADD `paused` set + LREM ring) / resume/3 / limit/4 / depth/2. DISTINCT scope from a queue-wide pause.
- EchoMQ.Conformance — scenarios/0 = the keyword list of 18 (fence…resubscribe); run/2 → {:ok, n}, n==18 today.
- EchoWire facade — eval/5 runs scripts; expect NO new delegate for emq.2.2 (mutations run through eval).
- NO echo_mq/priv/ — scripts are inline Script.new/2 attrs.

V1 FEATURE REFERENCE (probed, all 8 operator anchors EXIST under echo/apps/echomq/priv/scripts/): pause-7, drain-6, obliterate-2, removeJob-12, reprocessJob-8, updateData-1, updateProgress-3, addLog-2. These root keys in DATA values (root .. "j:" .. jobId) and use the v1 legacy v1 set model (wait/paused-LIST/completed/failed/prioritized/waiting-children) — structurally inexpressible under declared-keys; PORT the capability, never lift the form.

VERDICT: BUILD-GRADE. Every carve verb grounds in a real v1 Lua anchor + the §6 grammar + the as-built four-set floor; no INVENTED surface. The emq.2.2 files do not yet exist (authored fresh this run, to the emq.2.1 exemplar shape).

## {emq-2-decisions} Decisions

### D-1 — Re-scope (Operator, supersedes the migration framing). echo_mq MUST reach FULL feature parity with the v1 echomq line: every module + every Lua script rewritten to the v2 laws (braced emq:{q}: · branded JOB ids · every Lua key declared-or-rooted · server-clock where leases are touched · honest-row conformance). The seam (design §10 seam 1) is answered by a full ADR Venus-1 authors. The emq specifications (roadmap + ladder) are reconciled to include the full parity surface.

### D-2 — Brand-new EchoMQ, NO compatibility layer. Rewrite from scratch, porting the v1 feature set as a capability reference. ZERO "1.3.1" / "old" / "legacy" / "migrate-from-v1" language anywhere in the new documentation — echo_mq is the single source of truth, no ambiguity. apps/echomq is a FEATURE REFERENCE only (what to port), never a thing migrated from. The prior emq.2 triad's migration intent (migrate/4, tombstone fence arm, maintenance-branch patch, drain-and-switch) is RETIRED.

### D-3 — Pipeline = solo-Director design phase (no Apollo this session). Custom shape: Venus-1 (architect) reconciles the emq specs + authors the granular emq.2.1/2.2/2.3 triads + prompts + the parity ADR; Venus-2 (architect) DESIGNS the per-agent echo_mq skills + the agent-def tuning; the Director SOLO-WRITES those skills + defs (Venus-2 designs, Director implements). Venus-1 ∥ Venus-2 run as real parallel general-purpose spawns adopting the venus charter, self-registering (LAW-1).

### D-4 — emq.2 decomposes into emq.2.1 + emq.2.2 + emq.2.3 (three granular rungs, each a full triad emq.2.N.md/.stories.md/.llms.md + an emq.2.N.prompt.md runbook). Venus-1 fixes the exact carve of the parity surface across the three rungs from the real v1 inventory (25 .ex + 26 .lua) and the design canon — coherent, one-increment-one-run, dependency-ordered.

### D-5 — Agent tooling. Each of venus/mars/apollo gains an echo_mq dev skill under .claude/skills/ (the .claude/skills/<name>/SKILL.md convention) + an ADDITIVE tuning of its .claude/agents/<role>.md charter (an "echo_mq program" section + a skill pointer + roadmap awareness), so the shared charters keep serving the other programs (portal/mercury/redis/elixir) unchanged — additive diff only, no removal of existing cross-program content. The Operator's instruction is the explicit grant required for the peer-def edits (portal-leadteam-governance).

### D-6 — No commit this session (design + tooling phase, not a rung ship). All artifacts land in the working tree; the tuned agents/skills are read from disk at session start, so a RESTART reloads them with no commit required. The Operator commits out-of-band. The session ends by asking the Operator to restart and handing over the exact /x-mode prompt to spin out the emq.2.1 build next session. The in-flight echo/apps/exchange/ (trd.1.1) + docs/exchange/* stay untouched and OUT of any emq-2 work.

### D-7

D-7 (Venus-2) — The skill set: THREE per-role dev skills + ONE shared references file (V-1).

NAMES (on the .claude/skills/<name>/ convention, role-suffixed for discoverability beside the existing course-writer skills):
- `echo-mq-architect`  → loaded by venus on an emq.* rung
- `echo-mq-implementor` → loaded by mars on an emq.* rung
- `echo-mq-evaluator`  → loaded by apollo on an emq.* rung

Each is .claude/skills/<name>/SKILL.md (frontmatter name + description trigger paragraph + a role-craft body). All three carry a `references/echo-mq-program.md` (the SAME file, one per skill dir OR a shared one the Director places once and all three SKILL.md point at by relative path) holding the COMMON program law: the v2 laws table (S-1..S-7 braced/branded/declared-keys/server-clock/honest-row/one-time-fork/additive-minor), the gate ladder (per-app compile --warnings-as-errors + per-app suites + the ≥100 determinism loop + the conformance count-byte-unchanged law), the roadmap awareness (emq.0→emq.8 + the master invariant + the emq.2.x parity cluster + the seams), the NO-INVENT grounding map (real modules/Lua/design §), and the process locks (no-git-by-agents, Director-commits-by-pathspec, per-app-testing-only). The Director decides one-shared-file-vs-three-copies at write time (the design spec recommends ONE shared references file under a stable path, e.g. .claude/skills/echo-mq-program.md, all three SKILL.md linking it — single-source-correct).

The role-distinct craft (the SKILL.md body) per role:
- architect: the triad shape (emq.N.md/.stories.md/.llms.md), the lag-1 pre-build reconcile (the /reconcile algorithm), carving a parity surface from the v1 reference + design §, surfacing-not-deciding the seam forks, the design-phase rules for a SYSTEM founding, the forward-tense "emq.N builds" grounding.
- implementor: the spec-cited build inside the boundary (echo_mq + the one echo_wire seam), the inline Script.new/2 law (NOT priv/), the declared-keys/branded-id/server-clock Lua laws, the conformance additive-minor mechanics (extend scenarios/0 + register the probe + keep the prior N byte-unchanged), the gate ladder run-before-report, realization-over-literal.
- evaluator: the post-build reconcile (as-built → spec promises), the §11.2 charter applied to echo_mq (prompted-checks + un-prompted finding + attack-that-held + mutation kill-rate), the adversarial echo_mq probes (the order theorem byte=mint, declared-keys grep over every new script, the destructive-act/at-most-once/non-atomic-read probes), the conformance count-byte-unchanged re-verify, the spec-sync + mentoring loop.

### D-8

D-8 (Venus-2) — The charter tuning: ONE additive "## echo_mq program" block per role (V-2), no dedicated variant.

EXACT SHAPE (the Director adds this block to each of .claude/agents/{venus,mars,apollo}.md, AFTER the existing role-specific craft sections and BEFORE "## Scope + framing" — additive, preserving every cross-program line):

A "## echo_mq program" section carrying, identically-structured across the three:
1. THE POINTER — "On any rung whose slug matches emq.* (the EchoMQ bus program — design canon docs/echo_mq/emq.design.md, roadmap docs/echo_mq/emq.roadmap.md), load the `<echo-mq-architect|implementor|evaluator>` skill: it carries the program craft (the v2 laws, the gate ladder, the conformance additive-minor law, the NO-INVENT grounding, the roadmap awareness)."
2. THE ROADMAP AWARENESS — one line: the ladder emq.0→emq.8 (Movement 0 land+prove · Movement I core parity incl. the emq.2.x full-feature-parity-rewrite cluster · Movement II family depth), the master invariant (the fork happened once; the v2 key universe is grammar-total braced emq:{q}: with the {emq}: reserve, every Lua key declared-or-rooted, the version record monotone behind the five-code fence; no later rung re-breaks the wire — additive registration is a minor, a wire break is a major).
3. THE PROGRAM GUARDRAILS EARNED — the small program-specific delta the shared charter does not already state: per-app testing ONLY (umbrella-wide mix test BANNED — the record's D7); TMPDIR=/tmp; the live engine is Valkey on port 6390 (redis-cli -p 6390 ping → PONG; :valkey-tagged suites are excluded by default); the determinism loop owns the machine; agents run NO git, the Director commits by pathspec; apps/echomq is the FROZEN v1 push source (1.3.0) — a FEATURE REFERENCE to port from, never a thing migrated-from and never edited (zero "1.3.1"/"old"/"legacy"/"migrate-from-v1" framing — echo_mq is the single source of truth).

Each role's block adds its ONE role-specific program line (architect: the seam forks live in emq.roadmap.md §Seams + design §10 — surface, never decide; implementor: build inline Script.new/2, NOT priv/ — no echo_mq/priv/ exists; evaluator: re-verify the conformance count is byte-unchanged for the prior scenarios + each new one probe-registered, and the order theorem byte=mint).

RATIONALE: additive-only preserves the cross-program service (a generic charter line a future portal/redis rung earns serves echo_mq for free); the program craft lives in the skill so the block stays a thin pointer; the Operator's instruction is the explicit grant for the peer-def edits (portal-leadteam-governance). The Director WRITES these blocks; Venus-2 only DESIGNS them.

### D-9 — THE CARVE + THE LADDER RESLOT (recommended; the sequencing surfaced as a fork)

THE CARVE (emq.2 → emq.2.1 + emq.2.2 + emq.2.3, dependency-ordered, one-increment-one-run):
- emq.2.1 — INTROSPECTION & METRICS (the read plane). Ports v1: queue.ex get_counts/count/get_job_counts/get_job_count_by_types (getCounts-1.lua), get_job_state/get_jobs-by-states/get_waiting/active/delayed/completed/failed + _count (getState-8.lua), get_metrics (getMetrics-2.lua), get_job/get_meta, get_deduplication_job_id, the RATE-LIMIT family get_rate_limit_ttl/get_global_rate_limit + isMaxed-2.lua/getRateLimitTtl-2.lua. echo_mq target: a new EchoMQ.Metrics (or fold reads into Jobs/Lanes) + the rate-limit gate. Pure-read verbs over the as-built four sets + three-field row + lanes; ONE new transition-free script class per read; NO state-machine change. Conformance: counts/state/metrics/ratelimit scenarios. GROUND: the v1 read API is the parity surface; the as-built jobs.ex/lanes.ex/keyspace.ex is the floor; design §6 grammar for any new read key.
- emq.2.2 — LIFECYCLE & MUTATION OPS (the operator plane). Ports v1: pause/resume queue-wide (pause-7.lua — distinct from lanes.ex's per-GROUP pause), drain (drain-6.lua), obliterate (obliterate-2.lua), update_data/update_progress (updateData-1/updateProgress-3.lua), add_log/get_job_logs (addLog-2.lua), remove_job (removeJob-12.lua), reprocess_job (reprocessJob-8.lua). echo_mq target: a new EchoMQ.Admin (or Ops) + the job-mutation verbs on Jobs. Each is a real transition over the row+sets under the v2 laws (declared keys, EMQ* refusals where a precondition fails, server-clock where leases touched). Conformance: pause/drain/obliterate/update/log/remove/reprocess scenarios. GROUND: v1 lifecycle Lua scripts; the as-built state machine; design §5 wire-class registry for refusals.
- emq.2.3 — OBSERVABILITY & RECOVERY (the watch plane). Ports v1: queue_events (the per-queue event stream pub/sub — subscribe/unsubscribe/handle_event), telemetry (EchoMQ.Telemetry attach/attach_many/emit/span + the job_* emitters), stalled_checker / moveStalledJobsToWait-9.lua (the explicit stalled-sweep beyond the built reap), lock_manager + extendLock(s)/releaseLock (worker-side lock tracking + lease extension), cancellation_token (cooperative cancel — the worker-side half; distributed cancel stays emq.6). echo_mq target: EchoMQ.Events + EchoMQ.Telemetry + EchoMQ.StalledCheck + lock-extension verbs on Jobs. GROUND: v1 observability modules; the as-built consumer/pump process shapes; design §5 (events as the durable receipt under completion-deletes, §12.3 ground); the SSUBSCRIBE deferral (§12.3) keeps the event channel on the existing pub/sub seam.

THE LADDER RESLOT: emq.2 slot = the parity cluster (emq.2.1/2.2/2.3). OLD emq.2 (migration) RETIRES as a non-feature (D-2). emq.3 (parent/flow), emq.4 (groups deepened), emq.5 (batches), emq.6 (lifecycle: cancel/checkpoints), emq.7 (cache deepened), emq.8 (conformance/telemetry/benchmark proof stack) KEEP their slots + content. The parity cluster fills the v1 floor BELOW those families; it does NOT subsume them (Arm A, V-1). Design §10 seam-1 (in-place v2→v2 migration) resolves on the no-release precondition (§11.11): drain-precondition is the honest default; no converter to build; migration is not a program feature.

THE FORK SURFACED TO THE DIRECTOR/OPERATOR (architecture/sequencing = not Venus's to decide): does the Operator want the parity cluster kept to the un-slotted floor (Arm A, recommended), OR the feature rungs emq.3/4/5 PULLED INTO the cluster (Arm B)? The carve, the roadmaps, and the exemplar are authored to Arm A; if the Operator rules Arm B, the cluster re-sequences (a cheap roadmap edit before any build). RECORDED as the gate the Director ratifies before fan-out.

### D-10 — Director GATE on Venus-1 = PASS (build-grade); Arm A RATIFIED (consistent with the Operator's directive, surfaced for explicit confirm).

GATE (Director read the artifacts, not the report): emq.2.design.md is build-grade — five steelmanned ADRs (ADR-0 from-scratch-not-converter resolving §10 seam 1 on the no-release precondition; ADR-1 the reads→ops→observability carve, dependency-ordered, one-increment-one-run; ADR-2 the parity/family boundary de-conflicting emq.3–emq.8 with a per-family KEEP-vs-floor table + the two-layer telemetry split surface@emq.2.3/proof@emq.8; ADR-3 the stalled plane = worker-side lock-extension + explicit sweep beside the as-built reaper; ADR-4 events+telemetry on the EXISTING pub/sub seam, NO SSUBSCRIBE per §12.3). Every deliverable traces to a real v1 module/Lua anchor (file:line table in §0) or a design §. The emq.2.1 exemplar triad+prompt SHIPPED (Venus-1 Y-2: coverage closure D→US verified; conformance count 18 used as the byte-unchanged contract; grounding held).

ARM A RATIFIED. The parity cluster (emq.2.1/2.2/2.3) fills the v1 operational FLOOR echo_mq lacks (reads · ops · observability); emq.3 (flows) / emq.4 (groups deepened) / emq.5 (batches) / emq.6 (distributed cancel/TTL/checkpoints) / emq.7 (cache) / emq.8 (proof stack) KEEP their confirmed Stage-1b slots + content; the cluster fills the gap BELOW the families, does not subsume them. GROUND: the Operator's own "emq.2.1 + emq.2.2 + emq.2.3" directive = exactly a 3-rung cluster (Arm A); both arms reach full parity (floor + families); Arm B re-sequences a confirmed ladder + emq3.x's hard-gate for zero parity gain. This is the Director ratifying the Operator's IMPLIED direction, not overriding an open fork — SURFACED in the handoff for explicit confirm/override (Arm B = a cheap roadmap edit before any build, per ADR-2/§6).

PROCEED: fan out Venus-3 (emq.2.2 operator plane) ∥ Venus-4 (emq.2.3 watch plane) from the ADR's fixed carve, to Arm A. The legacy emq.2.* files (migration body) are SUPERSEDED by the emq.2.1/2.2/2.3 cluster — disposition (delete vs stub) deferred to the handoff (recorded, not assumed). Framing residue in the roadmaps ("push source"/"dissolves"/version mentions outside the banned set) noted for an optional Operator-directed tightening pass — not a gate blocker (the emq.2 reframe is grep-clean of the banned 1.3.1/old/legacy/migrate-from set).

### D-11

D-1 (Venus-4, emq.2.3) — the lock-extension verb RE-SCORES the active ZSET member; it does NOT port the v1 separate lock-string key

The carve (ADR-3) names a "lock-extension verb on EchoMQ.Jobs (re-score the active-set member to a fresh lease deadline from the server clock, refusing EMQSTALE on a stale token — declared keys, the DQ-2c server-clock law)". The build-shaping fact this triad fixes (grounded, not invented): the v2 bus's lease IS the active ZSET score (jobs.ex:135 @claim `ZADD KEYS[2], now + lease, id`), so the extension verb re-scores that member to TIME+lease under declared keys [active, job_key], token-fenced on the attempts field (the @complete EMQSTALE pattern jobs.ex:142-144). The v1 extendLock-2.lua form — a SEPARATE string key `emq:{q}:j:<id>:lock`, GET==token → SET PX — is STRUCTURALLY inexpressible/unnecessary under the v2 single-ZSET lease and is NOT ported (the program law: port the capability, never the v1 form). This is the architect's parity carving (skill §3), grounded in the as-built @claim/@complete scripts + design DQ-2c (server clock) + §5 (EMQSTALE reuse, no new wire class). Recorded as a spec INV + the design-gate ruling the build adopts (it is NOT a re-design of the canon — the canon is reconcile-only).

### D-12

D-3 (Venus-3) — emq.2.2 triad locks the carve to the v2 four-set model + names the design-gate forks (build-shaping, not architecture)
emq.2.2 = the operator plane (lifecycle & mutation ops), authored to the FIXED carve (emq.2.design ADR-1 §2, Arm A ADR-2). The triad locks these CONTRACTS (each grounded, no architecture decided — the open forks are surfaced to the design gate / Operator, never ruled here):

1. RE-DERIVE against the v2 four sets, not the v1 model. Every verb operates over pending/active/schedule/dead + the §6-registered metrics:/job:<id>:logs/de: keys. The v1 legacy v1 set model (wait/paused-LIST/completed/failed/prioritized/waiting-children) does NOT exist; the v1 scripts are the capability reference, never the form. So: drain removes the `pending` ZSET (+ optionally `schedule`), obliterate destroys the four sets + the §6 aux keys (no completed/failed set), reprocess_job moves `dead`→`pending` (the "retry a failed job" surface — no completed set).

2. NEW module EchoMQ.Admin (or Ops) for the queue-scope verbs (pause/resume/drain/obliterate); the job-mutation verbs (update_data/update_progress/add_log/get_job_logs/remove_job/reprocess_job) land on EchoMQ.Jobs beside the state machine. Exact placement = the design-gate's reductive call (≥2 steelmanned alternatives), recorded at the build.

3. Queue-wide pause is DISTINCT from Lanes' per-group pause (Lanes.pause/3 = one group via SADD `paused`+LREM ring). Queue-wide pause gates the WHOLE claim. SURFACED FORK (design gate, possibly the Operator): the as-built `claim` (ZPOPMIN, jobs.ex) has no pause gate — realizing queue-wide pause either (a) adds a meta/`{emq}:`-flag check to the @claim transition (touches emq.1's shipped script — INV1 byte-unchanged-conformance care), or (b) realizes pause as a separate gate the public claim/3 reads before the script. Recommended (a) as the atomic form; the build's design-make rules it with steelmen.

4. Lock/precondition typed refusals need an EMQ* class (§5 additive minor with a probe): v1 removeJob refuses a locked job (return 0), obliterate refuses non-paused/active (-1/-2), reprocess refuses wrong-state (-3). The exact class word(s) (e.g. EMQLOCK for a held-job refusal, EMQSTATE for a wrong-state/not-paused refusal) = the design-gate's §5 call, registered with conformance probes. The five-code fence union stands unextended.

5. The lock primitive these refusals read (the `job:<id>:lock` subkey, §6 closed sub-set) is the worker-side lock plane's WRITE surface — emq.2.3's (ADR-3). emq.2.2 READS lock presence for the remove refusal but does not ship the lock-extension verb (emq.2.3). Recorded as the cross-rung boundary.

### D-13

D-2 (Venus-4, emq.2.3) — the watch-plane deliverable carve + the conformance scenario set

emq.2.3's deliverables map to ADR-3 (the stalled plane) + ADR-4 (the event+telemetry plane), dependency-ordered behind a design-make gate (the emq.1/emq.2.1 relocated-gate precedent):
- D1 design-make (FIRST gate) — adopt ADR-3/ADR-4; rule (a) the EchoMQ.Events placement + the channel name (a queue_key suffix vs the {emq}: reserve) + the event payload contract (which lifecycle facts publish, and where they're emitted — host-side after a transition verdict, NOT a new Lua emit, since the as-built transition scripts return verdicts the host already sees), (b) the EchoMQ.Telemetry event-name tree under [:emq, …], (c) the lock-extension verb's name/return + the worker-side lock-plane process name (lock_manager) + its opt-in supervised shape (the Pump precedent), (d) the stalled-sweep's stall-count mechanism beyond reap. ≥2 steelmanned alternatives where the spec leaves a fork.
- D2 EchoMQ.Events — per-queue event subscription over Connector.subscribe/2+unsubscribe/2; publish lifecycle events; auto-resubscribe keeps it live across reconnect. NO SSUBSCRIBE.
- D3 EchoMQ.Telemetry — attach/attach_many/emit/span over the lifecycle, re-rooted [:emq,…]; the v1 six events. SURFACE only (ADR-2: the proof stack is emq.8).
- D4 the lock-extension verb on EchoMQ.Jobs — re-score active member to TIME+lease, EMQSTALE on stale token, declared keys (D-11/the prior decision).
- D5 the worker-side lock plane — lock_manager: track/untrack held jobs, extend on a timer, release on completion; opt-in supervised process (Pump shape). A consumer without it is the unchanged v2 worker.
- D6 the explicit stalled-sweep — stalled_checker/moveStalledJobsToWait capability re-derived under TIME + the four ZSETs; a stall-count threshold beyond the dead-lease reap.
- D7 the cooperative cancellation_token — worker-side new/cancel/check; distributed cancel is emq.6.
- D8 proof — conformance scenarios + probes; the 18 prior byte-unchanged.

The conformance scenarios emq.2.3 ADDS (additive-minor law; names spelled, the build pins the exact set at D1/D8): a `lock_extend` scenario (a claimed job's lease is extended past its original deadline; the reaper does NOT reclaim it; a stale token is refused EMQSTALE), a `stalled` scenario (a job whose lease expired without extension crosses the stall-count threshold → recovered/dead per the threshold), an `events` scenario (a subscriber receives a lifecycle event — e.g. completed/failed — on the connector pub/sub seam), and a `telemetry` scenario (an attached handler receives an [:emq,…] lifecycle event). The exact set + count is the build's D8 call; the 18 prior names stay byte-unchanged and both pinning tests (conformance_scenarios_test @run_order + conformance_run_test {:ok, 18}) update to the new total in the same change. This is the architect's deliverable carve from the v1 inventory + the design ADRs (NOT a re-design of the canon).

## {emq-2-alternatives} Alternatives

### V-1 — Skill-set SHAPE: three per-role skills vs one shared skill

OPTION A (CHOSEN) — THREE per-role skills (echo-mq-architect, echo-mq-implementor, echo-mq-evaluator), each a focused craft manual + a SHARED references/ file (the v2 laws, the gate ladder, the roadmap, the as-built surface map, NO-INVENT, no-git) all three point at.
+ Each spawn reads ONLY its role's craft — no wading past 2/3 irrelevant material (the apollo "keep the definitions lean" principle).
+ The role-distinct craft is genuinely distinct (triad/reconcile/carve vs spec-cited-build-inside-boundary vs the §11.2 adversarial verify) — a real separation, not an artificial split.
+ The common program law is itself single-source (the shared references/ file), so a v2-law correction lands once.
- Three files to keep in sync IF the common law lived in each — mitigated by the shared references/ file carrying the common law.

OPTION B (rejected) — ONE shared echo-mq-dev skill all three roles load.
+ One file.
- Forces each spawn to read past the other two roles' craft every rung — the bloat the team's own lean-definition discipline warns against; the architect does not need the §11.2 adversarial-verify recipe, the evaluator does not need the carve-the-parity-surface method.
- Conflates three distinct contracts into one — harder to mentor (Apollo folds a build-fidelity lesson into the implementor skill, a brief-fidelity lesson into the architect skill; one shared file blurs WHERE a lesson lands).

DECISION: A. Three role skills + one shared references/ file for the common program law. The role-distinct craft is the skill body; the program-wide law is the shared reference. This is the DRY-correct split: distinct-by-role in three bodies, common-by-program in one reference.

### V-2 — Charter-integration SHAPE: additive "## echo_mq program" block vs dedicated *-echomq charter variants

OPTION A (CHOSEN) — ADDITIVE block. Add ONE "## echo_mq program" section to each of venus/mars/apollo.md: the roadmap pointer, "load the <skill> skill when on an emq.* rung", and the small program-specific delta (the v2 laws named, the per-app/Valkey-6390/determinism-loop specifics, the conformance additive-minor law, no-git). PRESERVES every existing cross-program line (portal/mercury/redis/elixir) verbatim — additive diff only.
+ The shared program-NEUTRAL discipline (reconcile, cite-don't-invent, done-is-a-closure, the design phase, the mentoring loop) IS the echo_mq discipline too — no duplication; a future portal/redis lesson applied to the charter automatically serves echo_mq.
+ One file per role, one git history, one place the Operator reviews.
+ Matches D-5 exactly ("an additive tuning … additive diff only, no removal of existing cross-program content").

OPTION B (rejected) — DEDICATED venus-echomq / mars-echomq / apollo-echomq charter variants (separate .md files).
+ A fully echo_mq-focused charter with nothing else.
- FORKS the shared craft: every guardrail a future portal/redis rung earns must now be applied TWICE (the generic charter AND the echomq variant) — the exact maintenance-debt the team's single-source discipline exists to prevent; the charters already carry deep cross-program F6.x lessons that would have to be mirrored.
- A new agent registration surface (the x-mode protocol spawns general-purpose + adopts .claude/agents/<role>.md; a *-echomq variant would need its own wiring) for no behavioral gain over A — the skill already carries the program craft.

DECISION: A. The charter stays ONE per role, additively tuned; the program craft lives in the skill the block points at. The shared discipline is preserved as the single authority it already is.

### V-3 — the ladder-disposition arms (steelmanned), for the carve decision D-7

ARM A — PARITY CLUSTER FILLS THE GAP BELOW emq.3-emq.8 (leave them as-is). emq.2.1/2.2/2.3 ship exactly the v1 parity surface NO existing rung owns (introspection/metrics · lifecycle ops · events/telemetry/recovery). emq.3 (flows), emq.4 (groups deepened), emq.5 (batches), emq.6 (lifecycle: cancel/checkpoints), emq.8 (conformance/telemetry/benchmark) keep their slots + content. Steelman: emq.3-emq.8 are CONFIRMED at the Stage-1b checkpoint; emq3.x stream tier hard-gates on the ladder; the families they ship (flows/groups-deepened/batches) are genuinely LATER capability families, not the v1 floor echo_mq lacks today — re-sequencing them buys zero parity and risks the confirmed plan. The parity gap is real and self-contained: read verbs, operator mutations, the observability plane. Counter-example tested: does emq.2.3 "telemetry" collide with emq.8 "telemetry contract"? NO — emq.2.3 ports the v1 EchoMQ.Telemetry emit/attach surface (the events FIRE); emq.8 ships the conformance+matrix+benchmark PROOF STACK that asserts the telemetry contract. Two layers, one names the surface, one proves it — the same split bcs3.x used for EMQKIND (the key lets it pass, the law proves it). RESIDUAL RISK: a reviewer could read "FULL feature parity, every module" as subsuming flows/groups/batches into the cluster too. Mitigation: the ADR's ladder-reconciliation table names each existing rung's disposition explicitly + surfaces the sequencing as a fork to the Operator.

ARM B — PARITY CLUSTER SUBSUMES THE FEATURE RUNGS (re-sequence emq.3-emq.8 into emq.2.N). Read "every module + every Lua script" maximally: the cluster IS the whole v1 rewrite, so flow_producer→emq.2.x, groups-deepened→emq.2.x, etc., and emq.3+ renumber or vanish. Steelman: one coherent "parity rewrite" deliverable, no gap between "parity" and "the families"; matches the Operator's "full parity" phrasing most literally; the /echomq + /redis-patterns courses then teach one convergence cluster, not a split. WHY REJECTED: (1) blast radius — emq.3-emq.8 are CONFIRMED (Stage-1b ruling) and emq3.x (the stream tier, PROPOSED) hard-gates on emq.0 + sequences against this ladder; re-sequencing forces re-ratification of confirmed plans for zero parity gain. (2) granularity — flows (488 LoC v1 + the A-1-compatible flow design that is "real design work," design §11.10), groups-deepened (control plane + recovery + weighted rotation), batches (bulk-consume + affinity + partitioned finish) are each a FULL rung of their own; cramming them into a 3-rung cluster violates one-increment-one-run. (3) the parity GAP (the v1 floor echo_mq lacks NOW — reads/ops/observability) is distinct from the FAMILY DEPTH those rungs add; conflating them loses the dependency order (you cannot deepen groups before the group introspection reads exist).

ARM C — DO NOTHING / KEEP emq.2 AS MIGRATION. Reject by D-1/D-2: the Operator RETIRED migration; echo_mq is built fresh, nothing to migrate FROM. The slot must be re-purposed.

DECISION GROUND: Arm A. The parity cluster is the v1 FLOOR (reads · ops · observability) that echo_mq lacks today; the existing emq.3-emq.8 are the later FAMILIES that build above the floor. The carve fills the gap, does not subsume the ladder. The sequencing (does the Operator want flows/groups/batches PULLED INTO the cluster?) is surfaced as the one fork the Director routes — Arm A is the recommended arm, not a unilateral ruling (venus charter: surface forks, never decide them).

## {emq-2-learnings} Learnings

### L-1

L-3 (Venus-2) — The skill is the DRY home for program craft; the charter block is a thin pointer. The decisive design insight: the build-team charters ALREADY carry the program-neutral discipline (reconcile, cite-don't-invent, done-is-a-closure, the design phase, the mentoring loop) — that IS the echo_mq discipline. So the additive charter tuning must add ONLY the program-specific delta (the v2 laws named, the per-app/Valkey-6390/determinism specifics, the skill pointer), NOT re-state the shared craft. The full program craft lives in the skill, so a charter block stays ~15 lines and the cross-program service is preserved untouched. This mirrors the team's own single-source-of-truth law applied reflexively to its OWN tooling: the v2-laws table lives once (the shared echo-mq-program.md reference all three skills cite), the role-distinct craft lives once per role (the SKILL.md body), the pointer lives once per charter. A correction to a v2 law lands in one file; a correction to a role's reconcile method lands in one SKILL.md; a future portal/redis lesson to a charter serves echo_mq for free. The relative-path arithmetic is load-bearing and was verified against the real tree (../../docs/echo_mq from .claude/skills/; ../echo-mq-program.md sibling from a SKILL.md dir) — a broken cite in a skill is the same gate-invisible defect class as a stale spec claim.

### L-2

L-1 (Venus-3) — the parity rung's headline craft: RE-DERIVE against the v2 four-set model, never transliterate the v1 form
The operator-plane verbs (drain/obliterate/remove/reprocess/pause) read NATURALLY against legacy v1's set model (wait/paused-LIST/completed/failed/prioritized/waiting-children), but the as-built v2 bus is pending/active/schedule/dead with completion-DELETES. The grounding work that makes a parity rung honest is the re-derivation, captured in INV3 + stated in every Deliverable:
- drain empties `pending` (+ optional schedule), NOT wait+paused LISTs;
- obliterate destroys the four sets + §6 aux keys, NOT completed/failed/waiting-children;
- reprocess is `dead`→`pending` (the bus's only finished-and-retained state), NOT completed/failed→wait;
- queue-wide pause is a claim GATE (the bus has no wait↔paused LIST to RENAME), DISTINCT from Lanes' per-group park.
The v1 `data` field maps to the as-built `payload` field. Two real seams surfaced for the build's design gate (NOT decided): (a) the queue-wide pause gate's placement (inside the shipped @claim — atomic but INV1-byte-unchanged-risk — vs a separate gate the public claim/3 reads); (b) the §5 EMQ* class word(s) for the precondition refusals (locked/not-paused/live-active/not-dead). Both are additive minors registered with probes; the five-code fence union stands. This is the pattern emq.2.3 (the watch plane) reuses: the event seam update_progress emits + the lock subkey remove reads are emq.2.3's write surface, named as the cross-rung boundary.

### L-3

L-1 (Venus-4, emq.2.3) — the watch-plane rung re-introduces the ≥100 loop the read/op rungs dropped; the runbook risk tier MUST track the process delta

The emq.2 cluster's three rungs have DIFFERENT risk tiers driven by ONE fact — does the rung add a process? emq.2.1 (read plane) + emq.2.2 (operator plane, synchronous mutations) are no-new-process rungs: their runbooks correctly drop the ≥100 determinism loop (synchronous deterministic verbs) and run a SOLO Director review (no Apollo). emq.2.3 (watch plane) re-introduces opt-in PROCESSES — the worker-side lock plane + the explicit stalled sweep, both timer-driven — exactly as emq.1's Pump did. So emq.2.3's runbook MUST (and does) (a) require the ≥100 loop for the process-touching suites, machine-owned, and (b) raise the risk tier to moderate with a DEDICATED Apollo evaluator (the process-and-lease tier, x-mode §11.3), because the substantive correctness risk is a timer-driven lease-extension RACING the reaper — a hazard a single green run cannot expose (the F5.4/F5.6/F5.7 same-ms collision precedent: the independent loop, not the implementer's run, is the gate). The architect lesson: when carving a cluster, the per-rung runbook's loop-requirement + Apollo-tier is a FUNCTION of the process/lease delta, not a cluster-wide constant — author it per rung from the deliverable shape (a new GenServer/timer or a new lease transition → loop + Apollo; pure reads/synchronous mutations → solo Director, no loop). This mirrors the portal F0/presentation-rung learning (presentation rungs drop the ≥100 loop) inverted: a PROCESS rung re-arms it.

## {emq-2-report} Report

### Y-1

Y-3 (Venus-2) — the agent-tooling design spec is on disk, ready for the Director to write the .claude files FROM.

DELIVERED (docs-only, uncommitted): docs/echo_mq/specs/emq-2.tooling-design.md (~470 lines). It DESIGNS, the Director WRITES — no .claude file created/edited by Venus-2.

THE SHAPE (D-7/D-8): three per-role dev skills + ONE shared references file + one additive charter block per role.
- SKILLS (3 + 1 shared): echo-mq-architect (venus), echo-mq-implementor (mars), echo-mq-evaluator (apollo), each .claude/skills/<name>/SKILL.md with FULL frontmatter + body content the Director writes verbatim. The shared .claude/skills/echo-mq-program.md (flat sibling, single-source) carries the common law: the v2-laws table (S-1..S-7 braced/branded/declared-keys/server-clock/honest-row/one-time-fork+additive-minor), the gate ladder (asdf re-probe · Valkey 6390 PONG · per-app compile --warnings-as-errors · per-app suites NEVER umbrella-wide · Conformance.run/2 · the ≥100 determinism loop owning the machine), the conformance additive-minor law (extend scenarios/0 + register the probe + prior N byte-unchanged; as-built 18), the roadmap awareness (emq.0→emq.8 + the master invariant + the emq.2.x parity cluster + the seams), NO-INVENT grounding, the process locks (no-git, pathspec, escalate-don't-invent). An optional adjunct echo-mq-surface.md maps the real module/Lua/key names (the NO-INVENT anchors). All relative paths VERIFIED against the tree.
- CHARTER TUNINGS (3): the EXACT "## echo_mq program" block for each of venus/mars/apollo.md, with the PLACEMENT named (immediately before the final "## Scope + framing"). ADDITIVE diff only — every cross-program line (portal/mercury/redis/elixir F6.x craft, design phase, mentoring loop) preserved. Each block = a thin skill-pointer + the roadmap+master-invariant line + the program guardrails the shared charter doesn't already state.

THE RATIONALE (both shape calls, in §6):
- THREE per-role skills, not one shared (V-1): the role craft is genuinely distinct (architect triad/reconcile/carve · implementor spec-cited-build-inside-boundary+Lua-laws · evaluator §11.2 adversarial-verify); one shared skill forces each spawn past 2/3 irrelevant craft (the apollo "keep definitions lean" rule). The COMMON law lives once in the shared reference all three cite — DRY-correct.
- ADDITIVE charter blocks, not dedicated *-echomq variants (V-2): the shared program-NEUTRAL discipline the charters carry IS the echo_mq discipline; a variant FORKS it (every future portal/redis lesson applied twice — the maintenance debt the single-source discipline prevents). The program delta is small, bolts on as one section — exactly D-5's shape; the Operator's instruction is the peer-def grant (portal-leadteam-governance).

GROUNDING: every fact cited to the canon (emq.design.md S-1..S-7/§2/§3/§5/§6/§10/§11/§12, emq.roadmap.md ladder+master-invariant+seams, echo_mq.md milestones) or the as-built craft (emq-1.progress.md: per-app testing, TMPDIR=/tmp, Valkey 6390 PONG, --warnings-as-errors, the determinism loop, inline Script.new/2-not-priv/, the conformance 14→18 additive-minor law, the lag-1 reconcile, realization-over-literal, L-6 pre-existing-is-two-facts). NO-INVENT: the as-built surface map probed live (echo_mq/lib = backoff/conformance/consumer/jobs/keyspace/lanes/pool/pump+core/repeat; echo_wire/lib = connector/resp/script+echo_wire.ex; conformance scenarios/0 = 18, verified).

SELF-CHECK (clean): framing — zero perceptual/interior-state verbs, zero gendered agent pronouns (grep-verified); the propagation clause is in the doc header and in every skill/charter block; D-2 zero-migration-framing honored (the only "legacy" hit is inside the prohibition clause itself); relative paths resolve (../../docs/echo_mq from .claude/skills/; ../echo-mq-program.md sibling). Docs-only, uncommitted — left for the Director.

### Y-2 — Venus-1 deliverable (1)+(2) COMPLETE; (3) = carve-precise-enough-to-fan-out (path stated)

DELIVERABLE (1) — THE PARITY ADR + THE RECONCILED ROADMAPS. SHIPPED.
- docs/echo_mq/specs/emq.2.design.md — NEW. The full-parity design in the emq.1.design.md precedent shape: §0 context (the re-scope + the as-built floor + the v1 capability-reference table) · ADR-0 (the crossing is a FROM-SCRATCH rewrite, NOT a converter — design §10 seam 1 RESOLVED on the no-release precondition §11.11: drain-precondition, no migration tool/tombstone/v1-patch) · ADR-1 (THE CARVE: emq.2.1 read plane → emq.2.2 operator plane → emq.2.3 watch plane, dependency-ordered, one-increment-one-run, with the full carve table) · ADR-2 (THE PARITY/FAMILY BOUNDARY — the per-family table naming what each confirmed emq.3-emq.8 rung KEEPS vs the floor the cluster builds below it; the two-layer telemetry split surface@emq.2.3 / proof@emq.8) · ADR-3 (the stalled plane: explicit sweep + worker-side lock plane beside the as-built reaper) · ADR-4 (the event+telemetry plane on the EXISTING pub/sub seam, no SSUBSCRIBE — design §12.3) · §6 the surfaced fork · §7 the roadmap reconciliation · §8 out-of-scope.
- THE LADDER-RECONCILIATION SETTLED + RECORDED: the parity cluster takes the emq.2 slot; OLD emq.2 (migration) RETIRES as a non-feature; emq.3 (flows) / emq.4 (groups deepened) / emq.5 (batches) / emq.6 (cancel/checkpoints) / emq.7 (cache) / emq.8 (proof stack) KEEP their confirmed slots + content — the cluster fills the floor BELOW them, does NOT subsume them (Arm A). emq3.x stream tier's hard-gate on emq.0 unchanged.
- ROADMAPS RECONCILED (3 files, grep-clean of 1.3.1/old/legacy/migrate-from): emq.roadmap.md (Movement-I Why/What reframed; the emq.2 ladder row → the 3-rung parity cluster; the Where line → apps/echomq as capability REFERENCE; seam 1 flipped OPEN→RULED drain-precondition) · emq2.roadmap.md (the Movement-I summary + the emq.2 row mirrored) · echo_mq.md (the Movement-I one-liner + the emq.2 ladder row's Ships+Unblocks → "the operational floor every consumer reads through"). The legit "Movement 0 · BCS Migration" (the unrelated echo2-migration record) PRESERVED — not blanket-erased.

DELIVERABLE (2) — THE emq.2.1 EXEMPLAR TRIAD. SHIPPED (4 files, the emq.1 triad shape precedent):
- emq.2.1.md (the spec body, authoritative): Goal · 5W · Scope · D1-D8 · INV1-INV7 · DoD. The read plane: counts-by-state over the AS-BUILT four sets (pending/active/schedule/dead — NOT the v1 state list; NO completed set under completion-deletes, so "completed" reads the metrics counter), job+state lookup gated by BrandedId.valid?/1, the metrics read with no-phantom-counter, the dedup read, the rate-limit read + the EMQ*-classed at-ceiling gate (design §5), per-lane introspection over Lanes.depth/2.
- emq.2.1.stories.md (US1-US8 Connextra + GWT + the standing EMQ.2.1-US-GATE Valkey story; Coverage closure D1→US7…D8→US8 — VERIFIED complete + bijective).
- emq.2.1.llms.md (the Mars brief: References-in-order · Requirements R1-R8 traced US→INV · Execution topology with the build-order DAG + exact files touched · Agent stories AS-1..AS-8 as Directive+Acceptance-gate contracts · the comprehensive prompt).
- emq.2.1.prompt.md (the x-mode 5-stage runbook: pre-Stage-1 fork gate · the design-make · the as-built floor RE-PROBE · Mars-1→Director-review→Mars-2→Venus-reconcile→Director-closure · the Stage-5 pathspec; risk-tier = low, no Apollo required, NO ≥100 determinism loop since the rung adds no process).

GROUNDING (NO-INVENT held): every emq.2.1 deliverable traces to a real v1 read script (getCounts-1/getState-8/getMetrics-2/getRateLimitTtl-2/isMaxed-2.lua) as the capability reference + the as-built echo_mq structures (jobs.ex four sets, keyspace.ex job_key gate, lanes.ex depth/2, conformance.ex 18 scenarios) as the floor + the design § for every grammar/wire-class claim. Conformance count = 18 (VERIFIED live), used as the byte-unchanged contract throughout. The echo-mq-architect skill (Venus-2's craft) was loaded post-authoring and CONFIRMS every convention (inline-not-priv · count-is-a-claim · zero-migration-framing · the carve shape) — strong convergence.

DELIVERABLE (3) — emq.2.2 + emq.2.3: PATH TAKEN = carve precisely enough to fan out (NOT authored solo). RATIONALE: (a) the ADR's carve table (ADR-1) + the parity/family boundary table (ADR-2) FIX the exact deliverables/invariants/grounding/dependency-position for emq.2.2 (lifecycle & mutation ops — pause/drain/obliterate/update_data/update_progress/add_log/remove_job/reprocess_job, v1 anchors pause-7/drain-6/obliterate-2/updateData-1/updateProgress-3/addLog-2/removeJob-12/reprocessJob-8.lua) and emq.2.3 (observability & recovery — events/telemetry/stalled-sweep+lock-plane/cooperative-cancel, v1 anchors queue_events.ex/telemetry.ex/stalled_checker.ex+moveStalledJobsToWait-9/lock_manager.ex+extendLock(s)/releaseLock/cancellation_token.ex). (b) The fan-out pattern (spec-write → spec-author agents per rung) is the program's idiom + faster than solo. (c) MOST IMPORTANT: the §6 sequencing fork must be Operator-ruled FIRST — if the Operator rules Arm B, emq.2.2/2.3 re-scope, so authoring them now risks wasted work against an unratified carve. The emq.2.design.md forward-links ./emq.2.2.md + ./emq.2.3.md are intended targets the fan-out creates.

THE ONE FORK SURFACED (Operator's call, per the venus charter): the parity/family sequencing — Arm A (recommended; cluster fills the floor, emq.3-emq.8 keep their slots) vs Arm B (pull the feature families into the cluster). Everything authored to Arm A; an Arm-B ruling is a cheap roadmap edit before any build.

VERDICT: BUILD-GRADE for the carve + the emq.2.1 exemplar (every claim grounded in a real anchor or design §; coverage closure verified; links resolve except the two intended fan-out targets; conformance count true). NO code, NO git (design+spec phase). Handing the carve back to the Director: gate the carve (+ route the fork to the Operator), then fan out spec-author agents for emq.2.2 + emq.2.3 OR have Venus-1 author them on an explicit continue.

### Y-3

Y-1 (Venus-3) — emq.2.2 (the operator plane) full triad + prompt authored, BUILD-GRADE
4 files authored to the FIXED carve (emq.2.design ADR-1 §2, Arm A), matching the emq.2.1 exemplar shape exactly:
- emq.2.2.md — Goal · 5W · Scope(In/Out) · D1..D10 · INV1..INV8 · DoD. D1 = the design-make gate; INV8 = the SPECCED-not-shipped gate.
- emq.2.2.stories.md — US1..US10 Connextra + GWT + INVEST/Priority/Size; US10 = the standing EMQ.2.2-US-GATE Valkey story; Coverage BIJECTION D1→US9 … D10→US10.
- emq.2.2.llms.md — References(7, in order) · Requirements R1..R10 (R→US→INV) · Execution topology (runtime + build DAG + exact files) · Agent stories AS-1..AS-10 (Directive+Acceptance gate) · the comprehensive prompt.
- emq.2.2.prompt.md — the x-mode runbook: Flat-L2, slug emq-2-2, the 4 design-make decisions, the as-built floor (re-probe), the 5-stage pipeline, the Stage-5 pathspec, the risk tier, acceptance.

VERDICT: BUILD-GRADE. Reconcile clean (T-8): every operator verb grounds in a real v1 Lua anchor (all 8 verified to exist) + the §6 grammar + the as-built four-set floor; zero INVENTED surface. Gates pass: traceability closure bijective (D↔US↔R↔AS, 10 each; INV1..8); NO-INVENT (every cited arity real — Jobs.complete/4, @claim ZPOPMIN, Lanes.pause/3, Keyspace.job_key/2+BrandedId.valid?, EchoMQ.Repeat, Conformance.scenarios/0+run/2); voice CLEAN (third-person, no interior-state verbs); ZERO migration/legacy framing.

The two design-gate forks SURFACED (not decided — D-12): (a) queue-wide pause placement (gate-in-@claim vs separate gate); (b) the §5 EMQ* refusal class word(s). The determinism loop posture declared: it DOES apply (the suites mint branded ids — the same-ms collision hazard), unlike read-only emq.2.1 which skipped it. Risk tier: low-moderate (above emq.2.1 — destructive verbs + a possible @claim edit), no Apollo charter required unless @claim is edited and the claim scenario is not byte-identical.

### Y-4

Y-1 (Venus-4) — emq.2.3 watch-plane triad + prompt AUTHORED, BUILD-GRADE

The 4 files (docs/echo_mq/specs/):
- emq.2.3.md — Goal · 5W · Scope · D1–D8 · INV1–INV8 · DoD. The watch plane: EchoMQ.Events (ADR-4, connector pub/sub seam), EchoMQ.Telemetry ([:emq,…] surface, ADR-4+ADR-2 two-layer), the lock-extension verb on EchoMQ.Jobs (ADR-3, re-score active member to TIME+lease, EMQSTALE), the opt-in worker-side lock plane (ADR-3, Pump shape), the explicit stalled-sweep (ADR-3, beyond reap/2), the cooperative cancellation_token (ADR-3, worker-side half).
- emq.2.3.stories.md — US1–US8 Connextra + GWT; US8 = the standing EMQ.2.3-US-GATE (Valkey 6390 + the ≥100 loop); Coverage closure D1→US7·D2→US1·D3→US2·D4→US3·D5→US4·D6→US5·D7→US6·D8→US8 (complete bijection).
- emq.2.3.llms.md — References (read-first), the R1–R8 requirements table (each → a US, → an INV/check), the execution topology + build-order DAG + exact files, AS-1–AS-8 (Directive + Acceptance gate), the comprehensive prompt + the propagation clause.
- emq.2.3.prompt.md — the x-mode SIX-stage runbook (Mars-1 → Director review → Mars-2 → APOLLO → Venus → Director-close), the design-make rulings, the as-built floor (re-probe), the ≥100-loop mandate, the moderate risk tier + Apollo-warranted, the Stage-6 pathspec, "emq.2 cluster COMPLETE" on close.

Coverage-closure check: PASS. D1–D8 ↔ US1–US8 complete bijection; INV1–INV8 declared in .md, referenced in every stories' encodes line + every brief To-column.

The no-SSUBSCRIBE / no-emq.8-proof boundary HONORED:
- Every SSUBSCRIBE occurrence is the prohibition (design §12.3 deferral / the Apollo grep-expect-empty probe) — never built. EchoMQ.Events rides the EXISTING Connector.subscribe/2+unsubscribe/2 seam (the {:emq_push,…} push + the resubscribe MapSet).
- emq.8 = the telemetry CONTRACT (ADR-2 two-layer split); emq.2.3 ships the SURFACE that fires, never emq.8's proof.
- emq.6 = the DISTRIBUTED cancel (out of scope; emq.2.3 ships the worker-side cooperative half); emq3.2 = the durable replayable stream (out of scope).
- EMQSTALE reused (the existing fencing-token class) — no new wire class, the five-code fence union stands unextended.

Process/risk: emq.2.3 adds opt-in PROCESSES (the lock plane + the stalled sweep, both timer-driven) + a new lease transition → the runbook REQUIRES the ≥100 determinism loop for the process-touching suites (DoD + INV8 + the runbook's `for i in $(seq 1 100)` machine-owned) and declares a MODERATE risk tier with a DEDICATED Apollo evaluator warranted (Stage 4).

Anchors: EVERY surface grounded — no escalation needed. ADR-3 lock-extension = the @claim re-score (jobs.ex:135) + the @complete EMQSTALE fence (jobs.ex:142-144); ADR-4 events = Connector.subscribe/2 + resubscribe MapSet (connector.ex:108,606); telemetry = Connector.emit/3 zero-cost precedent (connector.ex:634-640); the process shape = EchoMQ.Pump :transient/opt-in (pump.ex:31-38,7-9). The v1 capability anchors all probed (lock_manager/stalled_checker/telemetry/queue_events/cancellation_token + the 4 .lua). The v2-rewrite delta recorded as D-11 (re-score, NOT a v1 …:lock string) + D-13 (the deliverable carve + the conformance scenario set).

Framing: third person throughout; zero gendered pronouns / perceptual verbs (verified); zero legacy/migrate-from framing (the only "migrated from" hits are the mandated NO-MIGRATION assertions). The propagation clause is in the brief + the prompt.

VERDICT: BUILD-GRADE. The emq.2.3 triad derives from the RATIFIED Arm-A carve (ADR-1/2/3/4), grounds every surface in a real v1 anchor + a design §, honors the two-layer (surface/proof) + the worker-side/distributed boundaries, and the master invariant (18 prior byte-unchanged + new scenarios probe-registered, no wire break, declared keys, server clock, branded ids). No fork surfaced (the one cluster fork — Arm A vs B — is design §6, already at the Operator). Files left in the working tree; no git.

### Y-5

Y-7 (Director) — emq-2 design + tooling phase COMPLETE; build-grade; handed off for restart-activation. NO commit (D-6 — design phase; the Operator commits out-of-band, the restart reloads the tooling).

THE TEAM (LAW-1 held): director + Venus-1∥Venus-2 (parallel: specs ∥ tooling) + Venus-3∥Venus-4 (parallel: emq.2.2 ∥ emq.2.3 fan-out) — 5 real general-purpose spawns adopting the venus charter, all self-registered, no FAKE-N. Pipeline = solo-Director design phase (D-3, the Operator's collapse; no Apollo this session).

DELIVERED + GATED (Director read every artifact, not the reports):
1. THE PARITY SPECS (Venus-1/3/4). emq.2.design.md (5 steelmanned ADRs; ADR-0 from-scratch-not-converter resolving §10 seam 1 on the no-release precondition; ADR-1 the reads→ops→watch carve; ADR-2 the parity/family boundary de-conflicting emq.3–emq.8; ADR-3 the stalled plane; ADR-4 events+telemetry on the existing pub/sub seam). The 3 triads + prompts: emq.2.1 (read plane — handles completion-deletes/no-completed-set + no-phantom-counter), emq.2.2 (operator plane — queue-wide-pause≠Lanes, excludes batch/distributed-cancel), emq.2.3 (watch plane — NO SSUBSCRIBE, telemetry-surface-not-emq.8-proof, cooperative-not-distributed-cancel, lease=active-score-not-:lock-string; self-escalates Apollo+determinism-loop for its build). ALL build-grade: coverage closure bijective, NO-INVENT (every verb → a real v1 anchor + design §), zero legacy framing, forward-tense. Roadmaps reconciled (emq.roadmap/emq2.roadmap/echo_mq.md). emq.progress.md dashboard reconciled to the cluster. Legacy emq.2.* (migration triad) given SUPERSEDED banners (reversible; delete deferred to the Operator).
2. THE TOOLING (Venus-2 designed, Director solo-wrote). 5 skill files (echo-mq-program + echo-mq-surface references + the 3 per-role SKILL.md, loader-registered) + 3 additive charter blocks (venus/mars/apollo +62/-0, cross-program service preserved).

THE ONE SURFACED FORK (Operator's call): the parity/family sequencing — Arm A (cluster fills the floor; emq.3–emq.8 keep slots — RECOMMENDED + everything authored to it; ratified D-10 as the Operator's implied direction per "emq.2.1+2.2+2.3") vs Arm B (subsume the families). Arm-B = a cheap roadmap edit before any build.

OPEN FOR THE OPERATOR (handoff): (a) confirm Arm A; (b) optional roadmap framing tightening — Venus-1's reconcile is grep-clean of the BANNED set (1.3.1/old/legacy/migrate-from) but residual "push source/dissolves/version" framing remains in the Movement-0 narrative + course bridge (accurate-in-context, the Operator's call on aggressiveness); (c) legacy emq.2.* — banners applied, delete if preferred.

THE BUILD SEQUENCE (next session, post-restart): emq.2.1 (read — risk LOW, solo-Director) → emq.2.2 (ops — solo-Director) → emq.2.3 (watch — Apollo §11.3 + ≥100 determinism loop, per its prompt). The team reloads echo_mq-specialized at restart. SCOPE held: zero code touched this phase; the Operator's mercury/portal/exchange out-of-band work excluded throughout.
