# echo_graft — the transactional + replicated durability tier (Rust)

`echo_graft` is a from-scratch Rust Volume engine — an LSN-ordered commit log,
copy-on-write page data, a conditional-write commit that doubles as the
multi-writer fence, and lazy page faulting — driven from the BEAM as a supervised
**`echo_graft_backend`** sidecar over EchoMQ (RESP3). It fills the durability
quadrant that is **transactional and replicated** at once, beside Champ
(bounded-loss, in-memory) and Oban (strict, single-node). Where `echo_data` is
identity and `echo_mq` is the queue, `echo_graft` is the durable floor underneath
`echo_store`'s cache: a commit is a fenced LSN append, replicated page-by-page to
Tigris over object storage.

It was **seeded from** [`orbitinghail/graft`](https://github.com/orbitinghail/graft)
(MIT OR Apache-2.0), with the SQLite extension cut and three seams rewritten — a
Tigris remote over Apache OpenDAL, branded-Snowflake identity at the edge, and an
EchoMQ change-feed off the commit LSN. It keeps **no upstream compatibility** (not
API, not wire, not cherry-pick); upstream is a read-only idea source, never a sync
target. The standing brief is `apps/echo_graft/README.md`; the program canon is
`docs/graft/`.

## The two engines coexist — `echo_graft_backend` is a peer, not a replacement

The umbrella ships **two functional-twin durability engines**, and they
**coexist** (Operator ruling D-1 = A, `docs/graft/graft.engine-split.design.md`):

| Engine | Runtime | Local store | Role |
|---|---|---|---|
| `EchoStore.Graft.*` | native BEAM | CubDB | the **canonical**, untouched page/Volume engine — see [`echo_store.md`](echo_store.md) (§ "Graft") |
| `echo_graft` + `echo_graft_backend` | Rust sidecar | Fjall | a **coexisting peer**, driven over the bus by `EchoStore.GraftBackend` |

Both own the write-lock, the OCC commit, the conditional-write fence, the segment
rollup, the Tigris remote, lazy reads, and a change-feed — they are twins, not
layers. The Rust peer never modifies or wraps the native engine, and its bus lanes
are distinct by construction: `egraft:cmd:{vol}` / `egraft:reply:{client}` /
`egraft:feed:{vol}` vs the native `graft:{vol}:commits`.

## The crate map

A Cargo workspace inside the umbrella's `apps/` (Mix ignores it — no `mix.exs`):

| Crate | Role |
|---|---|
| `echo_graft` | the Volume runtime — core, the Fjall local store, the OpenDAL remote, the rt action layer |
| `echo_graft_proto` | the byte-frozen, version-negotiated wire — see [`echo_graft/wire.md`](echo_graft/wire.md) |
| `echo_graft_backend` | the EchoMQ-participant sidecar — see [`echo_graft/backend.md`](echo_graft/backend.md) + [`echo_graft/low-latency-tier.md`](echo_graft/low-latency-tier.md) |
| `echo_graft_test` | the Volume/transaction parity harness + integration tests (incl. live-Tigris legs) |
| `echo_graft_tracing` | the tracing setup helper (test / antithesis) |

## The engine — `echo_graft::rt::runtime::Runtime`

The engine handle is `Runtime` (`Clone`, wraps `Arc<RuntimeInner>`); everything the
sidecar dispatches lands on its method map. The public surface, by concern:

| Module | Role |
|---|---|
| `rt::runtime::Runtime` | the engine handle: `volume_open` / `volume_open_branded` / `resolve_branded`, `volume_writer` / `volume_reader`, `volume_push` / `volume_pull`, `volume_snapshot`, `get_commit`, `feed` |
| `identity::BrandedId` | the validated `{NS}{base62}` edge identity — **caller-supplied** (`parse`/`namespace`/`body`/`as_str`); the engine validates + round-trips, it never mints |
| `remote` | the Tigris remote over OpenDAL — `RemoteConfig::{Memory, Fs, S3Compatible}`; the commit fence is OpenDAL's `if_not_exists` ⇒ `ConditionNotMatch` |
| `feed` | the change-feed: the byte-frozen `FeedEvent`, the `ChangeFeed` trait, the `InMemoryFeed` stub, and `lane_for/1` (`egraft:feed:{vol}`) |
| `volume` / `volume_reader` / `volume_writer` | a `Volume` record, a lock-free `VolumeReader` over a snapshot, a read-your-write `VolumeWriter` staging a segment |
| `err` | the engine error taxonomy — `GraftErr` / `LogicalErr` (the wire's closed-kind source) |
| `local::fjall_storage` | the on-disk store (tags / volumes / log / pages / the branded↔native index), snapshot-version-level OCC |

Local commit OCC is **snapshot-version-level, not page-level** (a stale-base commit
aborts `VolumeConcurrentWrite` even on disjoint pages); page-level merge is a
remote-sync property, not a local-commit one. The branded id is caller-supplied —
the platform mints, the engine validates and stores.

## The BEAM client — `EchoStore.GraftBackend`

The Elixir half of the peer (`apps/echo_store/lib/echo_store/graft_backend.ex`): a
`GenServer` that handshakes, sends the request/response verbs
(`open_volume` / `resolve_branded` / `commit` / `push` / `pull` / `read` /
`snapshot`) on a per-Volume command lane, and subscribes the change-feed lane to
observe durable advances without polling. It rides only the verified
`EchoMQ.Connector` surface (`command/3` for `PUBLISH`, `subscribe/2` for the reply +
feed lanes), owns the feed replay cursor (the last-seen LSN), and never inspects the
opaque feed blob beyond the two fields its cursor needs (`GraftBackend.FeedBlob`).
`commit/5`'s `:mode` option (`:async` | `:sync`, defaulting `:sync`) is the
client-API durability default the wire never carries.

## What makes it trustworthy

The rung ladder eg.1–eg.5, as-built on disk:

| Rung | Ships |
|---|---|
| **eg.1** | core fork + workspace — the runtime carved from upstream, `libgraft_ext` removed, the Fjall store retained, upstream Volume tests green |
| **eg.2** | the Tigris remote (OpenDAL `S3Compatible`) + the conditional-write fence, verified live against real Tigris |
| **eg.3** | branded-Snowflake identity + the EchoMQ change-feed off the commit LSN |
| **eg.4** | `echo_graft_backend` sidecar + `echo_graft_proto` versioned wire + `EchoStore.GraftBackend` client; the cross-runtime contract |
| **eg.5** | the low-latency write tier (group-commit buffer + per-call `:async`/`:sync` mode) **and** the first live Rust↔Valkey :6390 socket binding |

The posture the gates hold:

- **Byte-frozen wire.** Once `echo_graft_proto` defines a message, its encoding is
  frozen; a change is a `PROTO_MIN..=PROTO_MAX` bump with regenerated fixtures, never
  a silent edit. A single shared fixture set is asserted byte-for-byte by **both**
  runtimes' conformance suites — neither side owns its own truth.
- **Determinism.** Any new mint / lease / commit surface runs a ≥100-iteration
  interleaving loop with no conflict-detection miss or lost commit (eg.3's
  `identity_feed` ran 100/100). Fault suites run `--test-threads=1` (the engine's
  antithesis precept state is process-global).
- **Live-fenced.** eg.2's conditional-write fence is verified against real Tigris;
  eg.5's socket binding is proven over a real Valkey :6390 round-trip (open → commit
  → push → ack → feed), env-gated so the default suite needs no running bus.
- **Owned divergences.** No upstream compatibility; OpenDAL (not `object_store`);
  base58 `Gid` native ids with caller-supplied branded ids (no Rust minter); a macOS
  `tcp_user_timeout` cfg-gate. These are permanent, owned departures — nothing to
  re-merge.

## Where echo_store uses it

`EchoStore.GraftBackend` is the BEAM-facing peer; the durability-shootout numbers
that rank `echo_graft` beside Champ and Oban are **pending eg.6** (the cross-compile
+ CI + shootout rung). The `EchoStore.Durability.Graft` outbox adapter (the
"commit-log-is-the-outbox" facade, [`echo_store/durability/README.md`](echo_store/durability/README.md))
rides the **native** engine, not this Rust peer — the two stay distinct.
