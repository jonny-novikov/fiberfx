# Echo · Component Reference
<show-structure depth="2"/>

A reference page for each of the seven applications in the umbrella: what it is, the
modules that carry its weight, and how it fits the whole. The applications are described
floor-first, in the order they depend on one another.

## echo_data — the BCS foundation

`echo_data` owns identity and the persistent structures built on it. It is the one
application every other one rests on, and it has no umbrella dependencies of its own.

The identity core is three modules. `EchoData.Snowflake` mints lock-free, time-ordered
64-bit ids from a single `:atomics` cell with a compare-exchange per mint, handling clock
regression and sequence exhaustion without blocking. `EchoData.BrandedId` is the codec and
hash contract — namespace plus base62 Snowflake, the single `hash32/1`, the `~b` compile-time
sigil, and the `self_check!/0` that proves the native and pure paths agree.
`EchoData.Base62` is the width-11 `0-9A-Za-z` codec. `EchoData.Native` is the optional Rust
and C NIF; when it is absent, the pure implementations serve identical results.

On top of the ids sit the persistent structures: `EchoData.BrandedChamp`, `EchoData.BrandedMap`,
and `EchoData.BrandedTree` are CHAMP-based immutable maps keyed by branded ids, with
`EchoData.ChampNode`, `EchoData.ChampServer`, and `EchoData.ChampView` providing the node
representation and the in-memory, rebuildable views the product uses for leaderboards.
`EchoData.BCS` is the boundary gate — it admits ids of one namespace and refuses everything
else, adding no second parser. The BCS sub-tree (`EchoData.BCS.Archetypes`,
`EchoData.BCS.EdgeStore`, `EchoData.BCS.PropertyStore`, with its supervisor) is the
branded-component store. The Graft segment types — `EchoData.Graft.Id`,
`EchoData.Graft.PageSet`, `EchoData.Graft.Segment`, `EchoData.Graft.Types` — define the
page-based replication units that `echo_store` drives. `EchoData.Timeline`,
`EchoData.Buckets`, `EchoData.FrozenIndex`, and `EchoData.Edges` round out the structure set.

## echo_wire — the wire

`echo_wire` is the transport layer, extracted to stand as its own library. Its facade,
`EchoWire`, is the front door to three concerns: RESP framing, the single-owner socket
connector, and the script registry behind a version fence.

The transport modules keep their frozen names from the records that cite them:
`EchoMQ.Connector` is the pooled, single-owner Valkey connector — authenticated boot, an
idle heartbeat with server-death recovery, graceful shutdown, and a fixed pool with a
lock-free claim; `EchoMQ.RESP` is the RESP3 codec with HELLO negotiation and out-of-band
push routing; `EchoMQ.Script` is the Lua registry that loads scripts behind a fence so a
running node does not see a half-applied change. The command side — `EchoWire.Cmd`,
`EchoWire.Command`, `EchoWire.Pipe`, and `EchoWire.Result` — builds, pipelines, and reads
back commands. Everything in the umbrella that prices a call, sweeps a queue, or parks a
consumer speaks through this one layer.

## echo_mq — the message bus

`echo_mq` is the queue and bus over Valkey, and it is the largest of the substrate
applications. It builds fair admission, a parking consumer, batches, control flows, and
streams on the wire.

The two modules at its heart are `EchoMQ.Lanes` and `EchoMQ.Consumer`. A lane is a
per-group pending set named by an identity; the ring is the rota of lanes serviceable right
now, and every claim rotates it one step before serving, so fairness is constructed rather
than hashed. `EchoMQ.Consumer` is the loop that owns the rhythm — a supervised process with
a dedicated connector that reaps expired leases, promotes due schedules, drains the ring,
then parks on a wake key with a blocking read until readiness or the next beat. A raising
handler converts to a typed retry and the loop survives; a drained stop settles the job in
hand and nothing more.

Around that core: `EchoMQ.Jobs` and `EchoMQ.Queue` hold the job transitions and the queue
surface; `EchoMQ.Flows` carries control flows and group-aware pause and resume;
`EchoMQ.BatchConsumer`, `EchoMQ.BatchFinish`, and `EchoMQ.BatchShaper.Core` carry batching;
`EchoMQ.Cancel`, `EchoMQ.Locks`, `EchoMQ.Stalled`, `EchoMQ.Repeat`, and `EchoMQ.Backoff`
carry lifecycle, leases, and retry; `EchoMQ.Stream`, `EchoMQ.StreamConsumer`, and
`EchoMQ.StreamRetention` carry the stream tier; `EchoMQ.Meter`, `EchoMQ.Metrics`, and
`EchoMQ.Metronome` carry measurement and cadence; `EchoMQ.Pool` and `EchoMQ.Pump` carry the
connection pool and the drain pump; and `EchoMQ.Admin`, `EchoMQ.Dashboard`,
`EchoMQ.Conformance`, `EchoMQ.Events`, and `EchoMQ.Keyspace` carry administration, the
operator view, the conformance gate, the event model, and the key layout. Two Mix tasks,
`echo_mq.dashboard` and `echo_mq.stories`, drive the dashboard and the worked narratives.

