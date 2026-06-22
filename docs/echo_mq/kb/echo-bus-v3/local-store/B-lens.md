# Chapter — The Local Store (CubDB · MVCC · replay) · Lens B (persistence-led)

> **Lens B — the persistence-led / vision-forward lens ("the floor rises to carry the log").** This
> chapter is read from the durable engine outward, not from the bus inward. The priorities are fixed, in
> order: (1) the durable engine — Champ accept-tier + Graft commit-tier → Tigris — is the platform's
> **universal substrate**, the floor every surface stands on; (2) the **commit-log-as-outbox (ADR-A) is the
> keystone** — durability becomes one atomic act, off SQL entirely; (3) the engine's forward path is Champ
> accept → Graft commit → Tigris replication → the outbox subsuming the SQLite journal; (4) the bus is **one
> client** of the durable floor, beside the cache, the Tables, and the workers — it consumes durability, it
> does not own it. What this lens CHAMPIONS in the local store: the commit log earning its keep three times
> (durability, replication, the change feed) from one append-only structure; the reserved-LSN-range outbox
> (`@obx_base`) as the proven seed of the v4 north star; and CubDB's MVCC roots as the time-travel substrate
> the bus's archive borrows rather than invents.
>
> The discipline holds regardless of the lens: **forks are SURFACED, never decided** — each closes with a
> ranked recommendation and the one carrying reason, and pre-empts the bus lens's strongest objection. The
> grounding is **NO-INVENT** — every as-built surface is cited to `file:line`, every unbuilt surface is
> forward-tense. This document was **authored independently**; the sibling bus-led lens (`A-lens.md`) was not
> read. Convergence is confidence; divergence is the signal the Operator most needs.

---

## §0 · Context

**What this chapter is.** The local store is Chapter II of the Echo Persistence manuscript — the durable
local page tier (CubDB's append-only immutable B-tree), its MVCC time-travel (roots kept by reachability, GC
by pins + a retention window), and the unification of replay (green boot, replica catch-up, the change feed
are *one fold from a starting LSN*). From the persistence lens this is not a subsystem the bus reaches down
into; it is the **floor the whole platform stands on**, and the question this chapter settles is how the bus's
forthcoming Stream Tier archive (emq3.5) **lands on a floor that was already complete** — built for the page
workloads of Chapter III, the outbox of the v4 north star, and the Tables, long before any stream slice asks
to be stored.

**What is as-built (verified at source this session).**

- **CubDB is the durable local tier** — append-only, immutable copy-on-write B-tree, zero-cost MVCC
  snapshots. Two words ("append-only" + "immutable") give crash-safe single-act commits and free retained
  roots (`local-store/cubdb/index.md` §1; the engine store is `EchoStore.Graft.Store` over CubDB, cited in
  `graft.engine-split.design.md` §3b — `append` in one tx, `page_at` reverse-select, `index_at`, `commits`).
- **MVCC time-travel is checkout-at-LSN** — opening a Volume at any LSN is picking that root, lock-free; GC
  reclaims old, unpinned roots by reachability, never by age, and *"a reader pinned at an old LSN keeps that
  root and everything it reaches alive"* (`local-store/mvcc-time-travel/checkout-and-gc.md` §1–§2).
- **Replay is one signature** — `replay(from_lsn, apply_fn)`; green boot, replica catch-up, and the change
  feed differ only in the starting LSN and whether bytes are local or pulled from object storage
  (`local-store/replay-and-recovery/index.md` §1, §3).
- **The outbox already lives in this store as a reserved page range.** `EchoStore.Durability.Graft`
  (`echo/apps/echo_store/lib/echo_store/plugins/graft.ex`) writes each enqueue intent as a CubDB page commit
  at `@obx_base + seq`, where `@obx_base = :erlang.bsl(1, 48)` (`plugins/graft.ex:46`) — *"so an intent page
  is never overwritten, which makes recovery a single head-snapshot scan."* `replay/2` reads every
  reserved-range page whose commit LSN is above the enqueue watermark and re-enqueues it (`plugins/graft.ex:155`);
  the cursors are `:obx_enqueued_wm` and `{:obx_applied, name}` (`plugins/graft.ex:13, 246`).
- **The commit log is the outbox is the change-feed source — one structure, three jobs.** The manuscript
  states it directly: *"the commit log is the outbox … durability, replication, and the change feed all fall
  out of one append-only log — which is why this engine is the platform's default"*
  (`engines/native-elixir/the-commit-log-outbox.md` §2).

