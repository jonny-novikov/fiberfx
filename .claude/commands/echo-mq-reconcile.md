---
description: echo-mq-reconcile — the engine that (re)builds an "EchoMQ, In Depth" course chapter to the THREE-PILLAR target design. Wipes the chapter's old off-target internals and rebuilds it fresh from a persistent <chapter>.prompt.md, fanned out one echo-mq-expert per module. Grounded in real code (echo/apps/echo_mq + echo_wire + echo_cache) where it exists and the design canon (emq.roadmap.md §stream-tier + emq3.specs.md) where it doesn't. Four disciplines — as-shipped (no versions), extract-and-annotate code (two-beat Lua, no file:line), the [RECONCILE] md shadow, no-invent. Dark-editorial (no re-skin); never the frozen echo/apps/echomq tree; never git.
argument-hint: <chapter> (overview · protocol · queue · bus · cache · proof)  ·  <chapter>/<module>  ·  <chapter>/<module>/<dive>  ·  empty (next per the resume point)
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep, Skill, AskUserQuestion
model: opus
---

# /echo-mq-reconcile — (re)build a chapter to the three-pillar target

> **⚠ BCS CALIBRATION (2026-06-25).** This command predates the new BCS manuscript and still names **`EchoCache.*`**
> (→ **`EchoStore.*`** / `echo/apps/echo_store`) and **`Exchange.*`** (→ **`codemojex`** / `echo/apps/codemojex`, B7),
> cites the retired figure source `docs/echo/bcs/content/bcsN.*` (→ **`docs/echo/bcs/bcs.N.md`**), and builds the cms at
> the stale `apps/jonnify-cms` (→ **`go/jonnify-cms`**). For a run that brings the echomq course to the **new BCS
> direction**, prefer **`/bcs-reconcile E<N>`** (it loads the `bcs-writer` overlay + composes this engine's
> dark-editorial discipline). Use this command directly only for an echomq change that is **not** about the BCS deltas.

You are bringing a chapter of the jonnify **"EchoMQ, In Depth"** course (served at `/echomq`) to the **three-pillar
target design**. In the current model this is a **build/rebuild to target**, not a preserve-and-retarget: the old
course internals are off-target (a different structure, version framing, the retired v1-line teaching), so this engine
**wipes the chapter's old content and rebuilds it fresh** from a durable per-chapter brief. The course teaches **one
shipped Valkey-native system you own, canonical in Elixir**, as **three pillars** (the Queue · the Bus · the Cache)
above one wire, with an Overview, a Protocol foundation, and a Proof chapter.

The craft is the **`echo-mq-writer`** skill + the **`echo-mq-expert`** agent; the structure/grounding authority is the
program canon `docs/echo_mq/` + the as-built code. **Ground in real code where it exists, the design canon where it
doesn't, and never past either.** This is the sibling of `/echo-mq-write` (greenfield authoring); both obey the same
four disciplines below.

## Arguments & scope

```
$ARGUMENTS
```

The chapters are the six named sections (course-map §2): `overview` (home + `/echomq/overview`) · `protocol` · `queue`
· `bus` · `cache` · `proof`. Then:

- **A CHAPTER** — `<chapter>` (e.g. `protocol`) → (re)build the chapter landing + **every module** in it (the default).
- **A MODULE** — `<chapter>/<module>` → the hub + all its dives.
- **A PAGE** — a full route tail → that one page.
- **Empty** → read `references/course-map.md` §9 (resume point) and build the next chapter in the program order, or ask
  in plain text which scope (do **not** guess a large scope).

## The target — the four disciplines + the build checklist

A chapter conforms when **all** of these hold. **(A)** is the four authoring disciplines (the heart of the new
course); **(B)** the binding craft rules; **(C)** the gate-invisible conventions.

### (A) The four authoring disciplines — apply per page

1. **As-shipped voice, NO versions.** Teach every capability present tense, as one shipped system. **No "2.0 / 3.0"**
   label in prose, no "tracked as it is built", no live build-status, no "the break". A real wire constant inside a
   code extract is fine **as code**; never as the framing.
2. **Extract-and-annotate code; Lua in two beats; NO `file:line`.** Lift the atomic **Elixir** fn onto the page as a
   `pre.code` block with **added teaching comments** that explain the idea. For Lua: first the **named handle** (e.g.
   `EchoMQ.Jobs @enqueue`), then a **separate** Lua block with the **real script body** (`if string.sub(ARGV[1],1,3)
   == kind …`), deeply commented (the branded-id gate, the `KEYS`/`ARGV` contract, each atomic transition). **Never
   print a `file:line` citation.** Extracts are verbatim source (no highlight `<span>`s, decode entities).
