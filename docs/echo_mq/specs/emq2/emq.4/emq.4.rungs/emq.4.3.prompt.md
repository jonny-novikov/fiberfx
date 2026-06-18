# EMQ.4.3 · the build orchestration runbook — found the park-don't-poll metronome's blocking-claim primitive (Arm B)

> **Status: SPECCED, the runbook ready (authored at the `emq-4-3` design run, re-derived to Arm B per the
> Operator's ruling D-1).** This runbook drives the **emq.4.3** build — the THIRD sub-rung of the
> groups-deepened family (the park-don't-poll metronome) — a **HIGH-risk** rung that **founds a new
> blocking-claim primitive** subsuming the shipped `BLPOP wake` + `drain` two-step. The `/echo-mq-ship` skill
> ([`.claude/skills/echo-mq-ship/SKILL.md`](../../../../../../.claude/skills/echo-mq-ship/SKILL.md)) is the binding
> (it is `/x-mode` with the echo_mq context pre-loaded: Venus loads `echo-mq-architect`, Mars loads
> `echo-mq-implementor`, the Director verifies code + invariants, **Apollo — the evaluator — loads
> `echo-mq-evaluator` and is MANDATORY on this HIGH-risk rung, IN the per-rung pipeline**); the inputs are the
> triad ([`./emq.4.3.md`](emq.4.3.md) · [`./emq.4.3.stories.md`](emq.4.3.stories.md)), the family
> ([`../emq.4.md`](../emq.4.md) — the deepening contract + the carve + the THREE forks), and the canon
> ([`../../../emq.design.md`](../../../../emq.design.md) §4 row 4 / §12.2 / §12.5 / §5 / §6 / §7 / §8 / S-1/§6 /
> S-6). **The build does NOT start until the Operator rules FORK A-MECH** (the mechanism — the touch-set, the §6
> grammar question, and the floor-raise depend on it).

## The family in one paragraph

emq.4 is the groups-deepened family — the shipped fair-lanes (`EchoMQ.Lanes`) mechanism taken to **production
multi-tenant depth** along four axes: a control plane (move a member between lanes; deepen
pause/resume/limit/drain), group-aware recovery (a group-scoped stalled-sweep), the park-don't-poll metronome (the
wake/notify beat hardened), and weighted/deficit rotation (fair-share beyond round-robin + a starvation drill). The
basics ALREADY shipped (B3.4 "Fair Lanes", 8/8 G1–G8); emq.4 does **not** found the family — it **deepens** it.
The family carves into emq.4.1 (control plane — **SHIPPED**) · 4.2 (group-aware recovery — **SHIPPED**) · 4.3 (the
metronome — **this rung**, HIGH-risk) · 4.4 (weighted/deficit + the drill — HIGH iff `@gclaim` edited). The full
deepening contract + the three forks are [`../emq.4.md`](../emq.4.md).

## The rung in one paragraph

emq.4.3 carves the **park-don't-poll metronome**, **re-derived to Arm B** (the Operator's ruling D-1). The shipped
mechanism is a **two-step**: `EchoMQ.Consumer` parks on `BLPOP emq:{q}:wake <beat>` (`consumer.ex:144-149`, the
beat the fallback), is woken by a wake-push baked into every serviceable transition (`@genqueue`/`@gresume`/
`@glimit`/`@greassign`/`@greap_group` in `lanes.ex`; `@complete`/`@retry`/`@promote`/`@reap` in `jobs.ex`;
`@sweep_stalled` in `stalled.ex` — 7 wake-push scripts, the single per-queue `emq:{q}:wake` LIST capped 64), then
`drain`s the ring with rotating `@gclaim`s. **Arm B founds the primitive that makes block-and-serve ONE readiness
contract:** the consumer blocks DIRECTLY on the readiness signal (a server-side blocking move) and then runs the
atomic `@gclaim`, so the lost-wakeup window between "last claim" and "park" closes **by construction**. It builds,
inside `echo/apps/echo_mq` under the v2 laws (the one-transition-one-script law — `@gclaim` NEVER bypassed, design
§12.2; declared keys; branded group ids; the inline `Script.new/2` law; additive-minor conformance; the server
clock on any lease): **(1)** the **new blocking-claim primitive** over the shipped `Connector.command/3` + the
atomic `@gclaim` (the mechanism — MECH-(i)/(ii)/(iii) — WITHHELD pending FORK A-MECH; Venus recommends MECH-(i):
a `BLMOVE` block-move on the shipped `emq:{q}:wake` → `@gclaim`); **(2)** the metronome conformance scenario(s)
(additive minor, the prior **55** byte-unchanged); **(3)** the `:valkey` + **process** suites + the
**≥100-iteration determinism loop**; **(4)** the version climb **2.4.2 → 2.4.3** (the floor-raise minor + the
lockstep fence). The shipped `@gclaim`/`@genqueue`/`@gpause`/`@gresume`/`@glimit`/`@greassign`/`@gdrain`/
`@greap_group` and the `jobs.ex`/`stalled.ex` recovery scripts are **byte-frozen** except the wake-addressing a
ruled MECH-(iii) per-lane LIST would change (INV4 byte-freezes the rest). **The FROZEN-WIRE verdict: NO `echo_wire`
edit** (`Connector.command/3` already carries a blocking command — `consumer.ex:147`). The honest **Out**: a new
transport/connector verb (rides the shipped connector — INV3), bypassing `@gclaim` (§12.2 forbids it — the block
precedes the claim), a host clock on a lease (server clock only — INV2), the control plane (emq.4.1 SHIPPED), the
recovery (emq.4.2 SHIPPED), weighted rotation (emq.4.4), a new §6 key family UNLESS the Operator rules one
(MECH-(iii)). The contract is [`./emq.4.3.md`](emq.4.3.md) (FORK A RULED Arm B; FORK A-MECH + FORK A-MECH-§6
withheld; INV1–INV5).

