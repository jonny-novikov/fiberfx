---
name: art-course-writer
description: Use this skill to author or continue the course 'The Art of BCS' (The Art of the Branded Component System) served at /art — the senior continuation of /bcs, taught from the docs/echo/art manuscript (the Prelude, the Preface, and ten Parts: the runtime that subsumes the constellation, the four arguments — no coordinator, no log broker, no message broker, no orchestrator — the hot path, the durable edge, EchoMesh, observability, the whole picture) and the Exchange Platform exemplar. Triggers: any request to create, continue, extend, relink, or validate the course landing, a chapter landing, or a deep-dive for this course; to grade a page with the jonnify-cms gates; or to wire a new chapter into the course. The course renders in ITS OWN visual identity — the architect's-blueprint adaptation of the contract-sheet system defined by the A0 landing (html/art/index.html), with the cool-paper / architect-indigo / availability-green / EchoMesh-violet / edge-amber palette — NEVER the dark-editorial tokens of the sibling courses, and NEVER the warm oxide-red contract sheet of /bcs verbatim. Every figure on every page is quoted VERBATIM from a committed source — the art manuscript (docs/echo/art/), a committed Exchange-exemplar gate transcript, or a cited primary source; EchoMesh is a FORWARD CONCEPT taught in proposed/living-status voice ('the course introduces…', 'the manuscript plans…') — never asserted as shipped. The deliverable is always a self-contained static HTML page graded A+ across the ten gates (the nine Apollo gates + the refs mandate), authored into the existing identity and spec system — never a rebuild of either. Do NOT use for the /bcs basics course (bcs-course-writer), the /echomq course (echo-mq-writer), the /redis-patterns course (redis-course-writer), the /elixir course (elixir-course-writer / elixir-technical-writer), the /course/agile-agent-workflow course (agile-course-writer), other jonnify sections, or generic documents.
---

# Authoring the jonnify "The Art of BCS" course

This skill authors the course served at **`/art`**: *The Art of BCS* — the **senior continuation of `/bcs`**, the
architect's case for owning the runtime rather than renting a constellation of third-party infrastructure around it.
It teaches a manuscript being written in this repository — for a stateful, soft-real-time system run by one
organization, the BEAM subsumes the four systems a production exchange is conventionally built around (a coordinator,
a log broker, a message broker, an orchestrator), the branded identity carries the system's state across every store
and language, and the case is built part by part to **EchoMesh** — the distributed substrate where the system keeps
running even when a provider does not. Two sources of truth govern, and where this skill disagrees with them, they
win:

1. **The spec system** under `docs/echo/art/` is the source of truth for *structure and grounding* — the
   [`art.toc.md`](../../../docs/echo/art/art.toc.md) (the chapter→dive tree, A0–A10), the **manuscript**
   ([`art.prelude.md`](../../../docs/echo/art/art.prelude.md), [`art.preface.md`](../../../docs/echo/art/art.preface.md),
   and the `art[N].md` / `art[N][D].md` chapter+dive files), and — once authored — the chapter triads. **Author a
   page only from its manuscript chapter and its spec; never invent structure.**
2. **The Go `jonnify-cms` binary** is the source of truth for the gates and the resolvable routes. Where this skill
   and the tool disagree, run the tool — it wins.

The prose discipline and the interactive craft are SHARED with the sibling courses — read
`.claude/skills/elixir-technical-writer/references/technical-writer.md` and `visualization-master.md` for the voice
and the interactive rules. **The design system is NOT shared:** ignore `design-tokens.md` — this course has its own
identity (§7). THIS skill documents what is *different* for The Art of BCS: its manuscript grounding, its identity,
its page surfaces, and its gate command.

## 0. Four standing rules

1. **Reuse, do not reinvent.** The identity, the routing, the stamp convention, the validator, and the spec system all
   exist and are proven. Author content *into* them — never rebuild a system or introduce a library.
2. **Validate without images.** Validation is headless and text-only: `cms check` + reading the markup + an optional
   `curl` route crawl. Never screenshot.
