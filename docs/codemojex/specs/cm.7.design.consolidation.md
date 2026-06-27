# cm.7 — The KeyShop: the Director's consolidation (the staged dual-architect debate)

> The Director-CONSOLIDATOR synthesis of the **blind** dual-architect pass on the cm.7 KeyShop (multi-rail
> key pay-in). Two architects argued the same five forks from divergent lenses, neither reading the other's
> deliverable until both landed:
> - **Venus** — the *product / flow / minimal-surface* lens → the cm.6 reconcile note + the cm.7 triad
>   ([`cm.7.md`](./cm.7.md) / [`.stories.md`](./cm.7.stories.md) / [`.llms.md`](./cm.7.llms.md)) + the roadmap
>   reconcile; fork positions `V-1`..`V-4`, `V-6`, `V-10`..`V-12` (`cm-7.progress.md`).
> - **Venus-Postgres** — the *payments-integrity / relational / reconciliation* lens →
>   [`cm.7.postgres.design.md`](./cm.7.postgres.design.md); fork positions `V-5`, `V-7`, `V-8`, `V-9`.
>
> This document **stages the disagreement** — it does not average it. The locked scope is `cm-7` ledger `D-1`
> (cm.6 ships as-built, byte-frozen) / `D-2` (cm.7 = pay-in only; cm.8 = withdrawals). The Operator rules the
> two open forks below; the convergences are recommended for lock.

## The headline — high convergence

Two lenses that exist to disagree **converged on four of the five forks**, the rate pin-location, and the
booking correctness. That convergence is the strongest available signal those forks are settled. The KeyShop
that falls out is **almost entirely additive composition over shipped cm.5 / cm.6 seams**: it reuses
`Wallet.house_post/5` (zero DDL on the revenue ledger), the cm.5 buy-in partial-unique-index as the exactly-once
gate, and `house_balance`'s existing per-currency `GROUP BY`. The genuinely open questions are narrow and
audit-shaped.

---

## CONVERGED — recommend lock (both lenses, not contested)

- **F1 · the rail abstraction → a bare `rail` discriminator string, NOT a rails table.** Venus Arm B = VenusPG
  Arm A. The four rails (`stars` / `ton` / `usdt` / `rub`) are a closed, code-known set; the per-rail facts
  (minor unit, decimals, store-fee) live in a **frozen `Codemojex.Rails` module**, asserted by a boot vector
  (the `branded_id.self_check!` pattern), **never a mutable `decimals` column** — VenusPG's load-bearing point:
  a money-scaling constant an admin could fat-finger silently mis-scales every nanoTON. The order carries the
  rail as a typed string (the brand-is-the-type discipline applied to currency). A runtime rail-registry is a
  named cm.8+ forward, not an audit gap.
