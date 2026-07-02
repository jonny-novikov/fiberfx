# Codemojex — the course · TOC

The standalone course over the shipped Codemojex engine — the real-money emoji Mastermind on the
Branded Component System — served at `/codemojex` in the CMX calibration of the contract-sheet
identity (Telegram-blue lead). Nine chapters of three dives each teach the running game from the
identity law up to the production node. Every claim is grounded in `echo/apps/codemojex`, the binding
design ([`codemojex.design.md`](../../codemojex.design.md)), and the twelve generated story features
([`stories/`](../../stories/)) — the acceptance catalog; unshipped work (cm.8+) is stated
forward-tense wherever it is named. This map is the course's source of truth; the plan + grounding
contract is [`course.roadmap.md`](course.roadmap.md), the dashboard is
[`course.progress.md`](course.progress.md), the landing manuscript is
[`course.landing.md`](course.landing.md).

## C0 — Overview — [`course.0.md`](course.0.md) · `/codemojex/overview`

> The game in one paragraph, the Mastermind family it belongs to, the engine whose modes are policy,
> and the four-layer architecture at a glance.

- [C0.1 · The game and the family](course.0.md#c01--the-game-and-the-family)
- [C0.2 · The engine and its policies](course.0.md#c02--the-engine-and-its-policies)
- [C0.3 · The architecture at a glance](course.0.md#c03--the-architecture-at-a-glance)

## C1 — The Game as Branded Systems — [`course.1.md`](course.1.md) · `/codemojex/branded-systems`

> Fifteen branded namespaces are the primary keys; four layers each own their tier; the privacy
> boundary is structural — no player-facing view ever selects the secret.

- [C1.1 · Branded ids are the keys](course.1.md#c11--branded-ids-are-the-keys)
- [C1.2 · The four layers](course.1.md#c12--the-four-layers)
- [C1.3 · The privacy boundary](course.1.md#c13--the-privacy-boundary)

## C2 — Rooms, Modes, and the Secret — [`course.2.md`](course.2.md) · `/codemojex/rooms-and-modes`

> A room is a template carrying a mode and its four policies; a game snapshots the room and pins a
> six-code secret; the blind mode publishes a commitment at open and reveals at close.

- [C2.1 · Room as template and mode](course.2.md#c21--room-as-template-and-mode)
- [C2.2 · The emoji set](course.2.md#c22--the-emoji-set)
- [C2.3 · The secret and its commitment](course.2.md#c23--the-secret-and-its-commitment)

## C3 — Guesses on Fair Lanes — [`course.3.md`](course.3.md) · `/codemojex/guesses-on-fair-lanes`

> A guess is validated, has locked positions overlaid, is charged, then is enqueued on the player's
> own `PLR` lane; the bus rotates service so one masher cannot starve the field; one consumer scores.

- [C3.1 · The guess and the lock](course.3.md#c31--the-guess-and-the-lock)
- [C3.2 · Charged, then enqueued](course.3.md#c32--charged-then-enqueued)
- [C3.3 · Fair lanes and the worker](course.3.md#c33--fair-lanes-and-the-worker)

## C4 — Scoring and Settlement — [`course.4.md`](course.4.md) · `/codemojex/scoring-and-settlement`

> Distance per position, `100 − 20·d`, summing to 600 — linear only, no tiers, no bonus; the close
> race is resolved exactly once by `SET … NX`; settlement is a strategy the game selects — live
> winner-take-all, sealed top-K, or the Golden Room's live split.

- [C4.1 · Distance and points](course.4.md#c41--distance-and-points)
- [C4.2 · The total out of 600](course.4.md#c42--the-total-out-of-600)
- [C4.3 · Settlement strategies](course.4.md#c43--settlement-strategies)

## C5 — The Economy and the Bank — [`course.5.md`](course.5.md) · `/codemojex/the-economy`

> Keys, clips, and diamonds on separate paths; every balance change locks the player row and writes a
> paired `TXN` ledger row, all or nothing; the pool pays out from the game; the rake stays forward.

- [C5.1 · Three currencies](course.5.md#c51--three-currencies)
- [C5.2 · The transactional wallet](course.5.md#c52--the-transactional-wallet)
- [C5.3 · The bank, the pool, and the rake](course.5.md#c53--the-bank-the-pool-and-the-rake)

## C6 — The Revenue Ledger and the KeyShop — [`course.6.md`](course.6.md) · `/codemojex/commerce`

> The `RVL` revenue ledger books the house's five Golden-Room movements and the KeyShop's gross
> purchases; multi-rail pay-in behind an exactly-once gate per rail; cash-out is the forward cm.8.

- [C6.1 · The revenue ledger](course.6.md#c61--the-revenue-ledger)
- [C6.2 · The KeyShop](course.6.md#c62--the-keyshop)
- [C6.3 · Cash-out and the treasury (forward)](course.6.md#c63--cash-out-and-the-treasury-forward)

## C7 — The Live Surface on Phoenix — [`course.7.md`](course.7.md) · `/codemojex/the-live-surface`

> Verified `initData` mints the one `SES` session; the JSON API answers through the facade and
> privacy-safe views; the game channel pushes live results with no per-game process.

- [C7.1 · The auth floor](course.7.md#c71--the-auth-floor)
- [C7.2 · The JSON API](course.7.md#c72--the-json-api)
- [C7.3 · Channels and PubSub](course.7.md#c73--channels-and-pubsub)

## C8 — Production Deployment — [`course.8.md`](course.8.md) · `/codemojex/production`

> One dependency-ordered supervision tree; a pinned release image; a pragmatic single-thread Valkey
> node sized for the latency tail, private on the 6PN.

- [C8.1 · The release](course.8.md#c81--the-release)
- [C8.2 · The pragmatic Valkey node](course.8.md#c82--the-pragmatic-valkey-node)
- [C8.3 · Fault tolerance and correctness](course.8.md#c83--fault-tolerance-and-correctness)

## The doors

- **Out:** [/bcs](/bcs) — the architecture law; its B7 chapter is this game taught inside the BCS
  course, and it doors back here · [/echomq](/echomq) — the bus the guesses ride · [/redis-patterns](/redis-patterns)
  — the Valkey patterns applied · [/mesh](/mesh) — the CAP weave the stack composes.
- **In:** `/bcs/codemojex` (the B7 chapter landing) door-links to `/codemojex`,
  `/codemojex/commerce`, and `/codemojex/production`.

## Tally

Nine chapters, C0–C8 · 27 dives · the landing **built**, the nine chapters **stubbed** (gated real
shells), the dives **planned** — the fine-grained state is [`course.progress.md`](course.progress.md).
