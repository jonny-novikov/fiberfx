# Codemojex · Design

<show-structure depth="2"/>

Codemojex is a real-time, multiplayer code-breaking competition that runs as a Telegram Mini App — Mastermind played with an emoji keyboard, for money. This document is the binding design of the `codemojex` application as it stands in the Echo umbrella: its engine, its systems, its messaging, its storage tiers, its data model, the way it is built and deployed for production, and the questions still open before launch. It is written against the source, not ahead of it — every module, namespace, table, and Valkey key named here exists in `echo/apps/codemojex`.

The design is one instance of the Branded Component System: each part of the game is a system that owns its state, and the only things that cross a boundary are branded identities and messages about them. The four libraries beneath it — `echo_wire` (the wire), `echo_data` (the id and the stores), `echo_mq` (the bus), and `echo_store` (the near-cache and the durable floor) — compose into the umbrella, and Codemojex is the application that sits on top of all four.

## The engine — a generic Mastermind, the modes are policy

The Game system is a **Mastermind engine**. The family is defined by two things only — a **code space** (positions, a symbol set, the duplicate rule) and a **feedback function** (what a guess reveals about the secret) — and **everything else is policy**. A game holds the secret, the timer, the state, a **type**, and the four policies the type selects; the secret, the guess, and the distance math are one code path shared by every type, and the type branches only the edges: what the view exposes per guess, when settlement runs, and how the pool pays.

This is why the model is **one `games` table with a type discriminator**, not a table per type: in BCS the 14-byte brand *is* the entity's type, and the only value that crosses a boundary is that identity — a per-type table would fork the one `GAM` identity that travels from Postgres to the cache to the bus to the channel. No new entity types separate the modes. A radical variant is a new set of policy values on the same entities, not new code.

The two launch types:

| Type | Feedback | Settlement | Scoring | Economy |
|---|---|---|---|---|
| `classic` | `score` — live per-guess 0–600 | `live` — close on a perfect crack or the timer | linear distance | per-guess fee, winner-take-all pool |
| `golden` | **`none`** — no per-guess signal until reveal | **`sealed`** — one batch at close, pay the top K | linear distance | per-guess fee (all-pay), boosted pool, top-K split |

Golden is the blind/sealed mode: a player submits and receives no per-guess feedback, the room accrues a pool over its life, closes on the timer, and settles once over every guess — paying the top players whose combinations were closest, against a secret the server committed to in advance. Both modes share one linear scoring function; the difference is the feedback and the settlement, not the math.

## The game in one paragraph

A room is a template; a game is one play in it. The first player to join a waiting room starts a game: the room's emoji set and props are snapshotted, a secret of six distinct codes is drawn, and a timer begins. Players submit six-emoji guesses; each guess is charged a fee and scored by distance from the secret, with a per-position score of `100 - 20·d` summing to 600 for a perfect crack. Scores feed a per-game leaderboard, ranked by the player's best linear total. For a classic game, a perfect crack or the timer expiring closes the game and pays its diamond prize pool winner-take-all to the top scorer; for a golden game, the timer closes it, the secret is revealed, and a sealed pass pays the top K. Three currencies move through the game — keys, clips, and diamonds — each in its own lane, all mutated atomically in Postgres.

## The architecture at a glance

Codemojex is four layers, and the layering is the architecture. Requests enter at a thin Phoenix surface, durable work travels on the EchoMQ bus to a small set of authorities, and state rests in three tiers chosen by what each kind of data needs.

```
Telegram Mini App  ──HTTPS/WSS──▶  Phoenix surface (CodemojexWeb)
                                    │  JSON API + Channels, privacy-safe views
                                    ▼
                                   Codemojex facade  ──▶  domain systems
                                    │   (Rooms · Guesses · Scoring · Wallet · Board · …)
                                    ▼
                                   EchoMQ bus on Valkey
                                    │   fair lanes: guesses · settle · notify · commands
                                    ▼
                  ┌──────────────── consumers (the authorities) ─────────────────┐
                  │  ScoreWorker     Settle      NotificationWorker   CommandWorker │
                  └──────────────────────────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼─────────────────────────────┐
        ▼                           ▼                             ▼
   Postgres (SoR)            Valkey (bus · board · L2)      EchoStore tables (L1)
   players · txns ·          leaderboard ZSET ·             games · emoji sets
   rooms · games ·           player/attempt counters ·      (immutable, coherence :none)
   emoji_sets · guesses      close lock                     → optional Graft floor → Tigris
```

