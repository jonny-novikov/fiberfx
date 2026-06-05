# F3 — The release timeline (front-matter reading 2)

- **Route (served):** `/elixir/language/timeline`
- **File:** `elixir/language/timeline.html`
- **Place in the chapter:** the second of three optional front-matter readings the F3 landing routes the reader through "before the lessons" (reading 2 of 3). It traces the language's growth release by release; it follows reading 1 (`/elixir/language/history`) and precedes reading 3 (`/elixir/language/under-the-hood`).
- **Accent:** elixir (purple); the `<h1>` accent word `timeline` is the `<span class="ex">`.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3 · before the lessons · reading 2`

`<h1>`: The release `timeline`

Lede (verbatim):

> From a first commit in 2011 to a stable release line shipping on a predictable cadence, Elixir has grown deliberately. Each milestone below adds one capability that shaped how the language is written today.

No `.kicker` line is present on this reading.

## Sections

In order: `#tlfig` ("Milestones" — the interactive), `#cadence` ("The cadence").

- **Milestones (`#tlfig`):** the interactive timeline figure.
- **The cadence (`#cadence`):** prose on the roughly six-month minor-version rhythm since v1.0 and the set-theoretic type-system thread, plus a `.deflist` — Release rhythm ("a new minor version about every six months."), Current stable line ("the 1.19 series, on Erlang/OTP 26 through 28."), Compatibility ("each minor version supports a specific range of Erlang/OTP releases.").
- **Running example:** none; the page is the language's own version history.
- **`.note` (verbatim):** "Next: **under the hood** — what happens when this source becomes bytecode on the BEAM."

## The interactives

### Figure — "Releases · select a milestone" (`#tlfig`)
- **Markup:** `<figure class="fig" aria-labelledby="tTitle">` titled "Releases · select a milestone"; an `<svg viewBox="0 0 960 200">` with a horizontal axis line and a `<g id="tl">` populated at runtime with eight milestone nodes (each a circle, a version `<text>`, a year `<text>`, and a transparent `r=22` hit-circle `role="button" tabindex="0"`); below, a `.geo-readout#tlOut` (`aria-live="polite"`) and a live `.take#tlAge`.
- **Control:** the eight invisible hit-circles built over each node; click / keydown (Enter/Space) set `sel = i` and call `render()`.
- **`TL` dataset (the eight milestones, verbatim version/date/headline):** `first commit`/`9 Jan 2011`; `v0.5.0`/`25 May 2012`; `v1.0`/`18 Sep 2014`; `v1.6`/`2018`; `v1.9`/`2019`; `v1.14`/`2022`; `v1.17`/`2024`; `v1.19`/`9 Jan 2026`. Each carries a one-line headline `h`, for example v1.0 "The first stable release: macros, protocols, and the Mix build tool." and v1.19 "The current stable line, running on Erlang/OTP 26 through 28."
- **Pure functions:** `xAt(i)` positions a node along the axis; `render()` redraws the eight nodes (highlighting `sel` with a dashed tick and brighter colours) and writes `#tlOut` as `<b>version</b> · date — headline`; the default `sel = 2` (v1.0). A separate IIFE builds the hit-areas. A live `#tlAge` paragraph computes `new Date().getFullYear() - 2011` and writes "That is about N years since the first commit — a deliberately steady climb, with a new minor version roughly every six months."
- **Degrades:** the milestone nodes are JS-built, so absent without JS; the same eight milestones and the cadence facts are also stated in the `#cadence` prose and `.deflist` (the content survives). The `.arc-flow` animation is unused here; no browser storage; `prefers-reduced-motion` respected globally.

### Footer build-stamp decoder (`#stamp`)
- **Stamp id:** `TSK0Nb9nIdHp3I` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-31 13:24:06 UTC". The `decodeBranded` function (epoch `1704067200000`) decodes it to `ns=TSK · node=0 · seq=0 · 2026-05-31 13:24:06 UTC`, matching `#st-ts`. Toggle on click / Enter / Space.

## References (#refs, verbatim)

This reading carries no `#refs` References block (the `.refs` styles are absent from its `<style>`; only `values` and `playground` carry one). Release facts are cited inline in the `#tlfig`/`#cadence` prose and `.deflist`.

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/language">language</a><span class="rsep">/</span><span class="rcur">timeline</span>`.
- **crumbs:** `F3 · The Elixir Language` → `/elixir/language` · sep `/` · here `The release timeline` (no link).
- **toc-mini:** `#tlfig` ("The timeline") · `#cadence` ("The cadence").
- **pager:** prev → `/elixir/language/history` ("← The history"); next → `/elixir/language/under-the-hood` ("Next · under the hood →").
- **footer (`.foot-nav`, three columns):** Chapters → `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`; The course → `/elixir`, `/elixir/course`, `/elixir/algebra/functions`; brand + foot-logo both → `/elixir`.
- **Page meta:** `<title>` "The Elixir release timeline — F3 · jonnify"; `<meta name="description">` "An interactive timeline of Elixir's milestones, from the first commit in 2011 to the current stable release, with one headline feature per version."

## Build instruction

To rebuild this front-matter reading, copy the `<head>`…`</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir (purple) accent — the closest model is the sibling reading `elixir/language/under-the-hood.html` (same eyebrow form `F3 · before the lessons · reading N`, same JS-built select figure, and like this page no `.refs` block) — then change only `<title>`/`<meta>`, the route-tag, and the `<main>` body. Keep the `#tl`/`render` timeline figure, the live `#tlAge` computation, and the branded-stamp decoder. Preserve clamp-spacing (`clamp(2.7rem,1.9rem + 4.2vw,5.1rem)`; spaces around `+` are load-bearing). No-invent guards: report only verifiable release dates and headline features as written; the chapter's running example is a learning `Portal` whose only real surfaces are a branded store, an event-sourced engine behind ONE `Portal` facade, and a Phoenix web app — invent no others, and cite the companion course for OTP internals rather than re-teaching them. Voice: no first person, no exclamation marks, no emoji, and none of *just*/*simply*/*obviously*. Model sibling to copy from: `elixir/language/under-the-hood.html` (front-matter reading), or this page `elixir/language/timeline.html`.
