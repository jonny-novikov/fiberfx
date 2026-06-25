---
name: redis-course-writer
description: "Use this skill to author or continue the course 'Redis Patterns Applied' served at /redis-patterns — rendered in the BCS contract-sheet identity with the redis-red #d6584f accent (light-paper --b-* tokens + --r-red, mono-forward system fonts, nothing fetched), never the dark-editorial tokens of the sibling courses. Triggers: any request to create, continue, extend, relink, or validate a course home, chapter landing, module hub, deep-dive, or workshop for this course; to grade a page with the jonnify-cms gates; or to wire a new module into a chapter. Every Redis pattern is taught APPLIED — grounded in the real as-built echo data layer (EchoMQ backed by Valkey + EchoStore in front: echo/apps/echo_mq, echo/apps/echo_store, echo/apps/echo_wire) and worked through codemojex consumer (echo/apps/codemojex — Codemojex.Guesses / Codemojex.Board / Codemojex.ScoreWorker), never invented, never from .out transcripts, and with NO mention of BullMQ — the course opens doors to the dedicated /echomq and /bcs courses. The deliverable is always a self-contained static HTML page graded A+ across the ten gates (the nine Apollo gates + the refs mandate), authored into the existing design system and spec system — never a rebuild of either. Do NOT use for the /elixir course (elixir-course-writer / elixir-technical-writer), the /course/agile-agent-workflow course (agile-course-writer), the /bcs course (bcs-course-writer), the /echomq course (echo-mq-writer), other jonnify sections, or generic documents."
---

# Authoring the jonnify "Redis Patterns Applied" course

> **⚠ BCS CALIBRATION (2026-06-25) — the figure source moved.** The committed BCS manuscript figures now live in
> **`docs/echo/bcs/bcs.N.md`** (B0–B8); the old `docs/echo/bcs/content/bcs3.*` / `bcs4.*` / `bcsA.md` paths cited
> below are **retired** (the directory is absent). Cite the `bcs.N.md` chapter that owns the figure — the chapter →
> figure map is in **`bcs-writer`**'s `references/bcs-canon.md` (id vectors → `bcs.0`/`bcs.2`; EchoStore → `bcs.4`;
> the persistence floor → `bcs.5`; codemojex → `bcs.7`). EchoStore + codemojex grounding here is already current; the
> cross-course BCS-direction run is **`/bcs-reconcile R<N>`**.

This skill authors the course served at **`/redis-patterns`**: the 30 Redis design patterns, taught **applied to
the BCS architecture** — each grounded in the **real as-built echo data layer**: **EchoMQ** (the owned protocol)
backed by **Valkey** (`echo/apps/echo_mq/` + the one owned client `echo/apps/echo_wire/`), with **EchoStore** in
front (`echo/apps/echo_store/`), and worked through the **codemojex** consumer (`echo/apps/codemojex/` —
`Codemojex.Guesses` / `Codemojex.Board` / `Codemojex.ScoreWorker`; design corpus `echo/apps/codemojex/`) — opening doors to
the dedicated `/echomq` and `/bcs` courses. EchoMQ-in-production IS the advanced application of these Redis
patterns; keep the focus on the pattern. Three sources of truth govern, and where this skill disagrees with them,
they win:

1. **The spec system** under `docs/redis-patterns/` is the source of truth for *structure and grounding* — the
   [`redis-patterns.toc.md`](../../../docs/redis-patterns/redis-patterns.toc.md) (the chapter→module→dive tree), the
   [`redis-patterns.roadmap.md`](../../../docs/redis-patterns/redis-patterns.roadmap.md) (the canonical
   pattern→EchoMQ grounding map), the contract
   [`specs/redis-patterns.md`](../../../docs/redis-patterns/specs/redis-patterns.md), and the per-chapter specs +
   per-module quads. **Author a page only from its spec; never invent structure.**
2. **The reframe contract**
   [`specs/reframe-echomq/reframe-echomq.md`](../../../docs/redis-patterns/specs/reframe-echomq/reframe-echomq.md)
   is the source of truth for the *identity and the re-grounding* — the contract-sheet token swap + the dark→light
   class map, the `.door`/`.bridge`/`.vnote` devices, the figure inventory, the no-BullMQ + naming law, the
   narrative retarget, and the gate mounts. The rung sequence is
   [`reframe-echomq.roadmap.md`](../../../docs/redis-patterns/specs/reframe-echomq/reframe-echomq.roadmap.md).
