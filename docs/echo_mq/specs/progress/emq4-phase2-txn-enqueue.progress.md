# emq4-phase2-txn-enqueue — AAW scope ledger

## {emq4-phase2-txn-enqueue-thinking} Thinking

### T-1 — Phase 2 reframe + grounding complete

REFRAME (the load-bearing insight from grounding). The roadmap frames Phase 2 as literal Oban parity: a Postgres Journal adapter so `intents` rides the app's `Repo.transaction/1`. The Operator steered: "Not parity. Push forward echo_data and echo_store." The deep consequence found in code: in the forward-push the business data does NOT live in Postgres — there is no app `Repo`. echo_data/echo_store carry ZERO Ecto/Postgrex (verified: echo_data deps = stream_data only; echo_store deps = echo_data/echo_mq/echo_wire/exqlite/cubdb). So "enqueue atomic with the business write" can only be true if the DURABLE BCS SUBSTRATE holds both the business data AND the enqueue intent, and one atomic write to that substrate carries both. The transactional boundary moves from "the app's Postgres txn" to "a single-writer commit inside echo_store".

GROUNDED AT SOURCE (all verified, file:line):
- EchoStore.Journal (journal.ex): `intend_and_enqueue/4` (67-77) ALREADY is the outbox-in-one-verb (mint JOB, record intent, Lanes.enqueue, mark); `record/4`+`mark_enqueued/2` the two edges; `record_many/2` (58-60) group commit one WAL append; `applied` table + `replay/2` (233-260) cover both crash windows; `compact/1` = coverage-not-ack. SQLite via Exqlite.Sqlite3, WAL, one file per group, one owner process.
- EchoStore.Graft.VolumeServer (volume_server.ex): single-writer, mailbox IS the write lock (commit = handle_call, 129-159); OCC base_lsn validate-or-{:error,{:conflict,head}}; `commit/3` stages a page map; write-through L1 versioned by CMT id (monotonic = commit order). Graft facade: open_volume/2, begin/1, commit/3, read/2, read_at/3.
- EchoStore.Graft.Sync: publish_notice/3 + subscribe_commits/2 (commit notices over the bus, bytes via Tigris).
- EchoMQ.Jobs.enqueue/4 (jobs.ex 28-37): two-key atomic Lua — kind law first (EMQKIND), EXISTS→0 dedup (returns {:ok,:duplicate}), HSET row, ZADD score-0 pending. enqueue_many/3 pipelined. Lanes.enqueue/5 = (conn,queue,group,job_id,payload) the lane analogue.
- EchoData.BrandedId: generate!/1 (mint, needs Snowflake), valid?/1, byte order == mint order. EchoData.Graft.Id: VOL/SEG/CMT brands.

FORK SET (candidate axes from the prompt, my framing): (A) where the txn boundary lives — Journal SQLite outbox vs Graft volume vs both; (B) the new echo_data surface — a branded intent/outbox identity + a BCS transactional-write path; (C) the new echo_store surface — the atomic data-write-plus-intent API + the committer; (D) the committer shape/ownership/idempotency; (E) the Postgres adapter's fate (steelman→chosen-against, deferred seam vs removed). I will merge B+C into one "what each app earns" fork driven by A, keep A/D/E as distinct Operator-rulable forks, and carry the Postgres arm as a fully steelmanned CHOSEN-AGAINST.

PLACEMENT: design doc beside the chapter spec home — docs/echo_mq/specs/emq4/emq4.phase2.design.md (the emq.N.design.md precedent: context + one ADR per decision + surfaced forks + carve + consequences). Reconcile emq4.roadmap.md lines 103-119 + the parity-matrix row 261. Ledger here.

DECOMPOSITION (per-app build law, echo/CLAUDE.md §4 — one app + ≤1 named seam per rung): P2.a echo_data identity surface (pure) → P2.b echo_store atomic-write + committer (echo_store + exqlite, no bus edit) → P2.c echo_mq drain wiring (the bus, one connector seam) — each its own per-app gate; the v2 master invariant binds P2.c.
