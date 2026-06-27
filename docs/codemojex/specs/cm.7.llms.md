# cm.7 — The KeyShop · agent brief (compact)

> The one-screen brief, derived from [`cm.7.md`](./cm.7.md) (the body wins). **RULED build-grade brief** — the
> design phase is closed (`cm-7` `D-1`..`D-6`). Acceptance: [`cm.7.stories.md`](./cm.7.stories.md). Relational
> contract: [`cm.7.postgres.design.md`](./cm.7.postgres.design.md). Framing: third person; no
> first-person-agent narration; no perceptual / interior-state verbs.

## What

The **KeyShop**: a real multi-rail key-purchase flow replacing the weak `Wallet.purchase_keys/3`
(`wallet.ex:147`) + `game_controller.ex:46` (`params["ref"] || "stars"`, no exactly-once → **double-mint on
replay**). A player picks a `PKG` package; an `ORD` order is created with the rail, the price **pinned in the
rail's minor unit**, and the **rate + provenance snapshotted** (`D-4`); the gross rail amount settles
**externally**; the rail's payment is recorded **exactly-once** as `OTX` (the **partial unique index `(rail,
external_id) WHERE external_id IS NOT NULL`**); on confirmation, `KeyShop.settle_payment/1` runs **one
`Repo.transaction` gated on the `OTX` insert** — the keys are **minted** (`TXN` credit, `ref=ORD`) and the
**gross is booked** to the **same `revenue_ledger`** cm.6 founded (`Wallet.house_post`, **`account="platform"`,
`reason="purchase"`, `currency=`the rail — `D-3`**). The frozen `Codemojex.Rails` module holds the per-rail
facts; the pure `Codemojex.KeyShop` module is the price/net-revenue/store-fee math. Stars built end-to-end;
TON/USDT/RUB schema-shaped (`D-5`); `WHK` folds into the `OTX` gate for the Stars launch (a forward table).

## References (read first)

- **The contract it extends:** [`cm.6.md`](./cm.6.md) (esp. [§ Forward: the multi-currency ledger](./cm.6.md) +
  `D-5` + S11) — the **same** `revenue_ledger`, no second store. `cm.6` code is **byte-frozen** (`D-1`).
- **The pricing input:** [`economy/economy.packages.md`](./economy/economy.packages.md) — the Stars ladder
  (5=99⭐ … 1000=9999⭐, 0–50% discount), ~$0.013/⭐, ~32% mobile / ~3% desktop store fee, 200⭐ = 1 TON (TON
  floats), the live `stars_usd_rate`.
- **The roadmap:** [`codemojex.roadmap.md`](./codemojex.roadmap.md) §Commerce + §branded-namespaces (PKG/ORD/
  OTX/WHK; "OTX kept separate from TXN").
- **The as-built money surface:** `Wallet.house_post/5` (`wallet.ex:482`), `book_house/5` (`:313`),
  `house_balance/0..1` (`:325` — `SUM(delta) GROUP BY currency`), `credit/5` (`:383`, no exactly-once),
  `buy_in/2` (`:208`, the exactly-once `on_conflict` idiom to mirror); `Economy` (`economy.ex` — read-time
  conversions; **do not edit**); the `revenue_ledger.ex` schema (cm.6, frozen).
- **The styling model:** [`cm.6.md`](./cm.6.md) / [`cm.4.md`](./cm.4.md) (the ruled-brief shape).

## The five forks — RULED (`cm-7` `D-3`..`D-6`; the two lenses converged, the Operator ruled the divergences)

- **F1 rail abstraction** (`D-6`) → a bare `rail` discriminator STRING on the order/OTX/RVL + the per-rail facts
  as **frozen data in `Codemojex.Rails`** (a `self_check!` boot vector); **no `rails` table, no mutable
  `decimals` column**.
- **F2 package pricing** (`D-6`) → one base (Stars) price on the package + a rate-derived per-rail amount
  **pinned + frozen on the order** at creation, **+ a nullable per-rail override** column; discounts live
  **once** in the base ladder.
- **F3 rate** (`D-6` pin + `D-4` source) → the rate **PINNED on the order at creation** + `rate_source` /
  `rate_quoted_at` **provenance columns**; launch **source = config** (`key_shop_rates` in runtime.exs); the
  `rates` table is **cm.8**.
- **F4 order/payment** (`D-6` + `D-5`) → one `orders` table + a `rail` discriminator + one `OTX` (the **partial
  unique index `(rail, external_id) WHERE external_id IS NOT NULL`** = the gate); **`WHK` folds into the `OTX`
  gate for the Stars launch** (a forward `webhooks` table for the first push rail); **not** per-rail tables.
- **F5 minor-unit** (`D-6`) → store each rail's amount in its **native minor unit, integer-exact** (star /
  nanoTON 1e9 / micro-USDT 1e6 / kopeck 100) in the `:bigint` `delta`; **no normalization at write**; USD
  roll-up read-time.
- **The booking convention** (`D-3`) → `house_post(account="platform", currency=<rail>, +gross, reason=
  "purchase", ref=ORD)` — so the shipped `house_balance` (`WHERE account="platform"`) **SEES** the revenue;
  `account="purchase"` would hide it.

## Requirements (each → a story → an invariant)

1. The frozen `Codemojex.Rails` (the per-rail facts + the minor-unit table + `self_check!`) + the pure
   `Codemojex.KeyShop` pricing — `price_minor/3`, `net_revenue/3`, `usd_face_cents/2`; discounts in the base
   ladder. → S5 / A5. (`D-6` F1/F2/F5.)
2. The `PKG` packages catalog (DB-stored, editable — `enabled`/`sort`/nullable per-rail overrides) +
   `Codemojex.key_packages/0`. → S8 / A8. (Venus-Postgres.)
3. The `ORD`/`OTX` order model — one orders table + a `rail` discriminator; the `OTX` **partial unique index
   `(rail, external_id)`**; `WHK` folds into it for launch (a forward table). → S1, S2, S7 / A1, A2.
   (Venus-Postgres.)
4. The rate snapshot + provenance pinned on the `ORD` (`price_minor` + `rate_minor`/`rate_pair`/`rate_source`/
   `rate_quoted_at`), read once from config at creation. → S4 / A4. (`D-4`.)
5. The Stars rail end-to-end — the Telegram XTR invoice flow (invoice → `pre_checkout` (tamper guard) →
   `successful_payment` → `settle_payment/1`). → S2, S3, S7 / A2, A3, A7. (`D-5`.)
6. The fulfilment primitive `KeyShop.settle_payment/1` — OTX-gated, one `Repo.transaction`: insert `OTX` + mint
   `TXN` keys (`ref=ORD`) + book `RVL` gross (`house_post(Wallet.house_account(), order.currency, amount_minor,
   "purchase", order_id)` — `account="platform"`, `D-3`) + flip `ORD → paid`. → S1, S2, S3, S3b / A1, A2, A3,
   A8b.
7. The cutover — retire the client-supplied key-count/ref; mint only via `settle_payment/1`. → S6 / A6.
8. The shaped rails — ORD/OTX/PKG shapes proven rail-stable for TON/USDT/RUB (forward verifier adapters). →
   S3, S12 / A3. (`D-5`.)
9. The migrations + the gate ladder + the stories; cm.6 byte-frozen. → S9, S10, S11 / A9, A10, A11.

## Execution topology + build order (smallest-change first)

1. **Venus-Postgres** authors [`cm.7.postgres.design.md`](./cm.7.postgres.design.md) + the **one** additive
   migration (the 5th) creating `packages` · `order_transactions` · `orders` (+ the `webhooks` forward table)
   + the schemas; the `OTX` **partial unique index `(rail, external_id) WHERE external_id IS NOT NULL`** + the
   FKs (`references type: :string` — the branded-PK gotcha).
2. **`Codemojex.Rails`** (pure, frozen): the `@rails` minor-unit map + `factor/1` / `decimals/1` / `self_check!`
   (the boot vector). Then **`Codemojex.KeyShop`** pricing (pure — no Repo/HTTP): `price_minor/3` (Stars
   verbatim; others rate-derived or override), `net_revenue/3`, `usd_face_cents/2`. Unit-tested first.
3. **The catalog read** — `Codemojex.key_packages/0` (`enabled`, sorted); seed the launch ladder.
4. **Create-order** — `KeyShop.create_order(player, package_id, rail)`: price via `KeyShop`, **pin**
   `price_minor` + the rate snapshot (`rate_minor`/`rate_pair`/`rate_source`/`rate_quoted_at`), insert `ORD`
   (`created`); the route takes `{package_id, rail}` only.
5. **The Stars rail** — `sendInvoice` (XTR, the `ORD` id as payload); `pre_checkout_query` (re-validate
   `created` + the pinned `price_minor`, fail-closed); `successful_payment` → `settle_payment/1`.
6. **`settle_payment/1`** — one `Repo.transaction` under a `FOR UPDATE` order lock: insert `OTX` (Pattern A,
   gated on the partial unique index) → IF wrote: mint the `TXN` keys (`ref=ORD`) + book the `RVL` gross
   (`house_post`, `account="platform"`) + `ORD → paid`; ELSE a replay no-ops.
7. **The cutover** — retire `buy_keys`'s direct key-count path / `Wallet.purchase_keys/3` as a public surface.
8. **The stories** + the determinism loop; `mix codemojex.stories` regenerates the faces.

**Files** (boundary `echo/apps/codemojex/**` + the rung docs): `lib/codemojex/rails.ex` (new) ·
`lib/codemojex/key_shop.ex` (new — pricing + `create_order`/`settle_payment`) ·
`lib/codemojex/schemas/{package,order,order_transaction,webhook}.ex` (new, Venus-Postgres; `webhook.ex` the
forward schema) · `lib/codemojex/wallet.ex` (the mint seam `credit_purchase/3` or `purchase_keys/3` rebound —
**additive**; cm.6 sites + `house_post/5` frozen) · `lib/codemojex/game.ex` (the facade) ·
`lib/codemojex_web/controllers/{game_controller,telegram_controller}.ex` · `lib/codemojex_web/router.ex` ·
`priv/repo/migrations/<×1>` (Venus-Postgres) · `config/runtime.exs` (`key_shop_rates`) · `test/…`.

## Cite-map (every public call → its real module)

| Call | Module / site |
|---|---|
| book the gross (`account="platform"`, `D-3`) | `Wallet.house_post/5` (`wallet.ex:482`) / `book_house/5` (`:313`) — **no new verb**; `Wallet.house_account/0` (`:303`) = `"platform"` |
| the reconciliation read | `Wallet.house_balance/0..1` (`wallet.ex:325`, `WHERE account="platform"`) — **no change**, new currency buckets appear |
| the exactly-once idiom | `Wallet.buy_in/2` (`wallet.ex:208`) / `insert_buy_in` (`wallet.ex:425-443`) — `on_conflict: :nothing` + the count-rose check on the partial unique index (`golden_rooms.exs:73-76`) |
| the brand mint | `EchoData.BrandedId.generate!("PKG"/"ORD"/"OTX"/"WHK")` |
| the player credit (mint) | `Wallet.credit_purchase/3` (new) **or** `purchase_keys/3` rebound (`wallet.ex:147`), `ref=ORD` — mirrors `credit/5` (`wallet.ex:383`), inside `settle_payment/1`'s txn (Venus-Postgres §5 F-2) |
| the read-time USD | `Economy.to_cents`/`to_usd` (`economy.ex:22`/`:25`) — pattern for `KeyShop`, **do not edit `Economy`** |
| the webhook in | `CodemojexWeb.TelegramController` (the as-built) — + `pre_checkout`/`successful_payment` |
| JSON | `:jason` (declared `mix.exs:58`) — the OTX `raw_payload` codec, **zero new dep** |

## Gate ladder (per-app, from `echo/apps/codemojex`)

`asdf current` / `.tool-versions` (re-probe) · `valkey-cli -p 6390 ping` → `PONG` · `pg_isready` ·
`TMPDIR=/tmp mix compile --warnings-as-errors` · `TMPDIR=/tmp mix test --include valkey` (boots Valkey 6390 +
Postgres) · the migration up/down + fresh reinit (DB name from `config/test.exs`, surfaced before the drop) ·
the **≥100 determinism loop** (`for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break;
done` — the multi-mint hazard) · cm.6 byte-frozen (`git diff --stat` empty over `revenue_ledger.ex` / the cm.6
migration / the cm.6 booking sites) · the cm.4/cm.5/cm.6 suites green · boundary ⊆ `echo/apps/codemojex/**` +
the rung docs · `mix.lock` untouched · Apollo BUILD-GRADE (money-critical, §11.2).
