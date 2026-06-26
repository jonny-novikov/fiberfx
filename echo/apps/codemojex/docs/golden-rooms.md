# Codemojex · Golden Rooms

> **Status — the approved launch model, reconciled ahead of the build.** A Golden Room is the **tournament**
> room of the launch: a buy-in to enter, a gather of ten paid members before the timer starts, a live classic
> game, and a proportional split of the prize pool among the top finishers. This document is the binding
> design of that model (the calibration ledger `D-17`/`D-18`; the decision surface
> `docs/codemojex/specs/economy/economy.md` §8). It reconciles **ahead of the engine**: the substrate it
> reuses is shipped and cited at `file:line`; the tournament mechanics — the `:gathering` state,
> `Wallet.buy_in`, `close_split`, `close_void`, the wired sweep — are the **successor build rung** (named in
> `docs/codemojex/codemojex.roadmap.md`), written here forward-tense and marked *(forward)*. The earlier
> `gold_multiplier` "boost class" is **removed** (`D-16`): it was backend + canon drift absent from the real
> product, and the Golden Room is a tournament, not a ×boost.

A Golden Room is a **tournament** built on the ordinary Codemoji game. It plays exactly like a classic game —
the same six-emoji secret, the same linear scoring, the same live per-guess feedback — but it gates its start
on a field, funds its prize from the field's buy-ins, and splits that prize among the top finishers rather
than paying one winner. Golden Rooms exist to concentrate attention: a time-bound, candidly stated,
self-funding prize that draws a crowd to one room.

A Golden Room is **`type:"classic"` with `golden: true`** — `golden` is the **tournament marker**, not a game
type and not a boost flag. The blind/sealed commit-reveal mode is a **separate** surface, the `type:"golden"`
game (no per-guess feedback, a sealed top-K at close) — a different mechanism that is **not** a "Golden Room".
The two were once collapsed onto one word; the launch model separates them. `Codemojex.create_golden_room/3`
produces a **classic**-typed, live tournament: it must stop defaulting `type` to `"golden"`
(`rooms.ex:31` today routes `golden: true → type:"golden" →` the blind policy — the collision the reconcile
strikes), and the blind mode is reached only by an explicit `type: "golden"`.

The design rule is the one the rest of the game follows: the game is a snapshot of its room. A Golden Room's
tournament props — the buy-in, the gather threshold, the duration — are captured onto the game when it forms,
so editing the room never changes the terms of a game already in flight.

## What makes a room golden

The marker and the tournament props sit on both the room template and the game it snapshots:

- `golden` — a boolean marking the tournament class; a normal room is `false`. *(shipped:
  `schemas/room.ex:20`, `schemas/game.ex:34`.)*
- `start_threshold` — the number of **paid members** that must gather before the timer starts (the launch
  default is **10**); `nil` keeps the legacy first-join start for ordinary rooms. *(forward — the build rung
  adds the column + the gather gate; `create_golden_room/3` defaults it to 10.)*
- the **buy-in** — the entry fee, a flat **$1** at launch via a pure `buy_in(game)` that takes the room's
  `keys_to_enter` config but **ignores** it (a forward config hook; flat $1 at launch). *(forward.)*

The removed `gold_multiplier` column is reconciled out in the build rung; the prize pool has **no boost**.

## Membership is the buy-in

A Golden Room is a paid tournament, and **paying the buy-in is what makes a player a member** for the room's
life. The $1 buy-in is charged **once, at join** (entry into the gathering room); a re-join never charges
again. Membership is durable — recorded as a `buy_in` transaction in Postgres and cached in ETS — so the
member set is exactly the players with a `buy_in` transaction for the game. *(forward — this supersedes the
earlier member-by-guess set, ledger `D-18`.)*

Paying the buy-in is distinct from guessing: a member may guess during the gathering phase (the guess is
scored and builds standing), but a member who never guesses is still a member who funded the pool.

## Gather, then start — the self-funding pool

