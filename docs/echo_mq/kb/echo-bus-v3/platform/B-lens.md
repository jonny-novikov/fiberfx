# Chapter — The Platform (Stream Tier · bus+persistence one system · the door to BCS) · Lens B (persistence-led)

> **Lens B — the persistence-led / vision-forward lens ("the floor rises to carry the log").** This chapter
> is read from the durable engine outward. Priorities, in order: (1) the durable engine is the platform's
> **universal substrate**, the floor every surface stands on; (2) the **commit-log-as-outbox (ADR-A) is the
> keystone** — the v4 north star; (3) the engine's forward path is Champ accept → Graft commit → Tigris
> replication → the outbox subsuming the SQLite journal; (4) the bus is **one client** of the durable floor,
> beside the cache, the Tables, and the workers. What this lens CHAMPIONS at the platform level: the
> **engine-as-substrate, bus-as-consequence** reframe (the manuscript's own gravity — *"the durable floor was
> never the point; it was the threshold"*); the commit-LSN-as-shared-cursor as the single coordinate that
> makes "one system, not two" literal; and a development path that hardens the engine + the outbox toward
> ADR-A, with the bus archive (emq3.5) falling out of a floor already in place.
>
> The discipline holds regardless of lens: **forks are SURFACED, never decided** — each closes with a ranked
> recommendation and the one carrying reason, and pre-empts the bus lens's strongest objection. **NO-INVENT**
> — every as-built surface is cited to `file:line`, every unbuilt surface forward-tense. **Authored
> independently** — the sibling bus-led lens (`A-lens.md`) was not read. Convergence is confidence;
> divergence is the signal.

---

## §0 · Context

**What this chapter is.** The platform chapter is Chapter IV of the Echo Persistence manuscript — where the
bus (EchoMQ 3.0, the Stream Tier) and the durable floor (the engines + store of the prior chapters) are shown
to be **one system**, joined at exactly three seams (a shared cursor, an outbox, a fold), and then the door
opens onto BCS (the substrate stops being plumbing and becomes the way systems are built). From the
persistence lens this chapter is the payoff: the floor built across thirteen modules is revealed as the
threshold, and the bus is its first and most demanding *client*, not its spine. The question this chapter
settles is the platform's organizing one — **is development bus-led or persistence-led?** — and that ruling
drives where the merge-read watermark lives, what vocabulary the platform adopts, and what comes next after the
Stream Tier.

**What is as-built (verified at source this session).**

- **The commit LSN is the shared cursor — the literal join.** *"A number that means 'this much is durable' on
  the store side is the identical number that means 'subscribe from here' on the bus side … they share a
  cursor"* (`bus-and-persistence/index.md` §1). The native engine publishes commit notices on
  `graft:{vol}:commits` (`sync.ex:41`); the Committer drains them to the work bus (`committer.ex:99-107`).
- **The loop closes via the fold, and the bus's retention drives the engine's commit.** *"The engine's commit
  drives the bus and the bus's retention drives the engine's commit … 'the bus and the store are one system'
  is not a slogan: it is a literal loop"* (`bus-and-persistence/the-loop-closes.md` §2). The fold:
  *"a dedicated fold consumer … commits those slices into the engine with `EchoStore.Graft.commit/3` —
  fold-before-trim … the fold watermark always sits at or ahead of the trim watermark"* (`the-loop-closes.md`
  §1).
- **The merge-read watermark `W` is named.** A deep read *"concatenates the segments below `W` (now in the
  store) with the live tail at or above `W` (still on the bus), with no gap and no overlap, because the same
  watermark divides them"* (`the-loop-closes.md` §1; `streams.synthesis.md` F3.5-B: scalar `W` from the
  engine's committed frontier — CONVERGED across the prior two-architect debate).
- **The durable floor was the threshold; the substrate becomes BCS.** *"That floor was never the point; it was
  the threshold … the queue was simply the first thing the platform built on it — the load-bearing proof that
  the floor holds"* (`the-door-to-bcs/index.md` §1). The three primitives (versioned commit log,
  `EchoStore.Table` L1, `EchoStore.Coherence` newer-wins where the branded id IS the version) describe *"a
  place to keep any system's state"* (§1) — the BCS door.
- **The outbox sits to ONE SIDE of the cycle.** *"The outbox (12.2) sits to one side of this cycle, keeping
  the enqueue hot path off durable storage while still surviving a crash"* (`the-loop-closes.md` §2) — the bus
  stays volatile (D-2), durability is beside it (`durability.ex:6-9`).
- **The Stream Tier's live frontier.** emq3.1–3.4 SHIPPED; **emq3.5 NEXT** (the archive fold), emq3.6
  (time-travel + hydration). The v2 master invariant binds every 3.x rung unchanged (`emq.streams.md`).

> **The one question this chapter must answer well, from this lens:** Is the platform a bus with persistence
> bolted beneath it, or a **durable substrate with the bus as its first client**? The manuscript answers
> persistence-led in its own voice (*"the floor the bus stands on"*); this chapter's job is to argue that
> reading rigorously, show it drives the concrete decisions (the watermark's home, the vocabulary, the
> development path), and pre-empt the bus lens's case that the bus is the spine.

---

### F-PLAT-A — the spine (THE reframe): bus-led vs persistence-led

**The fork.** What is the platform's spine — the bus (the bus is primary; persistence is a durable floor it
writes through) or the durable engine (the engine is the universal substrate; the bus is one client of it)?
This is the organizing decision that drives the development path.

