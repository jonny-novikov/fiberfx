# EMQ.2.2 · user stories

> Who wants the operator plane, what they need, and how acceptance is known. Derived from
> [`./emq.2.2.md`](emq.2.2.md) (BUILT — reconciled to the as-built surface this run; acceptance is the
> 32-scenario conformance run + the named `:valkey` drills, all green). The
> consumer ground is the bus's operators — a runbook pausing/draining a queue, a control plane obliterating
> a test queue, a worker rewriting a stuck job, an on-call removing a poisoned job, the conformance
> harness, and the watch plane (emq.2.3) whose events fire on these transitions. The capability ground is
> the v1 `echomq` operator API (`EchoMQ.Queue` lifecycle + `EchoMQ.Worker` mutations) and its operator
> scripts, ported onto `echo_mq`'s as-built four-set state machine (never the v1 set names). The acceptance
> lens is the read plane (emq.2.1): every mutation is asserted by reading the structure it changed.

## EMQ.2.2-US1 — stop the whole queue, then start it again

As an operator handling an incident, I want to pause and resume claiming on an entire queue, so that I can
stop work flowing while I investigate, then resume it — without touching the per-group lanes or losing the
backlog.

Acceptance criteria
- Given a queue with a non-empty pending set, when `pause/2` runs, then a subsequent claim answers **empty**
  (claiming is gated), and the pending set is unchanged (the backlog survives — emq.2.1's counts read the
  same pending depth before and after).
- Given a paused queue, when `resume/2` runs, then a subsequent claim serves the head of pending again
  (claiming restored).
- Given the queue-wide pause, when it runs, then it is **distinct** from `Lanes.pause/3`: it gates the whole
  queue, not one group; a per-group park is unaffected, and the paused flag is a §6-registered key or meta
  field, never a v1-shaped `wait`↔`paused` LIST rename (the bus has no LISTs).

INVEST — independent of the job mutations; testable by a `:valkey` suite that pauses then claims;
encodes EMQ.2.2-INV2, EMQ.2.2-INV3, EMQ.2.2-INV1.
Priority: must · Size: 5 · Implements deliverables: EMQ.2.2-D2.

## EMQ.2.2-US2 — empty a bad backlog

As an operator clearing a poisoned queue, I want to drain the pending backlog (and optionally the schedule),
so that I can discard waiting work and its rows without disturbing jobs already in flight.

Acceptance criteria
- Given a queue with pending and active jobs, when `drain/3` runs, then the `pending` set is emptied and
  each drained job's row and §6 `logs` subkey are deleted (emq.2.1's pending count reads zero), while the
  `active` jobs are **untouched** (they are in flight — their count is unchanged).
- Given drain with `include_schedule: true`, when it runs, then the `schedule` set is emptied too.
  **`[RECONCILE]`** the drain protects the repeat REGISTRY, not individual occurrences: it never deletes
  `emq:{q}:repeat` / `emq:{q}:repeat:<name>`, so a registered repeatable keeps producing after a drain (the
  as-built row stores no job→repeat backref, so an already-enqueued scheduled occurrence is just a job and
  drains with the `schedule` flag — EMQ.2.2-D3).
- Given the drain, when it runs, then it is ONE inline script declaring exactly the keys it touches, and
  each job key is derived from the declared queue root (INV4).

INVEST — independent of pause; testable by a `:valkey` suite with pending + active;
encodes EMQ.2.2-INV2, EMQ.2.2-INV3, EMQ.2.2-INV4.
Priority: must · Size: 5 · Implements deliverables: EMQ.2.2-D3.

## EMQ.2.2-US3 — destroy a queue entirely

As a control plane tearing down an ephemeral test queue, I want to obliterate a paused queue, so that every
structure and every job row is removed and the queue's keyspace footprint is gone.

Acceptance criteria
- Given a **paused** queue, when `obliterate/3` runs, then every as-built set
  (`pending`/`active`/`schedule`/`dead`) and the fixed-name §6 auxiliary keys
  (`metrics:*`, the lane structures `gactive`/`glimit`/`ring`/`wake`/`paused`-SET + each `g:<g>:pending`,
  `repeat` + each `repeat:<name>`, `limiter`, `meta` with the paused flag) and every reachable job row +
  its `:logs`/`:lock` subkeys are removed; the work is bounded per invocation by `budget` (it answers `:more`
  while work remains, `:ok` when done — the iterative capability). **`[RECONCILE]`** `de:*` dedup strings are
  NOT swept by obliterate (an orphaned `de:<did>` with no live referrer is not discoverable under declared
  keys — no `SCAN`; they are released at remove/drain time — EMQ.2.2-D4, the bounded-completeness limit).
- Given a queue that is **not paused**, when `obliterate/3` runs, then it refuses with the `EMQSTATE` class
  (`{:error, :not_paused}`) and changes nothing.
- Given a paused queue with live `active` jobs and no force flag, when `obliterate/3` runs, then it refuses
  with `EMQSTATE` (`{:error, :active}`) unless `force: true`; there is **no** `completed`/`failed` set to
  destroy (the metrics counters are the throughput record, deleted as §6 keys).

