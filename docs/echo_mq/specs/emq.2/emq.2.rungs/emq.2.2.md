# EMQ.2.2 · The operator plane — Movement I, the parity floor (lifecycle & mutation ops)

> **Status: BUILT** (the second rung of the emq.2 full-parity cluster; the carve + the ADRs are
> [`./emq.2.design.md`](../emq.2.design.md); reconciled to the as-built tree this run — the design-make
> decisions resolved, the three realization-over-literal re-derivations folded, the conformance count
> re-pinned to the as-built truth). emq.2.2 builds, inside `echo/apps/echo_mq` under the v2 laws, the
> **operator plane** of the bus — the lifecycle and
> job-mutation verbs an operator runbook drives a queue with: queue-wide pause/resume, drain, obliterate,
> the in-flight job mutations (update-data / update-progress / add-log + the log read), and the job
> lifecycle moves (remove a job, reprocess a dead job). It ports the v1 `echomq` operator capabilities
> (`pause-7`, `drain-6`, `obliterate-2`, `updateData-1`, `updateProgress-3`, `addLog-2`, `removeJob-12`,
> `reprocessJob-8`) **re-derived against `echo_mq`'s as-built four-set state machine** (`pending` / `active`
> / `schedule` / `dead` with completion-deletes). Each verb is a **real
> transition** over the row and the sets under the v2 laws — declared keys, an `EMQ*` typed refusal where a
> precondition fails, the server clock where a lease is touched. The v1 line (`apps/echomq`) is a
> **capability reference** — the list of operator surfaces to port — never a thing migrated from. This rung
> stands **on** the read plane (emq.2.1): emq.2.1's counts and state lookups are the acceptance lens for
> emq.2.2's effects (a paused queue reads its counts unchanged; a drained queue reads pending zero; a
> reprocessed job reads `pending`).

## Goal

emq.2.2 builds the bus's operator surface: the mutation verbs that **change** the state emq.2.1 observes —
"stop and resume claiming on this whole queue", "empty the pending backlog", "destroy a paused queue
entirely", "rewrite a job's data / progress / log while it is in flight", "remove one job from the queue",
and "send a dead job back to be retried". The capability reference is the frozen v1 line's operator API
(the lifecycle and mutation verbs of `EchoMQ.Queue` / `EchoMQ.Worker`, `apps/echomq/lib/echomq/queue.ex` +
`worker.ex`) and its operator scripts (`pause-7.lua`, `drain-6.lua`, `obliterate-2.lua`, `updateData-1.lua`,
`updateProgress-3.lua`, `addLog-2.lua`, `removeJob-12.lua`, `reprocessJob-8.lua` under
`apps/echomq/priv/scripts/`). emq.2.2 re-derives those capabilities against `echo_mq`'s real keyspace —
**not** the v1 state names: the as-built bus has `pending` / `active` / `schedule` / `dead` (and **no
`completed` / `failed` / `wait` / `prioritized` / `waiting-children` set**), so drain empties the `pending`
set (and optionally `schedule`), obliterate destroys exactly the four as-built sets plus the §6-registered
auxiliary keys, and reprocess moves a `dead` job back to `pending` (the "retry a failed job" surface — there
is no `completed` set to reprocess from). Every mutation script declares its keys in `KEYS[]` or
grammar-derives them (the master invariant); every precondition failure refuses with an `EMQ*` first-word
class (the §5 closed wire-class registry — adding a class is an additive minor registered with its probe);
every addition registers a conformance scenario in the same change (the additive-minor law); the prior 24
scenarios pass byte-unchanged and the 8 new operator scenarios register beside them (24 → 32). The
queue-wide pause is **distinct** from `EchoMQ.Lanes`' per-group pause (which parks one identity's lane);
emq.2.2's pause gates claiming on the whole queue.

## Rationale (5W)

