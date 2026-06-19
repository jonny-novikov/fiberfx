# EMQ.4.3 · user stories — the park-don't-poll metronome (a metronome-as-system)

> Who wants the metronome-as-system, what they need, and how we know it works. Each story is Connextra with
> Given/When/Then acceptance, an INVEST line naming the invariant(s) it encodes, and a Priority/Size/Implements
> line; the file ends with a Coverage line mapping every Deliverable to ≥1 story. The standing
> **`EMQ.4.3-US-GATE`** carries the Valkey gate (design §7) — a structural gate. emq.4.3 is the THIRD sub-rung of
> the groups-deepened family (Movement II): **the park-don't-poll metronome**, **re-derived to MECH-(ii)** (the
> Operator's rulings D-1, D-2) — emq.4.3 founds the metronome as a **system**: a NEW supervised
> `EchoMQ.Metronome` process per queue owns the **single** `BLPOP emq:{q}:wake <beat>` block (the SHIPPED verb on
> the SHIPPED token) + a registry of idle consumers; on a wake it pokes the *k* registered-idle consumers over
> **BEAM messages**, **each running the byte-frozen `EchoMQ.Lanes.claim/3` (@gclaim) exactly once**
> (consumer-fair; re-poke when work remains). **`EchoMQ.Consumer` gained an ADDITIVE, OPT-IN `:metronome` POOL
> mode (D-3) and RETAINS `park/1` + its standalone loop byte-for-byte** — a standalone consumer is unchanged and
> still self-parks; the metronome is an opt-in coordinator for a POOL. The founding rides the shipped connector
> (`Connector.command/3` already carries the `BLPOP`, `consumer.ex:170`) with **no `echo_wire` change at all**
> (D-4: `@wire_version` byte-unchanged) and **NO floor-raise** (`BLPOP` is shipped). Past-tense: every emq.4.3
> surface is SHIPPED. The spec **body** [`./emq.4.3.md`](emq.4.3.md) (and the family
> [`../emq.4.md`](../emq.4.md)) is authoritative — when a derived artifact disagrees with the body, the body wins.
> **Risk: HIGH** — the founding reshapes a **BEAM process/lease surface** on the fairness-critical wake path (the
> metronome's serialization point + the registration contract) and adds the **multi-consumer fairness proof** the
> conformance suite lacks; a lost-wakeup race at the registration boundary + a same-millisecond branded-id mint
> are **cross-run** hazards → the proof is the `:valkey` PROCESS suite + the **≥100-iteration determinism loop**
> owning the machine, NOT a conformance scenario and NOT one green run; **Apollo MANDATORY**. **Both Operator
> forks are RULED** (FORK A = Arm B, D-1; FORK A-MECH = MECH-(ii),
> D-2; FORK A-MECH-§6 CLOSED by construction — the fan-out is BEAM messages, not a keyspace registry); the
> decision record is
> [`../../../../kb/metronome-design/metronome-fork-decision.md`](../../../../kb/metronome-design/metronome-fork-decision.md).

## EMQ.4.3-US1 — a job admitted while a consumer is registered-idle is served well before the beat (the headline metronome proof)

As a **bus consumer registered-idle at rest on an empty queue**, I want a job admitted to my lane to be **served
well before the beat** (not only when the beat next elapses), so that the bus is **prompt under load** while
costing the wire nothing at rest — a registered consumer is poked on availability, not on a poll.

Acceptance criteria
- Given a consumer **registered-idle** with the queue's metronome on a queue with **no** serviceable lane (the
  metronome holds the single `BLPOP emq:{q}:wake <beat>` block, the consumer is parked awaiting a `:claim_once`
  poke), when a job is admitted to a serviceable lane (`EchoMQ.Lanes.enqueue/5`, which `LPUSH`es the
  `emq:{q}:wake` LIST the metronome is blocked on and re-rings the lane), then the consumer **serves that job well
  before a full `beat_ms` elapses** (a fast `beat_ms`, e.g. 1000, with the job handled in well under that window
  — the assertion is **WELL BEFORE THE BEAT**, not "eventually") — the metronome unblocks on the LPUSH, pokes the
  registered-idle consumer, and the consumer runs the atomic byte-frozen `@gclaim` once (NOT by waiting out the
  beat as a poll, NOT by each consumer holding its own block).
