# Codemojex · Roadmap: a branded-native bitmapist on its own Fly machine

<show-structure depth="2"/>

The earlier plan put bitmapist-server beside Valkey. This revision moves it onto its own minimal Fly machine and replaces the Python client with a Go port, so the codemojex-dashboard connects to it directly and speaks branded ids natively. The store stays Doist's bitmapist-server, whose roaring bitmaps make the branded-id offsets cheap; the client becomes a small Go library that resolves a branded id to its offset with the same codec the Echo umbrella already ships. The Go port is written and tested — this document is the roadmap to deploy and wire it. As the project's decision of record, the playable entity is a **game** (`GAM`) inside a room (`RMM`), superseding the earlier `round`/`RND`.

## What changed from the co-located plan

Three things move. First, **bitmapist-server runs as a separate Fly app**, not a sidecar on the two-vCPU Valkey host, so its memory-mapped database and its restarts are isolated from the money game entirely, and the analytics machine is sized and scaled on its own terms. Second, **the client is Go, not Python** — a port of bitmapist4's cohort model — because the dashboard and the marker are Go, and one implementation in the stack's own language is cleaner than running a Python runtime for the read side. Third, the client is **branded-native**: its API takes `USR…` and `RMM…` ids and resolves the offset internally, so nothing upstream handles raw integers.

## The store and why roaring still earns its place

bitmapist-server keeps each bitmap as a roaring structure and holds only the hot set in memory [2]. The published result is a dataset that needed about 129 gigabytes on Redis fitting in roughly 300 megabytes on the server, a 443-fold reduction [2][3]. It is a single Go binary with the flags that matter here: `-addr` to listen, `-db` for the memory-mapped database file, and `-bak` for a consistent snapshot on a signal [2]. It speaks the Redis protocol, which is what lets a Go client talk to it.

Roaring matters because the branded offset is sparse. A plain Valkey bitmap grows to the size of its largest offset — set the bit for id eight million and Redis allocates a megabyte to hold one bit [4] — and the Codemojex offset can land anywhere in the 32-bit range. Roaring stores 32-bit integers in two-level containers, dense ranges as bitmaps and sparse ranges as packed 16-bit arrays, so scattered high offsets cost on the order of sixteen bits each [5]. That is the whole reason the offset can be a hash of the branded id with no dense-ordinal remapping.

## The branded offset, ported and proven

The offset is the in-repo hash applied to the decoded snowflake. The Echo umbrella owns this contract in three places that must agree — the Rust NIF `branded_id.rs`, the C ABI `branded_id.h`, and the pure module `EchoData.BrandedId` — and the Go port carries the same algorithms and the same contract vectors. Encoding `USR` over snowflake `274557032793636864` yields `USR0KHTOWnGLuC`; the trie hash of that snowflake is `234878118`; and that hash is the bit offset. The port's tests assert these vectors and a million-iteration round-trip, so a Go caller derives the offset the BEAM would.

Two properties of that hash shape what the dashboard can ask, and both come straight from the source rather than guesswork. The hash is the first half of MurmurHash3's fmix64 truncated to 32 bits, so it is **one-way**: an offset does not reveal its branded id. Marking and membership work from a branded id forward, but listing the members of a cohort as branded ids needs a separate offset-to-id index, because the hash cannot be run backward. The hash is also **collision-bearing** in the 32-bit space, so distinct counts undercount by the collision rate — on the order of `N squared over two to the thirty-third` colliding pairs at `N` users, which stays under a tenth of a percent into the millions, but is a property to record, not wave away. For the questions Codemojex asks — how many were active, how many converted — this is well within tolerance; for a per-user audit trail it is not, and that path keeps a side index.

## The Go client, rewritten from Python

The client is a port of bitmapist4's model. It keeps the library's key conventions — the `bitmapist_` prefix and the dated sibling keys for day, week, month, and year, with hourly off as bitmapist4 defaults [6][7] — so the data is wire-compatible with bitmapist-server's tooling and with a Python reader, should one ever run beside it. Its surface is the cohort vocabulary: mark an event for a user, mark a date-independent flag, test membership, count a period, intersect or union or difference a set of event keys, and read a retention row. Every entry point takes a branded id and runs it through the codec; the cohort math sits over a small store interface, which is what let the intersection, funnel, and retention logic be unit-tested without a server. The set operations write a temporary result key and delete it after counting, so cohort scratch does not linger — the same discipline the rest of the system follows.

## The transport detail that bites

bitmapist-server implements a subset of the Redis protocol on a minimal RESP server and does not negotiate RESP3. A client that mandates a `HELLO 3` handshake fails against it. The dashboard therefore reaches bitmapist-server through a plain RESP client — redigo — that issues exactly the commands given, while keeping its richer Valkey client for the actual Valkey instance. This is a deliberate split, noted here because the failure mode is a confusing handshake error rather than a clear one.

## The event model and what it answers

