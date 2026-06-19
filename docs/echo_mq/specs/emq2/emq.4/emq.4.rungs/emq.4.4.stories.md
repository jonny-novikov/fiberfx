# EMQ.4.4 — stories (weighted/deficit rotation + the starvation drill)

> The acceptance face of [`emq.4.4.md`](emq.4.4.md) (the body is authoritative — if a story disagrees with the
> body, the body wins). Every Deliverable becomes a Connextra user story with concrete Given/When/Then
> acceptance (Gherkin/BDD); each names the invariant(s) it exercises; the Coverage map at the foot proves every
> Deliverable traces to a story. **The mechanism-dependent stories (US1, US2) are authored to the OBSERVABLE
> outcome — the proportion and the no-starvation guarantee — which holds for EVERY Fork-B arm; the
> representation and rotation MECHANISM behind them is [WITHHELD — pinned at the Fork B ruling].** Forward-tense:
> every emq.4.4 surface is PROPOSED, not shipped.
>
> **The standing liveness law (the gate-must-exercise-its-outcome rule).** US1 and US2 are POSITIVE proofs: a
> present precondition (a weighted lane / a flooded lane) MUST run the rotation and assert the observed share /
> the drained depth — a vacuous pass (no work served, or a weight that changes nothing) is a LOUD failure, never
> a silent green. A weighted-proportion scenario that serves zero jobs, or a drill where a lane never fills,
> proves nothing and fails its own letter.

---

## US1 — Proportional fair-share (weighted rotation)

**As a** multi-tenant bus operator, **I want** a lane to carry a weight so the rotation serves higher-weight
lanes proportionally more, **so that** a premium tenant gets a larger share of the machine than a background
tenant — without a numeric per-job priority (retired by design) and without any lane being shut out.

