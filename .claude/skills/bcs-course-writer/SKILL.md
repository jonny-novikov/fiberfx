---
name: bcs-course-writer
description: "Use this skill to author or continue the course 'The Branded Component System' served at /bcs — the course taught from the BCS manuscript (docs/echo/bcs/content/, Parts I–VIII: the law in three clauses, the 14-byte branded-snowflake identity contract, the Elixir BCS core, the EchoMQ 2.0 Valkey-native bus, the trading-system capstone). Triggers: any request to create, continue, extend, relink, or validate the course landing, a chapter landing, module hub, or deep-dive for this course; to grade a page with the jonnify-cms gates; or to wire a new module into a chapter. The course renders in ITS OWN visual identity — the contract-sheet system defined by the B0 landing (html/bcs/index.html) — never the dark-editorial tokens of the sibling courses, and every figure on every page is quoted VERBATIM from a committed output under docs/echo/bcs/content/ (frozen rung transcripts, the contract + vectors, the bench record); unwritten manuscript Parts use the living-status voice ('the manuscript plans…'). The deliverable is always a self-contained static HTML page graded A+ across the ten gates (the nine Apollo gates + the refs mandate), authored into the existing identity and spec system — never a rebuild of either. Do NOT use for the /echomq course (echo-mq-writer), the /redis-patterns course (redis-course-writer), the /elixir course (elixir-course-writer / elixir-technical-writer), the /course/agile-agent-workflow course (agile-course-writer), other jonnify sections, or generic documents."
---

# Authoring the jonnify "Branded Component System" course

This skill authors the course served at **`/bcs`**: the BCS manuscript taught as a course — the architecture law
(*systems own their state and behavior; only identities, and messages about identities, cross boundaries;
identity is a typed, ordered, placed contract*), the branded-snowflake canon, the Elixir reference
implementation, the EchoMQ 2.0 Valkey-native bus, and the trading capstone. Two sources of truth govern, and
where this skill disagrees with them, they win:

1. **The spec system** under `docs/echo/bcs/` is the source of truth for *structure and grounding* — the
   [`bcs.toc.md`](../../../docs/echo/bcs/bcs.toc.md) (the chapter→module tree),
   [`bcs.roadmap.md`](../../../docs/echo/bcs/bcs.roadmap.md) (the canonical per-chapter **grounding map** + the
   seams ledger), the contract [`bcs.md`](../../../docs/echo/bcs/bcs.md), and the chapter triads
   (`specs/bcs.N.{md,specs.md,llms.md}` — the D-4 naming, not `.stories.md`). **Author a page only from its
   spec; never invent structure.**
2. **The Go `jonnify-cms` binary** is the source of truth for the gates and the resolvable routes. Where this
   skill and the tool disagree, run the tool — it wins.

The prose discipline and the interactive craft are SHARED with the sibling courses — read
`.claude/skills/elixir-technical-writer/references/technical-writer.md` and `visualization-master.md` for the
voice and the interactive rules. **The design system is NOT shared:** ignore `design-tokens.md` — this course
has its own identity (§7). THIS skill documents what is *different* for BCS: its manuscript grounding, its
identity, its page surfaces, and its gate command.

## 0. Four standing rules

1. **Reuse, do not reinvent.** The identity, the routing, the stamp convention, the validator, and the spec
   system all exist and are proven. Author content *into* them — never rebuild a system or introduce a library.
2. **Validate without images.** Validation is headless and text-only: `cms check` + reading the markup + an
   optional `curl` route crawl. Never screenshot.
3. **Every figure verbatim from a committed output.** The manuscript's evidence ethic is the course's: a number,
   gate count, namespace, key, or script name appears on a page only if it exists in a committed output under
   `docs/echo/bcs/content/`. Verify by reading the source before citing. Unwritten manuscript Parts (IV–VIII;
   chapters 3.4–3.6) take the living-status voice: *"the manuscript plans…"* — never asserted-as-written.
4. **The course's own identity.** Pages render in the contract-sheet system (§7), copied from a built BCS page.
   The dark-editorial tokens of `/elixir`, `/redis-patterns`, `/echomq`, and the AAW course are out of bounds:
   no navy/cream/gold palette, no Cormorant Garamond / PT Serif / Manrope, no `.chap`/`.mods`/`.mod` card grid.

## 1. Where to work

