---
description: echo-mq-write — greenfield authoring for the "EchoMQ, In Depth" course. Fan out echo-mq-expert subagents to author a NEW chapter's pages (landing, module hubs, dives, workshop) in parallel from a persistent <chapter>.prompt.md, then build/relink the manifest pages + adversarially gate + sync the views. The greenfield sibling of /echo-mq-reconcile (which wipes + rebuilds an existing chapter); both obey the same four disciplines. Dark-editorial; one shipped system, three pillars; grounded in echo/apps/echo_mq + the design canon.
argument-hint: <chapter-slug> <module-slug>[:dive1,dive2,dive3] [<module-slug>…]  (chapters: overview · protocol · queue · bus · cache · proof)
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep, Skill, AskUserQuestion
model: fable
---

# /echo-mq-write — greenfield parallel authoring for the "EchoMQ, In Depth" course

You are authoring a **NEW chapter** (no existing pages at the route) of the jonnify **"EchoMQ, In Depth"** course
(served at `/echomq`) — the depth course on the far side of every `→ EchoMQ` door in `/redis-patterns`. This is the
**greenfield sibling of [`/echo-mq-reconcile`](echo-mq-reconcile.md)** (which wipes + rebuilds an *existing*,
off-target chapter): the flow, the four disciplines, the persistent-prompt mechanism, and the gate are **identical** —
the only difference is there is no old content to wipe. **Read `/echo-mq-reconcile` for the full engine; this command
is the greenfield entry point.**

EchoMQ is **one shipped Valkey-native system you own, canonical in Elixir**, organized as **three pillars** (the Queue ·
the Bus · the Cache) above one wire, with an Overview, a Protocol foundation, and a Proof chapter. The craft is the
**`echo-mq-writer`** skill (read its `references/course-map.md`); the structure/grounding is the program canon
`docs/echo_mq/` (`emq.roadmap.md` incl. §stream-tier, `emq.design.md`, `emq3.specs.md`) + the as-built code
`echo/apps/echo_mq` (+ `echo_wire` / `echo_cache`). The design is **dark-editorial** (never contract-sheet).

## The four authoring disciplines (identical to /echo-mq-reconcile §A)
1. **As-shipped, NO versions** — present tense, one system; no "2.0/3.0" label, no "tracked as it is built".
2. **Extract-and-annotate code; Lua in two beats; NO `file:line`** — lift the real Elixir fn with teaching comments;
   Lua = the named handle (`EchoMQ.Jobs @enqueue`) then a separate commented script body.
3. **The `[RECONCILE]` shadow** — the md source-of-record flags every canon-grounded claim (chiefly the Bus/streams
   depth: `emq.roadmap.md` §stream tier / `emq3.specs.md`); never leaks into the HTML.
4. **No-invent** — real code where it exists, design canon where it doesn't, never past either; **never** the frozen,
   unrelated `echo/apps/echomq` tree (`EchoMQ.Keys`/`LockManager`/`Scripts`/`Worker`/`moveToActive` → 0 on every page).

## Arguments
```
$ARGUMENTS
```
**Token 1 = the chapter** (a section slug: `overview · protocol · queue · bus · cache · proof`). **Special: `overview`**
= the home `index.html` (the six-section map) + the overview landing + dives (no `.applied` block). **Tokens 2…N = one
module each**, `<module-slug>` or `<module-slug>:<dive1>,<dive2>,<dive3>` (**≥3** dives). The chapter closes with a
**workshop** module. If only the chapter is given, **do not guess** — read the content-map row and either author every
module implied or `AskUserQuestion` which to author.

## The flow (see /echo-mq-reconcile for the full step detail)

- **Step 0 — Ground (read-only).** Invoke the **`echo-mq-writer`** skill; read `references/course-map.md` (the spine,
  routes, the as-built grounding map §3b, the four disciplines). Read the chapter's content-map row + (for a Bus page)
  the §stream-tier canon. For each module resolve its pillar, the **as-built surfaces** (read them in `echo/apps/…`,
  verify arity — MATCH=real / CANON=specified→`[RECONCILE]`), its dives, and its routes. Pick the **model page** (a
  built echomq page of the surface; bootstrap the first page from `elixir/index.html`).
- **Step 1 — De-risk.** Build the validator (`cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .`); confirm the
  surfaces exist; create `html/echomq/<chapter>/`.
- **Step 1.5 — Author the persistent prompt** at `docs/echo_mq/course/<chapter>.prompt.md` (orchestrator-only):
  status blockquote ("greenfield build to target; do NOT re-skin") → the thesis → Shared context (the as-built floor,
  the four disciplines, the model page, the sources, the resolving doors, the gate command, the hard constraints) →
  one `## MODULE` section per target (Directive + Gate) → Acceptance → Inputs.
- **Step 2 — Author the manifest landing first, then fan out.** The **home map + the chapter landing are route
  manifests** (orchestrator-only). Then spawn **one `echo-mq-expert` per module, in one message**
  (`subagent_type: "echo-mq-expert"`; fall back to `general-purpose`), each pointed at its section of the persistent
  prompt: *"Read the `echo-mq-writer` skill, then `docs/echo_mq/course/<chapter>.prompt.md` — its Shared context and
  your `## MODULE <id>` section. Build only that module's pages (hub + dives), md-first (with `[RECONCILE]` at
  canon-only claims) then the HTML. Obey the four disciplines. NEVER git; edit ONLY your module's files."*
- **Step 3 — Adversarially verify.** Gate each page to STATUS: PASS, then the scrubs (course-map §7 / echo-mq-reconcile
  Step 3): frozen-tree → 0; no version label in prose; no `file:line`; every Lua block has a named handle; zero
  `[RECONCILE]` in HTML; every surface re-found in code or canon (canon ⇒ `[RECONCILE]` in md); clamp/route-tag/voice;
  scripts parse. Fix defects yourself, re-gate.
- **Step 4 — Build/relink the manifests** (home map + chapter landing; flip `soon`→`built`, resolve hrefs; the
  `.applied` block on a section landing except Overview). Re-gate.
- **Step 5 — Sync the views** — the route-mirror md with `[RECONCILE]` markers; the content-map
  `echo_mq.course.md` (mark built); the dashboard `echo_mq.course.progress.md` + the `[RECONCILE]` ledger; the skill
  digest `references/course-map.md` resume point; the chapter `llms.txt`; re-pin the `<chapter>.prompt.md` floor.
- **Step 6 — Report.** Pages authored (route + grade), the gate tally, the `[RECONCILE]` markers written, defects
  fixed, manifests relinked, views synced, the next gap. Confirm dark-editorial (no re-skin). **Do not commit** — the
  operator commits batches out-of-band; never `git add`/`commit`/`restore`, and the spawned agents must not either.
