# B8.2 · The Log and the Ledger

> Module hub for `/bcs/trading/log-and-ledger`, the second module of the capstone. Bootstrapped from the built
> B8.1 hub `engine` — the events the engine emits land here. **Grounding posture (the B8 rule):** two layers,
> never confused. The memory layer is **real, shipped, actively-hardened Elixir**: `EchoCache.Journal` lives in
> the live umbrella at `echo/apps/echo_cache/lib/echo_cache/journal.ex` under the pluggable `EchoCache.Shadow`
> behaviour (`shadow.ex`, with `EchoCache.Litestream` and `EchoCache.Shadow.Copy`), and its behavior is on the
> committed B4.4 record (`content/bcs4.4.md`, `bcs_rung_4_4_check.out`, `PASS 6/6`). Every journal figure is
> verbatim from there, source-labelled. What is **PROPOSED** is the trading **ledger** that stands on the
> substrate — `Trading.Ledger` (double-entry in Postgres, one `Ecto.Multi` per posting) and `Exchange.Projection`
> (idempotent log consumers into Tables) (`docs/trading/`): taught in design voice, with no platform number,
> because the ledger has run no rung yet. The journal's numbers are real; the ledger's are not yet (BCS.8-INV2).

## Hero

**B8.2 · The Log and the Ledger — manuscript Part VIII, the trading corpus.** The engine emits facts. This module
is where those facts are kept, replayed, and settled.

A trading platform keeps two kinds of memory, and they belong in two different places. The **stream** — the
append-only log of every fill — is the source of truth for *unsettled* state, and recovery from it is replay, not
a feature. The **ledger** — settled money, posted double-entry — is the regulated record of *settled* positions.
The log layer is the as-built `EchoCache.Journal` under a pluggable `EchoCache.Shadow`, quoted from its committed
B4.4 record; the regulated **`Trading.Ledger`** is a **PROPOSED** design object (`docs/trading/`), taught as
design and never as a measured result.

## The two memories in one file

The journal carries two memories, and the schema is the cargo law (source: `bcs_rung_4_4_check.out`,
`content/bcs4.4.md`). The **intents** table is Richardson's transactional outbox — the recorded job id, the name,
the version, an enqueued flag; the writer records the intent before the bus hears it, marks it after. The
**applied** table is the lane's last word per name — the newest version this lane has ever applied, surviving the
table, the node, and the bus. The committed gate fixes it: `one journal file per group, named by the group's
branded id ... the schema carries the two memories: intents (the outbox) and applied (the lane's last word per
name)`.

## The as-built memory — the journal, committed

The module invents nothing under the memory layer. `EchoCache.Journal` is real Elixir in the live umbrella
(`echo/apps/echo_cache/lib/echo_cache/journal.ex`), one per group, owned by one process — the single writer of
Chapter 4.3 as a storage discipline. Its committed behavior is the whole six-gate record, quoted verbatim
(source: `content/echo_data/runtimes/elixir/bcs_rung_4_4_check.out`, `PASS 6/6`):

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

These are the **as-built journal's** committed numbers — the memory layer the PROPOSED ledger stands on — never
the trading platform's own. The ledger has produced no rung yet; the platform's first number lands when the first
rung's harness runs.

## The shadow, pluggable

The off-box layer is named and pluggable. `EchoCache.Shadow` is a behaviour
(`echo/apps/echo_cache/lib/echo_cache/shadow.ex`): one contract — `start_link/1`, `restore/1` returning
`{:ok, :restored | :no_replica}`, `status/1`, `stop/1` — with two implementations. `EchoCache.Litestream`
(`litestream.ex`) replicates each per-group journal to S3-compatible object storage and restores before the
journal reopens; `EchoCache.Shadow.Copy` snapshots to a local directory on a development laptop. The supervisor
and the restore path never know which one is wired — the same contract either way. The kind law holds at the
shadow's door: a non-branded group is refused.

## The regulated ledger — PROPOSED

