# msh — the delivery roadmap (the forward ladder)

> The forward msh program: the hot-context engine + prompt builder for Claude agents, over the `memory/`
> corpus and the `docs/` program trees. Consolidated 2026-07-02 from the genesis lens debate
> ([synthesis](./kb/genesis/msh.synthesis.md)) under the Operator rulings D-1..D-12; the binding design is
> [`./msh.design.md`](./msh.design.md); the dashboard is [`./msh.progress.md`](./msh.progress.md); the
> operating manual is [`./program/msh.program.md`](./program/msh.program.md). The as-built Phase-1 record is
> [docs/go/msh](../go/msh/msh.roadmap.md) (frozen reverse-mode; rung ids `msh.0–msh.6` belong to it — this
> ladder numbers forward rungs **msh2.N**, D-4).

Read [`./msh.references.md`](./msh.references.md) before expanding this roadmap.

## The program

**One Go module — `go/msh` — serving precise, budgeted, cited per-rung context as MCP tools; every rung
ships product the Operator uses that day.**

- **Why.** Agents load fat always-on context (the full MEMORY.md index + hand navigation) while the corpus,
  the specs, and the transcripts already hold the right context — unranked, unbudgeted, unassembled.
- **What.** The msh2 ladder below: anchor integrity → schema v2 → ranked search → the snapshot → THE pack →
  the docs pattern + ingestion → the aaw routing authority.
- **Who.** The Operator owns rulings and fences; Claude agents consume the tools at rung-open; the ship
  skills consume the M4 routing authority.
- **When.** msh2.1 builds in the genesis run (D-1); each following rung ships in its own run.
- **Where.** Code `go/msh` (M4: `go/aaw`); canon here; triads under `./specs/`; ledgers under
  `./specs/progress/`.

## The msh2 ladder

Rung entry law: **Goal · Boundary · Type · Gates (the type ladder in [program/msh.program.md](./program/msh.program.md) + rung extras) ·
SHIPS = what the Operator uses that day · Status.** `[FENCE]` = an explicit Operator allowance at the named
moment.

