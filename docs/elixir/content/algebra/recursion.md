# F1.06 — Recursion & induction (dive / lesson)

- **Route (served):** `/elixir/algebra/recursion`
- **File:** `elixir/algebra/recursion.html`
- **Place in the chapter:** the sixth lesson of F1 · Algebra, closing the Structure movement. It follows `F1.05` (collections) and shows how functional code traverses without a loop — base case plus step, the call stack, and induction (the proof sharing recursion's shape). It precedes `F1.07` (higher-order operators), which capture this recursion as named patterns.
- **Accent:** gold chapter accent (gold/elixir token palette).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F1 · Algebra`

`h1`: `Recursion & induction`

Hero lede (verbatim): "A function that calls itself needs only two things: a base case that stops, and a step that moves toward it. The same two parts, used as a proof, are mathematical induction."

Kicker (verbatim): "Functional code has no loop counter. To walk a list you handle its head and recurse on its tail until nothing is left — iteration is recursion. We trace a recursion through the call stack, see why the base case is what makes it stop, and meet induction, which proves a recursive definition correct using the very same shape."

## Sections

Three teaching sections, each closing with a `.bridge` and a `.take`:

1. **The call stack** (`#stack`) — tracing `sum([1, 2, 3, 4])` as it winds down then unwinds; the list is handled head `[h | t]` then recurse on tail, base case `sum([]) = 0`, step `h + sum(t)`.
2. **The base case** (`#base`) — why the base case is what makes a recursion terminate; `count(n)` with and without a base case.
3. **Induction** (`#induction`) — proving a recursive definition with base + step; `1 + 2 + … + n = n·(n+1)/2`.

Synthesis "What this lands" closes the arc and forwards to F1.07.

## The interactives

Three interactive figures plus the footer build-stamp decoder.

### Figure — "sum([1, 2, 3, 4]) · wind down, then unwind" (`#stackTitle`)

- Controls: a single `.fold-ctrl` slider `#stkStep` (step; min 0, max 8, step 1, value 8). No `.solid-select`.
- Readout `#stkOut` (verbatim default): `done · sum([1, 2, 3, 4]) = 1 + 9 = 10`.

### Figure — "count(n) · does it reach a stop?" (`#baseTitle`)

- Control group `#baseSel` ("Base case"), two buttons: `data-base="on" data-c="sage"` "with base case" (active); `data-base="off" data-c="elixir"` "without base case". `.fold-ctrl` slider `#baseN` (start n; min 1, max 6, step 1, value 4) with its value box.
- Readout `#baseOut` (verbatim default): `count(4) reduces to count(0) — base reached in 5 steps · terminates`.

### Figure — "Induction · base, then every step" (`#indTitle`)

- Controls: a single `.fold-ctrl` slider `#indN` (prove to n; min 1, max 8, step 1, value 6).
- Readout `#indOut` (verbatim default): `1 + 2 + … + 6 = 21 · 6·7/2 = 21 · equal — and induction proves it for every n`.

### Degrade behaviour

Controls, SVGs, and the default readouts render in static markup; the code blocks are filled by JS on init. The page respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0NZOxym7bpA` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-30 12:01:12 UTC" (the decoded UTC timestamp).
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`; `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`; `EPOCH_MS = 1704067200000`). Toggle on click / Enter / Space.

## References (#refs, verbatim)

No `#refs` References section is present on this page. The lesson's cross-links are the crumbs, toc-mini, `.note`, pager, and footer (see Wiring); the prose names F1.05 (collections) and F1.07.

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/algebra">algebra</a><span class="rsep">/</span><span class="rcur">recursion</span>`.
- **crumbs:** `F1 · Algebra` → `/elixir/algebra` · sep `/` · `F1.05` → `/elixir/algebra/collections` · sep `/` · here `F1.06` (no link).
- **toc-mini:** `#stack` ("The call stack") · `#base` ("The base case") · `#induction` ("Induction").
- **pager:** prev → `/elixir/algebra/collections` ("← F1.05 · collections"); next → `/elixir/algebra` ("More in F1 · Algebra →"). (The synthesis `.note` names F1.07 — "Higher-order operations" — as "(planned)".)
- **footer:** identical three-column footer — brand → `/elixir`; `Chapters` F1–F6; `The course` `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- **Page meta:** `<title>` "Recursion & induction — F1.06 · jonnify"; `<meta description>` "Base case plus step: the call stack of a recursive sum, why the base case makes it terminate, and induction — the proof that shares recursion's shape."

## Build instruction

To (re)build this lesson, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built gold-accent sibling — the model is `elixir/algebra/collections.html` (F1.05, the same lesson template: crumbs, toc-mini, three figures, the step-slider trace pattern, `.bridge`/`.take` rhythm) — then change only `<title>`/`<meta>`, the route-tag, the crumbs, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written (branded store, event-sourced engine behind one `Portal` facade, Phoenix web app); this lesson is pure algebra and names no engine internals — cite the companion course for OTP internals, do not re-teach. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously.
