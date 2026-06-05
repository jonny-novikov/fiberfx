# F4.04.3 — Hashing & collisions (dive)

- Route (served): `/elixir/algorithms/maps/hashing`
- File: `elixir/algorithms/maps/hashing.html`
- Place in the chapter: Last of the three dives under the `F4.04 · maps` hub (`/elixir/algorithms/maps`). It follows `F4.04.2 · sets` and gives the mechanism under both lookup and membership: a hash turns a key into an integer, the integer picks a slot, collisions resolve in place. Its advanced section sketches the 32-way HAMT and hands off directly to `F4.05` — the start of the persistent-map spine that leads to CHAMP and the branded-CHAMP map.
- Accent: sage (chapter accent); the figures' default highlight is `--sage-bright` `#a7c9b1`, with gold (`#f0cd7f`) for the colliding second key.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.04 · part 3 of 3`

Hero h1: Hashing & `collisions` (the word "collisions" carries the `.ex` elixir-bright italic accent).

Lede (verbatim):

> Both a map lookup and a set membership test rest on the same trick: a **hash function** turns a key into an integer, the integer picks a **slot**, and the value lives there — no scanning, so the cost does not grow with the collection. When two keys pick the same slot, that is a **collision**, resolved in place. Elixir's term hash is `:erlang.phash2`.

Kicker (verbatim):

> Hashing the route `"/elixir/algorithms/maps"` to a slot, and watching a second key collide with it. Select a step.

## Sections

In order:

1. **`#hash` — Key, hash, slot** (teaching). The key is hashed to a large integer; reducing modulo the number of slots gives an index; lookups repeat the computation and go straight to the slot; two distinct keys can land together and both are kept. Carries the `#hsSel` step-through figure.
2. **`#advanced` — Advanced: the 32-way HAMT** (advanced). Elixir stores a large map as a hash array mapped trie — a tree consuming the key's hash five bits at a time, branching up to 32 ways per level, depth about `log₃₂ n` (roughly four levels for millions of keys); small maps (≤ 32 keys) stay a flat sorted array; branded Snowflake ids hash like any other key and stay a stable pivot across the BEAM, Node, and Go runtimes. Carries the static `#hsHamtTitle` trie figure. Names `F4.05` as where the trie is built.
3. **References** (`#refs`).

Running example: hashing the route `"/elixir/algorithms/maps"` to a slot in an 8-slot table, plus a colliding second key. Real Elixir code shown in `#advanced`:

```
:erlang.phash2("/elixir/algorithms/maps")     # => 48721903   (a term hash)
:erlang.phash2("/elixir/algorithms/maps", 8)  # => 7          (bounded to one of 8 slots)
%{} |> Map.put("PGE0NbWMtkolM0", page)  # PGE = page namespace
# small map (<= 32 keys): flat sorted array
# large map: a 32-way HAMT keyed by chunks of the hash, depth ~ log32 n
```

## The interactives

### Figure 1 — `#hash`: The step · select one

- `<figure class="fig">`, labelled by `#hsTitle` (`The step · select one`).
- Control group `#hsSel` (`.solid-select`, aria-label "The hashing step") with three buttons:
  - `data-k="hash"` `data-c="sage"` (active by default) — label `hash`
  - `data-k="bucket"` `data-c="blue"` — label `bucket`
  - `data-k="collision"` `data-c="gold"` — label `collision`
- SVG element ids: first key `#hsKey1` (`"/elixir/algorithms/maps"`); second key `#hsKey2` / `#hsKey2T` (`"/elixir/algorithms/sorting"`, hidden until the collision step); integer box `#hsInt` / `#hsIntT` (`48721903`); eight bucket slots `#hsSlot0`–`#hsSlot7` (slot `[7]` highlighted sage by default); caption `#hsCaption`; code `#hsCode`; readout `#hsOut`; role `#hsRole`; result `#hsResult`.
- Pure function: `pick(k)` selects a case and recolours the key/slot rects, toggles the second-key opacity, and writes caption, role, result, code, and out. The `rem 8` label fixes slot `[7]` as the target; no live numeric compute (the hash `48721903` and slot `7` are the worked constants).
- Default caption (`#hsCaption`, verbatim): `phash2 maps the key to an integer`. Default role: `any term to an integer`. Default result: `48721903`.
- (The per-step caption/role/result/out strings for `bucket` and `collision` live in the `CASES` object further down the script; the markup defaults shown above are the `hash` step.)
- Default selection on load: `hash`.

