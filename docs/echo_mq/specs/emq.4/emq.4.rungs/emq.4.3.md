# EMQ.4.3 · The park-don't-poll metronome — the wake/notify beat deepened (Movement II, the groups family)

> **Status: 📐 PROPOSED — the rung's spec body (the seed the full triad grows from at build time).** The THIRD
> sub-rung of the emq.4 "groups deepened" family; the family contract + the carve + the forks are
> [`../emq.4.md`](../emq.4.md) (authoritative — if this carve disagrees with the body, the body wins). emq.4.3
> deepens the **park-don't-poll metronome** — the wake/notify beat by which a consumer PARKS (blocks) and is woken
> on admission/availability instead of busy-polling. **The core mechanism is ALREADY SHIPPED:** `EchoMQ.Consumer`
> (`consumer.ex:144-147`) parks on the `wake` key with `BLPOP` (the beat as the fallback), and every transition
> that makes a lane serviceable (`@genqueue`/`@gclaim`/`@gresume`/`@glimit`/`@reap`/`@complete`/`@retry`/`@promote`)
> pushes a `wake`. So emq.4.3 does **not** found the mechanism — it **deepens** its robustness and fairness (no
> lost wakeup under a concurrent admit-then-park; fair wakes across parked consumers; possibly a **per-lane** wake,
> since today a **single** per-queue `wake` LIST capped at 64 is shared by all lanes and all parked consumers).
> **Risk: HIGH** — the deepening founds/reshapes a **process/lease surface** on the fairness-critical wake path; a
> **lost-wakeup race** and a same-millisecond branded-id mint are **cross-run** hazards one green run cannot
> surface. **Apollo MANDATORY at build; the ≥100-iteration determinism loop owns the proof; the Director's verify
> deepens.** emq.4.3 builds **only after the Operator rules Fork A** (deepen the shipped metronome — Arm A,
> recommended — vs found a new blocking-claim primitive — Arm B; the touch-set depends on the ruling). The v2
> master invariant binds (server clock where a lease is touched · no wire break). Forward-tense: every emq.4.3
> surface is PROPOSED, NOT shipped.

## 0 · The slice — what emq.4.3 deepens, and the reconcile delta it carries

The family ([`../emq.4.md`](../emq.4.md)) deepens the shipped fair-lanes mechanism. emq.4.3 carves the
**metronome**. The foundation proved the *mechanism* — park on `BLPOP wake`, the beat as a fallback, a wake pushed
by every serviceable transition — on the happy path. emq.4.3 takes it to the **robustness and fairness** a
multi-tenant production bus needs: a wake must **never be lost** when work arrives exactly as a consumer parks, and
when several consumers park on one queue the wakes must be **distributed fairly** (no consumer starved). The open
structural question is the **single per-queue `wake` LIST**: today it is one key (`emq:{q}:wake`, capped 64,
`LTRIM 0 63`) shared by all lanes and all parked consumers, so a wake intended for one lane wakes whatever consumer
`BLPOP`s first — a thundering-herd / cross-lane-wake question a per-lane wake would answer. **This is a reconcile
delta against the chapter's ruled spine** (which grades emq.4.3 "founds a process/lease surface"): the core IS
shipped, so what the HIGH-risk grade attaches to is the **deepening's** new surface — surfaced as **Fork A** below,
the Operator's call before the build.

## Goal

emq.4.3 deepens, inside `echo/apps/echo_mq`, the **park-don't-poll metronome** over the shipped `EchoMQ.Consumer`
park loop and the shipped `wake` protocol so that: (a) a parked consumer (`BLPOP emq:{q}:wake <beat>`, the beat the
fallback) is woken **within the beat** when its lane becomes serviceable, with **no lost wakeup** under a concurrent
admit-then-park (the load-bearing metronome proof); (b) when several consumers park on one queue, wakes are
**distributed fairly** across them (no permanent starvation of a parked consumer); (c) *(Fork A Arm A — recommended)*
the wake protocol is hardened (and, if ruled, made **per-lane**) without busy-polling and without a new transport —
the family rides the shipped connector. Any lease the deepening touches reads `TIME` **server-side** (the as-built
pattern). The deepening does **not** break the wire (no new key family beyond a possible per-lane `wake:<group>`
member of the §6 grammar — re-probe the grammar at the reconcile; if a per-lane wake needs a new §6 member, that is
a grammar question surfaced to the Operator, NOT assumed). emq.4.3 builds only after **Fork A** is ruled.

## Rationale (5W)

- **Why** — the metronome is the surface that makes the bus **cheap at rest and prompt under load**: a parked
  consumer costs the wire nothing, and a ready job is served within the beat. The foundation proved the mechanism;
  emq.4.3 hardens it for production — a **lost wakeup** (work admitted in the window between a consumer's last claim
  and its `BLPOP`) would hang a ready job until the next beat, and an **unfair** wake distribution would starve a
  parked consumer. These are the robustness properties a multi-tenant bus needs and the foundation did not gate at
  this depth.
