# EMQ1 · the v1 to v3 EchoMQ command matrix

> **PROPOSED** — the v1 BullMQ-derived Lua command corpus mapped to its state-of-the-art v3 (BCS + EchoMesh ready) reimplementation.

## Rationale

The 50 v1 Lua commands under `echo/apps/echomq/scripts/commands/` are the valuable, near-complete job-system command surface that arrived in v1: a full admission / scheduling / claim / finish / flow / lock / metrics / removal grammar, hardened in BullMQ and lifted into the frozen v1 bus. The v2 `echo_mq` bus ported a **subset** of that surface under the v2 laws — re-derived, never copied — leaving the rest unbuilt or deliberately retired. This matrix maps **all 50** of them v1 → v3, so the state-of-the-art EchoMQ Bus is **BCS + EchoMesh ready**: every command either holds as-shipped, gets a PROPOSED re-derivation, or is honestly named as retired/folded.

The structural spine that governs every row: **v1 Lua roots keys in data values** — a `parentKey` read out of a job hash (`HMGET jobKey "parentKey"`), a per-job key spliced from an `ARGV` prefix inside the script body (`prefix .. jobId`), a scheduler-occurrence id built from a `ZSCORE`-returned millisecond (`repeat:<id>:<millis>`), a `<base><jobId>:lock` string built from a `cmsgpack`-unpacked base. Under the v2 **declared-keys law (A-1 / S-6)** a key must be in `KEYS[]` or grammar-rooted from a declared `KEYS[n]`; a key sourced from a data value is structurally illegal. Therefore **every v3 form is a re-derivation, never a lift** — the value of v1 is the *grammar of capabilities* it enumerates, not the Lua that implements them.

## 5W

- **Why** — the v1 corpus is the most complete statement of *what a job system must do*; the v2 bus is the most complete statement of *how it must be done lawfully*. The gap between them is unmapped. This spec closes it, so the bus that BCS and EchoMesh build on has a single, audited command surface with every v1 capability accounted for.
- **What** — a command-by-command matrix: each of the 50 v1 Lua scripts, its purpose, its v2 as-built status (PORTED / PARTIAL / NOT YET / retired-folded), its PROPOSED v3 decision under the declared-keys laws, and what each integration target (BCS, EchoMesh) needs from it.
- **Who** — authored for the EchoMQ program (the architect/implementor/evaluator triad over `docs/echo_mq/`), and for the two consuming courses: BCS (`/bcs`) and EchoMesh (`/mesh`, `/art`).
- **When** — after the v2 bus reached its operator/flow/lock/metrics plane (emq.2.x / emq.3.x as-built) and before the stream-tier and lanes-deepened rungs (emq.3.x stream / emq.4) that BCS + EchoMesh demand; the PROPOSED column is the forward ladder.
- **Where** — the v1 corpus `echo/apps/echomq/scripts/commands` → the v2 bus `echo/apps/echo_mq` → the v3 BCS/EchoMesh-ready form.

## Motivation — the integration targets

Two real consumers shape every v3 decision in this matrix. Neither is satisfied by a lift of v1; each needs the command surface re-derived to a specific property.

**BCS — the Branded Component System architecture.** BCS makes the **14-byte branded id** the one addressable entity across every surface: "a fill matched on a consistency-first book is the same addressable entity in the availability-first cache that serves it, the stream that logs it, the object store that retains it, and the worker that prices it" (`docs/echo/mesh/markdown/index.md`). From the command surface BCS needs: **the order theorem** (byte order = mint order, no second index) as the deterministic-admission floor a consumer's hot path stands on — for codemoji, the per-player guess stream; **single-writer claim** with the lease as the only ownership proof (codemoji scores each guess under a single authority); **fair lanes** (per-player / per-tenant, one Lanes group per player) replacing per-job priority so a many-tenants-one-queue surface has no noisy-neighbour starvation; **flows** as the composite work unit (a parent job whose children are fanned in by branded id); and an **operator plane** (remove / reprocess / drain / clean / pause) over branded ids for a consumer's runbook.

**EchoMesh — CAP segmented across a BCS stack on the BEAM.** EchoMesh treats CAP as "a menu to read, not a wall to scale," and **segments** the consistency↔availability trade subsystem by subsystem (`docs/echo/art/markdown/echomesh/index.md`). From the command surface it needs each verb placed on the dial: the **consistency-first** surfaces — single-writer claim, single-id state-of-record reads, flow fan-in, destructive control-plane acts — "refuse rather than risk a second writer" under partition; the **availability-first** surfaces — counts, metrics, set/hash-shaped reads, paged retention reads — "degrade rather than stop," served from the nearest replica with a bounded staleness budget. The segmentation only coheres because the branded id is shared across the dial, and the substrate is **transparent** (the same code from a laptop to a fleet, placement by the branded id over a consistent-hashing ring). The matrix's **BCS** and **EchoMesh** columns record, per command, which property the v3 form must carry. (EchoMesh is a forward concept — every EchoMesh claim here is in proposed voice, never asserted as shipped.)

## The matrix

All 50 v1 commands, grouped by family. 

Columns: **Command** · **v1 (purpose)** · **v2 status** · **v3 decision (PROPOSED)** · **BCS** · **EchoMesh**. v2 status is as-shipped present tense; every v3 claim is forward / PROPOSED.

### add-core

| Command | v1 (purpose) | v2 status | v3 decision (PROPOSED) | BCS | EchoMesh |
|---|---|---|---|---|---|
| `addStandardJob-9` | Immediate admission: INCR id, store row + push to wait/paused LIST, marker, events | **PORTED** — `Jobs.enqueue/4` (`@enqueue`); declared 2-key, branded-`JOB` gate, score-0 mint-ordered `pending` ZSET | Keep the as-built `@enqueue`; add the parent/flow edge back as a **declared** dependents-set, never a data-rooted `parentKey` | The order theorem (byte order = mint order, no second index) is the deterministic-admission floor for the hot path | Availability-first/segmented: idempotent at-least-once admission survives a partition; one branded id across bus/cache/stream/store |
| `addDelayedJob-6` | Delayed admission: store row, pack run-at into a `delayed` ZSET score with a 12-bit id tiebreak, marker | **PORTED** — `Jobs.enqueue_at/5` + `enqueue_in/5` (`@schedule`); `enqueue_in` scores from server `TIME` | Keep `@schedule` as a **visibility fence** (not a second queue); mint-ordered id stays sort key once promoted; server clock prices the delay | Scheduled and retry jobs re-score onto one `schedule` set — one timing source for the consuming app | The trade-staleness-for-availability dial in physical form: a server-clock fence, never the caller's clock |
| `addPrioritizedJob-9` | Priority admission: store row, `priority*2^32 + INCR(pc)` packed score, global `prioritized` ZSET | **PORTED (folded/re-aimed)** — no `prioritized` set; priority is per-group fairness via `Lanes.enqueue/5` (`@genqueue`, D-9) | Keep fair lanes as the priority model (rotating ring = the rota); intra-group priority = a non-zero lane score on `g:<group>:pending`, no new key family (emq.4) | Fair lanes give many-tenants-one-queue isolation a global priority number cannot | Consistency-first/coordinated: bounded, fair, per-identity service is a server-side invariant, not a client hint |

### add-parent-repeat

| Command | v1 (purpose) | v2 status | v3 decision (PROPOSED) | BCS | EchoMesh |
|---|---|---|---|---|---|
| `addParentJob-6` | Add a flow **parent** held until children finish; register the child in a parent dependency SET (a parent_key read from a data value) | **PORTED** — `Flows.add/3` (+ `add_bulk/3`, `children_values/3`, `ignored_failures/3`, `dependencies/3`); `@enqueue_flow`/`@hold_parent`/`@enqueue_flow_child` | Keep the atomic same-queue + parent-first cross-queue add; add a **roster subkey** (Fork R2.B) so the mesh can list which legs remain, not just the count | The flow IS the BCS multi-leg work unit — parent = an order, children = validation/inventory/payment legs, fanned in by branded id | Consistency-side for same-queue (one slot, atomic fan-in); availability-side for cross-queue (eventually-consistent outbox fan-in, INV5/INV7) — CAP segmented per flow shape |
| `addRepeatableJob-2` | Register/override a **repeatable** schedule; on override rebuild the stale delayed id from data | **PORTED** — `Repeat.register/6` · `cancel/3` · `due/3` · `advance/4` · `count/2` over `emq:{q}:repeat` (zset) + `emq:{q}:repeat:<name>` (hash); cadence = `Pump` | Keep the registry + fresh-mint-per-occurrence; extend the record with the v1 `pattern`/`tz`/`endDate` cron fields, next score computed host-side | A daily periodic sweep registers once; every run is a first-class, mint-ordered, browsable job | Consistency-side — one queue owns its `{q}` repeat slot; the owning node's pump is the single writer that mints + advances |

### scheduler

| Command | v1 (purpose) | v2 status | v3 decision (PROPOSED) | BCS | EchoMesh |
|---|---|---|---|---|---|
| `addJobScheduler-11` | Upsert a scheduler + materialize its next occurrence; compute next-millis, evict the previous, resolve slot collisions (`-10`/`-11`) | **PARTIAL** — `Repeat.register/6` + `Pump` cover registration + cadence; the in-script collision codes have no v2 equivalent (fresh mint makes them moot) | Keep `register/6`; add `upsert` (re-register a live name updates + re-scores); fresh branded `JOB` id per occurrence; next-millis from server `TIME` at the pump | A consumer registers periodic cadences once; each run is a first-class browsable `JOB` on the queue's slot | Consistency-side: the registry is a per-`{q}` slot fact, so a partition isolates one queue's cadence, never the mesh's |
| `getJobScheduler-1` | Read a scheduler record: `ZSCORE` next-run + `HGETALL` template hash | **PARTIAL** — `Repeat.count/2` reads depth; `due/3` reads records due now; no single-name point read of one registration's record+score | Add `get(conn, queue, name)` → `{score, %{every_ms, template}}` over the two declared keys; honest-row `:absent` | Lets an operator/console inspect one registered cadence by name without walking the due set | Read-side; a point read of one slot's registry, available even when other slots are partitioned |
| `removeJobScheduler-3` | Remove a scheduler + its one next-programmed job (the synthetic `repeat:<id>:<millis>` job) | **PORTED** — `Repeat.cancel/3` (`@repeat_cancel`): `ZREM` member + `DEL` record | Keep `cancel/3`; the v1 "delete the next programmed job" half is **not lifted** (the next occurrence is a freshly-minted `JOB`, removed via the Jobs surface) | Cancelling a cadence stops future mints cleanly; in-flight occurrences drain as ordinary jobs | Consistency-side; cancellation is a single-slot, partition-local mutation |
| `updateJobScheduler-12` | Iterate a scheduler: recompute next-millis, add the next occurrence, guard re-entry via a producer-id match, emit `duplicated` on collision | **PORTED** — `Repeat.advance/4` (`@repeat_advance`): re-score to now+`every_ms`; sweeps a dangling member when cancelled mid-sweep; `Pump` drives it | Keep `advance/4` + the pump; the v1 producer-id re-entry guard is **superseded** by the pump's single owner-started sweep (no data-rooted producer-id string) | The pump advances each consumer's cadence idempotently; a mid-sweep cancel is swept, never resurrected | Availability dial: the pump's owner-started cadence keeps occurrences flowing per slot without cross-slot coordination |
| `updateRepeatableJobMillis-1` | Legacy: re-score an existing repeatable by custom or legacy key | **PARTIAL** — `advance/4` re-scores a registration; no separate legacy re-score-by-arbitrary-key verb (one name-keyed registry, no key duality) | Fold into `advance/4` (re-score to an explicit next-at); the v1 legacy/custom-key branch is **dropped** | One re-score path; no legacy key-shape branching for the platform to special-case | Consistency-side; a single-slot re-score, partition-local |
| `removeRepeatable-3` | Legacy + new removal of a repeatable; `ZREM` registration, `DEL` hash, remove the next programmed job | **PORTED** — `Repeat.cancel/3` covers the **new** form; the legacy concat-key path has no v2 equivalent (no legacy ids in the v2 keyspace) | `cancel/3` is the single removal verb; the dual legacy/new branches **collapse to one** | Removing a repeatable is one verb regardless of vintage; clean for lifecycle ops | Consistency-side; single-slot removal, partition-local |

### move-active-wait

| Command | v1 (purpose) | v2 status | v3 decision (PROPOSED) | BCS | EchoMesh |
|---|---|---|---|---|---|
| `moveToActive-11` | Worker fetch: wait→active, lock, fetch data; promote due delayed first; rate-limit + pause gates | **PORTED** — `Jobs.claim/4` (`@claim`; `ZPOPMIN pending` → `active` lease-scored on `TIME`, token = `HINCRBY attempts`); grouped `Lanes.claim/3` (`@gclaim`); pause gate `Jobs.paused?/2` | Keep `@claim` (server-clock lease, attempts token); make the **lane-aware claim the mesh-facing default** (a node claims only the lanes it owns); no client-side `LMPOP` (§12.2) | The single-writer claim — work drawn atomically, the lease the only ownership proof | Consistency-first (§4 row 24): one claimant per slot, refuse rather than admit a second writer under partition |
| `moveJobFromActiveToWait-9` | Worker-initiated requeue: return a still-leased active job to wait (lock-token-fenced); priority-aware; emits `waiting` | **PARTIAL** — the *crash-recovery* return is `Jobs.reap/2` (`@reap`) + `Stalled.check/3`; a lock-fenced **voluntary** active→pending with no dead-letter has no dedicated verb | Add a token-fenced `requeue` verb: `attempts`-fenced active→pending (no attempts bump, no morgue), declared `[active, pending, job_key]`; the v1 lock-token fence → the `EMQSTALE` attempts fence; priority → the lane arm | A worker yielding work it cannot finish back to the single-writer queue without consuming an attempt | Consistency-first: the give-back stays on the owning slot; a node shedding load returns work to the same authoritative pending set |
| `moveJobsToWait-8` | Bulk move completed/failed/delayed → wait by score window; strips finish fields; "no priorities" | **PARTIAL** — single-job equivalents exist (`reprocess_job/3` dead→pending, `promote/3` due schedule→pending); a bulk/count-windowed retried-set→pending verb is NOT YET built | Add a bulk `requeue_set(state, count)` over `schedule`/`dead` → `pending`, batched, declared keys; the per-job row cleared via a grammar-derived `job:` key; `completed` is gone (completion-deletes) | Operator bulk-recovery — replay a window of dead/scheduled work onto pending after a fix, in mint order | Consistency-first with an availability lever — bulk replay onto the owning slot; the recovered backlog is the consistent ledger the cache then serves |
| `moveStalledJobsToWait-8` | Periodic stalled sweep: under a check-lock, move stalled active→wait, bump `stc`, dead-letter past `maxStalledJobCount` (unless repeatable), re-mark still-active | **PORTED** — `Stalled.check/3` (`@sweep_stalled`; `ZRANGEBYSCORE active` by `TIME`, `HINCRBY stalled`, recover < max else dead-letter; lane-aware), opt-in `:transient` timer, above `Jobs.reap/2` | Formalize the as-built sweep: the v1 two-scan mark-then-sweep collapses to one server-clock lease scan (the lease deadline IS the staleness signal); `stc`→the row's `stalled` field; repeatable-exemption is a forward additive arm | The crash-recovery safety net — a dead worker's leases return to the queue; repeated stalls dead-letter so a poison job cannot loop the fleet | Consistency-first recovery: the fold-to-state restart (Armstrong) operationalized — a lost lane's in-flight leases recover on a survivor, the lease the only liveness fact |

### move-finish-delay-children

| Command | v1 (purpose) | v2 status | v3 decision (PROPOSED) | BCS | EchoMesh |
|---|---|---|---|---|---|
| `moveToFinished-14` | Move a locked active job → completed/failed; release lock, run parent fan-in, trim/keep, optionally fetch next + promote delayed | **PORTED** — `Jobs.complete/5` (`@complete`, completion-deletes); parent fan-in via `Flows` `@complete` hook; fail arm = `@retry` dead-letter | Keep `complete/5`; finalize-status as the host-read result seam; keep the v1 fetch-next + promote-on-finish **decomposed** into `claim`/`promote` (no monster script) | The terminal write of the Jobs surface — single-writer, fenced, completion-deletes | Consistency-first: refuse-on-stale (`EMQSTALE`); same-slot fan-in atomic, cross-queue release eventually-consistent |
| `moveToDelayed-8` | Move a locked active job → delayed ZSET at a baked score; release lock, bump attempts, set delay, wake marker | **PORTED** (as retry-reschedule) — `Jobs.retry/7` + `@retry` non-terminal arm (`state=scheduled`, `ZADD schedule now+delay` on server `TIME`) | Retain `@retry`'s scheduled arm as the active→scheduled path; if a host-initiated (non-failure) defer is needed, add a thin `defer/…` routing the same `schedule` ZADD — declared-keys, server clock | Backoff-driven retry of a consumer's jobs; visibility-fence reschedule | Consistency-first: the schedule set is single-slot, server-clock-scored; no cross-node timing trust |
| `moveToWaitingChildren-7` | Worker parks its own active job → waiting-children IF deps remain (or a named child) and no failed children; release lock | **PARTIAL** — the *fan-in* (parent held `awaiting_children`, released at zero) is in `Flows`; the worker-initiated *self-park pending a runtime-added child* is not a distinct port | Add an explicit `await_children/…` over `Flows` — host reads dep count / `:unsuccessful` host-side (never a Lua data-rooted key), parks parent on its slot; honest-row `{:awaiting,n}`/`{:ready,0}`/`{:failed_children}` | Dynamic flows where a parent discovers children at runtime (compose multi-leg job DAGs) | Consistency-first within a slot; the parent's await is a same-slot guarded transition, not a cross-region promise |
| `promote-9` | Promote ONE specific delayed job (by id) → wait/prioritized immediately; strip marker, re-enqueue by priority, emit `waiting` | **PARTIAL** — `Jobs.promote/3` (`@promote`) promotes *all due* `schedule` members (batch, server clock), not a targeted single-id force-promote | Add a sibling `promote_now/3` (declared `[schedule, pending]`, id gated at `Keyspace.job_key/2`) that `ZREM`s one id + `ZADD pending 0` on its slot — the targeted form beside the due-sweep | Operator/early-trigger of a scheduled job | Consistency-first: targeted single-slot move; deterministic, no clock-skew dependence |

### retry-reprocess-change

| Command | v1 (purpose) | v2 status | v3 decision (PROPOSED) | BCS | EchoMesh |
|---|---|---|---|---|---|
| `retryJob-11` | Move a failed job from `active` back to `wait`/`prioritized` immediately, releasing its lock; the operator "retry now" verb | **PARTIAL** — split across `Jobs.retry/7` (`@retry`, worker active→scheduled/dead) + `reprocess_job/3` (operator dead→pending); no single "active→pending now, lock-released" operator verb | A declared-keys `requeue_active/4` (`active`→`pending`, lease-retired, lane-aware) — re-derive the v1 effect under braces; **no** data-value lock token | The operator "kick a stuck claim back to the front" control for a consumer's work lane | Consistency-first (CP-side) operator action — manual, audited, single-writer-serialized, not an availability path |
| `reprocessJob-8` | Reprocess a finished/failed job: remove from its state ZSET, drop finish fields, re-add to wait, mend parent-dependency links | **PORTED** — `Jobs.reprocess_job/3` (`@reprocess`); `dead`→`pending`, clears `last_error`, refuses non-dead `EMQSTATE`; emq.2.2 | Extend the shipped `@reprocess` with the A-1-clean flow fan-in re-link (the v1 parent-dependency mend) via declared §6 parent subkeys, once the flow subkeys are the source of truth | The post-fix "re-run a dead job" recovery the operator runbook drives | CP-side recovery verb (deterministic, single-slot, audited) — the consistency-first queue's repair lever |
| `changeDelay-4` | Re-score a job already in the `delayed` set to a new delay; emits `delayed`, re-arms the marker | **NOT YET** — no `change_delay`; the bus has `schedule` + `@schedule`/`enqueue_in/5` + `@promote`, but no in-place re-score of a scheduled member | `reschedule/4` — re-`ZADD` the `schedule` member under a `TIME`-derived run-at (server clock), declared-keys, branded id at the builder | Lets an operator push out / pull in a scheduled end-of-day/repeatable job without drop-and-re-add | CP-side admin write to a scheduled item; staleness here is a *budget knob* (the M4 dial), not an availability path |
| `changePriority-7` | Re-position a job in `wait`/`prioritized` at a new priority score | **NOT YET (capability RETIRED)** — no `change_priority`; the v1 `prioritized` ZSET is **retired by design** (§6; mint-order IS the order theorem, per-group **Lanes** replace priority) | **No priority re-score**; the v3 equivalent is `Lanes` group re-assignment / weighted rotation (emq.4) — re-aim, not re-implement | Per-player fairness (one Lanes group per player, as codemoji uses) replaces per-job priority for the work surface | Lane fairness is the AP-leaning "keep all lanes answering under contention" dial (emq.4) |

### locks

| Command | v1 (purpose) | v2 status | v3 decision (PROPOSED) | BCS | EchoMesh |
|---|---|---|---|---|---|
| `extendLock-2` | Renew one job's lease — `SET …:lock PX` if token matches, drop it from the stalled set | **PORTED** — `Jobs.extend_lock/5` (`@extend_lock`); re-scores the `active` member under server `TIME`, token-fenced `EMQSTALE` | Hold the shipped server-clock, token-fenced, lease-IS-score form; extend with an explicit returned `lease_deadline` so a consumer reasons about its own headroom | Token-fence is the single-writer guarantee for a long handler (Decider step) holding a row mid-work | Best-Effort-Availability corner: a consistency-first lease, correct-always (the CP dial) |
| `extendLocks-1` | Batch-renew many leases — loop over `cmsgpack`-unpacked ids/tokens, `SET …:lock PX` per match; return failed ids | **PORTED** — `Jobs.extend_locks/4` (`@extend_locks`); one `TIME` read, variadic ARGV id/token pairs slot-rooted off `KEYS[1]=active`, returns `failed` (drives the `Locks` beat) | Keep the as-built variadic A-1 form (the 2026-06-14 slot-rooted-ARGV ruling); surface `Locks.extend/1`'s `{extended, dropped}` as the plane's telemetry | One server-clock read amortizes the whole held set — bulk-fence for a worker draining many branded jobs | The single-`TIME` batch keeps every lease on one consistency clock — the availability-corner lease, fleet-wide |
| `releaseLock-1` | Release a lease — `DEL …:lock` if token matches | **PORTED** (re-split) — `Locks.untrack_job/2` DELs the `emq:{q}:job:<id>:lock` *presence marker*; the lease is released by the natural `active`-score expiry / `complete` | Keep the L-3 two-part release (marker DEL on untrack + self-expiring marker `PX` TTL); the lease end stays score-driven; make the marker DEL idempotent + return prior held-state | Releasing the marker unblocks `remove_job` (`EMQLOCK` lifts) — clean hand-back of a completed branded job | Marker self-expiry is the partition-healing escape hatch: a dead holder cannot pin the row past its lease |

### metrics-state

| Command | v1 (purpose) | v2 status | v3 decision (PROPOSED) | BCS | EchoMesh |
|---|---|---|---|---|---|
| `getCounts-1` | Counts per requested state name | **PORTED** — `Metrics.get_counts/3` (`@counts`, closed-registry) | Keep `@counts`; add a one-shot multi-set snapshot + an honest `as_of` server-`TIME` stamp | Per-state depth feeds the operator dashboard | Availability-first: a queue-health read, stale-tolerant, served from the nearest replica |
| `getCountsPerPriority-4` | Counts per priority band over the `prioritized` ZSET | **NOT YET (retired by design)** — no `prioritized` set; priorities are `Lanes` | Re-derive as per-lane depth — `Metrics.lane_depths/3` over `g:<group>:pending`, branded-group-gated | Per-lane backlog is the fair-lane / per-player depth the bus reads | Availability-first: per-segment (per-player lane) depth, observational only |
| `getMetrics-2` | Completed/failed throughput series | **PARTIAL** — `Metrics.get_metrics/3` reads the `count`; the `:data` time-series + Prometheus export are unbuilt (emq.8) | Keep the counter read; build the `metrics:<which>:data` ring honestly behind it; the Prometheus *format* wrapper stays emq.8 | Terminal-outcome throughput for capacity/SLO dashboards | Availability-first: a metered observation surface, never on the order-of-record write path |
| `getState-8` | A job's state across 8 sets | **PORTED** — `Metrics.get_job_state/3` (`@state_lookup`; 4 sets + the row-field branch) | Keep the four-set + `awaiting_children` row-field probe; the closed `@lookup_states` table is the honest-row guard; add owning-slot/`as_of` on a replica read | A runbook reads a job's state before any mutate; the flow-parent `awaiting_children` verdict | Consistency-first: the authoritative state-of-record read for one branded id |
| `getStateV2-8` | The `LPOS`-based state read (newer-Valkey variant) | **PORTED (subsumed)** — folded into `Metrics.get_job_state/3`; the bus has no wait/paused LISTs, all four states are ZSETs (`ZSCORE`) | No separate verb — the ZSET keyspace makes the LIST-vs-ZSET split moot; one `get_job_state/3` | Same as `getState` — one canonical state read | Consistency-first: same single-id state-of-record read; the variant collapses |
| `getDependencyCounts-4` | Counts per child state (processed/unprocessed/ignored/failed) for a flow parent | **PARTIAL (split, not aggregated)** — count is `Flows.dependencies/3`; per-state reads are `children_values/3` + `ignored_failures/3`; no single aggregate verb | A `Flows.child_counts/3` composing the declared `:dependencies` counter + `:processed`/`:failed` subkeys on the parent slot — NOT a SET-cardinality lift | The fan-in progress a multi-leg/saga parent reads before proceeding | Consistency-first: a flow parent's child-state read is on the strong-consistency (state-of-record) axis |

