# EMQ.5.2 — the Mars brief (the `min_size`/`timeout` batch shaping — the self-pacing batch consumer)

> The compact build brief. The body [`emq.5.2.md`](emq.5.2.md) is authoritative; the acceptance is
> [`emq.5.2.stories.md`](emq.5.2.stories.md); the run scope is [`emq.5.2.prompt.md`](emq.5.2.prompt.md). Build
> ONLY inside `echo/apps/echo_mq` (the cadence rides the shipped `@bclaim`/`claim_batch/4` — NO new Lua, NO
> `echo_wire` edit). Cite the spec line for every public call; emq.5.2 adds NO `Script.new/2` (it CALLS the
> byte-frozen host fns); the shaping core is PURE (an injected clock — the `EchoMQ.Pump.Core` discipline); the
> conformance additive-minor mechanics.
>
> **Framing law (propagated).** Third person for any agent; no gendered pronouns for agents; no perceptual or
> interior-state verbs for agents or software (components read, compute, refuse, return); no first-person
> narration. Bind this same clause in any sub-brief.

## References (read first — the exact upstream, links/paths first)

1. **The body** — [`emq.5.2.md`](emq.5.2.md): Goal · Scope · INV-NoLua/Boundary/PureCore/Floor+Ceiling/ClaimPath/
   PartialFailure/Conf/Events · the settled design decisions (D1 watch-depth · D2 ceiling-wins · D3 per-member
   events) · the forks (5.2-A the home / 5.2-B the handler contract) · the conformance posture · DoD. **The two
   forks were RULED** — FORK 5.2-A → **D-1: a NEW `EchoMQ.BatchConsumer`** (a sibling of `EchoMQ.Consumer`, NOT a
   mode); FORK 5.2-B → **D-2: a per-member verdict map** `%{id => :ok | {:error, reason}}` (an absent member
   fail-safe retries `"missing verdict"`); the count → **D-3: +3 → 67**. Build to the ruled arms. *(This brief is
   retained as the build record; the rung SHIPPED — Director-verified BUILD-GRADE.)*
2. **The spine to RIDE + BYTE-FREEZE (SHIPPED)** — `echo/apps/echo_mq/lib/echo_mq/jobs.ex`:
   - `claim_batch/4` (`jobs.ex:520-539`) — `claim_batch(conn, queue, size, lease_ms) when is_integer(size) and
     size > 0 and is_integer(lease_ms) and lease_ms > 0`; `if paused?(conn, queue) -> :empty` (FIRST); evals
     `@bclaim` over keys `[queue_key(q,"pending"), queue_key(q,"active")]` + argv `[queue_key(q,"job:"),
     lease_ms, size]`; `{:ok, []} -> :empty`, `{:ok, members} -> {:ok, Enum.map(members, &List.to_tuple/1)}`. **The
     flush call** — the cadence calls this ONCE per flush for the decided `size`. **BYTE-FROZEN.**
   - `@bclaim` (`jobs.ex:200-219`) — the count-variant `ZPOPMIN emq:{q}:pending` loop, one `TIME`, one batch lease,
     per-member attempts. **BYTE-FROZEN** (emq.5.2 adds no Lua — `grep redis.call` on the lib diff = 0).
   - `pending_size/2` (`jobs.ex:863-866`) — `Connector.command(conn, ["ZCARD", queue_key(q, "pending")])`. **The
     WATCH-DEPTH primitive** — a PURE READ of the pending depth (no claim, no lease tick). The cadence reads THIS
     to decide whether the floor is met (D1). **BYTE-FROZEN.**
   - `complete/5` (`jobs.ex:589`) — `complete(conn, queue, job_id, token, result \\ nil)`; `retry/7` (`jobs.ex:759`)
     — `retry(conn, queue, job_id, token, delay_ms, max_attempts, error)`. **BYTE-FROZEN** — the per-member
     resolution the batch handler's verdict maps to (the standalone `drain/1` settle, `consumer.ex:155-161`,
     generalized to a batch).
   - `paused?/2` (`jobs.ex:482`) — consulted FIRST inside `claim_batch/4` (a paused queue → `:empty`).
