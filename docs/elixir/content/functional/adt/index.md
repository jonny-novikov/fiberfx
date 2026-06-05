# F2.07 — Algebraic data types (module hub)

- Route (served): `/elixir/functional/adt`
- File: `elixir/functional/adt/index.html`
- Place in the chapter: The seventh module of F2 · Functional Programming. It frames the algebra of types — products multiply, sums add — and pattern matching as the eliminator, then hands off to three deep dives. It sits between `F2.06` (closures) and `F2.08` (composition & pipelines) in the chapter arc.
- Accent: elixir (purple) — `--elixir:#b39ddb`, `--elixir-bright:#cdb8f0`.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F2 · Functional Programming`

H1: `Algebraic data types`

Lede (verbatim):
> Complex data is built from two operations. A product type holds several values at once — this *and* that. A sum type is one of several shapes — this *or* that. Combine them and you can describe any data precisely, then take it apart with pattern matching.

Kicker (verbatim):
> They are called *algebraic* because counting their values follows ordinary algebra. The number of values a product type can hold is the *product* of its parts; for a sum type it is the *sum* of its variants. Tuples and structs are products; tagged tuples like `{:ok, value}` are sums. Designing data well is choosing the right sums and products.

## What the page frames

This hub teaches three concepts inline (sections `#product`, `#sum`, `#match`) and then routes to three deep dives (section `#dives`). The dive cards:

- `F2.07.1` — **Product types** — Tuples and structs — fields by position or name, immutable update, and why inhabitants multiply. Route `/elixir/functional/adt/product`. Built.
- `F2.07.2` — **Sum types** — Tagged tuples and variants — one shape or another, and the `{:ok, _} | {:error, _}` idiom. Route `/elixir/functional/adt/sum`. Built.
- `F2.07.3` — **Pattern matching on data** — Destructuring products to bind fields, and dispatching on sum variants with case and function heads. Route `/elixir/functional/adt/matching`. Built.

Note: the dive cards are bespoke anchor blocks (inline-styled `<a>` tiles), not the `.mods`/`.dives` grid; there are no built/planned pills on them — all three are live links.

The synthesis section (`What this lands`) closes: a product multiplies the possibilities, a sum adds them, pattern matching reads which shape a value has; `F2.08` then composes the functions over them into pipelines.

## The interactives

### Hero figure — `Sum is a choice, product is a combination`
- `<figure class="hero-fig">` labelled by `#hpTitle` (`Sum is a choice, product is a combination`).
- SVG ids: sum group `#hpSum` (with `#hpVarBox`, `#hpTagBox`, `#hpTag`, `#hpPay`, `#hpPay2`), inactive variant `#hpAlt` (`#hpAltBox`, `#hpAltTag`, `#hpAltPay`); product struct fields drawn statically (`%Point{x:3, y:7, z:2}`).
- Control: one button `#hpNext`, label `▸ next variant` (`&#9656; next variant`).
- Pure function: `paint(v)` cycles `VARIANTS` `[Circle{r}, Rect{w,h}]` — a sum value is exactly one variant at a time. Static markup already shows `VARIANTS[0]` (Circle).
- Readout `#hpCap` (`aria-live="polite"`), verbatim default:
  - `Shape = Circle{r}`
  - `A sum value is one variant now: Circle, holding a radius. Pattern matching reads which.`
- Second variant caption (verbatim, painted on next): `Now the same value is Rect, holding a width and a height. Never both variants at once.`

### Section 1 — `{a, b} · every combination is a value`  (`#product`)
- `<figure class="fig">` labelled by `#prTitle`. Controls: range `#prA` (`values in a`, 1–4, default 2) and `#prB` (`values in b`, 1–4, default 3); value spans `#prAval`/`#prBval`. SVG grid group `#prGrid`. Code `#prCode`.
- Pure function: `renderPr()` computes `n = a * b` and renders an `a × b` grid of cells.
- Readout `#prOut`, verbatim default: `2 a-values × 3 b-values = 6 possible values`.
- Deflist (verbatim): `algebraic data type` — a type built from products and sums of other types; `product type` — several values held together — a tuple or a struct; `sum type` — one of several alternatives — a tagged tuple or variant; `tagged tuple` — a tuple whose first element is an atom naming the variant.
- Take (verbatim): `A product type is an and: all fields present together. Its value count is their product.`

