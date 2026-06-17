# B8.2.3 · The Double-Entry Ledger

> Dive 3 of B8.2 · route `/bcs/trading/log-and-ledger/the-double-entry-ledger` · teaches
> `docs/trading/trading.specs.md` (the regulated ledger — Postgres double-entry, `Ecto.Multi`, the stream the
> source of truth for unsettled / Postgres for settled) + `docs/trading/trading.roadmap.md` (TRD.3, TRD.5).
> **Grounding:** compaction and the price are as-built — `echo/apps/echo_cache/lib/echo_cache/journal.ex` — every
> figure verbatim from `bcs_rung_4_4_check.out` (`PASS 6/6`), source-labelled. `Trading.Ledger` and
> `Exchange.Projection` are **PROPOSED** (`docs/trading/`). No platform number invented. The priced pair `524 µs ↔
> 148 µs` is kept intact.

The double-entry ledger.

The platform keeps two records and decides, in the open, which holds which truth. The **stream** — the journal's
log of fills — is the source of truth for *unsettled* state; the **Postgres ledger** is the regulated record of
*settled* positions. Settled money posts double-entry, every posting one `Ecto.Multi`. The compaction that keeps
the log small is as-built `EchoCache.Journal` behavior, quoted from its record; the **`Trading.Ledger`** that posts
the settled side is a **PROPOSED** design object (`docs/trading/trading.specs.md`), taught as design and never as a
measured result.

Source: compaction (`compact(j)`) and the writer's price are real Elixir at
`echo/apps/echo_cache/lib/echo_cache/journal.ex`, recorded in
`content/echo_data/runtimes/elixir/bcs_rung_4_4_check.out`. `Trading.Ledger` and `Exchange.Projection` are
**PROPOSED** (`docs/trading/`).

Interactive 1 (hero): a double-entry poster — a fill posts two balanced entries (a debit and a credit) inside one
`Ecto.Multi`; the readout checks that the postings sum to zero and that a malformed posting aborts the whole
multi. The shape is **PROPOSED** design; no number is claimed.

## §1 Compaction is coverage — the outbox empties, the memory does not

The same coverage predicate that drives replay retires the outbox: an intent is retired when its name carries an
applied version at least as new — coverage, not acknowledgment (source: the H5 derivation,
`bcs_rung_4_4_check.out`). After the loss drill closed at 50 of 50, all 50 intents are deletable, the applied
memory keeps all 50 names, replay finds nothing, and a reopen still remembers. The committed gate:
`all 50 intents retired by coverage in one pass, the applied memory kept its 50 names, replay over the compacted
journal found nothing to do, and a fresh open of the same file still answers the last word -- the outbox empties,
the memory does not`.

`compact(j)` is the retention verb, idempotent and safe to run on a schedule; the outbox stays small, the last
word per name persists. Intents are small, coverage is one SQL pass, and an outbox kept under a few thousand rows
replays in milliseconds.

## §2 The price of memory

The journal's durability is not free, and the record prices it exactly (source: the H6 derivation,
`bcs_rung_4_4_check.out`). On prepared-once statements — the single writer's privilege, with bind resetting the
statement — the writer's pair is two WAL commits and one cached rowid read at `synchronous=NORMAL`. The committed
gate:
`the memory's price on this disk: 143 us per record-and-mark pair at the writer's edge, and a remembered lane
end-to-end median of 524 us against the bare lane's committed 148 us -- 3.5 times the latency buys an outbox, a
last word per name, and a replay that survives the bus`.

The priced pair is **`524 µs`** (the remembered lane's end-to-end median) against the bare lane's committed
**`148 µs`** — the two numbers travel together, and `143 µs` is the record-and-mark pair at the writer's edge. At
`synchronous=NORMAL` the WAL issues no per-commit sync — the checkpoint is the sole I/O barrier — which is the
journal's speed and its stated power-loss trade. The numbers carry their header: one scheduler, this container's
disk, a 29-byte payload; the 3.5 multiple travels better than the 143.

Interactive 2: a price bar over the H6 record — the bare lane's committed `148 µs`, the remembered lane's `524 µs`
median, and the `143 µs` record-and-mark pair, drawn to scale with the 3.5× multiple labelled. Every value is the
record's own; no platform number is added.

## §3 The regulated ledger — PROPOSED

The settled side is the design's `Trading.Ledger` (`docs/trading/trading.specs.md`), status **PROPOSED**.
Double-entry in Postgres: branded id columns under the SQL canon with the domain's reject table as the floor,
every posting one `Ecto.Multi` — a single all-or-nothing transaction, so a fill either posts both entries or
neither. The directional decision is named in the spec and revisitable only by editing the spec: the stream (the
journal, then milestone-B stream lanes) is the source of truth for *unsettled* state; the Postgres ledger is the
regulated record of *settled* positions.

`Exchange.Projection` (also **PROPOSED**) is the idempotent log consumer that folds the log into Tables — the read
path the platform serves positions and balances from. Both modules are taught as design; neither has a rung yet,
and so neither claims a latency, throughput, or posting number. The first such number lands when the first rung's
harness runs (`docs/trading/trading.roadmap.md`, TRD.3 and TRD.5).

## §4 Why the split, weighed

The two-store decision is argued, not assumed. **One Postgres ledger for everything** — regulated and queryable,
but every unsettled tick becomes a synchronous SQL write on the hot path, where the fold of an in-memory log
answers for free. **One stream for everything, no Postgres** — replayable and fast, but a regulated record of
settled money wants the SQL canon's constraints, the reject table, and the audit a relational ledger gives. The
design splits the difference along the settlement boundary: unsettled state where replay is cheap, settled money
where regulation is required, the boundary named in the spec. The Postgres canon the ledger posts to is the
substrate of `/redis-patterns` and `/elixir`; the stream lanes the unsettled log moves to are `/echomq`.

## References

Sources:

- Richardson — Pattern: Transactional outbox — https://microservices.io/patterns/data/transactional-outbox.html (the outbox the journal compacts; coverage retires it without acknowledgment)
- SQLite — Write-Ahead Logging — https://www.sqlite.org/wal.html (at synchronous NORMAL the checkpoint is the sole sync barrier — the journal's speed and the price this dive quotes)
- Litestream — How it works — https://litestream.io/how-it-works/ (the off-box replica that completes the journal's durability story beside the box)

Related:

- /bcs/trading/log-and-ledger — B8.2 · The Log and the Ledger, the module hub
- /bcs/cache/the-lane-that-remembers — B4.4 · The Lane That Remembers, the journal and the price quoted here
- /bcs/cache — B4 · EchoCache, the chapter the journal lives in
- /bcs/bus — B3 · The Bus, the work lanes settlement jobs drain
- /elixir — Functional Programming in Elixir, the umbrella and the SQL canon
- /redis-patterns — Redis Patterns Applied, the durable-memory substrate

Pager: previous `/bcs/trading/log-and-ledger/replay-equals-live` · next `/bcs/trading/log-and-ledger` (back to the hub).