- **F2 · package pricing → one base (Stars) price + a rate-derived per-rail amount, PINNED on the order.** Both
  Arm B. The discount ladder (`economy.packages.md`) lives **once** in the base; the per-rail price is derived at
  order creation and **frozen on the order row** (VenusPG's immutability rule: the package is a *template*, the
  order holds the authoritative money — editing a package never rewrites a booked order, the price analogue of
  cm.6's "balance = sum of immutable rows"). A nullable per-rail **override** column is admitted for round-number
  rails (RUB), itself pinned-on-order at creation.
- **F4 · the table split → ONE `orders` (ORD) + ONE `order_transactions` (OTX); per-rail tables rejected.** Both
  Arm A — the order *lifecycle* is rail-independent; the rail-specific bytes are one OTX row + a verbatim jsonb
  payload. The **exactly-once authority is a partial unique index `(rail, external_id)`** — the exact shipped
  `transactions_buy_in_once_index` pattern (`golden_rooms:73-76`), the named fix for today's `"stars"`-literal
  double-mint (`game_controller.ex:46`). A purchase confirmation = **three rows in one `Repo.transaction`**: the
  OTX receipt (the rail), the TXN keys mint (the wallet credit), the RVL revenue (`house_post`) — each fires
  **once**, gated on the OTX insert (the conservation point; the count-rose check of `insert_buy_in`). *(The
  apparent roadmap "OTX separate from TXN" vs cm.6 "book to the same RVL" conflict is resolved by Venus L-1:
  three rows, three concerns, one event — OTX is the receipt, TXN the player credit, RVL the platform revenue.)*
- **F5 · the minor-unit convention → native minor unit per currency, integer-exact, store-exact-convert-at-read.**
  Both Arm A. `stars`=star (0dp), `ton`=nanoTON (1e9), `usdt`=micro-USDT (1e6), `rub`=kopeck (100), `keys`/`cents`
  internal. The `:bigint` delta holds it with orders of magnitude of headroom (a 130-TON whale = 1.3e11 nanoTON ≪
  9.2e18). **No per-row decimals column** (a derivable constant invites drift); the convention is a pinned spec
  table + the frozen `Rails` module. This is cm.6's `D-2` keys-exactness discipline generalized to rails —
  normalize-at-write would bake a rate into the ledger and destroy the audit.
- **F3 · the rate PIN LOCATION → on the order row at creation (lens-independent, non-negotiable).** Both. TON
  floats, so booked revenue must be reproducible: the order pins the rate, and a later rate change never rewrites
  a booked order. *(The divergence is only the rate's SOURCE — Fork 1 below.)*
- **`D-3` · the booking correctness fix (VERIFIED, recommend ratify).** Purchase revenue books
  `account="platform"`, `reason="purchase"`, `currency=<rail>` — **not** `account="purchase"` (the shared
  brief's literal text). **Director-verified at source:** `house_balance/0..1` defaults to
  `WHERE account == "platform"` (`wallet.ex:22` `@house "platform"`, `wallet.ex:325-328`), and the frozen cm.6
  design already rules this convention — so `account="purchase"` would make all purchase revenue **invisible** to
  the one reconciliation read the ledger exists to answer. VenusPG caught it by grounding against the shipped
  read; it aligns cm.7 with the byte-frozen cm.6 surface rather than forking it. *Not an Operator fork — a
  correctness fix to the Director's brief; ratified.*

---

## DIVERGED — the Operator rules

### Fork 1 — F3 the rate SOURCE (and its audit provenance)

The pin-location is agreed (on the order). The divergence is **where the launch rate comes from + how its
provenance is captured**.

- **Venus (product / minimal-surface, `V-3`/`V-10`):** **config-only** for launch — a `key_shop_rates` map in
  `runtime.exs` (`stars_usd`, `ton_usd`, `usdt_usd`, `rub_usd`), read at order creation, the value snapshotted
  onto the order. The rates *table* is a named **cm.8** forward (the withdrawal rung needs floating-rate history
  anyway). Smallest launch surface; zero DDL beyond the order's pinned `rate` column.
- **VenusPG (payments-integrity, `V-8`):** config-launch **plus provenance columns on the order** —
  `rate_source` (a free string: `"config"` | `<provider>`) + `rate_quoted_at` — so every booked order
  *self-describes* its rate's origin. The objection: a config map has no `fetched_at`, no source, no history, so
  finance cannot answer "why was this order booked at 6.40 RUB/Star on the 14th" — the value was overwritten. A
  rates/quotes table is then the clean cm.8 upgrade that drops in **without reshaping the order** (the order
  already records source + quoted-at).
- **(Heavier alternative, both defer):** a **rates table now** — auditable history independent of orders.
  Rejected for cm.7 by both (the volume + regulatory audit that justify it arrive with cm.8 cash-out).

**Director lean → VenusPG's synthesis (config-launch + the two provenance columns).** It is a ~2-column delta
over Venus's position that closes a real finance-audit gap at near-zero cost, keeps the rates *table* in cm.8,
and makes the order row the self-contained system of record. The product lens's "minimal launch surface" is
preserved (no table yet); the integrity lens's "every booked rate has a provenance" is satisfied by the columns.

### Fork 2 — the cm.7 BUILD SCOPE (and, following it, F4 webhook idempotency)

Both architects converge on a **scope recommendation** the Operator should ratify, because it sets the spec's
acceptance: cm.7 builds the **multi-rail foundation** (the `packages` catalog, the ORD/OTX order flow, the pure
pricing/rails module, the rate-pin, the per-rail exactly-once gate, the `house_post` revenue booking) **+ the
Telegram Stars rail end-to-end** (the real `invoice → pre_checkout → successful_payment` flow); the
**TON / USDT / RUB payment adapters** (on-chain confirmation monitoring, a fiat processor) are **shaped but not
built** — each lands as its own forward increment when its verifier ships (the ORD/OTX rows are rail-stable).

- **Option A (recommended) — Stars end-to-end + the rails schema-shaped.** Ships a working multi-rail *spine* +
  the live Stars rail now; the other three rails' adapters are forward. Each non-Stars rail is a substantial,
  independent integration (a TON indexer, a fiat KYC'd processor) — bundling all four balloons the rung.
- **Option B — all four rails end-to-end now.** One larger rung delivering Stars + TON + USDT + RUB live. Much
  bigger surface (three payment integrations + their webhook verifiers) in one increment.

**F4 webhook idempotency (WHK) follows the scope choice:**
- Under **Option A**, the WHK table **folds into the OTX `(rail, external_id)` unique index** for the Stars
  launch (Venus `V-11`): Telegram's `successful_payment` *is* the confirmation, and a replay is a no-op (the
  duplicate OTX insert suppresses → the whole transaction no-ops). A dedicated `webhooks` table is the named
  forward for the first **push-webhook** rail (on-chain TON confirmations arrive decoupled from an order).
- VenusPG (`V-9`) ranks a **WHK Postgres table now** regardless (defense-in-depth: dedupe the *delivery* at
  ingress, before the money transaction; OTX dedupes the *payment*).

**Director lean → Option A + WHK-folds-into-OTX for the Stars launch.** It is the smallest correct surface that
honors the multi-rail intent: a player can buy keys with Stars today, and the schema + pricing + booking are
already multi-rail, so adding TON/USDT/RUB is shipping an adapter, not a redesign. The WHK table lands with the
first async rail, where it is load-bearing. *(If the Operator wants defense-in-depth from day one, WHK-now is a
~3-column add — a clean Option-A+ variant.)*

---

## The synthesized cm.7 shape (on the recommended rulings)

- **Four new tables** (one additive migration, count 4→5; the first real FKs in the schema —
  `references type: :string` for the branded PKs): `packages` (PKG — the editable catalog template: base Stars
  price + nullable per-rail overrides), `orders` (ORD — the rail-independent lifecycle + the pinned money + the
  pinned rate/source/quoted-at), `order_transactions` (OTX — the external rail receipt + the `(rail, external_id)`
  exactly-once key + the verbatim jsonb payload); `webhooks` (WHK) **forward** (folds into OTX for the Stars
  launch under Option A).
- **Two new modules:** `Codemojex.Rails` (pure — the frozen per-rail facts + the minor-unit table + the boot
  vector) and `Codemojex.KeyShop` (the order/booking I/O + the pure pricing: `price_minor` / `net_revenue`
  (`:mobile` | `:desktop` store fee) / `usd_face_cents` over package + rail + rate). The Telegram invoice flow in
  the web layer.
- **The money path (one `Repo.transaction`, gated on the OTX insert):** OTX receipt → TXN keys mint
  (`credit(player, :keys, keys, "purchase", order_id)`, the branded ORD ref, not the `"stars"` literal) → RVL
  revenue (`house_post("platform", <rail>, +gross_minor, "purchase", order_id)`). Exactly-once on
  `(rail, external_id)`; `house_balance()` returns the new per-rail buckets with **zero read change**.
- **cm.8 designed-for (built: none):** the withdrawal seam is a signed `house_post` **debit** (negative delta —
  the same no-CHECK property that admits cm.6's `deposit_seed`) + the shared rate-pin shape + the rates table the
  Fork-1 provenance columns upgrade into.

## The decisions to lock on the Operator's ruling

- **`D-4`** ← Fork 1 (the rate source + provenance).
- **`D-5`** ← Fork 2 (the cm.7 build scope + the WHK placement that follows).
- **`D-6`** ← the convergence lock (F1 / F2 / F4-split / F5 / F3-pin) as the ruled build contract.
- **`D-3`** stands ratified (the booking correctness fix).

On the ruling, Venus finalizes the cm.7 triad to a **build-grade ruled brief** (folding the rulings into the
Rulings + Build-brief sections), and the cm.7 spec is **approved** — the build runs as a later rung via
`/codemojex-ship cm.7` (an L2 Squad: money + schema + an external-wire/exactly-once surface → Apollo mandatory).
No production code and no commit this phase beyond the Operator-approved spec docs.