- Given the job is served, when the handler answers `:ok`, then `@complete` settles it (the row deleted) and the
  consumer **re-registers idle** with the metronome (register-idle → `:claim_once` → `@gclaim` once →
  re-register) — the rest state is "registered-idle," the metronome's beat the fallback.
- Given the consumer is registered-idle, when **nothing** is admitted, then the metronome's block **returns on the
  beat** (`beat_ms` the fallback timeout) and the metronome's beat loop re-runs `reap → promote` (the cadence
  migrated from the consumer per SEAM-1) before re-blocking — the metronome's beat doubles as the pump cadence, so
  a due schedule still promotes without an admit.

INVEST — independent (the metronome's serve-well-before-beat contract); testable by the `:valkey` "admit while
registered" scenario (register a consumer with a slow-ish beat → admit a job → assert it is handled well before
the beat elapses — **a no-op that polls on the beat fails this assertion**); encodes EMQ.4.3-INV1 (the metronome
is sound — served well before the beat), EMQ.4.3-INV2 (`@gclaim` stays the atomic claim — the poke triggers it).
Priority: must · Size: 5 · Implements: the metronome process + the consumer rewire + lost-wakeup robustness.

## EMQ.4.3-US2 — no wake is lost when work arrives exactly as a consumer re-registers (the lost-wakeup race, the load-bearing proof)

As a **bus operator running a busy multi-tenant queue**, I want a job admitted in the **window between a
consumer's last claim and its re-registration** to still be served within the beat, so that a ready job is
**never hung** until the next beat by a lost wakeup — the robustness property the shipped happy-path two-step did
not gate at this depth.

Acceptance criteria
- Given a consumer that has just run its one `@gclaim` on a poke (its lane is momentarily empty) and is **about
  to re-register idle**, when a job is admitted **exactly at that registration boundary** (the classic lost-wakeup
  window: the admit's `LPUSH wake` races the consumer's transition back to registered-idle), then the job is
  **still served within the beat** — because the **metronome**, not the consumer, holds the single block on
  `emq:{q}:wake`: the metronome is **continuously blocked** (or re-blocking on its own beat) regardless of any
  individual consumer's registration state, so the admit's `LPUSH` satisfies the metronome's in-flight block and
  it pokes a registered consumer on the next round — the window closes **by construction** (the block is owned by
  the always-present metronome, not by a consumer transitioning between claims), not by a recheck-after-park.
- Given the race is run **repeatedly** (the admit timed to land at varied points around the registration
  boundary), when the **≥100-iteration determinism loop** runs the suite owning the machine, then **every**
  iteration serves the raced job within the beat — a lost wakeup that hangs the job until the next beat would
  surface as a cross-run flake the loop catches (one green run is NOT proof).
- Given a consumer crashes **mid-claim** (after a poke, before `@complete`), then its lane's work is **not lost**:
  the metronome **monitor-detects** the dead consumer and removes its registration (no orphaned registration), and
  the in-flight job is recovered by the standing server-clock lease + the `@reap`/`reap_group` recovery path
  (`@gclaim` set the `TIME` lease; the lapsed lease returns the member to its lane and re-rings it, with a wake
  the metronome catches) — **no leaked claim**.

INVEST — independent (the lost-wakeup robustness contract); testable by the `:valkey` "registration-boundary
race" scenario under the **≥100 loop** (admit at the boundary → served within the beat, every run) + the
crash-mid-claim case (the registration removed by monitor, the job reaped); encodes EMQ.4.3-INV1 (no lost wakeup,
the load-bearing proof) + EMQ.4.3-INV2 (the poke triggers `@gclaim`, never bypasses it). Priority: must · Size: 5
· Implements: lost-wakeup robustness + the registration/drain contract — **the load-bearing proof; the ≥100 loop
owns it.**

## EMQ.4.3-US3 — several registered consumers share a queue fairly (no consumer starves)

As a **bus operator scaling consumers horizontally on one queue** (the echo_bot Telegram-notification pool —
`emq.roadmap.md:31-32`), I want readiness **distributed fairly** across several registered consumers, so that
adding consumers adds throughput without **starving** any one of them — a registered consumer is not permanently
passed over while others serve.

