# EMQ.3.3 · The cross-queue flow — the third sub-rung (Movement I, the flow family)

> **Status: SPECCED 2026-06-15** (the THIRD sub-rung of the emq.3 parent/flow family — the family contract + the
> carve + the forks are [`./emq.3.md`](../../emq.3.md); the first slice [`./emq.3.1.md`](emq.3.1.md) SHIPPED
> 2026-06-15 at CONFORMANCE 45/45, the second [`./emq.3.2.md`](emq.3.2.md) SHIPPED 2026-06-15 at CONFORMANCE
> 46/46). emq.3.3 carves the **cross-queue flow** — a parent and its DIRECT children in **different queues** (the
> v1 shape: a parent in `orders`, children in `validation`/`inventory`/`payments`). Under the v2 braced keyspace
> each queue is a **different cluster slot**, so a child's completion **cannot atomically reach** the parent's
> other-slot `:dependencies` counter — **no single Lua script** spans both (S-1/§6). The decrement is delivered
> by a **completion-signal hop** (the [`./emq.3.md`](../../emq.3.md) Fork A mechanism, RULED single-queue-first
> 2026-06-14): the cross-queue child's completion **emits** to a durable per-queue **outbox** on the child's own
> slot, and a **per-queue sweep** drains the outbox and delivers the decrement to the parent **on the parent's
> slot** — giving **eventually-consistent** fan-in across queues (stated honestly — **INV7**: explicitly NOT
> "atomic across queues"). **Risk: HIGH** — emq.3.3 (a) founds a new cross-slot completion signal (the outbox +
> the sweep-deliver) and (b) **edits a shipped Lua script** (`@complete` gains an additive cross-queue branch),
> the inverse of emq.3.2's NORMAL-risk host-only reads → **Apollo MANDATORY** + the **≥100 determinism loop**.
> The four cross-queue forks were ruled **D-1..D-4** (this rung's ledger [`./emq-3-3.progress.md`](../../progress/emq-3-3.progress.md)
> — the recommended arms this triad is authored to): **D-1** the outbox-on-the-child's-slot · **D-2** piggyback
> `EchoMQ.Pump.sweep/1` · **D-3** the `:processed` HSETNX idempotency guard · **D-4** the additive cross-queue
> branch in `@complete` (the single-queue fan-in branch BYTE-FROZEN). **D-5** locks the scope bound (FLAT
> cross-queue; failure-policy + bulk + grandchildren are emq.3.4) and the add-side semantics (the cross-queue add
> is host-orchestrated, NON-atomic across slots, parent-first, fail-closed).

## 0 · The slice — what emq.3.3 carves, and why third

emq.3.1 founded the single-queue flow: a parent → its same-queue children, the dependency graph riding
**declared §6 subkeys of the parent** (`emq:{q}:job:<parent>:dependencies` the outstanding-child STRING counter,
`…:processed` the completed-children HASH), the parent held out of `pending` until fan-in, the fan-in hook on
`@complete` recording each completing child in `:processed` and decrementing `:dependencies` — **all on the one
`{q}` slot, one atomic EVAL** (`@enqueue_flow` lands the whole flow, `@complete`'s fan-in branch releases the
parent at zero). emq.3.2 added the **read API** over those subkeys (`children_values/3` / `dependencies/3`) and
made `:processed` carry a **real result**. Both stayed inside the **single-queue** carve.

emq.3.3 is the **cross-queue crossing**: the same parent → child dependency graph, but the children run in
**different queues** than the parent. This is the v1 flow's defining shape (`flow_producer.ex` — a parent in
`orders`, children in `validation`/`inventory`/`payments`, `echo/apps/echomq/lib/echomq/flow_producer.ex:28-30`),
and it is **the hard one**: under the braced keyspace a parent in queue P and a child in queue C have keys on
**different cluster slots** (`slot({P}) ≠ slot({C})` — the hashtag is the queue name, the co-location law,
`emq.design.md:46`), and a Lua script may touch keys of **one slot only**. So the single-queue fan-in
(`@complete` records the child in the parent's `:processed` and decrements the parent's `:dependencies` in **one
EVAL**, `jobs.ex:181-188`) is **structurally impossible** across the boundary — no single script can both ZREM
the child from `emq:{C}:active` and DECR `emq:{P}:job:<parent>:dependencies`.

The cross-queue **mechanism** — the genuine new design — is the **completion-signal hop** (D-1..D-4): the child's
completion **emits** the decrement-to-deliver into a durable **outbox on its own slot** (atomically, inside the
`@complete` EVAL), and a **per-queue sweep** (a new pass on the existing `EchoMQ.Pump`) drains the outbox and
delivers the decrement to the parent **on the parent's slot** (a second, separate EVAL, made idempotent by a
`:processed` guard). The fan-in is therefore **eventually-consistent** (the parent is released on the **next
sweep tick** after the last child completes, never synchronously — INV7), and delivery is **at-least-once made
effectively-once** (a re-delivered completion is a no-op). It is the **third** sub-rung because the cross-queue
crossing is meaningful only after a flow can be added + fanned in (emq.3.1) and read (emq.3.2), and it stays
**FLAT** (a parent + its DIRECT cross-queue children — grandchildren / deep recursion AND the failure-policy are
**emq.3.4**, the honest **Out**, D-5a).

## Goal

