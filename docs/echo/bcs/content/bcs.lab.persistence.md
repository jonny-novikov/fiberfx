# BCS · Lab Note — The Floor Under the Lane: Six Ways to Persist an Intent

<show-structure depth="2"/>

A lab note beside the ladder, not a chapter. Chapter 4.4 shipped the journal and committed its price — 143 microseconds per record-and-mark pair — and Chapter 4.5's referee will hold whole caches to account. Between them sits a narrower question worth answering with instruments rather than taste: what is each of those microseconds buying, and what would the alternatives charge for the same intent? The lab holds the workload constant — the same three 14-byte branded ids per intent, the same record-then-mark shape — and swaps the engine underneath six times: the production journal fused onto a single `RETURNING` statement, the same journal under group commit, a raw append-only file at three sync disciplines, OTP's own `disk_log`, a Rust NIF over the same SQLite, and Tigris S3 measured both as a lane and as a shipping layer. The committed record (`lab/lab_persistence_bench.out`, `LAB PASS 7/7`) prices the spread: `143.5` µs through the production pair, `33.5` per intent in a depth-128 group commit, `3.1` on a buffered append, `4.2` through `disk_log`, `77.5` through one fused NIF call — and a median of `106.7` ms for an intent shipped as its own S3 object, `743` times the local pair, which is the entire argument for local-first written as one number.

## The method, and what it overturned

Every leg states its derivation before its measurement, and the bands were written before the runs. Three of them did not survive contact, and the record keeps all three corrections in the open: the fused statement's expected savings evaporated (the removed statement was never the cost), `disk_log` beat its derived floor (the log owner batches internally), and the S3 segment ceiling had to be re-derived to ride the round trip the per-intent leg measured. A lab that only confirms its derivations was not measuring anything.

The header pins the conditions every figure below inherits: `SQLite 3.46.0 via exqlite (WAL, synchronous=NORMAL) | rusqlite bundled via lane_rs NIF: built | S3 fly.storage.tigris.dev region auto | Elixir 1.14.0 OTP 25 | schedulers 1`.

## Prior art read first: async-sqlite onto the BEAM

The brief named ryanfowler's `async-sqlite` as the shape to study, and its architecture is worth restating precisely because of how familiar it turns out to be: a `Client` is one background SQLite connection on its own thread, fed by a bounded queue, callable concurrently from anywhere; a `Pool` is N of those; rusqlite's `bundled` build is the default underneath [1]. Translated onto the BEAM, the journal already is that design — the owner GenServer is the client's connection thread, the mailbox is the bounded queue, and exqlite's NIFs are dirty-IO scheduled so the blocking lives where blocking belongs. "Async SQLite" is not a library the journal lacks; it is the architecture the journal was built as. What remains measurable is the binding (leg C) and the batching (leg B) — and behind every leg stands the same forty-year-old contract ARIES wrote down: log the intent before the effect, and recovery is a replay of the log [2].

## A — The fused statement: a negative result, kept

SQLite 3.46 accepts `INSERT … RETURNING seq`, collapsing the journal's insert-then-read-rowid into one statement. The patch is small and stayed in production:

```elixir
insert:
  prep.(
    "INSERT INTO intents(job_id, name_id, version, enqueued, recorded_at) " <>
      "VALUES(?,?,?,0,?) RETURNING seq"
  ),
```

with one correctness note that matters more than the optimization: a `RETURNING` statement abandoned after its first row must be stepped to `:done` before the owner replies, so the write is fully applied — `hot_one/3` drains it. The derivation expected the pair to fall toward two thirds of the committed floor. It did not move: `143.5 us per record-and-mark against the committed unfused floor of 143 -- the removed statement was a no-IO rowid read, and the pair's cost lives in the two owner hops and the WAL append, not in statement count: a negative result, kept`. The statement count was never the bill. The pair pays for two GenServer round trips and one WAL append, and removing a read that touched no disk removed nothing. The fusion stays — one statement fewer is one statement fewer — and the regression run of the full 4.4 rung passed `PASS 6/6` with the pair inside its committed band, the frozen record untouched.

## B — Group commit: the 1984 answer still pays

If the WAL append is the bill, amortize it. `record_many/2` landed in the production journal beside the pair — one `BEGIN…COMMIT` around a batch of recorded intents, marks deliberately untouched so the outbox seam stays a seam:

```elixir
def handle_call({:record_many, triples}, _from, s) do
  :ok = Sqlite3.execute(s.db, "BEGIN")
  now = System.os_time(:millisecond)

  seqs =
    Enum.map(triples, fn {job_id, name_id, version} ->
      [seq] = hot_one(s.db, s.stmts.insert, [job_id, name_id, version, now])
      seq
    end)

  :ok = Sqlite3.execute(s.db, "COMMIT")
  {:reply, {:ok, seqs}, s}
end
```

Each depth ran on a fresh journal so no inherited checkpoint pollutes the curve, and the curve behaved: `45.9 us per intent at depth 8, 35.1 at 32, 33.5 at 128 -- monotone with depth, one WAL append shared by the batch`. This is DeWitt's group commit doing in 2026 exactly what it did in 1984 — the commit cost divided by the number of riders [3]. The fit is writers that admit in bursts: a producer draining its own upstream can record thirty intents for the price of one and a half.

## C — The Rust binding, isolated

Leg C builds the async-sqlite shape natively: a `cdylib` crate on rustler and rusqlite `bundled`, every NIF dirty-IO scheduled, loaded straight through `:erlang.load_nif/2` with no mix integration — the lab measures the binding, not the packaging. The fused call is the crate's one-closure-on-the-connection idiom as a single crossing:

```rust
#[rustler::nif(schedule = "DirtyIo")]
fn record_pair(res: ResourceArc<Conn>, job: String, name: String, ver: String, ts: i64) -> NifResult<i64> {
    let conn = res.0.lock().unwrap();
    let seq: i64 = {
        let mut ins = conn.prepare_cached(
            "INSERT INTO intents(job_id,name_id,version,enqueued,recorded_at) \
             VALUES(?,?,?,0,?) RETURNING seq",
        ).map_err(err)?;
        ins.query_row(rusqlite::params![job, name, ver, ts], |r| r.get(0)).map_err(err)?
    };
    let mut mk = conn.prepare_cached("UPDATE intents SET enqueued=1 WHERE job_id=?").map_err(err)?;
    mk.execute(rusqlite::params![job]).map_err(err)?;
    Ok(seq)
}
```

The bench calls the NIF with no owner process in front, so the deltas isolate cleanly: `91.5 us per two-call pair, 77.5 fused in one NIF call, 11.2 per intent at depth 32 in one transaction -- same engine as P1, the deltas are crossings and hops`. The accounting closes to within noise. P1's 143.5 minus C's 91.5 is the two GenServer hops the bench removed. The two-call pair minus the fused call is one NIF crossing. And the batch rows make the same point at depth: the production `record_many` pays three NIF crossings per row (bind, step, drain) where the Rust transaction pays none, and 35.1 minus 11.2 is almost exactly that crossing budget. Nothing here is SQLite being faster in Rust — it is the same SQLite with fewer border checkpoints. The plain production translation: adopting this binding would buy back the crossing tax at the price of a per-platform `.so` in the build, and the journal's owner hops — the larger share — would remain, because the owner is the design, not overhead.

## D — `disk_log`: OTP's own WAL

The runtime ships a write-ahead log and has for decades — `disk_log`, the primitive under mnesia, with halt and wrap variants, internal chunked format, and automatic repair of logs that were not properly closed [4]. The lane logs two terms per pair and folds chunks to replay:

```elixir
:ok = :disk_log.log(log, {:i, job, name_id, version, ts})
:ok = :disk_log.log(log, {:m, job})
```

The derived floor assumed two synchronous round trips to the log owner and was wrong in the right direction: `4.2 us per pair async with repair-on-open standing behind it, 546.9 with a sync per pair -- the chunk fold returned every term`. The log owner batches internally, so a logged term costs barely more than a message send until someone asks for a sync — at which point it costs what every sync costs on this disk. For an obligations lane, `disk_log` async is the strongest pure-OTP candidate in the matrix: the AOF leg's speed with crash repair the AOF leg does not have.

## E — The raw append: the floor itself