> **The one question this chapter must answer well, from this lens:** When the bus's Stream Tier archive
> (emq3.5) folds a trimmed slice into the local store, is it **adding to a floor that already holds the
> outbox, the Tables, and the page workloads** — landing as ordinary pages under the already-built MVCC,
> replay, and GC machinery — or is it being treated as a bus-shaped special case that the store must bend to
> accommodate? The persistence lens insists the archive is the floor's *fourth tenant*, not a new wing.

---

### F-LS-A — the archive's landing representation in CubDB

**The fork.** A trimmed stream slice (a contiguous run of branded `EVT` records the retention window is about
to drop from the live stream) must become local CubDB pages the engine can replicate and time-travel. *How* is
it represented on the page axis?

> **Arm A1 — a reserved high-LSN page range, the `@obx_base` pattern carried forward.** Each archived stream
> segment takes a page index in a reserved high range — e.g. a stream-archive base far above both the
> business-page range and the outbox's `@obx_base`, the segment's branded `EVT` floor mapped to the page
> index — exactly as the outbox already partitions the page axis into "ordinary commits" and "reserved
> intents."
>
> - *Rationale.* The store ALREADY proves this representation works for a non-page tenant: the outbox's
>   reserved range coexists with business pages in one log, one writer, separated only by where they sit on
>   the LSN axis (`plugins/graft.ex:16-22`; `the-commit-log-is-the-outbox.md` §1). A second reserved tenant
>   (the stream archive) is the same move a second time — the floor's proven idiom, not a new one.
> - *5W.* **Why** — reuse the partition-the-page-axis idiom the outbox validated, so the archive inherits
>   replay/GC/replication with no new mechanism. **What** — an archived segment is a page (or a small page
>   run) at a reserved-range index, its bytes the slice's records, committed via the engine's public
>   `commit/3`. **Who** — the emq3.5 fold consumer (a stream client) writes it; the engine owns it
>   thereafter. **When** — emq3.5, forward-tense. **Where** — the engine's existing `EchoStore.Graft.Store`
>   on CubDB (`graft.engine-split.design.md` §3b); the fold writes through `EchoStore.Graft.commit/3`
>   (`echo/apps/echo_store/lib/echo_store/graft.ex:41`). The reserved base is a forward-tense constant the
>   rung declares, an analogue of `@obx_base` (`plugins/graft.ex:46`).
> - *Steelman.* This is the floor's own pattern, reused. The outbox demonstrates that a reserved page range
>   is durable, replicated, GC-safe, and recoverable by a head-snapshot scan above a watermark — every
>   property the archive needs — and it does so WITHOUT touching the engine, because a reserved page index is
>   still an ordinary page to CubDB. The persistence lens prizes this: the archive is not a new storage shape,
>   it is the third tenant of a page axis the store already multiplexes (business pages, outbox intents,
>   archive segments). The watermark recovery the archive needs is the SAME `replay`-above-a-watermark the
>   outbox already runs (`plugins/graft.ex:155-179`), so the fold rung writes almost no new recovery code.
> - *Steward.* The honest multi-year cost: a reserved range is a global, hand-allocated constant, and a third
>   tenant on one page axis means the engine's compaction now sweeps three kinds of dead page, and a reader
>   that snapshots the head sees all three ranges. That is fine — CubDB GC is reachability-based, indifferent
>   to which range a page sits in (`checkout-and-gc.md` §2) — but the rung MUST declare the archive base far
>   enough above `@obx_base` that the two reserved tenants never collide, and that allocation is a permanent
>   keyspace fact the store carries. Named, it ages well; unnamed, two reserved ranges could one day overlap.

