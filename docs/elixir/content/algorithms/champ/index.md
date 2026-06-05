# F4.06 — CHAMP maps (module hub)

- Route (served): `/elixir/algorithms/champ`
- File: `elixir/algorithms/champ/index.html`
- Place in the chapter: the sixth module of F4 · Algorithms & Data Structures and the centre of the persistent-map spine F4.05→F4.09 (HAMT → CHAMP → Snowflake/branded ids → persistence → branded-CHAMP). It frames three dives — compressed node layout, cache-friendly iteration, canonical equality — and hands off to F4.07, where the CHAMP becomes the stack's branded data layer.
- Accent: sage (the F4 chapter accent; `--sage` / `--sage-bright #a7c9b1`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F4 · Persistent maps · module 6`

Hero h1 (verbatim): `CHAMP maps` (the word `maps` carries the `.ex` accent span).

Hero lede (verbatim):

> A **CHAMP** — Compressed Hash-Array Mapped Prefix-tree — is the compressed successor to the HAMT from F4.04. It keeps the same `log₃₂ n` lookup, but lays each node out differently: instead of one array mixing entries and sub-nodes, a node holds **two** bitmaps and **two** densely packed arrays — one for inline entries, one for sub-nodes — with no empty slots.

Kicker line (verbatim):

> That compression buys two things this course leans on: cache-friendly iteration, and a single **canonical** shape per map, which makes equality and snapshot diffs cheap. It is the structure under a persistent page registry, and the basis for the branded-CHAMP trie (F4.09) used as the data layer in the stack.

(Note: the body cites the branded-CHAMP as F4.09; the dive prose and pager point to F4.07 as the next module. Both numbers appear verbatim on the live pages.)

## What the page frames

The hub presents one teaching section (`#node` Inside a CHAMP node), the three-dive directory (`#dives`), and an advanced section (`#advanced` Advanced: why compression pays). The dives are presented as full-width cards (not a `.mods` grid), each with its number, title, summary, route, and chapter-accented left border:

- F4.06.1 — Compressed node layout — `Two bitmaps — datamap and nodemap — and two packed arrays, with a slot's position found by popcount.` — route `/elixir/algorithms/champ/layout` — built (sage left border).
- F4.06.2 — Cache-friendly iteration — `Contiguous entries walk linearly in a canonical order, with far fewer cache misses than a HAMT's interleaved slots.` — route `/elixir/algorithms/champ/iteration` — built (blue left border).
- F4.06.3 — Canonical equality — `One shape per map means equal maps are identical trees, and a one-entry change touches only the path to it.` — route `/elixir/algorithms/champ/equality` — built (gold left border).

The advanced section closes with a `.bridge` (`F4.04 · a 32-way HAMT` → `F4.06 · the compressed CHAMP`) and a `.note` linking the three dives in order, naming predecessor `F4.05 — Hash Array Mapped Tries` and next module `F4.07 — Branded CHAMP maps`.

## The interactives

### Hero figure — "Two compartments, two bitmaps" (`aria-labelledby="hpTitle"`)

- Figcaption title (`#hpTitle`): `Two compartments, two bitmaps`.
- Controls (`.hp-ctrls`): button `#hpAdd` label `▸ insert key`; button `#hpReset` label `reset`.
- SVG element ids: `hpDataBits`, `hpNodeBits`, `hpDataArr`, `hpNodeArr`, count tspans `hpDataN`/`hpDataU` and `hpNodeN`/`hpNodeU`, banner group `hpBanner` with `hpBannerHd`/`hpBannerSub`, caption `#hpCap`.
- Pure functions / scripted model: an `initial()` 8-slot state (slot 2 holds entry `a→1`, slot 5 holds a sub-node) and a fixed `SCRIPT` of four inserts: `{slot:4,key:'b',val:2}` (free → entry added), `{slot:2,key:'c',val:3}` (collides with `a` → promote both to a sub-node), `{slot:5,key:'d',val:4}` (hits an existing sub-node → descends), `{slot:0,key:'e',val:5}` (free → entry added). `dataEntries()` collects data slots in canonical slot order; `nodeCount()` counts node slots; `render()` repaints both bitmap rows, both packed arrays, the popcount counts, and the caption.
- Readout strings VERBATIM. Initial caption (`#hpCap`): `datamap: 1 entry · nodemap: 1 sub-node` then `A free slot lands an entry in the data array; a collision promotes both into a sub-node, moving the bit datamap→nodemap.` Count lines in the SVG: `popcount(datamap) = 1 entry` and `popcount(nodemap) = 1 sub-node`. Banner default `insert` / `—`. Per-insert banners: free slot → head `insert b→2 · slot free`, sub `datamap bit set → entry appended to the data array`; collision → head `insert c→3 · collides with a`, sub `datamap→nodemap: both pairs promoted into a new sub-node`; existing sub-node → head `insert d→4 · slot holds a sub-node`, sub `descends one level — this node is unchanged`. Fixed legend strings: `free slot inserts an entry · collision promotes to a sub-node`, `datamap bit / entry`, `nodemap bit / sub-node`, `8 of 32 slots shown`.

### Teaching figure — "The angle · select one (8 of 32 slots shown)" (`#node`, `aria-labelledby="chTitle"`)

- Control group `#chSel` (role group, label `The angle`): button `data-k="layout"` `data-c="sage"` (active) label `layout`; `data-k="iteration"` `data-c="blue"` label `iteration`; `data-k="equality"` `data-c="gold"` label `equality`.
- SVG element ids: `chDataArr`, `chNodeArr`, badge group `chBadge` (`canonical form` / `one shape per map`), caption `#chCaption`; code/readout `#chCode`, `#chOut`; role `#chRole`, expr `#chExpr`.
- Pure function: `pick(k)` reads the `CASES[k]` record and recolours the two packed arrays, toggles the badge, and swaps the caption/code/role/expr/out. Default `pick('layout')`.
- Readout strings VERBATIM (the three `CASES`):
  - `layout` — caption `two bitmaps, two packed arrays — no empty slots`; role `two bitmaps, two dense arrays`; expr `datamap + nodemap mark the present slots`; out `A CHAMP node keeps two bitmaps and two packed arrays. The datamap says which slots hold inline entries, the nodemap which hold children, and each array stores only the present items — no empty cells to skip.`
  - `iteration` — caption `entries sit contiguously — walk them directly`; role `entries stored contiguously`; expr `iterate the entry array — cache-friendly`; out `Because entries are contiguous and separate from child pointers, iteration sweeps the entry array in a fixed, canonical order, then descends — far fewer cache misses than a HAMT's interleaved layout.`
  - `equality` — caption `one canonical shape per map`; role `one canonical shape per map`; expr `equal maps are identical trees`; out `CHAMP keeps one canonical shape for a given set of entries, so two equal maps are identical trees. Equality and hashing can short-circuit on shared sub-trees, and a one-entry change touches only its path.`
- The static initial-state SVG is authored into the markup (slot 2 entry `a→1`, slot 5 sub-node), so the figure reads correctly with no JS. `prefers-reduced-motion: reduce` disables the `hpIn` insert animation and the `arc-flow` dash flow; the reveal-on-scroll falls back to visible.

### Footer build-stamp decoder

- `#stampId` text: `TSK0NcUnRROMSG`; the panel's authored `st-ts` is `2026-06-01 08:45:36 UTC`.
- Decoder: `decodeBranded` strips the 3-char namespace (`TSK`), base62-decodes the remainder to a snowflake, then `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FF`, `seq = snow & 0xFFF`, with `EPOCH_MS = 1704067200000` (2024-01-01 UTC). Decoded timestamp: `2026-06-01 08:45:36 UTC`.

## References (#refs, verbatim)

Intro line: `Primary sources for this lesson, and where it connects in the course.`

Sources:
- `https://michael.steindorfer.name/publications/oopsla15.pdf` — Steindorfer & Vinju, "Optimizing Hash-Array Mapped Tries for Fast and Lean Immutable JVM Collections" (OOPSLA 2015) — the CHAMP paper (DOI 10.1145/2814270.2814312); the HAMT compression this lesson builds on.
- `https://blog.acolyer.org/2015/11/27/hamt/` — The Morning Paper — CHAMP summary — a walkthrough of the OOPSLA 2015 result.

Related in this course:
- `/elixir/algorithms/maps`
- `/elixir/algorithms/champ/layout`
- `/elixir/algorithms`

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / champ` (the trailing `champ` is the `.rcur` current segment; `elixir` and `algorithms` are links).
- crumbs (verbatim): `F4 · Algorithms & Data Structures` (link to `/elixir/algorithms`) / `F4.06 · champ` (here).
- toc-mini: `#node` → `Inside a CHAMP node`; `#dives` → `Three deep dives`; `#advanced` → `Advanced: why compression pays`.
- pager: prev → `/elixir/algorithms` label `← F4 · Algorithms & Data Structures`; next → `/elixir/algorithms/champ/layout` label `Start · compressed node layout →`.
- footer: column **Chapters** — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column **The course** — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot-tag: `Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir.`
- Page meta: `<title>` = `CHAMP maps — F4.06 · jonnify`. `<meta description>` = `A CHAMP is the compressed successor to the HAMT: same O(log32 n) lookup, but each node splits its slots into two bitmaps and two densely packed arrays — entries and sub-nodes. That compression buys cache-friendly iteration and a canonical shape per map, which makes equality and snapshot diffs cheap. It is the structure under the course's persistent registry and the branded-CHAMP trie in the stack.`

## Build instruction

To rebuild this hub, copy the `head…</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the figure/decoder IIFE and the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling hub on the sage F4 accent, then change only `<title>`/`<meta description>`, the `route-tag` current segment, and the `<main>` body. Keep the hub-specific lede styling (`.hero-lede .lede` upright lead paragraph) and the three-card `#dives` block. No-invent guards: use only the real Portal surfaces as written — the branded store keyed by PGE Snowflake ids, the event-sourced engine behind ONE Portal facade, the Phoenix web app — and the only code shown here is the illustrative `Champ.Node` struct and `Registry` snapshot/put; do not invent further module names, arities, or struct fields. Cite the companion course for OTP/BEAM internals; do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/algorithms/maps/index.html` (the F4.04 hub on the same sage accent); the F4.06 dive heads in this same directory share the identical chrome.
