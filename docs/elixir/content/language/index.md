# F3 — The Elixir Language (chapter landing)

- **Route (served):** `/elixir/language`
- **File:** `elixir/language/index.html`
- **Place in the chapter:** the F3 chapter landing — the hub that frames the chapter's nine modules (`F3.01`–`F3.09`) in three movements (Foundations, Data & shape, Concurrency) and routes the reader through three optional front-matter readings (`history`, `timeline`, `under-the-hood`) before the lessons begin. It follows `F2 · Functional Programming` and precedes `F4 · Algorithms & Data Structures`.
- **Accent:** elixir (purple) — `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`; the `<h1>` accent word `Language` is the `<span class="ex">`.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `Chapter F3 · nine modules`

`<h1>`: The Elixir `Language`

Lede (verbatim):

> F2 argued that programs are pure transformations of immutable data, composed into pipelines. This chapter is where that argument becomes a working language: the syntax, the data, and the runtime that make those ideas the path of least resistance.

Kicker (verbatim):

> Elixir is a young language on an old, battle-tested machine. Before the lessons begin, three short readings set the scene: who built it and why, how it has grown release by release, and what actually happens when your source becomes bytecode on the BEAM. Then the nine modules run from the values you type into the shell, through pattern matching and modules, to processes and OTP.

## What the page frames

The landing presents four blocks: an interactive journey path over the nine modules (`#arc`), a three-card "Before the lessons" front-matter row (`#intro`), the nine modules listed as `.deflist` entries grouped into three phases (`#modules`), and a "Where this sits" placement note (`#sits`).

The nine modules, verbatim from `#modules` (each a `.deflist` `<dt>`/`<dd>` with an inline status span):

Foundations
- `F3.01 · Values, types & IEx` — *start here* — "The data you build with; the shell as a tool." — `/elixir/language/values` — built (leaf)
- `F3.02 · Pattern matching & the match operator` — *available* — "= is a match, not assignment." — `/elixir/language/match` — built (hub, 3 dives)
- `F3.03 · Functions, modules & the pipe` — *available* — "Defining and composing in modules." — `/elixir/language/modules` — built (hub, 3 dives)

Data & shape
- `F3.04 · Enumerables & streams` — *available* — "Eager versus lazy traversal." — `/elixir/language/enum-streams` — built (hub, 3 dives)
- `F3.05 · Structs, maps & keyword lists` — *available* — "Shaping data; when to use which." — `/elixir/language/structs` — built (hub, 3 dives)
- `F3.06 · Protocols & behaviours` — *available* — "Polymorphism and contracts." — `/elixir/language/protocols` — built (hub, 3 dives)

Concurrency
- `F3.07 · Processes & the actor model` — *available* — "spawn, send, receive; isolation." — `/elixir/language/processes` — built (hub, 3 dives)
- `F3.08 · OTP: GenServer & supervisors` — *available* — "Stateful servers and fault tolerance." — `/elixir/language/otp` — built (hub, 3 dives)
- `F3.09 · The process playground` — *available · lab* — "Spawn processes, send messages, watch the mailbox live." — `/elixir/language/playground` — built (single-page lab)

Front-matter readings (`#intro`, three linked cards):
- Reading 1 — A short history — "Why José Valim built a new language on a thirty-year-old VM." — `/elixir/language/history`
- Reading 2 — The release timeline — "From the first commit to today, one headline per milestone." — `/elixir/language/timeline`
- Reading 3 — Under the hood — "Source to bytecode: tokens, the AST, macros, and the BEAM." — `/elixir/language/under-the-hood`

`.note` (`#sits`, verbatim): "Begin with **F3.01 — Values, types & IEx**, or read the short history first for context."

## The interactives

### Hero motif (static SVG)
A non-interactive `<svg class="hero-motif">` (`viewBox="0 0 1000 96"`) showing `source.ex` → `AST + macros` → `BEAM bytecode`, joined by the animated `.arc-flow` dashed line. No controls; decorative.

