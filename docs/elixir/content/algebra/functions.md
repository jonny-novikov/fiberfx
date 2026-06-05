# F1.01 — What a function really is (dive / lesson)

- **Route (served):** `/elixir/algebra/functions`
- **File:** `elixir/algebra/functions.html`
- **Place in the chapter:** the first lesson of F1 · Algebra, in the Foundations movement and the "start here" of the whole course. It settles what a function is — a single-valued mapping, then a first-class value — and it is the foundation the rest of the chapter rests on; it precedes `F1.02` (substitution).
- **Accent:** gold chapter accent (the gold/elixir token palette; the `.ex` heading word renders in elixir-bright).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F1 · Algebra`

`h1`: `What a really is` (with the word "really" as the `.ex` accent span — `What a <span class="ex">really</span> is`).

Hero lede (verbatim): "Before any syntax: a function is a rule that assigns to every input exactly one output. That one sentence is the whole foundation the rest of the course is built on."

Kicker (verbatim): "The word is overloaded in everyday programming, where a “function” might print, mutate, or return something different each time it runs. Here we use the mathematical meaning, recover the three sets that define it, and then meet it again as an ordinary Elixir value. Get this right and composition, purity, and higher-order code all follow."

## Sections

Three teaching sections, each pairing one algebraic idea with its Elixir form via a `.bridge` and closing with a `.take`:

1. **A function is a mapping** (`#mapping`) — domain, codomain, range; the single-output rule. Running idea: a finite mapping `[-2,-1,0,1,2]` under a chosen rule. Real Elixir shown (verbatim default code block): `[-2, -1, 0, 1, 2] |> Enum.map(&(&1 * &1)) # => [4, 1, 0, 1, 4]`. A `.deflist` defines domain / codomain / range.
2. **Exactly one output** (`#one-output`) — the vertical line test; `y = x²` (a function) vs `x = y²` (not). Bridge to purity: "A pure function returns the same result for the same argument, every time — the basis of F1.02."
3. **Functions are values** (`#first-class`) — first-class functions, `fn` / `&`, higher-order. Real Elixir shown (built by JS): `f = fn x -> x + 1 end`, `f.(x)`, and `apply_twice = fn g, x -> g.(g.(x)) end`.

Synthesis "What this lands" closes the arc and forwards to F1.02.

## The interactives

Three interactive figures plus the footer build-stamp decoder.

### Figure — "The mapping · choose a function" (`#mapTitle`)

- Control group `#mapSel` (`role="group"`, `aria-label="Choose a function"`), four buttons: `data-fn="square" data-c="gold"` label "x²" (starts `active`); `data-fn="double" data-c="blue"` label "2x"; `data-fn="negate" data-c="sage"` label "−x"; `data-fn="const" data-c="elixir"` label "→ 1".
- SVG (`viewBox="0 0 720 340"`): domain circles, codomain circles with ids `#r4 #r2 #r1 #r0 #rn1 #rn2 #rn4`, arrow group `#mapArrows`. Code block `#mapCode`, readout `#mapOut`.
- Pure function: `renderMap()` reads the active `data-fn` from `MAP_FNS` (`square &(&1 * &1)`, `double &(&1 * 2)`, `negate &(-&1)`, `const fn _ -> 1 end`) over `DOMAIN = [-2,-1,0,1,2]`; redraws arrows by `LEFT_Y`/`VAL_Y`, recolours hit codomain dots, rewrites `#mapCode`, and computes the deduped sorted range. Initial call `renderMap()`.
- Readout `#mapOut` (verbatim default): `domain {-2, -1, 0, 1, 2} · range {0, 1, 4}`.

### Figure — "The vertical line test · count the outputs" (`#vlTitle`)

- Control group `#vlSel` (`role="group"`, `aria-label="Choose a relation"`), two buttons: `data-rel="fn" data-c="sage"` label "y = x²" (starts `active`); `data-rel="rel" data-c="elixir"` label "x = y²". Plus a `.fold-ctrl` slider `#vlX` (min −2, max 2, step 0.1, value 1) with value `#vlXval`.
- SVG (`viewBox="0 0 560 380"`): curves `#curveFn` / `#curveRel`, movable `#vline`, intersection dots `#dotA` / `#dotB`. Readout `#vlOut`.
- Pure function: `renderVL()` reads the slider and active relation; `sx(x)=280+40x`, `sy(y)=190-40y`; for `fn` plots one dot at `(x, x²)`, for `rel` plots `±√x` (two dots when x>0, one at the vertex when x=0, none when x<0). Initial call `renderVL()`.
- Readout `#vlOut` (verbatim default): `x = 1.0 → output {1.00} · 1 value · a function`. (When the relation fails: `x = … → outputs {+…, −…} · 2 values · not a function`.)

