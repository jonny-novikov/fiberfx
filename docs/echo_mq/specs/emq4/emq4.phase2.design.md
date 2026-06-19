# Phase 2 — Transactional-enqueue — the design (the reframe, the ADRs, the surfaced forks, the carve)

> **Status: DESIGN — authored this run, awaiting the Director's verification of the carve and the Operator's
> rulings on the surfaced forks (§7).** This is the architectural design the Phase 2 spec triads derive from,
> in the [`emq.2.design.md`](../emq1/emq.2/emq.2.design.md) precedent's shape: a context section, the reframe,
> one ADR per architecture decision with steelmanned alternatives, the four-part-arm surfaced forks, the
> per-app build carve, and the consequences. It fills the two open markers the roadmap carries at Phase 2 —
> the bare `Alternatives: [RECONCILE]` and the directive `Push forward echo_data and echo_store`
> ([`emq4.roadmap.md`](../../emq4.roadmap.md) Phase 2). It invents no surface: every module an arm names is
> verified at its source and cited, or written forward-tense for a surface a Phase 2 rung builds.

## 0 · Context — the steer that re-aimed the phase

[`emq4.roadmap.md`](../../emq4.roadmap.md) Phase 2 covers Oban's single strongest property: enqueue in the
same transaction as the business data. Its drafted approach was **literal parity** — a Postgres `Journal`
adapter so the `intents` write rides the consuming app's own `Repo.transaction/1`, the enqueue intent
committing in the same Postgres transaction as the row that triggered it, with a committer draining the
outbox to the bus at-least-once.

**The Operator's steer re-aims the headline:**

> **Not parity. Push forward `echo_data` and `echo_store`.**

The primary direction is therefore a **BCS-native transactional-enqueue** whose transactional boundary lives
*inside the owned stack* — `echo_data` identity plus the `echo_store` durable tier — advancing those two apps
with new surface, **with no Postgres or Ecto dependency**. The Postgres-adapter arm is **not dropped
silently**: it is carried in §7 Fork D as a fully steelmanned arm that is then **CHOSEN-AGAINST**, so the
path not taken keeps its best case on the record for a future Postgres-resident consumer.

### 0.1 · The reframe the forward-push forces (load-bearing)

The literal-parity framing rests on a precondition the forward-push removes: **a Postgres `Repo` holding the
business data**. In the owned stack there is no app `Repo` — the durability tier is `echo_store` itself, and
both shipped substrates carry **zero** Ecto/Postgrex (verified: `echo_data` declares only `stream_data`
test-side; `echo_store` declares `echo_data` · `echo_mq` · `echo_wire` · `exqlite` · `cubdb`, no SQL client
beyond SQLite — `apps/echo_store/mix.exs`). So "the enqueue commits atomically with the business write"
cannot mean "inside the app's Postgres transaction"; it can only mean:

> **The durable BCS substrate that holds the business write also holds the enqueue intent, and one atomic
> write to that substrate carries both.**

The transactional boundary moves from *the app's Postgres transaction* to *a single-writer commit inside
`echo_store`*. This is precisely what advances the two apps: `echo_store` earns an **atomic
data-write-plus-intent** API on a single-writer substrate, and `echo_data` earns the **branded identity** the
intent is addressed by. The bus is unchanged in contract — it remains the at-least-once, idempotent
delivery surface the committer drains to.

This reframe is not a softening of the guarantee. The outbox pattern's guarantee has always been *the intent
is transactional with the data; delivery is at-least-once and idempotent* (the roadmap's own first
mitigation). Oban makes the intent transactional with the data because the data is in Postgres; the
forward-push makes the intent transactional with the data because the data is in the same `echo_store`
single-writer commit. The guarantee is identical; the substrate under it is the owned stack instead of
Postgres.

### 0.2 · The as-built floor (verified at source; re-probe at each rung's build)

