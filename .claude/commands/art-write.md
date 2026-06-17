---
description: art-write — fan out art-expert subagents to author an "Art of BCS" chapter's pages (chapter landing + its three dives) in parallel, then relink the course landing + adversarially gate + sync the TOC
argument-hint: <chapter-slug> [<dive1> <dive2> <dive3>]  (e.g. thesis the-constellation the-primitives identity-across-boundaries)  ·  chapter slugs: thesis no-coordinator no-log-broker no-message-broker no-orchestrator hot-path durable-edge echomesh echomesh-depth whole-picture (or a1…a10) · a0/landing = the course landing
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep, Skill, AskUserQuestion
model: opus
---

# /art-write — parallel page authoring for "The Art of BCS" course

You are orchestrating a **parallel authoring batch** for the jonnify *The Art of BCS* course (served at `/art`) — the
senior continuation of `/bcs`, the architect's case for owning the runtime. Fan out one **`art-expert`** subagent per
dive, then perform the **orchestrator-only** steps the subagents are forbidden from doing (relink the shared
**manifest** pages — the course landing and the chapter landing — and sync the TOC). The craft's source of truth is
the **`art-course-writer`** skill; the *structure and grounding* are the **spec system** — the TOC
(`docs/echo/art/art.toc.md`) and the **manuscript** (`docs/echo/art/art.prelude.md`, `art.preface.md`, and the
`art[N].md` / `art[N][D].md` chapter+dive files). **Author only from the manuscript; never invent structure, and never
invent a figure.**

## The two course-defining rules (read first)

1. **The course's own identity.** Pages render in the **architect's-blueprint** system defined by the A0 exemplar
   `html/art/index.html` — cool blueprint paper tokens (`--a-paper`/`--a-card`/`--a-ink`), the four themed hues
   `--a-arc` (architect indigo) / `--a-avail` (availability green) / `--a-mesh` (EchoMesh violet) / `--a-edge` (edge
   amber), system font stacks, the nines-rule, frozen-transcript evidence blocks, the rich course-to-course `.door`
   blocks. NEVER the dark-editorial tokens of the sibling courses, and NEVER the `/bcs` warm `--b-*` oxide-red tokens
   cloned verbatim. Every page copies a built ART page.
2. **Figures verbatim; forward status.** Every number on a page exists in a committed source — the art manuscript
   (`docs/echo/art/`), a committed Exchange-exemplar gate transcript, or a cited primary source; the availability
   arithmetic is **derived**, not asserted. **EchoMesh (A8) is a FORWARD CONCEPT** (not yet in code) and every
   manuscript-pending Part (A2–A5, A7, A9, A10) is referenced in living-status voice — *"the course introduces…"*,
   *"the manuscript plans…"* — never asserted-as-shipped. The manuscript is read-only for authoring.

## Arguments

```
$ARGUMENTS
```

Parse the argument string as whitespace-separated tokens:

- **Token 1 = the chapter.** A chapter **slug** (`thesis`, `no-coordinator`, `no-log-broker`, `no-message-broker`,
  `no-orchestrator`, `hot-path`, `durable-edge`, `echomesh`, `echomesh-depth`, `whole-picture`) or an `a<N>` number you
  resolve via the skill's `references/course-map.md`. **Special: `a0` (or `landing`)** = re-author/extend the course
  landing from the A0 manuscript — orchestrator-only, no fan-out.
- **Tokens 2…4 = the dive slugs** (three per chapter; **A9 · EchoMesh in Depth carries two**). If omitted, read the
  chapter's dive slugs from the TOC entry (and the chapter triad once it exists). A chapter is a landing **plus its
  dives** — three for the standard chapter, two for A9.

If the arg string is empty, or only the chapter is given, read the TOC's dive slugs for that chapter and author the
landing + its dives (three per chapter — **A9 · EchoMesh in Depth carries two**). If the chapter's **manuscript chapter
is missing** (`art[N].md` and/or its dive files `art[N][D].md` not present under `docs/echo/art/`), **stop and report**:
the course does not author ahead of the book. The dive articles under A2–A8 plus A10 are manuscript-pending; **A8 ·
Introducing EchoMesh and A9 · EchoMesh in Depth — the heart pair — are a PROPOSED concept** — author them only when the
manuscript exists, and then in forward-looking voice throughout.