- **Exercises:** EMQ.4.4-INV1 (fairness is proportional), EMQ.4.4-INV3 (the weight rides an existing key shape,
  no new key family, no numeric priority), EMQ.4.4-INV4 (server clock on the served job's lease),
  EMQ.4.4-INV5 (branded group at the weight + claim boundaries).

```gherkin
Given a queue with two lanes A and B, each named by a valid branded group id
  And lane A is assigned weight 3 and lane B is assigned weight 1
  And both lanes are flooded with far more pending JOB-ids than the window will serve
When the rotation serves N jobs over a window (N large enough to be statistically meaningful, e.g. >= 80)
Then lane A is served approximately 3x as often as lane B over the window (about a 3:1 ratio)
  And lane B is served a NON-ZERO number of times (a higher weight serves proportionally more, NEVER all)
  And every served job carried a server-clock lease (active score = TIME-derived deadline, no host timestamp)
  And both lanes were gated as valid branded groups before any wire (an ill-formed group raises pre-wire)
```

- **Liveness (no vacuous pass):** the window MUST serve > 0 jobs from EACH lane; an outcome where lane B is
  served zero times is a STARVATION failure (it is the thing US2 forbids), and an outcome where the served
  counts are equal (≈1:1) is a WEIGHT-IGNORED failure (the weight changed nothing). Both are red, not green.
- **Determinism note (mechanism-conditional):** the proportion is asserted as an APPROXIMATE ratio over a
  window (weighted/deficit schemes are exactly-proportional only in the limit; a tolerance band, e.g. lane A
  within [2x, 4x] of lane B, is the honest bound — a brittle exact-equality assert would forge flakiness). If
  the ruled mechanism makes the rotation a process/lease surface, the ≥100 determinism loop owns this proof;
  if it is a pure additive script (no new process, no new mint), a multi-seed sweep + an honest
  determinism-posture statement is the bound (the emq.4.1/4.2 posture).

---

## US2 — No lane starves under skew (the starvation drill) — THE CAPSTONE GUARANTEE

**As a** multi-tenant bus operator, **I want** a proof that under sustained load skew (one lane flooded, the
rest trickling) every lane still drains, **so that** a noisy neighbour can never monopolize the machine and
starve a quiet tenant — the strong guarantee a proportional scheme must keep.

- **Exercises:** EMQ.4.4-INV1 (fairness is starvation-free), EMQ.4.4-INV4 (server clock on every served
  lease), EMQ.4.4-INV5 (branded groups).

```gherkin
Given a queue with one HEAVY lane (weight 5) and two-or-more LIGHT lanes (weight 1), each a valid branded group
  And the HEAVY lane is flooded DEEP (e.g. 200 pending JOB-ids — ~40 weighted turns to exhaust alone)
  And each LIGHT lane is trickled a small, steady backlog (e.g. 6 pending JOB-ids; each light lane's depth > 0 — the liveness floor)
When the rotation (wclaim/3) is driven over a bounded EARLY window of 9 turns (3 ring cycles), while the heavy lane is still deep
Then EVERY light lane is served INSIDE that early window (the interleaving witness — no light lane is stuck at its backlog)
  And every served job's lease was computed from the server clock (redis.call('TIME'), no host timestamp)
  And when the rotation is then driven to completion, EVERY lane's pending depth reaches zero (the terminal liveness floor — no lane left starved)
```

- **Liveness + the load-bearing no-op-defeater (the body's L-1 correction):** the witness is the **early-window
  interleaving**, NOT the terminal drain alone. A terminal depth-0 check is a WEAK no-op-defeater — a no-rotation
  FIFO drain ALSO empties every lane eventually (the re-ring guard advances the head as each lane empties), so it
  cannot distinguish fair rotation from no rotation. The mutation that proves the real defeater: a rotation that
  serves the heavy lane to exhaustion FIRST (FIFO / no fair-share) serves ZERO from a light lane in the early
  window → the drill goes RED (a light lane is unserved inside the 9-turn window). The drill MUST actually flood
  the heavy lane and trickle the light lanes (each light lane's initial depth > 0); a drill where a light lane was
  never filled, or where the window ends before any serve, proves nothing and is a LOUD failure. The terminal
  drain remains the liveness floor (every lane reaches zero), but the early-window interleaving is the witness.
- **The boundary it must respect (INV8, from the family):** a weight of ZERO is NOT a starvation outcome — a
  parked lane is the operator's explicit `Lanes.pause/3` (emq.4.1), never a rotation result. The drill uses
  POSITIVE weights on every lane; a zero-weight lane is out of scope (it is a pause, tested by the shipped
  `pause` scenario, byte-unchanged).

---

## US3 — The byte-freeze discipline (the shipped lane surface stands unbroken)

**As a** maintainer of the frozen wire, **I want** every shipped `@g*` lane script that emq.4.4 does not name
to stay byte-identical to HEAD, **so that** the fairness deepening cannot silently re-shape the fairness-critical
claim path or any sibling lane behaviour the whole chapter rests on.

- **Exercises:** EMQ.4.4-INV2 (byte-freeze every unedited `@g*`), EMQ.4.4-INV6 (the prior conformance scenarios
  byte-unchanged).

```gherkin
Given the shipped lane family is EIGHT @g* scripts in lanes.ex
  (@genqueue, @gclaim, @gpause, @gresume, @glimit, @greassign, @gdrain, @greap_group)
When emq.4.4 builds the weighted rotation under the ruled Fork-B mechanism
Then if Fork B rules ADDITIVE (a new weighted-claim script, @gclaim byte-unchanged):
       ALL EIGHT shipped @g* scripts are byte-identical to HEAD (grep redis.call on those scripts in the lib diff = 0)
  And  if Fork B rules an @gclaim EDIT (the deficit counter on the ring):
       @gclaim is the rung's target (it may change) but EVERY OTHER of the eight is byte-identical to HEAD
         (@genqueue/@gpause/@gresume/@glimit/@greassign/@gdrain/@greap_group: grep redis.call on those = 0)
  And in either case the prior fair-lanes conformance scenarios pass byte-unchanged
       (rotate, pause, limit, lane_depth, stalled_group, reassign, lane_drain, reap_group — name + contract + verdict body git-verified)
```

- **Liveness:** the byte-freeze grep is run over the ACTUAL lib diff against HEAD and asserted = 0 for the
  frozen set; a non-zero result on a frozen script is a LOUD failure (an unintended edit), not a warning.

---

## US4 — The wire law (no new key family, no numeric priority, the two-planes version)

**As a** steward of the v2 protocol, **I want** the weight to ride an existing key shape and the rotation to
ride the shipped lane keys, with no new key family and no resurrected numeric priority, **so that** the
fairness deepening is additive over the grammar-total keyspace and breaks nothing on the wire.

- **Exercises:** EMQ.4.4-INV3 (no new key family, no numeric priority), EMQ.4.4-INV6 (additive-minor, the
  two-planes version model).

```gherkin
Given the §6 keyspace grammar is closed and grammar-total (keyspace.ex queue_key/2 builds emq:{q}:<type>)
  And glimit + gactive are per-queue HASHes keyed by group (the g-segment per-queue HASH shape)
When emq.4.4 stores a lane weight (the home is [WITHHELD]: a new per-queue g-segment HASH emq:{q}:gweight
       keyed group->weight is the candidate — an existing SHAPE, not a new FAMILY)
Then a grep of the new/edited rotation for a lane key outside the shipped g:-segment family returns empty
  And a grep for a numeric-priority score / a `prioritized` key / a `pc` counter returns empty (weight is per-LANE, never per-job)
  And the §6 grammar in keyspace.ex is unedited (no new {q}:<type> grammar member; gweight needs no grammar edit)
  And the @wire_version constant (echo_wire connector.ex) is unchanged at echomq:2.4.2 IF Fork B rules additive
       (an @gclaim edit that changes the wire behaviour of a claim is a protocol minor — the @wire_version step is ruled at the Fork B ruling)
  And the echo_mq mix.exs version is the rung LABEL only (read by nobody at runtime — the two-planes model, emq.4.3 D-4), stepped to 2.4.4
```

---

## US5 — Additive-minor conformance growth (the count re-pin)

**As a** keeper of the conformance harness, **I want** the weighted-proportion and starvation-drill scenarios
registered with their probes in the same change and the prior set kept byte-unchanged, **so that** the bus
contract grows only by additive minor and a port still conforms by translation.

- **Exercises:** EMQ.4.4-INV6 (the additive-minor conformance law).

```gherkin
Given the live conformance set is 59 scenarios (conformance_run_test.exs asserts {:ok, 59};
       conformance_scenarios_test.exs @run_order = 59 names — the prior set, byte-unchanged contract)
When emq.4.4 registers the weighted-proportion + starvation-drill scenarios in scenarios/0
Then the git-diff of scenarios/0 shows ONLY additions (the prior 59 names + contracts + verdict bodies byte-unchanged, git-verified)
  And each new scenario's probe is registered in the SAME change (a present precondition runs it with a positive proof)
  And the count re-pins 59 -> N (N = 61 for the two new scenarios) in BOTH pinning tests
       (conformance_run_test.exs {:ok, N} + conformance_scenarios_test.exs @run_order)
  And Conformance.run/2 prints N lines and returns {:ok, N} against the truth row (Valkey on 6390)
```

- **Liveness:** the new scenarios are not vacuous — the weighted-proportion scenario asserts the observed share
  (US1) and the starvation-drill asserts every lane drains (US2); a scenario that merely sets a weight and asserts
  nothing about the served share fails its own letter (it is the gate-must-exercise-its-outcome rule).

---

## US6 — Honest-row proof + the determinism posture

**As an** evaluator (Apollo, MANDATORY iff `@gclaim` is edited), **I want** the proof run against the truth row
with a determinism posture honest to the mechanism, **so that** a green board reflects the real engine and the
real cross-run hazard, never a host that lacks Valkey or a single lucky run.

- **Exercises:** the honest-row law (S-4), the determinism posture; closes the rung's proof.

```gherkin
Given the live engine is Valkey on port 6390 (redis-cli -p 6390 ping -> PONG)
When the per-app gate ladder runs inside echo/apps/echo_mq (TMPDIR=/tmp, --include valkey)
Then compile --warnings-as-errors is clean, the :valkey weighted + drill suites are green, Conformance.run/2 -> {:ok, N}
  And IF the ruled mechanism makes the rotation a process/lease surface:
       the >=100 determinism loop owns the proof (FOREGROUND, timeout-bounded chunks driven to an accumulated count -- emq.4.3 L-2)
  And IF the rotation is a pure additive script (no new process, no new id-mint):
       a multi-seed sweep + an explicit honest determinism-posture statement is the bound (no forged load -- the emq.4.1/4.2 posture)
  And the claims are phrased against Valkey, current stable line (a host without Valkey runs the probes elsewhere and reports them as that row, never the truth row)
  And IF @gclaim is edited: Apollo is MANDATORY -- the dedicated evaluator re-runs the ladder + the loop independently and re-verifies the byte-frozen scripts
```

---

## US-GATE — the standing conformance gate (every emq.* rung)

**As the** program, **I want** the full conformance harness green against the truth row at the rung's close,
**so that** the bus contract is provably whole after the deepening.

```gherkin
Given Valkey on 6390 is up (PONG) and the fence reads the live @wire_version (echomq:2.4.2)
When EchoMQ.Conformance.run/2 runs over a live connection at the rung's close
Then it prints one line per scenario and returns {:ok, N} (N = the re-pinned total, 61)
  And both pinning tests pass (the pure registry test + the wire run test, count re-pinned to N)
```

---

## Coverage map (every Deliverable → its story)

| Deliverable (from [`emq.4.4.md`](emq.4.4.md) Goal/Scope/DoD) | Story | Invariant(s) |
|---|---|---|
| The lane **weight** representation (no new key family — the [WITHHELD] Fork-B home) | US1, US4 | INV3, INV5 |
| The **weighted / deficit** rotation (lanes served in proportion to weight) | US1 | INV1, INV4, INV5 |
| The **starvation drill** (early-window interleaving witness + every lane drains — the capstone guarantee) | US2 | INV1, INV4, INV5 |
| The **weighted-proportion** conformance scenario (additive minor) | US1, US5 | INV1, INV6 |
| The **starvation-drill** conformance scenario (additive minor) | US2, US5 | INV1, INV6 |
| The **byte-freeze** of every unedited `@g*` (7 if `@gclaim` edited, 8 if additive) | US3 | INV2 |
| The prior conformance scenarios byte-unchanged + the count re-pin 59 → N | US3, US5, US-GATE | INV2, INV6 |
| No new key family / no numeric priority / §6 unedited / the two-planes version | US4 | INV3 |
| The `:valkey` weighted + drill suites + the determinism posture + honest-row | US6 | S-4, INV1 |
| The conformance harness green (`{:ok, N}`) at the rung's close | US-GATE | INV6 |

**Traceability note (correct by definition):** every Deliverable in the body maps to at least one story above,
and every story names the invariant(s) it exercises; completion is provable from this text — a Deliverable with
no green story is not done. The two mechanism-dependent Deliverables (the weight representation + the rotation)
are covered by stories authored to the OBSERVABLE outcome (US1's proportion, US2's no-starvation), so the
acceptance is complete and signable BEFORE the Fork B ruling pins the mechanism; the ruling fills in the
[WITHHELD] representation/rotation without changing what US1/US2 assert.