3. **Every figure verbatim from a committed source.** The manuscript's evidence ethic is the course's: a number, SLA,
   availability figure, gate count, namespace, or module name appears on a page only if it exists in a committed
   source — the art manuscript (`docs/echo/art/`), a committed Exchange-exemplar gate transcript, or a primary source
   cited in References. Verify by reading the source before citing. **EchoMesh is a FORWARD CONCEPT** — it does not yet
   exist in code; the unwritten manuscript Parts take the living-status voice (*"the course introduces…"*, *"the
   manuscript plans…"*) and never assert a figure as shipped.
4. **The course's own identity.** Pages render in the **architect's-blueprint** identity (§7), copied from a built ART
   page. The dark-editorial tokens of `/elixir`, `/redis-patterns` (the dark-editorial ones), `/echomq`, and the AAW
   course are out of bounds; so is the warm oxide-red contract sheet of `/bcs` used verbatim — The Art of BCS adapts
   that family into its own cool-paper, indigo-led palette.

## 1. Where to work

| Path | Role |
|---|---|
| `html/art/` | The served course. Whole hand-authored HTML files; the URL tree mirrors the dir tree (`serveDirTree`, read live — a new `.html` is live on save, no rebuild). |
| `docs/echo/art/art.toc.md` | The living **course TOC** — chapters A0–A10, dives, abstracts, status. |
| `docs/echo/art/art.prelude.md`, `art.preface.md` | The **mission** and the **architectural thesis** — the grounding for the A0 orientation and a citable spine throughout. |
| `docs/echo/art/art[N].md`, `art[N][D].md` | The **manuscript** — a chapter landing `art[N].md` (page `A[N]`) and its three dives `art[N][D].md` (pages `A[N].[D]`). The content spine each page teaches. Read-only for authoring. |
| `docs/echo/art/markdown/<route>.md` | The **route-mirror md**, authored before each page's HTML (the served route minus `/art/`, `.md` appended; the landing is `markdown/index.md`). |
| `apps/jonnify-cms/bin/cms` | The **validator** (Go). Build: `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .`. |
| `references/course-map.md` (this skill) | The A0–A10 chapter/route/status map + the resume point. |

## 2. The product and the running grounding

A course of interconnected **static HTML** pages: no framework, no runtime, no CDN, no fetched fonts, no browser
storage. The grounding is **a book being written in this repository** — *The Art of BCS*: a Prelude (the mission), a
Preface (the thesis), and ten Parts that take the production concerns of an exchange one at a time. The identity canon
is the **branded snowflake** the `/bcs` course owns (the course assumes it as settled ground and doors to `/bcs` for
it). The worked system is the **Exchange Platform** exemplar (`Exchange.*`, the bounded `EchoCache.Ring` ingress, the
single-writer book, the pure decider); the bus is **EchoMQ 2.0 backed by Valkey**. The destination the whole course
builds toward is **EchoMesh** — the distributed BEAM substrate of Part VIII, a **forward concept introduced and built
toward, not yet shipped**. Where the course meets the bus protocol it doors to `/echomq`; the substrate patterns to
`/redis-patterns`; the law, the contract, and the as-built ring/journal/lanes to `/bcs`; the Phoenix engine, the
umbrella, and the Fly deployment chapter to `/elixir`.

## 3. The structure — two levels and three page surfaces

Two levels, `A<chapter>.<dive>` (course letter **A**); a chapter maps **one-to-one to a manuscript chapter**
(`A1` teaches `art1.md`, its dive `A1.2` teaches `art12.md`):

- **Chapter** `A[N]` (A0…A10) → a landing. A0 is the **course landing itself** (`/art` → `index.html`); A1–A10 each
  get a chapter landing `<chapter-slug>/index.html` (e.g. `/art/thesis` → `thesis/index.html`). The chapter slugs from
  the TOC: `thesis · no-coordinator · no-log-broker · no-message-broker · no-orchestrator · hot-path · durable-edge ·
  echomesh · echomesh-depth · whole-picture` (A1–A10). The heart is the **A8→A9 pair** — `echomesh` introduces
  EchoMesh, `echomesh-depth` takes it to its CAP/PACELC foundations.
- **Dive** `A[N].[D]` → a deep-dive, **three per chapter** (`D` of 1, 2, 3), fixed by the manuscript — the lone
  exception is **A9 · EchoMesh in Depth, which carries two** (`pacelc-design` + `under-the-hood`, each with an
  interactive failure-and-recovery emulator). A0's
  three dives are leaf files at the course root (`/art/<dive-slug>` → `<dive-slug>.html`); A1–A10's three dives sit
  under the chapter dir (`/art/<chapter-slug>/<dive-slug>` → `<chapter-slug>/<dive-slug>.html`). The dive slugs are
  fixed in the TOC (and pinned in the chapter triad at build time).

Three **page surfaces** — copy the design system **from a built ART page of the same surface**; the A0 landing
(`html/art/index.html`) is the canonical exemplar and the bootstrap for the first page of any new surface (never
another jonnify course):

- **The course landing** (`/art` → `index.html`) — A0 itself: the thesis, the borrowed-availability interactive, the
  constellation-subsumed interactive, the A0–A10 map ending at EchoMesh, the rich course-to-course doors, References.
- **A chapter landing** (`<chapter>/index.html`) — the chapter's teaching arc over its three dive cards, closing with
  an "Up next" link.
- **A dive** (`<chapter>/<sub>.html`) — a full lesson (§5).

**Full links PASS — no fail-by-design manifests.** Unbuilt chapters/dives render as **non-anchor `soon` cards**; a
card becomes a link only when its route ships. Every ART page holds STATUS: PASS on all ten gates, `links` included.

## 4. The running argument — the manuscript taught, and the grounding boundary

Where `/bcs` bridges *the manuscript's law → its committed evidence*, this course bridges **the architect's case → the
arithmetic, the runtime, and the working system that prove it**. Every page teaches what the manuscript argued and
proves it the manuscript's way: the availability arithmetic derived, the cloud's own SLAs stated fairly and cited, a
committed Exchange-exemplar gate transcript quoted verbatim, a primary source linked for every external claim.

**The grounding rule (the master discipline).** A page grounds in its manuscript chapter first (`A[N].[D]` teaches
`art[N][D].md`), and in the evidence that chapter rests on: the cited primary sources (AWS SLA, Armstrong's history &
thesis, the BEAM Book, Programming Erlang, the Twitter Snowflake announcement, Kafka KRaft, Kubernetes, FLAME — each
linked, never paraphrased into a fabricated number; **for the EchoMesh chapters A8/A9, the CAP/PACELC literature in
`art.references.md` — Gilbert-Lynch's CAP proof, FLP, Paxos, the Yu-Vahdat consistency-cost work — and the CAP source
`art.cap.md`**), the availability arithmetic (derived, not asserted), and — for Parts VI and VIII–IX — the committed
`Exchange.*` / `EchoCache.*` gate records (quoted verbatim, source-labelled). **No invention:** never a fabricated
SLA, availability figure, latency number, module, or API. **EchoMesh — introduced in A8 (`/art/echomesh`) and taken
to its CAP/PACELC depth in A9 (`/art/echomesh-depth`) — and every manuscript-pending Part are forward/living status**
— taught as introduced or planned, never as shipped. The sibling courses own their depth — link forward through the
doors instead of teaching it.

## 5. Page anatomy & the interactive contract

The ART anatomy, established by the exemplar: a `header.top` (brand `jonnify·art`, the segmented `.route-tag`, an
anchor `.topnav`) → a hero (`.kicker`, `h1`, `.lede`, supporting `.heronote`) → a **signature interactive** (the
borrowed-availability calculator on the landing; a chapter-apt interactive elsewhere) → numbered sections (`.sech`
headers: `§N` + a mono uppercase title + a right-aligned source label) separated where apt by the **nines-rule**
device (`.ninerule`) → **evidence blocks** (`figure.frozen` with a source-labelled `figcaption`, the `frozen` tag, and
a verbatim `pre` — an Exchange gate transcript, a cited SLA table, or a derived-arithmetic ledger) → cards (`.pcard`
for chapters/dives, `.door` for the cross-course reference blocks) → a **References** section (`<section id="refs">`
with `class="refs"`, two columns, `Sources` / `Related` groups) → a `nav.pager` (`class="pager"`, ≥1 resolving
internal href) → `footer.site-foot` (3 columns `.foot-nav` + `.foot-bar` with the `.stamp` + decoder). Each page
carries ≥1 interactive (≥2 on a dive) that **performs a real operation and shows its actual result** over a fixed
dataset via pure functions — the A0 borrowed-availability calculator is the exemplar shell. Static markup stays
readable without JS; honour `prefers-reduced-motion`; no browser storage.

**Every page has a route-mirrored md, authored first**, at `docs/echo/art/markdown/<route>.md` — the served route
minus the `/art/` prefix with `.md` appended (the landing is `markdown/index.md`). It is the source-of-record the HTML
reflects: the page's prose in clean markdown + a `## References` with `Sources` / `Related` groups. Author the md,
then build the HTML to match it.

## 6. The ten gates

`containers · svg · no-future · voice · storage · motion · degrade · links · pager · refs` (refs opt-in via
`--require-refs`). Build the validator, then run on every page:

```bash
apps/jonnify-cms/bin/cms check \
  --routes-from /art=html/art \
  --routes-from /bcs=html/bcs \
  --routes-from /echomq=html/echomq \
  --routes-from /redis-patterns=html/redis-patterns \
  --routes-from /elixir=elixir \
  --chapter-alias a1=thesis,a2=no-coordinator,a3=no-log-broker,a4=no-message-broker,a5=no-orchestrator,a6=hot-path,a7=durable-edge,a8=echomesh,a9=echomesh-depth,a10=whole-picture \
  --require-refs html/art/<path>.html
```

Ship only at **STATUS: PASS** — on every page, with no manifest exception (§3). The extra `--routes-from` mounts let
the door links resolve in-gate. Gate-invisible checks, verified by reading: **clamp spacing** (spaces around `+`/`-`
inside `clamp()`, or the declaration drops to a UA default), **right-route-vs-resolvable** (read crumbs and pager
intent), and **figure provenance** (re-read the committed source of every number quoted).

## 7. The identity & the two mandatory layout rules

**The architect's-blueprint identity** (defined by `html/art/index.html`; copy its `<head>`…`</style>`, header,
footer, and trailing scripts, then change only `<title>`/`<meta>`, the route-tag, and `<main>`). It is the
contract-sheet *family* (light paper, mono-forward system fonts, numbered §sections with source labels, frozen-
transcript evidence blocks) adapted into its own palette:

