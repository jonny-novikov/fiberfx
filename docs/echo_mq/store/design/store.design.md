# EchoStore — module architecture, the rename, the Shadow ruling, and guidance for Venus and Mars

> The cache app grew an engine: a native Graft replication layer on CubDB, streamed to Tigris S3, with the
> SQLite journal demoted to a local working set. `EchoCache` no longer names what the app is, so it is renamed
> `EchoStore`. This records the module architecture, the actionable rename, the settled Shadow decision (retire
> it), the one dev↔prod transparency knob, and then splits the rest into what Venus surfaces and what Mars
> executes. Tigris and Graft facts are verified at source and cited; the engine is written-to-fit but not yet
> compiled, and that is flagged where it bites. NO-INVENT holds.

## 0 · The module architecture

The app is now three concerns stacked on the bus, not one cache. Bottom to top:

```text
┌──────────────────────────────────────────────────────────────────────┐
│ echo_store  (the data plane: cache + journal + replication engine)     │
│                                                                        │
│  L1 cache            EchoStore.Table        ETS :public read_concurrency│
│  directory           EchoStore              named-table registry        │
│  local journal       EchoStore.Journal      SQLite/exqlite, WAL (local) │
│  coherence/keyspace  EchoStore.Coherence / .Keyspace / .Ring            │
│                                                                        │
│  Graft engine        EchoStore.Graft                 (facade)           │
│    single writer       .Graft.VolumeServer   mailbox = global write lock│
│    durable store       .Graft.Store          CubDB immutable B-tree     │
│    lock-free reads     .Graft.Reader         L1 → CubDB → lazy fetch     │
│    real-time stream    .Graft.Streamer       → Tigris, backoff, resume   │
│    bus notices         .Graft.Sync           EchoMQ PUBLISH/SUBSCRIBE    │
│    remote contract     .Graft.Remote         behaviour                  │
│    remote impl         .Graft.Remote.Tigris  S3 object layout + CAS      │
│  S3 client           EchoStore.Tigris        native SigV4 on :crypto/:httpc│
└───────────────┬───────────────────────────────────┬────────────────────┘
                │ depends on                          │ depends on
┌───────────────▼─────────────────────┐   ┌───────────▼────────────────────┐
│ echo_data  (the data model / BCS)    │   │ echo_wire  (the bus, untouched) │
│  EchoData.BrandedId, .Bcs, Snowflake │   │  EchoMQ.Connector / .RESP /     │
│  EchoData.Graft.{Id, PageSet,        │   │  .Script — deps-free by design  │
│    Commit, Snapshot, SyncPoint,      │   │  (Graft's transport, unchanged) │
│    Segment}                          │   └─────────────────────────────────┘
└──────────────────────────────────────┘
```

The split is the reason the rename is clean. `echo_data` is the **data model** — branded ids and the Graft
structs, pure data, no processes; it depends on nothing above it. `echo_store` is the **data plane** — the
cache, the journal, and the Graft engine that turns those structs into replicated state. `echo_wire` is the
**transport**, dependency-free, used at runtime and never imported. `echo_cache` named only the first room of
the first floor; `echo_store` names the floor.

## 1 · The rename — actionable

`EchoCache → EchoStore`, `echo_cache → echo_store`. A pure mechanical rename: no semantics change, only
names, consistently. The procedure that was run on the two delivered apps, and the steps to finish it
umbrella-wide.

Structural moves:

```bash
cd apps
git mv echo_cache echo_store
git mv echo_store/lib/echo_cache echo_store/lib/echo_store
git mv echo_store/lib/echo_store/echo_cache.ex echo_store/lib/echo_store/echo_store.ex
```

Content rewrite across every app (module, app atom, and string forms in one pass):

```bash
find apps -type f \( -name '*.ex' -o -name '*.exs' \) -print0 \
  | xargs -0 sed -i 's/EchoCache/EchoStore/g; s/echo_cache/echo_store/g'
```

Verification — the tree must hold zero residue:

```bash
grep -rn 'EchoCache\|echo_cache' apps --include='*.ex' --include='*.exs'   # expect nothing
grep -n 'app: :echo_store' apps/echo_store/mix.exs                         # expect a hit
```

What lives outside this tree and must be checked in the real repo, because the two-app deliverable cannot
see it:

- **`config/`** — `Application.get_env(:echo_cache, …)` and any `config :echo_cache, …` keys become
  `:echo_store`. (None were present in the umbrella config seen here; `runtime.exs` is the likely home in
  production.)
