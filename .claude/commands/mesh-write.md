---
description: mesh-write — fan out mesh-expert subagents to author "EchoMesh, In Depth" pages (the M0 overview / a chapter landing + its three dives) in parallel, then relink the course landing + adversarially gate + sync the TOC
argument-hint: <chapter>  [<dive1> <dive2> <dive3>]   (e.g. overview the-impossible the-menu the-mesh  ·  impossible safety-and-liveness the-proof the-menu-not-the-wall)  ·  chapters: overview impossible best-effort-availability best-effort-consistency trading segmenting stack transparent future (or m0…m8) · landing = the course landing
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep, Skill, AskUserQuestion
model: fable
---

# /mesh-write — parallel page authoring for "EchoMesh, In Depth"

You are orchestrating a **parallel authoring batch** for the jonnify *EchoMesh, In Depth* course (served at `/mesh`) —
the senior successor to the EchoMesh chapters of `/art`, the CAP theorem read as a menu. Fan out one **`mesh-expert`**
subagent per page, then perform the **orchestrator-only** steps (relink the shared **manifest** pages — the course
landing and the chapter/overview landing — and sync the TOC). The craft's source of truth is the **`mesh-course-writer`**
skill; the *structure and grounding* are the **manuscript** (`docs/echo/mesh/mesh.toc.md`, `mesh.landing.md`,
`mesh.0.md`, the `mesh.[N].md` / `mesh.[N].[D].md` files). **Author only from the manuscript; never invent structure,
and never invent a figure.**

## The two course-defining rules (read first)

1. **The course's own identity.** Pages render in the **CAP contract-sheet** system defined by the exemplar
   `html/mesh/index.html` — the /bcs contract-sheet BASIS (warm paper `--m-paper`/`--m-card`/`--m-ink`, mono-forward,
   numbered sections, frozen evidence) carried into a violet-led, CAP-duality surface: `--m-mesh` (EchoMesh violet) /
   `--m-cons` (consistency-first blue) / `--m-avail` (availability-first green) / `--m-edge` (staleness amber). The
   signature primitive is the **`.htabs` hover-to-switch tab component**. NEVER the dark-editorial tokens of the
   sibling courses, and NEVER the `/bcs` `--b-*` tokens cloned verbatim. Every page copies a built MESH page.
2. **Figures verbatim; forward status.** Every figure on a page exists in a committed source — the mesh manuscript
   (`docs/echo/mesh/`) or a cited primary source (the CAP literature; the stack pieces). **EchoMesh is a FORWARD
   CONCEPT** — its pieces real and shipped, its composition into the mesh PROPOSED; carry a visible "Proposed · not
   shipped" note and never assert a shipped mesh figure. The manuscript is read-only for authoring.

## Arguments

```
$ARGUMENTS
```

Parse the argument string as whitespace-separated tokens:

- **Token 1 = the chapter.** A chapter **slug** (`overview`, `impossible`, `best-effort-availability`,
  `best-effort-consistency`, `trading`, `segmenting`, `stack`, `transparent`, `future`) or an `m<N>` number you resolve
  via the skill's `references/course-map.md` (`m0`=overview, `m1`=impossible, …). **Special: `landing`** = re-author/
  extend the course landing from `mesh.landing.md` — orchestrator-only, no fan-out.
- **Tokens 2…4 = the three dive slugs.** If omitted, read the chapter's dive slugs from the skill's course-map / the
  TOC. A chapter is a landing **plus three dives** (the M0 overview included).

If the chapter's **manuscript file is missing**, **stop and report**: the course does not author ahead of the book.
(The full manuscript M0–M8 is authored today.)

## Step 0 — Ground the batch (read-only)

1. Invoke the **Skill tool with skill `mesh-course-writer`**; read its `references/course-map.md` (chapter table,
   identity, the `.htabs` component, the resume point).
2. Read the chapter's TOC entry + its **manuscript file + three dive files** (`mesh.[N].md`, `mesh.[N].[D].md`), and
   `mesh.landing.md` / `mesh.0.md` where the chapter cites them. Confirm each dive's manuscript file exists.
3. For each page resolve: its number `M[N]` / `M[N].[D]`, manuscript file, served route (the M0 overview is
   `/mesh/overview`; its dives are `/mesh/overview/<dive>`; M1–M8 dives are `/mesh/<chapter>/<dive>`), and its pager
   position. Identify the cited CAP literature / stack sources.
4. **Pick the model page — a built MESH page.** The landing (`html/mesh/index.html`) is the canonical exemplar (carrying
   the `.htabs` component); afterwards each surface copies its own built precedent. Never another jonnify course.

## Step 1 — De-risk shared dependencies (once)

- Build the validator: `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .` (GOWORK=off mandatory; the prebuilt
  `bin/cms` is the fallback).
- The cms gate runs from the **filesystem** (`--routes-from /mesh=html/mesh` + the sibling mounts), so it needs no
  running server. The `/mesh` route **is wired** (`main.go` · `Makefile` · `Dockerfile`); a live crawl is
  `curl -s -o /dev/null -w '%{http_code}' http://localhost:8765/mesh` after `make restart` (port 8765; a `000` means
  the dev server is down or pre-dates the /mesh wiring — `make restart` picks it up).
- Confirm the page dirs exist (`html/mesh/<chapter>/`; the overview is `html/mesh/overview/`).

## Step 2 — Author the chapter/overview landing first, then fan out the dives

