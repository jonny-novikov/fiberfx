---
description: redis-write — fan out redis-expert subagents to author a redis-patterns chapter's pages (landing, module hubs, dives, workshop) in parallel, then build/relink the manifest pages + adversarially gate + sync the TOC
argument-hint: <chapter-slug> <module-slug>[:dive1,dive2,dive3] [<module-slug>[:dives] …]  (e.g. caching cache-aside write-through cache-stampede-prevention)  ·  or `overview` for the R0 home + landing + dives
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep, Skill, AskUserQuestion
model: opus
---

# /redis-write — parallel page authoring for the "Redis Patterns Applied" course

You are orchestrating a **parallel authoring batch** for the jonnify "Redis Patterns Applied" course (served at
`/redis-patterns`). Fan out one **`redis-expert`** subagent per module, then perform the **orchestrator-only** steps
the subagents are forbidden from doing (author/relink the shared **manifest** pages — the home map and the chapter
landing — and sync the TOC). The craft's source of truth is the **`redis-course-writer`** skill; the *structure and
grounding* are the **spec system** — the TOC (`docs/redis-patterns/redis-patterns.toc.md`), the roadmap + grounding
map (`docs/redis-patterns/redis-patterns.roadmap.md`), the contract (`docs/redis-patterns/specs/redis-patterns.md`),
and the per-chapter specs; the *identity and re-grounding* are the **reframe contract**
(`docs/redis-patterns/specs/reframe-echomq/reframe-echomq.md` — the BCS contract-sheet identity with the redis-red
accent, the `.door`/`.bridge`/`.vnote` devices, the figure inventory, the no-BullMQ + naming law). **Author only
from the spec; never invent structure or grounding.**

## Arguments

```
$ARGUMENTS
```

Parse the argument string as whitespace-separated tokens:

- **Token 1 = the chapter.** A chapter **dir slug** (`caching`, `coordination`, `queues`, `time-delay-priority`,
  `streams-events`, `flow-control`, `data-modeling`, `production-operations`) or an `R<N>` number you resolve to its
  slug via the skill's `course-map.md`. **Special: `overview` (or `r0`)** = the R0 set (the home `index.html` +
  the overview landing `overview/index.html` + R0.2 `redis-under-portal` + R0.3 `patterns-become-protocol`) — all
  BUILT; the home, the overview landing, and R0.3 are reframed to the contract-sheet identity (`re0`), R0.2's
  reframe is rung `re1`. Reframing already-built pages follows
  `docs/redis-patterns/specs/reframe-echomq/reframe-echomq.roadmap.md`, not this command's authoring flow.
- **Tokens 2…N = one module each**, `<module-slug>` or `<module-slug>:<dive1>,<dive2>,<dive3>`. The **chapter spec**
  (`specs/<chapter>/<chapter>.md`) names each module's number, **pattern slug**, **grounding artifact**, and dives;
  the optional `:`-list overrides the dive slugs (**≥3**). If a module has been deepened into its own **triad**
  (`specs/<chapter>/r<N>.<M>.{md,stories,llms}`, plus a `.prompt.md` for specific cases), the agent builds from that;
  otherwise it builds from the chapter-spec module row.

If the arg string is empty, or only the chapter is given, **do not guess** — read the chapter spec's module ladder
and either author every module in it or `AskUserQuestion` which to author.

## Step 0 — Ground the batch (read-only)

1. Invoke the **Skill tool with skill `redis-course-writer`**; read its `references/course-map.md` (chapter table,
   the chapter-landing anatomy, the resume point).
2. Read the chapter spec `specs/<chapter>/<chapter>.md` (the module ladder + grounding + dives), the chapter's TOC
   section (`redis-patterns.toc.md`), and the **grounding map** in `redis-patterns.roadmap.md` — the real EchoMQ
   key/command/Lua/Go function (or echo-data-layer/Exchange surface) each requested pattern is grounded in.
3. For each requested module resolve: its number `R[N].[M]`, pattern slug, **grounding artifact**, served route,
   dive slugs (from args / the spec / to-design), whether it has a per-module triad/prompt, and its
   dependency-ordered position (for the pager + the build order).
