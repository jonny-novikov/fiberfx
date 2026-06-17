---
description: agile-write — fan out agile-expert subagents to author a chapter's modules (hub + dives) in parallel, then relink + adversarially gate + sync the four living views
argument-hint: <chapter-slug> <module-slug>[:dive1,dive2,dive3] [<module-slug>[:dives] …]  (e.g. decomposition acceptance splitting value-ladder)
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep, Skill, AskUserQuestion
model: opus
---

# /agile-write — parallel module authoring for the Agile Agent Workflow course

You are orchestrating a **parallel authoring batch** for the jonnify "Agile Agent Workflow" course (served at
`/course/agile-agent-workflow`). Fan out one **`agile-expert`** subagent per module, then perform the
**orchestrator-only** steps the subagents are forbidden from doing (relink the shared chapter landing, sync the
living views, final gate). The course's authoring guide is `docs/agile-agent-workflow/CLAUDE.md`; the craft's source
of truth is the `agile-course-writer` skill. Read both if anything below is ambiguous.

## Arguments

```
$ARGUMENTS
```

Parse the argument string as whitespace-separated tokens:

- **Token 1 = the chapter.** A chapter **dir slug** (`decomposition`, `roadmap`, `spec`, …) or an `A<N>` number you
  resolve to its dir via `course-map.md`. This chapter's **landing must already exist** at
  `html/agile-agent-workflow/<chapter>/index.html` — you author its *modules*, not the chapter itself. (If the
  landing does NOT exist, stop and offer to author the chapter landing first.)
- **Tokens 2…N = one module each**, in the form `<module-slug>` or `<module-slug>:<dive1>,<dive2>,<dive3>`:
  - `<module-slug>` is the on-disk dir under the chapter → served at `/course/agile-agent-workflow/<chapter>/<module-slug>`.
  - the optional `:`-list names the dive subpage slugs (**≥3**). If omitted, the agent designs ≥3 dives from the
    module's TOC abstract.

If the arg string is empty, or only the chapter is given, **do not guess the whole chapter** — use
`AskUserQuestion` (or ask in plain text) which modules to author.

## Step 0 — Ground the batch (read-only)

1. Read `.claude/skills/agile-course-writer/references/course-map.md` (chapter table, numbering, resume point) and
   the chapter's section of `docs/agile-agent-workflow/agile-agent-workflow.toc.md` (per-module abstracts).
2. Read the chapter landing `html/agile-agent-workflow/<chapter>/index.html` and read each requested module's card to
   capture its **number** (`A<N>.<MM>`), **title**, and **one-liner**.
3. For each requested module resolve: number, title, served route, dive slugs (from args or to-design), and its
   **dependency-ordered position** in the chapter (for the pager + the build order).

## Step 1 — De-risk shared dependencies (once, so the agents don't race)

- Build the validator: `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .` (GOWORK=off is mandatory here).
- Confirm the local server answers: `curl -s -o /dev/null -w '%{http_code}' http://localhost:8765/course/agile-agent-workflow/<chapter>` → `200`. If not, `make watch` (or `make start`); port is **8765**.
- Confirm the model pages exist: `html/agile-agent-workflow/why/two-layers/index.html` (hub model) and
  `…/why/two-layers/spec.html` (lesson model).

## Step 2 — Lock cross-links, then fan out (one Agent message, parallel)

**Pager convention (model, gate-invisible — get it right):** a module **hub** pager is `prev` = the **chapter
landing**, `next` = the module's **own first dive**. Dive pagers chain hub → dive1 → dive2 → dive3 → back to hub
*within* the module. (Do NOT chain hub→sibling-module — that diverges from `why/two-layers/index.html`.)

Spawn **one agent per module, all in a single message** so they run concurrently. Use
`subagent_type: "agile-expert"`; **if that errors "agent type not found"** the def is not loaded this session — fall
back to `subagent_type: "general-purpose"` (the brief below is self-contained, so it behaves the same). Give each
agent a complete brief:

- its **module number, title, slug, served route**, and the **dive slugs** (or "design ≥3 dives from this abstract");
- the module's **TOC abstract** (ground the content — do not drift);
- **Portal grounding / no-invent:** use only `Portal.ID.generate/1` and `Portal.ID.decode/1` (`.type`,`.timestamp`);
  reuse the canonical value ladder (browse → enrol → open a lesson → track progress); cite `/elixir` for OTP, invent
  no other Portal API or surface;
