# F5.01.1 — The development roadmap (dive)

- Route (served): `/elixir/pragmatic/foundations/roadmap`
- File: `elixir/pragmatic/foundations/roadmap.html`
- Place in the chapter: the first of F5.01's three dives (part 1 of 3). It names the whole path the Portal travels — HTML templating → simple web server → Portal logic → Phoenix → Fly — and makes the case for starting thin (the tracer-bullet move) before the next dive shows the server itself.
- Accent: burgundy (`--burgundy: #c4504c`; the F5 chapter accent).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F5.01 · part 1 of 3`

Hero `h1` (verbatim): The development roadmap

Hero lede (`.lede`, verbatim):

> The Portal is built along one path, and naming it up front keeps every decision honest. The path is: **HTML templating**, then a **simple web server**, then the **Portal logic** behind it, then **Phoenix**, then **Fly** in production. The ordering is the point. You do not build the engine in full and bolt on a web layer at the end; you get a thin slice running first — a tracer bullet — and grow it. The system is always runnable, so risk is paid down early and there is always something to show.

Kicker (`.kicker`, verbatim):

> Two ways to build the same Portal, and why the order changes everything. Then the five stages, one at a time.

## Sections

In order, the teaching arc runs from why → what:

1. **Two strategies** (`#strategy`) — the difference is *when the thing first runs*, not how much you build; the `#rmSel` figure compares "big design up front" against "start thin, iterate". `.take` (verbatim): "A thin slice that runs is worth more than a thick design that does not. The roadmap is that instinct, spread across the course: ship a runnable Portal early, then make it real."
2. **The five stages** (`#stages`) — each stage leaves the Portal runnable and adds one capability; mapped onto one Mix project (engine tree vs. web tree). `.bridge`: "the instinct" → "the roadmap". `.take` is folded into the section close; the `.note` (verbatim) points forward: "Next: [**a thin web server in Elixir**](/elixir/pragmatic/foundations/thin-server) — stage two, the server that makes the Portal runnable today."

The real Elixir code shown (`pre.code`) is the roadmap mapped onto one Mix project:

```
# the roadmap, mapped onto one Mix project
portal/
  lib/
    portal/         # Portal logic — the engine, grows in F5.02–F5.09
    portal_web/     # the web layer — thin now (F5.01), Phoenix later (F6)
  mix.exs           # deps: {:bandit}, {:plug} now;  {:phoenix} arrives in F6

# 1 templating  — HTML/EEx on screen .......... done
# 2 web server  — thin Plug + Bandit ........... F5.01  (here)
# 3 Portal      — domain, contracts, events .... F5.02–F5.09
# 4 Phoenix     — replace the server, add UI ... F6
# 5 Fly         — deploy to production ......... upcoming (out of scope)
```

## The interactives

### Figure — "First running build · select an approach" (`#rmSel` selector + `#rmOut` readout)

- `<figure class="fig" aria-labelledby="rmTitle">`, title `#rmTitle` "First running build · select an approach". A `.solid-select#rmSel` group of two `<button data-k>`s and an `<svg viewBox="0 0 720 180">` of two timeline bars.
- Buttons (`data-k`, label): `bigbang` "big design up front" · `thin` "start thin, iterate" (`class="active"`).
- SVG chip ids: `#rmChip_bigbang` (first runs at the end) and `#rmChip_thin` (burgundy `#c4504c`; first runs on day one, then grows).
- Pure function: `pick(k)` looks up `APP[k]`, toggles each `#rmSel` button's `active`/`aria-pressed`, restrokes the two bars (`BURG_MUTE = '#c4504c'` when on, else `#3a4263`), and writes `#rmRole` (name), `#rmResult` (first), and `#rmOut.innerHTML` (`name — first running build first. desc`). Initial call `pick('thin')`.
- Readout `APP` desc strings (verbatim):
  - bigbang: name "Big design up front", first "at the end" — "Build every layer before anything runs. The first integration happens last, so the riskiest unknowns — does the web reach the engine, does a request round-trip — surface latest, when they are most expensive to fix."
  - thin: name "Start thin, iterate", first "day one" — "Get one request end to end first, then grow. The system runs from the start, so integration risk is paid down early and every later change lands in a working frame you can demo and test."
