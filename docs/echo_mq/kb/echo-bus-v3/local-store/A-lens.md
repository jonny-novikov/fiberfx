# echo-bus-v3 · Chapter II (the local store) — Lens A: BUS-LED

> **Lens A — the BUS-LED view ("the log reaches down to the floor").** This chapter argues every
> local-store fork from the runtime that OPERATES and CARRIES the work: the EchoMQ Stream Tier, whose
> live ladder (emq3.1–3.6) is the platform's spine. The priorities, in order: (1) the Stream Tier is the
> spine — the log that carries work; (2) **emq3.5, the archive fold, is the keystone** — the bus reaching
> down into durable storage; (3) the forward climb streams → retention → archive → time-travel → the BCS
> substrate; (4) persistence is the **floor the bus stands on** — a service the bus *consumes* through a
> public facade, never the master. This chapter CHAMPIONS: a trimmed slice landing in CubDB the way the
> outbox already lands intents (a reserved high range), the journal demoted to a working set the bus can
> rebuild, and one watermark serving the trim, the fold, and the GC. It honors the Steward part of each
> arm honestly — an arm favored here still carries its true multi-year keep-cost.
>
> Forks are **SURFACED, never decided** — the ranked arm is a recommendation with one carrying reason; the
> Operator rules. **NO-INVENT** holds: every named surface is verified at its source (cited `file:line`) or
> written forward-tense for unbuilt surface. **Authored independently — the sibling (persistence-led) lens
> was not read.**

---

## §0 · Context

**What this chapter is.** Chapter II of the echo-persistence manuscript is the **local store** — CubDB as
the durable single-file page tier (append-only, immutable B-tree), its MVCC/time-travel (checkout-at-LSN,
GC by reachability), and replay/recovery. From the bus lens, this chapter answers one thing: **when the
Stream Tier trims its old tail, what does that trimmed slice BECOME on disk, and how does the local store's
own retention machinery stay coherent with the stream's retention window.** The local store is where the
bus's archived work lands — the bottom of the fold.

**What is as-built (verified against disk, cited).**

- **CubDB is the durable page tier** — `EchoStore.Graft.Store` on CubDB, "append-only immutable B-tree,
  zero-cost MVCC snapshots" with `append` in one tx, `page_at` (reverse-select), `index_at`, and `commits`
  (`graft.engine-split.design.md` §3b citing `store.ex:1-20,42-106`). The manuscript teaches the two words
  that do the work — append-only (crash-safe; the last complete header wins) and immutable (copy-on-write;
  old roots stay) — at `docs/echo-persistence/local-store/cubdb/index.md` §1.
- **MVCC GC computes liveness from pins + a retention window, never age.** "GC reclaims nodes no retained
  or pinned version can reach… liveness from active pins plus the retention window, never from age alone"
  (`docs/echo-persistence/local-store/mvcc-time-travel/checkout-and-gc.md` §2). The figure shows "a
  retention watermark marks the last three as kept; running GC reclaims versions older than the watermark
  unless a pin holds them" (same file, figure note). **This is a real second watermark in the platform.**
- **The outbox already lands intents as page-commits in a reserved high LSN range.** `EchoStore.Durability.Graft`
  (the BYO outbox adapter) writes each intent as a page commit at `page_idx = @obx_base + next_seq(g.db)`
  where `@obx_base = :erlang.bsl(1, 48)` = `1 <<< 48` (`echo/apps/echo_store/lib/echo_store/plugins/graft.ex:46`,
  the `record/4` allocator at `:83-88`); `replay/2` drains that range above a CubDB watermark key
  `:obx_enqueued_wm` filtering `lsn > wm and idx >= @obx_base` (`plugins/graft.ex:155-161`). **This is the
  prior art for "a non-page write becomes CubDB pages in a reserved range" — and it is shipped.**
- **The journal is already DEMOTED in canon.** `emq.streams.md` §"The durable-archive answer": "the SQLite
  journal is demoted to a rebuildable local working set (on recovery the bus's own admission dedup absorbs
  the ids the journal would have replayed)"; `EchoStore.Shadow` is retired, the Litestream sidecar gone.
- **`EchoData.Graft.Segment`** is the unit a fold produces: `defstruct [:id, :lsn, :pages, :directory, :frames]`,
  `@enforce_keys [:id, :lsn, :pages]` (`echo/apps/echo_data/lib/echo_data/graft/segment.ex:19-20`).

> **The one question this chapter must answer well, from the bus lens:**
> When the Stream Tier folds a trimmed slice into the local store, what page-index scheme makes that slice a
> set of CubDB pages the engine can read back AND replicate — without inventing a second source of truth,
> and without the local store's own GC racing the stream's retention window? The bus wants the cheapest
> landing that reuses the outbox's proven pattern; the floor must accept the slice as ordinary pages.

---

### F-LS-A — the archive's landing representation in CubDB (the page-index scheme)

