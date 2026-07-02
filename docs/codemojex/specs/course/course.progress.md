# Codemojex — the course · Progress

```text
CODEMOJEX · /codemojex                                       pages 10 / 37 shipped (landing + 9 stubs)

  landing  /codemojex                        ████████████████████████  built A+   ✓
  C0  overview                               ████░░░░░░░░░░░░░░░░░░░░  stub       ◐   dives ○○○
  C1  branded-systems                        ████░░░░░░░░░░░░░░░░░░░░  stub       ◐   dives ○○○
  C2  rooms-and-modes                        ████░░░░░░░░░░░░░░░░░░░░  stub       ◐   dives ○○○
  C3  guesses-on-fair-lanes                  ████░░░░░░░░░░░░░░░░░░░░  stub       ◐   dives ○○○
  C4  scoring-and-settlement                 ████░░░░░░░░░░░░░░░░░░░░  stub       ◐   dives ○○○
  C5  the-economy                            ████░░░░░░░░░░░░░░░░░░░░  stub       ◐   dives ○○○
  C6  commerce                               ████░░░░░░░░░░░░░░░░░░░░  stub       ◐   dives ○○○
  C7  the-live-surface                       ████░░░░░░░░░░░░░░░░░░░░  stub       ◐   dives ○○○
  C8  production                             ████░░░░░░░░░░░░░░░░░░░░  stub       ◐   dives ○○○

  COURSE   █████░░░░░░░░░░░░░░░░░░░░░░░░░░░  10 / 37 pages shipped   (1 built + 9 stubs; 27 dives planned)
```

Legend — **✓ built** · gated `STATUS: PASS`, full content — **◐ stub** · gated `STATUS: PASS` real
shell (identity + thesis + dive gists), content authoring planned — **○ planned** · route named in the
TOC, page not yet on disk.

## Now building

- **Scaffold rung (2026-07-02)** — the course canon (this directory, 13 files), the canon reconcile
  (tiers→linear closed · Golden-Room tense to as-built · the `/bcs/codemojex/**` → `/codemojex`
  re-home), the landing + nine stubs in the CMX Telegram-blue calibration, and the `/bcs/codemojex`
  door section. Verification transcript appended below when the gates run.

## Verification transcripts

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
