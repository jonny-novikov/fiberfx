---
description: bcs-write — fan out bcs-expert subagents to author a BCS chapter's pages (chapter landing, module hubs, dives) in parallel, then relink the course landing + adversarially gate + sync the TOC
argument-hint: <chapter-slug> <module-slug>[:dive1,dive2,dive3] [<module-slug>[:dives] …]  (e.g. ideas system-substrate identity-contract)  ·  chapter slugs: ideas elixir-core bus cache go node fly trading (or b1…b8)
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep, Skill, AskUserQuestion
model: opus
---

# /bcs-write — parallel page authoring for the "Branded Component System" course

You are orchestrating a **parallel authoring batch** for the jonnify "Branded Component System" course (served at
`/bcs`). Fan out one **`bcs-expert`** subagent per module, then perform the **orchestrator-only** steps the
subagents are forbidden from doing (relink the shared **manifest** pages — the course landing and the chapter
landing — and sync the TOC). The craft's source of truth is the **`bcs-course-writer`** skill; the *structure and
grounding* are the **spec system** — the TOC (`docs/echo/bcs/bcs.toc.md`), the roadmap + grounding map
(`docs/echo/bcs/bcs.roadmap.md`), the contract (`docs/echo/bcs/bcs.md`), and the chapter triads
(`docs/echo/bcs/specs/bcs.N.{md,specs.md,llms.md}`). **Author only from the spec; never invent structure, and
never invent a figure.**

## The two course-defining rules (read first)

1. **The course's own identity.** Pages render in the contract-sheet system defined by the B0 exemplar
   `html/bcs/index.html` — light paper tokens, the segment hues, system font stacks, frozen-transcript evidence
   blocks. NEVER the dark-editorial tokens of the sibling courses. Every page copies a built BCS page.
2. **Figures verbatim; living status.** Every number on a page exists in a committed output under
   `docs/echo/bcs/content/` (the contract + vectors, the rung transcripts, the bench record, `bcsA.md`).
   Unwritten manuscript Parts (IV–VIII; chapters 3.4–3.6) are referenced as *"the manuscript plans…"* — never
   asserted-as-written. The manuscript and its ledger are read-only for authoring.

## Arguments

```
$ARGUMENTS
```

Parse the argument string as whitespace-separated tokens:

- **Token 1 = the chapter.** A chapter **dir slug** (`ideas`, `elixir-core`, `bus`, `cache`, `go`, `node`,
  `fly`, `trading`) or a `b<N>` number you resolve via the skill's `references/course-map.md`. **Special:
  `b0` (or `landing`)** = re-author/extend the course landing from `specs/bcs.0.*` — orchestrator-only, no
  fan-out.
- **Tokens 2…N = one module each**, `<module-slug>` or `<module-slug>:<dive1>,<dive2>,<dive3>`. The **chapter
  triad** (`specs/bcs.N.specs.md`) names each module's number, manuscript chapter, grounding, and dives; the
  optional `:`-list overrides the dive slugs (**≥3**).

If the arg string is empty, or only the chapter is given, **do not guess** — read the chapter triad's module
ladder and either author every module in it or `AskUserQuestion` which to author. If the chapter has **no triad
yet** under `specs/`, stop and report: the triad is authored first (the `bcs.0.*` exemplar shows the form) —
pages are never authored ahead of the spec. If the chapter's manuscript Part is unwritten (B4–B8), stop: the
course does not author ahead of the book.

## Step 0 — Ground the batch (read-only)

1. Invoke the **Skill tool with skill `bcs-course-writer`**; read its `references/course-map.md` (chapter table,
   identity notes, the resume point).
2. Read the chapter triad `specs/bcs.N.{md,specs.md,llms.md}`, the chapter's TOC section (`bcs.toc.md`), and the
   **grounding map** in `bcs.roadmap.md` — the manuscript files + committed evidence each requested module draws
   on.
3. For each requested module resolve: its number `B[N].[M]`, manuscript chapter (`content/bcs<N>.<M>.md`),
   evidence files, served route, dive slugs, and its pager position.
4. **Pick the model page per surface — a built BCS page.** The B0 landing (`html/bcs/index.html`) is the
   canonical exemplar; the first chapter landing / hub / dive of the course bootstraps its design from it, and
   afterwards each surface copies its own built precedent. Never another jonnify course.

## Step 1 — De-risk shared dependencies (once)

- Build the validator: `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .` (GOWORK=off mandatory; the
  prebuilt `bin/cms` is the fallback).
- The cms gate runs from the **filesystem** (`--routes-from /bcs=html/bcs` + the three sibling mounts), so it
  needs no running server. The `/bcs` route **is wired** (`main.go` · `Makefile` · `Dockerfile`, shipped with
  bcs.0); a live crawl is `curl -s -o /dev/null -w '%{http_code}' http://localhost:8765/bcs` after `make start`
  (port 8765; a `000` means the dev server is down, not a missing route).
- Confirm `html/bcs/<chapter>/` exists (create the dir if needed).

## Step 2 — Author the chapter landing first, then fan out the modules