### Section 2 — `A | B · a value is exactly one variant`  (`#sum`)
- `<figure class="fig">` labelled by `#suTitle`. Controls: range `#suA` (`values in A`, 1–4, default 2), `#suB` (`values in B`, 1–4, default 3); spans `#suAval`/`#suBval`. SVG groups `#suGroupA` (sage dots) / `#suGroupB` (gold dots). Code `#suCode`.
- Pure function: `renderSu()` computes `n = a + b` and draws two disjoint groups.
- Readout `#suOut`, verbatim default: `2 in A + 3 in B = 5 possible values`.
- Take (verbatim): `A sum type is an or: one variant at a time. Its value count is their sum.`

### Section 3 — `case result do · one clause per variant`  (`#match`)
- `<figure class="fig">` labelled by `#mTitle`. Control group `#mSel` with three buttons:
  - `data-k="ok"` `data-c="sage"` (active) — label `{:ok, 42}`
  - `data-k="error"` `data-c="burg"` — label `{:error, :timeout}`
  - `data-k="pending"` `data-c="gold"` — label `:pending`
- SVG clause rows `#mC0`/`#mT0`, `#mC1`/`#mT1`, `#mC2`/`#mT2`. Code `#mCode`.
- Pure function: `renderM()` reads the active key from `M` (`ok` → clause 0 `binds v = 42` `"got 42"`; `error` → clause 1 `binds e = :timeout` `"failed: timeout"`; `pending` → clause 2 `no fields to bind` `"still waiting"`), highlights the matching clause, and renders the readout/code.
- Readout `#mOut`, verbatim default: `{:ok, 42} · matches the first clause · binds v = 42 · "got 42"`.
- Take (verbatim): `Pattern matching is the eliminator for algebraic data: one clause per shape, fields bound as they match.`

### Degrade behaviour
Every figure renders a static default in markup (Circle hero variant, the `2×3` grid via the seeded slider values, the `{:ok, 42}` matched clause) before JS runs. The hero swap animation `hpIn` and the `.arc-flow` flow animation are gated by `@media (prefers-reduced-motion: no-preference)` and disabled under `prefers-reduced-motion: reduce`; `scroll-behavior` also drops to `auto`. The reveal-on-scroll script adds `.in` immediately when reduced motion is set or `IntersectionObserver` is absent.

### Footer build-stamp
`#stampId` text = `TSK0NaskveSuwK`. The `decodeBranded` script splits the namespace (`TSK`) and base62-decodes the snowflake; decoded fields: namespace `TSK`, snowflake `319406067182206976`, node `0`, seq `0`, timestamp `2026-05-31 09:25:40 UTC` (matches the hard-coded `#st-ts`).

## References (#refs, verbatim)

This page has no `References` (`#refs`) section. No Sources block and no "Related in this course" block are present in the markup; cross-links live inline in the prose and pager (`/elixir/functional/adt/product`, `/elixir/functional/adt/sum`, `/elixir/functional/adt/matching`, `/elixir/functional/closures/currying`).

## Wiring

- route-tag (verbatim): `/ elixir / functional / adt` — `elixir` → `/elixir`, `functional` → `/elixir/functional`, current segment `adt` (`.rcur`).
- crumbs (verbatim): `F2 · Functional` (`/elixir/functional`) / `F2.06` (`/elixir/functional/closures`) / `F2.07` (`.here`).
- toc-mini: `#product` → `Product: this and that`; `#sum` → `Sum: this or that`; `#match` → `Taking it apart`; `#dives` → `Three deep dives`.
- pager: prev → `/elixir/functional/closures/currying` label `F2.06 · currying`; next → `/elixir/functional/adt/product` label `Start · product types`.
- footer: column **Chapters** — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta: `<title>` = `Algebraic data types — F2.07 · jonnify`; `<meta description>` = `The algebra of types: product types hold several values at once and their counts multiply; sum types are one shape or another and their counts add; pattern matching takes them apart.`

## Build instruction

To rebuild this page, copy the `head…</style>`, `header`, `footer`, and trailing reveal/decoder `<script>` blocks verbatim from a recent BUILT sibling on the F2 elixir-purple accent — the model sibling is the F2.05 folds hub at `elixir/functional/folds/index.html` (another module hub with the `.mods`/dive pattern, the hero-fig, and the same stamp/reveal scripts). Change only `<title>`/`<meta>`, the route-tag (`elixir / functional / adt`), the crumbs, the toc-mini anchors, and the `<main>` body. This hub keeps the landing-style italic display lede via `.hero-lede` and a `hero-fig` concept figure in `.hero-art`. No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind one Portal facade, and the Phoenix web app — and cite the companion course for OTP internals rather than re-teaching them; do not invent routes, ids, or readout strings. Voice rules: no first person, no exclamation marks, no emoji, and none of just / simply / obviously.