- **What** — emq.4.3 builds (forward-named; the deepened surface — re-probe the shipped `Consumer`/`wake` at the
  pre-build reconcile): (1) the **lost-wakeup-robust** park/wake protocol over the shipped `BLPOP wake` (the
  precise mechanism — a recheck-after-park, an atomic claim-or-park, or a per-lane wake — is **WITHHELD** and pinned
  at the reconcile + the ruled Fork A arm); (2) **fair** wake distribution across parked consumers; (3) *(if Fork A
  Arm A rules per-lane)* a per-lane wake addressing; (4) the conformance scenario(s) for the metronome (admit while
  parked → wake before the beat; no lost wakeup) (additive minor, the prior 52 byte-unchanged); (5) the `:valkey` +
  **process** test suites + the **≥100-iteration determinism loop** owning the machine.
- **Who** — the program (the rung that hardens the metronome); the bus's **consumers**, who gain lost-wakeup-free,
  fairly-woken parking; **Apollo**, who re-runs the gate ladder + the ≥100 loop independently (**MANDATORY** — the
  rung founds/reshapes a process/lease surface on the fairness-critical wake path). The shipped `EchoMQ.Consumer`
  loop + the wake protocol are the proven precedent it deepens.
- **When** — Movement II, the groups family's **third** sub-rung, after emq.4.1 (control plane) and emq.4.2
  (recovery). SPECCED this design cycle as a seed; **built only after the Operator rules Fork A** (deepen vs found —
  the touch-set depends on it; the recommended arm is "deepen," which this seed is authored to). The full triad +
  the build follow one increment per run.
- **Where** — `echo/apps/echo_mq` only: `consumer.ex` (EDIT — the deepened park/wake loop — **the HIGH-RISK
  process-surface edit; Apollo MANDATORY**), and the wake-push sites in `lanes.ex` / `jobs.ex` **only if** a
  per-lane wake is ruled (re-probe — a per-lane wake would touch the shipped scripts that push `wake`, re-grading
  those edits under byte-freeze of the unchanged logic), `conformance.ex` (EDIT — the metronome scenario(s) + the
  count re-pin), `test/*_test.exs` (NEW/EDIT — the `:valkey` + process metronome proof), the two pinning tests
  (EDIT — the count). `echo_wire` is **untouched** (the metronome rides the shipped connector `BLPOP`/`eval` — no
  new transport, no new connector verb; INV3). `apps/echomq` is **untouched** (the capability reference). Whether
  the §6 grammar in `keyspace.ex` gains a per-lane `wake:<group>` member is a **grammar question** ruled at the
  reconcile, NOT assumed (the default is the shipped single per-queue `wake`). Exact line anchors pinned at the
  pre-build reconcile.

## Scope

- **In** — the deepened metronome: (1) **lost-wakeup robustness** (a wake is never lost under a concurrent
  admit-then-park — the load-bearing proof); (2) **fair** wake distribution across parked consumers; (3) the
  metronome conformance scenario(s) (additive minor, the prior 52 byte-unchanged); (4) the `:valkey` + **process**
  test suites + the **≥100-iteration determinism loop** owning the machine (one green run is NOT proof — a
  lost-wakeup race + a same-millisecond mint are cross-run hazards); (5) honest-row reporting (Valkey on 6390 the
  truth row); **Apollo MANDATORY** (the process/lease surface).
- **Out** — a **new transport** (the metronome rides the shipped connector `BLPOP`/`eval` — INV3; no `SSUBSCRIBE`,
  no new connector verb); a **host clock** on any lease the deepening touches (server clock only — INV2); the
  **control plane** (emq.4.1); the **group-scoped recovery** (emq.4.2); the **weighted/deficit rotation** (emq.4.4 —
  the metronome wakes a serviceable lane; *which* serviceable lane is served and in what share is the rotation, a
  separate rung); a **per-lane wake** UNLESS Fork A Arm A rules it in (the default is the shipped single per-queue
  `wake`); any **edit to a shipped lane/job script's logic** beyond the wake-addressing a ruled per-lane wake
  requires (the byte-freeze discipline holds for the unchanged logic — INV4); any **`echo_wire`/transport** change;
  any **edit to the frozen v1 line**.

## Invariants (the subset emq.4.3 carries, from the family EMQ.4-INV1–8)

