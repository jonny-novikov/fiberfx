---
name: mesh-course-writer
description: >-
  Use this skill to author or continue the course 'EchoMesh, In Depth' served at /mesh — the senior successor to the
  EchoMesh chapters (A8–A9) of /art, taught from the docs/echo/mesh manuscript (the landing mesh.landing.md, the M0
  overview mesh.0.md, the chapter landings mesh.[N].md and dives mesh.[N].[D].md) and the CAP literature (Gilbert &
  Lynch). It teaches the CAP theorem as a menu rather than a wall, and shows how EchoMesh SEGMENTS the
  consistency/availability trade across a Branded Component System stack on the BEAM, then makes the infrastructure
  transparent. Triggers: any request to create, continue, extend, relink, or validate the course landing, the M0
  overview, a chapter landing, or a deep-dive for this course; to grade a page with the jonnify-cms gates; or to wire a
  new chapter in. The course renders in ITS OWN visual identity — the /bcs contract-sheet BASIS (warm paper, mono-
  forward, numbered sections, frozen-transcript evidence) carried into a violet-led, CAP-duality surface
  (consistency-first blue ↔ availability-first green, amber for the staleness/edge dial), defined by the exemplar
  html/mesh/index.html — NEVER the dark-editorial tokens of the sibling courses, and NEVER the /bcs --b-* tokens
  cloned verbatim. The signature interactive primitive is .htabs — hover-to-switch tabs (the /bcs id-anatomy hover
  generalized) used for concept schemas, the stack surfaces, and health/recovery/partition emulators. Every figure is
  quoted VERBATIM from a committed source (the mesh manuscript or a cited primary source); EchoMesh is a FORWARD
  CONCEPT taught in proposed/living-status voice ('the course introduces…', 'as designed, the mesh would…') — its
  pieces real and shipped, their composition into the mesh proposed. The deliverable is always a self-contained static
  HTML page graded A+ across the ten jonnify-cms gates, authored into the existing design system — never a rebuild.
  Do NOT use for the /art course (art-course-writer), the /bcs course (bcs-course-writer), the /echomq course
  (echo-mq-writer), the /redis-patterns course (redis-course-writer), the mesh MANUSCRIPT (mesh-writer), other jonnify
  sections, or generic documents.
---

# Authoring the jonnify "EchoMesh, In Depth" course

This skill authors the course served at **`/mesh`**: *EchoMesh, In Depth* — the **senior successor to the EchoMesh
chapters (A8–A9) of `/art`**. It teaches the CAP theorem as a menu rather than a wall, and shows how EchoMesh segments
the consistency/availability trade across a Branded Component System stack on the BEAM, then makes the infrastructure
transparent. Two sources of truth govern, and where this skill disagrees with them, they win:

1. **The manuscript** under `docs/echo/mesh/` is the source of truth for *structure and grounding* — the
   [`mesh.toc.md`](../../../docs/echo/mesh/mesh.toc.md) (the chapter→dive tree), the landing
   ([`mesh.landing.md`](../../../docs/echo/mesh/mesh.landing.md)), the overview
   ([`mesh.0.md`](../../../docs/echo/mesh/mesh.0.md)), the chapter landings `mesh.[N].md`, the dives `mesh.[N].[D].md`,
   and the CAP appendix `appendixes/mesh.cap.md`. **Author a page only from its manuscript file; never invent
   structure.**
2. **The Go `jonnify-cms` binary** is the source of truth for the gates and the resolvable routes. Where this skill
   and the tool disagree, run the tool — it wins.

The prose discipline and the interactive craft are SHARED with the sibling courses — read
`.claude/skills/elixir-technical-writer/references/technical-writer.md` and `visualization-master.md` for the voice
and the interactive rules. **The design system is NOT shared:** this course has its own identity (§7). THIS skill
documents what is *different* for EchoMesh, In Depth: its manuscript grounding, its identity, its `.htabs` component,
its page surfaces, and its gate command.