3. **The `[RECONCILE]` shadow.** In the **markdown source-of-record only** (`docs/echo_mq/course/markdown/<route>.md`),
   add an inline **`[RECONCILE: what is ahead of as-built code + the canon that specifies it]`** at every claim
   grounded in the design canon rather than real code — chiefly the entire **Bus/streams depth** (cite `emq.roadmap.md`
   §stream tier / `emq3.specs.md` emq3.N). Real-code claims carry no marker. **The HTML NEVER contains a `[RECONCILE]`
   marker.** These are the iteration-2 worklist (indexed in `echo_mq.course.progress.md`).
4. **No-invent — real-code-or-canon, never past either.** Ground in the real code (`echo/apps/echo_mq` + `echo_wire` +
   `echo_cache`) where it exists (Protocol, Queue, Cache, the Bus's pub/sub) and in the design canon where it doesn't
   (the Bus's streams). Never invent a Lua script, key, field, module, or arity. **The one-way guard:** the frozen,
   unrelated tree `echo/apps/echomq` (no underscore) is **NOT part of this course** — never cite it (`EchoMQ.Keys`,
   `LockManager`, `Scripts`, `Worker`, `moveToActive` → 0 on every page).

**The design STAYS dark-editorial — this command does NOT re-skin** (unlike `/redis-reconcile`). It rebuilds content +
structure to the target; it never changes the visual identity tokens, the header/footer shell, or the layout system.

### (B) The binding craft rules (surface-aware)

5. **The pillar/source is the content spine** *(HUBS)*. A module hub's `.lede` + `<h2>` order follow its pillar's
   logic and the as-built surfaces it teaches (the content-map row + the chapter prompt's `## MODULE` section).
   Framing/interactives/`.bridge`/dives layer after. *(DIVES* re-root only on drift. *LANDINGS* state the pillar +
   carry the `.applied` block but have no single source spine; the Overview landing has no `.applied`.)
6. **References is a two-column block** *(ALL pages)*. `<section id="refs">` → `<div class="refs">` → two child
   `<div>`s (`<h3>Sources</h3>` / `<h3>Related in this course</h3>`),
   `.refs{display:grid;grid-template-columns:1fr 1fr;gap:1.4rem 2.4rem}` (+ `@media(max-width:680px){.refs{grid-template-columns:1fr}}`).
7. **Route-mirror md** *(ALL pages)*. `docs/echo_mq/course/markdown/<route>.md` exists, mirrors the HTML (the
   pattern↔implementation spine + a two-column `## References`), and carries the `[RECONCILE]` shadow (A3).

### (C) The gate-invisible conventions

8. **clamp()** values spaced. 9. **Segmented clickable route-tag** (`/echomq` one segment; leaf `.rcur`).
10. **Canonical 3-column footer** + valid `TSK…` stamp. 11. **The `.bridge`** (`.cell.idea` = the redis-patterns
    pattern → `.cell.elix` = the real `echo/apps/echo_mq` implementation) + a `.take`; ≥1 interactive on a hub, two per
    dive (real computation, degrades, reduced-motion, no storage). 12. **Voice** — a worker / queue / script / cache /
    runtime does not "see" / "want" / "know" / "decide". 13. **Pager loop + crumbs** at intended parents (hub
    `prev`=landing, `next`=first dive; dives chain hub→dive1→…→hub). 14. **No invented surface** — every `EchoMQ.*` /
    `EchoWire.*` / `EchoCache.*` / `Exchange.*` is real in `echo/apps/echo_mq`/`echo_wire`/`echo_cache` OR specified in
    canon (canon ⇒ `[RECONCILE]` in the md); every `/redis-patterns` `/elixir` cross-link resolves.

## Step 0 — Ground the batch (read-only)

1. Invoke the **Skill tool with skill `echo-mq-writer`**; read its standing rules + `references/course-map.md` (the
   spine, routes, the as-built grounding map §3b, the four disciplines, the resume point).
2. Read the chapter's row in the content-map `docs/echo_mq/course/echo_mq.course.md`; for a Bus page also read the
   **§stream-tier** section of `emq.roadmap.md` + `emq3.specs.md` (the canon grounding).
3. For each target module resolve: its pillar, the **as-built surfaces** to teach (read them in `echo/apps/echo_mq` /
   `echo_wire` / `echo_cache` — the real fn + **verified arity**; mark each MATCH=real or CANON=specified), its dive
   slugs, and its served routes.
4. **Audit any current pages** at the route to scope the wipe:
   ```bash
   D=html/echomq/<chapter>
   ls -R $D 2>/dev/null                                                            # what exists to wipe/replace
   grep -rniE '2\.0|3\.0|the break|frozen at|as it is built|movement (I|II)' $D/   # off-target version/movement framing
   grep -rnoE 'echo/apps/echomq\b|EchoMQ\.Keys\b|EchoMQ\.LockManager|EchoMQ\.Scripts|moveToActive|EchoMQ\.Worker' $D/  # frozen-tree citations
   ```
   Read the **model page** — a built echomq page of the same surface in the target identity (for the first page of a
   surface, bootstrap from `elixir/index.html`).

## Step 1 — De-risk (once)

Build the validator: `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .` (GOWORK=off mandatory). Confirm the
surfaces a build will cite exist: `ls echo/apps/echo_mq/lib/echo_mq/`, `echo/apps/echo_wire/lib/echo_mq/`,
`echo/apps/echo_cache/lib/echo_cache/`; for a Bus chapter, confirm the §stream-tier canon + `emq3.specs.md`.

## Step 1.5 — Author the persistent chapter prompt (orchestrator-only) — THE durable artifact

Before any fan-out, WRITE the durable per-chapter brief at **`docs/echo_mq/course/<chapter>.prompt.md`** (e.g.
`docs/echo_mq/course/protocol.prompt.md`). It crystallizes Step 0's grounding into a reusable file the subagents read
(rather than an ephemeral inline brief). Skeleton (course-map §5):

- **Status blockquote** — who reads it + HOW ("one echo-mq-expert (re)builds ONE module from its `## MODULE` section;
  read the echo-mq-writer skill, this brief's Shared context, then your section, then the model page. FRESH BUILD to
  the target — wipe the old route content; do NOT re-skin.").
- **The thesis in one paragraph** — the chapter's place in the one-system / three-pillar identity.
- **Shared context (every module)** — chapter/routes/dirs/md-mirror root; the **as-built floor** (every surface the
  chapter teaches, verified on disk, MATCH=real or CANON=specified→`[RECONCILE]`); the **four disciplines** (A1–A4);
  the model page; the sources allow-list; the resolving cross-course doors; the **gate command**; the **hard
  constraints** (NEVER git; edit ONLY this module's `html/echomq/<chapter>/<module>/` files + its md mirror; landings /
  home / content-map / llms.txt are orchestrator-only).
- **One `## MODULE <id> · <name>` section per fan-out target** — a **Directive** (what to teach, the extracted Elixir +
  the two-beat Lua, the pattern↔implementation bridge, the interactives) + a **Gate** (STATUS: PASS + the per-module
  scrubs).
- **Acceptance — "<chapter> built" means** · **Inputs** (content-map · canon · model page · skill · agent · command).

This file is itself a synced view (Step 5) — re-pin its floor if a surface moves.

## Step 2 — Wipe + fan out one echo-mq-expert per module (point them at the prompt)

If the route holds off-target content, **wipe it** (the chapter's old `html/echomq/<chapter>/` page set + its md
mirror) so the rebuild is clean — the operator granted the wipe; the page set is being replaced, not preserved.

Spawn **one `echo-mq-expert` per module** (all in one message for a chapter run). Use
`subagent_type: "echo-mq-expert"`; on "agent type not found" fall back to `general-purpose`. Point each at its section
of the persistent prompt — do **not** restate the brief inline:

> You are (re)building MODULE `<id>` of `<chapter>` for "EchoMQ, In Depth". Read the **`echo-mq-writer`** skill, then
> **`docs/echo_mq/course/<chapter>.prompt.md`** — its Shared context (every module) and your `## MODULE <id>` section.
> Build only that module's pages (hub + dives) to your section's Directive — md-first (with `[RECONCILE]` markers at
> canon-only claims), then the HTML to match. Obey the four disciplines (as-shipped/no-versions · extract-and-annotate
> two-beat Lua, no file:line · `[RECONCILE]` in md only · no-invent / never the frozen `echo/apps/echomq`). Dark-editorial,
> no re-skin. Ship only at your section's Gate STATUS: PASS. NEVER run git; edit ONLY your module's files.

A **chapter landing** is **orchestrator-only** — you build it yourself (the four disciplines; it states the pillar,
carries the 2-col refs + the `.applied` block, no single source spine; the Overview landing + home carry no `.applied`).

## Step 3 — Adversarially verify (do NOT trust "all PASS")

For each page, gate (zsh: `${=FLAGS}`), then run the scrub:

```bash
FLAGS="--routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns --routes-from /elixir=elixir --routes-from /bcs=html/bcs --require-refs"
D=html/echomq/<chapter>
for p in $(find $D -name '*.html'); do printf "%s " "$p"; apps/jonnify-cms/bin/cms check ${=FLAGS} "$p" 2>&1 | grep -oE 'STATUS: (PASS|FAIL)'; done
grep -rnoE 'echo/apps/echomq\b|EchoMQ\.Keys\b|EchoMQ\.LockManager|EchoMQ\.Scripts|moveToActive|EchoMQ\.Worker' $D/ || echo "frozen-tree clean OK"   # A4 one-way guard: empty
grep -rniE '2\.0|3\.0|version [0-9]' $D/ | grep -viE 'echomq:[0-9]' || echo "no-version label OK"      # A1: only code-constant contexts
grep -rn '\[RECONCILE\]' $D/ && echo "RECONCILE LEAKED INTO HTML — remove" || echo "no [RECONCILE] in HTML OK"   # A3: empty
grep -rnoE 'file:line|\.ex:[0-9]+|\.lua:[0-9]+|lib/echo_mq/[a-z_]+\.ex:[0-9]' $D/ || echo "no file:line OK"        # A2: empty
grep -rnoE '(EchoMQ|EchoWire|EchoCache|Exchange)\.[A-Za-z._]+' $D/ | sort -u    # A4: cross-check each in echo/apps/echo_mq|echo_wire|echo_cache OR canon (canon ⇒ [RECONCILE] in md)
for p in $(find $D -name '*.html'); do grep -c 'grid-template-columns:1fr 1fr' "$p"; done   # rule 6: ≥1 each
find docs/echo_mq/course/markdown/<chapter> -name '*.md'                         # rule 7: one md per page
for p in $(find $D -name '*.html'); do node --check <(sed -n '/<script>/,/<\/script>/p' "$p" | sed '1d;$d') 2>&1 | head -1; done  # scripts parse
grep -rnoE 'clamp\([^)]*\)' $D/ | grep -E '[0-9a-z](\+|-)[0-9]' || echo "clamp OK"
```

**Re-find every quoted figure** (key / verb / wire string / module / arity) verbatim in its real `echo/apps/echo_mq`
source OR in the canon (`emq.roadmap.md` §stream tier / `emq3.specs.md`) — a canon-only figure must carry a
`[RECONCILE]` in the md. Confirm: no version label in prose; no `file:line`; every Lua block has a named handle; zero
`[RECONCILE]` in HTML; the frozen tree is uncited. Fix any defect yourself (do-no-harm), re-gate to PASS.

## Step 4 — Build/relink the manifests (orchestrator-only)

- **The chapter landing** (`<chapter>/index.html`): build/relink to the modules (flip each card `soon`→`built`, resolve
  hrefs); state the pillar; carry the `.applied` block (except Overview). Dark-editorial, route manifest (a `links`
  FAIL on still-unbuilt forward routes is expected). Re-gate.
- **The home map** (`index.html`): relink the chapter's modules; keep the full links-PASS philosophy (unbuilt sections
  stay non-anchor `soon` cards). Re-gate.

## Step 5 — Sync the views

- the route-mirror **md** with its `[RECONCILE]` markers (Step 2/3);
- **`docs/echo_mq/course/echo_mq.course.md`** (the content-map) — mark the chapter built; keep the spine accurate;
- **`docs/echo_mq/course/echo_mq.course.progress.md`** — re-true the dashboard + the **`[RECONCILE]` ledger index**
  (the grep over the md mirror);
- **`references/course-map.md`** (the skill digest) — update the resume point;
- the **`llms.txt`** for the chapter (orchestrator-owned) — mirror the built structure;
- the **`<chapter>.prompt.md`** floor — re-pin if a surface moved.
- Do not write redundant status prose into nav pages — the pills show status.

## Step 6 — Report

Summarise per page: route, what was built, the grounding (per surface: real vs canon→`[RECONCILE]`), and the gate
grade. Note the `[RECONCILE]` markers written (the iteration-2 worklist), any defect fixed (a frozen-tree slip, a
version-label leak, a `file:line` caught), the manifests relinked, the views synced, and the next chapter. Confirm the
design stayed dark-editorial (no re-skin) and the persistent `<chapter>.prompt.md` was authored. Note whether
`echo-mq-expert` resolved or fell back to `general-purpose`. **Do not commit** — the operator commits batches
out-of-band; never `git add`/`commit`/`restore`, and the spawned agents must not either.
