# echo_graft_proto — the byte-frozen cross-runtime wire

`echo_graft_proto` is the contract between the two runtimes: the Rust
`echo_graft_backend` sidecar and its BEAM client `EchoStore.GraftBackend`. Every
message has **one** frozen encoding, asserted byte-for-byte by a conformance suite
**both** sides run against a single shared fixture set — neither side owns its own
truth. It is the parent crate of the wire; the overview is [`../echo_graft.md`](../echo_graft.md).

## The encoding — the `EchoMQ.RESP` intersection

A message is a flat RESP3 array of bulk strings, `[tag, field, field, …]`,
byte-identical to the Elixir `EchoMQ.RESP.encode/1` codec
(`apps/echo_wire/lib/echo_mq/resp.ex`). Every field is a bulk string; integers are
their decimal ASCII; an absent optional id is the empty string. Nothing here emits a
nested aggregate — `EchoMQ.RESP.encode/1` is itself flat — so the two
implementations cannot disagree on structure; only the bytes remain to prove equal,
which the shared fixture does. The Rust `encode_parts/1` and `decode_parts/1` are the
mirror of `EchoMQ.RESP.encode/1` / `parse/1`.

The eg.3 `FeedEvent` rides as an **opaque** bilrost blob (already byte-frozen in
`echo_graft::feed`): the wire wraps it as one bulk string in `Msg::Feed` and never
re-encodes its fields, so the two freeze-points compose without duplication.

## The message taxonomy — `Msg`

Each variant has one byte-frozen encoding; requests/responses carry a `corr`
correlation id, the handshake and the feed do not. The Rust enum is
`echo_graft_proto::Msg`; the Elixir mirror is `EchoStore.GraftBackend.Proto` (tagged
tuples — same closed tag set, same arities).

| Wire tag | `Msg` variant | Direction | Carries |
|---|---|---|---|
| `HELLO` | `Hello` | client → backend | `proto_min` · `proto_max` · `client` |
| `WELCOME` | `Welcome` | backend → client | the selected `proto` |
| `INCOMPAT` | `Incompatible` | backend → client | `proto_min` · `proto_max` · `reason` |
| `OPEN` | `OpenVolume` | request | `corr` · `branded` · optional `local`/`remote` Log ids |
| `RESOLVE` | `ResolveBranded` | request | `corr` · `branded` |
| `COMMIT` | `Commit` | request | `corr` · `vid` · `base` · **`mode`** · `pages` |
| `PUSH` | `Push` | request | `corr` · `vid` |
| `PULL` | `Pull` | request | `corr` · `vid` |
| `READ` | `Read` | request | `corr` · `vid` · `pageidx` |
| `SNAP` | `Snapshot` | request | `corr` · `vid` |
| `GETCOMMIT` | `GetCommit` | request | `corr` · `log` · `lsn` |
| `ACK` | `Ack` | response | `corr` · `lsn` |
| `PAGES` | `Pages` | response | `corr` · raw page/vid bytes |
| `SNAPRESP` | `SnapshotResp` | response | `corr` · `lsn` · `pages` |
| `ERR` | `Err` | response | `corr` · `kind` · `detail` |
| `FEED` | `Feed` | publish-only | the opaque `FeedEvent` blob |

The error `kind` is a **closed** taxonomy (`ErrKind`): `conflict` (a lost OCC or
fence) · `not_found` (no such Volume/commit) · `version_mismatch` (no overlapping
protocol version) · `unavailable` (transport / storage / overload). A new kind is a
protocol-version bump, never a silent addition.

## The version fence — drop-v1, `PROTO_MIN = PROTO_MAX = 2`

eg.5's wire law (Operator ruling D-5): **v1 was dropped.** It had zero deployed
consumers, so the build speaks **only** v2 — `PROTO_MIN = PROTO_MAX = 2` on both
sides. The `Hello`/`Welcome`/`Incompatible` handshake negotiates the overlap; a v1
peer fails negotiation **by design** (correct: v1 is dropped). `negotiate/2` selects
`min(client_max, PROTO_MAX)` when the ranges overlap.

The per-call durability mode rides the **`COMMIT` message itself**, not a separate
`COMMIT2` tag:

- `Commit` gains a fixed-position `mode` field (`async` | `sync`) between `base` and
  the page count — `[COMMIT, corr, vid, base, mode, npages, (idx, page)*]`. The
  strict-arity decoder, indexing the fields **after the tag**, reads the mode at index
  3 (`rest[3]`), then the page tail from index 5 (`rest[5..]`).
- The mode is **always** on the wire; there is no mode-less `COMMIT`. The `:sync`
  default lives in the **client API** (`EchoStore.GraftBackend.commit/5` substitutes
  `:sync` when the caller omits `:mode`, then always encodes it) — never a
  wire/version default, because v1 is dropped so there is no mode-absent frame for a
  wire default to fill.
- An out-of-set mode token is a `BadField("commit_mode")`, never a silent default —
  the `Mode` token set is closed (`async`/`sync`), exactly like `ErrKind`.

`grep COMMIT2` is 0 in the tree: the modification is in place, not a parallel shape.

## What is byte-frozen, what was regenerated

The fixture set lives at `crates/echo_graft_proto/tests/fixtures/wire.fixtures`,
**mirrored byte-identical** into `apps/echo_store/test/fixtures/graft_backend/`.
The eg.5 v2 bump regenerated exactly:

- `hello` / `welcome` — the version bytes `1` → `2`.
- `commit` — `*7` → `*8`, with `$4\r\nsync\r\n` inserted at the mode position.
- `commit_async` — a new fixture (the `async` mode token).

Every **non-v2** fixture stays byte-identical to its prior state:
`incompatible` · `open_volume` · `resolve_branded` · `push` · `pull` · `read` (and
the eg.3 51-byte `FeedEvent` blob it wraps). A silent re-encode of those would be a
loud failure.

## Dual-side conformance — the cross-runtime-skew proof

The byte-freeze posture under drop-v1 is **not** a HEAD-diff (the `commit`/handshake
fixtures were intentionally regenerated). It is a **dual-side equality**: the Rust
conformance suite (`crates/echo_graft_proto/tests/conformance.rs`) and the Elixir
conformance suite (`apps/echo_store/test/echo_store/graft_backend/proto_conformance_test.exs`)
both assert their own encoder produces the shared fixture bytes — so Rust-encode ==
fixture == Elixir-encode, and a drift on either side fails loud. Because the two
fixture files are held byte-identical, the conformance is the standing proof that the
two runtimes cannot diverge on the wire — the class of bug a second, independent
encoder would re-open.

Regenerate the Rust side with `REGEN_FIXTURES=1 cargo test -p echo_graft_proto --test
conformance`; the Elixir mirror must then be re-synced byte-identical, or its
conformance test fails.