Acceptance criteria
- Given **N (two or more)** consumers **registered-idle** with the same queue's metronome, when a **stream** of
  jobs is admitted across one or more serviceable lanes, then the metronome pokes the registered-idle consumers
  such that **each** makes progress — each claims and completes a share of the work over the run; **neither/none**
  is permanently starved (no consumer goes the whole run without serving while another serves the whole stream).
  The fairness mechanism is **one `@gclaim` per idle consumer per wake** — the metronome hands out exactly one
  claim authorization per registered-idle consumer per poke round (a poke-one-to-exhaustive-drain would let one
  worker hog the beat), and **re-pokes promptly** when work remains (so throughput holds while fairness is exact).
- Given the readiness signal is the shipped single per-queue `emq:{q}:wake` LIST (capped 64 — the metronome is the
  **single** blocker on it), when many admits push readiness, then the herd-of-blockers is **gone** (only the
  metronome's one connection blocks, not N consumers stampeding the shared token), and a poked consumer runs the
  rotating `@gclaim`, so fairness **between lanes** is the shipped ring rotation (`LMOVE ring ring LEFT RIGHT`,
  byte-unchanged — INV4) and fairness **between consumers** is the metronome's one-claim-per-idle-consumer
  dispatch; the per-lane wake / thundering-herd-by-lane refinement is **deferred** (the herd is already eliminated
  at the connection level), NOT founded here.
- Given the determinism hazard (a same-millisecond branded-id mint across concurrent consumers + the wake race),
  when the **≥100-iteration loop** runs the multi-consumer suite owning the machine, then it is green every run.

INVEST — independent (the multi-consumer fairness contract — the proof the conformance suite lacks, carried by the
`:valkey` PROCESS suite `metronome_test.exs` US3, not a conformance scenario); testable by
the `:valkey` "N registered consumers" scenario under the ≥100 loop (a stream of admits → each consumer serves a
share, none starves — **a no-op that pokes one consumer to exhaustive-drain fails the no-starvation assertion**);
encodes EMQ.4.3-INV1 (fair service across registered consumers, bounded starvation) + EMQ.4.3-INV4 (the ring
rotation + `@gclaim` byte-unchanged). Priority: must · Size: 5 · Implements: fair readiness distribution — **the
load-bearing multi-consumer proof.**

## EMQ.4.3-US4 — the registration contract composes with the consumer lifecycle (register/deregister + drain-on-stop)

As a **bus operator supervising a consumer pool**, I want a consumer's registration with the metronome to be
**clean across its whole lifecycle** — register on idle, deregister on death or stop, drain on `:shutdown` — so
that the metronome's registry never holds a **stale** entry (a dead consumer's pid) and a stop never **leaks** a
claim or **orphans** a registration.

Acceptance criteria
- Given a consumer registered-idle with the metronome, when the consumer **dies** (crash, kill, normal exit),
  then the metronome **monitor-detects** the `:DOWN` and **removes** the registration — the next poke round does
  NOT poke a dead pid (no orphaned registration); the metronome itself **survives** (a dead consumer is a
  registry removal, not a metronome crash).
- Given a consumer is registered-idle, when `EchoMQ.Consumer.stop/2` is called (the unsupervised owner's verb) or
  a supervisor sends `:shutdown`, then the consumer **deregisters** from the metronome at a settle point and
  exits cleanly (`:normal` for `stop/2`, `:shutdown` for the supervisor — the consumer traps exits and honors the
  control message at the settle point, modeled on the shipped `:emq_stop`/`{:EXIT, …}` discipline,
  `consumer.ex:104-112`); the job in hand (if poked mid-claim) settles, nothing more is claimed — **no leaked
  claim, no orphaned registration**.
- Given the metronome process itself **crashes** (the serialization point fails), when its supervisor restarts it,
  then no work is lost: any in-flight claim is protected by the server-clock lease + the `@reap`/`reap_group`
  recovery path, the restarted metronome re-blocks on `BLPOP emq:{q}:wake` and consumers re-register on their next
  idle transition — the metronome holds **no** Valkey lease of its own (its only block is a host-timeout `BLPOP`,
  INV2), so a restart is clean.

INVEST — independent (the registration/lifecycle contract); testable by the `:valkey` + process "consumer death →
registration removed" scenario (kill a registered consumer → assert the metronome does not poke its pid and
survives) + the "stop/shutdown drains" scenario (stop a registered consumer → no leaked claim, deregistered) + the
"metronome restart" case; encodes EMQ.4.3-INV1 (the metronome stays sound across consumer churn) + EMQ.4.3-INV2
(no metronome-owned lease; the server-clock lease + reap recover in-flight work). Priority: must · Size: 3 ·
Implements: the registration/drain contract + the host-wiring (the supervised lifecycle).

