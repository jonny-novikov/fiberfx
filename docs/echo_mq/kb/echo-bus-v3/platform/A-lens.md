# echo-bus-v3 · Chapter IV (the platform) — Lens A: BUS-LED

> **Lens A — the BUS-LED view ("the log reaches down to the floor").** This chapter argues every platform
> fork from the runtime that OPERATES and CARRIES the work: the EchoMQ Stream Tier, the platform's spine.
> The priorities, in order: (1) the Stream Tier is the spine — the log that carries work; (2) **emq3.5, the
> archive fold, is the keystone** — the bus reaching down into durable storage; (3) the forward climb
> streams → retention → archive → time-travel → the BCS substrate; (4) persistence is the **floor the bus
> stands on** — a service the bus *consumes*, never the master. This chapter CHAMPIONS: the bus as the
> development spine, the merge-read as a BUS read, the engine as the SINK, and a development path that finishes
> the stream tier, lands the fold as the next rung, and treats the engine as where trimmed segments land. It
> honors the Steward part of each arm honestly.
>
> Forks are **SURFACED, never decided**. **NO-INVENT** holds: every named surface is verified at its source
> (cited) or written forward-tense. **Authored independently — the sibling (persistence-led) lens was not
> read.**

---

## §0 · Context

**What this chapter is.** Chapter IV of the echo-persistence manuscript is the **platform** — the EchoMQ bus
(its Champ accept tier + the Stream Tier ladder), the bus+persistence "one system" join (the commit-LSN
cursor, the outbox, the fold), beats-over-classical-scheduling, and the door to BCS. From the bus lens this
chapter answers the platform's organizing question: **is the development path read forward from the BUS (the
spine that carries work, reaching down into a durable floor) or from the ENGINE (the substrate, with the bus a
client of it)?** That reframe drives everything downstream — the merge-read's watermark, the vocabulary, the
roadmap sequencing.

**What is as-built / established (verified, cited).**

- **The Stream Tier ladder is the live frontier.** emq3.1–3.4 SHIPPED (conformance 77 per the recon brief);
  **emq3.5 is NEXT** (`emq.streams.md` "Status: ACTIVE / NEXT… emq3.5 is next", re-sequenced ahead of the
  2.x-runway remainder, Operator-ruled 2026-06-22). The ladder: verbs → writer law → readers → retention →
  **archive (emq3.5)** → time-travel (`emq.streams.md` ladder; `the-stream-tier-ladder.md` §1).
- **The commit LSN is a SHARED CURSOR in a LOOP.** "When the accept tier… folds a batch into a Graft
  transaction, that batch becomes one LSN replicated to Tigris — and that same LSN is published over EchoMQ. A
  number that means 'this much is durable' on the store side is the identical number that means 'subscribe from
  here' on the bus side… the engine's commit drives the bus, and — through the archive fold — the bus drives
  the engine's commit" (`platform/bus-and-persistence/index.md` §1). **The loop is real and established — this
  chapter engages it, it does not deny it.**