3. **The Go `jonnify-cms` binary** is the source of truth for the gates and the resolvable routes. Where this skill
   and the tool disagree, run the tool — it wins.

This course renders in **the BCS contract-sheet identity with the redis-red `#d6584f` accent**: the light-paper
`--b-*` tokens plus `--r-red`, mono-forward SYSTEM font stacks with **nothing fetched**, `figure.frozen` evidence
blocks, the 14-cell `.idrule`, `.sech` numbered section headers — never the dark-editorial tokens of `/elixir` and
`/course/agile-agent-workflow`. The identity authority is the reframe contract (above); the model to copy is
`html/redis-patterns/index.html`. **The reframe is in progress:** R0 is reframed (the model); R1–R4 are
mid-migration (still dark-editorial until rungs `re2`–`re5`) — never copy identity from an unreframed page. The
shared craft in `.claude/skills/elixir-technical-writer/references/` still applies for the prose discipline, the
interactive/visualization rules, and the page-anatomy *shape* (`visualization-master.md`, `technical-writer.md`,
`page-anatomy.md`, `references-section.md`); its `design-tokens.md` is superseded by the contract sheet. THIS
skill documents only what is *different* for the redis course: its spec system, its BCS-grounding boundary, its
page surfaces, and its gate command.

## 0. Two standing rules

1. **Reuse, do not reinvent.** The design system, the routing, the Snowflake convention, the validator, and the spec
   system all exist and are proven. Author content *into* them — never rebuild a system or introduce a library.
2. **Validate without images.** Validation is headless and text-only: `cms check` + reading the markup + an optional
   `curl`/`python3` route crawl. Never screenshot.

## 1. Where to work

| Path | Role |
|---|---|
| `html/redis-patterns/` | The served course. Whole hand-authored HTML files; the URL tree mirrors the dir tree (`serveDirTree`, read live — a new `.html` is live on save, no rebuild). |
| `docs/redis-patterns/redis-patterns.toc.md` | The living **TOC** — the chapter→module→dive tree + per-module abstracts + status. The structural map. |
| `docs/redis-patterns/redis-patterns.roadmap.md` | The **program roadmap** + the **grounding map** (which pattern is grounded in which real EchoMQ key/command/Lua script, echo-data-layer module, or `Codemojex.*` consumer surface). Cite these; never invent. |
| `docs/redis-patterns/specs/redis-patterns.md` | The **contract** — the page surfaces, the chapter-landing anatomy, the ten gates, the no-invent rule, the chapter map. |
| `docs/redis-patterns/specs/reframe-echomq/reframe-echomq.md` | The **reframe contract** — the identity authority: the contract-sheet token swap + dark→light class map, the `.door`/`.bridge`/`.vnote` devices, the **figure inventory**, the no-BullMQ + naming law, the gate mounts. The rung sequence: `reframe-echomq.roadmap.md`. |
| `docs/redis-patterns/specs/<chapter>/<chapter>.md` | The **chapter spec** — the module ladder a page batch builds from. R0 (`overview/`) is taken deep: a chapter index + `r0.md` roadmap + per-module **quads** (`r0.M.md` / `.stories.md` / `.llms.md` / `.prompt.md`). |
| `apps/jonnify-cms/bin/cms` | The **validator** (Go). Build: `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .`. |
| `.claude/skills/elixir-technical-writer/references/` | The SHARED craft (visualization, voice, page-anatomy shape; its `design-tokens.md` is superseded by the contract sheet). |
| `references/course-map.md` (this skill) | The R0–R8 chapter/route/status map + the resume point. |

## 2. The product and the running grounding