### introspect-read

| Command | v1 (purpose) | v2 status | v3 decision (PROPOSED) | BCS | EchoMesh |
|---|---|---|---|---|---|
| `getRanges-1` | Job-ids per requested states over a window (`LRANGE`/`ZRANGE`); v6-marker-aware | **NOT YET** — no `get_ranges`; the v1 state structures do not exist (§6 retires wait/paused/completed/failed/prioritized) | Re-aim to a per-state windowed browse over the four as-built sets: `pending` via REV BYLEX (`Jobs.browse/3`) + `ZRANGE`/`ZREVRANGE` over active/schedule/dead; declared KEYS[]; forward: an `XRANGE` mint-instant window (emq3.6) | Read a queue's backlog/morgue by state for the operator runbook with no second index (the order theorem) | Consistency-first (CP) read of the bus state — which set holds an id; on the state-of-record side |
| `getRateLimitTtl-2` | Remaining limiter TTL in ms (`PTTL`; `max` from meta when `maxJobs`=0) | **PORTED** — `Metrics.get_rate_limit_ttl/3` (`@rate_ttl`); declared `[limiter, meta]` | Hold as-shipped; forward: extend to the per-group/per-player limiter window (the `EMQRATE`-class per-group window) for EchoMesh's per-lane temporal-fairness knob | Read how long until the rate window reopens — a throttle a consumer consults before scaling out producers | Consistency-first read against the regulated window; the rate fence is exact, never best-effort |
| `isMaxed-2` | Is the queue at its concurrency ceiling → boolean | **PORTED** — `Metrics.is_maxed/2` (`@is_maxed`); a read-and-refuse returning `:ok`/`{:error,:rate}` (`EMQRATE`) over `ZCARD active` | Hold as-shipped (v2 already evolves the v1 boolean into a typed `EMQRATE` wire refusal, the additive minor); forward: carry the consult-before-claim contract to per-lane ceilings (`Lanes`) | The scale-out gate: a producer/strategy consults the ceiling before claiming, so the system never over-admits | Consistency-first admission gate — the ceiling is a hard refuse (the CP "refuse rather than risk a second writer" posture) |
| `isFinished-3` | Is a job finished (in `completed`→1 / `failed`→2 ZSET); `-1` missing; optional result from the hash | **PARTIAL** — no `is_finished`; subsumed by `Metrics.get_job_state/3`; the gap: there is no `completed` set (completion-deletes), only `dead` is retained | A thin `finished?/3` over `get_job_state/3` — `:dead` is the only retained terminal state; "completed" is observed via `metrics:completed`; forward: durable finished-history via stream replay (emq3.3/3.5) | "Did this trade-job terminate?" — `dead` (the morgue) is the retained answer; live outcome rides the metrics counter | Consistency-first point read of regulated state; the durable finished-history that emq3.5 archives serves the availability-first retention surface for audit/backtest |
| `isJobInList-1` | Is an id a member of a LIST (`LRANGE`+linear scan) → 1/nil | **NOT YET** — no `in_list`; the bus has no membership LISTs (claiming is `ZPOPMIN`, not a list scan) | Re-aim to O(log n) set membership: a declared-key `ZSCORE` over the relevant sorted set (the `@state_lookup` mechanism), never a linear `LRANGE`; forward: stream-position membership by entry-id | Confirm an order/job's set residency cheaply — "is this id still pending/active" without pulling the whole set | Consistency-first membership probe on the regulated bus; exact, partition-refusing on the CP side |
| `paginate-1` | Stable-cursor page of a set or hash (`SSCAN`/`HSCAN`, optional job fetch) | **NOT YET** — no `paginate`; the listing path is `Jobs.browse/3` REV-BYLEX + `pending_size/3` ZCARD (sorted-set windowing, not SSCAN/HSCAN) | The primary listing is the order-theorem browse (REV BYLEX, stable because mint-ordered — v1's findPage warns SSCAN is unstable); set/hash reads via a declared-key `HSCAN`; forward: the canonical paged read is `XRANGE`/`XAUTOCLAIM` over the stream tier (entry-id IS the cursor, emq3.1/3.6, retention-bounded emq3.4) | Page a large backlog/event log for recorded-runs + backtest replay (the named emq3 consumers) | Availability-first (AP) read — paged reads resolve from the nearest replica, staleness-bounded; the stream-tier retention is globally replicated |

### data-progress-log

| Command | v1 (purpose) | v2 status | v3 decision (PROPOSED) | BCS | EchoMesh |
|---|---|---|---|---|---|
| `updateData-1` | Replace a job's `data` hash field | **PORTED** — `Jobs.update_data/4` (`@update_data`) | Keep the one-declared-key `@update_data`; `data`→`payload`; gate id at `Keyspace.job_key/2`; immutability stance for stream-tier records (emq3.2: append, don't replace) | Re-arms a job's payload before claim (a job re-targets before it is drawn) | Consistency-first: a single-slot HSET on the owning node, refuses (`:gone`) on a missing row — no cross-region write |
| `updateProgress-3` | Write `progress` + XADD a `progress` event to the queue stream | **PORTED** — `Jobs.update_progress/4` (`@update_progress`); the v2 form is a `PUBLISH emq:{q}:events`, not an `XADD` (D-5/D-6) | Keep the field-write + the registered `PUBLISH` progress event; promote to a retained stream record at emq3.2 (forward) | A long-running job's heartbeat the operator dashboard watches | Availability-first observability edge: a subscriber-less `PUBLISH` is a no-op; the watch plane degrades, never blocks the write |
| `addLog-2` | Append a line to a job's `:logs` list, keep-N trim | **PORTED** — `Jobs.add_log/5` + `get_job_logs/3` (`@add_log`); both keys co-located by the braced root | Keep two-declared-keys (row + `:logs` subkey), keep-N `LTRIM`, honest count; forward: retention-as-policy for trimmed-away lines (emq3.5 archive) | Per-job audit trail for a worker's diagnostics | Consistency-first but bounded: the `:logs` list co-locates by hashtag; retained-but-trimmed, a staleness-budget candidate for the archive |
| `saveStacktrace-1` | HMSET `stacktrace` + `failedReason` onto the job hash | **NOT YET (folded)** — no `save_stacktrace`; the failure record is the single `last_error` field set by `@retry`'s dead-letter arm, cleared by `reprocess_job/3` | A dedicated `@save_stacktrace` re-derivation under declared-keys — separate `stacktrace`/`failed_reason` fields beside `last_error`, written on the dead-letter transition, server-clock-stamped; companion to emq.3.4 `fail_parent_on_failure` | Rich post-mortem on a dead job before reprocess | Consistency-first morgue: failure detail is single-writer on the owning node's row, read by recovery sweeps; never a partition-spanning write |

### remove-clean

| Command | v1 (purpose) | v2 status | v3 decision (PROPOSED) | BCS | EchoMesh |
|---|---|---|---|---|---|
| `removeJob-2` | Remove one job from every state + all its data; refuse if active/locked; optionally recurse into children; skip scheduler jobs | **PORTED** — `Jobs.remove_job/4` (`@remove_job`), emq.2.2 | Keep the single-job `@remove_job`; add a declared-keys **recursive** variant that walks the `Flows` declared subkeys (`:dependencies`/`:processed`), never the v1 data-value `parent_key`; FLAT first (grandchildren → emq.3.5) | The removal verb behind an operator runbook / a consumer's job cleanup over branded ids | Operator-plane write on the consistency-first side — a destructive act gated `EMQLOCK`, single-slot atomic |
| `removeChildDependency-1` | Break one parent↔child link: `SREM` the child key from the parent dependency SET, `HDEL parent` from the child; move parent to wait if last child | **NOT YET** as a named verb — closest is the automatic fan-in `DECR` in `@flow_deliver`, not an explicit detach | A new `Flows.drop_dependency/3` — `DECR` the parent's declared `:dependencies` counter + record the child in `:processed` (HSETNX), at-zero release the parent to `pending`; declared parent subkeys only, no `parent_key` value-read | Lets a multi-leg flow cancel one leg without failing the parent | Consistency-first, single-slot for a same-queue parent; a cross-queue detach rides the eventually-consistent `flow:outbox` + sweep |
| `removeDeduplicationKey-1` | Release a dedup key iff it still points at this job: `GET`, compare to ARGV jobId, `DEL` on match | **PARTIAL / folded** — the GET-compare-DEL is inlined into `@remove_job`'s `de:` branch; `Metrics.get_deduplication_job_id/3` reads it; no standalone release verb | Surface a standalone `Jobs.release_dedup/3` reusing the `@remove_job` `de:` branch verbatim — declared `KEYS[1] = emq:{q}:de:<did>` (the one v1 op that was almost legal), value-compare against the branded id receipt | The idempotency-key release behind a producer that retired a dedup window early | Consistency-first local key op; the dedup key is a single-slot per-queue structure under braces |
| `removeUnprocessedChildren-2` | Recursively remove a job's children, ignoring processed & locked | **NOT YET** — no recursive child-removal verb; `Flows` ships fan-in + failure-policy, not a recursive teardown | A bounded `Flows.remove_children/3` walking the parent's declared `:dependencies`/`:processed`/`:failed`/`:unsuccessful` subkeys (the A-1-clean graph), per-slot same-queue, `flow:outbox`-hopped cross-queue; FLAT first (grandchildren = the deferred emq.3.5 V-1 fork) | Tears down a cancelled fan-out's child legs without touching the parent's own state | Consistency-first for same-queue children; cross-queue teardown is availability-leaning (eventually-consistent, idempotent) |
| `cleanJobsInSet-3` | Bulk-remove jobs from one set older than a timestamp, up to a limit, skipping locked + scheduler jobs; emit a `cleaned` event | **PARTIAL** — `Admin.drain/3` (`@drain`) wipes `pending` (+ optional `schedule`); predicate-free (no age grace, no limit, no per-set dispatch, no scheduler-skip); `obliterate/3` wipes a paused queue whole | A `Admin.clean/4` over the four v2 sets with a server-clock `TIME` age grace + a limit + honest-count return; per-set dispatch folds away (no v1 prioritized/completed/failed sets under completion-deletes) | The operator's age-based queue hygiene for a consumer's work lanes during an incident | Availability-first maintenance: a bounded, honest-count sweep that degrades a backlog rather than blocking the live path; per-queue single-slot |

### destructive-lifecycle

| Command | v1 (purpose) | v2 status | v3 decision (PROPOSED) | BCS | EchoMesh |
|---|---|---|---|---|---|
| `drain-5` | Empty `wait`+`paused`(+`delayed`)+`prioritized`, skipping job-scheduler-owned delayed jobs; leaves active/completed/failed | **PORTED** — `Admin.drain/3` (`@drain`), emq.2.2 | Keep the shipped `@drain` (one slot, `KEYS[1]`=base root, `KEYS[2]`=pending, optional `KEYS[3]`=schedule); the v1 scheduler-skip re-derives as the repeat REGISTRY surviving (D-4), no per-job backref to read | Clears a queue's pending backlog during an incident without killing in-flight active jobs | A control-plane (consistency-first) act on a queue surface — a single-slot atomic op, no availability claim |
| `obliterate-2` | Destroy a *paused* queue iteratively: refuse if not paused / has active jobs (unless force), delete every set + job key + ~13 auxiliary keys, bounded by `count` | **PORTED** — `Admin.obliterate/3` (`@obliterate`), emq.2.2 | Keep the bounded `:more`/`:ok` form; `EMQSTATE not paused` / `active jobs present` refusals; every job key derived from `KEYS[2]` base; the v1 set-list collapses to the four braced sets + lane structures + `repeat`/`metrics:*`/`meta` | A control plane tears down ephemeral/test queues down to their keyspace footprint, leaving no trace | The consistency-first edge of the dial — a destroy is correct-always, never optimistic; bounded budget keeps each call a sound single-slot transaction |
| `pause-7` | Pause/resume the queue globally: RENAME `wait`↔`paused`, set/clear `meta.paused`, manage the delay marker, XADD a `paused`/`resumed` event | **PORTED** — `Admin.pause/2` + `resume/2` (`@pause`/`@resume`), emq.2.2 | Keep the shipped FORM b — a `paused` FIELD on `emq:{q}:meta`; the claim paths read it first and answer `:empty`; no `wait`↔`paused` RENAME (one `pending` set), `@claim`/`@gclaim` byte-frozen; the event PUBLISH rides the emq.2.3 watch plane | An operator quiesces a runaway lane's claiming during an incident without moving the backlog | A control-plane (consistency-first) gate; pausing claim trades availability (workers get `:empty`) for operational control — segmentation by operation |

## Side-by-side v1 → v3

The per-family detail. Each `## Family` block carries its per-command side-by-side: the v1 mechanism (and the specific data-value key root that bars a lift), the v2 as-built status, and the PROPOSED v3 form. Voice: as-shipped present tense for v2 as-built; forward / PROPOSED for every v3 claim.

## Family: add-core

The three v1 admission scripts (`addStandardJob-9`, `addDelayedJob-6`, `addPrioritizedJob-9`) are BullMQ's three enqueue entry points: immediate, delayed, and priority-ordered. All three share the same `ARGV[1]` msgpacked args array (prefix, custom id, name, timestamp, `parentKey`, parent-deps key, parent `{id,queueKey}`, repeat-job key, dedup key) and the same `storeJob`/`getOrSetMaxEvents`/`deduplicateJob`/`handleDuplicatedJob` includes; they differ only in the destination structure (wait/paused LIST · `delayed` ZSET · `prioritized` ZSET). The structural fault that forbids a lift is identical across all three: **the parent existence guard reads `parentKey` from `args[5]` (a data value carried in `ARGV`, then `EXISTS`-checked and used as an operand) and writes `parentDependenciesKey` from `args[6]` — neither is a `KEYS[]` entry**, so the cross-entity write is rooted in a data value, which the v2 declared-keys law (A-1) makes illegal. The job id is likewise an unbranded `INCR` counter (`KEYS[4]`/`KEYS[3]`), and the destination key is the implicit, data-derived `args[1] .. jobId`.

### addStandardJob-9

**v1 purpose + mechanism.** Immediate enqueue. Takes `KEYS[1..9]` = wait, paused, meta, id, completed, delayed, active, events-stream, marker; `ARGV[1]` = msgpacked args, `ARGV[2]` = JSON data, `ARGV[3]` = msgpacked opts. It `INCR`s `KEYS[4]` (or uses a custom id from `args[2]`, routing duplicates through `handleDuplicatedJob`), runs `deduplicateJob`, `storeJob` (`HMSET` the row + `XADD added`), then `getTargetQueueList` picks wait-vs-paused and `addJobInTargetList` `LPUSH`/`RPUSH`es the id onto that LIST and sets the marker, then `XADD waiting`. **Data-value key roots (v3-illegal):** `parentKey = args[5]` is read from `ARGV`, `EXISTS`-checked, and used as an operand; `parentDependenciesKey = args[6]` is the target of `SADD parentDependenciesKey jobIdKey` — both keys arrive in a data array, not `KEYS[]`. The destination job key `args[1] .. jobId` is also data-derived.

**v2 status — PORTED.** `EchoMQ.Jobs.enqueue/4` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`), the inline `@enqueue` `Script.new(:enqueue, …)`: `keys = [Keyspace.job_key(queue, job_id), Keyspace.queue_key(queue, "pending")]` — both declared; `Keyspace.job_key/2` gates `BrandedId.valid?` and the script's first act is the `JOB`-namespace `EMQKIND` refusal; idempotency is `EXISTS KEYS[1]` (→ `:duplicate`); the row is `HSET state/attempts/payload`; the pending entry is `ZADD KEYS[2] 0 ARGV[1]` (score-0, so member byte order is mint order). Features catalog row 304 binds the v1 `queue.ex` adds to this.

**v3 PROPOSED.** The as-built `@enqueue` already IS the state-of-the-art re-derivation (branded key builder, declared 2-key form, score-0 mint-ordered ZSET replacing the wait/prioritized LIST, idempotent admission, honest-row). v3 re-introduces what BCS + EchoMesh need beyond it: the parent/flow dependents edge returns as a **declared** `KEYS[]` dependents-set with a branded parent-job key (the design §10 flow seam, the v1 `args[5]`/`args[6]` data-rooted operands re-expressed lawfully). PROPOSED, not asserted-shipped.

**BCS / EchoMesh.** BCS: the order theorem (no second index) is the deterministic admission a consumer's hot path stands on (for codemoji, the per-player guess stream). EchoMesh: availability-first/segmented — idempotent at-least-once admission tolerates a partition, the 14-byte branded id is the same addressable entity across the bus, cache, stream, and store (`docs/echo/mesh/markdown/index.md`).

```text
v1 addStandardJob-9                              v3 enqueue (PROPOSED, as-built @enqueue + flow edge)
─────────────────────────────────               ──────────────────────────────────────────────────
KEYS: wait,paused,meta,id,completed,             KEYS: [job_key(q,brandedId),                # declared, branded-gated
      delayed,active,events,marker                      queue_key(q,"pending"),              # declared
jobId = INCR(KEYS[4])     -- int counter                (+ declared dependents-set for flow)] # PROPOSED, branded parent
parentKey = args[5]       -- DATA VALUE          ARGV: [brandedJobId, payload]
  EXISTS parentKey ; SADD args[6] jobIdKey       if sub(ARGV[1],1,3) ~= 'JOB' -> EMQKIND     -- kind law, first act
storeJob: HMSET row ; XADD added                 if EXISTS KEYS[1] -> return 0 (:duplicate)  -- idempotent
getTargetQueueList -> LPUSH/RPUSH wait|paused    HSET KEYS[1] state=pending attempts=0 payload
XADD waiting                                     ZADD KEYS[2] 0 ARGV[1]                      -- score-0 = mint order
```

### addDelayedJob-6

**v1 purpose + mechanism.** Delayed enqueue. `KEYS[1..6]` = marker, meta, id, delayed, completed, events; same `ARGV` triad. After the identical `INCR`/custom-id/`deduplicateJob`/`storeJob` preamble, it calls `addDelayedJob`, where `getDelayedScore` composes the score as `(timestamp + delay) * 0x1000` with a 12-bit slot carved for an intra-timestamp tiebreak (a `ZREVRANGEBYSCORE` probe finds the next free slot), then `ZADD delayed score jobId`, `XADD delayed`, and a delay-marker. **Data-value key roots (v3-illegal):** identical to addStandardJob — `parentKey = args[5]` and `parentDependenciesKey = args[6]` are read from the data array, and the delay itself comes from `opts['delay']` (a data field), with the *client* timestamp (`args[4]`) as the time base.

**v2 status — PORTED.** `EchoMQ.Jobs.enqueue_at/5` and `enqueue_in/5` (inline `@schedule`): declared `keys = [Keyspace.job_key(queue, job_id), Keyspace.queue_key(queue, "schedule")]`; `state=scheduled` row + `ZADD KEYS[2] score ARGV[1]`. For `enqueue_in` the score is computed **inside the script from server `TIME`** (`now = t[1]*1000 + floor(t[2]/1000); score = now + delay`); for `enqueue_at` the score is the caller's absolute run-at ms. Features catalog row 327 binds `addDelayedJob-6.lua` → the `@schedule` run-at-scored set.

**v3 PROPOSED.** The as-built `@schedule` is the re-derivation: a **visibility fence on the `schedule` set, not a second queue** (design §6 — `schedule` is a registry type) — the mint-ordered branded id stays the sort key once promoted, so a job minted earlier but scheduled later still sorts by mint after release; the promote pump (`Jobs.promote/3`, driven by `EchoMQ.Pump`) releases due members to `pending`. 
The v1 12-bit-slot score-packing tiebreak is gone — order falls out of the branded mint, not a bit-stuffed score. 
The server clock (`TIME`) replaces the client timestamp wherever the delay is priced (the lease/clock law). PROPOSED for v3: a handler-driven dynamic-delay re-score of an active job onto the same `schedule` set (features §forward, emq.4 candidate).

**BCS / EchoMesh.** BCS: scheduled and retry jobs share one `schedule` set and one timing source across a consuming app. EchoMesh: the trade-staleness-for-availability dial made physical — a server-clock visibility fence means delay is sound from a laptop to a Fly fleet, never the caller's clock.

```text
v1 addDelayedJob-6                               v3 enqueue_in/_at (PROPOSED, as-built @schedule)
──────────────────────────────                  ─────────────────────────────────────────────────
KEYS: marker,meta,id,delayed,completed,events    KEYS: [job_key(q,brandedId), queue_key(q,"schedule")]
delay = opts['delay']       -- DATA field        ARGV: [brandedJobId, payload, 'in'|'at', value]
ts    = args[4]             -- CLIENT clock       if sub(ARGV[1],1,3) ~= 'JOB' -> EMQKIND
getDelayedScore: (ts+delay)*0x1000 + 12-bit slot  if EXISTS KEYS[1] -> return 0 (:duplicate)
  (ZREVRANGEBYSCORE probe for free slot)          if ARGV[3]=='in':  t=TIME; now=t[1]*1000+floor(t[2]/1000)
ZADD delayed score jobId                                             score = now + value   -- SERVER clock
XADD delayed ; delay-marker                       else:              score = value         -- absolute run-at
parentKey/deps = args[5]/args[6]  -- DATA VALUES  HSET KEYS[1] state=scheduled attempts=0 payload
                                                  ZADD KEYS[2] score ARGV[1]   -- visibility fence; mint stays sort key
```

### addPrioritizedJob-9

**v1 purpose + mechanism.** Priority enqueue. `KEYS[1..9]` = marker, meta, id, prioritized, delayed, completed, active, events, `pc` (priority counter); same `ARGV` triad. After the shared preamble it calls `addJobWithPriority`, where `getPriorityScore` builds a packed score `priority * 0x100000000 + INCR(priorityCounterKey) % 0x100000000` (a global numeric priority in the high 32 bits, a monotone counter in the low 32 for FIFO-within-priority), then `ZADD prioritized score jobId`, `isQueuePausedOrMaxed`, marker, `XADD waiting`. **Data-value key roots (v3-illegal):** identical `parentKey = args[5]`/`parentDependenciesKey = args[6]` data-array operands; priority comes from `opts['priority']` (a data field), and the dedicated **global** `prioritized` ZSET + `pc` counter are the structures v2 retires.

**v2 status — PORTED (folded / re-aimed).** There is **no `addPrioritizedJob` port and no numeric-priority script** in `echo_mq` — confirmed: the only `priorit` hits in `lib/` are `admin.ex`/`metrics.ex` comments noting the bus has no `prioritized` set. Priority is re-aimed to **per-group fairness**: `EchoMQ.Lanes.enqueue/5` (inline `@genqueue`, `lib/echo_mq/lanes.ex`) admits onto a per-group lane ZSET and maintains a rotating ring (the rota); `Lanes.claim/3` rotates one step and serves the head — fairness is *constructed*, not a hashed/numeric score (D-9). Features catalog **row 328** records the disposition verbatim: "*— folded: the v2 `pending` set is score-0 … priority lanes are `EchoMQ.Lanes` (per-group). No separate prioritized set (design §6 — the v1 `prioritized` type retires).*" Design §6: "the v1-shaped lifecycle types retire."

**v3 PROPOSED.** v3 keeps fair lanes as the priority model — the rotating ring replaces the global priority number, giving per-identity fairness over one shared machine. **Intra-group priority** is the forward addition (emq.4): per the features forward section it is "*a non-zero lane score on the existing `g:<group>:pending` ZSET — no new key family*" — i.e. priority becomes a lane-local score (and a per-group ceiling / pause-resume), declared-keys-clean, never a new global `prioritized` key or a `pc` counter. The v1 packed-score-plus-secondary-counter scheme does not return. PROPOSED, not asserted-shipped.

**BCS / EchoMesh.** BCS: fair lanes give a consuming app (codemoji's per-player lanes) many-tenants-on-one-queue isolation (no noisy-neighbour starvation) that a single global priority integer cannot. EchoMesh: the consistency-first/coordinated end of the dial — bounded, fair, per-identity service is a server-side invariant computed on the bus, not a client-supplied hint that a partition could distort.

```text
v1 addPrioritizedJob-9                           v3 Lanes.enqueue (PROPOSED — as-built @genqueue;
─────────────────────────────                         intra-group priority = lane score, emq.4)
KEYS: marker,meta,id,prioritized,delayed,        KEYS: [job_key(q,brandedId), lane(q,group)="…g:<g>:pending",
      completed,active,events,pc                        ring, paused, glimit, gactive, wake]   -- all declared
priority = opts['priority']    -- DATA field     ARGV: [brandedJobId, payload, group]
getPriorityScore:                                if sub(ARGV[1],1,3) ~= 'JOB' -> EMQKIND
  priority*2^32 + INCR(pc)%2^32  -- global + ctr  if EXISTS KEYS[1] -> return 0 (:duplicate)
ZADD prioritized score jobId   -- 1 global ZSET  HSET KEYS[1] state=pending attempts=0 payload group=ARGV[3]
isQueuePausedOrMaxed ; marker ; XADD waiting     ZADD KEYS[2] 0 ARGV[1]   -- score-0 lane; PROPOSED: non-zero = intra-group prio
parentKey/deps = args[5]/args[6] -- DATA VALUES  ring bookkeeping: add lane if serviceable, LPUSH wake  -- fairness constructed
                                                 -- claim rotates the ring one step (D-9), not a numeric sort
