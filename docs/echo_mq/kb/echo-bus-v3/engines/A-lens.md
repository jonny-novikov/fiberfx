# echo-bus-v3 · Chapter III (the engines) — Lens A: BUS-LED

> **Lens A — the BUS-LED view ("the log reaches down to the floor").** This chapter argues every engine
> fork from the runtime that OPERATES and CARRIES the work: the EchoMQ Stream Tier, the platform's spine.
> The priorities, in order: (1) the Stream Tier is the spine — the log that carries work; (2) **emq3.5, the
> archive fold, is the keystone** — the bus reaching down into the durable engine; (3) the forward climb
> streams → retention → archive → time-travel → the BCS substrate; (4) persistence is the **floor the bus
> stands on** — an engine the bus *consumes* through a public facade, never the master. This chapter
> CHAMPIONS: the fold-consumer as a BUS citizen reading off the wire and writing into the engine as a SINK,
> the native `EchoStore.Graft` engine as the one the bus folds into (per COEXIST), and the engine consumed
> as a peer with ZERO engine edits. It honors the Steward part of each arm honestly.
>
> Forks are **SURFACED, never decided**. **NO-INVENT** holds: every named surface is verified at its source
> (cited `file:line`) or written forward-tense. **Authored independently — the sibling (persistence-led)
> lens was not read.**

---

## §0 · Context

**What this chapter is.** Chapter III of the echo-persistence manuscript is the **engines** — the native
Elixir `EchoStore.Graft` engine on CubDB (VolumeServer / Reader / Committer), the Rust `echo_graft_backend`
on Fjall + OpenDAL, Tigris + the conditional-write fence, and the BEAM↔Rust contract. From the bus lens this
chapter answers: **which engine does the bus fold into, WHERE does the fold-consumer live given the
dependency direction, and what is the two-engine coexistence's forward path.** The engine is the SINK at the
bottom of the fold; the bus is the citizen that writes into it.

**What is as-built (verified against disk, cited).**

- **COEXIST is RULED — two engines, native canonical + untouched.** "D-1 = Option A (COEXIST), D-2 =
  `echo_graft_backend`" — both engines kept; the native `EchoStore.Graft.*` engine stays canonical and
  **untouched**; the Rust engine is a **coexisting peer** (`docs/graft/graft.engine-split.design.md` §0, §7
  ledger; Operator ruling 2026-06-21). D-4 (long-term convergence of the two page-engines) is **DEFERRED —
  post-eg.6** (§7 ledger).
- **The native engine's public fold target.** `EchoStore.Graft.VolumeServer.commit/3` — the single-writer
  commit path (the mailbox IS the write lock, `volume_server.ex:2-8`), at `volume_server.ex:50`, OCC-rejecting
  a stale base (`:129-159`). Plus `open_volume/2` (`graft.ex:31`), `read/2` (`graft.ex:48`), `read_at/3`
  (`graft.ex:56`), `head_lsn/1` (delegated, `graft.ex:40-44`). The native engine's bus notices ride
  `EchoStore.Graft.Sync` on channel `graft:<vol>:commits` (`sync.ex:41`).
- **The Rust backend is a distinct peer on distinct lanes.** `EchoStore.GraftBackend.commit/5`
  (`echo/apps/echo_store/lib/echo_store/graft_backend.ex:122`, `:mode` `:sync`|`:async` at `:123`); the
  command lane `egraft:cmd:<vol>` (`graft_backend.ex:59`) and the feed lane `egraft:feed:<vol>`
  (`graft_backend.ex:63`) — DISTINCT from the native `graft:<vol>:commits` (`graft.engine-split.design.md` §6:
  "the change-feed lane is distinct, not shared"). The wire is the byte-frozen `echo_graft_proto` via
  `EchoStore.GraftBackend.Proto`; the contract was proven COMPOSITIONALLY at eg.4 (D-7=A — Rust dispatch
  in-process, BEAM client over live Valkey `:6390`, meeting at shared fixtures;
  `docs/echo-persistence/engines/beam-rust-contract/index.md` §2).
- **The dependency direction is LOAD-BEARING.** `echo/apps/echo_store/mix.exs` deps/0 declares
  `{:echo_mq, in_umbrella: true}` (`:27`) — echo_store depends on echo_mq. `echo/apps/echo_mq/mix.exs` deps/0
  declares only `{:echo_data, …}` + `{:echo_wire, …}` (`:30-31`) — **echo_mq does NOT depend on echo_store.**
  Therefore `echo_mq` CANNOT call `echo_store`; the fold-consumer must live echo_store-side or host-side.
- **eg.6 is DEFERRED, not next.** The Graft roadmap: eg.1–eg.5 SHIPPED; eg.6 (cross-compile Mac+Windows + CI +
  the per-workload durability shootout, D-5) is DEFERRED behind a fly.io EchoMQ deploy floor. The live frontier
  is the BUS rung **emq3.5** (the recon brief; `graft.engine-split.design.md` §7 D-4/D-5; the eg.4 dive notes
  "the one literally-connected Rust-to-Valkey socket… deferred by ruling to eg.5/eg.6",
  `beam-rust-contract/index.md` §2).