- **Sibling consumers** — `apps/codemojex` references the namespace; the `sed` above already rewrote it, but
  any app added since must be re-grepped. No sibling declares `{:echo_cache, in_umbrella: true}` in its deps
  today, so there is no dep edge to update beyond the namespace.
- **Release & ops** — `mix.exs` release definitions, `Dockerfile`/`fly.toml` env names, the `_build` and
  `deps` caches (`rm -rf _build deps && mix deps.get`), and any observability dashboards keyed on the old
  process or ETS-table names (`EchoCache.Graft.Registry` → `EchoStore.Graft.Registry`). Branded-id and L1
  *data* names are unaffected: the L1 table name defaults to the Volume's `VOL` GID, not the app name.

Rollback is the same `sed` with the arguments swapped, plus the inverse `git mv` — which is why the rename is
low-risk to land early.

## 2 · The Shadow ruling — retire it

> **RULED —** The `EchoStore.Shadow` behaviour and its `Copy` implementation are retired. Durable, replicated
> state is the Graft engine streamed to Tigris; the SQLite journal is demoted to a rebuildable local working
> set that needs no replica of its own.

Three facts forced it. First, Shadow's production role — an object-storage replica of the journal — was the
Litestream sidecar, already removed; the engine now replicates pages natively. Second, the journal's contents
are rebuildable: the moduledoc already notes that on recovery the bus's own admission dedup absorbs the job
ids the journal would have replayed, so a lost journal reconstructs rather than corrupts. Third, and
decisively, a second durability mechanism is the opposite of the transparency this change is for: one path,
gated by one knob (§3), is legible; two paths are not. Recon confirmed Shadow had no production caller — only
its own two test files — so retirement deleted `shadow.ex`, `shadow/copy.ex`, and both tests, with no
supervision or restore-path edits.

What is given up: the local `VACUUM INTO` snapshot convenience `Copy` provided. It is not missed — a developer
who wants a point-in-time journal copy runs `VACUUM INTO` as a one-liner, which does not warrant a supervised
behaviour. **Mars may overturn this** on one condition: if the journal is ever deemed *not* rebuildable (it
holds state the bus cannot re-derive), then `Copy` returns as a local-only restore path. That condition is a
Venus surface (§4), not a foregone conclusion.

## 3 · Dev↔prod transparency — one knob

The same code runs in both environments. The only difference is the value of `remote_cfg` passed to
`EchoStore.Graft.open_volume/2`. When it is `nil`, the `VolumeServer` starts no `Streamer`; commits land in
CubDB and the L1 and go no further. When it is a Tigris config, the `Streamer` runs and ships every commit.
Nothing else in the call path branches on environment.

| Dimension | Dev box (`remote_cfg: nil`) | Production (`remote_cfg: Tigris`) |
| --- | --- | --- |
| Streamer | not started | one per Volume, real-time upload |
| Durability | local CubDB + journal | local CubDB + Tigris S3 |
| Replication | none — single box | Graft segments + conditional commits on Tigris |
| Network | none | Tigris S3 over HTTPS (SigV4) |
| Reads | L1 → CubDB | L1 → CubDB → lazy fetch from Tigris |
| Bus notices | published only if a connector is wired | published after each upload |
| Code path | identical | identical |

Production config is read straight from Fly's injected secrets — `EchoStore.Tigris.config/1` falls back to
`AWS_ENDPOINT_URL_S3`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `BUCKET_NAME`. A dev box that sets none of
these and passes `remote_cfg: nil` is fully functional offline. Transparency is therefore not a feature added
on top; it is the absence of an environment branch.

## 4 · Guidance for Venus — what to surface, not decide

The engine is wired; several real forks remain open. Venus surfaces them with the four-part arms when Mars
calls for a ruling; none should be silently resolved in code.

- **Segment key layout.** Segments are stored globally at `segments/{SEG}`. Per-Volume prefixing,
  `logs/{VOL}/segments/{SEG}`, makes lifecycle and garbage collection scope to a Volume — at the cost of a
  longer key and losing cross-Volume dedup. A fork to surface, with GC as the deciding lens.
