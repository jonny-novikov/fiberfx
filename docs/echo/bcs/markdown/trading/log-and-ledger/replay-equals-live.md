# B8.2.2 · Replay Equals Live

> Dive 2 of B8.2 · route `/bcs/trading/log-and-ledger/replay-equals-live` · teaches
> `docs/trading/trading.specs.md` (the master invariant — state reconstructable as a fold over the log) +
> `docs/trading/trading.roadmap.md` (TRD.3, TRD.5). **Grounding:** the replay and the loss drill are as-built —
> `echo/apps/echo_cache/lib/echo_cache/journal.ex` — every figure verbatim from `bcs_rung_4_4_check.out` (`PASS
> 6/6`), source-labelled. The `Exchange.Book` that inherits the mechanic is **PROPOSED**. No platform number
> invented.

Replay equals live.

The master invariant of the platform reads: one instrument's book is reconstructable as a fold over an
append-only event log (`docs/trading/trading.specs.md`). State is not a thing kept beside the log — state *is* the
fold of the log. Recovery is therefore replay, not a feature bolted on afterward. The as-built `EchoCache.Journal`
already proves the posture on the job lane, and the **PROPOSED** `Exchange.Book` inherits a certified mechanic
rather than inventing one.

Source: the replay verb `replay(j, conn)` and the memory check `apply_and_remember` are real Elixir at
`echo/apps/echo_cache/lib/echo_cache/journal.ex`, taught in `content/bcs4.4.md`, recorded in
`content/echo_data/runtimes/elixir/bcs_rung_4_4_check.out`. The per-instrument `Exchange.Book` that owns one
journal is **PROPOSED** (`docs/trading/trading.specs.md`).

Interactive 1 (hero): a restart-and-remember stepper — fold a fixed name through a full stop of table and journal,
then replay an old version (`:remembered_stale` from the journal alone, no cache row touched) and a genuinely
newer one (the new last word) — v5 then v6, the H3 record's own values.

## §1 The journal remembers what the cache forgot

The applied table lives in the file, so it survives the table, the node, and the bus (source: the H3 derivation,
`bcs_rung_4_4_check.out`). After a full restart with an empty L1, a replayed old version must answer
`:remembered_stale` from the journal alone — no cache row consulted, none created — while a genuinely newer
version passes through and updates the memory. The committed gate:
`the journal remembered v5 across a full stop of table and journal; the replayed old version answered
:remembered_stale without touching the cache -- the table's verdict counters did not move and no row appeared --
and the genuinely newer v6 passed through and became the new last word`.

Without this memory, an empty L1 makes every replayed message look fresh; with it, staleness is a fact about the
lane, not about whichever rows happen to be resident. The memory check runs before the cache: `apply_and_remember`
consults the journal first and answers `:remembered_stale` without an ETS lookup, because the journal's word
outlives the cache's rows.

## §2 The bus dies; the lane replays

The bus is volatile by D-2, so a bus restart erases queued coherence jobs. The loss drill stages exactly that
(source: the H4 derivation, `bcs_rung_4_4_check.out`): 50 intents recorded and enqueued, 20 applied before the
loss, the lane's queue keys flushed. Replay must re-enqueue exactly the 30 uncovered intents in seq order, and a
consumer must drain them to a remembered count of 50. The committed gate:
`the bus restart erased the queue and the journal replayed the lane back: exactly 30 uncovered intents re-enqueued
in seq order under their recorded job ids, the consumer drained them, and the applied memory closed at 50 of 50
names holding their final versions`.

Replay selects by coverage — every intent whose name lacks an applied version at least as new — so the 20
already-applied intents are not re-sent and the 30 lost ones are, with no acknowledgment bookkeeping anywhere on
the hot path. Replay reuses the recorded job ids, so the bus answers `:duplicate` for whatever it still holds,
which the record counts in the open.

Interactive 2: a loss-drill ledger over the fixed 50/20/30 — record 50, apply some, flush the bus, replay — and
read the counts the journal's coverage predicate produces (uncovered re-enqueued, applied closing at 50 of 50),
the H4 record's own arithmetic.

## §3 Coverage, not acknowledgment

The same predicate drives replay and the dedup floor: an intent is uncovered when its name carries no applied
version at least as new. The hot path pays no per-intent completion write — there is no acknowledgment row to
maintain. This is the design's reach: the replay property — folding the log reproduces live state — is the
Chapter 4.4 posture re-gated per book (`docs/trading/trading.specs.md`, the master invariant's mechanics). What
the journal proves on the job lane, the PROPOSED `Exchange.Book` reuses for its instrument's log: kill the book,
restart, replay equals live.

## §4 Recovery is replay — the alternatives weighed

The posture is chosen against named alternatives. **A WAL inside the bus** — the obvious place to put durability,
and the one the law forbids: the bus stays volatile by D-2, and durability lives in a file the bus has never heard
of, which keeps the bus a fan-out primitive and not a log. **A dual-write to a store, then the bus** — a crash
between the two writes loses the message or announces a write that never happened; the outbox closes both seams by
recording the intent first and relaying after. **A canonical store the book reads back on every command** — a
round trip on the hot path, where the fold of an in-memory log answers for free. Recovery as replay costs a price
this module measures in dive 3 — `524 µs ↔ 148 µs` end to end — and that price buys an outbox, a last word per
name, and a replay that survives the bus.

The fold that *is* live state is written in the functional core the platform is built in (`/elixir`); the bus the
log moves to at milestone B is the stream lanes of `/echomq`.

## References

Sources:

- Richardson — Pattern: Transactional outbox — https://microservices.io/patterns/data/transactional-outbox.html (the outbox closes the dual-write seams; the relay may deliver twice, absorbed by admission dedup)
- SQLite — Write-Ahead Logging — https://www.sqlite.org/wal.html (the WAL the journal's durability rides; the replay reads from the same file)
- Litestream — How it works — https://litestream.io/how-it-works/ (restore by snapshot plus replay — the off-box recovery verb the node-death drill runs first)

Related:

- /bcs/trading/log-and-ledger — B8.2 · The Log and the Ledger, the module hub
- /bcs/cache/the-lane-that-remembers — B4.4 · The Lane That Remembers, the replay posture re-gated per book
- /bcs/cache — B4 · EchoCache, the cache the journal's memory outlives
- /bcs/bus — B3 · The Bus, the volatile bus the lane replays onto
- /elixir — Functional Programming in Elixir, the functional fold replay is
- /echomq — EchoMQ, the protocol in depth — the stream lanes the log moves to

Pager: previous `/bcs/trading/log-and-ledger/the-journal-and-the-shadow` · next `/bcs/trading/log-and-ledger/the-double-entry-ledger`.