```

## Family: add-parent-repeat

### addParentJob-6

**v1 purpose + mechanism.** Adds a **parent** job for a parent/child flow. `KEYS` = `meta`, `id`, `delayed`, `waiting-children`, `completed`, events-stream; the flow shape arrives msgpacked in `ARGV[1]` (prefix, custom id, name, timestamp, **`parentKey`**, **parent dependencies key**, `parent {id, queueKey}`, repeat-job key, dedup key). It `INCR`s the counter (or uses a custom id, dedup-guarded via `handleDuplicatedJob`), `storeJob`s the row, `ZADD`s the job into `waiting-children`, `XADD`s a `waiting-children` event, and — if a parent dependencies key is present — `SADD`s the new job key into the parent's dependency SET. **The v3-illegal form:** the parent linkage operands `parentKey` and `parentDependenciesKey` arrive as **ARGV data values** (and `storeJob` writes `parentKey` as a row field; `handleDuplicatedJob` does `HGET jobKey "parentKey"` then `EXISTS` on that read-back key) — a key whose identity is rooted in a data value, structurally illegal under the declared-keys law (S-6).

**v2 status — PORTED.** The single-queue + cross-queue flow capability is the as-built **`EchoMQ.Flows`** module (`echo/apps/echo_mq/lib/echo_mq/flows.ex`): `add/3` (parent + flat child list), `add_bulk/3` (the v1 `flow_producer add_bulk` parity), the child-result reads `children_values/3` (v1 `get_children_values`) and `dependencies/3` (v1 `get_dependencies_count`), and the failure read `ignored_failures/3` (v1 `get_ignored_children_failures`). The inline scripts are `@enqueue_flow` (one atomic same-queue land), `@hold_parent` + `@enqueue_flow_child` (the cross-queue, parent-first, non-atomic land). The fan-in release lives in `EchoMQ.Jobs.@complete`; the cross-queue completion-signal hop in `EchoMQ.Pump.@flow_deliver`. **The v1 data-rooted `parentKey` is NOT lifted:** the parent linkage is a `parent` (and `parent_queue`/`parent_policy`) **DATA field** on each child row, read **host-side** to rebuild the parent's *declared* `:dependencies`/`:processed` keys (`Keyspace.job_key(queue, parent_id) <> ":dependencies"`), so no Lua key is ever read out of a hash field (S-6/INV2). This resolves the design canon's §11.10 deferral ("an A-1-compatible flow design is real design work for the family rungs") — shipped across emq.3.1–emq.3.4.

**v3 reimplementation (PROPOSED).** The state-of-the-art form **keeps the as-built shape** (it is already braced, branded-gated, declared-keys, honest-row) and **forward-extends one gap** the BCS+EchoMesh manuscripts imply. Every id is gated at `Keyspace.job_key/2` (raises pre-wire, INV4); the parent is held `state = awaiting_children` with `:dependencies` = N; same-queue flows land in one atomic `@enqueue_flow` (one slot — either all or none), cross-queue flows land parent-first and fail-closed (a partial add leaves the parent held, never spuriously executed). The PROPOSED forward delta: a **child-roster subkey** (the deferred Fork **R2.B**, the v1 `get_dependencies/1` "which children remain" answer that v2 dropped in favour of the bare counter) — a declared `<> ":roster"` set composed exactly like `:dependencies`, so the mesh's introspection can answer *which* legs are outstanding (not just how many) without ever rooting a key in data. The cross-queue fan-in stays the eventually-consistent outbox→pump hop — the manuscript's per-subsystem availability choice (`docs/echo/mesh/markdown/index.md` §"Segmenting"). **PROPOSED — not asserted as shipped.**

**BCS relevance.** The flow is the BCS composite work unit: a parent job whose children are independent legs, fanned in by the 14-byte branded id — the same addressable entity across the cache, the stream, and the worker (the mesh principle cited at the head of this matrix).

**EchoMesh relevance.** Segmented by construction: a same-queue flow is **consistency-first** (one `{q}` slot, atomic fan-in); a cross-queue flow is **availability-first** (eventually-consistent cross-slot outbox fan-in, INV5/INV7) — the same command sitting on either side of the CAP dial by flow shape, per the heart-of-the-course segmentation thesis.

```text
v1 addParentJob-6                          v3 (PROPOSED) EchoMQ.Flows.add/3
-----------------                          -------------------------------
6 KEYS (meta,id,delayed,                    every id gated at Keyspace.job_key/2
  waiting-children,completed,events)          (BrandedId.valid?, EMQKIND) BEFORE wire
parentKey = args[5]  (DATA VALUE)           parent linkage = `parent` DATA FIELD on
parentDependenciesKey = args[6] (DATA VAL)    each child row; parent's :dependencies
EXISTS parentKey  (key from data!)            REBUILT HOST-SIDE into a DECLARED key
INCR id  →  storeJob (HMSET parentKey field)  same-queue: ONE atomic @enqueue_flow (1 slot)
ZADD waiting-children ts jobId              cross-queue: @hold_parent FIRST (fail-closed)
SADD parentDependenciesKey jobIdKey           then @enqueue_flow_child per slot
                                            fan-in: EchoMQ.Jobs.@complete (same-q) /
                                              Pump.@flow_deliver (cross-q, eventual)
                                            + PROPOSED <> ":roster" subkey (Fork R2.B)
```

### addRepeatableJob-2

**v1 purpose + mechanism.** Registers (or overrides) a **repeatable** job. `KEYS` = `repeat` zset, `delayed` zset; `ARGV` = next-millis, msgpacked opts (`name`, `tz?`, `pattern?`, `endDate?`, `every?`), a legacy custom key, the custom key, and the prefix. It `ZADD`s `nextMillis → customKey` into `repeat` and `HMSET`s the opts under `repeatKey .. ":" .. customKey`. On an **override** it reads `ZSCORE repeat customKey` and, if a prior schedule exists, **rebuilds the stale delayed-job id from data** — `delayedJobId = "repeat:" .. customKey .. ":" .. prevMillis` — then `removeJob`s it and `ZREM`s it from `delayed`. **The v3-illegal form:** the delayed job's identity is a **string built from data values** (`customKey` + the prior score read back from the zset), and `removeJob(delayedJobId, …, prefixKey, …)` then composes `prefixKey .. jobId` to reach a key — operands rooted in data, not in `KEYS[]` (S-6).

**v2 status — PORTED.** The repeat capability is the as-built **`EchoMQ.Repeat`** module (`echo/apps/echo_mq/lib/echo_mq/repeat.ex`): `register/6`, `cancel/3`, `due/3`, `advance/4`, `count/2` over two declared, `{q}`-hashtagged keys — `emq:{q}:repeat` (a zset scored by next-run millis, members = registration **names**) and `emq:{q}:repeat:<name>` (a hash carrying `every_ms` + payload `template`). The inline scripts `@register`/`@cancel`/`@advance` take both keys in `KEYS[1..2]` (declared); the **cadence is host-side** (`EchoMQ.Pump` reads due registrations, mints, enqueues, advances). **The override-delete-stale-delayed of v1 is not lifted** — v2 doesn't carry a per-occurrence "delayed twin" row whose id is data-rebuilt; each occurrence mints a **fresh branded `JOB` id** at sweep time, so there is no stale row to reverse-engineer-and-remove (re-registering a live name is idempotent — `@register` answers `:exists` and changes nothing).

**v3 reimplementation (PROPOSED).** Keep the as-built registry and the **fresh-mint-per-occurrence** law (a daily report registers once; each run is a first-class, mint-ordered, browsable job — id reuse would break the order theorem and dedup). Two ids gated at the key builder; the period and template are the record, the name is the registry member. The PROPOSED forward delta: the as-built record is **`every_ms`-only**, dropping the v1 cron-expressiveness (`pattern`, `tz`, `endDate`); v3 carries those back as additional hash fields and computes the next score **host-side** (the next cron tick under `tz`, capped at `endDate`), feeding `@advance`'s `ARGV` a server-clock-derived `next_at` — never a Lua key rooted in a data value (S-6). The single owning node's pump remains the single writer for a queue's `{q}` repeat slot (slot-soundness). **PROPOSED — not asserted as shipped.**

**BCS relevance.** A periodic sweep registers once and produces a first-class branded `JOB` per occurrence — the same addressable, browsable, mint-ordered unit every other BCS surface references by id.

**EchoMesh relevance.** **Consistency-first:** one queue owns its `{q}` repeat slot, and the owning node's pump is the single writer that mints and advances it — under a partition, lost slots reduce cadence (a missed tick), never double-fire, exactly the "refuses rather than risk a second writer" placement the architect manuscript names.

```text
v1 addRepeatableJob-2                       v3 (PROPOSED) EchoMQ.Repeat
---------------------                       ---------------------------
2 KEYS (repeat zset, delayed zset)          2 DECLARED keys per verb:
ARGV opts: name,tz,pattern,endDate,every      KEYS[1]=emq:{q}:repeat (zset, names)
ZADD repeat nextMillis customKey              KEYS[2]=emq:{q}:repeat:<name> (hash)
HMSET repeat:customKey  opts...             @register idempotent (EXISTS→:exists)
-- override path (DATA-ROOTED): --          NO delayed-twin to reverse-engineer:
  prevMillis = ZSCORE repeat customKey        each occurrence MINTS A FRESH JOB id
  delayedJobId="repeat:"..customKey..         host-side cadence (EchoMQ.Pump):
    ":"..prevMillis   (id FROM DATA)            due/3 → mint+enqueue → advance/4
  removeJob(delayedJobId,prefixKey,…)        next_at = server clock (now_ms()+every)
  ZREM delayed delayedJobId                  + PROPOSED: pattern/tz/endDate fields,
                                               next score computed HOST-SIDE
```

## Family: scheduler

The v1 job-scheduler family is BullMQ's "job factory": a `repeat` sorted set scores each registration (`jobSchedulerId`) by its next-run millisecond, a `<repeat>:<id>` hash holds the template (`name`/`data`/`opts`/`every`/`pattern`/`tz`/`offset`/`ic`), and each occurrence is materialized as a synthetic, name-rooted delayed job whose id is the **string** `repeat:<id>:<millis>`. The structural fault that bars every lift: v1 derives the per-occurrence job key from a **data value** — the millis read back via `ZSCORE` and a synthetic id string spliced from it (`prefixKey .. "repeat:" .. id .. ":" .. millis`), with `isJobSchedulerJob` re-deriving that same id from a hash field (`HGET jobKey "rjk"`). Under the v2 declared-keys law (A-1) a key must be in `KEYS[]` or grammar-rooted from a declared `KEYS[n]`; a key spliced from a ZSCORE-returned value is structurally illegal, so every v3 form is a re-derivation around the v2 `emq:{q}:repeat` registry, not a port of the synthetic-id mechanism.

The v2 as-built `EchoMQ.Repeat` already ports the whole family to the v2 laws (`emq.features.md` §316 maps v1 `job_scheduler.ex` `upsert/get/list/count/remove/remove_by_key/calculate_next_millis` → `repeat.ex` `register/cancel/due/advance/count`): two `{q}`-hashtagged declared keys (`emq:{q}:repeat` zset scored by next-run ms, members are registration **names**; `emq:{q}:repeat:<name>` hash carrying `every_ms`+`template`), with the cadence driven host-side by `EchoMQ.Pump` and a **fresh branded `JOB` id minted per occurrence** — never the reused `repeat:<id>:<millis>` row, because id reuse would break both the order theorem and dedup. v3 carries that surface forward and extends it for what BCS + EchoMesh need.

### addJobScheduler-11

**v1 purpose + mechanism.** Upserts a job scheduler and materializes its next occurrence as a delayed job. KEYS[1..11] = `repeat`, `delayed`, `wait`, `paused`, `meta`, `prioritized`, `marker`, `id`, `events`, `pc` (priority counter), `active`; ARGV = next-millis, msgpacked scheduler opts (`name`/`tz`/`pattern`/`endDate`/`every`), `jobSchedulerId`, template data, template opts, delayed opts, timestamp, prefix key, producer key. It reads `prevMillis = ZSCORE(repeat, jobSchedulerId)`, recomputes next-millis via `getJobSchedulerEveryNextMillis` (offset/startDate arithmetic against `now`), **evicts the previous occurrence** (`removeJobFromScheduler` scans delayed/prioritized/wait/paused for the data-derived id `repeat:<id>:<prevMillis>`), then on collision (`EXISTS jobKey`) either advances one `every` slot or returns `-11 SchedulerJobSlotsBusy` (`every` case) / `-10 SchedulerJobIdCollision` (`pattern` case). It calls `storeJobScheduler` (rebuilds the `<repeat>:<id>` hash) and `addJobFromScheduler`, returning `{jobId, delay}`. **The illegal-to-lift form:** the occurrence id `"repeat:" .. jobSchedulerId .. ":" .. nextMillis` and its key `prefixKey .. jobId` are spliced from a ZSCORE-read data value, and the eviction scans sets for that data-derived id — both barred under A-1.

**v2 status — PARTIAL.** Registration + cadence are ported: `EchoMQ.Repeat.register/6` (the inline `@repeat_register` `Script.new(:repeat_register, …)`: `EXISTS KEYS[2]` idempotency guard, then `HSET KEYS[2] 'every_ms' … 'template' …` + `ZADD KEYS[1] <first_at> ARGV[1]`), with `EchoMQ.Pump` reading due registrations and minting occurrences. The **gap**: v2 has no in-script slot-collision codes (`-10`/`-11`) — fresh per-occurrence mint makes id collision structurally impossible, so the v1 slot-busy machinery has no port and needs none. `pattern`/`tz`/`endDate` cron semantics are not in `repeat.ex` (period-only `every_ms`).

**v3 reimplementation — PROPOSED.** Keep `register/6` over the two declared `{q}`-hashtagged keys; **add upsert** (a re-register of a live name updates `every_ms`/`template` and re-scores, rather than the v2 `:exists` no-op) to recover the v1 "override a repeatable" intent under the braced grammar (S-1). Next-millis derives from the **server clock** `TIME` at the pump's sweep (the emq.2 ruling DQ-2c — `TIME` where a lease/run-at is touched), every occurrence mints a **fresh branded `JOB` id gated at `Keyspace.job_key/2`** (`BrandedId.valid?`), and the registry record and zset member share one `{q}` slot by grammar (slot-soundness, S-6). The v1 eviction-of-previous-occurrence is **dropped**: a freshly-minted occurrence never collides, so there is nothing to evict.

```text
v1 (addJobScheduler-11)                         v3 (PROPOSED — EchoMQ.Repeat.register/6 + upsert)
─────────────────────────────────────────      ─────────────────────────────────────────────────
KEYS[1..11] repeat/delayed/wait/.../active      keys = [emq:{q}:repeat, emq:{q}:repeat:<name>]   -- both declared, one slot
prevMillis = ZSCORE(repeat, jobSchedulerId)     register: EXISTS KEYS[2] ? upsert(every_ms,template)+re-score
nextMillis = everyNextMillis(prev,every,now,…)    : HSET KEYS[2] every_ms/template; ZADD KEYS[1] first_at name
jobId = "repeat:"..id..":"..nextMillis  -- DATA  occurrence id = fresh branded JOB (host mint, job_key/2 gated)
jobKey = prefixKey .. jobId             -- DATA  next-run from server TIME at the Pump sweep (emq.2 DQ-2c)
collision? advance one slot | return -10/-11    fresh mint => no slot collision; no -10/-11
storeJobScheduler + addJobFromScheduler         Pump.sweep mints + enqueues the occurrence (Jobs.@enqueue)
return {jobId, delay}                           return {:ok, :registered | :upserted}
```

### getJobScheduler-1

**v1 purpose + mechanism.** Reads one scheduler record. KEYS[1] = `repeat`, ARGV[1] = id. It derives the hash key `KEYS[1] .. ":" .. ARGV[1]`, reads `score = ZSCORE(repeat, id)`, and on a hit returns `{HGETALL(<repeat>:<id>), score}`, else `{nil, nil}`. The derived hash key here is grammar-rooted from `KEYS[1]` + an ARGV id (the read is benign, no data-value key splice), so the mechanism is close to lift-legal already.

**v2 status — PARTIAL.** `EchoMQ.Repeat.count/2` reads registry depth (`ZCARD emq:{q}:repeat`) and `due/3` reads the due records (`ZRANGEBYSCORE` + per-name `HMGET … 'every_ms' 'template'`). The **gap**: there is no single-name **point read** returning one registration's record plus its score.

**v3 reimplementation — PROPOSED.** Add `get(conn, queue, name)` → `{score, %{every_ms, template}}`: a declared-keys read over `emq:{q}:repeat` (`ZSCORE`) + `emq:{q}:repeat:<name>` (`HGETALL`/`HMGET`), both composed by `Keyspace.queue_key/2` so they share the `{q}` slot, honest-row `:absent` when the member is missing. Read-only — no clock, no mint.

```text
v1 (getJobScheduler-1)                          v3 (PROPOSED — EchoMQ.Repeat.get/3)
─────────────────────────────────────────      ─────────────────────────────────────────────
KEYS[1] repeat ; ARGV[1] id                     keys = [emq:{q}:repeat, emq:{q}:repeat:<name>] -- one slot
key = KEYS[1] .. ":" .. id   (grammar-rooted)   ZSCORE emq:{q}:repeat  <name>
score = ZSCORE(repeat, id)                      HMGET  emq:{q}:repeat:<name>  every_ms template
hit ? {HGETALL(key), score} : {nil, nil}        {:ok, {score, %{every_ms, template}}} | {:ok, :absent}
```

### removeJobScheduler-3

**v1 purpose + mechanism.** Removes a scheduler and its one next-programmed job. KEYS[1..3] = `repeat`, `delayed`, `events`; ARGV = `jobSchedulerId`, prefix. It reads `millis = ZSCORE(repeat, id)`; if present it **removes the next delayed occurrence** by the data-derived id `"repeat:" .. id .. ":" .. millis` (`ZREM delayed`, `removeJobKeys(prefix .. delayedJobId)`, `XADD events removed`), then `ZREM repeat id` + `DEL <repeat>:<id>`, returning `0`/`1`. **Illegal-to-lift:** the `delayedJobId` is spliced from the ZSCORE-returned millis and used to build a key passed to `removeJobKeys` — a data-value-rooted key, barred under A-1.

**v2 status — PORTED.** `EchoMQ.Repeat.cancel/3` (`@repeat_cancel`: `local removed = ZREM KEYS[1] ARGV[1]; DEL KEYS[2]; return removed`) removes the registry member + record over the two declared keys, answering `:cancelled`/`:absent`.

**v3 reimplementation — PROPOSED.** Keep `cancel/3` verbatim in shape. The v1 "delete the next programmed job" half is **not lifted**: the next occurrence is a freshly-minted branded `JOB` (no `repeat:<id>:<millis>` to derive), so removing it routes through the Jobs surface against a declared key, never a data-rooted id splice. `cancel/3`'s two keys are `{q}`-co-located by grammar (S-6).

```text
v1 (removeJobScheduler-3)                        v3 (PROPOSED — EchoMQ.Repeat.cancel/3)
─────────────────────────────────────────       ─────────────────────────────────────────
KEYS[1..3] repeat/delayed/events                 keys = [emq:{q}:repeat, emq:{q}:repeat:<name>]
millis = ZSCORE(repeat, id)                      removed = ZREM KEYS[1] <name>
delayedId = "repeat:"..id..":"..millis  -- DATA  DEL KEYS[2]
ZREM delayed delayedId; removeJobKeys(prefix..)  -- no data-rooted next-job removal: occurrence is a branded JOB
ZREM repeat id; DEL repeat:id                    return removed  →  {:ok, :cancelled | :absent}
return 0 | 1
```

### updateJobScheduler-12

**v1 purpose + mechanism.** Iterates a scheduler (the per-occurrence "advance"): validate it exists, recompute next-millis, add the next delayed occurrence. KEYS[1..12] = `repeat`, `delayed`, `wait`, `paused`, `meta`, `prioritized`, `marker`, `id`, `events`, `pc`, `producer`, `active`; ARGV = next-millis, id, delayed data, delayed opts, timestamp, prefix, producer id. It reads `prevMillis = ZSCORE(repeat, id)` (guard: no scheduler → no iteration), `HMGET`s `name/data/every/startDate/offset`, recomputes `nextMillis` via `getJobSchedulerEveryNextMillis`, then **re-entry-guards on `producerId == currentDelayedJobId`** (the data-derived `"repeat:" .. id .. ":" .. prevMillis`). On a free next slot it `ZADD`s the new score, `HINCRBY ic`, mints (`INCR id`), and `addJobFromScheduler`s; else `XADD events duplicated`. **Illegal-to-lift:** both `currentDelayedJobId`/`nextDelayedJobId` and the producer-id comparison are rooted in ZSCORE/`HMGET` data values.

**v2 status — PORTED.** `EchoMQ.Repeat.advance/4` (`@repeat_advance`: if `EXISTS KEYS[2] == 0` then `ZREM KEYS[1] ARGV[1]; return 0` — sweep a dangling member — else `ZADD KEYS[1] <next_at> ARGV[1]; return 1`) re-scores the registration to now+`every_ms`, answering `:advanced`/`:absent`. `EchoMQ.Pump` (+ `Pump.Core`) drives the per-occurrence advance as part of its promote+fire-repeats sweep.

**v3 reimplementation — PROPOSED.** Keep `advance/4` + the pump. The v1 **producer-id re-entry guard is superseded**: the pump is the single owner-started cadence (`EchoMQ.Pump`, a `:transient` opt-in child), so concurrent re-iteration by a stray producer cannot occur and no data-rooted producer-id string is needed. The next-at is computed from server `TIME` at sweep time (emq.2 DQ-2c), and the mid-sweep-cancel sweep (`:absent` removing the dangling member) is retained — it is the honest-row, slot-sound replacement for v1's `duplicated` emission.

```text
v1 (updateJobScheduler-12)                       v3 (PROPOSED — EchoMQ.Repeat.advance/4 + Pump)
─────────────────────────────────────────       ─────────────────────────────────────────────
KEYS[1..12] repeat/delayed/.../producer/active   keys = [emq:{q}:repeat, emq:{q}:repeat:<name>]
prevMillis = ZSCORE(repeat, id)                  EXISTS KEYS[2] == 0 ? ZREM KEYS[1] name (sweep) ; return 0
HMGET name/data/every/startDate/offset           else ZADD KEYS[1] <next_at = TIME + every_ms> name ; return 1
guard: producerId == "repeat:"..id..":"..prev    -- re-entry guard SUPERSEDED by Pump single-owner sweep
ZADD repeat next; HINCRBY ic; INCR id; addJob    Pump.sweep mints fresh JOB + Jobs.@enqueue per occurrence
else XADD events duplicated                       advance answers {:ok, :advanced | :absent}
```

### updateRepeatableJobMillis-1

**v1 purpose + mechanism.** Legacy single-purpose re-score: re-set an existing repeatable's next-run millis. KEYS[1] = `repeat`, ARGV = next-millis, custom key, legacy custom key. It re-scores by whichever key exists: `if ZSCORE(repeat, customKey)` → `ZADD repeat nextMillis customKey` (return it); `elseif ZSCORE(repeat, legacyCustomKey) ~= false` → `ZADD … legacyCustomKey`; else `''`. The keys are zset **members** (ARGV-supplied), not constructed Redis keys, so this one does not splice a data-value key — but it embodies the legacy/custom-key **duality** that v2's single named registry removes.

**v2 status — PARTIAL.** `EchoMQ.Repeat.advance/4` re-scores a registration (`ZADD emq:{q}:repeat <next_at> <name>`). The **gap**: there is no standalone "re-score by arbitrary custom-or-legacy key" verb — v2 has exactly one registry keyed by **name**, with no legacy/custom key forms to disambiguate.

**v3 reimplementation — PROPOSED.** **Fold into `advance/4`** (an explicit-next-at re-score over the branded-name registry); the v1 legacy/custom-key branch is **dropped**. One name-keyed registration under the braced `emq:{q}:repeat` (S-1) means there is no second key shape to reconcile — the dual-key probe is a v1-only artifact that the v2 closed registry eliminates.

```text
v1 (updateRepeatableJobMillis-1)                 v3 (PROPOSED — folded into EchoMQ.Repeat.advance/4)
─────────────────────────────────────────       ─────────────────────────────────────────────────
KEYS[1] repeat ; ARGV next/custom/legacy         keys = [emq:{q}:repeat, emq:{q}:repeat:<name>]
ZSCORE(repeat, customKey) ? ZADD…customKey       ZADD emq:{q}:repeat <next_at> <name>   -- one named member
elseif ZSCORE(repeat, legacyKey) ? ZADD…legacy   -- legacy/custom DUALITY dropped (single closed registry, S-1)
else ''                                          return {:ok, :advanced | :absent}
```

### removeRepeatable-3

**v1 purpose + mechanism.** Legacy+new removal of a repeatable. KEYS[1..3] = `repeat`, `delayed`, `events`; ARGV = old repeat job id, options-concat (legacy member), repeat job key (new member), prefix. It tries the **legacy** path first (`millis = ZSCORE(repeat, ARGV[2])`; if present builds `repeatJobId = ARGV[1] .. millis`, `ZREM delayed` + `removeJobKeys(ARGV[4] .. repeatJobId)` + `XADD removed`; then `ZREM repeat ARGV[2]` → `0`), else the **new** path (`millis = ZSCORE(repeat, ARGV[3])`; builds `"repeat:" .. ARGV[3] .. ":" .. millis`, same removal; `ZREM repeat ARGV[3]` + `DEL <repeat>:<ARGV[3]>` → `0`), else `1`. **Illegal-to-lift:** both `repeatJobId` forms are spliced from the ZSCORE-returned millis and fed to `removeJobKeys` — data-value-rooted keys.

**v2 status — PORTED (new form).** `EchoMQ.Repeat.cancel/3` (`@repeat_cancel`) is the new-form removal: `ZREM` the member + `DEL` the record over the two declared keys. The **gap**: the v1 legacy concat-key branch has no v2 equivalent — there are no legacy ids in the v2 keyspace to remove.

**v3 reimplementation — PROPOSED.** `cancel/3` is the **single** removal verb; the v1 dual legacy/new branches **collapse to one**. The data-rooted next-programmed-job removal is dropped (the next occurrence is a freshly-minted branded `JOB`, removed via the Jobs surface against a declared key). One branded-name registry under braces means no legacy-id reconciliation path to carry.

```text
v1 (removeRepeatable-3)                           v3 (PROPOSED — EchoMQ.Repeat.cancel/3)
─────────────────────────────────────────        ─────────────────────────────────────────
KEYS[1..3] repeat/delayed/events                  keys = [emq:{q}:repeat, emq:{q}:repeat:<name>]
LEGACY: millis = ZSCORE(repeat, ARGV[2])          removed = ZREM KEYS[1] <name>
  repeatJobId = ARGV[1] .. millis        -- DATA  DEL KEYS[2]
  ZREM delayed; removeJobKeys(prefix..)            -- single path: legacy/new DUALITY collapsed (one registry)
