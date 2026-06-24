# Codemojex · Roadmap to the Complete Game

Codemojex is the reference implementation for this course: the game whose running code proves the Branded Component System rather than describing it. At its core it is a member of the Mastermind family of deductive code-breaking games, and the architecture treats it as exactly that — a generic engine, with each room mode chosen as configuration on the same branded entities. The app in the repository today is a skeleton; this roadmap is the path from that skeleton to a complete game across chapter B7, six modules of three dives each, on the identity, bus, store, and floor the earlier chapters raised.

## The game, and the family it belongs to

A game of Codemojex hides a secret of six emoji in fixed positions, drawn from a themed set; a player submits a sequence and the game reports how close it was. That places it in the Mastermind family, where the defining element is the feedback function — what a guess reveals about the secret — over a code space of positions and symbols. The classic mode reveals a linear score; the Golden Rooms mode reveals nothing until the room closes. Both are the same game with a different feedback policy.

## The engine and its policies

The Game system is a Mastermind engine. A game (`GAM`) carries a mode and four policies, and the secret, the guess, and the distance math are identical underneath:

- feedback — `score` (the live mode's 0 to 600) or `none` (blind, for Golden Rooms)
- scoring — the linear distance scale, or a coarser exact-match ranking
- settlement — `live` (a continuous leaderboard, closing on a perfect score or the timer) or `sealed` (one batch at close, paying the top K)
- economy — the per-guess currency path and the payout curve

A new mode is a new set of policy values on the same entities, not new code. This is the reason the game is built on BCS: a radical variant needs no new identity types and no new systems.

## The layering

```
  Phoenix (codemojex_web)  live surface     : JSON API behind privacy-safe views; a
                                              game channel pushing live results; a
                                              LiveView admin. No per-game process.
        |
  EchoMQ (Valkey)          real-time, queues: per-player guess lanes to one scorer;
                                              leaderboard ZSET; locks; tier claims.
                                              All derived and reconstructable.
        |
  EchoStore (ETS L1)       read-hot cache   : a game's secret and emoji set are
                                              immutable for the game; the cache reads
                                              L1 and falls back to Postgres.
        |
  Postgres (Ecto)          system of record : players, transactions, games (secret,
                                              commitment, pool, state), guesses, rooms,
                                              emoji_sets. ACID, CHECK-constrained.
        |
  BCS (branded ids)        identity         : {ns}{base62} ids are the primary keys,
                                              minted by the echo_data Snowflake.
```

Money is real and a game carries a server-side secret, so both live on the Postgres floor; the other layers are cached or derived over it.

## The branded namespaces

| Namespace | Entity | Role |
|:---------:|--------|------|
| `USR` | account | Telegram-bound identity; owns the wallet |
| `SES` | session | a verified session minted from Telegram initData |
| `PLR` | player | the game persona; names the guess lane |
| `ROM` | room | a template carrying a mode and its policies |
| `RMP` | membership | a player's presence in a room, with lifecycle and a display alias |
| `GAM` | game | one game in a room: the secret, commitment, timer, state, and policies |
| `GES` | guess | one submitted attempt |
| `EMS` | emoji set | the cells a room exposes; the `XXYY` codes |
| `RSC` | resource | the sprite-sheet asset behind an emoji set |
| `TXN` | transaction | a ledger row for every currency change |
| `BNK` | bank | the prize escrow a pool accrues in and pays out from |
| `PKG` | package | a purchasable bundle of keys |
| `ORD` | order | a purchase order, with state |
| `OTX` | order transaction | the real-money payment record |
| `WHK` | webhook | an inbound, idempotent webhook event |
| `SHR` | share token | a referral or share token, for attribution |
| `AEV` | analytics event | an append-only, one-way observation |

## Golden Rooms

Golden Rooms are a blind mode of the engine. A player submits a sequence and receives no per-guess feedback; the room accrues a pool over its life (for example a day or two), closes on the timer, and settles once, paying the top players whose combinations were closest. The mode is carried by policy, so it adds no new namespaces:

- feedback `none`, settlement `sealed`, a reduced emoji set (for example 18 or 24 cells) so the space stays tractable without hints, and an all-pay attempt economy where the fee is sunk whether or not a player places.
- a provably-fair secret: the game publishes a commitment at open and reveals the secret at close, so a player can verify the secret was fixed in advance (see the specification and architecture draft).
- an anonymized leaderboard: generated neutral names and avatars, no real personas.

Golden Rooms exist for live dynamics and for anti-abuse: with no per-guess signal a feedback-driven clicker bot cannot hill-climb toward the secret, and the all-pay structure gives blind farming a negative expected value. Pool balancing and any house participation are an integrity decision held in the architecture draft, with transparent margin levers as the default.

## The six modules

### B7.1 · The Game as Branded Systems

The model: the entities as branded ids that are the primary keys, the four layers and who owns what, and the privacy line a player never crosses.

- **B7.1.1 · Branded ids are the keys** — the full namespace set, minted by the echo_data Snowflake; the id is the primary key in Postgres and the address in every other layer.
- **B7.1.2 · The four layers** — identity, a Postgres system of record, an EchoStore cache, an EchoMQ bus, and a Phoenix surface; money, the secret, and the commitment live on the floor.
- **B7.1.3 · The privacy boundary** — a player sees their own attempts, best score, and the leaderboard; in blind mode not even a score leaks until reveal.

### B7.2 · Rooms, Modes, and the Secret

The board: a room is a template that carries a mode; a game is the instance in it, snapshotting the room and pinning the secret.

- **B7.2.1 · Room as template and mode** — a `ROM` holds duration, emoji set, fee, paid or free, seed pool, and a mode with its four policies; a `RMP` is the reified membership.
- **B7.2.2 · The emoji set** — an `EMS` set is the cells a room exposes and the `XXYY` codes, backed by an `RSC` sprite sheet; Golden Rooms draw from a reduced set.
- **B7.2.3 · The secret and its commitment** — a `GAM` draws six distinct codes; in blind mode it publishes a commitment at open and reveals at close, so the secret is verifiable and immutable for the game's life.

### B7.3 · Guesses on Fair Lanes

The play path: a guess is validated, has locked positions overlaid, is charged, then enqueued on the player's own lane to one scorer.

- **B7.3.1 · The guess and the lock** — a `GES` is six codes validated against the keyboard; a player's locked positions, held in Valkey, are overlaid so a confirmed cell is guaranteed.
- **B7.3.2 · Charged, then enqueued** — the wallet charges the currency path before the guess is accepted; the guess is enqueued as a branded job on the player's `PLR` lane.
- **B7.3.3 · Fair lanes and the worker** — the bus rotates service across lanes so one player cannot starve the field; one consumer scores; live mode broadcasts the result, blind mode stores it and reveals nothing.

### B7.4 · Scoring, Tiers, and Settlement

The score: distance per position on the linear scale and the thirty tiers for live rooms, and a single batch settlement with a top-K payout for sealed rooms.

- **B7.4.1 · Distance and points** — distance is the absolute gap between a guessed position and the secret's; points run 100, 80, 60, 40, 20, 0, and an emoji not in the code scores zero.
- **B7.4.2 · The total and the thirty tiers** — the six position points sum to a score out of 600; the uniform twenty-point gaps form thirty tiers, the live leaderboard's ladder.
- **B7.4.3 · Settlement strategies** — `live` closes on a perfect score or the timer; `sealed` runs one pass at close, scores every `GES` against the revealed secret, ranks players, and pays the top K from the bank, idempotently.

### B7.5 · The Economy and the Bank

The money: three currencies on separate paths, balances mutated transactionally on Postgres, a bank escrow per game, and a settlement that pays the same on a re-run.

- **B7.5.1 · Three currencies** — keys pay in paid rooms and are bought with Telegram Stars; clips pay in free rooms and carry no value; diamonds are prizes, convertible to keys at ten to one.
- **B7.5.2 · The transactional wallet** — a balance change locks the player row, checks the non-negative invariant, writes the balance, and inserts a paired ledger row, all or nothing; the paid and free paths never cross.
- **B7.5.3 · The bank, the pool, and the rake** — a `BNK` escrow holds each game's pool; fees accrue in and payouts flow out; a published platform rake is taken and the remainder pays the board. House margin is bounded by transparent levers, not undisclosed players.

### B7.6 · The Live Surface on Phoenix

The surface: a privacy-safe JSON and channel API, a live leaderboard with no per-game process, an operator admin, deployed on Fly.

- **B7.6.1 · The JSON API** — every call goes through the `Codemojex` facade and the privacy-safe views; endpoints cover players, rooms, games, guessing, own history, the leaderboard, and the key economy.
- **B7.6.2 · Channels and PubSub** — a game channel returns the view on join; for live rooms the scorer broadcasts results and the channel pushes; for blind rooms the channel carries timer and state only until reveal. No per-game process.
- **B7.6.3 · Production on Fly** — the application supervises the repo, PubSub, the bus and its consumers, and the endpoint, running as a long-lived service on Fly Machines. The load is steady and the heavy work, settlement, is a single batch pass at a game's close, so there is no ephemeral-machine job tier.

## Grounding

Every module is grounded in the `codemojex` app in the repository: the rules in `docs/` (the game rules, the currency model, rooms and emoji sets), the Ecto schemas, and the modules that carry the logic. The architecture is the same identity, bus, store, and floor the earlier chapters built; the only citable identity vector across the course remains `placement(USR0KHTOWnGLuC) = 234878118`.

## Build order and status

The app today is a skeleton that fits the real EchoMQ, EchoData, Ecto, and Phoenix interfaces; the six modules turn it into the complete, running game with both modes. The order is B7.1 through B7.6, each module a landing and three dives, each page held to the A+ gates and relinked to its predecessor as it ships. The chapter landing is written; the modules follow. The feature list is in `codemojex.specs.md`; the technical draft and open questions are in `codemojex.architecture.md`.
