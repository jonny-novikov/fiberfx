# F4.05.1 — Bitmapped nodes (dive)

- Route (served): `/elixir/algorithms/hamt/bitmap`
- File: `elixir/algorithms/hamt/bitmap.html`
- Place in the chapter: dive 1 of 3 under the `F4.05` HAMT hub, in the arc **node → descent → sharing**. It teaches how one HAMT node packs its slots: a single bitmap plus one packed array, indexed by popcount. It precedes `indexing` (the descent) and `sharing` (the edit).
- Accent: sage (F4 · Algorithms & Data Structures).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.05 · part 1 of 3`

H1: Bitmapped `nodes` (the word `nodes` in the `.ex` elixir-accent span).

Hero lede (verbatim):

> A HAMT node could be a 32-element array, but most slots in most nodes are empty, so that wastes space. Instead a node keeps one 32-bit **bitmap** — a bit set for each occupied slot — and one packed array holding only the occupants, in slot order. To find a slot's position in that array you take a **popcount**: the number of set bits below it.

Kicker (verbatim):

> A node with entries at slots 1 and 6 and a child at slot 4 (8 of 32 slots shown). One array holds all three. Select what to read.

## Sections

In order:
1. `One bitmap, one array` (`#bits`) — the teaching section. The bitmap says which slots are used; the array holds the contents densely; reading a slot is "test the bit, then index into the array by the popcount of the lower bits." Carries the interactive figure. Closes on a `.take`: "A bitmap plus a popcount replaces a 32-wide array of mostly-empty slots with a compact one. The node stores one small array and one integer, and still finds any slot in constant time."
2. `Advanced: leaves and children, mixed` (`#advanced`) — the advanced section. The one array holds two kinds of cell (an inline entry and a child node), needing a tag or side table to tell them apart; "That mixing is the one compromise the layout makes, and it is the thing F4.06 removes by keeping **two** bitmaps and two arrays, one per kind." Includes an `import Bitwise` code block (`occupied?/2` and `index/2` via `popcount`) and an `F4.05.1 → F4.06` bridge.

Running example: a node with entries at slots `1` and `6` and a child at slot `4` (8 of 32 slots shown), backed by the `slots[]` packed array; the worked index is `index(bitmap, 4) = 1 → slots[1]`.

Real Elixir shown (advanced block, verbatim):

```
import Bitwise

# is slot i occupied? — test the one bitmap
def occupied?(bitmap, i), do: (bitmap &&& (1 <<< i)) != 0

# position in the packed array = popcount of the lower bits
def index(bitmap, i), do: popcount(bitmap &&& ((1 <<< i) - 1))
# index(bitmap, 4) = popcount(bits 0..3) = 1  ->  slots[1]
# each slots[] cell is a leaf or a child — a tag says which
```

## The interactives

### Figure — "What to read · select one"
- `<figure class="fig">` labelled by `#bmTitle`; control group `#bmSel` (`solid-select`, `role="group"`, label "What to read") with three buttons:
  - `data-k="bitmap"` `data-c="sage"` (active) — label `bitmap`
  - `data-k="array"` `data-c="blue"` — label `packed array`
  - `data-k="popcount"` `data-c="gold"` — label `popcount`
- SVG ids: `#bmHi` (sage highlight band), `#bmB1` / `#bmB4` / `#bmB6` (the set bitmap cells), `#bmArr` (the packed array bar), `#bmPop` (the popcount worked overlay, opacity-toggled), `#bmCaption`. Readout block `#bmCode`, `#bmOut`, plus `#bmRole` and `#bmResult` lines.
- `pick(k)` reads the `CASES` table; sets the highlight fill/opacity, array stroke, popcount overlay, caption, role, result, code and readout. Runs `pick('bitmap')` on load.
- Static default caption in markup (verbatim): `bitmap marks slots 1, 4 and 6 — three occupants, packed`. Default role: `which slots are occupied`; default result: `bitmap → 3 packed slots`.
- Readout strings (`out`, verbatim, HTML stripped):
  - `bitmap`: "The **bitmap** records which of the 32 slots are occupied — here slots 1, 4 and 6. The `slots` array holds exactly those three, packed in slot order, with nothing in between." (caption: `bitmap marks slots 1, 4 and 6 — three occupants, packed`; result: `bitmap → 3 packed slots`).
  - `array`: "The **packed array** holds the three occupants in slot order. Two are inline entries and one is a child node — both kinds live in this one array, which is the trait F4.06 changes." (caption: `the array holds the three occupants — two leaves and a child`; role: `the contents, densely packed`; result: `slots[] = {leaf, child, leaf}`).
  - `popcount` case follows the same `CASES`/`pick` shape (gold accent), driving the `#bmPop` worked overlay reading `slot 4 is set — its index in slots[] is:` / `popcount(bitmap below slot 4) = 1 set bit (slot 1) → slots[1]`.

