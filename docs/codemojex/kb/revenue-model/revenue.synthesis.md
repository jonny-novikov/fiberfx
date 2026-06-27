# Revenue Model — the Director's synthesis (cross-lens)

> The cross-lens diff of the blind dual-architect debate over [`revenue.brief.md`](./revenue.brief.md):
> **Venus-Revenue-Ledger** (the accounting / ledger / cost-basis lens, [`revenue.design.ledger-lens.md`](./revenue.design.ledger-lens.md))
> ∥ **Venus-Revenue-Shop** (the pricing / pay-in / product / analytics lens, [`revenue.design.shop-lens.md`](./revenue.design.shop-lens.md)).
> Both argued the same five forks blind, from divergent lenses; neither read the other. This doc **stages** the
> convergence and the narrow divergences and **surfaces the open forks for the Operator to rule** — it decides
> none (the [`aaw.architect-approach`](../../../aaw/aaw.architect-approach.md): the architects argue, the Director
> synthesizes, the Operator rules). NO-INVENT; framing law (third person; no first-person-agent narration; no
> perceptual / interior-state verbs).

## 1. The headline — a high-convergence design

The blind pass returned the strongest signal it can: **the two lenses converged on the winning arm of all five
forks.** An accounting lens optimizing for *books that balance and survive audit* and a product lens optimizing
for *what the operator must read and what makes the discount ladder safe* independently reached the **same**
architecture. When opposite lenses agree blind, the design is load-bearing, not lens-dependent.

The agreed model in one sentence: **two orthogonal ledgers** — the byte-frozen native-unit `revenue_ledger` (the
GROSS, *"what arrived,"* cm.6/cm.7, untouched) and a NEW single-canonical-unit **weighted-average cost basis
(WAC)** carried on the player balance (*"what the keys cost"*) — **bound by a read-time money-conservation property
test**, read through a **layered Analytics Engine** whose money floor is SoR-exact Postgres. Every fork is a choice
about the *second* ledger; **none touches the first** (G2 holds throughout).

This directly answers the Operator's seed question. *How is revenue calculated when cost-per-key differs across
packages?* — **two figures, never conflated:** the booked **gross** (what arrived, discount already inside it,
cost-per-key irrelevant) is the revenue the platform recognizes; the **WAC** (the blended cost-per-key, which the
discount *lowers*) is the separate cost basis that makes recognition-at-consumption and a safe withdrawal possible.

## 2. The convergent spine (both lenses, same winner)

| Fork | Ledger rank | Shop rank | Converged | The agreed shape |
|---|---|---|---|---|
| **F1** recognition | **C** ≻ A ≻ B | **C** ≻ A ≻ B | **C — Hybrid** | gross stays the booked/cash revenue (frozen); realized-vs-deferred is a DERIVED projection priced at WAC. Accrual-as-replacement breaks G2 — off the table. |
| **F2** WAC mechanics | **A** ≻ C ≻ B | **A** ≻ B ≻ C | **A — one running field** | a single cost-basis field on `players`; store the TOTAL basis (re-blend = pure addition), derive avg at read; O(1), append-aligned. Cost-lots (B) rejected — over-engineered for a WAC + breaks append-only. |
| **F3** multi-currency | **A≡C** ≻ B | **C≈A** ≻ B | **A/C — canonical unit** | normalize each acquisition to ONE canonical USD sub-unit ONCE, from cm.7's PINNED order rate (`D-4`); the revenue_ledger stays native. Per-rail (B) rejected — fungibility forbids N bases on one key pool. |
| **F4** analytics | **A** ≻ C ≻ B (layered) | **A** ≻ C ≻ B (layered) | **layered (A floor)** | money reads = SoR-exact Postgres projection (extends `revenue_breakdown/1`); cohort/funnel = forward `AEV` + `cm-bitmapist`; EchoStore = a later live cache. |
| **F5** conservation | a deliverable + property test | Statement 1 + property test | **canonical-USD property test** | a read-time money-conservation identity, property/grid-tested, ALONGSIDE (never replacing) cm.6's keys-unit conservation; dust pinned to one named bucket. |

Both lenses even converged on the **audit mechanism** for F2: the running field is authoritative, reconciled by a
property test that re-folds the `orders` history (the cm.6 conservation precedent). The ledger lens framed
derived-on-read as *"the AUDIT of the field"*; the shop lens independently proposed *"a reconciliation property
test: running field ≡ fold-over-orders."* Same mechanism, two names — a second-order convergence.

**The five, in one line each:**

- **F1 — Hybrid.** Keep the frozen `revenue_ledger` booking gross-at-pay-in (the cash/bookings ledger, the tax +
  21-day-hold-liquidity truth); add the realized/deferred accrual split as a *derived read* priced at WAC
  (`realized = Σ keys_consumed·WAC`, `deferred = Σ outstanding_keys·WAC`). The only accrual-correct path that
  respects G2 — both numbers, one store, no frozen-row touch. The games-industry **bookings vs revenue** dual.
