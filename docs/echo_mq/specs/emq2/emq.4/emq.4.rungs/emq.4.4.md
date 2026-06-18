# EMQ.4.4 · Weighted/deficit rotation + the starvation drill — fair-share beyond round-robin (Movement II, the groups family, the capstone)

> **Status: 📐 PROPOSED — the rung's spec body (the seed the full triad grows from at build time).** The FOURTH and
> **CAPSTONE** sub-rung of the emq.4 "groups deepened" family; the family contract + the carve + the forks are
> [`../emq.4.md`](../emq.4.md) (authoritative — if this carve disagrees with the body, the body wins). emq.4.4
> deepens the **rotation** itself: today the ring serves lanes in **strict round-robin** (every claim rotates the
> ring one step — `@gclaim`'s `LMOVE KEYS[1] KEYS[1] LEFT RIGHT` then `ZPOPMIN` the head, `lanes.ex:38,41`),
> equal-share by construction. emq.4.4 adds **fair-share BEYOND round-robin** — weighted / deficit round-robin over
> the ring so a higher-weight lane is served proportionally more — plus the **starvation drill**, a proof that **no
> lane starves under skew** (the capstone guarantee). **Risk: HIGH iff it edits the shipped `@gclaim` ring
> rotation** — then the **byte-freeze discipline** holds for **every OTHER** `@g*` script (`@genqueue`/`@gpause`/
> `@gresume`/`@glimit` byte-identical to HEAD) and **Apollo is MANDATORY** (a shipped-script edit on the
> fairness-critical claim path); if the weighting can land **additively** (a separate weighted-claim path leaving
> `@gclaim` byte-unchanged), the rung re-grades to NORMAL+. Which of the two is the **weighted-rotation mechanism
> fork** (Fork B) — the Operator's call at the pre-build reconcile. The v2 master invariant binds (server clock
> where a lease is touched · declared keys · no new key family · no wire break). Forward-tense: every emq.4.4
> surface is PROPOSED, NOT shipped.

## 0 · The slice — what emq.4.4 deepens, and why the capstone

The family ([`../emq.4.md`](../emq.4.md)) deepens the shipped fair-lanes mechanism. emq.4.4 carves the **rotation**.
The foundation proved **equal** fairness — the ring rotates one step per claim, so every serviceable lane gets an
equal turn (constructed, not hashed — design D-9). emq.4.4 takes fairness to **proportional**: a lane can carry a
**weight**, and the rotation serves lanes **in proportion to weight** (weighted / deficit round-robin), while the
**starvation drill** proves the strong guarantee a proportional scheme must keep — **no lane starves under skew**
(a heavy lane cannot monopolize the machine; a quiet lane is still served). It is the **capstone** because it is the
highest-risk axis (it may re-shape the shipped `@gclaim` ring rotation, the fairness-critical claim path) and it
builds on the whole chapter — the control plane (emq.4.1) shapes the lanes, recovery (emq.4.2) keeps them whole, the
metronome (emq.4.3) wakes them, and emq.4.4 decides **which serviceable lane is served, and in what share**.

## Goal

emq.4.4 builds, inside `echo/apps/echo_mq`, **weighted / deficit round-robin** over the ring plus the **starvation
drill**: (a) a lane carries a **weight** *(the weight's home — a `gweight` HASH field beside the shipped `glimit`/
`gactive` HASHes, or the ruled Fork-B representation — is pinned at the reconcile; **no new key FAMILY**, INV1)*, and
the claim rotation serves lanes **in proportion to weight** (a higher-weight lane gets proportionally more serves,
never all of them); (b) the **starvation drill** — a `:valkey` scenario that floods one lane and trickles the others
and proves **every** lane's depth reaches zero over the drill window (no lane starved); (c) the weighting is realized
either **additively** (a separate weighted-claim path, `@gclaim` byte-unchanged) **or** by **editing `@gclaim`**
under the byte-freeze discipline (every OTHER `@g*` script byte-identical to HEAD) — the **ruled Fork-B mechanism**
— all under the A-1 declared-keys law, branded group ids gated at the lane-key builder, the **server clock** on any
lease (the shipped `@gclaim` lease pattern), and additive-minor conformance growth.

## Rationale (5W)

- **Why** — equal round-robin is fair only when lanes deserve equal share; a multi-tenant bus needs **proportional**
  fairness (a premium tenant served more, a background tenant served less) **without** a numeric per-job priority
  (retired by design) and **without** starving any lane. Weighted/deficit round-robin is the textbook answer
  (fair-share scheduling), and the **starvation drill** is the proof the scheme keeps its strong guarantee under the
  adversarial case (sustained skew). It is the capstone because it completes the fairness story the family opened
  (equal lanes → proportional lanes, starvation-proof) and carries the chapter's highest risk (the shipped
  claim-path edit).