- **The merge-read watermark `W` is the engine's folded frontier.** "Define the watermark `W` as the branded
  id of Graft's folded frontier: everything below `W` has been folded to segments, everything at or above `W`
  is still in the live stream… provably no gap and no overlap… because fold-before-trim… and the order theorem"
  (`the-stream-tier-ladder.md` §2). This matches the streams-tier synthesis (F3.5-B: "a single branded-id
  watermark `W` derived from Graft's folded frontier", `streams.synthesis.md` §1).
- **The door to BCS frames the floor as the substrate (the persistence-led reading, stated in canon).** "That
  floor was never the point; it was the threshold… The queue was simply the FIRST thing the platform built on
  it — the load-bearing proof that the floor holds… if state is this cheap to keep, what is the right shape for
  the systems that keep it? The answer… is BCS" (`platform/the-door-to-bcs/index.md` §1). **This is the exact
  framing F-PLAT-A must contest from the bus lens.**
- **Two vocabularies coexist.** The manuscript's established "Echo Bus + Echo Persistence" ("the platform is
  two halves that compose", `overview/persistence-in-the-platform.md` §intro) vs. mesh.8.1's PROPOSED "EchoMesh
  weave" (the CLAUDE.md whole-picture frame: "EchoMesh is the weave, taught forward-tense, not a shipped
  product").

> **The one question this chapter must answer well, from the bus lens:**
> The commit-LSN loop is real — the engine's commit drives the bus AND the bus's fold drives the engine. So
> "which leads?" is not a denial of the loop but a question about its LOAD-BEARING member for the DEVELOPMENT
> PATH: which member does work enter and exit through, which member is the live frontier the next rung extends,
> and which vocabulary and roadmap does the platform adopt going forward? The bus lens answers: the bus is the
> spine the work travels on; the engine is the durable floor at the bottom of the fold; the development path is
> the bus ladder, and emq3.5 is its next rung.

---

### F-PLAT-A — the spine (THE reframe): bus-led or persistence-led?

This is the chapter's organizing fork. The manuscript states BOTH readings — the bus+persistence loop
(`bus-and-persistence/index.md` §1) and the floor-as-substrate (`the-door-to-bcs/index.md` §1). The bus lens
argues bus-led, honestly, against the loop.

> **Arm A1 — BUS-LED: the bus is the spine; persistence is the floor the bus stands on.** The development path
> reads forward from the Stream Tier — the live ladder (emq3.1–3.6) carries work; the engine is the durable
> SINK the bus folds into; the merge-read is a bus read; the next rung is a bus rung (emq3.5).
> - *Rationale.* Work enters and exits the platform through the bus; the engine is reached, in BOTH directions
>   of the loop, ACROSS the bus's wire (the commit LSN is *published over EchoMQ*; the fold *reads off the
>   bus*). So even granting the loop, the bus is the medium every edge crosses — the load-carrying member of
>   the structure. The live frontier is a bus rung; the development path is the bus ladder.
> - *5W.* **Why** — the platform's value is delivered as work carried by the bus (jobs, streams, events); the
>   floor exists to make that work durable, not the reverse. **What** — a development path organized as the bus
>   ladder (streams → retention → archive → time-travel → BCS substrate), with persistence a consumed floor.
>   **Who** — the consumers that carry work over the bus (codemojex; the planned echo_bot Telegram consumer);
>   the bus operator. **When** — now (emq3.5 is the live next rung). **Where** — `emq.streams.md` (the ladder),
>   `the-stream-tier-ladder.md` (the bus arc), consuming `EchoStore.Graft` as the floor. **Steelman.** Three
>   structural facts carry bus-led, even granting the loop. (1) **The bus is the transport of BOTH loop edges.**
>   The engine's commit LSN does not reach a consumer directly — it is "published over EchoMQ"
>   (`bus-and-persistence/index.md` §1), so the engine speaks TO the bus; and the fold reads the trimmed tail
>   OFF the bus into the engine. Every edge of the loop crosses the bus's wire — the bus is the medium, the
>   spine the loop is strung on. (2) **The live frontier is a bus rung.** emq3.5 is NEXT (`emq.streams.md`);
>   eg.6 (the engine's next) is DEFERRED behind a deploy floor (the recon brief, `graft.engine-split.design.md`
>   §7). The platform's forward motion right now IS the bus ladder; the engine is shipped-and-consumed
>   (eg.1–eg.5), the bus is climbing. (3) **The merge-read is a BUS read.** A deep read is "segments below `W`
>   concatenated with the live tail at or above `W`" (`the-stream-tier-ladder.md` §2) — a STREAM read that
>   happens to fault into the engine for the cold portion; the consumer asks the bus (`XRANGE`/`read_deep`), and
>   the bus reaches into the floor. The engine is the sink the bus reads FROM, not the surface the consumer
>   addresses. **Steward.** The honest keep-cost: bus-led is a FRAMING, and the loop is genuinely bidirectional
>   — the engine's commit DOES drive the bus (a replica's position is the engine's LSN), so a reader who only
>   sees "bus on top" misses that the engine is the source of the durability coordinate. The bus lens must NOT
>   overclaim: it does not deny the engine mints the LSN or that the engine is the durability source-of-truth;
>   it claims only that the bus is the load-CARRYING member (work travels on it; both loop edges cross it; the
>   live frontier is a bus rung). The multi-year liability: if a future workload makes the engine the primary
>   surface consumers address directly (a raw-page store accessed without the bus), bus-led under-describes
>   that path — but no such workload is named (the named demand is bus-carried work, `emq.streams.md` §"The
>   needs").

> **Arm A2 — PERSISTENCE-LED: the engine/floor is the substrate; the bus is a client of it.** The development
> path reads forward from the durable floor — the engine is the substrate that keeps all state; the bus
> (including the Stream Tier) is one client built ON the floor; the door to BCS is the destination (the floor
> becomes the substrate for systems).
> - *Rationale.* The manuscript's own door-to-BCS framing: "the queue was simply the first thing the platform
>   built on it… the floor was never the point; it was the threshold" (`the-door-to-bcs/index.md` §1) — the
>   floor is the general substrate, the bus a first proof.
> - *5W.* **Why** — durable, replicated, coherent state keyed by identity is the general capability; the queue
>   is one application of it. **What** — a development path organized around the substrate (the engines, the
>   Table/Coherence, the commit log), with the bus a consumer. **Who** — the systems that keep state on the
>   substrate (BCS systems, codemojex). **When** — the door-to-BCS horizon. **Where** —
>   `the-door-to-bcs/index.md` (the substrate framing), the engines chapter. **Steelman.** The door-to-BCS
>   makes the strongest case: the durable floor "produced… none of it queue-specific" — a versioned log, an L1
>   cache, newer-wins coherence keyed by branded id — "the description of a place to keep ANY system's state"
>   (`the-door-to-bcs/index.md` §1). The commit LSN ORIGINATES at the engine (the engine mints it; the bus
>   subscribes), so the engine is the source of the platform's organizing coordinate. BCS — the destination —
>   is a discipline over the STORAGE substrate (Tables, Properties, Coherence), not over the bus. **Steward.**
>   The keep-cost from the bus lens: persistence-led under-describes where the platform's WORK and its live
>   development frontier actually are. The floor is shipped-and-consumed (eg.1–eg.5); the bus is the climbing
>   frontier (emq3.5 NEXT, eg.6 DEFERRED). Reading the path forward from the floor frames the live work (the
>   stream tier) as a "client built on" a finished substrate — but the substrate is finished and the bus is
>   what is being built, so the frame points at the static member and away from the moving one. It also reads
>   the LOOP as one-directional (engine → bus), eliding that the fold makes the bus drive the engine's commit
>   too (`bus-and-persistence/index.md` §1) — the bus is not merely a client, it is a co-equal loop member that
>   ALSO writes the engine.

**Ranked recommendation (Lens A — bus-led): A1 (BUS-LED — the bus is the spine, persistence the floor), with
the loop conceded and reframed as a transport asymmetry: both loop edges cross the bus's wire, so the bus is
the load-carrying member.** The reframe is not a denial of the commit-LSN loop (which is real and cited) — it
is a claim about the loop's LOAD-BEARING member for the DEVELOPMENT PATH. Three structural facts carry it: (1)
both edges of the loop travel ON the bus (the commit LSN is *published over EchoMQ*; the fold *reads off the
bus*), so the bus is the medium the loop is strung on; (2) the live development frontier is a BUS rung (emq3.5
NEXT; the engine's eg.6 DEFERRED), so the platform's forward motion IS the bus ladder; (3) the merge-read is a
BUS read that faults into the engine for the cold portion — the consumer addresses the bus, the bus reaches the
floor. A2 (persistence-led) reads the path forward from a FINISHED substrate and frames the climbing bus as a
"client built on" it — pointing at the static member and away from the moving one, and reading the loop
one-directionally. The bus lens concedes the engine mints the LSN and is the durability source-of-truth; it
claims the bus is the spine work travels on and the floor is what the bus stands on. **This is the chapter's
SHARPEST expected DIVERGENCE:** the persistence-led lens will read this exact fork the opposite way, anchored
on the door-to-BCS "the floor was the threshold, the queue was the first thing built on it" framing — and that
disagreement is the highest-value signal the debate produces for the Operator's development-path ruling.

> **Pre-empted persistence-lens objection:** *"The commit LSN ORIGINATES at the engine — the engine mints it,
> replicates it, and the bus merely SUBSCRIBES from it — so the engine is the source-of-truth and the
> organizing coordinate of the whole platform; the door to BCS confirms it (the floor is the substrate, the
> queue the first thing built on it). The bus is a client of the floor, not its spine."* Answer: that the
> engine MINTS the LSN is conceded — and it is exactly why the bus lens calls the engine the durability
> source-of-truth and the FLOOR. But minting a coordinate is not carrying the work: the LSN reaches a consumer
> only because it is *published over EchoMQ* (`bus-and-persistence/index.md` §1), so the engine's own
> coordinate travels to its readers ON the bus — the engine speaks through the bus, which makes the bus the
> spine even for the engine's output. And the loop is bidirectional: the fold makes the BUS drive the engine's
> commit (`bus-and-persistence/index.md` §1), so the bus is not a mere client — it WRITES the floor. The
> door-to-BCS framing is about the storage substrate's GENERALITY (it can keep any system's state), which is
> true and not contested — but generality of the floor is not primacy in the development path: the floor is
> shipped-and-consumed (eg.1–eg.5) while the BUS is the live climbing frontier (emq3.5 NEXT, eg.6 DEFERRED).
> The development path is read forward from where the building is happening, and that is the bus ladder. The
> floor is the threshold the bus carries work across — the spine and the floor, not the substrate and its
> client.

---

### F-PLAT-B — the merge-read watermark `W` (engine-derived scalar vs a bus-side keyspace watermark)

Canon already defines `W` as "the branded id of Graft's folded frontier" (`the-stream-tier-ladder.md` §2;
`streams.synthesis.md` F3.5-B). This fork asks whether the bus lens wants a bus-SIDE watermark key instead.

> **Arm B1 — `W` is DERIVED from the engine's folded frontier (a scalar branded id, no new bus key).** The
> merge-read computes `W` by reading the archive's own frontier (the highest folded id / the engine's head
> LSN); no separately-maintained `emq:{q}:stream:<name>:archived` key.
> - *Rationale.* The archive is the One authority for "what is archived"; deriving `W` from its frontier means
>   the watermark can never drift from the actual archive contents — a separately-maintained key is a second
>   source of truth that can disagree with the engine (the dangerous failure: the key says archived, the engine
>   does not have it).
> - *5W.* **Why** — One authority: the engine's frontier IS what is archived, so reading it is the
>   non-drifting `W`. **What** — `W` = the engine's folded frontier (a branded id), read at merge time. **Who**
>   — the merge-read (echo_store-side or the deep-read surface). **When** — emq3.5. **Where** — forward-tense,
>   over the engine's frontier (`head_lsn/1` delegated, `graft.ex:40-44`, mapping to the highest folded branded
>   id). **Steelman.** This is the converged answer (BOTH streams-tier lenses derived `W` from Graft's frontier,
>   `streams.synthesis.md` F3.5-B), and the bus lens AGREES even reading from the bus: a drift-prone side key is
>   worse than a derived scalar precisely because the merge's correctness (no gap, no overlap) rests on `W`
>   being the EXACT fold boundary, and only the engine's own frontier is exactly that. The order theorem makes
>   `W` a clean monotone cut; fold-before-trim makes it the trim boundary too (`the-stream-tier-ladder.md` §2);
>   so one derived value is the entire merge contract, with no bookkeeping key to keep coherent or clean up
>   (no §6 subkey, honoring the architect skill's subkey-cleanup law by adding none). **Steward.** The
>   keep-cost: deriving `W` requires the merge-read to READ the engine's frontier, a cross-app read (echo_store
>   sees the engine; a polyglot reader does not). For the BEAM merge-read this is free; for a POLYGLOT reader
>   doing a deep read, the engine's frontier is not visible over a stock Redis client — which is the one real
>   gap B2 addresses.

