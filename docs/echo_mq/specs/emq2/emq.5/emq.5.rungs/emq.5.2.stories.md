# EMQ.5.2 — stories (the `min_size`/`timeout` batch shaping — the self-pacing batch consumer)

> The acceptance face of [`emq.5.2.md`](emq.5.2.md) (the body is authoritative — if a story disagrees with the
> body, the body wins). Every Deliverable becomes a Connextra user story with concrete Given/When/Then acceptance
> (Gherkin/BDD); each names the invariant(s) it exercises; the Coverage map at the foot proves every Deliverable
> traces to a story. **✅ SHIPPED — Director-verified BUILD-GRADE; the two forks RULED (FORK 5.2-A → D-1 a new
> `EchoMQ.BatchConsumer` sibling · FORK 5.2-B → D-2 the per-member verdict map); the count LANDED at +3 → 67 (D-3).**
>
> **The standing liveness law (the gate-must-exercise-its-outcome rule).** US1 (the floor) is a POSITIVE proof: a
> present precondition (a queue flooded to ≥ `min_size`) MUST run the cadence and assert the flush carries ≥
> `min_size` members — a vacuous pass (a cadence that flushes nothing from a flooded queue, or that flushes a
> single member proving nothing about the floor) is a LOUD failure. US2 (the ceiling) MUST hold a real trickle
> until `timeout` and assert the PARTIAL flush — a ceiling proof with the floor already met proves nothing about
> the timeout. US3's partial-failure isolation MUST actually fail one member and complete the rest — a property
> asserted with no failing member proves nothing and fails its own letter. The shaping timer is tested against an
> INJECTED clock (no real-time sleep), so the ceiling assertion is deterministic, never a flake.
>
> **The forks are RULED.** US1/US2/US3 are authored to the OBSERVABLE outcomes (the flush shapes, the per-member
> settle) which hold for the ruled home (FORK 5.2-A → D-1: `EchoMQ.BatchConsumer`, a sibling of `EchoMQ.Consumer`).
> US3 + US5 reference the FORK 5.2-B handler contract → D-2: the per-member verdict map
> `%{id => :ok | {:error, reason}}` (a served member absent from the map fail-safe RETRIES, never silently
> completes).

---

## US1 — The size-floor flush (a flooded queue → one batch of ≥ `min_size` members)

**As a** high-throughput bulk-drain consumer, **I want** the cadence to wait until at least `min_size` jobs are
pending and then flush ONE batch, **so that** each batch carries enough members to amortize the per-job work my
batch handler does — the floor earns its latency cost by making the batch worth a single bulk operation.

- **Exercises:** EMQ.5.2-INV-Floor+Ceiling (the floor leg), EMQ.5.2-INV-ClaimPath (drains via `claim_batch/4`
  over flat `pending`, not `Lanes.claim`), EMQ.5.2-INV-PureCore (the flush decision is the injected-clock pure
  core), EMQ.5.2-INV-PartialFailure (the all-good path — every member completes).

```gherkin
Given a batch-aware consumer configured with min_size = 4 and a timeout (e.g. 1000ms)
  And a queue whose pending set is flooded to >= min_size distinct mint-ordered JOB-ids (e.g. 10 pending)
When the cadence observes the depth (via Jobs.pending_size/2 — a ZCARD, no claim, no lease tick) and the floor is met
Then the shaping core decides FLUSH and the consumer calls Jobs.claim_batch/4 ONCE over the flat emq:{q}:pending
  And the served batch carries >= min_size members (the floor leg — the request size >= min_size)
  And the members are claimed via @bclaim (the byte-frozen spine — NOT Lanes.claim/3, the grouped ring)
  And the batch handler is invoked over the served members and the all-good verdict completes every member (per-member complete/5)
  And NO lease ticks during accumulation (the depth was WATCHED via pending_size/2, claimed only at the flush — D1)
```

- **Liveness (no vacuous pass):** the floor scenario MUST start with ≥ `min_size` pending and assert the flush
  carries ≥ `min_size` members; a cadence that flushes nothing from a flooded queue, or a `min_size`-1 config that
  proves nothing about the floor, is a LOUD failure (use `min_size >= 2`, a flood > `min_size`). The
  watch-not-claim assertion is load-bearing: the depth read MUST be `pending_size/2` (a `ZCARD`), not a claim — a
  claim during accumulation would tick leases (the D1 hazard the watch-depth model dodges).
