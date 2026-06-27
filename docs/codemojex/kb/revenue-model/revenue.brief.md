# Revenue Model — the locked-constraints brief (the dual-architect debate)

> The **shared, identical** brief for the blind design pass: **Venus-Revenue-Ledger ∥ Venus-Revenue-Shop**.
> Method of record: [`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) (four-part
> arms; the multi-architect debate). Pattern: [`../auth-flow/`](../auth-flow/) (README + two lens docs + a
> Director synthesis). Both architects argue the **same forks** from a **divergent lens**; neither reads the
> other until both land. The Director synthesizes; the Operator rules. **NO-INVENT:** every named surface is
> grounded at a real `file:line` in `echo/apps/codemojex`, or written forward-tense for surface not yet built.
> Framing law: third person for any agent reference; no first-person-agent narration; no perceptual /
> interior-state verbs (sees / notices / feels).

## The seed problem (what the Operator asked)

> *How is revenue calculated when the cost per key differs across packages?*

Packages discount the **price the player pays**, not directly the **revenue booked**. Two distinct figures must
never be conflated:

1. **Booked pay-in revenue = the GROSS rail amount received** (cm.7, already specced). Buy 1000 keys for 9,999⭐
   → the platform books `+9999` `currency="stars"` to the `revenue_ledger`. The 50 % discount is *already inside*
   that 9,999 — there is nothing to normalize. Revenue-per-package = *what arrived*; cost-per-key is irrelevant
   to **this** number.
2. **Cost basis per key = the weighted-average cost (WAC)** — the Operator's Fork. The same fungible key enters a
   balance at ~19.8⭐ (the 5-pack) or ~10⭐ (the 1000-pack), **and** across four rails at floating rates, so a
   player's key balance is a **blend**. `on buy: new_avg = (old_keys·old_avg + bought_keys·unit_price) /
   (old_keys + bought_keys)`; `on spend: avg unchanged, the cost that flows out = keys_spent · avg`.

The WAC is the number that makes the **middle** of the money pipe conserve — the figure the gross cannot supply:
it is what lets revenue be **recognized at consumption** (unspent keys = a deferred-revenue liability at WAC) and
what prices a **safe withdrawal** in cm.8 (💎 → keys → WAC = the cost basis that stops discount-arbitrage). The
discount lowers the **WAC**, not the booked **gross** — which is exactly *why* a cost basis on the balance is
needed.

The pipe, end to end: **pay-in (rail $) → keys (balance, at WAC) → spend (guesses / buy-ins) → pool (💎) →
winnings (💎) → withdrawal (rail $, cm.8)**. cm.6/cm.7 fix the left end (gross booked at entry); cm.8 is the
right end (💎 → cash). The WAC binds the middle.

## The GIVENs — Operator-ruled, carried by BOTH, NOT re-litigated

- **G1 — the Operator's Fork (RULED): track the average cost per key on the *player balance account*.** The
  platform maintains a **weighted-average cost basis per key, per player**, updated on every key acquisition and
  carried as the balance is spent/converted. This is chosen *over* not tracking a cost basis at all, and *over*
  tracking it off-player (e.g. only in a global ledger). The architects design the WAC system **around** this
  ruling — they do not re-debate whether to track it; they surface the **mechanics** forks (F1–F5).
- **G2 — `revenue_ledger` is byte-frozen (cm.6 `D-1`).** The founded house-account ledger (`RVL`-branded; signed
  `:bigint` `delta`, no CHECK; multi-source/multi-currency; `Wallet.house_post/5` / `house_balance/0..1` /
  `revenue_breakdown/1`) is **additive-only**. The revenue model builds **on** it; it does not reshape it.
- **G3 — cm.7 KeyShop is the pay-in surface (specced, forward).** The "three rows, one event" model (`OTX`
  receipt + `TXN` keys-mint + `RVL` gross booking, gated on `OTX (rail, external_id)` exactly-once) and the
  **gross-booked-at-pay-in** convention (`account="platform", reason="purchase", currency=`the rail) are the
  inputs the WAC consumes. The revenue model must **reconcile with** cm.7 — the central question is whether
  gross-at-pay-in stays the revenue figure or is reframed as a deposit/deferred-revenue event that the WAC
  amortizes (F1).
- **G4 — cm.8 = withdrawals (forward).** Diamonds → TON/USDT/RUB at floating rates, with the house **debit**
  (negative `delta`), rate-pinning, KYC/hold. The cost basis (G1) must **serve** cm.8: the WAC is the input to a
  safe withdrawal rate and the margin computation. Design *for* this seam; build none of it here.
- **G5 — the broadened scope: an Analytics Engine for revenue flow.** A read model / projection over the ledgers
  that reports the money flow — gross pay-in, realized vs deferred revenue, the outstanding-keys liability at
  WAC, blended margin per cohort/rail/package, and the full funnel (pay-in → spend → pool → withdrawal). cm.6's
  `revenue_breakdown/1` is its seed; the Analytics Engine is its full surface (a forward `AEV`/analytics rung).
- **G6 — boundary + brand law.** `echo/apps/codemojex/**` only; sibling apps (echo_mq/echo_store/echo_data/
  echo_wire) are consumed, never edited. Any new entity is a 14-byte branded snowflake
  (`EchoData.BrandedId.generate!/1`, brand = the type); name new brands forward-tense and verify the namespace is
  free against `codemojex.design.md`. Money moves only through `Codemojex.Wallet` inside a `Repo.transaction`.

## The forks — argue EACH in four-part arms (Rationale · 5W · Steelman · Steward)

> Per the architect-approach: rank the arms from your lens, and **pre-empt the strongest objection the opposing
> lens will raise** so the synthesis inherits a rebuttal already on the page. Surface, never decide.

- **F1 — Revenue-recognition timing (THE fork the seed question raises).**
  - *Arm A — Cash-basis (gross at pay-in).* Revenue is the gross booked at purchase, full stop (cm.7 as-built);
    the WAC is a **side ledger** used only for the cm.8 withdrawal cost basis, never for recognition. Simplest;
    revenue = cash in.
  - *Arm B — Accrual (deferred at pay-in → realized at consumption).* Pay-in is a **liability** (unearned); as
    keys are spent (guesses → platform / buy-ins → pool), `keys_spent · WAC` is recognized as **earned**
    revenue; unspent keys are a deferred-revenue liability at WAC. The WAC is **load-bearing for recognition**.
  - *Arm C — Hybrid.* Book gross to `revenue_ledger` at pay-in (the cash view, unchanged), **and** maintain a
    parallel realized/deferred split (a second `account`/`reason` view, or an analytics projection) so finance
    reads **both** cash and accrual without a second store.
- **F2 — The WAC mechanics, *within* the G1 ruling (where on the player balance, and how it re-blends).**
  - *Arm A — one running field* on the player wallet (`key_cost_basis_minor` + `keys` → derive avg), re-blended
    on each buy; O(1), one row.
  - *Arm B — a cost-lots ledger* (`COST`/lot rows per acquisition; FIFO/specific-id possible), exact provenance,
    more rows + a consumption-order rule.
  - *Arm C — derived-on-read projection* from the `transactions`/`orders` history (no stored field; recompute the
    WAC from the ledger). State the trade vs G1's "on the player balance **account**" (does derived-on-read honor
    "on the account"?).
- **F3 — The multi-currency cost basis (keys bought across stars/TON/USDT/RUB at floating rates).**
  - *Arm A — normalize to one canonical unit* (USD cents, or a canonical minor unit) at acquisition time, using
    the **pinned** order rate (cm.7 `D-4`); the WAC is one number. Cross-rail comparable; depends on the rate pin.
  - *Arm B — per-rail cost basis* (a WAC per currency the keys were bought in); exact to the rail, but a single
    key balance then carries N bases and spending must pick one.
  - *Arm C — keys-as-the-unit + a stored acquisition-cost-in-canonical* per movement (the WAC is in canonical
    cents but anchored to the keys count). Reconcile with cm.7's store-native-minor-unit / convert-at-read
    discipline (`D-6` F5).
- **F4 — The Analytics Engine shape (the broadened-scope read model).**
  - *Arm A — Postgres view / materialized projection* over `revenue_ledger` + `transactions` + `orders` (extends
    `revenue_breakdown/1`); SoR-consistent, queryable, refresh cost.
  - *Arm B — an EchoStore projection* (L1-ETS-over-L2-Valkey near-cache, `coherence:` mode) fed by the ledger
    writes; fast reads, a coherence question.
  - *Arm C — a counting/analytics edge* (the bitmapist substrate referenced in [`../auth-flow/README.md`](../auth-flow/README.md)
    G8 — `infra/codemojex-bitmapist`, `:6400` — **verify on disk before citing**); cohort/funnel-shaped, a second
    system to operate. Name the `AEV` analytics brand forward-tense.
- **F5 — The conservation invariant (what must balance, and the WAC's role).** State the money-conservation
  identity the model must hold and make it a **property-test target** (the cm.6 lesson — a money invariant needs a
  grid/property test, not fixed examples). Candidate: `Σ gross_pay_in == Σ realized_revenue + deferred_liability(=
  outstanding_keys · WAC) + Σ withdrawn_at_cost + rounding_dust`. Pin the dust rule (the cm.5 `add_dust`
  precedent). Reconcile with cm.6's keys-unit three-term conservation (it must not break it).

## Ground truth — re-probe on disk (cite methods, not memory)

| Surface | As-built anchor (re-verify) | Role in the revenue model |
|---|---|---|
| `revenue_ledger` (cm.6) | `schemas/revenue_ledger.ex`; `Wallet.house_post/5` (`wallet.ex:~482`), `house_balance/0..1` (`~325`, `WHERE account="platform"`), `revenue_breakdown/1` (`~351`), `@house "platform"` (`~22`) | the house income/expense ledger; **byte-frozen**; the analytics seed |
| `transactions` (`TXN`) | the player currency ledger; `Wallet.credit/5` (`wallet.ex:~383`), the `buy_in` partial unique index `transactions_*_once_index` (golden_rooms migration) | the player-side movements the WAC is computed from |
| `players` wallet | keys / clips / diamonds / bonus_diamonds buckets; the non-negative CHECK | where the G1 WAC field would live (F2 Arm A) |
| `Economy` (pure) | `economy.ex`: `@diamonds_per_key 10` (`:10`), `@cents_per_diamond 1.2` (`:11`); `keys_from_diamonds`/`diamonds_for_keys`/`to_cents`/`to_usd`; `entry_fee_split[_keys]/5` | the in-game conversions (10💎 = 1 key = 12¢) the cost basis threads through |
| cm.7 KeyShop | [`../../specs/cm.7.md`](../../specs/cm.7.md) + [`cm.7.postgres.design.md`](../../specs/cm.7.postgres.design.md): `PKG`/`ORD`/`OTX`, `KeyShop.price_minor/3`, `settle_payment/1`, `Codemojex.Rails` frozen minor-units, the `D-4` rate-pin | the pay-in event the WAC consumes; the unit_price source |
| The package ladder | [`../../specs/economy/economy.packages.md`](../../specs/economy/economy.packages.md): 5=99⭐ … 1000=9999⭐ (0..50 %); ~$0.013/⭐; ~32 % mobile / ~3 % desktop store fee; 200⭐ = 1 TON | the discount → cost-per-key spread (the seed) |
| The economy decision history | [`../../specs/economy/economy.md`](../../specs/economy/economy.md) (the §8 launch model; the Golden buy-in / pool) | how keys/💎 already move through the game |

**Reading list (both):** this brief · `cm.6.md` (the ledger contract) · `cm.7.md` + `cm.7.postgres.design.md`
(the pay-in surface) · `economy.md` + `economy.packages.md` · `wallet.ex` + `economy.ex` (the as-built money
code) · `codemojex.roadmap.md` (where `AEV` analytics + the `BNK` bank + cm.8 sit) · `kb/auth-flow/` (the kb
debate pattern + the bitmapist reference).

## Deliverable (each architect)

Write **one lens doc** to this directory:
- **Venus-Revenue-Ledger →** `revenue.design.ledger-lens.md` — the **accounting / ledger / cost-basis** lens:
  recognition timing, the WAC mechanics + the conservation invariant, the relational/ledger integration with the
  frozen `revenue_ledger` + `transactions`, the property-test target, the cm.8 withdrawal-cost seam.
- **Venus-Revenue-Shop →** `revenue.design.shop-lens.md` — the **pricing / pay-in / product / analytics** lens:
  the package → cost-per-key feed into the WAC, the multi-rail rate handling, what the purchase event emits, the
  **Analytics Engine** product surface (the revenue-flow funnel + operator reads), the withdrawal-rate product
  bind.

Each doc: argue **all five forks** in four-part arms from the lens, **rank** the arms, **pre-empt** the opposing
lens's strongest objection, end with a **one-paragraph recommendation** (advice, never a decision). Ground every
surface or mark it forward-tense. The Director writes `revenue.synthesis.md` + finalizes `README.md` after both
land; the Operator rules; then the specs (cm.7 reconcile + the forward analytics/cm.8 rungs) are written.
