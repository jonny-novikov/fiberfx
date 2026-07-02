---
description: bcs-reconcile — the CROSS-COURSE engine that brings chapters of BOTH BCS consumer courses to the new Branded Component System direction in one run. Takes mixed chapter tokens — R<N> = a /redis-patterns chapter, E<N> = an /echomq pillar — and reconciles each to the new manuscript docs/echo/bcs/bcs.N.md via the bcs-writer calibration overlay (the five deltas: figure source → bcs.N.md · EchoCache → EchoStore · Exchange → codemojex · the persistence floor + the /echo-persistence door · the refined branded-id canon), while each course keeps its OWN identity (redis re-skins to contract-sheet; echomq stays dark-editorial). Routes each token to its per-course expert + craft skill, fans out one expert per module, adversarially gates with the BCS scrubs, relinks, syncs, reports. Never invents; never a .out; never the retired content/bcsN.* path; never git.
argument-hint: one or more chapter tokens — R<N> (redis, e.g. R3 R4) · E<N> (echomq, e.g. E3) · a course section name (queues · bus) · <course>/<chapter>/<module> for one module. e.g. /bcs-reconcile R3 R4 E3
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep, Skill, AskUserQuestion
model: fable
---

# /bcs-reconcile — bring the consumer courses to the new BCS direction (one cross-course run)

You are reconciling chapters of the **two BCS consumer courses** — **Redis Patterns Applied** (`/redis-patterns`) and
**EchoMQ, In Depth** (`/echomq`) — to the **new Branded Component System manuscript** `docs/echo/bcs/bcs.N.md` (B0–B8,
all built). One run can span both courses: `R3 R4 E3` reconciles redis R3 (queues) + R4 (time-delay-priority) **and**
echomq E3 (the Bus). The **calibration** (the five deltas) is shared and owned by the **`bcs-writer`** skill; the
**identity + craft** stays per-course. This is the sibling of `/bcs-author` (which authors *new* pages to the same
direction).

**The authority is `bcs-writer`** (the cross-cutting BCS direction) **composed with the per-course craft skill**
(`redis-course-writer` for an R-chapter, `echo-mq-writer` for an E-chapter). Where they disagree on a **cross-cutting
fact** (a surface name, the figure source, a door), **`bcs-writer` wins**; on **identity/craft** (tokens, layout,
re-skin vs dark-editorial), the **per-course skill wins**. **Reconcile to fit the new direction; never invent, never
re-skin against the per-course rule.**

## Arguments & routing

```
$ARGUMENTS
```

Parse whitespace-separated tokens; route each to its course (the [canon digest](../skills/bcs-writer/references/bcs-canon.md) §5 has the full tables):

- **`R<N>`** → `/redis-patterns` chapter. Slugs: `r1=caching · r2=coordination · r3=queues · r4=time-delay-priority ·
  r5=streams-events · r6=flow-control · r7=data-modeling · r8=production-operations`. Craft: **`redis-course-writer`** +
  the **`redis-expert`** agent. Identity: **contract-sheet** (a dark-editorial R-chapter is **re-skinned**, per
  `redis-course-writer`).
- **`E<N>`** or a section name → `/echomq` pillar. `E0=overview · E1=protocol · E2=queue · E3=bus · E4=cache ·
  E5=proof`. Craft: **`echo-mq-writer`**. Identity: **dark-editorial, NO re-skin** + the `[RECONCILE]` md shadow.
- **`<course>/<chapter>/<module>`** → one module of one course.
- **Empty** → ask in plain text which chapters (do **not** guess a large scope).

> **`B<N>` is NOT a target.** Unlike `/redis-reconcile` (which aliases `B<N>→R<N>`), here `B<N>` means the **manuscript**
> chapter you ground IN (`docs/echo/bcs/bcs.N.md`), never a reconcile target. The /bcs course is the **source**.

