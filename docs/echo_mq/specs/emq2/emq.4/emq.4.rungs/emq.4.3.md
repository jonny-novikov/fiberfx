# EMQ.4.3 · The park-don't-poll metronome — a metronome-as-system (Movement II, the groups family)

> **Status: ✅ SHIPPED — built to MECH-(ii), the metronome-as-system (the Operator's rulings D-1..D-5); this body
> reconciled BACKWARD to the as-built surface (Stage-5).** The THIRD sub-rung of the emq.4 "groups deepened"
> family; the family contract + the carve + the forks are [`../emq.4.md`](../emq.4.md) (authoritative — if this
> carve disagrees with the body, the body wins). emq.4.3 founds the **metronome as a system** — the wake/notify
> beat made a supervised process in its own right, the BCS law the whole stack is built to (*a system is an OTP
> process that owns its data privately and shares only messages*). **The Operator ruled FORK A → Arm B** (D-1:
> found a new blocking-claim primitive that subsumes the shipped wake-token two-step) and **FORK A-MECH →
> MECH-(ii)** (D-2: a dedicated, supervised metronome process per queue, decided over MECH-(iv-b) because it buys
> the entire multi-consumer benefit **reversibly** — delete a supervisor child — and leaves the safety-critical
> `@gclaim` byte-frozen). **Three settled rulings the build earned (D-3..D-5) are recorded below.** The decision
> record is
> [`../../../../kb/metronome-design/metronome-fork-decision.md`](../../../../kb/metronome-design/metronome-fork-decision.md).
> **What emq.4.3 built:** a NEW `EchoMQ.Metronome` (+ its pure decision core `EchoMQ.Metronome.Core`) — a
> supervised process per queue owning the **single** `BLPOP emq:{q}:wake <beat>` block (the SHIPPED verb on the
> SHIPPED token; **no new blocking command, NO floor-raise**) + a registry of idle consumers; on a wake it pokes
> the *k* registered-idle consumers over **BEAM messages**, **each running the byte-frozen `EchoMQ.Lanes.claim/3`
> (@gclaim) exactly once** (one claim per idle consumer per wake = consumer-fair; the metronome re-pokes promptly
> while work remains). **`EchoMQ.Consumer` gained an ADDITIVE, OPT-IN `:metronome` POOL mode (D-3)** — with a
> `:metronome` the consumer registers idle, awaits a `:claim_once`, claims once, settles, and re-registers, and
> runs no block or cadence of its own (the metronome owns the one block + the one beat per queue); **WITHOUT a
> `:metronome` the consumer is the shipped standalone loop BYTE-FOR-BYTE — it RETAINS `park/1` and runs its own
> reap/promote** (a lone consumer is no herd, and the live codemojex consumer is unchanged). The new
> `EchoMQ.Queue` supervisor (`rest_for_one`) is the host-wiring that starts ONE registered metronome FIRST + N
> opt-in consumers (SEAM-2 resolved). The founding is **host-started, no auto-start** (`echo_mq` is a library —
> `mix.exs` has no `mod:`). **Risk: HIGH** — the risk concentrated on the **BEAM process/lease surface** (the
> metronome's serialization point + the registration contract) and the **multi-consumer fairness proof** the
> conformance suite lacks; a **lost-wakeup race** at the registration boundary (closed at `poke_round/1`'s top by
> the F-1 mailbox drain) and a same-millisecond branded-id mint are **cross-run** hazards one green run cannot
> surface. **Apollo MANDATORY at build; the ≥100-iteration determinism loop owned the proof; the Director's verify
> deepened.** The v2 master invariant binds (`@gclaim` byte-frozen and never bypassed — design §12.2; the §6
> grammar UNEDITED — the fan-out is BEAM messages, not a keyspace registry; server clock where a lease is touched —
> the `@gclaim` `TIME` is the only lease; the inline `Script.new/2` law — no new script). **emq.4.3 carries ZERO
> wire-protocol delta (D-4/D-5): the metronome introduces no wire behavior, so `@wire_version` stays
> `echomq:2.4.2` and NO conformance scenario was added (the count is byte-unchanged).** The `mix.exs` `version:
> "2.4.3"` is the roadmap-rung LABEL (independent of `echo_wire` — `mix.exs:7`), NOT a fence climb. The proof of
> record is the `:valkey` PROCESS suite (`metronome_test.exs` US1–US4 + the F-2 synchronous-registration test +
> `metronome_core_test.exs`) and the ≥100-iteration determinism loop — NOT a conformance scenario. Past-tense:
> every emq.4.3 surface is SHIPPED.

## 0 · The slice — what emq.4.3 founded, and how the seed's wire deltas resolved at build

The family ([`../emq.4.md`](../emq.4.md)) deepens the shipped fair-lanes mechanism. emq.4.3 carved the
**metronome**. The foundation proved the *mechanism* — park on `BLPOP wake`, the beat as a fallback, a wake pushed
by every serviceable transition — on the happy path, with the beat fused into each `EchoMQ.Consumer`'s
`spawn_link` loop (every consumer is its own metronome). The Operator's rulings scoped emq.4.3 to **found the
metronome as a system**: a supervised process per queue owns the single block and fans readiness out to a pool of
*opt-in* registered consumers over BEAM messages, so the herd-of-blockers is gone (one connection blocks),
readiness is **fairly distributed** across consumers (one `@gclaim` per idle consumer per wake), and a job
admitted while a consumer is registered-idle is served **well before** the beat — with **no lost wakeup** by
construction. The rewire is **additive (D-3)**: the standalone consumer is untouched; the pool path is a new
opt-in mode beside it.

**The seed carried two forward-tense wire deltas; the build resolved BOTH to a NO-OP (D-4/D-5) — emq.4.3 is a
pure BEAM rung with zero wire-protocol delta:**

- **DELTA 1 (resolved NO-OP) — no conformance scenario, the count is byte-unchanged (D-5).** The seed planned
  "re-pin 55 → N" — adding a metronome conformance scenario. **As built, NO scenario was added**: the
  metronome-as-system introduces no wire behavior (it rides the shipped `BLPOP` on the shipped token and triggers
  the byte-frozen `@gclaim`), so there is nothing for a conformance scenario to exercise that the existing
  fair-lanes scenarios do not. `conformance.ex` and both pinning tests are byte-unchanged versus HEAD; the live
  count is **59** (`conformance_run_test.exs:48` `== {:ok, 59}`; `conformance_scenarios_test.exs` `@run_order`
  asserts exactly 59 names — note that count drifted to 59 from the ewr client-floor + native-expiry rungs that
  landed after this rung's seed was authored, NOT from emq.4.3). **The PROOF is the `:valkey` PROCESS suite**
  (`metronome_test.exs` US1–US4 + the F-2 synchronous-registration test; `metronome_core_test.exs` for the pure
  core) **+ the ≥100-iteration determinism loop**, NOT a conformance scenario — a process/lease/timing surface is
  proven by a process suite, not by a single-connection conformance probe.
- **DELTA 2 (resolved NO-OP) — the fence does NOT climb; `@wire_version` stays `echomq:2.4.2` (D-4).** The seed
  planned a lockstep climb `2.4.2 → 2.4.3` across the `mix.exs` label AND the `@wire_version`/`{emq}:version`
  fence. **As built, the fence did NOT move**: `connector.ex:35` `@wire_version "echomq:2.4.2"` is byte-unchanged,
  because emq.4.3 carries ZERO wire-protocol delta (no new command, no new scenario, no grammar edit) — there is
  no additive-minor for the version record to reflect. The `mix.exs` `version: "2.4.3"` (`mix.exs:7`) is the
  roadmap-rung LABEL, **explicitly INDEPENDENT of `echo_wire`** (the `mix.exs` comment says so), NOT a fence
  climb. The wire is byte-identical to HEAD; `{emq}:version` still reads `echomq:2.4.2` after connect. No
  computed-floor raise applies either — `BLPOP` is already in the shipped inventory (the shipped park rides it,
  `consumer.ex:170`).

The chapter's ruled spine grades emq.4.3 "founds a process/lease surface" — and under MECH-(ii) that grade is
**literal**: the metronome is a new supervised process owning a beat and a lease-adjacent block. The grade is
the rung's, the mechanism is ruled (D-2), and the **build-time seams** (§ below) resolved against the as-built
tree — never an Operator fork.

## Goal

emq.4.3 founds, inside `echo/apps/echo_mq`, a **metronome-as-system** for the **park-don't-poll metronome** over
the shipped `EchoMQ.Consumer` loop, the shipped `g:`-segment lane keyspace, the shipped `emq:{q}:wake` readiness
LIST, and the shipped `@gclaim` atomic claim, so that: (a) a NEW supervised `EchoMQ.Metronome` process per queue
(+ its pure decision core `EchoMQ.Metronome.Core`) owns the **single** `BLPOP emq:{q}:wake <beat>` block and a
**registry of idle consumers**, and on a wake pokes the *k* registered-idle consumers over **BEAM messages**, each
running the byte-frozen `EchoMQ.Lanes.claim/3` (@gclaim) **exactly once** — so
a job admitted to a serviceable lane while a consumer is registered-idle is **served well before the beat** (the
beat the fallback), with **no lost wakeup** under a concurrent admit-then-register, because the metronome holds the
single block on the very LIST the admit pushes to (the lost-wakeup window closes by construction at the
registration boundary, not by a recheck); (b) when several consumers register on one queue, readiness is
**distributed fairly** across them — one `@gclaim` per idle consumer per wake, the metronome re-poking promptly
when work remains — so **no consumer is permanently starved** and throughput holds; (c) the metronome's
registration contract composes with the consumer lifecycle — a dead consumer is **monitor-detected** and removed
from the registry, and `stop/2` / a supervisor `:shutdown` drains cleanly with **no orphaned registration and no
leaked claim**; (d) the block **rides the shipped connector** (`Connector.command/3` already carries an arbitrary
blocking command with a custom timeout — the shipped park's `BLPOP` is proof, `consumer.ex:147`) — **no new
connector verb, no `echo_wire` logic edit** — and the atomic `@gclaim` stays the only claim (the block NEVER
bypasses the lease/attempts/`gactive`/ring-rotation bookkeeping — design §12.2; it precedes the claim, it does not
replace it). Any lease the primitive touches reads `TIME` **server-side** (the as-built `@gclaim` pattern; the
block timeout is a host-side blocking-command timeout, NOT a lease). The metronome is **host-started, no
auto-start** (the library law — `echo_mq` has no `mod:`); emq.4.3 built the **host-wiring API** as the new
`EchoMQ.Queue` `rest_for_one` supervisor (`queue.ex` — SEAM-2 resolved), which starts ONE registered metronome
FIRST + N opt-in `:metronome` consumers under the host's supervision tree. **The `EchoMQ.Consumer` rewire is
ADDITIVE and OPT-IN (D-3): the consumer GAINS a `:metronome` POOL mode and RETAINS `park/1` + its standalone loop
BYTE-FOR-BYTE** — without a `:metronome` it self-parks and runs its own reap/promote exactly as shipped (the live
codemojex consumer is unchanged). The metronome does **not** break the wire: it raises **no** computed floor
(`BLPOP` is shipped), it edits **no** §6 grammar (the fan-out is BEAM messages, not a keyspace registry), and it
makes **no** wire-level move at all — `@wire_version` stays `echomq:2.4.2` and NO conformance scenario was added
(D-4/D-5: emq.4.3 carries ZERO wire-protocol delta, so there is no additive-minor for the version record to
reflect). The `mix.exs` `version: "2.4.3"` is the roadmap-rung LABEL, independent of `echo_wire`.

## Rationale (5W)

- **Why** — the metronome is the surface that makes the bus **cheap at rest and prompt under load**: a parked
  consumer costs the wire nothing, and a ready job is served within the beat. The foundation proved the *two-step*
  mechanism (park on a wake token, then drain) for a **single** consumer, where the shipped loop is already correct
  — sub-beat on the happy path, beat-bounded on a lost token, no lost work. The gap the foundation's design leaves
  is **multi-consumer**: with the beat fused into each consumer, N consumers on one queue all block on the **shared**
  `emq:{q}:wake` token (a cross-consumer thundering herd), and the beat is each consumer's private concern rather
  than a coordinated surface. The roadmap's headline-planned consumer makes that gap live: **echo_bot** — "Telegram
  notifications at scale" (`emq.roadmap.md:31-32`; the seam `EchoBot.Platform.Telegram.send_reply/3`) — is a
  notification **pool** (many sends, few queues). MECH-(ii) makes the beat a **system** (the stack's own law): one
  process per queue holds the single block and hands out one claim per idle consumer per wake, eliminating the herd
  at the connection level and distributing readiness fairly — **without** re-grading the safety-critical claim and
  **reversibly** (delete a supervisor child; the wire and `@gclaim` are byte-for-byte where they started). codemojex
  (one-lane-per-player today) is the degenerate one-consumer case — it does not need the metronome and is not
  harmed (a one-consumer pool is the trivial degenerate). These are the robustness + fairness properties a
  multi-tenant bus needs and the foundation's two-step did not gate at this depth.
- **What** — emq.4.3 builds (forward-named; re-probe the shipped `Consumer`/`@gclaim`/`wake` at the pre-build
  reconcile): (1) a **NEW `EchoMQ.Metronome`** — a supervised process per queue owning the single
  `BLPOP emq:{q}:wake <beat>` block + an idle-consumer registry, modeled on the shipped `Consumer` `spawn_link`-loop
  discipline (traps exits; owns a **dedicated connector lane** for the blocking verb), with a **pure decision core**
  (which idle consumers to poke / how many claims to authorize) testable without Valkey; on a wake it pokes the
  registered-idle consumers over BEAM messages, each running the byte-frozen `@gclaim` once, and **re-pokes
  promptly** when work remains; (2) **`EchoMQ.Consumer` rewired ADDITIVELY (D-3)** — it GAINS an opt-in
  `:metronome` POOL mode (register-idle with the metronome → receive a `:claim_once` message → run `@gclaim` once →
  re-register) and **RETAINS `park/1` + its standalone loop byte-for-byte**; without a `:metronome` it self-parks
  and runs its own `reap → promote` exactly as shipped (the metronome is an opt-in coordinator for a POOL, not a
  replacement of the standalone consumer — the live codemojex consumer is unchanged). The one-beat-per-queue
  `reap → promote` cadence lives on the metronome's loop for the pool path (SEAM-1 resolved: `metronome.ex` runs
  `Jobs.reap` + `Jobs.promote` per beat, then blocks); (3) the **host-wiring API** — the new `EchoMQ.Queue`
  `rest_for_one` supervisor (`queue.ex`; SEAM-2 resolved) that starts ONE registered metronome FIRST + N opt-in
  consumers under the host's supervisor (the library law — host-started, no `mod:` auto-start); (4) **lost-wakeup
  robustness by construction** (no wake lost under a concurrent admit-then-register — closed at `poke_round/1`'s top
  mailbox drain, F-1), **fair** readiness distribution across registered consumers, and a **clean
  registration/drain contract** (monitor-detected death, no orphaned registration, no leaked claim); (5) **NO
  conformance scenario was added (D-5)** — the metronome introduces no wire behavior, so the proof is the
  `:valkey` **process** suite (`metronome_test.exs` US1–US4 + the F-2 synchronous-registration test;
  `metronome_core_test.exs` for the pure core), not a conformance scenario (the prior count is byte-unchanged);
  (6) the `:valkey` + **process** test suites + the **≥100-iteration determinism loop** owning the machine;
  (7) **NO version climb (D-4)** — `@wire_version` stays `echomq:2.4.2` (zero wire-protocol delta); the `mix.exs`
  `version: "2.4.3"` is the roadmap-rung LABEL, independent of `echo_wire`.
- **Who** — the program (the rung that founds the metronome system); the bus's **consumers**, who gain
  herd-free, fairly-served, lost-wakeup-free blocking via the metronome; **echo_bot's planned Telegram pool** (the
  pivot consumer the founding is justified by); **Apollo**, who re-runs the gate ladder + the ≥100 loop
  independently (**MANDATORY** — the rung founds a process/lease surface on the fairness-critical wake path). The
  shipped `EchoMQ.Consumer` loop, the `@gclaim` atomic claim, and the wake protocol are the proven precedents it
  builds on; the `EchoMQ.Pump` opt-in cadence child (`pump.ex` — owner-started, no `mod:`, a pure tick/batch
  decision core) is the **precedent for the library-law process shape** the metronome follows.
- **When** — Movement II, the groups family's **third** sub-rung, after emq.4.1 (control plane — SHIPPED) and
  emq.4.2 (group-aware recovery — SHIPPED). SHIPPED this cycle (built to MECH-(ii) per D-1, D-2) — no Operator fork
  remained open (FORK A = Arm B, D-1; FORK A-MECH = MECH-(ii), D-2; FORK A-MECH-§6 CLOSED by construction). The
  build ran in two Mars passes (the core primitive, then the multi-consumer proof) to avoid single-agent overload.
- **Where** — `echo/apps/echo_mq` only (the as-built touch-set): a **NEW `metronome.ex`** (the supervised
  metronome process — the HIGH-RISK process-surface addition; Apollo MANDATORY) + a **NEW `metronome/core.ex`**
  (`EchoMQ.Metronome.Core` — the pure decision core: `beat_ms/1`, `dispatch/1`, `repoke?/1`), `consumer.ex`
  (EDIT — **ADDITIVE: GAINS the opt-in `:metronome` POOL mode and RETAINS `park/1` + the standalone loop
  byte-for-byte**, D-3; the standalone loop still owns its own `reap → promote`, the pool path runs none), a
  **NEW `queue.ex`** (`EchoMQ.Queue` — the host-wiring `rest_for_one` supervisor that starts ONE registered
  metronome FIRST + N opt-in consumers; SEAM-2 resolved), `mix.exs` (EDIT — the roadmap-rung LABEL `version:
  "2.4.3"`, INDEPENDENT of `echo_wire`; NOT a fence climb), and `test/*` (NEW — `metronome_test.exs` US1–US4 +
  the F-2 synchronous-registration test + `metronome_core_test.exs`, modeled on `consumer_test.exs`). **`conformance.ex`
  is UNTOUCHED** (D-5 — NO scenario added; the count is byte-unchanged) and **the two pinning tests are UNTOUCHED**
  (no count re-pin). **`echo_wire` is UNTOUCHED, INCLUDING the `@wire_version` constant** (D-4 — `connector.ex:35`
  stays `echomq:2.4.2`; emq.4.3 carries ZERO wire-protocol delta: the block rides the shipped
  `Connector.command/3` `BLPOP` — no new transport, no new connector verb, no facade change, no frozen-record edit;
  INV3 — see the FROZEN-WIRE VERDICT below). **The shipped `@gclaim`, the 10 wake-pushing scripts, and `keyspace.ex`
  are UNTOUCHED** (byte-frozen — the metronome blocks on the SAME shipped `emq:{q}:wake` token they push to, and
  the fan-out is BEAM messages, not a keyspace registry; INV4). `apps/echomq` is **UNTOUCHED** (the capability
  reference).

### The FROZEN-WIRE VERDICT (the headline reconcile finding — Venus surfaces, the Director carries it)

`EchoMQ.Connector` / `RESP` / `Script` are **frozen by committed records** (`echo_wire.ex:12-14`: "Module names
`EchoMQ.Connector`, `EchoMQ.RESP`, and `EchoMQ.Script` are frozen by the committed records that cite them"; the
`EchoWire` facade is the forward-facing name). The connector's public surface is `command/3`, `pipeline/3`,
`eval/5`, `push_command/3`, `subscribe/2`, `unsubscribe/2`, `noreply_pipeline/3`, `transaction_pipeline/3`,
`stats/1`, `wire_version/0`. **`command/3` (`connector.ex:49`) carries an ARBITRARY command as
`[binary | integer | atom]` parts with a custom `timeout` — the shipped (and RETAINED) park `BLPOP` rides it
(`consumer.ex:170` = `Connector.command(s.conn, ["BLPOP", wake, secs], s.beat_ms + 2_000)`).** The metronome's
single `BLPOP emq:{q}:wake <beat>` block rides the **same** `command/3` verb — the **identical** call the
standalone park makes (`metronome.ex:142`), in the metronome process for the pool path. **Therefore: MECH-(ii)
rides the existing connector with NO `echo_wire` LOGIC edit and NO frozen-record change.** The connector is a
serialized FIFO `GenServer`, so a blocking `command/3` holds the WHOLE connector for the block — but the metronome
**owns its own connector lane** for its single blocking verb (the `:conn`/`:connector` start option,
`metronome.ex:61-69`, modeled on the consumer's "blocking verbs get their own lane (Appendix B)" discipline), so a
long block on the metronome's own lane starves no other caller. **There is NO computed-floor raise** — `BLPOP` is
already in the shipped inventory (the shipped park rides it), so the metronome adds **no** new core command (this
is the decisive difference from the provisional MECH-(i)/(iv-b) drafts, which would have introduced `BLMOVE`/a
script re-grade). **As built, there is NO wire-level cost at all (D-4/D-5):** emq.4.3 carries ZERO wire-protocol
delta — no new command, no new conformance scenario, no grammar edit — so there is no additive-minor for the
version record to reflect, and `@wire_version` stays `echomq:2.4.2` byte-unchanged (`connector.ex:35`). The
`echo_wire` lib is byte-identical to HEAD. The `mix.exs` `version: "2.4.3"` is the roadmap-rung LABEL, independent
of `echo_wire` (the records freeze the connector's contract; the metronome neither touches the contract nor moves
the version string).

## Scope

- **In** — the founded metronome-as-system: (1) the **NEW `EchoMQ.Metronome`** supervised process per queue (+
  the **NEW `EchoMQ.Metronome.Core`** pure decision core) — the single `BLPOP emq:{q}:wake <beat>` block + the
  idle-consumer registry + the BEAM-message fan-out (one `@gclaim` per idle consumer per wake; re-poke when work
  remains) + the pure decision core; (2) **`EchoMQ.Consumer` rewired ADDITIVELY (D-3)** (GAINS the opt-in
  `:metronome` POOL mode and RETAINS `park/1` + the standalone loop byte-for-byte; the one-beat-per-queue cadence
  is the metronome's for the pool path, the standalone consumer keeps its own); (3) the **host-wiring API** — the
  NEW `EchoMQ.Queue` `rest_for_one` supervisor (host-started, no `mod:` auto-start — the library law); (4)
  **lost-wakeup robustness by construction** (no wake lost under a concurrent admit-then-register — the
  load-bearing proof); (5) **fair** readiness distribution across registered consumers (no consumer permanently
  starved); (6) the **registration/drain contract** (monitor-detected consumer death, clean `stop/2` + `:shutdown`
  drain, no orphaned registration, no
  leaked claim); (7) **NO conformance scenario (D-5)** — the metronome introduces no wire behavior, so the proof is
  the `:valkey` PROCESS suite (`metronome_test.exs` US1–US4 + the F-2 synchronous-registration test;
  `metronome_core_test.exs`), and the prior conformance count is byte-unchanged; (8) the `:valkey` + **process**
  test suites + the **≥100-iteration determinism loop** owning the machine (one green run is NOT proof — a
  lost-wakeup race + a same-millisecond mint are cross-run hazards); (9) **NO version climb (D-4)** — `@wire_version`
  stays `echomq:2.4.2` (zero wire-protocol delta); `mix.exs` `version: "2.4.3"` is the roadmap-rung LABEL,
  independent of `echo_wire`; (10) honest-row reporting (Valkey on 6390 the truth row); **Apollo MANDATORY** (the
  process/lease surface).
- **Out** — a **new transport / connector verb** (the block rides the shipped `Connector.command/3` `BLPOP` — INV3;
  no `SSUBSCRIBE`, no facade change, no frozen-record edit); a **new blocking command / a computed-floor raise**
  (MECH-(ii) uses the SHIPPED `BLPOP` — no `BLMOVE`/`BLMPOP`, no floor-raise; the provisional MECH-(i)/(iv-b)
  drafts' floor-raise does NOT apply); **bypassing `@gclaim`** (the metronome's poke triggers the atomic `@gclaim`,
  which NEVER pops the lane/ring outside the script — the lease/attempts/`gactive`/ring-rotation bookkeeping stays
  one Lua script, design §12.2; the block precedes the claim, it does not replace it); an **`@gclaim` edit** (it is
  byte-frozen — MECH-(ii) was decided over MECH-(iv-b) precisely to leave the safety-critical claim untouched); a
  **§6 grammar edit** (the fan-out is BEAM messages, not a keyspace registry — `keyspace.ex` untouched; FORK
  A-MECH-§6 CLOSED by construction); a **`mod:` auto-start** (the library law — host-started only); a **host clock**
  on any lease (server clock only — INV2); the **control plane** (emq.4.1 — SHIPPED); the **group-scoped recovery**
  (emq.4.2 — SHIPPED); the **weighted/deficit rotation** (emq.4.4 — the metronome's poke runs `@gclaim`, which
  serves *a* serviceable lane via the byte-frozen ring rotation; *which* serviceable lane and in what share is the
  rotation, a separate rung — and MECH-(ii) leaves that rotation-fairness seam **inside** `@gclaim` for 4.4's Fork
  B, unforeclosed); any **edit to a shipped lane/job/recovery script's logic** (the 10 wake-pushing scripts + the
  `@gclaim` byte-frozen — INV4); a **per-lane readiness LIST / per-lane wake** (the herd is eliminated at the
  connection level by the single blocker — a per-lane refinement is deferred, not founded); **any `echo_wire`
  change at all** (D-4 — the `echo_wire` lib is byte-identical to HEAD, INCLUDING the `@wire_version` constant: zero
  wire-protocol delta); a **DROP of the consumer's standalone `park/1`** (D-3 — the rewire is additive; the
  standalone consumer is untouched); any **edit to the frozen v1 line**.

## Invariants (the subset emq.4.3 carries, from the family EMQ.4-INV1–8)

- **EMQ.4.3-INV1 (← EMQ.4-INV7) — the metronome is sound (no lost wakeup; fair across registered consumers;
  bounded starvation).** A consumer registered-idle with the metronome **serves the ready lane well before the
  beat** when a lane becomes serviceable, and a wake is **never lost** under a concurrent admit-then-register (a
  job admitted in the window between a consumer's last claim and its re-registration is still served within the
  beat — the metronome holds the single block on the very `emq:{q}:wake` LIST the admit pushes to, so the
  lost-wakeup window closes **by construction** at the registration boundary); when several consumers register,
  readiness is **distributed fairly** (one `@gclaim` per idle consumer per wake; the metronome re-pokes promptly
  when work remains) and **no consumer is permanently starved**. *Check:* the `:valkey` metronome scenario (admit a
  job while a consumer is registered-idle → served well before the beat elapses, NOT only on the beat) + a
  lost-wakeup race scenario (admit exactly at the registration boundary → still served within the beat) + a
  multi-consumer fairness scenario (N registered consumers, a stream of admits → distinct service, each makes
  progress, none starves) — the load-bearing proof; the **≥100-iteration determinism loop** owns it (the race +
  the same-millisecond mint surface only across runs).
- **EMQ.4.3-INV2 (← EMQ.4-INV5) — server clock where a lease is touched; `@gclaim` is the claim.** The atomic
  `@gclaim` stays the claim — the lease is `redis.call('TIME')` server-side inside `@gclaim` (`lanes.ex:50-51`),
  attempts the fencing token; the metronome's poke triggers `@gclaim`, which NEVER pops the lane/ring outside the
  script (design §12.2 — no second, weaker transition path). The metronome's `BLPOP` block timeout is a host-side
  blocking-command timeout (`beat_ms`-derived), **not** a lease, and the metronome owns no Valkey lease of its own.
  *Check:* a grep of the metronome path shows the lane pop is inside `@gclaim` only (no client-side
  `ZPOPMIN`/`LMOVE` of the lane/ring in `metronome.ex` or the rewired `consumer.ex`); `@gclaim`'s lease is
  `redis.call('TIME')`; no host timestamp computes a lease.
- **EMQ.4.3-INV3 (← EMQ.4-INV1) — the wire law (ride the shipped connector; NO floor-raise; FROZEN-WIRE).** The
  metronome's block rides the shipped `Connector.command/3` (`BLPOP` carries as parts — the IDENTICAL call the
  shipped park makes) + the poked consumer's `@gclaim` rides `Connector.eval/5` — **no new transport**, **no new
  connector verb**, **no `echo_wire` LOGIC edit**, **no frozen-record change** (`Connector`/`RESP`/`Script`
  byte-unchanged), **no `SSUBSCRIBE`**, **no new wire class**, and **NO computed-floor raise** (`BLPOP` is already
  in the shipped inventory — the metronome adds no new core command). The fan-out is **BEAM messages**, so the §6
  grammar is **UNEDITED** (no new keyspace member). **As built, there is NO wire-level change at all (D-4):** the
  `echo_wire` lib is byte-identical to HEAD, INCLUDING the `@wire_version` constant — `connector.ex:35` stays
  `echomq:2.4.2`, because emq.4.3 carries ZERO wire-protocol delta (no new command, no new conformance scenario,
  no grammar edit), so there is no additive-minor for the version record to reflect. The readiness signal stays the
  shipped per-queue `emq:{q}:wake` (a registered §6 `type`, `keyspace_extend_test.exs` lists it) — no new §6
  member. *Check:* a grep of the metronome path for a new transport/connector verb returns empty; `echo_wire/lib/`
  byte-identical to HEAD (the `@wire_version` constant unchanged); the computed-floor inventory (the P6 probe) is
  unchanged (no `BLMOVE`/`BLMPOP` enters); `{emq}:version` reads `echomq:2.4.2` after connect; `keyspace.ex`
  byte-unchanged.
- **EMQ.4.3-INV4 (← EMQ.4-INV3) — the shipped surface is byte-unchanged; the metronome is NEW/additive.** The
  shipped lane/job/recovery scripts' **logic** is byte-unchanged — **`@gclaim` stays byte-identical to HEAD** (the
  metronome's poke triggers it, never edits it), and the **10 wake-pushing scripts** (`lanes.ex` `@genqueue` /
  `@gresume` / `@glimit` / `@greassign` / `@greap_group`; `jobs.ex` `@complete` / `@retry` / `@promote` / `@reap`;
  `stalled.ex` `@sweep_stalled`) are byte-identical to HEAD (the metronome blocks on the SAME `emq:{q}:wake` token
  they push to — `grep redis.call` on the lib diff = 0); `keyspace.ex` byte-unchanged (no §6 edit). The metronome
  process (`metronome.ex`), its pure core (`metronome/core.ex`), and the host-wiring supervisor (`queue.ex`) are
  NEW modules (additive); `consumer.ex` is rewired **ADDITIVELY (D-3)** — it GAINS the opt-in `:metronome` POOL
  mode and **RETAINS `park/1` + the standalone loop byte-for-byte** (a NEW process-coordination addition, not a
  script edit, and not a removal). The prior fair-lanes conformance scenarios pass **byte-unchanged**. *Check:* the
  byte-freeze grep on `@gclaim` + the 10 wake-push scripts in the lib diff = 0; `keyspace.ex` byte-identical to
  HEAD; the standalone `park/1` + `loop/1` retained in `consumer.ex`; the prior scenarios git-verified unchanged.
- **EMQ.4.3-INV5 (← EMQ.4-INV6) — the additive-minor conformance law (satisfied NO-OP: D-5, no scenario added).**
  emq.4.3 introduces no wire behavior, so it adds **NO** conformance scenario — `conformance.ex` and both pinning
  tests are byte-unchanged versus HEAD. The proof of the metronome is the `:valkey` PROCESS suite
  (`metronome_test.exs` US1–US4 + the F-2 synchronous-registration test; `metronome_core_test.exs` for the pure
  core) + the ≥100-iteration determinism loop — NOT a conformance scenario (a process/lease/timing surface is
  proven by a process suite, not a single-connection conformance probe). The live count stays **59** (the count the
  ewr client-floor + native-expiry rungs reached AFTER this rung's seed was authored; emq.4.3 did not touch it).
  *Check:* `git diff` of `conformance.ex` + the two pinning tests = empty; `Conformance.run/2` returns `{:ok, 59}`
  byte-unchanged.

## The rung's forks — all Operator forks RULED; the build-time seams RESOLVED at build

> **Both Operator forks are RULED.** FORK A = **Arm B** (D-1: found a new blocking-claim primitive that subsumes
> the shipped wake-token two-step). FORK A-MECH = **MECH-(ii)** (D-2: the metronome-as-system, decided over
> MECH-(iv-b) on reversibility — it buys the multi-consumer benefit by adding a deletable supervisor child, where
> (iv-b) buys it by re-grading the frozen `@gclaim`). FORK A-MECH-§6 is **CLOSED by construction** (the fan-out is
> BEAM messages, not a keyspace registry — no §6 grammar edit). The decision record is
> [`../../../../kb/metronome-design/metronome-fork-decision.md`](../../../../kb/metronome-design/metronome-fork-decision.md)
> (the Director's synthesis of the two-architect consultation + the rulings).

### The build-time seams — RESOLVED (the as-built resolution, synced backward at Stage-5)

> Three build seams were left to the build's Stage-0 reconcile against the as-built tree (none an Operator fork —
> the architecture is ruled, D-2). Their as-built resolutions:
>
> - **SEAM-1 — the reap/promote cadence migration. RESOLVED: metronome-owned for the pool path; UNCHANGED for the
>   standalone consumer.** The metronome's beat loop runs `Jobs.reap` then `Jobs.promote` once per beat, then holds
>   the single `BLPOP wake` block (`metronome.ex:125-132`). An opt-in `:metronome` consumer runs NO `reap/promote`
>   of its own (it registers, claims once on a poke, re-registers — `consumer.ex:185-215`). **The standalone
>   consumer is unchanged — it still runs its own `reap → promote` per beat** (`consumer.ex:114-121`). The
>   one-beat-per-queue intent holds for the pool; the standalone path is byte-for-byte the shipped loop.
> - **SEAM-2 — the host-wiring API shape. RESOLVED: a NEW `EchoMQ.Queue` `rest_for_one` supervisor (`queue.ex`).**
>   `EchoMQ.Queue.start_link/1` (`use Supervisor`) starts ONE `EchoMQ.Metronome` FIRST (registered by name via
>   `metronome_name/1`, so a consumer resolves it at start) + N opt-in `:metronome` consumers under
>   `rest_for_one`, with a `child_spec/1` for the host's tree (`queue.ex:21-100`). It lives in its own module (not
>   `metronome.ex`/`consumer.ex`), modeled on `EchoMQ.Pool`'s `use Supervisor` discipline. No hidden boot — the
>   host starts an `EchoMQ.Queue` (a pool) or an `EchoMQ.Consumer` standalone (a lone consumer).
> - **SEAM-3 — the registration message protocol. RESOLVED.** A consumer registers idle with
>   `{:register_idle, self()}` (`consumer.ex:190`); the metronome monitors it (`Process.monitor/1`, once per pid)
>   and appends it to an ordered idle list (head = idle-longest, the fair tie-break, `metronome.ex:206-214`); it
>   pokes one `{:claim_once, self()}` per registered-idle consumer per wake (`metronome.ex:154-170`), and the
>   consumer claims once then re-registers. A `{:deregister, pid}` (the consumer's clean stop/shutdown courtesy)
>   demonitors + drops it; a monitored `:DOWN` forgets it (no orphaned registration — `metronome.ex:178-232`).
>   **F-1** (the lost-wakeup fix): `poke_round/1` drains its mailbox at the TOP, BEFORE dispatch, so a registration
>   that arrived during the `BLPOP` block is folded in and not stranded for a beat. **F-2** (the synchronous-
>   registration fix): a `:name`d metronome registers its name from the PARENT on the returned pid BEFORE
>   `start_link` returns (`metronome.ex:83-94`), so a consumer's first `send(name, {:register_idle, …})` cannot
>   raise on an unregistered atom.

## Definition of Done

- [x] **FORK A** confirmed RULED (Arm B — found a new blocking-claim primitive, D-1) and **FORK A-MECH** confirmed
      RULED (MECH-(ii) — the metronome-as-system, D-2); **FORK A-MECH-§6** confirmed CLOSED by construction (BEAM
      fan-out, no §6 edit) — all recorded on the ledger before the build (no Operator fork remained open).
- [x] The **NEW `EchoMQ.Metronome`** built (`metronome.ex`) — a supervised process per queue owning the single
      `BLPOP emq:{q}:wake <beat>` block (riding `Connector.command/3`, the standalone park's verb — NO floor-raise)
      + an idle-consumer registry + the BEAM-message fan-out (one `@gclaim` per idle consumer per wake, re-poke
      when work remains) + a **pure decision core** `EchoMQ.Metronome.Core` (`metronome/core.ex` — `beat_ms/1`,
      `dispatch/1`, `repoke?/1`) testable without Valkey; modeled on the shipped `Consumer` `spawn_link`-loop
      discipline (traps exits, its own connector lane).
- [x] **`EchoMQ.Consumer` rewired ADDITIVELY (D-3)** — it GAINS an opt-in `:metronome` POOL mode (register-idle →
      `:claim_once` → run the byte-frozen `@gclaim` once → re-register, `consumer.ex:185-256`) and **RETAINS
      `park/1` + the standalone loop byte-for-byte** (`consumer.ex:114-172` — the standalone consumer self-parks
      and runs its own `reap → promote`). The metronome owns the one-beat-per-queue cadence for the POOL path only
      (SEAM-1 resolved); the standalone path is unchanged.
- [x] The **host-wiring API** built (SEAM-2 resolved): the NEW `EchoMQ.Queue` `rest_for_one` supervisor
      (`queue.ex`) starts ONE registered metronome FIRST + N opt-in `:metronome` consumers under the host's
      supervisor (the library law — host-started, no `mod:` auto-start; modeled on `EchoMQ.Pool`'s `use Supervisor`
      discipline).
- [x] **Lost-wakeup robustness by construction** (no wake lost under a concurrent admit-then-register — the
      metronome holds the single block on the LIST the admit pushes to, and `poke_round/1` drains its mailbox at
      the TOP before dispatch, F-1) + **fair** readiness distribution across registered consumers (no consumer
      permanently starved) + a clean **registration/drain contract** (monitor-detected consumer death removes the
      registration; `stop/2` + `:shutdown` drain with no orphaned registration, no leaked claim).
- [x] The block **NEVER bypasses `@gclaim`** (§12.2 — the metronome's poke triggers the atomic claim via
      `Lanes.claim/3`; the lane/ring pop is inside `@gclaim` only); **`@gclaim` byte-unchanged**; the **10
      wake-pushing scripts** byte-unchanged (the metronome blocks on the SAME shipped `emq:{q}:wake`);
      `keyspace.ex` byte-unchanged (no §6 edit — INV4).
- [x] **NO conformance scenario added (D-5)** — the metronome introduces no wire behavior, so `conformance.ex` and
      both pinning tests are byte-unchanged versus HEAD; the live count stays **59** (`Conformance.run/2 →
      {:ok, 59}`). The PROOF is the `:valkey` PROCESS suite (`metronome_test.exs` US1–US4 + the F-2
      synchronous-registration test; `metronome_core_test.exs`) + the ≥100 loop, NOT a conformance scenario.
- [x] **NO version climb (D-4)** — emq.4.3 carries ZERO wire-protocol delta, so `@wire_version` stays
      `echomq:2.4.2` byte-unchanged (`connector.ex:35`); `{emq}:version` still reads `echomq:2.4.2` after connect.
      The `mix.exs` `version: "2.4.3"` (`mix.exs:7`) is the roadmap-rung LABEL, INDEPENDENT of `echo_wire` — NOT a
      fence climb (no new core command, no additive-minor scenario, so nothing for the version record to reflect).
- [x] The proof: the `:valkey` + **process** metronome suites green per-app; the **≥100-iteration determinism
      loop** green owning the machine (the lost-wakeup race + the mint hazard); the shipped script logic
      byte-unchanged (`@gclaim` + the 10 wake-push scripts; `keyspace.ex`) — INV4; the **FROZEN-WIRE** verdict held
      (`echo_wire/lib/` byte-identical to HEAD, INCLUDING the `@wire_version` constant; no new connector verb; no
      floor-raise); honest-row reporting (Valkey on 6390); **Apollo MANDATORY** — the dedicated evaluator re-ran the
      whole ladder + the loop independently and re-verified the byte-unchanged conformance + the frozen wire + the
      byte-frozen `@gclaim`; **the Director's verify deepened** (the ≥100 loop + the multi-consumer fairness probe +
      a net-zero mutation spot-check).
- [x] INV1–INV5 verified as runnable checks; the spec body ([`../emq.4.md`](../emq.4.md)) remains authoritative;
      the as-built reconcile synced this body post-build (the backward reconcile owed — the emq.4.2 F6 lesson; the
      build-time seams SEAM-1/2/3 synced to their as-built resolution).

Family: [`../emq.4.md`](../emq.4.md) (the contract, the carve, the forks — authoritative) · Chapter stories:
[`../emq.4.stories.md`](../emq.4.stories.md) (US3 — the metronome) · Rung stories:
[`./emq.4.3.stories.md`](emq.4.3.stories.md) · Rung runbook: [`./emq.4.3.prompt.md`](emq.4.3.prompt.md) · Decision
record: [`../../../../kb/metronome-design/metronome-fork-decision.md`](../../../../kb/metronome-design/metronome-fork-decision.md)
(the FORK A-MECH ruling MECH-(ii) + the two-architect synthesis) · As-built floor (the build target — re-probe at
the pre-build reconcile; line numbers are hints): `consumer.ex` (the **shipped park-don't-poll loop** the rewire
targets: `spawn_link` `consumer.ex:39-40` (NOT a GenServer) + `trap_exit` `:41`, `beat_ms` default 1000
`consumer.ex:58`, the loop `check_control → reap → promote → drain → park` `consumer.ex:91-98`, `drain/1`
exhaustive recursion until `Lanes.claim → :empty` `consumer.ex:114-142`, `park/1` =
`Connector.command(conn, ["BLPOP", wake, secs], beat_ms + 2_000)` `consumer.ex:144-149` (the verb the metronome
relocates), the dedicated connector lane self-started `consumer.ex:43-51`, the settle-point control discipline
`consumer.ex:104-112`, `stop/2` `consumer.ex:78-89`, `child_spec/1` `consumer.ex:18-25`) + `lanes.ex` (the atomic
claim `@gclaim` `lanes.ex:37-61` — `LMOVE ring ring LEFT RIGHT` rotate `:38`, `ZPOPMIN` the head `:41`, the
**server-clock** `TIME` lease `:50-51`, `gactive` `:53`, attempts the fencing token; the wake-push in `@genqueue`
`:30-31` / `@gresume` `:77-78` / `@glimit` `:94-95` / `@greassign` `:132-133` / `@greap_group` `:375-376` — each
`LPUSH <base>'wake' '1'` + `LTRIM 0 63`, the single per-queue `wake` LIST capped 64 — **byte-frozen**) + `jobs.ex`
(the wake-push in `@complete:200-201` / `@retry:277-278` / `@promote:336-337` / `@reap:366-367` — **byte-frozen**)
+ `stalled.ex` (the wake-push in `@sweep_stalled:83-84` — **byte-frozen**; 10 wake-push scripts total across the 3
files) + `pump.ex` (`EchoMQ.Pump` — the **library-law process precedent**: an opt-in owner-started child, a pure
tick/batch decision core, no `mod:`) + `keyspace.ex` (the §6 `type` registry, `queue_key/2:14` → `emq:{q}:<type>`
— **byte-frozen**, no §6 edit) + `conformance.ex` (the scenario set — **UNTOUCHED by emq.4.3 (D-5): no scenario
added, the count byte-unchanged at 59**) + `connector.ex` (the FROZEN wire: `command/3:49` carries the `BLPOP`
block; `@wire_version "echomq:2.4.2":35` — **UNCHANGED by emq.4.3 (D-4): zero wire-protocol delta, the fence does
not climb**) · The wire facade (FROZEN):
`echo/apps/echo_wire/lib/echo_wire.ex` (`Connector`/`RESP`/`Script` frozen by committed records, `:12-14`) · The
test harness model: `consumer_test.exs` (`@moduletag :valkey`, `Connector.start_link(port: 6390)`, per-test queue
`q = "emq0.consumer#{System.unique_integer([:positive])}"`, `on_exit` purge over `KEYS emq:{q}:*`, `wait_until/2`,
`EchoData.Snowflake.start(4)` in `setup_all`) · Design: [`emq.design.md`](../../../../emq.design.md) §4 row 4 (the
*park, don't poll* law re-aimed to the fair-lanes rung — the law this rung founds the system for), §12.2 (the
one-transition-one-script law — `@gclaim` never bypassed; client-side pops rejected), §12.5 (the engine
floor/ceiling — a computed-floor raise is a protocol minor; MECH-(ii) raises NO floor — `BLPOP` is shipped), §5
(no new wire class), §6 (the CLOSED `type` registry — UNEDITED under MECH-(ii)), §4 (the server-clock law), §11.12
(the escalation protocol — the reconcile-delta seams) · Roadmap:
[`../../../emq.roadmap.md`](../../../../emq.roadmap.md) (the emq.4 row · Movement II · the echo_bot Telegram pool
consumer, `:31-32`) · Approach:
[`../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
