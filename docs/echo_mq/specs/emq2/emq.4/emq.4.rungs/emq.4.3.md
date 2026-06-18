# EMQ.4.3 · The park-don't-poll metronome — a new blocking-claim primitive (Movement II, the groups family)

> **Status: 📐 PROPOSED — re-derived to Arm B (the Director's ruling D-1).** The THIRD sub-rung of the emq.4
> "groups deepened" family; the family contract + the carve + the forks are [`../emq.4.md`](../emq.4.md)
> (authoritative — if this carve disagrees with the body, the body wins). emq.4.3 deepens the **park-don't-poll
> metronome** — the wake/notify beat by which a consumer PARKS (blocks) and is served on admission/availability
> instead of busy-polling. **The Operator ruled FORK A → Arm B** (D-1): emq.4.3 does NOT merely harden the shipped
> wake-token two-step (that was Arm A, recommended-but-rejected) — it **founds a new blocking-claim primitive that
> subsumes the shipped two-step.** The shipped two-step is: a consumer parks on `BLPOP emq:{q}:wake <beat>`
> (`consumer.ex:144-149`, the beat the fallback), is woken by a wake-push baked into every serviceable transition
> (`@genqueue`/`@gclaim`/`@gresume`/`@glimit`/`@greassign`/`@greap_group` in `lanes.ex`, `@complete`/`@retry`/
> `@promote`/`@reap` in `jobs.ex`, `@sweep_stalled` in `stalled.ex`), then `drain`s the ring with rotating
> `@gclaim`s. **Arm B founds the primitive that makes block-and-serve ONE readiness contract** — the consumer
> blocks DIRECTLY on the readiness signal (a server-side blocking move) and then runs the atomic `@gclaim`, so the
> lost-wakeup window between "last claim" and "park" closes **by construction** (the signal IS the structure the
> admit pushes to; there is no separate token that can be missed). **Risk: HIGH** — the founding reshapes a
> **process/lease surface** on the fairness-critical wake path and raises the **computed wire floor** (a blocking
> command enters the core inventory); a **lost-wakeup race** and a same-millisecond branded-id mint are
> **cross-run** hazards one green run cannot surface. **Apollo MANDATORY at build; the ≥100-iteration determinism
> loop owns the proof; the Director's verify deepens.** The **mechanism sub-fork is WITHHELD** (FORK A-MECH below)
> — emq.4.3 builds only after the Operator rules which Arm-B mechanism. The v2 master invariant binds (the
> one-transition-one-script law · server clock where a lease is touched · `@gclaim` stays the atomic claim, never
> bypassed — design §12.2). Forward-tense: every emq.4.3 surface is PROPOSED, NOT shipped.

## 0 · The slice — what emq.4.3 founds, and the reconcile deltas it carries

The family ([`../emq.4.md`](../emq.4.md)) deepens the shipped fair-lanes mechanism. emq.4.3 carves the
**metronome**. The foundation proved the *mechanism* — park on `BLPOP wake`, the beat as a fallback, a wake pushed
by every serviceable transition — on the happy path. The Operator's Arm-B ruling (D-1) scopes emq.4.3 to **found a
new blocking-claim primitive that subsumes that two-step**, so the wake is no longer a separate token a consumer
consumes-then-drains but the **readiness contract the consumer blocks-and-claims on**, with **no lost wakeup** by
construction and **fair** service across parked consumers.

**Two reconcile deltas against the seed (both carried below):**

- **DELTA 1 — the conformance count is 55, not 52.** The seed (authored pre-emq.4.1) said "prior 52". The live
  set is **55** (`conformance_run_test.exs:48` `== {:ok, 55}`; `conformance_scenarios_test.exs` `@run_order` 55
  names) — emq.4.1 added two (`reassign`, `lane_drain`), emq.4.2 added one (`reap_group`), 52 → 54 → 55. emq.4.3
  re-pins **55 → N**.
- **DELTA 2 — the fence is `echomq:2.4.2`, not `echomq:2.0.0`.** The connector `@wire_version` climbs in lockstep
  per rung (D-3): 4.1 → `2.4.1`, 4.2 → `2.4.2`. emq.4.3 advances to **`echomq:2.4.3`** across the `mix.exs` label
  AND the `@wire_version`/`{emq}:version` fence together. This is one minor step on the climb to `echomq:3.0.0` —
  the MAJOR ratified at emq.8, NOT this rung. **A blocking-command floor-raise (a new core command) is itself a
  computed-floor protocol minor** (§12.5) — emq.4.3 carries one, the version step covers it.

The chapter's ruled spine grades emq.4.3 "founds a process/lease surface" — and under Arm B that grade is
**literal**: the primitive is the new surface, not merely a hardened wake protocol. Surfaced as **FORK A-MECH**
below (the mechanism), the Operator's call before the build.

## Goal

emq.4.3 founds, inside `echo/apps/echo_mq`, a **new blocking-claim primitive** for the **park-don't-poll
metronome** over the shipped `EchoMQ.Consumer` park loop, the shipped `g:`-segment lane keyspace, and the shipped
`@gclaim` atomic claim, so that: (a) a parked consumer **blocks on the readiness signal and serves the ready lane
within the beat** (the beat the fallback), with **no lost wakeup** under a concurrent admit-then-park — the
load-bearing metronome proof — because the block-target IS the structure the admit pushes to (the lost-wakeup
window closes by construction, not by a recheck); (b) when several consumers park on one queue, readiness is
**distributed fairly** across them (no consumer permanently starved); (c) the primitive **rides the shipped
connector** (`Connector.command/3` already carries an arbitrary blocking command with a custom timeout — park's
`BLPOP` is proof, `consumer.ex:147`) — **no new connector verb, no `echo_wire` edit** — and the atomic `@gclaim`
stays the claim (a blocking pop NEVER bypasses the lease/attempts/`gactive`/ring-rotation bookkeeping — design
§12.2). Any lease the primitive touches reads `TIME` **server-side** (the as-built `@gclaim` pattern). The
primitive does **not** break the wire: it raises the **computed floor** by one blocking command (a protocol minor
— §12.5, carried by the version step), and whether it needs a new §6 key member (a per-lane readiness LIST) is a
**grammar question surfaced to the Operator at the mechanism ruling, NOT assumed** (the default rides the shipped
single per-queue `emq:{q}:wake`). emq.4.3 builds only after **FORK A-MECH** is ruled.

## Rationale (5W)

- **Why** — the metronome is the surface that makes the bus **cheap at rest and prompt under load**: a parked
  consumer costs the wire nothing, and a ready job is served within the beat. The foundation proved the
  *two-step* mechanism (park on a wake token, then drain). Arm B founds the *primitive* that makes the two steps
  **one readiness contract**, eliminating the structural gap the two-step leaves: a **lost wakeup** (work admitted
  in the window between a consumer's last claim and its `BLPOP`) would hang a ready job until the next beat, and a
  separate wake token is a value that can be consumed by the wrong consumer or trimmed away. Blocking directly on
  the readiness structure closes that gap by construction. These are the robustness properties a multi-tenant bus
  needs and the foundation's two-step did not gate at this depth.
- **What** — emq.4.3 builds (forward-named; the founded primitive — re-probe the shipped `Consumer`/`@gclaim`/
  `wake` at the pre-build reconcile): (1) the **new blocking-claim primitive** — a block-and-serve over the
  shipped connector that subsumes the `BLPOP wake` + `drain` two-step (the precise mechanism — a server-side
  blocking move on the readiness LIST feeding the atomic `@gclaim`, or a dedicated metronome process owning the
  block, or a third the reconcile reveals — is **WITHHELD** and pinned at **FORK A-MECH** + the reconcile); (2)
  **lost-wakeup robustness by construction** (no wake lost under a concurrent admit-then-park); (3) **fair**
  readiness distribution across parked consumers; (4) the conformance scenario(s) for the metronome (admit while
  parked → served within the beat; the park-boundary lost-wakeup race; multi-consumer fairness) (additive minor,
  the prior **55** byte-unchanged); (5) the `:valkey` + **process** test suites + the **≥100-iteration determinism
  loop** owning the machine; (6) the version climb **2.4.2 → 2.4.3** (the floor-raise minor + the lockstep fence).
- **Who** — the program (the rung that founds the metronome primitive); the bus's **consumers**, who gain
  lost-wakeup-free, fairly-served blocking; **Apollo**, who re-runs the gate ladder + the ≥100 loop independently
  (**MANDATORY** — the rung founds/reshapes a process/lease surface on the fairness-critical wake path AND raises
  the computed floor). The shipped `EchoMQ.Consumer` loop, the `@gclaim` atomic claim, and the wake protocol are
  the proven precedents it subsumes.
- **When** — Movement II, the groups family's **third** sub-rung, after emq.4.1 (control plane — SHIPPED) and
  emq.4.2 (group-aware recovery — SHIPPED). SPECCED this design cycle (re-derived to Arm B per D-1); **built only
  after the Operator rules FORK A-MECH** (the mechanism — the touch-set + the §6 grammar question depend on it).
  The full triad + the build follow one increment per run.
- **Where** — `echo/apps/echo_mq` only: `consumer.ex` (EDIT — the founded block-and-serve loop replaces the
  `BLPOP wake` → `drain` two-step — **the HIGH-RISK process-surface edit; Apollo MANDATORY**), `lanes.ex` and/or
  `jobs.ex` / `stalled.ex` (EDIT **only if** the chosen mechanism re-addresses the wake-push — re-probe; a
  per-lane readiness LIST would touch the shipped scripts that push `wake`, re-grading those edits under
  byte-freeze of the unchanged logic — INV4), `keyspace.ex` (EDIT **only if** the Operator rules a new §6 `type`
  member for a per-lane readiness LIST — the §6 `type` registry is CLOSED, `keyspace.ex:14`, so a new member is a
  grammar edit ruled at FORK A-MECH, NOT assumed), `conformance.ex` (EDIT — the metronome scenario(s) + the count
  re-pin), `mix.exs` (EDIT — the version 2.4.2 → 2.4.3), `test/*_test.exs` (NEW/EDIT — the `:valkey` + process
  metronome proof), the two pinning tests (EDIT — the count). **`echo_wire` is UNTOUCHED** (the primitive rides
  the shipped `Connector.command/3` `BLPOP`/`BLMOVE`/`BLMPOP`/`eval` — no new transport, no new connector verb,
  no facade change; INV3 — see the FROZEN-WIRE VERDICT below). `apps/echomq` is **UNTOUCHED** (the capability
  reference). Exact line anchors pinned at the pre-build reconcile.

### The FROZEN-WIRE VERDICT (the headline reconcile finding — Venus surfaces, the Director carries it)

`EchoMQ.Connector` / `RESP` / `Script` are **frozen by committed records** (`echo_wire.ex:12-14`: "Module names
`EchoMQ.Connector`, `EchoMQ.RESP`, and `EchoMQ.Script` are frozen by the committed records that cite them"; the
`EchoWire` facade is the forward-facing name). The connector's public surface is `command/3`, `pipeline/3`,
`eval/5`, `push_command/3`, `subscribe/2`, `unsubscribe/2`, `noreply_pipeline/3`, `transaction_pipeline/3`,
`stats/1`, `wire_version/0` (`connector.ex:41-138`). **`command/3` (`connector.ex:49`) carries an ARBITRARY
command as `[binary | integer | atom]` parts with a custom `timeout` — the shipped park `BLPOP` rides it
(`consumer.ex:147` = `Connector.command(s.conn, ["BLPOP", wake, secs], s.beat_ms + 2_000)`).** A blocking
`BLMOVE`/`BLMPOP`/`BRPOPLPUSH` would ride the **same** `command/3` verb. **Therefore: BOTH candidate Arm-B
mechanisms ride the existing connector with NO `echo_wire` edit and NO frozen-record change.** The connector is a
serialized FIFO `GenServer` (`send_pipe` enqueues to `pending`, `connector.ex:298`), so a blocking `command/3`
holds the WHOLE connector for the block — but the consumer **already holds a dedicated connector lane** (the
`consumer.ex` moduledoc: "a dedicated connector — blocking verbs get their own lane (Appendix B)"; `start_link`
self-starts one, `consumer.ex:43-51`), so a long block on the consumer's own lane starves no other caller. **The
only wire-level cost is the computed-floor raise** (a blocking command enters the core inventory the P6 probe
records) — **a protocol minor (§12.5), carried by the 2.4.2 → 2.4.3 version step, NOT a wire break.**

## Scope

- **In** — the founded blocking-claim primitive: (1) **the block-and-serve primitive** that subsumes the shipped
  `BLPOP wake` + `drain` two-step, riding `Connector.command/3` (no `echo_wire` edit); (2) **lost-wakeup
  robustness by construction** (a wake is never lost under a concurrent admit-then-park — the load-bearing proof);
  (3) **fair** readiness distribution across parked consumers; (4) the metronome conformance scenario(s) (additive
  minor, the prior **55** byte-unchanged); (5) the `:valkey` + **process** test suites + the **≥100-iteration
  determinism loop** owning the machine (one green run is NOT proof — a lost-wakeup race + a same-millisecond mint
  are cross-run hazards); (6) the version climb **2.4.2 → 2.4.3** (the floor-raise minor + the lockstep fence);
  (7) honest-row reporting (Valkey on 6390 the truth row); **Apollo MANDATORY** (the process/lease surface + the
  floor-raise).
- **Out** — a **new transport / connector verb** (the primitive rides the shipped `Connector.command/3` — INV3;
  no `SSUBSCRIBE`, no facade change, no frozen-record edit); **bypassing `@gclaim`** (a blocking pop NEVER pops the
  lane/ring outside the atomic `@gclaim` — the lease/attempts/`gactive`/ring-rotation bookkeeping stays one Lua
  script, design §12.2; the block precedes the claim, it does not replace it); a **host clock** on any lease the
  primitive touches (server clock only — INV2); the **control plane** (emq.4.1 — SHIPPED); the **group-scoped
  recovery** (emq.4.2 — SHIPPED); the **weighted/deficit rotation** (emq.4.4 — the metronome serves a serviceable
  lane; *which* serviceable lane is served and in what share is the rotation, a separate rung); a **new §6 key
  family** UNLESS the Operator rules one at FORK A-MECH (the default rides the shipped `emq:{q}:wake`); any **edit
  to a shipped lane/job script's logic** beyond the wake-addressing a ruled per-lane readiness LIST requires (the
  byte-freeze discipline holds for the unchanged logic — INV4); any **`echo_wire`/transport** change; any **edit
  to the frozen v1 line**.

## Invariants (the subset emq.4.3 carries, from the family EMQ.4-INV1–8)

- **EMQ.4.3-INV1 (← EMQ.4-INV7) — the metronome is sound (no lost wakeup; fair service).** A parked consumer
  **serves the ready lane within the beat** when a lane becomes serviceable, and a wake is **never lost** under a
  concurrent admit-then-park (a job admitted in the window between a consumer's last claim and its block is still
  served within the beat — and under Arm B that window closes **by construction**, because the block-target IS the
  structure the admit pushes to); when several consumers park, readiness is **distributed fairly** (no consumer
  permanently starved). *Check:* the `:valkey` metronome scenario (admit a job while a consumer is parked → it is
  served before the beat elapses, NOT only on the beat) + a lost-wakeup race scenario (admit exactly at the park
  boundary → still served within the beat) + a multi-consumer fairness scenario (two parked consumers, a stream of
  admits → both make progress, neither starves); the **≥100-iteration determinism loop** owns the proof (the race
  surfaces only across runs).
- **EMQ.4.3-INV2 (← EMQ.4-INV5) — server clock where a lease is touched; `@gclaim` is the claim.** The atomic
  `@gclaim` stays the claim — the lease is `redis.call('TIME')` server-side inside `@gclaim` (`lanes.ex:50-51`),
  attempts the fencing token; the block-and-serve primitive **precedes** the claim and NEVER pops the lane/ring
  outside `@gclaim` (design §12.2 — no second, weaker transition path). The beat/park timing is a host-side
  blocking-command timeout (not a lease). *Check:* a grep of the founded primitive shows the lane pop is inside
  `@gclaim` only (no client-side `ZPOPMIN`/`LMOVE` of the lane/ring); `@gclaim`'s lease is `redis.call('TIME')`;
  no host timestamp computes a lease.
- **EMQ.4.3-INV3 (← EMQ.4-INV1) — the wire law (no new transport, ride the shipped connector; FROZEN-WIRE).** The
  primitive rides the shipped `Connector.command/3` (`BLPOP`/`BLMOVE`/`BLMPOP` carry as parts) + `Connector.eval/5`
  (`@gclaim`) — **no new transport**, **no new connector verb**, **no `echo_wire` edit**, **no frozen-record
  change** (`Connector`/`RESP`/`Script` byte-unchanged), **no `SSUBSCRIBE`**, **no new wire class**. The only
  wire-level change is the **computed-floor raise** (the new blocking command enters the core inventory — a
  protocol minor, §12.5, carried by the version step). The readiness signal stays a §6-grammar key (the shipped
  per-queue `emq:{q}:wake`, or — only if the Operator rules it at FORK A-MECH AND the §6 `type` registry admits it
  — a per-lane `wake:<group>` member, a grammar question surfaced, never assumed). *Check:* a grep of the
  metronome path for a new transport/connector verb returns empty; `echo_wire/lib/` byte-unchanged in the lib
  diff; `{emq}:version` reads `echomq:2.4.3` after connect; the readiness key classifies under the §6 grammar.
- **EMQ.4.3-INV4 (← EMQ.4-INV3) — the shipped surface is byte-unchanged except where the founding names it.** The
  shipped lane/job/recovery scripts' **logic** is byte-unchanged where the rung does not edit it; if a per-lane
  readiness LIST is ruled, the only change to the wake-pushing scripts is the **wake addressing** (the
  `LPUSH`/`LTRIM` target), every other line byte-identical to HEAD (`grep redis.call` on the unchanged logic = 0);
  **`@gclaim` stays byte-unchanged** (the block precedes it, never edits it); the prior fair-lanes conformance
  scenarios pass **byte-unchanged**. *Check:* the byte-freeze grep on the unchanged script logic = 0; `@gclaim`
  byte-identical to HEAD; the prior scenarios git-verified unchanged; the prior 55 byte-unchanged.
- **EMQ.4.3-INV5 (← EMQ.4-INV6) — the additive-minor conformance law.** The metronome scenario(s) are registered
  in `scenarios/0` **with their probes in the same change**; the prior **55** scenarios pass **byte-unchanged**
  (name + contract + verdict body, git-verified); the count re-pins **55 → N** in **both** pinning tests
  (`conformance_scenarios_test.exs` + `conformance_run_test.exs`). *Check:* the git-diff shows only additions to
  `scenarios/0`; both count assertions updated; `Conformance.run/2` prints N lines.

## The rung's fork — Venus surfaces, the Operator (via the Director) rules

> **FORK A is ALREADY RULED (D-1): Arm B — found a new blocking-claim primitive that subsumes the shipped
> wake-token two-step.** What remains is the **mechanism** of that primitive, withheld below. (The seed's Fork A —
> "deepen the shipped metronome (Arm A)" vs "found a new primitive (Arm B)" — is closed; this body is re-derived
> to the ruled Arm B.)

### FORK A-MECH — the blocking-claim mechanism: which primitive subsumes the two-step

> **The reconcile delta carried into the build (the headline fork).** Arm B founds a new blocking-claim primitive.
> The as-built reconcile finds THREE candidate mechanisms, each riding the shipped connector (the FROZEN-WIRE
> VERDICT: NO `echo_wire` edit either way), differing in the **process shape**, the **§6 grammar question**, and
> the **floor-raise**. **The decisive constraint** (design §12.2, `emq.design.md:457-463`): a blocking pop must
> NEVER bypass the atomic `@gclaim` — "a client-side pop would BYPASS the script layer's event and bookkeeping
> path: a second, weaker transition path is the opposite of a wire contract … claim IS `ZPOPMIN` inside the claim
> script." So every mechanism is **block-then-`@gclaim`** (the block is on a *readiness signal*; the claim stays
> the atomic `@gclaim`), never block-and-pop-the-lane. Each arm is stated four-part (Rationale / 5W-in-brief /
> Steelman / Steward+Cost), with its **FROZEN-WIRE verdict + touch-set + §6 question + risk** explicit.
>
> - **MECH-(i) — server-side blocking move on the readiness LIST → `@gclaim` (RECOMMENDED).** The consumer blocks
>   on the shipped `emq:{q}:wake` LIST with a **server-side blocking move** (`BLMOVE wake <sink> LEFT RIGHT <beat>`
>   — atomically pop-and-stash the readiness token, so a crash mid-block does not lose it) instead of `BLPOP wake`,
>   then runs the existing `drain` → `@gclaim`. The wake token's *semantics* change from "a fire-and-forget
>   counter" to "the readiness signal the consumer **block-moves** on"; the lost-wakeup window closes by
>   construction (the admit `LPUSH`es the very LIST the consumer is blocked-moving on — no separate token to miss,
>   and `BLMOVE`'s atomic move means a consumed signal is recoverable, not dropped). *5W-in-brief:* edits
>   `consumer.ex` `park/1` (the `BLPOP` → `BLMOVE`); the wake-push sites are byte-unchanged (still `LPUSH wake` +
>   `LTRIM`) IF the readiness stays the per-queue `wake` (no §6 question); `@gclaim` byte-unchanged. *Steelman:*
>   the smallest founding that genuinely subsumes the two-step — one blocking primitive (`BLMOVE`) replaces the
>   `BLPOP`, the block-target IS the readiness structure, and the atomic claim is untouched (§12.2 honored). It
>   reuses the shipped `emq:{q}:wake` (no new key family, no §6 grammar question) and `@gclaim` (no byte-change to
>   the fairness-critical claim). *Steward + Cost:* **FROZEN-WIRE: rides `Connector.command/3`, NO `echo_wire`
>   edit.** Touch-set: `consumer.ex` (`park/1` → block-move) + `conformance.ex` + `mix.exs` (version) + tests.
>   **§6: NONE** (reuses `emq:{q}:wake`). **Floor-raise: `BLMOVE` is 6.2-level** (within the 7.0 ceiling; the
>   computed floor ≈ 6.2 already names `LMOVE` as the newest — `BLMOVE` is its blocking sibling, a one-command
>   floor-raise, a protocol minor §12.5). **Risk: HIGH** (the process-surface edit on the wake path + the
>   floor-raise; the lost-wakeup race + the mint hazard are cross-run — the ≥100 loop is the proof). A `<sink>`
>   key for the atomic move is a per-consumer scratch LIST — a §6 question IFF it is a new persisted member; the
>   reconcile pins whether the sink rides an existing per-queue member or is a transient the consumer owns (the
>   default: surface it, do not assume).
>
> - **MECH-(ii) — a dedicated metronome process distinct from `EchoMQ.Consumer`.** A NEW supervised process owns
>   the beat/notify and the block, decoupled from the drain; `EchoMQ.Consumer` (or a successor) claims when the
>   metronome signals readiness. *5W-in-brief:* a new module/process (a `GenServer` or `spawn_link` loop) + a
>   rewire of `consumer.ex`'s loop; the block still rides `Connector.command/3` (`BLPOP`/`BLMOVE`); `@gclaim`
>   byte-unchanged. *Steelman:* separates "who owns the beat" from "who drains," which could let many consumers
>   share one metronome's readiness fan-out (a cleaner multi-consumer fairness story). *Steward + Cost:*
>   **FROZEN-WIRE: rides the shipped connector, NO `echo_wire` edit.** Touch-set: a NEW process module +
>   `consumer.ex` rewire + the supervisor + `conformance.ex` + `mix.exs` + tests — **the largest touch-set.** **§6:
>   possibly a fan-out signalling key (a per-consumer or per-lane readiness member — a grammar question).**
>   **Floor-raise: same as the block it uses** (`BLPOP` none / `BLMOVE` 6.2). **Risk: HIGH+** (a new process +
>   a loop rewire is the riskiest slice; it front-loads the hardest surface and it is a re-org of *who* owns the
>   block more than a *new blocking primitive* — the genuinely-new content is thin unless paired with MECH-(i)'s
>   block). *Dis-recommended on its own:* it changes the process topology without, by itself, founding a new
>   blocking primitive; the §12.2 law still forces block-then-`@gclaim`.
>
> - **MECH-(iii) — a per-lane readiness LIST the consumer block-moves on (the per-lane wake answer).** The
>   thundering-herd / cross-lane-wake question (today ONE per-queue `wake` LIST, capped 64, shared by all lanes
>   and consumers) is answered by a **per-lane readiness LIST** (`emq:{q}:wake:<group>` — a new §6 `type` member),
>   each consumer block-moving on the lane(s) it owns. *5W-in-brief:* edits `consumer.ex` (block on the lane
>   signal) + the wake-push sites in `lanes.ex`/`jobs.ex`/`stalled.ex` (the `LPUSH`/`LTRIM` target becomes
>   per-lane — INV4 byte-freezes the rest) + `keyspace.ex` (the new §6 `type` member). *Steelman:* the
>   finest-grained fairness (a lane's readiness wakes exactly the consumer(s) that serve it — no cross-lane
>   thundering herd). *Steward + Cost:* **FROZEN-WIRE: rides `Connector.command/3`, NO `echo_wire` edit.**
>   Touch-set: `consumer.ex` + **the 7 wake-push scripts (re-addressing only — INV4)** + `keyspace.ex` (§6) +
>   `conformance.ex` + `mix.exs` + tests — **a wide touch-set across frozen scripts.** **§6: YES — a new
>   `wake:<group>` member of the CLOSED `type` registry (`keyspace.ex:14`, §6 line 290), a grammar edit the
>   Operator must rule.** **Floor-raise: `BLMOVE` 6.2.** **Risk: HIGH** (the §6 grammar edit + touching all 7
>   frozen wake-push scripts, even if only re-addressing — a wide blast radius on the fairness-critical path).
>   *Steward note:* this is the most complete answer to the shared-`wake` thundering herd but the widest change;
>   it can also LAYER on MECH-(i) later (found the blocking primitive at emq.4.3 on the per-queue wake, make it
>   per-lane at a follow-up) — decoupling the grammar question from the primitive founding.
>
> **Recommendation: MECH-(i)** — a server-side blocking move on the shipped `emq:{q}:wake` LIST feeding the
> atomic `@gclaim`. It is the smallest founding that genuinely **subsumes** the two-step (one blocking primitive,
> the block-target IS the readiness structure, the lost-wakeup window closed by construction), it honors §12.2
> (`@gclaim` stays the atomic claim), it reuses the shipped `wake` (no §6 grammar question), and `@gclaim` and the
> wake-push sites stay byte-unchanged. MECH-(iii)'s per-lane fairness is a real but wider surface (a §6 edit + all
> 7 wake-push scripts) that can **layer on later**; MECH-(ii) is a process re-org that does not, by itself, found
> a new blocking primitive. **This fork settles BEFORE the emq.4.3 build** — it is gate-relevant (HIGH-risk +
> Apollo either way, but the **touch-set, the §6 grammar question, and the floor-raise differ**), and it is **the
> Operator's call**, not Venus's. This body is authored to **MECH-(i)** pending the ruling.

