---
description: redis-reconcile — the one-shot engine that reconciles a whole "Redis Patterns Applied" chapter to the TARGET DESIGN in a single run: the BCS contract-sheet identity (redis-red accent), the Exchange Platform exemplar consumer, grounding in the real as-built echo data layer (echo/apps/echo_mq · echo_cache · echo_wire · echo/apps/exchange — never a .out transcript), ZERO BullMQ, Valkey the only engine. Fans out redis-expert reconcilers per module, then adversarially gates + relinks + syncs the living views. Reconcile to fit; never invent.
argument-hint: <chapter> · B<N> · R<N> (whole chapter, e.g. /redis-reconcile B1) · <chapter>/<module> · <chapter>/<module>/<dive> (one page)
allowed-tools: Agent, Read, Write, Edit, Bash, Glob, Grep, Skill, AskUserQuestion
model: opus
---

# /redis-reconcile — reconcile a chapter to the target design (one run)

You are **reconciling already-built pages** of the jonnify "Redis Patterns Applied" course (served at
`/redis-patterns`) to the **TARGET DESIGN** — in one pass per chapter. This is the engine that applies, end to end,
the reconcile proven on **R0** (the reframed home + overview + R0.2 + R0.3): the BCS **contract-sheet** identity,
the **Exchange Platform** exemplar, grounding in the **real as-built echo data layer**, **zero BullMQ**, Valkey the
only engine. It is the sibling of `/redis-write` (which authors *new* pages); use `/redis-reconcile` to bring
**existing** pages to the target design.

The law is the **reframe contract** ([`docs/redis-patterns/specs/reframe-echomq/reframe-echomq.md`](docs/redis-patterns/specs/reframe-echomq/reframe-echomq.md));
the craft is the **`redis-course-writer`** skill + the **`redis-expert`** agent def; the grounding is the
**grounding map** ([`redis-patterns.roadmap.md`](docs/redis-patterns/redis-patterns.roadmap.md)) resolved to the
**real code**; the visual + structural model is a **reframed R0 page** on disk (the home `html/redis-patterns/index.html`,
the R0.2 hub `…/overview/redis-under-portal/index.html`, the hover-select figure `…/patterns-become-protocol/the-four-layers.html`).
**Reconcile to fit; never invent, never author a brand-new lesson.**

## Arguments & scope

```
$ARGUMENTS
```

Map **`B<N>` → `R<N>`** (the operator writes the chapter as `B1`; it is R1). Resolve `R<N>` → its dir slug via the
skill's `course-map.md` (`r1=caching`, `r2=coordination`, `r3=queues`, `r4=time-delay-priority`,
`r5=streams-events`, `r6=flow-control`, `r7=data-modeling`, `r8=production-operations`). Then:

- **A CHAPTER** — `<chapter>` / `B<N>` / `R<N>` (e.g. `B1`, `caching`) → reconcile the chapter landing + **every
  built module** in it (the default, whole-chapter run).
- **A MODULE** — `<chapter>/<module>` → the hub + all its dives.
- **A PAGE** — a full route tail → that one page.
- **Empty** → read `course-map.md`, find the **next un-reconciled** chapter (one still in the dark-editorial
  identity, or still naming Portal/BullMQ, or grounded in the old Portal surfaces), and reconcile that — or ask in
  plain text which scope (do **not** guess a large scope). **R0 is already reconciled** (do not redo it); the
  frontier is **R1 `caching`** (`re2`).

## The target design — the reconcile checklist

A page conforms when **all** of these hold. **(A)** is the reframe-to-target work (the reason this command exists);
**(B)** the three binding craft rules; **(C)** the gate-invisible conventions.

### (A) The reframe-to-target axes — apply per page

1. **Identity → contract-sheet.** If the chapter is still **dark-editorial** (dark navy `--ink:#0a0e1a`,
   Google-fetched Cormorant/PT Serif/Manrope/JetBrains), re-skin it: copy the `<head>…</style>` + header + footer +
   scripts **verbatim from a reframed R0 page** of the same surface, change only `<title>`/`<meta>`, the route-tag,
   and `<main>`. Light-paper `--b-*` tokens + redis-red `--r-red`, mono-forward **system** fonts (nothing fetched),
   `figure.frozen` evidence blocks, the 14-cell `.idrule`, `.sech` headers, the `.stamp` footer. Header is scoped
   **`header.top{…}`**, NEVER bare `.top` (the `.mod` cards reuse `<div class="top">`; a bare rule floats every card
   over the header). (Pages already in the contract-sheet — skip; this is a content reconcile, not a re-skin.)
