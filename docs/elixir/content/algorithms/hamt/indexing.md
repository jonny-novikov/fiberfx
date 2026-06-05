# F4.05.2 — Hash-prefix indexing (dive)

- Route (served): `/elixir/algorithms/hamt/indexing`
- File: `elixir/algorithms/hamt/indexing.html`
- Place in the chapter: dive 2 of 3 under the `F4.05` HAMT hub, the **descent** step of the arc node → descent → sharing. It teaches how the key's hash chooses a path down the tree, five bits per level. It follows `bitmap` (the node) and precedes `sharing` (the edit).
- Accent: sage (F4 · Algorithms & Data Structures).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.05 · part 2 of 3`

H1: Hash-prefix `indexing` (the word `indexing` in the `.ex` elixir-accent span).

Hero lede (verbatim):

> A flat table reduced the whole hash to one slot with a single modulo. A trie reads the hash in pieces: five bits choose a slot at the root, the next five choose a slot in that child, and so on down. Each five-bit chunk picks one of 32 slots, so a key's path is its hash, read five bits at a time, until it reaches a leaf.

Kicker (verbatim):

> Descending on the registry key `"/elixir/algorithms/maps"`, whose `phash2` is the same `48721903` from F4.04. Select a level to see which bits it reads.

## Sections

In order:
1. `Five bits at a time` (`#descend`) — the teaching section. The hash is a fixed integer consumed in five-bit chunks from the low end: level 0 reads bits 0–4, level 1 reads bits 5–9, and so on, each chunk naming a slot in the current node; a lookup repeats the same chunking. Carries the interactive figure. Closes on a `.take`: "A key's path is its hash, read five bits per level. Because each step is a constant-time slot pick and the tree is about four levels deep for millions of keys, the whole descent is treated as O(1)."
2. `Advanced: depth and collisions` (`#advanced`) — the advanced section. Depth is about `log₃₂ n` (roughly four levels for millions of keys, six for a fully-spread 32-bit hash); keys sharing low bits share a path and split at the first differing chunk; a true full-hash collision is held in a small collision node at the bottom; a map of at most 32 keys stays a flat sorted array. Notes that any term keys the same way, so branded Snowflake `PGE` ids index like a route string. Includes a `slot_at/2` code block and an `F4.04 → F4.05.2` bridge.

Running example: the registry key `"/elixir/algorithms/maps"`, with `phash2` = `48721903` (carried over from F4.04), split into five-bit chunks `15` (bits 0–4), `31` (bits 5–9), `27` (bits 10–14) — the descent `root → 15 → 31 → 27 → leaf ⇒ %Page{}`.

Real Elixir shown (advanced block, verbatim):

```
import Bitwise

# the slot at a given level = a five-bit chunk of the hash
def slot_at(hash, level) do
  (hash >>> (5 * level)) &&& 0b11111   # 0b11111 = 31, a 5-bit mask
end

# slot_at(48721903, 0) = 15 · slot_at(48721903, 1) = 31 · slot_at(48721903, 2) = 27
# descend root -> 15 -> 31 -> 27 -> leaf; depth grows as log32 n
```

## The interactives

### Figure — "The level · select one"
- `<figure class="fig">` labelled by `#ixTitle`; control group `#ixSel` (`solid-select`, `role="group"`, label "The descent level") with three buttons:
  - `data-k="0"` `data-c="sage"` (active) — label `level 0`
  - `data-k="1"` `data-c="blue"` — label `level 1`
  - `data-k="2"` `data-c="gold"` — label `level 2`
