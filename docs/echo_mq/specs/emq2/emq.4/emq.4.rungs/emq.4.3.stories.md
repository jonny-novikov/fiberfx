# EMQ.4.3 · user stories — the park-don't-poll metronome (a new blocking-claim primitive)

> Who wants the deepened metronome, what they need, and how we know it works. Each story is Connextra with
> Given/When/Then acceptance, an INVEST line naming the invariant(s) it encodes, and a Priority/Size/Implements
> line; the file ends with a Coverage line mapping every Deliverable to ≥1 story. The standing
> **`EMQ.4.3-US-GATE`** carries the Valkey gate (design §7) — a structural gate. emq.4.3 is the THIRD sub-rung of
> the groups-deepened family (Movement II): **the park-don't-poll metronome**, **re-derived to Arm B** (the
> Operator's ruling D-1) — emq.4.3 founds a **new blocking-claim primitive** that **subsumes** the shipped
> `BLPOP wake` + `drain` two-step (a consumer blocks DIRECTLY on the readiness signal and then runs the atomic
> `@gclaim`, so the lost-wakeup window closes **by construction**), over the **shipped** `EchoMQ.Consumer` park
> loop, the **shipped** `@gclaim` atomic claim, and the **shipped** `emq:{q}:wake` protocol — riding the shipped
> connector (`Connector.command/3` already carries a blocking command, `consumer.ex:147`) with **no `echo_wire`
> edit** (the FROZEN-WIRE verdict). Forward-tense: every emq.4.3 surface is PROPOSED, NOT shipped. The spec
> **body** [`./emq.4.3.md`](emq.4.3.md) (and the family [`../emq.4.md`](../emq.4.md)) is authoritative — when a
> derived artifact disagrees with the body, the body wins. **Risk: HIGH** — the founding reshapes a process/lease
> surface on the fairness-critical wake path and raises the computed wire floor (a blocking command enters the
> core inventory — a protocol minor, §12.5); a lost-wakeup race + a same-millisecond branded-id mint are
> **cross-run** hazards → the proof is the **≥100-iteration determinism loop** owning the machine, NOT one green
> run; **Apollo MANDATORY**. **The mechanism is WITHHELD** (FORK A-MECH in the body) — these stories are authored
> to the recommended **MECH-(i)** (a server-side block-move on the shipped `emq:{q}:wake` → `@gclaim`); an Arm-B
> mechanism ruling re-derives them before the build.

## EMQ.4.3-US1 — a job admitted while a consumer is parked is served within the beat (the headline metronome proof)

As a **bus consumer parked at rest on an empty queue**, I want a job admitted to my lane to be **served within the
beat** (not only when the beat next elapses), so that the bus is **prompt under load** while costing the wire
nothing at rest — a parked consumer wakes on availability, not on a poll.

Acceptance criteria
- Given a consumer parked (blocked on the readiness signal) on a queue with **no** serviceable lane, when a job is
  admitted to a serviceable lane (`EchoMQ.Lanes.enqueue/5`, which `LPUSH`es the `emq:{q}:wake` readiness LIST and
  re-rings the lane), then the consumer **serves that job within the beat** — observably **before** a full
  `beat_ms` elapses (a fast `beat_ms`, e.g. 1000, with the job handled in well under that window) — by
  unblocking on the readiness signal and running the atomic `@gclaim` (NOT by waiting out the beat as a poll).
- Given the job is served, when the handler answers `:ok`, then `@complete` settles it (the row deleted) and the
  consumer **re-parks** (blocks again) — the loop is `…→ drain → block`, the block the rest state, the beat the
  fallback.
- Given the consumer is parked, when **nothing** is admitted, then the block **returns on the beat**
  (`beat_ms` the fallback timeout) and the loop re-runs `reap → promote → drain → block` — the metronome's beat
  doubles as the pump cadence, so a due schedule still promotes without an admit.

