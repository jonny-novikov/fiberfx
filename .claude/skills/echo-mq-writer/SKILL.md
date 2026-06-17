---
name: echo-mq-writer
description: "Use this skill to author or continue the course 'EchoMQ, In Depth' on the jonnify dark-editorial design system (served at /echomq). Triggers: any request to create, continue, extend, relink, or validate a course home, chapter landing, module hub, deep-dive, or workshop for this course; to grade a page with the jonnify-cms gates; or to wire a new module into a chapter. EchoMQ is taught as ONE shipped Valkey-native job system you own, canonical in Elixir, organized as THREE PILLARS above one owned wire — the Queue (distribute work), the Bus (broadcast signals + a retained replayable event log), and the Cache (serve reads) — plus an Overview, a Protocol foundation (the owned emq:{q}: keyspace, the Lua layer, immutability + branded ids), and a Proof chapter (conformance, telemetry, benchmark). The single canon is docs/echo_mq/ (emq.design.md + emq.roadmap.md + emq3.specs.md); the canonical code is echo/apps/echo_mq + echo/apps/echo_wire + echo/apps/echo_cache (NEVER the frozen, unrelated echo/apps/echomq). Four authoring disciplines define the course: (1) as-shipped voice, NO version numbers in main content; (2) extract-and-annotate code — lift the real Elixir fn onto the page with added teaching comments, show Lua in two beats (the named handle then a separate commented script body), and NEVER print a file:line citation; (3) the [RECONCILE] shadow — the markdown source-of-record flags every claim ahead of the as-built code (chiefly the Bus/streams depth grounded in canon), never leaking into the HTML; (4) no-invent — ground in real code where it exists and the design canon where it doesn't, never past either. Each chapter is authored from a persistent <chapter>.prompt.md fan-out brief. 'Polyglot' is the thesis (the protocol lives below the language line) stated in one line, not a per-runtime syllabus. It is the course on the far side of every → EchoMQ door in /redis-patterns. The deliverable is always a self-contained static HTML page graded A+ across the ten gates, authored into the existing dark-editorial design system and program canon — never a rebuild of either. Do NOT use for the /redis-patterns course (redis-course-writer / redis-expert), the /elixir course (elixir-course-writer / elixir-technical-writer), the /bcs course (bcs-course-writer), the /course/agile-agent-workflow course (agile-course-writer), the echo_mq library BUILD (the echo-mq-architect / echo-mq-implementor / echo-mq-evaluator program skills), other jonnify sections, or generic documents."
---

# Authoring the jonnify "EchoMQ, In Depth" course

This skill authors the course served at **`/echomq`**: the **internals of the Valkey-native job system you own**,
canonical in **Elixir**, and what they mean for the **BCS family of systems**. EchoMQ is taught as **one shipped
system** organized as **three pillars** above one owned wire — **the Queue**, **the Bus**, **the Cache** — with an
**Overview**, a **Protocol** foundation, and a **Proof** chapter. Where [`/redis-patterns`](../../../docs/redis-patterns/redis-patterns.toc.md)
teaches each Redis pattern *applied* and doors here, this course teaches the **whole system in depth**. It is the course
on the far side of every `→ EchoMQ` door in `/redis-patterns`.

**The digest is [`references/course-map.md`](references/course-map.md)** — the identity, the six-section three-pillar
spine, the routes, the as-built grounding map, the four authoring disciplines, and the resume point. **Read it first;
this SKILL documents the craft.** Two sources of truth govern and win where this skill disagrees:

1. **The program canon** under `docs/echo_mq/` — the structure, the grounding, the design. The canonical **code** is
   `echo/apps/echo_mq` + `echo/apps/echo_wire` + `echo/apps/echo_cache`.
2. **The Go `jonnify-cms` binary** — the gates and the resolvable routes. Run the tool; it wins.

