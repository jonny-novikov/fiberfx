# cm.7 — Stories (the acceptance face)

> The Operator's verifiable acceptance for cm.7, derived from [`cm.7.md`](./cm.7.md) (the body wins on any
> disagreement) and the **locked rulings** (`cm-7` ledger `D-1`..`D-6`). The model is the **KeyShop**: a `PKG`
> catalog (DB-stored), an `ORD`/`OTX` order flow (one `orders` table + a `rail` discriminator; the **partial
> unique index `(rail, external_id) WHERE external_id IS NOT NULL`** the exactly-once gate; `WHK` folds into it
> for the Stars launch, `D-5`), the frozen `Codemojex.Rails` + the pure `Codemojex.KeyShop` pricing modules, the
> Stars rail end-to-end via `settle_payment/1`, and gross purchase revenue booked into the **same**
> `revenue_ledger` cm.6 founded (`account="platform"`, `reason="purchase"`, `currency=`the rail — `D-3`). Each
> story is Connextra + Given/When/Then; each names the invariant(s) it exercises and the surface that closes it.
> A gate must **exercise** its outcome — a no-op must not satisfy a story's letter.
>
> **RULED — the design phase is closed (`D-1`..`D-6`).** Framing: third person; no first-person-agent
> narration; no perceptual / interior-state verbs; **forward-tense** for the unbuilt KeyShop surface
> (`Codemojex.Rails` / `Codemojex.KeyShop` · the `PKG`/`ORD`/`OTX` tables (+ the `WHK` forward) · the invoice
> flow).

## Roles

- **A player** — buys keys across rails: wants to pick a package and pay in Stars (today) or TON/USDT/RUB
  (forward), and receive the keys exactly once. The product the player buys is **keys**; the rail is the
  payment method.
- **Finance** — reads the platform's purchase revenue: wants every sale booked **gross, exactly once, in the
  rail's native unit**, into the same `revenue_ledger` as the Golden cuts, reproducible from the pinned rate.
- **The Operator** — accepts the rung; signs off the exactly-once invariant, the three-row atomicity, the
  byte-frozen cm.6, the editable catalog, and the migration up/down; **rules** the F1–F5 forks.
- **A redelivering rail** — Telegram redelivers a `successful_payment`, a chain re-emits a confirmation; the
  `OTX` `(rail, external_id)` partial-unique gate makes the redelivery a no-op (for the Stars launch `WHK`
  **folds into** that gate, `D-5`; the forward `webhooks` table dedups the *delivery* at ingress for the async
  push rails).
- **The cm.6 `revenue_ledger`** — the **same** ledger this rung books into (no second revenue store); cm.7
  adds purchase rows with zero DDL (the cm.6 [§ Forward](./cm.6.md) seam).
- **cm.8 — the cash-out rung** — a forward consumer that binds to the withdrawal-debit seam cm.7 designs-for
  (a negative-`delta` house debit in the rail currency); **named**, not built (`D-2`).

---

## S1 — Exactly-once mint per rail (THE headline — the double-mint fix)

*As Finance, I want a replayed payment to mint keys and book revenue exactly once, so that a redelivered
webhook never duplicates keys or revenue.*

**Exercises:** the exactly-once invariant (A1, INV-EXACTLY-ONCE-PER-RAIL); the `OTX` **partial unique index
`(rail, external_id) WHERE external_id IS NOT NULL`** gate; the named fix for the current `"stars"`-literal
double-mint (`wallet.ex:147`/`game_controller.ex:46`). **Surface:** `Codemojex.KeyShop.settle_payment/1` (§7)
gated on the `OTX` insert (the cm.5 `insert_buy_in` Pattern A — `on_conflict: :nothing` + the count-rose check,
`golden_rooms.exs:73-76`).

- **Given** a fulfilled order (rail `r`, `external_id e`) — keys minted, revenue booked
- **When** the same payment (`r`, `e`) is delivered again (a redelivered `successful_payment` / a re-emitted
  confirmation)
