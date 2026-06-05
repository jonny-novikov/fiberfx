# F4.06.3 — Canonical equality (dive)

- Route (served): `/elixir/algorithms/champ/equality`
- File: `elixir/algorithms/champ/equality.html`
- Place in the chapter: the third and closing F4.06 dive. With the node laid out (F4.06.1) and the walk established (F4.06.2), this dive shows the payoff of CHAMP's canonical form — cheap equality and cheap diffs are the same property — and hands the chapter spine to F4.07, where the trie becomes the stack's branded data layer.
- Accent: sage (the F4 chapter accent; the dive-card border on the hub is gold, but the chapter accent is sage).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4.06 · part 3 of 3`

Hero h1 (verbatim): `Canonical equality` (the word `equality` carries the `.ex` accent span).

Hero lede (verbatim):

> Because a CHAMP forbids redundant nodes — entries are inlined as high as they can go, and never share a slot with children — a given set of entries has exactly one tree shape. That **canonical form** is what makes equality cheap: two equal maps are structurally identical, so a comparison can short-circuit on shared sub-trees, and a hash can be cached per node. The same sharing makes a one-entry change touch only the path to it.

Kicker line (verbatim):

> Two registry snapshots as CHAMP maps. Select what to read — the canonical shape, an equality check, or a one-entry diff.

## Sections

In order:

1. `#cmp` — **One shape, cheap comparison** (teaching): equal maps are the same tree; an unequal pair differs only where its entries differ. Carries the interactive figure (two snapshots, A and B).
2. `#advanced` — **Advanced: snapshots & the branded trie**: on the BEAM `==` already compares maps by contents, but a hand-built persistent map's canonical shape keeps that comparison fast (shared terms, cached per-node hash) and turns versioning into a cheap operation; identifies the structure as the stack's `BrandedChamp` trie keyed by branded Snowflake ids, naming the example id `PGE0NbWMtkolM0`. Closes with a `.bridge` (`F4.06.1–2 · compact, canonical nodes` → `F4.07 · the branded CHAMP`) and a `.note` closing F4.06.

Running example: two registry snapshots A and B drawn as small CHAMP trees — identical in the canonical and equal views, with one child of snapshot B highlighted as the only difference in the diff view; the diff is produced by `Registry.put(v1, "/elixir/algorithms/champ", page)`.

Real Elixir code shown (advanced section, verbatim):

```
# canonical form: equal maps are structurally identical
v1 = Registry.snapshot()
v2 = Registry.put(v1, "/elixir/algorithms/champ", page)

v1 == v1                       # true — same tree
v1 == v2                       # false — differ on one path only

# structural sharing: v2 reuses every untouched node from v1
# a history of snapshots costs only the changed sub-trees
```

## The interactives

### Teaching figure — "What to read · select one" (`#cmp`, `aria-labelledby="eqTitle"`)

- Control group `#eqSel` (role group, label `What to read`): button `data-k="canonical"` `data-c="sage"` (active) label `canonical`; `data-k="equal"` `data-c="blue"` label `equal?`; `data-k="diff"` `data-c="gold"` label `diff`.
- SVG element ids: snapshot-A nodes `eqAroot`, `eqA0`, `eqA1`; snapshot-B nodes `eqBroot`, `eqB0`, the highlighted `eqBdiff` with label `eqBdiffT`; the centre symbol `eqSym` with caption `eqSymCap`; figure caption `eqCaption`; code/readout `#eqCode`, `#eqOut`; role `#eqRole`, result `#eqResult`.
- Pure function: `pick(k)` reads `CASES[k]` and recolours the highlighted B-child (`bdiffFill`/`bdiffStroke`/`bdiffTextFill`), swaps the centre symbol/symbol-caption, and the caption/role/result/code/out. Default `pick('canonical')`. Palette constants include `SAGEINK`/`GOLDINK` fills used for the diff node.
- Readout strings VERBATIM (the three `CASES`):
  - `canonical` — symbol `≡` (`≡`), symCap `identical structure`; caption `one canonical shape — the two maps are the same tree`; role `one canonical shape per map`; result `equal maps are identical trees`; out `The CHAMP invariants force a single shape for any set of entries: no node wraps a lone entry, and entries never share a slot with children. So two maps with the same entries are the same tree, drawn identically here.`
  - `equal` — symbol `= true`, symCap `compare structure, short-circuit`; caption `equal: matching sub-trees can be the same term in memory`; role `compare structure, not every key`; result `true, via shared sub-trees`; out `Equality compares the structure, not every key in turn. Sub-trees that are equal are frequently the same term in memory, so a node-by-node check short-circuits — and a cached per-node hash makes it quicker still.`
  - `diff` — symbol `≠` (`≠`), symCap `one sub-tree differs`; caption `one entry changed — only the path to it differs; the rest is shared`; role `shared structure makes diffs cheap`; result `only the changed path differs`; out `Change a single entry and only the path to it is rebuilt — the highlighted sub-tree. Every other node is shared with the previous snapshot, so the diff is that one path, and keeping the history is cheap.`