A read of immutable game data hits an in-process ETS cache; a guess is a job on a per-player lane; money is a relational transaction; the leaderboard is a Valkey sorted set. Nothing in the picture is merged — the boundaries are real, and the same code runs whether the systems share a node or not.

## Identity: the branded component law

Every entity in Codemojex is a 14-character branded snowflake: a three-character uppercase namespace followed by eleven Base62 characters encoding a 63-bit snowflake (`ts(41) | node(10) | seq(12)`, epoch `1704067200000`). The id is typed, time-ordered, and placeable, and it is the only key that crosses a boundary — it keys the row in Postgres, the entry in Valkey, the job on the bus, and the message that announces a result. The brand *is* the type: `EchoData.BrandedId.generate!/1` validates by shape, not a registry, so the brand carried on a value is what gets checked at every boundary.

Nine namespaces carry the game today:

| Namespace | Entity | Lives in                                         |
|-----------|-------|--------------------------------------------------|
| `PLR`     | player | Postgres `players`, Valkey lanes/board           |
| `ROM`     | room (template) | Postgres `rooms`                                 |
| `GAM`     | game | Postgres `games`, EchoStore `:cm_games`          |
| `GES`     | guess | Postgres `guesses`                               |
| `EMS`     | emoji set | Postgres `emoji_sets`, EchoStore `:cm_emojisets` |
| `TXN`     | wallet transaction | Postgres `transactions`                          |
| `JOB`     | a unit of work on the bus | Valkey (the queues)                              |
| `NOT`     | an outbound notification | Valkey (the notify lane)                         |
| `CMD`     | an inbound bot command | Valkey (the commands lane)                       |

The forward namespaces the roadmap schedules for the deferred systems (`RMP` membership · `BNK` bank · `SES` session · `RSC` resource · `PKG`/`ORD`/`OTX`/`WHK`/`SHR`/`AEV` for commerce, growth, analytics) land with their systems; the nine above are the as-built set.

Because the id carries its mint time, it doubles as a version: a game's secret and an emoji set are immutable for the game's life, so the entity's own id is a sound cache version and a sound idempotency token.

## The systems

The domain is a set of small modules, each owning one concern and speaking maps across its boundary. The `Codemojex` module is a thin facade that delegates into them; nothing else reaches across.

**Play — `Codemojex.Guesses` and `Codemojex.Locks`.** The play API validates a six-emoji guess against the game's keyboard, overlays the player's locked positions, charges the right currency through the wallet, and enqueues the guess as a `JOB` on the player's own lane. The host never scores; it accepts and enqueues. Locks let a player pin a code at a position so it persists across their guesses.

**The scoring authority — `Codemojex.ScoreWorker` and `Codemojex.Scoring`.** Scoring is a pure function: a guessed emoji that exists in the secret earns `100 - 20·d` for its distance `d`, zero for a miss, summing out of 600. The worker is the single authority that runs it — it reads the secret through the cache, scores, writes a `GES` guess, records the result on the leaderboard, and (for a classic game) publishes the outcome. The purity is load-bearing: a re-delivered guess re-scores to the same number. The score is linear only — there is no tier ladder and no first-mover bonus; the raw best total is the rank.

**Rooms and the keyboard — `Codemojex.Rooms` and `Codemojex.EmojiSet`.** A room holds the props a game inherits — emoji set, duration, seed prize pool, guess fee, whether it is free, its type, the sealed `payout_split`, and the reduced-set `cell_count`. An emoji set is a sprite sheet plus the cells a room exposes; a code is `XXYY` (column then row), and a game's secret is six distinct codes drawn from the game's snapshotted keyboard. The player-facing snapshot of a set carries the keyboard and nothing the secret could leak from.

**Money — `Codemojex.Wallet`, `Codemojex.Economy`, `Codemojex.Ledger`.** Balances live in Postgres and move only inside database transactions; the pure math (conversion rates, the winner-take-all split, the sealed top-K split, USD formatting) lives in `Economy`, and the append-only statement is read through `Ledger`. The wallet is the one system where correctness outranks speed.