- **Why** — `echo_mq` ships the state machine, the lanes, and (after emq.2.1) the read plane, but has **no
  operator plane**: an operator cannot pause a runaway queue, drain a bad backlog, destroy a test queue,
  rewrite a stuck job's data, append a diagnostic log, remove one poisoned job, or send a dead job back to
  be retried. The v1 line carries all of these (`EchoMQ.Queue.pause`/`drain`/`obliterate`/`remove_job`/
  `reprocess`, `EchoMQ.Worker.update_progress`/`log`/`update_data`), and the program's parity thesis
  ([`../emq.roadmap.md`](../../../emq.roadmap.md) Movement I) requires `echo_mq` to carry them before
  `apps/echomq` can dissolve. The parity carve ([`./emq.2.design.md`](../emq.2.design.md) ADR-1) places the
  operator plane **second** because its mutations change exactly the state the read plane already observes,
  so **emq.2.1's reads are emq.2.2's acceptance lens** (a drained queue is asserted by reading its pending
  count to zero; a reprocessed job by reading its state back to `pending`). The front door records the
  consumer story: "the operational floor every consumer reads through … the operator lifecycle verbs a
  runbook drives" ([`../echo_mq.md`](../../../echo_mq.md), the reframed emq.2 row).
- **What** — emq.2.2 builds, inside `echo_mq`: a **queue-scope operator module** (`EchoMQ.Admin`, or the
  verbs folded onto an existing module — the placement is the build's reductive call, recorded at the
  design gate) carrying **queue-wide pause/resume** (a claim gate over the whole queue, distinct from
  `Lanes.pause/3`'s per-group park — the `pause-7` capability re-derived), **drain** (empty the `pending`
  backlog, optionally `schedule`, removing each drained job's row and §6 subkeys — the `drain-6`
  capability), and **obliterate** (destroy a paused queue: every as-built set + every §6 auxiliary key,
  refusing on a non-paused queue or live active jobs unless forced, bounded per call — the `obliterate-2`
  capability); plus **job-mutation verbs** on `EchoMQ.Jobs` — **update_data** (replace the job's payload —
  `updateData-1`), **update_progress** (write the progress field — `updateProgress-3`), **add_log** /
  **get_job_logs** (append to / read the job's `:logs` list — `addLog-2`), **remove_job** (remove one job
  from its set + delete the row and §6 subkeys, refusing a held/locked job — `removeJob-12`), and
  **reprocess_job** (move a `dead` job back to `pending`, refusing a job not in `dead` — `reprocessJob-8`).
  The exact verb set traces to the v1 operator API (Deliverables below); no operator surface here is
  invented.