- **What** — emq.4.4 builds (forward-named; the weighted rotation does not yet exist — re-probe the shipped
  `@gclaim` at the pre-build reconcile, the emq.4.1–4.3 builds will have moved the surface): (1) the lane **weight**
  representation *(WITHHELD — pinned at the reconcile per the ruled Fork B; a `gweight` HASH field is the candidate,
  no new key family)*; (2) the **weighted/deficit** rotation (the ruled Fork-B mechanism — deficit counter on the
  ring, weighted multi-pop, or a per-lane budget); (3) the **starvation drill** scenario + the weighted-proportion
  scenario (additive minor, the prior 52 byte-unchanged); (4) the `:valkey` + (if a process/lease surface) the
  determinism suites + the byte-freeze grep on the unedited `@g*` scripts.
- **Who** — the program (the rung that completes the groups fairness story); multi-tenant **operators**, who gain
  proportional fair-share with a starvation guarantee; **Apollo**, who re-runs the gate ladder independently
  (**MANDATORY** if `@gclaim` is edited — a shipped-script edit on the fairness-critical claim path); the
  conformance harness, which grows by the weighted-proportion + starvation-drill scenarios. The shipped `@gclaim`
  ring rotation is the precedent it deepens.
- **When** — Movement II, the groups family's **fourth and capstone** sub-rung, **last** (it builds on emq.4.1–4.3).
  SPECCED this design cycle as a seed; **Fork B** (the weighted mechanism — below) is surfaced at the pre-build
  reconcile with the shipped `@gclaim` re-probed; the ruled mechanism decides whether `@gclaim` is edited (HIGH) or
  the weighting lands additively (NORMAL+). The full triad + the build follow one increment per run.
- **Where** — `echo/apps/echo_mq` only: `lanes.ex` (EDIT — the weighted rotation; **the `@gclaim` edit is
  fork-gated** — if Fork B rules an edit, `@gclaim` is the target and **every OTHER `@g*` is byte-frozen**; if Fork
  B rules additive, a **new** weighted-claim script + `@gclaim` byte-unchanged — re-probe), `conformance.ex` (EDIT —
  the weighted-proportion + starvation-drill scenarios + the count re-pin), `test/*_test.exs` (NEW/EDIT — the
  `:valkey` weighted + drill proof), the two pinning tests (EDIT — the count). `echo_wire` is **untouched** (the
  rotation rides the shipped connector `eval`). `apps/echomq` is **untouched** (the capability reference). The §6
  grammar in `keyspace.ex` is **unedited** (no new key family — the weight rides an existing key shape). Exact line
  anchors pinned at the pre-build reconcile.

## Scope

- **In** — weighted/deficit rotation + the drill: (1) the lane **weight** representation (no new key family — the
  ruled Fork-B home); (2) the **weighted / deficit** rotation over the ring (lanes served in proportion to weight);
  (3) the **starvation drill** (a skewed-load scenario proving every lane drains) + the weighted-proportion
  scenario; (4) the conformance scenarios (additive minor, the prior 52 byte-unchanged); (5) the `:valkey` suites +
  (if the rotation becomes a process/lease surface) the **≥100-iteration determinism loop**, else a multi-seed
  sweep + an honest determinism-posture statement; (6) the **byte-freeze grep** on every unedited `@g*` script (= 0
  for `grep redis.call`).
- **Out** — any **numeric per-job priority** (retired by design — weight is **per-lane**, not per-job; INV1); any
  **new lane key family** (the weight rides an existing key shape; the rotation rides the shipped `g:`-segment keys
  + the ring — INV1); a **starvation-by-design exemption** (a lane MUST NOT be starvable — that is the drill's
  guarantee; a weight of zero that parks a lane is the operator's explicit pause via emq.4.1, not a rotation
  outcome); the **control plane** (emq.4.1); the **group-scoped recovery** (emq.4.2); the **metronome** (emq.4.3 —
  the metronome wakes a serviceable lane; emq.4.4 decides which lane is served and in what share); any **edit to a
  shipped `@g*` script except the one Fork B names** (every other `@g*` byte-frozen — INV3); any
  **`echo_wire`/transport** change; any **edit to the frozen v1 line**.

## Invariants (the subset emq.4.4 carries, from the family EMQ.4-INV1–8)

- **EMQ.4.4-INV1 (← EMQ.4-INV7) — fairness is sound (proportional, and starvation-free).** Lanes are served **in
  proportion to weight** (a higher-weight lane gets proportionally more serves, never all of them); under sustained
  skew **every** lane's depth reaches zero (the starvation drill — no lane starved). *Check:* the
  weighted-proportion `:valkey` scenario (two lanes, weights 3:1 → serves approximate 3:1 over a window); the
  **starvation-drill** scenario (one lane flooded, others trickling → every lane's depth reaches zero over the
  window); the determinism loop green if the rotation is a process/lease surface.
