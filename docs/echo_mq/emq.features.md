# EchoMQ 3.0 — the feature catalog (the complete capability surface + the v1→v2 parity proof)

> A canon-level companion to [`./emq.design.md`](./emq.design.md) (the binding design) and
> [`./emq.roadmap.md`](./emq.roadmap.md) (the delivery plan). This file CATALOGS — every shipped, building,
> planned, and proposed EchoMQ capability in one place, with the consumer and system use cases each serves —
> and PROVES v2 full-parity against the frozen v1 line: one row per v1 capability, each mapped to the v2 home
> that rewrites it, the rung that owns it, and its status. The design and the rung triads DEFINE; this file
> MAPS. **Three parts:** **Part A** — the complete feature set by Movement (the capability rows + use cases);
> **Part B** — the v1 → v2 full-parity proof (one row per v1 capability); **Part C** — the **forward-feature
> catalog** in the 5-section format (Goal · Rationale · 5W · Scope · Acceptance Criteria), categorized by
> feature area, the per-feature detail folded up from the former `roadmap/` per-area files. Grounding law
> (binding, NO-INVENT): every reference is a real module/file or a design § (cited `file:line` where
> load-bearing); engine claims cite `valkey.io`; **voice tracks status** — SHIPPED reads present tense,
> SPECCED/BUILDING reads "emq.N builds…", PLANNED reads "the roadmap plans…", PROPOSED reads "proposed:". The v2
> master invariant ([`./emq.roadmap.md`](./emq.roadmap.md) §The master invariant) frames every feature: braced
> `emq:{q}:`, the first-byte-disjoint `{emq}:` reserve, the gated branded `job:` position, every Lua key
> declared-or-rooted, the version record monotone behind the five-code fence, additive registration a protocol
> minor — no later rung re-breaks the wire.
>
> Verified against the as-built tree 2026-06-15 (`echo/apps/echo_mq` + `echo/apps/echo_wire`; the v1 reference
> `echo/apps/echomq`). Status legend: **✅ shipped** · **📐 specced** (the triad authored, no build artifact yet)
> · **📋 planned** (a confirmed rung, not yet built) · **🔭 proposed** (awaiting Operator slot ratification) ·
> **— ruled-out** (explicitly not a feature, with the ruling cited). **The emq.2 cluster is CLOSED** (read →
> ops → watch → close, 4/4 shipped); **the flow family** has emq.3.1/3.2/3.3 shipped (3.3 cross-queue
> shipped-this-run) and **emq.3.4** (failure-policy + bulk) **specced** — the new triad
> [`./specs/emq.3.4.md`](./specs/emq.3/emq.3.4.md).

---

## Part A — the complete EchoMQ 3.0 feature set, by Movement

EchoMQ is one program in three movements; all code converges in `echo/apps/echo_mq` above
`echo/apps/echo_wire` ([`./emq.roadmap.md`](./emq.roadmap.md) §The epic). The exemplar consumer throughout is
**codemoji** (`echo/apps/codemoji` — a code-breaking game standing on exactly this tree: it mints branded
`RND`/`USR`/`JOB`/`GES` ids, enqueues guesses on `EchoMQ.Lanes`, drains them with two `EchoMQ.Consumer`
instances, scores under a single authority, publishes `EchoMQ.Events`, and settles prizes on a second queue;
every claim is grounded in that real surface, never invented). The forward-looking consumer is **echo_bot**
(`echo/apps/echo_bot`): Telegram-bot notifications at scale that *could* enqueue Telegram sends onto the bus
once the bot's notification path moves off the direct synchronous `sendMessage` it ships with today — a
planned consumer, named in forward tense, never asserted as a shipped integration.

### Movement 0 · the substrate — the wire, the cache, the canon (shipped)

| Feature | Capability statement | Home (as-built) | Status |
|---|---|---|---|
| **The extracted wire** | A RESP3 connector over a frozen-named wire layer — `EchoMQ.{RESP, Connector, Script}` under the `EchoWire` facade — dependency-free, the universal predecessor every later rung lands its verbs on. | `echo/apps/echo_wire/lib/echo_wire.ex` (9 `defdelegate`s + `script/2`); `connector.ex` | ✅ |
| **The connect-scoped version fence** | On every connect and reconnect the connector claims `{emq}:version` `SET NX`, read-back-verifies, and refuses typed on mismatch — the boot contract for a fresh v2 deployment, five-code fence union. | `echo_wire` Connector (`{emq}:version` = `echomq:2.0.0`); design §3 | ✅ |
| **Pub/sub seam + telemetry hook** | `subscribe/2`/`unsubscribe/2` over `push_command` (RESP3), the `{:emq_push, …}` message, a guarded `emit/3` (zero cost when `:telemetry` is absent) — the seam the event/telemetry plane rides. | `echo_wire` Connector | ✅ |
| **The near-cache** | A read-through cache with a pluggable `EchoCache.Shadow` archive behaviour (`Shadow.Copy` laptop impl, Litestream conforming) — the structural landing of the BCS near-cache. | `echo/apps/echo_cache` (7 files + the nested `Directory`) | ✅ |
| **The canon (identity + structures)** | The lock-free `:atomics` Snowflake mint, the 14-byte `BrandedId` (the `JOB`/`ORD` brand domains), and the CHAMP family — Ecto-free, the in-umbrella dep every key and id gates on. | `echo/apps/echo_data` (the additive `bcs/` subtree) | ✅ |

**Use cases.** *Consumers/systems:* any BEAM service needing an audited keyspace and a self-healing connector
to Valkey; the cache fronts hot reads for a read-heavy consumer. *codemoji:* the wire is `EchoMQ.Connector`
over `EchoWire`; branded `RND`/`USR`/`JOB`/`GES` ids mint on `EchoData.BrandedId` and gate every key the game
touches. *echo_bot (planned):* a notifications consumer would mint and carry the same branded id from enqueue
to delivery.

### Movement I · the core — push the v1 capability surface to state-of-the-art

`echo_mq` carries the BCS state machine; Movement I rewrites the rest of the v1 capability surface into it
**from scratch under the v2 laws** — never migrated-from ([`./emq.roadmap.md`](./emq.roadmap.md) Movement I;
`apps/echomq` is a feature reference, the list to port).

#### The state machine + fair lanes + the cadence (shipped — emq.0/emq.1)

| Feature | Capability statement | Home (as-built, `echo/apps/echo_mq/lib/echo_mq/`) | Status |
|---|---|---|---|
| **The eight-verb state machine** | `enqueue`/`enqueue_at`/`enqueue_in`/`enqueue_many`, `claim`, `complete`, `retry`, `promote`, `reap`, `browse`, `pending_size` over the three-field row (`state`/`attempts`/`payload`) and the four sorted sets (`pending` score-0 / `active` lease-scored / `schedule` run-at-scored / `dead`); attempts-as-token with `EMQSTALE`; completion-deletes; REV BYLEX browse; the server clock `TIME`. | `jobs.ex` (7 inline `Script.new/2` transitions `@enqueue`…`@reap`) | ✅ |
| **The branded `JOB` identity** | The job position `emq:{q}:job:<branded-id>` gated `BrandedId.valid?/1` at the key builder (raises before any wire); the kind law (`JOB`-only) the enqueue script's first act, a typed `EMQKIND` refusal; byte order IS mint order (the order theorem — browse with no second index). | `keyspace.ex` (`job_key/2`); `jobs.ex` `@enqueue`; design §2 | ✅ |
| **Fair lanes (basics)** | `enqueue/5`, `claim/3`, `pause/3`, `resume/3`, `limit/4`, `depth/2` — per-**group** pause/resume/limit and round-robin rotation (the ring is the rota), gated G1–G8. | `lanes.ex` | ✅ |
| **The scheduler + retry vocabulary** | Scheduled/repeatable jobs as a visibility fence on the `schedule` set; `Repeat` (`register`/`cancel`/`due`/`advance`/`count`); attempts-with-backoff (`Backoff.delay_ms/2` — fixed/exponential/jitter) + the poison-job drill; connector auto-resubscribe. | `repeat.ex`, `backoff.ex`, `pump.ex` + `pump/core.ex` (the promote+repeat sweep) | ✅ (emq.1, `e0fa9b03`) |
| **The consumer + cadence** | `EchoMQ.Consumer` (`child_spec`/`start_link`/`stop`) draining the queue; `EchoMQ.Pump` the supervised promote+repeat sweep with a pure decision core. | `consumer.ex`, `pump.ex` | ✅ |
| **Honest-row conformance** | A self-describing scenario harness — `scenarios/0` + `run/2 → {:ok, n}`, one CONF line per scenario, the count pinned in two tests; **37 scenarios today** (18 state-machine/emq.1 + 6 read + 8 ops + 5 watch), each addition an additive minor with its probe. | `conformance.ex` (`scenarios/0`, `conformance.ex:25`) | ✅ |

**Use cases.** *Consumers/systems:* any producer/worker needing exactly-the-state-it-claims with at-least-once
delivery, retries with backoff, and scheduled/repeatable work. *codemoji:* the work surface — **guess
scoring then prize settlement** — is `EchoMQ.Jobs` with branded job ids, drained by two `EchoMQ.Consumer`
instances (a score queue then a settle queue, move-then-settle), shaped by `EchoMQ.Lanes` **per player** so
one player's flood cannot starve another. *echo_bot (planned):* scheduled and repeatable notification sends
would land on **this movement's emq.1 row** — the bus's scheduled-jobs surface a forward consumer can build on.

#### The full-parity cluster — emq.2 (building: read ✅ · ops ✅ · watch 🔨 · closer 🔨)

emq.2 is the **full-parity rewrite** of the v1 capability floor `echo_mq` lacks, decomposed read→ops→watch on
the dependency-and-concern boundary (the carve + the five ADRs: [`./specs/emq.2.design.md`](specs/emq.2/emq.2.design.md)).
Each rung stands ON the as-built floor and is acceptance-checked through the prior rung's reads.