3. **The pure-core PRECEDENT to FOLLOW (SHIPPED)** — `echo/apps/echo_mq/lib/echo_mq/pump/core.ex`: `tick_ms/1`
   (`pump/core.ex:24-29`) + `batch/1` (`pump/core.ex:42-47`) — PURE fns of the start options, NO process/clock/I/O,
   `@default_tick_ms`/`@default_batch` module attrs, a non-positive value `raise ArgumentError`, DOCTESTED
   (`pump/core.ex:18-21,36-39`). **`EchoMQ.BatchShaper.Core` is the ISOMORPH** — a pure flush-decision over (depth,
   elapsed, min_size, timeout), the same validation discipline, doctested.
4. **The lifecycle PRECEDENT (SHIPPED)** — `echo/apps/echo_mq/lib/echo_mq/consumer.ex` (257 lines):
   - `child_spec/1` (`consumer.ex:28-35`), `start_link/1` (`consumer.ex:52-89` — the `:conn`/`:connector` exclusive
     lane setup at `:60-68`; the `:queue`/`:handler`/`:lease_ms`/`:beat_ms`/`:retry_delay_ms`/`:max_attempts`
     options at `:70-80`), `stop/2` (`consumer.ex:101-112` — drain-and-stop), `check_control/0` (`consumer.ex:127`
     — control honored at settle points, between jobs never inside one).
   - **The TWO shipped modes** (BOTH claim via `Lanes.claim/3` → `{id, payload, att, group}`, the GROUPED ring):
     the standalone `loop/1` (`consumer.ex:114-121` — reap→promote→`drain/1`→park); the emq.4.3 `metronome_loop/1`
     (`consumer.ex:185-188` — register_idle→await_poke→`claim_once/1`, dispatched off the `:metronome` opt-in at
     `consumer.ex:82-85`). **The `:metronome` opt-in is the EXACT third-mode precedent** for FORK 5.2-A Arm A (a
     third dispatch off `start_link` on an opt-in option).
   - The per-job handler shape (the precedent the batch handler generalizes): `s.handler.(%{id:, payload:,
     attempts:, group:})` → `:ok | {:error, reason}`, mapped to `Jobs.complete`/`Jobs.retry` (`consumer.ex:144-161`);
     the rescue/catch hardening (`consumer.ex:146-153` — a raising handler converts to a retry, Chapter 3.5).
5. **The events seam (SHIPPED)** — `echo/apps/echo_mq/lib/echo_mq/events.ex`: `publish/5` (`events.ex:117` —
   `publish(conn, queue, event, job_id, extra \\ [])`, host-side PUBLISH of cjson on `emq:{q}:events`, the id
   gated at the key builder `:119`, fire-and-forget). **The batch lifecycle events ride this PER-MEMBER** (D3 — one
   `publish/5` per member on its own `job_id`; NO batch-level event, NO new transport).
6. **The keyspace** — `echo/apps/echo_mq/lib/echo_mq/keyspace.ex`: `queue_key/2` builds `emq:{q}:<type>`;
   `job_key/2` gates `BrandedId.valid?/1` and raises pre-wire. **No grammar edit** — the cadence rides the shipped
   `pending`/`active`/`events`.
7. **The conformance harness** — `echo/apps/echo_mq/lib/echo_mq/conformance.ex` (`scenarios/0` + `run/2`) + the two
   pins `test/conformance_run_test.exs` (`{:ok, 64}` at `:50`) + `test/conformance_scenarios_test.exs` (`@run_order`,
   64 names). The additive-minor law: extend `scenarios/0` with the new scenario(s) + the probe in the SAME change,
   the prior 64 byte-unchanged, re-pin the count in BOTH tests. The emq.5.1 batch scenarios (`batch_claim` `:148`,
   `batch_claim_short` `:149`, `batch_partial_failure` `:150`; the probes `apply_scenario(:batch_*)` at `:2079`,
   `:2133`, `:2174`) are the EXACT precedent for the shaping scenario shape.
8. **The program law** — `.claude/skills/echo-mq-program.md` (the v2 laws, the gate ladder, the additive-minor
   law) + the as-built map `.claude/skills/echo-mq-surface.md`. **Re-probe the as-built tree at Stage-0** (the
   lag-1 law — line numbers are hints, grep/Read to confirm).

## Requirements (numbered — each traces to a story + an invariant)

