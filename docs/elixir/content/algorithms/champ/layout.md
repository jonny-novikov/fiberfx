# F4.06.1 — Compressed node layout (dive)

- Route (served): `/elixir/algorithms/champ/layout`
- File: `elixir/algorithms/champ/layout.html`
- Place in the chapter: the first of the three F4.06 dives. It opens the CHAMP teaching arc by laying out a single node — the two bitmaps (`datamap`/`nodemap`), the two packed arrays, and the `popcount` index trick — before iteration (F4.06.2) and equality (F4.06.3) build on that shape.
- Accent: sage (the F4 chapter accent; the dive-card border on the hub is sage).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.06 · part 1 of 3`

Hero h1 (verbatim): `Compressed node layout` (the word `layout` carries the `.ex` accent span).

Hero lede (verbatim):

> A CHAMP node describes its 32 slots with two bitmaps. The `datamap` has a bit set for each slot holding an inline entry; the `nodemap` has a bit set for each slot holding a child node. The entries live in one packed array and the children in another, each holding only what is present — no empty cells. To find a slot's position in its array you take a **popcount**: the number of set bits below it.

Kicker line (verbatim):

> An 8-slot node (32 in reality) with entries at slots 1 and 4 and children at slots 2 and 6. Select what to read.

## Sections

In order:

1. `#bits` — **Two bitmaps, two arrays** (teaching): the bitmaps say which slots are used; the arrays hold the contents densely; reading a slot is check-the-bit then index-by-popcount. Carries the interactive figure.
2. `#advanced` — **Advanced: against the HAMT node**: contrasts CHAMP's two-bitmap split against a HAMT node's single mixed array, shows the `Bitwise` `entry?`/`child?`/`data_index` helpers, and ties the compact node to the stack's `BrandedChamp` trie. Closes with a `.bridge` (`F4.04 · one bitmap, one mixed array` → `F4.06.1 · two bitmaps, two packed arrays`) and a `.note` pointing to iteration.

Running example: an 8-of-32-slot node with `datamap` bits at slots 1 and 4 (`entries[]` of two), `nodemap` bits at slots 2 and 6 (`nodes[]` of two), and the worked index `data_index(datamap, 4) = popcount(bits 0..3) = 1 → entries[1]`.

Real Elixir code shown (advanced section, verbatim):

```
import Bitwise

# is slot i an inline entry? a child? — test the two bitmaps
def entry?(datamap, i), do: (datamap &&& (1 <<< i)) != 0
def child?(nodemap, i), do: (nodemap &&& (1 <<< i)) != 0

# position in the packed array = popcount of the lower bits
def data_index(datamap, i), do: popcount(datamap &&& ((1 <<< i) - 1))
# data_index(datamap, 4) = popcount(bits 0..3) = 1  ->  entries[1]
```

## The interactives

### Teaching figure — "What to read · select one" (`#bits`, `aria-labelledby="laTitle"`)

- Control group `#laSel` (role group, label `What to read`): button `data-k="datamap"` `data-c="sage"` (active) label `datamap`; `data-k="nodemap"` `data-c="blue"` label `nodemap`; `data-k="popcount"` `data-c="gold"` label `popcount`.
- SVG element ids: datamap/nodemap highlight rects `laDmapHi`/`laNmapHi`; bit rects `laDmap1`, `laDmap4`, `laNmap2`, `laNmap6`; packed arrays `laDataArr`/`laNodeArr`; popcount banner group `laPop`; caption `laCaption`; code/readout `#laCode`, `#laOut`; role `#laRole`, result `#laResult`.
- Pure function: `pick(k)` reads `CASES[k]` and sets the two highlight opacities, the two array stroke-widths, the popcount-banner opacity, and swaps caption/role/result/code/out. Default `pick('datamap')`.
- Static popcount banner text in markup: `slot 4 is set in datamap — its index in entries[] is:` and `popcount(datamap below slot 4) = 1 set bit (slot 1) → entries[1]`.
- Readout strings VERBATIM (the three `CASES`):
  - `datamap` — caption `datamap marks slots 1 and 4 — two entries, packed`; role `which slots hold entries`; result `datamap → 2 packed entries`; out `The datamap records which slots hold inline entries — here slots 1 and 4. The entries array holds exactly those two, packed in order, with nothing in between.`
  - `nodemap` — caption `nodemap marks slots 2 and 6 — two children, packed`; role `which slots hold sub-nodes`; result `nodemap → 2 packed sub-nodes`; out `The nodemap records which slots hold child nodes — here slots 2 and 6 — in a second packed array. A slot is in one map or the other, never both, so the two never collide.`
  - `popcount` — caption `index in entries[] = popcount of the lower datamap bits`; role `popcount gives the array index`; result `index = popcount(datamap & lower bits)`; out `To turn a slot into an array position, popcount the bitmap bits below it. Slot 4 has one set bit beneath it (slot 1), so its entry is at entries[1] — constant time, one instruction.`
