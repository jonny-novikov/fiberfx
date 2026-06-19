# EMQ.4.3 · the build orchestration runbook — found the park-don't-poll metronome as a system (MECH-(ii))

> **Status: ✅ SHIPPED (built to MECH-(ii) per the Operator's rulings D-1..D-5; this runbook is the historical
> build record).** This runbook drove the **emq.4.3** build — the THIRD sub-rung of the groups-deepened family
> (the park-don't-poll metronome) — a **HIGH-risk** rung that **founded the metronome as a system**: a NEW
> supervised `EchoMQ.Metronome` process per queue owning the single `BLPOP emq:{q}:wake <beat>` block + an
> idle-consumer registry, fanning readiness out to a pool of *opt-in* registered consumers over BEAM messages
> (one byte-frozen `@gclaim` per idle consumer per wake). **As built, three settled rulings narrowed the plan:
> the consumer rewire is ADDITIVE/OPT-IN — the consumer RETAINS `park/1` (D-3); `@wire_version` did NOT climb,
> staying `echomq:2.4.2` (D-4); and NO conformance scenario was added — the proof is the `:valkey` PROCESS suite
> (D-5). The forward-tense "drops park / 55 → N / fence climb 2.4.2 → 2.4.3" language below is the SUPERSEDED
> plan; the as-built reality is in the triad body §0 + the DoD.** The `/echo-mq-ship` skill
> ([`.claude/skills/echo-mq-ship/SKILL.md`](../../../../../../.claude/skills/echo-mq-ship/SKILL.md)) is the binding
> (it is `/x-mode` with the echo_mq context pre-loaded: Venus loads `echo-mq-architect`, Mars loads
> `echo-mq-implementor`, the Director verifies code + invariants, **Apollo — the evaluator — loads
> `echo-mq-evaluator` and is MANDATORY on this HIGH-risk rung, IN the per-rung pipeline**); the inputs are the
> triad ([`./emq.4.3.md`](emq.4.3.md) · [`./emq.4.3.stories.md`](emq.4.3.stories.md)), the family
> ([`../emq.4.md`](../emq.4.md) — the deepening contract + the carve + the forks), the decision record
> ([`../../../../kb/metronome-design/metronome-fork-decision.md`](../../../../kb/metronome-design/metronome-fork-decision.md)
> — the MECH-(ii) ruling), and the canon ([`emq.design.md`](../../../../emq.design.md) §4 row 4 / §12.2 / §12.5 /
> §5 / §6 / §7 / §8 / S-1/§6 / S-6). **Both Operator forks are RULED — no fork is open at the build** (FORK A =
> Arm B, D-1; FORK A-MECH = MECH-(ii), D-2; FORK A-MECH-§6 CLOSED by construction). What remains is a small set of
> **build-time seams** (SEAM-1/2/3 in the body) Mars pins at the Stage-0 reconcile against the as-built tree — not
> Operator forks.

## The family in one paragraph

emq.4 is the groups-deepened family — the shipped fair-lanes (`EchoMQ.Lanes`) mechanism taken to **production
multi-tenant depth** along four axes: a control plane (move a member between lanes; deepen
pause/resume/limit/drain), group-aware recovery (a group-scoped stalled-sweep), the park-don't-poll metronome (the
wake/notify beat made a system), and weighted/deficit rotation (fair-share beyond round-robin + a starvation
drill). The basics ALREADY shipped (B3.4 "Fair Lanes", 8/8 G1–G8); emq.4 does **not** found the family — it
**deepens** it. The family carves into emq.4.1 (control plane — **SHIPPED**) · 4.2 (group-aware recovery —
**SHIPPED**) · 4.3 (the metronome — **this rung**, HIGH-risk) · 4.4 (weighted/deficit + the drill — HIGH iff
`@gclaim` edited; **MECH-(ii) leaves the rotation-fairness seam inside `@gclaim` for 4.4's Fork B, unforeclosed**).
The full deepening contract + the three forks are [`../emq.4.md`](../emq.4.md).

## The rung in one paragraph

emq.4.3 carves the **park-don't-poll metronome**, **re-derived to MECH-(ii), the metronome-as-system** (the
Operator's rulings D-1, D-2). The shipped mechanism fuses the beat into each `EchoMQ.Consumer`'s `spawn_link`
loop: a consumer parks on `BLPOP emq:{q}:wake <beat>` (`consumer.ex:144-149`, the beat the fallback), is woken by
a wake-push baked into every serviceable transition (10 wake-pushing scripts across `lanes.ex` / `jobs.ex` /
`stalled.ex`, the single per-queue `emq:{q}:wake` LIST capped 64), then `drain`s the ring with rotating `@gclaim`s
— **every consumer is its own metronome.** **MECH-(ii) makes the beat a system:** a NEW supervised
`EchoMQ.Metronome` process per queue owns the **single** `BLPOP emq:{q}:wake <beat>` block (the SHIPPED verb on the
SHIPPED token) + a **registry of idle consumers**; on a wake it pokes the *k* registered-idle consumers over
**BEAM messages**, each running the byte-frozen `@gclaim` **exactly once** (consumer-fair; re-poke when work
remains). `EchoMQ.Consumer` is rewired (drops its private `park/1`, gains a registration: register-idle →
`:claim_once` → `@gclaim` once → re-register); the `reap → promote` cadence migrates to the metronome (one beat
per queue — SEAM-1). It builds, inside `echo/apps/echo_mq` under the v2 laws (the one-transition-one-script law —
`@gclaim` NEVER bypassed, design §12.2; the §6 grammar UNEDITED — BEAM-message fan-out; the inline `Script.new/2`
law — no new script; the server clock on any lease — `@gclaim`'s `TIME` is the only one; additive-minor
conformance): **(1)** the NEW `EchoMQ.Metronome` (the supervised process + a pure decision core) + the consumer
rewire + the host-wiring helper (the library law — host-started, no `mod:`); **(2)** the metronome conformance
scenario(s) (additive minor, the prior **55** byte-unchanged); **(3)** the `:valkey` + **process** suites + the
**≥100-iteration determinism loop**; **(4)** the version climb **2.4.2 → 2.4.3** (an additive minor — the count
grows — **NOT a floor-raise**: `BLPOP` is shipped). The shipped `@gclaim`, the 10 wake-pushing scripts, and
`keyspace.ex` are **byte-frozen** (the metronome blocks on the SAME shipped `emq:{q}:wake`; the fan-out is BEAM
messages, no §6 edit). **The FROZEN-WIRE verdict: NO `echo_wire` LOGIC edit** (`Connector.command/3` already
carries the `BLPOP` — `consumer.ex:147`; the metronome makes the IDENTICAL call, relocated); the **only**
`echo_wire` touch is the `@wire_version` constant. The honest **Out**: a new transport/connector verb (rides the
shipped connector — INV3), a new blocking command / a floor-raise (uses the SHIPPED `BLPOP` — none), bypassing
`@gclaim` (§12.2 forbids it), an `@gclaim` edit (byte-frozen — MECH-(ii) was decided over MECH-(iv-b) to keep it
so), a §6 grammar edit (BEAM fan-out, not a keyspace registry), a `mod:` auto-start (the library law), a host
clock on a lease (server clock only — INV2), the control plane (emq.4.1 SHIPPED), the recovery (emq.4.2 SHIPPED),
weighted rotation (emq.4.4), a per-lane wake (the herd is eliminated at the connection level). The contract is
[`./emq.4.3.md`](emq.4.3.md) (FORK A RULED Arm B; FORK A-MECH RULED MECH-(ii); FORK A-MECH-§6 CLOSED; INV1–INV5).

## Mode

**Flat-L2** (a build + a gate + a verify + a MANDATORY evaluator), Director-supervised, with **Mars's build
divided across two passes** (the Operator's no-overload directive — see the pipeline). **Not** the Design-Phase
variant (the triad exists, re-derived to MECH-(ii) this run). **HIGH-risk.** emq.4.3 **founds a new BEAM
process/lease surface** (the metronome is a new supervised process owning a beat + a lease-adjacent block; the
risk concentrates on its serialization point + the registration contract), and rides the **fairness-critical wake
path** where a **lost-wakeup race** at the registration boundary and a **same-millisecond branded-id mint** are
**cross-run** hazards. It **raises NO computed wire floor** (`BLPOP` is shipped — the metronome adds no new core
command; this is the decisive difference from the chosen-against MECH-(iv-b), which would have re-graded
`@gclaim`). So the per-app gate ladder **PLUS the ≥100-iteration determinism loop owning the machine** (one green
run is NOT proof) **PLUS Apollo MANDATORY** (the dedicated evaluator re-runs the whole ladder + the loop
independently, re-verifies the byte-unchanged conformance + the frozen wire + the byte-frozen `@gclaim`, and
renders the BUILD-GRADE / BLOCKED verdict the Director ratifies). **The Director's verify deepens to the ≥100 loop
+ the multi-consumer fairness probe.** It edits **no** shipped lane/recovery script's LOGIC (the byte-freeze grep
on `@gclaim` + the 10 wake-push scripts = 0; `keyspace.ex` byte-unchanged), touches **no** `echo_wire` logic (only
the `@wire_version` constant), and performs **no** destructive at-rest op.

Scope slug: **`emq-4-3`** (dashed, no dots — `tool_x_*`/`TeamCreate` require `^[a-z0-9][a-z0-9-]*$`). Operator:
`jonny`. Workspace: `/Users/jonny/dev/jonnify`. Ledger: `docs/echo_mq/specs/progress/emq-4-3.progress.md` (the
design run opened it with the reconcile T-1..T-9 + the rulings D-1/D-2 + the learning L-1; the ship run carries
the build records).

## The mechanism is RULED — MECH-(ii), the metronome-as-system (D-2)

There is **no build-choice gate** — both Operator forks are ruled (the prior MECH-(i) provisional gate is
closed). The build proceeds directly to MECH-(ii):

> **FORK A = Arm B (D-1).** emq.4.3 founds a new blocking-claim primitive that subsumes the shipped wake-token
> two-step.
>
> **FORK A-MECH = MECH-(ii) (D-2) — the metronome-as-system.** A NEW supervised `EchoMQ.Metronome` process per
> queue owns the **single** `BLPOP emq:{q}:wake <beat>` block (the SHIPPED verb on the SHIPPED token; **no new
> blocking command, NO floor-raise**) + a registry of idle consumers; on a wake it pokes the *k* registered-idle
> consumers over **BEAM messages**, **each running the byte-frozen `@gclaim` exactly once** (the dispatch contract
> — one claim per idle consumer per wake = consumer-fair; the metronome re-pokes promptly when work remains, so
> throughput holds; a poke-one-to-exhaustive-drain would hog the beat). `EchoMQ.Consumer` loses its private
> `BLPOP` park and gains a registration (register idle → receive `:claim_once` → run `@gclaim` once →
> re-register). The decision was MECH-(ii) over MECH-(iv-b) (block on the ring / rotate-in-place) for one reason
> that dominates on a HIGH-risk frozen-surface rung: **(ii) buys (iv-b)'s entire multi-consumer benefit
> reversibly — delete a supervisor child — where (iv-b) buys it by re-grading the hottest script.** The
> found-new charter (D-1) is honored on the BEAM process axis, where the cost is removable, not on the wire axis,
> where it is frozen by committed records. The decision record:
> [`../../../../kb/metronome-design/metronome-fork-decision.md`](../../../../kb/metronome-design/metronome-fork-decision.md).
>
> **FORK A-MECH-§6 — CLOSED by construction.** The fan-out is BEAM messages, not a keyspace registry, so there is
> **no** §6 grammar edit — `keyspace.ex` is byte-unchanged.
>
> **VERSION — the fence climbs in lockstep (D-3).** emq.4.3 climbs **2.4.2 → 2.4.3** across BOTH the `mix.exs`
> label AND the connector `@wire_version` / `{emq}:version` fence — they carry the same number and move together
> per rung. The connector fence **logic** stays frozen (only the constant moves; `connector.ex:35`); the `:fence`
> conformance scenario + `connector_test` are version-agnostic (assert the live key `== Connector.wire_version()`),
> so they never need a per-rung edit; the bump re-seeds `{emq}:version` once via `DEL`. This is one minor step on
> the climb to `echomq:3.0.0` — the **MAJOR** ratified at emq.8 (the horizon the Director tracks), not this rung.
> **The climb is an additive minor because the conformance count grows — NOT a floor-raise** (`BLPOP` is already
> in the shipped inventory; the metronome introduces no new core command, so §12.5's computed-floor-raise minor
> does not apply).

## The as-built floor (verified at the re-derivation, this run — the build's Stage-0 RE-PROBES each; the lag-1 law)

Anchors drift; a sibling rung could move the `echo_mq` surface before emq.4.3 reads it — the build's Stage-0
reconcile re-pins every line below:

- **The conformance count** — `conformance.ex` `scenarios/0` (`:78`; the pre-build floor = **55**; emq.4.1 added
  `reassign`/`lane_drain`, emq.4.2 added `reap_group`, 52 → 54 → 55). **The seed's "52" was STALE (pre-emq.4.1
  ship) — re-derived to 55 → N.** `conformance_run_test.exs:48` `== {:ok, 55}`; `conformance_scenarios_test.exs`
  `@run_order` (`:28`) = exactly 55 names, asserted `Keyword.keys(scenarios()) == @run_order` (`:87`); the module
  docs the count word ("fifty-five").
