# echo_store — the L1-over-L2 cache, coherence, and Graft

`echo_store` (the successor name of `echo_cache`) is the read-hot half of the
stack: an in-process ETS **L1** over a shared Valkey **L2**, kept coherent across
nodes by a broadcast ring, with a native-BEAM replication engine (**Graft**)
underneath for durable, versioned volumes. Where `echo_data` is identity and
`echo_mq` is the queue, `echo_store` is the cache the hot path reads through — and
the layer Codemojex's `Cache` seam fronts so a round's immutable secret and emoji
set are served from memory.

## The cache table — `EchoStore.Table`

An ETS L1 in front of the Valkey L2. A miss triggers a **single-flight fill** from
L2 (concurrent readers of the same key wait on one in-flight read, not N), and a
write carries a 14-byte version so coherence can order updates.

| Function | Purpose |
|---|---|
| `start_link/1` | start a named table (L1 + its L2 binding) |
| `fetch/3` | read by id; fill from L2 on an L1 miss (single-flight) |
| `put/3`, `put/4` | write a value (optionally with an explicit 14-byte version) |
| `apply_coherence/4` | apply an out-of-band coherence notice for `{id, version}` |
| `apply_batch/2` | apply a batch of coherence notices |
| `invalidate/3` | drop an id from L1 (and signal peers) |
| `stats/1`, `stop/1` | table metrics / shutdown |

The L2 frame is `<<version::binary-14, value::binary>>`: the value with its
version prepended, so a reader can compare versions without unpacking the value.

## Coherence — `EchoStore.Coherence`

Cross-node cache coherence rides EchoMQ. The ordering rule is the point: a version
is a branded id, and `newer?/2` compares **only the 11-byte payload body** — the
snowflake — so "which write wins" is a string compare of the time-ordered part,
namespace bytes skipped.

| Function | Purpose |
|---|---|
| `newer?/2` | is version A newer than B? (compare the 11-byte body) |
| `channel/1`, `queue/1` | the per-table pub/sub channel and coherence queue names |
| `payload/2`, `parse/1` | encode / decode an `{id, version}` notice |
| `broadcast/4` | publish a coherence notice for peers to apply |
| `enqueue/5` | durably enqueue a coherence notice on a group |
| `drop_l2/4` | evict the L2 entry for a stale `{id, version}` |

## The coherence ring — `EchoStore.Ring`

A single-producer ring that batches coherence work (`publish/2`, `occupancy/1`,
`stats/1`) so a burst of writes collapses into batched notices rather than a
message per write.

## Durable intent — `EchoStore.Journal`

An append-only intent log that makes "write, then enqueue" crash-safe: record the
intent (`record/4`, `record_many/2`), enqueue, mark enqueued (`mark_enqueued/2`),
and `replay/2` on recovery so nothing is lost between the write and the queue.
`last_applied/2` and `apply_and_remember/4` give idempotent application; `compact/1`
trims the log.

## Graft — the native-BEAM replication engine

`EchoStore.Graft` and its submodules are a from-scratch, dependency-light volume
replication engine that runs entirely on the BEAM:

| Module | Role |
|---|---|
| `Graft.VolumeServer` | the single-writer per volume; OCC commit |
| `Graft.Store` | the on-disk page store (CubDB-backed) |
| `Graft.PageSet` | a commit's changed pages, delta-encoded (varint) |
| `Graft.Segment` | framed, compressed (zlib) commit segments |
| `Graft.Reader` | lock-free readers over committed pages |
| `Graft.Streamer` | per-volume uploader to the remote |
| `Graft.Remote` / `Graft.Remote.Tigris` | the S3-compatible remote (Tigris) over SigV4 |
| `Graft.Sync`, `Graft.Supervisor` | replication coordination and supervision |

A single writer takes the commit; the page set is the delta; segments stream to
Tigris; readers never block on the writer. No external replication daemon — the
engine is BEAM code over `:crypto`/`:httpc`.

## Why the versions are pinned

The keyspace memory figures (what a `SET` costs at 14 vs 16 bytes, what a `SADD`
member costs by length) come from Valkey's own allocator accounting on the bundled
jemalloc; the L1 sort/scan timings are JIT timings. The bench pins both so a
`.out` figure regenerates.

## Where Codemojex uses it

Codemojex's `Cache` reads a round (with its secret) and an emoji set through
`EchoStore.Table` L1, falling back to Postgres on a miss. Both are immutable for a
round's life, so they cache under the round's own version and never go stale — the
hot scoring path never touches the database for the secret.
