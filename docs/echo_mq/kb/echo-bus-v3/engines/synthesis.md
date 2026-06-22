# echo-bus-v3 · Chapter III (the engines) — Director synthesis of the two-architect debate

> **The Director's job here is to STAGE the disagreement, not average it**
> ([`aaw.architect-approach.md`](../../../../aaw/aaw.architect-approach.md) §The multi-architect debate). Two
> vision-forward architects argued the same engine forks independently — **Lens A** (bus-led,
> [`A-lens.md`](./A-lens.md)) and **Lens B** (persistence-led, [`B-lens.md`](./B-lens.md)), neither reading the
> other. The three judgments stay separate: *the architects argued, the Director synthesizes, the Operator
> rules.* No fork below is decided.

---

## §0 · The result in one line

**All three engine forks CONVERGED — the emq3.5 engine surface is fully ruled by the agreement.** Two
opposite-optimizing lenses independently reached the same arm on every engine question: the fold targets the
**native `EchoStore.Graft`** engine via its public `commit/3`; the **fold-consumer lives store-side** (the
`echo_store → echo_mq` dependency direction forces it); the **native engine carries emq3.5 alone**, the Rust
peer a deferred evidence-gated track. The only difference is a **framing nuance** on F-ENG-B (whose surface the
fold consumer "belongs to") that is the engines reflection of the platform's F-PLAT-A spine divergence — not a
substance disagreement.

---

## §1 · Cross-lens fork ledger (the diff)

| Fork | Lens A (bus-led) | Lens B (persistence-led) | Verdict | Synthesis note |
|---|---|---|---|---|
| **F-ENG-A** which engine the bus folds into | native `EchoStore.Graft` via `commit/3` | native `EchoStore.Graft` (the canonical floor; the archive its consequence) | **CONVERGED** | The fold commits to the native engine's public `EchoStore.Graft.VolumeServer.commit/3` (`volume_server.ex:50`) — COEXIST-canonical, in-process. The Rust `echo_graft_backend` is rejected for emq3.5 (it contradicts COEXIST-canonical and ties the keystone to the DEFERRED eg.6 deploy floor). |
| **F-ENG-B** fold-consumer placement | a store-side `StreamConsumer`-shaped consumer (the dependency direction forces store-side; the native `Committer` proves the shape) | a store-side fold `StreamConsumer` (the store reaches UP — the FEATURE); avoid the injected-callback that puts the no-loss invariant inside the bus | **CONVERGED** (framing nuance) | Both place the consumer **store-side**, both reject an injected bus-side callback. They differ only on the *ownership story* (a bus citizen living store-side vs the store reaching up) — the engines reflection of F-PLAT-A; staged there, not a substance split. |
| **F-ENG-C** eg.6 deferral + forward engine path | native engine ALONE for emq3.5; Rust the peer; convergence is the deferred D-4 call | native alone for emq3.5; forward = native → the ADR-A substrate; Rust a deferred evidence-gated peer | **CONVERGED** | emq3.5 rides the native engine alone; the two-engine convergence (D-4) stays deferred post-eg.6 / post-shootout (`graft.engine-split.design.md` §7). Neither lens fuses the deferred horizon decision into the rung. |

---

## §2 · The convergences — the build-ready engine decision set

Because the two opposite-optimizing lenses agree on every engine fork, these carry the highest confidence in
the KB. Stated as the surface emq3.5 would freeze:

- **The engine is the native `EchoStore.Graft`** (F-ENG-A). The fold commits trimmed slices through the public
  `EchoStore.Graft.VolumeServer.commit/3` (`volume_server.ex:50`, OCC single-writer mailbox) — the
  COEXIST-canonical, in-process engine, **UNTOUCHED** (the fold is a *consume-the-facade* act, not an engine
  edit). The Rust `echo_graft_backend` (`EchoStore.GraftBackend.commit/5`, lanes `egraft:cmd`/`egraft:feed`) is
  the coexisting peer, **not** the emq3.5 target.
- **The fold-consumer lives store-side** (F-ENG-B). The dependency direction is load-bearing: `echo_store`
  depends on `echo_mq`, so **`echo_mq` cannot call `echo_store`** — the fold must be an `echo_store`-side (or
  host-side) consumer that *reads* trimmed slices off the bus and *writes* them into the engine. The as-built
  `EchoStore.Graft.Committer` (which already consumes bus notices and drains to the engine) proves the shape.
  **Both lenses reject** an injected bus-side callback that would place the no-loss invariant inside `echo_mq`,
  which cannot verify it.
- **The native engine carries emq3.5 alone; the Rust track is deferred** (F-ENG-C). emq3.5 does not wait on the
  two-engine convergence: eg.6 (cross-compile + CI + the per-workload shootout) is **DEFERRED** behind a fly.io
  EchoMQ deploy floor (`graft.roadmap.md`; `graft.engine-split.design.md` §7), and the D-4 convergence ruling
  is parked for that shootout's evidence. The archive folds into the native engine, which is shipped and ready.

---

## §3 · The divergence (a framing nuance, not a substance split) — F-ENG-B's ownership story

There is **no substance divergence** in this chapter — both lenses chose the same engine, the same placement,
and the same deferral. The one difference is narrative, and it is the engines reflection of the platform's
F-PLAT-A spine fork:

| | **Lens A — the fold consumer is a BUS citizen, living store-side** | **Lens B — the fold consumer is the STORE reaching up (the feature)** |
|---|---|---|
| **The story** | The fold consumer is a Stream-Tier consumer that happens to run store-side because the dependency graph forces it; the bus reaches *down* into the floor. | The store reaches *up* to the bus to ingest what it must persist; the dependency direction (`echo_store → echo_mq`) is a feature — the store owns durability. |
| **What both agree** | Store-side placement; the native `Committer` shape; reject the injected bus-side callback; the native engine UNTOUCHED. | (identical) |

**Director's framing:** because the *code* is identical (a store-side consumer over `commit/3`), this nuance
does not affect the emq3.5 build at all — it is purely which spine narrative the development path adopts, which
is exactly the **F-PLAT-A** ruling. Staged there; no engine decision turns on it.

---

## §4 · Consensus findings both lenses raised

1. **The Rust engine is the wrong target for emq3.5** — both reject it on the same two grounds (COEXIST names
   the native engine canonical; eg.6 is deferred behind a deploy floor the archive must not wait on).
2. **The dependency direction is the architecture, not an obstacle** — both derive store-side placement from
   `echo_store → echo_mq` and cite the as-built `Committer` as the proven shape.
3. **The native engine stays UNTOUCHED** — both treat the fold as a consume-the-public-facade act (`commit/3`),
   honoring COEXIST D-1=A literally; no fork proposes an engine edit.

---

## §5 · Consolidated recommended next actions (for Operator ratification)

1. **Build emq3.5's fold consumer store-side over the native `commit/3` (converged across all three forks).** A
   `Committer`-shaped `echo_store`-side (or host-side) consumer; no injected bus-side callback; the native
   engine UNTOUCHED.
2. **Keep the engine-consolidation track (eg.6 / D-4) deferred** — the archive does not wait on the shootout;
   the Rust peer's convergence is ruled later, on its evidence and its deploy floor.
3. **Carry the F-ENG-B ownership-story nuance into the F-PLAT-A ruling** — it is a narrative consequence of the
   spine decision, not an independent engine choice.

---

*Director synthesis. The architects argued (Lens A bus-led, Lens B persistence-led); on the engines they
converged completely — the strongest agreement in the KB — fixing the emq3.5 engine surface. The Operator
rules the one framing nuance with the platform's spine fork.*
