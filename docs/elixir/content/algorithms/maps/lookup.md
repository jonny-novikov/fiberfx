# F4.04.1 — Maps & key lookup (dive)

- Route (served): `/elixir/algorithms/maps/lookup`
- File: `elixir/algorithms/maps/lookup.html`
- Place in the chapter: First of the three dives under the `F4.04 · maps` hub (`/elixir/algorithms/maps`). It teaches reading and writing a map by key over the course's page registry; it precedes `F4.04.2 · sets` (membership) and `F4.04.3 · hashing`. Part of the persistent-map spine's opening: map fetch is `O(1)`, the trade introduced after sorting's `O(log n)`.
- Accent: sage (chapter accent; the dive's figure default highlight is `--sage-bright` `#a7c9b1`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.04 · part 1 of 3`

Hero h1: Maps & key `lookup` (the word "lookup" carries the `.ex` elixir-bright italic accent).

Lede (verbatim):

> A map associates keys with values and retrieves a value by its key in effectively constant time, no matter how many entries it holds. The course's page registry is exactly this: a map from a route string to a `%Page{}` struct. `Map.get` returns the value or `nil`, `Map.fetch` returns a tagged result, and `Map.put` returns a new map with the entry added or replaced.

Kicker (verbatim):

> Looking up the page for `"/elixir/algorithms/maps"` — this very page — in the registry, and adding a new one. Select an operation.

## Sections

In order:

1. **`#ops` — Three ways to touch a map** (teaching). `Map.get` and `Map.fetch` read by key — the difference is only how they report a miss; `Map.put` writes, returning a fresh map and leaving the original untouched. Carries the `#lkSel` select-an-operation figure.
2. **`#advanced` — Advanced: updates, structs & assigns** (advanced). Strict update syntax `%{map | key => value}` (raises on a missing key) versus `Map.put/3` (always succeeds); a `%Page{}` struct is a map with a hidden `:__struct__` key; a LiveView's `socket.assigns` is a map and `assign/3` returns a new socket — the immutable `Map.put` in disguise.
3. **References** (`#refs`).

Running example: the course page registry — a map from a route string to a `%Page{}` struct. Real Elixir code shown in `#advanced`:

```
%{page | built: true}          # raises if :built is not already a key
Map.put(page, :built, true)    # always returns a new struct
page.__struct__                # => Jonnify.Course.Page
def mount(%{"route" => route}, _session, socket) do
  {:ok, assign(socket, :page, Jonnify.Course.fetch!(route))}
end
```

## The interactives

### Figure — `#ops`: The operation · select one

- `<figure class="fig">`, labelled by `#lkTitle` (`The operation · select one`).
- Control group `#lkSel` (`.solid-select`) with three buttons:
  - `data-k="get"` `data-c="sage"` (active by default) — label `Map.get`
  - `data-k="fetch"` `data-c="blue"` — label `Map.fetch`
  - `data-k="put"` `data-c="gold"` — label `Map.put`
- SVG element ids: query key `#lkKey` (`"/elixir/algorithms/maps"`); registry rows `#lkR0` (`"/elixir/algorithms/maps"`), with static rows for `"/elixir/algorithms/sorting"` and `"/elixir/language/modules"`; new-entry row `#lkNewRow` / `#lkNewText` (`"/elixir/language/under-the-hood"`, hidden until `put`); result box text `#lkSvgRes`; code `#lkCode`; readout `#lkOut`; role `#lkRole`; result `#lkResult`.
- Pure function: `pick(k)` selects a case from `CASES`, sets the `#lkR0` row colours, toggles the new-row opacity (`op('lkNewRow', c.newOp)`), and writes `#lkSvgRes`, `#lkRole`, `#lkResult`, `#lkCode`, `#lkOut`. Helper `row(id, fill, stroke, w)` and `op(id, v)`; no numeric compute.
- Readout strings VERBATIM by case:
  - **get** — svgRes `%Page{}`; role: `value, or nil if absent`; result: `%Page{title: "Maps, sets & hashing"}`; out: "**Map.get** returns the value for a key, or `nil` when the key is absent (or a default you pass as the third argument). Simple, but a missing key and a key whose value is `nil` look the same."
  - **fetch** — svgRes `{:ok, %Page{}}`; role: `tagged: {:ok, v} or :error`; result: `{:ok, %Page{title: "Maps, sets & hashing"}}`; out: "**Map.fetch** reports presence in the return tag: `{:ok, value}` or `:error`. That distinguishes a missing key from a present `nil`, and pattern-matches cleanly in a `case`."
  - **put** — svgRes `4 entries`; role: `insert or overwrite, returns a new map`; result: `pages with the new route added`; out: "**Map.put** adds the key, or overwrites it if present, and hands back a **new** map — the old one is untouched, because maps are immutable. The two maps share most of their structure (F4.05)."
- Default selection on load: `get`.
- Degrade: the SVG renders statically with `#lkR0` highlighted and the result box showing `%Page{}`; the `#lkNewRow`/`#lkNewText` start at opacity `0` and only show under `put`. No motion is gated beyond the JS controller; the page works without JS as a static figure.

### Footer build-stamp decoder

- `.stamp` `#stamp`, id `#stampId` = `TSK0NbdtNGr90a` (namespace `TSK`; base62 Snowflake decoded client-side with epoch `1704067200000`).
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

- route-tag (verbatim): `/` `elixir` `/` `algorithms` `/` `maps` `/` `lookup` (segments `elixir`, `algorithms`, `maps` link to `/elixir`, `/elixir/algorithms`, `/elixir/algorithms/maps`; `lookup` is the current `.rcur` segment, unlinked).
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) `/` `F4.04` (→ `/elixir/algorithms/maps`) `/` `lookup` (here).
- toc-mini: `#ops` "Three ways to touch a map"; `#advanced` "Advanced: updates, structs & assigns".
- pager: prev → `/elixir/algorithms/maps` "F4.04 · maps"; next → `/elixir/algorithms/maps/sets` "Next · MapSet".
- footer columns: identical to the chapter siblings — brand `jonnify` → `/elixir`; Chapters column (`/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix`); The course column (`/elixir`, `/elixir/course`, `/elixir/algebra/functions`).
- Page meta: `<title>` = `Maps & key lookup — F4.04.1 · jonnify`. `<meta description>` = "A map associates keys with values and looks one up in effectively constant time. Over the course's page registry — a map from route to a page struct — Map.get, Map.fetch, and Map.put read and write by key, and a LiveView's socket.assigns is itself just such a map."

## Build instruction

To (re)build this page, copy the `head`…`</style>`, the `header.site`, the `footer.site-foot`, and the two trailing `<script>` blocks (the `#lkSel` figure controller + Snowflake decoder, then the reveal-on-scroll enhancer) verbatim from a recent BUILT sibling on the F4 sage accent; change only `<title>`/`<meta description>`, the `.route-tag`, and the `<main>` body. This is a dive: keep the hero (eyebrow + h1 + lede + kicker + toc-mini), the one teaching section (`#ops` with the `.solid-select` figure), the one advanced section (`#advanced` with its code block and `.bridge`), and the References block. No-invent guards: use only the real Portal surfaces as written — the branded store (`%Page{}` keyed by a branded Snowflake id, decoded via `Jonnify.Course`), the event-sourced engine behind ONE Portal facade, and the Phoenix web app (`assign/3`, `socket.assigns`); cite the companion course for OTP internals, do not re-teach them. Do not fabricate routes, ids, readout strings, code tokens, or reference URLs. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously. Model sibling to copy from: `elixir/algorithms/maps/sets.html` (adjacent dive, same accent, same dive anatomy of one teaching + one advanced section).