> **Arm A1 — persistence-led (the engine is the substrate; the bus is a client).** The durable engine (Champ
> accept → Graft commit → Tigris) is the platform's universal floor. The bus is ONE client of that floor,
> beside the cache, the Tables, and the workers. Development hardens the engine + the outbox; the bus's Stream
> Tier archive (emq3.5) is a CONSEQUENCE of the floor already being there.
>
> - *Rationale.* The manuscript's own gravity is persistence-led: the floor *"was never the point; it was the
>   threshold"* and *"the queue was simply the first thing the platform built on it — the load-bearing proof
>   that the floor holds"* (`the-door-to-bcs/index.md` §1). The loop closes because *"the bus's retention
>   drives the engine's commit"* (`the-loop-closes.md` §2) — the engine is the destination, the bus the
>   tributary. And the dependency direction agrees: `echo_store` (durability) depends on `echo_mq` (the bus),
>   so durability sits ABOVE the bus in the dependency graph — the store owns durability, the bus rides under
>   it.
> - *5W.* **Why** — the engine is the only surface every other surface consumes (the outbox, the archive, the
>   cache invalidation, the Tables, BCS state all ride it); a substrate every client dogfoods is the spine.
>   **What** — read the platform as a durable floor with clients; sequence development as "deepen the floor
>   toward ADR-A; the bus archive falls out." **Who** — the platform; each surface a peer client of the floor.
>   **When** — the reframe is now; the development path it implies is F-PLAT-D. **Where** — the engine
>   (`EchoStore.Graft`, `graft.ex`); the outbox (`plugins/graft.ex`, the `@obx_base` reserved range); the v4
>   ADRs (`echo_mq-v4-durability-adr.md`); the dependency table (`echo/CLAUDE.md` §1).
> - *Steelman.* Three independent facts converge on persistence-led, and the convergence is the argument.
>   (1) **The manuscript** teaches it directly (the floor is the threshold; the bus is the first client; the
>   door past the floor is BCS — *"if state is this cheap to keep and this safe to share, what is the right
>   shape for the systems that keep it?"*, `the-door-to-bcs/index.md` §1). (2) **The dependency graph** puts
>   durability above the bus (`echo_store → echo_mq`), so the bus structurally CANNOT own durability — the
>   store does, and reaches down to the bus (the as-built `Committer`, `committer.ex`). (3) **The v4 north
>   star** (ADR-A) makes the engine's commit log the universal substrate — the outbox, and the bus's whole
>   durable story, become tenants of one append-only fenced replicated log. Read together: the engine is the
>   floor, the bus is a client, and the platform's whole forward motion is the engine deepening into the
>   substrate the bus (and the cache, and BCS) stand on. This is not a demotion of the bus — the bus is the
>   load-bearing FIRST client, the proof the floor holds — it is a correct identification of which surface is
>   the spine.
> - *Steward.* The honest multi-year cost: persistence-led sequencing front-loads engine/outbox hardening
>   (ADR-A, ADR-E) and treats the bus's most visible feature (the archive) as a downstream consequence, which
>   can read as "the bus waits on the store." The steward's answer is the sequencing in F-PLAT-D: the bus's
>   Stream Tier ships its writer/readers/retention (emq3.1–3.4, DONE) WITHOUT waiting on anything — those are
>   bus-side; only the archive (emq3.5) consumes the floor, and it consumes a floor ALREADY complete (the
>   native engine, eg.1–eg.5 shipped). So persistence-led does not stall the bus; it correctly orders the ONE
>   rung that crosses into durability.

> **Arm A2 — bus-led (the bus is the spine; persistence is a durable floor it writes through).** EchoMQ is the
> platform's organizing surface — work, signals, the event log all flow through it — and persistence is the
> durable backing the bus writes through when a value must survive. Development is bus-led: the bus's needs
> drive what the floor must provide.
>
> - *Rationale.* The bus is what consumers touch — they enqueue, subscribe, stream; the durable floor is
>   plumbing the bus calls when it needs durability. The platform's surface area IS the bus, so the bus's
>   roadmap is the platform's roadmap.
> - *5W.* **Why** — the bus is the consumer-facing surface; its requirements drive the floor. **What** — read
>   the platform as a bus with a durable backing; sequence development by bus rungs (the Stream Tier ladder).
>   **Who** — the bus as spine; persistence as a service. **When** — standing. **Where** — `emq.streams.md`
>   (the Stream Tier ladder as the platform's forward plan).
> - *Steward.* The bus-led reading is honest about what consumers see (the bus IS the surface), and the Stream
>   Tier ladder is real forward motion. But the steward's caution — and the lens's whole argument — is that it
>   inverts the dependency and the manuscript: the bus structurally depends on `echo_store` for durability
>   (`echo_store → echo_mq` means the store consumes the bus, so durability is ABOVE the bus, not beneath it),
>   and the manuscript explicitly refuses the "bus on one side, database on the other" split as two stacks
>   bolted together (`bus-and-persistence/index.md` §1). Bus-led also mis-sequences the v4 north star: ADR-A
>   makes durability the substrate the bus rides, not a service the bus drives — reading the bus as the spine
>   would put the engine's evolution downstream of the bus's, when the manuscript and the ADRs put it upstream.

**Ranked recommendation (Lens B — persistence-led): A1 (persistence-led — the engine is the substrate, the
bus is its first client), strongly.** A1 carries on the convergence of three independent facts: the
manuscript teaches it (*"the floor the bus stands on"*; the floor is the threshold; BCS is the door past it),
the dependency graph enforces it (durability is above the bus; the store reaches down), and the v4 north star
realizes it (ADR-A makes the engine's log the universal substrate). The reframe is not a re-ranking of
importance — the bus is the load-bearing FIRST client — it is the correct identification of the spine, and it
drives the concrete decisions below: the watermark lives with the engine (F-PLAT-B), the vocabulary is the
established "Echo Bus + Echo Persistence" (F-PLAT-C), and the development path hardens the floor toward ADR-A
(F-PLAT-D).

> **Pre-empted bus-lens objection:** *"The bus is the platform — it is what every consumer touches, every
> course teaches it as the headline (`/echomq`, the Stream Tier is the active program), and persistence is the
> durable backing it writes through. Calling the bus 'one client' demotes the surface that IS the product to a
> peer of the cache."* Answer: 'one client' is not a demotion — the manuscript calls the bus the
> load-bearing FIRST client, *"the proof that the floor holds"* (`the-door-to-bcs/index.md` §1) — it is a
> structural fact about the dependency graph. The bus cannot be the spine that owns durability because
> `echo_store` (durability) depends on `echo_mq` (the bus): the store consumes the bus, reaches down to it
> (the as-built `Committer`), and owns the durable engine the bus's archive must use. The bus being the
> consumer-facing surface and the engine being the spine are not in tension — a building's lobby is what
> visitors touch, but the foundation is what holds it up. The persistence lens's claim is precisely that the
> platform's forward motion (the v4 ADR-A north star) is the FOUNDATION deepening into the universal
> substrate, with the bus, the cache, and BCS all standing on it — and reading the bus as the spine would
> invert that, sequencing the engine's evolution downstream of the bus's when the manuscript and the ADRs put
> it upstream. The bus is the headline; the engine is the spine; both are true.

---

### F-PLAT-B — the merge-read watermark `W` (engine-derived vs bus-side keyspace key)

**The fork.** The deep read concatenates segments below `W` (in the engine) with the live tail at/above `W`
(on the bus). Where does `W` live: a scalar derived from the engine's folded frontier, or a bus-side keyspace
watermark (`emq:{q}:stream:<name>:archived`) the fold updates and the merge consults?

> **Arm B1 — `W` is derived from the engine's committed frontier (the archive owns its own extent).** `W` is a
> branded id read from the engine — the top id of the last folded/committed segment. The merge-read computes
> the cut from the archive's own truth; no separate bus-side index.
>
> - *Rationale.* The archive's extent is the archive's truth — the highest id durably folded is a fact the
>   engine already knows (its committed frontier). Deriving `W` from the engine means the cut cannot drift
>   from what is actually durable. This is the shared-cursor discipline (the commit LSN is one number read two
>   ways) applied to the archive boundary.
> - *5W.* **Why** — one authority for the archive's extent (the engine that holds it); no drift between the
>   cut and the durable truth. **What** — `W` = the engine's committed frontier (a branded id), read on the
>   deep read. **Who** — the merge-read derives it from the engine; the fold consumer advances the frontier by
>   committing. **When** — emq3.5. **Where** — the engine's committed frontier (the native engine's head/LSN
>   extent, `EchoStore.Graft.commit/3` advances it, `graft.ex:41`; the order theorem makes `W` a clean branded
>   sort key); `streams.synthesis.md` F3.5-B CONVERGED on this (scalar `W` from the engine's committed
>   extent).
> - *Steelman.* This is the persistence lens's central principle made concrete: the engine OWNS the durable
>   extent, so the cut is derived from the owner, not cached in a follower. Because the fold enforces
>   fold-before-trim (commit durably, then trim — `the-loop-closes.md` §1, the fold watermark at/ahead of the
>   trim watermark), every id `≤ W` is in a segment (no gap) and no id `> W` is in a segment (no overlap), so
>   the no-gap/no-overlap property is a CONSEQUENCE of fold-before-trim + the order theorem, not a second
>   invariant to maintain. And `W` being a branded id means it sorts with everything else — no second clock,
>   no separate index. The prior two-architect debate CONVERGED here (`streams.synthesis.md` F3.5-B), which is
>   strong evidence the engine-derived `W` is right.
> - *Steward.* The honest cost: deriving `W` from the engine on each deep read is a read of the engine's
>   extent (a cross-component read, store-side). It is read ONCE per deep-read (not per entry), and the
>   read-path cost is dominated by the segment fetch from Tigris/CubDB anyway, so the soundness win (no drift)
>   is worth one small read. IF measurement later shows the `W` read is hot, a cached bus-side value (B2) is
>   the additive optimization — but a cache, derived from the engine, never the source of truth.

> **Arm B2 — `W` is a bus-side keyspace watermark (`emq:{q}:stream:<name>:archived`, a string the fold updates,
> the merge consults).** The fold writes `W` into a braced keyspace key; the merge-read reads it from the bus
> keyspace; a polyglot reader can SEE the archive frontier without calling the engine.
>
> - *Rationale.* A polyglot client computing its own merge cut needs `W` visible at the wire, in the bus
>   keyspace it already speaks — not behind an engine call it cannot make. A bus-side `W` makes the archive
>   frontier a first-class, wire-visible value.
> - *5W.* **Why** — make `W` visible to a polyglot reader at the wire. **What** — a braced keyspace key
>   `emq:{q}:stream:<name>:archived` carrying `W`. **Who** — the fold consumer writes it; the merge-read (and
>   a polyglot reader) reads it. **When** — emq3.5. **Where** — the braced grammar (a new §6 subkey on the
>   `{q}` slot — declared-keys clean, but per the subkey-cleanup law it MUST name what retires it on stream
>   destroy, or it leaks).
> - *Steward.* The polyglot-visibility win is real — a non-BEAM reader computing the merge cut wants `W` at
>   the wire. But the steward's load-bearing caution: a bus-side `W` is a SECOND authority for a fact the
>   engine already owns (the archive's durable extent), and two authorities for one fact is the drift surface
>   the shared-cursor design exists to eliminate. If the bus-side `W` and the engine's true frontier disagree
>   (a fold that committed but failed to update the key, or vice versa), the merge-read gains a gap or an
>   overlap the order theorem cannot close. The steward refuses to make a polyglot-visible bus key the SOURCE
>   OF TRUTH for the engine's extent — cache it, derive it, but the engine owns it. Plus the new subkey carries
>   the cleanup-disposition obligation (the subkey-leak law).

**Ranked recommendation (Lens B — persistence-led): B1 (`W` derived from the engine's committed frontier),
with B2's keyspace key available as a DERIVED cache if polyglot-visibility demands it — never as the source of
truth.** B1 carries because it makes the no-gap/no-overlap property a CONSEQUENCE of fold-before-trim rather
than a second invariant, keeps the archive's extent in one authority (the engine that holds it), and the prior
two-architect debate already CONVERGED on it (`streams.synthesis.md` F3.5-B). If a polyglot reader must
compute the merge cut itself, B2's bus-side `W` is the right ADDITIVE surface — but as a cache derived from
the engine's frontier, with its cleanup disposition named, never as a second source of truth. The choice of
whether polyglot-visibility is required is the Operator's; the source-of-truth question is not (the engine
owns its extent).

> **Pre-empted bus-lens objection:** *"A deep read is a bus operation — the reader is on the bus, the live
> tail is on the bus, and a polyglot client reads the bus keyspace, not the engine. Putting `W` in the bus
> keyspace (B2) keeps the whole merge-read on one surface the reader already speaks; deriving it from the
> engine forces a cross-app read into every deep read's hot path."* Answer: the persistence lens AGREES the
> deep read is consumer-facing and AGREES that IF a polyglot reader must compute the cut, a wire-visible `W`
> (B2) serves it — as a derived cache. Where it does not yield is on the source of truth: the archive's
> durable extent is a fact the ENGINE owns (it is what the engine has committed and replicated), and the
> shared-cursor discipline the whole platform runs on (the commit LSN is one number, not two kept in sync)
> says the cut is DERIVED from that owner, never duplicated into a follower as the authority. The cross-app
> read the bus lens worries about is one read per deep-read, dominated by the Tigris/CubDB segment fetch the
> read does anyway — a negligible cost for eliminating the drift between the cut and what is actually durable.
> B2's bus-side `W` as a CACHE (derived, refreshed from the engine) gives the polyglot reader its wire-visible
> value AND keeps the engine the authority; B2 as the SOURCE OF TRUTH gives two authorities for one fact and a
> merge-read whose correctness depends on them never disagreeing — exactly the fault the engine-derived `W`
> makes structurally impossible.

---

### F-PLAT-C — vocabulary coherence: "platform" / "Echo Bus + Echo Persistence" vs "EchoMesh"

**The fork.** The vision manuscript's established vocabulary is *"Echo Bus (EchoMQ on Valkey) carries the work,
and Echo Persistence keeps the state"* (`persistence-in-the-platform.md`). `mesh.8.1` offers the PROPOSED
"EchoMesh weave" (a CAP-segmented composition). Does the development path unify these, or keep them distinct —
and which vocabulary does it adopt?

> **Arm C1 — keep them distinct; the development path adopts "Echo Bus + Echo Persistence" (the established,
> shipped vocabulary), and treats "EchoMesh" as the PROPOSED senior frame it stands beneath.** The platform's
> working vocabulary is the manuscript's "Echo Bus + Echo Persistence" (established, status-shipped); EchoMesh
> stays the forward-tense, course-taught weave (PROPOSED composition over shipped substrate), not the
> development path's working name.
>
> - *Rationale.* The two have different epistemic status. "Echo Bus + Echo Persistence" describes shipped,
>   as-built surfaces (the bus, the engines, the store — all on disk, `status: established` in the manuscript).
>   "EchoMesh" is explicitly a PROPOSED composition taught forward-tense (the repo's own framing:
>   *"EchoMesh is the weave, taught forward-tense, not a shipped product … a PROPOSED composition over shipped
>   substrate"*, `CLAUDE.md` mesh.8.1 summary). Adopting EchoMesh as the development path's working vocabulary
>   would assert-as-shipped a frame the program deliberately keeps proposed.
> - *5W.* **Why** — match the working vocabulary to as-built reality; reserve the proposed frame for the
>   senior course voice. **What** — development speaks "Echo Bus + Echo Persistence"; EchoMesh remains the
>   forward-tense weave. **Who** — the development path; the course corpus (`/mesh`, `/art`) carries EchoMesh.
>   **When** — standing. **Where** — `persistence-in-the-platform.md` (the established vocabulary);
>   `mesh.8.1.md` (the PROPOSED weave); the `/mesh` course (EchoMesh taught forward-tense).
> - *Steelman.* The persistence lens prizes honest status. The manuscript is `status: established` and
>   describes things that exist; EchoMesh is `status: PROPOSED` and describes a composition that is taught, not
>   shipped. Keeping them distinct keeps the development path's vocabulary grounded in the as-built (no
>   asserting a proposed weave as the working reality) while preserving EchoMesh as the legitimate senior frame
>   for the course corpus, which explicitly teaches it forward-tense. Unifying them under one name would either
>   demote EchoMesh from its proposed status (asserting it shipped) or inflate "Echo Bus + Echo Persistence"
>   into a CAP-weave claim the as-built does not yet make — both dishonest about status.
> - *Steward.* The honest cost: two vocabularies is a small ongoing coherence tax (a reader must know that
>   "the platform" / "Echo Bus + Echo Persistence" is the as-built and "EchoMesh" is the proposed senior
>   frame over the same substrate). The steward accepts it because the alternative — one name spanning shipped
>   and proposed — erases exactly the status distinction the program's NO-INVENT/forward-tense discipline
>   exists to preserve. The two names mark two epistemic states; that is a feature, not a debt.

> **Arm C2 — unify under one vocabulary (adopt "EchoMesh" as the platform's name, or fold "Echo Persistence"
> into the EchoMesh weave).** One name for the whole — the bus, the engines, the store, the CAP segmentation —
> taught and developed as "EchoMesh."
>
> - *Rationale.* One vocabulary is simpler to teach and to reason about; EchoMesh is the senior frame that
>   already encompasses the bus and the persistence tiers as CAP-segmented surfaces, so folding everything
>   under it gives a single mental model.
> - *Steward.* Simplicity is real, but the steward's verdict against C2: it collapses the status distinction
>   the program guards. EchoMesh is PROPOSED (a composition taught forward-tense over shipped substrate);
>   "Echo Bus + Echo Persistence" is ESTABLISHED (as-built). Adopting EchoMesh as the working vocabulary for
>   the development path would assert a proposed weave as the shipped reality — the exact assert-as-shipped
>   error the forward-tense discipline forbids. The unification is the right SENIOR framing for the course
>   corpus (where EchoMesh is legitimately taught), but it is the wrong WORKING vocabulary for a development
>   path that must stay grounded in what is on disk.

**Ranked recommendation (Lens B — persistence-led): C1 (keep them distinct; the development path adopts the
established "Echo Bus + Echo Persistence"; EchoMesh remains the PROPOSED senior frame).** C1 carries because
the two vocabularies mark two epistemic states the program's NO-INVENT/forward-tense discipline exists to
preserve: "Echo Bus + Echo Persistence" is as-built (`status: established`), EchoMesh is a PROPOSED composition
taught forward-tense. The development path must speak the as-built vocabulary; EchoMesh stays the legitimate
senior frame for the course corpus over the same substrate. Unifying would erase the status distinction — the
right move for the senior course voice, the wrong move for a grounded development path.

> **Pre-empted bus-lens objection:** *"EchoMesh is the architecturally complete vision — CAP-segmented
> surfaces over one branded identity — and the development path should aim at it as the destination, adopting
> its vocabulary as the unifying frame rather than the narrower 'Echo Bus + Echo Persistence.'"* Answer: the
> persistence lens AGREES EchoMesh is the architecturally complete senior vision and that the development path
> aims toward the composition it describes (the engine as substrate, the bus as a CAP-availability-first
> client — that IS the EchoMesh segmentation). Where it does not yield is on the working VOCABULARY: EchoMesh
> is, by the program's own framing, a PROPOSED composition taught forward-tense, not a shipped product
> (`CLAUDE.md` mesh.8.1 summary). A development path's working vocabulary must name what is on disk —
> asserting "EchoMesh" as the platform's working name would claim-as-shipped a weave the program deliberately
> keeps proposed, the exact forward-tense violation the NO-INVENT discipline guards. The destination can be
> the EchoMesh composition while the working vocabulary stays the established "Echo Bus + Echo Persistence" —
> the senior frame for the course, the as-built names for the build. Aiming at EchoMesh and speaking
> as-built are not in tension; conflating the proposed frame with the shipped vocabulary is the error.

---

### F-PLAT-D — the development-path sequencing (what's next after emq3.5 + emq3.6, from the persistence lens)

**The fork.** After the Stream Tier completes (emq3.5 the archive, emq3.6 time-travel + hydration), what is
the next development line from the persistence lens?

> **Arm D1 — the v4 commit-log-as-outbox line (ADR-A) is next: make the Graft commit log the canonical
> transactional substrate, subsuming the SQLite journal (ADR-E).** After the Stream Tier, the development path
> turns to the v4 north star: `EchoStore.Durability.Graft` (the already-built outbox-as-commit-log) becomes
> the canonical durability tier, the transactional-enqueue boundary moves entirely onto the engine's commit
> (ADR-A: datum + intent in one `commit/3`), and `exqlite` retires on the named schedule (ADR-E).
>
> - *Rationale.* This is the keystone of the persistence lens and the platform's named forward direction. The
>   v4 ADR is ALREADY written and Operator-review-ready (`echo_mq-v4-durability-adr.md`), the outbox is
>   ALREADY half-built (`plugins/graft.ex`, the `@obx_base` reserved range, `replay/2` recovery, the Committer
>   drain), and ADR-E's retirement is conditioned on rebuildability — which ADR-A RESTORES (nothing durable in
>   SQLite anymore). The Stream Tier proves the engine carries the bus's archive; the v4 line proves the
>   engine carries the bus's DURABILITY, completing the "engine as universal substrate" arc.
> - *5W.* **Why** — consummate the v4 north star: one durable engine, the founding no-SQL intent restored as
>   fact, durability as one atomic act off SQL. **What** — ADR-A (commit-log-as-outbox canonical), ADR-C (the
>   stream-subscriber committer — already as-built, `committer.ex`), ADR-E (`exqlite` retires); the
>   `EchoStore.intend/4` surface (forward-tense, ADR-G). **Who** — the platform durability owner; the bus
>   consumes it unchanged (`enqueue` is unchanged, `echo_mq-v4-durability-adr.md` "What does not change").
>   **When** — after the Stream Tier, the v4 line. **Where** — `EchoStore.Durability.Graft` (`plugins/graft.ex`,
>   already built); the v4 ADRs (`echo_mq-v4-durability-adr.md`); the SQLite retirement (ADR-E).
> - *Steelman.* The development path the persistence lens proposes is exactly this: harden the engine + the
>   outbox; the bus archive (emq3.5) is a consequence of the floor already being there, and the v4 line is the
>   floor becoming the universal transactional substrate. The pieces are in place (the outbox built, the ADR
>   written, the committer shipped), the sequencing is clean (ADR-A frees ADR-E; ADR-A determines ADR-C — the
>   couplings the v4 ADR proves cohere), and the destination is the founding intent made fact: *"there were no
>   plans to use SQL"* and the one place SQL entered is scheduled out (`echo_mq-v4-durability-adr.md` ADR-E).
>   This is not a new program — it is the consummation of a direction already half-built and fully specced.
> - *Steward.* The honest cost is the migration's sequencing (ADR-E open Q4: the retirement timeline relative
>   to the Phase-1 Graft-history work it shares a substrate with) and the OCC-retry contract the v4 surface
>   introduces (ADR-A/G: callers honor `{:error, {:conflict, head}}` — open Q2: does the common consumer
>   accept it, or is a serialization helper needed?). Both are NAMED open questions in the v4 ADR, the
>   Operator's to rule — the steward surfaces them, does not pretend they are closed.

> **Arm D2 — the BCS-substrate line is next: deepen the door-to-BCS (Tables/Properties/Edges over the engine)
> as the platform's forward direction.** After the Stream Tier, the development path turns to BCS: the
> substrate's three primitives (the versioned log, the L1 Table, newer-wins coherence) become the full BCS
> system surface (PropertyStore, EdgeStore, Archetypes) the codemojex apps ride.
>
> - *Rationale.* The manuscript's own finale is the door to BCS (*"the durable substrate stops being plumbing
>   and starts being the Branded Component System"*, `the-loop-closes.md` §2; `the-door-to-bcs/index.md`). The
>   floor was built to be the BCS substrate; the next move is through the door.
> - *Steward.* The BCS line is real and IS the manuscript's finale, but the steward's sequencing caution: BCS
>   over the engine is largely ALREADY built (the BCS reference systems `Bcs.{PropertyStore,EdgeStore,
>   Archetypes}` exist, `echo/CLAUDE.md` §2; the Tables + Coherence are shipped), whereas the v4 outbox line
>   (D1) is the floor's own DURABILITY evolution that is half-built and fully specced but not yet canonical.
>   The persistence lens orders D1 BEFORE deepening D2: make the engine the universal TRANSACTIONAL substrate
>   (ADR-A) first, because BCS state riding the engine wants that durability story complete. D2 is the
>   destination the floor was built for; D1 is the floor finishing the substrate D2 stands on. They are not
>   exclusive — D1 sequences ahead of a deeper D2.

**Ranked recommendation (Lens B — persistence-led): D1 (the v4 commit-log-as-outbox line / ADR-A) is the next
development line, sequencing ahead of a deeper BCS push (D2).** D1 carries because it is the keystone of this
lens and the platform's named, half-built, fully-specced forward direction: the engine becomes the universal
transactional substrate (ADR-A), the outbox is unified with durability in one `commit/3`, SQLite retires
(ADR-E), and the founding no-SQL intent is restored as fact. The Stream Tier proves the engine carries the
bus's archive; the v4 line proves it carries the bus's durability — completing the "engine as universal
substrate" arc. D2 (BCS) is the destination the floor was built for, sequenced AFTER the floor's own
durability evolution completes (the substrate BCS stands on). The exact sequencing, and the v4 ADR's named
open questions (the retirement timeline, the OCC-retry contract), are the Operator's.

> **Pre-empted bus-lens objection:** *"After the Stream Tier, the next move is more BUS — deepen the streams
> (object payloads, more groups, the log-tier exit), because the bus is the active program and the Stream
> Tier's seams (`emq.streams.md` §Seams) are the live frontier. The v4 durability line is a store-internal
> evolution, not the platform's forward motion."* Answer: the persistence lens reads the platform's forward
> motion as the FLOOR's evolution, not the bus's seams — and the v4 line is precisely that: the engine
> becoming the universal transactional substrate (ADR-A), which the manuscript names as where EchoMQ 4+ is
> heading *"in the large"* (`the-commit-log-is-the-outbox.md` §2: *"this is exactly where EchoMQ 4+ is heading
> … ADR-A makes the commit-log-as-outbox the journal itself, atomic and durable in one act, off SQL"*). The
> bus's Stream Tier seams (object payloads, the log-tier exit) are explicitly PARKED until a real consumer
> presents large-end demand (`emq.streams.md` §Seams: *"if a real consumer ever presents large-end demand …
> the log tier and only the log tier moves"*) — they are not the live frontier, they are reserved exits. The
> live, named, half-built forward direction is the v4 outbox line, which the v4 ADR has already specced and
> the outbox has already half-built. Deepening the bus past the Stream Tier waits for demand that does not yet
> exist; deepening the floor toward ADR-A consummates a direction already in motion. The persistence lens
> sequences the floor's durability evolution (D1) ahead because it is the substrate the bus — and BCS, and the
> cache — all stand on, and completing it is what makes everything above it solid.

---

## §Fork ledger (Lens B — persistence-led)

| Fork | Lens-B ranked arm | One-line reason |
|---|---|---|
| **F-PLAT-A** the spine (THE reframe) | **A1** persistence-led (engine = substrate, bus = first client) | The manuscript teaches it (*"the floor the bus stands on"*), the dependency graph enforces it (`echo_store → echo_mq`), the v4 north star realizes it (ADR-A) — three facts converge. |
| **F-PLAT-B** merge-read watermark `W` | **B1** `W` derived from the engine's committed frontier; B2 keyspace key as a DERIVED cache if polyglot-visible | No-gap/no-overlap is a CONSEQUENCE of fold-before-trim, not a second invariant; the engine owns its extent (one authority); the prior debate CONVERGED here. |
| **F-PLAT-C** vocabulary coherence | **C1** keep distinct; development speaks established "Echo Bus + Echo Persistence"; EchoMesh stays the PROPOSED senior frame | The two names mark two epistemic states (as-built vs proposed-forward-tense) the NO-INVENT discipline exists to preserve. |
| **F-PLAT-D** development-path sequencing | **D1** the v4 commit-log-as-outbox line (ADR-A) is next, ahead of a deeper BCS push (D2) | The keystone + the named, half-built, fully-specced forward direction: the engine becomes the universal transactional substrate; SQLite retires; the no-SQL intent restored as fact. |

**Where I most expect to DIVERGE from the bus lens (this chapter):**
- **F-PLAT-A** — the headline divergence of the whole KB: bus-led vs persistence-led. The bus lens likely
  reads the bus as the spine (the consumer-facing surface, the active program); the persistence lens reads the
  engine as the spine (the substrate every client dogfoods, above the bus in the dependency graph).
- **F-PLAT-D** — likely divergence on what's next: the bus lens probably sequences more bus (the Stream Tier
  seams, deeper streams); the persistence lens sequences the v4 ADR-A durability line ahead (the floor's own
  evolution).
- **F-PLAT-B** — possible convergence on the engine-derived `W` (the prior two-architect debate converged),
  with divergence on whether a bus-side `W` is a peer surface (bus lens) or strictly a derived cache
  (persistence lens).
- **F-PLAT-C** — likely a soft divergence: both may keep the vocabularies distinct; the lenses may part on
  whether EchoMesh is the aimed-at unifying frame (bus lens may lean toward it) or strictly the proposed
  senior course frame (persistence lens).

---

## §Manuscript reconciliation (proposed from this lens — PROPOSE only; the Director applies)

1. **`platform/bus-and-persistence/index.md` §4 — resolve the status drift: Module 14 is marked `_(soon)_`
   though it is `status: established` and built.** Line 36 calls Module 14 *"(soon)"*, but
   `the-door-to-bcs/index.md` is `status: established` and `the-door-to-bcs/index.md` §4 states *"all fourteen
   modules are built."* *Proposed:* drop the `_(soon)_` on the Module 14 pointer in §4 (it contradicts the
   target's own established/built status). A docs-internal inconsistency the recon flagged — surfaced for the
   Director, who owns the manuscript edit.

2. **`emq.streams.md` ladder table — the header still labels SHIPPED rungs "PROPOSED."** The table header
   (line 66) reads *"Ships (PROPOSED)"* for every rung, but emq3.1–3.4 are SHIPPED (`emq.streams.md` line 4:
   *"`emq3.1`–`emq3.4` SHIPPED, `emq3.5` is next"*). The per-rung "Ships (PROPOSED)" column now mislabels four
   shipped rungs. *Proposed:* re-label the shipped rungs' status in the table (or split the column into
   shipped/proposed), so the table agrees with the document's own status line. This is a docs-vs-as-built
   inconsistency the recon flagged; `emq.streams.md` is the bus canon (reconcile-only — the Operator/Director
   rules the edit, I surface it).

3. **`platform/bus-and-persistence/the-loop-closes.md` §1 — the framing already matches this lens; reinforce
   the watermark's authority.** §1 names `W` and fold-before-trim correctly and persistence-led. The only
   addition F-PLAT-B implies: a sentence that `W` is DERIVED from the engine's committed frontier (the engine
   owns its extent), so the no-gap/no-overlap property is a consequence of one authority — making explicit
   what the dive teaches implicitly. (Additive, optional; the dive is already sound.)