**Competitive state — `Codemojex.Board`.** The leaderboard is a Valkey sorted set per game, scored by the player's best linear total. A separate in-memory CHAMP projection (`Codemojex.Leaderboard`) is available as a rebuildable view.

**Reads — `Codemojex.View`.** The player-facing reads carry the privacy invariant in their shape: no view returns the secret, and no view returns another player's guesses. For a golden game the gate widens — no score crosses the wire until the game's `revealed_ms` is set.

**Gateways — `Codemojex.Notifier`, `Codemojex.EchoBot`, `Codemojex.RateLimiter`, `Codemojex.Telegram`.** Outbound messages and inbound bot updates both ride the bus as jobs on per-chat lanes; the rate limiter is a token bucket that turns "too soon" into a delayed re-enqueue rather than a blocked process; `Telegram` is the dependency-light HTTP transport for the send side.

## Messaging: the EchoMQ bus

The bus is the spine of the runtime. `Codemojex.Bus` holds one RESP3 connector to Valkey in `:persistent_term`; everything that touches the queue goes through it, so there is a single supervised path to the store. Work is dropped onto the bus with `EchoMQ.Lanes.enqueue/5` and drained by `EchoMQ.Consumer`, and the enqueue is idempotent — a re-enqueued `JOB` answers `:duplicate`, not a second unit of work.

Four lanes carry four kinds of work, each grouped so one heavy producer cannot starve the rest:

- **Guesses** — queue `cm`, lane keyed by the player's `PLR`. The bus rotates service across players, so one fast tapper does not freeze the field.
- **Settlement** — queue `cm-settle`, lane keyed by the game's `GAM`. Closing a game is its own job, never an ungrouped enqueue, so a draining consumer always finds it.
- **Notifications** — the notify lane, keyed by chat, drained by the rate-limited `NotificationWorker`.
- **Bot commands** — `bot.commands`, keyed by chat, drained by the `CommandWorker` that the bot gateway feeds.

Two patterns recur. The first is the move-then-settle split: the guess queue competes, and a separate settle queue pays, so contention and payout never share a path. The second is the delayed re-enqueue: when the rate limiter reports a guess arrived too soon, or a notification hits a transient failure, the worker re-enqueues the same job with `EchoMQ.Jobs.enqueue_in/5` after a computed delay, with capped exponential backoff — the worker defers rather than blocks.

When the scoring worker finishes a guess in a **classic** game, it announces the result twice for two audiences. It publishes a `scored` event on the bus with `EchoMQ.Events` for any bus consumer, and it broadcasts a `:scored` message over Phoenix PubSub on the game's topic for the live surface. Both carry the player's name, percentage, and effective score — and neither carries the secret or the guess content. A **golden** game suppresses this per-guess announcement entirely: it stores the guess and reveals nothing until the sealed reveal at close.

## Storage tiers

Codemojex keeps three tiers and places each kind of data on the one that fits it. The id runs through all of them, so a piece of state is one name asked at different depths, not three schemes translated between three stores.

**Postgres — the system of record.** The durable, queryable truth: `players` and their `transactions`, `rooms`, `games` (secret included, server-side), `emoji_sets`, and `guesses`. Money and history are relational because they need locks, constraints, and ordered queries.

**Valkey — the bus and the live competitive state.** Three roles on one engine: the EchoMQ queues; the leaderboard and its machinery (a sorted set per game, the player set, the attempts and total-won counters, and the game-close lock); and the L2 layer shared by the near-cache. This is the hot, volatile half — fast, and rebuildable from the system of record.

**EchoStore — the near-cache, declared in `Codemojex.Tables`.** Two L1-over-L2 caches sit in front of Postgres on the scoring hot path: `:cm_games` (`GAM`, the game and its secret) and `:cm_emojisets` (`EMS`, the keyboard). A read is a caller-side `:ets` lookup; a miss coalesces onto one in-flight fill that checks L2 and falls through to a loader that reads Postgres, writing both layers under a TTL. Because both entities are immutable for the game's life, coherence is `:none` and the cache never goes stale. The directory the tables register into is supervised first under `:rest_for_one`, so if it ever restarts the tables restart with it and re-register.

**The durable floor — optional, via `EchoStore.Graft`.** When a `:graft_volume` is configured, `Codemojex.Application` starts the Graft committer: a single-writer page store on an append-only B-tree that folds to Tigris object storage behind a create-only conditional-write fence. It is the replicated substrate beneath the volatile half, and the app boots cleanly without it.

