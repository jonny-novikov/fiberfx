[ch04-cb-emoji-set-frontend.md](../../../../../fireheadz/Writerside/topics/codemoji-backend/part-07-game-engine/ch04-cb-emoji-set-frontend.md)# Currency Model

## What are the three currencies in Codemoji?

Codemoji uses a three-currency economy. Each currency serves a distinct role in the game loop:

| Currency     | Symbol       | Purpose                            | Purchasable?               | Withdrawable? |
|--------------|--------------|------------------------------------|----------------------------|---------------|
| **Keys**     | `keys`       | Guess cost in paid rooms           | Yes (Telegram Stars)       | No            |
| **Diamonds** | `diamonds`   | Prize payouts, convertible to keys | Won from games             | No            |
| **Clips**    | `clips`      | Guess cost in free rooms only      | No (granted via bonuses)   | No            |

The exchange rate is fixed:

```
1 key     = 10 diamonds  = $0.12 (12 cents)
1 diamond = $0.012       = 1.2 cents
```

```elixir
@diamonds_per_key 10
```

---

## How are keys structured in the balance model?

Keys are the primary consumable currency. Diamonds can be withdrawn or converted to keys.

| Column   | Type        | Description                          |
|----------|-------------|--------------------------------------|
| `keys`   | `integer`   | Regular keys (purchased or earned)   |
| `clips`  | `integer`   | Promotional clips (free room only)   |


Note that `clips` are excluded from the available balance.
Clips can only be used in free rooms and carry no economic value.

---

## How are diamonds structured?

Diamonds are the prize currency, won from games and depositable via the prize bank.

---

## What is the currency lifecycle?

Each currency follows a distinct earn-spend-transfer lifecycle:

```
KEYS LIFECYCLE
==============
  Earn:
    purchase (Telegram Stars)  ──> keys += N
    diamond conversion         ──> keys += floor(diamonds / 10)
    grant (admin/reward)       ──> keys += N

  Spend:
    paid room guess            ──> keys -= guessFee
    free room guess            ──> clips -= clipCost


DIAMONDS LIFECYCLE
==================
  Earn:
    prize deposit (game win)   ──> diamonds += prizePool
    bonus grant                ──> bonusDiamonds += N

  Spend:
    convert to keys            ──> diamonds -= N * 10
    (future) marketplace       ──> diamonds -= price

  Lock:
    pending conversion         ──> lockedDiamonds += N
    release on completion      ──> lockedDiamonds -= N
```

---

## How does diamond-to-key conversion work?

Players convert diamonds to keys at a 10:1 rate. The conversion is validated and executed atomically.
Two transaction records are created: one diamond debit and one key credit. 
The reason fields cross-reference each other.

---

## What are the balance mutation rules?

All balance mutations follow these invariants:

1. **Non-negative balances**: The application validates `available >= amount` before every deduction.

2. **Atomic updates**.

3. **Separate currency paths**: Paid rooms deduct from `keys` only; free rooms deduct from `clips` only. The two paths never cross.

   ```text
   // Paid room:
   // Only touches 'keys' 
   
   // Free room:
   // Only touches 'clips', never 'keys'
   ```

5. **Every currency mutation records a transaction**: No balance change happens without a corresponding transaction.