- **EMQ.4.4-INV2 (← EMQ.4-INV3) — the byte-freeze discipline (every unedited `@g*` is byte-unchanged).** emq.4.4
  edits **at most one** shipped lane script (`@gclaim`, and only if Fork B rules an edit); **every OTHER** `@g*`
  script — `@genqueue`, `@gpause`, `@gresume`, `@glimit` — is **byte-identical to HEAD** (`grep redis.call` on those
  scripts in the lib diff = 0); if Fork B rules **additive**, `@gclaim` itself is byte-unchanged too (the weighting
  is a new script). The prior fair-lanes conformance scenarios (`rotate`, `pause`, `limit`, `lane_depth`,
  `stalled_group`) pass **byte-unchanged**. *Check:* the byte-freeze grep on the unedited `@g*` scripts = 0; the
  prior scenarios git-verified unchanged; the prior 52 byte-unchanged.
- **EMQ.4.4-INV3 (← EMQ.4-INV1) — the wire law (no new key family, no numeric priority).** The weight rides an
  **existing key shape** (a `gweight` HASH field beside `glimit`/`gactive`, or the ruled representation — **no new
  key FAMILY**); the rotation rides the shipped `emq:{q}:g:<group>:pending` / `ring` keys; **no numeric per-job
  priority** (weight is per-lane); **no new wire class**, **no new transport**. *Check:* a grep of the new/edited
  rotation for a lane key not in the shipped family returns empty; a grep for a numeric-priority score / a
  `prioritized` key returns empty; `{emq}:version` reads `echomq:2.0.0`; the §6 grammar is unedited.
- **EMQ.4.4-INV4 (← EMQ.4-INV5) — server clock where the lease is touched.** The weighted claim reads `TIME`
  **server-side** inside the script to lease the served job (the shipped `@gclaim` `redis.call('TIME')` lease
  pattern, `lanes.ex:50-52`); no host clock crosses the lease. *Check:* a grep of the weighted-claim script for a
  host-supplied lease timestamp returns empty; the lease is computed from `redis.call('TIME')`.
- **EMQ.4.4-INV5 (← EMQ.4-INV4) — branded group identity at the weight + claim boundaries.** A weight is set on a
  **valid branded group** (gated `EchoData.BrandedId.valid?/1` at the lane-key builder before any wire); the
  weighted claim serves a member of a branded-gated lane. *Check:* an ill-formed group raises before the wire when
  a weight is set; the weighted-claim scenario uses branded groups.
- **EMQ.4.4-INV6 (← EMQ.4-INV6) — the additive-minor conformance law.** The weighted-proportion + starvation-drill
  scenarios are registered in `scenarios/0` **with their probes in the same change**; the prior **52** scenarios
  pass **byte-unchanged**; the count re-pins **52 → N** in **both** pinning tests. *Check:* the git-diff shows only
  additions to `scenarios/0`; both count assertions updated; `Conformance.run/2` prints N lines.

## The rung's fork — Venus surfaces, the Operator (via the Director) rules

### FORK B — the weighted-rotation mechanism: a ring deficit counter vs a weighted multi-pop vs a per-lane budget

