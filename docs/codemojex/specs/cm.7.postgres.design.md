# cm.7 · The KeyShop — the relational redesign (multi-rail pay-in)

> **Status — RECONCILED to the LOCKED rulings (cm-7 ledger `D-1`..`D-6`, Operator-ruled).** This is the
> column-by-column schema design for the **KeyShop** — the multi-rail key-purchase surface (Telegram Stars +
> TON / USDT / RUB → keys) — authored from the **relational / payments-integrity / reconciliation lens**. The
> blind dual-architect pass is **CLOSED**: the forks were positioned from this lens (`V-5`..`V-9`) against
> Venus-Triad's product lens (`V-1`..`V-4`), and the Operator ruled — **`D-1`..`D-6` are LOCKED, this document
> reads them as RULED, not as "I rank."** The two ruled divergences: **`D-4`** (the rate source = config-launch +
> `rate_source`/`rate_quoted_at` provenance columns on the order — this lens's `V-8` synthesis, now the ruling)
> and **`D-5`** (the cm.7 build scope = Stars end-to-end + TON/USDT/RUB schema-shaped; **WHK FOLDS INTO the OTX
> `(rail, external_id)` index for the Stars launch** — the dedicated `webhooks` table is a designed-FORWARD shape
> for the first push-webhook rail, on-chain TON). The convergence build contract is **`D-6`** (F1 / F2 / F4-split
> / F5 / F3-pin); the booking convention is **`D-3`** (`account="platform"`, `reason="purchase"`, ratified).
> **This is a SPEC, not code** — no production code is written this phase, and the document is forward-tense for
> the entire (unbuilt) cm.7 surface.
> NO-INVENT: every column / index / type / call site grounds at a real `schemas/*.ex` · `lib/codemojex/*.ex` ·
> `priv/repo/migrations/*.exs` `file:line`, the cm-7 ledger `D-1`..`D-6`, the cm.6 frozen design, or is marked
> **(forward)** for the unbuilt surface.

Paths below are relative to `echo/apps/codemojex/` unless rooted. The boundary is the codemojex app: three new
schema files BUILT this rung (`package.ex`, `order.ex`, `order_transaction.ex`) — the `webhooks` table
(`webhook.ex`) is **designed-FORWARD, NOT built** (`D-5`: it folds into the OTX `(rail, external_id)` index for
the Stars launch; the table lands with the first push-webhook rail), one new migration (creating the **three**
built tables), the Postgres I/O module (`lib/codemojex/key_shop.ex` — new; the orders/payments/booking surface),
a pure pricing/rails module (`lib/codemojex/rails.ex` — new), and the Telegram invoice flow in the web layer. The
**`revenue_ledger` is the SAME ledger cm.6 books into — no second revenue store, ZERO DDL on it** (`D-1`).

---

## §0 — The locked constraints (design around, not about — cm-7 ledger `D-1`..`D-6` + the as-built)

The lens of this design is the **relational shape that makes multi-rail purchase accounting CORRECT,
auditable, and exactly-once**. The forks are **RULED** (`D-1`..`D-6`, Operator-decided over the positioned
`V-5`..`V-9`); this design converges on the chosen arms and builds them out — it does not re-argue them. The
constraints below are the **rulings** (the contract) and the **as-built money surface** the KeyShop sits beside
(verified at `file:line`, none re-derived).

### The rulings (cm-7 ledger `{cm-7-decisions}` — the contract)

- **`D-1` — cm.6 ships AS-BUILT; the `revenue_ledger` is BYTE-FROZEN and is the SAME ledger cm.7 books into.**
  The schema `{id RVL, account, currency, delta :bigint signed no-CHECK, reason, ref, inserted_at}`
  (`schemas/revenue_ledger.ex` + `priv/repo/migrations/20260627090000_create_revenue_ledger.exs`, **uncommitted,
  byte-frozen**) is already multi-source / multi-currency, its `:bigint` delta sized for withdrawal scale
  (cm-6 `D-8b`). cm.7 is a pure **producer**: it books purchase revenue via `Wallet.house_post/5` with **zero
  DDL on `revenue_ledger`**. There is **NO second revenue store**.
- **`D-2` — cm.7 = THE KEYSHOP, multi-rail PAY-IN ONLY** (keys bought via Stars + TON / USDT / RUB). cm.8 =
  withdrawals (diamonds → TON / USDT / RUB at floating rates), **NOT this rung** — cm.7 **designs-for** the
  withdrawal seam (§8) but does not build it.
- **`D-3` (RULED — stands ratified) — purchase revenue books `account="platform"`, `reason="purchase"`,
  `currency=<rail>`, NOT `account="purchase"`.** The shipped `house_balance/0..1` (`wallet.ex:325-336`) filters
  `WHERE account == "platform"`, and the cm.6 frozen design (`cm.6.postgres.design.md` §2/§8) already rules cm.7
  purchases book to `account="platform"`. Booking `account="purchase"` (the brief's literal text) would make
  **all** purchase revenue invisible to `house_balance()` — a reconciliation defect. The movement kind
  `"purchase"` lives in `reason` (free-text, zero DDL); the rail lives in `currency`. **(See §5 for the booking
  primitive; this is the rung's central reconciliation-correctness ruling.)**
- **`D-4` (RULED) — the rate SOURCE = config-launch + `rate_source`/`rate_quoted_at` provenance columns on the
  order.** The rate-at-purchase is PINNED on the order at creation (the lens-independent convergence) AND the
  order carries `rate_source` (`"config"` | `<provider>`) + `rate_quoted_at`, so every booked order
  self-describes its rate's origin (closing the finance-audit-provenance gap a bare config map leaves). The cm.7
  launch source is a config rate map (`key_shop_rates` in `runtime.exs`), read once at order creation, labeled
  `rate_source="config"`; the snapshotted rates/quotes HISTORY table is the cm.8 upgrade (drops in WITHOUT
  reshaping the order). **(This is this lens's `V-8` synthesis, now the ruling — §2.3/§8.2 carry it.)**
- **`D-5` (RULED) — the cm.7 BUILD SCOPE = Stars end-to-end + TON/USDT/RUB schema-shaped; WHK FOLDS INTO OTX for
  the Stars launch.** cm.7 BUILDS the multi-rail FOUNDATION (the `packages` PKG catalog · the ORD/OTX order flow ·
  the pure `KeyShop` pricing + the `Rails` frozen module · the rate-pin per `D-4` · the per-rail exactly-once
  gate · the `house_post` purchase-revenue booking per `D-3`) + the Telegram **STARS** rail END-TO-END (invoice
  → `pre_checkout_query` → `successful_payment`). cm.7 **SHAPES** (does not build) the TON/USDT/RUB adapters — the
  ORD/OTX rows are rail-stable. **WHK folds into the OTX `(rail, external_id)` partial-unique index for the Stars
  launch** — Telegram's `successful_payment` IS the order-coupled confirmation, so a replay no-ops via the
  suppressed duplicate OTX insert (the count-rose check); the dedicated `webhooks` (WHK) table is the **named
  FORWARD** for the first PUSH-webhook rail (on-chain TON confirmations arrive decoupled from an order). **(§2.4
  carries the designed-forward WHK shape; §4 builds THREE tables; the WHK-as-table-now variant is Option-A+,
  NOT ruled in.)**
- **`D-6` (RULED — the convergence build contract) — F1 / F2 / F4-split / F5 / F3-pin.** The two lenses converged
  on these; locked as the build contract: F1 = a bare `rail` discriminator + the frozen `Rails` module (no rails
  table, no mutable decimals column); F2 = one BASE Stars price + a rate-derived per-rail amount PINNED on the
  order (the package is a template) + a nullable per-rail override; F4-split = ONE `orders` + ONE
  `order_transactions` with the `(rail, external_id)` partial-unique exactly-once gate (three rows in one
  `Repo.transaction`, the mint+booking gated on the OTX insert); F5 = each currency in its NATIVE minor unit
  (store-exact, convert at read); F3-pin = the rate pinned on the order row. **(§2/§3/§5/§8 build all of these.)**

### The economy + the new currencies (the broadened economy — the cm.7 trigger)

The Operator broadened the economy with three real-money rails beside Telegram Stars. **cm.7 is pay-in:**

| Rail | `currency` string | Nature · ground |
|---|---|---|
| **Telegram Stars** | `"stars"` | Telegram's in-app currency (XTR), **integer** (no sub-unit); USD value derived from TON (`200 Stars = 1 TON`, Telegram-fixed; TON floats). `~$0.013`/Star face; `~32%` mobile vs `~3%` desktop store fee (`economy.packages.md`). The 1st rail (the as-built `purchase_keys` path, `wallet.ex:147`). |
| **Toncoin** | `"ton"` | TON, **9 decimals → nanoTON** (`1 TON = 1_000_000_000` nanoTON); market-priced, floats. |
| **Tether USD** | `"usdt"` | USDT stablecoin, **6 decimals → micro-USDT** (`1 USDT = 1_000_000`); `~1 USD`. |
| **Russian rouble** | `"rub"` | RUB fiat, **2 decimals → kopeck** (`1 RUB = 100`); market-priced. |

The in-app economy (`economy.ex:1-27`, unchanged): **keys** (bought with Stars; pay for guesses in paid rooms),
**clips** (free; carry no value), **diamonds** (the prize currency, won from rooms, `10:1 → keys` at
`@diamonds_per_key 10`, `@cents_per_diamond 1.2`). Today diamonds are **in-app-only**; cm.8 makes them
cash-out. The pricing input is the Stars→keys ladder + discounts at `economy.packages.md` (the 7-package ladder,
`5 keys @ 99⭐` … `1000 keys @ 9999⭐`, discounts `0..50%`).

### The as-built money surface (the KeyShop sits beside it — verified, none re-derived)

- **A-1 — The revenue ledger cm.7 books into (`D-1`).** `schemas/revenue_ledger.ex:14-33`:
  `@primary_key {:id, :string, autogenerate: false}`; fields `{account :string, currency :string,
  delta :integer, reason :string, ref :string}` + `timestamps(type: :utc_datetime_usec, updated_at: false)`.
  The **Elixir field is `:integer`; the migration column is `:bigint`** (`20260627090000…:19`) — Ecto has no
  width split, so the schema casts `:integer` over the `:bigint` column. **NO non-negative CHECK** (the
  deliberate inverse of `players`), **NO exactly-once index** ("each house post is a distinct accrual",
  `revenue_ledger.ex:9-12`). The `RVL` PK is the sole uniqueness.
- **A-2 — The booking primitive cm.7 reuses: `Wallet.house_post/5`** (`wallet.ex:482-498`, **public** since
  cm.6). Mints `EchoData.BrandedId.generate!("RVL")`, inserts ONE signed `revenue_ledger` row via
  `RevenueLedger.changeset/2`, **touches NO balance column** (so it never hits `players_non_negative` and needs
  no player lock), returns the `RVL` id. It books **ANY** `(account, currency, delta, reason, ref)` with **zero
  DDL** — `currency` and `reason` are free-text. This is the seam cm.7 produces into:
  `house_post("platform", "ton", +gross_nanoton, "purchase", order_id)`.
- **A-3 — The reconciliation reads (`D-1`, the multi-currency seam already in place).**
  `Wallet.house_balance/0..1` (`wallet.ex:325-336`): `SUM(delta) WHERE account == "platform" GROUP BY currency`
  → `%{"keys" => Σ}` today; **`%{"keys" => …, "stars" => …, "ton" => …}` once cm.7 books purchase rows, with NO
  read change** (the cm.6 docstring states this verbatim, `wallet.ex:319-323`). `Wallet.revenue_breakdown/1`
  (`wallet.ex:351-360`): `SUM(delta) WHERE ref == $game GROUP BY reason`. cm.7 adds a per-rail / per-order
  reconciliation read in the same shape (§7).
- **A-4 — The weak purchase surface cm.7 REPLACES (the rung's reason to exist).** `Wallet.purchase_keys/3`
  (`wallet.ex:147`) = `credit(player, :keys, keys, "purchase", ref)` — a bare wallet credit with **NO revenue
  booking** and **NO exactly-once guard**. The call site `game_controller.ex:46` passes
  `params["ref"] || "stars"` — so a request that omits `ref` books **`ref = "stars"`** (a constant literal), and
  replaying the request **mints keys again** (the double-mint-on-replay hazard). There is **NO `packages` table,
  NO Telegram invoice flow** (no `pre_checkout`/`successful_payment` handlers — verified absent by grep), **NO
  Stars-amount capture, NO purchase-revenue booking** today. cm.7 replaces the *caller-side flow* (a real order
  + invoice + the per-rail exactly-once key + the `house_post` booking); the wallet's `credit` primitive stays.
- **A-5 — The shipped exactly-once PATTERN cm.7 mirrors (`A-4`'s fix).** The Golden-Room buy-in is
  exactly-once via a **partial unique index** `transactions_buy_in_once_index` on `(player, ref) WHERE reason =
  'buy_in'` (`20260626120000_golden_rooms.exs:73-76`), inserted with **Pattern A** (`on_conflict: :nothing`,
  `conflict_target` byte-matched to the partial `where:`; `wallet.ex:438-441`), with the count-rose check
  distinguishing `:wrote` from `:suppressed` (`wallet.ex:425-443`) and the changeset DB-error → changeset-error
  bridge (`transaction.ex:26`, `unique_constraint(:ref, name: :transactions_buy_in_once_index)`). cm.7's
  per-rail exactly-once is this pattern, keyed `(rail, external_id)` (§2.2, §6).
- **A-6 — The `transactions` row shape (the keys MINT cm.7 writes).** `schemas/transaction.ex:6-15`:
  `{player, currency :string, delta :integer (signed), reason :string, ref :string}` + append-only timestamps.
  cm.7's key-mint is `credit(player, :keys, keys, "purchase", order_id)` (`wallet.ex:383-396`) — ONE signed
  `transactions` credit row, **inside the same `Repo.transaction` as the OTX insert + the `house_post`** (§5),
  the `ref` the branded `ORD` id (not the weak `"stars"` literal).
- **A-7 — The non-negative CHECK the house does NOT inherit, and the player DOES** (`player.ex:43-47`):
  `validate_number(>= 0)` on all five balances + `check_constraint :players_non_negative`. The keys MINT is a
  `players.keys += keys` credit (always non-negative — a mint never goes negative), so it sits cleanly inside
  `players`. The revenue booking is `house_post` (no balance column, `A-2`). cm.7 introduces **no** new CHECK
  on `players`/`revenue_ledger`.
- **A-8 — The branded-id contract (the PKG/ORD/OTX/WHK brands).** `EchoData.BrandedId.generate!(ns)`
  (`branded_id.ex:93`) mints a 14-byte branded snowflake — **time-ordered** (sorts by creation),
  **coordination-free** (mint on any node, no registry). `valid_ns?` (`branded_id.ex:143`) accepts **any
  `[A-Z]{3}`** namespace, so `PKG`/`ORD`/`OTX`/`WHK` are valid with **zero registration / zero migration**
  (exactly as `RVL` was in cm.6). The brand **IS** the type — checked at every boundary.
- **A-9 — FROZEN at-rest surface.** Four migrations are **byte-frozen**:
  `20260618000000_create_codemojex.exs`, `20260625145121_add_player_tg_user_id.exs`,
  `20260626120000_golden_rooms.exs`, and (under `D-1`) `20260627090000_create_revenue_ledger.exs`. cm.7 adds a
  **NEW 5th** migration; it edits none. Boundary ⊆ `echo/apps/codemojex/**` + the rung docs; `mix.lock`
  untouched (the existing Ecto / `exqlite` stack).

---

## §1 — The reinitialization target (surfaced FIRST, before any reinit)

The codemojex Ecto Repo (`Codemojex.Repo`) is configured in the **umbrella** config tree (`echo/config/`), NOT
in an app-local `config/` (cm.5/cm.6 §1, unchanged):

| MIX_ENV | DB name | Config site |
|---|---|---|
| `test` | **`codemojex_test`** + `#{MIX_TEST_PARTITION}` suffix | `echo/config/test.exs` (pool `Ecto.Adapters.SQL.Sandbox`) |
| `dev` | **`codemojex_dev`** | `echo/config/dev.exs` |
| `prod` | `System.get_env("DATABASE_URL")` | `echo/config/runtime.exs` (the Operator's deploy; out of this rung's reinit) |

**No `*_snapshot` database exists** in the echo umbrella config (cm.5/cm.6 §1 verified it). **Surface the DB
target FIRST, then reinit** (from the app dir, per the per-app gate ladder + `TMPDIR=/tmp`):

```bash
cd /Users/jonny/dev/jonnify/echo/apps/codemojex
MIX_ENV=test TMPDIR=/tmp mix ecto.drop      # drops codemojex_test (+ the active MIX_TEST_PARTITION suffix)
MIX_ENV=test TMPDIR=/tmp mix ecto.create
MIX_ENV=test TMPDIR=/tmp mix ecto.migrate   # replays the 4 shipped migrations + the NEW cm.7 KeyShop migration
```

Notes (cm.5/cm.6 §1, unchanged): (a) the `Ecto.Adapters.SQL.Sandbox` pool runs the suite in transactions, so
the reinit is a one-time schema rebuild before the suite; (b) under `MIX_TEST_PARTITION=N` the drop/create/migrate
run under the same partition env so the suffixed DB is rebuilt; (c) dev reinitializes the same way with
`MIX_ENV=dev`. `prod` is the Operator's deploy — and because cm.7's migration `up` is **non-destructive** (pure
`create table`, §4), the prod cutover is a forward `mix ecto.migrate` with **no destructive at-rest op**. The
migration **file** count goes **4 → 5** (one new migration, creating the **three** built tables — `packages` ·
`orders` · `order_transactions`; the `webhooks` table is designed-forward, NOT in this migration, `D-5`).

---

## §2 — The schemas (NEW — the packages / orders / payments surface; +the designed-forward WHK)

cm.7 adds the purchase surface that SITS IN FRONT of the existing `revenue_ledger` booking. **THREE tables are
built this rung** (`D-5`): **packages** (a versionable catalog template, `V-7`/`D-6` F2), **orders** (ORD — the
authoritative money: the pinned price + the pinned rate, immutable once paid, `V-7`/`D-6` F2), and
**order_transactions** (OTX — the external rail receipt + the **per-rail exactly-once key**, `V-9`/`D-6`
F4-split). A **fourth table, `webhooks` (WHK), is DESIGNED-FORWARD but NOT built** (`D-5`): for the Stars launch
WHK **folds into the OTX `(rail, external_id)` index** — Telegram's `successful_payment` is the order-coupled
confirmation, deduped by the OTX insert directly — and the dedicated `webhooks` table lands with the first
PUSH-webhook rail (on-chain TON, §2.4). The rail is a **discriminator** (`V-5`/`D-6` F1), the minor-unit
convention is **native-per-currency** (`V-6`/`D-6` F5, §8).

### §2.1 — `packages` (NEW table `packages`, `schemas/package.ex`) — the catalog (a versionable template)

The buyable bundles. Per `V-7` (CONVERGES with the product lens `V-2` Arm B), the package carries **ONE base
price** — the Stars ladder (the canonical face) + the keys granted — NOT four per-rail price columns. A standing
per-rail price column is a drift hazard (four editable money cells per row, nothing reconciling them); the per-rail
amount is **derived at order creation** from the base + the rate (F3) and **pinned on the order** (§2.3), so the
package is a template, not a live price source. An optional nullable per-rail **override** is admitted for rails an
operator wants pinned to a round number (RUB), but it too is pinned-on-order (the integrity rule — editing a
package never alters a booked order).

| Column | Type · null · default | Why · ground |
|---|---|---|
| `id` | `:string`, **PK**, `autogenerate: false` | the branded `PKG` id (`A-8`), `generate!("PKG")`; time-ordered, coordination-free. Mirrors every codemojex PK (`player.ex:6`, `revenue_ledger.ex:17`). |
| `keys` | `:integer`, `null: false` | the keys granted by this package (`5`/`15`/`50`/`100`/`200`/`500`/`1000`, `economy.packages.md`). The product. `:integer` (a key count, like `players.keys`). |
| `stars_price` | `:integer`, `null: false` | the **base** price in whole Stars (the canonical face: `99`/`249`/`799`/`1449`/`2599`/`5499`/`9999`, `economy.packages.md`). XTR is integer (`A`'s minor-unit table, decimals 0). The single editable money figure (`V-7`). |
| `discount_pct` | `:integer`, `null: true` | the display discount (`0`/`16`/`20`/`27`/`35`/`45`/`50`, `economy.packages.md`) — presentational; the real price is `stars_price`. Nullable (a package may carry none). A domain CHECK `0..100` (the `rooms_revenue_pct_range` idiom, `golden_rooms.exs:51-54`). |
| `ton_price_minor` | `:bigint`, `null: true` | OPTIONAL operator override: a pinned TON price in **nanoTON** (`V-7`). NULL ⇒ derive from `stars_price` + the rate at order creation. `:bigint` (nanoTON scale). |
| `usdt_price_minor` | `:bigint`, `null: true` | OPTIONAL override: a pinned USDT price in **micro-USDT**. NULL ⇒ derive. |
| `rub_price_minor` | `:bigint`, `null: true` | OPTIONAL override: a pinned RUB price in **kopeck** (the rail most likely pinned to a round number, `V-7`). NULL ⇒ derive. |
| `enabled` | `:boolean`, `null: false`, `default: true` | the runtime on/off (the `V-1` "enable is a flag, not a rails table" position). A disabled package is not orderable; existing orders are unaffected (the pin-on-order rule). |
| `sort` | `:integer`, `null: false`, `default: 0` | the catalog display order. Presentational. |
| `inserted_at` / `updated_at` | `:utc_datetime_usec` | **standard `timestamps()`** (NOT append-only) — a package IS editable (price/enabled change over time); the order's pinned copy is what is immutable, not the template. This is the deliberate difference from the append-only ledger tables. |

> **Why `packages` is editable but the order's price is not** (the `V-7` integrity rule, restated at the column
> level): the package is a **template** an operator versions (raise the Stars price, disable a bundle); the
> **order** pins the price + rate at creation (§2.3) and never reads back through to the package at settlement. So
> a price edit changes **future** orders, never an in-flight or booked one — the price analogue of cm.6's
> "balance = sum of immutable rows". `packages` carries `updated_at`; the order does not.

**The Ecto schema** (`schemas/package.ex` — NEW; forward-tense; the catalog template):

```elixir
defmodule Codemojex.Schemas.Package do
  @moduledoc "A buyable key bundle — the KeyShop catalog (cm.7). The base price is whole Stars (the canonical face, economy.packages.md); the per-rail price is derived at order creation + pinned on the order, with an optional nullable per-rail minor-unit override. A versionable TEMPLATE — editing it changes future orders only (the order pins its own price), so this table carries updated_at while the ledger tables do not."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "packages" do
    field :keys, :integer
    field :stars_price, :integer
    field :discount_pct, :integer
    field :ton_price_minor, :integer     # the :bigint column (nanoTON), nullable override
    field :usdt_price_minor, :integer    # micro-USDT, nullable override
    field :rub_price_minor, :integer     # kopeck, nullable override
    field :enabled, :boolean, default: true
    field :sort, :integer, default: 0
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(pkg, attrs) do
    pkg
    |> cast(attrs, [:id, :keys, :stars_price, :discount_pct,
                    :ton_price_minor, :usdt_price_minor, :rub_price_minor, :enabled, :sort])
    |> validate_required([:id, :keys, :stars_price])
    |> validate_number(:keys, greater_than: 0)
    |> validate_number(:stars_price, greater_than: 0)
    |> check_constraint(:discount_pct, name: :packages_discount_pct_range)
  end
end
```

### §2.2 — `order_transactions` (NEW table `order_transactions`, `schemas/order_transaction.ex`) — OTX, the external rail receipt + the per-rail exactly-once key

The external payment record per rail — and the **exactly-once authority** (`V-9`). One OTX row is the confirmed
payment: the rail's external charge identifier (the Telegram charge id for Stars, the on-chain tx hash for TON, a
processor reference id for fiat) lives in `external_id`, and a **partial unique index** `(rail, external_id)
WHERE external_id IS NOT NULL` (§3) is the per-rail dedup — the precise fix for `A-4`'s `"stars"`-literal
double-mint. The full provider receipt is preserved verbatim in `raw_payload` (a stronger audit trail than
hand-picked columns — nothing is dropped). The key-MINT + the revenue booking fire **only if the OTX insert
actually wrote** (§5, §6).

| Column | Type · null · default | Why · ground |
|---|---|---|
| `id` | `:string`, **PK**, `autogenerate: false` | the branded `OTX` id (`A-8`), `generate!("OTX")`. |
| `order_id` | `:string`, `null: false` | the parent `ORD` id (§2.3) — an OTX belongs to one order. FK → `orders(id)` (§3). |
| `rail` | `:string`, `null: false` | the payment method: `"stars"`/`"ton"`/`"usdt"`/`"rub"` (the discriminator, `V-5`). A CHECK pins the closed set (§3). Half of the exactly-once key. |
| `external_id` | `:string`, `null: true` | the rail's external charge identifier — Stars: the Telegram `telegram_payment_charge_id`; TON: the on-chain `tx_hash`; fiat: the processor reference. **Nullable** because it does not exist until the provider confirms (a created-but-unconfirmed OTX has none); the **partial** unique index `(rail, external_id) WHERE external_id IS NOT NULL` (§3) is the exactly-once authority. The other half of the dedup key. |
| `amount_minor` | `:bigint`, `null: false` | the GROSS rail amount RECEIVED, in the rail's **native minor unit** (`V-6`/§8): Stars→whole stars, TON→nanoTON, USDT→micro-USDT, RUB→kopeck. The figure booked to `revenue_ledger` (§5). `:bigint` — nanoTON scale (a 130-TON whale = `1.3e11` nanoTON ≪ `int8` `9.2e18`). The schema field casts `:integer` over the `:bigint` (the `revenue_ledger` idiom, `A-1`). |
| `status` | `:string`, `null: false`, `default: "confirmed"` | the payment status: `"confirmed"` (the provider settled — the only status that drives a mint) · `"failed"` · `"refunded"` (cm.8-forward; a chargeback/refund record). A CHECK pins the set (§3). |
| `raw_payload` | `:map` (`:jsonb` column), `null: true` | the FULL provider receipt verbatim (the Telegram `successful_payment`, the TON tx, the processor callback) — the audit trail. `:jsonb` (Postgres native; Ecto `:map`). Nullable (a manually-recorded OTX may carry none). |
| `inserted_at` | `:utc_datetime_usec`, **append-only** | `timestamps(updated_at: false)` — an OTX is an immutable receipt (the `revenue_ledger`/`transactions` discipline, `A-1`/`A-6`). A refund is a NEW OTX row, never an in-place mutation. |

**The Ecto schema** (`schemas/order_transaction.ex` — NEW; forward-tense; the exactly-once receipt):

```elixir
defmodule Codemojex.Schemas.OrderTransaction do
  @moduledoc "An external rail payment receipt for an order (cm.7, OTX). The (rail, external_id) partial unique index is the per-rail exactly-once authority — the fix for the 'stars'-literal double-mint (the buy_in exactly-once pattern, golden_rooms.exs:73-76, applied to purchases). The key-mint + the revenue booking fire only if THIS row's insert actually wrote. external_id is nullable (it does not exist until the provider confirms); the FULL provider receipt is preserved in raw_payload. Append-only — a refund is a new row."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "order_transactions" do
    field :order_id, :string
    field :rail, :string
    field :external_id, :string
    field :amount_minor, :integer       # the :bigint column; the gross rail amount in native minor units
    field :status, :string, default: "confirmed"
    field :raw_payload, :map            # the :jsonb column — the verbatim provider receipt
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(otx, attrs) do
    otx
    |> cast(attrs, [:id, :order_id, :rail, :external_id, :amount_minor, :status, :raw_payload])
    |> validate_required([:id, :order_id, :rail, :amount_minor])
    # The DB-error -> changeset-error bridge: a 23505 on the partial unique index surfaces
    # as a changeset error, not a raised ConstraintError. Names the SAME index as the
    # migration (§3) byte-for-byte. Mirrors transaction.ex:26.
    |> unique_constraint([:rail, :external_id], name: :order_transactions_rail_external_once_index)
  end
end
```

### §2.3 — `orders` (NEW table `orders`, `schemas/order.ex`) — ORD, the rail-independent lifecycle + the pinned money

The authoritative money + the lifecycle (`V-9`). The order LIFECYCLE (a player buys package X → pending →
paid → fulfilled / failed / refunded) is **rail-independent** — one orders table with a `rail` discriminator,
not per-rail tables. The order **pins** the price + the rate at creation (`V-7`/`V-8`), so booked revenue is
reproducible and a later package/rate edit never rewrites it.

| Column | Type · null · default | Why · ground |
|---|---|---|
| `id` | `:string`, **PK**, `autogenerate: false` | the branded `ORD` id (`A-8`), `generate!("ORD")`. **This is the `ref` on the keys-mint `transactions` row AND the `revenue_ledger` row** — the per-order reconciliation key, replacing the weak `"stars"` literal (`A-4`). |
| `player` | `:string`, `null: false` | the buyer `PLR` id. FK → `players(id)` (§3). The wallet the keys mint into. |
| `package_id` | `:string`, `null: true` | the `PKG` ordered (§2.1). **Nullable** — a future non-catalog purchase (a custom amount) carries the keys/price inline; the catalog order references the template. FK → `packages(id)` (§3). |
| `rail` | `:string`, `null: false` | the payment method (the discriminator, `V-5`): `"stars"`/`"ton"`/`"usdt"`/`"rub"`. A CHECK pins the closed set (§3). |
| `keys` | `:integer`, `null: false` | the keys to MINT on settlement — **pinned from the package at creation** (`V-7`), not read back through. So a package `keys` edit never changes a booked order's grant. `:integer`. |
| `currency` | `:string`, `null: false` | the booked currency — the rail's currency (`"stars"`/`"ton"`/`"usdt"`/`"rub"`). Separated from `rail` (they coincide at cm.7) so a future rail paying in a currency ≠ its name (a card charged in USD) extends cleanly (`V-9`). This is the `currency` passed to `house_post` (§5). |
| `price_minor` | `:bigint`, `null: false` | the GROSS rail amount the player must pay, in the rail's **native minor unit** (`V-6`/§8) — **pinned at creation** from the package base + the rate (or the package override, `V-7`). The order's authoritative price; the OTX `amount_minor` must equal it on a clean settlement (§6). `:bigint`. |
| `rate_minor` | `:bigint`, `null: true` | the rate SNAPSHOT used to derive `price_minor` (`D-4`/`D-6` F3-pin). **Nullable** — the Stars rail needs no rate (the base price IS Stars); TON/USDT/RUB pin the rate-at-creation here so the derivation is reproducible. Stored as a minor-unit-scaled integer (the convention pinned in the `rate_pair` + §8), never a float (no lossy money math). |
| `rate_pair` | `:string`, `null: true` | the rate's pair label, e.g. `"stars_per_ton"` / `"usdt_per_usd"` / `"rub_per_usd"` — names what `rate_minor` measures (`D-4`). Nullable (Stars). |
| `rate_source` | `:string`, `null: true` | the rate's provenance (`D-4`, RULED): `"config"` (the launch source) or a provider name. The audit anchor finance reads to answer "why this rate" — the provenance column that closes the bare-config-map gap. Nullable (Stars). |
| `rate_quoted_at` | `:utc_datetime_usec`, `null: true` | when the pinned rate was quoted (`D-4`). For a `config` rate, the order's own `inserted_at` is the de-facto quoted-at; for a future rates-table source (cm.8), the row's `fetched_at`. Nullable (Stars). |
| `status` | `:string`, `null: false`, `default: "created"` | the lifecycle: `"created"` (invoice issued, unpaid) · `"paid"` (the OTX confirmed, keys minted, revenue booked — the terminal happy state) · `"failed"` (the player abandoned / the payment failed) · `"refunded"` (cm.8-forward). A CHECK pins the set (§3). |
| `inserted_at` / `updated_at` | `:utc_datetime_usec` | **standard `timestamps()`** — the order's `status` mutates (`created → paid`), so it carries `updated_at`. The money columns (`price_minor`, `rate_*`, `keys`) are pinned-at-creation by DISCIPLINE (never UPDATEd after `paid`), not by an append-only-table guard — the order is a small state machine, the receipts (OTX) are the append-only records. |

**The Ecto schema** (`schemas/order.ex` — NEW; forward-tense; the lifecycle + the pinned money):

```elixir
defmodule Codemojex.Schemas.Order do
  @moduledoc "A key-purchase order (cm.7, ORD) — the rail-independent lifecycle (created -> paid -> failed/refunded) + the PINNED money (price_minor + the rate snapshot, frozen at creation). The order id is the ref on the keys-mint transactions row AND the revenue_ledger row (the per-order reconciliation key, replacing the weak 'stars' literal). The money columns are pinned at creation by discipline (never UPDATEd after paid), so a later package/rate edit never rewrites a booked order. The append-only receipts are OTX (§2.2)."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  @rails ~w(stars ton usdt rub)
  @statuses ~w(created paid failed refunded)

  schema "orders" do
    field :player, :string
    field :package_id, :string
    field :rail, :string
    field :keys, :integer
    field :currency, :string
    field :price_minor, :integer        # the :bigint column; gross rail amount in native minor units
    field :rate_minor, :integer         # the :bigint column; the pinned rate snapshot (nullable; Stars=nil)
    field :rate_pair, :string
    field :rate_source, :string
    field :rate_quoted_at, :utc_datetime_usec
    field :status, :string, default: "created"
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:id, :player, :package_id, :rail, :keys, :currency, :price_minor,
                    :rate_minor, :rate_pair, :rate_source, :rate_quoted_at, :status])
    |> validate_required([:id, :player, :rail, :keys, :currency, :price_minor])
    |> validate_inclusion(:rail, @rails)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:keys, greater_than: 0)
    |> validate_number(:price_minor, greater_than: 0)
    # the DB-error -> changeset-error bridge for the status/rail CHECKs (§3).
    |> check_constraint(:rail, name: :orders_rail_valid)
    |> check_constraint(:status, name: :orders_status_valid)
  end
end
```

### §2.4 — `webhooks` (WHK) — DESIGNED-FORWARD, NOT built this rung (`D-5`)

**RULED (`D-5`): WHK FOLDS INTO the OTX `(rail, external_id)` partial-unique index for the Stars launch — the
`webhooks` table is NOT created this rung.** This section documents the WHK shape **designed-forward** so the
build adds it cleanly when the first push-webhook rail (on-chain TON) lands; it is **not** in the §4 migration.

**Why the fold is correct for Stars (the pull-vs-push distinction — the design heart of `D-5`).** Telegram's
`successful_payment` is an **order-coupled** confirmation: it arrives as the settlement response to an invoice
the platform issued, carrying the `telegram_payment_charge_id` that becomes the OTX `external_id`. So a
re-delivered `successful_payment` is deduped **directly** by the OTX `(rail, external_id)` partial-unique index
(§3) via the Pattern A suppressed insert + the count-rose check (§5) — the mint + the booking ride the OTX
insert, so a replay mints nothing / books nothing. A separate `webhooks` ingress table would dedupe the same
event a second time, **upstream** of the OTX gate, but for a pull-confirmation rail the OTX gate already sits on
the event's own identifier — the second dedup layer buys nothing the OTX index does not already give. **The
WHK table earns its keep only for a PUSH-confirmation rail** — an on-chain TON confirmation a chain watcher
observes **decoupled** from any order (no request-response to ride), where the inbound event must be recorded
and matched to an order before it can drive a settlement, and an ingress idempotency key prevents a doubly-observed
confirmation re-driving the match. That is the first push rail (TON), and the `webhooks` table lands with it.

**The designed-forward WHK shape (built with the first push rail — TON; NOT this rung):**

| Column | Type · null · default | Why · ground |
|---|---|---|
| `id` | `:string`, **PK**, `autogenerate: false` | the branded `WHK` id (`A-8`), `generate!("WHK")`. |
| `rail` | `:string`, `null: false` | the source rail (a push rail: `"ton"` first; the discriminator). A CHECK pins the rail set. |
| `event_id` | `:string`, `null: false` | the provider's event identifier (the TON tx hash / a processor callback id). UNIQUE per `(rail, event_id)` — the ingress dedup key for a decoupled push event. |
| `order_id` | `:string`, `null: true` | the `ORD` the event resolved to (set once matched). Nullable — a push event is recorded before it is matched to an order. FK → `orders(id)`. |
| `processed_at` | `:utc_datetime_usec`, `null: true` | when the event finished driving the order (the mint committed). Nullable — absent for a recorded-but-not-yet-processed event. |
| `inserted_at` | `:utc_datetime_usec`, **append-only** | `timestamps(updated_at: false)` — the receipt of delivery is immutable. |

```elixir
# FORWARD (NOT built this rung — D-5; lands with the first push-webhook rail, on-chain TON):
defmodule Codemojex.Schemas.Webhook do
  @moduledoc "An inbound PUSH-rail-event idempotency record (FORWARD — the first push rail, TON). For a push-confirmation rail an on-chain/processor event arrives DECOUPLED from an order, so it is recorded by (rail, event_id) UNIQUE at ingress and matched to an order before it drives a settlement. For the Stars launch WHK folds into the OTX (rail, external_id) index (D-5) — successful_payment is order-coupled, deduped by OTX directly — so this table is NOT created this rung."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "webhooks" do
    field :rail, :string
    field :event_id, :string
    field :order_id, :string
    field :processed_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(whk, attrs) do
    whk
    |> cast(attrs, [:id, :rail, :event_id, :order_id, :processed_at])
    |> validate_required([:id, :rail, :event_id])
    |> unique_constraint([:rail, :event_id], name: :webhooks_rail_event_once_index)
  end
end
```

> **The Option-A+ variant (NOT ruled in — recorded for completeness, `D-5`).** A `webhooks` table built **now**
> (this lens's original `V-9` defense-in-depth) would dedupe the Stars `successful_payment` at ingress, upstream
> of the OTX gate, and give an auditable durable delivery record from day one. The Operator **declined** it: for
> the pull-confirmation Stars rail the OTX `(rail, external_id)` index already provides exactly-once on the event's
> own identifier, so the table is not needed at launch. It remains available as a ~4-column Option-A+ add if the
> Operator later wants ingress-level dedup + a delivery audit before the first push rail; the shape above drops in
> unchanged. (The `raw_payload` audit trail the integrity lens wanted for Stars is already preserved on the OTX
> row, §2.2 — the verbatim `successful_payment` — so the Stars launch loses no audit by folding WHK into OTX.)

---

## §3 — The indexes + the FKs + the CHECKs

The exactly-once indexes are the rung's correctness core; the FKs bind the order graph; the CHECKs pin the
closed enums (the `games_status` / `rooms_revenue_pct_range` idiom, `golden_rooms.exs:17-20,51-54`).

### The unique index (the exactly-once authority — `D-6` F4-split)

ONE built unique index this rung — the per-rail exactly-once gate (`D-5`/`D-6`: WHK folds into it for Stars, so
it is the SOLE dedup authority at launch).

| Index | Table | Definition | Backs · ground |
|---|---|---|---|
| `order_transactions_rail_external_once_index` | `order_transactions` | **partial UNIQUE** `(rail, external_id) WHERE external_id IS NOT NULL` | **THE per-rail exactly-once key** (§2.2/§6) — a confirmed payment (Stars charge id / TON tx hash / fiat ref) is unique per rail; the mint fires only if the OTX insert wrote. **Partial** so many NULL-`external_id` created-but-unconfirmed rows coexist. The EXACT shape of `transactions_buy_in_once_index` (`golden_rooms.exs:73-76`), byte-matched by the `OrderTransaction.changeset` `unique_constraint` (§2.2) and the `KeyShop` `conflict_target` fragment (§5). For the Stars launch this index ALSO subsumes ingress dedup (`D-5`): `successful_payment` is order-coupled, deduped here directly. |

> **The `webhooks_rail_event_once_index` (UNIQUE `(rail, event_id)`) is FORWARD, NOT built this rung** (`D-5`,
> §2.4) — it lands with the `webhooks` table for the first push-webhook rail (TON), where a decoupled push event
> needs ingress dedup the OTX gate cannot give (the OTX gate keys on the payment's `external_id`, which a push
> event resolves to only after matching).

### The lookup indexes (the read shapes — §7)

| Index | Table | Definition | Backs · ground |
|---|---|---|---|
| `orders_player_index` | `orders` | `(player)` | a player's purchase history (§7); the lobby "your orders" read. |
| `orders_status_index` | `orders` | `(status)` | the open-order sweep (`status = 'created'` stale-invoice reconcile, §7) + ops dashboards. |
| `order_transactions_order_id_index` | `order_transactions` | `(order_id)` | the per-order receipt read (an order's OTX rows, §7). |

> **No index on `revenue_ledger`** — cm.7 books into the EXISTING `(account)` / `(ref)` indexes (`A-1`,
> `20260627090000…:25-26`) with **zero DDL** (`D-1`). Purchase revenue rows carry `account="platform"` (the
> `(account)` index serves `house_balance`) and `ref=<ORD id>` (the `(ref)` index serves the per-order revenue
> read, §7). **The cm.7 spec must NOT add a `revenue_ledger` index** — that would touch the frozen surface.

### The foreign keys (the order graph)

| FK | From → To | On delete | Ground |
|---|---|---|---|
| `orders.player` | → `players(id)` | `:restrict` (`:nilify_all` rejected — an order must keep its buyer for audit) | the buyer; the wallet the keys mint into (`A-7`). |
| `orders.package_id` | → `packages(id)` | `:nilify_all` (a deleted package leaves the order's PINNED keys/price intact — the template can go, the booked order stays — `V-7`) | the catalog reference; nullable. |
| `order_transactions.order_id` | → `orders(id)` | `:restrict` (a receipt must keep its order) | the parent order. |

> **FORWARD (`D-5`):** the `webhooks.order_id` → `orders(id)` FK (`:nilify_all` — an event may outlive a voided
> order) lands with the `webhooks` table for the first push rail; NOT built this rung.

> **FK references are by the branded string PK** — `references(:players, type: :string, column: :id)` (the codemojex
> ids are `:string` branded snowflakes, not integers — `A-8`). Mars confirms the `type: :string` on every
> `references/2` (the default is `:bigserial`, wrong here). The cm.5 migration uses no FK (the games/transactions
> relation is by `ref` string, not a DB FK); cm.7 INTRODUCES real FKs for the order graph — flagged as a new
> at-rest pattern for the Director.

### The CHECK constraints (the closed enums — the `golden_rooms` domain-guard idiom)

| CHECK | Table | Predicate | Ground |
|---|---|---|---|
| `orders_rail_valid` | `orders` | `rail IN ('stars','ton','usdt','rub')` | the closed rail set (`V-5`); the DB backstop if app logic slips (the `players_non_negative` philosophy). |
| `orders_status_valid` | `orders` | `status IN ('created','paid','failed','refunded')` | the lifecycle states; mirrors `games_status` (`golden_rooms.exs:17-20`). |
| `order_transactions_rail_valid` | `order_transactions` | `rail IN ('stars','ton','usdt','rub')` | the rail set on the receipt. |
| `order_transactions_status_valid` | `order_transactions` | `status IN ('confirmed','failed','refunded')` | the payment states. |
| `packages_discount_pct_range` | `packages` | `discount_pct IS NULL OR (discount_pct >= 0 AND discount_pct <= 100)` | nullable-aware domain guard; mirrors `rooms_revenue_pct_range` (`golden_rooms.exs:51-54`). |
| `orders_price_positive` | `orders` | `price_minor > 0` | a money backstop (an order charges a positive gross). |
| `order_transactions_amount_positive` | `order_transactions` | `amount_minor > 0` | a received-amount backstop. |

> **Why amounts CHECK `> 0` but `revenue_ledger.delta` does NOT** (the deliberate inverse, `A-1`): the
> `revenue_ledger.delta` is **signed** (a withdrawal debit is negative — `D-1`/`D-2`); the ORDER/OTX amounts are
> always a **positive gross received** (a refund is a separate OTX row with `status="refunded"`, not a negative
> amount), so they carry a positive CHECK. The signed-vs-positive split is the structural difference between the
> revenue ledger (a balance that swings) and the order/payment records (gross movements).

---

## §4 — The additive migration (the 5th cm.7 migration; up + down)

**Strategy (decided):** ONE new migration
(`priv/repo/migrations/20260628NNNNNN_create_key_shop.exs`) **creates** the **three** built tables (`packages` ·
`orders` · `order_transactions`) + their indexes + FKs + CHECKs. The `webhooks` (WHK) table is NOT here (`D-5` —
it folds into the OTX index for Stars; a forward migration adds it with the first push rail, §2.4). The four
shipped migrations stay **byte-frozen** (`A-9` — never edit a shipped migration; the
cm.4/cm.5/cm.6 additive precedent). `up`/`down` are EXPLICIT (the cm.5/cm.6 idiom), `:bigint` for every money
column, `:jsonb` for `raw_payload`, `timestamps(type: :utc_datetime_usec, updated_at: false)` for the append-only
table (OTX) and full `timestamps()` for the editable ones (orders, packages). The `webhooks` (WHK) table is
**NOT** created here (`D-5` — it folds into the OTX `(rail, external_id)` index for the Stars launch; it lands
with the first push-webhook rail, §2.4).

```elixir
defmodule Codemojex.Repo.Migrations.CreateKeyShop do
  use Ecto.Migration

  # cm.7 — the KeyShop (multi-rail pay-in: Stars + TON/USDT/RUB -> keys). THREE NEW
  # tables (D-5): packages (the catalog template), orders (ORD — the lifecycle + the
  # PINNED money), order_transactions (OTX — the external rail receipt + the per-rail
  # exactly-once key). The webhooks (WHK) table is NOT created here — it folds into the
  # OTX (rail, external_id) index for the Stars launch (successful_payment is order-
  # coupled, deduped by OTX directly) and lands with the first push-webhook rail (TON).
  # Additive onto the FOUR shipped migrations (all byte-frozen, incl. cm.6 revenue_ledger).
  # cm.7 creates, never edits — and touches the revenue_ledger with ZERO DDL (house_post).
  #
  # up is NON-DESTRUCTIVE (pure create — the destructive gate is a no-op on it); down is
  # the dev-reset inverse (drops the three new tables), never a live rollback over orders.
  def up do
    # --- packages: the catalog TEMPLATE (editable; carries updated_at) ---
    create table(:packages, primary_key: false) do
      add :id, :string, primary_key: true
      add :keys, :integer, null: false
      add :stars_price, :integer, null: false          # the base price (whole Stars)
      add :discount_pct, :integer                        # presentational; nullable
      add :ton_price_minor, :bigint                      # nanoTON override; nullable
      add :usdt_price_minor, :bigint                     # micro-USDT override; nullable
      add :rub_price_minor, :bigint                      # kopeck override; nullable
      add :enabled, :boolean, null: false, default: true
      add :sort, :integer, null: false, default: 0
      timestamps(type: :utc_datetime_usec)               # EDITABLE template -> updated_at
    end

    create constraint(:packages, :packages_discount_pct_range,
             check: "discount_pct IS NULL OR (discount_pct >= 0 AND discount_pct <= 100)")

    # --- orders: ORD — the lifecycle + the PINNED money ---
    create table(:orders, primary_key: false) do
      add :id, :string, primary_key: true
      add :player, references(:players, type: :string, column: :id, on_delete: :restrict), null: false
      add :package_id, references(:packages, type: :string, column: :id, on_delete: :nilify_all)
      add :rail, :string, null: false
      add :keys, :integer, null: false                   # pinned from the package at creation
      add :currency, :string, null: false
      add :price_minor, :bigint, null: false             # gross rail amount, native minor units, PINNED
      add :rate_minor, :bigint                            # the rate snapshot; nullable (Stars)
      add :rate_pair, :string
      add :rate_source, :string                           # "config" | <provider> — the provenance
      add :rate_quoted_at, :utc_datetime_usec
      add :status, :string, null: false, default: "created"
      timestamps(type: :utc_datetime_usec)                # status mutates -> updated_at
    end

    create constraint(:orders, :orders_rail_valid,
             check: "rail IN ('stars','ton','usdt','rub')")
    create constraint(:orders, :orders_status_valid,
             check: "status IN ('created','paid','failed','refunded')")
    create constraint(:orders, :orders_price_positive, check: "price_minor > 0")
    create index(:orders, [:player])
    create index(:orders, [:status])

    # --- order_transactions: OTX — the external receipt + the per-rail exactly-once key ---
    create table(:order_transactions, primary_key: false) do
      add :id, :string, primary_key: true
      add :order_id, references(:orders, type: :string, column: :id, on_delete: :restrict), null: false
      add :rail, :string, null: false
      add :external_id, :string                           # Stars charge id / TON tx hash / fiat ref; nullable until confirmed
      add :amount_minor, :bigint, null: false             # gross rail amount, native minor units
      add :status, :string, null: false, default: "confirmed"
      add :raw_payload, :map                              # :jsonb — the verbatim provider receipt
      timestamps(type: :utc_datetime_usec, updated_at: false)  # APPEND-ONLY receipt
    end

    create constraint(:order_transactions, :order_transactions_rail_valid,
             check: "rail IN ('stars','ton','usdt','rub')")
    create constraint(:order_transactions, :order_transactions_status_valid,
             check: "status IN ('confirmed','failed','refunded')")
    create constraint(:order_transactions, :order_transactions_amount_positive,
             check: "amount_minor > 0")
    create index(:order_transactions, [:order_id])
    # THE per-rail exactly-once authority (the 'stars'-literal double-mint fix) — PARTIAL
    # UNIQUE, byte-matched by the OrderTransaction changeset + the KeyShop conflict_target.
    create unique_index(:order_transactions, [:rail, :external_id],
             where: "external_id IS NOT NULL",
             name: :order_transactions_rail_external_once_index)

    # NOTE (D-5): the `webhooks` (WHK) table is NOT created here — for the Stars launch it
    # folds into the OTX (rail, external_id) index above (successful_payment is order-
    # coupled, so OTX dedupes it directly). The WHK shape (§2.4) lands in its OWN forward
    # migration with the first push-webhook rail (on-chain TON), where a decoupled push
    # event needs ingress dedup the OTX gate cannot give.
  end

  def down do
    # drop the THREE new tables in FK-dependency order (children before parents).
    drop table(:order_transactions)
    drop table(:orders)
    drop table(:packages)
  end
end
```

- **`up` is NON-DESTRUCTIVE — it only creates** the **three** new tables (`D-5`; the `webhooks` table is forward,
  §2.4). No cm.4/cm.5/cm.6 column, index, or CHECK is touched, and **`revenue_ledger` gets ZERO DDL** (`D-1` —
  cm.7 books into it, never alters it). So the **destructive gate** is a **no-op on `up`** — flagged so the
  Director knows cm.7's forward migration drops nothing and the prod cutover carries no at-rest data risk
  (contrast cm.5's `gold_multiplier` `DROP COLUMN`).
- **`down` drops the three new tables in FK-dependency order** (order_transactions → orders → packages — children
  before parents, or the FK blocks the drop). On `codemojex_test`/`codemojex_dev` the reinit is create/drop clean
  (§1). On shipped data `down` would drop accrued orders/receipts — the dev-reset inverse, not a live rollback over
  money (the cm.5/cm.6 posture); a live rollback would be its own runbook. `down` IS a destructive op (it drops
  tables) but is the **reverse** path, never run on `up`.
- **Frozen-migration verification (the gate):** `git diff` on the four shipped migrations
  (`20260618000000_create_codemojex.exs`, `20260625145121_add_player_tg_user_id.exs`,
  `20260626120000_golden_rooms.exs`, `20260627090000_create_revenue_ledger.exs`) must be **empty** — cm.7 only
  adds the new file. The migration **file** count goes **4 → 5** (the one new file creates **three** tables; the
  `webhooks` table is a separate forward migration, `D-5`).
- **The `references/2` `type: :string`** (the codemojex branded-id PK type, `A-8`) is load-bearing — the Ecto
  default is `:bigserial`, which would create an `int8` FK column against a `:string` PK and fail. Every
  `references` above pins `type: :string, column: :id`. **Flag for Mars (F-1).**

### The reinit plan

Per §1: `MIX_ENV=test TMPDIR=/tmp mix ecto.drop && … ecto.create && … ecto.migrate` from the app dir — the new
migration replays after the four shipped ones. The `Ecto.Adapters.SQL.Sandbox` pool makes it a one-time schema
rebuild before the suite. No `*_snapshot` DB exists. `prod` is the Operator's forward `ecto.migrate` (the
non-destructive `up`).

---

## §5 — The booking primitive + the keys-mint + the call sites (the conservation point)

A purchase is a **revenue-recognition + currency-exchange event**: the player's rail funds are EXTERNAL, the
platform receives the GROSS rail amount, **N keys are MINTED to the wallet** (a credit `transactions` row), and
the gross is **booked to `revenue_ledger`** (`account="platform"`, `currency=<rail>`, `reason="purchase"`,
`ref=<ORD id>` — `D-3`). The three writes — the OTX receipt, the keys mint, the revenue booking — fire in **ONE
`Repo.transaction`**, and **only if the OTX insert actually wrote** (the exactly-once gate, §6). This is the cm.5
buy-in shape (a partial-unique-index-gated, atomic, multi-write transaction) applied to purchases.

### The new surface: `Codemojex.KeyShop.settle_payment/1` (NEW, forward-tense — the fulfillment primitive)

The single fulfillment entry point. Given a confirmed provider event, it runs the atomic settlement — and **the
OTX insert IS the exactly-once gate** (`D-5`): for the Stars launch there is no separate WHK ingress step; the
`(rail, external_id)` partial-unique index dedupes the `successful_payment` directly (a replay suppresses the
OTX insert and mints nothing). A future push rail (TON) records + dedupes its decoupled event at the `webhooks`
table first (§2.4), then calls this same primitive:

```elixir
# lib/codemojex/key_shop.ex (NEW). The atomic purchase settlement (cm.7). ONE
# Repo.transaction: insert the OTX receipt with Pattern A (on_conflict :nothing on the
# (rail, external_id) partial unique index, byte-matched to the migration §3 / §2.2); IF
# it wrote (the count-rose check, mirroring insert_buy_in wallet.ex:425-443) THEN mint the
# keys (a players credit) AND book the gross to revenue_ledger (house_post) AND flip the
# order to :paid; ELSE (a replay) mutate NOTHING. The mint + the booking are GATED on the
# OTX insert, so a doubly-delivered/duplicate payment mints once, books once. Returns
# {:ok, :fulfilled} (wrote) | {:ok, :already_fulfilled} (suppressed) | {:error, reason}.
def settle_payment(%{order_id: order_id, rail: rail, external_id: external_id,
                     amount_minor: amount_minor, payload: payload}) do
  Repo.transaction(fn ->
    order = lock_order(order_id)                                  # SELECT ... FOR UPDATE (the per-order serialize)

    cond do
      is_nil(order) -> Repo.rollback(:no_order)
      order.status == "paid" -> :already_fulfilled               # fast idempotency (the order is settled)
      true ->
        case insert_otx(order_id, rail, external_id, amount_minor, payload) do
          :suppressed -> :already_fulfilled                       # the (rail, external_id) dedup fired — mint NOTHING
          :wrote ->
            # 1. MINT the keys (a players credit — always non-negative, A-7) keyed on the ORD id.
            {:ok, _} = Wallet.credit_purchase(order.player, order.keys, order_id)
            # 2. BOOK the gross to the SAME revenue_ledger (D-1/D-3) — account="platform",
            #    currency=the rail, reason="purchase", ref=the order id. ZERO DDL on revenue_ledger.
            Wallet.house_post(Wallet.house_account(), order.currency, amount_minor, "purchase", order_id)
            # 3. FLIP the order to paid (the only money-column-adjacent UPDATE; the price/rate stay pinned).
            mark_paid!(order)
            :fulfilled
        end
    end
  end)
end
```

### The wallet seam: `Wallet.credit_purchase/3` (NEW, or reuse `purchase_keys/3` rebound)

cm.7 needs the keys mint to ride the **caller's** `Repo.transaction` (so it is atomic with the OTX + the
booking), and to key the `transactions` `ref` on the **ORD id** (not the weak `"stars"` literal, `A-4`). Two
options for Mars:

- **(a)** Rebind `Wallet.purchase_keys/3` (`wallet.ex:147`) so its `ref` is always the ORD id and route the
  `game_controller.ex:46` call through `KeyShop`; OR
- **(b)** add `Wallet.credit_purchase/3` (a thin sibling of `credit/5` with `reason="purchase"`) that the
  caller invokes **inside** its transaction, leaving `purchase_keys/3` as the legacy alias deprecated.

Either way the **mint is one signed `transactions` credit row** (the `credit/5` shape, `wallet.ex:383-396`),
non-negative-safe (`A-7`), inside the settlement transaction. **Flag for Mars (F-2):** choose (a) vs (b); the
booking content (one mint row, `ref=ORD`) is identical. The `house_post` call is UNCHANGED (`A-2`, public since
cm.6) — cm.7 is a pure producer into it.

### The booking call — the `D-3` resolution, concretely

```elixir
# the purchase revenue booking (D-3) — the SAME revenue_ledger, ZERO DDL:
Wallet.house_post(
  Wallet.house_account(),   # "platform" — so house_balance() (WHERE account="platform") SEES it (D-3)
  order.currency,           # the rail: "stars" | "ton" | "usdt" | "rub" — the multi-currency seam (cm.6 §8)
  amount_minor,             # the GROSS received, native minor units (V-6/§8) — positive (revenue in)
  "purchase",               # the movement KIND in `reason` (free-text, zero DDL) — distinguishes purchases
  order_id                  # ref = the ORD id (the per-order reconciliation key, replacing "stars")
)
```

### The call sites (keyed to the as-built + the new flow)

| # | Site | Anchor | The cm.7 wiring (forward-tense) | Same txn? |
|---|---|---|---|---|
| 1 | **Order creation** | `game_controller.ex:46` (`Codemojex.purchase_keys(player, keys, "stars")` — the weak surface, `A-4`) | REPLACE with `KeyShop.create_order(player, package_id, rail)` — mints the `ORD`, pins keys/price/rate (`V-7`/`V-8`), issues the rail invoice. Status `created`. NO keys minted yet. | its own txn (insert order) |
| 2 | **Stars invoice** | NONE today (no `pre_checkout`/`successful_payment` — `A-4`) | NEW Telegram invoice flow (`sendInvoice` with the XTR price; the `pre_checkout_query` answered; `successful_payment` → `settle_payment` directly — the OTX `(rail, external_id)` index dedupes the order-coupled confirmation, NO WHK ingress step, `D-5`). cm.7 BUILDS this rail end-to-end. | — (web/bot) |
| 3 | **Payment settlement** | NONE today | NEW `KeyShop.settle_payment/1` — the atomic OTX + mint + `house_post` + `mark_paid` (above), gated on the OTX insert. | **ONE new txn** (§6) |
| 4 | **TON/USDT/RUB settlement** (forward adapters) | NONE today | the SAME `settle_payment/1` — each rail's webhook verifier (the on-chain tx confirmation / the processor callback) lands the `external_id` + `amount_minor` and calls `settle_payment`. cm.7 SHAPES the ORD/OTX rows (rail-stable, `D-6` F4-split); the PUSH rails (TON) ALSO record their decoupled event at the forward `webhooks` table first (`D-5`/§2.4). Each adapter ships as its verifier lands. | the SAME `settle_payment` txn |
| 5 | **Stale-order sweep** | NONE today (cf. `void_if_stale/1` `rooms.ex:447-457`, the games sweep) | NEW (forward) `KeyShop.expire_stale_orders/0` — flip `created` orders past a TTL to `failed` (no money moved; an unpaid invoice expires). Mirrors the cm.5 void sweep posture. | per-order txn |

> **The exactly-once gate is the conservation guarantee** — the mint + the booking BOTH ride the OTX-insert
> result. A duplicate provider event (a re-delivered `successful_payment`, or a re-confirmed tx) hits the
> `(rail, external_id)` partial-unique index, suppresses the OTX insert, and **mints nothing / books nothing**.
> This is the `A-5` buy-in pattern (`insert_buy_in` `:wrote`/`:suppressed`, `wallet.ex:425-443`) applied to
> purchases — crash-safe by construction (the OTX row IS the exactly-once authority, co-located with the mint +
> the booking in one transaction). For the Stars launch this is the SOLE dedup layer (`D-5`); a push rail (TON)
> adds the `webhooks` ingress layer in front for its decoupled events (§2.4).

---

## §6 — The invariants (the rung's correctness contract)

The cm.7 invariants, each grounded in a shipped pattern or a new structural guarantee:

- **INV-EXACTLY-ONCE-PER-RAIL** (the rung's headline — the SOLE dedup at the Stars launch, `D-5`) — a confirmed
  payment fulfils **once**. The `(rail, external_id)` partial unique index (§3) is the authority; `settle_payment`
  inserts the OTX with Pattern A and mints **only if the insert wrote** (§5). N deliveries of the same
  `(rail, external_id)` ⇒ ONE OTX row, ONE keys mint, ONE revenue row. For the Stars rail this gate ALSO subsumes
  ingress dedup (`successful_payment` is order-coupled, deduped here directly — no WHK table at launch).
  *(The `A-5`/`A-4` fix: replaces the `"stars"`-literal double-mint with a DB-enforced per-rail key.)*
- **INV-INGRESS-IDEMPOTENT** (FORWARD — push rails only, `D-5`) — for a PUSH-confirmation rail (on-chain TON), an
  inbound decoupled event is processed **once**: the `(rail, event_id)` unique index on the forward `webhooks`
  table (§2.4) drops a doubly-observed confirmation at ingress, before it is matched to an order and drives the
  settlement (defense in depth with INV-EXACTLY-ONCE-PER-RAIL). **NOT a launch invariant** — the Stars rail's
  exactly-once rests on INV-EXACTLY-ONCE-PER-RAIL alone (the OTX gate keys on the order-coupled `external_id`).
- **INV-ATOMIC-PURCHASE** — the OTX receipt + the keys mint + the revenue booking + the order `:paid` flip are
  **all-or-nothing**: one `Repo.transaction` (§5). A crash between any two leaves **none** committed — never keys
  without revenue, never revenue without keys, never a `paid` order without its receipt.
- **INV-PRICE-PINNED** — a booked order's `price_minor` / `rate_minor` / `keys` are **immutable after creation**
  (`V-7`/`V-8`). A package or rate edit changes **future** orders only; `house_post` books the OTX
  `amount_minor`, which on a clean settlement equals the order's pinned `price_minor`. *(The price analogue of
  cm.6's "balance = sum of immutable rows".)*
- **INV-GROSS-BOOKED** — the FULL gross rail amount received is booked to `revenue_ledger` (`reason="purchase"`,
  `currency=<rail>`), in the rail's native minor unit (`V-6`/§8). No netting at write — the store fee
  (`~32%` mobile / `~3%` desktop, `economy.packages.md`) is a **read-time** deduction (the net-revenue view),
  never a stored lossy row (the cm.6 `D-2` discipline applied to rails).
- **INV-VISIBLE-REVENUE** (`D-3`) — purchase revenue books `account="platform"`, so the shipped
  `house_balance/0..1` (`WHERE account="platform"`) **sees it** and returns it grouped by `currency` with NO read
  change. *(The reconciliation-correctness ruling — booking `account="purchase"` would make it invisible.)*
- **INV-MINT-NON-NEGATIVE** — the keys mint is a `players.keys +=` credit, always non-negative (a mint never
  goes negative), so it sits inside `players` under `players_non_negative` (`A-7`) with no CHECK interaction.

### The conservation-honesty statement (mirroring cm.6 `D-3`/§6 — the purchase double-entry framing)

> **A purchase is a CROSS-BOUNDARY double-entry, not an in-system zero-sum.** The player's rail funds are
> EXTERNAL (they never enter the codemojex ledgers — the platform receives them off-system, at the rail). So a
> purchase has **no internal debit counterparty**: it is **external rail gross IN → keys minted (a `transactions`
> credit) + revenue booked (a `revenue_ledger` credit)**. The balance identity is across the boundary —
> `gross_received_minor (the OTX/order amount) == revenue_booked_minor (the RVL row)` per order, and the keys
> minted are the product delivered for that gross. It is **NOT** `Σ transactions.delta + Σ revenue_ledger.delta =
> 0` (the keys mint is a positive credit with no matching debit — the keys are *created*, the rail value is
> *received externally*). Finance reads: per-order, `gross == booked`; in aggregate, `house_balance()` grouped by
> currency is the gross revenue per rail (the **read-time** net applies the store fee). The keys liability (keys
> minted but unspent) is a separate accounting the in-app economy already tracks via `players.keys` —
> cm.7 does not conflate revenue (the rail gross) with the keys-outstanding liability.

---

## §7 — The reconciliation reads (the rung's queryable payoff)

Two new `KeyShop` reads (and the cm.6 reads, unchanged, now multi-currency), each a clean aggregate keyed on the
branded ids:

```elixir
@doc "A player's purchase history (cm.7) — keyed by the orders_player_index (§3)."
def orders_for(player) do
  Repo.all(from o in Order, where: o.player == ^player, order_by: [desc: o.inserted_at])
end

@doc """
An order's whole money story (cm.7) — the order's pinned price/rate + its OTX receipts +
the revenue row(s) it booked, by the ORD id (the per-order reconciliation key, D-3). The
revenue side reuses the SHIPPED revenue_breakdown-by-ref shape (wallet.ex:351), since
purchase rows carry ref=<ORD id>.
"""
def order_reconciliation(order_id) do
  order = Repo.get(Order, order_id)
  receipts = Repo.all(from t in OrderTransaction, where: t.order_id == ^order_id)        # OTX, by order_id index
  revenue = Wallet.revenue_breakdown(order_id)                                            # the RVL rows, ref=ORD (A-3)
  %{order: order, receipts: receipts, revenue: revenue}
end
```

- **`Wallet.house_balance/0..1` is UNCHANGED and now MULTI-CURRENCY** (`A-3`/`D-3`). Once cm.7 books purchase
  rows it returns `%{"keys" => …, "stars" => …, "ton" => …, "usdt" => …, "rub" => …}` — one exact bucket per
  rail, grouped by `currency`, **NO read change** (the cm.6 §8 seam realized). For finance, the USD/net view is a
  **read-time** roll-up over the buckets (the store-fee deduction per rail + the rate per currency), computed in
  the pure pricing module — never a stored normalized total (the `D-2`/INV-GROSS-BOOKED discipline).
- **`Wallet.revenue_breakdown/1` is UNCHANGED** (`A-3`). Because purchase revenue carries `ref=<ORD id>`,
  `revenue_breakdown(order_id)` returns the order's purchase revenue rows grouped by `reason` (`%{"purchase" =>
  gross}`) — the per-order revenue read, reusing the shipped `(ref)` index with zero DDL.
- **The stale-order reconcile** — `orders WHERE status='created' AND inserted_at < <TTL>` (the
  `orders_status_index`, §3) is the unpaid-invoice sweep (call site 5, §5); the cm.5 `void_if_stale/1`
  (`rooms.ex:447-457`) posture, applied to orders. No money moved — an expired invoice flips `created → failed`.

---

## §8 — Forward-compat: the cm.6 confirm (the minor-unit convention) + the cm.8 withdrawal seam

### §8.1 — The cm.6 forward-compat CONFIRM (the `:bigint` delta holds every rail — the minor-unit convention)

**The question (the brief): does the cm.6 `revenue_ledger` `:bigint` delta + the free-string `currency`
genuinely hold nanoTON (TON, 9 dp) / micro-USDT (6 dp) / kopeck (RUB, 2 dp) / star / key / cent — WITHOUT a
schema change? ANSWER: YES.** The cm.6 schema is **byte-frozen** (`D-1`); cm.7 CONFIRMS it, does not change it.
The minor-unit convention is the pin cm.6 left for cm.7 (`cm.6.postgres.design.md` §8 named `"stars"`/`"cents"`
forward but did not pin the bigint *unit* per currency):

| Rail / unit | `currency` string | minor unit | `1 major = N minor` | decimals | a whale figure | fits `int8` (`9.2e18`)? |
|---|---|---|---|---|---|---|
| Telegram Stars | `"stars"` | star | `1` | 0 (XTR is integer) | `9999` (1000-key pkg) | yes (trivially) |
| Toncoin | `"ton"` | nanoTON | `1_000_000_000` | 9 | `130 TON = 1.3e11` nanoTON | yes (`1.3e11 ≪ 9.2e18`) |
| Tether USD | `"usdt"` | micro-USDT | `1_000_000` | 6 | `130 USDT = 1.3e8` | yes |
| Russian rouble | `"rub"` | kopeck | `100` | 2 | `12000 RUB = 1.2e6` | yes |
| keys (cm.5/cm.6) | `"keys"` | key | `1` | 0 | (Golden cuts) | yes |
| cents (forward) | `"cents"` | cent | `1` | 0 | — | yes |

- **CONFIRM 1 — the width holds.** Even a lifetime of TON revenue at nanoTON scale is far below `int8`'s
  `9.2e18` ceiling (millions of TON = `~1e15` nanoTON, still 3+ orders of magnitude of headroom). The cm-6 `D-8b`
  widening to `:bigint` (over `transactions`' `:integer`) was made **precisely** for this — the cm.6 design
  states the delta "accrues unbounded over the platform's life and a withdrawal-scale figure must not overflow
  `int4`" (`cm.6.postgres.design.md` §2 line 146). **No DDL is owed; the field already holds every rail.**
- **CONFIRM 2 — the free-string `currency` holds the rail.** `revenue_ledger.currency` is free-text
  (`A-1`); booking `"ton"`/`"usdt"`/`"rub"` is one `house_post` call with a new `currency` value — **zero DDL**.
  `house_balance` GROUPs by it (`A-3`); a new currency is a new bucket, no read change.
- **CONFIRM 3 — store EXACT, convert at READ (the `D-2` discipline extended to rails).** Each rail's gross is
  booked in its OWN minor unit, integer-exact — NO normalization at write (a single common-unit total would BAKE
  a rate into the ledger and destroy the audit: you could never re-derive what was actually received). The
  single-number USD view is a **read-time** roll-up (SUM each bucket × its rate), in the pure pricing module —
  exactly the cm.6 keys/💎/¢ pattern (`economy.ex:19,22,25`), never a stored lossy total.
- **THE BUILD-PRECISION PIN (the load-bearing detail Mars wires identically across OTX.amount_minor /
  order.price_minor / RVL.delta):** all three carry the **same** minor unit per currency (the table above). The
  convention lives in a **frozen** `Codemojex.Rails` module (the `V-5`/`V-6` position) as module data
  (`%{"ton" => %{minor: 1_000_000_000, decimals: 9}, …}`), asserted by a **boot vector** (the `branded_id`
  `self_check!` pattern) so a wrong factor is caught at boot, never silently mis-scaling a nanoTON. **A mutable
  decimals column is forbidden** (`V-5` — a money-scaling constant must be frozen, not a row an admin can
  fat-finger).

### §8.2 — The cm.8 withdrawal seam (DESIGN-FOR only — NAME it, do not build it; `D-2`)

cm.8 = the cash-out / treasury rung: withdrawable diamonds → TON / USDT / RUB at floating rates. cm.7's shapes
extend to it cleanly:

- **The house DEBIT — a NEGATIVE `revenue_ledger.delta`.** A withdrawal is the inverse of a purchase: the
  platform pays out, so it books a **negative** `delta` to the SAME `revenue_ledger` (`account="platform"`,
  `currency=<rail>`, `reason="withdrawal"`, `ref=<the withdrawal id, a new WDR/cm.8 brand>`), in the rail's
  native minor unit (§8.1). The `revenue_ledger.delta` is **already signed with no CHECK** (`A-1`/`D-1`) — it
  admits the debit **by construction** (the same property that admits the cm.6 `deposit_seed` debit). `house_post`
  books it with ZERO DDL: `house_post("platform", "ton", -payout_nanoton, "withdrawal", wdr_id)`. So
  `house_balance()` nets purchases (positive) against withdrawals (negative) per currency — the platform's true
  per-rail position.
- **The diamonds → rail conversion-rate READ + the rate-pinning SHARED with F3/`V-8`.** A withdrawal converts
  diamonds (the in-app prize currency, `10:1 → keys` today) to a rail at a **floating** rate. The rate-pinning
  shape cm.7 builds (`D-4`) — `rate_minor` + `rate_pair` + `rate_source` + `rate_quoted_at` pinned on the order — is the
  EXACT shape a `withdrawals` row pins (the diamonds→rail rate at request time, so a booked payout is
  reproducible). cm.7's `rate_source="config"` launch + the named `rates`/`quotes` table upgrade (`V-8`) is where
  cm.8's floating rates land: the withdrawal volume + the regulatory audit justify the rates table THERE.
- **What cm.7 does NOT build (the `D-2` quarantine):** the `withdrawals` table (a `WDR` brand), the
  diamonds-debit + locked-diamonds interaction (`players.locked_diamonds`, `player.ex:21`), KYC/AML, the 21-day
  hold (`economy.packages.md`), fraud, and the actual payout execution. cm.7 ensures the **revenue_ledger booking
  shape** (signed delta, per-rail currency, minor units) and the **rate-pinning shape** extend to cm.8 — and
  stops there.

### §8.3 — The cm.6 schema confirm (BYTE-FROZEN — confirm, do not change)

cm.7 makes **ZERO** edits to `schemas/revenue_ledger.ex` or `20260627090000_create_revenue_ledger.exs` (`D-1`,
`A-9`). The frozen-migration `git diff` gate (§4) covers it — the cm.6 migration must be byte-unchanged. The
multi-currency seam was DESIGNED into cm.6 (`account`/`currency` dimensioned, `house_post`/`house_balance`
currency-agnostic); cm.7 is the producer that REALIZES it, adding no column, no index, no read change to the
ledger.

---

## §9 — The gate ladder (codemojex, from the app dir)

Re-probe `asdf current` / `.tool-versions` from `echo/apps/codemojex` (do not hardcode the toolchain — Elixir
1.18.4 / OTP 28.5.0.1 at last probe, but re-verify); the per-app ladder:

```bash
cd /Users/jonny/dev/jonnify/echo/apps/codemojex
asdf current                                         # re-probe; do not hardcode
valkey-cli -p 6390 ping                              # -> PONG (the bot/store lanes need Valkey)
# Postgres up + codemojex_test reinit (§1):
MIX_ENV=test TMPDIR=/tmp mix ecto.drop && MIX_ENV=test TMPDIR=/tmp mix ecto.create && MIX_ENV=test TMPDIR=/tmp mix ecto.migrate
TMPDIR=/tmp mix compile --warnings-as-errors          # the clean-compile gate
TMPDIR=/tmp mix test --include valkey                 # the cm.7 KeyShop stories + the cm.5/cm.6 suite green untouched
# the migration up/down round-trip + a fresh reinit (the FK-order drop, §4)
```

- **The frozen-migration `git diff` is empty** (the FOUR shipped migrations, §4) — cm.7 only adds the new file;
  the migration **file** count goes 4 → 5 (the new file creates **three** tables; `webhooks` is forward, `D-5`).
- **The ≥100 determinism loop is MANDATORY** — cm.7 mints **multiple** branded ids on the Stars settlement hot
  path (`ORD` at order creation; `OTX` + `RVL` + `TXN` at settlement — three mints in the one settlement
  transaction), so the same-millisecond branded-id mint hazard (the BCS id contention the cm.6 design names,
  `cm.6.postgres.design.md` §9) applies — **more mints per purchase than cm.6's per-buy-in pair.** (A future push
  rail adds a `WHK` mint at ingress, off this launch path.) Ratify with the repeated full-suite loop,
  reinit-per-iter:

  ```bash
  cd /Users/jonny/dev/jonnify/echo/apps/codemojex
  for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break; done
  ```

  A multi-seed sweep alone is **insufficient** (re-seeding does not reproduce same-ms mint contention). The loop
  is the cm.5/cm.6 precedent, now over a heavier mint path.
- **The exactly-once probe (adversarial — the rung's correctness core):** a test that calls `settle_payment`
  TWICE with the same `(rail, external_id)` (a re-delivered `successful_payment`) must mint keys ONCE, book
  revenue ONCE, leave ONE OTX row — the INV-EXACTLY-ONCE-PER-RAIL gate (the SOLE dedup at the Stars launch,
  `D-5`). The net-zero mutation spot-check: removing the `(rail, external_id)` UNIQUE (or the `on_conflict` guard)
  MUST make this probe fail. The cm.5 buy-in double-charge test is the template.
- **The boundary** is **⊆ `echo/apps/codemojex/**` + the rung docs**; `mix.lock` untouched (the existing Ecto /
  `exqlite` stack — no new dep). No sibling umbrella app.

---

## §10 — Build-precision flags + the coordination contracts (what Mars wires both sides of)

**Build-precision flags (Mars — the load-bearing details).**

- **F-1 — Every `references/2` pins `type: :string, column: :id`** (§4). The codemojex PKs are `:string`
  branded snowflakes (`A-8`); the Ecto `references` default is `:bigserial`, which would create an `int8` FK
  against a `:string` PK and FAIL the migration. cm.7 INTRODUCES the first real FKs in the codemojex schema
  (cm.5 relates by `ref` string, no FK) — confirm each FK column type at build.
- **F-2 — The keys mint rides the SETTLEMENT transaction, `ref = the ORD id`** (§5). Choose `Wallet.credit_purchase/3`
  (new) vs rebinding `purchase_keys/3` (`wallet.ex:147`); either way the mint is ONE `transactions` credit row
  inside `settle_payment`'s `Repo.transaction`, keyed on the ORD id — NEVER the weak `"stars"` literal
  (`game_controller.ex:46`, `A-4`). Do NOT mint outside the settlement transaction (it would break
  INV-ATOMIC-PURCHASE).
- **F-3 — The `(rail, external_id)` conflict_target fragment is BYTE-MATCHED to the partial index `where:`**
  (§3/§5). `KeyShop.insert_otx` uses Pattern A — `on_conflict: :nothing, conflict_target:
  {:unsafe_fragment, "(rail, external_id) WHERE external_id IS NOT NULL"}` — and the fragment must equal the
  migration's `where:` predicate byte-for-byte (the cm.5 `insert_buy_in` discipline, `wallet.ex:438-441`). The
  `:wrote`/`:suppressed` decision is the **count-rose** check (re-count after the insert), NOT the returned
  struct (Pattern A returns a `:loaded` struct carrying the minted id even when suppressed — the
  `resolve_by_tg`/`insert_buy_in` trap, `wallet.ex:84-90,425-443`).
- **F-4 — `house_post` is UNCHANGED; cm.7 is a pure producer** (`A-2`/`D-1`/`D-3`). Book
  `house_post("platform", order.currency, amount_minor, "purchase", order_id)` — `account="platform"` (so
  `house_balance` sees it, `D-3`), `currency=`the rail (the multi-currency seam), `reason="purchase"`,
  `ref=`the ORD id. NO edit to `revenue_ledger.ex` or its migration (the frozen-diff gate, §4).
- **F-5 — The minor-unit convention is FROZEN module data + a boot vector** (§8.1/`V-6`). `Codemojex.Rails`
  (new) holds `%{"stars" => %{minor: 1, decimals: 0}, "ton" => %{minor: 1_000_000_000, decimals: 9}, "usdt" =>
  %{minor: 1_000_000, decimals: 6}, "rub" => %{minor: 100, decimals: 2}}`, asserted at boot (the
  `branded_id.self_check!` pattern). `order.price_minor`, `OTX.amount_minor`, `RVL.delta` ALL carry the same
  unit per currency. A mutable decimals column is forbidden (a money-scaling constant must be frozen).
- **F-6 — The PKG/ORD/OTX brands parse with zero registration** (`A-8`). `generate!("PKG")` / `generate!("ORD")`
  / `generate!("OTX")` — any `[A-Z]{3}` is valid (`branded_id.ex:143`); no registry edit, no migration (exactly as
  `RVL` in cm.6). Confirm each parses at build. (The `WHK` brand is reserved for the forward push-rail table,
  `D-5`/§2.4 — not minted this rung.)
- **F-7 — The rate is PINNED on the order, never re-read** (`V-8`/§2.3). `rate_minor` + `rate_pair` +
  `rate_source` + `rate_quoted_at` are set ONCE at order creation; settlement reads `order.price_minor` (already
  derived from the pin), never re-derives from a live rate. A config-rate launch labels `rate_source="config"`.
- **F-8 — Amounts are integer minor units, NEVER floats** (§8.1). No float money math anywhere — `price_minor`,
  `amount_minor`, `rate_minor` are `:bigint` integers; the rate is a minor-unit-scaled integer
  (`stars_per_ton`), the derivation `div`/`*` integer arithmetic (the `economy.ex` floor-before-×10 discipline).

**The coordination contracts (what Mars wires identically on both the relational + the triad side).** This
relational design and Venus-Triad's `cm.7.{md,stories.md,llms.md}` are authored in parallel from the same
locked-constraints brief (blind); they meet at these contracts:

1. **The THREE-table column set + the PKG/ORD/OTX brands** (§2; the `webhooks` WHK table is FORWARD, `D-5`) — the
   triad's schema references must name these columns; the changesets require the §2 fields. **The triad must NOT
   list `webhooks` among the built migration tables** — it folds into OTX for the Stars launch (a Venus-Triad
   reconcile point; see the note at the end of §10).
2. **The `(rail, external_id)` partial-unique exactly-once authority** (§3/§6) — the SOLE dedup at the Stars
   launch (`D-5`); the triad's INV-EXACTLY-ONCE-PER-RAIL story asserts on a re-delivered `successful_payment`
   (same `(rail, external_id)`), not on raw OTX rows, and does not assert a separate WHK-ingress layer for Stars.
3. **The `D-3` booking convention** (§5) — `house_post("platform", <rail>, gross_minor, "purchase", order_id)`;
   the triad's stories assert on `house_balance`/`revenue_breakdown`, and carry the `D-3` rationale (visible
   revenue). **Without `D-3` the rung books revenue the shipped `house_balance` cannot see.**
4. **The conservation-honesty statement** (§6) — the triad must carry it verbatim (a purchase is a cross-boundary
   double-entry: external gross IN → keys + revenue, NOT `Σ-rows=0`; the keys-liability is separate from
   revenue). **Without it the rung's "balance" is mis-read.**
5. **The minor-unit convention table** (§8.1) — `currency` carries native minor units (nanoTON/micro-USDT/
   kopeck/star); `house_balance` returns a per-currency map; the convention is frozen module data + a boot vector.
6. **The cm.8 withdrawal seam** (§8.2) — the signed `house_post` debit + the shared rate-pin shape; cm.7
   DESIGNS-FOR it, BUILDS none of it.

**Constraints this design surfaced but could NOT fully ground (flagged, not invented):**

- **The exact Stars→keys derivation for the TON/USDT/RUB rails** — `economy.packages.md` gives the Stars ladder
  + the `200 Stars = 1 TON` Telegram-fixed peg + the `~$0.013`/Star face, but the precise per-rail price formula
  (the rounding rule from a base Stars price to a pinned nanoTON/kopeck) is a pricing-module choice Venus-Triad +
  the Operator pin; this design pins WHERE the result is stored (`order.price_minor`, native minor units) and
  that it is integer-exact, not the exact formula.
- **The `rate_source` config shape for cm.7 launch** — `D-4` (RULED) sets `config` for launch (a `key_shop_rates`
  map in `runtime.exs`) with a named `rates`/`quotes` table upgrade at cm.8; the exact config-map shape is a
  `runtime.exs` detail the Operator sets. The design pins the ORDER's rate-provenance columns
  (`rate_source`/`rate_quoted_at`), not the config map's keys.
- **The Telegram invoice API specifics** (`sendInvoice`/`answerPreCheckoutQuery`/`successful_payment` field
  names) — cm.7 BUILDS the Stars rail, but the exact ex_gram/Telegram Bot API call shapes are a web-layer detail
  Mars wires at build (the `telegram.ex:6` injectable-transport pattern); this design pins the OTX `external_id`
  = the `telegram_payment_charge_id` and the `raw_payload` = the verbatim `successful_payment`.

**RESOLVED by the Operator's rulings (no longer open):**

- **The WHK durability fork** (was: Postgres table vs Valkey-NX vs fold-into-OTX) — **RULED `D-5`: WHK folds into
  the OTX `(rail, external_id)` index for the Stars launch** (pull-confirmation, deduped on the order-coupled
  `external_id` directly); the dedicated `webhooks` Postgres table is the named FORWARD for the first
  push-webhook rail (TON). The WHK-as-table-now (this lens's `V-9`) is the Option-A+ variant, NOT ruled in (§2.4).
- **The rate SOURCE divergence** (was: this lens's provenance-columns-+-earlier-rates-table vs the product lens's
  config-only) — **RULED `D-4`: config-launch + the `rate_source`/`rate_quoted_at` provenance columns on the
  order** (this lens's `V-8` synthesis); the rates/quotes history table is the cm.8 upgrade.

> **A Venus-Triad reconcile flag (for the Director).** This relational design now reads `D-5` as ruled (three
> built tables; WHK folds into OTX; the `webhooks` table is forward). Venus-Triad's `cm.7.md` was authored when
> WHK was still framed as a built table (its §6c describes WHK recording an event "before it drives ORD/OTX", and
> its Acceptance A10/A11 list `webhooks` among the built migration tables + the per-call mints). **The triad needs
> the same `D-5` reconcile** — `webhooks` out of the built-table set, the Stars exactly-once resting on the OTX
> gate alone, WHK named forward for push rails. Flagged so the two deliverables converge before Mars builds.

## References (grounding)

- **The rulings (the contract):** cm-7 ledger `{cm-7-decisions}` `D-1`..`D-6`
  (`docs/codemojex/specs/progress/cm-7.progress.md`) — `D-1`/`D-2` (cm.6 ships as-built / cm.7 = pay-in only),
  `D-3` (the `account="platform"` booking, ratified), `D-4` (config-launch rate source + provenance columns),
  `D-5` (Stars end-to-end + WHK folds into OTX), `D-6` (the F1/F2/F4-split/F5/F3-pin convergence). cm.6 ships
  as-built / `revenue_ledger` byte-frozen,
  cm.7 = multi-rail pay-in only / cm.8 = withdrawals, the `account="platform"` + `reason="purchase"` booking
  convention. The fork positions `V-5`..`V-9` (this lens) + `V-1`..`V-4` (the product lens).
- **The cm.6 template + the frozen ledger:** `docs/codemojex/specs/cm.6.postgres.design.md` (the relational-design
  structure §0..§10; §2 the `revenue_ledger` columns; §5 `house_post`; §8 the multi-currency seam naming
  `"stars"`/`"cents"` forward); `schemas/revenue_ledger.ex` (the byte-frozen schema); `priv/repo/migrations/
  20260627090000_create_revenue_ledger.exs` (the byte-frozen migration; line 18 names `"stars"`/`"cents"`
  forward).
- **The exactly-once pattern (the rung's core):** `priv/repo/migrations/20260626120000_golden_rooms.exs:73-76`
  (`transactions_buy_in_once_index` — the partial unique index); `lib/codemojex/wallet.ex:425-443`
  (`insert_buy_in` — Pattern A + the count-rose `:wrote`/`:suppressed`); `lib/codemojex/schemas/transaction.ex:26`
  (the changeset DB-error → changeset-error bridge).
- **The weak surface cm.7 replaces:** `lib/codemojex/wallet.ex:147` (`purchase_keys/3` — bare credit, no booking,
  no exactly-once); `lib/codemojex_web/controllers/game_controller.ex:46` (the `params["ref"] || "stars"` literal —
  the double-mint hazard).
- **The booking + mint primitives:** `lib/codemojex/wallet.ex:482-498` (`house_post/5` — the producer seam, public,
  zero DDL); `:325-336` (`house_balance/0..1` — `WHERE account="platform" GROUP BY currency`, the `D-3` visibility
  constraint); `:351-360` (`revenue_breakdown/1` — `WHERE ref GROUP BY reason`); `:383-396` (`credit/5` — the mint
  shape); `:22` (`@house "platform"`), `:303-304` (`house_account/0`).
- **The economy + pricing input:** `lib/codemojex/economy.ex:10-11` (`@diamonds_per_key 10`,
  `@cents_per_diamond 1.2`), `:19,22,25` (`diamonds_for_keys`/`to_cents`/`to_usd` — the read-time converters,
  the `D-2` store-exact-convert-at-read pattern); `docs/codemojex/specs/economy/economy.packages.md` (the Stars
  ladder + discounts, `200 Stars = 1 TON`, `~$0.013`/Star, `~32%` mobile / `~3%` desktop fee, the 21-day hold).
- **The branded-id contract:** `echo/apps/echo_data/lib/echo_data/branded_id.ex:93` (`generate!(ns)`), `:143`
  (`valid_ns?` — any `[A-Z]{3}`, zero registration); the PKG/ORD/OTX/WHK brands.
- **The schema idioms to mirror:** `schemas/transaction.ex:6-15` (the append-only row); `schemas/player.ex:43-47`
  (`guard/1`/`players_non_negative` — the mint sits inside it); `schemas/game.ex` (the snapshotted levers).
- **The migration idioms:** `priv/repo/migrations/20260626120000_golden_rooms.exs` (`:bigint` money, explicit
  up/down, the `games_status` CHECK `:17-20`, the `rooms_revenue_pct_range` nullable-aware CHECK `:51-54`, the
  partial unique index `:73-76`).
- **The byte-frozen migrations (the 4 → 5 freeze gate, §4):** `20260618000000_create_codemojex.exs`,
  `20260625145121_add_player_tg_user_id.exs`, `20260626120000_golden_rooms.exs`,
  `20260627090000_create_revenue_ledger.exs`.
- **Config:** `echo/config/test.exs` (`codemojex_test`), `echo/config/dev.exs` (`codemojex_dev`),
  `echo/config/runtime.exs` (`prod`, the Operator's deploy; the `key_shop_rates` config seam, `V-8`).