- Tokens: `--a-paper` (cool blueprint paper) · `--a-card` (near-white drawing card) · `--a-ink` (deep blue-ink) ·
  `--a-dim` · `--a-line` and the four themed hues `--a-arc` (architect indigo — the house lead, the role oxide-red
  plays on `/bcs`) · `--a-avail` (availability green — the nines/arithmetic) · `--a-mesh` (EchoMesh violet — the
  heart) · `--a-edge` (edge amber — the line drawn outside the runtime); evidence blocks on `--a-term-bg`.
- Type: system stacks only — `--mono` (ui-monospace first) for ids, headers, labels, evidence; `--sans` for body
  prose. Nothing fetched.
- Devices: the **nines-rule** (`.ninerule`, the availability strip — the role the 3/11 `.idrule` plays on `/bcs`), the
  borrowed-availability **calculator** figure, triptych grids, `.sech` numbered section headers with source labels,
  `figure.frozen` evidence blocks, the rich `.door` course-to-course reference blocks.
- **MUST NOT:** the dark-editorial navy/cream/gold palette, Cormorant Garamond / PT Serif / Manrope, the `.chap` /
  `.mods` / `.mod` card grid; and MUST NOT clone the `/bcs` warm oxide-red `--b-*` tokens verbatim — The Art of BCS is
  the `--a-*` blueprint adaptation.