## Step 0 — Ground the batch (read-only)

1. Invoke the **Skill tool with skill `art-course-writer`**; read its `references/course-map.md` (chapter table,
   identity notes, the resume point).
2. Read the chapter's TOC section (`art.toc.md`) and its **manuscript chapter + three dive files** (`art[N].md`,
   `art[N][D].md`) — and the Prelude/Preface where the chapter cites them. Confirm each dive's manuscript file exists.
3. For each dive resolve: its number `A[N].[D]`, manuscript chapter (`art[N][D].md`), served route
   (`/art/<chapter-slug>/<dive-slug>`; A0's dives are leaf files at the course root, `/art/<dive-slug>`), and its pager
   position. Identify the cited primary sources and (for A6/A8) the Exchange-exemplar evidence.
4. **Pick the model page per surface — a built ART page.** The A0 landing (`html/art/index.html`) is the canonical
   exemplar; the first chapter landing / dive of the course bootstraps its design from it, and afterwards each surface
   copies its own built precedent. Never another jonnify course.

## Step 1 — De-risk shared dependencies (once)

- Build the validator: `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .` (GOWORK=off mandatory; the prebuilt
  `bin/cms` is the fallback).
- The cms gate runs from the **filesystem** (`--routes-from /art=html/art` + the four sibling mounts), so it needs no
  running server. The `/art` route **is wired** (`main.go` · `Makefile` · `Dockerfile`, shipped with the A0 landing);
  a live crawl is `curl -s -o /dev/null -w '%{http_code}' http://localhost:8765/art` after `make start` (port 8765; a
  `000` means the dev server is down, not a missing route).
- Confirm `html/art/<chapter-slug>/` exists (create the dir if needed; A0's dives are at the course root).

## Step 2 — Author the chapter landing first, then fan out the dives

**The course landing (`index.html`) and the chapter landing (`<chapter>/index.html`) are shared manifest surfaces** —
the orchestrator (you) authors/relinks them, never the parallel agents, to avoid a parallel-write conflict. If the
chapter landing does not exist, author it first (bootstrap its design from the A0 exemplar; the anatomy: the chapter's
teaching arc over its three dive cards, closing with an "Up next" link). **Full links PASS discipline:** unbuilt dives
are non-anchor `soon` cards — link only routes that exist, so every page holds STATUS: PASS with no manifest
exception.

Then spawn **one agent per dive, all in a single message** so they run concurrently — heavy author agents cap at **≤2
concurrent**; wave the three dives (e.g. 2 then 1). Use `subagent_type: "art-expert"`; **if that errors "agent type
not found"** the def is not loaded this session — fall back to `subagent_type: "general-purpose"` (the brief below is
self-contained). Give each agent:

- its **dive number, manuscript chapter (`art[N][D].md`), slug, served route**;
- its **grounding** — the manuscript dive file + the Prelude/Preface lines it rests on + the cited primary sources
  (and, for A6/A8, the Exchange-exemplar gate records) — and the instruction to **read them and quote figures
  verbatim** (a number not in a committed source does not appear; the availability arithmetic is derived, not
  asserted), plus the **forward/living-status rule** (EchoMesh PROPOSED; manuscript-pending Parts in living-status
  voice);
- the **route-mirrored md to author FIRST**: `docs/echo/art/markdown/<route>.md` (the served route minus `/art/`,
  `.md` appended);
- the **model page** — a built ART page of the same surface (per Step 0.4) — and the identity boundary (the MUST-NOT
  list: no dark-editorial palette/fonts/card classes, no `/bcs` `--b-*` tokens cloned verbatim);
- its **locked pager** (dives chain landing → dive1 → dive2 → dive3 → landing) + crumbs + `Related` routes;
- the **mandatory rules**: the clickable segmented route-tag; the canonical 3-column footer + a freshly minted
  **`ART…`** stamp (`apps/jonnify-cms/bin/cms stamp mint --ns ART`, decode-verified); the `class="refs"` References
  block (two columns, `Sources` = REAL vetted links from the registry in the agent def / `Related` = resolving
  internal routes); ≥2 interactives per dive (≥1 per landing) — pure functions over fixed data, live readout,
  degrades, honours `prefers-reduced-motion`, no storage; frozen-transcript / derived-arithmetic evidence blocks
  source-labelled; the **voice** rules (narrow, measured; the cloud's case stated fairly);
- the **gate command** and **ship only at STATUS: PASS**;
- **hard constraints:** NEVER run git; edit ONLY its own dive's files; do NOT touch the course landing, the chapter
  landing, or the manuscript (`docs/echo/art/art*.md`).

## Step 3 — Adversarially verify (do NOT trust the agents' "all PASS")

For each new page run the gate (in zsh force word-split with `${=FLAGS}`):

```bash
FLAGS="--routes-from /art=html/art --routes-from /bcs=html/bcs --routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns --routes-from /elixir=elixir --chapter-alias a1=thesis,a2=no-coordinator,a3=no-log-broker,a4=no-message-broker,a5=no-orchestrator,a6=hot-path,a7=durable-edge,a8=echomesh,a9=echomesh-depth,a10=whole-picture --require-refs"
apps/jonnify-cms/bin/cms check ${=FLAGS} <page>.html
```

Then the gate-**invisible** failure modes:

- **Figure provenance** (the course's reason to exist): list every number/SLA/availability figure/module name on the
  page and re-find each in its claimed source (the manuscript chapter, the cited SLA, the gate transcript); anything
  not found is fabricated — fix it. The availability arithmetic must show its derivation.
- **Identity leak:** `grep -n 'Cormorant\|Manrope\|PT Serif\|--b-paper\|--b-ns' <page>` and check no dark-editorial or
  verbatim-`/bcs` palette values or `.chap`/`.mods`/`.mod` classes appear.
- clamp() values are spaced; the route-tag is the exact segmented form; every Sources `<li>` carries `href="http`;
  crumbs/pager point at the **intended** parent; each inline `<script>` parses (`node --check`); the **route-mirrored
  md exists** for every page authored.
- **Voice covers software components** (gate-blind):
  `grep -rnoE '\b(runtime|broker|coordinator|mesh|gate|bus|store|system) (sees?|wants?|knows?|decides?)\b' <chapter dir>`.
- **Forward status:** EchoMesh and any manuscript-pending Part are never asserted-as-shipped
  (`grep -n 'the course introduces\|the manuscript plans\|proposed' <page>` should cover every such reference).
- Live crawl (server up): every new route 200; `soon` cards stay non-anchor.

Fix any defect yourself, deterministically (do-no-harm), then re-gate to PASS.

## Step 4 — Relink the manifest pages (orchestrator-only)

On the course landing (`html/art/index.html`) and the chapter landing, for each newly-built dive/chapter turn its
non-anchor card `<div class="pcard">…</div>` → `<a class="pcard" href="…">…</a>` and flip its chip `soon` → built;
update the footer chapters column the same way. **Keep full links PASS** — link only routes that now resolve. Re-gate
both pages to STATUS: PASS.

## Step 5 — Sync the TOC

Mark the dives/chapter built in `docs/echo/art/art.toc.md` (route link + dive list + status legend `✓ built`). Do not
write redundant status prose ("all built", "complete") into nav pages — the cards' chips already show status; describe
structure and the arc instead. Never edit the manuscript (`docs/echo/art/art*.md`).

## Step 6 — Report

Summarise: pages authored (route + grade), the gate tally, any defects you fixed (especially figure-provenance /
identity-leak / forward-status drift), the manifests relinked, the TOC synced, and the next gap from `course-map.md`.
Note whether the `art-expert` type resolved or fell back to `general-purpose`. **Do not commit** — the operator
commits batches out-of-band; never `git add`/`commit`/`restore`, and the spawned agents must not either.
