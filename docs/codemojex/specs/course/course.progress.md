# Codemojex — the course · Progress

```text
CODEMOJEX · /codemojex                                 pages 17 / 37 shipped (landing · C0–C1 complete · 7 stubs)

  landing  /codemojex          ████████████████████████  built A+  ✓
  C0  overview                 ████████████████████████  built A+  ✓  dives ●●●
  C1  branded-systems          ████████████████████████  built A+  ✓  dives ●●●
  C2  rooms-and-modes          ████░░░░░░░░░░░░░░░░░░░░  stub      ◐  dives ○○○
  C3  guesses-on-fair-lanes    ████░░░░░░░░░░░░░░░░░░░░  stub      ◐  dives ○○○
  C4  scoring-and-settlement   ████░░░░░░░░░░░░░░░░░░░░  stub      ◐  dives ○○○
  C5  the-economy              ████░░░░░░░░░░░░░░░░░░░░  stub      ◐  dives ○○○
  C6  commerce                 ████░░░░░░░░░░░░░░░░░░░░  stub      ◐  dives ○○○
  C7  the-live-surface         ████░░░░░░░░░░░░░░░░░░░░  stub      ◐  dives ○○○
  C8  production               ████░░░░░░░░░░░░░░░░░░░░  stub      ◐  dives ○○○

  COURSE   █████████████░░░░░░░░░░░░░░░░░  17 / 37 pages shipped   (landing + C0–C1 · 7 hubs stub; 21 dives planned)
```

Legend — **✓ built** · gated `STATUS: PASS`, full content — **◐ stub** · gated `STATUS: PASS` real
shell (identity + thesis + dive gists), content authoring planned — **○ planned** · route named in the
TOC, page not yet on disk. A dive row shows **●** for a built dive, **○** for a planned one.

## Now building

- **C1 authoring rung (2026-07-02)** — the `branded-systems` chapter deepened from stub → hub (the
  brand × tier matrix — four namespaces × three storage tiers — grounded in design §Identity +
  `Codemojex.Tables`/`View`) plus its three dives — `branded-ids-are-the-keys` (the id anatomy + the
  fifteen-namespace roster) · `the-four-layers` (the stack + a durable-vs-derived sorter + the
  supervision tree) · `the-privacy-boundary` (the read inspector + the classic/golden gate + the
  privacy stories). Authored via **`/codemojex-write branded-systems`**; the fan-out `codemojex-expert`
  subagents went idle-on-spawn without writing any file (two dispatch cycles), so the orchestrator
  self-authored all three dives from the pre-read Step-0 grounding (the recover-from-tree fallback),
  md-first. C1 is the **second complete chapter** (hub + 3 dives, all A+).
- **C0 authoring rung (2026-07-02)** — the `overview` chapter deepened from stub → hub (the
  mode-as-policy matrix, grounded verbatim in `Codemojex.Rooms.policies_for/2`) plus its three dives
  — `the-game-and-the-family` · `the-engine-and-its-policies` · `the-architecture-at-a-glance` —
  authored via **`/codemojex-write overview`** (the fan-out: three `codemojex-expert` agents, each
  pre-grounded, md-first). C0 is the **first complete chapter** (hub + 3 dives, all A+). The
  `/codemojex-write` + `/codemojex-reconcile` suite (command pair + `codemojex-expert` agent +
  `codemojex-course-writer` skill) shipped with this rung.
- **Scaffold rung (2026-07-02)** — the course canon (this directory, 13 files), the canon reconcile
  (tiers→linear closed · Golden-Room tense to as-built · the `/bcs/codemojex/**` → `/codemojex`
  re-home), the landing + nine stubs in the CMX Telegram-blue calibration, and the `/bcs/codemojex`
  door section.

## Verification transcripts

**C1 authoring rung (2026-07-02) — all green.**

- `cms check --require-refs` (mounts: /codemojex /bcs /echomq /redis-patterns /mesh /echo-persistence)
  over the C1 hub + three dives: **4 × `grade: A+` / `STATUS: PASS`**, all ten gates; the landing
  re-gated **A+** after the C1 card chip flip (planned → built).
- The `:root` token block is **md5-identical** across the hub and all three dives (`b5ac2b7f…`) and
  matches the C0 canonical — the CMX identity held byte-for-byte. Identity greps (font-leak ·
  external-asset · `--b-`) each empty; **four unique `CMX…` stamps** (`…SOX/SOY/SOZ/SOa`).
- Grounding: every `Codemojex.*` / `EchoData.*` / `EchoStore.*` / `EchoMQ.*` token resolves on disk
  (including the nested `EchoStore.Directory` in `echo_store.ex`); the C1.1 roster-vs-live-mint
  distinction (13 live `generate!` sites · `CMD` folds onto a `JOB` id · `WHK` forward) verified against
  `grep`; the `EchoData.BrandedId` doctest (`encode!`/`parse`/`hash32`) and `revealed?/1` quoted
  verbatim; scoring untouched (linear-only — no tier/bonus language, confirmed by grep).
- All inline scripts parse (`node --check`, both blocks on all four pages). Figure validator
  (`mcp/e2e/figures.suite.js`, `file://`, headless): **11 PASS · 0 FAIL** — no horizontal overflow,
  every SVG label fits across all seven figures.
- One `degrade`-gate false-positive fixed: the gate's naive `.reveal` substring match tripped on
  `Codemojex.View.revealed?/1`; reworded to `Codemojex.View` · `revealed?/1` (no reveal animation exists).

**C0 authoring rung (2026-07-02) — all green.**

- `cms check --require-refs` (mounts: /codemojex /bcs /echomq /redis-patterns /mesh /echo-persistence)
  over the C0 hub + three dives: **4 × `grade: A+` / `STATUS: PASS`**, all ten gates.
- The `:root` token block is **md5-identical** across the hub and all three dives (`b5ac2b7f…`) —
  the CMX identity held byte-for-byte through the parallel fan-out. Identity greps (font-leak ·
  external-asset · `--b-`) each empty; **four unique `CMX…` stamps** (`…HN/HO/HP/HQ`).
- Grounding: all **fifteen** cited `Codemojex.*` names resolve to real defmodules on disk;
  figure-provenance spot-checked (`Rooms.policies_for/2` return maps · `EmojiSet.@code_length 6`)
  verbatim; scoring stays linear (no tier/bonus language).
- All inline scripts parse (`node --check`). Figure validator (`mcp/e2e/figures.suite.js`, `file://`,
  headless): **11 PASS · 0 FAIL** — no horizontal overflow, every SVG label fits.

**Scaffold rung (2026-07-02) — all green.**

- `cms check --require-refs` (mounts: /codemojex /bcs /echomq /redis-patterns /mesh /echo-persistence)
  over the ten `/codemojex` pages + the edited `/bcs/codemojex`: **11 × `grade: A+` / `STATUS: PASS`**,
  zero FAIL lines.
- Identity greps, each empty: font leaks · external assets (`<link |<script src|fetch(`) · `--b-`
  residue (the `--c-*` calibration is total). **Ten unique `CMX…` stamps**, one per page.
- Shell consistency: the nine chapter stubs share a byte-identical `<style>` block.
- Serve sweep (`go/echo-static` on `:1330`): all eleven routes **200**.
- Figure validator (`mcp/e2e/figures.suite.js`, headless): **20 PASS · 0 FAIL** — no horizontal
  overflow, every SVG label fits, on all ten pages.
