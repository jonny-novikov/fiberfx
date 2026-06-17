---
name: elixir-references-bibliography
description: "How the /elixir per-module reference bibliography is generated (REFS dict -> kb md -> page insert), the stale-source bug class the cms gates can't catch, and the deterministic repair pattern"
metadata:
  node_type: memory
  type: project
  originSessionId: 73b81fc7-ffef-4d6d-ac38-349cafb4dda9
---

The elixir course's per-module **References** sections are bibliography-driven. Single source of truth: the `REFS` dict in `docs/elixir/kb/_gen_refs_md.py` (keyed by module id, e.g. `"F5.05": [(title, url, note), ...]`; the `.py` keeps ASCII source via `—` escapes that Python evaluates to em-dashes).

**Pipeline (two stages, per `docs/elixir/references/watch_refs.sh`):**
1. `( cd docs/elixir/kb && python3 _gen_refs_md.py )` → writes **`docs/elixir/kb/elixir-references.md`** — the canonical bibliography the references-insert reads (watch_refs.sh line 104: "sourced from docs/elixir/kb/elixir-references.md").
2. `( cd docs/elixir/references && python3 fetch_refs.py )` → downloads each URL into `references/files/` and writes `manifest.json` + `INDEX.md`. **Its HTTP status doubles as a URL liveness check** (`--force` re-fetches all; bare run only fetches new URLs). NOTE: `alistair.cockburn.us/hexagonal-architecture/` returns `000` from curl = **expired TLS cert on the origin** (real, ongoing), not a dead page — it is course-canonical (cited by served `pragmatic/architecture.html` + `boundaries/index.html`); keep it.
The watch daemon (PID varies; `REFS_AI=0` safe mode) re-runs stage 1 when `elixir-progress.md` mtime changes. The **top-level `docs/elixir/elixir-references.md` is a SEPARATE git-tracked doc NOT written by either script** — do not assume it mirrors kb.

**Bug class (the cms gates CANNOT catch this):** when a chapter's modules are reshuffled/retitled, the `REFS` dict can keep the OLD topic's sources. The insert then ships **topically-wrong references that still PASS all 9 Apollo gates** (gates check structure/links/voice, not whether a source matches the lesson topic). Fix at the **generator** (`REFS` dict), never the output. 2026-06: F5.02–F5.09 were all stale (mapped to pre-reshuffle topics: F5.05→Task/GenStage/Flow, F5.06→telemetry, F5.08→efficiency/Benchee, etc.); re-curated to canonical primary sources (Fowler, Meyer, Evans, Cockburn, Valim, hexdocs).

**Repair pattern for already-inserted stale page refs** (deterministic, do-no-harm — used `/tmp/sources_fix.py`): parse `kb/elixir-references.md` per module → build `<li>` list; for each `elixir/pragmatic/<dir>/*.html`, replace **only** the `<h3>Sources</h3><ul>…</ul>` (page refs block = `section.reveal[aria-labelledby=refsTitle] > p.prose + div.refs > (h3 Sources+ul)+(h3 Related+ul)`), preserving the per-page intro `<p>` and the Related list. **Gate each rewrite on a stale-marker regex** so only genuinely-wrong pages change (idempotent; preserves page-tailored notes on correct pages). Parser gotcha: reset the current-module on ANY non-target header or it vacuums the next chapter's bullets. Relates to [[elixir-course-update-pipeline]], [[jonnify-cms-toolchain]], [[user-commits-elixir-batches]].
