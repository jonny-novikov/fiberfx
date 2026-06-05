# F4.06.2 — Cache-friendly iteration (dive)

- Route (served): `/elixir/algorithms/champ/iteration`
- File: `elixir/algorithms/champ/iteration.html`
- Place in the chapter: the second of the three F4.06 dives. With the node layout established in F4.06.1, this dive walks the structure — a pre-order that reads the packed entry array first, then descends — and contrasts the access pattern with a HAMT's interleaved slots before equality (F4.06.3) closes the module.
- Accent: sage (the F4 chapter accent; the dive-card border on the hub is blue, but the chapter accent is sage).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.06 · part 2 of 3`

Hero h1 (verbatim): `Cache-friendly iteration` (the word `iteration` carries the `.ex` accent span).

Hero lede (verbatim):

> Walking a CHAMP is a pre-order over the tree: at each node, yield the packed entry array first, then descend into each child. Because the entries are contiguous and held apart from child pointers, that first step is a linear read of adjacent memory — a much friendlier access pattern than a HAMT, whose single array interleaves entries with pointers and gaps. The order is also **canonical**: the same map always yields its entries in the same sequence.

Kicker line (verbatim):

> The same node, walked as a CHAMP and as a HAMT. Select the step, or compare the layouts.

## Sections

In order:

1. `#walk` — **Entries first, then descend** (teaching): a node's own entries come out before any child's, in slot order; carries the interactive figure that swaps between the CHAMP walk and the HAMT layout.
2. `#advanced` — **Advanced: canonical order & diffs**: ties the traversal to the eager `Enum`/lazy `Stream` story from F3.04, now over a tree; explains the two payoffs — canonical order (deterministic snapshots) and structural sharing (re-read only what changed) — and frames the course page registry's snapshot-and-diff. Closes with a `.bridge` (`F3.04 · Enum walks a collection` → `F4.06.2 · a cache-friendly pre-order`) and a `.note` pointing to equality.

Running example: the same node drawn twice — as a CHAMP (two packed entries numbered 1 and 2, then two children numbered 3 and 4, swept in one contiguous order) and as a HAMT (the same payload scattered with pointers and gaps across eight slots).

Real Elixir code shown (advanced section, verbatim):

```
# pre-order walk: this node's packed entries, then each child
def reduce(%Champ.Node{entries: es, nodes: ns}, acc, fun) do
  acc = Enum.reduce(es, acc, fun)            # contiguous, canonical order
  Enum.reduce(ns, acc, fn child, a -> reduce(child, a, fun) end)
end

# same sequence every time  ->  snapshot, then diff only the changed sub-tree
```

## The interactives

### Teaching figure — "What to read · select one" (`#walk`, `aria-labelledby="itTitle"`)

- Control group `#itSel` (role group, label `What to read`): button `data-k="entries"` `data-c="sage"` (active) label `entries`; `data-k="descend"` `data-c="blue"` label `descend`; `data-k="hamt"` `data-c="gold"` label `vs HAMT`.
- SVG element ids: the CHAMP-node group `itChamp` (entry rects `itE0`/`itE1`, child rects `itN0`/`itN1`) and the HAMT-node group `itHamt`; caption `itCaption`; code/readout `#itCode`, `#itOut`; role `#itRole`, result `#itResult`. The CHAMP/HAMT groups toggle by opacity.
- Pure function: `pick(k)` reads `CASES[k]` and sets the `itChamp`/`itHamt` opacities and swaps caption/role/result/code/out. Default `pick('entries')`.
- Static CHAMP-sweep caption in markup: `one contiguous sweep: entries, then children`.
- Readout strings VERBATIM (the three `CASES`):
  - `entries` — caption `the packed entry array is read first, in canonical slot order`; role `entries are contiguous, read first`; result `walk entries[] linearly`; out `The walk reads the contiguous entries first, in slot order. They sit next to each other in memory, so this is a linear scan with good cache locality — not a hunt across a sparse array.`
  - `descend` — caption `after the entries, descend into each child in order`; role `then descend into the children`; result `recurse into nodes[]`; out `Once the entries are out, the walk descends into each child node in slot order and repeats. Entries before children, left to right — the order is fixed, so it is reproducible.`
  - `hamt` — caption `a HAMT mixes entries, pointers, and gaps across its slots`; role `a HAMT scatters entries among pointers`; result `more cache misses`; out `A HAMT stores entries and child pointers together in one array with gaps. Iterating gets the same elements, but hops between payload and pointers and over empty slots — more cache misses on every node.`
