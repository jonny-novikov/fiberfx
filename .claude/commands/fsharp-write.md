---
description: fsharp-write — fan out fsharp-expert subagents to author an F# In Depth chapter's pages (chapter landing, module hubs, dives) in parallel, then relink the landing map + adversarially gate + sync the TOC
argument-hint: <chapter-slug> <module-slug>[:dive1,dive2,dive3] [<module-slug>[:dives] …]  (e.g. language values bindings functions)  ·  chapter slugs history|language|for-csharp|for-elixir|algorithms|devops
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep, Skill, AskUserQuestion
model: fable
---

# /fsharp-write — parallel page authoring for the "F# In Depth" course

You are orchestrating a **parallel authoring batch** for the jonnify "F# In Depth" course (served at
`/fsharp`). Fan out one **`fsharp-expert`** subagent per module, then perform the **orchestrator-only**
steps the subagents are forbidden from doing: author/relink the shared **manifest** pages (the home
map and the chapter landing) and sync the TOC + progress. The craft's source of truth is the
**`fsharp-course-writer`** skill; the *structure and grounding* are the **spec system** — the TOC
(`docs/fsharp/fsharp.toc.md`), the roadmap + grounding map (`docs/fsharp/fsharp.roadmap.md`), the
contract (`docs/fsharp/specs/fsharp.md`), and (when present) the per-chapter specs. **Author only from
the spec; never invent structure or grounding.**

## Arguments

```
$ARGUMENTS
```

Parse the argument string as whitespace-separated tokens:

- **Token 1 = the chapter.** A chapter **dir slug** (`history`, `language`, `for-csharp`, `for-elixir`,
  `algorithms`, `devops`) or a `C<N>` number you resolve to its slug via the skill's `course-map.md`.
- **Tokens 2…N = one module each**, `<module-slug>` or `<module-slug>:<dive1>,<dive2>,<dive3>`. The
  TOC (`docs/fsharp/fsharp.toc.md`) names each module's number, slug, and (for C0–C3) its three
  dives; the optional `:`-list overrides the dive slugs. C4/C5 modules are single pages (no dives).

If the arg string is empty, or only the chapter is given, **do not guess** — read the chapter's TOC
section and either author every module in it or `AskUserQuestion` which to author.

## Step 0 — Ground the batch (read-only)

1. Invoke the **Skill tool with skill `fsharp-course-writer`**; read its `references/course-map.md`
   (chapter table, the resume point).
2. Read the chapter's section in `docs/fsharp/fsharp.toc.md` (the module ladder + dives), the
   contract `docs/fsharp/specs/fsharp.md`, and the **grounding map** in `docs/fsharp/fsharp.roadmap.md`
   — what each requested module is grounded in.
3. For each requested module resolve: its number `C[N].[M]`, slug, served route, dive slugs, and its
   grounding:
   - **C0** — the documented history + the Sources to cite.
   - **C1 / C2** — the F# (and C#) language features it teaches; every snippet must be valid idiomatic F#.
   - **C3 (for Elixir devs)** — the Elixir habit each module maps from + its idiomatic F# form; the
     matching `/elixir` module to cross-link; every F# snippet valid idiomatic F#, the Elixir real (no strawman).
   - **C4 (Algorithms)** — the matching **Elixir E4** module (`/elixir/algorithms/<slug>`) it reflects;
     cross-link it and add the F# implementation/efficiency note; every snippet valid idiomatic F#.
   - **C5 (DevOps)** — the **real `ibbs` surface** the grounding map names (open it on disk under
     `/Users/jonny/dev/ibbs` and read the actual F# before briefing the agent).
4. **Pick the model page per surface** — copy the design system from `html/fsharp/index.html` (the
   home/manifest model) or a built F# page of the same surface (hub/dive). The identity is
   dark-editorial + the F# violet accent (`--fsharp:#b48ee0`); never the redis/BCS contract sheet.

## Step 1 — De-risk shared dependencies (once)

- Build the validator: `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .` (GOWORK=off mandatory).
- The cms gate runs from the **filesystem** (`--routes-from /fsharp=html/fsharp`), so it needs no
  running server. A **live route crawl** does: `curl -s -o /dev/null -w '%{http_code}' http://localhost:8765/fsharp`.
  The `/fsharp` route is already wired (`main.go` + `Dockerfile` + `Makefile` + the `folderRouted`
  slice in `cmd/sitemap/main.go` + `html/llms.txt`), so the crawl works once `make start` is up.
- Confirm `html/fsharp/<chapter>/` exists (create the dir if needed).

## Step 2 — Author the manifest landing first, then fan out the modules

**The home map (`index.html`) and the chapter landing (`<chapter>/index.html`) are ROUTE MANIFESTS** —
the orchestrator (you) authors/relinks them, never the parallel agents, to avoid a parallel-write
conflict on the shared file. If the chapter landing does not exist, author it first (the teaching arc:
overview → how to read → the module cards → a closing recap/lab where useful). Spawn one
`fsharp-expert` for it, or author it yourself from the spec.

Then spawn **one agent per module, all in a single message** so they run concurrently. Use
`subagent_type: "fsharp-expert"`; **if that errors "agent type not found"** the def is not loaded this
session — fall back to `subagent_type: "general-purpose"` (the fsharp-expert brief is self-contained).
Give each agent:

- its **module number, slug, served route**, and the **dive slugs** (or "single page" for C4/C5);
- its **grounding** (per Step 0.3), with the instruction to **invent nothing**: for C4, quote ONE
  tight real excerpt from the named `ibbs` surface, re-found on disk under `/Users/jonny/dev/ibbs`
  before citing (never a fabricated project/assembly/function/route/flag; honour the README's
  representative-vs-live notes); for C1–C3, every F# snippet **valid and idiomatic** (no invented
  syntax/operator/library function); for C0, only what the documented record supports;
