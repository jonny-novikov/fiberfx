# F4.04.2 — MapSet & membership (dive)

- Route (served): `/elixir/algorithms/maps/sets`
- File: `elixir/algorithms/maps/sets.html`
- Place in the chapter: Second of the three dives under the `F4.04 · maps` hub (`/elixir/algorithms/maps`). It follows `F4.04.1 · lookup` (a map keys values) and precedes `F4.04.3 · hashing` (the mechanism under both). A set keys presence — membership is the same `O(1)` keyed lookup, returning a boolean — grounded in the course's set of built routes that the link checker tests against.
- Accent: sage (chapter accent); the membership figure's default highlight is `--sage-bright` `#a7c9b1`, with blue (`#9fc0ea`) and gold (`#f0cd7f`) for the algebra cases.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.04 · part 2 of 3`

Hero h1: MapSet & `membership` (the word "membership" carries the `.ex` elixir-bright italic accent).

Lede (verbatim):

> A set holds unique elements and answers one question fast: is this element present? `MapSet.member?` does it in O(1), the same keyed lookup as a map. Sets also combine: `union`, `intersection`, and `difference` let you reason about whole collections at once.

Kicker (verbatim):

> The course keeps a set of **built** route strings; the link checker that grades every page asks whether each internal href is in it. Here that set meets the set of all **F4 chapter** routes. Select an operation.

## Sections

In order:

1. **`#ops` — Membership and set algebra** (teaching). Two sets — `built` (routes whose modules are shipped) and `f4` (every route in this chapter); ask membership, or combine the sets. Carries the `#msSel` two-overlapping-sets figure.
2. **`#advanced` — Advanced: a set is a map** (advanced). A `MapSet` is a map whose keys are the elements and whose values are a placeholder, so membership is the `O(1)` map lookup of the previous dive; `MapSet.new/1` deduplicates; the link checker is `MapSet.member?(allowed_routes(), href)` in spirit, the same shape that underlies `Phoenix.Presence`.
3. **References** (`#refs`).

Running example: the course's `built` route set against the `f4` chapter route set. Real Elixir code shown in `#advanced`:

```
MapSet.new([1, 2, 2, 3])    # => MapSet.new([1, 2, 3])
def valid_link?(href), do: MapSet.member?(allowed_routes(), href)
#   set:  is X present? are these unique?      (O(1) membership)
#   list: what is the order? walk them all       (O(n) membership)
#   map:  what value does key X hold?            (O(1) lookup)
```

## The interactives

### Figure — `#ops`: The operation · select one

- `<figure class="fig">`, labelled by `#msTitle` (`The operation · select one`).
- Control group `#msSel` (`.solid-select`, aria-label "The set operation") with three buttons:
  - `data-k="member"` `data-c="sage"` (active by default) — label `member?`
  - `data-k="intersection"` `data-c="blue"` — label `intersection`
  - `data-k="difference"` `data-c="gold"` — label `difference`
- SVG element ids: two overlapping ellipses (`built` sage / `f4 (chapter)` blue) with four chips — `#msChipMod` (`modules`), `#msChipSort` (`sorting`), `#msChipMaps` (`maps`), `#msChipHamt` (`hamt`); caption `#msCaption`; code `#msCode`; readout `#msOut`; role `#msRole`; result `#msResult`.
- Pure function: `pick(k)` selects a case from `CASES` and recolours the chips via `chip(id, fill, stroke, w)`, then writes caption, role, result, code, and out. No numeric compute.
- Readout strings VERBATIM by case:
  - **member** — caption: `"/elixir/algorithms/maps" is in built — member? returns true`; role: `is the route in the set? O(1)`; result: `true`; out: "**member?** tests presence in O(1). The maps route is built, so it returns `true`; the planned HAMT route is not yet in the set, so `false`. This is the check behind every internal link."
  - **intersection** — caption: `in both built and f4 — the shipped F4 modules`; role: `in both sets — built F4 modules`; result: `sorting, maps`; out: "**intersection** keeps only elements in both sets — the F4 routes that are also built. Modules (an F3 route) drops out, and the planned HAMT route drops out."
  - **difference** — caption: `in f4 but not in built — the modules still to ship`; role: `in F4, not yet built`; result: `hamt`; out: "**difference** keeps what is in the first set but not the second: F4 routes that are not yet built. That is the chapter roadmap — the HAMT module and the rest of the spine."
- The case `code` blocks reference `Jonnify.Course.built_routes()`, `Jonnify.Course.chapter_routes("F4")`, `MapSet.member?`, `MapSet.intersection`, and `MapSet.difference`; the planned route shown is `"/elixir/algorithms/maps-hamt"` (returns `false` / appears only under `difference`).
- Default selection on load: `member`.
- Degrade: the SVG renders statically with the `maps` chip highlighted sage and the default caption shown; the controller only recolours chips and rewrites text — the page works without JS as a static figure.

### Footer build-stamp decoder

- `.stamp` `#stamp`, id `#stampId` = `TSK0NbdtNVKgds` (namespace `TSK`; base62 Snowflake decoded client-side with epoch `1704067200000`).
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

- route-tag (verbatim): `/` `elixir` `/` `algorithms` `/` `maps` `/` `sets` (segments `elixir`, `algorithms`, `maps` link to `/elixir`, `/elixir/algorithms`, `/elixir/algorithms/maps`; `sets` is the current `.rcur` segment, unlinked).
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) `/` `F4.04` (→ `/elixir/algorithms/maps`) `/` `sets` (here).
- toc-mini: `#ops` "Membership and set algebra"; `#advanced` "Advanced: a set is a map".
- pager: prev → `/elixir/algorithms/maps/lookup` "F4.04.1 · lookup"; next → `/elixir/algorithms/maps/hashing` "Next · hashing".
- footer columns: identical to the chapter siblings — brand `jonnify` → `/elixir`; Chapters column (`/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`); The course column (`/elixir`, `/elixir/course`, `/elixir/algebra/functions`).
- Page meta: `<title>` = `MapSet & membership — F4.04.2 · jonnify`. `<meta description>` = "A MapSet stores unique elements and answers membership in O(1). Over the course's route sets — built versus planned — MapSet.member? is exactly the links gate, and union, intersection, and difference compose the sets. A MapSet is a map under the hood."

## Build instruction

To (re)build this page, copy the `head`…`</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the `#msSel` figure controller + Snowflake decoder, then the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on the F4 sage accent; change only `<title>`/`<meta description>`, the `.route-tag`, and the `<main>` body. This is a dive: keep the hero (eyebrow + h1 + lede + kicker + toc-mini), the one teaching section (`#ops` with the `.solid-select` two-set figure), the one advanced section (`#advanced` with its code block and `.bridge`), and the References block. No-invent guards: use only the real Portal surfaces as written — the branded store, the set of built routes exposed through `Jonnify.Course` (`built_routes/0`, `chapter_routes/1`), the event-sourced engine behind ONE Portal facade, and the Phoenix web app (`Phoenix.Presence` named only as the same set shape, not re-taught); cite the companion course for OTP internals. Do not fabricate routes, ids, readout strings, code tokens, or reference URLs. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/algorithms/maps/lookup.html` (adjacent dive, same accent, same one-teaching-plus-one-advanced anatomy).