**The course landing (`index.html`) and the chapter landing (`<chapter>/index.html`) are shared manifest
surfaces** — the orchestrator (you) authors/relinks them, never the parallel agents, to avoid a parallel-write
conflict. If the chapter landing does not exist, author it first (bootstrap its design from the B0 exemplar; the
anatomy: the chapter's teaching arc over its module cards, closing with an "Up next" grid). **Full links PASS
discipline:** unbuilt modules are non-anchor `soon` cards — link only routes that exist, so every page holds
STATUS: PASS with no manifest exception.

Then spawn **one agent per module, all in a single message** so they run concurrently — heavy author agents cap
at **≤2 concurrent**; wave larger batches. Use `subagent_type: "bcs-expert"`; **if that errors "agent type not
found"** the def is not loaded this session — fall back to `subagent_type: "general-purpose"` (the brief below
is self-contained). Give each agent:

- its **module number, manuscript chapter, slug, served route**, and the **dive slugs**;
- its **grounding files** from the grounding map — the manuscript chapter + the evidence files — and the
  instruction to **read them and quote figures verbatim** (a number not in a committed output does not appear),
  plus the **living-status rule** for any reference to an unwritten Part;
- the **route-mirrored md to author FIRST**: `docs/echo/bcs/markdown/<route>.md` (the served route minus
  `/bcs/`, `.md` appended);
- the **model page** — a built BCS page of the same surface (per Step 0.4) — and the identity boundary (the
  MUST-NOT list: no dark-editorial palette/fonts/card classes);
- its **locked pager** (hub `prev` = chapter landing, `next` = own first dive; dives chain hub → dive1 → dive2 →
  dive3 → hub) + crumbs + `Related` routes;
- the **mandatory rules**: the clickable segmented route-tag; the canonical 3-column footer + a freshly minted
  **`BCS…`** stamp (`apps/jonnify-cms/bin/cms stamp mint --ns BCS`, decode-verified); the `class="refs"`
  References block (two columns, `Sources` = REAL vetted links from the registry in the skill / `Related` =
  resolving internal routes); ≥2 interactives per dive (≥1 per hub/landing) — pure functions over fixed data,
  live readout, degrades, honours `prefers-reduced-motion`, no storage; frozen-transcript evidence blocks
  source-labelled; the **voice** rules;
- the **gate command** and **ship only at STATUS: PASS**;
- **hard constraints:** NEVER run git; edit ONLY its own module's files; do NOT touch the course landing, the
  chapter landing, or anything under `docs/echo/bcs/content/`.

## Step 3 — Adversarially verify (do NOT trust the agents' "all PASS")

For each new page run the gate (in zsh force word-split with `${=FLAGS}`):

```bash
FLAGS="--routes-from /bcs=html/bcs --routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns --routes-from /elixir=elixir --chapter-alias b1=ideas,b2=elixir-core,b3=bus,b4=cache,b5=go,b6=node,b7=fly,b8=trading --require-refs"
apps/jonnify-cms/bin/cms check ${=FLAGS} <page>.html
```

Then the gate-**invisible** failure modes:

- **Figure provenance** (the course's reason to exist): list every number/namespace/script name on the page and
  re-find each in its claimed source under `docs/echo/bcs/content/`; anything not found is fabricated — fix it.
- **Identity leak:** `grep -n 'Cormorant\|Manrope\|PT Serif' <page>` and check no dark-editorial palette values
  or `.chap`/`.mods`/`.mod` classes appear.
- clamp() values are spaced; the route-tag is the exact segmented form; every Sources `<li>` carries
  `href="http`; crumbs/pager point at the **intended** parent; each inline `<script>` parses (`node --check`);
  the **route-mirrored md exists** for every page authored.
- **Voice covers software components** (gate-blind): `grep -rnoE '\b(store|gate|connector|system|boundary|bus|id) (sees?|wants?|knows?|decides?)\b' <module dirs>`.
- **Living status:** no unwritten manuscript chapter asserted-as-written
  (`grep -n 'the manuscript plans' <page>` should cover every Part IV–VIII reference).
- Live crawl (server up): every new route 200; `soon` cards stay non-anchor.

Fix any defect yourself, deterministically (do-no-harm), then re-gate to PASS.

## Step 4 — Relink the manifest pages (orchestrator-only)

On the course landing (`html/bcs/index.html`) and the chapter landing, for each newly-built module/chapter turn
its non-anchor card `<div class="pcard">…</div>` → `<a class="pcard" href="…">…</a>` and flip its chip
`soon` → built; update the footer chapters column the same way. **Keep full links PASS** — link only routes that
now resolve. Re-gate both pages to STATUS: PASS.

## Step 5 — Sync the TOC

Mark the modules built in `docs/echo/bcs/bcs.toc.md` (route link + dive list + status legend). Do not write
redundant status prose ("all built", "complete") into nav pages — the cards' chips already show status; describe
structure and the arc instead. Never edit `content/bcs.toc.md` or `content/bcs.progress.md` (the manuscript's;
decision D-7).

## Step 6 — Report

Summarise: pages authored (route + grade), the gate tally, any defects you fixed (especially figure-provenance /
identity-leak drift), the manifests relinked, the TOC synced, and the next gap from `course-map.md`. Note
whether the `bcs-expert` type resolved or fell back to `general-purpose`. **Do not commit** — the operator
commits batches out-of-band; never `git add`/`commit`/`restore`, and the spawned agents must not either.
