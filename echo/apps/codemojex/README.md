# Codemojex — Postgres persistence + Phoenix `codemojex_web`

*The Game, The Code, The Competition*

---

## What is Codemojex?

Codemojex is a competitive puzzle game where players race to decode a secret sequence of 6 emojis.
Think Wordle meets Mastermind — but with emojis, real money prizes, and a ticking clock.

> *"Guess the code of 6 emojis"*

[Rules of Game](./docs/codemojex.game_rules.md)

Codemojex app and a Phoenix web surface, **without displacing BCS, EchoStore, or EchoMQ** — each keeps its job;
Postgres is added underneath as the durable floor for crucial data.

## The layering

```
  EchoMQ (Valkey)        real-time + queues  : per-player guess lanes -> one
                                               ScoreWorker; leaderboard ZSET,
                                               tier-first claims, players set,
                                               attempt counter, locks, close-lock.
                                               All derived/ephemeral -> reconstructable.
        |
  EchoStore (ETS L1)     read-hot cache      : a round's secret and an emoji set are
                                               immutable for the round's life; the
                                               Cache seam reads L1, falls back to ...
        |
  Postgres (Ecto)        SYSTEM OF RECORD    : players (balances), transactions
                                               (ledger), rounds (secret + pool),
                                               guesses, rooms, emoji_sets. ACID,
                                               CHECK-constrained, queryable, durable.
        |
  BCS (branded ids)      identity            : {ns}{base62} ids ARE the primary keys
                                               (USR/TXN/RND/GES/RMM/EMS), minted by
                                               the Snowflake in echo_data.
```

Why Postgres now: balances are money and rounds carry a server-side secret — both
must survive a restart and be auditable. BCS `PropertyStore` is ETS (in-memory) and
Valkey alone is not a money system-of-record. Postgres is the durable answer; the
other three layers are unchanged and still earn their keep.

## What changed

| File | Change |
|---|---|
| `lib/codemojex/repo.ex` | **new** — `Codemojex.Repo` (Postgres). |
| `lib/codemojex/schemas/*.ex` | **new** — Player, Transaction, EmojiSet, Room, Round, Guess. Branded text PKs; field names match the game's plain maps. |
| `priv/repo/migrations/…_create_codemojex.exs` | **new** — six tables, the `players_non_negative` CHECK, indexes. |
| `lib/codemojex/store.ex` | `Store` is now Ecto-backed (maps cross the boundary, status atom↔text); `Bus` is supervisable; `Cache` now caches over Postgres. |
| `lib/codemojex/wallet.ex` | **stateless + transactional** — each op runs in `Repo.transaction` with `SELECT … FOR UPDATE` on the player row + the CHECK as backstop. The single-writer GenServer is gone (only same-player mutations contend now; it scales). |
| `lib/codemojex/ledger.ex` | reads the `transactions` table. |
| `lib/codemojex/view.ex` | `my_history` reads Postgres; added `lobby/0`. |
| `lib/codemojex/game.ex` | `ScoreWorker` broadcasts `:scored` on PubSub (the live path); facade drops `start/1` (Application owns startup) and gains `lobby`. |
| `lib/codemojex/application.ex` | **new** — supervises Repo, PubSub, the EchoMQ bus + two consumers, and the endpoint. |
| `lib/codemojex_web/**` | **new** — endpoint, router, `GameController` + fallback + `ErrorJSON`, `UserSocket` + `RoomChannel`. |

## The web surface (JSON + WebSocket)

JSON API (`/api`, all calls go through the `Codemojex` facade and the privacy-safe
views — the secret and other players' guesses never cross this boundary):

```
GET  /api/health
POST /api/players                 {name, keys?, clips?, diamonds?}
GET  /api/rooms                   -> lobby
POST /api/rooms/:id/join          {player}
GET  /api/rounds/:id              -> round view (no secret)
POST /api/rounds/:id/guess        {player, emojis: [6 XXYY codes]}
GET  /api/rounds/:id/history      {player}  -> own attempts only
GET  /api/rounds/:id/leaderboard
POST /api/keys/buy                {player, keys, ref?}
POST /api/keys/convert            {player, diamonds}
```

WebSocket: socket `/socket`, channel `round:<id>`. Join returns the round view;
when the ScoreWorker finishes an attempt it broadcasts `:scored` on PubSub topic
`round:<id>` and the channel pushes it — the live leaderboard updates with **no
per-room process** (the RoomServer that was argued down). `refresh` re-reads view +
leaderboard on demand.

> Player identity is read from the request for now; production must verify Telegram
> `initData` before trusting `params["player"]`. (TODO.)

## Install into the umbrella

1. Drop `codemojex/` into `apps/` (replacing the existing app).
2. Apply the config blocks shown in `umbrella-config/` to your real
   `config/{config.exs,dev.exs,runtime.exs,test.exs}` — they add `ecto_repos`, the
   endpoint, the JSON library, dev/test Postgres creds, and the prod runtime block,
   alongside the existing `echo_bot` config (which is untouched).
3. Bring it up:

```sh
mix deps.get
mix ecto.create
mix ecto.migrate
iex -S mix            # Repo + PubSub + bus + consumers + endpoint on :4000
mix run priv/round.exs   # a full round end to end (needs Valkey on $VK_PORT)
```

## Honest status

This was written to fit the real EchoMQ / EchoData / Ecto / Phoenix APIs but **has
not been compiled** — there is no Elixir/OTP toolchain in the authoring sandbox, and
no Postgres or Valkey to run against. The proof is:

```sh
mix deps.get && mix ecto.create && mix ecto.migrate && mix compile
```

Expect to chase small things on first compile (a missing import, an arity, a
changeset detail). The arithmetic (scoring, the economy, XXYY mapping) was validated
independently; the database and web wiring need a real `mix` to confirm.