## The data model

The relational schema is six tables, each keyed by a branded id and carrying its own status word as text. (`NOT`, the notification brand, is a Valkey bus lane, not a Postgres table — there is no `notifications` table.)

- **`players`** — `PLR` key; `keys`, `clips`, `diamonds`, `bonus_diamonds`, `locked_diamonds` as non-negative big integers, guarded by a CHECK constraint the wallet leans on as a backstop, plus a nullable `tg_chat_id` for the notification address. (`bonus_diamonds` is a promotional **wallet bucket** — not a game scoring bonus; the "no bonus tiers" rule targets scoring, not the wallet.)
- **`transactions`** — `TXN` key; `player`, `currency`, `delta`, `reason`, `ref`; append-only, indexed by `(player, inserted_at)` for a statement. The `player` column holds a `PLR` id — the column name is the wire word, the id value carries the brand.
- **`emoji_sets`** — `EMS` key; the sprite grid (`cols`, `rows`, `cell_size`, `sprite_url`) and the exposed `codes` — the full keyboard. The two seeded sets are measured from the real sprite sheets under `docs/codemojex/emoji-sets/` at `cell_size` 72 (a `10×15` 150-cell sheet and a `10×21` 210-cell sheet).
- **`rooms`** — `ROM` key; the template props and at most one active `game` — including the room's default game `type`, the `payout_split` policy (the sealed-split weight array), and the reduced-set `cell_count` (nullable; null = the full keyboard).
- **`games`** — `GAM` key; the per-play entity. It carries:
  - the `type` discriminator (`classic` | `golden`), bounded by a `games_type` CHECK, and the four policy columns it selects — `feedback`, `scoring`, `settlement`, `economy` — snapshotted from the room at start and immutable for the game's life;
  - the `secret` (server-side, selected by no player-facing query) and `cell_codes`, the game's snapshotted keyboard (a randomized `cell_count`-cell subset of the room's codes, or the full set) the secret is drawn from;
  - the commit-reveal columns for the blind mode — `commitment` (SHA-256 of the secret ‖ nonce, lowercase hex, set at open), `nonce` (server-side, sealed, revealed at close), `revealed_ms` (the privacy gate), `top_k` (the sealed payout breadth, default 5), and `payout_split` (the snapshotted weight array, default `[40,25,15,12,8]`);
  - the timer, the diamond `prize_pool`, the fee props, and the `golden`/`gold_multiplier` boost;
  - the `status`, a CHECK-bounded text word over the seven canon states `scheduled · open · active · revealing · settling · settled · voided`. Classic traverses `open → settled`; golden traverses `open → revealing → settling → settled`; `voided` is the abort path; indexed by `room`.
- **`guesses`** — `GES` key; the player's `emojis` and the linear `points` (sum of `100 - 20·d`, out of 600); indexed by `(game, player)`. There is no `tier` and no `percentage` column — the linear `points` is the sole stored score; a percentage is computed on read if surfaced, never stored.

Alongside it, the Valkey keyspace for one game is a small family under `cm:<game>:` — `board` (the sorted set, ranked by the best linear total), `base` (the per-player best-total hash that feeds the ZSET), `players` (a set), `attempts` (a counter), and `closed` (the one-shot close lock) — plus a per-player `lock:<player>` hash and the global `cm:total_won`. There is no `ptier`/`bonus`/`tierfirst` layer: the leaderboard ranks the raw best total, so the score a player sees is the score they earned.

### The game as a state machine

A room is a template and a container; a game is one playthrough inside it, with a small state machine. When a player joins a waiting room, a game is formed: a fresh six-emoji secret is minted from the game's snapshotted keyboard, the room's properties and policies are snapshotted onto it, an end instant `ends_ms` is set, and the game enters `open`.

```
        join a waiting room
                │
                ▼
          ┌──────────┐   guess → score (the cm lane)
          │   open   │◀──────────────────┐
          └────┬─────┘                   │ board + events (classic)
   600 crack   │  or timer ends_ms       │
   or a sweep  ▼                          │
        SET cm:<game>:closed NX ──────────┘
                │  (only the winner of the SET proceeds)
                ▼
    classic ─▶ settled                golden ─▶ revealing ─▶ settling ─▶ settled
              (winner-take-all,                 (reveal secret+nonce, score
               room returns to waiting)          the sealed batch, pay top-K)
```