The streams-tier KB ruled the fold MECHANISM (a dedicated fold-consumer commits via `VolumeServer.commit/3`,
`streams.synthesis.md` F3.5-A) but never specified the **representation** — *how a slice of stream entries
becomes a page map the engine commits*. That is this fork.

> **Arm A1 — a reserved high-range page index, the outbox pattern generalized.** Each folded entry (or a
> fixed-size run of entries) becomes a CubDB page at an index in a reserved archive range, exactly as the
> outbox writes intents at `@obx_base + seq` — a distinct reserved base (e.g. an `@archive_base`, disjoint
> from `@obx_base = 1<<<48`) per stream, the page index monotone in the entry's branded id.
> - *Rationale.* The pattern is already shipped and proven for "a non-page write becomes CubDB pages." A
>   stream entry is a small immutable claim (claims-only is the tier law, `emq.streams.md` §"The needs");
>   landing each at a reserved-range page index reuses `record/4`'s allocator shape, the `commit/3` write
>   path, and the `replay/2` range-scan reader — three surfaces that exist and are tested.
> - *5W.* **Why** — the cheapest correct landing is the one the engine already knows how to write and scan;
>   a reserved range keeps archive pages from colliding with the Volume's live page space or the outbox's.
>   **What** — a fold that maps each entry's branded id to a monotone page index in a per-stream reserved
>   range, committed as a page map via the public `EchoStore.Graft.VolumeServer.commit/3`. **Who** — the
>   emq3.5 fold-consumer (a bus citizen); the engine is the sink. **When** — emq3.5. **Where** — forward-tense
>   in the fold-consumer's commit step, over `volume_server.ex:50` (`commit/3`, verified), modelled on
>   `plugins/graft.ex:83-88`. **Steelman.** The outbox proves the whole loop end to end: an intent → a page at
>   `@obx_base + seq` → committed → range-scanned on replay above a watermark (`plugins/graft.ex:46,155-161`).
>   The archive fold is the SAME shape with a different base and a different reader (a range read, not a
>   replay-to-enqueue). The branded id gives a total monotone order (the order theorem, `id.ex:28-49`), so
>   "monotone page index in id order" is well-defined and the range is contiguous by construction — which is
>   exactly what makes the merge-read's scalar watermark sound (F-PLAT-B). It composes with GC: archive pages
>   are ordinary CubDB pages, so the engine's reachability GC already covers them. **Steward.** The keep-cost:
>   a reserved range is a frozen-forever address-space carve — `@obx_base` already claims `1<<<48`, so the
>   archive base must be chosen disjoint and documented, and the two ranges' coexistence (outbox + archive in
>   one Volume) must be specced or a future third reserved-range user collides. The page-index→entry mapping
>   must be reversible (the reader recovers the entry/id from the page), so the page payload carries the
>   branded id, not just the claim. It couples the archive's address scheme to the outbox's convention — a
>   shared idiom, cheaper to keep than two, but a change to one invites a look at the other.

> **Arm A2 — a Volume-per-stream (each stream is its own Graft Volume).** The fold opens a dedicated Graft
> Volume per stream (`EchoStore.Graft.open_volume/2`, `graft.ex:31`, verified) and commits folded slices as
> ordinary low-range pages in that Volume — no reserved range, the whole Volume IS the archive of one stream.
> - *Rationale.* A stream's archive is conceptually a single growing log; mapping it to a single Volume gives
>   it the Volume's full machinery (snapshots, checkout-at-LSN, its own change-feed) without sharing address
>   space with anything.
> - *5W.* **Why** — isolation: one stream's archive cannot collide with another's or with the outbox, and a
>   per-stream Volume gets per-stream replication and recovery for free. **What** — `open_volume/2` per
>   stream; folded slices committed as normal pages; the Volume's `head_lsn` is the fold frontier. **Who** —
>   the fold-consumer, one Volume per stream it serves. **When** — emq3.5. **Where** — `graft.ex:31`
>   (`open_volume/2`, verified), `volume_server.ex:50` (`commit/3`). **Steelman.** Cleanest isolation: a
>   Volume is the engine's natural unit of replication and recovery (the `Streamer` rolls a Volume's LSN
>   range to a Segment, `streamer.ex:88`), so a per-stream Volume means box-loss restore is per-stream, and
>   the merge-read watermark IS the Volume's `head_lsn` (a verified surface, `graft.ex` delegates `head_lsn/1`)
>   — no reserved-range bookkeeping at all. It sidesteps A1's address-space-carve entirely. **Steward.** The
>   keep-cost: a Volume is a single-writer process (`VolumeServer`'s mailbox is the write lock,
>   `volume_server.ex:2-8`) plus a `Streamer`, a `Reader`, registry/supervisor entries (`supervisor.ex:1-27`)
>   — so a platform with thousands of streams spawns thousands of Volumes, each a process tree and a Tigris
>   key space (`segments/{SEG}` per Volume). That is a real operational scaling cost the bus lens must weigh:
>   the tier's named demand is "a handful of groups per stream" and "event streams" (small end,
>   `emq.streams.md` §"The needs"), but the COUNT of streams is unbounded (a game mints a stream per run
>   window). Per-stream Volumes scale the engine's process/Tigris footprint with the stream count, not the
>   data volume. The COEXIST law also bites: a per-stream archive Volume is a NEW Volume the bus opens in the
>   native engine — still a consume-the-facade act (no engine edit), but it multiplies the engine's live
>   Volume set, which the engine's operator now owns.