## 0. Four standing rules

1. **Reuse, do not reinvent.** The identity, the routing, the `.htabs` component, the stamp convention, and the
   validator all exist and are proven (the exemplar `html/mesh/index.html`). Author content *into* them — never
   rebuild a system or introduce a library.
2. **Validate without images.** Validation is headless and text-only: `cms check` + reading the markup + an optional
   `curl` route crawl. Never screenshot.
3. **Every figure verbatim from a committed source.** A theorem statement, figure, SLA, module name, or strategy
   appears on a page only if it exists in a committed source — the mesh manuscript (`docs/echo/mesh/`) or a primary
   source cited in References (the CAP literature; the stack pieces). Verify by reading the source before citing.
   **EchoMesh is a FORWARD CONCEPT** — its pieces are real and shipped, their composition into the mesh is the
   PROPOSED design; teach it in living-status voice and never assert a mesh figure as shipped.
4. **The course's own identity.** Pages render in the **CAP contract sheet** identity (§7), copied from a built MESH
   page. The dark-editorial tokens of `/elixir`, `/echomq`, and the AAW course are out of bounds; so are the `/bcs`
   `--b-*` tokens used verbatim — EchoMesh, In Depth carries the /bcs BASIS into its own violet-led, CAP-duality
   surface.

## 1. Where to work

| Path | Role |
|---|---|
| `html/mesh/` | The served course. Whole hand-authored HTML files; the URL tree mirrors the dir tree (`serveDirTree`, read live — a new `.html` is live on save, no rebuild). |
| `docs/echo/mesh/mesh.toc.md` | The living **course TOC** — the landing, M0, chapters M1–M8, dives, abstracts, status. |
| `docs/echo/mesh/mesh.landing.md`, `mesh.0.md` | The **front page** and the **overview** (orientation). |
| `docs/echo/mesh/mesh.[N].md`, `mesh.[N].[D].md` | The **manuscript** — a chapter landing `mesh.[N].md` (page `M[N]`) and its three dives `mesh.[N].[D].md` (pages `M[N].[D]`). The content spine each page teaches. Read-only for authoring. |
| `docs/echo/mesh/appendixes/mesh.cap.md` | The **CAP appendix** — the deep theorem reference grounding M0/M1. |
| `docs/echo/mesh/markdown/<route>.md` | The **route-mirror md**, authored before each page's HTML (the served route minus `/mesh/`, `.md` appended; the landing is `markdown/index.md`). |
| `apps/jonnify-cms/bin/cms` | The **validator** (Go). Build: `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .`. |
| `references/course-map.md` (this skill) | The chapter/route/status map + the resume point. |

## 2. The product and the running grounding

A course of interconnected **static HTML** pages: no framework, no runtime, no CDN, no fetched fonts, no browser
storage. The grounding is **the CAP literature** (Gilbert & Lynch's 2002 proof and 2012 perspective, the catalogue of
four coping strategies; PACELC) and **a real, shipped stack** — the BEAM, EchoCache, the EchoMQ bus and streams,
globally replicated Tigris S3 retention, and Postgres with `Ecto.Multi`. The destination is **EchoMesh** — the
segmented mesh on the owned stack with transparent infrastructure (FLAME, Fly Machines, placeless placement), a
**forward concept the course introduces and builds toward: its pieces real and shipped, its composition proposed.**
Where the course meets the owned-runtime case it doors to `/art`; the law and the identity contract to `/bcs`; the bus
and stream tier to `/echomq`; the engine and the Fly deployment to `/elixir`.

## 3. The structure — surfaces and routes

The course is the **landing**, the **M0 overview**, and chapters **M1–M8**, each a landing and (the standard) **three
dives**. The routes:

- **The course landing** (`/mesh` → `index.html`) — the front page (`mesh.landing.md`): the thesis, the four-strategies
  signature `.htabs`, the stack `.htabs`, the chapter map M0–M8, the doors, References. **The design exemplar.**
- **M0 · Overview** (`/mesh/overview` → `overview/index.html`) — the orientation chapter (`mesh.0.md`), opening into
  three dives: `the-impossible` (`mesh.0.1.md`) · `the-menu` (`mesh.0.2.md`) · `the-mesh` (`mesh.0.3.md`), served at
  `/mesh/overview/<dive>`.
- **M1–M8 · chapters** — a chapter landing `<chapter>/index.html` (`mesh.[N].md`) and three dives
  `<chapter>/<dive>.html` (`mesh.[N].[D].md`). The chapter slugs from the TOC: `impossible · best-effort-availability ·
  best-effort-consistency · trading · segmenting · stack · transparent · future` (M1–M8). **M5 · Segmenting is the
  heart.**

Three **page surfaces** — copy the design system **from a built MESH page**; the landing (`html/mesh/index.html`) is
the canonical exemplar and the bootstrap for the first page of any new surface (never another jonnify course): the
**course landing** / the **M0 overview** / a **chapter landing** (the chapter's teaching arc over its three dive cards,
closing with an "Up next") / a **dive** (a full lesson, §5).

**Full links PASS — no fail-by-design manifests.** Unbuilt chapters/dives render as **non-anchor `soon` cards**; a
card becomes a link only when its route ships. Every MESH page holds STATUS: PASS on all ten gates, `links` included.

## 4. The grounding boundary — the CAP literature, the real stack, the proposed mesh

A page grounds in its manuscript file first (`M[N].[D]` teaches `mesh.[N].[D].md`), and in the evidence that file rests
on: the cited CAP literature (Gilbert & Lynch 2002/2012, PACELC — each linked, never paraphrased into a fabricated
claim) and the real stack pieces (FLAME, Fly Machines, Tigris, Ecto.Multi, the BEAM — each with its primary source).
**State the theorem precisely:** under a partition a service gives up consistency or availability; an asynchronous
network cannot *distinguish* a partition from a slow link; on a healthy network consistency still costs coordination
latency (PACELC). Never the loose "two of three." **No invention:** never a fabricated figure, SLA, latency number,
module, or API. **EchoMesh is forward/living status** — taught as proposed, never as shipped, with a visible "Proposed
· not shipped" note where the page leans on the mesh. The sibling courses own their depth — link forward through the
doors instead of teaching it.

## 5. Page anatomy, the `.htabs` component & the interactive contract

The MESH anatomy, established by the exemplar: a `header.top` (brand `jonnify·mesh`, the segmented `.route-tag`, an
anchor `.topnav`) → a hero (`.kicker`, `h1`, `.lede`, supporting `.heronote`, the **"Proposed · not shipped"** note
where apt) → a **signature interactive** → numbered sections (`.sech` headers: `§N` + a mono uppercase title + a
right-aligned source label) separated where apt by the **CAP-spectrum rule** device (`.caprule`) → **evidence blocks**
(`figure.frozen`, source-labelled) → cards (`.pcard` for chapters/dives, `.door` for the cross-course blocks) → a
**References** section (`<section id="refs">` with `class="refs"`, two columns, `Sources` / `Related`) → a `nav.pager`
(`class="pager"`, ≥1 resolving internal href) → `footer.site-foot` (3 columns + `.foot-bar` with the `.stamp` +
decoder).