- **R1 — `EchoMQ.BatchShaper.Core` (the pure flush-decision core).** A NEW pure module — the `EchoMQ.Pump.Core`
  isomorph (`pump/core.ex`). It validates `min_size` (a positive integer) and `timeout` (a positive integer ms)
  the `Pump.Core` way (`Keyword.get` with a default, a non-positive value `raise ArgumentError` — `pump/core.ex:27,45`),
  and answers the FLUSH DECISION as a PURE function of (the observed pending depth, the ms elapsed since the window
  opened, `min_size`, `timeout`): **flush when `depth >= min_size`** (the floor → the request `size` ≥ `min_size`)
  **OR when `elapsed >= timeout`** (the ceiling → `size =` the observed depth, possibly < `min_size`, D2); `depth ==
  0` at the ceiling → NO flush (the empty case). NO process, NO wall clock, NO I/O — time enters ONLY as an injected
  `now_ms`/`elapsed`. Doctested (the `Pump.Core` doctest precedent). The exact fn names/arity are Mars's to shape to
  the `Pump.Core` idiom (e.g. a `decide(depth, elapsed_ms, opts)` returning `{:flush, size}` | `:wait`, + the
  validating `min_size/1`/`timeout/1`). → US4, US1, US2; INV-PureCore, INV-Floor+Ceiling.
- **R2 — `EchoMQ.BatchConsumer` (the home — FORK 5.2-A → D-1, a NEW sibling process).** A supervised process
  (`batch_consumer.ex`, a SIBLING of `EchoMQ.Consumer` — `consumer.ex` UNTOUCHED) that opens a window (marks `t0`
  from the injected `:now_fn` clock), reads `Jobs.pending_size/2` on a poll cadence (the watch-depth primitive —
  NO claim, NO lease tick during accumulation, D1), feeds (depth, elapsed = `now − t0`) to `BatchShaper.Core`, and
  on a `{:flush, size}` decision calls `Jobs.claim_batch/4` ONCE for the decided `size` over the flat
  `emq:{q}:pending` (NOT `Lanes.claim/3` — the grouped ring is emq.5.3). The SAME `t0` is held across `:wait` polls
  (the ceiling fires; a fresh `t0` only after a flush). The lifecycle (`child_spec`/`start_link`/`stop/2`/the
  `:conn`-`:connector` lane/control-honoring) duplicates the `EchoMQ.Consumer` discipline minimally (D-1's
  accepted ~40-line cost). The poll cadence holds the wait HOST-SIDE (a `receive … after poll_ms` honoring control
  — NO blocking Lua, NO `BLPOP`-for-`min_size`); control is honored between batches and at the poll wait, never
  inside a batch. → US1, US2; INV-Floor+Ceiling, INV-ClaimPath, INV-PureCore.