## EMQ.4.3-US5 — the primitive rides the shipped wire, never bypasses the atomic claim, and raises no floor (the FROZEN-WIRE + §12.2 contract)

As a **protocol steward**, I want the metronome-as-system to ride the **shipped connector**, keep the atomic
`@gclaim` as the only claim, and add **no** new core command, so that founding the metronome **does not break the
wire**, does not open a second weaker transition path, and does not raise the computed floor — the wire broke
once, §12.2 forbids a client-side pop that bypasses the script layer's bookkeeping, and MECH-(ii) was decided
over MECH-(iv-b) precisely to leave the safety-critical claim byte-frozen.

Acceptance criteria
- Given the metronome, when the lib diff is examined, then the block rides `EchoMQ.Connector.command/3` (a
  `BLPOP emq:{q}:wake <beat>` carried as parts — the IDENTICAL call the standalone `consumer.ex:170` park makes,
  in the metronome) and the poked consumer's claim rides `EchoMQ.Connector.eval/5` (the atomic
  `@gclaim`) — **no new transport, no new connector verb, no `echo_wire` logic edit, no frozen-record change**
  (`Connector`/`RESP`/`Script` byte-unchanged); a grep of the metronome path for a new transport/connector verb
  returns empty; `echo/apps/echo_wire/lib/` is **byte-identical to HEAD** in the diff (INCLUDING the
  `@wire_version` constant — D-4: zero wire-protocol delta).
- Given the metronome serves a lane, when the claim is examined, then the lane head is popped **inside `@gclaim`
  only** (`ZPOPMIN` inside the script, `lanes.ex:41`) — **never** a client-side `ZPOPMIN`/`LMOVE` of the
  lane/ring in `metronome.ex` or the rewired `consumer.ex` — so the **server-clock** `TIME` lease, the `attempts`
  fencing token, the `gactive` accounting, and the ring rotation stay one atomic Lua transition (§12.2);
  **`@gclaim` is byte-identical to HEAD** (INV4); the **10 wake-pushing scripts** are byte-identical to HEAD (the
  metronome blocks on the SAME `emq:{q}:wake` they push to); `keyspace.ex` is byte-identical to HEAD (the fan-out
  is BEAM messages — no §6 edit).
- Given **NO** new core command and **NO** new conformance scenario enter the inventory (D-4/D-5), when the
  version is checked, then the fence has **NOT** moved — `@wire_version` stays **`echomq:2.4.2`** byte-unchanged
  (`connector.ex:35`), and `{emq}:version` still reads `echomq:2.4.2` after connect — because emq.4.3 carries
  ZERO wire-protocol delta, so there is no additive-minor for the version record to reflect (the metronome adds no
  `BLMOVE`/`BLMPOP`, no new scenario; the P6 floor inventory is unchanged). The `mix.exs` `version: "2.4.3"`
  (`mix.exs:7`) is the roadmap-rung LABEL, independent of `echo_wire` — NOT a fence climb. The `:fence` conformance
  scenario (version-agnostic — asserts the live key `== Connector.wire_version()`) passes byte-unchanged.

INVEST — independent (the wire-discipline contract); testable by the FROZEN-WIRE grep (`echo_wire/lib/`
byte-identical to HEAD, INCLUDING `@wire_version`), the §12.2 grep (the lane pop is inside `@gclaim` only;
`@gclaim` + the 10 wake-push scripts + `keyspace.ex` byte-frozen), the floor-inventory check (no new core
command), and the `:fence` scenario (live key `== 2.4.2`); encodes EMQ.4.3-INV3 (the wire law — ride the shipped
connector, no new transport, NO floor-raise, NO version move) + EMQ.4.3-INV4 (`@gclaim` + the shipped scripts
byte-unchanged) + EMQ.4.3-INV2 (the claim stays atomic + server-clock). Priority: must · Size: 3 · Implements:
the FROZEN-WIRE verdict (zero wire delta).

