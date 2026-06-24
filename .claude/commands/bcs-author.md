---
description: bcs-author — the CROSS-COURSE engine that authors NEW pages of either BCS consumer course (/redis-patterns or /echomq) born in the new Branded Component System direction. Like /bcs-reconcile it routes per chapter (R<N> = redis, E<N> = echomq) and loads the bcs-writer calibration overlay (the five deltas: bcs.N.md figure source · EchoStore · codemojex · the persistence floor + the /echo-persistence door · the refined branded-id canon) composed on the per-course craft skill (redis-course-writer / echo-mq-writer), but it AUTHORS greenfield pages from the spec rather than reconciling existing ones. Fans out one per-course expert per module, builds the manifest pages (orchestrator-only), adversarially gates with the BCS scrubs, syncs the TOC. Author only from the spec + the manuscript; never invent; never a .out; never the retired content/bcsN.* path; never git.
argument-hint: <course> <chapter> <module-slug>[:dive1,dive2,dive3] …  — course is redis|echomq (or inferred from R<N>/E<N>). e.g. /bcs-author echomq bus events-log time-travel archive  ·  /bcs-author R5 streams-events stream-add consumer-groups
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep, Skill, AskUserQuestion
model: opus
---

# /bcs-author — author new consumer-course pages, born in the new BCS direction

You are authoring **new pages** of a BCS consumer course — **Redis Patterns Applied** (`/redis-patterns`) or **EchoMQ,
In Depth** (`/echomq`) — **born calibrated** to the new manuscript `docs/echo/bcs/bcs.N.md`. This is the greenfield
sibling of `/bcs-reconcile`: same routing, same calibration overlay, but you **build from the spec + the manuscript**
rather than re-grounding existing pages. The page authoring flow is the per-course one (`/redis-write` for redis,
`/echo-mq-write` for echomq); this command adds the **`bcs-writer`** calibration so a new page never repeats the old
EchoCache / Exchange / `content/bcsN.*` drift.

**The authority is `bcs-writer`** (the cross-cutting direction) **composed with the per-course craft skill** +
**the per-course spec system** (the structure/grounding — never invent either). **Author only from the spec and the
manuscript; never invent structure or grounding.**

## Arguments & routing

```
$ARGUMENTS
```

Token 1 (or an `R<N>`/`E<N>` prefix) selects the **course**; the rest are the chapter + one module each
(`<module-slug>` or `<module-slug>:<dive1>,<dive2>,<dive3>`, ≥3 dives). Resolve via the
[canon digest](../skills/bcs-writer/references/bcs-canon.md) §5:

- **redis / `R<N>`** → craft **`redis-course-writer`** + **`redis-expert`**; identity **contract-sheet**; spec system
  `docs/redis-patterns/specs/<slug>/` (chapter spec + per-module quad) + the content-map spine.
- **echomq / `E<N>`** → craft **`echo-mq-writer`**; identity **dark-editorial** + `[RECONCILE]` md shadow; canon
  `docs/echo_mq/` (the content-map + the stream-tier canon for the Bus).

If only a chapter is given, **do not guess** — read the chapter's module ladder and either author all of it or
`AskUserQuestion` which modules. `B<N>` is the **manuscript source** (`docs/echo/bcs/bcs.N.md`), never a build target.

## Step 0 — Ground the batch (read-only)

1. Invoke **Skill `bcs-writer`** + read `references/bcs-canon.md` (the deltas, figure inventory, door map).
2. Invoke the **per-course craft skill** + read its `references/course-map.md`.
3. Read the **chapter spec** (redis: `specs/<slug>/<slug>.md`; echomq: the content-map row + the stream-tier canon)
   and the **manuscript chapter(s)** the pages ground in (`docs/echo/bcs/bcs.N.md` — the figure home per the digest).
4. For each module resolve: its number, slug, **grounding artifact** (the real `echo/apps` surface + the `bcs.N.md`
   figure), served route, dive slugs, pager position.