INVEST — independent of drain; testable by a `:valkey` suite that pauses then obliterates;
encodes EMQ.2.2-INV6, EMQ.2.2-INV3, EMQ.2.2-INV4.
Priority: must · Size: 5 · Implements deliverables: EMQ.2.2-D4.

## EMQ.2.2-US4 — rewrite a job's data in flight

As a worker (or an operator fixing a job's input), I want to replace a job's payload, so that I can correct
a job's data without re-enqueuing it.

Acceptance criteria
- Given a job in any state, when `update_data/4` runs, then the row's `payload` field is replaced (the v1
  `data` capability, `data` → the as-built `payload` field), and `get_job/3` (emq.2.1) reads the new
  payload.
- Given a missing job, when `update_data/4` runs, then it answers `{:error, :gone}` (the `-1` typed-absent
  sentinel — the `complete/4` convention, no wire class), changing nothing.
- Given the verb, when it runs, then it is a transition on the row (a declared key, no set move), and the
  branded id is gated at the key builder.

INVEST — independent of the other mutations; testable by a `:valkey` suite;
encodes EMQ.2.2-INV2, EMQ.2.2-INV5, EMQ.2.2-INV6.
Priority: should · Size: 2 · Implements deliverables: EMQ.2.2-D5.

## EMQ.2.2-US5 — record a job's progress

As a worker reporting progress (and a dashboard watching it through emq.2.3), I want to write a job's
progress field, so that a long-running job's advancement is visible and an event fires on each update.