`open` accepts guesses; `Codemojex.Guesses.submit/3` admits a guess only while the status is `open` and `ends_ms` has not passed. A classic game leaves `open` on a perfect crack of 600 inside the scoring authority or on the timer under a sweep; a golden game leaves only on the timer (there is no per-guess signal, so no early close). Both transitions take an exactly-once `SET cm:<game>:closed NX` — the single caller that wins it settles; every other caller is a no-op. `settled` is terminal, and a classic room returns to waiting to form the next game.

## Core flows

**A guess, end to end.** The surface accepts `POST /games/:id/guess` and returns immediately. `Codemojex.Guesses` reads the game from the system of record, checks it is open and unexpired, validates the six emojis against the keyboard, overlays the player's locks, and charges the fee through the wallet; only a charged guess is enqueued on the player's lane. The `ScoreWorker` claims it, reads the secret through the cache, scores it, writes a `GES` guess, increments the game's attempt counter, records the result on the board, and — in a classic game — announces it on the bus and over PubSub; a golden game stores the guess and announces nothing. A perfect 600 closes a classic game there and then.

**Settlement, exactly once.** A game closes from one of two triggers — a perfect crack (classic only), or an expired timer — and the two can race. The close path takes a one-shot lock with an atomic `SET … NX` on `cm:<game>:closed`; only the closer that wins it pays, and the loser is a no-op. For a **classic** game the winner reads the top of the board, computes the winner-take-all split over the diamond pool (shared evenly on a tie), deposits each prize through the wallet, bumps the global total-won counter, marks the game `settled`, and returns the room to waiting. A **golden** game reveals the secret and nonce, scores every guess against the revealed secret with the same linear function, ranks players by their best total, and pays the top `top_k` from the pool — each rank `i` taking its weight share `payout_split[i] / Σ payout_split` of the effective (boosted) pool, with the integer-division remainder added to rank 1 so the whole pool is distributed. The pass is pure and guarded, so a re-run pays identically.

**The economy.** Three currencies, each in its own path: keys pay for guesses in paid rooms and are bought with Telegram Stars; clips pay for guesses in free rooms and carry no value; diamonds are the prize currency, won from rooms and convertible to keys at a fixed 10:1. Every balance change is a database transaction that locks the player row with `SELECT … FOR UPDATE`, checks the non-negative invariant, writes the new balance, and inserts the paired `TXN` ledger row — all or nothing. The row lock serializes only same-player mutations, so the field is never funnelled through one process; the database does the work a single-writer process would have, and scales with it.

**The leaderboard.** A scored guess updates the player's best linear total in the `cm:<game>:base` hash and writes that total to the sorted set; the board is ranked by the raw best total. There is no tier race, no bonus, and no effective-vs-base distinction — the score a player sees is the score they earned.

**The provably-fair secret (golden).** At open, a golden game draws the secret and a nonce, computes `commitment = SHA-256(secret ‖ nonce)` over a canonical UTF-8 encoding (the six codes joined by a record separator, then the nonce, emitted as lowercase hex — zero new dependency), and stores all three; the secret and nonce are sealed server-side, the commitment may be exposed at open so the player records it. At close the secret and nonce are revealed so any player recomputes the commitment and checks it — the commitment binds the server to the secret it fixed at open. This converts a server the player must trust into a server the player can check.

## The web surface

The surface is a thin Phoenix application, deliberately small. A JSON API under `/api` covers the lifecycle: a health check, player creation, the room lobby, joining a room, a game view, submitting a guess, a player's own history, the leaderboard, and the two key operations (buy and convert). Every action calls the `Codemojex` facade and the privacy-safe views; a guess returns an accepted-and-on-its-way response while the bus carries the scoring, and there is no process per room, so a large field of idle rooms costs nothing.

The live half is Phoenix Channels. A client joins `game:<id>`, which subscribes the channel to the matching PubSub topic. For a classic game, when the scoring worker finishes an attempt the channel pushes the `scored` event to the client, and the leaderboard updates without any per-room process. For a golden game the channel carries state and the timer only — no per-guess results — until the sealed reveal at close pushes the revealed secret, the final board, and the payouts in one fat `revealed` event. Joins return the game view, never the secret (and, for a golden game, the public commitment but never its preimage), and a refresh re-reads the view and the board on demand.

