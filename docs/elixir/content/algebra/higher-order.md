# F1.07 — Higher-order operators (Σ, Π) (dive / lesson)

- **Route (served):** `/elixir/algebra/higher-order`
- **File:** `elixir/algebra/higher-order.html`
- **Place in the chapter:** the seventh lesson of F1 · Algebra, opening "The operators" movement. It follows `F1.06` (recursion) and captures that recursion once and for all as named higher-order operations — Σ and Π as operators over a function, then map / filter / reduce, ending on `reduce` as the general fold. It precedes `F1.08` (pattern matching).
- **Accent:** gold chapter accent (gold/elixir token palette).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F1 · Algebra`

`h1`: `Higher-order operators (Σ, Π)` (the `(Σ, Π)` rendered as a `.math` span).

Hero lede (verbatim): "The summation and product signs are functions in disguise: each takes another function and a range and folds them into one value. The same idea, generalised, is map, filter, and reduce."

Kicker (verbatim): "F1.01 made functions into values; a **higher-order** operation is one that takes a function as an argument. Mathematics has had these for centuries in Σ and Π. We start there, meet the three everyday operators that capture the recursion of F1.06 once and for all, and end on reduce — the one the others are special cases of."

## Sections

Three teaching sections, each closing with a `.bridge` and a `.take`:

1. **Sigma and Pi** (`#sigma-pi`) — Σ and Π as operators that take a function over a range. Real Elixir shown: `Enum.reduce(1..n, 0, fn i, acc -> acc + f.(i) end)`.
2. **Map, filter, reduce** (`#trio`) — the everyday trio and how each reshapes a collection. Real Elixir shown: `Enum.map/2`, `Enum.filter/2`, `Enum.reduce/3`.
3. **Reduce is the general one** (`#fold`) — `reduce` as the fold the others are instances of. Real Elixir shown: `Enum.reduce(list, acc0, fn x, acc -> combine end)`.

Synthesis "What this lands" closes the arc and forwards to F1.08.

## The interactives

Three interactive figures plus the footer build-stamp decoder.

### Figure — "Σ and Π · an operator over a function" (`#spTitle`)

- Control group `#spOp` ("Operator"), two buttons: `data-op="sum" data-c="gold"` "Σ sum" (active); `data-op="prod" data-c="blue"` "Π product". Control group `#spF` ("Function"), three buttons: `data-fn="id" data-c="sage"` "f(i) = i"; `data-fn="sq" data-c="sage"` "f(i) = i²" (active); `data-fn="dbl" data-c="sage"` "f(i) = 2i". `.fold-ctrl` slider `#spN` (n; min 1, max 6, step 1, value 4) with its value box.
- Readout `#spOut` (verbatim default): `Σ i² for i = 1..4 · 1 + 4 + 9 + 16 = 30`.

### Figure — "One list · three shapes" (`#trioTitle`)

- Control group `#trioSel` ("Operation"), three buttons: `data-op="map" data-c="sage"` "map · ×2" (active); `data-op="filter" data-c="blue"` "filter · even"; `data-op="reduce" data-c="gold"` "reduce · +".
- Readout `#trioOut2` (verbatim default): `Enum.map(list, &(&1 * 2)) → [2, 4, 6, 8, 10, 12] · length preserved, 6 → 6`.

### Figure — "reduce([1, 2, 3, 4]) · the accumulator" (`#foldTitle`)

- Control group `#foldSel` ("Combining function"), three buttons: `data-c2="sum" data-c="gold"` "+ from 0 · Σ" (active); `data-c2="prod" data-c="blue"` "× from 1 · Π"; `data-c2="collect" data-c="sage"` "build a list". `.fold-ctrl` slider `#foldStep` (step; min 0, max 4, step 1, value 4) with its value box.
- Readout `#foldOut` (verbatim default): `done · reduce with + from 0 = 10 · this is Σ`.

### Degrade behaviour

Controls, SVGs, and the default readouts render in static markup; the code blocks are filled by JS on init. The page respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0NZQEZI7GRk` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-30 12:18:56 UTC" (the decoded UTC timestamp).
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`; `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`; `EPOCH_MS = 1704067200000`). Toggle on click / Enter / Space.

## References (#refs, verbatim)

No `#refs` References section is present on this page. The lesson's cross-links are the crumbs, toc-mini, `.note`, pager, and footer (see Wiring); the prose names F1.01 (functions as values) and F1.06 (recursion).

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/algebra">algebra</a><span class="rsep">/</span><span class="rcur">higher-order</span>`.
- **crumbs:** `F1 · Algebra` → `/elixir/algebra` · sep `/` · `F1.06` → `/elixir/algebra/recursion` · sep `/` · here `F1.07` (no link).
- **toc-mini:** `#sigma-pi` ("Sigma and Pi") · `#trio` ("Map, filter, reduce") · `#fold` ("Reduce is the general one").
- **pager:** prev → `/elixir/algebra/recursion` ("← F1.06 · recursion"); next → `/elixir/algebra` ("More in F1 · Algebra →"). (The synthesis `.note` names F1.08 as "(planned)".)
- **footer:** identical three-column footer — brand → `/elixir`; `Chapters` F1–F6; `The course` `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- **Page meta:** `<title>` "Higher-order operators (Σ, Π) — F1.07 · jonnify"; `<meta description>` "Σ and Π as operators over a function, the map / filter / reduce trio and how each reshapes a collection, and reduce as the general fold the others are instances of."

## Build instruction

To (re)build this lesson, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built gold-accent sibling — the model is `elixir/algebra/recursion.html` (F1.06, the same lesson template: crumbs, toc-mini, three figures, two-group `.solid-select` selectors plus a `.fold-ctrl`, `.bridge`/`.take` rhythm) — then change only `<title>`/`<meta>`, the route-tag, the crumbs, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written (branded store, event-sourced engine behind one `Portal` facade, Phoenix web app); this lesson is pure algebra over `Enum.map`/`Enum.filter`/`Enum.reduce` and names no engine internals — cite the companion course for OTP internals, do not re-teach. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously.
