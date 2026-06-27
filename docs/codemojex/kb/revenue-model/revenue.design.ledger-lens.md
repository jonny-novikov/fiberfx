# Revenue Model — the LEDGER / accounting / cost-basis lens

> **Architect:** Venus-Revenue-Ledger (the **ledger / accounting / cost-basis** lens of the blind dual-architect
> debate). Sibling: Venus-Revenue-Shop (the pricing / pay-in / product / analytics lens). Method:
> [`../../aaw/aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md) (four-part arms). Shared brief:
> [`revenue.brief.md`](./revenue.brief.md) — its GIVENs (G1–G6) are **carried, not re-litigated**.
> **This architect stayed BLIND** — `revenue.design.shop-lens.md` was not read. The Director synthesizes; the
> Operator rules. **NO-INVENT:** every named surface grounds at a real `echo/apps/codemojex` `file:line` or is
> marked **forward-tense**. Framing law: third person for any agent reference; no first-person-agent narration;
> no perceptual / interior-state verbs.
>
> **This is a DESIGN doc that SURFACES forks — it decides none.** Each fork is argued in four-part arms
> (Rationale · 5W · Steelman · Steward), **ranked from this lens**, with the **opposing lens's strongest
> objection pre-empted**. It ends with a one-paragraph recommendation (advice, never a decision).

## §0 — The lens, and the one distinction the whole argument turns on

The ledger lens reads the revenue model as a **set of books that must balance, reconcile, and survive audit**.
Its non-negotiables: (a) the shipped `revenue_ledger` is byte-frozen (G2) and must not be reshaped; (b) every
figure finance reports must **tie out to the system of record** — a fast number that drifts from the books is a
liability, not a feature; (c) money is conserved to the last integer unit, with the rounding dust **named, not
lost** (the cm.6 lesson, F5).

**The distinction the seed question forces — two figures that must never be conflated** (the brief's frame, restated in ledger terms):

| | **Booked pay-in revenue** | **Cost basis per key (the WAC)** |
|---|---|---|
| What it is | the **GROSS rail amount received** | the **weighted-average cost** of a fungible key |
| Unit | the rail's **NATIVE minor unit** (star / nanoTON / micro-USDT / kopeck) | a **single canonical unit** (it must be — see F3) |
| Where it lives | `revenue_ledger` (`account="platform"`, `reason="purchase"`, cm.7 `D-3`) — **frozen** | **forward** — a cost basis on the player balance (G1) |
| The discount's effect | **none** — the discount is *already inside* the 9 999⭐ gross; revenue = what arrived | **lowers it** — the 1000-pack key costs ≈ 10⭐, the 5-pack key ≈ 19.8⭐ |
| The audit rule | store EXACT, never normalize at write (cm.7 `D-6` F5) | normalize ONCE at acquisition from the **pinned** rate (cm.7 `D-4`) |

The revenue_ledger answers *"what arrived?"* The WAC answers *"what did the keys on this balance cost, so that
revenue can be recognized at consumption (F1) and a withdrawal can be priced without discount-arbitrage (cm.8)?"*
These are **orthogonal ledgers in different units**, and the entire model is the discipline that keeps them
**reconcilable** (F5) without letting the second corrupt the first. Every fork below is a choice about the
**second** ledger; **none of them touches the first** (G2 holds throughout).

The money pipe the WAC binds (the brief's): **pay-in (rail $) → keys (balance, at WAC) → spend (guesses /
buy-ins) → pool (💎) → winnings (💎) → withdrawal (rail $, cm.8)**. cm.6/cm.7 fixed the left end (gross at
entry); cm.8 is the right end; the WAC is the **middle term the gross cannot supply**.

---

## §1 — F1 · Revenue-recognition timing (THE fork the seed question raises)

*When is a purchase "earned" revenue? Keys are a **prepaid stored-value instrument** — the player pays now and
consumes the service (guesses, buy-ins) later.*

### Arm A — Cash-basis (gross recognized at pay-in; the WAC is a side ledger)

- **Rationale (ledger lens).** Revenue is the gross booked at purchase, full stop — exactly the as-built shape
  (`house_post("platform", rail, gross, "purchase", ord)`, cm.7 `D-3`; `house_balance/0..1`, `wallet.ex:340`).
  The WAC exists **only** as the cm.8 withdrawal cost basis, never for recognition. Revenue = cash in.
- **5W.** WHO: finance reads `house_balance()` per currency. WHAT: the gross row, unchanged. WHY: simplicity +
  it is what ships + it is a defensible point-of-sale policy for a virtual good. WHERE: `revenue_ledger`
  (frozen). WHEN: at `settle_payment/1` (cm.7 §5), the instant the rail confirms.
- **Steelman.** For a *consumable game token* many operators **do** recognize at point of sale (a key is a sale,
  not a refundable deposit). It needs **zero new accounting machinery**, it is the tax/operational truth (cash
  received), and it keeps one number per rail that already reconciles to the rail's own books.
- **Steward.** It is **shipped and frozen-safe** — it asks nothing of G2. But it leaves the **deferred-revenue
  liability invisible**: a balance of unspent keys is an undelivered obligation (the player can spend them later,
  or in cm.8 redeem their cost basis), and a single cash figure **cannot answer "what do we still owe in
  undelivered keys?"** For a prepaid instrument that is an incomplete book, not a wrong one.

### Arm B — Accrual (deferred at pay-in → realized at consumption)

- **Rationale (ledger lens).** The textbook-correct treatment of a prepaid instrument (ASC 606 / IFRS 15): pay-in
  is a **contract liability** (unearned); as keys are spent, `keys_spent · WAC` becomes **earned** revenue;
  unspent keys are a deferred-revenue liability at WAC. The WAC is **load-bearing for recognition**.
- **5W.** WHO: finance reads realized vs deferred. WHAT: reframe the pay-in row from "revenue" to "deferred
  revenue," then move it to "earned" as keys are consumed. WHY: a key is a performance obligation, satisfied on
  consumption. WHERE: it would have to **rewrite the meaning of the frozen `reason="purchase"` row** and the
  `house_balance` read that sums it as revenue. WHEN: recognition trails consumption, not pay-in.
- **Steelman.** It is the **most defensible revenue-recognition policy** in an audit — it never recognizes
  revenue before delivering the product, and the outstanding-keys liability is explicit on the balance sheet.
- **Steward — the disqualifier.** As a **replacement** it **breaks G2**: it reshapes what the byte-frozen
  `revenue_ledger` row *means* and what `house_balance/0..1` returns. cm.7 `D-3` exists precisely so purchase
  revenue is *visible* as `account="platform"`; re-labelling it "deferred" reverses that ruling. **Accrual-as-a-
  replacement is off the table.** Its correctness survives only if the gross booking is left untouched and the
  realized/deferred split is computed as a **derived view** — which is Arm C.

### Arm C — Hybrid (book gross at pay-in unchanged; ALSO maintain a realized/deferred projection)

- **Rationale (ledger lens).** Keep the cash ledger exactly as shipped (the frozen gross booking, the tax truth)
  **and** add a parallel realized/deferred split as a **derived read** — `realized = Σ(keys_spent_to_platform ·
  WAC)`, `deferred_liability = outstanding_keys · WAC` — so finance reads **both cash and accrual from one
  store**, no second ledger, no frozen-row touch.
- **5W.** WHO: finance + the Operator. WHAT: the unchanged gross rows **plus** a projection (a Postgres view /
  the analytics engine, F4) that reads the WAC basis (G1) to compute realized/deferred. WHY: the cash view is the
  operational/tax truth; the accrual view is the **economic** truth (what is earned vs owed). WHERE: a read over
  `revenue_ledger` + `transactions` + the forward WAC basis (no DDL on the frozen ledger). WHEN: on demand;
  point-in-time via the F4 projection.
- **Steelman.** It is the **only arm that delivers the accrual-correct view without violating G2** — both numbers
  exist, neither store is reshaped, and the WAC (G1, already ruled) is exactly what makes the split computable.
- **Steward.** It honours the cm.6 discipline literally — *"balance = sum of immutable rows, queried not
  re-derived"*: the gross rows stay the cash SoR; the realized/deferred split is a **projection** that cites
  them. It is additive, frozen-safe, and reuses `revenue_breakdown/1`'s shape (`wallet.ex:366`) as its seed.

### Ranking (ledger lens) — **C ≻ A ≻ B**

**C** is the lens winner: the only path to the accrual-correct book that respects the frozen ledger. **A** is a
strong, shipped, defensible #2 — keep it as the cash layer (it *is* the cash layer inside C). **B** ranks last
**only because, as a replacement, it breaks G2** — its accounting purity is precisely what C preserves
non-destructively.

### Pre-empt the SHOP lens's strongest objection

The shop lens will argue **Arm A** — "revenue = what arrived; a key is a sale not a deposit; the simplest policy
is the most operationally honest, and it is what ships." **Rebuttal, already on the page:** Arm C **keeps that
number byte-for-byte** — the cash figure the shop lens wants is the cash layer of the hybrid, unchanged and
frozen-safe. The disagreement is only over whether the deferred-revenue liability is *also* surfaced, and since
that is a **projection over the WAC the Operator already ruled in (G1)** — no second store, no frozen-row touch —
the cost of adding it is near-zero. The shop lens's simplicity win is **fully preserved**; C strictly dominates A
by adding the liability view for free. **Convergence point for the synthesis:** both lenses keep gross-at-pay-in;
the only live question is whether to *also* expose the accrual split, and the WAC makes that cheap.

---

## §2 — F2 · The WAC mechanics, within the G1 ruling (where on the balance, and how it re-blends)

*G1 is ruled: track a weighted-average cost per key, per player, **on the player balance account**. The fork is
the **relational shape**, not whether to track it.*

The WAC arithmetic (the brief's): on buy `new_avg = (old_keys·old_avg + bought·unit_price)/(old_keys+bought)`; on
spend `avg unchanged, cost_out = keys_spent · avg`. The **order-independence on spend** (the average is
unchanged — you never need to know *which* key you spent) is WAC's defining property and the whole reason it beats
FIFO/LIFO: **no consumption-order rule is needed.** Every shape below must honour that.

### Arm A — One running field on the player wallet (the recommended shape)

- **Rationale (ledger lens).** Store, beside `players.keys`, a single integer **`key_cost_basis_micros`** = the
  *total* canonical cost of the **current** key balance (canonical unit per F3). The WAC is **derived**
  (`basis / keys`), never stored. The re-blend is then **pure addition**: on buy of `B` keys at canonical cost
  `C`, `keys += B; basis += C` — **no weighted-average division at all** (the average emerges at read). On spend
  of `S` of `K`, `cost_out = floor(basis · S / K); basis -= cost_out; keys -= S`. O(1), one row, exactly the
  shape `players.keys` already is.
- **5W.** WHO: `Codemojex.Wallet` (`wallet.ex`), inside the existing `Repo.transaction`s that already mutate
  `keys`. WHAT: one new nullable `:bigint` column on `players` (additive migration, the cm.5/cm.6 precedent) +
  the basis delta written in the **same** transaction as every keys mint/spend (atomic, like cm.6's `house_post`
  rides the buy-in txn, `wallet.ex:271`). WHERE: `players` (the balance account, G1 literally). WHEN: on
  `settle_payment` (acquire), `charge_guess`/`buy_in`/`convert_to_keys` (spend/mint).
- **Steelman.** It is **integer-exact by construction** (store the total, never the average → no float WAC, no
  re-blend rounding on buy), **O(1)** on the hot path, **one row** (no table growth), and it satisfies *"on the
  player balance account"* word-for-word. cm.8 reads it in one indexed lookup.
- **Steward.** It mirrors the canonical codemojex pattern exactly — a running field on `players` (like `keys`,
  `diamonds`), reconstructable from the append-only trail (Arm C is its *audit*, not its rival). The dust is
  **structural** (F5): the remainder stays in `basis`, and spend-all (`S=K`) drains `basis` to exactly 0 — the
  cm.6 one-floor-complement discipline, applied to cost.

### Arm B — A cost-lots ledger (`LOT` rows per acquisition)

- **Rationale (ledger lens).** One immutable-ish `LOT` row per acquisition `{keys, unit_cost, remaining_keys}`;
  on spend, consume lots in an order (FIFO / specific-id). Exact provenance — every spent key traces to its
  purchase.
- **5W.** WHO: a new `LOT`-branded table + a consumption walker. WHAT: a row per buy, a `remaining_keys`
  **mutated** on each spend, a consumption-order rule. WHERE: a new table (off the `players` account). WHEN: on
  every acquire and spend.
- **Steelman.** Exact lot-level provenance enables FIFO/LIFO/specific-identification and a per-lot margin audit —
  the richest possible cost trail.
- **Steward — the disqualifier for a *WAC* policy.** G1 ruled **weighted-average**, under which **consumption
  order is irrelevant** (every key carries the blend). So the lot machinery — per-lot provenance, the exhaustion
  order, the `remaining_keys` mutation — buys **nothing the ruled policy uses**, while costing: (a) a **mutable**
  table (`remaining_keys` decrements), which **breaks the append-only ledger discipline** every codemojex ledger
  holds (`transactions`/`revenue_ledger` are append-only); (b) a consumption-order rule WAC exists to delete; (c)
  unbounded row growth on the hot path. It is the right shape only for a policy the Operator did **not** rule.

### Arm C — Derived-on-read (no stored field; recompute the WAC from history)

- **Rationale (ledger lens).** Store nothing on the balance; recompute the WAC by replaying the player's
  acquisitions + spends from `orders` + `transactions` on each read.
- **5W.** WHO: a read function. WHAT: a fold over the player's order/txn history. WHERE: **not** on the account
  (G1's literal "on the player balance account" is unmet). WHEN: per read — O(history).
- **Steelman.** Zero schema change; the basis is always re-derivable, so it can never drift from the source rows;
  it is the **correct definition** of the WAC.
- **Steward.** As the **PRIMARY** store it fails on three counts: it is **not "on the account"** (G1); it is
  **O(history) per read** (a hot-path and cm.8-path cost); and it needs data the current rows **do not carry** —
  the per-spend realized cost and the canonical per-acquisition cost (today `transactions.delta` is a bare keys
  count, `transaction.ex:8-13`; `orders.price_minor` is the rail gross, convertible only via the pinned rate).
  **But** as the **AUDIT of Arm A** it is exactly right: re-derive the basis from the append-only trail to verify
  the running field — the cm.6 reconciliation discipline. Arm A and Arm C **compose** (store + audit); they are
  not exclusive.

### Ranking (ledger lens) — **A ≻ C ≻ B** (A primary + C as its audit; B rejected for a WAC policy)

**A** is the store G1 mandates (on-the-account, O(1), integer-exact, append-aligned). **C** is its
**reconciliation read**, not a rival — adopt both (the field is authoritative; the replay audits it). **B** is
over-engineered for the ruled WAC and **fights the append-only discipline**; it would win only under a FIFO/
specific-id policy the Operator did not choose.

### Pre-empt the SHOP lens's strongest objection

The shop lens will likely want **cost-lots (Arm B)** for **per-package / per-rail provenance** — "which bundle and
rail did each key come from, for cohort margin." **Rebuttal, already on the page:** under the **ruled** WAC,
provenance is **deliberately blended away** (that is the policy). The acquisition-grain provenance the shop lens
needs **already exists, immutably, in `orders`** — `package_id` + `rail` + `price_minor` + the pinned rate (cm.7
§2.3) — and the per-cohort margin is an **analytics projection** (F4) over those rows, **not** a mutable cost-lots
table on the hot balance path re-implementing provenance the orders already hold. Arm A keeps the balance O(1) and
append-clean; the shop lens gets richer, immutable provenance from `orders` + `AEV`. **Both win; fungibility and
the append-only discipline are preserved.**

---

## §3 — F3 · The multi-currency cost basis (keys bought across stars / TON / USDT / RUB at floating rates)

*A key bought with TON costs nanoTON; with RUB, kopeck; with Stars, stars. A player's key balance is ONE pool of
**fungible** keys. What unit is the cost basis in?*

The governing fact: **keys are fungible.** Once in the balance, a key is not a "TON-key" or a "stars-key" — the
player spends *a key*. A single fungible pool can carry **exactly one** cost basis per key; the moment it carries
N, "spend a key" has no principled answer (the consumption-order problem WAC exists to avoid, F2). This fact
**decides the fork.**

### Arm A — Normalize to ONE canonical unit (USD sub-cent) at acquisition, from the pinned rate

- **Rationale (ledger lens).** A fungible key demands a single averageable unit; USD is the natural accounting
  bridge (cm.7 already computes `usd_face_cents`, cm.7.md §4b; the in-game economy already bridges via
  `@cents_per_diamond 1.2` + `to_cents`, `economy.ex:11,22`; cm.6's forward note already names `"cents"` as the
  read-time roll-up currency). Convert each acquisition's gross to **canonical micro-USD ONCE at acquisition**,
  using the **rate already pinned on the order** (cm.7 `D-4` — `rate_minor`/`rate_pair`/`rate_source`/
  `rate_quoted_at`). The WAC is then **one number**, reproducible (the rate is pinned), cross-rail comparable.
- **5W.** WHO: `KeyShop.settle_payment` feeds the canonical cost to `Wallet` at mint. WHAT: `canonical_cost =
  convert(order.price_minor, order.rate_*)` → added to `key_cost_basis_micros` (F2-A). WHY: fungibility +
  cross-rail margin + the cm.8 USD-denominated safe rate all need one unit. WHERE: computed at acquire, stored on
  `players`. WHEN: once, at settlement, from the pin (never re-read — the cm.7 `D-4` audit discipline).
- **Steelman.** One canonical WAC is the **only** coherent basis for a fungible balance; it is **reproducible**
  (the pinned rate is the audit anchor); and it is **the exact input cm.8 needs** (a single USD cost basis to
  price a safe withdrawal).
- **Steward — the one discipline that must be stated sharply.** The normalization is for the **WAC ONLY**, and it
  **does NOT contradict cm.7 `D-6` F5 "store native, convert at read."** Those rules govern **different
  ledgers**: the `revenue_ledger` keeps the **native-unit gross** ("what arrived," never normalized — frozen);
  the WAC is a **separate derived cost basis** in canonical units. The native audit is untouched; the canonical
  basis is an *additional* lens computed from the pinned rate. The lossy step `D-6` forbids (baking a rate into
  *the revenue ledger*) is **not** taken here — the revenue ledger stays native; only the new, derived basis is
  canonical.

### Arm B — Per-rail cost basis (a WAC per currency the keys were bought in)

- **Rationale (ledger lens).** Keep a separate WAC per rail; never cross-convert.
- **5W.** WHO: N basis fields (or N basis rows) per player. WHAT: a `{stars: …, ton: …, usdt: …, rub: …}` basis;
  on spend, **pick a rail**. WHERE: on the balance, ×N. WHEN: per buy (per rail) and per spend (after the pick).
- **Steelman.** Exact to the rail — no rate ever enters the basis; a TON-key's cost is pure nanoTON.
- **Steward — the disqualifier.** It **violates fungibility**: a single key balance carrying N bases forces
  "spend a key" to **pick one rail**, which is the FIFO/specific-id problem WAC was ruled in to delete (F2). It
  re-introduces a consumption-order rule, multiplies the balance schema ×N, and **still cannot answer "what did
  this spent key cost in one comparable unit"** without converting — so it pays the fungibility cost and *still*
  needs Arm A's conversion for any cross-rail report or the cm.8 rate. The per-rail visibility it offers is a
  **reporting** need that lives in `orders` (immutable, per-acquisition), not on the fungible balance.

### Arm C — Keys-as-the-unit + a stored canonical acquisition-cost per movement

- **Rationale (ledger lens).** Anchor everything to the **keys count**, and store, **per acquisition movement**,
  its canonical cost; the running basis is the sum, the WAC is `basis / keys`. This is the **storage discipline
  that realizes Arm A** — Arm A is the *unit decision* (one canonical unit), Arm C is *how it is stored* (per-
  movement canonical cost, anchored to keys, summed into the running field).
- **5W.** WHO/WHAT/WHERE/WHEN: identical to F2-A's running field — each acquisition contributes its canonical
  cost; the field is the sum; the WAC is the read-time quotient.
- **Steelman.** It makes the **store-exact / convert-at-read** discipline literal: the per-movement canonical cost
  is stored exact, the per-key average is computed at read (a quotient that may carry a remainder = dust, F5) —
  the cm.6 `D-2` pattern, applied to cost.
- **Steward.** It is **not a rival to Arm A** — it is its **implementation**. Together: the canonical unit is the
  WAC's unit (A); the storage is the per-movement canonical cost summed into the on-account running field (C).

### Ranking (ledger lens) — **A ≡ C (a pair) ≻ B (rejected — fungibility forbids it)**

**A** decides the *unit* (one canonical sub-cent USD); **C** is *how* it is stored and reconciled (per-movement
canonical cost → the running field → derived WAC). Adopt them as the pair. **B** is rejected: a fungible pool
cannot carry N bases without re-importing the consumption-order problem WAC exists to remove. **Unit pin (forward,
build-rung):** store the basis in a **fine canonical sub-cent integer** — micro-USD (1e-6 USD) — so a per-key WAC
of ≈ 13–26¢ (5-pack $1.29/5 ≈ 25.8¢; 1000-pack $129.99/1000 ≈ 13.0¢, `economy.packages.md`) is integer-exact and
the per-key division dust is < 1 µUSD; roll up to whole cents only at read. The exact factor is a **frozen
`Codemojex.Rails`-style constant** (cm.7 §4a) asserted by a boot vector, **never a mutable column** (the cm.7
`D-6` F5 "a money-scaling constant must be frozen" discipline).

### Pre-empt the SHOP lens's strongest objection

The shop lens will want **per-rail / per-package visibility** (toward Arm B) for **"blended margin per cohort /
rail / package"** (brief G5). **Rebuttal, already on the page:** per-rail **margin reporting** does **not** require
a per-rail **cost basis on the fungible balance**. The rail/package provenance for margin lives in the **immutable
`orders` rows** (`rail`, `package_id`, `price_minor`, the pinned rate) at the **acquisition grain** and in the
analytics projection (F4 / `AEV`) — *not* smeared across the fungible key pool. The cost **basis** must be single-
unit (fungibility); the margin **report** reads the orders provenance. The shop lens gets every per-rail/per-
package margin it needs from `orders` + analytics, while the balance carries one canonical WAC — **both lenses
win, fungibility intact.**

---

## §4 — F4 · The Analytics Engine shape (the broadened-scope read model)

*Report the money flow: gross pay-in, realized vs deferred revenue, the outstanding-keys liability at WAC,
blended margin per cohort/rail/package, the full funnel (pay-in → spend → pool → withdrawal).*

From the ledger / SoR-consistency lens the governing principle is: **the financial figures must be exact to the
system of record.** A reconciliation number that lags or drifts is worse than none. So this is **not one choice —
it is a layered read model**, and the ledger lens's job is to (a) insist the **financial layer is SoR-exact** and
(b) **specify what the ledger must EMIT** to feed every layer.

### Arm A — A Postgres view / materialized projection over `revenue_ledger` + `transactions` + `orders` (+ the WAC basis)

- **Rationale (ledger lens).** Read the same Postgres tables the money lives in, in the same transaction-
  consistent snapshot — so the reported figures **ARE the books, by construction** (no drift). `revenue_breakdown/1`
  (`wallet.ex:366`) is the seed; extend it to the realized/deferred split (F1-C), the liability-at-WAC, and the
  margin.
- **5W.** WHO: finance + the Operator. WHAT: a view (live, always-consistent) or a materialized view (point-in-
  time snapshots, a refresh cost). WHERE: Postgres, over the frozen ledger + the forward WAC basis — **zero DDL on
  `revenue_ledger`** (a read). WHEN: on demand / scheduled refresh.
- **Steelman.** **SoR-exact** — the financial truth has a single, transaction-consistent source. It is the
  layer an auditor accepts.
- **Steward.** The ledger lens's **primary** deliverable. The other layers **cite** it. Frozen-safe (a read).

### Arm B — An EchoStore projection (L1-ETS-over-L2-Valkey near-cache, `coherence:` mode)

- **Rationale (ledger lens).** Fast reads for live operator surfaces, fed by the ledger writes.
- **5W.** WHO: the live dashboard. WHAT: a near-cache projection. WHERE: EchoStore (`echo_store`, consumed not
  edited — G6). WHEN: continuously, eventually-consistent.
- **Steelman.** Sub-millisecond glanceable counters (the live pool, a revenue ticker) without hitting Postgres.
- **Steward — the coherence caveat.** A near-cache **lags** the ledger (the invalidation window). For a
  **glanceable counter** that is fine; for **financial reconciliation** it is **not** — the books cannot be
  eventually-consistent. So Arm B is right for the **live-counter** surface and **wrong** for the financial-report
  surface. It must be a cache that **cites Arm A**, never the source of a reconciliation figure.

### Arm C — A counting / analytics edge (bitmapist; `infra/cm-bitmapist`, `:6400`)

- **Rationale (ledger lens).** The **funnel-cohort** dimension — "how many actors in cohort X did action Y" —
  answered by branded-id-keyed bitmap set-ops. Verified on disk: `infra/cm-bitmapist/` (a Go port of Doist
  bitmapist4, **branded-id-native**: `Offset(id) = Hash32(Decode(id))`, exposing `Mark`/`MarkUnique`/`In`/`Count`/
  `AndCount`/`OrCount`/`XorCount`/`RetentionRow`). *(The brief's `infra/codemojex-bitmapist` is the README NAME;
  the on-disk directory is `infra/cm-bitmapist` — NO-INVENT correction.)*
- **5W.** WHO: growth/operator funnel reads. WHAT: actor cohorts — buyers → spenders → winners → withdrawers,
  retention rows. WHERE: a **second system** (a Go service on `:6400`), fed by `AEV` events the ledger emits. WHEN:
  marked at each pipe stage; queried as set cardinalities.
- **Steelman.** Bitmap cohort/funnel math is the **right tool** for the actor funnel (cardinality, retention,
  conversion) and the substrate **already exists**.
- **Steward — two flags.** (1) It **counts actors, it does not sum money** — `Offset` is MurmurHash3-derived and
  **one-way** (it cannot reverse to the id or the amount), so it answers *"how many players bought then withdrew,"*
  never *"how much revenue"*; it is the **funnel** layer, not the **money** layer. (2) It is a **second system to
  operate** — a real operational cost the ledger lens names.

### The layered model (the ledger-lens deliverable) + **what the ledger MUST EMIT**

The analytics engine is **three layers**, each citing the one below:

| Layer | Surface | Arm | Consistency | Fed by |
|---|---|---|---|---|
| **Financial / reconciliation** | gross · realized/deferred · liability-at-WAC · margin | **A** (Postgres view) | **SoR-exact** | `revenue_ledger` + `transactions` + `orders` + the WAC basis |
| **Live counters** | the live pool, a revenue ticker, ops dashboards | **B** (EchoStore) | eventually-consistent (a cache that cites A) | the ledger writes |
| **Funnel / cohort** | buyers→spenders→winners→withdrawers, retention | **C** (bitmapist) | actor-set cardinality | **`AEV`** events |

**What the ledger must EMIT to feed this (the brief's explicit ask):**

1. **The gross rows — already emitted, frozen.** `revenue_ledger` carries `{account, currency, delta, reason,
   ref}` — gross by rail, by movement-kind, by ref. Sufficient for the **cash** view as-is (G2 holds).
2. **NEW — cost-basis movements (the accrual + liability feed).** Per key-spend, the **realized cost**
   (`keys_spent · WAC_at_spend`) and the **running outstanding basis**; per acquisition, the **canonical cost**.
   This is the F2 running-field trail (the per-movement canonical cost + the realized-cost-out). Without it the
   realized/deferred split (F1-C) and the liability-at-WAC are not computable. **Forward-tense — this is the
   rung's new emission.** It needs **no new brand** on the recommended path (an additive `players` column + a
   nullable `cost_micros` annotation on the keys-movement `TXN`); see §6.
3. **NEW — `AEV` actor events (the funnel feed).** A `buy` / `spend` / `win` / `withdraw` event, keyed by the
   `PLR` id, **append-only, one-way, never authoritative** (rebuildable by replay — the roadmap's `AEV`
   definition, `codemojex.roadmap.md:66`). This feeds Arm C's bitmap marks (`Mark(player_id, "bought")` →
   `AndCount` the cohorts). **Forward-tense.**

### Ranking (ledger lens) — **A ≻ C ≻ B** (but LAYERED, not either/or)

**A** is non-negotiable for the financial figures (SoR-exact — the books). **C** is a real, distinct second
value (the actor funnel the bitmapist substrate already serves), ranked above B because its job (cohort counting)
is **honest at what it does** — it does not pretend to be the money truth. **B** ranks last **for reconciliation**
(a coherence liability the ledger lens trusts least), though it is fine as a **glanceable cache** that cites A.

### Pre-empt the SHOP lens's strongest objection

The shop lens will champion the **fast** layers (bitmapist C and/or EchoStore B) as the **product** analytics
surface — real-time operator dashboards, a live revenue funnel. **Rebuttal, already on the page:** the ledger lens
**does not reject the fast layers** — it **layers** them. It insists only that every **financial** figure
(revenue recognized, deferred liability, margin) has an **SoR-exact Postgres source of record (A)**, and the fast
surfaces (B/C) are **caches and cohort-counters that cite it**. A fast number that does not tie out to the books
is a finance liability, not a feature. **Convergence:** the shop lens gets its live product surfaces; the ledger
lens gets its SoR-exact truth; `AEV` feeds both — the engine is layered, and the layering *is* the agreement.

---

## §5 — F5 · The conservation invariant (what must balance, and the WAC's role)

This is the ledger lens's headline deliverable. The cm.6 lesson is explicit: a money invariant needs a **grid /
property test, not fixed examples** — cm.6's fixed-example suite missed a `div(pool,10)→div(pool,9)` floor-
divergence survivor (`codemojex.roadmap.md:166`, the Apollo M5 finding). The WAC carries the **same hazard on the
money the platform later pays out** (cm.8). So: state the identity precisely, make it a property/grid target, pin
the dust rule, and reconcile it with cm.6 so it does not break it.

### The identity (canonical units — micro-USD; per player, summed to platform)

Two ledger-lens **refinements of the brief's candidate** are load-bearing, because the brief's candidate
(`Σ gross_pay_in == Σ realized_revenue + deferred_liability + Σ withdrawn_at_cost + dust`) **omits two terms that
a game with a prize pool and winnings cannot omit**:

- **Refinement 1 — keys minted from WON diamonds are a basis injection NOT from pay-in.** A player converts won
  💎 → keys (`convert_to_keys`, `wallet.ex:157`); those keys enter the balance with a cost basis = the diamonds'
  canonical value (10💎 = 1 key, `@diamonds_per_key 10`; 💎 = 1.2¢, `@cents_per_diamond 1.2`), **not** a pay-in.
  The identity must carry a **`B_win`** term or it will not balance for any player who has won.
- **Refinement 2 — spent keys SPLIT by destination; pool-funding keys are a LIABILITY transfer, NOT realized
  revenue.** Keys spent on golden guesses (`charge_guess_golden` → `inc_pool!`, `wallet.ex:139`) and the pool
  portion of buy-ins (`entry_fee_split_keys`, `economy.ex:63`) fund the **prize pool** — a liability the platform
  owes the winners, **not** platform revenue. Only paid-room guess fees and the buy-in **house cut** (cm.6's
  `house_post(@house,"keys",fee-pool_keys,…)`, `wallet.ex:271`) are realized revenue. Lumping all spend into
  "realized revenue" (the brief's candidate does) **overstates revenue by the pool transfer.**

The corrected platform-wide identity (canonical micro-USD), with every key's cost accounted:

```
  Σ canonical_gross_pay_in            (money players put in, each order's price_minor at its pinned rate)
+ Σ winnings_converted_to_keys_basis  (B_win — keys minted from won 💎, valued at 10💎=1key, 💎=1.2¢)
==
  deferred_liability  (= Σ outstanding_keys · WAC)            ← F1 deferred / the unspent-keys liability
+ realized_revenue_basis  (cost basis of keys → platform: paid-room guess fees + buy-in house cut)
+ pool_transfer_basis     (cost basis of keys → the prize pool: golden guess fees + buy-in pool portion)
+ Σ withdrawn_at_cost     (cm.8 — cost basis of keys/💎 leaving via withdrawal)
+ ε                       (the named rounding dust — see the dust rule)
```

In words: **every micro-USD a player put in (plus every micro-USD of winnings converted to keys) is, at all
times, either still held as keys (the deferred liability), or has left the balance as platform revenue, as a pool
transfer, or as a withdrawal — plus a bounded, named dust.** The gross-pay-in side is the **canonical-converted**
gross (using the pinned rates), **not** the native-unit revenue_ledger sum — the identity lives in the WAC's
canonical unit, while the revenue_ledger keeps its native audit untouched (the §0 two-ledgers distinction).

### Reconcile with cm.6's keys-unit conservation (it must NOT break)

cm.6's invariant is `Σ player_key_debits == Σ house_key_credits + Σ pool_key_portions` — a **keys-count**
conservation at the **buy-in**, over three observable columns (`wallet.ex:362-365` docstring; roadmap `D-3`).
The WAC identity is **orthogonal**: it is a **canonical-cost** conservation across the **whole pay-in→spend→
withdraw pipe**. They hold **simultaneously on different units and grains** — cm.6 governs that a buy-in's *keys*
partition exactly (the one-floor `entry_fee_split_keys` complement); the WAC identity governs that the *canonical
cost* of those same keys is conserved as they flow. The WAC model **reads** cm.6's keys split (the realized-vs-
pool destination of buy-in keys is exactly cm.6's house-cut-vs-pool-portion split) and **values** it in canonical
units. Nothing in the WAC model re-denominates or edits cm.6's keys conservation — it **composes on top**.

### The dust rule (the cm.5 `add_dust` / cm.6 one-floor precedent) — make it STRUCTURAL

Store the **total basis** (not the average), and conservation becomes structural — no leak possible:

- **On buy:** `basis += canonical_cost` — pure **addition**, **no division, no dust** on acquisition.
- **On spend of `S` of `K`:** `cost_out = floor(basis · S / K); basis -= cost_out; keys -= S`. The remainder
  (`basis·S/K − cost_out`) **stays in `basis`** (it is not subtracted), so it is **never lost** — it stays
  attached to the remaining keys (minutely raising their WAC) and **washes out at spend-all**: when `S = K`,
  `cost_out = floor(basis·K/K) = basis` exactly → `basis → 0` with **zero strand**. ε is therefore bounded by
  `< 1 µUSD` per held balance and **→ 0 on spend-all** — the cm.6 "no key minted or lost" discipline, applied to
  canonical cost (`add_dust`, `economy.ex:113-115`; the `entry_fee_keys − pool_keys` complement, `wallet.ex:252`).
- **The canonical conversion at acquisition** (rail minor → µUSD via the pinned rate) floors consistently; any
  sub-µUSD remainder is **accumulated in a named platform dust line**, never silently dropped — so ε is a
  **tracked ledger figure**, the auditable residue, not a leak.

### The property / grid test target (the cm.6 lesson, operationalized)

A **property test** (StreamData-style), not fixed examples, asserting the identity holds **exactly** (modulo the
pinned ε) for every generated sequence. The grid must sweep:

- **multiple rails × multiple rates** (stars/ton/usdt/rub at varying pinned rates) → the **cross-currency
  re-blend** (F3) and the canonical conversion;
- **buys interleaved with spends** → the re-blend ordering and the running-field arithmetic;
- **the golden bands** (deposit-recovery / first-mover / full-revenue, `entry_fee_split_keys`) → the **realized-
  vs-pool split** (Refinement 2);
- **conversions** (won 💎 → keys, `convert_to_keys`) → the **`B_win` injection** (Refinement 1);
- **edges:** spend-all (`outstanding → 0`, `basis → 0` exactly, no strand), buy-after-zero (re-blend from empty),
  1-key / sub-cent amounts (the per-key division dust), and a forward cm.8 withdrawal leg (`withdrawn_at_cost`).
- **A net-zero mutation spot-check** (the cm.6/cm.7 precedent): replacing the `floor`-and-retain dust rule with a
  naive `round` (or dropping the pool-transfer term) **MUST** make the property fail — the proof the test is live.

### Ranking (ledger lens)

There is no arm to rank here — F5 is a **deliverable, not a choice**: the identity above (with both refinements),
realized as a **structural** running-total basis, gated by a **property/grid test** with the named dust line. The
only fork the synthesis carries is **where the test lives** (a `Wallet`/`Economy` property suite — the cm.6
`conservation` test's sibling), which is an implementation seam, not an architecture fork.

### Pre-empt the SHOP lens's strongest objection

The shop lens may treat conservation as accounting ceremony, secondary to pricing and the funnel. **Rebuttal,
already on the page:** conservation is the invariant that makes the WAC **trustworthy for the shop lens's own
numbers.** The cm.8 safe-withdrawal rate and the G5 blended-margin reports are only as honest as the cost basis
they read; an unconserved basis (dust leaking, or pool-transfer mis-booked as revenue) **silently corrupts every
margin and withdrawal figure downstream** — the cm.6 floor-divergence survivor, but now on money the platform
**pays out** (a worse failure mode). The property test is not ceremony; it is the **gate that protects the shop
lens's pricing and margin surfaces.** **Convergence:** the conservation invariant is the shared floor both lenses
build on.

---

## §6 — The new branded entities (forward-tense; namespace verified against `codemojex.design.md`)

The as-built nine brands are `PLR`/`ROM`/`GAM`/`GES`/`EMS`/`TXN`/`JOB`/`NOT`/`CMD` (`codemojex.design.md`
namespace table) + `SES` (cm.4) + `RVL` (cm.6); cm.7 takes `PKG`/`ORD`/`OTX` (+ `WHK` forward). The forward
catalog (`codemojex.roadmap.md:47-66`) reserves `RMP`/`BNK`/`RSC`/`SHR`/`AEV`. `generate!/1` accepts any
`[A-Z]{3}` with zero registration (the cm.7 `A-8` ground).

| Brand | Entity | Status | Needed when |
|---|---|---|---|
| **(none)** | the cost basis itself | **recommended path needs NO new brand** | F2-A: a `players.key_cost_basis_micros` **column** + a nullable `cost_micros` annotation on the keys-movement `TXN` — the basis is a running field on an existing entity, audited by `orders` + `transactions` (Arm C). The steward win: **fewer brands.** |
| **`AEV`** | analytics event | **named-forward (catalog)** — cite, write forward-tense | F4 funnel feed: an append-only, one-way actor event (`buy`/`spend`/`win`/`withdraw`), keyed by `PLR`, feeding the bitmapist cohorts. Already reserved (`roadmap:66`). |
| **`LOT`** | a cost lot | **proposed forward — ONLY if F2-Arm-B is ruled** | the cost-lots ledger (F2-B). **Verified FREE** (absent from the as-built nine + the forward catalog). Surfaced as the brand Arm B *would* need; **not** on the recommended path (Arm A needs none). |
| **`WDR`** | a withdrawal record | **named-forward (cm.7 §8.2)** — cite | cm.8: the withdrawal id the negative-`delta` `house_post("platform",rail,-payout,"withdrawal",wdr_id)` references; the WAC is its cost-basis input (§7). Not minted this scope. |

**Recommendation on brands:** the recommended path (F2-A + F3-A/C) introduces **no new brand for the cost basis**
(a `players` column + a `TXN` annotation), cites **`AEV`** (named-forward) for the funnel, and feeds the forward
**`WDR`** (cm.8). **`LOT`** is surfaced only as the brand the rejected cost-lots arm would require — its presence
in the synthesis is a signal that ruling F2-B carries a new branded, mutable, append-breaking table.

---

## §7 — The cm.8 withdrawal-cost seam the WAC must serve

cm.8 is the right end of the pipe (💎 → rail $); cm.7 §8.2 already **names** the seam — a withdrawal books a
**negative `delta`** to the same frozen `revenue_ledger` (`house_post("platform", rail, -payout_minor,
"withdrawal", wdr_id)`), admitted because the `delta` is signed with no CHECK (the same property the cm.6
`deposit_seed` debit relies on). The WAC is what makes that debit **safe**:

1. **The cost-basis input to a safe rate (the anti-arbitrage floor).** Without a cost basis, the discount is an
   arbitrage: a whale buys keys at the 50%-discount WAC (≈ 13¢/key, `economy.packages.md` 1000-pack), and if the
   value round-trips out at full face, extracts the discount as cash. The WAC gives cm.8 the **true cost basis of
   the keys/💎 being withdrawn**, so the safe withdrawal rate is bounded by `f(WAC)` — the platform pays out no
   more than cost basis warrants, and the discount **cannot be withdrawn as profit**. The WAC is the input the
   gross **cannot** supply (the gross is "what arrived"; the WAC is "what it cost") — exactly the brief's "💎 →
   keys → WAC = the cost basis that stops discount-arbitrage."
2. **The margin computation on the negative debit.** When cm.8 books `-payout`, the platform's per-withdrawal
   margin = `(canonical value received for those keys) − payout` — and `Σ withdrawn_at_cost` (the F5 term) is the
   cost basis leaving via withdrawal, which the WAC supplies. So `house_balance()` nets purchases (positive)
   against withdrawals (negative) per rail (cm.7 §8.2), and the WAC turns that net into a **true margin** (gross −
   cost basis − payouts).
3. **What the WAC's shape must guarantee for cm.8 (why F2-A + F3-A are the cm.8-serving arms).** cm.8 reads the
   cost basis **at withdrawal time**, so it needs: **(a)** an **O(1), on-the-account** read — F2-**A** (a running
   field on `players`), not F2-C (an O(history) replay) nor F2-B (a mutable lots walk); and **(b)** a **single
   canonical unit** it can convert to the rail at the pinned withdrawal rate — F3-**A** (canonical µUSD), not
   F3-B (N per-rail bases with no single basis to price against). The **rate-pin shape cm.7 built** (`D-4`:
   `rate_minor`/`rate_pair`/`rate_source`/`rate_quoted_at`) is the **exact** shape a `WDR` row pins for the
   diamonds→rail rate (cm.7 §8.2) — the WAC supplies the cost basis, the pinned rate supplies the conversion, and
   the withdrawal is reproducible. **The recommended arms (A on F2, A/C on F3) are precisely what the withdrawal
   seam needs** — designing the WAC any other way makes cm.8's hot path slow or its basis ambiguous.

cm.8 **builds** the `WDR` table, the diamonds-debit + `locked_diamonds` interaction, KYC/AML, the 21-day hold,
and the floating-rate source; **this scope builds none of it** — it ensures the WAC is the on-account, canonical,
conserved cost basis cm.8 can read.

---

## §8 — Recommendation (advice from the ledger lens — never a decision)

Keep the shipped cash ledger exactly as it is — the byte-frozen `revenue_ledger` booking gross-at-pay-in in native
rail units is the tax/operational truth and G2 (so **F1-A is retained as the cash layer**) — and **add the WAC as
a single canonical-µUSD running field on the player balance** (F2-**A**: store the total basis, re-blend by pure
addition, derive the average at read), in **one canonical unit** (F3-**A**, realized via F3-**C**'s per-movement
storage), normalized once at acquisition from the **rate cm.7 already pins** — never touching the native-unit
revenue audit. On that basis stand three things: a **hybrid realized/deferred projection** (F1-**C**: the cash
view unchanged + the accrual view as a derived read, the only accrual-correct path that respects the frozen
ledger); a **layered analytics engine** (F4) whose **financial figures are SoR-exact in Postgres (A)**, with an
EchoStore live counter (B) and the existing `infra/cm-bitmapist` funnel (C) as eventually-consistent caches/
cohort-counters that **cite** it, fed by **`AEV`** events; and the **cm.8 safe-withdrawal cost basis** (§7).
Bind the whole with the **canonical money-conservation identity** (§5, with the two refinements the brief's
candidate omits — the winnings-injection `B_win` and the pool-transfer-vs-realized split — and the cm.6 keys-
conservation it composes on, not breaks), realized as a **structural** running-total basis with the floor-and-
retain dust rule, and **gated by a property/grid test** (the cm.6 floor-divergence lesson). On the recommended
path **no new brand is needed for the cost basis** (a `players` column + a `TXN` annotation); cite the named-
forward **`AEV`** (analytics) and **`WDR`** (cm.8); **`LOT`** is the brand the rejected cost-lots arm (F2-B) would
require, surfaced so the Operator sees the cost of ruling it. The through-line: **two ledgers, one canonical unit
for the second, conservation proven by property, the frozen first never touched.**
