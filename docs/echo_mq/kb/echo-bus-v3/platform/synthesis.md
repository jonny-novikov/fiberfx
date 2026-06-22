# echo-bus-v3 · Chapter IV (the platform) — Director synthesis of the two-architect debate

> **The Director's job here is to STAGE the disagreement, not average it**
> ([`aaw.architect-approach.md`](../../../../aaw/aaw.architect-approach.md) §The multi-architect debate). Two
> vision-forward architects argued the same platform forks independently — **Lens A** (bus-led,
> [`A-lens.md`](./A-lens.md)) and **Lens B** (persistence-led, [`B-lens.md`](./B-lens.md)), neither reading the
> other. This is the chapter the whole KB turns on. The three judgments stay separate: *the architects argued,
> the Director synthesizes, the Operator rules.* No fork below is decided.

---

## §0 · The result in one line

**Two of four forks CONVERGED — the merge-read watermark (F-PLAT-B) and the vocabulary (F-PLAT-C).** Two forks
DIVERGED — **F-PLAT-A (the spine)** and **F-PLAT-D (the sequencing)** — and they are **one disagreement**: is
the platform's development path read forward from the **bus** (the spine that carries work, with persistence
the floor it stands on) or from the **engine** (the universal substrate, with the bus its first client)? That
single meta-axis — together with the local-store divergences F-LS-B/F-LS-C — **is the reframed development path
the Operator is asked to rule.** It does **not** block emq3.5 (whose entire build surface converged).

---

## §1 · Cross-lens fork ledger (the diff)

| Fork | Lens A (bus-led) | Lens B (persistence-led) | Verdict | Synthesis note |
|---|---|---|---|---|
| **F-PLAT-A** the spine (THE reframe) | **bus-led** — the bus is the spine; persistence is the floor it stands on | **persistence-led** — the engine is the substrate; the bus is its first client | **DIVERGED** (the headline) | A genuine spine-vs-substrate call, both readings grounded — see §3. Both CONCEDE the commit-LSN loop is real and bidirectional. |
| **F-PLAT-B** merge-read watermark `W` | `W` engine-derived scalar (no new bus key); a bus-side key only as a named polyglot addition | `W` derived from the engine's committed frontier; a bus-side key only as a DERIVED cache | **CONVERGED** | `W` is a scalar branded id read from the engine's folded frontier — one authority, no drift; no-gap/no-overlap is a CONSEQUENCE of fold-before-trim + the order theorem. (Re-confirms streams-tier F3.5-B.) A bus-side `emq:{q}:stream:<name>:archived` key is an optional polyglot cache, never the source of truth, cleanup named. |
| **F-PLAT-C** vocabulary coherence | keep DISTINCT — "Echo Bus + Echo Persistence" shipped, "EchoMesh" proposed | keep distinct — development speaks the established vocabulary; EchoMesh stays the proposed senior frame | **CONVERGED** | The two names mark two epistemic states (as-built vs proposed-forward-tense) the NO-INVENT discipline exists to preserve. Unifying under "EchoMesh" would assert a proposed weave as as-built. |
| **F-PLAT-D** development-path sequencing | after the tier (emq3.5→3.6), the **BCS substrate door**; eg.6 deferred-parallel | after the tier, the **v4 commit-log-as-outbox line (ADR-A)** ahead of a deeper BCS push | **DIVERGED** | The sequencing consequence of F-PLAT-A — see §3. Both agree the Stream Tier (emq3.5, emq3.6) is finished first. |

---

## §2 · The convergences — the build-ready decisions

- **The merge-read watermark `W` is engine-derived (F-PLAT-B).** A deep read concatenates segments below `W`
  (in the engine) with the live tail at/above `W` (on the bus); `W` is a **scalar branded id read from the
  engine's folded frontier** (`head_lsn/1` delegated, `graft.ex:40-44`), so the cut cannot drift from what is
  actually durable, and no-gap/no-overlap falls out of **fold-before-trim + the order theorem** — not a second
  invariant. This **re-confirms** the prior streams-tier synthesis (F3.5-B). A bus-side keyspace watermark
  (`emq:{q}:stream:<name>:archived`) is an **optional derived cache** for polyglot deep reads only — written
  after the engine commit, its cleanup named in `obliterate`, never the source of truth.
- **The vocabulary stays distinct (F-PLAT-C).** The development path speaks the **shipped** "Echo Bus + Echo
  Persistence"; **"EchoMesh"** remains the PROPOSED senior whole-picture frame, taught forward-tense. Both
  lenses bind to the program's grounding discipline: naming the shipped platform "EchoMesh" would assert a
  proposed composition as as-built.

---

## §3 · The divergence (staged, not averaged) — the spine meta-axis

F-PLAT-A and F-PLAT-D are the same disagreement (the spine, and what it implies for sequencing). Both lenses
**concede the commit-LSN loop is real and bidirectional** — the engine mints the LSN the bus subscribes from,
*and* the archive fold makes the bus drive the engine's commit. The divergence is which member the
**development path** treats as load-bearing.

### F-PLAT-A — the spine: bus-led or persistence-led?