- the **model pages to copy verbatim** (hub: `why/two-layers/index.html`; lesson: `why/two-layers/spec.html`) —
  change only `<title>`/`<meta>`, the route-tag, and the `<main>` body, keeping the footer stamp;
- its **locked pager links** + crumbs + `Related in this course` routes (all must resolve);
- the **mandatory rules**: clickable **segmented route-tag** (`.rsep`/`.rcur`, `/course/agile-agent-workflow` is one
  segment); canonical **3-column `.foot-cols` footer**; **References → Sources = ≥3 real vetted links** wrapped
  `<li><a href="https://…">Author &mdash; <em>Title</em></a> &mdash; gloss.</li>` reused from the registry on
  `html/agile-agent-workflow/index.html` (never fabricate a URL); **two interactives per dive** (hero + main, ≥1
  framing interactive on the hub) — real computation over a fixed dataset, live `.geo-readout` (aria-live), pure
  functions, degrades without JS, honours `prefers-reduced-motion`, no browser storage; **voice** (no first person,
  no exclamation/emoji, none of {just, simply, obviously, effortless, magical, revolutionary, blazing});
- **md-first:** also write each page's md source under `docs/agile-agent-workflow/content/<chapter>/<module>/`;
- the **gate command** and **ship only at STATUS: PASS**;
- **hard constraints:** NEVER run git; edit ONLY its own module's files + md sources; **do NOT touch the chapter
  landing** (you relink it in Step 4).

If a module's pager points at a sibling still being built in the same batch, tell that agent a `links` FAIL on that
one sibling route is expected until it lands — but with the model pager convention (next = own first dive) this
rarely arises.

## Step 3 — Adversarially verify (do NOT trust the agents' "all PASS")

Run, for each new page, the gate (in zsh, force word-split with `${=FLAGS}` — zsh does NOT split unquoted vars):

```bash
FLAGS="--routes-from /course/agile-agent-workflow=html/agile-agent-workflow --chapter-alias a0=what,a1=why,a2=decomposition,a<N>=<chapter> --require-refs"
apps/jonnify-cms/bin/cms check ${=FLAGS} <page>.html
```

(Add `a<N>=<chapter>` for the chapter you are authoring if not already in the alias list.) Then check the
gate-**invisible** failure modes the gates cannot:

- `grep -rnoE 'Portal\.[A-Za-z]+' <module dirs> | grep -v 'Portal\.ID'` → **must be empty** (invented-API guard).
- clamp() values are spaced (`1.9rem + 4.2vw`, never `1.9rem+4.2vw`); the route-tag is the exact segmented form;
  every Sources `<li>` carries `href="http`; crumbs/pager point at the **intended** parent (the `links` gate only
  proves they resolve); each inline `<script>` parses (`node --check`).
- Live crawl: every new route returns **200**, every still-unbuilt sibling returns **404**.

Fix any defect yourself, deterministically (do-no-harm — change only what is wrong), then re-gate to PASS.

## Step 4 — Relink the chapter landing (orchestrator-only)

In `html/agile-agent-workflow/<chapter>/index.html`, for each newly-built module turn its card
`<div class="mod">…</div>` → `<a class="mod" href="/course/agile-agent-workflow/<chapter>/<module-slug>">…</a>` and
flip its pill `soon` → `built`. Re-gate the landing — it must stay **STATUS: PASS**.

## Step 5 — Sync the four living views (they must agree)

- the served pages (done by the agents),
- `docs/agile-agent-workflow/agile-agent-workflow.toc.md` — mark the modules built (`✓ built` + route link + the dive
  list),
- `.claude/skills/agile-course-writer/references/course-map.md` — the chapter row status, a built-modules block, and
  the **resume point**,
- `docs/agile-agent-workflow/llms.md` — the chapter's module list with dives.

Do not write redundant status prose ("all built", "complete") into nav pages — the cards' pills already show status;
describe structure and the arc instead.

## Step 6 — Report

Summarise: pages authored (route + grade), the gate tally, any defects you fixed (especially invented-API or pager
drift), the relinked cards, the four views synced, and the next gap from `course-map.md`. Note whether the
`agile-expert` type resolved or fell back to `general-purpose`. **Do not commit** — the user commits batches
out-of-band; never `git add`/`commit`/`restore`, and the spawned agents must not either.
