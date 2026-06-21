---
title: "echo_graft — Integration surface"
id: echo-graft-integration-surface
status: Draft
note: "Signatures below are a target sketch against graft 0.2.1; the crate is ~24% documented, so confirm each against the pinned source before relying on it."
---

# echo_graft — the concrete part to get for integration { id="echo-graft-integration-surface" }

> _The exact upstream surface the sidecar wraps: which `graft` modules to depend on, what each provides, the minimal Volume API the EchoMQ sidecar exposes 1:1, and the Tigris remote wiring._

> {style="warning"}
> **Reconciliation banner (read first).** This page is a **pre-eg.1 target sketch** against `graft` 0.2.1 and has been overtaken by the as-built. Two corrections apply throughout: (1) the remote backend is **Apache OpenDAL**, *not* `object_store` — the §4 `object_store::aws::AmazonS3Builder` block is historical; the real seam is `echo_graft::remote::RemoteConfig::S3Compatible` reading `AWS_ENDPOINT_URL` (proven live against Tigris in `eg.2`). (2) `echo_graft` keeps **no backward compatibility** with upstream Graft — the internal-id seam in §5 is a clean layering boundary, **not** an upstream-mergeability concession. The binding direction is `echo/apps/echo_graft/README.md` (which supersedes the former `FORK.md`); the as-built remote facts are in `docs/graft/specs/graft.2.md`.

## 1. What to depend on

The fork pulls one crate; everything else comes transitively.

```toml
# crates/echo_graft/Cargo.toml (forked; pin to a commit, do not float)
[dependencies]
graft = { git = "https://github.com/orbitinghail/graft", rev = "<PINNED_COMMIT>" }
# transitively present and load-bearing for the seams:
#   object_store = "0.12"   # remote backend (S3 → Tigris)
#   fjall / lsm-tree         # local store
#   tokio = "1.48"           # async runtime
#   zstd                     # segment frames
#   splinter-rs              # page-set bitmaps
#   bilrost                  # commit/segment encoding
#   bs58                     # GID (base58) identifiers
#   culprit / thiserror      # error context
```

> {style="note"}
> Newer upstream merged `graft-core` into `graft-kernel` and moved clients to talk directly to object storage. Pin a commit, then confirm whether the core types live under `graft::core` (as in 0.2.1) or a `graft-kernel` crate, and adjust the paths below.

## 2. Module map — what each piece gives you

| Module | Role in the integration |
|---|---|
| `graft::rt::runtime` | **The entry point.** Instantiate once; owns the Tokio runtime, the local store, and the remote backend. The sidecar holds one Runtime. |
| `graft::setup` | Wires the Runtime's storage: local (Fjall path) + remote (`object_store`). This is where Tigris is configured. |
| `graft::volume` | A `Volume` handle — the unit of transactional state. The sidecar maps one branded Snowflake → one Volume. |
| `graft::volume_writer` | A `VolumeWriter`: stage page writes against a base snapshot, then **commit** (the single commit op). Read-your-write within the txn. |
| `graft::volume_reader` | A `VolumeReader`: lock-free reads against an immutable snapshot; pages fault in lazily from remote if not cached. |
| `graft::snapshot` | A `Snapshot` (an LSN-addressed view). The reader's basis and the change-feed cursor. |
| `graft::core` | `PageIndex`, `LSN`, `GID`, `Page`/page bytes. The value types crossing your wire. Macros `pageidx!`, `lsn!`. |
| `graft::remote` | The `object_store`-backed remote (segments, commits, checkpoints). You configure it; you don't reimplement it. |
| `graft::local` | The Fjall local store (tags/volumes/log/pages). Keep as-is. |
| `graft::err` | `GraftErr` / `LogicalErr` — map these to your wire error taxonomy (conflict/abort, not-found, unavailable). |

## 3. The minimal surface the sidecar wraps

Model the sidecar as a thin async facade over the Runtime. Every EchoMQ verb maps to one of these; nothing else needs to cross the bus.

