# F1.08 — Equations & pattern matching (dive / lesson)

- **Route (served):** `/elixir/algebra/pattern-matching`
- **File:** `elixir/algebra/pattern-matching.html`
- **Place in the chapter:** the eighth lesson of F1 · Algebra, closing "The operators" movement. It follows `F1.07` (higher-order operators) and turns the match operator of `F1.04` into solving by structure — destructuring, dispatch by shape, and guards. It precedes `F1.09` (the plotting lab).
- **Accent:** gold chapter accent (gold/elixir token palette).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F1 · Algebra`

`h1`: `Equations & pattern matching`

Hero lede (verbatim): "Some equations hold for every value; others you solve for the few that fit. Pattern matching is the second kind made structural — given a shape, find the bindings that make both sides agree."

Kicker (verbatim): "An identity like (a+b)² = a² + 2ab + b² is true for all a and b; a conditional equation like x + 3 = 5 is solved by finding x. Elixir’s match operator solves by structure: it lines a pattern up against a value, binds the variables, and routes control to the clause whose shape fits. We pull a structure apart, dispatch on shape, and refine with guards."

## Sections

Three teaching sections, each closing with a `.bridge` and a `.take`:

1. **Destructuring** (`#destructure`) — a pattern picks out the parts of a value; `{a, b} = pair`, `[h | t] = list`, `%{key: v} = map`.
2. **Dispatch by shape** (`#dispatch`) — `case` and the first matching clause wins; `{:ok, _}` vs `{:error, _}` vs list shapes.
3. **Guards** (`#guards`) — `when` refines a match by value; `def sign(n) when n > 0, do: :positive`.

Synthesis "What this lands" closes the arc and forwards to F1.09.

## The interactives

Three interactive figures plus the footer build-stamp decoder.

### Figure — "Destructuring · a pattern picks out the parts" (`#dTitle`)

- Control group `#destrSel` ("Choose a pattern"), four buttons: `data-p="tuple" data-c="gold"` "{a, b, c}" (active); `data-p="list" data-c="blue"` "[head | tail]"; `data-p="map" data-c="sage"` "%{x: px, y: py}"; `data-p="ok" data-c="elixir"` "{:ok, value}".
- Readout `#destrOut` (verbatim default): `binds · a = 1 · b = 2 · c = 3`.

### Figure — "case · the first matching clause wins" (`#dispTitle`)

- Control group `#dispSel` ("Choose an input"), four buttons: `data-i="ok" data-c="sage"` "{:ok, 42}" (active); `data-i="err" data-c="elixir"` "{:error, \"bad\"}"; `data-i="empty" data-c="blue"` "[]"; `data-i="list" data-c="gold"` "[1, 2, 3]".
- Readout `#dispOut` (verbatim default): `{:ok, 42} · clause 1 matches · → "ok: 42"`.

### Figure — "when · a condition on the match" (`#gTitle`)

- Controls: a single `.fold-ctrl` slider `#gN` (n; min −5, max 5, step 1, value 3). No `.solid-select`.
- Readout `#gOut` (verbatim default): `n = 3 · n > 0 holds · → :positive`.

### Degrade behaviour

Controls, SVGs, and the default readouts render in static markup; the code blocks are filled by JS on init. The page respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0NZREMiYalU` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-30 12:32:53 UTC" (the decoded UTC timestamp).
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`; `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`; `EPOCH_MS = 1704067200000`). Toggle on click / Enter / Space.

## References (#refs, verbatim)

No `#refs` References section is present on this page. The lesson's cross-links are the crumbs, toc-mini, `.note`, pager, and footer (see Wiring); the prose names F1.04 (the match operator).

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/algebra">algebra</a><span class="rsep">/</span><span class="rcur">pattern-matching</span>`.
- **crumbs:** `F1 · Algebra` → `/elixir/algebra` · sep `/` · `F1.07` → `/elixir/algebra/higher-order` · sep `/` · here `F1.08` (no link).
- **toc-mini:** `#destructure` ("Destructuring") · `#dispatch` ("Dispatch by shape") · `#guards` ("Guards").
- **pager:** prev → `/elixir/algebra/higher-order` ("← F1.07 · higher-order"); next → `/elixir/algebra` ("More in F1 · Algebra →"). (The synthesis `.note` names F1.09 — "Functions on the plane" — as "(planned)".)
- **footer:** identical three-column footer — brand → `/elixir`; `Chapters` F1–F6; `The course` `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- **Page meta:** `<title>` "Equations & pattern matching — F1.08 · jonnify"; `<meta description>` "Solving by structure: destructuring tuples, lists and maps, dispatching control by shape, and guards that refine a match by value."

## Build instruction

To (re)build this lesson, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built gold-accent sibling — the model is `elixir/algebra/higher-order.html` (F1.07, the same lesson template: crumbs, toc-mini, three figures, multi-button `.solid-select` selectors plus a `.fold-ctrl`, `.bridge`/`.take` rhythm) — then change only `<title>`/`<meta>`, the route-tag, the crumbs, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written (branded store, event-sourced engine behind one `Portal` facade, Phoenix web app); this lesson is pure Elixir pattern matching (`case`, `when`, destructuring) and names no engine internals — cite the companion course for OTP internals, do not re-teach. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously.
