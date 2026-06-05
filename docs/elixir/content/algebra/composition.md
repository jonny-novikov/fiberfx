# F1.03 — Composition, f∘g (dive / lesson)

- **Route (served):** `/elixir/algebra/composition`
- **File:** `elixir/algebra/composition.html`
- **Place in the chapter:** the third lesson of F1 · Algebra, closing the Foundations movement. It follows `F1.02` (functions as values, evaluated by substitution) and shows how those values are joined into larger ones — the composite, why order matters and grouping is free, and the pipe. Its pager forwards back to the chapter ("More in F1 · Algebra"); the next chapter lesson is `F1.04`.
- **Accent:** gold chapter accent (gold/elixir token palette).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F1 · Algebra`

`h1`: `Composition, f∘g` (the `f∘g` rendered as a `.math` span).

Hero lede (verbatim): "Feed one function’s output into the next and you have built a third function. Order changes the result; grouping does not; and Elixir’s pipe is this idea written left to right."

Kicker (verbatim): "F1.01 made functions into values and F1.02 let you evaluate them by substitution. Composition is how those values are joined into larger ones. We define the composite, watch why order matters and grouping is free, and arrive at the pipe — the operator the landing page has been previewing."

## Sections

Three teaching sections, each closing with a `.bridge` and a `.take`:

1. **Chaining functions** (`#compose`) — the composite `(g∘f)(x) = g(f(x))`, range/domain fit, and that order matters. A `.deflist` defines composite / order / associative / identity. Running example: two of `f = +1`, `×2`, `x²` composed both ways. Real Elixir shown: `x |> f.() |> g.()` and `g(f(x))`.
2. **Associativity** (`#associativity`) — `(h∘g)∘f = h∘(g∘f)`; grouping is free, so a chain needs no parentheses. Running example: `f = +1`, `g = ×2`, `h = x²` with a movable grouping bracket. Real Elixir shown: `x |> inc.() |> dbl.() |> sq.()`.
3. **The pipe** (`#pipe`) — `|>` as composition in evaluation order; three spellings (pipe / composition / nested) of one function, plus the identity stage as the neutral element. Real Elixir shown: pipe, composition `(sq ∘ dbl ∘ inc)(x)`, nested `sq(dbl(inc(x)))`, and `& &1` as identity.

Synthesis "What this lands" closes the arc (naming F1.01, F1.02, F1.07, F2) and forwards to F1.04.

## The interactives

Three interactive figures plus the footer build-stamp decoder. A shared `FNS` dataset drives all three: `inc {+1}`, `dbl {×2}`, `sq {x²}`.

### Figure — "Compose two · order matters" (`#ordTitle`)

- Control group `#ordF` ("Choose f"): `data-fn="inc" data-c="sage"` "f = +1" (active); `data-fn="dbl" data-c="blue"` "f = ×2"; `data-fn="sq" data-c="gold"` "f = x²". Control group `#ordG` ("Choose g"): "g = +1" (sage); "g = ×2" (blue); "g = x²" (gold, active). `.fold-ctrl` slider `#ordX` (input x; min 0, max 9, step 1, value 3) with `#ordXval`.
- SVG (`viewBox="0 0 760 150"`): function-machine `#o_in`, `#o_f`, `#o_mid`, `#o_g`, `#o_out`. Code block `#ordCode`, readout `#ordOut`.
- Pure function: `renderOrd()` reads the active f/g and x, computes `gf = g(f(x))` and `fg = f(g(x))`, updates the machine, writes the `g ∘ f` code (pipe + nested), and the readout. Initial call `renderOrd()`.
- Readout `#ordOut` (verbatim default): `(g ∘ f)(3) = 16 · (f ∘ g)(3) = 10 · order matters`. (When the two agree: `same here`.)

### Figure — "Compose three · grouping is free" (`#assTitle`)

