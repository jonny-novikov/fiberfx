# EMQ.5.2 · the build orchestration runbook — the `min_size`/`timeout` batch shaping (the self-pacing batch consumer)

> The authoritative run scope for shipping emq.5.2 via `/echo-mq-ship` (Flat-L2, Director-supervised). The body
> ([`emq.5.2.md`](emq.5.2.md)) is the contract; the acceptance is [`emq.5.2.stories.md`](emq.5.2.stories.md); the
> Mars brief is [`emq.5.2.llms.md`](emq.5.2.llms.md). This runbook binds them to the pipeline stages + the gate
> ladder + the risk tier. **No decision the body has fixed is left open here — EXCEPT the two forks (5.2-A the
> shaping home, 5.2-B the batch handler contract) + the conformance count granularity, which the Operator rules at
> the pre-build reconcile (the Director routes via AskUserQuestion). NONE changes the risk tier** (both forks are
> host-side shape decisions over the byte-frozen `@bclaim`; neither adds Lua, a lease, or a wire edit; the count is
> bookkeeping).
>
> **Framing law (propagated).** Third person for any agent; no gendered pronouns for agents; no perceptual or
> interior-state verbs for agents or software; no first-person narration. Bind this same clause in any sub-brief.

## The family in one paragraph

emq.5 builds the **batch CONSUME** family across four dependency-ordered sub-rungs ([`../emq.5.md`](../emq.5.md),
the Operator-blessed carve): **emq.5.1** the batch-claim spine (`@bclaim` + `claim_batch/4` — fetch up to N jobs
in one atomic claim) — SHIPPED, the SPINE; **emq.5.2** `min_size`/`timeout` shaping (a batch-aware consumer that
waits for ≥ `min_size` OR until `timeout`, then drains via `@bclaim`) — THIS rung, the SHAPING; **emq.5.3** group
affinity + batch concurrency (`@gbclaim`, a homogeneous lane-scoped batch — Apollo recommended); **emq.5.4** the
partitioned finish (a batch resolves as a partition + dynamic delay). The PRODUCE half already ships
(`Jobs.enqueue_many/3`, `jobs.ex:124`) and is NOT re-built. 5.1 landed FIRST — 5.2/5.3/5.4 each ride `@bclaim` and
are mutually independent (the Operator may re-order them). Each ships independently; nothing in the family is a
wire break.

## The rung in one paragraph

emq.5.2 builds the **`min_size`/`timeout` shaping** cadence: a batch-aware consumer that watches the pending depth
and flushes ONE batch when EITHER a SIZE FLOOR (`min_size`) or a LATENCY CEILING (`timeout`) is reached, draining
via the SHIPPED, byte-frozen `@bclaim`/`Jobs.claim_batch/4` (emq.5.1, the spine). The spine is a manual single-shot
pull (FORK 5.1-C RULED non-blocking); emq.5.2 gives it a self-pacing rhythm with a size floor (so a batch is worth
the bulk-handler cost) and a latency ceiling (so a trickle still drains within a bound). The mechanism is the
carve's reserved "batch-aware Consumer mode … a PURE shaping core (accumulate/flush, injected clock); batch
lifecycle events on the `EchoMQ.Events` seam" ([`../emq.5.md`](../emq.5.md) §1 row emq.5.2). The pattern is
**already proven** by the shipped `EchoMQ.Pump`/`Pump.Core` (`pump/core.ex` — a supervised cadence over a pure
decision core); emq.5.2 is the batch isomorph. It rides `@bclaim` and adds **NO new Lua, NO new lease, NO new key
family, NO wire edit** (the cadence is a HOST process over the byte-frozen spine — `grep redis.call` on the lib
diff = 0). All under the v2 master invariant (braced keyspace · branded `JOB` ids gated · no new Lua key · the
server clock already inside the byte-frozen `@bclaim` · inline `Script.new/2` — none added · additive-minor
conformance).

## Mode