4. **Pick the model page per surface — copy the design system from a REFRAMED redis page; never from a
   dark-editorial one.** The course renders in the BCS contract-sheet identity with the redis-red `#d6584f` accent
   (light-paper `--b-*` tokens + `--r-red`, mono-forward SYSTEM fonts, nothing fetched; the identity authority is
   `docs/redis-patterns/specs/reframe-echomq/reframe-echomq.md`):
   - **home · chapter landing (the manifest surfaces)** → `html/redis-patterns/index.html` (the contract-sheet
     bootstrap and the canonical model).
   - **module hub · dive** → the R0.3 `overview/patterns-become-protocol/` hub + dives
     (`the-four-layers.html` is the hover-select figure exemplar).
   The one-time bootstrap *from BCS* (`html/bcs/index.html`) happened at `re0` — never bootstrap again. **R1–R4
   are mid-migration** (still dark-editorial until rungs `re2`–`re5`); do not pick them as models. Every page
   copies from a reframed redis page, changing only `<title>`/`<meta>`, the route-tag, and `<main>`.

## Step 1 — De-risk shared dependencies (once)

- Build the validator: `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .` (GOWORK=off mandatory).
- The cms gate runs from the **filesystem** (`--routes-from /redis-patterns=html/redis-patterns`), so it needs no
  running server. A **live route crawl** does: `curl -s -o /dev/null -w '%{http_code}' http://localhost:8765/redis-patterns`.
  If the `/redis-patterns` route is **not yet wired into the server** (the Stage-2 5-file checklist: `main.go`,
  `Dockerfile`, `Makefile`, the `folderRouted` slice in `cmd/sitemap/main.go`), pages still author + gate fine, but
  the live crawl will 404 — note that the wiring is a prerequisite for the live crawl, not for authoring.
- Confirm `html/redis-patterns/<chapter>/` exists (create the dir if needed).

## Step 2 — Author the manifest landing first, then fan out the modules

**The home map (`index.html`) and the chapter landing (`<chapter>/index.html`) are ROUTE MANIFESTS** — the
orchestrator (you) authors/relinks them, never the parallel agents, to avoid a parallel-write conflict on the shared
file. If the chapter landing does not exist, author it first. For **R1–R8** the chapter-landing anatomy is
**overview → why & when (use cases) → what (the module cards) → how to apply → the EchoMQ exemplar workshop**,
closing with the **"Up next" grid** of the chapters that follow. For **R0** the home + overview landing instead
follow `specs/overview/r0.1.prompt.md` (the orientation variant: the map / module cards + "Up next", no workshop).
Spawn one `redis-expert` for it, or author it yourself from the spec.

Then spawn **one agent per module, all in a single message** so they run concurrently. Use
`subagent_type: "redis-expert"`; **if that errors "agent type not found"** the def is not loaded this session — fall
back to `subagent_type: "general-purpose"` (the redis-expert brief below is self-contained). Give each agent:

- its **module number, pattern slug, slug, served route**, and the **dive slugs** (or "design ≥3 from the chapter
  spec");
- its **grounding artifact** from the grounding map, quoted VERBATIM from the **real as-built echo data layer** —
  `echo/apps/echo_mq` (EchoMQ — `Jobs`/`Lanes`/`Consumer`/`Keyspace` + the inline Lua; the braced `emq:{q}:`
  keyspace), `echo/apps/echo_cache` (EchoCache — `Ring`/`Table`/`Journal`/`Coherence`), `echo/apps/echo_wire` (the
  EchoWire connector — `EchoMQ.Connector`, EVALSHA-first, the `echomq:2.0.0` fence) — and the **Exchange Platform**
  consumer (`echo/apps/exchange` — `Exchange.Gateway`/`Exchange.OrderBook`/`Exchange.Decider`), plus the committed
  BCS figures the reframe contract's **figure inventory** licenses (`docs/echo/bcs/content/bcs3.*` / `bcs4.*` /
  `bcsA.md` + `docs/echo_mq/emq.design.md`) — and the instruction to **re-find every figure on disk in its real
  source before citing**, to **never cite a `.out` rung transcript** (NOT course material), to invent nothing
  (no fabricated Redis/Valkey command, Lua script, EchoMQ module, or echo-data-layer/Exchange surface), and to obey
  the **no-BullMQ + naming law** (the course contains **NO mention of BullMQ at all**; never "BullMQ-compatible",
  never the `bull:` keyspace, never bullmq.io, **never Dragonfly** — the engine is Valkey only; write "EchoMQ", never
  "EchoMQ 2.0" as a recurring label);
