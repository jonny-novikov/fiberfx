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

## {emq4-phase2-txn-enqueue-alternatives} Alternatives

### V-1 — the four Phase 2 surfaced forks (Venus surfaces, the Operator rules)

Full four-part arms live in docs/echo_mq/specs/emq4/emq4.phase2.design.md §7. Summary + STEELMAN/CHOSEN-AGAINST record:

FORK A — the substrate (where the txn boundary lives).
  A1 SQLite Journal outbox · A2 a Graft volume (single-writer OCC) · A3 both.
  STEELMAN(A1): the only arm whose atomic write is already shipped + drilled — record_many/2 SQLite txn + applied/replay/compact crash machinery. Least new surface, most reuse.
  STEELMAN(A2): Graft commit/3 is already one indivisible single-writer step, OCC-validated, durable + replicated; unifies the durable tier with Phase 1.
  CHOSEN-AGAINST(A3): reintroduces the dual-write problem the outbox exists to remove — two engines cannot be one atomic write without 2PC, the exact thing D-2 avoids. Weakest steward.
  VENUS RECOMMENDS A1 (proves a guarantee the substrate already provides).

FORK B — the intent brand (what identity the outbox entry earns).
  B1 a new OBX brand (intent ⟂ job) · B2 reuse the JOB id (intent ≡ job, the Journal's shipped 1:1).
  STEELMAN(B1): follows VOL/SEG/CMT/JOB pattern; lets one intent fan out to N jobs (Phase 3 workflows) without id collision; keeps outbox compaction lifecycle independent of the bus lifecycle.
  STEELMAN(B2): least surface, matches shipped intend_and_enqueue/4 exactly; order theorem still holds.
  CHOSEN-AGAINST(B2): forecloses one-trigger-many-jobs fan-out and conflates two lifecycles under one id.
  VENUS RECOMMENDS B1 (keeps Phase 3 unforeclosed; one small pure module). Brand spelling (OBX or other) is the Operator's to confirm.

FORK C — the committer shape/ownership.
  C1 owner-started opt-in GenServer (async drain, cadence + nudge) · C2 inline at intend (sync, replay-only on restart).
  STEELMAN(C1): mirrors EchoMQ.Pump/Repeat opt-in cadence; reuses replay/compact; consumer call stays cheap, drain off-path; bus outage delays delivery, never blocks the write.
  STEELMAN(C2): the shipped intend_and_enqueue/4 generalized; no new process.
  CHOSEN-AGAINST(C2): re-couples the consumer to bus availability (the atomic write succeeds but the inline enqueue fails on a bus outage) — the opposite of the outbox's decoupling.
  VENUS RECOMMENDS C1 (preserves the outbox's defining decoupling property).

FORK D — the Postgres adapter's fate (the chosen-against parity arm, on the record).
  PARITY ARM (CHOSEN-AGAINST by the Operator's steer): a Postgres Journal adapter so the intents write rides the app's Repo.transaction/1.
  STEELMAN(parity, on record): literal Oban parity — the enqueue and the business write are one Postgres commit; strictly better for a consumer whose data ALREADY lives in Postgres (no second substrate, the db txn carries the intent free); lowest-friction adoption for every Oban shop; the drain half is identical to the forward-push.
  CHOSEN-AGAINST: the steer pushes forward echo_data/echo_store, not a SQL dependency the owned stack avoids; serves only Postgres-resident consumers; advances neither named app.
  Disposition sub-fork: D1 deferred seam (parked) · D2 removed.
  VENUS RECOMMENDS D1 (preserves a large-audience option at one roadmap line; the steer is still honored — nothing built, no dependency added).

All four parked in emq4.roadmap.md §Seams as P2-A..P2-D. The Operator rules; recommendations are advice, never decisions.

## {emq4-phase2-txn-enqueue-progress} Progress

### P-1 — design authored + roadmap reconciled (spec-only; no code, no git)

AUTHORED: docs/echo_mq/specs/emq4/emq4.phase2.design.md — the Phase 2 design (context + the reframe §0.1 + ADR-1/2/3 + INV-1..7 §4 + the flow §5 + the per-app carve §6 + the four surfaced forks §7 + consequences §8). Home: beside the chapter spec, the emq.N.design.md precedent.

RECONCILED docs/echo_mq/emq4.roadmap.md Phase 2 (lines ~98-135):
  - Approach rewritten to lead with the forward-push (BCS-native, no Postgres/Ecto), with the boundary moved to a single-writer echo_store commit.
  - Resolved the bare `Alternatives: [RECONCILE]` + `Push forward echo_data and echo_store` markers into the design link + the chosen-against parity arm.
  - Risk table updated (5 rows: the atomic-commit boundary, the committer idempotency, ordering, opt-in, the consumer-bus decoupling).
  - Parity-matrix row 261 updated (mechanism = single-writer commit + committer; Postgres adapter chosen-against, deferred seam).
  - Non-goals "Becoming a SQL queue" bullet reconciled to the chosen-against framing.
  - ADDED §Seams parking P2-A..P2-D as named Operator decisions.

VERIFICATION: all 15 relative links in the design doc resolve (manual check); the roadmap→design link resolves; msh specs confirms emq4.phase2.design.md introduces ZERO new dead targets (the remaining findings are pre-existing drift in other files, out of scope).

BUILD-GRADE for a DESIGN deliverable: every surface grounded at source (journal.ex, volume_server.ex, graft.ex, sync.ex, jobs.ex, branded_id.ex, graft/id.ex) or written forward-tense (the OBX intent id, the intend verb, the committer — all the surface Phase 2 BUILDS). No invented arity. The no-Postgres property verified at both apps' mix.exs deps.

NEXT (Operator-gated): the Operator rules P2-A..P2-D; then the triads for P2.a → P2.b → [P2.c] derive from the chosen arms. NO triad authored yet (the forks gate it).
