# EMQ.4.4 · Weighted/deficit rotation + the starvation drill — fair-share beyond round-robin (Movement II, the groups family, the capstone)

> **Status: ✅ SHIPPED — Fork B ruled Arm 2 (the additive weighted multi-pop), D-1; built + Director-verified
> PASS (Y-2 on the ledger), zero remediation.** The FOURTH and **CAPSTONE** sub-rung of the emq.4 "groups deepened"
> family; the family contract + the carve are [`../emq.4.md`](../emq.4.md). emq.4.4 deepens the **rotation** itself:
> the ring served lanes in **strict round-robin** (every claim rotates the ring one step — `@gclaim`'s `LMOVE
> KEYS[1] KEYS[1] LEFT RIGHT` then `ZPOPMIN` the head, `lanes.ex:38,41`), equal-share by construction. emq.4.4 adds
> **fair-share BEYOND round-robin** — a weighted multi-pop over the ring so a higher-weight lane is served
> proportionally more — plus the **starvation drill**, a proof that **no lane starves under skew** (the capstone
> guarantee). **Fork B ruled Arm 2 → the weighting landed ADDITIVELY: a NEW inline `@gwclaim` script + a new
> `wclaim/3` host verb, with `@gclaim`/`claim/3` BYTE-FROZEN (the equal round-robin and the weighted path coexist).**
> The rung graded **NORMAL+** — every shipped `@g*` script (all EIGHT: `@genqueue`/`@gclaim`/`@gpause`/`@gresume`/
> `@glimit`/`@greassign`/`@gdrain`/`@greap_group`) is byte-identical to HEAD; Apollo was an optional fast-finisher,
> not mandated (no shipped-script edit). The v2 master invariant holds (server clock on the served lease · declared
> keys A-1 · no new key family — the weight rides the new `emq:{q}:gweight` per-queue HASH, an existing shape · no
> wire break — `@wire_version` stays `echomq:2.4.2`, an additive minor; `mix.exs` label → 2.4.4, the two-planes
> model).

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

emq.4.4 built, inside `echo/apps/echo_mq`, a **weighted multi-pop** over the ring plus the **starvation drill**:
(a) a lane carries a **weight** — the home is the new `emq:{q}:gweight` per-queue HASH (group → weight), the same
key SHAPE as `glimit`/`gactive`, **no new key FAMILY** and no §6 grammar edit (INV3); a weight is set with the new
`weight/4` host verb (`w >= 1`, branded-gated at `lane_key!/2`, no re-ring — a weight change never alters a lane's
serviceability) — and the new `wclaim/3` rotation serves lanes **in proportion to weight** (a higher-weight lane
gets proportionally more serves, never all of them); (b) the **starvation drill** — a `:valkey` scenario that floods
one HEAVY lane and trickles several LIGHT lanes and proves no lane starves, witnessed by **interleaving within a
bounded early window** (every light lane is served inside a 9-turn / 3-ring-cycle window while the heavy lane is
still deep) plus the terminal liveness that every lane drains to zero (the early-window witness is the load-bearing
no-op-defeater — see DoD); (c) the weighting landed **additively** — the new inline `@gwclaim` script (Fork B Arm 2,
D-1) leaving `@gclaim` BYTE-FROZEN — all under the A-1 declared-keys law, branded group ids gated at the lane-key
builder, the **server clock** on the served lease (the shipped `@gclaim` lease pattern, `lanes.ex:50-52`), and
additive-minor conformance growth (59 → 61).

## Rationale (5W)

- **Why** — equal round-robin is fair only when lanes deserve equal share; a multi-tenant bus needs **proportional**
  fairness (a premium tenant served more, a background tenant served less) **without** a numeric per-job priority
  (retired by design) and **without** starving any lane. Weighted/deficit round-robin is the textbook answer
  (fair-share scheduling), and the **starvation drill** is the proof the scheme keeps its strong guarantee under the
  adversarial case (sustained skew). It is the capstone because it completes the fairness story the family opened
  (equal lanes → proportional lanes, starvation-proof) and carries the chapter's highest risk (the shipped
  claim-path edit).
- **What** — emq.4.4 built (Fork B Arm 2, the additive weighted multi-pop): (1) the lane **weight** representation
  — the new `emq:{q}:gweight` per-queue HASH (group → weight), the `glimit`/`gactive` key SHAPE, no new key family,
  set by `weight/4` (`@gweight` — `HSET gweight group w`, no re-ring); (2) the **weighted multi-pop** rotation — the
  new inline `@gwclaim` script (`wclaim/3` host verb): one `LMOVE` ring step, then K = `min(weight, lane depth,
  glimit headroom)` heads served in one atomic turn sharing ONE server-clock lease, `gactive += K`, the
  `@gclaim:53-59` re-ring guard; (3) the **starvation-drill** scenario + the **weighted-proportion** scenario
  (additive minor, the prior 59 byte-unchanged → 61); (4) the `:valkey` proof + the multi-seed determinism sweep
  (Arm 2 mints no id and starts no process — no ≥100 loop) + the byte-freeze grep on every shipped `@g*` (all
  eight = 0).
- **Who** — the program (the rung that completes the groups fairness story); multi-tenant **operators**, who gain
  proportional fair-share with a starvation guarantee; the conformance harness, which grew by the
  weighted-proportion + starvation-drill scenarios. The shipped `@gclaim` ring rotation is the precedent the new
  `@gwclaim` deepens (byte-frozen — the weighted path is parallel). **Apollo** was an optional fast-finisher, NOT
  mandated (Arm 2 edits no shipped script).
- **When** — Movement II, the groups family's **fourth and capstone** sub-rung, **last** (built on emq.4.1–4.3).
  **Fork B ruled Arm 2 (D-1)** at the pre-build reconcile with the shipped `@gclaim` re-probed (byte-frozen across
  4.1/4.2/4.3); the additive ruling graded the rung NORMAL+. Built + Director-verified PASS in one increment.
- **Where** — `echo/apps/echo_mq` only: `lanes.ex` (the new `@gwclaim`/`@gweight` scripts + `wclaim/3`/`weight/4`
  host verbs; `@gclaim`/`claim/3` and every other `@g*` BYTE-FROZEN — the weighted path is additive/parallel),
  `conformance.ex` (the `weighted_proportion` + `starvation_drill` scenarios + the count re-pin), the `:valkey`
  proof (the two conformance scenarios), the two pinning tests (the count 59 → 61), `mix.exs` (the rung label →
  2.4.4). `echo_wire` is **untouched** (the rotation rides the shipped connector `eval`; `@wire_version` stays
  `echomq:2.4.2`). `apps/echomq` is **untouched** (the capability reference). The §6 grammar in `keyspace.ex` is
  **unedited** (no new key family — `gweight` rides `Keyspace.queue_key/2`).

## Scope

- **In** — the weighted multi-pop + the drill: (1) the lane **weight** representation (the `emq:{q}:gweight`
  per-queue HASH — no new key family); (2) the **weighted multi-pop** rotation over the ring (`@gwclaim`/`wclaim/3`
  — lanes served in proportion to weight, K = `min(weight, depth, glimit headroom)`); (3) the **starvation drill**
  (a skewed-load scenario witnessing interleaving in a bounded early window + every lane draining) + the
  weighted-proportion scenario; (4) the conformance scenarios (additive minor, the prior 59 byte-unchanged → 61);
  (5) the `:valkey` suites + a **multi-seed sweep** + an honest determinism-posture statement (Arm 2 mints no id and
  starts no process — the ≥100 loop is not required, running it would forge load the rung did not introduce);
  (6) the **byte-freeze grep** on every shipped `@g*` script (= 0 for `grep redis.call`).
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
  proportion to weight** (a higher-weight lane gets proportionally more serves, never all of them — K =
  `min(weight, depth, glimit headroom)`, so a weight is a throughput share clamped by the concurrency ceiling and a
  zero/parked lane is the operator's `pause/3`, never a rotation outcome); under sustained skew **no lane starves**.
  *Check:* the weighted-proportion `:valkey` scenario (two lanes, weights 3:1 → serves within the band `2x ≤ A/B ≤
  4x` over a window — proportional only in the limit, the band is the honest bound); the **starvation-drill**
  scenario (one HEAVY lane flooded, several LIGHT lanes trickling → every light lane is served INSIDE a bounded
  early window of 9 turns / 3 ring cycles AND every lane drains to zero). The early-window interleaving is the
  load-bearing assertion (the terminal drain alone is not a no-op-defeater — see DoD); the multi-seed sweep is
  green (Arm 2 mints no id and starts no process).
- **EMQ.4.4-INV2 (← EMQ.4-INV3) — the byte-freeze discipline (every shipped `@g*` is byte-unchanged).** Fork B
  ruled Arm 2 (additive), so emq.4.4 edits **no** shipped lane script: **all EIGHT** `@g*` scripts — `@genqueue`,
  `@gclaim`, `@gpause`, `@gresume`, `@glimit`, `@greassign`, `@gdrain`, `@greap_group` — are **byte-identical to
  HEAD** (`grep redis.call` on the lib diff for those = 0; the weighting is the NEW `@gwclaim` + `@gweight`, parallel
  paths). The prior fair-lanes conformance scenarios (`rotate`, `pause`, `limit`, `lane_depth`, `stalled_group`,
  `reassign`, `lane_drain`, `reap_group`) pass **byte-unchanged**. *Check:* the byte-freeze grep on the eight shipped
  `@g*` scripts = 0; the prior scenarios git-verified unchanged; the prior 59 byte-unchanged.
- **EMQ.4.4-INV3 (← EMQ.4-INV1) — the wire law (no new key family, no numeric priority).** The weight rides an
  **existing key shape** — the new `emq:{q}:gweight` per-queue HASH (group → weight), the same shape as
  `glimit`/`gactive`, built by `Keyspace.queue_key/2`, **no new key FAMILY** and no §6 grammar edit; the rotation
  rides the shipped `emq:{q}:g:<group>:pending` / `ring` keys; **no numeric per-job priority** (weight is per-LANE);
  **no new wire class**, **no new transport**. *Check:* a grep of `@gwclaim`/`@gweight` for a lane key not in the
  shipped `g:`-segment family returns empty; a grep for a numeric-priority score / a `prioritized` key returns
  empty; `{emq}:version` reads `echomq:2.4.2` (the wire `@wire_version` is unchanged — Arm 2 is an additive minor;
  `mix.exs` 2.4.4 is the rung label, the two-planes model); the §6 grammar in `keyspace.ex` is unedited.
- **EMQ.4.4-INV4 (← EMQ.4-INV5) — server clock where the lease is touched.** `@gwclaim` reads `TIME`
  **server-side** inside the script ONCE per turn and leases every job it serves on that one deadline (the shipped
  `@gclaim` `redis.call('TIME')` lease pattern, `lanes.ex:50-52`, mirrored at `@gwclaim`); no host clock crosses the
  lease. *Check:* a grep of `@gwclaim` for a host-supplied lease timestamp returns empty; the lease is computed from
  `redis.call('TIME')`; the starvation-drill scenario asserts every served job carries a `TIME`-derived `active`
  score.
- **EMQ.4.4-INV5 (← EMQ.4-INV4) — branded group identity at the weight + claim boundaries.** A weight is set on a
  **valid branded group** (gated `EchoData.BrandedId.valid?/1` at `lane_key!/2` before any wire — `weight/4` gates
  it); the weighted claim serves a member of a branded-gated lane. *Check:* an ill-formed group raises before the
  wire when a weight is set; the weighted-proportion + starvation-drill scenarios use branded `PRT` groups.
- **EMQ.4.4-INV6 (← EMQ.4-INV6) — the additive-minor conformance law.** The `weighted_proportion` +
  `starvation_drill` scenarios are registered in `scenarios/0` **with their probes in the same change**; the prior
  **59** scenarios pass **byte-unchanged**; the count re-pins **59 → 61** in **both** pinning tests
  (`conformance_run_test.exs` `{:ok, 61}` + `conformance_scenarios_test.exs` `@run_order`). *Check:* the git-diff
  shows only additions to `scenarios/0`; both count assertions updated; `Conformance.run/2` prints 61 lines.

## The rung's fork — RULED

### FORK B — the weighted-rotation mechanism — RULED: Arm 2 (the additive weighted multi-pop), D-1

> **The ruling.** Venus surfaced three arms re-grounded against the re-probed `@gclaim` (byte-frozen across
> 4.1/4.2/4.3) + the shipped `metronome.ex`; the Operator (via the Director) ruled **Arm 2 — the additive weighted
> multi-pop**. **Why Arm 2:** it keeps `@gclaim` (the fairness-critical claim path) **byte-frozen** — the weighting
> is a parallel `@gwclaim` script, so the equal round-robin and the weighted path coexist; it keeps fairness
> **server-side in the claim** (sound across a consumer pool and a future cluster — the BCS property); it is
> **reversible** (a new script vs. re-founding a frozen one); and it avoids the 4.3↔4.4 coupling Arm 3 forces.
> The cost accepted: weight granularity is integer multiples (acceptable for per-tenant fair-share). The rung
> graded **NORMAL+** (no shipped-script edit → Apollo optional, the determinism posture by a multi-seed sweep).
>
> **The arms (recorded — Arm 2 ruled):**
> - **Arm 1 — a deficit counter on the ring (DRR).** Each lane carries a deficit credited per rotation, consumed per
>   serve. *Steelman:* smooth proportional share at fine granularity, starvation-free by construction. *Cost (why
>   not):* an EDIT to `@gclaim` (HIGH-risk → byte-freeze every OTHER `@g*` + Apollo MANDATORY + the ≥100 loop) — a
>   frozen-claim-path edit the Operator chose against on a capstone.
> - **Arm 2 — a weighted multi-pop. ✅ RULED.** A higher-weight lane serves K heads per rotation (K = `min(weight,
>   lane depth, glimit headroom)`). *As built:* the NEW inline `@gwclaim` — one `LMOVE` ring step, then K heads
>   served in one atomic turn sharing one server-clock lease, `gactive += K`, the `@gclaim:53-59` re-ring guard;
>   `@gclaim` byte-unchanged. The granularity is integer multiples (the accepted cost).
> - **Arm 3 — a per-lane budget refreshed by the metronome.** The beat refreshes a per-lane serve budget. *Steelman:*
>   couples to the 4.3 cadence. *Cost (why not):* the reconcile found it ENTANGLING — the shipped metronome owns no
>   lease + decides host-side in a pure Core, so a per-lane budget either regresses fairness host-side (loses the BCS
>   property) or needs a new wire structure + couples two rungs + risks a §6 question; granularity is beat-bound.
>
> **No new key family any arm** (every arm rides an existing key shape — INV3); Arm 2 added the `emq:{q}:gweight`
> per-queue HASH on the `glimit`/`gactive` shape.

## Definition of Done

- [x] **Fork B** surfaced with all three arms + costs + the `@gclaim`-edit risk trade-off, the shipped `@gclaim`
      re-probed; the Operator ruled **Arm 2 (the additive weighted multi-pop)**, D-1; the body re-derived to it
      (the `emq:{q}:gweight` weight home + the `@gwclaim` rotation pinned).
- [x] The lane **weight** representation built: the `emq:{q}:gweight` per-queue HASH (no new key family — the
      `glimit`/`gactive` shape), set by `weight/4` (`@gweight`; `w >= 1`, branded-gated, no re-ring).
- [x] The **weighted multi-pop** rotation built (lanes served in proportion to weight): the new inline `@gwclaim` +
      `wclaim/3` host verb — additive, `@gclaim` byte-unchanged (every other `@g*` byte-frozen too — all eight).
- [x] The **starvation-drill** + **weighted-proportion** conformance scenarios registered (additive minor — the
      prior **59** byte-unchanged; the count re-pinned **59 → 61** in both pinning tests). **The drill shape (the
      load-bearing correction, ledger L-1, independently verified):** the drill ships as a **bounded-early-window
      interleaving witness** — every LIGHT lane is served within a 9-turn / 3-ring-cycle window while the HEAVY lane
      is still deep — NOT a terminal depth-0 check alone. *Why:* a terminal depth-0 check is a **weak
      no-op-defeater** — a no-rotation FIFO drain ALSO empties every lane (the re-ring guard `@gclaim:57` `elseif
      ZCARD lane == 0` advances the head as each lane empties), so it cannot distinguish fair rotation from no
      rotation. The early-window interleaving DOES distinguish them: a FIFO / serve-heavy-to-exhaustion-first
      rotation serves ZERO from a light lane in the early window → the drill goes RED under that mutation. The
      terminal drain remains as the liveness floor (every lane reaches zero), but the witness is the early window.
- [x] The proof: the `:valkey` weighted + drill scenarios green per-app; a **multi-seed sweep + an honest
      determinism-posture statement** (Arm 2 mints no id and starts no process — the ≥100 loop is not required); the
      byte-freeze grep on every shipped `@g*` = 0 (all eight — INV2); honest-row reporting (Valkey on 6390).
      **Apollo** was an optional fast-finisher, NOT mandated (Arm 2 edits no shipped script).
- [x] INV1–INV6 verified as runnable checks; the family contract ([`../emq.4.md`](../emq.4.md)) remains the carve
      authority; this body is now authoritative (synced to the as-built post-build, Stage-5).

Family: [`../emq.4.md`](../emq.4.md) (the contract, the carve, the forks — the carve authority) · Chapter stories:
[`../emq.4.stories.md`](../emq.4.stories.md) (US4 — weighted/deficit + the drill) · Rung stories +
brief: [`emq.4.4.stories.md`](emq.4.4.stories.md) · [`emq.4.4.llms.md`](emq.4.4.llms.md) · As-built surface
(SHIPPED): `echo/apps/echo_mq/lib/echo_mq/lanes.ex` — the NEW weighted path: `@gwclaim` (`lanes.ex:87` — one
`LMOVE` ring step, K = `min(weight, ZCARD lane, glimit headroom)` heads in one atomic turn, ONE server-clock lease
`redis.call('TIME')`, `gactive += K`, the `@gclaim:53-59` re-ring guard, a nested-array return) + `@gweight`
(`lanes.ex:137` — `HSET gweight group w`, no re-ring) + `wclaim/3` (`lanes.ex:281` → `{:ok, [{id, payload,
attempts, group}, ...]}` | `:empty`) + `weight/4` (`lanes.ex:309`, `w >= 1`, branded-gated). The shipped ring
rotation `@gclaim` (`lanes.ex:37`) + every other `@g*` (`@genqueue`/`@gpause`/`@gresume`/`@glimit`/`@greassign`/
`@gdrain`/`@greap_group`) are **BYTE-FROZEN** (all eight `grep redis.call` = 0). `conformance.ex` (the **59→61**
scenario set the additive-minor law grew — `weighted_proportion` + `starvation_drill`; the `rotate` scenario "two
lanes claim in strict rotation — the ring is the rota" is the equal-share precedent) · The v1 capability reference
(the re-aim record, READ-ONLY — the form NOT to lift):
[`../../emq.commands/features/groups/changePriority-7.md`](../../../emq.commands/features/groups/changePriority-7.md)
(RETIRED → "weighted rotation, emq.4" — the canon names this rung) · Design:
[`../../../emq.design.md`](../../../../emq.design.md) §10 seam 2 / §4 cluster 2 (the displaced groups family RULED →
emq.4), §4 (the server-clock law — the lease in the rotation), S-6 (the declared-keys A-1 law), S-1/§6 (the braced
keyspace) · Roadmap: [`../../../emq.roadmap.md`](../../../../emq.roadmap.md) (the emq.4 row · Movement II) · Approach:
[`../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