```rust
// echo_graft_sidecar — the only Graft surface the bus touches.
// (Names are a target sketch; bind to the real graft 0.2.1 signatures.)
pub struct Engine {
    rt: graft::rt::runtime::Runtime, // owns Tokio + local(Fjall) + remote(object_store)
}

impl Engine {
    // setup: local Fjall dir + remote object_store(Tigris). See §4.
    pub async fn open(cfg: EngineCfg) -> Result<Self, graft::err::GraftErr>;

    // identity: branded {ns}{base62}  <->  Graft Volume/GID (base58). Map at the edge.
    pub async fn open_volume(&self, branded_id: &str) -> Result<Volume, GraftErr>;

    // read path: snapshot -> lazy page fault
    pub async fn snapshot(&self, vol: &Volume) -> Result<Snapshot, GraftErr>; // returns the head LSN view
    pub async fn read_page(&self, snap: &Snapshot, idx: PageIndex) -> Result<Page, GraftErr>;

    // write path: stage pages, then ONE commit (OCC + LSN append + conflict detect)
    pub async fn begin(&self, vol: &Volume) -> Result<Writer, GraftErr>;       // VolumeWriter on a base snapshot
    pub fn stage(&self, w: &mut Writer, idx: PageIndex, bytes: Bytes);          // read-your-write
    pub async fn commit(&self, w: Writer) -> Result<Lsn, GraftErr>;            // Err(conflict) on OCC failure  -> the fence

    // replication: push (rollup -> segment -> conditional commit) / pull (fetch missing LSNs)
    pub async fn push(&self, vol: &Volume) -> Result<Lsn, GraftErr>;
    pub async fn pull(&self, vol: &Volume) -> Result<Lsn, GraftErr>;
}
```

Mapping to the rungs and the EchoMQ protocol (`eg.4`):

| Sidecar method | EchoMQ verb | Rung that needs it |
|---|---|---|
| `open_volume` | `OPEN {branded_id}` | eg.3 (identity), eg.4 |
| `snapshot` / `read_page` | `SNAPSHOT` / `READ {idx}` | eg.4 |
| `begin` / `stage` / `commit` | `BEGIN` / `STAGE` / `COMMIT` | eg.2 (fence), eg.4 |
| `push` / `pull` | `PUSH` / `PULL` | eg.2 |
| commit success → `{branded_id, lsn}` | change-feed event | eg.3 |

The async note that drives the sidecar shape: the Runtime is **Tokio**-based and does blocking object-storage and LSM I/O. The sidecar owns the Tokio runtime; each EchoMQ request is handled on a Tokio task and the reply goes back over the bus. This is exactly why the integration is a sidecar and not a NIF — a NIF would have to drive Tokio inside the BEAM and run on dirty schedulers.

## 4. Tigris wiring (the `remote` seam, `eg.2`)

The remote backend is `object_store`, so Tigris is a configuration, and the commit fence is its conditional put:

```rust
// confirm exact builder methods against object_store 0.12
let tigris = object_store::aws::AmazonS3Builder::new()
    .with_endpoint(cfg.tigris_endpoint)        // Tigris S3 endpoint
    .with_bucket_name(cfg.bucket)
    .with_access_key_id(cfg.access_key)
    .with_secret_access_key(cfg.secret_key)
    .with_conditional_put(object_store::aws::S3ConditionalPut::ETagMatch) // create-if-not-exists -> commit fence
    .build()?;
// hand `tigris` to graft::setup as the remote store; graft writes
// /segments/{SegmentId} and /logs/{LogId}/commits/{LSN} through it.
```

Two writers racing a commit resolve by the losing conditional put failing — this is the fenced head from `eg.2`, provided by `object_store` + Graft's commit protocol, with no separate lease.

## 5. Identity mapping (`eg.3`)

Graft identifies Volumes/Logs with base58 GIDs; the platform uses `{ns}{base62}` Snowflakes. Map at the edge and keep the GID internal as a clean layering boundary (the edge speaks branded, the core speaks its native id; the mapping is the only translation point — not an upstream-mergeability concern):

| External (your edge) | Internal (Graft) |
|---|---|
| `VOL0O5fmcxbds8` (namespace `VOL`, Base62) | Volume GID (base58) |
| `LOG0O5fmcxbds8` (namespace `LOG`, Base62) | Log GID (base58) |

The mapping is persisted once in the Fjall volumes partition (single source of truth) and resolved on `open_volume`.

## 6. What NOT to take

- The SQLite extension (the VFS + pragma crate) — removed in `eg.1`, not wrapped.
- The SQLite plugin/VFS dependency chain.
- Any "run a Graft service" middle-man assumptions — current Graft is client-direct-to-object-storage, which is what the sidecar embeds.

## 7. Confirm-before-building checklist

- [ ] Pin the upstream commit; record it in `README.md` (the former `FORK.md`).
- [ ] Confirm whether core types are `graft::core` or `graft-kernel` at that commit.
- [ ] Confirm the real `Runtime` constructor and the `VolumeWriter` commit signature (the design exposes a single commit op).
- [ ] Confirm `object_store` 0.12's conditional-put builder method name for the S3 store.
- [ ] Confirm `GraftErr` variants for the conflict/abort case so the fence surfaces cleanly on the wire.

## References

- Crate API — https://docs.rs/graft/latest/graft/
- Architecture — https://graft.rs/docs/internals
- Source + license — https://github.com/orbitinghail/graft (MIT OR Apache-2.0)
- object_store — https://docs.rs/object_store