- **`EchoMQ.StreamConsumer` IS as-built** (emq3.3 shipped it) — `echo/apps/echo_mq/lib/echo_mq/stream_consumer.ex`
  (present, ~19.7 KB). The streams-tier KB wrote it forward-tense; it is now real, so the fold-consumer can be
  a configured `StreamConsumer`, but it lives in echo_mq and CANNOT itself call echo_store (the dependency
  direction) — F-ENG-B resolves where the fold-into-engine step actually executes.

> **The one question this chapter must answer well, from the bus lens:**
> The bus carries the work and the engine is its durable sink — but `echo_mq` cannot call `echo_store`, so the
> code that reads a trimmed slice off the bus and writes it into the engine cannot be a plain method on a bus
> module. Where does the fold-consumer LIVE, which engine does it write into, and how does that placement keep
> the bus the spine and the engine the floor without a dependency inversion or a COEXIST violation?

---

### F-ENG-A — which engine does the bus fold into? (native `EchoStore.Graft` vs Rust `echo_graft_backend`)

> **Arm A1 — the bus folds into the NATIVE `EchoStore.Graft` engine via its public `commit/3`.** emq3.5's
> fold-consumer commits each trimmed slice through `EchoStore.Graft.VolumeServer.commit/3`
> (`volume_server.ex:50`), the native canonical engine, adding NO method to it.
> - *Rationale.* COEXIST rules the native engine canonical and untouched (`graft.engine-split.design.md` §0);
>   the canon explicitly names the fold target as the native engine — emq3.5 "folds trimmed stream segments
>   into the `EchoStore.Graft` engine's local CubDB and lets the engine stream those pages natively to Tigris"
>   (`emq.streams.md` §"The durable-archive answer"). The native engine is in-process on the BEAM, so the fold
>   is a function call, not a cross-runtime wire.
> - *5W.* **Why** — the canonical engine is the one canon names, it is in-process (no wire hop), and consuming
>   its public `commit/3` honors COEXIST literally. **What** — the fold-consumer commits slices via
>   `VolumeServer.commit/3` (`volume_server.ex:50`), reads them back via `read_at/3` (`graft.ex:56`). **Who** —
>   the emq3.5 fold-consumer (echo_store-side per F-ENG-B), a CLIENT of the engine. **When** — emq3.5. **Where**
>   — over `volume_server.ex:50` (`commit/3`) + `graft.ex:48-56` (reads), all public, all verified.
>   **Steelman.** Three things converge on the native engine. (1) Canon names it: the durable-archive answer is
>   the native `EchoStore.Graft` engine, one knob `remote_cfg`, not a sidecar (`emq.streams.md`). (2) COEXIST
>   makes it the canonical untouched default (`graft.engine-split.design.md` §0); the fold consuming its public
>   `commit/3` is the cleanest possible honoring of "consume as a peer, no engine edit." (3) It is in-process:
>   the native engine lives in the BEAM (`graft.ex:2-4` "Native-BEAM Graft… with no foreign engine"), so the
>   fold pays no cross-runtime wire, no proto encode, no backend availability dependency — a slice-commit is a
>   GenServer call into `VolumeServer`'s mailbox (`volume_server.ex:2-8`). The streams-tier KB already
>   converged both lenses on exactly this (`streams.synthesis.md` F3.5-A: "commits each trimmed slice to the
>   native engine via its PUBLIC `commit/3` — COEXIST honored literally, no engine edit"). **Steward.** The
>   keep-cost: the fold now depends on the native engine's availability and failure modes (CubDB/Tigris
>   unreachable, an OCC conflict) — but those are the archive's failure modes regardless of engine, and the
>   fold-then-trim safety turns an unreachable Tigris into stalled retention (memory grows) rather than dropped
>   data (`streams.synthesis.md` F3.5-A Steward). It ties emq3.5 to the native engine specifically, so IF the
>   Operator later rules convergence onto Rust (D-4, deferred), the fold's commit call-site moves — but that is
>   a deferred horizon decision, and A1 keeps the fold a thin client either way.

