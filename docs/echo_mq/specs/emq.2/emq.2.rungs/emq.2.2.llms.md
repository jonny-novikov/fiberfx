# EMQ.2.2 · the agent brief (LLM build brief)

> The build-grade brief Mars built emq.2.2 from and the Operator/verifier accepted against. Derived from
> [`./emq.2.2.md`](emq.2.2.md) (the spec body — **authoritative**; this brief and the stories derive from
> it, and when they disagree the body wins) and the carve [`./emq.2.design.md`](../emq.2.design.md).
> **Reconciled to the as-built surface this run** — the design-make resolutions, the three
> realization-over-literal re-derivations, and the conformance count are folded; the `[RECONCILE]` markers
> name each place the as-built shipped a different mechanism than the literal spec. Framing: no gendered
> pronouns for agents; no perceptual or interior-state verbs for agents or software (components read,
> compute, refuse, return); no first-person narration. Enforce these same rules in any downstream prompt.

## References (read first, in order)

1. **The carve + the ADRs** — [`./emq.2.design.md`](../emq.2.design.md): ADR-0 (no migration — built fresh),
   ADR-1 (the carve: emq.2.2 = the operator plane, second because its mutations change the state the read
   plane observes), ADR-2 (the parity/family boundary — emq.2.2 ships the operator floor, NOT the batch
   *consume* family (emq.5), NOT the **distributed** cancel/checkpoints (emq.6)), ADR-3 (the lock/stalled
   boundary — the worker-side lock plane is emq.2.3; emq.2.2 only *reads* the `lock` subkey for the remove
   refusal).
2. **The spec body** — [`./emq.2.2.md`](emq.2.2.md): Goal · 5W · Scope · D1–D10 · INV1–INV8 · DoD.
3. **The read plane (the acceptance lens)** — [`./emq.2.1.md`](emq.2.1.md): emq.2.1's `get_counts`,
   `get_job`/`get_job_state`, `get_metrics` are how every emq.2.2 mutation is asserted (a drained queue
   reads pending zero; a reprocessed job reads `pending`). Build emq.2.2 *after* emq.2.1; use its reads as
   the test lens.