- **F2 — one running field.** `players.key_cost_basis_*` holding the *total* canonical cost of the current
  balance; buy = `basis += cost` (pure addition, no division → no acquisition dust); spend of `S` of `K` =
  `cost_out = floor(basis·S/K); basis -= cost_out` (the remainder stays attached → washes to 0 on spend-all).
  O(1), one column, on the account (G1 literally), append-aligned. WAC's order-independence on spend means **no
  consumption-order rule** — the property that kills cost-lots (B) for a *ruled* WAC.
- **F3 — one canonical unit.** A fungible key pool can carry exactly one cost basis; normalize each acquisition to
  a fine canonical USD sub-unit ONCE at settlement, from the rate cm.7 already **pins** on the order (`D-4` →
  reproducible, never re-read). This does **not** violate cm.7 `D-6` F5 — that governs the *native* revenue
  ledger (untouched); the WAC is a *separate* derived canonical basis (both lenses reached this independently).
- **F4 — layered.** Money reads (gross · realized/deferred · liability-at-WAC · margin) are SoR-exact Postgres
  aggregates extending `revenue_breakdown/1` (the launch floor); the actor cohort/funnel (buyers→spenders→
  winners→withdrawers, LTV/retention) is the forward `AEV` event stream over the as-built `cm-bitmapist` edge;
  an EchoStore near-cache is a later serving tier *only if* the dashboard gets hot. Each read where its
  consistency need lands it — the `mesh.8.1` CAP-segmentation discipline applied to analytics.
- **F5 — one conservation identity, property-tested.** A read-time money-conservation invariant in the canonical
  unit, swept by a property/grid test (the cm.6 lesson — a fixed-example suite missed the M5 floor-divergence
  survivor), running ALONGSIDE cm.6's keys-unit three-term conservation (which it reads and values, never breaks).

## 3. The narrow divergences (what the Operator actually rules)

Convergence on the arms means the genuine decisions are **not** *"which approach"* — they are three sharp
sub-points the lenses split on, or that only one lens reached.

### Δ1 — The cost-basis unit: micro-USD (store) vs cents (read) — RECONCILABLE

The ledger lens stores **µUSD** (`key_cost_basis_micros`, 1e-6 USD) so the per-key WAC (≈ 13–26¢) is
integer-exact and the per-key division dust is `< 1 µUSD`. The shop lens names **cents** (`key_cost_basis_cents`,
the operator's native read unit) and flags a real precision trap: do **not** name it `*_minor` — that conflates
it with cm.7's rail minor units (nanoTON/kopeck). **Synthesis (reconcilable):** STORE in the fine unit (µUSD, for
integer-exact division + structural dust), READ/roll-up in cents (the operator's unit). These are the *storage*
and *read* units of one field — not a real conflict. **Recommendation: store µUSD, present cents** — ratify on
default unless the Operator prefers cents-storage (which reintroduces per-key division dust).

### Δ2 — The conservation identity's completeness — the asymmetric CATCH (adopt the superset)

The ledger lens caught **two terms the brief's candidate AND the shop's Statement 1 both omit** — terms a game
*with a prize pool and winnings* cannot omit:

1. **`B_win` — the winnings injection.** Keys minted from WON 💎 (`convert_to_keys`, 10💎 = 1 key) enter the
   balance with a cost basis from the diamonds' value, **not** from pay-in. Omit it and the identity will not
   balance for any player who has won.
2. **The pool-transfer-vs-realized split.** Keys spent on golden guesses + the buy-in **pool portion**
   (`entry_fee_split_keys`) fund the **prize pool** — a liability the platform owes the winners, **not** revenue.
   Only paid-room guess fees + the buy-in **house cut** are realized revenue. Lumping all spend into "realized"
   (the brief's + the shop's candidate) **overstates revenue by the pool transfer.**

This is a **correctness catch, not a preference.** **Synthesis: adopt the ledger lens's refined superset
identity** — it is strictly more correct, and it reconciles with (does not break) cm.6's keys-unit conservation.
This is the dual-architect's headline value-add: one lens caught what the brief and the other lens missed.

### Δ3 — The WAC basis: GROSS vs NET of store fee — the shop-only finding (GENUINE)

The shop lens surfaced (§8.3) what the ledger lens did not: the ~32% mobile / ~3% desktop store fee makes "cost
basis" **two numbers**. Is the WAC the player's **GROSS** paid amount, or the platform's **NET** (gross − store
fee)? The shop's resolution: **WAC = GROSS** (the conservative withdrawal floor — a player can never extract more
than they paid); the **net take-home is a separate read-time margin figure** (R4 = gross − store fee). This is
load-bearing for both the withdrawal floor and the margin number, and invisible from a pure ledger view.
**GENUINE — the Operator should rule it** (it sets what "cost basis" means everywhere downstream).

## 4. The sequencing — how this lands as rungs (the "prepare to write specs" decision)