## EMQ.4.3-US6 — the metronome adds NO conformance scenario; the proof is the process suite, the prior set byte-unchanged

As a **conformance maintainer**, I want the metronome proven by the **`:valkey` PROCESS suite** rather than a
conformance scenario — because the metronome introduces no wire behavior — with the conformance set and both
pinning tests **byte-unchanged**, so that the protocol's wire contract never silently changes (D-5) and "proven"
means proven on the surface that actually carries the risk (a process/lease/timing surface, not a
single-connection probe).

Acceptance criteria
- Given the metronome introduces no wire behavior (it rides the shipped `BLPOP` on the shipped token and triggers
  the byte-frozen `@gclaim`), when `EchoMQ.Conformance.scenarios/0` and both pinning tests are examined, then they
  are **byte-unchanged versus HEAD** — **NO scenario was added**; the `git diff` of `conformance.ex` +
  `conformance_run_test.exs` + `conformance_scenarios_test.exs` is **empty**; `Conformance.run/2` over a live
  Valkey-6390 connection returns `{:ok, 59}` byte-unchanged (the count the ewr client-floor + native-expiry rungs
  reached after this rung's seed was authored; emq.4.3 did not touch it).
- Given the proof, when the metronome is exercised, then it is the **`:valkey` PROCESS suite**
  (`metronome_test.exs` US1 served-well-before-the-beat + US2 lost-wakeup + US3 multi-consumer fairness + US4
  registration/drain + the F-2 synchronous-registration test) **and `metronome_core_test.exs`** (the pure
  `beat_ms/1`/`dispatch/1`/`repoke?/1` decisions) — not a conformance scenario, because a process/lease/timing
  surface is proven by a process suite under the ≥100 loop, not by a single-connection conformance probe.
- Given the determinism posture, when the suite is the metronome process/lease suite, then the **≥100-iteration
  loop** is the proof of record (a same-millisecond mint + a lost-wakeup race are cross-run hazards) — the rung
  states the loop ran and was green owning the machine, NOT a multi-seed sweep alone.

INVEST — independent (the no-scenario / process-proof contract); testable by the `git diff` of `conformance.ex` +
both pinning tests = empty, `run/2 → {:ok, 59}` byte-unchanged, and the `:valkey` process suite green under the
≥100 loop; encodes EMQ.4.3-INV5 (the additive-minor conformance law, satisfied NO-OP — no scenario added).
Priority: must · Size: 2 · Implements: the process-suite proof (no conformance scenario, no count re-pin).

## EMQ.4.3-US-GATE — the Valkey gate (the standing structural story; design §7)

As a **bus operator**, I want the metronome rung proven against a **live Valkey on 6390** with the honest-row
reporting and the grammar/version gate intact, so that "green" means proven on the truth engine, not asserted.

Acceptance criteria (the standing gate, design §7 / §8)
- Given the truth engine, when the suites run, then `valkey-cli -p 6390 ping` → `PONG` precedes any trust in a
  green board; the `:valkey` + process metronome suites run **inside `echo/apps/echo_mq`** (per-app, NEVER
  umbrella-wide; `--include valkey`); `TMPDIR=/tmp` for all `mix` (the ENOSPC overlay hazard).
- Given the version fence, when a connector connects, then `GET {emq}:version` → **`echomq:2.4.2`** (byte-unchanged
  — emq.4.3 carries zero wire-protocol delta, so the fence does NOT climb, D-4); the grammar is total with the
  four-member reserve and **UNEDITED** (the metronome fan-out is BEAM messages); the engine-hygiene allowlist
  {Valkey, Redis-as-the-historical-row} holds (no banned engine token in the rung's added source — the §8
  assembled deny-list).
- Given honest-row reporting, when a claim is phrased, then it is phrased against **Valkey, current stable line**
  (the truth row, gating); a host without Valkey runs the probes elsewhere and reports them as that row, never
  the truth row.
- Given the determinism proof, when the rung reports, then the **≥100-iteration determinism loop** is green owning
  the machine (no concurrent liveness server, no sibling heavy I/O) — the lost-wakeup race + the same-millisecond
  mint are the cross-run hazards the loop guards.

INVEST — independent (the standing structural gate); testable by the live run on 6390 + the version probe + the
engine-hygiene test + the ≥100 loop; encodes the design §7/§8 gate + EMQ.4.3-INV1 (the ≥100 proof) +
EMQ.4.3-INV3 (the version + the unedited grammar). Priority: must · Size: 1 · Implements: the structural gate
(every D-n's proof runs on the truth engine).

## Coverage — every Deliverable → its story (provable from the text)

| Deliverable (from the body) | Story | Invariant(s) |
|---|---|---|
| FORK A = Arm B (D-1), FORK A-MECH = MECH-(ii) (D-2), FORK A-MECH-§6 CLOSED — all ruled before the build | (process gate; the body DoD + the ledger D-1/D-2) | — |
| The NEW `EchoMQ.Metronome` + `EchoMQ.Metronome.Core` (supervised process per queue, single `BLPOP wake` block + idle-consumer registry + BEAM fan-out + pure decision core) | EMQ.4.3-US1, US3, US5 | INV1, INV2, INV3 |
| `EchoMQ.Consumer` rewired ADDITIVELY (D-3 — GAINS the opt-in `:metronome` POOL mode, RETAINS `park/1` + the standalone loop byte-for-byte; the `reap → promote` cadence is the metronome's for the pool path only) | EMQ.4.3-US1, US4 | INV1, INV2 |
| The host-wiring API — the NEW `EchoMQ.Queue` `rest_for_one` supervisor (host-started, no `mod:` auto-start — the library law) | EMQ.4.3-US4 | INV1 |
| Lost-wakeup robustness by construction (no wake lost under a concurrent admit-then-register) | EMQ.4.3-US2 | INV1, INV2 |
| Fair readiness distribution across registered consumers (one `@gclaim` per idle consumer per wake; bounded starvation) | EMQ.4.3-US3 | INV1, INV4 |
| The registration/drain contract (monitor-detected death, clean stop/shutdown, no orphaned registration, no leaked claim) | EMQ.4.3-US4 | INV1, INV2 |
| `@gclaim` stays the atomic claim (the poke never bypasses it — §12.2); the FROZEN-WIRE verdict; NO floor-raise; `keyspace.ex` byte-unchanged | EMQ.4.3-US5 | INV2, INV3, INV4 |
| NO conformance scenario (D-5 — the metronome adds no wire behavior); the proof is the `:valkey` PROCESS suite + the ≥100 loop; `conformance.ex` + both pin tests byte-unchanged, count 59 | EMQ.4.3-US6 | INV5 |
| NO version climb (D-4 — `@wire_version` stays `echomq:2.4.2`; `mix.exs` `2.4.3` is the roadmap LABEL, independent of `echo_wire`) | EMQ.4.3-US5, US-GATE | INV3 |
| The proof: `:valkey` + process suites green; the ≥100 determinism loop green; the byte-freeze grep (`@gclaim` + 10 wake-push + keyspace); FROZEN-WIRE held; Apollo MANDATORY | EMQ.4.3-US2, US3, US-GATE | INV1, INV4 |
| Honest-row reporting (Valkey on 6390 the truth row) | EMQ.4.3-US-GATE | the §7/§8 gate |

Body: [`./emq.4.3.md`](emq.4.3.md) (authoritative) · Runbook: [`./emq.4.3.prompt.md`](emq.4.3.prompt.md) ·
Family: [`../emq.4.md`](../emq.4.md) (US3 — the metronome) · Decision record:
[`../../../../kb/metronome-design/metronome-fork-decision.md`](../../../../kb/metronome-design/metronome-fork-decision.md)
(the MECH-(ii) ruling) · Design: [`emq.design.md`](../../../../emq.design.md) §4 row 4 / §12.2 / §12.5 / §5 / §6 /
§7 / §8 · Approach: [`../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