> **Arm A2 — a Volume-per-stream (a dedicated Graft Volume for each archived stream).** Each stream archives
> into its OWN Graft Volume — `EchoStore.Graft.open_volume(stream_vol, …)` — so the stream's segments are the
> whole page space of a Volume dedicated to it, not a reserved range inside a shared one.
>
> - *Rationale.* A Volume is the engine's natural unit of isolation: one single-writer `VolumeServer`, one
>   LSN log, one Tigris remote prefix, one snapshot lineage. A stream that may grow deep deserves its own
>   Volume so its retention, its replica catch-up, and its GC are independent of any other tenant's.
> - *5W.* **Why** — give each archived stream the engine's full isolation unit. **What** — a `VOL`-branded
>   Volume per stream, opened lazily on first fold. **Who** — the fold consumer opens it via the engine
>   facade. **When** — emq3.5. **Where** — `EchoStore.Graft.open_volume/2` (`graft.ex:31`), `new_volume_id/0`
>   (`graft.ex:38`), one `VolumeServer` per Volume (`volume_server.ex:34`).
> - *Steelman.* Isolation is real and it is the engine's grain. A deep, long-retained stream archived into its
>   own Volume cannot starve the outbox's writer, cannot bloat the business Volume's compaction, and its
>   Tigris segments live under their own prefix (clean operationally). Time-travel over one stream's history is
>   a checkout on THAT Volume's roots — the cleanest possible mapping of "this stream's past" to "this Volume's
>   LSN axis." For a small handful of streams (the tier's stated demand — *"a handful of groups per stream"*,
>   `emq.streams.md`), a handful of Volumes is a modest, legible footprint.
> - *Steward.* The cost is per-Volume overhead: each Volume is a supervised single-writer process, a CubDB
>   file, a Streamer, a Registry entry (`volume_server.ex:90-111`; `supervisor.ex` per §3b). The tier's demand
>   is small *now*, but "a Volume per stream" scales the process/file count with stream count, and the fold
>   consumer must manage Volume lifecycle (open on first fold, and — the subkey-cleanup law's analogue — name
>   what RETIRES a Volume when its stream is destroyed, or Volumes leak). For the stated small-end demand this
>   is bounded; past the log-tier exit (`emq.streams.md` §Seams) it would not be.

**Ranked recommendation (Lens B — persistence-led): A1 (the reserved-range pattern), with A2 reserved for a
stream the Operator declares "deep and isolated."** A1 carries because it makes the archive the floor's proven
third tenant — it reuses the EXACT `@obx_base`/`replay`-above-a-watermark idiom the outbox already validates in
this store, so the archive inherits durability, replication, GC, and recovery with the least new mechanism and
the smallest new surface. The persistence lens reads the store as one substrate multiplexing tenants on a
shared page axis, and the outbox is the precedent that this is sound. A2's Volume-per-stream is the right
answer for a *specific* stream the Operator marks as deep/long-retained/operationally-isolated — it is an
additive escalation, not the default, and the choice (shared reserved range vs dedicated Volume) is the
Operator's per-stream call, not the architect's.

> **Pre-empted bus-lens objection:** *"A reserved page range buries stream archives inside a Volume the bus
> can't address as a stream — the bus wants each stream's archive to be a first-class, independently
> retained, independently replicated thing, which a dedicated Volume (A2) gives cleanly. Forcing archives
> into a shared reserved range subordinates the stream's identity to the store's page bookkeeping."* Answer:
> the persistence lens does not refuse A2 — it reserves it for the stream that has earned isolation, and
> surfaces the per-stream choice to the Operator. But the DEFAULT must be A1 for one reason the bus lens
> undercounts: the archive's recovery, GC, and replication are not bus concerns the store should re-implement
> per stream — they are floor properties the store ALREADY delivers for the outbox, and the reserved-range
> pattern is precisely what lets the archive inherit them unchanged. A Volume-per-stream by default pays
> per-stream process/file/Streamer overhead for an isolation most streams (small, run-bounded — the tier's
> own demand) never need, and it pushes Volume-lifecycle management into the bus's fold consumer. The
> archive's identity is preserved either way — the branded `EVT` floor is the segment's key, addressable on
> the page axis regardless of which Volume holds it — so isolation, not addressability, is the real axis, and
> isolation is an opt-in property, not a default the store should pay for universally.

---

### F-LS-B — the SQLite journal's fate (demoted to a rebuildable working set — kept, or subsumed?)