2. **Exemplar Portal → the Exchange Platform.** The worked consumer is the **Exchange Platform**
   (`echo/apps/exchange` — `Exchange.Gateway`/`OrderBook`/`Decider`; `docs/exchange/`), NOT Portal. The "one facade"
   is **`EchoWire`** (`echo/apps/echo_wire` — the one owned Valkey client over `EchoMQ.Connector`); `%Portal.Error{}`
   / "the closed error set" → the connector's real typed returns (`:disconnected` / `:overloaded` /
   `{:version_fence, got}`) or `Exchange.Gateway`'s six closed errors. A `Portal.enroll`-style example → an
   `Exchange.Gateway.parse_place/1` or `EchoWire`/`EchoMQ.Jobs` call. **Keep every URL slug** (e.g. an
   `…/redis-under-portal` path stays — change human titles + labels, never the href).
3. **BullMQ → ZERO.** No mention of BullMQ anywhere on a page. The v1 history is told without naming it ("EchoMQ
   broke from its v1 line, now frozen at `1.3.0`"). Never the `bull:` keyspace, never `bullmq.io` in Sources,
   **never Dragonfly** (`docs/exchange` names Dragonfly the native primary — the reframe overrides it; **Valkey
   only**). Always "EchoMQ" (never "EchoMQ 2.0" as a recurring label); `echomq:2.0.0` only as a quoted wire string.
4. **Ground in the real as-built code — never a `.out`.** Re-ground every figure to the real surfaces:
   `echo/apps/echo_mq` (EchoMQ — `Jobs`/`Lanes`/`Consumer`/`Keyspace`, the `emq:{q}:<type>` builder, the Lua
   scripts), `echo/apps/echo_cache` (EchoCache — `Ring`/`Table`/`Journal`/`Coherence`), `echo/apps/echo_wire`
   (`EchoWire` + `EchoMQ.Connector`, the `echomq:2.0.0` fence), `echo/apps/exchange` (the consumer). Supplement with
   the committed BCS manuscript figures (`docs/echo/bcs/content/bcs3.*`, `bcs4.*`, `bcsA.md`) + `emq.md`. **`.out`
   rung transcripts are NOT course material** — never quote a `.out` file or foreground a "PASS N/N" gate dump as a
   page figure; teach the *pattern* from the code. Engine is **Valkey 9.1.0** (the live figure `bcsA.md` measured;
   fix any stray `8.1.8`).

### (B) The three binding craft rules (surface-aware)

5. **Source is the content spine** *(HUBS)*. The hub's `.lede` is the author source's opening summary; its `<h2>`
   order follows the source's `##` order (`content/<section>/<pattern>.md.txt`, per the
   [content-map](docs/redis-patterns/redis-patterns.content-map.md)). Framing/interactives/`.bridge`/`.door`/grounding
   layer **after** the source sections. *(DIVES* are aspect-faithful — re-root only on drift. *LANDINGS* have no
   single source.)
6. **References is a two-column block** *(ALL pages)*. `<div class="refs">` → two child `<div>`s (`<h3>Sources</h3>`
   / `<h3>Related in this course</h3>`), `display:grid;grid-template-columns:1fr 1fr;gap:1.4rem 2.4rem`
   (+ `@media(max-width:680px){grid-template-columns:1fr}`). Sources = ≥3 REAL vetted links (redis.io/docs,
   `redis.io/commands/<cmd>`, **valkey.io** topics/commands, github.com/redis, llmstxt.org — **never bullmq.io**).
7. **Route-mirror md** *(ALL pages)*. `docs/redis-patterns/markdown/<route>.md` exists and mirrors the reconciled
   HTML (the source spine + the jonnify grounding + a two-column `## References`).

### (C) The gate-invisible conventions

