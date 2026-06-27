# Codemojex Revenue Model — design-ahead KB

A two-architect design-ahead of the **revenue model** — the cost-per-key question broadened to a weighted-average
cost basis on the player balance and an Analytics Engine for revenue flow — authored for **independent Operator
review** before the cost-basis surface freezes. Method of record:
[`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) (four-part arms; the
multi-architect debate). Pattern: [`../auth-flow/`](../auth-flow/).

**The seed (the Operator's question):** *How is revenue calculated when the cost per key differs across packages?*
The package ladder ([`economy.packages.md`](../../specs/economy/economy.packages.md)) discounts the **price paid**
(5 keys = 99⭐ ≈ 19.8⭐/key … 1000 keys = 9999⭐ ≈ 10⭐/key), not the booked **gross**. Two figures, never
conflated: the **gross** (what arrived — the discount already inside it) is the recognized revenue; the **WAC**
(the blended cost-per-key the discount *lowers*) is the separate cost basis that makes recognition-at-consumption
and a safe cm.8 withdrawal possible.

**The model (the convergent design):** **two orthogonal ledgers** — the byte-frozen native-unit `revenue_ledger`
(the GROSS, cm.6/cm.7, untouched) and a NEW single-canonical-unit **weighted-average cost basis (WAC)** on the
player balance — **bound by a read-time money-conservation property test**, read through a **layered Analytics
Engine** whose money floor is SoR-exact Postgres. Every fork is a choice about the *second* ledger; none touches
the first (G2).

| Doc | Author | What it is |
|---|---|---|
| [`revenue.brief.md`](./revenue.brief.md) | Director | The shared, identical locked-constraints brief — the seed, the GIVENs (G1–G6), the five forks (F1–F5), the ground truth, the deliverable contract. |
| [`revenue.design.ledger-lens.md`](./revenue.design.ledger-lens.md) | Venus-Revenue-Ledger | Every fork from the **accounting / ledger / cost-basis** lens: recognition timing, the WAC mechanics + the conservation invariant, the frozen-`revenue_ledger` integration, the cm.8 withdrawal-cost seam. |
| [`revenue.design.shop-lens.md`](./revenue.design.shop-lens.md) | Venus-Revenue-Shop | Every fork from the **pricing / pay-in / product / analytics** lens: the package → cost-per-key feed, the multi-rail rate handling, the Analytics Engine product surface (the revenue-flow funnel), the withdrawal-rate product bind. |
| [`revenue.synthesis.md`](./revenue.synthesis.md) | Director | The cross-lens diff: the **convergence on all five forks**, the three narrow divergences (Δ1 unit · Δ2 conservation completeness · Δ3 gross-vs-net basis), the rung-sequencing options, and the forks surfaced for the Operator to rule. |

**Read order for review:** the synthesis first (the convergent spine + the three divergences + the sequencing),
then either lens doc for the full four-part argument behind any fork.

**The GIVENs (Operator-ruled, carried by both):** **G1** track a weighted-average cost per key on the player
balance account (the Operator's Fork) · **G2** the cm.6 `revenue_ledger` is byte-frozen (additive only) · **G3**
cm.7 KeyShop is the pay-in surface (gross booked at pay-in; the WAC reconciles *with* it) · **G4** cm.8 =
withdrawals (the WAC must serve a safe payout rate) · **G5** the broadened scope = an Analytics Engine for revenue
flow · **G6** boundary `echo/apps/codemojex/**` + the BCS brand law.

**The convergence (the headline):** the two lenses, blind, ranked the **same winning arm on all five forks** —
F1 Hybrid · F2 one running cost-basis field · F3 one canonical unit · F4 a layered engine with a Postgres money
floor · F5 a read-time conservation property test. The genuine decisions left for the Operator are three sub-points
(the synthesis §3) + the rung-sequencing (§4).

**Status:** design-ahead, uncommitted, for review. **No code, no canon edit, no migration** — the cost-basis
surface is forward-tense throughout; the cm.7 reconcile + the cost-basis/recognition rung's spec triad are the
post-ruling steps. The `revenue_ledger` (cm.6) stays byte-frozen; cm.7 stays as-ruled (a light seam note only).
Audit ledger: [`../../specs/progress/cm-revenue-model.progress.md`](../../specs/progress/cm-revenue-model.progress.md).
