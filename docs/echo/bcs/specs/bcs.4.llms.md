# BCS.4 · agent guide

> How to build the B4 batches (`/bcs/cache`): requirements, do-NOTs, the **verified grounding bank** (the
> senior read every figure below directly in the manuscript chapters and the committed rung records — cite from
> here and the named sources; re-derive nothing, invent nothing), per-module briefs, and the verification
> commands. **B4.1–B4.4 are manuscript-ready; B4.5 is manuscript-pending** (D-B4.2) — it carries a pointer only.
> Spec of record: [`bcs.4.specs.md`](bcs.4.specs.md) · chapter doc: [`bcs.4.md`](bcs.4.md).

## References

- The triad: [`bcs.4.md`](bcs.4.md) · [`bcs.4.specs.md`](bcs.4.specs.md) (the module ladder + invariants + DoD).
- The course docs: [`../bcs.md`](../bcs.md) · [`../bcs.toc.md`](../bcs.toc.md) ·
  [`../bcs.roadmap.md`](../bcs.roadmap.md).
- The design exemplars: the built B2 chapter landing (`html/bcs/elixir-core/index.html`) — or the B3 chapter
  landing once built — a built hub (`html/bcs/elixir-core/otp-application/index.html`), a built dive
  (`html/bcs/elixir-core/otp-application/the-export-list.html`). Copy head/header/footer/scripts from a built
  BCS page of the same surface — never another course.
- The manuscript (read-only): `../content/bcs4.md` (the Part preface — the chapter landing's spine; it also
  carries the LMAX/ring and journal/Litestream essays the landing may draw on) · `../content/bcs4.1.md`–
  `bcs4.4.md`; the committed evidence under `../content/echo_data/runtimes/elixir/`
  (`bcs_rung_4_1`…`4_4_check.out`).

## Requirements

- **BCS.4-R1** — md mirror first (`docs/echo/bcs/markdown/cache/<route>.md`), then the HTML, per page.
  [US: BCS.4-US1]
- **BCS.4-R2** — build each page to the ladder in [`bcs.4.specs.md`](bcs.4.specs.md); dives are fixed (D-B4.1).
  [US: BCS.4-US3]
- **BCS.4-R3** — every figure from the bank below or re-verified in the named `content/` file; rung records
  verbatim in source-labelled `figure.frozen` blocks; derive lines may ride beside their measurements (D-B4.3).
  [US: BCS.4-US1]
- **BCS.4-R4** — a fresh `BCS…` stamp per page, minted and decode-verified. [US: BCS.4-US2]
- **BCS.4-R5** — gate every page; ship only at STATUS: PASS. [US: BCS.4-US2]
- **BCS.4-R6** — priced pairs travel together (762 ns ↔ 31 µs · 72 µs ↔ 148 µs · 148 µs ↔ 524 µs) — D-B4.5.
  [US: BCS.4-US3]

## Do NOT

- Do not copy dark-editorial tokens, fonts, or card classes; copy only built BCS pages.
- Do not anchor unbuilt routes; B4.5 is named in `<strong>`, never linked; defer cross-links to concurrent
  siblings.
- Do not edit `../content/**`, the course landing, the chapter landing (orchestrator-only), or the TOC.
- Do not fetch anything external; no storage APIs; honour `prefers-reduced-motion`.
- Do not write a figure absent from the bank and the sources. **Do not invent a comparison-set number** — the
  referee chapter (`bcs4.5.md`) is unwritten; Nebulex/Cachex/Valkey-tracking may be characterized only as the
  Part preface characterizes them (coherence as deletion, no version, no order) — D-B4.2.
- Do not assert Litestream as implemented — the manuscript *names* it and deliberately does not build it.
- Do not run git. Mind the gate traps: `just`/`simply`/`obviously` in prose; the literal substring `/future`;
  a perceptual verb on a tool (a cache/table/ring/journal does not "see"/"want"/"know"/"decide"; verbatim
  transcript lines inside `figure.frozen` are exempt).

