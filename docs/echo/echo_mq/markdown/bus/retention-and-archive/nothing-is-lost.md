# Nothing is lost — the Bus, module 05, dive 02

> Route: `/echomq/bus/retention-and-archive/nothing-is-lost`. Surface: `EchoStore.StreamArchive.fold/3` (+
> `merge_read/5`, `archive_frontier/1`) and the fold-before-trim ordering of `EchoStore.StreamArchive.Driver`.
> Real `echo/apps/echo_store` code; no Lua (the fold is `EchoStore.Graft.VolumeServer.commit/3`, not Lua).

## The frame

`XTRIM` returns only a removed **count** — never the deleted entries. So there is no recovery after a trim:
once a record is trimmed off the live stream, the stream cannot hand it back. That single fact makes the
no-loss guarantee rest on **ordering**: a record is removed from the live stream **only after** it is
committed to the durable floor and the watermark has advanced past it. Fold first, trim second. Get the order
wrong and a trim could delete a record the fold never captured — gone, with only a count to remember it by.

## The fold — `EchoStore.StreamArchive.fold/3`

`EchoStore.StreamArchive.fold(volume_id, slice, db)` folds a mint-ordered `{branded, fields}` slice into the
native `EchoStore.Graft` engine's CubDB — **one page per record** — through the **public**
`EchoStore.Graft.VolumeServer.commit/3`. The engine internals are untouched: the archive is a new consumer of
the public commit surface, not an edit to it. It returns `{:ok, W}` (the new frontier), `:noop` for an empty
slice, or the engine's `{:error, term}` verbatim (on any fold error the caller does **not** trim — the safe
direction).

## The reserved page range — `2^49`, disjoint by construction

The Graft engine multiplexes one page axis: a business write commits its pages at **low** indices, a page per
table row counting up from 0. The archive must never overwrite one of those, so each folded record lands in a
reserved **high** range:

    @archive_base = :erlang.bsl(1, 49)   # 2^49

`2^49` sits ~563 trillion indices above the business-page floor. A forward `:arc_seq` allocator — which counts
the archive's page index up from 0 — can never reach a business page, so the archive range `[2^49, ∞)` is
**disjoint from where real commits land by construction**. No archive page index can ever overwrite a data
page; the disjointness is proven by the arithmetic, not enforced by a check.

## The page axis is branded-id-monotone — the order theorem reaching disk

Records fold in **mint order**: the writer mints monotone `EVT` ids, and `EchoMQ.Stream.read/6` returns the
slice in mint order (the order theorem of the stream-log module). So the page axis `@archive_base + 0, +1, …`
is **branded-id-monotone** — a forward scan reads the archive oldest-first, a reverse scan newest-first, with
**no second index**. The order theorem that held in memory now holds on disk: the page index *is* the sort.
Each page payload is `{branded, fields}` — the 14-byte branded `EVT` receipt a polyglot reader recovers
without re-encoding, plus its claims-only fields.

## The watermark `W` — a branded id, never `head_lsn`

`W` is the branded `EVT` id of the **highest-folded record**, persisted under `:arc_frontier` and read by
`archive_frontier/1`. It is **not** the engine's integer `head_lsn` — that is the engine's page cursor (it
addresses pages), the wrong type to compare against a live-tail `EVT` id. `W` is the seam: everything with a
branded id ≤ `W` is in the archive; everything with a branded id > `W` is still on the live stream.

## The merge-read — `merge_read/5`, split on `W`