- Take (verbatim): `A canonical shape collapses equality from "compare every key" to "compare the trees," and a change to one entry leaves the rest of the tree shared. Cheap equality and cheap diffs are the same property seen twice.`
- Degrade behaviour: both snapshot trees are authored in the SVG markup (default canonical view, `≡`), so the figure reads with no JS; `prefers-reduced-motion: reduce` disables the `arc-flow` dash flow and the reveal transition.

### Footer build-stamp decoder

- `#stampId` text: `TSK0NbfRww0Tzc`; the panel's authored `st-ts` is `2026-05-31 20:47:04 UTC`.
- Decoder: `decodeBranded` strips the `TSK` namespace, base62-decodes the remainder, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FF`, `seq = snow & 0xFFF`, `EPOCH_MS = 1704067200000`. Decoded timestamp: `2026-05-31 20:47:04 UTC`. (The advanced prose also displays a sample registry-key id `PGE0NbWMtkolM0`, the `PGE` namespace used for `%Page{}` ids.)

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `https://michael.steindorfer.name/publications/oopsla15.pdf` — Steindorfer & Vinju, "Optimizing Hash-Array Mapped Tries for Fast and Lean Immutable JVM Collections" (OOPSLA 2015) — the CHAMP paper: canonicalisation, the compact node, and cheap equality.
- `https://lampwww.epfl.ch/papers/idealhashtrees.pdf` — Bagwell, "Ideal Hash Trees" (2001) — the HAMT the CHAMP refines.

Related in this course:
- `/elixir/algorithms/champ`
- `/elixir/algorithms/champ/layout`
- `/elixir/algorithms/maps`

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / champ / equality` (the trailing `equality` is the `.rcur` current segment; `elixir`, `algorithms`, `champ` are links).
- crumbs (verbatim): `F4` (link to `/elixir/algorithms`) / `F4.06` (link to `/elixir/algorithms/champ`) / `equality` (here).
- toc-mini: `#cmp` → `One shape, cheap comparison`; `#advanced` → `Advanced: snapshots & the branded trie`.
- pager: prev → `/elixir/algorithms/champ/iteration` label `← F4.06.2 · iteration`; next → `/elixir/algorithms` label `Back to F4 · Algorithms & Data Structures →`.
- footer: identical to the hub — column **Chapters** (`/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`) and column **The course** (`/elixir`, `/elixir/course`, `/elixir/algebra/functions`); foot-tag `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta: `<title>` = `Canonical equality — F4.06.3 · jonnify`. `<meta description>` = `CHAMP maintains one canonical shape per set of entries, so two equal maps are structurally identical trees and equality short-circuits on shared sub-trees. The same sharing makes a one-entry change cheap — only the path to it differs — which is what lets the course diff two registry snapshots.`

## Build instruction

To rebuild this dive, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure-`pick` + Snowflake-decoder IIFE and the reveal-on-scroll enhancer) verbatim from a recent BUILT F4.06 sibling on the sage accent, then change only `<title>`/`<meta description>`, the `route-tag` segments, and the `<main>` body. Keep the dive lede styling, the `#advanced` section, the `.bridge`, the `.note`, and the `#refs` block. No-invent guards: use only the real Portal surfaces as written — the branded store keyed by PGE Snowflake ids (the `PGE0NbWMtkolM0` form shown), the event-sourced engine behind ONE Portal facade, the Phoenix web app — and the only code shown is the illustrative `Registry.snapshot/0` / `Registry.put/3` and `==` comparisons; do not invent further `Registry`/`BrandedChamp` functions or arities. Cite the companion course for BEAM term-equality and hashing internals; do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/algorithms/champ/iteration.html` (the preceding F4.06 dive on the same sage accent and identical chrome).
