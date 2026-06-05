# F2.07.3 — Pattern matching on data (dive)

- Route (served): `/elixir/functional/adt/matching`
- File: `elixir/functional/adt/matching.html`
- Place in the chapter: Part 3 of 3 in the F2.07 algebraic-data-types triad, and its closer. Having built products and sums, this dive shows how pattern matching takes both apart — destructuring products and dispatching on sum variants — then hands off to `F2.08` (composition & pipelines).
- Accent: elixir (purple) — `--elixir:#b39ddb`, `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F2.07 · part 3 of 3`

H1: `Pattern matching on data`

Lede (verbatim):
> Pattern matching is how algebraic data is taken apart. A pattern mirrors the shape of a value: match it and the names inside bind to the matching pieces. For a sum, a clause per variant dispatches on the tag; for a product, the pattern reaches in and pulls out fields.

Kicker (verbatim):
> It is the same matching seen in F1.08, now aimed at the data of this module. Destructuring handles products — `{:ok, v}` binds `v`. Dispatch handles sums — a function head per tag, each handling one variant. Together they make consuming an algebraic value as structured as building it.

## Sections

1. **Destructuring** (`#destructure`) — teaching section. A pattern on the left of `=` binds names to the parts of the value on the right. Deflist: `destructuring`, `clause`, `dispatch`, `guard` (a `when` condition that further restricts a clause). Running example: `{:ok, v} = {:ok, 42}`. Take: `Destructuring reads a value's parts by mirroring its shape. The names on the left bind to the pieces on the right.`
2. **Dispatch on the tag** (`#dispatch`) — function-head dispatch. Define a function once per variant and the tag chooses the clause; `area/1` has a head per shape. Running example: `{:circle, 5}` / `{:rectangle, 3, 4}` / `{:triangle, 6, 4}`. Take: `Dispatch is matching at the function head: one clause per tag, each binding that variant's fields.`
3. **Worked examples** (`#gallery`) — gallery of four real Elixir snippets (case / heads / guard / nested).

A closing section **Where this goes** (`#close`) summarises the whole module and points to `F2.08`.

Real Elixir code shown (gallery `GAL`, verbatim semantics):
- `case`: `case result do` / `{:ok, v} -> v` / `{:error, _} -> nil` / `end` — note "one clause per result variant".
- `heads`: `def greet({:user, name}), do: "Hi #{name}"` / `def greet(:guest), do: "Hi there"` — note "one function head per variant".
- `guard`: `case n do` / `x when x > 0 -> :positive` / `0 -> :zero` / `_ -> :negative` / `end` — note "a when guard refines which clause matches".
- `nested`: `line = %Line{from: %Point{x: 0, y: 0}, to: %Point{x: 3, y: 4}}` / `%Line{to: %Point{x: x1}} = line` / `x1   # => 3` — note "reach into a nested product in one pattern".

## The interactives

### Section 1 figure — `pattern = value · names bind to parts`  (`#destructure`)
- `<figure class="fig">` labelled by `#dTitle`. Control group `#dSel`: button `data-k="ok"` `data-c="sage"` (active) label `{:ok, v}`; `data-k="point"` `data-c="gold"` label `%Point{x: x, y: y}`; `data-k="list"` `data-c="blue"` label `[head | tail]`; `data-k="pair"` `data-c="elixir"` label `{a, b}`.
- SVG ids: pattern `#dPat`, value `#dVal`, binds group `#dBinds`. Code `#dCode`.
- Pure function: per the active key, sets the pattern, the value, the bound names, code, and readout.
- Readout `#dOut`, verbatim default: `{:ok, v} = {:ok, 42} · binds v = 42`.

### Section 2 figure — `def area(shape) · one head per variant`  (`#dispatch`)
- `<figure class="fig">` labelled by `#diTitle`. Control group `#diSel`: button `data-k="circle"` `data-c="sage"` (active) label `{:circle, 5}`; `data-k="rect"` `data-c="gold"` label `{:rectangle, 3, 4}`; `data-k="tri"` `data-c="blue"` label `{:triangle, 6, 4}`.
- SVG head rows `#diC0`/`#diT0`, `#diC1`/`#diT1`, `#diC2`/`#diT2`. The three static heads: `def area({:circle, r}), do: 3.14159 * r * r`; `def area({:rectangle, w, h}), do: w * h`; `def area({:triangle, b, h}), do: b * h / 2`. Code `#diCode`.
- Pure function: highlights the matching head for the chosen shape and renders the bind + result.
- Readout `#diOut`, verbatim default: `{:circle, 5} · matches head 1, binds r = 5 · 78.54`.

### Section 3 — gallery (`#gallery`)
- Control group `#gSel`: `data-g="case"` `data-c="sage"` (active) label `case`; `data-g="heads"` `data-c="gold"` label `heads`; `data-g="guard"` `data-c="blue"` label `guard`; `data-g="nested"` `data-c="elixir"` label `nested`. Code `#gCode`.
- Readout `#gOut`, verbatim default: `case · one clause per result variant`.

### Degrade behaviour
Each figure renders a static default in the markup (`{:ok, v} = {:ok, 42}`, the `{:circle, 5}` matched head, the `case` gallery snippet) before JS runs. The `.arc-flow` animation and `scroll-behavior` are gated by `prefers-reduced-motion`; the reveal-on-scroll script adds `.in` immediately under reduced motion or when `IntersectionObserver` is missing.

### Footer build-stamp
`#stampId` text = `TSK0NaskwFvy6q`. Decoded: namespace `TSK`, snowflake `319406067735855104`, node `0`, seq `0`, timestamp `2026-05-31 09:25:40 UTC` (matches the hard-coded `#st-ts`).

## References (#refs, verbatim)

This page has no `References` (`#refs`) section. There is no Sources block and no "Related in this course" block; cross-links are inline only (the kicker cites `F1.08`, and the close note links the `F2.07` hub and the `F2` overview).

## Wiring

- route-tag (verbatim): `/ elixir / functional / adt / matching` — `elixir` → `/elixir`, `functional` → `/elixir/functional`, `adt` → `/elixir/functional/adt`, current segment `matching` (`.rcur`).
- crumbs (verbatim): `F2` (`/elixir/functional`) / `F2.07` (`/elixir/functional/adt`) / `matching` (`.here`).
- toc-mini: `#destructure` → `Destructuring`; `#dispatch` → `Dispatch on the tag`; `#gallery` → `Worked examples`.
- pager: prev → `/elixir/functional/adt/sum` label `Part 2 · sum types`; next → `/elixir/functional/composition` label `F2.08 · Composition & pipelines`.
- footer: column **Chapters** — `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. Column **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta: `<title>` = `Pattern matching on data — F2.07.3 · jonnify`; `<meta description>` = `Taking algebraic data apart: destructuring products to bind fields, and dispatching on sum variants with case and function heads.`

## Build instruction

To rebuild this page, copy the `head…</style>`, `header`, `footer`, and trailing reveal/decoder `<script>` blocks verbatim from a recent BUILT sibling on the F2 elixir-purple accent — the model sibling is its triad neighbour `elixir/functional/adt/sum.html` (identical dive shell: upright `.hero-copy .lede`, two teaching `.fig` sections plus a gallery, `solid-select` controls, the gallery `GAL` pattern, the `.note` close, and the same stamp/reveal scripts). Change only `<title>`/`<meta>`, the route-tag (`elixir / functional / adt / matching`), the crumbs, the toc-mini anchors, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind one Portal facade, and the Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them; do not invent routes, ids, readout strings, or code tokens. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
