# F5.01 — A running Portal from day one (module hub)

- Route (served): `/elixir/pragmatic/foundations`
- File: `elixir/pragmatic/foundations/index.html`
- Place in the chapter: the opening module of F5 · Pragmatic Programming. It sets the approach the whole chapter builds on — the course-wide roadmap, the thin web server that runs the Portal today, and the seam that lets Phoenix take over in F6 — and frames its three deep dives (`roadmap`, `thin-server`, `replaceable`). It bridges from F4 (the branded CHAMP store was built) into F5 (make it run), and points forward to F5.02 — Modeling the Portal domain.
- Accent: burgundy (`--burgundy: #c4504c`; the F5 chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5 · the approach · module 1`

Hero `h1` (verbatim): A running Portal from `day one` (with `day one` in `<span class="ex">`).

Hero lede (`.lede`, verbatim):

> The first pragmatic decision is the cheapest and the most important: the system runs from the start. Rather than build the Portal in the dark for months and wire up a web layer at the end, you stand it up behind a **thin Elixir web server** on day one — a handful of lines that answer real HTTP requests by calling the engine — and then grow the engine underneath it. The server is deliberately minimal, and it is meant to be thrown away: in F6 it is replaced by Phoenix, which calls the same engine. Nothing about the Portal logic changes when that happens, because the web was never allowed to reach into it.

Kicker (`.kicker`, verbatim):

> This module sets the approach: the course-wide roadmap the Portal travels, the thin web server that runs it today, and the seam that lets Phoenix take over later without a rewrite.

## What the page frames

The hub presents three deep dives (not a `.mods` grid — the children are linked dive cards under `#dives`). The intro prose (`#dives`, verbatim): "In order: the roadmap and the case for starting thin; the minimal web server that runs the Portal today; and the discipline that keeps the web a replaceable detail so F6 can swap in Phoenix."

The three dive cards (each an `<a>` link, left-bordered by accent):

- **F5.01.1 · The development roadmap** — `/elixir/pragmatic/foundations/roadmap` — built. One-line (verbatim): "HTML templating → simple web server → Portal logic → Phoenix → Fly — the whole journey, and why you start thin." (left-border `--burgundy`)
- **F5.01.2 · A thin web server in Elixir** — `/elixir/pragmatic/foundations/thin-server` — built. One-line (verbatim): "A `Plug.Router` behind `Bandit`: each route turns a request into a call on `Portal.Engine` and sends the result." (left-border `--blue`)
- **F5.01.3 · A web layer built for replacement** — `/elixir/pragmatic/foundations/replaceable` — built. One-line (verbatim): "Every route only calls `dispatch/1` and `query/2`, so Phoenix slots into the same seam in F6 with the engine untouched." (left-border `--gold`)

The `#why` section carries a roadmap figure (below) and a `.take` (verbatim): "You are not building a web server; you are building the Portal. The server is scaffolding that lets the Portal run while it is built — valuable precisely because it is cheap to stand up and cheap to replace."

The `.bridge` (F4 → F5): cell "F4 · the store was built" → cell "F5 · make it run". The closing `.note` (verbatim): "Start with [the development roadmap](/elixir/pragmatic/foundations/roadmap), then [the thin web server](/elixir/pragmatic/foundations/thin-server), then [building it for replacement](/elixir/pragmatic/foundations/replaceable). The next module, F5.02 — Modeling the Portal domain, gives the engine its first real shape. See also the design brief: [the blueprint](/elixir/pragmatic/architecture)."

## The interactives

### Hero figure — "One swappable part" (`#rpSwap` swap toggle)

- `<figure class="hero-fig" aria-labelledby="rpTitle">`, figcaption `.fc-lbl#rpTitle` "One swappable part". An `<svg viewBox="0 0 320 300">` shows THE BROWSER (`GET /enroll`) → the WEB LAYER (`#rpSwap`, replaceable) → the ENGINE CORE (`Portal.Engine · dispatch / query`, untouched).
- Controls: `<button id="rpBtn">` (label "▸ swap in Phoenix") and `<button id="rpReset" class="ghost">` (label "reset").
- Caption `.hp-cap#rpCap` (`aria-live="polite"`).
- Pure functions (IIFE): `el(name, attrs)` builds an SVG node; `row(label, isNew)` builds the WEB LAYER `g.hp-row`; `render()` clears `#rpSwap` and rebuilds the row from the `phoenix` boolean, rewriting `#rpCap` and the button label. `rpBtn` toggles `phoenix`; `rpReset` sets it false.
- Caption strings (verbatim):
  - thin (`phoenix = false`): `[ thin Elixir web server ]` then "The web layer runs the Portal today — small, and built to be thrown away." (button: "▸ swap in Phoenix")
  - phoenix (`phoenix = true`): `[ Phoenix + LiveView ]` then "A new web layer slots into the same seam. The engine core is untouched." (button: "▸ back to the thin server")
- Static default: the markup ships the thin-server `hp-row` and the thin caption; JS only enhances. The new-row animation `@keyframes hpIn` is disabled under `prefers-reduced-motion: reduce`. No browser storage.

### Roadmap figure — "The development roadmap · select a stage" (`#foSel` selector + `#foOut` readout)

- `<figure class="fig" aria-labelledby="foTitle">`, title `#foTitle` "The development roadmap · select a stage". A `.solid-select#foSel` group of five `<button data-k>`s and an `<svg viewBox="0 0 720 170">` of five chips.
- Buttons (`data-k`, label): `templating` "templating" · `server` "web server" (`class="active"`) · `portal` "Portal" · `phoenix` "Phoenix" · `fly` "Fly".
- SVG chip ids: `#foChip_templating`, `#foChip_server` (burgundy `#c4504c`, F5.01 here), `#foChip_portal`, `#foChip_phoenix`, `#foChip_fly`.
- Pure function: `pick(k)` looks up `STAGES[k]`, toggles each `#foSel` button's `active`/`aria-pressed`, restrokes each chip (burgundy `BURG_MUTE = '#c4504c'` when on, else `#3a4263` or `#2a3252` for `fly`), and writes `#foRole` (name), `#foResult` (where), and `#foOut.innerHTML` (`name — where. desc`). `ORDER = ['templating','server','portal','phoenix','fly']`; initial call `pick('server')`.
- Readout `STAGES` desc strings (verbatim):
  - templating: name "HTML templating", where "earlier (done)" — "EEx renders HTML. The Portal already has a way to put markup on the screen — the front of the system exists before its engine does."
  - server: name "Simple web server", where "F5.01 (here)" — "A thin Elixir web server answers HTTP requests by calling the Portal. This module. It is deliberately minimal — enough to run, not a framework."
  - portal: name "Portal logic", where "F5.02–F5.09" — "The engine behind the server grows module by module — domain, contracts, events, state, tests, seams — while the server keeps running the whole time."
  - phoenix: name "Phoenix", where "F6" — "The thin server is replaced by Phoenix and LiveView, which call the same engine. The Portal logic does not change — only its front end."
  - fly: name "Fly production", where "upcoming · out of scope" — "The finished application is deployed and run live on Fly. A later chapter, beyond this course's current scope."
- Static default: the `web server` button is `active` and the static labels (`stage: Simple web server`, `where: F5.01 (here)`) render in markup; `#foOut` is empty until `pick('server')` fills it. Respects `prefers-reduced-motion` globally; no storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0Ncqekwi5IG` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 13:51:30 UTC".
- Pure functions: `b62decode(s)` (base62 over `"0123…XYZabc…xyz"` → BigInt); `pad2(x)`; `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`, formatted UTC. Fills `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`. Toggle on click / Enter / Space sets `.open` + `aria-expanded`.
- Decoding `TSK0Ncqekwi5IG`: namespace `TSK`; the snowflake's `ts >> 22` over epoch `2024-01-01` resolves to the panel's stamped "2026-06-01 13:51:30 UTC".

## References (#refs, verbatim)

Intro line: "Starting with a running system, and the tools that make a thin Elixir server small."

**Sources**
- [Hunt & Thomas — *The Pragmatic Programmer*](https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/) — tracer bullets and walking skeletons.
- [Elixir — Plug](https://hexdocs.pm/plug/readme.html) — the composable adapter for HTTP.
- [Bandit](https://hexdocs.pm/bandit/Bandit.html) — a pure-Elixir HTTP server for a Plug.
- [Phoenix — Overview](https://hexdocs.pm/phoenix/overview.html) — what replaces the thin server in F6.

**Related in this course**
- F5.01.1 · The development roadmap → `/elixir/pragmatic/foundations/roadmap`
- F5.01.2 · A thin web server in Elixir → `/elixir/pragmatic/foundations/thin-server`
- F5.01.3 · A web layer built for replacement → `/elixir/pragmatic/foundations/replaceable`
- F5.0.1 · The Portal engine blueprint → `/elixir/pragmatic/architecture` — the layers this server sits on.
- F5 · Pragmatic Programming → `/elixir/pragmatic`

## Wiring

- route-tag (verbatim): `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/pragmatic">pragmatic</a><span class="rsep">/</span><span class="rcur">foundations</span>`.
- crumbs: `F5 · Pragmatic Programming` → `/elixir/pragmatic` · sep `/` · here `F5.01 · foundations` (no link).
- toc-mini: `#why` ("Why start thin") · `#dives` ("Three deep dives").
- pager: prev → `/elixir/pragmatic` ("← F5 · overview"); next → `/elixir/pragmatic/foundations/roadmap` ("Start · the development roadmap →").
- footer (3-column `.foot-nav`):
  - Brand column: `.foot-logo` → `/elixir`; tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters column: `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework").
  - The course column: `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
- Page meta: `<title>` "Start thin: a running Portal from day one — F5.01 · jonnify"; `<meta description>` "Pragmatic programming starts with a system that runs. F5.01 stands the Portal up behind a minimal Elixir web server from the first day, places that move on a course-wide roadmap — HTML templating, a simple web server, Portal logic, Phoenix, then Fly production — and keeps the web layer thin enough that Phoenix replaces it in F6 without touching the engine. Three dives on the roadmap, the thin server, and the replaceable seam."

## Build instruction

To rebuild this page, copy the head…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent BUILT sibling on the burgundy F5 accent — the model is this module's own dive `elixir/pragmatic/foundations/roadmap.html` (same chapter, same `--burgundy` accent, same stamp/decoder script) — and change only `<title>`/`<meta>`, the route-tag, and the `<main>` body. The hub body differs from a dive in carrying the two-column `.hero` grid (`.hero-copy` + `.hero-art` hero figure), the `#why`/`#dives` sections, the three linked dive cards, and the F4→F5 `.bridge`. No-invent guards: use only the real Portal surfaces as written — the event-sourced engine `Portal.Engine` behind one boundary (`dispatch/1`, `query/2`), the thin `Plug.Router` on `Bandit`, the branded store under it, and Phoenix as the F6 replacement; cite the companion `/elixir` course for OTP internals (supervisors, applications) rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