The settled side is the design's `Trading.Ledger` (`docs/trading/trading.specs.md`), status **PROPOSED**: settled
money posts double-entry in Postgres, branded id columns under the SQL canon, every posting one `Ecto.Multi` — a
single all-or-nothing transaction per posting. The decision is named in the spec: the stream is the source of
truth for *unsettled* state, the Postgres ledger the regulated record of *settled* positions. `Exchange.Projection`
(also PROPOSED) folds the log idempotently into Tables. Both are taught as design; neither has a rung yet, and so
neither claims a number.

## The three dives

- **B8.2.1 · The Journal and the Shadow** — `the-journal-and-the-shadow` — one `EchoCache.Journal` per book,
  named by its branded id; the two memories (intents/outbox + applied/last-word); both crash seams closed by
  machinery that already exists — the never-enqueued intent replayed, the enqueued-but-unmarked one answered
  `:duplicate` at admission; `replay is exactly %{replayed: 0, deduplicated: 0}` when coverage is total; the
  pluggable `EchoCache.Shadow` (Litestream off-box / Copy on a laptop, the same contract).
- **B8.2.2 · Replay Equals Live** — `replay-equals-live` — state *is* the fold of the log; the journal remembers
  across a full restart (`:remembered_stale` from the journal alone, no cache row touched; v5 → v6); the loss
  drill over the fixed 50/20/30 (`exactly 30 uncovered intents re-enqueued in seq order`, `50 of 50`); recovery
  is replay, the Chapter 4.4 posture re-gated per book — the **PROPOSED** `Exchange.Book` inherits a certified
  mechanic.
- **B8.2.3 · The Double-Entry Ledger** — `the-double-entry-ledger` — compaction (`the outbox empties, the memory
  does not`); the **PROPOSED** `Trading.Ledger`: settled money posts double-entry in Postgres, one `Ecto.Multi`
  per posting; the stream the source of truth for *unsettled*, the Postgres ledger for *settled*; the H6 price
  pair (`524 µs ↔ 148 µs`, `143 µs` record-and-mark).

## The doors

- **/echomq — EchoMQ, the protocol in depth** — the bus the log rides, and the stream lanes the log moves to at
  milestone B.
- **/redis-patterns — Redis Patterns Applied** — the substrate: the outbox, the durable memory, the single-writer
  move.
- **/elixir — Functional Programming in Elixir** — the umbrella the journal and shadow live in, and the functional
  fold replay is.

## References

Sources:

- Richardson — Pattern: Transactional outbox (record the intent locally first, relay to the broker after; the
  relay may deliver twice, so consumers must be idempotent — the outbox the journal's `intents` table is):
  https://microservices.io/patterns/data/transactional-outbox.html
- SQLite — Write-Ahead Logging (the WAL commit path and checkpointing; at synchronous NORMAL the checkpoint is the
  sole sync barrier — the journal's speed and its stated power-loss trade): https://www.sqlite.org/wal.html
- Litestream — How it works (a separate process copies WAL pages to replicas and restores by snapshot plus replay
  — the off-box `EchoCache.Litestream` shadow): https://litestream.io/how-it-works/

Related:

- /bcs/trading — B8 · The Trading System, the chapter landing
- /bcs/trading/engine — B8.1 · The Engine, the engine whose events land in this log
- /bcs/cache/the-lane-that-remembers — B4.4 · The Lane That Remembers, the as-built journal quoted here
- /bcs/cache — B4 · EchoCache, the cache the journal's memory outlives
- /bcs/bus — B3 · The Bus, the work lanes the journal's outbox feeds
- /bcs/elixir-core — B2 · The Elixir BCS Core, the functional core replay is the fold of
- /echomq — EchoMQ, the protocol in depth
- /redis-patterns — Redis Patterns Applied, the substrate
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/trading` (B8 · The Trading System) · next `/bcs/trading/log-and-ledger/the-journal-and-the-shadow`.
