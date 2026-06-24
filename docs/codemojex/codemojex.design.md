# Codemojex · Architecture
<show-structure depth="2"/>

Codemojex is a real-time, multiplayer code-breaking competition that runs as a Telegram Mini App — Mastermind played with a six-cell emoji keyboard, for money. This document is the architectural design of the `codemojex` application as it stands in the Echo umbrella: its systems, its messaging, its storage tiers, and the way it is built and deployed for production. It is written against the source, not ahead of it — every module, namespace, table, and Valkey key named here exists in `apps/codemojex`.

The design is one instance of the Branded Component System: each part of the game is a system that owns its state, and the only things that cross a boundary are branded identities and messages about them. The four libraries beneath it — `echo_wire` (the wire), `echo_data` (the id and the stores), `echo_mq` (the bus), and `echo_store` (the near-cache and the durable floor) — compose into the umbrella, and Codemojex is the application that sits on top of all four.

## The game in one paragraph

A room is a template; a round is a game played in it. The first player to join a waiting room starts a round: the room's emoji set and props are snapshotted, a secret of six distinct codes is drawn, and a timer begins. Players submit six-emoji guesses; each guess is charged a fee and scored by distance from the secret, with a per-position score of `100 - 20·d` summing to 600 for a perfect crack. Scores feed a per-round leaderboard with a first-mover bonus for being first to reach a tier. A perfect crack, or the timer expiring, closes the round and pays its diamond prize pool winner-take-all to the top scorer. Three currencies move through the game — keys, clips, and diamonds — each in its own lane, all mutated atomically in Postgres.

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
   players · txns ·          leaderboard ZSET ·             rounds · emoji sets
   rooms · rounds ·          first-mover hashes ·           (immutable, coherence :none)
   emoji_sets · guesses      counters · close lock          → optional Graft floor → Tigris