A course of interconnected **static HTML** pages: no framework, no runtime, no CDN, no browser storage, nothing
fetched. The running grounding is the **real as-built echo data layer** — the code, never specs, **never `.out`
files**: **EchoMQ** (`echo/apps/echo_mq/` — `Jobs` / `Lanes` / `Consumer` / `Keyspace` + the Lua scripts; the
owned protocol, the braced `emq:{q}:` keyspace, every Lua key declared) **backed by Valkey** via the one owned
client **EchoWire** (`echo/apps/echo_wire/` — `EchoWire`, `EchoMQ.Connector`, EVALSHA-first, the `echomq:3.0.0`
version fence), with **EchoStore** in front (`echo/apps/echo_store/` — `Ring` / `Table` / `Journal` / `Coherence`;
L1 ETS + L2 Valkey), worked through the **codemojex** consumer (`echo/apps/codemojex/`). Supplement with the
committed BCS manuscript figures `docs/echo/bcs/content/bcs3.*` / `bcs4.*` / `bcsA.md` and the spec
`docs/echo_mq/emq.design.md`; the reframe contract's **figure inventory** licenses what may appear — every figure
verbatim from a committed source. **`.out` rung transcripts are NOT course material:** never cite a `.out` file or
a "PASS N/N" gate dump as a page figure — teach the PATTERN from the real code. **NO mention of BullMQ at all:**
the course contains zero BullMQ references; never "BullMQ-compatible", never a "lineage note", never the `bull:`
keyspace, never bullmq.io in Sources, **never Dragonfly** — the engine is **Valkey only**. Always write
**"EchoMQ"** — no version label in prose ("EchoMQ 2.0"/"EchoMQ 3.0"/"v1 line" all out); `echomq:3.0.0` (the as-built `@wire_version`) appears only as a quoted wire string inside
a frozen figure). The queue, coordination, and time families ground in `echo/apps/echo_mq/`; the cache family in
`echo/apps/echo_store/` (and `bcs4.*`); modeling grounds in clean standalone examples. Where a chapter's deeper
implementation belongs to the protocol itself, it links forward to the **dedicated EchoMQ course** (`/echomq`).

## 3. The structure — three levels and four page surfaces

Three levels, `R<chapter>.<module>.<dive>` (course letter **R**):

- **Chapter** `R[N]` (R0…R8) → a landing `<chapter>/index.html` (route `/redis-patterns/caching`). Slugs are the
  eight `specs/` folders: `caching · coordination · queues · time-delay-priority · streams-events · flow-control ·
  data-modeling · production-operations` (R1–R8); R0 is `overview`.
- **Module** `R[N].[M]` → a hub `<chapter>/<module>/index.html` (route `/redis-patterns/caching/cache-aside`).
- **Dive** `R[N].[M].[S]` → a deep-dive `<chapter>/<module>/<sub>.html` (≥3 per module).

Four **page surfaces**. Copy the design system **from a REFRAMED redis page of the same surface**:
`html/redis-patterns/index.html` for the home and the manifest surfaces; the R0.3
`overview/patterns-become-protocol/` hub + dives for hubs and dives. The one-time bootstrap *from BCS*
(`html/bcs/index.html`) happened at `re0` — never bootstrap again, and never copy identity from a dark-editorial
R1–R4 page while those chapters are mid-migration. The layouts each surface adopts:

- **The course home** (`/redis-patterns` → `index.html`) — the contract-sheet bootstrap and the canonical model:
  a hero (`.kicker`, the `--r-red` accent span, the `.idrule`), a "how to read this", and **the map** (the full
  chapter→module directory: a `.chap` section per chapter over a `.mods` grid of its module cards). The home
  carries the whole course; there is no separate contents page.