### Figure — "First-class · store, pass, apply" (`#fcTitle`)

- Control group `#fcSel` (function: `data-fn="inc" data-c="sage"` "increment" active; `data-fn="square" data-c="gold"` "square"; `data-fn="double" data-c="blue"` "double"); control group `#fcMode` (`data-mode="once" data-c="elixir"` "apply once" active; `data-mode="twice" data-c="elixir"` "apply twice"); `.fold-ctrl` slider `#fcX` (min 0, max 9, step 1, value 3) with `#fcXval`.
- SVG (`viewBox="0 0 720 150"`): function-machine with `#fmIn`, `#fmLabel`, `#fmBadge`, `#fmOut`. Code block `#fcCode`, readout `#fcOut` (both empty in static markup, filled by JS).
- Pure function: `renderFC()` reads `FC_FNS` (`inc fn x -> x + 1 end`, `square fn x -> x * x end`, `double fn x -> x * 2 end`), applies once or twice, updates the machine text, and writes `#fcCode` (the `f = …`, `apply_twice = fn g, x -> g.(g.(x)) end`, and call lines) and `#fcOut`. Initial call `renderFC()`.
- Readout `#fcOut` (built by JS; once form): `f = <name> · x = <x> · f.(<x>) = <result>`; twice form: `f = <name> · x = <x> · f.(f.(<x>)) = f.(<once>) = <result>`.

### Degrade behaviour

Controls, SVGs, and the `#mapping` default code/readout render in static markup; the first-class figure's `#fcCode`/`#fcOut` are empty until JS runs `renderFC()`. The page respects `prefers-reduced-motion` globally (reveal transitions and `.arc-flow` animation disabled); no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0NZFJOg3mIS` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-30 09:46:06 UTC" (the decoded UTC timestamp).
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (splits `ns = id.slice(0,3)` / `snow = b62decode(id.slice(3))`; `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`; `EPOCH_MS = 1704067200000`; fills `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`). Toggle on click / Enter / Space.

## References (#refs, verbatim)

No `#refs` References section is present on this page. The lesson's cross-links are the crumbs, the toc-mini, the `.note`, the pager, and the footer (see Wiring); it forwards to F1.02 (substitution), and the bridges name F1.02, F1.03, F1.07, and F2 in prose.

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/algebra">algebra</a><span class="rsep">/</span><span class="rcur">functions</span>` (`elixir` and `algebra` are links; `functions` is current).
- **crumbs:** `F1 · Algebra` → `/elixir/algebra` · sep `/` · here `F1.01` (no link).
- **toc-mini:** `#mapping` ("A mapping") · `#one-output` ("Exactly one output") · `#first-class` ("Functions are values").
- **pager:** prev → `/elixir/algebra` ("← F1 · Algebra"); next → `/elixir/algebra/substitution` ("Next · F1.02 substitution →").
- **footer:** identical three-column footer to the chapter landing — brand → `/elixir`; `Chapters` column F1–F6 (`/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`); `The course` column `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- **Page meta:** `<title>` "What a function really is — F1.01 · jonnify"; `<meta description>` "A function as a mapping: domain, codomain, and range; the single-output rule; and the first-class function as an ordinary Elixir value."

## Build instruction

To (re)build this lesson, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built gold-accent sibling — the model is `elixir/algebra/substitution.html` (F1.02, the closest lesson-template sibling with crumbs, toc-mini, three figures, and the stepper/classifier patterns) — then change only `<title>`/`<meta>`, the route-tag, the crumbs, and the `<main>` body (hero → three teaching sections, each figure + `.bridge` + `.take` → synthesis → pager). No-invent guards: use only the real Portal surfaces as written (branded store, event-sourced engine behind one `Portal` facade, Phoenix web app); this lesson is pure algebra and names no engine internals — cite the companion course for OTP internals, do not re-teach. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously.