| Rung | M | Type | Goal | Boundary | SHIPS (usable that day) | Status |
|---|---|---|---|---|---|---|
| **msh2.1** | M1 | go-code | anchor integrity: ONE canonical config-marker spelling (legacy spellings read through a deprecation window — the three-way wart dies) + anchor schema v1.1 additive `docs_root` + docstring sync; read-only preserved (D-5) | `go/msh` | honest root resolution from any directory; `memory_project` reports `docs_root` | 📋 **this run** (D-1) |
| **msh2.2** | M1 | go-code + memory-data | frontmatter v2 `{project, status, review_after}` (D-8): scoped `memory_scan/stale` (`project` filter), `status` retires the supersession sniff (demoted to fallback), NEW review-due stale rule (the day-one consumer); the 69-note backfill as a staged, byte-diffed sub-rung **[FENCE: the one scoped `memory/` mass edit — S-4]** | `go/msh` + `memory/` | scoped scans; declared supersession; review-due findings; an honestly-keyed corpus | 📋 |
| **msh2.3** | M2 | go-code | `memory_search` v1: the `Scorer` seam + the deterministic lexical composite (BM25F over name/description/body + type/recency weights + staleness demotion + graph proximity from seeds) + the miss-log armed; golden-rank fixtures; tool pin 8→9 | `go/msh` | ranked, cited recall — the grep-the-corpus ritual retired; the miss-log starts collecting Hugot/tags evidence | 📋 |
| **msh2.4** | M2 | go-code | the corpus snapshot: in-process `{size, mtime}` re-stat with the SHA256 backstop; the snapshot-API invariant (every read through it); latency gate vs the recorded 0.36s baseline (D-7) | `go/msh` | ms-latency on every tool; the load-bearing substrate for multi-root ingestion | 📋 |
| **msh2.5** | M2 | go-code | `memory_context` + the MCP prompt (one assembly, D-2): budgeted fold over search · section-capable truncation at heading boundaries (D-9) · anchor defaults · `path#heading` citations · `§budget` accounting · `§history` pointers + prepared invocation (D-11) · `role` param (D-10); the pack schema authored as a CONTRACT SET with the triad; tool pin 9→10 | `go/msh` | **THE product** — the one-call rung-open pack, tool and prompt | 📋 |
| **msh2.6** | M3 | go-code + docs | speclint v2 shape rules: the program artifact set · triad naming · ledger placement, as `Finding`s with `file:line`; `docs/msh/` gated as the first conforming exemplar | `go/msh` + `docs/msh` | the normalized docs pattern lintable over any `docs/<prog>`; drift = findings, not archaeology | 📋 |
| **msh2.7** | M3 | go-code | multi-root ingestion (D-6): the loader goes root→roots; docs nodes root-tagged, memory-only invariants fenced per root; packs gain `§docs` (the rung's roadmap row + linked design §§); golden-pack fixtures re-pinned; latency re-measured | `go/msh` | rung packs carry the rung's spec sections — the program-context engine complete | 📋 |
| **msh2.8** | M3 | go-code | the generated MEMORY **companion** view (never writes `MEMORY.md`): the derived index rendered beside the hand one + a divergence report | `go/msh` | the evidence for the index's future — retirement stays an Operator ruling | 📋 optional |
| **msh2.9** | M4 | aaw-server | the routing surface (D-12): aaw serves routing/formation query tools (additive fold toward the specced mcp7 set; selftest pin re-pinned in the same change) **[FENCE: `go/aaw` — S-5, ruled at M4-open]** | `go/aaw` | one QUERYABLE routing authority; arms the D-10 role-default trigger | 🔒 M4 |
| **msh2.10** | M4 | docs | docs/aaw rewrite-to-pointers: short, mcp-tools-forward, citing the served table; the restatement census → 1 (the exit gate); the five ship skills + CLAUDE.md pointers swept; the duplicate `mcp/` progress file deduped; the stranded D-7/D-8 x-mode corrections folded **[FENCE: `docs/aaw` + `.claude` sweep — S-5]** | `docs/aaw` + `.claude` | agent-fast aaw docs; one routing authority end to end | 🔒 M4 |

**Movements.** M0 = the genesis (this run: the canon you are reading, gated by `msh specs msh`) · **M1 the
trustworthy substrate** (2.1–2.2) · **M2 the engine** (2.3–2.5; the product lands at 2.5) · **M3 the docs
joins** (2.6–2.8) · **M4 the aaw authority** (2.9–2.10, server-data-first, tools-then-docs).

## Seams & open decisions

- **S-1 · Hugot placement** — the hybrid `Scorer` is **deferred-standing** (triggers: a live :8902 AND a
  miss-log-demonstrated lexical miss-class), not a scheduled rung; the Operator may promote it to the ladder
  tail at any gate. The evidence bar itself is converged (both lenses).
- **S-2 · Key arity + degrade** — scalar vs list-valued `project:`; unset-key degrade order
  (containing-directory name, then unscoped). Settled in the msh2.2 triad.
- **S-3 · Prompt timing** — the prompt registers WITH msh2.5 (one assembly, D-2); reopening splits it to its
  own rung (lens B's arm) if the pack rung runs heavy.
- **S-4 · The backfill fence** — msh2.2's `memory/` mass edit is pre-announced here and re-confirmed at
  M1-open: staged script, backup, byte-diff review, `msh memory audit` clean before and after.
- **S-5 · The M4 fences** — `go/aaw` (msh2.9) and `docs/aaw` + the `.claude` skills sweep (msh2.10) are
  outside every fence until the M4-open ruling names them.

## The deferred-standing set (named triggers, never scheduled)

| Deferred surface | The named trigger |
|---|---|
| Hugot hybrid scorer (S-1) | :8902 live + a measured lexical miss-class |
| multi-project anchor + `memory_project set` (D-5) | real worktree parallelism |
| the budgeted history snippet tier ≤10% (D-11) | the miss-log shows pack pointers going unfollowed |
| `role` default from the served routing table (D-10) | msh2.9 ships |
| the `tags` contract key (D-8) | a miss-log-demonstrated synonymy class |
| retiring the hand-curated `MEMORY.md` (F2) | the msh2.8 companion's divergence evidence + a ruling |

---

Design: [msh.design.md](./msh.design.md) · Dashboard: [msh.progress.md](./msh.progress.md) · Manual:
[program/msh.program.md](./program/msh.program.md) · Genesis record: [kb/genesis](./kb/genesis/msh.synthesis.md) ·
Ledger: [specs/progress/msh-genesis.progress.md](./specs/progress/msh-genesis.progress.md)