A mark sets one bit at the user's offset in the day, week, month, and year bitmaps for an event, plus the bare event key. The events map onto hooks the game already has: registered at wallet creation, active on any command or guess, played on game entry, guessed on a charged guess, won in the score worker, paid on a key purchase, converted on a diamond exchange. With those in place the questions are bit operations — daily, weekly, and monthly actives are counts; retention is a cohort key intersected with each later period and counted, the cohort model bitmapist established carried over the same bit operations [1][8]; a funnel is registered intersected with played intersected with paid; a revenue cohort is paid intersected with active; per-room engagement is a played-in-room bitmap per `RMM`.

## Who marks

The dashboard is the reader. Marking is a separate concern, and the same Go client serves it: a small marker consumes the events the game already emits and records them, so there is one bitmapist implementation in the stack. The Elixir game stays the source of events and needs no port of its own; it hands events to the Go marker over the channel it already publishes on. An alternative keeps marking in Elixir by writing the same key convention directly, which avoids a marker process at the cost of a second implementation of the conventions — the roadmap prefers the single Go client.

## Deployment

bitmapist-server ships as its own Fly app. The image builds the binary from source and runs it bound to the private network on port 6400, with the database on a mounted volume and `-bak` wired for snapshots. The app has no public services: it is reached only at its `internal` address from apps in the same organization, which is the same trust boundary as the Valkey node, since bitmapist-server has no authentication of its own. It is sized small — a `shared-cpu-1x` with a few hundred megabytes, because the hot set at Codemojex scale is a few megabytes — and kept always-on rather than scaled to zero, since it is stateful behind a memory-mapped file. The Dockerfile and the `fly.toml` are part of the delivery.

## The roadmap

- **P0 — The bitmapist app.** Build the image, create the volume, deploy the private Fly app on 6400, confirm `info keys` answers and the database survives a restart and a `-bak` snapshot. Exit: a private, durable analytics store reachable at its internal address.
- **P1 — Confirm the offset in place.** The Go codec is ported and vector-tested; in P1 it is vendored into the dashboard and the marker, and the collision bound is recorded against the real id population as a decision of record. Exit: one offset function, shared, with a known error bound.
- **P2 — The marker.** Stand up the Go marker on the events the game emits, marking registered, active, played, guessed, won, paid, and converted through the client. Exit: events appear as bits, verified by count and `info keys`.
- **P3 — The dashboard read path.** Wire the dashboard to bitmapist-server through the redigo store and render actives, a retention curve, and the funnel. Exit: live cohort, retention, and funnel views speaking branded ids.
- **P4 — Drill-down with a side index.** Where a view needs the actual users behind a count, add an offset-to-id index so the one-way hash can be resolved. Exit: cohort membership resolvable to branded ids where the product needs it.
- **P5 — Durability and operations.** Snapshot the database on signal to the volume and onward to object storage, drill a restore, and watch the machine's small footprint over time. Exit: a tested backup and restore.

## Risks and decisions

The offset is one-way and collision-bearing; the roadmap accepts that for counts and adds a side index only where membership must be resolved, rather than fighting the hash. The store has no authentication, so its safety rests entirely on staying private to the 6PN network — no public service block, ever. The transport must be a plain RESP client, since bitmapist-server does not speak RESP3, and choosing otherwise produces an opaque handshake failure. The store is stateful behind one memory-mapped file on one volume, so its backup is part of the work, not an afterthought. And the schema and the game still name the entity `rounds` pending the `GAM` rename.

## References

1. bitmapist — analytics and cohort library on Redis bitmaps (event-period model, ids in [0, 2^32)): [github.com/Doist/bitmapist](https://github.com/Doist/bitmapist)
2. bitmapist-server — memory-efficient standalone store (roaring bitmaps, hot-set caching, the `-addr`/`-db`/`-bak` flags, the memory-mapped database, the Redis-protocol surface): [github.com/Doist/bitmapist-server](https://github.com/Doist/bitmapist-server)
3. Doist Engineering — bitmapist in production (130GB to 300MB, 443x, cohort visualization): [doist.dev/bitmapist](https://www.doist.dev/bitmapist/)
4. Vikram Oberoi — retention analyses with bitmaps (the eight-million-id megabyte, sparse-bitmap memory, the roaring fix): [vikramoberoi.com](https://vikramoberoi.com/posts/using-bitmaps-to-run-interactive-retention-analyses-over-billions-of-events-for-less-than-100-mo/)
5. Roaring bitmaps — a primer (32-bit integers, two-level containers, dense versus sparse): [machine-learning-made-simple.medium.com](https://machine-learning-made-simple.medium.com/an-introduction-to-roaring-bitmaps-for-software-engineers-dd98859dd29a)
6. bitmapist4 — the library this client ports (hourly binning off by default, unique events, pipelined transactions, the `bitmapist_` key prefix): [github.com/Doist/bitmapist4](https://github.com/Doist/bitmapist4)
7. Using bitmapist for analytics — worked example (the dated-sibling keys a mark writes, the build): [dev.to](https://dev.to/tmns/using-bitmapist-for-super-fast-analytics-3e9i)
8. Redis bitmaps for analytics — command semantics (SETBIT, BITCOUNT, BITOP, the 2^32 addressable bits): [oneuptime.com](https://oneuptime.com/blog/post/2026-01-21-redis-bitmaps-analytics/view)