| Path | Role |
|---|---|
| `html/bcs/` | The served course. Whole hand-authored HTML files; the URL tree mirrors the dir tree (`serveDirTree`, read live — a new `.html` is live on save, no rebuild). |
| `docs/echo/bcs/bcs.toc.md` | The living **course TOC** — chapters B0–B8, modules, abstracts, status. (NOT `content/bcs.toc.md` — that is the manuscript's reading order, never edited by course authoring.) |
| `docs/echo/bcs/bcs.roadmap.md` | The **roadmap** + the canonical **grounding map** (which manuscript files + committed evidence each chapter draws on) + the seams ledger. Cite these; never invent. |
| `docs/echo/bcs/bcs.md` | The **contract** — the spec-system rules, the identity declaration + MUST-NOT list, the chapter map. |
| `docs/echo/bcs/specs/bcs.N.{md,specs.md,llms.md}` | The **chapter triad** a page batch builds from. `bcs.0.*` (the landing rung) is the exemplar. |
| `docs/echo/bcs/content/` | The **manuscript + evidence** (Author/Operator's; read-only for course authoring): `bcs<part>.<chapter>.md` chapters, `contract.md` + `vectors.json` (the canon), `echo_data/**` (rung transcripts, runtimes, benches), `docs/` (the five historical articles), `bcs.progress.md` (the ledger, decisions D-1…D-10). |
| `docs/echo/bcs/markdown/<route>.md` | The **route-mirror md**, authored before each page's HTML. |
| `apps/jonnify-cms/bin/cms` | The **validator** (Go). Build: `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .`. |
| `references/course-map.md` (this skill) | The B0–B8 chapter/route/status map + the resume point. |

## 2. The product and the running grounding

A course of interconnected **static HTML** pages: no framework, no runtime, no CDN, no fetched fonts, no browser
storage. The grounding is **a book being written in this repository**: the BCS manuscript — eight Parts, every
built chapter backed by a rung (an executable check script + a frozen `PASS n/n` transcript). The identity canon
is the **branded snowflake** (`content/contract.md`): 3-char uppercase namespace + 11 Base62 chars carrying
`ts(41) | node(10) | seq(12)`, epoch `1704067200000`; canonical vector `hash32(274557032793636864) = 234878118`;
ceiling `MAX_PAYLOAD = "AzL8n0Y58m7"`. The worked project is a trading system (`AST TXN PRT ORD RSK STR`); the
bus is **EchoMQ 2.0, backed by Valkey** through a purpose-built connector (gated `PASS 8/8` against live Valkey
8.1.8: sequential INCR `29456` ops/s, pipelined SET `454483` ops/s). Where the course meets the bus protocol it
doors to `/echomq`; the substrate patterns to `/redis-patterns`; the Portal engine to `/elixir`.

## 3. The structure — three levels and four page surfaces

Three levels, `B<chapter>.<module>.<dive>` (course letter **B**); module numbers map **one-to-one to manuscript
chapters** (`B2.3` teaches `content/bcs2.3.md`):

- **Chapter** `B[N]` (B0…B8) → a landing `<chapter>/index.html`. Slugs: `ideas · elixir-core · bus · cache · go ·
  node · fly · trading` (B1–B8); B0 is the course landing itself (`/bcs` → `index.html`).
- **Module** `B[N].[M]` → a hub `<chapter>/<module>/index.html`.
- **Dive** `B[N].[M].[S]` → a deep-dive `<chapter>/<module>/<sub>.html` (≥3 per module, fixed in the chapter
  triad at build time).

Four **page surfaces** — copy the design system **from a built BCS page of the same surface**; the B0 landing
(`html/bcs/index.html`) is the canonical exemplar and the bootstrap for the first page of any new surface (never
another jonnify course):

- **The course landing** (`/bcs` → `index.html`) — B0 itself: the law triptych, the id-anatomy SVG, the frozen
  transcripts, the B1–B8 map, the doors, References.
- **A chapter landing** (`<chapter>/index.html`) — the chapter's teaching arc over its module cards, closing
  with an "Up next" grid.
- **A module hub** (`<chapter>/<module>/index.html`) — the module's framing + its ≥3 dive cards.
- **A dive** (`<chapter>/<module>/<sub>.html`) — a full lesson (§5).

**Full links PASS — no fail-by-design manifests.** Unbuilt chapters/modules render as **non-anchor `soon`
cards** (the B0 inversion of the sibling courses' route-manifest convention); a card becomes a link only when
its route ships. Every BCS page holds STATUS: PASS on all ten gates, `links` included.

## 4. The running argument — the manuscript taught, and the grounding boundary

Where `/redis-patterns` bridges *a pattern → its real application*, this course bridges **the manuscript's
argument → its committed evidence**. Every page teaches what the manuscript wrote and proves it the manuscript's
way: a frozen transcript, a normative vector, a bench record — quoted verbatim, labelled with its source file.

**The grounding rule (the master discipline).** The per-chapter grounding map in `bcs.roadmap.md` is
authoritative: B1 → `content/bcs1.*.md` + the rung 1.1 transcripts + the bench record; B2 → `content/bcs2.*.md`
+ the rung 2.2–2.5 transcripts + the code drops; B3 → `content/bcs3.*.md` + `bcsA.md` + the connector evidence;
B4–B8 → TOC abstracts (living status). **No invention:** never a fabricated figure, namespace, Lua script,
module, or API. The sibling courses own their depth — link forward through the doors instead of teaching it.

## 5. Page anatomy & the interactive contract

The BCS anatomy, established by the exemplar: a `header.top` (brand `jonnify·bcs`, the segmented `.route-tag`,
an anchor `.topnav`) → a hero (`.kicker`, `h1`, `.lede`, supporting `.heronote`) → numbered sections (`.sech`
headers: `§N` + a mono uppercase title + a right-aligned source label) separated where apt by the 14-cell
`.idrule` device → **frozen-transcript evidence blocks** (`figure.frozen` with a source-labelled `figcaption`,
the `frozen` tag, and a verbatim `pre`) → cards (`.pcard` for chapters/modules, `.door` for cross-course doors)
→ a **References** section (`<section id="refs">` with `class="refs"`, two columns, `Sources` / `Related`
groups) → a `nav.pager` (`class="pager"`, ≥1 resolving internal href) → `footer.site-foot` (3 columns
`.foot-nav` + `.foot-bar` with the `.stamp` + decoder). Each page carries ≥1 interactive (≥2 on a dive) that
**performs a real operation and shows its actual result** over a fixed dataset via pure functions — the B0
id-anatomy segment readout is the exemplar shell. Static markup stays readable without JS; honour
`prefers-reduced-motion`; no browser storage.

**Every page has a route-mirrored md, authored first**, at `docs/echo/bcs/markdown/<route>.md` — the served
route minus the `/bcs/` prefix with `.md` appended (the landing is `markdown/index.md`). It is the
source-of-record the HTML reflects: the page's prose in clean markdown + a `## References` with `Sources` /
`Related` groups. Author the md, then build the HTML to match it.

## 6. The ten gates

`containers · svg · no-future · voice · storage · motion · degrade · links · pager · refs` (refs opt-in via
`--require-refs`). Build the validator, then run on every page:

```bash
apps/jonnify-cms/bin/cms check \
  --routes-from /bcs=html/bcs \
  --routes-from /echomq=html/echomq \
  --routes-from /redis-patterns=html/redis-patterns \
  --routes-from /elixir=elixir \
  --chapter-alias b1=ideas,b2=elixir-core,b3=bus,b4=cache,b5=go,b6=node,b7=fly,b8=trading \
  --require-refs html/bcs/<path>.html
```

Ship only at **STATUS: PASS** — on every page, with no manifest exception (§3). The extra `--routes-from`
mounts let the door links resolve in-gate. Gate-invisible checks, verified by reading: **clamp spacing** (spaces
around `+`/`-` inside `clamp()`, or the declaration drops to a UA default), **right-route-vs-resolvable** (read
crumbs and pager intent), and **figure provenance** (re-read the committed source of every number quoted).

## 7. The identity & the two mandatory layout rules

**The contract-sheet identity** (defined by `html/bcs/index.html`; copy its `<head>`…`</style>`, header, footer,
and trailing scripts, then change only `<title>`/`<meta>`, the route-tag, and `<main>`):

- Tokens: `--b-paper #f6f3ec` · `--b-card #fffefa` · `--b-ink #22282b` · `--b-dim` · `--b-line` and the four
  segment hues `--b-ns #b23b2e` (oxide red) · `--b-ts #20618e` (drafting blue) · `--b-node #2e7d5b` (verdigris)
  · `--b-seq #7d4e8f` (violet); transcript blocks on `--b-term-bg #171c1e`.
- Type: system stacks only — `--mono` (ui-monospace first) for ids, headers, labels, evidence; `--sans` for
  body prose. Nothing fetched.
- Devices: the 14-cell `.idrule` (3 namespace cells + 11 payload cells), triptych grids, `.sech` numbered
  section headers with source labels, `figure.frozen` transcripts.

The two mandatory layout rules (drift source — enforce on every page):

1. **Clickable segmented route-tag.** Intermediate path parts are `<a href>` to that route level, the current
   part is `<span class="rcur">`, separated by `<span class="rsep">/</span>`; `/bcs` is one segment; the site
   root `/` is never a segment.
2. **Canonical 3-column footer.** `footer.site-foot` → `.foot-nav` (brand + chapters column + courses column) +
   `.foot-bar` with the `.stamp` + decoder (verbatim from the exemplar; a valid **`BCS…`** id).

## 8. Voice

Visible prose and code comments never contain *revolutionary, blazing, magical, simply, just, obviously,
effortless*; no exclamation marks, no emoji, no first person, no perceptual or interior-state verb applied to a
tool, an agent, or a software component (a store / gate / connector does not "see" / "want" / "decide"). Active
voice, short sentences, one idea per section.

```bash
grep -nE '\b(just|simply|obviously|effortless|magical|revolutionary|blazing)\b' html/bcs/<path>.html
```

## 9. Branded Snowflake build stamp — the course's own namespace

Every page carries the footer `.stamp` + decoder (copied verbatim from the exemplar). The id is a 14-char
**`BCS…`** form — the course stamps in its **own namespace**, the manuscript's D-8 rule applied to the course
itself. Mint fresh per page and verify the round-trip:

```bash
apps/jonnify-cms/bin/cms stamp mint --ns BCS     # → BCS0NtBpC9oGGW (e.g.)
apps/jonnify-cms/bin/cms stamp decode BCS0NtBpC9oGGW
```

Epoch `1704067200000`; layout `ts(41)<<22 | node(10)<<12 | seq(12)`. Update the panel's static `timestamp` dd to
the decoded value (the no-JS fallback).

## 10. The authoring workflow (spec-first; per module)

1. **Read the chapter triad AND the manuscript chapter.** The triad (`specs/bcs.N.*`) names the module, its
   manuscript chapter, its grounding, and its dives. Then read the manuscript chapter and the evidence files the
   grounding map names. **Never author ahead of the spec, and never paraphrase a figure.**
2. **Author md-first, then the HTML.** Write `docs/echo/bcs/markdown/<route>.md`, then build the page copying
   the design system from a built BCS page of the same surface (bootstrap: the B0 landing). Mint a fresh `BCS…`
   stamp. Quote evidence in `figure.frozen` blocks, source-labelled.
3. **Relink the parent landing** (orchestrator-only when fanning out) — flip the module's non-anchor `soon`
   card to a live `<a>` card. Keep full links PASS: link only routes that now exist.
4. **Gate every page** to STATUS: PASS; adversarially read the gate-invisible bits (clamp, route-tag, figure
   provenance, no dark-editorial token leak: `grep -n 'Cormorant\|Manrope\|PT Serif'`).
5. **Sync the TOC** — mark the module built in `docs/echo/bcs/bcs.toc.md` so the views agree.

When fanning out to background agents (one per module or per dive), give each: this skill, a built BCS model
page, the exact route + numbering + the module's spec + grounding files, the gate command, the verbatim-figure
guard, the living-status rule, and an explicit **no-git** constraint. Then adversarially verify their output
yourself.

## 11. Spec system & course map

The structure is settled **specs-first** before any page: the TOC maps, the roadmap plans and fixes the
grounding, the chapter triads define, and page authoring expands a spec faithfully. See
`references/course-map.md` for the B0–B8 chapter/route/status table and the resume point. Do not write
redundant status prose ("all built", "complete") into nav pages — the cards' chips already show status;
describe structure and the arc instead. **Never run git** in an authoring agent — leave changes in the working
tree; the operator commits batches out-of-band. Never edit the manuscript or its ledger
(`docs/echo/bcs/content/**`).
