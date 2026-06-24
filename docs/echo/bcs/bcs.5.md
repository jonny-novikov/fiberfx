# BCS · B5 — The Persistence Floor
<show-structure depth="2"/>

B5 is the persistence floor: `EchoStore.Graft`, a native-BEAM build of Graft's idea — lazy, partial, strongly consistent, page-based replication on object storage. Three dives carry it — the single-writer engine on CubDB, the lazy and partial reader at a snapshot, and the portable remote with its commit-LSN cursor and the stream archive. The chapter is served at `/bcs/persistence`; its dives at `/bcs/persistence/the-engine`, `/bcs/persistence/the-lazy-reader`, and `/bcs/persistence/the-remote`.

B5 is the persistence floor: `EchoStore.Graft`, a native-BEAM build of Graft's idea — lazy, partial, strongly consistent, page-based replication on object storage, with no foreign engine. A volume is a single-writer process whose mailbox is the global write lock; its store is CubDB's append-only immutable B-tree, where a snapshot costs nothing; its L1 is the same `EchoStore.Table` that fronts the cache, used here as the write-through head page. A reader fetches only the pages a read touches; `Graft.Streamer` ships segments to Tigris in real time, the native replacement for Litestream; commit notices ride the bus while the bytes travel via Tigris; and the commit-LSN is the cursor a replica reads from. The stream archive folds trimmed `EchoMQ.Stream` segments into the same floor — deep history without resident memory.

Every surface here is real source under `echo_store` — `graft.ex` and the `graft/` engine, `stream_archive.ex`, and the shared `table.ex`. Where a figure would carry a size or rate, it rides a committed benchmark output and appears only once that output is in the tree; no engine number is cited that the tree does not assert.

## B5.1 · The single-writer engine

The floor begins with a volume, and a volume has exactly one writer. `EchoStore.Graft.VolumeServer` is one process per volume, and its mailbox is Graft's global write lock: every commit to that volume passes through one GenServer, serialized by the BEAM's mailbox, so there is no lock to acquire and no contention to lose. A write begins, stages its pages, and commits; the pages of one business write land at low indices, a page per table row counting up from zero.

The store beneath the writer is CubDB, an append-only immutable B-tree. Entries are never changed in place; a write appends, and a read takes a zero-cost immutable snapshot, so concurrent reads neither block writes nor are blocked by them. A Graft snapshot is a CubDB snapshot — the same structure gives the engine its consistency and the reader its isolation, and it is pure Elixir, with no C extension to build or trust.

Identity runs through the engine as it runs through the rest of BCS. A volume, a segment, and a commit each carry a branded GID — `VOL`, `SEG`, `CMT` — minted from the same Snowflake the cache and the bus use, so a commit sorts by when it happened and a segment names itself on the wire. The engine is single-writer where it must be and immutable where it can be; the rest of the floor is what that one commit becomes once it leaves the node.

## B5.2 · The lazy reader

Replication here is lazy and partial, the two words that separate this floor from a backup. A reader does not replay a log or wait for a full file to land; it fetches only the pages a read touches, on demand, at a chosen snapshot. Decoupled metadata and data let a replica spin up at once — it learns which pages exist without holding them, and pulls a page the moment a read asks for it.

The hottest page is already in memory. The reader's L1 is `EchoStore.Table`, the same read-concurrent ETS cache that fronts Part IV, used here as a write-through head page: a commit writes the head page through to ETS, and a read of the newest page is a caller-side lookup that never touches disk or the remote. The cache and the floor share one structure, so the tier that makes reads fast is the tier that keeps the engine's head durable.

Consistency is not traded away for laziness. Reads run at a snapshot with serializable isolation, so a partial view is still a correct one — a reader sees a single point in time across every page it pulls, never a mix of an old page and a new one. The floor fetches little and late, and what it returns is exactly what a full, eager replica would have returned, only without the bytes in between.

## B5.3 · The portable remote

The durable copy lives in object storage, and a streamer keeps it current. `EchoStore.Graft.Streamer` ships segments and conditional commit objects to Tigris in real time — the native replacement for Litestream, which streamed SQLite's write-ahead pages to S3 the same way. Object storage becomes a transactional remote because the commit object is written conditionally: two writers that share a destination cannot overwrite each other, so the remote is safe without a coordinator.

The bus and the bytes travel separately. `EchoStore.Graft.Sync` sends a low-latency commit notice over `EchoMQ.Connector` — a small message that a new commit exists — while the pages themselves move through Tigris. A replica reads the notice, learns the new commit-LSN, and pulls the pages it needs; the commit-LSN is the cursor, the offset on the log that tells a reader how far it has caught up. The same idea ports: the Rust `echo_graft` pairs Fjall with OpenDAL, a different engine and a portable remote, for hosts that do not run the BEAM.

Deep history lands on the same floor. When EchoMQ trims a stream, `EchoStore.StreamArchive` folds the trimmed segments into this engine's CubDB at a reserved high page range, far above any business page, and on to Tigris — deep history without resident memory. A reader merges the archived pages with the live tail on an engine-derived watermark, so a stream's past is queryable beside its present, and what a system trims is kept, not lost.

## References

- [orbitinghail — Graft: lazy, partial, strongly consistent replication](https://github.com/orbitinghail/graft) — the page-replication engine echo_store builds natively on the BEAM.
- [Ong — CubDB, an Elixir embedded key-value store](https://hexdocs.pm/cubdb/CubDB.html) — the append-only immutable B-tree the volume commits onto.
- [Thompson et al. — The LMAX Disruptor (2011)](https://lmax-exchange.github.io/disruptor/disruptor.html) — the single-writer principle the volume server applies to commits.
- [Helland — Life Beyond Distributed Transactions (CIDR 2007)](https://ics.uci.edu/~cs223/papers/cidr07p15.pdf) — entities made durable and addressed across a boundary.
- [Tigris — conditional object operations](https://www.tigrisdata.com/docs/objects/conditionals/) — the conditional commit objects that make object storage a transactional remote.
- [Johnson — Litestream: streaming replication for SQLite](https://litestream.io/how-it-works/) — the WAL-to-object-storage streamer the native Streamer replaces.
- [Kreps — The Log (LinkedIn Engineering)](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying) — the commit log whose offset is the cursor a replica reads from.
