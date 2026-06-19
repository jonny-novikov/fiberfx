# EMQ.5 · Batches — the bulk-consume family (Movement II, the 2nd family)

> **Status: 📐 PROPOSED — the family carve (this decomposition), NOT built.** The voice is forward-tense
> ("emq.5.N builds…"); no batch-*consume* surface exists on disk yet. emq.5 is the **2nd Movement II family**,
> opening on a complete emq.4 groups family (4.1–4.4 CLOSED, conformance 61). It decomposes into **four sub-rungs**
> the way emq.2/emq.3/emq.4 did; the per-rung triads under `./emq.5.rungs/` are a SEPARATE
> fan-out, authored when each rung is reached (Venus). This file is the **carve + the recommended topology**, not
> the per-rung spec.
>
> **Risk (forward): UNIFORM NORMAL.** Every rung is **additive over proven mechanisms** — the multi-pop is the
> shipped `@gwclaim` shape, the shaping is a supervised process with a pure core, the affinity rides the now-complete
> fair-lanes ring, the finish reuses the byte-frozen `@complete`/`@retry`/`@schedule`. No destructive at-rest op, no
> wire break; batches is lower-risk than the emq.4 groups family (which carried a destructive drain + a new process
> surface). The one elevated point is **emq.5.3** (the fair-lanes composition) where **Apollo is recommended** to
> carry the emq.4.4-L1 fairness-witness craft forward.

## 0 · The as-built floor — what "batches" stand on

Batches are a Movement II **consume** family. The **PRODUCE half already ships** and is NOT re-built here:
`EchoMQ.Jobs.enqueue_many/3` (bulk enqueue, emq.1/emq.2.2). What emq.5 builds is the **batch CONSUME** family — a
worker that fetches up to *N* jobs in one atomic claim instead of one at a time, amortizing the per-job round-trip
and lease bookkeeping across the batch.