4. **No edit forced to `the-door-to-bcs/index.md`** — its persistence-led framing (*"that floor was never the
   point; it was the threshold"*) is the manuscript's existing endorsement of the reframe (a CONVERGENCE
   point). Flagged, not edited.

---

## §What I deliberately did NOT decide

- **Every fork is the Operator's.** A1-vs-A2 (the spine), B1-vs-B2 (the watermark's home/authority),
  C1-vs-C2 (the vocabulary), and D1-vs-D2 (the next development line) are recommendations with one reason each
  — the choice belongs to the Operator after the Director stages this lens against the bus lens. F-PLAT-A is
  the headline ruling the whole KB turns on; I argue persistence-led but do not decide it.
- **The v4 ADR's open questions stay open** (D1) — the `exqlite` retirement timeline (ADR-E Q4), the OCC-retry
  contract's acceptability (ADR-A/G Q2), the single-volume guarantee's adequacy (ADR-F Q3) — all named in the
  v4 ADR as the Operator's, surfaced not closed.
- **The Stream Tier seams** (object payloads, the log-tier exit, exactly-once) stay PARKED as
  `emq.streams.md` §Seams sets them — I do not reopen them.
- **No canon edit, no engine edit, no code, no git.** This document touches exactly one file (itself); the
  manuscript edits above are PROPOSED for the Director.

