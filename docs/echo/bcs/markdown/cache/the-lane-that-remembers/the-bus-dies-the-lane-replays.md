# B4.4.2 · The Bus Dies; the Lane Replays

> Dive 2 of B4.4 · route `/bcs/cache/the-lane-that-remembers/the-bus-dies-the-lane-replays` · teaches H3–H4 of
> `content/bcs4.4.md`, quoting `bcs_rung_4_4_check.out`.

D-2 keeps the bus volatile on purpose, so a bus restart erases queued coherence jobs — Chapter 4.2 stated that
ceiling in the open, and the TTL was the floor under the loss. This dive raises the ceiling without touching the
decision. The H3 gate stops the table and the journal, reopens the same file against an empty L1, and proves the
applied memory outlives everything around it: `the journal remembered v5 across a full stop of table and
journal; the replayed old version answered :remembered_stale without touching the cache`. The H4 gate stages
D-2's loss itself — 50 intents recorded and enqueued, 20 applied, the lane's queue keys flushed — and the
journal replays the lane back: `exactly 30 uncovered intents re-enqueued in seq order under their recorded job
ids`, the applied memory closing at 50 of 50.

## §1 The transcript

This dive reads the memory derive, H3, the loss derive, and H4 (source:
`content/echo_data/runtimes/elixir/bcs_rung_4_4_check.out`; the record opens with H1–H2 and closes with H5–H6 —
the hub holds it whole):

```
derive (memory): the applied table lives in the file, so it survives the table, the node, and the bus; after a full restart with an empty L1, a replayed old version must answer :remembered_stale from the journal alone -- no cache row consulted, none created -- while a genuinely newer version passes through and updates the memory
H3 memory ok -- the journal remembered v5 across a full stop of table and journal; the replayed old version answered :remembered_stale without touching the cache -- the table's verdict counters did not move and no row appeared -- and the genuinely newer v6 passed through and became the new last word
derive (loss): D-2 keeps the bus volatile, so a bus restart erases queued coherence jobs; 50 intents recorded and enqueued, 20 applied before the loss, the lane's queue keys flushed -- replay must re-enqueue exactly the 30 uncovered intents in seq order, and a consumer must drain them to a remembered count of 50
H4 loss ok -- the bus restart erased the queue and the journal replayed the lane back: exactly 30 uncovered intents re-enqueued in seq order under their recorded job ids, the consumer drained them, and the applied memory closed at 50 of 50 names holding their final versions
```

## §2 The memory across a restart

The applied table lives in the file, so it survives the table, the node, and the bus. Without this memory, an
empty L1 makes every replayed message look fresh; with it, staleness is a fact about the lane, not about
whichever rows happen to be resident. The drill: stop the table and the journal, reopen the same file against an
empty L1, replay an old version — `:remembered_stale` from the journal alone, "no cache row consulted, none
created" — then deliver a genuinely newer version, which passes through and updates the memory. The gate's
verbatim close: "the table's verdict counters did not move and no row appeared -- and the genuinely newer v6
passed through and became the new last word."

The decision underneath: **the memory check runs before the cache.** `apply_and_remember` consults the journal
first and answers `:remembered_stale` without an ETS lookup, because the journal's word outlives the cache's
rows — the gate proves the counters do not move.

## §3 The loss drill — 50, 20, 30

D-2 keeps the bus volatile, so a bus restart erases queued coherence jobs. The rung stages exactly that: 50
intents recorded and enqueued, 20 applied before the loss, the lane's queue keys flushed. Replay selects by
coverage — every intent whose name lacks an applied version at least as new — so the twenty already-applied
intents are not re-sent and the thirty lost ones are, with no acknowledgment bookkeeping anywhere on the hot
path. The gate: "exactly 30 uncovered intents re-enqueued in seq order under their recorded job ids, the
consumer drained them, and the applied memory closed at 50 of 50 names holding their final versions."

Recovery, after the bus came back empty (source: `content/bcs4.4.md`, How):

```elixir
{:ok, %{replayed: n, deduplicated: m}} = Journal.replay(:limits_journal, conn)
{:ok, retired} = Journal.compact(:limits_journal)
```

Operators get `replay/2` as the recovery verb and `compact/1` as the retention verb, both idempotent, both safe
to run on a schedule. Replay is at-least-once by construction and harmless by comparison — the same two facts,
in the same order, as everywhere else in this part. The journal is per-group and per-node: it restores its own
lane's obligations and claims nothing about cross-group ordering, which the lanes never promised anyway.
Application on the consumer side is the engine the manuscript's previous chapter gated — **B4.3 · The Single
Writer and the Ring** — and the compaction predicate and the price close the module in the next dive.

## References

Sources:

- Richardson, C. — Pattern: Transactional outbox —
  https://microservices.io/patterns/data/transactional-outbox.html (the at-least-once relay this replay is)
- SQLite — Write-Ahead Logging — https://www.sqlite.org/wal.html (the file the applied memory survives in)
- Litestream — How it works — https://litestream.io/how-it-works/ (restore by snapshot plus replay — the
  off-box echo of this drill, named and not built)

Related:

- /bcs/cache/the-lane-that-remembers — B4.4 · The Lane That Remembers, the module hub; the full rung in context
- /bcs/cache — B4 · EchoCache, the chapter landing
- /bcs/bus/state-machine — B3.3 · The State Machine in Lua, the volatile bus, its lease, and its reaper
- /bcs/bus/jobs-are-entities — B3.2 · Jobs Are Entities, the recorded job ids the replay reuses
- /bcs/cache/coherence-by-mint-time — B4.2 · Coherence by Mint Time, the lane being replayed back
- /echomq — EchoMQ, the protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/cache/the-lane-that-remembers/two-memories-one-file` · next
`/bcs/cache/the-lane-that-remembers/coverage-and-the-price`.