> **Arm A3 — a segment-per-trim (each trim emits one `EchoData.Graft.Segment` directly to Tigris-via-engine).**
> Skip the page-index entirely: a trim event constructs one `Segment` (`segment.ex:20`) from the dropped
> entries and hands it to the engine's segment path, so the archive unit is the Segment, not a CubDB page map.
> - *Rationale.* The engine's durable-at-rest unit on Tigris IS the Segment (`segments/{SEG}` frames,
>   `emq.streams.md` §"The durable-archive answer"); emitting a Segment per trim aligns the archive unit with
>   the storage unit and skips the local CubDB round-trip.
> - *5W.* **Why** — fewest moving parts: one trim → one Segment → Tigris, no local page bookkeeping. **What** —
>   a Segment built from the trimmed run, pushed via the engine's `Streamer`/remote path. **Who** — the trim
>   path. **When** — emq3.5. **Where** — forward-tense over `EchoData.Graft.Segment` (`segment.ex:20`) and the
>   `Streamer` push (`streamer.ex:88`). **Steelman.** Aligns the archive grain to the storage grain; a
>   walk-forward deep read fetches whole Segments (the engine's box-loss restore already does this,
>   `emq.streams.md`), so reading the archive is "fetch the Segments below the watermark." **Steward.** The
>   keep-cost is severe and disqualifying from this lens: it BYPASSES the engine's commit path
>   (`VolumeServer.commit/3`) and writes Segments directly, which means the archive no longer rides the
>   engine's OCC/fence/recovery — it invents a SECOND write path into the durable floor, exactly the "no
>   foreign engine / consume the facade" boundary the COEXIST ruling drew (`graft.engine-split.design.md` §0).
>   The local CubDB tier (the whole point of Chapter II) is skipped, so the archive has no local copy, no
>   MVCC, no lazy-read cache — a deep read ALWAYS pays Tigris. It also re-derives Segment framing outside the
>   `Streamer`, the one place that knows how (`streamer.ex:88-112`). This arm trades the engine's proven write
>   path for a shortcut.

**Ranked recommendation (Lens A — bus-led): A1 (reserved high-range page index, the outbox pattern
generalized), with the per-stream reserved base documented disjoint from `@obx_base` and the page payload
carrying the branded id.** For the runtime that carries the work, the winning property is that the archive
landing reuses a SHIPPED, tested pattern — the outbox's "a non-page write becomes a CubDB page at a reserved
index, range-scanned above a watermark" (`plugins/graft.ex:46,83-88,155-161`) — so emq3.5's fold is a thin
generalization of a path that already works, not a new mechanism. The branded id's total order makes the
reserved range contiguous by construction, which is precisely what lets the merge-read partition on a single
scalar watermark (F-PLAT-B) and lets the engine's reachability GC cover archive pages for free. A2's
per-stream Volume is the cleanest isolation but scales the engine's process + Tigris footprint with the
**stream count** (unbounded — a stream per run window), the wrong axis for a tier whose demand is small-per-
stream but many-streams; the bus lens parks A2 as the right answer for a FEW long-lived high-value streams,
named, not defaulted. A3 is rejected: it invents a second write path into the floor and skips the local tier,
violating the COEXIST "consume the facade" boundary.