8. **clamp()** values spaced (`clamp(2.7rem, 1.9rem + 4.2vw, 5.1rem)`). 9. **Segmented clickable route-tag**
   (each path part its own element; `/redis-patterns` one segment; leaf `.rcur`). 10. **Canonical 3-column footer**
   + valid `TSK…` stamp. 11. **Every figure on the hover-select pattern** of `/bcs/ideas/system-substrate` (exemplar
   `…/patterns-become-protocol/the-four-layers.html`): a `.segbar` + an SVG whose `g[data-…]` groups highlight on
   hover AND click (`.focus`/`.on`, dimming others) with a live `.readout`; SHORT diagram labels, full detail in the
   readout; ≥1 `svg` per page. 12. **Voice** — a cache / caller / surface / queue / script / store does not "see" /
   "want" / "know" / "decide". 13. **Pager loop + crumbs** point at intended parents (hub `prev`=landing,
   `next`=first dive; dives chain hub→dive1→dive2→dive3→hub). 14. **No invented surface** — every `EchoMQ.*` /
   `EchoCache.*` / `EchoWire.*` / `Exchange.*` is real on disk in `echo/apps/`; every `/echomq` `/bcs` `/elixir`
   cross-link resolves.

## Step 0 — Ground the batch (read-only)

1. Invoke the **Skill tool with skill `redis-course-writer`**; read its standing rules + `references/course-map.md`.
2. Read the **reframe contract** (`specs/reframe-echomq/reframe-echomq.md` — the figure inventory + the no-BullMQ
   law + the as-built grounding row) and the **grounding map** in `redis-patterns.roadmap.md`.
3. For each target module resolve: its author source `content/<section>/<pattern>.md.txt` (the spine), its dive
   slugs, the **real echo/apps surface** each pattern re-grounds onto, and its served routes.
4. **Audit the current pages** to scope the gap:
   ```bash
   D=html/redis-patterns/<chapter>/<module>
   grep -lE 'ink:#0a0e1a|Cormorant|fonts\.googleapis' $D/*.html      # still dark-editorial? (axis 1 re-skin)
   grep -rniE 'portal|bullmq|bull:|dragonfly' $D/ | grep -viE '<slug-to-keep>'   # axis 2/3 targets
   grep -oE '<h2>[^<]*</h2>' $D/index.html                           # rule 5: hub h2 order vs the source
   for p in $D/*.html; do grep -cq 'grid-template-columns:1fr 1fr' "$p" && echo "$p 2col" || echo "$p 1col"; done
   ls docs/redis-patterns/markdown/<chapter>/<module>*/ 2>/dev/null  # rule 7: which mds exist
   ```
5. Read the **reframed R0 model** of each surface (home / hub / dive) to copy the contract-sheet shape.

## Step 1 — De-risk (once)

Build the validator: `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .` (GOWORK=off mandatory; runs from the
filesystem, no server). Confirm the real surfaces a re-ground will cite exist: `ls echo/apps/echo_mq/lib/echo_mq/`,
`echo/apps/echo_cache/lib/echo_cache/`, `echo/apps/echo_wire/lib/`, `echo/apps/exchange/lib/exchange/`.

## Step 1.5 — Author the persistent chapter prompt (orchestrator-only) — the durable fan-out brief

Before fan-out, WRITE the durable per-chapter brief at **`docs/redis-patterns/specs/<chapter>/<chapter>.prompt.md`**
(e.g. `docs/redis-patterns/specs/caching/caching.prompt.md`). It crystallizes Step 0's grounding into a reusable file
each subagent reads (rather than an ephemeral inline brief). Skeleton:

- **Status blockquote** — "one redis-expert reconciles ONE module from its `## MODULE` section; read the
  `redis-course-writer` skill, this brief's Shared context, then your section, then the reframed R0 model page. This is
  a RECONCILE of existing pages — do NOT rewrite from scratch, do NOT re-skin a contract-sheet page."
- **The chapter in one paragraph** — what it teaches, and the **redis↔echomq door**: the `→ EchoMQ` CTA now points at
  the **named echomq pillar route** (R1 caching → **`/echomq/cache`**, per `redis-patterns.echomq-doors.md`), not the
  bare `/echomq`.