- **Then** `players.keys` rose **once**, there is **exactly one** `TXN` purchase credit and **exactly one**
  `RVL` purchase row for that payment — the second `settle_payment/1` is a **no-op** (the `OTX` insert hits the
  partial unique index and suppresses; no second mint, no second booking),
- **And** the **mutation guard:** removing the partial unique index `(rail, external_id)` (or the `on_conflict`
  suppression) MUST make this story **fail** (the net-zero spot-check — the gate proves the gate).

## S2 — The three rows, one transaction, all-or-nothing

*As the Operator, I want a purchase's external receipt, key credit, and revenue booking to be all-or-nothing,
so that a crash can never leave a half-recognized purchase.*

**Exercises:** atomicity (A2); the three-rows-one-event model (§2). **Surface:** the single `Repo.transaction`
in fulfilment: insert `OTX`, mint the `TXN` key credit, book the `RVL` gross via `Wallet.house_post`
(`wallet.ex:482`).

- **Given** a confirmed payment for an order (package keys `K`, gross `G` minor units)
- **When** fulfilment commits
- **Then** the `OTX` receipt **AND** the `TXN` key credit (`players.keys += K`) **AND** the `RVL` gross
  booking (`+G`) are **all present**,
- **And** a forced rollback mid-fulfilment leaves **none** of the three — **no key minted**, no receipt, no
  revenue row (one `Repo.transaction`; a partial recognition is impossible).

## S3 — Revenue booked GROSS, native unit, same ledger (the multi-currency seam)

*As Finance, I want purchase revenue booked gross in the rail's native minor unit into the same ledger as the
Golden cuts, so that the platform's books are one queryable balance across rails.*

**Exercises:** gross booking (A3); the minor-unit convention (F5/`D-6`); the multi-currency read seam (cm.6
S11); the `D-3` account convention. **Surface:** `Wallet.house_post(Wallet.house_account(), "<rail>",
+gross_minor, "purchase", order_id)` (`account="platform"`, `reason="purchase"` — `D-3`) →
`Wallet.house_balance/0..1` (`wallet.ex:325`, `SUM(delta) GROUP BY currency` — **unchanged**).

- **Given** a Stars purchase whose Telegram `total_amount` is `T` ⭐
- **When** it is fulfilled
- **Then** `revenue_ledger` holds **one** `+T` row (`currency="stars"`, `account="platform", reason="purchase"`, `ref=`the order
  id) — the **gross** Telegram credits the developer, booked verbatim (not a computed expectation),
- **And** `Wallet.house_balance()` returns `%{"keys" => …, "stars" => T}` — the **cm.6 read with no change**,
  the new `"stars"` bucket present beside the Golden `"keys"` bucket (the seam `D-5`/S11 forecast),
- **And** a `currency="ton"` purchase sums into its own **nanoTON** bucket and a `"rub"` into **kopeck** — each
  rail's gross stored in its native unit, no normalization at write (the cm.6 `D-2` discipline; a shaped-rail
  unit check).

## S3b — Purchase revenue is SEEN by the reconciliation read (the `D-3` correctness fix)

*As Finance, I want the purchase revenue to appear in the house balance the ledger exists to answer, so that the
platform-revenue figure is not silently under-reported by the booking-account choice.*

**Exercises:** INV-VISIBLE-REVENUE (`D-3`, A8b); the booking-account convention. **Surface:** the booking
`account="platform"` (`D-3`) → `Wallet.house_balance/0..1` defaults `WHERE account == "platform"` (`@house`,
`wallet.ex:22`; `wallet.ex:325-328`).

- **Given** a fulfilled Stars purchase (booked `account="platform"`, `reason="purchase"`, `currency="stars"`)
- **When** Finance reads the default `Wallet.house_balance()` (the `WHERE account="platform"` filter)
- **Then** the result **includes** the `"stars"` purchase revenue (the platform-revenue figure is complete),
- **And** the **mutation guard:** booking the purchase as `account="purchase"` MUST make this story **fail** —
  the revenue would be invisible to the one reconciliation read (the precise defect `D-3` prevents; the gate
  proves the gate).

