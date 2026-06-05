# F1 — Algebra (chapter landing)

- **Route (served):** `/elixir/algebra`
- **File:** `elixir/algebra/index.html`
- **Place in the chapter:** the F1 chapter landing — the opening chapter of *Functional Programming in Elixir*. It frames the chapter's nine lessons (each a single leaf page), grouped into four movements — Foundations, Structure, The operators, The lab — and routes the reader to the first lesson, `F1.01` at `/elixir/algebra/functions`.
- **Accent:** Algebra is the gold chapter (`--gold` / `--gold-bright`; the landing's hero motif and dictionary use gold).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `Chapter F1 · nine lessons`

`h1`: `Algebra.`

Hero lede (verbatim): "The first crossing. Before a single line of Elixir, one thing becomes plain: the algebra you already know — functions, substitution, composition — *is* functional programming."

Kicker (verbatim): "Each lesson pairs one algebraic idea with the Elixir it becomes: a function is a first-class value, substitution is referential transparency, composition is the pipe, and the higher-order operators Σ and Π are a fold. Read in order, the chapter is a dictionary you already half-know — nine lessons that turn quiet intuition into the foundation everything after it rests on."

## What the page frames

The landing presents the chapter as nine lessons in four movements. The "nine lessons" `#modules` section lists them with `.deflist` entries under group labels. Each module is a single leaf page (no module hubs in this chapter — the dives ARE the modules).

- **F1.01 · What a function really is** — "Mappings, domain, and range: each input goes to exactly one output." — `/elixir/algebra/functions` — built (start-here; the only one labelled "start here", the rest "available")
- **F1.02 · The substitution model** — "Replace equals with equals; an expression *is* its value — referential transparency." — `/elixir/algebra/substitution` — built
- **F1.03 · Composition, f ∘ g** — "Chain small functions into larger ones; composition is associative — the pipe." — `/elixir/algebra/composition` — built
- **F1.04 · Immutability & binding** — "A symbol names a fixed value; you rewrite expressions, never mutate." — `/elixir/algebra/immutability` — built
- **F1.05 · Sets, sequences & mappings** — "Collections, and applying one function across all of them at once." — `/elixir/algebra/collections` — built
- **F1.06 · Recursion & induction** — "Define a thing in terms of itself: base case and step; prove it by induction." — `/elixir/algebra/recursion` — built
- **F1.07 · Higher-order operators — Σ and Π** — "Operators that take functions; sums and products as a single fold." — `/elixir/algebra/higher-order` — built
- **F1.08 · Equations & pattern matching** — "Identities, solving, and matching a value by its structure." — `/elixir/algebra/pattern-matching` — built
- **F1.09 · Functions on the plane — a plotting lab** — "Plot and compose functions, and watch f ∘ g take shape as curves you can drag." — `/elixir/algebra/plotting-lab` — built (the lab)

Group labels (verbatim): `Foundations` (F1.01–F1.03) · `Structure` (F1.04–F1.06) · `The operators` (F1.07–F1.08) · `The lab` (F1.09, in gold-bright).

The landing also carries a "The algebra you already speak" `#rosetta` dictionary (algebra → Elixir / FP) and a "Where this sits" `#sits` section placing F1 before F2 · Functional Programming, F3 · The Elixir Language, and F4 · Algorithms & Data Structures.

## The interactives

This landing carries two interactive figures plus the footer build-stamp decoder. (No `#refs` References section is present on this page.)

### Hero motif (static SVG, non-interactive)

A `.hero-motif` SVG (`viewBox="0 0 1000 118"`, `aria-label`: "A value x is sent through g, then f, composing into f of g of x.") drawing `x → g → f → f(g(x))` with the caption "x ↦ f(g(x)) — compose functions, and that is the whole game". No controls.

### Figure — "The journey · select a lesson" (`#arc` section)

- `<figure>` title (`#jTitle`): "The journey · select a lesson".
- SVG node graph: nine `.arc-node` groups, each `data-mod="F1.01"`…`F1.09`, `role="button"`, `tabindex="0"`. Phase column rules at x=363/717/953; labels FOUNDATIONS, STRUCTURE, THE OPERATORS, THE LAB.
- Readout block `.arc-readout`: `#jNm` (title), `#jOne` (one-line), `#jId` (lesson id), `#jPhase` (phase), `#jStatus` (status), `#jOpen` (an "Open … →" link).
- Pure function: `selectMod(id)` reads `MODS[id]` (the `MODS` dataset keyed `F1.01`–`F1.09`, each `{title, one, phase, status, route, slug}`, `F1.09` also `lab:true`), toggles the matching `.arc-node` `active`, and writes title/one/id/phase/status/open-link into the readout. Wired via `click` and `keydown` (Enter/Space) on each node; initial call `selectMod('F1.01')`.
- Default readout (static markup, the `F1.01` strings): `#jNm` "What a function really is"; `#jOne` "A rule that sends each input to exactly one output — the whole of functional programming starts here."; `#jId` "F1.01"; `#jPhase` "Foundations"; `#jStatus` "available now"; `#jOpen` link "Open F1.01 · functions →" → `/elixir/algebra/functions`.
- `.take` (verbatim): "The chapter is a single line of reasoning: settle what a function is, learn the operators that act on it, then compose those operators into programs."

### Figure — "A mapping · choose a rule f : A → B" (`#mapping` section)

- `<figure>` title (`#mTitle`): "A mapping · choose a rule f : A → B".
- Control group `#mp-buttons` (`role="group"`, `aria-label="Choose a function rule"`), three buttons (all `data-c="gold"`): `data-f="add2"` label "f(x) = x + 2" (starts `active`); `data-f="dbl"` label "f(x) = 2x"; `data-f="sq"` label "f(x) = x²".
- SVG `#mp-svg` (`viewBox="0 0 460 300"`): groups `#mp-arrows`, `#mp-in`, `#mp-out`. Readout `#mp-readout` (default static content "—").
- Pure function: `render(key)` from `fns {add2:{f:x+2,lab:'x + 2'}, dbl:{f:2x,lab:'2x'}, sq:{f:x²,lab:'x²'}}` over inputs `[1,2,3,4]`; draws the input circles, output circles (y-scaled by `vy(v)` with `MAXV=16`), and the connecting arrows, then writes the readout. Initial call `render('add2')`.
- Readout string (verbatim, built by `render`): `f(x) = <lab> · {1, 2, 3, 4} ↦ {<outs>}`.
- `.bridge`: idea cell `F1 · Algebra` "A function f : A → B is a rule sending each element of the domain to one element of the range."; elixir cell "A first-class value: `f = fn x -> x + 2 end` — pass it, return it, compose it."
- `.take` (verbatim): "Every input has exactly one arrow. Switch the rule and the mapping redraws whole — the mathematical meaning and the Elixir value are the same object."

### The rosetta dictionary (`#rosetta`, static table)

A `.rosetta` `role="table"` with rows (algebra → Elixir / FP), verbatim: a function f : A → B → a function (first-class); substitution → referential transparency; composition f ∘ g → the pipe |>; x is a fixed value → immutable data; Σ, Π over a set → reduce / fold; recursive definition → recursion (no loops); solving by structure → pattern matching.

### Degrade behaviour

Both figures' controls + SVG render in static markup; the `#mapping` readout starts at "—" and the journey readout starts pre-filled with the `F1.01` strings. JS enhances by wiring clicks and the initial `render`/`selectMod`. The page respects `prefers-reduced-motion` globally (the `.arc-flow` dash animation is suppressed; reveal transitions disabled); no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0NeCK8RHBRY` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-02 09:22:19 UTC" (the decoded UTC timestamp).
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` — splits `ns = id.slice(0,3)` and `snow = b62decode(id.slice(3))`, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`, formatting a UTC string; fills `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`. Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

No `#refs` References section is present on this page. The landing has no Sources/Related block; its cross-links live in the `#sits` section, the `.note`, the pager, and the footer (see Wiring).

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><span class="rcur">algebra</span>` (only `elixir` is a link; `algebra` is the current segment).
- **crumbs:** none on the landing (crumbs appear on the dive pages, not on this chapter landing).
- **toc-mini:** none on the landing (the in-page navigation is the journey figure, not a `.toc-mini` pill row).
- **pager:** prev → `/elixir` ("← Course contents"); next → `/elixir/algebra/functions` ("Start · F1.01 · functions →").
- **footer:** three columns —
  - brand: `.foot-logo` → `/elixir`; tag "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - `Chapters`: `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework).
  - `The course`: `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- **Page meta:** `<title>` "F1 · Algebra — jonnify"; `<meta description>` "The Algebra chapter: the opening chapter of Functional Programming in Elixir. Nine lessons showing that the algebra you already know — functions, substitution, composition, recursion — is functional programming, with an algebra-to-Elixir dictionary and an interactive function visualizer."

## Build instruction

To (re)build this landing, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built sibling on the gold accent — the model is this chapter's own `elixir/algebra/index.html`, the canonical F1 landing — then change only `<title>`/`<meta>`, the route-tag, and the `<main>` body (hero → `#arc` journey figure → `#mapping` figure → `#rosetta` → `#modules` deflist → `#sits` → pager). No-invent guards: cite only the real Portal surfaces as written (the branded store, the event-sourced engine behind one `Portal` facade, the Phoenix web app); this F1 landing predates the Portal and stays pure-algebra, so it names no engine internals — cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