> **Arm A2 — the bus folds into the Rust `echo_graft_backend` via `EchoStore.GraftBackend.commit/5`.** The
> fold-consumer commits slices over the byte-frozen `echo_graft_proto` wire to the Rust backend on
> `egraft:cmd:<vol>`, riding the bus to the engine (`graft_backend.ex:122`).
> - *Rationale.* The Rust backend is REACHED over the bus (`beam-rust-contract/index.md` §1: "the platform
>   reaches it the way it reaches everything else — over EchoMQ"), so folding into it is itself a bus
>   operation — the most bus-native framing of "the log reaches the floor."
> - *5W.* **Why** — the Rust engine is driven entirely over EchoMQ, so a fold into it is a pure bus act (no
>   in-process engine coupling at all). **What** — the fold-consumer sends `Commit` on `egraft:cmd:<vol>` via
>   `EchoStore.GraftBackend.commit/5` (`graft_backend.ex:122`). **Who** — the fold-consumer as a GraftBackend
>   client. **When** — emq3.5. **Where** — `graft_backend.ex:122` (`commit/5`), the `egraft:cmd:<vol>` lane
>   (`:59`). **Steelman.** The most bus-pure story: the engine is a backend the bus drives, so the fold becomes
>   "publish a Commit on the command lane, get an Ack with the LSN, the feed publishes a FeedEvent"
>   (`beam-rust-contract/index.md` §1) — entirely on the wire, no cross-app in-process call, no dependency-
>   direction problem at all (the fold-consumer in echo_mq could in principle drive the backend over the bus
>   without linking echo_store). The Rust engine does "blocking object-storage and LSM I/O" in a supervised
>   process whose crash is a restart, not an outage (`beam-rust-contract/index.md` §2), which is the right home
>   for the archive's heavy I/O. **Steward.** The keep-cost is decisive against this arm. (1) It CONTRADICTS
>   canon: the durable-archive answer names the NATIVE engine, not the backend (`emq.streams.md`). (2) It
>   CONTRADICTS COEXIST: the native engine is canonical; routing the archive to the Rust peer makes the peer
>   the archive's engine, which the ruling did not assign (the Rust engine serves "raw page/Volume + replica-
>   recovery workloads", `graft.engine-split.design.md` §5 Option A) — and D-4 convergence is explicitly
>   DEFERRED, so pre-committing the archive to Rust pre-empts a deferred decision. (3) eg.6 is DEFERRED: the
>   "one literally-connected Rust-to-Valkey socket" is a deployment concern deferred to eg.5/eg.6
>   (`beam-rust-contract/index.md` §2), so routing the archive through the backend ties emq3.5's keystone to a
>   deferred deploy floor. (4) It pays a cross-runtime wire (proto encode, backend availability) for every
>   slice when the native in-process engine is right there. The bus-pure elegance is real but it is bought
>   against canon, against COEXIST, and against a deferred deploy floor.

**Ranked recommendation (Lens A — bus-led): A1 (fold into the NATIVE `EchoStore.Graft` via public `commit/3`),
decisively — and this is a CONVERGENCE with canon, COEXIST, and the prior streams-tier synthesis.** The bus
lens, even reading the platform forward from the bus, lands on the native engine: canon names it
(`emq.streams.md`), COEXIST rules it canonical + untouched (`graft.engine-split.design.md` §0), it is
in-process (no wire hop, no proto, no backend-availability dependency), and consuming its public `commit/3`
(`volume_server.ex:50`) honors "consume as a peer, no engine edit" literally. A2's bus-pure framing (fold over
the wire into the Rust backend) is the most bus-native STORY, but it contradicts canon AND COEXIST AND ties
emq3.5 to the DEFERRED eg.6 deploy floor — three reasons the keystone rung should not absorb. The COEXIST
boundary stated plainly: **emq3.5 folds into the native engine; the Rust `echo_graft_backend` stays the peer
for raw-page/replica-recovery workloads on its own `egraft:*` lanes; the two never share the archive, and
D-4 convergence is the Operator's deferred call.**

> **Pre-empted persistence-lens objection:** *"The Rust engine is the platform's eventual durability spine
> (the roadmap framed it filling the transactional+replicated quadrant), and the BEAM↔Rust contract is already
> proven; folding into the native CubDB engine entrenches the engine the convergence (D-4) may retire,
> building emq3.5 on a path that becomes legacy."* Answer: D-4 is explicitly DEFERRED to post-eg.6
> (`graft.engine-split.design.md` §7), and COEXIST rules the native engine CANONICAL today (§0) — so the
> non-speculative, ruled choice IS the native engine; pre-committing the archive to Rust pre-empts a deferred
> decision against the current ruling. The proven contract is real but eg.6's live socket is DEFERRED behind a
> deploy floor (`beam-rust-contract/index.md` §2), so the Rust path is not yet a production deploy target for
> the keystone rung. A1 also keeps the fold a THIN CLIENT of a public `commit/3` — if convergence later rules
> Rust, the fold's commit call-site moves to `GraftBackend.commit/5` with the fold-consumer's structure
> unchanged. The bus lens builds emq3.5 on the ruled, in-process, canon-named engine and leaves convergence to
> the Operator's deferred shootout — exactly where the ruling put it.

---

### F-ENG-B — the fold-consumer placement (the dependency-direction fork)

`echo_mq` cannot call `echo_store` (verified: `echo_mq/mix.exs:30-31` has no echo_store edge;
`echo_store/mix.exs:27` depends on echo_mq). So the code that reads a trimmed slice off the bus AND writes it
into `EchoStore.Graft.commit/3` cannot be a plain echo_mq module. Three placements.

