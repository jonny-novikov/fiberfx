# C1.2 — The four layers

> Route `/codemojex/branded-systems/the-four-layers` · dive of C1 · stamp `CMX0OSU7SXsSOZ`
> Grounding re-found in `echo/apps/codemojex` + design §Storage / §Architecture / §Fault tolerance
> on 2026-07-02.

Codemojex is four layers, and the layering is the architecture. A request enters at a thin Phoenix
surface; durable work travels on the EchoMQ bus to a small set of authorities; and state rests in
three storage tiers chosen by what each kind of data needs. Each layer owns its tier, and the
branded id is the one value that threads all of them. The load-bearing point: money, the secret,
and the commitment rest on the durable Postgres floor, while everything in Valkey — the board, the
counters, the near-cache — is derived and reconstructable from the floor.

## Four layers, four owners

- **The Phoenix surface (`CodemojexWeb`).** A JSON API under `/api` and Phoenix Channels. Every
  action calls the `Codemojex` facade and the privacy-safe views; a guess returns an
  accepted-and-on-its-way response while the bus carries the scoring; there is no process per room.
- **The facade and the domain systems.** The `Codemojex` module is a thin facade that delegates into
  small systems — `Rooms`, `Guesses`, `Scoring`, `Wallet`, `Board`, and the rest — each owning one
  concern and speaking maps across its boundary. Nothing else reaches across.
- **The EchoMQ bus on Valkey.** Four fair lanes carry four kinds of work — guesses, settlement,
  notifications, bot commands — each grouped so one heavy producer cannot starve the rest. Work is a
  `JOB` dropped on a lane and drained by a consumer.
- **The storage tiers.** Three of them, each holding the data that fits it (below).

The supervision tree is the dependency order (design §Fault tolerance):

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

The as-built `Codemojex.Tables` also starts a third table, `:cm_sessions` (cm.4) — the design's
diagram predates it; the code is the authority for the table roster (§The near-cache tier).

## Durable and derived

The three tiers (design §Storage tiers):

- **Postgres — the system of record.** `players` and their `transactions`, `rooms`, `games` (secret
  included, server-side), `emoji_sets`, and `guesses`. "Money and history are relational because
  they need locks, constraints, and ordered queries."
- **Valkey — the bus and the live competitive state.** The EchoMQ queues; the leaderboard (a sorted
  set per game), the player set, the attempts and total-won counters, and the game-close lock; and
  the L2 layer shared by the near-cache. "This is the hot, volatile half — fast, and rebuildable
  from the system of record."
- **EchoStore — the near-cache.** L1-over-L2 caches on the scoring hot path (below).

So the split is exact. On the floor and irreplaceable: the `players` balances, the append-only
`transactions` ledger, the `games` secret and nonce, and the golden commitment. In Valkey and
rebuildable: the leaderboard sorted set, the counters, the close lock, and the L1/L2 cache. The
volatile half can be lost and rebuilt; the floor cannot.

## The near-cache tier

`Codemojex.Tables` declares three L1-over-L2 caches, each keyed by a branded id:

- `:cm_games` (kind `"GAM"`) — a game and its secret, `coherence: :none`.
- `:cm_emojisets` (kind `"EMS"`) — an emoji set's layout, `coherence: :none`.
- `:cm_sessions` (kind `"SES"`, cm.4) — a verified session, the first mutable table,
  `coherence: :tracking`, so a revoked session is evicted from every holder's L1 immediately.

A read is a caller-side `:ets` lookup; a miss coalesces onto one in-flight fill that checks L2 (the
shared Valkey) and falls through to a loader that reads Postgres, writing both layers under a TTL.
The loader returns `{:ok, term_to_binary(map), id}` — the entity's own 14-byte id as the L2 version.
The two game caches are immutable for a game's life, so their coherence is `:none` and the cache
never goes stale. The `EchoStore.Directory` the tables register into is supervised first under
`:rest_for_one`, so a directory restart cascades to the tables and they re-register — the cache
roster cannot silently empty out from under the readers.

## References

### Sources

- Helland — *Life Beyond Distributed Transactions* (CIDR 2007) — entities behind boundaries, the
  tiered placement of durable versus derived state. https://ics.uci.edu/~cs223/papers/cidr07p15.pdf
- Erlang — *supervisor* — the dependency-ordered tree and the `:rest_for_one` cache tier.
  https://www.erlang.org/doc/apps/stdlib/supervisor.html

### Related

- `/codemojex/branded-systems` — the chapter hub.
- `/codemojex/overview/the-architecture-at-a-glance` — C0.3, the four layers first sketched.
- `/bcs` — the systems discipline the layering is built to.
- `/echomq` — the bus the durable work rides.