**Flat-L2, Director-supervised.** Venus (reconcile/author the triad — DONE; loads `echo-mq-architect`) → Mars-1
(build to the brief — `echo-mq-implementor`) → Director solo review (independent gate re-run on Valkey 6390 + an
adversarial probe + a net-zero mutation spot-check) → Mars-2 (remediate + harden — **a candidate right-size
collapse**: no wire/Lua, so the Director MAY collapse Mars-2 if Stage-2 verify is clean) → Director ship (one
LAW-4 pathspec commit). **Apollo (`echo-mq-evaluator`) is an OPTIONAL fast-finisher** (closure + stories) — this
rung edits NO shipped script and adds NO Lua/lease (`@bclaim` is byte-frozen), so Apollo is NOT a ship
precondition; the determinism posture is a multi-seed sweep + the pure-core doctests (the core is pure +
clock-injected), run by the Director (and Mars), not an Apollo mandate.

## The forks are OPEN — the Operator's pre-build decisions (ruled via AskUserQuestion BEFORE Mars builds)

> **Two forks + the conformance count granularity. NONE changes the risk tier (all are host-side shape decisions
> over the byte-frozen `@bclaim`).** The Director routes each to the Operator via `AskUserQuestion`, records the
> ruling, and only THEN releases Mars. The full four-part Arms (Rationale / 5W / Steelman / Steward) are in the
> body §"The rung's forks"; the compact routing summary:
>
> - **FORK 5.2-A — the shaping home.** A batch-aware **mode on `EchoMQ.Consumer`** (Arm A — reuses the shipped
>   lifecycle `child_spec`/`stop`/the `:conn` lane; the emq.4.3 `:metronome` opt-in is the exact third-mode
>   precedent; matches the carve's wording; cost: a third cadence + a second handler shape in an already-257-line
>   module) **vs** a new **`EchoMQ.BatchConsumer`** process (Arm B — clean single-purpose separation; cost:
>   duplicates ~40-60 lines of OTP lifecycle plumbing; diverges from the carve's wording). **Venus lean: Arm A** (a
>   Consumer mode — matches the carve, reuses the lifecycle, the `:metronome` precedent; a right-size-collapse rung
>   should not duplicate plumbing). The cadence behavior (US1/US2/US3) is IDENTICAL either way — the fork is a
>   code-organization call.
>
> - **FORK 5.2-B — the batch handler contract (the load-bearing fork).** How the batch handler signals per-member
>   success/failure for the partial-failure settle (emq.5.1 INV7). Arm A — a SINGLE batch verdict (`:ok` → complete
>   all / `{:error, r}` → retry all; simplest, but forfeits INV7 isolation through the cadence — one bad member
>   redoes the whole batch); Arm B — a PER-MEMBER verdict map (`%{id => :ok | {:error, reason}}`; makes INV7
>   isolation observable + usable, most expressive, per-member `reason` → each `last_error`; cost: a richer
>   contract); Arm C — a results/`{:ok, failed_ids}` shape (middle ground; no per-member `reason`); Arm D — keep
>   the SINGLE-JOB handler, batch amortizes only the CLAIM (forfeits the handler-WORK amortization the `min_size`
>   floor's latency is paid for — argued against). **Venus lean: Arm B** (the per-member verdict map — it makes
>   emq.5.1's partial-failure isolation observable + usable through the shaping path, the whole point of the floor
>   being a batch the handler sees together). This fork DECIDES the value proposition of batch shaping (handler-WORK
>   amortization vs claim-only).
>
> - **The conformance count granularity (a [WITHHELD] Operator call, the emq.5.1-FORK-5.1-B precedent).** The
>   proposed decomposition: `batch_shaping_floor` + `batch_shaping_timeout` + `batch_shaping_partial_failure`, the
>   lean **+3 → 67** (each leg a distinct observable — the emq.5.1 granularity). The Operator may choose fewer (+2
>   → 66 folding floor+ceiling; +1 → 65 if partial-failure is judged emq.5.1-covered). **Venus lean: +3 → 67.**
>
> **None changes the risk tier:** 5.2-A is code organization; 5.2-B is the host-side verdict-mapping shape; the
> count is bookkeeping. All are host-side over the byte-frozen `@bclaim` — no Lua, no lease, no wire edit. The
> grade stays NORMAL the instant the Operator rules.