- Control group `#assSel` ("Choose a grouping"): `data-grp="right" data-c="elixir"` "h ∘ (g ∘ f)" (active); `data-grp="left" data-c="gold"` "(h ∘ g) ∘ f". `.fold-ctrl` slider `#assX` (input x; min 0, max 6, step 1, value 3) with `#assXval`.
- SVG (`viewBox="0 0 660 180"`): three-stage chain `#a_in`, `#a_v1`, `#a_v2`, `#a_out`, with grouping brackets `#brFG`/`#brFGlabel` and `#brGH`/`#brGHlabel`. Code block `#assCode`, readout `#assOut`.
- Pure function: `renderAss()` computes `v1 = x+1`, `v2 = 2·v1`, `out = v2²`; highlights whichever bracket the grouping selects; writes the pipe code and the readout. Initial call `renderAss()`.
- Readout `#assOut` (verbatim default): `(h ∘ (g ∘ f))(3) = 64 · ((h ∘ g) ∘ f)(3) = 64 · equal — grouping does not matter`.

### Figure — "Three notations · one value" (`#pipeTitle`)

- Control group `#pipeStages` ("Stages in the pipeline"): three toggle buttons all starting `active` — `data-stage="inc" data-c="sage"` "inc · +1"; `data-stage="dbl" data-c="blue"` "dbl · ×2"; `data-stage="sq" data-c="gold"` "sq · x²". Control group `#pipeId` ("Identity stage"): one toggle `data-id="off" data-c="elixir"` "add id". `.fold-ctrl` slider `#pipeX` (input x; min 0, max 9, step 1, value 3) with `#pipeXval`.
- Code block `#pipeCode` (no SVG — code-only figure), readout `#pipeOut`.
- Pure function: `renderPipe()` reads the active stages (in `PIPE_ORDER = ['inc','dbl','sq']`) and the id toggle, folds them over x, then writes three labelled spellings into `#pipeCode` (pipe — left to right; composition — right to left; nested calls) and the readout. Initial call `renderPipe()`.
- Readout `#pipeOut` (verbatim default): `x = 3 · three spellings, one value = 64`. (With id on, it appends `· f ∘ id = f — value unchanged`.)

### Degrade behaviour

Controls, SVGs, and the default readouts render in static markup; `#ordCode`, `#assCode`, `#pipeCode` are filled by JS on init. The page respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0NZIcjv0dSi` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-30 10:32:27 UTC" (the decoded UTC timestamp).
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`; `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`; `EPOCH_MS = 1704067200000`). Toggle on click / Enter / Space.

## References (#refs, verbatim)

No `#refs` References section is present on this page. The lesson's cross-links are the crumbs, toc-mini, `.note`, pager, and footer (see Wiring); the synthesis names F1.07 and F2 in prose, and the pager returns to the chapter.

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/algebra">algebra</a><span class="rsep">/</span><span class="rcur">composition</span>`.
- **crumbs:** `F1 · Algebra` → `/elixir/algebra` · sep `/` · `F1.02` → `/elixir/algebra/substitution` · sep `/` · here `F1.03` (no link).
- **toc-mini:** `#compose` ("Chaining functions") · `#associativity` ("Associativity") · `#pipe` ("The pipe").
- **pager:** prev → `/elixir/algebra/substitution` ("← F1.02 · substitution"); next → `/elixir/algebra` ("More in F1 · Algebra →"). (Note: the forward link returns to the chapter, not to F1.04; the synthesis `.note` names F1.04 as "(planned)" — written before later lessons were marked built.)
- **footer:** identical three-column footer — brand → `/elixir`; `Chapters` F1–F6; `The course` `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- **Page meta:** `<title>` "Composition, f∘g — F1.03 · jonnify"; `<meta description>` "Chaining functions into new ones: the composite g∘f, why order matters and grouping is free, and the pipe as composition written in evaluation order."

## Build instruction

To (re)build this lesson, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built gold-accent sibling — the model is `elixir/algebra/substitution.html` (F1.02, the same lesson template: crumbs, toc-mini, three figures, `.bridge`/`.take` rhythm, code blocks filled by JS) — then change only `<title>`/`<meta>`, the route-tag, the crumbs, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written (branded store, event-sourced engine behind one `Portal` facade, Phoenix web app); this lesson is pure algebra and names no engine internals — cite the companion course for OTP internals, do not re-teach. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously.
