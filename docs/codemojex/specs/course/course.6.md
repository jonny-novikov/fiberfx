# Codemojex course · C6 — The Revenue Ledger and the KeyShop

> **Route** `/codemojex/commerce` · **stub shipped** — this manuscript is the chapter brief; the C6
> authoring rung deepens both. An **extension chapter**: cm.6 and cm.7 shipped after the B7 arc was
> written, so commerce had no module — it does now.
> **Sources** cm.6 ([`../cm.6.md`](../cm.6.md)) + cm.7 ([`../cm.7.md`](../cm.7.md)) shipped;
> cm.8 forward.

Where C5 moves the players' money, C6 books the house's. The `RVL` revenue ledger (cm.6) is the
platform's own account — a dedicated table of **signed** deltas with no non-negative CHECK,
multi-source and multi-currency — and the KeyShop (cm.7) is the multi-rail pay-in that feeds it. The
chapter's law is conservation: every keys-unit a player is debited is a house credit or a pool
conversion, proven by a property test, and every rail's external event lands exactly once.

## C6.1 · The revenue ledger

The `revenue_ledger` table (`RVL`-branded, signed `delta`) books the five Golden-Room revenue
movements — seed · deposit-recovery · first-mover · full-revenue · void-reclaim — as explicit house
credits paired inside the buy-in's `Repo.transaction`. `Wallet.house_post`/`house_balance` and
`revenue_breakdown/1` are the reconciliation reads; the keys-unit conservation invariant
(`Σ player debits == Σ house credits + Σ pool conversions`) is held by a property test. Dive route:
`/codemojex/commerce/the-revenue-ledger` (planned).

## C6.2 · The KeyShop

A DB-stored `PKG` catalog (keys · base Stars price · discount · active — the shop edits without a
deploy) behind a multi-rail order flow: one `orders` table with a rail discriminator (`ORD`), the
payment record per rail (`OTX`, with `UNIQUE(rail, external_id)` the exactly-once gate — the Telegram
charge id, the on-chain tx hash, the processor settlement id), and idempotent inbound webhooks
(`WHK`). Telegram Stars (XTR) is built end to end — `invoice → pre_checkout → successful_payment` —
with the TON/USDT/RUB rails schema-shaped, their verifiers forward. Prices are minor-unit
(star · nanoTON · micro-USDT · kopeck), the rate pinned per order; gross purchase revenue books to
the **same** `revenue_ledger` (`account="platform"`, `reason="purchase"`, the rail as currency), so
`house_balance` sees the whole house. Dive route: `/codemojex/commerce/the-keyshop` (planned).

## C6.3 · Cash-out and the treasury (forward)

**Forward — cm.8, the next rung.** The withdrawal rail: diamonds → TON/USDT/RUB at floating rates,
pinned per withdrawal at request time; a house **debit** (a negative `revenue_ledger.delta` through
the same `Wallet.house_post`, no new ledger verb); a `rates` table with a poller; KYC/AML and the
21-day hold; the treasury reconciliation. cm.7 designed-for this seam and built none of it — the
regulatory and fraud weight is quarantined in cm.8. Dive route:
`/codemojex/commerce/cash-out-and-the-treasury` (planned).

## Grounding

- `echo/apps/codemojex/lib/codemojex/key_shop.ex` · `rails.ex` · `wallet.ex`
  (`house_post`/`house_balance`) · `schemas/{package,order,order_transaction,webhook,revenue_ledger}.ex`.
- [`../cm.6.md`](../cm.6.md) (the revenue ledger) · [`../cm.7.md`](../cm.7.md) (the KeyShop) ·
  [`../../kb/revenue-model/`](../../kb/revenue-model/).
- [`stories/revenue-ledger.stories.md`](../../stories/revenue-ledger.stories.md) ·
  [`stories/keyshop.stories.md`](../../stories/keyshop.stories.md).

## Reconcile notes

C6.3 is the chapter's only forward-tense dive (cm.8); everything else shipped (`2de57202` cm.6,
`0acba290` cm.7). The page must never let the withdrawal rail read as built.

## Doors

[/echomq](/echomq) — exactly-once on the bus · [`C5`](course.5.md) ← · → [`C7`](course.7.md).