---

## §Surface citations (NO-INVENT)

**As-built (module / file:line — verified at source this session):**

- The commit-LSN-as-shared-cursor — the native engine's `Sync` publishes notices on `graft:{vol}:commits`
  (`sync.ex:41`); the `Committer` drains them to the work bus (`committer.ex:99-107`), persisted SyncPoint
  frontier (`:110-114`) — `echo/apps/echo_store/lib/echo_store/graft/{sync,committer}.ex`.
- The outbox sits to one side (D-2 holds) — `EchoStore.Durability` facade, intents low-volume, bus on Valkey
  (`durability.ex:6-9`); the outbox-as-commit-log `EchoStore.Durability.Graft`, `@obx_base = :erlang.bsl(1,48)`
  (`plugins/graft.ex:46`), `intend_and_enqueue/4` (`:110`), `replay/2` (`:155`) —
  `echo/apps/echo_store/lib/echo_store/{durability,plugins/graft}.ex`.
- The engine's commit (the fold target, the `W` source) — `EchoStore.Graft.commit/3` (`graft.ex:41`,
  defdelegated to `VolumeServer`, the single-writer OCC mailbox `volume_server.ex:129-159`) —
  `echo/apps/echo_store/lib/echo_store/graft.ex`.
- The BCS substrate primitives (the door) — `EchoStore.Table` (L1 ETS) + `EchoStore.Coherence` (newer-wins,
  the branded id IS the version); the BCS reference systems `Bcs.{PropertyStore,EdgeStore,Archetypes}`
  (`echo/CLAUDE.md` §2) — `echo/apps/echo_store/`, `echo/apps/echo_data/lib/echo_data/bcs/`.