### Figure 2 — `#advanced`: A map as a 32-way trie on the key's hash (static)

- `<figure class="fig">`, labelled by `#hsHamtTitle` (`A map as a 32-way trie on the key's hash`).
- A static (non-interactive) SVG: a ROOT · 32 slots node branching on `bits 0–4 of hash` (slot `5`) to a NODE · 32 slots branching on `bits 5–9 of hash` (slot `9`) to a leaf `"/elixir/algorithms/maps" => %Page{}`. Annotations: `depth ≈ log₃₂ n`, `5 hash bits per level`, `32 = 2⁵ children per node`, `~4 levels for millions of keys`, `so lookup is treated as O(1)`, `small map (≤32): flat array`, `F4.05 builds this trie`.
- No controls; renders fully without JS.

### Footer build-stamp decoder

- `.stamp` `#stamp`, id `#stampId` = `TSK0NbdtNjWd96` (namespace `TSK`; base62 Snowflake decoded client-side with epoch `1704067200000`).
- Decoded timestamp shown in markup (`#st-ts`): `2026-05-31 20:25:17 UTC`.
- Panel fields `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts` populate on load via `decodeBranded`; toggles open on click / Enter / Space.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `Hash table — Wikipedia` — `https://en.wikipedia.org/wiki/Hash_table` — hashing and collisions.
- `Map` / `MapSet` — Elixir documentation — `https://hexdocs.pm/elixir/Map.html` — maps and sets in Elixir.

Related in this course:
- `/elixir/algorithms/maps` — F4.04 · Maps, sets & hashing
- `/elixir/algorithms/sorting` — F4.03 · Sorting & searching
- `/elixir/language/structs` — F3.05 · Structs, maps & keyword lists

## Wiring

- route-tag (verbatim): `/` `elixir` `/` `algorithms` `/` `maps` `/` `hashing` (segments `elixir`, `algorithms`, `maps` link to `/elixir`, `/elixir/algorithms`, `/elixir/algorithms/maps`; `hashing` is the current `.rcur` segment, unlinked).
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) `/` `F4.04` (→ `/elixir/algorithms/maps`) `/` `hashing` (here).
- toc-mini: `#hash` "Key, hash, slot"; `#advanced` "Advanced: the 32-way HAMT".
- pager: prev → `/elixir/algorithms/maps/sets` "F4.04.2 · sets"; next → `/elixir/algorithms` "Back to F4 · Algorithms & Data Structures".
- footer columns: identical to the chapter siblings — brand `jonnify` → `/elixir`; Chapters column (`/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`); The course column (`/elixir`, `/elixir/course`, `/elixir/algebra/functions`).
- Page meta: `<title>` = `Hashing & collisions — F4.04.3 · jonnify`. `<meta description>` = "Maps and sets reach O(1) by hashing: phash2 turns a key into an integer, which picks a slot, and collisions resolve in place. Elixir stores entries in a 32-way HAMT, so depth is about log32 n — the door into F4.05. Branded Snowflake ids hash like any other key."

## Build instruction

To (re)build this page, copy the `head`…`</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the `#hsSel` figure controller + Snowflake decoder, then the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on the F4 sage accent; change only `<title>`/`<meta description>`, the `.route-tag`, and the `<main>` body. This is a dive: keep the hero (eyebrow + h1 + lede + kicker + toc-mini), the one teaching section (`#hash` with the `.solid-select` step figure), the one advanced section (`#advanced` with the static HAMT trie figure, its code block, and `.bridge`), and the References block. No-invent guards: use only the real Portal surfaces as written — `:erlang.phash2` for the term hash, the branded store (Snowflake ids in namespace `PGE`/`TSK` that hash like any term), the event-sourced engine behind ONE Portal facade, and the Phoenix web app; the HAMT and persistent trie belong to `F4.05` and are only sketched here, so do not re-teach OTP or BEAM internals — cite the companion course. Do not fabricate routes, ids, readout strings, code tokens, or reference URLs. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/algorithms/maps/sets.html` (adjacent dive, same accent, same one-teaching-plus-one-advanced anatomy; this dive adds a second static figure in the advanced section).