## Per-module briefs + the verified grounding bank

Pager law: hub prev = `/bcs/cache`, next = own first dive; dives chain hub → dive1 → dive2 → dive3 → back to
the hub. `Related`: the chapter landing, `/bcs/bus` modules where the content meets them (the job lane → the
state machine and fair lanes; the journal's replay → jobs-are-entities), `/bcs/elixir-core/property-stores`
(the stores being cached), and the doors (`/redis-patterns` R1 caching, `/echomq`, `/elixir`).

### B4.1 `cache-aside` — teaches `../content/bcs4.1.md`

Dives: `declared-not-discovered` · `one-fill-per-herd` · `the-jittered-clock`.

The transcript, verbatim (source: `bcs_rung_4_1_check.out` — note the header and the `derive` lines are part of
the record; the hub's frozen block quotes the record whole):

```
header: Valkey 9.1.0 on 6390 | Elixir 1.14.0 OTP 25 | schedulers 1
E1 declared ok -- two caches enumerable with their full declarations -- kind, ttl, coherence -- an undeclared name answers :error, and a wrong-kind id is refused at the door: zero loader runs, zero keys on the wire
E2 sources ok -- one name, three sources in order: a cold read fills (loader ran once), a warm read hits L1 without touching the owner, and an L1 drop falls back to L2 -- the loader still ran once; the L2 row carries the declared TTL (PTTL 300 ms of 300)
derive (herd): 200 concurrent cold readers without single-flight run 200 loads; the law demands the misses coalesce onto one flight -- expect loader runs 1 and 199 coalesced waiters
E3 herd ok -- the thundering herd survived with one fill: 200 concurrent cold readers, loader runs 1, coalesced waiters 199, every reader holding the one answer
derive (speed): a hit is a caller-side lookup on a public read-concurrency set plus the kind gate and a counter bump -- expect 250,000 to 1,500,000 hit reads per second on this core; an L2 GET pays a loopback round trip, and Appendix A committed 29,456 sequential round trips per second, near 34 us each -- expect the L1 hit at least 10 times cheaper than the wire
E4 speed ok -- measured: 1311621 hit reads per second (762 ns each) against 31 us per L2 GET on the same wire -- the L1 hit is 40 times cheaper than the round trip it replaces, inside the derived band
derive (jitter): ttl 300 ms at jitter 0.2 spreads expiry uniformly across plus-minus 60 ms -- 400 rows filled in one fast pass should spread at least 70 ms beyond their fill walltime, approaching 120; a jitter 0.0 cohort's spread can never exceed its own fill walltime -- jitter adds nothing; the sweeper on a 100 ms tick then reclaims the whole cohort without a single read
E5 jitter ok -- 400 rows filled in 24 ms expire 138 ms apart at jitter 0.2 -- no synchronized re-herd -- while the jitter 0.0 cohort spreads 5 ms across a 4 ms fill: jitter added nothing there; the sweeper then reclaimed the whole cohort on its tick (swept 400, table size 0) with not one read paying the cleanup
derive (bound): refdata declares max_size 100 with a 60 s ttl, so nothing expires to reclaim -- 49 more fills fit beside the 51 live rows, then every further fill must serve its caller and skip the insert
E6 bound ok -- the declaration holds: size capped at 100 of 100, 101 fills served their callers and skipped the insert -- a full cache is a stat, never an error -- and the writer path lands one value in both layers
PASS 6/6
```

Verified teaching points (source: `bcs4.1.md`):

- The declaration shape (quote from the How):
  ```elixir
  {:ok, _} =
    EchoCache.Table.start_link(
      name: :quotes,
      kind: "AST",
      ttl_ms: 300,
      jitter: 0.2,
      sweep_ms: 100,
      coherence: :none,          # wired by Chapter 4.2
      loader: &PriceFeed.load/1,
      connector: [port: 6390]
    )
  ```
  and the read path: `{:ok, quote, :hit} = EchoCache.Table.fetch(:quotes, "AST0NuE6bV7FoH")`;
  `EchoCache.tables/0` as "the law made callable."
- The surface is `fetch/2` with source tags `:hit | :l2 | :fill`; the L2 row is written `SET ... PX`; the
  keyspace is `ecc:{<table>}:<id>` — "a fresh prefix beside `emq:`, never inside it"; the wire is the Appendix
  B production connector, "reused untouched" (named in living-status — its prose appendix is unwritten).
- The herd pattern's name: singleflight, "a duplicate function call suppression mechanism" (the Go port's
  idiom).
- Decisions: declared, not discovered · the hit path never enters the owner (public ETS + `read_concurrency`,
  `:counters` not `GenServer.call`) · flights are processes, not owner code · values are binaries · full
  degrades to pass-through (no LRU — "an LRU would tax every read with touch-tracking") · two clocks, again
  (BEAM monotonic for L1, server `PX` for L2).
- Boundaries: staleness bound = the TTL, nothing sharper (4.2's business); L1 is per-node; loader errors are
  not cached (negative caching deliberately omitted).
- Files: `runtimes/elixir/lib/echo_cache/echo_cache.ex`, `lib/echo_cache/keyspace.ex`,
  `lib/echo_cache/table.ex`.

Sources: Erlang/OTP ets `https://www.erlang.org/doc/apps/stdlib/ets.html` · Valkey SET
`https://valkey.io/commands/set/` · Valkey EXPIRE `https://valkey.io/commands/expire/` · Go x/sync singleflight
`https://pkg.go.dev/golang.org/x/sync/singleflight`.

### B4.2 `coherence-by-mint-time` — teaches `../content/bcs4.2.md`

Dives: `the-twenty-nine-bytes` · `the-broadcast-lane` · `the-job-lane`.

The transcript, verbatim (source: `bcs_rung_4_2_check.out`; it contains a mid-record `[error] GenServer …
terminating … (stop) killed` block — that is the staged consumer kill of the F5 drill and part of the frozen
record; quote it or elide it with a clearly-marked `…` in dive context, but the hub's frozen block keeps the
record whole):

```
F1 surface ok -- the vocabulary is whole: channel, queue, a twenty-nine-byte payload of two names, parse refusing garbage; tables declare their lane in the directory; and the connector's push path refuses a protocol 2 connection with a typed :requires_resp3
F2 newer-wins ok -- a late stale invalidation bounced off both layers -- the L1 row survived holding px=105.00 and the L2 drop script answered 0 -- while a genuinely newer version applied and the replay of the old one stayed stale: idempotence is a comparison, not a log
derive (broadcast): the lane is one PUBLISH hop on the wire whose committed sequential floor is 29,456 round trips per second, near 34 us each -- expect a median push latency between 30 and 500 us, and the receiver's apply is one ETS comparison on top
F3 broadcast ok -- median push latency 72 us over 100 messages, inside the derived band; the cross-node round trip holds -- the writer put px=106.00, 3 subscribers heard the name, and the other node's next read fell through its dropped L1 to the shared L2 and answered fresh
F4 loss ok -- the price of fire-and-forget, stated as a gate: :qc declared the job lane and holds no subscription, so the broadcast passed it by and it still serves px=100.00 -- bounded staleness until its own lane delivers, which is the next gate's business
derive (job lane): a consumer crash after claim strands the coherence job on a lease; the reaper returns it, a second consumer applies it with token 2, and reapplication is harmless because newer-wins is a comparison -- expect attempts 2 and exactly one effective drop
F5 job lane ok -- the lane that survives: the first consumer died holding the job, the reaper returned it, the healer applied it -- :qc dropped its stale row and now serves px=107.00 from the shared L2 -- the completed job left no row to browse, and replaying the same version answers stale: at-least-once delivery, exactly-once effect
derive (price): the broadcast lane is one wire hop; the job lane pays three to five hops -- enqueue, wake, claim, complete -- so a parked consumer should land its median between 80 us and 2 ms, the same order as the bus's committed 0.3 ms end-to-end median, carrying the guarantee the push cannot
F6 price ok -- the two lanes on one row: broadcast median 72 us fire-and-forget, job lane median 148 us at-least-once -- the guarantee costs 2.1 times the latency, and gates F4 and F5 are the reason a surface pays it
PASS 6/6
```

Verified teaching points (source: `bcs4.2.md`):

- The message: `EchoCache.Coherence.payload/2` frames "a cached name, a colon, and the writer's mint-time
  version"; `parse/1` refuses anything not exactly two valid branded ids. The cargo law rides into coherence
  unchanged.
- The writer's side, verbatim from the How:
  ```elixir
  version = BrandedId.generate!("TXN")           # the write's own identity
  :ok = Table.put(:quotes, ast_id, "px=106.00", version)
  {:ok, _heard} = Coherence.broadcast(conn, "quotes", ast_id, version)
  # or, when at-least-once matters:
  {:ok, :enqueued} = Coherence.enqueue(conn, "quotes", group, ast_id, version)
  ```
  and the comparison that is the whole protocol:
  ```elixir
  Coherence.newer?("TXN0NuG2aaaaaaa", "TXN0NuFzzzzzzzz")
  # payload bytes in mint order: true — no decode, no clock, no quorum
  ```
- The comparison-set gap, as the chapter states it: Valkey's tracking sends "an unversioned *forget this key*";
  Nebulex synchronizes by deletion; "neither message carries an order" — Lamport's 1978 total order is the cure
  this series carries in every identity. (No comparative *measurement* exists — D-B4.2.)
- The channel is `ecc:{<table>}:coh`; the queue is `ecc.coh.<table>`; the connector grows `push_command/3` and
  `subscribe/2` — send-only, RESP3-only, refusing protocol 2 with `:requires_resp3`.
- Decisions: the version is a name · coherence drops; it never writes · stale messages bounce off both layers
  (the same predicate in two places — L1 comparison in the owner, L2 comparison in one Lua script) · the
  job-lane consumer lives in the application's tree (`coherence_handler/1` makes it one line) · the push path is
  send-only and RESP3-only · the applier is the owner — for now (4.3 moves it onto the ring).
- Boundaries: the broadcast lane inherits its substrate's contract whole (at-most-once, unpersisted, lost on
  disconnect; resubscription rides supervision); the job lane inherits the bus's (volatile by D-2); same-ms
  cross-node mints order by node-and-sequence bits — "an arbitrary-but-total tiebreak in exactly Lamport's
  sense."
- Files: `runtimes/elixir/lib/echo_cache/coherence.ex`, the grown `lib/echo_cache/table.ex`, the grown
  `lib/echo_mq/connector.ex`.

Sources: Valkey Pub/Sub `https://valkey.io/topics/pubsub/` · Valkey client-side caching
`https://valkey.io/topics/client-side-caching/` · Lamport 1978
`https://dl.acm.org/doi/10.1145/359545.359563`.

### B4.3 `single-writer-ring` — teaches `../content/bcs4.3.md`

Dives: `two-sequences-one-table` · `occupancy-and-the-bound` · `the-storm-drill`.

The transcript, verbatim (source: `bcs_rung_4_3_check.out`):

```
header: Valkey 9.1.0 on 6390 | Elixir 1.14.0 OTP 25 | schedulers 1
G1 surface ok -- the ring's surface is whole -- publish, occupancy, stats, stop, a generic one-batch apply function -- and the declaration tells the truth: the broadcast table carries its ring name and capacity 512 in the directory, the :none table carries nil, and a fresh ring stands at occupancy 0
derive (order): the applier drains everything between head and tail in one pass, so concatenating the batches must reproduce publish order exactly; wakes are edge-triggered on the empty-to-nonempty transition, so 1000 items published into a draining ring should cost a handful of wakes -- well under fifty -- and more than one batch proves the batching is real
G2 order ok -- 1000 items crossed the ring in publish order exactly -- the concatenated batches reproduce the sequence -- through 2 batches (largest 801) on 1 wakes: one message per busy period, not one per item
derive (throughput): a publish is one ETS insert and three atomics operations, near 0.5 to 1 us, and the apply side amortizes to nothing over batches -- so publish cost alone governs, and the end-to-end rate on one scheduler should land between 100,000 and 2,500,000 items per second, floor 80,000; mid-storm occupancy must sit strictly between zero and capacity and drain to exactly zero
G3 occupancy ok -- mid-storm the gauge read 600 of 4096 and drained to exactly 0; priced, the ring moved 100000 items in 99 ms -- 1005116 items per second end to end on one scheduler, inside the derived band, largest batch 200, nothing dropped
derive (full): with capacity 64 and the applier held inside its first apply, exactly 64 publishes are accepted and 136 are refused and counted; releasing the applier drains the 64, and the next publish lands -- the ring under storm refuses, recovers, and keeps serving
G4 full ok -- the bound held its shape: 64 accepted, 136 refused with :dropped and counted -- never blocked, never overwritten -- then the release drained all 64 and publish 201 landed and applied: a storm bends the lane's at-most-once contract no further than the contract already bends
derive (storm): 500 invalidations published on the wire ride push frames at the committed 72 us median into the owner, which only parses and publishes -- application happens on the ring's applier, so a fetch fired mid-storm answers without queueing behind 500 applies; expect the storm applied within two seconds and the mid-storm fill well under 50 ms
G5 storm ok -- 500 invalidations crossed the wire and the ring in 25 ms with nothing dropped; every stormed row left L1, the one name whose writer placed a new value answers px=109.00 from the shared L2, and a fill fired mid-storm completed in 0 ms -- the owner parses and publishes while the applier applies, and neither waits for the other
derive (convergence): for each of 200 names holding version v2, a shuffled stream delivers either v1,v3,v1 or v1,v1 -- whatever the arrival order, a row is dropped if and only if a version newer than v2 appeared, and the per-name verdict counts are invariant under permutation: exactly 100 applied and 400 stale
G6 convergence ok -- 500 shuffled messages converged: the 100 names that saw a newer version lost their rows, the 100 that saw only older versions still answer :hit, and the verdict counters landed exactly on 100 applied and 400 stale -- arrival order changed nothing, because every application is the same comparison
PASS 6/6
```

Verified teaching points (source: `bcs4.3.md`):

- The structure: an atomics pair (tail/head) over a public ETS table whose rows are reused by
  `rem(seq, capacity)`; the load-bearing documented sentence: "All atomic operations are mutually ordered."
- The prior art: LMAX — "6 million orders per second on a single thread" — fed by the Disruptor; the chapter
  "translates that shape onto the BEAM" and reads it beside park-don't-poll ("both replace discovery with
  arrival"). The Disruptor correspondence paragraph (sequences are atomics; slots are ETS rows; the single
  business-logic thread is the applier; the wait strategy is the mailbox).
