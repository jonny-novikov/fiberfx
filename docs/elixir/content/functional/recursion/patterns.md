# F2.04.3 — Recursion patterns (dive)

- Route (served): `/elixir/functional/recursion/patterns`
- File: `elixir/functional/recursion/patterns.html`
- Place in the chapter: the third and final F2.04 dive (`part 3 of 3`), under the `/elixir/functional/recursion` hub. It closes the recursion arc by showing that the recursions that recur — sum, length, reverse, map, filter — are all one fold, then hands off to F2.05 (`folds`), which makes `reduce` the subject.
- Accent: elixir (purple) — `--elixir:#b39ddb` / `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F2.04 · part 3 of 3`

H1 (verbatim): `Recursion patterns`

Hero lede (verbatim):

> Write a few recursions over lists and the same shapes keep appearing. Sum, length, reverse, map, and filter all walk the list the same way — and all of them are one idea wearing different clothes: a fold.

Kicker line (verbatim):

> Each pattern peels the head, does something with it, and recurses on the tail. The only thing that changes is what it does with the head and how it starts. That is exactly what `Enum.reduce` abstracts: a starting value and a function that folds each element into an accumulator. F1.07 named this; here every recursion on this page collapses into one. Pick a pattern and see its recursive form beside its fold.

## Sections

In order:

1. `Five patterns, one fold` (`#patterns`) — the teaching section. A `.deflist` (`pattern`, `fold`, `combiner`, `initial value`) then a two-column recursive-vs-fold figure across the five patterns.
2. `Where this goes` (`#close`) — the closing section: summarises F2.04 and points to F2.05.

Running example: the list `[1, 2, 3]` transformed by each of the five patterns, shown as input chips → result.

Real Elixir code shown — each pattern's recursive form beside its `Enum.reduce` fold (from the `P` data, verbatim):

- `sum`: recursive `def sum([]), do: 0` / `def sum([h | t]), do: h + sum(t)`; fold `Enum.reduce([1, 2, 3], 0, fn x, acc -> acc + x end)`.
- `length`: recursive `def len([]), do: 0` / `def len([_ | t]), do: 1 + len(t)`; fold `Enum.reduce([1, 2, 3], 0, fn _, acc -> acc + 1 end)`.
- `reverse`: recursive `def rev([]), do: []` / `def rev([h | t]), do: rev(t) ++ [h]`; fold `Enum.reduce([1, 2, 3], [], fn x, acc -> [x | acc] end)`.
- `map`: recursive `def map([], _), do: []` / `def map([h | t], f), do: [f.(h) | map(t, f)]`; fold `Enum.reduce([1, 2, 3], [], fn x, acc -> acc ++ [x * 2] end)`.
- `filter`: recursive `def filt([], _), do: []` / `def filt([h | t], p) do  if p.(h), do: [h | filt(t, p)], else: filt(t, p) end`; fold `Enum.reduce([1, 2, 3], [], fn x, acc -> if rem(x, 2) == 1, do: acc ++ [x], else: acc end)`.

## The interactives

### Section 1 — recursion-and-its-fold, `aria-labelledby="patTitle"` (`#patterns`)

- Figure title (`#patTitle`, verbatim): `A recursion and its fold`.
- Control group `patSel` (`role="group"`, `aria-label="Choose a pattern"`): buttons `data-p="sum"` (`data-c="sage"`, default `active`), `data-p="length"` (`data-c="blue"`), `data-p="reverse"` (`data-c="elixir"`), `data-p="map"` (`data-c="gold"`), `data-p="filter"` (`data-c="sage"`).
- SVG element ids: `patIn` (input chip group `[1, 2, 3]`), `patName` (the pattern name between the arrow), `patOut` (result chips/value). Plus the two-column code panes `pre.code#patRec` (label `recursive`) and `pre.code#patRed` (label `as a fold`), and readout `#patOutTxt`.
- Pure functions: `patKey()` reads the active `data-p`; `chip(...)` / `bigVal(...)` draw the result cells; `renderPat()` paints the input chips, the result (a single `bigVal` for `sum`/`length`, a chip row for `reverse`/`map`/`filter`), the pattern name, both code panes, and the readout. Per-pattern result data (verbatim): `sum` → `6`; `length` → `3`; `reverse` → `[3, 2, 1]`; `map` → `[2, 4, 6]`; `filter` → `[1, 3]`.
- Readout `#patOutTxt` (`aria-live="polite"`). Initial markup (verbatim): `sum · start at 0, combiner adds each element · [1, 2, 3] → 6`. Per-pattern `note` strings (verbatim): `sum` "start at 0, combiner adds each element · [1, 2, 3] → 6"; `length` "start at 0, combiner adds one and ignores the element · [1, 2, 3] → 3"; `reverse` "start at [], combiner prepends each element · [1, 2, 3] → [3, 2, 1]"; `map` "start at [], combiner appends the transformed element · [1, 2, 3] → [2, 4, 6]"; `filter` "start at [], combiner keeps elements that pass the test · [1, 2, 3] → [1, 3]".

