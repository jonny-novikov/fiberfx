# Chapter — The Engines (native Graft · Rust · Tigris+fence · BEAM↔Rust) · Lens B (persistence-led)

> **Lens B — the persistence-led / vision-forward lens ("the floor rises to carry the log").** This chapter
> is read from the durable engine outward. Priorities, in order: (1) the durable engine is the platform's
> **universal substrate**; (2) the **commit-log-as-outbox (ADR-A) is the keystone** — the v4 north star; (3)
> the engine's forward path is Champ accept → Graft commit → Tigris replication → the outbox subsuming the
> SQLite journal; (4) the bus is **one client** of the durable floor. What this lens CHAMPIONS in the engines
> chapter: the native `EchoStore.Graft` engine as the canonical floor the whole platform dogfoods (the bus's
> archive, the outbox, the cache invalidation, the Tables all ride it); the `echo_store → echo_mq` dependency
> direction as a **FEATURE** (the store owns durability; the bus rides above); and the Rust `echo_graft_backend`
> as a specialized peer that earns its place on raw-page/replica workloads, not as a replacement for the floor.
>
> The discipline holds regardless of lens: **forks are SURFACED, never decided** — each closes with a ranked
> recommendation and the one carrying reason, and pre-empts the bus lens's strongest objection. **NO-INVENT**
> — every as-built surface is cited to `file:line`, every unbuilt surface is forward-tense. **Authored
> independently** — the sibling bus-led lens (`A-lens.md`) was not read. Convergence is confidence; divergence
> is the signal.

---

## §0 · Context

**What this chapter is.** The engines chapter is Chapter III of the Echo Persistence manuscript — the page
engines that turn CubDB roots into replicated pages: the native Elixir `EchoStore.Graft.*` engine, the Rust
`echo_graft` engine, the Tigris remote behind a create-if-not-exists fence, and the byte-frozen BEAM↔Rust
contract (`echo_graft_proto`). From the persistence lens this chapter is the **substrate's own description** —
the floor the bus's Stream Tier archive lands on is not abstract durability, it is THESE engines, with these
commit/fence/replicate/recover guarantees already shipped. The chapter's job, from this lens, is to settle
which engine the bus folds into, where the fold-consumer lives given the dependency direction, and how the
two-engine coexistence travels forward toward the ADR-A north star.

**What is as-built (verified at source this session).**

- **TWO independently-complete durability engines exist, ruled to COEXIST.** `graft.engine-split.design.md`
  §0: *"two independently-complete durability engines … functional twins, not layers"* — the native Elixir
  `EchoStore.Graft.*` (CubDB) and the Rust `apps/echo_graft` (Fjall + OpenDAL, eg.1–eg.5 shipped). The
  Operator ruled **D-1 = A (COEXIST)**, native canonical + **UNTOUCHED**; the Rust engine a coexisting peer
  named `echo_graft_backend` (binary), `echo_graft_proto` (wire), `EchoStore.GraftBackend` (Elixir client) —
  D-2 (`graft.engine-split.design.md` §7).
