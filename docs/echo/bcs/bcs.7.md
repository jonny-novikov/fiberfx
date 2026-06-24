# BCS · B7 — Codemojex

B7 is the worked project: **Codemojex**, a multiplayer code-guessing game on Telegram — Mastermind played with emoji — built on the substrate the course has assembled. It is the reference implementation the rest of the series points at, where the branded id, the property stores, the bus and its lanes, the wallet, and the live surface meet in one running game. The chapter is served at `/bcs/codemojex`, and it is the one three-level chapter besides the Elixir core — six modules, each with three dives.

The substrate beneath Codemojex is shipped source — `echo_data` (the id and the stores), `echo_mq` (the bus and the connector), `echo_wire` (the wire) — and the game is the forward-looking layer built on top of it. Every namespace, lane, and currency named here is the game's own, and nothing is asserted that the committed substrate does not support.

## The six modules

Codemojex is built in six moves: the game as branded systems (B7.1); rooms, modes, and the committed secret (B7.2); a guess charged and dropped onto a fair lane (B7.3); scoring, tiers, and settlement (B7.4); the three-currency economy and the bank (B7.5); and the live Phoenix surface that players touch (B7.6). Each rests on the one before — there is no scoring without a guess, no settlement without an economy, no surface without all of it underneath.

## B7.1 · Branded systems

Codemojex is built the way Parts I and II said to build: as branded systems, where every entity is a 14-character branded id and that id is the only key that crosses a boundary. A player is a `USR`, a room is its own namespace, an event is an `EVT`; the id keys the row in Postgres, the entry in Valkey, the job on the bus, and the message that announces a result — one name read at every tier, rather than four schemes translated between four stores.

The game is four layers, and the layering is the architecture. The Telegram client is the surface a player sees; the Phoenix app is the boundary that accepts intents and serves views; the EchoMQ bus and its workers carry the work that must not be lost; and the stores — Valkey for the hot, volatile state, Postgres for the system of record — hold what the game knows. Nothing reaches across a layer except by id and message.

A privacy boundary runs through the layers. What is public — a player's handle, their place on the board, a finished result — is one set of fields; what is private — the wallet balance, the in-flight guess, the identity behind the handle — is another, and the views the surface returns are shaped so the private set never crosses to a player who should not see it. The boundary is a property of the read path, not a filter bolted on at the edge.

## B7.2 · Rooms and modes

A room is a single game in progress, described by two things: a template and a mode. The template is the rule set — how long the code is, how many guesses are allowed, how scoring works; the mode is how the room runs — continuous and live, or sealed and settled in a batch. The same code serves every room because the room's behavior is data it carries, not a branch in the engine.

The puzzle is an emoji set. The secret the players are guessing is a sequence drawn from a fixed alphabet of emoji, and a guess is a sequence of the same shape — Mastermind, with pictures in place of colored pegs. The fixed alphabet is what makes a guess scorable by position and the board between two players comparable.

The secret is held behind a commitment. Before a room opens, the server publishes a hash of the secret, not the secret itself; at settlement it reveals the secret and the salt, and any player can check that the revealed secret matches the hash posted at the start. The commitment is what lets the game prove it did not change the answer once guesses were in — the trust is in the math, not in the operator's word.

## B7.3 · Guesses on fair lanes

A guess goes through three states before it scores. First it is locked: the player commits the sequence, and the lock is what makes the guess final and chargeable. Then it is charged — Codemojex is an all-pay game, so a guess costs whether or not it wins, the way an all-pay auction charges every bidder — and only a charged guess is enqueued. The order is deliberate: the charge and the enqueue are bound, so a crash cannot drop a paid guess or enqueue an unpaid one.

Guesses ride fair lanes. Each room is its own lane on the bus, claimed under the ring invariant from B3, so a busy room draws from its own lane in rotation and cannot starve the rooms beside it — a popular game does not freeze the rest of the board. The lane is the same fairness mechanism the bus already provides, used here to keep one room's traffic from monopolizing the workers.

A worker drains the lane and scores the guess. It is a supervised consumer, leasing each guess as it works so a crash makes the in-flight guess visible again rather than lost; it reads the room's secret, scores the guess by distance, and writes the result back as a property keyed by the guess's id. The play loop is a write onto a lane and a worker draining it, nothing more elaborate.

## B7.4 · Scoring, tiers, and settlement

