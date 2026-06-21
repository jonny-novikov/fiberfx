# EMQ.5 · Batches — the bulk-consume family (Movement II, the 2nd family)

> **Status: 🔨 IN PROGRESS — the family carve (this decomposition); the SPINE (emq.5.1) + the SHAPING (emq.5.2) + the GROUP-AFFINITY (emq.5.3) SHIPPED; only emq.5.4 (the finish) remains.** The voice is
> forward-tense for the unbuilt rungs ("emq.5.N builds…"); emq.5 is the **2nd Movement II family**, opening on a
> complete emq.4 groups family (4.1–4.4 CLOSED). It decomposes into **four sub-rungs** the way emq.2/emq.3/emq.4
> did; the per-rung triads under `./emq.5.rungs/` are a SEPARATE fan-out, authored when each rung is reached
> (Venus). This file is the **carve + the recommended topology**, not the per-rung spec.
>
> **emq.5.1 SHIPPED** (the spine landed; the three forks RULED — FORK 5.1-A → the LOOP, FORK 5.1-B → THREE
> scenarios / **conformance 61 → 64**, FORK 5.1-C → the short batch; rung label **2.5.0**, wire `@wire_version`
> frozen at `echomq:2.4.2`; `@bclaim` `jobs.ex:200-219` + `claim_batch/4` `jobs.ex:520-539`). **emq.5.2 SHIPPED** (the shaping cadence — `EchoMQ.BatchConsumer` + `BatchShaper.Core`; forks RULED D-1 → a new module, D-2 → a per-member verdict map; **conformance 64 → 67**; `60de5dc8`). **emq.5.3 SHIPPED** (the group-affinity batch — `@gbclaim` + `bclaim/3`, ring-rotated, the `@gwclaim` isomorph minus the `gweight` read; forks RULED D-1 → additive `@gbclaim` / reuse `gactive` / ring-rotated; **conformance 67 → 70**; the ≥100 loop 100/100; `a299aa73`). **emq.5.4
> now rides the shipped `@bclaim`/`@gbclaim`** — the per-rung carve table below stays the forward-looking decomposition
> authority for them.
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
  fencing token; `jobs.ex:165` the script, `jobs.ex:418` the host fn → `{:ok, {id, payload, att}}` on a hit, `:empty`
  on an empty pending set, the queue-wide pause honored host-side FIRST) — the spine generalizes this, returning a
  LIST of `{id, payload, att}` members.
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
| **emq.5.1 ✅ SHIPPED** | **the batch-claim spine** — `@bclaim` (count-variant `ZPOPMIN emq:{q}:pending` up to `size` under one `TIME`, one batch lease, attempts per member) + `Jobs.claim_batch/4` + the manual-pull host API; partial-failure isolation rides the shipped per-member `@complete`/`@retry` (a *tested* property, not new Lua) | `@claim` · `@gwclaim` (the proven multi-pop loop) · `emq:{q}:pending`/`active` | **M** | **NORMAL** (additive Lua, `@claim` byte-frozen) **+ the ≥100 determinism loop** (a mint/lease surface) | **Flat-L2** — Venus → Director ruled FORK 5.1-A → the LOOP / 5.1-B → THREE (conf 64) / 5.1-C → short batch → Mars build → Director verify PASS → done (zero remediation; Apollo optional, not run) |
| **emq.5.2 ✅ SHIPPED** | **`min_size`/`timeout` shaping** — `EchoMQ.BatchConsumer` (a NEW watch-depth process, a SIBLING of `Consumer` — D-1) flushes ONE batch when the size floor (`min_size`) or the latency ceiling (`timeout`) is reached, draining via the byte-frozen `@bclaim`/`claim_batch/4`; a **pure shaping core** `EchoMQ.BatchShaper.Core` (`decide/4`, injected clock); a per-member verdict map (absent → fail-safe retry — D-2); per-member events on the `EchoMQ.Events` seam | emq.5.1 · `EchoMQ.Consumer` (the lifecycle precedent) · `EchoMQ.Events` | **M** | **NORMAL** (new supervised process + pure core; **no new Lua/lease**) | **Flat-L2** — Venus → Director ruled D-1/D-2/D-3 → Mars build → Director verify PASS (mutation spot-check net-zero) → **Mars-2 collapsed** (right-size, zero findings); conf 67, `60de5dc8` |
| **emq.5.3 ✅ SHIPPED** | **group-affinity batch** — `@gbclaim` (a NEW additive lane script — D-1) rotates the ring (`LMOVE`) and serves a HOMOGENEOUS batch from the landed lane up to the `glimit` headroom (ring-rotated, no caller group — D-1 5.3-C; the `@gwclaim` isomorph minus the `gweight` read, K = min(depth, headroom)) + `Lanes.bclaim/3`; reuse `gactive` (D-1 5.3-B) | emq.5.1 · **the CLOSED emq.4 ring** (`@gwclaim`/`gactive`/`gweight`) | **M–L** | **NORMAL+** (additive `@gbclaim`; shipped `@g*`/`@bclaim` byte-frozen) | **Flat-L2 + Apollo** — Venus → Director ruled D-1 (3 forks; 5.3-C NEW, surfaced at reconcile) → Mars build → Director verify PASS (declared-keys + byte-freeze battery + a mutation 6/10 + the ≥100 loop 100/100) → Mars-2 (the label fix); conf 70, `a299aa73` |
| **emq.5.4 — RULED B · T · N** | **the partitioned finish + dynamic delay** — a batch resolves as a **partition** `%{completed, retried, dead, delayed}` via the shipped per-member transitions (a NEW pure `EchoMQ.BatchFinish.partition/N` — D-3 = Arm N; `dead` EMERGES from `@retry` `{:ok, :dead}`, not a caller verdict); `Jobs.delay/5` re-scores an active member onto the schedule set via a NEW minimal atomic `@delay` (D-1 = Arm B — `ZREM active` / `HSET state=scheduled` attempts-PRESERVED / `ZADD schedule`, the inverse of `@claim`), token-fenced on the attempts-token (D-2 = Arm T). *(The carve's earlier "reuse `@schedule` / zero new Lua" lean was CORRECTED at reconcile — `@schedule` is a first-write that cannot re-score an active member.)* | `@complete`/`@retry`/`@schedule`/`@promote` (all **byte-frozen**, the reuse targets) · `EchoMQ.BatchConsumer` `defp settle` (the `{:delay, ms}` branch) · emq.5.1 | **M** | **NORMAL** (one NEW additive `@delay` script — the inverse of a claim, releases a lease; reuses the byte-frozen transitions; **no new lease surface**) | **Flat-L2** — Venus author+reconcile → Director rules FORK 5.4-A (RULED B · T · N) → Mars build → Director verify (byte-freeze the reused scripts + the declared-keys/attempts-preserved/atomicity/token-fence probes) → Mars-2. Apollo optional |

**Family total ≈ 4 rungs, ~4–5 rung-points** (comparable to emq.4). **One new additive Lua script per CLAIM rung**
(`@bclaim` at 5.1, `@gbclaim` at 5.3) **plus one for the RESOLVE half** (`@delay` at 5.4, RULED D-1 = Arm B — the
inverse of a claim); **zero new Lua in 5.2** (the shaping cadence is a supervised process + a pure core). *(The earlier
"zero new Lua in 5.2 and 5.4" read was corrected at the emq.5.4 reconcile: 5.4's `@delay` is the symmetric resolve-half
script — the atomic active→scheduled re-score `@schedule` cannot express.)*

## 2 · Build order & dependencies

```
emq.5.1  batch-claim spine   ──►  everything below builds on @bclaim
   ├─► emq.5.2  shaping ✅    (rides 5.1; independent of 5.3)
   ├─► emq.5.3  affinity ✅   (rides 5.1 + the CLOSED emq.4 ring)
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
  not edits to a shipped one); the `mix.exs` **rung label** climbs (emq.5.1 RULED **`2.5.0`**, opening the family).
  The `:fence` scenario + `connector_test` stay version-agnostic.
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
- **FORK 5.4-A — dynamic delay (RULED B · T · N, D-1/D-2/D-3).** The reconcile CORRECTED this fork's original "reuse
  `@schedule`" lean: `@schedule` (`jobs.ex:55-73`) is a FIRST-WRITE (an `EXISTS` guard that no-ops a present row + an
  `attempts 0` reset) — it CANNOT re-score an active member. **RULED: D-1 = Arm B** a NEW minimal atomic `@delay`
  (active → schedule, attempts-PRESERVED, the inverse of `@claim`) — chosen over Arm A′ (a host two-step — NON-ATOMIC,
  lost-member window) and Arm C (fold into `@promote` — wrong direction, edits a frozen script); **D-2 = Arm T**
  `delay/5` token-fenced on the attempts-token (over Arm F token-free); **D-3 = Arm N** a NEW pure
  `EchoMQ.BatchFinish.partition/N` (over Arm X — folding into the private `defp settle`, a process IO method). The
  per-rung body [`./emq.5.rungs/emq.5.4.md`](./emq.5.rungs/emq.5.4.md) carries the full four-part Arms + the KB record
  [`../../../kb/emq-5-4-decisions.md`](../../../kb/emq-5-4-decisions.md).

## 5 · Map

- The family abstract + scope: [`../../../emq.features.md`](../../../emq.features.md) §C.3 (Batches) · the mechanism
  reservation: [`../../../emq.design.md`](../../../emq.design.md) §6.2 (count-variant pops).
- The roadmap row + the ladder: [`../../../emq.roadmap.md`](../../../emq.roadmap.md) (emq.5).
- The proven shape it generalizes: emq.4.4 `@gwclaim` ([`../emq.4/emq.4.rungs/emq.4.4.md`](../emq.4/emq.4.rungs/emq.4.4.md)).
- The per-rung triads (a SEPARATE fan-out, authored at build time): `./emq.5.rungs/emq.5.1.md` … `emq.5.4.md`.