## The as-built floor (re-probed at Venus's reconcile, this run — Mars RE-PROBES each at Stage-0; the lag-1 law)

- **Toolchain:** Erlang 28.5.0.1 / Elixir 1.18.4 (`echo/.tool-versions`, re-probe `asdf current` from the app
  dir). Valkey on **6390** → PONG. `{emq}:version` = `echomq:2.4.2` == `@wire_version` (`connector.ex:35`; the boot
  fence passes).
- **`claim_batch/4` (jobs.ex:520-539) — the FLUSH call (SHIPPED, byte-frozen):** `claim_batch(conn, queue, size,
  lease_ms) when is_integer(size) and size > 0 and is_integer(lease_ms) and lease_ms > 0` :520-521 · `if
  paused?(conn, queue) -> :empty` :522-523 (pause FIRST) · keys `[queue_key(q,"pending"), queue_key(q,"active")]`
  :525 · argv `[queue_key(q,"job:"), lease_ms, size]` :527-531 · `{:ok, []} -> :empty`, `{:ok, members} -> {:ok,
  Enum.map(members, &List.to_tuple/1)}` :534-535. The cadence calls this ONCE per flush for the decided `size`.
- **`@bclaim` (jobs.ex:200-219) — the claim script (SHIPPED, byte-frozen):** `ZCARD KEYS[1]` depth clamp `k =
  min(size, depth)` :201-204 · ONE `TIME` :205-206 · the per-member loop `ZPOPMIN`→`HINCRBY attempts`→`HSET state
  active`→`ZADD active now+lease id` :208-217. emq.5.2 adds NO Lua — this is byte-frozen.
- **`pending_size/2` (jobs.ex:863-866) — the WATCH-DEPTH primitive (SHIPPED, byte-frozen):** `Connector.command(conn,
  ["ZCARD", queue_key(q, "pending")])` :865. A PURE READ — no claim, no lease tick. The cadence reads THIS to decide
  the floor (D1). **CORRECTION to the Director's seed: the fn is `pending_size/2`, not "Jobs.depth/2 or similar".**
- **`complete/5` (jobs.ex:589) + `retry/7` (jobs.ex:759) — the per-member settle (SHIPPED, byte-frozen):**
  `complete(conn, queue, job_id, token, result \\ nil)` :589 · `retry(conn, queue, job_id, token, delay_ms,
  max_attempts, error)` :759. The batch handler's verdict maps to these per-member (the `consumer.ex:155-161`
  settle, generalized).
- **`paused?/2` (jobs.ex:482):** consulted FIRST inside `claim_batch/4`.
- **`EchoMQ.Pump.Core` (pump/core.ex) — the pure-core PRECEDENT:** `tick_ms/1` :24-29 + `batch/1` :42-47 — pure fns
  of options, `@default_tick_ms 1_000`/`@default_batch 100`, a non-positive value `raise ArgumentError` :27,45,
  doctested :18-21,36-39. `EchoMQ.BatchShaper.Core` is the ISOMORPH.
- **`EchoMQ.Consumer` (consumer.ex, 257 lines) — the lifecycle PRECEDENT:** `child_spec/1` :28-35 · `start_link/1`
  :52-89 (the `:conn`/`:connector` lane :60-68; the options :70-80) · `stop/2` :101-112 · `check_control/0` :127
  (control at settle points). TWO shipped modes, BOTH via `Lanes.claim/3` → `{id, payload, att, group}` (the
  GROUPED ring): the standalone `loop/1` :114-121 · the emq.4.3 `metronome_loop/1` :185-188 (dispatched off the
  `:metronome` opt-in :82-85 — the EXACT third-mode precedent for FORK 5.2-A Arm A). The per-job handler:
  `s.handler.(%{id:, payload:, attempts:, group:})` → `:ok | {:error, reason}` → `Jobs.complete`/`Jobs.retry`
  :144-161; the rescue/catch hardening :146-153 (Chapter 3.5).