The forward-push **builds on** this shipped surface and replaces none of it. The lag-1 reconcile (the
`echo-mq-architect` skill's step 1) re-probes each anchor at the rung's build — line numbers drift, so the
citations are hints; grep/Read the tree to confirm.

- **The outbox already exists, in one app.** [`EchoStore.Journal`](../../../../echo/apps/echo_store/lib/echo_store/journal.ex)
  is the per-group SQLite outbox: `intend_and_enqueue/4` is the outbox-in-one-verb (mint a `JOB` id, record
  the intent, `Lanes.enqueue`, mark enqueued); `record/4` and `mark_enqueued/2` are the two edges;
  `record_many/2` is a group commit amortizing one WAL append across a batch; the `applied` table is the
  lane's per-name version memory; `replay/2` re-enqueues every intent not covered by the applied memory,
  reusing recorded job ids so the bus's admission dedup absorbs what it still holds; `compact/1` retires
  every covered intent (coverage, not acknowledgment). The `intents` table — `seq` · `job_id UNIQUE` ·
  `name_id` · `version` · `enqueued` · `recorded_at` — is the outbox row, on `Exqlite.Sqlite3` with WAL, one
  file per group, one owner process.
- **The strongly-consistent tier already exists.** [`EchoStore.Graft.VolumeServer`](../../../../echo/apps/echo_store/lib/echo_store/graft/volume_server.ex)
  is one single-writer process per Volume; its mailbox **is** the global write lock (a commit is a
  `handle_call`, so commits serialize by construction, no lock primitive). `commit/3` stages a page map
  against a `base_lsn` and validates OCC — `{:error, {:conflict, head}}` when the base is stale — then writes
  through the L1 versioned by a `CMT` id whose snowflake suffix is monotonic in commit order.
  [`EchoStore.Graft`](../../../../echo/apps/echo_store/lib/echo_store/graft.ex) is the facade (`open_volume/2`,
  `begin/1`, `commit/3`, `read/2`, `read_at/3`); [`EchoStore.Graft.Sync`](../../../../echo/apps/echo_store/lib/echo_store/graft/sync.ex)
  carries commit *notices* over the bus (`publish_notice/3`, `subscribe_commits/2`) while the bytes travel
  via Tigris off the write path.
- **The bus is the idempotent delivery surface.** [`EchoMQ.Jobs.enqueue/4`](../../../../echo/apps/echo_mq/lib/echo_mq/jobs.ex)
  is the two-key atomic Lua: the kind law first (a non-`JOB` id refused `EMQKIND`), `EXISTS → 0` dedup (a
  re-enqueued id returns `{:ok, :duplicate}`), the row `HSET`, and a score-0 `ZADD` into `pending` that
  preserves mint order. `enqueue_many/3` pipelines it; `EchoMQ.Lanes.enqueue/5` is the lane analogue
  `(conn, queue, group, job_id, payload)`. Newer-wins admission plus the score-0 `pending` set make a
  re-applied version harmless and a re-drained intent order-preserving.
- **Identity is the thread.** [`EchoData.BrandedId`](../../../../echo/apps/echo_data/lib/echo_data/branded_id.ex):
  `generate!/1` mints a 14-byte branded id (needs `EchoData.Snowflake`), `valid?/1` gates it, and byte order
  **is** mint order (the order theorem). [`EchoData.Graft.Id`](../../../../echo/apps/echo_data/lib/echo_data/graft/id.ex)
  carries the `VOL` / `SEG` / `CMT` brands.

The gap Phase 2 closes is precise: the outbox guarantee exists for the **coherence job lane** (a name-version
message), but there is **no surface that makes an arbitrary business-data write atomic with an enqueue
intent**, and the outbox lives only in `echo_store`'s Journal, addressed by a coherence `name_id` — not yet
a first-class branded **intent** entity in `echo_data`. Phase 2 builds exactly that surface.

## 1 · ADR-1 — the transactional boundary is a single-writer `echo_store` commit, not a Postgres transaction

**Context.** Transactional enqueue requires the enqueue intent to commit atomically with the business-data
write. Oban achieves this with the consuming app's Postgres transaction. The forward-push has no app
`Repo`; the durable tier is `echo_store`. The boundary must therefore be a write primitive `echo_store`
already owns and can make atomic.

**Decision.** The transactional boundary is **a single-writer commit inside `echo_store`** — a write that
lands the business datum and an outbox intent in one indivisible step on a single owner process, whose
substrate (SQLite Journal, Graft volume, or both) is settled by §7 Fork A. The bus stays volatile (D-2) and
unchanged in contract; a committer drains the outbox to `EchoMQ.Jobs.enqueue` / `Lanes.enqueue`
at-least-once, made idempotent by the bus's `EXISTS → 0` dedup, mint-ordered `JOB` ids, the score-0
`pending` set, and newer-wins.

**Alternatives.**
1. *Baseline — the Postgres `Journal` adapter (literal parity).* The drafted approach: an adapter so the
   `intents` write rides the app's `Repo.transaction/1`. **Chosen-against** by the Operator's steer — fully
   steelmanned in §7 Fork D and kept as the path-not-taken record; it adds an Ecto/Postgrex dependency edge
   and a SQL substrate the forward-push exists to avoid, and it only serves a Postgres-resident consumer.
2. *Two separate writes plus a reconciliation sweep.* Write the business datum, then enqueue, and reconcile
   drift later. **Rejected** — this is exactly the dual-write hazard the outbox pattern exists to remove; a
   crash between the two writes loses the enqueue with no covering replay.
3. *A single-writer `echo_store` commit carrying both: **CHOSEN.*** The substrate `echo_store` already runs
   the single-writer discipline (the Journal owner process; the Graft `VolumeServer` mailbox-as-lock), so
   the atomic data-plus-intent write is an additive API on a shipped substrate, not a new engine.

**Consequences.** The guarantee is identical to Oban's outbox guarantee with the substrate swapped from
Postgres to the owned tier. "Transactional with the data" is now scoped to data that lives in `echo_store`'s
durable tier — a consumer whose data lives in an external Postgres is served by the chosen-against Fork D
arm, deferred as a seam (§7 Fork D). The committer is the one new moving part; its idempotency rides
machinery the bus already provides, so it adds no new correctness primitive.

## 2 · ADR-2 — `echo_data` earns a branded `intent` identity (the outbox entry as a BCS entity)

**Context.** The outbox entry must be a first-class identity to be addressed, deduplicated, browsed, and
audited under the BCS law (the only cargo across a boundary is an identity). Today the Journal's `intents`
row is keyed by an opaque `seq` and a `job_id`; the coherence lane addresses by a `name_id`. Neither is a
branded **intent** entity, and `echo_data` — the identity library — carries no intent namespace.

**Decision.** `echo_data` builds a branded **intent** identity: a new namespace registered through the
shipped `EchoData.BrandedId` contract (the proposed brand is surfaced in §7 Fork B; the working name is
`OBX`, the outbox entry), minted `generate!/<brand>`, byte order == mint order, so an intent sorts by
creation and the committer drains in mint order with no second index — the same order theorem the `JOB`
position rides. This is the minimal, pure (`echo_data` has no processes) surface the forward-push earns in
the identity app.

**Alternatives.**
1. *Reuse the `JOB` id as the intent id.* The intent and the job it enqueues share one id. **Rejected for
   the general case, surfaced as the simplification arm in §7 Fork B** — it conflates two lifecycle entities
   (an outbox entry that may be compacted away versus a job that lives on the bus), and forecloses an intent
   that fans out to more than one job. The Journal today already mints the `JOB` id *as* the intent's
   `job_id`; whether the general Phase 2 intent keeps that 1:1 binding or earns its own brand is the Fork B
   decision.
2. *An opaque integer/`seq` intent key (no brand).* **Rejected** — it violates the BCS law (a non-identity
   crossing the boundary), forfeits the order theorem, and cannot be gated at a key builder the way every
   other `echo_store`/`echo_mq` entity is.
3. *A new branded `intent` namespace: **CHOSEN*** (brand spelling per §7 Fork B). It is additive and pure in
   `echo_data`, composes with the existing `VOL`/`SEG`/`CMT`/`JOB` brands, and gives the outbox entry the
   same identity discipline as every other entity in the stack.

**Consequences.** `echo_data` gains one small, pure, frozen surface (a namespace constant plus the mint and
classify helpers, mirroring `EchoData.Graft.Id`). The intent becomes browsable and auditable by mint order.
The brand is a public, frozen contract once shipped — priced in the §7 Fork B Steward.

## 3 · ADR-3 — the atomic data-write-plus-intent API and the committer are `echo_store` surface

**Context.** The boundary (ADR-1) needs an API a consumer calls to write a business datum and an outbox
intent atomically, and a process that drains the outbox to the bus. Both are data-plane concerns —
`echo_store` is the data plane; `echo_mq` is the bus.

**Decision.** `echo_store` builds the **atomic data-write-plus-intent API** (`intend/…`, an additive verb on
the substrate chosen in §7 Fork A — the Journal owner or the Graft `VolumeServer`) and the **committer**
process (§7 Fork C) that drains the outbox to `EchoMQ.Jobs.enqueue` / `Lanes.enqueue` and marks each intent
covered. The API lands the business datum and the branded intent (ADR-2) in one single-writer step; the
committer's idempotency is the bus's `EXISTS → 0` dedup, the `applied`-style memory, and `replay/2`-style
restart recovery — all already in the Journal.

**Alternatives.**
1. *Fold the committer into `echo_mq`.* **Rejected** — the committer reads `echo_store`'s outbox and is a
   data-plane concern; putting it in the bus inverts the dependency (the bus must not depend on the store)
   and breaks the per-app boundary.
2. *Make the consumer drive the drain (no committer process).* The consumer calls `replay`-style draining
   itself. **Rejected as the default** — it pushes restart-safety and ordering onto every consumer; the
   library law wants an owner-started, opt-in committer (no `mod:` auto-start) the deployment turns on.
   Surfaced as the "shape" axis of §7 Fork C.
3. *The atomic API + an owner-started committer in `echo_store`: **CHOSEN*** (shape per §7 Fork C). It keeps
   the data plane's concerns in the data plane, reuses the Journal's shipped idempotency machinery, and
   honors the opt-in library law.

**Consequences.** `echo_store` gains the consumer-facing transactional verb and one supervised, opt-in
process. The bus gains nothing it does not already have — the committer calls the shipped enqueue surface,
so `echo_mq`'s only Phase 2 change is the thin drain-wiring rung (the carve, §6) that connects an
`echo_store` committer to the bus through the connector, with no new Lua and no wire change.

## 4 · The invariants Phase 2 carries (binding; each a runnable check on its rung)

The forward-push touches three apps; the bus-touching rung (P2.c, §6) carries the **v2 master invariant**
whole ([`echo-mq-program`](../../../../.claude/skills/echo-mq-program.md) §The v2 laws). The invariants below
are the Phase 2 contract; each derives into a Given/When/Then check on the rung that earns it.

- **INV-1 · atomic data-plus-intent.** The `echo_store` `intend` verb lands the business datum and the
  outbox intent in one single-writer step — a crash before the step persists neither, after it persists both
  (no partial write). *Check: a fault injected between the datum and the intent never leaves one without the
  other; the single-writer commit is the unit.*
- **INV-2 · at-least-once, idempotent delivery.** The committer drains every intent to the bus at least
  once; a re-drained intent is absorbed by `EXISTS → 0` (returns `{:ok, :duplicate}`), so re-delivery is
  harmless. *Check: drain an intent twice → exactly one `pending` member; the second answers `:duplicate`.*
- **INV-3 · mint-ordered drain.** Intents drain in branded-id mint order; the score-0 `pending` set
  preserves it on the bus. *Check: intents minted in order t1<t2<t3 appear in `pending` in BYLEX order
  t1,t2,t3 after the drain.*
- **INV-4 · coverage, not acknowledgment.** The hot path pays no per-intent completion write; an intent
  retires only when its name carries an applied/covered version at least as new (the Journal's `compact/1`
  discipline, carried to the chosen substrate). *Check: a covered intent is gone after compaction; the drain
  performs no synchronous ack write.*
- **INV-5 · restart-safe.** After an owner restart, every intent not yet covered re-drains (the `replay/2`
  discipline), reusing recorded ids so the bus dedup absorbs duplicates. *Check: kill and restart the owner
  mid-drain → no lost intent, no double `pending` member.*
- **INV-6 · branded intent identity.** Every outbox intent is addressed by a branded id gated
  `EchoData.BrandedId.valid?/1`; byte order is mint order. *Check: an ill-formed intent id raises at the key
  builder before any write; two intents sort by mint.*
- **INV-7 · no Postgres, no new bus wire.** The forward-push adds no Ecto/Postgrex dependency to `echo_data`
  or `echo_store`, and the bus-touching rung adds no new Lua key and no wire-class — the committer calls the
  shipped enqueue surface. *Check: `grep -i 'ecto\|postgrex'` over the two apps' `mix.exs` is empty; the
  P2.c lib diff adds zero `redis.call` lines (byte-frozen Lua, [`echo/CLAUDE.md`](../../../../echo/CLAUDE.md)
  §4).*

## 5 · The flow (the weave, end to end)

```text
consumer ── intend(datum, …) ──▶  echo_store single writer  ── ONE atomic commit ──┐
                                  (Journal owner OR Graft VolumeServer — Fork A)    │
                                                                                    ├─▶ business datum persisted
                                                                                    └─▶ OBX intent persisted (Fork B brand)
                                                                                            │
        committer (echo_store, owner-started, opt-in — Fork C)  ── drains in mint order ────┘
                                                                                            │
                                                  EchoMQ.Jobs.enqueue / Lanes.enqueue  ◀─────┘   (bus, unchanged)
                                                  EXISTS→0 dedup · score-0 pending · newer-wins
                                                                                            │
                                                                              mark intent covered (echo_store)
                                                                              compact: coverage, not ack
```

One entity's life: the business datum and its enqueue intent are **recorded once** in a single `echo_store`
commit, then the intent is **carried** to the volatile bus by the committer — no surface beneath another,
the boundary atomic at the one single-writer step, delivery at-least-once and idempotent past it.

## 6 · The per-app build carve (the build never smuggles a three-app rung)

The design spans three apps; the **build** respects the per-app boundary and gate ladder — a rung edits one
app plus at most one named seam ([`echo/CLAUDE.md`](../../../../echo/CLAUDE.md) §4, "no third app"). The
forward-push decomposes into three sequenced rungs, each with its own per-app gate. **Each rung is a full
triad** (`emq4.p2.<rung>.{md,stories.md,llms.md}` + a `.prompt.md` runbook) authored after the Operator
rules §7.

| Rung | App (+ seam) | Builds (forward-tense) | Depends on | Gate (per-app) |
|---|---|---|---|---|
| **P2.a** | `echo_data` (pure) | the branded **intent** identity — a new namespace + mint/classify helpers (ADR-2; brand per Fork B), mirroring `EchoData.Graft.Id` | as-built `BrandedId`/`Snowflake` | `TMPDIR=/tmp mix compile --warnings-as-errors` + `mix test` in `echo_data`; a multi-seed mint sweep (a pure id-mint suite — the same-ms mint hazard, so the ≥100 loop if the suite mints) |
| **P2.b** | `echo_store` (+ `exqlite`/`cubdb` already in deps) | the atomic **data-write-plus-intent** API (`intend/…`) on the Fork-A substrate + the committer (Fork C), reusing the Journal's `applied`/`replay`/`compact` idempotency (ADR-3) | P2.a | `mix compile --warnings-as-errors` + `mix test` in `echo_store`; the **≥100 determinism loop** (Store/process/id-mint suite — [`echo/CLAUDE.md`](../../../../echo/CLAUDE.md) §3) |
| **P2.c** | `echo_mq` (+ the one `echo_wire` connector seam) | the **drain wiring** — the committer's call into `EchoMQ.Jobs.enqueue`/`Lanes.enqueue` through the connector; **no new Lua, no wire-class, byte-frozen scripts** (INV-7) | P2.b | `valkey-cli -p 6390 ping` + `mix compile --warnings-as-errors` + `TMPDIR=/tmp mix test --include valkey` in `echo_mq`; `EchoMQ.Conformance.run/2` byte-unchanged (no new scenario unless a deliverable adds one, then additive-minor + re-pin); the ≥100 loop |

**Sequence: P2.a → P2.b → P2.c.** P2.a is pure and unblocks the identity the rest address; P2.b is the
substance (the atomic API + the committer) and depends only on the new identity; P2.c is the thin bus
wiring and is the only rung under the v2 master invariant. No rung edits a third app; the only cross-app
seam is P2.c's named `echo_wire` connector edge, and even that is a *call* into the shipped enqueue surface,
not a wire change.

> **Boundary note for P2.b.** `echo_store` already depends on `echo_mq` and `echo_wire` in-umbrella, so the
> committer calling the bus is an existing dependency edge, not a new one — P2.b stays within `echo_store`'s
> own boundary. P2.c exists as a separate rung only if the connector seam itself needs a touch (a new helper
> on the bus side); if the committer drains purely through the shipped `EchoMQ.Jobs`/`Lanes` public surface
> with no bus-side edit, **P2.c collapses into P2.b's gate** (the conformance + Valkey re-run) and the carve
> is two rungs. Which of the two holds is settled at P2.b's reconcile — surfaced so the build never assumes
> a third-app rung it does not need. The honest default is two rungs (P2.a, P2.b) with P2.c as a
> contingency.

## 7 · The surfaced forks — Venus surfaces, the Operator rules

Each fork is argued in four-part arms ([`aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md):
Rationale · 5W · Steelman · Steward). The arms are set side by side; a recommendation is noted with the one
reason that carries it; **the choice is the Operator's.** A deferred fork becomes a named decision in the
roadmap's seams.

### Fork A — where the transactional boundary lives (the substrate)

The atomic data-plus-intent write (ADR-1) must land on a single-writer substrate. `echo_store` ships two.

**Arm A1 — the SQLite `Journal` outbox** (`EchoStore.Journal`, the shipped `intents`/`applied`/`replay/2`).
- *Rationale.* The outbox already exists and is the literal mechanism the roadmap names; the atomic
  data-plus-intent write is an additive verb on a working owner process, not a new engine.
- *5W.* **Why** reuse the proven outbox; **What** a `intend` verb that writes the datum and the intent in one
  SQLite transaction (the `record_many/2` group-commit precedent); **Who** a consumer whose business data is
  local/rebuildable working set; **When** P2.b; **Where** `echo/apps/echo_store/lib/echo_store/journal.ex`
  (additive).
- *Steelman.* The Journal is the smallest possible delta: `intend_and_enqueue/4`, `record_many/2`, the
  `applied` memory, `replay/2`, and `compact/1` are already there and tested. SQLite gives a real local
  transaction so the datum and the intent are genuinely one atomic write (`BEGIN`/`COMMIT`, the
  `record_many/2` pattern). The crash windows are already drilled. This arm ships Phase 2 with the least new
  surface and the most reuse.
- *Steward.* The Journal is `echo_store`'s last C-backed store (`exqlite`); `store.design.md` §4 already
  carries the journal's future as an open fork (folding it into CubDB to retire `exqlite`). Choosing the
  Journal as the txn boundary deepens the commitment to SQLite at exactly the moment another design line is
  questioning it. The Journal is also a *local working set* (rebuildable, no replica of its own — `store.design.md`
  §2); business data that must survive box loss needs the Graft tier beneath it anyway.

**Arm A2 — a `Graft` volume** (`EchoStore.Graft.VolumeServer`, single-writer OCC, `CMT`-branded commits).
- *Rationale.* Graft is the strongly-consistent, durable, replicated tier; if the business datum must be
  durable and box-loss-survivable, the txn boundary should be the same commit that replicates it.
- *5W.* **Why** put the boundary where durable history already lives; **What** the datum and the intent as
  pages in one `commit/3` against a `base_lsn` (OCC validate-or-conflict); **Who** a consumer whose business
  data is durable, audited, replicated state; **When** P2.b; **Where**
  `echo/apps/echo_store/lib/echo_store/graft/volume_server.ex` (additive).
- *Steelman.* Graft's `commit/3` is already one indivisible single-writer step (the mailbox is the write
  lock), already OCC-validated, already write-through to L1 versioned by a monotonic `CMT` id, and already
  streamed off-path to Tigris with commit notices over the bus. A datum written here is durable and
  replicated by construction; the intent rides the same commit, so atomicity and durability are one act. For
  Phase 1 (durable history) the roadmap already chose Graft — using it for Phase 2 unifies the durable tier
  rather than splitting it across SQLite and CubDB.
- *Steward.* Graft is page-based; an arbitrary business datum must be marshalled into a page set, which is a
  heavier consumer contract than a SQLite row. The OCC conflict path (`{:error, {:conflict, head}}`) surfaces
  to the caller — a contended volume makes the consumer handle retries, where the Journal's owner serializes
  silently. Graft is also the newer, less-exercised engine (`store.design.md` notes it is written-to-fit and
  recently compiled); leaning Phase 2's correctness on it raises the proving cost.

**Arm A3 — both (Journal for the intent, Graft for the durable datum).**
- *Rationale.* The two substrates have complementary strengths: the Journal is the cheap, proven outbox; Graft
  is the durable, replicated store. Use each for what it is best at.
- *5W.* **Why** separate the intent's outbox role from the datum's durability role; **What** the datum
  commits to a Graft volume and the intent records in the Journal, bound into one logical transaction; **Who**
  a consumer wanting both durable business data and the proven outbox; **When** P2.b (the heaviest arm);
  **Where** both modules, plus a coordinator that makes the two writes one boundary.
- *Steelman.* It is the "right tool for each job" composition and mirrors the roadmap's own layering (Graft
  for history, Journal for the outbox). Each half keeps its shipped idempotency.
- *Steward.* **This arm reintroduces the dual-write problem the outbox pattern exists to remove** — two
  substrates (Graft + SQLite) cannot be one atomic write without a distributed-commit protocol between them,
  which is precisely the 2PC the whole D-2 stance avoids. Making them "one boundary" means one must be the
  source of truth and the other derived, which collapses back to A1 or A2. The maintenance and proving cost
  is the union of both engines for a guarantee neither composition strengthens. The weakest Steward of the
  three.

| Arm | Boundary substrate | Atomicity | Durability of the datum | New surface | Proving cost |
|---|---|---|---|---|---|
| **A1 Journal** | SQLite `intents` (`BEGIN`/`COMMIT`) | one local SQL txn | local/rebuildable working set | smallest (additive verb) | lowest (shipped + drilled) |
| **A2 Graft** | one `commit/3` (mailbox-as-lock, OCC) | one single-writer commit | durable + replicated (Tigris) | medium (page marshalling) | higher (newer engine) |
| **A3 both** | Graft datum + Journal intent | **not one atomic write** without 2PC | durable | largest (two engines + coordinator) | highest |

**Recommendation: A1 (the Journal), for one reason** — it is the only arm whose atomic write is *already
shipped and drilled* (the `record_many/2` SQLite transaction + the `applied`/`replay`/`compact` crash
machinery), so Phase 2 proves a guarantee the substrate already provides rather than a new one; a consumer
needing durable, box-loss-survivable business data layers the Graft tier beneath, which is Phase 1's job, not
Phase 2's. Surfaced, not decided.

### Fork B — what identity the intent earns (the brand)

ADR-2 builds a branded intent identity; its exact form is the Operator's.

**Arm B1 — a new `OBX` (outbox) brand, distinct from the `JOB` id.**
- *Rationale.* The outbox entry and the job it enqueues are two lifecycle entities; a distinct brand keeps
  them separable, browsable, and auditable independently.
- *5W.* **Why** an intent is its own entity (it may be compacted while the job lives, and may fan out);
  **What** an `OBX` namespace in `echo_data`, minted `generate!("OBX")`; **Who** every Phase 2 consumer and
  the committer; **When** P2.a; **Where** a new `echo_data` id module mirroring `EchoData.Graft.Id`.
- *Steelman.* It follows the established pattern exactly (`VOL`/`SEG`/`CMT`/`JOB` each name a kind); it lets
  an intent fan out to several jobs later (a workflow seam, Phase 3) without an id collision; it keeps the
  outbox's compaction lifecycle independent of the job's bus lifecycle. The order theorem gives mint-ordered
  draining for free.
- *Steward.* One more public, frozen brand to keep and test forever; a second id on the intent→job edge the
  consumer and the committer both carry. Modest, and consistent with the corpus's identity discipline.

**Arm B2 — reuse the `JOB` id as the intent id (the 1:1 binding the Journal ships today).**
- *Rationale.* The Journal already mints the `JOB` id *as* the intent's `job_id`; keep the intent and the job
  one identity for the common 1:1 case.
- *5W.* **Why** the simplest possible surface; **What** no new brand — the intent is addressed by the `JOB`
  id it will enqueue; **Who** consumers with strictly one-job-per-intent; **When** P2.a is then a no-op (no
  new identity); **Where** nowhere new.
- *Steelman.* It is the least surface and matches the shipped Journal behavior precisely — `intend_and_enqueue/4`
  mints the `JOB` id and records the intent under it. For a strict 1:1 outbox it is sufficient and the order
  theorem still holds (the `JOB` id is mint-ordered).
- *Steward.* It forecloses an intent that fans out to more than one job (the intent has no identity distinct
  from a single job), which collides with Phase 3 workflows where one trigger fans out. It also conflates two
  lifecycles — an intent compacted after coverage versus a job that may still be on the bus — under one id,
  so "show me the outbox" and "show me the jobs" read the same key space. Cheaper now, a constraint later.

| Arm | Brand | Fan-out (1 intent → N jobs) | New `echo_data` surface | Lifecycle separation |
|---|---|---|---|---|
| **B1 `OBX`** | new namespace | supported | one small pure module | intent ⟂ job |
| **B2 reuse `JOB`** | none | foreclosed | none | intent ≡ job |

**Recommendation: B1 (`OBX`), for one reason** — a distinct intent identity keeps Phase 2 from foreclosing
Phase 3's fan-out (one trigger → many jobs) and keeps the outbox's compaction lifecycle independent of the
bus lifecycle, at the cost of one small pure module that follows the shipped `EchoData.Graft.Id` pattern
exactly. The brand spelling (`OBX` or another three-letter uppercase namespace) is itself the Operator's to
confirm. Surfaced, not decided.

### Fork C — the committer's shape and ownership

ADR-3 puts the committer in `echo_store`; its shape is the Operator's.

**Arm C1 — an owner-started, opt-in `GenServer` committer (one per group/lane), polling-then-draining.**
- *Rationale.* The library law wants no `mod:` auto-start; a supervised, deployment-enabled process per
  outbox owner drains on a cadence and on demand, reusing the Journal's `replay`/`compact`.
- *5W.* **Why** restart-safety and ordering belong to one owner, not every consumer; **What** a `GenServer`
  the deployment starts, draining its outbox to the bus and marking coverage; **Who** the deployment that
  opts into transactional enqueue; **When** P2.b; **Where** a new `echo_store` module beside the Journal.
- *Steelman.* It mirrors the shipped `EchoMQ.Pump`/`EchoMQ.Repeat` opt-in cadence model (owner-started,
  `:transient`, no auto-start), reuses `replay/2` for restart recovery and `compact/1` for retirement, and
  keeps the consumer's call (`intend`) synchronous and cheap while the drain is async and off the consumer's
  path. The cadence is tunable; an on-demand nudge drains immediately after an `intend` burst.
- *Steward.* One more supervised process per outbox to operate and monitor; a polling cadence is a tuning
  surface (too slow adds latency, too fast adds load). All bounded and familiar — it is the same shape the
  bus's pumps already ship.

**Arm C2 — drain inline at `intend` time (no separate process), with `replay` only on restart.**
- *Rationale.* Avoid a new process: the `intend` call itself enqueues after the atomic write, and `replay/2`
  covers only the crash window — which is exactly what `intend_and_enqueue/4` does today.
- *5W.* **Why** the least operational surface; **What** `intend` writes atomically then enqueues in the same
  call; **Who** consumers wanting no extra process; **When** P2.b; **Where** the `intend` verb itself.
- *Steelman.* It is the shipped `intend_and_enqueue/4` behavior generalized — record, enqueue, mark, with
  `replay/2` on restart. No new process to supervise. For low-volume consumers it is the simplest correct
  thing.
- *Steward.* **It re-opens a window the outbox pattern is meant to close cleanly**: if the enqueue is inline
  with the consumer's call, the consumer's latency now includes the bus round-trip, and a bus outage blocks
  or fails the consumer's `intend` (the atomic write succeeded, but the inline enqueue did not). The drift
  between "written" and "enqueued" is then carried until the next restart's `replay` rather than drained
  promptly by an owner. It couples the consumer to the bus's availability — the opposite of the outbox's
  decoupling. Acceptable only where the consumer can tolerate bus-coupled latency.

| Arm | Drain | Consumer latency | Bus-outage behavior | New process |
|---|---|---|---|---|
| **C1 owner-started committer** | async, on cadence + nudge | cheap (write only) | drain retries; consumer unaffected | one opt-in `GenServer` |
| **C2 inline at `intend`** | synchronous in the call | write + bus round-trip | `intend` blocks/fails the enqueue leg | none |

**Recommendation: C1 (the owner-started committer), for one reason** — it preserves the outbox pattern's
defining property (the consumer is decoupled from the bus's availability; a bus outage delays delivery but
never blocks or fails the atomic business write), reusing the shipped pump/`replay`/`compact` machinery; C2's
inline drain re-couples the consumer to the bus, which is the coupling the whole pattern exists to remove.
Surfaced, not decided.

### Fork D — the Postgres adapter's fate (the chosen-against parity arm, kept on the record)

The Operator's steer chose the forward-push over literal parity. Per the architect's approach, the parity
arm is steelmanned in full and recorded **CHOSEN-AGAINST**, then its disposition (deferred seam vs removed)
is the Operator's.

**The parity arm, steelmanned (CHOSEN-AGAINST by the Operator's steer).** A **Postgres `Journal` adapter** so
the `intents` write runs inside the consuming app's own `Repo.transaction/1`, the enqueue intent committing
in the *same Postgres transaction* as the business row that triggered it, with the committer draining the
outbox to the bus at-least-once.
- *Steelman (its best case, on the record).* This is **literal Oban parity** — the single guarantee Oban
  users rely on, in the exact mechanism they expect: the enqueue and the business write are one Postgres
  commit, so a rolled-back transaction enqueues nothing and a committed one always enqueues. For a consumer
  whose source-of-truth data **already lives in Postgres**, this is strictly better than the forward-push:
  no second substrate, no marshalling, the database transaction they already run carries the intent for
  free. It is the lowest-friction adoption path for the largest existing audience (every Oban shop), and the
  outbox-drain half is identical to the forward-push (mint-ordered `JOB` ids, `EXISTS → 0` dedup, the
  committer, `replay`). A future Postgres-resident consumer of EchoMQ would want exactly this.
- *Why chosen-against.* The Operator steered to **push forward `echo_data` and `echo_store`**, not to add a
  SQL dependency the owned stack exists to avoid. The adapter introduces an Ecto/Postgrex dependency edge and
  a Postgres substrate, serves only Postgres-resident consumers, and advances neither of the two apps the
  steer names. It is the right answer to a different question (a Postgres-resident consumer) than the one
  Phase 2 now asks (the owned-stack forward-push).

**The disposition sub-fork (the Operator's to rule).**

**Arm D1 — keep the Postgres adapter as a deferred seam** (a named, parked decision; not built in Phase 2,
re-openable when a Postgres-resident consumer presents the need).
- *Steelman.* The best case above is real and audience-large; parking it (not deleting it) keeps the door
  open for a future consumer at zero present cost, and the drain half is shared with the forward-push, so the
  later adapter is a thin add. The roadmap's "Non-goals" already frames "becoming a SQL queue" as the line
  not crossed — a deferred seam honors that while preserving optionality.
- *Steward.* A parked seam is a standing line in the roadmap to maintain and re-justify; it carries a small
  documentation cost and a temptation to build prematurely. Bounded — it is one seam entry.

**Arm D2 — remove the Postgres adapter from the roadmap entirely** (the forward-push is the answer; a future
Postgres need re-derives from scratch).
- *Steelman.* It keeps the roadmap honest to the steer — the owned stack is the answer, full stop, with no
  SQL surface implied as "coming." It removes the temptation and the maintenance of a parked seam.
- *Steward.* It discards the steelmanned best case for a Postgres-resident consumer; if that consumer arrives,
  the design re-derives without the record. The `CHOSEN-AGAINST` rationale in this document and the ledger
  preserves the thinking either way, so the loss is small.

| Arm | Postgres adapter | Serves a Postgres-resident consumer | Roadmap surface | Optionality |
|---|---|---|---|---|
| **D1 deferred seam** | parked, named, not built | later, as a thin add | one seam entry | preserved |
| **D2 removed** | gone | re-derive from scratch | none | discarded (record kept) |

**Recommendation: D1 (deferred seam), for one reason** — the parity arm's best case (every Oban shop, data
already in Postgres) is genuine and the drain half is shared with the forward-push, so parking it as a named
seam preserves a large-audience option at the cost of one roadmap line, while the steer is still honored
(nothing is built, no dependency is added). Surfaced, not decided.

## 8 · Consequences (the whole)

- **The two apps advance, as steered.** `echo_data` earns a branded intent identity (ADR-2); `echo_store`
  earns the atomic data-write-plus-intent API and the committer (ADR-3). The bus is unchanged in contract;
  the boundary moves into the owned stack (ADR-1).
- **No Postgres, no new wire.** The forward-push adds no Ecto/Postgrex (INV-7) and no new Lua key or
  wire-class; the bus-touching rung byte-freezes its Lua. The parity arm and its dependency stay
  chosen-against and (recommended) parked as a seam.
- **The guarantee is Oban's outbox guarantee with the owned substrate.** "Transactional with the data" is
  scoped to data in `echo_store`'s durable tier; a Postgres-resident consumer is the deferred Fork D arm.
- **The build is reviewable.** Three sequenced per-app rungs (P2.a → P2.b → [P2.c]), each with its own gate;
  the only cross-app seam is P2.c's named connector edge, which is a call into the shipped enqueue surface,
  not a wire change — and may collapse into P2.b if no bus-side edit is needed (§6).
- **Phase 3 is unforeclosed.** A distinct intent brand (Fork B, recommended B1) leaves room for the
  one-trigger-many-jobs fan-out Phase 3 workflows need; the committer (Fork C, recommended C1) is the same
  opt-in cadence shape the bus's pumps already ship.

## 9 · References

- The phase and its open markers: [`emq4.roadmap.md`](../../emq4.roadmap.md) Phase 2 (the
  `Alternatives: [RECONCILE]` and `Push forward echo_data and echo_store` lines this design fills) and the
  parity matrix row.
- The design-doc precedent (shape): [`emq.2.design.md`](../emq1/emq.2/emq.2.design.md). The fork structure:
  [`aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md).
- The durable tier and its open forks: [`store.design.md`](../../store/design/store.design.md) (the Journal's
  future §4, the Shadow ruling §2, the one-knob transparency §3). The volatile-bus stance and the parity
  framing: [`emq4.roadmap.md`](../../emq4.roadmap.md) (D-2, the cross-cutting mitigations).
- The v2 laws the P2.c rung carries: [`emq.design.md`](../../emq.design.md) (S-1..S-7) via
  [`echo-mq-program.md`](../../../../.claude/skills/echo-mq-program.md). The per-app boundary and gate ladder:
  [`echo/CLAUDE.md`](../../../../echo/CLAUDE.md) §§3–4.
- The as-built anchors (re-probe at each rung's build): `EchoStore.Journal`
  ([`journal.ex`](../../../../echo/apps/echo_store/lib/echo_store/journal.ex)), `EchoStore.Graft.VolumeServer`
  ([`volume_server.ex`](../../../../echo/apps/echo_store/lib/echo_store/graft/volume_server.ex)),
  `EchoStore.Graft` ([`graft.ex`](../../../../echo/apps/echo_store/lib/echo_store/graft.ex)),
  `EchoStore.Graft.Sync` ([`sync.ex`](../../../../echo/apps/echo_store/lib/echo_store/graft/sync.ex)),
  `EchoMQ.Jobs` ([`jobs.ex`](../../../../echo/apps/echo_mq/lib/echo_mq/jobs.ex)), `EchoData.BrandedId`
  ([`branded_id.ex`](../../../../echo/apps/echo_data/lib/echo_data/branded_id.ex)), `EchoData.Graft.Id`
  ([`id.ex`](../../../../echo/apps/echo_data/lib/echo_data/graft/id.ex)).
