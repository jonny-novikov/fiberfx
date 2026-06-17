# B4.4.1 · Two Memories, One File

> Dive 1 of B4.4 · route `/bcs/cache/the-lane-that-remembers/two-memories-one-file` · teaches H1–H2 of
> `content/bcs4.4.md`, quoting `bcs_rung_4_4_check.out`.

One SQLite file per group, owned by one process, standing beside the bus — and inside it, two memories: the
`intents` table is the outbox at the writer's edge, the `applied` table is the lane's last word per name at the
applier's edge. The literature's answer to the dual-write trap is Richardson's transactional outbox — record the
intent in local durable storage first, relay it to the broker after, and accept that the relay may deliver
twice, so consumers "must be idempotent". This series is unusually well-armed for that acceptance: "the bus
already deduplicates a job id at admission, and newer-wins already makes a re-applied version a no-op. What was
missing was only the durable intent and the durable memory of application." The law's wording is exact: "the bus
gets no WAL; the journal, which is not the bus, gets SQLite's."

## §1 The transcript

This dive reads the opening of the record — the self-check line, the header naming SQLite, H1, the windows
derive, and H2 (source: `content/echo_data/runtimes/elixir/bcs_rung_4_4_check.out`; H3–H6 follow — the hub
holds the record whole):

```
02:15:17.826 [info] EchoData: contract self-check passed, codec=pure
header: Valkey 9.1.0 on 6390 | SQLite 3.46.0 via exqlite, WAL, synchronous=NORMAL | Elixir 1.14.0 OTP 25 | schedulers 1
H1 files ok -- one journal file per group, named by the group's branded id -- two groups, two files on disk -- a non-branded group is refused at the door, and the schema carries the two memories: intents (the outbox) and applied (the lane's last word per name)
derive (windows): the writer's flow is record, enqueue, mark -- two crash seams; a death before the enqueue leaves a pending intent that replay enqueues; a death after the enqueue but before the mark leaves the bus holding the job, and replay's reuse of the recorded job id lets the bus's own admission dedup absorb it; full coverage by the applied memory makes replay a no-op
H2 windows ok -- both crash seams closed by machinery that already exists: the never-enqueued intent replayed onto the bus, the enqueued-but-unmarked one answered :duplicate at admission and was counted, both ended in the applied memory -- and once coverage is total, replay is exactly %{replayed: 0, deduplicated: 0}
```

## §2 Two memories in one file

The `intents` table is the outbox: `seq`, the recorded job id, the name, the version, an enqueued flag, nothing
else — "the cargo law in a schema". The `applied` table is the lane's last word per name: the newest version
this group has ever applied, surviving the table, the node, and the bus. The committed surface gate: one journal
file per group, named by the group's branded id — `journal-<group>.db` under the declared directory — a
non-branded group refused at the door, and the schema carrying "intents (the outbox) and applied (the lane's
last word per name)".

The writer's edge, one verb, and the applier's edge, one handler (source: `content/bcs4.4.md`, How):

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

Writers get the outbox in one verb, `intend_and_enqueue/4`, with the two seams inside it drilled rather than
assumed. Consumers swap one handler for another: `Journal.handler/2` wires the lane through the memory, and
everything from 4.2's crash choreography still applies beneath it.

## §3 The seams, closed by what already exists

The writer's flow is record, enqueue, mark — two seams. A death before the enqueue leaves a pending intent that
replay enqueues; a death after the enqueue but before the mark leaves the bus holding the job, and replay's
reuse of the recorded job id lets the bus's own admission dedup absorb it. The rung drills both at once, then
calls `replay`: "both crash seams closed by machinery that already exists: the never-enqueued intent replayed
onto the bus, the enqueued-but-unmarked one answered :duplicate at admission and was counted, both ended in the
applied memory -- and once coverage is total, replay is exactly %{replayed: 0, deduplicated: 0}".

Two decisions hold the seams open on purpose, then close them by replay:

- **`mark_enqueued` is a separate call on purpose.** Folding it into the enqueue would erase the seam the drill
  exists to cover; "the outbox pattern's candor is that the seams are real", named, and closed by replay rather
  than wished away.
- **Replay reuses recorded job ids.** Minting fresh ids on replay would defeat the bus's admission dedup and
  deliver duplicates the consumer must absorb anyway; reusing the recorded id lets the bus answer `:duplicate`
  for whatever survived, which the record counts in the open.

Recovery is one idempotent verb (source: `content/bcs4.4.md`, How):

```elixir
{:ok, %{replayed: n, deduplicated: m}} = Journal.replay(:limits_journal, conn)
```

Replay is Richardson's at-least-once relay, with the duplicate handling this series shipped two chapters ago —
the admission dedup of **B3.2 · Jobs Are Entities** and the newer-wins comparison of **B4.2 · Coherence by Mint
Time**.

## References

Sources:

- Richardson, C. — Pattern: Transactional outbox —
  https://microservices.io/patterns/data/transactional-outbox.html (the outbox's contract and its crash seams)
- SQLite — Write-Ahead Logging — https://www.sqlite.org/wal.html (the commit path under both memories)
- Litestream — How it works — https://litestream.io/how-it-works/ (the off-box layer the boundary names and
  does not build)

Related:

- /bcs/cache/the-lane-that-remembers — B4.4 · The Lane That Remembers, the module hub; the full rung in context
- /bcs/cache — B4 · EchoCache, the chapter landing
- /bcs/bus/jobs-are-entities — B3.2 · Jobs Are Entities, the admission dedup that absorbs the replayed job id
- /bcs/cache/coherence-by-mint-time — B4.2 · Coherence by Mint Time, the lane the journal stands beside
- /bcs/elixir-core/property-stores — B2.2 · Property Stores on ETS, the stores being cached
- /echomq — EchoMQ, the protocol in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/cache/the-lane-that-remembers` · next
`/bcs/cache/the-lane-that-remembers/the-bus-dies-the-lane-replays`.