Scoring is a distance. A guess is compared to the secret position by position, and each position contributes points by how close it lands — an exact match scores the most, a near match less, a miss nothing — summing to a bounded total per guess. The scoring is pure: the same guess against the same secret always scores the same, so a result can be recomputed and checked rather than trusted.

A player's running total places them in a tier. The totals are banded into thirty tiers, each a fixed range, and a player's best total decides their band; the leaderboard is a Valkey sorted set keyed by that best total, so a player's rank is a single read and the board is always in order. Tiers turn a continuous score into a ladder players can climb.

Settlement closes a room, and a room settles one of two ways. A live room settles continuously — each result lands as it is scored — while a sealed room settles in a batch, ranking the field and paying the top places at the end. Either way settlement is idempotent: it claims the room once, and a replay of the same settlement finds the claim taken and does nothing, so a crash mid-settlement never pays twice.

## B7.5 · The economy and the bank

Codemojex runs on three currencies. Keys are the paid currency, bought with Telegram Stars; Clips are earned free through play; Diamonds are prizes, and they convert to keys at a fixed rate. Three currencies keep the paid economy, the free economy, and the prize economy distinct, so a change to one does not silently move the others.

A wallet is a system, keyed by the player's id, with a ledger of transactions beside it. Every move of value is an entry in a `TXN` ledger, and a spend, a charge, or a payout is an atomic `Ecto.Multi` — the balance change and the ledger entry land together or not at all, so the balance is always the sum of the ledger and never drifts from it. The wallet is the one place in the game where correctness matters more than speed.

The bank holds the money the game itself moves. A `BNK` escrow holds stakes while a room is in play; the all-pay pool collects every charged guess and pays it out at settlement; and the house takes a published, transparent rake — a stated cut of the pool, shown to players, rather than hidden house entries playing against them. The rake is candid by design, and its exact terms are the kind of decision that belongs with the chief architect and legal before launch.

## B7.6 · The live surface on Phoenix

Players touch a JSON API. The surface accepts an intent — open a room, lock a guess — and answers immediately, often with a 202 that says the work is accepted and on its way, while the bus carries the actual scoring; the views it returns are the privacy-safe shape from B7.1, and there is no process per room, so a million idle rooms cost nothing. The surface is thin by design: it accepts and it reads, and the work happens behind it.

Results reach players over Phoenix Channels. When a worker scores a guess it broadcasts a `scored` event on the room's PubSub topic, and every client subscribed to that room sees the result arrive — a live push, rather than a client polling into blind silence. The channel is the difference between a game that feels alive and one that feels like a form.

The whole thing deploys as one supervised application on Fly. There is no ephemeral tier and no separate worker fleet — the endpoint, the bus, and the workers are children of one supervision tree, deployed as Fly Machines — because the load is steady and the work is bounded. How that deployment is built, sized, and run is B8, the chapter that follows.

## References

- [Mastermind (the board game)](https://en.wikipedia.org/wiki/Mastermind_(board_game)) — the guess-against-a-hidden-code loop Codemojex plays with emoji.
- [All-pay auction](https://en.wikipedia.org/wiki/All-pay_auction) — every guess pays whether or not it wins, the pool's economic shape.
- [Commitment scheme](https://en.wikipedia.org/wiki/Commitment_scheme) — the hash posted at the start that proves the secret was not changed.
- [Easley & Kleinberg — Networks, Crowds, and Markets, ch. 9](https://www.cs.cornell.edu/home/kleinber/networks-book/networks-book-ch09.pdf) — the auction theory behind the all-pay pool and settlement.
- [King — Announcing Snowflake (2010)](https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake) — the branded id that keys every player, room, and guess across every tier.
- [Helland — Life Beyond Distributed Transactions (CIDR 2007)](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf) — entities behind boundaries, the privacy seam, and the idempotent settlement.
- [Ecto.Multi](https://hexdocs.pm/ecto/Ecto.Multi.html) — the all-or-nothing transaction the wallet's balance and ledger ride.
- [Kreps — The Log (LinkedIn Engineering)](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying-abstraction) — the bus the charged guesses are dropped onto and drained from.
- [Phoenix — Channels](https://hexdocs.pm/phoenix/channels.html) — the live `scored` push that makes the board feel alive.
- [Fly.io — Fly Machines](https://fly.io/docs/machines/) — the one supervised app the game deploys as, taken up in B8.