- Static default: the `start thin, iterate` button is `active` and the static labels (`approach: Start thin, iterate`, `first running build: day one`) render in markup; `#rmOut` is empty until `pick('thin')` fills it. The roadmap `.arc-flow`/animations respect `prefers-reduced-motion`; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0NcqelCK1Ro` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 13:51:30 UTC".
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`, formatted UTC. Toggle on click / Enter / Space.
- Decoding `TSK0NcqelCK1Ro`: namespace `TSK`; the snowflake over epoch `2024-01-01` resolves to the panel's stamped "2026-06-01 13:51:30 UTC".

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

**Sources**
- [Introduction to Mix — Elixir documentation](https://hexdocs.pm/elixir/introduction-to-mix.html) — applications, deps, and tasks.
- [`Mix` — Elixir documentation](https://hexdocs.pm/mix/Mix.html) — the build tool reference.

**Related in this course**
- F5.01 · Foundations → `/elixir/pragmatic/foundations`
- A thin web server in Elixir → `/elixir/pragmatic/foundations/thin-server`
- F5 · Pragmatic Programming → `/elixir/pragmatic`

## Wiring

- route-tag (verbatim): `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/pragmatic">pragmatic</a><span class="rsep">/</span><a href="/elixir/pragmatic/foundations">foundations</a><span class="rsep">/</span><span class="rcur">roadmap</span>`.
- crumbs: `F5` → `/elixir/pragmatic` · sep `/` · `F5.01` → `/elixir/pragmatic/foundations` · sep `/` · here `roadmap` (no link).
- toc-mini: `#strategy` ("Two strategies") · `#stages` ("The five stages").
- pager: prev → `/elixir/pragmatic/foundations` ("← F5.01 · foundations"); next → `/elixir/pragmatic/foundations/thin-server` ("Next · the thin server →").
- footer (3-column `.foot-nav`): Brand → `/elixir`; Chapters column `/elixir/algebra` ("F1 · Algebra"), `/elixir/functional` ("F2 · Functional Programming"), `/elixir/language` ("F3 · The Elixir Language"), `/elixir/algorithms` ("F4 · Algorithms & Data Structures"), `/elixir/pragmatic` ("F5 · Pragmatic Programming"), `/elixir/phoenix` ("F6 · Phoenix Framework"); The course column `/elixir` ("Course home"), `/elixir/course` ("Contents & history"), `/elixir/algebra/functions` ("Start · F1.01").
- Page meta: `<title>` "The development roadmap — F5.01.1 · jonnify"; `<meta description>` "The whole course is one development roadmap: HTML templating, then a simple web server, then the Portal logic behind it, then Phoenix in F6, then Fly in production. You start thin and grow it so the system runs from day one — a tracer bullet — instead of disappearing into months of build with nothing to show."

## Build instruction

To rebuild this page, copy the head…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent BUILT sibling on the burgundy F5 accent — the model is its sibling dive `elixir/pragmatic/foundations/thin-server.html` (same `--burgundy` chapter, same single-column lesson `.hero`, same stamp/decoder and reveal scripts) — and change only `<title>`/`<meta>`, the route-tag, the crumbs, and the `<main>` body. The dive body is a single-column `.hero` lede + kicker, two `<section>`s (`#strategy` with the `#rmSel` figure, `#stages` with the Mix-project `pre.code` + `.bridge`), then the `#refs` and pager. No-invent guards: use only the real Portal surfaces as written — the engine in `lib/portal/`, the thin web layer in `lib/portal_web/`, `Bandit`/`Plug` now and `Phoenix` in F6; cite the companion `/elixir` course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
