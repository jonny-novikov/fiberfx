---
name: elixir-batch-presentational-drift
description: "Newly-built elixir module batches diverge from the established page template in gate-invisible presentational ways (breadcrumb route-tag, tile/card clickability, status pills) — audit each new batch against a known-good sibling"
metadata: 
  node_type: memory
  type: project
  originSessionId: 73b81fc7-ffef-4d6d-ac38-349cafb4dda9
---

When a chapter's later modules are built after its first one or two (e.g. F6.03–F6.09 after F6.01/F6.02 = lifecycle+routing), the later pages DIVERGE from the established template in presentational details the cms gates do NOT catch (gates check form/links, not template parity). Hit **3× in the F6 (phoenix) batch, 2026-06-02**:

1. **Header breadcrumb (`.route-tag`)** — later pages shipped a flat inert `<span class="route-tag">/elixir/phoenix/liveview</span>` instead of the segmented clickable form `<span class="route-tag"><span class="rsep">/</span><a href="/elixir">elixir</a>…<span class="rcur">LEAF</span></span>`. **28 pages** (7 chapters × index+3 dives). Gate-invisible: plain text has no href to break. Leaf = non-link `.rcur`; ancestors link to their cumulative path.
2. **Chapter-hub module cards** — later built modules still rendered `<div class="mod is-quiet"><span class="pill planned">` (dimmed, non-clickable) though the manifest said `built`. Fix → `<a class="mod" href="/elixir/<chapter>/<slug>">` + `pill built`.
3. **Course-root tiles** (`elixir/course/index.html`) — F6 tiles were `<div class="mod">` while F1–F5 were `<a class="mod" href=…>`. Fix → wrap each tile as `<a>` to its module hub.

**Audit one-liners for any new batch:**
- breadcrumb form: `for f in $(find elixir -name '*.html'); do grep -qE 'route-tag">/elixir' "$f" && echo "$f"; done` (broken = plain-text)
- built-but-planned: `grep -rl 'pill planned' elixir/*/index.html` (all 59 manifest modules are Status `built`, so ANY planned pill is stale)
- course-root tile parity: F6 `<a class="mod">` count should equal its module count

**Fix pattern:** deterministic do-no-harm Python script gated to the broken form ONLY, matching a known-good SIBLING's exact idiom (lifecycle for breadcrumbs, F5 tiles for course-root), dry-run first, idempotent. The broken markup is self-describing — the route-tag text IS the route, so no manifest lookup.

**The real fix is a gate:** a cms check "manifest says built ⇒ every reference is a live `<a>`, and the page matches the template's breadcrumb form" would catch all three at authoring time; until then it recurs on each new batch.

**RESOLVED 2026-06-02 — `elixir/algebra/index.html` restructured (user: "restructure algebra page to be the same Chapter structure and pass general Chapter page/validator in go").** It was the lone **bespoke** chapter landing (`.topbar`/`.nav-links`, own `--surface`/`--muted` tokens, KaTeX, an unused `data-level` toggle) — it actually **FAILED 3 cms gates** (voice `just`/`simply`, no `prefers-reduced-motion`, no `.pager`) and shipped a **leaked `build_page.py` Python f-string** verbatim in committed HTML (`""" + ''.join(f'<line …' for y in range(120,301,40)) + """` inside the hero SVG — un-evaluated builder template). Rebuilt onto the **canonical A+ chapter-landing skeleton = `elixir/functional/index.html`** (copy its `<head>` tokens + `.site`/`.hero`/`#arc` journey/`#modules` deflist/`#sits`/`.pager`/build-stamp anatomy; swap in the chapter's content), preserving algebra's Rosetta algebra→Elixir dictionary + the interactive function-mapping visualizer. Now A+. **Method for any chapter landing:** `cms build` is inert, so model on `functional/index.html` and validate with `cms check`; chapter accents are gold=F1, sage=F2, blue=F3, elixir=F4, blue=F5, burgundy=F6. The other 5 landings already conform.

Relates to [[elixir-content-fanout-drift]], [[f5-f6-page-bugs]], [[course-nav-prose-no-redundant-status]], [[jonnify-cms-toolchain]].