### Figure — "The journey · select a module" (`#arc`)
- **Markup:** `<figure class="fig" aria-labelledby="jTitle">` titled "The journey · select a module"; an `<svg viewBox="0 0 1080 160">` with nine `.arc-node` `<g>` groups (`data-mod="F3.01"`…`F3.09"`, each `role="button" tabindex="0"`), grouped under phase labels FOUNDATIONS / DATA & SHAPE / CONCURRENCY, plus `start here` and `lab` end labels. Below it an `.arc-readout` with ids `#jNm`, `#jOne`, `#jId`, `#jPhase`, `#jStatus`, and `#jOpen`.
- **Pure function:** `selectMod(id)` — toggles the `active` class on the matching `.arc-node`, then writes the module's `title`/`one`/`id`/`phase`/`status` into the readout and rebuilds `#jOpen`'s "Open `<id>` · `<slug>` →" link from the `MODS` dataset. Wired via `click` and `keydown` (Enter/Space) on each node; initial call `selectMod('F3.01')`.
- **`MODS` dataset:** the nine modules keyed `F3.01`–`F3.09`, each `{ title, one, phase, status: 'available now', route, slug }` (and `lab: true` on `F3.09`) — the same nine routes listed above.
- **Default readout (static markup):** `#jNm` "Values, types & IEx", `#jOne` "The data you build with; the shell as a tool.", `#jId` "F3.01", `#jPhase` "Foundations", `#jStatus` "available now", `#jOpen` `<a href="/elixir/language/values">Open F3.01 · values →</a>`.
- **Degrades:** the SVG, default readout, and the `F3.01` open-link are present in static markup; JS only re-applies the already-default `F3.01` state. The `.arc-flow` dashed-line animation is gated by `@media (prefers-reduced-motion: no-preference)`; no browser storage.

`.take` (verbatim): "The chapter is one line of reasoning: learn the syntax and data, give that data shape, then put it to work across processes — the thing the BEAM was built to do."

### Footer build-stamp decoder (`#stamp`)
- **Stamp id:** `TSK0NbBlxkmhTE` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-31 13:51:47 UTC".
- **Pure functions:** `b62decode(s)` (base62 over `"0123…XYZabc…xyz"` → BigInt); `pad2(x)`; `decodeBranded(id)` — splits `ns = id.slice(0,3)` (`TSK`) and `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Decoding `TSK0NbBlxkmhTE` yields `ns=TSK · node=0 · seq=0 · 2026-05-31 13:51:47 UTC`, matching the hard-coded `#st-ts`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

This chapter landing carries no `#refs` References block. The per-module References blocks live on the lesson/lab pages (for example `/elixir/language/values` and `/elixir/language/playground`).

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><span class="rcur">language</span>` (current segment `language` not a link).
- **crumbs:** `Course` → `/elixir` · sep `/` · here `F3 · The Elixir Language` (no link).
- **toc-mini:** none on this landing; in-page section anchors are `#arc` ("The arc of the chapter"), `#intro` ("Before the lessons"), `#modules` ("The nine modules"), `#sits` ("Where this sits"), reached via the journey readout and prose links.
- **pager:** prev → `/elixir/functional` ("← F2 · Functional"); next → `/elixir/language/values` ("Start · F3.01 · values →").
- **footer (`.foot-nav`, three columns):**
  - Chapters: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Brand `.brand` (header) and `.foot-logo` (footer) both point at `/elixir`.
- **Page meta:** `<title>` "The Elixir Language — F3 · jonnify"; `<meta name="description">` "The chapter that grounds the functional ideas of F2 in real Elixir: values and IEx, pattern matching, modules, enumerables and streams, structs, protocols, processes, and OTP. Start with the language's history, a release timeline, and a look under the hood."

## Build instruction

To rebuild this chapter landing, copy the `<head>`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir (purple) accent — the closest model is this page's own `elixir/language/index.html` (the only F3 chapter landing) — then change only `<title>`/`<meta>`, the route-tag, and the `<main>` body. Keep the journey-path `selectMod`/`MODS` dataset and the branded-stamp decoder intact, and preserve the clamp-spacing in `clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` (spaces around `+` are load-bearing; without them the whole declaration is dropped and `h1` falls back to ~32px). No-invent guards: the chapter teaches only the real Elixir language surfaces; the running example is a learning `Portal`, whose real surfaces are a branded store, an event-sourced engine behind ONE `Portal` facade, and a Phoenix web app — invent no other Portal modules, and cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of *just*/*simply*/*obviously*. Model sibling to copy from: `elixir/language/index.html`.