**emq.2.1 · the read plane (introspection & metrics) — ✅ shipped (`7d98ef86`).** The module `EchoMQ.Metrics`
(`metrics.ex`):

- **Counts by state** — `get_counts/3` answers a count per requested state over the four as-built sets (and
  the metrics counters for `completed`/`failed`, which are no longer sets under completion-deletes), one
  inline `@counts` script declaring its keys; an unregistered state name is the typed `{:error,
  {:unknown_state, _}}`.
- **Job & state lookup** — `get_job/3` reads the three-field row; `get_job_state/3` answers the state by which
  set holds the id (`:pending`/`:active`/`:scheduled`/`:dead`/`:absent`/`:unknown`).
- **Throughput metrics** — `get_metrics/3` reads `emq:{q}:metrics:completed`/`:failed`; the counter write
  rides the EXISTING terminal transitions (`@complete`/`@retry` each `HINCRBY` once — so a metric read is
  never a phantom), `jobs.ex:169`/`jobs.ex:206`.
- **Dedup read** — `get_deduplication_job_id/3` reads the branded id parked at `emq:{q}:de:<dedupId>`.
- **The rate-limit plane** — `get_rate_limit_ttl/3`, `get_global_rate_limit/2`, and `is_maxed/2` — a
  read-and-refuse with the wire class `EMQRATE` (joined the closed registry as an additive minor) where the
  active set is at the configured ceiling.
- **Per-lane introspection** — `lane_depth/3`, `lane_depths/3` over the lane sets.

*Use cases — consumers/systems:* an operator dashboard reading queue depth and throughput; a runbook reading a
job's state before mutating it; the rate gate a claimer consults before claiming. *Consuming app:* the
counts/metrics/state introspection an operator dashboard reads queue health through — for codemoji, the
depth and throughput of the per-player score and settle queues (`echo_mq.md` reframed emq.2 row).

**emq.2.2 · the operator plane (lifecycle & mutation ops) — ✅ shipped (`76fc947c`).** `EchoMQ.Admin` (the
four queue-scope verbs) + six job-mutation verbs on `EchoMQ.Jobs`:

- **Queue-wide pause/resume** — `Admin.pause/2`/`resume/2` set/clear a `paused` field on the `meta` HASH; both
  `Jobs.claim/3` and `Lanes.claim/3` read it first and short-circuit to empty (FORM b — the shipped
  `@claim`/`@gclaim` byte-unchanged). Distinct from `Lanes.pause/3`'s per-group park.
- **Drain** — `Admin.drain/3` empties `pending` (optionally `schedule`), deleting each drained row + its
  `:logs` subkey; active jobs survive; the repeat REGISTRY survives (drain cancels no registered repeatable).
- **Obliterate** — `Admin.obliterate/3` destroys a **paused** queue (every set + the §6 auxiliary keys),
  bounded per call (`:more`/`:ok`), refusing a non-paused queue (`EMQSTATE`) or live-active jobs (unless
  `force`).
- **Job mutations on `Jobs`** — `update_data/4`, `update_progress/4` (emits the progress event the watch plane
  subscribes to — the locked D-5 contract `PUBLISH emq:{q}:events …`), `add_log/5` + `get_job_logs/3`,
  `remove_job/4` (refuses a locked job `EMQLOCK`; releases a caller-supplied dedup key), `reprocess_job/3`
  (`dead`→`pending`, refuses a non-dead job `EMQSTATE`).
- **Two new wire classes** — `EMQLOCK` (a locked job) + `EMQSTATE` (a wrong-state precondition); a missing job
  a `-1` sentinel → `{:error, :gone}`. The five-code fence union stays unextended.

*Use cases — consumers/systems:* an operator pausing/draining a runaway queue during an incident; a control
plane obliterating ephemeral test queues; an on-call removing a poisoned job or reprocessing a dead one after
fixing its cause. *Consuming app:* the operator runbook that drives the work queues' lifecycle — the
mutation side of the per-consumer lanes, e.g. draining or clearing codemoji's score/settle queues
(`echo_mq.md` reframed emq.2 row).

**emq.2.3 · the watch plane (observability & recovery) — 🔨 built on disk (the cluster's third rung).** Five
modules, the lease lifecycle completed and the observability plane lit up:

- **`EchoMQ.Events`** — per-queue event subscription over the connector pub/sub seam (`subscribe/2`,
  `unsubscribe/2`, `close/2`, `channel/1`, `publish/5`, `event_name/1` + a `handle_event/3` behaviour); events
  published host-side after a transition verdict onto `emq:{q}:events`; auto-resubscribe across a reconnect;
  at-most-once honesty stated. No new transport, no `SSUBSCRIBE` (design §12.3).
- **`EchoMQ.Meter`** (FILE still `telemetry.ex` until the emq.2.4 C1 rename) — `attach/4`, `attach_many/4`, `emit/3`, `span/3` over the `[:emq, …]` lifecycle
  (`job_added`/`job_started`/`job_completed`/`job_failed`/`job_retried`/`worker_started`/`worker_stopped`/
  `rate_limit_hit`); zero cost when `:telemetry` is absent. The surface fires — the contract is emq.8.
- **The lock-extension verb** — `Jobs.extend_lock/5` (`jobs.ex:646`) + `extend_locks/4` (`jobs.ex:671`) via
  `@extend_lock`/`@extend_locks` inline scripts: re-score the `active` member to `TIME`+lease (the server
  clock), refuse `EMQSTALE` on a stale attempts-token (the existing class — no new class), never a separate
  `…:lock` string.
- **The worker-side lock plane** — `EchoMQ.Locks` (+ `EchoMQ.Locks.Core`; FILES `lock_manager.ex` + `lock_manager/core.ex` until the C1 rename): `track_job/3`, `untrack_job/2`,
  `get_active_job_count/1`, `get_tracked_job_ids/1`, `is_tracked?/2`, extend-on-a-timer, release-on-completion
  — an opt-in supervised process (a consumer without it is the unchanged v2 worker).
- **The explicit stalled-sweep** — `EchoMQ.Stalled` (FILE `stalled_checker.ex`): `check/3`, `job_stalled?/4` + the periodic
  recovery distinguishing a reaped dead lease from a stall-count threshold (beyond the as-built single-scan
  reaper), reading the server `TIME`.
- **The cooperative cancellation token** — `EchoMQ.Cancel` (FILE `cancellation_token.ex`): `new/0`, `cancel/3`, `check/1`,
  `check!/1` (the worker-side half; the **distributed** cancel is emq.6).

emq.2.3 grows the conformance set to **37** (+5: `lock_extend`, `stalled`, `events`, `telemetry`, `cancel`).

*Use cases — consumers/systems:* a dashboard subscribing to completed/failed events; the platform attaching a
`:telemetry` handler; a long-running handler extending its lease so it is not reaped mid-work; an operator's
recovery sweep reclaiming genuinely stalled jobs. *codemoji:* the live feed — guess scoring and prize
settlement watched through `EchoMQ.Events` + telemetry as jobs move across the two queues;
emq.6's distributed cancel coordinates the local token this rung ships.

**emq.2.4 · the parity-closing stage — 🔨 the cluster closer (this design cycle specs it).** emq.2.4 is the
FINAL parity stage, two-part: (1) it builds the residual parity features + improvement opportunities the
emq.2 ⇄ emq.2.3 reconcile surfaces (the gap table — see [`./specs/emq.2.4.md`](specs/emq.2/emq.2.rungs/emq.2.4.md)); (2) it
ships the **complete test suite** that closes the v1↔v2 coverage gap for the shipped read/ops/watch surface —
porting v1's scenario DEPTH for the parity surface, while explicitly attributing the rest to its rung (worker
abstraction → emq.6, the OTel contract → emq.8, the ≥100 determinism loop replacing dedicated stress files).
emq.2.4 is process/mint-touching → HIGH-RISK → Apollo mandatory at build.

*Use cases — consumers/systems:* the parity guarantee itself — `echo_mq` carries the whole shipped v1
read/ops/watch surface, proven at v1's scenario depth, so `apps/echomq`'s dissolution can close (the program
thesis). *Consuming app:* the assurance that every queue-health, operator, and watch read a consumer makes is
exercised at depth before that consumer builds on it.

#### The parent/flow family — emq.3 (🔨 OPEN — single-queue + child-result reads + cross-queue shipped; failure-policy specced)