NEW: millis = ZSCORE(repeat, ARGV[3])             -- no data-rooted next-job removal (occurrence is a branded JOB)
  repeatJobId = "repeat:"..ARGV[3]..":"..millis    return removed  →  {:ok, :cancelled | :absent}
ZREM repeat <member>; DEL repeat:key ; 0 | 1
```

## Family: move-active-wait

The four BullMQ-derived v1 commands that move a job **across the wait/active boundary** — the worker fetch (`moveToActive`), the worker-initiated return (`moveJobFromActiveToWait`), the bulk state→wait drain (`moveJobsToWait`), and the periodic stalled-recovery sweep (`moveStalledJobsToWait`). All four are structurally a *list↔list/zset move* in v1; the v2 line re-derives every one against the four-sorted-set state machine (§4 row 17, 23) under the v2 laws. None is a lift: each v1 form roots a per-job key in an `ARGV` prefix concatenated inside the script body (the open-keyspace flaw, design §0), which the declared-keys law (S-6) forbids.

> v1 files read: `moveToActive-11.lua`, `moveJobFromActiveToWait-9.lua`, `moveJobsToWait-8.lua`, `moveStalledJobsToWait-8.lua` (+ includes `prepareJobForProcessing`, `getTargetQueueList`, `moveJobToWait`, `addJobInTargetList`, `removeLock`, `moveJobFromPrioritizedToActive`). The features-catalog parity rows are `emq.features.md` B.2 lines 329 / 332 / 351.

### moveToActive-11

**v1 purpose + mechanism.** The worker's fetch primitive: move the next eligible job from `wait` to `active`, lock it for the lock-duration, and return its hash so the worker owns it. KEYS[1..11] = `wait, active, prioritized, events, stalled, rateLimiter, delayed, paused, meta, pc(priority counter), marker`; ARGV = `prefix, timestamp, opts(msgpack: token, lockDuration, limiter, name)`. It first promotes due delayed jobs (`promoteDelayedJobs`), checks the rate-limiter TTL and pause/maxed gate (`getTargetQueueList` reads `meta`), then `RPOPLPUSH wait active` (falling back to `moveJobFromPrioritizedToActive` = `ZPOPMIN prioritized` → `LPUSH active`). On a hit, `prepareJobForProcessing` writes the lock as a **separate string** `<prefix><jobId>:lock` (`SET … PX lockDuration`), bumps `ats`, emits the `active` event, and `HGETALL`s the row. **The v3-illegal form:** the job key and lock key are `keyPrefix .. jobId` and `jobKey .. ':lock'` — operand keys built from an `ARGV` prefix inside the script body, exactly what S-6/§0 forbid; and the fetch spans three structure types (wait LIST + prioritized ZSET + delayed ZSET) the engine cannot enumerate statically.

**v2 status — PORTED.** `EchoMQ.Jobs.claim/4` (`jobs.ex`, the `@claim` inline `Script.new(:claim, …)`): `ZPOPMIN` over the same-score `pending` zset, `HINCRBY attempts` to **mint the fencing token** (no separate `:lock` string — the lease IS the `active`-set score), `ZADD active (TIME + lease)` on the **server clock**, and returns `{id, payload, attempts}`. The queue-wide pause flag is read FIRST (`Jobs.paused?/2` on `emq:{q}:meta`), answering `:empty` with `pending` unmutated (emq.2.2-D2). The grouped/fair arm is `EchoMQ.Lanes.claim/3` (`@gclaim`: `LMOVE ring ring LEFT RIGHT` rotates one identity, then `ZPOPMIN` that lane). Features-catalog parity row 329 (✅, emq.0/emq.1).

**v3 PROPOSED.** Keep the as-built `@claim` as the canonical form — it already satisfies every law (declared `[pending, active]`; the per-job key derived in-script as `ARGV[1] .. id` rooted in the declared queue base, slot-sound per the S-6 2026-06-14 ARGV-rooting clarification; server-clock lease; branded id gated host-side at `Keyspace.job_key/2`). v3 PROPOSES that the **lane-aware claim is the mesh-facing default**: a node claims only the lanes it owns (the consistent-hashing ring, EchoMesh manuscript "Topology and locality"), so the rotating `@gclaim` ring becomes the per-owner work draw. The client-side multi-source pop (`LMPOP`/`ZMPOP`) is PROPOSED to stay rejected — every transition is one Lua script, atomic on the engine, and claim-IS-`ZPOPMIN`-inside-the-script (design §12.2). Forward-tense: v3 builds no new claim wire; it scopes the existing one to ownership.

**BCS relevance.** The single-writer claim — work is drawn atomically and the lease is the only proof of ownership, so the worker that holds a claimed job is the sole holder of it.

**EchoMesh relevance.** Sits on the **consistency-first** side of the dial (design §4 row 24): the claim surface refuses a second writer rather than risk divergence under partition (`art/echomesh/index.md` "Partition-survival").

```text
v1 moveToActive-11                            v3 PROPOSED (claim, lane-aware)
KEYS 1..11 (wait,active,prioritized,…,        @claim already shipped, declared [pending,active];
  marker); ARGV prefix,ts,opts(msgpack)       per-job key = ARGV[base]..id (slot-sound, S-6)
RPOPLPUSH wait active                          ZPOPMIN pending  (mint order = order theorem)
  | else ZPOPMIN prioritized -> LPUSH active   no prioritized set (retired, §6); lane = @gclaim ring
SET <prefix><id>:lock PX lockDuration          HINCRBY attempts  (token); ZADD active (TIME+lease)
HGETALL <prefix><id>                           return {id, payload, attempts}
v3-illegal: key = prefix .. id (data-rooted)   mesh: claim only owned lanes (ring)
```

### moveJobFromActiveToWait-9

**v1 purpose + mechanism.** The *worker-initiated* voluntary return of a still-held active job to wait (distinct from crash recovery). KEYS[1..9] = `active, wait, stalled, paused, meta, limiter, prioritized, marker, event`; ARGV = `jobId, lockToken, jobKey`. It checks the row `EXISTS`, calls `removeLock(jobKey, stalled, token, jobId)` — a **lock-token fence**: `GET <jobKey>:lock`; if it matches, `DEL` the lock + `SREM stalled`; else return `-6` (token mismatch) / `-2` (lock missing). Then `LREM active 1 jobId`; on success it reads the job's **priority from a hash field** (`HGET jobKey "priority"`) and either `pushBackJobWithPriority(prioritized, priority, jobId)` or `addJobInTargetList(target, …)` (target from `getTargetQueueList`), emits `waiting`, and returns the limiter `PTTL`. **The v3-illegal form:** `jobKey` arrives as **ARGV[3]** and `<jobKey>:lock` is built from it in-script (a data-supplied key operand); the priority operand (`prioritized` vs `wait`) is **chosen from a value read out of the hash** (`HGET … "priority"`) — both forbidden under S-6 (key choice driven by data, not by a declared root).

**v2 status — PARTIAL.** The *crash-recovery* direction of active→pending is ported (`Jobs.reap/2` `@reap`; `Stalled.check/3`), and the token-fence machinery exists (`extend_lock/5`'s `EMQSTALE` attempts fence; `@complete`/`@retry` are token-fenced active-exits). But a dedicated **voluntary, fenced active→pending that bumps no attempt and writes no morgue** — the v1 "I changed my mind, give it back" verb — has no counterpart; the nearest exit, `@retry`, consumes the attempt and schedules/dead-letters. The v1 priority arm is moot: the `prioritized` set is retired (the v2 `pending` is score-0, mint order IS the order theorem; per-group priority is `EchoMQ.Lanes` — features row 328, design §6).

**v3 PROPOSED.** A `requeue/4` verb: `attempts`-token-fenced (the v1 lock-token fence → the `EMQSTALE` attempts fence, the established complete/retry pattern) active→pending move that **does not increment attempts and does not touch the morgue**, declaring `[active, pending, job_key]` with the row gated at `Keyspace.job_key/2`. The v1 priority branch is PROPOSED to resolve via the lane arm (grouped child → its lane `emq:{q}:g:<group>:pending`, mirroring `@reap`'s group branch), never a separate prioritized set. Forward-tense: v3 adds this as a registered transition with its own conformance scenario (the additive-minor law).

**BCS relevance.** A worker cleanly yielding work it cannot finish back to the single-writer queue without burning a retry attempt — the cooperative give-back the decider/gateway needs under backpressure.

**EchoMesh relevance.** **Consistency-first**: the give-back lands on the job's owning slot (the same authoritative `pending` set), so a node shedding load never forks ownership.

```text
v1 moveJobFromActiveToWait-9                   v3 PROPOSED (requeue, fenced)
ARGV jobId, lockToken, jobKey                  declared [active, pending, job_key]; id gated
removeLock: GET <jobKey>:lock == token?        att = HGET job_key attempts; att == ARGV token?
  no -> -6 / -2 (lock string fence)              no -> EMQSTALE  (attempts fence, no :lock)
LREM active 1 jobId                            ZREM active id
p = HGET jobKey "priority"                     (no priority read; lane arm via row 'group')
  p>0 -> ZADD prioritized ; else RPUSH wait    ZADD pending 0 id   (or g:<grp>:pending)