- **EMQ.4.3-INV1 (← EMQ.4-INV7) — the metronome is sound (no lost wakeup; fair wakes).** A parked consumer is woken
  **within the beat** when its lane becomes serviceable, and a wake is **never lost** under a concurrent
  admit-then-park (a job admitted in the window between a consumer's last claim and its `BLPOP` is still served
  within the beat); when several consumers park, wakes are **distributed fairly** (no consumer permanently starved).
  *Check:* the `:valkey` metronome scenario (admit a job while a consumer is parked → it is served before the beat
  elapses, NOT only on the beat) + a lost-wakeup race scenario (admit exactly at the park boundary → still served);
  the **≥100-iteration determinism loop** owns the proof (the race surfaces only across runs).
- **EMQ.4.3-INV2 (← EMQ.4-INV5) — server clock where a lease is touched.** Any lease the deepened metronome touches
  reads `TIME` **server-side** inside the script (the as-built `@gclaim` lease pattern); the beat/park timing is a
  host-side `BLPOP` timeout (not a lease), but no **lease** is computed from a host clock. *Check:* a grep of any
  new lease-touching script for a host-supplied timestamp returns empty.
- **EMQ.4.3-INV3 (← EMQ.4-INV1) — the wire law (no new transport, ride the shipped connector).** The metronome
  rides the shipped connector `BLPOP`/`eval` — **no new transport**, **no `SSUBSCRIBE`**, **no new connector verb**,
  **no new wire class**; the wake stays a §6-grammar key (the shipped per-queue `emq:{q}:wake`, or — only if Fork A
  Arm A rules it AND the grammar admits it — a per-lane `wake:<group>` member, a grammar question surfaced to the
  Operator, never assumed). *Check:* a grep of the metronome path for a new transport/connector verb returns empty;
  `{emq}:version` reads `echomq:2.0.0`; the wake key classifies under the §6 grammar.
- **EMQ.4.3-INV4 (← EMQ.4-INV3) — the shipped surface is byte-unchanged except where the deepening names it.** The
  shipped lane/job scripts' **logic** is byte-unchanged; if a per-lane wake is ruled, the only change to the
  wake-pushing scripts is the **wake addressing** (the `LPUSH`/`LTRIM` target), every other line byte-identical to
  HEAD (`grep redis.call` on the unchanged logic = 0); the prior fair-lanes conformance scenarios pass
  **byte-unchanged**. *Check:* the byte-freeze grep on the unchanged script logic = 0; the prior scenarios
  git-verified unchanged; the prior 52 byte-unchanged.
- **EMQ.4.3-INV5 (← EMQ.4-INV6) — the additive-minor conformance law.** The metronome scenario(s) are registered in
  `scenarios/0` **with their probes in the same change**; the prior **52** scenarios pass **byte-unchanged**; the
  count re-pins **52 → N** in **both** pinning tests. *Check:* the git-diff shows only additions to `scenarios/0`;
  both count assertions updated; `Conformance.run/2` prints N lines.

## The rung's fork — Venus surfaces, the Operator (via the Director) rules

### FORK A — the metronome boundary: deepen the shipped metronome vs found a new blocking-claim primitive

