# echo-bus-v3 · Chapter II (the local store) — Director synthesis of the two-architect debate

> **The Director's job here is to STAGE the disagreement, not average it**
> ([`aaw.architect-approach.md`](../../../../aaw/aaw.architect-approach.md) §The multi-architect debate). Two
> vision-forward architects argued the same local-store forks independently — **Lens A** (bus-led,
> [`A-lens.md`](./A-lens.md)) and **Lens B** (persistence-led, [`B-lens.md`](./B-lens.md)), neither reading the
> other. This doc consolidates the result for **independent Operator review**. The three judgments stay
> separate: *the architects argued, the Director synthesizes, the Operator rules.* No fork below is decided.

---

## §0 · The result in one line

**One of three forks CONVERGED — the archive's landing representation (F-LS-A), the load-bearing emq3.5
decision.** Two opposite-optimizing lenses independently reached *the same* arm: a trimmed stream slice lands
as a **reserved high-range page index** in CubDB, the shipped `@obx_base` outbox pattern generalized. **Two
forks DIVERGED** — F-LS-B (the SQLite journal's fate) and F-LS-C (retention-watermark coupling) — both on the
**same meta-axis the platform chapter names** (keep right-sized boundaries vs unify onto one durable floor),
and **both are post-emq3.5 / v4-line decisions**, not emq3.5 blockers.

---

## §1 · Cross-lens fork ledger (the diff)

| Fork | Lens A (bus-led) | Lens B (persistence-led) | Verdict | Synthesis note |
|---|---|---|---|---|
| **F-LS-A** archive landing representation | A1 reserved high-range page index (outbox pattern generalized); A2 Volume-per-stream parked as opt-in | A1 reserved high-LSN page range (the floor's proven third tenant); A2 Volume-per-stream for an Operator-declared deep stream | **CONVERGED** | The archive lands as ordinary CubDB pages at a per-stream `@archive_base` disjoint from `@obx_base`, branded-id-monotone, the page payload carrying the id, committed via the public `commit/3`. A2 (a dedicated Graft Volume) is the named opt-in for a few deep/long-lived streams. Build-ready for emq3.5. |
| **F-LS-B** the SQLite journal's fate | keep SQLite as the **default** outbox; the demotion retires only the ARCHIVE role | Graft-as-outbox **subsumes** the journal (the destination, sequenced behind "Graft is the default floor"; `exqlite` retires per ADR-E) | **DIVERGED** | Both agree SQLite stays a rebuildable working set near-term; they split on the long-term destination — see §3. A **v4-line** decision (ADR-A/ADR-E), not an emq3.5 one. |
| **F-LS-C** MVCC/retention watermark coupling | keep the stream MINID window + the CubDB GC watermark **DISTINCT** | **couple** them: derive the archive GC boundary from the stream's MINID (one coordinate, store follows), pin-override preserved | **DIVERGED** | Both agree fold-before-trim + the engine's pin-override carry deep-read correctness; they split on whether to ALSO couple the GC boundary for one-coordinate elegance — see §3. Not load-bearing for emq3.5 correctness. |

---

## §2 · The convergence — the build-ready decision (F-LS-A)

Because the two opposite-optimizing lenses agree, this carries high confidence. Stated as the surface emq3.5
would freeze:

- **The archive lands as a reserved high-range page index.** Each folded slice becomes CubDB pages at a
  per-stream reserved base (`@archive_base`), **disjoint from the outbox's `@obx_base = :erlang.bsl(1, 48)`**
  (`echo/apps/echo_store/lib/echo_store/plugins/graft.ex:46`), the page index **monotone in the entry's
  branded id** (the order theorem makes the range contiguous by construction), the **page payload carrying the
  branded id** for reversible reads. Committed through the public `EchoStore.Graft.VolumeServer.commit/3`
  (`volume_server.ex:50`) — **no engine edit (COEXIST honored)**.
- **Why both lenses landed here:** it reuses a SHIPPED, tested path — the outbox's "a non-page write becomes a
  reserved-range CubDB page, range-scanned above a watermark" (`plugins/graft.ex:83-88,155-161`) — so the fold
  is a thin generalization, the archive inherits the engine's reachability GC for free, and the contiguous
  reserved range is exactly what lets the merge-read partition on a single scalar watermark `W` (platform
  F-PLAT-B).
- **The named opt-in:** A2 (a dedicated Graft Volume per stream, `open_volume/2` at `graft.ex:31`) is the right
  answer for a *few* deep/long-lived streams the Operator marks as isolated — both lenses agree it is an
  additive escalation, **not** the default (it scales the engine's process/Tigris footprint with the *stream
  count*, which is unbounded; the tier's demand is small-per-stream).

---

## §3 · The divergences (staged, not averaged) — the local-store face of the platform meta-axis

Both divergences are the **same disagreement** the platform chapter's F-PLAT-A names, seen at the storage tier:
the bus lens keeps **right-sized boundaries**; the persistence lens **unifies onto the one durable floor**.

### F-LS-B — the SQLite journal's fate

| | **Lens A — keep SQLite the default outbox** | **Lens B — Graft-as-outbox subsumes the journal** |
|---|---|---|
| **The arm** | The demotion retires only the ARCHIVE role; SQLite stays `EchoStore.Durability`'s default `SQLite` adapter for low-volume intents. | `EchoStore.Durability.Graft` becomes the canonical outbox; SQLite survives only as a rebuildable cache; `exqlite` retires on the ADR-E schedule. |
| **Load-bearing reason** | **Right-sizing** — the outbox is low-volume hot-path durability (`durability.ex:6-9`); a full page-store commit "OVER-serves" it (`graft.engine-split.design.md` §2), so keep the small thing on SQLite, the bulk archive on CubDB. | **The v4 north star (ADR-A)** — one durable engine, the founding no-SQL intent restored as fact; the outbox is ALREADY half-built on Graft (`plugins/graft.ex`), the ADR already written. |
| **The cost it accepts** | Two durable local stores coexist (SQLite intents + CubDB archive) — two retention stories an operator carries. | A migration with a real ordering constraint (ADR-E Q4: the retirement timeline); a host mid-adoption would be stranded if forced early. |
| **Pre-empts** | "Two stores is needless duplication" → the duplication is *apparent*; the two serve different-SIZED needs the design separated on purpose. | "Keep SQLite, it works" → "keep forever" is a standing re-promotion of the one SQL dependency the founding docs all name for retirement. |

**Reconcilable core:** both lenses agree SQLite **stays rebuildable near-term** — the Stream Tier does not
perform the retirement, and the canon demotion (`emq.streams.md` "the SQLite journal is demoted to a
rebuildable local working set") already holds. The split is purely the **long-term destination** (coexist
indefinitely vs subsume), which is a **v4 ADR-A/ADR-E decision** sequenced with F-PLAT-D — not emq3.5.

### F-LS-C — MVCC/retention watermark coupling

| | **Lens A — keep the two watermarks DISTINCT** | **Lens B — couple them (archive GC follows the stream MINID)** |
|---|---|---|
| **The arm** | The stream's MINID trim window (bus memory) and the CubDB GC retention watermark (engine version history) are different axes that never share a value. | The archive's local GC boundary is DERIVED from the stream's MINID floor — one coordinate for "where live ends and deep begins," pin-override preserved. |
| **Load-bearing reason** | **The COEXIST boundary** — the engine's GC ("pins + window, never age", `checkout-and-gc.md` §2) is the floor's business; the bus consumes, it does not co-manage. And the GC *structurally cannot* take a single external coordinate (a reader pin must override any watermark). | **The shared-cursor discipline** — the commit LSN is "one number read two ways"; retention should follow, so no-gap/no-overlap is a CONSEQUENCE of one boundary, not a two-GC coordination. |
| **The cost it accepts** | Two retention knobs; a theoretical storage waste (the engine may keep/reclaim out of step with the stream) — but *not a correctness problem* (the merge de-dups by id). | The store's archive GC depends on a value the stream owns (the retention floor) — an intended coupling, but the bus reaches into an engine-internal mechanism. |
| **Pre-empts** | "Follow the shared-cursor principle for retention too" → the LSN works because it is a shared *product* both legitimately read; GC is an engine *internal* a pin must override, so the fold watermark can only be one input, not the sole boundary. | "Coupling makes the floor hostage to a bus policy" → the pin-override bounds it; a retention change can never drop a page a deep reader pins. |

**Reconcilable core:** both lenses agree **fold-before-trim + the engine's pin-override carry deep-read
correctness** (F-PLAT-B's `W` is engine-derived either way). The divergence is whether to ALSO couple the GC
boundary for one-coordinate elegance — an emq3.5 *refinement*, not a correctness requirement. The bus lens's
sharpest point: even C2 cannot be the *sole* GC boundary (pins override), so the "one clean coordinate" is
partial in fact.

**Director's framing for the ruling (advice, not a decision):** F-LS-B is genuinely a **v4-line** decision —
defer it to the F-PLAT-D / ADR-A ruling, where it is the same question. F-LS-C can be ruled at emq3.5's own
threshold (or deferred): since both lenses agree correctness rests on fold-before-trim and the pin-override —
not on the GC coupling — emq3.5 can ship with the watermarks **distinct** (the lower-coupling default) and
adopt the coupling later as an additive optimization if measurement warrants it, with no correctness exposure
either way. **Surfaced for the Operator; not ruled here.**

---

## §4 · Consensus findings both lenses raised

1. **The shipped outbox is the archive's proven seed.** Both lenses independently anchored F-LS-A on
   `EchoStore.Durability.Graft`'s reserved-range pattern (`@obx_base`, `record/4`, `replay/2` above a
   watermark) — the strongest single signal that the reserved-range landing is the right representation.
2. **The engine's pin-override GC is the safety net.** Both treat "a reader pinned at an old LSN keeps its
   roots alive, regardless of any watermark" (`checkout-and-gc.md` §2) as the invariant that makes the archive
   safe under any retention policy.
3. **SQLite stays rebuildable near-term** — both honor the canon demotion; the disagreement is only about the
   long-term destination.

---

## §5 · Consolidated recommended next actions (for Operator ratification)

1. **Build emq3.5's archive landing to F-LS-A (converged):** the reserved high-range page index over the public
   `commit/3`, the page payload carrying the branded id, A2 (per-stream Volume) named as the Operator-declared
   opt-in. No engine edit (COEXIST).
2. **Rule F-LS-B with F-PLAT-D / ADR-A** — the SQLite-subsume destination is the v4-line decision, not an
   emq3.5 one; near-term SQLite stays rebuildable (already canon).
3. **Default F-LS-C to "distinct" for emq3.5** (lower coupling, no correctness exposure); adopt the
   MINID-coupled GC boundary later only as a measured additive optimization, the Operator's call at the rung.

---

*Director synthesis. The architects argued (Lens A bus-led, Lens B persistence-led); this doc staged the one
convergence and the two divergences; the Operator rules. The convergence (F-LS-A) is the build-ready emq3.5
landing; the divergences are the storage face of the platform's spine meta-axis.*
