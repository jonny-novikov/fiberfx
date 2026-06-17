---
name: fsharp-course-writer
description: "Use this skill to author or continue the course 'F# In Depth' served at /fsharp — the ML-family language on .NET, taught in depth across six chapters (C0 History, C1 F# Language, C2 F# for C# developers, C3 F# for Elixir Developers, C4 Algorithms & Data Structures, C5 Pragmatic Programming — DevOps Tools). Triggers: any request to create, continue, extend, relink, or validate the course home, a chapter landing, module hub, or deep-dive for this course; to grade a page with the jonnify-cms gates; or to wire a new module into a chapter. The course renders in the dark-editorial identity — the Elixir course's tokens (dark navy ink, cream text, gold house accent) with an F# violet language accent (--fsharp:#b48ee0) — modelled on html/fsharp/index.html; never the redis/BCS contract-sheet identity. Every claim is grounded, never invented: C0 in documented history, C1/C2 in valid idiomatic F# (and real C#), C3 bridging from real Elixir, C4 at parity with the Elixir algorithms chapter (/elixir/algorithms), and C5 in the REAL as-built ibbs codebase (/Users/jonny/dev/ibbs — DevOps.Tools / DevOps.Sfera / DevOps.Server + the Fable web/client-fs), quoted verbatim. The deliverable is always a self-contained static HTML page graded A+ across the ten jonnify-cms gates, authored into the existing design system and spec system — never a rebuild of either. Do NOT use for the /elixir course (elixir-course-writer / elixir-technical-writer), the /redis-patterns course (redis-course-writer), the /bcs course (bcs-course-writer), the /echomq course (echo-mq-writer), the /course/agile-agent-workflow course (agile-course-writer), other jonnify sections, or generic documents."
---

# Authoring the jonnify "F# In Depth" course

This skill authors the course served at **`/fsharp`** (course letter **C**): F# — the ML-family,
functional-first language on .NET — taught in depth across six chapters. The course teaches the
language seriously and lands its pragmatic chapter on a **real F# DevOps tool**. Two sources of
truth govern, and where this skill disagrees with them, they win:

1. **The spec system** under `docs/fsharp/` is the source of truth for *structure and grounding* —
   the [`fsharp.toc.md`](../../../docs/fsharp/fsharp.toc.md) (the C0–C5 chapter→module→dive tree),
   the [`fsharp.roadmap.md`](../../../docs/fsharp/fsharp.roadmap.md) (the authoring order + the
   grounding map + the vetted Sources registry), the contract
   [`specs/fsharp.md`](../../../docs/fsharp/specs/fsharp.md), and (added at authoring time) the
   per-chapter specs. **Author a page only from its spec; never invent structure.**
2. **The Go `jonnify-cms` binary** is the source of truth for the gates and the resolvable routes.
   Where this skill and the tool disagree, run the tool — it wins.

## 0. Two standing rules

1. **Reuse, do not reinvent.** The design system, the routing (`serveDirTree`), the Snowflake stamp,
   the validator, and the spec system all exist and are proven. Author content *into* them — never
   rebuild a system or introduce a library.
2. **Validate without images.** Validation is headless and text-only: `cms check` + reading the
   markup + an optional `curl`/`python3` route crawl. Never screenshot.

## 1. Identity — dark-editorial with the F# violet accent

The course renders in the **dark-editorial identity**, the same one `/elixir` and
`/course/agile-agent-workflow` use: the `:root` tokens dark navy `--ink`, cream text, the gold house
accent, the four font stacks (Cormorant Garamond / PT Serif / Manrope / JetBrains Mono loaded from
Google Fonts) — **with one language accent swapped in**: `--fsharp:#b48ee0; --fsharp-bright:#d2b8f5`.
The `.ex` h1 highlight, the active arc node, the `soon` pill, the `.op` code colour, and `.mod.lab`
use the F# accent; **gold stays the house colour** (route-tag, buttons, CTAs). This is **NOT** the
redis/BCS contract-sheet identity — no `--b-*` tokens, no `.sech`/`.idrule`/`.door`/`.frozen` devices,
no "nothing fetched" rule. **The model page is `html/fsharp/index.html`.** Copy its
`<head>`…`</style>`, `<header>`, `<footer>`, and trailing `<script>` blocks verbatim; change only
`<title>`/`<meta>`, the route-tag, the crumbs, and `<main>`.

