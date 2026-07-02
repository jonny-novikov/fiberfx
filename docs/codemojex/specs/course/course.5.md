# Codemojex course · C5 — The Economy and the Bank

> **Route** `/codemojex/the-economy` · **stub shipped** — this manuscript is the chapter brief; the
> C5 authoring rung deepens both.
> **Sources** B7.5 · cm.1 (the wallet) + cm.5 (`Wallet.buy_in`, the pool) · design §Core flows
> (the economy) · [`../economy/economy.md`](../economy/economy.md) §8.

Money is real, so it lives on the floor: three currencies each in its own lane, every balance change
a database transaction, and a settlement that pays the same on a re-run. The chapter teaches the
candid economy — fees stated, the pool stated up front, the conversion rate fixed and public — and
the wallet discipline that lets the field scale without a single-writer process: the row lock
serializes only same-player mutations, so the database does the work a funnel process would have.

## C5.1 · Three currencies

Keys pay in paid rooms and are bought through the KeyShop; clips pay in free rooms and carry no value
(excluded from the available balance); diamonds are prizes, convertible to keys at a fixed ten to
one. The paid and free paths never cross. Dive route: `/codemojex/the-economy/three-currencies`
(planned).

## C5.2 · The transactional wallet

A balance change locks the player row with `SELECT … FOR UPDATE`, checks the non-negative invariant
(backed by the schema CHECK as a backstop), writes the balance, and inserts the paired `TXN` ledger
row — all or nothing. `Wallet.buy_in` (cm.5) is the two-sided form: the player debit and the atomic
SQL pool credit in one transaction, with the `transactions(player, ref) WHERE reason='buy_in'`
partial unique index making a re-submitted buy-in exactly-once. Dive route:
`/codemojex/the-economy/the-transactional-wallet` (planned).

## C5.3 · The bank, the pool, and the rake

Today the pool lives on the game's own `prize_pool`: platform-seeded for an ordinary room, funded by
the field's buy-ins for a Golden Room ($1 × ten members, break-even by design, per-guess fees the
platform's revenue), paid out at settlement. The `BNK` escrow as a first-class entity and the
**published platform rake** are forward (`cm.9+`) — the design's ruled default is transparent margin
levers, never undisclosed house players. Dive route:
`/codemojex/the-economy/the-bank-the-pool-and-the-rake` (planned).

## Grounding

- `echo/apps/codemojex/lib/codemojex/wallet.ex` · `economy.ex` · `ledger.ex` ·
  `schemas/{player,transaction}.ex` (the non-negative CHECK).
- [`codemojex.design.md`](../../codemojex.design.md) §Core flows (the economy) / §Privacy and
  fairness (economic fairness); [`../economy/economy.md`](../economy/economy.md) §8 (the Golden Room
  economy — the decision surface).
- [`stories/wallet.stories.md`](../../stories/wallet.stories.md) ·
  [`stories/economy.stories.md`](../../stories/economy.stories.md) ·
  [`stories/golden-economy.stories.md`](../../stories/golden-economy.stories.md) ·
  [`stories/golden-tournament.stories.md`](../../stories/golden-tournament.stories.md).

## Reconcile notes

The rake and the `BNK` escrow are **forward** (`cm.9+`) and are the only forward-tense material in
this chapter; the buy-in, the pool, and the consolation clips shipped via cm.5.

## Doors

[/bcs](/bcs) — one writer per book, the ledger law · [`C4`](course.4.md) ← · → [`C6`](course.6.md).