- its **author source** `docs/redis-patterns/content/<section>/<pattern>.md.txt` (the
  [content-map](docs/redis-patterns/redis-patterns.content-map.md) names it) — **the content spine**: the hub LEADS
  with the source's opening summary as its `.lede`, then follows the source's `##` sections in the source's order
  (cache-aside: How It Works → Redis Commands Used → … → When to Avoid); the framing, interactives, `.bridge`, and
  grounding layer ON TOP, never replacing or preceding the source content;
- the **route-mirrored md to author FIRST**: `docs/redis-patterns/markdown/<route>.md` (the served route minus
  `/redis-patterns/`, `.md` appended) — the source-of-record the HTML reflects (the source spine + the jonnify
  grounding + a `## References` with `### Sources` / `### Related in this course`); exemplar depth
  `docs/redis-patterns/markdown/caching/branded-cache-aside.md`;
- the **model page** — a REFRAMED redis page of the same surface (per Step 0.4), with the header-scoping note:
  the sticky header is scoped `header.top{…}`, NEVER bare `.top` (the `.mod` cards reuse `<div class="top">` for
  their num+pill row; a bare `.top` rule makes every card row float over the header);
- its **locked pager** (hub `prev` = chapter landing, `next` = own first dive; dives chain hub → dive1 → dive2 →
  dive3 → hub) + crumbs + `Related in this course` routes;
- the **mandatory rules**: the clickable segmented route-tag; the canonical 3-column footer (`.foot-nav` +
  `.foot-bar`) + `TSK…` stamp; the **two-column References** block (`<div class="refs">` → a `<div>` for
  `<h3>Sources</h3>` and a `<div>` for `<h3>Related in this course</h3>`, side by side via
  `.refs{display:grid;grid-template-columns:1fr 1fr}`) with Sources = ≥3 REAL vetted links (redis.io/docs,
  `redis.io/commands/<cmd>`, `valkey.io/topics/<topic>` / `valkey.io/commands/<cmd>`, github.com/redis,
  antirez.com, llmstxt.org; **never bullmq.io** — the course names no BullMQ source); **two interactives per dive**
  (hero + main, ≥1 on the hub), every figure on the **hover-select pattern** of `/bcs/ideas/system-substrate`
  (exemplar: `html/redis-patterns/overview/patterns-become-protocol/the-four-layers.html` — a `.segbar` of buttons
  + an SVG whose `g[data-…]` groups highlight on hover AND click via `.focus`/`.on`, dimming the others, with a
  live `.readout`; SHORT labels in the diagram, the full detail in the readout; ≥1 `svg` per page) — real
  computation over a fixed dataset, pure functions, degrades without JS, honours `prefers-reduced-motion`, no
  browser storage; the contract-sheet devices — `.sech` headers with the `.ssrc` grounding citation, the 14-cell
  `.idrule`, `figure.frozen` for verbatim committed output, ONE `.door` per page (the Valkey specific/tuning + the
  `emq:{q}:` application), ≥1 `.vnote` where a Valkey fact applies; the `.bridge` (the Redis pattern → its real
  EchoMQ / EchoCache application) + a `.take`; the **voice** rules;
- the **gate command** and **ship only at STATUS: PASS**;
- **hard constraints:** NEVER run git; edit ONLY its own module's files; **do NOT touch the chapter landing or the
  home map** (you relink them in Step 4).

## Step 3 — Adversarially verify (do NOT trust the agents' "all PASS")

For each new page run the gate (in zsh force word-split with `${=FLAGS}`):

