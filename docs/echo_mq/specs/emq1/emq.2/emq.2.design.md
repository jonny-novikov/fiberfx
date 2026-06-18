# EMQ.2 · The full-parity rewrite — the design (the carve, the ADRs, the ladder reconciliation)

> **Status: DESIGN — authored this run (emq-2), awaiting the Director's ratification of the carve + the
> Operator's ruling on the one surfaced sequencing fork (§6).** This is the architectural design the
> emq.2 spec triads derive from, in the [`./emq.1.design.md`](../emq.1/emq.1.design.md) precedent's shape (a
> context section, one ADR per architecture decision with steelmanned alternatives, the carve table, the
> consequences). emq.2 is **RE-SCOPED** by the Operator (emq-2 ledger D-1/D-2): from "the v1→v2 migration
> path" to a **full feature-parity rewrite of the v1 echomq capability surface into `echo_mq`** — every
> module and every Lua script the frozen v1 line provides, rewritten from scratch under the v2 laws, with
> **no compatibility layer and zero migration framing** (`echo_mq` is the single source of truth;
> `apps/echomq` is a feature reference only — the capability list to port, never a thing migrated from).
> The engine line is the program canon ([`../emq.design.md`](../../../emq.design.md) S-4 — Valkey, current
> stable, the gate). This document invents no feature: every deliverable traces to a real v1 module/Lua
> anchor or a design §.

## 0 · Context — the re-scope, the constraint, the as-built floor

**The re-scope (the Operator's ruling, emq-2 ledger D-1/D-2).** The three launch-gate questions returned
a reframe, not a settlement of the old emq.2 migration triad. echo_mq MUST reach **full feature parity**
with the v1 `echomq` line: the bus has the BCS state machine and the fair-lanes basics but not the whole
v1 capability surface, and the program's thesis — `apps/echomq` dissolves when nothing depends on what it
alone provides ([`../emq.roadmap.md`](../../../emq.roadmap.md) Movement I) — cannot close while the v1 line
alone carries introspection, the operator lifecycle verbs, and the observability plane. The crossing is
**from scratch, not a migration**: there is nothing to migrate *from* (the v2 line has never shipped —
[`../emq.design.md`](../../../emq.design.md) §11.11), so the prior emq.2 triad's intent (`migrate/4`
copy-verify-DELETE, the tombstone fence arm, the v1 maintenance-branch patch, drain-and-switch) is
RETIRED. `apps/echomq` is read only as the capability reference — the list of public surfaces to port.

**The parity constraint, stated once.** Every v1 public capability that no shipped `echo_mq` surface and
no later confirmed rung (emq.3–emq.8) already provides is rewritten into `echo_mq` under the v2 master
invariant: the braced `emq:{q}:` keyspace, branded `JOB` ids gated at the key builder, every Lua key
declared in `KEYS[]` or grammar-derived, the server clock on any lease, the closed wire-class registry
for typed refusals, honest-row conformance, additive-minor protocol growth. No rewrite re-breaks the
wire and none re-builds the state machine — the parity surface stands ON the as-built floor.

**The as-built floor (verified 2026-06-13 against the tree; the lag-1 anchors RE-PROBED at each rung's
build).** `echo_mq` already carries, and the parity rewrite builds on top of, never replaces:

- **The state machine** — `EchoMQ.Jobs` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`): `enqueue/4`,
  `enqueue_at/5`, `enqueue_in/5`, `enqueue_many/3`, `claim/3`, `complete/4`, `retry/7`, `promote/3`,
  `reap/2`, `browse/3`, `pending_size/2` over seven inline `Script.new/2` transitions (`@enqueue`,
  `@schedule`, `@claim`, `@complete`, `@retry`, `@promote`, `@reap`). The three-field row (`state`,
  `attempts`, `payload`), the four sorted sets (`pending` score-zero / `active` lease-scored / `schedule`
  run-at-scored / `dead`), attempts-as-token with `EMQSTALE`, completion-deletes, REV BYLEX browse, the
  server-clock `TIME`. **Shipped** (the 18 conformance scenarios assert it).
- **Fair lanes (basics)** — `EchoMQ.Lanes` (`lanes.ex`): `enqueue/5`, `claim/3`, `pause/3`, `resume/3`,
  `limit/4`, `depth/2` — per-**group** pause/resume/limit and round-robin rotation. **Shipped** (G1–G8;
  the *deepening* — control plane, recovery, weighted rotation — is emq.4).
- **The consumer + the cadence** — `EchoMQ.Consumer` (`consumer.ex`: `child_spec`/`start_link`/`stop`),
  `EchoMQ.Pump` + `EchoMQ.Pump.Core` (the promote+repeat sweep), `EchoMQ.Repeat`
  (`register`/`cancel`/`due`/`advance`/`count`), `EchoMQ.Backoff` (`delay_ms/2` —
  fixed/exponential/jitter). **Shipped** (emq.1).
- **The grammar + the transport** — `EchoMQ.Keyspace` (`keyspace.ex`: `queue_key/2`, `job_key/2`,
  `reserve/1`, `version_key/0`, `slot/1`, `hashtag/1`), `EchoMQ.Pool`, and the `EchoWire` facade
  (`echo/apps/echo_wire/lib/echo_wire.ex` — 9 `defdelegate`s + `script/2`). The connect-scoped
  `{emq}:version` fence on the connector. **Shipped** (emq.0/emq.1).
- **Conformance** — `EchoMQ.Conformance` (`conformance.ex`): **18 scenarios** (`fence`, `mint`,
  `duplicate`, `kind`, `order`, `claim`, `stale`, `complete`, `retry`, `dead`, `reap`, `rotate`,
  `pause`, `limit`, `schedule`, `repeat`, `backoff`, `resubscribe`). Every parity rewrite registers its
  own scenarios beside these (the additive-minor law), and these 18 pass byte-unchanged.

**The v1 capability surface (the reference to port — public APIs verified by `grep`, `file:line`).**

| v1 module (`echo/apps/echomq/lib/echomq/`) | The public capability | v1 Lua (`priv/scripts/`) |
| --- | --- | --- |
| `queue.ex` (2144 LoC — the API hub) | introspection: `get_counts`/`count`/`get_job_counts`/`get_job_count_by_types`; `get_job`/`get_job_state`/`get_jobs`(by states)/`get_waiting`/`get_active`/`get_delayed`/`get_completed`/`get_failed` (+ `_count` each); `get_meta`/`get_version`; `get_metrics`; `get_deduplication_job_id`/`remove_deduplication_key`; rate-limit: `get_global_rate_limit`/`get_rate_limit_ttl`; workers: `get_workers`/`get_workers_count`/`export_prometheus_metrics`. lifecycle: `pause`/`resume`; `update_meta`. | `getCounts-1`, `getState-8`, `getMetrics-2`, `getRateLimitTtl-2`, `isMaxed-2`, `pause-7` |
| `worker.ex` (1908 LoC) | `pause`/`resume`/`paused?`/`running?`/`active_count`; `cancel_job`/`cancel_all_jobs`/`active_job_ids`; `get_next_job`; the stalled-check timer; `update_progress`/`log`/`update_data`. | `addLog-2`, `updateData-1`, `updateProgress-3`, `moveStalledJobsToWait-9` |
| `flow_producer.ex` | `add/2`, `add_bulk/2` — parent/child flows. | (the flow add scripts) |
| `job_scheduler.ex` | CRON repeatables: `upsert`/`get`/`list`/`count`/`remove`/`remove_by_key`/`calculate_next_millis`. | — |
| `lock_manager.ex` | worker-side lock tracking: `track_job`/`untrack_job`/`get_active_job_count`/`get_tracked_job_ids`/`is_tracked?` + the `extend_locks` loop. | `extendLock-2`, `extendLocks-2`, `releaseLock-1` |
| `queue_events.ex` | the per-queue event stream: `subscribe`/`unsubscribe`/`close` + the `handle_event` behaviour. | — |
| `stalled_checker.ex` | `check/2`, `job_stalled?/4` + the periodic sweep. | `moveStalledJobsToWait-9` |
| `telemetry.ex` | `attach`/`attach_many`/`emit`/`span` + `job_added`/`job_started`/`job_completed`/`job_failed`/`job_retried`/`worker_started`. | — |
| `cancellation_token.ex` | cooperative cancel: `new`/`cancel`/`check`/`check!`. | — |
| (lifecycle ops, in `queue.ex`/scripts) | `drain`, `obliterate`, `removeJob`, `reprocessJob`. | `drain-6`, `obliterate-2`, `removeJob-12`, `reprocessJob-8` |

## 1 · ADR-0 — the crossing is a from-scratch rewrite, not a converter (design §10 seam 1)

**Context.** The design's §10 seam 1 — "the in-place v2→v2 migration treatment … drain-precondition vs an
in-place converter, plus the wire-semver call" — was the open question the old emq.2 triad answered with a
full migration tool. The re-scope changes the question's premise: `echo_mq` is built fresh to parity, and
the v1 line is a reference, not a source. There is no v1-state-to-v2-state crossing to engineer.

**Alternatives.**
1. **Baseline — keep emq.2 as the v1→v2 migration path** (the retired triad: `migrate/4`,
   copy-verify-DELETE, the tombstone fence arm, the v1 `1.3.1` maintenance patch, drain-and-switch).
   *Rejected by the re-scope (D-1/D-2):* echo_mq is the single source of truth; there is nothing to
   migrate from; the design's own resolution ground (§11.11 — the v2 line has never shipped) makes a
   converter a feature with no user. Keeping it also keeps the migration framing the re-scope eradicates.
2. **An in-place v2→v2 converter for any keyspace a pre-reform 2.0 tree wrote.** *Rejected on the
   no-release precondition:* the v2 line has never shipped (§11.11), so no pre-reform 2.0 keyspace exists
   in any deployment; a converter for a state no one holds is unbuildable scope. The honest default —
   **drain the queues before an upgrade** — costs nothing and asserts nothing false.
3. **The from-scratch parity rewrite, drain-precondition as the only crossing.** *CHOSEN.* The v1
   capability surface is rewritten into `echo_mq` under the v2 laws; the only "crossing" is the operator's
   drain-and-upgrade, which needs no code (empty queues before the cutover — the cheap, honest default the
   design already names §10 seam 1). The seam **resolves**, it does not produce a deliverable.

**Decision.** emq.2 ships **no migration tool, no converter, no tombstone arm, and no v1-side patch**.
The design §10 seam 1 resolves on the no-release precondition: **drain-precondition is the documented
crossing**; `apps/echomq` is untouched (it is a reference, and the program's freeze holds with no
exception). The version fence the connector already carries (`{emq}:version` = `echomq:2.0.0`, claimed
`SET NX`, read-back-verified, refused typed on mismatch) stands unchanged — it is the boot contract for a
fresh v2 deployment, not a migration arm. Every emq.2.N rung is **additive on the wire**: it registers
new conformance scenarios and may extend the closed structure registry by an additive minor, but adds no
key *type* outside the §6 grammar and breaks no wire.

**Consequences.** The migration narrative is gone from the spec home (the roadmap rows, the front door,
the 2.x mirror are reframed — §7). The §10 seam 1 line in `../emq.roadmap.md` flips from OPEN to RULED
(drain-precondition; no converter). The one residual the migration tool used to own — a never-upgraded
`1.3.0` binary's structural unfenceability — is moot for a from-scratch deployment (a fresh v2 store has
no v1 binary pointed at it; the operator's runbook ordering, not a tool, governs a real cutover).

## 2 · ADR-1 — the carve: three dependency-ordered parity rungs over the as-built floor

**Context.** The parity gap (§0) is large — the v1 read surface, the operator lifecycle verbs, and the
whole observability plane — but it is **not** one increment. The program law is one-increment-one-run
([`../emq.roadmap.md`](../../../emq.roadmap.md)), and the gap has a natural dependency order: reads observe a
state the mutations change, and the observability plane watches both. The carve must also **de-conflict**
with the confirmed ladder — emq.3–emq.8 already own flows, groups-deepened, batches, cancel/checkpoints,
and the proof stack — so the parity cluster ships only the floor those families build *above*, never the
families themselves (ADR-2 settles that boundary).

**Alternatives.**
1. **One monolithic emq.2 "port everything" rung.** *Rejected:* ~6000 LoC of v1 surface across reads,
   mutations, events, telemetry, locks, and stalled-recovery is not one reviewable increment; it violates
   one-increment-one-run and gives the gate no honest sub-boundary.
2. **A rung per v1 module** (≈9 rungs: queue-reads, queue-ops, worker, lock_manager, queue_events,
   telemetry, stalled_checker, cancellation_token, …).
3. **Three rungs on the dependency-and-concern boundary: reads → ops → observability.** *CHOSEN.* The
   gap has exactly three coherent concerns, dependency-ordered, each a reviewable increment:

**Decision — the carve (one increment per run, dependency-ordered):**

- **emq.2.1 — the read plane (introspection & metrics).** **[BUILT** as `EchoMQ.Metrics`**]** Pure-read
  verbs over the as-built four sets + three-field row + lanes, plus the rate-limit gate (a read-and-refuse
  with the `EMQRATE` wire class, no transition — a pure-read primitive a claimer consults). Ports v1
  `getCounts`/`getState`/`getMetrics`/`getRateLimitTtl`/`isMaxed` and the `queue.ex` read API. **No new
  transition** — the reads observe the existing structures; the one write is a metrics counter the EXISTING
  terminal transitions (`@complete`/`@retry`) now maintain (a single `HINCRBY` so a metric read is never a
  phantom — the read plane's only earned write); any new key is a read target spelled against §6. **First,
  because the later rungs' acceptance reads through it** (a paused-queue test reads the counts; a
  stalled-recovery test reads job state).
- **emq.2.2 — the operator plane (lifecycle & mutation ops). [BUILT** — the four design-make decisions
  resolved at the build's ledger.**]** Real transitions over the row + sets:
  queue-wide `pause`/`resume` (distinct from `Lanes`' per-group pause), `drain`, `obliterate`,
  `update_data`/`update_progress`, `add_log`/`get_job_logs`, `remove_job`, `reprocess_job`. Each is a
  transition under the v2 laws (declared keys, an `EMQ*` typed refusal where a precondition fails, the
  server clock where a lease is touched). **Second, because these mutations change exactly the state the
  read plane already observes** (so emq.2.1's reads are the acceptance lens for emq.2.2's effects).
  **As-built resolution** ([`./emq.2.2.md`](emq.2.rungs/emq.2.2.md)): placement = a new `EchoMQ.Admin` (the four
  queue-scope verbs) + the six job-mutation verbs on `EchoMQ.Jobs`; the queue-wide pause = a `meta.paused`
  field both `Jobs.claim/3` and `Lanes.claim/3` read first (FORM b — the shipped `@claim`/`@gclaim` scripts
  byte-unchanged); the typed refusals = TWO new wire classes `EMQLOCK` (a locked job) + `EMQSTATE` (a
  wrong-state precondition), a missing job a `-1` sentinel → `{:error, :gone}` (no class); the
  drain/obliterate scope = the as-built four sets + the §6 keys. The progress
  event contract — `PUBLISH emq:{q}:events` of `cjson.encode({event="progress", job, progress})` — is the
  D-5 seam **emq.2.3 inherits** (its subscription subscribes once and dispatches on the `event` field; the
  worker-side lock plane that WRITES the `emq:{q}:job:<id>:lock` subkey `remove_job` reads is also emq.2.3's
  — no `SSUBSCRIBE`, ADR-4). Three realization-over-literal re-derivations folded into the spec (the
  as-built minimal three-field row stores no job→repeat or job→dedup backref): drain guards the repeat
  REGISTRY not individual occurrences; `remove_job/4` takes a caller-supplied `dedup_id`; obliterate's `de:*`
  release is bounded-complete (released at remove/drain time, not swept).
- **emq.2.3 — the watch plane (observability & recovery).** The per-queue event stream (`queue_events`
  ported as `EchoMQ.Events` on the existing pub/sub seam — §3), the telemetry surface
  (`EchoMQ.Telemetry` — attach/emit/span over the lifecycle the prior two rungs complete), the explicit
  stalled-sweep (`stalled_checker` / `moveStalledJobsToWait`, beyond the as-built reaper — §4), and the
  worker-side lock plane (lock tracking + lease extension `extendLock(s)`/`releaseLock`, plus the
  cooperative `cancellation_token`). **Third, because it watches the surface the first two rungs
  complete** — events fire on transitions emq.2.2 added; telemetry spans the verbs emq.2.1/2.2 expose.

**Consequences.** Three rungs, each gated against the as-built floor it stands on; the dependency order
makes each rung's acceptance cheap (the prior rung is the test lens). The cluster takes the emq.2 slot
(emq.2.1/2.2/2.3); the migration content vacates it (ADR-0). The de-confliction with emq.3–emq.8 is the
subject of ADR-2 (and the one fork §6 surfaces).

## 3 · ADR-2 — the parity/family boundary: what the cluster ships vs what the confirmed ladder keeps

**Context.** The Operator's "FULL feature parity, every module + every Lua script" could be read to
subsume the later capability families — flows, groups-deepened, batches, lifecycle controls — into the
parity cluster. But emq.3–emq.8 are **confirmed at the Stage-1b checkpoint**
([`../emq.roadmap.md`](../../../emq.roadmap.md)), and the 3.x stream tier hard-gates on this ladder. The
boundary between "the v1 floor echo_mq lacks today" and "the family depth a later rung adds" must be
named, or the cluster either double-ships a family or re-sequences a confirmed plan.

**Alternatives.** (the full steelman is the emq-2 ledger V-1)
1. **Arm A — the cluster fills the floor BELOW emq.3–emq.8; leave them as-is.** The parity cluster ships
   exactly the v1 surface NO confirmed rung owns (reads, ops, observability); emq.3 (flows), emq.4 (groups
   deepened), emq.5 (batches), emq.6 (cancel/checkpoints), emq.8 (the proof stack) keep their slots and
   content. *Steelman:* emq.3–emq.8 ship genuinely *later* capability families, not the v1 floor echo_mq
   lacks today; they are confirmed and downstream-depended-on; re-sequencing them buys zero parity. The
   floor (reads/ops/observability) is real, self-contained, and dependency-clean.
2. **Arm B — the cluster SUBSUMES the feature rungs; re-sequence emq.3–emq.8 into emq.2.N.** Read "every
   module" maximally: flows → emq.2.x, groups-deepened → emq.2.x, etc.; emq.3+ renumber or vanish.
   *Rejected:* (i) blast radius — emq.3–emq.8 are confirmed and emq3.x sequences against them, so this
   forces re-ratification for zero parity gain; (ii) granularity — flows (the A-1-compatible flow design
   is "real design work," design §11.10), groups-deepened, and batches are each a full rung of their own,
   so cramming them into a 3-rung cluster violates one-increment-one-run; (iii) the parity *floor* is a
   distinct concern from the family *depth* — you cannot deepen groups before the group introspection
   reads exist (emq.2.1 must precede emq.4 either way).

**Decision.** **Arm A is the recommended carve.** The parity cluster (emq.2.1/2.2/2.3) ships the
operational floor; emq.3–emq.8 keep their confirmed slots and content; the cluster fills the gap *below*
the families, it does not subsume them. The boundary, stated per family:

| Confirmed rung | What it keeps (NOT in the parity cluster) | The parity floor it builds above (in the cluster) |
| --- | --- | --- |
| emq.3 (parent/flow) | the flow family + the A-1-compatible flow design (design §11.10) | — (flows are a later family; the v1 `flow_producer` ports at emq.3, not here) |
| emq.4 (groups deepened) | control plane, group-aware recovery, weighted/deficit rotation, the starvation drill | the **group introspection reads** (`depth`/counts per lane) emq.2.1 ships are the lens emq.4's recovery is gated by |
| emq.5 (batches) | bulk consumption, `min_size`/`timeout` shaping, affinity, the partitioned finish | the **add_bulk producer** path co-locates with emq.2.2's mutation plane only as the read/observe side; the batch *consume* family is emq.5 |
| emq.6 (lifecycle controls) | TTL per worker/name, **distributed** cancel, checkpoints | the **worker-side cooperative cancel** (`cancellation_token`) + lock-extension emq.2.3 ships is the local primitive emq.6's distributed cancel coordinates |
| emq.8 (proof stack) | conformance suite + engine matrix + the **telemetry contract** + the benchmark gate | the **telemetry surface** (`attach`/`emit`/`span`, the events stream) emq.2.3 ships is the surface emq.8's contract *proves* — the same two-layer split bcs3.x used (the surface fires; the proof stack asserts it) |

**The fork this raises (NOT Venus's to decide — §6).** Arm A is recommended; whether the Operator wants
the feature rungs pulled into the cluster (Arm B) is an architecture/sequencing call. The carve, the
roadmaps, and the exemplar are authored to Arm A; an Arm-B ruling is a cheap roadmap edit before any
build. Surfaced to the Director for the Operator's gate.

**Consequences.** The telemetry/cancel/groups boundaries are explicit, so no later rung re-ships an
emq.2.N surface and no emq.2.N rung pre-empts a family. The two-layer split (surface at emq.2.3, proof at
emq.8) keeps the additive-minor law clean: emq.2.3 registers its own conformance scenarios; emq.8 adds the
matrix and the contract assertions over them.

## 4 · ADR-3 — the stalled plane: an explicit sweep beside the as-built reaper

**Context.** The as-built `EchoMQ.Jobs.reap/2` already returns expired-lease jobs from `active` to
`pending` by one server-clock scan (the `reap` conformance scenario). The v1 line additionally carries an
explicit `StalledChecker` (`check/2`, `job_stalled?/4`, the periodic sweep) and `moveStalledJobsToWait-9`,
plus a worker-side `LockManager` that tracks held jobs and *extends* their locks (`extendLock(s)`,
`releaseLock`) so a long-running handler keeps its lease rather than being reaped. The parity question:
does the as-built reaper already cover the v1 stalled-recovery surface, or is there a real gap?

**Alternatives.**
1. **Declare the reaper sufficient; port nothing.** *Rejected:* the reaper is a *server-side* sweep that
   reclaims a dead lease; the v1 `LockManager` is the *worker-side* counterpart that keeps a *live*
   handler's lease from expiring under a long job (lock extension), and `StalledChecker` is the
   operator-visible periodic recovery with a stall count. The reaper alone has no lease-extension verb and
   no worker-side tracking, so a slow-but-alive handler is reaped today — a real gap the parity surface
   closes.
2. **Fold lock-extension into the consumer silently.** *Rejected:* the extension is a wire verb
   (`PEXPIRE`/score-update on the active set under a declared key + the server clock) with a typed refusal
   when the token is stale (`EMQSTALE`) — it belongs as a `Jobs` transition, not buried in the consumer
   process, so a port and a polyglot reader receive the same contract.
3. **A lock-extension transition on `Jobs` + a worker-side lock plane + an explicit stalled-sweep, all in
   emq.2.3.** *CHOSEN.*

**Decision.** emq.2.3 ships: a **lock-extension verb** on `EchoMQ.Jobs` (re-score the active-set member
to a fresh lease deadline from the server clock, refusing `EMQSTALE` on a stale token — declared keys, the
DQ-2c server-clock law); a **worker-side lock plane** (the `LockManager` capability — track held jobs,
extend on a timer, release on completion) ported as a supervised, opt-in process beside the consumer (the
`EchoMQ.Pump` process-shape precedent); and the **explicit stalled-sweep** (`StalledChecker` /
`moveStalledJobsToWait` — a periodic recovery that distinguishes a reaped dead lease from a stalled-count
threshold, beyond the as-built single-scan reaper). The cooperative `cancellation_token` (the worker-side
half — `new`/`cancel`/`check`) ships here too; the **distributed** cancel stays emq.6 (ADR-2).

**Consequences.** The lease lifecycle is complete: server-side reap (shipped) + worker-side extend (new)
+ explicit stalled recovery (new). The extension verb is a clean additive transition under the master
invariant; the worker-side plane is opt-in (a consumer without it is the unchanged v2 worker, the
`EchoMQ.Pump` precedent). emq.6's distributed cancel coordinates the local cooperative token this rung
ships.

## 5 · ADR-4 — the event + telemetry plane: the existing pub/sub seam, not a new transport

**Context.** v1 `QueueEvents` is a per-queue event stream a consumer subscribes to (`subscribe`/
`unsubscribe` + `handle_event`); v1 `Telemetry` is the `:telemetry` attach/emit/span surface over the
job lifecycle. The design has already dispositioned the transport question: **sharded pub/sub
(`SSUBSCRIBE`) is deferred to the cache rung's invalidation bus** (design §12.3), and the per-queue event
stream's value *rises* under completion-deletes because "the event record is the durable receipt"
(§12.3). The connector already carries `subscribe/2`/`unsubscribe/2` over `push_command` (RESP3), with a
`[:emq, :connector, :reconnect]` telemetry event and the emq.1 auto-resubscribe set.

**Alternatives.**
1. **A new stream/transport for events now.** *Rejected:* design §12.3 defers `SSUBSCRIBE` to the cache
   rung and rejects it for the core event channel (pub/sub is fire-and-forget; the replayable event
   *stream* with ids and range reads is the 3.x tier's `EchoMQ.Stream`, emq3.2 — out of emq.2's scope).
   Inventing a transport here would pre-empt emq3.x and violate no-invent.
2. **Skip events; ship telemetry only.** *Rejected:* the v1 `QueueEvents` surface is a named parity
   capability (a consumer that subscribes to `:completed`/`:failed`); dropping it leaves a real gap an
   operator dashboard reads through.
3. **`EchoMQ.Events` over the existing connector pub/sub seam + `EchoMQ.Telemetry` over `:telemetry`.**
   *CHOSEN.*

**Decision.** emq.2.3 ships `EchoMQ.Events` — the per-queue event subscription surface over the **already
present** connector `subscribe/2`/`unsubscribe/2` pub/sub seam (the emq.1 auto-resubscribe set keeps it
live across a reconnect), publishing lifecycle events (`completed`/`failed`/`scheduled`/`stalled`/…) the
transition scripts emit — and `EchoMQ.Telemetry`, the `:telemetry` attach/emit/span surface over the same
lifecycle (the v1 `job_added`/`job_started`/`job_completed`/`job_failed`/`job_retried`/`worker_started`
events, re-rooted at `[:emq, …]`). **No new transport, no `SSUBSCRIBE`** (that is the cache rung's
evaluation, design §12.3). The event *contract* (the names, the payload shape) registers conformance
scenarios; the proof stack (emq.8) asserts the telemetry *contract* over them (ADR-2's two-layer split).

**Consequences.** The event plane rides the certified wire with zero new transport surface; the
fire-and-forget honesty stays stated (at-most-once on the push channel — the emq.1 resubscribe + the
cache's versioned-claims tolerance are the existing mitigations, design §12.3). The replayable event
stream stays the 3.x tier's job (emq3.2's `EchoMQ.Stream`); emq.2.3 ships the v1-parity pub/sub
subscription, not the durable stream — the boundary is explicit so emq3.x is not pre-empted.

## 6 · The surfaced fork (Operator's call — Venus surfaces, never decides)

> **FORK — the parity/family sequencing.** Does the Operator want **Arm A** (the recommended carve: the
> parity cluster fills the operational floor; emq.3–emq.8 keep their confirmed slots and content), or
> **Arm B** (pull the feature families — flows/groups-deepened/batches — into the parity cluster and
> re-sequence emq.3+)? The design, the carve table (§3), the roadmaps (§7), and the emq.2.1 exemplar are
> all authored to **Arm A** (recommended on the grounds in §3 + ledger V-1: emq.3–emq.8 are confirmed and
> downstream-depended-on; the floor is a distinct concern from the family depth). An Arm-B ruling is a
> cheap roadmap edit *before* any build run. This is the one architecture/sequencing decision the Director
> routes to the Operator; nothing below the fork is built until it is ruled.

## 7 · The roadmap reconciliation — the reframe (no migration language anywhere)

The parity rewrite reframes the emq.2 row across the spec home; the reframe is **grep-clean of
"1.3.1"/"old"/"legacy"/"migrate-from"** and frames `apps/echomq` as a feature reference only. The
concrete edits (applied this run by Venus-1):

- **[`../emq.roadmap.md`](../../../emq.roadmap.md)** — the emq.2 ladder row flips from "the v1→v2 migration
  path re-proven" to "**the full-parity rewrite: introspection & metrics (emq.2.1) · lifecycle & mutation
  ops (emq.2.2) · observability & recovery (emq.2.3)** — the v1 capability floor `echo_mq` lacks,
  rewritten under the v2 laws"; Movement I's 5W reframes the push-source line ("`apps/echomq` is a
  capability **reference**; the parity rewrite ports its surface, then it dissolves" — no migration); seam
  1 (the in-place v2→v2 treatment) flips from OPEN to **RULED (drain-precondition; no converter — ADR-0)**.
- The 2.x line mirror and the 3.x stream-tier roadmap (formerly two separate files) were **consolidated and
  removed** — the single source of truth is now [`../emq.roadmap.md`](../../../emq.roadmap.md), which carries the
  whole ladder (Movements 0–II), the emq.2 cluster row, and the dependencies (emq3.x's hard-gate on emq.0).
  There is no longer a separate per-tier roadmap file to maintain.
- **[`../echo_mq.md`](../../../echo_mq.md)** — the emq.2 ladder row's "Ships" + "Unblocks" reframe: from
  "program hygiene … no consumer rung gates on it" to "**the operational floor every consumer reads through**:
  the counts/metrics/state introspection an operator dashboard reads (emq.2.1), the operator lifecycle verbs
  a runbook drives (emq.2.2), and the event/telemetry plane a consumer observes the work surface through
  (emq.2.3)"; Movement I's one-line summary drops "the v1→v2 migration path" for "the full-parity rewrite
  of the v1 capability surface."

The old emq.2 triad (`emq.2.md` + `.stories.md` + `.prompt.md`) is **re-purposed**: this run
RETIRES its migration body and re-authors the cluster's exemplar (emq.2.1) + carve; the legacy emq.2.*
files are superseded by the emq.2.1/2.2/2.3 triads (the Director decides whether to delete or stub the
old `emq.2.*` files at fan-out — recorded, not assumed).

## 8 · Out of scope (the design's fences, carried)

No migration tool / converter / tombstone arm / v1-side patch (ADR-0). No wire break (every parity
addition is an additive protocol minor — new conformance scenarios, at most an additive structure-registry
extension spelled against §6). No new event transport / `SSUBSCRIBE` (design §12.3 — the cache rung's
evaluation; the durable stream is emq3.2). No feature family the confirmed ladder owns: flows (emq.3),
groups *deepened* (emq.4), batch *consume* (emq.5), **distributed** cancel / TTL / checkpoints (emq.6),
the proof stack (emq.8) — ADR-2. No edit to the frozen v1 `apps/echomq` (it is a reference).

---

The triads this design opens: [`./emq.2.1.md`](emq.2.rungs/emq.2.1.md) · [`./emq.2.2.md`](emq.2.rungs/emq.2.2.md) ·
[`./emq.2.3.md`](emq.2.rungs/emq.2.3.md) (each with `.stories.md` / `.prompt.md`). The precedent
shape: [`./emq.1.design.md`](../emq.1/emq.1.design.md). The canon: [`../emq.design.md`](../../../emq.design.md) (§6 the
grammar, §5 the wire-class registry, §10 seam 1, §11.10/§11.11, §12.3 the event-transport deferral, S-4
the engine gate). The program: [`../emq.roadmap.md`](../../../emq.roadmap.md) · [`../echo_mq.md`](../../../echo_mq.md).
The v1 feature reference: `echo/apps/echomq/lib/echomq/*.ex` + `echo/apps/echomq/priv/scripts/*.lua`. The
as-built floor: `echo/apps/echo_mq/lib/echo_mq/*.ex`. The re-scope ledger:
[`./emq-2.progress.md`](../progress/emq-2.progress.md) (D-1/D-2 the re-scope; D-7/D-9 the carve; V-1 the arms).