| | **Lens A — BUS-LED** (bus = spine, persistence = floor) | **Lens B — PERSISTENCE-LED** (engine = substrate, bus = client) |
|---|---|---|
| **The arm** | The development path reads forward from the Stream Tier; the engine is the durable SINK the bus folds into; the next rung is a bus rung (emq3.5). | The durable engine is the universal floor every surface stands on; the bus is one client; development hardens the floor toward ADR-A, and the archive falls out of a floor already there. |
| **Load-bearing reason** | **Transport asymmetry** — both loop edges cross the bus's wire (the commit LSN is *published over EchoMQ*; the fold *reads off the bus*), so the bus is the medium the loop is strung on; and the **live frontier is a bus rung** (emq3.5 NEXT; the engine's eg.6 DEFERRED). | **Three facts converge** — the manuscript teaches it (*"the floor the bus stands on"*; the floor is the threshold, the queue the first thing built on it), the **dependency graph enforces it** (`echo_store → echo_mq`, so the bus structurally cannot own durability), and the **v4 north star realizes it** (ADR-A makes the engine's log the universal substrate). |
| **The cost it accepts** | Reads the loop's *origin* (the engine mints the LSN, is the durability source-of-truth) as subordinate to its *transport* — concedes it must not overclaim the engine away. | Frames the platform's most visible feature (the archive) and its live build frontier (the Stream Tier) as a "client built on" a finished substrate — points at the static member while the bus is the moving one. |
| **Pre-empts** | "The LSN ORIGINATES at the engine, so the engine is the organizing coordinate" → minting a coordinate is not carrying the work; the engine speaks to its readers *through* the bus, and the fold makes the bus *write* the floor. | "The bus is the product every consumer touches" → a lobby is what visitors touch, the foundation is what holds it up; 'first client' is not a demotion (it is *the proof the floor holds*). |

### F-PLAT-D — the sequencing (after the Stream Tier, what's next?)

| | **Lens A — finish the bus tier → the BCS door** | **Lens B — the v4 ADR-A commit-log-as-outbox line** |
|---|---|---|
| **The arm** | emq3.5 (archive) → emq3.6 (time-travel + hydration) → the BCS substrate door (Tables/Coherence as the substrate, the codemojex/echo_bot consumer pivot); eg.6 a deferred-parallel engine track. | After the tier, make the Graft commit log the canonical transactional substrate (ADR-A), subsuming the SQLite journal (ADR-E); the engine becomes the universal floor BCS then deepens on. |
| **Load-bearing reason** | The live frontier is the bus ladder and it traces the manuscript's own Ch. IV arc (Modules 11→12→13→14); eg.6 is deferred behind a deploy floor — keep it off the critical path. | The keystone of the persistence lens and the platform's named, half-built, fully-specced forward direction; the v4 ADR is written and the outbox already half-built (`plugins/graft.ex`). |
| **The cost it accepts** | Leaves the two-engine convergence (D-4) and SQLite's retirement unsequenced — honest, but the floor's own durability evolution waits. | Sequences the BCS door (largely already shipped) after the floor's durability evolution; carries the v4 ADR's named open questions (the retirement timeline, the OCC-retry contract). |
| **Pre-empts** | "Consolidate the engine first" → the floor is settled for the bus's purposes (emq3.5 folds into the native engine alone); eg.6 is deferred, so consolidating first blocks the live frontier on a deploy dependency the ruling itself deferred. | "More bus is the next move" → the Stream Tier seams (object payloads, the log-tier exit) are explicitly PARKED until real large-end demand; the live, named, half-built direction is the v4 outbox line. |

**Director's framing for the ruling (advice, not a decision):** the two lenses are **not in conflict over
emq3.5** — both name it the keystone, and both build it the *same way* (a store-side fold consumer into the
native `commit/3`, F-ENG-A/B + F-LS-A, all converged). The divergence bites only on the trajectory **after**
the tier: bus-led extends toward the BCS door; persistence-led deepens the floor toward ADR-A. A reading the
Operator may prefer that takes the load-bearing half of each: **finish the Stream Tier (emq3.5 → emq3.6) — the
live frontier both lenses agree is next — and let the F-PLAT-A spine ruling set what follows** (the BCS door vs
the v4 ADR-A line), with the SQLite-subsume (F-LS-B) and the watermark-couple (F-LS-C) falling out of that same
ruling. That keeps the moving frontier moving while the Operator decides the spine. **Surfaced for the Operator;
not ruled here.**

---

## §4 · Consensus findings both lenses raised

1. **The commit-LSN loop is real and bidirectional** — both concede it explicitly (the engine mints the LSN
   published over EchoMQ; the fold makes the bus drive the engine's commit). The disagreement is which member
   the *development path* treats as load-bearing, not whether the loop exists.
2. **EchoMesh stays PROPOSED** — both keep the established/proposed vocabulary line the NO-INVENT discipline
   guards; the destination can be the EchoMesh composition while the working vocabulary stays as-built.
3. **`W` is engine-derived** — both reach the streams-tier-confirmed scalar watermark, refusing a second
   source of truth for the archive's extent.

---

## §5 · Consolidated recommended next actions (for Operator ratification)

1. **Rule the spine meta-axis (F-PLAT-A).** This is the reframed-development-path decision the rung exists to
   surface; it sets F-PLAT-D, F-LS-B, and F-LS-C with it (they are the same axis). The Director's framing (§3)
   offers a load-bearing-half reconciliation; the call is the Operator's.
2. **emq3.5 does not wait on the ruling.** Build the archive to the converged surface (F-PLAT-B `W`
   engine-derived; F-ENG-A/B native store-side fold; F-LS-A reserved-range landing); the spine ruling sets only
   what comes *after* emq3.6.
3. **Keep the vocabulary distinct (F-PLAT-C, converged)** — speak "Echo Bus + Echo Persistence" in the
   development path; keep EchoMesh the proposed senior frame.

---

*Director synthesis. The architects argued (Lens A bus-led, Lens B persistence-led); this chapter is the one
the KB turns on. Two forks converged (the watermark, the vocabulary); two diverged into one meta-axis (the
spine and its sequencing) — the reframed development path the Operator rules. emq3.5 is build-ready regardless.*