```bash
FLAGS="--routes-from /redis-patterns=html/redis-patterns --routes-from /echomq=html/echomq --routes-from /bcs=html/bcs --routes-from /elixir=elixir --chapter-alias r1=caching,r2=coordination,r3=queues,r4=time-delay-priority,r5=streams-events,r6=flow-control,r7=data-modeling,r8=production-operations --require-refs"
apps/jonnify-cms/bin/cms check ${=FLAGS} <page>.html
```

(The cross-course mounts are mandatory: the pages carry `/echomq` + `/bcs` doors, and the cms `links` allowlist
knows `/elixir` but not `/bcs`/`/echomq` — without the mounts the door links read as dangling.)

Then the gate-**invisible** failure modes:

- **No invented surface** (the course's reason to exist): `grep -rnoE '(Exchange|EchoMQ|EchoCache|EchoWire)\.[A-Za-z.]+' <module dirs>`
  and cross-check each on disk, then re-find every quoted figure on the page — key / verb / number / wire string —
  verbatim in its real source (the as-built `echo/apps/echo_mq` · `echo/apps/echo_cache` · `echo/apps/echo_wire` ·
  `echo/apps/exchange`, the committed `docs/echo/bcs/content/`, or `docs/echo_mq/emq.design.md`, per the reframe
  contract's figure inventory); anything not found there is fabricated — fix it. **`.out` rung transcripts are NOT
  course material** — a page citing a `.out` file or a "PASS N/N" gate dump as a figure is a defect; fix it.
- **The scrub greps are unconditionally empty** — zero hits, no exceptions: `grep -rniE 'bullmq|bull:|dragonfly'`;
  the font-leak grep too (`grep -rnE 'Cormorant|Manrope|PT Serif|JetBrains|fonts.googleapis'` — nothing fetched).
- clamp() values are spaced (`1.9rem + 4.2vw`); the route-tag is the exact segmented form; the sticky header is
  scoped `header.top{…}`, never bare `.top`; every Sources `<li>` carries `href="http`; crumbs/pager point at the
  **intended** parent; each inline `<script>` parses (`node --check`).
- **Source fidelity + structure:** the hub's `.lede` is the **author source's opening summary**, and its `<h2>`
  sections follow the **source's `##` order** (`grep -oE '<h2>[^<]*</h2>'` the hub vs the source); **References is
  two-column** (a `.refs` grid with two child `<div>`s, not stacked); the **route-mirrored md exists** at
  `docs/redis-patterns/markdown/<route>.md` for every page authored.
- **Voice covers software components** (gate-blind): a cache / caller / surface / session must not "see" / "want" /
  "know" / "decide" — `grep -rnoE '\b(cache|caller|surface|session|application|server|client) (sees?|wants?|knows?|decides?)\b'`.
- Live crawl (if the route is wired): every new route 200, every still-unbuilt sibling 404; on the manifest pages
  unbuilt entries are non-anchor `<div class="mod">` cards with the `soon` pill, never links.

Fix any defect yourself, deterministically (do-no-harm), then re-gate to PASS.

## Step 4 — Build/relink the manifest pages (orchestrator-only)

In the home map (`index.html`) and the chapter landing (`<chapter>/index.html`), for each newly-built module turn
its card `<div class="mod">…</div>` → `<a class="mod" href="…">…</a>` and flip its pill `soon` → `built`. These two
pages stay route manifests at a **FULL links-PASS** (the BCS philosophy — no fail-by-design): unbuilt
chapters/modules stay **non-anchor** `<div class="mod">` cards with the `soon` pill, so nothing dangles. Re-gate
both — they must reach a full STATUS: PASS.

## Step 5 — Sync the TOC

Mark the modules built in `docs/redis-patterns/redis-patterns.toc.md` (route link + dive list + status). Do not
write redundant status prose ("all built", "complete") into nav pages — the cards' pills already show status;
describe structure and the arc instead.

## Step 6 — Report

Summarise: pages authored (route + grade), the gate tally, any defects you fixed (especially invented-API /
grounding drift), the manifest pages relinked, the TOC synced, and the next gap from `course-map.md`. Note whether
the `redis-expert` type resolved or fell back to `general-purpose`. **Do not commit** — the operator commits batches
out-of-band; never `git add`/`commit`/`restore`, and the spawned agents must not either.
