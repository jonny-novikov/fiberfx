# Codemojex · Roadmap to the Complete Game

Codemojex is the reference implementation of the Branded Component System: the game whose running code proves the architecture rather than describing it. At its core it is a member of the Mastermind family of deductive code-breaking games, and the architecture treats it as exactly that — a generic engine, with each room mode chosen as configuration on the same branded entities. The app in the repository is a running game — cm.1 through cm.7 shipped the two-mode core, the auth floor, the Golden Room tournament, the revenue ledger, and the KeyShop — and this roadmap is the record of that path plus the forward feature catalog, on the identity, bus, store, and floor the earlier chapters raised. The teaching arc over the built game ships as the standalone [`/codemojex` course](./specs/course/course.toc.md), nine chapters of three dives each; the `/bcs/codemojex` chapter remains the BCS course's B7 and doors into it.

## The game, and the family it belongs to

A game of Codemojex hides a secret of six emoji in fixed positions, drawn from a themed set; a player submits a sequence and the game reports how close it was. That places it in the Mastermind family, where the defining element is the feedback function — what a guess reveals about the secret — over a code space of positions and symbols. The classic mode reveals a linear score; the blind/sealed `golden`-type mode reveals nothing until the game closes. Both are the same game with a different feedback policy. (A **Golden Room** is a third surface — a *live* tournament on the classic base, not the blind type; see the Golden Rooms section below.)

## The engine and its policies

The Game system is a Mastermind engine. A game (`GAM`) carries a mode and four policies, and the secret, the guess, and the distance math are identical underneath:

- feedback — `score` (the live mode's 0 to 600) or `none` (blind, the sealed `golden`-type mode)
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
                                              leaderboard ZSET; locks.
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
| `SES` | session | a verified session minted from Telegram initData |
| `PLR` | player | the game persona; names the guess lane |
| `ROM` | room | a template carrying a mode and its policies |
| `RMP` | membership | a player's presence in a room, with lifecycle and a display alias |
| `GAM` | game | one game in a room: the secret, commitment, timer, state, and policies |
| `GES` | guess | one submitted attempt |
| `EMS` | emoji set | the cells a room exposes; the `XXYY` codes |
| `RSC` | resource | the sprite-sheet asset behind an emoji set |
| `TXN` | transaction | a ledger row for every currency change |
| `RVL` | revenue ledger | a platform-revenue ledger row — the house account (the `BNK` bank's first slice, cm.6); a signed entry, sibling to `TXN`/`OTX` |
| `BNK` | bank | the prize escrow a pool accrues in and pays out from |
| `PKG` | package | a purchasable bundle of keys |
| `ORD` | order | a purchase order, with state |
| `OTX` | order transaction | the real-money payment record — the rail's external charge (`UNIQUE(rail, external_id)` the exactly-once gate per rail) |
| `WHK` | webhook | an inbound, idempotent webhook event |
| `SHR` | share token | a referral or share token, for attribution |
| `AEV` | analytics event | an append-only, one-way observation |

> This is the **full** catalog. The founding game used nine of these brands —
> `PLR`/`ROM`/`GAM`/`GES`/`EMS`/`TXN`/`JOB`/`NOT`/`CMD` — with one player entity (`PLR`); their systems have
> since landed `SES` sessions (cm.4), the `RVL` revenue ledger (cm.6), and the commerce
> `PKG`/`ORD`/`OTX`/`WHK` (cm.7). Still forward: `RMP` membership, the `BNK` bank, `RSC`, and the
> growth/analytics brands (`SHR`/`AEV`), landing with their `cm.8+` systems. The namespace table in
> [`codemojex.design.md`](./codemojex.design.md) is the as-built record.

## Golden Rooms and the blind mode

Two distinct surfaces once shared the word "golden"; the launch model separates them, and both are policy on the same branded entities, so neither adds a namespace.

**The Golden Room — the tournament (the launch headline).** A Golden Room is a `classic`-typed game carrying the `golden` **marker**: a *live* tournament. A player pays a **$1 buy-in** to become a member for the game's life; the game **gathers ten paid members** before its timer starts; the **buy-ins fund the prize pool** (per-guess fees are platform revenue); and at close the **top finishers split the pool proportionally** while every other member receives consolation clips. A never-filled gather voids and refunds the buy-ins. The full model is the decision surface `docs/codemojex/specs/economy/economy.md` §8 and the engine doc `echo/apps/codemojex/docs/golden-rooms.md`; the build rung is **cm.5** below. The earlier `gold_multiplier` boost is removed (`D-16`) — backend and canon drift absent from the product.

**The blind/sealed mode — the `golden` type.** Separately, the `golden` game *type* is the blind commit-reveal mode (shipped via cm.3): a player submits and receives no per-guess feedback; the game closes on the timer, reveals the secret, and settles once over every guess, paying the top K. It is carried by policy:

- feedback `none`, settlement `sealed`, a reduced emoji set (for example 18 or 24 cells) so the space stays tractable without hints, and an all-pay attempt economy where the fee is sunk whether or not a player places.
- a provably-fair secret: the game publishes a commitment at open and reveals the secret at close, so a player can verify the secret was fixed in advance.
- a forward anonymized leaderboard: generated neutral names and avatars, no real personas (lands with `RMP`).

The blind mode exists for anti-abuse: with no per-guess signal a feedback-driven clicker bot cannot hill-climb toward the secret, and the all-pay structure gives blind farming a negative expected value. Pool balancing and any house participation are an integrity decision held in the design, with transparent margin levers as the default.

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

### B7.4 · Scoring and Settlement

The score: distance per position on the linear scale, and a single batch settlement with a top-K payout for sealed rooms.

- **B7.4.1 · Distance and points** — distance is the absolute gap between a guessed position and the secret's; points run 100, 80, 60, 40, 20, 0, and an emoji not in the code scores zero.
- **B7.4.2 · The total out of 600** — the six position points sum to a score out of 600; the leaderboard ranks the raw best total — no tiers, no bonus.
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

The app today is a running game on the real EchoMQ, EchoData, Ecto, and Phoenix interfaces. The teaching arc now ships as the **standalone `/codemojex` course** — nine chapters (C0–C8) of three dives each: the six modules above reconciled to the as-built engine and extended with the shipped auth floor (cm.4), the revenue ledger and the KeyShop (cm.6/cm.7), and a production chapter — canonized in [`specs/course/`](./specs/course/course.toc.md), each page held to the A+ gates. The `/bcs/codemojex` chapter landing remains the BCS course's B7 and doors into the standalone course. The feature catalog (the systems still to build) is below in [§ The feature catalog](#the-feature-catalog); the binding design and the open questions are in [`codemojex.design.md`](./codemojex.design.md).

## The engine build ladder (spec-driven rungs `cm.N`)

> The section above (B7.1–B7.6) is the **course arc** — the teaching arc over the built game, canonized
> reconciled + extended as the standalone course map (C0–C8) in
> [`specs/course/course.toc.md`](./specs/course/course.toc.md). The
> ladder below is the **build ladder** — the spec-driven rungs that construct the engine, authored under
> `docs/codemojex/specs/`. The model the rungs build is canonized in [`codemojex.design.md`](./codemojex.design.md)
> (the `GAM` game entity, the type/policy discriminator, linear-only scoring, and the blind/sealed Golden
> mode);
> The slugs are `cm.N` (distinct from the course `B7.x`).

A new game mode is configuration on the same branded entities, so the ladder builds the **settled core
first** (buildable now), then the **blind Golden mode** (its forks ruled before its rung builds):

| Rung | Scope | Teaches (course) | Status |
|---|---|---|---|
| **cm.1 — the founding core** | the fresh Ecto schema (one clean initial create) · the `GAM` game entity (round→game rename, code + wire) · the type/policy discriminator + the `games_type` CHECK · **linear scoring, the bonus-tier economy removed** · the dev-DB reinitialization · classic live mode end-to-end | B7.1 · B7.2 · B7.3 · B7.4 (the linear scale) | ✅ **SHIPPED** (`specs/cm.1.{md,stories.md,llms.md}`) — built + committed via the `codemojex-game-rename` rung |
| **cm.2 — classic hardening** (optional) | any classic-mode polish cm.1 defers; folded into cm.1 | B7.3 · B7.6 | folded into cm.1 — no separate rung |
| **cm.3 — blind Golden** | feedback `none` + the privacy withholding · commit-reveal (`commitment`/`nonce`/`revealed_ms`) · sealed top-K settlement from the pool (the stored `payout_split`) · the per-game reduced set (`cell_count`/`cell_codes`) · the `revealing`/`settling` states | B7.2.3 · B7.4.3 · the Golden Rooms § | ✅ **SHIPPED** (`specs/cm.3.{md,stories.md,llms.md}`) — Arms V-7/V-8/V-14/V-15/V-16 ruled (D-15/D-16), built + committed via the `codemojex-game-rename` rung |
| **cm.4 — the auth floor** | verified Telegram `initData` (the pure `Codemojex.InitData` HMAC verifier) → a shared **`SES`-in-Valkey** session (the FIRST mutable `EchoStore.Table` — `:tracking` coherence + immediate revocation) · the handshake `POST /api/auth/:platform` (the sole `SES` mint) · the `:auth` plug + socket cutover to `conn.assigns.player` · `players.tg_user_id` resolve-or-create · **`POST /api/players` retired** (the free-money gap) | B7.5 (forward) | ✅ **SHIPPED** (`specs/cm.4.{md,stories.md,llms.md}` + `cm.4.postgres.design.md`) — the dual-architect HIGH-risk Squad rung (`cm-4`); the one pre-launch auth gap closed |
| **cm.5 — the Golden Room tournament** | the `:gathering` state machine (+ the `gathering` `games_status` CHECK value · the `ends_ms` `null:false` relaxation) · `start_threshold` (the gather gate, golden-default 10) · `Wallet.buy_in` (the two-sided debit + atomic SQL `+` pool credit · the `SET cm:<game>:paid NX` hint · the `transactions(player,ref) WHERE reason='buy_in'` partial unique index) · `close_split` (live-proportional top-K, mirrors `close_live`) + the consolation clips (`max_score/10`) · `close_void` (per-`(player,ref)` idempotent buy-in refund) · **wire a real sweep** (`close_if_expired` `rooms.ex:298` has zero callers — `I-9`) · the `gold_multiplier` reconcile-out · enforce `buy_in ⇒ not free` · the launch config (the free warm-up room + one Golden Room) | the Golden Rooms § | ✅ **SHIPPED** (`22cb2cf9`) — the `:gathering` state machine + `start_threshold` + `Wallet.buy_in` (two-sided debit + atomic SQL `+` pool credit + the `transactions(player,ref) WHERE reason='buy_in'` partial unique index) + `close_split`/`close_void`; the approved design (calibration `codemojex-golden-calibration`, ledger `D-17`/`D-18`). Built + committed (the golden_rooms migration `20260626120000`); **cm.6 books its five revenue movements on top**. *(Status reconciled at the cm.7 Stage-6 fold — the cell had lagged the as-built.)* |
| **cm.6 — the revenue ledger** (the `BNK` bank's first slice) | the dedicated **`revenue_ledger`** table (`RVL`-branded, signed `delta`, **no** non-negative CHECK, multi-source/multi-currency) · the house **platform-revenue account** booking the five Golden-Room revenue movements (seed · deposit-recovery · first-mover · full-revenue · void-reclaim) as explicit credits paired in the buy-in's `Repo.transaction` · the **keys-unit conservation** invariant (`Σ player debits == Σ house credits + Σ pool conversions`, proven by a property test against a cm.5-only computation) · the `Wallet.house_account/0` seam + the reconciliation read | B7.5 (the bank) | ✅ **SHIPPED** (`2de57202`; `cm-6` `D-1`..`D-12`) — built + verified through the money-critical L2 Squad: Venus-Postgres design · Mars build · **Apollo found the M5 floor-divergence survivor** (a fixed-example suite missed `div(pool,10)→div(pool,9)`) → Mars-2 closed it with the **spec-mandated conservation property test** + wired `entry_fee_split_keys` (one-floor STRUCTURAL conservation) · the ≥100 determinism loop 100/0 (the `RVL` mint is collision-free — the `EchoData.Snowflake` atomics-CAS). The dedicated `revenue_ledger` (signed, no-CHECK, multi-source/currency) + `Wallet.house_post`/`house_balance/0..1` (by account) + `revenue_breakdown/1` (by game). The BNK bank's foundation — cm.7 KeyShop + cm.8 withdrawal bind to it. *(Forward: a full-intake-double-entry rung itemizing the player buy-in keys-debit as a signed `TXN`.)* |
| **cm.7 — the KeyShop** (commerce, **multi-rail pay-in**) | the **`PKG`** packages catalog (keys · base Stars price · discount · active, **DB-stored** so the shop edits without a deploy) · a **multi-rail** order flow (`ORD`/`OTX`/`WHK` — one orders table + a rail discriminator; **`OTX UNIQUE(rail, external_id)`** the exactly-once gate per rail — the Telegram charge id · the on-chain tx hash · the processor settlement id) · the **Telegram XTR invoice** flow built end-to-end (`invoice → pre_checkout → successful_payment`) + the **TON/USDT/RUB** rails **shaped** (their verifiers forward) · a pure **`KeyShop`** net-revenue/store-fee/rail-rate module (the minor-unit convention F5: star/nanoTON/micro-USDT/kopeck; the rate **pinned per order**) · booking gross **purchase revenue** to the **same `revenue_ledger`** (`account="platform"`, `reason="purchase"`, `currency=`the rail — so `house_balance` sees it) | B7.5 · commerce | ✅ **SHIPPED** (`0acba290`; `cm-7` `D-1`..`D-10`) — built + verified through the money-critical L2 Squad: Venus + Venus-Postgres blind dual-architect design (D-3 caught `account="purchase"`→`"platform"`, the reconciliation bug `house_balance` would have hidden) · Mars build · Director verify (A1 exactly-once mutation-proven) · Director harden (150/150 determinism + migration up/down + from-zero reinit) · **Apollo BUILD-GRADE** (A1-A12 PASS; mutation kill-rate 3/3; replay + tamper attacks held; §5 spec-follows-code sync). **Multi-rail PAY-IN only** (withdrawals → cm.8); Telegram Stars end-to-end + TON/USDT/RUB schema-shaped (`D-5`); the `OTX (rail, external_id)` exactly-once gate closed the double-mint-on-replay hazard; gross purchase revenue booked to the **same `revenue_ledger`** (`D-3`). cm.6 byte-frozen; gate `mix test --include valkey` 129/0 (+ strict `--warnings-as-errors`). *(Forward, Apollo `L-6`: the first push-rail rung asserts `amount_minor >= order.price_minor` in `settle_payment`.)* |
| **cm.8 — cash-out / treasury** (withdrawals) | the **withdrawal** rail (diamonds → TON/USDT/RUB at **floating** rates) — a house **debit** (negative `revenue_ledger.delta` in the rail currency, the **same** `Wallet.house_post`, no new ledger verb) · **rate-pinning** at request time (the floating diamonds→rail rate snapshotted on the withdrawal record, reproducible) · a **`rates` table + poller** (the live floating-rate source cm.7 deferred from config) · **KYC/AML** + the **21-day hold** (`economy.packages.md`) + fraud · the house-balance debit + the treasury reconciliation | B7.6 + beyond | 📋 **NEXT after cm.7** (`cm-7` `D-2`) — the cash-out rung; cm.7 **designs-for** the withdrawal seam (the negative-`delta` debit shape) but builds none of it; the regulatory/fraud weight quarantined here |
| **cm.9+ — the further deferred** | the platform **rake** (a cut of the pool) · `RMP` membership + the anonymized leaderboard · growth (`SHR`) · analytics (`AEV`) · LiveAdmin treasury dashboards | B7.6 + beyond | 📋 named below (§ The feature catalog); out of the core engine's scope |

The gate is the codemojex app gate (`TMPDIR=/tmp mix compile --warnings-as-errors` + `mix test
--include valkey` on Valkey `:6390` + Postgres, plus the fresh-schema reinitialization on the
schema-landing rung). cm.1 (the settled core) and cm.3 (the blind/sealed Golden flow) **both shipped
on one schema** through the `codemojex-game-rename` rung — the founding core landed the six-table
model + the three brand re-bases (`RND`→`GAM`, `RMM`→`ROM`, `USR`→`PLR`) + classic mode, and the
blind flow landed the commit-reveal + sealed top-K on the same `games` columns. The per-rung audit
ledgers (and each rung's design-phase deliverable) were archived under `docs/codemojex/specs/progress/`
through cm.7 and retired from the working tree in the docs reorg (`7ffe0e29`) — that history is never
rewritten and remains in git; the settled spec triads under `specs/` are the living record.
The process that ships a rung is the **Codemojex Program** ([`program/codemojex.program.md`](./program/codemojex.program.md)).

> The tier `[RECONCILE]` is **closed**: the layering line and B7.4 above are now written to the
> as-built linear-only score (Operator-ruled: linear score only — no tiers, no bonus), and the
> reconciled, extended course map (C0–C8) is canonized in
> [`specs/course/`](./specs/course/course.toc.md).

## The feature catalog

The features that compose the complete game, grouped by system. The Game system is a generic Mastermind
engine; the classic live room, the Golden Room tournament, and the blind `golden`-type mode are modes of it, selected by policy — so reaching
the whole game is a matter of building these features, not new identity types. The **engine core**
(rooms/modes, the Mastermind engine, games + guesses, the blind Golden mode, the commit-reveal secret,
the three-currency transactional wallet, the classic + blind API) is **SHIPPED** on the as-built
brands — as are the auth floor (`cm.4`: verified `initData` → a shared `SES`-in-Valkey session, the first
mutable `EchoStore.Table`), the Golden Room tournament (`cm.5`), the revenue ledger (`cm.6`), and the
KeyShop (`cm.7`); the systems the catalog below marks 📋 are the **forward** `cm.8+` work.

> **Identity reconcile.** The as-built game re-based its single player entity to **`PLR`** (the
> `codemojex-game-rename` rung retired `USR`). The forward identity split named below — account (`USR`) /
> persona (`PLR`) / session (`SES`) / membership (`RMP`) — is the **deferred elaboration** that lands with
> the `SES`/`RMP` systems; today one `PLR` is the account, the persona, and the wallet owner. The catalog
> keeps the forward vocabulary so the target shape is on record.

### Identity and access ✅ (the `SES` session floor, cm.4) / 📋 (the `USR` account split)

- Verify Telegram `initData` and mint a short-lived session (`SES`) bound to an account (`USR`).
- Bind an account to a Telegram account id; one persona (`PLR`) per account to start.
- Resolve `PLR` and the account once, at session mint, and carry both in the session, so no request traverses the link mid-call.

### Player ✅ (core) / 📋 (profile)

- A `PLR` profile: display name, avatar, lifetime statistics.
- Name each player's guess lane by `PLR`, so the bus rotates service per persona.

### Rooms and modes ✅

- A `ROM` template: emoji set, duration, guess fee, paid or free, seed pool, and a mode.
- Two modes at launch: classic (live feedback) and golden (blind).
- A `ROM` carries the four engine policies: feedback, scoring, settlement, economy.
- 📋 A reified membership (`RMP`) with lifecycle (joined, active, left, banned) and a per-game display alias.

### The Mastermind engine ✅

- One secret, guess, and distance core shared by every mode.
- A feedback policy: `score` (0 to 600) or `none`.
- A scoring policy: linear distance (the one value today; one function for both modes).
- A settlement policy: `live` (close on a perfect score or the timer) or `sealed` (one batch at close, top K).
- An economy policy: the per-guess currency path and the payout curve.
- A `GAM` that carries its type, the four policies, the secret, the commitment, the timer, and its state.

### Games and guesses ✅

- The `GAM` state machine: scheduled, open, active, revealing, settling, settled, voided (CHECK-bounded).
- A guess (`GES`): six codes validated against the keyboard, with locked positions overlaid.
- Charge the currency path before accepting a guess; enqueue the guess as a job on the `PLR` lane.
- One consumer scores against the secret; the host never scores.
- Classic mode broadcasts the result; blind mode stores the guess and reveals nothing.
- Position locking, held in Valkey per player per game, persisting across guesses.

### The blind/sealed mode — the `golden` type ✅

- Accept guesses with no per-guess feedback for the game's life.
- Use a reduced emoji set (a per-game `cell_count` snapshot) to keep the space tractable without hints.
- Close on the timer; run one settlement pass over all guesses; pay the top K from the pool by the stored `payout_split`.
- An all-pay attempt economy: a per-attempt fee is sunk whether or not a player places.
- 📋 An anonymized leaderboard: generated neutral names and avatars (lands with `RMP`).

### The Golden Room tournament ✅ (cm.5)

- A `classic`-typed game with the `golden` **marker** — a live tournament, NOT the blind type and not a boost class (the `gold_multiplier` boost is removed, `D-16`).
- A **$1 buy-in** is membership for the game's life (a `buy_in` `TXN`, cached in ETS); a `:gathering` state holds the game until **ten paid members** gather, then the live timer starts.
- Buy-ins **fund the prize pool** (the keystone `$1 × 10 = $10` guaranteed, break-even); per-guess fees are platform revenue.
- At close the **top finishers split the pool proportionally** (`close_split` reusing `Economy.top_k_split`); every other member receives consolation clips (`max_score/10`).
- A never-filled gather **voids and refunds the buy-ins** exactly once (`close_void`); the periodic sweep (`Codemojex.Sweep`) drives the timer-close and the never-fills void.

### Provably-fair secret (commit-reveal) ✅

- At room open, publish a commitment — SHA-256(secret ‖ nonce), lowercase hex — over the secret and a nonce on the `GAM`.
- Keep the secret and the nonce server-side and sealed for the room's life.
- At close, reveal the secret and the nonce, and expose them so a player can recompute the commitment and verify it.
- Score settlement against the revealed secret; the commitment binds the server to the secret it fixed at open.

### Economy and the bank ✅ (wallet + the `RVL` revenue ledger, cm.6) / 📋 (the `BNK` escrow + rake)

- Three currencies: keys (paid rooms, bought with Stars), clips (free rooms, no value, excluded from the available balance), diamonds (prizes, convert to keys at ten to one).
- A transactional wallet: a row lock, the non-negative check, a paired ledger row, all or nothing; the paid and free paths never cross.
- The `RVL` revenue ledger (cm.6): the house platform-revenue account — signed deltas, multi-source/multi-currency, the keys-unit conservation property test.
- 📋 A `BNK` escrow per game: the pool accrues from fees and pays out at settlement (today the pool lives on the game's own `prize_pool`).
- 📋 A published platform rake; the remainder of the pool pays the board.
- Settlement that is pure and idempotent, so a re-run pays identically.

### Commerce ✅ (multi-rail pay-in, cm.7) / 📋 (cash-out, cm.8)

- A package catalog (`PKG`): bundles of keys for Telegram Stars.
- A purchase order (`ORD`) with state: created, pending, paid, fulfilled, failed, refunded.
- A payment ledger (`OTX`) per rail — Telegram Stars end-to-end, TON/USDT/RUB shaped — with `UNIQUE(rail, external_id)` the exactly-once gate, kept separate from the currency ledger (`TXN`).
- Inbound webhooks (`WHK`): idempotent, processed once, driving `ORD` and `OTX`.
- On paid, credit keys to the wallet as a `TXN`.

### Growth 📋

- Share and referral tokens (`SHR`): who shared what, and the redemptions.
- A disclosed bonus on redemption, granted through the economy, never a direct write.

### Analytics 📋

- An append-only event stream (`AEV`), emitted by every system, one-way.
- Never authoritative; rebuildable by replay.
- Powering the admin dashboards and live counters.

### API and realtime ✅

- A JSON API through the `Codemojex` facade and the privacy-safe views.
- Commands over REST: auth, lobby, join, submit guess (accepted, not scored on the request), buy, convert.
- A live channel per game for classic rooms: results, leaderboard, timer, and state changes.
- For blind rooms, a channel that carries state and timer only, with no results until the one fat `revealed` event at close.

### LiveAdmin 📋

- Rooms and packages management; emoji set and sprite uploads (`EMS`, `RSC`).
- A live board of active games with state, pool, and player counts.
- Treasury: the bank, payouts, the rake, refunds.
- Commerce: orders, payments, the webhook log, reconciliation.
- Players and moderation: ban through membership status.
- Analytics dashboards over the `AEV` stream.

### Anti-abuse and integrity ✅ (engine) / 📋 (policy)

- Golden Rooms break feedback-driven clicker bots: with no per-guess signal, a bot cannot hill-climb toward the secret.
- The all-pay economy gives blind farming a negative expected value.
- The commitment removes the rigged-secret vector.
- House participation and pool balancing are a decision for the Chief Architect and legal review; the default is transparent margin levers — a published rake, a capped or guaranteed pool, a minimum-participant threshold before a real pool forms — not undisclosed house players. The open questions are recorded in [`codemojex.design.md`](./codemojex.design.md) (§ Open questions).