- **The fence** — `connector.ex:35` `@wire_version "echomq:2.4.2"` (NOT the seed's stale `echomq:2.0.0`). emq.4.3
  climbs **2.4.2 → 2.4.3** in lockstep (the `mix.exs` `:echo_mq` `version` `:7` + `@wire_version` + the live
  `{emq}:version`). **An additive minor — NOT a floor-raise (`BLPOP` is shipped).**
- **`Consumer` (the shipped park-don't-poll loop — the REWIRE target)** — `consumer.ex`: `spawn_link` loop
  `:39-40` (NOT a GenServer) + `trap_exit` `:41`; `beat_ms` default 1000 `:58`; the loop `check_control → reap →
  promote → drain → park` `:91-98`; `drain/1` exhaustive recursion until `Lanes.claim → :empty` `:114-142`;
  `park/1` = `Connector.command(s.conn, ["BLPOP", wake, secs], s.beat_ms + 2_000)` `:144-149`,
  `wake = Keyspace.queue_key(s.queue, "wake")` `:146` (the verb the metronome relocates); the **dedicated
  connector lane** self-started `:43-51` (the moduledoc: "blocking verbs get their own lane (Appendix B)"); the
  **settle-point control discipline** `check_control` `:104-112` (`:emq_stop` → `exit(:normal)`; `{:EXIT, _,
  :shutdown}` → `exit(:shutdown)`) — the model for the registration's deregister-at-a-settle-point; `stop/2`
  `:78-89` (monitor + `:emq_stop`); `child_spec/1` `:18-25` (the model for the host-wiring child spec). **Mars
  re-probes `park/1` + the loop + the settle-point discipline before the REWIRE.**
- **`@gclaim` (BYTE-FROZEN — the atomic claim the poke triggers, never bypasses — §12.2)** — `lanes.ex:37-61`:
  `LMOVE KEYS[1] KEYS[1] LEFT RIGHT` (the ring rotate) `:38`; `ZPOPMIN lane` (the head) `:41`; `HINCRBY attempts`
  (the fencing token) `:48`; the **server clock** `redis.call('TIME')` + `now = t[1]*1000 + math.floor(t[2]/1000)`
  `:50-51`; the lease `ZADD active now+lease id` `:52`; the `gactive`/ceiling/ring bookkeeping `:53-59`; returns
  `{id, payload, att, g}`. **`@gclaim` is byte-frozen — the poke triggers it, the lib diff `grep redis.call` on
  `@gclaim` = 0.**
- **The wake-push protocol (the readiness signal the metronome blocks on — BYTE-FROZEN; the metronome blocks on
  the SAME `emq:{q}:wake` these push to)** — **10 distinct scripts**: `lanes.ex` `@genqueue:30-31`,
  `@gresume:77-78`, `@glimit:94-95`, `@greassign:132-133`, `@greap_group:375-376` (5); `jobs.ex` `@complete:200-201`,
  `@retry:277-278`, `@promote:336-337`, `@reap:366-367` (4); `stalled.ex` `@sweep_stalled:83-84` (1) — each
  `LPUSH <base>'wake' '1'` + `LTRIM <base>'wake' 0 63` (the single per-queue `wake` LIST capped 64). **All 10
  byte-frozen under MECH-(ii) — the metronome blocks on the same token; `grep redis.call` on the lib diff = 0.**
  (NB: the decision-doc/prior-trace figure "seven wake-pushers" was stale arithmetic — the as-built count is
  **10 distinct scripts**; this re-derivation pins 10.)
- **`Keyspace.queue_key/2` + the §6 `type` registry (UNEDITED — the fan-out is BEAM messages)** — `keyspace.ex:14`
  (`queue_key` → `emq:{q}:<type>`); the §6 `suffix := type (CLOSED registry)` (`emq.design.md:290`). `wake` is a
  registered per-queue type. **MECH-(ii) edits NO §6 member — `keyspace.ex` byte-unchanged.**
- **`EchoMQ.Pump` (the library-law process precedent)** — `pump.ex` + `pump/core.ex`: an opt-in `:transient`
  owner-started child, a **pure tick/batch decision core** testable without Valkey, `sweep/1` = promote +
  fire_repeats, **no `mod:`**. The model for the metronome's "thin but robust — every new process supervised with
  a pure decision core" shape (the program's law) and for the host-wiring helper (SEAM-2).
- **The FROZEN wire (NO `echo_wire` LOGIC edit)** — `connector.ex`: `command/3:49` carries arbitrary
  `[binary|integer|atom]` parts with a custom timeout (park's `BLPOP` rides it `:147`); `eval/5` (the EVALSHA-first
  `@gclaim`); the serialized FIFO `GenServer` (`send_pipe` enqueues `pending` `:298`). `Connector`/`RESP`/`Script`
  **frozen by committed records** (`echo_wire.ex:12-14`). The metronome's `BLPOP` rides the same `command/3` →
  **NO new verb, NO `echo_wire` LOGIC edit, NO frozen-record change.** The **only** `echo_wire` touch is the
  `@wire_version` constant (`:35`, the lockstep climb to `echomq:2.4.3`).
- **The test harness (the metronome suites model on it)** — `consumer_test.exs`: `@moduletag :valkey`;
  `Connector.start_link(port: 6390)`; per-test queue `q = "emq0.consumer#{System.unique_integer([:positive])}"`;
  `on_exit` purge over `KEYS emq:{q}:*`; `wait_until/2` (a 5ms poll, 400 tries); `BrandedId.generate!("JOB")` +
  `("PRT")`; `Consumer.start_link(queue:, handler:, connector: [port: 6390], beat_ms:, lease_ms:)`;
  `EchoData.Snowflake.start(4)` in `setup_all`. The multi-consumer fairness suite extends this (N consumers + one
  metronome + a stream of admits).

## The pipeline — the HIGH rung (Venus → Mars-1 → Director review → Mars-2 → Apollo MANDATORY → Director ship)

Each spawned stage is a real `general-purpose`/dedicated `Agent` that adopts its `.claude/agents/<role>.md`
charter, LOADS its `echo-mq-<role>` skill, and self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns). The
Director holds the gate between stages. The per-spawn contract is the `/x-mode` skill §3 (Framing → adopt charter
→ aaw ceremony → the stage block → audit directive → propagation clause → report). **Require artifact-level
checkpoints** (SendMessage a concrete report after each pass; the Director's ground-truth verification is the
gate, not the self-verdict).

### Stage 0/1 — Venus (architect): the triad re-derived to MECH-(ii) + the pre-build reconcile

**(DONE this run — the triad re-derived from the provisional MECH-(i) to the ruled MECH-(ii).)** Directive:
re-derive the emq.4.3 triad (`.md`/`.stories.md`/`.prompt.md`) to **MECH-(ii)** (D-1, D-2), reconciled lag-1
against the as-built tree. Re-probe every anchor above; pin the conformance count (**55** — reconcile the seed's
stale 52); pin the fence (**2.4.2 → 2.4.3** — reconcile the seed's stale 2.0.0); state the **NO floor-raise** fact
(MECH-(ii) uses the shipped `BLPOP`); render the **FROZEN-WIRE verdict** (NO `echo_wire` logic edit); pin the
wake-push count (**10 distinct scripts** — reconcile the stale "seven"); surface the three **build-time seams**
(SEAM-1 reap/promote migration, SEAM-2 host-wiring API shape, SEAM-3 registration message protocol) for Mars to
pin at Stage-0. Gate: the triad re-derived; the reconcile delta table; the BUILD-GRADE verdict; the seams
surfaced (none an Operator fork — the architecture is ruled). **At the build's Stage 0, Mars RE-PROBES the floor
(the lag-1 law — a sibling rung could have moved an anchor) and pins SEAM-1/2/3 against the real code.**

### Stage 1 — Mars-1 (implementor): PASS 1 — the core primitive (the metronome + the consumer rewire + the host-wiring)

**The Operator's no-overload directive divides Mars's build across two passes; this is PASS 1 — the core
primitive.** Directive: build the metronome-as-system to the brief's agent stories and the design. The order:
**(1)** at Stage-0, re-probe the floor + pin the three seams (SEAM-1: the `reap → promote` cadence migrates to the
metronome's beat loop, against `Jobs.reap/2` + `Jobs.promote/3`; SEAM-2: the host-wiring helper shape, modeled on
`Pump`/`Consumer` `child_spec`; SEAM-3: the registration message protocol — `{:register_idle, pid}` / monitor /
`:claim_once` / re-register, modeled on the consumer's settle-point discipline `consumer.ex:104-112`); **(2)**
build the NEW `metronome.ex` — a supervised `spawn_link`-loop process per queue (modeled on `consumer.ex:39-51`:
traps exits, owns a **dedicated connector lane** for the single `BLPOP emq:{q}:wake <beat>` block) holding the
single block + an idle-consumer registry + a **PURE decision core** (which registered-idle consumers to poke / how
many claims to authorize — testable without Valkey, the program's "thin but robust" law) + the BEAM-message
fan-out (poke the *k* registered-idle consumers, one `:claim_once` each per wake, re-poke promptly when work
remains) + `Process.monitor/1` on each registered consumer (a `:DOWN` removes the registration); the beat loop
runs `reap → promote` then blocks (SEAM-1); **(3)** rewire `consumer.ex` — drop `park/1` (the `BLPOP`); the loop
becomes register-idle → receive `:claim_once` → run the byte-frozen `@gclaim` ONCE (via `Lanes.claim/3` — NEVER a
client-side lane/ring pop, §12.2; `@gclaim` byte-frozen) → handle → settle (`@complete`/`Jobs.retry`) →
re-register; deregister at the settle point on `:emq_stop`/`{:EXIT, :shutdown}` (the existing `check_control`
discipline, extended to notify the metronome); **(4)** build the host-wiring helper (the library law — host-started,
no `mod:`: a forward-named `EchoMQ.start_queue/…`-style function returning/starting child specs for a metronome +
N consumers under the host's supervisor, modeled on `Pump`/`Consumer`). Cite the spec/design line for every public
call; **declared keys** (the block's only key is the shipped `emq:{q}:wake`; `@gclaim`'s keys are the shipped
`KEYS=[ring, active]` — INV3); **inline `Script.new/2`** (no `priv/`; **no new script** — the metronome adds no
Lua); **server clock** (`@gclaim`'s `TIME` is the only lease — INV2; the block timeout is host-side, not a lease;
the metronome owns no Valkey lease); **`@gclaim` byte-frozen** (`grep redis.call` on `@gclaim` in the lib diff = 0
— the poke triggers it, never edits it); compile clean (`--warnings-as-errors`, per-app). **INV3/INV4 gate**:
`@gclaim` + the 10 wake-push scripts + `keyspace.ex` byte-unchanged (`grep redis.call` on them = 0; `keyspace.ex`
byte-identical to HEAD); **the FROZEN-WIRE gate**: `echo/apps/echo_wire/lib/` byte-unchanged in the lib diff
EXCEPT the `@wire_version` constant. Gate (PASS 1): per-app compiles green; the metronome + the rewired consumer +
the host-wiring exist; the diff stays inside `echo_mq` (no `echo_wire` LOGIC; no `lanes.ex`/`jobs.ex`/`stalled.ex`
/`keyspace.ex` edit; no `apps/echomq`); the boundary grep empty. **PASS 1 reports the API the proof builds on
(the metronome's start signature, the registration message shapes) before PASS 2.**

### Stage 1 (cont.) — Mars-1 (implementor): PASS 2 — the multi-consumer proof (the harness + conformance + version + pins)

**PASS 2 — the load-bearing proof (depends on PASS 1's API).** Directive: build the proof the 55-scenario suite
lacks. **(1)** the `:valkey` + process metronome suite(s) (model on `consumer_test.exs`): **US1** admit-while-
registered → served WELL BEFORE the beat (the no-op-defeating assertion — a scenario that passes with a poll-on-
the-beat must be distinguished by asserting service well under `beat_ms`); **US2** the registration-boundary
lost-wakeup race (admit exactly as a consumer re-registers → served within the beat) + the crash-mid-claim case
(the registration monitor-removed, the job reaped); **US3** multi-consumer fairness (N registered consumers + a
stream of admits → each serves a share, none starves — the no-op-defeating assertion: a poke-one-to-exhaustive-
drain fails the no-starvation check); **US4** the registration/drain contract (consumer death → registration
removed + metronome survives; `stop/2`/`:shutdown` → deregistered, no leaked claim); **(2)** the metronome
scenario(s) in `conformance.ex` `scenarios/0` (additive — append the new scenario(s) + their probes; the prior 55
byte-unchanged) + the count re-pin **55 → N** in both pin tests (`conformance_run_test.exs:48` `{:ok, 55}` → N;
`conformance_scenarios_test.exs` `@run_order` + the module-doc "fifty-five" word); **(3)** the version bump
`mix.exs:7` **2.4.2 → 2.4.3** + the `@wire_version` constant `connector.ex:35` → `echomq:2.4.3` (no fence-logic
edit; the bump re-seeds `{emq}:version` once via `DEL` in the suite setup). Register the conformance scenario +
probe **in the same change** (INV5; the prior 55 byte-unchanged). Gate (PASS 2): the `:valkey` + process suites
green per-app; `Conformance.run/2 → {:ok, N}`; the count re-pinned in both tests; the version in lockstep; the
byte-freeze + FROZEN-WIRE greps still clean. Sequential after PASS 1, divided so neither pass overloads.

### Stage 2 — Director: solo review (a REAL pass — deepened for HIGH-risk)

A fresh-gate reconcile + an independent gate re-run on Valkey 6390 + **the ≥100 determinism loop** + the
adversarial probes: the **FROZEN-WIRE** probe (`echo/apps/echo_wire/lib/` byte-unchanged in the diff EXCEPT the
`@wire_version` constant; no new connector verb; `Connector`/`RESP`/`Script` byte-identical to HEAD); the **NO
floor-raise** probe (the P6 computed-floor inventory unchanged — no `BLMOVE`/`BLMPOP` enters; the block is the
shipped `BLPOP`); the **§12.2** probe (the lane/ring pop is inside `@gclaim` only — no client-side `ZPOPMIN`/`LMOVE`
of the lane/ring in `metronome.ex` or the rewired `consumer.ex`; `@gclaim` byte-frozen `grep redis.call` = 0); the
**lost-wakeup** probe (the load-bearing proof — admit a job exactly at the registration boundary, repeatedly under
the ≥100 loop → served within the beat EVERY run; a recheck-after-park or a design where the block dies with a
consumer would be caught here as a cross-run flake); the **serve-well-before-beat** probe (admit while registered
→ handled WELL BEFORE a full beat elapses, NOT only on the beat — defeats a no-op that polls on the beat); the
**multi-consumer fairness** probe (N registered consumers + a stream of admits → each serves a share, none starves
— defeats a poke-one-to-exhaustive-drain); the **registration/drain** probe (kill a registered consumer → the
metronome does not poke its pid + survives; `stop/2` → deregistered, no leaked claim); the **server-clock** probe
(`@gclaim`'s lease is `redis.call('TIME')`; the metronome's block timeout is host-side and touches NO lease — INV2);
the **byte-freeze** probe (`grep redis.call` on `@gclaim` + the 10 wake-push scripts + the recovery scripts in the
lib diff = 0; `keyspace.ex` byte-identical to HEAD; the prior metronome-adjacent scenarios `rotate`/`pause`/`limit`
byte-identical); the **byte-unchanged conformance** probe (`git diff` shows only additions to `scenarios/0` +
`@run_order`; the 55 prior scenarios byte-identical); the **version** probe (`{emq}:version` → `echomq:2.4.3`; the
`mix.exs` label + `@wire_version` in lockstep; the fence LOGIC frozen; the `:fence` scenario version-agnostic); a
**mutation spot-check** (Edit-in a fault — e.g. revert the consumer to its own `BLPOP` park so the metronome is
bypassed, or poke-one-to-drain → the lost-wakeup / fairness scenario catches it across the ≥100 loop → revert →
`git diff --stat` clean, net-zero, LAW-1a). Produce the REMEDIATE list.

### Stage 3 — Mars-2 (implementor, harden + the full gate ladder + the ≥100 loop)

Resume the Stage-1 Mars (one identity, the passes). Directive: remediate; run the full ladder — toolchain
re-probe (`asdf current erlang` from the app dir — confirmed Erlang 28.5.0.1 / Elixir 1.18.4 via `echo/.tool-versions`)
+ Valkey 6390 PONG; per-app pure + `:valkey` + process suites (`TMPDIR=/tmp`, NEVER umbrella-wide; `--include
valkey` for the metronome suites); `Conformance.run/2 → {:ok, N}` with the prior 55 byte-unchanged + the metronome
scenario(s) probe-registered; **the ≥100-iteration determinism loop green OWNING THE MACHINE** (`for i in $(seq 1
150); do TMPDIR=/tmp mix test --include valkey || break; done` — no concurrent liveness server, no sibling heavy
I/O; the lost-wakeup race + the same-millisecond branded-id mint are exactly the cross-run hazards one green run
does not surface); the version climbs to 2.4.3 in lockstep (the `mix.exs` label AND the `@wire_version` fence
together — D-3; the `:fence` scenario version-agnostic); coverage tabled with the reason for any gap. REMEDIATE
loop MAX 3. Gate: every ladder item PASS or explained; the conformance tally clean; the byte-freeze grep = 0
(`@gclaim` + the 10 wake-push + `keyspace.ex`); the FROZEN-WIRE grep clean (`echo_wire/lib/` byte-unchanged except
`@wire_version`); the NO-floor-raise check (no new core command); the ≥100 loop green; the boundary grep empty.

### Stage 4 — Apollo (evaluator) — MANDATORY (HIGH-risk)

Directive (**MANDATORY** — the rung founds a BEAM process/lease surface on the fairness-critical wake path): the
post-build reconcile (does the as-built metronome satisfy the spec's promises?) + the §11.2-charter adversarial
verification applied to the metronome (the lost-wakeup race under the ≥100 loop INDEPENDENTLY re-run; the
multi-consumer fairness probe; the §12.2 no-bypass probe; the FROZEN-WIRE re-verify; the NO-floor-raise check; the
server-clock probe; the registration/drain probe) + the per-app gate ladder + **the ≥100-iteration determinism
loop re-run independently** + re-verify the conformance count is byte-unchanged with the metronome scenario(s)
probe-registered + sync-check the spec body to what shipped (the SEAM-1/2/3 resolutions). Render the **BUILD-GRADE
/ BLOCKED verdict the Director ratifies** + ≥1 mentoring observation folded forward (Director-ratified). Apollo is
IN the pipeline on this rung (not a fast-finisher).

### Stage 5 — Venus (architect): the post-build reconcile

Sync the triad body to the as-built surface (the metronome's real shape — the `metronome.ex` module + its start
signature; the consumer rewire form; the host-wiring helper's real name/location; the SEAM-1/2/3 resolutions
[the reap/promote placement, the host-wiring API shape, the registration message protocol]; the metronome scenario
names + the final conformance N; the version 2.4.3; the §6 disposition — "UNEDITED, BEAM fan-out"); every triad
claim MATCH or `[RECONCILE]`-marked; fold the metronome axis discharged in the family ([`../emq.4.md`](../emq.4.md)
— the metronome sub-rung). **The backward reconcile is owed** (the emq.4.2 F6 lesson — a forward-only reconcile
lets the committed spec drift from as-built; sync the forward-tense brief to what shipped so emq.4.4 reconciles
against truth). **Re-pin the family body's stale "52" (INV6) + "echomq:2.0.0" (INV1) to the live 55→N + 2.4.3 if
the Director includes `emq.4.md` in the commit** (a family-level reconcile delta carried forward).

### Stage 6 — Director: closure + ONE LAW-4 commit + the family fold

Preconditions (x-mode §4): the gate green + **Apollo BUILD-GRADE** (MANDATORY on this rung — the evaluator's
verdict is a precondition, not optional) + the reconcile build-grade; the rulings already recorded (**D-1** Arm B,
**D-2** MECH-(ii)) + the version ruling (2.4.3) + a **`tool_x_complete` (Z-n)** this turn; `git status --short`
AND `git diff --cached --name-only` reviewed; `.git/rebase-merge`/`rebase-apply` checked. Then the **pathspec**
commit (below; NEVER `git add -A`, NEVER a bare commit). **Same turn:** flip the emq.4.3 row in the single roadmap
([`../../../emq.roadmap.md`](../../../../emq.roadmap.md)) and the dashboard
([`../../../emq.progress.md`](../../../../emq.progress.md)); record the metronome axis shipped (the groups family
deepening; 4.4 next); surface the **next frontier** (emq.4.4 weighted/deficit + the starvation drill — HIGH iff
`@gclaim` edited; **MECH-(ii) leaves the rotation-fairness seam INSIDE `@gclaim` for 4.4's Fork B, unforeclosed —
FORK B settles before 4.4**); under an **explicit Operator grant only**, fold any mentoring diff into the peer
charters / the echo-mq-* skills (one guardrail per finding). The message cites the slug, the Z-n, the D-n, and the
Y-n report.

## Risk tier

**HIGH.** emq.4.3 **founds a new BEAM process/lease surface** (the metronome is a new supervised process per queue
owning a beat + a lease-adjacent `BLPOP` block; the risk concentrates on its **serialization point** — one process
gates wakeups for a queue — and the **registration contract** — getting register/deregister/monitor/drain wrong
re-introduces a missed wake or an orphaned registration on the BEAM side), and rides the **fairness-critical wake
path**. It **raises NO computed wire floor** (`BLPOP` is shipped — the metronome adds no new core command; this is
the decisive difference from the chosen-against MECH-(iv-b), which would have re-graded the frozen `@gclaim`). The
cross-run hazards: a **lost-wakeup race** at the registration boundary (work admitted as a consumer re-registers)
and a **same-millisecond branded-id mint** across concurrent consumers — neither surfaces in one green run. The
mitigating gates:
1. **The lost-wakeup robustness (the load-bearing proof).** The metronome must serve a job admitted at the
   registration boundary within the beat — the Director's **lost-wakeup probe under the ≥100 loop** (admit at the
   boundary, repeatedly → served every run) catches a design where the block dies with a transitioning consumer;
   a scenario that only checks "served eventually" or runs once would pass even with a lost-wakeup bug, so the
   **WELL-BEFORE-THE-BEAT** assertion + the **≥100 loop** are mandatory (the gate-liveness law).
2. **The multi-consumer fairness (the proof the suite lacks).** N registered consumers + a stream of admits →
   each serves a share, none starves — the Director's **fairness probe** catches a poke-one-to-exhaustive-drain
   (which would hog the beat); the dispatch contract "one `@gclaim` per idle consumer per wake" is what makes it
   fair, and the probe asserts it.
3. **The §12.2 no-bypass + the FROZEN-WIRE verdict + the byte-frozen `@gclaim`.** The poke must trigger the atomic
   `@gclaim` (never a client-side lane/ring pop — design §12.2), must ride the shipped connector (NO `echo_wire`
   logic edit), and must leave `@gclaim` byte-frozen (the reason MECH-(ii) was chosen over MECH-(iv-b)) — the
   Director's **§12.2 probe** + **FROZEN-WIRE probe** + **byte-freeze probe** catch a bypass, a wire break, or a
   script edit.
4. **The ≥100 determinism loop owns the proof.** A multi-seed sweep is NOT enough — the same-millisecond mint +
   the lost-wakeup race are cross-run. The loop must own the machine.

**Apollo is MANDATORY** — the dedicated evaluator re-runs the whole ladder + the ≥100 loop independently and
renders the BUILD-GRADE / BLOCKED verdict the Director ratifies. The Director's verify deepens to the ≥100 loop +
the multi-consumer fairness probe.

## The Stage-6 commit pathspec (Director-only — the emq.4.3 BUILD)

Commit exactly the rung's measured surface (the build run's actual touch-set is authoritative — adjust to what the
stages truly changed; under MECH-(ii) the touch-set is the metronome + the consumer rewire + the host-wiring +
conformance + version + the `@wire_version` constant + tests — NO `lanes.ex`/`jobs.ex`/`stalled.ex`/`keyspace.ex`):

```text
docs/echo_mq/specs/emq2/emq.4/emq.4.md                       (the family contract, IF Stage-5 synced the stale 52→55 / 2.0.0→2.4.3 family pins)
docs/echo_mq/specs/emq2/emq.4/emq.4.rungs/emq.4.3.md         (the body, Stage-5 synced — status → SHIPPED, the count 55→N, the seam resolutions)
docs/echo_mq/specs/emq2/emq.4/emq.4.rungs/emq.4.3.stories.md
docs/echo_mq/specs/emq2/emq.4/emq.4.rungs/emq.4.3.prompt.md  (this runbook)
docs/echo_mq/specs/progress/emq-4-3.progress.md
docs/echo_mq/emq.roadmap.md                                  (the emq.4.3 row → shipped)
docs/echo_mq/emq.progress.md                                 (the dashboard fold)
echo/apps/echo_mq/lib/echo_mq/metronome.ex                   (NEW — the metronome-as-system: the supervised process + the pure decision core)
echo/apps/echo_mq/lib/echo_mq/consumer.ex                    (the rewire — drops park/1, gains the registration; the cadence migrated per SEAM-1)
echo/apps/echo_mq/lib/echo_mq/conformance.ex                 (the metronome scenario(s), additive)
echo/apps/echo_mq/mix.exs                                     (version 2.4.2 → 2.4.3, additive minor — NOT a floor-raise)
echo/apps/echo_wire/lib/echo_mq/connector.ex                 (ONLY the @wire_version constant 2.4.2 → 2.4.3 — NO logic edit; see note)
echo/apps/echo_mq/test/                                       (the metronome :valkey + process suites + the conformance pins 55→N)
# the host-wiring helper — re-probe its as-built location at Stage-0 (SEAM-2):
#   a NEW module (e.g. echo/apps/echo_mq/lib/echo_mq/queue.ex or similar), OR an addition to metronome.ex / consumer.ex
```

> **The `connector.ex` note (the ONE `echo_wire` file touched — and ONLY the constant).** The FROZEN-WIRE verdict
> is that the metronome needs **no `echo_wire` LOGIC edit** (`command/3` already carries the `BLPOP` — the
> metronome makes the IDENTICAL call, relocated). The version lockstep (D-3), however, moves the `@wire_version`
> CONSTANT (`connector.ex:35`) from `echomq:2.4.2` to `echomq:2.4.3` — this is the same one-line constant move
> emq.4.1/4.2 made, NOT a logic change to the frozen connector (the records freeze the module's CONTRACT, not the
> version string the fence climbs). `connector.ex` lives under `echo/apps/echo_wire/lib/echo_mq/` (the historical
> namespace under the `echo_wire` app — re-probe the exact path at Stage 0). **EXCLUDE the rest of
> `echo_wire/lib/` — byte-unchanged (INV3).**

**EXCLUDE** (Operator out-of-band — never sweep into the rung commit): `echo/apps/live_svelte/**`,
`echo/apps/mercury_cms/**`, `echo/apps/mercury_live_admin/**`, `html/**`, the F# course, and any
`[emq]`/`[bcs]`/`[mercury]` doc commits the Operator lands between stages. `echo/apps/echomq` (frozen v1 — the
capability reference) + the rest of `echo/apps/echo_wire/lib/` (the metronome rides the shipped connector — only
the `@wire_version` constant moves, see the note) + `echo/apps/echo_mq/lib/echo_mq/lanes.ex` (`@gclaim` + the 5
wake-push scripts byte-frozen — **NO `lanes.ex` edit under MECH-(ii)**) + `echo/apps/echo_mq/lib/echo_mq/jobs.ex`
(the 4 wake-push scripts byte-frozen — **NO `jobs.ex` edit**) + `echo/apps/echo_mq/lib/echo_mq/stalled.ex` (the
wake-push byte-frozen — **NO `stalled.ex` edit**) + `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` (**NO §6 grammar
edit — BEAM fan-out**) + `echo/mix.lock` (emq.4.3 adds no dep — expect `mix.lock` EXCLUDED) UNTOUCHED. **Never
`git add -A`.** (Under MECH-(ii), `lanes.ex`/`jobs.ex`/`stalled.ex`/`keyspace.ex` are NOT edited — if the build's
measured touch-set differs, the Director adjusts the pathspec to what truly changed.)

## Acceptance — "shipped" means

Every DoD box in [`./emq.4.3.md`](emq.4.3.md) is checkable from the run's outputs: FORK A confirmed Arm B (D-1) +
FORK A-MECH confirmed MECH-(ii) (D-2) + FORK A-MECH-§6 confirmed CLOSED before the build; the NEW
`EchoMQ.Metronome` (a supervised process per queue, the single `BLPOP wake` block + the idle-consumer registry +
the BEAM-message fan-out + a pure decision core) + the consumer rewire (drops `park/1`, gains the registration) +
the host-wiring API (host-started, no `mod:`); lost-wakeup robustness by construction (no wake lost under a
concurrent admit-then-register); fair readiness distribution across registered consumers (one `@gclaim` per idle
consumer per wake, no starvation); the registration/drain contract (monitor-detected death, clean stop/shutdown,
no orphaned registration, no leaked claim); the block NEVER bypasses `@gclaim` (§12.2; `@gclaim` byte-frozen); the
FROZEN-WIRE verdict held (`echo_wire/lib/` byte-unchanged but the `@wire_version` constant moved to 2.4.3); NO
floor-raise (`BLPOP` shipped); the 10 wake-push scripts + `keyspace.ex` byte-unchanged (INV4); the metronome
scenario(s) additive-minor with the prior 55 byte-unchanged + the count re-pinned 55 → N in both pin tests; the
`:valkey` + process suites green + **the ≥100-iteration determinism loop green owning the machine** (the
lost-wakeup race + the mint hazard) + no regression + the byte-freeze grep = 0 + the version 2.4.3 in lockstep;
**Apollo BUILD-GRADE** (MANDATORY — the evaluator's independent ladder + ≥100 loop + the §12.2/FROZEN-WIRE/fairness
re-verify). The spec body stays authoritative; Stage 5 syncs it to the as-built surface (the backward reconcile
owed; the SEAM-1/2/3 resolutions); the groups family capstone (emq.4.4 weighted/deficit + the drill) opens on a
proven metronome.

Inputs: [`./emq.4.3.md`](emq.4.3.md) · [`./emq.4.3.stories.md`](emq.4.3.stories.md) · Decision record:
[`../../../../kb/metronome-design/metronome-fork-decision.md`](../../../../kb/metronome-design/metronome-fork-decision.md)
(the MECH-(ii) ruling + the two-architect synthesis) · Family: [`../emq.4.md`](../emq.4.md) (the deepening
contract + the carve + the forks) · Canon: [`emq.design.md`](../../../../emq.design.md) §4 row 4 (park, don't
poll) / §12.2 (the one-transition-one-script law — `@gclaim` never bypassed) / §12.5 (the engine floor — a
computed-floor raise is a protocol minor; MECH-(ii) raises NO floor) / §5 (no new wire class) / §6 (the CLOSED
`type` registry — UNEDITED) / S-1/§6 / S-6 · Roadmap: [`../../../emq.roadmap.md`](../../../../emq.roadmap.md)
Movement II (the echo_bot Telegram pool consumer, `:31-32`) · The shape model:
[`./emq.4.2.prompt.md`](emq.4.2.prompt.md) (the sibling recovery runbook) · Skills:
`.claude/skills/echo-mq-ship.md` (the binding) + `echo-mq-{architect,implementor,evaluator}.md` (the per-role
craft) + `echo-mq-program.md` (the program law) · Approach:
[`../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
