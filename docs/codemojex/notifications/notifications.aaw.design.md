# codemojex Broadcast System — the pragmatic / code-first design (Venus-2)

> **Status:** DESIGN (Venus-2, the SECOND architect in the AAW multi-architect debate —
> [`aaw.architect-approach.md` §"The multi-architect debate"](../../aaw/aaw.architect-approach.md)).
> DESIGN/SPEC ONLY — no production code, no git.
> **Lens:** pragmatic delivery / code-first ([`AAW_DEVELOPMENT.md`](../../AAW_DEVELOPMENT.md) — *rigor is
> constant; ceremony scales to the work*). This doc is the **contrast** to Venus-1's spec-steward / BCS-invariant
> design ([`notifications.design.md`](notifications.design.md)) — it argues the SAME requirements from a divergent
> lens, surfaces the KEY forks as four-part arms, and ranks them. It does **not** decide; the Director stages the
> disagreement and the Operator rules.
> **Grounding:** the reconcile (§1) is re-verified at the cited `file:line` — not inherited. Unshipped surface is
> forward-tense. Contracts are linked, never restated.

## 0. The one-paragraph recommendation

Build the Broadcast system as **four code-first slices over the persistence substrate codemojex already runs
(Postgres `Repo`), with the audience/counters in Valkey**, and reach the global rate cap by **retuning the
existing in-memory `Codemojex.RateLimiter` to 27/s today** while **deferring the cluster-wide Valkey throttle to
a named horizon decision** — because the deployment is single-node *now* and a cluster-wide wire primitive is a
HIGH-risk frozen-grammar touch whose cost should not ride a delivery rung. The entities are **plain Ecto schemas
+ a small `Broadcast` server**, not four branded BCS components — the contract here is *deliverability*, not
*identity-across-a-boundary*, so the brand earns its keep only on the one id that genuinely crosses to Valkey
counters. Persistence is **counters-first**: a `broadcast_deliveries` row only for the *actionable* (failed)
recipients, live tiles in Valkey, and **compaction added only if the row count proves it needed** — not as
founding machinery. This is a recommendation (advice), not a ruling.

The divergences from Venus-1 are four; each is surfaced below as a four-part arm (Rationale · 5W · Steelman ·
Steward), ranked, each pre-empting the spec-steward lens's strongest objection. §6 is the explicit
"where I diverge from Venus-1 and why" table.

---

## 1. Reconcile — re-verified, not inherited

Venus-1's reconcile (`notifications.design.md` §1) is **accurate** — every `file:line` I re-checked holds. Three
facts are load-bearing for *this* lens and bear restating with their consequence drawn out:

| Fact (re-verified) | `file:line` | Consequence for the pragmatic lens |
|---|---|---|
| `Codemojex.RateLimiter` global rate/burst default **30/30**, **but `start_link` reads `:global_rate`/`:global_burst` opts** | [`rate_limiter.ex:48-52`](../../../echo/apps/codemojex/lib/codemojex/rate_limiter.ex) | Retuning to 27/s is a **config change**, not new code (see next row). |
| The limiter is started as a **bare child spec** `Codemojex.RateLimiter` (no opts) | [`application.ex:28`](../../../echo/apps/codemojex/lib/codemojex/application.ex) | Retune = change that one child spec to `{Codemojex.RateLimiter, global_rate: 27, global_burst: 27}`. **One line.** No new module, no Lua, no conformance bump, no Apollo gate. |
| **Single-node today** — NO `libcluster`/`flame` dep in `codemojex/mix.exs`; ONE `RateLimiter` + ONE of each `EchoMQ.Consumer` started | [`mix.exs`](../../../echo/apps/codemojex/mix.exs) (no cluster dep) · [`application.ex:21-46`](../../../echo/apps/codemojex/lib/codemojex/application.ex) | An in-memory global cap is **correct on one node**. The cluster-wide cap is a horizon need (multi-node is *anticipated* via the volume-conditional Graft committer, `application.ex:99`), not a *delivery* need. |
| `Codemojex.Repo` + six Ecto schemas + the `Store.upsert/3` precedent + a `Player` schema | [`repo.ex`](../../../echo/apps/codemojex/lib/codemojex/repo.ex) · [`schemas/player.ex`](../../../echo/apps/codemojex/lib/codemojex/schemas/player.ex) · [`store.ex:1`](../../../echo/apps/codemojex/lib/codemojex/store.ex) | Postgres is the **established** persistence substrate. `RecipientGroup.all` has a real source (`Player`). A new schema is a *mirror of a shipped pattern*, not new infrastructure. |

The send-path primitives Venus-1 cites are all real and re-verified:
[`Jobs.enqueue_many/4`](../../../echo/apps/echo_mq/lib/echo_mq/jobs.ex) (`jobs.ex:124`, batches in one flush,
per-item verdicts in input order), `enqueue_in/5` (`:95`), `enqueue_at/6` (`:84`),
[`Repeat.register/6`](../../../echo/apps/echo_mq/lib/echo_mq/repeat.ex) (`repeat.ex:58`),
[`Flows.add/3`](../../../echo/apps/echo_mq/lib/echo_mq/flows.ex) (`flows.ex:219`) + `children_values/3` (`:534`).
`EchoMQ.Throttle` does **not** exist (a `find` over `apps/` returns nothing) — confirmed new surface.
`EchoMQ.Conformance.run/2 → {:ok, 59}` ([`conformance_run_test.exs:48`](../../../echo/apps/echo_mq/test/conformance_run_test.exs)).

**Where the lens already bites:** two of Venus-1's six rungs (the retune-adjacent throttle work and the
compaction machinery) are, under the as-built single-node reality, either *cheaper than a new primitive* or
*not-yet-earned*. That is the whole argument, and §2 makes it as arms.

---

## 2. The forks — four-part arms, ranked

Four forks where the pragmatic lens genuinely diverges. Ranked by **how much the divergence matters to the
Operator's cost** (A highest). Each arm is argued Rationale · 5W · Steelman · Steward; each pre-empts the
spec-steward lens's best objection so the synthesis inherits the rebuttal.