The mechanism is **reserved, not invented** (design `emq.design.md` §6.2, lines 457–464): *"Count-variant pops
remain the 6.2-level surface the batch family builds on at its rung."* A batch claim is a **count-variant
`ZPOPMIN` INSIDE the claim script** — never a client-side `LMPOP`/`ZMPOP` (those are rejected by design because a
client pop bypasses the script layer's atomic event/bookkeeping path). The just-shipped **`@gwclaim` (emq.4.4)
already proves the exact shape**: it loops `ZPOPMIN lane` *K* times under one server-clock `TIME` read, leasing the
whole batch on one deadline. emq.5.1 is the non-grouped generalization of that proven loop.

What each axis stands on (all SHIPPED, present-tense):

- `EchoMQ.Jobs.claim/3` + `@claim` (the single `ZPOPMIN emq:{q}:pending` claim, server-clock lease, attempts as the
  fencing token) — the spine generalizes this.
- `EchoMQ.Lanes` + the ring (`emq:{q}:ring`) + `@gwclaim`/`@gclaim` + `emq:{q}:gactive`/`gweight` — the affinity +
  concurrency rung composes with this (emq.4, CLOSED).
- `EchoMQ.Consumer` (the park-don't-poll loop; the emq.4.3 `EchoMQ.Metronome` dispatch) — the shaping rung extends
  this.
- `EchoMQ.Events` (the host pub/sub seam) — batch lifecycle events register here, additive-minor.
- `@complete`/`@retry` (per-member resolution) + `@schedule`/`enqueue_at` (the schedule fence) — the partitioned
  finish + dynamic delay reuse these **byte-frozen**.

## 1 · The carve (size + recommended topology)

Each headline item in the roadmap's emq.5 row — *bulk consumption · `min_size`/`timeout` shaping · affinity · the
partitioned finish* — becomes one sub-rung, in the spine→shaping→composition→capstone shape emq.4 used.

| Rung | Ships (PROPOSED) | Stands on | Size | Risk | Recommended topology |
|---|---|---|---|---|---|
| **emq.5.1** | **the batch-claim spine** — `@bclaim` (count-variant `ZPOPMIN emq:{q}:pending` up to `size` under one `TIME`, one batch lease, attempts per member) + `Jobs.claim_batch/4` + the manual-pull host API; partial-failure isolation rides the shipped per-member `@complete`/`@retry` (a *tested* property, not new Lua) | `@claim` · `@gwclaim` (the proven multi-pop loop) · `emq:{q}:pending`/`active` | **M** | **NORMAL** (additive Lua, `@claim` byte-frozen) **+ the ≥100 determinism loop** (a new mint/lease surface) | **Flat-L2** — Venus → Director rules FORK 5.1-A → Mars build+self-verify → Director verify (declared-keys + byte-freeze + ≥100 loop) → Mars-2 harden. Apollo optional |
| **emq.5.2** | **`min_size`/`timeout` shaping** — a batch-aware `EchoMQ.Consumer` mode that waits for ≥ `min_size` OR until `timeout`, then drains via `@bclaim`; a **pure shaping core** (accumulate/flush, injected clock); batch lifecycle events on the `EchoMQ.Events` seam | emq.5.1 · `EchoMQ.Consumer`/`Metronome` · `EchoMQ.Events` | **M** | **NORMAL** (new supervised process + pure core; **no new Lua/lease**) | **Flat-L2** (a candidate **right-size collapse** — no wire/Lua, so Director may collapse Mars-2 if Stage-2 verify is clean). Apollo optional |
| **emq.5.3** | **group affinity + batch concurrency + dynamic rate** — `@gbclaim` (a homogeneous lane-scoped batch, additive beside `@gwclaim`); one in-flight batch per group (reuse `gactive` semantics); runtime-mutable rate on the emq.4 floor | emq.5.1 · **the CLOSED emq.4 ring** (`@gwclaim`/`gactive`/`gweight`) | **M–L** | **NORMAL+** (composes with the fairness ring; **additive `@gbclaim` keeps it NORMAL+ — an `@gwclaim`/`@gclaim` edit would force HIGH**) | **Flat-L2 + Apollo RECOMMENDED** — carry **emq.4.4-L1** (a fair-share property needs a bounded-early-window interleaving witness, not a terminal drain). Director verify = declared-keys + byte-freeze battery on the new lane script |
| **emq.5.4** | **the partitioned finish + dynamic delay** — a batch resolves as a **partition** (complete / retry-poison-alone / dead) via the shipped per-member transitions; `Jobs.delay/N` re-scores an active member onto the schedule set from the handler | `@complete`/`@retry` · `@schedule`/`enqueue_at` (all **byte-frozen**) · emq.5.1 | **M** | **NORMAL** (reuses shipped, byte-frozen transitions; **no new lease surface**) | **Flat-L2** — Venus → Director → Mars → Director verify (byte-freeze the reused scripts) → Mars-2. Apollo optional |

**Family total ≈ 4 rungs, ~4–5 rung-points** (comparable to emq.4). One new additive Lua script per claim rung
(`@bclaim`, `@gbclaim`); zero new Lua in 5.2 and 5.4.

## 2 · Build order & dependencies

```
emq.5.1  batch-claim spine   ──►  everything below builds on @bclaim
   ├─► emq.5.2  shaping       (rides 5.1; independent of 5.3)
   ├─► emq.5.3  affinity      (rides 5.1 + the CLOSED emq.4 ring)   ◄── Apollo recommended
   └─► emq.5.4  finish        (rides 5.1 + byte-frozen @complete/@retry/@schedule)
```

- **5.1 is the spine** — it must land first; 5.2/5.3/5.4 each ride `@bclaim`.
- **5.3 was gate-blocked on emq.4** ("affinity gates on emq.4's deepened rotation" — features.md C.3 §Scope). **emq.4
  is now CLOSED, so 5.3 is UNBLOCKED** — a direct dividend of this reconcile's family fold.
- 5.2, 5.3, 5.4 are mutually independent (all ride only 5.1) — the program ships one rung per run, but the Operator
  may re-order 5.2↔5.3↔5.4 freely after 5.1.

## 3 · Family version & conformance posture

- **Additive minors, 2.x line.** Each rung grows the conformance count from **61** (+ batch scenarios, prior
  byte-unchanged, re-pinned in both pinning tests) and is a host-verb/script addition — no new wire class.
- **The two planes hold (the emq.4.3-D4 model).** The wire `@wire_version` stays **frozen at `echomq:2.4.2`** unless
  a rung genuinely changes claim wire-behavior (none is foreseen — `@bclaim`/`@gbclaim` are additive *new* scripts,
  not edits to a shipped one); the `mix.exs` **rung label** climbs (the Operator's call — `2.5.0` opens the family,
  or continue `2.4.5`+). The `:fence` scenario + `connector_test` stay version-agnostic.
- **Determinism posture per rung:** 5.1 and 5.3 are **mint/lease surfaces → the ≥100 determinism loop** (the
  same-millisecond branded-`JOB` mint hazard the loop owns). 5.2 and 5.4 introduce **no new mint/lease** → a
  multi-seed sweep + an honest posture statement (5.2's only nondeterminism is the shaping timer, isolated in the
  pure core with an injected clock).

## 4 · Forks (open Operator decisions — settle at each rung's pre-build reconcile)

Framed forward; each is the architect's four-part Arm at the rung, ruled via `AskUserQuestion` before that build.

- **FORK 5.1-A — the count mechanism.** `ZPOPMIN emq:{q}:pending <count>` (the native count arg, one call) **vs** a
  `ZPOPMIN`-loop (the shipped `@gwclaim` shape, per-member attempts/lease bookkeeping in the loop). *Lean:* the loop,
  for symmetry with `@gwclaim` and per-member fencing.
- **FORK 5.2-A — the shaping home.** A batch-aware **mode on `EchoMQ.Consumer`** (additive) **vs** a new
  `EchoMQ.BatchConsumer` process. *Lean:* a mode on the shipped Consumer.
- **FORK 5.3-A — the affinity claim (risk-deciding).** An **additive `@gbclaim`** (NORMAL+, `@gwclaim`/`@gclaim`
  byte-frozen) **vs** extending `@gwclaim` to a batch-return (edits a frozen fairness script → **HIGH** + byte-freeze
  every other lane script + Apollo mandatory). *Lean:* additive `@gbclaim`.
- **FORK 5.3-B — the batch-concurrency home.** Reuse **`gactive`** (a batch counts as its `size` against the group
  ceiling) **vs** a new `gbatch` in-flight counter. *Lean:* reuse `gactive` (no new key, the §6 grammar unedited).
- **FORK 5.4-A — dynamic delay.** A new `Jobs.delay/N` re-score (active → schedule, reusing `@schedule`) **vs** fold
  into the shipped promote/schedule surface. *Lean:* a thin `delay/N` over the byte-frozen schedule fence.

## 5 · Map

- The family abstract + scope: [`../../../emq.features.md`](../../../emq.features.md) §C.3 (Batches) · the mechanism
  reservation: [`../../../emq.design.md`](../../../emq.design.md) §6.2 (count-variant pops).
- The roadmap row + the ladder: [`../../../emq.roadmap.md`](../../../emq.roadmap.md) (emq.5).
- The proven shape it generalizes: emq.4.4 `@gwclaim` ([`../emq.4/emq.4.rungs/emq.4.4.md`](../emq.4/emq.4.rungs/emq.4.4.md)).
- The per-rung triads (a SEPARATE fan-out, authored at build time): `./emq.5.rungs/emq.5.1.md` … `emq.5.4.md`.
