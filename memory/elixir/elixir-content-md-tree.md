---
name: elixir-content-md-tree
description: docs/elixir/content/ is a per-route markdown source-of-record for all 204 /elixir pages; how it was built and must be regenerated
project: elixir
metadata: 
  node_type: memory
  type: project
  originSessionId: 115257c9-0f9f-4c20-8429-887322132a0e
---

`docs/elixir/content/<route>/` is a **per-route markdown source-of-record** mirroring the live `/elixir` course (204 pages): one `.md` per page (`<dir>/index.md` for hubs/landings, `<dir>/<slug>.md` for dives). Each md documents the live page's anatomy (route, file, verbatim hero lede + kicker, the `.mods`/`.dives` card list or dive sections, every interactive figure's ids + pure-fn + verbatim readout strings, the `#refs` block, and a Wiring block: route-tag/crumbs/toc-mini/pager/footer/meta) and ENDS with a `## Build instruction` block (copy head/header/footer/scripts from a named sibling; no-invent Portal-API guards; voice rules). It is the elixir analogue of `docs/agile-agent-workflow/content/`.

**Two files are pre-existing exemplars — never regenerate them:** `docs/elixir/content/phoenix/index.md` (a chapter-level decomposition reference the AGILE course's A2.07 reads) and its companion `phoenix/rungs.md` (citable verbatim strings). So the phoenix-landing route is covered by that exemplar; the backfill skips `phoenix/index.md`. Total on disk = 205 md (204 page-md incl. the exemplar + `rungs.md`).

**Index:** `docs/elixir/content/llms.md` (llmstxt.org convention, modelled on `docs/agile-agent-workflow/llms.md`) is the machine-readable map of the tree — H1 `>` summary, then per-chapter `###` sections with module-number-ordered bullets (hubs top-level, dives indented), links pointing at the `.md` files tagged with their `/elixir/...` route. It is **generated mechanically** from each md's H1 (`# F4.09.3 — …`) + path (sorted `-V`, dives = depth-2 non-index, `rungs.md`/chapter-`index.md` excluded from bullets); verify with a link-existence sweep (every `](path.md)` resolves) — 204 links = 204 pages, 0 broken.

**Regenerate via the `elixir-content-backfill` Workflow** (script persisted under the session workflows dir; ~51 agents, one per `index.html` directory, each writing its `index.md` + one md per direct non-index `.html` child — a clean by-directory write-partition, no shared-file contention). Embed per-chapter `[[elixir-course-update-pipeline]]` context (from `docs/elixir/elixir-progress.md`) + the distilled template; agents READ the live HTML as ground truth (verbatim ledes/ids), return PROSE not schema (edit-heavy → avoid the [[workflow-heavy-agent-no-schema]] abort). Verify with a **bijection check**: every live `elixir/**/*.html` maps to exactly one `docs/elixir/content/**/*.md` (0 gaps), each generated md has `## Lead` + `## Wiring` + `## Build instruction`. Accents per chapter: F0 blue, F1 gold, F2/F3 elixir-purple, F4 sage, F5 burgundy, F6 blue. The user commits these batches out-of-band ([[user-commits-elixir-batches]]).
