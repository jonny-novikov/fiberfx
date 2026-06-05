# F3.04.2 — Comprehensions (dive)

- Route (served): `/elixir/language/enum-streams/comprehensions`
- File: `/Users/jonny/dev/jonnify/elixir/language/enum-streams/comprehensions.html`
- Place in the chapter: the second of three dives under the F3.04 `enum-streams` hub. It sits between `Enum` (F3.04.1) and lazy `Stream` (F3.04.3), teaching the `for` comprehension as set-builder notation written as code — a second way to walk an enumerable and build a collection.
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3.04 · part 2 of 3`

H1: Comprehensions

Hero lede (verbatim):

> A comprehension — `for` — is a compact way to walk one or more enumerables and build a collection. A **generator** draws elements, a **filter** drops the ones you do not want, and `:into` chooses what the result is collected into. It is set-builder notation, written as code.

Kicker (verbatim):

> The portal uses comprehensions to turn progress records into reports — a list of ids, a map keyed by course, or every valid pairing of course and lesson.

## Sections

Two teaching sections, over the same five progress records (`elixir`/`otp`) as the `Enum` dive.

1. `#build` — "Build a comprehension": each form adds one capability; carries the `Comprehension form · select one` interactive (below). Takeaway: "Read it left to right: draw from a generator, keep what passes the filters, collect into the target. For a single map-or-filter, `Enum` is often clearer; comprehensions earn their keep with multiple generators and `:into`."
2. `#anatomy` — "Generators, filters, into": every part is optional except one generator; generators can pattern-match, and a non-matching element is skipped silently.

Real Elixir code shown (verbatim, the `#anatomy` static block):

```elixir
# generator, filter, mapping body
for r <- progress, r.completed, do: r.lesson_id

# :into collects into something other than a list
for r <- progress, into: %{}, do: {r.course, r.lesson_id}

# a matching generator skips records that do not match
for %{completed: true, lesson_id: id} <- progress, do: id
```

Bridge cells (`F1 · set-builder notation` → `F3 · the comprehension`): `{ id(r) | r ∈ progress, completed(r) }` → `for r <- progress, r.completed, do: id(r)`.

Closing note: "Next: **lazy streams** — the same traversals, deferred until a result is pulled."

## The interactives

### Section figure — "Comprehension form · select one"

- `<figure class="fig">`, labelled by `#coTitle` ("Comprehension form · select one").
- Control group `#coSel` (`role="group"`, `aria-label="Comprehension form"`), four buttons: `data-k="basic"` (`data-c="elixir"`, label `generator`, default active), `data-k="filtered"` (`data-c="sage"`, label `+ filter`), `data-k="into"` (`data-c="blue"`, label `+ into map`), `data-k="nested"` (`data-c="gold"`, label `two generators`).
- SVG element ids: result group `#coResG`; plus the code panel `#coCode` and readout `#coOut` (both `aria-live="polite"`).
- The `RECS` running example: `{elixir, done}`, `{elixir, not}`, `{otp, done}`, `{otp, done}`, `{elixir, done}` — five records.
- The pure dispatch is `pick(k)`; each form is an entry in the `FORMS` table (`basic`, `filtered`, `into`, `nested`) with a `code` string, a `draw(g)` that renders into `#coResG`, and an `out`.
  - basic: `for r <- progress, do: r.lesson_id` — a list of 5 ids.
  - filtered: `for r <- progress, r.completed, do: r.lesson_id` — 4 ids (completed only).
  - into: `for r <- progress, into: %{}, do: {r.course, r.lesson_id}` — a map, 2 keys.
  - nested: `for c <- courses, r <- progress, r.course == c, do: {c, r.lesson_id}` — 5 `{course, id}` pairs.
- Readout strings (verbatim):
  - basic: `One generator r <- progress draws each record; the body maps it to its id. The result is a list of all 5.`
  - filtered: `The bare boolean r.completed is a filter — records that fail it are dropped, leaving 4.`
  - into: `into: %{} collects pairs into a map instead of a list. A repeated key overwrites, so each course keeps its last id — 2 keys.`
  - nested: `Two generators nest like loops: for each course, each matching record. The result is 5 pairs, grouped by course.`
- Degrade behaviour: the figure renders the static SVG `RESULT` label without JS; the code panel, result graphic, and readout are JS-populated, defaulting to the `basic` form via `pick('basic')`. No motion in this figure; the page's `.reveal` sections fall back to visible under `prefers-reduced-motion: reduce` or no `IntersectionObserver`.

### Footer build-stamp decoder

- `.stamp` `#stamp` with `#stampId` = `TSK0NbFneADV2G`. The static panel shows timestamp `2026-05-31 14:48:08 UTC`.
- `decodeBranded` splits the 3-char namespace (`TSK`) from the base-62 Snowflake, unpacks `ts >> 22`, `node = (snow >> 12) & 0x3FF`, `seq = snow & 0xFFF` against `EPOCH_MS = 1704067200000`, decoding to `2026-05-31 14:48:08 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/enumerable-and-streams.html` — Enumerables and streams — Elixir documentation
- `https://hexdocs.pm/elixir/Stream.html` — `Stream` — Elixir documentation
- `https://hexdocs.pm/elixir/Enumerable.html` — `Enumerable` protocol — Elixir documentation

Related in this course:
- `/elixir/language/enum-streams` — F3.04 · Enumerables & streams
- `/elixir/language/enum-streams/streams` — Lazy streams

## Wiring

- route-tag: `/ elixir / language / enum-streams / comprehensions` (`elixir` → `/elixir`, `language` → `/elixir/language`, `enum-streams` → `/elixir/language/enum-streams`, `comprehensions` current `.rcur`).
- crumbs: `F3` (→ `/elixir/language`) `/` `F3.04` (→ `/elixir/language/enum-streams`) `/` `comprehensions` (`.here`).
- toc-mini: `Build a comprehension` (`#build`), `Generators, filters, into` (`#anatomy`).
- pager: prev → `/elixir/language/enum-streams/enum` label `← Enum, the eager workhorse`; next → `/elixir/language/enum-streams/streams` label `Next · lazy streams →`.
- footer: column "Chapters" — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column "The course" — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01. Brand line `jonnify` → `/elixir`; copyright `© jonnify`.
- Page meta: `<title>` = `Comprehensions — F3.04 · jonnify`. `<meta name="description">` = `The for comprehension: generators draw from any enumerable, filters drop items, :into chooses the result collection, and multiple generators nest — set-builder notation as Elixir syntax.`

## Build instruction

To rebuild this dive, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir accent — the natural model is the adjacent dive `/elixir/language/enum-streams/enum.html` (identical head/header/footer, same single-column lesson hero, single `.solid-select` figure with a `#coCode`-style code panel, bridge, and References). Change only `<title>`/`<meta>`, the route-tag, the crumbs/toc-mini/pager, and the `<main>` body (the lesson hero, the `#build` `Comprehension form` figure, the `#anatomy` code block and the set-builder bridge). No-invent guards: the running example is the learning Portal's progress records — use only the real Portal surfaces as written (the branded store, the event-sourced engine behind one `Portal` facade, the Phoenix web app); cite the companion course for OTP internals rather than re-teaching them, and keep every Elixir token (`for`, the `<-` generator, the bare-boolean filter, `:into`, the `%{completed: true, lesson_id: id}` pattern, the readout strings) exactly as the live page shows them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