> **Built vs build-to-target.** An R-chapter (R3/R4 exist) is reconciled in place (re-skin + recalibrate). An echomq
> pillar may be **unbuilt or transitional** (`html/echomq/bus` does not exist) — there "bring to target" means **build
> the chapter fresh to the three-pillar target**, the `echo-mq-writer` model (wipe transitional content; build clean).
> If a chapter is entirely absent and greenfield, note it and prefer `/bcs-author`.

## The target — the five deltas + the per-course discipline

A page conforms when **both** hold:

- **(A) The five BCS calibration deltas** (`bcs-writer` §1, applied verbatim): (1) figure source →
  `docs/echo/bcs/bcs.N.md` (re-home every `content/bcsN.*` citation); (2) **EchoCache → EchoStore**
  (`echo/apps/echo_store`); (3) **Exchange → codemojex** (`echo/apps/codemojex`, B7); (4) **the persistence floor** —
  cite the new tier where it grounds (`EchoStore.Graft.*` / `echo_graft` / Tigris / the durability dial / Oban the
  comparison) and **door out to `/echo-persistence`** at the durability/archive frontier; (5) **the refined
  branded-id canon** (3-char ns + 11 Base62, epoch `1704067200000`, the boot vectors verbatim).
- **(B) The per-course discipline, unchanged** — the identity, the gates, the voice, the anatomy, the no-invent rule
  of `redis-course-writer` (contract-sheet, codemojex, zero-BullMQ) **or** `echo-mq-writer` (dark-editorial,
  as-shipped/no-versions, extract-and-annotate two-beat Lua, the `[RECONCILE]` md shadow, never the frozen
  `echo/apps/echomq`). **This command does not override (B); it overlays (A) onto it.**

## Step 0 — Ground the batch (read-only)

1. Invoke the **Skill tool with skill `bcs-writer`**; read it + `references/bcs-canon.md` (the deltas, the figure
   inventory, the door map, the numbering).
2. For each token's course, invoke its **per-course craft skill** (`redis-course-writer` or `echo-mq-writer`) and read
   its `references/course-map.md` (the surface, the gates, the identity, the resume point).
3. Read the **manuscript chapters** the run grounds in (`docs/echo/bcs/bcs.N.md` — at minimum the chapter that owns
   each cited figure: `bcs.0`/`bcs.2` for id vectors, `bcs.3` bus, `bcs.4` store, `bcs.5` persistence, `bcs.7`
   codemojex). The manuscript **body wins** on a figure.
4. For each target module resolve: its dir + served routes, the **real `echo/apps` surfaces** each figure re-grounds
   onto (read them — `echo/apps/echo_mq` · `echo_store` · `echo_wire` · `codemojex` · the floor `echo_store/graft*` +
   `echo_graft`), and the per-course identity (re-skin? dark-editorial?).
5. **Audit the current pages** to scope the gap (route the scrub by course):
   ```bash
   D=<chapter dir>     # html/redis-patterns/<slug> OR html/echomq/<section>
   grep -rniE 'EchoCache|echo/apps/echo_cache'    $D/   # delta 2 targets
   grep -rniE 'Exchange\.[A-Z]|echo/apps/exchange' $D/  # delta 3 targets
   grep -rn  'bcs/content/bcs'                     $D/   # delta 1 targets (retired figure source)
   grep -rniE 'dragonfly'                          $D/   # §1a.A — Valkey 9 only; reframe to Cluster hash-slots
   grep -rnE  'echomq:2\.[0-9]\.[0-9]|EchoMQ [0-9]\.[0-9]|v1 line' $D/   # §1a.B — the wire is echomq:3.0.0, no version label
   grep -rliE 'ink:#0a0e1a|Cormorant|fonts\.googleapis' $D/   # R-chapter only: still dark-editorial → re-skin
   ls -R $D 2>/dev/null || echo "absent → build-to-target / consider /bcs-author"
   ```