- **A chapter landing** (`<chapter>/index.html`) — the teaching arc: **overview → why & when (use cases) → what (the
  patterns, as module cards) → how to apply → the EchoMQ exemplar workshop**, closing with an **"Up next" grid**
  (`.upnext`, the home's chapter cards for the chapters that follow — none up to and including this one). R0's
  overview landing is the orientation variant (its module cards + the "Up next" grid).
- **A module hub** (`<chapter>/<module>/index.html`) — the module's framing + its ≥3 dive cards.
- **A dive** (`<chapter>/<module>/<sub>.html`) — a full lesson (see §5).

**The home and every chapter landing are route manifests that reach a FULL links-PASS** (the BCS philosophy — no
fail-by-design): a built chapter/module is an anchor card `<a class="mod" href="…">`, an unbuilt one is a
**non-anchor** card `<div class="mod">` with the `soon` pill — nothing dangles, and every lesson/hub page keeps
all internal links resolving. The shared card classes are `.chap · .chap-head · .cid · .mods · .mod · .num ·
.pill · .t · .o · .chap-link · .c-one` (class names kept for the relink tooling; copy the restyled rules from
`html/redis-patterns/index.html`).

## 4. The running argument — "Redis Pattern Applied", and the grounding boundary

Where `/elixir` bridges *an idea → its Elixir form* (the functional-Elixir & OTP craft behind the echo umbrella),
this course bridges **a Redis pattern → its real application in the echo data layer**. Every pattern lands twice:
the pattern (problem → solution → trade-offs → when-to-use) and the concrete move it becomes in EchoMQ / EchoStore /
the codemojex consumer. Make that correspondence explicit with the `.bridge` block (the pattern cell → the real
application cell — the right cell always names the EchoMQ / EchoStore / `Codemojex.*` application), closed by a
`.take`; the page's `.door` then surfaces the Valkey specific/tuning + the `emq:{q}:` application.

**The grounding rule (the master discipline).** Each module cites **one tight, real excerpt** as proof, verbatim
from a real as-built surface (or a committed figure the reframe contract's figure inventory licenses): a real
EchoMQ key (`emq:{q}:` form), a script verb of the eight (`enqueue`, `browse`, `pending_size`, `claim`, `complete`,
`retry`, `promote`, `reap`), the `attempts` fencing token (`HINCRBY`), an `echo/apps/echo_store/` figure (or
`bcs4.*`), an `Codemojex.*` consumer call, or a Valkey-documented command (`SET … PX`) — or, where the pattern is
not an EchoMQ one (modeling family), a clean standalone example. **The grounding map in
`redis-patterns.roadmap.md` is authoritative for which pattern lands where; the figure inventory in
`reframe-echomq.md` is authoritative for what may be quoted.** Never quote a `.out` rung transcript or a gate dump.
`redlock` and `probabilistic-data-structures` are taught as **contrasts**, not as something EchoMQ implements.

**No invention.** Cite only real surfaces. Do not invent a Redis/Valkey command, a Lua script, an EchoMQ module, or
an echo-data-layer / `Codemojex.*` surface — **verify on disk in `echo/apps/`**. The EchoMQ implementation *depth*
(the full Lua bundle, the version-fence internals, the protocol governance) belongs to the dedicated EchoMQ course;
a module that drifts into it links forward instead of teaching it.

## 5. Page anatomy & the interactive contract

The shared anatomy *shape* (`elixir-technical-writer/references/page-anatomy.md`) rendered in the contract sheet,
authored as a full HTML file: skip link → `<header class="top">` — scope the sticky rule **`header.top{…}`, NOT
bare `.top`**: the `.mod` cards reuse `<div class="top">` for their num+pill row, and a bare
`.top{position:sticky}` rule makes every card row float over the header — with a `.route-tag` = this page's exact
route → a `.hero` (crumbs, `.kicker`, `<h1>` with the `--r-red` accent span, lede) → the 14-cell `.idrule`
(`aria-hidden`) → teaching `<section>`s headed by `.sech` (the `§n` `.sno` in `--r-red`, mono uppercase title, the
`.ssrc` right slot citing the grounding file), each holding `.prose` + an interactive figure + a
**`figure.frozen`** (dark terminal, figcaption + `frozen` tag) for verbatim committed output / a light bordered
`pre` for didactic blocks + a live `.readout` + a closing `.take` (concept pairings use `.bridge`) → **one
`.door`** after the main teaching section (the Valkey specific/tuning + the `emq:{q}:` application; a
source-labelled `figure.frozen` where a committed figure exists) and ≥1 **`.vnote`** ("notes on Valkey": one
engine fact + its valkey.io citation) where a Valkey fact applies → a **References** section
(`<section id="refs">`, mandatory, gate #10) → a `.pager` → the footer with the `.stamp`. Each page carries ≥1
interactive that **performs the real operation and shows its actual result** over a fixed dataset — see
`elixir-technical-writer/references/visualization-master.md` for the rules. **Every interactive figure follows the
hover-select pattern** of `/bcs/ideas/system-substrate` (exemplar: the `.lstack` figure in
`html/redis-patterns/overview/patterns-become-protocol/the-four-layers.html`): a `.segbar` of buttons + an SVG
whose `g[data-…]` groups highlight on **hover AND click** (the `.focus`/`.on` classes dim the others) with a live
`.readout` — SHORT labels inside the diagram, the full detail in the readout, never long centered SVG text that
overlaps. Keep ≥1 `svg` per page.

### 5a. Source fidelity, the References block, and the route-mirrored md (three binding rules)

Every pattern module is built on its **author source** — `docs/redis-patterns/content/<section>/<pattern>.md.txt`
(the rendered `.html` sits beside it). Three rules are non-negotiable:

1. **The source is the content spine.** The module **hub** (the pattern page) **leads with the source's opening
   summary line** as its `.lede` (cache-aside: *"Use cache-aside for read-heavy workloads: on a cache miss, fetch
   from the database and populate the cache; on a write, invalidate or update the cache explicitly."*), then presents
   the **source's `##` sections, in the source's order**, as the page's `<section>`s — for cache-aside:
   `How It Works` → `Redis Commands Used` → `Advantages` → `The Staleness Problem` → `Mitigating Staleness` →
   `When to Use` → `When to Avoid`. The jonnify framing, the interactives, the `.bridge`, and the EchoMQ /
   EchoStore / codemojex grounding layer **on top of** that spine — they never replace it or precede the source
   summary. The module's dive
   cards and a closing recap follow the source sections; References closes the page. The
   [content-map](../../../docs/redis-patterns/redis-patterns.content-map.md) names the source file + per-section
   techniques for each module.

2. **References is a two-column block.** `<div class="refs">` holds **two child `<div>`s** side by side —
   `<h3>Sources</h3>` and `<h3>Related in this course</h3>` — with
   `.refs{display:grid;grid-template-columns:1fr 1fr;gap:1.4rem 2.4rem}` (collapse to one column under ~680px). Never
   a single stacked column.

3. **Every page has a route-mirrored md, authored first.** Write the page **md-first** at
   `docs/redis-patterns/markdown/<route>.md` — the served route minus the `/redis-patterns/` prefix with `.md`
   appended (`/redis-patterns/caching/cache-aside` → `docs/redis-patterns/markdown/caching/cache-aside.md`). It is the
   source-of-record the HTML reflects: the page's prose in clean markdown — the source-faithful spine (summary lede +
   the `##` sections in order) + the jonnify grounding + a `## References` with `### Sources` / `### Related in this
   course`. Author the md, then build the HTML to match it. Exemplar of the depth:
   `docs/redis-patterns/markdown/caching/branded-cache-aside.md`.

## 6. The ten gates

`containers · svg · no-future · voice · storage · motion · degrade · links · pager · refs` (refs opt-in via
`--require-refs`). Build the validator, then run on every page:

```bash
apps/jonnify-cms/bin/cms check \
  --routes-from /redis-patterns=html/redis-patterns \
  --routes-from /echomq=html/echomq --routes-from /bcs=html/bcs --routes-from /elixir=elixir \
  --chapter-alias r1=caching,r2=coordination,r3=queues,r4=time-delay-priority,r5=streams-events,r6=flow-control,r7=data-modeling,r8=production-operations \
  --require-refs html/redis-patterns/<path>.html
```

The cross-course mounts are mandatory: reframed pages carry `/echomq` + `/bcs` doors, and the cms `links`
allowlist knows `/elixir` but not `/bcs`/`/echomq` — without the mounts the door links read as dangling.

Ship only at **STATUS: PASS**. Checks the gates cannot see, verified by reading: **clamp spacing**
(`clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` — spaces around `+`/`-`, or the declaration drops to a UA default);
**right-route-vs-resolvable** (the `links` gate proves an href resolves, not that it is the intended parent — read
crumbs and pager); the **font-leak grep empty** (`Cormorant\|Manrope\|PT Serif\|JetBrains\|fonts.googleapis` —
nothing fetched); the **no-BullMQ scrub greps UNCONDITIONALLY empty** —
`grep -rniE 'bullmq|bull:|dragonfly' <path>` must return nothing (zero allowance: no lineage note, no `bull:`
keyspace, no Dragonfly; the engine is Valkey only); **no `.out` transcript cited** (`grep -nE '\.out\b' <path>`
empty — `.out` rung dumps are not course material); every quoted figure re-found in a real `echo/apps/` surface or
its committed BCS source. The home and chapter landings are manifests that reach a **full PASS**: unbuilt
chapters/modules are non-anchor `<div class="mod">` cards with the `soon` pill, built ones `<a class="mod">` — no
fail-by-design.

## 7. The two mandatory layout rules (drift source — enforce on every page)

1. **Clickable segmented route-tag.** The header `.route-tag` renders each path part as its own element —
   intermediate parts are `<a href>` to that route level, the current part is `<span class="rcur">`, separated by
   `<span class="rsep">/</span>`; `/redis-patterns` is one segment.
2. **Canonical 3-column footer.** `<footer class="site-foot">` → the 3-column `.foot-nav` + the `.foot-bar`
   carrying the `.stamp` + decoder script (verbatim; a valid `TSK…` Snowflake id; the contract-sheet `.stamp` is
   the dark popover decoder). The way to satisfy both without thinking: **copy the `<head>`…`</style>`,
   `<header>`, `<footer>`, and the trailing `<script>` blocks verbatim from a REFRAMED model page**
   (`html/redis-patterns/index.html` or an R0.3 page of the same surface), then change only `<title>`/`<meta>`,
   the route-tag, and `<main>`.

## 8. Voice

Visible prose and code comments never contain *revolutionary, blazing, magical, simply, just, obviously,
effortless*; no exclamation marks, no emoji, no first person ("I"/"we"/"our"), no perceptual or interior-state verb
applied to a tool or an agent. Active voice, short sentences, one idea per section.

```bash
grep -nE '\b(just|simply|obviously|effortless|magical|revolutionary|blazing)\b' html/redis-patterns/<path>.html
```

## 9. Branded Snowflake build stamp

Every page carries the footer `.stamp` + decoder (copied verbatim). The id is a 14-char `TSK…` form: 3-letter
namespace + base62(snowflake) padded to 11; epoch `1704067200000`; layout `ts(41)<<22 | node(10)<<12 | seq(12)`.
Reusing an existing valid id is fine (the decoder decodes whatever is in `#stampId`).

## 10. The authoring workflow (spec-first; per module)

1. **Read the spec AND the author source.** The chapter spec (`specs/<chapter>/<chapter>.md`) names the module, its
   pattern slug, its real grounding, and its dives; for a deepened module, read its quad and run its `.prompt.md`.
   **Then read the author source** `docs/redis-patterns/content/<section>/<pattern>.md.txt` (the content-map names
   which) — it is the **content spine** (§5a): its opening summary becomes the hub's lede, its `##` sections become
   the hub's sections in order. **Never author ahead of the spec, and never paraphrase past the source.**
2. **Author md-first, then the HTML.** Write the page's md at `docs/redis-patterns/markdown/<route>.md` (§5a rule 3)
   — the source-faithful spine + the jonnify grounding + a 2-column `## References`. Then build the **module hub**
   `<chapter>/<module>/index.html` to match it (the source summary as `.lede`; the source `##` sections in order;
   References as a two-column `.refs` block, §5a rule 2), and **each dive** `<chapter>/<module>/<sub>.html`. Copy the
   design system verbatim from a REFRAMED model page (never a dark-editorial R1–R4 page mid-migration); ground the
   worked example in the artifact the roadmap's grounding map names, quoted verbatim from the figure inventory's
   committed sources; add the `.bridge` (pattern ↔ EchoMQ/EchoStore application), the page's `.door`, ≥1 `.vnote`
   where a Valkey fact applies, and ≥1 hover-select interactive **on top of** the source spine.
3. **Relink the chapter landing** (orchestrator-only when fanning out) — turn the module's non-anchor
   `<div class="mod">` card into `<a class="mod" href="…">` and flip its pill `soon`→`built`; the manifests stay
   at a full links-PASS.
4. **Gate every page** to STATUS: PASS (with the cross-course mounts); adversarially read the gate-invisible bits
   (clamp, route-tag, `header.top` scoping, crumbs/pager parent, the font-leak + the unconditionally-empty
   no-BullMQ scrub greps, no `.out` transcript cited, no invented echo-data-layer / `Codemojex.*` surface — run
   `grep -rnoE '(Codemojex|EchoMQ|EchoStore|EchoWire)\.[A-Za-z.]+' <path>` and cross-check every hit on disk in
   `echo/apps/`, and re-find every quoted figure in its real `echo/apps/` surface or its committed BCS source
   `docs/echo/bcs/content/` + `docs/echo_mq/emq.design.md`).
5. **Sync the TOC** — mark the module built (route + dive list) so the views agree.

When fanning out to background agents (one per module or per dive), give each: this skill, a REFRAMED model page,
the exact route + numbering + the module's spec + grounding, the gate command (with the cross-course mounts), the
no-invent guard + the no-BullMQ naming law, and an explicit **no-git** constraint. Then adversarially verify their
output yourself.

## 11. Spec system & course map

The structure is settled **specs-first** before any page (the `echo/CLAUDE.md` discipline): the TOC maps, the
roadmap plans and fixes the grounding, the chapter specs define, and page authoring expands a spec faithfully. See
`references/course-map.md` for the R0–R8 chapter/route/status table and the resume point. Do not write redundant
status prose ("all built", "complete") into nav pages — the cards' pills already show status; describe structure and
the arc instead. **Never run git** in an authoring agent — leave changes in the working tree; the operator commits
batches out-of-band.
