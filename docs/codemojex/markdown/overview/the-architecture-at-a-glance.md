# C0.3 · The architecture at a glance

> Route `/codemojex/overview/the-architecture-at-a-glance` · chapter C0 Overview · dive 3 of 3.
> Grounding: `echo/apps/codemojex/lib/codemojex/game.ex` (the `Codemojex` facade, `Codemojex.Guesses`,
> `Codemojex.ScoreWorker`, `Codemojex.Settle`) · `store.ex` (`Codemojex.Store` / `Codemojex.Bus` /
> `Codemojex.Cache`) · `board.ex` · `view.ex` · `application.ex` · design §The architecture at a glance ·
> `stories/rooms-and-games.stories.md` · `stories/privacy.stories.md`.

Codemojex is four layers, and the layering is the architecture. Requests enter at a thin Phoenix
surface behind privacy-safe views; the `Codemojex` facade delegates into the domain systems; durable
work travels on the EchoMQ bus over Valkey, on lanes named by branded ids; and state rests on a
three-tier storage floor — Postgres the system of record, Valkey the derived real-time state,
EchoStore the immutable near-cache. Money and the secret live on the floor; the surface never selects
them. One glance holds the whole game.

## One sentence holds the game

The facade module's own documentation is the architecture in one sentence (`game.ex`, the
`Codemojex` moduledoc, quoted verbatim):

> Codemojex on the bus: a six-emoji code-breaking competition whose entities are branded components
> persisted in Postgres, whose guesses are jobs on per-player lanes scored by a single authority,
> whose three currencies mutate atomically in the database through a wallet with a transaction
> ledger, whose rooms template their games, and whose diamond prize pools settle through a second
> queue (winner-take-all for a classic game, a sealed top-K split for a golden game).

Each clause names a layer. "Branded components persisted in Postgres" is the floor. "Jobs on
per-player lanes scored by a single authority" is the bus and its consumers. "A wallet with a
transaction ledger" is a domain system behind the facade. And the sentence closes where startup
begins: "Startup is `Codemojex.Application`'s job — the Repo, PubSub, the EchoMQ bus and consumers,
and the Phoenix endpoint come up there."

## Layer by layer

**Layer 1 — the surface.** `codemojex_web/*`: the JSON API, the room channel, and the LiveView
lobby. Every read goes through `Codemojex.View`, whose moduledoc carries the invariant in its first
line: "nothing here returns the secret, and nothing returns another player's guesses." The facade's
own comment marks the view delegates the same way: "views (privacy-preserving: no secret, no others'
guesses)." The surface holds no game state and never scores.

**Layer 2 — the facade and the systems.** The `Codemojex` module is a thin facade that delegates
into small domain systems, each owning one concern: `Codemojex.Guesses` (the play API),
`Codemojex.Rooms` (templates and lifecycle), `Codemojex.Wallet` (currency, atomically in Postgres),
`Codemojex.Scoring` (the pure linear engine), `Codemojex.Board` (the competitive state),
`Codemojex.Settle` (the payout job). `Codemojex.Guesses.submit/3` validates a six-emoji guess
against the game's keyboard, overlays the player's locks (`Codemojex.Locks.merge/3`), charges the
room's currency through the wallet — and then hands off. The host never scores; the consumer does.

**Layer 3 — the bus.** `submit/3` mints a branded `JOB` (`EchoData.BrandedId.generate!("JOB")`) and
enqueues it — `Lanes.enqueue(Bus.conn(), @queue, player, job, payload)`, queue `"cm"`. The lane is
named by the player's `PLR`, "so the bus rotates service across players and one keyboard masher
cannot starve the field." `Codemojex.ScoreWorker` is the single scoring authority: `EchoMQ.Consumer`
drains the queue through `Lanes.claim`, the player id arriving as the lane group. Settlement is a
second queue, `"cm-settle"`, whose lane is the game's `GAM` — "the move-then-settle split is the
Exchange pattern: the guess queue competes, the settle queue pays" (`Codemojex.Settle`). Two more
lanes complete the picture: notifications on `"cm.notify"` and inbound bot commands, each keyed by
chat and drained by its own consumer.