4. **The as-built floor (the structures emq.2.2 mutates)** — RE-PROBE each at build time (the lag-1 law;
   earlier emq.* builds move the surface):
   - `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — the three-field row (`HSET … 'state','attempts','payload'`),
     the four sets `pending`/`active`/`schedule`/`dead`, the 7 inline `Script.new/2` transitions
     (`@enqueue`/`@schedule`/`@claim`/`@complete`/`@retry`/`@promote`/`@reap`). **`complete/4` DELETES the
     row everywhere — there is no `completed`/`failed` set.** `@claim` is `ZPOPMIN` on `pending` — the
     queue-wide pause gate (D2) attaches here or before it (D1's ruling).
   - `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` — `queue_key/2` (`emq:{q}:<type>`), `job_key/2` (gated by
     `BrandedId.valid?/1` — RAISES on an ill-formed id), `reserve/1` (`{emq}:`), the §6 grammar.
   - `echo/apps/echo_mq/lib/echo_mq/lanes.ex` — `pause/3`/`resume/3`/`limit/4`/`depth/2` — the
     **per-group** lifecycle (SADD `paused` set + LREM `ring`). emq.2.2's **queue-wide** pause is DISTINCT:
     it gates the whole claim, not one group. Do NOT reuse or collide with `Lanes`' `paused` set/ring.
   - `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — **24 scenarios as-built** (`scenarios/0` — the 18
     state-machine `fence:…resubscribe:` + emq.2.1's 6 read scenarios `counts`/`state`/`metrics`/`dedup`/
     `rate`/`lane_depth`); `run/2 → {:ok, 32}` as-built (the 8 operator scenarios registered beside them; the
     24 pass byte-unchanged, count re-pinned 24 → 32 in both pinning tests). **`[RECONCILE]`** the lag-1
     correction: the triad was authored saying "18 prior" but emq.2.1 had already grown the set to 24 by the
     time emq.2.2 built. (NOTE: the `conformance.ex` moduledoc prose still reads "eighteen runnable
     scenarios" — that is CODE prose, a cosmetic drift flagged for the Director/Mars, not edited here.)
   - `echo/apps/echo_mq/lib/echo_mq/repeat.ex` — `EchoMQ.Repeat` over `emq:{q}:repeat` — the drain
     scheduled-by-repeat guard (a repeat-owned scheduled job survives a drain).
   - `echo/apps/echo_wire/lib/echo_wire.ex` — the facade (`eval/5`); mutation scripts run through
     `Connector.eval`/`Pool.eval`. Expect **no** facade change unless the pause gate is realized inside
     `@claim` and the build needs a new delegate (it should not).
5. **The capability reference (the v1 operator API to port — NEVER migrated from, NEVER literally copied)** —
   `echo/apps/echomq/lib/echomq/queue.ex` (the lifecycle verbs `pause`/`resume`/`drain`/`obliterate`/
   `remove_job`/`reprocess`/`update_meta`) + `echo/apps/echomq/lib/echomq/worker.ex` (the mutations
   `update_progress`/`log`/`update_data`) + the operator scripts
   `echo/apps/echomq/priv/scripts/{pause-7,drain-6,obliterate-2,updateData-1,updateProgress-3,addLog-2,removeJob-12,reprocessJob-8}.lua`.
   **These root keys in data values** (`root .. "j:" .. jobId`) **and use set model**
   (`wait`/`paused`-LIST/`completed`/`failed`/`prioritized`/`waiting-children`) — emq.2.2 re-derives the
   *capability* against `echo_mq`'s real four sets + declared keys, it does NOT port the v1 form or the v1
   state list. The v1 `data` field → the as-built `payload` field.
6. **The canon** — [`../emq.design.md`](../../../emq.design.md): §6 (the grammar + the
   `metrics:`/`de:`/`job:<id>:logs` suffixes — `logs` is a registered `sub` member; drain/obliterate touch
   the registered sets + these suffixes, no new type), §5 (the closed wire-class registry — every
   precondition refusal's `EMQ*` class is an additive minor with a probe; the five-code fence union stands),
   §2 (the branded id gated at the key builder), §4/DQ-2c (the server clock on a lease), S-4 (Valkey the
   gate), §11.11 (the no-release ground).
7. **The shape precedent** — [`./emq.2.1.md`](emq.2.1.md) + [`./emq.2.1.llms.md`](emq.2.1.llms.md) +
   [`./emq.2.1.prompt.md`](emq.2.1.prompt.md) (the triad + brief + runbook shape; the inline-`Script.new/2`
   convention; the design-make-as-relocated-gate) and [`./emq.1.md`](../../emq.1/emq.1.md) (the transition-script
   precedent — `@schedule`/`@retry` as the model for a real mutation under the v2 laws).

## Requirements (each traced back to a story, forward to an invariant/check)

| # | Requirement | From | To |
| --- | --- | --- | --- |
| R1 | Queue-wide `pause/2`/`resume/2` set/clear a paused flag the claim path honors (a paused queue claims empty with a non-empty pending), DISTINCT from `Lanes.pause/3`'s per-group park | US1 | INV2, INV3, INV1 · the pause scenario |
| R2 | `EchoMQ.Admin.drain/3` empties `pending` (+ optional `schedule`), deletes each drained job's row + §6 `logs` subkey, leaves `active` intact; one inline script, keys derived from the declared queue root. **`[RECONCILE]`** keeps the repeat REGISTRY (never deletes `emq:{q}:repeat`/`repeat:<name>`), not individual occurrences — the as-built row stores no job→repeat backref (D3) | US2 | INV2, INV3, INV4 · the drain scenario |
| R3 | `EchoMQ.Admin.obliterate/3` destroys a **paused** queue (the four sets + the fixed-name §6 keys `metrics:*`/lane structures/`repeat`+`repeat:<name>`/`limiter`/`meta` + reachable rows), bounded by `budget` (`:more`/`:ok`); refuses non-paused / live-active (unless `force`) with `EMQSTATE`. **`[RECONCILE]`** `de:*` released at remove/drain time, not swept by obliterate (no `SCAN` under declared keys — D4) | US3 | INV6, INV3, INV4 · the obliterate scenario |
| R4 | `update_data/4` replaces the row's `payload` field (v1 `data` → `payload`); a missing job refuses typed; a transition on the row, branded id gated | US4 | INV2, INV5, INV6 · the update scenario |
| R5 | `EchoMQ.Jobs.update_progress/4` writes the row's `progress` field + emits the progress event — `PUBLISH emq:{q}:events` of `cjson.encode({event="progress", job, progress})` (the registered D-5 contract emq.2.3 inherits; no §6 key type, no new transport — rides the connector RESP3 seam); a missing job → `{:error, :gone}` (no phantom emit) | US5 | INV2, INV5 · the progress scenario |
| R6 | `add_log/4` appends to `emq:{q}:job:<id>:logs` (§6 `logs` subkey) with optional keep-N + returns the count; `get_job_logs/3` reads the list; a missing job refuses typed; keys declared, id gated | US6 | INV2, INV4, INV5 · the log scenario |
| R7 | `EchoMQ.Jobs.remove_job/4` removes a job from whichever set holds it (`ZREM` ×4) + deletes the row + §6 `logs` subkey; refuses a **locked** job (the `:lock` subkey present) with `EMQLOCK` (refuse-first). **`[RECONCILE]`** releases a dedup key via a caller-supplied optional `dedup_id` (`de:<dedup_id>` IFF its value == this id) — the as-built row stores no `deid` backref (D8) | US7 | INV6, INV2, INV5 · the remove scenario |
| R8 | `reprocess_job/3` moves a `dead` job to `pending` (clears `last_error`, sets `state = pending`); refuses a job **not in `dead`** with an `EMQ*` class; honors the pause flag | US8 | INV6, INV2, INV3 · the reprocess scenario |
| R9 | The operator-plane design recorded first: module placement; the queue-wide pause mechanism (≥2 steelmanned alternatives); the `EMQ*` class word(s) against §5; the drain/obliterate scope (as-built sets + §6 keys, NOT the v1 list); every key against §6 | US9 | INV8, INV4 · the ledger |
| R10 | Every mutation declares its keys or grammar-derives them; the new `EMQLOCK`/`EMQSTATE` classes registered with probes; the conformance registry grows additively; **the 24 prior scenarios byte-unchanged, the 8 new register beside them (count re-pins 24 → 32 in both pinning tests)**; honest-row reporting; the server clock binds any lease-touching verb (vacuous — none does) | US10 | INV1, INV6, INV7 · the conformance run |

## Execution topology

**Runtime shape (as-built).** A queue-scope operator module above the wire — `EchoMQ.Admin` (the queue-scope
verbs pause/resume/drain/obliterate) — plus the job-mutation verbs
(update_data/update_progress/add_log/get_job_logs/remove_job/reprocess_job) on `EchoMQ.Jobs` beside the
state machine they extend. Each verb runs ONE inline-`Script.new/2` script through `Connector.eval` (the
as-built transport); each script declares its keys in `KEYS[]` or derives them from the declared queue root.
**No new process** (operator verbs are synchronous transitions — the worker-side lock-tracking process is
emq.2.3). The queue-wide pause is the one verb that gates a *future* transition (claim) — **`[RECONCILE]`**
realized as FORM (b): a `meta.paused` field that both `EchoMQ.Jobs.claim/3` and `EchoMQ.Lanes.claim/3` read
FIRST (via `Jobs.paused?/2`) and short-circuit to empty; the shipped `@claim`/`@gclaim` scripts are
byte-unchanged (the gate-in-`@claim` form was steelmanned and retired — it would have edited emq.1's shipped
script).

**Build-order task DAG.**
1. **D1 design-make (gate — RESOLVED at the build's ledger D-1..D-4)** — adopt the carve (ADR-1); module
   placement = `Admin` (queue-scope) + `Jobs` (mutations); queue-wide pause = FORM (b), a `meta.paused` field
   both claim paths read first (the `@claim`-gate form steelmanned, rejected); `EMQ*` refusal classes =
   `EMQLOCK` (held-job) + `EMQSTATE` (not-paused / live-active / not-dead); drain/obliterate scope = the
   as-built sets + the §6 keys (NOT the v1 list). Logged as `tool_x_decision`s before any artifact (INV8).
2. **D2 queue-wide pause/resume** → the `meta.paused` field (`@pause`/`@resume` on `Admin`) + the `paused?/2`
   gate both `Jobs.claim/3` and `Lanes.claim/3` read first (FORM b — `@claim`/`@gclaim` byte-unchanged).
3. **D3 drain** → the drain script over `pending` (+ optional `schedule`), the repeat guard (depends on D1's
   scope; independent of D2).
4. **D4 obliterate** → the iterative obliterate over the four sets + §6 keys, the not-paused / live-active
   refusals (depends on D1's scope + the pause flag from D2 — obliterate requires paused).
5. **D5 update_data** → the payload-replace transition (independent).
6. **D6 update_progress** → the progress write + the event seam (independent; the event contract registered
   here, the subscription at emq.2.3).
7. **D7 add_log / get_job_logs** → the logs append/read over the §6 `logs` subkey (independent).
8. **D8 remove_job** → the multi-set remove + dedup release + the locked-job refusal (depends on D1's class
   word; reads the `:lock` subkey).
9. **D9 reprocess_job** → the `dead`→`pending` move + the not-dead refusal (depends on D1's class word + the
   pause flag from D2).
10. **D10 proof** → the 8 conformance scenarios + probes (one per verb); `EMQLOCK`/`EMQSTATE` registered;
    pure + `:valkey` suites; the 24 prior byte-unchanged; count re-pinned 24 → 32 in both pinning tests.

**Exact files touched (as-built — the build's actual touch-set: 3 new + 5 edited, all under `echo/apps/echo_mq/`):**
- `echo/apps/echo_mq/lib/echo_mq/admin.ex` — **NEW** (the queue-scope verbs pause/resume/drain/obliterate +
  their inline `@pause`/`@resume`/`@drain`/`@obliterate` scripts).
- `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — **EDIT** (+243): the six job-mutation verbs
  (update_data/update_progress/add_log/get_job_logs/remove_job/reprocess_job) + their inline scripts; a
  `paused?/2` reader; the `claim/3` pause-gate wrapper (FORM b — the `@claim` SCRIPT byte-unchanged; only the
  Elixir wrapper short-circuits when paused).
- `echo/apps/echo_mq/lib/echo_mq/lanes.ex` — **EDIT** (+27): `claim/3` honors the queue-wide pause
  (`EchoMQ.Jobs.paused?/2` first — a queue-wide pause stops grouped claims too); `@gclaim` byte-unchanged.
- `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` — **EXCLUDED** (the paused flag is a `meta` field — no
  keyspace change).
- `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — **EDIT** (+170/−4): 8 new scenarios in `scenarios/0` +
  their `apply_scenario` clauses; alias adds `Admin`; the run/2 doc count 24 → 32. The 24 prior scenarios are
  byte-unchanged. (**NOTE:** the moduledoc prose still says "eighteen runnable scenarios" — a CODE cosmetic
  drift flagged for the Director/Mars, not edited at Stage 4.)
- `echo/apps/echo_mq/test/` — the new `admin_test.exs` + `jobs_ops_test.exs` (the AS-2..AS-9 drills) + the
  count re-pin in `conformance_scenarios_test.exs` (the 32-name `@run_order`) + `conformance_run_test.exs`
  (`{:ok, 32}`).
- `echo/apps/echo_wire/lib/echo_wire.ex` — **EXCLUDED** (FORM b needed no delegate; mutations run through the
  existing `eval`).
- **`apps/echomq` untouched** (the capability reference). No third app touched. `echo/mix.lock` carries no
  emq.2.2 dep change.

## Agent stories (Directive + Acceptance gate — contracts, not tasks)

- **AS-1 — the design-make (the relocated gate — CLOSED at the build's ledger D-1..D-4).** *As-built:* the
  carve (ADR-1) adopted; placement = `Admin` (queue-scope) + `Jobs` (mutations); pause = FORM (b), a
  `meta.paused` field both claim paths read first (≥2 alternatives steelmanned: the gate-in-`@claim` form and
  a dedicated `qpaused` key, rejected); the `EMQ*` class words = `EMQLOCK` + `EMQSTATE` (one-class and
  per-refusal-word steelmanned, rejected); the drain/obliterate scope = the as-built four sets + the §6 keys
  (NOT the v1 list); every key spelled against §6. *Acceptance gate:* each recorded as a `tool_x_decision`
  before any `.ex`/Lua artifact — INV8 held (the ledger's D-1..D-4 precede the build artifacts).
- **AS-2 — queue-wide pause/resume.** *As-built:* `EchoMQ.Admin.pause/2`/`resume/2` set/clear the
  `meta.paused` field; both `EchoMQ.Jobs.claim/3` and `EchoMQ.Lanes.claim/3` read it first (via
  `Jobs.paused?/2`) — FORM (b), `@claim`/`@gclaim` byte-unchanged; DISTINCT from `Lanes.pause/3` (the
  per-group `paused` set/ring untouched). *Acceptance gate:* a paused queue with a non-empty pending claims
  **empty** (flat AND grouped); resume restores claiming; the pending set is unchanged by pause (emq.2.1's
  count reads the same); the `queue_pause` scenario passes (INV2, INV3, INV1).
- **AS-3 — drain.** *As-built:* `EchoMQ.Admin.drain/3` empties `pending` (+ optional `schedule`), deletes
  each drained job's row + §6 `logs` subkey, leaves `active` intact; one inline `@drain` script with keys
  derived from the declared queue root. **`[RECONCILE]`** the repeat REGISTRY survives (`@drain` never
  deletes `repeat`/`repeat:<name>`); individual already-enqueued occurrences drain like any scheduled job
  (the row stores no job→repeat backref). *Acceptance gate:* drain leaves pending zero and active intact
  (emq.2.1's counts); `include_schedule: true` empties schedule; the registry survives a drain; the script's
  derived keys pass the A-1 analysis; the `drain` scenario passes (INV2, INV3, INV4).
- **AS-4 — obliterate.** *As-built:* `EchoMQ.Admin.obliterate/3` destroys a **paused** queue (the four sets +
  the fixed-name §6 keys + reachable rows), bounded by `budget` (`:more`/`:ok`); refuses a non-paused queue
  (`EMQSTATE not paused` → `:not_paused`) and a live-active queue (unless `force`, `EMQSTATE active` →
  `:active`), refuse-first. *Acceptance gate:* a paused queue obliterates to every set empty; a non-paused
  queue refuses changing nothing; a live-active queue refuses unless forced; no `completed`/`failed` set is
  touched (none exists); `de:*` is not swept (the bounded-completeness limit); the `obliterate` scenario
  passes (INV6, INV3, INV4).
- **AS-5 — update_data.** *As-built:* `EchoMQ.Jobs.update_data/4` replaces the row's `payload` field (v1
  `data` → `payload`); a missing job answers `{:error, :gone}` (the `-1` typed-absent); one inline script,
  branded id gated. *Acceptance gate:* a job's payload is replaced and `get_job/3` (emq.2.1) reads the new
  payload; a missing job answers `{:error, :gone}`; an ill-formed id raises at the key builder; the
  `update_data` scenario passes (INV2, INV5, INV6).
- **AS-6 — update_progress.** *As-built:* `EchoMQ.Jobs.update_progress/4` writes the row's `progress` field +
  `PUBLISH emq:{q}:events` of `cjson.encode({event="progress", job, progress})` (the registered D-5 contract
  emq.2.3 inherits — no §6 key type, no new transport); a missing job answers `{:error, :gone}`. *Acceptance
  gate:* a job's progress is written; the emit is asserted through a bounded-receive subscriber seam
  (deterministic, ≥100-loop-safe); a missing job answers `{:error, :gone}` with NO phantom emit; the
  `update_progress` scenario passes (INV2, INV5).
- **AS-7 — add_log / get_job_logs.** *As-built:* `EchoMQ.Jobs.add_log/5`
  (`add_log(conn, queue, job_id, line, keep \\ 0)`) appends to `emq:{q}:job:<id>:logs` (the §6 `logs` subkey)
  with optional keep-N + returns the count, and `get_job_logs/3` reads the list; a missing job answers
  `{:error, :gone}`; the `logs` key declared, the id gated. *Acceptance gate:* a logged line lands on the
  `logs` list and `get_job_logs` reads it in order; keep-N trims to the last N; a missing job answers
  `{:error, :gone}`; the `job_logs` scenario passes (INV2, INV4, INV5).
- **AS-8 — remove_job.** *As-built:* `EchoMQ.Jobs.remove_job/4` removes a job from whichever set holds it
  (`ZREM` ×4) + deletes the row + §6 `logs` subkey; refuses a **locked** job (the `:lock` subkey present)
  with `EMQLOCK` → `:locked` (refuse-first); one inline script, id gated. **`[RECONCILE]`** the dedup release
  takes a caller-supplied optional `dedup_id` (`de:<dedup_id>` released IFF its value == this id) — the
  as-built row stores no `deid` backref. *Acceptance gate:* an unlocked job is removed from its set and reads
  absent (emq.2.1's `get_job_state`); a locked job refuses with `:locked` and is untouched; a caller-supplied
  dedup key is released; a missing job answers `{:error, :gone}`; the `remove_job` scenario passes
  (INV6, INV2, INV5).
- **AS-9 — reprocess_job.** *As-built:* `EchoMQ.Jobs.reprocess_job/3` moves a `dead` job to `pending`
  (clearing `last_error`, setting `state = pending`); refuses a job **not in `dead`** with `EMQSTATE not
  dead` → `:not_dead` (an atomic `ZREM dead` no-op as the guard); honors the pause seam. *Acceptance gate:*
  a dead job moves to pending and `get_job_state/3` reads `pending`; a non-dead job refuses with `:not_dead`
  (changing nothing); a reprocessed job stays unclaimable while paused; the `reprocess_job` scenario passes
  (INV6, INV2, INV3).
- **AS-10 — proof.** *Directive:* register a conformance scenario + probe for every operator verb (the 8 —
  `queue_pause`/`drain`/`obliterate`/`update_data`/`update_progress`/`job_logs`/`remove_job`/`reprocess_job`);
  register `EMQLOCK`/`EMQSTATE` with their probes; run pure + `:valkey` suites; keep the 24 prior scenarios
  byte-unchanged; re-pin the count 24 → 32 in both pinning tests; report honest-row. *Acceptance gate:*
  `EchoMQ.Conformance.run/2` answers `{:ok, 32}`, the 24 prior verdicts identical; `EMQLOCK`/`EMQSTATE`
  registered; Valkey on 6390 the truth row; the five-code fence union unextended (INV1, INV6, INV7).

## The comprehensive prompt (leaves no decision the spec has not fixed)

Build emq.2.2 — the bus's **operator plane** — inside `echo/apps/echo_mq`, to [`./emq.2.2.md`](emq.2.2.md)
(authoritative) and the carve [`./emq.2.design.md`](../emq.2.design.md), under the v2 master invariant
(braced `emq:{q}:` · branded `JOB` ids gated at the key builder · every Lua key declared-or-rooted · server
clock where a lease is touched · honest-row conformance · additive-minor protocol). FIRST run the
design-make (AS-1): rule the module placement (recommended: a new `EchoMQ.Admin` for the queue-scope verbs
pause/resume/drain/obliterate; the job mutations fold onto `EchoMQ.Jobs`); rule the queue-wide pause
mechanism — a paused flag the claim path honors, realized either inside the as-built `@claim` script (atomic
— then re-run the `claim` conformance scenario byte-for-byte to prove INV1) or as a separate gate the public
`claim/3` reads first (≥2 steelmanned alternatives); spell the `EMQ*` refusal class word(s) against §5 for
the precondition failures (locked job, not-paused, live-active, not-dead) and register each with a
conformance probe; rule the drain/obliterate scope as `echo_mq`'s **as-built** sets
(`pending`/`active`/`schedule`/`dead`) + the §6-registered auxiliary keys
(`metrics:*`/`de:*`/`job:<id>:logs`/the lane structures/`repeat`/the paused flag), NOT the v1 `drain`/
`obliterate` set list (`wait`/`paused`-LIST/`completed`/`failed`/`prioritized`/`waiting-children`), because
the bus has those four sets and completion-deletes leave **no `completed`/`failed` set**. The v1 `echomq`
operator API + scripts are the **capability reference** — what to port — never a literal copy and never a
thing migrated from; the v1 `data` field is the as-built `payload` field. Build the verbs as **real
transitions**, each ONE inline `Script.new/2` script (there is **no `priv/`** in `echo_mq`): queue-wide
pause/resume distinct from `Lanes.pause/3` (D2), drain leaving active intact (D3), obliterate refusing
non-paused / live-active (D4), update_data on the payload (D5), update_progress + the event seam (D6),
add_log/get_job_logs over the §6 `logs` subkey (D7), remove_job refusing a locked job (D8), reprocess_job
`dead`→`pending` refusing a non-dead job (D9). Every job-targeted verb gates the id with `BrandedId.valid?/1`
at the key builder (INV5); every script declares its keys in `KEYS[]` or grammar-derives them from the
declared queue root (INV4); every precondition refusal leads with its `EMQ*` class via `redis.error_reply`,
mapped client-side to a typed atom, and **changes nothing** (INV6); the server clock binds any lease-touching
verb (INV7, vacuous where none touches a lease). Register a conformance scenario + probe for every verb in
the same change and register `EMQLOCK`/`EMQSTATE` with probes (the additive-minor law); the **24 prior
scenarios pass byte-unchanged** and the count re-pins 24 → 32 in both pinning tests. Compile clean
(`--warnings-as-errors`, per-app); pure + `:valkey` suites green (`TMPDIR=/tmp`, Valkey 6390 PONG first);
the mutation verdicts asserted through emq.2.1's read lens; honest-row reporting. Keep the diff inside
`echo_mq` (+ a facade delegate only if proven needed — expect none); `apps/echomq` is untouched. Cite the
spec/design line for every public call; invent no operator surface, no state name, no key the design §6
grammar does not register, no `EMQ*` class outside §5's additive-minor rule; report any
realization-over-literal deviation. Author DOCS-free code (the spec is the doc); run no git.

---
The contract: [`./emq.2.2.md`](emq.2.2.md). The stories: [`./emq.2.2.stories.md`](emq.2.2.stories.md).
The runbook: [`./emq.2.2.prompt.md`](emq.2.2.prompt.md). The carve: [`./emq.2.design.md`](../emq.2.design.md).
The read plane (the acceptance lens): [`./emq.2.1.md`](emq.2.1.md). The canon:
[`../emq.design.md`](../../../emq.design.md). The capability reference: `echo/apps/echomq/lib/echomq/queue.ex` +
`worker.ex` + the operator scripts. The as-built floor:
`echo/apps/echo_mq/lib/echo_mq/{jobs,lanes,keyspace,conformance}.ex`.