A Golden Room forms in a new **`:gathering`** state: it accepts buy-ins and guesses, but the **timer has not
started** (`ends_ms` is unset) and no countdown runs. When the **tenth paid member** joins, the game
transitions `:gathering → :open`, sets `ends_ms = now + duration_ms`, and the live timed round begins. The
Room Lobby always shows the **live prize pool** and the **$1 fee**, and the gather counter (e.g. `7/10`)
surfaces on the gameplay (CODEMOJIES) board, reading the paid-member count against the threshold. *(forward —
the `:gathering` state machine + the gather gate, build rung; `:gathering` is added to the `games_status`
CHECK, and `ends_ms`'s `null:false` constraint is relaxed so a gathering game holds it nil.)*

The buy-ins **fund the pool**, and the coupling is the keystone of the economy:

> **enter_fee ($1) × floor (10) = the guaranteed pool ($10).**

The hard-ten floor is the **break-even point**: ten buy-ins fund the $10 guarantee exactly, so the platform
**never loses money on a started game**, and the pool grows past $10 with every member above ten. Per-guess
fees are **platform revenue**, not pool — only the buy-ins grow the prize. *(This reconciles out the old
"every attempt adds to the pool" copy; the pool is buy-in-funded. The exact keys→diamonds pool accounting —
a buy-in collected in keys funding a diamond prize — is a build-rung detail, `D-18` residual.)*

## How the prize pays out — two classes, every member paid

When a Golden Room closes — on a perfect crack, the timer, or the sweep, the same triggers as any classic
game — settlement pays **every member**, in one of two classes, inside one exactly-once close (the shipped
`SET cm:<game>:closed NX` lock, `rooms.ex:181`):

- **The top finishers split the diamond prize pool proportionally.** A new `settlement: "live_split"` /
  `economy: "proportional"` policy reuses the shipped, tested `Economy.top_k_split/3` (`economy.ex:62`):
  rank `i` takes `payout_split[i] / Σ` of the pool, the rounding dust added to rank 1, so the whole pool
  drains. The default breadth is `top_k` 5 over `payout_split` `[40,25,15,12,8]` (the snapshotted props,
  shipped — `game.ex:24-26`); diamonds convert to keys at the fixed 10:1 on a win (the shipped mechanic).
  *(forward — `close_split`, a thin new dispatch over the shipped payer; it **mirrors `close_live`'s shape**
  — a Store-only settle + the `{:golden_win}` fan-out — **not** `close_sealed`'s reveal path, which writes
  the cache twice and emits a `{:revealed}` event a live room must not.)*
- **Every other member receives consolation clips** — `clips = max_score / 10`, granted on finish. A member
  who paid but never guessed scores 0 and receives 0. Clips carry no economic value
  (`01-currency-model.md:36-37`), so the consolation cannot be farmed. *(forward.)*

The settlement is pure and guarded, so a re-run pays identically.

## When the field never gathers — void and refund

A Golden Room that never reaches its threshold has taken real money (the buy-ins) for a tournament that never
began, so it must give that money back. On a gather deadline a still-gathering game transitions
`:gathering → :voided` and **refunds every buy-in exactly once** — a new `close_void` path under the same
`SET … NX` close lock, made crash-resumable by a per-`(player, ref)` idempotency marker (a `buy_in_refund`
transaction guarded by a partial unique index, mirroring the shipped `tg_user_id` pattern at
`wallet.ex:52-88`). The **per-guess fees are not refunded** — a scored guess bought a delivered service (live
feedback + board standing) and is platform revenue (`D-14`). A **free** room, whose guesses cost only
valueless clips, may wait indefinitely. *(forward — `close_void`; the build rung also **wires the sweep**
that fires it: today `close_if_expired/1` (`rooms.ex:298`) has **zero callers** in `lib/` or `test/` and no
scheduler exists, so neither the timer-close nor the never-fills auto-close has an in-tree trigger.)*

## The buy-in is a two-sided transaction

A buy-in moves money into the pool, so it is the game's first **cross-entity** transaction: in one Postgres
transaction it **debits the joining player's wallet** and **increments `games.prize_pool`** — both commit or
neither. The pool increment is an **atomic SQL `+`** (never an app-side read-modify-write, which would lose
updates under concurrent joins), and the whole op is made **exactly-once in Postgres** via a partial unique
index on `transactions(player, ref) WHERE reason = 'buy_in'` (a Valkey `SET cm:<game>:paid NX` is a
fast-path hint, not the source of truth — the ledger is authoritative across a Valkey flush). A buy-in writes
**Postgres only**; it does not rewrite the immutable game cache, so the live pool is always a Postgres read
(the hot scoring path reads only the secret, never the pool — `game.ex:106-107`). The transaction inherits
the shipped wallet discipline — lock the player row `FOR UPDATE`, the non-negative CHECK backstop, a paired
`TXN` ledger row (`wallet.ex:158-217`; the `convert_to_keys` paired-`txn!` at `wallet.ex:118` is the in-app
template). The `buy_in` / `buy_in_refund` reasons are free-text, so no enum migration is owed. *(forward —
`Wallet.buy_in`; the app has no `Ecto.Multi` precedent, so a single `Repo.transaction` with a `lock(player)`
debit + an `update_all` `inc:` on the pool matches the app idiom.)*

A buy-in is real money, so a Golden Room **cannot be free** — `buy_in ⇒ not free` is enforced as a changeset
rule, since a real-money buy-in cannot fund a pool paid in valueless clips. *(forward.)*

## The win is a moment

A Golden Room win is louder than an ordinary one, on two channels — the shipped `golden_win` path carries it.
The top finishers are each sent a `golden_win` notification through the notification system, addressed by the
chat the player registered and delivered by `echo_bot` (`Codemojex.Notifier.golden_win/4`, called from
`rooms.ex:261`), and the close broadcasts a `{:golden_win, …}` message on the game's Phoenix PubSub topic
(`rooms.ex:267`) so the live surface can mark the moment for everyone watching. A player with no chat on file
is paid all the same — the diamonds are the record, the notice is the flourish.

## The launch config

The launch ships two rooms:

- a **free warm-up room — "Бокс для разминки"** (`type:"classic"`, free, **1 clip per guess**, no key spent,
  **no buy-in**) — the no-stakes room a new player learns in; and
- one **Golden Room** — `type:"classic"` + `golden: true`, a **$1** buy-in (priced in USD, collected via the
  shipped Telegram Stars → keys rail, `wallet.ex:108`), a per-guess fee, a **gather-10** start, a
  **buy-ins-only** pool, and a **live-proportional** top-K payout with consolation clips for the rest.

## Where it lives in the code

| Concern | Module | Status |
|---------|--------|--------|
| The tournament marker | `Codemojex.Schemas.Room`, `Codemojex.Schemas.Game` (the `golden` column) | shipped |
| The gather threshold | `start_threshold` on `rooms` + `games`, snapshotted at start | forward |
| Membership = the buy-in | `Wallet.buy_in` (the two-sided debit + atomic pool `+`) + the `buy_in` `TXN` | forward |
| The `:gathering` state + the gather gate | `Codemojex.Rooms` (the state machine + the `:gathering → :open` start transition under a `cm:<game>:started NX` lock) | forward |
| The proportional payout | `Economy.top_k_split/3` (`economy.ex:62`), via `close_split` (mirrors `close_live`) | payer shipped · dispatch forward |
| The consolation clips | the `max_score / 10` clip grant at finish | forward |
| The never-fills refund | `close_void` (per-`(player, ref)` idempotent) + the wired sweep | forward |
| The win notification | `Codemojex.Notifier.golden_win/4` (`rooms.ex:261`) | shipped |
| The live announce | the `{:golden_win, …}` broadcast (`rooms.ex:267`) | shipped |
| The convenience API | `Codemojex.create_golden_room/3` — stops defaulting `type` to `"golden"` | shipped · reconcile |

## References

- [Mastermind (the board game)](https://en.wikipedia.org/wiki/Mastermind_(board_game)) — the code-breaking game a Golden Room runs as a tournament.
- [Parimutuel betting](https://en.wikipedia.org/wiki/Parimutuel_betting) — the field-funded pool split among finishers, the shape the buy-in tournament takes.
- [All-pay auction](https://en.wikipedia.org/wiki/All-pay_auction) — every guess pays a fee whether or not it wins (the per-guess fee is platform revenue; the buy-ins fund the prize).
- [Telegram — Mini Apps (validating WebApp data)](https://core.telegram.org/bots/webapps) — the verified launch data a winner's chat is bound from, and Telegram Stars on the surface.