6. **Reachability (echomq only) — before reconciling a pillar, prove it is live (§1a.C).** A `core/` or `substrate/`
   tree may be served-but-orphaned legacy citing deleted code (the deleted Go port `apps/echomq-go`, the frozen
   `echo/apps/echomq`). If no LIVE page links in, **retire it, don't reconcile it** — a blind reconcile would polish
   pages describing a deleted world. The live spine is six pillars (overview · protocol · queue built; bus · cache ·
   proof soon).
   ```bash
   grep -rl 'href="/echomq/<section>' html/echomq --include='*.html' | grep -v '/<section>/'   # any live inbound link?
   # if empty → orphaned: rm -rf html/echomq/<section> + docs/echo/echo_mq/markdown/<section>{,.md}, then drop its
   # sitemap <url> blocks (filter html/sitemap.xml on /echomq/<section>), and re-point any door-map/spec references.
   ```

## Step 1 — De-risk (once)

Build the validator: `cd go/jonnify-cms && GOWORK=off go build -o bin/cms .` (GOWORK=off mandatory; runs from the
filesystem). Confirm the surfaces a re-ground will cite exist: `ls echo/apps/echo_store/lib/echo_store/`,
`echo/apps/echo_store/lib/echo_store/graft.ex`, `echo/apps/echo_graft`, `echo/apps/codemojex/lib/codemojex/`,
`ls docs/echo/bcs/bcs.{0,2,4,5,7}.md`, `ls -d html/echo-persistence` (the door target). Confirm `content/` is retired
(`ls docs/echo/bcs/content 2>/dev/null || echo retired`).

## Step 1.5 — Author the persistent chapter prompt (orchestrator-only)

For each chapter, WRITE the durable per-chapter brief where its course keeps them — redis:
`docs/redis-patterns/specs/<slug>/<slug>.prompt.md`; echomq: `docs/echo_mq/course/<section>.prompt.md`. Reuse the
course's existing prompt skeleton (the per-course reconcile command's Step 1.5) and **add a `## BCS CALIBRATION`
block** carrying the five deltas (verbatim from `bcs-writer` §1), the manuscript figure homes for this chapter, and
the `/echo-persistence` door + its gate mount. Each subagent reads this file, not an inline brief.

## Step 2 — Fan out one expert per module (point them at the prompt)

Spawn **one per-course expert per module** (all in one message). For an R-chapter use `subagent_type: "redis-expert"`;
for an E-chapter use `subagent_type: "echo-mq-expert"`; on "agent type not found" fall back to `general-purpose` (the
defs are self-contained). Heavy edits → md-mirror first, then HTML (a crash leaves a recoverable checkpoint). Brief
each by pointer:

> You are reconciling MODULE `<id>` of `<course>/<chapter>` to the **new BCS direction**. Read **both** skills: your
> per-course craft skill (**`redis-course-writer`** for redis / **`echo-mq-writer`** for echomq) AND the
> **`bcs-writer`** overlay; then **`<the chapter>.prompt.md`** — its Shared context + the `## BCS CALIBRATION` block +
> your `## MODULE <id>` section. Apply the five deltas to every figure/surface/door/id-vector; keep your course's
> identity (redis: re-skin to contract-sheet; echomq: dark-editorial, no re-skin, `[RECONCILE]` in md only).
> Preserve every interactive/SVG/pager/crumb/footer + the stamp. Ship only at your section's Gate STATUS: PASS, plus
> the BCS scrubs (0 EchoCache · 0 Exchange · 0 `bcs/content/bcs` · every surface re-found on disk). NEVER run git;
> edit ONLY your module's files.