- The declaration and the gauge, verbatim from the How:
  ```elixir
  EchoCache.Ring.occupancy({:coh, :quotes})
  # 0 in calm, a hill in a storm

  EchoCache.Ring.stats({:coh, :quotes})
  # %{published: ..., applied: ..., dropped: 0, wakes: ..., batches: ...,
  #   max_batch: ..., occupancy: 0, capacity: 4096}
  ```
- The derivation note is part of the record (D-B4.3): "the first band's ceiling undercounted exactly because it
  priced the apply side that batching had already amortized away."
- Decisions: the ring serves the broadcast lane only ("routing the job lane's at-least-once delivery through a
  dropping structure would launder a guarantee away") · drop, never block, never overwrite · single producer,
  structurally · the applier applies caller-side · runtime in `persistent_term`.
- Boundaries: single-producer is a hard precondition; a dropped message is a real loss bounded by the TTL; a
  brutal kill leaks one `persistent_term` entry ("a stated cost of kill-9 truthfulness"); the magnitude does
  not travel.
- Files: `runtimes/elixir/lib/echo_cache/ring.ex`, the grown `lib/echo_cache/table.ex`.

Sources: Fowler, The LMAX Architecture `https://martinfowler.com/articles/lmax.html` · the Disruptor technical
paper `https://lmax-exchange.github.io/disruptor/disruptor.html` · Erlang/OTP atomics
`https://www.erlang.org/doc/apps/erts/atomics.html`.

### B4.4 `the-lane-that-remembers` — teaches `../content/bcs4.4.md`

Dives: `two-memories-one-file` · `the-bus-dies-the-lane-replays` · `coverage-and-the-price`.

The transcript, verbatim (source: `bcs_rung_4_4_check.out`; the record opens with an `[info] EchoData: contract
self-check passed, codec=pure` line and its header names SQLite — keep them):

```
header: Valkey 9.1.0 on 6390 | SQLite 3.46.0 via exqlite, WAL, synchronous=NORMAL | Elixir 1.14.0 OTP 25 | schedulers 1
H1 files ok -- one journal file per group, named by the group's branded id -- two groups, two files on disk -- a non-branded group is refused at the door, and the schema carries the two memories: intents (the outbox) and applied (the lane's last word per name)
derive (windows): the writer's flow is record, enqueue, mark -- two crash seams; a death before the enqueue leaves a pending intent that replay enqueues; a death after the enqueue but before the mark leaves the bus holding the job, and replay's reuse of the recorded job id lets the bus's own admission dedup absorb it; full coverage by the applied memory makes replay a no-op
H2 windows ok -- both crash seams closed by machinery that already exists: the never-enqueued intent replayed onto the bus, the enqueued-but-unmarked one answered :duplicate at admission and was counted, both ended in the applied memory -- and once coverage is total, replay is exactly %{replayed: 0, deduplicated: 0}
derive (memory): the applied table lives in the file, so it survives the table, the node, and the bus; after a full restart with an empty L1, a replayed old version must answer :remembered_stale from the journal alone -- no cache row consulted, none created -- while a genuinely newer version passes through and updates the memory
H3 memory ok -- the journal remembered v5 across a full stop of table and journal; the replayed old version answered :remembered_stale without touching the cache -- the table's verdict counters did not move and no row appeared -- and the genuinely newer v6 passed through and became the new last word
derive (loss): D-2 keeps the bus volatile, so a bus restart erases queued coherence jobs; 50 intents recorded and enqueued, 20 applied before the loss, the lane's queue keys flushed -- replay must re-enqueue exactly the 30 uncovered intents in seq order, and a consumer must drain them to a remembered count of 50
H4 loss ok -- the bus restart erased the queue and the journal replayed the lane back: exactly 30 uncovered intents re-enqueued in seq order under their recorded job ids, the consumer drained them, and the applied memory closed at 50 of 50 names holding their final versions
derive (compaction): an intent is retired when its name carries an applied version at least as new -- coverage, not acknowledgment -- so after H4 all 50 intents are deletable, the applied memory keeps all 50 names, replay finds nothing, and a reopen still remembers
H5 compaction ok -- all 50 intents retired by coverage in one pass, the applied memory kept its 50 names, replay over the compacted journal found nothing to do, and a fresh open of the same file still answers the last word -- the outbox empties, the memory does not
derive (price): on prepared-once statements -- the single writer's privilege, with bind resetting the statement -- the writer's pair is two WAL commits and one cached rowid read at synchronous=NORMAL, so expect between 20 and 250 us on this disk; the remembered lane's end-to-end median should land between 200 us and 2 ms against the bare lane's committed 148 us: dearer, bounded, and the chapter's reason the journal is declared per group rather than assumed
H6 price ok -- the memory's price on this disk: 143 us per record-and-mark pair at the writer's edge, and a remembered lane end-to-end median of 524 us against the bare lane's committed 148 us -- 3.5 times the latency buys an outbox, a last word per name, and a replay that survives the bus
PASS 6/6
```

Verified teaching points (source: `bcs4.4.md`):

- The thesis: Richardson's transactional outbox, BCS-armed — "the bus already deduplicates a job id at
  admission, and newer-wins already makes a re-applied version a no-op. What was missing was only the durable
  intent and the durable memory of application." The law's wording is exact: "the bus gets no WAL; the journal,
  which is not the bus, gets SQLite's."
- The schema: `intents` (`seq`, the recorded job id, the name, the version, an enqueued flag — "the cargo law
  in a schema") and `applied` (the lane's last word per name).
- The writer's and applier's edges, verbatim from the How:
  ```elixir
  {:ok, _} =
    EchoCache.Journal.start_link(
      name: :limits_journal,
      group: group_id,            # the lane's PRT, one file per group
      table: "limits",
      dir: "/var/lib/echo/journals"
    )

  {:ok, job_id} = Journal.intend_and_enqueue(:limits_journal, conn, ast_id, version)
  ```
  ```elixir
  {:ok, _} =
    EchoMQ.Consumer.start_link(
      queue: Coherence.queue("limits"),
      connector: [port: 6390],
      handler: Journal.handler(:limits_journal, :limits)
    )
  ```
  ```elixir
  {:ok, %{replayed: n, deduplicated: m}} = Journal.replay(:limits_journal, conn)
  {:ok, retired} = Journal.compact(:limits_journal)
  ```
- How the gate improved the code: the first measurement landed at 224 µs — per-call statement preparation,
  "three SQL parses per pair"; the fix is prepared-once statements ("the single writer's privilege"), and the
  pair fell to the committed 143 µs. At `synchronous=NORMAL` "the checkpoint is the only operation to issue an
  I/O barrier."
- The toolchain fact: the runtime's mix project grew its **first compiled dependency** — `exqlite` vendored as
  path deps under `runtimes/elixir/vendor/`, the NIF compiled from the bundled SQLite amalgamation — and the
  rung runs under `MIX_ENV=prod mix run`, the first cache rung to do so.
- Decisions: one journal, one owner · coverage, not acknowledgment · replay reuses recorded job ids ·
  `mark_enqueued` is a separate call on purpose ("the outbox pattern's candor is that the seams are real") · the
  memory check runs before the cache · the journal's WAL is beside the bus (D-2 untouched).
- Boundaries: `synchronous=NORMAL` is a stated trade (a machine power loss may trim the unsynced WAL tail — the
  closing layer is "Litestream-shaped … referenced and deliberately not implemented here"); the journal is
  per-group and per-node; replay is at-least-once and harmless by comparison.
- Files: `runtimes/elixir/lib/echo_cache/journal.ex`; the vendored build chain under
  `runtimes/elixir/vendor/`.

Sources: Richardson, Transactional outbox
`https://microservices.io/patterns/data/transactional-outbox.html` · SQLite WAL `https://www.sqlite.org/wal.html`
· Litestream `https://litestream.io/how-it-works/`.

### B4.5 `cache-referee` — pointer (manuscript pending — D-B4.2)

`bcs4.5.md` is not written. The manuscript TOC plans: "Nebulex's near-cache topology, Cachex, and Valkey's
server-assisted tracking measured where they run: hit-path latency, the herd drill, and coherence-lag
distributions, with the rows the comparison set cannot print — typed keys, mint-ordered newer-wins, a
job-backed lane — beside the rows it wins." Reference it ONLY in living-status voice ("the manuscript plans the
referee chapter…"); no comparative figure exists, so none appears on any page. The module's grounding bank is
authored when the chapter ships.

## Agent stories

- **BCS.4-AS1 [implements BCS.4-US3]** — Per module: md mirrors first, then the pages, copying the design from
  the named model. Acceptance gate: every figure appears in this bank or the named manuscript file, character
  for character; the rung record verbatim in a `figure.frozen` block.
- **BCS.4-AS2 [implements BCS.4-US1]** — Interactives per surface: hub ≥1, dive ≥2, pure functions over the
  module's own fixed dataset (the gate explorer; a three-sources walk; a jitter-spread visualizer over the
  fixed 138 ms/5 ms cohorts; a newer-wins comparator over fixed version pairs; a ring occupancy gauge over the
  fixed 600-of-4096 storm; a replay-coverage stepper over the fixed 50/20/30 ledger), live readout, static
  degrade.
- **BCS.4-AS3 [implements BCS.4-US2]** — Gate, then self-audit: figure provenance, identity leak, clamp
  spacing, route-tag form, stamp decode, md mirror present, priced pairs intact (R6), no invented comparison-set
  number.

## Build order

1. Orchestrator: chapter landing (`/bcs/cache`) from this triad — gate it. B4.5 card non-anchor `planned`.
2. Waves of ≤2 module agents, suggested: B4.1+B4.2 → B4.3+B4.4. (Defer cross-sibling links within a wave;
   restore after the wave lands. Note the natural cross-references: 4.2 inherits 4.1's `invalidate/2`; 4.3 is
   4.2's engine; 4.4 journals 4.2's job lane.)
3. Orchestrator after each wave: restore deferred links → relink the chapter landing → after the first green
   wave relink the course landing (B4 card + footer) → sync [`../bcs.toc.md`](../bcs.toc.md) → final
   verification.

## The verification sequence

```bash
# Gate (per page; all ten must PASS)
FLAGS="--routes-from /bcs=html/bcs --routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns --routes-from /elixir=elixir --chapter-alias b1=ideas,b2=elixir-core,b3=bus,b4=cache,b5=go,b6=node,b7=fly,b8=trading --require-refs"
apps/jonnify-cms/bin/cms check ${=FLAGS} html/bcs/cache/<path>.html

# Stamp (per page)
apps/jonnify-cms/bin/cms stamp mint --ns BCS && apps/jonnify-cms/bin/cms stamp decode <id>

# Batch audits (all must return nothing)
grep -rn '/future' html/bcs/cache/
grep -rnEi '\b(revolutionary|blazing|magical|simply|just|obviously|effortless)\b' html/bcs/cache/
grep -rn 'localStorage\|sessionStorage\|Cormorant\|Manrope\|PT Serif' html/bcs/cache/
grep -rnE 'clamp\([^)]*[0-9](\+|-)[0-9]' html/bcs/cache/
grep -rnE '\b(cache|table|ring|journal|store|gate|system|boundary|bus|id|lane|applier) (sees?|wants?|knows?|decides?)\b' html/bcs/cache/

# Live crawl (server on :8765; 000 = server down, not route missing)
curl -s -o /dev/null -w '%{http_code}\n' localhost:8765/bcs/cache
```

## Comprehensive prompt

Build your assigned B4 module of the BCS course. Read [`bcs.4.specs.md`](bcs.4.specs.md) (your module's row in
the ladder is your structure — do not redesign it), your manuscript chapter under `../content/`, and your
module's section of this guide. Author the md mirrors first (`docs/echo/bcs/markdown/cache/<route>.md`), then
the pages, copying the contract-sheet design from the named built BCS page — never another course. Quote every
figure verbatim from the bank; render the rung record in a source-labelled `figure.frozen` block; keep priced
pairs together; never invent a comparison-set number (B4.5 is unwritten); mint and decode-verify a fresh `BCS…`
stamp per page; keep every internal link resolving. Gate each page; ship only at STATUS: PASS. Touch only your
module's routes. Never run git.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Chapter: ./bcs.4.md · Spec: ./bcs.4.specs.md
