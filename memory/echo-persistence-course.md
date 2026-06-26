---
name: echo-persistence-course
description: "/echo-persistence course = raw-served html/ + docs/ mirror, NO authoring skill (/bcs-author doesn't cover it); author natively by copying an existing module's design system"
metadata: 
  node_type: memory
  type: reference
  originSessionId: c36ee942-28f6-43e5-80f5-147072eaecaa
---

The **/echo-persistence** course: `docs/echo-persistence/**.md` (frontmatter incl. `renders-to:`) mirrors `html/echo-persistence/**` (committed HTML twins, served **raw** by `go/echo-static` — NOT built from the md). 4 chapters — overview, foundations, local-store, engines, platform; each module is a dir of `index.md` (hub) + 3 dives, each with an `.html` sibling + a chapter `llms.txt`. Identity = the /redis-patterns contract-sheet **re-themed amber/bronze** (`--p-accent:#b06f12`); pedagogy = ONE bespoke interactive SVG per page (IIFE toggling `on`/`dim` classes + a `.readout`), **no machine numbers**.

**There is NO echo-persistence authoring skill, and `/bcs-author` does NOT cover it** (it routes only redis/echomq and treats `/echo-persistence` as a *door target*). To author a page natively: copy the `<style>`+`header`+`.idrule`+`footer` VERBATIM from an existing module's html (verify by `<style>` sha vs the model); frontmatter keys `id: ep-mN-{hub|dN}`, `status`, `route`, `kind`, `design`, `pedagogy`, `grounded-in`, `renders-to`; pager + foot stamp. **Gate manually** (link-resolution sweep mapping `/route` → `html/route{.html,/index.html}`; `<style>` hash vs the model; no-machine-numbers scrub) — NOT jonnify-cms (that gates redis/elixir).

**Global module numbering is sequential across chapters**, so inserting a module renumbers every later one — do it with a high-to-low `sed` (14→15, 13→14, …) across docs+html, then fix the seam pagers by hand (the prev module's `next` → the new module). Use a `while read` loop (zsh doesn't word-split unquoted `$files`).

2026-06-26: added engines **Module 11 · postgres-wal** (PROPOSED/forward-tense; grounds `docs/graft/graft.pg-wal-archive.design.md`, the WAL-archive fork ruled A→B); platform modules renumbered 11–14 → 12–15. Related: [[echo-static-server]].