The shared craft in `.claude/skills/elixir-technical-writer/references/` applies in full — the prose
discipline (`technical-writer.md`), the interactive/visualization rules (`visualization-master.md`),
the page-anatomy shape (`page-anatomy.md`), the references block (`references-section.md`), **and**
`design-tokens.md` (which, unlike the redis course, is NOT superseded — F# keeps the dark-editorial
tokens). THIS skill documents only what is *different* for F#: its spec system, its grounding
boundary, and its course map.

## 2. The product and the grounding

A course of interconnected **static HTML** pages: no framework, no runtime, no browser storage.
The grounding discipline is **no invention** — every claim stands on something real (the grounding
map in `fsharp.roadmap.md` is authoritative):

- **C0 History** — documented history of the ML lineage and .NET. Cite authoritative sources; state
  only what the record supports; no invented dates, papers, or attributions.
- **C1 Language / C2 for C# devs** — every F# (and C#) code sample is **valid, idiomatic, and
  runnable**. Never invent F# syntax, an operator, or a library function. `|>` and `>>`, `Option`,
  `Result`, active patterns, discriminated unions, records, and computation expressions are real F#
  features — use them as the language defines them.
- **C3 for Elixir devs** — valid F# **beside real Elixir**, the Elixir-community parallel to C2: the
  BEAM functional vocabulary mapped onto F# on the CLR. Much carries over (immutability, pattern
  matching, the `|>` pipe); static types and exhaustiveness are the shift. The Elixir is real (no
  strawman); cross-link the matching `/elixir` module. F#'s actor is the **`MailboxProcessor`**.
- **C4 Algorithms** — valid F# at **parity with the Elixir course's E4** (`/elixir/algorithms`):
  same twelve-rung arc (lists → trees → sorting → maps → HAMT → CHAMP → branded ids → persistence →
  branded CHAMP behind an actor → recipes → dynamic programming → lab). Cross-link the matching E4
  module and **add notes on the F# implementation and its efficiency** (structural sharing, boxing,
  the cost model where the CLR differs from the BEAM). F#'s actor is the **`MailboxProcessor`**.
- **C5 DevOps Tools** — the **real as-built `ibbs` codebase** at **`/Users/jonny/dev/ibbs`** (the
  `DevOps.sln` solution: `src/DevOps.Tools` → `analysis.dll`, `src/DevOps.Sfera` → `sfera.dll`,
  `src/DevOps.Server` → `devops-server`, the Fable `web/client-fs`, `tests/DevOps.Tools.Tests`).
  This is the redis-style "cite ONE tight, real artifact" rule, but the artifact is `ibbs` F# code.
  **Verify every quoted module / function / endpoint / flag on disk before citing it; invent
  nothing.** Honour the README's representative-vs-live notes (e.g. `/api/database` is representative).

## 3. The structure — three levels and four page surfaces

Three levels, `C<chapter>.<module>.<dive>` (course letter **C**), folder-routed:

- **Chapter** `C[N]` (C0…C5) → a landing `<chapter>/index.html` (route `/fsharp/language`). Slugs:
  `history · language · for-csharp · for-elixir · algorithms · devops`.
- **Module** `C[N].[M]` → a hub `<chapter>/<module>/index.html` (route `/fsharp/language/values`).
- **Dive** `C[N].[M].[S]` → a deep-dive `<chapter>/<module>/<sub>.html`. C0/C1/C2 carry **3 dives
  each**; C4/C5 modules are single pages (mirroring Elixir F4/F5).

