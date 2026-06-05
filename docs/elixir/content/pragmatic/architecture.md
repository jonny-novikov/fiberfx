# F5.0.1 — The Portal engine blueprint (dive — design front-matter)

- Route (served): `/elixir/pragmatic/architecture`
- File: `elixir/pragmatic/architecture.html`
- Place in the chapter: the first of three design front-matter pages on the F5 landing (1 of 3). It lays out the whole engine the chapter builds — four layers between the F4 store below and the F6 LiveView UI above — before any module starts. It precedes `F5.0.2 · The domain model`.
- Accent: burgundy (`--burgundy:#c4504c`; active layer stroke `#c4504c`, highlight text `#e08f8b`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Hero lede (verbatim):

> Before the first module, here is the thing the chapter builds. The **Portal engine** is a framework-free domain core: it knows the Portal's rules and holds its state, but nothing in it imports Phoenix. It sits in the middle of a stack — the branded CHAMP store from F4 underneath it, the Phoenix LiveView UI from F6 on top — and exposes a single boundary, the facade, that the UI calls. Four layers, and each one is the work of a specific F5 module, so the whole chapter points at one destination: an engine with a clean, UI-ready edge.

Eyebrow (verbatim): `F5 · system design · 1 of 3`

Kicker (verbatim):

> Select a layer to see what it does and which module builds it. The engine is the two middle layers; F4 already built the bottom, and F6 will build the top.

h1 (verbatim): `The Portal engine ` + `blueprint` (`.ex` accent span).

## Sections

In order:

1. `#stack` — "The four layers". Teaching section. Carries the interactive stack figure. Prose: writes enter at the top as an event and settle into the store; reads climb back up as a projection; the engine never reaches past its own boundary, which lets F6 mount it without the engine knowing F6 exists. `.take` (verbatim): "The engine is the two middle layers. Everything F5 does is make those two layers correct and give them a single edge; the layers above and below are someone else's job, by design."
2. `#shape` — "The shape in code". Advanced/code section. Shows the boundary in real Elixir, plus a `.bridge` (a framework-free core → one UI-ready edge) and a forward `.note`.

Running example: the Portal engine stack — UI (Phoenix LiveView, F6) → engine facade (`Portal.Engine`, F5.08) → domain core (contexts · commands · queries · events, F5.02–F5.06) → persistence (branded CHAMP store + Snowflake ids, F4).

Real Elixir code shown (the `#shape` `pre.code`, verbatim):

```
# the boundary the UI calls — assembled across F5, mounted in F6
defmodule Portal.Engine do
  # write: a command is checked, emits an event, transitions state (F5.04-F5.06)
  def dispatch(command), do: # {:ok, event} | {:error, reason}

  # read: a projection over the current state (F5.05)
  def query(name, args), do: # {:ok, result}
end

# nothing above imports this; nothing here imports Phoenix — the seam is the point
```

`.bridge` cells (verbatim): idea "a framework-free core" — "The engine knows the rules and holds the state, with no web framework inside it." → elix "one UI-ready edge" — "`dispatch/1` and `query/2` — all a LiveView needs." `.note` (verbatim): "Next in the design brief: [the domain model](/elixir/pragmatic/domain-model) — the entities and contexts that live inside the core."

## The interactives

### `#stack` figure — "The stack · select a layer" (`#arSel` selector + `#arOut` readout)

- Markup: `<figure class="fig" aria-labelledby="arTitle">` titled "The stack · select a layer". Inside: a `.controls` > `.solid-select#arSel` group, an `<svg viewBox="0 0 720 250">` with four layer `<rect>`s and per-layer tag `<text>`s, a `.geo-readout#arOut` (`aria-live="polite"`), plus two mono lines `layer:` (`#arRole`) and `built by:` (`#arResult`).
- Control ids / buttons: `#arSel` group, `role="group"`, `aria-label="Layer"`. Four `<button data-k>`s: `ui` ("UI"), `facade` ("Facade", starts `active`), `core` ("Core"), `store` ("Store").
- SVG element ids: rects `#arBox_ui`, `#arBox_facade`, `#arBox_core`, `#arBox_store`; tags `#arTag_ui`, `#arTag_facade`, `#arTag_core`, `#arTag_store`. Static tag labels: `F6`, `F5.08`, `F5.02–F5.06`, `F4 ✓`.
- Pure function: `pick(k)` — toggles each `#arSel` button's `active`/`aria-pressed` by `data-k === k`; for each id in `ORDER ['ui','facade','core','store']` sets the matching box `stroke`/`stroke-width`/`fill` (on: `#c4504c` / `2` / `#1d1320`; off: `#3a4263` / `1.3` / `#10162b`) and the tag `fill` (`#e08f8b` on, `#8b93b0` off); writes `L.name` into `#arRole`, `L.by` into `#arResult`, and an HTML readout into `#arOut`. Wired by `addEventListener('click', …)` per button; initial call `pick('facade')`.
- Readout payloads (`LAYERS`, verbatim `name` / `by` / `desc`; `#arOut` renders ``The <b>{name}</b> layer — built by <b>{by}</b>. {desc}``):
  - ui: name "Phoenix LiveView (UI)", by "F6 (next chapter)", desc "The UI renders the engine's state and sends user actions back as events. It is the only layer that touches the browser — and the engine never reaches up into it."
  - facade: name "Engine facade", by "F5.08", desc "The one public API the UI calls: `dispatch/1` to change the system and `query/2` to read it. Everything else in the engine is private behind this edge."
  - core: name "Domain core", by "F5.02–F5.06", desc "The Portal's rules and state: bounded contexts, commands and queries, domain events, and where state lives. This is the bulk of the chapter, and it imports no web framework."
  - store: name "Persistence", by "F4 (built)", desc "The branded CHAMP store and Snowflake ids from F4 — already built. The core treats it as the place entities are kept and keyed; the lab wraps the F4.12 store here."
- Degrades: the `facade` button ships `active` and the readout lines default to `Engine facade` / `F5.08` in static markup; `pick('facade')` re-applies that default state. Respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id (`#stampId`): `TSK0NclTcNzS8O`; panel `#st-ts` hard-codes `2026-06-01 12:39:01 UTC`.
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`. Decoded namespace `TSK`; decoded timestamp matches `2026-06-01 12:39:01 UTC`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

Intro line: "The ideas behind a framework-free core with one boundary."

Sources:
- [Alistair Cockburn — Hexagonal architecture](https://alistair.cockburn.us/hexagonal-architecture/) — a core with ports, isolated from the UI.
- [Hunt & Thomas — *The Pragmatic Programmer*](https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/) — orthogonality and decoupling.
- [Phoenix — LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) — the UI layer F6 mounts on top.

Related in this course:
- `F5.0.2 · The domain model` → `/elixir/pragmatic/domain-model` — what lives in the core.
- `F5.0.3 · The command & event flow` → `/elixir/pragmatic/flow` — how the core moves.
- `F4.09 · Branded CHAMP maps & GenServer` → `/elixir/algorithms/branded-champ` — the store at the bottom layer.
- `F5 · Pragmatic Programming` → `/elixir/pragmatic`

## Wiring

- route-tag (verbatim): `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/pragmatic">pragmatic</a><span class="rsep">/</span><span class="rcur">architecture</span>` — i.e. `/ elixir / pragmatic / architecture`.
- crumbs (verbatim): `Contents` → `/elixir/course` · sep `/` · `F5 · Pragmatic Programming` → `/elixir/pragmatic` · sep `/` · here `The blueprint` (no link).
- toc-mini: `#stack` ("The four layers") · `#shape` ("The shape in code").
- pager: prev → `/elixir/pragmatic` ("← F5 · chapter overview"); next → `/elixir/pragmatic/domain-model` ("Next · the domain model →").
- footer (3-column `foot-nav`): brand `.foot-logo` → `/elixir`, `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."; Chapters column links `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework"); The course column links `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
- Page meta: `<title>` "The Portal engine blueprint — F5.0.1 · jonnify"; `<meta description>` "The system this chapter builds, at a glance: the Portal engine is a framework-free domain core that sits between the branded CHAMP store from F4 below and the Phoenix LiveView UI from F6 above. Four layers — UI, the engine facade, the domain core (contexts, commands, queries, events), and persistence — each built by a specific F5 module, so the chapter has one destination: a UI-ready engine boundary."

## Build instruction

To rebuild this page, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built design sibling on this burgundy chapter — the model is `elixir/pragmatic/domain-model.html` (the nearest design front-matter sibling, same hero/figure/refs anatomy) — then change only `<title>`/`<meta description>`, the `.route-tag` (last segment `<span class="rcur">architecture</span>`), the crumbs/eyebrow ("1 of 3"), and the `<main>` body. Keep the `#arSel`/`#arOut` selector pattern and the `pick(k)` shape; ship the `facade` button `active` so the figure degrades to a default readout. No-invent guards: use only the real Portal surfaces as written — `Portal.Engine` with `dispatch/1` and `query/2` as the one facade, a framework-free event-sourced core, the branded CHAMP store from F4, the Phoenix LiveView UI from F6 — cite the companion `/elixir` chapters for store/Phoenix internals, do not re-teach. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously.
