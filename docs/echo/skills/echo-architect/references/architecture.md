# Echo · Architecture
<show-structure depth="2"/>

Echo is a single Mix umbrella of seven applications. The dependencies run one way: the
data and wire primitives sit at the floor, the bus builds on the wire, the storage tiers
build on the bus and the primitives, and the product composes all of them. This document
describes that shape, the path a request takes through it, the order the node boots, and
where the pieces run in production.

## The layering

The umbrella's internal dependencies, read bottom to top:

```
codemojex ─────────────────────────────────────────── the product
   │  depends on: echo_mq, echo_store, echo_data, echo_wire, echo_bot
   ├── echo_store ── declared near-cache + Graft replication
   │      depends on: echo_data, echo_mq, echo_wire
   ├── echo_mq ───── fair lanes, consumers, batches, streams
   │      depends on: echo_data, echo_wire
   ├── echo_bot ──── Telegram engine (standalone)
   ├── echo_wire ─── RESP3 + connector + script fence (the wire)
   └── echo_data ─── branded ids, Snowflake, CHAMP, Graft types, NIF
```

`echo_data` and `echo_wire` have no umbrella dependencies — they are the foundation.
`echo_mq` adds queue semantics over the wire and the id primitives. `echo_store` adds the
cache and the durable tier. `echo_bot` is independent and is pulled in only by the product.
`echo_graft` is the reserved name for the Graft tier; its live engine is split across
`echo_data` (the segment types) and `echo_store` (the volume server and remote). `codemojex`
sits at the top and is the only application that knows about all of the others.

## The identity contract

Every entity the umbrella handles is a branded id, and one module — `EchoData.BrandedId` —
owns the format. The layout is fourteen bytes: a three-letter uppercase namespace followed
by the width-11 base62 of a 63-bit Snowflake.

```
USR0KHTOWnGLuC
└┬┘└─────┬────┘
 │       └── base62(snowflake), 11 chars
 └────────── namespace, 3 chars [A-Z]
```

The Snowflake itself is `ts(41) <<< 22 ||| node(10) <<< 12 ||| seq(12)`, epoch
2024-01-01, minted lock-free from a single `:atomics` cell by `EchoData.Snowflake`. Because
the timestamp leads, ids sort in creation order, carry their own age, and deduplicate by
value. `EchoData.BrandedId.hash32/1` is the single routing hash — the same value the bus
uses to place a lane. Namespaces seen across the product include `GAM` (game), `ROM` (room),
`PLR` (player), `SES` (session), `JOB` (queue job), `GES` (guess), and `EMS` (emoji set).

The codec has a Rust and C core under `EchoData.Native`, with a pure-Elixir path that
returns identical results; `self_check!/0` asserts the two agree at boot.

## The life of a request

A guess in `codemojex` exercises the whole stack and shows how the layers cooperate. The
async path is deliberate: the surface that accepts a guess never scores it.

- **Accept and charge.** `Codemojex.Guesses.submit/3` validates the six codes against the
  game's keyboard, overlays the player's locked positions, and charges the right currency
  through `Codemojex.Wallet` — clips for a free room, keys for a paid one, the golden path
  for a tournament — as a Postgres transaction with a ledger entry.
- **Enqueue on the player's lane.** It mints a `JOB` id, encodes `{:guess, game, player,
  guess}`, and enqueues it through `EchoMQ.Lanes` on a lane named by the player's `PLR`.
  Naming the lane by player is what lets the bus rotate service across players so one
  guesser cannot starve the field. `submit/3` returns once the job is enqueued.
- **Claim and score.** A supervised `EchoMQ.Consumer` — the scoring authority — beats on
  its cadence: it reaps expired leases, promotes due schedules, then drains the ring with
  rotating claims. When it claims the job it runs `Codemojex.Scoring.score/2` against the
  secret read from the system of record.
- **Persist and rank.** The consumer writes the `GES` row to Postgres, records the score
  in a Valkey sorted set through `Codemojex.Board`, and broadcasts the scored event on the
  `Codemojex.PubSub` topic `"game:" <> game`.
- **Read, with privacy intact.** `Codemojex.View` answers player reads — the game view,
  the player's own history, the leaderboard — and withholds the secret and other players'
  guesses by construction. The leaderboard reads the Board sorted set.

The wire under steps 2 through 4 is `echo_wire`: `EchoMQ.Connector` owns the sockets,
`EchoMQ.RESP` frames the protocol, and `EchoMQ.Script` runs the Lua behind the version
fence that the lane operations compile to.

## The boot order

`Codemojex.Application.start/2` brings the node up in a fixed order, each child depending
only on those before it:

- `Codemojex.Rails.self_check!/0` — assert every currency rail's scaling before any order
  can be priced, so a mis-scaled money constant fails the boot.
- `Codemojex.Repo` and `Phoenix.PubSub` — the system of record and the broadcast fabric.
- `Codemojex.Bus` — the shared Valkey connector for every lane.
- `Codemojex.Tables` — the EchoStore near-cache tier for games and emoji sets.
- `Codemojex.RateLimiter` and `Codemojex.EchoBot` — the limiter and the gateway the
  notification worker depends on.
- The consumers — scoring, settlement, notification, and inbound bot commands — each an
  `EchoMQ.Consumer` on its own lane.
- `EchoData.ChampServer` — an in-memory CHAMP view of the leaderboard, rebuildable from
  Graft.
- `Codemojex.Sweep` — the periodic close-and-nudge timer.
- `CodemojexWeb.Endpoint` — the Phoenix surface.
- The Graft `Committer` — started only when a volume is configured, so the node boots
  without the replicated tier.

## The deployment surfaces

The product runs on a small, legible set of services:

- **A single always-on Fly machine** carries the Phoenix endpoint: the JSON API, the
  channel socket, and the LiveView tiers. It is configured to stay up rather than scale to
  zero, so sockets do not drop.
- **Valkey** is the live tier on the bus port: the EchoMQ lanes, the Board sorted sets, and
  the L2 behind the EchoStore near-cache. In development the connector falls back to
  `127.0.0.1:6390` with no auth; in production it dials a dedicated node over a private
  network with a password from the environment.
- **Postgres** is the system of record: wallets, games, the transaction ledger, the revenue
  ledger, and the key shop.
- **Tigris** is cold storage: the Graft segments and conditional commit objects, alongside
  the content-hashed static bundles the welcome shell and board client load.

The board client and welcome shell ship as static assets to Tigris, swapped by an upload
and a pointer flip rather than a redeploy, so the always-on machine keeps its sockets while
the client changes.