**Forward-tense (a surface a rung BUILDS — not yet on disk):**

- The merge-read watermark `W` (F-PLAT-B) — derived from the engine's committed frontier (B1) or a bus-side
  keyspace cache (B2), emq3.5/3.6.
- The v4 surface `EchoStore.intend/4` (F-PLAT-D, ADR-G) — stages datum + intent in one `commit/3`, returns on
  durable commit or `{:error, {:conflict, head}}`; the canonical `EchoStore.Durability.Graft` after ADR-A;
  `exqlite` retirement after ADR-E.

**Canon / design cited:**

- `docs/echo-persistence/platform/**` — the chapter under reconciliation: `bus-and-persistence/index.md` (the
  shared cursor, the three seams, the Module-14 `_(soon)_` drift), `bus-and-persistence/the-loop-closes.md`
  (the loop closes, the bus's retention drives the engine's commit, `W`, fold-before-trim),
  `the-door-to-bcs/index.md` (the floor was the threshold; the substrate becomes BCS),
  `beats-classical-scheduling/the-commit-log-is-the-outbox.md` (where EchoMQ 4+ is heading: ADR-A).
- `docs/echo-persistence/overview/persistence-in-the-platform.md` — *"Echo Bus … carries the work, and Echo
  Persistence keeps the state"* (the established vocabulary); *"the floor the bus stands on."*