- **Shared context (every module)** — chapter/routes/dirs/md-mirror root; the **as-built floor** (every `echo/apps`
  surface the chapter cites, verified on disk with **verified arity** — MATCH, or note the drift to fix); the four
  reframe axes (A1–A4); the reframed R0 model page; the sources allow-list (never bullmq.io); the gate command; the
  hard constraints (NEVER git; edit ONLY this module's files; landing/home/manifests orchestrator-only).
- **One `## MODULE <id> · <name>` section per module** — a **Directive** (what to reconcile, the surfaces to
  re-verify against as-built, the door/branded-id angle to pull forward) + a **Gate** (STATUS: PASS + the per-module
  scrubs).
- **Acceptance — "<chapter> reconciled" means** · **Inputs** (the contract · the roadmap grounding map · the
  content-map · the model page · the skill · the agent · this command).

This file is itself a synced view (Step 5) — re-pin its floor if a surface moved.

## Step 2 — Fan out one redis-expert per module (point them at the persistent prompt)

Spawn **one `redis-expert` per module** (all in one message for a chapter run). Use `subagent_type: "redis-expert"`;
on "agent type not found" fall back to `general-purpose` (the def is self-contained). Heavy edits → instruct the
agent to reconcile the **route-mirror md first**, then the HTML, so an API-overload crash leaves a recoverable
checkpoint. Point each at its section of the persistent prompt — do **not** restate the brief inline:

> You are reconciling MODULE `<id>` of `<chapter>` for "Redis Patterns Applied". Read the **`redis-course-writer`**
> skill, then **`docs/redis-patterns/specs/<chapter>/<chapter>.prompt.md`** — its Shared context (every module) and your
> `## MODULE <id>` section. Reconcile only that module's pages to your section's Directive (md-first, then HTML). This is
> a RECONCILE — preserve every interactive/SVG/pager/crumb/footer + `TSK…` stamp; do NOT re-skin a contract-sheet page.
> Ship only at your section's Gate STATUS: PASS. NEVER run git; edit ONLY your module's files.

The persistent prompt's **Shared context** carries (authored once, read by all):

- **This is a RECONCILE of existing pages — do NOT rewrite from scratch.** Preserve every interactive, SVG, the
  pager, crumbs, footer + `TSK…` stamp; change only what the checklist requires.
- **The four reframe-to-target axes (A1–A4 above), verbatim** — the re-skin (if dark-editorial), Portal → the
  Exchange Platform / EchoWire, BullMQ → zero, ground in the real `echo/apps` code (never a `.out`), Valkey only,
  keep slugs. Quote the page's real grounding surfaces (read them in `echo/apps/…` before citing).
- read: the contract, the module spec, the author source (the spine), and the reframed R0 model page.
- **HUB** — re-root the lede + `<h2>` order to the source; layer the `.door` (the Valkey tuning + the `emq:{q}:`
  application) + `.bridge` (pattern → its EchoMQ/EchoCache application) + the hover-select figure on top.
- **DIVES** — rules 6 + 7 + the four axes; re-root only on drift.
- **ALL pages** — two-column References (drop any bullmq.io); route-mirror md at `docs/redis-patterns/markdown/<route>.md`;
  fix clamp / route-tag / voice / invented-surface / `8.1.8` defects.
- the **gate command** (Step 3, **with the cross-course mounts**); **ship only at STATUS: PASS**.
- **hard constraints**: NEVER run git; edit ONLY this module's `html/redis-patterns/<chapter>/<module>/` files + its
  `docs/redis-patterns/markdown/<chapter>/<module>/` mds; do **NOT** touch the chapter landing or the home (the
  orchestrator relinks them in Step 4).

A **chapter landing** is **orchestrator-only** — you reconcile it yourself (same four axes; it carries 2-col refs +
states the chapter arc, no single source spine).

## Step 3 — Adversarially verify (do NOT trust "all PASS")

For each reconciled page, gate (zsh: force word-split with `${=FLAGS}`), then run the scrub:

```bash
FLAGS="--routes-from /redis-patterns=html/redis-patterns --routes-from /echomq=html/echomq --routes-from /bcs=html/bcs --routes-from /elixir=elixir --chapter-alias r1=caching,r2=coordination,r3=queues,r4=time-delay-priority,r5=streams-events,r6=flow-control,r7=data-modeling,r8=production-operations --require-refs"
D=html/redis-patterns/<chapter>/<module>
for p in $D/*.html; do printf "%s " "$p"; apps/jonnify-cms/bin/cms check ${=FLAGS} "$p" 2>&1 | grep -oE 'STATUS: (PASS|FAIL)'; done
grep -rniE 'bullmq|bull:|dragonfly' $D/ || echo "no-bullmq OK"            # axis 3: UNCONDITIONALLY empty
grep -rniE 'portal' $D/ | grep -viE '<slug-to-keep>' || echo "no-portal OK" # axis 2: 0 except a kept slug
grep -rnoE '(EchoMQ|EchoCache|EchoWire|Exchange)\.[A-Za-z.]+' $D/ | sort -u  # axis 4: cross-check each on disk in echo/apps/
grep -rnoE 'PASS [0-9]+/[0-9]+|232 ns|8\.1\.8' $D/ || echo "no .out-dump / no stray figure OK"
grep -rnE 'Cormorant|Manrope|PT Serif|JetBrains|fonts\.googleapis' $D/ || echo "font-leak OK"
grep -oE '<h2>[^<]*</h2>' $D/index.html                                    # rule 5: hub h2 order == source ##
for p in $D/*.html; do grep -c 'grid-template-columns:1fr 1fr' "$p"; done  # rule 6: ≥1 each
ls docs/redis-patterns/markdown/<chapter>/<module>/*.md                     # rule 7: one md per page
for p in $D/*.html; do node --check <(sed -n '/<script>/,/<\/script>/p' "$p" | sed '1d;$d') 2>&1 | head -1; done  # scripts parse
grep -rnoE 'clamp\([^)]*\)' $D/ | grep -E '[0-9a-z](\+|-)[0-9]' || echo "clamp OK"
```

**Re-find every quoted figure** (key / verb / number / wire string / module / arity) verbatim in its real
`echo/apps/…` source or the committed manuscript — anything not found is fabricated; fix it. The `redis.call(...)`
inside a frozen Lua script is the Lua API (stays verbatim — not the engine name). Fix any defect yourself
(do-no-harm), re-gate to PASS.

## Step 4 — Relink the manifests (orchestrator-only)

The home map (`index.html`) and the chapter landing (`<chapter>/index.html`) are **route manifests** — you relink
them, never the agents. Update any title/label the reconcile changed (e.g. a retitled module), keep the **full
links-PASS** philosophy (unbuilt R5–R8 stay non-anchor `<div class="mod">` `soon` cards — nothing dangles), and
re-gate both to a full STATUS: PASS.

## Step 5 — Sync the living views

- the route-mirror **md** is created (Step 2/3);
- **`redis-patterns.toc.md`** + **`redis-patterns.roadmap.md`** — retitle the chapter/module entries the reconcile
  changed and retarget the chapter's grounding cell from the old Portal surface to the echo data layer; mark the
  chapter reconciled. The course-wide TOC header thesis already names the Exchange Platform + zero-BullMQ (set at
  R0) — keep it consistent.
- **`redis-patterns.echomq-doors.md`** (the canonical R↔E door map) — retarget this chapter's `→ EchoMQ` door to the
  **named echomq pillar route** (the echomq course is now pillar-routed: `/echomq/protocol · /queue · /bus · /cache ·
  /proof`; R1 caching → **`/echomq/cache`**), and correct any stale "carries no door" note. Confirm the on-page door
  CTA + the `Related in this course` link point at the pillar route, not the bare `/echomq`.
- **the `llms.txt`** for the chapter + any module — mirror the reconciled titles/grounding.
- Do not write redundant status prose into nav pages — the pills already show status.

## Step 6 — Report

Summarise per page: route, what changed (re-skin? Portal→Exchange re-ground? BullMQ→zero? code re-grounding? refs→2col?
md? voice/clamp fixes?), and the gate grade. Note any defect fixed (especially invented-surface / a `.out` citation
caught), the manifests relinked, the TOC/roadmap/llms.txt synced, and the next un-reconciled chapter. Note whether
`redis-expert` resolved or fell back to `general-purpose`. **Do not commit** — the operator commits batches
out-of-band; never `git add`/`commit`/`restore`, and the spawned agents must not either.