```

A read of immutable round data hits an in-process ETS cache; a guess is a job on a per-player lane; money is a relational transaction; the leaderboard is a Valkey sorted set. Nothing in the picture is merged — the boundaries are real, and the same code runs whether the systems share a node or not.

## Identity: the branded component law

Every entity in Codemojex is a 14-character branded snowflake: a three-character uppercase namespace followed by eleven Base62 characters encoding a 63-bit snowflake (`ts(41) | node(10) | seq(12)`, epoch `1704067200000`). The id is typed, time-ordered, and placeable, and it is the only key that crosses a boundary — it keys the row in Postgres, the entry in Valkey, the job on the bus, and the message that announces a result.

Nine namespaces carry the game:

| Namespace | Entity | Lives in |
|-----------|--------|----------|
| `USR` | player | Postgres `players`, Valkey lanes/board |
| `RMM` | room (template) | Postgres `rooms` |
| `RND` | round (a game) | Postgres `rounds`, EchoStore `:cm_rounds` |
| `GES` | guess | Postgres `guesses` |
| `EMS` | emoji set | Postgres `emoji_sets`, EchoStore `:cm_emojisets` |
| `TXN` | wallet transaction | Postgres `transactions` |
| `JOB` | a unit of work on the bus | Valkey (the queues) |
| `NOT` | an outbound notification | Valkey (the notify lane) |
| `CMD` | an inbound bot command | Valkey (the commands lane) |

Because the id carries its mint time, it doubles as a version: a round's secret and an emoji set are immutable for the round's life, so the entity's own id is a sound cache version and a sound idempotency token.

## The systems

The domain is a set of small modules, each owning one concern and speaking maps across its boundary. The `Codemojex` module is a thin facade that delegates into them; nothing else reaches across.

**Play — `Codemojex.Guesses` and `Codemojex.Locks`.** The play API validates a six-emoji guess against the round's keyboard, overlays the player's locked positions, charges the right currency through the wallet, and enqueues the guess as a `JOB` on the player's own lane. The host never scores; it accepts and enqueues. Locks let a player pin a code at a position so it persists across their guesses.

**The scoring authority — `Codemojex.ScoreWorker` and `Codemojex.Scoring`.** Scoring is a pure function: a guessed emoji that exists in the secret earns `100 - 20·d` for its distance `d`, zero for a miss, summing out of 600, with the tier being the total in 20-point steps. The worker is the single authority that runs it — it reads the secret through the cache, scores, writes a `GES` guess, records the result on the leaderboard, and publishes the outcome. The purity is load-bearing: a re-delivered guess re-scores to the same number.

**Rooms and the keyboard — `Codemojex.Rooms` and `Codemojex.EmojiSet`.** A room holds the props a round inherits — emoji set, duration, seed prize pool, guess fee, and whether it is free. An emoji set is a sprite sheet plus the subset of cells a room exposes; a code is `XXYY` (column then row), and a round's secret is six distinct codes drawn from the set. The player-facing snapshot of a set carries the keyboard and nothing the secret could leak from.

**Money — `Codemojex.Wallet`, `Codemojex.Economy`, `Codemojex.Ledger`.** Balances live in Postgres and move only inside database transactions; the pure math (conversion rates, the winner-take-all split, USD formatting) lives in `Economy`, and the append-only statement is read through `Ledger`. The wallet is the one system where correctness outranks speed.

**Competitive state — `Codemojex.Board`.** The leaderboard is a Valkey sorted set per round, scored by a player's best base total plus their first-mover bonuses; first-mover is an atomic, server-side claim. A separate in-memory CHAMP projection (`Codemojex.Leaderboard`) is available as a rebuildable view.

**Reads — `Codemojex.View`.** The player-facing reads carry the privacy invariant in their shape: no view returns the secret, and no view returns another player's guesses.

**Gateways — `Codemojex.Notifier`, `Codemojex.EchoBot`, `Codemojex.RateLimiter`, `Codemojex.Telegram`.** Outbound messages and inbound bot updates both ride the bus as jobs on per-chat lanes; the rate limiter is a token bucket that turns "too soon" into a delayed re-enqueue rather than a blocked process; `Telegram` is the dependency-light HTTP transport for the send side.

## Messaging: the EchoMQ bus

The bus is the spine of the runtime. `Codemojex.Bus` holds one RESP3 connector to Valkey in `:persistent_term`; everything that touches the queue goes through it, so there is a single supervised path to the store. Work is dropped onto the bus with `EchoMQ.Lanes.enqueue/5` and drained by `EchoMQ.Consumer`, and the enqueue is idempotent — a re-enqueued `JOB` answers `:duplicate`, not a second unit of work.

Four lanes carry four kinds of work, each grouped so one heavy producer cannot starve the rest:

- **Guesses** — queue `cm`, lane keyed by the player's `USR`. The bus rotates service across players, so one fast tapper does not freeze the field.
- **Settlement** — queue `cm-settle`, lane keyed by the round's `RND`. Closing a round is its own job, never an ungrouped enqueue, so a draining consumer always finds it.
- **Notifications** — the notify lane, keyed by chat, drained by the rate-limited `NotificationWorker`.
- **Bot commands** — `bot.commands`, keyed by chat, drained by the `CommandWorker` that the bot gateway feeds.

Two patterns recur. The first is the move-then-settle split borrowed from exchange design: the guess queue competes, and a separate settle queue pays, so contention and payout never share a path. The second is the delayed re-enqueue: when the rate limiter reports a guess arrived too soon, or a notification hits a transient failure, the worker re-enqueues the same job with `EchoMQ.Jobs.enqueue_in/5` after a computed delay, with capped exponential backoff — the worker defers rather than blocks.

When the scoring worker finishes, it announces the result twice for two audiences. It publishes a `scored` event on the bus with `EchoMQ.Events` for any bus consumer, and it broadcasts a `:scored` message over Phoenix PubSub on the round's topic for the live surface. Both carry the player's name, percentage, tier, effective score, and whether the guess claimed a tier — and neither carries the secret or the guess content.

## Storage tiers

Codemojex keeps three tiers and places each kind of data on the one that fits it. The id runs through all of them, so a piece of state is one name asked at different depths, not three schemes translated between three stores.

**Postgres — the system of record.** The durable, queryable truth: `players` and their `transactions`, `rooms`, `rounds` (secret included, server-side), `emoji_sets`, and `guesses`. Money and history are relational because they need locks, constraints, and ordered queries.

**Valkey — the bus and the live competitive state.** Three roles on one engine: the EchoMQ queues; the leaderboard and its machinery (a sorted set per round, the first-mover hashes, the player set, the attempts and total-won counters, and the round-close lock); and the L2 layer shared by the near-cache. This is the hot, volatile half — fast, and rebuildable from the system of record.

**EchoStore — the near-cache, declared in `Codemojex.Tables`.** Two L1-over-L2 caches sit in front of Postgres on the scoring hot path: `:cm_rounds` (`RND`, the round and its secret) and `:cm_emojisets` (`EMS`, the keyboard). A read is a caller-side `:ets` lookup; a miss coalesces onto one in-flight fill that checks L2 and falls through to a loader that reads Postgres, writing both layers under a TTL. Because both entities are immutable for the round's life, coherence is `:none` and the cache never goes stale. The directory the tables register into is supervised first under `:rest_for_one`, so if it ever restarts the tables restart with it and re-register.

**The durable floor — optional, via `EchoStore.Graft`.** When a `:graft_volume` is configured, `Codemojex.Application` starts the Graft committer: a single-writer page store on an append-only B-tree that folds to Tigris object storage behind a create-only conditional-write fence. It is the replicated substrate beneath the volatile half, and the app boots cleanly without it.

## The data model

The relational schema is six tables, each keyed by a branded id and carrying its own status word as text:

- **`players`** — `USR` key; `keys`, `clips`, `diamonds`, `bonus_diamonds`, `locked_diamonds` as non-negative big integers, guarded by a CHECK constraint that the wallet leans on as a backstop.
- **`transactions`** — `TXN` key; `player`, `currency`, `delta`, `reason`, `ref`; append-only, indexed by `(player, inserted_at)` for a statement.
- **`emoji_sets`** — `EMS` key; the sprite grid (`cols`, `rows`, `cell_size`, `sprite_url`) and the exposed `codes`.
- **`rooms`** — `RMM` key; the template props and at most one active `round`.
- **`rounds`** — `RND` key; the `secret` (server-side, selected by no player-facing query), the timer, the prize pool, and the fee props; indexed by `room`.
- **`guesses`** — `GES` key; the player's `emojis`, `points`, `percentage`, and `tier`; indexed by `(round, player)`.

Alongside it, the Valkey keyspace for one round is a small family under `cm:<round>:` — `board` (the sorted set), `base` / `ptier` / `bonus` / `tierfirst` (the first-mover hashes), `players` (a set), `attempts` (a counter), and `closed` (the one-shot close lock) — plus the global `cm:total_won`.

## Core flows

**A guess, end to end.** The surface accepts `POST /rounds/:id/guess` and returns immediately. `Codemojex.Guesses` reads the round from the system of record, checks it is open and unexpired, validates the six emojis against the keyboard, overlays the player's locks, and charges the fee through the wallet; only a charged guess is enqueued on the player's lane. The `ScoreWorker` claims it, reads the secret through the cache, scores it, writes a `GES` guess, increments the round's attempt counter, records the result on the board, and announces it on the bus and over PubSub. A perfect 600 closes the round there and then.

**Settlement, exactly once.** A round closes from one of two triggers — a perfect crack, or an expired timer — and the two can race. The close path takes a one-shot lock with an atomic `SET … NX` on `cm:<round>:closed`; only the closer that wins it pays, and the loser is a no-op. The winner reads the top of the board, computes the winner-take-all split over the diamond pool (shared evenly on a tie), deposits each prize through the wallet, bumps the global total-won counter, marks the round closed, and returns the room to waiting.

**The economy.** Three currencies, each in its own path: keys pay for guesses in paid rooms and are bought with Telegram Stars; clips pay for guesses in free rooms and carry no value; diamonds are the prize currency, won from rooms and convertible to keys at a fixed 10:1. Every balance change is a database transaction that locks the player row with `SELECT … FOR UPDATE`, checks the non-negative invariant, writes the new balance, and inserts the paired `TXN` ledger row — all or nothing. The row lock serializes only same-player mutations, so the field is never funnelled through one process; the database does the work a single-writer process would have, and scales with it.

**The leaderboard and first-mover.** A scored guess updates the player's best base total, then claims every still-unclaimed tier at or below the new tier with an atomic `HSETNX` race — the first id to reach a tier wins it server-side, with no read-modify-write — and the claimed bonuses are added to the effective score written to the sorted set. The board is ranked by effective score, so being first to a height is worth a little, permanently.

## The web surface

The surface is a thin Phoenix application, deliberately small. A JSON API under `/api` covers the lifecycle: a health check, player creation, the room lobby, joining a room, a round view, submitting a guess, a player's own history, the leaderboard, and the two key operations (buy and convert). Every action calls the `Codemojex` facade and the privacy-safe views; a guess returns an accepted-and-on-its-way response while the bus carries the scoring, and there is no process per room, so a large field of idle rooms costs nothing.

The live half is Phoenix Channels. A client joins `round:<id>`, which subscribes the channel to the matching PubSub topic; when the scoring worker finishes an attempt the channel pushes the `scored` event to the client, and the leaderboard updates without any per-room process. Joins return the round view, never the secret, and a refresh re-reads the view and the board on demand.

Player identity is read from the request today and is the one explicit gap before launch: in production it must come from verified Telegram `initData`, whose signature the server checks with an HMAC-SHA-256 over the bot token keyed by the constant `WebAppData`. Until that check is wired, the surface trusts a supplied id.

## Privacy and fairness

The privacy boundary is structural, not a filter at the edge. The secret exists in exactly one place a player can never read — the round row in Postgres and its immutable cache copy — and no player-facing view selects it; the keyboard snapshot, the round view, and the leaderboard are each shaped to carry only what is public. A player sees their own attempt history and no one else's. The live events that fan out carry a name and a score, never the code or the guess.

Fairness has two meanings here, and the design serves both. Procedural fairness is the per-player lane on the guess queue: service rotates across players, so paying for speed buys a turn, not the field. Economic fairness is the candid economy — every guess pays a fee, the prize pool is platform-seeded and stated, and the conversion rate is fixed and public, rather than hidden house entries playing against the field. The exact fee and pool terms are the kind of decision that belongs with the chief architect and legal review before launch.

## Fault tolerance and correctness

The runtime is a single supervision tree, and the order is the dependency order:

```
Codemojex.Supervisor (one_for_one)
├─ Codemojex.Repo                     # the system of record
├─ Phoenix.PubSub (Codemojex.PubSub)  # the live fan-out
├─ Codemojex.Bus                      # the shared RESP3 connector to Valkey
├─ Codemojex.Tables (rest_for_one)    # the EchoStore near-cache tier
│  ├─ EchoStore.Directory             #   started first; a restart cascades
│  ├─ EchoStore.Table :cm_rounds
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

