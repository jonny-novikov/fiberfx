# EchoMQ Durability Design — Consultation Questions for the Architect

> **Purpose.** A consultation brief. It frames the four open forks of **Phase 2 — Transactional-enqueue**
> ([`emq4.phase2.design.md`](../specs/emq4/emq4.phase2.design.md)) as comprehensive open questions for an
> independent architect to answer *before* the Operator rules. The questions are organized by the four-part
> lens of the architect's approach — **Rationale · 5W · Steelman · Steward**
> ([`aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md)) — turned from an instrument of argument
> into an instrument of interrogation. The design team's current recommendation is stated per fork **so the
> architect tests it rather than defers to it**.
>
> **How to answer.** For each fork, rank the arms, name the single decision whose reversal would cost the
> most, flag any arm resting on a false premise, and — most valuable from an outside vantage — surface a fork
> the brief did not. Grounding discipline holds: every named module below is verified at source or written in
> the forward tense for surface a Phase 2 rung builds; an answer that rests on an invented surface is the most
> expensive kind of wrong.

## 0 · The decision under consultation

**What Phase 2 must deliver.** *Enqueue a job atomically with the business write that triggers it* — Oban's
single strongest property. Oban reaches it because the job row and the business row commit in one Postgres
transaction. The owned stack has no application `Repo`, and the identity/store layer **forbids importing one**
(`echo_data` declares Ecto-freedom an enforced invariant). The Operator's steer is therefore not "reach Oban
parity" but **"push forward `echo_data` and `echo_store`"** — recover the guarantee inside the owned stack.

**The reframe the design proposes.** With no application `Repo`, "atomic with the business data" can resolve
only one way: **the durable substrate that holds the business write also holds the enqueue intent, and one
single-writer commit inside `echo_store` carries both.** The transactional boundary moves from *the app's
Postgres transaction* to *one `echo_store` commit*; a committer then drains the intent to the volatile bus
at-least-once, made idempotent by machinery the bus already runs. The guarantee is claimed identical to
Oban's outbox guarantee; the substrate beneath it is the owned tier.

**The fixed constraints (not under consultation — the architect should treat these as binding):**

- **D-2 — the bus stays volatile.** Durability is never added inside the bus hot path; it lives at the cheap
  edges (the journal) and in a strongly-consistent tier (the Graft engine). Any arm that taxes the bus's
  enqueue path with a synchronous durable write is out of bounds.
- **The BCS law.** Encapsulation is drawn around *systems*; the only values that cross a boundary are
  *identities* and *messages about identities* — no object graphs, no embedded id lists, no shared mutable
  state.
- **No SQL dependency in `echo_data` / `echo_store`.** A Postgres/Ecto edge cannot enter the identity or store
  layer; an arm that needs one must live in a separate adapter (this is Fork D).
- **At-least-once with idempotent handlers.** Exactly-once is not on the table; the drain is idempotent by
  `EXISTS → 0` dedup and newer-wins admission.

## 1 · The as-built floor (verified — the architect may rely on these)

The forward-push builds on shipped surface and replaces none of it. Line numbers drift; the modules and
arities below were confirmed at source for this brief.

- **The outbox already exists, for one lane.** `EchoStore.Journal`
  ([`journal.ex`](../../../echo/apps/echo_store/lib/echo_store/journal.ex)) is a per-group SQLite outbox on
  `exqlite` (WAL, one file per group, one owner process). `intend_and_enqueue/4` is the outbox-in-one-verb
  (record the intent, enqueue, mark); `record/4` and `mark_enqueued/2` are the two edges; `record_many/2`
  group-commits a batch under one WAL append; the `applied` table is the lane's per-name version memory;
  `replay/2` re-enqueues every intent not yet covered, reusing recorded ids so the bus dedup absorbs
  duplicates; `compact/1` retires covered intents (**coverage, not acknowledgment** — the hot path pays no
  per-intent completion write). The `intents` row is `seq · job_id UNIQUE · name_id · version · enqueued ·
  recorded_at`. **Today it is addressed by a coherence `name_id`, not a first-class intent identity.**
- **The strongly-consistent tier already exists.** `EchoStore.Graft.VolumeServer`
  ([`volume_server.ex`](../../../echo/apps/echo_store/lib/echo_store/graft/volume_server.ex)) is one
  single-writer process per volume; its mailbox **is** the write lock (a commit is a `handle_call`, so commits
  serialize by construction, no lock primitive). `commit/3` stages a page map against a `base_lsn` and
  validates OCC — `{:error, {:conflict, head}}` on a stale base — then writes through an L1 versioned by a
  monotonic `CMT` id. `EchoStore.Graft.Sync` carries commit *notices* over the bus (`publish_notice/3`,
  `subscribe_commits/2`) while bytes travel to Tigris off the write path.
- **The bus is the idempotent delivery surface.** `EchoMQ.Jobs.enqueue/4`
  ([`jobs.ex`](../../../echo/apps/echo_mq/lib/echo_mq/jobs.ex)) is a two-key atomic Lua: the kind law first, a
  `EXISTS → 0` dedup that returns `{:ok, :duplicate}` for a re-enqueued id, the row `HSET`, and a score-0
  `ZADD` into `pending` that preserves mint order. `enqueue_many/3` pipelines it; `EchoMQ.Lanes.enqueue/5` is
  the lane analogue `(conn, queue, group, job_id, payload)`.
- **Identity is the thread.** `EchoData.BrandedId.generate!/1` mints a 14-byte branded id whose **byte order is
  mint order** (the order theorem); `valid?/1` gates it; `EchoData.Graft.Id` carries the `VOL`/`SEG`/`CMT`
  brands.
- **The journal's standing premise (load-bearing for Fork A).**
  [`store.design.md`](../store/design/store.design.md) demotes the SQLite journal to a **rebuildable local
  working set** — a lost journal *reconstructs* (the bus's admission dedup absorbs the ids it would have
  replayed) rather than corrupts — and names "the journal's future" as folding `intents` into CubDB to retire
  `exqlite`. The demotion holds on one explicit condition: **only while the journal stays rebuildable.**

**The surface Phase 2 builds (forward tense — none of this exists yet):** a branded **intent** identity in
`echo_data` (working name `OBX`); an atomic **data-write-plus-intent** verb (`intend`) on `echo_store`; and a
**committer** that drains the outbox to the bus.

---

## 2 · Fork A — where the transactional boundary lives (the substrate)

The atomic data-plus-intent write must land on a single-writer substrate. `echo_store` ships two.

- **A1 — the SQLite `Journal` outbox.** The shipped `intents`/`applied`/`replay` mechanism; the atomic write
  is one local SQLite transaction (the `record_many/2` precedent).
- **A2 — a `Graft` volume.** The datum and the intent as pages in one `commit/3` (single-writer OCC); durable
  and Tigris-replicated by construction.
- **A3 — both** (Journal for the intent, Graft for the datum).

**Design team's current recommendation: A1**, on the single reason that its atomic write is the only one
*already shipped and drilled*.

### Rationale — does each arm credibly answer the need, and what *is* the need?

- What is the actual durability requirement of the "business data" in transactional-enqueue — a rebuildable
  working set, or a system-of-record that must survive box loss — and does the answer vary by consumer class
  rather than holding uniformly?
- If the requirement is merely *atomic* (the intent never diverges from the datum) and not *durable* (the
  datum survives a lost box), does A1 answer it completely, and does A2 then solve a problem Phase 2 does not
  have?
- Conversely, if "transactional with the data" implies in practice that the data is a system-of-record, is A1
  answering the question at all, or only the cheap half of it?

### 5W — Why · What · Who · When · Where

- **Who** are the concrete Phase 2 consumers, and where does each one's source-of-truth business data already
  live — in `echo_store`'s durable tier, in the rebuildable journal, or in a store outside the stack entirely?
- **When** — at which consumer, on the ladder — does a rebuildable substrate (A1) stop being sufficient and
  force the boundary onto the durable tier (A2)? Is that consumer real and near, or hypothetical and far?
- **Where** should the datum's *truth* reside relative to the intent — and is it coherent for the intent
  (which must be reliably drained) and the datum (which must be reliably kept) to live in substrates with
  different durability guarantees?

### Steelman — argue each arm at its best

- What is the strongest case that the journal's SQLite transaction is the *right* atomic boundary and not
  merely the *cheapest* — i.e., that local-WAL atomicity is exactly the correct granularity for an outbox
  intent, independent of the datum's durability?
- What is the strongest case for landing the very first transactional-enqueue on **A2** so the datum is
  durable and replicated by the same act that makes it atomic — and does Phase 1 (durable history, already
  slated for Graft) make A2 the unifying choice that avoids splitting the durable story across SQLite and
  CubDB?
- For **A3**, is there *any* construction in which two substrates are genuinely one atomic write without a
  distributed-commit protocol — for instance, one substrate as the source of truth and the other a derived
  projection — or does every honest reading of A3 collapse back into A1 or A2?

### Steward — what does each arm cost to keep for years?

- `store.design.md` demotes the journal to a *rebuildable* working set and conditions that demotion on
  rebuildability. **Transactional business data written into the journal may not be rebuildable.** Does
  choosing A1 as the transactional boundary therefore overturn the premise that lets the journal be demoted —
  and if so, is A1 quietly re-promoting SQLite to a durable store at the exact moment another design line is
  trying to retire `exqlite`?
- How does each arm age as the Graft engine matures? If `intents` is eventually folded into CubDB (the named
  journal-future fork), does an A1 transactional boundary make that migration harder, or does it ride along
  for free?
- A2 surfaces the OCC conflict path (`{:error, {:conflict, head}}`) to the caller, where A1's owner serializes
  silently. Which failure surface is cheaper to keep correct across years of consumers — a retry contract the
  caller must honor, or a serialization point that can become a throughput ceiling?
- How many invariants does each arm add, and how do they compose with what is already frozen (the journal's
  idempotency machinery, the Graft commit contract, the order theorem)?

### The hard question — is the fork well-posed?

Is there a **fourth arm** the brief has not surfaced: that the Graft commit log *is* the outbox — the intent
is a page in the same commit as the datum, and the committer drains from the commit stream
(`Graft.Sync.subscribe_commits/2`) rather than polling a separate `intents` table? Would unifying "outbox" and
"durable store" into one mechanism dominate the choice *between* them — and what does it cost that the brief's
framing hides?

---

## 3 · Fork B — what identity the outbox intent earns (the brand)

The intent must be addressable, deduplicable, and auditable under the BCS law. Two shapes.

- **B1 — a new branded `OBX` namespace**, distinct from the `JOB` id (intent ⟂ job).
- **B2 — reuse the `JOB` id** as the intent id (intent ≡ job — the 1:1 binding the journal ships today).

**Design team's current recommendation: B1**, on the single reason that a distinct identity keeps Phase 3's
one-trigger-to-many-jobs fan-out from being foreclosed.

### Rationale

- Is the outbox intent genuinely a distinct domain entity from the job it enqueues, or an implementation
  detail of the enqueue act dressed up as an entity?
- What, concretely, would a Phase 2 consumer *do* with an intent identity that it could not do with the job
  identity — browse, audit, deduplicate, correlate — and is any of that needed in Phase 2, or only anticipated
  for Phase 3?

### 5W

- **Who** reads or audits intents independently of jobs — an operator, a recovery path, a workflow engine —
  and **when** does that reader arrive (Phase 2, or only Phase 3 workflows)?
- **When** does the 1:1 intent-to-job binding actually break? Is the one-trigger-many-jobs fan-out a certainty
  on the roadmap (Phase 3 workflows) or a speculative option, and does that certainty justify paying for a
  frozen brand now?
- **Where** is the intent identity gated, and does a distinct brand add a second gate on the intent-to-job
  edge that both the consumer and the committer must carry?

### Steelman

- What is the strongest case that a distinct `OBX` brand pays for itself **within Phase 2** — a present
  benefit, not merely an option on the future?
- What is the strongest case that reusing the `JOB` id is not a *foreclosure* but a *correct model* — that an
  outbox intent simply *is* a deferred job, and inventing a second identity for it manufactures a distinction
  the domain does not have?

### Steward

- A 14-byte branded namespace is a **permanent, frozen public contract** once minted. What is the cost of
  minting `OBX` speculatively if Phase 3 reshapes the intent's role and the brand no longer fits — versus the
  cost of un-conflating two lifecycles later if B2 is chosen and fan-out arrives?
- How does a new brand compose with the existing `VOL`/`SEG`/`CMT`/`JOB` set — is there a taxonomy or
  namespace-pressure concern in adding intent-shaped brands one phase at a time?
- Under B2, the outbox lifecycle (an intent compacted after coverage) and the bus lifecycle (a job that may
  still be pending) share one key space, so "show me the outbox" and "show me the jobs" read the same keys.
  What does that conflation cost an operator or a recovery tool over time?

### The hard question

Should the intent reuse an **existing** brand's semantics rather than mint a new one — is the intent, riding a
single-writer commit, actually a `CMT` (a commit)? Or, under the BCS law, is the intent better modeled not as
an entity at all but as an **edge** (a relation between a datum identity and a job identity), which neither
arm currently considers?

---

## 4 · Fork C — the committer's shape and ownership

A process must drain the outbox to the volatile bus and mark coverage. Two shapes.

- **C1 — an owner-started, opt-in `GenServer`** that drains async on a cadence (the shipped `Pump`/`Repeat`
  shape), reusing `replay`/`compact`.
- **C2 — drain inline at `intend` time** (no separate process), with `replay` covering only the crash window —
  the shipped `intend_and_enqueue/4` behavior generalized.

**Design team's current recommendation: C1**, on the single reason that it preserves the outbox's defining
decoupling (a bus outage delays delivery but never blocks the atomic business write).

### Rationale

- Is decoupling the consumer from the bus's availability an *essential* property of transactional-enqueue, or
  a convenience a low-volume consumer can trade away for one fewer process?
- Does the outbox pattern's value survive at all if the drain is inline (C2) — or does inline draining quietly
  reduce the pattern to "write twice and hope," with `replay` as the only safety net?

### 5W

- **Who** operates the committer, and **how many** instances exist at scale — one per group, one per lane,
  one per volume? Does C1's process count grow in a dimension that becomes an operational burden?
- **When** does C2's coupling actually bite — what is the real frequency of bus unavailability and the
  consumer's latency budget — and is the coupling acceptable for the *common* consumer or only the marginal
  one?
- **Where** does the cadence-and-nudge tuning live under C1, and who owns it across deployments?

### Steelman

- What is the strongest case for **C2** — is "no new process to supervise" worth the coupling for the common
  low-volume case, and can the boundary be drawn so the *same* code path serves both (inline by default, an
  async committer as an opt-in escalation under load)?
- What is the strongest case for **C1** even at low volume — does the decoupling earn its keep before scale,
  purely on the correctness of never blocking a committed business write behind a bus round-trip?

### Steward

- A per-outbox process is a per-deployment operational surface: supervision, monitoring, a polling cadence
  that is too slow (latency) or too fast (load). How does that surface age, and does it scale linearly with
  groups/lanes in a way that becomes a liability?
- Does C1's polling cadence add a tuning burden that ages badly — and is there a **third shape** that
  dominates both: an *event-driven* drain off the single-writer commit stream
  (`Graft.Sync.subscribe_commits/2`), with no polling and no inline coupling?

### The hard question

Is Fork C a **false dichotomy** created by Fork A? If the substrate (A2, or the hard-question fourth arm under
Fork A) already emits a commit event, the committer is neither a poller (C1) nor inline (C2) but a *subscriber
to the commit stream* — and the right committer shape may be **determined by**, not chosen independently of,
the substrate. How tightly should C be ruled together with A?

---

## 5 · Fork D — the chosen-against parity arm's fate

The Operator steered to the forward-push over literal Oban parity. The parity arm — a **Postgres `Journal`
adapter** so the `intents` write rides the app's own `Repo.transaction/1` — is recorded **CHOSEN-AGAINST**.
Its disposition is the open fork.

- **D1 — keep it as a deferred seam** (named, parked, re-openable for a Postgres-resident consumer).
- **D2 — remove it from the roadmap entirely** (the owned stack is the answer; the `CHOSEN-AGAINST` record
  preserves the thinking).

**Design team's current recommendation: D1**, on the single reason that the parity arm's audience (every Oban
shop with data already in Postgres) is genuine and the drain half is shared, so parking it preserves a
large-audience option at the cost of one roadmap line.

### Rationale

- Is a Postgres-resident consumer of EchoMQ a *real anticipated* audience on this roadmap, or a hypothetical
  imported from Oban's world? Do any named consumers (the live and planned ones) keep their source-of-truth
  data in Postgres?
- Does the "own the runtime" thesis the stack is built on *actively not want* to serve the
  bring-your-own-Postgres audience — i.e., is serving it a feature or a dilution?

### 5W

- **Who** is the Postgres-resident consumer, and **where** would the adapter even live, given the identity and
  store layers forbid a SQL dependency — a separate adapter application, owned and tested by whom?
- **When** would the seam be opened, and what signal would trigger it?

### Steelman

- What is the strongest case that parking the adapter (D1) costs *nothing* and preserves real optionality —
  and is that case honest, or does a parked seam carry a hidden standing cost?
- What is the strongest case that surfacing it at all (versus D2) **dilutes the architecture's identity** —
  that "we sort of support Postgres, later" is a worse position than a clean "no"?

### Steward

- A parked seam is a standing line to re-justify every roadmap pass. Does D1 create a perpetual "someday" that
  confuses the architecture's identity, or is one named seam entry a genuinely cheap option to hold?
- Either way the `CHOSEN-AGAINST` reasoning is preserved in the design doc and ledger. Given that, what does
  D1 actually buy over D2 that the preserved record does not already provide?

### The hard question

Is the Postgres-parity question **in Phase 2's scope at all**? If transactional-enqueue for a Postgres-resident
app is fundamentally an *adapters* concern — a different program from "push the owned stack forward" — then the
right answer may be neither D1 nor D2 but **move it out of this roadmap entirely**, so Phase 2 is not asked to
hold a decision that does not belong to it.

---

## 6 · Cross-cutting questions (the whole, not the parts)

- **The reframe's soundness.** The design claims the guarantee is *identical* to Oban's DB-transaction
  enqueue, with the substrate swapped. Is that exactly true, or is there a residue: the consumer's *other*
  state — anything it writes that does **not** live in the `echo_store` commit — is no longer covered by the
  atomic boundary the way a single Postgres transaction would cover it. How large is that gap, and which
  consumers does it bite?
- **The composite default.** The recommendations compose as **A1 + B1 + C1 + D1**. Do they cohere, or do any
  two pull against each other — for instance, does A1's *rebuildable* journal sit uneasily with B1's
  *permanent* intent brand (a permanent identity for an entity in a reconstructable store)?
- **The interdependency map.** Which forks must be ruled *together*? The brief suspects A↔C (the substrate may
  determine the committer shape) and A↔B (a Graft `CMT` may subsume the intent brand). Are there others — and
  is the right unit of decision the four forks, or two or three coupled clusters?
- **The missing fork.** What decision does this brief fail to surface? Candidates the design team has not
  framed: the **consumer-facing API shape** of `intend` (what a caller passes and what atomicity it observes);
  the **failure/compensation semantics** when a drained job ultimately fails (does the intent's coverage imply
  anything about the job's outcome?); and **multi-group / multi-slot atomicity** (the boundary is one
  single-writer commit — what is the guarantee when a transaction must span two groups or two volumes?).
- **The steer's ambition.** The Operator's instruction was to *push `echo_data` and `echo_store` forward*.
  Does the design push them forward *enough* — a branded identity plus an outbox verb — or is it a minimal
  increment that under-delivers on the steer, leaving a more ambitious advance (a general transactional
  write-path on the BCS systems, not just an enqueue intent) unclaimed?

## 7 · What a useful answer looks like

The most valuable response does four things the internal design cannot do for itself:

1. **Ranks the arms per fork**, with the one reason that carries each ranking — and says plainly where it
   disagrees with the stated recommendation.
2. **Names the single decision with the highest reversal cost** across all four forks, since that is where an
   outside read earns the most (a frozen brand and a chosen substrate age differently than a parked seam).
3. **Flags any arm resting on a false premise** — especially a Steelman built on a surface that is weaker than
   it reads (the rebuildability tension under Fork A is the brief's own best candidate).
4. **Surfaces a fork the brief missed**, or collapses one the brief over-counted — the highest-leverage
   contribution an independent architect makes is to the *shape of the decision*, not only its resolution.

---

## References

- The design under review: [`emq4.phase2.design.md`](../specs/emq4/emq4.phase2.design.md) (the reframe, ADR-1..3,
  INV-1..7, the per-app carve, the four forks in full four-part arms).
- The phase and its parity framing: [`emq4.roadmap.md`](../emq4.roadmap.md) (Phase 2; the D-2 volatile-bus
  stance; the cross-cutting mitigations; "Non-goals — becoming a SQL queue").
- The method these questions apply: [`aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md) (the
  four-part arm; the surfaced-fork discipline; the multi-architect debate for a high-stakes frozen contract).
- The durable tier and the journal's standing premise: [`store.design.md`](../store/design/store.design.md)
  (the journal demoted to a rebuildable working set §2; the one-knob Tigris path §3; **the journal's future —
  folding `intents` into CubDB to retire `exqlite`, conditioned on rebuildability**).
- The v2 laws the bus-touching rung carries: [`emq.design.md`](../emq.design.md).
- The as-built anchors (re-probe at the build): `EchoStore.Journal`
  ([`journal.ex`](../../../echo/apps/echo_store/lib/echo_store/journal.ex)), `EchoStore.Graft.VolumeServer`
  ([`volume_server.ex`](../../../echo/apps/echo_store/lib/echo_store/graft/volume_server.ex)),
  `EchoMQ.Jobs`/`Lanes` ([`jobs.ex`](../../../echo/apps/echo_mq/lib/echo_mq/jobs.ex)), `EchoData.BrandedId`.
