# F3.04 — Enumerables & streams (module hub)

- Route (served): `/elixir/language/enum-streams`
- File: `/Users/jonny/dev/jonnify/elixir/language/enum-streams/index.html`
- Place in the chapter: the fourth module of F3 · The Elixir Language. It frames the three dives that move from eager traversal (`Enum`), through `for` comprehensions, to lazy `Stream` processing — all over the learning Portal's progress data. It follows F3.02 `match` in the pager and leads to F3.05 `Structs`.
- Accent: elixir (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3 · Data & shape · module 4`

H1: Enumerables & `streams` (the word "streams" is the italic elixir-accented `.ex` span).

Hero lede (verbatim):

> A great deal of Elixir is walking collections: a list of lessons, a map of scores, a learner's history. Anything that can be walked one element at a time implements the **Enumerable** protocol, and the `Enum` module is the toolkit for all of them. `Stream` is its lazy twin — the same operations, deferred until something asks for a result.

Kicker (verbatim):

> In F3.03 you piped a learner's progress through a few `Enum` calls. This module takes that further: the functions that summarise a collection, the `for` comprehension, and lazy streams that run over a full history without building every intermediate list.

## What the page frames

The landing opens with a teaching section, then the three-dive directory.

Teaching section `#protocol` — "One protocol, many collections": lists, ranges, maps, `MapSet`s, and streams all implement `Enumerable`, so the same `Enum` call works on any of them. Carries the `Enum.map over a source · select one` interactive (below). Takeaway: "The protocol is the abstraction: write against `Enum` once, and it runs on whatever collection you hand it. Maps are enumerable too — they yield `{key, value}` pairs, so the function takes a pair."

Three deep dives (`#dives`), as accent-coded cards:

- F3.04.1 · Enum, the eager workhorse — "The Enumerable protocol and the functions that walk any collection — `map`, `filter`, `reduce`, `group_by`, `frequencies`." Route `/elixir/language/enum-streams/enum`. Built (elixir left-border).
- F3.04.2 · Comprehensions — "`for` over generators, with filters and `:into` — set-builder notation rendered as Elixir syntax." Route `/elixir/language/enum-streams/comprehensions`. Built (blue left-border).
- F3.04.3 · Lazy streams — "`Stream` builds a recipe that runs only when pulled — eager versus lazy, early exit, and infinite sequences." Route `/elixir/language/enum-streams/streams`. Built (gold left-border).

Bridge cells (`F2 · higher-order functions & folds` → `F3 · Enum & Stream`): "Map, filter, and reduce as the shape of working with collections." → "Those operations as a real, protocol-backed library — eager in `Enum`, lazy in `Stream`."

Closing note: "Start with Enum, then comprehensions, then lazy streams. Next module: **F3.05 — Structs**."

## The interactives

### Hero figure — "When the work happens"

- `<figure class="hero-fig">`, labelled by `#ewTitle` ("When the work happens"). The SVG shows a six-element source `[1, 2, 3, 4, 5, 6]` flowing through three pipeline steps to a `RESULT`.
- Control group: `.hp-ctrls` with two buttons — `#ewBtn` (label `▸ make it lazy`, toggles to `▸ make it eager`) and `#ewReset` (label `reset`, `.ghost`).
- SVG element ids: chain group `#ewChain`; caption `#ewCap` (`aria-live="polite"`).
- The eager/lazy toggle is a small JS IIFE (no named pure function): the `EAGER` rows are `map(& &1 * &1)` (realises 6 → full list), `filter(& rem(&1, 2) == 0)` (realises 6 → full list), `take(2)` (keeps first 2 of the list); the `LAZY` rows are `Stream.map(& &1 * &1)` (fused — no list built), `Stream.filter(& rem(&1, 2) == 0)` (fused — no list built), `Enum.take(2)` (pulls only until 2 pass).
- Readout strings (verbatim). Eager (static default in markup and JS): `Enum · eager — 6 + 6 + 6 elements touched` then `Every step builds a full intermediate list, even though two results are wanted.` Lazy: `Stream · lazy — 4 elements pulled, then it stops` then `The steps fuse and pulling halts once take(2) is satisfied; elements 5 and 6 are never touched.`
- Degrade behaviour: the eager state is the static markup default — the full figure (`SOURCE · 6 ELEMENTS`, the three eager rows, `RESULT` `[4, 16]`) renders without JS. `@media (prefers-reduced-motion: no-preference)` adds the `hpIn` row-slide animation; under `prefers-reduced-motion: reduce` the `.hp-row.hp-new` animation is set to `none`.

### Section figure — "Enum.map over a source · select one"

- `<figure class="fig">`, labelled by `#esTitle` ("Enum.map over a source · select one").
- Control group `#esSel` (`role="group"`, `aria-label="Enumerable source"`), four buttons: `data-k="list"` (`data-c="elixir"`, label `list`, default active), `data-k="range"` (`data-c="blue"`, label `range`), `data-k="set"` (`data-c="sage"`, label `MapSet`), `data-k="stream"` (`data-c="gold"`, label `stream`).
- SVG element ids: source rect `#esSrc`, source text `#esSrcT` (default `[1, 2, 3]`); readout `#esOut` (`aria-live="polite"`).
- The pure function is `pick(k)`: it sets the active button, swaps the `#esSrcT` text from the `SRC` table, and writes the readout. The four sources all map to the same result `[1, 4, 9]`.
- Readout strings (verbatim), each suffixed with ` Either way the result is [1, 4, 9].`:
  - list: `A list is the most common enumerable. Enum.map walks it and returns a new list.`
  - range: `A range never stores its elements — it generates them on demand, yet Enum walks it the same way.`
  - set: `A MapSet holds unique values in any order; Enum still produces a list from it.`
  - stream: `A stream is lazy, but an Enum function forces it — pulling the three values and returning a list.`
- The `SRC` source values: list `[1, 2, 3]`, range `1..3`, set `MapSet.new([1, 2, 3])`, stream `Stream.take(1.., 3)`.

### Footer build-stamp decoder

- `.stamp` `#stamp` with `#stampId` = `TSK0NbFndaS2e8`. The static panel shows timestamp `2026-05-31 14:48:08 UTC`.
- `decodeBranded` splits the 3-char namespace (`TSK`) from the base-62 Snowflake, then unpacks `ts >> 22`, `node = (snow >> 12) & 0x3FF`, `seq = snow & 0xFFF`, against `EPOCH_MS = 1704067200000`, decoding to `2026-05-31 14:48:08 UTC`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/enumerable-and-streams.html` — Elixir — Enumerables and streams (guide) — eager versus lazy traversal.
- `https://hexdocs.pm/elixir/Stream.html` — Elixir — `Stream` — lazy enumerables.
- `https://hexdocs.pm/elixir/Enumerable.html` — Elixir — `Enumerable` protocol — what makes a thing enumerable.

Related in this course:
- `/elixir/language/match` — F3.02 · Pattern matching
- `/elixir/language` — F3 · The Elixir Language

## Wiring

- route-tag: `/ elixir / language / enum-streams` (`elixir` → `/elixir`, `language` → `/elixir/language`, `enum-streams` current `.rcur`).
- crumbs: `F3 · The Elixir Language` (→ `/elixir/language`) `/` `F3.04 · enum & streams` (`.here`).
- toc-mini: `One protocol, many collections` (`#protocol`), `Three deep dives` (`#dives`).
- pager: prev → `/elixir/language/match` label `← F3.02 · match`; next → `/elixir/language/enum-streams/enum` label `Start · the Enum module →`.
- footer: column "Chapters" — `/elixir/algebra` F1 · Algebra, `/elixir/functional` F2 · Functional Programming, `/elixir/language` F3 · The Elixir Language, `/elixir/algorithms` F4 · Algorithms & Data Structures, `/elixir/pragmatic` F5 · Pragmatic Programming, `/elixir/phoenix` F6 · Phoenix Framework. Column "The course" — `/elixir` Course home, `/elixir/course` Contents & history, `/elixir/algebra/functions` Start · F1.01. Brand line `jonnify` → `/elixir`; copyright `© jonnify`.
- Page meta: `<title>` = `Enumerables & streams — F3.04 · jonnify`. `<meta name="description">` = `A collection is anything that implements the Enumerable protocol; Enum walks it eagerly, and Stream walks it lazily. This module deepens the Enum steps from the pipe and adds lazy processing over a learner's full history. Three deep dives follow.`

## Build instruction

To rebuild this hub, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the elixir accent — the natural model is `/elixir/language/structs/index.html` (the next module hub on the same accent) or, lacking that, this module's own dives. Change only `<title>`/`<meta>`, the route-tag, the crumbs/toc-mini/pager, and the `<main>` body (hero, the `#protocol` teaching section, the three dive cards, the bridge). No-invent guards: the running example is the learning Portal — use only the real Portal surfaces as written (the branded store, the event-sourced engine behind one `Portal` facade, the Phoenix web app); cite the companion course for OTP internals rather than re-teaching them, and keep every Elixir token (`Enum`, `Stream`, `for`, `:into`, `MapSet`, the function names and readout strings) exactly as the live page shows them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