INVEST — independent (the metronome's serve-within-beat contract); testable by the `:valkey` "admit while parked"
scenario (park a consumer with a slow-ish beat → admit a job → assert it is handled well before the beat
elapses); encodes EMQ.4.3-INV1 (the metronome is sound — woken within the beat), EMQ.4.3-INV2 (`@gclaim` stays
the atomic claim — the block precedes it). Priority: must · Size: 5 · Implements: EMQ.4.3-D (the blocking-claim
primitive) + EMQ.4.3-D (lost-wakeup robustness).

## EMQ.4.3-US2 — no wake is lost when work arrives exactly as the consumer parks (the lost-wakeup race, the load-bearing proof)

As a **bus operator running a busy multi-tenant queue**, I want a job admitted in the **window between a
consumer's last claim and its block** to still be served within the beat, so that a ready job is **never hung**
until the next beat by a lost wakeup — the robustness property the shipped happy-path two-step did not gate at
this depth.

Acceptance criteria
- Given a consumer that has just drained its last claimable job (its lane is momentarily empty) and is **about to
  block**, when a job is admitted **exactly at that park boundary** (the classic lost-wakeup window: the admit's
  `LPUSH wake` races the consumer's transition into the block), then the job is **still served within the beat** —
  under Arm B's MECH-(i) the consumer **block-moves on the very `emq:{q}:wake` LIST the admit pushes to**, so
  there is **no separate token to miss**: either the readiness signal is already present (the block returns
  immediately) or the admit's `LPUSH` satisfies the in-flight block — the window closes **by construction**, not
  by a recheck-after-park.
- Given the race is run **repeatedly** (the admit timed to land at varied points around the park boundary), when
  the **≥100-iteration determinism loop** runs the suite owning the machine, then **every** iteration serves the
  raced job within the beat — a lost wakeup that hangs the job until the next beat would surface as a cross-run
  flake the loop catches (one green run is NOT proof).
- Given the block-move primitive (MECH-(i)), when a consumer crashes **mid-block**, then the readiness signal is
  **not lost** — `BLMOVE`'s atomic pop-and-stash means a consumed token is recoverable (a follow-up consumer
  finds it), distinct from `BLPOP`'s fire-and-forget consume; the lane's work is recovered by the standing
  `@reap`/`reap_group` recovery regardless.

INVEST — independent (the lost-wakeup robustness contract); testable by the `:valkey` "park-boundary race"
scenario under the **≥100 loop** (admit at the boundary → served within the beat, every run); encodes
EMQ.4.3-INV1 (no lost wakeup, the load-bearing proof) + EMQ.4.3-INV2 (the block precedes `@gclaim`, never bypasses
it). Priority: must · Size: 5 · Implements: EMQ.4.3-D (lost-wakeup robustness) — **the load-bearing proof; the
≥100 loop owns it.**

## EMQ.4.3-US3 — several parked consumers share a queue fairly (no consumer starves)

As a **bus operator scaling consumers horizontally on one queue**, I want readiness **distributed fairly** across
several parked consumers, so that adding consumers adds throughput without **starving** any one of them — a parked
consumer is not permanently passed over while others serve.

Acceptance criteria
- Given **two (or more)** consumers parked (blocked) on the same queue, when a **stream** of jobs is admitted
  across one or more serviceable lanes, then **both** consumers make progress — each claims and completes a share
  of the work over the run; **neither** is permanently starved (no consumer goes the whole run without serving
  while another serves the whole stream).
- Given the readiness signal is the shipped single per-queue `emq:{q}:wake` LIST (capped 64, MECH-(i)'s default —
  shared by all lanes and consumers), when many admits push readiness, then a woken consumer drains the **ring**
  (the rotating `@gclaim`), so fairness **between lanes** is the shipped ring rotation (`LMOVE ring ring LEFT
  RIGHT`, byte-unchanged — INV4) and fairness **between consumers** is that each block-move consumes one readiness
  token and serves; the thundering-herd / cross-lane-wake concern (a per-lane wake) is **deferred** to MECH-(iii)
  or a follow-up (FORK A-MECH — the Operator's call), NOT founded here under MECH-(i).
- Given the determinism hazard (a same-millisecond branded-id mint across concurrent consumers + the wake race),
  when the **≥100-iteration loop** runs the multi-consumer suite owning the machine, then it is green every run.

INVEST — independent (the multi-consumer fairness contract); testable by the `:valkey` "two parked consumers"
scenario under the ≥100 loop (a stream of admits → both consumers serve a share, neither starves); encodes
EMQ.4.3-INV1 (fair service across parked consumers) + EMQ.4.3-INV4 (the ring rotation byte-unchanged). Priority:
must · Size: 5 · Implements: EMQ.4.3-D (fair readiness distribution).

## EMQ.4.3-US4 — the primitive rides the shipped wire and never bypasses the atomic claim (the FROZEN-WIRE + §12.2 contract)

As a **protocol steward**, I want the new blocking-claim primitive to ride the **shipped connector** and keep the
atomic `@gclaim` as the only claim, so that founding the metronome primitive **does not break the wire** and does
not open a second, weaker transition path — the wire broke once, and §12.2 forbids a client-side pop that bypasses
the script layer's bookkeeping.

Acceptance criteria
- Given the founded primitive, when the lib diff is examined, then the block rides
  `EchoMQ.Connector.command/3` (a `BLMOVE`/`BLPOP` carried as parts, the shipped `consumer.ex:147` pattern) and
  the claim rides `EchoMQ.Connector.eval/5` (the atomic `@gclaim`) — **no new transport, no new connector verb,
  no `echo_wire` edit, no frozen-record change** (`Connector`/`RESP`/`Script` byte-unchanged); a grep of the
  metronome path for a new transport/connector verb returns empty; `echo/apps/echo_wire/lib/` is byte-unchanged
  in the diff.
- Given the primitive serves a lane, when the claim is examined, then the lane head is popped **inside `@gclaim`
  only** (`ZPOPMIN` inside the script, `lanes.ex:41`) — **never** a client-side `ZPOPMIN`/`LMOVE` of the
  lane/ring — so the **server-clock** `TIME` lease, the `attempts` fencing token, the `gactive` accounting, and
  the ring rotation stay one atomic Lua transition (§12.2); `@gclaim` is **byte-identical to HEAD** (INV4).
- Given the new blocking command enters the core inventory, when the version is checked, then the fence has
  climbed **`echomq:2.4.2` → `echomq:2.4.3`** in lockstep (the `mix.exs` label AND the `@wire_version`/
  `{emq}:version` fence together — D-3; the fence LOGIC frozen, only the constant moved), and the `:fence`
  conformance scenario (version-agnostic — asserts the live key `== Connector.wire_version()`) passes
  byte-unchanged; the computed-floor minor the blocking command raises (§12.5) is covered by this version step.

INVEST — independent (the wire-discipline contract); testable by the FROZEN-WIRE grep (`echo_wire/lib/`
byte-unchanged), the §12.2 grep (the lane pop is inside `@gclaim` only; `@gclaim` byte-frozen), and the `:fence`
scenario (live key `== 2.4.3`); encodes EMQ.4.3-INV3 (the wire law — ride the shipped connector, no new transport)
+ EMQ.4.3-INV4 (`@gclaim` byte-unchanged) + EMQ.4.3-INV2 (the claim stays atomic + server-clock). Priority: must ·
Size: 3 · Implements: EMQ.4.3-D (the blocking-claim primitive, FROZEN-WIRE) + the version climb.

## EMQ.4.3-US5 — the new scenarios grow the conformance set additively, the prior set byte-unchanged

As a **conformance maintainer**, I want the metronome scenario(s) added to the conformance set **additively** with
the prior **55** byte-unchanged and the count re-pinned in both pinning tests, so that the protocol's contract
grows by an **additive minor** (the wire never silently changes) and the count is a verifiable claim.

Acceptance criteria
- Given the metronome scenario(s), when `EchoMQ.Conformance.scenarios/0` is examined, then the new scenario(s) are
  **appended** with their probes **in the same change**, and the **55** prior scenarios are **byte-unchanged**
  (name + contract + verdict body, git-verified) — the `git diff` shows **only additions** to `scenarios/0`.
- Given the count grows, when both pinning tests are examined, then `conformance_run_test.exs`
  (`run/2 → {:ok, N}`) and `conformance_scenarios_test.exs` (`@run_order` length + the module-doc count) are
  **both** re-pinned **55 → N**; `Conformance.run/2` over a live Valkey-6390 connection prints **N** lines and
  returns `{:ok, N}`.
- Given the determinism posture, when the suite is the metronome process/lease suite, then the **≥100-iteration
  loop** is the proof of record (a same-millisecond mint + a lost-wakeup race are cross-run hazards) — the rung
  states the loop ran and was green owning the machine, NOT a multi-seed sweep alone.

INVEST — independent (the conformance-growth contract); testable by the `git diff` (only additions to
`scenarios/0`; the 55 prior byte-identical), both count pins updated, `run/2 → {:ok, N}`; encodes EMQ.4.3-INV5
(the additive-minor conformance law). Priority: must · Size: 2 · Implements: EMQ.4.3-D (the conformance
scenario(s) + the count re-pin).

## EMQ.4.3-US-GATE — the Valkey gate (the standing structural story; design §7)

As a **bus operator**, I want the metronome rung proven against a **live Valkey on 6390** with the honest-row
reporting and the grammar/version gate intact, so that "green" means proven on the truth engine, not asserted.

Acceptance criteria (the standing gate, design §7 / §8)
- Given the truth engine, when the suites run, then `valkey-cli -p 6390 ping` → `PONG` precedes any trust in a
  green board; the `:valkey` + process metronome suites run **inside `echo/apps/echo_mq`** (per-app, NEVER
  umbrella-wide; `--include valkey`); `TMPDIR=/tmp` for all `mix` (the ENOSPC overlay hazard).
- Given the version fence, when a connector connects, then `GET {emq}:version` → **`echomq:2.4.3`** (the lockstep
  climb from `2.4.2`); the grammar is total with the four-member reserve; the engine-hygiene allowlist {Valkey,
  Redis-as-the-historical-row} holds (no banned engine token in the rung's added source — the §8 assembled
  deny-list).
- Given honest-row reporting, when a claim is phrased, then it is phrased against **Valkey, current stable line**
  (the truth row, gating); a host without Valkey runs the probes elsewhere and reports them as that row, never
  the truth row.
- Given the determinism proof, when the rung reports, then the **≥100-iteration determinism loop** is green owning
  the machine (no concurrent liveness server, no sibling heavy I/O) — the lost-wakeup race + the same-millisecond
  mint are the cross-run hazards the loop guards.

INVEST — independent (the standing structural gate); testable by the live run on 6390 + the version probe + the
engine-hygiene test + the ≥100 loop; encodes the design §7/§8 gate + EMQ.4.3-INV1 (the ≥100 proof) +
EMQ.4.3-INV3 (the version). Priority: must · Size: 1 · Implements: the structural gate (every D-n's proof runs on
the truth engine).

## Coverage — every Deliverable → its story (provable from the text)

| Deliverable (from the body) | Story | Invariant(s) |
|---|---|---|
| FORK A-MECH ruled before any build artifact (the mechanism — the gate that opens the build) | (process gate; the body DoD + the prompt's build-choice gate) | — |
| The new blocking-claim primitive subsuming the `BLPOP wake` + `drain` two-step | EMQ.4.3-US1, US4 | INV1, INV2, INV3 |
| Lost-wakeup robustness by construction (no wake lost under a concurrent admit-then-park) | EMQ.4.3-US2 | INV1, INV2 |
| Fair readiness distribution across parked consumers | EMQ.4.3-US3 | INV1, INV4 |
| `@gclaim` stays the atomic claim (the block never bypasses it — §12.2); the FROZEN-WIRE verdict | EMQ.4.3-US4 | INV2, INV3, INV4 |
| *(If MECH-(iii))* per-lane readiness addressing, the wake-push logic byte-unchanged (INV4); the §6 grammar member ruled | EMQ.4.3-US3 (deferral noted), US4 | INV3, INV4 |
| The metronome conformance scenario(s), additive minor (prior 55 byte-unchanged; count re-pinned 55 → N) | EMQ.4.3-US5 | INV5 |
| The version climb 2.4.2 → 2.4.3 in lockstep (the floor-raise minor + the fence) | EMQ.4.3-US4, US-GATE | INV3 |
| The proof: `:valkey` + process suites green; the ≥100 determinism loop green; the byte-freeze grep; FROZEN-WIRE held; Apollo MANDATORY | EMQ.4.3-US2, US3, US-GATE | INV1, INV4 |
| Honest-row reporting (Valkey on 6390 the truth row) | EMQ.4.3-US-GATE | the §7/§8 gate |

Body: [`./emq.4.3.md`](emq.4.3.md) (authoritative) · Runbook: [`./emq.4.3.prompt.md`](emq.4.3.prompt.md) ·
Family: [`../emq.4.md`](../emq.4.md) (US3 — the metronome) · Design: [`../../../emq.design.md`](../../../../emq.design.md)
§4 row 4 / §12.2 / §12.5 / §5 / §6 / §7 / §8 · Approach:
[`../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