**The fork.** `store.design.md` demotes the SQLite journal to a rebuildable local working set and names its
future explicitly: *fold `intents` into CubDB and retire `exqlite`* — on the one condition that the journal
stays rebuildable (the v4 ADR's ADR-E, `echo_mq-v4-durability-adr.md`). Does the journal survive as the
outbox's SQLite adapter, or does the Graft commit-log-as-outbox SUBSUME it?

> **Arm B1 — Graft-as-outbox subsumes the journal (retire `exqlite` on the named schedule).** The durable
> transactional boundary moves entirely onto the Graft commit log: `EchoStore.Durability.Graft` becomes the
> canonical outbox, the SQLite `Journal` survives only as a rebuildable cache (eventually deleted), and
> `exqlite` retires.
>
> - *Rationale.* This is the keystone of the persistence lens, and it is ALREADY the ruled v4 direction.
>   ADR-A: *"the single-writer commit log is the transactional substrate AND the outbox in one mechanism"*;
>   ADR-E: *"because ADR-A keeps the transactional boundary off SQLite, the Journal's `exqlite` is retired on
>   the named schedule"* (`echo_mq-v4-durability-adr.md`). The as-built `EchoStore.Durability.Graft` already
>   IS this outbox — `record/4` commits an intent page, `replay/2` recovers above a watermark, the two
>   cursors live in CubDB (`plugins/graft.ex:83-92, 155-179, 246-251`). The SQLite path is the BYO-free
>   default the *core* ships; the Graft path is the BYO plugin (`durability.ex` moduledoc) — and the lens's
>   north star is to make the Graft path canonical.
> - *5W.* **Why** — one durable engine, not two; the founding no-SQL intent re-established as fact. **What** —
>   `intents` fold into CubDB (already the case for the Graft adapter); the journal is rebuildable; `exqlite`
>   retires on the ADR-E schedule. **Who** — the platform durability owner; the bus is a downstream consumer
>   that sees only `enqueue` (unchanged). **When** — the v4 line (post-Stream-Tier), the forward path. **Where**
>   — `EchoStore.Durability.Graft` (`plugins/graft.ex`) becomes the canonical adapter; `EchoStore.Journal` /
>   `exqlite` retire per ADR-E; the facade `EchoStore.Durability` (`durability.ex`) already abstracts the
>   choice, so the swap is a config change, not a rewrite (`durability.ex:10`).
> - *Steelman.* The reframe's whole force is that SQL was never the plan — *"D-2 keeps the bus volatile;
>   `echo_data` declares Ecto-freedom an enforced invariant; the v4 roadmap lists 'becoming a SQL queue' as a
>   non-goal"* (`echo_mq-v4-durability-adr.md`). SQLite entered through one pragmatic edge and the design has
>   ALWAYS named its exit. Subsuming the journal is not a new decision — it is the consummation of a decision
>   already made and already half-built. The commit-log-as-outbox makes recording-and-durability one act
>   (`the-commit-log-is-the-outbox.md` §1), inherits the fence + replication + recovery the engine already
>   runs, and — the load-bearing point — it RESTORES the rebuildability premise A1-SQLite would break: nothing
>   durable lives in SQLite anymore, so the demotion proceeds rather than reverses (ADR-E). The store ends with
>   one durable story to operate and reason about.
> - *Steward.* The honest cost is a migration with a real ordering constraint (ADR-E open question 4: ratify
>   the retirement timeline relative to the Phase-1 Graft-history work it shares a substrate with). Until the
>   Graft tier is the default deployment (today it is a BYO plugin a host adds — `durability.ex` moduledoc;
>   `graft.engine-split.design.md` §2), retiring SQLite would strand a host that has not adopted Graft. So B1
>   is the *destination*, sequenced behind "Graft is the default durable tier," not a flip the Stream Tier
>   itself performs. The steward keeps the journal alive AS a rebuildable working set in the meantime — which
>   is exactly what "demoted, not deleted" already means.

> **Arm B2 — keep the SQLite journal as a coequal outbox adapter (the pluggable facade is the point).**
> `EchoStore.Durability` stays a genuine plugin facade: SQLite, Memory, Postgres, and Graft are all
> first-class adapters; a host picks per deployment, and SQLite remains the dependency-free default the core
> ships.
>
> - *Rationale.* The facade EXISTS to make durability a config choice, not a rewrite (`durability.ex:6-9`).
>   Different hosts have different floors: a small single-box deployment is well served by `exqlite` with zero
>   extra dependencies; only a host that already runs the Graft tier wants the commit-log-as-outbox. Forcing
>   every host onto Graft removes the very pluggability the facade was built to provide.
> - *5W.* **Why** — preserve deployment optionality; keep the zero-dependency default. **What** — all adapters
>   coequal behind the facade. **Who** — the host operator chooses. **When** — standing. **Where** — the
>   eight-callback `EchoStore.Durability.Adapter` contract (`graft.engine-split.design.md` §3c — `child_spec`,
>   `intend_and_enqueue`, `record`, `mark_enqueued`, `record_many`, `replay`, `compact`, `last_applied`,
>   `stats`); the shipped `SQLite`/`Memory` core + `Postgres`/`Graft` BYO.
> - *Steward.* Coequality is honest about the present — Graft is a BYO plugin today, not the default — and the
>   facade's value is real. But the steward's caution (and the lens's whole argument) is that this is the
>   PRESENT, not the destination: `store.design.md` and ADR-E both name SQLite's retirement as the plan, and a
>   "keep SQLite coequal forever" stance re-promotes the pragmatic edge to a permanent fixture, which is
>   exactly the "becoming a SQL queue" drift the founding intent forbids. B2 describes the floor today; it
>   should not be mistaken for the floor's future.

**Ranked recommendation (Lens B — persistence-led): B1 (Graft-as-outbox subsumes the journal) as the
DESTINATION, sequenced behind "the Graft tier is the default durable floor"; B2 is the accurate present, not
the future.** B1 carries because it IS the keystone of this lens and the already-ruled v4 direction (ADR-A +
ADR-E): one durable engine, the founding no-SQL intent restored as fact, the outbox and the transactional
boundary unified in one `commit/3`. The sequencing is the honest part — the Stream Tier does not perform the
retirement (it consumes the floor as it stands), and SQLite stays a rebuildable working set until Graft is the
default deployment. This is a forward-path ruling, not a Stream-Tier-rung decision, and the timeline
(ADR-E open Q4) is the Operator's.

> **Pre-empted bus-lens objection:** *"The bus does not care which outbox adapter the store runs — `enqueue`
> is `enqueue`. Retiring SQLite is a store-internal migration with real risk (a host mid-adoption), and
> coupling it to the Stream Tier's roadmap is the persistence lens over-reaching: keep SQLite, it works, and
> let the Graft outbox be the opt-in it already is."* Answer: the persistence lens AGREES the bus is
> indifferent to the adapter and AGREES the retirement is sequenced behind Graft-as-default, not forced by the
> Stream Tier — that is exactly the recommendation. Where the lens does not yield is on the *destination*:
> "keep SQLite forever" is not a neutral default, it is a standing re-promotion of the one SQL dependency the
> platform's founding documents (`echo_data` Ecto-freedom invariant, the v4 non-goal, ADR-E) all name for
> retirement. The bus lens reads SQLite's persistence as harmless because the bus never touches it; the
> persistence lens reads it as a debt the floor has already committed to clearing. Both agree on the
> near-term (SQLite stays, rebuildable); they differ on whether the long-term plan is "subsume" (B1, the named
> future) or "coexist indefinitely" (B2, the unbounded present) — and that difference is precisely the kind of
> forward-path signal the Operator should rule, not a thing to default to inertia.

---

### F-LS-C — MVCC / retention watermark coupling (does CubDB GC share a watermark with the stream's MINID window?)

**The fork.** CubDB's compaction / retained-roots GC reclaims old roots by reachability + a retention window
(`checkout-and-gc.md` §2). The stream's bounded retention (emq3.4) trims by `MAXLEN`/`MINID` (a mint-instant
window). When the archive folds a stream into the store, do these two retention boundaries SHARE a watermark,
or stay independent?

> **Arm C1 — the archive's GC boundary is DERIVED from the stream's retention window (one watermark, the
> store follows the stream's MINID).** The archived segments below the stream's MINID retention floor are the
> store's eligible-for-deep-storage set; the store's local CubDB GC of archive pages is governed by a
> watermark that tracks the stream's retention policy, so "what the stream has stopped serving live" and "what
> the store holds for deep reads" align by construction.
>
> - *Rationale.* The two windows describe the same lifecycle from two ends: the stream's MINID says "below
>   here is no longer live"; the archive exists precisely to hold "below here." Aligning the GC boundary with
>   the retention floor means there is one coordinate for "where live ends and deep begins" — which is exactly
>   the merge-read watermark `W` the platform chapter establishes (the commit-LSN-as-cursor idea generalized).
> - *5W.* **Why** — one boundary for the live/deep transition, no drift between what the stream dropped and
>   what the store holds. **What** — the archive's local GC watermark is a function of the stream's MINID
>   retention floor (or the fold frontier that tracks it). **Who** — the fold consumer advances it as it folds
>   and as retention advances. **When** — emq3.5/emq3.4 together. **Where** — CubDB GC is reachability +
>   retention-window (`checkout-and-gc.md` §2); the stream MINID is mint-instant (`emq.streams.md`); the
>   shared coordinate is a branded id (the order theorem makes it sort cleanly).
> - *Steelman.* This is the persistence lens's core move applied to retention: the commit LSN that means "this
>   much is durable" on the store side is the same number that means "subscribe from here" on the bus side
>   (`bus-and-persistence/index.md` §1), and the SAME unification applies to retention — the id below which
>   the stream stops serving is the id above which the archive's deep storage holds. One watermark, two
>   readings. It makes the no-gap/no-overlap property of the deep read a CONSEQUENCE of a single boundary
>   rather than a coordination problem between two independent GCs. And it is sound because the engine's GC
>   already keeps anything a reader pins (`checkout-and-gc.md` §2) — a deep reader pinned at an old LSN holds
>   the archive roots it reads alive regardless of the retention watermark, so aligning the boundary with the
>   stream cannot drop a page a reader still needs.
> - *Steward.* The honest cost is a coupling: the store's archive GC now depends on a value the stream owns
>   (the retention floor), so a change to the stream's retention policy moves the store's GC boundary. That is
>   the INTENDED coupling (it is what "one boundary" means), but the steward must name the direction: the
>   stream's retention is the source, the archive's GC is the follower, and a deep reader's pin is the
>   override that keeps a pinned root alive past the boundary. Three rules, all already true of the engine's
>   GC — named, not invented.

> **Arm C2 — the two watermarks stay INDEPENDENT (CubDB GC by its own retention/reachability; the stream's
> MINID is a bus concern the store does not consult).** The store reclaims archive pages by its own retention
> window + pins, exactly as it reclaims business pages; the stream's MINID trims the live stream; neither
> reads the other's boundary.
>
> - *Rationale.* Separation of concerns: the store's GC is a storage property (reachability + a local
>   retention window), and coupling it to a bus-side policy makes the store's correctness depend on a value
>   another system owns. Keep the store's GC governed only by what the store can see.
> - *5W.* **Why** — keep the store's GC self-contained, no cross-system dependency. **What** — independent
>   retention windows; the archive's pages are GC'd like any pages. **Who** — the store's GC; the bus's trim.
>   **When** — standing. **Where** — `checkout-and-gc.md` §2 (the engine's own GC); `emq.streams.md` (the
>   stream's MINID, separate).
> - *Steward.* Independence is the safer default for the store IN ISOLATION — its GC cannot be broken by a bus
>   policy change. But the cost the persistence lens weighs heaviest: two independent retention boundaries
>   re-introduce exactly the drift the shared-cursor design exists to eliminate. If the archive's GC reclaims a
>   page the stream's deep-read still expects (because the two windows disagree), the merge-read gains a gap
>   the order theorem cannot close — a fault the shared watermark (C1) makes structurally impossible. The
>   steward's verdict: independence buys local simplicity at the cost of a cross-tier invariant the platform's
>   whole "one system, not two" thesis is built to provide.

**Ranked recommendation (Lens B — persistence-led): C1 (the archive's GC boundary is derived from the
stream's retention window — one watermark, the store follows), with the engine's pin-override preserved.** C1
carries because it makes the live/deep boundary a single coordinate — the same shared-cursor discipline the
platform chapter establishes for the commit LSN, applied to retention — so the deep read's no-gap/no-overlap
property falls out of one boundary instead of a coordination dance between two GCs. The engine's existing
reachability+pin GC is the safety net (a pinned deep reader holds its roots regardless of the watermark), so
the coupling cannot drop a page a reader needs. The direction is the named part: the stream's retention is the
source, the archive's GC is the follower.

> **Pre-empted bus-lens objection:** *"Coupling the store's GC to the stream's MINID makes the durable floor's
> correctness hostage to a bus policy — change retention and you can corrupt deep storage. The store should GC
> on its own terms (C2); the bus should not reach into the store's reclamation."* Answer: the coupling runs the
> safe direction and is bounded by the engine's existing pin-override, so a retention change cannot drop a page
> a deep reader pins — the store's correctness is NOT hostage, because reachability+pins (already as-built,
> `checkout-and-gc.md` §2) override the retention watermark for any live reader. The deeper point: the bus
> lens's "GC on its own terms" is precisely the two-authorities-for-one-fact drift the shared-cursor design
> eliminates everywhere else (the commit LSN is one number read two ways, not two numbers kept in sync). Two
> independent retention boundaries are not "separation of concerns" — they are a second source of truth for
> "where live ends and deep begins," and the merge-read's correctness depends on those two agreeing. C1 makes
> them agree by construction (one boundary); C2 hopes they agree (two boundaries, coordinated). The
> persistence lens reads the durable floor as the place this boundary SHOULD live, because the floor is what
> holds the deep half and already runs the GC — the stream merely declares where its live window ends.

---

## §Fork ledger (Lens B — persistence-led)

| Fork | Lens-B ranked arm | One-line reason |
|---|---|---|
| **F-LS-A** archive landing representation | **A1** reserved high-LSN page range (the `@obx_base` pattern carried forward); **A2** Volume-per-stream reserved for an Operator-declared deep/isolated stream | The archive is the floor's proven THIRD tenant — it reuses the outbox's reserved-range + `replay`-above-a-watermark idiom and inherits durability/replication/GC/recovery unchanged. |
| **F-LS-B** the SQLite journal's fate | **B1** Graft-as-outbox subsumes the journal (the DESTINATION, sequenced behind "Graft is the default floor"); B2 is the accurate present | The keystone + the already-ruled v4 direction (ADR-A/ADR-E): one durable engine, the founding no-SQL intent restored as fact; the retirement is sequenced, not Stream-Tier-forced. |
| **F-LS-C** MVCC / retention watermark coupling | **C1** the archive's GC boundary derived from the stream's retention window (one watermark, store follows), pin-override preserved | One coordinate for the live/deep boundary — the shared-cursor discipline applied to retention — makes no-gap/no-overlap a consequence of one boundary, not a two-GC coordination. |

**Where I most expect to DIVERGE from the bus lens (this chapter):**
- **F-LS-A** — the bus lens likely prefers a Volume-per-stream (A2) by default for stream-first
  addressability/isolation; the persistence lens defaults to the shared reserved range (A1) so the archive
  inherits floor properties, reserving A2 as an opt-in escalation.
- **F-LS-C** — the bus lens likely keeps the two retention watermarks INDEPENDENT (C2) to keep the store's GC
  off a bus policy; the persistence lens couples them (C1, store follows the stream) to eliminate the drift the
  shared-cursor design forbids. This is the sharpest local-store divergence.
- **F-LS-B** — likely a softer divergence: both lenses accept "SQLite stays rebuildable near-term"; they part
  on whether the long-term plan is "subsume" (B1, the named future) or "coexist indefinitely" (B2).

---

## §Manuscript reconciliation (proposed from this lens — PROPOSE only; the Director applies)

The local-store chapter (`docs/echo-persistence/local-store/**`) is `status: established` and largely
consistent with the as-built engine. The edits this lens's reading implies:

1. **`local-store/replay-and-recovery/index.md` — name the archive fold as a FOURTH replay-cursor case.** The
   hub teaches replay as one fold from a starting LSN with three cursors (green boot, replica catch-up, the
   change feed). The persistence lens's F-LS-A reading is that the emq3.5 archive fold's recovery (`replay`
   above the outbox watermark, `plugins/graft.ex:155`) is the SAME fold with a fourth starting point — what's
   missing is a sentence connecting the archive's recovery to the module's "recovery is not a special case"
   thesis. *Proposed framing:* a closing note that the Stream Tier archive's recovery is the same
   `replay(from_lsn, apply_fn)` from the archive watermark, so the archive joins the three replays rather than
   adding a fourth subsystem. (Additive; forward-tense for emq3.5.)

2. **`local-store/cubdb/index.md` — note the page axis is MULTIPLEXED (business + outbox + archive).** §1
   teaches CubDB as the page/LSN log. The outbox already partitions the axis (`@obx_base`), and F-LS-A adds a
   third tenant. *Proposed framing:* a one-line note in §1 or §3 that the same append-only file carries
   business pages, the outbox's reserved-range intents, and (forward-tense) the Stream Tier's archive segments
   — one structure, several tenants, GC indifferent to which range. (Grounds the outbox's `@obx_base` and the
   archive together; the manuscript currently teaches the outbox's reserved range only in the engines chapter,
   `the-commit-log-is-the-outbox.md`.)

3. **No edit to `mvcc-time-travel/checkout-and-gc.md` is forced** — but IF the Operator rules F-LS-C as C1
   (shared retention watermark), a future note connecting the engine's retention window to the stream's MINID
   would be warranted at that rung; flagged, not proposed now (it depends on an unmade ruling).

---

## §What I deliberately did NOT decide

- **Every fork is the Operator's.** A1-vs-A2 (and the per-stream escalation threshold), B1's retirement
  timeline, and C1-vs-C2 are recommendations with one reason each — the choice belongs to the Operator after
  the Director stages this lens against the bus lens.
- **The reserved archive base constant** (A1) — a forward-tense fact the emq3.5 rung declares, NOT a number I
  invent here; I name only that it must sit far above `@obx_base` (`plugins/graft.ex:46`).
- **The `exqlite` retirement timeline** (B1) — sequenced behind "Graft is the default floor"; the exact
  schedule is ADR-E's open Q4, the Operator's.
- **No canon edit, no engine edit, no code, no git.** The native `EchoStore.Graft.*` engine is read-only to
  this design (the COEXIST law); this document touches exactly one file (itself). The manuscript edits above
  are PROPOSED for the Director to apply.

---

## §Surface citations (NO-INVENT)

**As-built (module / file:line — verified at source this session):**

- `EchoStore.Durability.Graft` — the outbox-as-commit-log: `record/4` commits an intent page at
  `@obx_base + seq`, `@obx_base = :erlang.bsl(1, 48)` (`plugins/graft.ex:46, 83-92`); `replay/2` head-snapshot
  scan above the enqueue watermark (`:155-179`); `intend_and_enqueue/4` (`:110`); cursors `:obx_enqueued_wm`
  (`:246`) + `{:obx_applied, name}` (`:13, 128`); `compact/1` records the covered frontier (`:184`) —
  `echo/apps/echo_store/lib/echo_store/plugins/graft.ex`.
- `EchoStore.Graft` facade — `open_volume/2` (`graft.ex:31`), `new_volume_id/0` (`:38`), `commit/3`
  defdelegated to `VolumeServer` (`:41`), `read_at/3` snapshot read (`:56`) —
  `echo/apps/echo_store/lib/echo_store/graft.ex`.
- `EchoStore.Graft.VolumeServer` — the single-writer mailbox = the write lock (`volume_server.ex:1-8`);
  `commit/3` OCC `base_lsn != head → {:error,{:conflict,head}}` (`:48-51, 129-159`); `snapshot/1` (`:55`) —
  `echo/apps/echo_store/lib/echo_store/graft/volume_server.ex`.
- `EchoStore.Durability` facade + `EchoStore.Durability.Adapter` — the pluggable outbox; intents low-volume,
  bus on Valkey; SQLite/Memory core + Postgres/Graft BYO (`durability.ex:6-19`; the 8-callback contract per
  `graft.engine-split.design.md` §3c) — `echo/apps/echo_store/lib/echo_store/durability.ex`,
  `…/durability/adapter.ex`.

**Forward-tense (a surface a Stream rung BUILDS — not yet on disk):**

- The emq3.5 archive fold's CubDB landing representation (F-LS-A) — a reserved-range page write (A1) or a
  per-stream Volume (A2) — committed through the engine's public `EchoStore.Graft.commit/3` /
  `open_volume/2`; the reserved archive base constant is the rung's to declare (analogue of `@obx_base`).
- The shared live/deep retention watermark (F-LS-C, C1) — derived from the stream's MINID floor, advanced by
  the fold consumer.

**Canon / design cited:**

- `docs/echo-persistence/local-store/**` — the chapter under reconciliation: `cubdb/index.md` (CubDB's two
  words), `mvcc-time-travel/checkout-and-gc.md` (checkout-at-LSN, GC by pins+retention),
  `replay-and-recovery/index.md` (one fold, three cursors).
- `docs/echo-persistence/engines/native-elixir/the-commit-log-outbox.md` — one log, three jobs (durability,
  replication, change feed).
- `docs/echo_mq/kb/emq4-durability/echo_mq-v4-durability-adr.md` — ADR-A (commit-log-as-outbox), ADR-E
  (`exqlite` retires on schedule), the rebuildability premise.
- `docs/graft/graft.engine-split.design.md` — the COEXIST ruling (D-1=A, native canonical+untouched), the
  as-built capability maps (§3a–§3c), the outbox-consumes-the-native-engine seam (§3c).
- `docs/echo_mq/emq.streams.md` — the Stream Tier ladder, the durable-archive answer (emq3.5 folds segments
  into `EchoStore.Graft`), the small-end demand.

---

*Lens B — the persistence-led / vision-forward lens. Authored independently; the sibling bus-led lens
(`A-lens.md`) was not read. Convergence is confidence; divergence is the signal. The Director synthesizes; the
Operator rules.*