Four **page surfaces** (copy the design system from `html/fsharp/index.html` or a built F# page of
the same surface):

- **Course home** (`/fsharp` → `index.html`) — built at bootstrap: hero + motif, the 6-node arc
  selector, the F# composition interactive, the full C0–C5 map, the 3-column footer. The home
  carries the whole course; there is no separate contents page.
- **Chapter landing** (`<chapter>/index.html`) — the teaching arc: overview → how to read → the
  module cards (`.mods` grid) → a closing lab/recap where useful.
- **Module hub** (`<chapter>/<module>/index.html`) — the module's framing + its dive cards (or, for
  C3/C4, the full lesson).
- **Dive** (`<chapter>/<module>/<sub>.html`) — a full lesson (see §5).

**The home and every chapter landing are route manifests at a FULL links-PASS** (no fail-by-design):
a built chapter/module is an anchor card `<a class="mod" href="…">` with its real pill, an unbuilt
one a **non-anchor** `<div class="mod">` with the `soon` pill — nothing dangles. Shared card classes:
`.chap · .chap-head · .cid · .mods · .mod · .num · .pill · .t · .o · .chap-link · .c-one`.

## 4. Page anatomy & the interactive contract

The shared dark-editorial anatomy (`elixir-technical-writer/references/page-anatomy.md`), authored as
a full HTML file: skip link → `<header class="site">` with the `.route-tag` (this page's exact route)
→ a `.hero` (crumbs, `.eyebrow`, `<h1>` with the `--fsharp-bright` `.ex` accent, `.lede`, kicker) →
teaching `<section>`s, each holding `.prose` + an interactive figure + code blocks (`pre.code`, with
`.op` in the F# accent) + a closing `.take` (concept pairings use the `.bridge` device) → a
**References** section (mandatory, gate #10) → a `.pager` → the footer with the `.stamp`. Each page
carries ≥1 interactive that **performs the real operation and shows its actual result** over a fixed
dataset (see `visualization-master.md`): SHORT labels in the diagram, the detail in a live readout;
degrades without JS; honours `prefers-reduced-motion`; uses no browser storage; ≥1 `svg` per page.
The home's two interactives (the arc selector and the `|>` pipe builder) are the reference patterns.

## 5. The ten gates

`containers · svg · no-future · voice · storage · motion · degrade · links · pager · refs`. Build the
validator (`cd apps/jonnify-cms && GOWORK=off go build -o bin/cms .`), then run on every page,
mounting `/fsharp` and any cross-course route the page links to:

```bash
apps/jonnify-cms/bin/cms check \
  --routes-from /fsharp=html/fsharp \
  --routes-from /elixir=elixir \
  --require-refs html/fsharp/<path>.html
```

Add `--routes-from /redis-patterns=html/redis-patterns` / `/bcs` / `/echomq` if a page links there.
Ship only at **STATUS: PASS**. Then the gate-**invisible** checks (verify by reading): clamp() values
are spaced (`clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` — unspaced is invalid CSS dropped to a UA default);
the route-tag is the exact segmented form; crumbs/pager point at the **intended** parent; every
Sources `<li>` carries `href="http`; each inline `<script>` parses (`node --check`); and — the
no-invent discipline — **no invented F#/.NET API and no fabricated `ibbs` surface**: for C5, run
`grep -rnoE '(DevOps|Monitor|Sfera|Api|Ui|Dashboard|Database|Releases|App)\.[A-Za-z.]+' <page>` and
cross-check each on disk under `/Users/jonny/dev/ibbs`; for C1–C4, confirm every F# snippet is valid
idiomatic F#.

## 6. The two mandatory layout rules (drift source — enforce on every page)

1. **Clickable segmented route-tag.** Each path part is its own element: intermediate parts are
   `<a href>` to that route level, the current part is `<span class="rcur">`, separated by
   `<span class="rsep">/</span>`; `/fsharp` is one segment. Example for
   `/fsharp/language/pipe-and-compose`:
   `<span class="route-tag"><span class="rsep">/</span><a class="rcur"-less … >` — intermediate
   parts link, last is `.rcur`.
2. **Canonical 3-column footer.** `<footer class="site-foot">` → the 3-column `.foot-nav` + the
   `.foot-bar` carrying the `.stamp` + decoder script (verbatim; a valid `TSK…` Snowflake id). Copy
   `<head>`…`</style>`, `<header>`, `<footer>`, and the trailing `<script>` from `html/fsharp/index.html`,
   then change only `<title>`/`<meta>`, the route-tag/crumbs, and `<main>`.

## 7. Voice

No first person ("I"/"we"/"our"), no exclamation marks, no emoji, none of {just, simply, obviously,
effortless, magical, revolutionary, blazing}, no perceptual or interior-state verb applied to a tool
or an agent (a function does not "see"/"want"/"know"/"decide"). Active voice, short sentences, one
idea per section.

```bash
grep -nE '\b(just|simply|obviously|effortless|magical|revolutionary|blazing)\b' html/fsharp/<path>.html
```

## 8. Branded Snowflake build stamp

Every page carries the footer `.stamp` + decoder (copied verbatim from the model page). The id is a
14-char `TSK…` form: 3-letter namespace + base62(snowflake) padded to 11; epoch `1704067200000`;
layout `ts(41)<<22 | node(10)<<12 | seq(12)`. Reusing the model's valid id is fine (the decoder
decodes whatever is in `#stampId`).

## 9. The authoring workflow (spec-first; per module)

1. **Read the spec AND ground the page.** The chapter spec (when present) names the module, its
   dives, and its grounding; the grounding map in `fsharp.roadmap.md` names what the module stands on.
   For C5, open the real `ibbs` file(s) the map points to under `/Users/jonny/dev/ibbs` and read the
   actual code before writing a word. Never author ahead of the spec.
2. **Author the page(s).** Copy the design system verbatim from `html/fsharp/index.html` (or a built
   F# page of the same surface); write the module hub and each dive; ground the worked example in the
   real artifact (a quoted `ibbs` F# excerpt for C5, a valid F# snippet for C1–C4, a sourced fact for
   C0); add ≥1 interactive, a `.bridge`/`.take` where a pairing closes, and the References block.
   Optionally author the route-mirrored markdown at `docs/fsharp/markdown/<route>.md` first.
3. **Relink the chapter landing** (orchestrator-only when fanning out) — turn the module's non-anchor
   `<div class="mod">` card into `<a class="mod" href="…">` and flip its pill `soon`→`built`; the
   manifests stay at a full links-PASS.
4. **Gate every page** to STATUS: PASS; adversarially read the gate-invisible bits (clamp, route-tag,
   crumbs/pager parent, Sources `href`, scripts parse, **no invented F#/.NET API, no fabricated
   `ibbs` surface** — re-find every C4 figure on disk).
5. **Sync the TOC + progress** — mark the module built so the views agree.

When fanning out to background agents (one per module/dive), give each: this skill, the model page,
the exact route + numbering + the module's spec + its grounding, the gate command, the no-invent
guard, and an explicit **no-git** constraint. Then adversarially verify their output yourself.

## 10. Spec system & course map

The structure is settled **specs-first** before any page: the TOC maps, the roadmap plans and fixes
the grounding, the chapter specs define, and page authoring expands a spec faithfully. See
`references/course-map.md` for the C0–C5 chapter/route/status table and the resume point. Do not
write redundant status prose ("all built", "complete") into nav pages — the cards' pills already show
status; describe structure and the arc instead. **Never run git** in an authoring agent — leave
changes in the working tree; the operator commits batches out-of-band.