- **One writer, or many.** Tigris conditional writes give a real compare-and-set: the commit object is PUT
  create-only with `If-None-Match: "*"` and `X-Tigris-Consistent: true`, returning 412 when the LSN slot is
  taken (graft.rs's conditional commit, Tigris's documented behaviour). The per-Volume `VolumeServer` already
  serializes locally, so today the CAS is only a safety net. Whether to allow several nodes to write one
  Volume — letting the object store be the serializer — is a topology decision Venus should frame against the
  consistency the mesh wants, not enable by default.
- **The journal's future.** With Shadow gone and CubDB present, the SQLite journal (exqlite) is the last
  C-backed store in `echo_store`. Folding the intents table into CubDB would retire exqlite entirely and
  align with the journal-isolation direction — but it is a migration with its own risk surface, and the
  journal's rebuildability (the basis of §2) is exactly the question to test first.
- **The page-set substrate.** `EchoData.Graft.PageSet` is a pure-Elixir delta-varint set standing in for
  `splinter-rs`. The crossover where a Roaring-style bitmap or a Rustler binding earns the native-code cost is
  a measurement Venus should ask for before it is assumed.
- **Pull cadence.** Notices ride EchoMQ; the durable bytes ride Tigris. The replica pull path today is
  notice-driven with a `list_commits` fallback. Whether to add Tigris/Fly bucket notifications, or a periodic
  reconciliation sweep, is an availability fork.
- **SigV4 assurance.** The signer is `:crypto`-on-`:httpc`, dependency-free, but unproven here. A known-answer
  test against AWS's documented SigV4 vectors, and a decision on `:httpc` versus a pooled client (Finch) for
  production throughput, are surfaces — not yet rulings.

## 5 · Guidance for Mars — the execution playbook

Ordered, concrete, reversible.

1. **Land the rename.** Run the moves and the `sed` in §1, then `rm -rf _build deps && mix deps.get && mix
   compile`. The compile is the first real proof — this code has not been compiled in this environment, so
   expect to fix what only `mix compile` can find (the Graft engine fits the verified APIs of CubDB v2,
   `EchoStore.Table`, `EchoMQ.Connector`, and `EchoData.BrandedId`, but fit is not the same as compiled).
2. **Run the suite.** `mix test`. The retired Shadow tests are gone; nothing should reference them.
3. **Wire dev.** Open Volumes with `remote_cfg: nil`. Confirm a write→read round-trips against CubDB and the
   L1 with no network. This is the transparency baseline.
4. **Provision Tigris.** `fly storage create` injects `AWS_ENDPOINT_URL_S3`, `AWS_ACCESS_KEY_ID`,
   `AWS_SECRET_ACCESS_KEY`, `BUCKET_NAME`. The S3 endpoint is `https://t3.storage.dev` from outside Fly and
   `https://fly.storage.tigris.dev` from within; the SigV4 region is `auto`.
5. **Prove the signer before prod.** Add the SigV4 known-answer test (§4) and a single live round-trip:
   `EchoStore.Tigris.put_object/4` then `get_object/3` against the bucket. Do not ship the signer on fit
   alone.
6. **Wire prod.** Open Volumes with `remote_cfg: EchoStore.Tigris.config()`. Verify a commit appears as a
   `logs/{VOL}/commits/{LSN}` object and that a second node lazily fetches a `segments/{SEG}` frame on first
   read.
7. **Set lifecycle.** Decide segment GC scope (the §4 layout fork) before the bucket accumulates dead
   segments; Tigris lifecycle rules or a `Streamer`-adjacent sweep.
8. **Rollback.** The rename reverses with the swapped `sed` and inverse `git mv`; the Tigris path reverts by
   passing `remote_cfg: nil` — the dev configuration is also the kill switch.

## 6 · References

- [graft.rs/docs/internals](https://graft.rs/docs/internals/) — the transaction model, the conditional commit,
  the segment/snapshot/SyncPoint model the engine mirrors.
- [hexdocs.pm/cubdb](https://hexdocs.pm/cubdb/CubDB.html) — the append-only immutable B-tree, zero-cost MVCC
  snapshots, and ACID transactions behind `EchoStore.Graft.Store`.
- [Tigris — S3 compatibility](https://www.tigrisdata.com/docs/api/s3/) and
  [conditional operations](https://www.tigrisdata.com/docs/objects/conditionals/) — SigV4, the global
  endpoints, `If-None-Match: "*"` create-only with `X-Tigris-Consistent: true`, and the 412 on a taken key.
- In this repository: `graft-topology.design.md` (the model this engine realizes) and
  `journal-isolation.design.md` (the SQLite-isolation direction the journal's future in §4 continues).
