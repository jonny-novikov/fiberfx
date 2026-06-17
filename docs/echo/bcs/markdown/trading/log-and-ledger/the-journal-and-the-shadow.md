# B8.2.1 · The Journal and the Shadow

> Dive 1 of B8.2 · route `/bcs/trading/log-and-ledger/the-journal-and-the-shadow` · teaches
> `docs/trading/trading.specs.md` (the log — the Journal per book, the Shadow, milestone-A event store) +
> `docs/trading/trading.roadmap.md` (TRD.3). **Grounding:** the journal and the shadow are as-built Elixir in the
> live umbrella — `echo/apps/echo_cache/lib/echo_cache/journal.ex` and `shadow.ex` — every figure verbatim from
> `bcs_rung_4_4_check.out` (`PASS 6/6`), source-labelled. The drainer `Exchange.Book` is **PROPOSED**. No platform
> number invented.

The journal and the shadow.

A trading platform's log answers one obligation: every fill must survive the bus. The bus is volatile by decision
D-2 — a restart erases its queued jobs — so durability lives beside the bus, not inside it. The as-built
`EchoCache.Journal` is that durability: a per-group SQLite file holding two memories, the outbox of intents at the
writer's edge and the last applied version per name at the applier's edge. The committed gate fixes the schema:
`one journal file per group, named by the group's branded id ... the schema carries the two memories: intents (the
outbox) and applied (the lane's last word per name)`.

Source: the journal is real Elixir at `echo/apps/echo_cache/lib/echo_cache/journal.ex`, taught in
`content/bcs4.4.md`, its record `content/echo_data/runtimes/elixir/bcs_rung_4_4_check.out`. The book that owns one
per instrument, `Exchange.Book`, is **PROPOSED** (`docs/trading/trading.specs.md`).

The as-built surface, quoted from source: `start_link/1`; `record(j, job_id, name_id, version)` — "the writer's
first edge: record the intent before the bus hears it"; `mark_enqueued(j, job_id)` — "the writer's second edge:
the bus accepted this intent"; `record_many(j, triples)` — group commit, one WAL append amortized across a batch;
`intend_and_enqueue(j, conn, name_id, version)` — "the outbox in one verb: mint a job id, record the intent,
enqueue on the bus, mark it enqueued"; `replay(j, conn)`; `compact(j)` — "retire every intent whose name carries
an applied version at least as new". The handler `handler(j, table)` is "a consumer handler wiring the job lane
through the journal's memory".

Interactive 1 (hero): a two-memories schema viewer — select **intents** (the outbox) or **applied** (the lane's
last word per name) to read its columns and its role over a fixed two-name example, computed from the schema.

## §1 The two memories, in one file

The `intents` table is Richardson's transactional outbox: `seq`, the recorded `job_id`, the `name_id`, the
`version`, an `enqueued` flag, a `recorded_at` — the cargo law in a schema, nothing else. The `applied` table is
the lane's last word: `name_id` primary key, the newest `version`, its `seq`. The applied table lives in the file,
so it survives the table, the node, and the bus (source: the H3 derivation, `bcs_rung_4_4_check.out`).

Two doors, one law: a non-branded group is refused (`a non-branded group is refused at the door`). One journal
file per group, one owner process per journal — the single writer of Chapter 4.3 as a storage discipline, which
is what makes prepared-once statements trivially safe.

## §2 Both crash seams, closed by what already exists

The writer's flow is record, enqueue, mark — two crash seams (source: the H2 derivation,
`bcs_rung_4_4_check.out`). A death before the enqueue leaves a pending intent that replay enqueues. A death after
the enqueue but before the mark leaves the bus holding the job, and replay's reuse of the recorded job id lets the
bus's own admission dedup absorb it. Neither seam needs new machinery: the bus already deduplicates a job id at
admission (Richardson's at-least-once relay), and newer-wins already makes a re-applied version a no-op.

The committed gate closes both at once:
`both crash seams closed by machinery that already exists: the never-enqueued intent replayed onto the bus, the
enqueued-but-unmarked one answered :duplicate at admission and was counted, both ended in the applied memory -- and
once coverage is total, replay is exactly %{replayed: 0, deduplicated: 0}`.

Interactive 2: a two-seams walk — step a recorded intent through the writer's flow, choose a death point (before
the enqueue, or after the enqueue before the mark), and read what replay does — re-enqueue, or `:duplicate` at
admission — drawn from the H2 record.