> **Ranking:** **A** (the rate cap — a HIGH-risk wire touch vs a one-line retune) · **B** (the entity model —
> 4 branded components vs plain schemas) · **C** (persistence — found-compaction vs counters-first) · **D** (the
> build decomposition — a 6-rung triad ladder vs 3 code-first slices). A and B are the load-bearing forks; C and
> D largely follow once A and B are ruled.

---

### Fork A — the 27/s global cap: a new Valkey wire primitive, or retune-now / defer-the-primitive?

This re-opens Venus-1's **D-1** (the Operator ruled Valkey for her framing; the pragmatic lens re-argues it, the
Operator re-rules — this is exactly the "a later lens may re-argue a ruled fork" case the approach allows). Three
arms.

#### Arm A1 — **Retune the in-memory limiter to 27/s now; defer the cluster-wide primitive to a named horizon decision** (RECOMMENDED)

**Rationale.** The deployment is single-node today (`application.ex` starts ONE `RateLimiter`; no cluster dep).
On one node, the in-memory global bucket **is** the cluster-wide cap — there is no second node for it to be wrong
on. The cap the requirement names (27/s = 90% of 30) is reached by changing the limiter's start opts from the
30/30 default to `global_rate: 27, global_burst: 27` — a one-line child-spec edit
([`application.ex:28`](../../../echo/apps/codemojex/lib/codemojex/application.ex), the opts already exist at
`rate_limiter.ex:48-52`). The cluster-wide Valkey throttle is real *future* work; it is fused onto this delivery
only by the assumption that multi-node is imminent, which the tree does not show
([`AAW_DEVELOPMENT.md` §5](../../AAW_DEVELOPMENT.md) — *don't fuse a horizon decision into a delivery rung*).

**5W.**
- **Why** — the cap is needed *today* and reachable *today* without touching the frozen wire; the
  cluster-correct version is needed *when a second node exists*, which is a separate, schedulable unit.
- **What** — (now) the limiter's start opts retuned to 27/27 + a one-line config note; (deferred) a named horizon
  decision "cluster-wide send cap" recorded in the roadmap's Seams, built when multi-node lands.
- **Who** — the notification worker consumes the limiter unchanged (`RateLimiter.take/2`,
  [`notification_worker.ex:51`](../../../echo/apps/codemojex/lib/codemojex/notification_worker.ex)); the Operator
  owns the horizon decision.
- **When** — the retune ships in the first slice (S1, §3); the primitive is *not on this ladder* — it is a
  Seam.
- **Where** — `codemojex/lib/codemojex/application.ex` (the child spec) only. **Zero echo_mq / echo_wire edit.**

**Steelman.** The cheapest correct thing is a one-line edit to a *shipped, tested* token bucket whose math is
already the right shape (lazy refill, global + per-chat composed, `{:wait, ms}` the worker already handles). It
adds **no new public surface, no new Lua, no conformance scenario, no frozen-grammar touch, and removes the
HIGH-risk tier and the mandatory-Apollo gate from the critical path** — the rate cap drops from Venus-1's
single most expensive rung to a config line. The 27/s cap is *exactly* honored on the only node that exists. When
the second node arrives, the cluster-wide primitive is built deliberately, as its own rung, with the design
attention a frozen-wire change deserves — *better* attention than it gets riding a notification delivery, because
it is not racing a product feature. The single-node-correctness claim is not a hope: the limiter refills from
`System.monotonic_time` per node (`rate_limiter.ex:107`), so on one node its global bucket is the global cap by
construction.

**Steward.** Multi-year cost: **near zero added surface** — no module to freeze, no invariant to age, no
conformance count to re-pin, nothing new composing with the frozen `{emq}:` grammar. The honest debt: the cap is
**silently wrong the day a second node starts** — two nodes each admit 27/s = 54/s, over Telegram's 30. The
Steward's mitigation is the named Seam: the horizon decision is *recorded*, not forgotten, so multi-node cannot
ship without confronting it. The value honored is **Thin but robust** (the smallest change that is correct for
the deployment that exists) and **Do no harm** (the frozen wire is untouched). The value at risk is **Grounded
for the future** — and the mitigation is to ground the *decision* (the Seam) even though the *code* waits.

**Pre-empting the spec-steward objection.** Venus-1's strongest objection: *"single-node-correct is a trap —
the moment codemojex scales out, the cap silently double-counts and breaches Telegram's limit, and the failure
is invisible until production throttles you; the safe design builds the cluster-wide cap once, correctly, so
scale-out is a non-event."* The rebuttal is **already on the page** and has two parts. (1) A breach is **loud,
not silent**: Telegram answers `429` with `parameters.retry_after`, which the existing path already classifies
as retryable ([`echo_bot.ex:46`](../../../echo/apps/codemojex/lib/codemojex/echo_bot.ex)) — so an over-cap
multi-node deploy *self-throttles via backpressure*, it does not lose messages; the worst case is degraded
throughput, not data loss, and it is observable in the failure counters this design ships (§4). (2) The Seam
makes scale-out *not* a non-event but a *gated* event: "cluster-wide send cap" is a named horizon decision the
Operator must rule before multi-node ships — so the safety Venus-1 wants is preserved as a **decision gate**
rather than as **founding code that may never run** (if codemojex stays single-node, the primitive is pure
carrying cost). The disagreement reduces to a clean question for the Operator: *is multi-node imminent enough to
build the cap now, or is it a horizon to gate?* — which is precisely the fork to surface, not decide.

#### Arm A2 — **Build the Valkey `EchoMQ.Throttle` primitive now** (Venus-1's D-1, carried for the comparison)

**Rationale.** If multi-node is imminent (or the Operator wants the cap correct-by-construction regardless of
node count), a server-clock token bucket in Valkey is the only cluster-wide-correct home. This is Venus-1's
ruled position; it is carried here as a *seriously-argued* arm, not a strawman.

**5W.**
- **Why** — to make the global cap correct on N nodes, not 1.
- **What** — a new `EchoMQ.Throttle` (`take/3..4 → :ok | {:wait, ms}`), one inline `Script.new/2` keyed by
  server `TIME`, +1 conformance scenario re-pinned `{:ok, 59} → {:ok, 60}`.
- **Who** — the worker calls `Throttle.take/4` before the per-chat limiter; the echo_mq program owns the new
  surface forever.
- **When** — a HIGH-risk echo_mq rung, Apollo-mandatory, before the send-path rung that uses it.
- **Where** — `echo/apps/echo_mq` + the `{emq}:throttle:<name>` keyspace under the wire master invariant.

**Steelman.** Correct on day one for any deployment; the cap can never double-count. It composes with the
existing per-chat `RateLimiter` (which stays for the no-round-trip per-chat 1/s). The throttle is genuinely
reusable — *any* future global-rate need (not just broadcasts) has a home. If codemojex is *known* to be going
multi-node, building it now avoids a second pass and a migration of live traffic from the in-memory cap.

**Steward.** This is a **new frozen wire surface** under the v2 master invariant — the most expensive kind of
addition codemojex can make. It adds a conformance scenario (re-pinned in two pinning tests), a keyspace under
the braced grammar, a Lua body that must byte-freeze on every later re-drive, and a HIGH-risk gate (the
blast-radius / declared-keys / server-clock battery) on a *notification* feature. It is carried forever even if
codemojex never scales out. The Steward's verdict: **correct, but priced for a need the tree does not yet show**
— a multi-year liability taken on speculatively.

**Pre-empting the pragmatic objection (the mirror).** The pragmatic lens's objection to A2: *"you are paying a
frozen-wire liability for a node that does not exist."* A2's honest rebuttal: *if* the Operator knows multi-node
is on the near roadmap, the retune is throwaway work and a live-traffic migration later, so paying once now is
cheaper end-to-end. The fork is therefore decided by **one fact only the Operator holds**: the multi-node
horizon.

#### Arm A3 — **Retune now AND a behind-an-interface seam for the future primitive** (the hedge)

**Rationale.** Take A1's retune, but route the worker's global-cap check through a tiny indirection
(`Codemojex.SendCap.take/1`) whose only implementation today *is* the in-memory limiter — so swapping in the
Valkey throttle later is a one-module change with no worker edit.

**5W / Steelman (brief).** **Why** — minimize the future migration cost without paying the primitive now.
**What** — a thin `SendCap` wrapper + the A1 retune. **Steelman** — the worker never learns which cap it talks
to; the horizon swap touches one file. It is the classic "defer the decision, not the seam."

**Steward.** The honest cost: a **speculative abstraction** — an indirection built for a swap that may never
happen ([`AAW_DEVELOPMENT.md` §9](../../AAW_DEVELOPMENT.md) — *am I overbloating?*). The worker calling
`RateLimiter.take/2` directly is already a one-line call site; wrapping it earns little and adds a layer to
read. **The pragmatic lens mildly disfavors A3**: YAGNI says add the seam *when* the second implementation is
real, not before. Carried because it is the honest middle, but ranked below A1.

**Fork A surface.** A1 (retune now, defer the primitive as a Seam) vs A2 (build the primitive now) vs A3 (retune
+ a hedge seam). **Recommendation: A1** — the one reason that carries it: *the cap is exactly correct for the
deployment that exists, at the cost of one config line and zero frozen-wire risk, and the future need is
preserved as a gated decision rather than as code that may never run.* The Operator holds the deciding fact
(the multi-node horizon) and re-rules D-1.

---

### Fork B — the entity model: 4 branded BCS components, or the leanest code-first shape?

#### Arm B1 — **Plain Ecto schemas + one small `Broadcast` GenServer; brand ONLY the id that crosses to Valkey** (RECOMMENDED)

**Rationale.** The BCS law earns its ceremony when *identities cross an encapsulation boundary and the brand is
checked at every ingress* (`mesh.8.1`). Here, three of the four entities (`BroadcastTemplate`, `Broadcast`,
`RecipientGroup`) live **entirely inside codemojex** — they are written and read by codemojex code, persisted to
codemojex's own Postgres, never gated across a system boundary. A branded snowflake + a `Bcs.gate` namespace
buys nothing for a row that never leaves the app. The one entity whose id *does* cross a boundary is the
**broadcast id**, because it keys the Valkey counter hash (`cm:bcast:rollup:{id}`) — that one is worth a brand
(`BCA`) so the counter key is typed and time-ordered. The rest are **plain Ecto schemas** mirroring the six
codemojex schemas already shipped ([`schemas/`](../../../echo/apps/codemojex/lib/codemojex/schemas/)), and the
run-time aggregation is **one small `Codemojex.Broadcast` GenServer** (the state machine), not a branded
component system.

**5W.**
- **Why** — match the ceremony to where the boundary actually is; the brand is a typed cross-boundary thread,
  and only one id crosses.
- **What** — `Codemojex.Schemas.{BroadcastTemplate, Broadcast, RecipientGroup, BroadcastDelivery}` (plain Ecto)
  + a `Codemojex.Broadcast` GenServer for the live run; the broadcast id is a `BCA` branded snowflake
  ([`EchoData.BrandedId.generate!/1`](../../../echo/apps/echo_data/lib/echo_data/branded_id.ex)), the others use
  Ecto's own ids.
- **Who** — codemojex code writes/reads all four; only the Valkey counter layer sees the `BCA` id.
- **When** — slice S1 (§3).
- **Where** — `codemojex/lib/codemojex/schemas/` + `codemojex/lib/codemojex/broadcast.ex`.

**Steelman.** This is the leanest shape that satisfies the contract. It mirrors a **shipped, tested** pattern
(the six existing Ecto schemas + `Store.upsert/3`) — a new schema is transcription, not invention, so it ships
fast and is reviewed against a known template. The Operator's named entities
(BroadcastTemplate/Broadcast/BroadcastDelivery/RecipientGroup) are *exactly* the four schemas — the model is
1:1 with the requirement, no translation layer. The one brand that exists (`BCA`) is where it pays: a typed,
time-ordered Valkey key. The run-time machine is a GenServer — the BEAM's native unit for "a process owning
private state that mutates as events arrive" — which is what the aggregation *is*, without the BCS gate
ceremony around data that never crosses a boundary.

**Steward.** Multi-year cost: **low and familiar** — four Ecto schemas age like the six already in the tree;
one GenServer is a standard OTP child. No new branded namespace to track beyond `BCA` (free, verified against
the taken set). The honest debt: if codemojex *later* needs these entities to cross into another system (a
separate dashboard service, an external audience manager), the plain schemas would need branding then — but
that is a known, local refactor (add a brand column, gate the new boundary) done *when the boundary is real*,
not pre-paid. The value honored: **Thin but robust** and **One authority** (the Ecto schema is the single shape;
no parallel component-bundle definition). The value deferred: full BCS uniformity — accepted, because uniformity
for its own sake is ceremony where no boundary demands it.

**Pre-empting the spec-steward objection.** Venus-1's strongest objection: *"codemojex sits in the BCS stack;
modeling the Broadcast entities as anything other than branded components is an inconsistency that erodes the
law — the whole point of mesh.8.1 is that the brand is the type checked at every boundary, and a plain Ecto row
is exactly the 'embedded id list / object graph' the law forbids."* Two-part rebuttal, on the page. (1) The law
is scoped to **values that cross a system boundary** — `mesh.8.1`: *"the only values that cross a boundary are
identities and messages about identities."* A `BroadcastTemplate` row read and written only by codemojex's own
Repo **never crosses a boundary**, so the law does not bind it; applying the brand there is cargo-culting the
form without the substance. (2) Where a value *does* cross — the broadcast id into the Valkey counter key, and
the failure feedback into the audience — **this design IS BCS-faithful**: the counter key is the branded `BCA`
id (a typed identity crossing to the store), and the 403 feedback is *a message about identities* (the
suppressed recipient ids), exactly the law's shape (§4, §5). So the disagreement is not "BCS vs not-BCS" — it is
*"brand everything because the app is in the stack" vs "brand the ids that actually cross, which is the law's
own test."* The pragmatic reading is the **stricter** reading of mesh.8.1, not the looser one.

#### Arm B2 — **Four branded BCS components (BTP/BCA/BDV/RGP), components-as-data, gate-on-namespace** (Venus-1's model)

**Rationale.** Uniformity with the BCS stack: every entity a branded identity, data as plain bundles, the
system-as-process owning gated state. Carried as the serious alternative.

**5W / Steelman (brief).** **What** — four brands, four component bundles, `Bcs.gate` ingress. **Steelman** —
total consistency with `echo_data/bcs/`; if codemojex's entities *ever* cross to another system, they are
already typed; the model reads identically to the rest of the stack, so a stack-fluent maintainer needs no
context switch. The `BDV` time-ordering is genuinely elegant for free-order compaction (Venus-1 §2.4).

**Steward.** Four new branded namespaces to track and freeze; four component definitions that are a *second*
authority alongside whatever the persistence shape is (the DRY risk — the field set lives in both the component
bundle and the Postgres column set unless carefully unified). The ceremony is paid on every entity whether or
not its boundary is real. **Honest verdict:** correct and uniform, but it pays the brand+gate cost four times
where the boundary-crossing test (mesh.8.1's own) justifies it once.

**Pre-empting the pragmatic objection (the mirror).** The pragmatic objection to B2: *"three of four brands
never cross a boundary — you are paying for typing that nothing checks."* B2's rebuttal: uniformity has a real
maintenance value (one mental model for the whole stack) and the `BDV` time-ordering is a concrete payoff. The
fork turns on whether **stack-uniformity** or **boundary-minimalism** is the higher value here — an Operator
call.

**Fork B surface.** B1 (plain schemas + brand-the-crossing-id) vs B2 (four branded components).
**Recommendation: B1** — the one reason: *it is the stricter reading of mesh.8.1 (brand what crosses, which is
exactly one id here) and it mirrors a shipped Ecto pattern, so it ships faster and ages more cheaply.* Operator
rules.

---

### Fork C — persistence: found the period-compaction machinery, or counters-first and compact only if proven?

#### Arm C1 — **Counters-first: live tiles in Valkey + a `broadcast_deliveries` row only for FAILURES; add compaction only if row count proves it** (RECOMMENDED)

**Rationale.** The dashboard's headline need is **counts by status + a failure-reason breakdown** (the
requirement) — and counts are an **`HINCRBY`**, not a row scan. The *actionable* output is the failure subset
(it feeds `RGP` suppression). The full per-recipient chronological array is **cold archive** — read rarely, for
audit/replay. So the cheapest shape that satisfies the contract is: (a) Valkey `HINCRBY` counters per
`broadcast × status × reason` for the live tiles; (b) a `broadcast_deliveries` Postgres row written **only for
the failed recipients** (the small, actionable, growing set); (c) **no per-success row at all** by default —
the success count lives in the counter, and `message_id` is captured only if the Operator asks for
success-level audit. Compaction-to-one-row is **deferred machinery**: it solves a row-volume problem that only
exists if every success is persisted — which C1 doesn't do. Build compaction *if and when* a success-audit
requirement makes the row count real ([`AAW_DEVELOPMENT.md` §9](../../AAW_DEVELOPMENT.md)).

**5W.**
- **Why** — the dashboard reads counts (a counter op) and acts on failures (a small set); persisting 100k
  success rows to later compact them solves a problem the counter already avoids.
- **What** — Valkey `HINCRBY` rollup (`cm:bcast:rollup:{BCA-id}`, one `HGETALL` renders the tiles) + a
  `broadcast_deliveries` table that holds **only failures** `(broadcast_id, telegram_user_id, status, reason)`,
  written in batches as failures occur.
- **Who** — the `Broadcast` GenServer ticks the counters and batches the failure rows; the dashboard reads
  `HGETALL` + a `WHERE broadcast_id = ?` failures query.
- **When** — slice S2 (§3).
- **Where** — `cm:bcast:` Valkey keys (codemojex application keys, **NOT** the `emq:{q}:` bus grammar — stated
  so the master invariant is not mis-applied) + `codemojex/lib/codemojex/schemas/broadcast_delivery.ex`.

**Steelman.** 100k sends produce **a handful of counter increments and only the bounced rows** — the steady
state is *already* small without any compaction step, because the 99k+ successes were never written as rows in
the first place. There is no batched 100k-row insert, no period timer, no `compacting` state, no array
serialization, no trim job — the entire compaction subsystem (Venus-1 §3.1–§3.3, the `batch_size` parameter,
the straggler `timed_out` rule, the array-into-jsonb write) **does not need to exist**. The dashboard is *more*
responsive (a counter is fresher than a row aggregate) and the failure drill-down is a trivial indexed query.
The CAP-segmented story Venus-1 tells (counters = availability-first, the durable truth = consistency-first) is
*preserved* — counters are the hot tiles, the failure rows are the durable actionable record — just without the
cold array nobody reads. This is the leanest shape that delivers every named observation: counts by status ✓,
failure-reason breakdown ✓, actionable failures feeding suppression ✓.

**Steward.** Multi-year cost: **minimal and bounded** — the only growing table is `broadcast_deliveries`
holding *failures*, bounded by the bounce rate (the same set Venus-1's `failures` column holds), and itself
trimmable once applied to `RGP`. No compaction machinery to maintain, no period-timer correctness to reason
about, no array-serialization format to version. The honest debt: **if a success-level audit requirement
arrives** (the Operator wants the `message_id` of every delivered message, not just the count), C1 has to add
per-success persistence *then* — and at that point the compaction-to-one-row idea (Venus-1's design) becomes
exactly the right tool. So C1 doesn't *reject* compaction; it **defers it to the requirement that justifies it**
and keeps the door open (the `broadcast_deliveries` table can grow a success path and a compaction job without a
model change). Values honored: **Thin but robust**, **Do no harm** (no speculative subsystem). Value deferred:
full per-delivery audit — accepted, because no stated requirement asks for it.

**Pre-empting the spec-steward objection.** Venus-1's strongest objection: *"counters lose data — an `HINCRBY`
that fails leaves the tile permanently wrong, and with no per-delivery row there is nothing to reconcile it
against; the compacted Result row is the durable truth that makes the counters self-healing (a lost increment
re-derives from the array). Drop the array and you drop the audit trail and the self-heal."* Rebuttal, on the
page. (1) The self-heal Venus-1 prizes **re-derives the count from the per-delivery rows** — but if there are no
success rows, the thing being re-derived is just *the total send count*, which the **`Broadcast` GenServer
already knows** (it fanned out N recipients and counts terminal reports) and which is *also* recoverable from
the bus (the consumer's processed set) — so the count has a durable source without a 100k-row array. (2) The
audit trail that genuinely matters — *which users failed and why* — **is** persisted (the failure rows), with
full fidelity; what C1 declines to persist is the 99k+ **success** rows, whose only audit value is "this user
got message_id X," a requirement no one has stated. So the disagreement is precisely: *is per-success
`message_id` audit a requirement?* If yes, C1 grows a success path (and compaction becomes worth it); if no, the
array is cold storage for data nobody reads. The fork hands the Operator that exact question rather than
pre-deciding it by building the array.

#### Arm C2 — **The period-compaction model: batch every delivery, compact to one Result row at `period`, + a `failures` column** (Venus-1's §3–§4)

**Rationale.** Persist every delivery durably during the run (crash-resume from the last batch), then compact
the per-recipient results — chronologically, free, via `BDV` time-ordering — into ONE archived row at the
template period, with a `failures` jsonb column for the hot subset. Carried as the serious alternative.

**5W / Steelman (brief).** **What** — batched `BDV` writes + a `compacting` state + a `BroadcastResult` row
carrying the full chronological array + a `failures` column + Valkey counters. **Steelman** — a complete audit
trail (every `message_id` preserved), crash-resumable mid-broadcast (resume from the last batch), and the
compaction is genuinely *free-order* (the `BDV` snowflake IS the chronological key, no sort — Venus-1 §2.4, a
real and elegant property of [`Timeline`](../../../echo/apps/echo_data/lib/echo_data/timeline.ex)). 100k rows
→ 1 archived row is a real steady-state win *if* every delivery must be persisted.

**Steward.** A whole subsystem: a `batch_size` parameter to tune, a period timer whose correctness must be
reasoned about, a `draining → compacting` transition, a straggler `timed_out` rule (Venus-1 D-3), an
array-into-jsonb serialization format to version, and a trim job. All of it exists to manage the volume created
by *persisting every success* — volume C1 avoids by not creating it. **Honest verdict:** the right design *if*
per-success audit is a requirement; otherwise it is machinery built to clean up rows that needn't be written.

**Pre-empting the pragmatic objection (the mirror).** Pragmatic objection to C2: *"you persist 100k rows then
compact them; persisting only failures skips both steps."* C2's rebuttal: crash-resume needs the in-flight rows
(you can't resume a broadcast from counters alone), and a full audit trail is a real asset for a production
system handling money-adjacent notifications. The fork turns on **whether crash-resume mid-broadcast and
per-success audit are requirements** — Operator's call.

**Fork C surface.** C1 (counters-first, failures-only rows, defer compaction) vs C2 (batch-all + period
compaction). **Recommendation: C1** — the one reason: *the dashboard reads counts (a counter op) and acts on
failures (a small set), so the leanest shape persists exactly those and never creates the success-row volume
that compaction exists to manage; compaction is deferred to the audit requirement that would justify it.*
Operator rules — the deciding facts are *crash-resume* and *per-success audit*.

---

### Fork D — build decomposition: a 6-rung spec-triad ladder, or 3 code-first slices with slim records?

#### Arm D1 — **Three code-first slices; a full triad ONLY for the one new-process surface; slim records elsewhere** (RECOMMENDED)

**Rationale.** [`AAW_DEVELOPMENT.md` §2–§4](../../AAW_DEVELOPMENT.md): size the formation to the *delta*, not the
rung number; the code is the spec for small/additive work; a spec earns a full triad only where a *new
process/lease/protocol* surface is genuinely designed. Under the B1/C1 recommendations, most of this work is
**additive over shipped patterns** (Ecto schemas mirroring six existing ones; counters via the existing
`Codemojex.Wire.run/2`; a config retune). The genuinely *new* surface is the `Codemojex.Broadcast` state-machine
GenServer (a new process that owns a lifecycle) — *that* earns a slim spec first. The rest ships code-first with
a ~50-line record per slice (status → surface → invariants → gate).

**5W.**
- **Why** — ceremony scales to the work; six full triads (~300 lines each = ~1800 lines of spec) for what is
  mostly schema-transcription + a config line is the process-weight mismatch the doc names.
- **What** — three slices: **S1** (entities + audience resolution + the 27/s retune + the `Broadcast` GenServer
  skeleton — the *one* part that gets a slim spec-first), **S2** (the send path + counters-first persistence +
  `EchoBot.deliver/3` widened to carry `message_id`), **S3** (the `RGP` failure feedback + the dashboard read
  API). Each slice clears the verification floor (§5 below).
- **Who** — a single builder per slice (the right-sized formation for additive work), the Director verifies; a
  2nd architect / Apollo only if a slice surfaces a genuinely open fork or a new-lease surface mid-build.
- **When** — S1 → S2 → S3, each one tight increment.
- **Where** — `codemojex/lib/codemojex/` (schemas, broadcast.ex, the worker edit, application.ex). **No echo_mq
  edit at all** under the A1 recommendation.

**Steelman.** The work *is* mostly additive: the schemas mirror [`schemas/`](../../../echo/apps/codemojex/lib/codemojex/schemas/),
the counters ride [`Codemojex.Wire.run/2`](../../../echo/apps/codemojex/lib/codemojex/wire.ex) unchanged, the
retune is one line, the `deliver/3` widening is a two-line change to an existing function
([`echo_bot.ex:43`](../../../echo/apps/codemojex/lib/codemojex/echo_bot.ex)). Writing six triads *before* that
code is writing what the code already says — the §9 self-check fires on "am I writing docs the code already
says?" The one part that is *design* (the state machine) gets the spec it deserves, slim and high-level. The net:
the team ships faster, the records are readable (50 lines, not 500), and the rigor that matters — the gate
ladder, the boundary grep, the net-zero mutation check — **never scales down** (§5). This is the doc's thesis
applied literally: cut ceremony, keep rigor.

**Steward.** Multi-year cost: **the records stay legible** — a future maintainer reads three slim slice records
+ one state-machine spec, not six triads of which four restate the code. The honest debt: less *upfront*
formal-acceptance text means the Operator's sign-off leans more on the running gate + the slim record than on a
pre-written stories file — which is exactly the trade [`AAW_DEVELOPMENT.md`](../../AAW_DEVELOPMENT.md) endorses
for additive work, but which the spec-steward lens reads as under-specification. Mitigation: the state-machine
slice (the one with real design risk) keeps a full triad including stories, so the *risky* part is fully
specified; the additive parts are specified *by the code + the slim record*, which is the authority for a verb
list anyway (§4 of the dev doc). Value honored: **rigor is constant** (the floor holds), **Thin but robust**.
Value at risk: upfront formal acceptance breadth — accepted for the additive slices, preserved for the state
machine.

**Pre-empting the spec-steward objection.** Venus-1's strongest objection: *"a notification system handling
100k–1M sends/day to real users is production-critical; 'code-first, slim records' under-specifies the
acceptance, and without a Given/When/Then stories file per deliverable the Operator can't sign off and Apollo
can't verify against anything but the diff — the triad ladder is what makes 'done' provable from the text."*
Rebuttal, on the page. (1) **Rigor is not what scales down — ceremony is** ([`AAW_DEVELOPMENT.md` §1, §7](../../AAW_DEVELOPMENT.md)):
D1 keeps the *entire* verification floor — the gate ladder, the net-zero mutation check, the boundary grep, plus
the existing-suite-green proof — and adds an adversarial probe and (for S2, which touches the live send path) a
real-Telegram-stubbed delivery test. "Done" is provable from *running the gate*, which is a stronger proof than
a stories file that no one executed. (2) The acceptance the Operator actually signs is **deliverability
behavior** — the counters move, the failures suppress, the cap holds — and D1 specifies *that* as the slice
record's gate, at the boundary (the contract), not by re-reading the diff. (3) The *one* part with real design
ambiguity (the state machine's transitions and completion rule) **does** get a full triad with stories — so the
spec-steward's "prove done from the text" holds exactly where the design risk is, and is replaced by "prove done
from the gate" where the work is transcription. So the disagreement reduces to: *for additive-over-shipped-pattern
work, is the running gate + a slim record a sufficient acceptance, or is a per-deliverable stories file
required?* — which is the standing question [`AAW_DEVELOPMENT.md`](../../AAW_DEVELOPMENT.md) answers "gate
suffices for additive; triad for design," and D1 applies that line precisely.

#### Arm D2 — **The 6-rung spec-triad ladder (cmn.1 + emq.throttle + cmn.2–5), full triads** (Venus-1's §7)

**Rationale.** Decompose into six thin gateable rungs, each with a full `.md`/`.stories.md`/`.llms.md` triad, so
every deliverable is a Given/When/Then contract the Operator signs and Apollo verifies. Carried as the serious
alternative (and Venus-1 has already authored two of the six triads — cmn.1 + emq.throttle — so the ladder is
partly real).

**5W / Steelman (brief).** **What** — six rungs, six triads, the throttle rung HIGH-risk/Apollo-mandatory.
**Steelman** — every deliverable is a written, signable acceptance contract; the traceability (Deliverable →
story → invariant) is provable from the text alone; a production-critical system gets maximum upfront rigor; the
two already-authored triads (cmn.1, emq.throttle) are concrete and high-quality, so the ladder is not
hypothetical.

**Steward.** ~1800 lines of spec across six triads, four of which (cmn.2–5) largely describe additive code; the
triads must be kept in sync with the code as it lands (the lag-1 reconcile burden ×6). For the *additive* rungs
this is documentation that restates the code — the maintenance surface the dev doc warns against. **Honest
verdict:** the right rigor for the *design-heavy* rungs (the state machine, and the throttle *if* A2 wins);
over-ceremony for the schema/counter/retune rungs.

**Pre-empting the pragmatic objection (the mirror).** Pragmatic objection to D2: *"four of six triads restate
the code."* D2's rebuttal: a written acceptance contract has value independent of the code (it is what the
Operator signs and Apollo checks), and for a production system that breadth is cheap insurance. The fork turns
on **how much of this work is genuinely design vs transcription** — and under B2/C2 (Venus-1's model) *more* of
it is design (four branded components + a compaction subsystem), so D2 is more justified *in Venus-1's world*
than in B1/C1's. **This is the key coupling: D follows from B and C.**

**Fork D surface.** D1 (3 code-first slices + 1 state-machine triad + slim records) vs D2 (6 full triads).
**Recommendation: D1** — the one reason: *under B1/C1 most of this work is additive over shipped patterns, where
the code is the spec and the running gate is the acceptance; the full triad is reserved for the one new-process
surface that is genuinely design.* **D's answer is contingent on B and C** — if the Operator rules B2 (four
components) and C2 (compaction subsystem), the design surface grows and D2's ceremony is more warranted; under
B1/C1 it is not. Operator rules, after B and C.

---

## 3. The recommended build — three code-first slices (if the Operator rules A1/B1/C1/D1)

A concrete decomposition for the pragmatic path, shown so the Operator can compare ladders side by side. Each
slice clears the verification floor (§5).

| Slice | Title | What it builds | New surface that earns a spec? | Risk |
|---|---|---|---|---|
| **S1** | **Entities + audience + the cap + the machine skeleton** | the four plain Ecto schemas (mirroring `schemas/`); `RecipientGroup` resolution (`all` from `Player`, `admin`, `group_of_n`, `from_csv`); the **27/s retune** (one child-spec line); the `Codemojex.Broadcast` GenServer skeleton (the lifecycle states + transitions) | **Yes** — the `Broadcast` state machine gets a slim spec-first (status → states → transitions → completion rule → gate). The schemas + retune are code-first. | LOW (additive + 1 config line) |
| **S2** | **Send path + counters-first persistence** | the fan-out (`enqueue_many` — see the fan-out note below); per-recipient send gated by the (retuned) `RateLimiter`; `EchoBot.deliver/3` widened to carry `message_id`; the `HINCRBY` counter tiles; the failures-only `broadcast_deliveries` rows | code-first (the send path mirrors the existing worker; counters ride `Wire.run/2`) | MED (touches the live send path — gets the adversarial + stubbed-delivery probe) |
| **S3** | **Failure feedback + dashboard read** | 403 terminal outcomes → `RGP` suppression (a message about identities); the next broadcast skips suppressed; the dashboard read API (`HGETALL` + the failures query) | code-first | LOW |

**Fan-out note (a sub-fork I surface, do not decide).** Venus-1's Fork F (`enqueue_many` vs a Flow
parent→children) is real and stands. The pragmatic lean is **`enqueue_many`** for the floor: it is one bulk
admit ([`jobs.ex:124`](../../../echo/apps/echo_mq/lib/echo_mq/jobs.ex)), the `Broadcast` GenServer does the
aggregation host-side (it already owns the lifecycle state), and a 100k-child Flow is heavy machinery whose
fan-in (`children_values/3`) the GenServer doesn't need because it counts terminal reports directly. Flow is the
better fit *if* the Operator wants the bus to own the parent/fan-in durably (Venus-1's recommendation). The
pragmatic lens prefers the GenServer-aggregates shape — but this is the Operator's call (it is Venus-1's D-4).

---

## 4. The BCS law — honored where the boundary is real (not abandoned)

A pre-emptive clarification so the synthesis doesn't read B1/C1 as "abandoning BCS." This design is **faithful to
mesh.8.1 where the law applies**:

- **The id that crosses is branded.** The broadcast id is a `BCA` snowflake — it keys the Valkey counter hash
  (`cm:bcast:rollup:{BCA-id}`), a typed identity crossing the codemojex→Valkey boundary.
- **Failure feedback is a message about identities.** A 403 terminal outcome suppresses a recipient by **sending
  the suppressed user id to the `RGP`'s own gated suppression set** — not by mutating a shared object, exactly
  the law's shape (`mesh.8.1`: *"messages about identities"*).
- **The counter keys are codemojex application keys (`cm:bcast:`), NOT the `emq:{q}:` bus grammar** — stated so
  the v2 master invariant ([`echo/CLAUDE.md` §4](../../../echo/CLAUDE.md)) is not mis-applied to them. They ride
  [`Codemojex.Wire.run/2`](../../../echo/apps/codemojex/lib/codemojex/wire.ex) (the `EchoWire.Cmd` client),
  unchanged.

What the pragmatic lens declines is branding the entities that **never cross a boundary** — which, per
mesh.8.1's own boundary-crossing test, the law does not require. This is a *stricter* application of the law, not
a looser one.

---

## 5. The verification floor — never scales down (identical to Venus-1's rigor)

Whatever the Operator rules, every slice/rung clears this floor
([`AAW_DEVELOPMENT.md` §7](../../AAW_DEVELOPMENT.md)). The pragmatic lens cuts *ceremony*, never *rigor*:

- **The per-app gate ladder** — `TMPDIR=/tmp mix compile --warnings-as-errors` + the per-app suite, run from
  inside `codemojex/` (and `echo_mq/` only if A2 wins and a throttle rung exists). Valkey up on `:6390`.
- **The existing suite stays green and byte-stable** across the worker/`deliver` edits (behaviour-preservation).
- **The net-zero mutation check** — perturb an invariant (e.g. the 27/s cap, the suppression skip), confirm a
  test KILLS it, revert by an inverse edit, confirm `git diff` clean.
- **The boundary grep** — the diff touches only `codemojex/` (+ `echo_mq/` only under A2); no foreign app, no
  `mix.lock` unless a real dep moved. **Under A1/B1/C1/D1 the entire change is inside `codemojex/`** — a strictly
  smaller, more-reviewable blast radius than a design that edits the frozen echo_mq wire.
- **Conformance** — untouched under A1 (`{:ok, 59}` stays exact, because no echo_mq scenario is added). Under A2,
  re-pinned `{:ok, 60}` in both pinning tests with the new scenario probe-registered (the additive-minor law).

---

## 6. Where I diverge from Venus-1 — and why (the explicit summary)

| # | Dimension | Venus-1 (spec-steward) | Venus-2 (pragmatic / code-first) | Why I diverge | The Operator's deciding fact |
|---|---|---|---|---|---|
| **A** | The 27/s cap | A new Valkey `EchoMQ.Throttle` wire primitive (HIGH-risk, Apollo-mandatory, +1 conformance, touches the frozen `{emq}:` grammar) — D-1 ruled | **Retune the in-memory limiter to 27/s now** (one child-spec line, `application.ex:28`); **defer the cluster-wide primitive to a named Seam** | Single-node today (no cluster dep); the in-memory cap is exactly correct on one node; a frozen-wire primitive shouldn't ride a delivery rung for a node that doesn't exist. A multi-node over-cap is loud (Telegram `429` → existing retry), not silent. | **Is multi-node imminent enough to build the cap now, or a gated horizon?** (re-rules D-1) |
| **B** | Entity model | Four branded BCS components (BTP/BCA/BDV/RGP), gate-on-namespace | **Plain Ecto schemas** (mirroring the six shipped) **+ one `Broadcast` GenServer**; brand **only** the `BCA` id that crosses to Valkey counters | mesh.8.1's law binds values that **cross a boundary**; three of four entities never leave codemojex's Repo. Branding what crosses (one id) is the *stricter* reading, and plain schemas mirror a shipped pattern. | **Stack-uniformity vs boundary-minimalism** — and whether these entities will ever cross to another system |
| **C** | Persistence | Batch every delivery → compact to ONE Result row at `period` + a `failures` column | **Counters-first**: Valkey `HINCRBY` tiles + a `broadcast_deliveries` row **only for failures**; **no per-success row**; **compaction deferred** until row volume proves it | The dashboard reads counts (a counter op) and acts on failures (a small set); persisting 100k successes to later compact them creates the volume compaction exists to manage. The count has a durable source (the GenServer / the bus) without the array. | **Are crash-resume mid-broadcast and per-success `message_id` audit requirements?** |
| **D** | Build decomposition | 6 full spec triads (cmn.1 + emq.throttle + cmn.2–5; two already authored) | **3 code-first slices + slim records**; a **full triad only for the `Broadcast` state machine** (the one genuine new-process design) | Under B1/C1 most of the work is additive over shipped patterns — the code is the spec, the running gate is the acceptance; the triad is reserved for real design risk. | **For additive work, is the gate + a slim record sufficient acceptance, or is a per-deliverable stories file required?** (and D follows from B + C) |

**The coupling the synthesis must respect:** the four forks are **not independent**. A (the cap) is standalone —
it is the cleanest, highest-value divergence and the Operator can rule it alone. But **D follows from B and C**:
if the Operator rules B2 (four components) + C2 (compaction subsystem), the design surface is large enough that
D2's six triads are more warranted; if B1 + C1, the work is additive and D1's slices fit. So the recommended
ruling order is **A, then B, then C, then D** — and the most useful single signal for the Operator is the **A
fork** (build-the-primitive-now vs retune-and-gate-the-horizon), where the two lenses most sharply disagree on
cost.

**What both lenses agree on (the inheritance into synthesis):** the reconcile is accurate; Postgres is the cold
store; Valkey `HINCRBY` counters are the live tiles; the failure subset feeds `RGP` suppression as a message
about identities; `EchoBot.deliver/3` widens to carry `message_id`; the per-chat 1/s limiter stays in-memory
(no round-trip); the verification floor never scales down. The disagreement is **scope and ceremony**, not
correctness — which is the cleanest kind of fork for the Operator to rule.

---

## 7. References (grounded)

- **The method:** [`aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md) (the four-part arm, the
  multi-architect debate). **The lens:** [`AAW_DEVELOPMENT.md`](../../AAW_DEVELOPMENT.md) (rigor constant,
  ceremony scales; code-first; don't fuse a horizon into a delivery rung).
- **Venus-1's design (the contrast):** [`notifications.design.md`](notifications.design.md) + her authored
  triads under [`specs/`](specs/) (`cmn.1`, `emq.throttle`).
- **As-built code (re-verified at `file:line`):**
  `echo/apps/codemojex/lib/codemojex/{rate_limiter,notification_worker,echo_bot,telegram,notifier,application,store,wire,repo}.ex`;
  `echo/apps/codemojex/lib/codemojex/schemas/player.ex`;
  `echo/apps/echo_mq/lib/echo_mq/{jobs,repeat,flows,lanes,meter}.ex`;
  `echo/apps/echo_data/lib/echo_data/{branded_id,timeline}.ex`.
- **The BCS law + whole-picture frame:** [`docs/echo/mesh/content/mesh.8.1.md`](../../echo/mesh/content/mesh.8.1.md).
- **The v2 master invariant + conformance additive-minor law:** [`echo/CLAUDE.md` §4](../../../echo/CLAUDE.md),
  repo [`CLAUDE.md`](../../../CLAUDE.md), [`docs/echo_mq/emq.design.md`](../../echo_mq/emq.design.md).
- **Telegram limits:** ~30 msg/s broadcast → the 27/s = 90% cap; ~1 msg/s per chat; `429` carries
  `parameters.retry_after`; `403` = blocked/kicked/chat-not-found (permanent → suppress). Source:
  core.telegram.org/bots/api (sendMessage) + core.telegram.org/bots/faq (limits).
