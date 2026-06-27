# cm.7 — The KeyShop (multi-rail pay-in: Stars · TON · USDT · RUB → keys)

> The rung body — **authoritative**. The `.stories.md` (acceptance) and `.llms.md` (the agent brief) derive
> from this file; when a derived artifact disagrees, this body wins. The **relational** half (the `packages`
> catalog · the `orders` / `order_transactions` tables · the partial-unique exactly-once index · the migration
> + the reinit · the `webhooks` forward table) is owned by **Venus-Postgres** —
> [`cm.7.postgres.design.md`](./cm.7.postgres.design.md) is the build-grade column contract this body
> coordinates with (the column names, the table split, the minor-unit table, the `settle_payment/1` primitive).
>
> **RULED — the design phase is CLOSED; this triad is the build-grade ruled brief for Mars.** The dual-architect
> blind pass converged on the build contract; the Operator ruled the two divergences. The locked rulings are
> `cm-7` ledger `D-1`..`D-6` (see [§ Rulings](#rulings-cm-7-d-1d-6-locked) — authoritative for the build) and the
> Director synthesis [`cm.7.design.consolidation.md`](./cm.7.design.consolidation.md) (the argued background).
> The build runs via `/codemojex-ship cm.7` (an L2 Squad — money + a new schema + an external-wire/exactly-once
> surface → **Apollo mandatory**). The acceptance face is [`cm.7.stories.md`](./cm.7.stories.md); the compact
> brief is [`cm.7.llms.md`](./cm.7.llms.md).
>
> **The contract it extends.** cm.7 is the **KeyShop** cm.6 forward-referenced (cm.6.md Scope-Out · `cm-6`
> `D-5` · S11) and the roadmap's **Commerce** system (`codemojex.roadmap.md` §Commerce + §branded-namespaces).
> It books purchase revenue into the **same `revenue_ledger`** cm.6 founded — there is **no second revenue
> store**. cm.6 stays **byte-frozen** (`D-1`); its [§ Forward: the multi-currency ledger](./cm.6.md) note is the
> seam this rung plugs into. **The booking convention is `account="platform"`, `reason="purchase"`,
> `currency=`the rail (`D-3`)** — so the shipped `house_balance/0..1` (`WHERE account="platform"`) sees the
> purchase revenue.
>
> Framing law (propagates to every prompt derived from this body): third person for any agent reference; no
> first-person-agent narration; no perceptual / interior-state verbs (sees / notices / feels).

## 1. The rung in one paragraph

Replace the one weak commerce surface with a real shop. Today a player "buys keys" through
`CodemojexWeb.GameController.buy_keys/2` (`game_controller.ex:44`), which calls
`Codemojex.purchase_keys(player, keys, params["ref"] || "stars")` → `Wallet.purchase_keys/3`
(`wallet.ex:147`) = `credit(player, :keys, keys, "purchase", ref)` — a client supplies the key count **and**
the payment `ref` (defaulting to the literal `"stars"`), with **no** invoice, **no** payment capture, **no**
exactly-once guard (`credit/5`, `wallet.ex:383`, has none — unlike the `buy_in` `(player, ref)` partial index),
and **no** revenue booked. A replayed request **mints keys again**. cm.7 makes a purchase a real,
exactly-once, revenue-recognized event across **four rails** — Telegram **Stars** (XTR, the built rail) plus
**TON / USDT / RUB** (the shaped rails). A player picks a **package** (`PKG`, a DB-stored bundle so the shop
edits without a deploy); an **order** (`ORD`) is created with the package, the rail, the **amount pinned in
that rail's minor unit**, and the **rate snapshotted** at creation; the platform receives the **gross rail
amount** (the player's funds settle on Telegram's / the chain's / the processor's books — **external**); the
rail's payment is recorded **exactly-once** as an **order transaction** (`OTX`, keyed `UNIQUE(rail,
external_id)` on the rail's charge id / tx hash / processor ref); on confirmation the order's keys are
**minted to the wallet** (a `TXN` credit) and the **gross is booked to the `revenue_ledger`**
(`account="platform", reason="purchase"`, `currency=`the rail) — both inside one `Repo.transaction`, gated on the `OTX`
uniqueness so a replay is a no-op. The pure **`Codemojex.KeyShop`** module is the price/net-revenue/store-fee/
rate math (the [`economy/economy.packages.md`](./economy/economy.packages.md) model). After cm.7 the
client-supplied key count and payment ref are **gone** — the smallest change that makes "mint keys without a
captured, exactly-once, revenue-booked payment" **unrepresentable**.

## 2. The product frame (what a purchase IS)

A purchase is a **revenue-recognition + currency-exchange event**, not a balance write:

- The player's **rail funds are EXTERNAL** — they settle on Telegram's (Stars), the TON chain's, or the fiat
  processor's books. codemojex never holds the player's stars/TON/RUB; it observes that the gross **arrived**.
- The platform receives the **GROSS rail amount** and **MINTS N keys** to the player's wallet (a `TXN` credit
  — the product the player bought).
- The **gross is booked to the `revenue_ledger`** as house income (`account="platform", reason="purchase"`, `currency=`the rail,
  `delta=+gross_minor`) — the same ledger, the same `Wallet.house_post/5` primitive cm.6 founded.
- The **exactly-once key (per rail)** prevents the double-mint-on-replay the current `"stars"`-literal path
  invites: every rail has exactly one external charge identifier (the Telegram charge id · the on-chain tx
  hash · the processor settlement id), and `UNIQUE(rail, external_id)` on `OTX` is the authority — the cm.5
  `buy_in` exactly-once pattern (a partial unique index = the exactly-once gate) applied to purchases.

**Three rows, three concerns, one event** (the reconcile of `codemojex.roadmap.md` §Commerce L272 "OTX kept
separate from the currency ledger TXN" **with** cm.6 `D-5` "book revenue to the same RVL ledger" — no
contradiction, three different rows about the same purchase):

| Row | Table | Concern | The exactly-once anchor |
|---|---|---|---|
| `OTX` | `order_transactions` | the **external payment receipt** (the rail's charge) | `UNIQUE(rail, external_id)` — **the gate** |
| `TXN` | `transactions` (as-built) | the player's **wallet credit** (N keys minted) | rides the OTX gate (minted once per OTX) |
| `RVL` | `revenue_ledger` (cm.6) | the platform's **revenue recognition** (gross booked) | rides the OTX gate (booked once per OTX) |

## 3. Ground truth (re-probed on disk — cite methods, not just lines)

| Surface | As-built (verdict) | cm.7 |
|---|---|---|
| The weak buy path | `GameController.buy_keys/2` (`game_controller.ex:44`) reads `params["keys"]` + `params["ref"] \|\| "stars"`; calls `Codemojex.purchase_keys/3` (MATCH) | replace with the order flow; the client never supplies the key count or the ref |
| The mint | `Wallet.purchase_keys/3` (`wallet.ex:147`) = `credit(player, :keys, keys, "purchase", ref)`; `credit/5` (`wallet.ex:383`) has **no** exactly-once guard (MATCH — the double-mint hazard) | mint keys **gated on the `OTX` uniqueness**, inside the fulfilment transaction |
| The facade | `Codemojex.purchase_keys/3` (`game.ex:212`, `defdelegate … to: Wallet`) (MATCH) | a new `Codemojex.KeyShop`-facing facade (catalog · create order · fulfil); `purchase_keys` is retired or made internal |
| The house ledger | `Wallet.house_post/5` (`wallet.ex:482`) inserts one signed `RVL` row; `book_house/5` (`wallet.ex:313`) the public verb; `house_balance/0..1` (`wallet.ex:325`) = `SUM(delta) GROUP BY currency` defaulting `WHERE account="platform"` (`@house`, `wallet.ex:22`) (MATCH) | book the gross via `house_post` with `account="platform"`, `reason="purchase"`, `currency=`the rail (`D-3`) — so `house_balance/0..1` (which filters `WHERE account="platform"`) **SEES** the purchase rows; booking `account="purchase"` would make them **invisible** to the one reconciliation read (the `D-3` correctness fix); **no new ledger verb**; `house_balance` returns the new currency buckets with **no read change** |
| The revenue schema | `schemas/revenue_ledger.ex` (cm.6, uncommitted): `{id RVL, account, currency, delta :integer→bigint signed, reason, ref, inserted_at}`, no CHECK, no exactly-once index (MATCH) | **byte-frozen** (cm.6 `D-1`); cm.7 books `currency` ∈ {stars,ton,usdt,rub} rows, `account="platform", reason="purchase"` |
| The economy math | `Economy` (`economy.ex`): `@diamonds_per_key 10` (`:10`), `@cents_per_diamond 1.2` (`:11`); `diamonds_for_keys`/`to_cents`/`to_usd` (`:19`/`:22`/`:25`) — pure, read-time conversions (MATCH) | `KeyShop` is the **purchase** pricing module **beside** `Economy` (the in-game math) — net-revenue / store-fee / rail-rate; it does **not** edit `Economy` |
| Packages | **none** — no `packages` table, no catalog (MATCH) | a new `PKG` `packages` catalog (DB-stored, editable without a deploy) — Venus-Postgres |
| Invoice flow | **none** — no `pre_checkout_query` / `successful_payment` handler; the Telegram controller is the webhook in (`CodemojexWeb.TelegramController`, cm.4 / the bot wiring) (MATCH) | the Telegram **XTR invoice** flow (invoice → `pre_checkout` → `successful_payment`) for the Stars rail |
| Orders / payments | **none** — no `orders` / `order_transactions` / `webhooks` table (MATCH) | `ORD` / `OTX` / `WHK` — Venus-Postgres |
| Brands | namespaces taken (`codemojex.design.md`): CMD/EMS/GAM/GES/JOB/NOT/PLR/ROM/SES/TXN/RVL; **PKG/ORD/OTX/WHK are free** (the roadmap catalog, `codemojex.roadmap.md:61-64`); `generate!/1` accepts any valid 3-letter ns (MATCH) | mint `EchoData.BrandedId.generate!("PKG"/"ORD"/"OTX"/"WHK")` — the brand IS the type |
| The rate input | **none** — no rate surface; `economy.packages.md` proposes a configurable `stars_usd_rate` + a live TON rate (MATCH) | a **config** rate map (runtime.exs), **snapshotted on each order** (F3 — the launch source; the `rates` table is cm.8) |
| JSON | `:jason` declared in codemojex's own `mix.exs` `deps/0` (cm.4 `mix.exs:58`, MATCH) | the OTX `raw_payload` codec; **zero new dep** |
| Tests | the `Codemojex.Story` suites (`@moduletag :valkey`) drive the facade; the cm.4 auth suite drives the web layer (MATCH) | add KeyShop pricing unit tests (pure) + an order-flow story suite + an invoice/webhook controller test |

## 4. The two pure modules — `Codemojex.Rails` (frozen facts) + `Codemojex.KeyShop` (pricing) — NO Repo, NO HTTP

`D-6` (F1/F5) splits the pure surface in two, both `lib/codemojex/` (no DB), **beside** `Economy` (the in-game
currency math, **untouched**):

### 4a. `Codemojex.Rails` — the frozen per-rail facts (`lib/codemojex/rails.ex`, NEW)

The closed set of four rails as **frozen module data** — the minor unit, the factor, the decimals, the
store-fee surface — `D-6` F1: a bare `rail` STRING is the discriminator (the brand-is-the-type discipline
applied to currency), the per-rail facts live HERE, **never** a mutable `decimals` column (a money-scaling
constant an admin could fat-finger silently mis-scales every nanoTON — VenusPG's load-bearing point). A **boot
vector** asserts the table at start (the `EchoData.BrandedId.self_check!` pattern), so a typo in a factor fails
fast, not at the first mis-booked order:

```
# The minor-unit convention (F5/D-6 — every rail's amount stored in its NATIVE smallest unit, integer-exact).
@rails %{
  "stars" => %{minor: :star,       factor: 1,             decimals: 0},
  "ton"   => %{minor: :nano_ton,   factor: 1_000_000_000, decimals: 9},
  "usdt"  => %{minor: :micro_usdt, factor: 1_000_000,     decimals: 6},
  "rub"   => %{minor: :kopeck,     factor: 100,           decimals: 2}
}
@rail_names ~w(stars ton usdt rub)

@spec rails() :: [binary()]                                # the closed set — the CHECK + the changeset inclusion source
@spec factor(rail :: binary()) :: pos_integer()            # major→minor (e.g. 1_000_000_000 for ton)
@spec decimals(rail :: binary()) :: non_neg_integer()
@spec self_check!() :: :ok                                 # the boot vector: assert each rail's factor == 10**decimals
```

### 4b. `Codemojex.KeyShop` — the pricing math (`lib/codemojex/key_shop.ex`, NEW; also the order/settle I/O, §5/§7)

The price / net-revenue / store-fee math, pure over a package + a rail + a rate (the
[`economy.packages.md`](./economy/economy.packages.md) model made code). The pinned-on-the-order price reads
through it ONCE at order creation:

```
# The rail price for a package, in that rail's minor unit (via Codemojex.Rails), from the base (Stars) ladder
# + a rate. Stars: the package's stars_price verbatim (the canonical face — no rate). TON/USDT/RUB: DERIVED
# from the USD face via the rate, scaled to the rail's minor unit — UNLESS the package pins a per-rail override
# (ton_price_minor / usdt_price_minor / rub_price_minor, §5).
@spec price_minor(package :: map(), rail :: binary(), rates :: map()) :: {:ok, pos_integer()} | {:error, term()}

# Net developer revenue for a Stars sale, by surface (economy.packages.md — ~32% mobile / ~3% desktop fee).
@spec net_revenue(stars :: pos_integer(), surface :: :mobile | :desktop, rates :: map()) :: %{usd_cents: integer()}

# A package's USD face from its Stars price + the stars_usd rate (the economy.packages.md $0.013 default, live-tunable).
@spec usd_face_cents(package :: map(), rates :: map()) :: integer()
```

- **The discounts live ONCE** — in the base (Stars) ladder on the `packages` row (the stars/keys ratio,
  `economy.packages.md`: 5=99⭐ … 1000=9999⭐, 0..50%; `D-6` F2). The rails compute **off** that base; they do
  not each carry a discount.
- **The store-fee math is real** (`economy.packages.md`): a Stars sale nets ~**68%** on mobile (Apple/Google
  ~32%) vs ~**97%** on desktop; `net_revenue/3` returns both so the operator reads true take-home. The store
  fee is a **revenue-reporting** figure, **NOT** a booked deduction — the `revenue_ledger` books the **gross**
  (what Telegram credits, `INV-GROSS-BOOKED`); the net is a read-time view (the cm.6 `D-2` store-exact /
  convert-at-read discipline, applied to rails).
- **The rate is an INPUT, used once** — `price_minor/3` reads the `rates` map at order creation and the result
  is **pinned** on the order (`price_minor` + the rate snapshot `rate_minor`/`rate_pair`/**`rate_source`**/
  **`rate_quoted_at`**, §6a / `D-4`); the live rate is **never** read again for that order (the audit pin,
  `D-6` F3).
- **Purity** — every `Rails`/`KeyShop` pricing function is pure over its inputs; no `Repo`, no clock, no HTTP.
  The same inputs always yield the same price (the `Economy` discipline, `economy.ex:6`). The order/settle I/O
  (§5, §7) is the impure half of `KeyShop`, in its own functions.

## 5. The catalog — `PKG` packages (DB-stored, editable without a deploy)

A new `packages` table (Venus-Postgres, [`cm.7.postgres.design.md`](./cm.7.postgres.design.md) §2.1) so the
operator edits the shop without a deploy (cm.6 Scope-Out's "DB-stored" requirement). A **versionable template**
— editing it changes **future** orders only (the order pins its own price, `D-6` F2), so `packages` carries
`updated_at` while the ledger/receipt tables do not. The **column contract** (Venus-Postgres's):

- `id` (`PKG`-branded), `keys` (the bundle size), `stars_price` (the canonical base price, integer XTR),
  `discount_pct` (the display discount `0..100`, `economy.packages.md`), `enabled` (the runtime on/off — `D-6`
  F1's "enable is a flag, not a rails table"; a disabled package is not orderable, booked orders unaffected),
  `sort` (display order), and **optional nullable per-rail minor-unit price overrides** (`ton_price_minor` /
  `usdt_price_minor` / `rub_price_minor`) for rails an operator pins to a round number (`D-6` F2) — `NULL` ⇒
  derive from the base via the rate.
- The seven launch bundles are the `economy.packages.md` ladder (5/15/50/100/200/500/1000 keys), seeded by the
  migration. The catalog read is a public facade fn (`Codemojex.key_packages/0` → `enabled` packages, sorted).

## 6. The order flow — `ORD` / `OTX` (one orders table + a rail discriminator); `WHK` folds into `OTX` for launch

`D-6` F4-split — the rail-independent lifecycle is one `orders` table with a `rail` discriminator; the
rail-specific bytes are a single `OTX` row. **`WHK` folds into the `OTX` `(rail, external_id)` partial-unique
index for the Stars launch (`D-5`)** — Telegram's `successful_payment` IS the confirmation, a replay no-ops via
the suppressed duplicate `OTX` insert; a dedicated `webhooks` table is the **named forward** for the first
push-webhook rail (on-chain TON, whose confirmations arrive decoupled from an order). The **column contracts**
are Venus-Postgres's ([`cm.7.postgres.design.md`](./cm.7.postgres.design.md) §2.2/§2.3); the load-bearing shape:

### 6a. `orders` (`ORD`) — the rail-independent lifecycle + the pinned money

`{id (ORD), player (PLR), package_id (PKG, nullable), rail, keys, currency, price_minor (the pinned gross, the
rail's minor unit), rate_minor, rate_pair, rate_source, rate_quoted_at, status, inserted_at, updated_at}`. The
**status machine** (Venus-Postgres §2.3, CHECK-pinned): `created → paid`, with `failed` / `refunded` terminal
(`paid` is the terminal happy state — the OTX confirmed, keys minted, revenue booked). The **price + the rate
are PINNED at creation** (`D-6` F2/F3): `price_minor` in the rail's native minor unit (`D-6` F5), and — `D-4` —
the rate snapshot `rate_minor`/`rate_pair`/**`rate_source`** (`"config"` at launch, or a provider name)/
**`rate_quoted_at`**, so every booked order **self-describes its rate's origin** and is reproducible regardless
of later rate moves (the cm.8 rates table drops in without reshaping the order). The order `id` is the **`ref`**
on the keys-mint `transactions` row AND the `revenue_ledger` row (the per-order reconciliation key, replacing
the weak `"stars"` literal). Stars needs no rate (the base price IS Stars) — its `rate_*` are `nil`.

### 6b. `order_transactions` (`OTX`) — the external receipt + the exactly-once gate (the conservation point)

`{id (OTX), order_id (ORD), rail, external_id (nullable), amount_minor, status, raw_payload (jsonb — the
verbatim provider receipt), inserted_at}` (append-only). The exactly-once authority is a **partial unique index
`(rail, external_id) WHERE external_id IS NOT NULL`** (Venus-Postgres §3) — the exact shipped
`transactions_buy_in_once_index` pattern (`golden_rooms.exs:73-76`), the named fix for today's `"stars"`-literal
double-mint. `external_id` is the rail's external charge identifier (the Telegram `telegram_payment_charge_id` ·
the TON `tx_hash` · the processor settlement id) and is **nullable** because it does not exist until the
provider confirms — the **partial** index excludes the unconfirmed. A replayed payment hits the index, the OTX
insert **suppresses** (Pattern A, `on_conflict: :nothing` + the count-rose check), and the fulfilment **mints
nothing / books nothing** (§7). The rail-VARYING audit fields (a TON `from_address` / `confirmations`, a fiat
settlement ref) live in `raw_payload` verbatim — a stronger audit trail than hand-picked columns (nothing
dropped).

### 6c. `webhooks` (`WHK`) — folds into `OTX` for the Stars launch; a named forward table (`D-5`)

For the **Stars launch, WHK is NOT a table** — the `OTX` `(rail, external_id)` partial-unique index carries the
idempotency, and Telegram's `successful_payment` is itself the confirmation, so a redelivered update no-ops via
the suppressed `OTX` insert (`D-5`). A dedicated `webhooks` table — `{id (WHK), rail, event_id, order_id,
processed_at}`, `UNIQUE(rail, event_id)` (Venus-Postgres §2.4, shaped) — is the **named forward** for the first
**push-webhook** rail (on-chain TON, whose confirmations arrive decoupled from any order, so a separate
ingress-dedup record is load-bearing there). The Stars launch dedups the *payment* at OTX; the forward WHK
dedups the *delivery* at ingress (defense in depth, for the async rails). *(Director note: if the Operator
later wants ingress dedup from day one, WHK-as-a-table is a clean ~4-column Option-A+ add — Venus-Postgres §2.4
is already build-grade for it.)*

## 7. The Stars rail — the Telegram XTR invoice flow + `settle_payment/1` (the BUILT rail)

cm.7 **builds the Stars rail end to end** (the closest-to-shipped, no external chain/processor) and **shapes**
the ORD/OTX rows for the other three (`D-5`). The Telegram XTR flow (pinned against the live Bot Payments docs
at build, not memory — the cm.4 `InitData` discipline):

1. **Invoice** — `Codemojex.KeyShop.create_order(player, package_id, "stars")` creates the `ORD` (`created`),
   pins `keys` / `price_minor` from the package via `KeyShop.price_minor` (Stars = the package `stars_price`,
   no rate), and returns an invoice link / a `sendInvoice` payload (currency `XTR`, the `ORD` id as the invoice
   `payload`). NO keys minted yet.
2. **`pre_checkout_query`** — the bot answers `answerPreCheckoutQuery` `ok: true` after re-validating the `ORD`
   is `created` and the amount matches the pinned `price_minor` (a tamper check); a mismatch / a non-`created`
   order → `ok: false`. Handled in `CodemojexWeb.TelegramController` (the as-built webhook in) — **fail-closed**.
3. **`successful_payment`** — on the update, call `KeyShop.settle_payment/1` (the fulfillment primitive,
   Venus-Postgres §5) with `external_id = successful_payment.telegram_payment_charge_id` and `amount_minor =
   total_amount`. It runs **one `Repo.transaction`** under a `FOR UPDATE` order lock: insert the `OTX`
   (`rail="stars"`, gated on the `(rail, external_id)` partial-unique index, **Pattern A**); **IF it wrote**
   → (a) **mint the keys** (`Wallet.credit_purchase(order.player, order.keys, order_id)` — the `transactions`
   credit, `ref =` the ORD id), (b) **book the gross** (`Wallet.house_post(Wallet.house_account(),
   order.currency, amount_minor, "purchase", order_id)` — `account="platform"`, `D-3`), (c) flip `ORD → paid`;
   **ELSE** (a replay — the OTX suppressed) mutate **NOTHING**. Returns `{:ok, :fulfilled}` |
   `{:ok, :already_fulfilled}` | `{:error, reason}`.

> **The amount is the Telegram-reported `total_amount`** (the gross XTR Telegram credits the developer) — the
> `revenue_ledger` books **what arrived**, not a computed expectation; `pre_checkout` already rejected a
> mismatch. The mint + the booking are **GATED on the OTX insert** (the conservation point) — a replay mints
> once, books once.

## 8. The other three rails — TON / USDT / RUB (SHAPED, not built — `D-5`)

The ORD/OTX/PKG shapes are **rail-stable**; each non-Stars rail lands as its own **forward increment** when its
**webhook verifier + external-id source** ships, calling the **same** `settle_payment/1` with **no order/ledger
reshape**:

- **TON** — `external_id` = the on-chain `tx_hash`; the inbound event is a chain watcher / a TON Connect
  callback; the gross is in **nanoTON** (F5); the price derives from the USD face via the snapshotted
  `ton_usd` rate (Telegram fixes 200⭐ = 1 TON, but TON→USD floats — pin the rate). The verifier confirms the
  tx + the amount + the destination before fulfilment.
- **USDT** — `external_id` = the settlement / tx id; gross in **micro-USDT** (F5); ~1 USD (a stablecoin, but
  still rate-pinned for honesty).
- **RUB** — `external_id` = the processor settlement id; gross in **kopeck** (F5); a per-package RUB override
  (F2) is the likely operator choice (a round-rouble price), else rate-derived.

Each rail's `house_post(Wallet.house_account(), order.currency, amount_minor, "purchase", order_id)` books into
the **same** `revenue_ledger` (`account="platform"`, `D-3`); `house_balance` returns the new currency bucket
with **no read change**. cm.7 ships the Stars rail end-to-end (`D-5`); the other three are schema-shaped
forward increments — the build-order below is Stars-first so the rung is shippable at the Stars boundary.

## 9. The cutover map (method level — every trust point → its replacement)

| Surface | As-built | cm.7 |
|---|---|---|
| `POST /api/keys/buy` (`GameController.buy_keys/2`, `game_controller.ex:44`) | trusts `params["keys"]` + `params["ref"] \|\| "stars"` (MATCH) | **retired** for the order flow — keys are minted only via a settled order; the route is removed or repurposed to **create an order** (`{package_id, rail}` → an invoice / a pay link), never a direct key count |
| `Codemojex.purchase_keys/3` (`game.ex:212`) | `defdelegate … to: Wallet` (MATCH) | retired, or `purchase_keys/3` rebound so its `ref` is always the ORD id and routed through `KeyShop` (Venus-Postgres §5 F-2 — Mars chooses (a) rebind vs (b) a new `Wallet.credit_purchase/3`); never a public client surface |
| `Wallet.purchase_keys/3` (`wallet.ex:147`) | `credit(:keys, "purchase", ref)`, no exactly-once (MATCH) | the mint moves **inside** `settle_payment/1`'s transaction, gated on the `OTX` `(rail, external_id)` partial-unique index (the named double-mint fix); `ref` = the `ORD` id, never `"stars"` |
| The Telegram webhook | `CodemojexWeb.TelegramController` (the as-built in) (MATCH) | + `pre_checkout_query` (tamper guard) + `successful_payment` → `settle_payment/1` (fail-closed; idempotent via the `OTX` gate — WHK folds in for the Stars launch, `D-5`) |

## 10. Acceptance (the runnable gate — every invariant a check; a no-op must not satisfy its letter)

Run from `echo/apps/codemojex`, `TMPDIR=/tmp`, Valkey on `6390` + Postgres up.

| # | Invariant | The check (positive proof) |
|---|---|---|
| A1 | **Exactly-once mint per rail (THE headline — the double-mint fix).** A replayed payment (same `rail` + `external_id`) mints keys **once** and books revenue **once** | a story: fulfil an order; re-deliver the **same** `successful_payment` (same charge id); assert `players.keys` rose **once**, **one** `TXN` purchase credit, **one** `RVL` purchase row — the second fulfilment is a no-op (the `OTX` `UNIQUE`). A **mutation:** removing the `UNIQUE(rail, external_id)` (or the `on_conflict` guard) MUST make A1 fail (the net-zero spot-check). |
| A2 | **The three rows, one transaction, all-or-nothing.** On a fulfilled payment: the `OTX` receipt **AND** the `TXN` key credit **AND** the `RVL` gross booking are all present or all absent | a story: a successful payment → all three rows present, `players.keys` += the package keys, `revenue_ledger` += the gross; a forced rollback mid-fulfilment → **none** of the three, no key minted (one `Repo.transaction`). |
| A3 | **Revenue is booked GROSS in the rail's minor unit, into the same ledger.** | a story: a Stars purchase of `total_amount` ⭐ → `revenue_ledger` holds `+total_amount` `currency="stars" account="platform", reason="purchase"`; `Wallet.house_balance()` returns `%{"keys" => …, "stars" => total_amount}` — the cm.6 read, **no change**, the new currency bucket present (the multi-currency seam exercised). A `currency="ton"` row sums into its own `nanoTON` bucket (a shaped-rail unit test). |
| A4 | **The amount + the rate are PINNED on the order at creation** (the audit reproducibility; `D-4`) | a story: create a TON order at config rate R; change the config rate to R'; the order's `price_minor` + `rate_minor` are **still** R-derived (the live rate is never re-read), and `rate_source="config"` + `rate_quoted_at` are recorded; the booked revenue equals the pinned figure. |
| A5 | **The pure `KeyShop` + `Rails` modules — priced + net-revenue + store-fee + the boot vector, fixture-tested.** | `KeyShop` unit tests (no DB): `price_minor(pkg, "stars", rates)` = the package `stars_price`; `price_minor(pkg, "ton", rates)` = the USD-face-derived nanoTON (within the rounding pin); `net_revenue(stars, :mobile, rates)` ≈ 68% and `:desktop` ≈ 97% of the USD face (`economy.packages.md`); a per-rail override is honored over the derived price. `Rails.self_check!()` asserts each rail's `factor == 10**decimals` (the boot vector). Purity: the same inputs → the same price (a property check). |
| A6 | **The client cannot supply the key count or the payment ref.** | a grep shows no `params["keys"]`/`params["ref"]` reaching a mint; the order-create route takes `{package_id, rail}` only; minting is reachable **only** from `settle_payment/1` (the OTX-gated fulfilment). The free-key gap is closed. |
| A7 | **The `pre_checkout` tamper guard.** | a `pre_checkout_query` whose amount ≠ the pinned `price_minor`, or whose `ORD` is not `created`, → `answerPreCheckoutQuery ok: false`; a matching one → `ok: true`. A present precondition runs it (a real handler call). |
| A8 | **The catalog is DB-stored + editable.** | `Codemojex.key_packages/0` returns the `enabled` packages, sorted; toggling `enabled=false` on a row removes it from the read with **no deploy** (a DB update + a re-read), and a booked order is unaffected (the pin-on-order rule). |
| A8b | **INV-VISIBLE-REVENUE — purchase revenue is SEEN by the reconciliation read (`D-3`).** | a story: after a Stars purchase, `Wallet.house_balance()` (the default `WHERE account="platform"`) **includes** the `"stars"` purchase revenue. A **mutation:** booking the purchase as `account="purchase"` MUST make this story fail (it would hide the revenue from the one read — the `D-3` correctness fix proven). |
| A9 | **cm.6 is byte-frozen; the existing suites stay green.** | `git diff --stat` over `revenue_ledger.ex`, the cm.6 migration, the cm.6 booking sites in `wallet.ex`/`rooms.ex` is **empty**; `mix test --include valkey` green incl. the cm.4/cm.5/cm.6 suites + the new KeyShop suite. |
| A10 | **The migration up/down + fresh reinit clean.** | Venus-Postgres: the one additive migration creating `packages` · `order_transactions` · `orders` (+ the `webhooks` forward table, `D-5`) `up`/`down` clean (the FK-order drop) from a fresh `codemojex_test` reinit (the DB name read from `config/test.exs`, surfaced before the drop); the **four shipped migrations byte-frozen**. The first real FKs in the schema (`references type: :string` — the branded-PK gotcha). |
| A11 | **The ≥100 determinism loop** (`settle_payment/1` mints **multiple** ids per call — `OTX` + the `TXN` mint + the `RVL` revenue — the same-ms branded-id mint hazard) | `for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey \|\| break; done` green throughout; the posture statement names the multi-mint contention. |
| A12 | **Apollo BUILD-GRADE** (money-critical) | the §11.2 charter — the exactly-once + the three-row-atomicity table at `file:line`, ≥1 un-prompted finding, ≥1 attack-that-held (a replay / a tamper / a partial-fulfilment), a mutation kill-rate. |

Gate ladder (per-app, from the app dir): re-probe `asdf current` / `.tool-versions` · `valkey-cli -p 6390
ping` → `PONG` · Postgres up · `TMPDIR=/tmp mix compile --warnings-as-errors` · `TMPDIR=/tmp mix test
--include valkey` · the migration up/down + reinit · the ≥100 loop.

## 11. Given / When / Then (the headline stories — the full set is [`cm.7.stories.md`](./cm.7.stories.md))

- **S-EXACTLY-ONCE — the double-mint fix (the headline).** *As Finance, I want a replayed payment to mint keys
  and book revenue exactly once, so that a redelivered webhook never duplicates keys or revenue.* **Given** a
  fulfilled order (rail `r`, `external_id e`), **When** the same payment (`r`, `e`) is delivered again,
  **Then** `players.keys` rose **once**, there is **one** `TXN` purchase credit and **one** `RVL` purchase row
  — the second fulfilment is a no-op under `UNIQUE(rail, external_id)`.
- **S-THREE-ROWS — atomic recognition.** *As the Operator, I want a purchase's receipt, key credit, and
  revenue booking to be all-or-nothing.* **Given** a confirmed payment, **When** fulfilment commits, **Then**
  the `OTX` **AND** the `TXN` key credit **AND** the `RVL` gross booking are all present (or, on a rollback,
  all absent) — one `Repo.transaction`.
- **S-GROSS-REVENUE — same ledger, native unit.** *As Finance, I want purchase revenue booked gross in the
  rail's minor unit into the same ledger as the Golden cuts.* **Given** a Stars purchase of `T` ⭐, **When**
  fulfilled, **Then** `revenue_ledger` holds `+T` (`currency="stars" account="platform", reason="purchase"`) and
  `house_balance()` returns the `"stars"` bucket beside `"keys"` — the cm.6 read unchanged.
- **S-PINNED-RATE — reproducible, self-describing booking.** *As Finance, I want the rail amount and the rate
  (with its provenance) pinned at order creation so booked revenue is reproducible and auditable.* **Given** a
  TON order at config rate R, **When** the config rate later changes, **Then** the order's
  `price_minor`/`rate_minor` stay R-derived, `rate_source="config"` + `rate_quoted_at` are recorded (`D-4`),
  and the booked revenue equals the pin.
- **S-PRICED — the pure shop.** *As a player, I want each package priced in my chosen rail.* **Given** a
  package and a rail, **When** `KeyShop.price_minor/3` runs, **Then** Stars = the base `stars_price`,
  TON/USDT/RUB = the USD-face-derived minor amount (or the per-rail override), and `net_revenue/3` reports the
  true mobile/desktop take-home (`economy.packages.md`).
- **S-NO-CLIENT-MINT — the gap closed.** *As the Operator, I want minting impossible without a captured
  payment.* **Given** the order flow, **When** a client posts a key count or a payment ref directly, **Then**
  no keys are minted — the create route takes `{package_id, rail}` only and the mint is reachable solely from
  OTX-gated fulfilment.
- **S-CATALOG — editable shop.** *As the Operator, I want to edit the shop without a deploy.* **Given** the
  `packages` table, **When** a row's `enabled`/price is updated, **Then** `Codemojex.key_packages/0` reflects it
  on the next read, no deploy; a booked order is unaffected (the pin-on-order rule).
- **S-CM6-FROZEN — additive only.** *As the Operator, I want cm.7 to add the pay-in rows without touching
  cm.6.* **Given** the byte-frozen `revenue_ledger` + its booking sites, **When** cm.7 books purchases,
  **Then** `git diff --stat` over the cm.6 code is empty and the cm.4/cm.5/cm.6 suites stay green.

## 12. Scope In

1. **The `PKG` packages catalog** (DB-stored, editable without a deploy — `enabled`/`sort`/the nullable per-rail
   overrides) + the catalog read facade `Codemojex.key_packages/0` — §5; Venus-Postgres owns the table.
2. **The `ORD`/`OTX` order model** (`D-6` F4-split: one `orders` table + a `rail` discriminator + the pinned
   money/rate; one `order_transactions` receipt; the **partial unique index `(rail, external_id) WHERE
   external_id IS NOT NULL`** the exactly-once gate). **`WHK` folds into the `OTX` gate for the Stars launch**
   (`D-5`); the `webhooks` table ships **shaped/forward** for the first push-webhook rail — §6; Venus-Postgres
   owns the tables.
3. **The two pure modules** — `Codemojex.Rails` (the frozen per-rail facts + the minor-unit table + the
   `self_check!` boot vector, `D-6` F1/F5) and `Codemojex.KeyShop` pricing (`price_minor` · `net_revenue` ·
   `usd_face_cents`; the discounts in the base ladder once) — §4.
4. **The Stars rail end-to-end** — the Telegram XTR invoice flow (invoice → `pre_checkout` (tamper guard) →
   `successful_payment` → `settle_payment/1`), exactly-once on the Telegram charge id — §7.
5. **The fulfilment primitive `Codemojex.KeyShop.settle_payment/1`** — one `Repo.transaction` under a `FOR
   UPDATE` order lock, gated on the `OTX` insert: insert `OTX`, **mint the keys** (`Wallet.credit_purchase` /
   rebound `purchase_keys`, `ref=ORD`), **book the gross** to the same `revenue_ledger` (`Wallet.house_post`,
   `account="platform", reason="purchase"`, `currency=`the rail, `D-3`), flip `ORD → paid` — §5, §7.
6. **The rate snapshot + provenance** (`D-4`) — a `key_shop_rates` config map (runtime.exs), read once at order
   creation and **pinned** on the `ORD` (`price_minor` + `rate_minor`/`rate_pair`/**`rate_source="config"`**/
   **`rate_quoted_at`**), so the order self-describes its rate's origin — §6a.
7. **The cutover** — retire the client-supplied key-count/ref path; minting only via `settle_payment/1` — §9.
8. **The shaped rails** — the ORD/OTX/PKG shapes proven rail-stable for TON/USDT/RUB (their verifier adapters
   are forward increments, `D-5`) — §8.
9. **The migration + the gate ladder + the stories** — §10.

## 13. Scope Out

- **Withdrawals / cash-out** (diamonds → TON/USDT/RUB) — **cm.8** (`cm-7` `D-2`); cm.7 designs-for the
  withdrawal seam (the negative-`delta` house debit, the rate-pin shape — cm.6's [§ Forward](./cm.6.md) note)
  but **builds none of it**. No KYC/AML, no 21-day hold, no `rates` table this rung.
- **A live `rates` table + a poller** — cm.8 (the cash-out rung needs live floating rates anyway); cm.7's rate
  source is **config**, pinned per order (F3). The pin shape is rates-table-ready (no reshape when the source
  upgrades).
- **A first-class `rails` registry table** — the frozen `Codemojex.Rails` module is the launch home for the
  four closed rails (`D-6` F1); a runtime rail-toggle table is a named cm.8+ forward.
- **The non-Stars rail VERIFIERS** (the TON chain watcher, the fiat processor integration) — shaped, not
  built; each lands as a forward increment with its rail's webhook verifier (§8, `D-5`). cm.7 ships the Stars
  rail.
- **The dedicated `webhooks` (WHK) table as the active idempotency layer** — it **folds into the `OTX` gate**
  for the Stars launch (`D-5`); the table ships shaped/forward for the first push-webhook rail (on-chain TON).
- **The BNK rake** (a cut of the prize pool), `RMP` membership, growth (`SHR`), analytics (`AEV`),
  LiveAdmin commerce dashboards — later rungs (the roadmap §feature-catalog).
- **Any cm.6-frozen surface** — `revenue_ledger.ex`, the cm.6 migration, the cm.6 booking sites in
  `wallet.ex`/`rooms.ex`, the conservation invariant — **untouched** (cm.6 `D-1`; A9).
- **In-game `Economy` math** — `economy.ex` is the per-guess/pool/conversion math; `KeyShop` is a **new**
  purchase module beside it. cm.7 does **not** edit `Economy`.

## 14. The rung (placement + risk)

- **cm.7 — the KeyShop** = the **Commerce** system (the roadmap §Commerce), a **sibling to cm.6** that plugs
  into the Arm-2 `revenue_ledger` with no re-design (`cm-6` `D-5`). Successor to cm.6; predecessor to **cm.8**
  (the cash-out / treasury rung — withdrawals diamonds → TON/USDT/RUB, the house debit, KYC/hold/rate-pinning).
- **Risk: HIGH** — real money (multi-rail pay-in) + a new schema surface (`PKG`/`ORD`/`OTX` + the `WHK`
  forward) + an exactly-once invariant + an external invoice/webhook flow → **L2 Squad, Apollo mandatory,
  Venus-Postgres** on the relational model, the **≥100 determinism loop** (multi-mint per `settle_payment`), the
  **migration up/down** + fresh reinit. A data-model + money rung.
- **Build via** `/codemojex-ship cm.7`. The build-time forks are **ruled** (the design phase is closed —
  `D-3`..`D-6`, see [§ Rulings](#rulings-cm-7-d-1d-6-locked)); this triad is the **build-grade ruled brief**.

---

## Rulings (cm-7 D-1..D-6, locked)

The dual-architect blind pass (the **product / flow / minimal-surface** lens, [`cm.7.md`](./cm.7.md) — Venus,
vs the **payments-integrity / relational / reconciliation** lens, [`cm.7.postgres.design.md`](./cm.7.postgres.design.md)
— Venus-Postgres, staged in [`cm.7.design.consolidation.md`](./cm.7.design.consolidation.md)) **converged on
four of the five forks + the rate pin-location + the booking correctness**; the Operator ruled the two
divergences. The build converges on these — it does **not** re-debate them. This section is authoritative for
the build.

- **`D-1` · cm.6 scope** — cm.6 ships **as-built, byte-frozen**; the broadened currencies are spec'd **forward**
  (the cm.6 [§ Forward](./cm.6.md) note). cm.7 books pay-in rows into the **same** `revenue_ledger` with **zero
  DDL**.
- **`D-2` · the pay-in / withdrawal split** — cm.7 = multi-rail **PAY-IN only**; cm.8 = withdrawals. cm.7
  **designs-for** the withdrawal seam (a negative-`delta` house debit, §13) but builds none of it.
- **`D-3` · the booking convention** (a payments-integrity correctness fix — VERIFIED, ratified) — purchase
  revenue books `account="platform"`, `reason="purchase"`, `currency=<rail>`, `ref=<ORD id>` — **NOT**
  `account="purchase"` (the shared brief's literal text). **Director-verified at source:** `house_balance/0..1`
  defaults to `WHERE account == "platform"` (`@house "platform"`, `wallet.ex:22`; `wallet.ex:325-328`), so
  `account="purchase"` would make **all** purchase revenue **invisible** to the one reconciliation read the
  ledger exists to answer. The movement-kind `"purchase"` lives in `reason` (free-text, zero DDL); the rail
  lives in `currency` (the multi-currency seam). *Chosen against* the brief's literal `account="purchase"` — the
  reconciliation defect the integrity lens exists to prevent.
- **`D-4` · F3 the rate SOURCE → config-launch + rate-provenance columns on the order** (Operator-ruled; the
  VenusPG synthesis over Venus's config-only V-3). The rate-at-purchase is **pinned on the order at creation**
  (the lens-independent convergence) AND the order carries `rate_source` (`"config"` | a provider) +
  `rate_quoted_at`, so every booked order **self-describes its rate's origin**. The launch source is a
  `key_shop_rates` config map (runtime.exs), read once at order creation, labeled `rate_source="config"`. The
  rates/quotes **history table is the cm.8 upgrade** — it drops in without reshaping the order. *Chosen against*
  config-only (no provenance — finance sees the pinned number but not its origin/quoted-time) and a rates table
  now (pulls cm.8's floating-rate machinery into a pay-in rung).
- **`D-5` · the cm.7 BUILD SCOPE → Stars end-to-end + TON/USDT/RUB schema-shaped** (Operator-ruled Option A; both
  architects' convergent recommendation). cm.7 BUILDS the multi-rail **foundation** (the `packages` catalog · the
  `ORD`/`OTX` order flow · the pure `KeyShop` pricing + `Codemojex.Rails` frozen module · the rate-pin per `D-4`
  · the per-rail exactly-once gate · the `house_post` purchase booking per `D-3`) + the Telegram **Stars rail
  END-TO-END** (the real invoice → `pre_checkout_query` → `successful_payment` flow). cm.7 **SHAPES** (does not
  build) the TON/USDT/RUB payment **adapters** — the ORD/OTX rows are rail-stable, so each non-Stars rail lands
  as its own forward increment when its verifier ships. **`WHK` folds into the `OTX` `(rail, external_id)`
  partial-unique index for the Stars launch** (Telegram's `successful_payment` IS the confirmation; a replay
  no-ops via the suppressed duplicate OTX insert); a dedicated `webhooks` table is the **named forward** for the
  first push-webhook rail (on-chain TON). *Chosen against* all four rails end-to-end now (three external-payment
  integrations + their verifiers in one HIGH-risk increment) and WHK-as-a-table-now (the VenusPG `V-9`
  defense-in-depth — available as an Option-A+ ~4-column variant if the Operator later wants ingress dedup from
  day one).
- **`D-6` · the convergence build contract** (F1 / F2 / F4-split / F5 / F3-pin — the two lenses converged; not a
  re-decided fork). The cm.7 triad + Mars bind to:
  - **F1 (rail)** = a bare `rail` **discriminator STRING** on the order/OTX/RVL rows (the brand-is-the-type
    discipline applied to currency) + the per-rail facts (minor unit, decimals, store-fee) as **FROZEN data in
    a pure `Codemojex.Rails` module**, asserted by a boot vector (the `self_check!` pattern). **NO `rails`
    table; NO mutable `decimals` column** (a money-scaling hazard — an admin could fat-finger it).
  - **F2 (pricing)** = one **base Stars price** on the package (the discounts live once in the base) + a
    rate-derived per-rail amount **PINNED + frozen on the order** at creation (the package is a TEMPLATE; the
    order holds the authoritative money — editing a package never rewrites a booked order) + a **nullable
    per-rail override** column (round-number rails, also pinned-on-order).
  - **F4-split** = **ONE `orders` (ORD)** table (the rail-independent lifecycle + the pinned money/rate) +
    **ONE `order_transactions` (OTX)** table (the external receipt `{rail, external_id, amount_minor,
    raw_payload jsonb, status}`). Exactly-once = a **PARTIAL UNIQUE INDEX `(rail, external_id) WHERE external_id
    IS NOT NULL`** — the shipped `transactions_buy_in_once_index` pattern (`golden_rooms.exs:73-76`), Pattern A
    insert (`on_conflict: :nothing` + the count-rose check). A purchase confirmation = **THREE rows in ONE
    `Repo.transaction`** (the OTX receipt + the `TXN` keys mint `ref=ORD` + the `RVL` revenue), the
    mint+booking **GATED on the OTX insert** (the conservation point). The first real FKs in the schema
    (`references type: :string` — the branded-PK gotcha).
  - **F5 (minor-unit)** = each currency stored in its **NATIVE minor unit, integer-exact**, in the `:bigint`
    `delta` (stars=1, ton=nanoTON 1e9, usdt=micro-USDT 1e6, rub=kopeck 100; keys/cents internal).
    **Store-exact-convert-at-READ** (the cm.6 `D-2` discipline extended); **NO per-row decimals column; NO
    normalize-at-write**. The convention is a spec table (§4a) + the frozen `Rails` module.
  - **F3 pin-location** = the rate pinned **ON THE ORDER ROW** at creation (with `D-4`'s source/provenance
    columns).

> **The do-nothing baseline** (rejected): leave cm.7 the roadmap stub (Stars-only, the current
> `purchase_keys/3` literal-`ref` path). It fails the Operator's multi-rail intent **and** carries the
> double-mint hazard unfixed — cm.7 beats it on both.

---

## 15. Boundary

`echo/apps/codemojex/**` only:
`lib/codemojex/rails.ex` (new — the frozen per-rail facts + the boot vector, `D-6` F1/F5) ·
`lib/codemojex/key_shop.ex` (new — the pure pricing + the `create_order`/`settle_payment` order I/O) ·
`lib/codemojex/schemas/{package,order,order_transaction,webhook}.ex` (new — Venus-Postgres; `webhook.ex` the
`D-5` forward schema) ·
`lib/codemojex/wallet.ex` (the mint seam — `credit_purchase/3` **or** `purchase_keys/3` rebound, Venus-Postgres
§5 F-2; `ref=ORD` — additive; the cm.6 booking sites + `house_post/5` **byte-frozen**, cm.7 is a pure producer
into it) ·
`lib/codemojex/game.ex` (the `Codemojex` facade: `key_packages/0`, `create_order/3`, the settle entry) ·
`lib/codemojex_web/controllers/{game_controller,telegram_controller}.ex` (the create-order route; the
`pre_checkout`/`successful_payment` handling) ·
`lib/codemojex_web/router.ex` (the order route) ·
`priv/repo/migrations/<new × 1>` (Venus-Postgres — one additive migration, the 5th, creating
`packages`/`order_transactions`/`orders` + the `webhooks` forward table) ·
`config/runtime.exs` (the `key_shop_rates` config map — read in `runtime.exs` per the cm.4 config discipline) ·
`test/…` (the `Rails`/`KeyShop` pricing unit tests + the order-flow story suite + the invoice/webhook
controller test) ·
`docs/codemojex/specs/cm.7.*`.

**Out of bounds:** every sibling umbrella app (echo_mq / echo_store / echo_data / echo_wire / echo_bot —
codemojex consumes their surface, never edits it); `echo/mix.lock` (no new dependency — `:jason` is declared,
`:crypto` is OTP); the cm.6-frozen `revenue_ledger.ex` / the cm.6 migration / the cm.6 booking lines /
`house_post/5`; a frozen ledger's history. **`echo/config`** changes only the rate map in `runtime.exs`.

## 16. Build brief

See [`cm.7.llms.md`](./cm.7.llms.md) — the compressed agent brief: the references, the numbered requirements
(each traced to a story + an invariant), the execution topology + the file-by-file build order (smallest-change
first — the pure `KeyShop` module, then the catalog, then the order model, then the Stars rail, then the
cutover), the agent stories (Directive + Acceptance gate), the cite-map (every public call → its real module),
and the gate ladder. The acceptance face is [`cm.7.stories.md`](./cm.7.stories.md). **This brief becomes
build-grade only on the Operator's approval of the F1–F5 synthesis** (the design phase precedes the build).
