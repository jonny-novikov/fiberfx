# Revenue Model — the shop lens (pricing · pay-in · product · analytics)

> The **shop-lens** half of the blind dual-architect debate (Venus-Revenue-Ledger ∥ Venus-Revenue-Shop), authored
> from the locked-constraints brief [`revenue.brief.md`](./revenue.brief.md). Method of record:
> [`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) (four-part arms; the
> multi-architect debate). This lens argues all five forks (F1–F5) from the **pricing / pay-in / product /
> analytics** view: the package → cost-per-key feed into the WAC, the multi-rail rate handling, what the purchase
> event emits, the **Analytics Engine** product surface, and the withdrawal-rate product bind. It **surfaces**
> forks and ranks the arms; it does **not** decide them — the Director synthesizes, the Operator rules.
>
> **NO-INVENT.** Every named surface grounds at a real `echo/apps/codemojex` `file:line`, or is marked
> **(forward)** for surface not yet built. The bitmapist counting edge (`infra/codemojex-bitmapist/`, `:6400`) was
> **probed on disk and is ABSENT** — it lives only in the auth-flow design-ahead KB (`kb/auth-flow/README.md` G8;
> `auth.design.A-consumer-lens.md:57,81,425,628`), itself uncommitted, naming the marker/dashboard wiring "roadmap
> P1–P3 (unbuilt)". So this lens cites bitmapist strictly **(forward / PROPOSED)**, never as-built.
>
> **Framing law** (propagates to every prompt derived from this doc): third person for any agent reference; no
> first-person-agent narration; no perceptual / interior-state verbs (sees / notices / feels).
>
> **Blind-pass discipline:** authored without reading `revenue.design.ledger-lens.md`. Each fork pre-empts the
> strongest objection the **ledger / accounting lens** is expected to raise, so the synthesis inherits a rebuttal
> already on the page.

---

## 0. The lens in one paragraph

The shop lens reads the revenue model as a **product surface and a money pipe**, not a ledger schema. Its three
load-bearing questions: (1) **What must the operator read** — gross cash-in vs earned revenue, the deferred
liability, blended margin and effective discount per package/rail/cohort, the full funnel — and where does each
read sit given its consistency need? (2) **What does the pay-in event emit** — the purchase (`settle_payment/1`,
[`cm.7.postgres.design.md`](../../specs/cm.7.postgres.design.md) §5) already holds `order.keys` and the pinned
`order.price_minor` + rate, so the unit-price and its canonicalization are computable at the mint, for free. (3)
**What makes the discount ladder safe** — the cost-per-key spread the ladder creates (the seed) is exactly what a
weighted-average cost basis (the WAC) measures, and the WAC is the arbitrage-proof floor that lets aggressive
discounting coexist with cm.8 withdrawals. The through-line of every ranking below: **the WAC is a NEW, SEPARATE,
canonical cost-basis figure that sits BESIDE the frozen native-unit `revenue_ledger`** — exactly as cm.7's
`KeyShop` sits beside `Economy` — never inside it.

---

## 1. The seed, re-read from the shop lens (the package ladder IS the cost-per-key spread)

The Operator's seed question — *how is revenue calculated when the cost per key differs across packages?* — is, from
the shop lens, a statement about the **package ladder** ([`economy.packages.md`](../../specs/economy/economy.packages.md)):

| Package | Stars ⭐ | ⭐ / key | Gross / key @ $0.013 | Display discount |
|---|---|---|---|---|
| 5 keys | 99 | **19.80** | ~$0.257 | 0% |
| 50 keys | 799 | 15.98 | ~$0.208 | 20% |
| 200 keys | 2,599 | 12.99 | ~$0.169 | 35% |
| 1000 keys | 9,999 | **10.00** | ~$0.130 | 50% |

A key bought in the 1000-pack costs **half** what the same key costs in the 5-pack. The keys are **fungible** — the
wallet is a single `players.keys` count, not lots ([`cm.7.postgres.design.md`](../../specs/cm.7.postgres.design.md)
A-7), the game spends them undifferentiated. So a player's balance is a **blend**, and the only honest "cost per
key" is the **weighted average** the Operator ruled in (G1). The economic weight of the spread: the in-game key
**value** is fixed at **12¢** (`@diamonds_per_key 10` × `@cents_per_diamond 1.2`, `economy.ex:10-11`,
`to_cents/1` `economy.ex:22`) — so the deep-discount key is bought roughly **at value** (~13¢), the shallow key at
**~2× value** (~26¢). That spread is not cosmetic: it is the difference between a discount that subsidizes play and
a discount that, paired with a face-rate withdrawal, becomes a **2× money pump** (§6, §7).

**What the seed does NOT ask** (G2/G3, carried, not re-litigated): the *booked gross* is settled — cm.7 books the
gross rail amount at pay-in (`INV-GROSS-BOOKED`), the discount is already inside that gross, there is nothing to
normalize on the revenue side. The WAC is the figure for the **middle** of the pipe —
`pay-in (rail $) → keys (at WAC) → spend → pool (💎) → winnings (💎) → withdrawal (rail $)` — the number the gross
cannot supply.

---

## 2. F1 — Revenue-recognition timing (cash-basis vs accrual vs hybrid)

**The fork.** Does the gross-at-pay-in stay *the* revenue figure (cash), or is it reframed as a deposit the WAC
amortizes into earned revenue as keys are consumed (accrual)?

### Arm A — Cash-basis (gross at pay-in; the WAC is a side ledger for cm.8 only)
- **Rationale.** Revenue = cash in. The `revenue_ledger` purchase row IS recognized revenue, full stop. This is the
  cm.7 as-built (`INV-GROSS-BOOKED`, `INV-VISIBLE-REVENUE`); the WAC exists only to price a cm.8 withdrawal.
- **5W.** The operator reads gross pay-in per rail off `house_balance/0..1` (`wallet.ex:325`) with **zero new read**;
  recognition happens once, at `settle_payment`; nothing amortizes.
- **Steelman.** Maximal simplicity and zero new surface for recognition. For a prepaid-virtual-currency product
  where keys are *usually* spent fast, cash ≈ accrual, so the deferral is a rounding concern. It is also the
  liquidity-true number: cash-in is what funds the 21-day-hold withdrawal obligation (`economy.packages.md`).
- **Steward.** Already shipped; respects the frozen ledger (G2) trivially. But it leaves the operator **blind to
  the deferred liability** — the very figure the seed's WAC enables (`outstanding_keys · WAC`) — and reports
  revenue for keys not yet consumed, which overstates *earned* revenue at any instant.

### Arm B — Accrual (deferred at pay-in → realized at consumption; the WAC is load-bearing for recognition)
- **Rationale.** Pay-in is an unearned **liability**; as keys are spent (guesses → platform, buy-ins → pool),
  `keys_spent · WAC` becomes earned revenue; unspent keys are a deferred-revenue liability at WAC. This is the
  GAAP-shaped model for a virtual-currency product.
- **5W.** Recognition moves from the pay-in event to the **spend** events (`charge_guess` `wallet.ex:111`, `buy_in`
  `wallet.ex:208`); the `revenue_ledger` purchase row would have to mean "deposit," not "revenue."
- **Steelman.** The accounting-correct view: a player who buys 1000 keys and plays none has given the platform
  **cash but not revenue** — a deferred liability, not earned income. Accrual is what an auditor and a serious
  finance function expect.
- **Steward.** **Fights the frozen ledger.** The cm.7 RVL purchase row already *means* "gross revenue recognized"
  (`reason="purchase"`, seen by `house_balance`); reframing it as a deposit is a semantic reshape of a byte-frozen
  surface (G2 forbids). It also muddies the cash/liquidity view the withdrawal-timing needs. A bigger, riskier
  build for a number that — crucially — can be **presented on read** without changing the store.

### Arm C — Hybrid (book gross to the cash ledger AND present realized/deferred as a read-time projection)
- **Rationale.** Keep the frozen `revenue_ledger` as the **cash / bookings** ledger (unchanged, what cm.7 ships) and
  derive the **realized/deferred split** as an **analytics projection** priced at WAC — no second store, no
  unfreeze. Finance reads BOTH the cash view and the accrual view from one set of facts.
- **5W.** Gross books at pay-in (as today); a forward analytics read computes `realized = Σ keys_spent · WAC` and
  `deferred = Σ outstanding_keys · WAC` over the `transactions` spend movements + the per-player WAC; the operator
  reads bookings (cash) and revenue (earned) side by side.
- **Steelman.** Recognition timing is a **reporting** choice, and a projection can present accrual over a cash-basis
  store. The games industry runs exactly this dual (**bookings** = gross cash in; **revenue** = recognized over
  consumption) and the broadened scope G5 asks for both. It is the only arm that gives the product surface every
  number while leaving cm.6/cm.7 byte-frozen.
- **Steward.** Lowest blast radius for the most reads. The cash ledger stays the at-rest truth (frozen); the accrual
  split is a derived read (the Analytics Engine, F4). The only cost is defining the projection — which F4 builds
  regardless.

**Ranking (shop lens): C ▸ A ▸ B.** Hybrid gives the product surface the cash view (liquidity, the withdrawal
obligation), the earned view (true revenue), and the deferred liability (the seed's WAC made visible) **without a
second store and without touching the frozen ledger**. Cash-basis (A) is the as-built and the simplest, but blinds
the operator to the deferred liability. Accrual (B) is the "correct" recognition but fights the frozen ledger and
over-reshapes for a number a projection supplies.

**Pre-empt the ledger lens.** The accounting lens is expected to argue **B (accrual)** as GAAP-correct and to call
gross-at-pay-in an overstatement (revenue booked for unconsumed keys = textbook deferred-revenue). **Rebuttal:** the
shop lens does not choose — **Hybrid presents accrual over the cash-basis store.** The frozen RVL stays the bookings
ledger (cash in, the liquidity view the 21-day hold needs); the realized/deferred split is a **read-time projection**
priced at WAC (`deferred_liability = outstanding_keys · WAC`), so finance reads the accrual numbers **without** a
second store and **without** unfreezing cm.6/cm.7 (G2). Recognition timing is a reporting lens, not a storage
decision — and the projection is exactly the Analytics Engine (F4) the broadened scope already mandates.

---

## 3. F2 — The WAC mechanics within G1 (where on the balance, and how it re-blends)

**The fork.** G1 ruled *track the WAC per key, per player, on the balance account*. Where does it live and how does
it re-blend?

### Arm A — One running cost-basis field on the player account (re-blended on each buy)
- **Rationale.** A single derived figure per player — `key_cost_basis` (canonical, §4) alongside `players.keys`,
  giving `avg = basis / keys` — re-blended at the one pay-in event: `new_basis = old_basis + bought_keys ·
  unit_cost`; `on spend: basis -= keys_spent · avg` (avg unchanged). O(1), one column, mirrors the wallet's
  "balance is a column" shape.
- **5W.** The field lives on `players` (the brief's F2-A home; the wallet under the non-negative CHECK,
  [`cm.7.postgres.design.md`](../../specs/cm.7.postgres.design.md) A-7); it updates **inside** `settle_payment/1`'s
  transaction (where `order.keys` and `order.price_minor` are already in hand, §5); it is operator-internal — the
  player never reads a cost basis.
- **Steelman.** WAC is **by definition** an aggregate — the weighted *average*. The running field is the exact
  minimal shape: it captures the path-dependent running average incrementally, at the one event the shop already
  owns, with no consumption-order rule. It honors G1's "on the balance **account**" literally.
- **Steward.** The drift risk (a stored aggregate that could diverge from history) is closed by a **reconciliation
  property test** — the running field must equal the fold over the `orders` history (the cm.6 conservation-property
  precedent, `cm.6.md` §Acceptance). The audit trail already lives in `orders` (every buy is an `ORD`/`OTX` with its
  price pinned), so the running field adds a fast read, not a new source of truth.

### Arm B — A cost-lots ledger (a `COST`/lot row per acquisition; FIFO or specific-id)
- **Rationale.** Exact provenance: each acquisition is a lot; a spend consumes lots by a rule (FIFO / specific-id),
  giving lot-level cost trails.
- **5W.** A new branded lot table (forward), a row per purchase, a consumption-order rule applied at every spend
  (`charge_guess`/`buy_in`).
- **Steelman.** Auditor-grade provenance and the substrate for tax-lot optimization; the maximal-fidelity cost
  model.
- **Steward.** The fungible-keys model has **no natural consumption order** — keys are one count, not lots — so FIFO
  is an *imposed* fiction that buys provenance the shop does not need (blended margin never matches a spent key to a
  specific purchase). It duplicates what `orders` already records and taxes every spend path with a lot walk. Wrong
  weight for launch.

### Arm C — Derived-on-read projection (no stored field; recompute the WAC from history)
- **Rationale.** No new column; recompute the WAC from the `transactions`/`orders` history on demand.
- **5W.** Each WAC read folds the player's ordered acquisition + spend movements (buys re-blend; spends deduct at the
  running avg) to the current basis.
- **Steelman.** Zero schema change; the history is already on disk; nothing to keep in sync.
- **Steward.** A current-balance WAC is **path-dependent** — it must replay the full ordered trajectory (a buy, then
  a spend at the then-current avg, then a buy) to get the basis of the keys *currently held*, not the naive all-time
  average. That is O(n)-per-read on a figure the hot paths (the operator dashboard, the cm.8 withdrawal pricing)
  need cheaply, and it arguably violates G1's "on the **account**" (the figure is never on the account).

**Ranking (shop lens): A ▸ B ▸ C.** The one running field honors G1, costs O(1) at the event the shop owns, gives
exactly the blended figure margin / liability / the withdrawal floor need, and is drift-proofed by a reconciliation
property test against `orders`. Lots (B) buy provenance the fungible model does not need. Derived-on-read (C) pays an
O(n) read and a subtle path-dependence, and reads as *not* "on the account."

**Pre-empt the ledger lens.** The accounting lens is expected to favor **B (cost-lots)** for exact, reconstructible
provenance and to call a running field "a derived aggregate with no audit trail / a drift surface." **Rebuttal:** the
provenance the ledger lens wants **already exists** in `orders` + `order_transactions` (every acquisition is an
`ORD`/`OTX` row with its `price_minor` and pinned rate, append-only — `cm.7.postgres.design.md` §2.2/§2.3). The
running field is a **fast read over that audit trail**, not a replacement for it; a **reconciliation property test**
(running field ≡ fold-over-`orders`, the cm.6 precedent) makes drift a CI failure, not a silent error. A separate
`COST`-lots table *duplicates* the order history and forces a consumption-order rule the fungible-keys wallet does
not otherwise carry. Arm A + the existing `orders` history delivers the ledger lens's auditability **and** the
shop's O(1) simplicity.

---

## 4. F3 — The multi-currency cost basis (stars / TON / USDT / RUB at floating rates)

**The fork.** Keys are bought across four rails at floating rates. In what unit is the cost basis carried so a
single fungible key has a single, comparable cost?

### Arm A — Normalize to one canonical unit (USD cents) at acquisition, via the pinned order rate
- **Rationale.** A single WAC requires a single unit; canonicalize each acquisition's cost to **USD cents** at
  acquisition time using the **pinned** order rate (cm.7 `D-4` — `rate_minor`/`rate_pair`/`rate_source`/
  `rate_quoted_at` on the order, `cm.7.postgres.design.md` §2.3). The WAC is one cross-rail-comparable number.
- **5W.** At `settle_payment`, `unit_cost_cents = canonicalize(order.price_minor, order.<pinned rate>)`; USD cents is
  the operator's native unit and `economy.ex`'s existing read unit (`to_cents`/`to_usd`, `economy.ex:22,25`).
- **Steelman.** The canonicalization is **free and audit-safe**: cm.7 `D-4` already pins the rate on the order
  precisely so a booked figure is reproducible regardless of later rate moves — so the canonical cost is re-derivable
  from the order's own pinned rate, never a live re-read. USD cents is the comparability anchor margin and the
  withdrawal floor both need.
- **Steward.** The apparent clash with cm.7 `D-6` F5 ("store native minor unit, convert at read; never normalize at
  write") **dissolves** (see Arm C): the revenue gross stays native (frozen, audit = what arrived); the WAC is a
  *separate* figure whose purpose is comparability, so it is canonical by necessity.

### Arm B — Per-rail cost basis (a WAC per currency the keys were bought in)
- **Rationale.** Exact to the rail; no rate baked into the basis.
- **5W.** A single key balance carries N cost bases; a spend must pick which rail's basis flows out.
- **Steelman.** No canonicalization, no rate dependence in the stored basis; each rail's cost is exact in its own
  unit.
- **Steward.** Unworkable for a fungible balance: four bases on one key count, and spending forces a rail-selection
  rule on fungible keys — and the product still needs ONE comparable number for blended margin and the withdrawal
  floor, so the canonicalization is merely **deferred to read-time** while a spend-time selection rule is **added**.
  Strictly worse than doing it once, at acquisition.

### Arm C — Keys-as-the-unit + the acquisition cost stored in canonical cents per movement
- **Rationale.** The precise reconcile of Arm A with cm.7 `D-6` F5: the WAC is **per key** (the fungible unit) and
  the **cost** is carried in **canonical USD cents** per acquisition movement — `key_cost_basis_cents` anchored to
  the keys count.
- **5W.** Same canonicalization as Arm A (at the pinned rate, at acquisition), stated as the field shape F2 Arm A
  stores: `players.key_cost_basis_cents` + `players.keys` → `avg_cents/key`.
- **Steelman.** Honors keys-as-fungible-unit AND canonical-cents-for-comparability AND store-exact-convert-at-read —
  because it leaves the `revenue_ledger` native (untouched) and adds the canonical cost basis as the *separate*
  figure. It is Arm A's principle in the exact field shape F2 ranks first.
- **Steward.** The one nuance the build must pin (a precision flag): the field is in **canonical cents**, distinct
  from the rail-native minor units cm.7 stores — naming it `*_minor` (the brief's shorthand) would conflate it with
  the rail minor unit; it is `*_cents`.

**Ranking (shop lens): C ≈ A ▸ B.** Arm A is the principle (canonicalize to USD cents at the pinned rate); Arm C is
its precise, reconciled form (keys-unit + canonical-cents cost, the `revenue_ledger` left native). They are one
answer. Per-rail bases (B) are rejected: four cost bases on a fungible key, a spend-time rail-selection rule, and the
canonicalization unavoidable at read anyway.

**Pre-empt the ledger lens.** The accounting lens is expected to defend cm.7's store-native / convert-at-read
discipline (`D-6` F5, `cm.6` `D-2`) and to charge that canonicalizing the cost basis to USD "bakes a rate" and
"destroys the audit." **Rebuttal:** the WAC **is not the `revenue_ledger`.** The revenue gross stays byte-frozen and
native (G2) — that audit (what arrived) is untouched. The WAC is a *separate* cost-basis figure whose entire purpose
is cross-rail comparability, which is **impossible** without a common unit. The rate it canonicalizes at is the
**pinned, audited order rate** (`D-4`) — so the canonical cost basis is itself re-derivable from the order, never a
live re-read. Two figures, two units, two purposes, both audit-safe: revenue native (what arrived), cost basis
canonical-at-pinned-rate (re-derivable). This is the **same read-time-roll-up principle** cm.7 §8.1 already blesses
for the single-number USD revenue view (`SUM bucket × rate`) — applied to the cost side.

---

## 5. F4 — The Analytics Engine (THE product surface — the broadened-scope read model)

This is the heart of the shop lens. The brief broadens scope (G5) to an **Analytics Engine for revenue flow**. The
shop-lens design: the operator's reads have **different consistency needs**, so the Engine is **layered** — each
read sits where its need dictates (the CAP-segmentation discipline of the whole BCS stack, `mesh.8.1`, applied to
the analytics surface). The three candidate substrates are not one-of-three; they are the **three tiers** of one
layered Engine.

### 5.1 The operator reads (the product spec — what the dashboard reports)

| # | Read | Source | Consistency need |
|---|---|---|---|
| R1 | **Gross pay-in** per rail (+ the read-time USD roll-up) | `house_balance/0..1` (`wallet.ex:325`), `WHERE reason="purchase" GROUP BY currency` | SoR-exact |
| R2 | **Realized vs deferred revenue** | `Σ keys_spent · WAC` (realized) / `Σ outstanding_keys · WAC` (deferred), over `transactions` spend rows + the WAC | SoR-exact (penny) |
| R3 | **Outstanding-keys liability at WAC** | `Σ players.keys · WAC` — the balance-sheet figure (F1's deferred liability) | SoR-exact (penny) |
| R4 | **Blended margin + effective discount** per package / rail / cohort | revenue − cost(WAC) − store-fee (read-time, `economy.packages.md`) | SoR-exact |
| R5 | **ARPU / LTV** | revenue ÷ cohort size; lifetime-value curves | countable, rebuildable |
| R6 | **The full funnel** — pay-in → keys → spend → pool → withdrawal — volumes + conversion | the AEV event stream (forward) over all systems | countable, rebuildable |

R1–R4 are **money** reads: they must reconcile to the penny (F5), so they are SoR-exact aggregates over the frozen
`revenue_ledger` + `transactions` + `orders`. R5–R6 are **cohort/funnel-shape** reads: set membership + counting
over time, rebuildable by replay (the AEV "never authoritative, rebuildable" property,
[`codemojex.roadmap.md`](../../codemojex.roadmap.md) §Analytics).

### 5.2 The arms (the three tiers)

#### Arm A — A Postgres view / materialized projection (over `revenue_ledger` + `transactions` + `orders`)
- **Rationale.** Extends `revenue_breakdown/1` (`wallet.ex:351`) into a `revenue_flow` projection; the money reads
  R1–R4 are SoR-consistent SQL aggregates.
- **5W.** A forward `Codemojex.Analytics` module over a Postgres projection; the operator reads the money funnel from
  the system of record; refresh cost on a materialized view, or live aggregates at launch volume.
- **Steelman.** The money funnel **must** be penny-exact (R2–R4, F5) — finance reconciles to the cent, and an
  eventually-consistent margin number is a wrong number. Postgres is where the frozen ledgers already live; this
  reuses the cm.6 read shape with the cm.7 multi-currency seam realized.
- **Steward.** Lowest new surface for the highest-trust reads; the **launch floor** of the Engine. The WAC reads
  (R2–R4) need only the per-player WAC (F2-A) joined to the spend movements.

#### Arm B — An EchoStore projection (L1-ETS-over-L2-Valkey near-cache, `coherence:` mode), fed by ledger writes
- **Rationale.** Fast reads for a hot dashboard; the store pushes invalidation.
- **5W.** A forward EchoStore table over the Postgres projection; coherence via the store's invalidation push
  (`:tracking`/`:broadcast`).
- **Steelman.** If the dashboard reads get hot, a near-cache serves them at ETS speed; the BCS stack already runs
  this pattern.
- **Steward.** A **serving optimization, not the SoR**, and a money figure on an eventually-consistent cache raises a
  coherence question (a stale margin is a wrong margin). It earns its place only **after** the dashboard demonstrably
  gets hot — a later tier, not a launch one.

#### Arm C — A counting / analytics edge (the bitmapist substrate — FORWARD, not on disk)
- **Rationale.** The cohort / funnel reads R5–R6 are set-membership + counting (registered / active / played / paid;
  retention rows; funnel conversion) — the exact bitmapist domain (roaring bitmaps; `AndCount`/`OrCount`;
  `RetentionRow`), and rebuildable by replay (the AEV property).
- **5W.** The forward **`AEV`** (analytics event) brand — append-only, one-way, emitted by every system, never
  authoritative ([`codemojex.roadmap.md`](../../codemojex.roadmap.md) §branded-namespaces L66, §Analytics L282–286)
  — feeds the bitmapist counting edge (auth-flow KB G8; `:6400`; Go redigo client; **PROBED ABSENT on disk** — cite
  forward only). Off the money hot path; fire-and-forget.
- **Steelman.** ARPU/LTV/retention and the count-funnel are **not** SQL-aggregate-shaped — they are cohort-bitmap
  shaped, and forcing them onto the money projection (Arm A) bloats it with a workload Postgres serves poorly.
  Rebuildable-by-replay makes the counting edge safe to lose and reconstruct.
- **Steward.** A **second system to operate** and entirely forward (the brand, the edge, the marker wiring are all
  unbuilt). Named so the forward rungs have a target; **not** the launch floor.

**Ranking (shop lens, for the launch floor): A ▸ C ▸ B.** The money funnel (R1–R4) is the floor and **must** be a
SoR-exact Postgres projection (Arm A, extending `revenue_breakdown/1`). The cohort/LTV funnel (R5–R6) is Arm C — the
forward `AEV` stream + the bitmapist edge — named forward-tense (PROPOSED, off the money path, rebuildable). The
EchoStore cache (Arm B) is a later serving tier, added only if the dashboard gets hot. The Engine is **layered**, not
one substrate: **money = penny-exact Postgres; cohorts = countable, rebuildable bitmapist; serving = fast cache** —
each read where its consistency need lands it. The product home is the forward **LiveAdmin Analytics dashboard**
([`codemojex.roadmap.md`](../../codemojex.roadmap.md) §LiveAdmin L296–302).

**Pre-empt the ledger lens.** The accounting lens is expected to call the Engine over-scoped — "the money reads are
SQL aggregates over the frozen ledger + `transactions`; extend `revenue_breakdown/1` and stop; there is no 'engine'."
**Rebuttal:** agreed **for the floor** — the money funnel IS Arm A (Postgres aggregates extending
`revenue_breakdown/1`), which is exactly what this lens ranks first and the only tier built first. The "Engine"
framing is the **product surface** the broadened scope G5 mandates: the operator dashboard, the cohort/LTV reads, and
the AEV funnel — which the money queries alone do not supply (ARPU/retention/funnel-conversion are not SQL-aggregate
shaped). The disagreement is only **scope and naming**: both lenses build the money reads as SoR Postgres aggregates;
the shop lens *additionally names* the forward cohort (Arm C) and serving (Arm B) tiers so the forward analytics
rungs (`AEV`, LiveAdmin) have a target. Naming a forward tier is not building it.

---

## 6. F5 — The conservation invariant (what must balance, and the WAC's role)

**The fork (the framing choice).** What money-conservation identity must the model hold, in what unit, at what scope
— and how is it a property-test target (the cm.6 lesson: a money invariant needs a grid/property test, not fixed
examples)?

### Statement 1 (recommended) — the canonical-USD cost-basis conservation (read-time)
- **Rationale.** Every cent a player paid for keys is, at any instant, either **still held** (deferred liability),
  **consumed** (realized revenue), or **withdrawn at cost** (cm.8) — to the penny, modulo integer dust:
  `Σ gross_pay_in_usd == deferred(Σ outstanding_keys · WAC) + realized(Σ keys_consumed · WAC) + Σ withdrawn_at_cost
  + rounding_dust`. The cost basis is **conserved** as it flows through the pipe.
- **5W.** Computed at the **pinned** rates (`D-4`), at **read time** (a property test, not a stored total); per-player
  and in aggregate; the unit is canonical USD cents (the WAC unit, §4).
- **Steelman.** It is the product identity behind every dashboard number (R2–R4) AND the cm.8 solvency floor (§7):
  `Σ gross_pay_in_usd` equals `Σ acquisition_cost_basis` because a key's cost basis IS what was paid for it — so the
  liability the platform can owe in withdrawable basis is **bounded by the gross received**. It is the broadened
  scope's "the funnel reconciles" made provable.
- **Steward.** A **read-time** property test over random buy/spend/withdraw sequences across rails at random pinned
  rates (the cm.6 conservation-property precedent); the dust pinned to **one named bucket** (the cm.5 `add_dust`
  rule, `economy.ex:113-115`) so integer-division residue closes the identity exactly. It runs **alongside**, never
  replacing, cm.6's keys-unit conservation.

### Statement 2 (the ledger lens's likely frame) — keep cm.6's keys-unit three-term conservation as THE identity
- **Rationale.** `Σ player_key_debits == Σ house_key_credits + Σ pool_key_portions` (cm.6 `D-3`), in keys, over three
  observable columns; the WAC conservation is a separate concern.
- **Steelman.** It is the proven, at-rest, store-native invariant; it bakes no rate; it is already shipped and tested.
- **Steward.** **Correct but incomplete** for the revenue model: it is the Golden-Room keys-flow conservation (the
  pool), not the pay-in cost-basis conservation. It says nothing about deferred liability, realized revenue, or the
  withdrawal floor — the figures the broadened scope and cm.8 require. It must be **preserved untouched**, but it is
  not the revenue-model identity.

### Statement 3 (rejected) — `Σ all-ledger-rows = 0`
- **Rationale / Steward.** The naive single-table zero-sum — **explicitly rejected** by both cm.6 (`D-3`) and cm.7
  (the conservation-honesty statement, `cm.7.postgres.design.md` §6): a purchase is a **cross-boundary** double-entry
  (external rail gross IN → keys minted + revenue booked), keys are *created*, the rail value received *externally*.
  A row-sum does not balance and must not be read as the system total.

**Ranking (shop lens): Statement 1 ▸ Statement 2 (preserve, do not replace) ▸ Statement 3 (the named trap).** The
canonical-USD cost-basis conservation is the identity the broadened scope (G5) and the cm.8 safety bind (§7) require;
it runs alongside cm.6's keys conservation, never instead of it; Statement 3 is the trap both prior rungs already
named.

**Pre-empt the ledger lens.** The accounting lens is expected to insist the identity be stated in a **single
store-native unit** (the cm.7 `D-6` F5 / cm.6 `D-2` "store exact, convert at read" discipline) and to resist a
canonical-USD identity as "baking rates into the conservation." **Rebuttal:** the conservation is a **read-time
property test**, not a stored total, computed at the **pinned** rates (`D-4`) — so it is reproducible and audit-safe,
exactly like the read-time USD roll-up cm.7 §8.1 already blesses. The keys-unit conservation (cm.6) stays the
**at-rest** invariant (untouched, Statement 2 preserved); the canonical-USD WAC conservation is the **read-time**
revenue-model invariant (the broadened scope). Both hold; neither bakes a stored total; the dust rule (cm.5
`add_dust`) closes the integer residue in one named bucket so the read-time identity is exact.

---

## 7. The cm.8 withdrawal-rate product bind (the WAC as the arbitrage-proof floor)

The brief's explicit ask: how does the WAC set a **safe, arbitrage-proof** payout rate for cm.8? This is the
product-critical reason G1 (track the WAC) is the prerequisite for cm.8 (safe withdrawals).

**The arbitrage the WAC stops.** The discount ladder creates a 2× cost-per-key spread (§1). Pair a 50%-off key
(~13¢ cost basis) with a withdrawal priced at the *face* rate (~26¢, the 5-pack rate) and a player can **buy cheap,
withdraw dear** — a 2× money pump that extracts the discount as cash. The discount, meant as a **play subsidy**,
becomes a **cash-extraction arbitrage**.

**The bind, at two levels:**

- **Per-player (anti-arbitrage).** A withdrawal prices a withdrawn key at **its WAC** (the player's canonical cost
  basis), never the face — so a discount-bought key withdraws at its *discounted* basis. The discount stays a play
  subsidy; it can never be cashed out above what was paid. The pipe `💎 → keys (10:1, `convert_to_keys`
  `wallet.ex:156`) → withdrawal` is floored by the WAC: `payout_per_key ≤ WAC`.
- **Aggregate (solvency).** The conservation identity (§6) bounds the platform's total withdrawable obligation by the
  gross received: `deferred + realized + withdrawn_at_cost == Σ gross_pay_in`. The WAC-priced deferred liability is
  bounded by the cash in — so the platform can never owe more in withdrawable basis than it took in for those keys.
  This generalizes the Golden Room keystone (`$1 × 10 = $10` break-even, buy-in-funded, zero platform exposure,
  [`economy.md`](../../specs/economy/economy.md) §8): the payout obligation is floored by the cost basis received.

**The product statement:** *the cm.8 payout rate for a withdrawn key is the WAC (its canonical cost basis) — the
arbitrage-proof floor. A discount-bought key withdraws at its discounted WAC, never the face; and in aggregate the
WAC-priced deferred liability is bounded by the gross pay-in, so the platform's total withdrawal obligation never
exceeds the cost basis received.* This is the shape cm.7 already designs-for (the signed `house_post` debit + the
shared rate-pin, `cm.7.postgres.design.md` §8.2); the WAC is the missing input that makes the payout rate **safe**,
not merely **recorded**.

---

## 8. The package / discount design implications the cost-basis surfaces

The cost-basis tracking is not neutral plumbing — it changes what the shop can safely do:

1. **The WAC unlocks aggressive discounting.** Without a per-key cost basis, a 50%-off package paired with face-rate
   withdrawals is a money pump (§7). *With* the WAC flooring the payout, the discount is a **bounded play subsidy** —
   so the operator can run the full 0–50% ladder safely **because** the cost basis is tracked. The seed's "different
   cost per key" is not a problem to tolerate; it is a lever the WAC makes safe.

2. **Per-rail overrides decouple pricing freedom from margin comparability.** A package may pin
   `ton_price_minor`/`rub_price_minor` to a round number (`cm.7.postgres.design.md` §2.1); the WAC, being canonical
   (§4), keeps the cross-rail margin comparable regardless. The operator sets rail prices independently and still
   reads one blended margin.

3. **The store fee makes "cost basis" two numbers — pin which is the WAC.** Apple/Google take ~32% mobile / ~3%
   desktop *before* the developer payout (`economy.packages.md`), so the platform's *net* take is `gross × (1−fee)`
   while the player *paid* the gross. The shop-lens resolution: the **WAC = the player's GROSS cost basis** (the
   withdrawal floor — a player can never extract more than the gross they paid, the conservative floor); the
   platform's **net take-home is a separate read-time figure** (gross − store fee, the margin view, R4). One gross
   basis, the store fee applied only on the margin read — so the withdrawal floor stays conservative and the margin
   stays honest. This ambiguity is invisible from a pure ledger view and is load-bearing for both the floor and the
   margin number.

---

## 9. Recommendation (advice, never a decision)

From the pricing / pay-in / product / analytics lens: rule **F1 Hybrid (C)** — keep the byte-frozen `revenue_ledger`
as the cash/bookings ledger (gross at pay-in, the withdrawal-liquidity view) and present realized/deferred as a
read-time analytics projection priced at WAC, so finance reads both cash and accrual with no second store and no
unfreeze; **F2 the one running cost-basis field on the player account (A)** — O(1), emitted inside `settle_payment`,
drift-proofed by a reconciliation property test against the `orders` history; **F3 canonicalize the cost basis to USD
cents at acquisition using the pinned order rate (A's principle in C's keys-unit + canonical-cents form)** — the
`revenue_ledger` stays native (cm.7 `D-6` F5 untouched), the WAC is the separate comparable figure, named
`key_cost_basis_cents` (not `_minor`); **F4 a layered Analytics Engine** — the money funnel as a SoR-exact Postgres
projection (A, the launch floor, extending `revenue_breakdown/1`), the cohort/LTV funnel as the forward `AEV`
bitmapist counting edge (C, named forward — PROBED ABSENT on disk, PROPOSED only), an EchoStore cache (B) only if the
dashboard gets hot; **F5 the canonical-USD cost-basis conservation identity as a read-time property-test target**
(`Σ gross_pay_in == deferred + realized + withdrawn_at_cost + dust`), alongside — never replacing — cm.6's keys
conservation, with the dust pinned to one bucket (cm.5 `add_dust`) and the WAC the arbitrage-proof floor under the
cm.8 payout rate. The through-line: **the WAC is a NEW, SEPARATE, canonical cost-basis figure that sits beside the
frozen native-unit `revenue_ledger`** (exactly as cm.7's `KeyShop` sits beside `Economy`) — it makes the discount
ladder safe to pair with withdrawals and the funnel reconcile to the penny, and it touches no frozen surface to do
it.

---

## 10. Ground truth (cited, not from memory)

- **As-built money code.** `Codemojex.Wallet` — `house_post/5` (`wallet.ex:482`), `house_balance/0..1`
  (`wallet.ex:325`, `WHERE account="platform" GROUP BY currency`), `revenue_breakdown/1` (`wallet.ex:351`, `WHERE
  ref GROUP BY reason`), `credit/5` (`wallet.ex:383`, the mint shape), `convert_to_keys/2` (`wallet.ex:156`, 10:1),
  `charge_guess/3` (`wallet.ex:111`), `buy_in/2` (`wallet.ex:208`), `@house "platform"` (`wallet.ex:22`).
  `Codemojex.Economy` — `@diamonds_per_key 10` / `@cents_per_diamond 1.2` (`economy.ex:10-11`), `to_cents`/`to_usd`
  (`economy.ex:22,25`), `add_dust` (`economy.ex:113-115`).
- **The pay-in surface (cm.7).** `settle_payment/1` + the WAC's inputs (`order.keys`, `order.price_minor`, the pinned
  rate) — [`cm.7.postgres.design.md`](../../specs/cm.7.postgres.design.md) §5, §2.3 (`D-4` rate-pin), §2.1 (per-rail
  overrides), §8.1 (the minor-unit convention + read-time roll-up), §8.2 (the cm.8 withdrawal seam), §6 (the
  cross-boundary conservation-honesty statement); the as-built A-7 (the `players` wallet + non-negative CHECK).
  [`cm.7.md`](../../specs/cm.7.md) §2 (the three-rows-one-event model), `INV-GROSS-BOOKED` / `INV-VISIBLE-REVENUE`.
- **The frozen ledger (cm.6, G2).** [`cm.6.md`](../../specs/cm.6.md) `D-1` (signed, no-CHECK, multi-source/currency),
  `D-3` (the keys-unit three-term conservation + the conservation-honesty mandate), §Forward (the multi-currency seam
  + the cm.8 withdrawal-debit seam).
- **The package ladder + the seed.** [`economy.packages.md`](../../specs/economy/economy.packages.md) (5=99⭐ …
  1000=9999⭐, 0–50%; ~$0.013/⭐; ~32% mobile / ~3% desktop store fee; 200⭐ = 1 TON; the 1000-Star minimum + the
  21-day hold). [`economy.md`](../../specs/economy/economy.md) §8 (the launch Golden Room; the `$1×10=$10`
  break-even keystone).
- **Forward placements.** [`codemojex.roadmap.md`](../../codemojex.roadmap.md) — `AEV` (analytics event,
  append-only/one-way, L66; §Analytics L282–286), `BNK` (the bank + the rake, L60/L128/L265), `SHR` (growth),
  §LiveAdmin (L296–302, the analytics/treasury dashboards), the cm.8 cash-out rung (L168). The bitmapist counting
  edge — **(forward, PROBED ABSENT on disk):** [`../auth-flow/README.md`](../auth-flow/README.md) G8;
  [`../auth-flow/auth.design.A-consumer-lens.md`](../auth-flow/auth.design.A-consumer-lens.md):57,81,425,628 (`:6400`,
  Go redigo client, cohorts active/registered/played/paid, marker wiring "roadmap P1–P3 unbuilt").
- **Boundary + brand law (G6).** `echo/apps/codemojex/**` only; new entities are branded snowflakes
  (`EchoData.BrandedId.generate!/1`); money moves only through `Codemojex.Wallet` inside a `Repo.transaction`. The
  forward `key_cost_basis_cents` field on `players` and the `Codemojex.Analytics` module are named forward-tense.
