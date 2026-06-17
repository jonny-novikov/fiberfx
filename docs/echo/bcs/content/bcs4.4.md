# BCS · Chapter 4.4 — The Lane That Remembers

<show-structure depth="2"/>

Chapter 4.2 priced the job lane's guarantee and then stated its ceiling in the open: the bus is volatile by decision D-2, so a bus restart erases the lane's queued obligations, and the TTL is the floor under the loss. This chapter raises the ceiling without touching the decision. The part's sixth law — recovery is replay beside the bus, never WAL inside it — lands as one production module, `EchoCache.Journal`: a per-group SQLite file holding two memories, the outbox of intents at the writer's edge and the last applied version per name at the applier's edge. The committed record (`bcs_rung_4_4_check.out`, `PASS 6/6`) closes every crash seam with machinery that already exists, replays a lane back into existence after a simulated bus loss — `exactly 30 uncovered intents re-enqueued in seq order` — remembers across a full restart what the cache forgot, and prices the memory: `143 us per record-and-mark pair` at the writer's edge, a remembered lane median of `524 us` against the bare lane's committed 148, and the closing line of the record itself — `3.5 times the latency buys an outbox, a last word per name, and a replay that survives the bus`.

## Why

A coherence intent on the job lane is an obligation: somebody's risk limit changed, and a stale cached copy of it costs money. Chapter 4.2's lane survives a consumer crash — the reaper and the lease saw to that — but the obligation itself lived only on the bus, and D-2 keeps the bus volatile on purpose. The dual-write trap waits on either side of the obvious fix: write the store, then enqueue, and a crash between them loses the message; enqueue, then write, and a crash between them announces a write that never happened. The literature's answer is Richardson's transactional outbox — record the intent in local durable storage first, relay it to the broker after, and accept that the relay may deliver twice, so consumers "must be idempotent" [1]. This series is unusually well-armed for that acceptance: the bus already deduplicates a job id at admission, and newer-wins already makes a re-applied version a no-op. What was missing was only the durable intent and the durable memory of application — one SQLite file per group, owned by one process, standing beside the bus. The law's wording is exact: the bus gets no WAL; the journal, which is not the bus, gets SQLite's.

## What

**Two memories in one file.** The `intents` table is the outbox: `seq`, the recorded job id, the name, the version, an enqueued flag, nothing else — the cargo law in a schema. The `applied` table is the lane's last word per name: the newest version this group has ever applied, surviving the table, the node, and the bus. The committed surface gate: one journal file per group, named by the group's branded id, a non-branded group refused at the door, and the schema carrying `intents (the outbox) and applied (the lane's last word per name)`.

**Every crash seam, closed by what already exists.** The writer's flow is record, enqueue, mark — two seams. The record drills both at once: a never-enqueued intent and an enqueued-but-unmarked one, then `replay`: `both crash seams closed by machinery that already exists: the never-enqueued intent replayed onto the bus, the enqueued-but-unmarked one answered :duplicate at admission and was counted, both ended in the applied memory -- and once coverage is total, replay is exactly %{replayed: 0, deduplicated: 0}`. Replay reuses the recorded job ids, so the bus's own admission dedup absorbs whatever it still holds — Richardson's at-least-once relay, with the duplicate handling this series shipped two chapters ago.

**The journal remembers what the cache forgot.** The title's gate stops the table and the journal, reopens the same file against an empty L1, and replays an old version: `the journal remembered v5 across a full stop of table and journal; the replayed old version answered :remembered_stale without touching the cache -- the table's verdict counters did not move and no row appeared -- and the genuinely newer v6 passed through and became the new last word`. Without this memory, an empty L1 makes every replayed message look fresh; with it, staleness is a fact about the lane, not about whichever rows happen to be resident.

**The bus dies; the lane replays.** Fifty intents recorded and enqueued, twenty applied, then the lane's queue keys flushed — D-2's loss, staged: `the bus restart erased the queue and the journal replayed the lane back: exactly 30 uncovered intents re-enqueued in seq order under their recorded job ids, the consumer drained them, and the applied memory closed at 50 of 50 names holding their final versions`. Replay selects by coverage — every intent whose name lacks an applied version at least as new — so the twenty already-applied intents are not re-sent and the thirty lost ones are, with no acknowledgment bookkeeping anywhere on the hot path.

**Compaction is coverage.** The same predicate retires the outbox: `all 50 intents retired by coverage in one pass, the applied memory kept its 50 names, replay over the compacted journal found nothing to do, and a fresh open of the same file still answers the last word -- the outbox empties, the memory does not`.

**The price, and how the gate improved the code.** The first measurement of the writer's pair came in at 224 microseconds against a derivation that priced WAL commits — the gap was per-call statement preparation, three SQL parses per pair. The fix is the single writer's privilege: the five hot statements are prepared once at journal start and rebound per call (exqlite's bind resets the statement), and the pair fell to the committed `143 us per record-and-mark pair`. At `synchronous=NORMAL` the WAL issues no per-commit sync — "the checkpoint is the only operation to issue an I/O barrier" [2] — so the pair is two log appends and a cached rowid read. End to end, the remembered lane's median is `524 us` against the bare lane's committed 148: the multiple is the record's own closing words, `3.5 times the latency buys an outbox, a last word per name, and a replay that survives the bus`.

## Who

Surfaces whose invalidations are obligations — limits, halts, risk parameters — declare a journal beside their job lane and stop pricing a bus restart at one TTL. Writers get the outbox in one verb, `intend_and_enqueue/4`, with the two seams inside it drilled rather than assumed. Consumers swap one handler for another: `Journal.handler/2` wires the lane through the memory, and everything from 4.2's crash choreography still applies beneath it. Operators get `replay/2` as the recovery verb and `compact/1` as the retention verb, both idempotent, both safe to run on a schedule. Chapter 4.5's referee inherits this drill list alongside the others. And the off-box layer is named, not built: Litestream streams a SQLite WAL to replicas from a separate process and restores by snapshot-plus-replay [3] — the journal file is exactly the artifact it wants, and keeping that process outside this codebase is the same separation D-2 already taught.

## When

Declare a journal per group when losing that group's queued coherence to a bus restart costs more than 143 microseconds per write ever will — and skip it for surfaces where the TTL floor was always acceptable; the broadcast lane, in particular, gains nothing from an outbox it would only drop. Run `compact` on a timer sized to your replay-window appetite: intents are small, coverage is one SQL pass, and an outbox kept under a few thousand rows replays in milliseconds. And choose the synchronous level with eyes open: `NORMAL` survives every process and bus crash this part stages, and trades the tail of a machine power loss for its speed — the boundary below says where that trade's remainder lives.

## Where

The journal in `runtimes/elixir/lib/echo_cache/journal.ex`; the file per group at `journal-<group>.db` under the declared directory. The runtime's mix project grew its first compiled dependency — `exqlite` and its build chain vendored as path deps under `runtimes/elixir/vendor/` (tarballs from the package mirror, the NIF compiled from the bundled SQLite amalgamation, no system SQLite consulted) — and the rung runs under `MIX_ENV=prod mix run`, the first cache rung to do so, with the plain-script tower untouched. The rung and its committed record: `bcs_rung_4_4_check.exs`, `bcs_rung_4_4_check.out`.

## How — the remembered lane

**The writer's edge, one verb:**

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

**The applier's edge, one handler:**

```elixir
{:ok, _} =
  EchoMQ.Consumer.start_link(
    queue: Coherence.queue("limits"),
    connector: [port: 6390],
    handler: Journal.handler(:limits_journal, :limits)
  )