## S4 — The price + the rate (with provenance) are PINNED on the order (reproducible, auditable booking)

*As Finance, I want the rail price, the conversion rate, AND its provenance pinned at order creation, so that
booked revenue is reproducible and self-describing no matter how the rate moves afterward.*

**Exercises:** the rate-pin + provenance (A4); `D-4` (config source + `rate_source`/`rate_quoted_at`, pinned per
order). **Surface:** `ORD` carries `price_minor` + `rate_minor`/`rate_pair`/`rate_source`/`rate_quoted_at`, set
once at creation from the `key_shop_rates` config map (§6a); the live rate is **never** re-read for that order.

- **Given** a TON order created at config rate `R` (`price_minor` derived from the USD face × `R`, in nanoTON;
  `rate_source="config"`, `rate_quoted_at` stamped)
- **When** the config rate later changes to `R'`
- **Then** the order's `price_minor` and `rate_minor` are **still `R`-derived** (the live rate is not re-read),
  and `rate_source`/`rate_quoted_at` record the booking's origin (the `D-4` provenance — finance can answer
  "why this rate"),
- **And** when the order settles, the booked `RVL` gross equals the **pinned** `price_minor` — a booked order is
  reproducible from its own pinned rate, independent of the current config (the cm.8 rates table upgrades the
  source without reshaping the order).

## S5 — The pure `KeyShop` module — priced, net-revenue, store-fee (fixture-tested)

*As a player, I want each package priced in my chosen rail; as the Operator, I want true mobile/desktop
take-home, so that the shop reads correctly and revenue planning is honest.*

**Exercises:** the pricing module (A5); F2/V-2 (base price + derived conversion + overrides); the store-fee
math (`economy.packages.md`); purity. **Surface:** `Codemojex.KeyShop` (`lib/codemojex/key_shop.ex`) — pure,
no `Repo`, no HTTP.

- **Given** a package (the `economy.packages.md` ladder — e.g. 100 keys = 1 449 ⭐, display 27%) and a rate map
- **When** `KeyShop.price_minor(pkg, rail, rates)` runs
- **Then** for `"stars"` it returns the package `stars_price` **verbatim** (the canonical base face); for
  `"ton"`/`"usdt"`/`"rub"` it returns the **USD-face-derived** amount in that rail's minor unit (within the
  rounding pin) — **unless** the package carries a per-rail override, which is honored over the derived price,