emq.3.3 builds, inside `echo/apps/echo_mq`, the **cross-queue flow**:
(1) **the cross-queue add** — `EchoMQ.Flows.add/3` extended to ADMIT children whose queue differs from the
parent's (the as-built `reject_cross_queue/2` host-refusal at `flows.ex:191` is **replaced by an admit path**);
the cross-queue add is **host-orchestrated and NON-atomic across slots** (no single `@enqueue` spans the
children's different slots — D-5b): the parent lands FIRST (held, `state = awaiting_children`, `:dependencies` =
N, on its slot), then each child lands on its own slot carrying the emq.3.1 `parent` field **plus** a new
`parent_queue` field; a partial add leaves the parent HELD (fail-closed, host-retryable by id);
(2) **the outbox emit** (D-1, D-4) — the cross-queue child's `@complete` gains an **additive cross-queue branch**:
when the host detects the child carries a `parent_queue` field, it passes the outbox key
(`emq:{C}:flow:outbox`) and the cross-queue tuple, and the script **RPUSHes** the completion entry
(`parent_queue`, `parent_id`, `child_id`, `result`) into the outbox **atomically with the active-set ZREM** (one
EVAL on the child's slot {C}); the **single-queue fan-in branch** (`jobs.ex:181-188`) and the non-flow path stay
**BYTE-UNCHANGED**;
(3) **the sweep-deliver** (D-2, D-3) — `EchoMQ.Pump.sweep/1` gains a **third pass**
`deliver_flow_completions(conn, queue, batch)` (after promote + fire_repeats → `{:ok, %{promoted, fired,
delivered}}`) that drains `emq:{queue}:flow:outbox` (LIMIT `:batch`) and, per entry, issues a new
**`@flow_deliver`** EVAL on the **parent's slot** that records the child in the parent's `:processed` via
**HSETNX** and — only on the first record — **DECRs** the parent's `:dependencies` and at-zero releases the
parent to `pending`; the drained entry is then removed (a re-delivery finds the child already in `:processed` →
no double-DECR — the crash-recovery keystone, D-3);
(4) the conformance scenario **`flow_cross_queue`** (additive minor, `46 → 47`), the prior 46 byte-unchanged,
both pinning tests re-pinned;
(5) the `:valkey` cross-queue suite (a flow minting a parent + children **across queues**, completed, swept,
fanned-in) under the **≥100-iteration determinism loop** (the mint-touching surface).
The new **outbox** subkey joins the flow-subkey **lifecycle carry** (N1) — its cleanup is **NAMED, deferred** to
the emq.3.x lifecycle rung (D-5c); it is **self-clearing** in steady state (its own sweep drains it). The shipped
`@enqueue`/`@claim`/`@retry`/`@promote`/`@reap`/`@schedule` **Lua** is **untouched**; the `@enqueue_flow` **Lua**
is **untouched** (the cross-queue add is host-orchestrated per-slot, NOT one new spanning script); the single-queue
`@complete` fan-in branch is **byte-frozen**; `apps/echomq` is **untouched** (the capability reference).

## Rationale (5W)

- **Why** — emq.3.3 restores the v1 flow's **defining capability**: cross-queue parent/child graphs (a parent in
  one queue, its children in others — the documented v1 shape, `flow_producer.ex:28-30`). It is the **closer**
  of the flow family's core: emq.3.1 founded the mechanism (same-queue, atomic), emq.3.2 made the result
  consumable, emq.3.3 crosses the slot boundary the v1 flow lived on — the part the braced keyspace makes
  genuinely hard (no atomic single script spans two slots). It is the **smallest** rung that does so, and it
  founds the cross-slot completion-signal mechanism **deliberately** (its consistency model is designed, not
  improvised — exactly why Fork A deferred it to its own rung, `emq.3.md:289`).
- **What** — emq.3.3 builds: the **cross-queue add** (a host-orchestrated, non-atomic, parent-first, fail-closed
  extension of `EchoMQ.Flows.add/3`); the **outbox emit** (an additive cross-queue branch in the shipped
  `@complete`, the single-queue branch byte-frozen — D-4); the **sweep-deliver** (a third `EchoMQ.Pump.sweep/1`
  pass + the new `@flow_deliver` idempotent script — D-2/D-3); the **`flow_cross_queue`** conformance scenario;
  the `:valkey` cross-queue suite. **Authored to D-1** (the outbox on the child's slot), **D-2** (piggyback the
  Pump), **D-3** (the `:processed` HSETNX guard), **D-4** (the additive `@complete` branch).
- **Who** — the program (the rung that closes the flow family's core by crossing the slot boundary); the bus's
  consumers, who gain cross-queue flows (a parent that fans in over children in *other* queues — the v1
  surface); the conformance harness, which grows by `flow_cross_queue` (additive minor). **Exchange**
  (prospective): a cross-queue order pipeline (a parent `order` job in `orders` fanning in over `validation` /
  `inventory` / `payments` legs) — *no TRD rung names flows today* ([`../emq.features.md`](../../../emq.features.md) —
  recorded, not asserted).
- **When** — Movement I, the flow family's **third** sub-rung, after emq.3.1 + emq.3.2 shipped (emq.3.3 extends
  the `add/3` admit path emq.3.1 built, emits through the `@complete` seam emq.3.1 built, and the deliver records
  into the `:processed`/`:dependencies` subkeys emq.3.1 writes + emq.3.2 reads). SPECCED this design cycle; the
  four forks are **ruled D-1..D-4** (the Operator's land-gate was dissolved by the 2026-06-15 governing
  directive — the Director rules the design forks with delegated authority, robustness the lens), so the triad
  is authored to the ruled arms with **no pre-build re-scope**.