Grounded in [`codemojex.roadmap.md`](../../codemojex.roadmap.md): cm.6 (revenue_ledger, **shipped**) → cm.7
(multi-rail pay-in, **ruled**) → **cm.8** (cash-out/treasury, withdrawals — *consumes the WAC*) → cm.9+ (the rake,
`AEV` analytics, LiveAdmin — already deferred). The WAC cost-basis is the **foundation cm.8 needs**, logically
sitting **between cm.7 (pay-in) and cm.8 (withdrawal)**. The money-floor analytics rides on the WAC; the cohort/
funnel (`AEV` + `cm-bitmapist`) is already roadmap'd to cm.9+. Three placements for the WAC + recognition +
money-floor:

| Option | Shape | Trade |
|---|---|---|
| **A — a dedicated cost-basis / recognition rung** (between cm.7 and cm.8) | cm.7 stays multi-rail pay-in only; a new rung adds the WAC field + canonical normalization + the spend-path flow + the conservation property test + the F1-C realized/deferred Postgres projection; cm.8 consumes it | **(recommended)** clean separation; cm.7 stays focused (it is already HIGH-risk + large); the WAC lands as its own money-critical rung with its own property-test gate |
| **B — fold the WAC into cm.7** | `settle_payment/1` already holds `order.keys` + `price_minor` + the pinned rate, so it can emit the WAC update inline | bloats an already-HIGH-risk rung; couples the recognition model to the pay-in cutover |
| **C — fold the WAC into cm.8** | the withdrawal rung needs it, so build it there | defers the cost basis until withdrawals; bloats cm.8 with recognition + analytics on top of KYC/holds/rates |

The **cm.7 reconcile** (the Operator's explicit ask) is **light either way**: add the forward note that the WAC
consumes `settle_payment`'s pinned-rate output, and confirm gross-stays-the-booked-revenue (F1-C) — cm.7's
`revenue_ledger` booking is unchanged; the reconcile only records the seam the WAC plugs into.

## 5. The Director's recommendation

Ratify the **convergent spine** (F1-C Hybrid · F2-A running field · F3 canonical-unit · F4 layered/Postgres-floor
· F5 conservation property test). Rule the three deltas as: **Δ1** store µUSD / read cents; **Δ2** adopt the
ledger lens's refined superset identity (with `B_win` + the pool-transfer split); **Δ3** WAC = the **gross** cost
basis (the conservative withdrawal floor), net take-home a separate margin read. Sequence as **Option A** — a
dedicated cost-basis/recognition rung between cm.7 and cm.8, with a light cm.7 reconcile recording the seam. The
recommended path needs **no new brand** for the cost basis (a `players` column + a nullable `cost_*` annotation on
the keys-movement `TXN`); it cites the named-forward **`AEV`** (the analytics funnel) and **`WDR`** (the cm.8
withdrawal record); **`LOT`** is surfaced only as the brand the rejected cost-lots arm (F2-B) would require — its
presence is the signal that ruling F2-B costs a new branded, mutable, append-breaking table.

## 6. What the Operator rules (the surfaced forks → `AskUserQuestion`)

1. **The recognition model (F1)** — ratify **Hybrid** (gross booked + a derived realized/deferred view), or ship
   **cash-only** at launch and defer the accrual projection.
2. **The WAC basis (Δ3)** — **GROSS** (conservative floor) vs **NET** of store fee.
3. **The sequencing (§4)** — Option A (dedicated rung) vs B (fold into cm.7) vs C (fold into cm.8).

Δ1 (µUSD-store/cents-read) and Δ2 (adopt the refined identity) are **ratified by default** in the synthesis —
clear technical resolutions, surfaced here for visibility, overridable on request.

## 7. The NO-INVENT ledger (both lenses' ground-truth corrections — and the one disk adjudicated)

Both lenses ran NO-INVENT and it paid off — and they **split on one fact**, which the Director resolved on disk:

- **The bitmapist path.** The brief said `infra/codemojex-bitmapist`; the on-disk dir is **`infra/cm-bitmapist`**
  (the ledger lens's catch). **Disk confirms `infra/cm-bitmapist/` EXISTS** (a Go service, branded-id-native).
  The shop lens probed the brief's *wrong* name and concluded **ABSENT** — incorrect; the substrate is **as-built**.
  **Resolution:** the `cm-bitmapist` **substrate is as-built**; the **`AEV` brand + the marker wiring are forward**
  (both lenses agree the funnel *tier* is unbuilt). The synthesis cites the substrate as real, the wiring as cm.9+.
- **The `D-6` reconcile.** Canonical-µUSD WAC does **not** violate cm.7 `D-6` F5 ("store native, convert at read")
  — they govern **different ledgers**: the `revenue_ledger` stays native + frozen; the WAC is a separate derived
  canonical basis from the *pinned* rate. **Both lenses reached this independently** — a convergent NO-INVENT
  clearing of the one apparent contradiction in the brief.

---

**Status:** synthesis complete; the three forks are surfaced for the Operator. On the rulings: the `cm-n`
decisions (`D-1…`) are locked, this README + the cm.7 triad are reconciled (the light seam note), and the cost-
basis/recognition rung's spec triad is authored. **No production code, no migration exists before the approved
design** (the design-phase discipline). The Operator rules; then the specs are written.