The bottom of the matrix is an owner process and `:file.write/2` — 51-byte intent frames, 15-byte mark frames, three disciplines that make the durability ladder explicit: `:buffered` rides `:delayed_write`, `:everysec` issues the write and syncs on a one-second timer (the Redis AOF shape), `:always` pays `datasync` per pair. The record: `3.1 us per pair buffered, 13.3 everysec, 533.8 with a datasync every pair (one datasync measured at 1828 us) -- replay folded every frame back on all three files`. That 3.1 is what persistence costs when nothing else is bought with it: no UNIQUE constraint, no SQL replay predicate, no repair beyond a torn-frame check at fold time. The spread from 3.1 to 533.8 on one module is the entire `synchronous` debate rendered as a single column of numbers — and the anchored single `datasync` at 1828 µs shows the cliff every per-operation-sync design lives beside.

## F — The wire: the reasoning and the numbers

The off-box layer was measured, not estimated, against the Tigris bucket on Fly — a minimal SigV4 client on `:httpc`, payloads signed with their real SHA-256, region the literal `auto` Tigris carries in the credential scope:

```elixir
key_signing =
  ("AWS4" <> c.secret)
  |> hmac(date) |> hmac(c.region) |> hmac("s3") |> hmac("aws4_request")

signature = hex(:crypto.mac(:hmac, :sha256, key_signing, to_sign))
```

**The reasoning, first.** An intent that travels as its own object pays one signed round trip, and a round trip is milliseconds where the journal pays microseconds — three orders of magnitude, before any argument about durability. So the only viable S3 shape for a lane is amortization: K intents per object, the round trip divided by K, falling as 1/K, with the local journal still in front as the synchronous truth. That is Litestream's architecture stated as arithmetic — local WAL first, pages shipped behind, restore as snapshot-plus-replay [6] — and Litestream documents Tigris as a replica target directly.

**The numbers.** Per-intent: `one PUT per intent: median 106.7 ms over 20 -- 743 times the fused local pair, the number that prices why the journal is local-first`. Segments at depth 128: `143.8 ms per 128-intent segment -- 1123.3 us per intent shipped -- and restore walked 8 segments to recover all 1024 intents in 582 ms`. The per-segment time tracks the per-intent median — the wire charges per round trip, not per byte, at these sizes — so the 1/K arithmetic extends where the bench stopped: depth 512 on this same egress prices near 280 µs per intent shipped, and the restore path walked list-then-GET-then-fold at roughly 73 ms per segment.

**What the milliseconds are made of.** This container reached `fly.storage.tigris.dev` from outside Fly's network; that hostname is the within-Fly endpoint, with `t3.storage.dev` the canonical name for external callers — one service either way [7]. The measured 106-144 ms per round trip is therefore this egress's number, a ceiling for the deployment that matters: Portal on Fly rides the internal path to the same buckets, and every figure in this section scales down with that RTT while the 1/K shape stays. The composition for a production lane follows directly: a sync-ack-to-S3 lane inherits P6 whole and is priced out of obligations work; an async shipping layer behind the journal inherits the local pair's microseconds, pays the wire in the background, and meets the wire again only at restore — 582 ms to recover a thousand intents is a restore budget, not a latency budget, and that is the correct side of the trade. The bench left the bucket as it found it: `swept 8 segments and 21 intent objects`.

## The matrix

| Engine | Pair / per-intent | Survives process crash | Survives power loss | Survives the box | The catch |
|---|---|---|---|---|---|
| Journal, fused pair | `143.5` µs | yes | NORMAL tail only [5] | no | the owner hops are the price of UNIQUE, SQL replay, and coverage compaction |
| Journal, `record_many` d128 | `33.5` µs | yes | NORMAL tail only | no | callers must batch; marks stay per-intent |
| Rust NIF, fused call | `77.5` µs | yes | NORMAL tail only | no | a per-platform `.so`; the owner hops return the moment an owner fronts it |
| `disk_log`, async | `4.2` µs | yes, repair-on-open | OS-buffered tail | no | term log, no UNIQUE, no SQL — replay predicates move into code |
| AOF, buffered | `3.1` µs | only after flush | no | no | lab-grade: torn-frame check is the whole recovery story |
| AOF, datasync per pair | `533.8` µs | yes | yes | no | the 1828 µs cliff, paid every pair |
| S3, segment d128 | `1123.3` µs shipped | yes | yes | yes | RTT-shaped; restore-time recovery, not read-time |