- **Where** — `echo/apps/echo_mq` only: `flows.ex` (EDIT — `add/3` gains the cross-queue admit path; the host
  orchestration: parent-first, per-child cross-slot enqueue carrying `parent_queue`, fail-closed; the
  `reject_cross_queue/2` refusal at `flows.ex:191` is removed/replaced), `jobs.ex` (EDIT — the **additive
  cross-queue branch** in `@complete`; the single-queue fan-in branch `jobs.ex:181-188` BYTE-FROZEN; the host
  `complete` wrapper detects `parent_queue` and supplies the outbox key + the cross-queue ARGV), `pump.ex` (EDIT
  — the third `deliver_flow_completions` pass on `sweep/1` + the new `@flow_deliver` script; `sweep/1`'s return
  grows to `%{promoted, fired, delivered}`), `conformance.ex` (EDIT — `flow_cross_queue` + the count re-pin
  `46 → 47`), `test/flow_cross_queue_test.exs` (NEW — `:valkey`), the two pinning tests (EDIT — the count).
  **`keyspace.ex` is UNEDITED**: `queue_key/2` is a pure composer (`"emq:{" <> q <> "}:" <> type`,
  `keyspace.ex:14-15`) with no runtime registry allowlist, so `queue_key(queue, "flow:outbox")` already composes
  the outbox key slot-soundly (the hashtag is `queue`); the §6 "registration" of the `flow:outbox` type + the
  child-row `parent_queue` field is a **canon + conformance** act (the grammar §6 `type`/`suffix` set + the
  `flow_cross_queue` scenario), not a code-allowlist edit. `echo_wire` is **untouched** (the emit + deliver ride
  the shipped connector `eval`; no new transport, no new connector verb). `apps/echomq` is **untouched**. Exact
  line anchors re-pinned at the pre-build reconcile (the lag-1 law — emq.3.1/3.2 moved the surface).

## Scope

- **In** — the FLAT cross-queue flow (a parent + its DIRECT children in different queues): (1) the **cross-queue
  add** (`EchoMQ.Flows.add/3` admits cross-queue children; host-orchestrated, NON-atomic across slots,
  parent-first, fail-closed — D-5b); each cross-queue child carries `parent` (the bare parent id, emq.3.1)
  **plus** `parent_queue` (the parent's queue, NEW); (2) the **outbox emit** (the additive cross-queue branch in
  `@complete` — D-1/D-4): the child's completion RPUSHes `(parent_queue, parent_id, child_id, result)` into
  `emq:{C}:flow:outbox` atomically with the active-ZREM, the single-queue branch byte-frozen; (3) the
  **sweep-deliver** (the third `Pump.sweep/1` pass + `@flow_deliver` — D-2/D-3): drain the outbox, deliver the
  decrement on the parent's slot via the `:processed` HSETNX guard, at-zero release the parent, remove the
  drained entry; (4) `flow_cross_queue` conformance (additive minor, the prior 46 byte-unchanged); (5) the
  `:valkey` cross-queue suite; the mint/process-touching cross-queue scenario under the **≥100-iteration
  determinism loop**; honest-row reporting (Valkey on 6390 the truth row).