### Footer build-stamp decoder
- `#stamp` carries `build TSK0NcRkmfpSdc`. The Branded Snowflake decoder (B62 → snowflake, `EPOCH_MS = 1704067200000`, namespace = first 3 chars `TSK`) decodes ts/node/seq on activation. Pre-rendered timestamp in markup: `2026-06-01 08:03:01 UTC`.
- Degrade: figure is meaningful statically (default bitmap state rendered in markup); the reveal-on-scroll on the References section is JS-gated and disabled under `prefers-reduced-motion: reduce`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- Bagwell, "Ideal Hash Trees" (2001) — the original HAMT paper. `https://lampwww.epfl.ch/papers/idealhashtrees.pdf`
- Hash array mapped trie — Wikipedia — the structure in brief. `https://en.wikipedia.org/wiki/Hash_array_mapped_trie`

Related in this course:
- F4.05 · Hash Array Mapped Tries (HAMT) — `/elixir/algorithms/hamt`
- F4.04 · Maps, sets & hashing — `/elixir/algorithms/maps`
- F4.06 · CHAMP maps — `/elixir/algorithms/champ`

## Wiring

- route-tag (verbatim): `/ ` `elixir` `/ ` `algorithms` `/ ` `hamt` `/ ` `bitmap` — `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, `hamt` → `/elixir/algorithms/hamt`, `bitmap` the current `.rcur` segment.
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) · `F4.05` (→ `/elixir/algorithms/hamt`) · `bitmap` (`.here`).
- toc-mini: `One bitmap, one array` (`#bits`) · `Advanced: leaves and children, mixed` (`#advanced`).
- pager: prev → `/elixir/algorithms/hamt` label `← F4.05 · hamt`; next → `/elixir/algorithms/hamt/indexing` label `Next · indexing →`.
- footer: identical three-column course footer — brand/tagline, `Chapters` (`/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`), `The course` (`/elixir`, `/elixir/course`, `/elixir/algebra/functions`).
- Page meta — `<title>`: `Bitmapped nodes — F4.05.1 · jonnify`. `<meta description>`: "A HAMT node keeps one 32-bit bitmap marking which of its slots are occupied and one packed array holding only the occupants, in slot order; a slot's position in the array is the popcount of the lower bits. The single array mixes inline entries and child nodes — the one compromise that F4.06 removes with two bitmaps and two arrays."

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the trailing script blocks (the figure `CASES`/`pick` selector, plus the Branded Snowflake decoder + reveal-on-scroll enhancement) verbatim from a recent BUILT sibling on the F4 sage accent — the simplest model is its own hub `elixir/algorithms/hamt/index.html` or the parallel dive `elixir/algorithms/hamt/sharing.html`. Change only `<title>` / `<meta description>`, the route-tag, the crumbs/toc/pager, and the `<main>` body (hero, `#bits` figure, `#advanced`, references). No-invent guards: cite only the real surfaces as written — the bitmap+packed-array node, `popcount`-by-lower-bits indexing, the leaf/child mixing that `F4.06` (CHAMP) removes with two bitmaps and two arrays, and the page registry stored in nodes like this keyed on a branded id; do not re-teach BEAM/OTP internals or invent Portal API. Voice rules: no first person, no exclamation marks, no emoji, none of "just" / "simply" / "obviously". Model sibling to copy from: `elixir/algorithms/hamt/sharing.html`.
