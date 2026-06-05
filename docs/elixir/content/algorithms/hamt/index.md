# F4.05 — Hash array mapped tries (module hub)

- Route (served): `/elixir/algorithms/hamt`
- File: `elixir/algorithms/hamt/index.html`
- Place in the chapter: module 5 of the restructured 12-module F4 chapter, and the first of the chapter's three persistent-map modules. It opens the persistent-map spine `F4.05` (HAMT) → `F4.06` (CHAMP) → `F4.07` (Snowflake/branded ids) → `F4.08` (persistence) → `F4.09` (branded-CHAMP). It generalises `F4.04`'s flat hash table into a tree, and frames three dives: `bitmap`, `indexing`, `sharing`.
- Accent: sage (the F4 · Algorithms & Data Structures chapter accent; `--sage` / `--sage-bright`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4 · Persistent maps · module 5`

H1: Hash array mapped `tries` (the word `tries` set in the `.ex` elixir-accent span).

Hero lede (verbatim):

> F4.04 sent a key through a hash to a slot in one flat table. A **HAMT** — a hash array mapped trie — spreads that idea over a tree. It consumes the key's hash a few bits at a time, branching up to 32 ways at each level, so a node is a small **bitmap** plus one packed array, and the depth is about `log₃₂ n` — roughly four levels for millions of keys.

Kicker (verbatim):

> It is the structure the BEAM uses for a large immutable map, and the first of the chapter's three persistent-map modules: the page registry behind the portal is a map, and that map is a trie like this one.

## What the page frames

The hub's three dives (the `Three deep dives` section), each a card linking to a leaf route, with its `F4.05.x` number, left-border accent, and one-line summary verbatim:

- `F4.05.1` — **Bitmapped nodes** — "One `bitmap` marks the occupied slots; a single packed array holds them, and a slot's position is found by `popcount`." Route `/elixir/algorithms/hamt/bitmap`. Border accent sage. Built.
- `F4.05.2` — **Hash-prefix indexing** — "Five bits of the hash pick a slot at each level; the next five pick the next, so the depth is about `log₃₂ n`." Route `/elixir/algorithms/hamt/indexing`. Border accent blue. Built.
- `F4.05.3` — **Structural sharing** — "An insert copies the path from root to the changed leaf and shares every other sub-tree, so the old map stays intact." Route `/elixir/algorithms/hamt/sharing`. Border accent gold. Built.

The body also carries an `Inside a HAMT node` teaching section (the `#node` figure) and an `Advanced: a tree of 32-way nodes` section (the `#advanced` why-32 argument plus a `Hamt.Node` defstruct and an `F4.04 → F4.05` bridge). The dives are introduced in the arc "the node, the descent, and the way an edit shares structure in turn."

## The interactives

### Hero figure — "A set bit maps to a packed slot by popcount"
- `<figure class="hero-fig">` labelled by `#haTitle` (`fc-lbl`: "A set bit maps to a packed slot by popcount").
- Controls (`.ha-ctrls`): button `#haAdd` (label `▸ insert key`) and ghost button `#haReset` (label `reset`).
- SVG groups: `#haBits` (the eight shown bitmap cells), `#haLinks` (popcount connectors), `#haArr` (the packed array cells), `#haWork` (the worked-example box) with line `#haWorkLine`; readout caption `#haCap`.
- Static default in markup: slots `2` and `5` set, two packed entries `[0]`/`[1]`, worked box reading `bitmap = 0b00100100` / `2 bits set → array length 2` / `index(slot) = popcount(bits below slot)`.
- Logic (inline IIFE): `SLOTS = 8` shown of 32; `INITIAL = [2, 5]`; `POOL = [4, 0, 6]` inserted in order; `CAP = 5`. `indexOfSlot(slot)` computes the popcount of set bits strictly below a slot (its array index); `bitmapBits()` renders the 8-bit string; `render(isInsert)` redraws cells, connectors, the worked line, and the caption.
- Caption default strings (verbatim): `bitmap 0b00100100 · 2 slots set` and `Each set bit owns one packed slot; its index is the popcount below it.` On insert the worked line reads `insert slot N: popcount(below) = i → array[i]`.
- Degrade: the static SVG already shows the two-bit node, so it is meaningful with no JS; `.ha-new` insert animation is gated by `@media (prefers-reduced-motion: no-preference)` and disabled under `reduce`.

### Section figure — "The angle · select one (8 of 32 slots shown)"
- `<figure class="fig">` labelled by `#hmTitle`; control group `#hmSel` (`solid-select`, `role="group"`, label "The angle") with three buttons:
  - `data-k="bitmap"` `data-c="sage"` (active) — label `bitmap`
  - `data-k="index"` `data-c="blue"` — label `index`
  - `data-k="sharing"` `data-c="gold"` — label `sharing`
- SVG ids switched per case: `#hmArr` (the packed array bar, stroke recoloured), `#hmBadgePop` / `#hmBadgeShare` (the two worked-example overlays, opacity toggled), `#hmCaption`; plus the `#hmCode` code block, `#hmOut` readout, `#hmRole` and `#hmExpr` lines.
- `pick(k)` reads the `CASES` table and sets the array stroke, the badge opacities, caption/role/expr text, code, and readout. `pick('bitmap')` runs on load.
- Readout strings (`out`, verbatim, HTML stripped):
  - `bitmap`: "A HAMT node keeps **one bitmap and one packed array**. The bitmap says which of 32 slots are occupied — here three — and the array stores exactly those three, in slot order, with nothing in between." (role: `one bitmap, one packed array`; expr: `the array holds only the present slots`; caption: `one bitmap marks the three occupied slots`).
  - `index`: "To turn a slot into an array position, **popcount** the bitmap bits below it. Slot 4 has one set bit beneath it (slot 1), so its occupant is at `array[1]` — constant time, one instruction per level." (role: `a slot index by popcount`; expr: `one CPU instruction per level`; caption: `popcount of the lower bits gives the array position`).
  - `sharing`: "Because the node is immutable, an insert builds **new nodes only along the path** from the root to the changed leaf. Every other sub-tree is shared, pointer-identical, with the previous map — so the old map is still there and the new one is cheap." (role: `persistent — shares structure`; expr: `the old map stays intact`; caption: `an insert copies the path and shares the rest`).

### Footer build-stamp decoder
- `#stamp` carries `build TSK0NcRkmRv7GS`. The decoder (B62 → snowflake, `EPOCH_MS = 1704067200000`) splits a 3-char namespace (`TSK`) + base62 snowflake and decodes ts/node/seq. Pre-rendered timestamp in markup: `2026-06-01 08:03:01 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- Bagwell, P. (2001). *Ideal Hash Trees.* — the original HAMT paper. `https://lampwww.epfl.ch/papers/idealhashtrees.pdf`
- Hash array mapped trie — Wikipedia — the structure in brief. `https://en.wikipedia.org/wiki/Hash_array_mapped_trie`

Related in this course:
- F4.04 · Maps, sets & hashing — the flat table this trie generalises. `/elixir/algorithms/maps`
- F4.06 · CHAMP maps — the compressed successor. `/elixir/algorithms/champ`
- Structural sharing — how an insert reuses the old map. `/elixir/algorithms/hamt/sharing`

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `algorithms` `/ ` `hamt` — segmented `<span class="route-tag">` with `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, and `hamt` as the current `.rcur` segment.
- crumbs (verbatim): `F4 · Algorithms & Data Structures` (→ `/elixir/algorithms`) · `F4.05 · hamt` (`.here`).
- toc-mini: `Inside a HAMT node` (`#node`) · `Three deep dives` (`#dives`) · `Advanced: a tree of 32-way nodes` (`#advanced`).
- pager: prev → `/elixir/algorithms/maps` label `← F4.04 · maps`; next → `/elixir/algorithms/hamt/bitmap` label `Start · bitmapped nodes →`.
- footer: three columns. Brand column (logo → `/elixir`, tagline "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."). `Chapters`: `F1 · Algebra` `/elixir/algebra`, `F2 · Functional Programming` `/elixir/functional`, `F3 · The Elixir Language` `/elixir/language`, `F4 · Algorithms & Data Structures` `/elixir/algorithms`, `F5 · Pragmatic Programming` `/elixir/pragmatic`, `F6 · Phoenix Framework` `/elixir/phoenix`. `The course`: `Course home` `/elixir`, `Contents & history` `/elixir/course`, `Start · F1.01` `/elixir/algebra/functions`.
- Page meta — `<title>`: `Hash array mapped tries — F4.05 · jonnify`. `<meta description>`: "A HAMT spreads a hash table over a tree: it consumes the key's hash five bits at a time, branching up to 32 ways per level, so a node is a bitmap plus one packed array and depth is about log32 n. It is the structure the BEAM uses for a large immutable map, and the first of the chapter's three persistent-map modules — the page registry is a map, and that map is a trie like this one."

## Build instruction

To rebuild this hub, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the trailing script blocks (the section-figure `CASES`/`pick`, the hero-node IIFE, and the Branded Snowflake decoder + reveal-on-scroll) verbatim from a recent BUILT sibling on the F4 sage accent — the `bitmap` dive (`elixir/algorithms/hamt/bitmap.html`) is the closest hub-adjacent sibling, or another F4 module hub such as `elixir/algorithms/maps/index.html`. Change only `<title>` / `<meta description>`, the route-tag, and the `<main>` body (hero, `#node` figure, `#dives` cards, `#advanced`, references). No-invent guards: cite only the real course surfaces as written — the BEAM `Map` is a HAMT, the page registry is a map from a route to a `%Page{}` keyed by a branded `PGE…` Snowflake id, and the persistent-map spine continues into `F4.06` (CHAMP) and the `BrandedChamp` trie; do not re-teach OTP internals or invent Portal API. Voice rules: no first person, no exclamation marks, no emoji, and none of "just" / "simply" / "obviously". Model sibling to copy from: `elixir/algorithms/hamt/bitmap.html`.