This course is a SIBLING craft to `/redis-patterns`, `/elixir`, `/bcs`, and `/course/agile-agent-workflow`. It renders
in the **jonnify dark-editorial design system** (dark ink, cream text, gold/blue house accents + a scoped EchoMQ teal
token) — **never** the redis/BCS contract-sheet identity. The shared craft lives in
`.claude/skills/elixir-technical-writer/references/` (`design-tokens.md`, `visualization-master.md`,
`technical-writer.md`, `page-anatomy.md`, `references-section.md`) and applies verbatim — read those for the tokens and
the interactive/visualization rules. THIS skill documents only what is *different* for echomq: the grounding boundary,
the **four authoring disciplines**, the **persistent-prompt** mechanism, the page surfaces, and the gate command.

## 0. Standing rules

1. **Reuse, do not reinvent.** The design system, routing, Snowflake convention, validator, and program canon all
   exist and are proven. Author content *into* them — never rebuild a system or introduce a library.
2. **Validate without images.** Headless and text-only: `cms check` + reading the markup + an optional `curl` crawl.
   Never screenshot.
3. **EchoMQ is ONE system, canonical in Elixir — as shipped, no versions.** Teach EchoMQ through the canonical Elixir
   implementation (`echo/apps/echo_mq`). Present every capability **as shipped, present tense** — **no "2.0 / 3.0"**
   label in prose, no "tracked as it is built", no live build-status. A real wire constant inside a code extract is
   fine **as code**; never as the course's framing. **"Polyglot" is the thesis** (the protocol lives below the
   language line, so any runtime that speaks the keys + Lua is a peer) — state it in **one line** (the overview); the
   course teaches Elixir.
4. **Backed by Valkey — the substrate of record.** Conformance/durability claims are phrased against **Valkey (current
   stable line)** — never a pinned version, never a nonexistent benchmark/suite result. Dragonfly is the multithreading
   **performance target** (its thread-per-shard placement is what the declared-keys + per-queue hashtag discipline
   unlocks) — never transfer one engine's capability to the other.

## 1. Where to work

| Path | Role |
|---|---|
| `html/echomq/` | The served course — **wired live** (`main.go` → `serveDirTree`, `ECHOMQ_DIR`); a new `.html` is live on save. Sections: `overview` · `protocol` · `queue` · `bus` · `cache` · `proof` (the old `core/substrate/groups/batches/lifecycle/production` dirs are transitional — see course-map §2). |
| `docs/echo_mq/emq.roadmap.md` | the program map + the **3.x stream-tier canon** (§"EchoMQ 3.x — the stream tier") — the **Bus pillar's grounding** where code is not yet on disk. |
| `docs/echo_mq/emq.design.md` · `emq3.specs.md` | the binding design (master invariant + laws) + the stream-tier specification (S1 writer · S2 readers · S3 memory). The canon a not-yet-coded surface is taught from. |
| `docs/echo_mq/emq.progress.md` · `echo_mq.md` · `emq.references.md` | the as-built dashboard, the program front door, the references. |
| `echo/apps/echo_mq` · `echo/apps/echo_wire` · `echo/apps/echo_cache` | **THE canonical code (the convergence target — the proof).** Verify any surface here before citing it (arity, field, script). |
| `echo/apps/echomq` | **A frozen, UNRELATED tree — NOT part of this course.** Never cite it (course-map §3a). |
| `docs/echo_mq/course/echo_mq.course.md` | **the content-map / TOC** — the six-section spine, routes, status. |
| `docs/echo_mq/course/markdown/<route>.md` | the **route-mirror md** (md-first source-of-record) — **this is where the `[RECONCILE]` shadow lives**. |
| `docs/echo_mq/course/<chapter>.prompt.md` | the **persistent fan-out brief** for each chapter (§10). |
| `docs/echo_mq/course/echo_mq.course.progress.md` | the dashboard + the **`[RECONCILE]` ledger index**. |
| `apps/jonnify-cms/bin/cms` | the **validator** (Go). Build: `cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .`. |
| `.claude/skills/elixir-technical-writer/references/` | the SHARED craft (dark-editorial tokens, visualization, voice, page anatomy). |
| `references/course-map.md` (this skill) | the identity + spine + routes + grounding map + the four disciplines + resume point. |

## 2. The product and the grounding — one canonical system