- **Determinism note (NOT a mint/lease surface in emq.5.2's own code):** the claim is the byte-frozen `@bclaim`
  (proven by emq.5.1's ≥100 loop); emq.5.2 adds no id-mint and no lease of its own. The only nondeterminism is the
  shaping TIMER, isolated in the injected-clock pure core — so the posture is a MULTI-SEED sweep + an honest
  statement, NOT the ≥100 loop.

---

## US2 — The latency-ceiling flush (a trickle < `min_size` → a partial flush within `timeout`)

**As a** bulk-drain consumer, **I want** the cadence to flush whatever is pending when `timeout` elapses even if
fewer than `min_size` are ready, **so that** a slow trickle still drains within a bounded latency — `min_size` is
a soft/best-effort floor, never a hard wait that could stall indefinitely.

- **Exercises:** EMQ.5.2-INV-Floor+Ceiling (the ceiling / the soft floor / the empty case), EMQ.5.2-INV-PureCore
  (the injected clock — the ceiling is deterministic), EMQ.5.2-INV-ClaimPath.

```gherkin
Given a batch-aware consumer with min_size = 5 and timeout = 1000ms, and an INJECTED clock (the test seam)
  And a queue with M = 2 pending JOB-ids (M < min_size), no further arrivals
When the window has been open for elapsed >= timeout (advanced via the injected clock — no real sleep)
Then [D2: THE CEILING WINS, THE FLOOR IS SOFT] the shaping core decides FLUSH despite depth < min_size
  And the consumer flushes the PARTIAL: claim_batch/4 serves exactly the M available members (< min_size)
  And the flush happens within timeout of the window opening (the latency ceiling — a hard bound on the wait)
  And the served members are processed by the batch handler and settled per-member
  And a window that observes depth == 0 at the ceiling flushes NO batch (the empty case — re-open the window, no claim_batch/4 call)
  And a queue paused queue-wide answers :empty from the flush (the byte-frozen claim_batch/4 honors paused?/2 FIRST), so the cadence flushes nothing
```

- **Liveness:** the ceiling scenario MUST start with `0 < M < min_size` pending and assert the partial flush of
  exactly M members within `timeout` (a ceiling proof with the floor already met proves nothing about the
  timeout; a flush of more than M, or a hang past `timeout`, is a LOUD failure). The empty leg MUST be the
  genuinely-idle window (zero arrivals → no `claim_batch/4` call). The injected clock makes the `timeout`
  assertion deterministic (no real-time sleep, no flake). This is the `batch_shaping_timeout` conformance
  scenario.

---

## US3 — Partial-failure isolation through the cadence (one poisoned member never sinks the batch)

**As a** bulk-drain consumer, **I want** the shaping consumer to resolve each member of a flushed batch
independently — completing the good ones and retrying the poisoned one — **so that** one bad job in a batch is
isolated to its own retry, the rest settle, and the batch stays a CLAIM unit (the emq.5.1 isolation, now driven
by the self-pacing cadence).

- **Exercises:** EMQ.5.2-INV-PartialFailure (per-member resolution over byte-frozen `complete/5`/`retry/7`),
  EMQ.5.2-INV-Events (per-member publish on each member's id), EMQ.5.2-INV-NoLua (the resolution rides the
  byte-frozen transitions, no new Lua).

```gherkin
Given a batch-aware consumer (EchoMQ.BatchConsumer) that flushed a batch of N members (each with its own attempts token, e.g. N=3, member k is "poison")
  And the batch handler contract is FORK 5.2-B → D-2 (a per-member verdict map %{id => :ok | {:error, reason}})
When the handler answers :ok for the N-1 good members and {:error, reason} for member k
Then the consumer completes the N-1 good members (per-member Jobs.complete/5) and retries member k (Jobs.retry/7 — scheduled, last_error = reason)
  And member k's row is state = scheduled with its last_error kept; the other N-1 rows are retired (complete deleted them)
  And the other members' completion is UNAFFECTED by member k's failure (no batch-scoped rollback — each settle is independent)
  And after promote, a fresh flush finds ONLY member k (the poison), now carrying attempts = 2 (its own token advanced)
  And each member's lifecycle event is published per-member on its own branded job_id (Events.publish/5 — D3; no batch-level event)
  And a served member ABSENT from the verdict map is fail-safe-RETRIED ({:error, "missing verdict"}), never silently completed (D-2 sub-decision — unprocessed work must not retire)
  And a stale-token resolution of any member is refused EMQSTALE by the byte-frozen @complete/@retry (per-member fencing)
  And no new resolution Lua exists (grep redis.call on the lib diff = 0 — INV-NoLua; the batch is a CLAIM unit, not a resolution unit)
```

- **Liveness (no vacuous pass):** the scenario MUST actually fail member k (drive a real `retry/7` via the
  handler's `{:error, reason}`) and complete the rest — a "partial-failure" proof with no failing member, or one
  that completes all N, proves nothing about isolation and is a LOUD failure. The fail-safe leg MUST include a
  member ABSENT from the verdict map and assert it retries (`"missing verdict"`), not silently completes. The
  EMQSTALE leg MUST exercise a genuinely stale token. This is the `batch_shaping_partial_failure` conformance
  scenario (which omits a member to prove the fail-safe observably; the live process independently proves the
  fail-safe in `batch_consumer_test.exs`). The ruled FORK 5.2-B → D-2 (the per-member verdict map) makes this
  isolation observable through the cadence — one poison member retries alone, the rest complete.

---

## US4 — The pure shaping core (the flush decision is a pure function with an injected clock)

**As a** maintainer, **I want** the accumulate/flush decision to be a PURE function of (the observed depth, the
elapsed ms, `min_size`, `timeout`) with an injected clock and no process/wall-clock/I/O, **so that** the cadence's
logic is deterministically testable in isolation (the `EchoMQ.Pump.Core` discipline) and the only nondeterminism —
the timer — is contained at the test seam.

- **Exercises:** EMQ.5.2-INV-PureCore (no process/clock/I/O; the injected clock; the validation discipline).

```gherkin
Given EchoMQ.BatchShaper.Core — the pure decision module (the EchoMQ.Pump.Core isomorph; validate!/2 + decide/4)
When decide(depth, elapsed_ms, min_size, timeout) is called
Then it returns {:flush, size} | :wait, deterministic given its arguments (same inputs → same output, doctested)
  And depth >= min_size decides {:flush, depth} (the floor — size = depth, always >= min_size); elapsed >= timeout with depth > 0 decides {:flush, depth} (the ceiling partial, D2)
  And depth == 0 at the ceiling decides :wait (the empty case)
  And the module has NO Connector/Jobs/Process/:timer/System.monotonic_time reference (grep = 0 — time enters only as the injected elapsed)
  And a non-positive min_size or timeout RAISES ArgumentError (validate!/2 — re-validated inside decide/4; a shaper that cannot advance is a config error, not a silent no-op)
```

- **Liveness:** the core's purity is asserted by a grep (no clock/process/I/O reference) AND a doctest proving the
  decision is a deterministic function of its arguments; the validation guard is asserted by a raise test (a
  non-positive knob raises). A core that reaches for a wall clock or a process would defeat the injected-clock
  determinism the whole posture rests on.

---

## US5 — The byte-freeze + no-Lua discipline (`@bclaim` and every shipped script stand unbroken)

**As a** maintainer of the frozen wire, **I want** emq.5.2 to add NO Lua and to keep `@bclaim`, `claim_batch/4`,
`pending_size/2`, `complete/5`, `retry/7`, and every shipped script byte-identical to HEAD, **so that** the
shaping cadence is purely a HOST process over the byte-frozen spine — it cannot silently re-shape the claim, the
resolution, or any wire behavior.

- **Exercises:** EMQ.5.2-INV-NoLua (no new Lua, every shipped script byte-frozen), EMQ.5.2-INV-Boundary (the diff
  ⊆ `echo_mq`, `@wire_version` frozen, no new key family), EMQ.5.2-INV-Conf (the prior 64 byte-unchanged).

```gherkin
Given the shipped Lua corpus (every Script.new in jobs.ex + every @g* in lanes.ex) and the byte-frozen host fns
       (claim_batch/4, @bclaim, pending_size/2, complete/5, retry/7)
When emq.5.2 builds the shaping cadence (EchoMQ.BatchShaper.Core + EchoMQ.BatchConsumer — pure Elixir + host-fn calls)
Then NO new redis.call-bearing script is added (grep redis.call on the lib diff = 0 — emq.5.2 adds NO Lua)
  And every shipped script is byte-identical to HEAD; @bclaim/claim_batch/4/pending_size/2/complete/5/retry/7 are byte-unchanged (the cadence CALLS them)
  And the prior 64 conformance scenarios pass byte-unchanged (name + contract + verdict body git-verified)
  And the §6 grammar in keyspace.ex is unedited (no new emq:{q}:<type> family — the cadence rides pending/active/events)
  And {emq}:version reads echomq:2.4.2 (the wire @wire_version is unchanged — no claim wire-behavior change; the diff ⊆ echo_mq)
  And the diff touches no echo_wire file and no apps/echomq file
```

- **Liveness:** the byte-freeze grep is run over the ACTUAL lib diff against HEAD and asserted = 0 (emq.5.2 adds
  no Lua at all — a non-zero `grep redis.call` is itself the alarm: this rung is a host-process rung); a touched
  `echo_wire` or `apps/echomq` file is a LOUD boundary failure.

---

## US6 — Additive-minor conformance growth (the count re-pin)

**As a** keeper of the conformance harness, **I want** the shaping scenario(s) registered with their probes in the
same change and the prior 64 kept byte-unchanged, **so that** the bus contract grows only by additive minor.

- **Exercises:** EMQ.5.2-INV-Conf (the additive-minor conformance law).

```gherkin
Given the prior conformance set was 64 scenarios (the prior set, byte-unchanged contract)
When emq.5.2 registers the three shaping scenarios in scenarios/0 (D-3, +3 → 67:
       batch_shaping_floor + batch_shaping_timeout + batch_shaping_partial_failure)
Then the git-diff of scenarios/0 shows ONLY additions (the prior 64 names + contracts + verdict bodies byte-unchanged, git-verified; the sole `-` line is a trailing-comma artifact on the previously-last entry)
  And each new scenario's probe is registered in the SAME change (a present precondition — a flooded queue / a held trickle — runs it with a positive proof)
  And the count re-pins 64 -> 67 in BOTH pinning tests (conformance_run_test.exs {:ok, 67} + conformance_scenarios_test.exs @run_order)
  And Conformance.run/2 prints 67 lines and returns {:ok, 67} against the truth row (Valkey on 6390)
```

- **Liveness:** the new scenarios are not vacuous — `batch_shaping_floor` asserts the ≥ `min_size` flush (US1),
  `batch_shaping_timeout` asserts the partial flush within `timeout` (US2), and `batch_shaping_partial_failure`
  asserts the isolation (US3); a scenario that flushes a batch and asserts nothing about the flush shape fails its
  own letter (the gate-must-exercise-its-outcome rule).

---

## US7 — Honest-row proof + the determinism posture (the multi-seed sweep)

**As an** evaluator (Apollo, an optional fast-finisher — this rung edits no shipped script and adds no Lua/lease),
**I want** the proof run against the truth row with a determinism posture honest to a pure, clock-injected core,
**so that** a green board reflects the real engine and the real (timer-only) nondeterminism, never a host that
lacks Valkey.

- **Exercises:** the honest-row law (S-4), the determinism posture (a multi-seed sweep — NOT the ≥100 loop, no
  id-mint/lease in emq.5.2's own code); closes the rung's proof.

```gherkin
Given the live engine is Valkey on port 6390 (valkey-cli -p 6390 ping -> PONG)
When the per-app gate ladder runs inside echo/apps/echo_mq (TMPDIR=/tmp, --include valkey)
Then compile --warnings-as-errors is clean (exit 0), the :valkey shaping suite is green, Conformance.run/2 -> {:ok, 67}
  And the PURE-core doctests/unit tests are green (the EchoMQ.BatchShaper.Core decision + the validation guard)
  And a MULTI-SEED sweep is green (the only nondeterminism is the shaping timer, isolated in the injected-clock pure core)
       + an HONEST determinism-posture statement (emq.5.2 mints no id and touches no lease of its own — @bclaim is byte-frozen, proven by emq.5.1's ≥100 loop)
  And the byte-freeze grep on @bclaim (and every shipped script) = 0 (INV-NoLua — emq.5.2 adds NO Lua)
  And the claims are phrased against Valkey, current stable line (a host without Valkey runs the probes elsewhere and reports them as that row, never the truth row)
```

- **Determinism rationale:** unlike emq.5.1 (whose proof minted branded JOB-ids and `@bclaim` leased on the
  server clock → the ≥100 loop), emq.5.2 adds NO id-mint and NO lease of its own — the claim is the byte-frozen
  `@bclaim`, and the cadence's only nondeterminism is the shaping timer, contained in the injected-clock pure
  core. So a multi-seed sweep + an honest statement is the posture taken (the ≥100 loop is for a mint/lease
  surface, which emq.5.2's own code is not). As built: an 8-seed sweep on the pure core + the conformance
  registry, plus a 25× repeat of the new `:valkey` `BatchConsumer` suite (process-timing shakeout), plus the
  Director's independent full re-run (Y-1) — all green; emq.5.2 owns no new lease and `@bclaim`'s lease is
  emq.5.1-proven.

---

## US-GATE — the standing conformance gate (every emq.* rung)

**As the** program, **I want** the full conformance harness green against the truth row at the rung's close, **so
that** the bus contract is provably whole after the shaping cadence lands.

```gherkin
Given Valkey on 6390 is up (PONG) and the fence reads the live @wire_version (echomq:2.4.2)
When EchoMQ.Conformance.run/2 runs over a live connection at the rung's close
Then it prints one line per scenario and returns {:ok, 67} (the re-pinned total — 64 + the three shaping scenarios)
  And both pinning tests pass (the pure registry test + the wire run test, count re-pinned to 67)
```

---

## Coverage map (every Deliverable → its story)

| Deliverable (from [`emq.5.2.md`](emq.5.2.md) Goal/Scope/DoD) | Story | Invariant(s) |
|---|---|---|
| `EchoMQ.BatchShaper.Core` — the pure accumulate/flush decision (injected clock, the `Pump.Core` isomorph) | US4, US1, US2 | INV-PureCore, INV-Floor+Ceiling |
| `EchoMQ.BatchConsumer` (the home — FORK 5.2-A → D-1, a sibling process; watch `pending_size/2`, flush via `claim_batch/4`) | US1, US2 | INV-Floor+Ceiling, INV-ClaimPath, INV-PureCore |
| The size-floor flush (≥ `min_size` members, D1 watch-depth) | US1 | INV-Floor+Ceiling, INV-ClaimPath |
| The latency-ceiling flush (the partial / the soft floor / the empty case, D2) | US2 | INV-Floor+Ceiling, INV-PureCore |
| The batch handler contract (FORK 5.2-B → D-2; per-member verdict map → `complete/5`/`retry/7`, absent → fail-safe retry) | US3 | INV-PartialFailure |
| Partial-failure isolation through the cadence (a tested property over byte-frozen transitions) | US3 | INV-PartialFailure, INV-Events, INV-NoLua |
| The batch lifecycle events ride the shipped `Events.publish/5` (per-member, D3) | US3 | INV-Events |
| The byte-freeze + no-Lua discipline (every shipped script byte-frozen; emq.5.2 adds NO Lua) | US5 | INV-NoLua, INV-Boundary |
| The prior conformance scenarios byte-unchanged + the count re-pin 64 → 67 | US5, US6, US-GATE | INV-Conf, INV-NoLua |
| The three shaping conformance scenarios (additive minor — D-3, +3 → 67) | US1, US2, US6 | INV-Floor+Ceiling, INV-Conf |
| The `batch_shaping_partial_failure` conformance scenario (additive minor) | US3, US6 | INV-PartialFailure, INV-Conf |
| The `:valkey` shaping suite + the pure-core doctests + the multi-seed sweep + honest-row | US7 | S-4, INV-PureCore, INV-Floor+Ceiling |
| The conformance harness green (`{:ok, 67}`) at the rung's close | US-GATE | INV-Conf |

**Traceability note (correct by definition):** every Deliverable in the body maps to at least one story above,
and every story names the invariant(s) it exercises; completion is provable from this text — a Deliverable with
no green story is not done. US1/US2/US3 are authored to the OBSERVABLE outcomes (the flush shapes, the per-member
settle), realized by the ruled home FORK 5.2-A → D-1 (`EchoMQ.BatchConsumer`, a sibling of `EchoMQ.Consumer`).
US3 + US5's handler references are FORK 5.2-B → D-2 (the per-member verdict map; an absent member fail-safe
retries). The count LANDED at **+3 → 67** (D-3, the emq.5.1 granularity precedent); US6/US-GATE pin 67.
