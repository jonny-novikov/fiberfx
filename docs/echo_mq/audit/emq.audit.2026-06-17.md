# EchoMQ docs audit — reconciliation actionables (2026-06-17)

> **Purpose.** A categorized ledger of staleness found while compacting Movements 0/I, reframing the consumer
> (Exchange → codemoji/echo_bot), and recalibrating the program. The **APPLIED** section records what this run
> changed; the **PROPOSED** sections are **propose-only — for Operator approval before any apply** (each carries a
> BEFORE → AFTER so the change is legible in advance). Nothing in the PROPOSED sections has been touched.
>
> Counts are `grep`-measured against the tree on 2026-06-17 and will drift; re-measure before acting.

## Summary

| # | Category | Scope | Severity | Status |
|---|---|---|---|---|
| — | Compaction (Movements 0/I) | `emq.roadmap.md` · `emq.progress.md` · `program/` | — | ✅ APPLIED |
| — | Consumer reframe (Exchange → codemoji/echo_bot) | the living canon + the calibrations | — | ✅ APPLIED (calibrations) · ⏳ in fan-out (specs) |
| P1 | **CLAUDE.md is stale** (pipeline · echomq · consumer · engine) | `CLAUDE.md` | **HIGH** | 🔲 PROPOSED |
| P2 | `:line` anchor drift (methods-only) | `docs/echo_mq/` (671 living) | MEDIUM | 🔲 PROPOSED |
| P3 | `apps/echomq` removed-path citations | 62 living docs + `echo-mq-surface.md` + `echo-mq-program.md` | MEDIUM | 🔲 PROPOSED |
| P4 | Broken intra-doc links | `emq2/3.specs.md` · `emq.command-registry.md` | MEDIUM | 🔲 PROPOSED |
| P5 | Commit-hash / conformance-count drift | `emq.testing.md` · canon · stories | LOW–MED | 🔲 PROPOSED |
| P6 | Memory staleness (out-of-band) | `~/.claude/.../memory/` | LOW | 🔲 PROPOSED |
| P7 | Spec-body vs `.llms`/`.stories` lag | rung triads | LOW | 🔲 PROPOSED |

---

## ✅ APPLIED this run

- **Compaction.** `emq.roadmap.md` — closed-rung ladder collapsed to 4 cluster rows (no per-sub-rung hashes /
  fork rulings / gate tallies); "Movement 0" → "the foundation (emq.0, established)"; old-ladder table compacted.
  `emq.progress.md` — rewritten: commit hashes stripped, the per-sub-rung ASCII block collapsed to a 3-line
  Movement-I view, conformance corrected (`43/43` → **52/52**), `emq.2.4` corrected (`📐 specced` → ✅).
- **Consumer reframe (calibrations).** The named consumer changed from the Exchange platform to **codemoji**
  (present-tense, real `EchoMQ` + `EchoData.Bcs` consumer) + **echo_bot** (forward-tense, planned Telegram
  notifications) across `emq.roadmap.md`, `emq.progress.md`, `program/emq.{program,venus}.md`,
  `echo-mq-ship/SKILL.md`.