> **Pre-empted persistence-lens objection:** *"Reusing the outbox's reserved-range convention overloads
> `@obx_base`'s address-space idiom for a completely different concern (archive vs. transactional-enqueue),
> coupling two unrelated subsystems in one Volume's page space — a per-stream Volume (A2) gives the archive
> its own clean address space and the engine's natural replication/recovery unit, which is the principled
> representation."* Answer: the coupling is an IDIOM, not a dependency — A1 uses a DISJOINT reserved base, so
> the archive and outbox never share a page index; they share only the *technique* ("a reserved high range +
> a watermark range-scan"), which is exactly the kind of proven, tested pattern a new rung should reuse
> rather than reinvent. A2's "clean address space" is real but is bought with an unbounded process/Tigris
> footprint (one Volume tree per stream, scaling with the stream count, not the data) — a steep operational
> cost for a tier whose own canon claims the small end "a handful of groups per stream." The principled
> representation is the one that reuses the engine's proven write path at the engine's natural cost; A1 does,
> and names A2 as the opt-in for the few streams that genuinely warrant a dedicated Volume.

---

### F-LS-B — the SQLite journal's fate (keep it as the outbox adapter, or let Graft-as-outbox subsume it?)

Canon already DEMOTES the journal to "a rebuildable local working set" (`emq.streams.md` §"The durable-archive
answer"). The open question is what that demotion MEANS for the journal's role as the outbox's SQLite adapter.

> **Arm B1 — keep the SQLite journal as the default outbox adapter; the demotion is about the ARCHIVE path,
> not the outbox.** The journal stays `EchoStore.Durability`'s shipped `SQLite` backend (the
> `EchoStore.Journal`, `adapter.ex:9-15`); the demotion means only that the journal no longer carries the
> stream ARCHIVE (Graft does), not that the outbox stops using SQLite.
> - *Rationale.* The journal serves TWO things historically — the stream archive (now Graft's job) and the
>   transactional-enqueue outbox (still SQLite's job). The demotion retires the FIRST role; the second is a
>   distinct, low-volume concern the SQLite adapter serves well with zero new deps.
> - *5W.* **Why** — the outbox is "low-volume, the bus stays on Valkey" (`durability.ex:6-9`,
>   `graft.engine-split.design.md` §2); SQLite is an exact fit for low-volume intents and a Graft commit-log
>   outbox "over-serves" it (`graft.engine-split.design.md` §2 table). **What** — the journal keeps its outbox
>   role; only the archive role moves to Graft. **Who** — the outbox (`EchoStore.Durability`); the bus's
>   transactional-enqueue path. **When** — emq3.5 (the archive moves); the outbox is unchanged. **Where** —
>   `adapter.ex:9-15` (the SQLite backend, verified), unchanged. **Steelman.** The engine-split design is
>   explicit that the outbox and the page-store are DIFFERENT-SIZED concerns: "the outbox need… is already met
>   natively in Elixir with no foreign engine, and a full transactional page-store engine is the WRONG SIZE
>   for it" (`graft.engine-split.design.md` §2 conclusion). Keeping SQLite as the outbox honors that sizing
>   exactly: the bus's hot-path durability stays a small, mostly-idle SQLite dependency, and the archive's
>   bulk durability rides Graft. The two never compete. The "rebuildable working set" demotion is satisfied
>   because the bus's admission dedup absorbs replayed ids (`emq.streams.md`), so the journal can be rebuilt
>   from the bus on recovery — true of its outbox role too. **Steward.** The keep-cost: TWO durable local
>   stores coexist (SQLite for outbox intents, CubDB for archive pages), which an operator must understand as
>   two distinct things with two distinct retention stories. But they ARE distinct (low-volume intent journal
>   vs. bulk page archive), so one mental model would be a false simplification. The `Durability.Graft` BYO
>   adapter (`plugins/graft.ex`) remains available for a host that wants the outbox ON Graft — kept as an
>   option, not the default.

> **Arm B2 — let Graft-as-outbox subsume the journal; one durable local store (CubDB).** Make
> `EchoStore.Durability.Graft` the default outbox so BOTH the outbox intents and the archive pages live in
> one CubDB Volume (the outbox at `@obx_base`, the archive at `@archive_base`), and retire the SQLite journal
> entirely — one local durable engine.
> - *Rationale.* One durable local store is simpler than two: the same CubDB tier, the same MVCC, the same
>   replication, the same recovery — outbox and archive as two reserved ranges in one Volume.
> - *5W.* **Why** — collapsing two stores to one removes a whole subsystem (SQLite/`exqlite`) and unifies the
>   durability story under Graft. **What** — `Durability.Graft` the default adapter; the journal retired.
>   **Who** — the outbox + the archive, both on CubDB. **When** — emq3.5 or later. **Where** —
>   `plugins/graft.ex` becomes default; `adapter.ex:9-15` SQLite demoted to an option. **Steelman.** One
>   engine, one fence, one replication path — the archive and the outbox share `@obx_base`/`@archive_base`
>   ranges in one Volume, so a single `Streamer` ships both to Tigris and a single recovery restores both. It
>   removes the `exqlite` dependency from the default path. **Steward.** The keep-cost is the one the
>   engine-split design explicitly warned against: a Graft commit-log outbox "OVER-serves" the low-volume
>   intent need (`graft.engine-split.design.md` §2 table) — it puts every transactional-enqueue intent through
>   a full page-store commit (OCC head-check, page append, fence) when the intent is a tiny low-volume record
>   a SQLite row serves with far less machinery. It also makes the bus's hot-path durability (the outbox)
>   depend on the SAME engine as the bulk archive, coupling a small mostly-idle concern to a heavy one — the
>   opposite of the "outbox stands beside the bus, low-volume, mostly-idle" posture the design protects
>   (`durability.ex:6-9`). And `Durability.Graft` is documented as a BYO plugin "a host brings because it
>   needs the Graft tier" (`plugins/graft.ex:31`), not a default — making it default reverses a stated design
>   stance.

**Ranked recommendation (Lens A — bus-led): B1 (keep SQLite as the default outbox; the demotion retires only
the ARCHIVE role, not the outbox role).** The bus lens keeps the bus simple: the outbox is the only durability
the enqueue hot path touches and it is *low-volume by its own statement* (`durability.ex:6-9`), so it should
stay the small, mostly-idle SQLite dependency the design built it as — NOT be promoted onto a full page-store
engine that "over-serves" it (`graft.engine-split.design.md` §2). The archive's bulk durability rides Graft
(F-LS-A); the outbox's intent durability rides SQLite; the two are different-sized concerns the design
deliberately keeps apart, and conflating them couples the bus's hot path to the heavy engine. The "rebuildable
working set" demotion (canon) is honored: the journal can be rebuilt from the bus's admission dedup on recovery
in either role. `Durability.Graft` stays available as the BYO option for a host that genuinely wants the
outbox on Graft. **This is a fork where this lens expects to DIVERGE:** a persistence-led lens may prefer B2's
single-engine unification (one durable store, one fence, one recovery) over the bus lens's two-stores-by-size
separation.

> **Pre-empted persistence-lens objection:** *"Two durable local stores (SQLite + CubDB) is a needless
> duplication of the durability machinery — two fences, two recovery paths, two retention stories — when one
> CubDB Volume with two reserved ranges serves both the outbox and the archive under a single, already-built
> page-store engine; the unification is the cleaner architecture."* Answer: the duplication is APPARENT, not
> real — the two stores serve genuinely different-SIZED needs the engine-split design separated on purpose:
> the outbox is low-volume hot-path intents (a SQLite row), the archive is bulk cold pages (a CubDB Volume).
> Unifying them (B2) does not remove machinery; it MOVES the low-volume intent onto a heavy page-store commit
> that "over-serves" it (the design's own word, §2 table) and couples the bus's hot-path durability to the
> bulk engine — making a small mostly-idle dependency ride a large one. The cleaner architecture is the one
> that matches the mechanism to the load: SQLite for the small thing, CubDB for the big thing. The single
> recovery story the objection wants is already had where it matters (both rebuild from the bus's admission
> dedup); the bus lens declines to pay the over-serve cost to merge two stores whose separation is the point.

---

### F-LS-C — MVCC/retention watermark coupling (does CubDB GC share a watermark with the stream's MINID window?)

The platform has TWO retention watermarks today: the **stream's** MINID/MAXLEN trim window (emq3.4) and the
**local store's** CubDB GC retention watermark ("the last three kept… GC reclaims versions older than the
watermark unless a pin holds them", `checkout-and-gc.md` §1-2). This fork asks whether they couple.

> **Arm C1 — keep them DISTINCT; the stream MINID window and the CubDB GC watermark are different axes that
> never share a value.** The stream's trim window governs the HOT log's resident memory (what `XRANGE` can
> still see); the CubDB GC watermark governs the ARCHIVE Volume's version history (which old roots are
> reclaimable). They answer different questions over different data and stay independent.
> - *Rationale.* The stream window is about the bus's live tail (Valkey memory); the GC watermark is about
>   the engine's on-disk version history (CubDB roots). They retain different things for different reasons —
>   coupling them would tie the bus's memory policy to the engine's version-history policy, two concerns with
>   no shared correctness requirement.
> - *5W.* **Why** — a stream trims its hot tail to bound Valkey memory; the engine GCs old Volume versions to
>   bound CubDB file growth (compaction, `cubdb/index.md` §1). These are independent budgets. **What** — two
>   watermarks, two policies, no shared value. **Who** — the bus operator sets the stream window; the engine
>   operator sets the GC retention (or it defaults). **When** — emq3.4 (stream window) + the engine's existing
>   GC (`checkout-and-gc.md`). **Where** — the stream policy (forward-tense, emq3.4) vs. the engine's GC
>   (as-built, `checkout-and-gc.md`). **Steelman.** Separation of concerns: the bus lens does NOT want the
>   engine's GC to be a thing the bus reasons about — the bus consumes the engine as a floor, and the floor's
>   internal version-history GC is the floor's business. Coupling them would make a stream's MINID change
>   reach into the engine's GC, blurring the COEXIST boundary (the engine is consumed, not co-managed). The
>   fold-then-trim safety (the trim never outruns the fold, `streams.synthesis.md` F3.5-A, `retention…md` §2)
>   already guarantees the archive HAS what the stream trimmed BEFORE the trim — so the engine's GC can keep
>   the archive as long as it likes, independent of the stream window, and a deep read still finds the folded
>   slice. **Steward.** The keep-cost: two retention knobs an operator must understand as separate, and a
>   theoretical waste — the engine might GC an archived version the stream has long since trimmed, or keep one
>   the stream still serves live, with no coordination. But that "waste" is not a correctness problem (the
>   merge-read de-dups by id, F-PLAT-B), only a storage-efficiency one, and the alternative (coupling) pays a
>   boundary-blur cost to recover it.

> **Arm C2 — COUPLE them at the fold frontier; the GC retention watermark is the fold watermark, so the
> engine keeps exactly what the stream has archived-and-not-yet-superseded.** The single monotone fold/trim
> watermark (F-PLAT-B) doubles as the GC retention boundary: the engine retains archive Volume versions at or
> above the watermark and GCs below it, so the local store's version history is aligned to the stream's
> archived frontier.
> - *Rationale.* One watermark to reason about is simpler than two; if the fold frontier is the trim boundary
>   AND the GC boundary, then "what is durable, what is live, what is reclaimable" is one coordinate — the
>   same unification the platform already chose for the commit LSN (`bus-and-persistence/index.md` §1).
> - *5W.* **Why** — a single retention coordinate across the stream and the local store removes a whole class
>   of "the two watermarks drifted" reasoning. **What** — the fold watermark (a branded id / its LSN) is the
>   GC retention boundary. **Who** — the fold-consumer advances it; the engine's GC reads it. **When** —
>   emq3.5. **Where** — the fold watermark (forward-tense, derived from the engine's folded frontier per
>   F-PLAT-B) read by the engine's GC (`checkout-and-gc.md`, which today computes from pins + a window).
>   **Steelman.** It extends the platform's signature move — "one cursor for both worlds" (the commit LSN,
>   `bus-and-persistence/index.md` §1) — to retention: one watermark is the trim boundary, the merge cut, AND
>   the GC boundary. It guarantees the engine never GCs an archive version the merge-read might still need
>   (the GC boundary IS the merge cut, so anything the merge reads is at-or-above the GC boundary and safe).
>   **Steward.** The keep-cost is a real boundary-blur: the GC is the ENGINE's internal mechanism
>   (`checkout-and-gc.md` teaches it as the engine's reachability GC, computing from pins + the engine's own
>   retention window). Making the STREAM's fold watermark drive the engine's GC means the bus reaches into the
>   engine's version-history policy — which, even through a public knob, couples a bus concern to an engine
>   internal and edges past the COEXIST "consume, don't co-manage" line. It also fights the engine's EXISTING
>   GC rule, which is "pins + window, never age alone" (`checkout-and-gc.md` §2): a reader pinned at an old
>   LSN must keep that root alive regardless of any fold watermark, so the fold watermark cannot be the SOLE
>   GC boundary — it can only be ONE input beside the pins, which means the unification is partial, not the
>   clean single coordinate the rationale promises.

**Ranked recommendation (Lens A — bus-led): C1 (keep the stream MINID window and the CubDB GC watermark
DISTINCT), because the fold-then-trim safety already decouples correctness from coordination.** The bus
consumes the engine as a floor; the floor's internal version-history GC ("pins + window, never age",
`checkout-and-gc.md` §2) is the floor's business, and the bus has no correctness reason to reach into it. The
fold-then-trim order (`streams.synthesis.md` F3.5-A) guarantees the archive HOLDS a slice before the stream
trims it, so the engine's GC may retain or reclaim archive versions on its own schedule and a deep read still
finds the folded data (the merge de-dups by id, F-PLAT-B). C2's single-coordinate appeal is real but it
cannot actually BE the sole GC boundary — the engine's existing GC must honor reader pins regardless
(`checkout-and-gc.md` §2), so the fold watermark can only be one input, leaving the "one clean coordinate"
unrealized while paying a COEXIST boundary-blur. Keep them distinct; let the fold-then-trim safety carry the
correctness. **This is a fork where this lens expects to DIVERGE:** a persistence-led lens, reading the
platform forward from the engine, may WANT the unified retention coordinate (C2) as the natural extension of
"one cursor for both worlds," weighting the single-coordinate elegance over the COEXIST boundary the bus lens
guards.

> **Pre-empted persistence-lens objection:** *"The platform already unified the commit LSN as one cursor for
> both the store and the bus (`bus-and-persistence/index.md` §1); retention should follow the same principle —
> one watermark that is the trim boundary, the merge cut, AND the GC boundary — rather than leaving the
> engine's GC and the stream's window as two uncoordinated axes that can waste storage and drift."* Answer:
> the commit-LSN unification works because the LSN is a SHARED PRODUCT both sides legitimately read (the
> engine mints it, the bus subscribes from it) — neither side reaches into the other's internals. The GC
> watermark is NOT a shared product; it is the engine's INTERNAL reachability mechanism, and its governing
> rule ("pins + window, never age", `checkout-and-gc.md` §2) means a reader pin must override any external
> watermark — so the fold watermark can never be the GC's sole boundary, only one input beside the pins. That
> makes C2's "one clean coordinate" unachievable in fact while still paying the cost of the bus reaching into
> an engine internal (past COEXIST's consume-don't-co-manage line). The bus lens keeps the unification where
> it is principled (the commit LSN, a shared product) and declines to extend it to a mechanism (GC) that
> structurally cannot accept a single external coordinate. Correctness is carried by fold-then-trim, not by
> coupling.

---

## §Fork ledger (Lens A — bus-led — ranked arms, for the Director's cross-lens diff)

| Fork | Lens-A ranked arm | One-line reason (bus-led) |
|---|---|---|
| **F-LS-A** archive landing representation | **A1** reserved high-range page index (the outbox pattern generalized) | Reuses the SHIPPED outbox pattern (`@obx_base`+seq→page→range-scan); branded-id order makes the range contiguous → a scalar merge watermark; A2 per-stream Volume parked for the few high-value streams |
| **F-LS-B** SQLite journal's fate | **B1** keep SQLite as the default outbox; demotion retires the ARCHIVE role only | The outbox is low-volume hot-path; SQLite is the right-sized store; Graft "over-serves" it — keep the bus simple |
| **F-LS-C** MVCC/retention watermark coupling | **C1** keep the stream MINID window + CubDB GC watermark DISTINCT | Fold-then-trim already decouples correctness from coordination; the engine's GC ("pins + window, never age") can't accept a single external coordinate anyway |

**Where this lens most expects to DIVERGE from the persistence lens** (highest-value signals for the
Operator):

1. **F-LS-B (journal's fate) — B1 keep-SQLite vs the steward's likely B2 subsume-into-Graft.** The bus lens
   weights keeping the hot-path outbox a small right-sized SQLite dependency; the persistence lens likely
   weights a single unified CubDB durable store. A genuine SIZING-vs-UNIFICATION divergence.
2. **F-LS-C (watermark coupling) — C1 distinct vs the steward's likely C2 unified-retention-coordinate.** The
   bus lens guards the COEXIST "consume, don't co-manage" boundary and notes the engine's GC structurally
   can't take a single external watermark; the persistence lens, reading from the engine, likely wants the
   unified coordinate as the natural extension of the commit-LSN cursor. A BOUNDARY-vs-ELEGANCE divergence.
3. **F-LS-A (landing representation) — A1 reserved-range vs a possible persistence preference for A2 per-stream
   Volume.** The bus lens weights reusing the proven outbox pattern at bounded cost; the persistence lens may
   weight the per-stream Volume's clean isolation + natural replication unit, discounting the process/Tigris
   footprint the bus lens flags. A REUSE-vs-ISOLATION divergence.

---

## §Manuscript reconciliation (proposed from this lens — PROPOSE only; the Director applies)

The bus lens, reading Chapter II's manuscript against the as-built tree, proposes these `docs/echo-persistence/`
edits (each: file · what is stale · the proposed new framing):

- **`docs/echo-persistence/local-store/mvcc-time-travel/checkout-and-gc.md`** — *what is stale:* the dive
  teaches the engine's GC retention watermark ("the last three kept… pins plus the retention window") but does
  not connect it to the stream tier's MINID/MAXLEN retention window, leaving a reader to assume one retention
  story when there are two distinct axes. *Proposed framing:* a one-paragraph note (or a §forward link) naming
  that the platform has TWO retention watermarks — the engine's version-history GC (this dive) and the Stream
  Tier's trim window (Module 11.2 / emq3.4) — and that they are DISTINCT axes coupled only by the fold-then-trim
  safety, not by a shared value (per F-LS-C). This closes the gap a reader hits when Module 11.2's "fold
  watermark" and this dive's "retention watermark" both appear.
- **`docs/echo-persistence/platform/echomq-bus/retention-and-the-never-deleted-problem.md`** — *what is stale:*
  §2 narrates the F3.4-A fork and the Director reconciliation well, but does not name WHAT the trimmed slice
  becomes on disk (the page-index scheme) — the landing representation is the live open fork (F-LS-A) and the
  dive should at least point at it. *Proposed framing:* add a sentence after §2 noting that how a trimmed slice
  becomes durable pages (a reserved-range page index, generalizing the outbox's `@obx_base`, vs. a per-stream
  Volume) is itself an open emq3.5 design question, with a forward link — so the manuscript does not imply the
  fold's representation is settled when only the fold MECHANISM (fold-before-trim, a dedicated consumer) is.
- **`docs/echo-persistence/engines/native-elixir/the-commit-log-outbox.md`** (Dive 7.3) — *what is stale (to
  verify on apply):* if the dive presents the commit-log-as-outbox as the durability story without noting the
  SHIPPED `SQLite`/`Memory` adapters are the DEFAULT and the Graft commit-log is the BYO option
  (`adapter.ex:9-15`, `plugins/graft.ex:31`), it overstates the Graft outbox's role. *Proposed framing:* if so,
  a clause clarifying the Graft commit-log outbox is the BYO heavy option a host brings "because it needs the
  Graft tier," not the default low-volume outbox (which is SQLite) — aligning the dive with F-LS-B. *(Marked
  to-verify: the Director should read the dive body before applying, per realization-over-literal.)*

---

## §What I deliberately did NOT decide (the discipline)

- **Every fork above is SURFACED, not ruled.** The ranked arm is a recommendation with one carrying reason; the
  Operator rules. An architect that picks the winner has stopped being a steward.
- **The exact reserved archive base value** (the numeric `@archive_base`) — F-LS-A names the SCHEME (a disjoint
  reserved high range, the outbox pattern); the literal value is a build-time choice at the emq3.5 rung, not
  pre-decided here.
- **The CubDB compaction CADENCE** — when the engine compacts the archive Volume's dead pages
  (`cubdb/index.md` §1, `compaction.md`) is the engine's operational policy, consumed not co-managed by the
  bus (COEXIST). Out of the bus tier's scope.
- **The page payload encoding** (how a stream entry's claim + branded id serialize into a CubDB page value) —
  F-LS-A requires the page carry the branded id for reversibility; the exact codec is a build detail at emq3.5.
- **Whether the journal's SQLite schema changes** under the demotion — F-LS-B keeps SQLite as the outbox
  adapter; any schema evolution is the outbox's own concern, not this fork's.

---

## §Surface citations (NO-INVENT — every named surface grounded)

**Verified as-built (real `module/file:line`):**

- `EchoStore.Durability.Graft` outbox-as-page-commits — `@obx_base = :erlang.bsl(1, 48)` (`= 1<<<48`) at
  `echo/apps/echo_store/lib/echo_store/plugins/graft.ex:46`; the reserved-range allocator `record/4` at
  `:83-88` (`page_idx = @obx_base + next_seq`); the watermark range-scan `replay/2` at `:155-161` (filtering
  `lsn > wm and idx >= @obx_base`, `wm = :obx_enqueued_wm`); moduledoc "the outbox IS the Graft commit log…
  a host brings it because it needs the Graft tier" at `:31`.
- `EchoStore.Durability` / `.Adapter` — the outbox facade ("the bus stays on Valkey… only the low-volume
  outbox intents land in the journal", `durability.ex:6-9`); the 8-callback contract + shipped `SQLite`/`Memory`
  backends "zero new deps" (`adapter.ex:9-15`, `:28-45`).
- `EchoStore.Graft.VolumeServer.commit/3` — the single-writer commit path (mailbox = write lock,
  `volume_server.ex:2-8`); `commit/3` at `volume_server.ex:50` rejecting a stale base `{:error,{:conflict,head}}`
  (`:129-159`).
- `EchoStore.Graft.open_volume/2` (`graft.ex:31`); `new_volume_id/0` (`graft.ex:38`); `head_lsn/1` (delegated,
  `graft.ex:40-44`); `read/2` (`graft.ex:48`) / `read_at/3` (`graft.ex:56`).
- `EchoStore.Graft.Store` on CubDB — `append` (one tx), `page_at`, `index_at`, `commits` (per
  `graft.engine-split.design.md` §3b citing `store.ex:1-20,42-106`).
- `EchoStore.Graft.Streamer` — rolls an LSN range to a Segment, ships to Tigris, advances the watermark,
  crash-safe resume (per `graft.engine-split.design.md` §3b citing `streamer.ex:1-15,88-112`; the push at
  `streamer.ex:88`).
- `EchoData.Graft.Segment` — `defstruct [:id, :lsn, :pages, :directory, :frames]`, `@enforce_keys [:id,:lsn,:pages]`
  (`echo/apps/echo_data/lib/echo_data/graft/segment.ex:19-20`).
- `EchoStore.Graft.Supervisor` — a `Registry` + a `DynamicSupervisor` (per `graft.engine-split.design.md` §3b
  citing `supervisor.ex:1-27`).
- `EchoMQ.Stream.Id` order theorem — stream order == id sort == mint order, by construction
  (`echo/apps/echo_mq/lib/echo_mq/stream/id.ex:28-49`).

**Forward-tense (surface a rung BUILDS — not yet on disk):**

- The emq3.5 fold-consumer's page-index mapping (F-LS-A/A1 — a per-stream reserved `@archive_base` range,
  branded-id-monotone page indices, the page payload carrying the branded id). Does not exist; modelled on
  `plugins/graft.ex:83-88`.
- The per-stream archive Volume (F-LS-A/A2 — `open_volume/2` per stream) as the named opt-in for few
  high-value streams.
- The fold/trim/merge watermark (F-LS-C, F-PLAT-B) derived from the engine's folded frontier.

**Canon / design cited (NOT a code surface):** `docs/echo_mq/emq.streams.md` (the tier ladder, the needs, the
durable-archive answer demoting the journal, the version plane); `docs/echo_mq/kb/streams-tier/streams.synthesis.md`
(F3.5-A fold-before-trim, F3.4-A trim cadence — RULED context); `docs/graft/graft.engine-split.design.md`
(the COEXIST ruling D-1=A, the outbox-vs-page-store sizing §2, the as-built capability map §3); the
echo-persistence manuscript Chapter II (`local-store/cubdb/index.md`, `local-store/mvcc-time-travel/checkout-and-gc.md`).