A course of interconnected **static HTML** pages: no framework, no runtime, no CDN, no browser storage. The grounding
is **EchoMQ**, whose canonical code is `echo/apps/echo_mq` (the Valkey-native bus), with `echo/apps/echo_wire` (the
`EchoWire` wire facade — `EchoMQ.{Connector,Script,RESP}`) and `echo/apps/echo_cache` (`EchoCache.*`, the near-cache)
beside it.

> **The one-way grounding guard.** A frozen, unrelated tree `echo/apps/echomq` (no underscore — `EchoMQ.Keys`,
> `LockManager`, `Scripts`, `Worker`, `moveToActive`) shares the `EchoMQ.*` namespace but is **NOT part of this
> course**. Ground every page in `echo/apps/echo_mq` / `echo_wire` / `echo_cache`; the scrub
> `grep -E 'echo/apps/echomq\b|EchoMQ\.Keys\b|EchoMQ\.LockManager|EchoMQ\.Scripts|moveToActive|EchoMQ\.Worker'` is
> **0 on every page**.

The course is **one system, three pillars** (course-map §1–2). The Overview introduces the system + the pillars; the
Protocol teaches the shared substrate (keyspace, Lua, immutability); the Queue / Bus / Cache teach the three product
surfaces; the Proof teaches conformance + telemetry + the benchmark.

## 3. The structure — six sections, three levels, four page surfaces

Six sections (`overview · protocol · queue · bus · cache · proof`), three levels — **Section** landing
(`<section>/index.html`, route `/echomq/queue`) → **Module** hub (`<section>/<module>/index.html`, ≥3 dives) → **Dive**
(`<section>/<module>/<sub>.html`). Each section closes with a **workshop**. The Overview is the orientation chapter (the
home `/echomq` + the overview landing `/echomq/overview` + dives). **Flows live in the Queue pillar.**

Four **page surfaces**, all **dark-editorial**. Copy the design system **from a built echomq page of the same surface**;
**bootstrap** the first page from the nearest dark-editorial sibling (a built `html/echomq/` page, or `elixir/index.html`
— NOT a contract-sheet redis/bcs page), lifting the shared `<head>`…`</style>` + header + footer + scripts and rewriting
the route-tag, nav, and footer. Add the scoped EchoMQ accent token to `:root`; every other token is shared.

- **The course home** (`/echomq` → `index.html`) — a hero, a "how to read this" (the three pillars + the
  redis-patterns door), and **the map** (the six-section directory: a `.chap` per section over a `.mods` grid). The
  home carries the whole course; no separate contents page. The hero motif is the **three pillars over one wire** (not
  a runtime grid).
