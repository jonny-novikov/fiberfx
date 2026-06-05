# F3 — A short history of Elixir (front-matter reading 1)

- **Route (served):** `/elixir/language/history`
- **File:** `elixir/language/history.html`
- **Place in the chapter:** the first of three optional front-matter readings the F3 landing routes the reader through "before the lessons" (reading 1 of 3). It gives the language its origin story; it precedes reading 2, `/elixir/language/timeline`.
- **Accent:** elixir (purple); the `<h1>` accent word `Elixir` is the `<span class="ex">`.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3 · before the lessons · reading 1`

`<h1>`: A short history of `Elixir`

Lede (verbatim):

> Elixir is a young language built on a machine that had already been proving itself in production for two decades. The story is about one engineer who wanted Ruby's ergonomics and Erlang's resilience at the same time, and decided he could have both.

No `.kicker` line is present on this reading.

## Sections

In order: `#story` ("The story"), `#inherit` ("What it inherited" — the interactive), `#facts` ("Key facts").

- **The story (`#story`):** prose tracing José Valim (Ruby on Rails core team) from his multi-core Rails work to Erlang and the BEAM; the first commit on 9 January 2011 at Plataformatec, the first public release v0.5.0 on 25 May 2012, and the stable v1.0 on 18 September 2014 (macros, protocols, and the Mix build tool).
- **Key facts (`#facts`):** a `.deflist` — Creator (José Valim), First commit (9 January 2011, Plataformatec), First public release (v0.5.0, 25 May 2012), Version 1.0 (18 September 2014), Runtime (the BEAM, full Erlang interop), License (Apache 2.0; `.ex` and `.exs`).
- **Running example:** none; the page is narrative history, not Portal domain code.
- **`.note` (verbatim):** "Next: **the release timeline** — how the language grew, one headline per version."

## The interactives

### Figure — "Influences · select a parent" (`#inherit`)
- **Markup:** `<figure class="fig" aria-labelledby="iTitle">` titled "Influences · select a parent"; a `.controls > .solid-select#infSel` group of three buttons, an `<svg viewBox="0 0 720 270">` with three influence `<g class="inf-node">` boxes feeding an Elixir box (arrows `#arr-erlang`/`#arr-ruby`/`#arr-clojure`, boxes `#box-erlang`/`#box-ruby`/`#box-clojure`), and a `.geo-readout#infOut` (`aria-live="polite"`).
- **Control buttons (`#infSel`):** `data-inf="erlang" data-c="elixir"` ("Erlang", starts `active`); `data-inf="ruby" data-c="burg"` ("Ruby"); `data-inf="clojure" data-c="sage"` ("Clojure"). The three `.inf-node` SVG boxes are also clickable (`role="button" tabindex="0"`).
- **Pure function:** `selectInf(key)` — for `erlang`/`ruby`/`clojure`, sets the matching `#box-<k>` stroke/fill and `#arr-<k>` stroke to its `INF[k].color` (on) or `#2a3252`/`#10162b` (off); toggles each `#infSel` button's `active` class and `aria-pressed`; and writes `INF[key].text` into `#infOut.innerHTML`. Wired via `click` on each button and `click`/`keydown` on each `.inf-node`; initial call `selectInf('erlang')`.
- **`INF` readout strings (verbatim):**
  - erlang: "**From Erlang:** the BEAM and OTP. Lightweight processes, message passing, supervision, and fault tolerance — Elixir runs on the same virtual machine and can call any Erlang module directly."
  - ruby: "**From Ruby:** an approachable, expressive surface and a focus on developer happiness — do/end blocks, readable code, and first-class tooling such as Mix and IEx."
  - clojure: "**From Clojure:** macros and protocols. Code-as-data metaprogramming from the Lisp tradition, and polymorphism dispatched on the data type rather than on a class."
- **`BOXON` highlight fills:** `erlang '#1a1530'`, `ruby '#1f1418'`, `clojure '#16241a'`.
- **Degrades:** the three influence buttons, the SVG boxes, and the `.bridge` summary ("The inheritance" → "The result") are all in static markup; JS only highlights and writes the readout (the `#infOut` default state is supplied by `selectInf('erlang')`). No browser storage; `prefers-reduced-motion` respected globally.

`.bridge` (verbatim): "The inheritance — A resilient runtime from Erlang, a friendly surface from Ruby, and metaprogramming from the Lisp family by way of Clojure." → "The result — A functional, concurrent language that feels modern yet runs on a machine proven over decades."

### Footer build-stamp decoder (`#stamp`)
- **Stamp id:** `TSK0Nb9nIPf4oC` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-31 13:24:06 UTC". The `decodeBranded` function (epoch `1704067200000`) decodes it to `ns=TSK · node=0 · seq=0 · 2026-05-31 13:24:06 UTC`, matching `#st-ts`. Toggle on click / Enter / Space.

## References (#refs, verbatim)

This reading carries no `#refs` References block (the `.refs` styles are absent from its `<style>`; only the lesson and lab pages, `values` and `playground`, carry one). External facts are cited inline in the `#story` and `#facts` prose rather than as a Sources list.

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/language">language</a><span class="rsep">/</span><span class="rcur">history</span>`.
- **crumbs:** `F3 · The Elixir Language` → `/elixir/language` · sep `/` · here `A short history` (no link).
- **toc-mini:** `#story` ("The story") · `#inherit` ("What it inherited") · `#facts` ("Key facts").
- **pager:** prev → `/elixir/language` ("← F3 · overview"); next → `/elixir/language/timeline` ("Next · the timeline →").
- **footer (`.foot-nav`, three columns):** Chapters → `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; The course → `/elixir`, `/elixir/course`, `/elixir/algebra/functions`; brand + foot-logo both → `/elixir`.
- **Page meta:** `<title>` "A short history of Elixir — F3 · jonnify"; `<meta name="description">` "Why José Valim built Elixir on the Erlang VM in 2011, what it inherited from Erlang, Ruby, and Clojure, and how it reached a stable 1.0 in 2014."

## Build instruction

To rebuild this front-matter reading, copy the `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir (purple) accent — the closest model is the sibling reading `elixir/language/under-the-hood.html` (same eyebrow form `F3 · before the lessons · reading N`, same select-a-parent/stage figure pattern, and like this page no `.refs` block) — then change only `<title>`/`<meta>`, the route-tag, and the `<main>` body. Keep the `.solid-select#infSel`/`selectInf` interactive and the branded-stamp decoder. Preserve clamp-spacing (`clamp(2.7rem,1.9rem + 4.2vw,5.1rem)`; spaces around `+` are load-bearing). No-invent guards: state only verifiable history (creator, dates, releases) and the real Erlang/Ruby/Clojure inheritances as written; the chapter's running example is a learning `Portal` whose only real surfaces are a branded store, an event-sourced engine behind ONE `Portal` facade, and a Phoenix web app — invent no others, and cite the companion course for OTP internals rather than re-teaching them. Voice: no first person, no exclamation marks, no emoji, and none of *just*/*simply*/*obviously*. Model sibling to copy from: `elixir/language/under-the-hood.html` (front-matter reading), or this page `elixir/language/history.html`.