- the **model page** (`html/fsharp/index.html` or a built F# page of the same surface) and the
  instruction to copy `<head>`…`</style>`/`<header>`/`<footer>`/trailing `<script>` verbatim, changing
  only `<title>`/`<meta>`, the route-tag, the crumbs, and `<main>`;
- its **locked pager** (hub `prev` = chapter landing, `next` = own first dive; dives chain hub →
  dive1 → dive2 → dive3 → hub) + crumbs + `Related in this course` routes (for C3, the matching `/elixir` module; for C4, the matching E4 module);
- the **mandatory rules**: the clickable segmented route-tag; the canonical 3-column footer
  (`.foot-nav` + `.foot-bar`) + `TSK…` stamp (verbatim); the **References** block (real vetted Sources
  from the roadmap's registry — learn.microsoft.com/dotnet/fsharp, fsharp.org, the F# spec, the .NET
  docs, the HOPL F# history paper, fable.io, llmstxt.org — + `Related in this course`); ≥1 interactive
  per page that performs the real operation over a fixed dataset, degrades without JS, honours
  `prefers-reduced-motion`, uses no browser storage; ≥1 `svg` per page; the **voice** rules;
- the **gate command** and **ship only at STATUS: PASS**;
- **hard constraints:** NEVER run git; edit ONLY its own module's files; **do NOT touch the chapter
  landing or the home map** (you relink them in Step 4).

## Step 3 — Adversarially verify (do NOT trust the agents' "all PASS")

For each new page run the gate (mount `/fsharp` + any cross-course route the page links to):

```bash
apps/jonnify-cms/bin/cms check --routes-from /fsharp=html/fsharp --routes-from /elixir=elixir --require-refs <page>.html
```

(Add `--routes-from /redis-patterns=html/redis-patterns` / `/bcs` / `/echomq` if a page links there.)
Then the gate-**invisible** failure modes, fixed by reading:

- **No invented surface / no invalid code** (the course's discipline): for **C5**,
  `grep -rnoE '(DevOps|Monitor|Sfera|Api|Ui|Dashboard|Database|Releases|App)\.[A-Za-z.]+' <page>` and
  cross-check each on disk under `/Users/jonny/dev/ibbs`; re-find every quoted figure (module / function
  / endpoint / flag) verbatim in its real `ibbs` source; for **C1–C4**, confirm every F# snippet is
  valid idiomatic F# (no invented syntax/operator/API); for **C0**, every claimed fact is supported by
  a cited source.
- clamp() values are spaced (`1.9rem + 4.2vw`); the route-tag is the exact segmented form; every
  Sources `<li>` carries `href="http`; crumbs/pager point at the **intended** parent; each inline
  `<script>` parses (`node --check`).
- **Voice covers software components** (gate-blind): a function / value / module must not "see" /
  "want" / "know" / "decide" — `grep -rnoE '\b(function|value|module|server|client|caller) (sees?|wants?|knows?|decides?)\b'`.
- Live crawl (server up): every new route 200, every still-unbuilt sibling 404; on the manifest pages
  unbuilt entries are non-anchor `<div class="mod">` cards with the `soon` pill, never links.

Fix any defect yourself, deterministically (do-no-harm), then re-gate to PASS.

## Step 4 — Build/relink the manifest pages (orchestrator-only)

In the home map (`index.html`) and the chapter landing (`<chapter>/index.html`), for each newly-built
module turn its card `<div class="mod">…</div>` → `<a class="mod" href="…">…</a>` and flip its pill
`soon` → `built`. These pages stay route manifests at a **FULL links-PASS**: unbuilt chapters/modules
stay **non-anchor** `<div class="mod">` cards with the `soon` pill, so nothing dangles. Re-gate both.

## Step 5 — Sync the TOC + progress

Mark the modules built in `docs/fsharp/fsharp.toc.md` (route link + dive list + status) and update
`docs/fsharp/fsharp.progress.md` (the table + the resume point). Do not write redundant status prose
into nav pages — the cards' pills already show status; describe structure and the arc instead.

## Step 6 — Report

Summarise: pages authored (route + grade), the gate tally, any defects you fixed (especially
invented-API / grounding drift / invalid F#), the manifest pages relinked, the TOC + progress synced,
and the next gap from `course-map.md`. Note whether the `fsharp-expert` type resolved or fell back to
`general-purpose`. **Do not commit** — the operator commits batches out-of-band; never `git
add`/`commit`/`restore`, and the spawned agents must not either.