- **R3 — the batch handler contract (FORK 5.2-B → D-2, the per-member verdict map).** `EchoMQ.BatchConsumer`
  invokes the batch handler ONCE over the served members `[%{id:, payload:, attempts:}]` and maps its verdict to
  per-member `Jobs.complete/5` / `Jobs.retry/7`. **The contract is D-2: a per-member verdict map
  `%{id => :ok | {:error, reason}}`** — the consumer completes the `:ok` members and retries the `{:error, reason}`
  members, each `reason` threaded to `retry/7`'s `error` arg. A served member ABSENT from the map fail-safe-RETRIES
  (`{:error, "missing verdict"}`), never silently completes (D-2's sub-decision). A handler raise converts to a
  WHOLE-batch retry (every member retried — the `consumer.ex:146-153` rescue/catch hardening, generalized).
  → US3; INV-PartialFailure.
- **R4 — the batch lifecycle events (D3 — per-member, the seam reused).** Publish each member's lifecycle event
  via the shipped `EchoMQ.Events.publish/5` (`events.ex:117`) — per-member, on the member's own branded `job_id`
  (the id gated at the key builder, INV5); NO batch-level event, NO new transport. (Placement: the host-side
  publish-after-verdict convention the `@complete`/`@retry` D1 seam uses — emq.2.3-D1.) → US3; INV-Events.
- **R5 — the no-Lua + byte-freeze + wire law.** emq.5.2 adds NO new `Script.new/2`; `@bclaim`, `claim_batch/4`,
  `pending_size/2`, `complete/5`, `retry/7`, and every shipped script (`jobs.ex` + every `@g*` in `lanes.ex`)
  byte-identical to HEAD (`grep redis.call` on the lib diff = **0** — the cadence is pure Elixir + host-fn calls);
  the §6 grammar unedited; `{emq}:version` = `echomq:2.4.2`; no `echo_wire`/`apps/echomq` touch. → US5; INV-NoLua,
  INV-Boundary.
- **R6 — the three shaping conformance scenarios (additive minor — D-3, +3 → 67).** Register the three scenarios
  in `scenarios/0` with probes in the SAME change (`batch_shaping_floor` + `batch_shaping_timeout` +
  `batch_shaping_partial_failure`); the prior **64** byte-unchanged; re-pin **64 → 67** in BOTH pins. The scenarios
  settle through a conformance-local `settle_batch/4` that MIRRORS `BatchConsumer.settle/3` (cross-referenced by
  comment — the wire-level harness drives no spun process per scenario; the live process independently proves the
  fail-safe in `batch_consumer_test.exs`, L-3). Write the `:valkey` proof to US1 (the floor flush — a POSITIVE
  proof, ≥ `min_size` served from a flooded queue) + US2 (the ceiling flush — the partial within `timeout`,
  against an injected clock) + US3 (the isolation + the absent-member fail-safe). → US6, US1, US2, US3; INV-Conf.
- **R7 — the proof + determinism posture.** Per-app gate ladder inside `echo/apps/echo_mq` (TMPDIR=/tmp, `--include
  valkey`); `Conformance.run/2 → {:ok, 67}`; the PURE-core doctests/unit tests; a **multi-seed sweep** + an honest
  statement (emq.5.2 mints no id, touches no lease of its own — the only nondeterminism is the timer, isolated in
  the injected-clock core; NOT the ≥100 loop — emq.5.2's own code is not a mint/lease surface). As built: an 8-seed
  sweep + a 25× repeat of the new `:valkey` `BatchConsumer` suite + the Director's independent full re-run (Y-1);
  honest-row (Valkey 6390). → US7; S-4, INV-PureCore.

## Execution topology

**Runtime shape.** `EchoMQ.BatchShaper.Core` is a PURE module (no process — a value the consumer computes, the
`Pump.Core` shape). `EchoMQ.BatchConsumer` (the home ruled at FORK 5.2-A → D-1, a SIBLING of `EchoMQ.Consumer`) is
a supervised process holding a dedicated connector lane (the `EchoMQ.Consumer` discipline) that runs a
WATCH→DECIDE→FLUSH→SETTLE cycle: WATCH reads `Jobs.pending_size/2` (a `ZCARD` — no claim, no lease tick); DECIDE
feeds (depth, elapsed = `now − t0`, the `t0` held across `:wait` polls) to the pure core; FLUSH calls
`Jobs.claim_batch/4` ONCE over the flat `pending` for the decided `size` (the byte-frozen spine — one atomic
`@bclaim` eval, one `TIME`, one shared lease for the batch); SETTLE invokes the batch handler and maps its
per-member verdict map to per-member `Jobs.complete/5`/`Jobs.retry/7` (the partial-failure isolation; an absent
member fail-safe-retries), publishing each member's event via `Events.publish/5`. The wait for the floor is
HOST-SIDE (the poll cadence — NO blocking Lua), so `timeout` (the host wait bound) and `lease_ms` (the byte-frozen
`@bclaim` deadline) are INDEPENDENT (D1 — the consumer holds NO Valkey lease during accumulation). emq.5.2 adds NO
Lua, NO new key family, NO wire edit.

**The build-order task DAG.**
```
R1 BatchShaper.Core (the pure decision)  ──►  R2 EchoMQ.BatchConsumer (the home — watch/flush/settle)
   │                                              ├─► R3 the batch handler contract (verdict map → per-member settle)
   │                                              └─► R4 per-member lifecycle events (Events.publish/5)
   ├─► R5 no-Lua + byte-freeze + wire-law grep (grep redis.call = 0; §6 unedited; @wire_version frozen)
   └─► R6 the three shaping conformance scenarios + the 64→67 re-pin  ──►  R7 proof (:valkey + the multi-seed sweep + the core doctests)
```

**The EXACT files touched** (the Stage-6 commit pathspec — Director-only; the as-built touch-set, FORK 5.2-A →
D-1 = a NEW `batch_consumer.ex`, `consumer.ex` UNTOUCHED):
```
echo/apps/echo_mq/lib/echo_mq/batch_shaper/core.ex   (the NEW pure flush-decision core — the Pump.Core isomorph)
echo/apps/echo_mq/lib/echo_mq/batch_consumer.ex      (the NEW sibling process — FORK 5.2-A → D-1; consumer.ex UNTOUCHED)
echo/apps/echo_mq/lib/echo_mq/conformance.ex         (the three shaping scenarios + the settle_batch/4 mirror + the count prose)
echo/apps/echo_mq/test/batch_consumer_test.exs       (the :valkey shaping proof — NEW; US1 + US2 + US3 + the live fail-safe)
echo/apps/echo_mq/test/batch_shaper_core_test.exs    (the pure-core doctest/unit — NEW)
echo/apps/echo_mq/test/conformance_run_test.exs       (re-pin {:ok, 67})
echo/apps/echo_mq/test/conformance_scenarios_test.exs (re-pin @run_order → 67 names)
docs/echo_mq/specs/emq2/emq.5/emq.5.rungs/emq.5.2.{md,stories.md,llms.md,prompt.md}  (Stage-5 sync)
docs/echo_mq/specs/progress/emq-5-2.progress.md  (+ the registry)
```
*(`mix.exs` is NOT touched — the label stays `2.5.0`, the emq.4.3-D4 two-planes model: a host-process rung climbs
no version plane.)*
**EXCLUDED:** `jobs.ex` (BYTE-FROZEN — `@bclaim`/`claim_batch/4`/`pending_size/2`/`complete/5`/`retry/7`/every
script unchanged; the cadence CALLS them), `lanes.ex` (every `@g*` byte-frozen — emq.5.2 drains the FLAT pending,
not the ring), `keyspace.ex` (no grammar edit), `events.ex` (the seam reused as-is — D3, no edit), `echo_wire/*`
(untouched — `@wire_version` frozen), `apps/echomq` (the capability reference), `mix.lock` (no real dep moved), any
`AM`-status out-of-band file.

## Agent stories (Directive + Acceptance gate — each a contract at the boundary)

- **AS1 — build `EchoMQ.BatchShaper.Core`.** *Directive:* author the NEW pure flush-decision module (the
  `EchoMQ.Pump.Core` isomorph) — the accumulate/flush decision over (depth, elapsed, min_size, timeout), an
  injected clock, the `Pump.Core` validation. *Acceptance gate (contract):* **precondition** — (depth, elapsed_ms,
  min_size, timeout) as plain values; **postcondition** — `{:flush, size}` when `depth >= min_size` (size ≥
  min_size, the floor) OR `elapsed >= timeout` (size = depth, the ceiling, D2), `:wait` otherwise, NO flush when
  `depth == 0` at the ceiling; **invariant** — the module has NO Connector/Jobs/Process/:timer/System.monotonic_time
  reference (grep = 0), the decision is deterministic given its args (doctested), a non-positive knob raises
  `ArgumentError` (INV-PureCore).
- **AS2 — build `EchoMQ.BatchConsumer`.** *Directive:* the home ruled at FORK 5.2-A → D-1 (a NEW sibling process,
  `consumer.ex` untouched) — a watch→decide→flush→settle cycle reading `pending_size/2`, flushing via
  `claim_batch/4` over flat `pending`, settling per-member, the window `t0` held across `:wait` polls.
  *Acceptance gate:* **precondition** — a queue + a configured `min_size`/`timeout`/`batch_handler`; **postcondition**
  — a flood ≥ `min_size` flushes ≥ `min_size` members (the floor); a trickle < `min_size` flushes the partial within
  `timeout` (the ceiling, against an injected clock); a paused queue flushes nothing; **invariant** — the flush
  calls `claim_batch/4` (NOT `Lanes.claim/3`), the depth is WATCHED via `pending_size/2` (no lease tick during
  accumulation — D1), control honored between batches (INV-ClaimPath, INV-Floor+Ceiling).
- **AS3 — build the batch handler contract + prove partial-failure isolation.** *Directive:* invoke the batch
  handler over the served members, map its per-member verdict map (FORK 5.2-B → D-2) to per-member `complete/5`/`retry/7`;
  a `:valkey` proof that a flushed batch resolves member-by-member. *Acceptance gate:* **precondition** — a flushed
  batch of N with one designated poison member; **postcondition** — member k retried (scheduled, `last_error`
  kept), the rest completed, a fresh post-promote flush finds only k at attempts 2; **invariant** — no batch-scoped
  resolution script exists (`complete/5`/`retry/7` byte-frozen, no new Lua — INV-PartialFailure, INV-NoLua). The
  proof MUST actually fail a member (no vacuous pass).
- **AS4 — the events + the no-Lua/byte-freeze.** *Directive:* publish each member's event via `Events.publish/5`
  (per-member, D3); run the no-Lua + byte-freeze grep. *Acceptance gate:* **postcondition** — the events plane sees
  N per-member transitions (no batch-level event); `grep redis.call` on the lib diff = **0** (emq.5.2 adds NO Lua),
  every shipped script byte-identical to HEAD; **invariant** — `@wire_version` = `echomq:2.4.2`, the §6 grammar
  unedited, the diff ⊆ `echo_mq` (INV-NoLua, INV-Boundary, INV-Events).
- **AS5 — the conformance + the proof + the multi-seed sweep.** *Directive:* register the shaping scenario(s)
  (the three, D-3) additive-minor; re-pin 64 → 67 in both pins; run the full per-app gate ladder + the
  pure-core doctests + a multi-seed sweep. *Acceptance gate:* **postcondition** — `Conformance.run/2 → {:ok, 67}`,
  both pins pass, the core doctests green, the multi-seed sweep green; **invariant** — the prior 64 scenarios
  byte-unchanged (git-verified), each new scenario's probe registered in the same change, the determinism posture
  is a multi-seed sweep + an honest statement (emq.5.2 mints no id/lease of its own — NOT the ≥100 loop unless the
  Operator requests it) (INV-Conf, INV-NoLua). A scenario that flushes a batch and asserts nothing about the flush
  shape fails its own letter.

## A short comprehensive prompt (no decision the spec has not fixed — the forks are RULED)

Build the `min_size`/`timeout` batch shaping cadence inside `echo/apps/echo_mq` to the ruled FORK 5.2-A → D-1 (the
home) and FORK 5.2-B → D-2 (the batch handler contract). Add ONE new PURE module `EchoMQ.BatchShaper.Core` — the
`EchoMQ.Pump.Core` isomorph (`pump/core.ex`): `validate!/2` (a non-positive knob raises) + `decide(depth, elapsed,
min_size, timeout) → {:flush, size} | :wait` over (the observed pending depth, the ms elapsed since the window
opened, `min_size`, `timeout`) with an INJECTED clock — flush when `depth >= min_size` (the floor, `size = depth`,
always ≥ min_size) OR `elapsed >= timeout` with `depth > 0` (the ceiling partial, `size = depth`, possibly <
min_size — D2), `:wait` when `depth == 0` at the ceiling; NO process/wall-clock/I/O; doctest the decision. Build
`EchoMQ.BatchConsumer` (the home ruled FORK 5.2-A → D-1 — a NEW sibling process, `consumer.ex` UNTOUCHED; the
`:metronome` opt-in at `consumer.ex:82-85` is the lifecycle precedent, not a mode to add to): WATCH
`Jobs.pending_size/2` (`jobs.ex:863` — a `ZCARD`, no claim, no lease tick during accumulation, D1; hold `t0` across
`:wait` polls), DECIDE via the pure core, FLUSH via the byte-frozen `Jobs.claim_batch/4` (`jobs.ex:520`) over the
flat `emq:{q}:pending` (NOT `Lanes.claim/3` — the grouped ring is emq.5.3), SETTLE each member through the
byte-frozen `Jobs.complete/5` (`jobs.ex:589`) / `Jobs.retry/7` (`jobs.ex:759`) per the ruled FORK 5.2-B → D-2
verdict (a per-member verdict map `%{id => :ok | {:error, reason}}`; an absent member fail-safe-retries `"missing
verdict"`; a handler raise is a whole-batch retry). Publish each member's lifecycle event via the shipped
`EchoMQ.Events.publish/5` (`events.ex:117`) per-member on its own `job_id` (D3 — no batch-level event, no new
transport). Keep `@bclaim`,
`claim_batch/4`, `pending_size/2`, `complete/5`, `retry/7`, and EVERY shipped script byte-identical to HEAD —
emq.5.2 adds NO `Script.new/2` (`grep redis.call` on the lib diff = 0). Register the three shaping conformance
scenarios additive-minor (D-3 — `batch_shaping_floor` + `batch_shaping_timeout` + `batch_shaping_partial_failure`,
+3 → 67; the prior 64 byte-unchanged; re-pin 64 → 67 in both pins; the scenarios settle through a `settle_batch/4`
mirror of `BatchConsumer.settle/3`, cross-referenced by comment — L-3). Run the per-app gate ladder + the
pure-core doctests + a multi-seed sweep on Valkey 6390 (the determinism posture is a multi-seed sweep + an honest
statement — emq.5.2 mints no id and touches no lease of its own; NOT the ≥100 loop). No `echo_wire` edit
(`@wire_version` frozen at `echomq:2.4.2`); no §6 grammar edit; no new Lua; no new key family; no blocking Lua for
the floor (the wait is host-side); no git. Report the gate results before going idle.
