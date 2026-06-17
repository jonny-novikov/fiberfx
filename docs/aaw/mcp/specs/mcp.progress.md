# aaw MCP server v2 · build progress (live dashboard)

> The ladder's **implementation dashboard** — one glanceable view of how far each rung mcp1–mcp8 has
> moved from plan to shipped code, updated in real time at every stage transition. This is *how much
> is done*; the run ledger [`../aaw.mcp.progress.md`](../aaw.mcp.progress.md) is *what was decided and
> found* (append-only, server-written), the roadmap [`../aaw.mcp.roadmap.md`](../aaw.mcp.roadmap.md)
> is *what ships, in what order, and why*, and the chapter index [`mcp.md`](mcp.md) maps the triads.
> Maintained by the Director at each stage transition, alongside the index and roadmap status lines.

## Legend

```
✓ shipped      ◐ in flight (specced or build-grade or built)      ○ planned (roadmap row only)

A rung advances through four stages, each worth 6 of its 24 bar cells:
  specced      triad authored (mcpN.md + .stories.md + .llms.md), six gates green        →  6 cells
  build-grade  triad reconciled against the as-built tree; build GO standing             → 12 cells
  built        increment in the tree; rung gate + selftest green                         → 18 cells
  shipped      rung closed: Operator commit + ledger close entry (D-11 minimum met)      → 24 cells

Ladder % = stage points ÷ 32 (8 rungs × 4 stages). The bars are counted, not estimated.
```

## Ladder rollup

```
mcp1  Single-writer store discipline      ✓  ████████████████████████  shipped      7972859f (settled tier)
mcp2  Attribution, liveness & status      ✓  ████████████████████████  shipped      f44f0539 · 514d4768 (18 tools)
mcp3  Error vocabulary + §8 grammar       ✓  ████████████████████████  shipped      750bda97 (standard tier; 2nd context CLEAN; close P-9)
mcp4  Config, ports & the wire contract   ◐  ████████████░░░░░░░░░░░░  build-grade  Venus-mcp4 grounding reconcile vs 750bda97; GO ratified D-18
mcp5  The Reconcile tool                  ◐  ██████░░░░░░░░░░░░░░░░░░  specced      aaw reconcile CLI, zero tool-surface change; ratified D-16
mcp6  Message channels                    ○  ░░░░░░░░░░░░░░░░░░░░░░░░  planned      the MEASUREMENT rung (21 tools): its authoring runs server-coordinated; close records the productivity tally
mcp7  Resonance, archival & audit CLI     ○  ░░░░░░░░░░░░░░░░░░░░░░░░  planned      roadmap row (22-tool surface)
mcp8  Transport, conformance + cutover    ○  ░░░░░░░░░░░░░░░░░░░░░░░░  planned      absorbs the transport posture + C-1 probe (D-14 · D-16)
──────────────────────────────────────────────────────────────────────────────────
LADDER (mcp1–mcp8)                        ◐  ███████████░░░░░░░░░░░░░   47%         (15 / 32 stage points)
```

*Milestones (the roadmap's grouping): **M1 · The floor** (mcp1–mcp2) is complete. **M2 · The contract**
(mcp3–mcp5) is the frontier — mcp3 stands at built, mcp4 and mcp5 at specced; mcp5 was promoted
by the Operator on 2026-06-11 to **the Reconcile tool** (`aaw reconcile`, deterministic spec↔tree
drift; ratified D-16), and the displaced transport posture + C-1 probe ride mcp8, zero renumbering.
**M3 · The 22-tool surface** (mcp6–mcp7) and **M4 · The proof** (mcp8) follow.*

## Per-rung detail

```
✓ mcp1  specced → build-grade → built → shipped   commit 7972859f · settled tier · goldens are the regression floor
✓ mcp2  specced → build-grade → built → shipped   commits f44f0539 · 514d4768 · the model field landed early here
✓ mcp3  specced → build-grade → built → shipped   commit 750bda97 · standard tier complete: Mars build → Mars-mcp3-2
                                                  second context (independent DoD re-run, CLEAN, zero changes) →
                                                  Director gate green → close P-9; live :8905 still serves the 17-tool
                                                  pre-MCP1 binary until the Operator restarts from HEAD
◐ mcp4  specced → build-grade                     Venus-mcp4 grounding reconcile vs HEAD 750bda97 (D-18): all drift was
                                                  mcp3-diff line shifts, re-pinned; emission route locked (render via
                                                  internal/gates constants, the lock.go:44 way); build order AS1→AS5,
                                                  F-2 held-or-granted · next stage: built (one Mars, standard tier,
                                                  after the Venus-5 two-audience framing pass lands)
◐ mcp5  specced                                   the Reconcile tool: aaw reconcile CLI — claim grammar, read-only tree
                                                  probe, MATCH/STALE/MISSING deltas, gate-able exit codes (D1–D5,
                                                  INV1–INV5; ratified D-16) · next stage: build-grade
○ mcp6  —                                         depends on mcp2 (polling touches liveness); the ladder's productivity
                                                  gauge — its own authoring formation runs on the upfront instruments
                                                  (mcp1–mcp5) and the close entry records the tally (the roadmap's
                                                  "value measurement" section)
○ mcp7  —                                         completes the 22-tool surface
○ mcp8  —                                         settles the transport posture (the C-1 probe is the cutover gate);
                                                  proves the ladder; cuts over (the D-14 symlink seam was defused by
                                                  D-15 — the slug name is the real file, the dotted name the alias)
```

## How to maintain this file

At each stage transition, update three things together (or the views drift):

1. **The rung row** — advance its stage label; redraw the bar (`stage × 6` filled `█` cells of 24).
2. **The ladder rollup** — recount stage points ÷ 32; redraw the 24-cell rollup bar
   (`round(pct ÷ 100 × 24)` filled cells); flip `○`→`◐`→`✓`.
3. **The status lines elsewhere** — the index ([`mcp.md`](mcp.md)) value-ladder Status column and the
   roadmap status line say the same thing in words; the run ledger records the transition's evidence
   (the close entry, the commit, the reconcile verdict).

This dashboard is the quantitative companion to the run ledger: the ledger records *that and why* a
transition happened; this file counts *how many have*. Stage definitions are fixed by the legend —
a rung never advances on intention, only on the named artifact (triad on disk · reconcile verdict ·
green gate · close entry).

---

> Part of the AAW program. The index maps, the roadmap plans, the design defines, the triads prove,
> the ledger records — this file counts.