The parent/child flow family, redesigned A-1-clean: the A-1-compatible flow design landed FIRST (the v1
`flow_producer` roots key operands in data values, structurally inexpressible under declared keys — design
§11.10), then the carve into sub-rungs (the per-feature 5-section detail is **Part C.1**). **emq.3.1 SHIPPED
(2026-06-15)** — the **single-queue flow**: `EchoMQ.Flows.add/3` + the inline `@enqueue_flow` (a parent +
same-queue children enqueued atomically on one slot — the children claimable, the parent held out of `pending`
with its `:dependencies` count and its row `state = awaiting_children`), the fan-in hook on `@complete` (the
idempotent decrement releasing the parent at zero + the `:processed` record), the `awaiting_children` read-plane
state, and the `flow_add` + `flow_fanin` conformance scenarios (43 → 45). **emq.3.2 SHIPPED (2026-06-15;
ratified — the durable harness `echo/rungs/bus/emq_3_2_check.sh` 8/8, Director-reproduced)** — the **child-result
reads**: `EchoMQ.Flows.children_values/3` (the completed children's results over `:processed`, the v1
`get_children_values` parity) + `EchoMQ.Flows.dependencies/3` (the outstanding count over `:dependencies`, the v1
`get_dependencies`-count parity), plus the **real-result-carrying completion** (`complete/4` → `complete/5`,
`result \\ nil`, threading the result through the existing `ARGV[5]` slot — the `@complete` Lua byte-unchanged,
host-only → **NORMAL-risk**) that **closed emq.3.1's O1** (`:processed` now holds the real result, not the
presence marker), and the `flow_children_values` conformance scenario (45 → 46). **emq.3.3 SHIPPED (2026-06-15,
this run)** — the **cross-queue flow** (a parent and its DIRECT children in different queues, the v1 shape): the
cross-queue admit path on `add/3` (host-orchestrated, parent-first, fail-closed) + the **completion-signal hop**
— the child emits to a durable `emq:{C}:flow:outbox` on its own slot (atomic with the active-ZREM, an additive
`@complete` branch, the single-queue branch byte-frozen) and `EchoMQ.Pump.sweep/1`'s third pass
`deliver_flow_completions` delivers the decrement on the parent's slot via `@flow_deliver` (the `:processed`
HSETNX idempotency guard) — **eventually-consistent** (released on the next sweep tick, never "atomic across
queues"), at-least-once made effectively-once; the `flow_cross_queue` scenario (46 → 47); HIGH-risk, Apollo
MANDATORY. **emq.3.4 SPECCED (the new triad [`./specs/emq.3.4.md`](./specs/emq.3/emq.3.4.md))** — the **failure-policy
+ bulk add**: `fail_parent_on_failure` (the default — a dead child fails the parent, recorded in `:failed`) /
`ignore_dependency_on_failure` (the dead child is satisfied + recorded in `:unsuccessful`, so the parent
proceeds) over the **already-§6-reserved** `:failed`/`:unsuccessful` subkeys (no grammar edit), the additive
`@retry` dead-letter branch (the existing body byte-frozen) + the cross-queue fail-deliver (the same `flow:outbox`
+ sweep, via `@flow_fail_deliver`) + `EchoMQ.Flows.add_bulk/3` (the v1 `add_bulk/2` parity) + `ignored_failures/3`
(the v1 `get_ignored_children_failures` read); it closes the gap where a child that DIES leaves the parent
hanging forever; HIGH-risk (a shipped `@retry` edit → Apollo MANDATORY). **Grandchildren / deep recursion** is
the honest **Out** (the emq-3-4 V-1 scope fork RULED → Arm A, D-2: the locked Out → emq.3.5). Ports
v1 `flow_producer.ex` (`add/2` + the child-result reads + the cross-queue flow realized; `add_bulk/2` + the
failure-policy options → emq.3.4; the recursive tree → the deferred rung).

*Use cases — consumers/systems:* fan-out/fan-in pipelines where a parent job completes only when its children
do (or fails / proceeds when one dies — emq.3.4). *Consuming app:* a multi-leg work unit that gates on a set
of child jobs — one failed leg failing the parent (`fail_parent_on_failure`) or recorded-and-skipped
(`ignore_dependency_on_failure`) (prospective — no current consumer wires flows today; recorded, not asserted).

### Movement II · the extension — the EMQ family ladder (📋 planned)

A multi-tenant production bus needs the pattern depth established queueing systems proved at scale. The
roadmap plans five families, one rung each ([`./emq.roadmap.md`](./emq.roadmap.md) §Movement II):

| Rung | Family | The roadmap plans… | Status |
|---|---|---|---|
| **emq.4** | groups deepened | the control plane, group-aware recovery, the park-don't-poll metronome, weighted/deficit rotation + the starvation drill (the basics shipped as `EchoMQ.Lanes`); the group introspection reads emq.2.1 ships are the lens emq.4's recovery is gated by. | 📋 |
| **emq.5** | batches | bulk consumption, `min_size`/`timeout` shaping, affinity, the partitioned finish (the `add_bulk` producer path co-locates with emq.2.2; the batch *consume* family is here). | 📋 |
| **emq.6** | lifecycle controls | TTL per worker/name, **distributed** cancel (coordinating emq.2.3's local cooperative token), checkpoints. | 📋 |
| **emq.7** | the cache deepened | BCAST tracking, absorbed-fills compaction, journal `synchronous=FULL` per group, the invalidation-transport evaluation (design §12.3's named reopening); may be pulled forward (Operator call). | 📋 |
| **emq.8** | the proof stack | conformance + the engine matrix + the **telemetry contract** (asserting the surface emq.2.3 fires — ADR-2's two-layer split) + the benchmark gate with rival numbers recorded. | 📋 |

**Use cases.** *Consumers/systems:* multi-tenant operators needing fair rotation under contention (emq.4),
high-throughput bulk drains (emq.5), bounded worker lifecycles and cross-node cancel (emq.6), a deepened
near-cache (emq.7), and engine claims turned into a parse + a benchmark (emq.8). *codemoji:* **per-player
fairness at cluster scale** — flood one player's guess lane, the others hold (emq.4's deepened groups carry
codemoji's per-player `EchoMQ.Lanes` to cluster scale); a settle-worker's bounded lifecycle (emq.6).
*echo_bot (planned):* the telemetry contract a notifications consumer's observability would gate on (emq.8).

### EchoMQ 3.x · the stream tier (🔭 proposed — awaiting Operator slot ratification)

Proposed: the next major — event streams whose append order is mint order, retention as declared policy, the
archive under a shadow, and time-travel by mint instant — on the certified wire, under the v2 laws, with no
second protocol (a partitioned-log adoption was examined and rejected, BCS App. I). Hard-gates on emq.0 (the
wire + the pluggable shadow, both closed). Consolidated into [`./emq.roadmap.md`](./emq.roadmap.md) §EchoMQ 3.x.

| Rung | Proposed: ships | Status |
|---|---|---|
| **emq3.1** | the stream verbs on the connector: `XADD`, `XRANGE`, `XREADGROUP`, `XACK`, `XAUTOCLAIM`. | 🔭 |
| **emq3.2** | `EchoMQ.Stream`, the writer law: hash-tagged per key, branded record ids, append is mint order. | 🔭 |
| **emq3.3** | groups + the polyglot seam: a BEAM consumer and one non-BEAM reader on one group, crash → `XAUTOCLAIM` re-delivery. | 🔭 |
| **emq3.4** | retention as declared policy: `MAXLEN` (approx) + mint-time `MINID` windows per stream. | 🔭 |
| **emq3.5** | the archive: segments folded to SQLite under `EchoCache.Shadow`; merge reads; box-loss restore. | 🔭 |
| **emq3.6** | time-travel + hydration: a mint-instant → `XRANGE` bounds; Table hydration from a tail. | 🔭 |

**Use cases.** *Consumers/systems:* per-key event streams with replay, polyglot readers on ordinary Redis
clients over claims-only payloads, declared retention, deep history restorable after box loss, and mint-time
window queries. *Consuming app (prospective):* every domain event an immutable entry on a per-key stream lane
that projections and polyglot consumers replay — for codemoji, each scored guess or settled prize as a
mint-ordered event a downstream reader could replay; a non-BEAM reader could ride emq3.3 as a consumer group
beside a BEAM one; a replay discipline would gate on emq3.4's windows and emq3.5's archive (proposed — no
current consumer wires the stream tier today).

### The unslotted proposals (🔭 held at the program seam)

Held at [`./emq.roadmap.md`](./emq.roadmap.md) §Seams item 8, owners unchanged, slotted only by a checkpoint
ruling: the **transport rung** (the connector over unix sockets + TLS); **FLAME ephemeral consumers**
(consumers as runners that exist only for the drain — the journal-beside-consumer pattern makes the consumer
disposable); the **Go-driven conformance harness** + the Go store/keyspace ports; the **MCP surface** over
bus + cache + journal; and the **cross-runtime fleet** (the Go sibling; echomq-node strictly proposed).

---

## Part B — the v1 → v2 full-parity-proof table

One row per v1 `echomq` capability (every lib module + its public feature, every operator/lifecycle Lua
script). Columns: **v1 capability** (the reference — `echo/apps/echomq/`) | **v2 home** (the real `echo_mq`
module or sibling app, cited) | **which emq.x rewrites it** | **status**. This PROVES full-parity: every v1
capability is **rewritten** (✅/🔨), **scheduled at a named rung** (📋), or **explicitly ruled out** (—) with
its ruling cited. The "which emq.x?" column is the Operator's answer to *what still owes what*.

> Read with the **single hard rule** ([`./emq.roadmap.md`](./emq.roadmap.md) Movement I): `apps/echomq` is a
> **feature reference** — the capability list to port — never a thing migrated-from. A v2 home is a **fresh
> rewrite under the v2 laws** (braced + branded + declared-keys + server-clock), never a lift of the v1 form.

### B.1 — the lib modules

| v1 module (`echo/apps/echomq/lib/echomq/`) | v1 public capability | v2 home (`echo/apps/echo_mq/lib/echo_mq/` unless noted) | Which emq.x | Status |
|---|---|---|---|---|
| `backoff.ex` | `delay_ms/2` — fixed/exponential/jitter retry delays, above the wire | `backoff.ex` (`Backoff.delay_ms/2`) | emq.1 | ✅ |
| `id.ex` | producer-minted Snowflake, config node id, `mint`/`brand`/`decode`/`boot_check!` | `echo/apps/echo_data` — `EchoData.Snowflake` + `BrandedId` (the `JOB` brand) | M0 | ✅ |
| `champ.ex` | the 14-byte branded-id parse/build/validate (`generate_id`/`parse`/`valid?`/`namespace`/`timestamp`) | `echo/apps/echo_data` — `EchoData.BrandedId` + the CHAMP family | M0 | ✅ |
| `keys.ex` | the keyspace builder (the v1 `<prefix>:<queue>:<type>` grammar) | `keyspace.ex` (`queue_key/2`, `job_key/2`, `reserve/1`, `version_key/0`, `slot/1`, `hashtag/1`) — **rewritten braced** `emq:{q}:` | emq.0 | ✅ |
| `redis_connection.ex` | the v1 connection (`EVALSHA`+`NOSCRIPT` self-heal, pub/sub) | `echo/apps/echo_wire` — `EchoMQ.Connector` (under `EchoWire`) | emq.0 | ✅ |
| `scripts.ex` | the script bundle loader (`priv/scripts/*.lua`) | inline `Script.new/2` module attributes (the per-module law — **no `priv/`**); `echo_wire` `Script` | emq.0 | ✅ |
| `fence.ex` | `preflight/2`, `preflight!/2`, `sentinel_keys/2` — the boot keyspace/version fence | `echo_wire` Connector fence (`{emq}:version`, connect-scoped, claim/read-back/refuse) + `keyspace.ex` reserve read | emq.0 | ✅ |
| `fence_error.ex` | `%EchoMQ.FenceError{}` — the five-code boot-fence union | the `echo_wire` connector fence outcome (the five-code union; design §5/§11.7) | emq.0 | ✅ |
| `version.ex` | `wire_version/0` = `echomq:2.0.0`, `parse/1`, the lib name | the `echo_wire` connector's pinned `@wire_version` (`= echomq:2.0.0`) | emq.0 | ✅ |
| `types.ex` | the v1 shared type defs / structs | the as-built module structs + typespecs across `echo_mq` (no central `types` module — co-located) | emq.0 | ✅ |
| `job.ex` | the job entity (the v1 multi-field hash) | the **three-field row** (`state`/`attempts`/`payload`) the `@enqueue` script writes; `Jobs.get_job/3` reads it (no `Job` struct — design §11.11 field reform) | emq.1 (+ emq.2.1 read) | ✅ |
| `queue.ex` (the 2144-LoC hub) — **reads** | `get_counts`/`count`/`get_job_counts`; `get_job`/`get_job_state`/`get_jobs`-by-state; `get_meta`/`get_version`; `get_metrics`; `get_deduplication_job_id`; `get_global_rate_limit`/`get_rate_limit_ttl`; `get_workers`/`export_prometheus_metrics` | `metrics.ex` — `get_counts/3`, `get_job/3`, `get_job_state/3`, `get_metrics/3`, `get_deduplication_job_id/3`, `get_rate_limit_ttl/3`, `get_global_rate_limit/2`, `is_maxed/2`, `lane_depth/3`, `lane_depths/3` | emq.2.1 | ✅ |
| `queue.ex` — **lifecycle ops** | `pause`/`resume`; `update_meta`; (+ the script-backed `drain`/`obliterate`/`removeJob`/`reprocessJob`) | `admin.ex` — `pause/2`, `resume/2`, `drain/3`, `obliterate/3`; + `Jobs.remove_job/4`, `reprocess_job/3` | emq.2.2 | ✅ |
| `queue.ex` — **enqueue/claim** | `add`/`add_bulk`, the priority/delayed adds | `jobs.ex` — `enqueue/4`, `enqueue_at/5`, `enqueue_in/5`, `enqueue_many/3`, `claim/3` | emq.0/emq.1 | ✅ |
| `queue.ex` — `get_workers`/`get_workers_count` (the worker registry read) | reads the live worker set | the worker *registry* read is the **worker abstraction** — emq.6 (ADR-2; emq.2.3 ships the lock plane, not the registry); `Metrics` covers queue health, not the worker roster | emq.6 | 📋 |
| `queue.ex` — `export_prometheus_metrics` (the Prometheus *format* wrapper) | formats the metrics for Prometheus | the **telemetry contract** (the export/format wrapper beyond the raw `get_metrics/3` read) — emq.8 (emq.2.1 Scope "Out"); the raw read is shipped | emq.8 | 📋 |
| `worker.ex` (1908 LoC) — **lock plane** | `cancel_job`/`cancel_all_jobs`/`active_job_ids`; the stalled-check timer; lock tracking | `lock_manager.ex` (+ `lock_manager/core.ex`) — `track_job/3`, `untrack_job/2`, `get_active_job_count/1`, `get_tracked_job_ids/1`, `is_tracked?/2`; `stalled_checker.ex`; `cancellation_token.ex` | emq.2.3 | 🔨 |
| `worker.ex` — **job mutations** | `update_progress`/`log`/`update_data` | `jobs.ex` — `update_progress/4`, `add_log/5` + `get_job_logs/3`, `update_data/4` | emq.2.2 | ✅ |
| `worker.ex` — **the worker abstraction** | `pause`/`resume`/`paused?`/`running?`/`active_count`; `get_next_job`; the full processing loop + concurrency model | `consumer.ex` (`Consumer` draining) covers the consume loop; the **full worker abstraction** (the v1 per-worker pause/concurrency/registry) is emq.6 (design ADR-2 — `Consumer` is partial parity, the abstraction depth is the lifecycle-controls rung) | emq.6 | 📋 |
| `lock_manager.ex` | `track_job`/`untrack_job`/`get_active_job_count`/`get_tracked_job_ids`/`is_tracked?` + the `extend_locks` loop | `lock_manager.ex` (the five reads) + `Jobs.extend_lock/5`/`extend_locks/4` (the wire verbs, `jobs.ex:646`/`671`) | emq.2.3 | 🔨 |
| `queue_events.ex` | the per-queue event stream: `subscribe`/`unsubscribe`/`close` + `handle_event/3` | `events.ex` — `EchoMQ.Events` over the connector pub/sub seam (no `SSUBSCRIBE`; the durable replayable stream is emq3.2) | emq.2.3 | 🔨 |
| `stalled_checker.ex` | `check/2`, `job_stalled?/4` + the periodic sweep | `stalled_checker.ex` — `check/3`, `job_stalled?/4` + the `:sweep` timer (server-clock, beyond the as-built reaper) | emq.2.3 | 🔨 |
| `telemetry.ex` | `attach`/`attach_many`/`emit`/`span` + the six lifecycle helpers | `telemetry.ex` — `attach/4`, `attach_many/4`, `emit/3`, `span/3` + the `[:emq, …]` lifecycle (the **surface**; the **contract** is emq.8) | emq.2.3 (surface) / emq.8 (contract) | 🔨 / 📋 |
| `cancellation_token.ex` | cooperative cancel: `new`/`cancel`/`check`/`check!` | `cancellation_token.ex` — the worker-side half (the **distributed** cancel is emq.6) | emq.2.3 (local) / emq.6 (distributed) | 🔨 / 📋 |
| `flow_producer.ex` | `add/2`, `add_bulk/2`, `get_children_values`, `get_dependencies`, `get_ignored_children_failures` — parent/child flows + failure-policy | `EchoMQ.Flows.add/3` + `@enqueue_flow` + the `@complete` fan-in hook — the **single-queue** flow (parent + same-queue children, atomic; `awaiting_children`); the A-1-compatible redesign carries the dependency graph in declared §6 subkeys of the parent, **not** the v1 data-value `parent_key`. **Child-result reads (emq.3.2 ✅):** `children_values/3` over `:processed` + `dependencies/3` over `:dependencies` + the real-result `complete/5` (host-only, O1 closed). **Cross-queue (emq.3.3 ✅):** the cross-queue admit path + the `flow:outbox` + `Pump.sweep/1`'s `deliver_flow_completions` + `@flow_deliver` (the `:processed` HSETNX guard) — eventually-consistent. **Failure-policy + bulk (emq.3.4 ✅):** `fail_parent_on_failure`/`ignore_dependency_on_failure` over the §6-reserved `:failed`/`:unsuccessful` (the additive `@retry` branch + `@flow_fail_deliver`) + `add_bulk/3` + `ignored_failures/3`. Grandchildren → the deferred rung (the V-1 fork). | emq.3.1 (single-queue ✅) + emq.3.2 (reads ✅) + emq.3.3 (cross-queue ✅) + emq.3.4 (failure-policy + bulk ✅) | ✅ |
| `job_scheduler.ex` | CRON repeatables: `upsert/7`/`get/4`/`list/3`/`count/3`/`remove/4`/`remove_by_key/4`/`calculate_next_millis/2` | `repeat.ex` — `register`/`cancel`/`due`/`advance`/`count` (the scheduled/repeatable visibility fence on the `schedule` set); `pump.ex` drives the sweep | emq.1 | ✅ |
| `migration.ex` | `migrate/4` — the v1→v2 offline copy-verify-DELETE tool | **— ruled out.** emq.2 design ADR-0 (the no-release precondition, design §11.11): the v2 line has never shipped, so there is nothing to migrate from; the crossing is the **drain-precondition** (empty queues before an upgrade — needs no code). Roadmap §Seams item 1: RULED. | — | — |

### B.2 — the Lua scripts (the operator/lifecycle/recovery surface)

The v1 line carries 26 `priv/scripts/*.lua`; the v2 line has **no `priv/`** — every script is an inline
`Script.new/2` module attribute (S-6, the per-module law). One row per v1 script.

| v1 script (`echo/apps/echomq/priv/scripts/`) | v1 capability | v2 home (inline `Script.new/2`) | Which emq.x | Status |
|---|---|---|---|---|
| `addStandardJob-7.lua` | enqueue a standard job | `jobs.ex` `@enqueue` (the kind law first act, `EMQKIND`) | emq.0/emq.1 | ✅ |
| `addDelayedJob-6.lua` | enqueue onto the delayed/schedule set | `jobs.ex` `@schedule` (run-at-scored `schedule` set) | emq.1 | ✅ |
| `addPrioritizedJob-7.lua` | enqueue with a priority score | — folded: the v2 `pending` set is score-0 (mint order IS the order theorem); priority lanes are `EchoMQ.Lanes` (per-group). No separate prioritized set (design §6 — the v1 `prioritized` type retires). | emq.1 (lanes) | ✅ |
| `moveToActive-11.lua` | claim: move wait→active, mint the lock | `jobs.ex` `@claim` (`ZPOPMIN` pending → `active` lease-scored, mints token by `HINCRBY attempts`) | emq.0/emq.1 | ✅ |
| `moveToFinished-15.lua` | complete/fail: move active→completed/failed | `jobs.ex` `@complete` (completion-deletes — no `completed` set) + `@retry`'s dead-letter arm | emq.0/emq.1 | ✅ |
| `moveToDelayed-8.lua` | reschedule active→delayed (retry) | `jobs.ex` `@retry` (schedules with `last_error` kept) | emq.1 | ✅ |
| `moveJobFromActiveToWait-10.lua` | return an active job to wait | `jobs.ex` `@reap` (expired-lease `active`→`pending`, one server-clock scan) | emq.0 | ✅ |
| `promote-10.lua` | promote a due delayed job to wait | `jobs.ex` `@promote` (releases a due `schedule` member to `pending`); `pump.ex` drives it | emq.1 | ✅ |
| `metaEnsureVersion-1.lua` | claim/verify the meta version | the `echo_wire` connector fence (`{emq}:version` claim/read-back, connect-scoped) | emq.0 | ✅ |
| `getCounts-1.lua` | counts by state | `metrics.ex` `@counts` (the four sets + the metric counters; unknown state → typed error) | emq.2.1 | ✅ |
| `getState-8.lua` | a job's state | `metrics.ex` `@state_lookup` (which set holds the id) | emq.2.1 | ✅ |
| `getMetrics-2.lua` | completed/failed throughput | `metrics.ex` `get_metrics/3` (`metrics:completed`/`:failed`, the counter on `@complete`/`@retry`) | emq.2.1 | ✅ |
| `getRateLimitTtl-2.lua` | the limiter TTL | `metrics.ex` `get_rate_limit_ttl/3` | emq.2.1 | ✅ |
| `isMaxed-2.lua` | is the queue at its ceiling | `metrics.ex` `is_maxed/2` (the read-and-refuse, `EMQRATE`) | emq.2.1 | ✅ |
| `pause-7.lua` | queue-wide pause (the `meta.paused` flag) | `admin.ex` `pause/2`/`resume/2` (the `paused` meta field; both claim paths read it — FORM b) | emq.2.2 | ✅ |
| `drain-6.lua` | empty the pending backlog | `jobs.ex` `@drain` (`admin.ex` `drain/3`) | emq.2.2 | ✅ |
| `obliterate-2.lua` | destroy a queue (iterative) | `jobs.ex` `@obliterate` (`admin.ex` `obliterate/3`, bounded `:more`/`:ok`, refuses non-paused/live-active) | emq.2.2 | ✅ |
| `updateData-1.lua` | replace a job's data | `jobs.ex` `@update_data` (`Jobs.update_data/4`, `data`→`payload`) | emq.2.2 | ✅ |
| `updateProgress-3.lua` | write a job's progress | `jobs.ex` `@update_progress` (`Jobs.update_progress/4` + the `PUBLISH emq:{q}:events` progress event) | emq.2.2 | ✅ |
| `addLog-2.lua` | append to a job's logs | `jobs.ex` `@add_log` (`Jobs.add_log/5` + `get_job_logs/3`, the `:logs` subkey, keep-N trim) | emq.2.2 | ✅ |
| `removeJob-12.lua` | remove one job (+ its dedup) | `jobs.ex` `@remove_job` (`Jobs.remove_job/4` across the four sets; refuses a locked job `EMQLOCK`; releases a caller-supplied `de:` key) | emq.2.2 | ✅ |
| `reprocessJob-8.lua` | retry a finished/failed job | `jobs.ex` `@reprocess` (`Jobs.reprocess_job/3`, `dead`→`pending`, refuses non-dead `EMQSTATE`) | emq.2.2 | ✅ |
| `extendLock-2.lua` | extend one job's lock lease | `jobs.ex` `@extend_lock` (`Jobs.extend_lock/5`, re-score `active` to `TIME`+lease, `EMQSTALE`) | emq.2.3 | 🔨 |
| `extendLocks-2.lua` | extend many leases | `jobs.ex` `@extend_locks` (`Jobs.extend_locks/4`, the batch, returns the un-extendable) | emq.2.3 | 🔨 |
| `releaseLock-1.lua` | release a held lock | folded into the v2 lease model: the lease IS the `active` score, retired by the existing `@complete`/`@retry` transitions; the worker-side plane untracks, it does not double-retire (emq.2.3 D5) | emq.2.3 | 🔨 |
| `moveStalledJobsToWait-9.lua` | the periodic stalled-recovery sweep | `stalled_checker.ex` `check/3` (declares only the sets it touches — never the v1 9-key LIST shape; server-clock) | emq.2.3 | 🔨 |

### B.3 — the parity verdict

**Every v1 capability is accounted for.** Counting the lib + script rows above:

- **✅ shipped** — the substrate, the state machine + branded identity, fair lanes, the scheduler + retry +
  backoff, the read plane (emq.2.1), the operator plane (emq.2.2). The bulk of the v1 surface.
- **🔨 building** — the watch plane (emq.2.3, on disk): events, telemetry **surface**, the lock plane + the
  lock-extension verbs, the explicit stalled-sweep, the cooperative cancel — closed by **emq.2.4** (the parity
  closer + the complete test suite).
- **🔨 the parent/flow family OPEN** — `flow_producer` → **emq.3**: the **single-queue** slice **shipped at
  emq.3.1** (`EchoMQ.Flows.add/3` + `@enqueue_flow` + the `@complete` fan-in + `awaiting_children`; `flow_add` +
  `flow_fanin`), the **child-result reads shipped at emq.3.2** (`children_values/3` + `dependencies/3` + the
  real-result `complete/5` host-only, O1 closed; `flow_children_values`), and the **cross-queue flow shipped at
  emq.3.3** (the `flow:outbox` + `Pump.sweep/1`'s `deliver_flow_completions` + `@flow_deliver`, eventually-consistent;
  `flow_cross_queue`); **failure-policy + `add_bulk` (emq.3.4) is 📐 specced** (the additive `@retry` branch +
  `@flow_fail_deliver` over the §6-reserved `:failed`/`:unsuccessful`); **grandchildren** is 📋 (the V-1 scope
  fork) — the honest bound.
- **📋 scheduled at a named rung** — the **worker abstraction** depth and the worker *registry* read
  (`worker.ex` pause/concurrency/`get_workers`, **distributed** cancel → **emq.6**); the **telemetry contract** +
  the Prometheus export wrapper (`export_prometheus_metrics` → **emq.8**). These are deliberate deferrals to
  confirmed rungs (design ADR-2), not under-ports.
- **— ruled out** — `migration.ex` (`migrate/4`): the design's ADR-0 / §11.11 / roadmap §Seams item 1 —
  drain-precondition; the v2 line has never shipped, so there is nothing to migrate from. The one explicit
  non-feature.

**What still owes what (the Operator's "which emq.x?" answer):** the shipped read/ops/watch surface owes
nothing (the emq.2 cluster CLOSED); flows owe **emq.3.4** (failure-policy + `add_bulk` — specced) + the
grandchildren rung (the V-1 fork); the worker abstraction + distributed cancel owe **emq.6**; the telemetry
contract + Prometheus export owe **emq.8**. No v1 capability is orphaned.

---

## Part C — the forward-feature catalog (the 5-section format)

> The per-feature detail behind Part A's by-Movement set and Part B's parity proof. Every forward feature is
> described here in the canonical 5-section format (Operator directive, the emq-3-4 D-1 documentation contract):
> **Goal · Rationale · 5W · Scope (In / Out) · Acceptance Criteria** — categorized by feature area (Flows ·
> Groups · Batches · Lifecycle controls · Locks · The proof stack). This Part **folds** the former
> `docs/echo_mq/roadmap/{groups,batches,observables,a1-extend-locks}.md` per-area files up into this canonical
> catalog (they are removed once this coverage is verified) and adds the **Flow family** (the active frontier,
> previously absent from the per-feature detail). **Voice tracks status** (the as-built-floor honesty the folded
> files carried, preserved): a SHIPPED capability reads present tense and names the as-built module it deepens;
> a SPECCED capability reads "emq.N builds…"; a PLANNED capability reads "the roadmap plans…". **The Acceptance
> Criteria source** (D-1): a **delivered** feature's AC reference the generated stories catalog
> ([`./stories/`](./stories/) — `mix echo_mq.stories`, the catalogue that cannot drift from code); an **unbuilt**
> feature's AC are the forward spec the rung turns into code (the rung's triad under [`./specs/`](./specs/)).

### C.1 — Flows (the parent/child dependency family — emq.3)

> **The as-built floor (read before reconciling).** The flow family is **`EchoMQ.Flows`**
> (`echo/apps/echo_mq/lib/echo_mq/flows.ex`) over inline `Script.new/2` transitions + a fan-in hook on the
> shipped `EchoMQ.Jobs.@complete`, redesigned A-1-clean from the v1 `flow_producer` (the dependency graph in
> **declared §6 parent subkeys** — `emq:{q}:job:<parent>:{dependencies,processed,failed,unsuccessful}`,
> §6-reserved at the founding — never the v1 data-value `parent_key`). The happy path is SHIPPED end to end
> (emq.3.1–3.3); emq.3.4 closes the failure half; grandchildren is the one deferred depth (the emq-3-4 V-1
> fork). The rung rows: [`./emq.roadmap.md`](./emq.roadmap.md) §the rung ladder (emq.3) + the family contract
> [`./specs/emq.3.md`](specs/emq.3/emq.3.md).

**Parent/child fan-in (single-queue) — ✅ SHIPPED (emq.3.1).**
- **Goal** — a parent job becomes claimable only when all its same-queue children complete (fan-in), atomically
  on one slot.
- **Rationale** — the v1 `flow_producer` fan-out/fan-in capability, redesigned under the v2 declared-keys law
  (the v1 form roots keys in data values — structurally illegal, design §11.10); the smallest coherent flow that
  founds the whole mechanism (the declared-subkey dependency tree + the fan-in gate) without the cross-slot
  complication.
- **5W** — *Who*: a consumer running fan-out/fan-in pipelines. *What*: `EchoMQ.Flows.add/3` (parent + same-queue
  children) + `@enqueue_flow` + the `@complete` fan-in hook + the `awaiting_children` row state. *When*: emq.3.1
  (SHIPPED 2026-06-15). *Where*: `flows.ex` (`add/3`, `@enqueue_flow`); the fan-in branch in `jobs.ex`
  `@complete`; the parent's `:dependencies` STRING counter + `:processed` HASH on the parent's `{q}` slot.
  *Why*: a parent that runs only after its children do, atomic and A-1-clean.
- **Scope** — *In*: same-queue flows (parent + children in one queue → one slot → one atomic script); the parent
  held out of `pending` until `:dependencies` hits zero. *Out*: cross-queue (emq.3.3), child-result reads
  (emq.3.2), failure-policy (emq.3.4) — each its own slice.
- **Acceptance Criteria** — the generated stories ([`./stories/flows.stories.md`](./stories/flows.stories.md));
  the `flow_add` + `flow_fanin` conformance scenarios (43 → 45); the ≥100 determinism loop (the mint-touching
  surface); Apollo BUILD-GRADE (kill 3/3); the durable harness `echo/rungs/bus/emq_3_1_check.sh` PASS 9/9.

**Child-result reads — ✅ SHIPPED (emq.3.2).**
- **Goal** — a parent's handler reads its completed children's results, and the outstanding-dependency count.
- **Rationale** — the v1 `get_children_values`/`get_dependencies` parity; closes emq.3.1's O1 (the `:processed`
  value becomes a real result via the existing `ARGV[5]` seam, the `@complete` Lua byte-unchanged).
- **5W** — *Who*: a flow parent's handler. *What*: `EchoMQ.Flows.children_values/3` (`HGETALL` of `:processed`)
  + `dependencies/3` (`GET` of the `:dependencies` counter, `{:ok, 0}` sentinel) + the real-result `complete/5`
  (`result \\ nil`, host-only). *When*: emq.3.2 (SHIPPED 2026-06-15; NORMAL-risk — no shipped-script edit).
  *Where*: `flows.ex` (`children_values/3`, `dependencies/3`); `jobs.ex` `complete/5`. *Why*: the fan-in payload
  a parent consumes.
- **Scope** — *In*: the two host-only reads + the real-result completion. *Out*: cross-queue (emq.3.3), the
  failure reads (`ignored_failures/3` — emq.3.4).
- **Acceptance Criteria** — the generated stories ([`./stories/flows.stories.md`](./stories/flows.stories.md));
  the `flow_children_values` conformance scenario (45 → 46); the durable harness `emq_3_2_check.sh` 8/8
  Director-reproduced.

**Cross-queue flow — ✅ SHIPPED (emq.3.3, this run).**
- **Goal** — a parent fans in over children in *different* queues (the v1 shape — a parent in `orders`, children
  in `validation`/`inventory`/`payments`).
- **Rationale** — the v1 flow's defining cross-queue shape; under the braced keyspace a parent and a child in
  different queues are on different cluster slots, so the fan-in decrement cannot reach the parent atomically (no
  single Lua spans two slots) — the genuinely hard slice the family deferred to its own rung.
- **5W** — *Who*: a consumer running cross-queue pipelines. *What*: the cross-queue admit path on `add/3`
  (host-orchestrated, parent-first, fail-closed) + the **completion-signal hop** — the child emits to a durable
  `emq:{C}:flow:outbox` on its own slot (atomic with the active-ZREM, an additive `@complete` branch, the
  single-queue branch byte-frozen), and `EchoMQ.Pump.sweep/1`'s third pass `deliver_flow_completions` delivers
  the decrement on the parent's slot via `@flow_deliver` (the `:processed` HSETNX idempotency guard). *When*:
  emq.3.3 (SHIPPED 2026-06-15; HIGH-risk — a shipped-script edit + a new cross-slot mechanism → Apollo
  MANDATORY). *Where*: `flows.ex` (the admit path), `jobs.ex` (`@complete` cross-queue branch), `pump.ex`
  (`deliver_flow_completions` + `@flow_deliver`); the `flow:outbox` per-queue key + the child's `parent_queue`
  field. *Why*: the cross-queue fan-in, eventually-consistent + idempotent.
- **Scope** — *In*: FLAT cross-queue (a parent + its DIRECT cross-queue children), eventually-consistent
  (released on the next sweep tick, **never** "atomic across queues"), at-least-once made effectively-once.
  *Out*: failure-policy + bulk (emq.3.4), grandchildren (the V-1 fork), the flow-subkey cleanup (the lifecycle
  rung).
- **Acceptance Criteria** — the generated stories (regenerated post-ship); the `flow_cross_queue` conformance
  scenario (46 → 47); the ≥100 determinism loop; Apollo BUILD-GRADE; the durable harness `emq_3_3_check.sh`
  9/9.

**Failure-policy + bulk add — 📐 SPECCED (emq.3.4 builds this).**
- **Goal** — a flow whose child **dies** terminates: the parent **fails** (the default) or **proceeds** past the
  ignored failure — instead of hanging in `awaiting_children` forever; plus bulk flow submission.
- **Rationale** — a correctness gap, not a nicety: today the parent is released only by a child *completing*, so
  a child that dies (`@retry`'s dead-letter arm, `jobs.ex:254-259`) never reaches the parent and the flow stalls
  — the inverse of the v1 default ("if a child fails, the parent will also fail", `flow_producer.ex:76-82`).
  `add_bulk` is the last unported v1 producer verb.
- **5W** — *Who*: a consumer whose flow has a failable child (and one submitting many flows at once). *What*: the
  per-child `fail_parent_on_failure` (default) / `ignore_dependency_on_failure` options over the
  **already-§6-reserved** `:failed`/`:unsuccessful` subkeys (an additive `@retry` dead-letter branch routes a
  same-queue death atomically; a cross-queue death rides the same `flow:outbox` + sweep via `@flow_fail_deliver`,
  idempotent); `EchoMQ.Flows.add_bulk/3` (N flows, fail-closed per flow); `ignored_failures/3` (the v1
  `get_ignored_children_failures` read). *When*: emq.3.4 builds this (SPECCED — the triad
  [`./specs/emq.3.4.md`](./specs/emq.3/emq.3.4.md); HIGH-risk — a shipped `@retry` edit → Apollo MANDATORY). *Where*:
  `flows.ex` (the policy flags + `add_bulk/3` + `ignored_failures/3`), `jobs.ex` (the additive `@retry` branch,
  the dead-letter body byte-frozen), `pump.ex` (the KIND dispatch + `@flow_fail_deliver`). *Why*: a flow that
  terminates either way; the producer surface completed.
- **Scope** — *In*: the FLAT failure-policy (one parent level) + `add_bulk/3` + the ignored-failures read. *Out*:
  **grandchildren / deep recursion** (the V-1 scope fork RULED → Arm A, D-2: the locked Out → emq.3.5), the TTL
  auto-cancel of a stuck flow (emq.6), `remove_dependency` (the v1 third option — deferred), the flow-subkey
  cleanup (the lifecycle rung).
- **Acceptance Criteria** (the forward spec — the rung turns it into code) — the triad
  [`./specs/emq.3.4.md`](./specs/emq.3/emq.3.4.md) INV1–INV11; the `flow_fail_parent`/`flow_ignore_dep`/`flow_add_bulk`
  conformance scenarios (47 → 50); the `:valkey` failure suite + the ≥100 determinism loop; the `@retry`
  dead-letter body + `@complete` + `@flow_deliver` byte-unchanged (the HIGH-risk regression bound); Apollo
  MANDATORY BUILD-GRADE. (On ship, the AC re-home to the generated `stories/flows.stories.md`.)

**Grandchildren / deep recursion — 📋 PLANNED (emq.3.5 — the V-1 scope fork RULED → Arm A, D-2).**
- **Goal** — a flow tree deeper than one parent level — a cross-queue child that is itself a flow-parent of
  grandchildren (the v1 recursive `build_flow_commands`, `flow_producer.ex:51-56/:238`).
- **Rationale** — the v1 flow is a recursive tree; the v2 family built it flat (one parent level) through
  emq.3.4, so the recursive depth is the last flow capability — a multi-level fan-in where a grandchild's
  completion releases the child whose completion then signals the parent (two hops, each crossing a slot for a
  cross-queue tree).
- **5W** — *Who*: a consumer running multi-level dependency trees. *What*: the roadmap plans a recursive-tree add
  + multi-level fan-in (composing the emq.3.3 cross-queue completion + the emq.3.4 failure propagation). *When*:
  **emq.3.5** — the **emq-3-4 V-1 scope fork RULED → Arm A** (D-2): the locked Out of emq.3.4, routed here as its
  own rung (a later Arm-B fold into emq.3.4 stays a zero-cost Operator option); recorded NOT built. *Where*:
  `flows.ex` (the recursive add) + the existing
  fan-in/fail-deliver mechanisms applied per tree level. *Why*: full v1 flow-tree parity.
- **Scope** — *In* (when slotted): the recursive tree + multi-level fan-in/failure propagation. *Out* (until
  slotted): everything — it is the deferred depth; emq.3.1–3.4 build the flat shape.
- **Acceptance Criteria** (the forward spec, when the rung is authored) — the recursive add lands a tree of
  arbitrary depth; a grandchild's completion releases its parent (the child), whose completion then releases the
  grandparent; the failure-policy propagates per level; the ≥100 loop; Apollo MANDATORY (a shipped-script
  surface). The triad is authored when the V-1 fork slots the rung.

### C.2 — Groups deepened (the fair-lanes family — emq.4)

> **The as-built floor (read before reconciling).** Groups are not net-new — the BASICS shipped in Movement 0 as
> **`EchoMQ.Lanes`** (`echo/apps/echo_mq/lib/echo_mq/lanes.ex`, gated G1–G8): the per-group pending lane
> (`emq:{q}:g:<group>:pending`), the rotating fair claim over the ring (`emq:{q}:ring`, `LMOVE`-rotated one step
> per claim — fairness CONSTRUCTED, never hashed), the per-group concurrency ceiling (`glimit`/`gactive`,
> `Lanes.limit/4`), per-group pause/resume (`Lanes.pause/3`·`resume/3`), the park-don't-poll wake
> (`emq:{q}:wake`). **emq.4 DEEPENS this module** — it does not build a queue; the voice is "emq.4 extends Lanes
> with…", never "Lanes builds…" (it exists). Folded from the former `roadmap/groups.md`.

**Goal** — multi-tenant fairness depth on the shipped `EchoMQ.Lanes`: per-group rate limiting, default/per-group
concurrency, max-group-size back-pressure, intra-group priority, and group-aware recovery — so one shared queue
serves thousands of tenants fairly under contention.

**Rationale** — a shared queue across many tenants needs the depth established queueing systems proved at scale:
without it one tenant can fill the queue and starve the rest. The basics (rotation, per-group ceiling,
pause/resume) ship; emq.4 adds the fairness knobs a production multi-tenant bus needs — temporal fairness (rate
limits) beside the existing concurrency ceiling, and recovery that re-admits a lane the instant a slot frees.

**5W** — *Who*: a multi-tenant operator running one shared queue across many tenants (the per-user transcoding
case); **codemoji**: per-player throttling so one hot player's guess lane cannot consume the drain budget
(emq.4 carries codemoji's per-player `EchoMQ.Lanes` fairness to cluster scale). *What*: per-group rate limiting (global +
per-group override), default + per-group concurrency, max group size (back-pressure with a typed refusal),
intra-group priority, group-aware recovery. *When*: emq.4 (Movement II; the per-group ceiling + pause/resume
SHIPPED in Movement 0, the deepening is the rung). *Where*: extends `EchoMQ.Lanes` (`@gclaim` rotation,
`@glimit`/`gactive`, `@genqueue` admission, the `ring`/`paused`/`wake` keyspace). *Why*: even processing across
many groups under contention; no single group monopolizes throughput.

**Scope** — *In*: per-group rate limiting (the temporal fairness knob — a per-group `EMQRATE`-class window gating
`@gclaim`); the per-group rate-limit override (heterogeneous tenant quotas); the default (all-groups) concurrency
ceiling layered over the shipped per-group `glimit`; max group size (a `ZCARD lane >= max` refusal arm in
`@genqueue` — a new `EMQ*` wire class registered WITH its conformance probe, the additive-minor law); intra-group
priority (a non-zero lane score on the existing `g:<group>:pending` ZSET — no new key family); group-aware
recovery (re-admitting a lane the moment a completion frees a concurrency slot under contention). *Out*: the
basics already shipped (rotation, per-group ceiling, per-group pause/resume — Movement 0, recovery deepens only);
**pluggable execution backends / FLAME** (HELD at the program seam §Seams item 8, NOT emq.4 — a runner/transport
concern on `EchoMQ.Consumer`, not a `Lanes` keyspace deepening — the one folded feature that breaks the
groups→emq.4 mapping); batches × groups affinity (emq.5).

**Acceptance Criteria** (the forward spec — the rung turns it into code; the AC re-home to the generated
`stories/groups.stories.md` as features ship) — the emq.4 triad (authored when the rung is reached) names: a
flooding group is throttled without starving the others (the rate-limit gate); a group at its concurrency
ceiling is parked and re-admitted on a freed slot (recovery); an enqueue past max-group-size returns the typed
refusal; the prior conformance scenarios byte-unchanged + the new group scenarios registered additive-minor; the
≥100 determinism loop (the process/mint-touching lane surface). The generated `stories/groups.stories.md`
(`mix echo_mq.stories`) already carries the SHIPPED group basics (4 scenarios).

### C.3 — Batches (the bulk-consume family — emq.5)

> **The as-built floor (read before reconciling).** Batches are a Movement II *consume* family — NOT yet built.
> The PRODUCER half co-locates with emq.1/emq.2.2: `EchoMQ.Jobs.enqueue_many/3` (bulk enqueue) already ships.
> What emq.5 builds is the **batch CONSUME** family: a worker that fetches up to N jobs in one atomic claim
> instead of one at a time. The voice is forward-tense — "emq.5 builds…" / "the roadmap plans…"; no batch-consume
> surface exists on disk yet. Folded from the former `roadmap/batches.md`.

**Goal** — high-throughput bulk consumption: a worker fetches up to `size` jobs in one atomic claim, with
shaping (`min_size`/`timeout`), group affinity, batch concurrency, partial-failure isolation, batch lifecycle
events, dynamic rate, manual pull, and dynamic delay — amortizing the per-job round-trip and lease bookkeeping
across N jobs.

**Rationale** — for a high-throughput consumer the per-job round-trip dominates; a batch claim pops up to `size`
members under one server-clock read. The shaping knobs bound the latency/throughput trade-off; affinity composes
with the emq.4 groups to keep per-tenant batches fair; partial-failure isolation reuses the shipped single-job
`@complete`/`@retry` so one poison job does not fail the whole batch.

**5W** — *Who*: a high-throughput consumer where the per-job round-trip dominates (bulk ingestion, log shipping,
reporting); **a downstream consumer**: a periodic sweep draining thousands of accumulated rows in batches. *What*: batch
consume + `min_size`/`timeout` shaping + group affinity + batch concurrency + partial-failure isolation + batch
events + dynamic rate + manual pull + dynamic delay. *When*: emq.5 (Movement II; the bulk PRODUCE half
`enqueue_many/3` ships, the consume family is the rung). *Where*: extends the claim surface
(`EchoMQ.Jobs.claim/3` → a new batch-claim script popping up to `size` under one `TIME` read) + a batch-aware
`EchoMQ.Consumer` + the shipped `EchoMQ.Lanes` ring (affinity) + the schedule fence (dynamic delay) + the
`EchoMQ.Events` seam (batch events). *Why*: raise drain throughput under load without breaking per-tenant
fairness.

**Scope** — *In*: batch consume (the multi-pop generalization of the single `@claim`); `min_size`/`timeout`
shaping (wait for at least `min_size`, no longer than `timeout`); group affinity (homogeneous batches served
round-robin across the ring, gates emq.4); batch concurrency (one in-flight batch per group, sibling to
`gactive`); partial-failure isolation (each member resolves through the shipped `@complete`/`@retry`); batch
lifecycle events (on the shipped `EchoMQ.Events` seam, registered additive-minor); dynamic rate (runtime-mutable,
on the emq.4 rate floor); manual pull (explicit fetch-process-resolve, the multi-job generalization of the manual
`claim/3`); dynamic delay (re-score an active job onto the schedule set from the handler). *Out*: the bulk
PRODUCE half (`enqueue_many/3` — shipped, emq.1/emq.2.2); group affinity gates on emq.4's deepened rotation; the
durable replayable stream (the emq3.2 stream tier, NOT the `EchoMQ.Events` pub/sub seam).

**Acceptance Criteria** (the forward spec — the rung turns it into code; AC re-home to a generated
`stories/batches.stories.md` on ship) — the emq.5 triad names: a batch claim returns up to `size` (at least the
available) under one `TIME` read; `min_size`/`timeout` bound batch size and latency simultaneously (never starve,
never thrash); an affinity batch targets one ring lane and keeps the rotation fair; a partly-failed batch retries
the poison member alone and completes the rest; the prior conformance byte-unchanged + the new batch scenarios
additive-minor; the ≥100 determinism loop (the batch-claim mint surface).

### C.4 — Lifecycle controls (TTL, distributed cancel, checkpoints — emq.6)

> **The as-built floor (read before reconciling).** The LOCAL half of cancellation already shipped in emq.2.3:
> **`EchoMQ.CancellationToken`** (the worker-side cooperative token — `new`/`cancel`/`check`/`check!`) lets a
> handler observe a cancel signal and stop cooperatively; the lock plane (`EchoMQ.Locks` — `track_job`/
> `untrack_job`/`get_tracked_job_ids`) knows which node holds a job; the stalled sweep
> (`EchoMQ.Stalled` `:sweep` timer + server-clock scan) is the recovery sweep. What emq.6 builds is the
> **DISTRIBUTED** form + TTL + checkpoints. The voice: the local token + lock plane + stalled sweep are SHIPPED
> (present tense); the distributed cancel, TTL, and checkpoints are forward-tense. Folded from the former
> `roadmap/observables.md`.

**Goal** — bounded, cancelable, resumable worker lifecycles: a cancel raised on ANY node reaches the handler
wherever it runs (distributed cancel), a job that runs too long is auto-canceled (TTL), and a long stateful job
resumes from its last checkpoint after a crash (resumable state).

**Rationale** — a production bus needs to stop distributed work cleanly and bound a job's wall-clock time; the
local cooperative token (shipped) gives a handler a stop signal it polls, but a cluster-wide cancel must
propagate to the node actually running the handler, and a long job that fails partway should resume rather than
restart.

**5W** — *Who*: an operator/handler stopping a running job from anywhere (a UI cancel button, a supervisor
abandoning work), bounding a job's wall-clock time, or running long stateful restartable jobs; **a downstream
consumer**: a long-running worker's bounded lifecycle — a long computation canceled cluster-wide or auto-canceled
on TTL, a multi-stage job resuming from its last completed stage. *What*: a distributed cancel that reaches a handler on
any node; a TTL that auto-cancels a job exceeding its max processing time; checkpoints (the persisted last value
a retried job resumes from). *When*: emq.6 (Movement II; the LOCAL cooperative token + lock plane + stalled sweep
ship at emq.2.3). *Where*: extends `EchoMQ.CancellationToken` (the shipped worker-side token) coordinated across
nodes via the `EchoMQ.Locks` lock plane (which node holds the job — shipped) + the `EchoMQ.Events` pub/sub seam
(deliver the cancel); TTL extends the `EchoMQ.Stalled` sweep (the server-clock timer — shipped) with a
per-job/per-name deadline; checkpoints extend the shipped progress/data persistence (`update_progress/4`·
`update_data/4`) into a resume contract the `@retry` path reads. *Why*: clean stop of distributed work; bounded
worker lifecycles; resume long jobs from the last checkpoint.

**Scope** — *In*: the distributed cancel (raised on any node, delivered to the handler wherever it runs); the TTL
auto-cancel (a per-job/per-name max processing time, swept); checkpoints (a persisted last value the retry
resumes from). *Out*: the LOCAL cooperative cancel + the lock plane + the stalled sweep (shipped, emq.2.3 — the
floor emq.6 deepens); the raw progress/data persistence (shipped, emq.2.2 — checkpoints formalize it into a
resume contract).

**Acceptance Criteria** (the forward spec — the rung turns it into code) — the emq.6 triad names: a cancel raised
on node A reaches a handler running on node B (the distributed delivery, via the lock plane + the event seam); a
job exceeding its TTL is auto-canceled by the sweep; a retried checkpointed job resumes from its last persisted
value rather than restarting; the prior conformance byte-unchanged + the new lifecycle scenarios additive-minor;
the ≥100 determinism loop (the process/sweep-touching surface).

### C.5 — Locks (the lock plane + the `@extend_locks` A-1 convention)

> **The as-built floor (read before reconciling).** The worker-side lock plane shipped in emq.2.3:
> **`EchoMQ.Locks`** (`track_job`/`untrack_job`/`get_active_job_count`/`get_tracked_job_ids`/`is_tracked?`) +
> the lock-extension verbs `EchoMQ.Jobs.extend_lock/5`/`extend_locks/4` (re-score the `active` member to
> `TIME`+lease, the server clock, `EMQSTALE` on a stale attempts-token — never a separate `:lock` string). The
> `@extend_locks` A-1-wording question raised by Apollo Y-3 §4 is **RESOLVED** in the design canon (see below).
> Folded from the former `roadmap/a1-extend-locks.md` — **the fork it surfaced is now closed.**

**The `@extend_locks` A-1 slot-rooted-ARGV convention — ✅ RESOLVED (design §1 S-6, Operator-ratified
2026-06-14).**
- **Goal** — a blessed, stated rule for a variadic dynamic-job-id Lua script that derives each per-job key
  in-script from an ARGV base (rather than a declared `KEYS[n]`).
- **Rationale** — `EchoMQ.Jobs.extend_locks/4` (the batch lock-extension verb, the v1 `extendLocks` parity)
  extends an unknown-at-author-time NUMBER of leases, so it passes the variadic id pairs + the queue base through
  `ARGV` and derives each `jk = base .. 'job:' .. id` in-script. Read strictly against S-6, that derived key is
  rooted in an ARGV operand, not a declared `KEYS[n]` — so the A-1-wording owed a one-time ruling: is an ARGV
  base that provably carries the `{q}` slot an A-1-compatible root?
- **5W** — *Who*: the program (the keyspace-discipline maintainers); the implementor of any future variadic
  dynamic-id script. *What*: the resolution — an ARGV base MAY root an in-script derived key IFF it provably
  carries the same braced `{q}` slot as a declared `KEYS[n]` (the slot-soundness obligation discharged
  explicitly). *When*: **RESOLVED 2026-06-14** — the design canon §1 S-6 carries "The slot-rooted-ARGV
  clarification (Operator-ratified 2026-06-14 — emq-3 @extend_locks A-1-wording, Apollo Y-3 §4)" = Arm 1
  ratified; the lint that enforces it is emq.8. *Where*: `emq.design.md` §1 S-6 (the wording); the as-built
  `EchoMQ.Jobs.@extend_locks` (A-1-compatible AS-IS, no code edit); emq.8 lints the corpus against the ruled
  wording. *Why*: codify the established `Jobs.*` convention (used precisely where the id set is dynamic; the
  singular `@extend_lock` declares both keys the textbook way) with the slot-soundness obligation that makes it
  safe, before the Movement II dynamic-id scripts (max-group-size, batch-claim) are authored.
- **Scope** — *In* (settled): the S-6 wording extension (an ARGV-rooted derived key is A-1-compatible iff
  slot-provable against a declared `KEYS[n]`); the obligation every future ARGV-rooted derived key inherits.
  *Out*: the strict Arm 2 (mandate a declared `KEYS[n]` root, edit the shipped `@extend_locks`) — **NOT** chosen
  (the byte-empty-diff purity the slot-soundness obligation already secures was not worth churning a shipped,
  gated surface); the emq.8 A-1 lint that mechanically enforces the ruled wording (the rung that owns it).
- **Acceptance Criteria** (the resolution's proof) — the design canon §1 S-6 records the slot-rooted-ARGV
  clarification (verifiable: `emq.design.md:102-113`); the as-built `@extend_locks` is unedited and gated
  (`Keyspace.job_key/2` raises on an ill-formed id host-side before the wire); emq.8's A-1 lint (when authored)
  enforces "every ARGV-rooted derived key is slot-provable against a declared `KEYS[n]`."

### C.6 — The proof stack (conformance, the engine matrix, the telemetry contract, the benchmark gate — emq.8)

> **The as-built floor (read before reconciling).** The conformance harness ships and grows every rung —
> **`EchoMQ.Conformance`** (`scenarios/0` + `run/2 → {:ok, n}`, one CONF line per scenario, the count pinned in
> two tests; **47 scenarios** as built); the telemetry **surface** fires (`EchoMQ.Meter`, emq.2.3 — the
> `[:emq, …]` lifecycle, zero cost when `:telemetry` is absent); the engine claims are phrased against Valkey
> with honest-row reporting. What emq.8 builds is the three-layer **proof**: the conformance corpus closed, the
> engine matrix, the telemetry **contract** (asserting the surface emq.2.3 fires), the benchmark gate.

**Goal** — turn the engine claims into a parse and a number: the conformance suite (the wire-level referee), the
engine matrix (the truth row + the historical row, computed floor), the telemetry contract (asserting the
surface fires), and the benchmark gate (the published table with the rival's strengths recorded beside
EchoMQ's).

**Rationale** — a production bus's claims must be enforced, not narrated: the conformance scenarios are the
higher-signal gate (the emq.1 L-1 lesson — they caught self-inflicted bugs the unit suites missed); the matrix
keeps the engine-version claims honest; the telemetry contract proves the surface the watch plane fires; the
benchmark records the rival numbers beside EchoMQ's rather than claiming a win.

**5W** — *Who*: the program (the proof the whole bus stands on); a consumer trusting the engine claims;
**echo_bot (planned)**: the telemetry contract a notifications consumer's observability would gate on. *What*: the conformance corpus (the additive-minor
scenario set), the engine matrix (Valkey current stable the truth row + Redis 7.2.x the historical row, the
computed floor in every row), the telemetry contract (asserting the `[:emq, …]` surface fires — ADR-2's
two-layer split), the benchmark gate (the published table, rival strengths recorded). *When*: emq.8 (Movement
II, the last rung; the conformance harness + the telemetry surface ship and grow every prior rung). *Where*:
`EchoMQ.Conformance` (the corpus), a matrix surface, the `EchoMQ.Meter` contract, a benchmark harness; the
`@extend_locks` A-1 lint (C.5) lands here against the ruled wording. *Why*: engine claims turned into a parse +
a benchmark; the proof stack the program thesis rests on.

**Scope** — *In*: the conformance corpus closed (the referee habit); the engine matrix (truth + historical rows,
computed floor); the telemetry contract (the surface emq.2.3 fires, asserted); the benchmark gate (honest rival
numbers); the A-1 lint (the ruled slot-rooted-ARGV wording, C.5). *Out*: the telemetry SURFACE (shipped, emq.2.3
— the contract proves it); the conformance scenario REGISTRATION (every rung adds its own additive-minor — emq.8
proves the corpus, it does not retro-register).

**Acceptance Criteria** (the forward spec — the rung turns it into code) — the emq.8 triad names: the conformance
corpus passes whole on the truth row (`run/2 → {:ok, n}`) with the count pinned; the matrix records the truth +
historical rows with the computed floor; the telemetry contract asserts every `[:emq, …]` event the watch plane
fires; the benchmark publishes EchoMQ's numbers beside the rival's strengths; the A-1 lint passes over the
corpus (every ARGV-rooted derived key slot-provable). The conformance generated catalogue
([`./stories/`](./stories/)) is the living proof the corpus cannot drift from code.

---

The binding design: [`./emq.design.md`](./emq.design.md). The delivery plan: [`./emq.roadmap.md`](./emq.roadmap.md).
The emq.2 parity carve: [`./specs/emq.2.design.md`](specs/emq.2/emq.2.design.md). The parity-closing triad:
[`./specs/emq.2.4.md`](specs/emq.2/emq.2.rungs/emq.2.4.md). The worked consumer: `echo/apps/codemoji`; the planned consumer: `echo/apps/echo_bot`.
The as-built floor: `echo/apps/echo_mq/lib/echo_mq/*.ex` + `echo/apps/echo_wire`. The v1 feature reference:
`echo/apps/echomq/lib/echomq/*.ex` + `echo/apps/echomq/priv/scripts/*.lua`.
