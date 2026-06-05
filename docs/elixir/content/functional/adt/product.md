# F2.07.1 — Product types (dive)

- Route (served): `/elixir/functional/adt/product`
- File: `elixir/functional/adt/product.html`
- Place in the chapter: Part 1 of 3 in the F2.07 algebraic-data-types triad. It opens the teaching arc — products before sums before matching — establishing how tuples and structs bundle fields and why a product's inhabitants multiply.
- Accent: elixir (purple) — `--elixir:#b39ddb`, `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F2.07 · part 1 of 3`

H1: `Product types`

Lede (verbatim):
> A product type holds several values at once. A tuple bundles them by position; a struct bundles them by name. Either way every field is present together, and because each field varies independently, the number of distinct values is the product of the fields' counts.

Kicker (verbatim):
> Tuples are quick and anonymous: `{1, 2}` is two values with no labels. Structs add names and a type: `%Point{x: 1, y: 2}` says these two numbers are a point. Both are immutable, so "changing" a field means building a new value with that field replaced.

## Sections

1. **Tuple or struct** (`#shapes`) — teaching section. The same pair of values as a positional tuple (`elem/2`) or a named struct (the dot). Deflist: `product type`, `tuple` (`{1, 2}`, read with `elem/2`), `struct` (`%Point{x: 1, y: 2}`), `field`. Running example: `{1, 2}` ↔ `%Point{x: 1, y: 2}`. Take: `Tuples index by position, structs by name. Reach for a struct when the fields deserve names and a type.`
2. **Updating a field** (`#update`) — immutable update. `%{point | x: new}` builds a new struct sharing untouched fields; the original is intact. Running example: `point = %Point{x: 1, y: 2}` → `moved = %{point | x: 7}`. Take: `Updating a struct builds a new one with the change applied; the original is untouched.`
3. **Worked examples** (`#gallery`) — gallery of four real Elixir snippets (tuple / defstruct / update / nested).

Real Elixir code shown (gallery `GAL`, verbatim semantics):
- `tuple`: `p = {3, 4}` then `elem(p, 0)   # => 3` — note "two values by position, read with elem/2".
- `def`: `defmodule Point do` / `defstruct x: 0, y: 0` / `end`, then `%Point{x: 1, y: 2}   # => %Point{x: 1, y: 2}` — note "defstruct names the fields and gives defaults".
- `update`: `p = %Point{x: 1, y: 2}` then `%{p | y: 9}   # => %Point{x: 1, y: 9}` — note "replace one field, build a new struct".
- `nested`: `line = %Line{from: %Point{x: 0, y: 0}, to: %Point{x: 3, y: 4}}` then `line.to.x   # => 3` — note "a product whose fields are themselves products".

## The interactives

### Section 1 figure — `same data · positional or named`  (`#shapes`)
- `<figure class="fig">` labelled by `#shTitle`. Control group `#shSel`: button `data-k="tuple"` `data-c="blue"` (active) label `tuple`; button `data-k="struct"` `data-c="gold"` label `struct`.
- SVG ids: `#shValue`, `#shL0`/`#shB0`/`#shV0`, `#shL1`/`#shB1`/`#shV1`, `#shRead`. Code `#shCode`.
- Pure function: `renderSh()` reads `shKey()` and swaps the displayed value, field labels, and read expression between tuple and struct encodings.
- Readout `#shOut`, verbatim default: `tuple · fields by position · elem(t, 0) reads the first`. Struct branch readout (verbatim): `struct · fields by name · point.x reads the x field`.

### Section 2 figure — `%{point | x: new} · a new struct, original intact`  (`#update`)
- `<figure class="fig">` labelled by `#upTitle`. Control: range `#upX` (`new x`, 0–9, default 7), value span `#upXval`. SVG: original point drawn statically, new point text `#upNew`. Code `#upCode`.
- Pure function: `renderUp()` reads `x` and updates `#upNew` to `x: <x>, y: 2`, the code block, and the readout.
- Readout `#upOut`, verbatim default: `moved has x = 7 · point is still x = 1, y = 2`.

### Section 3 — gallery (`#gallery`)
- Control group `#gSel`: `data-g="tuple"` `data-c="blue"` (active) label `tuple`; `data-g="def"` `data-c="gold"` label `defstruct`; `data-g="update"` `data-c="sage"` label `update`; `data-g="nested"` `data-c="elixir"` label `nested`. Code `#gCode`. Pure function `renderG()` reads `gKey()` and writes the snippet + note.
- Readout `#gOut`, verbatim default: `tuple · two values by position, read with elem/2`.

### Degrade behaviour
Every figure carries a static default in the markup (the tuple encoding, `x: 7, y: 2` moved struct, the tuple gallery snippet) before JS runs. The `.arc-flow` animation and `scroll-behavior` are gated by `prefers-reduced-motion`; the reveal-on-scroll script adds `.in` immediately under reduced motion or when `IntersectionObserver` is missing.

### Footer build-stamp
`#stampId` text = `TSK0NaskvqxGfA`. Decoded: namespace `TSK`, snowflake `319406067366756352`, node `0`, seq `0`, timestamp `2026-05-31 09:25:40 UTC` (matches the hard-coded `#st-ts`).

## References (#refs, verbatim)

This page has no `References` (`#refs`) section. There is no Sources block and no "Related in this course" block; cross-links are inline only (the bridge cell cites `F1.04 · immutability`, and the pager links the hub and the next dive).

## Wiring

- route-tag (verbatim): `/ elixir / functional / adt / product` — `elixir` → `/elixir`, `functional` → `/elixir/functional`, `adt` → `/elixir/functional/adt`, current segment `product` (`.rcur`).
- crumbs (verbatim): `F2` (`/elixir/functional`) / `F2.07` (`/elixir/functional/adt`) / `product` (`.here`).
- toc-mini: `#shapes` → `Tuple or struct`; `#update` → `Updating a field`; `#gallery` → `Worked examples`.
- pager: prev → `/elixir/functional/adt` label `F2.07 · hub`; next → `/elixir/functional/adt/sum` label `Part 2 · sum types`.
- footer: column **Chapters** — `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. Column **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta: `<title>` = `Product types — F2.07.1 · jonnify`; `<meta description>` = `Tuples and structs: bundling fields by position or by name, immutable struct update, and why a product type's inhabitants multiply.`

## Build instruction

To rebuild this page, copy the `head…</style>`, `header`, `footer`, and trailing reveal/decoder `<script>` blocks verbatim from a recent BUILT sibling on the F2 elixir-purple accent — the model sibling is its triad neighbour `elixir/functional/adt/sum.html` (same dive shell: upright `.hero-copy .lede`, three `.fig` sections, `solid-select`/`fold-ctrl` controls, the gallery `GAL` pattern, and identical stamp/reveal scripts). Change only `<title>`/`<meta>`, the route-tag (`elixir / functional / adt / product`), the crumbs, the toc-mini anchors, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind one Portal facade, and the Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them; do not invent routes, ids, readout strings, or code tokens. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