The two mandatory layout rules (drift source — enforce on every page):

1. **Clickable segmented route-tag.** Intermediate path parts are `<a href>` to that route level, the current part is
   `<span class="rcur">`, separated by `<span class="rsep">/</span>`; `/art` is one segment; the site root `/` is
   never a segment.
2. **Canonical 3-column footer.** `footer.site-foot` → `.foot-nav` (brand + chapters column + courses column) +
   `.foot-bar` with the `.stamp` + decoder (verbatim from the exemplar; a valid **`ART…`** id).

## 8. Voice

Visible prose and code comments never contain *revolutionary, blazing, magical, simply, just, obviously, effortless*;
no exclamation marks, no emoji, no first person, no perceptual or interior-state verb applied to a tool, an agent, or a
software component (a runtime / broker / coordinator / mesh does not "see" / "want" / "decide"). Active voice, short
sentences, one idea per section. The course's claim is **narrow and measured** — never anti-cloud zealotry; state the
cloud's case fairly (its own published SLAs) before declining it.

```bash
grep -nE '\b(just|simply|obviously|effortless|magical|revolutionary|blazing)\b' html/art/<path>.html
```

## 9. Branded Snowflake build stamp — the course's own namespace

Every page carries the footer `.stamp` + decoder (copied verbatim from the exemplar). The id is a 14-char **`ART…`**
form — the course stamps in its **own namespace** (the manuscript's identity rule applied to the course itself). Mint
fresh per page and verify the round-trip:

```bash
apps/jonnify-cms/bin/cms stamp mint --ns ART     # → ART0Nz1UqsfWC0 (e.g.)
apps/jonnify-cms/bin/cms stamp decode ART0Nz1UqsfWC0
```

Epoch `1704067200000`; layout `ts(41)<<22 | node(10)<<12 | seq(12)`. Update the panel's static `timestamp` dd to the
decoded value (the no-JS fallback).

## 10. The authoring workflow (spec-first; per chapter or dive)

1. **Read the manuscript chapter AND the TOC entry (and the triad, once it exists).** The TOC names the chapter, its
   route slug, its three dives, and its grounding. The manuscript chapter (`art[N].md` / `art[N][D].md`) is the content
   spine. Read it and the evidence it rests on (the cited sources; for Parts VI/VIII the Exchange-exemplar gate
   records). **Never author ahead of the manuscript, and never paraphrase a figure into a fabricated number.**
2. **Author md-first, then the HTML.** Write `docs/echo/art/markdown/<route>.md`, then build the page copying the
   design system from a built ART page of the same surface (bootstrap: the A0 landing). Mint a fresh `ART…` stamp.
   Quote evidence in `figure.frozen` blocks, source-labelled.
3. **Relink the parent landing** (orchestrator-only when fanning out) — flip the chapter/dive's non-anchor `soon` card
   to a live `<a>` card. Keep full links PASS: link only routes that now exist.
4. **Gate every page** to STATUS: PASS; adversarially read the gate-invisible bits (clamp, route-tag, figure
   provenance, no dark-editorial or verbatim-`/bcs` token leak: `grep -n 'Cormorant\|Manrope\|PT Serif\|--b-paper\|--b-ns' <page>`).
5. **Sync the TOC** — mark the chapter/dive built in `docs/echo/art/art.toc.md` so the views agree.

When fanning out to background agents (one per chapter or per dive), give each: this skill, a built ART model page, the
exact route + numbering + the manuscript chapter + grounding files, the gate command, the verbatim-figure guard, the
forward/living-status rule (EchoMesh PROPOSED), and an explicit **no-git** constraint. Then adversarially verify their
output yourself.

## 11. Spec system & course map

The structure is settled **specs-first** before any page: the TOC maps, the manuscript is the content spine, and page
authoring expands it faithfully. See `references/course-map.md` for the A0–A10 chapter/route/status table and the
resume point. Do not write redundant status prose ("all built", "complete") into nav pages — the cards' chips already
show status; describe structure and the arc instead. **Never run git** in an authoring agent — leave changes in the
working tree; the operator commits batches out-of-band. Never edit the manuscript (`docs/echo/art/art*.md`) — it is
the Author/Operator's.
