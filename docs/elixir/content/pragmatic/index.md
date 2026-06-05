# F5 — Pragmatic Programming (chapter landing)

- Route (served): `/elixir/pragmatic`
- File: `elixir/pragmatic/index.html`
- Place in the chapter: the F5 chapter landing. It frames three design front-matter pages (`architecture`, `domain-model`, `flow`) and the nine modules `F5.01`–`F5.09` that build the framework-free Portal engine technique by technique, ending in the LiveView-ready engine lab. It sits between `F4 · Algorithms & Data Structures` (which it builds on) and `F6 · Phoenix Framework` (which it hands the LiveView-ready facade to).
- Accent: burgundy (`--burgundy:#c4504c`; chapter spine and SVG nodes stroke `#9c5f5c`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Hero lede (verbatim):

> Everything so far has been parts; this chapter builds a **product**. F5 is a pragmatic, end-to-end build of the **Portal engine** — the framework-free core that holds the Portal's domain logic — applying the working practices of pragmatic programming in Elixir: stand it up behind a thin web server so it runs from day one, model the domain in plain structs and contexts, fire a tracer bullet through one real use case, guard it with contracts, separate commands from queries, decide where state lives, and test the pure core. By the last module the engine is assembled behind a clean facade and mounted in a LiveView sketch — ready to wire into Phoenix LiveView in F6.

Eyebrow (verbatim): `F5 · chapter overview`

Kicker (verbatim):

> Nine modules, one product. Each applies a pragmatic technique to the same growing engine, so by the end you have not nine demos but one coherent Portal engine with a UI-ready boundary.

h1 (verbatim): `Pragmatic ` + `programming` (`.ex` accent span).

## What the page frames

The landing carries three card sections. The `#design` section frames three design pages (`.pill built` "design"); the `#modules` section frames the nine modules (each `.pill built` "built"), the last a `.mod.lab`.

### Design front-matter (`#design` — "The system we're building")

- `F5.0.1` · The Portal engine blueprint — "The whole engine at a glance: a framework-free core between the F4 store below and the F6 LiveView UI above, and which module builds each layer." → `/elixir/pragmatic/architecture` — built (design)
- `F5.0.2` · The domain model — "The entities and bounded contexts the engine owns — Accounts, Catalog, Learning — modeled as structs keyed by branded ids." → `/elixir/pragmatic/domain-model` — built (design)
- `F5.0.3` · The command & event flow — "How one use case moves through the engine: command, contract, event, state, query — the read/write split the UI will see." → `/elixir/pragmatic/flow` — built (design)

### Modules (`#modules` — "Module navigation")

Each `.mod` is an `<a>` to its hub and lists three `.dives` (plain text, not links).

- `F5.01` · Start thin: a running Portal from day one — "Stand the Portal up behind a minimal Elixir web server now, and plan the path to Phoenix." → `/elixir/pragmatic/foundations` — built. Dives: `F5.01.1` The development roadmap · `F5.01.2` A thin web server in Elixir · `F5.01.3` A web layer built for replacement
- `F5.02` · Modeling the Portal domain — "The Portal's entities as structs and bounded contexts: Accounts, Catalog, Learning." → `/elixir/pragmatic/domain` — built. Dives: `F5.02.1` Structs & typespecs · `F5.02.2` Bounded contexts · `F5.02.3` A context's public API
- `F5.03` · Tracer bullets: a walking skeleton — "Build one use case end to end first: enroll a learner, then deliver the first lesson." → `/elixir/pragmatic/tracer-bullets` — built. Dives: `F5.03.1` Tracer bullets vs prototypes · `F5.03.2` The walking skeleton · `F5.03.3` Iterating the slice
- `F5.04` · Design by contract — "Preconditions, postconditions, and invariants on the engine's commands." → `/elixir/pragmatic/contracts` — built. Dives: `F5.04.1` Preconditions, postconditions & invariants · `F5.04.2` Assertions in Elixir · `F5.04.3` Failing fast
- `F5.05` · Commands, queries & events — "Separate writes from reads; model every change to the engine as a domain event." → `/elixir/pragmatic/cqrs` — built. Dives: `F5.05.1` Command/query separation · `F5.05.2` Domain events · `F5.05.3` The engine as a reducer
- `F5.06` · Where engine state lives — "Choosing where state lives — GenServer, Agent, ETS — and the process boundary around it." → `/elixir/pragmatic/state` — built. Dives: `F5.06.1` Choosing where state lives · `F5.06.2` The engine GenServer · `F5.06.3` Supervision
- `F5.07` · Pragmatic testing — "Testing the pure core, property-based tests, and contracts as tests." → `/elixir/pragmatic/testing` — built. Dives: `F5.07.1` Testing the pure core · `F5.07.2` Property-based testing · `F5.07.3` Contract tests
- `F5.08` · Boundaries & integration seams — "Ports, adapters, and the engine facade the UI will call — with error shapes the UI can render." → `/elixir/pragmatic/boundaries` — built. Dives: `F5.08.1` Ports & adapters · `F5.08.2` The engine facade · `F5.08.3` Error contracts for the UI
- `F5.09` · Lab: the Portal engine, LiveView-ready — "Assemble the engine facade and mount it behind a LiveView sketch — ready for F6." → `/elixir/pragmatic/engine-lab` — built (`.mod.lab`, num suffixed " · lab"). Dives: `F5.09.1` The engine facade end to end · `F5.09.2` A LiveView mount sketch · `F5.09.3` What ships in F6

`.note` after the grid (verbatim): "The chapter opens with **F5.01 — Pragmatic foundations** and closes with the **F5.09** engine lab. It builds on [**F4 — Algorithms & Data Structures**](/elixir/algorithms) — the branded CHAMP store from F4 is the kind of component the engine wraps — and hands its LiveView-ready facade to F6, the Phoenix chapter, where the UI is built."

## The interactives

This landing carries one content figure (the chapter-arc spine) plus the footer build-stamp decoder. The arc figure is a static SVG (no control group, no readout `pick`); it is not JS-driven.

### `#arc` figure — "Nine modules · one product, the Portal engine"

- Markup: `<figure class="fig" aria-labelledby="arcTitle">` titled "Nine modules · one product, the Portal engine". Inside: a static `<svg viewBox="0 0 720 158">` drawing a horizontal spine of nine nodes (circles + numeric labels `01`–`09` + name labels `serve · domain · tracer · contract · events · state · tests · seams · engine`), the ninth styled as the lab node (`engine`, sub-label "lab · LiveView-ready", stroke `#b39ddb`). Below, a static `.geo-readout` (no `id`, no `aria-live`).
- Control ids / buttons: none. The figure has no `.solid-select` group and no `pick` function.
- SVG element ids: none (the spine uses unkeyed `<circle>`/`<text>` nodes).
- Pure function: none on this figure.
- Static readout string (the `.geo-readout`, verbatim): "One product runs the length of the chapter. F5.01–F5.03 give the engine a shape that is cheap to change; F5.04–F5.06 make it trustworthy with contracts, an explicit command/query/event flow, and a decided home for state; F5.07–F5.08 make it usable from the outside, tested and behind a facade. The F5.09 lab mounts that facade in a LiveView sketch, the seam F6 picks up."
- Axis caption (verbatim): "shape it to change (01–03) · make it trustworthy (04–06) · make it usable (07–09)".
- `.take` (verbatim): "Pragmatism is not a topic; it is the discipline of building one thing well. This chapter spends every module on the same engine, so the techniques land as habits, not trivia."
- Degrades: the SVG and its readout are entirely static markup; nothing is JS-gated except the global `.reveal` scroll-in, which is bypassed under `prefers-reduced-motion`. No browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id (`#stampId`): `TSK0Nd9oGw3uls`; panel `#st-ts` hard-codes `2026-06-01 18:19:32 UTC`.
- Pure functions: `b62decode(s)` (base62 over `"0123…XYZabc…xyz"` → BigInt), `pad2(x)`, `decodeBranded(id)` — splits `ns = id.slice(0,3)` and `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Decoded namespace `TSK`; decoded timestamp matches `2026-06-01 18:19:32 UTC`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

This landing carries no `#refs` / `.refs` block. There is no References section on the chapter landing (the design subpages and module pages carry the references). The `.note` and footer links cover its cross-links.

## Wiring

- route-tag (verbatim): `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><span class="rcur">pragmatic</span>` — i.e. `/ elixir / pragmatic`.
- crumbs (verbatim): `Contents` → `/elixir/course` · sep `/` · here `F5 · Pragmatic Programming` (no link).
- toc-mini: `#design` ("The system we're building") · `#arc` ("The chapter arc") · `#modules` ("Module navigation").
- pager: prev → `/elixir/algorithms` ("← F4 · Algorithms & Data Structures"); next → `/elixir/course` ("All chapters · Contents →").
- footer (3-column `foot-nav`):
  - brand: `.foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
  - Header `.brand` and footer `.foot-logo` both point at `/elixir`.
- Page meta: `<title>` "Pragmatic Programming — F5 · jonnify"; `<meta description>` "The F5 chapter overview: a pragmatic build of the Portal engine in Elixir. Nine modules carry one product from a decoupled core through domain modeling, a tracer-bullet walking skeleton, design by contract, commands/queries/events, where state lives, testing, and integration seams — ending in a lab where the engine facade is mounted behind a LiveView sketch, ready to integrate with Phoenix LiveView in F6."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built sibling on this burgundy chapter — the model is `elixir/pragmatic/architecture.html` (closest design sibling) — then change only `<title>`/`<meta description>`, the `.route-tag` (ending in `<span class="rcur">pragmatic</span>` with no further segment, since this is the chapter root), and the `<main>` body. Keep the chapter-arc figure static (no control group); the spine SVG and its `.geo-readout` ship as fixed markup. No-invent guards: use only the real Portal surfaces as written — a branded store keyed by Snowflake namespaces, an event-sourced engine behind ONE `Portal.Engine` facade (`dispatch/1`, `query/2`), and the Phoenix web app above; cite the companion `/elixir` chapters (`F4` store, `F6` Phoenix) for internals, do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously.