A **chapter landing** is **orchestrator-only** — you reconcile it yourself (same deltas + the course's landing rules).

## Step 3 — Adversarially verify (do NOT trust "all PASS")

For each page, run the **per-course gate** (the redis or echomq `FLAGS`, **with `--routes-from
/echo-persistence=html/echo-persistence` added** so a persistence door resolves), then the **BCS calibration scrubs**:

```bash
# redis FLAGS (contract-sheet course):
FLAGS="--routes-from /redis-patterns=html/redis-patterns --routes-from /echomq=html/echomq --routes-from /bcs=html/bcs --routes-from /elixir=elixir --routes-from /echo-persistence=html/echo-persistence --chapter-alias r1=caching,r2=coordination,r3=queues,r4=time-delay-priority,r5=streams-events,r6=flow-control,r7=data-modeling,r8=production-operations --require-refs"
# echomq FLAGS: --routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns --routes-from /bcs=html/bcs --routes-from /elixir=elixir --routes-from /echo-persistence=html/echo-persistence --require-refs
D=<chapter dir>
for p in $(/usr/bin/find $D -name '*.html'); do printf "%s " "$p"; go/jonnify-cms/bin/cms check ${=FLAGS} "$p" 2>&1 | grep -oE 'STATUS: (PASS|FAIL)'; done
/usr/bin/grep -rniE 'EchoCache|echo/apps/echo_cache'    $D/ && echo "DELTA2 FAIL" || echo "EchoStore OK"
/usr/bin/grep -rniE 'Exchange\.[A-Z]|echo/apps/exchange' $D/ && echo "DELTA3 FAIL" || echo "codemojex OK"
/usr/bin/grep -rn  'bcs/content/bcs'                     $D/ && echo "DELTA1 FAIL" || echo "bcs.N.md OK"
/usr/bin/grep -rniE 'dragonfly'                          $D/ && echo "ENGINE FAIL (Valkey 9 only — §1a.A)" || echo "Valkey OK"
/usr/bin/grep -rnE  'echomq:2\.[0-9]\.[0-9]|EchoMQ [0-9]\.[0-9]|v1 line' $D/ && echo "VERSION FAIL (wire is echomq:3.0.0, no label — §1a.B)" || echo "as-shipped OK"
/usr/bin/grep -rnoE '(EchoStore|EchoMQ|EchoWire|Codemojex)\.[A-Za-z.]+' $D/ | sort -u   # re-find each on disk in echo/apps/
/usr/bin/grep -rn '234878118\|1704067200000' $D/        # delta 5: if id vectors cited, verbatim only
```

(Use `/usr/bin/grep` and `/usr/bin/find` — the shell aliases mis-scrub patterns with `=`/quotes and silently
return 0.) **Re-find every quoted figure** verbatim in its real `echo/apps/…` source or its `bcs.N.md` chapter —
anything not found is fabricated; fix it. Also run the per-course gate-invisible checks (redis: font-leak +
no-BullMQ + clamp + voice; echomq: no-version + frozen-tree + no-`file:line` + zero `[RECONCILE]` in HTML). Fix any
defect yourself (do-no-harm), re-gate to PASS.

## Step 4 — Relink the manifests (orchestrator-only)

Per course, relink the home map + the chapter landing (flip `soon`→`built`, resolve hrefs), keep the full links-PASS
philosophy (unbuilt entries stay non-anchor `soon` cards), and re-gate both. A persistence door on a manifest is a
real link only if `/echo-persistence` is mounted; otherwise `<strong>`-name it.

## Step 5 — Sync the living views

- the route-mirror **md** (Step 2/3);
- **redis**: `redis-patterns.toc.md` + `.roadmap.md` (retitle + retarget the chapter's grounding to EchoStore/codemojex
  + the floor), `redis-patterns.echomq-doors.md` (the R↔E door; add the `→ /echo-persistence` edge at the
  durability/archive frontier), the chapter `llms.txt`;
- **echomq**: `docs/echo_mq/course/echo_mq.course.md` (content-map) + `echo_mq.course.progress.md` (the `[RECONCILE]`
  ledger) + the skill's `references/course-map.md` resume point + the chapter `llms.txt`;
- **both**: re-pin the `<chapter>.prompt.md` floor if a surface moved. Do not write redundant status prose into nav
  pages — the pills show status.

## Step 6 — Report

Per page: route, course, what changed (re-skin? the five deltas applied — figure-source re-home / EchoStore /
codemojex / persistence-floor door / id-vector fix?), and the gate grade. Note any defect fixed (an invented surface,
a retired `content/bcsN.*` citation, a stale EchoCache/Exchange caught), the manifests relinked, the views synced, and
whether each expert resolved or fell back to `general-purpose`. **Do not commit** — the Operator commits batches
out-of-band; never `git add`/`commit`/`restore`, and the spawned agents must not either.
