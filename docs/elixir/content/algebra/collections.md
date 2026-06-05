# F1.05 — Sets, sequences & mappings (dive / lesson)

- **Route (served):** `/elixir/algebra/collections`
- **File:** `elixir/algebra/collections.html`
- **Place in the chapter:** the fifth lesson of F1 · Algebra, in the Structure movement. It follows `F1.04` (immutability) — the elements are immutable values, so the collections holding them are immutable too — and meets the three collection shapes plus `Enum.map`, the operation the operator lesson `F1.07` builds on. It precedes `F1.06` (recursion).
- **Accent:** gold chapter accent (gold/elixir token palette).
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F1 · Algebra`

`h1`: `Sets, sequences & mappings`

Hero lede (verbatim): "A single value is rarely the whole story. Three shapes of collection cover almost everything — ordered sequences, distinct sets, and key-to-value mappings — and one operation runs a function across any of them."

Kicker (verbatim): "Each shape answers a different question: in what order, how many distinct, and looked up by what. Once the elements are immutable values from F1.04, the collections holding them are immutable too. We meet the three, then apply a function across a collection with map — the operation the next chapters build on."

## Sections

Three teaching sections, each closing with a `.bridge` and a `.take`:

1. **Sequence and set** (`#shapes`) — ordered `List` (`[3, 1, 4]`) vs distinct `MapSet` (`MapSet.new([3, 1, 4, 1])`) vs key-to-value `Map` (`%{a: 1}`); order and duplicates kept vs dropped.
2. **Mapping over a collection** (`#mapping-over`) — `Enum.map` applies one function across every element, preserving length and returning a new list.
3. **A mapping is a function** (`#mapping-is`) — a `Map` is itself a function from key to value; `Map.get(squares, key)` is a lookup.

Synthesis "What this lands" closes the arc and forwards to F1.06.

## The interactives

Three interactive figures plus the footer build-stamp decoder.

### Figure — "Same elements · sequence versus set" (`#shapeTitle`)

- Controls: a single `.fold-ctrl` slider `#seqN` (take; min 1, max 8, step 1, value 5). No `.solid-select`.
- Readout `#seqOut` (verbatim default): `list — length 5 (order & duplicates kept) · set — size 4 · one duplicate dropped`.

### Figure — "Enum.map · apply f to every element" (`#mapTitle`)

- Control group `#mapSel` ("Choose a function"), three buttons: `data-fn="inc" data-c="sage"` "+1"; `data-fn="dbl" data-c="blue"` "×2"; `data-fn="sq" data-c="gold"` "x²" (active).
- Readout `#mapOut` (verbatim default): `[1, 2, 3, 4] → [1, 4, 9, 16] · length preserved (4 → 4) · a new list is returned`.

### Figure — "A map of squares · look up a key" (`#lookTitle`)

- Controls: a single `.fold-ctrl` slider `#lookK` (key; min 0, max 5, step 1, value 3).
- Readout `#lookOut` (verbatim default): `Map.get(squares, 3) → 9 · the key is present`.

### Degrade behaviour

Controls, SVGs, and the default readouts render in static markup; the code blocks are filled by JS on init. The page respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0NZNbwzpRFw` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-30 11:42:14 UTC" (the decoded UTC timestamp).
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`; `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`; `EPOCH_MS = 1704067200000`). Toggle on click / Enter / Space.

## References (#refs, verbatim)

No `#refs` References section is present on this page. The lesson's cross-links are the crumbs, toc-mini, `.note`, pager, and footer (see Wiring); the prose names F1.04 (immutable values).

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/algebra">algebra</a><span class="rsep">/</span><span class="rcur">collections</span>`.
- **crumbs:** `F1 · Algebra` → `/elixir/algebra` · sep `/` · `F1.04` → `/elixir/algebra/immutability` · sep `/` · here `F1.05` (no link).
- **toc-mini:** `#shapes` ("Sequence and set") · `#mapping-over` ("Mapping over a collection") · `#mapping-is` ("A mapping is a function").
- **pager:** prev → `/elixir/algebra/immutability` ("← F1.04 · immutability"); next → `/elixir/algebra` ("More in F1 · Algebra →"). (The synthesis `.note` names F1.06 as "(planned)".)
- **footer:** identical three-column footer — brand → `/elixir`; `Chapters` F1–F6; `The course` `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- **Page meta:** `<title>` "Sets, sequences & mappings — F1.05 · jonnify"; `<meta description>` "Three shapes of collection — ordered lists, distinct MapSets, key-to-value Maps — and Enum.map, the operation that applies a function across any of them."

## Build instruction

To (re)build this lesson, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built gold-accent sibling — the model is `elixir/algebra/immutability.html` (F1.04, the same lesson template: crumbs, toc-mini, three figures, `.solid-select`/`.fold-ctrl` controls, `.bridge`/`.take` rhythm) — then change only `<title>`/`<meta>`, the route-tag, the crumbs, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written (branded store, event-sourced engine behind one `Portal` facade, Phoenix web app); this lesson is pure algebra over `List`/`MapSet`/`Map`/`Enum` and names no engine internals — cite the companion course for OTP internals, do not re-teach. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously.