> **The fairness representation, which decides the risk grade.** Weighted/deficit rotation over the ring can be
> realized three ways, and the choice decides whether the shipped `@gclaim` is **edited** (HIGH-risk → byte-freeze
> every OTHER `@g*` + Apollo) or a **separate** weighted-claim path is added (`@gclaim` byte-unchanged → NORMAL+):
> - **Arm 1 — a deficit counter on the ring (DRR — Deficit Round Robin).** Each lane carries a **deficit** credited
>   per rotation and consumed per serve; a lane serves while it has credit, else it is skipped and re-credited next
>   round. *Steelman:* the textbook deficit-round-robin — **bounded, fair, starvation-free by construction** (every
>   lane is credited every round, so none can be starved); smooth proportional share at fine granularity. *Cost:* a
>   new per-lane deficit counter (a HASH field — rides an existing key shape, no new family) **and an edit to the
>   `@gclaim` rotation** (HIGH-risk → byte-freeze every OTHER `@g*` + Apollo MANDATORY).
> - **Arm 2 — a weighted multi-pop.** A higher-weight lane serves **K heads per rotation** (K = the lane's weight).
>   *Steelman:* **additive** — a separate weighted-claim path can leave `@gclaim` **byte-unchanged** (NORMAL+); the
>   weight is read, K members popped, the ring rotated once. *Cost:* weight granularity is **integer multiples**
>   (less smooth than DRR); a burst of K serves to one lane is less even than DRR's interleaving.
> - **Arm 3 — a per-lane budget refreshed by the metronome.** The beat (emq.4.3) refreshes a per-lane **serve
>   budget**; a lane serves while it has budget. *Steelman:* couples cleanly to emq.4.3's metronome (the beat is
>   already the cadence). *Cost:* the fairness is only as fine as the **beat** (coarse if the beat is 1s); it
>   **couples two rungs** (emq.4.4 depends on emq.4.3's metronome shape), and the budget refresh is a process/lease
>   surface (the ≥100 loop).
>
> **Recommendation: surface all three at emq.4.4's pre-build reconcile** with the shipped `@gclaim` **re-probed**
> (the emq.4.1–4.3 builds will have moved the surface). The trade-off is explicit — **the `@gclaim` edit decides
> the risk grade** (Arm 1 edits it → HIGH + Apollo; Arm 2 is additive → NORMAL+; Arm 3 is additive but couples to
> emq.4.3). **No new key family any arm** (every arm rides an existing key shape — INV3). This seed is authored to
> keep both shapes open (the weight representation + the rotation are WITHHELD until the ruling); **the Operator
> rules the mechanism**, not Venus.

## Definition of Done

- [ ] **Fork B** surfaced to the Director with all three arms + costs + the `@gclaim`-edit risk trade-off, the
      shipped `@gclaim` re-probed; the Operator's mechanism ruling recorded; the seed re-derived to the ruled arm at
      the pre-build reconcile (the weight representation + the rotation pinned).
- [ ] The lane **weight** representation built (no new key family — the ruled Fork-B home).
- [ ] The **weighted / deficit** rotation built (lanes served in proportion to weight) — additively (`@gclaim`
      byte-unchanged) or by editing `@gclaim` under byte-freeze of every OTHER `@g*` (the ruled mechanism).
- [ ] The **starvation drill** + the weighted-proportion conformance scenarios registered (additive minor — the
      prior **52** byte-unchanged; the count re-pinned **52 → N** in both pinning tests); the drill proves every lane
      drains under skew.
- [ ] The proof: the `:valkey` weighted + drill suites green per-app; the **≥100 determinism loop** if the rotation
      is a process/lease surface, else a multi-seed sweep + an honest determinism-posture statement; the byte-freeze
      grep on every unedited `@g*` = 0 (INV2); honest-row reporting (Valkey on 6390); **Apollo MANDATORY** if
      `@gclaim` is edited (the dedicated evaluator re-ran the ladder + re-verified the byte-frozen scripts).
- [ ] INV1–INV6 verified as runnable checks; the spec body ([`../emq.4.md`](../emq.4.md)) remains authoritative; the
      as-built reconcile syncs this seed post-build.

Family: [`../emq.4.md`](../emq.4.md) (the contract, the carve, the forks — authoritative) · Chapter stories:
[`../emq.4.stories.md`](../emq.4.stories.md) (US4 — weighted/deficit + the drill) · As-built floor (the build target — re-probe at the pre-build
reconcile; line numbers are hints): `echo/apps/echo_mq/lib/echo_mq/lanes.ex` (`@gclaim` — the **shipped ring
rotation** the weighting deepens: `LMOVE KEYS[1] KEYS[1] 'LEFT' 'RIGHT'` `lanes.ex:38` (the rota step), `ZPOPMIN`
the lane head `lanes.ex:41`, the **server-clock lease** `redis.call('TIME')` `lanes.ex:50-52`, the `gactive`
`HINCRBY` + `glimit` re-ring guard `lanes.ex:53-59`; the `glimit` / `gactive` HASHes beside which a `gweight` field
would ride; `claim/3` the host verb; the `g:<group>:pending` / `ring` keyspace) + the OTHER `@g*` scripts to
**byte-freeze** (`@genqueue`/`@gpause`/`@gresume`/`@glimit`) + `conformance.ex` (the **52**-scenario set the
additive-minor law grows — the `rotate` scenario "two lanes claim in strict rotation — the ring is the rota" is the
equal-share precedent; re-probe the live count) · The v1 capability reference (the re-aim record, READ-ONLY — the
form NOT to lift): [`../../emq.commands/features/groups/changePriority-7.md`](../../../emq.commands/features/groups/changePriority-7.md)
(RETIRED → "weighted rotation, emq.4" — the canon names this rung) · Design:
[`../../../emq.design.md`](../../../../emq.design.md) §10 seam 2 / §4 cluster 2 (the displaced groups family RULED →
emq.4), §4 (the server-clock law — the lease in the rotation), S-6 (the declared-keys A-1 law), S-1/§6 (the braced
keyspace) · Roadmap: [`../../../emq.roadmap.md`](../../../../emq.roadmap.md) (the emq.4 row · Movement II) · Approach:
[`../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
