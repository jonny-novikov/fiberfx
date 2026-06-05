# F2.07.2 — Sum types (dive)

- Route (served): `/elixir/functional/adt/sum`
- File: `elixir/functional/adt/sum.html`
- Place in the chapter: Part 2 of 3 in the F2.07 algebraic-data-types triad, between product types and pattern matching. It teaches sums as tagged tuples — one variant at a time — and why a sum's inhabitants add.
- Accent: elixir (purple) — `--elixir:#b39ddb`, `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F2.07 · part 2 of 3`

H1: `Sum types`

Lede (verbatim):
> A sum type is one of several variants — one at a time, never together. Elixir spells it with tagged tuples: an atom in the first position names the variant, and the rest carries that variant's data. The number of values a sum can hold is the sum of its variants'.

Kicker (verbatim):
> The tag is what makes the variants distinguishable. `{:circle, r}` and `{:rectangle, w, h}` are both tuples, but the leading `:circle` or `:rectangle` tells them apart at a glance and in a pattern match. The most common sum of all is `{:ok, value}` or `{:error, reason}`.

## Sections

1. **One of several shapes** (`#variants`) — teaching section. A shape is a circle, rectangle, or triangle; the tag selects which. Deflist: `sum type`, `variant`, `tag` (the leading atom naming the variant), `discriminate` (tell variants apart — by their tags). Running example: `{:circle, 5}` / `{:rectangle, w, h}` / `{:triangle, b, h}` with area formulas. Take: `A sum type lets one value be any of several shapes. The tag is how code knows which it has.`
2. **Why they add** (`#count`) — counting. Because a value is exactly one variant, totals add rather than multiply; a nullary variant like `:pending` contributes exactly one. Running example: `{:ok, a} | {:error, b}`. Take: `Variants add because only one holds at a time. Counting a sum is adding its variants' values.`
3. **Worked examples** (`#gallery`) — gallery of four real Elixir snippets (result / atom enum / shapes / option).

Real Elixir code shown (gallery `GAL`, verbatim semantics):
- `result`: `# success or failure` / `{:ok, value} | {:error, reason}` then a `case File.read("x.txt") do` with `{:ok, data} -> data` / `{:error, _} -> ""` / `end` — note "success carries a value, failure carries a reason".
- `enum`: `# a closed set of atoms, each a nullary variant` / `:red | :green | :blue` / `# 1 + 1 + 1 = 3 values` — note "three tags, no fields; three values total".
- `shape`: `{:circle, r}` / `| {:rectangle, w, h}` / `| {:triangle, b, h}` — note "variants carrying different numbers of fields".
- `option`: `# a value that may be absent` / `{:some, value} | :none` then `case lookup do` with `{:some, v} -> v` / `:none -> default` / `end` — note "present-with-a-value, or absent".

## The interactives

### Section 1 figure — `a shape · the tag picks the variant`  (`#variants`)
- `<figure class="fig">` labelled by `#vTitle`. Control group `#vSel`: button `data-k="circle"` `data-c="sage"` (active) label `{:circle, r}`; `data-k="rect"` `data-c="gold"` label `{:rectangle, w, h}`; `data-k="tri"` `data-c="blue"` label `{:triangle, b, h}`.
- SVG ids: `#vValue`, `#vTag`, `#vArea`, drawn-shape group `#vShape`. Code `#vCode`.
- Pure function: per the active key, sets the tagged value, the tag, and the area formula/result, and draws the shape.
- Readout `#vOut`, verbatim default: `{:circle, 5} · tag :circle selects the circle clause · area 78.54`.

### Section 2 figure — `{:ok, a} | {:error, b} · totals add`  (`#count`)
- `<figure class="fig">` labelled by `#cTitle`. Controls: range `#cA` (`values in :ok`, 1–4, default 2), `#cB` (`values in :error`, 1–4, default 3); spans `#cAval`/`#cBval`. SVG groups `#cGroupA` (`{:ok, a}`, sage) / `#cGroupB` (`{:error, b}`, burgundy). Code `#cCode`.
- Pure function: computes the total as a sum (`a + b`) and draws two disjoint variant groups.
- Readout `#cOut`, verbatim default: `2 in :ok + 3 in :error = 5 possible values`.

### Section 3 — gallery (`#gallery`)
- Control group `#gSel`: `data-g="result"` `data-c="sage"` (active) label `result`; `data-g="enum"` `data-c="gold"` label `atom enum`; `data-g="shape"` `data-c="blue"` label `shapes`; `data-g="option"` `data-c="elixir"` label `option`. Code `#gCode`. The labels map (`labels`) is `result: 'result', enum: 'atom enum', shape: 'shapes', option: 'option'`.
- Readout `#gOut`, verbatim default: `result · success carries a value, failure carries a reason`.

### Degrade behaviour
Each figure renders a static default in the markup (`{:circle, 5}` with its area, the `2 + 3 = 5` count, the `result` gallery snippet) before JS runs. The `.arc-flow` animation and `scroll-behavior` are gated by `prefers-reduced-motion`; the reveal-on-scroll script adds `.in` immediately under reduced motion or when `IntersectionObserver` is absent.

### Footer build-stamp
`#stampId` text = `TSK0Naskw3jDW4`. Decoded: namespace `TSK`, snowflake `319406067555500032`, node `0`, seq `0`, timestamp `2026-05-31 09:25:40 UTC` (matches the hard-coded `#st-ts`).

## References (#refs, verbatim)

This page has no `References` (`#refs`) section. There is no Sources block and no "Related in this course" block; cross-links are inline only (the bridge cell cites `F2.07.3 · matching`, and the pager links the previous and next dives).

## Wiring

- route-tag (verbatim): `/ elixir / functional / adt / sum` — `elixir` → `/elixir`, `functional` → `/elixir/functional`, `adt` → `/elixir/functional/adt`, current segment `sum` (`.rcur`).
- crumbs (verbatim): `F2` (`/elixir/functional`) / `F2.07` (`/elixir/functional/adt`) / `sum` (`.here`).
- toc-mini: `#variants` → `One of several shapes`; `#count` → `Why they add`; `#gallery` → `Worked examples`.
- pager: prev → `/elixir/functional/adt/product` label `Part 1 · product types`; next → `/elixir/functional/adt/matching` label `Part 3 · matching`.
- footer: column **Chapters** — `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`. Column **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta: `<title>` = `Sum types — F2.07.2 · jonnify`; `<meta description>` = `Tagged tuples and variants: a value is one shape or another, the atom tag discriminates, and the inhabitants add — including the {:ok, _} | {:error, _} idiom.`

## Build instruction

To rebuild this page, copy the `head…</style>`, `header`, `footer`, and trailing reveal/decoder `<script>` blocks verbatim from a recent BUILT sibling on the F2 elixir-purple accent — the model sibling is its triad neighbour `elixir/functional/adt/product.html` (identical dive shell: upright `.hero-copy .lede`, three `.fig` sections, `solid-select`/`fold-ctrl` controls, the gallery `GAL` pattern, and the same stamp/reveal scripts). Change only `<title>`/`<meta>`, the route-tag (`elixir / functional / adt / sum`), the crumbs, the toc-mini anchors, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind one Portal facade, and the Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them; do not invent routes, ids, readout strings, or code tokens. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
