# Codemojex · Golden Rooms

A Golden Room is a platform-boosted class of room. 
It plays exactly like an ordinary Codemoji game — the same six-emoji secret, the same linear scoring, the same first-mover tiers — but the diamond prize the winner takes is multiplied by a gold factor the platform funds. Golden Rooms exist to concentrate attention: a boosted, time-bound, candidly stated prize that draws a crowd to one room. This document describes the mechanic and how it is wired through the game, grounded in `apps/codemojex`.

The design rule is the same one the rest of the game follows: the round is a snapshot of its room. A Golden Room's boost is captured onto the round when it starts, so editing the room — or ending the golden promotion — never changes the terms of a round already in flight.

## What makes a room golden

Two props carry the mechanic, on both the room template and the round it snapshots:

- `golden` — a boolean flagging the class. A normal room is `false`.
- `gold_multiplier` — the factor the winner's diamond pool is multiplied by at close. A golden room defaults to `3x` unless a multiplier is given; a normal room is `1x`.

Both are columns on `rooms` and `games`, defaulted so existing rooms are unaffected, and both are cast in the schemas the game's maps speak. 
A Golden Room is otherwise an ordinary room: it can set a higher guess fee and a larger seed pool at creation, the way any room can — golden is the boost on top, not a separate economy.

## Creating one

`Codemojex.create_golden_room/3` is the convenience over `create_room/3`:

```elixir
# a golden room with the default 3x boost over a 500-diamond seed pool
{:ok, room} = Codemojex.create_golden_room("Friday Gold", emoji_set, seed_pool: 500)

# a 5x boost, premium fee
{:ok, room} =
  Codemojex.create_golden_room("Mega Gold", emoji_set,
    seed_pool: 1_000,
    gold_multiplier: 5,
    guess_fee: 3
  )
```

The room is created in the waiting state like any other; the first player to join starts the round, and the round snapshots `golden` and `gold_multiplier` from the room. From that moment the round's terms are fixed.

## How the boost pays out

The multiplier is applied once, at the moment of settlement, over the seeded diamond pool. `Codemojex.Economy.effective_pool/3` is the pure rule:

```elixir
def effective_pool(pool, true, mult) when is_integer(mult) and mult > 0, do: pool * mult
def effective_pool(pool, _golden, _mult), do: pool
```

When a round closes — on a perfect crack or an expired timer — the closer computes the effective pool, then runs the ordinary winner-take-all split over it: the whole boosted pool to the top scorer, divided evenly on a tie. The boosted diamonds are deposited through the same wallet path as any prize, inside the same exactly-once close (the `SET … NX` lock means a perfect-crack close and a timer close cannot both pay). The platform funds the difference between the seeded pool and the boosted payout; diamonds are the platform's prize currency, so a larger payout is a larger platform commitment, recorded like any other prize deposit.

Because `effective_pool` is a pure function and the payout runs inside the one-shot close, a re-run settlement pays identically and a Golden Room never double-pays its boost.

## The win is a moment

A Golden Room win is louder than an ordinary one, on two channels. The winner is sent a `golden_win` notification — the boosted diamonds and the multiplier — through the notification system, addressed by the chat the player registered and delivered by `echo_bot` (see `docs/codemojex/notifications`). And the close broadcasts a `{:golden_win, …}` message on the round's Phoenix PubSub topic, so the live surface can mark the moment for everyone watching the room, the same way a scored guess fans out. A player with no chat on file is paid all the same — the diamonds are the record, the notice is the flourish.

## Fairness and economics

The boost is candid by construction. A Golden Room states its multiplier, its seed pool, and its fee up front, the same way every room states its terms; there are no hidden house entries and no opaque odds. The platform funds the boost openly, as a promotion to draw play, and the winner-take-all rule that governs every room governs this one. The exact multipliers, fees, and how often a Golden Room runs are promotional and economic decisions — the kind that belong with the chief architect and legal review before launch, alongside the rest of the prize model.

## Where it lives in the code

| Concern | Module |
|---------|--------|
| The flag and factor | `Codemojex.Schemas.Room`, `Codemojex.Schemas.Round` (the `golden` + `gold_multiplier` columns) |
| Creation and the round snapshot | `Codemojex.Rooms.create_room/3`, `start_round` |
| The boosted payout | `Codemojex.Economy.effective_pool/3`, applied in `Codemojex.Rooms` on close |
| The win notification | `Codemojex.Notifier.golden_win/4`, addressed via `Codemojex.Store.chat_of/1` |
| The live announce | a `{:golden_win, …}` broadcast on the round's PubSub topic |
| The convenience API | `Codemojex.create_golden_room/3` |

## References

- [Mastermind (the board game)](https://en.wikipedia.org/wiki/Mastermind_(board_game)) — the code-breaking round a Golden Room boosts.
- [All-pay auction](https://en.wikipedia.org/wiki/All-pay_auction) — every guess pays a fee; the boosted pool is the prize over it.
- [Telegram — Mini Apps (validating WebApp data)](https://core.telegram.org/bots/webapps) — the verified launch data a winner's chat is bound from.