- **Who** — the bus's operators and the platform that drives them: an operator runbook pausing/draining a
  queue during an incident, a control plane obliterating ephemeral test queues, a worker (or a dashboard)
  rewriting a stuck job's data/progress/log, an on-call removing a poisoned job, an operator reprocessing a
  dead job after fixing its cause, the conformance harness asserting the mutation verdicts, and the watch
  plane (emq.2.3) whose events fire on exactly these transitions. The Exchange platform's operator surface
  drives the work queues through this kind of lifecycle ("Positions and exposure read from Tables" —
  `exchange.patterns.md` Pattern V is the read side; the operator's runbook is the mutation side). No single
  TRD rung *gates* on emq.2.2 by name (it is the floor, not a feature), recorded not asserted.
- **When** — Movement I, **second of the emq.2 cluster** (emq.2.1 → **emq.2.2** → emq.2.3;
  [`./emq.2.design.md`](../emq.2.design.md) ADR-1's dependency order), after emq.2.1 (the read plane) closed
  — emq.2.1's reads are this rung's acceptance lens. BUILT; reconciled to the as-built tree this run. The
  parity carve was authored to Arm A (the recommended carve — design §6); the read plane (emq.2.1) and this
  operator plane stand on it.
- **Where** — `echo/apps/echo_mq` only (the new `EchoMQ.Admin` module + the mutation verbs on
  `EchoMQ.Jobs`, all as inline `Script.new/2` attributes — the as-built convention, **not** `priv/`; the 8
  new conformance scenarios in `conformance.ex`; the pure + `:valkey` suites). `apps/echomq` is untouched
  (the capability reference). **`[RECONCILE]` — no `echo_wire` seam: the queue-wide pause is realized as the
  SEPARATE-gate form (FORM b, EMQ.2.2-D1(b)) — `EchoMQ.Jobs.claim/3` and `EchoMQ.Lanes.claim/3` read the
  `meta.paused` flag FIRST and short-circuit to empty, leaving the shipped `@claim`/`@gclaim` scripts
  byte-unchanged — so no `echo_wire` delegate is added (the gate-in-`@claim` form was steelmanned and
  retired; it would have edited emq.1's shipped script, the rung's named elevated risk).** Exact key,
  structure, and script anchors are pinned against the as-built tree (the lag-1 discipline) — emq.1's,
  emq.2.1's, and emq.2's earlier builds moved the `echo_mq` surface before emq.2.2 mutated it.

## Scope

- **In** — queue-wide **pause/resume** (a claim gate over the whole queue via a `meta.paused` field both
  `Jobs.claim/3` and `Lanes.claim/3` read first, distinct from `Lanes.pause/3`); **drain** (empty the
  `pending` backlog + optionally `schedule`, deleting each drained job's row and §6 `logs` subkey; active
  jobs survive — **`[RECONCILE]`** the repeat REGISTRY survives, not individual repeat-produced occurrences:
  the as-built row stores no job→repeat backref, so drain never deletes `emq:{q}:repeat`/`repeat:<name>` —
  see EMQ.2.2-D3); **obliterate** (destroy a *paused* queue — every as-built set
  `pending`/`active`/`schedule`/`dead` + the fixed-name §6 auxiliary keys `metrics:*`/lane structures/`repeat`+
  `repeat:<name>`/`limiter`/`meta`, refusing a non-paused queue or live active jobs unless forced, bounded
  per invocation; **`[RECONCILE]`** `de:*` dedup strings are released at remove/drain time, not swept by
  obliterate — an orphaned `de:<did>` with no live referrer is not discoverable under declared keys, the
  bounded-completeness honest limit — see EMQ.2.2-D4); **update_data** (replace the job payload);
  **update_progress** (write the progress field + emit the watch-plane progress event on `emq:{q}:events`);
  **add_log** / **get_job_logs** (append to / read `emq:{q}:job:<id>:logs`, the §6 `logs` subkey, with an
  optional keep-N trim); **remove_job** (remove one job from whichever set holds it + delete the row and §6
  subkeys + **`[RECONCILE]`** release a caller-supplied dedup key — `remove_job/4` takes an optional
  `dedup_id`; the as-built row stores no `deid` backref, so the held `de:<did>` is the caller's to name —
  refusing a locked job); **reprocess_job** (move a `dead` job back to `pending`, refusing a job not in
  `dead`); the `EMQ*`-classed typed refusals for the precondition failures (locked job → `EMQLOCK`;
  not-paused / live-active / not-dead → `EMQSTATE`; a missing job → a `-1` sentinel mapped `{:error, :gone}`,
  no class — §5 additive minors registered with probes); pure + `:valkey` suites; the conformance scenarios +
  probes registering each mutation verdict.
- **Out** — the read plane (counts / job + state lookup / metrics / dedup read / rate-limit read — emq.2.1,
  the acceptance lens here); the **batch consume** family (`add_bulk` consumption, `min_size`/`timeout`
  shaping — emq.5, ADR-2); the **distributed** cancel / TTL / checkpoints (emq.6, ADR-2) — the worker-side
  cooperative cancel + lock-extension is emq.2.3 (ADR-3); the **event stream + telemetry + explicit
  stalled-sweep + worker-side lock plane** (emq.2.3, ADR-3/ADR-4) — emq.2.2 *reads* the `job:<id>:lock`
  presence for the remove refusal but ships **no** lock-extension verb and **no** lock-tracking process; the
  per-group lifecycle (`Lanes.pause`/`resume`/`limit` — already shipped, distinct scope); any new key *type*
  outside the §6 grammar (drain/obliterate touch the registered sets + the registered `metrics:`/`de:`/`logs`
  suffixes — no new type); any v1-shaped state type the bus does not have (`wait`/`paused`-LIST/`completed`/
  `failed`/`prioritized`/`waiting-children`); any wire break (every addition is an additive protocol minor);
  any edit to the frozen v1 line; the in-flight `echo/apps/exchange/` + `docs/exchange/*`.

## Deliverables

emq.2.2 builds (as-built — the operator surface now lives in `echo_mq`; the frozen `apps/echomq` reference
named the capabilities to port):

- **EMQ.2.2-D1** — **the design-make gate (FIRST; RESOLVED at the build's ledger, recorded before any build
  artifact — INV8):** the operator-plane design adopting [`./emq.2.design.md`](../emq.2.design.md)'s carve
  (ADR-1) and the four rulings the build made — (a) the **module placement: a new `EchoMQ.Admin`** carries
  the four queue-scope verbs (pause/resume/drain/obliterate); the six job-mutation verbs **fold onto
  `EchoMQ.Jobs`** beside the state machine they extend (the `EchoMQ.Metrics`-beside-`Jobs` read-plane
  precedent; all-on-`Jobs` and a single `EchoMQ.Operator` steelmanned and rejected); (b) the **queue-wide
  pause mechanism: a `paused` field on the `meta` HASH (FORM b)** — `EchoMQ.Jobs.claim/3` AND
  `EchoMQ.Lanes.claim/3` read it FIRST and short-circuit to empty (a queue-wide pause gates both the flat
  and the grouped claim); the gate-INSIDE-`@claim` form (a, atomic but edits emq.1's shipped script) and a
  dedicated `qpaused` key were steelmanned and rejected — **`@claim`/`@gclaim` are byte-unchanged by
  construction**, so the `claim` conformance scenario is byte-identical with no re-run-and-diff; (c) the
  **`EMQ*` refusal class words: TWO** — `EMQLOCK` (a held/locked job on remove → `{:error, :locked}`) and
  `EMQSTATE` (a wrong-state precondition, atom-distinguished by the calling verb: not-paused →
  `{:error, :not_paused}`, live-active → `{:error, :active}`, not-dead → `{:error, :not_dead}`); a missing
  job is a `-1` return sentinel mapped `{:error, :gone}` (the as-built `complete/4` convention — no class);
  each class registered with a conformance probe in the same change, the five-code fence union UNEXTENDED;
  (d) the **drain/obliterate scope** — the as-built four sets `pending`/`active`/`schedule`/`dead` + the §6
  auxiliary keys each touches. Every key spelled against §6; recorded BEFORE any
  build story ran (the emq.1/emq.2.1 precedent: the design-make is the relocated gate).
- **EMQ.2.2-D2** — **queue-wide pause/resume:** `EchoMQ.Admin.pause/2` and `resume/2` set/clear a `paused`
  field on the `meta` HASH (`HSET meta paused 1` / `HDEL meta paused` — an as-built §6-registered key type,
  no new type, no `keyspace.ex` change; the v1 `pause-7` `meta.paused` flag re-derived, dropping v1's
  wait↔paused LIST rename — the bus has no LISTs). **The claim path honors it (FORM b): both
  `EchoMQ.Jobs.claim/3` and `EchoMQ.Lanes.claim/3` read the flag first** (via `Jobs.paused?/2`) and answer
  **empty** even with a non-empty pending set, and resume restores claiming. Distinct from `Lanes.pause/3`:
  this gates the **whole** queue (flat AND grouped claims); the per-group park (the Lanes `paused` SET +
  ring) is unchanged and structurally disjoint from this meta field.
- **EMQ.2.2-D3** — **drain:** `EchoMQ.Admin.drain/3` empties the `pending` set (and, with
  `include_schedule: true`, the `schedule` set), deleting each drained job's row and its §6 `logs` subkey,
  via ONE inline `@drain` script declaring `KEYS[1]` = the queue base root + `KEYS[2]` = `pending` (+ optional
  `KEYS[3]` = `schedule`); each `job:<id>`/`:logs` key derives from the declared base root (INV4) — the
  `drain-6` capability re-derived: `active` jobs are **not** drained (they are in flight). **`[RECONCILE]` —
  the repeat guard protects the REGISTRY, not individual occurrences.** v1 `drain-6` guards id-encoded
  `repeat:<sched>:<millis>` scheduled members; but the as-built `EchoMQ.Repeat` mints a fresh ordinary
  branded JOB id per occurrence and the three-field row stores **no job→repeat backref**, so there is no id
  pattern distinguishing a repeat-produced scheduled job from a hand-scheduled one (storing one would change
  the row shape the 24 prior scenarios pin — INV1; the store-a-backref alternative was rejected). The honest
  re-derivation: **drain never deletes the repeat registry (`emq:{q}:repeat` / `emq:{q}:repeat:<name>`)**, so
  a drain does not cancel a registered repeatable — future occurrences keep minting (the operationally
  meaningful guarantee); individual already-enqueued scheduled occurrences drain like any scheduled job when
  the `schedule` flag is set (they are just jobs).
- **EMQ.2.2-D4** — **obliterate:** `EchoMQ.Admin.obliterate/3` destroys a **paused** queue — every as-built
  set (`pending`/`active`/`schedule`/`dead`) and the §6 auxiliary keys (`metrics:completed`[`:data`]/
  `metrics:failed`[`:data`], the lane structures `gactive`/`glimit`/`ring`/`wake`/`paused`-SET + each
  `g:<g>:pending`, `repeat` + each `repeat:<name>`, `limiter`, and `meta` with the paused flag) and every
  reachable job row + its `:logs`/`:lock` subkeys — bounded per invocation by `budget` (the iterative
  `obliterate-2` capability: answers `:more` while work remains, `:ok` when done). It **refuses** a non-paused
  queue (`EMQSTATE not paused` → `{:error, :not_paused}`, the refusal is the script's first act) and (unless
  `force: true`) a queue with live active jobs (`EMQSTATE active jobs present` → `{:error, :active}`), each
  changing nothing. The fixed-name keys derive from the declared base root directly; the OPEN families are
  read from the live structures that name them (the `ring`/`paused` SET names live groups; the `repeat` ZSET
  names live registrations) and each family key derives from the base — slot-sound, declared-keys-clean. No
  `completed`/`failed` set exists to destroy — the metrics counters are the throughput record, deleted as §6
  keys. **`[RECONCILE]` — `de:*` is NOT swept by obliterate.** Under declared keys an orphaned `de:<did>`
  with no live referrer is not individually discoverable (no `SCAN` — it would cross slots and break the A-1
  law); the `scan-the-de-family` alternative was rejected. `de:` strings are released at remove-time
  (`remove_job/4`, D8) and at drain-time; obliterate clears the discoverable structure keys — the
  bounded-completeness honest limit.
- **EMQ.2.2-D5** — **update_data:** `EchoMQ.Jobs.update_data/4` replaces the job's `payload` field (the v2
  row's payload — the `updateData-1` capability, `data` → `payload` under the as-built three-field row),
  refusing a missing job with `{:error, :gone}`. A transition on the row, one declared key, no set move.
- **EMQ.2.2-D6** — **update_progress:** `EchoMQ.Jobs.update_progress/4` writes a `progress` field on the job
  row (the `updateProgress-3` capability), and **emits the progress event** the watch plane (emq.2.3)
  subscribes to. **The registered event contract (the locked D-5 seam emq.2.3 inherits):** after the field
  write, the script issues `PUBLISH emq:{q}:events cjson.encode({event="progress", job=<id>, progress=<value>})`
  — a single `cjson` JSON object `{"event":"progress","job":"<branded-id>","progress":"<value>"}` on the
  per-queue events channel `emq:{q}:events`. The event NAME rides the payload's `event` field (one channel
  per queue carries every lifecycle event, distinguished by `event` — the v1 `QueueEvents` shape), so
  emq.2.3's `EchoMQ.Events` subscribes ONCE and dispatches on it. The channel derives from the declared queue
  base root; a pub/sub channel is not a slot-routed keyspace key, so it adds **no §6 key type, no `KEYS[]`
  declaration, no new transport** — it rides the existing connector RESP3 pub/sub seam (ADR-4). A
  subscriber-less PUBLISH is a no-op (returns 0) until emq.2.3 subscribes. Refuses a missing job
  (`{:error, :gone}`).
- **EMQ.2.2-D7** — **add_log / get_job_logs:** `EchoMQ.Jobs.add_log/5` (`add_log(conn, queue, job_id, line,
  keep \\ 0)`) appends a line to `emq:{q}:job:<id>:logs` (the §6 `logs` subkey) with an optional keep-N trim
  (the `addLog-2` capability — returns the log count); a missing job refuses `{:error, :gone}`.
  `EchoMQ.Jobs.get_job_logs/3` reads the logs list in append order (a read paired with the write, on the
  state-machine module beside `get_job`); a missing job answers `{:error, :gone}`, a job with no logs
  `{:ok, []}`. Both declare the `logs` key, gated by `BrandedId.valid?/1` at the key builder.
- **EMQ.2.2-D8** — **remove_job:** `EchoMQ.Jobs.remove_job/4` removes one job from whichever set holds it
  (`ZREM` across all four — `pending`/`active`/`schedule`/`dead`) and deletes the row and its §6 `logs`
  subkey — the `removeJob-12` capability re-derived against the four sets. **`[RECONCILE]` — the dedup
  release takes a caller-supplied `dedup_id` (an optional 4th argument).** v1 `removeJob-12` finds the dedup
  key via `HGET jobKey "deid"`, but the as-built three-field row stores **no `deid` backref**, so remove
  cannot discover the dedup id from the row (the `scan-the-de-family` alternative breaks declared keys; a
  stored backref breaks the row INV1 pins). When `dedup_id` is supplied, the script releases `de:<dedup_id>`
  **IFF** its value `== this job id` (the v1 guard re-derived under declared keys); when omitted, no dedup
  key is released — a caller that parked a dedup key knows its `did` and passes it. It **refuses a locked
  job** (`emq:{q}:job:<id>:lock` present — the §6 `lock` subkey the worker-side lock plane writes at emq.2.3)
  with `EMQLOCK` → `{:error, :locked}` (the refusal is the first act, the job untouched). Branded id gated at
  the key builder; a missing job answers `{:error, :gone}`.
- **EMQ.2.2-D9** — **reprocess_job:** `EchoMQ.Jobs.reprocess_job/3` moves a **dead** job back to `pending`,
  clearing the failure field (`last_error`) and resetting the row to `state = pending` (the `reprocessJob-8`
  capability re-derived: the bus's only finished-and-retained state is `dead`, so reprocess is
  `dead`→`pending`, the "retry a failed job" surface). The not-dead guard is an atomic `ZREM dead` whose
  no-op (`~= 1`) **refuses a job not in `dead`** with `EMQSTATE not dead` → `{:error, :not_dead}` (the
  refusal is the first act, changing nothing). The D2 pause seam holds: a reprocessed job lands `pending` but
  stays unclaimable while the queue is paused (the claim path gates it; the reprocess transition itself does
  not consult the flag — the job IS pending, pause gates the future claim). A missing job answers
  `{:error, :gone}`.
- **EMQ.2.2-D10** — **proof:** the **8 new conformance scenarios** + probes registered for every operator
  verdict — `queue_pause`, `drain`, `obliterate`, `update_data`, `update_progress` (asserting the emit
  through a bounded-receive subscriber seam — D-5), `job_logs`, `remove_job`, `reprocess_job` (the
  after-the-mutation assertions: a paused queue claims empty with a non-empty pending; drain leaves pending
  zero and active intact; obliterate refuses a non-paused queue and clears every set when paused;
  update_data/update_progress/add_log rewrite the row/logs and a missing job refuses typed; remove_job
  removes an unlocked job and refuses a locked one; reprocess_job moves a dead job to pending and refuses a
  live one); pure + `:valkey` suites. **The prior 24 conformance scenarios pass byte-unchanged** (the 18
  state-machine + emq.2.1's 6 read scenarios — the additive-minor law) and the **count re-pins 24 → 32** in
  both pinning tests (`conformance_scenarios_test.exs` + `conformance_run_test.exs`); honest-row reporting
  (Valkey on 6390 the truth row).

## Invariants

- **EMQ.2.2-INV1** — the wire law: zero wire breaks; emq.2.2 adds no key *type* outside the §6 grammar
  (drain/obliterate touch the registered sets + the §6 `metrics:`/`de:`/`logs` suffixes; the paused flag is a
  field on the existing `meta` HASH — never a new type); every conformance addition is an additive protocol
  minor registered with its probe in the same change; the **24 prior conformance scenarios pass
  byte-unchanged** (the 18 state-machine + emq.2.1's 6 read scenarios) and the count re-pins **24 → 32**.
  The TWO new `EMQ*` refusal classes (`EMQLOCK`, `EMQSTATE`) are additive minors registered with their
  probes; the five-code fence union stands unextended.
- **EMQ.2.2-INV2** — every verb is a **real transition** under the v2 laws: a mutation changes the row
  and/or moves/clears a set member atomically in ONE inline script; it never reads-then-writes across two
  round trips (the v1 form's race). The queue-wide pause is the one verb that gates a *future* transition
  (claim) rather than moving a member; it is realized so a paused queue's claim is empty (D2). emq.2.1's
  reads are the acceptance lens — every transition is asserted by reading the structure it changed.
- **EMQ.2.2-INV3** — the structures are the as-built ones: every verb operates on
  `pending`/`active`/`schedule`/`dead` (the four sets) + the §6-registered auxiliary keys — **never** a
  v1-shaped state type the bus does not have (no `wait`/`paused`-LIST/`completed`/`failed`/`prioritized`/
  `waiting-children`). drain empties `pending` (+ optional `schedule`); obliterate destroys the four sets +
  the §6 keys; reprocess is `dead`→`pending` (no `completed`/`failed` set to reprocess from), stated in the
  contract.
- **EMQ.2.2-INV4** — declared keys, self-justified: every mutation script declares its structure keys in
  `KEYS[]` or derives them in-script only from a declared `KEYS[n]` root by the registered grammar (the
  master invariant; the A-1 lint). drain/obliterate, which sweep many job rows, derive each
  `job:<id>`/subkey from the declared queue root (the §6 grammar) — slot-sound under braces (every derivable
  key shares the declared root's slot).
- **EMQ.2.2-INV5** — branded identity at the mutation boundary: every job-targeted verb gates the id with
  `BrandedId.valid?/1` at `Keyspace.job_key/2` (an ill-formed id raises before any wire — the as-built key
  builder's contract); a mutation never constructs a job key from an ungated string.
- **EMQ.2.2-INV6** — the wire-class discipline: every precondition refusal leads with its `EMQ*` first-word
  class via `redis.error_reply` (the §5 convention), mapped client-side to a typed atom — as-built:
  `EMQLOCK` (a locked job → remove) → `{:error, :locked}`; `EMQSTATE` (not-paused / live-active → obliterate;
  not-dead → reprocess) → `{:error, :not_paused}` / `{:error, :active}` / `{:error, :not_dead}` (the class
  word is the wire token; the calling verb maps the precise atom). A **missing** job (update/progress/log/
  remove) is an EXISTENCE check, not a policy refusal: the script returns a `-1` sentinel mapped
  `{:error, :gone}` (the as-built `complete/4` convention — no wire class, the typed-absent arm). An
  unrecognized `EMQ*` first word passes through untyped (forward-compatible with minors); the five-code fence
  union stands unextended. A refused mutation **changes nothing** (the refusal is the first act, before any
  write).
- **EMQ.2.2-INV7** — the server clock where a lease is touched: any verb that re-prices a lease deadline (if
  the build finds one — e.g. a reprocess that re-leases) reads `TIME` **inside** the script (the §4/DQ-2c
  server-clock law, sound under effects replication), never the caller's clock. Most operator verbs touch no
  lease (drain/obliterate/update/log/remove operate on the row + sets); the invariant binds the one that
  does, and is vacuously satisfied where none does — stated, not assumed.
- **EMQ.2.2-INV8** — the design gate (satisfied): no build artifact predated EMQ.2.2-D1's placement + pause
  mechanism + refusal class words + drain/obliterate scope being recorded (the build's ledger logged D-1..D-4
  before any `.ex`/Lua artifact — INV8 held). The triad is now reconciled to the as-built surface; the
  forward-tense "emq.2.2 builds …" stands as the design intent the build realized.

## Definition of Done

- [x] EMQ.2.2-D1: the operator-plane design recorded (module placement → `Admin` + `Jobs`; the queue-wide
      pause mechanism FORM (b) with ≥2 steelmanned alternatives; the `EMQ*` refusal class words `EMQLOCK`/
      `EMQSTATE` against §5; the drain/obliterate scope as the as-built sets + §6 keys, NOT the v1 list);
      every key spelled against §6 (the gate that opened the build — logged D-1..D-4 before any artifact).
- [x] D2–D9 built in `echo_mq` as real transitions (INV2): queue-wide pause/resume distinct from
      `Lanes.pause/3` (INV3); drain empties pending (+ optional schedule), active intact; obliterate destroys
      the four sets + §6 keys, refusing non-paused / live-active (INV6); update_data / update_progress /
      add_log + get_job_logs on the row/logs, gated by `BrandedId.valid?/1` (INV5); remove_job removes an
      unlocked job and refuses a locked one (INV6); reprocess_job moves dead→pending and refuses a non-dead
      job (INV6).
- [x] Every mutation script declares its keys or grammar-derives them (INV4); drain/obliterate derive each
      job key from the declared queue root; the A-1 reading is the as-built convention; the server clock
      binds any lease-touching verb (INV7, vacuous — no operator verb touches a lease).
- [x] Every precondition refusal leads with an `EMQ*` class mapped client-side to a typed atom (INV6); a
      refused mutation changes nothing; the new `EMQLOCK`/`EMQSTATE` classes registered with conformance
      probes; the five-code fence union stands unextended.
- [x] Pure + `:valkey` suites green per-app; the **24 prior conformance scenarios pass byte-unchanged** and
      the 8 new operator scenarios pass beside them (the count re-pins 24 → 32 in both pinning tests; the
      registry grows additively — INV1); honest-row reporting (Valkey on 6390 the truth row).
- [x] The mutation verdicts proven against emq.2.1's read lens: a paused queue claims empty with a non-empty
      pending; drain leaves pending zero and active intact; obliterate clears every set when paused and
      refuses when not; update/log rewrites the row/logs; remove_job removes an unlocked job; reprocess_job
      moves a dead job to pending.
- [x] The emq.1 + emq.2.1 gate ladders + the emq.2.design carve still green end-to-end (no regression — the
      full suite + the ≥100 determinism loop, 100/100); the spec body is now reconciled to the as-built
      surface (this Stage-4 sync).

Stories: [`./emq.2.2.stories.md`](emq.2.2.stories.md) · Agent brief: [`./emq.2.2.llms.md`](emq.2.2.llms.md) ·
Runbook: [`./emq.2.2.prompt.md`](emq.2.2.prompt.md) · Carve + ADRs: [`./emq.2.design.md`](../emq.2.design.md)
(ADR-1 the carve, ADR-2 the parity/family boundary, ADR-3 the lock/stalled boundary) · Read plane (the
acceptance lens): [`./emq.2.1.md`](emq.2.1.md) · Roadmap: [`../emq.roadmap.md`](../../../emq.roadmap.md) (the
emq.2 ladder row) · Design: [`../emq.design.md`](../../../emq.design.md) §6 (the grammar + the
`metrics:`/`de:`/`job:<id>:logs` suffixes), §5 (the wire-class registry for the precondition refusals), §2
(the branded id at the key builder), §4/DQ-2c (the server clock on a lease), S-4 (Valkey the gate) ·
Capability reference: `echo/apps/echomq/lib/echomq/queue.ex` + `worker.ex` (the operator API),
`echo/apps/echomq/priv/scripts/{pause-7,drain-6,obliterate-2,updateData-1,updateProgress-3,addLog-2,removeJob-12,reprocessJob-8}.lua`
· As-built floor: `echo/apps/echo_mq/lib/echo_mq/{jobs.ex,lanes.ex,keyspace.ex,conformance.ex}` · Program
front door: [`../echo_mq.md`](../../../echo_mq.md) (the reframed emq.2 row) · Approach:
[`../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
