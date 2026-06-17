---
name: agile-course-writer
description: "Use this skill to author or continue the course 'Agile Agent Workflow in Elixir — Pragmatic Programming with Claude Agents' on the jonnify dark-editorial design system (served at /course/agile-agent-workflow). Triggers: any request to create, continue, extend, relink, or validate a chapter landing, module hub, deep-dive subpage, or the Portal exemplar for this course; to grade a page with the jonnify-cms Apollo gates; or to wire a new module into a chapter. The deliverable is always a self-contained static HTML page graded A+ across the ten gates (the nine Apollo gates + the agile-course refs mandate), authored into the existing design system — never a rebuild of the system. Do NOT use for the /elixir course (that is elixir-course-writer / elixir-technical-writer), for unrelated jonnify sections, or for generic documents."
---

# Authoring the jonnify "Agile Agent Workflow" course

This skill continues a long-running course about **Pragmatic Programming with Claude Agents** — building reliable
software as a human + a Claude agent over thin, provable increments. **The Go `jonnify-cms` binary is the source
of truth** for the gates and the resolvable routes; where this skill and the tool disagree, run the tool — it wins.

This course is a SIBLING craft to `/elixir` and shares the same design system, prose discipline, interactive
contract, and Snowflake stamp. The deep references in `.claude/skills/elixir-technical-writer/references/`
(`design-tokens.md`, `visualization-master.md`, `technical-writer.md`, `page-anatomy.md`) describe that shared
craft and apply verbatim — read them for the design tokens and the interactive/visualization rules. THIS skill
documents only what is *different* for the agile course: its toolchain, its structure, its tenth gate, and its
running argument.

## 0. Two standing rules

1. **Reuse, do not reinvent.** The design system, the routing, the Snowflake convention, and the validator all
   exist and are proven. Author content *into* them — never rebuild the system or introduce a library.
2. **Validate without images.** Validation is headless and text-only: `cms check` + reading the markup + an
   optional `curl`/`python3` route crawl. Never screenshot.

## 1. Where to work — and the one big difference from /elixir