Delivery is at-least-once, and every handler is idempotent so re-delivery is harmless. Scoring is pure, so a re-scored guess is identical; settlement is guarded by the one-shot `SET NX` lock; the first-mover claim is `HSETNX`; the wallet is a database transaction backed by a CHECK constraint. Each consumer leases the job it is working, so a crashed consumer's in-flight job becomes visible again rather than lost, and its supervisor restarts it in place. The near-cache tier uses `:rest_for_one` so a directory restart re-registers the tables, and cache writes are best-effort — a Valkey blip or a table restart can never fail the writer recording a round or a set.

## Production deployment

The release is a `mix release codemojex` built from the umbrella root in a pinned image (Elixir 1.18.4 / OTP 28.5.0.1). The multi-stage Dockerfile compiles `codemojex` over its in-umbrella dependencies — `echo_mq`, `echo_data`, `echo_wire`, and `echo_store` — builds `echo_data`'s native branded-id codec, and assembles a self-contained release onto a slim runtime stage. `echo_store` is a first-class dependency now, so the image builds its SQLite C-NIF (exqlite) and CubDB; `echo_bot` and `echo_graft` stay out, each its own concern.

The bus's Valkey runs as its own machine, not in the web container. In production that is a dedicated Fly machine with an append-only log set to flush every second — a roughly one-second loss bound that EchoMQ's checkpoints are designed against — eviction turned off so memory pressure surfaces as an alert rather than silent data loss, and the kernel tuned away from its defaults for an in-memory store. The app reaches it over the private network; the connector dials a fixed host and a configurable port. Production deployment, the Valkey machine, and the kernel tuning are covered in depth in the BCS course chapter on production, served at `/bcs/fly`, and in the dedicated `echo-valkey` datastore configuration.

