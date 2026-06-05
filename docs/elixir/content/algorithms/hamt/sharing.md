# F4.05.3 — Structural sharing (dive)

- Route (served): `/elixir/algorithms/hamt/sharing`
- File: `elixir/algorithms/hamt/sharing.html`
- Place in the chapter: dive 3 of 3 under the `F4.05` HAMT hub, the **sharing** step of the arc node → descent → sharing, and the close of module `F4.05`. It teaches how an insert copies the root-to-leaf path and shares every other sub-tree, making the structure persistent. It follows `bitmap` and `indexing`, and hands the persistent-map spine forward to `F4.06` (CHAMP).
- Accent: sage (F4 · Algorithms & Data Structures).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.05 · part 3 of 3`

H1: Structural `sharing` (the word `sharing` in the `.ex` elixir-accent span).

Hero lede (verbatim):

> The trie nodes are immutable, so an insert cannot edit them in place. Instead it builds new nodes only along the path from the root to the changed leaf, and reuses every other sub-tree exactly as it was. The result is a second map that shares almost all of its structure with the first — and the first map is still there, unchanged.

Kicker (verbatim):

> Adding one page to the registry, `"PGE0NcQgyPQEbI"`, turning version `v1` into `v2`. Select what to highlight.

## Sections

In order:
1. `Copy the path, share the rest` (`#share`) — the teaching section. An insert walks the new key's hash down the tree, rebuilding each node it passes and leaving everything off that path untouched; the new root points to the rebuilt path and to the old, shared sub-trees. Carries the interactive figure. Closes on a `.take`: "An insert costs new nodes only along one root-to-leaf path — about `log₃₂ n` of them — and shares the rest. That is what makes an immutable map cheap to update and its old versions free to keep."
2. `Advanced: persistence and snapshots` (`#advanced`) — the advanced section. A sequence of edits is a sequence of overlapping versions; a hundred edits cost a hundred short paths, not a hundred copies — the meaning of a **persistent** data structure. For the page registry this lets a LiveView diff two snapshots by comparing references and skip shared sub-trees; `F4.06` (CHAMP) keeps the sharing and adds a **canonical** shape, and the stack's `BrandedChamp` trie (F4.07) is that structure keyed by branded Snowflake ids. Includes a `v1`/`v2` `Map.put` code block and an `F4.05.3 → F4.06` bridge.

Running example: adding page `"PGE0NcQgyPQEbI"` to a three-page registry `v1`, producing `v2`; in the SVG, shared sub-trees `A` and `C`, the original `node B`, the rebuilt `node B′`, and the `+ new leaf` — `v2` rebuilds the root, the path node, and the new leaf (three nodes).

Real Elixir shown (advanced block, verbatim):

```
# v1 holds three pages; adding one returns v2 — v1 is untouched
v1 = %{"PGE0NXh7MFjxT6" => modules, "PGE0NbLeJJpTmr" => sorting, "PGE0NbWMtkolM0" => maps}
v2 = Map.put(v1, "PGE0NcQgyPQEbI", trees)

# only the nodes on the path to the new leaf are rebuilt
# v2's other sub-trees are the same references as v1's — shared, not copied
v1["PGE0NbWMtkolM0"] == v2["PGE0NbWMtkolM0"]   # true; v1 still works
```

## The interactives

### Figure — "What to highlight · select one"
- `<figure class="fig">` labelled by `#shTitle`; control group `#shSel` (`solid-select`, `role="group"`, label "What to highlight") with three buttons:
  - `data-k="copied"` `data-c="gold"` (active) — label `copied path`
  - `data-k="shared"` `data-c="sage"` — label `shared sub-trees`
  - `data-k="persist"` `data-c="blue"` — label `both versions`