## §3 The journal's WAL is beside the bus, not inside it

The law's wording is exact: the bus gets no WAL; the journal, which is not the bus, gets SQLite's. D-2 stands
untouched — the bus stays volatile, restart semantics stay replay, and durability lives in a file the bus has
never heard of. The journal runs `PRAGMA journal_mode=WAL`, `synchronous=NORMAL`, `busy_timeout=5000` — the last
because the shadow takes brief write locks at checkpoint and the journal waits rather than errors. `mark_enqueued`
is a separate call on purpose: folding it into the enqueue would erase the seam the drill exists to cover.

## §4 The shadow, pluggable behind one contract

The off-box layer is named and pluggable, not built into the journal. `EchoCache.Shadow`
(`echo/apps/echo_cache/lib/echo_cache/shadow.ex`) is a behaviour: `@callback start_link/1`; `@callback restore/1`
returning `{:ok, :restored | :no_replica} | {:error, term}`, restore-if-missing so an existing live file is never
overwritten; `@callback status/1`; `@callback stop/1`. Two implementations honour it:

- **`EchoCache.Litestream`** (`litestream.ex`) — the off-box replicator: one server covers one journal directory,
  renders a Litestream config naming each per-group database and its replica URL, and spawns the binary under a
  monitored Port. `restore/1` rebuilds a group's database file from its replica before the journal reopens — the
  first line of the node-death runbook. The kind law holds here too: `the shadow refuses a non-branded group`.
- **`EchoCache.Shadow.Copy`** — the laptop shadow: `VACUUM INTO` snapshots to a local directory, zero binaries,
  zero credentials, runs anywhere Exqlite runs.

Wire by tuple: `{EchoCache.Litestream, dir: ..., bucket: ...}`, `{EchoCache.Shadow.Copy, db: ..., dir: ...}`, or
`:none`. The supervisor and the restore path never know which one is wired — the same contract either way. The
milestone-A event store is the journal under a shadow; the move to per-instrument stream lanes is milestone B, the
conn.1–conn.2 recorded dependency (`docs/trading/trading.specs.md`).

## References

Sources:

- Richardson — Pattern: Transactional outbox — https://microservices.io/patterns/data/transactional-outbox.html (record the intent locally first, relay after; the relay may deliver twice — the journal's `intents` outbox)
- SQLite — Write-Ahead Logging — https://www.sqlite.org/wal.html (the WAL commit path; at synchronous NORMAL the checkpoint is the sole sync barrier — the journal's `journal_mode=WAL` and `synchronous=NORMAL`)
- Litestream — How it works — https://litestream.io/how-it-works/ (a separate process copies WAL pages to replicas and restores by snapshot plus replay — the `EchoCache.Litestream` shadow)

Related:

- /bcs/trading/log-and-ledger — B8.2 · The Log and the Ledger, the module hub
- /bcs/cache/the-lane-that-remembers — B4.4 · The Lane That Remembers, the as-built journal quoted here
- /bcs/cache — B4 · EchoCache, the chapter the journal lives in
- /bcs/bus — B3 · The Bus, the work lanes the outbox feeds
- /redis-patterns — Redis Patterns Applied, the outbox substrate
- /elixir — Functional Programming in Elixir, the umbrella the journal and shadow live in

Pager: previous `/bcs/trading/log-and-ledger` (the hub) · next `/bcs/trading/log-and-ledger/replay-equals-live`.