Player identity is read from the request today and is the one explicit gap before launch: in production it must come from verified Telegram `initData`, whose signature the server checks with an HMAC-SHA-256 over the bot token keyed by the constant `WebAppData`. Until that check is wired, the surface trusts a supplied id.

## Privacy and fairness

The privacy boundary is structural, not a filter at the edge. The secret exists in exactly one place a player can never read — the game row in Postgres and its immutable cache copy — and no player-facing view selects it; the keyboard snapshot, the game view, and the leaderboard are each shaped to carry only what is public. A player sees their own attempt history and no one else's. The live events that fan out carry a name and a score, never the code or the guess. A golden game tightens this further: it publishes the commit-reveal **commitment** (public by design — it binds the server to the secret it fixed at open) but never the commitment's **preimage** (the secret and the nonce), and it emits no per-guess results at all; only the sealed reveal at close exposes the secret and the nonce, so a player can recompute the commitment and verify it.

Fairness has two meanings here, and the design serves both. Procedural fairness is the per-player lane on the guess queue: service rotates across players, so paying for speed buys a turn, not the field. Economic fairness is the candid economy — every guess pays a fee, the prize pool is platform-seeded and stated, and the conversion rate is fixed and public, rather than hidden house entries playing against the field. The blind mode adds an anti-abuse property: with no per-guess signal a feedback-driven clicker bot cannot hill-climb toward the secret, and the all-pay structure gives blind farming a negative expected value. The exact fee and pool terms are the kind of decision that belongs with the chief architect and legal review before launch (see Open questions).

## Fault tolerance and correctness

The runtime is a single supervision tree, and the order is the dependency order:

```
Codemojex.Supervisor (one_for_one)
├─ Codemojex.Repo                     # the system of record
├─ Phoenix.PubSub (Codemojex.PubSub)  # the live fan-out
├─ Codemojex.Bus                      # the shared RESP3 connector to Valkey
├─ Codemojex.Tables (rest_for_one)    # the EchoStore near-cache tier
│  ├─ EchoStore.Directory             #   started first; a restart cascades
│  ├─ EchoStore.Table :cm_games
│  └─ EchoStore.Table :cm_emojisets
├─ Codemojex.RateLimiter
├─ Codemojex.EchoBot
├─ EchoMQ.Consumer :cm_score          # the scoring authority
├─ EchoMQ.Consumer :cm_settle         # the settlement worker
├─ EchoMQ.Consumer :cm_notify         # the rate-limited notifier
├─ EchoMQ.Consumer :cm_commands       # inbound bot commands
├─ EchoData.ChampServer (Leaderboard) # an in-memory CHAMP projection
├─ [EchoStore.Graft.Committer]        # optional, when :graft_volume is set
└─ CodemojexWeb.Endpoint              # the HTTP/WS surface
```

Delivery is at-least-once, and every handler is idempotent so re-delivery is harmless. Scoring is pure, so a re-scored guess is identical; settlement is guarded by the one-shot `SET NX` lock; the golden sealed pass is pure and idempotent, so a re-run pays identically; the wallet is a database transaction backed by a CHECK constraint. Each consumer leases the job it is working, so a crashed consumer's in-flight job becomes visible again rather than lost, and its supervisor restarts it in place. The near-cache tier uses `:rest_for_one` so a directory restart re-registers the tables, and cache writes are best-effort — a Valkey blip or a table restart can never fail the writer recording a game or a set.

## Production deployment

The release is a `mix release codemojex` built from the umbrella root in a pinned image (Elixir 1.18.4 / OTP 28.5.0.1). The multi-stage Dockerfile compiles `codemojex` over its in-umbrella dependencies — `echo_mq`, `echo_data`, `echo_wire`, and `echo_store` — builds `echo_data`'s native branded-id codec, and assembles a self-contained release onto a slim runtime stage. `echo_store` is a first-class dependency, so the image builds its SQLite C-NIF (exqlite) and CubDB; `echo_bot` and `echo_graft` stay out, each its own concern.