- **Out** — the **failure-policy** (the v1 `fail_parent_on_failure` / `ignore_dependency_on_failure`,
  `flow_producer.ex:80-81`; the `:failed` / `:unsuccessful` subkeys) — **emq.3.4**; **`add_bulk`** (the v1
  `add_bulk/2`, `flow_producer.ex:183`) — **emq.3.4**; **grandchildren / deep recursion** (a cross-queue child
  that is itself a parent of grandchildren — emq.3.3 builds ONE parent level of cross-queue fan-in; the recursive
  cross-queue tree is **emq.3.4**, recorded NOT built here — D-5a); the **flow-subkey CLEANUP/lifecycle** (the
  `obliterate`/`@drain` sweep of `:dependencies`/`:processed`/**`flow:outbox`** + per-flow completion cleanup — a
  **NAMED CARRY** to the emq.3.x lifecycle rung, D-5c + the honest bounds below; emq.3.3 **adds** the outbox, it
  does not retire it); any **edit to a shipped Lua script other than the additive `@complete` branch**
  (`@enqueue`/`@claim`/`@retry`/`@promote`/`@reap`/`@schedule`/`@enqueue_flow` — none); any **new wire class**
  (none — the emit/deliver are plain `RPUSH`/`HSETNX`/`DECR`/`ZADD`; no fence code, no `EMQ…` class); any **new
  transport** (none — the connector `eval` carries both scripts); any **`keyspace.ex` grammar-enforcement edit**
  (none — `queue_key/2` composes the outbox key already); any **edit to the frozen v1 line**; the in-flight
  `echo/apps/exchange/` + `docs/exchange/*`; the Operator's concurrent `docs/echo/mesh/**` course work.

### The honest bounds + carried follow-ups (surfaced at authoring — recorded, not papered over)

emq.3.3 ships the FLAT cross-queue flow; these are its honest bounds, each a **correct-for-scope** limit, never a
defect:

- **B1 — the cross-queue fan-in is EVENTUALLY-CONSISTENT, not atomic (INV7, the headline honesty bound).** A
  cross-queue child completing does **NOT** synchronously release its parent. The parent's `:dependencies` is
  decremented, and at-zero the parent released to `pending`, **only on the next sweep tick** of the queue whose
  outbox holds the entry (latency bounded by `:tick_ms`, default 1000ms — `pump.ex:44`). The single-queue carve
  (emq.3.1/3.2) **remains fully atomic** (one slot, one EVAL) — emq.3.3 does not regress it; the honesty bound is
  scoped to the cross-queue path. **No page, story, doc, or comment may claim "atomic across queues."** The
  contract states the model explicitly.
- **B2 — the cross-queue ADD is NON-atomic across slots (INV7's add-side consequence, D-5b).** No single
  `@enqueue` script spans the children's different slots, so the cross-queue add is **host-orchestrated
  per-slot**: the parent lands FIRST (held, `state = awaiting_children`, `:dependencies` = N, on its slot), then
  each child lands on its own slot. The single-queue "one atomic `@enqueue_flow`" claim does **NOT** carry to
  cross-queue, and the contract says so. **FAIL-CLOSED**: a partial add (a child fails to land cross-slot) leaves
  the parent **HELD** — never claimable, never spuriously executed — host-retryable by id. **Parent-first is the
  safe order**: the parent's `:dependencies` counter exists before any child can complete + deliver, so no
  deliver ever races an absent counter.
- **B3 — delivery is AT-LEAST-ONCE made EFFECTIVELY-ONCE; the drop window is PROVABLY ABSENT (D-1/D-3, the
  crash-recovery keystone).** Emission is **atomic with completion** (D-1, D-4): the outbox RPUSH and the
  active-set ZREM are **one EVAL on slot {C}**, so a completed cross-queue child **always** has a durable outbox
  entry — there is **no state** where a child completed but produced no signal (the drop window does not exist).
  Delivery is **idempotent** (D-3): a re-delivered completion (a sweep crash AFTER the parent DECR, BEFORE the
  outbox-clear) finds the child already a `:processed` field (HSETNX returns 0) → no DECR → a no-op; the parent
  is released **exactly once**. The **one residual** is operational, not a correctness defect: a queue whose pump
  **never runs** lingers its outbox undrained → its cross-queue children's parents are **delayed, never dropped**
  (the durable outbox drains on the next pump start — B4). A defensive **re-derivation reconcile** (recompute
  outstanding deps from authoritative child-row state for the pathological pump-never-runs operator error) is an
  **optional emq.3.4 add** — an honest bound, **NOT** an emq.3.3 requirement (the atomic emit makes the common
  path complete without it).
- **B4 — the sweep is an OPERATIONAL REQUIREMENT, with a named recovery (D-2).** The queue **hosting cross-queue
  children** must run an `EchoMQ.Pump` to drain its outbox and deliver its children's completions — the same
  opt-in contract scheduled/repeatable work already has (`pump.ex` moduledoc: a deployment that wants scheduled
  work released runs a pump). The contract states this. **The recovery if it does not**: the durable outbox
  survives on the child's slot; when a pump is **later** started on that queue, the backlog drains and every
  waiting parent is released — **eventual consistency holds even across a pump-absent window** (delayed, never
  lost — the durable-outbox property B3 rests on).
- **B5 — the new outbox subkey joins the lifecycle carry, but is SELF-CLEARING (N1, D-5c).** `emq:{q}:flow:outbox`
  is drained-to-empty by its **own** sweep in steady state — **unlike** `:dependencies`/`:processed` (which
  persist past the parent row until a lifecycle rung sweeps them). Its cleanup disposition is **NAMED** (the §2
  guardrail): a queue that **stops** being swept lingers outbox entries → the deferred emq.3.x lifecycle rung
  enumerates `emq:{q}:flow:outbox` in `admin.ex` `del_job` (`admin.ex:152`) **and** `@drain`'s `wipe()`
  (`admin.ex:90`) — joining the `:dependencies`/`:processed` carry (emq.3.2-N1). **emq.3.3 does NOT build that
  cleanup** (named, deferred); `admin.ex` is **untouched** this rung.
- **B6 — FLAT, one parent level.** emq.3.3's cross-queue fan-in is the flat shape (a parent → its DIRECT
  cross-queue children). Grandchildren (a cross-queue child that is itself a parent — the v1 recursive
  `build_flow_commands`, `flow_producer.ex:238`) and the failure-policy are **emq.3.4**, **Out**; emq.3.3 does
  not pre-empt them.

## Deliverables

emq.3.3 builds (forward-named; the cross-queue surface does not yet exist — Stage-0 confirmed: `add/3` REFUSES
cross-queue at `reject_cross_queue/2` `flows.ex:191`, `sweep/1` has only promote + fire_repeats `pump.ex:91-100`,
no `@flow_deliver` symbol, no `flow:outbox` key, no `parent_queue` field):

- **EMQ.3.3-D1 — the fork gate (settled, FIRST):** the four cross-queue forks **ruled D-1..D-4** (this rung's
  ledger [`./emq-3-3.progress.md`](../../progress/emq-3-3.progress.md) — V-1..V-4 surfaced, D-1..D-4 locked by the Director
  under the 2026-06-15 delegated-authority directive): **D-1** the outbox on the child's slot · **D-2** piggyback
  `EchoMQ.Pump.sweep/1` · **D-3** the `:processed` HSETNX idempotency guard · **D-4** the additive cross-queue
  branch in `@complete` (the single-queue branch byte-frozen) — plus **D-5** (scope + add-side semantics). The
  triad is authored to exactly these arms → **no pre-build re-scope**. Recorded BEFORE any build artifact.
- **EMQ.3.3-D2 — the cross-queue add (`EchoMQ.Flows.add/3` extended; the `reject_cross_queue/2` refusal
  replaced):** `add/3` ADMITS a child whose `:queue` differs from the parent's queue. The add is
  **host-orchestrated and NON-atomic across slots** (D-5b): (1) land the **parent FIRST** — `state =
  awaiting_children`, `:dependencies` = N (the total child count), on the parent's slot (the existing
  same-queue-parent `@enqueue_flow` shape, or a parent-only enqueue when all children are cross-queue); (2) land
  each **child** on its own slot, its row carrying the emq.3.1 `parent` field (the bare parent id) **plus** a new
  **`parent_queue`** field (the parent's queue) — so the child's `@complete` knows which outbox to emit to and the
  deliver knows which slot the parent is on. **FAIL-CLOSED**: a partial add leaves the parent HELD (never
  claimable), host-retryable by id; the parent-first order guarantees the `:dependencies` counter exists before
  any child can complete. Returns `{:ok, {parent_id, [child_id]}}` (the emq.3.1 shape). Each id (parent + every
  child) is gated at `Keyspace.job_key/2` (raises on an ill-formed id — INV4) BEFORE the wire. *Forward-named:*
  `EchoMQ.Flows.add/3` (the cross-queue admit path), `flows.ex`.
- **EMQ.3.3-D3 — the outbox emit (the additive cross-queue branch in `@complete` — D-1/D-4; the single-queue
  branch BYTE-FROZEN):** the cross-queue child's `@complete` (`jobs.ex:152`) gains an **additive branch**: when
  the host detects the child carries a `parent_queue` field (a cross-queue child), it supplies the outbox key
  `emq:{C}:flow:outbox` (a new declared `KEYS[n]`) and the cross-queue ARGV (`parent_queue`, `parent_id`), and
  the script **RPUSHes** the completion entry into the outbox **atomically with the active-set ZREM** (one EVAL
  on the child's slot {C}). The entry encodes `(parent_queue, parent_id, child_id, result)` (the deliver's
  inputs). **The EXISTING single-queue fan-in branch (`if KEYS[3] and was_active == 1`, `jobs.ex:181-188`) stays
  BYTE-UNCHANGED** — it fires only when the host supplies the same-queue parent keys (`KEYS[3..5]`), and the new
  cross-queue branch fires only when the host supplies the outbox key; the two are **mutually exclusive by which
  keys the host appends** (the shipped branch-by-key-presence idiom, `jobs.ex:159/181`). A **non-flow** completion
  (neither extra key set) is byte-unchanged (the emq.3.1 invariant, `jobs.ex:148-151`). The host `complete`
  wrapper detects `parent_queue` HOST-SIDE (via `parent_of/3`-class read, extended to read `parent_queue` too).
  *Forward-named:* the `@complete` cross-queue branch + the host `complete` extension, `jobs.ex`.
- **EMQ.3.3-D4 — the sweep-deliver (the third `Pump.sweep/1` pass + `@flow_deliver` — D-2/D-3):**
  `EchoMQ.Pump.sweep/1` (`pump.ex:91`) gains a **third pass** `deliver_flow_completions(conn, queue, batch)`
  after promote + fire_repeats; `sweep/1`'s return grows to `{:ok, %{promoted, fired, delivered}}`. The pass
  drains `emq:{queue}:flow:outbox` (LIMIT `:batch`) and, **per entry**, issues a new **`@flow_deliver`** EVAL on
  the **parent's slot** (the parent key rebuilt HOST-SIDE via `Keyspace.job_key(parent_queue, parent_id)` from
  the entry's fields — the v1 data-value `parent_key` is NOT lifted; the host builds the declared keys). The
  `@flow_deliver` script (declared keys `KEYS[1]` = the parent's `:dependencies`, `KEYS[2]` = the parent's
  `:processed`, `KEYS[3]` = the parent row, all on the parent's slot; `ARGV[1]` = `child_id`, `ARGV[2]` =
  `result`):
  `if HSETNX(KEYS[2], ARGV[1], ARGV[2]) == 1 then left = DECR(KEYS[1]); if left <= 0 then ZADD(<parent pending>,
  0, parent); HSET(KEYS[3], 'state', 'pending') end end` — the **`:processed` HSETNX guard** (D-3): the DECR fires
  **only on the first record** of a child, so a re-delivered completion is a no-op. After a successful deliver the
  drained entry is removed from the outbox (on slot {C}). The deliver is **at-least-once → effectively-once**
  (B3). *Forward-named:* `deliver_flow_completions/3` + `@flow_deliver`, `pump.ex`.
- **EMQ.3.3-D5 — the lifecycle disposition (NAMED, a carry — the §2 guardrail discharged; D-5c):** emq.3.3
  **names** what retires the **new** `flow:outbox` subkey (and re-affirms the emq.3.2-N1 `:dependencies`/`:processed`
  carry): the deferred emq.3.x lifecycle rung enumerates `emq:{q}:flow:outbox` in **both** `Admin`-surface
  destructive sweeps — `obliterate`'s `del_job` (`admin.ex:152`, today `DEL jk`/`:logs`/`:lock`) **and** `@drain`'s
  `wipe()` (`admin.ex:90`, today `DEL jk`/`:logs`) — joining `:dependencies`/`:processed`. The outbox is
  **self-clearing** in steady state (its own sweep drains it), so the at-rest concern is only a queue that STOPS
  being swept. **emq.3.3 adds ZERO cleanup** (named, deferred); `admin.ex` is untouched. *Check:* the body names
  the outbox's cleanup home (both sweeps) + the owning rung; emq.3.3's touch-set adds no `DEL`/`HDEL`/`UNLINK` of
  a flow subkey; `admin.ex` is untouched.
- **EMQ.3.3-D6 — the proof:** the `:valkey` cross-queue suite green per-app; the mint/process-touching
  cross-queue scenario (a flow minting a parent + N children **across queues**, each completed → emitted, the
  sweep run, the parent released) under the **≥100-iteration determinism loop** owning the machine (one green run
  is NOT proof — the master-invariant hazard; a cross-queue flow mints many ids across queues); the prior emq.1 +
  emq.2.{1,2,3,4} + emq.3.{1,2} suites + `Conformance.run/2` pass **unchanged** (no regression — INV3); the
  **single-queue `@complete` fan-in branch byte-unchanged** (git-diff shows only ADDED lines; the existing
  branches at `jobs.ex:152-191` untouched — INV3, the HIGH-risk regression bound); honest-row reporting (Valkey
  on 6390 the truth row); the `flow_cross_queue` scenario registered additive-minor with the prior 46
  byte-unchanged; **Apollo MANDATORY** (HIGH-risk — a shipped-script edit + a new cross-slot mechanism; D-1
  risk-tier).

## Invariants (runnable checks)

- **EMQ.3.3-INV1 — the wire law (no break, no new wire class, no new transport; one additive shipped-script
  branch).** emq.3.3 adds **no new wire class** (the emit/deliver are plain `RPUSH`/`HSETNX`/`DECR`/`ZADD`/`HSET`
  — no fence code, no `EMQ…` class); **no new transport** (the connector `eval` carries both `@complete` and
  `@flow_deliver`; no `SSUBSCRIBE`); and edits **exactly one** shipped Lua script — `@complete`, **additively**
  (a new branch gated on a host-supplied key the shipped callers never pass). The five-code fence union stands
  unextended; the closed wire-class registry is unchanged. *Check:* a `git diff` of every `@… Script.new/2`
  attribute in `jobs.ex` + `flows.ex` + `pump.ex` shows **only** (a) ADDED lines in `@complete`'s body (the new
  cross-queue branch; the existing branches byte-identical) and (b) the NEW `@flow_deliver` attribute; no other
  `Script.new/2` body changes; `keyspace.ex`'s grammar is unedited.
- **EMQ.3.3-INV2 — the declared-keys A-1 law over the new scripts (S-6, the slot-soundness obligation).** Every
  key in the `@complete` cross-queue branch and in `@flow_deliver` is **declared in `KEYS[]`** or grammar-rooted
  from a declared `KEYS[n]` (the `@extend_locks` `base .. 'job:' .. id` form, ratified 2026-06-14,
  `design.md:102-112`). The emit branch's keys are **all on the child's slot {C}** (the active set + the outbox);
  `@flow_deliver`'s keys are **all on the parent's slot {P}** (the parent's `:dependencies` + `:processed` +
  row). **No script mixes slots; no key is read out of a data value in Lua** (the v1 `parent_key` data-value
  form, `flow_producer.ex:354/327`, is NOT lifted — the host reads the child's `parent`/`parent_queue` fields
  HOST-SIDE and passes declared keys, the emq.3.1 pattern extended). *Check:* a grep over the new emit branch +
  `@flow_deliver` confirms every `redis.call` key argument is a `KEYS[n]` or `ARGV[base] .. <literal>`; a
  reviewer names the single slot of each script's key set (the CROSSSLOT-invisible-on-single-node-6390 F-1 trap —
  the engine on 6390 will NOT catch a cross-slot key; the review + the declared-keys grep must).
- **EMQ.3.3-INV3 — the shipped surface is byte-unchanged except the one additive `@complete` branch (the
  HIGH-risk regression bound).** A job with **no parent** flows through `@enqueue`/`@claim`/`@complete` exactly as
  emq.3.2 shipped; a **single-queue** flow child fans in through the **byte-frozen** `@complete` fan-in branch
  (`jobs.ex:181-188`) exactly as emq.3.1 shipped; the cross-queue branch fires **only** on the host-supplied
  outbox key (provably false for every shipped path). *Check:* the emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2} suites +
  `Conformance.run/2` pass **unchanged**; the prior **46** conformance scenarios are byte-identical (name +
  contract + verdict body, git-verified); the `git diff` of `@complete` shows the existing non-flow / flat /
  grouped-lane / single-queue-flow branches (`jobs.ex:152-191`) **byte-identical** (only ADDED lines for the new
  branch); Apollo's explicit byte-check confirms it.
- **EMQ.3.3-INV4 — branded identity at every boundary.** The cross-queue `add/3` gates **every** id (parent +
  each child) at `Keyspace.job_key/2` (which gates `BrandedId.valid?/1` and raises before any wire); the deliver
  rebuilds the parent key through `Keyspace.job_key(parent_queue, parent_id)` (gated). An ill-formed id raises at
  the key builder, never reaching a key. *Check:* a cross-queue `add/3` with an ill-formed child id raises at
  `Keyspace.job_key/2`; a deliver of an entry whose parent id is valid issues a well-formed
  `:dependencies`/`:processed` key on the parent's slot.
- **EMQ.3.3-INV5 — the cross-queue fan-in is eventually-consistent (INV7, the cross-queue honesty — the
  headline).** The contract states the consistency model **explicitly**: a cross-queue child completing releases
  its parent **on the next sweep tick** of the queue whose outbox holds the entry (latency bounded by
  `:tick_ms`), **never synchronously**, **never "atomic across queues."** *Check (the `flow_cross_queue`
  scenario):* a `:valkey` scenario adds a cross-queue flow (a parent in P, a child in C ≠ P), completes the
  child, asserts the parent is **still held** (`claim` on P answers `:empty`; `dependencies/3` still > 0)
  **before** any sweep, then runs `deliver_flow_completions` (or a `Pump` tick), then asserts the parent is
  **released** (claimable; `dependencies/3` == 0) — the parent moved on the **sweep**, not on the completion.
- **EMQ.3.3-INV6 — idempotent delivery (at-least-once → effectively-once; the crash-recovery keystone, D-3).**
  A re-delivered completion **does not double-DECR**: `@flow_deliver` DECRs `:dependencies` only when its HSETNX
  of the child into `:processed` succeeds (returns 1), so re-running the deliver for an already-recorded child is
  a **no-op** — the parent is released **exactly once**. *Check (the `flow_cross_queue` scenario):* the scenario
  runs `@flow_deliver` for the same child **twice** (simulating a sweep re-delivery) and asserts `:dependencies`
  decremented **once** (not twice), `:processed[child]` is the result, and the parent is released exactly once;
  the second deliver returns its no-op verdict.
- **EMQ.3.3-INV7 — emission atomic with completion (the no-drop guarantee, D-1/D-4).** The cross-queue child's
  outbox RPUSH and its active-set ZREM are **one EVAL** on the child's slot {C}: a completed cross-queue child
  **always** has a durable outbox entry — there is **no state** where the child completed but produced no signal
  (the drop window does not exist). *Check:* the `@complete` cross-queue branch performs the outbox `RPUSH` and
  the active `ZREM` in the **same** `Script.new/2` body (one EVAL); a `:valkey` scenario completes a cross-queue
  child and asserts (before any sweep) the outbox holds exactly one entry for it AND the child is gone from
  `active` — both effects of the one EVAL.
- **EMQ.3.3-INV8 — the additive-minor conformance law.** `flow_cross_queue` is registered in `scenarios/0`
  **with its probe in the same change**; the prior **46** scenarios pass **byte-unchanged**; the count re-pinned
  **46 → 47** in **both** pinning tests (`conformance_scenarios_test.exs` + `conformance_run_test.exs`). *Check:*
  the `git diff` shows only additions to `scenarios/0`; both pin tests assert the new total **47**;
  `Conformance.run/2` prints the new line count and returns `{:ok, 47}`.
- **EMQ.3.3-INV9 — the new outbox subkey's lifecycle is NAMED (the §2 guardrail, D-5c).** The spec body **names**
  the cleanup disposition for the new `flow:outbox` subkey — both FIXED-list destructive sweeps (`obliterate`'s
  `del_job` `admin.ex:152` **and** `@drain`'s `wipe()` `admin.ex:90`) gaining `emq:{q}:flow:outbox`, routed to
  the emq.3.x lifecycle rung (D-5/B5), joining the emq.3.2-N1 `:dependencies`/`:processed` carry; the outbox is
  self-clearing in steady state. emq.3.3 adds **no** cleanup. *Check:* the body names the outbox's cleanup home
  (both sweeps) + the owning rung; emq.3.3's touch-set contains **no** `DEL`/`HDEL`/`UNLINK` of a flow subkey;
  `admin.ex` is untouched.
- **EMQ.3.3-INV10 — slot soundness + the family boundary (FLAT cross-queue, one parent level).** The emit's keys
  are exactly the child's `{C}` slot; the deliver's keys are exactly the parent's `{P}` slot; emq.3.3 ships the
  FLAT cross-queue fan-in only — no failure-policy (emq.3.4), no `add_bulk` (emq.3.4), no grandchildren/deep
  recursion (emq.3.4); it re-ships no emq.2 surface and pre-empts no Movement-II family. *Check:* the emit/deliver
  scripts each build keys of exactly one slot; the deliverable touch-set is the cross-queue add + the emit branch
  + the deliver pass + the conformance scenario; the body names the boundary and the honest bounds B1–B6.

## Definition of Done

- [ ] EMQ.3.3-D1: the four forks ruled D-1..D-4 (+ D-5) recorded BEFORE any build artifact (the gate that opened
      the build); the triad authored to the ruled arms → no pre-build re-scope.
- [ ] The cross-queue add built (D2): `EchoMQ.Flows.add/3` admits cross-queue children, host-orchestrated,
      NON-atomic across slots, parent-first, fail-closed (the parent held on a partial add); each cross-queue
      child carries `parent` + `parent_queue`; every id gated at `Keyspace.job_key/2`; the `reject_cross_queue/2`
      refusal replaced.
- [ ] The outbox emit built (D3, D-1/D-4 — the additive `@complete` branch): the cross-queue child's completion
      RPUSHes `(parent_queue, parent_id, child_id, result)` into `emq:{C}:flow:outbox` atomically with the
      active-ZREM (one EVAL); the single-queue fan-in branch (`jobs.ex:181-188`) byte-frozen; the non-flow path
      byte-unchanged.
- [ ] The sweep-deliver built (D4, D-2/D-3): `EchoMQ.Pump.sweep/1` gains `deliver_flow_completions` (→ `%{…,
      delivered}`); `@flow_deliver` records the child via HSETNX + DECRs only on first-record + at-zero releases
      the parent on the parent's slot; the drained entry removed; delivery idempotent (re-deliver is a no-op).
- [ ] The lifecycle disposition NAMED (D5, B5): `emq:{q}:flow:outbox` routed to the emq.3.x lifecycle rung (both
      destructive sweeps), joining the `:dependencies`/`:processed` carry; emq.3.3 added no cleanup; `admin.ex`
      untouched.
- [ ] `flow_cross_queue` registered (D6/INV8, additive minor): the prior 46 conformance scenarios byte-unchanged;
      the count re-pinned **46 → 47** in both pinning tests.
- [ ] The proof (D6): the `:valkey` cross-queue suite green per-app; the **≥100 determinism loop** green for the
      mint/process-touching cross-queue scenario; the emq.1 + emq.2.{1,2,3,4} + emq.3.{1,2} suites +
      `Conformance.run/2` passed unchanged (no regression — INV3); the single-queue `@complete` fan-in branch
      **byte-unchanged** (git-diff only-added-lines, Apollo's byte-check); honest-row reporting (Valkey on 6390);
      **Apollo MANDATORY** verified (HIGH-risk).
- [ ] INV1–INV10 verified as runnable checks; the spec body remains authoritative; the post-build reconcile
      (Stage 5/Stage 7) syncs it to the as-built surface.

Stories: [`./emq.3.3.stories.md`](emq.3.3.stories.md) · Agent brief: [`./emq.3.3.llms.md`](emq.3.3.llms.md) ·
Runbook: [`./emq.3.3.prompt.md`](emq.3.3.prompt.md) (the design-authoring runbook; the build runbook this cycle
authors) · Family: [`./emq.3.md`](../emq.3.md) (the contract, the carve, Fork A's cross-queue arm + INV7 — the
authoritative family ground) · The shipped slices (the floor emq.3.3 extends): [`./emq.3.1.md`](emq.3.1.md)
(`EchoMQ.Flows.add/3` the same-queue atomic add, the `:processed`/`:dependencies` subkeys, the `@complete` fan-in
branch `jobs.ex:181-188`, the O1/O2/L-5 honest bounds) + [`./emq.3.2.md`](emq.3.2.md) (`children_values/3` /
`dependencies/3`, the real-result `complete/5`, the N1 lifecycle carry emq.3.3 extends) · This rung's ledger (the
ruled forks): [`./emq-3-3.progress.md`](../../progress/emq-3-3.progress.md) (V-1..V-4 surfaced; **D-1..D-5** locked — the arms
this triad is authored to) · The v1 capability reference (READ-ONLY, the FORM not to lift):
`echo/apps/echomq/lib/echomq/flow_producer.ex` (`add/2` `:123`, `add_bulk/2` `:183`, the per-node `queue_name`
spanning `:28-30`, the data-value `parent_key` tree `:354/327` that v2 does NOT lift) · The promote-sweep
precedent: `echo/apps/echo_mq/lib/echo_mq/pump.ex` (`EchoMQ.Pump.sweep/1` `:91`, `:transient`/`:tick_ms`/`:batch`)
· As-built surface (the floor, re-pinned at the pre-build reconcile): `echo/apps/echo_mq/lib/echo_mq/flows.ex`
(`add/3` `:83`, `reject_cross_queue/2` `:191` the host-refusal emq.3.3 replaces, `@enqueue_flow` `:39` UNTOUCHED)
+ `echo/apps/echo_mq/lib/echo_mq/jobs.ex` (`@complete` `:152`, the single-queue fan-in branch `:181-188` the
byte-frozen bound, `complete/5` `:365`, `parent_of/3` `:397` the host read extended to `parent_queue`,
`@extend_locks` `:664` the A-1 slot-rooted-ARGV precedent) + `echo/apps/echo_mq/lib/echo_mq/keyspace.ex`

> **[POST-BUILD RECONCILE — Apollo, emq-3-4 verdict 2026-06-15, BUILD-GRADE]** The PRE-build line anchors above
> (and inline throughout this body) drifted by the cross-queue branch insertion — the SHIPPED `as-built` numbering
> is: `@complete` attr opens at **`jobs.ex:175`** (was `:152`); the byte-frozen single-queue fan-in branch
> `if KEYS[3] and was_active == 1` is now **`jobs.ex:212-219`** (was `:181-188`); the additive cross-queue emit
> branch (gated `ARGV[6] == 'xq'`, early-return) is **`jobs.ex:204-211`**; `complete/5` is **`:412`**, `parent_of/3`
> **`:459`** (now an `HMGET parent parent_queue` dispatch). The cross-queue ADD landed via TWO new single-slot
> scripts (the realization the body left open, D-5b): `@hold_parent` **`flows.ex:73`** + `@enqueue_flow_child`
> **`flows.ex:90`**; `add/3` is **`:152`**, `add_cross_queue` **`:285`**. The sweep-deliver is `@flow_deliver`
> **`pump.ex:42`** + `deliver_flow_completions/3` **`:161`** + `deliver_one/2` **`:202`**; `sweep/1` **`:126`**. The
> `flow_cross_queue` probe is **`conformance.ex:1140`**; count re-pinned **46→47** in both pins. The branches'
> byte-freeze, the four scripts' declared-keys/slot-soundness, and the conformance additive-minor are all VERIFIED
> against this shipped surface (the prose + contract are faithful — only the line numbers moved). See ledger
> `emq-3-4.progress.md` (Y-1).
+ `echo/apps/echo_mq/lib/echo_mq/keyspace.ex`
(`queue_key/2` `:14` the pure composer — `queue_key(q, "flow:outbox")` composes the outbox key, UNEDITED;
`job_key/2` `:17` the gated builder) + `echo/apps/echo_mq/lib/echo_mq/conformance.ex` (the **46**-scenario set;
`flow_cross_queue` + its `apply_scenario` probe NEW) + `echo/apps/echo_mq/lib/echo_mq/admin.ex` (`del_job`
`:152` / `@drain` `wipe()` `:90` the FIXED enumerations — the N1 carry, UNTOUCHED) · Design:
[`../emq.design.md`](../../../emq.design.md) §6 (the grammar — the slot constraint forcing the cross-queue fork;
`:298-324`), §11.10 (the deferral + the owed flow design; `:447-451`), §5 (no new wire class), S-6 (the
declared-keys A-1 law; `:95-112`), S-1/§6 (the braced keyspace — the slot constraint), §11.12 (the escalation
protocol) · Roadmap: [`../emq.roadmap.md`](../../../emq.roadmap.md) Movement I (the closer) · The feature catalog:
[`../emq.features.md`](../../../emq.features.md) (the emq.3 row) · Approach:
[`../../elixir/specs/specs.approach.md`](../../../../elixir/specs/specs.approach.md)