- Take (verbatim): `A bitmap plus a popcount replaces a 32-wide array of mostly-empty slots with a compact one. The node stores two small arrays and two integers, and still finds any slot in constant time.`
- Degrade behaviour: the figure SVG is fully authored in the markup (default state shows the `datamap` view), so it reads with no JS; `prefers-reduced-motion: reduce` disables the `arc-flow` dash flow and the reveal transition.

### Footer build-stamp decoder

- `#stampId` text: `TSK0NbfRwTKzr6`; the panel's authored `st-ts` is `2026-05-31 20:47:04 UTC`.
- Decoder: `decodeBranded` strips the `TSK` namespace, base62-decodes the remainder, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FF`, `seq = snow & 0xFFF`, `EPOCH_MS = 1704067200000`. Decoded timestamp: `2026-05-31 20:47:04 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for the CHAMP node layout, and where it connects in the course.`

Sources:
- `https://michael.steindorfer.name/publications/oopsla15.pdf` — Steindorfer & Vinju, "Optimizing Hash-Array Mapped Tries for Fast and Lean Immutable JVM Collections" (OOPSLA 2015) — the CHAMP paper, DOI 10.1145/2814270.2814312.
- The Morning Paper, "CHAMP — optimizing hash-array mapped tries" (2015) — a walkthrough of the structure. (No external link on this entry — plain text.)

Related in this course:
- `/elixir/algorithms/champ`
- `/elixir/algorithms/champ/iteration`
- `/elixir/algorithms/maps`

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / champ / layout` (the trailing `layout` is the `.rcur` current segment; `elixir`, `algorithms`, `champ` are links).
- crumbs (verbatim): `F4` (link to `/elixir/algorithms`) / `F4.06` (link to `/elixir/algorithms/champ`) / `layout` (here).
- toc-mini: `#bits` → `Two bitmaps, two arrays`; `#advanced` → `Advanced: against the HAMT node`.
- pager: prev → `/elixir/algorithms/champ` label `← F4.06 · champ`; next → `/elixir/algorithms/champ/iteration` label `Next · iteration →`.
- footer: identical to the hub — column **Chapters** (`/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`) and column **The course** (`/elixir`, `/elixir/course`, `/elixir/algebra/functions`); foot-tag `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta: `<title>` = `Compressed node layout — F4.06.1 · jonnify`. `<meta description>` = `A CHAMP node carries a datamap and a nodemap — two bitmaps marking which of its 32 slots hold inline entries and which hold sub-nodes — and stores each kind in its own packed array with no empty cells. A slot's position in an array is the popcount of the lower bits of the matching bitmap.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure-`pick` + Snowflake-decoder IIFE and the reveal-on-scroll enhancer) verbatim from a recent BUILT F4.06 sibling on the sage accent, then change only `<title>`/`<meta description>`, the `route-tag` segments, and the `<main>` body. Keep the dive lede styling (`.hero-copy .lede` upright lead paragraph), the `#advanced` section, the `.bridge`, the `.note`, and the `#refs` block. No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE Portal facade, the Phoenix web app — and the only code shown is the illustrative `Bitwise`/`entry?`/`child?`/`data_index` helpers and the `Champ.Node` shape; do not invent extra arities, struct fields, or a `popcount` signature beyond what is shown. Cite the companion course for BEAM/`Bitwise` internals; do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/algorithms/champ/iteration.html` (the next F4.06 dive on the same sage accent and identical chrome).