Acceptance criteria
- Given a job, when `update_progress/4` runs, then the row's `progress` field is written (the
  `updateProgress-3` capability) and the **progress event** is emitted — `PUBLISH emq:{q}:events` of the
  `cjson` JSON object `{"event":"progress","job":"<id>","progress":"<value>"}` (the registered D-5 contract
  emq.2.3's subscription inherits; the event name rides the `event` field, one channel per queue). A
  subscriber-less PUBLISH is a no-op until emq.2.3 subscribes.
- Given a missing job, when `update_progress/4` runs, then it answers `{:error, :gone}`, changing nothing
  (including no phantom emit — the PUBLISH is after the existence check).
- Given the verb, when it runs, then it is a transition on the row, declared key, branded id gated.

INVEST — independent of update_data; testable by a `:valkey` suite (+ the event seam asserted at emq.2.3);
encodes EMQ.2.2-INV2, EMQ.2.2-INV5.
Priority: should · Size: 2 · Implements deliverables: EMQ.2.2-D6.

## EMQ.2.2-US6 — leave a diagnostic on a job, and read it back

As an operator debugging a job, I want to append a log line to a job and read its logs, so that a runbook
records what it did to a job and an investigator reads the trail.

Acceptance criteria
- Given a job, when `add_log/5` (`add_log(conn, queue, job_id, line, keep \\ 0)`) appends a line, then it
  lands on `emq:{q}:job:<id>:logs` (the §6 `logs` subkey) and the verb answers the log count; with a keep-N
  argument, the list is trimmed to the last N (the `addLog-2` capability).
- Given a job with logs, when `get_job_logs/3` reads it, then it answers the logs list in append order; a
  missing job answers `{:error, :gone}`, a job with no logs `{:ok, []}`.
- Given either verb, when it runs, then the `logs` key is declared and the branded id is gated at the key
  builder (INV5).

INVEST — independent of the row mutations; testable by a `:valkey` suite;
encodes EMQ.2.2-INV2, EMQ.2.2-INV4, EMQ.2.2-INV5.
Priority: should · Size: 3 · Implements deliverables: EMQ.2.2-D7.

## EMQ.2.2-US7 — remove one poisoned job

As an on-call removing a single bad job, I want to remove one job from the queue, so that a poisoned job
leaves every state structure and its row is deleted — unless a worker still holds it.

Acceptance criteria
- Given a job in some state, when `remove_job/4` runs, then it is removed from whichever set holds it
  (`ZREM` across `pending`/`active`/`schedule`/`dead`) and the row and §6 `logs` subkey are deleted — the
  `removeJob-12` capability re-derived (emq.2.1's `get_job_state` reads the job absent after).
  **`[RECONCILE]`** the dedup release takes a caller-supplied optional `dedup_id`: when supplied, `de:<dedup_id>`
  is released IFF its value `== this job id`; the as-built row stores no `deid` backref, so the held dedup
  key is the caller's to name (EMQ.2.2-D8).
- Given a **locked** job (`emq:{q}:job:<id>:lock` present — the §6 `lock` subkey the worker-side lock plane
  writes at emq.2.3), when `remove_job/4` runs, then it refuses with `EMQLOCK` (`{:error, :locked}`) and the
  job is **untouched** (the refusal is the first act). A missing job answers `{:error, :gone}`.
- Given the verb, when it runs, then the branded id is gated at the key builder and the removal is one inline
  script (INV2, INV4, INV5).

INVEST — independent of reprocess; testable by a `:valkey` suite (+ a locked-job drill setting the lock key);
encodes EMQ.2.2-INV6, EMQ.2.2-INV2, EMQ.2.2-INV5.
Priority: must · Size: 3 · Implements deliverables: EMQ.2.2-D8.

## EMQ.2.2-US8 — send a dead job back to be retried

As an operator who fixed a job's root cause, I want to reprocess a dead job, so that a dead-lettered job
returns to pending to be claimed again — but only a job that is actually dead.

Acceptance criteria
- Given a job in `dead`, when `reprocess_job/3` runs, then it moves to `pending`, the failure field
  (`last_error`) is cleared, and the row reads `state = pending` — the `reprocessJob-8` capability
  re-derived (`dead`→`pending`, the bus's only finished-and-retained state is `dead`; there is no
  `completed`/`failed` set to reprocess from). emq.2.1's `get_job_state` reads the job `pending` after.
- Given a job **not** in `dead` (pending/active/scheduled), when `reprocess_job/3` runs, then it refuses
  with `EMQSTATE not dead` (`{:error, :not_dead}`, an atomic `ZREM dead` no-op as the guard) and changes
  nothing; an absent job answers `{:error, :gone}`.
- Given a paused queue, when a job is reprocessed, then it lands in pending but stays unclaimable while
  paused (the D2 pause seam holds).

INVEST — independent of remove; testable by a `:valkey` suite that dead-letters then reprocesses;
encodes EMQ.2.2-INV6, EMQ.2.2-INV2, EMQ.2.2-INV3.
Priority: must · Size: 3 · Implements deliverables: EMQ.2.2-D9.

## EMQ.2.2-US9 — the design gate before any build

As the Operator, I want the operator-plane design — the module placement, the queue-wide pause mechanism,
the `EMQ*` refusal class words, and the drain/obliterate scope, with steelmanned alternatives — recorded
BEFORE any build story runs, so that the rung mutates `echo_mq`'s real four-set structures and invents no
v1-shaped state.

Acceptance criteria (the gate closed at the build's ledger — D-1..D-4 recorded before any artifact)
- Given the design gate, the build recorded (a) the placement: a new `EchoMQ.Admin` for the queue-scope
  verbs, the job mutations on `EchoMQ.Jobs` (all-on-`Jobs` and a single `EchoMQ.Operator` steelmanned,
  rejected); (b) the queue-wide pause mechanism: a `meta.paused` field gated FORM (b) — both claim paths read
  it first; the gate-in-`@claim` form (a) and a dedicated `qpaused` key steelmanned, rejected (so
  `@claim`/`@gclaim` stay byte-unchanged); (c) the `EMQ*` class words spelled against §5: TWO — `EMQLOCK` and
  `EMQSTATE` (one-class and per-refusal-word alternatives steelmanned, rejected); (d) the drain/obliterate
  scope: the as-built four sets + the §6 keys (NOT the v1 list); every key spelled against §6; no `.ex`/Lua
  artifact predated the ledger entry.
- Given the approved design, when the build landed, then the declared-keys (A-1) analysis passed over every
  new mutation script (each `KEYS[]`-rooted or grammar-derived from a declared root).

INVEST — the opening story, blocking all build stories; testable from the ledger + the analysis run;
encodes EMQ.2.2-INV8, EMQ.2.2-INV4.
Priority: must · Size: 3 · Implements deliverables: EMQ.2.2-D1.

## EMQ.2.2-US10 · EMQ.2.2-US-GATE — the Valkey gate, specification by example

As the Operator, I want every emq.2.2 mutation registered with a conformance probe and proven against the
truth row, so that the protocol grows by additive minors only and the mutation verdicts stay a parse, not
prose.

Acceptance criteria
- Given the build, when the conformance suite runs against Valkey on 6390, then the prior **24** scenarios
  pass byte-unchanged and the **8** new operator scenarios (`queue_pause`, `drain`, `obliterate`,
  `update_data`, `update_progress`, `job_logs`, `remove_job`, `reprocess_job`) pass beside them — the
  registry grows additively (**24 → 32**), the new `EMQLOCK`/`EMQSTATE` classes are registered with probes,
  and `EchoMQ.Conformance.run/2` answers `{:ok, 32}`.
- Given a host without the truth row, when probes run elsewhere, then results report as that row, never as
  the truth row (honest-row reporting — design §1 S-4); the five-code fence union stands unextended.

INVEST — standing (the design §7 per-rung twin); testable by one tagged conformance run;
encodes EMQ.2.2-INV1, EMQ.2.2-INV6.
Priority: must · Size: 2 · Implements deliverables: EMQ.2.2-D10.

---
Coverage: D1→US9 · D2→US1 · D3→US2 · D4→US3 · D5→US4 · D6→US5 · D7→US6 · D8→US7 · D9→US8 · D10→US10.
Spec: [`./emq.2.2.md`](emq.2.2.md) ·
Carve: [`./emq.2.design.md`](../emq.2.design.md) · Read plane (the acceptance lens):
[`./emq.2.1.md`](emq.2.1.md).