- `docs/echo_mq/kb/emq4-durability/echo_mq-v4-durability-adr.md` — ADR-A (commit-log-as-outbox), ADR-C (the
  stream-subscriber committer), ADR-E (`exqlite` retires), ADR-F/G (the bounded guarantee, `intend`/OCC-retry);
  the named open questions.
- `docs/echo_mq/kb/streams-tier/streams.synthesis.md` — F3.5-B CONVERGED (scalar `W` from the engine's
  committed extent); the prior two-architect debate's convergences as RULED.
- `docs/echo_mq/emq.streams.md` — the Stream Tier ladder (emq3.1–3.4 SHIPPED, emq3.5 next), the durable-archive
  answer, the PARKED seams; the "Ships (PROPOSED)" header drift.
- `docs/echo/mesh/mesh.8.1.md` (via `CLAUDE.md` mesh.8.1 summary) — the PROPOSED EchoMesh weave (a composition
  taught forward-tense over shipped substrate).
- `echo/CLAUDE.md` §1–§2 — the `echo_store → echo_mq` dependency direction; the BCS reference systems.

---

*Lens B — the persistence-led / vision-forward lens. Authored independently; the sibling bus-led lens
(`A-lens.md`) was not read. Convergence is confidence; divergence is the signal. The Director synthesizes; the
Operator rules.*
