# echo_graft_backend — the sidecar architecture

`echo_graft_backend` is the supervised EchoMQ participant that drives the
`echo_graft` Rust page-engine. The engine does blocking object-storage + LSM I/O, so
it runs as a backend process addressed over the bus rather than an in-VM NIF: an
engine crash becomes a supervised restart, not a downed orchestrator. The crate is a
**session + dispatch + publish shell** with no engine logic of its own. The overview
is [`../echo_graft.md`](../echo_graft.md); the wire it speaks is [`wire.md`](wire.md);
the write tier it fronts is [`low-latency-tier.md`](low-latency-tier.md).

## The layers

| Module | Role |
|---|---|
| `session::Session` | the version handshake, the request→dispatch→reply path, the per-push change-feed republish |
| `dispatch` | the 1:1 translation of each `echo_graft_proto` request onto the real `Runtime` method map, with the closed error taxonomy |
| `transport::FeedSink` | the abstract publish capability (the engine carries no Valkey client) — `InMemorySink` for the in-process proof, `BusPublishSink` (in `live`) for the live bus |
| `feed_sink::BusFeed` | the `ChangeFeed` that frames each event as `Msg::Feed` and publishes it on `egraft:feed:{vol}` through a `FeedSink` |
| `backpressure::Backpressure` | the per-Volume in-flight cap (see [`low-latency-tier.md`](low-latency-tier.md)) |
| `live::LiveBackend` | the live Valkey :6390 RESP3 transport (eg.5) — binds the session to a real socket and consults the cap |
| `backend_main` | the deployable binary — opens an engine `Runtime`, binds `live::serve`, serves real clients |

## The session — `session::Session`

A `Session` wraps one `Runtime` and one `FeedSink`; the transport hands it
already-framed request bytes and takes the response bytes back — the session never
owns a socket.

- **The handshake gates it.** `Hello` → `Welcome` (at `min(client_max, PROTO_MAX)`)
  or `Incompatible`; a request before the handshake is refused `unavailable` and
  touches no Volume. A refused handshake performs no Volume op.
- **The feed republish.** eg.3's `volume_push` records advances in the engine's
  in-memory feed (`RuntimeInner.feed` is a concrete `Arc<InMemoryFeed>` — the engine
  is byte-frozen, so the backend reads advances out per push rather than injecting a
  bus sink). After each `Push` acks, the session reads the events the engine published
  beyond a bus-side cursor (`InMemoryFeed::events_since`, monotone + gap-free) and
  republishes them through the sink, advancing the cursor so each event goes out
  exactly once. `replay_since/2` serves a reconnecting client's resubscribe from its
  last-seen LSN.

## The dispatch — `dispatch`