### FORK A-MECH-§6 — the per-lane-wake grammar question (surfaced, NOT decided)

> **A new §6 key member is the Operator's call.** The §6 `suffix := type (CLOSED registry)` (`emq.design.md:290`;
> `keyspace.ex:14` builds it). MECH-(iii) needs a NEW `type` member (`wake:<group>`), which is a **grammar edit**
> — a protocol minor, registered with its conformance probe, the §6 grammar amended. MECH-(i) (recommended) and
> MECH-(ii) ride the shipped `emq:{q}:wake` and need **no §6 edit** (unless MECH-(i)'s atomic-move `<sink>` is
> ruled a new persisted member — the reconcile pins it). **Venus surfaces this; the Operator rules it at the
> mechanism ruling, never assumed.**

## Definition of Done

- [ ] **FORK A** confirmed RULED (Arm B — found a new blocking-claim primitive, D-1) and **FORK A-MECH** settled
      by the Operator (MECH-(i) server-side block-move — recommended — vs MECH-(ii) dedicated process vs MECH-(iii)
      per-lane LIST), recorded **BEFORE** any build artifact (the gate that opens the build; the touch-set, the §6
      grammar question, and the floor-raise depend on it); the body re-derived to the ruled mechanism at the
      pre-build reconcile.
- [ ] **FORK A-MECH-§6** ruled by the Operator IF the chosen mechanism implies a new §6 `type` member (MECH-(iii),
      or MECH-(i)'s `<sink>` if persisted); else recorded "rides the shipped `emq:{q}:wake`, no §6 edit."
- [ ] The **new blocking-claim primitive** built over the shipped `Connector.command/3` + the atomic `@gclaim`,
      subsuming the `BLPOP wake` + `drain` two-step (no wake lost under a concurrent admit-then-park, by
      construction; the block NEVER bypasses `@gclaim` — §12.2).
- [ ] **Fair** readiness distribution across parked consumers built (no consumer permanently starved).
- [ ] *(If MECH-(iii) is ruled)* the per-lane readiness addressing built, with the shipped wake-pushing scripts'
      **logic** byte-unchanged (only the addressing changed — INV4) and the §6 grammar member ruled by the
      Operator; **`@gclaim` byte-unchanged** under every mechanism.
- [ ] The metronome conformance scenario(s) registered (additive minor — the prior **55** byte-unchanged; the
      count re-pinned **55 → N** in both pinning tests).
- [ ] The version climbs **2.4.2 → 2.4.3** in lockstep (the `mix.exs` label AND the `@wire_version`/`{emq}:version`
      fence together — D-3; the fence LOGIC frozen, only the constant moves; the `:fence` scenario version-agnostic),
      covering the computed-floor minor the new blocking command raises (§12.5).
- [ ] The proof: the `:valkey` + **process** metronome suites green per-app; the **≥100-iteration determinism
      loop** green owning the machine (the lost-wakeup race + the mint hazard); the shipped script logic
      byte-unchanged where the rung does not name it + `@gclaim` byte-unchanged (INV4); the **FROZEN-WIRE**
      verdict held (`echo_wire/lib/` byte-unchanged); honest-row reporting (Valkey on 6390); **Apollo MANDATORY** —
      the dedicated evaluator re-ran the whole ladder + the loop independently and re-verified the byte-unchanged
      conformance + the frozen wire; **the Director's verify deepens** (the ≥100 loop).
- [ ] INV1–INV5 verified as runnable checks; the spec body ([`../emq.4.md`](../emq.4.md)) remains authoritative;
      the as-built reconcile syncs this body post-build (the backward reconcile owed — the emq.4.2 F6 lesson).

Family: [`../emq.4.md`](../emq.4.md) (the contract, the carve, the forks — authoritative) · Chapter stories:
[`../emq.4.stories.md`](../emq.4.stories.md) (US3 — the metronome) · Rung stories:
[`./emq.4.3.stories.md`](emq.4.3.stories.md) · Rung runbook: [`./emq.4.3.prompt.md`](emq.4.3.prompt.md) · As-built
floor (the build target — re-probe at the pre-build reconcile; line numbers are hints): `consumer.ex` (the
**shipped park-don't-poll two-step**: `spawn_link` `consumer.ex:40` (NOT a GenServer), `beat_ms` default 1000
`consumer.ex:58`, the loop `reap → promote → drain (rotating claim) → park` `consumer.ex:91-97`, `park/1` =
`Connector.command(conn, ["BLPOP", wake, secs], beat_ms + 2_000)` `consumer.ex:144-149`, the dedicated connector
lane `consumer.ex:43-51`) + `lanes.ex` (the atomic claim `@gclaim` `lanes.ex:37-61` — `LMOVE ring ring LEFT RIGHT`
rotate :38, `ZPOPMIN` the head :41, the **server-clock** `TIME` lease :50-51, attempts the fencing token; the
wake-push in `@genqueue`/`@gresume`/`@glimit`/`@greassign`/`@greap_group` — `LPUSH ... 'wake' '1'` + `LTRIM ... 0
63`, the single per-queue `wake` LIST capped 64) + `jobs.ex` (the wake-push in `@complete:200`/`@retry:277`/
`@promote:336`/`@reap:366`) + `stalled.ex` (the wake-push in `@sweep_stalled:83`) + `keyspace.ex` (the §6 `type`
registry, `queue_key/2:14`) + `conformance.ex` (the **55**-scenario set the additive-minor law grows — re-probe
the live count) + `connector.ex` (the FROZEN wire: `command/3:49` carries blocking commands; `@wire_version
"echomq:2.4.2":35`) · The wire facade (FROZEN): `echo/apps/echo_wire/lib/echo_wire.ex` (`Connector`/`RESP`/`Script`
frozen by committed records, :12-14) · Design: [`../../../emq.design.md`](../../../../emq.design.md) §4 row 4 (the
*park, don't poll* law re-aimed to the fair-lanes rung — the law this rung founds the primitive for), §12.2 (the
one-transition-one-script law — `@gclaim` never bypassed; client-side pops rejected), §12.5 (the engine
floor/ceiling — a computed-floor raise is a protocol minor; `LMOVE` the 6.2-level newest), §5 (no new wire class),
§6 (the CLOSED `type` registry — the per-lane-wake grammar question), §4 (the server-clock law), §11.12 (the
escalation protocol — the reconcile-delta fork) · Roadmap: [`../../../emq.roadmap.md`](../../../../emq.roadmap.md)
(the emq.4 row · Movement II) · Approach:
[`../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