Each row's catch column is load-bearing: the fast rows buy speed by shedding exactly the guarantees Chapter 4.4's gates drill, and the durable rows pay for what they keep.

## What landed in production, and what stayed in the lab

Two changes shipped into `lib/echo_cache/journal.ex` and regressed green against the full 4.4 rung: the fused `RETURNING` insert with its drain-to-done discipline, and `record_many/2` group commit. The negative result on the fusion is part of the ship — the statement count was cleared as a suspect, and the pair's true cost now has a name. Everything else stays under `lab/` and `native/` by intention: the AOF and `disk_log` lanes lack the constraint and replay machinery the journal's gates require, the Rust binding's crossing savings do not yet justify a compiled artifact in the tree's build story, and the S3 client is a measuring instrument, not a client library. Chapter 4.5's referee inherits this matrix as calibration: when Nebulex, Oban, and the rest take the stand, the floor under every persistence claim is now a measured number, not an assumption.

## Boundaries

One scheduler, this container's disk, this container's egress — the header travels with every figure, and the wire numbers in particular are egress-shaped with the within-Fly path strictly cheaper [7]. The lab modules are lab-grade on purpose: no CRC beyond frame shape, no compaction, no retries or multipart on the S3 client, and the `lane_rs` cdylib is a per-environment build output excluded from the archive. The journal's own boundaries stand unchanged from 4.4 — `synchronous=NORMAL` trades the power-loss tail for its speed [5], and Litestream remains the named, deliberately unbuilt layer above it [6]. The benches measure record-side cost in isolation; nothing here re-prices the consumer side of the lane, which 4.4's end-to-end figure already carries.

## Companion files

`runtimes/elixir/lab/lab_persistence_bench.exs` and the committed `lab/lab_persistence_bench.out`; the lab lanes under `runtimes/elixir/lab/persistence/` (`aof_lane.ex`, `disk_log_lane.ex`, `s3_lane.ex`, `lane_rs.ex`); the crate under `runtimes/elixir/native/lane_rs/`; the grown production journal at `runtimes/elixir/lib/echo_cache/journal.ex`.

## References

1. Fowler, R. — async-sqlite (a Client as one background SQLite connection thread behind a bounded queue, a Pool as N of them, rusqlite bundled by default — the architecture the journal's owner already implements, read here as prior art for legs B and C): [github.com/ryanfowler/async-sqlite](https://github.com/ryanfowler/async-sqlite)
2. Mohan, C., Haderle, D., Lindsay, B., Pirahesh, H., Schwarz, P. — ARIES: A Transaction Recovery Method Supporting Fine-Granularity Locking and Partial Rollbacks Using Write-Ahead Logging, ACM TODS 17(1), 1992 (the WAL contract every leg in this lab implements a corner of): [dl.acm.org/doi/10.1145/128765.128770](https://dl.acm.org/doi/10.1145/128765.128770)
3. DeWitt, D., Katz, R., Olken, F., Shapiro, L., Stonebraker, M., Wood, D. — Implementation Techniques for Main Memory Database Systems, SIGMOD '84 (group commit: the log force amortized across concurrent committers, measured here as leg B's monotone curve): [dl.acm.org/doi/10.1145/602259.602261](https://dl.acm.org/doi/10.1145/602259.602261)
4. OTP documentation — disk_log, kernel (halt and wrap term logs with internal chunked format and automatic repair of improperly closed logs — leg D's engine and its recovery story): [erlang.org/doc/apps/kernel/disk_log.html](https://www.erlang.org/doc/apps/kernel/disk_log.html)
5. SQLite documentation — Write-Ahead Logging (at synchronous NORMAL the checkpoint is the sole sync barrier; the journal's speed and its stated power-loss trade): [sqlite.org/wal.html](https://sqlite.org/wal.html)
6. Litestream documentation — How it works (local WAL first, pages shipped to replicas from a separate process, restore by snapshot plus replay — the architecture leg F's arithmetic re-derives): [litestream.io/how-it-works](https://litestream.io/how-it-works/)
7. Fly.io documentation — Tigris Global Object Storage (the t3.storage.dev canonical endpoint and the within-Fly fly.storage.tigris.dev name reaching one service; why this lab's wire figures are an external-egress ceiling): [fly.io/docs/tigris](https://fly.io/docs/tigris/)