> **Arm B1 — an echo_store-side `StreamConsumer`-shaped fold-consumer (echo_store owns the fold).** The
> fold-consumer is a process IN echo_store that uses `EchoMQ.StreamConsumer` (or its consumer primitives) to
> read the stream off the bus and `EchoStore.Graft.VolumeServer.commit/3` to write — legal because echo_store
> already depends on echo_mq (`echo_store/mix.exs:27`).
> - *Rationale.* echo_store depends on echo_mq, so an echo_store-side process can call BOTH the bus (read the
>   slice) and the engine (commit it) — the only app that can see both surfaces. The fold is "read off the bus,
>   write to the engine," and echo_store is where both are in scope.
> - *5W.* **Why** — the dependency direction makes echo_store the one place a single process can consume the
>   bus AND the engine; the fold needs both. **What** — an echo_store process consuming `EchoMQ.StreamConsumer`
>   (`stream_consumer.ex`, as-built) reading the stream, committing via `EchoStore.Graft.VolumeServer.commit/3`
>   (`volume_server.ex:50`). **Who** — echo_store, supervised under its own tree, consuming both facades.
>   **When** — emq3.5. **Where** — forward-tense in echo_store (e.g. an `EchoStore.StreamArchive`-shaped module)
>   consuming `EchoMQ.StreamConsumer` (echo_mq, as-built) + `EchoStore.Graft` (echo_store, as-built).
>   **Steelman.** This is the placement the dependency direction MAKES natural: echo_store → echo_mq is the
>   existing edge (`echo_store/mix.exs:27`), so an echo_store-side fold-consumer reads the bus through echo_mq's
>   public consumer surface and writes the engine through echo_store's own `commit/3` — both calls in scope, no
>   inversion, no new dependency edge. The native engine's own `Committer` is ALREADY an echo_store-side process
>   that consumes a bus channel and drains it ("subscribes to the commit channel, re-publishes each commit's
>   names to a work queue", `graft.engine-split.design.md` §3b citing `committer.ex:99-114`) — so "an
>   echo_store process that consumes the bus and writes durably" is a SHIPPED shape; the fold-consumer is the
>   same shape pointed the other way (bus → engine instead of engine → bus). It honors the bus lens cleanly:
>   the fold-consumer is a BUS CITIZEN (it reads `XREADGROUP` off the wire like any consumer) that happens to
>   live in echo_store because that is where the engine sink is in scope. **Steward.** The keep-cost: the fold
>   logic lives in echo_store, not echo_mq, so a reader looking for "the archive fold" finds it across the app
>   boundary from the Stream Tier code — the spec must NAME this placement clearly (the fold is a bus consumer
>   that lives store-side by dependency necessity) or it reads as a surprise. It also means echo_store grows a
>   new supervised process (the fold-consumer) beside the engine, which echo_store's operator now owns.

> **Arm B2 — a HOST-APP consumer (the consuming application wires the fold).** Neither echo_mq nor echo_store
> owns the fold; a host application (codemojex, or a dedicated archive app) wires a consumer that reads the
> stream and commits to the engine, composing the two public facades itself.
> - *Rationale.* The fold is an application policy (which streams to archive, into which Volumes, on what
>   cadence); pushing it to the host keeps both echo_mq and echo_store free of a cross-concern and lets each
>   host choose its archive policy.
> - *5W.* **Why** — archive policy is application-specific; a host that owns the streams owns their archival.
>   **What** — a host process composing `EchoMQ.StreamConsumer` + `EchoStore.Graft.commit/3`. **Who** — the
>   host app (codemojex / an archive service). **When** — emq3.5. **Where** — forward-tense in a host app.
>   **Steelman.** Maximum flexibility + minimum library coupling: neither library grows a cross-app process,
>   and each host wires exactly the archive policy it wants. It is the most honest about archival being a
>   policy, not a mechanism. **Steward.** The keep-cost is the one the bus lens weights heavily against: the
>   tier PROMISES the archive as a built capability ("the archive: a group consumer folding trimmed segments
>   into the Graft engine", `emq.streams.md` ladder emq3.5) — pushing it to the host leaves that promise
>   UN-KEPT and makes every host hand-roll the fold (the fold-then-trim safety, the watermark derivation, the
>   segment shaping), the exact DX tax the bus lens refuses. It also risks N divergent fold implementations
>   that get the fold-then-trim ordering subtly wrong (a host's timer-driven trim outrunning its fold,
>   dropping un-archived data — the failure `retention…md` §2 dramatizes). The archive is too load-bearing to
>   be un-owned.

> **Arm B3 — an injected callback (echo_mq's consumer calls an injected fold function the host/echo_store
> supplies).** `EchoMQ.StreamConsumer` (in echo_mq) gains a fold-callback option; the host (or echo_store)
> injects a function that commits the slice to the engine, so the fold runs FROM echo_mq's consumer beat
> without echo_mq depending on echo_store.
> - *Rationale.* The consumer beat is in echo_mq and already has the slice; injecting the engine-write as a
>   callback lets the fold ride that beat without echo_mq linking echo_store — dependency-direction-legal via
>   inversion of control.
> - *5W.* **Why** — the consumer beat already holds the slice; a callback runs the engine-write there without
>   a dependency edge. **What** — a `:fold_fun`-style callback on `EchoMQ.StreamConsumer`; the host injects a
>   closure over `EchoStore.Graft.commit/3`. **Who** — echo_mq's consumer runs it; the host/echo_store supplies
>   it. **When** — emq3.5. **Where** — `stream_consumer.ex` (as-built) gains a callback option; the closure is
>   host-side. **Steelman.** The fold rides the consumer beat (which already exists and already recovers via
>   PEL-first, `streams.synthesis.md` F3.3-B), so the fold inherits crash recovery for free, AND echo_mq keeps
>   no echo_store dependency (the engine-write is an opaque injected function). It is the tightest coupling of
>   "the consumer that has the slice" to "the write that durably stores it." **Steward.** The keep-cost: an
>   injected callback that does blocking durable I/O (a Tigris-backed `commit/3`) runs INSIDE echo_mq's
>   consumer beat, so a slow/unreachable engine stalls the consumer's beat — coupling the bus's consumer
>   liveness to the engine's durability latency, inside echo_mq. It also makes echo_mq's consumer contract
>   carry a fold-callback surface that only the archive uses, widening a frozen public surface for one caller.
>   And the fold-then-trim ordering now spans echo_mq (the beat, the trim) and the injected closure (the
>   commit) — the safety invariant is split across an injection boundary, harder to spec and gate than a single
>   echo_store-side process that does both in order.

**Ranked recommendation (Lens A — bus-led): B1 (an echo_store-side `StreamConsumer`-shaped fold-consumer),
because the dependency direction makes echo_store the one place a single process sees BOTH the bus and the
engine, and the native `Committer` proves the shape is shipped.** The fold is "read a slice off the bus, write
it into the engine" — and echo_store is the only app where both `EchoMQ.StreamConsumer` (via the existing
`echo_store/mix.exs:27` edge) and `EchoStore.Graft.commit/3` are in scope. The native engine's own `Committer`
is ALREADY an echo_store-side process consuming a bus channel and draining durably
(`graft.engine-split.design.md` §3b, `committer.ex:99-114`), so the fold-consumer is a SHIPPED shape pointed
bus→engine. It keeps the fold a bus CITIZEN (reading `XREADGROUP` off the wire) that lives store-side by
necessity, with the fold-then-trim safety entirely inside ONE process (no injection boundary to split the
invariant across). B2 leaves the tier's archive promise un-kept and invites N divergent folds; B3 stalls the
bus's consumer beat on engine latency and splits the safety invariant across an injection boundary. **This is a
fork where this lens expects to DIVERGE in EMPHASIS:** a persistence-led lens likely ALSO lands echo_store-side
(the engine is store-side), but may frame the fold-consumer as an ENGINE feature (the engine ingesting a
stream) rather than a BUS citizen living store-side — the same placement, a different ownership story.

> **Pre-empted persistence-lens objection:** *"Putting the fold-consumer in echo_store makes it an ENGINE
> concern (the store ingesting durable data), so it should be framed and owned as part of the engine's
> ingestion surface — a bus consumer living in echo_store is really the store reaching up to pull from the
> bus, not the bus reaching down."* Answer: the PLACEMENT is agreed (echo_store-side, by the dependency
> direction — both lenses must land here), so the divergence is only the ownership STORY, and the bus-lens
> framing is the truer one: the fold-consumer reads the stream with `XREADGROUP` off the wire exactly as every
> other consumer does (at-least-once, PEL-first recovery, the consumer beat — `streams.synthesis.md` F3.3-B),
> so it IS a bus citizen by construction; it lives in echo_store only because that is where the engine sink is
> in scope, not because it is an engine feature. The native `Committer` precedent settles it: an echo_store-side
> process that consumes a bus channel is already called a bus consumer, not an engine ingestion surface
> (`committer.ex:99-114`). The fold is the bus reaching down (it reads the bus's trimmed tail and sinks it);
> the store hosts the process only because the dependency direction forbids echo_mq from holding the engine
> reference. Same code, and the bus-citizen framing keeps the spine/floor relationship straight.

---

### F-ENG-C — eg.6's deferral + the forward engine path (does emq3.5 ride the native engine ALONE?)

> **Arm C1 — emq3.5 rides the NATIVE engine ALONE; the Rust backend stays the peer for raw-page/replica
> workloads; convergence (D-4) is the Operator's deferred call after the shootout.** The keystone fold uses
> only `EchoStore.Graft` (native, in-process); `echo_graft_backend` is untouched by emq3.5, serving its own
> raw-page/replica-recovery workloads on `egraft:*` lanes; the two-engine forward path is decided post-eg.6 by
> the per-workload shootout.
> - *Rationale.* COEXIST already ruled the native engine canonical and the Rust engine a peer with a DIFFERENT
>   assigned workload (`graft.engine-split.design.md` §5 Option A, §7 D-4 deferred); emq3.5 has no reason to
>   touch the Rust engine, and the deferred eg.6 deploy floor means the Rust path is not a production deploy
>   target for the keystone yet.
> - *5W.* **Why** — the native engine is canonical, in-process, and canon-named for the archive; the Rust
>   engine has a distinct assigned role and a DEFERRED deploy floor; convergence is a DEFERRED shootout
>   decision. **What** — emq3.5 over `EchoStore.Graft` only; the Rust backend untouched; the forward path
>   parked at D-4/D-5. **Who** — the fold-consumer (native engine); the Operator (the deferred convergence
>   call). **When** — emq3.5 now; convergence post-eg.6. **Where** — `EchoStore.Graft.commit/3`
>   (`volume_server.ex:50`); the Rust peer on `egraft:cmd:<vol>` (`graft_backend.ex:59`), untouched.
>   **Steelman.** This is the ruled, non-speculative path: D-1=A makes the native engine canonical
>   (`graft.engine-split.design.md` §0); the Rust engine serves "raw page/Volume + replica-recovery workloads"
>   (§5 Option A), a workload the Stream Tier archive is NOT; D-4 convergence and D-5 the shootout's shape are
>   the Operator's, post-eg.6 (§7). So emq3.5 riding the native engine alone is exactly what the ruling
>   prescribes, and it keeps the keystone OFF the deferred eg.6 deploy floor (the live Rust-to-Valkey socket is
>   "deferred by ruling to eg.5/eg.6", `beam-rust-contract/index.md` §2). The two engines coexist as the
>   ruling drew them: native for the in-process archive + outbox-on-Graft, Rust for raw-page/replica, distinct
>   lanes (`graft:<vol>:commits` vs `egraft:feed:<vol>`), no overlap. The forward trajectory is honestly a
>   DEFERRED fork (the shootout decides), and naming it deferred is the correct architect posture. **Steward.**
>   The keep-cost: two engines persist long-term until D-4 rules (maintenance of both), and the Rust eg.1–eg.5
>   investment does not reach the ARCHIVE path soon (it serves its own workloads). But that is the ruling's
>   accepted cost (§5 Option A tradeoffs: "two page-engines to maintain long-term; the Operator must later
>   decide whether they converge"), not a new one this fork introduces.

> **Arm C2 — emq3.5 designs the fold ENGINE-AGNOSTIC over a shared commit interface, so it rides either engine.**
> The fold-consumer commits through an abstraction both engines satisfy (a `commit(volume, base, pages)`
> contract `EchoStore.Graft.VolumeServer.commit/3` and `EchoStore.GraftBackend.commit/5` both fit), so emq3.5
> is portable across the native and Rust engines and convergence does not require re-touching the fold.
> - *Rationale.* If the fold targets a shared commit interface rather than a concrete engine, a future
>   convergence (D-4) onto Rust is a config flip, not an emq3.5 edit — future-proofing the keystone against the
>   deferred decision.
> - *5W.* **Why** — an engine-agnostic fold survives the D-4 convergence decision unchanged. **What** — a
>   `commit` behaviour both engines implement; the fold-consumer holds the behaviour, not a concrete engine.
>   **Who** — the fold-consumer over an injected engine module. **When** — emq3.5. **Where** — forward-tense, a
>   behaviour over `volume_server.ex:50` + `graft_backend.ex:122`. **Steelman.** Future-proofs the keystone:
>   the fold does not bind to an engine the convergence might retire, so D-4 (whatever it rules) leaves emq3.5
>   untouched. It is the most defensive posture against a deferred decision. **Steward.** The keep-cost is over-
>   engineering against a DEFERRED, possibly-never decision: the two engines' commit contracts are NOT actually
>   interchangeable — the native `commit/3` is an in-process GenServer call returning `{:ok, lsn}` (`volume_server.ex:50`),
>   the Rust `commit/5` is a bus round-trip with a `:mode` async/sync and a proto-encoded `Ack`
>   (`graft_backend.ex:122-123`), with DIFFERENT failure modes (in-process conflict vs. wire `unavailable`),
>   DIFFERENT latency regimes, and DIFFERENT recovery (the Rust side resubscribes from last-seen LSN,
>   `beam-rust-contract/index.md` §2). An abstraction papering over those differences hides exactly the
>   properties the fold-then-trim safety depends on (when is the slice DURABLE? — a sync in-process return vs.
>   a sync wire Ack are different guarantees). Building the abstraction now, for a convergence the ruling
>   DEFERRED and may never make (it could rule the engines stay specialized, §5 Option A), pays real complexity
>   for speculative portability — the anti-pattern the engine-split design itself warns against ("do not fuse
>   horizon decisions into a rung", §0 / D-4). A1 keeps the fold a thin client whose ONE commit call-site moves
>   if convergence ever rules Rust — a smaller, later cost than a premature abstraction.

**Ranked recommendation (Lens A — bus-led): C1 (emq3.5 rides the native engine ALONE; the Rust backend stays
the peer; convergence is the Operator's deferred post-eg.6 call), because it is the RULED path and keeps the
keystone off the deferred eg.6 deploy floor.** COEXIST ruled the native engine canonical and the Rust engine a
peer with a DISTINCT assigned workload (`graft.engine-split.design.md` §5 Option A); the archive is not that
workload; D-4 convergence is DEFERRED (§7). So emq3.5 over the native engine alone is precisely the ruling's
prescription, and it keeps the keystone in-process and off the deferred Rust deploy floor
(`beam-rust-contract/index.md` §2). C2's engine-agnostic abstraction future-proofs against a DEFERRED,
possibly-never convergence by papering over commit contracts that are genuinely different (in-process call vs.
bus round-trip, different durability semantics the fold-then-trim safety depends on) — over-engineering that
fuses a horizon decision into the rung, exactly what the engine-split design warns against (§0, D-4). Keep
emq3.5 a thin client of the native engine; let the ONE commit call-site move IF convergence later rules Rust.
**This is a fork where this lens expects to DIVERGE:** a persistence-led lens may favor C2's engine-agnostic
abstraction (the engine as a swappable substrate the bus targets generically), weighting portability across the
two engines over the bus lens's "ride the ruled in-process engine, defer the abstraction."

> **Pre-empted persistence-lens objection:** *"Binding emq3.5 to the concrete native engine entrenches a
> coupling the convergence (D-4) will have to unwind; an engine-agnostic commit interface keeps the keystone
> portable and makes the eventual convergence a config flip, which is the principled, future-proof design."*
> Answer: D-4 is DEFERRED and may rule the engines stay SPECIALIZED, not converge (`graft.engine-split.design.md`
> §5 Option A explicitly keeps that open) — so building a portability abstraction now pays certain complexity
> for a speculative, possibly-never payoff, the precise "fuse a horizon decision into a rung" anti-pattern the
> design names (§0). Worse, the two engines' commit contracts are NOT cleanly interchangeable: the native
> `commit/3` is an in-process GenServer call (`volume_server.ex:50`), the Rust `commit/5` is a bus round-trip
> with async/sync modes and wire failure modes (`graft_backend.ex:122-123`) — and the fold-then-trim safety
> turns on KNOWING when a slice is durable, which those two contracts answer differently. An abstraction hides
> exactly the property the safety needs. The future-proof claim is illusory: A1 keeps the fold a thin client
> whose single commit call-site is a one-line move if convergence ever rules Rust — cheaper, later, and
> without hiding the durability semantics. The bus lens binds to the ruled in-process engine and leaves the
> abstraction to the rung that actually needs it (if ever).

---

## §Fork ledger (Lens A — bus-led — ranked arms, for the Director's cross-lens diff)

| Fork | Lens-A ranked arm | One-line reason (bus-led) |
|---|---|---|
| **F-ENG-A** which engine the bus folds into | **A1** the NATIVE `EchoStore.Graft` via public `commit/3` | Canon names it + COEXIST rules it canonical/untouched + in-process (no wire); A2 (Rust) contradicts canon/COEXIST + ties the keystone to the deferred eg.6 deploy floor |
| **F-ENG-B** fold-consumer placement | **B1** echo_store-side `StreamConsumer`-shaped fold-consumer | The dependency direction makes echo_store the one app seeing BOTH bus + engine; the native `Committer` proves the shape; fold-then-trim safety in ONE process |
| **F-ENG-C** eg.6 deferral + forward path | **C1** native engine ALONE; Rust the peer; convergence is the deferred D-4 call | The RULED path (COEXIST §5 Option A); keeps the keystone in-process + off the deferred Rust deploy floor; C2's abstraction fuses a deferred horizon decision into the rung |

**Where this lens most expects to DIVERGE from the persistence lens** (highest-value signals for the
Operator):

1. **F-ENG-C (forward engine path) — C1 native-alone+defer vs the steward's likely C2 engine-agnostic
   abstraction.** The bus lens rides the ruled in-process engine and defers the abstraction; the persistence
   lens likely wants the engine as a swappable substrate the bus targets generically. A RIDE-THE-RULED vs
   FUTURE-PROOF-THE-SUBSTRATE divergence.
2. **F-ENG-B (placement) — agreed echo_store-side, but DIVERGENT OWNERSHIP STORY.** Both lenses land
   store-side (the dependency direction forces it), but the bus lens frames the fold-consumer as a BUS citizen
   living store-side; the persistence lens likely frames it as an ENGINE ingestion feature. Same placement,
   opposite spine/floor story — a high-value framing signal.
3. **F-ENG-A (which engine) — CONVERGENCE expected, both A1.** The bus lens, COEXIST, canon, and the prior
   streams-tier synthesis all land on the native engine. If the persistence lens also lands A1 (likely), this
   is the strongest convergence signal of the engines chapter — both lenses agree the archive folds into the
   native engine.

---

## §Manuscript reconciliation (proposed from this lens — PROPOSE only; the Director applies)

- **`docs/echo-persistence/engines/beam-rust-contract/index.md`** (Module 10 hub) — *what is stale:* its three
  dives are labelled `_(soon)_` (Dives 10.1/10.2/10.3) though the module's frontmatter is `status: established`
  and eg.4 is SHIPPED — an internal status drift. *Proposed framing:* either author the three dives or drop the
  `_(soon)_` markers to match `status: established` and the SHIPPED eg.4 (the recon-flagged inconsistency). No
  content claim changes — only the status marker is reconciled to as-built.
- **`docs/echo-persistence/platform/bus-and-persistence/index.md`** (Module 12 hub) — *what is stale:* §4 calls
  Module 14 `_(soon)_` though the chapter's pages carry `status: established`; the same internal status drift.
  *Proposed framing:* reconcile the `_(soon)_` marker to the established status (or author Module 14), so the
  manuscript does not advertise an established module as forthcoming.
- **`docs/echo-persistence/engines/beam-rust-contract/index.md`** §2 — *what to verify on apply:* it states "the
  one literally-connected Rust-to-Valkey socket is a deployment concern, deferred by ruling to eg.5/eg.6." The
  recon found eg.5 SHIPPED the first live Rust↔Valkey binding (the recon brief; the echo-graft-fork memory:
  "the FIRST live Rust↔Valkey binding (echo_graft_backend on Valkey :6390)"). *Proposed framing:* if eg.5 indeed
  landed the live socket, update §2 to say the live binding shipped at eg.5 and eg.6 carries the remaining
  cross-compile + shootout — so the dive does not under-state what eg.5 delivered. *(Marked to-verify: the
  Director should confirm eg.5's live-socket status against `graft.roadmap.md` before applying.)*

---

## §What I deliberately did NOT decide (the discipline)

- **Every fork above is SURFACED, not ruled.** The ranked arm is a recommendation with one carrying reason; the
  Operator rules.
- **The D-4 convergence of the two page-engines** — DEFERRED post-eg.6 by the ruling
  (`graft.engine-split.design.md` §7); this lens recommends emq3.5 ride the native engine and leaves
  convergence to the Operator's deferred shootout. NOT pre-decided.
- **The D-5 shootout's outcome** — which engine wins which workload is the deferred per-workload shootout's
  finding (`graft.engine-split.design.md` §7 D-5), not this design's.
- **eg.6's scheduling** — when the deferred eg.6 (cross-compile + CI + shootout) runs, behind the fly.io deploy
  floor, is the Operator's sequencing, not this chapter's.
- **The store.design.md §4 Graft forks** (segment key layout, one-writer-or-many, pull cadence, SigV4) are
  echo_store's open engine forks; emq3.5 CONSUMES the engine as a peer and does not touch them (COEXIST). Out
  of scope.

---

## §Surface citations (NO-INVENT — every named surface grounded)

**Verified as-built (real `module/file:line`):**

- `EchoStore.Graft.VolumeServer.commit/3` — the native fold target, single-writer mailbox write lock
  (`echo/apps/echo_store/lib/echo_store/graft/volume_server.ex:2-8`); `commit/3` at `volume_server.ex:50`,
  OCC-rejecting a stale base (`:129-159`).
- `EchoStore.Graft` facade — `open_volume/2` (`graft.ex:31`), `read/2` (`graft.ex:48`), `read_at/3`
  (`graft.ex:56`), `head_lsn/1` delegated (`graft.ex:40-44`); moduledoc "Native-BEAM Graft… with no foreign
  engine" (`graft.ex:2-4`).
- `EchoStore.Graft.Committer` — the echo_store-side bus-consuming drain ("subscribes to the commit channel,
  re-publishes each commit's names to a work queue at-least-once, persisted frontier"; the SHIPPED bus-consumer
  shape the fold mirrors), per `graft.engine-split.design.md` §3b citing `committer.ex:99-114`.
- `EchoStore.Graft.Sync` — native commit notices on channel `graft:<vol>:commits` (`sync.ex:41`).
- `EchoStore.GraftBackend.commit/5` — the Rust peer's client commit (`graft_backend.ex:122`, `:mode`
  `:sync`|`:async` at `:123`); command lane `egraft:cmd:<vol>` (`graft_backend.ex:59`), feed lane
  `egraft:feed:<vol>` (`graft_backend.ex:63`).
- `EchoMQ.StreamConsumer` — AS-BUILT (emq3.3) — `echo/apps/echo_mq/lib/echo_mq/stream_consumer.ex` (present,
  ~19.7 KB); the consumer surface the echo_store-side fold-consumer (F-ENG-B/B1) reads the stream through.
- Dependency direction — `echo/apps/echo_store/mix.exs:27` (`{:echo_mq, in_umbrella: true}`);
  `echo/apps/echo_mq/mix.exs:30-31` (only `{:echo_data,…}` + `{:echo_wire,…}`, no echo_store edge).

**Forward-tense (surface a rung BUILDS — not yet on disk):**

- The emq3.5 echo_store-side fold-consumer (F-ENG-B/B1 — an `EchoStore.StreamArchive`-shaped process consuming
  `EchoMQ.StreamConsumer` + `EchoStore.Graft.commit/3`). Does not exist.
- The fold-consumer's commit-into-native-engine step (F-ENG-A/A1, over `volume_server.ex:50`).

**Canon / design cited (NOT a code surface):** `docs/graft/graft.engine-split.design.md` (the COEXIST ruling
D-1=A §0/§7, the outbox-vs-page-store sizing §2, the as-built capability map §3, the Option A tradeoffs §5,
the reconciled eg.4 §6 / distinct lanes); `docs/echo_mq/emq.streams.md` (the durable-archive answer naming the
native engine, the emq3.5 ladder row); `docs/echo_mq/kb/streams-tier/streams.synthesis.md` (F3.5-A
fold-before-trim via the native `commit/3` — RULED context); the echo-persistence manuscript Chapter III
(`engines/native-elixir/index.md` the VolumeServer/Reader/Committer topology, `engines/beam-rust-contract/index.md`
the wire-is-the-contract + compositional proof + deferred live socket).