The same image runs locally under docker compose: Postgres, the Valkey the bus expects on its connector port, and the endpoint, wired the way Fly wires them. A health check at `/api/health` lets a machine that stops answering be taken out of rotation, and the endpoint stays up across a rolling deploy so a live channel is not dropped under a player.

## Configuration

The app reads a small set of knobs, all with sensible defaults:

- `:valkey_port` — the port the bus connector and the cache tables dial (the connector host is fixed). The whole runtime shares one port.
- `:graft_volume` — when set to a volume id, the durable Graft committer starts; absent, the replicated floor is not in the tree.
- `:rounds_cache_ttl_ms` / `:sets_cache_ttl_ms` — the TTLs for the two near-caches; both entities are immutable, so the TTLs are generous.

A note on building and running: this app is parse-verified in the sandbox, and the faithful compile and release are produced in the pinned 1.18.4 / OTP 28 image, where the native codec and the SQLite C-NIF are built. The sandbox toolchain is older, so `mix compile` and `mix release` belong to the image, not the bench.

## References

- [Mastermind (the board game)](https://en.wikipedia.org/wiki/Mastermind_(board_game)) — the guess-against-a-hidden-code loop Codemojex plays with emoji.
- [All-pay auction](https://en.wikipedia.org/wiki/All-pay_auction) — every guess pays a fee whether or not it wins.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the time-ordered ids that key every entity across every tier.
- [Helland — Life Beyond Distributed Transactions (CIDR 2007)](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf) — entities behind boundaries, the privacy seam, and idempotent activities.
- [Kreps — The Log (LinkedIn Engineering)](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying-abstraction) — the bus as the log work is dropped onto and drained from.
- [Ecto.Multi](https://hexdocs.pm/ecto/Ecto.Multi.html) — the all-or-nothing balance-and-ledger transaction the wallet runs.
- [Phoenix — Channels](https://hexdocs.pm/phoenix/channels.html) — the live `scored` push and the per-round topics.
- [Erlang/OTP — the supervisor behaviour](https://www.erlang.org/doc/apps/stdlib/supervisor.html) — the dependency-ordered tree and the rest-for-one cache tier.
- [Erlang/OTP — the gen_server behaviour](https://www.erlang.org/doc/apps/stdlib/gen_server.html) — the supervised consumers and gateways.
- [Valkey — Persistence (RDB and the append-only file)](https://valkey.io/topics/persistence/) — the durable bus and competitive state, with a one-second loss bound.
- [Fly.io — Fly Machines](https://fly.io/docs/machines/) — the machines the release and the dedicated Valkey deploy as.
- [Telegram — Mini Apps (validating WebApp data)](https://core.telegram.org/bots/webapps) — the `initData` signature check and Telegram Stars on the surface.
