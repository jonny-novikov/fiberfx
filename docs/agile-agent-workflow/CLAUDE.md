# CLAUDE.md — authoring the "Agile Agent Workflow" course

Guidance for a Claude agent authoring or extending this course. It orients you; it does **not** restate the craft.
The single source of truth for *how* to write a page is the **`agile-course-writer` skill** — load it first
(`Skill` tool, skill `agile-course-writer`). This file tells you where everything lives, the rules that fail
silently, and how a batch is run.

## What this course is

A set of **hand-authored static HTML pages** served byte-for-byte at **`/course/agile-agent-workflow`** by the
jonnify Fiber server (folder-routed via `serveDirTree`; the URL tree mirrors `html/agile-agent-workflow/`, read
from disk live — a new `.html` is live on save, no rebuild). It teaches **Pragmatic Programming with Claude
Agents**: a human **Operator** (judgement, decomposition, acceptance) and a Claude **Author** (fast, well-specified
implementation) build the **Portal** platform from zero to production over thin, provable slices.

Structure is three levels — `A<chapter>.<module>.<subpage>`:

- **Chapter** `A[N]` → a landing page `<chapter>/index.html` (route `…/why`, `…/decomposition`).
- **Module** `A[N].[M]` (two-digit M) → a hub `<chapter>/<module>/index.html`.
- **Subpage** `A[N].[M].[S]` → a deep-dive lesson `<chapter>/<module>/<sub>.html` (≥3 per module — the "Dives
  into" list on the hub).

(A0 is the historical exception: its landing `/what` doubles as the A0.2 module hub. Every chapter from A1 on
nests its modules under the chapter dir.)

## The four living views — change one, change all

A change to course structure must land in all of these or they drift apart (the `agile-course-writer` skill, the
`jonnify-cms` validator, and the `watch.sh`/`reconcile.sh` watcher all assume they agree):

| View | Path | Role |
|---|---|---|
| The served pages | `html/agile-agent-workflow/` | what ships; the route manifest is the home `index.html` |
| Per-page md sources of record | `docs/agile-agent-workflow/content/<chapter>/<module>/<page>.md` | author here first; the HTML is hand-built from these |
| Living table of contents + abstracts | `docs/agile-agent-workflow/agile-agent-workflow.toc.md` | per-chapter / per-module abstracts + build status |
| Machine route/status map | `.claude/skills/agile-course-writer/references/course-map.md` | the A0–A7 route table + the **resume point** |

A fifth, the machine-readable agent brief, mirrors the first four: `docs/agile-agent-workflow/llms.md` (the
`llmstxt.org` convention the course itself teaches).

## The validator — ship only at STATUS: PASS

`apps/jonnify-cms/bin/cms` is the **source of truth for the gates and the resolvable routes** (build it with
`cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .`). Ten gates: `containers` · `svg` · `no-future` ·
`voice` · `storage` · `motion` · `degrade` · `links` · `pager` · **`refs`** (the agile mandate, opt-in via
`--require-refs`). Run on every page:

```bash
apps/jonnify-cms/bin/cms check \
  --routes-from /course/agile-agent-workflow=html/agile-agent-workflow \
  --chapter-alias a0=what,a1=why,a2=decomposition --require-refs \
  html/agile-agent-workflow/<path>.html
```

**The home `index.html` is the route manifest** — it forward-links chapters not yet built, so it FAILS `links` by
design. Every *lesson/hub* page must keep all internal links resolving.

### Gate-invisible — verify these by reading (the gates cannot)

1. **Clamp spacing.** `clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` must keep spaces around `+`/`-`. `1.9rem+4.2vw` is
   invalid CSS → the whole declaration is dropped → UA-default fallback (h1 renders at ~32px). The gates strip
   `<style>`, so they never see it. `cms check --fix` repairs it deterministically.
2. **Right route vs. resolvable route.** `links` proves an href *resolves*, not that it is the *intended* parent.
   Read crumbs and pager.
3. **Real Sources links.** `refs` only checks the block is present. Every `<li>` under **Sources** must be a real,
   vetted external `https://` link — reuse the registry below; never fabricate a URL.

## The two mandatory layout rules (drift source — enforce on every page)

These caused cross-page drift before they were codified; they are now non-negotiable:

1. **Clickable segmented route-tag** (the Elixir pattern). In `<header class="site">`, the `.route-tag` renders
   each path part as its own element: intermediate parts are `<a href>` links to that route level, the current
   (last) part is `<span class="rcur">`, separated by `<span class="rsep">/</span>`; `/course/agile-agent-workflow`
   is one segment. Keep the `.route-tag a` / `.rsep` / `.rcur` CSS.
2. **Canonical 3-column footer** (no one-off footers). `<footer class="site-foot">` → `.foot-cols` (brand + `.tag`
   / a chapter-or-module column / a "The course" column) + `.foot-bottom` carrying the `.stamp` + decoder script
   (verbatim; a valid `TSK…` Snowflake id).

The way to satisfy both without thinking is rule #0: **copy the `<head>`…`</style>`, `<header>`, `<footer>`, and
the two trailing `<script>` blocks verbatim from a recent BUILT model page**, then change only `<title>`/`<meta>`,
the route-tag, and the `<main>` body. Good models: `why/two-layers/index.html` (hub), `why/two-layers/spec.html`
(lesson), `why/index.html` (chapter landing).

## No-invent guards

- **Portal API.** Use only `Portal.ID.generate/1` and `Portal.ID.decode/1` (`.type`, `.timestamp`). The Portal's
  surfaces are a branded store, an event-sourced engine behind ONE facade, a Phoenix web app, a Telegram bot, and
  a student dashboard — invent no others. Cite the companion `/elixir` course for OTP internals; do not re-teach.
- **Voice.** No first person, no exclamation marks, no emoji, none of {just, simply, obviously, effortless,
  magical, revolutionary, blazing}, no perceptual/interior-state verbs applied to a tool or an agent.

## The Sources registry (real, vetted; reuse, never fabricate)

| Title | URL |
|---|---|
| The Pragmatic Programmer | `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/` |
| Extreme Programming Explained | `https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/` |
| Specification by Example | `https://gojko.net/books/specification-by-example/` |
| User Stories Applied | `https://www.mountaingoatsoftware.com/books/user-stories-applied` |
| Continuous Delivery | `https://continuousdelivery.com/` |
| INVEST in Good Stories | `https://xp123.com/articles/invest-in-good-stories-and-smart-tasks/` |
| Gherkin reference | `https://cucumber.io/docs/gherkin/reference/` |
| User-story template (Connextra) | `https://www.agilealliance.org/glossary/user-story-template/` |
| The `llms.txt` convention | `https://llmstxt.org/` |
| Anthropic — Building effective agents | `https://www.anthropic.com/engineering/building-effective-agents` |

The course home `html/agile-agent-workflow/index.html` is the canonical copy of this registry. The full canon is
the Appendix of `agile-agent-workflow.toc.md`.

## How a batch is run (the fan-out, user-confirmed)

1. **Draft the md source first** under `content/<chapter>/<module>/`.
2. **Author the module hub**, then **fan out one `agile-expert` subagent per dive (or per module), in parallel.**
   Spawn with the `Agent` tool, `subagent_type: "agile-expert"`. Each agent loads the skill, copies a model page,
   and is given: the exact route + numbering, the topic/abstract (from the TOC), the model page, the gate command,
   the no-invent guards, and an explicit **no-git** constraint. Lock cross-links between the parallel pages up
   front (each pager's forward link points at a sibling still being built — a `links` FAIL on **that one sibling**
   is expected until it lands).
3. **Gate every page** to STATUS: PASS; adversarially verify the gate-invisible bits.
4. **Relink the chapter landing yourself** (the orchestrator, not the parallel agents — they would conflict on the
   shared landing file): turn each built module's `.mod` `<div>` into `<a class="mod" href="…">`, flip its pill
   `soon`→`built`/`live`, and point the chapter `.note`/pager forward.
5. **Sync the four views** — the served pages, the TOC, `course-map.md`, and `llms.md` — so they agree, and confirm
   new routes 200 and still-unbuilt siblings 404 against the running server (`:8765`).

## Operational notes

- **Never run git** in an authoring agent — leave changes in the working tree; the operator commits batches
  out-of-band (the tree goes clean between turns).
- **Local server:** `make watch` (auto-restarts only on root `.go` changes; HTML is served live). Port **8765**.
  `GOWORK=off` is mandatory for any `go` command in this workspace.
- **Resume point:** always read the bottom of `course-map.md` — it names the next gap. As of this writing: A0 built
  (`/what`); A1 has A1.01–A1.04 + A1.06 built, **A1.05 (`/why/correct`) is the one A1 gap**; A2 landing built
  (`/decomposition`), modules A2.01–A2.07 in progress; A3–A7 planned.