- **And** `KeyShop.net_revenue(stars, :mobile, rates)` ≈ **68%** of the USD face and `:desktop` ≈ **97%**
  (`economy.packages.md`'s ~32% / ~3% fee) — the store fee is a **read-time reporting** figure, not a booked
  deduction (the ledger books the gross, S3),
- **And** the discounts live **once** in the base ladder (a rail does not carry its own discount),
- **And** `KeyShop` is **pure** — the same `(pkg, rail, rates)` always yields the same price (a property
  check), no clock, no DB.

## S6 — The client cannot supply the key count or the payment ref (the gap closed)

*As the Operator, I want minting impossible without a captured, exactly-once payment, so that the current
free-key replay surface is gone.*

**Exercises:** the cutover (A6); the named hazard (`game_controller.ex:46` `params["ref"] || "stars"`).
**Surface:** the create-order route takes `{package_id, rail}` only; the mint moves inside OTX-gated
fulfilment (§9); `Wallet.purchase_keys/3` is retired or made an internal fulfilment helper.

- **Given** the order flow
- **When** a client posts a key count (`params["keys"]`) or a payment ref (`params["ref"]`) directly
- **Then** **no keys are minted** — the create-order route accepts only `{package_id, rail}` (the price + the
  amount are server-derived and pinned), and minting is reachable **only** from the OTX-gated fulfilment path,
- **And** a grep shows no `params["keys"]`/`params["ref"]` reaching a `credit`/mint, and `Codemojex.
  purchase_keys/3` is no longer a public client surface.

## S7 — The `pre_checkout` tamper guard (the Stars rail)

*As Finance, I want the pre-checkout step to reject a tampered amount or a non-`created` order, so that a player
cannot pay a different amount than the order pinned.*

**Exercises:** the invoice flow (A7); fail-closed (the cm.4 discipline). **Surface:**
`CodemojexWeb.TelegramController` `pre_checkout_query` handling (§7 step 2).

- **Given** a `created` Stars order with pinned `price_minor`
- **When** a `pre_checkout_query` arrives whose amount ≠ the pinned `price_minor`, **or** whose `ORD` is not
  `created`
- **Then** the bot answers `answerPreCheckoutQuery ok: false` (the payment is refused),
- **And** a `pre_checkout_query` whose amount matches the pinned `price_minor` on a `created` order → `ok:
  true` (a present, valid precondition runs it — not a silent skip).

## S8 — The catalog is DB-stored and editable without a deploy

*As the Operator, I want to edit the shop's bundles and prices without a deploy, so that the catalog is an
operational lever, not a code change.*

**Exercises:** the catalog (A8); the DB-stored requirement (cm.6 Scope-Out). **Surface:** the `packages`
(`PKG`) table + `Codemojex.key_packages/0` (the `enabled`-sorted read).

- **Given** the `packages` table seeded with the launch ladder (`economy.packages.md` — 5/15/50/100/200/500/
  1000 keys)
- **When** `Codemojex.key_packages/0` is read
- **Then** it returns the **`enabled`** packages, **sorted** (the shop face),
- **And** toggling a row's `enabled=false` (a DB update) removes it from the next read **with no deploy**, and
  editing a price / a per-rail override is reflected on the next read.

## S9 — cm.6 is byte-frozen; the existing suites stay green (additive only)

*As the Operator, I want cm.7 to add the pay-in rows without touching cm.6, so that the money-critical revenue
ledger and its proofs are unchanged.*

**Exercises:** the cm.6 freeze (A9, `D-1`); additivity. **Surface:** cm.7 books through the existing
`Wallet.house_post` — no edit to `revenue_ledger.ex`, the cm.6 migration, or the cm.6 booking sites
(`wallet.ex`/`rooms.ex`).

- **Given** the byte-frozen cm.6 `revenue_ledger.ex`, its migration, and its booking lines (the seed debit,
  the buy-in credits, the void reclaim)
- **When** cm.7 books purchase rows and `mix test --include valkey` runs (Valkey 6390 + Postgres)
- **Then** `git diff --stat` over the cm.6 code is **empty** (no cm.6 file edited),
- **And** the cm.4 auth, cm.5 golden, and cm.6 revenue suites stay **green** alongside the new KeyShop suite —
  cm.7 is purely additive on the purchase side.

## S10 — The migration up/down + fresh reinit clean

*As the Operator, I want the new commerce tables to migrate up and down cleanly from a fresh schema, so that
the shop's schema is reversible and reproducible.*

**Exercises:** the migration gate (A10). **Surface:** the one new additive migration (the 5th) creating
`packages` · `order_transactions` · `orders` (+ the `webhooks` forward table, `D-5`) — Venus-Postgres; the
first real FKs (`references type: :string`).

- **Given** a fresh `codemojex_test` (the DB name read from `config/test.exs`, surfaced before the drop)
- **When** the cm.7 migration runs `up` then `down` (the `down` drops in FK order)
- **Then** it is **clean** (non-destructive on shipped data), and the **four shipped migrations stay
  byte-frozen**,
- **And** `mix ecto.drop/create/migrate` is clean on the (partitioned) test DB.

## S11 — The ≥100 determinism loop (multi-mint per settlement)

*As the Operator, I want the settlement path — which mints multiple branded ids per call — proven stable under
repeated runs, so that the same-millisecond mint hazard never forks a row or double-fulfils.*

**Exercises:** the determinism loop (A11); the multi-mint contention (`OTX` + the `TXN` mint + the `RVL`
revenue per `settle_payment/1` — the cm.4/cm.6 same-ms branded-id hazard). **Surface:** the loop over the
order-flow story suite.

- **Given** `settle_payment/1` minting **multiple** ids per call (the `OTX` receipt, the `TXN` credit row, and
  the `RVL` revenue row)
- **When** the full suite runs `≥100` iterations (reinit-per-iter — `for i in $(seq 1 150); do TMPDIR=/tmp mix
  test --include valkey || break; done`)
- **Then** it is **green throughout** — no forked row, no mis-count, no double-fulfilment,
- **And** the determinism-posture statement **names** the multi-mint contention as the loop's target.

## S12 — The withdrawal seam is designed-for, not built (cm.8 forward)

*As cm.8 (the cash-out rung), I want cm.7's shapes to extend cleanly to a house withdrawal debit, so that
cash-out plugs into the same ledger and rate-pin with no reshape.*

**Exercises:** the forward withdrawal seam (`D-2`); the shape-stability for cm.8. **Surface:** the spec body
§13 + the cm.6 [§ Forward](./cm.6.md) note — a **named** seam, **no code** this rung.

- **Given** cm.7's order/rate-pin/minor-unit shapes
- **When** the cm.8 withdrawal model is considered
- **Then** a cash-out is a **negative `delta`** house row in the **rail currency** through the **same**
  `Wallet.house_post/5` (`account="payout"`/`"withdrawal"`, `reason="cash_out"`) — no new ledger verb, the
  house's negative swing admitted by cm.6's no-CHECK ledger (`D-1`),
- **And** the floating diamonds→rail rate is **pinned on the withdrawal record** (the same rate-pin discipline
  as the order, F3) — the shape extends with **no reshape**,
- **And** cm.7 **builds none of this** (no KYC/AML, no hold, no `rates` table) — the seam is named on record so
  the target shape is fixed (`D-2`).

---

## Coverage (every body Deliverable → its story → its invariant)

| Deliverable (cm.7.md) | Story | Invariant / ruling |
|---|---|---|
| The `PKG` packages catalog (DB-stored, editable) — Venus-Postgres | S8 | A8; `D-6` F2 |
| The `ORD`/`OTX` order model (one `orders` table + a `rail` discriminator); `WHK` folds into `OTX` — Venus-Postgres | S1, S2, S7 | A1, A2; `D-6` F4-split, `D-5` |
| The `OTX` partial unique index `(rail, external_id)` — the exactly-once gate | S1 | **A1 (the headline)**, INV-EXACTLY-ONCE-PER-RAIL |
| The frozen `Codemojex.Rails` (per-rail facts + the boot vector) | S5 | A5; `D-6` F1/F5 |
| The pure `Codemojex.KeyShop` pricing module | S5 | A5; `D-6` F2/F5 |
| The Stars rail end-to-end (the Telegram XTR invoice flow + `settle_payment/1`) | S2, S3, S7 | A2, A3, A7; `D-5` |
| The fulfilment primitive `settle_payment/1` (OTX-gated mint + gross booking) | S1, S2, S3 | A1, A2, A3, INV-ATOMIC-PURCHASE |
| Gross revenue booked to the same `revenue_ledger` (native minor unit) | S3 | A3; cm.6 S11; `D-6` F5, INV-GROSS-BOOKED |
| **Purchase revenue SEEN by `house_balance` (`account="platform"`)** | **S3b** | **A8b, INV-VISIBLE-REVENUE (`D-3`)** |
| The rate snapshot + provenance — pinned on the order | S4 | A4; `D-4`, INV-PRICE-PINNED |
| The cutover (client-supplied key-count/ref retired) | S6 | A6; the named hazard |
| The shaped rails (TON/USDT/RUB — shapes rail-stable) | S3, S12 | A3; `D-5` |
| The migration + fresh reinit | S10 | A10 |
| cm.6 byte-frozen + the existing suites green | S9 | A9; `D-1` |
| The ≥100 determinism loop (multi-mint per `settle_payment`) | S11 | A11; the same-ms mint hazard |
| The withdrawal seam designed-for (cm.8) | S12 | `D-2` (forward) |
| Apollo BUILD-GRADE (money-critical) | (all) | A12 |