5. **Pick the model page** per the per-course skill (redis: a **reframed** contract-sheet page — never a
   dark-editorial one; echomq: a built dark-editorial echomq page, or bootstrap from `elixir/index.html`).

## Step 1 — De-risk (once)

Build the validator: `cd go/jonnify-cms && GOWORK=off go build -o bin/cms .`. Confirm the cited surfaces exist
(`echo/apps/echo_store` + `graft.ex` + `echo/apps/echo_graft` + `echo/apps/codemojex` + `docs/echo/bcs/bcs.N.md` +
`html/echo-persistence`). Confirm `html/<course>/<chapter>/` exists (create if needed).

## Step 2 — Author the manifest landing first, then fan out the modules

The home map + the chapter landing are **route manifests** — author/relink them yourself (orchestrator-only), never
the parallel agents. Then spawn **one per-course expert per module, all in one message** (`redis-expert` /
`echo-mq-expert`; fall back to `general-purpose`). Brief each by pointer:

> You are authoring MODULE `<id>` of `<course>/<chapter>`, **born in the new BCS direction**. Read **both** skills:
> your per-course craft skill (**`redis-course-writer`** / **`echo-mq-writer`**) AND the **`bcs-writer`** overlay; then
> the page's spec + the manuscript chapter named in your brief. Build the hub + dives from the spec (md-first, then
> HTML) in your course's identity; ground every figure in a **real `echo/apps` surface or a verbatim `bcs.N.md`
> figure**, applying the five deltas (figure source = `bcs.N.md`; EchoStore not EchoCache; codemojex not Exchange;
> door to `/echo-persistence` at the durability/archive frontier; the id vectors verbatim). Two interactives per
> dive, the per-course gate + the BCS scrubs (0 EchoCache · 0 Exchange · 0 `bcs/content/bcs`). Ship at STATUS: PASS.
> NEVER run git; edit ONLY your module's files; do NOT touch the landing or the home.

## Step 3 — Adversarially verify

Run the **per-course gate** (with `--routes-from /echo-persistence=html/echo-persistence` added) on every new page,
then the **BCS scrubs** (the same block as `/bcs-reconcile` Step 3 — 0 EchoCache · 0 Exchange · 0 `bcs/content/bcs`;
every `(EchoStore|EchoMQ|EchoWire|Codemojex)\.` surface re-found on disk; cited id vectors verbatim) and the
per-course gate-invisible checks (redis: font-leak/no-BullMQ/clamp/voice; echomq: no-version/frozen-tree/no-`file:line`/
no `[RECONCILE]` in HTML). Use `/usr/bin/grep` + `/usr/bin/find`. Re-find every figure verbatim in its source; fix any
defect (do-no-harm); re-gate to PASS.

## Step 4 — Build/relink the manifests (orchestrator-only)

Turn each new module's card `<div class="mod">` → `<a class="mod" href>` + flip `soon`→`built`; keep the full
links-PASS (unbuilt entries stay non-anchor `soon` cards). Re-gate both manifest pages.

## Step 5 — Sync the views

Per course: the route-mirror md (Step 2); the TOC/content-map (mark built); the door map (`redis-patterns.echomq-doors.md`
for an R↔E edge; add the `→ /echo-persistence` edge where a new page reaches the durability/archive frontier); the
chapter `llms.txt`; the resume point. No redundant status prose in nav pages.

## Step 6 — Report

Per page: route, course, grounding (the real artifact + the `bcs.N.md` figure), the deltas honoured, the gate grade.
Note any defect fixed (invented surface / a `content/bcsN.*` slip / a stale EchoCache or Exchange), the manifests
relinked, the views synced, the next gap, and whether each expert resolved or fell back to `general-purpose`.
**Do not commit** — the Operator commits batches out-of-band; the spawned agents must not run git either.