> **The reconcile delta (the headline fork).** The chapter's ruled spine grades emq.4.3 as **founding** a
> process/lease surface (HIGH-risk). The as-built reconcile finds the **park-don't-poll core already shipped** —
> `EchoMQ.Consumer` parks on `BLPOP emq:{q}:wake` (`consumer.ex:144-147`, the beat the fallback) and is woken by the
> wake-push baked into every serviceable transition (`@genqueue`/`@gclaim`/`@gresume`/`@glimit`/`@reap`/`@complete`/
> `@retry`/`@promote`). So emq.4.3 does **not** found the mechanism; it **deepens** it. What, exactly, is the new
> process/lease surface the HIGH-risk grade attaches to?
> - **Arm A — emq.4.3 hardens the shipped metronome (RECOMMENDED).** The deepening is **lost-wakeup robustness** +
>   **multi-consumer wake fairness** + possibly a **per-lane wake** (today a **single** per-queue `wake` LIST,
>   capped 64, is shared by all lanes and all parked consumers — a thundering-herd / cross-lane-wake question a
>   per-lane wake would answer). The new surface is the hardened wake protocol and any process change it implies.
>   HIGH-risk **stands** because a lost-wakeup race and a same-millisecond mint are **cross-run** hazards (the ≥100
>   loop is the proof), and the wake path is fairness-critical. *Steelman:* the shipped park loop is the
>   foundation; deepening its robustness/fairness is the smallest, most-grounded slice; per-lane wake is the natural
>   answer to the shared-`wake` thundering herd; the consistency model is the shipped at-least-once. *Cost:* a
>   per-lane wake (if ruled) touches the shipped wake-pushing scripts' addressing (INV4 byte-freezes the rest), and
>   a new §6 `wake:<group>` member is a grammar question.
> - **Arm B — emq.4.3 founds a genuinely new blocking-claim primitive.** If the Operator intends a **new** primitive
>   — e.g. a server-side blocking grouped claim beyond `BLPOP wake`, or a **dedicated metronome process** distinct
>   from `EchoMQ.Consumer` — that is a larger founding and a **different touch-set** (a new module/process, possibly
>   a new connector verb). *Steelman:* a purpose-built blocking-claim primitive could give tighter latency and
>   per-lane fairness natively. *Cost:* a new process/primitive is the largest, riskiest slice; it may pull a new
>   connector verb (an `echo_wire` seam — out of the family's "ride the shipped connector" grain); it front-loads
>   the hardest surface onto a rung whose core is already shipped.
>
> **Recommendation: Arm A** — the as-built park loop is the foundation; emq.4.3 deepens its robustness and fairness
> (and, if ruled, makes the wake per-lane). This seed is authored to **Arm A**. An Arm-B ruling re-scopes emq.4.3
> to a new primitive (and possibly an `echo_wire` seam) **before** its build. **This fork settles before the
> emq.4.3 build** — it is gate-relevant (HIGH-risk + Apollo either way, but the **touch-set differs**), and it is
> **the Operator's call**, not Venus's.

## Definition of Done

- [ ] **Fork A** settled by the Operator (deepen — Arm A, recommended — vs found a new primitive — Arm B), recorded
      **BEFORE** any build artifact (the gate that opens the build; the touch-set depends on it); the seed
      re-derived to the ruled arm at the pre-build reconcile.
- [ ] The **lost-wakeup-robust** park/wake protocol built over the shipped `BLPOP wake` (no wake lost under a
      concurrent admit-then-park).
- [ ] **Fair** wake distribution across parked consumers built (no consumer permanently starved).
- [ ] *(If Fork A Arm A rules per-lane)* the per-lane wake addressing built, with the shipped wake-pushing scripts'
      **logic** byte-unchanged (only the addressing changed — INV4) and any §6 grammar question ruled by the
      Operator.
- [ ] The metronome conformance scenario(s) registered (additive minor — the prior **52** byte-unchanged; the count
      re-pinned **52 → N** in both pinning tests).
- [ ] The proof: the `:valkey` + **process** metronome suites green per-app; the **≥100-iteration determinism
      loop** green owning the machine (the lost-wakeup race + the mint hazard); the shipped script logic
      byte-unchanged where the rung does not name it (INV4); honest-row reporting (Valkey on 6390); **Apollo
      MANDATORY** — the dedicated evaluator re-ran the whole ladder + the loop independently and re-verified the
      byte-unchanged conformance; **the Director's verify deepens** (the ≥100 loop).
- [ ] INV1–INV5 verified as runnable checks; the spec body ([`../emq.4.md`](../emq.4.md)) remains authoritative; the
      as-built reconcile syncs this seed post-build.

Family: [`../emq.4.md`](../emq.4.md) (the contract, the carve, the forks — authoritative) · Chapter stories:
[`../emq.4.stories.md`](../emq.4.stories.md) (US3 — the metronome) · Chapter brief:
[`../emq.4.llms.md`](../emq.4.llms.md) (R3, AS3) · As-built floor (the build target — re-probe at the pre-build
reconcile; line numbers are hints): `echo/apps/echo_mq/lib/echo_mq/consumer.ex` (the **shipped park-don't-poll
loop**: `spawn_link` `consumer.ex:40` (NOT a GenServer), `beat_ms` default 1000 `consumer.ex:58`, the loop
`reap → promote → drain (rotating claim) → park` `consumer.ex:91-97`, `park/1` = `BLPOP emq:{q}:wake <beat>`
`consumer.ex:144-147`) + `echo/apps/echo_mq/lib/echo_mq/lanes.ex` (the wake-push in `@genqueue`/`@gclaim`/`@gresume`/
`@glimit` — `LPUSH ... 'wake' '1'` + `LTRIM ... 0 63`, the single per-queue `wake` LIST capped 64) +
`echo/apps/echo_mq/lib/echo_mq/jobs.ex` (the wake-push in `@reap`/`@complete`/`@retry`/`@promote`) +
`conformance.ex` (the **52**-scenario set the additive-minor law grows — re-probe the live count) · Design:
[`../../../emq.design.md`](../../../emq.design.md) §4 row 4 (the *park, don't poll* law re-aimed to the fair-lanes
rung — the law this rung deepens), §10 seam 2 / §4 cluster 2 (the displaced groups family RULED → emq.4), §5 (no new
wire class), §4 (the server-clock law), §11.12 (the escalation protocol — the reconcile-delta fork) · Roadmap:
[`../../../emq.roadmap.md`](../../../emq.roadmap.md) (the emq.4 row · Movement II) · Approach:
[`../../../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