The bus's Valkey runs as its own machine, not in the web container. The app reaches it over the private network; the connector dials a fixed host and a configurable port. The same image runs locally under docker compose: Postgres, the Valkey the bus expects on its connector port, and the endpoint, wired the way Fly wires them. A health check at `/api/health` lets a machine that stops answering be taken out of rotation, and the endpoint stays up across a rolling deploy so a live channel is not dropped under a player. Production deployment, the Valkey machine, and the kernel tuning are covered in depth in the BCS course chapter on production, served at `/bcs/fly`, and in the dedicated `echo-valkey` datastore configuration.

### The pragmatic Valkey node

The recommendation is short because the constraint is sharp: Valkey runs commands on one thread, so the machine is sized for a steady latency tail, not for throughput headroom. The launch node is **Valkey 9.1** over its bundled jemalloc on a Fly **`shared-cpu-2x`, one-gigabyte** machine, eviction off.

- One gigabyte forces the shared class. `io-threads` stays at **1** — extra I/O threads busy-wait and would drain the shared burst balance even while idle; the second vCPU is left for the background threads that sleep (the `everysec` AOF fsync on its own thread, jemalloc's background purge, the lazy frees).
- `maxmemory` is a loud **512-megabyte** guardrail under **`noeviction`**, far above a working set that is single-digit megabytes (player balances live in Postgres), so a runaway keyspace rejects writes rather than being killed.
- Durability is **AOF alone** (one fork source); jemalloc is the allocator the resident-size budget depends on.
- The node is private by construction — bound to the IPv6 wildcard so it answers only on the org's 6PN, reachable at `codemojex-valkey.internal:6390`. Its volume lives on one host in one region — the single point of failure to retire with a replica before real money flows.

The pragmatic upgrade ladder, each step on evidence: add a replica in the primary region; split the Phoenix web and worker process groups; move Phoenix to a performance machine when guess throughput is sustained; and shard Valkey by hash tag only when one command thread is finally the bottleneck.

Two version-9 touchpoints sit on paths the bus exercises directly. The closed-game keys (the board, the hashes, the counter, the marker, the lock hashes) are not expired by the close today, so under `noeviction` they accumulate — a key-level expiry at close fixes it on any version, and `HEXPIRE` gives per-field control where a hash should outlive some of its fields. The lock plane's marker can collapse to one self-expiring hash field and release by token with `DELIFEQ` rather than an unconditional delete. And the 9.1 fixes sit on paths the bus uses — the stream-trim null-deref on `EchoMQ.Stream.trim`, and the rehashing latency reduction on the lane sorted sets and the job-hash dictionary as they grow.

## Configuration

The app reads a small set of knobs, all with sensible defaults:

- `:valkey_port` — the port the bus connector and the cache tables dial (the connector host is fixed). The whole runtime shares one port.
- `:graft_volume` — when set to a volume id, the durable Graft committer starts; absent, the replicated floor is not in the tree.
- `:games_cache_ttl_ms` / `:sets_cache_ttl_ms` — the TTLs for the two near-caches; both entities are immutable, so the TTLs are generous.

A note on building and running: this app is parse-verified in the sandbox, and the faithful compile and release are produced in the pinned 1.18.4 / OTP 28 image, where the native codec and the SQLite C-NIF are built. The sandbox toolchain is older, so `mix compile` and `mix release` belong to the image, not the bench.

## Open questions (for the Chief Architect and legal review)

Codemojex is a generic Mastermind engine on BCS, and the Golden Room is a mode of that engine rather than a separate product. The model is settled; the questions that remain are product, integrity, and regulatory ones, recorded here so they are decided deliberately. Two that bore on the schema have since been **ruled** and are noted as resolved.

- **House participation.** Should the platform ever field system-controlled players, and if so, must it be disclosed? Undisclosed house players that win prizes back from paying users in a real-money contest are likely deceptive and unlawful in many jurisdictions, and they interact badly with an anonymized leaderboard that would hide them. The recommended default is transparent margin levers — a published rake, a capped or guaranteed pool, a minimum-participant threshold before a real pool forms — which bound the house's exposure without deception. A decision and a jurisdiction review are needed before any house-participation mechanism is built.
- **Regulatory classification.** A paid-entry, prize-pool, blind-outcome mode may be regulated as gambling in some jurisdictions, while the live skill mode may be treated differently. Where can paid rooms operate, and under what licensing and age and region gating? Eligibility is a config seam and a launch-gate decision — a join-time predicate with a permissive default — not a schema-shaping column.
- **Code-space sizing.** What reduced symbol-set size (`cell_count`) balances tractability against the no-feedback difficulty, and how is it tuned as traffic changes?
- **Settlement atomicity.** Settlement moves real money across many wallets in one pass; how is it made atomic and idempotent — a single transaction per game, or a staged ledger with one commit — and how are partial failures recovered? Today the pass is pure and guarded by the one-shot close lock, paying from the game's own pool.
- **Anonymization mapping.** Is the alias stable across a player's rooms or fresh per game, and where is the mapping held so a client cannot correlate it back to a real identity? The alias rides the later `RMP` membership; until then a golden leaderboard ranks by `PLR`, and the reveal-gated privacy already secures the blind contest.
- **Live-mode anti-abuse.** Beyond the blind mode, what controls does the live mode need (rate limits, attempt caps, device and account signals), and how do they interact with the per-guess economy?
- **Withdrawal and identity verification.** Diamonds convert to keys but are not withdrawable today; if cash-out is ever added, what verification and anti-fraud controls apply?
- **Scoring unification — RULED.** The live linear-distance score and the blind ranking share **one** linear scoring function behind a policy switch; the difference between modes is feedback and settlement, not the math.
- **Commitment scheme — RULED.** The provably-fair commitment is **SHA-256(secret ‖ nonce)**, lowercase hex, over a canonical UTF-8 encoding — the lean instantiation, publishable for the player to recompute (an HMAC's keyed secret cannot be, and a per-cell commitment would leak structure).

## References

- [Mastermind (the board game)](https://en.wikipedia.org/wiki/Mastermind_(board_game)) — the guess-against-a-hidden-code loop Codemojex plays with emoji.
- [The feedback function and minimax code-breaking](https://arxiv.org/abs/1607.04597) · [a related analysis](https://arxiv.org/abs/1207.0773) — the deductive structure the engine's distance scoring sits in.
- [Commitment schemes (commit and reveal)](https://en.wikipedia.org/wiki/Commitment_scheme) — the hiding + binding properties the golden secret needs.
- [All-pay auction](https://en.wikipedia.org/wiki/All-pay_auction) · [contests, Networks ch. 9](https://www.cs.cornell.edu/home/kleinber/networks-book/networks-book-ch09.pdf) — every guess pays a fee whether or not it wins.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the time-ordered ids that key every entity across every tier.
- [Helland — Life Beyond Distributed Transactions (CIDR 2007)](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf) — entities behind boundaries, the privacy seam, and idempotent activities.
- [Kreps — The Log (LinkedIn Engineering)](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying-abstraction) — the bus as the log work is dropped onto and drained from.
- [Ecto.Multi](https://hexdocs.pm/ecto/Ecto.Multi.html) — the all-or-nothing balance-and-ledger transaction the wallet runs.
- [Phoenix — Channels](https://hexdocs.pm/phoenix/channels.html) — the live `scored` push and the per-game topics.
- [Erlang/OTP — the supervisor behaviour](https://www.erlang.org/doc/apps/stdlib/supervisor.html) — the dependency-ordered tree and the rest-for-one cache tier.
- [Erlang/OTP — the gen_server behaviour](https://www.erlang.org/doc/apps/stdlib/gen_server.html) — the supervised consumers and gateways.
- [Valkey — Benchmarking (single-threaded execution)](https://valkey.io/topics/benchmark/) · [Diagnosing latency](https://valkey.io/topics/latency/) · [Hash Field Expirations](https://valkey.io/blog/hash-fields-expiration/) · [Release 9.1.0](https://github.com/valkey-io/valkey/releases/tag/9.1.0) — the single-thread sizing, the AOF fsync thread, the per-field TTL, and the 9.1 fixes the bus paths use.
- [Valkey — Persistence (RDB and the append-only file)](https://valkey.io/topics/persistence/) — the durable bus and competitive state, with a one-second loss bound.
- [Fly.io — Fly Machines](https://fly.io/docs/machines/) · [Machine sizing](https://fly.io/docs/machines/guides-examples/machine-sizing/) · [Private Networking](https://fly.io/docs/networking/private-networking/) — the machines the release and the dedicated Valkey deploy as, and the 6PN they talk over.
- [Telegram — Mini Apps (validating WebApp data)](https://core.telegram.org/bots/webapps) — the `initData` signature check and Telegram Stars on the surface.