- **`EchoMQ.Events.publish/5` (events.ex:117) — the events seam (SHIPPED):** `publish(conn, queue, event, job_id,
  extra \\ [])` — host-side PUBLISH of cjson on `emq:{q}:events`, the id gated at the key builder :119,
  fire-and-forget. The batch events ride this PER-MEMBER (D3 — gates a SINGLE job_id; a batch-level event would
  need a representative id or an additive variant, declined D3).
- **The keyspace (keyspace.ex):** `queue_key/2` builds `emq:{q}:<type>`; `job_key/2` gates `BrandedId.valid?/1`.
  **No grammar edit** — the cadence rides the shipped `pending`/`active`/`events`. No `BatchShaper`/`BatchConsumer`
  exists yet (`grep BatchShaper|BatchConsumer` = 0, greenfield).
- **Conformance = 64 (LIVE):** `conformance_run_test.exs:50` `{:ok, 64}`; `conformance_scenarios_test.exs`
  `@run_order` = 64 names; the emq.5.1 batch scenarios `batch_claim`/`batch_claim_short`/`batch_partial_failure`
  (`conformance.ex:148-150`, probes `:2079`/`:2133`/`:2174`) are the EXACT precedent for the shaping scenario shape.
- **The version model (two-planes, emq.4.3 D-4) — as built:** `mix.exs:7` version "2.5.0" = the rung LABEL read by
  nobody at runtime; `@wire_version` "echomq:2.4.2" = the wire constant, frozen by committed records. The label
  step is a [WITHHELD] decision (a label-only call, no wire impact — within the batches family, the emq.5.1
  precedent stepped to 2.5.0 opening the family; emq.5.2 may hold at 2.5.0 or step a patch — the Operator's call).
  Conformance goes 64 → N (the granularity [WITHHELD]).

## The pipeline — the stages

### Stage 0/1 — Venus (architect): the triad + the pre-build reconcile + the forks surfaced — DONE
The triad is authored ([`emq.5.2.md`](emq.5.2.md) body authoritative; [`emq.5.2.stories.md`](emq.5.2.stories.md)
+ [`emq.5.2.llms.md`](emq.5.2.llms.md) derived) with the reconcile deltas carried (the 64 count, the byte-freeze
universe = `@bclaim`/`claim_batch/4`/`pending_size/2`/`complete/5`/`retry/7` + every shipped script, the re-probed
`Pump.Core`/`Consumer`/`Events` anchors, the `pending`/`active`/`events` home, the two-planes version) and the two
forks ([WITHHELD]: 5.2-A the home, 5.2-B the handler contract) + the [WITHHELD] count granularity framed OPEN.
Two design calls SETTLED with rationale (D1 watch-depth, D2 ceiling-wins) + one (D3 per-member events) — NOT
Operator forks. **Director gate:** read the body + this runbook (the files, not the report); route FORK 5.2-A/5.2-B
+ the count granularity to the Operator (AskUserQuestion); record the rulings; then release Mars.

### Stage 1 — Mars-1 (implementor): build to the ruled arms
Re-probe the floor (Stage-0, the lag-1 law — every anchor above). Build **R1** (the NEW `EchoMQ.BatchShaper.Core`
— the pure flush-decision, the `Pump.Core` isomorph, an injected clock, the validation discipline), **R2** (the
batch-aware consumer mode — the home ruled at FORK 5.2-A; WATCH `pending_size/2` → DECIDE via the core → FLUSH via
the byte-frozen `claim_batch/4` over flat `pending` → SETTLE per-member), **R3** (the batch handler contract — the
shape ruled at FORK 5.2-B; the verdict mapped to per-member `complete/5`/`retry/7`), **R4** (the per-member
lifecycle events via `Events.publish/5` — D3), **R5** (the no-Lua + byte-freeze + wire-law grep battery), **R6**
(the shaping conformance scenario(s) — the ruled granularity + the 64→N re-pin in both pins), and self-verify the
per-app gate ladder + the pure-core doctests + a **multi-seed sweep**. **Stories:** Mars writes/extends the
`:valkey` proof to US1 (the floor flush — a POSITIVE proof, ≥ `min_size` served from a flooded queue) + US2 (the
ceiling flush — the partial within `timeout`, against an INJECTED clock — no real sleep) + US3 (the partial-failure
isolation through the cadence). Cite the spec line for every public call; emq.5.2 adds NO `Script.new/2` (it CALLS
the byte-frozen host fns); the shaping core is PURE (an injected clock); the conformance additive-minor mechanics.
Report the gate results before going idle (an interim if a sweep is mid-run).

### Stage 2 — Director: solo review (a REAL pass)
Independent gate re-run on Valkey 6390 (not Mars's word): `compile --warnings-as-errors`, `mix test --include
valkey`, `Conformance.run/2 → {:ok, N}`. The adversarial probes:
1. **The floor no-op-defeater** — flood a queue to ≥ `min_size`, run the cadence → assert ONE flush of ≥ `min_size`
   members via `claim_batch/4`; mutate the core to flush at depth 1 → the batch under-floors (US1 RED). A
   `min_size`-1 config proves nothing — confirm the proof uses `min_size >= 2`, a flood > `min_size`.
2. **The ceiling probe (against the injected clock)** — a trickle of M < `min_size`, advance the INJECTED clock to
   `timeout` → assert the PARTIAL flush of exactly M within `timeout` (D2); a window with the floor already met
   proves nothing about the timeout. Confirm NO real-time sleep (the injected clock is the seam — a real sleep is a
   flake the probe rejects).
3. **The watch-not-claim probe (D1)** — confirm the accumulation reads `pending_size/2` (a `ZCARD`), NOT a claim —
   no lease ticks during the wait (a claim-during-accumulation would couple `timeout`↔`lease_ms`, the D1 hazard).
   Assert `timeout` and `lease_ms` are independent (a window with `timeout > lease_ms` flushes a full-lease batch,
   no early reap).
4. **The empty/pause probe** — an idle window (zero arrivals) at the ceiling → NO `claim_batch/4` call (the empty
   case); a paused queue → the flush answers `:empty`, pending UNTOUCHED (the byte-frozen `claim_batch/4` honors
   `paused?/2` FIRST).
5. **The partial-failure isolation probe** — flush a batch of N, the handler fails member k + succeeds the rest →
   k `scheduled` (last_error kept), the rest retired, a fresh post-promote flush finds only k at attempts 2; a
   stale-token resolution → `EMQSTALE` (the byte-frozen fencing). The per-member events: N per-member publishes on
   the members' own ids (D3 — no batch-level event).
6. **The no-Lua + byte-freeze grep** — `grep redis.call` on the lib diff = **0** (emq.5.2 adds NO Lua — the alarm
   if non-zero: this is a host-process rung); `@bclaim`/`claim_batch/4`/`pending_size/2`/`complete/5`/`retry/7` +
   every shipped script byte-identical to HEAD; the §6 grammar unedited; `@wire_version` = `echomq:2.4.2`.
7. **The pure-core probe (INV-PureCore)** — `EchoMQ.BatchShaper.Core` has NO Connector/Jobs/Process/:timer/
   System.monotonic_time reference (grep = 0); the decision is deterministic given its args (the doctest); a
   non-positive `min_size`/`timeout` raises `ArgumentError` (the `Pump.Core` validation discipline).
8. **A net-zero mutation spot-check** — two distinct load-bearing tests proven to BITE (the floor-flush size + the
   partial-failure isolation), reverted net-zero.

The determinism posture is a **multi-seed sweep + the pure-core doctests** (NOT the ≥100 loop — emq.5.2 mints no
id and touches no lease of its own; `@bclaim`'s lease is emq.5.1-proven, byte-frozen). The Director MAY request a
≥100 loop on the `:valkey` shaping suite if it judges the `@bclaim`-leasing flush a borderline lease surface, but
the body's posture is the multi-seed sweep (the rung owns no new lease). The injected clock is the determinism
seam for the ceiling (no real-time flake).

### Stage 3 — Mars-2 (implementor): remediate + harden + the full gate ladder (a CANDIDATE COLLAPSE)
**A candidate right-size collapse:** no wire/Lua, so the Director MAY collapse Mars-2 if the Stage-2 verify is
clean (zero findings). If run: apply the Director's findings; run the FULL per-app gate ladder + the pure-core
doctests + the multi-seed sweep. No-Lua + byte-freeze + boundary + FROZEN-WIRE confirmations. Report (an interim
before idle — silence reads as a stall, emq.4.3 L-2).

### Stage 4 — Apollo (evaluator): OPTIONAL fast-finisher (NOT a gate — emq.5.2 adds no Lua, edits no shipped script)
If run: the post-build reconcile (does the as-built code satisfy the spec's promises?); the §11.2-charter
adversarial verification (the floor/ceiling/partial-failure probes applied to the cadence); re-run the per-app
gate ladder + the multi-seed sweep independently; re-verify the conformance count is byte-unchanged with each new
scenario probe-registered; sync the spec to what shipped; the mentoring loop. This rung edits no shipped script and
adds no Lua/lease, so Apollo is an optional fast-finisher (closure + stories), NOT a ship precondition.

### Stage 5 — Venus (architect): the post-build reconcile
Sync the triad to what shipped — the ruled home (FORK 5.2-A: the Consumer mode or the `BatchConsumer` sibling, and
the actual touch-set), the ruled handler contract (FORK 5.2-B: the verdict shape), the scenario set + the final
count N, the byte-freeze set actually frozen, the `@wire_version` disposition (frozen), the rung label. Surgical
sync, body authoritative. (The `emq.5.2.md` body is edited at THIS stage — the as-built reconcile syncs the seed
POST-build, never pre-build.)

### Stage 6 — Director: closure + ONE LAW-4 commit
One Director pathspec commit of the rung's measured surface (the code + the triad + the `emq-5-2` ledger).
Re-verify `git diff --cached --name-only` is purely the rung before committing (the Operator pre-stages
out-of-band — exclude `AM`-status files); split an entangled tree into separate scoped commits per concern. Mark
emq.5.2 SHIPPED in the roadmap/progress, note the batches family shaping landed (5.3/5.4 still ride `@bclaim`). No
push unless asked.

## Risk tier — NORMAL (a host-process rung; a multi-seed sweep; a candidate right-size collapse)

| Dimension | Grade |
|---|---|
| **Risk** | **NORMAL** — additive over a proven mechanism + a proven pattern: `@bclaim` (the claim) is SHIPPED + byte-frozen; the shaping is a supervised process with a PURE decision core (`EchoMQ.Pump.Core` is the precedent); the events ride the shipped `Events.publish/5`. **NO new Lua · no new lease · no new key family · no destructive at-rest op · no frozen-line edit · no wire break.** NOT HIGH (no shipped-script edit, no destructive op, no new lease *surface* — `@bclaim` does the leasing, byte-frozen). |
| **Apollo** | **Optional fast-finisher** (closure + stories) — NOT a ship precondition (no shipped-script edit, no Lua). |
| **Determinism** | **A multi-seed sweep + the pure-core doctests + an honest statement** — emq.5.2 mints NO id and touches NO lease of its own (the claim is the byte-frozen `@bclaim`, emq.5.1-proven by the ≥100 loop); the only nondeterminism is the shaping TIMER, isolated in the injected-clock pure core. NOT the ≥100 loop (unlike emq.5.1, a mint/lease surface). The Operator may request the ≥100 loop for the `@bclaim`-leasing `:valkey` suite at the pre-build reconcile if judged borderline. |
| **No-Lua / byte-freeze set** | emq.5.2 adds **NO Lua** (`grep redis.call` on the lib diff = **0**). EVERY shipped script byte-frozen — `@bclaim`, `claim_batch/4`, `pending_size/2`, `complete/5`, `retry/7`, every `jobs.ex` script, every `@g*` in `lanes.ex`. The cadence is pure Elixir (`BatchShaper.Core`) + host-fn calls. |
| **Wire** | `@wire_version` UNCHANGED at `echomq:2.4.2` (no claim wire-behavior change — `claim_batch/4` rides the shipped connector `eval`); `mix.exs` rung label → a [WITHHELD] step (the two-planes model, a label-only decision). |
| **Right-size collapse** | **A candidate** — no wire/Lua, so the Director MAY collapse Mars-2 if Stage-2 verify is clean (the carve names emq.5.2 a right-size-collapse candidate). |

The grade is stated forward so the build runs at the right rigor the instant the Operator rules the forks.

## Acceptance — "shipped" means

- FORK 5.2-A (the home) + FORK 5.2-B (the handler contract) ruled (the Operator's calls recorded); the count
  granularity ruled; the triad re-derived to them (Stage-5).
- R1–R7 built and green: `EchoMQ.BatchShaper.Core` (the pure flush-decision, an injected clock, the `Pump.Core`
  validation); the batch-aware consumer mode (the home ruled at FORK 5.2-A; watch `pending_size/2`, flush via the
  byte-frozen `claim_batch/4` over flat `pending`, settle per-member); the batch handler contract (the shape ruled
  at FORK 5.2-B); the per-member lifecycle events via the shipped `Events.publish/5` (D3); the conformance
  scenario(s) (additive minor — prior 64 byte-unchanged, re-pinned 64 → N in both pins); the no-Lua + byte-freeze
  grep = 0 over every shipped script.
- The proof: the `:valkey` shaping suite green per-app; the pure-core doctests green; a multi-seed sweep green +
  an honest determinism-posture statement (emq.5.2 owns no new id-mint/lease); honest-row (Valkey 6390). Apollo an
  optional fast-finisher.
- INV-NoLua/Boundary/PureCore/Floor+Ceiling/ClaimPath/PartialFailure/Conf/Events verified as runnable checks; the
  body remains authoritative; the as-built reconcile syncs the seed post-build (Stage-5); one LAW-4 pathspec commit
  (Stage-6); the batches family shaping landed (5.3/5.4 ride `@bclaim`).

## The Stage-6 commit pathspec (Director-only — the emq.5.2 BUILD; adjust to the ruled touch-set)

```bash
# THE CODE (the additive touch-set — the home FORK 5.2-A decides consumer.ex-edit vs batch_consumer.ex-new):
#   echo/apps/echo_mq/lib/echo_mq/batch_shaper/core.ex   (the NEW pure flush-decision core — the Pump.Core isomorph)
#   echo/apps/echo_mq/lib/echo_mq/consumer.ex            (IFF FORK 5.2-A = Arm A: the additive :batch mode)
#     OR echo/apps/echo_mq/lib/echo_mq/batch_consumer.ex (IFF FORK 5.2-A = Arm B: the NEW sibling process)
#   echo/apps/echo_mq/lib/echo_mq/conformance.ex         (the shaping scenario(s) + the count prose)
#   echo/apps/echo_mq/test/<batch_shaping_or_consumer>_test.exs  (the :valkey shaping proof — NEW; US1 + US2 + US3)
#   echo/apps/echo_mq/test/batch_shaper_core_test.exs    (the pure-core doctest/unit — OR doctests inline)
#   echo/apps/echo_mq/test/conformance_run_test.exs       (re-pin {:ok, N})
#   echo/apps/echo_mq/test/conformance_scenarios_test.exs (re-pin @run_order → N names)
#   echo/apps/echo_mq/mix.exs                            (the rung label — a [WITHHELD] step, the two-planes model)
# THE DOCS:
#   docs/echo_mq/specs/emq2/emq.5/emq.5.rungs/emq.5.2.{md,stories.md,llms.md,prompt.md}
#   docs/echo_mq/specs/emq2/emq.5/emq.5.md          (IFF a Stage-5 carve sync is needed — the shaping SHIPPED note)
#   docs/echo_mq/specs/progress/emq-5-2.progress.md  (+ the registry)
# EXCLUDED: jobs.ex (BYTE-FROZEN — @bclaim/claim_batch/4/pending_size/2/complete/5/retry/7/every script; the cadence CALLS them),
#   lanes.ex (every @g* byte-frozen — emq.5.2 drains flat pending, not the ring), keyspace.ex (no grammar edit),
#   events.ex (the seam reused as-is — D3, no edit), echo_wire/* (untouched — @wire_version frozen), apps/echomq,
#   mix.lock (no real dep moved), the .claude/ calibration diffs (harness-fenced), any AM-status out-of-band file.
```