Each request variant grounds in a `Runtime` method: `OpenVolume` →
`volume_open_branded`, `Commit` → `volume_writer` + `write_page` + `commit`, `Push` →
`volume_push`, `Read` → `volume_reader` + `read_page`, `Snapshot` →
`volume_snapshot`, and so on. The backend adds no engine logic — only translation and
the **closed** error mapping (`err_kind_of`): `VolumeConcurrentWrite` → `conflict`,
`VolumeNotFound` → `not_found`, everything else → `unavailable`. Two realizations are
flagged in source: a wire page is right-padded to the fixed `PAGESIZE` (an
over-`PAGESIZE` page is `unavailable`, never a panic), and the commit `mode`/`base`
are advisory to the thin dispatch (the mode's guarantee is enforced by the buffer, the
base by the engine's own OCC).

## The live transport — `live::LiveBackend` + `live::serve`

The ruled A-2: a **raw `tokio` socket loop reusing the proto codec**, no
redis/valkey client dependency. Two facts keep it small — RESP3 pub/sub is itself a
flat array-of-bulk-strings protocol (the shape `encode_parts` already speaks), and
each message payload is an `echo_graft_proto` frame decoded by the same codec the
conformance suite pins byte-equal to `EchoMQ.RESP`. So the live bytes cannot drift
from the BEAM client; only `HELLO 3` and a streaming RESP3 reader are new wire code.

### The two-socket split

`live::serve` opens **two** connections to :6390 (the bus splits read and write
cleanly):

- a **command connection** that `SUBSCRIBE`s the control lane (`egraft:cmd:_control`)
  plus each per-Volume command lane it serves, and reads inbound
  `["message", lane, payload]` pushes;
- a **publish connection** used to `PUBLISH` replies on `egraft:reply:{client}` and
  feed events on `egraft:feed:{vol}` (the `BusPublishSink`, fire-and-forget — a
  publish error is logged and dropped, never stalling a commit).

`hello3` writes `HELLO 3` and moves on without consuming the reply: on the command
socket the reply is the first frame the reader sees (a `%` map → classified ignored);
on the publish socket the read half is never read, so the reply sits harmlessly
buffered. The engine dispatch is **blocking** (it `block_on`s remote I/O), so the loop
bridges it with `tokio::task::block_in_place` — the engine blocks on a worker thread
legally while the reader stays responsive and the feed sink's spawn still sees the
runtime handle.

### The cap on the live path (criterion 8)

`LiveBackend::handle_request_frame` is the production call site: it decodes the frame
just enough to (a) learn a `Hello`'s reply lane, then (b) consult
`Backpressure::admit(vid)` for a `{vol}`-bearing command **before**
`Session::handle_frame`. At the cap it refuses with `Msg::Err{Unavailable}` without
dispatching; below it, the held `Permit` spans the dispatch (release-on-drop). This
closes UF-1's "tested in isolation ≠ wired in" trap — the criterion's grep resolves to
`bp.admit` on the real request path, and the deterministic non-gated tests
(`live_cap_is_consulted_on_the_live_path`, `live_unknown_vid_is_not_found`) fail if the
consult is removed.

## In-process vs. live — the transport abstraction

The session depends only on the `FeedSink` capability, not a concrete client. The
in-process round-trip proof drives a real engine through a `Session` over
`InMemorySink` (no bus, no socket) and asserts the engine-side facts the wire must
surface — commit→push acks the LSN and publishes a matching opaque feed frame, two
conflicting commits split ack/`conflict`, a refused handshake touches no Volume. The
**live leg** swaps `InMemorySink` for the bus-backed sink and runs against a real
Valkey :6390 — env-gated (`ECHO_GRAFT_BACKEND_TEST`), so the default suite needs no
running bus, and an excluded leg is reported skipped, never trivially passed. A
spawned test stands the backend up inside itself (a `live::serve` task) and tears it
down at test end — a spawned process cannot leave a server running, so the proof is
self-contained.

## The binary — `backend_main`

The deployable entry stands the engine up as a real participant: it opens an engine
`Runtime` (a memory remote + a temporary Fjall store for the eg.5 leg; a deployment
swaps in the real Tigris remote + a persistent store), opens each `ECHO_GRAFT_BRANDED`
Volume up front so its command lane can be subscribed, binds `live::serve`, and prints
a single `READY <branded>=<vid> …` line so a launching supervisor can wait for the
backend to be connected + subscribed before driving it. Configuration is by env
(`ECHO_GRAFT_VALKEY_HOST`/`PORT`, `ECHO_GRAFT_BRANDED`, `ECHO_GRAFT_CAP`); SIGINT or a
closed serve loop triggers shutdown.

## How the BEAM drives it — `EchoStore.GraftBackend`

The Elixir client (`apps/echo_store/lib/echo_store/graft_backend.ex`) is the
peer that turns this sidecar into a BEAM-callable durability tier. It publishes each
request on the matching lane via `EchoMQ.Connector.command/3` (`PUBLISH`), listens on
its own `egraft:reply:{client}` lane for the correlated response, and subscribes the
`egraft:feed:{branded}` lane to advance its replay cursor from the opaque feed blob
(`GraftBackend.FeedBlob` peeks only the branded id + LSN). The connector owns
supervised reconnect and re-issues every subscription on reconnect, so the feed
survives a bounce and the client replays from its last-seen LSN. The vid-less verbs
(`hello` / `open_volume` / `resolve_branded`) ride the shared control lane, exempt
from the per-Volume cap by the same construction the backend enforces.