- Take (verbatim): `Contiguous entries turn a node's contribution into a straight-line read; the canonical order makes that read reproducible. A HAMT gets the same answer but pays in cache misses, hopping over gaps and past child pointers.`
- Degrade behaviour: both node groups are authored in the SVG markup (default `itChamp` visible, `itHamt` hidden), so the figure reads with no JS; `prefers-reduced-motion: reduce` disables the `arc-flow` dash flow and the reveal transition.

### Footer build-stamp decoder

- `#stampId` text: `TSK0NbfRwhoXUO`; the panel's authored `st-ts` is `2026-05-31 20:47:04 UTC`.
- Decoder: `decodeBranded` strips the `TSK` namespace, base62-decodes the remainder, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FF`, `seq = snow & 0xFFF`, `EPOCH_MS = 1704067200000`. Decoded timestamp: `2026-05-31 20:47:04 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for the CHAMP traversal, and where it connects in the course.`

Sources:
- `https://michael.steindorfer.name/publications/oopsla15.pdf` — Steindorfer & Vinju, "Optimizing Hash-Array Mapped Tries for Fast and Lean Immutable JVM Collections" (OOPSLA 2015) — the CHAMP paper, which separates entries from sub-nodes for a contiguous, canonical iteration order (DOI 10.1145/2814270.2814312).
- `https://lampwww.epfl.ch/papers/idealhashtrees.pdf` — Bagwell, "Ideal Hash Trees" (2001) — the HAMT layout that interleaves entries and pointers, which CHAMP reorganises.

Related in this course:
- `/elixir/algorithms/champ`
- `/elixir/algorithms/champ/equality`
- `/elixir/algorithms/maps`

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / champ / iteration` (the trailing `iteration` is the `.rcur` current segment; `elixir`, `algorithms`, `champ` are links).
- crumbs (verbatim): `F4` (link to `/elixir/algorithms`) / `F4.06` (link to `/elixir/algorithms/champ`) / `iteration` (here).
- toc-mini: `#walk` → `Entries first, then descend`; `#advanced` → `Advanced: canonical order & diffs`.
- pager: prev → `/elixir/algorithms/champ/layout` label `← F4.06.1 · layout`; next → `/elixir/algorithms/champ/equality` label `Next · equality →`.
- footer: identical to the hub — column **Chapters** (`/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`) and column **The course** (`/elixir`, `/elixir/course`, `/elixir/algebra/functions`); foot-tag `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta: `<title>` = `Cache-friendly iteration — F4.06.2 · jonnify`. `<meta description>` = `Because a CHAMP node keeps its entries contiguous and separate from sub-node pointers, iteration walks the entry array linearly in a canonical order and recurses into sub-nodes after — far fewer cache misses than a HAMT, where entries and pointers are interleaved across a 32-slot array.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure-`pick` + Snowflake-decoder IIFE and the reveal-on-scroll enhancer) verbatim from a recent BUILT F4.06 sibling on the sage accent, then change only `<title>`/`<meta description>`, the `route-tag` segments, and the `<main>` body. Keep the dive lede styling, the `#advanced` section, the `.bridge`, the `.note`, and the `#refs` block. No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE Portal facade, the Phoenix web app — and the only code shown is the illustrative `reduce/3` over a `Champ.Node` and the `Enum.reduce` walk; do not invent extra functions, arities, or struct fields. Cite the companion course (F3.04) for `Enum`/`Stream` and the BEAM for memory/cache behaviour; do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/algorithms/champ/layout.html` (the preceding F4.06 dive on the same sage accent and identical chrome).
