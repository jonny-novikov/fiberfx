# B4 · EchoCache — the near-cache the comparison set does not ship

> Chapter landing for `/bcs/cache`, teaching manuscript Part IV. Orchestrator-authored; bootstrapped from the
> built B3 chapter landing. Source spine: `content/bcs4.md` (the Part preface) + `content/bcs.4.md` (the chapter
> doc). Figures verbatim from committed outputs; B4.5 in living-status voice (D-B4.2).

## Hero

**B4 · EchoCache — manuscript Part IV.** Reading is made cheap without making it wrong.

Part II gave the names a home and Part III put them in motion; Part IV makes reading them cheap without making
them wrong. **EchoCache** is a near-cache — an L1 of declared ETS tables in front of the L2 Valkey the systems
already share — and its one-line case is the part's title: branded keys, local speed, bus-driven coherence.

The comparison set is real and named — Valkey's own server-assisted client-side caching, Nebulex's near-cache
topology, Cachex beneath it — and every member shares one shape: **coherence is deletion**. The message says
*forget this key*; it carries no version, promises no order, leaves no record. EchoCache's coherence message says
something stronger — *a newer row exists for this name, minted at this time* — and because the version is a
branded identity, the receiver decides newer-wins by comparing two names. Coherence without coordination is the
identity theorem cashed a third time.

## The five modules

The Part is written through chapter 4.4; B4.1–B4.4 are buildable, each with a frozen `PASS 6/6` rung. B4.5 · The
Cache Referee waits for its manuscript chapter.

- **B4.1 · Cache-Aside at ETS Speed** — `cache-aside` — the declared L1 directory over L2 Valkey, three sources
  of one answer, single-flight fills, the jittered clock, the bound that degrades to pass-through. The rung
  reads `PASS 6/6`.
- **B4.2 · Coherence by Mint Time** — `coherence-by-mint-time` — the twenty-nine-byte message, newer-wins with
  teeth, the broadcast lane, the loss gated, the job lane that survives a crash, the price of the guarantee. The
  rung reads `PASS 6/6`.
- **B4.3 · The Single Writer and the Ring** — `single-writer-ring` — two atomic sequences over preallocated ETS
  slots, order through batches, occupancy as the gauge, drop as a counted refusal, the storm with the owner
  decoupled, convergence as a comparison. The rung reads `PASS 6/6`.
- **B4.4 · The Lane That Remembers** — `the-lane-that-remembers` — the per-group SQLite journal, two memories in
  one file, the crash seams closed, the bus dying and the lane replaying, coverage as compaction, the price of
  memory. The rung reads `PASS 6/6`.
- **B4.5 · The Cache Referee** — `cache-referee` — *manuscript pending*. The manuscript plans Nebulex, Cachex,
  and Valkey's server-assisted tracking measured where they run: hit-path latency, the herd drill, and
  coherence-lag distributions. A non-anchor `planned` card until `bcs4.5.md` ships.

## The laws of the part

Part IV states six laws and holds every chapter to them (source: `content/bcs4.md`).

- **The cache is declared, not discovered.** Every L1 table is declared per kind with its TTL, size bound, and
  coherence mode; the operator enumerates every cache in the node the way they enumerate stores.
- **One fill per herd.** Concurrent misses on a key coalesce onto a single in-flight fill; the herd reads the
  one answer. The thundering-herd drill is a gate, not an anecdote.
- **Coherence is a message about a name.** Invalidation carries the branded key and the writer's mint-time
  version, nothing else. Newer wins by comparing identities — no coordinator, no lock, no clock but the one
  already inside every id.
- **Two coherence lanes, named per surface.** The broadcast lane rides the bus's wake fabric for latency and
  accepts fire-and-forget delivery; the job-backed lane pays queue overhead to buy at-least-once. Each surface
  names which lane it rides.
- **The single writer applies the stream.** Per cache, coherence application is one owner draining an ordered
  ring — batched, allocation-light, race-free by construction.
- **Recovery is replay beside the bus, never WAL inside it.** Decision D-2 stands: the bus remains volatile. The
  memory that must survive a node lives in per-group journals beside the consumers, and recovery replays them.

## The floor under the floor

Part IV inherits a measured floor, not a hope (source: `content/bcs4.md`, quoting the Part III committed
records):

- the bus's committed `end-to-end median 0.3 ms bus vs 8.8 ms rival`;
- a parked consumer costs `0 commands` while it waits, so an invalidation lane is cheap to keep open;
- the conformance record's `fourteen of fourteen contracts hold` — a coherence message enqueued has gated, not
  assumed, delivery semantics;
- the torn-write drill landed `qty 12 once, never 17 -- and the order completes`, so a cache above the stores
  can be wrong only in the benign direction: stale for a bounded moment, never a fabricated row.

The four Part IV rung records on file (`content/echo_data/runtimes/elixir/`): `bcs_rung_4_1_check.out` `PASS 6/6`
· `bcs_rung_4_2_check.out` `PASS 6/6` · `bcs_rung_4_3_check.out` `PASS 6/6` · `bcs_rung_4_4_check.out` `PASS 6/6`.

## Up next

- **B5–B8 · Go, Node, Fly, Trading** — Parts V–VIII. The manuscript plans these chapters; the course builds them
  as the book ships.
- **B3 · The Bus** — Part III, the bus this cache's coherence rides.

## The doors

- **/echomq — EchoMQ, the protocol in depth** — the bus the coherence lanes ride, taught rung by rung.
- **/redis-patterns — Redis Patterns Applied** — the caching substrate (R1 cache-aside) under EchoCache.
- **/elixir — Functional Programming in Elixir** — the umbrella where echo_data, the production identity
  library, lives.

## References

Sources:

- Erlang/OTP — ets (the declared L1 tables; ordered traversal; protection levels): https://www.erlang.org/doc/apps/stdlib/ets.html
- Valkey — client-side caching (the comparison set's coherence-as-deletion contract): https://valkey.io/topics/client-side-caching/
- Lamport — Time, Clocks, and the Ordering of Events (the total order newer-wins carries in the name): https://dl.acm.org/doi/10.1145/359545.359563

Related:

- /bcs — BCS, the course home: the law, the id anatomy, the chapter map
- /bcs/bus — B3 · The Bus, the bus EchoCache's coherence rides
- /bcs/elixir-core — B2 · The Elixir BCS Core, the stores being cached
- /echomq — EchoMQ, the protocol in rung-level depth on the far side of the door
- /redis-patterns — Redis Patterns Applied, the caching substrate
- /elixir — Functional Programming in Elixir, the umbrella