The agile course has **no `build_page.py` and no content/fragment split**. Each page is a **complete, hand-authored
`.html` file** under `html/agile-agent-workflow/`, with the full `<head>`+`<style>` design system inlined, served
byte-for-byte by the jonnify Fiber server via `serveDirTree`. To author a page you write the whole file; to keep
the design system identical you **copy the `<head>`…`</style>`, the `<header class="site">`, the
`<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from an existing page** (a good model
is `html/agile-agent-workflow/what/four-artifacts.html` for a lesson, `…/why/two-layers/index.html` for a module hub), then
change only the `<title>`, `<meta description>`, the header `route-tag`, and the `<main>` body.

| Path | Role |
|---|---|
| `html/agile-agent-workflow/` | The served course. Whole HTML files; the URL tree mirrors the dir tree. |
| `apps/jonnify-cms/bin/cms` | The validator (Go). Build with `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .`. |
| `docs/agile-agent-workflow/{watch,reconcile}.sh` | The standing two-tier watcher + the deterministic `--fix` reconciler. |
| `.claude/skills/elixir-technical-writer/references/` | The SHARED craft refs (design tokens, visualization, voice, anatomy). |
| `references/course-map.md` (this skill) | The A0–A7 chapter/module/route/status map + the resume point. |
| `docs/agile-agent-workflow/agile-agent-workflow.toc.md` | The living, writer-maintained course table of contents + per-chapter/module abstracts. Sync it whenever a module lands. |

## 2. The product and the running project

A course of interconnected **static HTML** pages: no framework, no runtime, no CDN, no browser storage. Each page =
the shared head + a hand-authored `<main>` + one inline `<script>` + one or more inline SVG/HTML interactives.

The single running project is the **Portal**: a learning platform carried from an empty repository to a deployed,
multi-surface system (a branded store; an event-sourced engine behind one facade; a Phoenix web app; a Telegram
bot; a student dashboard). Every example is practised on the Portal so they accumulate instead of resetting — and
the A7 exemplar runs the whole workflow on it end to end. Reuse this domain; do not invent new ones. The Portal's
Elixir/OTP internals are taught by the companion `/elixir` course; cite it, do not re-teach it.

## 3. The structure — three levels, `A<chapter>.<module>.<subpage>`

The course mirrors the elixir course's chapter→lesson nesting, one level deeper:

- **Chapter** `A[N]` (A0…A7) — a top-level section with a **landing** page. e.g. A1 = "Why an Agile Agent
  Workflow" → `/course/agile-agent-workflow/why` (`why/index.html`).
- **Module** `A[N].[M]` — a chapter *has* modules; each is a **hub** that lists its subpages. e.g. A1.01 =
  "The two failure modes" → `/course/agile-agent-workflow/why/failure-modes` (`why/failure-modes/index.html`).
- **Subpage** `A[N].[M].[S]` — each module has **≥3** deep-dive subpages (the "Dives into" list on the hub). e.g.
  A1.01.1 → `/course/agile-agent-workflow/why/failure-modes/vibe-coding` (`why/failure-modes/vibe-coding.html`).

**Route convention (locked): modules nest under their chapter dir.** A chapter landing is `<chapter>/index.html`;
a module hub is `<chapter>/<module-slug>/index.html`; a subpage is `<chapter>/<module-slug>/<sub-slug>.html`. The
URL path mirrors the numbering. (A0 is the historical exception: its landing was consolidated from the retired
`/intro` into `/what`, which now doubles as the A0 chapter landing AND the A0.2 module hub — do NOT copy that
flatness for A1+.) `serveDirTree` resolves all of this with no
server change, and `cms --routes-from` derives the routes from the filesystem.

**Numbering is two-digit for modules** (`A1.01`…`A1.06`) and single-digit for subpages (`A1.01.1`). A deep-dive of a
subpage uses a flat hyphenated filename (e.g. `…-roadmap-anatomy.html`) and the label "A1.01.1 deep dive".

## 4. The course's running argument (the agile "bridge")

Where the elixir course bridges *an idea → its Elixir form*, this course bridges **a principle → its practice on the
Portal**. Every concept lands twice: the principle (Pragmatic Programming / Agile / XP / the Author–Operator thesis)
and the concrete move it becomes on the Portal. Make that correspondence explicit on every concept with the
`.bridge` block: `.cell.idea` (the principle) → `.arrow` → `.cell.elix` (the Portal practice), closed by a `.take`.

The thesis the whole course argues: **a Claude agent is a fast, tireless implementer of *well-specified* thin
slices; the human is the source of decomposition, judgement, and acceptance.** Every page should serve that thesis.

## 5. Page anatomy (every page, in order)

Identical to the shared anatomy (see `elixir-technical-writer/references/page-anatomy.md`), as a full HTML file:

1. Skip link, then `<header class="site">` with brand + nav carrying a `.route-tag` = **this page's exact route**,
   rendered as the **Elixir clickable-segment breadcrumb** (mandatory): each path part is its own element —
   intermediate parts are `<a href>` links to that route level, the current (last) part is `<span class="rcur">`,
   separated by `<span class="rsep">/</span>`; the base `/course/agile-agent-workflow` is one segment. The supporting
   CSS (`.route-tag a`, `.route-tag .rsep`, `.route-tag .rcur`) must be present. Copy it from a recent page — the
   route-tag `<a>` hrefs are then validated by the `links` gate.
2. A `.hero` inside a **`.hero-split`** (hero text on the left, an **interactive figure** on the right — the
   four-artifacts / elixir pattern; stacks to one column on mobile): `.crumbs` (the chapter→module→here trail), an
   `.eyebrow` (chapter · module · position), an `<h1>` with the accent word in `<span class="ex">` (the course's
   signature elixir-purple), a `.lede`, a `.kicker`, a `.toc-mini` (must include a `#refs` link).
3. One or more `<section>`s. A teaching section pairs `.prose` with a `.fig` (the interactive), a `pre.code`
   block where relevant, a `.geo-readout` live region, and a closing `.take`. Concept pairings use `.bridge`.
   A `.note` carries the forward pointer.
