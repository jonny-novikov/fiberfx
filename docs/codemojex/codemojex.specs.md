# Codemojex · Feature Specification

<show-structure depth="2"/>

The features to implement to reach the complete game, grouped by system. The Game system is a generic Mastermind engine; the classic live room and the Golden Room are two modes of it, selected by policy. Reaching the whole game is a matter of building these features, not new identity types.

## Identity and access

- Verify Telegram `initData` and mint a short-lived session (`SES`) bound to an account (`USR`).
- Bind a `USR` to a Telegram account id; one persona (`PLR`) per account to start.
- Resolve `PLR` and `USR` once, at session mint, and carry both in the session, so no request traverses the link mid-call.

## Player

- A `PLR` profile: display name, avatar, lifetime statistics.
- Name each player's guess lane by `PLR`, so the bus rotates service per persona.

## Rooms and modes

- A `ROM` template: emoji set, duration, guess fee, paid or free, seed pool, and a mode.
- Two modes at launch: classic (live feedback) and golden (blind).
- A `ROM` carries the four engine policies: feedback, scoring, settlement, economy.
- A reified membership (`RMP`) with lifecycle (joined, active, left, banned) and a per-game display alias.

## The Mastermind engine

- One secret, guess, and distance core shared by every mode.
- A feedback policy: `score` (0 to 600) or `none`.
- A scoring policy: linear distance, or an exact-match ranking.
- A settlement policy: `live` (close on a perfect score or the timer) or `sealed` (one batch at close, top K).
- An economy policy: the per-guess currency path and the payout curve.
- A `GAM` that carries its mode, the four policies, the secret, the commitment, the timer, and its state.

## Games and guesses

- The `GAM` state machine: scheduled, open, active, revealing, settling, settled, voided.
- A guess (`GES`): six codes validated against the keyboard, with locked positions overlaid.
- Charge the currency path before accepting a guess; enqueue the guess as a job on the `PLR` lane.
- One consumer scores against the secret; the host never scores.
- Live mode broadcasts the result; blind mode stores the guess and reveals nothing.
- Position locking, held in Valkey per player per game, persisting across guesses.

## Golden Rooms (the blind mode)

- Accept guesses with no per-guess feedback for the room's life.
- Use a reduced emoji set (for example 18 or 24 cells) to keep the space tractable without hints.
- Close on the timer; run one settlement pass over all guesses; pay the top K from the bank.
- An all-pay attempt economy: a per-attempt fee is sunk whether or not a player places.
- An anonymized leaderboard: generated neutral names and avatars, no real personas.

## Provably-fair secret (commit-reveal)

- At room open, publish a commitment over the secret and a nonce on the `GAM`.
- Keep the secret and the nonce server-side and sealed for the room's life.
- At close, reveal the secret and the nonce, and expose them so a player can recompute the commitment and verify it.
- Score settlement against the revealed secret; the commitment binds the server to the secret it fixed at open.

## Economy and the bank

- Three currencies: keys (paid rooms, bought with Stars), clips (free rooms, no value, excluded from the available balance), diamonds (prizes, convert to keys at ten to one).
- A transactional wallet keyed by `USR`: a row lock, the non-negative check, a paired ledger row, all or nothing.
- A `BNK` escrow per game: the pool accrues from fees and pays out at settlement.
- A published platform rake; the remainder of the pool pays the board.
- Settlement that is pure and idempotent, so a re-run pays identically.

## Commerce

- A package catalog (`PKG`): bundles of keys for Telegram Stars.
- A purchase order (`ORD`) with state: created, pending, paid, fulfilled, failed, refunded.
- A payment ledger (`OTX`) for Stars, kept separate from the currency ledger (`TXN`).
- Inbound webhooks (`WHK`): idempotent, processed once, driving `ORD` and `OTX`.
- On paid, credit keys to the `USR` wallet as a `TXN`.

## Growth

- Share and referral tokens (`SHR`): who shared what, and the redemptions.
- A disclosed bonus on redemption, granted through the economy, never a direct write.

## Analytics

- An append-only event stream (`AEV`), emitted by every system, one-way.
- Never authoritative; rebuildable by replay.
- Powering the admin dashboards and live counters.

## API and realtime

- A JSON API through the `Codemojex` facade and the privacy-safe views.
- Commands over REST: auth, lobby, join, submit guess (accepted, not scored on the request), buy, convert.
- A live channel per game for live rooms: results, leaderboard, tier claims, timer, and state changes.
- For blind rooms, a channel that carries state and timer only, with no results until reveal.

## LiveAdmin

- Rooms and packages management; emoji set and sprite uploads (`EMS`, `RSC`).
- A live board of active games with state, pool, and player counts.
- Treasury: the bank, payouts, the rake, refunds.
- Commerce: orders, payments, the webhook log, reconciliation.
- Players and moderation: ban through membership status.
- Analytics dashboards over the `AEV` stream.

## Anti-abuse and integrity

- Golden Rooms break feedback-driven clicker bots: with no per-guess signal, a bot cannot hill-climb toward the secret.
- The all-pay economy gives blind farming a negative expected value.
- The commitment removes the rigged-secret vector.
- House participation and pool balancing are a decision for the Chief Architect and legal review. The default is transparent margin levers — a published rake, a capped or guaranteed pool, a minimum-participant threshold before a real pool forms — not undisclosed house players. The open questions are recorded in `codemojex.architecture.md`.