- **Pipeline recalibration (D-1).** Apollo lifted out of the per-rung loop → the standing **Mentor** (calibrates
  agents from the Director's consolidated findings, PROPOSE-ONLY); Venus = strawman author + four-part Arms; the
  Director rules the Arms via the **mandatory `AskUserQuestion`** and verifies code + invariants; story-coverage
  → Mars. Folded into `program/emq.{venus,mars,apollo,program}.md` + `echo-mq-ship/SKILL.md`.
- **Exchange scrub of FROZEN ledgers (D-2).** Records-freeze was overridden by **explicit Operator grant** for
  the Exchange term only — the ship-history (counts, verdicts, dates) is preserved; only "Exchange/trading/TRD"
  consumer references are reframed/neutralized. Executed in the fan-out (see status above).
- **Local fixes.** `apps/echomq` "UNTOUCHED feature reference" boundary claims corrected (echomq is removed);
  broken `emq2.specs.md`/`emq3.specs.md` links in `emq.roadmap.md` + `emq.progress.md` redirected to the design
  canon.

---

## P1 — CLAUDE.md is stale (HIGH — it OVERRIDES, and now contradicts D-1)

`CLAUDE.md` is the governing instruction file; left stale it ships contradictory guidance every session. Four
drifts:

1. **The pipeline (line 55)** still names Apollo a high-risk evaluator / "optional fast-finisher" — contradicts
   D-1 (Apollo = Mentor, out of the loop; the Director verifies).
2. **apps/echomq** described as the live "FROZEN v1 bus deferred to delete" — it is **removed**.
3. **The named consumer** is implied to be Exchange (`exchange`, `investex` out-of-scope pointers frame the
   program around it) — now codemoji/echo_bot.
4. **Engine claim** "Valkey 9 on `:6390`" — verify the major version against the running engine (the program
   docs say "Valkey, current stable line").

> **BEFORE** (CLAUDE.md line 55):
> `→ **Mars-1** (build…) → **Director** solo review (…) → **Mars-2** (…) → **Director** ship (…). **Apollo** (`echo-mq-evaluator`) is **mandatory only on a high-risk rung** … on a normal rung it is an optional fast-finisher (closure + stories).`
>
> **AFTER** (proposed):
> `→ **Mars** (build + self-verify + stories) → **Director** verify (code + invariants) → **Mars-2** (remediate + harden) → **Director** ship + consolidate findings. **Apollo** is the standing **Mentor** — out of the per-rung loop; it folds the Director's consolidated findings into agent calibrations (PROPOSE-ONLY). Every design Arm is ruled by the Director with the Operator via the mandatory `AskUserQuestion`.`

**Recommended:** apply P1 next — it is the one stale doc that actively contradicts a just-ruled decision.

---

## P2 — `:line` anchor drift (methods-only)

**671** `file:line` anchors (`*.ex/exs/lua:NNN`) across living `docs/echo_mq/` (611 more in frozen ledgers —
leave those: history). AAW churns line numbers every rung, so each anchor is a latent lie. The roadmap +
progress already moved to methods-only; the rung triads + feature slices have not.

> **BEFORE** (e.g. `emq.commands/features/index.txt`):
> `EchoMQ.Jobs.enqueue/4 (@enqueue, jobs.ex:14)`
>
> **AFTER** (proposed):
> `EchoMQ.Jobs.enqueue/4 (@enqueue)` — method + script attr only; re-probe the tree for the line.

**Recommended scope:** a sweep over `docs/echo_mq/specs/**` (excluding `specs/progress/`), strip `:NNN`,
keep the module/function/script-attr. Mechanical + verifiable (`grep -c` before/after).

---

## P3 — `apps/echomq` removed-path citations

`apps/echomq` is **removed**, yet **62** living `docs/echo_mq` files (non-frozen) still cite it, and two team
docs describe it as live:

- `.claude/skills/echo-mq-surface.md` — an entire section **"`echo/apps/echomq/lib/` — the FROZEN feature
  reference"** maps a deleted tree (25 `.ex` + 26 `.lua` named for porting).
- `.claude/skills/echo-mq-program.md` — one `apps/echomq` reference.

> **BEFORE** (`echo-mq-surface.md`):
> `## `echo/apps/echomq/lib/` — the FROZEN feature reference — REFERENCE ONLY` … (the v1 capability list)
>
> **AFTER** (proposed):
> Drop the section (the parity port is complete + the line removed); the v1→v2 parity record lives in
> `docs/echo_mq/emq.features.md` + the command registry. Replace inbound citations with "the v1→v2 parity
> catalog" pointer.

**Recommended scope:** update the two team skills first (they're loaded every rung); then a living-docs sweep
turning "ported from `apps/echomq`" into the past-tense "rewritten fresh into `echo_mq`, the line removed".

---

## P4 — Broken intra-doc links

- `emq2.specs.md` / `emq3.specs.md` — **do not exist anywhere**; referenced as "the line/tier specifications."
  (Fixed in `emq.roadmap.md` + `emq.progress.md` this run; check `emq.design.md` / `emq.references.md` /
  `echo_mq.md` for the same.)
- `emq.command-registry.md` — CLAUDE.md cites it at the program root; the real file is
  `epics/emq.epic.1/emq.commands.registry.md` (note the plural `commands`).

> **BEFORE** (CLAUDE.md): `emq.command-registry.md — the v1→v3 command matrix sorted by the 12-feature taxonomy`
>
> **AFTER** (proposed): `epics/emq.epic.1/emq.commands.registry.md` (the matrix) + `specs/emq.commands/llms.txt`
> (the flat agent index)

**Recommended scope:** a markdown-link checker over `docs/echo_mq/**` on a stable tree (the reorg-link-rebase
lesson: run a reproducible full sweep, don't enumerate by eye).

---

## P5 — Commit-hash / conformance-count drift

- **Hashes in living canon:** ~7 hex tokens in `emq.design.md`/`emq.features.md`/`emq.references.md` (the
  compaction policy: ship detail lives in frozen ledgers + git, not the living canon).
- **Stale conformance counts:** `emq.testing.md` and `specs/emq.3/emq.3.rungs/emq.3.4.stories.md` carry pre-close
  numbers (`43/43`, `18 as-built`); the live count is **52/52** (Movement I closed).

> **BEFORE** (`emq.testing.md`): `…conformance 43/43…`   **AFTER** (proposed): `…conformance 52/52 (Movement I closed)…`

**Recommended scope:** re-pin every living-doc conformance figure to 52; strip canon hashes (keep a single
git-show recovery pointer where one documents how to recover trimmed content).

---

## P6 — Memory staleness (out-of-band, `~/.claude/.../memory/`)

The auto-memory still encodes the pre-pivot world: `echomq-umbrella-app` ("apps/echomq = the v1 bus FROZEN…"
— removed), `echo-mq-three-movements` (Apollo = "fast finisher"; Exchange the consumer), and the Exchange/redis
notes naming the Exchange platform the consumer. Out of this run's file scope; flagged so the next memory pass
re-trues them to: echomq removed · Apollo = Mentor · consumers codemoji (live) + echo_bot (planned).

---

## P7 — Spec-body vs `.llms`/`.stories` lag

Per the program law the `<rung>.md` **body** is authoritative; the `.llms.md` brief + `.stories.md` can lag. A
lag-1 reconcile of the emq.2/emq.3 triads' `.llms`/`.stories` against their bodies (and against the as-built
surface) is the standard hygiene pass — bundle it with the P2 methods-only sweep since both touch the same files.

---

## How to action this report

Each P-item is independently approvable. Suggested order by value: **P1** (contradiction, apply now) → **P3**
(team skills loaded every rung) → **P4** (broken links) → **P2 + P7** (one combined specs sweep) → **P5**
(figures) → **P6** (memory). Each, when approved, is a scoped change verifiable by a before/after `grep -c`.
