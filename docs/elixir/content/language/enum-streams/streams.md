# F3.04.3 — Lazy streams (dive)

- Route (served): `/elixir/language/enum-streams/streams`
- File: `/Users/jonny/dev/jonnify/elixir/language/enum-streams/streams.html`
- Place in the chapter: the third and final dive under the F3.04 `enum-streams` hub. It closes the eager → lazy arc — `Stream` builds a recipe that runs only when pulled — and hands back to the F3 chapter overview, with F3.05 Structs next.
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3.04 · part 3 of 3`

H1: Lazy streams

Hero lede (verbatim):

> Where `Enum` runs each step to completion, `Stream` builds a **recipe**. `Stream.map` and `Stream.filter` compute nothing on their own; the work happens only when an `Enum` function pulls values through — and only as far as it needs.

Kicker (verbatim):

> That difference is invisible on five records and decisive on a learner's full history. If you want the first three completed lessons, an eager pipeline still scans everything; a lazy one stops the moment it has three.

## Sections

Two teaching sections, over an eight-record history (the running example grows from five records to eight).

1. `#lazy` — "Eager versus lazy": the same pipeline (keep completed lessons, take the first three) over eight records; the `Strategy · select one` interactive (below) toggles strategy and shows how many records each examines. Takeaway: "Same result, different work. `Stream` pulls one element at a time and stops early; `Enum` finishes every step first. On small data it makes no difference — on large or expensive data, it is the difference."
2. `#when` — "When laziness wins": reach for `Stream` when the source is large, when a step is expensive, when you only need part of the result, or when the source has no end at all.

Real Elixir code shown (verbatim, the `#when` static block):

```elixir
# lazy: nothing has run yet, only a recipe
stream =
  history
  |> Stream.map(&decode/1)
  |> Stream.filter(& &1.completed)

# runs now, and only as far as Enum.take needs
first_three = stream |> Enum.take(3)

# an endless source is fine when consumed lazily
Stream.iterate(1, & &1 * 2) |> Enum.take(5)  # => [1, 2, 4, 8, 16]
```

Bridge cells (`Enum · eager` → `Stream · lazy`): "Compute the whole collection now, every step to completion." → "Compute on demand — only the elements that are actually pulled."

Closing note: "That completes F3.04 — the portal can read its collections eagerly or lazily. Next module: **F3.05 — Structs**, where the maps these functions walk gain a name and a shape. Return to the chapter overview." (chapter overview links `/elixir/language`.)

## The interactives

### Section figure — "Strategy · select one"

- `<figure class="fig">`, labelled by `#stTitle` ("Strategy · select one").
- Control group `#stSel` (`role="group"`, `aria-label="Traversal strategy"`), two buttons: `data-k="eager"` (`data-c="blue"`, label `eager · Enum`, default active), `data-k="lazy"` (`data-c="gold"`, label `lazy · Stream`).
- SVG element ids: record-box group `#stRecs` (eight boxes drawn once from the `DONE` array, ids `srec0`–`srec7` and `srect0`–`srect7`); counter text `#stCount`; result text `#stResult`; plus the code panel `#stCode` and readout `#stOut` (both `aria-live="polite"`).
- The running example: `DONE = [true, false, true, false, true, true, false, true]` (eight records, green dot = completed); `NEED = 3`. The lazy strategy examines until the third completed is found — `lazyExamined = 5` (the third completed sits at index 4, so five records are touched).
- The pure dispatch is `pick(k)`; each strategy is an entry in the `STRAT` table (`eager`, `lazy`) with an `examined` count, a `code` string, and an `out`.
  - eager: examines all 8; code `history |> Enum.filter(& &1.completed) |> Enum.take(3)` `# records examined: 8`.
  - lazy: examines 5; code `history |> Stream.filter(& &1.completed) |> Enum.take(3)` `# records examined: 5`.
- Counter/result strings (verbatim): `#stCount` = `records examined: <n> of 8`; `#stResult` = `result: 3 ids`.
- Readout strings (verbatim):
  - eager: `Enum.filter walks all 8 records before Enum.take keeps three. An eager step does its full work no matter how little you need.`
  - lazy: `Stream.filter does nothing until Enum.take pulls. It examines records one at a time and stops at the third completed — 5 here. The last 3 are never touched.`
- Degrade behaviour: the eight record boxes and the `HISTORY · 8 RECORDS (green = completed)` label render statically; the highlight/dim of examined records, the counter, result, code, and readout are JS-populated, defaulting to the `eager` strategy via `pick('eager')`. No motion in this figure; the page's `.reveal` sections fall back to visible under `prefers-reduced-motion: reduce` or no `IntersectionObserver`.

### Footer build-stamp decoder

- `.stamp` `#stamp` with `#stampId` = `TSK0NbFneQ72Js`. The static panel shows timestamp `2026-05-31 14:48:08 UTC`.
- `decodeBranded` splits the 3-char namespace (`TSK`) from the base-62 Snowflake, unpacks `ts >> 22`, `node = (snow >> 12) & 0x3FF`, `seq = snow & 0xFFF` against `EPOCH_MS = 1704067200000`, decoding to `2026-05-31 14:48:08 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/enumerable-and-streams.html` — Enumerables and streams — Elixir documentation — eager versus lazy traversal.
- `https://hexdocs.pm/elixir/Stream.html` — `Stream` — Elixir documentation — lazy enumerables.
- `https://hexdocs.pm/elixir/Enumerable.html` — `Enumerable` protocol — Elixir documentation — what makes a thing enumerable.

Related in this course:
- `/elixir/language/enum-streams` — F3.04 · Enumerables & streams
- `/elixir/language/enum-streams/enum` — Enum, the eager workhorse

## Wiring

- route-tag: `/ elixir / language / enum-streams / streams` (`elixir` → `/elixir`, `language` → `/elixir/language`, `enum-streams` → `/elixir/language/enum-streams`, `streams` current `.rcur`).
- crumbs: `F3` (→ `/elixir/language`) `/` `F3.04` (→ `/elixir/language/enum-streams`) `/` `streams` (`.here`).
- toc-mini: `Eager versus lazy` (`#lazy`), `When laziness wins` (`#when`).
- pager: prev → `/elixir/language/enum-streams/comprehensions` label `← Comprehensions`; next → `/elixir/language` label `F3 overview →`.
- footer: column "Chapters" — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column "The course" — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01. Brand line `jonnify` → `/elixir`; copyright `© jonnify`.
- Page meta: `<title>` = `Lazy streams — F3.04 · jonnify`. `<meta name="description">` = `Stream builds a lazy recipe that computes nothing until an Enum function pulls values through — the same pipeline eager and lazy, early exit, infinite sequences, and when laziness is worth it.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir accent — the natural model is the adjacent dive `/elixir/language/enum-streams/enum.html` (identical head/header/footer, same single-column lesson hero, single `.solid-select` figure with a code panel and `.geo-readout`, bridge, and References block). Change only `<title>`/`<meta>`, the route-tag, the crumbs/toc-mini/pager, and the `<main>` body (the lesson hero, the `#lazy` `Strategy` figure, the `#when` code block and the eager/lazy bridge). No-invent guards: the running example is the learning Portal's history — use only the real Portal surfaces as written (the branded store, the event-sourced engine behind one `Portal` facade, the Phoenix web app); cite the companion course for OTP internals rather than re-teaching them, and keep every Elixir token (`Stream.map`, `Stream.filter`, `Stream.iterate`, `Enum.filter`, `Enum.take`, `&decode/1`, the readout strings, the `[1, 2, 4, 8, 16]` result) exactly as the live page shows them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