> **Arm B2 — a bus-side keyspace watermark `emq:{q}:stream:<name>:archived` (a polyglot-visible key).** The
> fold-consumer writes the watermark id into a bus keyspace key after each fold; the merge-read (and a polyglot
> reader) reads `W` from that key.
> - *Rationale.* A polyglot reader holds only a stock Redis client and cannot read the engine's frontier; a
>   bus-side key makes `W` visible to any reader on the wire, which the tier's polyglot promise needs.
> - *5W.* **Why** — the polyglot seam is a tier law (claims-only payloads, a stock client, `emq.streams.md`
>   §"The needs"); a deep read by a polyglot reader needs `W` on the wire. **What** — a keyspace key
>   `emq:{q}:stream:<name>:archived` the fold-consumer writes. **Who** — the fold-consumer writes it; a polyglot
>   reader reads it. **When** — emq3.5. **Where** — a §6 subkey under the braced `emq:{q}:` keyspace
>   (forward-tense). **Steelman.** It makes `W` a first-class wire-visible coordinate, so a polyglot deep read
>   (segments below `W`, tail above) is possible with a stock client — the polyglot seam extended to deep
>   reads. **Steward.** The keep-cost is the one the bus lens (and the streams-tier synthesis) weighed against:
>   a separately-WRITTEN key is a SECOND source of truth that can drift from the engine's actual frontier (the
>   fold commits to the engine, THEN writes the key — a crash between them leaves the key stale, asserting
>   archived what the engine has, or behind what the engine holds). It also adds a §6 subkey whose CLEANUP
>   disposition must be named (the architect skill's subkey-cleanup law: a new subkey absent from
>   `obliterate`'s list leaks at rest). The drift risk is the dangerous one; the cleanup is the bookkeeping one.

**Ranked recommendation (Lens A — bus-led): B1 (`W` derived from the engine's folded frontier, no new bus key)
for the BEAM merge-read — with B2's bus-side key as a NAMED, cleanup-specified ADDITION only where a polyglot
deep read is a real requirement.** The bus lens converges with the streams-tier synthesis and the persistence
lens here: a derived scalar from the engine's frontier is the One authority for `W` and cannot drift, which is
exactly what the merge's no-gap/no-overlap correctness needs (`the-stream-tier-ladder.md` §2). A separately-
written bus key (B2) is a second source of truth that can go stale against the engine — the dangerous failure.
The bus lens's ONE refinement from its own priority (the polyglot seam): IF a polyglot reader must do a deep
read across `W` (not just read the live tail, which it already can), THEN a bus-side `:archived` key is the
mechanism — but it is an ADDITION layered for polyglot visibility, written AFTER the engine commit and with its
cleanup named (folded into `obliterate`), not the PRIMARY `W` (which stays engine-derived to avoid drift). The
default is B1; B2 is the named polyglot extension. **Expected DIVERGENCE is mild:** both lenses likely land
B1-derived as the primary; the bus lens may press harder on the B2 polyglot-key addition (it weights the
polyglot seam), where the persistence lens may treat polyglot deep reads as out of scope.

> **Pre-empted persistence-lens objection:** *"Deriving `W` from the engine's frontier is correct and
> drift-free; adding a bus-side `:archived` key reintroduces exactly the second-source-of-truth drift the
> derived watermark was chosen to avoid — the polyglot deep read is a niche need that does not justify a
> drift-prone key."* Answer: agreed that B1-derived is the PRIMARY and drift-free `W`, and the bus lens makes
> it the default precisely for that reason — the B2 key is NOT a replacement for the derived `W`, it is an
> optional polyglot-visibility ADDITION, written after the engine commit and named in `obliterate`. The drift
> concern is real and is bounded by construction: the key is advisory for polyglot READERS (it tells a stock
> client roughly where the seam is); the BEAM merge-read still derives the authoritative `W` from the engine,
> so a stale key never corrupts a BEAM deep read — at worst a polyglot reader's seam is slightly behind, which
> the order theorem makes safe to de-dup by id. Whether the polyglot deep read is "niche" is the Operator's
> call on the tier's polyglot promise; the bus lens surfaces the mechanism without forcing it, and keeps the
> authoritative `W` engine-derived either way.

---

### F-PLAT-C — vocabulary coherence: "platform" vs "EchoMesh" (unify, or keep distinct?)

> **Arm C1 — keep them DISTINCT: "Echo Bus + Echo Persistence" is the SHIPPED platform vocabulary; "EchoMesh"
> is the PROPOSED weave taught forward-tense.** The development path adopts the established "platform" vocabulary
> (two halves that compose); EchoMesh stays the forward-tense whole-picture frame, not the as-built name.
> - *Rationale.* The manuscript is `status: established` and uses "Echo Bus + Echo Persistence" throughout
>   (`overview/persistence-in-the-platform.md`); mesh.8.1's "EchoMesh weave" is explicitly PROPOSED, taught
>   forward-tense, "not a shipped product" (CLAUDE.md whole-picture frame). Collapsing a shipped vocabulary into
>   a proposed one would assert EchoMesh as as-built, which it is not.
> - *5W.* **Why** — the established platform is shipped substrate (the bus + the engines + the store); EchoMesh
>   is a PROPOSED composition over it (CLAUDE.md: "a PROPOSED composition over shipped substrate… taught
>   forward-tense"). The two voices must stay distinct or the proposed leaks into the as-built. **What** — the
>   development path uses "the platform / Echo Bus + Echo Persistence" for shipped reality; "EchoMesh" stays the
>   forward concept. **Who** — the spec/manuscript authors; the development-path readers. **When** — now and
>   forward. **Where** — the manuscript (established voice) vs. mesh.8.1 / the /mesh course (proposed voice).
>   **Steelman.** The whole BCS/echo program enforces this split deliberately: the /art and /mesh courses teach
>   EchoMesh in "proposed/living-status voice… never asserted as shipped" (the art-course-writer +
>   mesh-course-writer disciplines), while the echo-persistence manuscript and the emq specs teach the bus +
>   engines as SHIPPED. Keeping the vocabularies distinct preserves exactly that grounding discipline — the
>   reader always knows whether a name is a thing that runs or a thing proposed. Unifying them would require
>   either demoting the shipped platform to "proposed" (false) or promoting EchoMesh to "shipped" (false). The
>   development path is about shipped rungs, so it speaks the shipped vocabulary. **Steward.** The keep-cost:
>   two names for overlapping territory (the "platform" and the "EchoMesh weave" both describe the bus + floor
>   composition), which a reader must learn map to the same substrate at different status levels. But that IS
>   the honest state (one shipped, one proposed), and conflating them would lose the status distinction the
>   whole program guards.

> **Arm C2 — UNIFY under "EchoMesh": adopt EchoMesh as the single platform vocabulary, treating the
> bus+persistence composition as the EchoMesh weave realized.** The development path names the whole "EchoMesh,"
> folding "Echo Bus + Echo Persistence" into it as the weave's now-shipped substrate.
> - *Rationale.* One name for the whole is simpler than two; mesh.8.1 already frames the bus + cache + log +
>   worker as one weave, so adopting EchoMesh as the platform name unifies the vocabulary.
> - *5W.* **Why** — a single platform name reduces the reader's vocabulary load. **What** — "EchoMesh" as the
>   platform name; the bus+persistence halves as its realized weave. **Who** — the platform's authors/readers.
>   **When** — forward. **Where** — the manuscript + mesh.8.1, unified. **Steelman.** mesh.8.1 already gives a
>   coherent whole-picture name for the composition (the weave of consistency-first ledger, availability-first
>   cache+log, elastic worker); adopting it would give the platform one organizing vocabulary instead of "two
>   halves." **Steward.** The keep-cost is the grounding violation the program forbids: EchoMesh is PROPOSED,
>   "taught forward-tense, not a shipped product" (CLAUDE.md) — naming the SHIPPED platform "EchoMesh" asserts a
>   proposed composition as as-built, exactly the no-invent / proposed-not-shipped discipline the /art and
>   /mesh courses enforce. It would also import EchoMesh's CAP-segmentation framing (a per-operation CAP trade)
>   as the platform's shipped vocabulary, when the platform ships specific surfaces (the bus, the engines), not
>   a CAP-weave abstraction. The simplification is bought by blurring shipped vs. proposed.

**Ranked recommendation (Lens A — bus-led): C1 (keep DISTINCT — "Echo Bus + Echo Persistence" is the shipped
platform vocabulary; "EchoMesh" stays the PROPOSED forward-tense weave).** The development path is about
shipped rungs, so it must speak the shipped vocabulary — and the whole echo program guards the line between
shipped substrate and the PROPOSED EchoMesh composition (CLAUDE.md: "a PROPOSED composition over shipped
substrate… taught forward-tense"; the /art + /mesh courses teach EchoMesh in proposed/living-status voice
only). Unifying under "EchoMesh" (C2) would assert a proposed weave as as-built — the exact no-invent violation
the program forbids — and import a CAP-segmentation abstraction as the platform's name when the platform ships
concrete surfaces. The bus lens keeps the vocabularies distinct: the platform (Echo Bus + Echo Persistence) is
what runs; EchoMesh is the forward whole-picture frame the bus + floor will COMPOSE INTO, taught forward-tense.
**Expected DIVERGENCE is low:** both lenses should land C1 (the grounding discipline binds both); any
difference is emphasis (the bus lens names the bus as the spine of the shipped platform; the persistence lens
may name the floor as its substrate — but both keep EchoMesh proposed).

> **Pre-empted persistence-lens objection:** *"mesh.8.1 already provides a unified whole-picture vocabulary
> (the weave), and the platform IS that weave realized — clinging to 'two halves that compose' fragments a
> picture EchoMesh already makes whole; adopt EchoMesh as the platform vocabulary."* Answer: EchoMesh is
> explicitly PROPOSED — "the weave, taught forward-tense, not a shipped product… a PROPOSED composition over
> shipped substrate" (CLAUDE.md) — so naming the SHIPPED platform "EchoMesh" asserts as-built what is proposed,
> the precise grounding violation the whole program (the /art and /mesh course disciplines, the no-invent rule)
> forbids. "Two halves that compose" is not fragmentation; it is the HONEST shipped state (a bus and a floor
> that genuinely compose via the commit-LSN loop), and it composes FORWARD into the EchoMesh weave taught in
> proposed voice. The development path speaks what runs; EchoMesh is where it is heading, named forward-tense.
> Keep the spine/floor vocabulary for the shipped platform and let EchoMesh remain the proposed whole — the
> distinction is the grounding, not a fragmentation.

---

### F-PLAT-D — the development-path sequencing (after emq3.5 + emq3.6, what's next from the bus lens?)

> **Arm D1 — finish the Stream Tier (emq3.5 → emq3.6), THEN the BCS substrate via the door, with eg.6 as a
> parallel deferred engine track.** The reframed roadmap from the bus lens: (1) emq3.5 the archive (the
> keystone, next); (2) emq3.6 time-travel + hydration (closes the tier); (3) the door to BCS — Tables /
> Properties / Coherence as the substrate for BCS systems (the consumer pivot: codemojex live, echo_bot
> planned); with eg.6 (cross-compile + the per-workload shootout) a DEFERRED parallel engine track behind the
> fly.io deploy floor, ruling D-4 convergence when its evidence lands.
> - *Rationale.* The bus ladder has a natural completion (the tier whole at emq3.6), and its completion OPENS
>   the door to BCS (the door-to-BCS framing: the floor + the bus together become the substrate for systems);
>   the engine track (eg.6) is deferred and proceeds in parallel without blocking the bus.
> - *5W.* **Why** — the live frontier is the bus ladder; finishing it completes the tier and reaches the BCS
>   door; the engine track is deferred and parallel. **What** — emq3.5 → emq3.6 → the BCS substrate door, eg.6
>   deferred-parallel. **Who** — the bus consumers (codemojex, echo_bot); the BCS systems past the door.
>   **When** — emq3.5 now; emq3.6 next; the door after; eg.6 deferred. **Where** — `emq.streams.md` (the bus
>   ladder), `the-door-to-bcs/index.md` (the substrate door), `graft.engine-split.design.md` §7 (eg.6/D-4
>   deferred). **Steelman.** This sequencing follows the platform's OWN arc: the manuscript closes the bus arc
>   (Module 11) → the bus+persistence join (Module 12) → beats-over-scheduling (Module 13) → the door to BCS
>   (Module 14), which is exactly emq3.5/3.6 finishing the tier and then BCS as the substrate destination. It
>   keeps the deferred engine work (eg.6, D-4 convergence) OFF the critical path — the bus does not wait on the
>   fly.io deploy floor — while still naming it as the parallel track that rules convergence when evidence
>   lands. The consumer pivot (codemojex live, echo_bot planned Telegram) gives the path a concrete demand
>   target. **Steward.** The keep-cost: it sequences the BCS substrate door AFTER the tier (emq3.6), so a
>   consumer wanting BCS-on-the-substrate before time-travel must wait — but the door-to-BCS substrate (Tables,
>   Coherence) is largely ALREADY shipped (`the-door-to-bcs/index.md` §1: the floor "already stores state by
>   branded id"), so the door is mostly a framing/consumer step, not a heavy build, and sequencing it after the
>   tier is cheap. It also leaves eg.6/D-4 as a deferred fork (the convergence undecided), which is honest but
>   means the two-engine maintenance persists until the shootout.

> **Arm D2 — pivot to the deferred engine track (eg.6 + D-4 convergence) BEFORE completing the bus tier.**
> Sequence eg.6 (cross-compile, CI, the per-workload shootout) and the D-4 convergence decision NEXT, settling
> the engine story before finishing emq3.6, so the durable floor is consolidated first.
> - *Rationale.* Consolidating the engine (resolving two-engine coexistence via the shootout) before extending
>   the bus gives the bus a settled floor to fold into.
> - *5W.* **Why** — a settled single engine simplifies everything the bus folds into. **What** — eg.6 + D-4
>   next; emq3.6 after. **Who** — the engine track. **When** — before emq3.6. **Where** —
>   `graft.engine-split.design.md` §7 (eg.6/D-4). **Steelman.** A consolidated engine removes the two-engine
>   maintenance and gives the merge-read/fold a single settled target. **Steward.** The keep-cost is decisive
>   against it from the bus lens: eg.6 is DEFERRED BEHIND A FLY.IO DEPLOY FLOOR (the recon brief), so
>   sequencing it next BLOCKS the live bus frontier on a deploy dependency that is not ready — stalling emq3.5/3.6
>   (the keystone + tier completion) behind engine work that the ruling itself deferred. It also pre-empts D-4
>   (the convergence decision the ruling parked post-eg.6 explicitly to wait for shootout evidence,
>   `graft.engine-split.design.md` §7) by forcing it earlier than its evidence. The bus does NOT need the engine
>   consolidated to fold (emq3.5 folds into the native engine alone, F-ENG-C/C1) — so consolidating first
>   trades the live, ready bus frontier for deferred, blocked engine work. Wrong order from the bus lens.

**Ranked recommendation (Lens A — bus-led): D1 (finish the Stream Tier emq3.5 → emq3.6, then the BCS substrate
door, with eg.6 a deferred parallel engine track), because the live frontier is the bus ladder and the engine
track is deferred behind a deploy floor.** The reframed development path from the bus lens: the keystone
(emq3.5, the archive) is NEXT; emq3.6 (time-travel + hydration) closes the tier; the door to BCS (Tables /
Properties / Coherence as the substrate, the codemojex-live / echo_bot-planned consumer pivot) is the
destination the completed tier opens — and this exactly traces the manuscript's own Chapter IV arc (Modules
11 → 12 → 13 → 14). eg.6 + the D-4 convergence are a DEFERRED parallel engine track behind the fly.io deploy
floor, ruling convergence when the shootout's evidence lands — kept OFF the bus's critical path. D2 (engine
consolidation first) is rejected: it blocks the live bus frontier on a deferred deploy dependency and pre-empts
the convergence decision the ruling parked for evidence. The bus does not wait on the engine to fold; the
development path is the bus ladder, and emq3.5 is its next rung. **Expected DIVERGENCE:** the persistence-led
lens may sequence the engine consolidation (eg.6/D-4) higher (reading the path forward from the floor, it may
want the substrate settled first), where the bus lens keeps the bus ladder on the critical path and the engine
track deferred-parallel.

> **Pre-empted persistence-lens objection:** *"Two coexisting page-engines is an unresolved liability; the
> development path should consolidate the engine (eg.6 + the shootout + D-4) before piling more bus rungs onto
> an unsettled floor — build the foundation solid, then extend."* Answer: the floor is NOT unsettled for the
> bus's purposes — emq3.5 folds into the native engine ALONE (the ruled canonical engine, F-ENG-C/C1), so the
> bus has a settled, in-process target TODAY; the two-engine question (D-4) is about the RUST peer's
> raw-page/replica workload, which the archive does not touch. And eg.6 is DEFERRED behind a fly.io deploy
> floor (the recon brief; `graft.engine-split.design.md` §7) — sequencing it next would block the live bus
> frontier (emq3.5/3.6) on a deploy dependency the ruling itself deferred, AND pre-empt the D-4 convergence the
> ruling parked specifically to wait for shootout evidence. "Build the foundation, then extend" is sound when
> the foundation is on the critical path — but here the foundation (the native engine) is shipped-and-consumed
> and the bus is what is being built, so the order is: extend the bus (it is ready and live), let the deferred
> engine track resolve convergence in parallel when its evidence and its deploy floor arrive. The bus lens
> keeps the moving frontier moving and the deferred track deferred.

---

## §Fork ledger (Lens A — bus-led — ranked arms, for the Director's cross-lens diff)

| Fork | Lens-A ranked arm | One-line reason (bus-led) |
|---|---|---|
| **F-PLAT-A** the spine (THE reframe) | **A1** BUS-LED (bus = spine, persistence = floor) | The loop is conceded + reframed: both loop edges cross the bus's wire (the commit LSN is *published over EchoMQ*; the fold *reads off the bus*); the live frontier is a bus rung — the bus is the load-carrying member |
| **F-PLAT-B** merge-read watermark `W` | **B1** engine-derived scalar (no new bus key) + B2 as a named polyglot-only addition | One authority (the engine's frontier) → no drift; a bus-side key is a second source of truth; B2 layered only for polyglot deep reads, cleanup named |
| **F-PLAT-C** vocabulary coherence | **C1** keep DISTINCT (platform shipped; EchoMesh PROPOSED) | The development path speaks the SHIPPED vocabulary; unifying under EchoMesh asserts a proposed weave as as-built (the no-invent violation the program forbids) |
| **F-PLAT-D** development-path sequencing | **D1** finish the tier (emq3.5→3.6) → BCS door; eg.6 deferred-parallel | The live frontier is the bus ladder + traces the manuscript's Ch.IV arc; eg.6 is DEFERRED behind a deploy floor — keep it off the critical path |

**Where this lens most expects to DIVERGE from the persistence lens** (highest-value signals for the
Operator):

1. **F-PLAT-A (THE reframe) — A1 bus-led vs the steward's A2 persistence-led.** THE chapter's sharpest
   divergence and the debate's highest-value signal: the bus lens reads the development path forward from the
   bus (spine) reframing the loop as a transport asymmetry; the persistence lens reads it forward from the
   floor (substrate), anchored on the door-to-BCS "the queue was the first thing built on the floor" framing.
   A genuine SPINE-vs-SUBSTRATE divergence on the development path's organizing principle.
2. **F-PLAT-D (sequencing) — D1 finish-the-bus-tier vs the steward's likely D2 consolidate-the-engine-first.**
   The bus lens keeps the live bus ladder on the critical path with eg.6 deferred-parallel; the persistence
   lens, reading from the floor, may want the engine consolidated (eg.6/D-4) before extending the bus. A
   FRONTIER-vs-FOUNDATION sequencing divergence.
3. **F-PLAT-B (watermark) — likely CONVERGENCE on B1-derived, with the bus lens pressing the B2 polyglot
   addition.** Both lenses likely derive `W` from the engine's frontier (drift-free); the divergence is mild —
   the bus lens weights the polyglot deep-read enough to surface the B2 bus-side key as a named addition, where
   the persistence lens may treat it as out of scope.

---

## §Manuscript reconciliation (proposed from this lens — PROPOSE only; the Director applies)

- **`docs/echo-persistence/platform/the-door-to-bcs/index.md`** §1 — *what is stale (a framing tension, not a
  factual error):* the dive frames the bus as "the FIRST thing the platform built on" the floor, which reads
  the development path purely persistence-led — eliding that the bus is the live frontier and that the
  commit-LSN loop is bidirectional (the bus drives the engine's commit too, per Module 12 §1). *Proposed
  framing:* a balancing clause acknowledging the bus is not merely "the first thing built on the floor" but a
  co-equal loop member and the platform's live development frontier (emq3.5 NEXT) — so the substrate framing
  does not overstate the floor's primacy in the development path. *(This is the F-PLAT-A divergence surfaced in
  the manuscript; the Director should stage it, not silently resolve it — both readings are defensible.)*
- **`docs/echo-persistence/platform/echomq-bus/the-stream-tier-ladder.md`** §1 — *what is stale:* the ladder
  labels emq3.3 "Build-ready" and presents the rungs as PROPOSED, but emq3.1–3.4 are SHIPPED (conformance 77;
  `emq.streams.md` "emq3.1–3.4 SHIPPED, emq3.5 is next") — the same "ladder table still labels shipped rungs
  PROPOSED" drift the recon flagged in `emq.streams.md` itself. *Proposed framing:* mark emq3.1–3.4 SHIPPED and
  emq3.5 NEXT, so the dive matches the as-built ladder state rather than its design-ahead snapshot.
- **`docs/echo_mq/emq.streams.md`** ladder table (§"The ladder") — *what is stale:* the table header says
  "Ships (PROPOSED)" though emq3.1–3.4 have shipped (the file's own status line says so). *Proposed framing:*
  reconcile the per-row status to SHIPPED for emq3.1–3.4 (the table currently reads as all-proposed while the
  status line says four are shipped) — the recon-flagged docs-vs-specs drift. *(Canon edit — the Director
  applies; this lens only PROPOSES, per edit-only-the-triad / no-canon-edit.)*

---

## §What I deliberately did NOT decide (the discipline)

- **Every fork above is SURFACED, not ruled.** F-PLAT-A (the reframe) especially: the bus lens ARGUES bus-led,
  but the spine-vs-substrate call is the Operator's — both readings are defensible and the divergence IS the
  value.
- **The `echomq:3.0.0` cutover ratification** — DEFERRED (declared when the tier is whole, the
  defer-the-fence-cutover pattern, `emq.streams.md` §"Version plane"); never auto-claimed by a rung. Parked.
- **The D-4 engine convergence + the D-5 shootout outcome** — DEFERRED post-eg.6 by the ruling
  (`graft.engine-split.design.md` §7); the bus lens recommends a deferred-parallel engine track and does NOT
  rule convergence.
- **Whether Module 14 (the BCS substrate door) is a build or a framing rung** — F-PLAT-D notes the substrate is
  largely already shipped (`the-door-to-bcs/index.md` §1), so the door is mostly a framing/consumer step; the
  exact build scope is the door rung's own design, not this chapter's.
- **The consumer pivot's concrete demands** (codemojex live, echo_bot planned Telegram) — named as the path's
  demand target, but the specific consumer features are the consumers' own specs, not this chapter's.

---

## §Surface citations (NO-INVENT — every named surface grounded)

**Verified as-built (real `module/file:line`):**

- `EchoStore.Graft.head_lsn/1` — the engine's folded-frontier read backing the engine-derived `W` (F-PLAT-B/B1),
  delegated (`echo/apps/echo_store/lib/echo_store/graft.ex:40-44`).
- `EchoStore.Graft.VolumeServer.commit/3` — the fold target the bus folds into (`volume_server.ex:50`).
- `EchoMQ.StreamConsumer` — AS-BUILT (emq3.3) — `echo/apps/echo_mq/lib/echo_mq/stream_consumer.ex` (present);
  the fold `StreamConsumer` (F-PLAT-D) is a configured instance.
- `EchoStore.Table` (L1 ETS, the BCS-substrate surface, `put/4` 14-byte version at `table.ex:97`) +
  `EchoStore.Coherence` (newer-wins, "a message about a name") — the door-to-BCS substrate
  (`the-door-to-bcs/index.md` §1; `graft.engine-split.design.md` §3 / the BCS code at `echo/apps/echo_data/lib/echo_data/bcs/`).
- The order theorem — stream order == id sort == mint order (`echo/apps/echo_mq/lib/echo_mq/stream/id.ex:28-49`),
  underwriting the merge-read seam at `W`.

**Forward-tense (surface a rung BUILDS — not yet on disk):**

- The emq3.5 merge-read / deep-read surface computing `W` from the engine's folded frontier (F-PLAT-B/B1).
- The optional bus-side `emq:{q}:stream:<name>:archived` watermark key for polyglot deep reads (F-PLAT-B/B2),
  cleanup named in `obliterate`.
- The emq3.6 time-travel (`read_since`/`read_between` over `Snowflake.min_for/1`) + Table hydration surfaces
  (the tier-completion rung, F-PLAT-D).

**Canon / design cited (NOT a code surface):** `docs/echo_mq/emq.streams.md` (the ladder, emq3.5 NEXT, the
durable-archive answer, the version plane); `docs/echo_mq/kb/streams-tier/streams.synthesis.md` (F3.5-B `W`
engine-derived, F3.4-A — RULED context); `docs/graft/graft.engine-split.design.md` (COEXIST D-1=A, eg.6/D-4
deferred §7); the echo-persistence manuscript Chapter IV (`platform/bus-and-persistence/index.md` the
commit-LSN loop §1, `platform/echomq-bus/the-stream-tier-ladder.md` the bus arc + `W` §2,
`platform/the-door-to-bcs/index.md` the substrate framing §1); `docs/echo/mesh/mesh.8.1.md` + CLAUDE.md (the
PROPOSED EchoMesh weave over shipped substrate, the proposed-not-shipped grounding discipline).