```

**Recovery, after the bus came back empty:**

```elixir
{:ok, %{replayed: n, deduplicated: m}} = Journal.replay(:limits_journal, conn)
{:ok, retired} = Journal.compact(:limits_journal)
```

## Decisions

**One journal, one owner.** The single writer of 4.3 as a storage discipline: every statement runs in one process, which is what makes prepared-once statements trivially safe and SQLite's single-writer nature a fit instead of a fight.

**Coverage, not acknowledgment.** An intent is retired when its name carries an applied version at least as new. The hot path pays no per-intent completion write; replay and compaction share one predicate; and the applied table does double duty as the dedup floor and the retention rule.

**Replay reuses recorded job ids.** Minting fresh ids on replay would defeat the bus's admission dedup and deliver duplicates the consumer must absorb anyway; reusing the recorded id lets the bus answer `:duplicate` for whatever survived, which the record counts in the open.

**`mark_enqueued` is a separate call on purpose.** Folding it into the enqueue would erase the seam the drill exists to cover; the outbox pattern's candor is that the seams are real, named, and closed by replay rather than wished away.

**The memory check runs before the cache.** `apply_and_remember` consults the journal first and answers `:remembered_stale` without an ETS lookup, because the journal's word outlives the cache's rows — the gate proves the counters do not move.

**The journal's WAL is beside the bus.** D-2 stands untouched: the bus remains volatile, restart semantics remain replay, and durability lives in a file the bus has never heard of. The law's wording was always about location.

## Boundaries

`synchronous=NORMAL` is a stated trade: every process crash, consumer kill, and bus restart in this part is fully covered, and a machine power loss may trim the unsynced tail of the WAL — the layer that closes that gap is Litestream-shaped, a separate process streaming the journal off the box [3], referenced and deliberately not implemented here. The journal is per-group and per-node: it restores its own lane's obligations and claims nothing about cross-group ordering, which the lanes never promised anyway. Replay is at-least-once by construction and harmless by comparison — the same two facts, in the same order, as everywhere else in this part. And the microseconds carry their header: one scheduler, this container's disk, a 29-byte payload; the 3.5 multiple travels better than the 143.

## Companion files

`runtimes/elixir/lib/echo_cache/journal.ex`; the vendored build chain under `runtimes/elixir/vendor/` and the grown `mix.exs`; the rung `bcs_rung_4_4_check.exs` and its committed record `bcs_rung_4_4_check.out`.

## References

1. Richardson, C. — Transactional outbox, microservices.io pattern catalog (record the message in the service's database, relay it to the broker after; the relay may deliver more than once, so consumers must be idempotent — the outbox's contract, which the bus's admission dedup and newer-wins already satisfy): [microservices.io/patterns/data/transactional-outbox.html](https://microservices.io/patterns/data/transactional-outbox.html)
2. SQLite documentation — Write-Ahead Logging (the WAL's commit path and checkpointing; at synchronous NORMAL the checkpoint is the sole sync barrier, which is the journal's speed and its stated power-loss trade): [sqlite.org/wal.html](https://sqlite.org/wal.html)
3. Litestream documentation — How it works (a separate background process takes over SQLite checkpointing, copies WAL pages to a shadow sequence and replicas, and restores by snapshot plus WAL replay — the off-box layer this chapter names and does not build): [litestream.io/how-it-works](https://litestream.io/how-it-works/)