- **The native engine is the canonical floor.** `EchoStore.Graft` — *"Native-BEAM Graft … with no foreign
  engine"* (`graft.ex:2-4`): `open_volume/2` (`graft.ex:31`), `commit/3` (`:41`, the single-writer OCC
  mailbox `volume_server.ex:1-8, 129-159`), `Store` on CubDB (`store.ex` per §3b), `Streamer` → Tigris (*"the
  native, real-time replacement for the Litestream sidecar"*, §3b), `Reader` lazy-fault (`reader.ex` per §3b),
  `Sync` notices on `graft:{vol}:commits` (`sync.ex:41`), `Committer` the commit-log-as-outbox drain
  (`committer.ex:1-18`), `Epoch` fencing (`epoch.ex`), `Divergence` no-merge guard (`divergence.ex`).
- **The Rust engine is a specialized peer, reached over the bus.** `EchoStore.GraftBackend` drives
  `echo_graft_backend` over RESP3 through `echo_graft_proto`: a `Hello`/`Welcome` handshake, a per-Volume
  command lane `egraft:cmd:{vol}`, a per-client reply lane `egraft:reply:{client}`, and a publish-only feed
  lane `egraft:feed:{vol}` — *"the contract is the only coupling — an engine crash is a restart, not a downed
  orchestrator"* (`engines/beam-rust-contract/index.md` §1–§2; `graft.engine-split.design.md` §6). The Rust
  feed lane is DISTINCT from the native `graft:{vol}:commits` (§6).
- **The dependency direction is fixed.** `echo_store` depends on `echo_mq` (`echo/CLAUDE.md` §1 dependency
  table) → `echo_mq` CANNOT call `echo_store`. The store owns durability; the bus is the lower layer.
- **eg.6 is DEFERRED (2026-06-22), NOT next.** `graft.roadmap.md`: eg.1–eg.5 SHIPPED; eg.6 (ship AND run the
  fully integrated BEAM↔Rust stack + per-workload shootout) is DEFERRED behind the **fly.io EchoMQ deploy
  floor** (no Dockerfile/`fly.toml` yet), spec `graft.6.md` `status: Draft`. The live frontier is the BUS rung
  **emq3.5**.

> **The one question this chapter must answer well, from this lens:** Given two complete page engines ruled to
> coexist, the native engine the canonical floor, and eg.6 deferred behind a deploy floor — when the bus's
> archive (emq3.5) needs durable storage, does it fold into the **floor that is already complete and already
> dogfooded** (the native `EchoStore.Graft`, via its public `commit/3`), and does the fold-consumer's
> placement respect the `echo_store → echo_mq` direction as the FEATURE it is (the store owns durability, so
> the fold lives store-side or host-side, never inside the bus)?

---

### F-ENG-A — which engine does the bus fold into? native `EchoStore.Graft` vs Rust `echo_graft_backend`

**The fork.** The emq3.5 archive must commit trimmed segments into a durable page engine. Two exist. Which one?

> **Arm A1 — the native `EchoStore.Graft` engine (the canonical floor).** The fold commits each trimmed slice
> into the native engine via its public `EchoStore.Graft.commit/3` (`graft.ex:41`) — the in-process,
> single-crash-domain, already-dogfooded floor.
>
> - *Rationale.* The native engine is the canonical durability tier by ruling (D-1=A, native canonical +
>   untouched, `graft.engine-split.design.md` §7) and by the manuscript (*"the native Elixir `EchoStore.Graft.*`
>   on CubDB is the canonical default"*, `overview/persistence-in-the-platform.md` §1). The bus already
>   dogfoods it: `emq.streams.md` states the archive *"folds trimmed stream segments into the `EchoStore.Graft`
>   engine's local CubDB"* — named, not invented. The fold is a consumer of the floor through the floor's own
>   front door.
> - *5W.* **Why** — store on the canonical, in-process, untouched floor the platform already runs. **What** —
>   the fold consumer calls `EchoStore.Graft.commit/3` with the segment's pages; the engine streams them to
>   Tigris via its own `Streamer` and announces on `graft:{vol}:commits` via its own `Sync` — no new engine
>   logic. **Who** — the fold consumer (placement is F-ENG-B). **When** — emq3.5, forward-tense. **Where** —
>   `EchoStore.Graft.commit/3` (`graft.ex:41`); `Streamer` → Tigris (§3b); `Sync` (`sync.ex:41`). The engine
>   is UNTOUCHED — the fold issues no edit to any `EchoStore.Graft.*` module (the COEXIST law).
> - *Steelman.* This is the persistence lens realized literally: the archive is nearly free precisely BECAUSE
>   the floor is already complete. The native engine ships everything the archive needs — single-writer OCC
>   commit, the create-if-not-exists fence to Tigris, real-time segment rollup, lazy box-loss recovery, the
>   change feed — and it is in-process, so the fold pays no cross-runtime hop for the common case
>   (`graft.engine-split.design.md` §2: *"the only durability the consumer's hot path touches is the
>   low-volume outbox, already served natively with no foreign engine"*). The order theorem extends cleanly:
>   a trimmed slice is a run of branded `EVT` records in mint order, committed as one (or a few) Graft
>   commit(s), so archived order == stream order == mint order by construction — the same proof the writer
>   earned, carried to the archive. And the manuscript ALREADY names this engine as the archive target, so A1
>   is reconciliation, not a new design.
> - *Steward.* The honest multi-year cost is that the fold couples the bus's archive to the native engine's
>   public surface — `commit/3` becomes a contract the fold depends on. That is a thin, stable, already-public
>   surface (a single-writer mailbox call, `volume_server.ex:48-51`), and the COEXIST law keeps the engine
>   untouched, so the coupling is one-directional and reviewable. The one named obligation: the fold must
>   honor fold-before-trim (commit the slice durably, THEN trim past it — F-ENG-B's ordering), which is a fold
>   property, not an engine change.

> **Arm A2 — the Rust `echo_graft_backend` engine.** The fold drives the Rust engine over the bus
> (`EchoStore.GraftBackend.commit/5`), folding segments into Fjall + OpenDAL.
>
> - *Rationale.* The Rust engine is the page-fault-performance + deployable-backend peer
>   (`graft.engine-split.design.md` §5 Option A rationale); a deep archive workload that wants Rust's raw-page
>   throughput, or a deployment where the archive lives beside Go workers, is exactly the Rust engine's
>   assigned lane.
> - *5W.* **Why** — raw-page performance / a deployable backend for a deep archive. **What** — the fold sends
>   `Commit` messages over `egraft:cmd:{vol}`; the Rust side takes the fence; an `Ack(lsn)` returns; a
>   `FeedEvent` publishes on `egraft:feed:{vol}` (`beam-rust-contract/index.md` §1). **Who** — the fold
>   consumer as a `GraftBackend` client. **When** — emq3.5 at the earliest. **Where** —
>   `EchoStore.GraftBackend.commit/5` (named in the engine-split memory; §6); the Rust runtime
>   (`graft.engine-split.design.md` §3a).
> - *Steward.* The cost the steward weighs heaviest: A2 pulls a cross-runtime wire and a second crash domain
>   onto the archive path, and — load-bearing — **eg.6 is DEFERRED behind the fly.io deploy floor that does
>   not exist yet** (`graft.roadmap.md`). eg.5 proved the binding against a LOCAL Valkey `:6390`, not a
>   deployed bus; the integrated-deploy-and-measure rung is exactly what is not yet dischargeable. Folding the
>   archive into the Rust engine in emq3.5 would make the Stream Tier's durability depend on a deployment floor
>   the durability roadmap itself defers. The Rust engine is real and complete in isolation, but it is the
>   wrong floor to MANDATE for the archive before its deploy story lands.

**Ranked recommendation (Lens B — persistence-led): A1 (the native `EchoStore.Graft` engine), decisively —
with A2 available as an Operator-declared per-stream escalation once eg.6's deploy floor lands.** A1 carries
on three grounds the persistence lens reads as primary: (1) it IS the canonical floor by ruling and by
manuscript, and the archive is the floor's consequence — *"the fold being a property of the engine already in
place is what makes the archive nearly free"* (`emq.streams.md`); (2) it is in-process and untouched, so the
fold inherits the engine's commit/fence/replicate/recover with no cross-runtime hop and no engine edit (the
COEXIST law honored literally); (3) it does not couple the Stream Tier to eg.6's deferred deploy floor. A2 is
the right answer for a SPECIFIC stream the Operator marks as raw-page-heavy or backend-deployed — an additive
escalation once the Rust deploy story is real, not the default.

> **Pre-empted bus-lens objection:** *"The bus shouldn't care which engine backs the archive — it commits a
> slice and moves on; the engine choice is a store concern. And the Rust engine is the platform's bet on a
> deployable backend, so routing the archive to it dogfoods the harder path."* Answer: the persistence lens
> AGREES the engine choice is a store concern — which is exactly why it defaults to the store's CANONICAL
> engine (the native one, ruled canonical + untouched), not the peer. The bus lens's "dogfood the harder
> path" undercounts the sequencing: eg.6 (the integrated Rust deploy) is DEFERRED behind a fly.io floor that
> is not built, so routing the live emq3.5 archive to the Rust engine would gate a SHIPPING bus rung on a
> DEFERRED durability rung — inverting the dependency the platform's roadmap deliberately sets. The native
> engine is not the easy path chosen for convenience; it is the COMPLETE, in-process, already-dogfooded floor
> the whole platform stands on, and the archive landing there is the floor doing what it already does. The
> Rust engine earns the archive when its deploy floor lands and an Operator names a stream that wants it —
> additively, per stream, not as the default the Stream Tier must wait on.

---

### F-ENG-B — the fold-consumer placement (the dependency-direction fork)

**The fork.** `echo_mq` cannot call `echo_store` (the dependency runs store → mq, `echo/CLAUDE.md` §1). So the
component that reads a trimmed stream slice AND commits it to the engine cannot live inside the bus. Where does
the fold-consumer live: an echo_store-side StreamConsumer, a host-app consumer, or an injected callback?

> **Arm B1 — an echo_store-side fold StreamConsumer (the store reaches UP to the bus).** The fold consumer is
> a process in `echo_store` (or a module the store provides), holding a connector lane, reading the stream via
> the bus's public stream-read surface, and committing slices via the engine's `commit/3` — both ends in the
> app that already depends on `echo_mq`.
>
> - *Rationale.* The dependency direction MAKES this the natural home: `echo_store` already depends on
>   `echo_mq` (it consumes the bus for cache invalidation, the Committer's `Jobs.enqueue`, the Sync feed), so a
>   store-side consumer can legally read the stream AND call the engine — both surfaces are in scope. The
>   store owns durability; the archive IS durability; therefore the archive's consumer is the store's.
> - *5W.* **Why** — the only placement where one component legally touches both the bus stream-read and the
>   engine commit. **What** — a store-side process reading the stream (via the bus's public stream surface)
>   and committing slices to `EchoStore.Graft.commit/3`. **Who** — `echo_store` owns it. **When** — emq3.5.
>   **Where** — `echo_store`-side, beside `EchoStore.Graft.Committer` (`committer.ex`, the precedent: a
>   store-side process that subscribes to a feed and re-publishes via `EchoMQ.Jobs.enqueue` — the store
>   reaching up to the bus is ALREADY the as-built shape); commits via `EchoStore.Graft.commit/3` (`graft.ex:41`).
> - *Steelman.* This is the persistence lens's central claim made structural: the dependency direction is a
>   FEATURE. The store owning durability and reaching UP to the bus is exactly the as-built `Committer`
>   pattern — *"subscribes to the volume's commit channel … re-publishes its names to the work bus
>   at-least-once"* (`committer.ex:1-18`). The fold consumer is the MIRROR of the Committer: the Committer
>   reads the engine's commits and writes to the bus; the fold reads the bus's stream and writes to the
>   engine. Same direction (store-side, touching both), same legality, same crash-domain. The platform's "one
>   system" thesis lives here: the loop closes BECAUSE the store can reach both halves — *"the engine's commit
>   drives the bus, and through the archive fold, the bus drives the engine's commit"*
>   (`bus-and-persistence/index.md` §1). Placing the fold store-side is what makes that loop legal.
> - *Steward.* The honest cost: a store-side consumer reads the bus's stream through the bus's PUBLIC stream
>   surface (whatever emq3.x freezes for grouped reads), so the store now depends on that surface staying
>   stable — a real coupling, but one-directional (store → mq, the existing direction) and over a public
>   contract, so reviewable. The store must also manage the fold consumer's lifecycle and its fold-before-trim
>   ordering. All bounded; all the existing `Committer`'s shape.

> **Arm B2 — a host-app consumer (the application that owns both the stream and the Volume wires the fold).**
> Neither `echo_mq` nor `echo_store` ships the fold; the HOST application (the one that runs the stream and
> opens the Volume — e.g. codemojex) wires a consumer that reads the stream and commits to the engine.
>
> - *Rationale.* The host already composes both libraries; the fold is application policy (which streams
>   archive, into which Volume, on what retention) the host is best placed to declare. Keeping the fold in the
>   host keeps both libraries free of a cross-concern.
> - *5W.* **Why** — the fold is app policy; the host owns both wires. **What** — a host-supplied consumer.
>   **Who** — the host app. **When** — emq3.5. **Where** — the host app's supervision tree; reads the bus
>   stream surface, commits via `EchoStore.Graft.commit/3`.
> - *Steward.* This is honest about the fold being policy, and it keeps the libraries clean. The cost: every
>   host re-implements the fold (and its fold-before-trim safety), so the at-least-once/no-loss archive
>   guarantee is re-proven per host rather than shipped once — a DRY liability across deployments, and the
>   exact "each consumer reinvents recovery" risk the platform's "recovery is not a special case" thesis
>   exists to avoid. The store-side B1 ships the guarantee once; B2 ships a pattern hosts must each instantiate.

> **Arm B3 — an injected callback into the bus's stream consumer.** The bus's stream consumer accepts an
> injected fold callback (a function the host or store supplies) that the consumer invokes on the
> about-to-be-trimmed slice — the bus calls OUT to durability without depending on `echo_store`.
>
> - *Rationale.* It keeps the consumer machinery in the bus (where the stream lives) while inverting the
>   dependency via a callback, so the bus never names `echo_store` — the durability target is whatever the
>   caller injects.
> - *5W.* **Why** — keep the consumer in the bus, invert the dependency via a function. **What** — a
>   `fold_fun` option on the bus's stream consumer. **Who** — the bus runs the consumer; the caller supplies
>   the callback. **When** — emq3.5. **Where** — a callback option on the bus stream consumer (forward-tense);
>   the callback closes over `EchoStore.Graft.commit/3`.
> - *Steward.* The callback legally inverts the dependency (the bus calls a function, never `echo_store`), and
>   it co-locates the fold with the stream read. But the steward's caution: the fold-before-trim ORDERING now
>   lives in the bus (the bus must call the fold AND confirm durable commit BEFORE it trims), which puts a
>   cross-system crash-safety invariant inside the bus — a property the bus cannot verify (it cannot see the
>   engine's durable extent). The injected callback hides WHERE the no-loss guarantee is enforced, which is
>   exactly the "one line a reviewer can point at" the persistence lens prizes. It also threads engine state
>   through an opaque closure the bus holds, blurring the boundary.

**Ranked recommendation (Lens B — persistence-led): B1 (an echo_store-side fold StreamConsumer), strongly —
the dependency direction is the FEATURE that makes B1 the natural and reviewable home.** B1 carries because it
is the mirror of the already-as-built `EchoStore.Graft.Committer`: the store reaching UP to the bus to touch
both the stream-read and the engine-commit is the EXISTING legal shape, and the fold is just that pattern run
the other way (read the stream, write the engine). It ships the at-least-once/fold-before-trim guarantee ONCE,
store-side, where a reviewer can point at one component and say "this is why no archived entry is lost." B2
(host consumer) is the right answer when the fold is genuinely per-host policy the platform should not
standardize — surfaced for the Operator. B3 (injected callback) is the one to avoid as a default: it puts a
cross-system crash-safety invariant inside the bus, which cannot verify it.

> **Pre-empted bus-lens objection:** *"The fold-consumer should live in the bus — that's where the stream and
> the consumer machinery already are (the `StreamConsumer` shape emq3.3 ships). Pushing it into echo_store
> means the store reaches up into the bus's read path, and an injected callback (B3) keeps the machinery where
> it belongs while inverting the one dependency edge cleanly."* Answer: the persistence lens reads the
> dependency direction not as an obstacle to route around with a callback, but as the platform's FACT about
> who owns durability — the store does, the bus does not. The bus's `StreamConsumer` shape is real and the
> fold consumer can REUSE that shape, but the fold's defining act is a DURABLE COMMIT to the engine, and that
> act — plus the fold-before-trim ordering that makes it loss-free — belongs with the component that owns
> durability and can verify the commit landed. B3's injected callback does invert the edge legally, but it
> relocates the no-loss invariant INTO the bus, which cannot observe the engine's durable extent to enforce
> "nothing is trimmed until its segment is committed." B1 keeps that invariant where it is checkable (the
> store sees the commit ack and the trim it issues), ships it once, and matches the as-built `Committer`'s
> store-reaches-up shape exactly. The bus owning the stream and the store owning the fold-into-durability is
> not a layering violation — it is the loop the manuscript already describes, with each half owned by the
> surface that can guarantee it.

---

### F-ENG-C — eg.6's deferral + the forward two-engine path toward the ADR-A north star

**The fork.** eg.6 (the integrated Rust deploy + per-workload shootout) is DEFERRED behind the fly.io EchoMQ
deploy floor. Given that, does emq3.5 ride the native engine ALONE — and what is the two-engine coexistence's
forward trajectory toward the v4 commit-log-as-outbox north star?

> **Arm C1 — emq3.5 rides the native engine alone; the Rust engine stays a deferred specialized peer; the
> forward path is the native engine BECOMING the ADR-A outbox substrate.** The archive folds into the native
> `EchoStore.Graft` only (F-ENG-A, A1). The Rust engine remains the eg.6-deferred peer for raw-page/replica
> workloads. The forward trajectory: the native engine's commit log — which ALREADY hosts the outbox
> (`@obx_base`, `plugins/graft.ex:46`) — becomes the canonical v4 transactional substrate (ADR-A), subsuming
> the SQLite journal (ADR-E), with the archive as a third tenant on the same log.
>
> - *Rationale.* This is the persistence lens's whole arc in one arm. The native engine is the floor; eg.6's
>   deferral means the floor the Stream Tier stands on is the native one (the Rust deploy floor is not ready);
>   and the v4 north star (ADR-A) makes the native commit log the universal substrate — the outbox, the
>   archive, and the Tables all tenants of one append-only, fenced, replicated log. The pieces are already in
>   place: the outbox is a reserved range on the native log (`plugins/graft.ex`), the Committer drains it
>   (ADR-C, `committer.ex`), and ADR-E retires SQLite once ADR-A lands. The two-engine coexistence's forward
>   path is NOT convergence-now (D-4 defers that post-eg.6) — it is the native engine deepening into the ADR-A
>   substrate while the Rust engine waits for its deploy floor and its named workloads.
> - *5W.* **Why** — the floor the live Stream Tier stands on is the native engine (eg.6 deferred), and the v4
>   north star makes that engine's log the universal substrate. **What** — emq3.5 → native engine; the
>   forward path → ADR-A (commit-log-as-outbox canonical) + ADR-E (`exqlite` retires); the Rust engine remains
>   a deferred peer (D-4 convergence post-eg.6). **Who** — the platform; the bus consumes the floor unchanged
>   (sees `enqueue`/the archive surface). **When** — emq3.5 now; ADR-A/E on the v4 line; eg.6 when the deploy
>   floor lands. **Where** — native `EchoStore.Graft` (`graft.ex`); the outbox `plugins/graft.ex`; the v4 ADRs
>   (`echo_mq-v4-durability-adr.md`); the deferred Rust rung `graft.6.md` (`status: Draft`).
> - *Steelman.* The two-engine coexistence is sometimes read as an unresolved tension ("which one wins?"). The
>   persistence lens reads it as RESOLVED for the present and DEFERRED for the future, both correctly: present
>   = the native engine is canonical and carries the live floor (the archive, the outbox, the Tables); future
>   = D-4 (convergence) waits for the eg.6 per-workload shootout to produce EVIDENCE rather than a guess
>   (`graft.engine-split.design.md` §7). That is the right shape — no premature winner, a real measurement
>   gate, and a clear north star (ADR-A) the native engine is already half-built toward. The forward path is
>   not "pick an engine" but "deepen the canonical floor into the universal substrate, and let the shootout
>   rule convergence when the deploy floor makes it measurable."
> - *Steward.* The honest cost: two page engines is a standing maintenance surface until D-4 rules, and the
>   "native deepens into ADR-A while Rust waits" path means the Rust engine's eg.1–eg.5 investment does not
>   reach the live archive path soon. The steward accepts this — it is the Operator's ruled posture (A
>   coexist, D-4 deferred) — and names it plainly: coexistence is a real keep-cost, justified by reversibility
>   (A keeps the door open to B or C after evidence) and by the two engines genuinely serving different
>   workloads (native = in-process/low-dep; Rust = raw-page/deployable).

> **Arm C2 — accelerate the Rust engine onto the archive path now (treat eg.6's deferral as a gap to close,
> not a sequencing fact).** Bring eg.6's deploy floor forward so the archive can ride the Rust engine, making
> the Rust engine the durable spine sooner.
>
> - *Rationale.* The Rust engine fills the "transactional + replicated" quadrant in the original roadmap
>   framing; getting it onto the live archive path proves the harder bet and the deployable-backend story
>   earlier.
> - *Steward.* The steward's verdict against C2: eg.6's deferral is not an oversight to close — it is a RULED
>   sequencing fact with a named root (the fly.io EchoMQ deploy floor does not exist; eg.5 proved the binding
>   only against a local Valkey, `graft.roadmap.md`). Accelerating the Rust engine onto the archive would gate
>   a shipping bus rung (emq3.5) on building a deployment floor the durability roadmap deliberately defers, and
>   would mandate a cross-runtime crash domain on the archive path before the per-workload shootout (D-5) has
>   shown the Rust engine WINS the archive workload. C2 spends the most risk for the least-evidenced need —
>   the same trap `graft.engine-split.design.md` §5 names against Option B (retire the native engine).

**Ranked recommendation (Lens B — persistence-led): C1 (emq3.5 rides the native engine alone; the forward
path is the native engine becoming the ADR-A substrate; the Rust engine stays a deferred, evidence-gated
peer).** C1 carries because it is the Operator's ruled posture read forward correctly: the native engine is
canonical and carries the live floor (eg.6 deferred), the v4 north star (ADR-A) makes that engine's log the
universal substrate the outbox already seeds, and D-4 convergence waits for the eg.6 shootout's evidence
rather than a premature guess. The development path the persistence lens proposes is exactly this: harden the
engine + the outbox toward ADR-A; the bus archive (emq3.5) is the consequence of the floor already being
there; the Rust engine earns the archive path when its deploy floor lands and the shootout names its workloads.

> **Pre-empted bus-lens objection:** *"The bus shouldn't have to wait on, or reason about, the engines'
> coexistence roadmap at all — emq3.5 needs a durable commit, the store provides one, done. And the two-engine
> question is a store-internal matter that the Stream Tier design should treat as opaque."* Answer: the
> persistence lens AGREES the bus consumes durability opaquely — it calls `commit/3` and the floor does the
> rest. The reason the coexistence roadmap matters to THIS design is narrow and load-bearing: F-ENG-A chooses
> WHICH engine `commit/3` lands in, and that choice cannot be opaque because one engine (native) is in-process
> and ready while the other (Rust) is gated behind eg.6's deferred deploy floor. Treating the engine choice as
> opaque would let "the store provides a durable commit" silently route the live archive into a Rust engine
> whose deploy story is not built — a sequencing fault the bus lens's opacity would hide. The persistence lens
> surfaces it precisely so the Operator rules with the sequencing visible: native now (ready, canonical,
> in-process), Rust later (evidence-gated, deploy-floor-gated). The development path's whole reframe — engine
> as substrate, bus as consequence — is what makes this sequencing legible instead of an accident.

---

## §Fork ledger (Lens B — persistence-led)

| Fork | Lens-B ranked arm | One-line reason |
|---|---|---|
| **F-ENG-A** which engine the bus folds into | **A1** native `EchoStore.Graft` (canonical floor); A2 Rust as an Operator-declared per-stream escalation once eg.6's deploy floor lands | The native engine IS the canonical, in-process, untouched, already-dogfooded floor; the archive is its consequence (*"nearly free"*); A1 avoids gating a shipping bus rung on the deferred Rust deploy. |
| **F-ENG-B** fold-consumer placement (dependency direction) | **B1** echo_store-side fold StreamConsumer (the store reaches UP — the FEATURE); B2 host-consumer for genuine per-host policy; avoid B3 | The dependency direction makes B1 the only placement legally touching both the stream-read and the engine-commit; it mirrors the as-built `Committer` and ships the no-loss guarantee once, checkably. |
| **F-ENG-C** eg.6 deferral + forward path | **C1** native alone for emq3.5; forward path = native → ADR-A substrate; Rust a deferred evidence-gated peer (D-4 post-shootout) | The Operator's ruled posture read forward: native carries the live floor (eg.6 deferred), the v4 north star makes its log the universal substrate, convergence waits for the shootout's evidence. |

**Where I most expect to DIVERGE from the bus lens (this chapter):**
- **F-ENG-B** — the sharpest divergence: the bus lens likely wants the fold consumer IN the bus (reusing the
  `StreamConsumer` machinery) with an injected callback (B3) to invert the one dependency edge; the
  persistence lens places it store-side (B1) because durability — and the fold-before-trim no-loss invariant —
  belongs with the surface that owns and can verify it.
- **F-ENG-A** — possible divergence on the escalation: the bus lens may treat the engine choice as fully
  opaque/store-internal; the persistence lens insists native-vs-Rust is a sequencing-visible choice (native
  ready, Rust eg.6-deferred) the Operator must rule, not default.
- **F-ENG-C** — likely convergence on "native now," possible divergence on how much the Stream Tier design
  should reason about the engines' forward path (the persistence lens makes it central; the bus lens may want
  it opaque).

---

## §Manuscript reconciliation (proposed from this lens — PROPOSE only; the Director applies)

1. **`engines/beam-rust-contract/index.md` — resolve the status-voice drift: the dives are marked `_(soon)_`
   though the page is `status: established` and eg.4 is SHIPPED.** Lines 29–31 mark Dives 10.1/10.2/10.3
   `_(soon)_`, but the front-matter is `status: established` and the hub itself says *"This is rung eg.4"*
   (shipped, per `graft.roadmap.md`). *Proposed:* drop the `_(soon)_` markers on the three dives (or, if the
   dives are genuinely unwritten, change the hub's framing to "the three dives ahead" rather than asserting an
   established contract whose dives are pending). This is a docs-vs-as-built inconsistency the recon flagged —
   surfaced for the Director, who owns the manuscript edit.

2. **`engines/beam-rust-contract/index.md` + `the-volume-server.md` (native-elixir) — flag the surviving
   "Litestream replacement" wording.** The native engine's moduledocs describe the `Streamer` as *"the native,
   real-time replacement for the Litestream sidecar"* (`graft.engine-split.design.md` §3b quotes it from
   `streamer.ex`), but Litestream/`Shadow` were RETIRED (`emq.streams.md`: *"the `EchoStore.Shadow` behaviour
   is retired … the Litestream sidecar is gone"*). The "replacement for Litestream" framing is now describing
   a thing that no longer exists to be replaced. *Proposed:* note in the manuscript (and flag for a future code
   moduledoc pass — OUTSIDE this design's edit scope) that the `Streamer` is simply the native real-time
   shipper; the "replacement for Litestream" lineage is historical. NOTE-ONLY: the code moduledoc lives in
   `streamer.ex`, which this design does NOT edit.

3. **`overview/persistence-in-the-platform.md` §2 — the framing already matches this lens; reinforce it.** §2
   states *"EchoMQ itself dogfoods the page engine as its durable spine, and the planned Stream Tier archives
   there — so Echo Persistence is not a bolt-on beneath the bus, it is the floor the bus stands on."* This is
   the persistence lens verbatim — no edit needed; flagged as the manuscript's existing endorsement of the
   reframe (a CONVERGENCE point, not a drift).

---

## §What I deliberately did NOT decide

- **Every fork is the Operator's.** A1-vs-A2 (and the per-stream escalation threshold), B1-vs-B2-vs-B3, and
  C1-vs-C2 are recommendations with one reason each — the choice belongs to the Operator after the Director
  stages this lens against the bus lens.
- **The COEXIST boundary is absolute and NOT mine to move.** D-1=A (native canonical + untouched) and D-2 (the
  `echo_graft_backend`/`echo_graft_proto`/`EchoStore.GraftBackend` names) are Operator rulings
  (`graft.engine-split.design.md` §7); this design reads every `EchoStore.Graft.*` and `echo_graft_*` surface
  as read-only.
- **D-4 (two-engine convergence)** stays DEFERRED post-eg.6 — I argue the forward TRAJECTORY (native deepens
  toward ADR-A; Rust waits for evidence) but do not pre-empt the convergence ruling, which is the shootout's
  to inform.
- **No canon edit, no engine edit, no code, no git.** This document touches exactly one file (itself); the
  manuscript edits above are PROPOSED for the Director.

---

## §Surface citations (NO-INVENT)

**As-built (module / file:line — verified at source this session):**

- `EchoStore.Graft` (native, canonical floor) — `open_volume/2` (`graft.ex:31`), `new_volume_id/0` (`:38`),
  `commit/3` defdelegated to `VolumeServer` (`:41`), `read/2` (`:48`), `read_at/3` (`:56`); moduledoc
  *"Native-BEAM Graft … no foreign engine"* (`graft.ex:2-4`) — `echo/apps/echo_store/lib/echo_store/graft.ex`.
- `EchoStore.Graft.VolumeServer` — single-writer mailbox = write lock (`volume_server.ex:1-8`); `commit/3` OCC
  `{:error,{:conflict,head}}` (`:48-51, 129-159`); `Streamer` started on a remote (`:90-101`); `Sync`
  read-context registration (`:106-111`) — `echo/apps/echo_store/lib/echo_store/graft/volume_server.ex`.
- `EchoStore.Graft.Sync` — `publish_notice`/`subscribe_commits`/`decode_notice`; channel
  `graft:{vol}:commits` (`sync.ex:41`) — `echo/apps/echo_store/lib/echo_store/graft/sync.ex`.
- `EchoStore.Graft.Committer` — the commit-log-as-outbox drain (ADR-C): `subscribe_commits` (`committer.ex:56`),
  `announce/4` enqueues a JOB (`:99-107`), persisted SyncPoint frontier `advance/2` (`:110-114`);
  moduledoc the mirror-of-the-fold precedent (`:1-18`) — `echo/apps/echo_store/lib/echo_store/graft/committer.ex`.
- `EchoStore.Durability.Graft` — the outbox is the commit log; reserved range `@obx_base = :erlang.bsl(1,48)`
  (`plugins/graft.ex:46`); consumes the NATIVE engine (`VolumeServer`/`Store`, `plugins/graft.ex:39-41`) —
  `echo/apps/echo_store/lib/echo_store/plugins/graft.ex`.

**Forward-tense (a surface a Stream rung BUILDS — not yet on disk):**

- The emq3.5 fold consumer (F-ENG-B) — a store-side StreamConsumer (B1) reading the bus stream surface and
  committing slices via `EchoStore.Graft.commit/3`, mirroring `EchoStore.Graft.Committer`'s store-reaches-up
  shape; fold-before-trim ordering.
- `EchoStore.GraftBackend.commit/5` (F-ENG-A, A2 escalation) — the Rust-engine client path, available once
  eg.6's deploy floor lands; named in the engine-split memory + `graft.engine-split.design.md` §6.

**Canon / design cited:**

- `docs/graft/graft.engine-split.design.md` — the COEXIST ruling (D-1=A native canonical+untouched, D-2 names,
  §7); the two-engine capability maps (§3a Rust / §3b native / §3c outbox); the
  outbox-consumes-the-native-engine seam (§3c); the duplicated-vs-complementary split (§4); the
  resolution options + Option-A recommendation (§5).
- `docs/graft/graft.roadmap.md` — eg.1–eg.5 SHIPPED; eg.6 DEFERRED behind the fly.io EchoMQ deploy floor;
  `graft.6.md` `status: Draft`; the per-workload shootout (D-5).
- `docs/echo-persistence/engines/**` — the chapter under reconciliation: `beam-rust-contract/index.md` (the
  wire-is-the-contract, the compositional proof, the `_(soon)_` drift), `native-elixir/the-commit-log-outbox.md`
  (one log, three jobs).
- `docs/echo-persistence/overview/persistence-in-the-platform.md` — *"the floor the bus stands on"* (the
  manuscript's existing endorsement of the reframe).
- `docs/echo_mq/kb/emq4-durability/echo_mq-v4-durability-adr.md` — ADR-A (commit-log-as-outbox), ADR-C (the
  stream-subscriber committer), ADR-E (`exqlite` retires).
- `docs/echo_mq/emq.streams.md` — the archive folds into `EchoStore.Graft`; *"the fold being a property of the
  engine already in place is what makes the archive nearly free."*
- `echo/CLAUDE.md` §1 — the `echo_store → echo_mq` dependency direction (the table).

---

*Lens B — the persistence-led / vision-forward lens. Authored independently; the sibling bus-led lens
(`A-lens.md`) was not read. Convergence is confidence; divergence is the signal. The Director synthesizes; the
Operator rules.*
