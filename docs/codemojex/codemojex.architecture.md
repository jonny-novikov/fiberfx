# Codemojex · Technical Architecture (Draft for Review)

<show-structure depth="2"/>

A draft of the technical architecture for the Codemojex game and `codemojex_web`, for Chief Architect review. The thesis: Codemojex is a generic Mastermind engine on the Branded Component System, and the Golden Rooms variant is a mode of that engine rather than a separate product. 
Open questions, including the integrity and regulatory ones, are at the end.

## The engine

The Game system is a Mastermind engine. The family is defined by two things only: a code space (positions, a symbol set, and whether duplicates are allowed) and a feedback function (what a guess reveals about the secret). Everything else is policy.

- A `GAM` holds the secret, the timer, the state, a mode, and four policies — feedback, scoring, settlement, economy — plus a commitment for blind modes.
- The secret, the guess, and the distance math are one code path shared by every mode. The policies branch only the edges: what the view exposes per guess, when settlement runs, and how the pool pays.
- The classic mode is feedback `score`, settlement `live`. The Golden Room is feedback `none`, settlement `sealed`, over a reduced symbol set. No new entity types separate them.

## The layering (no ephemeral job tier)

```
  Phoenix (codemojex_web)  live surface     : JSON API, a game channel, a LiveView admin
        |
  EchoMQ (Valkey)          real-time, queues: per-player guess lanes to one scorer;
                                              leaderboard ZSET; locks; tier claims
        |
  EchoStore (ETS L1)       read-hot cache   : a game's secret and emoji set, immutable
                                              for the game; falls back to Postgres
        |
  Postgres (Ecto)          system of record : players, transactions, games (secret,
                                              commitment, pool, state), guesses, rooms
        |
  BCS (branded ids)        identity         : {ns}{base62} primary keys, Snowflake-minted
```

The app runs as a long-lived service on Fly Machines. The load is steady — a trickle of guesses over a game's life — and the heavy work, settlement, is a single batch pass at a game's close. There is therefore no bursty, scale-to-zero job profile and no ephemeral-machine tier; the worker is a supervised consumer in the running app.

## Data flow — a live game

Join returns the game view with no secret. A guess is submitted over REST and acknowledged with `202`, not scored on the request. The wallet is charged on the room's currency path; the guess is enqueued as a `GES` job on the player's `PLR` lane. One consumer scores it against the secret, writes the guess and score, moves the leaderboard ZSET, and broadcasts on PubSub; the game channel pushes the result. The submit and the score are decoupled, which is why fair lanes work: no request blocks on the lane and the scorer.

## Data flow — a Golden Room

At open, the game publishes its commitment. Players submit guesses that are charged, enqueued, and stored; the channel carries the timer and state only, with no results. At close, the secret and nonce are revealed. One settlement pass scores every `GES` against the revealed secret, ranks players, pays the top K from the bank as `TXN` rows, and records the rake; the game moves to settled, and the secret, nonce, and commitment are exposed for verification.

## Provably-fair secret

A commitment scheme gives two properties the blind mode needs: hiding, so no information about the secret leaks before reveal, and binding, so the server cannot open the commitment to a different secret after the room opens. A hash-based commitment over the secret and a nonce is the lean instantiation. The commitment is stored on the `GAM` at open, revealed at close, and verifiable by anyone who recomputes it. This converts a server the player must trust into a server the player can check.

## Realtime and transport

Commands run over REST, idempotent and authenticated against the Telegram session. Live state runs over Phoenix Channels on a per-game topic. The operator console runs over LiveView, which needs no separate admin API and subscribes to the same PubSub. Inbound payments run over webhooks with their own signature auth and retry-safe handling. A submitted guess is acknowledged, not scored, on the request; the result arrives over the channel for a live room or at settlement for a blind one.

## Anonymization

The leaderboard display name and avatar are a per-game alias, derived or stored on the membership (`RMP`); the real `PLR` and `USR` never cross the public boundary. The alias is a view policy, not a new identity, so anonymization adds no entity type.

## Open questions (for the Chief Architect and legal review)

- House participation. Should the platform ever field system-controlled players, and if so, must it be disclosed? Undisclosed house players that win prizes back from paying users in a real-money contest are likely deceptive and unlawful in many jurisdictions, and they interact badly with the anonymized leaderboard that would hide them. The recommended default is transparent margin levers — a published rake, a capped or guaranteed pool, a minimum-participant threshold before a real pool forms — which meet the same goal of bounding the house's exposure without deception. A decision and a jurisdiction review are needed before any house-participation mechanism is built.
- Regulatory classification. A paid-entry, prize-pool, blind-outcome mode may be regulated as gambling in some jurisdictions, while the live skill mode may be treated differently. Where can paid rooms operate, and under what licensing and age and region gating?
- Scoring unification. Should the live linear-distance score and the blind exact-match ranking share one scoring function behind a policy switch, or remain separate implementations the engine selects between?
- Code-space sizing. What reduced symbol-set size balances tractability against the no-feedback difficulty, and how is it tuned as traffic changes?
- Commitment scheme. A hash-based commitment is the lean choice; is a stronger scheme or a published per-room seed required for the fairness guarantee the product wants to advertise?
- Settlement atomicity. Settlement moves real money across many wallets in one pass; how is it made atomic and idempotent — a single transaction per game, or a staged ledger with one commit — and how are partial failures recovered?
- Anonymization mapping. Is the alias stable across a player's rooms or fresh per game, and where is the mapping held so a client cannot correlate it back to a real identity?
- Live-mode anti-abuse. Beyond Golden Rooms, what controls does the live mode need (rate limits, attempt caps, device and account signals), and how do they interact with the per-guess economy?
- Withdrawal and identity verification. Diamonds convert to keys but are not withdrawable today; if cash-out is ever added, what verification and anti-fraud controls apply?

## References

- Mastermind and its family — https://en.wikipedia.org/wiki/Mastermind_(board_game)
- The feedback function and minimax code-breaking — https://arxiv.org/abs/1607.04597 , https://arxiv.org/abs/1207.0773
- Commitment schemes, commit and reveal — https://en.wikipedia.org/wiki/Commitment_scheme
- All-pay auctions and contests — https://en.wikipedia.org/wiki/All-pay_auction , https://www.cs.cornell.edu/home/kleinber/networks-book/networks-book-ch09.pdf