## echo_store — the cache and the durable tier

`echo_store` holds two tiers: a declared near-cache and a native-BEAM replication engine.
It depends on `echo_data`, `echo_mq`, and `echo_wire`.

The near-cache is `EchoStore` itself: L1 ETS tables in front of the L2 Valkey the systems
already share, with the first law that a cache is declared, not discovered. Every table
registers its full specification at start, the operator enumerates the node's caches, and a
cache absent from the directory does not exist. `EchoStore.Coherence` keeps L1 and L2
consistent with Snowflake-versioned, newer-wins resolution; `EchoStore.ComponentStore`,
`EchoStore.Table`, `EchoStore.Ring`, `EchoStore.Keyspace`, and `EchoStore.Journal` carry the
component reads, the table head, the hash ring, the key layout, and the write journal;
`EchoStore.Durability` with its memory and SQLite adapters carries local persistence.

The replication tier is Graft: native-BEAM, lazy, partial, page-based, strongly consistent,
with no foreign engine. `EchoStore.Graft.VolumeServer` is the single-writer process whose
mailbox is the global write lock; `EchoStore.Graft.Store` keeps pages on CubDB's append-only
immutable B-tree, where zero-cost MVCC snapshots are Graft snapshots; `EchoStore.Table`
serves as the write-through head-page cache; and `EchoStore.Graft.Remote.Tigris` ships
segments and conditional commit objects to Tigris S3 in real time. The supporting modules —
`EchoStore.Graft.Committer`, `EchoStore.Graft.Reader`, `EchoStore.Graft.Streamer`,
`EchoStore.Graft.Sync`, `EchoStore.Graft.Divergence`, `EchoStore.Graft.Epoch`,
`EchoStore.Graft.Segment`, and `EchoStore.Graft.Supervisor` — carry the commit path, reads,
streaming, sync, divergence detection, epochs, and supervision. `EchoStore.StreamArchive`
and `EchoStore.StreamHydrator` archive and rehydrate streams, and `EchoStore.Tigris` is the
shared object-store client.

## echo_bot — the Telegram engine

`echo_bot` is a compact, vendored Telegram engine, independent of the rest of the umbrella
and pulled in only by the product. `EchoBot.Application` runs the updater — polling in
development, webhook in production — and `EchoBot.Bot` is the client. `EchoBot.Platform` with
`EchoBot.Platform.Telegram` and `EchoBot.Platform.Update` adapts the platform and normalizes
inbound updates; `EchoBot.Config`, `EchoBot.Handler`, and `EchoBot.Handlers.Hello` carry
configuration and the handler chain. The engine starts no bot when no token is configured —
it logs a warning and the host still boots — so a bare interactive session needs no
credential.

## echo_graft — the reserved Graft name

`echo_graft` is the reserved application name for the Graft replication tier. It carries no
modules of its own in this branch; the live engine is split between `echo_data`, which
defines the segment types, and `echo_store`, which runs the volume server, the store, and
the Tigris remote. The name is held so the tier can be lifted into its own application
without renaming the modules that already cite it.

## codemojex — the reference application

`codemojex` is the product that composes the umbrella: a six-emoji code-breaking
competition whose entities are branded components in Postgres, whose guesses are jobs on
per-player lanes scored by a single authority, whose three currencies mutate atomically
through a wallet with a transaction ledger, and whose prize pools settle through a second
queue. It depends on every substrate application and on `echo_bot`.

The engine modules carry the game. `Codemojex.Guesses` is the play API — validate, overlay
locks, charge, enqueue — and `Codemojex.Scoring` is the authority the consumer runs.
`Codemojex.Rooms` templates games from rooms; `Codemojex.Wallet`, `Codemojex.Economy`,
`Codemojex.KeyShop`, and `Codemojex.Rails` carry the three currencies, the fee economy, the
purchase path, and the boot-time scaling check; `Codemojex.Board` and `Codemojex.View` carry
the Valkey-backed ranking and the privacy-enforcing reads; `Codemojex.Locks`,
`Codemojex.Sweep`, `Codemojex.Session`, `Codemojex.InitData`, and `Codemojex.EmojiSet` carry
position locks, the periodic sweep, sessions, the Telegram handshake, and the keyboard.
`Codemojex.Store` and `Codemojex.Cache` bind the system of record and the near-cache;
`Codemojex.Bus` and `Codemojex.Tables` bind the EchoMQ connector and the declared caches;
`Codemojex.RateLimiter` and `Codemojex.EchoBot` bind the limiter and the bot, wired to the
bus on both the outbound notification path and the inbound command path.

The web layer is `CodemojexWeb`: a Phoenix surface on Bandit with a JSON API, a channel
socket for the board, and the LiveView tiers for the lobby and game. `Codemojex.Application`
is the supervision tree that brings the whole node up in order — the Repo and PubSub, then
the bus, then the caches, the limiter and bot, the consumers, the leaderboard view, the
sweep, and the endpoint.