`merge_read/5` reads **archived ∪ live-tail** for a stream, split on `W`: records with branded id ≤ `W` come
from the engine's `@archive_base` range; records with branded id > `W` come from the live stream via
`EchoMQ.Stream.read/6` (the `XRANGE` lower bound is `W`'s xadd id, exclusive). The union is in mint order —
the archive is oldest-first, the live tail follows. When `W` is `:empty` (nothing folded), the whole stream
is read live; there is no archive seam. **No-gap/no-overlap is a consequence** of fold-before-trim + the
order theorem — never a per-read boundary check. The page index sorts the archive; the watermark splits the
seam; the read is two ordered halves concatenated.

## Fold-before-trim — the no-loss ordering

The cycle that bounds an **archived** stream lives in one process, `EchoStore.StreamArchive.Driver`, which
owns **both** calls so the ordering cannot be violated. On each beat, per archived stream:

1. read the about-to-trim slice `(W, floor]` from the live stream via `EchoMQ.Stream.read/6`;
2. `EchoStore.StreamArchive.fold/3` it into the engine and advance `W` to the highest-folded id;
3. cache `W` to the bus seam `emq:{q}:stream:<name>:archived` via `EchoMQ.Stream.put_archived/4` (a polyglot
   reader's seam, **never** the source of truth — `archive_frontier/1` is);
4. **only then** `EchoMQ.Stream.trim/4` the now-archived span.

If the fold fails — a wire fault on the read, an engine conflict — the cycle **aborts before the trim**: the
slice stays on the live stream (over-retention, never loss), and the next beat retries. The bare
`EchoMQ.StreamRetention` trim-only driver must **not** also run on an archived stream — it would trim before
the fold and lose the slice — so for an archived stream this driver **is** the retention path, trimming to the
same declared windows after folding. Bounded memory and deep history coexist with no loss.

## The wire-side seam cache

The watermark is cached on the wire by `EchoMQ.Stream.put_archived/4` / `get_archived/3` under
`emq:{q}:stream:<name>:archived`. A non-BEAM reader discovers where the archive ends and the live tail begins
**without a store call** — but it is a polyglot **cache** of the seam, never the source of truth. The
store-side `archive_frontier/1` is the truth; the wire seam is overwritten on each fold and deleted when the
stream is obliterated.

## Pattern & implementation

- **The pattern (Redis Patterns Applied).** A retained log needs deep history that outlives the resident
  window; archive the trimmed segments to durable storage and read them beside the live tail.
  [Streams & Events](/redis-patterns/streams-events) teaches event sourcing over a retained log.
- **The implementation (echo_store).** `EchoStore.StreamArchive.fold/3` folds the trimmed slice into the
  Graft engine at a reserved `2^49` page range, branded-id-monotone, through the public
  `VolumeServer.commit/3`; the watermark `W` (a branded id, never `head_lsn`) splits the `merge_read/5`; and
  fold-before-trim is the no-loss ordering, no-gap/no-overlap a consequence of it.

## Recap

What is trimmed is folded first. The fold lands one page per record at a reserved `2^49` range, disjoint from
business pages by construction and branded-id-monotone — the order theorem on disk. The watermark `W` (a
branded `EVT` id, never the engine's `head_lsn`) splits the merge-read: archive below, live tail above, one
mint-ordered stream. Fold-before-trim is the no-loss ordering, and no-gap/no-overlap follows from it. The
deep history is on the floor; the next dive is the floor itself, and the dial that turns it.

## References

### Sources
- [orbitinghail — Graft](https://github.com/orbitinghail/graft) — the lazy, partial, page-replication engine `echo_store` builds natively on the BEAM, that the archive folds into.
- [Ong — CubDB](https://hexdocs.pm/cubdb/CubDB.html) — the append-only immutable B-tree the fold commits the archive pages onto.
- [Valkey — XTRIM](https://valkey.io/commands/xtrim/) — the count-only trim that makes fold-before-trim the sole defense against loss.
- [Kreps — The Log](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying) — the log whose offset/cursor the watermark `W` plays for the archive seam.

### Related in this course
- [Retention & the archive](/echomq/bus/retention-and-archive) — the module this dive belongs to.
- [Retention is a policy](/echomq/bus/retention-and-archive/retention-is-a-policy) — the trim the fold runs before.
- [The door to persistence](/echomq/bus/retention-and-archive/the-door-to-persistence) — the durable floor in depth.
- [The order theorem](/echomq/bus/the-stream-log/the-order-theorem) — the mint order this fold carries to disk.
- [Echo Persistence](/echo-persistence) — the durable floor the fold writes into.
- [The Branded Component System · the persistence floor](/bcs/persistence) — the manuscript chapter this fold realizes.