- **A chapter landing** (`<section>/index.html`) — the teaching arc: **overview → why & when → what (the modules) →
  how it works → the `.applied` reverse-door block → the workshop**, closing with an **"Up next"** grid. Names the
  pillar it belongs to. The Overview landing is the orientation variant and carries **no** `.applied` block.
  - **The mandatory `.applied` "Redis Patterns Applied" block** (every pillar/section landing; the reverse of
    redis-patterns' door). Place it at the end of "how it works", styled in the echo accent. It names — and **links
    back to** — the `/redis-patterns` chapters that door into this section, per
    `docs/redis-patterns/redis-patterns.echomq-doors.md`. **Link only a BUILT redis-patterns chapter; `<strong>`-name
    an unbuilt one** (a prose back-link is gate-checked).
- **A module hub** (`<section>/<module>/index.html`) — the module's framing + its ≥3 dive cards.
- **A dive** (`<section>/<module>/<sub>.html`) — a full lesson (§5).

**The home and every chapter landing are route manifests** — they forward-link unbuilt pages (the `soon` pill), so a
`links` FAIL on an unbuilt route is expected *there* by design; every lesson/hub page must keep all internal links
resolving. Shared card classes: `.chap · .chap-head · .cid · .mods · .mod · .num · .pill · .t · .o · .chap-link · .c-one`.

## 4. The grounding boundary — depth, real-code-or-canon, as shipped

This course teaches the **system in depth**. Two grounding sources, one voice:

- **Real code** (`echo/apps/echo_mq` + `echo_wire` + `echo_cache`) — for the Protocol, the Queue, the Cache, and the
  Bus's **pub/sub events**. The real Lua script, the real key, the real field, the real module fn with its **verified
  arity** (verified by reading the file; **never printed as a `file:line`**). Present tense.
- **Design canon** (`emq.roadmap.md` §stream tier + `emq3.specs.md` + `emq.design.md`) — for the Bus's **streams /
  event log** (the verbs, `EchoMQ.Stream`, retention, the archive under a shadow, time-travel), which is **specified
  but not yet on disk** (upstream work). Teach it **as shipped** in the HTML, and mark **`[RECONCILE]`** in the md
  shadow at each canon-grounded claim (§4a).

Make the correspondence to the applied pattern explicit with the `.bridge` block (§5) and close with a `.take`. Verify
any surface you cite by reading it in `echo/apps/echo_mq` (real) or the canon (specified) before using it.

### 4a. The `[RECONCILE]` shadow — the honesty ledger (replaces the old three-state living-status)
The course is written **as shipped** in one present-tense voice. The honesty about what is **real code vs specified
canon** lives **only in the markdown source-of-record** (`docs/echo_mq/course/markdown/<route>.md`) as an inline
**`[RECONCILE: what is ahead of as-built, and where the canon says it]`** marker. Rules:
- **Real-code claims carry no marker.** Protocol/Queue/Cache/Events ground in `echo/apps/echo_mq` — no `[RECONCILE]`.
- **Canon-only claims carry `[RECONCILE]`** in the md, citing the canon (`emq.roadmap.md` §… / `emq3.specs.md` emq3.N)
  — chiefly the whole Bus/streams depth. The HTML reads as shipped.
- **The HTML NEVER contains a `[RECONCILE]` marker** (`grep '\[RECONCILE\]' html/echomq/` → 0).
- The markers are the **iteration-2 worklist**, indexed in `echo_mq.course.progress.md`; swept when the upstream stream
  tier lands. This is the AAW "ship the iteration" model: a complete, confident course now; reconcile the markers later.

### 4b. No invention — sharper than redis (a depth course must be exact)
Cite only **real, verified** surfaces (real code) or **specified** surfaces (the design canon). Never invent a Lua
script, key, field, module fn, or arity; never present a canon-only surface without a `[RECONCILE]` in the md. **Read
the surface (in code or canon) before citing it.** The load-bearing anchors are in course-map §3b. The named consumer
for "who drains the bus" is `Exchange.{Gateway, OrderBook, Decider}`. Report Valkey/Dragonfly facts honestly (§0.4);
never cite a benchmark result that does not exist.

### 4c. The redis-patterns door map — the bidirectional source of truth
`/redis-patterns` and `/echomq` link through **one canonical table**:
`docs/redis-patterns/redis-patterns.echomq-doors.md` (the `R ↔ E` edges). It governs both directions; when a page and
the map disagree, **the map wins**. As the pillars land, doors re-point to the **named pillar routes** (R1 caching →
`/echomq/cache`). The reverse back-link lives here as the hero `← redis-patterns R[N]` marker + the `.applied` block;
a reverse-door whose R-chapter is **not yet built** is **`<strong>`-named, never hard-linked**.

## 5. Page anatomy, the interactive contract & the code discipline

Identical to the shared anatomy (`elixir-technical-writer/references/page-anatomy.md`), dark-editorial, a full HTML
file: skip link → `<header class="site">` with a `.route-tag` = this page's exact route → a `.hero` (crumbs, eyebrow,
`<h1>` with the accent word, lede, kicker, a `.toc-mini` including `#refs`) → teaching `<section>`s (`.prose` + a `.fig`
interactive + a `pre.code` extract + a `.geo-readout` + a closing `.take`; pattern↔implementation pairings use
`.bridge`) → a **References** section (`<section id="refs">`, mandatory, gate #10) → a `.pager` → the footer `.stamp`.
Each page carries ≥1 interactive that **performs the real operation and shows its actual result** over a fixed dataset
(see `visualization-master.md`).

**The bridge** (`.cell.idea` → `.arrow` → `.cell.elix`): the redis-patterns pattern (`.cell.idea`) → the real
`echo/apps/echo_mq` implementation (`.cell.elix`). Close with a `.take`.

### 5a. The code discipline — extract-and-annotate, two beats for Lua, no `file:line`
- **Extract, don't cite.** Lift the atomic **Elixir** fn onto the page as a `pre.code` block with **added teaching
  comments** that explain the idea behind the code (the real source, commented for the reader). The page IS the
  extraction — there is no separate examples-file requirement.
- **Lua in two beats.** First name the handle (e.g. `EchoMQ.Jobs @enqueue` — the named script the Elixir verb runs),
  then a **separate** `pre.code` Lua block with the **real script body** (`if string.sub(ARGV[1],1,3) == kind …`),
  **deeply commented** — the branded-id gate, the `KEYS`/`ARGV` contract, each atomic transition, the macro details.
- **Never print a `file:line` citation** on a page. Grounding-by-location is the author's private verification only.
- **Verbatim source in extracts** — no HTML-highlight `<span>`s inside the code text, decode entities
  (`&gt;`→`>`, `&amp;`→`&`) so the block is the real code a reader can run.

### 5b. References + the md source-of-record (two binding rules)
1. **References is a two-column block.** `<section id="refs">` → `<div class="refs">` with **two child `<div>`s**
   (`<h3>Sources</h3>` + `<h3>Related in this course</h3>`), `.refs{display:grid;grid-template-columns:1fr 1fr;gap:1.4rem 2.4rem}`
   (one column under ~680px). **Sources** = REAL vetted links (§7); **Related in this course** = internal routes that
   resolve on disk.
2. **Every page is authored md-first** at `docs/echo_mq/course/markdown/<route>.md` (the served route minus `/echomq/`,
   `.md` appended) — the prose, the worked example on the real grounding, the pattern↔implementation pairing, a recap +
   a `## References`. **This md carries the `[RECONCILE]` shadow (§4a).** Author the md, then build the HTML to match.

## 6. The ten gates

`containers · svg · no-future · voice · storage · motion · degrade · links · pager · refs` (refs opt-in via
`--require-refs`). Build the validator, then on every page:

```bash
apps/jonnify-cms/bin/cms check \
  --routes-from /echomq=html/echomq \
  --routes-from /redis-patterns=html/redis-patterns \
  --routes-from /elixir=elixir --routes-from /bcs=html/bcs \
  --require-refs html/echomq/<path>.html
```

(`--routes-from` is repeatable — the cross-course mounts let `/redis-patterns` + `/elixir` + `/bcs` links resolve
in-gate.) Ship only at **STATUS: PASS**. Checks the gates cannot see, verified by reading: **clamp spacing**
(`clamp(2.7rem, 1.9rem + 4.2vw, 5.1rem)` — spaces around `+`/`-`); the **segmented route-tag**; **no-version scrub**
(no "2.0/3.0" as a prose label — `grep -niE '2\.0|3\.0|version [0-9]'` shows only code-constant contexts); **no
`file:line`** in any code block; **every Lua block paired with a named handle**; the **§2 frozen-tree scrub → 0**;
every `(EchoMQ|EchoWire|EchoCache|Exchange)\.[A-Za-z.]+` re-found in **code or canon** (canon-only ⇒ `[RECONCILE]` in
the md mirror); **zero `[RECONCILE]` in the HTML**. The home and chapter landings are manifests (forward-links to
unbuilt routes use the `soon` pill).

## 7. References — two-column, REAL vetted links

Cite only these (or a stable deep link under them — never invent a URL):
- Redis docs `https://redis.io/docs/`, a command `https://redis.io/commands/<command>`, the source
  `https://github.com/redis/redis`, `https://antirez.com/`;
- **Valkey** — `https://valkey.io/docs/` and `https://valkey.io/commands/<command>/` — the **substrate of record**;
- **DragonflyDB** — `https://www.dragonflydb.io/docs/...` — the performance-target facts;
- BullMQ `https://docs.bullmq.io/` — the **lineage reference / benchmark rival only** (never the v2 wire's canon);
- the `llms.txt` convention `https://llmstxt.org/`.

Wrap each `<li><a href="https://…">Author &mdash; <em>Title</em></a> &mdash; gloss.</li>`. **`Related in this course`**
entries are internal routes (`/echomq/…`, `/redis-patterns/…`, `/elixir/…`) that resolve on disk.

## 8. The two mandatory layout rules (drift source — enforce on every page)

1. **Clickable segmented route-tag.** The header `.route-tag` renders each path part as its own element — intermediate
   parts are `<a href>`, the current part is `<span class="rcur">`, separated by `<span class="rsep">/</span>`;
   `/echomq` is one segment.
2. **Canonical 3-column footer.** `<footer class="site-foot">` → `.foot-cols` + `.foot-bottom` carrying the `.stamp` +
   decoder script (verbatim; a valid `TSK…` Snowflake id). Satisfy both by **copying the `<head>`…`</style>`,
   `<header>`, `<footer>`, and trailing `<script>` blocks verbatim from a built model page**, then changing only
   `<title>`/`<meta>`, the route-tag, and `<main>`.

## 9. Branded Snowflake build stamp

Every page carries the footer `.stamp` + decoder (copied verbatim). The id is a 14-char `EMQ…` form: 3-letter
namespace + base62(snowflake) padded to 11; epoch `1704067200000`; layout `ts(41)<<22 | node(10)<<12 | seq(12)`.
Reusing an existing valid id is fine.

## 10. The authoring workflow — persistent-prompt, canon-first, per module

The orchestrator drives a chapter via a **persistent `<chapter>.prompt.md`** (course-map §5), then fans out one
subagent per module. Per page:

1. **Read the canon + the as-built code.** From the content-map + `<chapter>.prompt.md`: the section, its modules, the
   as-built **floor** (every surface, verified on disk — MATCH for real code, CANON for specified). Read the named code
   in `echo/apps/echo_mq` (+ `echo_wire`/`echo_cache`) and verify the arity/field/`numkeys` before citing. **Never
   author ahead of code-or-canon.**
2. **Author md-first, then the HTML.** Write `docs/echo_mq/course/markdown/<route>.md` (with `[RECONCILE]` markers at
   canon-only claims, §4a). Then build the hub + each dive to match: copy the dark-editorial design verbatim from a
   built model page; **extract-and-annotate** the code (two-beat Lua, no `file:line`, §5a); add the `.bridge` + ≥1 real
   interactive; as-shipped voice, no versions.
3. **Relink the chapter landing** (orchestrator-only when fanning out) — flip the module's card pill `soon`→`built`,
   resolve its href.
4. **Gate every page** to STATUS: PASS; adversarially read the gate-invisible bits (clamp, route-tag, crumbs/pager
   parent, the no-version + frozen-tree + no-`file:line` + Lua-two-beat scrubs of §6, and **zero `[RECONCILE]` leak
   into HTML**).
5. **Sync the views** — the route-mirror md (done in 2); the content-map digest if a hub's dive list changed; the
   `[RECONCILE]` ledger in `echo_mq.course.progress.md`.

When fanning out, give each subagent: this skill, the chapter's `<chapter>.prompt.md` (its Shared context + its
`## MODULE` section), a built model page, the gate command, the four disciplines, and an explicit **no-git** constraint.
Then adversarially verify their output yourself.

## 11. Program canon & course map

Structure is settled **canon-first** before any page: `emq.roadmap.md` + `emq.design.md` + `emq3.specs.md` are the
canon; the as-built `echo/apps/echo_mq` is the proof. The course is **one system, three pillars**, written **as
shipped**, with the real-vs-specified honesty in the **`[RECONCILE]` md shadow**. See `references/course-map.md` for
the spine, routes, grounding map, the four disciplines, and the resume point. Do not write redundant status prose
("all built", "complete") into nav pages — the pills show status; describe structure and the arc. **Never run git** in
an authoring agent — leave changes in the working tree; the operator commits batches out-of-band.