**The course landing (`index.html`) and the chapter/overview landing (`<chapter>/index.html`) are shared manifest
surfaces** — the orchestrator (you) authors/relinks them (or fans out ONE agent for a NEW chapter landing, a distinct
file). If the chapter/overview landing does not exist, author it first (bootstrap from the exemplar; the anatomy: the
chapter's teaching arc over its three dive cards, closing with an "Up next"). **Full links PASS:** unbuilt dives are
non-anchor `soon` cards.

Then spawn **one agent per dive, all in a single message** so they run concurrently — heavy author agents cap at **≤2
concurrent**; wave the three dives (2 then 1). Use `subagent_type: "mesh-expert"`; **if that errors "agent type not
found"** the def is not loaded this session — fall back to `subagent_type: "general-purpose"` (the brief below is
self-contained). Give each agent:

- its **page number, manuscript file (`mesh.[N].[D].md`), slug, served route**;
- its **grounding** — the manuscript file + the CAP literature / stack sources it cites — and the instruction to
  **read them and quote figures verbatim** (a figure not in a committed source does not appear), plus the
  **forward/living-status rule** (EchoMesh PROPOSED; a visible "Proposed · not shipped" note);
- the **route-mirrored md to author FIRST**: `docs/echo/mesh/markdown/<route>.md`;
- the **model page** — a built MESH page (the landing exemplar) — and the identity boundary (the MUST-NOT list: no
  dark-editorial palette/fonts/card classes, no `/bcs` `--b-*` tokens cloned verbatim);
- its **locked pager** + crumbs + `Related` routes;
- the **mandatory rules**: the clickable segmented route-tag; the canonical 3-column footer + a freshly minted
  **`MSH…`** stamp (`apps/jonnify-cms/bin/cms stamp mint --ns MSH`, decode-verified); the `class="refs"` References
  block (REAL vetted links from the registry in the agent def / `Related` = resolving routes); **≥2 interactives per
  dive (≥1 per landing), ≥1 an inline `<svg>`**, and the **`.htabs` hover-tab component** for schemas / the stack /
  **health-recovery-partition emulators** (pure functions, live readout, degrade, honour `prefers-reduced-motion`, no
  storage); the **voice** rules (measured; the CAP trade stated fairly);
- the **gate command** and **ship only at STATUS: PASS**;
- **hard constraints:** NEVER run git; edit ONLY its own page's files; do NOT touch the course landing, the
  chapter/overview landing, or the manuscript (`docs/echo/mesh/mesh*.md`).

## Step 3 — Adversarially verify (do NOT trust the agents' "all PASS")

For each new page run the gate (in zsh force word-split with `${=FLAGS}`):

```bash
FLAGS="--routes-from /mesh=html/mesh --routes-from /art=html/art --routes-from /bcs=html/bcs --routes-from /echomq=html/echomq --routes-from /elixir=elixir --chapter-alias m0=overview,m1=impossible,m2=best-effort-availability,m3=best-effort-consistency,m4=trading,m5=segmenting,m6=stack,m7=transparent,m8=future --require-refs"
apps/jonnify-cms/bin/cms check ${=FLAGS} <page>.html
```

Then the gate-**invisible** failure modes:

- **Figure provenance**: list every figure/theorem statement/SLA/module on the page and re-find each in its claimed
  source (the manuscript file, the cited paper). Anything not found is fabricated — fix it.
- **Identity leak:** `grep -n 'Cormorant\|Manrope\|PT Serif\|--b-paper\|--b-ns' <page>` — no dark-editorial or
  verbatim-`/bcs` palette/`.chap`/`.mods`/`.mod` classes.
- **`.htabs` degrade:** the panels read without the `js` class (CSS shows all); the component JS parses (`node --check`).
- clamp() values spaced; the route-tag the exact segmented form; every Sources `<li>` carries `href="http`;
  crumbs/pager point at the **intended** parent; the **route-mirrored md exists**.
- **Voice covers software components** (gate-blind):
  `grep -rnoE '\b(mesh|node|runtime|cache|bus|store|system|server) (sees?|wants?|knows?|decides?)\b' <chapter dir>`.
- **Forward status:** EchoMesh is never asserted-as-shipped (a "Proposed · not shipped" note is present where the page
  leans on the mesh).
- Live crawl (server up after `make restart`): every new route 200; `soon` cards stay non-anchor.

Fix any defect yourself, deterministically (do-no-harm), then re-gate to PASS.

## Step 4 — Relink the manifest pages (orchestrator-only)

On the course landing (`html/mesh/index.html`) and the chapter/overview landing, for each newly-built dive/chapter turn
its non-anchor card `<div class="pcard">…</div>` → `<a class="pcard" href="…">…</a>` and flip its chip `soon` → built;
update the footer chapters column the same way. **Keep full links PASS** — link only routes that now resolve. Re-gate
both pages to STATUS: PASS.

## Step 5 — Sync the TOC

Mark the dives/chapter built in `docs/echo/mesh/mesh.toc.md` (route + status `✓ built`). Do not write redundant status
prose into nav pages — the cards' chips show status; describe structure and the arc. Never edit the manuscript bodies.

## Step 6 — Report

Summarise: pages authored (route + grade), the gate tally, any defects you fixed (figure-provenance / identity-leak /
forward-status / `.htabs`-degrade drift), the manifests relinked, the TOC synced, and the next gap from `course-map.md`.
Note whether the `mesh-expert` type resolved or fell back to `general-purpose`. **Do not commit** — the operator commits
batches out-of-band; never `git add`/`commit`/`restore`, and the spawned agents must not either.
