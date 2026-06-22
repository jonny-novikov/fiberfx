# Echo Bus v3 — Director consolidation (cross-chapter rollup + ADR matrix + the reframed development path)

> **The Director's job is to STAGE the disagreement, not average it**
> ([`aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) §The multi-architect debate). Two
> vision-forward architects — **Lens A** bus-led, **Lens B** persistence-led — argued the same ten forks across
> three chapters (local-store · engines · platform), independently, neither reading the other. This rollup
> consolidates all three chapter syntheses into one picture: the convergence map, the ADR matrix (extending the
> `emq.design.md` decision set, never duplicating it), the **reframed development path**, the docs-vs-specs
> inconsistencies, and the `docs/echo-persistence/` reconciliation changeset. *The architects argued, the
> Director synthesizes, the Operator rules.* No fork is decided here.

---

## §0 · The result in one line

**Ten forks → six CONVERGED, four DIVERGED.** The two opposite-optimizing lenses independently reached the same
arm on every fork that **emq3.5's build touches** — so **emq3.5 is fully build-ready on the convergences
alone**. The four divergences collapse onto **one meta-axis** — *bus-as-spine (keep right-sized boundaries,
finish the frontier) vs engine-as-substrate (unify onto one durable floor, deepen toward ADR-A)* — and that
axis **is the reframed development path** the Operator is asked to rule (§3). It does **not** block emq3.5.

---

## §1 · The cross-chapter convergence map (all ten forks)

| Fork                                            | Chapter     | Lens A (bus-led) | Lens B (persistence-led)                                | Verdict         |
|-------------------------------------------------|-------------|---|---------------------------------------------------------|-----------------|
| **F-LS-A** archive landing representation       | local-store | reserved high-range page index (outbox pattern) | reserved high-LSN page range (the floor's 3rd tenant)   | **CONVERGED**   |
| **F-LS-B** SQLite journal's fate                | local-store | keep SQLite the **default** outbox | Graft-as-outbox **subsumes** it (ADR-E)                 | **DIVERGED**    |
| **F-LS-C** retention-watermark coupling         | local-store | keep the two watermarks **distinct** | **couple** (archive GC follows stream MINID)            | **DIVERGED**    |
| **F-ENG-A** which engine the bus folds into     | engines     | native `EchoStore.Graft` via `commit/3` | native `EchoStore.Graft`                                | **CONVERGED**   |
| **F-ENG-B** fold-consumer placement             | engines     | store-side (bus citizen) | store-side (the store reaches up)                       | **CONVERGED**   |
| **F-ENG-C** eg.6 deferral + forward engine path | engines     | native alone; Rust deferred peer | native alone; Rust deferred peer                        | **CONVERGED**   |
| **F-PLAT-A** the spine (THE reframe)            | platform    | **bus-led** (bus spine, persistence floor) | **persistence-led** (engine substrate, bus client)      | **DIVERGED**    |
| **F-PLAT-B** merge-read watermark `W`           | platform    | engine-derived scalar | engine-derived scalar                                   | **CONVERGED**   |
| **F-PLAT-C** vocabulary coherence               | platform    | keep "platform" | keep "platform"                                         | **CONVERGED**   |
| **F-PLAT-D** development-path sequencing        | platform    | finish tier → BCS door | the v4 ADR-A line                                       | **DIVERGED**    |

**The shape:** the six convergences (F-LS-A, F-ENG-A/B/C, F-PLAT-B/C) cover the archive's representation, its
engine, its consumer placement, its merge-read, and the vocabulary — the whole emq3.5 build surface plus the
naming discipline. The four divergences (F-PLAT-A, F-PLAT-D, F-LS-B, F-LS-C) are one disagreement wearing four
hats: the **spine** (F-PLAT-A) drives the **sequencing** (F-PLAT-D), which is the **SQLite-subsume** decision
(F-LS-B) and the **watermark-couple** decision (F-LS-C). Bus-led keeps boundaries and finishes the frontier;
persistence-led unifies onto the floor and deepens it.

---

## §2 · The emq3.5 build-ready decision set (the six convergences)

Stated as the surface emq3.5 would freeze — high confidence, because two opposite-optimizing lenses reached
each independently:

1. **The archive lands as a reserved high-range page index** (F-LS-A) — CubDB pages at a per-stream
   `@archive_base` disjoint from the outbox's `@obx_base = :erlang.bsl(1, 48)`
   (`echo/apps/echo_store/lib/echo_store/plugins/graft.ex:46`), branded-id-monotone (contiguous by the order
   theorem), the page payload carrying the branded id. A2 (a per-stream Graft Volume) is the named opt-in for a
   few deep streams.
2. **The fold targets the native `EchoStore.Graft`** (F-ENG-A) — committed through the public
   `EchoStore.Graft.VolumeServer.commit/3` (`volume_server.ex:50`); COEXIST-canonical, in-process, UNTOUCHED;
   the Rust `echo_graft_backend` is the coexisting peer, not the target.
3. **The fold-consumer lives store-side** (F-ENG-B) — forced by `echo_store → echo_mq` (the bus cannot call the
   store); a `Committer`-shaped `echo_store`-side (or host-side) consumer reads trimmed slices off the bus and
   writes them into the engine. No injected bus-side callback (the no-loss invariant must not live where the
   bus cannot verify it).
4. **The native engine carries emq3.5 alone; eg.6 / D-4 stay deferred** (F-ENG-C) — the archive does not wait
   on the per-workload shootout or the fly.io deploy floor.
5. **The merge-read watermark `W` is an engine-derived scalar** (F-PLAT-B) — a branded id read from the
   engine's folded frontier (`head_lsn/1`, `graft.ex:40-44`); no-gap/no-overlap is a consequence of
   fold-before-trim + the order theorem; a bus-side `emq:{q}:stream:<name>:archived` key only as an optional
   polyglot cache (cleanup named), never the source of truth. (Re-confirms streams-tier F3.5-B.)
6. **The vocabulary stays distinct** (F-PLAT-C) — the development path speaks the shipped "Echo Bus + Echo
   Persistence"; "EchoMesh" stays the PROPOSED senior frame, taught forward-tense.

**Consequence:** emq3.5 can enter its spec-triad build now on these six, regardless of how the Operator rules
the meta-axis below.

---

## §3 · The reframed development path (the one meta-axis — staged, not ruled)

The four divergences are **one decision**: which member of the real, bidirectional commit-LSN loop the
development path treats as **load-bearing**. Both lenses concede the loop (the engine mints the LSN the bus
subscribes from; the archive fold makes the bus drive the engine's commit). The reframe is which one *leads*.

**The shared spine (both paths agree):** finish the Stream Tier — **emq3.5** (the archive, the keystone) →
**emq3.6** (time-travel + Table hydration) — built the *same way* (a store-side fold consumer into the native
`commit/3`, merge-read on `W`). The paths only fork on what comes *after* emq3.6:

### Path A — bus-led ("finish the frontier, then the door")
- **emq3.5** archive → **emq3.6** time-travel/hydration → **the BCS substrate door** (Tables / Coherence as the
  substrate for BCS systems; the codemojex-live / echo_bot-planned consumer pivot).
- **eg.6** (cross-compile + the per-workload shootout) is a **deferred parallel** engine track behind the
  fly.io floor; ruling the D-4 convergence when its evidence lands.
- SQLite stays the **default outbox** (right-sized); the stream MINID window and the CubDB GC watermark stay
  **distinct**.
- *Load-bearing reason:* the live frontier is a bus rung; both loop edges cross the bus's wire; this traces the
  manuscript's own Chapter IV arc (Modules 11 → 14).

### Path B — persistence-led ("deepen the floor toward the north star")
- **emq3.5** archive → **emq3.6** time-travel/hydration → **the v4 commit-log-as-outbox line (ADR-A)**: make
  the Graft commit log the canonical transactional substrate, **subsume** the SQLite journal (ADR-E), restore
  the founding no-SQL intent as fact → then a deeper BCS push.
- The archive GC boundary is **derived from the stream's MINID** (one retention coordinate).
- *Load-bearing reason:* the manuscript teaches the engine as the floor every surface stands on, the dependency
  graph enforces it (`echo_store → echo_mq`), and the v4 ADR-A (already written, the outbox already half-built
  at `plugins/graft.ex`) realizes it.

**Director's framing for the ruling (advice, not a decision):** the two paths share emq3.5 + emq3.6 entirely,
so **the moving frontier can keep moving while the Operator decides the spine.** A reconciliation that takes the
load-bearing half of each: **ship the Stream Tier completion (emq3.5 → emq3.6) — the convergent near-term — and
let the F-PLAT-A spine ruling set the post-tier fork** (the BCS door vs the v4 ADR-A line), with F-LS-B
(SQLite's fate) and F-LS-C (the watermark coupling) falling out of that same ruling (they are the same axis).
The reframed development path is therefore: **[converged near-term] emq3.5 → emq3.6, then [the spine ruling]
either the BCS door (A) or the v4 ADR-A line (B).** **Surfaced for the Operator; not ruled here.**

> **Ruled (D-2 → §8):** the spine (EBV3-7) and the sequencing (EBV3-8) are **deferred** — finish emq3.5 →
> emq3.6 first; the durability **destination** (EBV3-9 → Graft-canonical; SQLite a thin pluggable adapter, out
> of scope) and the watermark (EBV3-10 → distinct for emq3.5) were ruled now. The near-term is unchanged; the
> post-tier fork (the BCS door vs the v4 ADR-A line) awaits the spine.

---

## §4 · The ADR matrix (new decisions — extending the `emq.design.md` set, not duplicating it)

Each row is a decision this consolidation surfaces. The **Extends / relates-to** column anchors it on an
existing locked decision so the matrix references rather than re-invents (`emq.design.md` S-1..S-7, §2/§3/§5/§12
ADRs, §10 DQ-1..DQ-4; the streams-tier F3.5-A/B; the engine-split COEXIST D-1; the v4 ADR-A/E).

| ADR | Question | Chapter | Chosen / staged | Extends / relates-to | Status |
|---|---|---|---|---|---|
| **EBV3-1** | How does a trimmed slice land in CubDB? | local-store | reserved high-range page index (`@archive_base` disjoint from `@obx_base`), payload carries the id | S-6 (declared keys / reserved ranges); streams-tier **F3.5-A** | **CONVERGED** → build emq3.5 |
| **EBV3-2** | Which engine does the fold target? | engines | native `EchoStore.Graft` via public `commit/3` | engine-split **COEXIST D-1=A**; streams-tier F3.5-A | **CONVERGED** |
| **EBV3-3** | Where does the fold-consumer live? | engines | store-side (or host-side); no injected bus callback | the `echo_store → echo_mq` dependency law (`echo/CLAUDE.md` §1) | **CONVERGED** |
| **EBV3-4** | Does emq3.5 wait on engine consolidation? | engines | no — native alone; eg.6 / D-4 deferred | graft.engine-split **D-4** / eg.6 deferral | **CONVERGED** |
| **EBV3-5** | Where does the merge-read watermark `W` live? | platform | engine-derived scalar; bus-side key only as a polyglot cache | streams-tier **F3.5-B**; the subkey-cleanup law | **CONVERGED** |
| **EBV3-6** | "platform" or "EchoMesh" vocabulary? | platform | keep distinct (shipped vs PROPOSED) | S-5 (grounding / eradication); the NO-INVENT / forward-tense discipline | **CONVERGED** |
| **EBV3-7** | The spine: bus-led or persistence-led? | platform | **DEFERRED** (D-2) — finish emq3.5→3.6 first; storage-axis annotation: "Graft = Primary Target, SQLite pluggable/out-of-scope" | the whole-picture frame (mesh.8.1); the dependency law | **DEFERRED** → spine sets post-tier |
| **EBV3-8** | Post-tier sequencing: BCS door or v4 ADR-A? | platform | **DEFERRED** (D-2) — tied to EBV3-7 | emq.roadmap §Seams (the deferred 2.x runway); v4 **ADR-A** | **DEFERRED** → follows EBV3-7 |
| **EBV3-9** | SQLite's fate: keep default or subsume? | local-store | **RULED → Graft-canonical** (D-2) — default production durability is robust Graft; SQLite a thin pluggable adapter, out of scope | v4 **ADR-A / ADR-E** | **RULED** (D-2) |
| **EBV3-10** | Couple the archive GC to the stream MINID? | local-store | **RULED → distinct for emq3.5** (D-2); MINID-coupled GC a later measured additive optimization | the commit-LSN shared-cursor; S-6 | **RULED** (D-2) |

---

## §5 · Inconsistencies found (docs-vs-specs / docs-vs-as-built)

Both lenses, reconciling the manuscript and the canon against the as-built tree, surfaced the same set:

1. **eg.6 is DEFERRED, not "next."** `graft.roadmap.md` / `graft.progress.md` show eg.6 deferred behind a
   fly.io EchoMQ deploy floor; the live frontier is the bus rung emq3.5. The manuscript's shootout/Rust pages
   frame eg.6 as the next measured rung. → manuscript edit (§6).
2. **The emq3.5 fold call-site is NAMED but UNSPECIFIED.** No spec states the page-index scheme or the
   merge-read; that gap is exactly this KB's F-LS-A / F-PLAT-B (now resolved on paper). → resolved by this KB.
3. **`emq.streams.md`'s ladder table still labels shipped rungs "PROPOSED."** Line 66's header reads "Ships
   (PROPOSED)" though the file's own status line (line 4) says emq3.1–3.4 SHIPPED. → **bus-canon sync,
   Operator's call** (not applied by this phase — §6).
4. **Manuscript internal status drift.** `platform/bus-and-persistence/index.md` calls Module 14 "(soon)"; 
   `engines/beam-rust-contract/index.md` calls its three dives "(soon)" — all are `status: established`. →
   manuscript edit (§6).
5. **emq3.4 (retention) is SHIPPED and F3.4-A is RULED** (the named/opt-in `EchoMQ.StreamRetention` driver),
   but the Stream-Tier manuscript pages teach retention forward-tense and F3.4-A as an open fork. → manuscript
   edit (§6).
6. **The live Rust↔Valkey socket landed at eg.5** (the first live binding on `:6390`); `beam-rust-contract`
   describing it "deferred to eg.5/eg.6" reads stale. → manuscript edit (§6, verify-on-apply).
7. **OpenDAL attribution (NOT an error to fix).** The manuscript correctly attributes OpenDAL to the *Rust*
   engine; the native engine uses its own `EchoStore.Tigris` client — the manuscript is right (a stale Claude
   memory note had it backwards). No edit.
8. **"Litestream replacement" residue** survives in `echo_store` `streamer.ex` moduledoc after Shadow/Litestream
   were retired — NOTE only (it lives in code, outside the manuscript and this design's edit scope).

---

## §6 · The `docs/echo-persistence/` reconciliation changeset (Director applies surgically)

Each edit is named here before it is applied; all are surgical factual reconciliations + forward-framing inside
existing pages, preserving the course voice / design / front-matter (no structural rewrite).

**Apply (lens-independent factual reconciliations):**
- **`platform/bus-and-persistence/index.md`** — drop the `_(soon)_` on the Module 14 pointer (target is
  `status: established`).
- **`engines/beam-rust-contract/index.md`** — drop the `_(soon)_` on Dives 10.1–10.3 (all `status:
  established`, eg.4 SHIPPED); reconcile the "live socket deferred to eg.5/eg.6" line to "eg.5 shipped the first
  live binding" (verify against `graft.roadmap.md` on apply).
- **`overview/the-durability-spectrum.md` · `foundations/durability-spectrum/{index,the-shootout-and-the-knob}.md`
  · `engines/rust/index.md`** — reframe eg.6 as DEFERRED (behind the fly.io EchoMQ deploy floor); the live
  frontier is emq3.5; the Champ+Graft shootout numbers stay "pending eg.6" but eg.6 is deferred, not next.
- **`platform/echomq-bus/the-stream-tier-ladder.md`** — mark emq3.1–3.4 SHIPPED, emq3.5 NEXT (match the as-built
  ladder).
- **`platform/echomq-bus/retention-and-the-never-deleted-problem.md`** — reconcile F3.4-A to RULED (the
  named/opt-in `EchoMQ.StreamRetention` driver shipped at emq3.4); add a sentence that the archive's *landing
  representation* (the page-index scheme) is the open emq3.5 design question (forward link to this KB).

**Apply (converged forward-framing):**
- **`local-store/replay-and-recovery/index.md`** — name the emq3.5 archive fold's recovery as the same
  `replay(from_lsn, apply_fn)` from the archive watermark (the fold joins the three replays, not a fourth
  subsystem). Forward-tense.
- **`local-store/cubdb/index.md`** — note the page axis is MULTIPLEXED (business pages + the outbox's
  `@obx_base` range + the archive's reserved range), GC indifferent to which range.
- **`platform/bus-and-persistence/the-loop-closes.md`** — one line that `W` is DERIVED from the engine's
  committed frontier (the engine owns its extent).
- **`local-store/mvcc-time-travel/checkout-and-gc.md`** — note the platform has two retention watermarks (the
  engine's version-history GC + the Stream Tier's trim window), coupled *only* by fold-then-trim (the converged
  correctness statement; neutral on the F-LS-C coupling fork).
- **`engines/native-elixir/the-commit-log-outbox.md`** — if it overstates the Graft-outbox's role, clarify the
  shipped `SQLite`/`Memory` adapters are the DEFAULT and the Graft commit-log is the BYO option (verify the dive
  body on apply, per realization-over-literal).

**Stage (the unruled spine — present both, do not resolve):**
- **`platform/the-door-to-bcs/index.md`** — add a balancing clause: the bus is not merely "the first thing
  built on the floor" but a co-equal loop member and the platform's live development frontier — so the
  substrate framing does not silently resolve the spine (F-PLAT-A) the Operator has yet to rule; point at this
  KB.

**Recommend (bus-canon sync — NOT applied by this phase; the Operator/Director rules the canon edit):**
- **`emq.streams.md`** ladder table — reconcile the per-row "Ships (PROPOSED)" status to SHIPPED for emq3.1–3.4
  (agrees with the file's own status line).

---

## §7 · What stays open (the Operator's — surfaced, not decided)

- **The spine meta-axis (EBV3-7) + post-tier sequencing (EBV3-8)** — **DEFERRED** (D-2): finish emq3.5 → emq3.6
  first; the spine sets the post-tier fork (the BCS door vs the v4 ADR-A line). EBV3-9 (SQLite → Graft-canonical)
  and EBV3-10 (watermark → distinct) were ruled independently (D-2 / §8) and are no longer open.
- **The `echomq:3.0.0` cutover ratification** — DEFERRED (declared when the tier is whole; the
  defer-the-fence-cutover pattern); never auto-claimed by a rung.
- **The D-4 engine convergence + the per-workload shootout (eg.6)** — deferred behind the fly.io deploy floor.
- **The v4 ADR's named open questions** — the `exqlite` retirement timeline (ADR-E Q4), the OCC-retry contract
  (ADR-A/G Q2), the single-volume guarantee (ADR-F Q3) — carried unchanged into a Path-B ruling.
- **The parked tier seams** — object payloads on streams, the log-tier exit, exactly-once — carried unchanged
  from [`emq.streams.md`](../../emq.streams.md) §Seams.

---

## §8 · Operator rulings (D-2 — post-consolidation)

The Operator ruled the four diverged forks (via `AskUserQuestion`, recorded as **D-2** in
[`echo-bus-v3.progress.md`](../../specs/progress/echo-bus-v3.progress.md)). Two deferred, two ruled — and the
axis proved **separable** (the durability destination ruled ahead of the spine):

| ADR | Fork | Ruling | Note |
|---|---|---|---|
| **EBV3-7** | the spine | **DEFERRED** | Finish emq3.5 → emq3.6 to the converged surface first; the spine ruling sets what follows. Storage-axis annotation: *"Graft = Primary Target. SQLite is a thin pluggable replacement, out of scope."* |
| **EBV3-8** | post-tier sequencing | **DEFERRED** | Tied to EBV3-7 — the BCS door vs the v4 ADR-A line follows the spine. |
| **EBV3-9** | SQLite's fate | **RULED → Graft-canonical** | The default production durability is robust Graft; SQLite is a thin pluggable adapter, **out of scope** (swappable, not hard-retired; neither the default nor worked further). Path B's storage destination, ruled ahead of the spine. |
| **EBV3-10** | watermark coupling | **RULED → distinct for emq3.5** | Lower coupling, no correctness exposure; the MINID-coupled GC boundary is a later measured additive optimization. |

**The separability result:** D-1 framed the four as "one axis — rule the spine, the rest fall out." The Operator
showed the durability **destination** (EBV3-9: Graft-canonical) is rulable **ahead of** the spine **narrative**
(EBV3-7) and the post-tier **sequencing** (EBV3-8) — three forks stayed spine-coupled, the storage destination
did not.

**emq3.5 is unblocked and reinforced:** the six convergences are the build surface; EBV3-10 fixes the watermark
distinct; EBV3-9 confirms the native `EchoStore.Graft` (already the converged F-ENG-A fold target) is the
production-default durability. The build enters its spec triad green. The §6 `the-commit-log-outbox.md`
manuscript item inverts accordingly (Graft the production default, SQLite the pluggable / out-of-scope adapter).

---

*Director consolidation. The architects argued (Lens A bus-led, Lens B persistence-led); this rollup staged the
six convergences (the build-ready emq3.5 surface) and the one meta-axis (the reframed development path); the
Operator rules. Convergence is confidence; the meta-axis is the signal.*