XADD events waiting                            attempts UNCHANGED; no morgue
v3-illegal: key from ARGV[3]; arm from HGET    slot-local, declared, server-clock untouched
```

### moveJobsToWait-8

**v1 purpose + mechanism.** Bulk-move a window of completed/failed/delayed jobs to wait — operator/recovery replay. KEYS[1..8] = `base, events, stateKey(failed|completed|delayed), wait, paused, meta, active, marker`; ARGV = `count, timestamp, prevState`. It `ZRANGEBYSCORE stateKey 0 timestamp LIMIT 0 count` to take a window, `HDEL`s finish fields (`finishedOn/processedOn/failedReason|returnvalue`) per job, emits `waiting` per id, then in `batches(#jobs, 7000)` does `ZREM stateKey …` + `LPUSH target …`. Explicitly **"does not support jobs with priorities."** **The v3-illegal form:** each job's hash key is `KEYS[1] .. key` — the base key **concatenated with a set member inside the loop** (operand keys synthesized from data), the canonical S-6 violation; and `target` (wait vs paused) is a value from `getTargetQueueList`.

**v2 status — PARTIAL.** Single-job equivalents of the move exist — `Jobs.reprocess_job/3` (`@reprocess`: `dead`→`pending`, clears `last_error`, refuses non-`dead` with `EMQSTATE`) and `Jobs.promote/3` (`@promote`: due `schedule`→`pending`, batched by `ARGV[2]`). A **bulk, count-windowed retried-set→pending** verb across a whole state is **NOT YET** built. Note the source set `completed` is gone entirely — v2 is completion-deletes (no `completed` set; features row 330, design §4 row 27), so only `schedule` and `dead` are real sources.

**v3 PROPOSED.** A `requeue_set(state, count)` bulk verb over `schedule`/`dead`, declaring `[source_set, pending, queue_base]`, batched like `@promote`/v1's `batches`. The per-job row is reset in-script via the **grammar-derived** key `ARGV[base] .. 'job:' .. id` (the slot-sound A-1 form — never the v1 `KEYS[1] .. member`), clearing `last_error` and setting `state=pending`. The v1 "no priorities" caveat dissolves: a grouped member recovers into its lane (the `@promote` group branch), so the v3 form is *more* capable than v1. Forward-tense: v3 builds this as the operator bulk-recovery transition with its conformance scenario.

**BCS relevance.** Operator bulk-replay — after a deploy fix, return a window of dead/scheduled work to `pending` in mint order, the authoritative backlog the system re-drains.

**EchoMesh relevance.** **Consistency-first with an availability lever**: the replay writes the owning slot's `pending` (the regulated ledger stays correct), and the recovered backlog is exactly the consistent state the availability-first cache then serves (manuscript "Segmenting").

```text
v1 moveJobsToWait-8                            v3 PROPOSED (requeue_set, bulk)
ARGV count, ts, prevState(failed|completed|    declared [source_set(schedule|dead), pending,
  delayed)                                       queue_base]; count-windowed, batched
ZRANGEBYSCORE stateKey 0 ts LIMIT 0 count      ZRANGEBYSCORE source -inf +inf LIMIT 0 count
HDEL <base..member> finishedOn/returnvalue…    HSET <base..'job:'..id> state pending; HDEL last_error
batches: ZREM stateKey … ; LPUSH target …      ZREM source … ; ZADD pending 0 …  (mint order)
"does not support priorities"                  grouped member -> its lane (more capable)
v3-illegal: key = KEYS[1] .. member            key = ARGV[base]..'job:'..id  (A-1 grammar-derived)
```

### moveStalledJobsToWait-8

**v1 purpose + mechanism.** The periodic stalled-recovery sweep that reclaims jobs whose worker died holding them. KEYS[1..8] = `stalled(SET), wait, active, stalled-check(KEY), meta, paused, marker, events`; ARGV = `maxStalledJobCount, prefix, timestamp, maxCheckTime`. Guarded by a `SET stalled-check ts PX maxCheckTime` once-per-window lock (returns `{}` if it already EXISTS). It `SMEMBERS stalled` (the candidates marked last pass), and for each whose `<prefix><jobId>:lock` is **missing** (`EXISTS … == 0`): `LREM active`, `HINCRBY jobKey stc 1`, decode `HGET jobKey "opts"` to test `repeat`, and if `stc > maxStalledJobCount` **and not repeatable** stamp `defa` (the fail reason) — then `moveJobToWait` (→ wait/paused) + emit `stalled`. Finally it re-marks the still-`active` list into `stalled` (`SADD` in batches) as next pass's candidates — the **two-scan "mark, then sweep next time"** model. **The v3-illegal form:** `jobKey = queueKeyPrefix .. jobId` and `jobKey .. ":lock"` are built from `ARGV[2]` in-script (data-rooted operands), and the staleness signal is a *separate lock string's* presence, not a server-clock lease.

**v2 status — PORTED.** `EchoMQ.Stalled.check/3` (`stalled.ex`, the `@sweep_stalled` inline script): `ZRANGEBYSCORE active -inf <TIME>` takes genuinely **expired-lease** members on the **server clock**, `HINCRBY <job> stalled` (the v1 `stc` → the row's `stalled` field, no new key type), recovers below `max_stalled` (→ `pending` or, for a grouped job, its lane) and dead-letters at/above it (`state=dead`, `last_error="stalled"`, `ZADD dead`, `metrics:failed`++). It declares only `[active, pending, dead]` + the queue base — **never the v1 9-key LIST shape** — and runs as an opt-in `:transient` timer (the `Pump` shape) layered *above* the as-built single-scan `Jobs.reap/2`. Renamed `EchoMQ.Stalled` (not `StalledChecker`) to avoid shadowing the frozen v1 module on the shared code path (emq.2.3 ledger L-1). Features row 351 (🔨, emq.2.3, on disk).

**v3 PROPOSED.** The as-built `@sweep_stalled` is already the v3 form — v3 PROPOSES only to formalize what shipped: the v1 two-scan mark-then-sweep **collapses to one server-clock lease scan** (the `active`-set deadline IS the staleness fact, so no separate `stalled` candidate SET and no `:lock` probe are needed). The v1 repeatable-job exemption (a `repeat`-flagged job is never dead-lettered) is PROPOSED as a forward additive arm — a per-row policy field gating the dead-letter branch, registered with its own conformance scenario (additive-minor law); the as-built sweep currently always dead-letters past `max_stalled`. Forward-tense: v3 hardens the threshold + lane-recovery sweep and lifts it into the conformance set.

**BCS relevance.** The crash-recovery safety net for the single-writer model — a dead worker's in-flight leases return to its queue, and a job that repeatedly kills its worker dead-letters instead of looping the fleet.

**EchoMesh relevance.** **Consistency-first recovery** — the fold-to-state, restart-to-known-state principle (Armstrong, cited in both manuscripts) made operational: when a node holding a lane is lost, its leases recover on a survivor, the server-clock lease being the only liveness fact the mesh needs (manuscript "Partition-survival").

```text
v1 moveStalledJobsToWait-8                     v3 PROPOSED (= as-built @sweep_stalled, hardened)
KEYS 1..8 incl. stalled SET + stalled-check    declared [active, pending, dead] + queue base only
SMEMBERS stalled  (candidates from last pass)  ZRANGEBYSCORE active -inf <TIME>  (one scan)
if <prefix><id>:lock EXISTS==0 -> stalled      lease deadline IS the staleness signal (no :lock)
HINCRBY <prefix..id> stc 1                      HINCRBY <base..'job:'..id> stalled 1
stc>max AND not repeat -> stamp 'defa'          st>=max -> dead + last_error + metrics:failed++
moveJobToWait ; XADD stalled                    else -> pending (or g:<grp>:pending); state=pending
SADD stalled <still-active>  (mark next pass)   no candidate SET; server-clock, one direction
v3-illegal: key = ARGV[2] .. id ; :lock probe   forward arm: per-row 'repeat' exempts dead-letter
```

## Family: move-finish-delay-children

### moveToFinished-14

**v1 purpose + mechanism.** Moves a locked active job to a finished status (completed/failed). Takes **14 KEYS** (`wait`, `active`, `prioritized`, `event`, `stalled`, `rate-limiter`, `delayed`, `paused`, `meta`, `pc`, `completed/failed`, `jobId`, `metrics`, `marker`) and 9 ARGV (jobId, timestamp, the result/failedReason field+value, `target`, fetch-next?, prefix, packed opts, fields-to-update). It guards pending children (`SCARD jobId:dependencies`, `ZCARD jobId:unsuccessful`), releases the lock, `LREM`s from active, then runs the parent fan-in: it reads `parentKey`/`parent` **out of the job hash** (`HMGET jobIdKey "parentKey" "parent"`), `cjson.decode`s the parent JSON to get `id`+`queueKey`, and builds `parentKey..":dependencies"`/`..":processed"` from those **data values** — the v3-illegal form. It then `ZADD`s the terminal set (or `removeJobKeys`), `XADD`s the event, and optionally fetches the next job (`RPOPLPUSH` + `promoteDelayedJobs` + rate-limit check).

**v2 status — PORTED.** `EchoMQ.Jobs.complete/5` + the inline `@complete` `Script.new(:complete, …)` (`jobs.ex:175`). The v2 form does **completion-deletes** (`DEL KEYS[2]` — no `completed` set; `emq.features.md:330`), `ZREM`s active with attempts-as-token (`EMQSTALE` on mismatch), and runs the parent fan-in via the `@complete` decrement hook — but it reads the `parent` field **HOST-SIDE** in `EchoMQ.Flows.parent_of/3`/`parent_fail_of`, then passes the parent's `:dependencies`/`:processed`/row as **declared KEYS** (`flows.ex:476`, `emq.features.md:315`). The fail arm is `@retry`'s dead-letter block (`emq.features.md:330`). Same-queue fan-in is atomic; cross-queue release is eventually-consistent via `flow:outbox` + `Pump.sweep/1` (emq.3.3).

**v3 reimplementation — PROPOSED.** Keep `complete/5` over `@complete` essentially as-built; it already satisfies the v2 laws. The v3 evolution is **not** a re-lift but a confirmation + two clarifications: (1) the finalize-status "result" stays the host-supplied `ARGV[5]` value the parent reads back over `:processed` (`children_values/3`) — never a Lua-decoded data key; (2) the v1 mega-script's tail (fetch-next + promote-delayed + drained-event) is PROPOSED to stay **decomposed** into the separate `claim`/`promote` verbs rather than folded back into `complete` — one act per script keeps slot-soundness trivial. Every parent key remains gated at `Keyspace.job_key/2` and declared in `KEYS[]` (S-6, `emq.design.md:95`).

```text
v1  moveToFinished-14
    KEYS[12]=jobId, ARGV[5]=target("completed"/"failed")
    parent = cjson.decode(HMGET jobIdKey "parent")   -- DATA VALUE → key
    SREM (parentKey..":dependencies") jobIdKey        -- key rooted in hash field
    updateParentDepsIfNeeded(...) → moveParentToWait  -- may cross queues, same EVAL
    LREM active; ZADD completed/failed | removeJobKeys; XADD completed/failed
```
```text
v3 (PROPOSED) — EchoMQ.Jobs.complete/5 + @complete  [as-built, confirmed]
    KEYS=[active, parent:dependencies, parent:processed, parent_row, ...] DECLARED
    host reads child row `parent`/`parent_queue` HOST-SIDE (Flows.parent_of/3)
    ZREM active (attempts-as-token, EMQSTALE) ; DECR KEYS[3] ; release parent at 0
    same-slot fan-in atomic ; cross-queue → flow:outbox + Pump.sweep (eventual)
    completion-deletes (DEL row) ; honest-row {:ok}/{:error,{:stale,...}}
```

### moveToDelayed-8

**v1 purpose + mechanism.** Moves a locked active job back to the delayed set (the retry/backoff path). Takes **8 KEYS** (`marker`, `active`, `prioritized`, `delayed`, `job`, `events`, `meta`, `stalled`) + 7 ARGV (prefix, timestamp, jobId, token, delay, skip-attempt, fields-to-update). It releases the lock (`removeLock` against `stalled`+token), `LREM`s active, computes a baked score via `getDelayedScore` (`delayedTimestamp * 0x1000` + a tie-break, so order is preserved within a ms), conditionally `HINCRBY atm`, `HSET delay`, `ZADD delayed score jobId`, `XADD delayed`, and pushes a wake marker. Key operands here are **all KEYS-passed** (the job key is `KEYS[5]`), so this command is closer to liftable than its siblings — but the delayed *score* encodes order in a packed integer, a form v3 re-derives on the server clock.

**v2 status — PORTED** (as the retry-reschedule). `EchoMQ.Jobs.retry/7` + the **non-terminal arm of `@retry`** (`jobs.ex:305`): below max-attempts it reads server `TIME`, sets `state=scheduled`, and `ZADD KEYS[2] now+delay id` on the `schedule` set, keeping `last_error` (`emq.features.md:331`). The host-side `EchoMQ.Backoff.delay_ms/2` computes the delay literal (fixed/exponential/jitter) and hands it to `retry/7` (surface map). There is no separate `delayed` set — v2 collapses delayed+scheduled into one server-clock-scored `schedule` zset.

**v3 reimplementation — PROPOSED.** Retain `@retry`'s scheduled arm as the canonical active→scheduled transition; the v1 `0x1000`-baked composite score is **superseded** by the plain server-clock `now+delay` score (`TIME` inside the transition is the ratified DQ-2c law, `emq.design.md:218`). If a *non-failure* host-initiated defer is ever required (the literal v1 "move-to-delayed" semantics, distinct from a retry), v3 PROPOSES a thin `defer/…` verb that routes the same `ZADD schedule now+delay` over declared `[active, schedule]` keys — additive, no new score scheme, attempts left untouched. All keys declared; the score is owned by the engine clock, not the caller's timestamp.

```text
v1  moveToDelayed-8
    KEYS[5]=jobKey (declared) ; ARGV[2]=timestamp (CLIENT clock), ARGV[5]=delay
    score = getDelayedScore = delayedTimestamp*0x1000 + tiebreak  -- packed order
    removeLock ; LREM active ; HINCRBY atm ; HSET delay ; ZADD delayed score id
```
```text
v3 (PROPOSED) — EchoMQ.Jobs.retry/7 + @retry scheduled arm  [as-built]
    KEYS=[active, schedule, dead, child_row] DECLARED ; Backoff.delay_ms host-side
    t = TIME ; now = t[1]*1000+... ; ZADD schedule (now+delay) id  -- SERVER clock
    state=scheduled ; last_error kept ; returns 'scheduled' (honest row)
  + PROPOSED defer/… : same ZADD schedule over [active, schedule], attempts intact
```

### moveToWaitingChildren-7

**v1 purpose + mechanism.** A *worker* voluntarily parks its own active job into waiting-children. Takes **7 KEYS** (`active`, `wait-children`, `job`, `job:dependencies`, `job:unsuccessful`, `stalled`, `events`) + 5 ARGV (token, child key, timestamp, jobId, prefix). If the job has failed children (`ZCARD jobUnsuccessfulKey ~= 0`) it returns `-9`; otherwise, if a named child is still an unmet dependency (`SISMEMBER jobDependenciesKey ARGV[2]`) **or** any deps remain (`SCARD`), it releases the lock, `LREM`s active, and `ZADD`s the job into `waiting-children`; if no deps remain it returns `1` ("nothing pending"). The dependency keys are KEYS-passed here, but the *trigger* is a worker deciding mid-execution to await children it may have just added — a control-flow shape, not just a finalize.

**v2 status — PARTIAL.** The *fan-in* this command supports is built — `EchoMQ.Flows` holds the parent out of `pending` with `state = awaiting_children` and `:dependencies = N`, releasing it at zero via the `@complete` hook (`flows.ex:2`, `emq.features.md:186`). But that is the **add-time** held-parent model. The distinct v1 capability — a worker, *during its own execution*, parking its already-active job pending a runtime-discovered child — has **no dedicated v2 verb**; v2 flows are declared at `add/3` time, and the `awaiting_children` read-plane is a pure read (`dependencies/3`), not a worker-initiated park.

**v3 reimplementation — PROPOSED.** Add an explicit `await_children/…` verb on `EchoMQ.Flows`. The host reads the outstanding-dependency count and `:unsuccessful` cardinality **HOST-SIDE** (the `flows.ex` `parent_of/3`/`dependencies/3` pattern — never a Lua key rooted in a hash field, S-6/INV2, `emq.design.md:95`), then issues a single same-slot transition that `ZADD`s the parent into an `awaiting_children`/wait-children set guarded on its slot. Honest-row return: `{:awaiting, n}` (parked), `{:ready, 0}` (no pending deps — caller proceeds), `{:failed_children}` (the v1 `-9`). The failed-children guard is preserved as a host read + a declared-key check, not a data-rooted `SISMEMBER`.

```text
v1  moveToWaitingChildren-7
    KEYS[4]=job:dependencies, KEYS[5]=job:unsuccessful (declared)
    if ZCARD unsuccessful ~= 0 -> -9
    if SISMEMBER deps ARGV[2] (named child) OR SCARD deps ~= 0:
        removeLock ; LREM active ; ZADD waiting-children score jobId
    else return 1   -- nothing pending, worker proceeds
```
```text
v3 (PROPOSED) — EchoMQ.Flows.await_children/…  [NEW verb, flows pattern]
    host reads dep-count + :unsuccessful HOST-SIDE (parent_of/3 / dependencies/3)
    one same-slot EVAL: KEYS=[active, awaiting_children, parent_row] DECLARED
    guard failed children host-side -> {:failed_children}
    ZADD awaiting_children parent ; row state=awaiting_children
    honest row: {:awaiting,n} | {:ready,0} | {:failed_children}
```

### promote-9

**v1 purpose + mechanism.** Promotes ONE specific delayed job (by id) immediately to wait/prioritized. Takes **9 KEYS** (`delayed`, `wait`, `paused`, `meta`, `prioritized`, `active`, `pc`, `event`, `marker`) + 2 ARGV (`queue.toKey('')` prefix, jobId). It `ZREM`s the id from `delayed` (returning `-3` if absent), reads the job's `priority` (`HGET (ARGV[1]..jobId) "priority"` — the job key built by **concatenating the prefix ARGV with the id**), strips a stale wait-list marker, then either `LPUSH`es to the target list (priority 0) or `addJobWithPriority`s into prioritized, `XADD`s `waiting`, and `HSET delay 0`. The targeted single-id force-promote is the distinguishing trait (vs a due-sweep).

**v2 status — PARTIAL.** `EchoMQ.Jobs.promote/3` + `@promote` (`jobs.ex:312`, `emq.features.md:333`) exists and is driven by `Pump`, but it promotes **all *due* members** of the `schedule` set up to a batch (`ZRANGEBYSCORE schedule -inf now LIMIT 0 batch` on the server clock), routing each to `pending` (or its lane). It is the *due-sweep*, not a targeted single-id force-promote regardless of due-time. The v1 "promote THIS id NOW even if not yet due" semantics has no dedicated v2 verb.

**v3 reimplementation — PROPOSED.** Add a sibling `promote_now/3` beside the batch `promote/3`. It declares `[schedule, pending]` keys, gates the id at `Keyspace.job_key/2` (the v3 fix for v1's prefix-concatenation key build), and does a single same-slot `ZREM schedule id` + `ZADD pending 0 id` + `HSET row state pending` — the targeted force-promote, ignoring due-time. The job-key is built by the gated key builder, never by ARGV string concatenation (S-6, `emq.design.md:149`). Honest-row: `{:ok, 1}` promoted / `{:ok, 0}` (not in schedule — the v1 `-3`). The lane-aware branch reuses the `@promote` group logic.

```text
v1  promote-9
    KEYS[1]=delayed ; ARGV[1]=prefix, ARGV[2]=jobId
    if ZREM delayed jobId == 1:
        jobKey = ARGV[1] .. jobId          -- key built from ARGV concat (illegal v3)
        priority = HGET jobKey "priority"
        LPUSH wait jobId | addJobWithPriority(...) ; XADD waiting ; HSET delay 0
    else return -3
```
```text
v3 (PROPOSED) — EchoMQ.Jobs.promote_now/3  [NEW, beside batch @promote]
    KEYS=[schedule, pending] DECLARED ; id gated at Keyspace.job_key/2
    one same-slot EVAL: ZREM schedule id ; ZADD pending 0 id ; HSET row state pending
    lane-aware branch reuses @promote group logic (g:/ring/wake)
    honest row: {:ok,1} promoted | {:ok,0} not-scheduled   (v1 -3)
    (batch due-sweep promote/3 retained unchanged — server-clock ZRANGEBYSCORE)
```

## Family: retry-reprocess-change

### retryJob-11

**v1 purpose + mechanism.** Retries a failed job by moving it from `active` back to the wait surface. Takes **11 KEYS** (`active`, `wait`, `paused`, *job key*, `meta`, `events`, `delayed`, `prioritized`, `pc` priority-counter, `marker`, `stalled`) and **6 ARGV** (prefix, timestamp, pushCmd, jobId, token, optional field updates). It first opportunistically `promoteDelayedJobs`, then `removeLock(jobKey, stalled, token, jobId)` — **rooting the lock at `jobKey .. ':lock'` and comparing a caller-passed token** — `LREM`s the id out of `active`, reads `priority` from the job hash, and re-adds to `wait` (standard) or `prioritized` (`addJobWithPriority`), bumping `atm` and emitting `waiting`. The lock-string + token compare and the read-then-route on `HGET priority` are the data-rooted forms v3 cannot lift.

**v2 status — PARTIAL.** The v1 capability is **split, not single-verb-ported**. Worker-driven retry is `EchoMQ.Jobs.retry/7` over inline `@retry` (jobs.ex:252–310): an `active`→`scheduled` (with `Backoff` delay) or `active`→`dead` transition, token-fenced on the row's `attempts` (`EMQSTALE`), lane-aware. Operator "un-fail" is `reprocess_job/3` (`dead`→`pending`). There is **no** single v2 verb that does v1's exact "release the lock and move the *active* job straight back to `pending` now." So: PARTIAL — the effect is reachable in pieces, the discrete operator verb is absent.

**v3 decision — PROPOSED.** Re-derive v1's operator intent as a declared-keys `requeue_active/4` (queue, job_id, token, opts): `KEYS = [active, pending(or the lane), job_key]`, all braced `emq:{q}:` (slot-sound, design §3 lines 97–112). The lease is the `active` *score* (not a `:lock` string) — releasing it is a `ZREM` from `active` + `ZADD` to `pending` at score 0, token-fenced on `attempts` exactly as `@retry` already does (`EMQSTALE`). Branded `JOB` id gated at `Keyspace.job_key/2`; honest-row CONF scenario; server `TIME` only if a lease deadline is touched. No data-value lock token, no `HGET priority` route (priority retired — see changePriority).

**BCS relevance.** PROPOSED: the operator "kick a stuck/abandoned claim back to the front of the queue" control for a consumer's work lane — a manual recovery hook on the work surface.

**EchoMesh relevance.** PROPOSED: a **consistency-first (CP) side** operator action — a deliberate, audited, single-writer-serialized mutation (the M5 "Best Effort Availability" surface: correct always, the rare manual path), never an availability/throughput path.

```text
v1 retryJob-11                              v3 (PROPOSED) requeue_active/4
KEYS[1..11]: active,wait,paused,JOBKEY,     KEYS = [ emq:{q}:active,
  meta,events,delayed,prioritized,pc,                emq:{q}:pending,
  marker,stalled                                     emq:{q}:job:<branded> ]  (all braced, slot-sound)
ARGV: prefix,ts,pushCmd,jobId,token,fields  ARGV = [ job_id, attempts-token, lease? ]
removeLock(jobKey..':lock', token)  -- DATA  fence: HGET attempts == token else EMQSTALE
LREM active -1 jobId                         ZREM active <id>          (lease IS the score)
HGET priority -> route wait|prioritized      ZADD pending 0 <id>       (no priority; lane-aware)
XADD events waiting; HINCRBY atm 1           honest-row CONF; server TIME only if lease touched
```

### reprocessJob-8

**v1 purpose + mechanism.** Reprocesses a finished job. Takes **8 KEYS** (*job key*, `events`, *job-state set*, `wait`, `meta`, `paused`, `active`, `marker`) and **6 ARGV** (job.id, pushCmd, propVal, prev-state, reset-`atm`, reset-`ats`). It `ZREM`s the id from its state zset, `HDEL`s `finishedOn`/`processedOn`/the result field (+ optional `atm`/`ats`), re-adds to the wait target, then **reads `parentKey` from the job hash (`HGET jobKey "parentKey"`) and re-links the parent's `:unsuccessful`/`:failed`/`:processed`/`:dependencies` subkeys** — the classic v1 illegality: a key operand (`parentKey`, and the `parentKey .. ":dependencies"` derivations) is rooted in a **data value**, structurally inexpressible under declared-keys (design §11.10).

**v2 status — PORTED.** `EchoMQ.Jobs.reprocess_job/3` + inline `@reprocess` (jobs.ex:855–866, fn :928–939; emq.2.2 `76fc947c`; emq.features.md B.2 `reprocessJob-8` row ✅). Re-derived clean: the bus's only finished-and-retained state is `dead`, so reprocess is `dead`→`pending` — `KEYS = [job_key, dead, pending]` (all declared), clears `last_error`, sets `state=pending`, `ZADD pending 0 id`; **refuses a non-dead job** with `EMQSTATE` → `{:error, :not_dead}`, missing → `{:error, :gone}`. The v1 parent-dependency mend is **deliberately not in this port** (flows are the separate emq.3 family).

**v3 decision — PROPOSED.** Keep the shipped `@reprocess` as the spine and **add the flow fan-in re-link the A-1-clean way**: when a reprocessed job is a flow child, restore the parent's outstanding count via the **declared §6 parent subkeys** `emq:{q}:job:<parent>:{dependencies,processed,failed,unsuccessful}` (the emq.3 dependency-graph home, emq.features.md C.1) — never the v1 data-value `parentKey`. Cross-queue parents ride the eventually-consistent `flow:outbox` + `Pump.sweep` hop (emq.3.3), so reprocess stays single-slot atomic and the parent signal is idempotent. Branded id at the builder; honest-row CONF.

**BCS relevance.** PROPOSED: the post-incident "re-run a dead job after fixing its cause" recovery a consumer's operator runbook drives.

**EchoMesh relevance.** PROPOSED: a **CP-side recovery verb** — deterministic, single-slot, audited; the consistency-first ledger/queue's repair lever (M5 segmentation: the regulated surface that is correct-always).

```text
v1 reprocessJob-8                            v3 (PROPOSED, on the shipped @reprocess)
KEYS[1..8]: JOBKEY,events,STATESET,wait,     KEYS = [ emq:{q}:job:<branded>,
  meta,paused,active,marker                          emq:{q}:dead, emq:{q}:pending ]  (declared)
ZREM stateset id; HDEL finishedOn/...        ZREM dead id; HDEL last_error; HSET state=pending
addJobInTargetList(wait, ...)                ZADD pending 0 id        (refuse non-dead -> EMQSTATE)
HGET jobKey "parentKey"            -- DATA    parent re-link via DECLARED §6 subkeys:
ZREM parentKey..':unsuccessful' / ':failed'    emq:{q}:job:<parent>:{dependencies,failed,
SADD parentKey..':dependencies'   -- DATA       unsuccessful,processed}  (emq.3 flow home)
                                             cross-queue parent -> flow:outbox + Pump.sweep (3.3)
```

### changeDelay-4

**v1 purpose + mechanism.** Changes a job's delay while it sits in the `delayed` set. Takes **4 KEYS** (`delayed`, `meta`, `marker`, `events`) and **4 ARGV** (delay, timestamp, jobId, *job key*). It checks the job exists, computes a new score via `getDelayedScore` (baking the new `timestamp+delay` into the high bits with the 12-bit FIFO tiebreak), `ZREM`s then `ZADD`s the id back at the new score, `HSET`s `delay` on the hash, emits `delayed`, and re-arms the marker. The *job key* arrives as **ARGV[4] (a data-supplied operand)** rather than a declared KEY — the v1 form v3 cannot lift.

**v2 status — NOT YET.** No `change_delay` exists (grep of `lib/` returns nothing). The bus has the adjacent machinery — the `schedule` set, `enqueue_at/5`/`enqueue_in/5` + inline `@schedule` (jobs.ex:38, :67), and `@promote` (jobs.ex:312) that releases due members — but **no verb that re-scores a member already on `schedule` in place**. It is not in the emq.features.md parity table at all (an unlisted v1 script).

**v3 decision — PROPOSED.** A declared-keys `reschedule/4` (queue, job_id, new_run_at | new_delay): `KEYS = [schedule, job_key]` (both braced `emq:{q}:`, slot-sound); the job key is a **declared KEY**, not ARGV[4]. Re-`ZADD` the `schedule` member under a server-`TIME`-derived run-at (the v2 schedule set is run-at-scored, not the v1 12-bit-packed score, so `getDelayedScore`'s bit-baking dissolves — the order theorem already orders by mint), refuse a job not on `schedule` (`EMQSTATE`), missing → `{:error, :gone}`. Branded id gated at the builder; honest-row CONF; design §3 declared-keys + server-clock laws.

**BCS relevance.** PROPOSED: lets an operator push out or pull in a scheduled report or a repeatable periodic job without a drop-and-re-add round trip.

**EchoMesh relevance.** PROPOSED: a CP-side admin write to a scheduled item; the *delay itself* is exactly the M4 "Trading Consistency for Availability" **staleness-budget dial** — tuning how far a deferred surface may lag, on purpose.

```text
v1 changeDelay-4                             v3 (PROPOSED) reschedule/4
KEYS[1..4]: delayed,meta,marker,events       KEYS = [ emq:{q}:schedule,
ARGV: delay,timestamp,jobId,JOBKEY -- KEY            emq:{q}:job:<branded> ]   (job key DECLARED)
                                  in ARGV!   ARGV = [ job_id, new_run_at | new_delay ]
score = getDelayedScore(ts,delay)            t = TIME; run_at = server-clock derived
  (timestamp<<12 | 12-bit FIFO tiebreak)     (schedule set is run-at-scored; no bit-baking;
ZREM delayed id; ZADD delayed score id        order theorem already orders by mint)
HSET JOBKEY delay; XADD events delayed       ZREM schedule id; ZADD schedule run_at id
addDelayMarkerIfNeeded                       refuse non-scheduled -> EMQSTATE; honest-row CONF
```

### changePriority-7

**v1 purpose + mechanism.** Changes a job's priority while it waits. Takes **7 KEYS** (`wait`, `paused`, `meta`, `prioritized`, `active`, `pc` priority-counter, `marker`) and **4 ARGV** (priority, *prefix key*, jobId, lifo). It builds `jobKey = ARGV[2] .. jobId` (**the job key rooted in a data-value prefix concat**), removes the id from `prioritized` (or `LREM` from the wait target), then `reAddJobWithNewPriority` — score-0 → `addJobInTargetList`, else `addJobWithPriority`/`pushBackJobWithPriority` against the `pc` counter — and `HSET`s the new `priority`. Both the ARGV-concat job key and the whole `prioritized`-ZSET-+-counter machine are forms v3 cannot lift.

**v2 status — NOT YET, and the capability is RETIRED by design.** No `change_priority` (grep returns nothing), and the priority *concept* is gone from the v2 line: jobs.ex/lanes.ex carry no `priority`/`prioritized`. The design **retires the v1 `prioritized` ZSET** — emq.features.md B.2 `addPrioritizedJob-7` row: "the v2 `pending` set is score-0 (mint order IS the order theorem); priority lanes are `EchoMQ.Lanes` (per-group). No separate prioritized set (design §6 — the v1 `prioritized` type retires)." So there is nothing to re-prioritize.

**v3 decision — PROPOSED (re-aim, not re-implement).** v3 has **no priority re-score verb** — re-scoring a `prioritized` ZSET is structurally absent. The forward equivalent of "this work matters more now" is **`EchoMQ.Lanes` group control**: re-assign the job's lane, or tune weighted/deficit rotation + ceilings (the emq.4 "groups deepened" rung, emq.features.md Movement II). Branded id + braced lane keys remain the law; ordering within `pending` stays mint-order (the order theorem). The honest v3 stance is the retirement, with Lanes as the answer to the *need* changePriority served.

**BCS relevance.** PROPOSED: per-player fairness (one `EchoMQ.Lanes` group per player) replaces per-job priority for a consumer's work surface — codemoji shapes lanes one group per player.

**EchoMesh relevance.** PROPOSED: lane fairness is the **AP-leaning dial** — "flood one player's lane, the others keep answering" (the emq.4 deepened groups carry codemoji's per-player lanes to cluster scale) — the availability-first segment of the mesh's work plane.

```text
v1 changePriority-7                          v3 (PROPOSED) -- RE-AIMED to Lanes (emq.4)
KEYS[1..7]: wait,paused,meta,prioritized,    No priority ZSET, no priority re-score verb.
  active,pc(counter),marker                  pending is a score-0 ZSET; order = mint
ARGV: priority, PREFIX, jobId, lifo          (the order theorem -- design §6).
jobKey = PREFIX .. jobId          -- DATA     "matters more now" -> EchoMQ.Lanes group control:
ZREM prioritized id / LREM wait id             - re-assign the job's lane
addJobWithPriority(pc-scored) /                - weighted/deficit rotation + ceilings (emq.4)
  pushBackJobWithPriority                     keys braced emq:{q}:g:<group>:... ; branded id gated
HSET jobKey priority                         the v1 `prioritized` type is RETIRED, not ported
```

## Family: locks

The v1 locks family is BullMQ's **separate-`…:lock`-string** lease model: a per-job string key (`<base><jobId>:lock`) holds an opaque worker token under a `PX` TTL, and a job's liveness is the *presence + expiry* of that string. Under the v2 laws this whole mechanism is **structurally inexpressible as-written** — v1 roots the lock key in a data-derived `baseKey .. jobIds[i] .. ':lock'` (extendLocks unpacks `baseKey`/ids/tokens from `cmsgpack` ARGV blobs), and the lease lives in a key *separate from the active set*. The v2 bus already **re-derived this family** at emq.2.3 (D4/D5) under the L-1/L-2/L-3 split: **the lease IS the `active`-set score** (no separate lock string as the clock), the `:lock` subkey survives **only** as a worker-held *presence marker* `remove_job` reads, and the worker-side cadence lives in the opt-in supervised `EchoMQ.Locks` plane. v3 inherits all three as shipped and only *extends* them for what BCS + EchoMesh need.

### extendLock-2

**v1 purpose + mechanism.** Renew a single job's lock and clear it from stalled recovery. `KEYS=[lock, stalled]`; `ARGV=[token, lockDuration_ms, jobid]`. It guards `GET KEYS[1] == ARGV[1]` (token match), then `SET KEYS[1] ARGV[1] PX ARGV[2]` and `SREM KEYS[2] ARGV[3]`, returning `1`/`0`. The lease lives in a **standalone `…:lock` string** whose `PX` TTL *is* the deadline — the form v3 cannot lift: the lease clock is a key separate from the work set, and the duration arrives caller-side (no server clock).

**v2 status — PORTED.** `EchoMQ.Jobs.extend_lock/5` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex`) + the inline `@extend_lock Script.new(:extend_lock, …)`. Declared `KEYS=[active, job_key]`; it reads `HGET job_key attempts`, refuses `EMQSTALE` on a token mismatch, reads server `TIME`, and re-scores the `active` member to `now + lease_ms` (`ZADD KEYS[1]`). `-1`→`{:error, :gone}`, `1`→`:ok`. The v1 stalled-`SREM` is gone — there is no stalled *set* to clear because the lease IS the score (the stalled-recovery sweep `EchoMQ.Stalled` reads the score, not a set).

**v3 reimplementation — PROPOSED.** Hold the shipped form verbatim (it already satisfies every law: declared keys, branded id gated at `Keyspace.job_key/2`, server `TIME` where the lease is touched, `EMQSTALE` fence — no new wire class). The forward extension BCS/EchoMesh want is **return the new `lease_deadline`** (the computed `now + lease_ms`) so a consumer fences its own remaining headroom rather than re-deriving it caller-side — a return-shape additive minor, no protocol break.

```text
v1 extendLock-2                          v3 extend_lock (PROPOSED, holds emq.2.3-D4)
KEYS[1]=lock  KEYS[2]=stalled            KEYS=[active, job_key]   (declared; branded id gated)
ARGV=[token, dur_ms, jobid]              ARGV=[job_id, token, lease_ms]
GET lock == token ?                      HGET job_key attempts == token ? else EMQSTALE
  SET lock token PX dur  (caller clock)    t=TIME; ZADD active (now+lease_ms) job_id  (server clock)
  SREM stalled jobid                       — no stalled set: lease IS the active score
return 1/0                               return 1 (:ok) / -1 (:gone) [+ lease_deadline]
```

### extendLocks-1

**v1 purpose + mechanism.** Batch-renew leases for many jobs in one round trip. `KEYS=[stalled]`; `ARGV=[baseKey, tokens, jobIds, lockDuration]` where `tokens`/`jobIds` are `cmsgpack`-packed arrays. It loops: `lockKey = baseKey .. jobIds[i] .. ':lock'`, `GET lockKey`, and on token match `SET lockKey token PX lockDuration` + `SREM stalled jobId`, else pushes to `failedJobs` (returned). **This is the canonical declared-keys violation** — the per-job key is built from a `baseKey` data value carried in ARGV (not a `KEYS[]` root), so v3 is a re-derivation, never a lift.

**v2 status — PORTED.** `EchoMQ.Jobs.extend_locks/4` + the inline `@extend_locks`. The sole declared key is `KEYS[1]=active`; each per-job key is grammar-derived in-script as `base .. 'job:' .. id` where `ARGV[1]=emq:{q}:` provably carries the *same braced `{q}` slot* as `KEYS[1]` — the **Operator-ratified 2026-06-14 slot-rooted-ARGV A-1 wording** (`emq.design.md` §1, the `@extend_locks` clarification), used precisely because the id set is variadic-at-author-time. One `TIME` read scores the whole batch; every id is gated `Keyspace.job_key/2` host-side before the wire (`Enum.each(held, …)`); it returns `failed`. This is exactly the verb `EchoMQ.Locks.extend/1` calls each beat.

**v3 reimplementation — PROPOSED.** Keep the as-built variadic slot-rooted form (S-6 binds unchanged — slot-soundness is discharged and reviewer-nameable, *not* an exemption). The forward need is **observability on the held set**: `Locks.extend/1` already answers `{:ok, %{extended: n, dropped: ids}}` — surface that as the lock plane's emitted telemetry so a fleet's lease-keeping is an honest-row metric (BCS/EchoMesh both run many lease-holders). No script change; a reporting surface over the shipped batch.

```text
v1 extendLocks-1                              v3 extend_locks (PROPOSED, holds emq.2.3-D4 + the A-1 ruling)
KEYS[1]=stalled                               KEYS=[active]   (the only declared key)
ARGV=[baseKey, cmsgpack tokens,               ARGV=[emq:{q}:, lease_ms, id1,tok1, id2,tok2, …]
      cmsgpack jobIds, dur]                          ^ ARGV[1] carries KEYS[1]'s {q} slot (slot-sound, A-1)
for each id:                                  t=TIME (once)
  lockKey = baseKey..id..':lock'  ← DATA-ROOTED   for each (id,tok):
  GET lockKey == token ?                          jk = ARGV[1]..'job:'..id  (grammar-derived, slot-sound)
    SET lockKey PX dur (caller clock)             HGET jk attempts == tok ?
    SREM stalled id                                 ZADD active (now+lease) id   (server clock)
  else failed[]+=id                               else failed[]+=id
return failed                                 return failed   → Locks.extend ⇒ {extended, dropped}
```

### releaseLock-1

**v1 purpose + mechanism.** Release one job's lease. `KEYS=[lock]`; `ARGV=[token, lockDuration]`. It guards `GET KEYS[1] == ARGV[1]`, then `DEL KEYS[1]` (returns the del count) else `0`. The lease end is a **`DEL` of the standalone `…:lock` string** — again the v1 separate-lock-string model the v2 keyspace does not carry.

**v2 status — PORTED (re-split per L-3).** The release splits across the two v2 mechanisms (`emq.design.md` L-1/L-2/L-3, `locks.ex` moduledoc): (a) the **lease** is released by the natural `active`-score expiry or `complete/4`, never an explicit `DEL`; (b) the **presence marker** `emq:{q}:job:<id>:lock` (written on `track_job/3`) is DELeted by `EchoMQ.Locks.untrack_job/2` on completion/release. That marker is what `EchoMQ.Jobs.remove_job/4` reads (`EXISTS jk..':lock'` → `EMQLOCK`, `jobs.ex:802`) to refuse deleting a held job. The marker also carries a self-expiring `PX` TTL (`Locks.Core.marker_ttl_ms/1`, default 2×lease, PEXPIRE-refreshed each beat) — restoring the v1 lock-string's self-healing under the v2 split (L-3).

**v3 reimplementation — PROPOSED.** Keep the two-part release: `untrack_job` DELs the marker; the lease ends by score, never a `DEL` of a lock-string-as-clock (which does not exist in the braced keyspace). The L-3 self-expiry stays the load-bearing safety property — a crashed holder's marker (and lease) lapse so `remove_job` is not blocked on a stale `EMQLOCK` for an unbounded window. PROPOSED forward: make the marker DEL **idempotent + return the prior held-state** so a release races cleanly with a reaper that already reclaimed (honest-row: report `released`/`already-gone`).

```text
v1 releaseLock-1                         v3 release (PROPOSED, holds emq.2.3-D5 / L-3)
KEYS[1]=lock                             marker = emq:{q}:job:<id>:lock   (presence flag, not the clock)
ARGV=[token, dur]                        lease  = the active-set score    (the real lease)
GET lock == token ?                      untrack_job(id):  DEL marker      (idempotent; [report released])
  DEL lock   (releases the lease)        lease release = active-score expiry / complete/4 (never DEL)
else 0                                   marker PX self-expires (≈2×lease) if the holder dies — L-3 self-heal
```

## Family: metrics-state

The v1 read family is six BullMQ-derived scripts that ask the queue how it is doing — counts by state, counts by priority band, throughput metrics, a single job's state, and a flow parent's child-state breakdown. Under the v2 laws the read plane is shipped as `EchoMQ.Metrics` (emq.2.1, `7d98ef86`) over the bus's four-set keyspace, with the flow-introspection slice on `EchoMQ.Flows` (emq.3.1/3.2). Two of the six have **no v2 port and no v3 lift** — `getCountsPerPriority` (the v1 `prioritized` ZSET retires under S-1/§6; priorities are per-group lanes) and the aggregate `getDependencyCounts` (its parts are split across `Flows`). The structural break across the whole family: v1 roots `prioritized`/state keys by string-concatenating `prefix .. ARGV[i]` (an **open concatenation off a data-shaped state name**), reads `meta.paused` to *pick which key to count*, and `getDependencyCounts` counts SETs (`SCARD`/`HLEN`) that v2 replaced with a STRING counter — so every v3 form is a re-derivation under declared-keys (A-1), not a port.

### getCounts-1

**v1 — purpose + mechanism.** Returns a count for each requested state name. `KEYS[1]` = `prefix`; `ARGV[1..]` = state names. For each name it builds `stateKey = prefix .. ARGV[i]` (**an open concatenation rooted in a data-shaped state name** — illegal under A-1), then dispatches by name: `wait`/`paused` → `LLEN` of a LIST with deprecated-marker peeking (`LINDEX -1`, RPOP the `"0:"` marker, subtract one), `active` → `LLEN`, everything else → `ZCARD`. Pure read with one incidental marker-cleanup RPOP.

**v2 status — PORTED.** `EchoMQ.Metrics.get_counts/3` (`metrics.ex:54`) with the inline `@counts` `Script.new(:counts, …)`. It declares the queue base as `KEYS[1]` (the slot root) and each set key at `KEYS[2..]`; set states (`pending`/`active`/`schedule`/`dead`) `ZCARD` their sorted set, metric states (`completed`/`failed`) `HGET … count` off `emq:{q}:metrics:<name>` (completion-deletes leave no set). `validate_states/1` rejects any name outside the closed `@set_states ∪ @metric_states` with `{:error, {:unknown_state, name}}`. There is no `wait`/`paused`-LIST/`prioritized`/`waiting-children` (emq.2.1-D3, design §6 closed registry).

**v3 — PROPOSED.** Keep the shipped closed-registry `@counts` verbatim; it is already declared-keys-clean and slot-sound (even a metric-only request pins `{q}` via the declared base). PROPOSED additions for BCS+EchoMesh: (1) a single round-trip multi-set **snapshot** so a dashboard reads all states atomically rather than racing per-state reads, and (2) an honest `as_of` field stamped from server `TIME` inside the script, so a mesh consumer reading a possibly-stale replica knows the read's own clock — the "staleness budget per surface" the EchoMesh manuscript makes explicit (mesh index, "Trading Consistency for Availability"). No open concatenation is reintroduced — every state name stays a closed-registry lookup.

**BCS relevance.** Per-state depth is exactly the queue-health row an operator dashboard reads (features emq.2 reframe).

**EchoMesh relevance.** Availability-first: a counts read is observational and stale-tolerant — it degrades, it does not refuse — so it sits on the availability axis ("always answering, staleness bounded"; served from the nearest replica per the architect view, `art82.md` "reads from the nearest replica").

```text
v1 getCounts-1                                  v3 (PROPOSED) Metrics @counts + snapshot
KEYS[1]=prefix; ARGV=state names                KEYS[1]=emq:{q}: base (slot root)
stateKey = prefix .. ARGV[i]  (open concat)     KEYS[2..]=declared set keys; ARGV=metric names
 wait/paused → LLEN + RPOP "0:" marker          set states  → ZCARD KEYS[i]
 active      → LLEN                             metric states → HGET base..'metrics:'..name 'count'
 else        → ZCARD                            closed registry; unknown name → {:error,{:unknown_state}}
returns {n, n, …}                               + PROPOSED one-shot snapshot + TIME as_of stamp
```

### getCountsPerPriority-4

**v1 — purpose + mechanism.** Returns a count per priority band. `KEYS[1..4]` = wait / paused / meta / prioritized keys; `ARGV[1..]` = priority values. For each priority: `0` → consult `isQueuePaused(KEYS[3])` (`HEXISTS meta paused`) and `LLEN` the **paused or wait** LIST accordingly (a key choice driven by a data read); non-zero → `ZCOUNT prioritized priority*0x100000000 .. (priority+1)*0x100000000-1` over the 64-bit packed priority+timestamp score.

**v2 status — NOT YET (retired by design).** There is **no `prioritized` set** in the bus and no per-priority count verb. The v1 `prioritized` ZSET and `addPrioritizedJob` retire under S-1/§6: the v2 `pending` set is a score-0 ZSET where mint order *is* the order theorem (features `addPrioritizedJob-7.lua` row — "folded… priority lanes are `EchoMQ.Lanes`"). Priority is expressed as **per-group fair lanes**, not a packed-score band.

**v3 — PROPOSED.** Re-derive the *intent* (depth behind a priority class) as **per-lane depth**: `EchoMQ.Metrics.lane_depths/3` (`metrics.ex:297`) already returns a count per group over `emq:{q}:g:<group>:pending`, each group id gated by `BrandedId.valid?/1` before the wire and the lane key derived in-script from the declared base (`base..'g:'..g..':pending'`). For an intra-lane priority dimension, the roadmap's lane-priority is a non-zero score on that same `g:<group>:pending` ZSET (features §lanes, "intra-group priority… no new key family") — so a per-priority count becomes a `ZCOUNT` over a score *window* on the lane set, declared-keys-clean, never the v1 64-bit-packed `prioritized` band and never a `meta.paused` branch that picks the key.

**BCS relevance.** Per-lane backlog is the fair-lane / per-player depth the bus reads to balance work across lane groups.

**EchoMesh relevance.** Availability-first: per-segment (per-player lane) depth is an observational read; it places on the availability axis like the other counts.

```text
v1 getCountsPerPriority-4                        v3 (PROPOSED) Metrics.lane_depths/3
KEYS=wait,paused,meta,prioritized; ARGV=prios    KEYS[1]=base; ARGV=base + group ids (branded-gated)
 p==0 → isQueuePaused(meta)? LLEN paused : wait  per group g:
 p!=0 → ZCOUNT prioritized                         ZCARD base..'g:'..g..':pending'
        p*2^32 .. (p+1)*2^32-1   (packed band)   (PROPOSED intra-lane priority = ZCOUNT score-window
returns counts; key choice from a data read)      on the same lane ZSET — no prioritized set, no meta branch)
```

### getMetrics-2

**v1 — purpose + mechanism.** Returns the throughput metrics block. `KEYS[1]` = metrics key, `KEYS[2]` = metrics-data key; `ARGV[1..2]` = a slice `[start,end]`. It `HMGET`s `count`/`prevTS`/`prevCount` from the metrics hash, `LRANGE`s the data series for the requested window, `LLEN`s the series length, and returns `{metrics, data, numPoints}`. Pure read; both keys are passed in `KEYS[]` (this one is already declared-keys-shaped in v1).

**v2 status — PARTIAL.** `EchoMQ.Metrics.get_metrics/3` (`metrics.ex:173`) reads the terminal-outcome counter at `emq:{q}:metrics:completed`/`:failed` — the `count` field plus the `:data` series `LLEN`. The counter write rides the *existing* terminal transitions (`@complete`/`@retry` each `HINCRBY` once — `jobs.ex:169`/`:206`), so a metric read is never a phantom. **Gap:** the time-series `:data` ring is unwritten this rung, so the verb honestly answers `data_points: 0`; the Prometheus *format* wrapper (`export_prometheus_metrics`) is deferred to **emq.8** (the telemetry contract, ADR-2 two-layer split; features lines 306, 372).

**v3 — PROPOSED.** Keep the honest counter read. PROPOSED to close the gap: write the `metrics:<which>:data` series as a bounded ring on the same terminal transitions (the moduledoc's stated "series is unwritten this rung"), trimmed by count/age the way `trimEvents`/`removeJobsByMaxCount` bound other structures — so the v1 `{metrics, data, numPoints}` slice read is fully re-derivable. The Prometheus/OpenTelemetry **format** wrapper stays emq.8 (the raw read is the floor; the contract is separate). The live `:telemetry` surface for the same lifecycle counts already ships as `EchoMQ.Meter` (`[:emq, :job, :complete|:fail]`, zero-cost when `:telemetry` is absent).

**BCS relevance.** Completed/failed throughput is the capacity/SLO signal a consumer's capacity dashboard reads over the bus.

**EchoMesh relevance.** Availability-first: a metered observation surface — it is read off the side, never on the state-of-record write path, so a stale or absent metric degrades the dashboard, it never blocks the write path.

```text
v1 getMetrics-2                                  v3 (PROPOSED) Metrics.get_metrics/3 + data ring
KEYS[1]=metrics, KEYS[2]=data; ARGV=start,end    hash = emq:{q}:metrics:<which>
HMGET count,prevTS,prevCount                     data = emq:{q}:metrics:<which>:data
LRANGE data start..end ; LLEN data               HGET hash 'count'  ; LLEN data  (now → 0, honest)
return {metrics, data, numPoints}                count rides @complete/@retry HINCRBY (no phantom)
                                                 PROPOSED: bounded :data ring + slice read; Prom fmt = emq.8
```

### getState-8

**v1 — purpose + mechanism.** Returns a single job's state. `KEYS[1..8]` = completed/failed/delayed/active/wait/paused/waiting-children/prioritized; `ARGV[1]` = job id. It probes in order: `ZSCORE` completed/failed/delayed/prioritized; then `LRANGE` the active/wait/paused **LISTs** and `checkItemInList` (an O(n) linear scan of the whole list); then `ZSCORE` waiting-children; else `"unknown"`. Eight keys, but the LIST membership is a full-range scan.

**v2 status — PORTED.** `EchoMQ.Metrics.get_job_state/3` (`metrics.ex:148`) with the inline `@state_lookup`. It declares the four set keys (`pending`/`active`/`schedule`/`dead`) + the job row key, probes each set by `ZSCORE` (no LIST scan — all four states are ZSETs), then a **row-field branch** (emq.3.1-D4): if the row's `state` field is `awaiting_children` it returns that (a flow parent held out of every set), if the row exists otherwise it returns `unknown` (in-flight between transitions), else `absent`. The id is gated at `Keyspace.job_key/2`, and the wire string is mapped through the closed `@lookup_states` table (not `to_existing_atom`) — the honest-row guard.

**v3 — PROPOSED.** Keep the shipped four-set + row-field probe; it is already the state-of-the-art form (declared keys, no scan, branded-gated, closed result table). The only PROPOSED carry-forward is honesty under the EchoMesh segment: when the read is served on a non-authoritative replica, return the verdict with the owning node's slot identity / `as_of` so a consumer can tell a strongly-consistent state read from a possibly-stale one — the manuscript's per-surface staleness contract. No v1 LIST scan, no eight-key sprawl: the four-ZSET keyspace makes the membership probe O(log n) and the result set closed.

**BCS relevance.** A runbook reads a job's state before any mutate (the read that gates a remove/reprocess); the `awaiting_children` verdict is exactly the flow-parent state a multi-leg BCS saga inspects.

**EchoMesh relevance.** Consistency-first: a single branded id's state is a state-of-record read — it sits on the strong-consistency axis (the consistency-first surface "refuses rather than risk a second writer", `art82.md`), the opposite dial from counts/metrics.

```text
v1 getState-8                                    v3 (PROPOSED, = shipped get_job_state/3)
KEYS[1..8] 8 sets/lists; ARGV[1]=id              KEYS[1..4]=pending/active/schedule/dead; KEYS[5]=row
ZSCORE completed/failed/delayed/prioritized      ZSCORE each of the 4 sets → state
LRANGE active/wait/paused + checkItemInList      HGET row 'state':
  (O(n) full LIST scan)                            'awaiting_children' → that ; else row? → unknown
ZSCORE waiting-children ; else 'unknown'           else → absent
                                                 id gated at job_key; result via closed @lookup_states
                                                 PROPOSED: + owning-slot/as_of honesty on a replica read
```

### getStateV2-8

**v1 — purpose + mechanism.** The newer-Valkey variant of `getState`: same 8 keys + job id, but the active/wait/paused membership uses `LPOS KEYS[n] ARGV[1]` (a single server-side list-position probe) instead of `LRANGE`+host scan. Functionally identical output to `getState`; only the LIST-membership mechanism is cheaper.

**v2 status — PORTED (subsumed).** No separate verb — `EchoMQ.Metrics.get_job_state/3` is the one canonical state read. The v1 `getState`-vs-`getStateV2` split exists *only because v1 keeps wait/paused/active as LISTs* (so it needs either a scan or `LPOS`). The bus has **no wait/paused/active LISTs** — all four states are ZSETs probed by `ZSCORE` (`@state_lookup`) — so the entire LIST-membership question, and with it the v1/v2 variant distinction, **collapses**.

**v3 — PROPOSED.** No standalone command. The v3 form is identical to `getState`'s `get_job_state/3`; the variant is moot because the v2 keyspace eliminated the LIST. PROPOSED only the same replica-honesty carry as `getState`. Re-introducing a `V2` would violate "one canonical surface" — there is one state read, full stop.

**BCS relevance.** Same as `getState` — the single canonical state read a BCS runbook/saga consults.

**EchoMesh relevance.** Consistency-first: the same single-id state-of-record read; the variant collapses into it.

```text
v1 getStateV2-8                                  v3 (PROPOSED): subsumed — no separate verb
KEYS[1..8]; ARGV[1]=id                           the v2 keyspace has NO wait/paused/active LIST
ZSCORE completed/failed/delayed/prioritized      → all four states are ZSETs (ZSCORE)
LPOS active/wait/paused  (cheaper than LRANGE)   → the LIST-membership question disappears
ZSCORE waiting-children ; else 'unknown'         → ONE get_job_state/3 ; getState & getStateV2 merge
```

### getDependencyCounts-4

**v1 — purpose + mechanism.** Returns a count per child state for a flow parent. `KEYS[1..4]` = processed / unprocessed / ignored / failed keys; `ARGV[1..]` = child-state names. For each name: `processed` → `HLEN` (a HASH of completed children + results), `unprocessed` → `SCARD` (a **SET** of pending child keys), `ignored` → `HLEN`, else `failed` → `ZCARD`. Four child-state structures, two of them SETs/HASHes of *child keys* — the shape v2 deliberately replaced.

**v2 status — PARTIAL (split, not aggregated).** There is no single aggregate `getDependencyCounts` verb; its pieces are split across `EchoMQ.Flows`: the outstanding-count is `Flows.dependencies/3` (`flows.ex:329`) — a `GET` of the `:dependencies` **STRING counter** (Fork R2.A: v1's pending-child SET became a counter, so the *count* is the only shape it yields; `{:ok, 0}` sentinel), explicitly parity of v1 `get_dependencies_count`, **not** `get_dependencies` (the "which children remain" SET roster). `processed` is read by `Flows.children_values/3` (`HGETALL` of `:processed`); the ignored-on-failure failures by `Flows.ignored_failures/3` (the `:failed`/`:unsuccessful` subkey). The `unprocessed` SET has no v2 analogue — it is implied by the counter, not enumerated.

**v3 — PROPOSED.** A `Flows.child_counts/3` re-derivation that composes, on the parent's `{q}` slot, the declared `:dependencies` counter (outstanding) + `HLEN` of `:processed` (done) + the `:failed`/`:unsuccessful` count (ignored-failures) into one read — every key declared in `KEYS[]` or composed `<> ":dependencies"`/`":processed"` from the gated parent `Keyspace.job_key/2` (the already-registered §6 subkeys; the `parent` data field is read **host-side**, never as a Lua key — the v1 `parent_key`/SET-of-child-keys form is structurally inexpressible under A-1). It reports `processed`/`outstanding`/`ignored_failures` honestly; it does **not** resurrect `unprocessed` as a SET cardinality (the counter is the source of truth) — an enumerated child roster, if BCS needs it, is the separate `get_dependencies`-analogue (Fork R2.B), explicitly out of scope of the count.

**BCS relevance.** Fan-in progress (how many children remain, how many succeeded/failed) is exactly what a BCS multi-leg order / saga parent reads before it proceeds or compensates.

**EchoMesh relevance.** Consistency-first: a flow parent's child-state read is a correctness read on the state-of-record axis — the parent must not proceed on a stale count, so it places on the strong-consistency dial, never the available-stale one.

```text
v1 getDependencyCounts-4                          v3 (PROPOSED) Flows.child_counts/3 (compose existing)
KEYS=processed,unprocessed,ignored,failed         parent_id gated at Keyspace.job_key/2 (branded)
ARGV=child-state names                            outstanding = GET  job:<p>:dependencies  (STRING ctr)
 processed   → HLEN  (hash of results)            processed   = HLEN  job:<p>:processed
 unprocessed → SCARD (SET of child keys)          ignored_fail= count job:<p>:failed/:unsuccessful
 ignored     → HLEN                               keys declared / composed from gated parent slot
 failed      → ZCARD                              NO unprocessed SET (counter is source of truth;
returns counts (SET/HASH of child KEYS)            child roster = separate get_dependencies, Fork R2.B)
```

## Family: introspect-read

This family is the **read plane** of v1 — the pure-read introspection verbs (ranges, rate-limit TTL, concurrency-ceiling, finished-check, list-membership, paginated scan). Two of the six are PORTED verbatim-in-spirit to `EchoMQ.Metrics` (emq.2.1); the other four are **RE-AIMED, not lifted** — each v1 form reads or paginates over a BullMQ state structure (a per-state `wait`/`paused`/`completed`/`failed` LIST/ZSET, or a SET/HASH page) that the v2 closed `type` registry (design §6) **deliberately does not have**: the bus is four sorted sets (`pending`/`active`/`schedule`/`dead`) + completion-deletes (no `completed`/`failed` set) + a branded-id-ordered `pending` (the order theorem: byte order = mint order, REV BYLEX browse, no second index). So every v3 form is a re-derivation under the v2 laws, evolved toward the stream tier (emq3.specs.md) that BCS + EchoMesh actually demand.

### getRanges-1

**v1 — purpose + mechanism.** Returns job-ids per requested states over a `[start,end]` window. `KEYS[1]`=prefix; `ARGV[1..3]`=start/end/asc, `ARGV[4..]`=state names. For `wait`/`paused`/`active` it `LRANGE`s the LIST (`prefix..state`), v6-marker-aware (pops a `0:`-prefixed marker); for the rest it `ZRANGE`/`ZREVRANGE`s the ZSET. **The v3-illegal form:** the state key is built by **concatenating a data-supplied state name onto the prefix** (`prefix .. ARGV[i]`) — an open concatenation, not a declared key; and it reads v1 state structures (wait LIST + prioritized ZSET) the v2 §6 registry retires.

**v2 status — NOT YET.** No `get_ranges` exists (grep: no `def get_ranges`). The closest as-built surface is `EchoMQ.Jobs.browse/3` (REV BYLEX over `pending`) + `EchoMQ.Metrics.get_counts/3` (per-state ZCARD). The structural gap is by design: design §6 retires the v1 `wait`/`paused`/`prioritized` types and completion-deletes leave no `completed`/`failed` set, so a per-state range over those does not exist.

**v3 — PROPOSED.** Re-derive as a windowed per-state browse over the **four as-built sets** under the v2 laws: `pending` via the order-theorem REV BYLEX (no second index), `active`/`schedule`/`dead` via `ZRANGE`/`ZREVRANGE`. One inline `Script.new/2`, **every set key in KEYS[]** (A-1 declared-keys; the open `prefix..ARGV[i]` concatenation is replaced by an enumerated, registry-closed set of declared KEYS[n]); branded ids gated at `Keyspace.job_key/2`. Forward of parity, the canonical windowed read becomes `XRANGE` over mint-instant bounds on the stream tier (emq3.6 time-travel — "branded mint instants map straight to `XRANGE` bounds").

```text
v1 (illegal to lift)                         v3 (PROPOSED, declared-keys)
KEYS[1]=prefix; ARGV=start,end,asc,types…    KEYS=[pending, active, schedule, dead]  (enumerated, §6-closed)
stateKey = prefix .. ARGV[i]   ← DATA-VALUE  pending: ZRANGE k '+' '-' BYLEX REV LIMIT 0 n  (order theorem)
LRANGE/ZRANGE/ZREVRANGE per v1 state         active/schedule/dead: ZRANGE/ZREVRANGE k start end
wait/paused LISTs + v6 markers               (no wait/paused/completed/failed/prioritized — §6 retires them)
                                             v3-forward: XRANGE <minId>-<maxId> over the stream tier (emq3.6)
```

### getRateLimitTtl-2

**v1 — purpose + mechanism.** Remaining limiter TTL in ms. `KEYS[1]`=limiter, `KEYS[2]`=meta; `ARGV[1]`=maxJobs. Calls `getRateLimitTTL(max, limiterKey)` (include): if `max <= GET limiter`, returns `PTTL limiter` (deleting it at pttl 0); when `maxJobs="0"` it reads `max` from `HGET meta max`. Both key operands are in `KEYS[]` here — this one is structurally lift-able (no data-value key root).

**v2 status — PORTED.** `EchoMQ.Metrics.get_rate_limit_ttl/3`, inline `@rate_ttl Script.new(:rate_ttl, …)` (metrics.ex:201-229, emq.2.1-D6). Declared KEYS=`[queue_key(q,"limiter"), queue_key(q,"meta")]`; the script reads `max` from meta when `ARGV[1]`=0, compares to `GET limiter`, returns `PTTL` when positive. Features catalog row: `getRateLimitTtl-2.lua → metrics.ex get_rate_limit_ttl/3 ✅`.

**v3 — PROPOSED.** Hold as-shipped — the v2 form already satisfies braced keyspace + declared-keys + honest-row. Forward, extend the same read to the **per-group/per-player** limiter window (the `EMQRATE`-class temporal-fairness knob over `EchoMQ.Lanes`, features.md §Scope) so EchoMesh can read the reopen-time of a per-lane rate window, not just the queue-global one.

```text
v1                                            v3 (PROPOSED — already PORTED, hold)
KEYS=[limiter, meta]; ARGV=maxJobs            keys=[queue_key(q,"limiter"), queue_key(q,"meta")]  (braced, slot-sound)
max = maxJobs==0 ? HGET meta max : maxJobs    @rate_ttl: max = ARGV[1]==0 ? HGET KEYS[2] 'max' : ARGV[1]
if max<=GET limiter: return PTTL limiter       if max>0 and max<=GET KEYS[1]: pttl=PTTL KEYS[1]; pttl>0 → return
                                              v3-forward: same read over a per-group limiter window (EMQRATE)
```

### isMaxed-2

**v1 — purpose + mechanism.** Boolean: is the queue at its concurrency ceiling. `KEYS[1]`=meta, `KEYS[2]`=active; calls `isQueueMaxed(meta, active)` (include): `HGET meta concurrency`, and if `LLEN active >= concurrency` returns `true`. Keys are both declared — lift-able, but the **active structure is a LIST** in v1 (vs a sorted set in v2) and the return is a bare boolean rather than a typed wire reply.

**v2 status — PORTED.** `EchoMQ.Metrics.is_maxed/2`, inline `@is_maxed` (metrics.ex:244-268, emq.2.1-D6). A **read-and-refuse**: `tonumber(HGET KEYS[1] 'concurrency')`, and if `ZCARD KEYS[2] >= cap` it `redis.error_reply('EMQRATE at concurrency ceiling')` → mapped to `{:error, :rate}`; else `:ok`. Declared KEYS=`[queue_key(q,"meta"), queue_key(q,"active")]`. Features row: `isMaxed-2.lua → is_maxed/2 (the read-and-refuse, EMQRATE) ✅`. The conformance set proves it (`rate`/`limit` scenarios).

**v3 — PROPOSED.** Hold as-shipped — v2 evolves the v1 boolean into the typed `EMQRATE` wire refusal (design §5 additive minor, in the closed wire-class registry with EMQKIND/EMQSTALE/EMQLOCK/EMQSTATE), the consult-before-claim contract (conformance: "at the ceiling is_maxed refuses and a skipping claimer leaves active at the ceiling"). Forward, the same gate is carried to per-lane ceilings across mesh nodes (`EchoMQ.Lanes`).

```text
v1                                            v3 (PROPOSED — already PORTED, hold)
KEYS=[meta, active]                           keys=[queue_key(q,"meta"), queue_key(q,"active")]
cap = HGET meta concurrency                   cap = tonumber(HGET KEYS[1] 'concurrency' or '0')
LLEN active >= cap  → return true (boolean)   ZCARD KEYS[2] >= cap → error_reply('EMQRATE …') → {:error,:rate}
                                              else 0 → :ok        (active is a SORTED SET, not a LIST)
```

### isFinished-3

**v1 — purpose + mechanism.** Is a job finished. `KEYS[1]`=completed, `KEYS[2]`=failed, `KEYS[3]`=job key; `ARGV[1]`=job id, `ARGV[2]`=return-value flag. `EXISTS job key` else `-1`; `ZSCORE completed id` → 1 (+ `HGET job returnvalue`); `ZSCORE failed id` → 2 (+ `HGET job failedReason`); else 0. The "finished" universe is the two terminal **sets** `completed`+`failed` — sets the v2 bus does not keep.

**v2 status — PARTIAL.** No `is_finished` (grep: no `def is_finished`). Subsumed by `EchoMQ.Metrics.get_job_state/3` (inline `@state_lookup`, metrics.ex:107-162), which answers `:pending`/`:active`/`:scheduled`/`:dead`/`:awaiting_children`/`:unknown`/`:absent` by which set holds the id (with the emq.3.1 row-field branch). **The gap:** there is no `completed` set — completion-deletes (design §6) remove the row — so v1's binary completed/failed cannot be reproduced; only `:dead` (the morgue) is retained, and "completed" is a `metrics:completed` throughput count, not a per-id lookup.

**v3 — PROPOSED.** A thin `finished?/3` derived over `get_job_state/3`: `:dead` is the bus's only retained terminal state, `:absent` answers a vanished completion. Declared KEYS=four sets + the row; branded id gated at `Keyspace.job_key/2` (raises before any wire). Forward, durable per-job finished-history (which completion-deletes drop) is recovered by **terminal-outcome replay off the stream tier** (emq3.3 journal-fold parity, emq3.5 archive) — the right home for "was this finished and how", because the live bus is intentionally amnesiac about success.

```text
v1                                            v3 (PROPOSED — re-aim over get_job_state)
KEYS=[completed, failed, job]; ARGV=id,rv?    keys = four sets ++ [job_key(q,id)]   (declared, branded-gated)
EXISTS job? else -1                           @state_lookup: ZSCORE pending/active/schedule/dead id
ZSCORE completed id → 1 (+returnvalue)        → :dead  = the ONLY retained terminal state (completion-deletes)
ZSCORE failed id    → 2 (+failedReason)       → :absent = vanished/never-was; success → metrics:completed count
else 0                                        v3-forward: durable finished-history = stream replay (emq3.3/3.5)
```

### isJobInList-1

**v1 — purpose + mechanism.** Is an id a member of a given LIST. `KEYS[1]`=list; `ARGV[1]`=id. `LRANGE KEYS[1] 0 -1` (pull the whole list), then `checkItemInList` (include) does a **linear scan** returning 1/nil. The membership universe is a v1 LIST; the check is O(n).

**v2 status — NOT YET.** No `in_list` exists (grep: no `def in_list`/`def is_job_in`). The bus has no membership LISTs — `pending` is a sorted set drained by `ZPOPMIN`, not an `LRANGE`-scanned list — so the v1 mechanism has no structure to run against.

**v3 — PROPOSED.** Re-derive as **O(log n) sorted-set membership** rather than a linear list scan: a declared-key `ZSCORE` over the relevant set (the exact mechanism `@state_lookup` already uses for the four sets). One declared KEYS[n] root; branded id gated at the key builder. This is strictly better than v1: the order theorem means the set is mint-ordered and membership is logarithmic, never an `LRANGE 0 -1` pull.

```text
v1                                            v3 (PROPOSED — set membership, not list scan)
KEYS=[list]; ARGV=id                          KEYS=[<one declared set key>]; ARGV=id  (branded-gated)
items = LRANGE list 0 -1   ← pulls whole list if redis.call('ZSCORE', KEYS[1], id) then return 1 end
linear checkItemInList(items, id) → 1/nil     return 0          (O(log n), mint-ordered — order theorem)
```

### paginate-1

**v1 — purpose + mechanism.** A stable-cursor page of a **set or hash**. `KEYS[1]`=the set/hash; `ARGV[1..6]`=page start/end/cursor/offset/maxIterations/fetch-jobs. `TYPE` switches `SSCAN`+`SCARD` (set) vs `HSCAN`+`HLEN` (hash); `findPage` (include) iterates the cursor, optionally `HGETALL`-fetching each member's job hash. Its own header **warns the pagination is unstable** because sets are not order-preserving — the exact weakness v2's mint-order browse removes.

**v2 status — NOT YET.** No `paginate` exists (grep: no `def paginate`). The as-built listing path is `EchoMQ.Jobs.browse/3` (REV BYLEX `LIMIT` over `pending`) + `pending_size/3` (`ZCARD`) — a sorted-set window, **stable by construction** (mint order), not an `SSCAN`/`HSCAN` cursor.

**v3 — PROPOSED.** The bus's primary listing is already the **order-theorem browse** (REV BYLEX, stable because mint-ordered — directly answering v1's instability warning). For genuinely set/hash-shaped reads (e.g. paging the `de:*` dedup space or a `meta` hash), a declared-key `HSCAN`/`SSCAN` cursor scoped under the slot. **The canonical v3 paginated read is the stream tier:** `XRANGE`/`XAUTOCLAIM` cursors where the **stream entry-id IS the cursor** (mint-ordered, emq3.1/3.6) — this is what a stream-replay consumer (recorded-runs, event replay) would demand, bounded by `MAXLEN`/`MINID` retention (emq3.4).

```text
v1 (unstable, by its own warning)            v3 (PROPOSED — stable cursor)
KEYS=[set|hash]; ARGV=start,end,cursor,…     primary: Jobs.browse — ZRANGE k '+' '-' BYLEX REV LIMIT 0 n
TYPE → SSCAN+SCARD | HSCAN+HLEN              (mint-ordered ⇒ STABLE; v1's "sets not order-preserving" gone)
findPage: cursor loop, optional HGETALL      set/hash reads: declared-key HSCAN/SSCAN under the slot
"pagination is not stable" (header warning)  v3-forward: XRANGE/XAUTOCLAIM — entry-id IS the cursor (emq3.1/3.6),
                                             retention-bounded MAXLEN/MINID (emq3.4)
```

## Family: data-progress-log

This family is the **job-row mutation surface** — the four BullMQ-derived scripts that write back onto an existing job's hash (its `data`, `progress`, `logs`, and failure record) after the job is in flight. All four are guarded by the same `EXISTS KEYS[1]` job-row check and return `-1` on a missing job. Three are **PORTED** to `EchoMQ.Jobs` (emq.2.2, the operator plane); the fourth (`saveStacktrace`) has **no dedicated port** — its capability is folded into the v2 morgue's single `last_error` field on the `@retry` dead-letter arm.

### updateData-1

**v1 purpose + mechanism.** Replace a job's `data` blob. `KEYS[1]` = the job-id hash key; `ARGV[1]` = the new data. If the row exists, `HSET KEYS[1] "data" ARGV[1]` and return `0`, else return `-1` (missing job). One declared key, one field write, no set move. Note: `KEYS[1]` is a *fully-formed* job key passed in by the host — not data-value-rooted — so this script is one of the few v1 forms that is *already* shape-legal under declared-keys (the field name `"data"` is the only thing that changes in v3).

**v2 status — PORTED.** `EchoMQ.Jobs.update_data/4` (`jobs.ex:702`) over the inline `@update_data Script.new(:update_data, …)` (`jobs.ex:690`): `if EXISTS KEYS[1] == 0 then return -1`, else `HSET KEYS[1] 'payload' ARGV[1]; return 1`. The v1 `data` field is renamed to the as-built `payload`; the missing-job sentinel maps `-1 → {:error, :gone}`. The id is gated at `Keyspace.job_key/2` (raises on an ill-formed id, INV5). Confirmed by `emq.features.md` Part B.2 (`updateData-1.lua` row, line 343).

**v3 PROPOSED.** Keep the emq.2.2 form verbatim — it already satisfies every v2 law: one `KEYS[1]` declared, the branded id gated at the key builder, `payload` (not `data`) on the three-field row. The forward evolution BCS + EchoMesh add is the **immutability discipline at the stream tier** (emq3.2, PROPOSED): for jobs whose result becomes a retained, replayable stream record, a payload mutation should be modeled as a new appended fact rather than an in-place `HSET`, so a fold-to-state replay reconstructs the true history. For the queue-tier job row, in-place replace stays correct (the row is mutable working state, not a logged event).

```text
v1 (updateData-1.lua)            │ v3 PROPOSED (EchoMQ.Jobs.update_data/4)
─────────────────────────────────┼──────────────────────────────────────────
KEYS[1] = job id key             │ KEYS[1] = Keyspace.job_key(q, id)  -- gated
ARGV[1] = data                   │ ARGV[1] = payload
if EXISTS KEYS[1]==1:            │ if EXISTS KEYS[1]==0: return -1   -- {:error,:gone}
  HSET KEYS[1] "data" ARGV[1]    │ HSET KEYS[1] 'payload' ARGV[1]
  return 0                       │ return 1                          -- :ok
else return -1                   │ (stream-tier: append, don't replace — emq3.2)
```

### updateProgress-3

**v1 purpose + mechanism.** Write a job's `progress` and emit a `progress` event. `KEYS[1]` = job-id key, `KEYS[2]` = the **event stream key**, `KEYS[3]` = the **meta key**; `ARGV[1]` = id, `ARGV[2]` = progress. If the row exists: `getOrSetMaxEvents(KEYS[3])` reads `opts.maxLenEvents` from the meta hash (defaulting/writing back `10000`), then `HSET KEYS[1] "progress" ARGV[2]` and `XADD KEYS[2] MAXLEN ~ <maxEvents> * event progress jobId ARGV[1] data ARGV[2]`, return `0`; else `-1`. The maxLen ceiling is read from a *meta hash field* — a data-value read for a script parameter, exactly the v1 idiom v3 must not lift as a key operand.

**v2 status — PORTED.** `EchoMQ.Jobs.update_progress/4` (`jobs.ex:736`) over `@update_progress` (`jobs.ex:710`): `HSET KEYS[1] 'progress' ARGV[1]`, then `PUBLISH ARGV[3]..'events'` a `cjson`-encoded `{event='progress', job=ARGV[2], progress=ARGV[1]}`, return `1`/`-1`. The host passes `argv = [progress, job_id, Keyspace.queue_key(queue, "")]` (line 738). The defining v2 change: it is a connector **`PUBLISH`** onto the per-queue events channel `emq:{q}:events`, **not** an `XADD` to a capped stream — the locked emq.2.2-D6/D-5 progress-event contract. The event name rides the payload's `event` field (one channel per queue, dispatched by `EchoMQ.Events` at emq.2.3). Confirmed by `emq.features.md` Part B.2 (line 344) and `emq.design.md` §ADR-4.

**v3 PROPOSED.** Keep the field-write + registered-event form. The v1 `XADD … MAXLEN ~ <maxEvents>` machinery (and its `getOrSetMaxEvents` meta read) is deliberately **not** reproduced: v2 collapsed the per-job progress stream into a pub/sub PUBLISH whose channel derives from the *declared* queue base root — a channel is not a slot-routed key, so it adds no §6 key type and no new transport (rides the existing RESP3 pub/sub seam). The forward layer BCS + EchoMesh want is the emq3.2 stream tier (PROPOSED): where a durable, replayable progress *log* is genuinely needed (audit, time-travel), it lands as branded-id stream records on the certified wire under declared retention — not as the v1 ad-hoc per-queue `XADD` with a meta-hash maxLen. The transient progress *signal* stays a PUBLISH.

```text
v1 (updateProgress-3.lua)              │ v3 PROPOSED (EchoMQ.Jobs.update_progress/4)
────────────────────────────────────────┼──────────────────────────────────────────────
KEYS[1] job, KEYS[2] stream, KEYS[3] meta│ KEYS[1] = Keyspace.job_key(q, id)  -- one declared key
maxEvents = HGET meta "opts.maxLenEvents"│ (no meta maxLen read — channel from declared queue root)
  (data-value read for the cap)          │ ARGV = [progress, id, queue_key(q,"")]
HSET job "progress" ARGV[2]              │ HSET KEYS[1] 'progress' ARGV[1]
XADD stream MAXLEN ~ maxEvents * …       │ PUBLISH ARGV[3]..'events'
  event progress jobId .. data ..        │   cjson{event='progress',job=…,progress=…}
return 0 / -1                            │ return 1 / -1   ({:ok}/{:error,:gone})
                                         │ (durable replay → emq3.2 stream tier, PROPOSED)
```

### addLog-2

**v1 purpose + mechanism.** Append a line to a job's logs. `KEYS[1]` = job-id key, `KEYS[2]` = the **job logs key** (a list); `ARGV[1]` = id, `ARGV[2]` = log, `ARGV[3]` = keepLogs. If the row exists: `RPUSH KEYS[2] ARGV[2]` to get the count; if `keepLogs` is non-empty, `LTRIM KEYS[2] -keepLogs -1` and return `min(keepLogs, count)`; else return `count`; missing job → `-1`. Both keys are fully-formed and passed by the host (the logs key is a *separately-passed* operand, not derived in-script from a data value), so the shape is legal — but in v3 the logs key is *derived* from the declared row key, tightening it.

**v2 status — PORTED.** `EchoMQ.Jobs.add_log/5` (`jobs.ex:766`) + `get_job_logs/3` (`jobs.ex:784`) over `@add_log` (`jobs.ex:747`): `RPUSH KEYS[2] ARGV[1]`; if `ARGV[2] ~= ''` then `LTRIM KEYS[2] -keep -1` and return `keep` when `keep < count`, else `count`; missing → `-1`. The host derives both keys co-located: `keys = [Keyspace.job_key(q, id), Keyspace.job_key(q, id) <> ":logs"]` (line 768) — the §6 `:logs` subkey. `add_log/5` returns `{:ok, n}`/`{:error, :gone}`; `get_job_logs/3` `LRANGE`s it. Confirmed by `emq.features.md` Part B.2 (line 345).

**v3 PROPOSED.** Keep the emq.2.2 form — it is already the model A-1-clean re-derivation: instead of the v1 *separately-passed* `KEYS[2]`, the logs list key is **derived from the declared row key** (`job_key(q,id) <> ":logs"`), so it provably shares the braced `{q}` slot (slot-soundness discharged by the grammar — `emq.design.md` §S-1 / the co-location law). Both keys declared; keep-N trim and honest count preserved. The forward addition BCS + EchoMesh want is retention-as-policy for the trimmed-away lines (emq3.4/3.5, PROPOSED): the `:logs` keep-N is a per-job staleness budget; deep history that must survive box-loss folds to the `EchoStore.Graft` archive (local CubDB → Tigris) rather than being silently `LTRIM`med to nothing.

```text
v1 (addLog-2.lua)                  │ v3 PROPOSED (EchoMQ.Jobs.add_log/5)
─────────────────────────────────────┼──────────────────────────────────────────────
KEYS[1] job, KEYS[2] logs (passed)   │ KEYS = [job_key(q,id), job_key(q,id)..":logs"]
ARGV = [id, log, keepLogs]           │   -- logs DERIVED from the declared row → slot-sound
count = RPUSH KEYS[2] log            │ count = RPUSH KEYS[2] ARGV[1]
if keepLogs != '':                   │ if ARGV[2] != '':
  LTRIM KEYS[2] -keepLogs -1         │   LTRIM KEYS[2] -keep -1
  return min(keepLogs, count)        │   if keep < count then return keep end
return count                         │ return count            -- {:ok, n} / {:error,:gone}
(missing → -1)                       │ (trimmed history → emq3.5 archive, PROPOSED)
```

### saveStacktrace-1

**v1 purpose + mechanism.** Persist a failure record. `KEYS[1]` = job key; `ARGV[1]` = stacktrace, `ARGV[2]` = failedReason. If the row exists: `HMSET KEYS[1] "stacktrace" ARGV[1] "failedReason" ARGV[2]`, return `0`; else `-1`. One declared key, two fields, no set move — shape-legal as-is, but it captures a *richer* failure record (a separate stacktrace blob + a human reason) than the v2 line currently keeps.

**v2 status — NOT YET (capability folded, no dedicated port).** There is **no** `save_stacktrace` function or `@save_stacktrace` script in `echo_mq` (grep of `lib/` confirms). The failure record in v2 is a single `last_error` STRING field on the job row, written by `@retry`'s dead-letter arm — `HSET KEYS[4] 'last_error' ARGV[5]` (`jobs.ex:281`) — and cleared by `reprocess_job/3` (`HDEL jk 'last_error'`, `jobs.ex:862`). The conformance morgue scenarios assert `HGET … last_error` (`conformance.ex:302,321,473,813,862`). So v1's two-field `{stacktrace, failedReason}` is collapsed to one `last_error` and is written **only on the dead-letter transition**, never as a standalone host-callable verb. (`saveStacktrace-1.lua` has no row in `emq.features.md` Part B.2's per-script table — an honest gap surfaced by this matrix.)

**v3 PROPOSED.** Re-derive a dedicated `@save_stacktrace` under the v2 laws to close the morgue-detail gap: one declared `KEYS[1]` = `Keyspace.job_key(q, id)` (gated), writing **separate `stacktrace` + `failed_reason` row fields beside the existing `last_error`** (keeping `last_error` as the terse browse summary the conformance set already reads), server-clock-stamped at the failure instant via `TIME` where the dead-letter occurs. It is the natural companion to the proposed emq.3.4 failure-policy work (`fail_parent_on_failure`): a flow that fails a parent on a dead child should carry the child's full stacktrace, not just `last_error`. Mark this a small forward rung — there is no v1 form to lift, only a capability to re-author A-1-clean.

```text
v1 (saveStacktrace-1.lua)            │ v3 PROPOSED (@save_stacktrace — re-derived)
───────────────────────────────────────┼──────────────────────────────────────────────
KEYS[1] = job key                      │ KEYS[1] = Keyspace.job_key(q, id)   -- gated, declared
ARGV[1] stacktrace, ARGV[2] reason     │ ARGV = [stacktrace, failed_reason]
if EXISTS KEYS[1]==1:                  │ if EXISTS KEYS[1]==0: return -1     -- {:error,:gone}
  HMSET KEYS[1] "stacktrace" ARGV[1]   │ HSET KEYS[1] 'stacktrace' ARGV[1]
            "failedReason" ARGV[2]     │            'failed_reason' ARGV[2]
  return 0                             │   (beside the existing terse `last_error` summary;
else return -1                         │    server-clock TIME-stamped at the dead-letter)
                                       │ companion to emq.3.4 fail_parent_on_failure (PROPOSED)
v2 today: NO dedicated port — only     │
  `last_error` on @retry dead-letter   │
  (jobs.ex:281), no host verb          │
```

## Family: remove-clean

The v1 BullMQ-derived removal/cleanup family — five Lua commands that delete one job (plus its children), break a parent↔child link, release a dedup key, recursively remove a job's unprocessed children, or bulk-clean a status set by age. Read against the as-built `echo/apps/echo_mq` tree (the v2 bus of record) and the v2 laws (`docs/echo_mq/emq.design.md` S-1…S-7, the §6 braced grammar), the family splits cleanly: the **single-job remove** and the **dedup-key release** are shipped (emq.2.2, folded into one script); the **bulk clean** has a shipped predicate-free cousin (`Admin.drain/3`); and the two **child-graph mutators** are NOT YET — their v1 forms root key operands in data values (the `parent_key` HASH field, the `:dependencies` SET of child *keys*), structurally illegal under the declared-keys law A-1, so each is a forward re-derivation, never a lift.

The structural fact that governs every v3 row: v1 carries the dependency graph as a **SET of child job-keys** at `<parent>:dependencies` and stores `parentKey`/`parent` **as hash fields** on each child, then reads those values back to construct the keys it mutates (`SREM parentDependenciesKey jobKey`, recursive `removeJobWithChildren(childJobPrefix, childJobId, …)`). The v2 bus already broke this: `EchoMQ.Flows` (emq.3.1–3.4) carries the graph as a **STRING counter** at `emq:{q}:job:<parent>:dependencies` with a `:processed`/`:failed`/`:unsuccessful` HASH, all **declared §6 parent subkeys**, never the v1 data-value `parent_key` (`flows.ex:6-23`, `jobs.ex:155`, design §11.10). So fan-in is a `DECR`, not a member-removal — which is exactly why v1's `removeChildDependency` (an `SREM` of a member) has no member to remove in v2 and must be re-conceived as a counter+record operation.

### removeJob-2

**v1 purpose + mechanism.** Removes a job from every status it may be in plus all its data, refusing if the job is active/locked. `KEYS[1]` = jobKey, `KEYS[2]` = repeat key; `ARGV` = `jobId`, `shouldRemoveChildren`, `queue prefix`. It guards with `isJobSchedulerJob` (returns `-8`) and `isLocked`, then calls `removeJobWithChildren(prefix, jobId, nil, options)`. The illegal-under-A-1 core is in the includes: `removeJobWithChildren` **constructs the failed-set key from the `prefix` ARGV** (`local failedSet = prefix .. "failed"`), and `removeJobChildren` reads child job-keys out of **`HGETALL <jobKey>:processed`**, **`HGETALL :failed`**, **`ZRANGE :unsuccessful`**, and **`SMEMBERS <jobKey>:dependencies`**, then for each derives `childJobPrefix`/`childJobId` from the *value* and recurses — every recursion roots its keys in data read from the store, against the engine's own rule that all keys be passed in `KEYS[]`.

**v2 status — PORTED (emq.2.2 ✅).** `EchoMQ.Jobs.remove_job/4` + the inline `@remove_job` `Script.new/2` (`jobs.ex:799-853`). It declares all six keys (`job_key`, `pending`, `active`, `schedule`, `dead`, `de:<did>`), refuses a locked job with `redis.error_reply('EMQLOCK job is locked')` → `{:error, :locked}`, answers `-1`→`{:error, :gone}` on a missing job, `ZREM`s across the four sets, deletes the row + its `:logs` subkey, and releases the dedup key iff it matches. Parity row: `emq.features.md` Part B.2, `removeJob-12.lua` → `@remove_job`, status ✅.

**v3 PROPOSED.** The single-job form is shipped and correct under the laws — v3 keeps it. The v1 *recursive* capability (`shouldRemoveChildren`) is the forward work: a declared-keys recursive variant that walks the **`Flows` declared subkeys** (the STRING `:dependencies` counter + the `:processed` HASH on the parent's `{q}` slot, `flows.ex:6-23`) rather than reading a `parent_key` hash field, FLAT first (grandchildren deferred to emq.3.5, the V-1 fork — `emq.features.md` C.1). Branded job ids gated at `Keyspace.job_key/2`; server-clock untouched (remove is not a lease op); honest `{:error, :gone}`/`:locked`/`:ok`.

**BCS / EchoMesh.** BCS: the removal verb a consumer's operator runbook drives over branded job ids (job cleanup). EchoMesh: an operator-plane **consistency-first** destructive act — gated (`EMQLOCK`), single-slot-atomic under braces; on a partition the owning node refuses rather than risk a torn removal.

```text
v1 removeJob-2 (BullMQ-derived)              v3 PROPOSED (under the v2 laws)
-------------------------------              ------------------------------------
KEYS[1]=jobKey  KEYS[2]=repeat               KEYS = [job_key, pending, active,
ARGV=jobId, removeChildren, PREFIX                   schedule, dead, de:<did>]   (declared)
isJobSchedulerJob → -8                       branded id gated at Keyspace.job_key/2
isLocked(prefix,id) → 0                      EXISTS :lock → EMQLOCK → {:error,:locked}
removeJobWithChildren(prefix,id,nil,opts):   @remove_job: ZREM x4 sets; DEL row+:logs;
  failedSet = PREFIX .. "failed"  (ARGV-key)   de: release iff GET==id           (shipped)
  SMEMBERS <jobKey>:dependencies →  recurse  recursive variant (PROPOSED): walk Flows
    childPrefix/childId from VALUE (A-1 ✗)     declared :dependencies/:processed (counter,
                                               not a member SET) — FLAT; grandchildren→emq.3.5
```

### removeChildDependency-1

**v1 purpose + mechanism.** Breaks a parent↔child dependency by removing the child reference from the parent. `KEYS[1]` = the `'key'` prefix; **`ARGV[1]` = job key, `ARGV[2]` = parent key** — both keys arrive as ARGV **data values**, the textbook A-1 violation. It `EXISTS`-checks both (`-1`/`-5`), calls `removeParentDependencyKey(jobKey, false, parentKey, KEYS[1], nil)` (which `SREM`s the child key from `<parentKey>:dependencies`, and if that was the last pending dependency, `ZREM`s the parent from `waiting-children` and moves it to wait/paused), then `HDEL`s `parentKey, parent` from the child hash. Both the `SREM` target and the `_moveParentToWait` keys are built from the ARGV `parentKey` and from values read via `getJobKeyPrefix`.

**v2 status — NOT YET (no named verb).** There is no `remove_child_dependency`/`drop_dependency` in the tree (grep confirms none in `lib/`). The nearest as-built behavior is the **automatic** fan-in `DECR` inside `@flow_deliver` (`pump.ex:42-51`) and `@complete`'s fan-in branch — but that fires on child *completion*, releasing the parent at zero; it is not an explicit operator detach of a still-pending child, and v1's `removeParentDependencyKey` is listed (under `flow_producer`) as the data-value form that does not port (`emq.features.md` Part B.1 flow row; design §11.10). Note the structural mismatch: v2 `:dependencies` is a **STRING counter** (Fork R2.A, `flows.ex:317-318`), not v1's SET of child keys — so there is literally no member to `SREM`.

**v3 PROPOSED.** A new `EchoMQ.Flows.drop_dependency/3` (queue, parent_id, child_id): on the parent's `{q}` slot, record the child in the parent's declared `:processed` HASH (HSETNX, idempotent), `DECR` the declared `:dependencies` counter, and at-zero release the parent to `pending` (the exact `@flow_deliver` shape, `pump.ex:42-51`) — every key host-built from `Keyspace.job_key(queue, parent_id)`, never a value-read parent_key (S-6/A-1). A cross-queue detach rides the same durable `emq:{C}:flow:outbox` + `Pump.sweep/1` hop the cross-queue fan-in uses (`pump.ex:189-196`), eventually-consistent + idempotent. The v1 `HDEL parentKey parent` on the child has no v2 analogue — the child carries no `parent_key` field by construction.

**BCS / EchoMesh.** BCS: lets a multi-leg flow drop one leg (e.g. a cancelled child) without failing the parent. EchoMesh: **consistency-first** and single-slot-atomic for a same-queue parent; a cross-queue detach sits **availability-leaning** (the eventually-consistent outbox+sweep), the same dial the cross-queue fan-in chose (`flows.ex` INV5/INV7).

```text
v1 removeChildDependency-1                   v3 PROPOSED Flows.drop_dependency/3
--------------------------                   -----------------------------------
KEYS[1]=prefix                               KEYS = [parent :dependencies,
ARGV[1]=jobKey  ARGV[2]=parentKey   (A-1 ✗)         parent :processed, parent row]  (declared)
EXISTS jobKey?→-1  EXISTS parentKey?→-5      all host-built: Keyspace.job_key(q,parent_id)<>…
removeParentDependencyKey:                   on {P}: HSETNX :processed child → DECR :dependencies
  SREM <parentKey>:dependencies jobKey         (counter, NOT a member SET — Fork R2.A)
  (member SET of child KEYS)                  left<=0 → ZADD <parent> pending; HSET row pending
  last child → _moveParentToWait(parentPrefix) cross-queue: flow:outbox + Pump.sweep hop (idem.)
HDEL jobKey parentKey, parent                no child parent_key field exists (A-1-clean graph)
```

### removeDeduplicationKey-1

**v1 purpose + mechanism.** Releases a deduplication key iff it still belongs to this job. `KEYS[1]` = deduplication key (already a declared key — the rare v1 command whose single key is in `KEYS[]`), `ARGV[1]` = job id. It `GET`s the key, and if `currentJobId == jobId`, `DEL`s it; else returns `0`. The only A-1 wrinkle is that the delete is **conditional on a data value** (the GET result), but the key itself is declared — so this command is the closest to legal of the family.

**v2 status — PARTIAL / folded.** The exact GET-compare-DEL is **inlined into `@remove_job`** (`jobs.ex:810-813`: `if ARGV[2] ~= '' then local dk = KEYS[6]; if GET dk == id then DEL dk end end`), with the dedup key declared as `KEYS[6] = emq:{q}:de:<did>` (`jobs.ex:844`). The read side ships separately as `Metrics.get_deduplication_job_id/3` (`metrics.ex:185`, emq.2.1). There is **no standalone release verb** — the conformance scenario covers it only via `remove_job` with the caller's dedup_id (`conformance.ex:124`, `1026-1044`). Per design DQ-4, dedup at v2 is simple NX+TTL and the branded id is the receipt (design §2, §11.10).

**v3 PROPOSED.** Surface a standalone `EchoMQ.Jobs.release_dedup/3` (queue, dedup_id, job_id) that reuses the `@remove_job` `de:` branch verbatim: one declared `KEYS[1] = Keyspace.queue_key(queue, "de:" <> did)`, value-compare against the branded id, `DEL` on match. This is the family's only near-direct port — the v1 key was already declared; v3 only re-roots it under the braced `emq:{q}:de:<did>` grammar (§6, charset `[A-Za-z0-9._-]{1,255}`) and compares against the 14-byte branded receipt rather than a decimal/custom id.

**BCS / EchoMesh.** BCS: the idempotency-key release a producer calls to retire a dedup window early (the dedup key is the producer-chosen key; the branded id is the receipt, design §2). EchoMesh: a **consistency-first** local single-slot key op — the dedup key co-locates with its queue under the hashtag (`{q}`), so it is one slot and never a cross-node operation.

```text
v1 removeDeduplicationKey-1                   v3 PROPOSED Jobs.release_dedup/3
--------------------------                    --------------------------------
KEYS[1]=deduplicationKey   (already declared) KEYS = [emq:{q}:de:<did>]   (declared, braced §6)
ARGV[1]=jobId                                 ARGV = [branded job id]
GET deduplicationKey                          GET dk
== jobId → DEL  else 0                        == id → DEL  (the @remove_job de: branch, reused)
                                              compares the 14-byte branded receipt, not decimal
```

### removeUnprocessedChildren-2

**v1 purpose + mechanism.** Recursively removes a job's children, ignoring processed and locked. `KEYS[1]` = jobKey, `KEYS[2]` = meta key; `ARGV[1]` = prefix, `ARGV[2]` = jobId. It builds `options = {removeChildren = "1", ignoreProcessed = true, ignoreLocked = true}` and calls `removeJobChildren(prefix, jobKey, options)`. Because `ignoreProcessed` is true, it skips the processed/failed/unsuccessful walks and goes straight to `SMEMBERS <jobKey>:dependencies`, then for **each member (a child job key) read from the store** derives `childJobId`/`childJobPrefix` and recurses into `removeJobWithChildren` — the same data-value key recursion as `removeJob-2`, here with locks ignored. (Note: `KEYS[2]` meta is declared but never used in the body — a v1 maintenance-line quirk.)

**v2 status — NOT YET.** No recursive child-removal verb exists (grep confirms). `EchoMQ.Flows` ships fan-in (emq.3.1), child-result reads (emq.3.2), cross-queue (emq.3.3) and failure-policy/`add_bulk` (emq.3.4 specced) — but a **recursive teardown** of a parent's children is absent, and v1's `removeJobChildren` is exactly the data-value-rooted recursion design §11.10 declares structurally inexpressible (the `flow_producer` row, `emq.features.md` Part B.1).

**v3 PROPOSED.** A bounded `EchoMQ.Flows.remove_children/3` (queue, parent_id, opts) walking the parent's **declared §6 subkeys** — the `:dependencies` counter + `:processed`/`:failed`/`:unsuccessful` HASHes (`flows.ex:6`, the A-1-clean graph) — to enumerate same-queue children and `@remove_job` each on the parent's `{q}` slot; cross-queue children are reached via the durable `flow:outbox` + `Pump.sweep/1` hop (`pump.ex:189-196`), eventually-consistent + idempotent. **FLAT first** (one parent level): grandchildren / deep recursion is the locked Out → emq.3.5 (the emq-3-4 V-1 scope fork, Arm A, D-2; `emq.features.md` C.1). An `ignore_locked` flag maps to the v2 `EMQLOCK` semantics (skip rather than refuse). Bounded per call (`:more`/`:ok`, the `obliterate` budget pattern, `admin.ex:248`) so one invocation can't block the engine.

**BCS / EchoMesh.** BCS: tears down a cancelled fan-out's child legs without touching the parent's own state. EchoMesh: same-queue teardown is **consistency-first** single-slot; cross-queue teardown is **availability-leaning** — eventually-consistent and idempotent over the outbox+sweep, the partition-tolerant edge the manuscripts assign to the bus's cross-node hops.

```text
v1 removeUnprocessedChildren-2               v3 PROPOSED Flows.remove_children/3
------------------------------               -----------------------------------
KEYS[1]=jobKey  KEYS[2]=meta (unused)        KEYS = parent declared §6 subkeys
ARGV[1]=PREFIX  ARGV[2]=jobId                       (:dependencies/:processed/:failed/
options={removeChildren="1",                         :unsuccessful, parent row)  (declared)
         ignoreProcessed=true,               same-queue: enumerate children from declared
         ignoreLocked=true}                    subkeys → @remove_job each on {P}  (bounded)
removeJobChildren:                           cross-queue: flow:outbox + Pump.sweep (idem.)
  SMEMBERS <jobKey>:dependencies → recurse   FLAT only; grandchildren → emq.3.5 (V-1 fork)
    childPrefix/childId from VALUE  (A-1 ✗)  ignore_locked → skip EMQLOCK (not refuse)
```

### cleanJobsInSet-3

**v1 purpose + mechanism.** Bulk-removes jobs from one specific set older than a timestamp, up to a limit. `KEYS[1]` = set key, `KEYS[2]` = events stream, `KEYS[3]` = repeat key; `ARGV` = `jobKey prefix`, `timestamp`, `limit` (0 = unlimited), `set name`. It dispatches on the set name: `active`/`wait`/`paused` → `cleanList`, `delayed`/`prioritized` → `cleanSet` (with `processedOn`/`timestamp` attributes), the completed/failed default → `cleanSet` (`finishedOn`, `hasFinished`). Both helpers compute each job's effective timestamp with `getTimestamp(jobKey, {...})`, skip scheduler jobs (`isJobSchedulerJob`) and locked jobs, and call `removeJob(job, true, jobKeyPrefix, true)` per member — **every per-member key built from the ARGV `jobKeyPrefix`** plus a job id read out of the set, and the grace-period decision read from **hash field values** (the A-1-illegal core). It then `XADD`s a `cleaned` event with the count and returns the deleted-id list.

**v2 status — PARTIAL.** `EchoMQ.Admin.drain/3` + the inline `@drain` (`admin.ex:84-122`) is the shipped cousin: it `ZRANGE`s `pending` (and optionally `schedule`), deletes each row + `:logs` subkey, and answers `{:ok, n}`. But it is **predicate-free** — no timestamp grace period, no limit, no per-set dispatch, no scheduler-skip — and only over `pending`/`schedule` (active survives by design). `Admin.obliterate/3` is the whole-queue destroyer for a paused queue (`admin.ex:248`). v1's per-member `removeJob` recursion does not port (the `flow`/recursion family, design §11.10); the v1 `prioritized`/`completed`/`failed` sets don't exist in v2 (completion-deletes + lanes-not-priority, design §6).

**v3 PROPOSED.** An `EchoMQ.Admin.clean/4` over the **four v2 sets** (`pending`/`active`/`schedule`/`dead`) with: a **server-clock `TIME` age grace** (touching the cleanup decision → `TIME` per DQ-2c, design §4 row 26 — read the row's age, not a hash field passed as ARGV), an optional limit (bounded `:more`/`:ok` like `obliterate`), a scheduler-skip (the `Repeat` registry survives — drain already preserves it, `admin.ex:105`), and an **honest count** return. The v1 multi-branch set dispatch collapses: there are no `prioritized`/`completed`/`failed` sets to special-case under completion-deletes; the v2 event record is the `PUBLISH emq:{q}:events` the watch plane consumes (emq.2.3, `events.ex`), replacing v1's `XADD … cleaned`. Every job key derives from the declared queue base root (`Keyspace.queue_key(queue, "")`, the `@drain`/`@obliterate` INV4 pattern), never the ARGV `jobKeyPrefix`.

**BCS / EchoMesh.** BCS: the operator's age-based queue hygiene for a consumer's work lanes during an incident (trim a backlog older than N). EchoMesh: **availability-first** maintenance — a bounded, honest-count sweep that *degrades* a backlog rather than blocking the live claim path (the staleness/edge dial the manuscripts assign to the durable-edge surfaces, `mesh/index.md` "Trading Consistency for Availability"); per-queue single-slot under braces.

```text
v1 cleanJobsInSet-3                          v3 PROPOSED Admin.clean/4
-------------------                          -------------------------
KEYS[1]=setKey KEYS[2]=events KEYS[3]=repeat KEYS = declared queue base + the target set(s)
ARGV=jobKeyPrefix, timestamp, limit, SETNAME ARGV=age-grace, limit, set selector
dispatch on SETNAME:                         four v2 sets only (pending/active/schedule/dead);
  active/wait/paused → cleanList               no prioritized/completed/failed (completion-
  delayed/prioritized → cleanSet               deletes + lanes, §6) → the dispatch collapses
  completed/failed → cleanSet (finishedOn)   age decision from server TIME on the row (DQ-2c),
per member: getTimestamp(jobKey,{...}) (HASH   NOT a hash field passed as ARGV  (A-1 ✓)
  values), skip locked/scheduler,            per member: @remove_job; keys from declared base
  removeJob(prefix-built key)       (A-1 ✗)    root, never ARGV jobKeyPrefix; bounded :more/:ok
XADD <events> cleaned count                  PUBLISH emq:{q}:events (the emq.2.3 watch plane)
return deleted list                          return honest {:ok, n}
```

## Family: destructive-lifecycle

The three queue-scope lifecycle commands — drain (empty the backlog), obliterate (destroy the queue), pause/resume (gate claiming). All three are **PORTED** in the v2 bus of record at **emq.2.2** (`EchoMQ.Admin`, shipped `76fc947c`). v1 roots its destructive reach in **data values** — `removeParentDependencyKey` reads `parentKey` out of a job hash (`HMGET jobKey "parentKey"`) and then operates on that read string, and obliterate gates on a `meta.paused` field it must `HEXISTS`-probe before acting — both structurally illegal under the v2 declared-keys law (A-1). Every v3 form is a re-derivation: the dependency graph lives in **declared §6 parent subkeys**, every Lua key is in `KEYS[]` or grammar-rooted, and the v1 BullMQ set zoo (`wait`/`paused`-LIST/`completed`/`failed`/`prioritized`/`waiting-children`) collapses onto the four braced sorted sets.

### drain-5

**v1 purpose + mechanism.** Drains the queue — removes all **waiting** or **delayed** (but not active/completed/failed) jobs. `KEYS[1..5]` = `wait`, `paused`, `delayed`, `prioritized`, `jobschedulers`; `ARGV[1]` = queue key prefix, `ARGV[2]` = "should clean delayed" flag. It first `ZRANGE`s the `jobschedulers` zset to build a `scheduledJobs` skip-set (delayed jobs whose id is `repeat:<id>:<millis>` are spared), then calls `removeListJobs`/`removeZSetJobs` on the four sets. **The data-value root v3 cannot lift:** the removal path descends into `removeJob → removeParentDependencyKey`, which when called with no explicit `parentKey` reads `HMGET jobKey "parentKey"` and operates on whatever string it finds — a key operand sourced from a hash field, structurally illegal under A-1.

**v2 status — PORTED.** `EchoMQ.Admin.drain/3` over the inline `@drain` `Script.new(:drain, …)` (`echo/apps/echo_mq/lib/echo_mq/admin.ex:84`, the `def drain` at `:109`). Empties `pending` (optionally `schedule` via `include_schedule: true`), deleting each drained row + its `:logs` subkey; `active` is untouched; the repeat REGISTRY survives. Answers `{:ok, n}`. Cataloged as emq.2.2 ✅ in `emq.features.md` Part B (`drain-6.lua` → `jobs.ex`/`admin.ex`).

**v3 decision — PROPOSED.** Keep the shipped form as the state-of-the-art reimplementation: one inline script, `KEYS[1]` = the declared queue base root (the slot all job keys derive from by the §6 grammar — A-1-clean, no `parentKey` hash read), `KEYS[2]` = `pending`, optional `KEYS[3]` = `schedule`. The v1 four-set sweep collapses because the v2 keyspace has no `wait`/`paused`-LIST/`prioritized` sets (priority is `EchoMQ.Lanes`; mint order IS the order theorem). The v1 **scheduler-skip** re-derives honestly: the as-built row stores no job→repeat backref, so the guard protects the *registry* (`emq:{q}:repeat` + `repeat:<name>` survive a drain), not individual already-enqueued occurrences (D-4). Slot-sound under braces; honest-row `{:ok, n}`.

**BCS relevance.** PROPOSED: the operator runbook clears a queue's pending backlog during an incident, leaving in-flight (`active`) jobs alone.

**EchoMesh relevance.** PROPOSED: a control-plane (consistency-first) act — a single-slot atomic backlog wipe; it sits on the consistency side of the dial, not the availability side.

```text
v1 (drain-5)                                  │ v3 (PROPOSED)
──────────────────────────────────────────── │ ────────────────────────────────────────────
KEYS: wait, paused, delayed,                  │ KEYS[1]=emq:{q}:  (declared base root)
      prioritized, jobschedulers              │ KEYS[2]=emq:{q}:pending
ARGV: prefix, cleanDelayed                    │ KEYS[3]=emq:{q}:schedule  (optional)
ZRANGE jobschedulers → build skip-set         │ ARGV: (none — registry survives by design)
removeListJobs(wait), removeListJobs(paused)  │ wipe(pending): ZRANGE → DEL each
  → removeJob → removeParentDependencyKey:    │   base..'job:'..id  + ':logs'
    HMGET jobKey "parentKey"  ◀── DATA-VALUE  │ if KEYS[3]: wipe(schedule)
    (operate on the read string — A-1 ILLEGAL)│ active untouched; repeat REGISTRY survives
removeZSetJobs(delayed if flag), prioritized  │ every job key grammar-rooted from KEYS[1]
                                              │ return n   (honest row)
```

### obliterate-2

**v1 purpose + mechanism.** Completely destroys a queue and all its contents. `KEYS[1]` = `meta`, `KEYS[2]` = `base`; `ARGV[1]` = `count` (iteration budget), `ARGV[2]` = `force`. It (1) refuses unless `HEXISTS meta "paused"` — **a key-precondition rooted in a data field**; (2) refuses on live `active` jobs unless force; then deletes active (+ each `…:lock`), `delayed`, `repeat` (+ each `repeat:<key>`), `completed`, `paused`, `prioritized`, `failed` via the shared `removeJobs` family (again descending through `removeParentDependencyKey`'s `HMGET parentKey` data-value path), and finally `DEL`s ~13 auxiliary keys built by string-concatenating `baseKey` (`events`, `delay`, `stalled-check`, `stalled`, `id`, `pc`, `marker`, `meta`, `metrics:completed[:data]`, `metrics:failed[:data]`). Returns `-1` NotPaused / `-2` ExistActiveJobs / `1` more-work / `0` done.

**v2 status — PORTED.** `EchoMQ.Admin.obliterate/3` over the inline `@obliterate` `Script.new(:obliterate, …)` (`admin.ex:141`, the `def obliterate` at `:248`). `KEYS[1]` = `meta`, `KEYS[2]` = base; `ARGV` = `[force, budget]` (default `@default_budget` 1000). Refuses a non-paused queue (`EMQSTATE not paused` → `{:error, :not_paused}`) and live-active jobs unless `force` (`EMQSTATE active jobs present` → `{:error, :active}`); deletes the four state sets + lane sets (read from the live `ring`/`paused` SMEMBERS) + `repeat:<name>` + the §6 auxiliary keys (`metrics:*`, `gactive`, `glimit`, `ring`, `wake`, `paused`, `repeat`, `limiter`, `meta`); bounded `:more`/`:ok`. Cataloged emq.2.2 ✅.

**v3 decision — PROPOSED.** Keep the shipped bounded form. The v1 `meta.paused` HEXISTS-gate is re-expressed soundly: `meta` is the declared `KEYS[1]`, so the precondition reads a *declared key* (`HGET meta 'paused'`), not a data-value-derived key — A-1-clean. Every job-row key derives in-script from the declared base root `KEYS[2]` by the §6 grammar (slot-sound under braces), never from an `HMGET parentKey`. The v1 set-list collapses onto the four braced sets; "open" key families (lane sets, repeat names) are read from the live structures that name them (`ring`, `paused`, `repeat`) — the INV4 form. The bounded budget (`:more`/`:ok`) keeps each call a single sound transaction. The honest limit is documented: a `de:<did>` dedup string with no live referrer is not individually discoverable under declared keys (D-4) — released at remove-time/drain-time instead.

**BCS relevance.** PROPOSED: a control plane destroys ephemeral or test queues down to their keyspace footprint, leaving no trace of their existence.

**EchoMesh relevance.** PROPOSED: the **consistency-first** end of the dial — a destroy is correct-always, never optimistic; the bounded budget makes each invocation a sound single-slot transaction rather than an availability bet.

```text
v1 (obliterate-2)                             │ v3 (PROPOSED)
──────────────────────────────────────────── │ ────────────────────────────────────────────
KEYS: meta, base                              │ KEYS[1]=emq:{q}:meta   KEYS[2]=emq:{q}:
ARGV: count, force                            │ ARGV: force, budget(=1000)
HEXISTS meta "paused" ~=1 → return -1         │ HGET KEYS[1] 'paused'==false → EMQSTATE not paused
getListItems(base..'active'); if active &&    │ ZRANGE base..'active' 0 budget-1; if #act>0 &&
  not force → return -2                        │   not force → EMQSTATE active jobs present
removeJobs(...) → removeParentDependencyKey:  │ del_job(id): DEL base..'job:'..id +':logs'+':lock'
  HMGET jobKey "parentKey"  ◀── DATA-VALUE    │ pending/schedule/dead bounded; lanes from
DEL base..'active', ...'delayed','completed', │   live ring/paused SMEMBERS (grammar-rooted)
  'paused','prioritized','failed' (v1 sets)   │ DEL repeat:<name> from base..'repeat' ZRANGE
DEL base..'events'/'id'/'marker'/'meta'/...   │ DEL metrics:* gactive glimit ring wake paused
  (~13 string-concat aux keys)                │   repeat limiter meta   (§6 aux keys)
return 0 / 1 / -1 / -2                        │ return 0(:ok) / 1(:more); typed EMQSTATE refusals
```

### pause-7

**v1 purpose + mechanism.** Pauses or resumes the queue *globally*. `KEYS[1..7]` = `wait`-or-`paused`, `paused`-or-`wait`, `meta`, `prioritized`, events-stream, `delayed`, `marker`; `ARGV[1]` = `"paused"` or `"resumed"`. If `KEYS[1]` EXISTS it `RENAME`s it to `KEYS[2]` (physically moving the whole list between `wait`↔`paused`); on pause it `HSET meta paused 1` + `DEL marker`; on resume it `HDEL meta paused` and adds a marker (a fixed `0` if waiting/priority jobs exist, else `addDelayMarkerIfNeeded` reading the next delayed timestamp); finally `XADD` a `paused`/`resumed` event. The pause STATE is itself a `meta` data field, and the whole-list RENAME is the v1 dual-set model.

**v2 status — PORTED.** `EchoMQ.Admin.pause/2` + `resume/2` over the inline `@pause`/`@resume` scripts (`admin.ex:36`, defs at `:54`/`:66`). Each `HSET`/`HDEL`s a `paused` field on `emq:{q}:meta` (`KEYS[1]`); both claim paths read it first and short-circuit to empty (FORM b, D-2). Distinct from `EchoMQ.Lanes.pause/3` (per-group park: SADD `paused` SET + LREM ring). Cataloged emq.2.2 ✅ (`pause-7.lua` → `admin.ex`).

**v3 decision — PROPOSED.** Keep the shipped FORM b as the state-of-the-art reimplementation: pause is a single `paused` FIELD on the declared `KEYS[1] = emq:{q}:meta`, and `Jobs.claim/3` / `Lanes.claim/3` read it first and answer `:empty`. **No `wait`↔`paused` RENAME** — the v2 bus has one `pending` set, so the v1 dual-list move is gone, and crucially the shipped `@claim`/`@gclaim` stay **byte-frozen** (the one-time-fork law: pause is an additive gate, not a wire break). The v1 `marker`/`addDelayMarkerIfNeeded` delay-machinery does not survive (the v2 `schedule` set's run-at score is the visibility fence; no marker key). The `paused`/`resumed` event PUBLISH rides the emq.2.3 watch plane (`EchoMQ.Events` over the connector pub/sub seam), not this script. Idempotent; honest-row `:ok`.

**BCS relevance.** PROPOSED: an operator quiesces a runaway lane's claiming during an incident without moving the backlog — `Metrics.get_counts/3` reads the same pending depth before and after.

**EchoMesh relevance.** PROPOSED: a control-plane (consistency-first) gate; pausing claim deliberately trades **availability** (workers receive `:empty`) for operational control — segmentation by operation, the consistency-first side of the CAP dial.

```text
v1 (pause-7)                                  │ v3 (PROPOSED)
──────────────────────────────────────────── │ ────────────────────────────────────────────
KEYS: wait|paused, paused|wait, meta,         │ KEYS[1]=emq:{q}:meta   (declared)
      prioritized, events, delayed, marker    │ ARGV: (pause / resume chosen by verb)
ARGV: "paused" | "resumed"                    │
EXISTS KEYS[1] → RENAME KEYS[1] KEYS[2]       │ pause:  HSET  KEYS[1] 'paused' '1' ; return 1
  (physically move the whole wait↔paused list)│ resume: HDEL  KEYS[1] 'paused'     ; return 1
pause:  HSET meta paused 1 ; DEL marker       │ NO wait↔paused RENAME (one pending set)
resume: HDEL meta paused ;                    │ @claim/@gclaim read 'paused' FIRST → :empty
  ZADD marker 0 "0"  or addDelayMarkerIfNeeded│   (FORM b, D-2; claim scripts BYTE-FROZEN)
XADD events "*" event ARGV[1]                  │ paused/resumed event → emq.2.3 EchoMQ.Events
                                              │   (connector pub/sub seam, not this script)
```