## Mode

**Flat-L2** (a build + a gate + a verify + a MANDATORY evaluator), Director-supervised. **Not** the Design-Phase
variant (the triad exists — authored this design run). **HIGH-risk.** emq.4.3 **founds a new process/lease
surface** (the blocking-claim primitive reshapes the consumer's block; it may start a new process under
MECH-(ii)), **raises the computed wire floor** (a blocking command — `BLMOVE`/`BLMPOP` — enters the core
inventory; a protocol minor, §12.5), and rides the **fairness-critical wake path** where a **lost-wakeup race**
and a **same-millisecond branded-id mint** are **cross-run** hazards. So the per-app gate ladder **PLUS the
≥100-iteration determinism loop owning the machine** (one green run is NOT proof) **PLUS Apollo MANDATORY** (the
dedicated evaluator re-runs the whole ladder + the loop independently, re-verifies the byte-unchanged conformance
+ the frozen wire, and renders the BUILD-GRADE / BLOCKED verdict the Director ratifies). **The Director's verify
deepens to the ≥100 loop.** It edits **no** shipped lane/recovery script's LOGIC (the byte-freeze grep on
`@gclaim` + the recovery scripts = 0; only a ruled MECH-(iii) re-addresses the wake-push, logic byte-unchanged —
INV4), and performs **no** destructive at-rest op.

Scope slug: **`emq-4-3`** (dashed, no dots — `tool_x_*`/`TeamCreate` require `^[a-z0-9][a-z0-9-]*$`). Operator:
`jonny`. Workspace: `/Users/jonny/dev/jonnify`. Ledger: `docs/echo_mq/specs/progress/emq-4-3.progress.md` (the
design run opened it with the reconcile T-2/T-3 + the learning L-1; the ship run carries the build records).

## The build-choice gate — the Operator rules FORK A-MECH BEFORE the build (Venus recommends MECH-(i))

FORK A is **already ruled (D-1): Arm B** — found a new blocking-claim primitive that subsumes the two-step. What
remains is the **mechanism** (FORK A-MECH, the body), **WITHHELD** pending the Operator's ruling. The build does
NOT start until it is ruled — the touch-set, the §6 grammar question, and the floor-raise all depend on it. The
Venus reconcile (ledger T-2/T-3, L-1) recommends; the Director routes to the Operator; the Operator rules:

> **FORK A-MECH — Venus recommends → MECH-(i) (server-side block-move on the shipped wake → `@gclaim`).** The
> consumer blocks on the shipped `emq:{q}:wake` LIST with a **server-side blocking move** (`BLMOVE wake <sink>
> LEFT RIGHT <beat>` — atomic pop-and-stash, so a crash mid-block does not lose the signal) instead of `BLPOP
> wake`, then runs the existing `drain` → atomic `@gclaim`. **Touch-set:** `consumer.ex` (`park/1` → block-move)
> + `conformance.ex` + `mix.exs` (version) + tests. **§6: NONE** (reuses `emq:{q}:wake`; the `<sink>` is pinned
> at Stage-0 reconcile — a transient the consumer owns, or surfaced as a §6 question if persisted). **Floor-raise:
> `BLMOVE` 6.2-level** (within the 7.0 ceiling; the computed floor ≈ 6.2 already names `LMOVE` — `BLMOVE` is its
> blocking sibling, a one-command minor §12.5). The one reason that carries it: it is the **smallest founding that
> genuinely subsumes the two-step** — one blocking primitive, the block-target IS the readiness structure, the
> lost-wakeup window closed by construction, `@gclaim` and the 7 wake-push scripts byte-unchanged, §12.2 honored.
>
> **MECH-(ii) (the alternative — a dedicated metronome process).** A NEW supervised process owns the beat/block,
> decoupled from the drain. **Touch-set: the largest** (a new process module + `consumer.ex` rewire + the
> supervisor + tests). **§6: possibly a fan-out signalling key.** **Risk: HIGH+** — a process re-org that does
> not, by itself, found a new blocking primitive (the §12.2 law still forces block-then-`@gclaim`); the
> genuinely-new content is thin unless paired with MECH-(i). **Dis-recommended on its own.**
>
> **MECH-(iii) (the per-lane readiness LIST — the per-lane wake answer).** A per-lane `emq:{q}:wake:<group>` LIST
> (a NEW §6 `type` member), each consumer block-moving on the lane(s) it owns. **Touch-set: wide** —
> `consumer.ex` + **the 7 wake-push scripts (re-addressing only — INV4)** + `keyspace.ex` (the §6 member) +
> tests. **§6: YES — a new `wake:<group>` member of the CLOSED `type` registry (`keyspace.ex:14`), a grammar edit
> the Operator must rule (FORK A-MECH-§6).** **Risk: HIGH** (the §6 edit + touching all 7 frozen wake-push
> scripts). Steward note: the most complete answer to the shared-`wake` thundering herd but the widest change;
> it can **layer on MECH-(i) later** (found the primitive on the per-queue wake now, make it per-lane at a
> follow-up). **If the Operator rules MECH-(ii) or MECH-(iii), Mars STOPS and re-scopes the touch-set + the gate
> before building** (the risk grade is HIGH either way, but the boundary, the §6 edit, and the byte-freeze set
> change).
>
> **FORK A-MECH-§6 — the per-lane-wake grammar question (surfaced, the Operator's call).** The §6 `suffix := type
> (CLOSED registry)` (`emq.design.md:290`). MECH-(iii) needs a NEW `type` member (`wake:<group>`) — a grammar
> edit, a protocol minor, registered with its conformance probe. MECH-(i)/(ii) ride the shipped `emq:{q}:wake`
> and need **no §6 edit** (unless MECH-(i)'s `<sink>` is ruled a persisted member). **Ruled at the mechanism
> ruling, never assumed.**
>
> **VERSION — the fence climbs in lockstep (D-3).** emq.4.3 climbs **2.4.2 → 2.4.3** across BOTH the `mix.exs`
> label AND the connector `@wire_version` / `{emq}:version` fence — they carry the same number and move together
> per rung. The connector fence **logic** stays frozen (only the constant moves; `connector.ex:35`); the `:fence`
> conformance scenario + `connector_test` are version-agnostic (assert the live key `== Connector.wire_version()`),
> so they never need a per-rung edit; the bump re-seeds `{emq}:version` once via `DEL`. This is one minor step on
> the climb to `echomq:3.0.0` — the **MAJOR** ratified at emq.8 (the horizon the Director tracks), not this rung.
> **The computed-floor raise the new blocking command introduces (§12.5) is itself a protocol minor — this version
> step covers it.**

## The as-built floor (verified at the design run, 2026-06-18 — the build's Stage-0 RE-PROBES each; the lag-1 law)

Anchors drift; a sibling rung could move the `echo_mq` surface before emq.4.3 reads it — the build's Stage-0
reconcile re-pins every line below:

- **The conformance count** — `conformance.ex` `scenarios/0` (the pre-build floor = **55**; emq.4.1 added
  `reassign`/`lane_drain`, emq.4.2 added `reap_group`, 52 → 54 → 55). **The seed's "52" was STALE (pre-emq.4.1
  ship) — re-derived to 55 → N.** `conformance_run_test.exs:48` `== {:ok, 55}`; `conformance_scenarios_test.exs`
  `@run_order` 55 names; both module docs the count word.
- **The fence** — `connector.ex:35` `@wire_version "echomq:2.4.2"` (NOT the seed's stale `echomq:2.0.0`). emq.4.3
  climbs **2.4.2 → 2.4.3** in lockstep (the `mix.exs` `:echo_mq` `version` + `@wire_version` + the live
  `{emq}:version`).
- **`Consumer` (the shipped park-don't-poll two-step — the EDIT target)** — `consumer.ex`: `spawn_link` loop
  `:40` (NOT a GenServer); `beat_ms` default 1000 `:58`; the loop `check_control → reap → promote → drain →
  park` `:91-97`; `drain/1` exhaustive recursion until `Lanes.claim → :empty` `:114-142`; `park/1` =
  `Connector.command(s.conn, ["BLPOP", wake, secs], s.beat_ms + 2_000)` `:144-149`, `wake = Keyspace.queue_key(s.queue,
  "wake")` `:146`; the **dedicated connector lane** self-started `:43-51` (the moduledoc: "blocking verbs get
  their own lane (Appendix B)"); `stop/2` `:78-89` (monitor + `:emq_stop` at a settle point). **Mars re-probes
  `park/1` + the loop before the EDIT.**
- **`@gclaim` (BYTE-FROZEN — the atomic claim the block PRECEDES, never bypasses — §12.2)** — `lanes.ex:37-61`:
  `LMOVE KEYS[1] KEYS[1] LEFT RIGHT` (the ring rotate) `:38`; `ZPOPMIN lane` (the head) `:41`; `HINCRBY attempts`
  (the fencing token) `:48`; the **server clock** `redis.call('TIME')` + `now = t[1]*1000 + math.floor(t[2]/1000)`
  `:50-51`; the lease `ZADD active now+lease id` `:52`; the `gactive`/ceiling/ring bookkeeping `:53-59`; returns
  `{id, payload, att, g}`. `claim/3` host verb `:171-184` (`KEYS=[ring, active]`, `ARGV=[base, lease]`;
  queue-wide pause honored first `:172`). **`@gclaim` is byte-frozen — the block feeds it, the lib diff `grep
  redis.call` on `@gclaim` = 0.**
- **The wake-push protocol (the readiness signal — re-addressed ONLY under a ruled MECH-(iii))** — `lanes.ex`
  `@genqueue:30-31`, `@gresume:77-78`, `@glimit:94-95`, `@greassign:132-133`, `@greap_group:375-376`; `jobs.ex`
  `@complete:200-201`, `@retry:277-278`, `@promote:336-337`, `@reap:366-367`; `stalled.ex` `@sweep_stalled:83-84`
  — each `LPUSH <base>'wake' '1'` + `LTRIM <base>'wake' 0 63` (the single per-queue `wake` LIST capped 64). **7
  scripts. Under MECH-(i)/(ii) they are byte-frozen; under MECH-(iii) only the `LPUSH`/`LTRIM` TARGET changes
  (the addressing), every other line byte-identical to HEAD (INV4).**
- **`Keyspace.queue_key/2` + the §6 `type` registry (the per-lane-wake grammar question)** — `keyspace.ex:14`
  (`queue_key` → `emq:{q}:<type>`); the §6 `suffix := type (CLOSED registry)` (`emq.design.md:290`). `wake` is a
  registered per-queue type (`keyspace_extend_test.exs:52` lists it). A per-lane `wake:<group>` (MECH-(iii)) is a
  NEW member — a §6 grammar edit ruled by the Operator (FORK A-MECH-§6), NOT assumed.
- **The FROZEN wire (NO `echo_wire` edit)** — `connector.ex`: `command/3:49` carries arbitrary
  `[binary|integer|atom]` parts with a custom timeout (park's `BLPOP` rides it `:147`); `eval/5:65` (the
  EVALSHA-first `@gclaim`); the serialized FIFO `GenServer` (`send_pipe` enqueues `pending` `:298`). `Connector`/
  `RESP`/`Script` **frozen by committed records** (`echo_wire.ex:12-14`). A blocking `BLMOVE`/`BLMPOP` rides the
  same `command/3` → **NO new verb, NO `echo_wire` edit, NO frozen-record change.**
- **The test harness (the metronome suites model on it)** — `consumer_test.exs`: `@moduletag :valkey`;
  `Connector.start_link(port: 6390)`; per-test queue `q = "emq0.consumer#{System.unique_integer([:positive])}"`;
  `on_exit` purge over `KEYS emq:{q}:*`; `wait_until/2` (a 5ms poll, 400 tries); `BrandedId.generate!("JOB")` +
  `("PRT")`; `Consumer.start_link(queue:, handler:, connector: [port: 6390], beat_ms:, lease_ms:)`;
  `assert_receive {:handled, …}, 3_000`. `EchoData.Snowflake.start(4)` in `setup_all`.

## The pipeline — the HIGH rung (Venus → Mars-1 → Director review → Mars-2 → Apollo MANDATORY → Director ship)

Each spawned stage is a real `general-purpose`/dedicated `Agent` that adopts its `.claude/agents/<role>.md`
charter, LOADS its `echo-mq-<role>` skill, and self-registers via `mcp__aaw__*` (LAW-1; no narrated spawns). The
Director holds the gate between stages. The per-spawn contract is the `/x-mode` skill §3 (Framing → adopt charter
→ aaw ceremony → the stage block → audit directive → propagation clause → report). **Require artifact-level
checkpoints** (SendMessage a concrete report after each pass; the Director's ground-truth verification is the
gate, not the self-verdict).

### Stage 0/1 — Venus (architect): the triad + the pre-build reconcile + the FORK A-MECH recommendation

**(DONE this design run — Stage 1, re-derived to Arm B.)** Directive: re-derive the emq.4.3 triad
(`.md`/`.stories.md`/`.prompt.md`) to **Arm B** (D-1), reconciled lag-1 against the as-built tree. Re-probe every
anchor above; pin the conformance count (**55** — reconcile the seed's stale 52); pin the fence (**2.4.2 → 2.4.3**
— reconcile the seed's stale 2.0.0); render the **FROZEN-WIRE verdict** (NO `echo_wire` edit — `command/3` carries
the block); FRAME **FORK A-MECH** as three mechanisms (MECH-(i)/(ii)/(iii)) each with its FROZEN-WIRE verdict +
touch-set + §6 question + floor-raise + risk; surface **FORK A-MECH-§6** (the per-lane-wake grammar question);
recommend **MECH-(i)**. Gate: the triad authored; the reconcile delta table; the BUILD-GRADE verdict; FORK A-MECH
+ FORK A-MECH-§6 surfaced for the Operator's ruling. **At the build's Stage 0, Mars RE-PROBES the floor (the
lag-1 law — a sibling rung could have moved an anchor).**

### Stage 1 — Mars-1 (implementor): found the blocking-claim primitive (after FORK A-MECH is ruled)

**Precondition: the Operator has ruled FORK A-MECH (and FORK A-MECH-§6 if implied).** If the ruling is MECH-(ii)
or MECH-(iii), Mars STOPS and re-scopes the touch-set + the gate before building (the boundary, the §6 edit, and
the byte-freeze set change). Directive (authored to the recommended **MECH-(i)**; re-scope to the ruled
mechanism): build the new blocking-claim primitive to the brief's agent stories and the design. The order: **(1)**
edit `consumer.ex` `park/1` to the founded primitive (MECH-(i): `Connector.command(s.conn, ["BLMOVE", wake,
<sink>, "LEFT", "RIGHT", secs], s.beat_ms + 2_000)` — a server-side block-move on the shipped `emq:{q}:wake`,
atomic pop-and-stash; pin the `<sink>` at the reconcile) — the block PRECEDES the existing `drain` → atomic
`@gclaim` (NEVER pop the lane/ring client-side — §12.2; `@gclaim` byte-frozen); keep the loop `reap → promote →
drain → block`, the beat the fallback timeout; **(2)** the metronome scenario(s) in `conformance.ex` (US1
admit-while-parked → served within the beat; US2 the park-boundary lost-wakeup race; US3 multi-consumer fairness —
the load-bearing proofs, each defeats a no-op: a scenario that passes even with the old `BLPOP` must be
distinguished, e.g. by asserting service WELL BEFORE the beat elapses, not merely "eventually") + the count re-pin
**55 → N** in both pin tests; **(3)** the `:valkey` + process suite(s) (model on `consumer_test.exs`); **(4)** the
version bump `mix.exs` **2.4.2 → 2.4.3** + (no fence-logic edit; the constant `@wire_version` moves to
`echomq:2.4.3`, the bump re-seeds `{emq}:version` once via `DEL` in the suite setup). Cite the spec/design line for
every public call; **declared keys** (every Lua key in `KEYS[]` or rooted — INV3; the block-move's keys are the
shipped `wake` + the `<sink>`); **inline `Script.new/2`** (no `priv/`; no new script unless MECH-(iii) re-addresses
the wake-push — then the EXISTING scripts' logic is byte-unchanged, only the `LPUSH`/`LTRIM` target moves);
**server clock** (`@gclaim`'s `TIME` is the only lease — INV2; the block timeout is host-side, not a lease);
**`@gclaim` byte-frozen** (`grep redis.call` on `@gclaim` in the lib diff = 0 — the block feeds it, never edits
it); register the conformance scenario + probe **in the same change** (INV5; the prior 55 byte-unchanged); compile
clean (`--warnings-as-errors`, per-app). **INV3/INV4 gate**: `@gclaim` + the 7 wake-push scripts byte-unchanged
(`grep redis.call` on them = 0; under MECH-(iii) the wake-push LOGIC byte-unchanged, only the addressing); **the
FROZEN-WIRE gate**: `echo/apps/echo_wire/lib/` byte-unchanged in the lib diff. Gate: per-app compiles green;
D-n exist; the diff stays inside `echo_mq` (no `echo_wire`; `keyspace.ex` ONLY if MECH-(iii) §6 ruled; no
`apps/echomq`); the boundary grep empty.

### Stage 2 — Director: solo review (a REAL pass — deepened for HIGH-risk)

A fresh-gate reconcile + an independent gate re-run on Valkey 6390 + **the ≥100 determinism loop** + ≥1
adversarial probe: the **FROZEN-WIRE** probe (`echo/apps/echo_wire/lib/` byte-unchanged in the diff; no new
connector verb; `Connector`/`RESP`/`Script` byte-identical to HEAD); the **§12.2** probe (the lane/ring pop is
inside `@gclaim` only — no client-side `ZPOPMIN`/`LMOVE` of the lane/ring; `@gclaim` byte-frozen `grep redis.call`
= 0); the **lost-wakeup** probe (the load-bearing proof — admit a job exactly at the park boundary, repeatedly
under the ≥100 loop → served within the beat EVERY run; a recheck-after-park or a separate-token design that loses
a wakeup is caught here as a cross-run flake); the **serve-within-beat** probe (admit while parked → handled WELL
BEFORE a full beat elapses, NOT only on the beat — defeats a no-op that just polls on the beat); the
**multi-consumer fairness** probe (two parked consumers + a stream of admits → both serve a share, neither
starves); the **server-clock** probe (`@gclaim`'s lease is `redis.call('TIME')`; the block timeout is host-side
but touches NO lease — INV2); the **byte-freeze** probe (`grep redis.call` on `@gclaim` + the 7 wake-push scripts
+ the recovery scripts in the lib diff = 0, or under MECH-(iii) the wake-push logic byte-identical with only the
addressing changed; the prior metronome-adjacent scenarios `rotate`/`pause`/`limit` byte-identical); the
**byte-unchanged conformance** probe (`git diff` shows only additions to `scenarios/0`; the 55 prior scenarios
byte-identical); the **version** probe (`{emq}:version` → `echomq:2.4.3`; the `mix.exs` label + `@wire_version` in
lockstep; the fence LOGIC frozen; the `:fence` scenario version-agnostic, byte-unchanged); a **mutation
spot-check** (Edit-in a fault — e.g. revert `park/1` to the old `BLPOP` → the lost-wakeup race scenario catches it
across the ≥100 loop → revert → `git diff --stat` clean, net-zero, LAW-1a). Produce the REMEDIATE list.

### Stage 3 — Mars-2 (implementor, harden + the full gate ladder + the ≥100 loop)

Resume the Stage-1 Mars (one identity, two passes). Directive: remediate; run the full ladder — toolchain
re-probe (`asdf current erlang` from the app dir — confirmed Erlang 28.5.0.1 / Elixir 1.18.4) + Valkey 6390 PONG;
per-app pure + `:valkey` + process suites (`TMPDIR=/tmp`, NEVER umbrella-wide; `--include valkey` for the
metronome suites); `Conformance.run/2 → {:ok, N}` with the prior 55 byte-unchanged + the metronome scenario(s)
probe-registered; **the ≥100-iteration determinism loop green OWNING THE MACHINE** (`for i in $(seq 1 150); do
TMPDIR=/tmp mix test --include valkey || break; done` — no concurrent liveness server, no sibling heavy I/O; the
lost-wakeup race + the same-millisecond branded-id mint are exactly the cross-run hazards one green run does not
surface); the version climbs to 2.4.3 in lockstep (the `mix.exs` label AND the `@wire_version` fence together —
D-3; the `:fence` scenario version-agnostic); coverage tabled with the reason for any gap. REMEDIATE loop MAX 3.
Gate: every ladder item PASS or explained; the conformance tally clean; the byte-freeze grep = 0; the FROZEN-WIRE
grep clean (`echo_wire/lib/` byte-unchanged); the ≥100 loop green; the boundary grep empty.

### Stage 4 — Apollo (evaluator) — MANDATORY (HIGH-risk)

Directive (**MANDATORY** — the rung founds a process/lease surface + raises the computed wire floor): the
post-build reconcile (does the as-built primitive satisfy the spec's promises?) + the §11.2-charter adversarial
verification applied to the metronome (the lost-wakeup race under the ≥100 loop INDEPENDENTLY re-run; the §12.2
no-bypass probe; the FROZEN-WIRE re-verify; the server-clock probe) + the per-app gate ladder + **the
≥100-iteration determinism loop re-run independently** + re-verify the conformance count is byte-unchanged with
the metronome scenario(s) probe-registered + sync-check the spec body to what shipped. Render the **BUILD-GRADE /
BLOCKED verdict the Director ratifies** + ≥1 mentoring observation folded forward (Director-ratified). Apollo is
IN the pipeline on this rung (not a fast-finisher).

### Stage 5 — Venus (architect): the post-build reconcile

Sync the triad body to the as-built surface (the founded primitive's real shape — the `park/1` block-move form,
the `<sink>` disposition, the ruled mechanism; the metronome scenario names + the final conformance N; the version
2.4.3; the §6 disposition — "rides `emq:{q}:wake`, no §6 edit" under MECH-(i), or the new member under
MECH-(iii)); every triad claim MATCH or `[RECONCILE]`-marked; fold the metronome axis discharged in the family
([`../emq.4.md`](../emq.4.md) — the metronome sub-rung). **The backward reconcile is owed** (the emq.4.2 F6 lesson
— a forward-only reconcile lets the committed spec drift from as-built; sync the forward-tense brief to what
shipped so emq.4.4 reconciles against truth). **Re-pin the family body's stale "52" (INV6) + "echomq:2.0.0" (INV1)
to the live 55→N + 2.4.3 if the Director includes `emq.4.md` in the commit** (a family-level reconcile delta
carried forward — see the Venus report).

### Stage 6 — Director: closure + ONE LAW-4 commit + the family fold

Preconditions (x-mode §4): the gate green + **Apollo BUILD-GRADE** (MANDATORY on this rung — the evaluator's
verdict is a precondition, not optional) + the reconcile build-grade; **≥1 `tool_x_decision` (D-n)** — at minimum
the FORK A-MECH ruling (the mechanism) + the FORK A-MECH-§6 ruling (the §6 question) + the version ruling
(2.4.3) — + a **`tool_x_complete` (Z-n)** this turn; `git status --short` AND `git diff --cached --name-only`
reviewed; `.git/rebase-merge`/`rebase-apply` checked. Then the **pathspec** commit (below; NEVER `git add -A`,
NEVER a bare commit). **Same turn:** flip the emq.4.3 row in the single roadmap
([`../../../emq.roadmap.md`](../../../../emq.roadmap.md)) and the dashboard
([`../../../emq.progress.md`](../../../../emq.progress.md)); record the metronome axis shipped (the groups family
deepening; 4.4 next); surface the **next frontier** (emq.4.4 weighted/deficit + the starvation drill — HIGH iff
`@gclaim` edited, **FORK B settles before 4.4**); under an **explicit Operator grant only**, fold any mentoring
diff into the peer charters / the echo-mq-* skills (one guardrail per finding). The message cites the slug, the
Z-n, the D-n, and the Y-n report.

## Risk tier

**HIGH.** emq.4.3 **founds a new process/lease surface** (the blocking-claim primitive reshapes the consumer's
block; MECH-(ii) starts a new process), **raises the computed wire floor** (a blocking command — `BLMOVE`/`BLMPOP`
— enters the core inventory; a protocol minor, §12.5, covered by the 2.4.3 version step), and rides the
**fairness-critical wake path**. The cross-run hazards: a **lost-wakeup race** (work admitted at the park boundary)
and a **same-millisecond branded-id mint** across concurrent consumers — neither surfaces in one green run. The
mitigating gates:
1. **The lost-wakeup robustness (the load-bearing proof).** The primitive must serve a job admitted at the park
   boundary within the beat — the Director's **lost-wakeup probe under the ≥100 loop** (admit at the boundary,
   repeatedly → served every run) catches a design that loses a wakeup; a scenario that only checks "served
   eventually" or runs once would pass even with a lost-wakeup bug, so the **WELL-BEFORE-THE-BEAT** assertion +
   the **≥100 loop** are mandatory (the gate-liveness law).
2. **The §12.2 no-bypass + the FROZEN-WIRE verdict.** The block must NEVER pop the lane/ring client-side
   (`@gclaim` stays the atomic claim — design §12.2) and must ride the shipped connector (NO `echo_wire` edit) —
   the Director's **§12.2 probe** (`@gclaim` byte-frozen; no client-side lane/ring pop) + the **FROZEN-WIRE probe**
   (`echo_wire/lib/` byte-unchanged) catch a bypass or a wire break.
3. **The ≥100 determinism loop owns the proof.** A multi-seed sweep is NOT enough — the same-millisecond mint +
   the lost-wakeup race are cross-run. The loop must own the machine.

**Apollo is MANDATORY** — the dedicated evaluator re-runs the whole ladder + the ≥100 loop independently and
renders the BUILD-GRADE / BLOCKED verdict the Director ratifies. The Director's verify deepens to the ≥100 loop.

## The Stage-6 commit pathspec (Director-only — the emq.4.3 BUILD)

Commit exactly the rung's measured surface (the build run's actual touch-set is authoritative — adjust to what the
stages truly changed; the mechanism ruling decides whether `keyspace.ex` and the wake-push scripts are touched):

```text
docs/echo_mq/specs/emq2/emq.4/emq.4.md                       (the family contract, IF Stage-5 synced the stale 52→55 / 2.0.0→2.4.3 family pins)
docs/echo_mq/specs/emq2/emq.4/emq.4.rungs/emq.4.3.md         (the body, Stage-5 synced — status → SHIPPED, the count 55→N, the ruled mechanism)
docs/echo_mq/specs/emq2/emq.4/emq.4.rungs/emq.4.3.stories.md
docs/echo_mq/specs/emq2/emq.4/emq.4.rungs/emq.4.3.prompt.md  (this runbook)
docs/echo_mq/specs/progress/emq-4-3.progress.md
docs/echo_mq/emq.roadmap.md                                  (the emq.4.3 row → shipped)
docs/echo_mq/emq.progress.md                                 (the dashboard fold)
echo/apps/echo_mq/lib/echo_mq/consumer.ex                    (the founded block-and-serve primitive — park/1)
echo/apps/echo_mq/lib/echo_mq/conformance.ex                 (the metronome scenario(s), additive)
echo/apps/echo_mq/lib/echo_wire/connector.ex                 (ONLY the @wire_version constant 2.4.2 → 2.4.3 — NO logic edit; see note)
echo/apps/echo_mq/mix.exs                                     (version 2.4.2 → 2.4.3, additive minor + the floor-raise)
echo/apps/echo_mq/test/                                       (the metronome :valkey + process suites + the conformance pins 55→N)
# IF MECH-(iii) is ruled (the per-lane wake):
echo/apps/echo_mq/lib/echo_mq/keyspace.ex                    (the new §6 wake:<group> type member — ONLY under MECH-(iii) + FORK A-MECH-§6 ruled)
echo/apps/echo_mq/lib/echo_mq/lanes.ex                        (the wake-push re-addressing — LOGIC byte-unchanged, INV4 — ONLY under MECH-(iii))
echo/apps/echo_mq/lib/echo_mq/jobs.ex                         (the wake-push re-addressing — LOGIC byte-unchanged, INV4 — ONLY under MECH-(iii))
echo/apps/echo_mq/lib/echo_mq/stalled.ex                      (the wake-push re-addressing — LOGIC byte-unchanged, INV4 — ONLY under MECH-(iii))
```

> **The `connector.ex` note (the ONE `echo_wire` file touched — and ONLY the constant).** The FROZEN-WIRE verdict
> is that the primitive needs **no `echo_wire` LOGIC edit** (`command/3` already carries the block). The version
> lockstep (D-3), however, moves the `@wire_version` CONSTANT (`connector.ex:35`) from `echomq:2.4.2` to
> `echomq:2.4.3` — this is the same one-line constant move emq.4.1/4.2 made, NOT a logic change to the frozen
> connector (the records freeze the module's CONTRACT, not the version string the fence climbs). `connector.ex`
> lives under `echo/apps/echo_wire/lib/echo_mq/` (the historical namespace under the `echo_wire` app — re-probe
> the exact path at Stage 0; the surface map cites `echo/apps/echo_wire/lib/`). If the build keeps the
> `@wire_version` in `echo_mq` instead (re-probe — the fence's `Keyspace` read is in `echo_mq` per the design §4
> cluster-4 note), adjust the pathspec. **EXCLUDE the rest of `echo_wire/lib/` — byte-unchanged (INV3).**

**EXCLUDE** (Operator out-of-band — never sweep into the rung commit): `echo/apps/live_svelte/**`,
`echo/apps/mercury_cms/**`, `echo/apps/mercury_live_admin/**`, `html/**`, the F# course, and any
`[emq]`/`[bcs]`/`[mercury]` doc commits the Operator lands between stages. `echo/apps/echomq` (frozen v1 — the
capability reference) + the rest of `echo/apps/echo_wire/lib/` (the primitive rides the shipped connector — only
the `@wire_version` constant moves, see the note) + `echo/apps/echo_mq/lib/echo_mq/lanes.ex` (`@gclaim` + the
wake-push scripts byte-frozen — **no `lanes.ex` edit UNLESS MECH-(iii) re-addresses the wake-push, logic
unchanged**) + `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` (**no grammar edit UNLESS MECH-(iii) §6 ruled**) +
`echo/mix.lock` (emq.4.3 adds no dep — expect `mix.lock` EXCLUDED) UNTOUCHED. **Never `git add -A`.** (Under
MECH-(i)/(ii), `lanes.ex`/`jobs.ex`/`stalled.ex`/`keyspace.ex` are NOT edited — adjust the pathspec to the ruled
mechanism.)

## Acceptance — "shipped" means

Every DoD box in [`./emq.4.3.md`](emq.4.3.md) is checkable from the run's outputs: FORK A confirmed Arm B (D-1) +
FORK A-MECH ruled (the mechanism) + FORK A-MECH-§6 ruled (the §6 question) before any artifact; the new
blocking-claim primitive (the `park/1` block-and-serve subsuming the `BLPOP wake` + `drain` two-step — no wake lost
under a concurrent admit-then-park, by construction; the block NEVER bypasses `@gclaim` — §12.2; `@gclaim`
byte-frozen); fair readiness distribution across parked consumers; the FROZEN-WIRE verdict held (`echo_wire/lib/`
byte-unchanged but the `@wire_version` constant moved to 2.4.3); the metronome scenario(s) additive-minor with the
prior 55 byte-unchanged + the count re-pinned 55 → N in both pin tests; the `:valkey` + process suites green + **the
≥100-iteration determinism loop green owning the machine** (the lost-wakeup race + the mint hazard) + no regression
+ the byte-freeze grep = 0 + the version 2.4.3 in lockstep; **Apollo BUILD-GRADE** (MANDATORY — the evaluator's
independent ladder + ≥100 loop + the §12.2/FROZEN-WIRE re-verify). The spec body stays authoritative; Stage 5 syncs
it to the as-built surface (the backward reconcile owed); the groups family capstone (emq.4.4 weighted/deficit +
the drill) opens on a proven metronome.

Inputs: [`./emq.4.3.md`](emq.4.3.md) · [`./emq.4.3.stories.md`](emq.4.3.stories.md) · Family:
[`../emq.4.md`](../emq.4.md) (the deepening contract + the carve + the forks) · Canon:
[`../../../emq.design.md`](../../../../emq.design.md) §4 row 4 (park, don't poll) / §12.2 (the
one-transition-one-script law — `@gclaim` never bypassed) / §12.5 (the engine floor — a computed-floor raise is a
protocol minor) / §5 (no new wire class) / §6 (the CLOSED `type` registry — the per-lane-wake grammar question) /
S-1/§6 / S-6 · Roadmap: [`../../../emq.roadmap.md`](../../../../emq.roadmap.md) Movement II · The shape model:
[`./emq.4.2.prompt.md`](emq.4.2.prompt.md) (the sibling recovery runbook) · Skills:
`.claude/skills/echo-mq-ship.md` (the binding) + `echo-mq-{architect,implementor,evaluator}.md` (the per-role
craft) + `echo-mq-program.md` (the program law) · Approach:
[`../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