**The `.htabs` hover-tab component (the signature primitive).** A tab strip (`.htabs-bar` with `role="tablist"` +
`<button role="tab" data-tab="…">`) over a panel set (`.htabs-panel` with `.htabs-p[data-tab]` `role="tabpanel"`).
The component JS (carried in the exemplar's trailing `<script>`, copy it verbatim) wires **`mouseenter` and `focus` to
switch, `click` to pin, and restores the pin on `mouseleave`** — hover-to-switch is the point (the reader no longer has
to click). It **degrades**: without the `html.js` class every panel is visible (CSS), so the page reads with no
script. Use `.htabs` for concept **schemas**, the **stack surfaces**, and **health / recovery / partition emulators**.
A signature `.htabs` may also drive an SVG (the active `data-tab` highlights an `<svg> g[data-tab]` group — the
exemplar's strategies-on-the-CAP-spectrum is the model).

Each page carries ≥1 interactive (≥2 on a dive), one of them an inline **`<svg role="img" aria-label="…">`** (the `svg`
gate is MANDATORY). Each performs a real operation over a fixed dataset and shows its result via pure functions; static
markup stays readable without JS; honour `prefers-reduced-motion`; no browser storage. Where the chapter is about
behaviour under a partition (M1, M3, M5, M8), prefer a **health/recovery/partition emulator** the reader drives.

**Every page has a route-mirrored md, authored first**, at `docs/echo/mesh/markdown/<route>.md` — the served route
minus the `/mesh/` prefix with `.md` appended (the landing is `markdown/index.md`).

## 6. The ten gates

`containers · svg · no-future · voice · storage · motion · degrade · links · pager · refs` (refs opt-in via
`--require-refs`). Build the validator, then run on every page:

```bash
apps/jonnify-cms/bin/cms check \
  --routes-from /mesh=html/mesh \
  --routes-from /art=html/art \
  --routes-from /bcs=html/bcs \
  --routes-from /echomq=html/echomq \
  --routes-from /elixir=elixir \
  --chapter-alias m0=overview,m1=impossible,m2=best-effort-availability,m3=best-effort-consistency,m4=trading,m5=segmenting,m6=stack,m7=transparent,m8=future \
  --require-refs html/mesh/<path>.html
```

Ship only at **STATUS: PASS** — on every page, with no manifest exception (§3). Gate-invisible checks, verified by
reading: **clamp spacing** (spaces around `+`/`-` inside `clamp()`), **the `.htabs` degrade** (panels visible without
the `js` class), **right-route-vs-resolvable** (read crumbs and pager intent), and **figure provenance** (re-read the
committed source of every figure quoted).

## 7. The identity & the two mandatory layout rules

**The CAP contract-sheet identity** (defined by `html/mesh/index.html`; copy its `<head>`…`</style>`, header, footer,
and trailing scripts, then change only `<title>`/`<meta>`, the route-tag, and `<main>`). It is the /bcs contract-sheet
*basis* (warm paper, mono-forward, numbered §sections, frozen-transcript evidence) carried into its own surface:

- Tokens: `--m-paper` (warm paper) · `--m-card` · `--m-ink` · `--m-dim` · `--m-line` (the /bcs basis) and the accents
  `--m-mesh` (EchoMesh violet — the house lead) · `--m-cons` (consistency-first / safety — blue) · `--m-avail`
  (availability-first / liveness — green) · `--m-edge` (staleness / trade dial / edge — amber); evidence on
  `--m-term-bg`. The CAP trade is made visible: consistency-first surfaces blue, availability-first green.
- Type: system stacks only — `--mono` (ui-monospace first) for ids/headers/labels/evidence; `--sans` for body prose.
  Nothing fetched.
- Devices: the **CAP-spectrum rule** (`.caprule`), the **`.htabs` hover-tab component**, `.sech` numbered headers,
  `figure.frozen` evidence, the rich `.door` blocks, the **"Proposed · not shipped"** note.
- **MUST NOT:** the dark-editorial navy/cream/gold palette, Cormorant Garamond / PT Serif / Manrope, the
  `.chap`/`.mods`/`.mod` card grid; and MUST NOT clone the `/bcs` `--b-*` tokens verbatim — EchoMesh, In Depth is the
  `--m-*` violet-led CAP-duality adaptation.

The two mandatory layout rules (drift source — enforce on every page):

1. **Clickable segmented route-tag.** Intermediate path parts are `<a href>` to that route level, the current part is
   `<span class="rcur">`, separated by `<span class="rsep">/</span>`; `/mesh` is one segment; the site root `/` is
   never a segment.
2. **Canonical 3-column footer.** `footer.site-foot` → `.foot-nav` (brand + chapters column + courses column) +
   `.foot-bar` with the `.stamp` + decoder (verbatim from the exemplar; a valid **`MSH…`** id).

## 8. Voice

Visible prose and code comments never contain *revolutionary, blazing, magical, simply, just, obviously, effortless*;
no exclamation marks, no emoji, no first person, no perceptual or interior-state verb applied to a tool, an agent, or a
software component (a mesh / node / runtime / cache / system does not "see" / "want" / "know" / "decide"; a server
*cannot distinguish* a partition from a slow link, it does not "know"). Active voice, short sentences, one idea per
section. The course's claim is **measured** — CAP is a constraint to design within, not to defeat; state the trade
fairly.

```bash
grep -nE '\b(just|simply|obviously|effortless|magical|revolutionary|blazing)\b' html/mesh/<path>.html
```

## 9. Branded Snowflake build stamp — the course's own namespace

Every page carries the footer `.stamp` + decoder (copied verbatim from the exemplar). The id is a 14-char **`MSH…`**
form — the course stamps in its **own namespace**. Mint fresh per page and verify the round-trip:

```bash
apps/jonnify-cms/bin/cms stamp mint --ns MSH      # → MSH0Nzv5M9mDqa (e.g.)
apps/jonnify-cms/bin/cms stamp decode MSH0Nzv5M9mDqa
```

Epoch `1704067200000`; layout `ts(41)<<22 | node(10)<<12 | seq(12)`. Update the panel's static `timestamp` dd to the
decoded value (the no-JS fallback).

## 10. The authoring workflow (per page)

1. **Read the manuscript file AND the TOC entry.** The TOC names the page, its route, and its grounding. The
   manuscript file (`mesh.[N].md` / `mesh.[N].[D].md`) is the content spine. Read it and the CAP literature / stack
   sources it cites. **Never author ahead of the manuscript, and never paraphrase a figure into a fabricated claim.**
2. **Author md-first, then the HTML.** Write `docs/echo/mesh/markdown/<route>.md`, then build the page copying the
   design system (incl. the `.htabs` component JS) from a built MESH page (bootstrap: the landing). Mint a fresh
   `MSH…` stamp. Quote evidence in `figure.frozen` blocks, source-labelled.
3. **Relink the parent landing** (orchestrator-only when fanning out) — flip the chapter/dive's non-anchor `soon` card
   to a live `<a>` card. Keep full links PASS: link only routes that now exist.
4. **Gate every page** to STATUS: PASS; adversarially read the gate-invisible bits (clamp, route-tag, figure
   provenance, the `.htabs` degrade, no `/bcs` token leak: `grep -n 'Cormorant\|Manrope\|PT Serif\|--b-paper\|--b-ns' <page>`).
5. **Sync the TOC** — mark the page built in `docs/echo/mesh/mesh.toc.md`.

When fanning out to background agents (one per page), give each: this skill, the built MESH exemplar, the exact route +
numbering + manuscript file + grounding, the gate command, the verbatim-figure guard, the forward/living-status rule
(EchoMesh PROPOSED), the `.htabs`/emulator requirement, and an explicit **no-git** constraint. Then adversarially
verify their output yourself.

## 11. Course map

See `references/course-map.md` for the chapter/route/status table and the resume point. Do not write redundant status
prose ("all built", "complete") into nav pages — the cards' chips already show status; describe structure and the arc
instead. **Never run git** in an authoring agent. Never edit the manuscript (`docs/echo/mesh/mesh*.md`) — it is the
Author/Operator's.
