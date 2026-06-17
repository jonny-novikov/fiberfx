# B4.4 · The Lane That Remembers

> Module hub · route `/bcs/cache/the-lane-that-remembers` · teaches `content/bcs4.4.md` · the rung is
> `bcs_rung_4_4_check.exs`, its committed record `bcs_rung_4_4_check.out` closes `PASS 6/6`.

The journal beside the bus: an outbox of intents, a last word per name, and a replay that survives the bus.

Chapter 4.2 priced the job lane's guarantee and then stated its ceiling in the open: the bus is volatile by
decision D-2, so a bus restart erases the lane's queued obligations, and the TTL is the floor under the loss.
This chapter raises the ceiling without touching the decision. The part's sixth law — recovery is replay beside
the bus, never WAL inside it — lands as one production module, `EchoCache.Journal`: a per-group SQLite file
holding two memories, the outbox of intents at the writer's edge and the last applied version per name at the
applier's edge. The committed record closes every crash seam with machinery that already exists, replays a lane
back into existence after a staged bus loss, and prices the memory on one row: `143 us per record-and-mark pair
at the writer's edge, and a remembered lane end-to-end median of 524 us against the bare lane's committed 148 us
-- 3.5 times the latency buys an outbox, a last word per name, and a replay that survives the bus`.

## §1 The outbox, BCS-armed

The dual-write trap waits on either side of the obvious fix: write the store, then enqueue, and a crash between
them loses the message; enqueue, then write, and a crash between them announces a write that never happened. The
literature's answer is Richardson's transactional outbox — record the intent in local durable storage first,
relay it to the broker after, and accept that the relay may deliver twice, so consumers "must be idempotent".
This series is unusually well-armed for that acceptance: "the bus already deduplicates a job id at admission,
and newer-wins already makes a re-applied version a no-op. What was missing was only the durable intent and the
durable memory of application." The law's wording is exact: "the bus gets no WAL; the journal, which is not the
bus, gets SQLite's."

The chapter's decisions:

- **One journal, one owner.** The single writer as a storage discipline: every statement runs in one process,
  which is what makes prepared-once statements trivially safe and SQLite's single-writer nature a fit instead of
  a fight.
- **Coverage, not acknowledgment.** An intent is retired when its name carries an applied version at least as
  new. The hot path pays no per-intent completion write; replay and compaction share one predicate.
- **Replay reuses recorded job ids.** Minting fresh ids on replay would defeat the bus's admission dedup;
  reusing the recorded id lets the bus answer `:duplicate` for whatever survived, which the record counts in
  the open.
- **`mark_enqueued` is a separate call on purpose.** Folding it into the enqueue would erase the seam the drill
  exists to cover; "the outbox pattern's candor is that the seams are real".
- **The memory check runs before the cache.** `apply_and_remember` consults the journal first and answers
  `:remembered_stale` without an ETS lookup, because the journal's word outlives the cache's rows.
- **The journal's WAL is beside the bus.** D-2 stands untouched: the bus remains volatile, restart semantics
  remain replay, and durability lives in a file the bus never touches.

The writer's edge, one verb (source: `content/bcs4.4.md`, How):

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

## §2 The proof

The full committed transcript, verbatim — the opening self-check line, the header naming SQLite, the derive
lines, the six gates (source: `content/echo_data/runtimes/elixir/bcs_rung_4_4_check.out`):

```
02:15:17.826 [info] EchoData: contract self-check passed, codec=pure
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

The opening `[info]` line and the SQLite header are part of the record — the runtime's mix project grew its
first compiled dependency for this rung (`exqlite`, vendored as path deps under `runtimes/elixir/vendor/`, the
NIF compiled from the bundled SQLite amalgamation), and the rung runs under `MIX_ENV=prod mix run`, the first
cache rung to do so. One production module lands: `runtimes/elixir/lib/echo_cache/journal.ex`; the file per
group is `journal-<group>.db` under the declared directory.

## §3 The dives

1. **Two Memories, One File** (`two-memories-one-file`) — H1, the surface: one journal file per group named by
   the group's branded id, a non-branded group refused at the door, the schema carrying "intents (the outbox)
   and applied (the lane's last word per name)"; H2, both crash seams closed — Richardson's outbox with the
   bus's own dedup, and "once coverage is total, replay is exactly %{replayed: 0, deduplicated: 0}".
2. **The Bus Dies; the Lane Replays** (`the-bus-dies-the-lane-replays`) — H3, the memory across a full restart:
   `:remembered_stale` without touching the cache; H4, the loss drill — "exactly 30 uncovered intents
   re-enqueued in seq order", the applied memory closing at 50 of 50.
3. **Coverage and the Price** (`coverage-and-the-price`) — H5, compaction: "the outbox empties, the memory does
   not"; H6, the price — `143 us per record-and-mark pair`, the remembered lane's `524 us` against the bare
   lane's committed 148 us, "3.5 times the latency buys an outbox, a last word per name, and a replay that
   survives the bus"; the prepared-statements fix the gate forced.

## References

Sources:

- Richardson, C. — Pattern: Transactional outbox —
  https://microservices.io/patterns/data/transactional-outbox.html (the outbox's contract and its crash seams;
  the relay may deliver twice, so consumers "must be idempotent")
- SQLite — Write-Ahead Logging — https://www.sqlite.org/wal.html (the journal's commit path and the NORMAL
  trade)
- Litestream — How it works — https://litestream.io/how-it-works/ (the off-box durability layer, named and
  deliberately not implemented)

Related:

- /bcs/cache — B4 · EchoCache, the chapter landing; Part IV's arc
- /bcs/cache/coherence-by-mint-time — B4.2 · Coherence by Mint Time, the job lane the journal stands beside
- /bcs/cache/single-writer-ring — B4.3 · The Single Writer and the Ring, the applier this journal's replay feeds
- /bcs/bus/jobs-are-entities — B3.2 · Jobs Are Entities, the admission dedup that absorbs the re-enqueued job id
- /bcs/bus/state-machine — B3.3 · The State Machine in Lua, the volatile bus and its reaper
- /bcs/bus — B3 · The Bus, Part III's arc
- /bcs/elixir-core/property-stores — B2.2 · Property Stores on ETS, the stores being cached
- /echomq — EchoMQ, the protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/cache` · next `/bcs/cache/the-lane-that-remembers/two-memories-one-file`.