4. **A References section** — `<section id="refs">` with `<h2>References</h2>` and a `<div class="refs">` holding an
   `<h3>Sources</h3>` list and an `<h3>Related in this course</h3>` list. **Mandatory on every page** (gate #10).
   **Every `Sources` entry MUST be a real external link**, wrapping the citation:
   `<li><a href="https://…">Author &mdash; <em>Title</em></a> &mdash; gloss.</li>`. Reuse a URL already vetted on an
   existing page — the course home `html/agile-agent-workflow/index.html` is the canonical link registry (Pragmatic
   Programmer → `pragprog.com`, Extreme Programming Explained → `oreilly.com`, Specification by Example → `gojko.net`,
   User Stories Applied → `mountaingoatsoftware.com`, Continuous Delivery → `continuousdelivery.com`, the `llms.txt`
   convention → `llmstxt.org`, Anthropic engineering → `anthropic.com/engineering/…`). **Never invent a URL**; if no
   vetted link fits, cite a different real authoritative source that has one. (`Related in this course` entries are
   internal course routes, not external links.)
5. A `.pager` (`.btn.ghost` back, `.btn` forward, `.spacer`) — both links must resolve to real/built routes.
6. The **canonical 3-column footer** (mandatory; no one-off footers) — `<footer class="site-foot">` with a
   `<div class="wrap" style="display:block">` holding `.foot-cols` (brand + `.tag` / a chapter-or-module link column
   / a "The course" column) and a `.foot-bottom` carrying the `.stamp` + decoder script (copied verbatim; a `TSK…`
   Snowflake id). The `.foot-cols` / `.fbrand` / `.foot-bottom` CSS must be present. Copy the whole footer verbatim
   from a recent page.

## 6. The interactive contract

Each lesson page carries **two** interactives — one **in the hero** (the `.hero-split` figure, the four-artifacts /
elixir pattern) and one in the **main content** — each of which **performs the real operation and shows its actual
result** (never a canned animation): inline SVG or HTML driven by vanilla JS; a live `.geo-readout` (`aria-live`); a
one-sentence `.take`; **degrades** (controls + SVG present in static markup, JS only enhances); respects
`prefers-reduced-motion`; no browser storage. Compute the readout from a fixed dataset with small pure functions so
it is always truthful — and the two interactives must teach *different* moves, not the same one twice (e.g. the hero
frames the idea, the content figure proves a consequence). See
`elixir-technical-writer/references/visualization-master.md` for the full rules and the standard shells.

## 7. The ten gates (nine Apollo + refs)

`containers` · `svg` (≥1 well-formed) · `no-future` (no `/future` links) · `voice` · `storage` · `motion` ·
`degrade` · `links` (every internal href resolves) · `pager` · **`refs`** (a `.refs` block is present — the
agile-course mandate, opt-in via `--require-refs`). Run, and read the per-gate output:

```bash
apps/jonnify-cms/bin/cms check \
  --routes-from /course/agile-agent-workflow=html/agile-agent-workflow \
  --chapter-alias a0=what,a1=why --require-refs \
  html/agile-agent-workflow/<path>.html
```

Ship only at **STATUS: PASS** (all ten). Two caveats the gates cannot see, so check them by reading:
- **Clamp spacing.** `clamp(2.7rem,1.9rem+4.2vw,5.1rem)` (no spaces around `+`/`-`) is invalid CSS → the whole
  declaration is dropped → UA-default fallback. The gates strip `<style>`, so they never catch it. The canonical
  form is **spaced**: `1.9rem + 4.2vw`. `cms check --fix` repairs it deterministically.
- **Right route, wrong route.** The `links` gate proves a route *resolves*, never that it is the *intended* one
  (a breadcrumb to `/why` vs `/what` passes either way). Read crumbs/pager to confirm the parent is correct.
- **Sources need real links — `refs` cannot see this.** The `refs` gate only checks a `.refs` block is *present*; it
  does not verify each `Sources` entry carries a real external `href`. Audit by reading, or assert it:
  `awk '/<h3>Sources<\/h3>/{p=1}p{print}/<\/ul>/{if(p)exit}' <page> | sed 's#</li>#</li>\n#g' | grep -c 'href="http'`
  must equal the Sources `<li>` count. Reuse vetted URLs from the course home; never fabricate one.

## 8. Voice (read the sweep, do not just run it)

Visible prose and code comments never contain: *revolutionary, blazing-fast, magical, simply, just, obviously,
effortless*. No exclamation marks, no emoji, no first-person ("I"/"we"/"our"), no perceptual or interior-state
verbs applied to a tool or an agent (a function does not "see"/"want"). Active voice, short sentences, one idea per
section. The agent is an implementer of well-specified work — never anthropomorphised.

```bash
grep -nE '\b(just|simply|obviously|effortless|magical|revolutionary|blazing)\b' html/agile-agent-workflow/<path>.html
```

## 9. Branded Snowflake build stamp

Every page carries the footer `.stamp` + decoder (copied verbatim from any existing page). The id is a 14-char
`TSK…` form: 3-letter namespace + base62(snowflake) padded to 11; epoch `1704067200000`; layout
`ts(41)<<22 | node(10)<<12 | seq(12)`. The decoder fills `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`. Reusing
an existing valid id is fine for a hand-authored page (the decoder just decodes whatever is in `#stampId`).

## 10. The authoring workflow (run for every new module)

0. **Draft the markdown source first.** Write each page's content as markdown in
   `docs/agile-agent-workflow/content/<chapter>/<module-slug>/<page>.md` — the readable source of record: the lead,
   the precise definition, the worked Portal example, the **intent of both interactives** (what the hero figure
   frames and what the content figure proves), the principle↔practice bridge, the recap, and the references. THEN
   hand-author the HTML page from it. The bespoke interactives are written into the HTML (there is no generator);
   the md is the human-readable plan the HTML realises, and it is committed alongside the page.
1. **Author the module hub** `<chapter>/<module-slug>/index.html` — hero, an SVG that frames the module, a `.mods`
   grid of the ≥3 subpage cards (real routes), a References section, a pager.
2. **Author each subpage** `<chapter>/<module-slug>/<sub>.html` — a full lesson (idea → worked Portal example →
   interactive → the principle↔practice bridge → recap → References → pager). Copy the design system verbatim.
3. **Relink the chapter landing** — in `<chapter>/index.html`, turn the module's `.mods` card from a static
   `<div class="mod">` into `<a class="mod" href="…/<module-slug>">`, flip its pill `soon`→`live`/`built`, and
   point its `.note`/pager forward to the now-live module.
4. **Verify routes** — `cms check … --require-refs` every new page → all **STATUS: PASS**; then crawl the running
   server (`python3`/`curl` against `:8765`): every new route 200, every still-unbuilt sibling 404.
5. **Adversarially read** the gate-invisible bits: clamp spacing applied, crumbs/pager parent correct, no invented
   Portal API (cross-check function names/arities against the companion elixir course; do not invent), **every
   `Sources` entry a real, vetted external link** (audit per §7; reuse the course-home registry, never fabricate).
6. **Sync the living TOC** — update `docs/agile-agent-workflow/agile-agent-workflow.toc.md` so it mirrors the built
   course: mark the new module/chapter built and write/refresh its abstract. This doc is writer-maintained in real
   time; treat it as part of "done" for any module that lands.

> If the user re-sends an identical request mid-task, do not re-author — finish verification and summarise.

## 11. Do-no-harm + multi-agent notes

- The **standing watcher** (`docs/agile-agent-workflow/`) reports DRIFT/CLEAN as pages land; `reconcile.sh` runs
  `cms check --fix` (clamp + route repair, route-verified — never invents a link). New pages that link to a
  not-yet-built sibling will FAIL `links` until it lands — that is expected, not drift, ONLY on the route-manifest
  home page; a lesson/hub page must not ship dangling internal links.
- When fanning out subpage authoring to background agents, give each: this skill, a model page to copy the design
  system from, the exact route + numbering + topic, the gate command to self-verify, the no-invent guard (Portal
  API + references — **every `Sources` entry must be a real, vetted URL from the course-home registry, never a
  fabricated link**), and an explicit **no git** constraint. Then adversarially verify their output yourself.

## 12. Course map and resume point

See `references/course-map.md` for the full A0–A7 chapter/module/route/status table and the current resume point.
In brief: A0 Foundations is built — its landing is now `/what` (consolidated from the retired `/intro`; it doubles
as the A0.2 module hub). A1 "Why an Agile Agent Workflow" (`/why`) is the active chapter: modules A1.01–A1.04 are
built (failure-modes, pragmatic, loop, two-layers). **Resume at A1.05 — "Correct by definition"** (`/why/correct`):
the module hub plus ≥3 deep-dive subpages, fanned out one agile-course-writer-skilled agent per dive (the
user-confirmed process). See `references/course-map.md` for the full table and locked slugs.
