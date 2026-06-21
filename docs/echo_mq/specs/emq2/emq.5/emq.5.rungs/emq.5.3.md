# EMQ.5.3 · Group affinity + batch concurrency + dynamic rate — the grouped batch (Movement II, the batches family, the composition)

> **Status: ✅ SHIPPED — the three forks RULED to their leans (ledger D-1); built BUILD-GRADE; Director verify CLEAN
> (one within-family-patch remediation, D-2).** The THIRD sub-rung of the emq.5 "batches" family; the family contract +
> the carve are [`../emq.5.md`](../emq.5.md). This body is now authoritative (synced to the as-built post-build,
> Stage-5). emq.5.3 **composes** the two CLOSED halves the family stands between: the SHIPPED flat-batch spine (emq.5.1
> — `@bclaim` + `claim_batch/4`) and the CLOSED fair-lanes ring (emq.4 — `@gclaim`/`@gwclaim`/`gactive`/`gweight`/
> `glimit`). The flat batch crosses groups — it bypasses the ring's per-group concurrency accounting; emq.5.3 makes the
> batch **affinity-respecting**: drawn from a SINGLE group (the ring rotation picks it — FORK 5.3-C RULED ring-rotated),
> counted against that group's `gactive` ceiling, so bulk consumption coexists with fair lanes.
>
> **The rulings (D-1) + the as-built (D-2).** FORK 5.3-A → **additive `@gbclaim`** (a NEW inline script parallel to
> `@gwclaim`; every shipped `@g*`/`@bclaim` byte-frozen). FORK 5.3-B → **reuse `gactive`** (no new key). FORK 5.3-C →
> **ring-rotated `bclaim/3`** (the rotation picks the group; no caller-named arity). The as-built `@gbclaim` is the
> `@gwclaim` body with ONE semantic delta: it **drops `@gwclaim`'s `gweight` read** — K = `min(lane depth, glimit
> headroom)`, the lane's full serviceable depth bounded only by its concurrency ceiling (a batch is a per-call request,
> not a per-lane throughput share, so no weight is read). The host verb is **`bclaim/3`** `(conn, queue, lease_ms)` —
> no `size` argument; the batch serves the lane's serviceable depth. The rung label is **`2.5.1`** (the within-family
> patch — emq.5 opened at `2.5.0` and held through 5.2, so 5.3 = `2.5.1`; the D-2 remediation corrected a `2.6.0`
> first cut); the wire `@wire_version` stays **frozen at `echomq:2.4.2`** (no wire break — an additive minor).
>
> **Risk: NORMAL+.** The additive `@gbclaim` keeps every shipped `@g*`/`@bclaim` script **byte-frozen** — the affinity
> claim is a NEW inline script parallel to `@gwclaim`, not an edit to a frozen fairness path. The one elevated point is
> the **fair-lanes composition** (a grouped claim touches the ceiling + ring bookkeeping the fairness story depends on),
> so the rung carried **emq.4.4-L1** (a fair-share property needs a bounded-early-window INTERLEAVING witness, not a
> terminal drain). A MINT/LEASE surface → the **≥100 determinism loop** (the same-millisecond branded-`JOB` mint
> hazard). Conformance grew **67 → 70** (`grouped_batch_affinity` · `grouped_batch_ceiling` · `grouped_batch_fairness`).

## 0 · The slice — what emq.5.3 composes, and why NORMAL+

The family ([`../emq.5.md`](../emq.5.md)) is the Movement II **consume** family. emq.5.1 shipped the **spine** — a
flat-set batch claim (`@bclaim` over `emq:{q}:pending`, a count-variant `ZPOPMIN` loop, one server-clock lease, up to
`size` heads). emq.5.2 shipped the **shaping cadence** (`EchoMQ.BatchConsumer` — `min_size`/`timeout` flush). Both are
**group-blind**: the flat `pending` set has no lane structure, so a flat batch can serve members of many groups in one
claim, and the ring's per-group `gactive` counter — the concurrency ceiling fairness depends on — is never touched.

emq.5.3 carves the **grouped batch**: a batch drawn from a SINGLE group's lane (`emq:{q}:g:<group>:pending`), leased on
one server-clock deadline, counted against that group's `gactive` ceiling. It is the bulk-consume axis of the fair-lanes
ring — a worker amortizes the per-job round-trip across a batch **without** breaking the per-group accounting the
fairness story keeps. The mechanism is **reserved, not invented** (the carve [`../emq.5.md`](../emq.5.md) §1 row emq.5.3;
the design [`../../../../emq.design.md`](../../../../emq.design.md) §6.2 count-variant pops): a batch claim is a count-variant
`ZPOPMIN` INSIDE the script, never a client-side `LMPOP`/`ZMPOP` (a client pop bypasses the bookkeeping path).

The just-CLOSED **`@gwclaim` (emq.4.4) already proves the exact grouped-multi-pop shape** (`lanes.ex:87-129`): one
ring step, then serve a lane K heads in one atomic turn under ONE `redis.call('TIME')` lease, `gactive += K`, the
`glimit` headroom clamp (K bounded so `gactive` never passes `glimit`), the post-increment re-ring guard. The as-built
`@gbclaim` (`lanes.ex:161-200`) is the `@gwclaim` body with the **single semantic delta that it DROPS the `gweight`
read entirely**: `@gwclaim`'s K is `min(weight, depth, glimit headroom)` (the weight is a per-lane throughput share);
`@gbclaim`'s K is `min(lane depth, glimit headroom)` — the lane's **full serviceable depth** bounded only by its
concurrency ceiling, because a batch is a per-call request, not a per-lane share, so no weight enters. There is **no
`size` argument** — the ring-rotated batch (FORK 5.3-C RULED Arm 1) serves whatever the rotated lane holds within its
headroom. This near-isomorphism (the `@gwclaim` loop, lease, `gactive += K`, and re-ring guard re-used verbatim, only
the K formula simplified) is why the rung is **additive over a proven mechanism** and graded **NORMAL+**, not HIGH —
FORK 5.3-A RULED additive, so `@gwclaim`/`@gclaim` stay byte-frozen.

## Goal

emq.5.3 built, inside `echo/apps/echo_mq`, a **grouped (affinity-respecting) batch claim** plus its batch-concurrency
accounting and a runtime-mutable rate on the emq.4 floor:

(a) **the affinity claim** — `@gbclaim`, a NEW inline `Script.new(:gbclaim, …)` BESIDE `@gwclaim` in `lanes.ex`
(`lanes.ex:161-200`): a **homogeneous lane-scoped batch** — one `LMOVE` ring step picks the group (FORK 5.3-C RULED
ring-rotated), then the rotated lane's full serviceable depth is served in one atomic turn, leased on ONE server-clock
`TIME` deadline, `gactive += the ACTUAL count served`, the `glimit` ceiling NEVER exceeded (**K = `min(lane depth,
glimit headroom)`** — the `gweight` read DROPPED; a lane at its ceiling is de-ringed — the `@gwclaim` ceiling
discipline). The host verb is **`Lanes.bclaim/3`** `(conn, queue, lease_ms)` (`lanes.ex:403-416`) — no `size`
argument, the batch serves the lane's serviceable depth — returning a LIST of `{id, payload, attempts, group}` (the
`@gwclaim`/`wclaim/3` 4-tuple shape) or `:empty` (an empty ring, a lane emptied since the rotation, a lane at its
ceiling, or a queue-wide pause honored host-side first);

(b) **batch concurrency** — a grouped batch counts as its served count against the group's `gactive` ceiling (FORK
5.3-B RULED reuse `gactive`, no new key); the `glimit` headroom clamp guarantees a batch never pushes a group past its
concurrency ceiling (the `@gwclaim` headroom invariant, carried);

(c) **the group-selection mechanism** — RULED **ring-rotated** (FORK 5.3-C Arm 1): `@gbclaim` does the `@gwclaim`
`LMOVE` ring step and serves a batch from whichever lane the rotation lands on (fairness-driven, operator-agnostic),
so fairness is preserved by construction and the `bclaim/3` arity carries no `group` argument. The caller-named arm
(`bclaim/4` with a `group`) was the chosen-against alternative — recorded under "The rung's forks";

(d) **dynamic rate** — a runtime-mutable rate on the emq.4 floor, grounded in the shipped `gweight`/`glimit` surface
(`Lanes.weight/4` `lanes.ex:433`, `Lanes.limit/4` `lanes.ex:475`), kept ADDITIVE (no new key family) — the existing
weight/limit setters ARE the runtime-mutable rate knobs; emq.5.3 rides them unchanged (no gap surfaced — they needed
no batch-aware edit).

All under the v2 laws — the A-1 declared-keys law (the lane base pins the `{q}` slot), branded group ids gated at the
lane-key builder, the **server clock** on the served lease, and additive-minor conformance growth (**67 → 70**, the
prior 67 byte-unchanged).

## Rationale (5W)

- **Why** — emq.5.1/5.2 give bulk consume over the FLAT set, but a multi-tenant bus runs the fair-lanes ring, and a
  flat batch crossing groups **silently bypasses the ring's `gactive` accounting** — a worker pulling a flat batch can
  over-serve one tenant past its `glimit` ceiling, defeating the fairness emq.4 built. emq.5.3 makes bulk consume
  **lane-aware**: a batch is homogeneous (one group), counted against that group's ceiling, so the throughput win of a
  batch coexists with the fairness guarantee of the lanes. The `@gwclaim` precedent (emq.4.4) made this additive — the
  grouped multi-pop is a proven shape; emq.5.3 re-uses its loop/lease/`gactive`/re-ring body and DROPS the `gweight`
  read (a batch is a per-call request, not a per-lane share), serving the lane's full serviceable depth within the
  ceiling.
- **What** — emq.5.3 built (the rulings D-1): (1) the **affinity claim** — the new inline `@gbclaim` (a count-variant
  `ZPOPMIN` over ONE ring-rotated lane, **K = `min(lane depth, glimit headroom)`** — no `size`, no `gweight` read, one
  `TIME` lease, `gactive += K`, the re-ring guard) + the host verb **`Lanes.bclaim/3`** `(conn, queue, lease_ms)`
  (FORK 5.3-C RULED ring-rotated → no `group`/`size` argument); (2) **batch concurrency** via `gactive` (FORK 5.3-B
  RULED — a batch counts its served members, no new key); (3) the **conformance scenarios** (additive minor — the
  prior 67 byte-unchanged → **70**: `grouped_batch_affinity` + `grouped_batch_ceiling` + the emq.4.4-L1
  `grouped_batch_fairness` interleaving witness); (4) the `:valkey` proof + the **≥100 determinism loop** (a mint/lease
  surface) + the **byte-freeze grep** on every shipped `@g*`/`@bclaim` (= 0 for `grep redis.call`).
- **Who** — the program (the rung that makes bulk-consume fair-lanes-aware); multi-tenant **operators**, who gain a
  per-lane batch claim that respects the lane's concurrency ceiling; the conformance harness, which grew by the
  affinity + ceiling + fairness-witness scenarios. The shipped `@gwclaim` (the grouped multi-pop) is the precedent the
  new `@gbclaim` re-uses (byte-frozen — the affinity path is parallel). **Apollo was RECOMMENDED** (the fair-lanes
  composition risk; carry emq.4.4-L1).
- **When** — Movement II, the batches family's **third** sub-rung (built on emq.5.1; rides the CLOSED emq.4 ring). The
  family carve gate-blocked 5.3 on emq.4 ("affinity gates on emq.4's deepened rotation"); **emq.4 is CLOSED, so 5.3 was
  UNBLOCKED**. The three forks (5.3-A / 5.3-B / 5.3-C) were ruled via `AskUserQuestion` at the pre-build reconcile (all
  to their leans, D-1), the body re-derived to the rulings before Mars built; Director verify CLEAN with one
  within-family-patch remediation (D-2: the `mix.exs` label `2.6.0` → `2.5.1`).
- **Where** — `echo/apps/echo_mq` only: `lanes.ex` (the new `@gbclaim` script `lanes.ex:161-200` + the `bclaim/3` host
  verb `lanes.ex:403-416`; every shipped `@g*` — `@genqueue`/`@gclaim`/`@gpause`/`@gresume`/`@glimit`/`@greassign`/
  `@gdrain`/`@greap_group`/`@gwclaim`/`@gweight` — and `@bclaim` BYTE-FROZEN), `conformance.ex` (the
  `grouped_batch_affinity`/`grouped_batch_ceiling`/`grouped_batch_fairness` scenarios + the count re-pin), the
  `:valkey` proof, the two pinning tests (`conformance_run_test.exs` `{:ok, 70}` + `conformance_scenarios_test.exs`
  `@run_order`), `mix.exs` (the rung label `2.5.1`; the wire `@wire_version` stays `echomq:2.4.2`, the two-planes
  model). `echo_wire` is **untouched** (the claim rides the shipped connector `eval`). `apps/echomq` is **untouched**
  (the capability reference). The §6 grammar in `keyspace.ex` is **unedited** (no new key family — `@gbclaim` rides the
  shipped `g:`-segment lane keys + `gactive`/`glimit`).

## Scope

- **In** — the grouped batch: (1) the **affinity claim** (`@gbclaim`/`bclaim/3` — a homogeneous ring-rotated
  lane-scoped batch, **K = `min(lane depth, glimit headroom)`** — no `size`, no `gweight` read, one server-clock lease,
  `gactive += K`); (2) **batch concurrency** (the group's `gactive` counts a batch's served members; the `glimit`
  headroom clamp guarantees no batch passes the ceiling — FORK 5.3-B RULED reuse `gactive`); (3) the
  **group-selection mechanism** RULED ring-rotated (FORK 5.3-C Arm 1 — the rotation picks the group); (4) the
  **dynamic rate** over the shipped `weight/4`/`limit/4` (additive — no new key, ridden unchanged); (5) the conformance
  scenarios (additive minor — the prior 67 byte-unchanged → **70**) **carrying emq.4.4-L1** (a bounded-early-window
  interleaving witness, not a terminal drain); (6) the `:valkey` suites + the **≥100 determinism loop** (a mint/lease
  surface) + the **byte-freeze grep** on every shipped `@g*`/`@bclaim` (= 0).
- **Out** — any **edit to a shipped `@g*`/`@bclaim` script** (every one byte-frozen — INV-Frozen; the affinity path is
  the NEW `@gbclaim`, parallel); a **caller-named batch** (FORK 5.3-C RULED ring-rotated — no `bclaim/4` with a `group`
  argument; the rotation picks the lane); a **`size` argument** (the ring-rotated batch serves the lane's serviceable
  depth, not a caller-requested count); any **new lane key family** (the batch rides the shipped `g:`-segment keys +
  `gactive`/`glimit` — INV-DeclaredKeys); any **numeric per-job priority** (retired by design — the lane is the unit,
  mint order is the order theorem); a **HETEROGENEOUS batch** (a single batch spanning groups is the FLAT `@bclaim`
  (emq.5.1), NOT this rung — INV-Affinity); the **shaping cadence** (`EchoMQ.BatchConsumer`, emq.5.2 — a grouped batch
  consumer riding `@gbclaim` is a carried follow-up, named not built here); the **partitioned finish** (emq.5.4); any
  **`echo_wire`/transport** change (`@wire_version` stays `echomq:2.4.2`); any **edit to the frozen v1 reference line**.

## Invariants (the runnable checks — from T-1)

- **EMQ.5.3-INV-Affinity — the batch is homogeneous (one group).** Every member a single `bclaim/3` returns belongs to
  the ONE served group (the lane the ring rotation landed on) — a grouped batch never mixes lanes (a cross-group batch
  is the flat `@bclaim`, a different rung). The members come from `emq:{q}:g:<group>:pending` (the shipped lane key) and
  only that lane. *Check:* the `grouped_batch_affinity` `:valkey` scenario — flood TWO branded lanes, claim a grouped
  batch, assert EVERY returned member's row `group` field equals the served group (and equals the other lane for NONE);
  a batch with members from two lanes is a LOUD failure.
- **EMQ.5.3-INV-Ceiling — `gactive += the actual count`, NEVER past `glimit`.** The served count increments the group's
  `gactive` by the ACTUAL number served; K is clamped by the `glimit` headroom (`K ≤ lim - cur` when a limit is set —
  the `@gwclaim` clamp `lanes.ex:172-176` mirrored in `@gbclaim`), so a batch NEVER pushes `gactive` past `glimit`. A
  lane at its ceiling (no headroom) is de-ringed and serves nothing (the `@gbclaim:177-180` guard). *Check:* the
  `grouped_batch_ceiling` `:valkey` scenario — set `glimit` g = 3, flood the lane 8 deep, claim a grouped batch, assert
  EXACTLY 3 served (the headroom — the lane's depth clamped to the ceiling), `gactive` g = 3 (= `glimit`), and a second
  claim returns `:empty` (the lane de-ringed at ceiling) until a `complete/5` frees headroom, then the freed slot
  serves again. The over-pop case (serving past the ceiling) is a LOUD failure.
- **EMQ.5.3-INV-ServerClock (← INV4) — one TIME, one batch lease.** `@gbclaim` reads `redis.call('TIME')`
  **server-side** inside the script ONCE per turn (`lanes.ex:181-182`) and leases every job it serves on that one
  deadline (the shipped `@gclaim`/`@gwclaim` `TIME` lease pattern, `lanes.ex:50-52` / `lanes.ex:110-111`); no host
  clock crosses the lease. *Check:* a grep of `@gbclaim` for a host-supplied lease timestamp returns empty; the
  affinity scenario asserts EVERY served member carries the SAME `TIME`-derived `active` score (one shared deadline —
  distinct deadlines would mean a per-member re-read, the `batch_claim` `:not_one_shared_lease` defeater).
- **EMQ.5.3-INV-DeclaredKeys (← S-6, the A-1/L-1 law) — the lane base pins the `{q}` slot.** `@gbclaim` declares the
  braced `KEYS[1]=ring`/`KEYS[2]=active` pinning the `{q}` slot (the `@gwclaim` convention, `lanes.ex:162,190`); the
  lane (`ARGV[1]..'g:'..g..':pending'`), `gactive`, and `glimit` are derived in-script from the declared queue base
  `ARGV[1]` by the registered grammar (`lanes.ex:164,171,173,193`). **An ARGV base is NOT a declared root** — the
  braced `KEYS[n]` pin the slot, the row/lane/counter ride that slot (the emq.5.1-L1 finding, gate-invisible on
  single-node Valkey). *Check:* every key `@gbclaim` touches shares the one `{q}` slot `KEYS[1]`/`KEYS[2]` pin; a grep
  confirms no key is read out of a data value, and the lane/counter keys root on the declared base.
- **EMQ.5.3-INV-Frozen (← INV2) — the byte-freeze discipline.** FORK 5.3-A RULED additive `@gbclaim`, so emq.5.3 edits
  **no** shipped script: every shipped `@g*` — `@genqueue`, `@gclaim`, `@gpause`, `@gresume`, `@glimit`, `@greassign`,
  `@gdrain`, `@greap_group`, `@gwclaim`, `@gweight` — AND `@bclaim` (emq.5.1) are **byte-identical to HEAD** (`grep
  redis.call` on the lib diff for those = 0; the affinity claim is the NEW `@gbclaim`, a parallel path). The prior
  fair-lanes + batch conformance scenarios pass **byte-unchanged**. *Check:* the byte-freeze grep on every shipped
  `@g*`/`@bclaim` script = 0; the prior scenarios git-verified unchanged; the prior 67 byte-unchanged.
- **EMQ.5.3-INV-Determinism — the ≥100 loop (a mint/lease surface).** `@gbclaim` mints no id (the host mints the
  branded `JOB` ids at enqueue), but the affinity + ceiling scenarios mint many `JOB`/`PRT` ids per run and lease a
  batch, so the suite carries the same-millisecond branded-id mint hazard. *Check:* `for i in $(seq 1 100); do
  TMPDIR=/tmp mix test --include valkey || break; done` is green end to end; the loop OWNS the machine (no concurrent
  liveness server). One green run is not proof.
- **EMQ.5.3-INV-Fairness (the emq.4.4-L1 carry) — a bounded-early-window interleaving witness.** FORK 5.3-C RULED
  ring-rotated, so the affinity batch rides the ring rotation and must NOT let a heavy lane monopolize it — the
  `grouped_batch_fairness` scenario witnesses interleaving within a bounded EARLY window (every light lane served
  inside the first ring cycles while the heavy lane is still deep), NOT a terminal drain alone (a no-rotation FIFO
  drain ALSO empties every lane — the terminal check is a weak no-op-defeater; the `starvation_drill` L-1 lesson,
  `conformance.ex:1992-2073`). *Check:* the `grouped_batch_fairness` `:valkey` scenario (`conformance.ex:2486`) drives
  a bounded early window of grouped-batch claims under skew, records the served groups in a `MapSet`, and asserts every
  light lane appears in the early window (a FIFO/serve-heavy-first batch starves them early — the no-op-defeater) AND
  every lane drains to zero (the liveness floor).

## The rung's forks — RULED (the Operator ruled all three to their leans, ledger D-1)

The Operator ruled all three forks via `AskUserQuestion` at the pre-build reconcile, each to its lean: **FORK 5.3-A →
additive `@gbclaim`** (NORMAL+, every shipped script byte-frozen), **FORK 5.3-B → reuse `gactive`** (no new key),
**FORK 5.3-C → ring-rotated `bclaim/3`** (the rotation picks the group). The body above is now authoritative against
the as-built; the four-part Arms (Rationale / 5W / Steelman / Steward) are retained below as the decision record.

### FORK 5.3-A — the affinity-claim mechanism (RISK-DECIDING) — RULED: Arm 1 (additive `@gbclaim`), D-1

> **Rationale.** "A batch from one group" can land as a NEW script parallel to `@gwclaim`, or as an EXTENSION of
> `@gwclaim` to return a batch — the choice sets the rung's risk tier.
>
> **5W.** *What:* where the grouped multi-pop lives. *Why:* `@gwclaim` already loops `ZPOPMIN` K times over one lane;
> the question is whether to re-use that body as a new script or grow the shipped one. *Who:* the build (the risk tier
> decides Apollo + the loop). *When:* before the build. *Where:* `lanes.ex`.
>
> **The arms:**
> - **Arm 1 — an additive `@gbclaim`. ◄ LEAN.** A NEW inline `Script.new(:gbclaim, …)` beside `@gwclaim`, the
>   `@gwclaim` body re-used with the caller's `size` in place of the lane's `weight` (both clamp to `min(request,
>   depth, glimit headroom)`). *Steelman:* keeps `@gwclaim`/`@gclaim` (the fairness-critical claim paths) **byte-frozen**
>   — the affinity path is parallel, the equal/weighted/affinity claims coexist; **reversible** (a new script vs.
>   re-founding a frozen one); grades **NORMAL+** (no shipped-script edit → Apollo RECOMMENDED not MANDATORY, the
>   determinism by the ≥100 loop). *Cost:* one more lane script (acceptable — the family already adds one additive
>   script per claim rung; `@bclaim` at 5.1, `@gbclaim` here).
> - **Arm 2 — extend `@gwclaim` to a batch-return.** Grow the shipped `@gwclaim` so a `size` argument overrides the
>   weight and it returns the requested batch. *Steelman:* one claim script, no duplication. *Cost (why not):* an EDIT
>   to a shipped, byte-frozen fairness script → **HIGH-risk** (byte-freeze every OTHER `@g*` + Apollo MANDATORY + the
>   ≥100 loop required); it entangles the fairness throughput-share with the caller's batch-request semantics (a weight
>   is a per-turn share, a batch size is a per-call request — folding them muddies the `@gwclaim` contract `wclaim/3`
>   already ships); a frozen-claim-path edit on a composition rung the family explicitly flagged additive.
>
> **Steward → RULED Arm 1 (additive `@gbclaim`), D-1.** It keeps the rung NORMAL+, the fairness path frozen, and is
> the direct dividend of the `@gwclaim` precedent — the grouped multi-pop is proven; re-used parallel. As built:
> `@gbclaim` `lanes.ex:161-200`, every shipped `@g*`/`@bclaim` byte-frozen.

### FORK 5.3-B — the batch-concurrency home — RULED: Arm 1 (reuse `gactive`), D-1

> **Rationale.** A grouped batch occupies N in-flight slots against the group's ceiling; the question is which counter
> records that occupancy.
>
> **5W.** *What:* the in-flight counter a batch increments. *Why:* the ring's ceiling is `gactive` (per-group in-flight,
> `HINCRBY gactive g`); a batch could reuse it (count as its `size`) or introduce a new `gbatch` counter. *Who:* the
> fairness accounting. *When:* before the build. *Where:* `lanes.ex` + (Arm 2 only) `keyspace.ex`.
>
> **The arms:**
> - **Arm 1 — reuse `gactive`. ◄ LEAN.** A batch counts as its `size` against the group's `gactive` ceiling
>   (`HINCRBY gactive g K`, the `@gwclaim:122` form). *Steelman:* NO new key, the §6 grammar unedited; the `glimit`
>   headroom clamp already governs `gactive`, so a batch is bounded by the SAME ceiling a single claim is — one
>   accounting, one ceiling, the fairness story unchanged. *Cost:* a batch's N slots are released by N per-member
>   `complete/5`/`retry/7` (each `HINCRBY gactive g -1`) — the existing transitions already do this (the batch is a
>   CLAIM unit, not a resolution unit; the emq.5.1 partial-failure model).
> - **Arm 2 — a new `gbatch` in-flight counter.** A separate `emq:{q}:gbatch` HASH counting in-flight BATCHES (not
>   members). *Steelman:* distinguishes "one batch of 10" from "10 single claims" for metrics. *Cost (why not):* a NEW
>   key family (a §6 grammar question), a SECOND ceiling to keep coherent with `gactive`, and a coherence hazard (a
>   per-member `complete` must decrement BOTH) — complexity the fairness story does not need; "in-flight work" is the
>   member count `gactive` already keeps.
>
> **Steward → RULED Arm 1 (reuse `gactive`), D-1.** No new key, the §6 grammar unedited, one ceiling — the batch is
> bounded by the same `glimit` a single claim is. As built: `HINCRBY ARGV[1]..'gactive' g k` (`lanes.ex:193`).

### FORK 5.3-C — the group-selection mechanism (NEW — surfaced by Venus at the reconcile) — RULED: Arm 1 (ring-rotated `bclaim/3`), D-1

> **Rationale.** "Affinity" is ambiguous between two materially different host APIs, and the reconcile confirmed **no
> caller-named-group claim exists today** — ring-rotate (`LMOVE`) is the ONLY group-selection mechanism (`@gclaim`/
> `@gwclaim`). The choice changes the `bclaim/N` arity AND the fairness property, so it is an **API-contract fork** the
> Director must rule, not Venus.
>
> **5W.** *What:* HOW the affinity batch picks its group. *Why:* T-1 says "drawn from a SINGLE group" — but "single"
> can mean *whichever lane the fair rotation lands on* (homogeneous-by-outcome) OR *the lane the caller names*
> (homogeneous-by-request). These are different surfaces. *Who:* the operator (the API they call) + the fairness story.
> *When:* before the build (it sets INV-Fairness vs. INV-Affinity-isolation and the host arity). *Where:* `lanes.ex`
> (the host verb arity + whether `@gbclaim` does the `LMOVE`).
>
> **The arms:**
> - **Arm 1 — ring-rotated (the `@gwclaim` generalization). ◄ LEAN / ✅ RULED.** `@gbclaim` does the `LMOVE` ring step
>   (like `@gwclaim`), serves a batch from whichever lane the rotation lands on; `bclaim/3` (`conn, queue, lease_ms`),
>   the operator does NOT pick the group. *Steelman:* the DIRECT `@gwclaim` isomorph (the body re-used wholesale; as
>   built K drops the `gweight` read and serves the lane's full serviceable depth — `min(depth, glimit headroom)`, no
>   `size`); fairness is preserved BY CONSTRUCTION (the rotation still round-robins lanes — a batch is one lane's turn
>   served deep); carries emq.4.4-L1 (the interleaving witness is the natural proof); the smallest change. *Cost:* the
>   operator cannot target a specific tenant's backlog — bulk consume is fairness-driven, not caller-driven.
> - **Arm 2 — caller-named (true affinity).** `@gbclaim` takes a specific `group` (no `LMOVE`), serves a batch from
>   THAT lane; `bclaim/4` (`conn, queue, group, size, lease_ms`). *Steelman:* true "affinity" — a worker dedicated to
>   one tenant pulls THAT tenant's batch (the literal reading of "affinity"); a manual-pull host API (`Lanes.bclaim/N`,
>   the `claim_batch/4` analog) connotes caller-choice; simpler accounting (no ring interaction — just the lane's
>   `gactive`/`glimit`). *Cost:* fairness becomes the CALLER's responsibility (the ring is bypassed — a caller hammering
>   one lane starves others); INV-Fairness narrows to INV-Affinity-isolation (the batch serves ONLY the named lane); it
>   is NOT the `@gwclaim` isomorph (no `LMOVE`), so the body diverges more from the precedent.
> - **Arm 3 — BOTH (ring-rotated `bclaim/3` + caller-named `bclaim_group/4`).** Ship both host verbs over (Arm 1)
>   one `@gbclaim` that the host calls with-or-without a pre-selected group. *Steelman:* covers both use cases (fair
>   bulk-drain AND targeted tenant-pull). *Cost (why not):* two host verbs + a branchier script (the group either comes
>   from `LMOVE` or from ARGV) — more surface than the family's "one increment, one capability" rhythm warrants for a
>   composition rung; defer the second verb to a follow-up if a consumer needs it.
>
> **Steward → RULED Arm 1 (ring-rotated `bclaim/3`), D-1.** The direct `@gwclaim` isomorph (the smallest, lowest-risk
> change), fairness preserved by construction, the emq.4.4-L1 interleaving witness the natural proof. The Operator
> ruled ring-rotated; the caller-named Arm 2 (`bclaim/4` with a `group`, the codemojex / echo_bot dedicated-worker
> pull model) remains the recorded chosen-against alternative, available as a later additive follow-up if a consumer
> needs targeted tenant-pull. As built: `bclaim/3` `lanes.ex:403-416` (no `group`, no `size`), `@gbclaim` does the
> `LMOVE` at `lanes.ex:162`.

## Definition of Done

- [x] **FORK 5.3-A / 5.3-B / 5.3-C** surfaced with their four-part Arms + the risk trade-offs (the shipped `@gwclaim`
      re-probed byte-frozen); the Operator ruled all three via `AskUserQuestion` to their leans (D-1: 5.3-A additive
      `@gbclaim`, 5.3-B reuse `gactive`, 5.3-C ring-rotated `bclaim/3`); the body re-derived to the rulings (the
      affinity-claim home, the concurrency counter, the group-selection mechanism + the `bclaim/3` arity pinned).
- [x] The **affinity claim** built: the new inline `@gbclaim` (`lanes.ex:161-200` — a count-variant `ZPOPMIN` over one
      ring-rotated lane, **K = `min(lane depth, glimit headroom)`** — the `gweight` read dropped, no `size`, ONE
      server-clock `TIME` lease, `gactive += K`, the `@gwclaim` re-ring guard) + the `bclaim/3` host verb
      (`lanes.ex:403-416`, FORK 5.3-C ruled ring-rotated) → `{:ok, [{id, payload, attempts, group}, …]}` | `:empty`.
      Additive — every shipped `@g*`/`@bclaim` byte-frozen (INV-Frozen).
- [x] **Batch concurrency** built (FORK 5.3-B ruled reuse `gactive`): a batch counts its served members against the
      group's `gactive` (`HINCRBY ... gactive g k`, `lanes.ex:193`); the `glimit` headroom clamp guarantees no batch
      passes the ceiling (INV-Ceiling); a lane at its ceiling is de-ringed and serves `:empty`.
- [x] The **conformance scenarios** registered (additive minor — the prior **67** byte-unchanged; the count re-pinned
      **67 → 70** in BOTH pinning tests): `grouped_batch_affinity` (every member from the served group — INV-Affinity),
      `grouped_batch_ceiling` (the `glimit` headroom clamp — INV-Ceiling), and `grouped_batch_fairness`
      **carrying emq.4.4-L1** (a bounded-early-window interleaving witness under skew, NOT a terminal drain — the
      load-bearing no-op-defeater; the `starvation_drill` shape, `conformance.ex:2486`).
- [x] The proof: the `:valkey` affinity + ceiling + fairness scenarios green per-app; the **≥100 determinism loop**
      green (a mint/lease surface — the same-millisecond branded-`JOB` mint hazard); the **byte-freeze grep** on every
      shipped `@g*`/`@bclaim` = 0 (INV-Frozen); honest-row reporting (Valkey on 6390). **Apollo RECOMMENDED** (the
      fair-lanes composition risk — carry emq.4.4-L1; the evaluator re-runs the gate ladder + the interleaving witness).
- [x] INV-Affinity / INV-Ceiling / INV-ServerClock / INV-DeclaredKeys / INV-Frozen / INV-Determinism / INV-Fairness
      verified as runnable checks; the family contract ([`../emq.5.md`](../emq.5.md)) remains the carve authority; this
      body is authoritative (synced to the as-built post-build, Stage-5).

Family: [`../emq.5.md`](../emq.5.md) (the contract, the carve, the forks — the carve authority) · Rung stories +
brief: [`emq.5.3.stories.md`](emq.5.3.stories.md) · [`emq.5.3.llms.md`](emq.5.3.llms.md) · Runbook:
[`emq.5.3.prompt.md`](emq.5.3.prompt.md) · The as-built surface (SHIPPED by this rung):
`echo/apps/echo_mq/lib/echo_mq/lanes.ex` — `@gbclaim` (`lanes.ex:161-200` — one `LMOVE` ring step picks the group,
then **K = `min(ZCARD lane, glimit headroom)`** heads served in one atomic turn (the `gweight` read DROPPED, no
`size`), ONE server-clock lease `redis.call('TIME')`, `gactive += K`, the re-ring guard, a nested-array return) +
`bclaim/3` (`lanes.ex:403-416` → `{:ok, [{id, payload, attempts, group}, …]}` | `:empty`, paused-first) · The proven
shape it generalizes (SHIPPED — the near-isomorph, **byte-frozen** by this rung): `@gwclaim` (`lanes.ex:87-129` — the
same loop/lease/`gactive`/re-ring body, but K = `min(weight, ZCARD lane, glimit headroom)`) + `wclaim/3`
(`lanes.ex:281-294`) + `@gclaim` (`lanes.ex:37-61`, the single grouped claim) + `weight/4`/`limit/4`
(`lanes.ex:433,475` — the dynamic-rate knobs) · The flat spine it composes with (SHIPPED, **byte-frozen**):
`echo/apps/echo_mq/lib/echo_mq/jobs.ex` — `@bclaim` (`jobs.ex:200-219`) + `claim_batch/4` (`jobs.ex:520-539` → `{:ok,
[{id, payload, att}, …]}` | `:empty`, paused-first, non-blocking) + the byte-frozen `complete/5` (`jobs.ex:589`)/
`retry/7` (`jobs.ex:759`) the per-member settle rides · The fairness-witness precedent (SHIPPED, the emq.4.4-L1
pattern to follow): `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — `:starvation_drill` (`conformance.ex:1992-2073` —
the bounded-9-turn early-window `MapSet` interleaving witness + the per-member `ZSCORE active` lease check + the
terminal-drain liveness floor) + `:batch_claim` (`conformance.ex:2084-2130` — the size/mint-order/shared-lease batch
template) · The v2 laws: S-6 (declared keys — the A-1/L-1 lane-base-pins-the-slot law) · §4 (the server clock — the
lease in the claim) · S-1/§6 (the braced keyspace — no new key family) · S-3/§5 (the additive-minor conformance law)
· Design: [`../../../../emq.design.md`](../../../../emq.design.md) §6.2 (count-variant pops — the reserved mechanism) · The
sibling precedent (SHIPPED — the weighted multi-pop + emq.4.4-L1): [`../../emq.4/emq.4.rungs/emq.4.4.md`](../../emq.4/emq.4.rungs/emq.4.4.md)
· Roadmap: [`../../../../emq.roadmap.md`](../../../../emq.roadmap.md) (the emq.5 row · Movement II) · Approach:
[`../../../../../elixir/specs/specs.approach.md`](../../../../../elixir/specs/specs.approach.md)
