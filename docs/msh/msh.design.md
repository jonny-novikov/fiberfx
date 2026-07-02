# msh — the design (the hot-context engine)

> The BINDING canon of the forward msh program, consolidated 2026-07-02 from the genesis debate — the lens
> pair [A · Steward](./kb/genesis/msh.design.A-steward-lens.md) / [B · Steelman](./kb/genesis/msh.design.B-steelman-lens.md),
> staged in the [Director synthesis](./kb/genesis/msh.synthesis.md), ruled on the run ledger
> ([msh-genesis](./specs/progress/msh-genesis.progress.md), D-1..D-12). The delivery ladder is
> [msh.roadmap.md](./msh.roadmap.md); read [msh.references.md](./msh.references.md) before expanding either.
> **As-built baseline:** [docs/go/msh/msh.design.md](../go/msh/msh.design.md) — the frozen reverse-mode
> record of the shipped Phase-1 toolchain; this document governs forward work.

## §1 · The product

A Claude agent opens a rung and **one call returns the precise, budgeted, cited context pack it needs** —
memory notes ranked by a real scorer, the active program's spec sections carried in, session-history
pointers attached — replacing fat always-loaded context (the full `MEMORY.md` index + hand navigation)
with tool-served, per-rung context whose cost is chosen (`token_budget`) and whose contents are accountable
(every line cited, every drop named). The consumer is an agent under a token budget, not a person at a
shell (lens B §0); the engine must therefore be **deterministic, auditable, and read-only** (lens A §0).

Three tool families deliver it, all additive over the shipped eight (D-2):

1. **`memory_search`** `{query, project?, type?, limit?}` → ranked, cited rows over the scorer — the
   retrieval primitive, usable product alone.
2. **`memory_context`** `{project?, rung?, role?, task?, token_budget}` → THE pack, a budgeted fold over
   search; unset args default from the live anchor. Registered also as the MCP **prompt** (one assembly).
3. **The docs join** — after ingestion (D-6), packs carry a `§docs` section: the rung's roadmap row + the
   design sections it links.

## §2 · The architecture

```
memory/ (flat, git-tracked, 3-key schema v2)          docs/<prog>/ trees (speclint-v2-conformant)
        \                                                 /
         ── the walker · frontmatter · linkx · typed graph ──        [shipped: go/msh/memory/*]
                          |
                the corpus SNAPSHOT                                   [msh2.4: {size,mtime}+SHA re-stat;
                          |                                            every read via the snapshot API]
                     the Scorer seam                                  [msh2.3: BM25F + type/recency +
                          |                                            staleness demotion + graph proximity]
                    the pack assembler                                [msh2.5: budget fold · section-capable
                          |                                            truncation · path#heading · §budget]
        MCP surface: tools + the prompt (:8899)                       [additive rows in buildMCPServer]
```

- **The store is the index.** `memory/` stays flat; scope is the `project:` frontmatter key; organic
  subdirs remain human convenience (D-ruled convergence, F1). No persistent index beside the files — the
  snapshot is a verified in-process mirror, never an authority (D-7).
- **Scoring is deterministic.** The lexical composite is v1 behind a `Scorer` interface; golden-rank
  fixtures pin the order (ties broken by path). The dormant Hugot/Similarity config
  (`go/msh/memory/internal/config/defaults.go:38-46`) keeps its seam: a hybrid implementation is
  deferred-standing behind a named evidence gate (a day-one miss-log demonstrating a lexical miss-class,
  and a live :8902).
- **The pack is a fold, not a source.** `memory_context` composes search × budget × dedupe × citations; a
  pack bug is diagnosable by its parts because the parts are tools (F5 convergence).
- **Docs join by ingestion, not by artifact.** Multi-root loading (root-tagged nodes, per-root invariant
  fences) lands only after the snapshot (D-7) and after speclint-v2 makes the trees reliable (D-6). No
  generated per-program content index; nothing new named `*.registry.json`.
- **History joins by pointer.** Every pack citation carries its note's `originSessionId` + a prepared
  `history_search` invocation; the budgeted snippet tier (≤10%, RAN/CAPPED/DEGRADED declared) ships only on
  pointer-unfollowed evidence (D-11).

## §3 · The contracts

- **Tool surface** (all additive; the registered count is pinned in a test and re-pinned per addition):
  the shipped eight — `memory_scan/graph/stale/audit`, `memory_project`, `mint`, `specs`, `history_search`
  — plus `memory_search` (msh2.3) and `memory_context` + the prompt (msh2.5). No tool is renamed, removed,
  or narrowed.