### Takeaway (`.take`, `#patterns`, verbatim)

"Once you see the accumulator and the combiner, every one of these is the same recursion with a different combiner — which is to say, a fold."

### Bridge cell (`#patterns`)

`F1.07 · operators` → "Sum and product were folds over a function; so is every list walk here." → `Elixir`: "`Enum.reduce(list, init, combiner)` captures the shape all five share."

### Close note (`#close`, `.note`, verbatim)

"Next: **F2.05 — map / filter / reduce (folds)** — reduce as the universal fold. Back to the [F2.04 hub](/elixir/functional/recursion) or the [F2 overview](/elixir/functional)." (This note carries the only two in-body hyperlinks: `/elixir/functional/recursion` and `/elixir/functional`.)

### Footer build-stamp decoder

- Stamp id (`#stampId`, verbatim): `TSK0NZi3zmYUd6`.
- Hard-coded fallback timestamp in markup (`#st-ts`): `2026-05-30 16:28:26 UTC`.
- Same `decodeBranded` logic (namespace `TSK`, b62 Snowflake, `EPOCH_MS = 1704067200000`) populating `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts` on click/Enter/Space; decoded UTC matches the markup fallback `2026-05-30 16:28:26 UTC`.

## References (#refs, verbatim)

This page has no `#refs` / References section. There is no References block, no Sources list, and no named "Related in this course" list. The cross-course links that exist are: the inline F1.07 bridge label (text only), and the two hyperlinks inside the closing `.note` — `/elixir/functional/recursion` (the F2.04 hub) and `/elixir/functional` (the F2 overview) — plus the pager (see Wiring).

## Wiring

- route-tag (verbatim): `/ elixir / functional / recursion / patterns` — `<a href="/elixir">elixir</a>` · `<a href="/elixir/functional">functional</a>` · `<a href="/elixir/functional/recursion">recursion</a>` · `<span class="rcur">patterns</span>`.
- crumbs (verbatim): `F2` (→ `/elixir/functional`) / `F2.04` (→ `/elixir/functional/recursion`) / `patterns` (here).
- toc-mini (verbatim): `Five patterns, one fold` → `#patterns`; `Where this goes` → `#close`.
- pager: prev → `/elixir/functional/recursion/tail-calls` label `← Part 2 · tail calls`; next → `/elixir/functional` label `More in F2 · Functional →`.
- footer: identical to the hub/`shape`/`tail-calls` — three columns. Brand logo → `/elixir` + tagline. `Chapters`: `F1 · Algebra` (`/elixir/algebra`), `F2 · Functional Programming` (`/elixir/functional`), `F3 · The Elixir Language` (`/elixir/language`), `F4 · Algorithms & Data Structures` (`/elixir/algorithms`), `F5 · Pragmatic Programming` (`/elixir/pragmatic`), `F6 · Phoenix Framework` (`/elixir/phoenix`). `The course`: `Course home` (`/elixir`), `Contents & history` (`/elixir/course`), `Start · F1.01` (`/elixir/algebra/functions`). Foot bar: `© jonnify` + build stamp.
- Page meta: `<title>` (verbatim) `Recursion patterns — F2.04.3 · jonnify`; `<meta description>` (verbatim) `sum, length, reverse, map, and filter written recursively — and why each one is a fold over the list.`

## Build instruction

To (re)build this page, copy the `<head>…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the IIFE with the `P` pattern table + `renderPat` + the branded Snowflake decoder, then the progressive-enhancement reveal script) verbatim from a recent BUILT sibling on the elixir (purple) accent — the model sibling is `elixir/functional/recursion/tail-calls.html` (adjacent dive; same single-column hero, `.deflist` + `.fig` + `.bridge` + `.take`, identical head/footer/decoder). Change only the `<title>` / `<meta description>`, the header `route-tag` (current `patterns` segment as `<span class="rcur">`), and the `<main>` body (this page is a two-section dive — one teaching figure plus a closing `.note` — rather than three sections). No-invent guards: use only the real Portal surfaces exactly as written elsewhere in the course — the branded store, the event-sourced engine behind the ONE `Portal` facade, the Phoenix web app — and cite the companion F5/F6 material for OTP/BEAM internals rather than re-teaching them; keep `Enum.reduce/3` and the five fold combiners exactly as written, and do not invent routes, ids, readout strings, code tokens, or function arities. Voice rules: no first person, no exclamation marks, no emoji, and none of "just" / "simply" / "obviously". Keep the footer build stamp as a real `TSK…` id whose decode matches its `#st-ts` markup. Model sibling to copy from: `elixir/functional/recursion/tail-calls.html`.