**Layer 4 — the floor.** Three tiers, each holding the data that fits it. Postgres is the system of
record — `Codemojex.Store.game/1` reads it, and players, transactions, rooms, games (secret
included, server-side), emoji sets, and guesses rest there. Valkey holds the derived real-time
state — the per-game leaderboard sorted set `Codemojex.Board` writes (`Board.record/3` returns "the
player's best linear total (the board rank)"), the attempt counters, and the bus itself. EchoStore is
the immutable near-cache — `Codemojex.Cache.fetch_game/1` over the tables `Codemojex.Tables`
declares (`:cm_games`, `:cm_emojisets`), an L1 `:ets` hit in the caller's process with Valkey as L2;
a game's secret is immutable for the game's life, so coherence is `:none` and the cache never goes
stale.

**The tree stands the floor up first.** `Codemojex.Application` starts the layers in dependency
order: "the relational system of record (`Repo`) and `PubSub` first; then the EchoMQ bus (`Bus`, the
shared Valkey connector); then the EchoStore near-cache tier (`Tables` …); then the consumers — the
scoring authority, the settlement worker, the notification worker, and the bot-command worker …;
then the Phoenix endpoint."

## A guess's journey

One entity crossing all four layers, top to floor and back:

1. **Submit** — `Codemojex.Guesses.submit(game, player, emojis)` reads the game's mutable state from
   the system of record (`Store.game/1`), validates the six emoji against the game's keyboard,
   overlays locks, and charges the wallet. "The game's mutable state is read from the system of
   record; the cache is trusted only for the immutable secret on the scoring path."
2. **Enqueue** — a fresh `JOB` id, then `Lanes.enqueue(Bus.conn(), @queue, player, job, payload)` on
   queue `"cm"`; the lane is the player's `PLR`.
3. **Claim** — `EchoMQ.Consumer` drains through `Lanes.claim`; `Codemojex.ScoreWorker.handle/1`
   receives the job, the player id as the lane group.
4. **Score** — the worker reads the secret through the cache (`Cache.fetch_game/1`), scores with the
   pure linear engine (`Scoring.score/2`), writes a `GES` guess to Postgres, and counts the attempt
   (`Cmd.incr("cm:" <> game <> ":attempts")`).
5. **Record** — `Board.record(game, player, total)` folds the best linear total onto the game's
   Valkey sorted set; the raw linear best is the sole rank.
6. **Announce** — for a classic game the worker publishes a `scored` event on the bus
   (`EchoMQ.Events`) and broadcasts `:scored` over `Phoenix.PubSub` on the topic
   `"game:" <> game` — the player's name, percentage, and effective score; no secret, no guess
   content. A golden game suppresses this per-guess feedback entirely — "the score is sealed until
   reveal" (the blind contract).

The acceptance catalog closes the loop: "a guess submitted on the lane is scored and reaches the
leaderboard" (`rooms-and-games.stories.md`).

## Money and the secret live on the floor

The floor is where the two sensitive things rest, and the layers above are shaped so neither
travels. The secret is a Postgres column read through the near-cache on the scoring path only; no
view returns it ("the game view never carries the secret" — `privacy.stories.md`). Money is
relational: the three currencies "mutate atomically in the database through a wallet with a
transaction ledger," and the diamond prize pools settle through the second queue, not through the
surface. What crosses the layers is identities and messages about them — a `GAM`, a `PLR`, a `JOB`,
a `GES`, and a `scored` event carrying a name and a percentage. That is the BCS law applied: the
boundaries are real, and the same code runs whether the systems share a node or not.

## References

### Sources

- Kreps — *The Log* — https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying-abstraction — the bus as the ordered log work is dropped onto and drained from.
- Helland — *Life Beyond Distributed Transactions* — https://ics.uci.edu/~cs223/papers/cidr07p15.pdf — entities behind boundaries and the privacy seam the views keep.
- Erlang/OTP — *supervisor* — https://www.erlang.org/doc/apps/stdlib/supervisor.html — the dependency-ordered tree that stands the four layers up.

### Related

- `/codemojex/overview/the-engine-and-its-policies` — C0.2, the previous dive: one engine, modes as policy.
- `/codemojex/branded-systems` — C1, the identity law that threads the four layers.
- `/echomq` — the bus: the queue, lane, and event protocol layer 3 runs on.
- `/bcs` — the architecture law: systems own state; identities and messages cross boundaries.