- **Frontmatter schema v2** (D-8): contract keys `project` (scoping), `status` (declared supersession — the
  1KB body sniff demotes to fallback via the shipped coalesce precedent), `review_after` (consumed day-one
  by a new review-due stale rule). `tags` is NOT contract. Key arity + unset-key degrade order are settled
  in the msh2.2 triad (Seam S-2).
- **Anchor schema v1.1** (D-5): `.msh-memory.json` gains `docs_root` additively; ONE canonical config-marker
  spelling (legacy spellings read through a deprecation window); the anchor remains hand-edited — msh
  writes nothing.
- **The pack contract** (D-9, both lenses' shared instinct): `memory_context`'s output schema is the
  program's largest freeze liability and is authored as a **contract set** (the architect-approach's second
  instrument) with the msh2.5 triad, reconciled against the implementation and real call sites before it
  pins. Sections: `§project · §memory · §docs (post-msh2.7) · §history · §budget`; `§budget` accounts
  requested/spent/dropped with every drop named.
- **Citations:** `path#heading`, resolving against the live tree (speclint re-used as the gate).

## §4 · The invariants (load-bearing; violating any is a defect, not a style choice)

1. **Read-only.** The toolchain writes nothing — not the corpus, not `MEMORY.md`, not the anchor, not the
   docs trees. A corpus change is a staged, Operator-reviewed rung (byte-diffed backfill), never a shipped
   msh write path (D-5, D-8).
2. **One authority.** The files are the only store. The snapshot is derived + discardable; a re-stat
   precedes every read. No disk index, no generated content index, no generated MEMORY.md replacement — a
   generated COMPANION view may ship, and the hand index retires only on an evidence ruling (F2
   convergence).
3. **Determinism.** Same corpus + same query → byte-identical ranking and pack; golden-rank and golden-pack
   fixtures gate it; ties break by path.
4. **Additive-minor evolution.** MCP tools only grow; the count pin moves in the same change that adds a
   tool (the aaw selftest discipline).
5. **Budget accountability.** A pack never exceeds `token_budget`; silent truncation and silent omission
   are gate failures (`§budget` declares drops; `§history` declares RAN/CAPPED/DEGRADED once snippets ship).
6. **Scope fences.** Build rungs edit `go/msh` only; msh2.2's backfill is the one scoped `memory/` edit;
   M4's rungs (go/aaw, docs/aaw + the skills sweep) open only on their movement-open rulings (S-4, S-5).
7. **The live server is never killed.** `make mcp` hot-swap + client `/mcp` reconnect; gates run
   `GOWORK=off`.

## §5 · The rulings (the genesis decision record)

| D | Fork | Ruling (2026-07-02) |
|---|---|---|
| D-1 | run scope | genesis + msh2.1 in one run; M1+ ship rung-per-run |
| D-2 | product | MCP context-pack tools + prompt; no generated brief files |
| D-3 | formation | ledgered trio + Mars at build rungs; Apollo absorbed for design (D-7 x-mode exception) |
| D-4 | namespace | forward rungs are msh2.N; msh.0–6/P2/FX stay the frozen reverse record |
| D-5 | F7 anchor | read-only minimal msh2.1; write-back/multi-project on the worktree trigger |
| D-6 | F6 docs | ingestion IN: shape rules → multi-root; no index artifact |
| D-7 | F4 cache | snapshot scheduled BEFORE ingestion; disk index never; 0.36s baseline recorded |
| D-8 | F2 schema | 3-key {project, status, review_after} + day-one review-due rule; tags deferred |
| D-9 | F5a granularity | section-capable; heading-boundary truncation only |
| D-10 | F5b role | caller param v1; served-table default on the D-12 trigger |
| D-11 | F9 history | pointers + prepared invocation; snippet tier evidence-gated |
| D-12 | F8 M4 | server-data-first; tools-then-docs; census→1 the exit gate |

Full arms + CHOSEN-AGAINST reasoning: the [synthesis](./kb/genesis/msh.synthesis.md) §3/§5 and the ledger's
decisions channel.

## §6 · References

The lens pair + synthesis + grounding pack under [`kb/genesis/`](./kb/genesis/genesis.grounding.md) · the
ladder [msh.roadmap.md](./msh.roadmap.md) · the operating manual
[program/msh.program.md](./program/msh.program.md) · the as-built record [docs/go/msh](../go/msh/msh.design.md)
(frozen) · the method [aaw.architect-approach](../aaw/aaw.architect-approach.md) · the triad contract
[aaw.specs-approach](../aaw/aaw.specs-approach.md).