- SVG ids: chunk boxes `#ixC0` / `#ixC1` / `#ixC2` (bits 0–4 = 15, 5–9 = 31, 10–14 = 27); node boxes `#ixN0` / `#ixN1` / `#ixN2`; leaf `#ixLeaf`; caption `#ixCaption`. Readout block `#ixCode`, `#ixOut`, plus `#ixRole` and `#ixResult` lines.
- Pure functions: `HASH = 48721903`; `chunk(level)` returns `(HASH >>> (5 * level)) & 31`; `pick(k)` recolours the selected chunk/node/leaf and writes the caption, role, result, code and readout. Runs `pick('0')` on load.
- Per-level role strings (`META`, verbatim): level 0 → `a hash chunk to a slot`; level 1 → `the next chunk, the next node`; level 2 → `the last chunk reaches a leaf`.
- Default static caption in markup (verbatim): `level 0 reads bits 0–4 = 15 — the root slot`. Default result line: `level 0 → slot 15`. The dynamic caption template reads `level N reads bits a–b = chunk — …`, with the level-2 tail "— slot 27, then the leaf", level-0 tail "— the root slot", else "— a child slot".
- Readout (`#ixOut`) template (verbatim, HTML stripped): "Level N reads **bits a–b of the hash**, which is `chunk`. That names the slot to follow in the current node[, and this one points at the leaf holding the page.] / [, leading one level deeper.]"
- Code (`#ixCode`) template (verbatim): `slot_at(48721903, N) = (48721903 >>> 5*N) &&& 31` then `# = chunk   ->  follow slot chunk at level N`.

### Footer build-stamp decoder
- `#stamp` carries `build TSK0NcUcXs4muG`. The Branded Snowflake decoder (B62 → snowflake, `EPOCH_MS = 1704067200000`, namespace `TSK`) decodes ts/node/seq on activation. Pre-rendered timestamp in markup: `2026-06-01 08:43:08 UTC`.
- Degrade: the figure renders meaningfully at its `level 0` static default; reveal-on-scroll on References is JS-gated and disabled under `prefers-reduced-motion: reduce`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- Bagwell, P. (2001). *Ideal Hash Trees.* — the original HAMT paper. (Not a link on this page — plain text.)
- Hash array mapped trie — Wikipedia — the structure in brief. `https://en.wikipedia.org/wiki/Hash_array_mapped_trie`

Related in this course:
- F4.05 · Hash Array Mapped Tries — `/elixir/algorithms/hamt`
- F4.04 · Maps, sets & hashing — `/elixir/algorithms/maps`
- F4.06 · CHAMP maps — `/elixir/algorithms/champ`

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `algorithms` `/ ` `hamt` `/ ` `indexing` — `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, `hamt` → `/elixir/algorithms/hamt`, `indexing` the current `.rcur` segment.
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) · `F4.05` (→ `/elixir/algorithms/hamt`) · `indexing` (`.here`).
- toc-mini: `Five bits at a time` (`#descend`) · `Advanced: depth and collisions` (`#advanced`).
- pager: prev → `/elixir/algorithms/hamt/bitmap` label `← F4.05.1 · bitmap`; next → `/elixir/algorithms/hamt/sharing` label `Next · sharing →`.
- footer: identical three-column course footer — brand/tagline, `Chapters` (`/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`), `The course` (`/elixir`, `/elixir/course`, `/elixir/algebra/functions`).
- Page meta — `<title>`: `Hash-prefix indexing — F4.05.2 · jonnify`. `<meta description>`: "A HAMT reads the key's hash in five-bit chunks from the low end: level 0 reads bits 0-4, level 1 reads bits 5-9, each chunk naming one of 32 slots, so a key's path is its hash read five bits at a time and depth grows as log32 n. Any term keys the same way, so branded Snowflake ids index like a route string."

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the trailing script blocks (the figure `META`/`chunk`/`pick` selector, plus the Branded Snowflake decoder + reveal-on-scroll) verbatim from a recent BUILT sibling on the F4 sage accent — the parallel dive `elixir/algorithms/hamt/bitmap.html` or the hub `elixir/algorithms/hamt/index.html`. Change only `<title>` / `<meta description>`, the route-tag, the crumbs/toc/pager, and the `<main>` body (hero, `#descend` figure, `#advanced`, references). No-invent guards: cite only the real surfaces as written — five-bit hash chunks via `slot_at/2`, `phash2("/elixir/algorithms/maps") = 48721903`, `log₃₂ n` depth, collision nodes at the bottom, and the branded `PGE` Snowflake id hashing like a route string into the page registry; do not re-teach BEAM/OTP internals or invent Portal API. Voice rules: no first person, no exclamation marks, no emoji, none of "just" / "simply" / "obviously". Model sibling to copy from: `elixir/algorithms/hamt/bitmap.html`.