- SVG ids: roots `#shV1Root` / `#shV2Root`; shared sub-trees `#shA` / `#shC`; path nodes `#shB` (original) / `#shBp` (rebuilt `B′`); new leaf `#shLeaf`; edges `#shEA1` `#shEC1` `#shEA2` `#shEC2` `#shEB1` `#shEBp` `#shELeaf`; caption `#shCaption`. Readout block `#shCode`, `#shOut`, plus `#shRole` and `#shResult` lines.
- Pure helpers: `box(id, txt, on, color, fill)` and `edge(id, on, color)` recolour each node/edge; `pick(k)` reads the `CASES` table and toggles which boxes/edges are lit, then writes caption, role, result, code and readout. Default `pick('copied')`.
- Default static caption in markup (verbatim): `v2 rebuilds the root, the path node, and the new leaf — three nodes`. Default role: `copy only the path`; default result: `3 rebuilt, the rest shared`.
- Readout strings (`out`, verbatim, HTML stripped):
  - `copied`: "An insert rebuilds **only the nodes on the path** from the root to the new leaf — here the root, one node B′, and the leaf itself. Three new nodes; nothing else is touched." (caption: `v2 rebuilds the root, the path node, and the new leaf — three nodes`; role: `copy only the path`; result: `3 rebuilt, the rest shared`).
  - `shared`: "Every sub-tree off the insert path — **A and C here** — is reused by reference, identical to v1's. The map shares almost all of its structure, so the new version costs only the rebuilt path." (caption: `sub-trees A and C are shared — pointer-identical with v1`; role: `reuse everything off the path`; result: `2 sub-trees shared, not copied`).
  - `persist`: "Because nothing was edited in place, **v1 is unchanged** and still usable; v2 lives alongside it, sharing all but the copied path. Keeping both — a snapshot history — is nearly free." (caption: `v1 still points only to its own nodes — unchanged and usable`; role: `the old map survives`; result: `v1 intact, v2 alongside it`).

### Footer build-stamp decoder
- `#stamp` carries `build TSK0NcRkn8Uwm8`. The Branded Snowflake decoder (B62 → snowflake, `EPOCH_MS = 1704067200000`, namespace `TSK`) decodes ts/node/seq on activation. Pre-rendered timestamp in markup: `2026-06-01 08:03:01 UTC`.
- Degrade: the figure renders meaningfully at its `copied` static default; reveal-on-scroll on References is JS-gated and disabled under `prefers-reduced-motion: reduce`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- Bagwell, P. (2001). *Ideal Hash Trees.* — the original HAMT paper, where path-copy sharing on insert is set out. `https://lampwww.epfl.ch/papers/idealhashtrees.pdf`
- Hash array mapped trie — Wikipedia — the structure in brief. `https://en.wikipedia.org/wiki/Hash_array_mapped_trie`

Related in this course:
- F4.05 · Hash Array Mapped Tries (HAMT) — `/elixir/algorithms/hamt`
- F4.04 · Maps, sets & hashing — `/elixir/algorithms/maps`
- F4.06 · CHAMP maps — the compressed successor that keeps this sharing. `/elixir/algorithms/champ`

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `algorithms` `/ ` `hamt` `/ ` `sharing` — `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, `hamt` → `/elixir/algorithms/hamt`, `sharing` the current `.rcur` segment.
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) · `F4.05` (→ `/elixir/algorithms/hamt`) · `sharing` (`.here`).
- toc-mini: `Copy the path, share the rest` (`#share`) · `Advanced: persistence and snapshots` (`#advanced`).
- pager: prev → `/elixir/algorithms/hamt/indexing` label `← F4.05.2 · index`; next → `/elixir/algorithms` label `Back to F4 · Algorithms & Data Structures →`.
- footer: identical three-column course footer — brand/tagline, `Chapters` (`/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`), `The course` (`/elixir`, `/elixir/course`, `/elixir/algebra/functions`).
- Page meta — `<title>`: `Structural sharing — F4.05.3 · jonnify`. `<meta description>`: "An insert builds new nodes only along the path from the root to the changed leaf and shares every other sub-tree by reference, so the old map stays intact and a new version costs about log32 n nodes. That persistence makes a snapshot history nearly free — the basis for cheap LiveView diffs and the spine that leads to CHAMP."

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the trailing script blocks (the figure `CASES`/`box`/`edge`/`pick` selector, plus the Branded Snowflake decoder + reveal-on-scroll) verbatim from a recent BUILT sibling on the F4 sage accent — the parallel dive `elixir/algorithms/hamt/bitmap.html` or the hub `elixir/algorithms/hamt/index.html`. Change only `<title>` / `<meta description>`, the route-tag, the crumbs/toc/pager, and the `<main>` body (hero, `#share` figure, `#advanced`, references). No-invent guards: cite only the real surfaces as written — path-copy sharing, pointer-identical reuse of off-path sub-trees, `Map.put/3` returning a new version with `v1` intact, persistence enabling reference-diff LiveView snapshots, and the spine forward to `F4.06` (CHAMP, canonical shape) and the `BrandedChamp` trie (F4.07) keyed by branded Snowflake ids; do not re-teach BEAM/OTP internals or invent Portal API. Voice rules: no first person, no exclamation marks, no emoji, none of "just" / "simply" / "obviously". Model sibling to copy from: `elixir/algorithms/hamt/bitmap.html`.
